// Original code, not ported from Chart.js: fl_chart line sample 11.
// ignore_for_file: public_member_api_docs
// #docregion fl_chart-11
import 'package:chartjs_docs/migrate/fl_chart/fl_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
// The public libraries have no way to create a tick for afterBuildTicks.
// ignore: implementation_imports
import 'package:flutter_chartjs_port/src/core/core.scale.dart' as core;
import 'package:material_ui/material_ui.dart';

const _bold = ChartTextStyle(fontSize: 18, fontWeight: FontWeight.bold);
const _plain = ChartTextStyle(fontSize: 14);

class Sample11 extends StatefulWidget {
  const Sample11({super.key});
  @override
  State<Sample11> createState() => _Sample11State();
}

class _Sample11State extends State<Sample11> {
  double _baseX = 0;
  double _baseY = 0;

  double get _chartBaseY => (20 - (_baseY + 10)) - 10;

  /// fl_chart places the ticks around a baseline.
  void _ticksFrom(Object? scale, double base) {
    final s = scale! as core.Scale;
    const step = 5.0;
    var value = base;
    while (value - step >= -10) {
      value -= step;
    }
    s.ticks = [
      for (var v = value; v <= 10.0001; v += step) core.Tick(value: v),
    ];
  }

  ChartAxis _axis(double base, ChartPosition position, String id) => LinearAxis(
    min: -10,
    max: 10,
    position: position,
    grid: AxisGrid(
      drawTicks: false,
      extra: {
        'color': (JsObjectFace c) => (tickOf(c) - base).abs() <= 0.1
            ? const Color(0xB3FFFFFF)
            : Fl.blueGrey,
        'lineWidth': (JsObjectFace c) =>
            (tickOf(c) - base).abs() <= 0.1 ? 1.0 : 0.4,
      },
    ),
    ticks: AxisTicks(
      autoSkip: false,
      maxRotation: 0,
      format: (t) => t.value.toStringAsFixed(t.value % 1 == 0 ? 0 : 1),
      extra: {
        'color': (JsObjectFace c) =>
            (tickOf(c) - base).abs() <= 0.1 ? Colors.white : Colors.white60,
        'font': (JsObjectFace c) =>
            (tickOf(c) - base).abs() <= 0.1 ? _bold : _plain,
      },
    ),
    extra: {
      ...flGridDash,
      'afterBuildTicks': (Object? s) => _ticksFrom(s, base),
    },
  );

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1.5,
    child: Padding(
      padding: const EdgeInsets.only(top: 18, right: 18),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                RotatedBox(
                  quarterTurns: 1,
                  child: Slider(
                    value: _baseY,
                    min: -10,
                    max: 10,
                    onChanged: (v) => setState(() => _baseY = v),
                  ),
                ),
                Expanded(
                  child: ChartView(
                    updateMode: 'none',
                    config: fills(
                      ChartConfig(
                        type: .line,
                        datasets: const [LineDataset(points: <DataPoint>[])],
                        animation: ChartAnimation.none,
                        tooltip: const ChartTooltip(enabled: false),
                        scales: {
                          'x': _axis(_baseX, .bottom, 'x'),
                          'x2': _axis(_baseX, .top, 'x2'),
                          'y': _axis(_chartBaseY, .left, 'y'),
                          'y2': _axis(_chartBaseY, .right, 'y2'),
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Slider(
            value: _baseX,
            min: -10,
            max: 10,
            onChanged: (v) => setState(() => _baseX = v),
          ),
        ],
      ),
    ),
  );
}
// #enddocregion fl_chart-11
