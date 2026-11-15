/// The adapter of apexcharts_flutter. The page imports this library as a
/// deferred library, so that a web build fetches apexcharts_flutter only when
/// a person selects it or a run needs it.
library;

import 'package:apexcharts_flutter/apexcharts_flutter.dart' as apex;
import 'package:chart_benchmark_lab/benchmark/config.dart';
import 'package:chart_benchmark_lab/charts/chart_adapter.dart';

import 'package:material_ui/material_ui.dart';

/// The apexcharts_flutter chart of [chart].
Widget apexChart(BenchmarkChart chart) => chart._apex();

/// The fill of a line or a radar, the alpha of the other libraries.
const double _fillAlpha = 0x26 / 0xff;

/// One category List for each item count and radar label step: a label
/// between two steps is empty, and the radar draws no empty label.
final Map<(int, int), List<String>> _radarCategories = {};

List<String> _radarCategoriesFor(int count, int step) =>
    _radarCategories.putIfAbsent(
      (count, step),
      () => List<String>.generate(
        count,
        (i) => i % step == 0 ? '$i' : '',
        growable: false,
      ),
    );

extension on BenchmarkChart {
  /// The colors of the series, or of the slices of a pie or a doughnut.
  List<Color> get _colors => config.alternateColors && config.type.hasItemColors
      ? const [chartBlue, chartTeal]
      : const [chartBlue];

  /// The chart through the typed `ApexOptions` of apexcharts_flutter, the
  /// public model that `ApexOptions.fromJson` gives. The adapter takes the
  /// constructor, so that each tick pays for no parse of a JSON Map: the
  /// other libraries also get typed objects.
  ///
  /// The package draws with its own geometry, and some of it has no option:
  /// - it always draws the grid and the axis labels of a line, bar, scatter
  ///   or bubble chart, and the rings, the spokes, the markers and the fill
  ///   of a radar ([ChartLibrary.fixedFeatures]);
  /// - its y axis has no `min` or `max`: a nice scale fits it to the data;
  /// - a scatter marker has a radius of 5 and a white border of 1;
  /// - a slice has a white border of 2, and a pie takes about 97% of half of
  ///   the short side;
  /// - a doughnut draws its hole as a white circle over a pie;
  /// - a radar takes the radius that its labels leave.
  ///
  /// The x axis of a bar chart is `numeric`, with the index of each bar as
  /// its x value. The package then draws 7 x labels, as on a line chart. On a
  /// `category` axis, it draws one label for each bar, also at 20,000 bars,
  /// where the other libraries draw a few. The bars stay in the same bands.
  Widget _apex() {
    final values = frame.values;
    final type = config.type;
    final options = switch (type) {
      ChartType.pie || ChartType.doughnut => apex.ApexOptions(
        type: type == ChartType.pie
            ? apex.ApexChartType.pie
            : apex.ApexChartType.donut,
        series: const [],
        pieSeries: [for (final p in values) p.y],
        colors: _colors,
        pie: const apex.ApexPieOptions(
          donutSizeFraction: BenchmarkChart.doughnutCutout,
        ),
        legend: const apex.ApexLegend(position: apex.ApexLegendPosition.none),
        animations: const apex.ApexAnimations(enabled: false),
      ),
      ChartType.radar => apex.ApexOptions(
        type: apex.ApexChartType.radar,
        series: [
          apex.ApexSeries(
            name: 'Values',
            points: [for (final p in values) apex.ApexPoint(y: p.y)],
          ),
        ],
        colors: _colors,
        categories: config.axes
            ? _radarCategoriesFor(values.length, radarLabelStep)
            : const [],
        legend: const apex.ApexLegend(position: apex.ApexLegendPosition.none),
        animations: const apex.ApexAnimations(enabled: false),
      ),
      ChartType.line ||
      ChartType.bar ||
      ChartType.scatter ||
      ChartType.bubble => apex.ApexOptions(
        type: switch (type) {
          ChartType.line =>
            config.fill ? apex.ApexChartType.area : apex.ApexChartType.line,
          ChartType.bar => apex.ApexChartType.bar,
          ChartType.scatter => apex.ApexChartType.scatter,
          _ => apex.ApexChartType.bubble,
        },
        series: [
          apex.ApexSeries(
            name: 'Values',
            points: switch (type) {
              ChartType.bar => [
                for (final p in values)
                  apex.ApexPoint(x: p.index.toDouble(), y: p.y),
              ],
              ChartType.bubble => [
                for (final p in values) apex.ApexPoint(x: p.x, y: p.y, z: p.r),
              ],
              _ => [for (final p in values) apex.ApexPoint(x: p.x, y: p.y)],
            },
          ),
        ],
        colors: _colors,
        xAxisType: apex.ApexXAxisType.numeric,
        // A line, scatter or bubble chart has its x range from 0 to 100.
        xMin: type == ChartType.bar ? null : 0,
        xMax: type == ChartType.bar ? null : 100,
        curve: config.curved ? apex.ApexCurve.smooth : apex.ApexCurve.straight,
        markers: apex.ApexMarkers(
          size: type == ChartType.line && config.markers ? 3 : 0,
          strokeWidth: 0,
          strokeColor: chartBlue,
        ),
        // A flat fill: both ends of the gradient have the same color.
        gradient: const apex.ApexGradientFill(
          enabled: true,
          opacityFrom: _fillAlpha,
          opacityTo: _fillAlpha,
          shadeIntensity: 0,
        ),
        bar: const apex.ApexBarOptions(columnWidthFraction: .8),
        // The radius of each bubble is its z value, with no scale.
        bubble: const apex.ApexBubbleOptions(zScaling: false),
        legend: const apex.ApexLegend(position: apex.ApexLegendPosition.none),
        animations: const apex.ApexAnimations(enabled: false),
      ),
      ChartType.polarArea => throw StateError(
        'apexcharts_flutter has no polar area chart.',
      ),
      ChartType.sankey => BenchmarkChart.noSankey(),
    };
    return apex.ApexChart(options: options, enableTooltip: config.tooltips);
  }
}
