// Ported from Chart.js v4.6.1 docs/charts/line.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The line color of the examples.
const Color teal = Color.fromRGBO(75, 192, 192, 1);

// #docregion live
ChartConfig liveLine(List<DataPoint> points) => ChartConfig(
  type: .line,
  datasets: [
    LineDataset(
      label: 'Signal',
      points: points,
      borderColor: const .constant(.solid(teal)),
      borderWidth: 1.5,
      pointRadius: 0,
    ),
  ],
  scales: const {
    'x': LinearAxis(min: 0, max: 999),
    'y': LinearAxis(min: -1.5, max: 1.5),
  },
  animation: ChartAnimation.none,
);

// Give a new List in each frame:
class const LiveLineChart({required final List<DataPoint> points, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ChartView(
    config: liveLine(points),
    updateMode: UpdateMode.none,
    dataOnlyUpdates: true,
  );
}
// #enddocregion live

void main() {
  Chart.register(registerables);
  runApp(
    const Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: Color(0xFFFFFFFF),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: _LiveDemo()),
        ),
      ),
    ),
  );
}

// 1,000 points with new values in each frame, as on the docs page.
class const _LiveDemo() extends StatefulWidget {
  @override
  State<_LiveDemo> createState() => _LiveDemoState();
}

class _LiveDemoState()
    extends State<_LiveDemo>
    with SingleTickerProviderStateMixin {
  int _tick = 0;
  late final _ticker = createTicker((_) => setState(() => _tick++));

  List<DataPoint> _points() => List.generate(1000, (index) {
    final x = index * 0.02;
    final y =
        math.sin(x + _tick * 0.05) + 0.4 * math.sin(3.1 * x - _tick * 0.11);
    return DataPoint(index, y);
  }, growable: false);

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LiveLineChart(points: _points());
}
