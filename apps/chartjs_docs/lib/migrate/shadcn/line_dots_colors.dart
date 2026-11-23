// Original code, not ported from Chart.js: a replica of the shadcn/ui demo "Line Chart - Dots Colors".
// ignore_for_file: public_member_api_docs
// #docregion shadcn-line-dots-colors
import 'package:chartjs_docs/migrate/shadcn/shadcn_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

// chartData: the browser, its visitors and its `fill`.
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
  labels: _browsers,
  datasets: const [
    LineDataset(
      label: 'Visitors',
      data: _visitors,
      cubicInterpolationMode: NaturalCurve(),
      borderColor: .constant(.solid(Shadcn.chart2)),
      borderWidth: 2,
      // Recharts draws the line and the dots past the edges of the plot.
      clip: ChartClip.none,
      // <Dot r={5} fill={payload.fill} stroke={payload.fill} />: the color
      // of each browser, with a 1 px stroke.
      pointRadius: .constant(5),
      pointBorderWidth: 1,
      pointBackgroundColor: .indexed(_fills),
      pointBorderColor: .indexed(_fills),
      // The active dot of Recharts (4 px, the line color) over the dot:
      // a 1.5 px ring of the browser color stays around it.
      pointHoverRadius: .constant(4.75),
      pointHoverBackgroundColor: .constant(.solid(Shadcn.chart2)),
      pointHoverBorderColor: .indexed(_fills),
      extra: {'pointHoverBorderWidth': 1.5, 'capBezierPoints': false},
    ),
  ],
  aspectRatio: 16 / 9,
  // margin={{top: 24, left: 24, right: 24}}
  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
  legend: shadcnNoLegend,
  tooltip: shadcnTooltip(
    tip,
    const ShadcnTooltipContent(
      indicator: .line,
      name: 'Visitors',
      hideLabel: true,
    ),
  ),
  interaction: shadcnInteraction(),
  animation: shadcnLineAnimation,
  // No XAxis: the points go from the left to the right edge of the plot.
  scales: [shadcnCategoryAxis(display: false), shadcnValueAxis(_visitors)],
);

class const ShadcnLineDotsColors({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const ShadcnCard(
    title: 'Line Chart - Dots Colors',
    chart: ShadcnChart(
      config: _config,
      semanticLabel: 'Line chart of the visitors of each browser',
    ),
  );
}
// #enddocregion shadcn-line-dots-colors

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ShadcnLineDotsColors(),
        ),
      ),
    ),
  );
}
