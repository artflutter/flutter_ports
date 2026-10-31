// Original code, not ported from Chart.js: the frameless chart benchmark.

// The reason of each import of lib/src is the comment above it.
// ignore_for_file: implementation_imports

/// The cases and the timing loop of the frameless chart benchmark
/// (`lib/main_bench.dart`).
///
/// A case makes a real `Chart` on a `UiCanvasElement` that no chart host
/// shows. Thus `detectPlatform` gives the `BasicPlatform`, and no frame
/// drives the chart. The chart has `responsive: false`,
/// `devicePixelRatio: 1` and a bitmap of [chartBenchWidth] x
/// [chartBenchHeight] pixels. The cases of the modes `chart` and `axes`
/// (phases 5 to 7) also have `animation: false`, `events: []` and no legend
/// (`plugins.legend: false` of `stressPluginOptions`, Chart.js ADR 0031,
/// Open). The other plugins of `registerables` run: the filler fills the
/// radar of `chart.radar`. The cases of the plugins (phase 8, the modes
/// `plugins`, `tooltip`, `fill`, `legend` and `title`) give their own
/// options. The cases of the modes `motion` and `theme` (phase 9) have the
/// default animations on a `BasicPlatform` that keeps them. The cases of
/// the mode `theme` switch the theme with the internal theme switch of
/// `ChartView` (Chart.js ADR 0050). Each iteration calls the chart directly
/// and times three parts on the UI thread:
/// - update: `chart.update('none')` without its draw. Only the cases with
///   [ChartBenchCall.update] have it. For [ChartBenchCall.frame], it is the
///   frame without its draws: the event, the theme switch and its update,
///   and the tick of the animator. For [ChartBenchCall.motion], it is
///   `chart.update()` and its render, which starts the animator and draws
///   nothing.
/// - draw: `chart.draw()`, also the draw inside `chart.update('none')`, in
///   an event or in a tick of the animator.
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
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
// Not public: UiCanvasElement, the canvas of a chart with no host.
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
// Not public: FilterCallback, the filter of the notifyPlugins override.
import 'package:flutter_chartjs_port/src/core/core.plugins.dart'
    show FilterCallback;
// Not public: jsDateNow, the Date.now() of the chart (a test clock sets it).
import 'package:flutter_chartjs_port/src/js/js_date.dart' show jsDateNow;
// Not public: jsGet, the reads of the scriptable delay of motion.line.delay.
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
// Not public: NativeEvent, the DOM event that the cases give the chart.
import 'package:flutter_chartjs_port/src/platform/native_event.dart';
// Not public: fromNativeEvent, the chart event of a NativeEvent.
import 'package:flutter_chartjs_port/src/platform/platform.flutter.dart'
    show fromNativeEvent;
// Not public: ChartThemeSwitch, the theme switch of ChartView (Chart.js ADR
// 0050), which the cases of the mode theme run without a widget.
import 'package:flutter_chartjs_port/src/widgets/chart_theme_switch.dart';

/// The width of the bitmap of the benchmark canvas, in device pixels.
const int chartBenchWidth = 800;

/// The height of the bitmap of the benchmark canvas, in device pixels.
const int chartBenchHeight = 480;

/// The time step of the moving points between two updates, in seconds:
/// one frame at 60 Hz.
const double chartBenchStep = 1 / 60;

/// The chart options that a benchmark chart adds to the options of its
/// case: no resize observer and a fixed device pixel ratio.
const Map<String, Object?> chartBenchOptions = {
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

  /// One frame of [ChartBenchScene.frame]: an event or a theme switch, a
  /// tick of the animator, or both, with the draws that they cause. The data
  /// does not change.
  frame,

  /// `chart.update()` in the default mode, with the default animations
  /// (the cases `motion.<type>` of the night series A-N3 of phase 9,
  /// Chart.js ADR 0049 section 7). The update makes the animations of each
  /// element and starts the animator, which no frame ticks. The data does
  /// not change. Before each iteration, `chart.stop()` ends the animations
  /// of the last one, outside the timing.
  motion;

  /// The primary metric of a case with this call: the cost of one whole
  /// frame, the sum of the medians of these figures (performance.md
  /// section 6). `draw+end` for [draw], `update` for [motion] (the update
  /// and its render), else `update+draw+end`.
  String get frameMetric => switch (this) {
    draw => 'draw+end',
    motion => 'update',
    update || frame => 'update+draw+end',
  };
}

/// The calls of a case that times a draw and an update.
const List<ChartBenchCall> chartBenchDrawAndUpdate = [
  ChartBenchCall.draw,
  ChartBenchCall.update,
];

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
    this.prepare,
    this.frame,
  });

  /// The config of `new Chart(canvas, config)`.
  final Map<String, Object?> config;

  /// Brings the new chart into the state of the case, outside the timing,
  /// before the warm-up: for example a hover and the end of the
  /// animations. Dart `null` for no preparation.
  final void Function(Chart chart)? prepare;

  /// The frame of [ChartBenchCall.frame], timed. Dart `null` for the other
  /// calls.
  final void Function(Chart chart)? frame;

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
/// [keys]. A later phase adds its cases to [chartBenchCases], or to
/// [chartBenchExplicitCases] for a case with [explicit].
final class ChartBenchCase {
  /// A case [name] of the mode [mode].
  const ChartBenchCase({
    required this.mode,
    required this.name,
    required this.call,
    required this.scene,
    this.keys = const {},
    this.counts,
    this.primary,
    this.explicit = false,
  });

  /// Whether only the full [id] selects the case ([selectedBy]). A mode, a
  /// name and the empty selection never select it. Thus an explicit case
  /// does not change the cases of an older selector. The cases of the
  /// resolver series of phase 10 (Chart.js ADR 0053,
  /// [chartBenchExplicitCases]) are explicit.
  final bool explicit;

