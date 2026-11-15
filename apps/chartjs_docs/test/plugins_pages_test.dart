// Original code, not ported from Chart.js: the tests of the plugin pages.
@TestOn('vm')
library;

import 'dart:io';

import 'package:chartjs_docs/examples/line_examples.dart';
import 'package:chartjs_docs/main.dart';
import 'package:chartjs_docs/ui/dartpad.dart';
import 'package:chartjs_docs/ui/snippets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/file_sources.dart';

Future<void> _open(
  WidgetTester tester,
  String route, {
  double width = 1400,
}) async {
  tester.view
    ..physicalSize = Size(width, 1000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(DocsApp(sources: fileSources(), initialRoute: route));
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUpAll(registerCharts);

  for (final route in ['/plugins', '/plugins/zoom']) {
    for (final width in [1400.0, 390.0]) {
      testWidgets('$route builds at the width $width', (tester) async {
        await _open(tester, route, width: width);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('the overview opens the docs of the zoom plugin', (tester) async {
    await _open(tester, '/plugins');
    final button = find.text('Read the docs');
    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Installation'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the zoom example opens in DartPad and resets', (tester) async {
    await _open(tester, '/plugins/zoom');
    final link = tester.widget<DartPadLink>(
      find.byKey(const ValueKey('zoom-usage.dartpad'), skipOffstage: false),
    );
    expect(link.file, '$zoomExamples/usage.dart');
    expect(File(link.file).readAsStringSync(), contains('\nvoid main() {'));
    final reset = find.byKey(const ValueKey('zoom-usage.action.0'));
    await tester.ensureVisible(reset);
    await tester.pump();
    await tester.tap(reset);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}
