// Original code, not ported from Chart.js: tests of the chart benchmark.

import 'dart:convert';

import 'package:chartjs_gallery/bench/chart_bench.dart';
import 'package:chartjs_gallery/demo/stress_axes.dart';
import 'package:chartjs_gallery/demo/stress_chart_config.dart';
import 'package:chartjs_gallery/demo/stress_point_controller.dart';
import 'package:chartjs_gallery/main_bench.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/elements/index.dart';
import 'package:flutter_chartjs/src/js/js_number.dart' show jsToNumber;
import 'package:flutter_chartjs/src/platform/platform.basic.dart';
import 'package:flutter_chartjs/src/scales/index.dart';
import 'package:flutter_test/flutter_test.dart';

/// The timing of these tests: one short batch after a short warm-up.
const ChartBenchSettings _settings = ChartBenchSettings(
  batches: 1,
  batchMs: 5,
  warmupMs: 5,
);

/// A figure of a BENCH line: ms with 3 decimals.
final Matcher _figure = matches(RegExp(r'^\d+\.\d{3}$'));

/// The figure keys of [part]: the median, the 10th and the 90th
/// percentile.
List<String> _keys(String part) => [
  '${part}MedianMs',
  '${part}P10Ms',
  '${part}P90Ms',
];

/// The only case of [selection].
ChartBenchCase _case(String selection) =>
    selectChartBenchCases(selection).single;