  /// The primary metric of the case, for example `update+draw+end`
  /// ([ChartBenchCall.frameMetric]): the BENCH line gets it as the key
  /// `primary`. The cases of phase 8 name it. Dart `null` for the cases of
  /// phases 5 to 7, whose lines keep their keys.
  final String? primary;

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
  /// or the [id]. Only the [id] selects an [explicit] case.
  bool selectedBy(String selector) => explicit
      ? selector == id
      : selector == mode || selector == name || selector == id;
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

/// The border colors of the datasets of the plugin cases, in turn.
const List<String> _benchBorders = [
  'rgb(54, 162, 235)',
  'rgb(255, 99, 132)',
  'rgb(255, 159, 64)',
  'rgb(255, 205, 86)',
  'rgb(75, 192, 192)',
  'rgb(153, 102, 255)',
  'rgb(201, 203, 207)',
];

/// The fill colors of the datasets of the plugin cases: the border colors
/// with alpha 0.5.
const List<String> _benchFills = [
  'rgba(54, 162, 235, 0.5)',
  'rgba(255, 99, 132, 0.5)',
  'rgba(255, 159, 64, 0.5)',
  'rgba(255, 205, 86, 0.5)',
  'rgba(75, 192, 192, 0.5)',
  'rgba(153, 102, 255, 0.5)',
  'rgba(201, 203, 207, 0.5)',
];

/// The time of one frame at 60 Hz, in ms: the step of the dates of the
/// animator ticks of the case `tooltip.fade`.
const double chartBenchFrameMs = chartBenchStep * 1000;

/// The frames of one fade of the tooltip in the case `tooltip.fade`: the
/// 200 ms of the opacity animation of the tooltip
/// (plugin.tooltip.js:1319-1322) at 60 Hz. The frame 12 ticks at 200 ms,
/// the end of the fade.
const int chartBenchFadeFrames = 12;

/// The phase step of the tick dates of the case `tooltip.fade`, in frames:
/// the fractional part of the golden ratio. The fade `c` (from 0) ticks at
/// the dates `start + (frame + phase) * chartBenchFrameMs`, with `phase` the
/// fractional part of `c * chartBenchFadePhase`. A real frame loop ticks at
/// the dates of the vsync, so the opacities of two fades are not the same.
/// With the same dates in each fade, the opacities repeat, and from the third
/// fade each line of the tooltip comes from the paragraph cache (Chart.js ADR
/// 0039, section 13, item 1).
const double chartBenchFadePhase = 0.6180339887498949;

/// The point counts of the cases of the tooltip, the fill, the legend and
/// the title: the points of each dataset.
const List<int> chartBenchPluginCounts = [100, 1000];

/// The values of [datasets] datasets of [n] points each, at the y values
/// of a `StressPointField` of `datasets * n` points: the point `i` of the
/// dataset `k` is the point `k * n + i` of the field.
final class _BenchSeries {
  _BenchSeries(
    this.datasets,
    this.n, {
    this.scale = 1,
    this.offset = 0,
    this.gapEvery = 0,
  }) : field = StressPointField(datasets * n) {
    for (var k = 0; k < datasets; k++) {
      data.add([for (var i = 0; i < n; i++) _value(k, i)]);
    }
  }

  final int datasets;
  final int n;

  /// The value of a field value `y` is `offset + scale * y`.
  final double scale;
  final double offset;

  /// A gap (`null`) at each point `i` with `i % gapEvery == gapEvery - 1`.
  /// 0 for no gap.
  final int gapEvery;

  final StressPointField field;

  /// The data of each dataset.
  final List<List<Object?>> data = [];

  /// `data.labels`: `Point <i>`.
  List<Object?> labels() => [for (var i = 0; i < n; i++) 'Point $i'];

  Object? _value(int k, int i) => gapEvery > 0 && i % gapEvery == gapEvery - 1
      ? null
      : offset + scale * field.y[k * n + i];

  /// Moves the points of the field by one frame and writes the new values
  /// into [data] in place. The gaps stay.
  void step() {
    field.step(datasets * n, chartBenchStep);
    for (var k = 0; k < datasets; k++) {
      final values = data[k];
      for (var i = 0; i < n; i++) {
        values[i] = _value(k, i);
      }
    }
  }
}

/// The dataset `k` with the [data], the label `Dataset <k + 1>`, a color
/// of [_benchBorders] and [_benchFills], `borderWidth` 1 and the options
/// [more].
Map<String, Object?> _benchDataset(
  int k,
  List<Object?> data, [
  Map<String, Object?>? more,
]) => <String, Object?>{
  'label': 'Dataset ${k + 1}',
  'data': data,
  'borderColor': _benchBorders[k % _benchBorders.length],
  'backgroundColor': _benchFills[k % _benchFills.length],
  'borderWidth': 1.0,
  ...?more,
};

/// The config of a chart of [type] with the labels of [series], the
/// [datasets], [chartBenchOptions] and the chart options [options].
Map<String, Object?> _benchConfig(
  String type,
  _BenchSeries series, {
  required List<Object?> datasets,
  required Map<String, Object?> options,
  List<Object?> plugins = const [],
}) => <String, Object?>{
  'type': type,
  'data': <String, Object?>{'labels': series.labels(), 'datasets': datasets},
  'options': <String, Object?>{...chartBenchOptions, ...options},
  'plugins': <Object?>[...plugins],
};

/// The hidden category x axis and linear y axis of the plugin and fill
/// cases, with the user bounds [min] and [max] of y (Chart.js ADR 0031,
/// section 5). [stacked] stacks the y values.
Map<String, Object?> _benchHiddenScales({
  required double min,
  required double max,
  bool stacked = false,
}) => <String, Object?>{
  'x': stressHiddenScale('category'),
  'y': <String, Object?>{
    ...stressHiddenScale('linear', min: min, max: max),
    if (stacked) 'stacked': true,
  },
};

/// The timing parts of a plugin case: the four parts of
/// `StressChartTiming`, and with [tooltip] the part `tooltipDraw`, the
/// draw of the tooltip from `beforeTooltipDraw` to `afterTooltipDraw`
/// (plugin.tooltip.js:1246-1262).
final class _PluginTiming {
  _PluginTiming({this.tooltip = false});

  final bool tooltip;
  final StressChartTiming _parts = StressChartTiming();
  int _tooltipStart = 0;
  int _tooltipTicks = 0;

  /// The inline plugins of the chart.
  List<Object?> get plugins => [
    _parts.plugin,
    if (tooltip)
      <String, Object?>{
        'id': 'benchTooltipTiming',
        'beforeTooltipDraw': (Object? chart, Object? args, Object? options) {
          _tooltipStart = _watch.elapsedTicks;
        },
        'afterTooltipDraw': (Object? chart, Object? args, Object? options) {
          _tooltipTicks += _watch.elapsedTicks - _tooltipStart;
        },
      },
  ];

