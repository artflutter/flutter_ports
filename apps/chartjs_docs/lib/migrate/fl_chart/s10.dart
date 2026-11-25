// Original code, not ported from Chart.js: fl_chart line sample 10.
// ignore_for_file: public_member_api_docs
// #docregion fl_chart-10
import 'dart:async';
import 'dart:math' as math;

import 'package:chartjs_docs/migrate/fl_chart/fl_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

LineDataset _line(List<DataPoint> points, Color color) => LineDataset(
  data: .points(points),
  borderWidth: 4,
  pointRadius: const .constant(0),
  borderColor: .resolver(
    horizontalGradient([color.withValues(alpha: 0), color], const [0.1, 1]),
  ),
);

class const _Label(final String text, final Color color)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
  );
}

class const Sample10({super.key}) extends StatefulWidget {
  @override
  State<Sample10> createState() => _Sample10State();
}

class _Sample10State() extends State<Sample10> {
  static const _limit = 100;
  List<DataPoint> _sin = [];
  List<DataPoint> _cos = [];
  double _x = 0;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      setState(() {
        _sin = [
          ..._sin.skip(_sin.length > _limit ? 1 : 0),
          DataPoint(_x, math.sin(_x)),
        ];
        _cos = [
          ..._cos.skip(_cos.length > _limit ? 1 : 0),
          DataPoint(_x, math.cos(_x)),
        ];
      });
      _x += 0.05;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cos.isEmpty) return const SizedBox(height: 300);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        _Label('x: ${_x.toStringAsFixed(1)}', Fl.white70),
        _Label('sin: ${_sin.last.y!.toStringAsFixed(1)}', Fl.blue),
        _Label('cos: ${_cos.last.y!.toStringAsFixed(1)}', Fl.pink),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 1.5,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: ChartView(
              updateMode: UpdateMode.none,
              config: fills(
                ChartConfig(
                  datasets: [_line(_sin, Fl.blue), _line(_cos, Fl.pink)],
                  animation: ChartAnimation.none,
                  pluginOptions: const [TooltipOptions(enabled: false)],
                  events: const [],
                  scales: [
                    LinearAxis(
                      .x,
                      min: _sin.first.x,
                      max: _sin.last.x,
                      grid: const AxisGrid(display: false),
                      ticks: const AxisTicks(display: false),
                      border: Fl.noBorder,
                    ),
                    LinearAxis(
                      .y,
                      min: -1,
                      max: 1,
                      grid: flGrid(show: (v) => v.abs() < 1),
                      ticks: const AxisTicks(display: false, stepSize: 0.5),
                      border: flGridDash,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// #enddocregion fl_chart-10

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Fl.item,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ChartTheme(data: ChartThemeData.dark(), child: Sample10()),
        ),
      ),
    ),
  );
}
