// The package exports nothing from lib/src yet; the public API comes in
// phase 9. The demo imports the ported files directly.
// ignore_for_file: implementation_imports

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:chartjs_gallery/demo/canvas_demo.dart' show labelColor;
import 'package:chartjs_gallery/demo/demo_chart.dart';
import 'package:chartjs_gallery/demo/demo_common.dart';
import 'package:chartjs_gallery/demo/demo_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_chartjs/src/canvas/canvas.dart';
import 'package:flutter_chartjs/src/helpers/index.dart'
    show ParsedFont, drawPoint, renderText, requestAnimFrame, toFont;

/// The point counts of the stress tab.
const List<int> stressPointCounts = [1000, 5000, 20000];

/// The label counts of the stress tab.
const List<int> stressLabelCounts = [0, 50, 200];

/// The figures of the stress tab, published twice a second and when the
/// loop stops: the point count N, the label count M, and the frame figures.
typedef StressStats = ({
  int points,
  int labels,
  int frames,
  double fps,
  double drawMs,
  double buildMs,
  double buildMaxMs,
  double rasterMs,
  double rasterMaxMs,
  int timings,
});

const StressStats _noStats = (
  points: 0,
  labels: 0,
  frames: 0,
  fps: 0,
  drawMs: 0,
  buildMs: 0,
  buildMaxMs: 0,
  rasterMs: 0,
  rasterMaxMs: 0,
  timings: 0,
);

/// A performance test bed: a chart host drawn again in every frame.
///
/// `requestAnimFrame` (helpers.extras) schedules each frame, as the
/// Chart.js animator does. A frame draws N moving points with `drawPoint`,
/// a polyline through N points, and M rotated labels with `renderText`.
/// The labels have one fixed angle of -45 degrees, as the tick labels of a
/// chart have; the `spin labels` switch gives each label a new angle in
/// every frame.
/// The readout shows the frames per second, the time of the draw calls,
/// and the build and raster times of `SchedulerBinding.addTimingsCallback`.
///
/// Every control has a `ValueKey` (`stress.n.5000`, `stress.m.200`,
/// `stress.start`, …) so that automation can drive it.
class StressDemo extends StatefulWidget {
  /// Creates the stress tab.
  ///
  /// [initialN] and [initialM] set the first point and label counts.
  /// [autoStart] starts the loop when the chart exists. [onStats] receives
  /// each published [StressStats]. They let a profiling entry point
  /// (`lib/main_stress.dart`) or a test drive the tab.
  const StressDemo({
    this.initialN,
    this.initialM,
    this.initialSpin = false,
    this.autoStart = false,
    this.onStats,
    super.key,
  });

  /// The first point count, or the first of [stressPointCounts].
  final int? initialN;

  /// The first label count, or 50.
  final int? initialM;

  /// Whether the labels start with a new angle in each frame.
  final bool initialSpin;

  /// Whether the loop starts as soon as the chart exists.
  final bool autoStart;

  /// Receives the figures each time the readout updates.
  final ValueChanged<StressStats>? onStats;

  @override
  State<StressDemo> createState() => _StressDemoState();
}

class _StressDemoState extends State<StressDemo> {
  static final int _maxPoints = stressPointCounts.reduce(math.max);

  late int _n = widget.initialN ?? stressPointCounts.first;
  late int _m = widget.initialM ?? stressLabelCounts[1];
  bool _points = true;
  bool _line = true;
  late bool _spin = widget.initialSpin;
  bool _running = false;
  bool _muted = false;

  DemoChart? _chart;
  int? _frameId;

  // Point positions and velocities, in fractions of the chart per second.
  final Float64List _px = Float64List(_maxPoints);
  final Float64List _py = Float64List(_maxPoints);
  final Float64List _vx = Float64List(_maxPoints);
  final Float64List _vy = Float64List(_maxPoints);
  double _t = 0;
  final Stopwatch _clock = Stopwatch();
  Duration _lastTick = Duration.zero;

  // Statistics.
  final ValueNotifier<StressStats> _stats = ValueNotifier(_noStats);
  int _frames = 0;
  int _windowFrames = 0;
  int _windowDrawMicros = 0;
  Duration _windowStart = Duration.zero;
  double _fps = 0;
  double _drawMs = 0;
  final List<FrameTiming> _timings = [];

  final ParsedFont _labelFont = toFont(<String, Object?>{'size': 12});
  final ParsedFont _titleFont = toFont(<String, Object?>{
    'size': 13,
    'weight': 'bold',
  });

