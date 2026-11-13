// Original code, not ported from Chart.js: fl_chart line sample 7.
// ignore_for_file: public_member_api_docs
// #docregion fl_chart-07
import 'package:chartjs_docs/migrate/fl_chart/fl_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

final ChartConfig _config = fills(
  ChartConfig(
    type: .line,
    labels: _months,
    datasets: [
      LineDataset(
        data: const [4, 3.5, 4.5, 1, 4, 6, 6.5, 6, 4, 6, 6, 7],
        tension: 0.35,
        borderWidth: 2,
        pointRadius: 0,
        borderColor: const .constant(.solid(Fl.green)),
        backgroundColor: .constant(.solid(Fl.red.withValues(alpha: 0.5))),
        fill: const ChartFill.dataset(1),
      ),
      const LineDataset(
        data: [7, 3, 4, 2, 3, 4, 5, 3, 1, 8, 1, 3],
        borderWidth: 2,
        pointRadius: 0,
        borderColor: .constant(.solid(Fl.red)),
      ),
    ],
    tooltip: const ChartTooltip(enabled: false),
    extra: const {'events': <String>[]},
    scales: {
      'x': const CategoryAxis(
        grid: AxisGrid(display: false),
        extra: Fl.noBorder,
        ticks: AxisTicks(
          maxRotation: 0,
          autoSkip: false,
          color: ChartPaint.solid(Colors.white),
          font: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
      'y': LinearAxis(
        min: 0,
        grid: flGrid(show: (v) => v == 1 || v == 4 || v == 5 || v == 6),
        extra: flGridDash,
        ticks: AxisTicks(
          stepSize: 1,
          autoSkip: false,
          color: const ChartPaint.solid(Colors.white),
          font: const TextStyle(fontSize: 10),
          format: (t) => '\$ ${t.value + 0.5}',
        ),
      ),
    },
  ),
);

class Sample7 extends StatelessWidget {
  const Sample7({super.key});
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 2,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 18, 4),
      child: ChartView(config: _config),
    ),
  );
}
// #enddocregion fl_chart-07
