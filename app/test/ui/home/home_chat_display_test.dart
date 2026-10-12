import 'dart:async';

import 'package:app/data/actions/actions_repository.dart';
import 'package:app/data/images/image_picker_service.dart';
import 'package:app/data/local/boxes.dart';
import 'package:app/data/local/records/message_record.dart';
import 'package:app/data/preferences/preferences.dart';
import 'package:app/data/repositories/session_read_repository.dart';
import 'package:app/data/sync/sync_service.dart';
import 'package:app/data/voice/speech_service.dart';
import 'package:app/domain/contracts/update_checker.dart';
import 'package:app/domain/contracts/dismissed_update_store.dart';
import 'package:app/domain/contracts/url_opener.dart';
import 'package:app/pairing/storage.dart';
import 'package:app/routing/adaptive.dart';
import 'package:app/ui/chat/attachment/viewmodels/attachment_viewmodel.dart';
import 'package:app/ui/chat/chat_page.dart';
import 'package:app/ui/chat/states/chat_state.dart';
import 'package:app/ui/chat/viewmodels/chat_viewmodel.dart';
import 'package:app/ui/chat/voice/viewmodels/voice_input_viewmodel.dart';
import 'package:app/ui/chat/widgets/input_bar.dart';
import 'package:app/ui/core/themes/themes.dart';
import 'package:app/ui/home/home_page.dart';
import 'package:app/ui/home/states/home_state.dart';
import 'package:app/ui/home/viewmodels/home_viewmodel.dart';
import 'package:app/ui/home/widgets/session_tile.dart';
import 'package:app/ui/update/viewmodels/update_banner_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/data/local/records/runtime_record.dart';
import 'package:app/domain/session_state.dart';
import 'package:provider/provider.dart';

import '../../transport/connection_manager_display_test.dart' as data;
import 'session_display_name_test.dart' show fixtureDisplay;

class _Storage extends data.Storage {
  @override
  Future<PeerRecord?> loadPeer(String epk) async => data.peer;
  @override
  Future<void> savePeer(PeerRecord peer) async {}
}

class _Secure implements FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => null;
  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {}
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Actions extends ActionsRepository {
  _Actions(super.conn);
  @override
  Future<ModelsCatalogue> listModels({bool forceRefresh = false}) async =>
      const ModelsCatalogue(models: []);
}

class _Speech implements SpeechService {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Picker implements IImagePickerService {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Checker implements UpdateChecker {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Dismissed implements DismissedUpdateStore {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Opener implements UrlOpener {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Read extends SessionReadRepository {
  _Read(super.boxes);
  @override
  Stream<List<MessageRecord>> watchMessages(String epk, String roomId) =>
      Stream.value([
        MessageRecord(
          id: 'synthetic-message',
          seq: 1,
          role: MsgRole.user,
          text: 'synthetic retained message',
          ts: DateTime(2026),
        ),
      ]);
  @override
  Stream<RuntimeRecord> watchRuntime(String epk, String roomId) => Stream.value(
    const RuntimeRecord(
      connection: RuntimeConnection.online,
      presence: RuntimePresence.alive,
    ),
  );
}

class _Sync extends SyncService {
  _Sync(super.conn, super.boxes);
  int requests = 0;
  @override
  Future<void> activate(String epk, String roomId) async {}
  @override
  void requestSync() {
    requests++;
  }

  @override
  List<QueuedMsg> get queuedMessages => [
    QueuedMsg(
      id: 'synthetic-queue',
      text: 'retained follow-up',
      editable: true,
      createdAt: DateTime(2026),
    ),
  ];
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    // No HTTP or downloaded fonts. Only the brand face is substituted in this
    // widget harness; naming/layout uses the production theme and mono assets.
    final font = await rootBundle.load(
      'assets/fonts/fira_mono/FiraMonoNerdFont-Regular.otf',
    );
    final manifest = const StandardMessageCodec().encodeMessage({
      for (final name in ['Inter-Bold.ttf', 'Inter-SemiBold.ttf'])
        name: [
          {'asset': name},
        ],
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final name = String.fromCharCodes(message!.buffer.asUint8List());
          if (name == 'AssetManifest.bin') return manifest;
          if (name.startsWith('Inter-')) return font;
          return null;
        });
  });
  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    GoogleFonts.config.allowRuntimeFetching = true;
  });

