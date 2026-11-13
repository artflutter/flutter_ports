// Original code, not ported from Chart.js: a replica of the Syncfusion demo "Line with dashes".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion sf-line-dashes
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

// The first four colors of the Syncfusion palette, and the colors of the
// axes and the tooltip in the light Material 3 theme.
const _colors = [
  Color.fromRGBO(6, 174, 224, 1),
  Color.fromRGBO(99, 85, 199, 1),
  Color.fromRGBO(49, 90, 116, 1),
  Color.fromRGBO(255, 180, 0, 1),
];
const _text = Color(0xFF49454F);
const _axisLine = Color(0xFFCAC4D0);
const _grid = Color(0xFFE6E0E9);
const _tooltip = Color(0xFF322F35);

const _series = {
  'Singapore': [6.6, 6.3, 6.7, 6.7, 6.4, 6.8, 7.7],
  'Saudi Arabia': [9.0, 9.3, 10.2, 10.2, 10.9, 9.3, 10.1],
  'Spain': [15.1, 15.5, 14.5, 13.9, 13.0, 13.4, 14.2],
  'Portugal': [18.8, 18.5, 17.6, 16.1, 17.2, 18.9, 19.4],
};

LineDataset _line(String name, Color color, List<double> values) => LineDataset(
  label: name,
  points: [for (final (i, v) in values.indexed) DataPoint(2010 + i, v)],
  borderColor: .constant(.solid(color)),
  backgroundColor: .constant(.solid(color)),
  borderWidth: 2,
  // dashArray: [15, 3, 3, 3]
  borderDash: const [15, 3, 3, 3],
  pointRadius: 4,
  pointHoverRadius: 4,
  pointBorderWidth: 2,
  pointBackgroundColor: const .constant(.solid(Colors.white)),
  pointBorderColor: .constant(.solid(color)),
  pointHoverBackgroundColor: const .constant(.solid(Colors.white)),
  pointHoverBorderColor: .constant(.solid(color)),
  extra: const {'pointHoverBorderWidth': 2, 'pointHitRadius': 8},
);

String? _year(AxisTickInfo tick) => '${tick.value.round()}';

String? _percent(AxisTickInfo tick) => '${tick.value.round()}%';

String? _tooltipTitle(List<ChartTooltipItem> items) => items.first.datasetLabel;

String? _tooltipLabel(ChartTooltipItem item) {
  final year = (item.parsed! as JsObjectFace)['x']! as num;
  return '${year.round()} : ${item.formattedValue}%';
}

TooltipLabelStyle _tooltipMarker(TooltipModel tooltip, ChartTooltipItem item) =>
    TooltipLabelStyle(
      borderColor: const ChartPaint.solid(Colors.white),
      backgroundColor: ChartPaint.solid(_colors[item.datasetIndex]),
    );

final ChartConfig _config = ChartConfig(
  type: .line,
  datasets: [
    for (final (i, MapEntry(:key, :value)) in _series.entries.indexed)
      _line(key, _colors[i], value),
  ],
  maintainAspectRatio: false,
  padding: const EdgeInsets.all(10),
  title: const ChartTitle(
    display: true,
    text: 'Capital investment as a share of exports',
    color: ChartPaint.solid(_text),
    font: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
  ),
  legend: const ChartLegend(
    usePointStyle: true,
    boxHeight: 7,
    labelColor: ChartPaint.solid(_text),
    labelFont: TextStyle(fontSize: 13),
  ),
  tooltip: ChartTooltip(
    backgroundColor: const ChartPaint.solid(_tooltip),
    yAlign: .bottom,
    extra: const {
      'titleAlign': TextAlign.center,
      'usePointStyle': true,
      'boxPadding': 4,
    },
    callbacks: TooltipCallbacks(
      labelColor: _tooltipMarker,
      title: (tooltip, arg) {
        final text = _tooltipTitle(arg);
        return text == null
            ? null
            : text.isEmpty
            ? <String>[]
            : [text];
      },
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
  scales: const {
    'x': LinearAxis(
      min: 2010,
      max: 2016,
      grid: AxisGrid(
        drawOnChartArea: false,
        color: ChartPaint.solid(_axisLine),
        extra: {'tickLength': 6},
      ),
      ticks: AxisTicks(
        stepSize: 2,
        color: ChartPaint.solid(_text),
        font: TextStyle(fontSize: 12),
        format: _year,
        align: .inner,
      ),
      extra: {
        'border': {'color': ChartPaint.solid(_axisLine)},
      },
    ),
    // NumericAxis(minimum: 3, maximum: 21, interval: 3)
    'y': LinearAxis(
      min: 3,
      max: 21,
      grid: AxisGrid(
        color: ChartPaint.solid(_grid),
        lineWidth: 0.7,
        drawTicks: false,
      ),
      ticks: AxisTicks(
        stepSize: 3,
        padding: 8,
        color: ChartPaint.solid(_text),
        font: TextStyle(fontSize: 12),
        format: _percent,
      ),
      extra: {
        'border': {'display': false},
      },
    ),
  },
);

class const SfLineDashes({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 320, child: ChartView(config: _config));
}
// #enddocregion sf-line-dashes
