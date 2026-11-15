// Original code, not ported from Chart.js: the live line chart.

import 'dart:async';
import 'dart:math' as math;

import 'package:chartjs_supabase_dashboard/src/live_series.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

/// The line of the series on a time axis.
///
/// The view follows the clock: a ticker moves the x range in each frame, so
/// that the line scrolls at an even speed. The right edge is the newest time
/// that all rows reached (`now - lagMs` of the series), so a new row comes
/// in from the right. The y range eases to the values in view.
///
/// A wheel or a trackpad scroll pans the x range (eased), a drag pans it,
/// and a pinch or Ctrl and the wheel zoom it (chartjs-plugin-zoom). The view
/// then stays where the user left it, until the right edge reaches the
/// newest time again or the button "Live" brings it back. When the left
/// edge comes near the oldest row, the series loads the page before it.
///
/// Each frame writes `min` and `max` of the two scales and calls
/// `chart.updateRanges`: the chart does no full update for a move. A new
/// row gives a new data List, and the `ChartView` updates the chart.
class const LiveChart({
  /// The rows of the chart.
  required final LiveSeries series,

  /// Called with the chart after the frame in which it starts.
  final ValueChanged<Chart>? onChartCreated,
  super.key,
}) extends StatefulWidget {
  /// Creates the chart of [series].
  this;

  @override
  State<LiveChart> createState() => _LiveChartState();
}

