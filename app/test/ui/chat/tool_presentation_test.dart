import 'dart:convert';

import 'package:app/domain/session_state.dart';
import 'package:app/ui/chat/widgets/tool_request_card.dart';
import 'package:app/ui/chat/widgets/source_code.dart';
import 'package:app/ui/chat/widgets/codemode_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/ui/chat/widgets/tool_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'read output uses file syntax and exact whitespace/copy while arguments are human-readable',
    (tester) async {
      const source = 'def example():\n\treturn "literal\\n"\n';
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
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ToolRequestCard(
              tool: ToolEvent(
                id: 'source',
                toolCallId: 'source',
                tool: 'read',
                args: {'path': 'example.py', 'offset': 1},
                status: ToolEventStatus.completed,
                result: source,
              ),
            ),
          ),
        ),
      );
      expect(find.byType(SourceCode), findsNothing);
      await tester.tap(find.byKey(const Key('tool-disclosure')));
      await tester.pump();
      final output = tester.widget<SourceCode>(find.byType(SourceCode));
      expect(output.language, 'py');
      expect(output.source, source);
      expect(find.text('path: example.py\noffset: 1'), findsOneWidget);
      await tester.tap(find.byTooltip('Copy output'));
      await tester.pump();
      expect(copied, source);
      expect(tester.takeException(), isNull);
    },
  );

  test('tool fields are readable without decoding code or string JSON', () {
    expect(
      toolFields({'path': 'lib/main.dart', 'offset': 12}),
      'path: lib/main.dart\noffset: 12',
    );
    expect(
      toolFields({'from': 'agent', 'message': 'first\n  second'}),
      'from: agent\nmessage: first\n  second',
    );
    expect(
      toolFields({
        'exit_code': 2,
        'items': ['one', 'two'],
      }),
      'exit code: 2\nitems:\n  • one\n  • two',
    );
    const source = '  {"output":"literal\\n"}\n\t';
    expect(toolFields(source), source);
  });

  test(
    'large field sets fall back to complete JSON instead of dropping data',
    () {
      final result = toolFields(List.generate(513, (i) => 'value $i'));
      expect(result, startsWith('[\n'));
      expect(result, contains('value 512'));
    },
  );

  test(
    'compact shell output retains failures and truncation, not routine timing',
    () {
      Map<String, Object> shell(String output, int exit, bool truncated) => {
        'output': output,
        'exit_code': exit,
        'truncated': truncated,
        'wall_time_seconds': 2.5,
      };
      expect(
        readableToolOutput('bash', shell('  one\n\ttwo\n', 0, false)),
        '  one\n\ttwo\n',
      );
      expect(readableToolOutput('bash', shell('', 0, false)), 'Completed.');
      expect(
        readableToolOutput('bash', shell('failure', 2, true)),
        'Exit code 2 · Output truncated\nfailure',
      );
      expect(readableToolOutput('bash', shell('', 2, false)), 'Exit code 2');
      final stored = {
        ...shell('partial\n', 0, true),
        'full_output_path': '/tmp/full-output.txt',
      };
      for (final value in [stored, jsonEncode(stored)]) {
        expect(
          readableToolOutput('bash', value),
          'Output truncated\nFull output: /tmp/full-output.txt\npartial\n',
        );
      }
      final duplicate = jsonEncode(stored).replaceFirst(
        '"full_output_path":',
        '"full_output_path":"other","full_output_path":',
      );
      expect(readableToolOutput('bash', duplicate), isNull);
      expect(
        readableToolOutput('bash', {...stored, 'full_output_path': 42}),
        isNull,
      );
    },
  );
}
