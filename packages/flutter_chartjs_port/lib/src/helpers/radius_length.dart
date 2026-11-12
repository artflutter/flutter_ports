// Original code, not ported from Chart.js: the lengths of a doughnut radius.

/// The value of the doughnut and pie options `cutout` and `radius` (row
/// `adapt-length-objects`).
///
/// Upstream holds a number (pixels) or a text that ends with `%` (a percent
/// of the whole), and `toPercentage` and `toDimension` (helpers.core.ts:86,
/// :91) parse the text. In the port, the option holds a `RadiusLength`,
/// also in a raw config: an object with the methods `pixelsOf` and
/// `fractionOf`. `PercentRadius` and `PixelRadius` are the two forms of
/// upstream. A new form is a new subclass, from a bump or from a plugin; the
/// doughnut code does not change.
///
/// This library is a pure layer.
library;

import 'package:meta/meta.dart' show immutable;

/// A length of a doughnut or a pie: `cutout` and `radius`.
///
/// ```dart
/// // The smaller of a percent and a number of pixels.
/// final class MinRadius extends RadiusLength {
///   const MinRadius(this.a, this.b);
///   final RadiusLength a;
///   final RadiusLength b;
///
///   @override
///   double pixelsOf(double whole) =>
///       math.min(a.pixelsOf(whole), b.pixelsOf(whole));
///
///   @override
///   double fractionOf(double whole) => pixelsOf(whole) / whole;
/// }
/// ```
@immutable
abstract class RadiusLength {
  /// A length.
  const RadiusLength();

  /// The length in pixels for the whole [whole] in pixels: upstream
  /// `toDimension(value, whole)` (the `radius` of controller.doughnut.js:229).
  double pixelsOf(double whole);

  /// The length as a part of the whole [whole] in pixels: upstream
  /// `toPercentage(value, whole)` (the `cutout` of controller.doughnut.js:218).
  double fractionOf(double whole);

  /// The length of [value], the value of the option, or Dart `null` for a
  /// value that is not a [RadiusLength]. A text of Chart.js (`'50%'`) is not
  /// a length: a debug build stops on it.
  static RadiusLength? of(Object? value) {
    assert(
      value is! String,
      'The options cutout and radius take a RadiusLength, not the text '
      '"$value".',
    );
    return value is RadiusLength ? value : null;
  }
}

/// A percent of the whole: `PercentRadius(50)` is `'50%'` upstream.
final class PercentRadius extends RadiusLength {
  /// The length of [percent] percent of the whole.
  const PercentRadius(this.percent);

  /// The percent.
  final double percent;

  @override
  double pixelsOf(double whole) => percent / 100 * whole;

  @override
  double fractionOf(double whole) => percent / 100;

  @override
  bool operator ==(Object other) =>
      other is PercentRadius && other.percent == percent;

  @override
  int get hashCode => percent.hashCode;

  @override
  String toString() => 'PercentRadius($percent)';
}

/// A number of pixels: `PixelRadius(150)` is `150` upstream.
final class PixelRadius extends RadiusLength {
  /// The length of [pixels] pixels.
  const PixelRadius(this.pixels);

  /// The pixels.
  final double pixels;

  @override
  double pixelsOf(double whole) => pixels;

  @override
  double fractionOf(double whole) => pixels / whole;

  @override
  bool operator ==(Object other) =>
      other is PixelRadius && other.pixels == pixels;

  @override
  int get hashCode => pixels.hashCode;

  @override
  String toString() => 'PixelRadius($pixels)';
}
