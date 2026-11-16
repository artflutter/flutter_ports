// Original code, not ported from Chart.js: the live line chart.

import 'dart:async';
import 'dart:math' as math;

import 'package:chartjs_supabase_dashboard/src/live_series.dart';
import 'package:clock/clock.dart';
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
/// A wheel or a trackpad scroll pans the x range (eased), and Ctrl and the
/// wheel or a trackpad pinch zoom it around the pointer: the ticker applies
/// both in its next frame. A drag pans the range and a touch pinch zooms it
/// (chartjs-plugin-zoom). The view then stays where the user left it, until
/// the right edge reaches the newest time again or the button "Live" brings
/// it back. When the left edge comes near the oldest row, the series loads
/// the page before it.
///
/// Each frame writes `min` and `max` of the two scales and calls
/// `chart.updateRanges`: the chart does no full update for a move, and one
/// update in a frame for a wheel pan or a wheel zoom. A new row gives a new
/// data List, and the `ChartView` updates the chart.
///
/// The solid line joins the rows that are at most `gapThreshold` of the
/// series apart (1 hour). A dashed line joins two rows across a longer gap
/// of at most `dashThreshold` (2 hours). Rows farther apart have no line
/// between them.
///
/// A vertical amber line with the page number marks the start of each page
/// of the history. The pages are the cells of a grid of time (`pageSpan` of
/// the series), so the lines are at uniform distances.
///
/// In the live view, the line grows to a new row: the chart update of the
/// row runs in the mode `grow`, whose animations move the new point from
/// the point before it to its place (the scriptable `from` of `x` and `y`).
/// While the point moves, the frames update the ranges in the mode `scroll`
/// with the duration 0: the other points go to their places at once, and
/// the animation of the new point takes the new place as its target
/// (core.animations.js:90-93). The update mode `none` writes the places
/// directly, and the animation then keeps the target of its start.
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

  /// The width of the line, in pixels.
  static const double _lineWidth = 2;

  /// The dashed line across a gap: the length of a dash and of the space
  /// after it, in pixels.
  static const double _dash = 4;
  static const double _dashSpace = 4;

  /// The update mode of the chart update that adds a new row in the live
  /// view: its point moves from the point before it to its place.
  static const UpdateMode _growMode = UpdateMode('grow');

  /// The update mode of the frames while the new point moves. Its duration
  /// is the base duration 0: a point with no animation goes to its place at
  /// once, and the running animation takes the new place as its target.
  static const UpdateMode _scrollMode = UpdateMode('scroll');

  /// The time in which the line grows to a new row.
  static const Duration _growTime = Duration(milliseconds: 500);

  /// The shortest new segment that grows, in pixels. A shorter segment, in
  /// a wide view, shows at once: the update of the mode `grow` resolves the
  /// animation options of each point in view.
  static const double _growMinPixels = 2;

  late final Ticker _ticker = createTicker(_onFrame);
  Duration _lastFrame = Duration.zero;

  /// The new row of the next chart update, which grows: its x, and the x
  /// and the y of the row before it. Dart `null` when the update adds no
  /// such row.
  ({double x, double fromX, double fromY})? _grow;

  /// The x of the last point of the data List of the last build.
  double? _lastX;

  /// The end of the move of the new point: until then the frames update
  /// the ranges in [_scrollMode].
  DateTime? _growEnd;

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

  /// The wheel zoom of the next frame: the factor of the width of the x
  /// range (below 1 zooms in), and the x of the pointer on the canvas.
  double _zoomBy = 1;
  double _zoomAt = 0;

  /// The wheel zoom of chartjs-plugin-zoom (`wheel.speed`, `MAX_DELTA`): a
  /// step of [_zoomNotch] pixels or more changes the width by [_zoomSpeed].
  static const double _zoomSpeed = 0.1;
  static const double _zoomNotch = 24;

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

  /// The time of the first row of the List of the live view, or negative
  /// infinity when the List has all rows.
  double _shownStart = double.negativeInfinity;

  /// The data List of the chart. A full update of the chart reads each row
  /// of its List, so the List stays short where it can:
  /// - The live view gets the rows of the last two widths of the view.
  /// - The history view holds its List while new rows come: they are out of
  ///   view. A new page gives it all rows.
  ///
  /// A notice of the series with no new row keeps the List: the chart then
  /// does no update. A zoom of the live view also keeps it, while it holds
  /// the view and is not too long for it: each step of a zoom changes the
  /// width, and a new List for each step is a full update of the chart for
  /// each step.
  List<DataPoint> _chartPoints() {
    final all = _series.points;
    final live = _follow && _move == null;
    if (_move != null) {
      // The move to the live edge crosses the rows between: all of them.
      _shown = all;
    } else if (live) {
      final edge = _edge();
      if (_shownFollow == true && identical(all, _shownFrom)) {
        if (_shownWindow == _window) return _shown;
        // The List has the rows from the left edge of the view, and the
        // view is not below a quarter of the width that the List is for.
        if (edge != null &&
            _shownStart <= edge - _window &&
            _window >= _shownWindow / 4) {
          return _shown;
        }
      }
      var start = edge == null
          ? 0
          : math.max(0, _series.pointIndexAt(edge - 2 * _window) - 1);
      // Not a gap point first: the dashed line of the gap needs the row
      // before it.
      if (start > 0 && all[start].y == null) start--;
      _shown = start == 0 ? all : all.sublist(start);
      _shownStart = start == 0
          ? double.negativeInfinity
          : _shown.first.x as double;
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
      // A touch pinch. The wheel zoom is in [_onWheel]: the plugin does a
      // chart update for each wheel event, and the ticker then does one
      // more in the same frame.
      pinch: const PinchOptions(enabled: true),
      mode: Mode.x,
      onZoom: (_) => _userZoomed(),
    ),
    limits: const {'x': ScaleLimits(minRange: _minWindow)},
  );

  /// Draws the dashed lines after the line. It has a draw hook only, so the
  /// chart keeps its range updates (`supportsDataUpdates`).
  late final ChartPlugin<Object?> _gaps = ChartPlugin(
    id: 'liveChartGaps',
    supportsDataUpdates: true,
    afterDatasetsDraw: (chart, args, options) => _drawGaps(chart),
  );

  /// Draws a dashed line across each gap in view of at most
  /// `dashThreshold` of the series: from the row before a point with no
  /// value to the row after it.
  ///
  /// It makes each dash as a line of its own, for the part in view only,
  /// and counts the dashes from the row before the gap: they stay on their
  /// times while the view moves. A line dash of the canvas cuts the whole
  /// line, also the part out of view: a gap of hours in a view of seconds
  /// is millions of pixels long.
  void _drawGaps(Chart chart) {
    final x = chart.scales['x'];
    final y = chart.scales['y'];
    final area = chart.chartArea;
    final ctx = chart.ctx;
    if (x == null || y == null || area == null || ctx == null) return;
    final points = _shown;
    // The first point at or after the left edge.
    var low = 0;
    var high = points.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if ((points[mid].x as double) < x.min) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    const period = _dash + _dashSpace;
    final longest = _series.dashThreshold.inMilliseconds;
    var dashes = false;
    // The point before the left edge is the gap point of a gap that starts
    // before the view and ends in it or after it.
    for (var i = math.max(1, low - 1); i < points.length - 1; i++) {
      final gap = points[i];
      if ((gap.x as double) > x.max) break;
      if (gap.y != null) continue;
      final from = points[i - 1];
      final to = points[i + 1];
      final fromValue = from.y;
      final toValue = to.y;
      if (fromValue == null || toValue == null) continue;
      if ((to.x as double) - (from.x as double) > longest) continue;
      final x0 = x.getPixelForValue(from.x);
      final y0 = y.getPixelForValue(fromValue);
      final dx = x.getPixelForValue(to.x) - x0;
      final dy = y.getPixelForValue(toValue) - y0;
      final length = math.sqrt(dx * dx + dy * dy);
      if (dx <= 0 || !length.isFinite) continue;
      // The part between the left and the right edge, as distances from
      // the row before the gap.
      final start = math.max<double>(0, (area.left - x0) / dx) * length;
      final end = math.min<double>(1, (area.right - x0) / dx) * length;
      for (
        var dash = (start / period).floorToDouble() * period;
        dash < end;
        dash += period
      ) {
        final a = math.max(dash, start);
        final b = math.min(dash + _dash, end);
        if (b <= a) continue;
        if (!dashes) {
          dashes = true;
          ctx
            ..save()
            ..beginPath()
            ..rect(area.left, area.top, area.width, area.height)
            ..clip()
            ..strokeStyle = _lineColor
            ..lineWidth = _lineWidth
            ..setLineDash(const [])
            ..beginPath();
        }
        ctx
          ..moveTo(x0 + dx * a / length, y0 + dy * a / length)
          ..lineTo(x0 + dx * b / length, y0 + dy * b / length);
      }
    }
    if (dashes) {
      ctx
        ..stroke()
        ..restore();
    }
  }

  /// The color of the page splits: amber, apart from the green line and the
  /// gray grid in the light and the dark theme.
  static const Color _pageColor = Color(0xFFF5A623);

  /// Draws the page splits before the line, so that the line stays on top.
  /// It has a draw hook only, so the chart keeps its range updates
  /// (`supportsDataUpdates`).
  late final ChartPlugin<Object?> _pageSplits = ChartPlugin(
    id: 'liveChartPages',
    supportsDataUpdates: true,
    beforeDatasetsDraw: (chart, args, options) {
      _drawPageSplits(chart);
      return true;
    },
  );

  /// Draws a vertical line at the start of each page in view, with the
  /// number of the page at the top, on the right of the line: the rows from
  /// the line to the next line on the right came in that page. Page 1 is the
  /// newest page, and the realtime rows follow it.
  void _drawPageSplits(Chart chart) {
    final x = chart.scales['x'];
    final area = chart.chartArea;
    final ctx = chart.ctx;
    if (x == null || area == null || ctx == null) return;
    final starts = _series.pageStarts;
    var drawn = false;
    for (var i = 0; i < starts.length; i++) {
      final ms = starts[i].millisecondsSinceEpoch.toDouble();
      if (ms < x.min || ms > x.max) continue;
      final at = x.getPixelForValue(ms);
      if (!drawn) {
        drawn = true;
        ctx
          ..save()
          ..beginPath()
          ..rect(area.left, area.top, area.width, area.height)
          ..clip()
          ..strokeStyle = _pageColor
          ..fillStyle = _pageColor
          ..lineWidth = 1
          ..setLineDash(const [])
          ..font = toFont(const TextStyle(fontSize: 11))
          ..textAlign = TextAlign.left
          ..textBaseline = CanvasTextBaseline.top;
      }
      ctx
        ..beginPath()
        ..moveTo(at, area.top)
        ..lineTo(at, area.bottom)
        ..stroke()
        ..fillText('page ${i + 1}', at + 4, area.top + 4);
    }
    if (drawn) ctx.restore();
  }

  /// The config without the data. Each build gives it a new dataset with
  /// the data List of the series: the options stay `==`, so the chart keeps
  /// the ranges that the frames write into them.
  late final ChartConfig _config = ChartConfig(
    type: .line,
    datasets: const [],
    maintainAspectRatio: false,
    // The room of the last time label: the x axis adds no padding for it.
    padding: const EdgeInsets.only(right: _labelRoom),
    // The animations run, with the duration 0: only the new point of the
    // mode `grow` moves (its transition below).
    animation: const ChartAnimation(duration: Duration.zero),
    transitions: const [HoverTransition.off()],
    legend: const ChartLegend(display: false),
    // The tooltip shows at once, as with no animation.
    tooltip: const ChartTooltip(
      extra: {
        'animations': {
          'numbers': {'duration': 0},
          'opacity': {'duration': 0},
        },
      },
    ),
    interaction: const ChartInteraction(
      mode: IndexInteractionMode(),
      intersect: false,
    ),
    plugins: [zoomPlugin, _pageSplits, _gaps],
    pluginOptions: [_zoom],
    extra: {
      'transitions': {
        'grow': {
          'animations': {
            'x': {
              'from': _growFromX,
              'duration': _growDuration,
              'easing': Curves.easeOutCubic,
            },
            'y': {
              'from': _growFromY,
              'duration': _growDuration,
              'easing': Curves.easeOutCubic,
            },
          },
        },
      },
    },
    scales: const {
      'x': TimeAxis(
        tooltipFormat: 'HH:mm:ss',
        ticks: AxisTicks(maxRotation: 0, callback: _timeLabel),
        extra: {
          // No tick for each millisecond of a range of some seconds.
          'time': {'minUnit': TimeUnit.second},
          'afterBuildTicks': _gridTicks,
          'afterFit': _noLabelPadding,
        },
      ),
      // No tick at the eased bounds, and whole numbers only (precision 0
      // rounds the step to an integer).
      'y': LinearAxis(
        ticks: AxisTicks(extra: {'includeBounds': false, 'precision': 0}),
        extra: {'afterFit': _fixedWidth},
      ),
    },
  );

  /// Whether [context] is the context of the point of the new row of
  /// [_grow].
  bool _isGrowPoint(Object? context) {
    final grow = _grow;
    if (grow == null || context is! ScriptableContext) return false;
    final raw = context.raw;
    return raw is DataPoint && raw.x == grow.x;
  }

  /// The scriptable `from` of `x` in the mode `grow`: the x pixel of the
  /// row before the new row for the new point, else `undefined`, which
  /// starts an animation at the current value.
  Object? _growFromX(Object? context) => _isGrowPoint(context)
      ? _chart?.scales['x']?.getPixelForValue(_grow!.fromX) ?? undefined
      : undefined;

  /// The scriptable `from` of `y` in the mode `grow`, as [_growFromX].
  Object? _growFromY(Object? context) => _isGrowPoint(context)
      ? _chart?.scales['y']?.getPixelForValue(_grow!.fromY) ?? undefined
      : undefined;

  /// The scriptable `duration` of `x` and `y` in the mode `grow`, in
  /// milliseconds: [_growTime] for the new point, else 0, so that each other
  /// point goes to its place at once.
  Object? _growDuration(Object? context) =>
      _isGrowPoint(context) ? _growTime.inMilliseconds : 0;

  /// The growth of the new row of [points], the data List of this build:
  /// in the live view, when the List adds one row after the last row of the
  /// List of the last build, and the new segment is at least
  /// [_growMinPixels] wide. Else Dart `null`.
  ({double x, double fromX, double fromY})? _growOf(List<DataPoint> points) {
    final previous = _lastX;
    final last = points.isEmpty ? null : points.last;
    final x = last?.x;
    _lastX = x is double ? x : null;
    if (previous == null || last == null || x is! double || x <= previous) {
      return null;
    }
    if (!_follow || _move != null || points.length < 2) return null;
    final before = points[points.length - 2];
    final fromY = before.y;
    if (before.x != previous || fromY == null || last.y == null) return null;
    final scale = _chart?.scales['x'];
    if (scale == null ||
        scale.getPixelForValue(x) - scale.getPixelForValue(previous) <
            _growMinPixels) {
      return null;
    }
    _growEnd = clock.now().add(_growTime + const Duration(milliseconds: 100));
    return (x: x, fromX: previous, fromY: fromY);
  }

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

  /// The `afterBuildTicks` hook of the x axis: the ticks of the grid of
  /// [_timeStep], in place of the ticks of the scale. The scale makes a
  /// tick for each second or minute of the range, up to some thousands in
  /// each update. The grid has about one tick for each 100 pixels, and its
  /// ticks stay on the same times while the range moves: no label jumps
  /// from one second to the next.
  static void _gridTicks(Scale scale) {
    final step = _timeStep(scale.max - scale.min, scale.width);
    scale.ticks = [
      for (
        var value = (scale.min / step).ceilToDouble() * step;
        value <= scale.max;
        value += step
      )
        Tick(value: value),
    ];
  }

  /// The label of a time tick: the seconds show while the grid of
  /// [_timeStep] is narrower than a minute.
  static List<String>? _timeLabel(
    Scale scale,
    double value,
    int index,
    List<Tick> ticks,
  ) {
    final step = _timeStep(scale.max - scale.min, scale.width);
    final time = DateTime.fromMillisecondsSinceEpoch(value.round());
    String two(int part) => part.toString().padLeft(2, '0');
    final hm = '${two(time.hour)}:${two(time.minute)}';
    return [if (step < 60000) '$hm:${two(time.second)}' else hm];
  }

  /// The time between two labels: about one label for each 100 pixels, and
  /// at least 5 seconds.
  static double _timeStep(double range, double width) {
    // 5, 10, 15 and 30 seconds, 1, 2, 5, 10, 15 and 30 minutes, 1 hour.
    const steps = <double>[
      5000, 10000, 15000, 30000, 60000, //
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
    var zoomed = false;
    if (_zoomBy != 1) {
      // The time at the pointer keeps its place. A live view keeps its
      // right edge on the live edge (below).
      final width = ((xMax - xMin) * _zoomBy).clamp(_minWindow, _maxWindow);
      final at = ((_zoomAt - x.left) / math.max(1, x.width)).clamp(0.0, 1.0);
      final time = xMin + (xMax - xMin) * at;
      _zoomBy = 1;
      toXMin = time - width * at;
      toXMax = toXMin + width;
      zoomed = true;
      if (width != _window) {
        // The toolbar shows the width, and the data List follows it.
        setState(() => _window = width);
      }
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
    } else if (zoomed || (toXMax - xMax).abs() > 2 * _window) {
      // A zoom step follows the fingers, and a long way has no easing
      // through the hours between.
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
      // At least 1 on each side: the range holds two whole numbers.
      final pad = math.max<double>((extent.max - extent.min) * 0.1, 1);
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
    final growEnd = _growEnd;
    final growing = growEnd != null && clock.now().isBefore(growEnd);
    if (!growing) _growEnd = null;
    chart.updateRanges(growing ? _scrollMode : UpdateMode.none);
    _loadOlderIfNear();

    if (!_follow && settled) _ticker.stop();
  }

  /// A wheel or a trackpad scroll without Ctrl pans the x range: down and
  /// right go back in time. With Ctrl, which a trackpad pinch also gives,
  /// it zooms the x range around the pointer, by the step of the wheel zoom
  /// of chartjs-plugin-zoom. The next frame of the ticker applies both: an
  /// event does no chart update of its own.
  void _onWheel(NativeEvent event) {
    event.preventDefault();
    _stopMove();
    if (event.ctrlKey) {
      final amount =
          _zoomSpeed * math.min(event.deltaY.abs(), _zoomNotch) / _zoomNotch;
      _zoomBy *= event.deltaY < 0 ? 1 - amount : 1 / (1 - amount);
      final canvas = _chart?.canvas;
      if (canvas != null) {
        _zoomAt = event.clientX - canvas.getBoundingClientRect().left;
      }
      _run();
      return;
    }
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

  /// A touch pinch of the zoom plugin zoomed the x range. A live view keeps
  /// its right edge on the live edge.
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
    final points = _chartPoints();
    _grow = _growOf(points);
    final config = _config.copyWith(
      datasets: [
        LineDataset(
          label: 'value',
          points: points,
          borderColor: const .constant(.solid(_lineColor)),
          backgroundColor: const .constant(.solid(Color(0x263ECF8E))),
          fill: FillTarget.toStart,
          borderWidth: _lineWidth,
          pointRadius: 0,
          pointHoverRadius: 4,
          // Smooth curves that do not overshoot the values, so the y range
          // of the values in view still holds the line.
          cubicInterpolationMode: const MonotoneCubicInterpolationMode(),
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
            updateMode: _grow == null ? UpdateMode.none : _growMode,
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
