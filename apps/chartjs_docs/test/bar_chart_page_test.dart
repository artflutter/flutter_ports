// Original code, not ported from Chart.js: the tests of the bar chart page.
@TestOn('vm')
library;

import 'dart:io';

import 'package:chartjs_docs/examples/bar_examples.dart';
import 'package:chartjs_docs/examples/line_examples.dart';
import 'package:chartjs_docs/main.dart';
import 'package:chartjs_docs/pages/bar_chart_page.dart';
import 'package:chartjs_docs/ui/snippets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The page shows the region `register` of the line examples too.
final Snippets _snippets = Snippets.parseAll([
  File(examplesAsset).readAsStringSync(),
  File(barExamplesAsset).readAsStringSync(),
]);

/// Each form of the examples with more than one form.
const List<String> _variants = [
  'general.grouped: false',
  'general.skipNull',
  'general.base',
  'styling.minBarLength',
  'styling.Shadow',
  'border-skipped..end',
  'border-skipped.false',
  'border-skipped.true',
  'border-width.Object',
  'border-radius.All corners',
  'border-radius.Object',
  'border-radius.Stacked',
  'bar-thickness.12',
  "bar-thickness.'flex'",
  'grid-offset.offset: false',
  'percentages.category 1.0 · bar 0.5',
  'percentages.category 0.5 · bar 1.0',
  'data.points',
  'stacked.Two stacks',
];

Future<void> _show(WidgetTester tester, Size size) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    DocsApp(snippets: _snippets, initialRoute: '/charts/bar'),
  );
  await tester.pump(const Duration(seconds: 2));
  await tester.pump(const Duration(seconds: 2));
}

Object? _read(Object? scope, String key) => (scope! as JsObjectFace)[key];

/// The scope and the key of the default of each row with a chart default.
final Map<String, (Object?, String)> _defaultsOf = () {
  final bar = _read(_read(defaults, 'elements'), 'bar');
  final dataset = _read(_read(defaults, 'datasets'), 'bar');
  return <String, (Object?, String)>{
    'barPercentage': (dataset, 'barPercentage'),
    'borderRadius': (bar, 'borderRadius'),
    'borderSkipped': (bar, 'borderSkipped'),
    'borderWidth': (bar, 'borderWidth'),
    'categoryPercentage': (dataset, 'categoryPercentage'),
    'grouped': (dataset, 'grouped'),
    'inflateAmount': (bar, 'inflateAmount'),
  };
}();

bool _sameDefault(Object? actual, String text) => switch (actual) {
  final num value => value == num.parse(text),
  final String value => "'$value'" == text,
  // An enum value, for example `BorderSkippedEdge.start`.
  final Enum value => '$value' == text,
  final bool value => '$value' == text,
  _ => false,
};

void main() {
  setUpAll(registerCharts);

  for (final size in const [Size(1440, 900), Size(800, 900), Size(412, 915)]) {
    testWidgets('the page builds at $size', (tester) async {
      await _show(tester, size);
      expect(tester.takeException(), isNull);
      expect(find.text('Bar Chart'), findsWidgets);
    });
  }

  testWidgets('each form of the examples draws', (tester) async {
    await _show(tester, const Size(1440, 900));
    for (final variant in _variants) {
      final chip = find.byKey(ValueKey(variant));
      await tester.ensureVisible(chip);
      await tester.pump();
      await tester.tap(chip);
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull, reason: variant);
    }
  });

  testWidgets('a navigation link moves its section into view', (tester) async {
    await _show(tester, const Size(1440, 900));
    // The outline is longer than the sidebar: scroll the sidebar first.
    final link = find.byKey(const ValueKey('nav.data-structure'));
    await tester.ensureVisible(link);
    await tester.pump();
    final heading = find.text('Data Structure').last;
    final before = tester.getTopLeft(heading).dy;
    await tester.tap(link);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final after = tester.getTopLeft(heading).dy;
    expect(after, lessThan(before));
    expect(after, inInclusiveRange(0, 200));
  });

  testWidgets('the sidebar opens the bar chart page', (tester) async {
    tester.view
      ..physicalSize = const Size(1440, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(DocsApp(snippets: _snippets));
    await tester.pump(const Duration(seconds: 1));
    final link = find.byKey(const ValueKey('page./charts/bar'));
    await tester.ensureVisible(link);
    await tester.pump();
    await tester.tap(link);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Bar Chart'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  test('the table gives the defaults of the chart', () {
    for (final row in barProperties) {
      final source = _defaultsOf[row.name];
      if (source == null) continue;
      final (scope, key) = source;
      expect(
        _sameDefault(_read(scope, key), row.fallback),
        isTrue,
        reason: row.name,
      );
    }
    expect(
      _defaultsOf.keys,
      everyElement(isIn(barProperties.map((r) => r.name))),
    );
  });

  test('each row without extra is a parameter of BarDataset', () {
    // The compiler checks each name of this call.
    const dataset = BarDataset(
      backgroundColor: .constant(.solid(teal)),
      barPercentage: 1,
      barThickness: 1,
      borderColor: .constant(.solid(teal)),
      borderRadius: 1,
      borderWidth: 1,
      categoryPercentage: 1,
      clip: ChartClip.none,
      data: [1],
      grouped: true,
      hoverBackgroundColor: .constant(.solid(teal)),
      hoverBorderColor: .constant(.solid(teal)),
      hoverBorderWidth: 1,
      indexAxis: XAxis(),
      label: '',
      maxBarThickness: 1,
      minBarLength: 1,
      order: 0,
      shadow: ChartShadow(color: teal),
      stack: '',
      xAxisID: '',
      yAxisID: '',
    );
    expect(dataset.label, '');
    final named = {
      'backgroundColor',
      'barPercentage',
      'barThickness',
      'borderColor',
      'borderRadius',
      'borderWidth',
      'categoryPercentage',
      'clip',
      'data',
      'grouped',
      'hoverBackgroundColor',
      'hoverBorderColor',
      'hoverBorderWidth',
      'indexAxis',
      'label',
      'maxBarThickness',
      'minBarLength',
      'order',
      'points',
      'shadow',
      'stack',
      'xAxisID',
      'yAxisID',
    };
    expect(
      barProperties.where((row) => !row.extra).map((row) => row.name).toSet(),
      named,
    );
  });

  test('the sample of the default options sets a default', () {
    final bar = _read(Chart.jsClass['overrides'], 'bar')! as JsObjectFace;
    addTearDown(() => bar['skipNull'] = undefined);
    skipNullInAllBarCharts();
    expect(bar['skipNull'], isTrue);
  });

  test('the region names are unique over the source files', () {
    expect(_snippets['bar-basic'], contains('BarDataset('));
    for (final name in _snippets.names) {
      expect(_snippets[name], isNot(contains('docregion')), reason: name);
    }
  });
}
