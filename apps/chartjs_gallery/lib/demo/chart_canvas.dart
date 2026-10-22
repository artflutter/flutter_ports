// Original code, not ported from Chart.js: the host of a gallery Chart.

// The package exports nothing from lib/src yet; the public API comes in
// phase 9. The demo imports the ported files directly.
// ignore_for_file: implementation_imports

import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/core/core.animator.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/platform/chart_host.dart';

/// Makes the chart of a [ChartCanvas] on its [canvas]: `new Chart(canvas,
/// config)`.
typedef ChartFactory = Chart Function(UiCanvasElement canvas);

/// A [ChartHost] that shows a real `Chart` of `core.controller` (phase 5).
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
/// `TickerMode(enabled: false)`. The phase 9 widget does the same.
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
