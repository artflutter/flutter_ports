// Original code, not ported from chartjs-plugin-zoom: the example app.

/// A line chart that zooms with the mouse wheel or a pinch, and pans with a
/// drag. The x axis stays inside the data, and a button puts back the whole
/// range.
///
/// Run it from a Flutter app of your own: copy this file to `lib/main.dart`
/// and add `flutter_chartjs_port` and `flutter_chartjs_plugin_zoom_port` to
/// the dependencies.
library;

import 'dart:math';

import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  // Register the chart components and the plugin before the first chart.
  Chart.register(registerables);
  Chart.register([zoomPlugin]);
  runApp(const ZoomExampleApp());
}

/// The example app: one line chart that follows the platform brightness.
class const ZoomExampleApp({super.key}) extends StatelessWidget {
  /// Creates the example app.
  this;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_chartjs_plugin_zoom_port',
      theme: ThemeData(brightness: Brightness.light),
      darkTheme: ThemeData(brightness: Brightness.dark),
      home: const ZoomPage(),
    );
  }
}

/// A page with the chart and a button that resets the zoom.
class const ZoomPage({super.key}) extends StatefulWidget {
  /// Creates the page.
  this;

  @override
  State<ZoomPage> createState() => _ZoomPageState();
}

class _ZoomPageState() extends State<ZoomPage> {
  /// The chart, from `onChartCreated`: the reset button calls its zoom API.
  Chart? _chart;

  /// 500 points of a signal.
  static final List<DataPoint> _points = [
    for (var i = 0; i < 500; i++)
      DataPoint(i, sin(i / 20) * 40 + sin(i / 3) * 8),
  ];

  /// The zoom options: the wheel and a pinch zoom the x axis, a drag pans
  /// it, and the original range of the axis is its limit.
  static const ZoomPluginOptions _zoom = ZoomPluginOptions(
    zoom: ZoomOptions(
      wheel: WheelOptions(enabled: true),
      pinch: PinchOptions(enabled: true),
      mode: Mode.x,
    ),
    pan: PanOptions(enabled: true, mode: Mode.x),
    limits: LimitOptions(
      x: ScaleLimits(min: ScaleLimit.original, max: ScaleLimit.original),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('flutter_chartjs_plugin_zoom_port')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ChartView(
            config: ChartConfig(
              datasets: [
                LineDataset(
                  label: 'Signal',
                  data: .points(_points),
                  borderWidth: 1.5,
                  pointRadius: const .constant(0),
                ),
              ],
              scales: const [LinearAxis(.x), LinearAxis(.y)],
              pluginOptions: const [_zoom],
            ),
            theme: dark
                ? const ChartThemeData.dark()
                : const ChartThemeData.light(),
            onChartCreated: (chart) => _chart = chart,
            semanticLabel: 'Line chart of a signal that zooms and pans',
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton(
              onPressed: () => _chart?.resetZoom(),
              child: const Text('Reset zoom'),
            ),
          ),
        ],
      ),
    );
  }
}
