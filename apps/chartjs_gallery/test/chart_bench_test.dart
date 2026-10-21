// Original code, not ported from Chart.js: tests of the chart benchmark.

import 'dart:convert';

import 'package:chartjs_gallery/bench/chart_bench.dart';
import 'package:chartjs_gallery/demo/stress_axes.dart';
import 'package:chartjs_gallery/demo/stress_chart_config.dart';
import 'package:chartjs_gallery/main_bench.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chartjs/src/controllers/index.dart';
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

/// The four parts of `StressChartTiming` in a BENCH line.
const List<String> _parts = [
  'elements',
  'layout',
  'datasetsUpdate',
  'datasetsDraw',
];

/// Collects the BENCH lines of [body].
Future<List<String>> _benchLines(Future<void> Function() body) async {
  final lines = <String>[];
  final old = debugPrint;
  debugPrint = (message, {wrapWidth}) {
    if (message != null && message.startsWith('BENCH')) lines.add(message);
  };
  try {
    await body();
  } finally {
    // flutter_test checks the debug variables before the tearDown.
    debugPrint = old;
  }
  return lines;
}

/// Pumps a [ChartBenchApp] until it prints `BENCH done`.
Future<void> _runApp(WidgetTester tester, ChartBenchApp app) async {
  await tester.pumpWidget(app);
  for (var i = 0; i < 200; i++) {
    await tester.pump();
    if (find.textContaining('Done (').evaluate().isNotEmpty) break;
  }
  // The frame of the last status.
  await tester.pump();
}

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
    expect(line['type'], 'line');
    expect(line['sharing'], true);
    expect(line['scriptable'], true);
    expect(line['call'], 'update');
    expect(line['batches'], 1);
    expect(line['batchMs'], 5);
    expect(line['warmupMs'], 5);
    expect(line['batchIterations'], isA<int>());
    expect(line['iterations'], line['batchIterations']);
    expect(line['warmupIterations'], greaterThanOrEqualTo(1));
    for (final key in [
      ..._keys('update'),
      ..._keys('draw'),
      ..._keys('end'),
      for (final part in _parts) ..._keys(part),
    ]) {
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
        expect(c.config.type, 'line');
        expect(c.getDatasetMeta(0).controller, isA<LineController>());
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
    // Case (a) only draws: the line has no update figures, and the parts of
    // the update are 0. The hidden scales of the mode chart give no tick
    // keys.
    expect(line['call'], 'draw');
    expect(line['type'], 'line');
    expect(line.keys, isNot(contains('updateMedianMs')));
    expect(line.keys, isNot(contains('ticks')));
    for (final key in [
      ..._keys('draw'),
      ..._keys('end'),
      for (final part in _parts) ..._keys(part),
    ]) {
      expect(line[key], _figure, reason: key);
    }
    expect(line['elementsMedianMs'], '0.000');
    expect(line['layoutMedianMs'], '0.000');
    expect(line['datasetsUpdateMedianMs'], '0.000');
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
          closeTo(area.left + (first['x']! as double) * area.width, 1e-9),
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
      for (final part in _parts) ..._keys(part),
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
    expect(draw['elementsMedianMs'], '0.000');
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
    expect(selectChartBenchCases('chart'), hasLength(16));
    expect(selectChartBenchCases('a,b,c'), hasLength(4));
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
    expect([for (final c in b) c.keys['type']], ['line', 'scatter']);
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

  test('the cases a, b and c keep their keys and get the key type', () {
    final cases = selectChartBenchCases('a,b,c');
    expect(
      [for (final c in cases) c.id],
      [
        'chart.a',
        'chart.b',
        'chart.b',
        'chart.c',
      ],
    );
    expect(
      [for (final c in cases) c.keys],
      [
        {'type': 'line', 'sharing': true, 'scriptable': false},
        {'type': 'line', 'sharing': true, 'scriptable': false},
        {'type': 'scatter', 'sharing': false, 'scriptable': false},
        {'type': 'line', 'sharing': true, 'scriptable': true},
      ],
    );
    expect([for (final c in cases) c.counts], [null, null, null, null]);
  });

  test('the cases chart.<type> come after the axes cases, two calls each', () {
    final ids = [for (final c in chartBenchCases) c.id];
    final lastAxes = ids.lastIndexWhere((id) => id.startsWith('axes.'));
    final types = chartBenchCases.sublist(lastAxes + 1);
    expect(ids.indexWhere((id) => id.startsWith('axes.')), 4);
    expect(
      [for (final c in types) '${c.id} ${c.call.name}'],
      [
        for (final type in StressChartType.values)
          if (!type.points)
            for (final call in ChartBenchCall.values)
              'chart.${type.name} ${call.name}',
      ],
    );
    expect(types, hasLength(12));
    for (final c in types) {
      final type = StressChartType.values.byName(c.name);
      expect(c.mode, 'chart');
      expect(c.keys, {
        'type': type.name,
        'sharing': type.sharing,
        'scriptable': false,
      });
      expect(c.counts, type.counts);
    }
    for (final selector in ['bar', 'chart.bar']) {
      expect(
        [for (final c in selectChartBenchCases(selector)) c.call],
        [ChartBenchCall.draw, ChartBenchCall.update],
        reason: selector,
      );
    }
    // No case has the type of the deleted gallery controller.
    for (final c in chartBenchCases) {
      expect(c.keys['type'], isNot('stressPoint'), reason: c.id);
    }
    expect(chartBenchDefaultCounts, [1000, 5000, 20000]);
  });

  testWidgets('a case without N runs its own counts, and N overrides them', (
    tester,
  ) async {
    const settings = ChartBenchSettings(batches: 1, batchMs: 1, warmupMs: 1);
    // A tiny copy of chart.radar with two counts.
    final radar = selectChartBenchCases('chart.radar').first;
    final small = ChartBenchCase(
      mode: radar.mode,
      name: radar.name,
      call: radar.call,
      scene: radar.scene,
      keys: radar.keys,
      counts: const [5, 7],
    );
    final own = await _benchLines(
      () => _runApp(tester, ChartBenchApp(cases: [small], settings: settings)),
    );
    expect(own.last, 'BENCH done');
    expect(
      [
        for (final line in own.take(own.length - 1))
          (jsonDecode(line.substring('BENCH '.length)) as Map)['n'],
      ],
      [5, 7],
    );
    await tester.pumpWidget(const SizedBox());
    final overridden = await _benchLines(
      () => _runApp(
        tester,
        ChartBenchApp(cases: [small], counts: const [3], settings: settings),
      ),
    );
    expect(overridden, hasLength(2));
    expect(
      (jsonDecode(overridden.first.substring('BENCH '.length)) as Map)['n'],
      3,
    );
    expect(benchCounts, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a tiny run of each case chart.<type> gives its keys and parts', (
    tester,
  ) async {
    final types = [
      for (final c in chartBenchCases)
        if (c.mode == 'chart' && !['a', 'b', 'c'].contains(c.name)) c,
    ];
    expect(types, hasLength(12));
    for (final benchCase in types) {
      final type = StressChartType.values.byName(benchCase.name);
      final reason = '${benchCase.id} ${benchCase.call.name}';
      Object? before;
      final line = runChartBenchCase(
        benchCase,
        10,
        _settings,
        onChart: (c) {
          expect(c.config.type, type.name, reason: reason);
          final controller = c.getDatasetMeta(0).controller!;
          expect(controller.enableOptionSharing, type.sharing, reason: reason);
          expect(c.getDatasetMeta(0).data, hasLength(10), reason: reason);
          before = c.getDatasetMeta(0).data.first;
        },
      );
      expect(before, isNotNull, reason: reason);
      expect(line['mode'], 'chart', reason: reason);
      expect(line['case'], type.name, reason: reason);
      expect(line['type'], type.name, reason: reason);
      expect(line['sharing'], type.sharing, reason: reason);
      expect(line['scriptable'], false, reason: reason);
      expect(line['n'], 10, reason: reason);
      for (final key in [
        if (benchCase.call == ChartBenchCall.update) ..._keys('update'),
        ..._keys('draw'),
        ..._keys('end'),
        for (final part in _parts) ..._keys(part),
      ]) {
        expect(line[key], _figure, reason: '$reason $key');
      }
      if (benchCase.call == ChartBenchCall.update) {
        expect(
          double.parse(line['elementsMedianMs']! as String),
          greaterThan(0),
          reason: reason,
        );
      }
    }
    expect(tester.takeException(), isNull);
  });

  test('an update of a case chart.<type> moves the values', () {
    for (final name in [
      'bar',
      'bubble',
      'doughnut',
      'pie',
      'polarArea',
      'radar',
    ]) {
      final benchCase = selectChartBenchCases(
        'chart.$name',
      ).singleWhere((c) => c.call == ChartBenchCall.update);
      final scene = benchCase.scene(10);
      final datasets =
          (scene.config['data']! as Map<String, Object?>)['datasets']!
              as List<Object?>;
      final data =
          (datasets.single! as Map<String, Object?>)['data']! as List<Object?>;
      final before = jsonEncode(data);
      scene.change!();
      expect(jsonEncode(data), isNot(before), reason: name);
      expect(scene.takeParts!().keys, _parts, reason: name);
    }
  });
}
