import 'package:app/domain/session_state.dart';
import 'package:app/ui/chat/widgets/compact_output_header.dart';
import 'package:app/ui/chat/widgets/activity_presentation.dart';
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
  test('all read states stay out of the feed; changes retain identity', () {
    const edit = ToolEvent(
      id: 'edit',
      toolCallId: 'edit',
      tool: 'edit',
      args: {},
    );
    final rows = activityRows([
      for (final status in ToolEventStatus.values)
        read('$status', 'lib/main.dart', status: status),
      const ToolEvent(
        id: 'symbol',
        toolCallId: 'symbol',
        tool: 'read_symbol',
        args: {},
      ),
      const ToolEvent(
        id: 'enclosing',
        toolCallId: 'enclosing',
        tool: 'functions.read_enclosing',
        args: {},
      ),
      edit,
    ]);
    expect(rows, [same(edit)]);
  });

  test('only the current running read appears in status', () {
    final running = read(
      'one',
      'lib/main.dart',
      status: ToolEventStatus.allowed,
    );
    expect(activeReadLabel([running]), 'Reading lib/main.dart…');
    expect(activeReadLabel([read('one', 'lib/main.dart')]), isNull);
    expect(
      activeReadLabel([
        running,
        const ToolEvent(id: 'edit', toolCallId: 'edit', tool: 'edit', args: {}),
      ]),
      isNull,
    );
    expect(
      activeReadLabel([read('one', '', status: ToolEventStatus.pending)]),
      'Reading…',
    );
    expect(activeReadLabel([]), isNull);
  });

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
