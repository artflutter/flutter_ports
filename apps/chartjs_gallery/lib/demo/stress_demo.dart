// The package exports nothing from lib/src yet; the public API comes in
// phase 9. The demo imports the ported files directly.
// ignore_for_file: implementation_imports

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:chartjs_gallery/demo/canvas_demo.dart' show labelColor;
import 'package:chartjs_gallery/demo/chart_canvas.dart';
import 'package:chartjs_gallery/demo/demo_chart.dart';
import 'package:chartjs_gallery/demo/demo_common.dart';
import 'package:chartjs_gallery/demo/demo_controls.dart';
import 'package:chartjs_gallery/demo/stress_axes.dart';
import 'package:chartjs_gallery/demo/stress_chart_config.dart';
import 'package:chartjs_gallery/demo/stress_point_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_chartjs/src/canvas/canvas.dart';
import 'package:flutter_chartjs/src/canvas/canvas_ui.dart' show UiCanvasElement;
import 'package:flutter_chartjs/src/core/core.animator.dart' show animator;
import 'package:flutter_chartjs/src/core/core.controller.dart';
// The typed options of Chart.js ADR 0018. The prefix keeps them apart from
// the PointOptions of demo_chart.dart, which the primitives mode uses.
import 'package:flutter_chartjs/src/elements/element_options.dart'
    as element_options;
import 'package:flutter_chartjs/src/elements/index.dart';
import 'package:flutter_chartjs/src/helpers/index.dart'
    show ParsedFont, drawPoint, renderText, requestAnimFrame, toFont;
import 'package:flutter_chartjs/src/types/basic.dart';
import 'package:flutter_chartjs/src/types/geometric.dart' show ChartArea;
import 'package:flutter_chartjs/src/types/index.dart' as types;

export 'package:chartjs_gallery/demo/stress_chart_config.dart'
    show stressAnimateMs;

/// The point counts of the stress tab: the N choices of the modes
/// [StressMode.primitives] and [StressMode.elements].
const List<int> stressPointCounts = [1000, 5000, 20000];

/// The label counts of the stress tab.
const List<int> stressLabelCounts = [0, 50, 200];

/// The scenes of the stress tab.
///
/// Each mode draws N items and M labels in each frame. The chips
/// `stress.mode.<name>` select the mode.
enum StressMode {
  /// N points with `drawPoint` and a polyline through N points, with the
  /// canvas calls of `helpers.canvas`. This is the scene of
  /// `packages/flutter_chartjs/doc/performance.md`.
  primitives(stressPointCounts, 'points'),

  /// The scene of [primitives], drawn by the phase 4 elements: N
  /// `PointElement` objects and one `LineElement` through N point elements.
  elements(stressPointCounts, 'point elements'),

  /// N `BarElement` objects in a grid of bar columns.
  bars([1000, 5000, 20000], 'bars'),

  /// N `ArcElement` objects as the slices of doughnut rings.
  arcs([100, 1000, 5000], 'arcs'),

  /// N points of a real `Chart` of phase 5 (Chart.js ADR 0021, section 8):
  /// `core.controller`, `core.config`, the producers of `DatasetController`
  /// and `PointElement`, with the gallery controller
  /// `StressPointController`. [StressChartCall] selects the call of each
  /// frame.
  chart(stressPointCounts, 'chart points'),

  /// The chart of [chart] on real scales of phase 6 (`lib/demo/
  /// stress_axes.dart`): an x axis of a [StressAxisType], a linear or
  /// logarithmic y axis, and the option `ticks.autoSkip` of the x axis.
  /// The calls are [StressChartCall.draw] and [StressChartCall.update].
  axes(stressPointCounts, 'chart points on scales');

  const StressMode(this.counts, this.items);

  /// The N choices of the mode, in ascending order.
  final List<int> counts;

  /// The name of the N items in the title of the chart.
  final String items;

  /// Whether the mode runs a real `Chart` on a chart host of its own:
  /// [chart] and [axes].
  bool get runsChart => this == chart || this == axes;
}

/// The call of each frame in the modes [StressMode.chart] and
/// [StressMode.axes] (Chart.js ADR 0021, section 8). [draw] and [update] run
/// with `animation: false`. The mode [StressMode.axes] has no [animate].
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
}

