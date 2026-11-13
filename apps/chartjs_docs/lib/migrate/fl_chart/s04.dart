// Original code, not ported from Chart.js: fl_chart line sample 4.
// ignore_for_file: public_member_api_docs
// #docregion fl_chart-04
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
final Color _above = Fl.purple.withValues(alpha: 0.7);
final List<Map<String, Object?>> _plugins = [areaBorder(Fl.white54)];

final ChartConfig _config = fills(
  ChartConfig(
    type: .line,
    labels: _months,
    datasets: [
      LineDataset(
        data: const [4, 3.5, 4.5, 1, 4, 6, 6.5, 6, 4, 6, 6, 7],
        tension: 0.35,
        borderWidth: 8,
        pointRadius: 0,
        borderColor: const .constant(.solid(Fl.yellow)),
        extra: {
          'fill': {
            'target': const {'value': 5},
            'above': const ChartPaint.solid(Fl.pink),
            'below': ChartPaint.solid(_above),
          },
        },
      ),
    ],
    tooltip: const ChartTooltip(enabled: false),
    extra: const {'events': <String>[]},
    plugins: _plugins,
    scales: {
      'x': const CategoryAxis(
        grid: AxisGrid(display: false),
        extra: Fl.noBorder,
        title: AxisTitle(
          display: true,
          text: '2019',
          color: ChartPaint.solid(Fl.yellow),
          font: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        ticks: AxisTicks(
          maxRotation: 0,
          autoSkip: false,
          color: ChartPaint.solid(Fl.yellow),
          font: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
      'y': LinearAxis(
        min: 0,
        grid: flGrid(show: (v) => v == 1 || v == 4 || v == 5 || v == 6),
        extra: flGridDash,
        title: const AxisTitle(
          display: true,
          text: 'Value',
          color: ChartPaint.solid(Fl.white70),
        ),
        ticks: AxisTicks(
          stepSize: 1,
          autoSkip: false,
          color: const ChartPaint.solid(Fl.white38),
          font: const TextStyle(fontSize: 12),
          callback: (scale, value, index, ticks) => ['\$ ${value + 0.5}'],
        ),
      ),
    },
  ),
);

class const Sample4({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 2,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 22, 28, 12),
      child: ChartView(config: _config),
    ),
  );
}
// #enddocregion fl_chart-04
