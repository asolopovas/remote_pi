// Plan/71: exercise the production ChatPage list, not isolated static cards.
import 'dart:async';
import 'dart:convert';
import 'package:app/ui/chat/widgets/codemode_preview.dart';
import 'dart:io';

import 'package:app/domain/session_state.dart';
import 'package:app/ui/chat/states/chat_state.dart';
import 'package:app/data/actions/actions_repository.dart';
import 'package:app/data/images/image_picker_service.dart';
import 'package:app/data/local/boxes.dart';
import 'package:app/data/preferences/preferences.dart';
import 'package:app/data/repositories/session_read_repository.dart';
import 'package:app/data/sync/sync_service.dart';
import 'package:app/data/transport/channel.dart';
import 'package:app/data/transport/connection_manager.dart';
import 'package:app/data/voice/speech_service.dart';
import 'package:app/pairing/storage.dart';
import 'package:app/protocol/protocol.dart';
import 'package:app/routing/adaptive.dart';
import 'package:app/ui/chat/attachment/viewmodels/attachment_viewmodel.dart';
import 'package:app/ui/chat/chat_page.dart';
import 'package:app/ui/chat/widgets/input_bar.dart';
import 'package:app/ui/chat/widgets/accordion_viewport.dart';
import 'package:app/ui/chat/viewmodels/chat_viewmodel.dart';
import 'package:app/ui/chat/voice/viewmodels/voice_input_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' show Tristate;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

class _FakeChannel implements IChannel {
  final _ctrl = StreamController<ServerMessage>.broadcast();
  @override
  Stream<ServerMessage> get serverMessages => _ctrl.stream;
  @override
  Future<void> send(ClientMessage msg) async {}
  @override
  Future<void> close() => _ctrl.close();
}

// Keep transport inert; drive the real ViewModel state as DB/stream updates do.
class _FakeStorage extends PairingStorage {
  @override
  Future<List<PeerRecord>> listPeers() async => const [];
  @override
  Future<PeerRecord?> loadPeer(String epk) async => null;
}