/// The figures of the stress tab, published twice a second and when the
/// loop stops: the mode, the item count N (`points`), the label count M,
/// and the frame figures. `updateMs` is the time of `chart.update()` without
/// its draw, in the modes [StressMode.chart] and [StressMode.axes].
/// `animatorMs` is the time of the animator tick without its draw, for
/// [StressChartCall.animate]. Both are 0 in the other modes.
///
/// The mode [StressMode.axes] also gives the parts of `StressAxesTiming`
/// (`layoutMs`, `datasetsUpdateMs` and `datasetsDrawMs`), and the tick count
/// (`ticks`, after the auto skip) and the `labelRotation` (`rotation`) of
/// the x axis. They are 0 in the other modes.
typedef StressStats = ({
  StressMode mode,
  int points,
  int labels,
  int frames,
  double fps,
  double drawMs,
  double updateMs,
  double animatorMs,
  double layoutMs,
  double datasetsUpdateMs,
  double datasetsDrawMs,
  int ticks,
  double rotation,
  double buildMs,
  double buildMaxMs,
  double rasterMs,
  double rasterMaxMs,
  int timings,
});

const StressStats _noStats = (
  mode: StressMode.primitives,
  points: 0,
  labels: 0,
  frames: 0,
  fps: 0,
  drawMs: 0,
  updateMs: 0,
  animatorMs: 0,
  layoutMs: 0,
  datasetsUpdateMs: 0,
  datasetsDrawMs: 0,
  ticks: 0,
  rotation: 0,
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
/// - [StressMode.chart]: a real `Chart` of N points. Each frame calls
///   `chart.draw()`, or writes the moving positions into the data objects
///   and calls `chart.update('none')` ([StressChartCall]). An inline plugin
///   draws the labels and the title in its `afterDraw` hook.
/// - [StressMode.axes]: the chart of [StressMode.chart] on real scales. An
///   update gives the scales new data limits, ticks, label sizes and a
///   rotation, and maps each point with `getPixelForValue`.
///
/// The element modes make their elements once for each mode and N. Each
/// frame writes the properties that move with the typed setters, and then
/// calls `draw` of each element. The mode [StressMode.chart] makes a new
/// chart for each N, `enableOptionSharing` value and `backgroundColor`
/// form. The mode [StressMode.axes] makes a new chart for each N, scale
/// type and `autoSkip` value.
///
/// The labels have one fixed angle of -45 degrees, as the tick labels of a
/// chart have; the `spin labels` switch gives each label a new angle in
/// every frame.
/// The readout shows the frames per second, the time of the draw calls,
/// and the build and raster times of `SchedulerBinding.addTimingsCallback`.
///
/// Every control has a `ValueKey` (`stress.mode.bars`, `stress.n.5000`,
/// `stress.m.200`, `stress.start`, `stress.chart.call.update`,
/// `stress.chart.sharing`, `stress.axes.scale.time`, …) so that automation
/// can drive it.
class StressDemo extends StatefulWidget {
  /// Creates the stress tab.
  ///
  /// [initialMode], [initialN] and [initialM] set the first mode, item count
  /// and label count. [initialSpin] and [initialLine] set the first state of
  /// two layer switches. [initialCall], [initialSharing] and
  /// [initialScriptable] set the case of the mode [StressMode.chart].
  /// [initialCall], [initialScale], [initialYScale] and [initialAutoSkip]
  /// set the case of the mode [StressMode.axes]. The mode [StressMode.axes]
  /// takes [StressChartCall.draw] for [StressChartCall.animate].
  /// [autoStart] starts the loop when the chart exists. [onStats] receives
  /// each published [StressStats]. They let a profiling entry point
  /// (`lib/main_stress.dart`) or a test drive the tab.
  const StressDemo({
    this.initialMode = StressMode.primitives,
    this.initialN,
    this.initialM,
    this.initialSpin = false,
    this.initialLine = true,
    this.initialCall = StressChartCall.draw,
    this.initialSharing = true,
    this.initialScriptable = false,
    this.initialScale = StressAxisType.linear,
    this.initialYScale = StressAxisType.linear,
    this.initialAutoSkip = true,
    this.autoStart = false,
    this.onStats,
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

  /// The first `enableOptionSharing` of the chart points: true as in a line
  /// chart, false as in a scatter chart.
  final bool initialSharing;

  /// Whether the chart points start with a scriptable `backgroundColor`.
  final bool initialScriptable;

  /// The first scale type of the x axis in the mode [StressMode.axes].
  final StressAxisType initialScale;

  /// The first scale type of the y axis in the mode [StressMode.axes]: one
  /// of [stressAxesValueTypes].
  final StressAxisType initialYScale;

  /// The first option `ticks.autoSkip` of the x axis in the mode
  /// [StressMode.axes].
  final bool initialAutoSkip;

  /// Whether the loop starts as soon as the chart exists.
  final bool autoStart;

  /// Receives the figures each time the readout updates.
  final ValueChanged<StressStats>? onStats;

  @override
  State<StressDemo> createState() => StressDemoState();
}

/// The state of a [StressDemo]: the loop, the scene and the figures.
class StressDemoState extends State<StressDemo> {
  static final int _maxPoints = stressPointCounts.reduce(math.max);

  late StressMode _mode = widget.initialMode;
  late int _n = widget.initialN ?? _mode.counts.first;
  late int _m = widget.initialM ?? stressLabelCounts[1];
  bool _points = true;
  late bool _line = widget.initialLine;
  late bool _spin = widget.initialSpin;
  // The mode axes has no call animate: it takes the call draw, as _setScene
  // does. Else the first frame waits for an animation that does not start.
  late StressChartCall _call =
      _mode == StressMode.axes && widget.initialCall == StressChartCall.animate
      ? StressChartCall.draw
      : widget.initialCall;
  late bool _sharing = widget.initialSharing;
  late bool _scriptable = widget.initialScriptable;
  late StressAxisType _scale = widget.initialScale;
  late StressAxisType _yScale = widget.initialYScale;
  late bool _autoSkip = widget.initialAutoSkip;
  bool _running = false;
  bool _muted = false;
  bool _autoStarted = false;

  DemoChart? _chart;
  int? _frameId;

  // The modes [StressMode.chart] and [StressMode.axes]: the chart and its
  // data objects `{x, y}`.
  _StressChart? _stressChart;
  List<AnyObject> _chartData = const [];

  // The mode [StressMode.axes]: the data and the timing plugin.
  StressAxesScene? _axesScene;
  final StressAxesTiming _axesTiming = StressAxesTiming();

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
  // The parts of [StressAxesTiming] of the frame calls of the window.
  int _windowLayoutTicks = 0;
  int _windowDatasetsUpdateTicks = 0;
  int _windowDatasetsDrawTicks = 0;
  Duration _windowStart = Duration.zero;
  double _fps = 0;
  double _drawMs = 0;
  double _updateMs = 0;
  double _animatorMs = 0;
  double _layoutMs = 0;
  double _datasetsUpdateMs = 0;
  double _datasetsDrawMs = 0;
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
  List<types.VisualElement> get debugElements => [
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

  /// The data objects `{x, y}` of the chart of the modes [StressMode.chart]
  /// and [StressMode.axes].
  @visibleForTesting
  List<AnyObject> get debugChartData => _chartData;

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
      _windowLayoutTicks = 0;
      _windowDatasetsUpdateTicks = 0;
      _windowDatasetsDrawTicks = 0;
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

  /// Sets the mode and N. A change of the mode keeps N, but not above the
  /// largest count of the new mode. A change of either makes the elements
  /// again. In the modes [StressMode.chart] and [StressMode.axes], a change
  /// of N makes a new chart. The mode [StressMode.axes] changes the call
  /// [StressChartCall.animate] to [StressChartCall.draw].
  void _setScene({StressMode? mode, int? n}) {
    final newMode = mode ?? _mode;
    final newN = n ?? (mode == null ? _n : math.min(_n, newMode.counts.last));
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
    if (newMode == StressMode.axes && _call == StressChartCall.animate) {
      _call = StressChartCall.draw;
    }
    _mode = newMode;
    _n = newN;
    _buildScene();
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

  /// Sets the case of the mode [StressMode.chart]. A change of the sharing,
  /// of the `backgroundColor` form, or to or from
  /// [StressChartCall.animate] (another `animation` option) makes a new
  /// chart.
  void _setChartCase({StressChartCall? call, bool? sharing, bool? scriptable}) {
    final newCall = call ?? _call;
    final animated = newCall == StressChartCall.animate;
    final animatedChanged = animated != (_call == StressChartCall.animate);
    _call = newCall;
    final newSharing = sharing ?? _sharing;
    final newScriptable = scriptable ?? _scriptable;
    if (newSharing == _sharing &&
        newScriptable == _scriptable &&
        !animatedChanged) {
      return;
    }
    _sharing = newSharing;
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
      case StressMode.chart || StressMode.axes:
        // The chart makes its point elements.
        return;
    }
    _sceneBuilds++;
  }

  /// `new Chart(canvas, config)` of the mode [StressMode.chart]: one dataset
  /// of N points of `StressPointController` at the positions of the moving
  /// points, with `animation: false`, or the looping animation of
  /// [StressChartCall.animate]. `stressChartConfig` gives the config, which
  /// the chart benchmark (lib/bench/chart_bench.dart) also uses.
  ///
  /// The inline plugin `stressLabels` draws the M labels and the title in
  /// its `afterDraw` hook, as the other modes draw them after their items.
  Chart _createChart(UiCanvasElement canvas) {
    registerGalleryComponents();
    final data = _chartData = _field.data(_n);
    return _StressChart(
      canvas,
      stressChartConfig(
        data: data,
        sharing: _sharing,
        scriptable: _scriptable,
        animate: _call == StressChartCall.animate,
        plugins: [_labelsPlugin],
      ),
    );
  }

  /// `new Chart(canvas, config)` of the mode [StressMode.axes]: the chart of
  /// [_createChart] with the scales of `stressAxesConfig`, and the timing
  /// plugin of [StressAxesTiming].
  Chart _createAxesChart(UiCanvasElement canvas) {
    registerGalleryComponents();
    final scene = _axesScene = StressAxesScene(
      _n,
      x: _scale,
      y: _yScale,
      positions: _field,
    );
    _chartData = scene.data;
    return _StressChart(
      canvas,
      stressAxesConfig(
        scene: scene,
        autoSkip: _autoSkip,
        plugins: [_labelsPlugin, _axesTiming.plugin],
      ),
    );
  }

  /// The inline plugin `stressLabels`: the M labels and the title, after the
  /// draw of the chart.
  AnyObject get _labelsPlugin => <String, Object?>{
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
      // The parts of the mode axes: the hooks of the frame calls of the
      // window ([_chartFrame]).
      double perFrame(int ticks) =>
          ticks / StressAxesTiming.ticksPerMs / _windowFrames;
      _layoutMs = perFrame(_windowLayoutTicks);
      _datasetsUpdateMs = perFrame(_windowDatasetsUpdateTicks);
      _datasetsDrawMs = perFrame(_windowDatasetsDrawTicks);
      _windowStart = now;
      _windowFrames = 0;
      _windowDrawMicros = 0;
      _windowUpdateMicros = 0;
      _windowAnimatorMicros = 0;
      _windowLayoutTicks = 0;
      _windowDatasetsUpdateTicks = 0;
      _windowDatasetsDrawTicks = 0;
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
  _StressChart? _listenedChart;

  /// One frame of the modes [StressMode.chart] and [StressMode.axes]: case
  /// (a) or case (b) of Chart.js ADR 0021, section 8.
  ///
  /// The draw time is the time of `chart.draw()`, also inside
  /// `chart.update()`. The update time is the time of `chart.update()`
  /// without its draw. The writes of the positions into the data objects
  /// are in neither time. In the mode [StressMode.axes], the plugin of
  /// [StressAxesTiming] times the parts. The parts count only the hooks of
  /// this call, as the draw time does: not the update at the construction of
  /// a chart, and not the update of a resize of its host.
  void _chartFrame(_StressChart chart) {
    if (_call == StressChartCall.animate) {
      _animateFrame(chart);
      return;
    }
    if (_call == StressChartCall.update) {
      final axesScene = _mode == StressMode.axes ? _axesScene : null;
      if (axesScene != null) {
        axesScene.write(_field);
      } else {
        _field.write(_chartData);
      }
    }
    chart.drawMicros = 0;
    final timing = _axesTiming..reset();
    final watch = Stopwatch()..start();
    switch (_call) {
      case StressChartCall.draw:
        chart.draw();
      case StressChartCall.update:
        chart.update('none');
      case StressChartCall.animate:
        // [_animateFrame] handles this case.
        break;
    }
    final total = watch.elapsedMicroseconds;
    _windowDrawMicros += chart.drawMicros;
    _windowUpdateMicros += total - chart.drawMicros;
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
  void _animateFrame(_StressChart chart) {
    if (!_animating) {
      _animating = true;
      _field.write(_chartData);
      if (!identical(_listenedChart, chart)) {
        _listenedChart = chart;
        animator.listen(chart, 'progress', (_) {
          if (mounted && _running && identical(_stressChart, chart)) {
            _scheduleFrame();
          }
        });
      }
      chart.drawMicros = 0;
      final watch = Stopwatch()..start();
      chart.update();
      _windowUpdateMicros += watch.elapsedMicroseconds - chart.drawMicros;
    }
    _windowDrawMicros += chart.drawMicros;
    _windowAnimatorMicros += chart.animatorMicros;
    chart
      ..drawMicros = 0
      ..animatorMicros = 0
      ..markTick();
  }

  void _step(double dt) {
    _t += dt;
    // The bars and the arcs move with the time only.
    if (_mode == StressMode.bars || _mode == StressMode.arcs) return;
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
    _stats.value = (
      mode: _mode,
      points: _n,
      labels: _m,
      frames: _frames,
      fps: _fps,
      drawMs: _drawMs,
      updateMs: _updateMs,
      animatorMs: _animatorMs,
      layoutMs: _layoutMs,
      datasetsUpdateMs: _datasetsUpdateMs,
      datasetsDrawMs: _datasetsDrawMs,
      ticks: axes?.ticks ?? 0,
      rotation: axes?.rotation ?? 0,
      buildMs: avg(build),
      buildMaxMs: max(build),
      rasterMs: avg(raster),
      rasterMaxMs: max(raster),
      timings: _timings.length,
    );
    widget.onStats?.call(_stats.value);
  }

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
      case StressMode.chart || StressMode.axes:
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
    };
    const callText = {
      StressChartCall.draw: 'draw',
      StressChartCall.update: 'upd',
      StressChartCall.animate: 'anim',
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
                tooltip: mode.name,
                value: mode,
              ),
          ],
          value: _mode,
          onChanged: (mode) => setState(() => _setScene(mode: mode)),
        ),
        gap,
        SegmentChoice<int>(
          label: 'N',
          items: [
            for (final v in _mode.counts)
              (key: 'stress.n.$v', text: count(v), tooltip: '$v', value: v),
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
              for (final call in StressChartCall.values)
                if (_mode != StressMode.axes || call != StressChartCall.animate)
                  (
                    key: 'stress.chart.call.${call.name}',
                    text: callText[call]!,
                    tooltip: call.name,
                    value: call,
                  ),
            ],
            value: _call,
            onChanged: (call) => setState(() => _setChartCase(call: call)),
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
          (
            key: 'stress.chart.sharing',
            icon: Icons.share,
            tooltip: 'enableOptionSharing',
            value: _sharing,
            onChanged: (v) => setState(() => _setChartCase(sharing: v)),
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
      ],
    );
  }

  /// The call of case (b), for the card.
  static const String _updateCall = "chart.update('none')";

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
          }} · '
          'StressPointController · PointElement.draw × N · '
          'plugin afterDraw: renderText × M (rotated)',
    StressMode.axes =>
      'helpers.extras: requestAnimFrame each frame · core.controller: '
          '${_call == StressChartCall.update ? _updateCall : 'chart.draw()'} · '
          'scales: ${_scale.name} x, ${_yScale.name} y · '
          'StressPointController: getPixelForValue × 2N · '
          'PointElement.draw × N · plugin afterDraw: renderText × M (rotated)',
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
              _toolbar(theme),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final height = (constraints.maxWidth * 0.6)
                      .clamp(240, 520)
                      .toDouble();
                  if (_mode.runsChart) {
                    final axes = _mode == StressMode.axes;
                    // A new N, sharing, backgroundColor form or a change to
                    // or from the call animate (mode chart), or a new N,
                    // scale type or autoSkip (mode axes) gives a new host,
                    // thus a new chart. A ChartCanvas makes its chart only
                    // once.
                    return KeyedSubtree(
                      key: ValueKey(
                        axes
                            ? (_n, _scale, _yScale, _autoSkip)
                            : (
                                _n,
                                _sharing,
                                _scriptable,
                                _call == StressChartCall.animate,
                              ),
                      ),
                      child: ChartCanvas(
                        key: ValueKey(
                          axes ? 'stress.axes.host' : 'stress.chart.host',
                        ),
                        height: height,
                        create: axes ? _createAxesChart : _createChart,
                        onChart: (chart) {
                          _stressChart = chart as _StressChart;
                          _animating = false;
                          _chartReady();
                        },
                        onTickerModeChanged: _onTickerModeChanged,
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
                builder: (context, stats, _) => ReadoutTable(
                  key: const ValueKey('stress.stats'),
                  rows: [
                    ('FPS', stats.fps.toStringAsFixed(1)),
                    ('frames', '${stats.frames}'),
                    ('draw', '${ms(stats.drawMs)} ms'),
                    if (stats.mode == StressMode.chart) ...[
                      ('update', '${ms(stats.updateMs)} ms'),
                      ('animator', '${ms(stats.animatorMs)} ms'),
                    ],
                    if (stats.mode == StressMode.axes) ...[
                      ('update', '${ms(stats.updateMs)} ms'),
                      ('layout', '${ms(stats.layoutMs)} ms'),
                      ('datasets update', '${ms(stats.datasetsUpdateMs)} ms'),
                      ('datasets draw', '${ms(stats.datasetsDrawMs)} ms'),
                      ('x ticks', '${stats.ticks}'),
                      ('rotation', stats.rotation.toStringAsFixed(1)),
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
              const SizedBox(height: 8),
              Text(
                'draw: the Dart time of the draw calls of one frame '
                '(recording into a ui.Picture). In the element modes, it '
                'also has the writes of the element properties. update: the '
                'time of chart.update() without its draw. animator: the tick '
                'of the animations before their draw (call animate). layout, '
                'datasets update and datasets draw (mode axes): the parts '
                'between the plugin hooks, in the draw and update calls of '
                'the frames only. Draw minus datasets draw is the '
                'draw of the scales, the labels and the title. build and '
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

/// The `Chart` of the mode [StressMode.chart]: it adds the time of each
/// `draw()` to [drawMicros], also the draw inside `update()`.
///
/// For [StressChartCall.animate], it also adds the time from the mark of
/// [markTick] to the start of a draw in the same frame to [animatorMicros]:
/// the tick of the animator before its draw.
final class _StressChart extends Chart {
  _StressChart(super.item, [super.userConfig]);

  /// The clock of the marks.
  static final Stopwatch _watch = Stopwatch()..start();

  /// The microseconds of the draws since the last reset.
  int drawMicros = 0;

  /// The microseconds of the animator ticks since the last reset.
  int animatorMicros = 0;

  /// The time of the mark, or Dart `null` for no mark.
  int? _markMicros;

  /// The time stamp of the frame of the mark.
  Duration? _markFrame;

  /// The time stamp of the current frame, or Dart `null` outside the frame
  /// callbacks.
  static Duration? get _frame {
    final scheduler = SchedulerBinding.instance;
    return scheduler.schedulerPhase == SchedulerPhase.transientCallbacks
        ? scheduler.currentFrameTimeStamp
        : null;
  }

  /// Marks the time in a frame callback before the animator callback.
  void markTick() {
    _markFrame = _frame;
    _markMicros = _markFrame == null ? null : _watch.elapsedMicroseconds;
  }

  @override
  void draw() {
    final mark = _markMicros;
    if (mark != null && _frame == _markFrame) {
      animatorMicros += _watch.elapsedMicroseconds - mark;
    }
    _markMicros = null;
    final watch = Stopwatch()..start();
    super.draw();
    drawMicros += watch.elapsedMicroseconds;
  }
}
