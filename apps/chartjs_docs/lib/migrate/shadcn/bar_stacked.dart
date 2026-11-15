// Original code, not ported from Chart.js: a replica of the shadcn/ui demo "Bar Chart - Stacked + Legend".
// ignore_for_file: public_member_api_docs
// #docregion shadcn-bar-stacked
import 'package:chartjs_docs/migrate/shadcn/shadcn_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _months = ['January', 'February', 'March', 'April', 'May', 'June'];
const _desktop = <num>[186, 305, 237, 73, 209, 214];
const _mobile = <num>[80, 200, 120, 190, 130, 140];

// <Bar dataKey={key} stackId="a" fill={color} radius={corners} />: the
// corners are an object of Chart.js.
BarDataset _bars(
  String label,
  List<num> data,
  Color color,
  Map<String, double> corners,
) => BarDataset(
  label: label,
  data: data,
  backgroundColor: .constant(.solid(color)),
  hoverBackgroundColor: .constant(.solid(color)),
  categoryPercentage: 0.8,
  barPercentage: 1,
  extra: {'borderRadius': corners, 'borderSkipped': false},
);

ChartConfig _config(ShadcnTip tip) => ChartConfig(
  type: .bar,
  labels: _months,
  datasets: [
    // radius={[0, 0, 4, 4]}: the bottom corners of the lower bar.
    _bars('Desktop', _desktop, Shadcn.chart1, {
      'bottomLeft': 4,
      'bottomRight': 4,
    }),
    // radius={[4, 4, 0, 0]}: the top corners of the upper bar.
    _bars('Mobile', _mobile, Shadcn.chart2, {'topLeft': 4, 'topRight': 4}),
  ],
  aspectRatio: 16 / 9,
  padding: const EdgeInsets.all(5),
  // <ChartLegend content={<ChartLegendContent />} />
  legend: shadcnLegend,
  // <ChartTooltip content={<ChartTooltipContent hideLabel />} />, with the
  // cursor: a muted band under the hovered month.
  tooltip: shadcnTooltip(tip, const ShadcnTooltipContent(hideLabel: true)),
  interaction: shadcnInteraction(),
  animation: shadcnBarAnimation,
  plugins: [shadcnCursor],
  scales: {
    'x': shadcnCategoryAxis(tickMargin: 10, stacked: true),
    'y': shadcnValueAxis([
      for (var i = 0; i < _desktop.length; i++) _desktop[i] + _mobile[i],
    ], stacked: true),
  },
);

class const ShadcnBarStacked({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const ShadcnCard(
    title: 'Bar Chart - Stacked + Legend',
    chart: ShadcnChart(
      config: _config,
      semanticLabel: 'Stacked bar chart of the desktop and the mobile visitors',
    ),
  );
}
// #enddocregion shadcn-bar-stacked

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ShadcnBarStacked(),
        ),
      ),
    ),
  );
}
