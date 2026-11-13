// Original code, not ported from Chart.js: a replica of the Syncfusion demo "Customized line chart".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion sf-customized-line
import 'dart:math' as math;

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _text = Color(0xFF49454F);
const _axisLine = Color(0xFFCAC4D0);
const _grid = Color(0xFFE6E0E9);
const _tooltip = Color(0xFF322F35);
// The second color of the Syncfusion palette: the markers.
const _marker = Color.fromRGBO(99, 85, 199, 1);
const _lineColor = Color.fromRGBO(53, 92, 125, 1);
const _dash = [15.0, 3.0, 3.0, 3.0];

// The share of each month from July 2018.
const List<double> _share = [2.9, 2.7, 2.3, 2.5, 2.2, 1.9, 1.6, 1.5, 1.9, 2];

// The custom renderer of the original draws a dashed line at the highest
// and at the lowest value, with a label. Here an inline plugin draws them
// after the datasets.
final Map<String, Object?> _highLow = {
  'id': 'highLow',
  'afterDatasetsDraw': (Chart chart, Object? args, Object? options) {
    final points = chart.getDatasetMeta(1).data;
    final y = chart.scales['y']!;
    final left = points.first.x;
    final right = points.last.x;
    final high = y.getPixelForValue(_share.reduce(math.max));
    final low = y.getPixelForValue(_share.reduce(math.min));
    final lowIndex = _share.indexOf(_share.reduce(math.min));
    chart.ctx!
      ..save()
      ..lineWidth = 2
      ..setLineDash(_dash)
      ..strokeStyle = Colors.green
      ..beginPath()
      ..moveTo(left, high)
      ..lineTo(right, high)
      ..stroke()
      ..strokeStyle = Colors.red
      ..beginPath()
      ..moveTo(left, low)
      ..lineTo(right, low)
      ..stroke()
      ..font = const TextStyle(fontFamily: 'sans-serif', fontSize: 12)
      ..textAlign = TextAlign.left
      ..textBaseline = CanvasTextBaseline.bottom
      ..fillStyle = Colors.green.shade800
      ..fillText('High point', left + 5, high - 10)
      ..textBaseline = CanvasTextBaseline.top
      ..fillStyle = Colors.red.shade800
      ..fillText('Low point', points[lowIndex].x, low + 10)
      ..restore();
  },
};

String? _percent(AxisTickInfo tick) {
  final value = tick.value;
  return '${value == value.roundToDouble() ? value.round() : value}%';
}

String? _tooltipLabel(ChartTooltipItem item) =>
    '${item.label} : ${item.formattedValue}%';

List<String> _noTitle(TooltipModel tooltip, List<ChartTooltipItem> items) =>
    const [];

final ChartConfig _config = ChartConfig(
  type: .line,
  datasets: [
    // A black line on the top and the right edges, with no tooltip.
    LineDataset(
      points: [
        DataPoint.time(DateTime(2018, 7), 3.5),
        DataPoint.time(DateTime(2019, 4), 3.5),
        DataPoint.time(DateTime(2019, 4), 1),
      ],
      borderColor: const .constant(.solid(Colors.black)),
      borderWidth: 2,
      pointRadius: 0,
      pointHoverRadius: 0,
      extra: const {'pointHitRadius': 0, 'clip': 0, 'animation': false},
    ),
    LineDataset(
      points: [
        for (final (i, share) in _share.indexed)
          DataPoint.time(DateTime(2018, 7 + i), share),
      ],
      borderColor: const .constant(.solid(_lineColor)),
      borderWidth: 2,
      pointRadius: 4,
      pointHoverRadius: 4,
      pointBorderWidth: 2,
      pointBackgroundColor: const .constant(.solid(Colors.white)),
      pointBorderColor: const .constant(.solid(_marker)),
      pointHoverBackgroundColor: const .constant(.solid(Colors.white)),
      pointHoverBorderColor: const .constant(.solid(_marker)),
      extra: const {'pointHoverBorderWidth': 2, 'pointHitRadius': 8},
    ),
  ],
  maintainAspectRatio: false,
  padding: const EdgeInsets.all(10),
  title: const ChartTitle(
    display: true,
    text: 'Capital investment as a share of exports',
    color: .solid(_text),
    font: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
  ),
  legend: const ChartLegend(display: false),
  // TooltipBehavior(header: '', canShowMarker: false)
  tooltip: ChartTooltip(
    backgroundColor: const .solid(_tooltip),
    displayColors: false,
    yAlign: .bottom,
    extra: const {},
    callbacks: TooltipCallbacks(
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
  plugins: [_highLow],
  scales: {
    // DateTimeAxis(intervalType: months, interval: 3, dateFormat: yMMM)
    'x': TimeAxis(
      min: DateTime(2018, 7),
      max: DateTime(2019, 4),
      unit: .month,
      tooltipFormat: 'MMM yyyy',
      grid: const AxisGrid(
        color: .solid(_grid),
        lineWidth: 0.7,
        extra: {'tickColor': ChartPaint.solid(_axisLine), 'tickLength': 6},
      ),
      ticks: const AxisTicks(
        stepSize: 3,
        maxRotation: 0,
        color: .solid(_text),
        font: TextStyle(fontSize: 12),
        align: .inner,
      ),
      extra: const {
        'border': {'color': ChartPaint.solid(_axisLine)},
      },
    ),
    // NumericAxis(minimum: 1, maximum: 3.5, interval: 0.5), no grid lines.
    'y': const LinearAxis(
      min: 1,
      max: 3.5,
      grid: AxisGrid(
        drawOnChartArea: false,
        color: ChartPaint.solid(_axisLine),
        extra: {'tickLength': 6},
      ),
      ticks: AxisTicks(
        stepSize: 0.5,
        color: ChartPaint.solid(_text),
        font: TextStyle(fontSize: 12),
        format: _percent,
      ),
      extra: {
        'border': {'color': ChartPaint.solid(_axisLine)},
      },
    ),
  },
);

class const SfCustomizedLine({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 320, child: ChartView(config: _config));
}
// #enddocregion sf-customized-line
