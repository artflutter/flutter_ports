// Original code, not ported from Chart.js: the parts of the fl_chart replicas.
// ignore_for_file: public_member_api_docs
// #docregion fl_chart-kit
import 'dart:math' as math;

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

abstract final class Fl() {
  static const page = Color(0xFF282E45);
  static const item = Color(0xFF1B2339);
  static const cyan = Color(0xFF50E4FF);
  static const blue = Color(0xFF2196F3);
  static const yellow = Color(0xFFFFC300);
  static const orange = Color(0xFFFF683B);
  static const green = Color(0xFF3BFF49);
  static const purple = Color(0xFF6E1BFF);
  static const pink = Color(0xFFFF3AF2);
  static const red = Color(0xFFE80054);
  static const white70 = Color(0xB3FFFFFF);
  static const white54 = Color(0x8AFFFFFF);
  static const white38 = Color(0x61FFFFFF);
  static const white10 = Color(0x1AFFFFFF);
  static const blueGrey = Color(0xFF607D8B);

  /// No axis line.
  static const noBorder = AxisBorder(display: false);
}

typedef Scriptable = Object? Function(JsObjectFace context);

/// The touch of fl_chart: the spots near the x of the pointer.
const InteractionMode flX = XInteractionMode();

Chart chartOf(JsObjectFace context) => context['chart']! as Chart;

/// A gradient over the chart area, from left to right.
Scriptable horizontalGradient(List<Color> colors, [List<double>? stops]) =>
    (context) {
      final chart = chartOf(context);
      final area = chart.chartArea;
      if (area == null) return ChartPaint.solid(colors.last);
      return ChartGradient.linear(
        Offset(area.left, 0),
        Offset(area.right, 0),
        colors,
        stops: stops,
      );
    };

/// A gradient over the chart area, from top to bottom.
Scriptable verticalGradient(List<Color> colors, List<double> stops) =>
    (context) {
      final chart = chartOf(context);
      final area = chart.chartArea;
      if (area == null) return ChartPaint.solid(colors.last);
      return ChartGradient.linear(
        Offset(0, area.top),
        Offset(0, area.bottom),
        colors,
        stops: stops,
      );
    };

/// The value of the tick of a scale context. The context of the axis line
/// has no tick.
double tickOf(JsObjectFace context) {
  final tick = context['tick'];
  return tick is Tick ? tick.value : double.nan;
}

/// The default grid line of fl_chart: a dash, and no axis line.
const AxisBorder flGridDash = AxisBorder(dash: [8, 4], display: false);

AxisGrid flGrid({bool Function(double value)? show}) => AxisGrid(
  drawTicks: false,
  lineWidth: 0.4,
  extra: {
    'color': (JsObjectFace c) => ChartPaint.solid(
      show == null || show(tickOf(c)) ? Fl.blueGrey : Colors.transparent,
    ),
  },
);

/// The frame around the chart area that fl_chart calls the border data.
Map<String, Object?> areaBorder(Color color, {double width = 1}) => {
  'id': 'areaBorder',
  'afterDraw': (Chart chart, Object? args, Object? options) {
    final area = chart.chartArea!;
    chart.ctx!
      ..save()
      ..strokeStyle = color
      ..lineWidth = width
      ..strokeRect(area.left, area.top, area.width, area.height)
      ..restore();
  },
};

/// The line from a hovered point to an edge, as the touch indicator.
Map<String, Object?> touchIndicator({
  Color? color,
  double width = 4,
  List<double> dash = const [],
  bool toTop = false,
  bool fullHeight = false,
  double? fromValue,
  bool Function(int index)? when,
}) => {
  'id': 'touchIndicator',
  'beforeDatasetsDraw': (Chart chart, Object? args, Object? options) {
    final area = chart.chartArea!;
    final ctx = chart.ctx!;
    for (final hit in chart.getActiveElements()) {
      if (when != null && !when(hit.index)) continue;
      final element = hit.element!;
      final dataset = chart.getDatasetMeta(hit.datasetIndex);
      final options = element.options;
      final stroke =
          color ??
          (options! as JsObjectFace)['borderColor'] ??
          dataset.controller;
      final start = fromValue == null
          ? element.y
          : chart.scales['y']!.getPixelForValue(fromValue);
      final end = fullHeight || toTop ? area.top : area.bottom;
      ctx
        ..save()
        ..strokeStyle = stroke
        ..lineWidth = width
        ..setLineDash(dash)
        ..beginPath()
        ..moveTo(element.x, fullHeight ? area.bottom : start)
        ..lineTo(element.x, fromValue == null ? end : element.y)
        ..stroke()
        ..restore();
    }
  },
};

sealed class const Annotation();