class _LiveChartState()
    extends State<LiveChart>
    with SingleTickerProviderStateMixin {
  /// The width of the x range at the start: 2 minutes.
  static const double _startWindow = 2 * 60 * 1000;

  /// The narrowest x range: 5 seconds.
  static const double _minWindow = 5000;

  /// The widest x range: 2 hours.
  static const double _maxWindow = 2 * 60 * 60 * 1000;

  /// The time constant of the eased x and y ranges, in milliseconds.
  static const double _easeMs = 90;

  /// The time constant of the eased delay of the right edge.
  static const double _lagEaseMs = 2000;

  /// A margin after the longest delay, so that a new row comes in from
  /// outside the chart area.
  static const double _lagMarginMs = 150;

  static const Color _lineColor = Color(0xFF3ECF8E);

  late final Ticker _ticker = createTicker(_onFrame);
  Duration _lastFrame = Duration.zero;

  Chart? _chart;
  bool _follow = true;
  double _window = _startWindow;

  /// The x range in view.
  double? _xMin;
  double? _xMax;

  /// The x range that the view eases to.
  double? _toXMin;
  double? _toXMax;

  /// The y range in view.
  double? _yMin;
  double? _yMax;

  /// The eased delay of the right edge, in milliseconds.
  double? _lag;

  /// The wheel pan of the next frame, in pixels: positive goes back.
  double _wheel = 0;

  /// A timed move of the x range on an ease-in-out curve, for the button
  /// "Live" and the zoom buttons: `from` is the range at the start, `to` the
  /// end range, or Dart `null` for the moving live range of the width
  /// `_window`, `ms` the duration and `start` the ticker time of the first
  /// frame. Dart `null` with no move.
  ({ScaleRange from, ScaleRange? to, double ms, Duration? start})? _move;

  /// The fixed widths of the zoom buttons.
  static const List<(String, double)> _ranges = [
    ('30s', 30 * 1000),
    ('2m', 2 * 60 * 1000),
    ('10m', 10 * 60 * 1000),
    ('1h', 60 * 60 * 1000),
  ];

  LiveSeries get _series => widget.series;

  /// The data List of the chart, and the state it comes from: the List of
  /// the series, the view mode and the page count.
  List<DataPoint> _shown = const [];
  List<DataPoint>? _shownFrom;
  bool? _shownFollow;
  int _shownPages = 0;
  double _shownWindow = 0;

  /// The data List of the chart. A full update of the chart reads each row
  /// of its List, so the List stays short where it can:
  /// - The live view gets the rows of the last two widths of the view.
  /// - The history view holds its List while new rows come: they are out of
  ///   view. A new page gives it all rows.
  ///
  /// A notice of the series with no new row keeps the List: the chart then
  /// does no update.
  List<DataPoint> _chartPoints() {
    final all = _series.points;
    final live = _follow && _move == null;
    if (_move != null) {
      // The move to the live edge crosses the rows between: all of them.
      _shown = all;
    } else if (live) {
      if (_shownFollow == true &&
          identical(all, _shownFrom) &&
          _shownWindow == _window) {
        return _shown;
      }
      final edge = _edge();
      final start = edge == null
          ? 0
          : math.max(0, _series.pointIndexAt(edge - 2 * _window) - 1);
      _shown = start == 0 ? all : all.sublist(start);
    } else {
      if (_shownFollow == false && _shownPages == _series.pages) return _shown;
      _shown = all;
    }
    _shownFrom = all;
    _shownFollow = live;
    _shownPages = _series.pages;
    _shownWindow = _window;
    return _shown;
  }

  late final ZoomPluginOptions _zoom = ZoomPluginOptions(
    // A pan or a zoom changes only the ranges: chart.updateRanges.
    rangeOnlyUpdates: true,
    pan: PanOptions(
      enabled: true,
      mode: Mode.x,
      onPan: (_) => _userPanned(),
      onPanComplete: (_) => _userPanned(),
    ),
    zoom: ZoomOptions(
      wheel: const WheelOptions(enabled: true, modifierKey: ModifierKey.ctrl),
      pinch: const PinchOptions(enabled: true),
      mode: Mode.x,
      onZoom: (_) => _userZoomed(),
    ),
    limits: const {'x': ScaleLimits(minRange: _minWindow)},
  );

  /// The config without the data. Each build gives it a new dataset with
  /// the data List of the series: the options stay `==`, so the chart keeps
  /// the ranges that the frames write into them.
  late final ChartConfig _config = ChartConfig(
    type: .line,
    datasets: const [],
    maintainAspectRatio: false,
    // The room of the last time label: the x axis adds no padding for it.
    padding: const EdgeInsets.only(right: _labelRoom),
    animation: ChartAnimation.none,
    legend: const ChartLegend(display: false),
    interaction: const ChartInteraction(
      mode: IndexInteractionMode(),
      intersect: false,
    ),
    plugins: [zoomPlugin],
    pluginOptions: [_zoom],
    scales: const {
      'x': TimeAxis(
        tooltipFormat: 'HH:mm:ss',
        ticks: AxisTicks(maxRotation: 0, callback: _timeLabel),
        extra: {'afterFit': _noLabelPadding},
      ),
      // No tick at the eased bounds: only the round values.
      'y': LinearAxis(
        ticks: AxisTicks(extra: {'includeBounds': false}),
        extra: {'afterFit': _fixedWidth},
      ),
    },
  );

  /// Half the width of a time label, in pixels.
  static const double _labelRoom = 28;

  /// The width of the y axis, in pixels.
  static const double _yAxisWidth = 48;

  /// The `afterFit` hook of the x axis: no padding for the labels. Chart.js
  /// pads the chart area by half of the first and the last label minus
  /// their distance to the edge. That padding changes in each frame of a
  /// moving range, and it jumps by half a label when a tick comes in at an
  /// edge: the whole plot jumps with it. The labels at the edges draw in
  /// the fixed padding of the chart on the right, and under the y axis on
  /// the left.
  static void _noLabelPadding(Scale scale) {
    scale
      ..paddingLeft = 0
      ..paddingRight = 0;
  }

  /// The `afterFit` hook of the y axis: one width, so that the plot does not
  /// move when the width of the labels changes.
  static void _fixedWidth(Scale scale) => scale.width = _yAxisWidth;

  /// The label of a time tick, or Dart `null` for a tick off the grid of
  /// [_timeStep]. The scale makes a tick each second (or minute), so the
  /// ticks on the grid stay on the same times while the range moves: no
  /// label jumps from one second to the next.
  static List<String>? _timeLabel(
    Scale scale,
    double value,
    int index,
    List<Tick> ticks,
  ) {
    final step = _timeStep(scale.max - scale.min, scale.width);
    // A call with one tick measures the label size: it gets a label.
    if (ticks.length > 1 && value % step != 0) return null;
    final time = DateTime.fromMillisecondsSinceEpoch(value.round());
    String two(int part) => part.toString().padLeft(2, '0');
    final hm = '${two(time.hour)}:${two(time.minute)}';
    return [if (step < 60000) '$hm:${two(time.second)}' else hm];
  }

  /// The time between two labels: about one label for each 100 pixels.
  static double _timeStep(double range, double width) {
    // 1, 2, 5, 10, 15 and 30 seconds, 1, 2, 5, 10, 15 and 30 minutes, 1 hour.
    const steps = <double>[
      1000, 2000, 5000, 10000, 15000, 30000, 60000, //
      120000, 300000, 600000, 900000, 1800000, 3600000,
    ];
    final labels = math.max(2, (width > 0 ? width : 800) / 100);
    for (final step in steps) {
      if (range / step <= labels) return step;
    }
    return steps.last;
  }

  @override
  void initState() {
    super.initState();
    _series.addListener(_seriesChanged);
  }

  @override
  void didUpdateWidget(LiveChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.series, widget.series)) {
      oldWidget.series.removeListener(_seriesChanged);
      widget.series.addListener(_seriesChanged);
    }
  }

  @override
  void dispose() {
    _series.removeListener(_seriesChanged);
    _chart?.canvas?.removeEventListener('wheel', _onWheel);
    _ticker.dispose();
    super.dispose();
  }

  void _onChartCreated(Chart chart) {
    _chart = chart;
    chart.canvas?.addEventListener('wheel', _onWheel, passive: false);
    widget.onChartCreated?.call(chart);
    _run();
  }

  void _seriesChanged() {
    setState(() {});
    // A new row can change the y range, and a new page the data in view.
    _run();
  }

  void _run() {
    if (_chart != null && !_ticker.isActive) {
      _lastFrame = Duration.zero;
      _ticker.start();
    }
  }

  void _setFollow(bool follow) {
    if (follow == _follow) return;
    setState(() => _follow = follow);
  }

  /// The right edge of the live view, in milliseconds since the epoch, or
  /// Dart `null` with no row. Before the first realtime row, it is the time
  /// of the newest row.
  double? _edge() {
    final newest = _series.newest;
    if (newest == null) return null;
    final lag = _lag;
    if (lag == null) return newest.millisecondsSinceEpoch.toDouble();
    return DateTime.now().millisecondsSinceEpoch - lag;
  }

  void _onFrame(Duration elapsed) {
    final chart = _chart;
    final x = chart?.scales['x'];
    final y = chart?.scales['y'];
    if (chart == null || x == null || y == null) return;
    final dt = _lastFrame == Duration.zero
        ? 16.0
        : (elapsed - _lastFrame).inMicroseconds / 1000;
    _lastFrame = elapsed;
    final ease = 1 - math.exp(-dt.clamp(0, 100) / _easeMs);

    final lagTarget = _series.lagMs;
    if (lagTarget != null) {
      final target = lagTarget + _lagMarginMs;
      final lag = _lag;
      _lag = lag == null
          ? target
          : lag + (target - lag) * (1 - math.exp(-dt / _lagEaseMs));
    }
    final edge = _edge();
    if (edge == null) return;

    var xMin = _xMin ?? x.min;
    var xMax = _xMax ?? x.max;
    var toXMin = _toXMin ?? xMin;
    var toXMax = _toXMax ?? xMax;

    if (_wheel != 0) {
      final shift = _wheel * (toXMax - toXMin) / math.max(1, x.width);
      _wheel = 0;
      toXMin -= shift;
      toXMax -= shift;
      _setFollow(toXMax >= edge);
    }
    if (_follow) {
      toXMax = edge;
      toXMin = edge - _window;
    }
    final move = _move;
    if (move != null) {
      // Each frame puts the range on the curve between the start range and
      // the end range of this frame: the live range moves with the clock.
      final start = move.start ?? elapsed;
      final t = ((elapsed - start).inMicroseconds / 1000 / move.ms).clamp(
        0.0,
        1.0,
      );
      final k = Curves.easeInOutCubic.transform(t);
      if (move.to case final to?) {
        toXMin = to.min;
        toXMax = to.max;
      }
      xMin = move.from.min + (toXMin - move.from.min) * k;
      xMax = move.from.max + (toXMax - move.from.max) * k;
      if (t >= 1) {
        // The live view takes its short data List again.
        setState(() => _move = null);
      } else {
        _move = (from: move.from, to: move.to, ms: move.ms, start: start);
      }
    } else if ((toXMax - xMax).abs() > 2 * _window) {
      // A long way: no easing through the hours between.
      xMin = toXMin;
      xMax = toXMax;
    } else {
      xMin += (toXMin - xMin) * ease;
      xMax += (toXMax - xMax) * ease;
    }

    var settled =
        (toXMin - xMin).abs() + (toXMax - xMax).abs() < _window * 1e-4;
    final extent = _series.extent(xMin, xMax);
    if (extent != null) {
      final pad = math.max((extent.max - extent.min) * 0.1, 0.5);
      final toYMin = extent.min - pad;
      final toYMax = extent.max + pad;
      final yMin = _yMin == null ? toYMin : _yMin! + (toYMin - _yMin!) * ease;
      final yMax = _yMax == null ? toYMax : _yMax! + (toYMax - _yMax!) * ease;
      settled &=
          (toYMin - yMin).abs() + (toYMax - yMax).abs() <
          (toYMax - toYMin) * 1e-3;
      _yMin = yMin;
      _yMax = yMax;
      y.options['min'] = yMin;
      y.options['max'] = yMax;
    }

    _xMin = xMin;
    _xMax = xMax;
    _toXMin = toXMin;
    _toXMax = toXMax;
    x.options['min'] = xMin;
    x.options['max'] = xMax;
    chart.updateRanges(UpdateMode.none);
    _loadOlderIfNear();

    if (!_follow && settled) _ticker.stop();
  }

  /// A wheel or a trackpad scroll without Ctrl pans the x range: down and
  /// right go back in time. With Ctrl, the zoom plugin zooms.
  void _onWheel(NativeEvent event) {
    if (event.ctrlKey) return;
    event.preventDefault();
    _stopMove();
    // deltaMode 1 counts lines, 2 pages: about 16 and 400 pixels.
    final unit = switch (event.deltaMode) {
      1 => 16.0,
      2 => 400.0,
      _ => 1.0,
    };
    _wheel +=
        (event.deltaX.abs() > event.deltaY.abs()
            ? -event.deltaX
            : event.deltaY) *
        unit;
    _run();
  }

  /// A drag of the zoom plugin moved the x range: the view takes it as it
  /// is, and follows the clock again when the right edge reaches the live
  /// edge.
  void _userPanned() {
    _stopMove();
    final scale = _chart?.scales['x'];
    final edge = _edge();
    if (scale == null || edge == null) return;
    _xMin = _toXMin = scale.min;
    _xMax = _toXMax = scale.max;
    _window = scale.max - scale.min;
    _setFollow(scale.max >= edge - _window * 0.01);
    _run();
  }

  /// A pinch or Ctrl and the wheel zoomed the x range. A live view keeps its
  /// right edge on the live edge.
  void _userZoomed() {
    _stopMove();
    final scale = _chart?.scales['x'];
    if (scale == null) return;
    final width = (scale.max - scale.min).clamp(_minWindow, _maxWindow);
    _window = width;
    if (_follow) {
      final edge = _edge() ?? scale.max;
      _xMax = _toXMax = edge;
      _xMin = _toXMin = edge - width;
    } else {
      final middle = (scale.max + scale.min) / 2;
      _xMin = _toXMin = middle - width / 2;
      _xMax = _toXMax = middle + width / 2;
    }
    setState(() {});
    _run();
  }

  /// Loads the page before the oldest row when the x range comes within
  /// half a width of it.
  void _loadOlderIfNear() {
    final oldest = _series.oldest;
    final min = _toXMin;
    if (oldest == null || min == null || _series.reachedStart) return;
    if (min < oldest.millisecondsSinceEpoch + _window * 0.5) {
      unawaited(_series.loadOlder());
    }
  }

  /// The button "Live": a move to the live edge with the width of the
  /// view, from 500 ms for a short way to 1400 ms for hours.
  void _backToLive() {
    final edge = _edge();
    final xMin = _xMin;
    final xMax = _xMax;
    if (edge == null || xMin == null || xMax == null) return;
    final widths = (edge - xMax).abs() / _window;
    final ms = (500 + 300 * math.log(1 + widths) / math.ln2).clamp(
      500.0,
      1400.0,
    );
    setState(() {
      _follow = true;
      _move = (from: (min: xMin, max: xMax), to: null, ms: ms, start: null);
    });
    _run();
  }

  /// Zooms the x range to [width] in 350 ms: the live view keeps its right
  /// edge on the live edge, and the history view keeps its center.
  void _zoomTo(double width) {
    final xMin = _xMin;
    final xMax = _xMax;
    if (xMin == null || xMax == null) return;
    final w = width.clamp(_minWindow, _maxWindow);
    if ((w - _window).abs() < 1) return;
    final middle = (xMin + xMax) / 2;
    setState(() {
      _window = w;
      _move = (
        from: (min: xMin, max: xMax),
        to: _follow ? null : (min: middle - w / 2, max: middle + w / 2),
        ms: 350,
        start: null,
      );
    });
    _run();
  }

  /// A drag, a wheel or a pinch of the user ends a move where it is.
  void _stopMove() {
    if (_move == null) return;
    setState(() => _move = null);
  }

  @override
  Widget build(BuildContext context) {
    final config = _config.copyWith(
      datasets: [
        LineDataset(
          label: 'value',
          points: _chartPoints(),
          borderColor: const .constant(.solid(_lineColor)),
          backgroundColor: const .constant(.solid(Color(0x263ECF8E))),
          fill: FillTarget.toStart,
          borderWidth: 2,
          pointRadius: 0,
          pointHoverRadius: 4,
          // The points are in the internal form of Chart.js, in the order
          // of x: an update reads no row (Chart.js performance docs).
          extra: const {'parsing': false, 'normalized': true},
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // One height: the chart area does not move when "Live" shows.
        SizedBox(
          height: 40,
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _ChartNote(series: _series),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  ),
                  child: _follow
                      ? const SizedBox.shrink()
                      : FilledButton.icon(
                          key: const ValueKey('dashboard.live'),
                          onPressed: _backToLive,
                          icon: const Icon(Icons.fast_forward),
                          label: const Text('Live'),
                        ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  key: const ValueKey('dashboard.zoom.out'),
                  tooltip: 'Zoom out',
                  onPressed: () => _zoomTo(_window * 2),
                  icon: const Icon(Icons.zoom_out),
                ),
                // The fixed widths fit a wide chart only.
                if (constraints.maxWidth >= 560)
                  SegmentedButton<double>(
                    key: const ValueKey('dashboard.ranges'),
                    segments: [
                      for (final (label, width) in _ranges)
                        ButtonSegment(
                          value: width,
                          label: Text(
                            label,
                            key: ValueKey('dashboard.range.$label'),
                          ),
                        ),
                    ],
                    selected: {
                      for (final (_, width) in _ranges)
                        if ((width - _window).abs() < width * 0.01) width,
                    },
                    emptySelectionAllowed: true,
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onSelectionChanged: (selection) {
                      if (selection.isNotEmpty) _zoomTo(selection.first);
                    },
                  ),
                IconButton(
                  key: const ValueKey('dashboard.zoom.in'),
                  tooltip: 'Zoom in',
                  onPressed: () => _zoomTo(_window / 2),
                  icon: const Icon(Icons.zoom_in),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ChartView(
            key: const ValueKey('dashboard.chart'),
            config: config,
            updateMode: UpdateMode.none,
            semanticLabel: 'Line chart of the live values of metric_points',
            onChartCreated: _onChartCreated,
          ),
        ),
      ],
    );
  }
}

/// The state of the history, at the left of the toolbar.
class const _ChartNote({required final LiveSeries series})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final text = !series.ready
        ? 'Loading the newest rows…'
        : series.loadingOlder
        ? 'Loading page ${series.pages + 1}…'
        : series.reachedStart
        ? 'All rows loaded'
        : null;
    if (text == null) return const SizedBox.shrink();
    return Chip(
      key: const ValueKey('dashboard.note'),
      label: Text(text),
      visualDensity: VisualDensity.compact,
    );
  }
}
