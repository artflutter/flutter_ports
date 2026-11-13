// Original code, not ported from Chart.js: a replica of the Graphic demo "Time series line chart".
// ignore_for_file: lines_longer_than_80_chars
// #docregion graphic-time-series
import 'package:chartjs_docs/migrate/graphic/graphic_data.dart';
import 'package:chartjs_docs/migrate/graphic/graphic_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

String _two(int value) => value.toString().padLeft(2, '0');

/// The `MM-dd` format of the demo.
String _monthDay(DateTime time) => '${_two(time.month)}-${_two(time.day)}';

List<String>? _timeLabel(
  Scale scale,
  double value,
  int index,
  List<Tick> ticks,
) => [_monthDay(DateTime.fromMillisecondsSinceEpoch(value.round()))];

/// The `TimeScale` of Graphic adds 10% of the range on each side.
final DateTime _first = timeSeriesSales.first.time;
final DateTime _last = timeSeriesSales.last.time;
final Duration _margin = _last.difference(_first) * 0.1;
final DateTime _min = _first.subtract(_margin);
final DateTime _max = _last.add(_margin);

/// The `TimeScale` of Graphic has 5 ticks at equal steps from min to max.
/// The time axis takes them from `labels` with the tick source `labels`.
final List<DateTime> _ticks = [
  for (var i = 0; i <= 4; i++) _min.add(_max.difference(_min) * (i / 4)),
];

final ({double min, double max}) _range = graphicRange([
  for (final sale in timeSeriesSales) sale.sales,
]);

String? _time(List<TooltipItem> items) =>
    'time: ${_monthDay(timeSeriesSales[items.first.dataIndex].time)}';

String? _sales(TooltipItem item) =>
    'sales: ${timeSeriesSales[item.dataIndex].sales}';

final ChartConfig _config = ChartConfig(
  type: .line,
  labels: _ticks,
  datasets: [
    LineDataset(
      points: [
        for (final sale in timeSeriesSales)
          DataPoint.time(sale.time, sale.sales),
      ],
      borderColor: const .constant(.solid(Gx.primary)),
      borderWidth: 2,
      borderDash: const [5, 2],
      pointRadius: 0,
      pointHoverRadius: 0,
    ),
  ],
  scales: {
    'x': TimeAxis(
      min: _min,
      max: _max,
      grid: noGrid,
      ticks: graphicTicks(callback: _timeLabel, source: .labels),
      extra: bottomAxis,
    ),
    'y': LinearAxis(
      min: _range.min,
      max: _range.max,
      grid: lineGrid,
      ticks: graphicTicks(callback: numberLabel, stepSize: 20),
      extra: leftAxis,
    ),
  },
  padding: regionPadding,
  maintainAspectRatio: false,
  animation: ChartAnimation.none,
  legend: const ChartLegend(display: false),
  // `PointSelection(dim: Dim.x)`: the point nearest to the pointer in x.
  interaction: const ChartInteraction(
    mode: IndexInteractionMode(),
    intersect: false,
  ),
  tooltip: graphicTooltip(
    position: const FollowYPositioner(),
    title: _time,
    label: _sales,
  ),
  plugins: [regionColor(const Color(0xffdddddd)), crosshair(), tooltipShadow],
);

/// `selected: {'touchMove': {1}}`: the second point starts selected.
void _preselect(Chart chart) {
  const selected = [ActiveElement(datasetIndex: 0, index: 1)];
  chart.setActiveElements(selected);
  chart.tooltip?.setActiveElements(selected);
  chart.update();
}

/// The replica of the Graphic demo "Time series line chart".
class const GraphicTimeSeries({super.key}) extends StatelessWidget {
  /// Creates the replica.
  this;

  @override
  Widget build(BuildContext context) => graphicBox(
    ChartView(
      config: _config,
      onChartCreated: _preselect,
      semanticLabel: 'Time series line chart of the sales of four weeks',
    ),
  );
}
// #enddocregion graphic-time-series
