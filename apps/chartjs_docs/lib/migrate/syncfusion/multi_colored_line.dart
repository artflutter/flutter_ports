// Original code, not ported from Chart.js: a replica of the Syncfusion demo "Multi-colored line".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion sf-multi-colored-line
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _text = Color(0xFF49454F);
const _axisLine = Color(0xFFCAC4D0);
const _grid = Color(0xFFE6E0E9);
const _tooltip = Color(0xFF322F35);

const _orange = Color.fromRGBO(248, 184, 131, 1);
const _pink = Color.fromRGBO(229, 101, 144, 1);
const _blue = Color.fromRGBO(53, 124, 210, 1);
const _teal = Color.fromRGBO(0, 189, 174, 1);

// The rainfall of each year from 1925, and the color of each point: the
// pointColorMapper of the original.
const List<(int, Color)> _rainfall = [
  (415, _orange), (408, _orange), (415, _orange), (350, _orange), //
  (375, _orange), (500, _orange), (390, _pink), (450, _pink),
  (440, _pink), (350, _pink), (400, _pink), (365, _blue),
  (490, _blue), (400, _blue), (520, _blue), (510, _blue),
  (395, _teal), (380, _teal), (404, _teal), (400, _teal),
  (500, _teal),
];

// A segment from point i - 1 to point i takes the color of point i.
Object? _segmentColor(JsObjectFace segment) =>
    _rainfall[(segment['p1DataIndex']! as num).toInt()].$2;

// The marker in the tooltip takes the color of the point.
TooltipLabelStyle _tooltipMarker(TooltipModel tooltip, ChartTooltipItem item) =>
    TooltipLabelStyle(
      borderColor: const ChartPaint.solid(Colors.white),
      backgroundColor: ChartPaint.solid(_rainfall[item.dataIndex].$2),
    );

String? _mm(AxisTickInfo tick) => '${tick.value.round()}mm';

String? _tooltipLabel(ChartTooltipItem item) =>
    '${item.label} : ${item.formattedValue}mm';

// TrackballBehavior draws a vertical line at the active point.
final Map<String, Object?> _trackball = {
  'id': 'trackball',
  'afterDatasetsDraw': (Chart chart, Object? args, Object? options) {
    final active = chart.getActiveElements();
    if (active.isEmpty) return;
    final area = chart.chartArea!;
    final x = active.first.element!.x;
    chart.ctx!
      ..save()
      ..strokeStyle = _text
      ..lineWidth = 1
      ..beginPath()
      ..moveTo(x, area.top)
      ..lineTo(x, area.bottom)
      ..stroke()
      ..restore();
  },
};

final ChartConfig _config = ChartConfig(
  type: .line,
  datasets: [
    LineDataset(
      label: 'Rainfall',
      points: [
        for (final (i, (mm, _)) in _rainfall.indexed)
          DataPoint.time(DateTime(1925 + i), mm),
      ],
      borderWidth: 2,
      pointRadius: 0,
      pointHoverRadius: 0,
      extra: const {
        'segment': {'borderColor': _segmentColor},
      },
    ),
  ],
  maintainAspectRatio: false,
  padding: const EdgeInsets.all(10),
  title: const ChartTitle(
    display: true,
    text: 'Annual rainfall of Paris',
    color: _text,
    font: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
  ),
  legend: const ChartLegend(display: false),
  // ActivationMode.singleTap: the nearest point on the x axis.
  interaction: const ChartInteraction(
    mode: NearestInteractionMode(),
    intersect: false,
    axis: .x,
  ),
  tooltip: ChartTooltip(
    backgroundColor: _tooltip,
    yAlign: .bottom,
    extra: const {
      'usePointStyle': true,
      'boxPadding': 4,
    },
    callbacks: TooltipCallbacks(
      labelColor: _tooltipMarker,
      title: _noTitle,
      label: (tooltip, arg) {
        final text = _tooltipLabel(arg);
        return text == null
            ? null
            : text.isEmpty
            ? <String>[]
            : [text];
      },
    ),
  ),
  plugins: [_trackball],
  scales: const {
    // DateTimeAxis(intervalType: years, dateFormat: y)
    'x': TimeAxis(
      unit: .year,
      tooltipFormat: 'yyyy',
      grid: AxisGrid(
        drawOnChartArea: false,
        color: _axisLine,
        extra: {'tickLength': 6},
      ),
      ticks: AxisTicks(
        stepSize: 5,
        maxRotation: 0,
        color: _text,
        font: TextStyle(fontSize: 12),
      ),
      title: AxisTitle(
        display: true,
        text: 'Year',
        color: _text,
        font: TextStyle(fontSize: 15),
      ),
      extra: {
        'border': {'color': _axisLine},
      },
    ),
    'y': LinearAxis(
      min: 200,
      max: 600,
      grid: AxisGrid(color: _grid, lineWidth: 0.7, drawTicks: false),
      ticks: AxisTicks(
        stepSize: 100,
        padding: 8,
        color: _text,
        font: TextStyle(fontSize: 12),
        format: _mm,
      ),
      extra: {
        'border': {'display': false},
      },
    ),
  },
);

List<String> _noTitle(TooltipModel tooltip, List<ChartTooltipItem> items) =>
    const [];

class SfMultiColoredLine extends StatelessWidget {
  const SfMultiColoredLine({super.key});

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 320, child: ChartView(config: _config));
}
// #enddocregion sf-multi-colored-line
