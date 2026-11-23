// Original code, not ported from Chart.js: a replica of the Syncfusion demo "Back to back column".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion sf-back-to-back-column
import 'package:chartjs_docs/migrate/syncfusion/sf_bar_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

// A ColumnSeries with its own width. `order` draws the widest column first,
// so that the narrow ones stay in front.
BarDataset _series(
  String year,
  Color color,
  double width,
  int order,
  List<num> data,
) => BarDataset(
  label: year,
  data: .values(data),
  order: order,
  backgroundColor: .constant(.solid(color)),
  hoverBackgroundColor: .constant(.solid(color)),
  // enableSideBySideSeriesPlacement: false
  grouped: false,
  categoryPercentage: width,
  barPercentage: 1,
);

final ChartConfig _config = ChartConfig(
  labels: const ['France', 'United Kingdom', 'Italy'],
  datasets: [
    _series('2014', Sf.blue, 0.7, 2, const [66316092, 64613160, 60789140]),
    _series('2010', Sf.purple, 0.5, 1, const [65027507, 62766365, 59277417]),
    _series('2006', Sf.slate, 0.3, 0, const [63621381, 60846820, 58143979]),
  ],
  maintainAspectRatio: false,
  padding: sfPadding,
  title: sfTitle('Population of various countries'),
  // TooltipBehavior(enable: true): the series name, a marker and the point.
  // The tooltip takes the front column under the pointer.
  pluginOptions: [
    sfTooltip(
      header: true,
      mode: const PointInteractionMode(),
      filter: (item, index, items, data) => index == 0,
      text: (item) => '${item.label.join(' ')} : ${sfCompact(sfValue(item))}',
    ),
    const LegendOptions(display: false),
  ],
  plugins: [sfTooltipLook],
  scales: [
    sfCategoryAxis(),
    // numberFormat: NumberFormat.compact(), no grid lines, an axis line.
    sfValueAxis(
      min: 56000000,
      max: 70000000,
      stepSize: 2000000,
      callback: sfCompactTick,
      grid: false,
      line: true,
    ),
  ],
);

class const SfBackToBackColumn({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 320, child: ChartView(config: _config));
}
// #enddocregion sf-back-to-back-column

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: SfBackToBackColumn(),
        ),
      ),
    ),
  );
}
