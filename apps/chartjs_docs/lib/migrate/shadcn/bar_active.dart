// Original code, not ported from Chart.js: a replica of the shadcn/ui demo "Bar Chart - Active".
// ignore_for_file: public_member_api_docs
// #docregion shadcn-bar-active
import 'package:chartjs_docs/migrate/shadcn/shadcn_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _browsers = ['Chrome', 'Safari', 'Firefox', 'Edge', 'Other'];
const _visitors = <num>[187, 200, 275, 173, 90];
const List<Color> _colors = [
  Shadcn.chart1,
  Shadcn.chart2,
  Shadcn.chart3,
  Shadcn.chart4,
  Shadcn.chart5,
];

// const ACTIVE_INDEX = 2
const _activeIndex = 2;

// The `fill` of each bar. The active bar has fillOpacity={0.8}.
final List<ChartPaint> _fills = [
  for (final (i, color) in _colors.indexed)
    .solid(i == _activeIndex ? color.withValues(alpha: 0.8) : color),
];

/// The `shape` of the active bar: a dashed stroke of its color, 2 px wide,
/// around its rounded rectangle (strokeDasharray={4} strokeDashoffset={4}).
/// Chart.js bars have no dash, so a plugin draws it after the bars.
final _activeOutline = Plugin<Object?>(
  id: 'activeOutline',
  afterDatasetsDraw: (chart, args, options) {
    final c = chart as Chart;
    final bar = c.getDatasetMeta(0).data[_activeIndex] as BarElement;
    final top = bar.y < bar.base ? bar.y : bar.base;
    c.ctx!
      ..save()
      ..strokeStyle = _colors[_activeIndex]
      ..lineWidth = 2
      ..setLineDash([4, 4])
      ..lineDashOffset = 4
      ..beginPath()
      ..roundRect(
        bar.x - bar.width / 2,
        top,
        bar.width,
        (bar.base - bar.y).abs(),
        8,
      )
      ..stroke()
      ..restore();
  },
);

ChartConfig _config(ShadcnTip tip) => ChartConfig(
  labels: _browsers,
  datasets: [
    BarDataset(
      label: 'Visitors',
      data: const .values(_visitors),
      backgroundColor: .indexed(_fills),
      hoverBackgroundColor: .indexed(_fills),
      borderRadius: 8,
      categoryPercentage: 0.8,
      barPercentage: 1,
      borderSkipped: BorderSkip.none,
    ),
  ],
  aspectRatio: 16 / 9,
  padding: const EdgeInsets.all(5),
  legend: shadcnNoLegend,
  pluginOptions: [
    shadcnTooltip(tip, const ShadcnTooltipContent(hideLabel: true)),
  ],
  interaction: shadcnInteraction(),
  animation: shadcnBarAnimation,
  plugins: [_activeOutline],
  scales: [
    // The tickFormatter gives the label of chartConfig: the whole name.
    shadcnCategoryAxis(tickMargin: 10, callback: null),
    shadcnValueAxis(_visitors),
  ],
);

class const ShadcnBarActive({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const ShadcnCard(
    title: 'Bar Chart - Active',
    chart: ShadcnChart(
      config: _config,
      semanticLabel:
          'Bar chart of the visitors of each browser, Firefox marked',
    ),
  );
}
// #enddocregion shadcn-bar-active

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ShadcnBarActive(),
        ),
      ),
    ),
  );
}
