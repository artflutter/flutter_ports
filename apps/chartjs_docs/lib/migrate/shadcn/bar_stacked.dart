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
// corners are the per-corner form of Chart.js, a BorderRadius.
BarDataset _bars(
  String label,
  List<num> data,
  Color color,
  BorderRadius corners,
) => BarDataset(
  label: label,
  data: .values(data),
  backgroundColor: .constant(.solid(color)),
  hoverBackgroundColor: .constant(.solid(color)),
  categoryPercentage: 0.8,
  barPercentage: 1,
  borderSkipped: BorderSkip.none,
  borderRadiusCorners: corners,
);

ChartConfig _config(ShadcnTip tip) => ChartConfig(
  labels: _months,
  datasets: [
    // radius={[0, 0, 4, 4]}: the bottom corners of the lower bar.
    _bars(
      'Desktop',
      _desktop,
      Shadcn.chart1,
      const BorderRadius.vertical(bottom: Radius.circular(4)),
    ),
    // radius={[4, 4, 0, 0]}: the top corners of the upper bar.
    _bars(
      'Mobile',
      _mobile,
      Shadcn.chart2,
      const BorderRadius.vertical(top: Radius.circular(4)),
    ),
  ],
  aspectRatio: 16 / 9,
  padding: const EdgeInsets.all(5),
  pluginOptions: [
    // <ChartTooltip content={<ChartTooltipContent hideLabel />} />, with the
    // cursor: a muted band under the hovered month.
    shadcnTooltip(tip, const ShadcnTooltipContent(hideLabel: true)),
    // <ChartLegend content={<ChartLegendContent />} />
    shadcnLegend,
  ],
  interaction: shadcnInteraction(),
  animation: shadcnBarAnimation,
  plugins: [shadcnCursor],
  scales: [
    shadcnCategoryAxis(tickMargin: 10, stacked: true),
    shadcnValueAxis([
      for (var i = 0; i < _desktop.length; i++) _desktop[i] + _mobile[i],
    ], stacked: true),
  ],
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
