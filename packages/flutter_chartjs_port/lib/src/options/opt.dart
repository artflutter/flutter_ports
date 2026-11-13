// Original code, not ported from Chart.js: the option cell of the typed model.

/// The option cell of the typed internal model (Chart.js ADR 0054 §1).
///
/// A typed option scope holds one [Opt] cell for each key that it owns. A
/// field of the type `Opt<T>?` is Dart `null` for an absent key. The three
/// JS states of a key stay apart:
/// - an absent key: the field is Dart `null`;
/// - an own key with the value `undefined`: [optUndefined];
/// - an own key with the value JS `null`: [optNull].
///
/// The other cases keep the value as the user gave it:
/// - [OptValue]: a value of the type of the key (a number as a `double`);
/// - [OptFunction]: a function value (a scriptable option, or a callback);
/// - [OptList]: an array (an indexable option, or a plain array);
/// - [OptScope]: a nested option object: a typed scope or a raw Map;
/// - [OptForeign]: any other JS value, outside the type of the key.
///
/// The type parameter `T` is the type of the key. The classification
/// functions ([classifyNumber], [classifyBool], [classifyString],
/// [classifyTyped], [classifyScope] and [classifyUnion]) give the cell of a
/// raw JS value for a key of a given shape. The order of their tests is the
/// order of the resolver: `undefined`, `null`, a function, an array, an
/// object, then the plain value.
///
/// This library is a pure layer.
library;

import 'dart:ui' show Locale, StrokeCap, StrokeJoin, TextAlign, TextDirection;

import 'package:flutter/animation.dart' show Curve;
import 'package:flutter/painting.dart' show EdgeInsets, TextStyle;
import 'package:flutter_chartjs_port/src/core/core.adapters.dart' show TimeUnit;
import 'package:flutter_chartjs_port/src/core/core.interaction.dart'
    show InteractionAxis, InteractionMode;
import 'package:flutter_chartjs_port/src/core/scale_option_enums.dart'
    show ScaleBounds, TickAlign, TickCrossAlign, TickSource;
import 'package:flutter_chartjs_port/src/helpers/cubic_interpolation_mode.dart'
    show CubicInterpolationMode;
import 'package:flutter_chartjs_port/src/helpers/grace_length.dart'
    show GraceLength;
import 'package:flutter_chartjs_port/src/helpers/point_style.dart'
    show PointStyle;
import 'package:flutter_chartjs_port/src/helpers/radius_length.dart'
    show RadiusLength;
import 'package:flutter_chartjs_port/src/js/js_function.dart' show jsIsFunction;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show JsObjectFace;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/plugins/decimation_algorithm.dart'
    show DecimationAlgorithm;
import 'package:flutter_chartjs_port/src/plugins/fill_target.dart'
    show FillTarget;
import 'package:flutter_chartjs_port/src/plugins/filler_draw_time.dart'
    show FillerDrawTime;
import 'package:flutter_chartjs_port/src/plugins/tooltip_position.dart'
    show TooltipPositioner;
import 'package:flutter_chartjs_port/src/types/align.dart'
    show ChartAlign, TooltipXAlign, TooltipYAlign;
import 'package:flutter_chartjs_port/src/types/arc_option_enums.dart'
    show ArcBorderAlign, ArcSpacingMode;
import 'package:flutter_chartjs_port/src/types/bar_option_enums.dart'
    show BorderSkippedEdge;
import 'package:flutter_chartjs_port/src/types/chart_axis.dart'
    show CartesianAxis, RAxis, ScaleAxis;
import 'package:flutter_chartjs_port/src/types/data_item.dart'
    show TypedDataItem;
import 'package:flutter_chartjs_port/src/types/layout.dart'
    show ChartPosition, LayoutPosition;
import 'package:flutter_chartjs_port/src/types/line_option_enums.dart'
    show SteppedLine;
import 'package:flutter_chartjs_port/src/types/tooltip_callbacks.dart';
import 'package:intl/intl.dart' show NumberFormat;

