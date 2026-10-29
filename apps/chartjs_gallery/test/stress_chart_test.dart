// Original code, not ported from Chart.js: tests of the stress mode chart.

import 'dart:convert';
import 'dart:math' as math;

import 'package:chartjs_gallery/bench/chart_bench.dart'
    show chartBenchHeight, chartBenchOptions, chartBenchWidth;
import 'package:chartjs_gallery/demo/chart_canvas.dart';
import 'package:chartjs_gallery/demo/demo_chart.dart' show DemoCanvasState;
import 'package:chartjs_gallery/demo/gallery_components.dart';
import 'package:chartjs_gallery/demo/stress_chart_config.dart';
import 'package:chartjs_gallery/demo/stress_demo.dart';
import 'package:chartjs_gallery/main_stress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/controllers/index.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/elements/element_options.dart';
import 'package:flutter_chartjs_port/src/elements/index.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart'
    show jsGet, jsObjectIsFrozen;
import 'package:flutter_chartjs_port/src/platform/platform.flutter.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.legend.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/widgets/chart_view.dart';
import 'package:flutter_test/flutter_test.dart';

import 'stress_controls.dart';

/// The point count of these tests: small, so that a frame is fast.
const int _n = 300;

/// Pumps [count] frames of 20 ms. The loop runs, so pumpAndSettle would not
/// return.
Future<void> _frames(WidgetTester tester, [int count = 4]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

/// Pumps a stress tab in the mode chart with [n] items of [type] and [m]
/// labels. It gives the list that receives the published figures.
Future<List<StressStats>> _pumpChart(
  WidgetTester tester, {
  StressChartCall call = StressChartCall.draw,
  StressChartType type = StressChartType.line,
  bool showLine = false,
  bool scriptable = false,
  bool autoStart = true,
  int n = _n,
  int m = 10,
}) async {
  final stats = <StressStats>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StressDemo(
          initialMode: StressMode.chart,
          initialN: n,
          initialM: m,
          initialCall: call,
          initialType: type,
          initialShowLine: showLine,
          initialScriptable: scriptable,
          autoStart: autoStart,
          onStats: stats.add,
        ),
      ),
    ),
  );
  return stats;
}

/// The state of the stress tab.
StressDemoState _state(WidgetTester tester) =>
    tester.state<StressDemoState>(find.byType(StressDemo));

/// The chart of the stress tab.
Chart _chart(WidgetTester tester) => _state(tester).debugChart!;

/// The point elements of the chart.
List<PointElement> _points(WidgetTester tester) => [
  for (final element in _chart(tester).getDatasetMeta(0).data)
    element as PointElement,
];

/// Taps the control of [key] (stressTap), then pumps frames.
Future<void> _tap(WidgetTester tester, String key) async {
  await stressTap(tester, key);
  await _frames(tester);
}

/// Whether the control of [key] is selected.
Future<bool> _selected(WidgetTester tester, String key) =>
    stressSelected(tester, key);

/// The controller class of each chart type.
final Map<StressChartType, Matcher> _controllerClass = {
  StressChartType.line: isA<LineController>(),
  StressChartType.scatter: isA<ScatterController>(),
  StressChartType.bar: isA<BarController>(),
  StressChartType.bubble: isA<BubbleController>(),
  StressChartType.doughnut: isA<DoughnutController>(),
  StressChartType.pie: isA<PieController>(),
  StressChartType.polarArea: isA<PolarAreaController>(),
  StressChartType.radar: isA<RadarController>(),
};

/// The data element class of each chart type.
final Map<StressChartType, Matcher> _elementClass = {
  StressChartType.line: isA<PointElement>(),
  StressChartType.scatter: isA<PointElement>(),
  StressChartType.bar: isA<BarElement>(),
  StressChartType.bubble: isA<PointElement>(),
  StressChartType.doughnut: isA<ArcElement>(),
  StressChartType.pie: isA<ArcElement>(),
  StressChartType.polarArea: isA<ArcElement>(),
  StressChartType.radar: isA<PointElement>(),
};

/// A frameless chart of [scene] on a `UiCanvasElement` of the benchmark
/// size, as the frameless benchmark makes it (`BasicPlatform`, no host).
Chart _framelessChart(StressChartScene scene) {
  registerGalleryComponents();
  return Chart(
    UiCanvasElement(width: chartBenchWidth, height: chartBenchHeight),
    stressChartConfig(
      scene: scene,
      scriptable: false,
      options: chartBenchOptions,
    ),
  );
}

