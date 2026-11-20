// Original code, not ported from Chart.js: a replica of the apexcharts_flutter demo "Bar — grouped (data labels)".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion apex-bar-grouped
import 'package:chartjs_docs/migrate/apexcharts/apex_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

BarDataset _series(String name, Color color, List<num> values) => BarDataset(
  label: name,
  data: values,
  backgroundColor: .constant(.solid(color)),
  hoverBackgroundColor: .constant(.solid(color)),
  borderWidth: 0,
  // plotOptions.bar.columnWidth: '70%': the group takes 70 % of its band,
  // and the columns of a group touch.
  categoryPercentage: 0.7,
  barPercentage: 1,
);

final ChartConfig _config = ChartConfig(
  labels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
  datasets: [
    _series('2023', Apex.blue, const [44, 55, 57, 56, 61, 58]),
    _series('2024', Apex.green, const [76, 85, 101, 98, 87, 105]),
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
  plugins: [apexDataLabels(), apexHover, apexTooltipLook],
  scales: [apexCategoryAxis(), apexValueAxis(min: 0, max: 120, stepSize: 20)],
);

class const ApexBarGrouped({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 320,
    child: ChartView(
      config: _config,
      semanticLabel: 'Grouped column chart of 2023 and 2024',
    ),
  );
}
// #enddocregion apex-bar-grouped

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ApexBarGrouped(),
        ),
      ),
    ),
  );
}
