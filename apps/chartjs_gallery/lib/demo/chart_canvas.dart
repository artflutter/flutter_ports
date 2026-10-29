// Original code, not ported from Chart.js: the host of a gallery Chart.

// The reason of each import of lib/src is the comment above it.
// ignore_for_file: implementation_imports

import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart'
    show Chart, animator;
// Not public: UiCanvasElement, the canvas of the host (Chart.js ADR 0048).
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
// Not public: ChartHost, the internal host of ChartView (Chart.js ADR 0048).
import 'package:flutter_chartjs_port/src/platform/chart_host.dart';

/// Makes the chart of a [ChartCanvas] on its [canvas]: `new Chart(canvas,
/// config)`.
typedef ChartFactory = Chart Function(UiCanvasElement canvas);

/// A [ChartHost] that shows a real `Chart` of `core.controller` (phase 5).
///
/// The public widget is `ChartView` (Chart.js ADR 0049): the type pages
/// and the Core and Axes tabs use it. This host stays for the stress host
/// `HOST=canvas`, the side A of the night series A-N1 (the overhead of
/// `ChartView`), and for a chart class that times its own draws. It goes
/// after the night record (spec-a, section 6).
///
/// The widget owns a `UiCanvasElement`. It makes the chart with [create]
/// after the first frame, once the host shows the canvas, so that
/// `detectPlatform` gives the `FlutterPlatform`. It destroys the chart when
/// it unmounts. A new [create] does not make a new chart: give the widget a
/// new key for that.
///
/// The widget is the owner of the chart. Thus it connects
/// `ChartHost.onTickerModeChanged` to `animator.mute` and `animator.unmute`
/// (Chart.js ADR 0016, decision 7), and it mutes a chart that it makes under
/// `TickerMode(enabled: false)`. `ChartView` does the same.
///
/// With a [height], the host has that height. Without one, the host takes
/// the height of its constraints.
class ChartCanvas extends StatefulWidget {
  /// Creates a host for the chart of [create].
  const ChartCanvas({
    required this.create,
    this.height,
    this.onChart,
    this.onTickerModeChanged,
    super.key,
  });

  /// Makes the chart on the canvas of the widget.
  final ChartFactory create;

  /// The height of the host.
  final double? height;

  /// Called once the chart exists.
  final ValueChanged<Chart>? onChart;

  /// Called after the mute or the unmute, with the new `enabled` value of
  /// the `TickerMode` of the host.
  final ValueChanged<bool>? onTickerModeChanged;

  @override
  State<ChartCanvas> createState() => ChartCanvasState();
}

/// The state of a [ChartCanvas]: it owns the canvas and the chart.
class ChartCanvasState extends State<ChartCanvas> {
  final UiCanvasElement _canvas = UiCanvasElement();
  Chart? _chart;
  bool _tickerEnabled = true;

  /// The chart, once it exists.
  Chart? get chart => _chart;

  /// The canvas of the chart.
  UiCanvasElement get canvas => _canvas;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final chart = _chart = widget.create(_canvas);
      if (!_tickerEnabled) animator.mute(chart);
      widget.onChart?.call(chart);
    }, debugLabel: 'ChartCanvas.start');
  }

  void _onTickerModeChanged(bool enabled) {
    _tickerEnabled = enabled;
    final chart = _chart;
    if (chart != null) {
      if (enabled) {
        animator.unmute(chart);
      } else {
        animator.mute(chart);
      }
    }
    widget.onTickerModeChanged?.call(enabled);
  }

  @override
  void dispose() {
    _chart?.destroy();
    _canvas.getContext2d().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _tickerEnabled = TickerMode.valuesOf(context).enabled;
    return SizedBox(
      height: widget.height,
      child: ChartHost(
        canvas: _canvas,
        onTickerModeChanged: _onTickerModeChanged,
      ),
    );
  }
}
