// Original code, not ported from Chart.js: fl_chart line sample 8.
// ignore_for_file: public_member_api_docs
// #docregion fl_chart-08
import 'package:chartjs_docs/migrate/fl_chart/fl_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const Map<int, (IconData, Color)> _icons = {
  0: (Icons.wb_sunny, Fl.yellow),
  2: (Icons.wine_bar_sharp, Fl.red),
  4: (Icons.watch_later, Fl.green),
  6: (Icons.whatshot, Fl.orange),
};

/// The SVG picture of the sample, drawn with paths.
Map<String, Object?> _pictures(List<double> xs) => {
  'id': 'pictures',
  'afterDatasetsDraw': (Chart chart, Object? args, Object? options) {
    final area = chart.chartArea!;
    final ctx = chart.ctx!..save();
    for (final x in xs) {
      final px = chart.scales['x']!.getPixelForValue(x);
      final y = area.bottom - 7;
      ctx
        ..fillStyle = const Color(0xFF495DFF)
        ..beginPath()
        ..arc(px, y, 7, 0, 6.2832)
        ..fill()
        ..fillStyle = Colors.white
        ..beginPath()
        ..moveTo(px, y + 4)
        ..bezierCurveTo(px + 1.6, y + 4, px + 3, y + 2.7, px + 3, y + 1)
        ..bezierCurveTo(px + 3, y - 0.6, px + 1.6, y - 4, px, y - 4)
        ..bezierCurveTo(px - 1.6, y - 4, px - 3, y - 0.6, px - 3, y + 1)
        ..bezierCurveTo(px - 3, y + 2.7, px - 1.6, y + 4, px, y + 4)
        ..fill();
    }
    ctx.restore();
  },
};

final List<Map<String, Object?>> _plugins = [
  annotations([
    VRange(2, 5, Fl.blue.withValues(alpha: 0.2)),
    VRange(8, 9, Fl.blue.withValues(alpha: 0.2)),
    HRange(2, 3, Fl.green.withValues(alpha: 0.3)),
    const HLine(5, Fl.green, 2, [5, 10], label: 'H: 5.0'),
    const VLine(5.7, Fl.blue, 2, [5, 10], label: 'V: 5.7'),
  ]),
  touchIndicator(color: Fl.orange, width: 3, toTop: true),
  _pictures(const [3.5, 8.5]),
  areaBorder(Fl.white54),
];

final ChartConfig _config = fills(
  ChartConfig(
    type: .line,
    datasets: [
      LineDataset(
        points: [
          DataPoint(0, 1),
          DataPoint(2, 1),
          DataPoint(4.9, 5),
          DataPoint(6.8, 5),
          DataPoint(7.5, 3.5),
          DataPoint(7.5, null),
          DataPoint(7.5, 2),
          DataPoint(8, 1),
          DataPoint(10, 2),
          DataPoint(11, 2.5),
        ],
        tension: 0.35,
        borderWidth: 4,
        borderDash: const [10, 6],
        pointRadius: 0,
        pointHoverRadius: 8,
        pointHoverBackgroundColor: const .constant(.solid(Fl.orange)),
        borderColor: const .constant(.solid(Fl.red)),
        borderCapStyle: StrokeCap.round,
      ),
    ],
    interaction: const ChartInteraction(mode: flX, intersect: false),
    tooltip: ChartTooltip(
      backgroundColor: const ChartPaint.solid(Fl.red),
      displayColors: false,
      bodyFont: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      callbacks: TooltipCallbacks(
        title: (tooltip, _) => null,
        label: (tooltip, i) => [i.formattedValue],
      ),
    ),
    plugins: _plugins,
    scales: {
      'x': const LinearAxis(
        min: 0,
        max: 11,
        grid: AxisGrid(display: false),
        extra: Fl.noBorder,
        ticks: AxisTicks(
          stepSize: 4,
          color: ChartPaint.solid(Colors.white),
          font: TextStyle(fontSize: 10),
        ),
      ),
      'y': LinearAxis(
        min: 0,
        max: 6,
        grid: const AxisGrid(display: false),
        extra: Fl.noBorder,
        ticks: AxisTicks(
          stepSize: 2,
          autoSkip: false,
          font: const TextStyle(fontFamily: 'MaterialIcons', fontSize: 32),
          format: (t) =>
              String.fromCharCode(_icons[t.value.toInt()]!.$1.codePoint),
          extra: {
            'color': (JsObjectFace c) =>
                ChartPaint.solid(_icons[tickOf(c).toInt()]!.$2),
          },
        ),
      ),
    },
  ),
);

class Sample8 extends StatelessWidget {
  const Sample8({super.key});
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1.7,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 24, 18, 12),
      child: ChartView(config: _config),
    ),
  );
}
// #enddocregion fl_chart-08
