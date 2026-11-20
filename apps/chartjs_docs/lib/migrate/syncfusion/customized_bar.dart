// Original code, not ported from Chart.js: a replica of the Syncfusion demo "Customized bar chart".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion sf-customized-bar
import 'package:chartjs_docs/migrate/syncfusion/sf_bar_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _apps = [
  'Facebook',
  'FB Messenger',
  'WhatsApp',
  'Instagram',
  'Skype',
  'Subway Surfers',
];
const List<num> _downloads = [4.119, 3.408, 2.979, 1.843, 1.039, 1.025];
const _dash = Color.fromRGBO(247, 160, 92, 1);

// The custom BarSegment paints an image of orange dashes over each bar.
// The plugin draws the dashes as lines, clipped to each bar.
final _dashes = Plugin<Object?>(
  id: 'dashes',
  afterDatasetDraw: (chart, args, options) {
    final ctx = chart.ctx!;
    for (final element in args.meta.data) {
      final bar = element as BarElement;
      final top = bar.y - bar.height / 2;
      final left = bar.base;
      final width = bar.x - bar.base;
      ctx
        ..save()
        ..beginPath()
        ..rect(left, top, width, bar.height)
        ..clip()
        ..strokeStyle = _dash
        ..lineWidth = 1.5
        ..lineCap = StrokeCap.round
        ..setLineDash(const [5, 4])
        ..beginPath();
      // Lines up to the right at about 40 degrees, 13 px apart.
      final run = bar.height * 1.2;
      for (var x = left - run; x < left + width; x += 13) {
        ctx
          ..moveTo(x, top + bar.height)
          ..lineTo(x + run, top);
      }
      ctx
        ..stroke()
        ..restore();
    }
  },
);

final ChartConfig _config = ChartConfig(
  indexAxis: const YAxis(),
  labels: _apps,
  datasets: const [
    BarDataset(
      data: _downloads,
      backgroundColor: .constant(.solid(Sf.blue)),
      hoverBackgroundColor: .constant(.solid(Sf.blue)),
      categoryPercentage: 0.7,
      barPercentage: 1,
    ),
  ],
  maintainAspectRatio: false,
  padding: sfPadding,
  title: sfTitle('Popular Android apps in the Google play store'),
  legend: const ChartLegend(display: false),
  tooltip: sfTooltip(
    text: (item) => '${item.label.join(' ')} : ${sfNumber(sfValue(item))}',
  ),
  plugins: [
    sfTooltipLook,
    sfPlotBorder,
    _dashes,
    sfDataLabels([for (final d in _downloads) sfNumber(d)]),
  ],
  scales: {
    'y': sfCategoryAxis(reverse: true),
    'x': sfValueAxis(
      min: 0,
      max: 4.5,
      stepSize: 0.5,
      grid: false,
      line: true,
      title: 'Downloads in Billion',
    ),
  },
);

class const SfCustomizedBar({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 320, child: ChartView(config: _config));
}
// #enddocregion sf-customized-bar

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: SfCustomizedBar(),
        ),
      ),
    ),
  );
}
