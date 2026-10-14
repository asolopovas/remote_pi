import 'dart:async';
import 'package:app/domain/contracts/agent_repository.dart';
import 'package:app/ui/agents/agents_page.dart';
import 'package:app/ui/agents/viewmodels/agents_viewmodel.dart';
import 'package:app/ui/core/themes/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'agents_viewmodel_test.dart' show Repo;

Future<void> selectProject(WidgetTester tester) async {
  await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Registered project').last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Lock does not stop agents; shutdown requires Owner-scoped confirmation',
    (tester) async {
      final repo = Repo();
      final vm = AgentsViewModel(repo);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: MaterialApp(
            theme: buildDarkTheme(),
            home: const AgentsPage(
              target: AgentsTarget('peer', 'room', 'Laptop', 'Project'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final shutdown = find.widgetWithText(
        TextButton,
        'Stop your managed agents and lock access',
      );
      await tester.ensureVisible(shutdown);
      await tester.pumpAndSettle();
      await tester.tap(shutdown);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Does not stop the OS, Relay, or other Owners'),
        findsOneWidget,
      );
      expect(repo.shutdowns, 0);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      final lock = find.widgetWithText(
        TextButton,
        'Lock (keep agents running)',
      );
      await tester.ensureVisible(lock);
      await tester.pumpAndSettle();
      await tester.tap(lock);
      await tester.pumpAndSettle();
      expect(repo.locks, 1);
      expect(repo.stops, 0);
      expect(repo.shutdowns, 0);
      await tester.ensureVisible(shutdown);
      await tester.pumpAndSettle();
      await tester.tap(shutdown);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Shut down'));
      await tester.pumpAndSettle();
      expect(repo.shutdowns, 1);
      expect(vm.state.message, 'Your managed agents stopped. Access locked.');
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    },
  );
  testWidgets('target change clears PIN and prevents control of old target', (
    tester,
  ) async {
    final repo = Repo();
    repo.security = const LauncherStatus(
      launcherId: 'launcher-1',
      epoch: 'epoch-1',
      configured: true,
      unlocked: false,
      expiresAt: null,
      cooldownUntil: 0,
    );
    final vm = AgentsViewModel(repo);
    Widget page(String room) => ChangeNotifierProvider.value(
      value: vm,
      child: MaterialApp(
        theme: buildDarkTheme(),
        home: AgentsPage(
          target: AgentsTarget('peer', room, 'Laptop', 'Project'),
        ),
      ),
    );
    await tester.pumpWidget(page('room'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(
      find.widgetWithText(TextField, 'PIN (6–12 digits)'),
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'PIN (6–12 digits)'),
      '123456',
    );
    await tester.pumpWidget(page('other'));
    await tester.pumpAndSettle();
    expect(field.controller!.text, isEmpty);
    expect(vm.state.invalid, true);
    await vm.launch('project', null, confirmed: true);
    expect(repo.launches, 0);
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
  });
  testWidgets(
    'PIN obscured, no autofill and cleared on background and disposal',
    (tester) async {
      final repo = Repo();
      repo.security = const LauncherStatus(
        launcherId: 'launcher-1',
        epoch: 'epoch-1',
        configured: true,
        unlocked: false,
        expiresAt: null,
        cooldownUntil: 0,
      );
      final vm = AgentsViewModel(repo);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: MaterialApp(
            theme: buildDarkTheme(),
            home: const AgentsPage(
              target: AgentsTarget('peer', 'room', 'Laptop', 'Project'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final pin = find.widgetWithText(TextField, 'PIN (6–12 digits)');
      final field = tester.widget<TextField>(pin);
      expect(field.obscureText, true);
      expect(field.autofillHints, isEmpty);
      await tester.enterText(pin, '123456');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      expect(field.controller!.text, isEmpty);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    },
  );
  testWidgets(
    'same ID with changed allowed folders invalidates selection, epoch changes also invalidate',
    (tester) async {
      final repo = Repo();
      final vm = AgentsViewModel(repo);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: MaterialApp(
            theme: buildDarkTheme(),
            home: const AgentsPage(
              target: AgentsTarget('peer', 'room', 'Laptop', 'Project'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await selectProject(tester);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Start agent'),
            )
            .onPressed,
        isNotNull,
      );
      repo.projectCatalog = const [
        LauncherProject('project', 'Registered project', '/project', [
          '/different',
        ]),
      ];
      await vm.refresh();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Start agent'),
            )
            .onPressed,
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
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Start agent'),
            )
            .onPressed,
        isNull,
      );
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    },
  );
  testWidgets('failed agent exposes confirmed cleanup retry', (tester) async {
    final repo = Repo();
    repo.availability = const AgentAvailability(
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
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: vm,
        child: MaterialApp(
          theme: buildDarkTheme(),
          home: const AgentsPage(
            target: AgentsTarget('peer', 'room', 'Laptop', 'Project'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(TextButton, 'Stop'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Stop'));
    await tester.pumpAndSettle();
    expect(find.text('Stop Failed Pi?'), findsOneWidget);
    expect(repo.stops, 0);
    await tester.tap(find.widgetWithText(FilledButton, 'Stop'));
    await tester.pumpAndSettle();
    expect(repo.stops, 1);
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
  });
  testWidgets('unknown outcome disables Start until list refresh succeeds', (
    tester,
  ) async {
    final repo = Repo();
    final vm = AgentsViewModel(repo);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: vm,
        child: MaterialApp(
          theme: buildDarkTheme(),
          home: const AgentsPage(
            target: AgentsTarget('peer', 'room', 'Laptop', 'Project'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await selectProject(tester);
    repo.pending = Completer<ManagedAgent>();
    final launch = vm.launch('/p', null, confirmed: true);
    repo.pending!.completeError(
      const AgentFailure(
        'Timed out; refresh before retry',
        outcomeUnknown: true,
      ),
    );
    await launch;
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Start agent'),
          )
          .onPressed,
      null,
    );
    repo.listFails = true;
    await vm.refresh();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Start agent'),
          )
          .onPressed,
      null,
    );
    repo.listFails = false;
    await vm.refresh();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Start agent'),
          )
          .onPressed,
      isNotNull,
    );
    expect(repo.launches, 1);
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Start agent'),
    );
    await tester.pumpAndSettle();
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
  });

  testWidgets(
    'explicit host, default directory, trust/lifetime confirmation and cancel',
    (tester) async {
      final repo = Repo();
      final subject = AgentsViewModel(repo);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: subject,
          child: MaterialApp(
            theme: buildDarkTheme(),
            home: const AgentsPage(
              target: AgentsTarget('peer', 'room', 'Laptop', 'Project'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Host: Laptop'), findsOneWidget);
      await selectProject(tester);
      expect(
        find.textContaining('Allowed folders:\n/project\n/shared'),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Start agent'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Start agent'));
      await tester.pumpAndSettle();
      expect(find.textContaining('local code you trust'), findsOneWidget);
      expect(find.textContaining('survives phone disconnects'), findsOneWidget);
      expect(
        find.textContaining('session is replaced, resumed or reloaded'),
        findsOneWidget,
      );
      expect(repo.launches, 0);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repo.launches, 0);
      await tester.tap(find.widgetWithText(FilledButton, 'Start agent'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Start'));
      await tester.pumpAndSettle();
      expect(repo.launches, 1);
      expect(subject.state.message, contains('Waiting for room discovery'));
      await tester.ensureVisible(find.text('Stop'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();
      expect(repo.stops, 0);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repo.stops, 0);
      await tester.pumpWidget(const SizedBox());
      subject.dispose();
    },
  );
  testWidgets('unavailable reason disables Start', (tester) async {
    final repo = Repo();
    repo.availability = const AgentAvailability(
      available: false,
      reason: 'Not allowed',
      cwd: '/p',
      maxAgents: 4,
      agents: [],
    );
    final vm = AgentsViewModel(repo);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: vm,
        child: MaterialApp(
          theme: buildDarkTheme(),
          home: const AgentsPage(
            target: AgentsTarget('peer', 'room', 'Laptop', 'Project'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Unavailable: Not allowed'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Start agent'),
          )
          .onPressed,
      null,
    );
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
  });
}
