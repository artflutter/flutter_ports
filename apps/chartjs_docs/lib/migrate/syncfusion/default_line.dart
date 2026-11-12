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
  borderColor: .constant(color),
  // The legend and the tooltip take this color.
  backgroundColor: .constant(color),
  borderWidth: 2,
  // MarkerSettings(isVisible: true): a white circle with a colored border.
  pointRadius: 4,
  pointHoverRadius: 4,
  pointBorderWidth: 2,
  pointBackgroundColor: Colors.white,
  pointBorderColor: color,
  pointHoverBackgroundColor: Colors.white,
  pointHoverBorderColor: color,
  extra: const {'pointHoverBorderWidth': 2, 'pointHitRadius': 8},
);

String? _year(AxisTickInfo tick) => '${tick.value.round()}';

String? _percent(AxisTickInfo tick) => '${tick.value.round()}%';

String? _tooltipTitle(List<ChartTooltipItem> items) => items.first.datasetLabel;

// The marker in the tooltip: a filled circle with a white border.
Map<String, Object?> _tooltipMarker(JsObjectFace item) => {
  'borderColor': Colors.white,
  'backgroundColor': _colors[(item['datasetIndex']! as num).toInt()],
};

String? _tooltipLabel(ChartTooltipItem item) {
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
    color: _text,
    font: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
  ),
  legend: const ChartLegend(
    usePointStyle: true,
    boxHeight: 7,
    labelColor: _text,
    labelFont: TextStyle(fontSize: 13),
  ),
  tooltip: const ChartTooltip(
    backgroundColor: _tooltip,
    titleText: _tooltipTitle,
    labelText: _tooltipLabel,
    yAlign: .bottom,
    extra: {
      'titleAlign': 'center',
      'usePointStyle': true,
      'boxPadding': 4,
      'callbacks': {'labelColor': _tooltipMarker},
    },
  ),
  scales: const {
    // NumericAxis(interval: 2, edgeLabelPlacement: shift), no grid lines.
    'x': LinearAxis(
      min: 2005,
      max: 2011,
      grid: AxisGrid(
        drawOnChartArea: false,
        color: _axisLine,
        extra: {'tickLength': 6},
      ),
      ticks: AxisTicks(
        stepSize: 2,
        color: _text,
        font: TextStyle(fontSize: 12),
        format: _year,
        align: .inner,
      ),
      extra: {
        'border': {'color': _axisLine},
      },
    ),
    // labelFormat: '{value}%', no axis line, no tick marks.
    'y': LinearAxis(
      min: 0,
      max: 100,
      grid: AxisGrid(color: _grid, lineWidth: 0.7, drawTicks: false),
      ticks: AxisTicks(
        stepSize: 20,
        padding: 8,
        color: _text,
        font: TextStyle(fontSize: 12),
        format: _percent,
      ),
      extra: {
        'border': {'display': false},
      },
    ),
  },
);

class SfDefaultLine extends StatelessWidget {
  const SfDefaultLine({super.key});

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 320, child: ChartView(config: _config));
}
// #enddocregion sf-default-line
