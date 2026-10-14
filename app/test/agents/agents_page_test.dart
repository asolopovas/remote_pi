import 'package:app/domain/contracts/agent_repository.dart';
import 'package:app/ui/agents/agents_page.dart';
import 'package:app/ui/agents/viewmodels/agents_viewmodel.dart';
import 'package:app/ui/core/themes/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'agents_viewmodel_test.dart' show Repo;

void main() {
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
