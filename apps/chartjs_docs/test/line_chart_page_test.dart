// Original code, not ported from Chart.js: the tests of the line chart page.
@TestOn('vm')
library;

import 'dart:io';

import 'package:chartjs_docs/examples/line_examples.dart';
import 'package:chartjs_docs/main.dart';
import 'package:chartjs_docs/pages/line_chart_page.dart';
import 'package:chartjs_docs/ui/snippets.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

final Snippets _snippets = Snippets.parse(
  File(examplesAsset).readAsStringSync(),
);

/// Each form of the examples with more than one form.
const List<String> _variants = [
  'point-styling.rect',
  'point-styling.star',
  'line-styling.Dashed',
  'line-styling.Filled',
  'line-styling.Points only',
  'gaps.spanGaps: true',
  'stepped.true',
  'stepped..before',
  'stepped..after',
  'stepped..middle',
  'data.points',
];

Future<void> _show(WidgetTester tester, Size size) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(DocsApp(snippets: _snippets));
  await tester.pump(const Duration(seconds: 2));
  await tester.pump(const Duration(seconds: 2));
}

Object? _read(Object? scope, String key) => (scope! as JsObjectFace)[key];

/// The scope and the key of the default of each row with a chart default.
final Map<String, (Object?, String)> _defaultsOf = () {
  final elements = _read(defaults, 'elements');
  final line = _read(elements, 'line');
  final point = _read(elements, 'point');
  return <String, (Object?, String)>{
    'borderCapStyle': (line, 'borderCapStyle'),
    'borderDash': (line, 'borderDash'),
    'borderDashOffset': (line, 'borderDashOffset'),
    'borderJoinStyle': (line, 'borderJoinStyle'),
    'borderWidth': (line, 'borderWidth'),
    'cubicInterpolationMode': (line, 'cubicInterpolationMode'),
    'fill': (line, 'fill'),
    'tension': (line, 'tension'),
    'pointBorderWidth': (point, 'borderWidth'),
    'pointHitRadius': (point, 'hitRadius'),
    'pointHoverBorderWidth': (point, 'hoverBorderWidth'),
    'pointHoverRadius': (point, 'hoverRadius'),
    'pointRadius': (point, 'radius'),
    'pointRotation': (point, 'rotation'),
    'pointStyle': (point, 'pointStyle'),
  };
}();

bool _sameDefault(Object? actual, String text) => switch (actual) {
  final num value => value == num.parse(text),
  final String value => "'$value'" == text,
  // A Flutter enum value, for example `StrokeCap.butt`.
  final Enum value => '$value' == text,
  // The default mode of `cubicInterpolationMode`.
  DefaultCubicInterpolationMode() => text == 'DefaultCubicInterpolationMode()',
  // The default point style.
  CirclePointStyle() => text == 'CirclePointStyle()',
  final bool value => '$value' == text,
  final List<Object?> value => listEquals(value, const []) && text == '[]',
  _ => false,
};

