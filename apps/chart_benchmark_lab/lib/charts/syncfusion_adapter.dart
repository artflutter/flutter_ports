/// The adapter of Syncfusion. The page imports this library as a deferred
/// library, so that a web build fetches Syncfusion only when a person selects
/// it or a run needs it.
library;

import 'dart:math' as math;

import 'package:chart_benchmark_lab/benchmark/config.dart';
import 'package:chart_benchmark_lab/benchmark/data.dart';
import 'package:chart_benchmark_lab/charts/chart_adapter.dart';

import 'package:material_ui/material_ui.dart';
import 'package:syncfusion_flutter_charts/charts.dart' as sf;

/// The Syncfusion chart of [chart].
Widget syncfusionChart(BenchmarkChart chart) => chart._syncfusion();

extension on BenchmarkChart {
  /// The zoom of Syncfusion: pinch, pan and wheel zoom, with `ZoomMode.x`.
  /// `maximumZoomLevel` 1/[chartMaxZoom] is its default 0.01. A zoom out stops
  /// at the full range, and a pan stays inside it. The selection zoom (a box)
  /// and the double-tap zoom stay off: fl_chart and Graphic have neither.
  sf.ZoomPanBehavior? get _sfZoom => config.zooms
      ? sf.ZoomPanBehavior(
          enablePinching: true,
          enablePanning: true,
          enableMouseWheelZooming: true,
          zoomMode: sf.ZoomMode.x,
          // The default, given so that a change of chartMaxZoom reaches it.
          // ignore: avoid_redundant_argument_values
          maximumZoomLevel: 1 / chartMaxZoom,
        )
      : null;

  Widget _syncfusion() {
    final marker = sf.MarkerSettings(
      isVisible: config.markers,
      width: 6,
      height: 6,
      borderWidth: 0,
      color: chartBlue,
    );
    if (!config.type.hasAxes) {
      const radius = '${BenchmarkChart.sliceExtent * 100}%';
      return sf.SfCircularChart(
        margin: EdgeInsets.zero,
        tooltipBehavior: sf.TooltipBehavior(enable: config.tooltips),
        series: <sf.CircularSeries<Sample, int>>[
          switch (config.type) {
            ChartType.doughnut => sf.DoughnutSeries<Sample, int>(
              dataSource: frame.values,
              xValueMapper: (p, _) => p.index,
              yValueMapper: (p, _) => p.y,
              pointColorMapper: (p, _) => itemColor(p.index),
              animationDuration: 0,
              radius: radius,
              innerRadius: '${BenchmarkChart.doughnutCutout * 100}%',
            ),
            // The public form of a polar area: equal slices, a radius for each.
            ChartType.polarArea => sf.PieSeries<Sample, int>(
              dataSource: frame.values,
              xValueMapper: (p, _) => p.index,
              yValueMapper: (_, _) => 1,
              pointColorMapper: (p, _) => itemColor(p.index),
              pointRadiusMapper: (p, _) =>
                  '${p.y * BenchmarkChart.sliceExtent}%',
              animationDuration: 0,
              radius: radius,
            ),
            _ => sf.PieSeries<Sample, int>(
              dataSource: frame.values,
              xValueMapper: (p, _) => p.index,
              yValueMapper: (p, _) => p.y,
              pointColorMapper: (p, _) => itemColor(p.index),
              animationDuration: 0,
              radius: radius,
            ),
          },
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
          pointColorMapper: (p, _) => itemColor(p.index),
          color: chartBlue,
          width: .8,
          animationDuration: 0,
        ),
      );
    } else if (config.type == ChartType.bubble) {
      series.add(
        sf.BubbleSeries<Sample, num>(
          dataSource: frame.values,
          xValueMapper: (p, _) => p.x,
          yValueMapper: (p, _) => p.y,
          // The series divides each size by the largest size, then scales it
          // into the range below, so y gives the shared radius formula. A
          // segment draws at twice its radius, so the range is half of it.
          sizeValueMapper: (p, _) => p.y,
          minimumRadius: bubbleRadius(0) / 2,
          maximumRadius: bubbleRadius(100) / 2,
          pointColorMapper: (p, _) => itemColor(p.index),
          color: chartBlue,
          animationDuration: 0,
        ),
      );
    } else {
      series.add(
        sf.ScatterSeries<Sample, num>(
          dataSource: frame.values,
          xValueMapper: (p, _) => p.x,
          yValueMapper: (p, _) => p.y,
          pointColorMapper: (p, _) => itemColor(p.index),
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
      zoomPanBehavior: _sfZoom,
      series: series,
    );
  }
}
