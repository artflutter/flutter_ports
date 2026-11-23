// Original code, not ported from Chart.js: a replica of the Syncfusion demo "Column with track".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion sf-track-column
import 'package:chartjs_docs/migrate/syncfusion/sf_bar_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _subjects = [
  'Subject 1',
  'Subject 2',
  'Subject 3',
  'Subject 4',
  'Subject 5',
];
const List<num> _marks = [71, 84, 48, 80, 76];

final ChartConfig _config = ChartConfig(
  labels: _subjects,
  datasets: const [
    BarDataset(
      label: 'Marks',
      data: _marks,
      backgroundColor: .constant(.solid(Sf.blue)),
      hoverBackgroundColor: .constant(.solid(Sf.blue)),
      categoryPercentage: 0.7,
      barPercentage: 1,
      // borderRadius: BorderRadius.circular(15), on all four corners.
      borderRadius: 15,
      borderSkipped: BorderSkip.none,
    ),
  ],
  maintainAspectRatio: false,
  padding: sfPadding,
  title: sfTitle('Marks of a student'),
  legend: sfLegend(const SfColumnIcon()),
  // format: 'point.y marks in point.x'
  tooltip: sfTooltip(
    text: (item) => '${sfValue(item)} marks in ${item.label.join(' ')}',
  ),
  plugins: [
    sfTooltipLook,
    // isTrackVisible: true, trackColor: Color.fromRGBO(198, 201, 207, 1)
    sfTrack(radius: 15),
    sfDataLabels([for (final m in _marks) '$m'], align: .top, fontSize: 10),
  ],
  scales: [
    sfCategoryAxis(),
    sfValueAxis(min: 0, max: 100, stepSize: 20, grid: false),
  ],
);

class const SfTrackColumn({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 320, child: ChartView(config: _config));
}
// #enddocregion sf-track-column

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: SfTrackColumn(),
        ),
      ),
    ),
  );
}
