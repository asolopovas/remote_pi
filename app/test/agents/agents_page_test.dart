import 'dart:async';

import 'package:app/domain/contracts/agent_repository.dart';
import 'package:app/ui/agents/agents_page.dart';
import 'package:app/ui/agents/viewmodels/agents_viewmodel.dart';
import 'package:app/ui/core/themes/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'agents_viewmodel_test.dart' show Repo;

Future<void> selectProject(WidgetTester tester) async {
  final tile = find.byKey(const ValueKey('launch-project-project'));
  await tester.ensureVisible(tile);
  await tester.tap(tile);
  await tester.pumpAndSettle();
}

Widget page(
  AgentsViewModel vm, {
  String room = 'room',
  bool dark = true,
  double scale = 1,
}) => ChangeNotifierProvider.value(
  value: vm,
  child: MaterialApp(
    theme: dark ? buildDarkTheme() : buildLightTheme(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: AgentsPage(target: AgentsTarget('peer', room, 'Laptop', 'Project')),
  ),
);

bool canStart(WidgetTester tester) {
  final button = find.widgetWithText(FilledButton, 'Start agent');
  return button.evaluate().isNotEmpty &&
      tester.widget<FilledButton>(button).onPressed != null;
}

Future<void> openRunning(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Agent options'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Started here'));
  await tester.pumpAndSettle();
}

LauncherStatus locked({bool configured = true, String epoch = 'epoch-1'}) =>
    LauncherStatus(
      launcherId: 'launcher-1',
      epoch: epoch,
      configured: configured,
      unlocked: false,
      expiresAt: null,
      cooldownUntil: 0,
    );

class _UnlockRepo extends Repo {
  int unlocks = 0;
  @override
  Future<void> unlock(String pin) async {
    if (pin.length < 6) throw const AgentFailure('PIN must be 6–12 digits.');
    unlocks++;
    security = LauncherStatus(
      launcherId: security.launcherId,
      epoch: 'unlocked-epoch',
      configured: true,
      unlocked: true,
      expiresAt: DateTime.now().millisecondsSinceEpoch + 600000,
      cooldownUntil: 0,
    );
  }
}

