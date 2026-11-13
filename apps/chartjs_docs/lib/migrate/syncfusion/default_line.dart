// Original code, not ported from Chart.js: a replica of the Syncfusion demo "Default line chart".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion sf-default-line
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

// The first colors of the Syncfusion palette, and the colors of the axes
// and the tooltip in the light Material 3 theme.
const _germany = Color.fromRGBO(6, 174, 224, 1);
const _england = Color.fromRGBO(99, 85, 199, 1);
const _text = Color(0xFF49454F);
const _axisLine = Color(0xFFCAC4D0);
const _grid = Color(0xFFE6E0E9);
const _tooltip = Color(0xFF322F35);
const List<Color> _colors = [_germany, _england];

LineDataset _series(String name, Color color, List<num> values) => LineDataset(
  label: name,
  points: [for (final (i, v) in values.indexed) DataPoint(2005 + i, v)],
  borderColor: .constant(.solid(color)),
  // The legend and the tooltip take this color.
  backgroundColor: .constant(.solid(color)),
  borderWidth: 2,
  // MarkerSettings(isVisible: true): a white circle with a colored border.
  pointRadius: 4,
  pointHoverRadius: 4,
  pointBorderWidth: 2,
  pointBackgroundColor: const .constant(.solid(Colors.white)),
  pointBorderColor: .constant(.solid(color)),
  pointHoverBackgroundColor: const .constant(.solid(Colors.white)),
  pointHoverBorderColor: .constant(.solid(color)),
  extra: const {'pointHoverBorderWidth': 2, 'pointHitRadius': 8},
);

List<String>? _year(Scale scale, double value, int index, List<Tick> ticks) => [
  '${value.round()}',
];

List<String>? _percent(
  Scale scale,
  double value,
  int index,
  List<Tick> ticks,
) => ['${value.round()}%'];

String? _tooltipTitle(List<TooltipItem> items) => items.first.datasetLabel;

// The marker in the tooltip: a filled circle with a white border.
TooltipLabelStyle _tooltipMarker(TooltipModel tooltip, TooltipItem item) =>
    TooltipLabelStyle(
      borderColor: const ChartPaint.solid(Colors.white),
      backgroundColor: ChartPaint.solid(_colors[item.datasetIndex]),
    );

String? _tooltipLabel(TooltipItem item) {
  final year = (item.parsed! as JsObjectFace)['x']! as num;
  return '${year.round()} : ${item.formattedValue}%';
}

final ChartConfig _config = ChartConfig(
  type: .line,
  datasets: [
    _series('Germany', _germany, const [21, 24, 36, 38, 54, 57, 70]),
    _series('England', _england, const [28, 44, 48, 50, 66, 78, 84]),
  ],
  maintainAspectRatio: false,
  padding: const EdgeInsets.all(10),
  title: const ChartTitle(
    display: true,
    text: 'Inflation - Consumer price',
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
    // NumericAxis(interval: 2, edgeLabelPlacement: shift), no grid lines.
    'x': LinearAxis(
      min: 2005,
      max: 2011,
      grid: AxisGrid(
        drawOnChartArea: false,
        color: ChartPaint.solid(_axisLine),
        extra: {'tickLength': 6},
      ),
      ticks: AxisTicks(
        stepSize: 2,
        color: ChartPaint.solid(_text),
        font: TextStyle(fontSize: 12),
        callback: _year,
        align: .inner,
      ),
      border: AxisBorder(color: ChartPaint.solid(_axisLine)),
    ),
    // labelFormat: '{value}%', no axis line, no tick marks.
    'y': LinearAxis(
      min: 0,
      max: 100,
      grid: AxisGrid(
        color: ChartPaint.solid(_grid),
        lineWidth: 0.7,
        drawTicks: false,
      ),
      ticks: AxisTicks(
        stepSize: 20,
        padding: 8,
        color: ChartPaint.solid(_text),
        font: TextStyle(fontSize: 12),
        callback: _percent,
      ),
      border: AxisBorder(display: false),
    ),
  },
);

class const SfDefaultLine({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 320, child: ChartView(config: _config));
}
// #enddocregion sf-default-line
