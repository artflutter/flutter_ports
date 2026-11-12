// Original code, not ported from Chart.js: Canvas 2D setter WebIDL conversions.

/// The WebIDL conversions that the DOM applies to the argument of a Canvas 2D
/// setter or method, over the Dart values that stand for JavaScript values
/// (Chart.js ADR 0043, Chart.js ADR 0017 section 8).
///
/// Upstream assigns an option value to a canvas setter as it is, for example
/// `ctx.lineWidth = options.borderWidth` (element.point.ts:97). The DOM
/// converts the value with the WebIDL type of the setter, and it ignores a
/// value that is not valid for the setter. The canvas interface of
/// `lib/src/canvas/canvas.dart` takes typed values, and it ignores Dart
/// `null`. Thus ported code converts the option value with these functions
/// before the call:
/// - [canvasStyle] for `fillStyle` and `strokeStyle`;
/// - [canvasNumber] for an `unrestricted double`, for example `lineWidth`
///   and `lineDashOffset`;
/// - [canvasKeyword] for a `DOMString` keyword, for example `textAlign`;
/// - [canvasLineCap] and [canvasLineJoin] for `lineCap` and `lineJoin`,
///   whose values are the Flutter enums `StrokeCap` and `StrokeJoin` (row
///   `adapt-flutter-stroke-enums`);
/// - [canvasLineDash] for the `sequence<unrestricted double>` of
///   `setLineDash`.
///
/// The element classes of `lib/src/elements/` call them. The dataset
/// controllers and the plugins of later phases assign option values to the
/// same setters, and call them too.
///
/// The mock context of chartjs-test-utils records the value that a setter
/// gets. Thus it records Dart `null` where upstream records `undefined`. In
/// the recorded calls, Dart `null` stands for JS `undefined`, as for an
/// absent argument (`harness-mock-optional-args`).
///
/// This library is a pure layer. It imports neither `dart:ui` nor
/// `package:flutter`.
library;

import 'dart:ui' show StrokeCap, StrokeJoin, TextAlign;

import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';

/// The value that the canvas setter `fillStyle` or `strokeStyle` gets for
/// the option value [value], for example `ctx.fillStyle =
/// options.backgroundColor` (element.point.ts:96-98, element.bar.js:191,
/// :197, element.arc.ts:489-490, element.line.js:18).
///
/// The [undefined] sentinel of an absent option gives Dart `null`. The DOM
/// ignores `undefined`, which is not a color, and the canvas layer ignores
/// `null`. Another value passes as it is.
Object? canvasStyle(Object? value) => switch (value) {
  Undefined() => null,
  _ => value,
};

/// The value that the canvas setter `lineWidth` or `lineDashOffset` gets
/// for the option value [value] (element.point.ts:97,
/// element.arc.ts:328-334, element.line.js:15, :17).
///
/// The setters of the DOM take an `unrestricted double`. They apply
/// `ToNumber` and ignore NaN and the infinities. The [undefined] sentinel
/// of an absent option gives Dart `null`, which the canvas layer ignores,
/// as the DOM ignores the NaN of `undefined`. Another value gives its
/// `ToNumber` ([jsToNumber]). Thus JS `null` gives 0, as in the DOM.
double? canvasNumber(Object? value) =>
    value is Undefined ? null : jsToNumber(value);

/// The value that the canvas setter `lineCap` gets for the option value
/// [value] (element.line.js:13): the [StrokeCap] itself. Another value gives
/// Dart `null`, which the canvas layer ignores, as the DOM ignores a string
/// that is not a keyword. A keyword of Chart.js (`'round'`) is not a
/// [StrokeCap]: a debug build stops on it.
// DIVERGES(chartjs): adapt-flutter-stroke-enums, a Flutter enum.
StrokeCap? canvasLineCap(Object? value) {
  assert(
    value is! String,
    'The line cap takes a StrokeCap, not the name "$value".',
  );
  return value is StrokeCap ? value : null;
}

/// The value that the canvas setter `lineJoin` gets for the option value
/// [value] (element.arc.ts:332, :335, element.line.js:16): the [StrokeJoin]
/// itself, as [canvasLineCap] gives the cap.
// DIVERGES(chartjs): adapt-flutter-stroke-enums, a Flutter enum.
StrokeJoin? canvasLineJoin(Object? value) {
  assert(
    value is! String,
    'The line join takes a StrokeJoin, not the name "$value".',
  );
  return value is StrokeJoin ? value : null;
}

/// The value that the canvas setter `textAlign` gets for the option value
/// [value] (the `textAlign` of the legend labels and of a legend item, the
/// `titleAlign`, `bodyAlign` and `footerAlign` of the tooltip): the Flutter
/// [TextAlign] itself, as [canvasLineCap] gives the cap (row
/// `adapt-flutter-text-align`).
// DIVERGES(chartjs): adapt-flutter-text-align, a Flutter enum.
TextAlign? canvasTextAlign(Object? value) {
  assert(
    value is! String,
    'The text align takes a TextAlign, not the name "$value".',
  );
  return value is TextAlign ? value : null;
}

/// The value that a canvas setter with a keyword gets for the option value
/// [value].
///
/// The setters of the DOM take a `DOMString`. They apply `ToString` and
/// ignore a string that is not a keyword. A `String` gives itself. JS
/// `null` and the [undefined] sentinel give Dart `null`, which the canvas
/// layer ignores, as the DOM ignores `'null'` and `'undefined'`. Another
/// value gives its `ToString` ([jsToString]).
String? canvasKeyword(Object? value) => switch (value) {
  final String keyword => keyword,
  null || Undefined() => null,
  _ => jsToString(value),
};

/// The argument that `setLineDash` gets for the option value [value], a
/// `number[]` (element.arc.ts:327, element.line.js:14).
///
/// The DOM converts the argument to a `sequence<unrestricted double>`: it
/// applies `ToNumber` to each item. A `List<double>` gives itself. Another
/// `List` gives a new list of the `ToNumber` of each item. Throws a
/// [TypeError] for a value that is not a `List`, as the DOM throws for a
/// value that is not a sequence, for example `undefined`.
List<double> canvasLineDash(Object? value) => switch (value) {
  final List<double> segments => segments,
  final List<Object?> items => [for (final item in items) jsToNumber(item)],
  _ => throw TypeError(),
};
