// Original code, not ported from Chart.js: a replica of the Graphic demo "River chart".
// ignore_for_file: lines_longer_than_80_chars
// #docregion graphic-river
import 'package:chartjs_docs/migrate/graphic/graphic_data.dart';
import 'package:chartjs_docs/migrate/graphic/graphic_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

final List<String> _dates = {for (final (date, _, _) in riverData) date}
    .toList();
final List<String> _types = {for (final (_, _, type) in riverData) type}
    .toList();
final Map<(String, String), int> _values = {
  for (final (date, value, type) in riverData) (date, type): value,
};

int _value(int type, int date) => _values[(_dates[date], _types[type])]!;

/// `StackModifier`: the sum of the values of the types up to [type].
int _stack(int type, int date) {
  var sum = 0;
  for (var t = 0; t <= type; t++) {
    sum += _value(t, date);
  }
  return sum;
}

/// `SymmetricModifier`: each stack is centered on 0, so it starts at minus
/// half of its total.
final List<double> _base = [
  for (var d = 0; d < _dates.length; d++) -_stack(_types.length - 1, d) / 2,
];

/// The top edge of the band of [type].
List<double> _topEdge(int type) => [
  for (var d = 0; d < _dates.length; d++) _base[d] + _stack(type, d),
];

/// Each band fills to the edge below it: the first band to the base, the
/// last dataset.
LineDataset _band(int type) => LineDataset(
  label: _types[type],
  data: _topEdge(type),
  fill: type == 0 ? FillTarget.toDataset(_types.length) : .toPrevious,
  backgroundColor: .constant(.solid(Gx.colors10[type])),
  borderWidth: 0,
  // `BasicAreaShape(smooth: true)` is a Catmull-Rom spline with the
  // tension 0.5 of Chart.js.
  tension: 0.5,
  pointRadius: 0,
  pointHoverRadius: 0,
);

/// `OrdinalScale(tickCount: 5)`.
List<String>? _dateLabel(
  Scale scale,
  double value,
  int index,
  List<Tick> ticks,
) => ordinalTick(index, _dates.length, 5) ? [_dates[index]] : null;

/// `multiTuples: true`: the date, then one line for each type.
String? _date(List<TooltipItem> items) => _dates[items.first.dataIndex];

String? _typeValue(TooltipItem item) =>
    '${_types[item.datasetIndex]}: ${_value(item.datasetIndex, item.dataIndex)}';

/// The tooltip leaves out the base.
bool _isBand(
  TooltipItem item,
  int index,
  List<TooltipItem> items,
  Object data,
) => item.datasetIndex < _types.length;

final ChartConfig _config = ChartConfig(
  type: .line,
  labels: _dates,
  datasets: [
    for (var t = 0; t < _types.length; t++) _band(t),
    LineDataset(
      label: 'base',
      data: _base,
      borderWidth: 0,
      tension: 0.5,
      pointRadius: 0,
      pointHoverRadius: 0,
    ),
  ],
  scales: {
    'x': CategoryAxis(
      grid: noGrid,
      ticks: graphicTicks(callback: _dateLabel),
      border: bottomBorder,
      extra: const {...bottomAxis, 'offset': true},
    ),
    'y': LinearAxis(
      min: -120,
      max: 120,
      grid: lineGrid,
      ticks: graphicTicks(callback: numberLabel, stepSize: 40),
      border: leftBorder,
      extra: leftAxis,
    ),
  },
  padding: regionPadding,
  maintainAspectRatio: false,
  animation: ChartAnimation.none,
  legend: const ChartLegend(display: false),
  // `PointSelection(dim: Dim.x, variable: 'date')`: all types at the date
  // nearest to the pointer.
  interaction: const ChartInteraction(
    mode: IndexInteractionMode(),
    intersect: false,
  ),
  tooltip: graphicTooltip(
    position: const FollowYPositioner(),
    title: _date,
    label: _typeValue,
    filter: _isBand,
  ),
  plugins: [crosshair(), tooltipShadow],
);

/// The replica of the Graphic demo "River chart".
class const GraphicRiver({super.key}) extends StatelessWidget {
  /// Creates the replica.
  this;

  @override
  Widget build(BuildContext context) => graphicBox(
    ChartView(
      config: _config,
      semanticLabel: 'River chart of six types by date',
    ),
  );
}
// #enddocregion graphic-river
