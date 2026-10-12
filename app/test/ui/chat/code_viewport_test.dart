import 'package:app/ui/chat/widgets/code_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));
Widget code(String text, {Key? key}) =>
    CodeViewport(key: key, label: 'dart', text: text, child: Text(text));
void main() {
  test(
    'optional composite wrap width rejects nonpositive and nonfinite values',
    () {
      for (final width in [
        0.0,
        -1.0,
        double.infinity,
        double.negativeInfinity,
        double.nan,
      ]) {
        expect(
          () => CodeViewport(
            text: '',
            bodyWrapWidth: width,
            child: const SizedBox(),
          ),
          throwsAssertionError,
        );
      }
      expect(
        const CodeViewport(
          text: '',
          bodyWrapWidth: 320,
          child: SizedBox(),
        ).bodyWrapWidth,
        320,
      );
    },
  );
  testWidgets(
    'exact title/count, default wrapping, streaming updates and full clipboard',
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
      await tester.pumpWidget(wrap(code('one\ntwo')));
      expect(find.text('dart · 2 lines'), findsOneWidget);
      expect(find.text('one\ntwo'), findsNothing);
      await tester.tap(find.text('dart · 2 lines'));
      await tester.pump();
      expect(find.byTooltip('Scroll horizontally'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsNothing);
      await tester.tap(find.byKey(const Key('code-wrap')));
      await tester.pump();
      expect(find.byTooltip('Wrap code'), findsOneWidget);
      await tester.pumpWidget(wrap(code('one\ntwo\nthree')));
      expect(find.text('dart · 3 lines'), findsOneWidget);
      expect(find.text('one\ntwo\nthree'), findsOneWidget);
      expect(find.byTooltip('Wrap code'), findsOneWidget);
      await tester.tap(find.byKey(const Key('code-copy')));
      await tester.pump();
      expect(copied, 'one\ntwo\nthree');
      expect(find.text('one\ntwo\nthree'), findsOneWidget);
      await tester.tap(find.text('dart · 3 lines'));
      await tester.pump();
      expect(find.text('one\ntwo\nthree'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'lazy list preserves toggles, releases untouched defaults and scopes identity',
    (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      String scope = 'peer1/session1';
      Future<void> pump() => tester.pumpWidget(
        wrap(
          ListView.builder(
            key: ValueKey(scope),
            controller: scroll,
            scrollCacheExtent: const ScrollCacheExtent.pixels(0),
            itemCount: 60,
            itemBuilder: (_, index) => SizedBox(
              height: 160,
              child: code('body $index', key: ValueKey(index)),
            ),
          ),
        ),
      );
      await pump();
      await tester.tap(find.byKey(const Key('code-disclosure')).first);
      await tester.pump();
      await tester.tap(find.byKey(const Key('code-wrap')).first);
      await tester.pump();
      final untouched = tester.state(find.byType(CodeViewport).at(1));
      scroll.jumpTo(5000);
      await tester.pumpAndSettle();
      expect(
        untouched.mounted,
        isFalse,
        reason: 'default wrapped bodies must not pin lazy rows',
      );
      scroll.jumpTo(0);
      await tester.pumpAndSettle();
      expect(find.text('body 0'), findsOneWidget);
      expect(find.byTooltip('Wrap code'), findsOneWidget);
      scope = 'peer2/session1';
      await pump();
      expect(find.text('body 0'), findsNothing);
      await tester.tap(find.byKey(const Key('code-disclosure')).first);
      await tester.pump();
      scope = 'peer2/session2';
      await pump();
      expect(find.text('body 0'), findsNothing);
    },
  );
  testWidgets(
    'narrow large text controls do not consume disclosure/title width',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        wrap(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: ListView(children: [code('long line ' * 60)]),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('code-disclosure')));
      await tester.pump();
      expect(find.byTooltip('Scroll horizontally'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
