// Original code, not ported from Chart.js: a replica of the Syncfusion demo "Bar with rounded corners".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion sf-rounded-bar
import 'package:chartjs_docs/migrate/syncfusion/sf_bar_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

final ChartConfig _config = ChartConfig(
  indexAxis: const YAxis(),
  labels: const [
    'Iceland',
    'Moldova',
    'Malaysia',
    'American Samoa',
    'Singapore',
    'Puerto Rico',
    'Algeria',
  ],
  datasets: const [
    BarDataset(
      data: [1.13, -1.05, 1.37, -1.3, 1.82, -1.74, 1.7],
      backgroundColor: .constant(.solid(Sf.blue)),
      hoverBackgroundColor: .constant(.solid(Sf.blue)),
      categoryPercentage: 0.7,
      barPercentage: 1,
      // borderRadius: BorderRadius.all(Radius.circular(10)): all corners.
      borderRadius: 10,
      extra: {'borderSkipped': false},
    ),
  ],
  maintainAspectRatio: false,
  padding: sfPadding,
  title: sfTitle('Population growth rate of countries'),
  legend: const ChartLegend(display: false),
  tooltip: sfTooltip(
    text: (item) => '${item.label.join(' ')} : ${sfNumber(sfValue(item))}',
  ),
  plugins: [sfTooltipLook],
  scales: {
    'y': sfCategoryAxis(reverse: true),
    // minimum: -2, maximum: 2, grid lines and an axis line, no tick marks.
    'x': sfValueAxis(min: -2, max: 2, stepSize: 0.5, line: true),
  },
);

class const SfRoundedBar({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 320, child: ChartView(config: _config));
}
// #enddocregion sf-rounded-bar

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: SfRoundedBar(),
        ),
      ),
    ),
  );
}
