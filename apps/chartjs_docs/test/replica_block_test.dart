// Original code, not ported from Chart.js: the tests of the replica block.
@TestOn('vm')
library;

import 'package:chartjs_docs/examples/line_examples.dart';
import 'package:chartjs_docs/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/file_sources.dart';

void main() {
  setUpAll(registerCharts);

  testWidgets('the DartPad and Original links share one line at the right', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1400, 1000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      DocsApp(
        sources: fileSources(),
        initialRoute: '/charts/line/migrate/shadcn',
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    const id = 'shadcn-line-default';
    final dartPad = tester.getRect(find.byKey(const ValueKey('$id.dartpad')));
    final original = tester.getRect(
      find.ancestor(
        of: find.descendant(
          of: find.ancestor(
            of: find.byKey(const ValueKey('$id.dartpad')),
            matching: find.byType(Wrap),
          ),
          matching: find.text('Original'),
        ),
        matching: find.byType(TextButton),
      ),
    );
    final code = tester.getRect(find.byKey(const ValueKey('$id.code')));
    expect(original.center.dy, moreOrLessEquals(dartPad.center.dy));
    expect(original.left, greaterThanOrEqualTo(dartPad.right));
    expect(dartPad.center.dy, moreOrLessEquals(code.center.dy, epsilon: 1));
  });
}
