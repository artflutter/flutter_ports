// Original code, not ported from Chart.js: a replica of the shadcn/ui demo "Line Chart - Multiple".
// ignore_for_file: public_member_api_docs
// #docregion shadcn-line-multiple
import 'package:chartjs_docs/migrate/shadcn/shadcn_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _months = ['January', 'February', 'March', 'April', 'May', 'June'];
const _desktop = <num>[186, 305, 237, 73, 209, 214];
const _mobile = <num>[80, 200, 120, 190, 130, 140];

// <Line dataKey={key} type="monotone" stroke={color} strokeWidth={2} dot={false} />
LineDataset _line(String label, List<num> data, Color color) => LineDataset(
  label: label,
  data: .values(data),
  cubicInterpolationMode: const MonotoneXCurve(),
  borderColor: .constant(.solid(color)),
  borderWidth: 2,
  // Recharts draws the line and the dots past the edges of the plot.
  clip: ChartClip.none,
  pointRadius: const .constant(0),
  pointHoverRadius: const .constant(4),
  pointBackgroundColor: .constant(.solid(color)),
  pointHoverBackgroundColor: .constant(.solid(color)),
  extra: const {'pointHoverBorderWidth': 0, 'capBezierPoints': false},
);

ChartConfig _config(ShadcnTip tip) => ChartConfig(
  labels: _months,
  datasets: [
    _line('Desktop', _desktop, Shadcn.chart1),
    _line('Mobile', _mobile, Shadcn.chart2),
  ],
  aspectRatio: 16 / 9,
  padding: const EdgeInsets.symmetric(horizontal: 12),
  // <ChartTooltipContent />: the month, then one row for each line.
  pluginOptions: [shadcnTooltip(tip), shadcnNoLegend],
  interaction: shadcnInteraction(),
  animation: shadcnLineAnimation,
  scales: [
    shadcnCategoryAxis(),
    shadcnValueAxis([..._desktop, ..._mobile]),
  ],
);

class const ShadcnLineMultiple({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const ShadcnCard(
    title: 'Line Chart - Multiple',
    chart: ShadcnChart(
      config: _config,
      semanticLabel: 'Line chart of the desktop and the mobile visitors',
    ),
  );
}
// #enddocregion shadcn-line-multiple

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ShadcnLineMultiple(),
        ),
      ),
    ),
  );
}
