// Original code, not ported from Chart.js: fl_chart line sample 2.
// ignore_for_file: public_member_api_docs
// #docregion fl_chart-02
import 'package:chartjs_docs/migrate/fl_chart/fl_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const List<Color> _colors = [Fl.cyan, Fl.blue];
const List<num> _xs = [0, 2.6, 4.9, 6.8, 8, 9.5, 11];
const _gridColor = Color(0xff37434d);

final Color _avg = Color.lerp(Fl.cyan, Fl.blue, 0.2)!;

String? _bottom(AxisTickInfo t) => switch (t.value.toInt()) {
  2 => 'MAR',
  5 => 'JUN',
  8 => 'SEP',
  _ => '',
};

String? _left(AxisTickInfo t) => switch (t.value.toInt()) {
  1 => '10K',
  3 => '30k',
  5 => '50k',
  _ => '',
};

ChartConfig _config(List<num> ys, {required bool average}) {
  final colors = average ? [_avg, _avg] : _colors;
  return fills(
    ChartConfig(
      type: .line,
      datasets: [
        LineDataset(
          points: [for (final (i, x) in _xs.indexed) DataPoint(x, ys[i])],
          tension: 0.35,
          borderWidth: 5,
          pointRadius: 0,
          pointHoverRadius: 8,
          fill: .origin,
          extra: {
            'borderColor': horizontalGradient(colors),
            'backgroundColor': horizontalGradient([
              for (final c in colors) c.withValues(alpha: average ? 0.1 : 0.3),
            ]),
            'borderCapStyle': StrokeCap.round,
          },
        ),
      ],
      interaction: const ChartInteraction(mode: flX, intersect: false),
      tooltip: ChartTooltip(
        enabled: !average,
        displayColors: false,
        callbacks: TooltipCallbacks(title: (tooltip, _) => null),
      ),
      plugins: [_border],
      scales: {
        'x': LinearAxis(
          min: 0,
          max: 11,
          grid: AxisGrid(
            color: ChartPaint.solid(average ? _gridColor : Fl.white10),
            drawTicks: false,
          ),
          ticks: const AxisTicks(
            stepSize: 1,
            autoSkip: false,
            maxRotation: 0,
            color: ChartPaint.solid(Colors.white),
            font: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            format: _bottom,
          ),
        ),
        'y': LinearAxis(
          min: 0,
          max: 6,
          grid: AxisGrid(
            color: ChartPaint.solid(average ? _gridColor : Fl.white10),
            drawTicks: false,
          ),
          ticks: const AxisTicks(
            stepSize: 1,
            autoSkip: false,
            color: ChartPaint.solid(Colors.white),
            font: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            format: _left,
          ),
        ),
      },
    ),
  );
}

final Map<String, Object?> _border = areaBorder(_gridColor);
final ChartConfig _main = _config(const [
  3,
  2,
  5,
  3.1,
  4,
  3,
  4,
], average: false);
final ChartConfig _average = _config(List.filled(7, 3.44), average: true);

class Sample2 extends StatefulWidget {
  const Sample2({super.key});
  @override
  State<Sample2> createState() => _Sample2State();
}

class _Sample2State extends State<Sample2> {
  bool _showAvg = false;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      AspectRatio(
        aspectRatio: 1.7,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 24, 18, 12),
          child: ChartView(config: _showAvg ? _average : _main),
        ),
      ),
      SizedBox(
        width: 60,
        height: 34,
        child: TextButton(
          onPressed: () => setState(() => _showAvg = !_showAvg),
          child: Text(
            'avg',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: _showAvg ? 0.5 : 1),
            ),
          ),
        ),
      ),
    ],
  );
}
// #enddocregion fl_chart-02
