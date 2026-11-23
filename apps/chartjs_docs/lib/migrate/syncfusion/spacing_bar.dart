// Original code, not ported from Chart.js: a replica of the Syncfusion demo "Bar width and spacing".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion sf-spacing-bar
import 'package:chartjs_docs/migrate/syncfusion/sf_bar_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _years = [2006, 2007, 2008, 2009, 2010];

// The points are {x: value, y: year}: the index axis of the bars is y.
BarDataset _trade(
  String name,
  Color color,
  int order,
  List<num> values,
  double width,
  double spacing,
) => BarDataset(
  label: name,
  data: .points([for (final (i, v) in values.indexed) DataPoint(v, _years[i])]),
  order: order,
  backgroundColor: .constant(.solid(color)),
  hoverBackgroundColor: .constant(.solid(color)),
  categoryPercentage: width,
  barPercentage: 1 - spacing,
);

ChartConfig _config(double width, double spacing) => ChartConfig(
  indexAxis: const YAxis(),
  datasets: [
    _trade(
      'Import',
      Sf.blue,
      1,
      const [16.219, 16.461, 17.427, 13.754, 15.743],
      width,
      spacing,
    ),
    _trade(
      'Export',
      Sf.purple,
      0,
      const [10.655, 11.498, 12.514, 11.012, 12.315],
      width,
      spacing,
    ),
  ],
  maintainAspectRatio: false,
  padding: sfPadding,
  title: sfTitle('Exports & Imports of US'),
  legend: sfLegend(const SfBarIcon(), reverse: true),
  tooltip: sfTooltip(
    header: true,
    text: (item) {
      final point = item.raw! as DataPoint;
      return '${sfNumber(point.y! as num)} : ${sfNumber(point.x! as num)}%';
    },
  ),
  plugins: [sfTooltipLook],
  scales: [
    // NumericAxis(minimum: 2005, maximum: 2011, interval: 1) as the index
    // axis: an axis line and tick marks, no grid lines.
    sfValueAxis(
      min: 2005,
      max: 2011,
      stepSize: 1,
      grid: false,
      line: true,
      ticks: true,
    ),
    sfValueAxis(
      direction: .x,
      min: 0,
      max: 20,
      stepSize: 2,
      callback: sfPercentTick,
      line: true,
      ticks: true,
      title: 'Goods and services (% of GDP)',
    ),
  ],
);

class const SfSpacingBar({super.key}) extends StatefulWidget {
  @override
  State<SfSpacingBar> createState() => _SfSpacingBarState();
}

class _SfSpacingBarState() extends State<SfSpacingBar> {
  double _width = 0.8;
  double _spacing = 0.2;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 320,
        child: ChartView(config: _config(_width, _spacing)),
      ),
      Wrap(
        spacing: 24,
        children: [
          SfStepper(
            id: 'sf-bar-spacing.width',
            label: 'Width',
            value: _width,
            onChanged: (value) => setState(() => _width = value),
          ),
          SfStepper(
            id: 'sf-bar-spacing.spacing',
            label: 'Spacing',
            value: _spacing,
            onChanged: (value) => setState(() => _spacing = value),
          ),
        ],
      ),
    ],
  );
}
// #enddocregion sf-spacing-bar

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: SfSpacingBar(),
        ),
      ),
    ),
  );
}
