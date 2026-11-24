// Original code, not ported from Chart.js: fl_chart bar sample 6.
// ignore_for_file: public_member_api_docs
// #docregion fl_chart-bar-06
import 'package:chartjs_docs/migrate/fl_chart/fl_bar_kit.dart';
import 'package:chartjs_docs/migrate/fl_chart/fl_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _months = [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];

/// Pilates, quick workouts and cycling of each month.
const List<(double, double, double)> _activity = [
  (2, 3, 2),
  (2, 5, 1.7),
  (1.3, 3.1, 2.8),
  (3.1, 4, 3.1),
  (0.8, 3.3, 3.4),
  (2, 5.6, 1.8),
  (1.3, 3.2, 2),
  (2.3, 3.2, 3),
  (2, 4.8, 2.5),
  (1.2, 3.2, 2.5),
  (1, 4.8, 3),
  (2, 4.4, 2.8),
];
const _space = 0.2;
const _names = ['Pilates', 'Quick workouts', 'Cycling'];
const List<Color> _colors = [Fl.purple, Fl.blue, Fl.cyan];

/// A rod from `fromY` to `toY` is a floating bar: a pair `[from, to]`.
List<(double, double)> _rods(int activity) => [
  for (final (pilates, quick, cycling) in _activity)
    switch (activity) {
      0 => (0, pilates),
      1 => (pilates + _space, pilates + _space + quick),
      _ => (
        pilates + quick + 2 * _space,
        pilates + quick + 2 * _space + cycling,
      ),
    },
];

/// The extra lines of fl_chart (`extraLinesData`), drawn over the bars.
final Plugin<Object?> _extraLines = Plugin(
  id: 'extraLines',
  afterDatasetsDraw: (chart, args, options) {
    final area = chart.chartArea!;
    final y = chart.scales['y']!;
    final ctx = chart.ctx!
      ..save()
      ..lineWidth = 1
      ..setLineDash(const [20, 4]);
    for (final (value, color) in const [
      (3.3, Fl.purple),
      (8.0, Fl.blue),
      (11.0, Fl.cyan),
    ]) {
      final pixel = y.getPixelForValue(value);
      ctx
        ..strokeStyle = color
        ..beginPath()
        ..moveTo(area.left, pixel)
        ..lineTo(area.right, pixel)
        ..stroke();
    }
    ctx.restore();
  },
);

final ChartConfig _config = flBars(
  ChartConfig(
    labels: _months,
    datasets: [
      for (var activity = 0; activity < 3; activity++)
        BarDataset(
          label: _names[activity],
          backgroundColor: .constant(.solid(_colors[activity])),
          barThickness: const BarThickness.pixels(5),
          borderRadius: 2.5,
          // The rods of a group stand on each other at one place.
          grouped: false,
          borderSkipped: BorderSkip.none,
          data: .ranges(_rods(activity)),
        ),
    ],
    pluginOptions: const [TooltipOptions(enabled: false)],
    events: const [],
    plugins: [_extraLines],
    scales: [
      // Without offset, the first and the last group stand at the ends of
      // the axis, as `BarChartAlignment.spaceBetween`.
      CategoryAxis(
        .x,
        grid: const AxisGrid(display: false, drawTicks: false),
        border: const AxisBorder(display: false),
        ticks: const AxisTicks(
          padding: 8,
          maxRotation: 0,
          autoSkip: false,
          color: .constant(.solid(Fl.white38)),
          font: .constant(TextStyle(fontSize: 10)),
        ),
        offset: false,
        afterFit: reserve(20),
      ),
      valueAxis(min: 0, max: 11 + _space * 3),
    ],
  ),
);

class const BarSample6({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activity',
          style: TextStyle(
            color: Fl.blue,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // The legend of the sample is a row of widgets.
        Wrap(
          spacing: 16,
          children: [
            for (final (i, name) in _names.indexed)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _colors[i],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Color(0xff757391),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 14),
        AspectRatio(aspectRatio: 2, child: OverflowChart(config: _config)),
      ],
    ),
  );
}
// #enddocregion fl_chart-bar-06

void main() {
  Chart.register(registerables);
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Fl.item,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: ChartTheme(
            data: const ChartThemeData.dark(),
            // The fl_chart gallery shows each sample in a card of at most
            // 600 pixels.
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: const BarSample6(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
