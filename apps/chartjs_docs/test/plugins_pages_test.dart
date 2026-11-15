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

  for (final width in [1400.0, 390.0]) {
    testWidgets('/plugins/zoom builds at the width $width', (tester) async {
      await _open(tester, '/plugins/zoom', width: width);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the plugin group has no overview page', (tester) async {
    await _open(tester, '/plugins/zoom');
    expect(find.text('AWESOME PLUGINS'), findsOneWidget);
    expect(find.text('Overview'), findsNothing);
    expect(find.byKey(const ValueKey('page./plugins')), findsNothing);
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
