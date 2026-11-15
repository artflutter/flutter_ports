// Original code, not ported from Chart.js: a replica of the shadcn/ui demo "Bar Chart".
// ignore_for_file: public_member_api_docs
// #docregion shadcn-bar-default
import 'package:chartjs_docs/migrate/shadcn/shadcn_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _months = ['January', 'February', 'March', 'April', 'May', 'June'];
const _desktop = <num>[186, 305, 237, 73, 209, 214];

ChartConfig _config(ShadcnTip tip) => ChartConfig(
  type: .bar,
  labels: _months,
  datasets: const [
    // <Bar dataKey="desktop" fill="var(--color-desktop)" radius={8} />
    BarDataset(
      label: 'Desktop',
      data: _desktop,
      backgroundColor: .constant(.solid(Shadcn.chart1)),
      // No change on a hover.
      hoverBackgroundColor: .constant(.solid(Shadcn.chart1)),
      // radius={8} rounds the four corners.
      borderRadius: 8,
      // barCategoryGap="10%": the bar takes 80 % of its band.
      categoryPercentage: 0.8,
      barPercentage: 1,
      extra: {'borderSkipped': false},
    ),
  ],
  // The 16:9 of ChartContainer, and the default margin of 5 px.
  aspectRatio: 16 / 9,
  padding: const EdgeInsets.all(5),
  legend: shadcnNoLegend,
  // <ChartTooltip cursor={false} content={<ChartTooltipContent hideLabel />} />
  tooltip: shadcnTooltip(tip, const ShadcnTooltipContent(hideLabel: true)),
  interaction: shadcnInteraction(),
  animation: shadcnBarAnimation,
  scales: {
    'x': shadcnCategoryAxis(tickMargin: 10),
    'y': shadcnValueAxis(_desktop),
  },
);

class const ShadcnBarDefault({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const ShadcnCard(
    title: 'Bar Chart',
    chart: ShadcnChart(
      config: _config,
      semanticLabel: 'Bar chart of the desktop visitors from January to June',
    ),
  );
}
// #enddocregion shadcn-bar-default

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ShadcnBarDefault(),
        ),
      ),
    ),
  );
}
