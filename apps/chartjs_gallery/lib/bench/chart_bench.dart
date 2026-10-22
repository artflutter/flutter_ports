// Original code, not ported from Chart.js: the frameless chart benchmark.

// The package exports nothing from lib/src yet; the public API comes in
// phase 9. The benchmark imports the ported files directly.
// ignore_for_file: implementation_imports

/// The cases and the timing loop of the frameless chart benchmark
/// (`lib/main_bench.dart`).
///
/// A case makes a real `Chart` on a `UiCanvasElement` that no chart host
/// shows. Thus `detectPlatform` gives the `BasicPlatform`, and no frame
/// drives the chart. The chart has `responsive: false`, `animation: false`,
/// `events: []` and `devicePixelRatio: 1`, and a bitmap of
/// [chartBenchWidth] x [chartBenchHeight] pixels. Each iteration calls the
/// chart directly and times three parts on the UI thread:
/// - update: `chart.update('none')` without its draw. Only the cases with
///   [ChartBenchCall.update] have it.
/// - draw: `chart.draw()`, also the draw inside `chart.update('none')`.
/// - end: the end of the recording. The context draws its picture into a
///   throwaway `ui.PictureRecorder`, as the paint of a chart host does, and
///   the recorder ends its picture and disposes of it. The end of the
///   recording also draws the pending circles of the circle batch.
///
/// A scene can also time parts of the update and the draw itself
/// ([ChartBenchScene.takeParts]). Each case times the element update, the
/// layout, the dataset update and the dataset draw with the hooks of an
/// inline plugin (`StressChartTiming`, Chart.js ADR 0031, section 6).
///
/// The timing loop follows `packages/flutter_chartjs_port/tool/bench/src/
/// harness.dart`: a warm-up, a calibration, and timed batches. A batch runs
/// a fixed count of iterations, about one batch time long. Its figure is
/// the mean of its iterations. Thus a batch includes its part of the
/// garbage collection. The figures of a case are the median, the 10th and
/// the 90th percentile (nearest rank) of its batches.
///
/// The benchmark does not measure the frame rate, the raster thread, the
/// vsync or the paint of a host. The frames do not give idle time, so the
/// garbage collection runs inside the loop.
library;

import 'dart:ui' as ui;

import 'package:chartjs_gallery/demo/gallery_components.dart';
import 'package:chartjs_gallery/demo/stress_axes.dart';
import 'package:chartjs_gallery/demo/stress_chart_config.dart';
import 'package:chartjs_gallery/demo/stress_timing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';

/// The width of the bitmap of the benchmark canvas, in device pixels.
const int chartBenchWidth = 800;

/// The height of the bitmap of the benchmark canvas, in device pixels.
const int chartBenchHeight = 480;

/// The time step of the moving points between two updates, in seconds:
/// one frame at 60 Hz.
const double chartBenchStep = 1 / 60;

/// The chart options that a benchmark chart adds to the options of its
/// case: no resize observer and a fixed device pixel ratio.
const AnyObject chartBenchOptions = {
  'responsive': false,
  'devicePixelRatio': 1.0,
};

/// The settings of a benchmark run. `lib/main_bench.dart` gives the defaults
/// of its defines: 15 batches of 200 ms after a warm-up of 1000 ms.
final class ChartBenchSettings {
  /// The settings of a run.
  const ChartBenchSettings({
    required this.batches,
    required this.batchMs,
    required this.warmupMs,
  });

  /// The timed batches of each case.
  final int batches;

  /// The target duration of one batch, in milliseconds.
  final int batchMs;

  /// The warm-up of each case, in milliseconds.
  final int warmupMs;
}

/// The call of each iteration of a case.
enum ChartBenchCall {
  /// `chart.draw()`. The data does not change.
  draw,

  /// A change of the data (not timed), then `chart.update('none')`.
  update,
}

/// The chart of a case for one point count.
final class ChartBenchScene {
  /// A chart with the config [config]. [change] changes the data before
  /// each update. [takeParts] gives the times of the parts. [describe]
  /// gives keys of the chart after the last batch.
  const ChartBenchScene({
    required this.config,
    this.change,
    this.takeParts,
    this.describe,
  });

