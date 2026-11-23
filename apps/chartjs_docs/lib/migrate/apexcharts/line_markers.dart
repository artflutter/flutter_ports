// Original code, not ported from Chart.js: a replica of the apexcharts_flutter demo "Line — markers + axis titles + $ format".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion apex-line-markers
import 'package:chartjs_docs/migrate/apexcharts/apex_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

// tooltip.y: {prefix: '$', suffix: 'k'}: the tooltip and the y labels.
String _dollars(num value) => '\$${apexNumber(value)}k';

List<String>? _dollarTick(Scale scale, double v, int i, List<Tick> t) => [
  _dollars(v),
];

ChartConfig _config(ApexZoom zoom) => ChartConfig(
  labels: const ['1', '2', '3', '4', '5', '6', '7', '8', '9'],
  datasets: const [
    LineDataset(
      label: 'Sales',
      data: .values([10, 41, 35, 51, 49, 62, 69, 91, 148]),
      // stroke: {curve: 'straight', width: 3}
      borderColor: .constant(.solid(Apex.blue)),
      backgroundColor: .constant(.solid(Apex.blue)),
      borderWidth: 3,
      borderJoinStyle: StrokeJoin.round,
      // markers: {size: 5}: a filled circle with a white ring.
      pointRadius: .constant(5),
      pointHoverRadius: .constant(5),
      pointBorderWidth: 2,
      pointBackgroundColor: .constant(.solid(Apex.blue)),
      pointBorderColor: .constant(.solid(Colors.white)),
      pointHoverBackgroundColor: .constant(.solid(Apex.blue)),
      pointHoverBorderColor: .constant(.solid(Colors.white)),
      extra: {'pointHoverBorderWidth': 2},
    ),
  ],
  maintainAspectRatio: false,
  padding: apexPadding,
  interaction: const ChartInteraction(
    mode: IndexInteractionMode(),
    intersect: false,
  ),
  animation: apexAnimation,
  plugins: apexZoomPlugins([apexHover, apexTooltipLook]),
  pluginOptions: [
    // One series: no legend, as in apexcharts_flutter.
    const LegendOptions(display: false),
    apexTooltip(value: _dollars),
    zoom.options,
  ],
  scales: [
    apexCategoryAxis(title: 'Week'),
    apexValueAxis(
      min: 0,
      max: 150,
      stepSize: 50,
      callback: _dollarTick,
      title: 'Revenue',
    ),
  ],
);

class const ApexLineMarkers({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const ApexZoomChart(
    config: _config,
    semanticLabel: 'Line chart of the weekly revenue',
  );
}
// #enddocregion apex-line-markers

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ApexLineMarkers(),
        ),
      ),
    ),
  );
}
