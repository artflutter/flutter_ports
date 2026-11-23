// Original code, not ported from Chart.js: a replica of the Graphic demo "Interactive Bar Chart".
// ignore_for_file: lines_longer_than_80_chars
// #docregion graphic-bar-interactive
import 'package:chartjs_docs/migrate/graphic/graphic_bar_data.dart';
import 'package:chartjs_docs/migrate/graphic/graphic_bar_kit.dart';
import 'package:chartjs_docs/migrate/graphic/graphic_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

final ({double min, double max}) _range = graphicRange([
  for (final row in basicData) row.sold,
]);

/// `ColorEncode(updaters: {'tap': {false: ...}})`: while a bar is
/// selected, the other bars fade to the alpha 100.
ChartPaint _color(ScriptableContext context) => .solid(
  (context.chart as Chart).getActiveElements().isEmpty
      ? Gx.primary
      : Gx.primary.withAlpha(100),
);

String _sold(int dataset, int index) => '${basicData[index].sold}';

String? _genreLine(List<TooltipItem> items) =>
    'genre: ${basicData[items.first.dataIndex].genre}';

String? _soldLine(TooltipItem item) =>
    'sold: ${basicData[item.dataIndex].sold}';

final ChartConfig _config = ChartConfig(
  labels: [for (final row in basicData) row.genre],
  datasets: [
    BarDataset(
      data: .values([for (final row in basicData) row.sold]),
      backgroundColor: const .resolver(_color),
      // The selected bar keeps the primary color.
      hoverBackgroundColor: const .constant(.solid(Gx.primary)),
      barThickness: const BarThickness.pixels(barSize),
      // The bars of Graphic start at 0, below the axis, and the region clips
      // them. The bars start at the bottom of the axis: the same look, and a
      // tap also selects a short bar.
      extra: {'base': _range.min},
    ),
  ],
  scales: [
    CategoryAxis(
      .x,
      grid: noGrid,
      ticks: graphicTicks(),
      border: bottomBorder,
      extra: bottomAxis,
    ),
    LinearAxis(
      .y,
      min: _range.min,
      max: _range.max,
      grid: lineGrid,
      ticks: graphicTicks(callback: numberLabel, stepSize: 80),
      border: leftBorder,
      extra: leftAxis,
    ),
  ],
  padding: regionPadding,
  maintainAspectRatio: false,
  animation: ChartAnimation.none,
  legend: const ChartLegend(display: false),
  // `PointSelection(dim: Dim.x)`: a tap selects the bar nearest in x.
  interaction: const ChartInteraction(
    mode: IndexInteractionMode(),
    intersect: false,
  ),
  pluginOptions: [
    graphicTooltip(
      position: const CenterPositioner(),
      title: _genreLine,
      label: _soldLine,
    ),
  ],
  plugins: [
    selectedElevation(color: Gx.primary),
    barLabels(_sold),
    barCrosshair,
    tooltipShadow,
    tapSelection(refresh: true),
  ],
  events: const ['click'],
);

/// The replica of the Graphic demo "Interactive Bar Chart".
class const GraphicBarInteractive({super.key}) extends StatelessWidget {
  /// Creates the replica.
  this;

  @override
  Widget build(BuildContext context) => GraphicBox(
    child: ChartView(
      config: _config,
      semanticLabel: 'Bar chart of the sales of five game genres',
    ),
  );
}
// #enddocregion graphic-bar-interactive

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: GraphicBarInteractive(),
        ),
      ),
    ),
  );
}