  /// The config of `new Chart(canvas, config)`.
  final AnyObject config;

  /// Changes the data before each update, outside the timing. Dart `null`
  /// for no change.
  final VoidCallback? change;

  /// The ticks of a `Stopwatch` of each part of the update and the draw
  /// since the last call, by the name of the part. A call resets the parts.
  /// Each call gives the same names. Dart `null` for no parts.
  ///
  /// The loop calls it before and after each batch. The BENCH line gets the
  /// figures `<name>MedianMs`, `<name>P10Ms` and `<name>P90Ms` of each part,
  /// after the figures of the end of the recording.
  final Map<String, int> Function()? takeParts;

  /// The keys of the chart after the last batch, for example the tick count
  /// of a scale. The BENCH line gets them after the keys of the case. Dart
  /// `null` for no keys.
  final Map<String, Object?> Function(Chart chart)? describe;
}

/// The counts of a case without its own counts and without the define `N`.
const List<int> chartBenchDefaultCounts = [1000, 5000, 20000];

/// One case of the benchmark.
///
/// The BENCH line of a case has the keys `mode` and `case`, and the keys of
/// [keys]. A later phase adds its cases to [chartBenchCases].
final class ChartBenchCase {
  /// A case [name] of the mode [mode].
  const ChartBenchCase({
    required this.mode,
    required this.name,
    required this.call,
    required this.scene,
    this.keys = const {},
    this.counts,
  });

  /// The point counts of the case without the define `N`, or Dart `null`
  /// for [chartBenchDefaultCounts].
  final List<int>? counts;

  /// The mode, for example `chart`.
  final String mode;

  /// The name of the case in its mode, for example `b`. Two cases can have
  /// the same name and other [keys].
  final String name;

  /// The call of each iteration.
  final ChartBenchCall call;

  /// Makes the chart of the case for a point count. Runs outside the
  /// timing.
  final ChartBenchScene Function(int n) scene;

  /// The other keys of the BENCH line, for example `type` and `sharing`.
  final Map<String, Object?> keys;

  /// The mode and the name: `chart.b`.
  String get id => '$mode.$name';

  /// Whether the selector [selector] selects this case: the mode, the name,
  /// or the [id].
  bool selectedBy(String selector) =>
      selector == mode || selector == name || selector == id;
}

/// A case of the stress mode chart (Chart.js ADR 0021, section 8; Chart.js
/// ADR 0031, sections 3 and 7), with the config of `stressChartConfig`, the
/// items of a `StressChartScene` of [type] at the values of
/// `StressPointField`, and the parts of `StressChartTiming`.
ChartBenchCase _stressCase(
  String name,
  ChartBenchCall call, {
  required StressChartType type,
  bool scriptable = false,
  List<int>? counts,
}) => ChartBenchCase(
  mode: 'chart',
  name: name,
  call: call,
  keys: {'type': type.name, 'sharing': type.sharing, 'scriptable': scriptable},
  counts: counts,
  scene: (n) {
    registerGalleryComponents();
    final field = StressPointField(n);
    final scene = StressChartScene(type, n, field);
    final timing = StressChartTiming();
    return ChartBenchScene(
      config: stressChartConfig(
        scene: scene,
        scriptable: scriptable,
        options: chartBenchOptions,
        plugins: [timing.plugin],
      ),
      change: () => scene.write(field..step(n, chartBenchStep)),
      takeParts: timing.take,
    );
  },
);

/// A case `chart.<type>` of a type other than `line` and `scatter`
/// (Chart.js ADR 0031, section 7): the name is the type, without the
/// scriptable color, with the counts of the type.
ChartBenchCase _typeCase(StressChartType type, ChartBenchCall call) =>
    _stressCase(type.name, call, type: type, counts: type.counts);

