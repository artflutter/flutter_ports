// Original code, not ported from Chart.js: fl_chart bar sample 8.
// ignore_for_file: public_member_api_docs
// #docregion fl_chart-bar-08
import 'dart:math' as math;

import 'package:chartjs_docs/migrate/fl_chart/fl_bar_kit.dart';
import 'package:chartjs_docs/migrate/fl_chart/fl_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/// The days from 4 on are the forecast: a dashed outline.
bool _forecast(int day) => day >= 4;

/// A random value and its error range for each day, as in the sample.
List<(double, double, double)> _randomData() {
  final random = math.Random();
  return [
    for (var day = 0; day < 7; day++)
      () {
        final y = random.nextInt(290) + 10.0;
        final lower = y < 50
            ? random.nextDouble() * 10
            : random.nextDouble() * 30 + 5;
        final upper = y > 290
            ? random.nextDouble() * 10
            : random.nextDouble() * 30 + 5;
        return (y, lower, upper);
      }(),
  ];
}

/// The error bars of fl_chart (`toYErrorRange`): a line with two caps of 14
/// pixels. Chart.js has no error bars: a small plugin draws them.
Plugin<Object?> _errorBars(List<(double, double, double)> data) => Plugin(
  id: 'errorBars',
  afterDatasetsDraw: (chart, args, options) {
    final y = chart.scales['y']!;
    final ctx = chart.ctx!
      ..save()
      ..lineWidth = 2;
    for (final (day, element) in chart.getDatasetMeta(0).data.indexed) {
      final (value, lower, upper) = data[day];
      final top = y.getPixelForValue(value + upper);
      final bottom = y.getPixelForValue(value - lower);
      final x = element.x;
      ctx
        ..strokeStyle = _forecast(day)
            ? Fl.cyan.withValues(alpha: 0.5)
            : Fl.orange
        ..beginPath()
        ..moveTo(x, top)
        ..lineTo(x, bottom)
        ..moveTo(x - 7, top)
        ..lineTo(x + 7, top)
        ..moveTo(x - 7, bottom)
        ..lineTo(x + 7, bottom)
        ..stroke();
    }
    ctx.restore();
  },
);

/// The dashed outline of the forecast bars (`borderDashArray`). The bars of
/// Chart.js have no dashed border: the plugin strokes it.
final Plugin<Object?> _dashedBars = Plugin(
  id: 'dashedBars',
  afterDatasetsDraw: (chart, args, options) {
    final ctx = chart.ctx!
      ..save()
      ..strokeStyle = Colors.white
      ..lineWidth = 2
      ..setLineDash(const [4, 4]);
    for (final (day, element) in chart.getDatasetMeta(0).data.indexed) {
      if (!_forecast(day)) continue;
      final bar = element as BarElement;
      ctx.strokeRect(bar.x - bar.width / 2, bar.y, bar.width, bar.base - bar.y);
    }
    ctx.restore();
  },
);

class const BarSample8({super.key}) extends StatefulWidget {
  @override
  State<BarSample8> createState() => _BarSample8State();
}

class _BarSample8State() extends State<BarSample8> {
  final List<(double, double, double)> _data = _randomData();

  late final ChartConfig _config = flBars(
    ChartConfig(
      datasets: [
        BarDataset(
          data: .points([
            for (final (day, (value, _, _)) in _data.indexed)
              DataPoint(day, value),
          ]),
          backgroundColor: .indexed([
            for (var day = 0; day < 7; day++)
              .solid(_forecast(day) ? Colors.transparent : Colors.white),
          ]),
          borderColor: .indexed([
            for (var day = 0; day < 7; day++)
              .solid(_forecast(day) ? Colors.transparent : Colors.white),
          ]),
          borderWidth: 2,
          barThickness: const BarThickness.pixels(22),
          borderSkipped: BorderSkip.none,
        ),
      ],
      tooltip: const ChartTooltip(enabled: false),
      events: const [],
      plugins: [_dashedBars, _errorBars(_data)],
      scales: [
        groupAxis(
          count: 7,
          groupWidth: 22,
          reservedSize: 38,
          ticks: AxisTicks(
            padding: 16,
            color: const .solid(Colors.white),
            font: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            callback: (scale, value, index, ticks) => [_days[index]],
          ),
        ),
        valueAxis(
          min: 0,
          max: 300,
          reservedSize: 30,
          ticks: AxisTicks(
            padding: 8,
            autoSkip: false,
            color: const .solid(Fl.white38),
            font: const TextStyle(fontSize: 14),
            callback: flTitles(),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.graphic_eq, color: Colors.white),
              SizedBox(width: 32),
              Flexible(
                child: Text(
                  'Sales forecasting chart',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(child: OverflowChart(config: _config)),
        ],
      ),
    ),
  );
}
// #enddocregion fl_chart-bar-08

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
                child: const BarSample8(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