  /// The ticks of each part since the last call. It resets the parts.
  Map<String, int> take() {
    final parts = {
      ..._parts.take(),
      if (tooltip) 'tooltipDraw': _tooltipTicks,
    };
    _tooltipTicks = 0;
    return parts;
  }
}

/// A case of phase 8: it names its primary metric
/// ([ChartBenchCall.frameMetric]).
ChartBenchCase _pluginCase(
  String mode,
  String name,
  ChartBenchCall call, {
  required List<int> counts,
  required Map<String, Object?> keys,
  required ChartBenchScene Function(int n) scene,
}) => ChartBenchCase(
  mode: mode,
  name: name,
  call: call,
  keys: keys,
  counts: counts,
  primary: call.frameMetric,
  scene: (n) {
    registerGalleryComponents();
    return scene(n);
  },
);

/// The plugin options of config A of Chart.js ADR 0038, section 10, item
/// 1: each plugin of `registerables` with its least work. The tooltip has
/// no option: the chart listens to no event.
Map<String, Object?> _leastWorkPlugins() => <String, Object?>{
  'legend': <String, Object?>{'display': false},
  'title': <String, Object?>{'display': false},
  'subtitle': <String, Object?>{'display': false},
  'colors': <String, Object?>{'enabled': false},
  'decimation': <String, Object?>{'enabled': false},
};

/// A case `plugins.line` of the CT stage 1 (Chart.js ADR 0038, section 10,
/// items 1 and 2): a line chart of [datasets] datasets in the config
/// [config].
/// - `A`: the seven plugins of `registerables`, each with its least work
///   ([_leastWorkPlugins]), no `fill` (the default `fill: false` of the
///   line) and no event (`events: []`).
/// - `B`: the same chart with `options.plugins: false`. Then
///   `_createDescriptors` gives no descriptor (core.plugins.js:101-107), and
///   each notify visits no plugin.
///
/// A minus B is an upper bound of the gain of the typed hook slots (CT):
/// the dispatch, the hook bodies and the three empty boxes. The chart has
/// no timing plugin, because B would turn it off: the BENCH line has no
/// parts. The key `notifies` gives the notifies of one iteration. The
/// scales are hidden (Chart.js ADR 0031, section 5).
ChartBenchCase _dispatchCase(
  String config,
  int datasets,
  ChartBenchCall call,
) => _pluginCase(
  'plugins',
  'line',
  call,
  counts: [if (datasets == 3) 1000 else 100],
  keys: {'config': config, 'datasets': datasets},
  scene: (n) {
    final series = _BenchSeries(datasets, n);
    return ChartBenchScene(
      config: _benchConfig(
        'line',
        series,
        datasets: [
          for (var k = 0; k < datasets; k++) _benchDataset(k, series.data[k]),
        ],
        options: <String, Object?>{
          'animation': false,
          'events': <String>[],
          'scales': _benchHiddenScales(min: 0, max: 1),
          'plugins': config == 'A' ? _leastWorkPlugins() : false,
        },
      ),
      change: series.step,
    );
  },
);

/// Sends a native event of [type] at ([x], [y]) to the event handler of
/// [chart] at once (core.controller.js:1163). The benchmark chart has no
/// host, so no platform listener exists: the event skips the throttled
/// proxy of the platform (platform.dom.js:240-254).
void _benchEvent(Chart chart, String type, double x, double y) {
  final event = NativeEvent(
    type: type,
    offsetX: x,
    offsetY: y,
    target: chart.canvas,
  );
  // The benchmark calls the event handler of the chart at once. It skips the
  // host input path of Chart.js ADR 0037: the pointer conversion of the
  // chart host and the throttled proxy of the platform listener.
  // ignore: invalid_use_of_internal_member
  chart.eventHandler(fromNativeEvent(event, chart));
}

/// Ticks the animator at [date], as a frame callback of the animator does
/// (core.animator.js:57-110). The frameless benchmark has no frame.
void _benchTick(double date) {
  // The benchmark ticks the animator as its frame callback does.
  // ignore: invalid_use_of_internal_member
  animator.update(date);
}

/// Ends each animation of the animator: two ticks one hour after now. The
/// first tick gives each animation its end value, and the second tick
/// removes the animations (core.animator.js:57-110).
void _benchFinishAnimations() {
  final date = jsDateNow() + Duration.millisecondsPerHour;
  _benchTick(date);
  _benchTick(date);
}

/// The pointer of the tooltip cases: the x of each point of dataset 0 and
/// the y of the middle of the chart area.
final class _BenchPointer {
  Float64List _xs = Float64List(0);
  double _y = 0;

  /// Reads the positions of the points of [chart]. Call it after the end
  /// of the animations.
  void measure(Chart chart) {
    _xs = Float64List.fromList([
      for (final element in chart.getDatasetMeta(0).data) element.x,
    ]);
    final area = chart.chartArea!;
    _y = (area.top + area.bottom) / 2;
  }

  /// A `mousemove` over the point [index] of dataset 0.
  void move(Chart chart, int index) =>
      _benchEvent(chart, 'mousemove', _xs[index], _y);

  /// A `mouseout`: the pointer leaves the canvas at its left edge.
  void out(Chart chart) => _benchEvent(chart, 'mouseout', -1, _y);
}

/// A `BasicPlatform` with the no-op `updateConfig` of `BasePlatform`
/// (platform.base.js:80-82): the chart keeps its option `animation`.
/// `BasicPlatform` writes `animation: false` (platform.basic.js:20-22). The
/// cases `tooltip.still` and `tooltip.fade` need the animations. The
/// reference generators of the controllers do the same in Node.js.
final class _AnimatedPlatform extends BasicPlatform {
  /// The class value of `config.platform` (core.controller.js:136).
  static final JsClass jsClass = JsClass(
    'AnimatedBasicPlatform',
    superclass: BasicPlatform.jsClass,
    construct: (newTarget, args) => _AnimatedPlatform(),
  );

