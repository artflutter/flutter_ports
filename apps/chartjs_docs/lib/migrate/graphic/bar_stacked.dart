// Original code, not ported from Chart.js: a replica of the Graphic demo "Stacked Bar Chart".
// ignore_for_file: lines_longer_than_80_chars
// #docregion graphic-bar-stacked
import 'package:chartjs_docs/migrate/graphic/graphic_bar_kit.dart';
import 'package:chartjs_docs/migrate/graphic/graphic_data.dart';
import 'package:chartjs_docs/migrate/graphic/graphic_kit.dart';
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart'
    show zoomPlugin;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

/// The types and the indexes in the order of the data, as the ordinal
/// scales of Graphic take them.
final List<String> _types = {for (final row in adjustData) row.type}.toList();
final List<String> _indexes = {
  for (final row in adjustData) row.index.toString(),
}.toList();

List<int> _values(String type) => [
  for (final row in adjustData)
    if (row.type == type) row.value,
];

/// `Varset('index') * Varset('value') / Varset('type')`: one dataset for
/// each type, in the colors of `Defaults.colors10`.
BarDataset _type(int index, String type) {
  final color = ChartValue<ChartPaint>.constant(.solid(Gx.colors10[index]));
  return BarDataset(
    label: type,
    data: _values(type),
    backgroundColor: color,
    hoverBackgroundColor: color,
    barThickness: const BarThickness.pixels(barSize),
  );
}

/// The label of each bar: its own value, in white text of 6 px.
String _value(int dataset, int index) => '${_values(_types[dataset])[index]}';

/// `multiTuples: true`: the index, then one line for each type.
String? _index(List<TooltipItem> items) => _indexes[items.first.dataIndex];

String? _typeValue(TooltipItem item) =>
    '${_types[item.datasetIndex]}: ${item.raw}';

final ChartConfig _config = ChartConfig(
  labels: _indexes,
  datasets: [for (final (i, type) in _types.indexed) _type(i, type)],
  scales: [
    // `StackModifier()`.
    CategoryAxis(
      .x,
      stacked: StackMode.on,
      grid: noGrid,
      ticks: graphicTicks(),
      border: bottomBorder,
      extra: bottomAxis,
    ),
    LinearAxis(
      .y,
      stacked: StackMode.on,
      min: 0,
      max: 1800,
      grid: lineGrid,
      ticks: graphicTicks(callback: numberLabel),
      border: leftBorder,
      extra: {
        ...leftAxis,
        'afterBuildTicks': tickValues(const [0, 500, 1000, 1500]),
      },
    ),
  ],
  padding: regionPadding,
  maintainAspectRatio: false,
  animation: ChartAnimation.none,
  legend: const ChartLegend(display: false),
  // `PointSelection(variable: 'index')`: a tap selects all the bars of an
  // index.
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
    // `RectShape(labelPosition: 0.5)`: the label in the middle of the bar.
    barLabels(
      _value,
      position: 0.5,
      font: labelFont.copyWith(fontSize: 6),
      color: const Color(0xFFFFFFFF),
    ),
    barCrosshair,
    tooltipShadow,
    zoomPlugin,
    tapSelection(onDoubleTap: resetRange),
  ],
  pluginOptions: const [horizontalRange],
  extra: const {
    'events': ['click'],
  },
);

/// The replica of the Graphic demo "Stacked Bar Chart".
class const GraphicBarStacked({super.key}) extends StatelessWidget {
  /// Creates the replica.
  this;

  @override
  Widget build(BuildContext context) => GraphicBox(
    child: ChartView(
      config: _config,
      semanticLabel: 'Stacked bar chart of the values of five channels',
    ),
  );
}
// #enddocregion graphic-bar-stacked

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: GraphicBarStacked(),
        ),
      ),
    ),
  );
}
