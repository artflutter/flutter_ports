// Original code, not ported from Chart.js: a replica of the Graphic demo "Spider Net Chart".
// ignore_for_file: lines_longer_than_80_chars
// #docregion graphic-spider-net
import 'package:chartjs_docs/migrate/graphic/graphic_data.dart';
import 'package:chartjs_docs/migrate/graphic/graphic_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

final List<String> _types = {for (final row in adjustData) row.type}.toList();
final List<String> _indexes = {
  for (final row in adjustData) row.index.toString(),
}.toList();

List<int> _values(String type) => [
  for (final row in adjustData)
    if (row.type == type) row.value,
];

final ({double min, double max}) _range = graphicRange([
  for (final row in adjustData) row.value,
]);

/// The radial axis of Graphic is a line up from the center, with the labels
/// of the round values on its left. Chart.js draws its tick labels along the
/// start angle, so this plugin draws the axis of Graphic instead.
final Map<String, Object?> _radialAxis = {
  'id': 'radialAxis',
  'beforeDatasetsDraw': (Chart chart, Object? args, Object? options) {
    final scale = chart.scales['r']! as RadialLinearScale;
    final x = scale.xCenter!;
    final y = scale.yCenter!;
    final ctx = chart.ctx!
      ..save()
      ..strokeStyle = Gx.stroke
      ..lineWidth = 1
      ..beginPath()
      ..moveTo(x, y)
      ..lineTo(x, y - scale.drawingArea)
      ..stroke()
      ..fillStyle = Gx.text
      ..font = const TextStyle(
        fontFamily: 'Helvetica Neue',
        fontFamilyFallback: ['Helvetica', 'Arial', 'sans-serif'],
        fontSize: 10,
      )
      ..textAlign = TextAlign.right
      ..textBaseline = CanvasTextBaseline.middle;
    for (final tick in scale.ticks ?? const <Tick>[]) {
      if (tick.value % 100 != 0) continue;
      final radius = scale.getDistanceFromCenterForValue(tick.value);
      ctx.fillText(tick.value.toString(), x, y - radius);
    }
    ctx.restore();
  },
};

/// `multiTuples: true`: the index, then one line for each type.
String? _index(List<ChartTooltipItem> items) => _indexes[items.first.dataIndex];

String? _typeValue(ChartTooltipItem item) =>
    '${_types[item.datasetIndex]}: ${item.raw}';

final ChartConfig _config = ChartConfig(
  type: .radar,
  labels: _indexes,
  datasets: [
    // `BasicLineShape(loop: true)` in a `PolarCoord` is a radar line.
    for (final (i, type) in _types.indexed)
      RadarDataset(
        label: type,
        data: _values(type),
        borderColor: .constant(.solid(Gx.colors10[i])),
        borderWidth: 2,
        fill: ChartFill.none,
        pointRadius: 0,
        pointHoverRadius: 0,
      ),
  ],
  scales: {
    'r': RadialLinearAxis(
      min: _range.min,
      max: _range.max,
      // An ordinal scale of Graphic puts each index in the middle of a band
      // of 360 / 7 degrees.
      startAngle: 360 / 7 / 2,
      grid: const AxisGrid(
        color: ChartPaint.solid(Gx.stroke),
        extra: {'circular': true},
      ),
      angleLinesColor: const ChartPaint.solid(Gx.stroke),
      pointLabelsColor: const ChartPaint.solid(Gx.text),
      pointLabelsFont: const TextStyle(fontSize: 10),
      pointLabelsPadding: 4,
      // The ticks at the round values give the circles of the grid, and
      // the tick at the max gives the outer circle: the circular axis line
      // of Graphic.
      ticks: const AxisTicks(
        display: false,
        stepSize: 100,
        extra: {'includeBounds': true},
      ),
    ),
  },
  maintainAspectRatio: false,
  animation: ChartAnimation.none,
  legend: const ChartLegend(display: false),
  // `PointSelection(dim: Dim.x, variable: 'index')`: all types at the index
  // of the point nearest to the pointer.
  interaction: const ChartInteraction(
    mode: IndexInteractionMode(),
    intersect: false,
    axis: .xy,
  ),
  tooltip: graphicTooltip(
    position: const TopLeftPositioner(),
    title: _index,
    label: _typeValue,
  ),
  plugins: [_radialAxis, polarCrosshair, tooltipShadow],
);

/// The replica of the Graphic demo "Spider Net Chart".
class GraphicSpiderNet extends StatelessWidget {
  /// Creates the replica.
  const GraphicSpiderNet({super.key});

  @override
  Widget build(BuildContext context) => graphicBox(
    ChartView(
      config: _config,
      semanticLabel: 'Spider net chart of five channels at seven indexes',
    ),
  );
}
// #enddocregion graphic-spider-net
