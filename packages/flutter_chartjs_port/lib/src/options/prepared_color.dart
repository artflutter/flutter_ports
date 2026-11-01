// Original code, not ported from Chart.js: numerical colors for pure layers.

/// Built-in colors stay numerical in pure Dart. Flutter installs the native
/// codec at the chart/canvas boundary; user color inputs must be Flutter Color.
library;

import 'package:flutter_chartjs_port/src/js/js_number.dart'
    show jsNumberToString;
import 'package:meta/meta.dart' show immutable, internal;

/// Converts a Flutter Color to numerical channels without parsing text.
@internal
PreparedColor? Function(Object?)? nativeColorReader;

/// Allocation-free native solid-color type check installed by Flutter.
@internal
bool Function(Object?)? nativeColorCheck;

/// Constructs a Flutter Color from numerical channels.
@internal
Object Function(PreparedColor)? nativeColorWriter;

/// Numerical sRGB channels used by defaults, themes and color arithmetic.
@internal
@immutable
final class PreparedColor {
  /// Keeps numerical channels and, when supplied, the original native color.
  const PreparedColor(
    this.red,
    this.green,
    this.blue,
    this.alpha, [
    Object? paint,
  ]) : _paint = paint;

  /// Red byte.
  final int red;

  /// Green byte.
  final int green;

  /// Blue byte.
  final int blue;

  /// Alpha in [0, 1].
  final double alpha;

  final Object? _paint;

  /// The native color. A pure-Dart caller can retain this numerical value
  /// until a Flutter boundary installs the codec.
  Object get paint {
    if (_paint != null) return _paint;
    final write = nativeColorWriter;
    return write == null ? this : write(this);
  }

  @override
  bool operator ==(Object other) =>
      other is PreparedColor &&
      red == other.red &&
      green == other.green &&
      blue == other.blue &&
      alpha == other.alpha;

  @override
  int get hashCode => Object.hash(red, green, blue, alpha);

  /// Legacy formatting for test/reference code. Rendering never reads it.
  String get css => 'rgba($red, $green, $blue, ${jsNumberToString(alpha)})';
}

/// Requires a native solid color or an internal numerical color. No string
/// syntax, including names and hex values, is accepted.
@internal
PreparedColor requireSolidColor(Object? value) {
  if (value is PreparedColor) return value;
  if (value is! String) {
    final color = nativeColorReader?.call(value);
    if (color != null) return color;
  }
  throw ArgumentError.value(
    value,
    'color',
    'Expected Flutter Color; CSS color strings are unsupported',
  );
}

/// Whether a value is a numerical or native solid color.
@internal
bool isSolidColor(Object? value) =>
    value is PreparedColor || (nativeColorCheck?.call(value) ?? false);

/// Numerical equality for the built-in default palette detection.
@internal
bool sameSolidColor(Object? a, PreparedColor b) {
  final color = a is PreparedColor ? a : nativeColorReader?.call(a);
  if (color == null) return false;
  return color.red == b.red &&
      color.green == b.green &&
      color.blue == b.blue &&
      color.alpha == b.alpha;
}

/// Public Flutter reads expose Color values, never generated CSS text.
@internal
@pragma('vm:prefer-inline')
@pragma('dart2js:prefer-inline')
@pragma('wasm:prefer-inline')
Object? publicColorValue(Object? value) =>
    value is PreparedColor ? value.paint : value;
