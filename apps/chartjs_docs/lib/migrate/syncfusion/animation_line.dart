// Original code, not ported from Chart.js: a replica of the Syncfusion demo "Dynamic update animation".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion sf-animation-line
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _color = Color.fromRGBO(6, 174, 224, 1);
const _text = Color(0xFF49454F);
const _axisLine = Color(0xFFCAC4D0);
const _grid = Color(0xFFE6E0E9);

class const SfAnimationLine({super.key}) extends StatefulWidget {
  @override
  State<SfAnimationLine> createState() => _SfAnimationLineState();
}

class _SfAnimationLineState() extends State<SfAnimationLine> {
  final math.Random _random = math.Random();
  late List<num> _values = _next();
  Timer? _timer;

  // 11 random values from 5 to 94.
  List<num> _next() => [for (var i = 0; i < 11; i++) 5 + _random.nextInt(90)];

  @override
  void initState() {
    super.initState();
    // Each 2 seconds a new data List: the chart animates to the new values.
    _timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => setState(() => _values = _next()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 320,
    child: ChartView(
      config: ChartConfig(
        type: .line,
        datasets: [
          LineDataset(
            points: [for (final (x, y) in _values.indexed) DataPoint(x, y)],
            borderColor: const .constant(.solid(_color)),
            borderWidth: 2,
            pointRadius: 4,
            pointBorderWidth: 2,
            pointBackgroundColor: const .constant(.solid(Colors.white)),
            pointBorderColor: const .constant(.solid(_color)),
          ),
        ],
        maintainAspectRatio: false,
        padding: const EdgeInsets.all(10),
        legend: const ChartLegend(display: false),
        tooltip: const ChartTooltip(enabled: false),
        animation: const ChartAnimation(duration: Duration(milliseconds: 1500)),
        // The original has no tooltip and no selection.
        extra: const {'events': <String>[]},
        scales: const {
          'x': LinearAxis(
            min: 0,
            max: 10,
            grid: AxisGrid(
              drawOnChartArea: false,
              color: .solid(_axisLine),
              extra: {'tickLength': 6},
            ),
            ticks: AxisTicks(
              stepSize: 2,
              color: .solid(_text),
              font: TextStyle(fontSize: 12),
            ),
            extra: {
              'border': {'color': ChartPaint.solid(_axisLine)},
            },
          ),
          'y': LinearAxis(
            min: 0,
            max: 100,
            grid: AxisGrid(
              color: .solid(_grid),
              lineWidth: 0.7,
              drawTicks: false,
            ),
            ticks: AxisTicks(
              stepSize: 20,
              padding: 8,
              color: .solid(_text),
              font: TextStyle(fontSize: 12),
            ),
            extra: {
              'border': {'display': false},
            },
          ),
        },
      ),
    ),
  );
}
// #enddocregion sf-animation-line