/// A case of the stress mode axes: the config of `stressAxesConfig`, the
/// points of `StressPointField` and the parts of `StressChartTiming`. The y
/// axis is linear, and the x axis has `ticks.autoSkip`.
ChartBenchCase _axesCase(StressAxisType scale, ChartBenchCall call) =>
    ChartBenchCase(
      mode: 'axes',
      name: scale.name,
      call: call,
      keys: {
        'scale': scale.name,
        'yScale': StressAxisType.linear.name,
        'autoSkip': true,
      },
      scene: (n) {
        registerGalleryComponents();
        final field = StressPointField(n);
        final scene = StressAxesScene(
          n,
          x: scale,
          y: StressAxisType.linear,
          positions: field,
        );
        final timing = StressChartTiming();
        return ChartBenchScene(
          config: stressAxesConfig(
            scene: scene,
            autoSkip: true,
            options: chartBenchOptions,
            plugins: [timing.plugin],
          ),
          change: () {
            field.step(n, chartBenchStep);
            scene.write(field);
          },
          takeParts: timing.take,
          describe: (chart) {
            final ticks = stressAxesTicks(chart);
            return {
              'ticks': ticks?.ticks,
              'rotation': ticks?.rotation.toStringAsFixed(2),
            };
          },
        );
      },
    );

/// The cases of the benchmark, in the order of a run.
///
/// The mode `chart` has the cases of the stress mode chart. They have no
/// labels and no title: the stress mode draws them in a plugin of the
/// gallery, not in the chart path. The BENCH line of each has the keys
/// `type`, `sharing` (the `enableOptionSharing` of the controller) and
/// `scriptable`, and the parts `elements`, `layout`, `datasetsUpdate` and
/// `datasetsDraw`.
/// - `a`: `chart.draw()` of a `line` chart. The points do not move.
/// - `b`: new positions in the data objects, then `chart.update('none')`,
///   of a `line` chart (`enableOptionSharing` true) and of a `scatter`
///   chart (false).
/// - `c`: as `b` with `line`, and a scriptable `backgroundColor`.
///
/// The cases `a`, `b` and `c` keep the names and the keys of phase 5
/// (Chart.js ADR 0021, section 8): `line` and `scatter` draw the points of
/// phase 5 on two hidden unit scales (Chart.js ADR 0031, section 3).
///
/// The mode `axes` has the cases of the stress mode axes: the points of
/// case `b` on real scales of phase 6. The name of a case is the scale type
/// of its x axis: `linear`, `logarithmic`, `category` or `time`. Each name
/// has two cases: `chart.draw()` (the scales and the points draw), and new
/// values then `chart.update('none')` (the data limits, the ticks, the label
/// sizes, the fit and `getPixelForValue` for each point). The y values
/// move. The x values are fixed and sorted, as `parsing: false` needs
/// (`StressAxesScene`). The BENCH line has the four parts, and the keys
/// `ticks` (the tick count after the auto skip) and `rotation` (the
/// `labelRotation`) of the x axis after the last batch.
///
/// After the `axes` cases, the mode `chart` has the cases of the six other
/// types (Chart.js ADR 0031, sections 5 and 7): `chart.bar`, `chart.bubble`,
/// `chart.doughnut`, `chart.pie`, `chart.polarArea` and `chart.radar`, each
/// with `chart.draw()` and with new values then `chart.update('none')`.
/// Each runs the counts of its type without the define `N`. Thus a default
/// run times the cases of phase 5 and phase 6 first. The selector `chart`
/// selects 16 cases; `CASES=a,b,c` selects the cases of Chart.js ADR 0021,
/// section 8.
final List<ChartBenchCase> chartBenchCases = [
  _stressCase('a', ChartBenchCall.draw, type: StressChartType.line),
  _stressCase('b', ChartBenchCall.update, type: StressChartType.line),
  _stressCase('b', ChartBenchCall.update, type: StressChartType.scatter),
  _stressCase(
    'c',
    ChartBenchCall.update,
    type: StressChartType.line,
    scriptable: true,
  ),
  for (final scale in StressAxisType.values)
    for (final call in ChartBenchCall.values) _axesCase(scale, call),
  for (final type in StressChartType.values)
    if (!type.points)
      for (final call in ChartBenchCall.values) _typeCase(type, call),
];

