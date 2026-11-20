// Original code, not ported from Chart.js: a replica of the shadcn/ui demo "Bar Chart - Horizontal".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion shadcn-bar-horizontal
import 'package:chartjs_docs/migrate/shadcn/shadcn_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _months = ['January', 'February', 'March', 'April', 'May', 'June'];
const _desktop = <num>[186, 305, 237, 73, 209, 214];

ChartConfig _config(ShadcnTip tip) => ChartConfig(
  // layout="vertical": the months on the y axis.
  indexAxis: const YAxis(),
  labels: _months,
  datasets: const [
    BarDataset(
      label: 'Desktop',
      data: _desktop,
      backgroundColor: .constant(.solid(Shadcn.chart1)),
      hoverBackgroundColor: .constant(.solid(Shadcn.chart1)),
      borderRadius: 5,
      categoryPercentage: 0.8,
      barPercentage: 1,
      extra: {'borderSkipped': false},
    ),
  ],
  aspectRatio: 16 / 9,
  // margin={{left: -20}}: the other sides are 0.
  padding: EdgeInsets.zero,
  legend: shadcnNoLegend,
  tooltip: shadcnTooltip(
    tip,
    const ShadcnTooltipContent(hideLabel: true),
    true,
  ),
  interaction: shadcnInteraction(horizontal: true),
  animation: shadcnBarAnimation,
  scales: [
    // <YAxis dataKey="month" type="category" tickLine={false} tickMargin={10} axisLine={false} ...>:
    // 60 px less the margin of -20 px.
    shadcnCategoryYAxis(width: 40),
    // <XAxis type="number" dataKey="desktop" hide />, and no CartesianGrid.
    shadcnValueAxis(direction: .x, _desktop, grid: false),
  ],
);

class const ShadcnBarHorizontal({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const ShadcnCard(
    title: 'Bar Chart - Horizontal',
    chart: ShadcnChart(
      config: _config,
      semanticLabel: 'Horizontal bar chart of the desktop visitors',
    ),
  );
}
// #enddocregion shadcn-bar-horizontal

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ShadcnBarHorizontal(),
        ),
      ),
    ),
  );
}
