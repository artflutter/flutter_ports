// Original code, not ported from Chart.js: a replica of the shadcn/ui demo "Bar Chart - Custom Label".
// ignore_for_file: public_member_api_docs
// #docregion shadcn-bar-label-custom
import 'package:chartjs_docs/migrate/shadcn/shadcn_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _months = ['January', 'February', 'March', 'April', 'May', 'June'];
const _desktop = <num>[186, 305, 237, 73, 209, 214];

ChartConfig _config(ShadcnTip tip) => ChartConfig(
  type: .bar,
  indexAxis: const YAxis(),
  labels: _months,
  datasets: const [
    // chartConfig gives the desktop bars --chart-2.
    BarDataset(
      label: 'Desktop',
      data: _desktop,
      backgroundColor: .constant(.solid(Shadcn.chart2)),
      hoverBackgroundColor: .constant(.solid(Shadcn.chart2)),
      borderRadius: 4,
      categoryPercentage: 0.8,
      barPercentage: 1,
      extra: {'borderSkipped': false},
    ),
  ],
  aspectRatio: 16 / 9,
  // margin={{right: 16}}
  padding: const EdgeInsets.only(right: 16),
  legend: shadcnNoLegend,
  // indicator="line" with one row: the month goes into the row.
  tooltip: shadcnTooltip(
    tip,
    const ShadcnTooltipContent(indicator: .line),
    true,
  ),
  interaction: shadcnInteraction(horizontal: true),
  animation: shadcnBarAnimation,
  plugins: [
    // <LabelList dataKey="month" position="insideLeft" offset={8} className="fill-(--color-label)" />
    shadcnLabels(
      id: 'months',
      position: .insideLeft,
      offset: 8,
      text: (i, value) => _months[i],
      color: (i) => Shadcn.background,
    ),
    // <LabelList dataKey="desktop" position="right" offset={8} className="fill-foreground" />
    shadcnLabels(id: 'values', position: .right, offset: 8),
  ],
  scales: {
    // <YAxis dataKey="month" type="category" hide />
    'y': shadcnCategoryYAxis(display: false),
    // <XAxis dataKey="desktop" type="number" hide />, and
    // <CartesianGrid horizontal={false} />: the vertical grid lines.
    'x': shadcnValueAxis(_desktop),
  },
);

class const ShadcnBarLabelCustom({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const ShadcnCard(
    title: 'Bar Chart - Custom Label',
    chart: ShadcnChart(
      config: _config,
      semanticLabel: 'Horizontal bar chart of the desktop visitors with labels',
    ),
  );
}
// #enddocregion shadcn-bar-label-custom

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ShadcnBarLabelCustom(),
        ),
      ),
    ),
  );
}