  @override
  void updateConfig(ChartConfiguration config) {
    // no-op
  }
}

/// The chart of the tooltip cases (Chart.js ADR 0039, Open 1): a line
/// chart of [datasets] datasets of [n] points on the default scales of
/// the docs blocks (a visible category x axis and a visible linear y axis),
/// with `interaction: {mode: 'index', intersect: false}` and no legend.
/// Without [tooltip], the chart has `plugins.tooltip: false`: the same
/// chart without the tooltip plugin. With [animate], the chart has the
/// default animations on the platform [_AnimatedPlatform], else
/// `animation: false`. The chart listens to the default events.
ChartBenchScene _tooltipScene(
  int datasets,
  int n, {
  required bool tooltip,
  required bool animate,
  void Function(Chart chart)? prepare,
  void Function(Chart chart)? frame,
}) {
  final series = _BenchSeries(datasets, n);
  final timing = _PluginTiming(tooltip: true);
  final config = _benchConfig(
    'line',
    series,
    datasets: [
      for (var k = 0; k < datasets; k++) _benchDataset(k, series.data[k]),
    ],
    options: <String, Object?>{
      if (!animate) 'animation': false,
      'interaction': <String, Object?>{'mode': 'index', 'intersect': false},
      'plugins': <String, Object?>{
        'legend': false,
        if (!tooltip) 'tooltip': false,
      },
    },
    plugins: timing.plugins,
  );
  if (animate) config['platform'] = _AnimatedPlatform.jsClass;
  return ChartBenchScene(
    config: config,
    takeParts: timing.take,
    prepare: prepare,
    frame: frame,
  );
}

/// The keys of a tooltip case.
Map<String, Object?> _tooltipKeys(int datasets, {required bool tooltip}) => {
  'datasets': datasets,
  'tooltip': tooltip,
};

/// Case (a) of Chart.js ADR 0039, Open 1, `tooltip.hover`: a hover change
/// in each frame. Each frame sends a `mousemove` over the next point of
/// dataset 0, so the index of the tooltip changes in each frame. The chart
/// has `animation: false`: the event draws the chart at once
/// (core.controller.js:683-695, :1180-1182). The frameless benchmark cannot
/// tick the animations of the elements in frame time, because each
/// animation takes its start from the clock (core.animation.js:37, :58).
/// Without [tooltip], it is the guard cell of the same chart without the
/// tooltip plugin.
ChartBenchCase _hoverCase(int datasets, {required bool tooltip}) => _pluginCase(
  'tooltip',
  'hover',
  ChartBenchCall.frame,
  counts: chartBenchPluginCounts,
  keys: _tooltipKeys(datasets, tooltip: tooltip),
  scene: (n) {
    final pointer = _BenchPointer();
    var index = 0;
    return _tooltipScene(
      datasets,
      n,
      tooltip: tooltip,
      animate: false,
      prepare: pointer.measure,
      frame: (chart) {
        index = (index + 1) % n;
        pointer.move(chart, index);
      },
    );
  },
);

/// Case (b) of Chart.js ADR 0039, Open 1, `tooltip.still`: a still tooltip
/// after its animation. The preparation sends a `mousemove` over the
/// middle point of dataset 0 and ends the animations. Each iteration calls
/// `chart.draw()`. The `$animations` of the tooltip keep their entries
/// after the end, so each draw calls the positioner and measures the lines
/// again (plugin.tooltip.js:1006-1048, Chart.js ADR 0039, section 13).
/// Without [tooltip], it is the same chart without the tooltip plugin.
ChartBenchCase _stillCase(int datasets, {required bool tooltip}) => _pluginCase(
  'tooltip',
  'still',
  ChartBenchCall.draw,
  counts: chartBenchPluginCounts,
  keys: _tooltipKeys(datasets, tooltip: tooltip),
  scene: (n) {
    final pointer = _BenchPointer();
    return _tooltipScene(
      datasets,
      n,
      tooltip: tooltip,
      animate: true,
      prepare: (chart) {
        _benchFinishAnimations();
        pointer
          ..measure(chart)
          ..move(chart, n ~/ 2);
        _benchFinishAnimations();
      },
    );
  },
);

/// Case (c) of Chart.js ADR 0039, Open 1, `tooltip.fade`: the fade in and
/// out of the tooltip, with the default animations. Each iteration is one
/// frame of a fade: a tick of the animator at a date
/// [chartBenchFrameMs] later than the frame before, and the draw of that
/// tick. The first frame of each fade also sends the event: a `mousemove`
/// over the middle point of dataset 0 (fade in) or a `mouseout` (fade
/// out), in turn. A fade has [chartBenchFadeFrames] frames, so each frame
/// draws the tooltip with a new opacity (Chart.js ADR 0039, section 13 and
/// Open 2). The dates of the ticks start at the clock after the event, as
/// the animations of the event take their start from the clock
/// (core.animation.js:37, :58). Each fade moves the dates of its ticks by
/// its phase ([chartBenchFadePhase]), so the opacities of one fade do not
/// repeat in the next fades, as in a real frame loop.
ChartBenchCase _fadeCase(int datasets) => _pluginCase(
  'tooltip',
  'fade',
  ChartBenchCall.frame,
  counts: chartBenchPluginCounts,
  keys: _tooltipKeys(datasets, tooltip: true),
  scene: (n) {
    final pointer = _BenchPointer();
    var frame = 0;
    var fade = 0;
    var phase = 0.0;
    var shown = false;
    var start = 0.0;
    return _tooltipScene(
      datasets,
      n,
      tooltip: true,
      animate: true,
      prepare: (chart) {
        _benchFinishAnimations();
        pointer.measure(chart);
      },
      frame: (chart) {
        if (frame == 0) {
          shown = !shown;
          if (shown) {
            pointer.move(chart, n ~/ 2);
          } else {
            pointer.out(chart);
          }
          start = jsDateNow();
          phase = (fade * chartBenchFadePhase) % 1;
          fade++;
        }
        frame++;
        _benchTick(start + (frame + phase) * chartBenchFrameMs);
        if (frame == chartBenchFadeFrames) frame = 0;
      },
    );
  },
);

/// A fill case of Chart.js ADR 0040, Open 2: three datasets of N points on
/// hidden scales, with `pointRadius: 0`, `animation: false`, `events: []`
/// and no legend.
/// - `fill.gaps`: a line chart, the values from -1 to 1 with a gap every
///   12 points, and `fill: {target: 'origin', above, below}` on each
///   dataset. `above` and `below` make the path clips of the filler
///   (`filler.drawing.js`, `clipVertical` and `clipHorizontal`).
/// - `fill.stack`: a line chart with stacked y values and `fill: 'stack'`
///   on each dataset. The stack target is quadratic in N, as upstream.
/// - `fill.radar`: a radar chart on a hidden polygon grid with the fills
///   `origin`, `-1` and `-1`.
ChartBenchCase _fillCase(String name, ChartBenchCall call) => _pluginCase(
  'fill',
  name,
  call,
  counts: chartBenchPluginCounts,
  keys: {'datasets': 3},
  scene: (n) {
    final timing = _PluginTiming();
    final series = switch (name) {
      'gaps' => _BenchSeries(3, n, scale: 2, offset: -1, gapEvery: 12),
      _ => _BenchSeries(3, n),
    };
    final Map<String, Object?> scales;
    final List<Object?> fills;
    switch (name) {
      case 'gaps':
        scales = _benchHiddenScales(min: -1, max: 1);
        fills = [
          for (var k = 0; k < 3; k++)
            <String, Object?>{
              'target': 'origin',
              'above': _benchFills[1],
              'below': _benchFills[0],
            },
        ];
      case 'stack':
        scales = _benchHiddenScales(min: 0, max: 3, stacked: true);
        fills = ['stack', 'stack', 'stack'];
      default:
        scales = <String, Object?>{
          'r': stressHiddenScale('radialLinear', min: 0, max: 1),
        };
        fills = ['origin', '-1', '-1'];
    }
    return ChartBenchScene(
      config: _benchConfig(
        name == 'radar' ? 'radar' : 'line',
        series,
        datasets: [
          for (var k = 0; k < 3; k++)
            _benchDataset(k, series.data[k], <String, Object?>{
              'fill': fills[k],
              'pointRadius': 0.0,
            }),
        ],
        options: <String, Object?>{
          'animation': false,
          'events': <String>[],
          'scales': scales,
          'plugins': stressPluginOptions(),
        },
        plugins: timing.plugins,
      ),
      change: series.step,
      takeParts: timing.take,
    );
  },
);

/// The line chart of the legend and title cases: three datasets of N
/// points on the default scales of the docs blocks, `animation: false` and
/// `events: []`.
/// - `legend.line` with `legend: true`: the legend of the docs blocks,
///   the defaults (`display: true`, `position: 'top'`,
///   plugin.legend.js:637-638).
/// - `legend.line` with `legend: false`: the same chart with
///   `plugins.legend: false`, the base of the legend and the title.
/// - `title.line`: `plugins.legend: false` and the title
///   `{display: true, text: 'Chart.js Line Chart'}`.
ChartBenchCase _boxCase(
  String mode,
  ChartBenchCall call, {
  required bool legend,
  required bool title,
}) => _pluginCase(
  mode,
  'line',
  call,
  counts: chartBenchPluginCounts,
  keys: {'datasets': 3, 'legend': legend, 'title': title},
  scene: (n) {
    final timing = _PluginTiming();
    final series = _BenchSeries(3, n);
    return ChartBenchScene(
      config: _benchConfig(
        'line',
        series,
        datasets: [
          for (var k = 0; k < 3; k++) _benchDataset(k, series.data[k]),
        ],
        options: <String, Object?>{
          'animation': false,
          'events': <String>[],
          'plugins': <String, Object?>{
            if (!legend) 'legend': false,
            if (title)
              'title': <String, Object?>{
                'display': true,
                'text': 'Chart.js Line Chart',
              },
          },
        },
        plugins: timing.plugins,
      ),
      change: series.step,
      takeParts: timing.take,
    );
  },
);

/// The cases of the plugins of phase 8, in the order of a run, after the
/// cases of phases 5 to 7. Each names its primary metric (the key
/// `primary` of its BENCH line). N is the point count of each dataset.
/// - `plugins.line` (CT stage 1, Chart.js ADR 0038, section 10): the
///   configs `A` and `B` ([_dispatchCase]), with 3 datasets of 1000 points
///   and 100 datasets of 100 points, each with `draw` and `update`. The
///   100-dataset cells are primary.
/// - `tooltip.hover`, `tooltip.still` and `tooltip.fade`: the cases (a),
///   (b) and (c) of Chart.js ADR 0039, Open 1, with 3 and 10 datasets.
///   `hover` and `still` also run without the tooltip plugin (the key
///   `tooltip` false): the guard cells. The lines have the part
///   `tooltipDraw`.
/// - `fill.gaps`, `fill.stack` and `fill.radar`: the fills of Chart.js ADR
///   0040, Open 2 ([_fillCase]), each with `draw` and `update`.
/// - `legend.line` (the legend on and off) and `title.line`
///   ([_boxCase]), each with `draw` and `update`.
final List<ChartBenchCase> _pluginCases = [
  for (final datasets in const [3, 100])
    for (final call in chartBenchDrawAndUpdate)
      for (final config in const ['A', 'B'])
        _dispatchCase(config, datasets, call),
  for (final datasets in const [3, 10]) ...[
    for (final tooltip in const [true, false])
      _hoverCase(datasets, tooltip: tooltip),
    for (final tooltip in const [true, false])
      _stillCase(datasets, tooltip: tooltip),
    _fadeCase(datasets),
  ],
  for (final name in const ['gaps', 'stack', 'radar'])
    for (final call in chartBenchDrawAndUpdate) _fillCase(name, call),
  for (final call in chartBenchDrawAndUpdate) ...[
    _boxCase('legend', call, legend: true, title: false),
    _boxCase('legend', call, legend: false, title: false),
    _boxCase('title', call, legend: false, title: true),
  ],
];

/// The point counts of the cases `motion.<type>`.
const List<int> chartBenchMotionCounts = [1000, 20000];

/// A case `motion.<type>` of the night series A-N3 of phase 9 (spec-a
/// section 9.4): the chart of the stress mode chart of [type] (the config
/// of `stressChartConfig` with [chartBenchOptions]) with the default
/// animations on the platform [_AnimatedPlatform], and the call
/// [ChartBenchCall.motion]. The construction runs the entry animation,
/// which the preparation ends. The primary figure is `update`: the update
/// in the default mode and its render, the path of
/// `Animations._createAnimations` for each element. The case reads no
/// reduced-motion flag: the canvas of the benchmark has none.
ChartBenchCase _motionCase(StressChartType type) => ChartBenchCase(
  mode: 'motion',
  name: type.name,
  call: ChartBenchCall.motion,
  keys: {'type': type.name, 'sharing': type.sharing, 'scriptable': false},
  counts: chartBenchMotionCounts,
  primary: ChartBenchCall.motion.frameMetric,
  scene: (n) {
    registerGalleryComponents();
    final field = StressPointField(n);
    final scene = StressChartScene(type, n, field);
    final timing = StressChartTiming();
    final config = stressChartConfig(
      scene: scene,
      scriptable: false,
      options: chartBenchOptions,
      plugins: [timing.plugin],
    );
    // The default animations: no option `animation: false`.
    (config['options']! as Map<String, Object?>).remove('animation');
    config['platform'] = _AnimatedPlatform.jsClass;
    return ChartBenchScene(
      config: config,
      takeParts: timing.take,
      prepare: (chart) => _benchFinishAnimations(),
    );
  },
);

/// The cases of phase 9, after the cases of phase 8: `motion.line` and
/// `motion.bar` ([_motionCase]).
final List<ChartBenchCase> _motionCases = [
  _motionCase(StressChartType.line),
  _motionCase(StressChartType.bar),
];

/// The delay of the case `motion.line.delay`: `ctx.type === 'data' ?
/// ctx.dataIndex : 0`, a scriptable `animation.delay` (the form of the
/// progressive line of the docs, judge-r.md section 4.8). Each data element
/// gets its own delay, so the animation options of each element differ.
Object? stressDelayByIndex(Object? context) =>
    jsGet(context, 'type') == 'data' ? jsGet(context, 'dataIndex') : 0.0;

/// The case `motion.line.delay` of the resolver series of phase 10
/// (Chart.js ADR 0053): the case `motion.line` ([_motionCase]) with the
/// scriptable delay [stressDelayByIndex] in `options.animation`. The other
/// animation options keep their defaults. It is a guard cell of the series
/// C7: the memo of the animations stays off for a scriptable delay.
ChartBenchCase _motionDelayCase() => ChartBenchCase(
  mode: 'motion',
  name: 'line.delay',
  call: ChartBenchCall.motion,
  keys: {'type': 'line', 'sharing': true, 'scriptable': false, 'delay': true},
  counts: chartBenchMotionCounts,
  primary: ChartBenchCall.motion.frameMetric,
  explicit: true,
  scene: (n) {
    registerGalleryComponents();
    final field = StressPointField(n);
    final scene = StressChartScene(StressChartType.line, n, field);
    final timing = StressChartTiming();
    final config = stressChartConfig(
      scene: scene,
      scriptable: false,
      options: chartBenchOptions,
      plugins: [timing.plugin],
    );
    // The default animations with a scriptable delay.
    (config['options']! as Map<String, Object?>)['animation'] =
        <String, Object?>{'delay': stressDelayByIndex};
    config['platform'] = _AnimatedPlatform.jsClass;
    return ChartBenchScene(
      config: config,
      takeParts: timing.take,
      prepare: (chart) => _benchFinishAnimations(),
    );
  },
);

/// The case `chart.c.indexable` of the resolver series of phase 10
/// (Chart.js ADR 0053): the case `chart.c` with the indexable
/// `backgroundColor` `[stressChartBackground, stressChartBackgroundOdd]` in
/// place of the scriptable color. An indexable option needs the context of
/// each element (core.config.js:405-418), as a scriptable option does, but
/// it calls no user function.
ChartBenchCase _indexableCase() => ChartBenchCase(
  mode: 'chart',
  name: 'c.indexable',
  call: ChartBenchCall.update,
  keys: {
    'type': StressChartType.line.name,
    'sharing': StressChartType.line.sharing,
    'scriptable': false,
    'indexable': true,
  },
  primary: ChartBenchCall.update.frameMetric,
  explicit: true,
  scene: (n) {
    registerGalleryComponents();
    final field = StressPointField(n);
    final scene = StressChartScene(StressChartType.line, n, field);
    final timing = StressChartTiming();
    final config = stressChartConfig(
      scene: scene,
      scriptable: false,
      options: chartBenchOptions,
      plugins: [timing.plugin],
    );
    final datasets =
        (config['data']! as Map<String, Object?>)['datasets']! as List<Object?>;
    (datasets.single! as Map<String, Object?>)['backgroundColor'] = <Object?>[
      stressChartBackground,
      stressChartBackgroundOdd,
    ];
    return ChartBenchScene(
      config: config,
      change: () => scene.write(field..step(n, chartBenchStep)),
      takeParts: timing.take,
    );
  },
);

/// The case `chart.line.primitive` of the resolver series of phase 10
/// (Chart.js ADR 0053): a line chart of N numbers with the labels
/// `Point <i>`, on a hidden category x axis and a hidden linear y axis from
/// 0 to 1 (the scales of `chart.bar`). The data is parsed (no option
/// `parsing: false`): each update parses the numbers into new parsed items
/// (core.datasetController.js, `parsePrimitiveData`). The dataset has the
/// point options of `stressChartConfig`. Before each update, the points of
/// a `StressPointField` move by one frame, and their y values go into the
/// same data List. It is the cell of the trigger of the typed parsed
/// records (judge-r.md section 1.2, C8).
ChartBenchCase _primitiveCase() => ChartBenchCase(
  mode: 'chart',
  name: 'line.primitive',
  call: ChartBenchCall.update,
  keys: {
    'type': StressChartType.line.name,
    'sharing': StressChartType.line.sharing,
    'scriptable': false,
    'parsing': true,
  },
  primary: ChartBenchCall.update.frameMetric,
  explicit: true,
  scene: (n) {
    registerGalleryComponents();
    final field = StressPointField(n);
    final data = <Object?>[for (var i = 0; i < n; i++) field.y[i]];
    final timing = StressChartTiming();
    final config = <String, Object?>{
      'type': 'line',
      'data': <String, Object?>{
        'labels': <Object?>[for (var i = 0; i < n; i++) 'Point $i'],
        'datasets': <Object?>[
          <String, Object?>{
            'data': data,
            'backgroundColor': stressChartBackground,
            'borderColor': '#36A2EB',
            'borderWidth': 1.0,
            'pointStyle': 'circle',
            'radius': 3.0,
            'showLine': false,
            'clip': false,
          },
        ],
      },
      'options': <String, Object?>{
        'animation': false,
        'events': <String>[],
        'maintainAspectRatio': false,
        'plugins': stressPluginOptions(),
        'layout': <String, Object?>{'autoPadding': false},
        'scales': <String, Object?>{
          'x': stressHiddenScale('category'),
          'y': stressHiddenScale('linear', min: 0, max: 1),
        },
        ...chartBenchOptions,
      },
      'plugins': <Object?>[timing.plugin],
    };
    return ChartBenchScene(
      config: config,
      change: () {
        field.step(n, chartBenchStep);
        for (var i = 0; i < n; i++) {
          data[i] = field.y[i];
        }
      },
      takeParts: timing.take,
    );
  },
);

/// The explicit cases of the resolver series of phase 10 (Chart.js ADR
/// 0053, judge-r.md section 4.8): `motion.line.delay`, `chart.c.indexable`
/// and `chart.line.primitive`. Only the full id of a case selects it
/// ([ChartBenchCase.explicit]). Thus `CASES=chart` still selects the 16
/// cases of phases 5 to 7, `CASES=motion` the 2 cases of phase 9, and a run
/// without the define `CASES` the cases of [chartBenchCases].
final List<ChartBenchCase> chartBenchExplicitCases = [
  _motionDelayCase(),
  _indexableCase(),
  _primitiveCase(),
];

/// The chart types of the cases `theme.switch` and `theme.anim` (the night
/// record B-R1 of phase 9).
const List<String> chartBenchThemeTypes = [
  'line',
  'bar',
  'scatter',
  'radar',
  'doughnut',
];

/// The themes of the cases of the mode `theme`, in turn: the two presets of
/// Chart.js ADR 0050. A chart starts with the first one.
const List<ChartThemeData> chartBenchThemes = [
  ChartThemeData.light(),
  ChartThemeData.dark(),
];

/// The theme state of a chart of the mode `theme`: the `ChartThemeSwitch`
/// of `ChartView` (Chart.js ADR 0050, "Runtime switch") on the root config
/// of the case, as the widget has it on its root Map.
final class _BenchTheme {
  /// Records the user `scales` of [root] and writes the compiled [theme]
  /// under `$theme`, before `new Chart`, as the start of the widget does.
  _BenchTheme(this.root, ChartThemeData theme) {
    _switch
      ..recordUserScales(root['options'])
      ..start(root, theme);
  }

