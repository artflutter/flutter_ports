// Original code, not ported from Chart.js: fl_chart line sample 3.
// ignore_for_file: public_member_api_docs
// #docregion fl_chart-03
import 'package:chartjs_docs/migrate/fl_chart/fl_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _days = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
const _values = [1.3, 1.0, 1.8, 1.5, 2.2, 1.8, 3.0];
final Color _indicatorColor = Fl.yellow.withValues(alpha: 0.2);
final Color _dotStroke = Fl.yellow.withValues(alpha: 0.5);
final Color _average = Fl.green.withValues(alpha: 0.8);

/// The drop lines of the spots, which fl_chart calls the spots line.
final _dropLines = Plugin<Object?>(
  id: 'dropLines',
  beforeDatasetsDraw: (chart, args, options) {
    final area = chart.chartArea!;
    final elements = chart.getDatasetMeta(0).data;
    final ctx = chart.ctx!
      ..save()
      ..strokeStyle = _indicatorColor
      ..lineWidth = 2;
    for (var i = 1; i < 6; i++) {
      ctx
        ..beginPath()
        ..moveTo(elements[i].x, elements[i].y)
        ..lineTo(elements[i].x, area.bottom)
        ..stroke();
    }
    ctx.restore();
    return true;
  },
);

final List<Plugin<Object?>> _plugins = [
  _dropLines,
  annotations([
    HLine(1.8, _average, 3, const [20, 10]),
  ]),
  touchIndicator(color: Fl.yellow, when: (i) => i != 0 && i != 6),
  areaBorder(Fl.white54),
];

/// Only the points between the first and the last day.
bool _inner(
  TooltipItem item,
  int index,
  List<TooltipItem> items,
  Object data,
) => item.dataIndex != 0 && item.dataIndex != 6;

/// The day of the first item, as the title of the tooltip.
List<String>? _tooltipTitle(TooltipModel tooltip, List<TooltipItem> items) =>
    items.isEmpty ? null : items.first.label;

/// The value in k calories, as the label of the tooltip.
List<String> _tooltipLabel(TooltipModel tooltip, TooltipItem item) => [
  '${item.formattedValue} k calories',
];

class const Sample3({super.key}) extends StatefulWidget {
  @override
  State<Sample3> createState() => _Sample3State();
}

class _Sample3State() extends State<Sample3> {
  int _touched = -1;
  bool _fitLeft = false;
  bool _fitBottom = true;

  void _hover(ChartEvent event, List<ActiveElement> hits, Chart chart) {
    final index = hits.isEmpty ? -1 : hits.first.index;
    final next = index == 0 || index == 6 ? -1 : index;
    if (next == _touched) return;
    _touched = next;
    chart.update(UpdateMode.none);
  }

  ChartPaint _bottomColor(Object? c) =>
      .solid(tickOf(c) == _touched ? Fl.yellow : _indicatorColor);

  ChartConfig _config() => fills(
    ChartConfig(
      labels: _days,
      datasets: [
        LineDataset(
          data: const .values(_values),
          borderColor: const .constant(.solid(Fl.red)),
          borderWidth: 4,
          fill: .toOrigin,
          pointRadius: const .indexed([0, 8.5, 6, 8.5, 6, 8.5, 0]),
          pointHoverRadius: const .indexed([0, 11.3, 8, 11.3, 8, 11.3, 0]),
          pointStyle: const .indexed([
            CirclePointStyle(),
            RectPointStyle(),
            CirclePointStyle(),
            RectPointStyle(),
            CirclePointStyle(),
            RectPointStyle(),
            CirclePointStyle(),
          ]),
          pointBackgroundColor: const .constant(.solid(Colors.white)),
          pointBorderColor: .constant(.solid(_dotStroke)),
          pointBorderWidth: 3,
          pointHoverBackgroundColor: const .constant(.solid(Colors.white)),
          pointHoverBorderColor: const .constant(.solid(Fl.yellow)),
          pointHoverBorderWidth: const .constant(5),
          stepped: SteppedLine.middle,
          extra: {
            'backgroundColor': verticalGradient(
              [Fl.red.withValues(alpha: 0.5), Fl.red.withValues(alpha: 0)],
              const [0.5, 1],
            ),
          },
        ),
      ],
      onHover: _hover,
      interaction: const ChartInteraction(mode: flX, intersect: false),
      pluginOptions: const [
        TooltipOptions(
          backgroundColor: ChartPaint.solid(Fl.green),
          titleColor: ChartPaint.solid(Colors.black),
          bodyColor: ChartPaint.solid(Colors.black),
          displayColors: false,
          titleFont: TextStyle(fontWeight: FontWeight.bold),
          bodyFont: TextStyle(fontWeight: FontWeight.w900),
          filter: _inner,
          callbacks: TooltipCallbacks(
            title: _tooltipTitle,
            label: _tooltipLabel,
          ),
        ),
      ],
      plugins: _plugins,
      scales: [
        CategoryAxis(
          .x,
          grid: AxisGrid(
            drawTicks: false,
            lineWidth: const .constant(0.5),
            color: .resolver(
              (c) => ChartPaint.solid(
                tickOf(c) == 0 ? Colors.transparent : Fl.white10,
              ),
            ),
          ),
          border: Fl.noBorder,
          ticks: AxisTicks(
            maxRotation: 0,
            font: const .constant(TextStyle(fontWeight: FontWeight.bold)),
            align: _fitBottom ? TickAlign.inner : TickAlign.center,
            color: .resolver(_bottomColor),
          ),
        ),
        LinearAxis(
          .y,
          min: 0,
          grid: AxisGrid(
            drawTicks: false,
            lineWidth: const .constant(0.5),
            color: .resolver(
              (c) => ChartPaint.solid(
                tickOf(c) == 0 ? Colors.transparent : Fl.white10,
              ),
            ),
          ),
          border: Fl.noBorder,
          ticks: AxisTicks(
            stepSize: 1,
            color: .constant(
              ChartPaint.solid(Fl.white54.withValues(alpha: 0.5)),
            ),
            font: const .constant(TextStyle(fontSize: 10)),
            callback: (scale, value, index, ticks) => [
              if (value == 0) '' else '${value.toInt()}k calories',
            ],
            align: _fitLeft ? TickAlign.inner : TickAlign.center,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const SizedBox(height: 10),
      const Text.rich(
        TextSpan(
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          children: [
            TextSpan(
              text: 'Average Line',
              style: TextStyle(color: Fl.green),
            ),
            TextSpan(
              text: ' and ',
              style: TextStyle(color: Colors.white),
            ),
            TextSpan(
              text: 'Indicators',
              style: TextStyle(color: Fl.yellow),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      AspectRatio(
        aspectRatio: 2,
        child: Padding(
          padding: const EdgeInsets.only(right: 20, left: 12),
          child: ChartView(config: _config(), updateMode: UpdateMode.none),
        ),
      ),
      const Text(
        'Fit Inside Title Option',
        style: TextStyle(color: Colors.white),
      ),
      const Divider(),
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('Left Title', style: TextStyle(color: Colors.white)),
          Switch(
            value: _fitLeft,
            onChanged: (v) => setState(() => _fitLeft = v),
          ),
          const Text('Bottom Title', style: TextStyle(color: Colors.white)),
          Switch(
            value: _fitBottom,
            onChanged: (v) => setState(() => _fitBottom = v),
          ),
        ],
      ),
    ],
  );
}
// #enddocregion fl_chart-03

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Fl.item,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ChartTheme(data: ChartThemeData.dark(), child: Sample3()),
        ),
      ),
    ),
  );
}
