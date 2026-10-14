import 'dart:async';
import 'package:app/domain/contracts/agent_repository.dart';
import 'package:app/ui/agents/agents_page.dart';
import 'package:app/ui/agents/viewmodels/agents_viewmodel.dart';
import 'package:app/ui/core/themes/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'agents_viewmodel_test.dart' show Repo;

void main() {
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
      expect(find.text('/project'), findsOneWidget);
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
      expect(find.textContaining('Waiting for room discovery'), findsOneWidget);
      await tester.ensureVisible(find.text('Stop'));
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
