// Original code, not ported from Chart.js: a replica of the ApexCharts.js demo "Gradient Line Chart".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion apexjs-line-forecast
import 'package:chartjs_docs/migrate/apexcharts/apex_kit.dart';
import 'package:chartjs_docs/migrate/apexcharts_js/apexjs_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const List<num> _sales = [
  4, 3, 10, 9, 29, 19, 22, 9, 12, 7, 19, 5, 13, 9, 17, 2, 7, 5, //
];

// xaxis.categories: the 11th of each month from January 2000.
final List<DataPoint> _points = [
  for (final (i, value) in _sales.indexed)
    DataPoint.time(DateTime(2000, 1 + i, 11), value),
];

// fill: {type: 'gradient', gradient: {type: 'horizontal',
// gradientToColors: ['#FDD835']}}: across the plot, from yellow on the
// left to the series color on the right.
final ChartValue<ChartPaint> _gradient = .resolver((context) {
  final area = context.chart.chartArea;
  if (area == null) return const ChartPaint.solid(Apex.blue);
  return ChartGradient.linear(
    Offset(area.left, 0),
    Offset(area.right, 0),
    const [Color(0xFFFDD835), Apex.blue],
  );
});

ChartConfig _config(ApexZoom zoom) => ChartConfig(
  datasets: [
    LineDataset(
      label: 'Sales',
      data: .points(_points),
      borderColor: _gradient,
      backgroundColor: _gradient,
      // stroke: {width: 5, curve: 'smooth'}
      borderWidth: 5,
      tension: 0.4,
      pointRadius: const .constant(0),
      pointHoverRadius: const .constant(0),
      // forecastDataPoints: {count: 7}: the last 7 points have a dashed
      // line (dashArray: 4).
      segment: LineSegmentStyle(
        borderDash: (s) =>
            s.p1DataIndex >= _sales.length - 7 ? const [4, 4] : null,
      ),
    ),
  ],
  maintainAspectRatio: false,
  padding: const EdgeInsets.fromLTRB(4, 0, 10, 0),
  // title.style: {fontSize: '16px', color: '#666'}
  interaction: const ChartInteraction(
    mode: IndexInteractionMode(),
    intersect: false,
  ),
  animation: apexAnimation,
  plugins: apexZoomPlugins([apexHover, apexTooltipLook]),
  pluginOptions: [
    apexJsTitle('Forecast', size: 16, color: const Color(0xFF666666)),
    const LegendOptions(display: false),
    apexTooltip(),
    zoom.options,
  ],
  scales: [
    // xaxis: {type: 'datetime', tickAmount: 10}, labels 'dd MMM'. Chart.js
    // puts a tick at each point and skips the ticks that do not fit.
    const TimeAxis(
      .x,
      unit: .day,
      tooltipFormat: 'dd MMM yyyy',
      displayFormats: TimeDisplayFormats(day: 'dd MMM'),
      grid: AxisGrid(
        color: .constant(.solid(apexJsGrid)),
        drawOnChartArea: false,
        tickLength: 6,
      ),
      ticks: AxisTicks(
        source: .data,
        color: .constant(.solid(Apex.text)),
        font: .constant(TextStyle(fontSize: 12)),
        padding: 4,
        maxRotation: 0,
      ),
      border: AxisBorder(color: .solid(apexJsGrid)),
    ),
    apexJsValueAxis(min: 0, max: 30, stepSize: 5),
  ],
);

class const ApexJsLineForecast({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const ApexZoomChart(
    config: _config,
    height: 350,
    semanticLabel: 'Line chart of the sales with a forecast',
  );
}
// #enddocregion apexjs-line-forecast

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ApexJsLineForecast(),
        ),
      ),
    ),
  );
}