/// The cases of [selection], a comma list of selectors (see
/// [ChartBenchCase.selectedBy]), in the order of [cases]. An empty
/// selection gives all [cases]. A selector that selects no case throws an
/// [ArgumentError].
List<ChartBenchCase> selectChartBenchCases(
  String selection, [
  List<ChartBenchCase>? cases,
]) {
  final all = cases ?? chartBenchCases;
  final selectors = [
    for (final part in selection.split(','))
      if (part.trim().isNotEmpty) part.trim(),
  ];
  if (selectors.isEmpty) return all;
  for (final selector in selectors) {
    if (!all.any((c) => c.selectedBy(selector))) {
      throw ArgumentError.value(selector, 'CASES', 'Selects no case');
    }
  }
  return [
    for (final c in all)
      if (selectors.any(c.selectedBy)) c,
  ];
}

/// The clock of the benchmark.
final Stopwatch _watch = Stopwatch()..start();

/// The `Chart` of a case: it adds the ticks of each `draw()` to
/// [drawTicks], also of the draw inside `update()`.
final class _BenchChart extends Chart {
  _BenchChart(super.item, [super.userConfig]);

  /// The ticks of the draws since the last reset.
  int drawTicks = 0;

  @override
  void draw() {
    final start = _watch.elapsedTicks;
    super.draw();
    drawTicks += _watch.elapsedTicks - start;
  }
}

/// The iterations of one case, with the sums of their times in ticks.
final class _Loop {
  _Loop(this.chart, this.context, this.call, this.change, this.takeParts);

  final _BenchChart chart;
  final UiCanvasContext context;
  final ChartBenchCall call;
  final VoidCallback? change;
  final Map<String, int> Function()? takeParts;

  int updateTicks = 0;
  int drawTicks = 0;
  int endTicks = 0;

  void reset() {
    updateTicks = 0;
    drawTicks = 0;
    endTicks = 0;
    takeParts?.call();
  }

  /// One iteration: the change of the data for an update, then the call
  /// and the end of the recording.
  void iterate() {
    if (call == ChartBenchCall.update) change?.call();
    chart.drawTicks = 0;
    final start = _watch.elapsedTicks;
    switch (call) {
      case ChartBenchCall.draw:
        chart.draw();
      case ChartBenchCall.update:
        chart.update('none');
    }
    final called = _watch.elapsedTicks;
    final recorder = ui.PictureRecorder();
    context.paint(ui.Canvas(recorder), ui.Offset.zero, 1, 1);
    recorder.endRecording().dispose();
    endTicks += _watch.elapsedTicks - called;
    drawTicks += chart.drawTicks;
    updateTicks += called - start - chart.drawTicks;
  }
}

/// The build mode of the program: `release`, `profile` or `debug`.
String get _buildMode => kReleaseMode
    ? 'release'
    : kProfileMode
    ? 'profile'
    : 'debug';

