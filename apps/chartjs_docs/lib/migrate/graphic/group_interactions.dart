// Original code, not ported from Chart.js: a replica of the Graphic demo "Group interactions".
// ignore_for_file: lines_longer_than_80_chars
// #docregion graphic-group-interactions
import 'package:chartjs_docs/migrate/graphic/graphic_data.dart';
import 'package:chartjs_docs/migrate/graphic/graphic_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

/// The dates and the names in the order of the data, as the ordinal scales
/// of Graphic take them.
final List<String> _dates = {for (final row in complexGroupData) row.date}
    .toList();
final List<String> _names = {for (final row in complexGroupData) row.name}
    .toList();
final Map<(String, String), int> _points = {
  for (final row in complexGroupData) (row.date, row.name): row.points,
};

/// `Varset('name')` splits the data in groups: one dataset for each name.
/// A name has no points on some dates: `spanGaps` joins its points.
LineDataset _group(int index, String name) {
  final color = Gx.colors10[index];
  return LineDataset(
    label: name,
    data: [for (final date in _dates) _points[(date, name)]],
    spanGaps: true,
    borderColor: .constant(.solid(color)),
    borderWidth: 0.5,
    // The `PointMark`.
    pointRadius: 2.5,
    pointBorderWidth: 0,
    pointBackgroundColor: .constant(.solid(color)),
    pointHoverRadius: 2.5,
    pointHoverBackgroundColor: .constant(.solid(color)),
    extra: const {'pointHoverBorderWidth': 0},
  );
}

/// The `updaters` of `ColorEncode`: when a point is selected, the other
/// groups fade to the alpha 100.
final Map<String, Object?> _fadeOtherGroups = {
  'id': 'fadeOtherGroups',
  'beforeDatasetDraw': (Chart chart, Object? args, Object? options) {
    final index = (args! as JsObjectFace)['index']! as num;
    final active = chart.getActiveElements();
    final ctx = chart.ctx!..save();
    if (active.isNotEmpty && active.first.datasetIndex != index) {
      ctx.globalAlpha = 100 / 255;
    }
  },
  'afterDatasetDraw': (Chart chart, Object? args, Object? options) =>
      chart.ctx!.restore(),
};

/// `OrdinalScale(tickCount: 5, inflate: true)`.
List<String>? _dateLabel(
  Scale scale,
  double value,
  int index,
  List<Tick> ticks,
) => ordinalTick(index, _dates.length, 5) ? [_dates[index]] : null;

final ({double min, double max}) _range = graphicRange(_points.values);

/// `variables: ['date', 'name', 'points']`.
String? _dateAndName(List<TooltipItem> items) =>
    'date: ${_dates[items.first.dataIndex]}\n'
    'name: ${_names[items.first.datasetIndex]}';

String? _value(TooltipItem item) => 'points: ${item.raw}';

final ChartConfig _config = ChartConfig(
  type: .line,
  labels: _dates,
  datasets: [for (final (i, name) in _names.indexed) _group(i, name)],
  scales: {
    'x': CategoryAxis(
      grid: noGrid,
      ticks: graphicTicks(callback: _dateLabel),
      border: bottomBorder,
      extra: bottomAxis,
    ),
    'y': LinearAxis(
      min: _range.min,
      max: _range.max,
      grid: lineGrid,
      ticks: graphicTicks(callback: numberLabel, stepSize: 25),
      border: leftBorder,
      extra: leftAxis,
    ),
  },
  padding: regionPadding,
  maintainAspectRatio: false,
  animation: ChartAnimation.none,
  legend: const ChartLegend(display: false),
  // A `PointSelection` without `dim`: the point nearest to the pointer.
  interaction: const ChartInteraction(
    mode: NearestInteractionMode(),
    intersect: false,
  ),
  tooltip: graphicTooltip(
    position: const AtPointerPositioner(),
    title: _dateAndName,
    label: _value,
  ),
  plugins: [
    _fadeOtherGroups,
    // The crosshair follows the pointer in x and has no horizontal line.
    crosshair(followX: true, horizontal: false),
    tooltipShadow,
  ],
);

/// The replica of the Graphic demo "Group interactions".
class const GraphicGroupInteractions({super.key}) extends StatelessWidget {
  /// Creates the replica.
  this;

  @override
  Widget build(BuildContext context) => graphicBox(
    ChartView(
      config: _config,
      semanticLabel: 'Line chart of the points of four players by date',
    ),
  );
}
// #enddocregion graphic-group-interactions
