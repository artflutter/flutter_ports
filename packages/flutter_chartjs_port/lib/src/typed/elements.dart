// Original code, not ported from Chart.js: the typed element options.

/// The element options of the typed API (Chart.js ADR 0052, sections 1 and
/// 4): [ChartElements], the group `options.elements`, and the options of
/// each element type, [PointElementStyle], [LineElementStyle],
/// [BarElementStyle] and [ArcElementStyle] (`docs/configuration/
/// elements.md`).
///
/// An element option is a default of all datasets of the chart: an option
/// of a dataset with the same name wins over it. Thus
/// `ChartElements(point: PointElementStyle(radius: 0))` hides the points of
/// each line dataset that sets no `pointRadius`
/// (`docs/general/performance.md`).
library;

import 'dart:ui' show Color;

import 'package:flutter/foundation.dart'
    show DiagnosticPropertiesBuilder, Diagnosticable, immutable;
import 'package:flutter_chartjs_port/src/typed/lower.dart';
import 'package:flutter_chartjs_port/src/typed/props.dart';
import 'package:flutter_chartjs_port/src/typed/values.dart'
    show ChartFill, ChartPointStyle;
import 'package:meta/meta.dart' show internal;

/// The options of the element types: `options.elements`
/// (`docs/configuration/elements.md`).
///
/// A pie, a doughnut and a polar area chart draw arcs, a bar chart draws
/// bars, and a line, a scatter, a bubble and a radar chart draw points and
/// lines.
@immutable
final class ChartElements with Diagnosticable {
  /// The element options.
  const ChartElements({this.point, this.line, this.bar, this.arc, this.extra});

  /// The options of the points: `elements.point`.
  final PointElementStyle? point;

  /// The options of the lines: `elements.line`.
  final LineElementStyle? line;

  /// The options of the bars: `elements.bar`.
  final BarElementStyle? bar;

  /// The options of the arcs: `elements.arc`.
  final ArcElementStyle? arc;

  /// The Chart.js element options that have no parameter, for example the
  /// options of a custom element type. The entries go into the `elements`
  /// Map last: an entry wins over a parameter with the same key. A Map
  /// value merges into the Map of the key, a List or another value replaces
  /// it.
  final Map<String, Object?>? extra;

  /// A copy of these element options with the given parameters. A
  /// parameter that is `null` keeps its value.
  ChartElements copyWith({
    PointElementStyle? point,
    LineElementStyle? line,
    BarElementStyle? bar,
    ArcElementStyle? arc,
    Map<String, Object?>? extra,
  }) => ChartElements(
    point: point ?? this.point,
    line: line ?? this.line,
    bar: bar ?? this.bar,
    arc: arc ?? this.arc,
    extra: extra ?? this.extra,
  );

  List<TypedProperty> get _props => [
    ('point', point),
    ('line', line),
    ('bar', bar),
    ('arc', arc),
    ('extra', byEntries(extra)),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartElements && propsEqual(_props, other._props);

  @override
  int get hashCode => propsHash(_props);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    addProps(properties, _props);
  }
}

/// The `elements` Map of [elements]: the keys in parameter order, `extra`
/// last.
@internal
Map<String, Object?> lowerElements(ChartElements elements) =>
    mergeExtra(<String, Object?>{
      if (elements.point case final point?) 'point': point._lower(),
      if (elements.line case final line?) 'line': line._lower(),
      if (elements.bar case final bar?) 'bar': bar._lower(),
      if (elements.arc case final arc?) 'arc': arc._lower(),
    }, elements.extra);

/// The options of the points of a chart: `elements.point`
/// (`docs/configuration/elements.md`, "Point Configuration").
///
/// A dataset option with the prefix `point` wins over each option, for
/// example `LineDataset.pointRadius` over [radius].
@immutable
final class PointElementStyle with Diagnosticable {
  /// The point options.
  const PointElementStyle({
    this.radius,
    this.pointStyle,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.hitRadius,
    this.hoverRadius,
    this.extra,
  });

  /// The radius of a point in pixels: `radius`. 0 draws no points. The
  /// default is 3.
  final double? radius;

  /// The style of a point: `pointStyle`. The default is a circle.
  final ChartPointStyle? pointStyle;

  /// The fill color of a point: `backgroundColor`.
  final Color? backgroundColor;

  /// The border color of a point: `borderColor`.
  final Color? borderColor;

  /// The border width of a point in pixels: `borderWidth`. The default is
  /// 1.
  final double? borderWidth;