  @override
  void initState() {
    super.initState();
    final random = math.Random(7);
    for (var i = 0; i < _maxPoints; i++) {
      _px[i] = random.nextDouble();
      _py[i] = random.nextDouble();
      final angle = random.nextDouble() * 2 * math.pi;
      final speed = 0.05 + random.nextDouble() * 0.25;
      _vx[i] = math.cos(angle) * speed;
      _vy[i] = math.sin(angle) * speed;
    }
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
      _frames = 0;
      _timings.clear();
      _scheduleFrame();
    } else {
      _cancelFrame();
      _clock.stop();
      _publish();
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
    final chart = _chart;
    if (!_running || !mounted || chart == null) return;
    final now = _clock.elapsed;
    final dt = math.min(
      (now - _lastTick).inMicroseconds / 1e6,
      0.05,
    );
    _lastTick = now;
    _step(dt);
    chart.render();
    _frames++;
    _windowFrames++;
    _windowDrawMicros += chart.lastDrawMicros;
    final window = now - _windowStart;
    if (window >= const Duration(milliseconds: 500)) {
      _fps = _windowFrames / (window.inMicroseconds / 1e6);
      _drawMs = _windowDrawMicros / _windowFrames / 1000;
      _windowStart = now;
      _windowFrames = 0;
      _windowDrawMicros = 0;
      _publish();
    }
    _scheduleFrame();
  }

  void _step(double dt) {
    _t += dt;
    for (var i = 0; i < _n; i++) {
      var x = _px[i] + _vx[i] * dt;
      var y = _py[i] + _vy[i] * dt;
      if (x < 0 || x > 1) {
        _vx[i] = -_vx[i];
        x = x.clamp(0, 1);
      }
      if (y < 0 || y > 1) {
        _vy[i] = -_vy[i];
        y = y.clamp(0, 1);
      }
      _px[i] = x;
      _py[i] = y;
    }
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
    _stats.value = (
      points: _n,
      labels: _m,
      frames: _frames,
      fps: _fps,
      drawMs: _drawMs,
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

  void _draw(DemoChart chart, CanvasRenderingContext2D ctx) {
    final w = chart.width;
    final h = chart.height;
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
        final y =
            h / 2 +
            math.sin(f * 6 * math.pi + _t * 1.5) * h * 0.3 +
            math.sin(i * 0.37 + _t * 6) * h * 0.04;
        if (i == 0) {
          ctx.moveTo(x, y);
        } else {
          ctx.lineTo(x, y);
        }
      }
      ctx.stroke();
    }
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
    final title = '$_n points · $_m labels · frame $_frames';
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

  Widget _choices(
    String name,
    List<int> values,
    int value,
    ValueChanged<int> set,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(width: 92, child: Text(name)),
        for (final v in values)
          ChoiceChip(
            key: ValueKey('stress.${name.toLowerCase()}.$v'),
            label: Text(v >= 1000 ? '${v ~/ 1000}k' : '$v'),
            selected: v == value,
            onSelected: (_) => setState(() => set(v)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String ms(double v) => v.toStringAsFixed(2);
    return DemoPageBody(
      children: [
        DemoCard(
          title: 'Stress test',
          source:
              'helpers.extras: requestAnimFrame each frame · helpers.canvas: '
              'drawPoint × N · lineTo × N · renderText × M (rotated)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Switch(
                    key: const ValueKey('stress.start'),
                    value: _running,
                    onChanged: _setRunning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _running ? 'Running' : 'Stopped',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              _choices('N', stressPointCounts, _n, (v) => _n = v),
              const SizedBox(height: 4),
              _choices('M', stressLabelCounts, _m, (v) => _m = v),
              const SizedBox(height: 4),
              ToggleChips(
                toggles: [
                  (
                    key: 'stress.layer.points',
                    label: 'points',
                    value: _points,
                    onChanged: (v) => setState(() => _points = v),
                  ),
                  (
                    key: 'stress.layer.line',
                    label: 'polyline',
                    value: _line,
                    onChanged: (v) => setState(() => _line = v),
                  ),
                  (
                    key: 'stress.spin',
                    label: 'spin labels',
                    value: _spin,
                    onChanged: (v) => setState(() => _spin = v),
                  ),
                ],
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
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) => DemoCanvas(
                  key: const ValueKey('stress.host'),
                  height: (constraints.maxWidth * 0.6).clamp(240, 520),
                  draw: _draw,
                  onChart: (chart) {
                    _chart = chart;
                    if (widget.autoStart && !_running) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && !_running) _setRunning(true);
                      });
                    }
                  },
                  onTickerModeChanged: _onTickerModeChanged,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'draw: the Dart time of the draw calls of one frame '
                '(recording into a ui.Picture). build and raster: '
                'FrameTiming of the last 120 frames. Profile on a device '
                'with flutter run --profile.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
