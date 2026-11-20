// Original code, not ported from Chart.js: the tests of the ergonomics app.
@TestOn('vm')
library;

import 'dart:io';

import 'package:chartjs_ergonomics/main.dart';
import 'package:chartjs_ergonomics/samples/line/index.dart';
import 'package:chartjs_ergonomics/ui/code_region.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Chart.register(registerables);

  test('each sample file has a region and an entry, in the list order', () {
    final files = Directory(lineFolder)
        .listSync()
        .map((entry) => entry.uri.pathSegments.last)
        .where((name) => name.endsWith('.dart'))
        .map((name) => name.substring(0, name.length - 5))
        .where((name) => name != 'index')
        .toSet();
    final listed = [for (final sample in lineSamples) sample.file];
    expect(listed.toSet(), hasLength(listed.length), reason: 'duplicates');
    expect({...listed, 'data'}, files);
    for (final file in files) {
      final source = File('$lineFolder/$file.dart').readAsStringSync();
      expect(codeRegion(source), isNotEmpty, reason: file);
    }
  });

  for (final sample in lineSamples) {
    testWidgets('${sample.file} draws with no error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(width: 700, child: sample.child),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
      expect(find.byType(ChartView), findsOneWidget);
    });
  }

  testWidgets('the page shows the shared data and the first sample', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(900, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ErgonomicsApp());
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Shared data'), findsOneWidget);
    expect(find.text('1. Minimal line'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