  /// The root config of the chart.
  final Map<String, Object?> root;

  // The bench runs the switch of the widget without a widget.
  // ignore: invalid_use_of_internal_member
  final ChartThemeSwitch _switch = ChartThemeSwitch();

  /// The inline plugin of the palette records: the hooks `beforeUpdate` and
  /// `beforeLayout` of the widget plugin `$chartView`
  /// (`chart_view_plugin.dart`), without its focus ring. It comes last in
  /// the plugins of the chart, as the widget plugin does.
  late final Map<String, Object?> plugin = <String, Object?>{
    'id': r'$chartView',
    'beforeUpdate': (Object? chart, Object? args, Object? options) {
      _switch.beforeUpdate(chart! as Chart);
    },
    'beforeLayout': (Object? chart, Object? args, Object? options) {
      _switch.afterColorize(chart! as Chart);
    },
  };

  /// The switch to [theme] in the update callback of the widget: steps 1 to
  /// 4 of the switch, then one `chart.update` with the mode of step 5
  /// (`'theme'` for a preset). An equal theme stops at the `==` of step 1:
  /// no update.
  void switchTo(Chart chart, ChartThemeData theme) {
    final mode = _switch.apply(chart, root, theme, reducedMotion: false);
    if (mode != null) chart.update(mode);
  }
}

/// A case of the mode `theme` (the night record B-R1 of phase 9, Chart.js
/// ADR 0050): a chart of [type] with 3 datasets (doughnut: 1) of N points
/// with no colors, the labels `Point <i>`, the default scales, the legend
/// and a title, the default animations on the platform [_AnimatedPlatform],
/// and the theme state [_BenchTheme] with the light preset. The colors
/// plugin gives the colors of the datasets from the palette of the theme.
/// No event reaches the chart. The preparation ends the entry animation.
/// [frame] makes the frame of the case from the chart and its theme state.
ChartBenchCase _themeCase(
  String name,
  String type, {
  required void Function(Chart chart, _BenchTheme theme) Function() frame,
  List<int> counts = chartBenchPluginCounts,
}) {
  final datasets = type == 'doughnut' ? 1 : 3;
  return _pluginCase(
    'theme',
    name,
    ChartBenchCall.frame,
    counts: counts,
    keys: {'type': type, 'datasets': datasets},
    scene: (n) {
      final timing = _PluginTiming();
      final series = _BenchSeries(datasets, n);
      final config = _benchConfig(
        type,
        series,
        datasets: [
          for (var k = 0; k < datasets; k++)
            <String, Object?>{
              'label': 'Dataset ${k + 1}',
              'data': type == 'scatter'
                  ? [
                      for (var i = 0; i < n; i++)
                        <String, Object?>{
                          'x': i.toDouble(),
                          'y': series.data[k][i],
                        },
                    ]
                  : series.data[k],
            },
        ],
        options: <String, Object?>{
          'plugins': <String, Object?>{
            'title': <String, Object?>{
              'display': true,
              'text': 'Chart.js Theme Chart',
            },
          },
        },
        plugins: timing.plugins,
      );
      config['platform'] = _AnimatedPlatform.jsClass;
      final theme = _BenchTheme(config, chartBenchThemes.first);
      (config['plugins']! as List<Object?>).add(theme.plugin);
      final step = frame();
      return ChartBenchScene(
        config: config,
        takeParts: timing.take,
        prepare: (chart) => _benchFinishAnimations(),
        frame: (chart) => step(chart, theme),
      );
    },
  );
}

/// The case `theme.switch` (TS): each frame is one switch, from the light
/// preset to the dark preset or back. The switch runs steps 1 to 4 with a
/// new theme (the compile memo, the `$theme` write, the user scales and the
/// palette records) and `chart.update('theme')`, which makes the
/// animations of the element colors. Then the frame ends them: a tick of
/// the animator one hour later gives each element its end value and draws
/// the chart, as the last frame of the transition does, and a second tick
/// removes the animations ([_benchFinishAnimations]). Thus `update` is the
/// switch, the update and the ticks, and `draw` is the draw of the new
/// theme.
ChartBenchCase _themeSwitchCase(String type) => _themeCase(
  'switch',
  type,
  frame: () {
    var index = 0;
    return (chart, theme) {
      index = 1 - index;
      theme.switchTo(chart, chartBenchThemes[index]);
      _benchFinishAnimations();
    };
  },
);

/// The case `theme.anim` (TA): the frames of the transition of 200 ms of
/// the update mode `'theme'` (`compile.dart`, theming.md §3.8), as the
/// case `tooltip.fade` gives the fade of 200 ms of the tooltip. Each
/// iteration is one frame: a tick of the animator at a date
/// [chartBenchFrameMs] later than the frame before, and the draw of that
/// tick. The first frame of each transition also switches the theme (light
/// to dark, or back) with `chart.update('theme')`. A transition has
/// [chartBenchFadeFrames] frames, and the last one ends it. Each
/// transition moves the dates of its ticks by its phase
/// ([chartBenchFadePhase]), as in a real frame loop.
///
/// Both presets have the palette of Chart.js, so the datasets keep their
/// colors. In the types `line`, `bar`, `scatter` and `radar`, the first
/// tick of a transition thus ends each animation (`from === to`,
/// core.animation.js), and the other frames tick no animation and draw
/// nothing. In the type `doughnut`, the arc border is the `surface` of the
/// theme (element.arc.ts:379): it animates in each frame of the transition.
ChartBenchCase _themeAnimCase(String type) => _themeCase(
  'anim',
  type,
  frame: () {
    var index = 0;
    var frame = 0;
    var transition = 0;
    var phase = 0.0;
    var start = 0.0;
    return (chart, theme) {
      if (frame == 0) {
        index = 1 - index;
        theme.switchTo(chart, chartBenchThemes[index]);
        start = jsDateNow();
        phase = (transition * chartBenchFadePhase) % 1;
        transition++;
      }
      frame++;
      _benchTick(start + (frame + phase) * chartBenchFrameMs);
      if (frame == chartBenchFadeFrames) frame = 0;
    };
  },
);

/// The case `theme.equal` (TE): each frame calls the switch with a new
/// instance that is `==` to the applied light preset, as a rebuild of an
/// app gives a new equal theme. Step 1 of the switch stops at the `==`:
/// the frame has no update and no draw (the key `notifies` is 0).
ChartBenchCase _themeEqualCase() => _themeCase(
  'equal',
  'line',
  counts: const [100],
  frame: () =>
      (chart, theme) =>
          theme.switchTo(chart, chartBenchThemes.first.copyWith()),
);

/// The cases of the night record B-R1 of phase 9 (Chart.js ADR 0050), after
/// the cases `motion.<type>`: `theme.switch` and `theme.anim` for each type
/// of [chartBenchThemeTypes], then `theme.equal` of a line chart.
final List<ChartBenchCase> _themeCases = [
  for (final type in chartBenchThemeTypes) _themeSwitchCase(type),
  for (final type in chartBenchThemeTypes) _themeAnimCase(type),
  _themeEqualCase(),
];

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
///
/// After them come the cases of the plugins of phase 8 ([_pluginCases]):
/// the modes `plugins`, `tooltip`, `fill`, `legend` and `title`. Their
/// BENCH lines have the key `primary`. Thus a default run times the cases
/// of phases 5 to 7 first, in the same order as before. The cases
/// `motion.line` and `motion.bar` of phase 9 come next ([_motionCases]),
/// and the cases of the mode `theme` of phase 9 come last ([_themeCases]):
/// `theme.switch`, `theme.anim` and `theme.equal`. The explicit cases of
/// phase 10 are not in this list: see [chartBenchExplicitCases].
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
    for (final call in chartBenchDrawAndUpdate) _axesCase(scale, call),
  for (final type in StressChartType.values)
    if (!type.points)
      for (final call in chartBenchDrawAndUpdate) _typeCase(type, call),
  ..._pluginCases,
  ..._motionCases,
  ..._themeCases,
];

