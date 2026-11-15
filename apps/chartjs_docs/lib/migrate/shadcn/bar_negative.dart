// Original code, not ported from Chart.js: a replica of the shadcn/ui demo "Bar Chart - Negative".
// ignore_for_file: public_member_api_docs
// #docregion shadcn-bar-negative
import 'package:chartjs_docs/migrate/shadcn/shadcn_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _months = ['January', 'February', 'March', 'April', 'May', 'June'];
const _visitors = <num>[186, 205, -207, 173, -209, 214];

// <Cell fill={item.visitors > 0 ? "var(--chart-1)" : "var(--chart-2)"} />
Color _colorOf(int i) => _visitors[i] > 0 ? Shadcn.chart1 : Shadcn.chart2;

final List<ChartPaint> _fills = [
  for (var i = 0; i < _visitors.length; i++) .solid(_colorOf(i)),
];

ChartConfig _config(ShadcnTip tip) => ChartConfig(
  type: .bar,
  labels: _months,
  datasets: [
    BarDataset(
      label: 'Visitors',
      data: _visitors,
      backgroundColor: .indexed(_fills),
      hoverBackgroundColor: .indexed(_fills),
      categoryPercentage: 0.8,
      barPercentage: 1,
    ),
  ],
  aspectRatio: 16 / 9,
  padding: const EdgeInsets.all(5),
  legend: shadcnNoLegend,
  // <ChartTooltipContent hideLabel hideIndicator />
  tooltip: shadcnTooltip(
    tip,
    const ShadcnTooltipContent(hideLabel: true, hideIndicator: true),
  ),
  interaction: shadcnInteraction(),
  animation: shadcnBarAnimation,
  // <LabelList position="top" dataKey="month" fillOpacity={1} />: the month
  // 5 px above a bar, or under a bar below 0, in the color of the bar.
  plugins: [
    shadcnLabels(
      id: 'months',
      offset: 5,
      text: (i, value) => _months[i],
      color: _colorOf,
    ),
  ],
  // No XAxis.
  scales: {
    'x': shadcnCategoryAxis(display: false),
    'y': shadcnValueAxis(_visitors),
  },
);

class const ShadcnBarNegative({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const ShadcnCard(
    title: 'Bar Chart - Negative',
    chart: ShadcnChart(
      config: _config,
      semanticLabel: 'Bar chart of the visitors with values below 0',
    ),
  );
}
// #enddocregion shadcn-bar-negative

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ShadcnBarNegative(),
        ),
      ),
    ),
  );
}
