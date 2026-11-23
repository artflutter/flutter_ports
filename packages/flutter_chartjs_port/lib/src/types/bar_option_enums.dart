// Original code, not ported from Chart.js: the set of the skipped bar edges.

/// The keywords of the bar option `borderSkipped` (row
/// `adapt-border-skipped-enum`), and the values of `barThickness` (row
/// `adapt-bar-thickness-class`).
///
/// The option holds a boolean or a value of [BorderSkippedEdge], also in a
/// raw config: `false` skips no border and `true` skips each border, as
/// upstream. The bar controller closes the set: `setBorderSkipped` gives
/// each value its edges. The name of each value is the keyword of Chart.js.
///
/// This library is a pure layer.
library;

import 'package:flutter_chartjs_port/chartjs_core.dart';
import 'package:meta/meta.dart' show immutable;

/// `borderSkipped` of a bar (index.d.ts:2158 `'start' | 'end' | 'left' |
/// 'right' | 'bottom' | 'top' | 'middle'`, with `boolean`): the edge of the
/// bar that draws no border.
enum BorderSkippedEdge() {
  /// `'start'`: the edge at the base of the bar, the default.
  start,

  /// `'end'`: the edge at the value of the bar.
  end,

  /// `'middle'`: the inner edges of a bar in a stack.
  middle,

  /// `'bottom'`: the bottom edge.
  bottom,

  /// `'left'`: the left edge.
  left,

  /// `'top'`: the top edge.
  top,

  /// `'right'`: the right edge.
  right;

  /// The value of [value], the value of the option `borderSkipped`, or Dart
  /// `null` for a value that is not a [BorderSkippedEdge] (a boolean among
  /// them). A keyword of Chart.js is not a value: a debug build stops on it.
  static BorderSkippedEdge? of(Object? value) {
    assert(
      value is! String,
      'The option borderSkipped takes a BorderSkippedEdge, not the name '
      '"$value".',
    );
    return value is BorderSkippedEdge ? value : null;
  }
}

/// `barThickness` of a bar (index.d.ts:124 `number | 'flex'`): the width of
/// each bar (row `adapt-bar-thickness-class`). Dart `null` is no value: the
/// width is the fraction `categoryPercentage` and `barPercentage` of the
/// category, the fit mode of upstream.
///
/// ```dart
/// BarDataset(
///   data: .values(values),
///   barThickness: const BarThickness.pixels(12),
/// ),
/// BarDataset(data: .values(values), barThickness: BarThickness.flex),
/// ```
@immutable
sealed class const BarThickness() {
  /// A fixed width of [value] pixels for each bar: `barThickness: 12`.
  const factory pixels(double value) = BarThicknessPixels;

  /// `'flex'`: each bar takes the room up to the bars next to it, for data
  /// with uneven gaps (controller.bar.js:89 `computeFlexCategoryTraits`).
  static const BarThickness flex = BarThicknessFlex();

  /// The value of [value], the value of the option `barThickness`, or Dart
  /// `null` for no value. Another value stops a debug build, and a release
  /// build gives `null`.
  static BarThickness? of(Object? value) {
    if (value is BarThickness) return value;
    assert(
      value == null || value is Undefined,
      'The option barThickness takes a BarThickness, not $value.',
    );
    return null;
  }
}

/// [BarThickness.pixels]: a fixed width of [value] pixels.
final class const BarThicknessPixels(
  /// The width of each bar in pixels.
  final double value,
) extends BarThickness {
  /// Creates the fixed width.
  this;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarThicknessPixels && value == other.value;

  @override
  int get hashCode => Object.hash(BarThicknessPixels, value);

  @override
  String toString() => 'BarThickness.pixels($value)';
}

/// [BarThickness.flex]: the width up to the bars next to each bar.
final class const BarThicknessFlex() extends BarThickness {
  /// Creates the flex width. [BarThickness.flex] is the one value.
  this;

  @override
  String toString() => 'BarThickness.flex';
}