void main() {
  for (final scale in [1.0, 2.0]) {
    for (final dark in [true, false]) {
      testWidgets(
        'project list has one clear action at 320px/${scale}x/dark=$dark',
        (tester) async {
          tester.view.physicalSize = const Size(320, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final vm = AgentsViewModel(Repo());
          await tester.pumpWidget(page(vm, dark: dark, scale: scale));
          await tester.pumpAndSettle();
          expect(find.text('Host: Laptop'), findsOneWidget);
          expect(find.byType(RadioListTile<String>), findsOneWidget);
          expect(find.byType(TextField), findsNothing);
          expect(find.text('Managed agents'), findsNothing);
          expect(find.text('Lock'), findsNothing);
          expect(find.text('Stop all and lock'), findsNothing);
          expect(find.widgetWithText(TextButton, 'Refresh'), findsNothing);
          expect(canStart(tester), isFalse);
          await selectProject(tester);
          expect(canStart(tester), isTrue);
          final start = find.widgetWithText(FilledButton, 'Start agent');
          await tester.ensureVisible(start);
          await tester.pumpAndSettle();
          expect(
            tester.getRect(start).top -
                tester.getRect(find.byType(RadioGroup<String>)).bottom,
            AppSpacing.md,
          );
          expect(
            tester.getSize(start).height,
            greaterThanOrEqualTo(AppSpacing.tap),
          );
          expect(tester.getRect(start).left, AppSpacing.md);
          expect(tester.getRect(start).right, 320 - AppSpacing.md);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          vm.dispose();
        },
      );
    }
  }

  testWidgets('missing host PIN is setup, not a disabled unlock/project form', (
    tester,
  ) async {
    final repo = Repo()..security = locked(configured: false);
    final vm = AgentsViewModel(repo);
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
    await tester.pumpWidget(page(vm));
    await tester.pumpAndSettle();
    expect(find.text('Host setup required'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(RadioListTile<String>), findsNothing);
    expect(find.text('Unlock'), findsNothing);
    expect(canStart(tester), isFalse);
    await tester.tap(find.byKey(const Key('copy-launcher-setup')));
    await tester.pump();
    expect(copied, 'remote-pi-launcher pin-setup');
    repo.security = locked();
    await vm.refresh();
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byKey(const Key('launcher-pin'))).enabled,
      isTrue,
    );
    expect(find.byType(RadioListTile<String>), findsNothing);
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
  });

  testWidgets(
    'configured PIN is editable and unlock reveals approved projects',
    (tester) async {
      final repo = _UnlockRepo()..security = locked();
      final vm = AgentsViewModel(repo);
      await tester.pumpWidget(page(vm));
      await tester.pumpAndSettle();
      final pin = find.byKey(const Key('launcher-pin'));
      final controller = tester.widget<TextField>(pin).controller!;
      expect(tester.widget<TextField>(pin).enabled, isTrue);
      expect(tester.widget<TextField>(pin).obscureText, isTrue);
      expect(tester.widget<TextField>(pin).autofillHints, isEmpty);
      expect(find.byType(RadioListTile<String>), findsNothing);
      await tester.enterText(pin, '123456');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Unlock'));
      await tester.pumpAndSettle();
      expect(repo.unlocks, 1);
      expect(controller.text, isEmpty);
      expect(find.byKey(const Key('launcher-pin')), findsNothing);
      expect(find.text('Registered project'), findsOneWidget);
      await selectProject(tester);
      expect(canStart(tester), isTrue);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    },
  );

  testWidgets('PIN clears on background, disposal and target replacement', (
    tester,
  ) async {
    final repo = Repo()..security = locked();
    final vm = AgentsViewModel(repo);
    await tester.pumpWidget(page(vm));
    await tester.pumpAndSettle();
    final pin = find.byKey(const Key('launcher-pin'));
    final controller = tester.widget<TextField>(pin).controller!;
    await tester.enterText(pin, '123456');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(controller.text, isEmpty);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.enterText(pin, '123456');
    await tester.pumpWidget(page(vm, room: 'other'));
    await tester.pumpAndSettle();
    expect(controller.text, isEmpty);
    expect(vm.state.invalid, isTrue);
    expect(canStart(tester), isFalse);
    expect(find.byType(RadioListTile<String>), findsNothing);
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
  });

  testWidgets('changed project access or host epoch clears selection', (
    tester,
  ) async {
    final repo = Repo();
    final vm = AgentsViewModel(repo);
    await tester.pumpWidget(page(vm));
    await tester.pumpAndSettle();
    await selectProject(tester);
    expect(canStart(tester), isTrue);
    repo.projectCatalog = const [
      LauncherProject('project', 'Registered project', '/project', [
        '/different',
      ]),
    ];
    await vm.refresh();
    await tester.pumpAndSettle();
    expect(canStart(tester), isFalse);
    expect(
      tester
          .widget<RadioGroup<String>>(find.byType(RadioGroup<String>))
          .groupValue,
      isNull,
    );
    await selectProject(tester);
    repo.security = LauncherStatus(
      launcherId: 'launcher-1',
      epoch: 'epoch-2',
      configured: true,
      unlocked: true,
      expiresAt: DateTime.now().millisecondsSinceEpoch + 600000,
      cooldownUntil: 0,
    );
    await vm.refresh();
    await tester.pumpAndSettle();
    expect(canStart(tester), isFalse);
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
  });

  testWidgets('start confirms project/access/lifetime without optional name', (
    tester,
  ) async {
    final repo = Repo();
    final vm = AgentsViewModel(repo);
    await tester.pumpWidget(page(vm));
    await tester.pumpAndSettle();
    await selectProject(tester);
    expect(find.text('Name (optional)'), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Start agent'));
    await tester.pumpAndSettle();
    expect(find.textContaining('/project'), findsWidgets);
    expect(find.textContaining('Access: /shared'), findsOneWidget);
    expect(find.textContaining('launcher closes or reloads'), findsOneWidget);
    expect(repo.launches, 0);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repo.launches, 0);
    await tester.tap(find.widgetWithText(FilledButton, 'Start agent'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Start'));
    await tester.pumpAndSettle();
    expect(repo.launches, 1);
    expect(find.text('Managed agents'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
  });

  testWidgets(
    'management is separate; failed owned agent has confirmed cleanup retry',
    (tester) async {
      final repo = Repo()
        ..availability = const AgentAvailability(
          available: true,
          cwd: '/p',
          maxAgents: 4,
          agents: [
            ManagedAgent(
              agentId: 'failed-live',
              name: 'Failed Pi',
              cwd: '/p',
              roomId: 'failed-room',
              state: 'failed',
              error: 'Cleanup failed',
            ),
          ],
        );
      final vm = AgentsViewModel(repo);
      await tester.pumpWidget(page(vm));
      await tester.pumpAndSettle();
      expect(find.text('Stop'), findsNothing);
      await openRunning(tester);
      expect(find.text('Failed Pi'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Stop'));
      await tester.pumpAndSettle();
      expect(find.text('Stop agent?'), findsOneWidget);
      expect(repo.stops, 0);
      await tester.tap(find.widgetWithText(FilledButton, 'Stop'));
      await tester.pumpAndSettle();
      expect(repo.stops, 1);
      expect(repo.shutdowns, 0);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    },
  );

  testWidgets('Lock access is secondary and never stops processes', (
    tester,
  ) async {
    final repo = Repo();
    final vm = AgentsViewModel(repo);
    await tester.pumpWidget(page(vm));
    await tester.pumpAndSettle();
    expect(find.text('Lock access'), findsNothing);
    await tester.tap(find.byTooltip('Agent options'));
    await tester.pumpAndSettle();
    expect(find.text('Stop all and lock'), findsNothing);
    await tester.tap(find.text('Lock access'));
    await tester.pumpAndSettle();
    expect(repo.locks, 1);
    expect(repo.shutdowns, 0);
    expect(repo.stops, 0);
    expect(find.byKey(const Key('launcher-pin')), findsOneWidget);
    expect(find.byType(RadioListTile<String>), findsNothing);
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
  });

  testWidgets(
    'unknown start needs reconciliation and explicit duplicate-risk confirmation',
    (tester) async {
      final repo = Repo();
      final vm = AgentsViewModel(repo);
      await tester.pumpWidget(page(vm));
      await tester.pumpAndSettle();
      await selectProject(tester);
      repo.pending = Completer<ManagedAgent>();
      final launch = vm.launch('project', null, confirmed: true);
      repo.pending!.completeError(
        const AgentFailure('Timed out', outcomeUnknown: true),
      );
      await launch;
      await tester.pumpAndSettle();
      expect(canStart(tester), isFalse);
      repo.listFails = true;
      await vm.refresh();
      await tester.pumpAndSettle();
      expect(canStart(tester), isFalse);
      repo.listFails = false;
      await vm.refresh();
      await tester.pumpAndSettle();
      expect(canStart(tester), isTrue);
      await tester.tap(find.widgetWithText(FilledButton, 'Start agent'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Starting another may create a second agent'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repo.launches, 1);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    },
  );

  testWidgets('unavailable and empty catalogs have no dead creation fields', (
    tester,
  ) async {
    final repo = Repo()
      ..availability = const AgentAvailability(
        available: false,
        reason: 'Not allowed',
        cwd: '/p',
        maxAgents: 4,
        agents: [],
      );
    final vm = AgentsViewModel(repo);
    await tester.pumpWidget(page(vm));
    await tester.pumpAndSettle();
    expect(find.text('Not allowed'), findsOneWidget);
    expect(find.byType(RadioListTile<String>), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Start agent'), findsNothing);
    repo.availability = const AgentAvailability(
      available: true,
      cwd: '/p',
      maxAgents: 4,
      agents: [],
    );
    repo.projectCatalog = [];
    await vm.refresh();
    await tester.pumpAndSettle();
    expect(find.text('No approved projects on this PC.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Start agent'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
  });
}