final class const HLine(
  final double y,
  final Color color,
  final double width,
  final List<double> dash, {
  final String? label,
}) extends Annotation;

final class const VLine(
  final double x,
  final Color color,
  final double width,
  final List<double> dash, {
  final String? label,
}) extends Annotation;

final class const VRange(final double x1, final double x2, final Color color)
    extends Annotation;

final class const HRange(final double y1, final double y2, final Color color)
    extends Annotation;

/// A small form of the Chart.js annotation plugin, which is not ported.
Map<String, Object?> annotations(List<Annotation> items) => {
  'id': 'annotations',
  'beforeDatasetsDraw': (Chart chart, Object? args, Object? options) {
    final area = chart.chartArea!;
    final x = chart.scales['x']!;
    final y = chart.scales['y']!;
    final ctx = chart.ctx!..save();
    for (final item in items) {
      switch (item) {
        case VRange(:final x1, :final x2, :final color):
          final left = x.getPixelForValue(x1);
          ctx
            ..fillStyle = color
            ..fillRect(
              left,
              area.top,
              x.getPixelForValue(x2) - left,
              area.height,
            );
        case HRange(:final y1, :final y2, :final color):
          final top = y.getPixelForValue(y2);
          ctx
            ..fillStyle = color
            ..fillRect(
              area.left,
              top,
              area.width,
              y.getPixelForValue(y1) - top,
            );
        case HLine(:final y, :final color, :final width, :final dash):
          final pixel = chart.scales['y']!.getPixelForValue(y);
          ctx
            ..strokeStyle = color
            ..lineWidth = width
            ..setLineDash(dash)
            ..beginPath()
            ..moveTo(area.left, pixel)
            ..lineTo(area.right, pixel)
            ..stroke();
          if (item.label case final text?) {
            ctx
              ..fillStyle = Colors.white
              ..font = const TextStyle(
                fontFamily: 'sans-serif',
                fontSize: 9,
                fontWeight: FontWeight.bold,
              )
              ..textAlign = TextAlign.right
              ..textBaseline = CanvasTextBaseline.bottom
              ..fillText(text, area.right - 5, pixel - 5);
          }
        case VLine(:final x, :final color, :final width, :final dash):
          final pixel = chart.scales['x']!.getPixelForValue(x);
          ctx
            ..strokeStyle = color
            ..lineWidth = width
            ..setLineDash(dash)
            ..beginPath()
            ..moveTo(pixel, area.top)
            ..lineTo(pixel, area.bottom)
            ..stroke();
          if (item.label case final text?) {
            ctx
              ..save()
              ..translate(pixel + 5, area.bottom - 5)
              ..rotate(-math.pi / 2)
              ..fillStyle = Colors.white
              ..font = const TextStyle(
                fontFamily: 'sans-serif',
                fontSize: 9,
                fontWeight: FontWeight.bold,
              )
              ..textAlign = TextAlign.left
              ..textBaseline = CanvasTextBaseline.top
              ..fillText(text, 0, 0)
              ..restore();
          }
      }
    }
    ctx.restore();
  },
};

Color lerpStops(List<Color> colors, List<double> stops, double t) {
  for (var s = 0; s < stops.length - 1; s++) {
    if (t <= stops[s]) return colors[s];
    if (t < stops[s + 1]) {
      return Color.lerp(
        colors[s],
        colors[s + 1],
        (t - stops[s]) / (stops[s + 1] - stops[s]),
      )!;
    }
  }
  return colors.last;
}

const noLegend = ChartLegend(display: false);

const List<ChartPluginList> noPlugins = [];

typedef ChartPluginList = Map<String, Object?>;

/// A chart that fills its box, as the fl_chart widget does.
Widget flChart(
  ChartConfig config, {
  Object? updateMode,
  ValueChanged<Chart>? onChartCreated,
}) => ChartView(
  config: config,
  updateMode: updateMode as String?,
  onChartCreated: onChartCreated,
);

/// The defaults of fl_chart. fl_chart draws the lines over the edges of the
/// chart area (`FlClipData.none()`). Chart.js clips a dataset at an edge with
/// a fixed `min` or `max`, which cuts thick lines at the edge. A sample that
/// pans or zooms passes `clip: true`.
ChartConfig fills(ChartConfig config, {bool clip = false}) => config.copyWith(
  maintainAspectRatio: false,
  legend: config.legend ?? noLegend,
  elements: config.elements ?? _touchRadius,
  extra: clip
      ? config.extra
      : {
          ...?config.extra,
          'datasets': {
            'line': {'clip': ChartClip.none},
          },
        },
);

/// fl_chart reacts within 10 pixels of a spot.
const _touchRadius = ChartElements(
  extra: {
    'point': {'hitRadius': 10},
  },
);
// #enddocregion fl_chart-kit
