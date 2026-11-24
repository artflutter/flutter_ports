// Original code, not ported from Chart.js: fl_chart line sample 9.
// ignore_for_file: public_member_api_docs
// #docregion fl_chart-09
import 'dart:math';

import 'package:chartjs_docs/migrate/fl_chart/fl_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _font = TextStyle(fontWeight: FontWeight.bold, fontSize: 18);

ChartPaint _zero(Object? c, Color color) =>
    .solid(tickOf(c) == 0 ? color : Colors.transparent);

/// The grid dash of both axes, and no axis line.
const AxisBorder _border = AxisBorder(dash: [8, 2], display: false);

/// The title of the tooltip: null keeps the title of Chart.js.
List<String>? _tooltipTitle(TooltipModel tooltip, List<TooltipItem> items) =>
    null;

/// The label of the tooltip: x, then y with two decimals.
List<String> _tooltipLabel(TooltipModel tooltip, TooltipItem item) {
  final p = item.parsed! as JsObjectFace;
  return ['${p['x']}, ${(p['y']! as num).toStringAsFixed(2)}'];
}

final ChartConfig _config = fills(
  ChartConfig(
    datasets: [
      LineDataset(
        data: .points([
          for (var i = 0; i <= 100; i++)
            DataPoint((i - 50) / 10, cos((i - 50) / 10)),
        ]),
        tension: 0.35,
        borderWidth: 3,
        pointRadius: const .constant(0),
        pointHoverRadius: const .constant(8),
        borderColor: const .constant(.solid(Fl.pink)),
        borderCapStyle: StrokeCap.round,
      ),
    ],
    interaction: const ChartInteraction(
      mode: NearestInteractionMode(),
      intersect: false,
      axis: .x,
    ),
    pluginOptions: const [
      TooltipOptions(
        backgroundColor: ChartPaint.solid(Colors.black),
        displayColors: false,
        bodyColor: ChartPaint.solid(Fl.pink),
        bodyFont: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        callbacks: TooltipCallbacks(title: _tooltipTitle, label: _tooltipLabel),
      ),
    ],
    plugins: [touchIndicator(color: Fl.pink, fromValue: 0)],
    scales: [
      LinearAxis(
        .x,
        min: -5,
        max: 5,
        grid: AxisGrid(
          drawTicks: false,
          lineWidth: const .constant(0.8),
          color: .resolver((c) => _zero(c, Fl.yellow)),
        ),
        border: _border,
        ticks: const AxisTicks(
          stepSize: 1,
          color: .constant(ChartPaint.solid(Fl.blue)),
          maxRotation: 0,
          font: .constant(_font),
          padding: 16,
        ),
      ),
      LinearAxis(
        .y,
        min: -1.5,
        max: 1.5,
        grid: AxisGrid(
          drawTicks: false,
          lineWidth: const .constant(0.8),
          color: .resolver((c) => _zero(c, Fl.blue)),
        ),
        border: _border,
        ticks: AxisTicks(
          stepSize: 0.5,
          color: const .constant(ChartPaint.solid(Fl.yellow)),
          font: const .constant(_font),
          padding: 16,
          callback: (scale, value, index, ticks) => [
            if (value % 1 == 0) '${value.toInt()}' else '$value',
          ],
        ),
      ),
    ],
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

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Fl.item,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ChartTheme(data: ChartThemeData.dark(), child: Sample9()),
        ),
      ),
    ),
  );
}
