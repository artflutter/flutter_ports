// Original code, not ported from Chart.js: fl_chart bar sample 2.
// ignore_for_file: public_member_api_docs
// #docregion fl_chart-bar-02
import 'package:chartjs_docs/migrate/fl_chart/fl_bar_kit.dart';
import 'package:chartjs_docs/migrate/fl_chart/fl_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _days = ['Mn', 'Te', 'Wd', 'Tu', 'Fr', 'St', 'Su'];
const _left = [5.0, 16.0, 18.0, 20.0, 17.0, 19.0, 10.0];
const _right = [12.0, 12.0, 5.0, 16.0, 6.0, 1.5, 1.5];
const _width = 7.0;
const _barsSpace = 4.0;
const _titleColor = Color(0xff7589a2);

/// `Fl.orange.avg(Fl.red)` of the sample.
const _avgColor = Color(0xFFF33447);

TextStyle _labelStyle(Color color) => TextStyle(
  color: color,
  fontSize: 12,
  fontWeight: FontWeight.bold,
  shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
);

class const BarSample2({super.key}) extends StatefulWidget {
  @override
  State<BarSample2> createState() => _BarSample2State();
}

class _BarSample2State() extends State<BarSample2> {
  int _touched = -1;

  /// The bar under the pointer, as the `touchCallback` of the sample.
  late final Plugin<Object?> _touch = flTouch((bar) {
    final index = bar?.index ?? -1;
    if (index != _touched) setState(() => _touched = index);
  });

  late final Plugin<Object?> _labels = rodLabels(_label);

  double _mean(int index) => (_left[index] + _right[index]) / 2;

  /// The touched group shows the average of its two bars.
  BarDataset _rods(List<double> values, Color color) => BarDataset(
    points: [
      for (final (i, value) in values.indexed)
        DataPoint(i, i == _touched ? _mean(i) : value),
    ],
    backgroundColor: .indexed([
      for (var i = 0; i < 7; i++) .solid(i == _touched ? _avgColor : color),
    ]),
    hoverBackgroundColor: .indexed([
      for (var i = 0; i < 7; i++) .solid(i == _touched ? _avgColor : color),
    ]),
    // Two bars of 7 pixels with 4 pixels between them.
    barThickness: _width + _barsSpace,
    maxBarThickness: _width,
    borderRadius: _width / 2,
    extra: const {'borderSkipped': false},
  );

  RodLabel _label(int dataset, int index) {
    if (index == _touched) {
      final text = _mean(index).toString();
      return RodLabel(text, _labelStyle(_avgColor), angle: -90);
    }
    final value = (dataset == 0 ? _left : _right)[index];
    return RodLabel(
      value.toString(),
      _labelStyle(dataset == 0 ? Fl.red : Fl.yellow),
    );
  }

  ChartConfig _config() => flBars(
    ChartConfig(
      type: .bar,
      datasets: [_rods(_left, Fl.red), _rods(_right, Fl.yellow)],
      tooltip: const ChartTooltip(enabled: false),
      plugins: [_labels, _touch],
      scales: {
        'x': groupAxis(
          count: 7,
          groupWidth: 2 * _width + _barsSpace,
          reservedSize: 42,
          ticks: AxisTicks(
            padding: 16,
            color: const .solid(_titleColor),
            font: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            callback: (scale, value, index, ticks) => [_days[index]],
          ),
        ),
        'y': valueAxis(
          min: 0,
          max: 20,
          interval: 1,
          reservedSize: 28,
          ticks: AxisTicks(
            padding: 0,
            autoSkip: false,
            color: const .solid(_titleColor),
            font: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            callback: (scale, value, index, ticks) => [
              switch (value) {
                0 => '1K',
                10 => '5K',
                19 => '10K',
                _ => '',
              },
            ],
          ),
        ),
      },
    ),
  );

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              _TransactionsIcon(),
              SizedBox(width: 38),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    text: 'Transactions ',
                    style: TextStyle(color: Colors.white, fontSize: 22),
                    children: [
                      TextSpan(
                        text: 'state',
                        style: TextStyle(
                          color: Color(0xff77839a),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 38),
          // The labels of the tallest bars stand above the chart.
          Expanded(
            child: overflowChart(
              _config(),
              overflow: const EdgeInsets.only(top: 24),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}

/// The five small bars before the title.
class const _TransactionsIcon() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 3.5,
    children: [
      for (final (height, alpha) in const [
        (10.0, 0.4),
        (28.0, 0.8),
        (42.0, 1.0),
        (28.0, 0.8),
        (10.0, 0.4),
      ])
        Container(
          width: 4.5,
          height: height,
          color: Colors.white.withValues(alpha: alpha),
        ),
    ],
  );
}
// #enddocregion fl_chart-bar-02
