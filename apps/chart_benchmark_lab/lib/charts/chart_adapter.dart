import 'dart:math' as math;

import 'package:chart_benchmark_lab/benchmark/config.dart';
import 'package:chart_benchmark_lab/benchmark/data.dart';
import 'package:fl_chart/fl_chart.dart' as fl;
import 'package:flutter/material.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart' as cj;
import 'package:graphic/graphic.dart' as gr;
import 'package:syncfusion_flutter_charts/charts.dart' as sf;

/// One active public-widget adapter; inactive engines are never mounted.
class BenchmarkChart extends StatelessWidget {
  /// All engines receive the same immutable source values and feature settings.
  const BenchmarkChart({
    required this.library,
    required this.config,
    required this.frame,
    required this.size,
    super.key,
  });

  /// Selected engine.
  final ChartLibrary library;

  /// Common effective features.
  final BenchmarkConfig config;

  /// Shared input snapshot.
  final DatasetFrame frame;

  /// Identical outer viewport for every engine.
  final Size size;

  @override
  Widget build(BuildContext context) => switch (library) {
    ChartLibrary.chartjs => _chartJs(),
    ChartLibrary.flChart => _flChart(),
    ChartLibrary.graphic => _graphic(),
    ChartLibrary.syncfusion => _syncfusion(),
  };

  Color _color(int index) =>
      config.alternateColors && config.type != ChartType.line && index.isOdd
      ? chartTeal
      : chartBlue;

  Widget _chartJs() {
    final values = frame.values;
    final color = config.alternateColors && config.type != ChartType.line
        ? const cj.ChartValue<Color>.indexed([chartBlue, chartTeal])
        : const cj.ChartValue<Color>.constant(chartBlue);
    final points =
        config.type == ChartType.line || config.type == ChartType.scatter
        ? [for (final p in values) cj.DataPoint(p.x, p.y)]
        : null;
    final dataset = switch (config.type) {
      ChartType.line => cj.LineDataset(
        key: const ValueKey('series'),
        label: 'Values',
        points: points,
        borderColor: const cj.ChartValue.constant(chartBlue),
        borderWidth: 2,
        backgroundColor: const cj.ChartValue.constant(Color(0x264f6bed)),
        pointBackgroundColor: chartBlue,
        pointBorderWidth: 0,
        pointRadius: config.markers ? 3 : 0,
        pointHoverRadius: 3,
        tension: config.curved ? .35 : 0,
        fill: config.fill ? cj.ChartFill.origin : cj.ChartFill.none,
      ),
      ChartType.bar => cj.BarDataset(
        key: const ValueKey('series'),
        label: 'Values',
        data: [for (final p in values) p.y],
        backgroundColor: color,
        borderWidth: 0,
        barPercentage: .8,
        categoryPercentage: 1,
      ),
      ChartType.scatter => cj.ScatterDataset(
        key: const ValueKey('series'),
        label: 'Values',
        points: points,
        backgroundColor: color,
        pointRadius: 3,
        pointBorderWidth: 0,
        showLine: false,
      ),
      ChartType.pie => cj.PieDataset(
        key: const ValueKey('series'),
        label: 'Values',
        data: [for (final p in values) p.y],
        backgroundColor: color,
        borderWidth: 0,
        radius: const cj.ChartLength.percent(90),
      ),
    };
    final grid = cj.AxisGrid(
      display: config.grid,
      color: chartGrid,
      drawTicks: false,
    );
    final ticks = cj.AxisTicks(
      display: config.axes,
      stepSize: 25,
      font: const TextStyle(fontSize: 10),
      maxRotation: 0,
      autoSkip: true,
      extra: const {'maxTicksLimit': 5},
    );
    return cj.ChartView(
      config: cj.ChartConfig(
        type: switch (config.type) {
          ChartType.line => cj.ChartKind.line,
          ChartType.bar => cj.ChartKind.bar,
          ChartType.scatter => cj.ChartKind.scatter,
          ChartType.pie => cj.ChartKind.pie,
        },
        datasets: [dataset],
        labels: config.type == ChartType.bar || config.type == ChartType.pie
            ? [for (final p in values) '${p.index}']
            : null,
        scales: config.type == ChartType.pie
            ? null
            : {
                'x': config.type == ChartType.bar
                    ? cj.CategoryAxis(
                        display: config.axes || config.grid,
                        grid: grid,
                        ticks: ticks,
                      )
                    : cj.LinearAxis(
                        min: 0,
                        max: 100,
                        display: config.axes || config.grid,
                        grid: grid,
                        ticks: ticks,
                      ),
                'y': cj.LinearAxis(
                  min: 0,
                  max: 100,
                  display: config.axes || config.grid,
                  grid: grid,
                  ticks: ticks,
                ),
              },
        animation: cj.ChartAnimation.none,
        legend: const cj.ChartLegend(display: false),
        tooltip: cj.ChartTooltip(enabled: config.tooltips),
        responsive: true,
        maintainAspectRatio: false,
        padding: EdgeInsets.zero,
        extra: {
          // The generator supplies sorted, finite numeric XY points.
          if (config.type == ChartType.line || config.type == ChartType.scatter)
            'parsing': false,
          'events': config.tooltips
              ? ['mousemove', 'mouseout', 'click', 'touchstart', 'touchmove']
              : <String>[],
        },
      ),
      updateMode: 'none',
      theme: const cj.ChartThemeData(),
      excludeFromSemantics: true,
    );
  }

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

