/// The adapter of fl_chart. The page imports this library as a deferred
/// library, so that a web build fetches fl_chart only when a person selects it
/// or a run needs it.
library;

import 'dart:math' as math;

import 'package:chart_benchmark_lab/benchmark/config.dart';
import 'package:chart_benchmark_lab/charts/chart_adapter.dart';

import 'package:fl_chart/fl_chart.dart' as fl;
import 'package:material_ui/material_ui.dart';

/// The fl_chart chart of [chart].
Widget flChart(BenchmarkChart chart) => chart._flChart();

// The default of fl_chart takes the text color from the line color, which
// has low contrast on its blue-grey tooltip background.
List<fl.LineTooltipItem> _flLineTooltipItems(List<fl.LineBarSpot> spots) => [
  for (final spot in spots)
    fl.LineTooltipItem(
      spot.y.toString(),
      const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    ),
];

extension on BenchmarkChart {
  /// The fl_chart line shadow. fl_chart converts the radius to a sigma with
  /// `radius * 0.57735 + 0.5`.
  Shadow get _flShadow => config.shadow
      ? Shadow(
          color: chartShadow,
          offset: chartShadowOffset,
          blurRadius: config.shadowBlur ? (chartShadowSigma - .5) / .57735 : 0,
        )
      : const Shadow(color: Colors.transparent);

  /// The zoom of fl_chart: `FlScaleAxis.horizontal` zooms and pans only x.
  /// fl_chart zooms with a pinch and with the mouse wheel, and pans with a
  /// drag. A trackpad scroll pans, its default
  /// (`trackpadScrollCausesScale: false`). Its `minScale` 1 keeps the full
  /// range, and its viewer stops a pan at the edge of the data.
  fl.FlTransformationConfig get _flZoom => config.zooms
      ? const fl.FlTransformationConfig(
          scaleAxis: fl.FlScaleAxis.horizontal,
          maxScale: chartMaxZoom,
        )
      : const fl.FlTransformationConfig();

  fl.FlTitlesData get _titles => fl.FlTitlesData(
    show: config.axes,
    topTitles: const fl.AxisTitles(),
    rightTitles: const fl.AxisTitles(),
    leftTitles: fl.AxisTitles(
      sideTitles: fl.SideTitles(
        showTitles: config.axes,
        reservedSize: 30,
        interval: 25,
        getTitlesWidget: (value, meta) => Text(
          value.toInt().toString(),
          style: const TextStyle(fontSize: 10),
        ),
      ),
    ),
    bottomTitles: fl.AxisTitles(
      sideTitles: fl.SideTitles(
        showTitles: config.axes,
        interval: config.type == ChartType.bar
            ? math.max(1, config.count / 4)
            : 25,
        getTitlesWidget: (value, meta) => Text(
          value.toInt().toString(),
          style: const TextStyle(fontSize: 10),
        ),
      ),
    ),
  );
  fl.FlGridData get _grid => fl.FlGridData(
    show: config.grid,
    horizontalInterval: 25,
    verticalInterval: config.type == ChartType.bar
        ? math.max(1, config.count / 4)
        : 25,
    getDrawingHorizontalLine: (_) =>
        const fl.FlLine(color: chartGrid, strokeWidth: 1),
    getDrawingVerticalLine: (_) =>
        const fl.FlLine(color: chartGrid, strokeWidth: 1),
  );

