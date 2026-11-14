// Original code, not ported from Chart.js: a replica of the Graphic demo "Custom Modifier".
// ignore_for_file: lines_longer_than_80_chars
// #docregion graphic-bar-custom-modifier
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

/// The `DodgeSizeModifier` of the demo fits the bars in their band, with
/// a space on each side of the group and between the bars. Chart.js fits
/// the bars this way by default: the group takes `categoryPercentage` of
/// the band, and each bar `barPercentage` of its part of the group.
BarDataset _type(int index, String type) {
  final color = ChartValue<ChartPaint>.constant(.solid(Gx.colors10[index]));
  return BarDataset(
    label: type,
    data: _values(type),
    backgroundColor: color,
    hoverBackgroundColor: color,
    categoryPercentage: 0.7,
    barPercentage: 0.67,
    // The bars start at the bottom of the axis.
    extra: {'base': _range.min},
  );
}

final ChartConfig _config = ChartConfig(
  type: .bar,
  labels: _indexes,
  datasets: [for (final (i, type) in _types.indexed) _type(i, type)],
  scales: {
    'x': CategoryAxis(
      // `tickLine = TickLine()`: a line of 5 px under each label.
      grid: const AxisGrid(
        color: .solid(Gx.stroke),
        drawOnChartArea: false,
        offset: false,
        extra: {'tickLength': 5},
      ),
      // The labels stay 7.5 px under the axis line.
      ticks: graphicTicks(extra: const {'padding': 2.5}),
      border: bottomBorder,
      extra: bottomAxis,
    ),
    'y': LinearAxis(
      min: _range.min,
      max: _range.max,
      grid: lineGrid,
      ticks: graphicTicks(callback: numberLabel, stepSize: 100),
      border: leftBorder,
      extra: leftAxis,
    ),
  },
  // `padding: (_) => const EdgeInsets.fromLTRB(40, 5, 10, 40)`: 20 px more
  // under the axis.
  padding: const EdgeInsets.only(top: 5, right: 10, bottom: 20),
  maintainAspectRatio: false,
  animation: ChartAnimation.none,
  legend: const ChartLegend(display: false),
  // The demo has no tooltip: a tap only feeds the double tap.
  tooltip: const ChartTooltip(enabled: false),
  plugins: [
    zoomPlugin,
    tapSelection(onDoubleTap: resetRange),
  ],
  extra: const {
    ...horizontalRange,
    'events': ['click'],
  },
);

/// The replica of the Graphic demo "Custom Modifier".
class const GraphicBarCustomModifier({super.key}) extends StatelessWidget {
  /// Creates the replica.
  this;

  @override
  Widget build(BuildContext context) => graphicBox(
    ChartView(
      config: _config,
      semanticLabel: 'Grouped bar chart of the values of five channels',
    ),
  );
}
// #enddocregion graphic-bar-custom-modifier
