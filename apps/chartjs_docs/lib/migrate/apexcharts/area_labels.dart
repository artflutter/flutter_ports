// Original code, not ported from Chart.js: a replica of the apexcharts_flutter demo "Area — with data labels".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion apex-area-labels
import 'package:chartjs_docs/migrate/apexcharts/apex_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

ChartConfig _config(ApexZoom zoom) => ChartConfig(
  type: .line,
  labels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug'],
  datasets: [
    LineDataset(
      label: 'Revenue',
      data: const [12, 18, 14, 26, 31, 28, 40, 52],
      borderColor: const .constant(.solid(Apex.green)),
      // chart.type: 'area': the default gradient of an area.
      backgroundColor: apexAreaFill(Apex.green),
      fill: .toStart,
      borderWidth: 2,
      borderJoinStyle: StrokeJoin.round,
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
  plugins: apexZoomPlugins([apexDataLabels(), apexHover, apexTooltipLook]),
  pluginOptions: [zoom.options],
  scales: {
    'x': apexCategoryAxis(),
    'y': apexValueAxis(min: 10, max: 60, stepSize: 10),
  },
);

class const ApexAreaLabels({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const ApexZoomChart(
    config: _config,
    semanticLabel: 'Area chart of the monthly revenue, with the values',
  );
}
// #enddocregion apex-area-labels