  for (final dark in [true, false]) {
    testWidgets(
      'Home navigation, alias control and actual roomsStream refresh chat (${dark ? 'dark' : 'light'})',
      (tester) async {
        tester.view.physicalSize = const Size(320, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        final h = (await tester.runAsync(
          () => data.Harness.create(_Storage()),
        ))!;
        await tester.runAsync(
          () =>
              h.push(data.announced(value: fixtureDisplay('rename').toJson())),
        );
        await tester.runAsync(
          () => h.push(
            data.announced(
              value: fixtureDisplay('rename').toJson(),
              room: 'r2',
            ),
          ),
        );
        final prefs = Preferences(_Secure());
        final home = HomeViewModel(h.storage, prefs, h.cm);
        final selection = SessionSelection();
        final shell = ShellLayout();
        final update = UpdateBannerViewModel(
          _Checker(),
          _Dismissed(),
          _Opener(),
          currentVersion: '0.0.0',
          enabled: false,
        );
        final boxes = LocalBoxes();
        final sync = _Sync(h.cm, boxes);
        final voice = VoiceInputViewModel(_Speech());
        final actions = _Actions(h.cm);
        final attach = AttachmentViewModel(_Picker(), actions);
        ChatViewModel? chat;
        Map<String, dynamic>? navigation;
        final router = GoRouter(
          initialLocation: '/home',
          routes: [
            GoRoute(path: '/home', builder: (_, _) => const HomePage()),
            GoRoute(
              path: '/chat',
              builder: (_, state) {
                navigation = state.extra as Map<String, dynamic>;
                chat ??= ChatViewModel(
                  _Read(boxes),
                  sync,
                  h.cm,
                  prefs,
                  h.storage,
                );
                return ChangeNotifierProvider<ChatViewModel>.value(
                  value: chat!,
                  child: ChatPage(
                    initialTitle: navigation!['title'] as String,
                    initialDevice: navigation!['device'] as String,
                    initialOnline: navigation!['online'] as bool,
                  ),
                );
              },
            ),
          ],
        );
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox.shrink());
          chat?.dispose();
          home.dispose();
          voice.dispose();
          attach.dispose();
          prefs.dispose();
          selection.dispose();
          shell.dispose();
          update.dispose();
          router.dispose();
          sync.dispose();
          actions.dispose();
        });
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<HomeViewModel>.value(value: home),
              ChangeNotifierProvider<Preferences>.value(value: prefs),
              ChangeNotifierProvider<SessionSelection>.value(value: selection),
              ChangeNotifierProvider<ShellLayout>.value(value: shell),
              ChangeNotifierProvider<UpdateBannerViewModel>.value(
                value: update,
              ),
              ChangeNotifierProvider<VoiceInputViewModel>.value(value: voice),
              ChangeNotifierProvider<AttachmentViewModel>.value(value: attach),
            ],
            child: MaterialApp.router(
              theme: dark ? buildDarkTheme() : buildLightTheme(),
              routerConfig: router,
              builder: (_, child) => MediaQuery(
                data: const MediaQueryData(
                  size: Size(320, 1100),
                  textScaler: TextScaler.linear(2),
                ),
                child: child!,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        home.setFilter(HomeFilter.all);
        await tester.pumpAndSettle();
        expect(find.text('Pi · system'), findsNWidgets(2));
        expect(
          tester.getSemantics(find.text('Connected').first).label,
          contains('Connected'),
        );
        Finder tile(String id) => find.byWidgetPredicate(
          (w) => w is SessionTile && w.room?.roomId == id,
        );
        await tester.longPress(tile('r1'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mobile alias'));
        await tester.pumpAndSettle();
        final aliasField = tester.widget<TextField>(find.byType(TextField));
        expect(
          aliasField.controller!.text,
          isEmpty,
        ); // routing name is NOT a saved override
        expect(
          find.text('Saved fallback when no desktop name is available'),
          findsOneWidget,
        );
        await tester.enterText(find.byType(TextField), 'Mobile <plain>');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(h.room().localName, 'Mobile <plain>');
        expect(h.room().name, 'routing-agent');
        expect(find.text('Pi · system'), findsNWidgets(2));
        expect(find.text('Mobile <plain>'), findsNothing);
        await tester.longPress(tile('r1'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mobile alias'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'Mobile <plain>',
        );
        await tester.enterText(find.byType(TextField), '');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(h.room().localName, isNull);
        expect(find.text('Pi · system'), findsNWidgets(2));
        await tester.tap(tile('r1'));
        await tester.pumpAndSettle();
        expect(navigation!['title'], 'Pi · system');
        expect(selection.current!.roomId, 'r1');
        expect(prefs.selectedRoomId, 'r1');
        expect(chat!.activeRoom!.roomId, 'r1');
        expect(find.text('Pi · system'), findsOneWidget);
        await tester.enterText(
          find.descendant(
            of: find.byType(InputBar),
            matching: find.byType(TextField),
          ),
          'synthetic unsent draft',
        );
        await tester.pump();
        final before = chat!.state as ChatReady;
        final inputState = tester.state(find.byType(InputBar));
        final checks = h.ch.checks.length;
        final sends = h.ch.sends.length;
        final reloads = sync.requests;
        var notices = 0;
        chat!.addListener(() => notices++);
        Future<void> patch(
          Map<String, dynamic> meta,
          String title, {
          String room = 'r1',
        }) async {
          await tester.runAsync(() => h.push(data.patch(meta, room: room)));
          await tester.pumpAndSettle();
          expect(find.text(title), findsOneWidget);
          expect(
            identical((chat!.state as ChatReady).messages, before.messages),
            isTrue,
          );
          expect(
            (chat!.state as ChatReady).queuedMessages,
            before.queuedMessages,
          );
          expect(
            identical(tester.state(find.byType(InputBar)), inputState),
            isTrue,
          );
          expect(
            tester
                .widget<TextField>(
                  find.descendant(
                    of: find.byType(InputBar),
                    matching: find.byType(TextField),
                  ),
                )
                .controller!
                .text,
            'synthetic unsent draft',
          );
          expect(prefs.selectedRoomId, 'r1');
          expect(h.cm.activeRoomId, 'r1');
          expect(h.ch.checks.length, checks);
          expect(h.ch.sends.length, sends);
          expect(sync.requests, reloads);
        }

        await patch({
          'display': data.display(2, 'Renamed <plain>'),
        }, 'Renamed <plain>');
        expect(notices, 1);
        await patch({
          'display': data.display(2, 'Renamed <plain>'),
        }, 'Renamed <plain>');
        expect(notices, 1);
        await patch(
          {'display': data.display(2, 'Other room')},
          'Renamed <plain>',
          room: 'r2',
        );
        expect(notices, 1);
        await patch({'model': 'model-only'}, 'Renamed <plain>');
        expect(notices, 2);
        await tester.tap(find.byTooltip('Session info'));
        await tester.pumpAndSettle();
        expect(find.text('model-only'), findsOneWidget);
        expect(find.text('r1'), findsOneWidget);
        expect(find.text('/synthetic/duplicate'), findsOneWidget);
        expect(find.text('Renamed <plain>'), findsNWidgets(2));
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        await h.cm.setRoomLocalName(
          data.peer.remoteEpk,
          'r1',
          'Saved fallback',
        );
        await tester.pumpAndSettle();
        expect(find.text('Renamed <plain>'), findsOneWidget);
        expect(h.room().localName, 'Saved fallback');
        await patch({
          'display': data.display(3, 'Desktop changed'),
        }, 'Desktop changed');
        expect(h.room().localName, 'Saved fallback');
        expect(
          h.storage.rooms.singleWhere((r) => r.roomId == 'r1').localName,
          'Saved fallback',
        );
        await patch({'display': data.display(4, null)}, 'Saved fallback');
        await patch({
          'display': data.display(5, 'Verified again'),
        }, 'Verified again');
        await patch({'display': null}, 'Saved fallback');
        await patch({
          'display': data.display(6, 'Unverified late'),
        }, 'Saved fallback');
        expect(h.room().localName, 'Saved fallback');
        await h.cm.setRoomLocalName(data.peer.remoteEpk, 'r1', null);
        await tester.pumpAndSettle();
        expect(find.text('duplicate'), findsOneWidget);
        final priorNotices = notices;
        await patch({'working': false}, 'duplicate');
        expect(notices, priorNotices + 1); // State emit must not double-notify.
        expect(find.text('synthetic retained message'), findsOneWidget);
        expect(tester.takeException(), isNull);
        semantics.dispose();
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  for (final size in [const Size(400, 900), const Size(900, 900)]) {
    testWidgets(
      'Home metadata and full relay status at default scale ${size.width}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final h = (await tester.runAsync(
          () => data.Harness.create(_Storage()),
        ))!;
        await tester.runAsync(
          () =>
              h.push(data.announced(value: fixtureDisplay('rename').toJson())),
        );
        final prefs = Preferences(_Secure());
        final home = HomeViewModel(h.storage, prefs, h.cm);
        final selection = SessionSelection();
        final shell = ShellLayout();
        final update = UpdateBannerViewModel(
          _Checker(),
          _Dismissed(),
          _Opener(),
          currentVersion: '0.0.0',
          enabled: false,
        );
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<HomeViewModel>.value(value: home),
              ChangeNotifierProvider<SessionSelection>.value(value: selection),
              ChangeNotifierProvider<ShellLayout>.value(value: shell),
              ChangeNotifierProvider<UpdateBannerViewModel>.value(
                value: update,
              ),
            ],
            child: MaterialApp(theme: buildDarkTheme(), home: const HomePage()),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Pi · system'), findsOneWidget);
        expect(find.text('Connected'), findsOneWidget);
        await tester.runAsync(
          () =>
              h.push(data.patch({'display': data.display(2, 'Home renamed')})),
        );
        await tester.pumpAndSettle();
        expect(find.text('Home renamed'), findsOneWidget);
        await h.cm.setRoomLocalName(data.peer.remoteEpk, 'r1', 'Home fallback');
        await tester.runAsync(
          () => h.push(
            data.announced(
              room: 'r2',
              value: data.display(
                1,
                'Other desktop',
                native: '11111111-1111-4111-8111-111111111111',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(h.room().cwd, h.room('r2').cwd);
        expect(find.text('Home renamed'), findsOneWidget);
        expect(find.text('Other desktop'), findsOneWidget);
        final checks = h.ch.checks.length;
        final sends = h.ch.sends.length;
        await tester.runAsync(
          () => h.push(
            data.patch({'display': data.display(3, 'Latest desktop')}),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Latest desktop'), findsOneWidget);
        expect(find.text('Other desktop'), findsOneWidget);
        expect(h.room().localName, 'Home fallback');
        expect(h.ch.checks.length, checks);
        expect(h.ch.sends.length, sends);
        expect(
          h.storage.rooms.singleWhere((r) => r.roomId == 'r1').localName,
          'Home fallback',
        );
        home.setFilter(HomeFilter.all);
        await h.cm.disconnect();
        await tester.pumpAndSettle();
        expect(find.text('Home fallback'), findsOneWidget);
        expect(find.text('duplicate'), findsOneWidget);
        expect(find.textContaining('Reconnecting'), findsNWidgets(2));
        expect(h.room().display, isNull);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        home.dispose();
        prefs.dispose();
        selection.dispose();
        shell.dispose();
        update.dispose();
      },
    );
  }
}
