// Original code, not ported from Chart.js: a replica of the Graphic demo "Custom Legend".
// ignore_for_file: lines_longer_than_80_chars
// #docregion graphic-bar-custom-legend
import 'package:chartjs_docs/migrate/graphic/graphic_bar_kit.dart';
import 'package:chartjs_docs/migrate/graphic/graphic_data.dart';
import 'package:chartjs_docs/migrate/graphic/graphic_kit.dart';
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart'
    show zoomPlugin;
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

/// `size: SizeEncode(value: 2)` and `DodgeModifier(ratio: 0.1)`: bars of
/// 2 px, side by side at a step of 0.1 of the band. The 5 steps take half of
/// the band.
BarDataset _type(int index, String type) {
  final color = ChartValue<ChartPaint>.constant(.solid(Gx.colors10[index]));
  return BarDataset(
    label: type,
    data: _values(type),
    backgroundColor: color,
    hoverBackgroundColor: color,
    categoryPercentage: 0.5,
    barPercentage: 1,
    maxBarThickness: 2,
    // The bars start at the bottom of the axis.
    extra: {'base': _range.min},
  );
}

String? _index(List<TooltipItem> items) => _indexes[items.first.dataIndex];

String? _typeValue(TooltipItem item) =>
    '${_types[item.datasetIndex]}: ${item.raw}';

final ChartConfig _config = ChartConfig(
  labels: _indexes,
  datasets: [for (final (i, type) in _types.indexed) _type(i, type)],
  scales: [
    CategoryAxis(
      .x,
      // `tickLine = TickLine()`: a line of 5 px under each label.
      grid: const AxisGrid(
        color: .solid(Gx.stroke),
        drawOnChartArea: false,
        offset: false,
        tickLength: 5,
      ),
      // The labels stay 7.5 px under the axis line.
      ticks: graphicTicks(extra: const {'padding': 2.5}),
      border: bottomBorder,
      extra: bottomAxis,
    ),
    LinearAxis(
      .y,
      min: _range.min,
      max: _range.max,
      grid: lineGrid,
      ticks: graphicTicks(callback: numberLabel, stepSize: 100),
      border: leftBorder,
      extra: leftAxis,
    ),
  ],
  padding: regionPadding,
  maintainAspectRatio: false,
  animation: ChartAnimation.none,
  // The legend of the annotations: a circle of radius 5 and a label of 10
  // px for each type, in the 20 px under the axis.
  legend: const ChartLegend(
    position: .bottom,
    labelColor: .solid(Gx.text),
    labelFont: TextStyle(fontSize: 10),
    usePointStyle: true,
    // The radius of the circle is `boxHeight` / √2.
    boxHeight: 7.07,
    labelPadding: 5,
    extra: {'maxHeight': 20},
  ),
  interaction: const ChartInteraction(
    mode: IndexInteractionMode(),
    intersect: false,
  ),
  tooltip: graphicTooltip(
    position: const CenterPositioner(),
    title: _index,
    label: _typeValue,
  ),
  plugins: [
    barCrosshair,
    tooltipShadow,
    zoomPlugin,
    tapSelection(onDoubleTap: resetRange),
  ],
  pluginOptions: const [horizontalRange],
  events: const ['click'],
);

/// The replica of the Graphic demo "Custom Legend".
class const GraphicBarCustomLegend({super.key}) extends StatelessWidget {
  /// Creates the replica.
  this;

  @override
  Widget build(BuildContext context) => GraphicBox(
    child: ChartView(
      config: _config,
      semanticLabel: 'Grouped bar chart of the values of five channels',
    ),
  );
}
// #enddocregion graphic-bar-custom-legend

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: GraphicBarCustomLegend(),
        ),
      ),
    ),
  );
}
