// Original code, not ported from Chart.js: the canvas values of option values.

/// The value that a canvas setter or method gets for an option value
/// (Chart.js ADR 0174).
///
/// Upstream assigns an option value to a canvas setter as it is, for example
/// `ctx.lineWidth = options.borderWidth` (element.point.ts:97). The canvas
/// interface of `canvas.dart` takes typed values and ignores Dart `null`.
/// Each function here gives the option value when it has the type of the
/// setter, and Dart `null` for an absent option (the `undefined` sentinel):
///
/// - [canvasStyle] for `fillStyle` and `strokeStyle`;
/// - [canvasNumber] for `lineWidth`, `lineDashOffset` and a stroke width;
/// - [canvasLineCap], [canvasLineJoin] and [canvasTextAlign] for the Flutter
///   enums `StrokeCap`, `StrokeJoin` and `TextAlign`;
/// - [canvasLineDash] for `setLineDash`.
///
/// No function applies the JavaScript `ToNumber`: a number option holds a
/// Dart `num`. A value of another type gives Dart `null` or NaN, which the
/// canvas ignores, as the DOM ignores the NaN of a value that is no number.
/// A width and a dash change pixels only (Chart.js ADR 0034).
///
/// This library is a framework-free core layer.
library;

import 'dart:ui' show StrokeCap, StrokeJoin, TextAlign;

import 'package:flutter_chartjs_port/src/js/js_undefined.dart';

/// The `fillStyle` or `strokeStyle` of the option value [value]
/// (element.point.ts:96-98, element.bar.js:191, :197, element.arc.ts:489-490,
/// element.line.js:18).
///
/// An absent option gives Dart `null`, which the canvas ignores. Another
/// value passes unchanged: the canvas takes a `Color` or a `ChartPaint`, and
/// it rejects another value at the setter.
Object? canvasStyle(Object? value) => value is Undefined ? null : value;

/// The `lineWidth`, `lineDashOffset` or stroke width of the option value
/// [value] (element.point.ts:97, element.arc.ts:328-334, element.line.js:15,
/// :17).
///
/// A `num` gives its `double`. Another value gives Dart `null`, which the
/// canvas ignores.
// DIVERGES(chartjs): adapt-canvas-option-values, no ToNumber.
double? canvasNumber(Object? value) => value is num ? value.toDouble() : null;

/// The `lineCap` of the option value [value] (element.line.js:13): the
/// [StrokeCap] itself, else Dart `null`. A keyword of Chart.js (`'round'`)
/// stops a debug build.
// DIVERGES(chartjs): adapt-flutter-stroke-enums, a Flutter enum.
StrokeCap? canvasLineCap(Object? value) {
  assert(
    value is! String,
    'The line cap takes a StrokeCap, not the name "$value".',
  );
  return value is StrokeCap ? value : null;
}

/// The `lineJoin` of the option value [value] (element.line.js:16): the
/// [StrokeJoin] itself, else Dart `null`. A keyword of Chart.js (`'bevel'`)
/// stops a debug build.
// DIVERGES(chartjs): adapt-flutter-stroke-enums, a Flutter enum.
StrokeJoin? canvasLineJoin(Object? value) {
  assert(
    value is! String,
    'The line join takes a StrokeJoin, not the name "$value".',
  );
  return value is StrokeJoin ? value : null;
}

/// The `textAlign` of the option value [value]: the [TextAlign] itself, else
/// Dart `null`. A keyword of Chart.js (`'center'`) stops a debug build.
// DIVERGES(chartjs): adapt-flutter-text-align, a Flutter enum.
TextAlign? canvasTextAlign(Object? value) {
  assert(
    value is! String,
    'The text align takes a TextAlign, not the name "$value".',
  );
  return value is TextAlign ? value : null;
}

/// The segments of `setLineDash` for the option value [value]
/// (element.line.js:14, element.arc.ts:331): a `List<double>` itself, or the
/// `double` of each `num` of another List.
///
/// A value that is not a List throws a [TypeError], as `setLineDash` throws
/// for a value that is not a sequence. An item that is not a `num` gives
/// NaN: the canvas then ignores the whole dash, as the DOM does.
// DIVERGES(chartjs): adapt-canvas-option-values, no ToNumber.
List<double> canvasLineDash(Object? value) => switch (value) {
  final List<double> segments => segments,
  final List<Object?> items => [
    for (final item in items)
      if (item is num) item.toDouble() else double.nan,
  ],
  _ => throw TypeError(),
};
