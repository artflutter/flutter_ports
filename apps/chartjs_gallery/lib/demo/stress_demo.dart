// The reason of each import of lib/src is the comment above it.
// ignore_for_file: implementation_imports

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:chartjs_gallery/bench/chart_bench.dart'
    show
        ChartBenchCase,
        ChartBenchScene,
        chartBenchCases,
        chartBenchFadeFrames,
        chartBenchOptions,
        chartBenchPluginCounts;
import 'package:chartjs_gallery/demo/canvas_demo.dart' show labelColor;
import 'package:chartjs_gallery/demo/chart_canvas.dart';
import 'package:chartjs_gallery/demo/demo_chart.dart';
import 'package:chartjs_gallery/demo/demo_common.dart';
import 'package:chartjs_gallery/demo/demo_controls.dart';
import 'package:chartjs_gallery/demo/gallery_components.dart';
import 'package:chartjs_gallery/demo/stress_axes.dart';
import 'package:chartjs_gallery/demo/stress_chart_config.dart';
import 'package:chartjs_gallery/demo/stress_timing.dart';
import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_chartjs_port/helpers.dart'
    show ParsedFont, drawPoint, renderText, requestAnimFrame, toFont;
// Not public: the typed options of Chart.js ADR 0018. The prefix keeps them
// apart from the PointOptions of demo_chart.dart (the primitives mode).
import 'package:flutter_chartjs_port/src/elements/element_options.dart'
    as element_options;
// Not public: NativeEvent, the DOM event that the scenes give the chart.
import 'package:flutter_chartjs_port/src/platform/native_event.dart';
// Not public: fromNativeEvent, the chart event of a NativeEvent.
import 'package:flutter_chartjs_port/src/platform/platform.flutter.dart'
    show fromNativeEvent;

export 'package:chartjs_gallery/demo/stress_chart_config.dart'
    show StressChartType, stressAnimateMs, stressArcCounts, stressPointCounts;

/// The label counts of the stress tab.
const List<int> stressLabelCounts = [0, 50, 200];

/// The scenes of the stress tab.
///
/// Each mode draws N items and M labels in each frame. The chips
/// `stress.mode.<name>` select the mode.
enum StressMode {
  /// N points with `drawPoint` and a polyline through N points, with the
  /// canvas calls of `helpers.canvas`. This is the scene of
  /// `packages/flutter_chartjs_port/doc/performance.md`.
  primitives(stressPointCounts, 'points'),

  /// The scene of [primitives], drawn by the phase 4 elements: N
  /// `PointElement` objects and one `LineElement` through N point elements.
  elements(stressPointCounts, 'point elements'),

  /// N `BarElement` objects in a grid of bar columns.
  bars([1000, 5000, 20000], 'bars'),

  /// N `ArcElement` objects as the slices of doughnut rings.
  arcs([100, 1000, 5000], 'arcs'),

  /// N items of a real `Chart` with the ported controller of a
  /// [StressChartType] (Chart.js ADR 0031, sections 3 and 5): `line` and
  /// `scatter` draw the points of phase 5 (Chart.js ADR 0021, section 8) on
  /// two hidden unit scales. The N choices are the counts of the type.
  /// [StressChartCall] selects the call of each frame.
  chart(stressPointCounts, 'chart items'),

  /// The chart of [chart] on real scales of phase 6 (`lib/demo/
  /// stress_axes.dart`): an x axis of a [StressAxisType], a linear or
  /// logarithmic y axis, and the option `ticks.autoSkip` of the x axis.
  /// The calls are [StressChartCall.draw] and [StressChartCall.update].
  axes(stressPointCounts, 'chart points on scales'),

  /// The chart of a plugin case of the frameless benchmark
  /// (`lib/bench/chart_bench.dart`) in the real frame loop: the legend, the
  /// title, the tooltip or the filler ([StressPluginScene]). N is the point
  /// count of each dataset. The calls are the calls of the scene
  /// ([StressPluginScene.calls]).
  plugins(chartBenchPluginCounts, 'points per dataset');

  const StressMode(this.counts, this.items);

  /// The N choices of the mode, in ascending order.
  final List<int> counts;

  /// The name of the N items in the title of the chart.
  final String items;

  /// Whether the mode runs a real `Chart` on a chart host of its own:
  /// [chart], [axes] and [plugins].
  bool get runsChart => this == chart || this == axes || this == plugins;
}

/// The widget that hosts the chart of the modes [StressMode.chart],
/// [StressMode.axes] and [StressMode.plugins] (the night series A-N1 of
/// phase 9: the overhead of `ChartView`, Chart.js ADR 0049).
enum StressHost {
  /// The gallery host `ChartCanvas` (`lib/demo/chart_canvas.dart`): it
  /// makes the chart in a post-frame callback after its first frame. The
  /// chart is a `_StressChart`, which times its draws itself.
  canvas,

  /// The public widget `ChartView`: it starts the chart in the first layout
  /// of its host. The widget makes a plain `Chart` of the same config, so
  /// two more inline plugins time the draws (`_PluginMeter`): the first
  /// inline plugin marks the start in `beforeDraw`, the last one adds the
  /// time in `afterDraw`. Its `drawMs` thus has no `clear()` and no
  /// `beforeDraw` hook of a registered plugin. The stress loop does not
  /// follow the `TickerMode` of this host: the widget mutes its chart
  /// itself.
  view,
}

/// The call of each frame in the modes [StressMode.chart],
/// [StressMode.axes] and [StressMode.plugins] (Chart.js ADR 0021, section
/// 8). [draw] and [update] of the modes chart and axes run with
/// `animation: false`. The mode [StressMode.axes] has no [animate]. Only the
/// mode [StressMode.plugins] has [frame] ([stressCallsOf]).
enum StressChartCall {
  /// Case (a): `chart.draw()`. The points do not move.
  draw,

  /// Case (b): new positions in the data objects, then
  /// `chart.update('none')`. With a scriptable `backgroundColor`, this is
  /// case (c).
  update,

  /// The animation cost (step 8 of the phase 5 prompt): the chart has
  /// `animation: {duration: 1000, loop: true}`. Its first update starts an
  /// animation of `x` and `y` of each point, which loops without end. In
  /// each frame, the module-level animator of `core.animator` ticks the N
  /// animations (the property writes) and calls `chart.draw()`. `animatorMs`
  /// is the time of that tick without the draw.
  animate,

  /// The frame of a tooltip scene of the mode [StressMode.plugins] (the call
  /// `frame` of the benchmark): an event of the chart, and in the scene
  /// [StressPluginScene.fade] the tick of the animator in the real frames.
  /// The data does not change.
  frame,
}

/// The calls of the mode [mode]: the scene [scene] gives the calls of the
/// mode [StressMode.plugins]. The element modes have the calls of the mode
/// [StressMode.chart], which they do not use.
List<StressChartCall> stressCallsOf(
  StressMode mode,
  StressPluginScene scene,
) => switch (mode) {
  StressMode.axes => const [StressChartCall.draw, StressChartCall.update],
  StressMode.plugins => scene.calls,
  _ => const [
    StressChartCall.draw,
    StressChartCall.update,
    StressChartCall.animate,
  ],
};

/// The call [call] in the mode [mode] with the plugin scene [scene]: [call]
/// when the mode has it ([stressCallsOf]), else the first call of the mode.
/// Thus the mode axes takes [StressChartCall.draw] for
/// [StressChartCall.animate], and a tooltip scene takes
/// [StressChartCall.frame].
StressChartCall stressCallOf(
  StressMode mode,
  StressChartCall call,
  StressPluginScene scene,
) {
  final calls = stressCallsOf(mode, scene);
  return calls.contains(call) ? call : calls.first;
}

/// The calls of the cases with a draw and an update.
const List<StressChartCall> _drawAndUpdate = [
  StressChartCall.draw,
  StressChartCall.update,
];

/// The scenes of the mode [StressMode.plugins]: each is a plugin case of the
/// frameless benchmark (`chartBenchCases` of `lib/bench/chart_bench.dart`,
/// task P1 of step 8 of phase 8), with the config of that case.
///
/// The scenes of the legend, the title and the filler run with
/// `animation: false` and `events: []`. The tooltip scenes listen to the
/// default events: a pointer over the chart host also gives events.
enum StressPluginScene {
  /// `legend.line`: three datasets on the visible default scales, with the
  /// legend of the docs blocks, or without it (the base of the legend and
  /// the title; [StressPluginCase.legend]).
  legend('legend', 'line', _drawAndUpdate),

  /// `title.line`: the chart of [legend] without the legend, with the title
  /// 'Chart.js Line Chart'.
  title('title', 'line', _drawAndUpdate),

  /// `tooltip.hover` (Chart.js ADR 0039, Open 1, case (a)): each frame sends
  /// a `mousemove` over the next point of dataset 0 to the event handler of
  /// the chart, with `animation: false`. Thus the tooltip changes its index
  /// in each frame, and the event draws the chart.
  hover('tooltip', 'hover', [StressChartCall.frame]),

  /// `tooltip.still` (case (b)): the default animations. The preparation of
  /// the benchmark hovers the middle point and ends the animations. Each
  /// frame calls `chart.draw()`.
  still('tooltip', 'still', [StressChartCall.draw]),

  /// `tooltip.fade` (case (c)): the default animations. The first frame of
  /// each `chartBenchFadeFrames` (12) frames sends a `mousemove` over the
  /// middle point of dataset 0 or a `mouseout`, in turn. The animator of the
  /// chart ticks the fade in the real frames: no manual tick.
  fade('tooltip', 'fade', [StressChartCall.frame]),

  /// `fill.gaps` (Chart.js ADR 0040, Open 2): a gap every 12 points and the
  /// fill `{target: 'origin', above, below}` (the path clips).
  gaps('fill', 'gaps', _drawAndUpdate),

  /// `fill.stack`: stacked y values and `fill: 'stack'`.
  stack('fill', 'stack', _drawAndUpdate),

  /// `fill.radar`: a radar with the fills `origin`, `-1` and `-1`.
  radar('fill', 'radar', _drawAndUpdate);

  const StressPluginScene(this.benchMode, this.benchName, this.calls);

  /// The mode of the benchmark case, for example `tooltip`.
  final String benchMode;

  /// The name of the benchmark case in its mode, for example `hover`.
  final String benchName;

  /// The calls of the scene: the calls of its benchmark cases.
  final List<StressChartCall> calls;

  /// The id of the benchmark case: `tooltip.hover`.
  String get benchId => '$benchMode.$benchName';

  /// Whether the scene is a tooltip case, with the part `tooltipDraw` and
  /// the choice of 3 or 10 datasets.
  bool get tooltip => benchMode == 'tooltip';
}

/// The dataset counts of the tooltip scenes.
const List<int> stressPluginDatasets = [3, 10];

/// One case of the mode [StressMode.plugins]: a scene and its keys. The keys
/// select one case of the benchmark ([benchKeys]).
@immutable
final class StressPluginCase {
  /// The case of [scene]. [legend] applies to the scene
  /// [StressPluginScene.legend], [tooltip] to the scenes
  /// [StressPluginScene.hover] and [StressPluginScene.still], and
  /// [datasets] (3 or 10) to the three tooltip scenes.
  const StressPluginCase(
    this.scene, {
    this.legend = true,
    this.tooltip = true,
    this.datasets = 10,
  });

  /// The scene.
  final StressPluginScene scene;

  /// Whether the scene [StressPluginScene.legend] shows the legend.
  final bool legend;

  /// Whether the scenes [StressPluginScene.hover] and
  /// [StressPluginScene.still] have the tooltip plugin.
  final bool tooltip;