class _FakeSecureStorage implements FlutterSecureStorage {
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
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeSpeech implements SpeechService {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakePicker implements IImagePickerService {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _SessionVM extends ChatViewModel {
  _SessionVM(super.read, super.sync, super.conn, super.prefs, super.storage);
  PeerRecord? testPeer;
  @override
  PeerRecord? get activePeer => testPeer;
}

void main() {
  late Directory dir;
  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('rp_rendering_');
    await LocalBoxes.initForTest(dir.path);
  });
  tearDownAll(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  testWidgets(
    'session tabs retain reverse disclosure and nested shared code at 320px/2x without child composer or stale room header',
    (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      final conn = ConnectionManager(
        factory: (_, _) async => _FakeChannel(),
        storage: _FakeStorage(),
      );
      final boxes = LocalBoxes();
      final sync = SyncService(conn, boxes);
      final prefs = Preferences(_FakeSecureStorage());
      final actions = ActionsRepository(conn);
      final vm = _SessionVM(
        SessionReadRepository(boxes),
        sync,
        conn,
        prefs,
        _FakeStorage(),
      );
      final voice = VoiceInputViewModel(_FakeSpeech());
      final attach = AttachmentViewModel(_FakePicker(), actions);
      final sel = SessionSelection();
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<ChatViewModel>.value(value: vm),
              ChangeNotifierProvider<VoiceInputViewModel>.value(value: voice),
              ChangeNotifierProvider<AttachmentViewModel>.value(value: attach),
              ChangeNotifierProvider<Preferences>.value(value: prefs),
              ChangeNotifierProvider<SessionSelection>.value(value: sel),
            ],
            child: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: const ChatPage(initialOnline: true),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      vm.emit(const ChatReady(messages: []));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Main'), findsOneWidget);
      expect(find.text('Sub-agents'), findsOneWidget);
      final mainButton = tester.widget<TextButton>(
        find.ancestor(of: find.text('Main'), matching: find.byType(TextButton)),
      );
      final mainSemantics = find.byKey(const ValueKey('session-tab-Main'));
      expect(
        tester.getSemantics(mainSemantics).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      expect(
        mainButton.style!.backgroundColor!.resolve({}),
        isNot(Colors.transparent),
      );
      expect(
        tester.getSize(find.text('Main').hitTestable()).height,
        lessThan(48),
      );
      expect(
        tester
            .getSize(
              find.ancestor(
                of: find.text('Main'),
                matching: find.byType(TextButton),
              ),
            )
            .height,
        greaterThanOrEqualTo(48),
      );
      await tester.tap(find.text('Sub-agents'));
      await tester.pumpAndSettle();
      final subagentButton = tester.widget<TextButton>(
        find.ancestor(
          of: find.text('Sub-agents'),
          matching: find.byType(TextButton),
        ),
      );
      expect(
        subagentButton.style!.backgroundColor!.resolve({}),
        isNot(Colors.transparent),
      );
      await tester.tap(find.text('Main'));
      await tester.pumpAndSettle();
      expect(find.byType(InputBar), findsOneWidget);
      await tester.tap(find.text('Sub-agents'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('No sub-agents in this session'), findsOneWidget);
      expect(find.byType(InputBar), findsNothing);
      await tester.tap(find.text('Main'));
      final lines = List.generate(100, (i) => 'nested line $i').join('\n');
      final tool = ToolEvent(
        id: 'tool',
        toolCallId: 'tool',
        tool: 'bash',
        args: const {
          'command': 'if true; then\n  printf "hello\\n"\nfi\n',
          'timeout': 120,
        },
        status: ToolEventStatus.completed,
        result: lines,
      );
      final agent = ToolEvent(
        id: 'agent',
        toolCallId: 'agent',
        tool: 'subagent',
        args: const {'agent': 'scout', 'task': 'Inspect'},
        status: ToolEventStatus.completed,
        result: 'Actual output\n```dart\n$lines\n```\nEnd of output',
      );
      final history = <ChatMessage>[tool, agent];
      vm.emit(ChatReady(messages: history));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('tool-disclosure')).hitTestable());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final mainList = find.byWidgetPredicate(
        (w) => w is ListView && w.reverse,
      );
      final mainScroll = tester.widget<ListView>(mainList).controller!;
      final toolAlignedOffset = mainScroll.offset;
      mainScroll.jumpTo(mainScroll.offset - 200);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final readingOffset = mainScroll.offset;
      final failed = ToolEvent(
        id: 'tool',
        toolCallId: 'tool',
        tool: 'bash',
        args: tool.args,
        status: ToolEventStatus.failed,
        result: lines,
      );
      vm.emit(ChatReady(messages: [failed, agent]));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('accordion-pinned-heading')), findsNothing);
      expect(
        find.byKey(const Key('tool-disclosure')).hitTestable(),
        findsNothing,
      );
      expect(mainScroll.offset, closeTo(readingOffset, 1));
      mainScroll.jumpTo(toolAlignedOffset);
      await tester.pumpAndSettle();
      expect(find.text('FAILED'), findsOneWidget);
      await tester.tap(find.byTooltip('Copy command').hitTestable());
      await tester.pump();
      expect(copied, (tool.args as Map)['command']);
      mainScroll.jumpTo(readingOffset);
      await tester.pumpAndSettle();
      vm.emit(
        ChatReady(
          messages: [failed, agent],
          streaming: const StreamingMessage(
            inReplyTo: 'update',
            buffer: 'New output',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(mainScroll.offset, closeTo(readingOffset, 1));
      await tester.tap(find.text('Sub-agents'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(InputBar), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey('subagent-agent')).hitTestable(),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Call returned'), findsWidgets);
      expect(find.textContaining('not live child telemetry'), findsOneWidget);
      await tester.tap(find.byKey(const Key('code-disclosure')).hitTestable());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final codeHeader = find.byKey(const Key('code-disclosure')).hitTestable();
      final agentList = find.byWidgetPredicate(
        (w) => w is ListView && !w.reverse,
      );
      expect(codeHeader, findsOneWidget);
      expect(
        tester.getRect(codeHeader).top,
        closeTo(tester.getRect(agentList).top, 1),
      );
      final agentScroll = tester.widget<ListView>(agentList).controller!;
      final agentAlignedOffset = agentScroll.offset;
      agentScroll.jumpTo(agentScroll.offset + 300);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(codeHeader, findsNothing);
      expect(find.byKey(const Key('accordion-pinned-heading')), findsNothing);
      agentScroll.jumpTo(agentAlignedOffset);
      await tester.pumpAndSettle();
      expect(codeHeader, findsOneWidget);
      expect(
        tester.getSemantics(codeHeader).flagsCollection.isExpanded,
        Tristate.isTrue,
      );
      await tester.tap(codeHeader);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('nested line 99'), findsNothing);
      await tester.tap(find.text('Main'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(InputBar), findsOneWidget);
      expect(mainScroll.offset, closeTo(readingOffset, 1));
      expect(
        find.byKey(const Key('tool-disclosure')).hitTestable(),
        findsNothing,
      );
      // Plan75: real recovered static source owns one nested viewport heading,
      // not an inferred child-tool event. Its independent controls/state persist.
      final recovered =
          jsonDecode(
                File(
                  'test/ui/chat/fixtures/75/75-reported-tool.json',
                ).readAsStringSync(),
              )
              as Map;
      final recoveredScript = (recovered['arguments'] as Map)['code'] as String;
      final preview = embeddedCodemodeSource(recoveredScript).first;
      final nestedTool = ToolEvent(
        id: 'nested',
        toolCallId: 'nested',
        tool: 'codemode',
        args: recovered['arguments'],
      );
      vm.emit(ChatReady(messages: [nestedTool]));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tool-disclosure')).hitTestable());
      await tester.pumpAndSettle();
      // The composite outer Scroll must not unbound nested frames or headings.
      await tester.tap(find.byKey(const Key('code-wrap')).hitTestable());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final embeddedViewport = find.byKey(
        ValueKey('tool-embedded-nested-${preview.offset}'),
      );
      await tester.tap(
        find
            .descendant(
              of: embeddedViewport,
              matching: find.byKey(const Key('code-disclosure')),
            )
            .hitTestable(),
      );
      await tester.pumpAndSettle();
      final nestedHeading = find
          .byKey(const Key('code-disclosure'))
          .hitTestable();
      expect(
        tester.getRect(nestedHeading).top,
        closeTo(tester.getRect(mainList).top, 1),
      );
      final nestedAlignedOffset = mainScroll.offset;
      mainScroll.jumpTo(
        (mainScroll.offset - 300).clamp(0, mainScroll.position.maxScrollExtent),
      );
      await tester.pumpAndSettle();
      expect(nestedHeading, findsNothing);
      expect(find.byKey(const Key('accordion-pinned-heading')), findsNothing);
      mainScroll.jumpTo(nestedAlignedOffset);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byTooltip('Copy decoded embedded string').hitTestable(),
      );
      await tester.pump();
      expect(copied, preview.text);
      await tester.tap(
        find
            .descendant(
              of: embeddedViewport,
              matching: find.byKey(const Key('code-wrap')),
            )
            .hitTestable(),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: embeddedViewport, matching: find.text('Wrap')),
        findsOneWidget,
      );
      vm.emit(
        ChatReady(
          messages: [nestedTool.copyWith(status: ToolEventStatus.completed)],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sub-agents'));
      await tester.pumpAndSettle();
      expect(
        find.byTooltip('Copy decoded embedded string').hitTestable(),
        findsNothing,
      );
      await tester.tap(find.text('Main'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: embeddedViewport, matching: find.text('Wrap')),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.descendant(
          of: embeddedViewport,
          matching: find.byKey(const Key('code-disclosure')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(nestedHeading);
      await tester.pumpAndSettle();
      expect(find.text(preview.text), findsNothing);
      expect(tester.takeException(), isNull);
      vm.testPeer = const PeerRecord(
        remoteEpk: 'another-peer',
        roomId: 'other-room',
        sessionName: 'Other',
        relayUrl: 'ws://example',
        pairedAt: 'today',
      );
      vm.emit(
        const ChatReady(
          messages: [UserMsg(id: 'other', text: 'Other room')],
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const Key('tool-disclosure')).hitTestable(),
        findsNothing,
      );
      expect(find.byType(InputBar), findsOneWidget);
      expect(find.text('Other room'), findsWidgets);
      expect(find.byType(AccordionAnchor), findsNothing);
      expect(tester.takeException(), isNull);
      semantics.dispose();
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
      attach.dispose();
      voice.dispose();
      actions.dispose();
      sync.dispose();
      sel.dispose();
      conn.dispose();
    },
  );

  testWidgets(
    'last reverse tool aligns once and its original heading scrolls away',
    (tester) async {
      final conn = ConnectionManager(
        factory: (_, _) async => _FakeChannel(),
        storage: _FakeStorage(),
      );
      final boxes = LocalBoxes();
      final sync = SyncService(conn, boxes);
      final prefs = Preferences(_FakeSecureStorage());
      final actions = ActionsRepository(conn);
      final vm = ChatViewModel(
        SessionReadRepository(boxes),
        sync,
        conn,
        prefs,
        _FakeStorage(),
      );
      final voice = VoiceInputViewModel(_FakeSpeech());
      final attach = AttachmentViewModel(_FakePicker(), actions);
      final sel = SessionSelection();
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<ChatViewModel>.value(value: vm),
              ChangeNotifierProvider<VoiceInputViewModel>.value(value: voice),
              ChangeNotifierProvider<AttachmentViewModel>.value(value: attach),
              ChangeNotifierProvider<Preferences>.value(value: prefs),
              ChangeNotifierProvider<SessionSelection>.value(value: sel),
            ],
            child: const ChatPage(initialOnline: true),
          ),
        ),
      );
      await tester.pump();

      vm.emit(
        ChatReady(
          messages: [
            const UserMsg(id: 'p', text: 'Parent'),
            ToolEvent(
              id: 'long',
              toolCallId: 'long',
              tool: 'bash',
              args: const {'command': 'long output'},
              status: ToolEventStatus.completed,
              result: List.generate(150, (i) => 'Line $i').join('\n'),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      final list = find.byWidgetPredicate((w) => w is ListView && w.reverse);
      await tester.tap(find.byKey(const Key('tool-disclosure')).hitTestable());
      await tester.pumpAndSettle();
      final heading = find.byKey(const Key('tool-disclosure')).hitTestable();
      expect(heading, findsOneWidget);
      expect(tester.getRect(heading).top, closeTo(tester.getRect(list).top, 1));
      final scroll = tester.widget<ListView>(list).controller!;
      final alignedOffset = scroll.offset;
      scroll.jumpTo(
        (scroll.offset - 300).clamp(0, scroll.position.maxScrollExtent),
      );
      await tester.pumpAndSettle();
      expect(heading, findsNothing);
      expect(find.byKey(const Key('accordion-pinned-heading')), findsNothing);
      final readingOffset = scroll.offset;
      tester.view.viewInsets = const FakeViewPadding(bottom: 180);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(heading, findsNothing);
      expect(scroll.offset, closeTo(readingOffset, 1));
      scroll.jumpTo(alignedOffset);
      await tester.ensureVisible(find.byKey(const Key('tool-disclosure')));
      await tester.pumpAndSettle();
      expect(heading, findsOneWidget);
      await tester.tap(heading);
      await tester.pumpAndSettle();
      expect(find.textContaining('Line 149'), findsNothing);
      expect(find.byKey(const Key('accordion-pinned-heading')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
      attach.dispose();
      voice.dispose();
      actions.dispose();
      sync.dispose();
      sel.dispose();
      conn.dispose();
    },
  );

  testWidgets(
    'reverse assistant code aligns independently and scrolls its heading away',
    (tester) async {
      final conn = ConnectionManager(
        factory: (_, _) async => _FakeChannel(),
        storage: _FakeStorage(),
      );
      final boxes = LocalBoxes();
      final sync = SyncService(conn, boxes);
      final prefs = Preferences(_FakeSecureStorage());
      final actions = ActionsRepository(conn);
      final vm = ChatViewModel(
        SessionReadRepository(boxes),
        sync,
        conn,
        prefs,
        _FakeStorage(),
      );
      final voice = VoiceInputViewModel(_FakeSpeech());
      final attach = AttachmentViewModel(_FakePicker(), actions);
      final sel = SessionSelection();
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<ChatViewModel>.value(value: vm),
              ChangeNotifierProvider<VoiceInputViewModel>.value(value: voice),
              ChangeNotifierProvider<AttachmentViewModel>.value(value: attach),
              ChangeNotifierProvider<Preferences>.value(value: prefs),
              ChangeNotifierProvider<SessionSelection>.value(value: sel),
            ],
            child: const ChatPage(initialOnline: true),
          ),
        ),
      );
      await tester.pump();

      final lines = List.generate(80, (i) => 'output $i').join('\n');
      vm.emit(
        ChatReady(
          messages: [
            AssistantMsg(id: 'code', text: 'Example\n```dart\n$lines\n```'),
            ToolEvent(
              id: 'cmd',
              toolCallId: 'cmd',
              tool: 'bash',
              args: const {'command': 'command'},
              result: lines,
              status: ToolEventStatus.completed,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tool-disclosure')).hitTestable());
      await tester.pumpAndSettle();
      final list = find.byWidgetPredicate((w) => w is ListView && w.reverse);
      final scroll = tester.widget<ListView>(list).controller!;
      scroll.jumpTo(scroll.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('accordion-pinned-heading')),
          matching: find.byKey(const Key('tool-disclosure')),
        ),
        findsNothing,
      );
      await tester.tap(find.byKey(const Key('code-disclosure')).hitTestable());
      await tester.pumpAndSettle();
      final heading = find.byKey(const Key('code-disclosure')).hitTestable();
      expect(heading, findsOneWidget);
      expect(tester.getRect(heading).top, closeTo(tester.getRect(list).top, 1));
      expect(
        tester
            .widgetList<AccordionAnchor>(
              find.byType(AccordionAnchor, skipOffstage: false),
            )
            .where((a) => a.expanded)
            .length,
        2,
      );
      final codeAlignedOffset = scroll.offset;
      scroll.jumpTo(scroll.offset - 200);
      await tester.pumpAndSettle();
      expect(heading, findsNothing);
      scroll.jumpTo(codeAlignedOffset);
      await tester.pumpAndSettle();
      expect(heading, findsOneWidget);
      await tester.tap(heading);
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<AccordionAnchor>(
              find.byType(AccordionAnchor, skipOffstage: false),
            )
            .where((a) => a.expanded)
            .length,
        1,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
      attach.dispose();
      voice.dispose();
      actions.dispose();
      sync.dispose();
      sel.dispose();
      conn.dispose();
    },
  );

  testWidgets(
    'reverse separated history with retained tool survives streaming and reload',
    (tester) async {
      final conn = ConnectionManager(
        factory: (_, _) async => _FakeChannel(),
        storage: _FakeStorage(),
      );
      final boxes = LocalBoxes();
      final sync = SyncService(conn, boxes);
      final prefs = Preferences(_FakeSecureStorage());
      final actions = ActionsRepository(conn);
      final vm = ChatViewModel(
        SessionReadRepository(boxes),
        sync,
        conn,
        prefs,
        _FakeStorage(),
      );
      final voice = VoiceInputViewModel(_FakeSpeech());
      final attach = AttachmentViewModel(_FakePicker(), actions);
      final sel = SessionSelection();
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<ChatViewModel>.value(value: vm),
              ChangeNotifierProvider<VoiceInputViewModel>.value(value: voice),
              ChangeNotifierProvider<AttachmentViewModel>.value(value: attach),
              ChangeNotifierProvider<Preferences>.value(value: prefs),
              ChangeNotifierProvider<SessionSelection>.value(value: sel),
            ],
            child: const ChatPage(initialOnline: true),
          ),
        ),
      );
      await tester.pump();
      final history = <ChatMessage>[
        for (var i = 0; i < 30; i++) ...[
          UserMsg(id: 'a$i', text: 'Prompt $i'),
          AssistantMsg(id: 'a$i', text: 'History $i\n' * 4),
          AssistantMsg(id: 'a$i', text: 'Segment $i'),
        ],
        const UserMsg(
          id: 'streaming',
          text: 'A valid ID, not a reserved row key',
        ),
        const ToolEvent(
          id: 'tool',
          toolCallId: 'tool',
          tool: 'bash',
          args: {'command': 'pwd'},
          status: ToolEventStatus.completed,
          result: 'directory',
        ),
      ];
      Future<void> show(
        List<ChatMessage> messages, [
        StreamingMessage? streaming,
      ]) async {
        vm.emit(ChatReady(messages: messages, streaming: streaming));
        await tester.pump();
        expect(tester.takeException(), isNull);
      }

      await show(history);
      await tester.tap(find.byKey(const Key('tool-disclosure')).hitTestable());
      await tester.pump();
      final list = find.byWidgetPredicate((w) => w is ListView && w.reverse);
      final scroll = tester.widget<ListView>(list).controller!;
      scroll.jumpTo(1400);
      await tester.pump();
      for (var i = 0; i < 5; i++) {
        await show(
          history,
          StreamingMessage(inReplyTo: 'streaming', buffer: 'Streaming $i'),
        );
        await show([
          ...history,
          AssistantMsg(id: 'streaming', text: 'Persisted $i'),
        ]);
        await show(history.toList());
      }
      // Settle any anchor correction after the retained rows move, then
      // return to the actual bottom before hitting their controls.
      scroll.jumpTo(0);
      await tester.pumpAndSettle();
      scroll.jumpTo(0);
      await tester.pumpAndSettle();
      expect(find.text('directory'), findsOneWidget);
      // Explicit collapse and wrap choices survive offscreen keepalive/remapping.
      await tester.tap(find.byKey(const Key('code-wrap')).hitTestable());
      await tester.pump();
      await tester.tap(find.byKey(const Key('tool-disclosure')).hitTestable());
      await tester.pump();
      scroll.jumpTo(1400);
      await tester.pump();
      await show(
        history,
        const StreamingMessage(inReplyTo: 'streaming', buffer: 'Next'),
      );
      await show(history);
      // Settle any anchor correction after the retained rows move, then
      // return to the actual bottom before hitting their controls.
      scroll.jumpTo(0);
      await tester.pumpAndSettle();
      scroll.jumpTo(0);
      await tester.pumpAndSettle();
      expect(find.text('directory'), findsNothing);
      await tester.tap(find.byKey(const Key('tool-disclosure')).hitTestable());
      await tester.pump();
      expect(find.text('Wrap').hitTestable(), findsOneWidget);

      // Tool classification can remove a retained row from the main thread.
      await show([
        ...history.take(history.length - 1),
        const ToolEvent(
          id: 'tool',
          toolCallId: 'tool',
          tool: 'subagent',
          args: {'agent': 'scout', 'task': 'Inspect'},
        ),
      ]);
      expect(
        find.byKey(const Key('tool-disclosure')).hitTestable(),
        findsNothing,
      );
      await show(history);
      expect(
        find.text('directory'),
        findsNothing,
      ); // removed rows start collapsed

      // A short reversed list naturally paints at the bottom, not at the top.
      await show(const [UserMsg(id: 'short', text: 'Short history')]);
      expect(
        tester
            .getRect(
              find.descendant(of: list, matching: find.text('Short history')),
            )
            .bottom,
        greaterThan(tester.getRect(list).center.dy),
      );
      // This branch is not a painting failure: there really are no messages in
      // state. Presence does not imply history, and no sliver is built here.
      await show(const []);
      expect(find.text('No messages available'), findsOneWidget);
      expect(find.text('online'), findsOneWidget);
      expect(list, findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
      attach.dispose();
      voice.dispose();
      actions.dispose();
      sync.dispose();
      sel.dispose();
      conn.dispose();
    },
  );
}
