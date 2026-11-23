// Original code, not ported from Chart.js: a replica of the Graphic demo "Transposed Bar Chart".
// ignore_for_file: lines_longer_than_80_chars
// #docregion graphic-bar-transposed
import 'package:chartjs_docs/migrate/graphic/graphic_bar_data.dart';
import 'package:chartjs_docs/migrate/graphic/graphic_bar_kit.dart';
import 'package:chartjs_docs/migrate/graphic/graphic_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

final ({double min, double max}) _range = graphicRange([
  for (final row in basicData) row.sold,
]);

/// The `LinearGradient` of a `GradientEncode` goes from the left to the
/// right of the region: the chart area.
ChartPaint _gradient(
  ScriptableContext context,
  List<Color> colors,
  List<double> stops,
) {
  // The legend reads the colors before the layout: no area yet.
  final area = context.chart.chartArea;
  if (area == null) return .solid(colors.last);
  return ChartGradient.linear(
    Offset(area.left, 0),
    Offset(area.right, 0),
    colors,
    stops: stops,
  );
}

ChartPaint _fill(ScriptableContext context) => _gradient(
  context,
  const [Color(0x8883bff6), Color(0x88188df0), Color(0xcc188df0)],
  const [0, 0.5, 1],
);

/// The gradient of the `tap` updater: the fill of the selected bar.
ChartPaint _selectedFill(ScriptableContext context) => _gradient(
  context,
  const [Color(0xee83bff6), Color(0xee3f78f7), Color(0xff3f78f7)],
  const [0, 0.7, 1],
);

String _sold(int dataset, int index) => '${basicData[index].sold}';

final ChartConfig _config = ChartConfig(
  // `RectCoord(transposed: true)`.
  indexAxis: const YAxis(),
  labels: [for (final row in basicData) row.genre],
  datasets: [
    BarDataset(
      data: .values([for (final row in basicData) row.sold]),
      backgroundColor: const .resolver(_fill),
      hoverBackgroundColor: const .resolver(_selectedFill),
      barThickness: const BarThickness.pixels(barSize),
      // The bars start at the left of the axis.
      extra: {'base': _range.min},
    ),
  ],
  scales: [
    LinearAxis(
      .x,
      min: _range.min,
      max: _range.max,
      grid: lineGrid,
      ticks: graphicTicks(callback: numberLabel, stepSize: 80),
      border: const AxisBorder(display: false),
      extra: bottomAxis,
    ),
    // Graphic puts the first genre at the bottom.
    CategoryAxis(
      .y,
      reverse: true,
      grid: noGrid,
      ticks: graphicTicks(),
      border: const AxisBorder(color: .solid(Gx.stroke)),
      extra: leftAxis,
    ),
  ],
  padding: regionPadding,
  maintainAspectRatio: false,
  animation: ChartAnimation.none,
  legend: const ChartLegend(display: false),
  // `PointSelection(dim: Dim.x)`: a tap selects the bar nearest along the
  // genre axis.
  interaction: const ChartInteraction(
    mode: IndexInteractionMode(),
    intersect: false,
    axis: .y,
  ),
  pluginOptions: const [TooltipOptions(enabled: false)],
  plugins: [barLabels(_sold), tapSelection()],
  events: const ['click'],
);

/// The replica of the Graphic demo "Transposed Bar Chart".
class const GraphicBarTransposed({super.key}) extends StatelessWidget {
  /// Creates the replica.
  this;

  @override
  Widget build(BuildContext context) => GraphicBox(
    child: ChartView(
      config: _config,
      semanticLabel: 'Horizontal bar chart of the sales of five game genres',
    ),
  );
}
// #enddocregion graphic-bar-transposed

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: GraphicBarTransposed(),
        ),
      ),
    ),
  );
}