/// Runs [benchCase] with [n] points and gives the keys of its BENCH line.
///
/// The line has the keys `mode`, `case`, `n`, the keys of the case, the
/// keys of [ChartBenchScene.describe], `call` and `iterations` (the timed
/// iterations). For each part, it has the
/// median, the 10th and the 90th percentile of the batches in ms, as
/// strings with 3 decimals: `updateMedianMs`, `updateP10Ms`, `updateP90Ms`
/// (only for [ChartBenchCall.update]), `drawMedianMs`, … and `endP90Ms`,
/// then the figures of the parts of [ChartBenchScene.takeParts], for
/// example `layoutMedianMs`.
/// It also has the keys that a run script needs to check the run:
/// - `batches`, `batchIterations` (the iterations of one batch), `batchMs`,
///   `warmupMs` and `warmupIterations`;
/// - `width`, `height` and `dpr` of the bitmap;
/// - `build` (`profile`, `release` or `debug`) and `platform`;
/// - `startMs`, the clock of the device at the start of the case in ms
///   since the epoch, and `wallMs`, the time of the case from the start of
///   its chart to the end of the last batch. A run script can align its
///   samples of the core frequency with them.
///
/// [onChart] receives the chart after the last batch, before the case
/// destroys it. It lets a test examine the chart.
Map<String, Object?> runChartBenchCase(
  ChartBenchCase benchCase,
  int n,
  ChartBenchSettings settings, {
  ValueChanged<Chart>? onChart,
}) {
  final startMs = DateTime.now().millisecondsSinceEpoch;
  final wall = Stopwatch()..start();
  final scene = benchCase.scene(n);
  final canvas = UiCanvasElement(
    width: chartBenchWidth,
    height: chartBenchHeight,
  );
  final chart = _BenchChart(canvas, scene.config);
  final context = canvas.getContext2d();
  try {
    final loop = _Loop(
      chart,
      context,
      benchCase.call,
      scene.change,
      scene.takeParts,
    );
    final ticksPerMs = _watch.frequency / 1000;

    // The warm-up and the calibration: iterate until the warm-up time is
    // over. The mean time of the iterations after the first one gives the
    // iterations of a batch.
    final warmupStart = _watch.elapsedTicks;
    var warmupIterations = 0;
    var firstTicks = 0;
    int elapsed;
    do {
      loop.iterate();
      warmupIterations++;
      elapsed = _watch.elapsedTicks - warmupStart;
      if (warmupIterations == 1) firstTicks = elapsed;
    } while (elapsed < settings.warmupMs * ticksPerMs);
    final perIteration = warmupIterations == 1
        ? firstTicks
        : (elapsed - firstTicks) / (warmupIterations - 1);
    final batchIterations = perIteration <= 0
        ? 1
        : (settings.batchMs * ticksPerMs / perIteration).round().clamp(
            1,
            1 << 20,
          );

    final update = <double>[];
    final draw = <double>[];
    final end = <double>[];
    final parts = <String, List<double>>{};
    for (var b = 0; b < settings.batches; b++) {
      loop.reset();
      for (var i = 0; i < batchIterations; i++) {
        loop.iterate();
      }
      final perMs = batchIterations * ticksPerMs;
      update.add(loop.updateTicks / perMs);
      draw.add(loop.drawTicks / perMs);
      end.add(loop.endTicks / perMs);
      scene.takeParts?.call().forEach(
        (name, ticks) => (parts[name] ??= []).add(ticks / perMs),
      );
    }
    final wallMs = wall.elapsedMilliseconds;
    final described = scene.describe?.call(chart) ?? const {};
    onChart?.call(chart);

    Map<String, Object?> figures(String part, List<double> samples) {
      samples.sort();
      String at(double p) => _percentile(samples, p).toStringAsFixed(3);
      return {
        '${part}MedianMs': at(0.5),
        '${part}P10Ms': at(0.1),
        '${part}P90Ms': at(0.9),
      };
    }

    return {
      'mode': benchCase.mode,
      'case': benchCase.name,
      'n': n,
      ...benchCase.keys,
      ...described,
      'call': benchCase.call.name,
      'iterations': settings.batches * batchIterations,
      if (benchCase.call == ChartBenchCall.update) ...figures('update', update),
      ...figures('draw', draw),
      ...figures('end', end),
      for (final MapEntry(key: name, value: samples) in parts.entries)
        ...figures(name, samples),
      'batches': settings.batches,
      'batchIterations': batchIterations,
      'batchMs': settings.batchMs,
      'warmupMs': settings.warmupMs,
      'warmupIterations': warmupIterations,
      'width': chartBenchWidth,
      'height': chartBenchHeight,
      'dpr': 1,
      'build': _buildMode,
      'platform': defaultTargetPlatform.name,
      'startMs': startMs,
      'wallMs': wallMs,
    };
  } finally {
    chart.destroy();
    context.dispose();
  }
}

/// The nearest-rank percentile [p] of the sorted [samples], as in
/// `tool/bench/src/harness.dart`.
double _percentile(List<double> samples, double p) {
  final rank = (p * samples.length).ceil() - 1;
  return samples[rank.clamp(0, samples.length - 1)];
}
