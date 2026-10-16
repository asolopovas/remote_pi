import 'package:app/domain/session_state.dart';
import 'package:app/ui/chat/widgets/compact_output_header.dart';
import 'package:app/ui/chat/widgets/read_activity_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' show Tristate;
import 'package:flutter_test/flutter_test.dart';

ToolEvent read(
  String id,
  String path, {
  ToolEventStatus status = ToolEventStatus.completed,
}) => ToolEvent(
  id: id,
  toolCallId: id,
  tool: 'functions.read',
  args: {'path': path},
  status: status,
  result: 'file contents $id',
);

void main() {
  test(
    'groups adjacent reads without losing invocation identity or errors',
    () {
      final first = read('one', 'lib/main.dart');
      final rows = activityRows([
        first,
        read('two', 'lib/main.dart'),
        const ToolEvent(id: 'edit', toolCallId: 'edit', tool: 'edit', args: {}),
        read('three', 'lib/other.dart', status: ToolEventStatus.failed),
      ]);
      expect(rows.length, 3);
      expect((rows.first as List<ToolEvent>).first, same(first));
      expect((rows.first as List<ToolEvent>).length, 2);
      expect(
        (rows.last as List<ToolEvent>).single.status,
        ToolEventStatus.failed,
      );
    },
  );

  testWidgets(
    'read contents are opt-in; path summary and changed hint remain compact',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadActivityGroup(
              reads: [
                read('one', 'lib/main.dart'),
                read('two', 'lib/main.dart'),
              ],
              changedPaths: const {'lib/main.dart'},
            ),
          ),
        ),
      );
      expect(
        find.textContaining('Read 1 file · 1 also edited · lib/main.dart'),
        findsOneWidget,
      );
      expect(find.text('file contents one'), findsNothing);
      await tester.tap(find.byKey(const Key('code-disclosure')));
      await tester.pumpAndSettle();
      expect(find.text('file contents one'), findsNothing);
      await tester.tap(find.byKey(const Key('tool-disclosure')).first);
      await tester.pumpAndSettle();
      expect(find.text('file contents one'), findsOneWidget);
      expect(find.text('file contents two'), findsNothing);
    },
  );

  testWidgets(
    'disclosure supports keyboard activation, arrows, semantics and stable focus',
    (tester) async {
      final semantics = tester.ensureSemantics();
      bool expanded = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => CompactOutputHeader(
                title: 'EDIT · lib/main.dart',
                expanded: expanded,
                disclosureKey: const Key('header'),
                onToggle: () => setState(() => expanded = !expanded),
              ),
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      final focus = FocusManager.instance.primaryFocus;
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(expanded, isTrue);
      expect(
        tester
            .getSemantics(find.byKey(const Key('header')))
            .getSemanticsData()
            .flagsCollection
            .isExpanded,
        Tristate.isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(expanded, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(expanded, isTrue);
      expect(FocusManager.instance.primaryFocus, same(focus));
      semantics.dispose();
      await tester.pumpWidget(const SizedBox());
    },
  );
}
