// Original code, not ported from Chart.js: a replica of the Graphic demo "Area chart".
// ignore_for_file: lines_longer_than_80_chars
// #docregion graphic-area
import 'package:chartjs_docs/migrate/graphic/graphic_data.dart';
import 'package:chartjs_docs/migrate/graphic/graphic_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

/// `(map['Close'] ?? double.nan)`: a `null` close is a NaN, a gap.
num _close(int index) => invalidData[index].close ?? double.nan;

final ({double min, double max}) _range = graphicRange([
  for (var i = 0; i < invalidData.length; i++) _close(i),
]);

/// `OrdinalScale(tickCount: 5)`: 5 labels at a regular step.
List<String>? _dateLabel(
  Scale scale,
  double value,
  int index,
  List<Tick> ticks,
) => ordinalTick(index, invalidData.length, 5)
    ? [invalidData[index].date]
    : null;

String? _date(List<TooltipItem> items) =>
    'Date: ${invalidData[items.first.dataIndex].date}';

String? _value(TooltipItem item) => 'Close: ${_close(item.dataIndex)}';

final ChartConfig _config = ChartConfig(
  type: .line,
  labels: [for (final day in invalidData) day.date],
  datasets: [
    LineDataset(
      data: [for (var i = 0; i < invalidData.length; i++) _close(i)],
      // The `LineMark` of 0.5 px over the `AreaMark` in the first color.
      borderColor: const .constant(.solid(Gx.primary)),
      borderWidth: 0.5,
      backgroundColor: .constant(.solid(Gx.colors10.first.withAlpha(80))),
      fill: .toStart,
      pointRadius: 0,
      pointHoverRadius: 0,
    ),
  ],
  scales: {
    'x': CategoryAxis(
      grid: noGrid,
      ticks: graphicTicks(callback: _dateLabel),
      // An ordinal scale of Graphic puts each value in the middle of a band.
      border: bottomBorder,
      extra: const {...bottomAxis, 'offset': true},
    ),
    'y': LinearAxis(
      min: _range.min,
      max: _range.max,
      grid: lineGrid,
      ticks: graphicTicks(callback: numberLabel, stepSize: 10),
      border: leftBorder,
      extra: leftAxis,
    ),
  },
  padding: regionPadding,
  maintainAspectRatio: false,
  animation: ChartAnimation.none,
  legend: const ChartLegend(display: false),
  interaction: const ChartInteraction(
    mode: IndexInteractionMode(),
    intersect: false,
  ),
  tooltip: graphicTooltip(
    position: const FollowYPositioner(),
    title: _date,
    label: _value,
  ),
  plugins: [crosshair(), tooltipShadow],
);

/// The replica of the Graphic demo "Area chart".
class const GraphicArea({super.key}) extends StatelessWidget {
  /// Creates the replica.
  this;

  @override
  Widget build(BuildContext context) => graphicBox(
    ChartView(
      config: _config,
      semanticLabel: 'Area chart of the close prices of a stock, with gaps',
    ),
  );
}
// #enddocregion graphic-area
