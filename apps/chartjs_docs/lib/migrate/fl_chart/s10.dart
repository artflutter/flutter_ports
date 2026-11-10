// Original code, not ported from Chart.js: fl_chart line sample 10.
// ignore_for_file: public_member_api_docs
// #docregion fl_chart-10
import 'dart:async';
import 'dart:math' as math;

import 'package:chartjs_docs/migrate/fl_chart/fl_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

LineDataset _line(List<DataPoint> points, Color color) => LineDataset(
  points: points,
  borderWidth: 4,
  pointRadius: 0,
  extra: {
    'borderColor': horizontalGradient(
      [color.withValues(alpha: 0), color],
      const [0.1, 1],
    ),
  },
);

class Sample10 extends StatefulWidget {
  const Sample10({super.key});
  @override
  State<Sample10> createState() => _Sample10State();
}

class _Sample10State extends State<Sample10> {
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

  Widget _label(String text, Color color) => Text(
    text,
    style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
  );

  @override
  Widget build(BuildContext context) {
    if (_cos.isEmpty) return const SizedBox(height: 300);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        _label('x: ${_x.toStringAsFixed(1)}', Fl.white70),
        _label('sin: ${(_sin.last.y!).toStringAsFixed(1)}', Fl.blue),
        _label('cos: ${(_cos.last.y!).toStringAsFixed(1)}', Fl.pink),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 1.5,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: ChartView(
              updateMode: 'none',
              config: fills(
                ChartConfig(
                  type: .line,
                  datasets: [_line(_sin, Fl.blue), _line(_cos, Fl.pink)],
                  animation: ChartAnimation.none,
                  tooltip: const ChartTooltip(enabled: false),
                  extra: const {'events': <String>[]},
                  scales: {
                    'x': LinearAxis(
                      min: _sin.first.x as double,
                      max: _sin.last.x as double,
                      grid: const AxisGrid(display: false),
                      ticks: const AxisTicks(display: false),
                      extra: Fl.noBorder,
                    ),
                    'y': LinearAxis(
                      min: -1,
                      max: 1,
                      grid: flGrid(show: (v) => v.abs() < 1),
                      ticks: const AxisTicks(display: false, stepSize: 0.5),
                      extra: flGridDash,
                    ),
                  },
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