/// One option value of a typed scope (Chart.js ADR 0054 §1).
sealed class Opt<T> {
  const Opt();

  /// The JS value of the cell, as the user gave it: [undefined] for
  /// [OptUndefined] and Dart `null` (JS `null`) for [OptNull].
  Object? get raw;
}

/// A value of the type of the key.
final class OptValue<T> extends Opt<T> {
  /// The cell of [value].
  const OptValue(this.value);

  /// The value. A JS number is a `double`.
  final T value;

  @override
  Object? get raw => value;

  @override
  String toString() => 'OptValue($value)';
}

/// A function value: a Dart `Function`, a `JsFunction` or a class value
/// (`jsIsFunction`).
final class OptFunction<T> extends Opt<T> {
  /// The cell of [function].
  const OptFunction(this.function);

  /// The function value, as the user gave it.
  final Object function;

  @override
  Object? get raw => function;

  @override
  String toString() => 'OptFunction($function)';
}

/// An array, as the user gave it (the same List).
final class OptList<T> extends Opt<T> {
  /// The cell of [items].
  const OptList(this.items);

  /// The array.
  final List<Object?> items;

  @override
  Object? get raw => items;

  @override
  String toString() => 'OptList($items)';
}

/// A nested option object: a typed scope or a raw `Map<String, Object?>`
/// (the same object).
final class OptScope<T> extends Opt<T> {
  /// The cell of [scope].
  const OptScope(this.scope);

  /// The nested object.
  final Object scope;

  @override
  Object? get raw => scope;

  @override
  String toString() => 'OptScope(${scope.runtimeType})';
}

/// An own key with the value `undefined`.
final class OptUndefined extends Opt<Never> {
  const OptUndefined._();

  @override
  Object? get raw => undefined;

  @override
  String toString() => 'OptUndefined';
}

/// An own key with the value JS `null`.
final class OptNull extends Opt<Never> {
  const OptNull._();

  @override
  Object? get raw => null;

  @override
  String toString() => 'OptNull';
}

/// A JS value outside the type of the key, kept as given (Chart.js ADR 0054
/// §6), for example the string `'5'` of a number key.
final class OptForeign<T> extends Opt<T> {
  /// The cell of [value].
  const OptForeign(this.value);

  /// The value, as the user gave it.
  final Object value;

  @override
  Object? get raw => value;

  @override
  String toString() => 'OptForeign($value)';
}

/// The cell of an own key with the value `undefined`.
const Opt<Never> optUndefined = OptUndefined._();

/// The cell of an own key with the value JS `null`.
const Opt<Never> optNull = OptNull._();

/// The atoms of a shape of the schema (`tool/options_schema.yaml`), as an
/// `int` mask for [classifyUnion].
///
/// The seven plain atoms (`number` to `any`) are bits 0 to 6. A typed atom
/// is its index from 1 shifted left by 7, in the bits of [typed]: a shape
/// holds at most one typed atom, and the index leaves room for 2^24 of them
/// below the sign bit (dart2js computes the bit operations in 32 bits).
abstract final class ShapeBits {
  /// `number`: a JS number.
  static const int number = 1;

  /// `bool`.
  static const int boolean = 2;

  /// `string`.
  static const int string = 4;

  /// `fn`: a plain function value.
  static const int function = 8;

  /// `list`: a plain array value.
  static const int list = 16;

  /// `scope <Kind>`: a nested option object.
  static const int scope = 32;

  /// `any`: any JS value.
  static const int any = 64;

  /// `curve`: a Flutter [Curve], the value of `easing`.
  static const int curve = 128;

  /// `interactionMode`: an [InteractionMode], the value of `mode` of the
  /// interaction options.
  static const int interactionMode = 256;

  /// `tooltipPositioner`: a [TooltipPositioner], the value of `position` of
  /// the tooltip options.
  static const int tooltipPositioner = 384;

  /// `strokeCap`: a Flutter [StrokeCap], the value of `borderCapStyle`.
  static const int strokeCap = 512;

  /// `strokeJoin`: a Flutter [StrokeJoin], the value of `borderJoinStyle`.
  static const int strokeJoin = 640;