  Widget _flChart() {
    final values = frame.values;
    switch (config.type) {
      case ChartType.line:
        return fl.LineChart(
          fl.LineChartData(
            minX: 0,
            maxX: 100,
            minY: 0,
            maxY: 100,
            titlesData: _titles,
            gridData: _grid,
            borderData: fl.FlBorderData(show: false),
            clipData: const fl.FlClipData.all(),
            lineTouchData: fl.LineTouchData(
              enabled: config.tooltips,
              touchTooltipData: const fl.LineTouchTooltipData(
                getTooltipItems: _flLineTooltipItems,
              ),
            ),
            lineBarsData: [
              fl.LineChartBarData(
                spots: [for (final p in values) fl.FlSpot(p.x, p.y)],
                color: chartBlue,
                isCurved: config.curved,
                shadow: _flShadow,
                dotData: fl.FlDotData(
                  show: config.markers,
                  getDotPainter: (_, _, _, _) =>
                      fl.FlDotCirclePainter(radius: 3, color: chartBlue),
                ),
                belowBarData: fl.BarAreaData(
                  show: config.fill,
                  color: const Color(0x264f6bed),
                ),
              ),
            ],
          ),
          duration: Duration.zero,
          transformationConfig: _flZoom,
        );
      case ChartType.bar:
        return fl.BarChart(
          fl.BarChartData(
            minY: 0,
            maxY: 100,
            alignment: fl.BarChartAlignment.spaceAround,
            titlesData: _titles,
            gridData: _grid,
            borderData: fl.FlBorderData(show: false),
            barTouchData: fl.BarTouchData(enabled: config.tooltips),
            barGroups: [
              for (final p in values)
                fl.BarChartGroupData(
                  x: p.index,
                  barRods: [
                    fl.BarChartRodData(
                      toY: p.y,
                      color: itemColor(p.index),
                      width: math.max(
                        .01,
                        (size.width - (config.axes ? 30 : 0)) /
                            config.count *
                            .8,
                      ),
                      borderRadius: BorderRadius.zero,
                    ),
                  ],
                ),
            ],
          ),
          duration: Duration.zero,
          transformationConfig: _flZoom,
        );
      case ChartType.scatter:
      case ChartType.bubble:
        return fl.ScatterChart(
          fl.ScatterChartData(
            minX: 0,
            maxX: 100,
            minY: 0,
            maxY: 100,
            titlesData: _titles,
            gridData: _grid,
            borderData: fl.FlBorderData(show: false),
            scatterTouchData: fl.ScatterTouchData(enabled: config.tooltips),
            scatterSpots: [
              for (final p in values)
                fl.ScatterSpot(
                  p.x,
                  p.y,
                  dotPainter: fl.FlDotCirclePainter(
                    radius: config.type == ChartType.bubble ? p.r : 3,
                    color: itemColor(p.index),
                  ),
                ),
            ],
          ),
          duration: Duration.zero,
          transformationConfig: _flZoom,
        );
      case ChartType.pie:
      case ChartType.doughnut:
      case ChartType.polarArea:
        final outer = size.shortestSide / 2 * BenchmarkChart.sliceExtent;
        final hole = config.type == ChartType.doughnut
            ? outer * BenchmarkChart.doughnutCutout
            : 0.0;
        final polar = config.type == ChartType.polarArea;
        return fl.PieChart(
          fl.PieChartData(
            centerSpaceRadius: hole,
            sectionsSpace: 0,
            startDegreeOffset: -90,
            pieTouchData: fl.PieTouchData(enabled: config.tooltips),
            sections: [
              for (final p in values)
                fl.PieChartSectionData(
                  value: polar ? 1 : p.y,
                  color: itemColor(p.index),
                  radius: polar ? outer * p.y / 100 : outer - hole,
                  showTitle: false,
                ),
            ],
          ),
          duration: Duration.zero,
        );
      case ChartType.sankey:
        BenchmarkChart.noSankey();
      case ChartType.radar:
        final side = config.grid
            ? const BorderSide(color: chartGrid)
            : const BorderSide(color: Colors.transparent, width: 0);
        final step = radarLabelStep;
        const label = TextStyle(fontSize: 10, color: Color(0xff677489));
        return fl.RadarChart(
          fl.RadarChartData(
            radarBorderData: side,
            tickBorderData: side,
            gridBorderData: side,
            tickCount: 4,
            // The default offset puts the top and bottom labels outside a plot
            // that fills its height.
            titlePositionPercentageOffset: .1,
            ticksTextStyle: config.axes
                ? label
                : const TextStyle(fontSize: 10, color: Colors.transparent),
            titleTextStyle: label,
            getTitle: config.axes
                ? (index, _) => fl.RadarChartTitle(
                    text: index % step == 0 ? '$index' : '',
                  )
                : null,
            radarTouchData: fl.RadarTouchData(enabled: config.tooltips),
            dataSets: [
              fl.RadarDataSet(
                dataEntries: [
                  for (final p in values) fl.RadarEntry(value: p.y),
                ],
                fillColor: config.fill
                    ? const Color(0x264f6bed)
                    : Colors.transparent,
                borderColor: chartBlue,
                borderWidth: 2,
                entryRadius: config.markers ? 3 : 0,
              ),
            ],
          ),
          duration: Duration.zero,
        );
    }
  }
}
