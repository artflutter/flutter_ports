// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 docs/guide/usage.md (MIT, chartjs-plugin-zoom contributors).
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion zoom-usage
const zoomUsage = ChartConfig(
  labels: ['January', 'February', 'March', 'April', 'May', 'June', 'July'],
  datasets: [
    LineDataset(
      label: 'My First Dataset',
      data: .values([65, 59, 80, 81, 56, 55, 40]),
      fill: .none,
      borderColor: .constant(.solid(Color.fromRGBO(75, 192, 192, 1))),
      tension: 0.1,
    ),
  ],
  pluginOptions: [
    ZoomPluginOptions(
      zoom: ZoomOptions(
        wheel: WheelOptions(enabled: true),
        pinch: PinchOptions(enabled: true),
        mode: Mode.xy,
      ),
    ),
  ],
);
// #enddocregion zoom-usage

void main() {
  Chart.register(registerables);
  Chart.register([zoomPlugin]);
  runApp(
    const Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: Color(0xFFFFFFFF),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: ChartView(config: zoomUsage)),
        ),
      ),
    ),
  );
}
