// Original code, not ported from Chart.js: a replica of the shadcn/ui demo "Bar Chart - Label".
// ignore_for_file: public_member_api_docs
// #docregion shadcn-bar-label
import 'package:chartjs_docs/migrate/shadcn/shadcn_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _months = ['January', 'February', 'March', 'April', 'May', 'June'];
const _desktop = <num>[186, 305, 237, 73, 209, 214];

ChartConfig _config(ShadcnTip tip) => ChartConfig(
  labels: _months,
  datasets: const [
    BarDataset(
      label: 'Desktop',
      data: _desktop,
      backgroundColor: .constant(.solid(Shadcn.chart1)),
      hoverBackgroundColor: .constant(.solid(Shadcn.chart1)),
      borderRadius: 8,
      categoryPercentage: 0.8,
      barPercentage: 1,
      extra: {'borderSkipped': false},
    ),
  ],
  aspectRatio: 16 / 9,
  // margin={{top: 20}}: room for the labels, and 0 on the other sides.
  padding: const EdgeInsets.only(top: 20),
  legend: shadcnNoLegend,
  tooltip: shadcnTooltip(tip, const ShadcnTooltipContent(hideLabel: true)),
  interaction: shadcnInteraction(),
  animation: shadcnBarAnimation,
  // <LabelList position="top" offset={12} className="fill-foreground" fontSize={12} />
  plugins: [shadcnLabels(id: 'values')],
  scales: [shadcnCategoryAxis(tickMargin: 10), shadcnValueAxis(_desktop)],
);

class const ShadcnBarLabel({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const ShadcnCard(
    title: 'Bar Chart - Label',
    chart: ShadcnChart(
      config: _config,
      semanticLabel: 'Bar chart of the desktop visitors with the values',
    ),
  );
}
// #enddocregion shadcn-bar-label

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ShadcnBarLabel(),
        ),
      ),
    ),
  );
}