void main() {
  testWidgets('main_bench prints one BENCH line for a tiny case', (
    tester,
  ) async {
    final lines = <String>[];
    final old = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null && message.startsWith('BENCH')) lines.add(message);
    };
    try {
      await tester.pumpWidget(
        ChartBenchApp(
          cases: selectChartBenchCases('c'),
          counts: const [10],
          settings: _settings,
        ),
      );
      for (var i = 0; i < 20 && !lines.contains('BENCH done'); i++) {
        await tester.pump();
      }
      // The frame of the last status.
      await tester.pump();
    } finally {
      // flutter_test checks the debug variables before the tearDown.
      debugPrint = old;
    }
    expect(lines, hasLength(2));
    expect(lines.last, 'BENCH done');
    expect(lines.first, startsWith('BENCH {'));
    final line =
        jsonDecode(lines.first.substring('BENCH '.length))
            as Map<String, Object?>;
    expect(line['mode'], 'chart');
    expect(line['case'], 'c');
    expect(line['n'], 10);
    expect(line['sharing'], true);
    expect(line['scriptable'], true);
    expect(line['call'], 'update');
    expect(line['batches'], 1);
    expect(line['batchMs'], 5);
    expect(line['warmupMs'], 5);
    expect(line['batchIterations'], isA<int>());
    expect(line['iterations'], line['batchIterations']);
    expect(line['warmupIterations'], greaterThanOrEqualTo(1));
    for (final key in [..._keys('update'), ..._keys('draw'), ..._keys('end')]) {
      expect(line[key], _figure, reason: key);
    }
    expect(line['width'], chartBenchWidth);
    expect(line['height'], chartBenchHeight);
    expect(line['dpr'], 1);
    expect(line['build'], 'debug');
    expect(line['platform'], isA<String>());
    expect(line['startMs'], isA<int>());
    expect(line['wallMs'], isA<int>());
    expect(
      find.byKey(const ValueKey('bench.status')),
      findsOneWidget,
    );
    expect(find.text('Done (1 of 1)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a case runs a chart with no host and destroys it', (
    tester,
  ) async {
    Chart? chart;
    final line = runChartBenchCase(
      _case('chart.a'),
      10,
      _settings,
      onChart: (c) {
        chart = c;
        expect(c.platform, isA<BasicPlatform>());
        expect(c.config.type, StressPointController.id);
        expect(c.options['responsive'], false);
        expect(c.options['animation'], false);
        expect(c.options['events'], isEmpty);
        expect(c.options['devicePixelRatio'], 1);
        expect(c.width, chartBenchWidth);
        expect(c.height, chartBenchHeight);
        expect(c.getDatasetMeta(0).data, hasLength(10));
        expect(Chart.instances.values, contains(c));
      },
    );
    expect(chart, isNotNull);
    expect(chart!.canvas, isNull);
    expect(Chart.instances.values, isNot(contains(chart)));
    // Case (a) only draws: the line has no update figures. The mode chart
    // has no scales, thus no tick keys.
    expect(line['call'], 'draw');
    expect(line.keys, isNot(contains('updateMedianMs')));
    expect(line.keys, isNot(contains('ticks')));
    for (final key in [..._keys('draw'), ..._keys('end')]) {
      expect(line[key], _figure, reason: key);
    }
  });

  testWidgets('the update cases move the points of the stress mode', (
    tester,
  ) async {
    // The field of the case starts at the points of the stress tab.
    final start = StressPointField(10);
    runChartBenchCase(
      _case('chart.c'),
      10,
      _settings,
      onChart: (c) {
        final points = [
          for (final element in c.getDatasetMeta(0).data)
            element as PointElement,
        ];
        final datasets = c.data['datasets']! as List<Object?>;
        final dataset = datasets.first! as Map<String, Object?>;
        final data = dataset['data']! as List<Object?>;
        final first = data.first! as Map<String, Object?>;
        // Each update moved the data objects, and the points follow them.
        expect(first['x'], isNot(start.x[0]));
        expect(first['y'], isNot(start.y[0]));
        final area = c.chartArea!;
        expect(
          points.first.x,
          area.left + (first['x']! as double) * area.width,
        );
        expect(points[0].options!['backgroundColor'], stressChartBackground);
        expect(points[1].options!['backgroundColor'], stressChartBackgroundOdd);
      },
    );
  });

  testWidgets('an axes case maps the points with its scales', (
    tester,
  ) async {
    final benchCase = selectChartBenchCases(
      'axes.category',
    ).singleWhere((c) => c.call == ChartBenchCall.update);
    int? ticks;
    double? rotation;
    final line = runChartBenchCase(
      benchCase,
      30,
      _settings,
      onChart: (c) {
        final x = c.scales['x']!;
        final y = c.scales['y']!;
        ticks = x.ticks!.length;
        rotation = jsToNumber(x.labelRotation);
        expect(x, isA<CategoryScale>());
        expect(y, isA<LinearScale>());
        expect(x.getLabels(), hasLength(30));
        expect(x.options['ticks'], containsPair('autoSkip', true));
        final meta = c.getDatasetMeta(0);
        expect(identical(meta.iScale, x), isTrue);
        expect(identical(meta.vScale, y), isTrue);
        final datasets = c.data['datasets']! as List<Object?>;
        final dataset = datasets.first! as Map<String, Object?>;
        final data = (dataset['data']! as List<Object?>)
            .cast<Map<String, Object?>>();
        final point = meta.data[5] as PointElement;
        // The category x is the index of the label. The y values moved.
        expect(data[5]['x'], 5);
        expect(point.x, x.getPixelForValue(5.0, 5));
        expect(point.y, y.getPixelForValue(data[5]['y'], 5));
        expect(c.chartArea!.bottom, lessThan(chartBenchHeight));
      },
    );
    expect(line['mode'], 'axes');
    expect(line['case'], 'category');
    expect(line['scale'], 'category');
    expect(line['yScale'], 'linear');
    expect(line['autoSkip'], true);
    // The x axis after the last batch.
    expect(line['ticks'], ticks);
    expect(line['ticks'], greaterThan(1));
    expect(line['rotation'], rotation!.toStringAsFixed(2));
    expect(line['call'], 'update');
    for (final key in [
      ..._keys('update'),
      ..._keys('draw'),
      ..._keys('end'),
      ..._keys('layout'),
      ..._keys('datasetsUpdate'),
      ..._keys('datasetsDraw'),
    ]) {
      expect(line[key], _figure, reason: key);
    }
    // The update fits the scales: the layout takes time.
    expect(double.parse(line['layoutMedianMs']! as String), greaterThan(0));

    // A draw has no layout and no dataset update.
    final draw = runChartBenchCase(
      selectChartBenchCases(
        'axes.time',
      ).singleWhere((c) => c.call == ChartBenchCall.draw),
      30,
      _settings,
      onChart: (c) => expect(c.scales['x'], isA<TimeScale>()),
    );
    expect(draw['scale'], 'time');
    expect(draw['ticks'], greaterThan(1));
    expect(draw['rotation'], matches(RegExp(r'^\d+\.\d\d$')));
    expect(draw.keys, isNot(contains('updateMedianMs')));
    expect(draw['layoutMedianMs'], '0.000');
    expect(draw['datasetsUpdateMedianMs'], '0.000');
    expect(draw['datasetsDrawMedianMs'], _figure);
    expect(tester.takeException(), isNull);
  });

  test('the axes scene writes the values of its scale types', () {
    final field = StressPointField(4);
    final scene = StressAxesScene(
      4,
      x: StressAxisType.logarithmic,
      y: StressAxisType.linear,
      positions: field,
    );
    expect(scene.labels, isEmpty);
    // parsing: false needs data sorted by x: equal factors on a logarithmic
    // axis, from 1 to 100000.
    final xs = [for (final item in scene.data) item['x']! as double];
    expect(xs.first, 1);
    expect(xs.last, 100000);
    for (var i = 1; i < xs.length; i++) {
      expect(xs[i] / xs[i - 1], closeTo(xs[1] / xs[0], 1e-9));
    }
    // A write moves the y values only.
    field.step(4, 0.5);
    scene.write(field);
    expect([for (final item in scene.data) item['x']], xs);
    expect(scene.data[1]['y'], field.y[1] * 100);
    expect(stressAxesValue(0, StressAxisType.logarithmic), 1);
    expect(stressAxesValue(1, StressAxisType.logarithmic), 100000);
    final linear = StressAxesScene(
      3,
      x: StressAxisType.linear,
      y: StressAxisType.linear,
      positions: field,
    );
    expect([for (final item in linear.data) item['x']], [0, 50, 100]);
    // The category and the time x do not move either.
    final time = StressAxesScene(
      3,
      x: StressAxisType.time,
      y: StressAxisType.logarithmic,
      positions: field,
    );
    final day = time.data[1]['x'];
    time.write(field);
    expect(time.data[1]['x'], day);
    expect(
      (time.data[2]['x']! as double) - (time.data[1]['x']! as double),
      // One day, or one day and the change of a daylight saving time.
      closeTo(Duration.millisecondsPerDay, 3600000),
    );
    final category = StressAxesScene(
      3,
      x: StressAxisType.category,
      y: StressAxisType.linear,
      positions: field,
    );
    expect(category.labels, ['Point 0', 'Point 1', 'Point 2']);
    expect([for (final item in category.data) item['x']], [0, 1, 2]);
  });

  test('selectChartBenchCases selects by mode, name and id', () {
    expect(selectChartBenchCases(''), chartBenchCases);
    expect(selectChartBenchCases('chart'), [
      for (final c in chartBenchCases)
        if (c.mode == 'chart') c,
    ]);
    expect(selectChartBenchCases('chart'), hasLength(4));
    final axes = selectChartBenchCases('axes');
    expect(
      [for (final c in axes) c.id],
      [
        for (final scale in StressAxisType.values) ...[
          'axes.${scale.name}',
          'axes.${scale.name}',
        ],
      ],
    );
    expect(
      [for (final c in selectChartBenchCases('time')) c.call],
      [
        ChartBenchCall.draw,
        ChartBenchCall.update,
      ],
    );
    final b = selectChartBenchCases('b');
    expect(b, hasLength(2));
    expect([for (final c in b) c.keys['sharing']], [true, false]);
    expect(selectChartBenchCases(' c , chart.a ').map((c) => c.name), [
      'a',
      'c',
    ]);
    expect(() => selectChartBenchCases('a,x'), throwsArgumentError);
  });

  test('parseChartBenchCounts reads a comma list of counts', () {
    expect(parseChartBenchCounts('1000,5000,20000'), [1000, 5000, 20000]);
    expect(parseChartBenchCounts(' 10 '), [10]);
    expect(() => parseChartBenchCounts('0'), throwsArgumentError);
    expect(() => parseChartBenchCounts('1k'), throwsFormatException);
  });
}