  /// `interactionAxis`: an [InteractionAxis], the value of `axis` of the
  /// interaction options.
  static const int interactionAxis = 768;

  /// `decimationAlgorithm`: a [DecimationAlgorithm], the value of
  /// `algorithm` of the decimation plugin.
  static const int decimationAlgorithm = 896;

  /// `scaleBounds`: a [ScaleBounds], the value of `bounds` of a scale.
  static const int scaleBounds = 1024;

  /// `tickSource`: a [TickSource], the value of `ticks.source`.
  static const int tickSource = 1152;

  /// `tickAlign`: a [TickAlign], the value of `ticks.align`.
  static const int tickAlign = 1280;

  /// `tickCrossAlign`: a [TickCrossAlign], the value of `ticks.crossAlign`.
  static const int tickCrossAlign = 1408;

  /// `chartAlign`: a [ChartAlign], the value of `align` of a box.
  static const int chartAlign = 1536;

  /// `tooltipXAlign`: a [TooltipXAlign], the value of `xAlign` of the
  /// tooltip.
  static const int tooltipXAlign = 1664;

  /// `tooltipYAlign`: a [TooltipYAlign], the value of `yAlign` of the
  /// tooltip.
  static const int tooltipYAlign = 1792;

  /// `arcBorderAlign`: an [ArcBorderAlign], the value of `borderAlign`.
  static const int arcBorderAlign = 1920;

  /// `arcSpacingMode`: an [ArcSpacingMode], the value of `spacingMode`.
  static const int arcSpacingMode = 2048;

  /// `fillerDrawTime`: a [FillerDrawTime], the value of `drawTime` of the
  /// filler.
  static const int fillerDrawTime = 2176;

  /// `timeUnit`: a [TimeUnit], the value of `time.unit`, `time.minUnit` and
  /// `time.round`.
  static const int timeUnit = 2304;

  /// `chartPosition`: a [ChartPosition], the `position` of the legend, the
  /// title and the subtitle.
  static const int chartPosition = 2432;

  /// `layoutPosition`: a [LayoutPosition], the `position` of a scale.
  static const int layoutPosition = 2560;

  /// `textAlign`: a Flutter [TextAlign], the `textAlign` of the legend labels
  /// and the `titleAlign`, `bodyAlign` and `footerAlign` of the tooltip.
  static const int textAlign = 2688;

  /// `steppedLine`: a [SteppedLine], the keyword form of `stepped`.
  static const int steppedLine = 2816;

  /// `borderSkippedEdge`: a [BorderSkippedEdge], the keyword form of
  /// `borderSkipped`.
  static const int borderSkippedEdge = 2944;

  /// `cubicInterpolationMode`: a `CubicInterpolationMode`, the value of the
  /// line `cubicInterpolationMode`.
  static const int cubicInterpolationMode = 3072;

  /// `pointStyle`: a `PointStyle`, the value of `pointStyle`.
  static const int pointStyle = 3200;

  /// `fillTarget`: a `FillTarget` (a `FillBoundary` or a `RelativeFill`),
  /// the text forms of `fill`.
  static const int fillTarget = 3328;

  /// `radiusLength`: a `RadiusLength`, the doughnut `cutout` and `radius`.
  static const int radiusLength = 3456;

  /// `graceLength`: a `GraceLength`, the scale `grace`.
  static const int graceLength = 3584;

  /// `scaleAxis`: a `ScaleAxis`, the `axis` of a scale.
  static const int scaleAxis = 3712;

  /// `cartesianAxis`: a `CartesianAxis` (`XAxis` or `YAxis`), the
  /// `indexAxis` of a chart and of a cartesian dataset.
  static const int cartesianAxis = 3840;

  /// `radialAxis`: an `RAxis`, the `indexAxis` of a radial dataset.
  static const int radialAxis = 3968;

  /// `textStyle`: a Flutter `TextStyle`, the value of a font option.
  static const int textStyle = 4096;

