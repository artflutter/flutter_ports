// Original code, not ported from Chart.js: fl_chart bar sample 3.
// ignore_for_file: public_member_api_docs
// #docregion fl_chart-bar-03
import 'package:chartjs_docs/migrate/fl_chart/fl_bar_kit.dart';
import 'package:chartjs_docs/migrate/fl_chart/fl_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _days = ['Mn', 'Tu', 'Wd', 'Th', 'Fr', 'St', 'Sn'];
const List<num> _values = [8, 10, 14, 15, 13, 10, 16];

/// `Fl.blue.darken(20)` of the sample.
const _darkBlue = Color(0xFF1A78C2);

class const BarSample3({super.key}) extends StatefulWidget {
  @override
  State<BarSample3> createState() => _BarSample3State();
}

class _BarSample3State() extends State<BarSample3> {
  int _touched = -1;

  /// The bar under the pointer, as the `touchCallback` of the sample.
  late final Plugin<Object?> _touch = flTouch((bar) {
    final index = bar?.index ?? -1;
    if (index != _touched) setState(() => _touched = index);
  });

  late final Plugin<Object?> _labels = rodLabels(_label);

  /// fl_chart paints the gradient in the rect of each bar: from the base to
  /// the tip of the bar.
  ChartPaint _gradient(ScriptableContext context) {
    final index = context.dataIndex;
    if (index == null) return const .solid(Fl.cyan);
    final y = context.chart.scales['y']!;
    return ChartGradient.linear(
      Offset(0, y.getPixelForValue(0)),
      Offset(0, y.getPixelForValue(_values[index].toDouble())),
      const [_darkBlue, Fl.cyan],
    );
  }

  RodLabel _label(int dataset, int index) => RodLabel(
    '${_values[index]}',
    TextStyle(
      color: Fl.cyan,
      fontWeight: FontWeight.bold,
      fontSize: index == _touched ? 40 : 18,
    ),
  );

  ChartConfig _config() => flBars(
    ChartConfig(
      labels: _days,
      datasets: [
        BarDataset(
          data: _values,
          backgroundColor: .resolver(_gradient),
          hoverBackgroundColor: .resolver(_gradient),
          barThickness: const BarThickness.pixels(8),
          borderRadius: 4,
          extra: const {'borderSkipped': false},
        ),
      ],
      animation: const ChartAnimation(
        duration: Duration(milliseconds: 100),
        easing: Curves.easeOutQuad,
      ),
      tooltip: const ChartTooltip(enabled: false),
      plugins: [_labels, _touch],
      scales: {
        // A category axis places the groups as `BarChartAlignment.spaceAround`.
        'x': CategoryAxis(
          grid: const AxisGrid(display: false, drawTicks: false),
          border: const AxisBorder(display: false),
          ticks: const AxisTicks(
            padding: 4,
            color: .solid(_darkBlue),
            font: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          extra: {'afterFit': reserve(30)},
        ),
        'y': valueAxis(min: 0, max: 20),
      },
    ),
  );

  @override
  Widget build(BuildContext context) =>
      AspectRatio(aspectRatio: 1.6, child: ChartView(config: _config()));
}
// #enddocregion fl_chart-bar-03

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
                child: const BarSample3(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
