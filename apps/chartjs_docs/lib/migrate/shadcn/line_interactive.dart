// Original code, not ported from Chart.js: a replica of the shadcn/ui demo "Line Chart - Interactive".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion shadcn-line-interactive
import 'package:chartjs_docs/migrate/shadcn/shadcn_data.dart';
import 'package:chartjs_docs/migrate/shadcn/shadcn_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

final List<String> _dates = [for (final (date, _, _) in visitorsByDay) date];
final _desktop = <num>[for (final (_, desktop, _) in visitorsByDay) desktop];
final _mobile = <num>[for (final (_, _, mobile) in visitorsByDay) mobile];

// The series of the buttons: the label of chartConfig, the data, the color
// and the total of `total`.
final List<(String, List<num>, Color, num)> _series = [
  ('Desktop', _desktop, Shadcn.chart1, _desktop.fold<num>(0, (a, b) => a + b)),
  ('Mobile', _mobile, Shadcn.chart2, _mobile.fold<num>(0, (a, b) => a + b)),
];

ChartConfig _config(ShadcnTip tip, int active) {
  final (_, data, color, _) = _series[active];
  return ChartConfig(
    labels: _dates,
    datasets: [
      // <Line dataKey={activeChart} type="monotone" stroke={`var(--color-${activeChart})`} ...>
      LineDataset(
        label: 'Page Views',
        data: data,
        cubicInterpolationMode: const MonotoneXCurve(),
        borderColor: .constant(.solid(color)),
        borderWidth: 2,
        // Recharts draws the line and the dots past the edges of the plot.
        clip: ChartClip.none,
        pointRadius: 0,
        pointHoverRadius: 4,
        pointBackgroundColor: .constant(.solid(color)),
        pointHoverBackgroundColor: .constant(.solid(color)),
        extra: const {'pointHoverBorderWidth': 0, 'capBezierPoints': false},
      ),
    ],
    // className="aspect-auto h-[250px] w-full"
    maintainAspectRatio: false,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    legend: shadcnNoLegend,
    // nameKey="views" and the labelFormatter of the date with the year.
    tooltip: shadcnTooltip(
      tip,
      ShadcnTooltipContent(
        name: 'Page Views',
        width: 150,
        labelFormatter: (date) => shortDate(date, year: true),
      ),
    ),
    interaction: shadcnInteraction(),
    animation: shadcnLineAnimation,
    // The cursor of the tooltip: a line at the hovered day.
    plugins: [shadcnCursor],
    scales: {
      // minTickGap={32}, and the tickFormatter of the month and the day.
      'x': shadcnCategoryAxis(
        callback: (scale, value, index, ticks) => [
          shortDate(_dates[value.toInt()]),
        ],
        autoSkipPadding: 32,
      ),
      'y': shadcnValueAxis(data),
    },
  );
}

class const ShadcnLineInteractive({super.key}) extends StatefulWidget {
  @override
  State<ShadcnLineInteractive> createState() => _ShadcnLineInteractiveState();
}

class _ShadcnLineInteractiveState() extends State<ShadcnLineInteractive> {
  // activeChart: the index of the series that the chart shows.
  int _active = 0;

  @override
  Widget build(BuildContext context) => ShadcnInteractiveCard(
    title: 'Line Chart - Interactive',
    series: [
      for (final (label, _, _, total) in _series) (label, total.toInt()),
    ],
    active: _active,
    onSelect: (i) => setState(() => _active = i),
    buttonKey: 'shadcn-line-interactive',
    chart: ShadcnChart(
      config: (tip) => _config(tip, _active),
      height: 250,
      semanticLabel: 'Line chart of the page views of each day',
    ),
  );
}
// #enddocregion shadcn-line-interactive

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ShadcnLineInteractive(),
        ),
      ),
    ),
  );
}