  /// The datasets of the tooltip scenes.
  final int datasets;

  /// The keys of the benchmark case, as its BENCH line gives them.
  Map<String, Object?> get benchKeys => switch (scene) {
    StressPluginScene.legend => {
      'datasets': 3,
      'legend': legend,
      'title': false,
    },
    StressPluginScene.title => {'datasets': 3, 'legend': false, 'title': true},
    StressPluginScene.hover || StressPluginScene.still => {
      'datasets': datasets,
      'tooltip': tooltip,
    },
    StressPluginScene.fade => {'datasets': datasets, 'tooltip': true},
    StressPluginScene.gaps ||
    StressPluginScene.stack ||
    StressPluginScene.radar => {'datasets': 3},
  };

  /// This case with the values that are given.
  StressPluginCase copyWith({
    StressPluginScene? scene,
    bool? legend,
    bool? tooltip,
    int? datasets,
  }) => StressPluginCase(
    scene ?? this.scene,
    legend: legend ?? this.legend,
    tooltip: tooltip ?? this.tooltip,
    datasets: datasets ?? this.datasets,
  );

  /// Two cases are equal when they select the same benchmark case.
  @override
  bool operator ==(Object other) =>
      other is StressPluginCase &&
      other.scene == scene &&
      mapEquals(other.benchKeys, benchKeys);

  @override
  int get hashCode => Object.hash(
    scene,
    Object.hashAllUnordered([
      for (final MapEntry(:key, :value) in benchKeys.entries)
        Object.hash(key, value),
    ]),
  );

  @override
  String toString() => '${scene.benchId} $benchKeys';
}

/// The benchmark case of [pluginCase] with the call [call]: the case of
/// `chartBenchCases` with the id of the scene, the call and the keys of
/// [pluginCase]. A call that the scene does not have throws an
/// [ArgumentError].
ChartBenchCase stressPluginBenchCase(
  StressPluginCase pluginCase,
  StressChartCall call,
) {
  if (!pluginCase.scene.calls.contains(call)) {
    throw ArgumentError.value(call, 'call', 'Not a call of $pluginCase');
  }
  final keys = pluginCase.benchKeys;
  return chartBenchCases.singleWhere(
    (c) =>
        c.id == pluginCase.scene.benchId &&
        c.call.name == call.name &&
        mapEquals(c.keys, keys),
  );
}

/// The config of a benchmark chart [config] for a chart host, in place:
/// without the keys of `chartBenchOptions` (`responsive: false` and the
/// fixed device pixel ratio), with `maintainAspectRatio: false`, and without
/// the platform of the benchmark (`config.platform`). Thus the chart fills
/// its host, and it gets the `FlutterPlatform`, which keeps the option
/// `animation`, as the DOM platform does. The other keys stay.
Map<String, Object?> stressHostConfig(Map<String, Object?> config) {
  final options = config['options']! as Map<String, Object?>;
  chartBenchOptions.keys.forEach(options.remove);
  options['maintainAspectRatio'] = false;
  config.remove('platform');
  return config;
}

/// The figures of the stress tab, published twice a second and when the
/// loop stops: the mode, the item count N (`points`), the label count M,
/// and the frame figures. `updateMs` is the time of `chart.update()` without
/// its draw, in the modes [StressMode.chart] and [StressMode.axes].
/// `animatorMs` is the time of the animator tick without its draw, for
/// [StressChartCall.animate]. Both are 0 in the other modes.
///
/// The modes [StressMode.chart] and [StressMode.axes] also give the parts
/// of `StressChartTiming` (`elementsMs`, `layoutMs`, `datasetsUpdateMs` and
/// `datasetsDrawMs`). The mode [StressMode.chart] gives `sharing`, the
/// `enableOptionSharing` of the controller of dataset 0 (the value of the
/// type before the first chart). The mode [StressMode.axes] gives the tick
/// count (`ticks`, after the auto skip) and the `labelRotation`
/// (`rotation`) of the x axis. They are 0 or false in the other modes.
///
/// The mode [StressMode.plugins] gives the four parts, `animatorMs` (the
/// tick of the animator before its draw, in the scene
/// [StressPluginScene.fade]) and `tooltipDrawMs`, the draw of the tooltip
/// from `beforeTooltipDraw` to `afterTooltipDraw` in the tooltip scenes.
///
/// A class with the field-wise `==` of a record: dart2wasm (Dart 3.11 to
/// 3.13.5) crashes on a record type with exactly 20 fields, because the
/// generated `hashCode` calls `Object.hash` with 21 arguments.
@immutable
final class StressStats {
  /// Creates the figures.
  const StressStats({
    required this.mode,
    required this.points,
    required this.labels,
    required this.frames,
    required this.fps,
    required this.drawMs,
    required this.updateMs,
    required this.animatorMs,
    required this.elementsMs,
    required this.layoutMs,
    required this.datasetsUpdateMs,
    required this.datasetsDrawMs,
    required this.ticks,
    required this.rotation,
    required this.sharing,
    required this.buildMs,
    required this.buildMaxMs,
    required this.rasterMs,
    required this.rasterMaxMs,
    required this.timings,
    this.tooltipDrawMs = 0,
  });

  /// The mode.
  final StressMode mode;

  /// The item count N.
  final int points;

  /// The label count M.
  final int labels;

  /// The frames since the loop started.
  final int frames;

  /// The frames per second.
  final double fps;

  /// The mean time of the draw calls of a frame.
  final double drawMs;

  /// The time of `chart.update()` without its draw.
  final double updateMs;

  /// The time of the animator tick without its draw.
  final double animatorMs;

  /// The part `elements` of `StressChartTiming`.
  final double elementsMs;

  /// The part `layout` of `StressChartTiming`.
  final double layoutMs;

  /// The part `datasetsUpdate` of `StressChartTiming`.
  final double datasetsUpdateMs;

  /// The part `datasetsDraw` of `StressChartTiming`.
  final double datasetsDrawMs;

  /// The tick count of the x axis after the auto skip.
  final int ticks;

  /// The `labelRotation` of the x axis.
  final double rotation;

  /// The `enableOptionSharing` of the controller of dataset 0.
  final bool sharing;

  /// The mean build time of the frame timings.
  final double buildMs;

  /// The longest build time of the frame timings.
  final double buildMaxMs;

  /// The mean raster time of the frame timings.
  final double rasterMs;

  /// The longest raster time of the frame timings.
  final double rasterMaxMs;

  /// The count of frame timings.
  final int timings;

  /// The part `tooltipDraw` of the tooltip scenes of the mode
  /// [StressMode.plugins].
  final double tooltipDrawMs;

  @override
  bool operator ==(Object other) =>
      other is StressStats &&
      mode == other.mode &&
      points == other.points &&
      labels == other.labels &&
      frames == other.frames &&
      fps == other.fps &&
      drawMs == other.drawMs &&
      updateMs == other.updateMs &&
      animatorMs == other.animatorMs &&
      elementsMs == other.elementsMs &&
      layoutMs == other.layoutMs &&
      datasetsUpdateMs == other.datasetsUpdateMs &&
      datasetsDrawMs == other.datasetsDrawMs &&
      ticks == other.ticks &&
      rotation == other.rotation &&
      sharing == other.sharing &&
      buildMs == other.buildMs &&
      buildMaxMs == other.buildMaxMs &&
      rasterMs == other.rasterMs &&
      rasterMaxMs == other.rasterMaxMs &&
      timings == other.timings &&
      tooltipDrawMs == other.tooltipDrawMs;

  // Object.hash takes at most 20 values.
  @override
  int get hashCode => Object.hashAll([
    mode,
    points,
    labels,
    frames,
    fps,
    drawMs,
    updateMs,
    animatorMs,
    elementsMs,
    layoutMs,
    datasetsUpdateMs,
    datasetsDrawMs,
    ticks,
    rotation,
    sharing,
    buildMs,
    buildMaxMs,
    rasterMs,
    rasterMaxMs,
    timings,
    tooltipDrawMs,
  ]);
}

const StressStats _noStats = StressStats(
  mode: StressMode.primitives,
  points: 0,
  labels: 0,
  frames: 0,
  fps: 0,
  drawMs: 0,
  updateMs: 0,
  animatorMs: 0,
  elementsMs: 0,
  layoutMs: 0,
  datasetsUpdateMs: 0,
  datasetsDrawMs: 0,
  ticks: 0,
  rotation: 0,
  sharing: false,
  buildMs: 0,
  buildMaxMs: 0,
  rasterMs: 0,
  rasterMaxMs: 0,
  timings: 0,
);

/// A performance test bed: a chart host drawn again in every frame.
///
/// `requestAnimFrame` (helpers.extras) schedules each frame, as the
/// Chart.js animator does. A frame draws the N items of the [StressMode]
/// and M rotated labels with `renderText`:
/// - [StressMode.primitives]: N moving points with `drawPoint` and a
///   polyline through N points.
/// - [StressMode.elements]: the same scene with N `PointElement` objects and
///   one `LineElement`.
/// - [StressMode.bars]: N `BarElement` objects with heights that move.
/// - [StressMode.arcs]: N `ArcElement` objects with angles that move.
/// - [StressMode.chart]: a real `Chart` of N items of a [StressChartType].
///   Each frame calls `chart.draw()`, or writes the moving values into the
///   data and calls `chart.update('none')` ([StressChartCall]). An inline
///   plugin draws the labels and the title in its `afterDraw` hook.
/// - [StressMode.axes]: the chart of [StressMode.chart] on real scales. An
///   update gives the scales new data limits, ticks, label sizes and a
///   rotation, and maps each point with `getPixelForValue`.
/// - [StressMode.plugins]: the chart of a plugin case of the frameless
///   benchmark ([StressPluginScene]). Each frame calls `chart.draw()`, or
///   changes the data and calls `chart.update('none')`, or sends the event
///   of a tooltip scene to the chart ([StressChartCall.frame]).
///
/// The element modes make their elements once for each mode and N. Each
/// frame writes the properties that move with the typed setters, and then
/// calls `draw` of each element. The mode [StressMode.chart] makes a new
/// chart for each N, chart type, `showLine` value and `backgroundColor`
/// form. The mode [StressMode.axes] makes a new chart for each N, scale
/// type and `autoSkip` value. The mode [StressMode.plugins] makes a new
/// chart for each N and [StressPluginCase].
///
/// The labels have one fixed angle of -45 degrees, as the tick labels of a
/// chart have; the `spin labels` switch gives each label a new angle in
/// every frame.
/// The readout shows the frames per second, the time of the draw calls,
/// and the build and raster times of `SchedulerBinding.addTimingsCallback`.
///
/// Every control has a `ValueKey` (`stress.mode.bars`, `stress.n.5000`,
/// `stress.m.200`, `stress.start`, `stress.chart.call.update`,
/// `stress.chart.type.bar`, `stress.axes.scale.time`,
/// `stress.plugins.scene.fade`, …) so that automation can drive it.
class StressDemo extends StatefulWidget {
  /// Creates the stress tab.
  ///
  /// [initialMode], [initialN] and [initialM] set the first mode, item count
  /// and label count. [initialSpin] and [initialLine] set the first state of
  /// two layer switches. [initialCall], [initialType], [initialShowLine] and
  /// [initialScriptable] set the case of the mode [StressMode.chart].
  /// [initialCall], [initialScale], [initialYScale] and [initialAutoSkip]
  /// set the case of the mode [StressMode.axes]. [initialPluginCase] sets
  /// the case of the mode [StressMode.plugins]. Each mode takes the first
  /// of its calls for a call that it does not have ([stressCallOf]): the
  /// mode [StressMode.axes] takes [StressChartCall.draw] for
  /// [StressChartCall.animate], and a tooltip scene takes
  /// [StressChartCall.frame].
  /// [autoStart] starts the loop when the chart exists. [onStats] receives
  /// each published [StressStats]. They let a profiling entry point
  /// (`lib/main_stress.dart`) or a test drive the tab. [host] selects the
  /// widget of the chart of the modes with a chart ([StressHost]).
  const StressDemo({
    this.initialMode = StressMode.primitives,
    this.initialN,
    this.initialM,
    this.initialSpin = false,
    this.initialLine = true,
    this.initialCall = StressChartCall.draw,
    this.initialType = StressChartType.line,
    this.initialShowLine = false,
    this.initialScriptable = false,
    this.initialScale = StressAxisType.linear,
    this.initialYScale = StressAxisType.linear,
    this.initialAutoSkip = true,
    this.initialPluginCase = const StressPluginCase(StressPluginScene.legend),
    this.autoStart = false,
    this.onStats,
    this.host = StressHost.canvas,
    this.chartSemanticsOnly = false,
    super.key,
  });

