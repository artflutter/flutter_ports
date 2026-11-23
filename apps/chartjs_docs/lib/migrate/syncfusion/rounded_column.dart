// Original code, not ported from Chart.js: a replica of the Syncfusion demo "Column with rounded corners".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion sf-rounded-column
import 'package:chartjs_docs/migrate/syncfusion/sf_bar_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _cities = ['New York', 'Tokyo', 'Chicago', 'Atlanta', 'Boston'];
const List<num> _areas = [8683, 6993, 5498, 5083, 4497];

final ChartConfig _config = ChartConfig(
  labels: _cities,
  datasets: const [
    BarDataset(
      data: .values(_areas),
      backgroundColor: .constant(.solid(Sf.blue)),
      hoverBackgroundColor: .constant(.solid(Sf.blue)),
      // width: 0.9, borderRadius: BorderRadius.circular(10)
      categoryPercentage: 0.9,
      barPercentage: 1,
      borderRadius: 10,
      // All four corners, also the ones on the base.
      borderSkipped: BorderSkip.none,
    ),
  ],
  maintainAspectRatio: false,
  // No axis is visible: the margin of 10 px on each side.
  padding: const EdgeInsets.all(10),
  pluginOptions: [
    sfTitle('Land area of various cities (sq.km)'),
    const LegendOptions(display: false),
    sfTooltip(
      text: (item) => '${item.label.join(' ')} : ${sfValue(item)} sq.km',
    ),
  ],
  plugins: [
    sfTooltipLook,
    // labelAlignment: ChartDataLabelAlignment.top: inside the end.
    sfDataLabels([for (final a in _areas) '$a'], align: .top),
    // The x axis labels with labelPosition: inside, in white.
    sfDataLabels(
      _cities,
      id: 'cityLabels',
      align: .bottom,
      color: Colors.white,
    ),
  ],
  scales: const [
    // The labels plugin above draws the labels.
    CategoryAxis(.x, display: ScaleDisplay.off),
    // isVisible: false
    LinearAxis(.y, display: ScaleDisplay.off, min: 0, max: 9000),
  ],
);

class const SfRoundedColumn({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 320, child: ChartView(config: _config));
}
// #enddocregion sf-rounded-column

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: SfRoundedColumn(),
        ),
      ),
    ),
  );
}