/// The cases of [selection], a comma list of selectors (see
/// [ChartBenchCase.selectedBy]), in the order of [cases]. [cases] defaults
/// to [chartBenchCases], then [chartBenchExplicitCases]. An empty
/// selection gives the cases of [cases] that are not
/// [ChartBenchCase.explicit]. Only its full id selects an explicit case,
/// for example `CASES=chart,chart.c.indexable`. A selector that selects no
/// case throws an [ArgumentError].
List<ChartBenchCase> selectChartBenchCases(
  String selection, [
  List<ChartBenchCase>? cases,
]) {
  final all = cases ?? [...chartBenchCases, ...chartBenchExplicitCases];
  final selectors = [
    for (final part in selection.split(','))
      if (part.trim().isNotEmpty) part.trim(),
  ];
  if (selectors.isEmpty) {
    return [
      for (final c in all)
        if (!c.explicit) c,
    ];
  }
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

  /// The calls of `notifyPlugins` since the last reset: one for each
  /// notify of a hook, also when no plugin gets it (Chart.js ADR 0038,
  /// section 10, item 4).
  int notifies = 0;

  @override
  void draw() {
    final start = _watch.elapsedTicks;
    super.draw();
    drawTicks += _watch.elapsedTicks - start;
  }

  @override
  bool? notifyPlugins(
    String hook, [
    Object? args,
    FilterCallback? filter,
  ]) {
    notifies++;
    return super.notifyPlugins(hook, args, filter);
  }
}