  // The default of fl_chart takes the text color from the line color, which
  // has low contrast on its blue-grey tooltip background.
  static List<fl.LineTooltipItem> _flLineTooltipItems(
    List<fl.LineBarSpot> spots,
  ) => [
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
                dotData: fl.FlDotData(
                  show: config.markers,
                  getDotPainter: (_, _, _, _) => fl.FlDotCirclePainter(
                    radius: 3,
                    color: chartBlue,
                  ),
                ),
                belowBarData: fl.BarAreaData(
                  show: config.fill,
                  color: const Color(0x264f6bed),
                ),
              ),
            ],
          ),
          duration: Duration.zero,
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
                      color: _color(p.index),
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
        );
      case ChartType.scatter:
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
                    radius: 3,
                    color: _color(p.index),
                  ),
                ),
            ],
          ),
          duration: Duration.zero,
        );
      case ChartType.pie:
        return fl.PieChart(
          fl.PieChartData(
            centerSpaceRadius: 0,
            sectionsSpace: 0,
            startDegreeOffset: -90,
            pieTouchData: fl.PieTouchData(enabled: config.tooltips),
            sections: [
              for (final p in values)
                fl.PieChartSectionData(
                  value: p.y,
                  color: _color(p.index),
                  radius: math.min(size.width, size.height) * .45,
                  showTitle: false,
                ),
            ],
          ),
          duration: Duration.zero,
        );
    }
  }

  Widget _graphic() {
    final variables = <String, gr.Variable<Sample, dynamic>>{
      if (config.type != ChartType.pie)
        'x': gr.Variable(
          accessor: (p) => p.x,
          scale: gr.LinearScale(min: 0, max: 100, ticks: [0, 25, 50, 75, 100]),
        ),
      'y': gr.Variable(
        accessor: (p) => p.y,
        scale: gr.LinearScale(min: 0, max: 100, ticks: [0, 25, 50, 75, 100]),
      ),
      if (config.type == ChartType.bar || config.type == ChartType.pie)
        'item': gr.Variable(
          accessor: (p) => '${p.index}',
          scale: gr.OrdinalScale(tickCount: 5),
        ),
      if (config.alternateColors && config.type != ChartType.line)
        'index': gr.Variable(accessor: (p) => p.index),
    };
    gr.ColorEncode color() => config.alternateColors
        ? gr.ColorEncode(encoder: (tuple) => _color(tuple['index'] as int))
        : gr.ColorEncode(value: chartBlue);
    final marks = <gr.Mark>[];
    switch (config.type) {
      case ChartType.line:
        if (config.fill) {
          marks.add(
            gr.AreaMark(
              color: gr.ColorEncode(value: const Color(0x264f6bed)),
              shape: gr.ShapeEncode(
                value: gr.BasicAreaShape(smooth: config.curved),
              ),
            ),
          );
        }
        marks.add(
          gr.LineMark(
            color: gr.ColorEncode(value: chartBlue),
            size: gr.SizeEncode(value: 2),
            shape: gr.ShapeEncode(
              value: gr.BasicLineShape(smooth: config.curved),
            ),
          ),
        );
        if (config.markers) {
          marks.add(
            gr.PointMark(
              color: gr.ColorEncode(value: chartBlue),
              size: gr.SizeEncode(value: 6),
            ),
          );
        }
      case ChartType.bar:
        marks.add(
          gr.IntervalMark(
            position: gr.Varset('item') * gr.Varset('y'),
            color: color(),
            size: gr.SizeEncode(
              value: math.max(
                .01,
                (size.width - (config.axes ? 30 : 0)) / config.count * .8,
              ),
            ),
          ),
        );
      case ChartType.scatter:
        marks.add(gr.PointMark(color: color(), size: gr.SizeEncode(value: 6)));
      case ChartType.pie:
        marks.add(
          gr.IntervalMark(
            position: gr.Varset('share') / gr.Varset('item'),
            color: color(),
            modifiers: [gr.StackModifier()],
          ),
        );
    }
    final axes = <gr.AxisGuide<dynamic>>[];
    if (config.type != ChartType.pie && (config.axes || config.grid)) {
      for (final variable in [
        if (config.type == ChartType.bar) 'item' else 'x',
        'y',
      ]) {
        axes.add(
          gr.AxisGuide(
            variable: variable,
            label: config.axes
                ? gr.LabelStyle(
                    textStyle: const TextStyle(
                      fontSize: 10,
                      color: Color(0xff677489),
                    ),
                  )
                : null,
            grid: config.grid
                ? gr.PaintStyle(strokeColor: chartGrid, strokeWidth: 1)
                : null,
          ),
        );
      }
    }
    return gr.Chart<Sample>(
      data: frame.values,
      variables: variables,
      marks: marks,
      // Configuration changes remount the adapter; normal ticks only
      // change data.
      rebuild: false,
      changeData: config.workload == Workload.live,
      transforms: config.type == ChartType.pie
          ? [gr.Proportion(variable: 'y', as: 'share')]
          : null,
      coord: config.type == ChartType.pie
          ? gr.PolarCoord(transposed: true, dimCount: 1, radiusRange: [0, .9])
          : null,
      padding: (_) => config.axes && config.type != ChartType.pie
          ? const EdgeInsets.fromLTRB(30, 0, 0, 22)
          : EdgeInsets.zero,
      axes: axes,
      selections: config.tooltips
          ? {
              'tap': gr.PointSelection(
                on: {gr.GestureType.tap, gr.GestureType.hover},
              ),
            }
          : {},
      tooltip: config.tooltips ? gr.TooltipGuide() : null,
    );
  }

  Widget _syncfusion() {
    final marker = sf.MarkerSettings(
      isVisible: config.markers,
      width: 6,
      height: 6,
      borderWidth: 0,
      color: chartBlue,
    );
    if (config.type == ChartType.pie) {
      return sf.SfCircularChart(
        margin: EdgeInsets.zero,
        tooltipBehavior: sf.TooltipBehavior(enable: config.tooltips),
        series: <sf.CircularSeries<Sample, int>>[
          sf.PieSeries<Sample, int>(
            dataSource: frame.values,
            xValueMapper: (p, _) => p.index,
            yValueMapper: (p, _) => p.y,
            pointColorMapper: (p, _) => _color(p.index),
            animationDuration: 0,
            radius: '90%',
          ),
        ],
      );
    }
    final series = <sf.CartesianSeries<Sample, num>>[];
    if (config.type == ChartType.line) {
      if (config.fill) {
        if (config.curved) {
          series.add(
            sf.SplineAreaSeries<Sample, num>(
              dataSource: frame.values,
              xValueMapper: (p, _) => p.x,
              yValueMapper: (p, _) => p.y,
              color: const Color(0x264f6bed),
              borderColor: chartBlue,
              markerSettings: marker,
              animationDuration: 0,
            ),
          );
        } else {
          series.add(
            sf.AreaSeries<Sample, num>(
              dataSource: frame.values,
              xValueMapper: (p, _) => p.x,
              yValueMapper: (p, _) => p.y,
              color: const Color(0x264f6bed),
              borderColor: chartBlue,
              markerSettings: marker,
              animationDuration: 0,
            ),
          );
        }
      } else if (config.curved) {
        series.add(
          sf.SplineSeries<Sample, num>(
            dataSource: frame.values,
            xValueMapper: (p, _) => p.x,
            yValueMapper: (p, _) => p.y,
            color: chartBlue,
            markerSettings: marker,
            animationDuration: 0,
          ),
        );
      } else {
        series.add(
          sf.LineSeries<Sample, num>(
            dataSource: frame.values,
            xValueMapper: (p, _) => p.x,
            yValueMapper: (p, _) => p.y,
            color: chartBlue,
            markerSettings: marker,
            animationDuration: 0,
          ),
        );
      }
    } else if (config.type == ChartType.bar) {
      series.add(
        sf.ColumnSeries<Sample, num>(
          dataSource: frame.values,
          xValueMapper: (p, _) => p.index,
          yValueMapper: (p, _) => p.y,
          pointColorMapper: (p, _) => _color(p.index),
          color: chartBlue,
          width: .8,
          animationDuration: 0,
        ),
      );
    } else {
      series.add(
        sf.ScatterSeries<Sample, num>(
          dataSource: frame.values,
          xValueMapper: (p, _) => p.x,
          yValueMapper: (p, _) => p.y,
          pointColorMapper: (p, _) => _color(p.index),
          color: chartBlue,
          markerSettings: const sf.MarkerSettings(
            width: 6,
            height: 6,
            borderWidth: 0,
          ),
          animationDuration: 0,
        ),
      );
    }
    sf.NumericAxis axis({required bool x}) => sf.NumericAxis(
      minimum: 0,
      maximum: x && config.type == ChartType.bar
          ? (config.count - 1).toDouble()
          : 100,
      interval: x && config.type == ChartType.bar
          ? math.max(1, config.count / 4)
          : 25,
      isVisible: config.axes || config.grid,
      labelStyle: TextStyle(
        fontSize: 10,
        color: config.axes ? const Color(0xff677489) : Colors.transparent,
      ),
      axisLine: const sf.AxisLine(width: 0),
      majorTickLines: const sf.MajorTickLines(size: 0),
      majorGridLines: sf.MajorGridLines(
        width: config.grid ? 1 : 0,
        color: chartGrid,
      ),
    );
    return sf.SfCartesianChart(
      margin: EdgeInsets.zero,
      plotAreaBorderWidth: 0,
      primaryXAxis: axis(x: true),
      primaryYAxis: axis(x: false),
      tooltipBehavior: sf.TooltipBehavior(enable: config.tooltips),
      series: series,
    );
  }
}
