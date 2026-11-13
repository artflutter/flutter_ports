// Original code, not ported from Chart.js: fl_chart line sample 6.
// ignore_for_file: public_member_api_docs
// #docregion fl_chart-06
import 'package:chartjs_docs/migrate/fl_chart/fl_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const Color _orange = Fl.orange;
final Color _orangeDark = Color.lerp(Fl.orange, Colors.black, 0.6)!;
final Color _blueDark = Color.lerp(Fl.blue, Colors.black, 0.6)!;

LineDataset _line(List<num> ys, Color from, Color to, Color text) =>
    LineDataset(
      points: [for (final (i, y) in ys.indexed) DataPoint(i * 2, y)],
      tension: 0.35,
      borderWidth: 10,
      pointRadius: 12,
      pointHoverRadius: 12,
      pointBorderColor: Colors.white,
      pointBorderWidth: 1,
      borderCapStyle: StrokeCap.round,
      extra: {
        'borderColor': horizontalGradient([from, to]),
        'pointBackgroundColor': [
          for (var i = 0; i < ys.length; i++)
            Color.lerp(from, to, i / (ys.length - 1)),
        ],
        'pointHitRadius': 12,
        'clip': false,
      },
    );

const Map<String, Map<String, Object>> _visibleBorder = {
  'border': {
    'dash': [8.0, 4.0],
    'display': true,
    'color': Fl.white54,
  },
};

String? _hideBottom(AxisTickInfo t) => t.value == 6 ? '' : '${t.value.toInt()}';

final ChartConfig _config = fills(
  ChartConfig(
    type: .line,
    datasets: [
      _line(const [1, 5, 3, 5], _orange, _orangeDark, _orange),
      _line(const [3, 1, 2, 1], _blueDark, Fl.blue, Fl.blue),
    ],
    interaction: const ChartInteraction(
      mode: NearestInteractionMode(),
      intersect: true,
    ),
    tooltip: ChartTooltip(
      backgroundColor: Colors.white,
      cornerRadius: 0,
      displayColors: false,
      bodyFont: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      callbacks: TooltipCallbacks(
        labelTextColor: (tooltip, item) =>
            ChartPaint.solid(item.datasetIndex == 0 ? _orange : Fl.blue),
        title: (tooltip, _) => null,
        label: (tooltip, i) => [i.formattedValue],
      ),
    ),
    scales: {
      'x': LinearAxis(
        min: 0,
        max: 6,
        position: .top,
        grid: flGrid(),
        extra: _visibleBorder,
        ticks: const AxisTicks(
          stepSize: 1,
          color: Fl.white70,
          maxRotation: 0,
          font: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      'y': LinearAxis(
        min: 0,
        max: 6,
        reverse: true,
        grid: flGrid(),
        extra: _visibleBorder,
        ticks: const AxisTicks(
          stepSize: 1,
          color: _orange,
          font: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          format: _hideBottom,
        ),
      ),
      'y2': const LinearAxis(
        min: 0,
        max: 6,
        reverse: true,
        position: .right,
        grid: AxisGrid(display: false),
        extra: Fl.noBorder,
        ticks: AxisTicks(
          stepSize: 1,
          color: Fl.blue,
          font: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          format: _hideBottom,
        ),
      ),
    },
  ),
);

class Sample6 extends StatelessWidget {
  const Sample6({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 22, bottom: 20),
    child: AspectRatio(aspectRatio: 2, child: ChartView(config: _config)),
  );
}
// #enddocregion fl_chart-06