/// The iterations of one case, with the sums of their times in ticks.
final class _Loop {
  _Loop(
    this.chart,
    this.context,
    this.call,
    this.change,
    this.takeParts,
    this.frame,
  );

  final _BenchChart chart;
  final UiCanvasContext context;
  final ChartBenchCall call;
  final VoidCallback? change;
  final Map<String, int> Function()? takeParts;
  final void Function(Chart chart)? frame;

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
  /// and the end of the recording. The notify count of the chart starts at
  /// 0: after the last iteration, it is the count of one iteration.
  void iterate() {
    if (call == ChartBenchCall.update) change?.call();
    // The animations of the last motion update end, outside the timing.
    if (call == ChartBenchCall.motion) chart.stop();
    chart
      ..drawTicks = 0
      ..notifies = 0;
    final start = _watch.elapsedTicks;
    switch (call) {
      case ChartBenchCall.draw:
        chart.draw();
      case ChartBenchCall.update:
        chart.update('none');
      case ChartBenchCall.frame:
        frame!(chart);
      case ChartBenchCall.motion:
        chart.update();
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
/// keys of [ChartBenchScene.describe], `call`, `primary` (only for a case
/// with [ChartBenchCase.primary]), `iterations` (the timed iterations) and
/// `notifies` (the calls of `notifyPlugins` in the last iteration). For
/// each part, it has the
/// median, the 10th and the 90th percentile of the batches in ms, as
/// strings with 3 decimals: `updateMedianMs`, `updateP10Ms`, `updateP90Ms`
/// (only for [ChartBenchCall.update], [ChartBenchCall.frame] and
/// [ChartBenchCall.motion]),
/// `drawMedianMs`, … and `endP90Ms`,
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
    scene.prepare?.call(chart);
    final loop = _Loop(
      chart,
      context,
      benchCase.call,
      scene.change,
      scene.takeParts,
      scene.frame,
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
      'primary': ?benchCase.primary,
      'iterations': settings.batches * batchIterations,
      'notifies': chart.notifies,
      if (benchCase.call != ChartBenchCall.draw) ...figures('update', update),
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
