// Original code, not ported from Chart.js: a replica of the shadcn/ui demo "Line Chart - Step".
// ignore_for_file: public_member_api_docs
// #docregion shadcn-line-step
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
      data: .values(_desktop),
      // type="step": the step is halfway between two points.
      stepped: SteppedLine.middle,
      borderColor: .constant(.solid(Shadcn.chart1)),
      borderWidth: 2,
      // Recharts draws the line and the dots past the edges of the plot.
      clip: ChartClip.none,
      pointRadius: .constant(0),
      pointHoverRadius: .constant(4),
      pointBackgroundColor: .constant(.solid(Shadcn.chart1)),
      pointHoverBackgroundColor: .constant(.solid(Shadcn.chart1)),
      pointHoverBorderWidth: .constant(0),
    ),
  ],
  aspectRatio: 16 / 9,
  padding: const EdgeInsets.symmetric(horizontal: 12),
  pluginOptions: [
    shadcnNoLegend,
    shadcnTooltip(tip, const ShadcnTooltipContent(hideLabel: true)),
  ],
  interaction: shadcnInteraction(),
  animation: shadcnLineAnimation,
  scales: [shadcnCategoryAxis(), shadcnValueAxis(_desktop)],
);

class const ShadcnLineStep({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const ShadcnCard(
    title: 'Line Chart - Step',
    chart: ShadcnChart(
      config: _config,
      semanticLabel: 'Step line chart of the desktop visitors',
    ),
  );
}
// #enddocregion shadcn-line-step

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ShadcnLineStep(),
        ),
      ),
    ),
  );
}
