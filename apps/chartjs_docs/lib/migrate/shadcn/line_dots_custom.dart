// Original code, not ported from Chart.js: a replica of the shadcn/ui demo "Line Chart - Custom Dots".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion shadcn-line-dots-custom
import 'package:chartjs_docs/migrate/shadcn/shadcn_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _months = ['January', 'February', 'March', 'April', 'May', 'June'];
const _desktop = <num>[186, 305, 237, 73, 209, 214];

/// The icon `GitCommitVertical` of lucide as a point style: a circle of a
/// quarter of the point radius, and a line above and under it. The point options
/// give the fill (the inside of the circle), the stroke and its width.
final class const GitCommitVertical() extends PointStyle {
  @override
  void draw(
    CanvasRenderingContext2D ctx, {
    required double x,
    required double y,
    required double radius,
    required double rad,
    required bool rotated,
    required double? width,
    required double borderWidth,
  }) {
    final r = radius / 4;
    ctx
      ..beginPath()
      ..arc(x, y, r, 0, 2 * 3.141592653589793)
      ..fill()
      ..stroke()
      ..beginPath()
      ..moveTo(x, y - 3 * r)
      ..lineTo(x, y - r)
      ..moveTo(x, y + r)
      ..lineTo(x, y + 3 * r)
      ..stroke();
  }
}

ChartConfig _config(ShadcnTip tip) => ChartConfig(
  labels: _months,
  datasets: const [
    LineDataset(
      label: 'Desktop',
      data: .values(_desktop),
      cubicInterpolationMode: NaturalCurve(),
      borderColor: .constant(.solid(Shadcn.chart1)),
      borderWidth: 2,
      // Recharts draws the line and the dots past the edges of the plot.
      clip: ChartClip.none,
      // The dot function draws the icon 24 px wide at each point, with the
      // background color inside and the line color around.
      pointStyle: .constant(GitCommitVertical()),
      pointRadius: .constant(12),
      pointBorderWidth: 2,
      pointBackgroundColor: .constant(.solid(Shadcn.background)),
      pointBorderColor: .constant(.solid(Shadcn.chart1)),
      // The active dot of Recharts fills the circle with the line color.
      pointHoverRadius: .constant(12),
      pointHoverBackgroundColor: .constant(.solid(Shadcn.chart1)),
      pointHoverBorderColor: .constant(.solid(Shadcn.chart1)),
      extra: {'pointHoverBorderWidth': 2, 'capBezierPoints': false},
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

class const ShadcnLineDotsCustom({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const ShadcnCard(
    title: 'Line Chart - Custom Dots',
    chart: ShadcnChart(
      config: _config,
      semanticLabel: 'Line chart of the desktop visitors with icon dots',
    ),
  );
}
// #enddocregion shadcn-line-dots-custom

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ShadcnLineDotsCustom(),
        ),
      ),
    ),
  );
}