  /// The radius in pixels, added to [radius], in which a pointer hits a
  /// point: `hitRadius`. The default is 1.
  final double? hitRadius;

  /// The radius of a point under the pointer, in pixels: `hoverRadius`. The
  /// default is 4.
  final double? hoverRadius;

  /// The Chart.js point options that have no parameter, for example
  /// `{'rotation': 45}`. The rules of [ChartElements.extra] apply.
  final Map<String, Object?>? extra;

  /// A copy of these point options with the given parameters. A parameter
  /// that is `null` keeps its value.
  PointElementStyle copyWith({
    double? radius,
    ChartPointStyle? pointStyle,
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    double? hitRadius,
    double? hoverRadius,
    Map<String, Object?>? extra,
  }) => PointElementStyle(
    radius: radius ?? this.radius,
    pointStyle: pointStyle ?? this.pointStyle,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    hitRadius: hitRadius ?? this.hitRadius,
    hoverRadius: hoverRadius ?? this.hoverRadius,
    extra: extra ?? this.extra,
  );

  /// The `point` Map.
  Map<String, Object?> _lower() => mergeExtra(<String, Object?>{
    'radius': ?radius,
    'pointStyle': ?pointStyle?.optionValue,
    'backgroundColor': ?colorValue(backgroundColor),
    'borderColor': ?colorValue(borderColor),
    'borderWidth': ?borderWidth,
    'hitRadius': ?hitRadius,
    'hoverRadius': ?hoverRadius,
  }, extra);

  List<TypedProperty> get _props => [
    ('radius', radius),
    ('pointStyle', pointStyle),
    ('backgroundColor', backgroundColor),
    ('borderColor', borderColor),
    ('borderWidth', borderWidth),
    ('hitRadius', hitRadius),
    ('hoverRadius', hoverRadius),
    ('extra', byEntries(extra)),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PointElementStyle && propsEqual(_props, other._props);

  @override
  int get hashCode => propsHash(_props);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    addProps(properties, _props);
  }
}

/// The options of the lines of a chart: `elements.line`
/// (`docs/configuration/elements.md`, "Line Configuration").
///
/// The line of a line and a radar dataset reads them. A dataset option of
/// the same name wins over each option, for example `LineDataset.tension`
/// over [tension].
@immutable
final class LineElementStyle with Diagnosticable {
  /// The line options.
  const LineElementStyle({
    this.tension,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderDash,
    this.fill,
    this.stepped,
    this.extra,
  });

  /// The Bézier curve tension of a line, from 0 (straight lines) to 1:
  /// `tension`. The default is 0.
  final double? tension;

  /// The fill color under a line: `backgroundColor`.
  final Color? backgroundColor;

  /// The color of a line: `borderColor`.
  final Color? borderColor;

  /// The width of a line in pixels: `borderWidth`. The default is 3.
  final double? borderWidth;

  /// The dash pattern of a line, lengths of dashes and gaps in pixels:
  /// `borderDash`. The default is a solid line.
  final List<double>? borderDash;

  /// The fill of the area under or between the lines: `fill`. The default
  /// is no fill.
  final ChartFill? fill;

  /// Whether a line is a stepped line: `stepped` as a boolean. The other
  /// forms go through [extra].
  final bool? stepped;

  /// The Chart.js line options that have no parameter, for example
  /// `{'cubicInterpolationMode': 'monotone'}`. The rules of
  /// [ChartElements.extra] apply.
  final Map<String, Object?>? extra;

  /// A copy of these line options with the given parameters. A parameter
  /// that is `null` keeps its value.
  LineElementStyle copyWith({
    double? tension,
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    List<double>? borderDash,
    ChartFill? fill,
    bool? stepped,
    Map<String, Object?>? extra,
  }) => LineElementStyle(
    tension: tension ?? this.tension,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    borderDash: borderDash ?? this.borderDash,
    fill: fill ?? this.fill,
    stepped: stepped ?? this.stepped,
    extra: extra ?? this.extra,
  );

  /// The `line` Map.
  Map<String, Object?> _lower() => mergeExtra(<String, Object?>{
    'tension': ?tension,
    'backgroundColor': ?colorValue(backgroundColor),
    'borderColor': ?colorValue(borderColor),
    'borderWidth': ?borderWidth,
    'borderDash': ?numberList(borderDash),
    'fill': ?fill?.optionValue,
    'stepped': ?stepped,
  }, extra);

