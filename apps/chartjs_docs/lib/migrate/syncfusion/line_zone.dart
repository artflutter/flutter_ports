// Original code, not ported from Chart.js: a replica of the Syncfusion demo "Line zone".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion sf-line-zone
import 'dart:math' as math;

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _text = Color(0xFF49454F);
const _axisLine = Color(0xFFCAC4D0);
const _grid = Color(0xFFE6E0E9);
const _tooltip = Color(0xFF322F35);

const _high = Color.fromRGBO(4, 8, 195, 1);
const _medium = Color.fromRGBO(26, 112, 23, 1);
const _low = Color.fromRGBO(229, 11, 10, 1);

// The rainfall of each year from 1950.
const List<double> _rainfall = [
  30.87, 31.25, 28.31, 26.15, 27.74, 25.38, 33.87, 30.23, 30.6, 28.75, //
  31.25, 28.6, 25.7, 30.26, 29.8, 27.26, 29.6, 30.39, 30.63, 29.7,
  30.33, 31.7, 34.96, 30.62, 33.03, 26.31, 30.44, 30.14, 32.75, 28.27,
  29.96, 33.86, 34.76, 31.4, 29.97, 31.38, 29.01, 25.9, 29.05, 32.17,
  32.44, 31.26, 32.62, 30.62, 32.69, 33.7, 31.86, 33.89, 28.47, 28.22,
  29.02, 29.05, 30.51, 33.25, 30.08, 29.82, 29.18, 31.24, 32.3, 31.37,
  30.1,
];

// onCreateShader: a vertical gradient over the bounds of the line, with
// three hard bands. The top third is high, the bottom third is low.
Object? _zones(JsObjectFace context) {
  final chart = context['chart']! as Chart;
  if (chart.chartArea == null) return _medium;
  final y = chart.scales['y']!;
  final top = y.getPixelForValue(_rainfall.reduce(math.max));
  final bottom = y.getPixelForValue(_rainfall.reduce(math.min));
  final gradient = chart.ctx!.createLinearGradient(0, top, 0, bottom);
  const stops = [0.0, 1 / 3, 1 / 3, 2 / 3, 2 / 3, 1.0];
  const colors = [_high, _high, _medium, _medium, _low, _low];
  for (var i = 0; i < stops.length; i++) {
    gradient.addColorStop(stops[i], colors[i]);
  }
  return gradient;
}

String? _mm(AxisTickInfo tick) => '${tick.value.round()}mm';

String? _tooltipLabel(ChartTooltipItem item) =>
    '${item.label} : ${item.formattedValue}mm';

List<String> _noTitle(TooltipModel tooltip, List<ChartTooltipItem> items) =>
    const [];

// The annotation of the original: a key of the three zones, at 95 % and
// 19 % of the plot area.
final Map<String, Object?> _zoneKey = {
  'id': 'zoneKey',
  'afterDraw': (Chart chart, Object? args, Object? options) {
    final area = chart.chartArea!;
    final x = area.left + area.width * 0.95 - 40;
    var y = area.top + area.height * 0.19 - 30;
    final ctx = chart.ctx!
      ..save()
      ..font = const TextStyle(fontFamily: 'sans-serif', fontSize: 14)
      ..textBaseline = CanvasTextBaseline.middle
      ..textAlign = TextAlign.left;
    for (final (color, text) in [
      (_high, 'High'),
      (_medium, 'Medium'),
      (_low, 'Low'),
    ]) {
      ctx
        ..fillStyle = color
        ..beginPath()
        ..arc(x + 6, y + 9, 5.5, 0, 2 * math.pi)
        ..fill()
        ..fillStyle = Colors.black87
        ..fillText(' $text', x + 13, y + 9);
      y += 20;
    }
    ctx.restore();
  },
};

final ChartConfig _config = ChartConfig(
  type: .line,
  datasets: [
    LineDataset(
      label: 'Rainfall',
      points: [
        for (final (i, mm) in _rainfall.indexed)
          DataPoint.time(DateTime(1950 + i), mm),
      ],
      borderWidth: 2,
      pointRadius: 0,
      pointHoverRadius: 0,
      extra: const {'borderColor': _zones},
    ),
  ],
  maintainAspectRatio: false,
  padding: const EdgeInsets.all(10),
  title: const ChartTitle(
    display: true,
    text: 'Average annual rainfall of United Kingdom',
    color: _text,
    font: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
  ),
  legend: const ChartLegend(display: false),
  // TrackballBehavior(lineType: none): a tooltip at the nearest year.
  interaction: const ChartInteraction(
    mode: NearestInteractionMode(),
    intersect: false,
    axis: .x,
  ),
  tooltip: ChartTooltip(
    backgroundColor: _tooltip,
    displayColors: false,
    yAlign: .bottom,
    extra: const {},
    callbacks: TooltipCallbacks(
      title: _noTitle,
      label: (tooltip, arg) {
        final text = _tooltipLabel(arg);
        return text == null
            ? null
            : text.isEmpty
            ? <String>[]
            : [text];
      },
    ),
  ),
  plugins: [_zoneKey],
  scales: const {
    // DateTimeAxis(interval: 5, intervalType: years, edge labels shifted)
    'x': TimeAxis(
      unit: .year,
      tooltipFormat: 'yyyy',
      grid: AxisGrid(
        drawOnChartArea: false,
        color: _axisLine,
        extra: {'tickLength': 6},
      ),
      ticks: AxisTicks(
        stepSize: 5,
        maxRotation: 0,
        color: _text,
        font: TextStyle(fontSize: 12),
        align: .inner,
      ),
      extra: {
        'border': {'color': _axisLine},
      },
    ),
    'y': LinearAxis(
      min: 24,
      max: 36,
      grid: AxisGrid(color: _grid, lineWidth: 0.7, drawTicks: false),
      ticks: AxisTicks(
        stepSize: 2,
        padding: 8,
        color: _text,
        font: TextStyle(fontSize: 12),
        format: _mm,
      ),
      extra: {
        'border': {'display': false},
      },
    ),
  },
);

class SfLineZone extends StatelessWidget {
  const SfLineZone({super.key});

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 320, child: ChartView(config: _config));
}
// #enddocregion sf-line-zone
