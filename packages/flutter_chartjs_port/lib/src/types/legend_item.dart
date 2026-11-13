// Original code, not ported from Chart.js: native extensible legend items.

/// The native legend item contract.
library;

import 'dart:ui' show StrokeCap, StrokeJoin, TextAlign;

import 'package:flutter_chartjs_port/src/helpers/point_style.dart'
    show PointStyle;
import 'package:flutter_chartjs_port/src/types/chart_paint.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart' show TRBLCorners;

/// A legend entry shared by generation, rendering and interaction.
///
/// Plugins may extend or implement this class. Consumers retain item identity.
/// Subclasses override [copyWith] to preserve their type and extra state, and
/// [merge] when their additional fields participate in merging.
class LegendItem {
  /// Creates a mutable legend entry. Lists and style objects retain identity.
  LegendItem({
    required this.text,
    this.fillStyle = const ChartPaint.unchanged(),
    this.fontColor = const ChartPaint.unchanged(),
    this.hidden = false,
    this.lineCap,
    this.lineDash,
    this.lineDashOffset,
    this.lineJoin,
    this.lineWidth,
    this.strokeStyle = const ChartPaint.unchanged(),
    this.pointStyle,
    this.rotation,
    this.textAlign,
    this.borderRadius,
    this.datasetIndex,
    this.index,
  });

  /// The label lines.
  List<String> text;

  /// The box fill; unchanged uses the resolved legend baseline.
  ChartPaint fillStyle;

  /// The text paint; unchanged uses the resolved legend baseline.
  ChartPaint fontColor;

  /// Whether the represented dataset or data item is hidden.
  bool hidden;

  /// The border cap, or the legend default.
  StrokeCap? lineCap;

  /// The border dash pattern, or the legend default.
  List<double>? lineDash;

  /// The border dash offset in pixels.
  double? lineDashOffset;

  /// The border join, or the legend default.
  StrokeJoin? lineJoin;

  /// The border width in pixels.
  double? lineWidth;

  /// The box stroke; unchanged uses the resolved legend baseline.
  ChartPaint strokeStyle;

  /// The point marker, including custom plugin styles.
  PointStyle? pointStyle;

  /// The point marker rotation in degrees.
  double? rotation;

  /// The label alignment, or the legend default.
  TextAlign? textAlign;

  /// The four box corner radii, or square corners.
  TRBLCorners? borderRadius;

  /// The dataset index, absent for a data-item or descriptive entry.
  int? datasetIndex;

  /// The data-item index, absent for a dataset or descriptive entry.
  int? index;

  /// Null arguments retain the current field. Nullable fields can be cleared
  /// directly on the returned mutable item.
  LegendItem copyWith({
    List<String>? text,
    ChartPaint? fillStyle,
    ChartPaint? fontColor,
    bool? hidden,
    StrokeCap? lineCap,
    List<double>? lineDash,
    double? lineDashOffset,
    StrokeJoin? lineJoin,
    double? lineWidth,
    ChartPaint? strokeStyle,
    PointStyle? pointStyle,
    double? rotation,
    TextAlign? textAlign,
    TRBLCorners? borderRadius,
    int? datasetIndex,
    int? index,
  }) => LegendItem(
    text: text ?? this.text,
    fillStyle: fillStyle ?? this.fillStyle,
    fontColor: fontColor ?? this.fontColor,
    hidden: hidden ?? this.hidden,
    lineCap: lineCap ?? this.lineCap,
    lineDash: lineDash ?? this.lineDash,
    lineDashOffset: lineDashOffset ?? this.lineDashOffset,
    lineJoin: lineJoin ?? this.lineJoin,
    lineWidth: lineWidth ?? this.lineWidth,
    strokeStyle: strokeStyle ?? this.strokeStyle,
    pointStyle: pointStyle ?? this.pointStyle,
    rotation: rotation ?? this.rotation,
    textAlign: textAlign ?? this.textAlign,
    borderRadius: borderRadius ?? this.borderRadius,
    datasetIndex: datasetIndex ?? this.datasetIndex,
    index: index ?? this.index,
  );

  /// Text and hidden replace their values. Null optional fields and unchanged
  /// paints inherit. Neither input is mutated; merge(null) returns this.
  LegendItem merge(LegendItem? other) {
    if (other == null) return this;
    return copyWith(
      text: other.text,
      fillStyle: other.fillStyle is UnchangedChartPaint
          ? null
          : other.fillStyle,
      fontColor: other.fontColor is UnchangedChartPaint
          ? null
          : other.fontColor,
      hidden: other.hidden,
      lineCap: other.lineCap,
      lineDash: other.lineDash,
      lineDashOffset: other.lineDashOffset,
      lineJoin: other.lineJoin,
      lineWidth: other.lineWidth,
      strokeStyle: other.strokeStyle is UnchangedChartPaint
          ? null
          : other.strokeStyle,
      pointStyle: other.pointStyle,
      rotation: other.rotation,
      textAlign: other.textAlign,
      borderRadius: other.borderRadius,
      datasetIndex: other.datasetIndex,
      index: other.index,
    );
  }
}
