// Original code, not ported from Chart.js: a replica of the apexcharts_flutter demo "Line — zoomable timeseries (drag / wheel to zoom)".
// ignore_for_file: public_member_api_docs
// #docregion apex-line-timeseries
import 'package:chartjs_docs/migrate/apexcharts/apex_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

// The visitors of 40 days from 1 January 2024, by the formula of the demo.
final List<DataPoint> _visitors = [
  for (var d = 0; d < 40; d++)
    DataPoint.time(
      DateTime.fromMillisecondsSinceEpoch(1704067200000 + d * 86400000),
      (30 + 35 * (0.5 + 0.5 * (d % 7 == 0 ? 1.0 : (d % 5) / 5.0)) + d * 1.4)
          .roundToDouble(),
    ),
];

ChartConfig _config(ApexZoom zoom) => ChartConfig(
  datasets: [
    LineDataset(
      label: 'Visitors',
      points: _visitors,
      borderColor: const .constant(.solid(Apex.purple)),
      backgroundColor: const .constant(.solid(Apex.purple)),
      borderWidth: 3,
      borderJoinStyle: StrokeJoin.round,
      // stroke: {curve: 'smooth'}
      tension: 0.4,
      pointRadius: 0,
      pointHoverRadius: 0,
    ),
  ],
  maintainAspectRatio: false,
  padding: apexPadding,
  legend: const ChartLegend(display: false),
  tooltip: apexTooltip(),
  interaction: const ChartInteraction(
    mode: IndexInteractionMode(),
    intersect: false,
  ),
  animation: apexAnimation,
  plugins: apexZoomPlugins([apexHover, apexTooltipLook]),
  pluginOptions: [zoom.options],
  scales: {
    // xaxis: {type: 'datetime'}: a tick at the start of a day, 'dd MMM'.
    'x': const TimeAxis(
      unit: .day,
      tooltipFormat: 'd MMM',
      grid: AxisGrid(display: false, drawTicks: false),
      ticks: AxisTicks(
        color: .solid(Apex.label),
        font: apexLabelFont,
        padding: 8,
        maxRotation: 0,
      ),
      border: AxisBorder(display: false),
      extra: {
        'time': {
          'displayFormats': {'day': 'dd MMM'},
        },
      },
    ),
    'y': apexValueAxis(min: 40, max: 120, stepSize: 20),
  },
);

class const ApexLineTimeseries({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const ApexZoomChart(
    config: _config,
    semanticLabel: 'Line chart of the visitors of 40 days',
  );
}
// #enddocregion apex-line-timeseries

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ApexLineTimeseries(),
        ),
      ),
    ),
  );
}
