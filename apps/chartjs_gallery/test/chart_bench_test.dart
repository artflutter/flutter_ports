// Original code, not ported from Chart.js: tests of the chart benchmark.

import 'dart:convert';

import 'package:chartjs_gallery/bench/chart_bench.dart';
import 'package:chartjs_gallery/demo/demo_common.dart';
import 'package:chartjs_gallery/demo/stress_axes.dart';
import 'package:chartjs_gallery/demo/stress_chart_config.dart';
import 'package:chartjs_gallery/main_bench.dart';
import 'package:flutter/material.dart' hide Title, Tooltip;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
// Not public: UiCanvasElement, the canvas of the internal host.
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart'
    show UiCanvasElement;
// Not public: Animation, the class of the animations of an element. The
// prefix keeps it apart from the Animation of Flutter.
import 'package:flutter_chartjs_port/src/core/core.animation.dart'
    as port
    show Animation;
// Not public: jsToNumber, the JS ToNumber of a raw chart value.
import 'package:flutter_chartjs_port/src/js/js_number.dart' show jsToNumber;
// Not public: jsGet, the JS property read of the chart values.
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
// Not public: Legend, the element class of plugin.legend (hit boxes).
import 'package:flutter_chartjs_port/src/plugins/plugin.legend.dart'
    show Legend;
// Not public: Title, the element class of plugin.title.
import 'package:flutter_chartjs_port/src/plugins/plugin.title.dart' show Title;
// Not public: Tooltip, the element class of plugin.tooltip.
import 'package:flutter_chartjs_port/src/plugins/plugin.tooltip.dart'
    show Tooltip;
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

/// The modes of the cases of phases 5 to 7.
const List<String> _phase7Modes = ['chart', 'axes'];

/// The case of [selection] with the call [call] and the keys [keys].
ChartBenchCase _pluginCase(
  String selection,
  ChartBenchCall call, [
  Map<String, Object?> keys = const {},
]) => selectChartBenchCases(selection).singleWhere(
  (c) => c.call == call && keys.entries.every((e) => c.keys[e.key] == e.value),
);

/// The figure keys of the parts that a case with [call] gives:
/// `update` (not for a draw), `draw` and `end`, then [parts].
List<String> _figureKeys(ChartBenchCall call, List<String> parts) => [
  if (call != ChartBenchCall.draw) ..._keys('update'),
  ..._keys('draw'),
  ..._keys('end'),
  for (final part in parts) ..._keys(part),
];

/// The case `tooltip.fade` with [datasets] datasets.
ChartBenchCase _fade(int datasets) => _pluginCase(
  'tooltip.fade',
  ChartBenchCall.frame,
  {'datasets': datasets},
);