  /// `locale`: a Flutter `Locale`, the chart option `locale` (Chart.js ADR
  /// 0119).
  static const int locale = 4224;

  /// `numberFormat`: a `NumberFormat` of package:intl, the tick option
  /// `format` (Chart.js ADR 0119).
  static const int numberFormat = 4352;

  /// `edgeInsets`: a Flutter [EdgeInsets], the value of a padding option.
  static const int edgeInsets = 4480;

  /// `textDirection`: the native direction of legend and tooltip text.
  static const int textDirection = 4608;

  /// Native tooltip callbacks.
  static const int tooltipCallbacks = 4736;

  /// The bits of the index of a typed atom: the native types of options
  /// that were names in Chart.js ([classifyTyped]).
  static const int typed = 0x7FFFFF80;
}

/// The cell of [raw] for the special values, or Dart `null` for a plain
/// value: `undefined`, `null`, a function, an array and an object.
Opt<T>? _special<T>(Object? raw) {
  if (raw == null) return optNull;
  if (raw is Undefined) return optUndefined;
  if (jsIsFunction(raw)) return OptFunction<T>(raw);
  if (raw is List<Object?>) return OptList<T>(raw);
  if (raw is Map<String, Object?> ||
      raw is OptionObject ||
      (raw is JsObjectFace && raw is! TypedDataItem)) {
    return OptScope<T>(raw);
  }
  return null;
}

/// A typed option object that a cell can hold as a nested scope: the base
/// of the typed scope classes (`option_scope.dart`).
abstract interface class OptionObject {}

/// The cell of [raw] for a key of the shape `number`.
Opt<double> classifyNumber(Object? raw) =>
    _special<double>(raw) ??
    (raw is num ? OptValue<double>(raw.toDouble()) : OptForeign<double>(raw!));

/// The cell of [raw] for a key of the shape `bool`.
Opt<bool> classifyBool(Object? raw) =>
    _special<bool>(raw) ??
    (raw is bool ? OptValue<bool>(raw) : OptForeign<bool>(raw!));

/// The cell of [raw] for a key of the shape `string`.
Opt<String> classifyString(Object? raw) =>
    _special<String>(raw) ??
    (raw is String ? OptValue<String>(raw) : OptForeign<String>(raw!));

/// The cell of [raw] for a key whose shape is one typed atom: a native type
/// [T] of an option that was a name in Chart.js (a Flutter `Curve`, an enum
/// such as `StrokeCap`, or a class of the port such as `InteractionMode`).
/// A value of [T] is an [OptValue]. A name of Chart.js is not a [T]: it is
/// a foreign value, as each other value is.
Opt<T> classifyTyped<T extends Object>(Object? raw) =>
    _special<T>(raw) ?? (raw is T ? OptValue<T>(raw) : OptForeign<T>(raw!));

/// The cell of [raw] for a key of the shape `scope <Kind>`: an object is an
/// [OptScope], another plain value is foreign.
Opt<S> classifyScope<S>(Object? raw) => _special<S>(raw) ?? OptForeign<S>(raw!);

/// The cell of [raw] for a key whose shape is a union of the atoms of
/// [mask] ([ShapeBits]), or `any`. A JS number is a `double`. A typed atom
/// of the union takes a value of its type ([classifyTyped]).
Opt<Object> classifyUnion(Object? raw, int mask) {
  final special = _special<Object>(raw);
  if (special != null) return special;
  final value = raw!;
  if (mask & ShapeBits.any != 0) {
    return OptValue<Object>(value is num ? value.toDouble() : value);
  }
  return switch (value) {
    final num n when mask & ShapeBits.number != 0 => OptValue<Object>(
      n.toDouble(),
    ),
    bool() when mask & ShapeBits.boolean != 0 => OptValue<Object>(value),
    String() when mask & ShapeBits.string != 0 => OptValue<Object>(value),
    _ when _typedFits(value, mask & ShapeBits.typed) => OptValue<Object>(
      value,
    ),
    _ => OptForeign<Object>(value),
  };
}