/// Checks that the controller of [chart] draws all [n] points, that no
/// point has `skip`, and that each point is at the pixel of the fractions
/// of [scene] within 1e-9 px (Chart.js ADR 0031, section 3).
void _expectAllDrawn(Chart chart, StressChartScene scene, int n, String at) {
  final meta = chart.getDatasetMeta(0);
  final controller = meta.controller!;
  // The test reads `_drawStart` and `_drawCount` of the controller, as the
  // draw does (core.datasetController.js:723-736).
  // ignore: invalid_use_of_internal_member
  final drawStart = controller.drawStart;
  // See drawStart.
  // ignore: invalid_use_of_internal_member
  final drawCount = controller.drawCount;
  expect(drawStart == null || drawStart == 0, isTrue, reason: at);
  expect(drawCount == null || drawCount == n, isTrue, reason: at);
  final area = chart.chartArea!;
  final points = meta.data;
  expect(points, hasLength(n), reason: at);
  for (var i = 0; i < n; i++) {
    final point = points[i] as PointElement;
    final item = scene.data[i]! as Map<String, Object?>;
    final x = item['x']! as double;
    final y = item['y']! as double;
    if (point.skip == true ||
        (point.x - (area.left + x * area.width)).abs() > 1e-9 ||
        (point.y - (area.bottom - y * area.height)).abs() > 1e-9) {
      fail(
        '$at: point $i at (${point.x}, ${point.y}), skip ${point.skip}, '
        'fractions ($x, $y), area ${area.left} ${area.top} ${area.right} '
        '${area.bottom}',
      );
    }
  }
}

/// Collects the STRESS lines of [body].
Future<List<Map<String, Object?>>> _stressLines(
  Future<void> Function() body,
) async {
  final lines = <String>[];
  final old = debugPrint;
  debugPrint = (message, {wrapWidth}) {
    if (message != null && message.startsWith('STRESS {')) {
      lines.add(message);
    }
  };
  try {
    await body();
  } finally {
    // flutter_test checks the debug variables before the tearDown.
    debugPrint = old;
  }
  return [
    for (final line in lines)
      jsonDecode(line.substring('STRESS '.length)) as Map<String, Object?>,
  ];
}

