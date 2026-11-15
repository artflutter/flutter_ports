// Original code, not ported from Chart.js: a replica of the apexcharts_flutter demo "Line — multi-series".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion apex-line-multi
import 'package:chartjs_docs/migrate/apexcharts/apex_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

LineDataset _series(String name, Color color, List<num> values) => LineDataset(
  label: name,
  data: values,
  borderColor: .constant(.solid(color)),
  // The legend takes this color.
  backgroundColor: .constant(.solid(color)),
  borderWidth: 3,
  borderJoinStyle: StrokeJoin.round,
  // No markers: the hover marker of `apexHover` shows the points.
  pointRadius: 0,
  pointHoverRadius: 0,
);

ChartConfig _config(ApexZoom zoom) => ChartConfig(
  type: .line,
  labels: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
  datasets: [
    _series('Team A', Apex.blue, const [31, 40, 28, 51, 42, 109, 100]),
    _series('Team B', Apex.green, const [11, 32, 45, 32, 34, 52, 41]),
    _series('Team C', Apex.yellow, const [15, 11, 32, 18, 9, 24, 11]),
  ],
  maintainAspectRatio: false,
  padding: apexPadding.copyWith(bottom: 0),
  legend: apexLegend,
  tooltip: apexTooltip(),
  interaction: const ChartInteraction(
    mode: IndexInteractionMode(),
    intersect: false,
  ),
  animation: apexAnimation,
  plugins: apexZoomPlugins([apexHover, apexTooltipLook]),
  pluginOptions: [zoom.options],
  scales: {
    'x': apexCategoryAxis(),
    'y': apexValueAxis(min: 0, max: 120, stepSize: 20),
  },
);

class const ApexLineMulti({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const ApexZoomChart(
    config: _config,
    semanticLabel: 'Line chart of three teams over a week',
  );
}
// #enddocregion apex-line-multi