/// Whether [value] is of the type of the typed atom [typedMask], the bits of
/// [ShapeBits.typed] of a shape (0 for no typed atom).
bool _typedFits(Object value, int typedMask) =>
    typedMask != 0 && classifyMask(value, typedMask) is OptValue;

/// The cell of [raw] for a key of the shape bits [mask] ([ShapeBits]): the
/// classification of [classifyNumber], [classifyBool], [classifyString],
/// [classifyTyped] or [classifyScope] for a shape of one atom, else
/// [classifyUnion].
Opt<Object?> classifyMask(Object? raw, int mask) => switch (mask) {
  ShapeBits.number => classifyNumber(raw),
  ShapeBits.boolean => classifyBool(raw),
  ShapeBits.string => classifyString(raw),
  ShapeBits.curve => classifyTyped<Curve>(raw),
  ShapeBits.interactionMode => classifyTyped<InteractionMode>(raw),
  ShapeBits.tooltipPositioner => classifyTyped<TooltipPositioner>(raw),
  ShapeBits.strokeCap => classifyTyped<StrokeCap>(raw),
  ShapeBits.strokeJoin => classifyTyped<StrokeJoin>(raw),
  ShapeBits.interactionAxis => classifyTyped<InteractionAxis>(raw),
  ShapeBits.decimationAlgorithm => classifyTyped<DecimationAlgorithm>(raw),
  ShapeBits.scaleBounds => classifyTyped<ScaleBounds>(raw),
  ShapeBits.tickSource => classifyTyped<TickSource>(raw),
  ShapeBits.tickAlign => classifyTyped<TickAlign>(raw),
  ShapeBits.tickCrossAlign => classifyTyped<TickCrossAlign>(raw),
  ShapeBits.chartAlign => classifyTyped<ChartAlign>(raw),
  ShapeBits.tooltipXAlign => classifyTyped<TooltipXAlign>(raw),
  ShapeBits.tooltipYAlign => classifyTyped<TooltipYAlign>(raw),
  ShapeBits.arcBorderAlign => classifyTyped<ArcBorderAlign>(raw),
  ShapeBits.arcSpacingMode => classifyTyped<ArcSpacingMode>(raw),
  ShapeBits.fillerDrawTime => classifyTyped<FillerDrawTime>(raw),
  ShapeBits.timeUnit => classifyTyped<TimeUnit>(raw),
  ShapeBits.chartPosition => classifyTyped<ChartPosition>(raw),
  ShapeBits.layoutPosition => classifyTyped<LayoutPosition>(raw),
  ShapeBits.tooltipCallbacks => classifyTyped<TooltipCallbacks>(raw),
  ShapeBits.textDirection => classifyTyped<TextDirection>(raw),
  ShapeBits.textAlign => classifyTyped<TextAlign>(raw),
  ShapeBits.steppedLine => classifyTyped<SteppedLine>(raw),
  ShapeBits.borderSkippedEdge => classifyTyped<BorderSkippedEdge>(raw),
  ShapeBits.cubicInterpolationMode => classifyTyped<CubicInterpolationMode>(
    raw,
  ),
  ShapeBits.pointStyle => classifyTyped<PointStyle>(raw),
  ShapeBits.fillTarget => classifyTyped<FillTarget>(raw),
  ShapeBits.radiusLength => classifyTyped<RadiusLength>(raw),
  ShapeBits.graceLength => classifyTyped<GraceLength>(raw),
  ShapeBits.scaleAxis => classifyTyped<ScaleAxis>(raw),
  ShapeBits.cartesianAxis => classifyTyped<CartesianAxis>(raw),
  ShapeBits.radialAxis => classifyTyped<RAxis>(raw),
  ShapeBits.edgeInsets => classifyTyped<EdgeInsets>(raw),
  ShapeBits.textStyle => classifyTyped<TextStyle>(raw),
  ShapeBits.locale => classifyTyped<Locale>(raw),
  ShapeBits.numberFormat => classifyTyped<NumberFormat>(raw),
  ShapeBits.scope => classifyScope<Object>(raw),
  _ => classifyUnion(raw, mask),
};
