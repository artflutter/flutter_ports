// Original code, not ported from Chart.js: fl_chart line sample 9.
// ignore_for_file: public_member_api_docs
// #docregion fl_chart-09
import 'dart:math';

import 'package:chartjs_docs/migrate/fl_chart/fl_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _font = TextStyle(fontWeight: FontWeight.bold, fontSize: 18);

ChartPaint _zero(JsObjectFace c, Color color) =>
    .solid(tickOf(c) == 0 ? color : Colors.transparent);

Map<String, Object?> _axis(Color color) => {
  'border': {
    'dash': [8.0, 2.0],
    'display': false,
  },
};

final ChartConfig _config = fills(
  ChartConfig(
    type: .line,
    datasets: [
      LineDataset(
        points: [
          for (var i = 0; i <= 100; i++)
            DataPoint((i - 50) / 10, cos((i - 50) / 10)),
        ],
        tension: 0.35,
        borderWidth: 3,
        pointRadius: 0,
        pointHoverRadius: 8,
        borderColor: const .constant(.solid(Fl.pink)),
        borderCapStyle: StrokeCap.round,
      ),
    ],
    interaction: const ChartInteraction(
      mode: NearestInteractionMode(),
      intersect: false,
      axis: .x,
    ),
    tooltip: ChartTooltip(
      backgroundColor: const ChartPaint.solid(Colors.black),
      displayColors: false,
      bodyColor: const ChartPaint.solid(Fl.pink),
      bodyFont: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      callbacks: TooltipCallbacks(
        title: (tooltip, _) => null,
        label: (tooltip, i) {
          final p = i.parsed! as JsObjectFace;
          return ['${p['x']}, ${(p['y']! as num).toStringAsFixed(2)}'];
        },
      ),
    ),
    plugins: [touchIndicator(color: Fl.pink, fromValue: 0)],
    scales: {
      'x': LinearAxis(
        min: -5,
        max: 5,
        grid: AxisGrid(
          drawTicks: false,
          lineWidth: 0.8,
          extra: {'color': (JsObjectFace c) => _zero(c, Fl.yellow)},
        ),
        extra: _axis(Fl.yellow),
        ticks: const AxisTicks(
          stepSize: 1,
          color: ChartPaint.solid(Fl.blue),
          maxRotation: 0,
          font: _font,
          padding: 16,
        ),
      ),
      'y': LinearAxis(
        min: -1.5,
        max: 1.5,
        grid: AxisGrid(
          drawTicks: false,
          lineWidth: 0.8,
          extra: {'color': (JsObjectFace c) => _zero(c, Fl.blue)},
        ),
        extra: _axis(Fl.blue),
        ticks: AxisTicks(
          stepSize: 0.5,
          color: const ChartPaint.solid(Fl.yellow),
          font: _font,
          padding: 16,
          callback: (scale, value, index, ticks) => [
            if (value % 1 == 0) '${value.toInt()}' else '$value',
          ],
        ),
      ),
    },
  ),
);

class const Sample9({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
    child: AspectRatio(aspectRatio: 1, child: ChartView(config: _config)),
  );
}
// #enddocregion fl_chart-09
