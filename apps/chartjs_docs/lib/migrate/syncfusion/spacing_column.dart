// Original code, not ported from Chart.js: a replica of the Syncfusion demo "Column width and spacing".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion sf-spacing-column
import 'package:chartjs_docs/migrate/syncfusion/sf_bar_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _gold = Color.fromRGBO(251, 193, 55, 1);
const _silver = Color.fromRGBO(177, 183, 188, 1);
const _bronze = Color.fromRGBO(140, 92, 69, 1);

// `width` is the part of the category that the group of columns takes:
// categoryPercentage. `spacing` is the gap in the place of each column:
// barPercentage is 1 - spacing.
BarDataset _medals(
  String name,
  Color color,
  List<num> data,
  double width,
  double spacing,
) => BarDataset(
  label: name,
  data: .values(data),
  backgroundColor: .constant(.solid(color)),
  hoverBackgroundColor: .constant(.solid(color)),
  categoryPercentage: width,
  barPercentage: 1 - spacing,
);

// The tooltip, built once: a new one in each build would update the chart.
final TooltipOptions _tooltip = sfTooltip(
  header: true,
  text: (item) => '${item.label.join(' ')} : ${sfValue(item)}',
);

ChartConfig _config(double width, double spacing) => ChartConfig(
  labels: const ['Norway', 'USA', 'Germany', 'Canada', 'Netherlands'],
  datasets: [
    _medals('Gold', _gold, const [16, 8, 12, 4, 8], width, spacing),
    _medals('Silver', _silver, const [8, 10, 10, 8, 5], width, spacing),
    _medals('Bronze', _bronze, const [13, 7, 5, 14, 4], width, spacing),
  ],
  maintainAspectRatio: false,
  padding: sfPadding,
  title: sfTitle('Winter olympic medals count - 2022'),
  legend: sfLegend(const SfColumnIcon()),
  pluginOptions: [_tooltip],
  plugins: [sfTooltipLook],
  scales: [sfCategoryAxis(), sfValueAxis(min: 0, max: 20, stepSize: 4)],
);

class const SfSpacingColumn({super.key}) extends StatefulWidget {
  @override
  State<SfSpacingColumn> createState() => _SfSpacingColumnState();
}

class _SfSpacingColumnState() extends State<SfSpacingColumn> {
  double _width = 0.8;
  double _spacing = 0.2;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 320,
        child: ChartView(config: _config(_width, _spacing)),
      ),
      // The property panel: Width and Spacing.
      Wrap(
        spacing: 24,
        children: [
          SfStepper(
            id: 'sf-column-spacing.width',
            label: 'Width',
            value: _width,
            onChanged: (value) => setState(() => _width = value),
          ),
          SfStepper(
            id: 'sf-column-spacing.spacing',
            label: 'Spacing',
            value: _spacing,
            onChanged: (value) => setState(() => _spacing = value),
          ),
        ],
      ),
    ],
  );
}
// #enddocregion sf-spacing-column

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: SfSpacingColumn(),
        ),
      ),
    ),
  );
}
