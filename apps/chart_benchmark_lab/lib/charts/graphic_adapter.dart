/// The adapter of Graphic. The page imports this library as a deferred
/// library, so that a web build fetches Graphic only when a person selects it
/// or a run needs it.
library;

import 'dart:math' as math;

import 'package:chart_benchmark_lab/benchmark/config.dart';
import 'package:chart_benchmark_lab/benchmark/data.dart';
import 'package:chart_benchmark_lab/charts/chart_adapter.dart';

import 'package:graphic/graphic.dart' as gr;
import 'package:material_ui/material_ui.dart';

/// The Graphic chart of [chart].
Widget graphicChart(BenchmarkChart chart) => chart._graphic();

/// The default range event of Graphic: a one-pointer drag pans, a pinch
/// zooms by the horizontal spread of the fingers (a vertical pinch does
/// nothing), and the mouse wheel zooms by 10%. A pinch and the wheel grow
/// or shrink the range on both sides alike, around the middle of the data,
/// not at the fingers or the cursor. Its double tap, which goes back to
/// the full range, is off (see [_graphicRange]). A bar keeps its width in
/// pixels, the size of its mark, as an fl_chart rod does.
final gr.EventUpdater<List<double>> _graphicRangeEvent =
    gr.Defaults.horizontalRangeEvent;

/// The horizontal range updater of Graphic: [_graphicRangeEvent], kept
/// inside the full range and at most [chartMaxZoom] times, as the other
/// libraries are. Without the bounds, a Graphic pan moves the data out of
/// view, and a zoom out makes it smaller than the plot. A double tap keeps
/// the range: the other libraries have no double-tap reset (the double-tap
/// zoom of Syncfusion is off).
List<double> _graphicRange(
  List<double> init,
  List<double> pre,
  gr.Event event,
) {
  if (event is gr.GestureEvent &&
      event.gesture.type == gr.GestureType.doubleTap) {
    return pre;
  }
  final next = _graphicRangeEvent(init, pre, event);
  // The range is the width of the data as a share of the plot: [0, 1] is
  // the full range, and a zoom makes it wider.
  final width = (next.last - next.first).clamp(1.0, chartMaxZoom);
  final start = ((next.first + next.last - width) / 2).clamp(1 - width, 0.0);
  return start == next.first && start + width == next.last
      ? next
      : [start, start + width];
}

extension on BenchmarkChart {
  /// The Graphic shadow: Material elevation, the only shadow of its API.
  gr.ElevationEncode? get _graphicElevation =>
      config.shadow ? gr.ElevationEncode(value: 4) : null;

