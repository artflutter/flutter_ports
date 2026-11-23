// Original code, not ported from Chart.js: a replica of the Syncfusion demo "Modified axis base".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion sf-axis-base-column
import 'package:chartjs_docs/migrate/syncfusion/sf_bar_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _green = Color.fromRGBO(107, 189, 98, 1);
const _red = Color.fromRGBO(199, 86, 86, 1);

const _countries = [
  'Iceland',
  'Algeria',
  'Singapore',
  'Malaysia',
  'Moldova',
  'American Samoa',
  'Latvia',
];
const List<num> _rates = [1.13, 1.7, 1.82, 1.37, -1.05, -1.3, -1.1];
// pointColorMapper: green for growth, red for decline.
final List<Color> _colors = [
  for (final r in _rates)
    if (r > 0) _green else _red,
];

// labelIntersectAction: wrap. A label that does not fit its category takes
// one line for each word.
List<String>? _wrap(Scale scale, double value, int index, List<Tick> ticks) {
  final label = _countries[value.round()];
  final room = scale.width / ticks.length;
  return [if (label.length * 7 > room) ...label.split(' ') else label];
}

// The tooltip, built once: a new one in each build would update the chart.
final TooltipOptions _tooltip = sfTooltip(
  text: (item) => '${item.label.join(' ')} : ${sfNumber(sfValue(item))}',
);

ChartConfig _config(double crossAt) => ChartConfig(
  labels: _countries,
  datasets: [
    BarDataset(
      data: const .values(_rates),
      backgroundColor: .indexed([for (final c in _colors) .solid(c)]),
      hoverBackgroundColor: .indexed([for (final c in _colors) .solid(c)]),
      categoryPercentage: 0.7,
      barPercentage: 1,
      // crossesAt of the x axis: the value where the columns start.
      extra: {'base': crossAt},
    ),
  ],
  maintainAspectRatio: false,
  padding: sfPadding,
  title: sfTitle('Population growth rate of countries'),
  pluginOptions: [const LegendOptions(display: false), _tooltip],
  plugins: [
    sfTooltipLook,
    sfDataLabels(
      [for (final r in _rates) sfNumber(r)],
      align: .middle,
      fills: _colors,
    ),
  ],
  scales: [
    // placeLabelsNearAxisLine: false: the labels stay at the bottom.
    sfCategoryAxis(callback: _wrap),
    sfValueAxis(min: -2, max: 2, stepSize: 1),
  ],
);

class const SfAxisBaseColumn({super.key}) extends StatefulWidget {
  @override
  State<SfAxisBaseColumn> createState() => _SfAxisBaseColumnState();
}

class _SfAxisBaseColumnState() extends State<SfAxisBaseColumn> {
  double _crossAt = -2;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(height: 320, child: ChartView(config: _config(_crossAt))),
      // The property panel: "Axis base value".
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        children: [
          const Text('Axis base value'),
          SegmentedButton<double>(
            key: const ValueKey('sf-column-axis-base.value'),
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: -2, label: Text('-2 (modified)')),
              ButtonSegment(value: 0, label: Text('0 (default)')),
            ],
            selected: {_crossAt},
            onSelectionChanged: (value) =>
                setState(() => _crossAt = value.single),
          ),
        ],
      ),
    ],
  );
}
// #enddocregion sf-axis-base-column

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: SfAxisBaseColumn(),
        ),
      ),
    ),
  );
}
