// Original code, not ported from Chart.js: a replica of the shadcn/ui demo "Bar Chart - Multiple".
// ignore_for_file: public_member_api_docs
// #docregion shadcn-bar-multiple
import 'package:chartjs_docs/migrate/shadcn/shadcn_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _months = ['January', 'February', 'March', 'April', 'May', 'June'];
const _desktop = <num>[186, 305, 237, 73, 209, 214];
const _mobile = <num>[80, 200, 120, 190, 130, 140];

// <Bar dataKey={key} fill={color} radius={4} />
BarDataset _bars(String label, List<num> data, Color color) => BarDataset(
  label: label,
  data: data,
  backgroundColor: .constant(.solid(color)),
  hoverBackgroundColor: .constant(.solid(color)),
  borderRadius: 4,
  // The group takes 80 % of its band, with about 4 px (barGap) between
  // its two bars.
  categoryPercentage: 0.8,
  barPercentage: 0.92,
  extra: const {'borderSkipped': false},
);

ChartConfig _config(ShadcnTip tip) => ChartConfig(
  labels: _months,
  datasets: [
    _bars('Desktop', _desktop, Shadcn.chart1),
    _bars('Mobile', _mobile, Shadcn.chart2),
  ],
  aspectRatio: 16 / 9,
  padding: const EdgeInsets.all(5),
  legend: shadcnNoLegend,
  // <ChartTooltipContent indicator="dashed" />
  tooltip: shadcnTooltip(tip, const ShadcnTooltipContent(indicator: .dashed)),
  interaction: shadcnInteraction(),
  animation: shadcnBarAnimation,
  scales: [
    shadcnCategoryAxis(tickMargin: 10),
    shadcnValueAxis([..._desktop, ..._mobile]),
  ],
);

class const ShadcnBarMultiple({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const ShadcnCard(
    title: 'Bar Chart - Multiple',
    chart: ShadcnChart(
      config: _config,
      semanticLabel: 'Bar chart of the desktop and the mobile visitors',
    ),
  );
}
// #enddocregion shadcn-bar-multiple

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ShadcnBarMultiple(),
        ),
      ),
    ),
  );
}
