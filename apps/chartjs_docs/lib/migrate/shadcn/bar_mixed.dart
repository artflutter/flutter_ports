// Original code, not ported from Chart.js: a replica of the shadcn/ui demo "Bar Chart - Mixed".
// ignore_for_file: public_member_api_docs
// #docregion shadcn-bar-mixed
import 'package:chartjs_docs/migrate/shadcn/shadcn_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

// chartData: the browser (its label in chartConfig), its visitors and its
// `fill`.
const _browsers = ['Chrome', 'Safari', 'Firefox', 'Edge', 'Other'];
const _visitors = <num>[275, 200, 187, 173, 90];
const _fills = <ChartPaint>[
  .solid(Shadcn.chart1),
  .solid(Shadcn.chart2),
  .solid(Shadcn.chart3),
  .solid(Shadcn.chart4),
  .solid(Shadcn.chart5),
];

ChartConfig _config(ShadcnTip tip) => ChartConfig(
  type: .bar,
  indexAxis: const YAxis(),
  labels: _browsers,
  datasets: const [
    // <Bar dataKey="visitors" radius={5} />: each bar takes its `fill`.
    BarDataset(
      label: 'Visitors',
      data: _visitors,
      backgroundColor: .indexed(_fills),
      hoverBackgroundColor: .indexed(_fills),
      borderRadius: 5,
      categoryPercentage: 0.8,
      barPercentage: 1,
      extra: {'borderSkipped': false},
    ),
  ],
  aspectRatio: 16 / 9,
  // margin={{left: 0}}: 0 on each side.
  padding: EdgeInsets.zero,
  legend: shadcnNoLegend,
  tooltip: shadcnTooltip(
    tip,
    const ShadcnTooltipContent(hideLabel: true),
    true,
  ),
  interaction: shadcnInteraction(horizontal: true),
  animation: shadcnBarAnimation,
  scales: {
    // The tickFormatter gives the label of chartConfig: the whole name.
    'y': shadcnCategoryYAxis(callback: null),
    'x': shadcnValueAxis(_visitors, grid: false),
  },
);

class const ShadcnBarMixed({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const ShadcnCard(
    title: 'Bar Chart - Mixed',
    chart: ShadcnChart(
      config: _config,
      semanticLabel: 'Horizontal bar chart of the visitors of each browser',
    ),
  );
}
// #enddocregion shadcn-bar-mixed

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ShadcnBarMixed(),
        ),
      ),
    ),
  );
}