void main() {
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  for (final call in [StressChartCall.draw, StressChartCall.update]) {
    for (final type in [StressChartType.line, StressChartType.scatter]) {
      testWidgets(
        'chart, ${call.name}, ${type.name}: the loop runs the chart',
        (tester) async {
          final stats = await _pumpChart(tester, call: call, type: type);
          await _frames(tester, 10);
          final chart = _chart(tester);
          expect(chart.platform, isA<FlutterPlatform>());
          expect(chart.config.type, type.name);
          expect(chart.options['animation'], false);
          final meta = chart.getDatasetMeta(0);
          expect(meta.controller, _controllerClass[type]);
          expect(meta.controller!.enableOptionSharing, type.sharing);
          final points = _points(tester);
          expect(points, hasLength(_n));
          final first = (x: points.first.x, y: points.first.y);
          final canvas = tester
              .state<ChartCanvasState>(
                find.byKey(const ValueKey('stress.chart.host')),
              )
              .canvas;
          expect(canvas.getContext2d().isEmpty, isFalse);

          await _frames(tester, 10);
          // Case (a) draws the same points. Case (b) moves them through the
          // data objects and update('none').
          final moved = points.first.x != first.x || points.first.y != first.y;
          expect(moved, call == StressChartCall.update);
          expect(identical(_points(tester).first, points.first), isTrue);
          final data = _state(tester).debugChartData;
          expect(data, hasLength(_n));
          final area = chart.chartArea!;
          final item = data[7]! as Map<String, Object?>;
          expect(
            points[7].x,
            closeTo(area.left + (item['x']! as double) * area.width, 1e-9),
          );
          expect(
            points[7].y,
            closeTo(area.bottom - (item['y']! as double) * area.height, 1e-9),
          );

          // The points get typed options. With the sharing, they hold the
          // one copy of getSharedOptions, as in a line chart. Without it,
          // each point holds its own copy of the cache entry, as in a scatter
          // chart (Chart.js ADR 0021, section 8).
          final options = points.first.options;
          expect(options, isA<PointOptions>());
          expect(jsObjectIsFrozen(options), isFalse);
          expect(identical(points[1].options, options), type.sharing);
          expect(options!['radius'], 3);
          expect(options['backgroundColor'], 'rgba(54, 162, 235, 0.45)');

          // Stopping publishes the figures.
          await _tap(tester, 'stress.start');
          expect(stats, isNotEmpty);
          expect(stats.last.mode, StressMode.chart);
          expect(stats.last.points, _n);
          expect(stats.last.labels, 10);
          expect(stats.last.frames, greaterThan(0));
          expect(stats.last.sharing, type.sharing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final type in StressChartType.values) {
    testWidgets('chart, ${type.name}: the controller of the type at '
        '${type.counts.first} items', (tester) async {
      await _pumpChart(
        tester,
        type: type,
        n: type.counts.first,
        m: 0,
        call: StressChartCall.update,
      );
      await _frames(tester, 6);
      final chart = _chart(tester);
      expect(chart.config.type, type.name);
      final meta = chart.getDatasetMeta(0);
      expect(meta.type, type.name);
      expect(meta.controller, _controllerClass[type]);
      expect(meta.controller!.enableOptionSharing, type.sharing);
      expect(meta.data, hasLength(type.counts.first));
      expect(meta.data.first, _elementClass[type]);
      // Only line and radar have a dataset element. Scatter has none with
      // showLine: false (controller.scatter.js:16).
      if (type == StressChartType.line || type == StressChartType.radar) {
        expect(meta.dataset, isA<LineElement>());
      } else {
        expect(meta.dataset, isNull);
      }
      // Bar, doughnut, pie, polarArea and radar have the labels `Point <i>`.
      expect(
        chart.data['labels'],
        hasLength(
          type.points || type == StressChartType.bubble ? 0 : type.counts.first,
        ),
      );
      await _tap(tester, 'stress.start');
      expect(tester.takeException(), isNull);
    });
  }

  for (final type in [StressChartType.line, StressChartType.scatter]) {
    test('${type.name}, update: 600 frames at 5000 points draw all points at '
        'the fraction pixels', () {
      const n = 5000;
      final field = StressPointField(n);
      final scene = StressChartScene(type, n, field);
      final chart = _framelessChart(scene);
      try {
        // The data of the field is not sorted by x, and each bounce clamps
        // a position to exactly 0 or 1 (stress_chart_config.dart).
        // `_sorted` of the meta is internal (Chart.js ADR 0048, section 6).
        // ignore: invalid_use_of_internal_member
        expect(chart.getDatasetMeta(0).sorted, isTrue);
        _expectAllDrawn(chart, scene, n, 'start');
        var bounds = 0;
        for (var frame = 0; frame < 600; frame++) {
          scene.write(field..step(n, 1 / 60));
          chart.update('none');
          _expectAllDrawn(chart, scene, n, 'frame $frame');
          for (var i = 0; i < n; i++) {
            if (field.x[i] == 0 || field.x[i] == 1) bounds++;
          }
        }
        // The loop has bounces: points at x = 0 and x = 1.
        expect(bounds, greaterThan(0));
      } finally {
        chart.destroy();
      }
    });

    test('${type.name}: unsorted x with a point at x = 1 in the middle: all '
        'points draw', () {
      const xs = [0.4, 0.9, 1.0, 0.0, 0.25, 1.0, 0.6];
      final field = StressPointField(xs.length);
      for (var i = 0; i < xs.length; i++) {
        field.x[i] = xs[i];
      }
      final scene = StressChartScene(type, xs.length, field);
      final chart = _framelessChart(scene);
      try {
        _expectAllDrawn(chart, scene, xs.length, 'trap');
        final x = chart.scales['x']!;
        expect((x.min, x.max), (0, 1));
      } finally {
        chart.destroy();
      }
    });

    test('${type.name}: the chart area is the canvas, and the dataset has no '
        'clip', () {
      final scene = StressChartScene(type, 50, StressPointField(50));
      final chart = _framelessChart(scene);
      try {
        final area = chart.chartArea!;
        expect(
          (area.left, area.top, area.right, area.bottom),
          (0, 0, chartBenchWidth, chartBenchHeight),
        );
        // `_clip` of the meta is internal (Chart.js ADR 0048, section 6).
        // ignore: invalid_use_of_internal_member
        expect(chart.getDatasetMeta(0).clip.disabled, isTrue);
        final y = chart.scales['y']!;
        expect((y.min, y.max), (0, 1));
        expect(y.options['display'], false);
      } finally {
        chart.destroy();
      }
    });
  }

  for (final type in [StressChartType.polarArea, StressChartType.radar]) {
    test('${type.name}: the range of r is 0 to 1 after an update', () {
      final field = StressPointField(100);
      final scene = StressChartScene(type, 100, field);
      final chart = _framelessChart(scene);
      try {
        scene.write(field..step(100, 0.5));
        chart.update('none');
        final r = chart.scales['r']!;
        expect((r.min, r.max), (0, 1));
      } finally {
        chart.destroy();
      }
    });
  }

  for (final type in [StressChartType.doughnut, StressChartType.pie]) {
    test('${type.name}: each arc has the outer radius of the chart area', () {
      final scene = StressChartScene(type, 100, StressPointField(100));
      final chart = _framelessChart(scene);
      try {
        final meta = chart.getDatasetMeta(0);
        // The default radius '100%' of the controller applies: the dataset
        // has no radius (controller.doughnut.js:216-229, with borderWidth 1,
        // no offset and no spacing).
        expect(meta.controller!.options['radius'], '100%');
        final area = chart.chartArea!;
        final expected =
            (math.min(area.right - area.left, area.bottom - area.top) - 1) / 2;
        expect(expected, greaterThan(100));
        for (final element in meta.data) {
          final arc = element as ArcElement;
          expect(arc.outerRadius, closeTo(expected, 1e-9));
          expect(
            arc.innerRadius,
            closeTo(type == StressChartType.doughnut ? expected / 2 : 0, 1e-9),
          );
        }
      } finally {
        chart.destroy();
      }
    });
  }

  for (final type in StressChartType.values) {
    test('${type.name}: the chart has no legend (Chart.js ADR 0031, Open)', () {
      final field = StressPointField(20);
      final chart = _framelessChart(StressChartScene(type, 20, field));
      // The same config without the opt-out: the legend of registerables
      // displays by default (plugin.legend.js:637-639).
      final withLegend = Chart(
        UiCanvasElement(width: chartBenchWidth, height: chartBenchHeight),
        stressChartConfig(
          scene: StressChartScene(type, 20, field),
          scriptable: false,
          options: {...chartBenchOptions, 'plugins': <String, Object?>{}},
        ),
      );
      try {
        // `plugins.legend: false` disables the plugin for the chart
        // (core.plugins.js:146-149, :163-165): it starts no legend.
        expect(chart.legend, isNull);
        expect(chart.boxes.whereType<Legend>(), isEmpty);
        final legend = withLegend.legend! as Legend;
        expect(withLegend.boxes, contains(legend));
        expect(legend.height, greaterThan(0));
        // A doughnut, pie or polar area legend has one item for each arc
        // (controller.doughnut.js:93-129, controller.polarArea.js:36-69).
        final arcs =
            type == StressChartType.doughnut ||
            type == StressChartType.pie ||
            type == StressChartType.polarArea;
        expect(legend.legendItems, hasLength(arcs ? 20 : 1));
        expect(
          withLegend.chartArea!.top,
          greaterThan(chart.chartArea!.top),
        );
      } finally {
        chart.destroy();
        withLegend.destroy();
      }
    });
  }

  test('StressChartScene: the data of each type, and the write', () {
    final field = StressPointField(4);
    for (final type in StressChartType.values) {
      final scene = StressChartScene(type, 4, field);
      expect(scene.data, hasLength(4), reason: type.name);
      expect(
        scene.labels,
        type.points || type == StressChartType.bubble
            ? isEmpty
            : ['Point 0', 'Point 1', 'Point 2', 'Point 3'],
        reason: type.name,
      );
    }
    final line = StressChartScene(StressChartType.line, 4, field);
    expect(line.data[2], {'x': field.x[2], 'y': field.y[2]});
    final bubble = StressChartScene(StressChartType.bubble, 4, field);
    final r = (bubble.data[1]! as Map<String, Object?>)['r']! as double;
    final v = field.vx[1] / 0.3;
    expect(r, 2 + 4 * v * v);
    final bar = StressChartScene(StressChartType.bar, 4, field);
    expect(bar.data[3], field.y[3]);
    final pie = StressChartScene(StressChartType.pie, 4, field);
    expect(pie.data[0], 0.05 + 0.95 * field.y[0]);

    field.step(4, 0.5);
    for (final scene in [line, bubble, bar, pie]) {
      scene.write(field);
    }
    expect(line.data[2], {'x': field.x[2], 'y': field.y[2]});
    // bubble keeps its r.
    expect(bubble.data[1], {'x': field.x[1], 'y': field.y[1], 'r': r});
    expect(bar.data[3], field.y[3]);
    expect(pie.data[0], 0.05 + 0.95 * field.y[0]);
  });

  test('stressChartConfig: the options of each type', () {
    final field = StressPointField(3);
    AnyObject config(StressChartType type, {bool showLine = false}) =>
        stressChartConfig(
          scene: StressChartScene(type, 3, field),
          scriptable: false,
          showLine: showLine,
        );
    for (final type in StressChartType.values) {
      final c = config(type);
      final options = c['options']! as Map<String, Object?>;
      final dataset =
          ((c['data']! as Map<String, Object?>)['datasets']! as List).single
              as Map<String, Object?>;
      expect(c['type'], type.name);
      expect(options['events'], isEmpty);
      expect(options['plugins'], {'legend': false});
      expect(dataset.containsKey('optionSharing'), isFalse);
      expect(dataset['backgroundColor'], stressChartBackground);
      if (type.points) {
        expect(options['parsing'], false);
        expect(options['layout'], {'autoPadding': false});
        expect(options['scales'], unitScales(hideTicks: true));
        expect(dataset['showLine'], false);
        expect(dataset['clip'], false);
        expect(dataset['pointStyle'], 'circle');
        expect(dataset['radius'], 3.0);
      } else {
        expect(options.containsKey('parsing'), isFalse);
        expect(dataset.containsKey('pointStyle'), isFalse);
        expect(dataset.containsKey('radius'), isFalse);
        expect(dataset.containsKey('showLine'), isFalse);
        expect(dataset.containsKey('clip'), isFalse);
      }
    }
    expect(
      (config(StressChartType.doughnut)['options']! as Map<String, Object?>)
          .containsKey('scales'),
      isFalse,
    );
    final radar = config(StressChartType.radar)['options']!;
    expect(
      (radar as Map<String, Object?>)['scales'],
      {
        'r': {
          'type': 'radialLinear',
          'display': false,
          'ticks': {'display': false},
          'min': 0,
          'max': 1,
        },
      },
    );
    final scatter = config(StressChartType.scatter, showLine: true);
    expect(
      (((scatter['data']! as Map<String, Object?>)['datasets']! as List).single
          as Map<String, Object?>)['showLine'],
      true,
    );
    expect(
      () => config(StressChartType.bar, showLine: true),
      throwsArgumentError,
    );
  });

  testWidgets('chart, update, scriptable: each point resolves its color', (
    tester,
  ) async {
    await _pumpChart(
      tester,
      call: StressChartCall.update,
      scriptable: true,
    );
    await _frames(tester, 10);
    final points = _points(tester);
    final options = points.first.options;
    // A scriptable option needs the context: no sharing (core.config.js:
    // 355-356), and no cache entry.
    expect(options, isA<PointOptions>());
    expect(options![r'$shared'], false);
    expect(identical(points[2].options, options), isFalse);
    expect(options['backgroundColor'], 'rgba(54, 162, 235, 0.45)');
    expect(points[1].options!['backgroundColor'], 'rgba(255, 99, 132, 0.45)');
    final before = points[1].options;
    await _frames(tester, 3);
    // Each update resolves the options again.
    expect(identical(points[1].options, before), isFalse);
    await _tap(tester, 'stress.start');
    expect(tester.takeException(), isNull);
  });

  testWidgets('chart: the controls have keys and make a new chart', (
    tester,
  ) async {
    await _pumpChart(tester, autoStart: false);
    await _frames(tester);
    for (final key in [
      'stress.mode.chart',
      'stress.chart.host',
      'stress.chart.call.draw',
      'stress.chart.call.update',
      for (final type in StressChartType.values)
        'stress.chart.type.${type.name}',
      'stress.chart.showLine',
      'stress.chart.scriptable',
      'stress.n.1000',
      'stress.m.0',
      'stress.spin',
      'stress.start',
      'stress.stats',
    ]) {
      expect(await stressControlExists(tester, key), isTrue, reason: key);
    }
    expect(await stressControlExists(tester, 'stress.chart.sharing'), isFalse);
    expect(await _selected(tester, 'stress.mode.chart'), isTrue);
    expect(await _selected(tester, 'stress.chart.type.line'), isTrue);
    expect(await _selected(tester, 'stress.chart.call.draw'), isTrue);
    expect(await _selected(tester, 'stress.chart.showLine'), isFalse);
    expect(await stressControlExists(tester, 'stress.layer.points'), isFalse);
    expect(find.byKey(const ValueKey('stress.host')), findsNothing);
    // The type segments show their icons, with the key on the icon.
    expect(
      tester.widget(find.byKey(const ValueKey('stress.chart.type.radar'))),
      isA<Icon>().having((i) => i.icon, 'icon', Icons.radar),
    );
    final first = _chart(tester);

    // The call changes the frames, not the chart.
    await _tap(tester, 'stress.chart.call.update');
    expect(await _selected(tester, 'stress.chart.call.update'), isTrue);
    expect(identical(_chart(tester), first), isTrue);

    // showLine makes a new chart with the line. The old chart is destroyed.
    await _tap(tester, 'stress.chart.showLine');
    final second = _chart(tester);
    expect(identical(second, first), isFalse);
    expect(first.canvas, isNull);
    expect(await _selected(tester, 'stress.chart.showLine'), isTrue);
    final line = second.getDatasetMeta(0).dataset! as LineElement;
    expect(line.options!['borderWidth'], 1);

    // N makes a new chart of N points.
    await _tap(tester, 'stress.n.1000');
    expect(_points(tester), hasLength(1000));
    expect(identical(_chart(tester), second), isFalse);

    // The scriptable color makes a new chart.
    final third = _chart(tester);
    await _tap(tester, 'stress.chart.scriptable');
    expect(identical(_chart(tester), third), isFalse);
    expect(
      _points(tester)[1].options!['backgroundColor'],
      'rgba(255, 99, 132, 0.45)',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('chart: each type segment makes a chart of its type', (
    tester,
  ) async {
    await _pumpChart(tester, autoStart: false, m: 0);
    await _frames(tester);
    // The first N of the point counts. A new type keeps the index of N.
    await _tap(tester, 'stress.n.1000');
    var chart = _chart(tester);
    for (final type in [
      ...StressChartType.values.skip(1),
      StressChartType.line,
    ]) {
      final key = 'stress.chart.type.${type.name}';
      await _tap(tester, key);
      expect(await _selected(tester, key), isTrue, reason: key);
      final next = _chart(tester);
      expect(identical(next, chart), isFalse, reason: key);
      expect(chart.canvas, isNull, reason: key);
      chart = next;
      expect(chart.config.type, type.name, reason: key);
      expect(
        chart.getDatasetMeta(0).controller,
        _controllerClass[type],
        reason: key,
      );
      // The N line shows the counts of the type, and the index of N stays.
      for (final count in {...stressPointCounts, ...stressArcCounts}) {
        expect(
          await stressControlExists(tester, 'stress.n.$count'),
          type.counts.contains(count),
          reason: '$key $count',
        );
      }
      expect(
        await _selected(tester, 'stress.n.${type.counts.first}'),
        isTrue,
        reason: key,
      );
      expect(
        chart.getDatasetMeta(0).data,
        hasLength(type.counts.first),
        reason: key,
      );
      expect(
        await stressControlExists(tester, 'stress.chart.showLine'),
        type.points,
        reason: key,
      );
      expect(
        await stressControlExists(tester, 'stress.chart.sharing'),
        isFalse,
        reason: key,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('chart: the call animate makes a new chart, and the loop goes '
      'on', (tester) async {
    final stats = await _pumpChart(tester);
    await _frames(tester, 10);
    var chart = _chart(tester);
    expect(chart.options['animation'], false);
    for (final (key, animated) in [
      ('stress.chart.call.animate', true),
      ('stress.chart.call.draw', false),
    ]) {
      // A change to or from animate gives another `animation` option, thus
      // a new chart. The old chart is destroyed.
      await _tap(tester, key);
      expect(await _selected(tester, key), isTrue, reason: key);
      final next = _state(tester).debugChart;
      expect(next, isNotNull, reason: key);
      expect(identical(next, chart), isFalse, reason: key);
      expect(chart.canvas, isNull, reason: key);
      expect(next!.options['animation'] != false, animated, reason: key);
      chart = next;
      // The running loop goes on with the new chart.
      final frames = _state(tester).debugFrames;
      await _frames(tester, 5);
      expect(_state(tester).debugFrames, greaterThan(frames), reason: key);
    }
    await _tap(tester, 'stress.start');
    expect(stats.last.frames, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('chart: a running loop goes on across the modes', (
    tester,
  ) async {
    final stats = await _pumpChart(tester, call: StressChartCall.update);
    await _frames(tester, 10);
    final x = _points(tester).first.x;
    await _frames(tester, 5);
    expect(_points(tester).first.x, isNot(x));

    // The elements mode gets a new host and goes on.
    await _tap(tester, 'stress.mode.elements');
    expect(_state(tester).debugChart, isNull);
    await _frames(tester, 10);
    final host = tester.state<DemoCanvasState>(
      find.byKey(const ValueKey('stress.host')),
    );
    final renders = host.chart!.renders;
    await _frames(tester, 5);
    expect(host.chart!.renders, greaterThan(renders));

    // The modes of the demo chart keep their host.
    await _tap(tester, 'stress.mode.bars');
    final bars = host.chart!.renders;
    await _frames(tester, 5);
    expect(host.chart!.renders, greaterThan(bars));

    // Back in the mode chart, a new chart runs.
    await _tap(tester, 'stress.mode.chart');
    await _frames(tester, 10);
    final again = _points(tester).first.x;
    await _frames(tester, 5);
    expect(_points(tester).first.x, isNot(again));
    await _tap(tester, 'stress.start');
    expect(stats.last.mode, StressMode.chart);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chart: a new mode takes the count at the index of N', (
    tester,
  ) async {
    await _pumpChart(
      tester,
      type: StressChartType.doughnut,
      n: 100,
      autoStart: false,
    );
    await _frames(tester);
    expect(await _selected(tester, 'stress.n.100'), isTrue);
    // 100 is the first count of a doughnut, and 1000 the first of the bars.
    await _tap(tester, 'stress.mode.bars');
    expect(await _selected(tester, 'stress.n.1000'), isTrue);
    expect(_state(tester).debugElements, hasLength(1000));
    expect(_state(tester).debugElements, everyElement(isA<BarElement>()));
    // 1000 is a count of the arcs too: N stays.
    await _tap(tester, 'stress.mode.arcs');
    expect(await _selected(tester, 'stress.n.1000'), isTrue);
    await _tap(tester, 'stress.n.100');
    await _tap(tester, 'stress.mode.primitives');
    expect(await _selected(tester, 'stress.n.1000'), isTrue);
    expect(tester.takeException(), isNull);
  });

  group('the timing split', () {
    /// Runs the mode chart with [call] for 4 windows of real time, and
    /// gives the published figures. The window of the figures is 500 ms of
    /// the Stopwatch, real time: runAsync lets it pass.
    Future<List<StressStats>> run(
      WidgetTester tester,
      StressChartCall call, {
      StressChartType type = StressChartType.line,
    }) async {
      final stats = await _pumpChart(tester, call: call, type: type);
      for (var k = 0; k < 4; k++) {
        await _frames(tester, 20);
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 520)),
        );
      }
      await _frames(tester, 3);
      return stats.where((s) => s.frames > 20).toList();
    }

    testWidgets('draw: drawMs only', (tester) async {
      final stats = await run(tester, StressChartCall.draw);
      expect(stats, isNotEmpty);
      final last = stats.last;
      expect(last.drawMs, greaterThan(0));
      expect(last.updateMs, lessThan(last.drawMs));
      expect(last.animatorMs, 0);
      // A draw has no element update, no layout and no dataset update.
      expect(last.elementsMs, 0);
      expect(last.layoutMs, 0);
      expect(last.datasetsUpdateMs, 0);
      expect(last.datasetsDrawMs, greaterThan(0));
      expect(last.datasetsDrawMs, lessThan(last.drawMs));
    });

    for (final type in [StressChartType.line, StressChartType.bar]) {
      testWidgets('update, ${type.name}: the four parts', (tester) async {
        final stats = await run(tester, StressChartCall.update, type: type);
        expect(stats, isNotEmpty);
        final last = stats.last;
        // update('none') draws: the draw inside it counts in drawMs, and the
        // rest in updateMs.
        expect(last.drawMs, greaterThan(0));
        expect(last.updateMs, greaterThan(0));
        expect(last.animatorMs, 0);
        expect(last.elementsMs, greaterThan(0));
        expect(last.layoutMs, greaterThan(0));
        expect(last.datasetsUpdateMs, greaterThan(0));
        // The three update parts are in the update time, without its draw.
        expect(
          last.elementsMs + last.layoutMs + last.datasetsUpdateMs,
          lessThan(last.updateMs),
        );
        expect(last.datasetsDrawMs, lessThan(last.drawMs));
      });
    }

    testWidgets('animate: the animator ticks and draws in each frame', (
      tester,
    ) async {
      final stats = await run(tester, StressChartCall.animate);
      final chart = _chart(tester);
      expect(chart.options['animation'], isNot(false));
      expect(chart.options['events'], isEmpty);
      expect(stats, isNotEmpty);
      expect(stats.last.drawMs, greaterThan(0));
      expect(stats.last.animatorMs, greaterThan(0));
      // The points move without an update: the animator writes x and y.
      final x = _points(tester).first.x;
      await _frames(tester, 5);
      expect(_points(tester).first.x, isNot(x));
      await _tap(tester, 'stress.start');
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('the chart listens to no event', (tester) async {
    // A pointer over the host would replay its last event in each update
    // (core.controller.js:528-534) and add a second draw to a frame.
    await _pumpChart(tester, call: StressChartCall.update);
    await _frames(tester, 3);
    expect(_chart(tester).options['events'], isEmpty);
  });

  for (final (type, showLine) in [
    (StressChartType.line, false),
    (StressChartType.scatter, true),
    (StressChartType.bar, false),
  ]) {
    testWidgets('main_stress gives the keys of the mode chart, ${type.name}, '
        'showLine $showLine', (tester) async {
      final lines = await _stressLines(() async {
        await tester.pumpWidget(
          StressProfileApp(
            mode: StressMode.chart,
            scenarios: const [(300, 0)],
            type: type,
            showLine: showLine,
          ),
        );
        await _frames(tester, 40);
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 600)),
        );
        await _frames(tester, 5);
        await tester.pump(const Duration(seconds: stressSeconds));
      });
      expect(lines, hasLength(1));
      final line = lines.single;
      expect(line['mode'], 'chart');
      expect(line['n'], 300);
      expect(line['call'], 'draw');
      expect(line['type'], type.name);
      expect(line['sharing'], type.sharing);
      expect(line['scriptable'], false);
      if (showLine) {
        expect(line['showLine'], true);
      } else {
        expect(line.keys, isNot(contains('showLine')));
      }
      for (final key in [
        'animatorMs',
        'elementsMs',
        'layoutMs',
        'datasetsUpdateMs',
        'datasetsDrawMs',
      ]) {
        expect(line[key], matches(RegExp(r'^\d+\.\d\d$')), reason: key);
      }
      final host = tester.state<ChartCanvasState>(
        find.byKey(const ValueKey('stress.chart.host')),
      );
      expect(host.chart!.config.type, type.name);
      expect(line['host'], 'canvas');
      for (final key in ['batches', 'batchFrames', 'buildP50Ms']) {
        expect(line.keys, contains(key));
      }
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final mode in [StressMode.chart, StressMode.plugins]) {
    testWidgets('main_stress hosts the chart of the mode ${mode.name} in a '
        'ChartView with HOST=view', (tester) async {
      final lines = await _stressLines(() async {
        await tester.pumpWidget(
          StressProfileApp(
            mode: mode,
            scenarios: const [(300, 0)],
            host: StressHost.view,
            pluginCase: const StressPluginCase(StressPluginScene.hover),
          ),
        );
        // ChartView starts its chart in the first layout of its host.
        expect(find.byType(ChartView), findsOneWidget);
        expect(find.byType(ChartCanvas), findsNothing);
        final chart = _state(tester).debugChart!;
        // A plain Chart: the widget makes it.
        expect(chart.runtimeType, Chart);
        expect(chart.platform, isA<FlutterPlatform>());
        final plugins = chart.config.plugins! as List<Object?>;
        expect(jsGet(plugins.first, 'id'), 'stressDrawStart');
        expect(jsGet(plugins.last, 'id'), 'stressDrawEnd');
        await _frames(tester, 40);
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 600)),
        );
        await _frames(tester, 5);
        // A rebuild of the tab gives the ChartView the same config.
        tester.element(find.byType(StressDemo)).markNeedsBuild();
        await _frames(tester, 2);
        expect(_state(tester).debugChart, same(chart));
        expect(chart.config.plugins, same(plugins));
        await tester.pump(const Duration(seconds: stressSeconds));
      });
      expect(lines, hasLength(1));
      final line = lines.single;
      expect(line['mode'], mode.name);
      expect(line['host'], 'view');
      expect(line['call'], mode == StressMode.chart ? 'draw' : 'frame');
      // The plugins of the meter time the draws of the chart.
      expect(double.parse(line['drawMs']! as String), greaterThan(0));
      await tester.pumpWidget(const SizedBox());
    });
  }

  test('the define HOST', () {
    for (final mode in [
      StressMode.chart,
      StressMode.axes,
      StressMode.plugins,
    ]) {
      expect(parseStressHost('', mode), StressHost.canvas);
      expect(parseStressHost('canvas', mode), StressHost.canvas);
      expect(parseStressHost('view', mode), StressHost.view);
      expect(() => parseStressHost('widget', mode), throwsArgumentError);
    }
    expect(parseStressHost('', StressMode.primitives), StressHost.canvas);
    expect(
      () => parseStressHost('view', StressMode.primitives),
      throwsArgumentError,
    );
    expect(
      () => parseStressHost('canvas', StressMode.bars),
      throwsArgumentError,
    );
  });

  test('stressBatchFigures gives the median of the batch percentiles', () {
    // 3 batches of 1000 us each from 0 to 3000; the frames have the build
    // durations 1, 2, 3 and 4 ms in batch 0, 5 and 6 ms in batch 1, and 7 ms
    // in batch 2. The raster duration is twice the build duration.
    StressFrame frame(int vsync, int buildMs) =>
        (vsync: vsync, build: buildMs * 1000, raster: buildMs * 2000);
    final frames = [
      frame(-10, 100),
      frame(0, 1),
      frame(100, 2),
      frame(200, 3),
      frame(900, 4),
      frame(1000, 5),
      frame(1999, 6),
      frame(2500, 7),
      frame(3001, 100),
    ];
    final figures = stressBatchFigures(
      frames,
      start: 0,
      end: 3000,
      batches: 3,
    )!;
    expect(figures.batches, 3);
    expect(figures.frames, 7);
    // p50: 2, 5 and 7 ms; the median is 5 ms. p90: 4, 6 and 7 ms; 6 ms.
    expect(figures.buildP50Ms, 5);
    expect(figures.buildP90Ms, 6);
    expect(figures.rasterP50Ms, 10);
    expect(figures.rasterP90Ms, 12);
    // A batch with no frame does not count.
    final sparse = stressBatchFigures(
      [frame(0, 1), frame(2900, 3)],
      start: 0,
      end: 3000,
      batches: 3,
    )!;
    expect((sparse.batches, sparse.frames, sparse.buildP50Ms), (2, 2, 1));
    expect(
      stressBatchFigures(frames, start: 4000, end: 5000, batches: 3),
      isNull,
    );
  });

  testWidgets('main_stress keeps a late publish out of the next scenario', (
    tester,
  ) async {
    // The frame after the timer of scenario 1 runs the old StressDemo once
    // more. When its window closes in that frame, it publishes the figures
    // of scenario 1. Scenario 2 runs fewer than 30 frames and has no window
    // of its own, so its line must give 0 frames per second.
    final lines = await _stressLines(() async {
      await tester.pumpWidget(
        const StressProfileApp(
          mode: StressMode.primitives,
          scenarios: [(300, 0), (600, 0)],
        ),
      );
      await _frames(tester, 50);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 700)),
      );
      await tester.pump(const Duration(seconds: stressSeconds));
      await _frames(tester, 10);
      await tester.pump(const Duration(seconds: stressSeconds));
    });
    expect(lines, hasLength(2));
    expect(lines[0]['n'], 300);
    expect(lines[1]['n'], 600);
    expect(lines[1]['fps'], '0.00');
    await tester.pumpWidget(const SizedBox());
  });

  test('the defines TYPE, SHARING and SHOWLINE (Chart.js ADR 0031, section '
      '5.6)', () {
    const chart = StressMode.chart;
    // Without TYPE: SHARING=0 gives scatter, SHARING=1 or no SHARING line.
    expect(parseStressType('', '', chart), StressChartType.line);
    expect(parseStressType('', '1', chart), StressChartType.line);
    expect(parseStressType('', '0', chart), StressChartType.scatter);
    for (final type in StressChartType.values) {
      expect(parseStressType(type.name, '', chart), type);
    }
    // With both: SHARING=1 needs line, SHARING=0 needs scatter.
    expect(parseStressType('line', '1', chart), StressChartType.line);
    expect(parseStressType('scatter', '0', chart), StressChartType.scatter);
    expect(() => parseStressType('line', '0', chart), throwsArgumentError);
    expect(() => parseStressType('scatter', '1', chart), throwsArgumentError);
    expect(() => parseStressType('bar', '1', chart), throwsArgumentError);
    expect(() => parseStressType('', '2', chart), throwsArgumentError);
    // An unknown name, and TYPE in another mode.
    expect(() => parseStressType('area', '', chart), throwsArgumentError);
    expect(
      () => parseStressType('bar', '', StressMode.axes),
      throwsArgumentError,
    );
    expect(parseStressType('', '1', StressMode.axes), StressChartType.line);

    expect(parseStressShowLine('0', StressChartType.bar, chart), isFalse);
    expect(parseStressShowLine('1', StressChartType.line, chart), isTrue);
    expect(parseStressShowLine('1', StressChartType.scatter, chart), isTrue);
    expect(
      () => parseStressShowLine('1', StressChartType.radar, chart),
      throwsArgumentError,
    );
    expect(
      () => parseStressShowLine('1', StressChartType.line, StressMode.axes),
      throwsArgumentError,
    );
    expect(
      () => parseStressShowLine('2', StressChartType.line, chart),
      throwsArgumentError,
    );
  });

  test('stressDefaultScenarios of the mode chart: the counts of the type', () {
    expect(
      stressDefaultScenarios(StressMode.chart, StressChartType.line),
      [(1000, 0), (5000, 0), (20000, 0)],
    );
    expect(
      stressDefaultScenarios(StressMode.chart, StressChartType.radar),
      [(100, 0), (1000, 0), (5000, 0)],
    );
    expect(stressDefaultScenarios(StressMode.chart), [
      for (final n in stressType.counts) (n, 0),
    ]);
  });
}
