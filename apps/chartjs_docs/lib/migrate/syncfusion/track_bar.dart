// Original code, not ported from Chart.js: a replica of the Syncfusion demo "Bar with track".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion sf-track-bar
import 'package:chartjs_docs/migrate/syncfusion/sf_bar_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _people = ['Mike', 'Chris', 'Helana', 'Tom', 'Federer', 'Hussain'];
const List<num> _hours = [7.5, 7, 6, 5, 7, 7];

final ChartConfig _config = ChartConfig(
  type: .bar,
  indexAxis: const YAxis(),
  labels: _people,
  datasets: const [
    BarDataset(
      data: _hours,
      backgroundColor: .constant(.solid(Sf.blue)),
      hoverBackgroundColor: .constant(.solid(Sf.blue)),
      categoryPercentage: 0.7,
      barPercentage: 1,
      borderRadius: 15,
      extra: {'borderSkipped': false},
    ),
  ],
  maintainAspectRatio: false,
  padding: sfPadding,
  title: sfTitle('Working hours of employees'),
  legend: const ChartLegend(display: false),
  tooltip: sfTooltip(
    text: (item) => '${item.label.join(' ')} : ${sfNumber(sfValue(item))}',
  ),
  plugins: [
    sfTooltipLook,
    // isTrackVisible: true, trackColor: Color.fromRGBO(198, 201, 207, 1)
    sfTrack(radius: 15),
    sfDataLabels([for (final h in _hours) sfNumber(h)], align: .top),
  ],
  scales: {
    'y': sfCategoryAxis(reverse: true),
    'x': sfValueAxis(
      min: 0,
      max: 8,
      stepSize: 1,
      grid: false,
      line: true,
      title: 'Hours',
    ),
  },
);

class const SfTrackBar({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 320, child: ChartView(config: _config));
}
// #enddocregion sf-track-bar

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: SfTrackBar(),
        ),
      ),
    ),
  );
}