  /// The first mode.
  final StressMode initialMode;

  /// The first item count, or the first count of [initialMode].
  final int? initialN;

  /// The first label count, or 50.
  final int? initialM;

  /// Whether the labels start with a new angle in each frame.
  final bool initialSpin;

  /// Whether the modes [StressMode.primitives] and [StressMode.elements]
  /// start with their line (the layer `stress.layer.line`).
  final bool initialLine;

  /// The first call of each frame in the mode [StressMode.chart].
  final StressChartCall initialCall;

  /// The first chart type of the mode [StressMode.chart].
  final StressChartType initialType;

  /// Whether a `line` or `scatter` chart of the mode [StressMode.chart]
  /// starts with its line (the dataset option `showLine`). The other types
  /// have no line: they take false.
  final bool initialShowLine;

  /// Whether the chart items start with a scriptable `backgroundColor`.
  final bool initialScriptable;

  /// The first scale type of the x axis in the mode [StressMode.axes].
  final StressAxisType initialScale;

  /// The first scale type of the y axis in the mode [StressMode.axes]: one
  /// of [stressAxesValueTypes].
  final StressAxisType initialYScale;

  /// The first option `ticks.autoSkip` of the x axis in the mode
  /// [StressMode.axes].
  final bool initialAutoSkip;

  /// The first case of the mode [StressMode.plugins].
  final StressPluginCase initialPluginCase;

  /// Whether the loop starts as soon as the chart exists.
  final bool autoStart;

  /// Receives the figures each time the readout updates.
  final ValueChanged<StressStats>? onStats;

  /// The widget that hosts the chart of the modes [StressMode.chart],
  /// [StressMode.axes] and [StressMode.plugins]. The other modes draw on the
  /// demo canvas.
  final StressHost host;

  /// Whether the toolbar and the readout are out of the semantics tree
  /// (`ExcludeSemantics`), so that only the chart and the static text give
  /// semantics nodes. The stress entry sets it with the define `SEMANTICS`
  /// (protocol B-N1 of phase 9): the readout changes twice a second, and its
  /// semantics updates are not the cost of the chart node.
  final bool chartSemanticsOnly;

  @override
  State<StressDemo> createState() => StressDemoState();
}

/// The state of a [StressDemo]: the loop, the scene and the figures.
class StressDemoState extends State<StressDemo> {
  static final int _maxPoints = stressPointCounts.reduce(math.max);

  late StressMode _mode = widget.initialMode;
  late StressChartType _type = widget.initialType;
  late int _n = widget.initialN ?? _countsOf(_mode).first;
  late int _m = widget.initialM ?? stressLabelCounts[1];
  bool _points = true;
  late bool _line = widget.initialLine;
  late bool _spin = widget.initialSpin;
  late StressPluginCase _pluginCase = widget.initialPluginCase;
  // The mode axes has no call animate: it takes the call draw, as _setScene
  // does. Else the first frame waits for an animation that does not start.
  late StressChartCall _call = stressCallOf(
    _mode,
    widget.initialCall,
    _pluginCase.scene,
  );
  late bool _showLine = widget.initialShowLine;
  late bool _scriptable = widget.initialScriptable;
  late StressAxisType _scale = widget.initialScale;
  late StressAxisType _yScale = widget.initialYScale;
  late bool _autoSkip = widget.initialAutoSkip;
  bool _running = false;
  bool _muted = false;
  bool _autoStarted = false;

  DemoChart? _chart;
  int? _frameId;

  // The modes [StressMode.chart] and [StressMode.axes]: the chart, its
  // dataset data and the timing plugin. A [_StressChart] on the host
  // [StressHost.canvas], a plain chart of a ChartView on [StressHost.view].
  Chart? _stressChart;

  // The host [StressHost.view]: the config of the ChartView of the host key
  // [_viewKey], the meter of its plugins, and the meter of each chart that a
  // ChartView made.
  Object? _viewKey;
  Map<String, Object?>? _viewConfig;
  late _PluginMeter _viewMeter;
  final Expando<_StressMeter> _viewMeters = Expando('stress meters');
  List<Object?> _chartData = const [];
  final StressChartTiming _timing = StressChartTiming();

  // The mode [StressMode.chart]: the items of the chart.
  StressChartScene? _chartScene;

  // The mode [StressMode.axes]: the data objects of the chart.
  StressAxesScene? _axesScene;

  // The mode [StressMode.plugins]: the benchmark scene of the chart, the
  // index of the hovered point (scene hover), and the frame of the fade and
  // its direction (scene fade).
  ChartBenchScene? _pluginScene;
  int _hoverIndex = 0;
  int _fadeFrame = 0;
  bool _fadeShown = false;

  // Point positions and velocities, in fractions of the chart per second.
  // The chart benchmark (lib/bench/chart_bench.dart) uses the same points.
  final StressPointField _field = StressPointField(_maxPoints);
  Float64List get _px => _field.x;
  Float64List get _py => _field.y;
  double _t = 0;
  final Stopwatch _clock = Stopwatch();
  Duration _lastTick = Duration.zero;

  // The elements of the element modes. _buildScene makes them once for each
  // mode and N. The frames only write their properties.
  List<PointElement> _pointElements = const [];
  List<PointElement> _linePoints = const [];
  LineElement? _lineElement;
  List<BarElement> _bars = const [];
  List<ArcElement> _arcs = const [];
  int _sceneBuilds = 0;
  ChartArea? _area;

  // The slice weights of one doughnut ring, written in each frame.
  final Float64List _sliceWeights = Float64List(_arcSlices);

  // Statistics.
  final ValueNotifier<StressStats> _stats = ValueNotifier(_noStats);
  int _frames = 0;
  int _windowFrames = 0;
  int _windowDrawMicros = 0;
  int _windowUpdateMicros = 0;
  int _windowAnimatorMicros = 0;
  // The parts of [StressChartTiming] of the frame calls of the window.
  int _windowElementsTicks = 0;
  int _windowLayoutTicks = 0;
  int _windowDatasetsUpdateTicks = 0;
  int _windowDatasetsDrawTicks = 0;
  int _windowTooltipDrawTicks = 0;
  Duration _windowStart = Duration.zero;
  double _fps = 0;
  double _drawMs = 0;
  double _updateMs = 0;
  double _animatorMs = 0;
  double _elementsMs = 0;
  double _layoutMs = 0;
  double _datasetsUpdateMs = 0;
  double _datasetsDrawMs = 0;
  double _tooltipDrawMs = 0;
  final List<FrameTiming> _timings = [];

  final ParsedFont _labelFont = toFont(<String, Object?>{'size': 12});
  final ParsedFont _titleFont = toFont(<String, Object?>{
    'size': 13,
    'weight': 'bold',
  });

  /// The count of the element builds: one for each start, change of the
  /// mode or change of N in an element mode. The frames do not make
  /// elements.
  @visibleForTesting
  int get debugSceneBuilds => _sceneBuilds;

  /// The elements that the frames draw: the point elements and the line,
  /// the bars, or the arcs. Empty in the mode [StressMode.primitives].
  @visibleForTesting
  List<VisualElement> get debugElements => [
    ..._pointElements,
    ?_lineElement,
    ..._bars,
    ..._arcs,
  ];

  /// The chart of the modes [StressMode.chart] and [StressMode.axes], once
  /// it exists.
  @visibleForTesting
  Chart? get debugChart => _stressChart;

  /// The frames of the loop since the last start. A frame that waits for
  /// the chart of a new host does not count.
  @visibleForTesting
  int get debugFrames => _frames;

  /// The dataset data of the chart of the modes [StressMode.chart] and
  /// [StressMode.axes]: the data objects `{x, y}` of `line`, `scatter` and
  /// the mode axes, the objects `{x, y, r}` of `bubble`, or numbers.
  @visibleForTesting
  List<Object?> get debugChartData => _chartData;

  /// The N choices of [mode]: the counts of the chart type in the mode
  /// [StressMode.chart], else the counts of the mode.
  List<int> _countsOf(StressMode mode) =>
      mode == StressMode.chart ? _type.counts : mode.counts;

  /// Whether the chart of the mode [StressMode.chart] shows its line: only a
  /// `line` or `scatter` chart has one.
  bool get _effectiveShowLine => _showLine && _type.points;

