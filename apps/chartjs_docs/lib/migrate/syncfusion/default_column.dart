// Original code, not ported from Chart.js: a replica of the Syncfusion demo "Default Column chart".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion sf-default-column
import 'package:chartjs_docs/migrate/syncfusion/sf_bar_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _countries = [
  'China',
  'Brazil',
  'Bolivia',
  'Mexico',
  'Egypt',
  'Mongolia',
];
const List<num> _growth = [0.541, 0.818, 1.51, 1.302, 2.017, 1.683];

final ChartConfig _config = ChartConfig(
  labels: _countries,
  datasets: const [
    BarDataset(
      data: .values(_growth),
      backgroundColor: .constant(.solid(Sf.blue)),
      hoverBackgroundColor: .constant(.solid(Sf.blue)),
      // The default `width: 0.7` of a ColumnSeries.
      categoryPercentage: 0.7,
      barPercentage: 1,
    ),
  ],
  maintainAspectRatio: false,
  padding: sfPadding,
  title: sfTitle('Population growth of various countries'),
  legend: const ChartLegend(display: false),
  // TooltipBehavior(header: '', canShowMarker: false)
  tooltip: sfTooltip(
    text: (item) => '${item.label.join(' ')} : ${sfNumber(sfValue(item))}%',
  ),
  plugins: [
    sfTooltipLook,
    // DataLabelSettings(isVisible: true, textStyle: TextStyle(fontSize: 10))
    sfDataLabels([for (final v in _growth) '${sfNumber(v)}%'], fontSize: 10),
  ],
  scales: [
    sfCategoryAxis(),
    // labelFormat: '{value}%', no axis line, no tick marks.
    sfValueAxis(min: 0, max: 2.5, stepSize: 0.5, callback: sfPercentTick),
  ],
);

class const SfDefaultColumn({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 320, child: ChartView(config: _config));
}
// #enddocregion sf-default-column

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: SfDefaultColumn(),
        ),
      ),
    ),
  );
}