  List<TypedProperty> get _props => [
    ('tension', tension),
    ('backgroundColor', backgroundColor),
    ('borderColor', borderColor),
    ('borderWidth', borderWidth),
    ('borderDash', byItems(borderDash)),
    ('fill', fill),
    ('stepped', stepped),
    ('extra', byEntries(extra)),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineElementStyle && propsEqual(_props, other._props);

  @override
  int get hashCode => propsHash(_props);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    addProps(properties, _props);
  }
}

/// The options of the bars of a chart: `elements.bar`
/// (`docs/configuration/elements.md`, "Bar Configuration").
///
/// A dataset option of the same name wins over each option, for example
/// `BarDataset.borderRadius` over [borderRadius].
@immutable
final class BarElementStyle with Diagnosticable {
  /// The bar options.
  const BarElementStyle({
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.extra,
  });

  /// The fill color of a bar: `backgroundColor`.
  final Color? backgroundColor;

  /// The border color of a bar: `borderColor`.
  final Color? borderColor;

  /// The border width of a bar in pixels: `borderWidth`. The default is 0.
  final double? borderWidth;

  /// The radius of the corners of a bar in pixels: `borderRadius` as a
  /// number. The object form goes through [extra].
  final double? borderRadius;

  /// The Chart.js bar options that have no parameter, for example
  /// `{'borderSkipped': false}`. The rules of [ChartElements.extra] apply.
  final Map<String, Object?>? extra;

  /// A copy of these bar options with the given parameters. A parameter
  /// that is `null` keeps its value.
  BarElementStyle copyWith({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    double? borderRadius,
    Map<String, Object?>? extra,
  }) => BarElementStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    extra: extra ?? this.extra,
  );

  /// The `bar` Map.
  Map<String, Object?> _lower() => mergeExtra(<String, Object?>{
    'backgroundColor': ?colorValue(backgroundColor),
    'borderColor': ?colorValue(borderColor),
    'borderWidth': ?borderWidth,
    'borderRadius': ?borderRadius,
  }, extra);

  List<TypedProperty> get _props => [
    ('backgroundColor', backgroundColor),
    ('borderColor', borderColor),
    ('borderWidth', borderWidth),
    ('borderRadius', borderRadius),
    ('extra', byEntries(extra)),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarElementStyle && propsEqual(_props, other._props);

  @override
  int get hashCode => propsHash(_props);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    addProps(properties, _props);
  }
}

/// The options of the arcs of a chart: `elements.arc`
/// (`docs/configuration/elements.md`, "Arc Configuration").
///
/// A dataset option of the same name wins over each option, for example
/// `PieDataset.offset` over [offset].
@immutable
final class ArcElementStyle with Diagnosticable {
  /// The arc options.
  const ArcElementStyle({
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.offset,
    this.spacing,
    this.extra,
  });

  /// The fill color of an arc: `backgroundColor`.
  final Color? backgroundColor;

  /// The border color of an arc: `borderColor`. The default is white.
  final Color? borderColor;

  /// The border width of an arc in pixels: `borderWidth`. The default is
  /// 2.
  final double? borderWidth;

  /// The offset of an arc from the center, in pixels: `offset`.
  final double? offset;

  /// The space between two arcs, in pixels: `spacing`.
  final double? spacing;

  /// The Chart.js arc options that have no parameter, for example
  /// `{'borderAlign': 'inner'}`. The rules of [ChartElements.extra] apply.
  final Map<String, Object?>? extra;

  /// A copy of these arc options with the given parameters. A parameter
  /// that is `null` keeps its value.
  ArcElementStyle copyWith({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    double? offset,
    double? spacing,
    Map<String, Object?>? extra,
  }) => ArcElementStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    offset: offset ?? this.offset,
    spacing: spacing ?? this.spacing,
    extra: extra ?? this.extra,
  );

  /// The `arc` Map.
  Map<String, Object?> _lower() => mergeExtra(<String, Object?>{
    'backgroundColor': ?colorValue(backgroundColor),
    'borderColor': ?colorValue(borderColor),
    'borderWidth': ?borderWidth,
    'offset': ?offset,
    'spacing': ?spacing,
  }, extra);

  List<TypedProperty> get _props => [
    ('backgroundColor', backgroundColor),
    ('borderColor', borderColor),
    ('borderWidth', borderWidth),
    ('offset', offset),
    ('spacing', spacing),
    ('extra', byEntries(extra)),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArcElementStyle && propsEqual(_props, other._props);

  @override
  int get hashCode => propsHash(_props);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    addProps(properties, _props);
  }
}
