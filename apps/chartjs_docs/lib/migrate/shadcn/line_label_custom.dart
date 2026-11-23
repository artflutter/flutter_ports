// Original code, not ported from Chart.js: a replica of the shadcn/ui demo "Line Chart - Custom Label".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion shadcn-line-label-custom
import 'package:chartjs_docs/migrate/shadcn/shadcn_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

// The labels of chartConfig in place of the keys "chrome", "safari", ...
const _browsers = ['Chrome', 'Safari', 'Firefox', 'Edge', 'Other'];
const _visitors = <num>[275, 200, 187, 173, 90];

ChartConfig _config(ShadcnTip tip) => ChartConfig(
  labels: _browsers,
  datasets: const [
    LineDataset(
      label: 'Visitors',
      data: .values(_visitors),
      cubicInterpolationMode: NaturalCurve(),
      borderColor: .constant(.solid(Shadcn.chart2)),
      borderWidth: 2,
      // Recharts draws the line and the dots past the edges of the plot.
      clip: ChartClip.none,
      pointRadius: .constant(3),
      pointBorderWidth: 2,
      pointBackgroundColor: .constant(.solid(Shadcn.chart2)),
      pointBorderColor: .constant(.solid(Shadcn.chart2)),
      pointHoverRadius: .constant(6),
      pointHoverBackgroundColor: .constant(.solid(Shadcn.chart2)),
      pointHoverBorderColor: .constant(.solid(Shadcn.chart2)),
      extra: {'pointHoverBorderWidth': 0, 'capBezierPoints': false},
    ),
  ],
  aspectRatio: 16 / 9,
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
  // <LabelList dataKey="browser" formatter={(value) => chartConfig[value]?.label} ...>
  plugins: [shadcnLabels(id: 'browsers', text: (i, value) => _browsers[i])],
  scales: [shadcnCategoryAxis(display: false), shadcnValueAxis(_visitors)],
);

class const ShadcnLineLabelCustom({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const ShadcnCard(
    title: 'Line Chart - Custom Label',
    chart: ShadcnChart(
      config: _config,
      semanticLabel: 'Line chart of the visitors with the browser names',
    ),
  );
}
// #enddocregion shadcn-line-label-custom

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ShadcnLineLabelCustom(),
        ),
      ),
    ),
  );
}
