// Original code, not ported from Chart.js: fl_chart bar sample 4.
// ignore_for_file: public_member_api_docs
// #docregion fl_chart-bar-04
import 'package:chartjs_docs/migrate/fl_chart/fl_bar_kit.dart';
import 'package:chartjs_docs/migrate/fl_chart/fl_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _months = ['Apr', 'May', 'Jun', 'Jul'];

/// `Fl.cyan.darken(60)`, `Fl.cyan.darken(30)` and `Fl.cyan` of the sample.
const List<Color> _colors = [Color(0xFF205B66), Color(0xFF38A0B3), Fl.cyan];

/// The ends of the three stack items of each rod: 4 groups of 5 rods.
const List<List<(double, double, double)>> _rods = [
  [
    (2e9, 12e9, 17e9),
    (13e9, 14e9, 24e9),
    (6000000000.5, 18e9, 23000000000.5),
    (9e9, 15e9, 29e9),
    (2000000000.5, 17000000000.5, 32e9),
  ],
  [
    (11e9, 18e9, 31e9),
    (14e9, 27e9, 35e9),
    (8e9, 24e9, 31e9),
    (6000000000.5, 12000000000.5, 15e9),
    (9e9, 15e9, 17e9),
  ],
  [
    (6e9, 23e9, 34e9),
    (7e9, 24e9, 32e9),
    (1000000000.5, 12e9, 14000000000.5),
    (4e9, 15e9, 20e9),
    (4e9, 15e9, 24e9),
  ],
  [
    (1000000000.5, 12e9, 14e9),
    (7e9, 25e9, 27e9),
    (6e9, 23e9, 29e9),
    (9e9, 15e9, 16000000000.5),
    (7e9, 12000000000.5, 15e9),
  ],
];

/// The height of stack item [item] of rod [rod] in each group.
List<DataPoint> _items(int rod, int item) => [
  for (final (group, rods) in _rods.indexed)
    DataPoint(group, switch (item) {
      0 => rods[rod].$1,
      1 => rods[rod].$2 - rods[rod].$1,
      _ => rods[rod].$3 - rods[rod].$2,
    }),
];

final List<List<DataPoint>> _points = [
  for (var rod = 0; rod < 5; rod++)
    for (var item = 0; item < 3; item++) _items(rod, item),
];

/// The grid of fl_chart: a line at each title, but not at the ends.
ChartPaint _gridColor(Object? context) {
  final value = tickOf(context);
  return .solid(
    value <= 0 || value >= 35000000000
        ? Colors.transparent
        : Colors.white.withValues(alpha: 0.1),
  );
}

ChartConfig _config(double width) {
  // fl_chart scales the bars and the spaces with the width of the chart.
  final barsWidth = 8 * width / 400;
  final barsSpace = 4 * width / 400;
  return flBars(
    ChartConfig(
      datasets: [
        // A rod with stack items is a stack of three datasets.
        for (var rod = 0; rod < 5; rod++)
          for (var item = 0; item < 3; item++)
            BarDataset(
              points: _points[rod * 3 + item],
              stack: 'rod $rod',
              backgroundColor: .constant(.solid(_colors[item])),
              hoverBackgroundColor: .constant(.solid(_colors[item])),
              barThickness: BarThickness.pixels(barsWidth + barsSpace),
              maxBarThickness: barsWidth,
            ),
      ],
      tooltip: const ChartTooltip(enabled: false),
      extra: const {'events': <String>[]},
      scales: {
        'x': groupAxis(
          count: 4,
          groupWidth: 5 * barsWidth + 4 * barsSpace,
          alignment: .center,
          groupsSpace: barsSpace,
          reservedSize: 28,
          ticks: AxisTicks(
            padding: 8,
            color: const .solid(Fl.white38),
            font: const TextStyle(fontSize: 10),
            callback: (scale, value, index, ticks) => [_months[index]],
          ),
        ),
        'y': valueAxis(
          min: 0,
          max: 35000000000,
          stacked: true,
          reservedSize: 40,
          grid: const AxisGrid(
            drawTicks: false,
            lineWidth: 1,
            extra: {'color': _gridColor},
          ),
          ticks: AxisTicks(
            padding: 8,
            autoSkip: false,
            color: const .solid(Fl.white38),
            font: const TextStyle(fontSize: 10),
            callback: flTitles(hideMax: true),
          ),
        ),
      },
    ),
  );
}

class const BarSample4({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1.66,
    child: Padding(
      padding: const EdgeInsets.only(top: 16),
      child: LayoutBuilder(
        builder: (context, constraints) =>
            ChartView(config: _config(constraints.maxWidth)),
      ),
    ),
  );
}
// #enddocregion fl_chart-bar-04

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
                child: const BarSample4(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
