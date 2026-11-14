// Original code, not ported from Chart.js: a replica of the Syncfusion demo "Default bar chart".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion sf-default-bar
import 'package:chartjs_docs/migrate/syncfusion/sf_bar_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

// A BarSeries. Syncfusion puts the first series at the bottom of each
// category: `order` gives the last series the first place from the top.
BarDataset _arrivals(String year, Color color, int order, List<num> data) =>
    BarDataset(
      label: year,
      data: data,
      order: order,
      backgroundColor: .constant(.solid(color)),
      hoverBackgroundColor: .constant(.solid(color)),
      categoryPercentage: 0.7,
      barPercentage: 1,
    );

final ChartConfig _config = ChartConfig(
  type: .bar,
  indexAxis: const YAxis(),
  labels: const ['France', 'Spain', 'US', 'Italy', 'Mexico', 'UK'],
  datasets: [
    _arrivals('2015', Sf.blue, 2, const [
      84452000,
      68175000,
      77774000,
      50732000,
      32093000,
      34436000,
    ]),
    _arrivals('2016', Sf.purple, 1, const [
      82682000,
      75315000,
      76407000,
      52372000,
      35079000,
      35814000,
    ]),
    _arrivals('2017', Sf.slate, 0, const [
      86861000,
      81786000,
      76941000,
      58253000,
      39291000,
      37651000,
    ]),
  ],
  maintainAspectRatio: false,
  padding: sfPadding,
  title: sfTitle('Tourism - Number of arrivals'),
  // `order` also sorts the legend: reverse gives 2015, 2016, 2017.
  legend: sfLegend(const SfBarIcon(), reverse: true),
  tooltip: sfTooltip(
    header: true,
    text: (item) => '${item.label.join(' ')} : ${sfCompact(sfValue(item))}',
  ),
  plugins: [sfTooltipLook],
  scales: {
    // The first category at the bottom, as in Syncfusion.
    'y': sfCategoryAxis(reverse: true),
    // numberFormat: NumberFormat.compact(), no grid lines.
    'x': sfValueAxis(
      min: 0,
      max: 100000000,
      stepSize: 10000000,
      callback: sfCompactTick,
      grid: false,
      line: true,
      ticks: true,
    ),
  },
);

class const SfDefaultBar({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 320, child: ChartView(config: _config));
}
// #enddocregion sf-default-bar
