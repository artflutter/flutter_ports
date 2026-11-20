// Original code, not ported from Chart.js: a replica of the shadcn/ui demo "Line Chart".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion shadcn-line-default
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
      // <Line type="natural" stroke="var(--color-desktop)" strokeWidth={2}>
      cubicInterpolationMode: NaturalCurve(),
      borderColor: .constant(.solid(Shadcn.chart1)),
      borderWidth: 2,
      // Recharts draws the line and the dots past the edges of the plot.
      clip: ChartClip.none,
      // dot={false}, and the active dot of Recharts on a hover: 4 px.
      pointRadius: 0,
      pointHoverRadius: 4,
      pointBackgroundColor: .constant(.solid(Shadcn.chart1)),
      pointHoverBackgroundColor: .constant(.solid(Shadcn.chart1)),
      extra: {'pointHoverBorderWidth': 0, 'capBezierPoints': false},
    ),
  ],
  // The 16:9 of ChartContainer, and margin={{left: 12, right: 12}}.
  aspectRatio: 16 / 9,
  padding: const EdgeInsets.symmetric(horizontal: 12),
  legend: shadcnNoLegend,
  // <ChartTooltip cursor={false} content={<ChartTooltipContent hideLabel />} />
  tooltip: shadcnTooltip(tip, const ShadcnTooltipContent(hideLabel: true)),
  interaction: shadcnInteraction(),
  animation: shadcnLineAnimation,
  scales: [
    // <XAxis dataKey="month" tickLine={false} axisLine={false} tickMargin={8} ...>
    shadcnCategoryAxis(),
    // <CartesianGrid vertical={false} />
    shadcnValueAxis(_desktop),
  ],
);

class const ShadcnLineDefault({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const ShadcnCard(
    title: 'Line Chart',
    chart: ShadcnChart(
      config: _config,
      semanticLabel: 'Line chart of the desktop visitors from January to June',
    ),
  );
}
// #enddocregion shadcn-line-default

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ShadcnLineDefault(),
        ),
      ),
    ),
  );
}