/// The median of the figure [part] of [line], in ms.
double _median(Map<String, Object?> line, String part) =>
    double.parse(line['${part}MedianMs']! as String);

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
    final line = jsonDecode(
      lines.first.substring('BENCH '.length),
    ) as Map<String, Object?>;
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

  test(
    'each case of phases 5 to 7 has no legend (Chart.js ADR 0031, Open)',
    () {
      // The configs of stressChartConfig and stressAxesConfig have
      // `plugins.legend: false` (stressPluginOptions), and chartBenchOptions
      // has no `plugins` key that replaces it. The cases of phase 8 give
      // their own plugin options.
      expect(chartBenchOptions.containsKey('plugins'), isFalse);
      for (final benchCase in chartBenchCases) {
        if (!_phase7Modes.contains(benchCase.mode)) continue;
        var checked = false;
        runChartBenchCase(
          benchCase,
          10,
          const ChartBenchSettings(batches: 1, batchMs: 1, warmupMs: 1),
          onChart: (chart) {
            checked = true;
            expect(
              jsGet(chart.options['plugins'], 'legend'),
              false,
              reason: benchCase.id,
            );
            expect(chart.legend, isNull, reason: benchCase.id);
            expect(chart.boxes.whereType<Legend>(), isEmpty);
          },
        );
        expect(checked, isTrue, reason: benchCase.id);
      }
    },
  );

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
        final datasets = readByName(c.data, 'datasets')! as List<Object?>;
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
        expect(
          (points[0].options! as JsObjectFace)['backgroundColor'],
          stressChartBackground,
        );
        expect(
          (points[1].options! as JsObjectFace)['backgroundColor'],
          stressChartBackgroundOdd,
        );
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
        expect((x.options['ticks']! as JsObjectFace)['autoSkip'], true);
        final meta = c.getDatasetMeta(0);
        expect(identical(meta.iScale, x), isTrue);
        expect(identical(meta.vScale, y), isTrue);
        final datasets = readByName(c.data, 'datasets')! as List<Object?>;
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
    final types = chartBenchCases.sublist(lastAxes + 1, lastAxes + 13);
    expect(ids.indexWhere((id) => id.startsWith('axes.')), 4);
    expect(
      [for (final c in types) '${c.id} ${c.call.name}'],
      [
        for (final type in StressChartType.values)
          if (!type.points)
            for (final call in chartBenchDrawAndUpdate)
              'chart.${type.name} ${call.name}',
      ],
    );
    // The cases of phase 8 come after them.
    expect(
      [
        for (final c in chartBenchCases.sublist(lastAxes + 13))
          if (_phase7Modes.contains(c.mode)) c.id,
      ],
      isEmpty,
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
    expect(
      [for (final c in selectChartBenchCases('chart.bar')) c.call],
      [ChartBenchCall.draw, ChartBenchCall.update],
    );
    // The bare name `bar` also selects motion.bar of phase 9.
    expect(
      [for (final c in selectChartBenchCases('bar')) c.id],
      ['chart.bar', 'chart.bar', 'motion.bar'],
    );
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

  test('the cases of phase 8 come last and name their primary metric', () {
    final first = chartBenchCases.indexWhere(
      (c) => !_phase7Modes.contains(c.mode),
    );
    // The cases of phase 9 (the modes motion and theme) come after them.
    final phase8 = [
      for (final c in chartBenchCases.sublist(first))
        if (c.mode != 'motion' && c.mode != 'theme') c,
    ];
    expect(
      [for (final c in chartBenchCases.sublist(first + phase8.length)) c.id],
      [
        'motion.line',
        'motion.bar',
        for (final _ in chartBenchThemeTypes) 'theme.switch',
        for (final _ in chartBenchThemeTypes) 'theme.anim',
        'theme.equal',
      ],
    );
    // The 24 cases of phases 5 to 7 keep their order before them.
    expect(first, 24);
    expect(
      [for (final c in phase8) '${c.id} ${c.call.name} ${c.keys}'],
      [
        for (final datasets in [3, 100])
          for (final call in ['draw', 'update'])
            for (final config in ['A', 'B'])
              'plugins.line $call {config: $config, datasets: $datasets}',
        for (final datasets in [3, 10]) ...[
          'tooltip.hover frame {datasets: $datasets, tooltip: true}',
          'tooltip.hover frame {datasets: $datasets, tooltip: false}',
          'tooltip.still draw {datasets: $datasets, tooltip: true}',
          'tooltip.still draw {datasets: $datasets, tooltip: false}',
          'tooltip.fade frame {datasets: $datasets, tooltip: true}',
        ],
        for (final name in ['gaps', 'stack', 'radar'])
          for (final call in ['draw', 'update'])
            'fill.$name $call {datasets: 3}',
        for (final call in ['draw', 'update']) ...[
          'legend.line $call {datasets: 3, legend: true, title: false}',
          'legend.line $call {datasets: 3, legend: false, title: false}',
          'title.line $call {datasets: 3, legend: false, title: true}',
        ],
      ],
    );
    for (final c in phase8) {
      expect(c.primary, c.call.frameMetric, reason: c.id);
      if (c.mode == 'plugins') {
        expect(c.counts, [if (c.keys['datasets'] == 3) 1000 else 100]);
      } else {
        expect(c.counts, chartBenchPluginCounts, reason: c.id);
      }
    }
    expect(ChartBenchCall.draw.frameMetric, 'draw+end');
    expect(ChartBenchCall.update.frameMetric, 'update+draw+end');
    expect(ChartBenchCall.frame.frameMetric, 'update+draw+end');
    expect(ChartBenchCall.motion.frameMetric, 'update');
    // The cases of phases 5 to 7 name no primary metric: their lines keep
    // their keys.
    for (final c in chartBenchCases.sublist(0, first)) {
      expect(c.primary, isNull, reason: c.id);
    }
    expect(selectChartBenchCases('plugins.line'), hasLength(8));
    expect(selectChartBenchCases('tooltip'), hasLength(10));
    expect(selectChartBenchCases('fill'), hasLength(6));
    // The bare name `radar` selects chart.radar and fill.radar.
    expect(
      {for (final c in selectChartBenchCases('radar')) c.id},
      {'chart.radar', 'fill.radar'},
    );
  });

  testWidgets('plugins.line runs config A with the seven plugins and B '
      'with none (Chart.js ADR 0038, section 10)', (tester) async {
    for (final datasets in [3, 100]) {
      for (final call in chartBenchDrawAndUpdate) {
        final notifies = <String, Object?>{};
        for (final config in ['A', 'B']) {
          final reason = '$config $datasets ${call.name}';
          final line = runChartBenchCase(
            _pluginCase('plugins.line', call, {
              'config': config,
              'datasets': datasets,
            }),
            4,
            _settings,
            onChart: (chart) {
              expect(readByName(chart.data, 'datasets'), hasLength(datasets));
              expect(chart.options['events'], isEmpty, reason: reason);
              expect(chart.options['animation'], false, reason: reason);
              for (final id in [
                'colors',
                'decimation',
                'filler',
                'legend',
                'subtitle',
                'title',
                'tooltip',
              ]) {
                expect(
                  chart.isPluginEnabled(id),
                  config == 'A',
                  reason: '$reason $id',
                );
              }
              if (config == 'A') {
                final plugins = chart.options['plugins'];
                expect(jsGet(jsGet(plugins, 'legend'), 'display'), false);
                expect(jsGet(jsGet(plugins, 'title'), 'display'), false);
                expect(jsGet(jsGet(plugins, 'subtitle'), 'display'), false);
                expect(jsGet(jsGet(plugins, 'colors'), 'enabled'), false);
                expect(jsGet(jsGet(plugins, 'decimation'), 'enabled'), false);
                // The legend builds its box, also with `display: false`.
                expect(chart.legend, isNotNull, reason: reason);
              } else {
                expect(chart.options['plugins'], false, reason: reason);
                expect(chart.legend, isNull, reason: reason);
              }
            },
          );
          expect(line['mode'], 'plugins');
          expect(line['case'], 'line');
          expect(line['config'], config);
          expect(line['datasets'], datasets);
          expect(line['primary'], call.frameMetric);
          for (final key in _figureKeys(call, const [])) {
            expect(line[key], _figure, reason: '$reason $key');
          }
          // No timing plugin: B would turn it off.
          expect(line.keys, isNot(contains('elementsMedianMs')));
          notifies[config] = line['notifies'];
        }
        // The notifies do not depend on the plugins.
        expect(notifies['A'], notifies['B']);
        if (call == ChartBenchCall.draw) {
          // beforeDraw, beforeDatasetsDraw, two for each dataset,
          // afterDatasetsDraw and afterDraw: 204 for 100 datasets.
          expect(notifies['A'], 4 + 2 * datasets);
        } else {
          expect(notifies['A'], greaterThan(4 + 2 * datasets));
        }
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('tooltip.hover changes the hover in each frame', (tester) async {
    for (final datasets in [3, 10]) {
      for (final tooltip in [true, false]) {
        final reason = '$datasets $tooltip';
        final line = runChartBenchCase(
          _pluginCase('tooltip.hover', ChartBenchCall.frame, {
            'datasets': datasets,
            'tooltip': tooltip,
          }),
          12,
          _settings,
          onChart: (chart) {
            expect(chart.options['animation'], false, reason: reason);
            expect(
              jsGet(chart.options['interaction'], 'mode'),
              'index',
              reason: reason,
            );
            expect(chart.legend, isNull, reason: reason);
            // The mode index makes the point of each dataset active.
            expect(chart.getActiveElements(), hasLength(datasets));
            if (tooltip) {
              final model = chart.tooltip! as Tooltip;
              expect(model.opacity, 1, reason: reason);
              expect(model.getActiveElements(), hasLength(datasets));
            } else {
              expect(chart.tooltip, isNull, reason: reason);
            }
          },
        );
        expect(line['call'], 'frame');
        expect(line['primary'], 'update+draw+end');
        for (final key in _figureKeys(ChartBenchCall.frame, [
          ..._parts,
          'tooltipDraw',
        ])) {
          expect(line[key], _figure, reason: '$reason $key');
        }
        // Each frame draws the chart in the event.
        expect(_median(line, 'draw'), greaterThan(0), reason: reason);
        expect(_median(line, 'datasetsDraw'), greaterThan(0), reason: reason);
        expect(line['elementsMedianMs'], '0.000', reason: reason);
        if (tooltip) {
          expect(_median(line, 'tooltipDraw'), greaterThan(0), reason: reason);
        } else {
          expect(line['tooltipDrawMedianMs'], '0.000', reason: reason);
        }
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('tooltip.hover moves the tooltip to the next point', (
    tester,
  ) async {
    final scene = _pluginCase('tooltip.hover', ChartBenchCall.frame, {
      'datasets': 3,
      'tooltip': true,
    }).scene(6);
    final chart = Chart(
      UiCanvasElement(width: chartBenchWidth, height: chartBenchHeight),
      scene.config,
    );
    addTearDown(chart.destroy);
    scene.prepare!(chart);
    final indexes = <Object?>[];
    for (var i = 0; i < 7; i++) {
      scene.frame!(chart);
      final active = (chart.tooltip! as Tooltip).getActiveElements();
      indexes.add(active.first.index);
    }
    expect(indexes, [1, 2, 3, 4, 5, 0, 1]);
  });

  testWidgets('tooltip.still draws a still tooltip after its animations', (
    tester,
  ) async {
    for (final tooltip in [true, false]) {
      final line = runChartBenchCase(
        _pluginCase('tooltip.still', ChartBenchCall.draw, {
          'datasets': 3,
          'tooltip': tooltip,
        }),
        12,
        _settings,
        onChart: (chart) {
          // The default animations, all at their end.
          expect(chart.options['animation'], isNot(false));
          expect(animator.running(chart), isFalse);
          expect(chart.getActiveElements(), hasLength(3));
          if (tooltip) {
            final model = chart.tooltip! as Tooltip;
            expect(model.opacity, 1);
            expect(model.getActiveElements().first.index, 6);
            // The ended animations stay in `$animations`.
            expect(model.$animations!.keys, containsAll(['x', 'y']));
          } else {
            expect(chart.tooltip, isNull);
          }
        },
      );
      expect(line['call'], 'draw');
      expect(line['primary'], 'draw+end');
      for (final key in _figureKeys(ChartBenchCall.draw, [
        ..._parts,
        'tooltipDraw',
      ])) {
        expect(line[key], _figure, reason: key);
      }
      expect(_median(line, 'tooltipDraw') > 0, tooltip);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('tooltip.fade gives a new opacity in each frame', (
    tester,
  ) async {
    final scene = _fade(3).scene(12);
    final chart = Chart(
      UiCanvasElement(width: chartBenchWidth, height: chartBenchHeight),
      scene.config,
    );
    addTearDown(chart.destroy);
    scene.prepare!(chart);
    expect(animator.running(chart), isFalse);
    final opacities = <double>[];
    for (var i = 0; i < 3 * chartBenchFadeFrames; i++) {
      scene.frame!(chart);
      opacities.add((chart.tooltip! as Tooltip).opacity);
    }
    const f = chartBenchFadeFrames;
    // The fade c ticks at the frames i + 1 + phase(c), phase(c) the
    // fractional part of c * chartBenchFadePhase. The last frame ends it.
    double phase(int c) => (c * chartBenchFadePhase) % 1;
    double done(int c, int i) => ((i + 1 + phase(c)) / f).clamp(0.0, 1.0);
    for (var i = 0; i < f; i++) {
      // The linear fade in, then the fade out, then the fade in again.
      expect(opacities[i], closeTo(done(0, i), 1e-5), reason: '$i');
      expect(opacities[f + i], closeTo(1 - done(1, i), 1e-5), reason: '$i');
      expect(opacities[2 * f + i], closeTo(done(2, i), 1e-5), reason: '$i');
    }
    // Each frame gives a new opacity, also against the earlier fades: a
    // real frame loop does not repeat the opacities of a fade, so the
    // lines of the tooltip miss the paragraph cache, as on a device
    // (Chart.js ADR 0039, section 13, item 1).
    final partial = [
      for (final o in opacities)
        if (o > 0 && o < 1) o,
    ];
    expect(partial, hasLength(3 * (f - 1)));
    expect(partial.toSet(), hasLength(partial.length));
    final line = runChartBenchCase(_fade(10), 12, _settings);
    expect(line['call'], 'frame');
    expect(line['tooltip'], true);
    expect(line['datasets'], 10);
    for (final key in _figureKeys(ChartBenchCall.frame, [
      ..._parts,
      'tooltipDraw',
    ])) {
      expect(line[key], _figure, reason: key);
    }
    expect(_median(line, 'draw'), greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the fill cases fill with the targets of Chart.js ADR 0040', (
    tester,
  ) async {
    for (final name in ['gaps', 'stack', 'radar']) {
      for (final call in chartBenchDrawAndUpdate) {
        final reason = '$name ${call.name}';
        final line = runChartBenchCase(
          _pluginCase('fill.$name', call),
          24,
          _settings,
          onChart: (chart) {
            expect(chart.config.type, name == 'radar' ? 'radar' : 'line');
            expect(chart.legend, isNull, reason: reason);
            final datasets =
                readByName(chart.data, 'datasets')! as List<Object?>;
            expect(datasets, hasLength(3));
            for (var k = 0; k < 3; k++) {
              final dataset = datasets[k]! as Map<String, Object?>;
              final data = dataset['data']! as List<Object?>;
              expect(data, hasLength(24));
              final fill = dataset['fill'];
              switch (name) {
                case 'gaps':
                  expect(data[11], isNull, reason: reason);
                  expect(data[23], isNull, reason: reason);
                  expect(data[10], isA<double>(), reason: reason);
                  expect(fill, containsPair('target', 'origin'));
                  expect(fill, contains('above'));
                  expect(fill, contains('below'));
                case 'stack':
                  expect(fill, 'stack', reason: reason);
                default:
                  expect(fill, ['origin', '-1', '-1'][k], reason: reason);
              }
              // The filler made the source of each dataset.
              expect(
                chart.getDatasetMeta(k)[r'$filler'],
                isNotNull,
                reason: '$reason $k',
              );
            }
            if (name == 'stack') {
              expect(
                jsGet(chart.scales['y']!.options, 'stacked'),
                true,
                reason: reason,
              );
            }
          },
        );
        expect(line['mode'], 'fill');
        expect(line['primary'], call.frameMetric);
        for (final key in _figureKeys(call, _parts)) {
          expect(line[key], _figure, reason: '$reason $key');
        }
        expect(_median(line, 'datasetsDraw'), greaterThan(0), reason: reason);
      }
    }
    expect(tester.takeException(), isNull);
  });

  test('an update of a plugin case moves the values and keeps the gaps', () {
    for (final selection in [
      'plugins.line',
      'fill.gaps',
      'fill.stack',
      'fill.radar',
      'legend.line',
      'title.line',
    ]) {
      final benchCase = selectChartBenchCases(
        selection,
      ).firstWhere((c) => c.call == ChartBenchCall.update);
      final scene = benchCase.scene(24);
      final datasets =
          (scene.config['data']! as Map<String, Object?>)['datasets']!
              as List<Object?>;
      final data =
          (datasets.first! as Map<String, Object?>)['data']! as List<Object?>;
      final before = jsonEncode(data);
      scene.change!();
      expect(jsonEncode(data), isNot(before), reason: selection);
      if (selection == 'fill.gaps') {
        expect(data[11], isNull);
        expect(data[23], isNull);
      }
    }
  });

  testWidgets('the legend and title cases show their boxes', (tester) async {
    for (final call in chartBenchDrawAndUpdate) {
      for (final (selection, legend, title) in [
        ('legend.line', true, false),
        ('legend.line', false, false),
        ('title.line', false, true),
      ]) {
        final reason = '$selection $legend ${call.name}';
        final line = runChartBenchCase(
          _pluginCase(selection, call, {'legend': legend}),
          12,
          _settings,
          onChart: (chart) {
            expect(readByName(chart.data, 'datasets'), hasLength(3));
            expect(chart.options['events'], isEmpty);
            if (legend) {
              final box = chart.legend! as Legend;
              expect(readByName(box.options, 'display'), true, reason: reason);
              expect(
                readByName(box.options, 'position'),
                'top',
                reason: reason,
              );
              expect(box.legendItems, hasLength(3), reason: reason);
              expect(chart.boxes, contains(box));
            } else {
              expect(chart.legend, isNull, reason: reason);
            }
            // The title plugin and the subtitle plugin each add a box,
            // also with `display: false` (plugin.title.js:108-118, :129-131).
            final block = chart.titleBlock! as Title;
            expect(chart.boxes, contains(block));
            expect(jsGet(block.options, 'display'), title, reason: reason);
            if (title) {
              expect(jsGet(block.options, 'text'), 'Chart.js Line Chart');
            }
            // The scales of the docs blocks are visible.
            expect(chart.scales['x']!.options['display'], true);
            expect(chart.chartArea!.top, greaterThan(0), reason: reason);
          },
        );
        expect(line['legend'], legend);
        expect(line['title'], title);
        expect(line['primary'], call.frameMetric);
        for (final key in _figureKeys(call, _parts)) {
          expect(line[key], _figure, reason: '$reason $key');
        }
      }
    }
    expect(tester.takeException(), isNull);
  });

  test('the cases motion.line and motion.bar of phase 9', () {
    final cases = selectChartBenchCases('motion');
    expect([for (final c in cases) c.id], ['motion.line', 'motion.bar']);
    for (final c in cases) {
      final type = StressChartType.values.byName(c.name);
      expect(c.call, ChartBenchCall.motion);
      expect(c.primary, 'update');
      expect(c.counts, chartBenchMotionCounts);
      expect(c.keys, {
        'type': type.name,
        'sharing': type.sharing,
        'scriptable': false,
      });
    }
    expect(chartBenchMotionCounts, [1000, 20000]);
  });

  testWidgets('a motion case animates each update and ends the animations '
      'before the next one', (tester) async {
    for (final selection in ['motion.line', 'motion.bar']) {
      final benchCase = _case(selection);
      final scene = benchCase.scene(10);
      final config = scene.config;
      // The default animations on the animated platform.
      final options = config['options']! as Map<String, Object?>;
      expect(options.containsKey('animation'), isFalse);
      Chart? seen;
      final line = runChartBenchCase(
        benchCase,
        10,
        _settings,
        onChart: (chart) {
          seen = chart;
          // The update of the last iteration runs its animations: the
          // animator has them, and no frame ticked them.
          expect(animator.has(chart), isTrue, reason: selection);
          expect(chart.options['animation'], isNot(false));
        },
      );
      expect(seen, isNotNull);
      expect(line['mode'], 'motion');
      expect(line['case'], benchCase.name);
      expect(line['call'], 'motion');
      expect(line['primary'], 'update');
      for (final key in _figureKeys(ChartBenchCall.motion, _parts)) {
        expect(line[key], _figure, reason: '$selection $key');
      }
      // The update renders no frame: the animator would draw it.
      expect(_median(line, 'draw'), 0);
    }
  });

  test('the cases of the mode theme of phase 9 (the night record B-R1)', () {
    expect(chartBenchThemeTypes, [
      'line',
      'bar',
      'scatter',
      'radar',
      'doughnut',
    ]);
    expect(chartBenchThemes, const [
      ChartThemeData.light(),
      ChartThemeData.dark(),
    ]);
    final cases = selectChartBenchCases('theme');
    // The doughnut has 1 dataset, the other types 3.
    String row(String name, String type, List<int> counts) =>
        'theme.$name {type: $type, datasets: ${type == 'doughnut' ? 1 : 3}} '
        '$counts';
    expect(
      [for (final c in cases) '${c.id} ${c.keys} ${c.counts}'],
      [
        for (final name in ['switch', 'anim'])
          for (final type in chartBenchThemeTypes)
            row(name, type, chartBenchPluginCounts),
        row('equal', 'line', [100]),
      ],
    );
    for (final c in cases) {
      expect(c.call, ChartBenchCall.frame, reason: c.id);
      expect(c.primary, 'update+draw+end', reason: c.id);
    }
    expect(selectChartBenchCases('theme.switch'), hasLength(5));
    expect(selectChartBenchCases('theme.anim'), hasLength(5));
    expect(selectChartBenchCases('theme.equal'), hasLength(1));
  });

  testWidgets('theme.switch switches the preset in each frame and ends the '
      'transition', (tester) async {
    for (final type in chartBenchThemeTypes) {
      final scene = _pluginCase('theme.switch', ChartBenchCall.frame, {
        'type': type,
      }).scene(12);
      // The widget form: the compiled light preset under `$theme` of the root
      // config before `new Chart`, and the palette hooks last.
      expect(scene.config.keys, contains(r'$theme'), reason: type);
      final plugins = scene.config['plugins']! as List<Object?>;
      expect(jsGet(plugins.last, 'id'), r'$chartView', reason: type);
      final chart = Chart(
        UiCanvasElement(width: chartBenchWidth, height: chartBenchHeight),
        scene.config,
      );
      addTearDown(chart.destroy);
      scene.prepare!(chart);
      expect(animator.has(chart), isFalse, reason: type);
      final dataset =
          (readByName(chart.data, 'datasets')! as List<Object?>).first!
              as Map<String, Object?>;
      // The colors plugin colors the datasets from the palette of the theme
      // (plugin.colors.ts:102-125).
      expect(dataset['backgroundColor'], isNotNull, reason: type);
      final element = chart.getDatasetMeta(0).data.first;
      for (final (color, surface) in [
        ('rgba(153, 153, 153, 1)', 'rgba(0, 0, 0, 1)'),
        ('rgba(102, 102, 102, 1)', 'rgba(255, 255, 255, 1)'),
        ('rgba(153, 153, 153, 1)', 'rgba(0, 0, 0, 1)'),
      ]) {
        scene.frame!(chart);
        expect(chart.options['color'], color, reason: type);
        // The frame ends the transition: no animation stays.
        expect(animator.has(chart), isFalse, reason: type);
        // The switch removes the palette colors, and the update colors the
        // dataset again.
        expect(dataset['backgroundColor'], isNotNull, reason: type);
        if (type == 'doughnut') {
          // The arc border is the surface (element.arc.ts:379).
          expect((element.options! as JsObjectFace)['borderColor'], surface);
        }
      }
    }
    final line = runChartBenchCase(
      _pluginCase('theme.switch', ChartBenchCall.frame, {'type': 'bar'}),
      12,
      _settings,
    );
    expect(line['mode'], 'theme');
    expect(line['case'], 'switch');
    expect(line['type'], 'bar');
    expect(line['datasets'], 3);
    expect(line['call'], 'frame');
    expect(line['primary'], 'update+draw+end');
    for (final key in _figureKeys(ChartBenchCall.frame, _parts)) {
      expect(line[key], _figure, reason: key);
    }
    expect(_median(line, 'draw'), greaterThan(0));
    expect(line['notifies'], greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('theme.anim ticks the transition of 200 ms in 12 frames', (
    tester,
  ) async {
    final scene = _pluginCase('theme.anim', ChartBenchCall.frame, {
      'type': 'doughnut',
    }).scene(12);
    final chart = Chart(
      UiCanvasElement(width: chartBenchWidth, height: chartBenchHeight),
      scene.config,
    );
    addTearDown(chart.destroy);
    scene.prepare!(chart);
    final element = chart.getDatasetMeta(0).data.first;
    const black = 'rgba(0, 0, 0, 1)';
    const white = 'rgba(255, 255, 255, 1)';
    expect((element.options! as JsObjectFace)['borderColor'], white);
    final borders = <Object?>[];
    for (var i = 0; i < 2 * chartBenchFadeFrames; i++) {
      scene.frame!(chart);
      borders.add((element.options! as JsObjectFace)['borderColor']);
    }
    const f = chartBenchFadeFrames;
    // The arc border animates from the light surface to the dark surface in
    // the first transition and back in the second one. The colors
    // interpolator gives the hex string of a grey between the ends
    // (core.animations.defaults.js, the `hexString` of @kurkle/color), and
    // the last frame gives the end value.
    expect(borders[f - 1], black);
    expect(borders[2 * f - 1], white);
    final between = [
      ...borders.sublist(0, f - 1),
      ...borders.sublist(f, 2 * f - 1),
    ];
    for (final border in between) {
      expect(border, isNot(anyOf(black, white)));
      expect(border, matches(RegExp(r'^#([0-9A-F]{3}|[0-9A-F]{6})$')));
    }
    expect(between.toSet(), hasLength(between.length));
    // The timed case draws in each frame only for the doughnut: in the
    // other types, both presets share the palette, so the first tick ends
    // each element animation and most frames draw nothing (the draw median
    // of the line case can be 0).
    final doughnut = runChartBenchCase(
      _pluginCase('theme.anim', ChartBenchCall.frame, {'type': 'doughnut'}),
      12,
      _settings,
    );
    expect(doughnut['case'], 'anim');
    expect(_median(doughnut, 'draw'), greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('theme.equal stops at the == of the switch: no update', (
    tester,
  ) async {
    final line = runChartBenchCase(_case('theme.equal'), 100, _settings);
    expect(line['mode'], 'theme');
    expect(line['case'], 'equal');
    expect(line['type'], 'line');
    expect(line['n'], 100);
    // No notify and no draw: the frame calls no `chart.update`.
    expect(line['notifies'], 0);
    expect(line['drawMedianMs'], '0.000');
    for (final key in _figureKeys(ChartBenchCall.frame, _parts)) {
      expect(line[key], _figure, reason: key);
    }
    for (final part in _parts) {
      expect(line['${part}MedianMs'], '0.000', reason: part);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('each BENCH line has the notify count of one iteration', (
    tester,
  ) async {
    final draw = runChartBenchCase(_case('chart.a'), 10, _settings);
    // beforeDraw, beforeDatasetsDraw, beforeDatasetDraw, afterDatasetDraw,
    // afterDatasetsDraw and afterDraw: 6 for the draw of one dataset.
    expect(draw['notifies'], 6);
    expect(draw.keys, isNot(contains('primary')));
  });

  test('the explicit cases of phase 10 leave the older selectors as they '
      'were', () {
    // The default run, the mode chart and the mode motion select the same
    // cases as before the explicit cases (Chart.js ADR 0053).
    expect(selectChartBenchCases(''), chartBenchCases);
    expect(chartBenchCases.where((c) => c.explicit), isEmpty);
    expect(selectChartBenchCases('chart'), hasLength(16));
    expect(
      [for (final c in selectChartBenchCases('motion')) c.id],
      [
        'motion.line',
        'motion.bar',
      ],
    );
    expect(selectChartBenchCases('line'), [
      for (final c in chartBenchCases)
        if (c.name == 'line') c,
    ]);
    expect(
      [for (final c in chartBenchExplicitCases) c.id],
      [
        'motion.line.delay',
        'chart.c.indexable',
        'chart.line.primitive',
      ],
    );
    for (final c in chartBenchExplicitCases) {
      expect(c.explicit, isTrue, reason: c.id);
      expect(selectChartBenchCases(c.id), [c], reason: c.id);
      // A name alone selects no case.
      expect(() => selectChartBenchCases(c.name), throwsArgumentError);
    }
    expect(
      [
        for (final c in selectChartBenchCases('motion,motion.line.delay')) c.id,
      ],
      ['motion.line', 'motion.bar', 'motion.line.delay'],
    );
    expect(
      selectChartBenchCases('chart,chart.c.indexable,chart.line.primitive'),
      hasLength(18),
    );
    final delay = _case('motion.line.delay');
    expect(delay.call, ChartBenchCall.motion);
    expect(delay.counts, chartBenchMotionCounts);
    expect(delay.primary, 'update');
    final indexable = _case('chart.c.indexable');
    final primitive = _case('chart.line.primitive');
    for (final c in [indexable, primitive]) {
      expect(c.call, ChartBenchCall.update, reason: c.id);
      expect(c.counts, isNull, reason: c.id);
      expect(c.primary, 'update+draw+end', reason: c.id);
    }
    expect(
      stressDelayByIndex(<String, Object?>{
        'type': 'data',
        'dataIndex': 3.0,
      }),
      3.0,
    );
    expect(stressDelayByIndex(<String, Object?>{'type': 'dataset'}), 0.0);
  });

  testWidgets('a tiny run of each explicit case of phase 10 gives its keys '
      'and parts', (tester) async {
    const n = 50;
    for (final benchCase in chartBenchExplicitCases) {
      final reason = benchCase.id;
      final lines = await _benchLines(() async {
        await _runApp(
          tester,
          // A new key for each case: a new state runs the new case.
          ChartBenchApp(
            key: ValueKey(benchCase.id),
            cases: [benchCase],
            counts: const [n],
            settings: const ChartBenchSettings(
              batches: 1,
              batchMs: 10,
              warmupMs: 0,
            ),
          ),
        );
      });
      expect(lines, hasLength(2), reason: reason);
      expect(lines.last, 'BENCH done', reason: reason);
      final line = jsonDecode(
        lines.first.substring('BENCH '.length),
      ) as Map<String, Object?>;
      expect(line['mode'], benchCase.mode, reason: reason);
      expect(line['case'], benchCase.name, reason: reason);
      expect(line['n'], n, reason: reason);
      expect(line['call'], benchCase.call.name, reason: reason);
      expect(line['primary'], benchCase.call.frameMetric, reason: reason);
      for (final MapEntry(:key, :value) in benchCase.keys.entries) {
        expect(line[key], value, reason: '$reason $key');
      }
      for (final key in _figureKeys(benchCase.call, _parts)) {
        expect(line[key], _figure, reason: '$reason $key');
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('motion.line.delay gives each point the delay of its index', (
    tester,
  ) async {
    var checked = false;
    runChartBenchCase(
      _case('motion.line.delay'),
      10,
      _settings,
      onChart: (chart) {
        checked = true;
        // The update of the last iteration runs its animations.
        expect(animator.has(chart), isTrue);
        final points = chart.getDatasetMeta(0).data;
        double start(int index) {
          final point = points[index] as PointElement;
          final animation = point.$animations!['x']! as port.Animation;
          // The start time of the animation (core.animation.js:37).
          // ignore: invalid_use_of_internal_member
          return animation.start;
        }

        // `start` is `Date.now() + delay`, and the delay of point i is i ms
        // (core.animation.js:37). Each update reads the clock once for each
        // animation, so two starts can differ by the clock too.
        expect(start(9) - start(0), greaterThanOrEqualTo(9));
        expect(start(5) - start(0), greaterThanOrEqualTo(5));
      },
    );
    expect(checked, isTrue);
  });

  testWidgets('chart.c.indexable and chart.line.primitive build the charts '
      'of their forms', (tester) async {
    var indexable = false;
    runChartBenchCase(
      _case('chart.c.indexable'),
      10,
      _settings,
      onChart: (chart) {
        indexable = true;
        final points = [
          for (final element in chart.getDatasetMeta(0).data)
            element as PointElement,
        ];
        // The indexable color gives the color of the index modulo 2.
        expect(
          (points[0].options! as JsObjectFace)['backgroundColor'],
          stressChartBackground,
        );
        expect(
          (points[1].options! as JsObjectFace)['backgroundColor'],
          stressChartBackgroundOdd,
        );
        expect(
          (points[2].options! as JsObjectFace)['backgroundColor'],
          stressChartBackground,
        );
      },
    );
    expect(indexable, isTrue);

    final scene = _case('chart.line.primitive').scene(10);
    final datasets =
        (scene.config['data']! as Map<String, Object?>)['datasets']!
            as List<Object?>;
    final data =
        (datasets.single! as Map<String, Object?>)['data']! as List<Object?>;
    final before = List.of(data);
    scene.change!();
    // The change writes new numbers into the same List.
    expect(data, hasLength(10));
    expect(data, isNot(before));
    expect(data.every((value) => value is double), isTrue);

    var primitive = false;
    runChartBenchCase(
      _case('chart.line.primitive'),
      10,
      _settings,
      onChart: (chart) {
        primitive = true;
        final meta = chart.getDatasetMeta(0);
        expect(chart.options['parsing'], isNot(false));
        expect(meta.data, hasLength(10));
        expect(chart.scales['x']!.type, 'category');
        // The parse gives new parsed items: x is the index, y the number.
        // The parsed items of the meta (core.datasetController.js:353).
        // ignore: invalid_use_of_internal_member
        final parsed = meta.parsed.first! as JsObjectFace;
        expect(parsed['x'], 0);
        expect(parsed['y'], isA<double>());
      },
    );
    expect(primitive, isTrue);
  });
}