  @override
  void initState() {
    super.initState();
    _buildScene();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  @override
  void dispose() {
    _cancelFrame();
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _stats.dispose();
    super.dispose();
  }

  void _onTimings(List<FrameTiming> timings) {
    _timings.addAll(timings);
    if (_timings.length > 120) {
      _timings.removeRange(0, _timings.length - 120);
    }
  }

  void _setRunning(bool running) {
    setState(() => _running = running);
    if (running) {
      _clock
        ..reset()
        ..start();
      _lastTick = Duration.zero;
      _windowStart = Duration.zero;
      _windowFrames = 0;
      _windowDrawMicros = 0;
      _windowUpdateMicros = 0;
      _windowAnimatorMicros = 0;
      _windowElementsTicks = 0;
      _windowLayoutTicks = 0;
      _windowDatasetsUpdateTicks = 0;
      _windowDatasetsDrawTicks = 0;
      _windowTooltipDrawTicks = 0;
      _frames = 0;
      _timings.clear();
      // The first frame of the animated case starts the animation again.
      _animating = false;
      _scheduleFrame();
    } else {
      _cancelFrame();
      _clock.stop();
      if (_animating) _stressChart?.stop();
      _publish();
    }
  }

  /// Sets the mode and N. A change of the mode keeps N when N is one of the
  /// counts of the new mode. Else it takes the count of the new mode at the
  /// index of N in the counts of the old mode, as a new chart type does. An
  /// N that is not one of the old counts (an `initialN` of a test) stays,
  /// but not above the largest count of the new mode. An explicit [n] wins.
  /// A change of either makes the elements again. In the modes
  /// [StressMode.chart] and [StressMode.axes], a change of N makes a new
  /// chart. The new mode takes the first of its calls for a call that it
  /// does not have ([stressCallOf]): the mode [StressMode.axes] changes the
  /// call [StressChartCall.animate] to [StressChartCall.draw].
  void _setScene({StressMode? mode, int? n}) {
    final newMode = mode ?? _mode;
    final newN = n ?? (mode == null ? _n : _countForMode(newMode));
    if (newMode == _mode && newN == _n) return;
    // The modes of the demo chart share one host. The modes chart and axes
    // have a host of their own, and a new host for each N. A new host gives
    // its chart.
    if (newMode.runsChart) {
      _stressChart = null;
      if (!_mode.runsChart) _chart = null;
    } else if (_mode.runsChart) {
      _stressChart = null;
    }
    _call = stressCallOf(newMode, _call, _pluginCase.scene);
    _mode = newMode;
    _n = newN;
    _buildScene();
  }

  /// The N of [mode] after a change from the current mode (see [_setScene]).
  int _countForMode(StressMode mode) {
    final counts = _countsOf(mode);
    if (counts.contains(_n)) return _n;
    final index = _countsOf(_mode).indexOf(_n);
    if (index < 0) return math.min(_n, counts.last);
    return index < counts.length ? counts[index] : counts.first;
  }

  /// Sets the case of the mode [StressMode.axes]. A change makes a new
  /// chart.
  void _setAxesCase({
    StressAxisType? scale,
    StressAxisType? yScale,
    bool? autoSkip,
  }) {
    final newScale = scale ?? _scale;
    final newYScale = yScale ?? _yScale;
    final newAutoSkip = autoSkip ?? _autoSkip;
    if (newScale == _scale &&
        newYScale == _yScale &&
        newAutoSkip == _autoSkip) {
      return;
    }
    _scale = newScale;
    _yScale = newYScale;
    _autoSkip = newAutoSkip;
    _stressChart = null;
  }

  /// Sets the case of the mode [StressMode.plugins]. A change makes a new
  /// chart. The new scene takes the first of its calls for a call that it
  /// does not have.
  void _setPluginCase(StressPluginCase pluginCase) {
    if (pluginCase == _pluginCase) return;
    _pluginCase = pluginCase;
    _call = stressCallOf(_mode, _call, pluginCase.scene);
    _stressChart = null;
  }

  /// Sets the case of the mode [StressMode.chart]. A change of the chart
  /// type, of `showLine`, of the `backgroundColor` form, or to or from
  /// [StressChartCall.animate] (another `animation` option) makes a new
  /// chart. A new type keeps the index of N in the counts of the type.
  void _setChartCase({
    StressChartCall? call,
    StressChartType? type,
    bool? showLine,
    bool? scriptable,
  }) {
    final newCall = call ?? _call;
    final animated = newCall == StressChartCall.animate;
    final animatedChanged = animated != (_call == StressChartCall.animate);
    _call = newCall;
    final newType = type ?? _type;
    final newShowLine = showLine ?? _showLine;
    final newScriptable = scriptable ?? _scriptable;
    if (newType == _type &&
        newShowLine == _showLine &&
        newScriptable == _scriptable &&
        !animatedChanged) {
      return;
    }
    if (newType != _type) {
      final index = _type.counts.indexOf(_n);
      if (index >= 0) _n = newType.counts[index];
    }
    _type = newType;
    _showLine = newShowLine;
    _scriptable = newScriptable;
    _stressChart = null;
  }

  /// The resolved options of each point element: the defaults of
  /// element.point.ts and the colors of the [StressMode.primitives] points,
  /// as typed options (Chart.js ADR 0018). All points share the object, as
  /// the shared options of a dataset are.
  static final element_options.PointOptions _pointElementOptions =
      element_options.PointOptions({
        ...PointElement.defaults,
        'backgroundColor': 'rgba(54, 162, 235, 0.45)',
        'borderColor': '#36A2EB',
        'borderWidth': 1.0,
        'pointStyle': 'circle',
        'radius': 3.0,
      });

  /// The resolved options of the line: the defaults of element.line.js and
  /// the color and width of the [StressMode.primitives] polyline, as typed
  /// options (Chart.js ADR 0018). A `List<double>` dash goes to
  /// `setLineDash` without a copy.
  static final element_options.LineOptions _lineElementOptions =
      element_options.LineOptions({
        ...LineElement.defaults,
        'borderColor': '#FF6384',
        'borderDash': const <double>[],
        'borderWidth': 1.5,
        'tension': 0.0,
      });

  /// The resolved options of each bar: the defaults of element.bar.js with
  /// a border and rounded corners, as typed options (Chart.js ADR 0018). All
  /// bars share the object, as the shared options of a dataset are.
  static final element_options.BarOptions _barOptions =
      element_options.BarOptions({
        ...BarElement.defaults,
        'backgroundColor': 'rgba(54, 162, 235, 0.45)',
        'borderColor': '#36A2EB',
        'borderWidth': 1.0,
        'borderRadius': 4.0,
      });

  /// controller.bar.js:202-232 `setBorderSkipped` for the option
  /// `borderSkipped: 'start'` of a vertical bar with a value above its
  /// base: the bottom edge has no border.
  static const Map<String, Object?> _barBorderSkipped = {'bottom': true};

  /// The slices of one doughnut ring.
  static const int _arcSlices = 5;

  /// The rings of one doughnut, one for each dataset.
  static const int _arcRings = 2;

  /// The resolved options of the arcs of each slice index: the defaults of
  /// element.arc.ts with the spacing and the rounded corners, and the
  /// colors of the Chart.js colors plugin, as typed options (Chart.js ADR
  /// 0018). A `List<double>` dash goes to `setLineDash` without a copy.
  static final List<element_options.ArcOptions> _arcOptions = [
    for (final color in const [
      'rgba(54, 162, 235, 0.5)',
      'rgba(255, 99, 132, 0.5)',
      'rgba(255, 159, 64, 0.5)',
      'rgba(255, 205, 86, 0.5)',
      'rgba(75, 192, 192, 0.5)',
    ])
      element_options.ArcOptions({
        ...ArcElement.defaults,
        'backgroundColor': color,
        'borderDash': const <double>[],
        'borderRadius': 4.0,
        'borderWidth': 2.0,
        'spacing': 2.0,
      }),
  ];

  /// Makes the elements of the mode for N items, and drops the elements of
  /// the other modes.
  void _buildScene() {
    _pointElements = const [];
    _linePoints = const [];
    _lineElement = null;
    _bars = const [];
    _arcs = const [];
    switch (_mode) {
      case StressMode.primitives:
        return;
      case StressMode.elements:
        _pointElements = [
          for (var i = 0; i < _n; i++)
            PointElement()..options = _pointElementOptions,
        ];
        _linePoints = [for (var i = 0; i < _n; i++) PointElement()];
        _lineElement = LineElement()
          ..options = _lineElementOptions
          ..points = _linePoints
          // controller.line.js:65-68 writes `animated: !animationsDisabled`.
          // The points move in each frame, as in an animation. Thus each
          // draw drops the cached path (element.line.js:439-443), and the
          // next draw makes a new Path2D.
          ..animated = true;
      case StressMode.bars:
        _bars = [
          for (var i = 0; i < _n; i++)
            BarElement()
              ..options = _barOptions
              ..horizontal = false
              ..borderSkipped = _barBorderSkipped
              // controller.bar.js:410: true for a bar that is not stacked.
              ..enableBorderRadius = true
              // controller.bar.js:252-256: 'auto' gives 0 when the ratio of
              // the bar width is not 1.
              ..inflateAmount = 0,
        ];
      case StressMode.arcs:
        _arcs = [
          for (var i = 0; i < _n; i++)
            ArcElement()..options = _arcOptions[i % _arcSlices],
        ];
      case StressMode.chart || StressMode.axes || StressMode.plugins:
        // The chart makes its elements.
        return;
    }
    _sceneBuilds++;
  }

  /// The config of `new Chart(canvas, config)` of the mode
  /// [StressMode.chart]: one dataset
  /// of N items of the chart type at the values of the moving points, with
  /// `animation: false`, or the looping animation of
  /// [StressChartCall.animate]. `stressChartConfig` gives the config, which
  /// the chart benchmark (lib/bench/chart_bench.dart) also uses.
  ///
  /// The inline plugin `stressLabels` draws the M labels and the title in
  /// its `afterDraw` hook, as the other modes draw them after their items.
  /// The plugin of [StressChartTiming] times the parts.
  Map<String, Object?> _chartConfig() {
    registerGalleryComponents();
    final scene = _chartScene = StressChartScene(_type, _n, _field);
    _chartData = scene.data;
    return stressChartConfig(
      scene: scene,
      scriptable: _scriptable,
      showLine: _effectiveShowLine,
      animate: _call == StressChartCall.animate,
      plugins: [_labelsPlugin, _timing.plugin],
    );
  }

  /// The config of `new Chart(canvas, config)` of the mode
  /// [StressMode.axes]: a `LineController` chart on the scales of
  /// `stressAxesConfig`, and the timing plugin of [StressChartTiming].
  Map<String, Object?> _axesChartConfig() {
    registerGalleryComponents();
    final scene = _axesScene = StressAxesScene(
      _n,
      x: _scale,
      y: _yScale,
      positions: _field,
    );
    _chartData = scene.data;
    return stressAxesConfig(
      scene: scene,
      autoSkip: _autoSkip,
      plugins: [_labelsPlugin, _timing.plugin],
    );
  }

  /// The config of `new Chart(canvas, config)` of the mode
  /// [StressMode.plugins]: the config of the benchmark case of the plugin
  /// case and the call ([stressPluginBenchCase]) for N points in each
  /// dataset, made for the host by [stressHostConfig]. The config keeps the
  /// timing plugins of the case: the four parts of `StressChartTiming`, and
  /// the part `tooltipDraw` in the tooltip scenes. The inline plugin
  /// `stressLabels` comes first, as in the mode [StressMode.chart].
  Map<String, Object?> _pluginChartConfig() {
    registerGalleryComponents();
    final scene = _pluginScene = stressPluginBenchCase(
      _pluginCase,
      _call,
    ).scene(_n);
    final config = stressHostConfig(scene.config);
    config['plugins'] = <Object?>[
      _labelsPlugin,
      ...config['plugins']! as List<Object?>,
    ];
    _chartData = const [];
    return config;
  }

  /// The host of the chart of [config] for the host key [hostKey], with the
  /// key [key] and the height [height] ([StressHost]): a [ChartCanvas] that
  /// makes a [_StressChart] of a new config, or a [ChartView] of one config
  /// for each host key, with the plugins of a [_PluginMeter] around its
  /// inline plugins. [onChart] gets the chart.
  Widget _chartHost({
    required Object hostKey,
    required String key,
    required double height,
    required Map<String, Object?> Function() config,
    required ValueChanged<Chart> onChart,
  }) {
    if (widget.host == StressHost.canvas) {
      return ChartCanvas(
        key: ValueKey(key),
        height: height,
        create: (canvas) => _StressChart(canvas, config()),
        onChart: onChart,
        onTickerModeChanged: _onTickerModeChanged,
      );
    }
    // One config for each host: a rebuild of the tab gives the ChartView
    // the same Map, thus no update (Chart.js ADR 0049, section 4).
    final viewKey = (_mode, hostKey);
    if (_viewKey != viewKey || _viewConfig == null) {
      final meter = _viewMeter = _PluginMeter();
      final viewConfig = _viewConfig = config();
      viewConfig['plugins'] = <Object?>[
        meter.first,
        ...viewConfig['plugins']! as List<Object?>,
        meter.last,
      ];
      _viewKey = viewKey;
    }
    final meter = _viewMeter;
    return SizedBox(
      height: height,
      child: ChartView.raw(
        key: ValueKey(key),
        config: _viewConfig!,
        onChartCreated: (chart) {
          _viewMeters[chart] = meter;
          onChart(chart);
        },
      ),
    );
  }

  /// Brings a new chart of the mode [StressMode.plugins] into the state of
  /// its case, before the first frame: the preparation of the benchmark
  /// case (for example the hover and the end of the animations of the
  /// scene [StressPluginScene.still]). Then it drops the times and the
  /// parts of the construction.
  void _preparePluginChart(Chart chart) {
    final scene = _pluginScene;
    if (scene == null) return;
    scene.prepare?.call(chart);
    _hoverIndex = 0;
    _fadeFrame = 0;
    _fadeShown = false;
    scene.takeParts?.call();
    _meterOf(chart)
      ..drawMicros = 0
      ..animatorMicros = 0;
  }

  /// The inline plugin `stressLabels`: the M labels and the title, after the
  /// draw of the chart.
  Map<String, Object?> get _labelsPlugin => <String, Object?>{
    'id': 'stressLabels',
    'afterDraw': (Object? chart, Object? args, Object? options) {
      final stressChart = chart! as Chart;
      final ctx = stressChart.ctx;
      if (ctx == null) return;
      _drawLabels(ctx, stressChart.width, stressChart.height);
      _drawTitle(ctx);
    },
  };

  /// A host gave its chart. The first chart starts the loop for
  /// [StressDemo.autoStart]. A running loop that waited for the chart of a
  /// new host continues.
  void _chartReady() {
    if (_running) {
      _scheduleFrame();
    } else if (widget.autoStart && !_autoStarted) {
      _autoStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_running) _setRunning(true);
      });
    }
  }

  void _onTickerModeChanged(bool enabled) {
    _muted = !enabled;
    if (enabled && _running) _scheduleFrame();
  }

  void _scheduleFrame() {
    if (_frameId != null || _muted) return;
    // helpers.extras.ts:14 requestAnimFrame: one frame callback.
    _frameId = requestAnimFrame(_onFrame);
  }

  void _cancelFrame() {
    final id = _frameId;
    if (id != null) {
      SchedulerBinding.instance.cancelFrameCallbackWithId(id);
      _frameId = null;
    }
  }

  void _onFrame() {
    _frameId = null;
    if (!_running || !mounted) return;
    final chart = _chart;
    final stressChart = _stressChart;
    // A new host gives its chart after its first frame. Then _chartReady
    // continues the loop.
    if (_mode.runsChart ? stressChart == null : chart == null) {
      return;
    }
    final now = _clock.elapsed;
    final dt = math.min(
      (now - _lastTick).inMicroseconds / 1e6,
      0.05,
    );
    _lastTick = now;
    _step(dt);
    if (stressChart != null && _mode.runsChart) {
      _chartFrame(stressChart);
    } else {
      chart!.render();
      _windowDrawMicros += chart.lastDrawMicros;
    }
    _frames++;
    _windowFrames++;
    final window = now - _windowStart;
    if (window >= const Duration(milliseconds: 500)) {
      _fps = _windowFrames / (window.inMicroseconds / 1e6);
      _drawMs = _windowDrawMicros / _windowFrames / 1000;
      _updateMs = _windowUpdateMicros / _windowFrames / 1000;
      _animatorMs = _windowAnimatorMicros / _windowFrames / 1000;
      // The parts of the modes chart and axes: the hooks of the frame calls
      // of the window ([_chartFrame]).
      double perFrame(int ticks) =>
          ticks / StressChartTiming.ticksPerMs / _windowFrames;
      _elementsMs = perFrame(_windowElementsTicks);
      _layoutMs = perFrame(_windowLayoutTicks);
      _datasetsUpdateMs = perFrame(_windowDatasetsUpdateTicks);
      _datasetsDrawMs = perFrame(_windowDatasetsDrawTicks);
      _tooltipDrawMs = perFrame(_windowTooltipDrawTicks);
      _windowStart = now;
      _windowFrames = 0;
      _windowDrawMicros = 0;
      _windowUpdateMicros = 0;
      _windowAnimatorMicros = 0;
      _windowElementsTicks = 0;
      _windowLayoutTicks = 0;
      _windowDatasetsUpdateTicks = 0;
      _windowDatasetsDrawTicks = 0;
      _windowTooltipDrawTicks = 0;
      _publish();
    }
    // In the animated case, the progress listener of the animator schedules
    // the next frame, so that this callback runs before the animator
    // callback of that frame ([_chartFrame]).
    if (!(stressChart != null && _animating)) _scheduleFrame();
  }

  /// Whether the chart of [StressChartCall.animate] runs its animation.
  bool _animating = false;

  /// The chart that has the progress listener of [_animateFrame].
  Chart? _listenedChart;

  /// The draw meter of [chart]: the chart itself on the host
  /// [StressHost.canvas], else the plugins of its ChartView.
  _StressMeter _meterOf(Chart chart) =>
      chart is _StressChart ? chart : _viewMeters[chart]!;

  /// One frame of the modes [StressMode.chart] and [StressMode.axes]: case
  /// (a) or case (b) of Chart.js ADR 0021, section 8.
  ///
  /// The draw time is the time of `chart.draw()`, also inside
  /// `chart.update()`. The update time is the time of `chart.update()`
  /// without its draw. The writes of the values into the data are in
  /// neither time. The plugin of [StressChartTiming] times the parts. The
  /// parts count only the hooks of this call, as the draw time does: not the
  /// update at the construction of a chart, and not the update of a resize
  /// of its host.
  void _chartFrame(Chart chart) {
    if (_mode == StressMode.plugins) {
      _pluginFrame(chart);
      return;
    }
    if (_call == StressChartCall.animate) {
      _animateFrame(chart);
      return;
    }
    if (_call == StressChartCall.update) {
      if (_mode == StressMode.axes) {
        _axesScene?.write(_field);
      } else {
        _chartScene?.write(_field);
      }
    }
    final meter = _meterOf(chart)..drawMicros = 0;
    final timing = _timing..reset();
    final watch = Stopwatch()..start();
    switch (_call) {
      case StressChartCall.draw:
        chart.draw();
      case StressChartCall.update:
        chart.update('none');
      case StressChartCall.animate || StressChartCall.frame:
        // [_animateFrame] handles the call animate. Only the mode plugins
        // has the call frame ([_pluginFrame]).
        break;
    }
    final total = watch.elapsedMicroseconds;
    _windowDrawMicros += meter.drawMicros;
    _windowUpdateMicros += total - meter.drawMicros;
    _windowElementsTicks += timing.elementsTicks;
    _windowLayoutTicks += timing.layoutTicks;
    _windowDatasetsUpdateTicks += timing.datasetsUpdateTicks;
    _windowDatasetsDrawTicks += timing.datasetsDrawTicks;
  }

  /// One frame of [StressChartCall.animate].
  ///
  /// The first frame writes the positions and calls `chart.update()`, which
  /// starts the looping animations. The animator then ticks them in its own
  /// frame callback and calls `chart.draw()`. A progress listener schedules
  /// this callback for the next frame. Thus in each frame this callback runs
  /// first: it marks the time, and [_StressChart.draw] takes the time from
  /// the mark to the start of the draw, the tick of the animator. The
  /// figures of the animator frame come in the next frame.
  void _animateFrame(Chart chart) {
    final meter = _meterOf(chart);
    if (!_animating) {
      _animating = true;
      _chartScene?.write(_field);
      if (!identical(_listenedChart, chart)) {
        _listenedChart = chart;
        animator.listen(chart, 'progress', (_) {
          if (mounted && _running && identical(_stressChart, chart)) {
            _scheduleFrame();
          }
        });
      }
      meter.drawMicros = 0;
      final watch = Stopwatch()..start();
      chart.update();
      _windowUpdateMicros += watch.elapsedMicroseconds - meter.drawMicros;
    }
    _windowDrawMicros += meter.drawMicros;
    _windowAnimatorMicros += meter.animatorMicros;
    meter
      ..drawMicros = 0
      ..animatorMicros = 0
      ..markTick();
  }

  /// One frame of the mode [StressMode.plugins]: the call of the benchmark
  /// case in the real frame loop.
  ///
  /// - [StressChartCall.draw]: `chart.draw()`.
  /// - [StressChartCall.update]: the change of the data of the benchmark
  ///   scene (not timed), then `chart.update('none')`.
  /// - [StressChartCall.frame], scene [StressPluginScene.hover]: a
  ///   `mousemove` over the next point of dataset 0 directly to the event
  ///   handler of the chart, around the host input path
  ///   ([_sendPluginEvent]). The chart has `animation: false`, so the event
  ///   draws the chart at once.
  /// - [StressChartCall.frame], scene [StressPluginScene.fade]: in the
  ///   first frame of each `chartBenchFadeFrames` frames, a `mousemove`
  ///   over the middle point of dataset 0 or a `mouseout`, in turn, also
  ///   directly to the event handler. The event starts the animations.
  ///   The animator ticks them and draws the chart in its own frame
  ///   callback.
  ///
  /// The update time is the time of the call without its draws: in the
  /// scenes hover and fade, the event handler of the chart only. The draw
  /// time has the draws of the call and of the animator callbacks. The
  /// animator time is the tick of the animator before its draw (scene
  /// fade): this callback schedules the next frame first, so that it runs
  /// before the animator callback of the next frame, and it marks the time
  /// at its end ([_StressChart.markTick]). The parts are the hooks since
  /// the last frame callback, also those of the animator callbacks. The
  /// events take the pointer positions from the elements before the
  /// timing.
  void _pluginFrame(Chart chart) {
    final scene = _pluginScene;
    if (scene == null) return;
    _scheduleFrame();
    // The animator callback of the last frame (scene fade).
    _takePluginFigures(chart, scene);
    final event = _call == StressChartCall.frame ? _pluginEvent(chart) : null;
    if (_call == StressChartCall.update) scene.change?.call();
    final watch = Stopwatch()..start();
    switch (_call) {
      case StressChartCall.draw:
        chart.draw();
      case StressChartCall.update:
        chart.update('none');
      case StressChartCall.frame:
        if (event != null) _sendPluginEvent(chart, event);
      case StressChartCall.animate:
        // The mode plugins has no call animate (stressCallsOf).
        break;
    }
    _windowUpdateMicros +=
        watch.elapsedMicroseconds - _meterOf(chart).drawMicros;
    _takePluginFigures(chart, scene);
    if (_pluginCase.scene == StressPluginScene.fade) _meterOf(chart).markTick();
  }

  /// Adds the draw time, the animator time and the parts of [chart] since
  /// the last call to the window, and resets them.
  void _takePluginFigures(Chart chart, ChartBenchScene scene) {
    final meter = _meterOf(chart);
    _windowDrawMicros += meter.drawMicros;
    _windowAnimatorMicros += meter.animatorMicros;
    meter
      ..drawMicros = 0
      ..animatorMicros = 0;
    final parts = scene.takeParts?.call();
    if (parts == null) return;
    _windowElementsTicks += parts['elements'] ?? 0;
    _windowLayoutTicks += parts['layout'] ?? 0;
    _windowDatasetsUpdateTicks += parts['datasetsUpdate'] ?? 0;
    _windowDatasetsDrawTicks += parts['datasetsDraw'] ?? 0;
    _windowTooltipDrawTicks += parts['tooltipDraw'] ?? 0;
  }

  /// The event of this frame of the scenes [StressPluginScene.hover] and
  /// [StressPluginScene.fade]: the type and the position of the pointer, or
  /// Dart `null` for no event. The pointer is at the y of the middle of the
  /// chart area, as in the benchmark. The positions come from the elements
  /// of dataset 0 in each frame, so that a resize of the host moves them.
  (String, double, double)? _pluginEvent(Chart chart) {
    final area = chart.chartArea;
    final points = chart.getDatasetMeta(0).data;
    if (area == null || points.isEmpty) return null;
    final y = (area.top + area.bottom) / 2;
    switch (_pluginCase.scene) {
      case StressPluginScene.hover:
        _hoverIndex = (_hoverIndex + 1) % points.length;
        return ('mousemove', points[_hoverIndex].x, y);
      case StressPluginScene.fade:
        final start = _fadeFrame == 0;
        _fadeFrame = (_fadeFrame + 1) % chartBenchFadeFrames;
        if (!start) return null;
        _fadeShown = !_fadeShown;
        // The pointer leaves the canvas at its left edge.
        return _fadeShown
            ? ('mousemove', points[points.length ~/ 2].x, y)
            : ('mouseout', -1, y);
      case _:
        return null;
    }
  }

  /// Sends the native event [event] directly to the event handler of
  /// [chart]: `chart.eventHandler(fromNativeEvent(event, chart))`, the call
  /// of `_benchEvent` of the benchmark. Thus `updateMs` compares with the
  /// update of the benchmark cell.
  ///
  /// This goes around the host input path of Chart.js ADR 0037: the pointer
  /// conversion of `ChartHost` and the throttled proxy of
  /// `createProxyAndListen` (platform.dom.js:240-254,
  /// `platform.flutter.dart`), which calls the handler in a
  /// `requestAnimFrame` callback. The handler runs at once, in this frame
  /// callback. `updateMs` is the time of the event handler of the chart only.
  void _sendPluginEvent(Chart chart, (String, double, double) event) {
    final (type, x, y) = event;
    // A direct call, as `_benchEvent` of the benchmark: no ChartHost pointer
    // conversion and no throttled proxy of the platform (Chart.js ADR 0037).
    // ignore: invalid_use_of_internal_member
    chart.eventHandler(
      fromNativeEvent(
        NativeEvent(type: type, offsetX: x, offsetY: y, target: chart.canvas),
        chart,
      ),
    );
  }

  void _step(double dt) {
    _t += dt;
    // The bars and the arcs move with the time only. The data of the mode
    // plugins changes in the call update ([_pluginFrame]).
    if (_mode == StressMode.bars ||
        _mode == StressMode.arcs ||
        _mode == StressMode.plugins) {
      return;
    }
    _field.step(_n, dt);
  }

  void _publish() {
    double avg(Iterable<Duration> values) => values.isEmpty
        ? 0
        : values.fold(0, (sum, d) => sum + d.inMicroseconds) /
              values.length /
              1000;
    double max(Iterable<Duration> values) =>
        values.fold(0, (m, d) => math.max(m, d.inMicroseconds / 1000));
    final build = _timings.map((t) => t.buildDuration);
    final raster = _timings.map((t) => t.rasterDuration);
    final stressChart = _stressChart;
    final axes = _mode == StressMode.axes && stressChart != null
        ? stressAxesTicks(stressChart)
        : null;
    _stats.value = StressStats(
      mode: _mode,
      points: _n,
      labels: _m,
      frames: _frames,
      fps: _fps,
      drawMs: _drawMs,
      updateMs: _updateMs,
      animatorMs: _animatorMs,
      elementsMs: _elementsMs,
      layoutMs: _layoutMs,
      datasetsUpdateMs: _datasetsUpdateMs,
      datasetsDrawMs: _datasetsDrawMs,
      ticks: axes?.ticks ?? 0,
      rotation: axes?.rotation ?? 0,
      sharing: _mode == StressMode.chart && _sharingOf(stressChart),
      buildMs: avg(build),
      buildMaxMs: max(build),
      rasterMs: avg(raster),
      rasterMaxMs: max(raster),
      timings: _timings.length,
      tooltipDrawMs: _tooltipDrawMs,
    );
    widget.onStats?.call(_stats.value);
  }

  /// The `enableOptionSharing` of the controller of dataset 0 of [chart],
  /// or the value of the chart type before the first update.
  bool _sharingOf(Chart? chart) =>
      chart?.getDatasetMeta(0).controller?.enableOptionSharing ?? _type.sharing;

  static const PointOptions _pointOptions = PointOptions(
    pointStyle: 'circle',
    radius: 3,
  );

  /// The y of point [i] of the polyline at the fraction [f] of the width,
  /// for the height [h]: a wave that moves with the time.
  double _waveY(int i, double f, double h) =>
      h / 2 +
      math.sin(f * 6 * math.pi + _t * 1.5) * h * 0.3 +
      math.sin(i * 0.37 + _t * 6) * h * 0.04;

  void _draw(DemoChart chart, CanvasRenderingContext2D ctx) {
    final w = chart.width;
    final h = chart.height;
    switch (_mode) {
      case StressMode.primitives:
        _drawPrimitives(ctx, w, h);
      case StressMode.elements:
        _drawElements(ctx, w, h);
      case StressMode.bars:
        _drawBars(ctx, w, h);
      case StressMode.arcs:
        _drawArcs(ctx, w, h);
      case StressMode.chart || StressMode.axes || StressMode.plugins:
        // The chart of these modes has its own host.
        return;
    }
    _drawLabels(ctx, w, h);
    _drawTitle(ctx);
  }

  /// The scene of [StressMode.primitives]: `drawPoint` for each point, and
  /// one polyline with `lineTo`.
  void _drawPrimitives(CanvasRenderingContext2D ctx, double w, double h) {
    if (_points) {
      ctx
        ..fillStyle = 'rgba(54, 162, 235, 0.45)'
        ..strokeStyle = '#36A2EB'
        ..lineWidth = 1;
      for (var i = 0; i < _n; i++) {
        drawPoint(ctx, _pointOptions, _px[i] * w, _py[i] * h);
      }
    }
    if (_line) {
      ctx
        ..strokeStyle = '#FF6384'
        ..lineWidth = 1.5
        ..beginPath();
      final last = _n - 1;
      for (var i = 0; i <= last; i++) {
        final f = i / last;
        final x = f * w;
        final y = _waveY(i, f, h);
        if (i == 0) {
          ctx.moveTo(x, y);
        } else {
          ctx.lineTo(x, y);
        }
      }
      ctx.stroke();
    }
  }

  /// The chart area of a chart of [w] x [h], made again only when the size
  /// changes.
  ChartArea _areaOf(double w, double h) {
    final area = _area;
    if (area != null && area.right == w && area.bottom == h) return area;
    return _area = Box(0, 0, w, h);
  }

  /// The scene of [StressMode.elements]: `PointElement.draw` for each point
  /// and `LineElement.draw` for the line.
  ///
  /// The line has no tension. Thus it takes the fast path of element.line.js
  /// (`fastPathSegment`), which joins the points of one x pixel into one
  /// vertical line. At large N its path has fewer segments than the
  /// polyline of [StressMode.primitives].
  void _drawElements(CanvasRenderingContext2D ctx, double w, double h) {
    // core.datasetController.js:736 element.draw(ctx, area).
    final area = _areaOf(w, h);
    if (_points) {
      final points = _pointElements;
      for (var i = 0; i < points.length; i++) {
        points[i]
          ..x = _px[i] * w
          ..y = _py[i] * h
          ..draw(ctx, area);
      }
    }
    final line = _lineElement;
    if (_line && line != null) {
      final points = _linePoints;
      final last = points.length - 1;
      for (var i = 0; i <= last; i++) {
        final f = i / last;
        points[i]
          ..x = f * w
          ..y = _waveY(i, f, h);
      }
      // core.datasetController.js:725 meta.dataset.draw(ctx, area, …).
      line.draw(ctx, area);
    }
  }

  /// The scene of [StressMode.bars]: a grid of cells, each with one
  /// vertical bar on the bottom of its cell. The cells are twice as high as
  /// wide. The heights move with the time.
  void _drawBars(CanvasRenderingContext2D ctx, double w, double h) {
    final bars = _bars;
    final n = bars.length;
    if (n == 0 || w <= 0 || h <= 0) return;
    final columns = math.max(1, math.sqrt(2 * n * w / h).ceil());
    final rows = (n / columns).ceil();
    final cellWidth = w / columns;
    final cellHeight = h / rows;
    // The defaults barPercentage 0.9 and categoryPercentage 0.8.
    final barWidth = cellWidth * 0.72;
    final maxHeight = cellHeight * 0.9;
    for (var i = 0; i < n; i++) {
      final base = (i ~/ columns + 1) * cellHeight;
      final height = maxHeight * (0.55 + 0.4 * math.sin(_t * 2 + i * 0.37));
      // controller.bar.js:677 draws each bar with draw(ctx).
      bars[i]
        ..x = (i % columns + 0.5) * cellWidth
        ..y = base - height
        ..base = base
        ..width = barWidth
        ..height = height
        ..draw(ctx);
    }
  }

  /// The scene of [StressMode.arcs]: a grid of doughnuts, each with
  /// [_arcRings] rings of [_arcSlices] slices. The weights of the slices
  /// move with the time. The angles follow controller.doughnut.js: the
  /// first slice starts at -90 degrees, and the cutout is 50 %.
  void _drawArcs(CanvasRenderingContext2D ctx, double w, double h) {
    final arcs = _arcs;
    final n = arcs.length;
    if (n == 0 || w <= 0 || h <= 0) return;
    final area = _areaOf(w, h);
    const perDoughnut = _arcSlices * _arcRings;
    final doughnuts = (n / perDoughnut).ceil();
    final columns = math.max(1, math.sqrt(doughnuts * w / h).ceil());
    final rows = (doughnuts / columns).ceil();
    final cellWidth = w / columns;
    final cellHeight = h / rows;
    final outerRadius = math.min(cellWidth, cellHeight) * 0.45;
    final ringWidth = (outerRadius - outerRadius * 0.5) / _arcRings;
    final weights = _sliceWeights;
    for (var first = 0, ring = 0; first < n; first += _arcSlices, ring++) {
      final count = math.min(_arcSlices, n - first);
      final doughnut = ring ~/ _arcRings;
      final x = (doughnut % columns + 0.5) * cellWidth;
      final y = (doughnut ~/ columns + 0.5) * cellHeight;
      // controller.doughnut.js:237-238: each ring has the same weight.
      final ringOuter = outerRadius - ringWidth * (ring % _arcRings);
      final ringInner = ringOuter - ringWidth;
      var total = 0.0;
      for (var s = 0; s < count; s++) {
        final weight = 1 + 0.6 * math.sin(_t * 1.2 + s * 1.3 + ring * 0.7);
        weights[s] = weight;
        total += weight;
      }
      var angle = -math.pi / 2;
      for (var s = 0; s < count; s++) {
        final circumference = weights[s] / total * 2 * math.pi;
        arcs[first + s]
          ..x = x
          ..y = y
          ..startAngle = angle
          ..endAngle = angle + circumference
          ..circumference = circumference
          ..outerRadius = ringOuter
          ..innerRadius = ringInner
          ..draw(ctx, area);
        angle += circumference;
      }
    }
  }

  /// The M labels of every mode.
  void _drawLabels(CanvasRenderingContext2D ctx, double w, double h) {
    if (_m > 0) {
      // A grid of labels, each rotated as an axis tick label is
      // (core.scale.js:1325 passes translation and rotation).
      final columns = math.max(1, math.sqrt(_m * w / h).ceil());
      final rows = (_m / columns).ceil();
      final cellWidth = w / columns;
      final cellHeight = h / rows;
      for (var j = 0; j < _m; j++) {
        final x = (j % columns + 0.5) * cellWidth;
        final y = (j ~/ columns + 0.5) * cellHeight;
        renderText(
          ctx,
          'Label $j',
          0,
          0,
          _labelFont,
          TextOpts(
            translation: (x, y),
            // A chart rotates its tick labels by one fixed angle. 'spin
            // labels' gives each label a new angle in every frame: the
            // worst case, because Impeller renders the glyphs again for
            // each new angle.
            rotation: _spin
                ? math.sin(_t + j * 0.3) * math.pi / 3
                : -math.pi / 4,
            color: labelColor,
            textAlign: 'center',
            textBaseline: 'middle',
          ),
        );
      }
    }
  }

  /// The title with the counts and the frame number.
  void _drawTitle(CanvasRenderingContext2D ctx) {
    final title = '$_n ${_mode.items} · $_m labels · frame $_frames';
    ctx.font = _titleFont.string;
    final titleWidth = ctx.measureText(title).width;
    renderText(
      ctx,
      title,
      8,
      8,
      _titleFont,
      TextOpts(
        color: '#333333',
        textBaseline: 'top',
        backdrop: Backdrop(
          4,
          4,
          titleWidth + 8,
          _titleFont.lineHeight + 4,
          'rgba(255, 255, 255, 0.85)',
        ),
      ),
    );
  }

  /// The controls: the start button, a segmented button for each choice and
  /// one segmented button of icons for the options. They wrap to the next
  /// line on a narrow screen. The chart comes after them.
  Widget _toolbar(ThemeData theme) {
    final layers =
        _mode == StressMode.primitives || _mode == StressMode.elements;
    String count(int v) => v >= 1000 ? '${v ~/ 1000}k' : '$v';
    const modeText = {
      StressMode.primitives: 'prim',
      StressMode.elements: 'elem',
      StressMode.bars: 'bars',
      StressMode.arcs: 'arcs',
      StressMode.chart: 'chart',
      StressMode.axes: 'axes',
      StressMode.plugins: 'plug',
    };
    const callText = {
      StressChartCall.draw: 'draw',
      StressChartCall.update: 'upd',
      StressChartCall.animate: 'anim',
      StressChartCall.frame: 'frame',
    };
    const axisText = {
      StressAxisType.linear: 'lin',
      StressAxisType.logarithmic: 'log',
      StressAxisType.category: 'cat',
      StressAxisType.time: 'time',
    };
    const gap = SizedBox(height: 6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SizedBox(
              width: 88,
              child: SegmentToggles(
                items: [
                  (
                    key: 'stress.start',
                    icon: _running ? Icons.pause : Icons.play_arrow,
                    tooltip: _running ? 'Stop' : 'Start',
                    value: _running,
                    onChanged: _setRunning,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _optionToggles(layers)),
          ],
        ),
        gap,
        SegmentChoice<StressMode>(
          label: 'mode',
          items: [
            for (final mode in StressMode.values)
              (
                key: 'stress.mode.${mode.name}',
                text: modeText[mode]!,
                icon: null,
                tooltip: mode.name,
                value: mode,
              ),
          ],
          value: _mode,
          onChanged: (mode) => setState(() => _setScene(mode: mode)),
        ),
        if (_mode == StressMode.chart) ...[
          gap,
          SegmentChoice<StressChartType>(
            label: 'type',
            items: [
              for (final type in StressChartType.values)
                (
                  key: 'stress.chart.type.${type.name}',
                  text: type.name,
                  icon: _typeIcons[type],
                  tooltip: type.name,
                  value: type,
                ),
            ],
            value: _type,
            onChanged: (type) => setState(() => _setChartCase(type: type)),
          ),
        ],
        if (_mode == StressMode.plugins) ...[
          gap,
          SegmentChoice<StressPluginScene>(
            label: 'scene',
            items: [
              for (final scene in StressPluginScene.values)
                (
                  key: 'stress.plugins.scene.${scene.name}',
                  text: scene.name,
                  icon: _sceneIcons[scene],
                  tooltip: scene.benchId,
                  value: scene,
                ),
            ],
            value: _pluginCase.scene,
            onChanged: (scene) => setState(
              () => _setPluginCase(_pluginCase.copyWith(scene: scene)),
            ),
          ),
        ],
        gap,
        SegmentChoice<int>(
          label: 'N',
          items: [
            for (final v in _countsOf(_mode))
              (
                key: 'stress.n.$v',
                text: count(v),
                icon: null,
                tooltip: '$v',
                value: v,
              ),
          ],
          value: _n,
          onChanged: (v) => setState(() => _setScene(n: v)),
        ),
        gap,
        SegmentChoice<int>(
          label: 'M',
          items: [
            for (final v in stressLabelCounts)
              (
                key: 'stress.m.$v',
                text: count(v),
                icon: null,
                tooltip: '$v labels',
                value: v,
              ),
          ],
          value: _m,
          onChanged: (v) => setState(() => _m = v),
        ),
        if (_mode.runsChart) ...[
          gap,
          SegmentChoice<StressChartCall>(
            label: 'call',
            items: [
              for (final call in stressCallsOf(_mode, _pluginCase.scene))
                (
                  key: 'stress.chart.call.${call.name}',
                  text: callText[call]!,
                  icon: null,
                  tooltip: call.name,
                  value: call,
                ),
            ],
            value: _call,
            onChanged: (call) => setState(() => _setChartCase(call: call)),
          ),
        ],
        if (_mode == StressMode.plugins && _pluginCase.scene.tooltip) ...[
          gap,
          SegmentChoice<int>(
            label: 'sets',
            items: [
              for (final datasets in stressPluginDatasets)
                (
                  key: 'stress.plugins.datasets.$datasets',
                  text: '$datasets',
                  icon: null,
                  tooltip: '$datasets datasets',
                  value: datasets,
                ),
            ],
            value: _pluginCase.datasets,
            onChanged: (datasets) => setState(
              () => _setPluginCase(_pluginCase.copyWith(datasets: datasets)),
            ),
          ),
        ],
        if (_mode == StressMode.axes) ...[
          gap,
          SegmentChoice<StressAxisType>(
            label: 'x',
            items: [
              for (final type in StressAxisType.values)
                (
                  key: 'stress.axes.scale.${type.name}',
                  text: axisText[type]!,
                  icon: null,
                  tooltip: type.name,
                  value: type,
                ),
            ],
            value: _scale,
            onChanged: (type) => setState(() => _setAxesCase(scale: type)),
          ),
          gap,
          SegmentChoice<StressAxisType>(
            label: 'y',
            items: [
              for (final type in stressAxesValueTypes)
                (
                  key: 'stress.axes.yScale.${type.name}',
                  text: axisText[type]!,
                  icon: null,
                  tooltip: type.name,
                  value: type,
                ),
            ],
            value: _yScale,
            onChanged: (type) => setState(() => _setAxesCase(yScale: type)),
          ),
        ],
      ],
    );
  }

  /// The icon of each chart type on the line `type` of the mode
  /// [StressMode.chart].
  static const Map<StressChartType, IconData> _typeIcons = {
    StressChartType.line: Icons.show_chart,
    StressChartType.scatter: Icons.scatter_plot,
    StressChartType.bar: Icons.bar_chart,
    StressChartType.bubble: Icons.bubble_chart,
    StressChartType.doughnut: Icons.donut_large,
    StressChartType.pie: Icons.pie_chart,
    StressChartType.polarArea: Icons.track_changes,
    StressChartType.radar: Icons.radar,
  };

  /// The icon of each scene on the line `scene` of the mode
  /// [StressMode.plugins].
  static const Map<StressPluginScene, IconData> _sceneIcons = {
    StressPluginScene.legend: Icons.legend_toggle,
    StressPluginScene.title: Icons.title,
    StressPluginScene.hover: Icons.ads_click,
    StressPluginScene.still: Icons.comment,
    StressPluginScene.fade: Icons.gradient,
    StressPluginScene.gaps: Icons.area_chart,
    StressPluginScene.stack: Icons.stacked_line_chart,
    StressPluginScene.radar: Icons.radar,
  };

  /// The controller class of each chart type, for the card.
  static const Map<StressChartType, String> _controllerNames = {
    StressChartType.line: 'LineController',
    StressChartType.scatter: 'ScatterController',
    StressChartType.bar: 'BarController',
    StressChartType.bubble: 'BubbleController',
    StressChartType.doughnut: 'DoughnutController',
    StressChartType.pie: 'PieController',
    StressChartType.polarArea: 'PolarAreaController',
    StressChartType.radar: 'RadarController',
  };

  /// The data element class of each chart type, for the card.
  static const Map<StressChartType, String> _elementNames = {
    StressChartType.line: 'PointElement',
    StressChartType.scatter: 'PointElement',
    StressChartType.bar: 'BarElement',
    StressChartType.bubble: 'PointElement',
    StressChartType.doughnut: 'ArcElement',
    StressChartType.pie: 'ArcElement',
    StressChartType.polarArea: 'ArcElement',
    StressChartType.radar: 'PointElement',
  };

  /// The on/off options of the mode, as one segmented button of icons.
  Widget _optionToggles(bool layers) {
    return SegmentToggles(
      items: [
        if (layers) ...[
          (
            key: 'stress.layer.points',
            icon: Icons.grain,
            tooltip: 'points',
            value: _points,
            onChanged: (v) => setState(() => _points = v),
          ),
          (
            key: 'stress.layer.line',
            icon: Icons.timeline,
            tooltip: 'polyline',
            value: _line,
            onChanged: (v) => setState(() => _line = v),
          ),
        ],
        (
          key: 'stress.spin',
          icon: Icons.rotate_right,
          tooltip: 'spin labels',
          value: _spin,
          onChanged: (v) => setState(() => _spin = v),
        ),
        if (_mode == StressMode.chart) ...[
          if (_type.points)
            (
              key: 'stress.chart.showLine',
              icon: Icons.timeline,
              tooltip: 'showLine',
              value: _showLine,
              onChanged: (v) => setState(() => _setChartCase(showLine: v)),
            ),
          (
            key: 'stress.chart.scriptable',
            icon: Icons.functions,
            tooltip: 'scriptable backgroundColor',
            value: _scriptable,
            onChanged: (v) => setState(() => _setChartCase(scriptable: v)),
          ),
        ],
        if (_mode == StressMode.axes)
          (
            key: 'stress.axes.autoSkip',
            icon: Icons.skip_next,
            tooltip: 'ticks.autoSkip',
            value: _autoSkip,
            onChanged: (v) => setState(() => _setAxesCase(autoSkip: v)),
          ),
        if (_mode == StressMode.plugins &&
            _pluginCase.scene == StressPluginScene.legend)
          (
            key: 'stress.plugins.legend',
            icon: Icons.list,
            tooltip: 'legend (off: the base of the legend and the title)',
            value: _pluginCase.legend,
            onChanged: (v) => setState(
              () => _setPluginCase(_pluginCase.copyWith(legend: v)),
            ),
          ),
        if (_mode == StressMode.plugins &&
            (_pluginCase.scene == StressPluginScene.hover ||
                _pluginCase.scene == StressPluginScene.still))
          (
            key: 'stress.plugins.tooltip',
            icon: Icons.chat_bubble_outline,
            tooltip: 'tooltip plugin (off: the base)',
            value: _pluginCase.tooltip,
            onChanged: (v) => setState(
              () => _setPluginCase(_pluginCase.copyWith(tooltip: v)),
            ),
          ),
      ],
    );
  }

  /// The call of case (b), for the card.
  static const String _updateCall = "chart.update('none')";

  /// The call of each frame of the mode [StressMode.plugins], for the card.
  String get _pluginCallText => switch (_call) {
    StressChartCall.draw => 'core.controller: chart.draw()',
    StressChartCall.update => 'core.controller: $_updateCall',
    _ when _pluginCase.scene == StressPluginScene.fade =>
      'chart event handler: mousemove and mouseout in turn, each '
          '$chartBenchFadeFrames frames · core.animator: the tick of the fade '
          'and chart.draw()',
    _ => 'chart event handler: mousemove over the next point',
  };

  /// The calls of each frame, for the card.
  String get _source => switch (_mode) {
    StressMode.primitives =>
      'helpers.extras: requestAnimFrame each frame · helpers.canvas: '
          'drawPoint × N · lineTo × N · renderText × M (rotated)',
    StressMode.elements =>
      'helpers.extras: requestAnimFrame each frame · elements: '
          'PointElement.draw × N · LineElement.draw (N points) · '
          'helpers.canvas: renderText × M (rotated)',
    StressMode.bars =>
      'helpers.extras: requestAnimFrame each frame · elements: '
          'BarElement.draw × N · helpers.canvas: renderText × M (rotated)',
    StressMode.arcs =>
      'helpers.extras: requestAnimFrame each frame · elements: '
          'ArcElement.draw × N · helpers.canvas: renderText × M (rotated)',
    StressMode.chart =>
      'helpers.extras: requestAnimFrame each frame · core.controller: '
          '${switch (_call) {
            StressChartCall.draw => 'chart.draw()',
            StressChartCall.update => _updateCall,
            StressChartCall.animate => 'core.animator: the tick of N looping '
                'animations and chart.draw()',
            // The mode chart has no call frame (stressCallsOf).
            StressChartCall.frame => 'chart.draw()',
          }} · '
          'controllers: ${_controllerNames[_type]} · '
          '${_elementNames[_type]}.draw × N · '
          'plugin afterDraw: renderText × M (rotated)',
    StressMode.axes =>
      'helpers.extras: requestAnimFrame each frame · core.controller: '
          '${_call == StressChartCall.update ? _updateCall : 'chart.draw()'} · '
          'scales: ${_scale.name} x, ${_yScale.name} y · '
          'LineController: getPixelForValue × 2N · '
          'PointElement.draw × N · plugin afterDraw: renderText × M (rotated)',
    StressMode.plugins =>
      'helpers.extras: requestAnimFrame each frame · $_pluginCallText · '
          'benchmark case ${_pluginCase.scene.benchId} '
          '${_pluginCase.benchKeys} · plugin afterDraw: renderText × M '
          '(rotated)',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String ms(double v) => v.toStringAsFixed(2);
    return DemoPageBody(
      children: [
        DemoCard(
          title: 'Stress test',
          source: _source,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExcludeSemantics(
                excluding: widget.chartSemanticsOnly,
                child: _toolbar(theme),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final height = (constraints.maxWidth * 0.6)
                      .clamp(240, 520)
                      .toDouble();
                  if (_mode == StressMode.plugins) {
                    // A new N or plugin case gives a new host, thus a new
                    // chart.
                    final hostKey = (_n, _pluginCase);
                    return KeyedSubtree(
                      key: ValueKey(hostKey),
                      child: _chartHost(
                        hostKey: hostKey,
                        key: 'stress.plugins.host',
                        height: height,
                        config: _pluginChartConfig,
                        onChart: (chart) {
                          _stressChart = chart;
                          _animating = false;
                          _preparePluginChart(chart);
                          _chartReady();
                        },
                      ),
                    );
                  }
                  if (_mode.runsChart) {
                    final axes = _mode == StressMode.axes;
                    // A new N, chart type, showLine, backgroundColor form or
                    // a change to or from the call animate (mode chart), or
                    // a new N, scale type or autoSkip (mode axes) gives a new
                    // host, thus a new chart. A ChartCanvas makes its chart
                    // only once.
                    final Object hostKey = axes
                        ? (_n, _scale, _yScale, _autoSkip)
                        : (
                            _n,
                            _type,
                            _scriptable,
                            _effectiveShowLine,
                            _call == StressChartCall.animate,
                          );
                    return KeyedSubtree(
                      key: ValueKey(hostKey),
                      child: _chartHost(
                        hostKey: hostKey,
                        key: axes ? 'stress.axes.host' : 'stress.chart.host',
                        height: height,
                        config: axes ? _axesChartConfig : _chartConfig,
                        onChart: (chart) {
                          _stressChart = chart;
                          _animating = false;
                          _chartReady();
                        },
                      ),
                    );
                  }
                  return DemoCanvas(
                    key: const ValueKey('stress.host'),
                    height: height,
                    draw: _draw,
                    onChart: (chart) {
                      _chart = chart;
                      _chartReady();
                    },
                    onTickerModeChanged: _onTickerModeChanged,
                  );
                },
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<StressStats>(
                valueListenable: _stats,
                builder: (context, stats, _) => ExcludeSemantics(
                  excluding: widget.chartSemanticsOnly,
                  child: ReadoutTable(
                    key: const ValueKey('stress.stats'),
                    rows: [
                      ('FPS', stats.fps.toStringAsFixed(1)),
                      ('frames', '${stats.frames}'),
                      ('draw', '${ms(stats.drawMs)} ms'),
                      if (stats.mode == StressMode.chart) ...[
                        ('update', '${ms(stats.updateMs)} ms'),
                        ('animator', '${ms(stats.animatorMs)} ms'),
                        ('elements', '${ms(stats.elementsMs)} ms'),
                        ('layout', '${ms(stats.layoutMs)} ms'),
                        ('datasets update', '${ms(stats.datasetsUpdateMs)} ms'),
                        ('datasets draw', '${ms(stats.datasetsDrawMs)} ms'),
                        ('sharing', '${stats.sharing}'),
                      ],
                      if (stats.mode == StressMode.axes) ...[
                        ('update', '${ms(stats.updateMs)} ms'),
                        ('elements', '${ms(stats.elementsMs)} ms'),
                        ('layout', '${ms(stats.layoutMs)} ms'),
                        ('datasets update', '${ms(stats.datasetsUpdateMs)} ms'),
                        ('datasets draw', '${ms(stats.datasetsDrawMs)} ms'),
                        ('x ticks', '${stats.ticks}'),
                        ('rotation', stats.rotation.toStringAsFixed(1)),
                      ],
                      if (stats.mode == StressMode.plugins) ...[
                        ('update', '${ms(stats.updateMs)} ms'),
                        ('animator', '${ms(stats.animatorMs)} ms'),
                        ('elements', '${ms(stats.elementsMs)} ms'),
                        ('layout', '${ms(stats.layoutMs)} ms'),
                        ('datasets update', '${ms(stats.datasetsUpdateMs)} ms'),
                        ('datasets draw', '${ms(stats.datasetsDrawMs)} ms'),
                        ('tooltip draw', '${ms(stats.tooltipDrawMs)} ms'),
                      ],
                      (
                        'build avg/max',
                        stats.timings == 0
                            ? 'n/a'
                            : '${ms(stats.buildMs)} / '
                                  '${ms(stats.buildMaxMs)} ms',
                      ),
                      (
                        'raster avg/max',
                        stats.timings == 0
                            ? 'n/a'
                            : '${ms(stats.rasterMs)} / '
                                  '${ms(stats.rasterMaxMs)} ms',
                      ),
                      ('timings', '${stats.timings} frames'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'draw: the Dart time of the draw calls of one frame '
                '(recording into a ui.Picture). In the element modes, it '
                'also has the writes of the element properties. update: the '
                'time of chart.update() without its draw. animator: the tick '
                'of the animations before their draw (call animate, scene '
                'fade). '
                'elements, layout, datasets update and datasets draw (modes '
                'chart, axes and plugins): the parts between the plugin '
                'hooks, in the draw and update calls of the frames only (mode '
                'plugins: also in the animator frames). tooltip draw: '
                'beforeTooltipDraw to afterTooltipDraw. elements is the '
                'parse and the first getMaxOverflow. Draw minus datasets '
                'draw is the draw of the scales, the labels and the title. '
                'sharing: enableOptionSharing of the controller. build and '
                'raster: FrameTiming of the last 120 '
                'frames. Profile on a device with flutter run --profile.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The draw meter of a stress chart: the time of each `draw()`, also the
/// draw inside `update()`, and the animator tick before a draw.
abstract interface class _StressMeter {
  /// The microseconds of the draws since the last reset.
  abstract int drawMicros;

  /// The microseconds of the animator ticks since the last reset.
  abstract int animatorMicros;

  /// Marks the time in a frame callback before the animator callback.
  void markTick();
}

/// The clock of the marks of the meters.
final Stopwatch _meterWatch = Stopwatch()..start();

/// The time stamp of the current frame, or Dart `null` outside the frame
/// callbacks.
Duration? get _meterFrame {
  final scheduler = SchedulerBinding.instance;
  return scheduler.schedulerPhase == SchedulerPhase.transientCallbacks
      ? scheduler.currentFrameTimeStamp
      : null;
}

/// The mark of [markTick] and the animator time of a meter.
mixin _TickMark {
  /// The microseconds of the animator ticks since the last reset.
  int animatorMicros = 0;

  /// The time of the mark, or Dart `null` for no mark.
  int? _markMicros;

  /// The time stamp of the frame of the mark.
  Duration? _markFrame;

  /// Marks the time in a frame callback before the animator callback.
  void markTick() {
    _markFrame = _meterFrame;
    _markMicros = _markFrame == null ? null : _meterWatch.elapsedMicroseconds;
  }

  /// Adds the time from the mark to now to [animatorMicros] when the mark is
  /// of the current frame, at the start of a draw.
  void _takeMark() {
    final mark = _markMicros;
    if (mark != null && _meterFrame == _markFrame) {
      animatorMicros += _meterWatch.elapsedMicroseconds - mark;
    }
    _markMicros = null;
  }
}

/// The `Chart` of the host [StressHost.canvas]: it adds the time of each
/// `draw()` to [drawMicros], also the draw inside `update()`.
///
/// For [StressChartCall.animate], it also adds the time from the mark of
/// [markTick] to the start of a draw in the same frame to [animatorMicros]:
/// the tick of the animator before its draw.
final class _StressChart extends Chart with _TickMark implements _StressMeter {
  _StressChart(super.item, [super.userConfig]);

  @override
  int drawMicros = 0;

  @override
  void draw() {
    _takeMark();
    final watch = Stopwatch()..start();
    super.draw();
    drawMicros += watch.elapsedMicroseconds;
  }
}

/// The draw meter of the chart of a `ChartView` ([StressHost.view]): the
/// inline plugin [first] marks the start of each draw in `beforeDraw`, and
/// the inline plugin [last] adds the time to its end in `afterDraw`. The
/// host puts [first] before the inline plugins of the config and [last]
/// after them. The `clear()` of `draw()` and the `beforeDraw` hooks of the
/// registered plugins come before the mark (core.controller.js:715-735).
final class _PluginMeter with _TickMark implements _StressMeter {
  @override
  int drawMicros = 0;

  /// The start of the current draw, or Dart `null` outside a draw.
  int? _drawStart;

  /// The first inline plugin of the chart.
  late final Map<String, Object?> first = <String, Object?>{
    'id': 'stressDrawStart',
    'beforeDraw': (Object? chart, Object? args, Object? options) {
      _takeMark();
      _drawStart = _meterWatch.elapsedMicroseconds;
    },
  };

  /// The last inline plugin of the chart.
  late final Map<String, Object?> last = <String, Object?>{
    'id': 'stressDrawEnd',
    'afterDraw': (Object? chart, Object? args, Object? options) {
      final start = _drawStart;
      if (start != null) {
        drawMicros += _meterWatch.elapsedMicroseconds - start;
      }
      _drawStart = null;
    },
  };
}
