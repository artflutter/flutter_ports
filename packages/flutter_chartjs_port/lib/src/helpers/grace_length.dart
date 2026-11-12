// Original code, not ported from Chart.js: the lengths of a scale grace.

/// The value of the scale option `grace` (row `adapt-length-objects`).
///
/// Upstream holds a number (data value units) or a text that ends with `%`
/// (a percent of half the data range), and `toDimension` (helpers.core.ts:91)
/// parses the text. In the port, the option holds a `GraceLength`, also in a
/// raw config: an object with the method `amountOf`. `PercentGrace` and
/// `ValueGrace` are the two forms of upstream. A new form is a new subclass,
/// from a bump or from a plugin; the scale code does not change.
///
/// This library is a pure layer.
library;

import 'package:meta/meta.dart' show immutable;

/// The room that a scale adds above and below its data: `grace`.
///
/// ```dart
/// // A percent of half the range, at least one value unit.
/// final class AtLeastOneGrace extends GraceLength {
///   const AtLeastOneGrace(this.percent);
///   final double percent;
///
///   @override
///   double amountOf(double halfRange) =>
///       math.max(percent / 100 * halfRange, 1);
/// }
/// ```
@immutable
abstract class GraceLength {
  /// A grace.
  const GraceLength();

  /// The grace in data value units for half the data range [halfRange]:
  /// upstream `toDimension(grace, (max - min) / 2)` (helpers.options.ts:188).
  double amountOf(double halfRange);

  /// The grace of [value], the value of the option, or Dart `null` for a
  /// value that is not a [GraceLength]. A text of Chart.js (`'5%'`) is not a
  /// grace: a debug build stops on it.
  static GraceLength? of(Object? value) {
    assert(
      value is! String,
      'The option grace takes a GraceLength, not the text "$value".',
    );
    return value is GraceLength ? value : null;
  }
}

/// A percent of half the data range: `PercentGrace(5)` is `'5%'` upstream.
final class PercentGrace extends GraceLength {
  /// The grace of [percent] percent of half the data range.
  const PercentGrace(this.percent);

  /// The percent.
  final double percent;

  @override
  double amountOf(double halfRange) => percent / 100 * halfRange;

  @override
  bool operator ==(Object other) =>
      other is PercentGrace && other.percent == percent;

  @override
  int get hashCode => percent.hashCode;

  @override
  String toString() => 'PercentGrace($percent)';
}

/// An amount in data value units: `ValueGrace(0.3)` is `0.3` upstream.
final class ValueGrace extends GraceLength {
  /// The grace of [amount] data value units.
  const ValueGrace(this.amount);

  /// The amount.
  final double amount;

  @override
  double amountOf(double halfRange) => amount;

  @override
  bool operator ==(Object other) =>
      other is ValueGrace && other.amount == amount;

  @override
  int get hashCode => amount.hashCode;

  @override
  String toString() => 'ValueGrace($amount)';
}
