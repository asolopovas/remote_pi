import 'package:app/ui/chat/widgets/compact_output_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('short status leaves title its intrinsic remaining width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 160));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: CompactOutputHeader(
              title: 'A command title that should remain readable',
              status: 'DONE',
              expanded: false,
              disclosureKey: Key('header'),
              onToggle: _noop,
            ),
          ),
        ),
      ),
    );
    final title = tester.getRect(
      find.text('A command title that should remain readable'),
    );
    final status = tester.getRect(find.text('DONE'));
    expect(status.width, lessThan(80));
    expect(title.width, greaterThan(status.width * 2));
    expect(status.left, greaterThan(title.left));
    expect(tester.takeException(), isNull);
  });

  testWidgets('long status remains bounded at narrow width and 2x text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 180));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SizedBox(
              width: 280,
              child: CompactOutputHeader(
                title: 'A long command title that is allowed to truncate',
                status: 'FAILED WITH A VERY LONG STATUS DESCRIPTION',
                expanded: true,
                disclosureKey: Key('header'),
                onToggle: _noop,
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(const Key('header'))).height,
      greaterThanOrEqualTo(48),
    );
  });
}

void _noop() {}
