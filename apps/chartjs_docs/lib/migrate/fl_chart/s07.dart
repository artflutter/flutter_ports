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
    labels: _months,
    datasets: [
      LineDataset(
        data: const .values([4, 3.5, 4.5, 1, 4, 6, 6.5, 6, 4, 6, 6, 7]),
        tension: 0.35,
        borderWidth: 2,
        pointRadius: const .constant(0),
        borderColor: const .constant(.solid(Fl.green)),
        backgroundColor: .constant(.solid(Fl.red.withValues(alpha: 0.5))),
        fill: const FillTarget.toDataset(1),
      ),
      const LineDataset(
        data: .values([7, 3, 4, 2, 3, 4, 5, 3, 1, 8, 1, 3]),
        borderWidth: 2,
        pointRadius: .constant(0),
        borderColor: .constant(.solid(Fl.red)),
      ),
    ],
    pluginOptions: const [TooltipOptions(enabled: false)],
    events: const [],
    scales: [
      const CategoryAxis(
        .x,
        grid: AxisGrid(display: false),
        border: Fl.noBorder,
        ticks: AxisTicks(
          maxRotation: 0,
          autoSkip: false,
          color: ChartPaint.solid(Colors.white),
          font: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
      LinearAxis(
        .y,
        min: 0,
        grid: flGrid(show: (v) => v == 1 || v == 4 || v == 5 || v == 6),
        border: flGridDash,
        ticks: AxisTicks(
          stepSize: 1,
          autoSkip: false,
          color: const ChartPaint.solid(Colors.white),
          font: const TextStyle(fontSize: 10),
          callback: (scale, value, index, ticks) => ['\$ ${value + 0.5}'],
        ),
      ),
    ],
  ),
);

class const Sample7({super.key}) extends StatelessWidget {
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

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Fl.item,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ChartTheme(data: ChartThemeData.dark(), child: Sample7()),
        ),
      ),
    ),
  );
}