  Widget _graphic() {
    final slices =
        config.type == ChartType.pie || config.type == ChartType.doughnut;
    final radial =
        slices ||
        config.type == ChartType.polarArea ||
        config.type == ChartType.radar;
    final variables = <String, gr.Variable<Sample, dynamic>>{
      if (!radial)
        'x': gr.Variable(
          accessor: (p) => p.x,
          scale: gr.LinearScale(min: 0, max: 100, ticks: [0, 25, 50, 75, 100]),
        ),
      'y': gr.Variable(
        accessor: (p) => p.y,
        scale: gr.LinearScale(min: 0, max: 100, ticks: [0, 25, 50, 75, 100]),
      ),
      if (config.type == ChartType.bar || radial)
        'item': gr.Variable(
          accessor: (p) => '${p.index}',
          // A radar has one spoke per item, so one tick per item.
          scale: gr.OrdinalScale(
            tickCount: config.type == ChartType.radar ? null : 5,
          ),
        ),
      if (config.alternateColors && config.type.hasItemColors)
        'index': gr.Variable(accessor: (p) => p.index),
    };
    gr.ColorEncode color() => config.alternateColors
        ? gr.ColorEncode(encoder: (tuple) => itemColor(tuple['index'] as int))
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
      case ChartType.bubble:
        marks.add(
          gr.PointMark(
            color: color(),
            size: gr.SizeEncode(
              encoder: (tuple) => bubbleRadius(tuple['y'] as double) * 2,
            ),
          ),
        );
      case ChartType.pie:
      case ChartType.doughnut:
        marks.add(
          gr.IntervalMark(
            position: gr.Varset('share') / gr.Varset('item'),
            color: color(),
            modifiers: [gr.StackModifier()],
          ),
        );
      case ChartType.polarArea:
        marks.add(
          gr.IntervalMark(
            position: gr.Varset('item') * gr.Varset('y'),
            color: color(),
          ),
        );
      case ChartType.sankey:
        BenchmarkChart.noSankey();
      case ChartType.radar:
        gr.Varset position() => gr.Varset('item') * gr.Varset('y');
        if (config.fill) {
          marks.add(
            gr.AreaMark(
              position: position(),
              color: gr.ColorEncode(value: const Color(0x264f6bed)),
              shape: gr.ShapeEncode(value: gr.BasicAreaShape(loop: true)),
            ),
          );
        }
        marks.add(
          gr.LineMark(
            position: position(),
            color: gr.ColorEncode(value: chartBlue),
            size: gr.SizeEncode(value: 2),
            shape: gr.ShapeEncode(value: gr.BasicLineShape(loop: true)),
          ),
        );
        if (config.markers) {
          marks.add(
            gr.PointMark(
              position: position(),
              color: gr.ColorEncode(value: chartBlue),
              size: gr.SizeEncode(value: 6),
            ),
          );
        }
    }
    // Only the filled marks: on a line, the elevation shadows a polygon.
    if (!config.type.drawsLine) {
      for (final mark in marks) {
        mark.elevation = _graphicElevation;
      }
    }
    final axes = <gr.AxisGuide<dynamic>>[];
    if (config.type.hasAxes && (config.axes || config.grid)) {
      final labelStyle = config.axes
          ? gr.LabelStyle(
              textStyle: const TextStyle(
                fontSize: 10,
                color: Color(0xff677489),
              ),
            )
          : null;
      final gridStyle = config.grid
          ? gr.PaintStyle(strokeColor: chartGrid, strokeWidth: 1)
          : null;
      if (config.type == ChartType.radar) {
        final step = radarLabelStep;
        axes
          ..add(
            gr.AxisGuide(
              variable: 'item',
              position: 1,
              labelMapper: config.axes
                  ? (_, index, _) => index % step == 0 ? labelStyle : null
                  : null,
              grid: gridStyle,
            ),
          )
          ..add(
            gr.AxisGuide(variable: 'y', label: labelStyle, grid: gridStyle),
          );
      } else {
        for (final variable in [
          if (config.type == ChartType.bar) 'item' else 'x',
          'y',
        ]) {
          axes.add(
            gr.AxisGuide(
              variable: variable,
              label: labelStyle,
              grid: gridStyle,
            ),
          );
        }
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
      transforms: slices ? [gr.Proportion(variable: 'y', as: 'share')] : null,
      coord: switch (config.type) {
        ChartType.pie => gr.PolarCoord(
          transposed: true,
          dimCount: 1,
          radiusRange: [0, BenchmarkChart.sliceExtent],
        ),
        ChartType.doughnut => gr.PolarCoord(
          transposed: true,
          dimCount: 1,
          radiusRange: [
            BenchmarkChart.sliceExtent * BenchmarkChart.doughnutCutout,
            BenchmarkChart.sliceExtent,
          ],
        ),
        ChartType.polarArea => gr.PolarCoord(
          radiusRange: [0, BenchmarkChart.sliceExtent],
        ),
        // Unlike a radius range, this also limits the spokes and the labels.
        ChartType.radar => gr.PolarCoord(endRadius: BenchmarkChart.radarExtent),
        _ when config.zooms => gr.RectCoord(
          horizontalRangeUpdater: _graphicRange,
        ),
        _ => null,
      },
      padding: (_) =>
          config.axes && config.type.hasAxes && config.type != ChartType.radar
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
}
