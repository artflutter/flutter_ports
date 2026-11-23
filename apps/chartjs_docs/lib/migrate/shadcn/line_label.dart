// Original code, not ported from Chart.js: a replica of the shadcn/ui demo "Line Chart - Label".
// ignore_for_file: public_member_api_docs
// #docregion shadcn-line-label
import 'package:chartjs_docs/migrate/shadcn/shadcn_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _months = ['January', 'February', 'March', 'April', 'May', 'June'];
const _desktop = <num>[186, 305, 237, 73, 209, 214];

ChartConfig _config(ShadcnTip tip) => ChartConfig(
  labels: _months,
  datasets: const [
    LineDataset(
      label: 'Desktop',
      data: _desktop,
      cubicInterpolationMode: NaturalCurve(),
      borderColor: .constant(.solid(Shadcn.chart1)),
      borderWidth: 2,
      // Recharts draws the line and the dots past the edges of the plot.
      clip: ChartClip.none,
      pointRadius: .constant(3),
      pointBorderWidth: 2,
      pointBackgroundColor: .constant(.solid(Shadcn.chart1)),
      pointBorderColor: .constant(.solid(Shadcn.chart1)),
      pointHoverRadius: .constant(6),
      pointHoverBackgroundColor: .constant(.solid(Shadcn.chart1)),
      pointHoverBorderColor: .constant(.solid(Shadcn.chart1)),
      extra: {'pointHoverBorderWidth': 0, 'capBezierPoints': false},
    ),
  ],
  aspectRatio: 16 / 9,
  // margin={{top: 20, left: 12, right: 12}}: room for the labels.
  padding: const EdgeInsets.fromLTRB(12, 20, 12, 0),
  legend: shadcnNoLegend,
  // indicator="line" with one row: the month goes into the row.
  tooltip: shadcnTooltip(tip, const ShadcnTooltipContent(indicator: .line)),
  interaction: shadcnInteraction(),
  animation: shadcnLineAnimation,
  // <LabelList position="top" offset={12} className="fill-foreground" fontSize={12} />
  plugins: [shadcnLabels(id: 'values')],
  scales: [shadcnCategoryAxis(), shadcnValueAxis(_desktop)],
);

class const ShadcnLineLabel({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const ShadcnCard(
    title: 'Line Chart - Label',
    chart: ShadcnChart(
      config: _config,
      semanticLabel: 'Line chart of the desktop visitors with the values',
    ),
  );
}
// #enddocregion shadcn-line-label

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ShadcnLineLabel(),
        ),
      ),
    ),
  );
}