void main() {
  setUpAll(registerCharts);

  for (final size in const [Size(1440, 900), Size(800, 900), Size(412, 915)]) {
    testWidgets('the page builds at $size', (tester) async {
      await _show(tester, size);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('page.title')), findsOneWidget);
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

  testWidgets('the live chart runs and stops', (tester) async {
    await _show(tester, const Size(1440, 900));
    final toggle = find.byKey(const ValueKey('live.toggle'));
    await tester.ensureVisible(toggle);
    await tester.pump();
    await tester.tap(toggle);
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.text('Pause'), findsOneWidget);
    await tester.tap(toggle);
    await tester.pump();
    expect(find.text('Run'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the live sample takes the data-only path', (tester) async {
    var layouts = 0;
    final spy = <String, Object?>{
      'id': r'$layoutSpy',
      'supportsDataUpdates': true,
      'beforeLayout': (Object? chart, JsObjectFace args, Object? options) {
        layouts++;
      },
    };
    Chart.register([spy]);
    addTearDown(() => Chart.unregister([spy]));
    Widget view(int step) => Directionality(
      textDirection: TextDirection.ltr,
      child: liveLineChart([
        for (var x = 0; x < 100; x++) DataPoint(x, (x + step) % 3),
      ]),
    );
    for (var step = 0; step < 3; step++) {
      await tester.pumpWidget(view(step));
      await tester.pump(const Duration(milliseconds: 16));
    }
    layouts = 0;
    for (var step = 3; step < 8; step++) {
      await tester.pumpWidget(view(step));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(layouts, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a navigation link moves its section into view', (tester) async {
    await _show(tester, const Size(1440, 900));
    final heading = find.text('Internal Data Format').last;
    final before = tester.getTopLeft(heading).dy;
    await tester.tap(find.byKey(const ValueKey('nav.internal-data-format')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final after = tester.getTopLeft(heading).dy;
    expect(after, lessThan(before));
    expect(after, inInclusiveRange(0, 200));
  });

  test('the table gives the defaults of the chart', () {
    for (final row in lineProperties) {
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
      everyElement(isIn(lineProperties.map((r) => r.name))),
    );
  });

  test('each row without extra is a parameter of LineDataset', () {
    // The compiler checks each name of this call.
    const dataset = LineDataset(
      backgroundColor: .constant(.solid(teal)),
      borderCapStyle: StrokeCap.butt,
      borderColor: .constant(.solid(teal)),
      borderDash: [1],
      borderJoinStyle: StrokeJoin.miter,
      borderWidth: 1,
      cubicInterpolationMode: MonotoneCubicInterpolationMode(),
      data: [1],
      fill: .none,
      hoverBackgroundColor: .constant(.solid(teal)),
      hoverBorderColor: .constant(.solid(teal)),
      hoverBorderWidth: 1,
      indexAxis: XAxis(),
      label: '',
      order: 0,
      pointBackgroundColor: .constant(.solid(teal)),
      pointBorderColor: .constant(.solid(teal)),
      pointBorderWidth: 1,
      pointHoverBackgroundColor: .constant(.solid(teal)),
      pointHoverBorderColor: .constant(.solid(teal)),
      pointHoverRadius: 1,
      pointRadius: 1,
      pointStyle: CirclePointStyle(),
      shadow: ChartShadow(color: teal),
      showLine: true,
      spanGaps: true,
      stack: '',
      stepped: SteppedLine.before,
      tension: 0,
      xAxisID: '',
      yAxisID: '',
    );
    expect(dataset.label, '');
    final named = {
      'backgroundColor',
      'borderCapStyle',
      'borderColor',
      'borderDash',
      'borderJoinStyle',
      'borderWidth',
      'cubicInterpolationMode',
      'data',
      'fill',
      'hoverBackgroundColor',
      'hoverBorderColor',
      'hoverBorderWidth',
      'indexAxis',
      'label',
      'order',
      'pointBackgroundColor',
      'pointBorderColor',
      'pointBorderWidth',
      'pointHoverBackgroundColor',
      'pointHoverBorderColor',
      'pointHoverRadius',
      'pointRadius',
      'pointStyle',
      'points',
      'shadow',
      'showLine',
      'spanGaps',
      'stack',
      'stepped',
      'tension',
      'xAxisID',
      'yAxisID',
    };
    expect(
      lineProperties.where((row) => !row.extra).map((row) => row.name).toSet(),
      named,
    );
  });

  test('the sample of the default options sets a default', () {
    final line = _read(Chart.jsClass['overrides'], 'line')! as JsObjectFace;
    addTearDown(() => line['spanGaps'] = undefined);
    spanGapsInAllLineCharts();
    expect(line['spanGaps'], isTrue);
  });

  test('the regions have no markers and no common indent', () {
    expect(_snippets['register'], 'Chart.register(registerables);');
    for (final name in _snippets.names) {
      expect(_snippets[name], isNot(contains('docregion')), reason: name);
    }
  });
}
