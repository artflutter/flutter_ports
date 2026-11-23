// Original code, not ported from Chart.js: a replica of the shadcn/ui demo "Bar Chart - Interactive".
// ignore_for_file: public_member_api_docs
// #docregion shadcn-bar-interactive
import 'package:chartjs_docs/migrate/shadcn/shadcn_data.dart';
import 'package:chartjs_docs/migrate/shadcn/shadcn_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

final List<String> _dates = [for (final (date, _, _) in visitorsByDay) date];
final _desktop = <num>[for (final (_, desktop, _) in visitorsByDay) desktop];
final _mobile = <num>[for (final (_, _, mobile) in visitorsByDay) mobile];

// The series of the buttons: the label of chartConfig, the data, the color
// and the total of `total`. The bar demo gives desktop --chart-2.
final List<(String, List<num>, Color, num)> _series = [
  ('Desktop', _desktop, Shadcn.chart2, _desktop.fold<num>(0, (a, b) => a + b)),
  ('Mobile', _mobile, Shadcn.chart1, _mobile.fold<num>(0, (a, b) => a + b)),
];

ChartConfig _config(ShadcnTip tip, int active) {
  final (_, data, color, _) = _series[active];
  return ChartConfig(
    labels: _dates,
    datasets: [
      // <Bar dataKey={activeChart} fill={`var(--color-${activeChart})`} />
      BarDataset(
        label: 'Page Views',
        data: .values(data),
        backgroundColor: .constant(.solid(color)),
        hoverBackgroundColor: .constant(.solid(color)),
        categoryPercentage: 0.8,
        barPercentage: 1,
      ),
    ],
    maintainAspectRatio: false,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    legend: shadcnNoLegend,
    pluginOptions: [
      shadcnTooltip(
        tip,
        ShadcnTooltipContent(
          name: 'Page Views',
          width: 150,
          labelFormatter: (date) => shortDate(date, year: true),
        ),
      ),
    ],
    interaction: shadcnInteraction(),
    animation: shadcnBarAnimation,
    // The cursor of the tooltip: a muted band under the hovered day.
    plugins: [shadcnCursor],
    scales: [
      shadcnCategoryAxis(
        callback: (scale, value, index, ticks) => [
          shortDate(_dates[value.toInt()]),
        ],
        autoSkipPadding: 32,
      ),
      shadcnValueAxis(data),
    ],
  );
}

class const ShadcnBarInteractive({super.key}) extends StatefulWidget {
  @override
  State<ShadcnBarInteractive> createState() => _ShadcnBarInteractiveState();
}

class _ShadcnBarInteractiveState() extends State<ShadcnBarInteractive> {
  int _active = 0;

  @override
  Widget build(BuildContext context) => ShadcnInteractiveCard(
    title: 'Bar Chart - Interactive',
    series: [
      for (final (label, _, _, total) in _series) (label, total.toInt()),
    ],
    active: _active,
    onSelect: (i) => setState(() => _active = i),
    buttonKey: 'shadcn-bar-interactive',
    chart: ShadcnChart(
      config: (tip) => _config(tip, _active),
      height: 250,
      semanticLabel: 'Bar chart of the page views of each day',
    ),
  );
}
// #enddocregion shadcn-bar-interactive

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ShadcnBarInteractive(),
        ),
      ),
    ),
  );
}
