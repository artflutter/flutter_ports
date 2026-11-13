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
Map<String, Object?> _dropLines() => {
  'id': 'dropLines',
  'beforeDatasetsDraw': (Chart chart, Object? args, Object? options) {
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
  },
};

final List<Map<String, Object?>> _plugins = [
  _dropLines(),
  annotations([
    HLine(1.8, _average, 3, const [20, 10]),
  ]),
  touchIndicator(color: Fl.yellow, when: (i) => i != 0 && i != 6),
  areaBorder(Fl.white54),
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
    chart.update('none');
  }

  ChartPaint _bottomColor(JsObjectFace c) =>
      .solid(tickOf(c) == _touched ? Fl.yellow : _indicatorColor);

  ChartConfig _config() => fills(
    ChartConfig(
      type: .line,
      labels: _days,
      datasets: [
        LineDataset(
          data: _values,
          borderColor: const .constant(.solid(Fl.red)),
          borderWidth: 4,
          fill: .toOrigin,
          pointBackgroundColor: const .constant(.solid(Colors.white)),
          pointBorderColor: .constant(.solid(_dotStroke)),
          pointBorderWidth: 3,
          pointHoverBackgroundColor: const .constant(.solid(Colors.white)),
          pointHoverBorderColor: const .constant(.solid(Fl.yellow)),
          extra: {
            'stepped': SteppedLine.middle,
            'backgroundColor': verticalGradient(
              [Fl.red.withValues(alpha: 0.5), Fl.red.withValues(alpha: 0)],
              const [0.5, 1],
            ),
            'pointStyle': const [
              CirclePointStyle(),
              RectPointStyle(),
              CirclePointStyle(),
              RectPointStyle(),
              CirclePointStyle(),
              RectPointStyle(),
              CirclePointStyle(),
            ],
            'pointRadius': const [0, 8.5, 6, 8.5, 6, 8.5, 0],
            'pointHoverRadius': const [0, 11.3, 8, 11.3, 8, 11.3, 0],
            'pointHoverBorderWidth': 5,
          },
        ),
      ],
      onHover: _hover,
      interaction: const ChartInteraction(mode: flX, intersect: false),
      tooltip: ChartTooltip(
        backgroundColor: const ChartPaint.solid(Fl.green),
        titleColor: const ChartPaint.solid(Colors.black),
        bodyColor: const ChartPaint.solid(Colors.black),
        displayColors: false,
        titleFont: const TextStyle(fontWeight: FontWeight.bold),
        bodyFont: const TextStyle(fontWeight: FontWeight.w900),
        filter: (item, index, items, data) =>
            item.dataIndex != 0 && item.dataIndex != 6,
        callbacks: TooltipCallbacks(
          title: (tooltip, items) => items.isEmpty ? null : items.first.label,
          label: (tooltip, item) => ['${item.formattedValue} k calories'],
        ),
      ),
      plugins: _plugins,
      scales: {
        'x': CategoryAxis(
          grid: AxisGrid(
            drawTicks: false,
            extra: {
              'color': (JsObjectFace c) => ChartPaint.solid(
                tickOf(c) == 0 ? Colors.transparent : Fl.white10,
              ),
              'lineWidth': 0.5,
            },
          ),
          extra: Fl.noBorder,
          ticks: AxisTicks(
            maxRotation: 0,
            font: const TextStyle(fontWeight: FontWeight.bold),
            align: _fitBottom ? TickAlign.inner : TickAlign.center,
            extra: {'color': _bottomColor},
          ),
        ),
        'y': LinearAxis(
          min: 0,
          grid: AxisGrid(
            drawTicks: false,
            extra: {
              'color': (JsObjectFace c) => ChartPaint.solid(
                tickOf(c) == 0 ? Colors.transparent : Fl.white10,
              ),
              'lineWidth': 0.5,
            },
          ),
          extra: Fl.noBorder,
          ticks: AxisTicks(
            stepSize: 1,
            color: ChartPaint.solid(Fl.white54.withValues(alpha: 0.5)),
            font: const TextStyle(fontSize: 10),
            callback: (scale, value, index, ticks) => [
              if (value == 0) '' else '${value.toInt()}k calories',
            ],
            align: _fitLeft ? TickAlign.inner : TickAlign.center,
          ),
        ),
      },
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
          child: ChartView(config: _config(), updateMode: 'none'),
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
