// Original code, not ported from Chart.js: the fill targets of the filler.

/// The text forms of the option `fill` (row `adapt-fill-target-objects`).
///
/// Upstream `fill` (`FillTarget` of index.d.ts:2300) is a number (the index
/// of a dataset), a boolean, an object `{value}`, a keyword (`'origin'`,
/// `'start'`, `'end'`, `'stack'`, `'shape'`) or a relative index as text
/// (`'+1'`, `'-2'`). `_decodeFill` (filler.options.js:46) parses the text.
/// In the port, a keyword is a [FillBoundary] and a relative index is a
/// [RelativeFill], also in a raw config. The number, the boolean and the
/// object stay. The filler plugin closes the set.
///
/// This library is a pure layer.
library;

import 'package:meta/meta.dart' show immutable;

/// A fill target that upstream gives as text: a [FillBoundary] or a
/// [RelativeFill].
sealed class FillTarget {
  /// The target of [value], the value of the option `fill`, or Dart `null`
  /// for another value (a number, a boolean, an object). A text of
  /// Chart.js is not a target: a debug build stops on it.
  static FillTarget? of(Object? value) {
    assert(
      value is! String,
      'The option fill takes a FillBoundary or a RelativeFill, not the text '
      '"$value".',
    );
    return value is FillTarget ? value : null;
  }
}

/// A fill to a boundary of the chart: the keywords of `fill`
/// (filler.options.js:73). The name of each value is the keyword.
enum FillBoundary implements FillTarget {
  /// `'origin'`: to the origin of the value axis. `fill: true` gives it.
  origin,

  /// `'start'`: to the start of the value axis.
  start,

  /// `'end'`: to the end of the value axis.
  end,

  /// `'stack'`: to the dataset below in the stack.
  stack,

  /// `'shape'`: the closed shape of the line, for a radar dataset.
  shape,
}

/// A fill to the dataset at [offset] from this dataset: the text `'+1'` for
/// 1 and `'-1'` for -1 upstream (filler.options.js:58-65).
@immutable
final class RelativeFill implements FillTarget {
  /// The fill to the dataset at [offset] from this one.
  const RelativeFill(this.offset);

  /// The offset of the target dataset from this dataset.
  final int offset;

  @override
  bool operator ==(Object other) =>
      other is RelativeFill && other.offset == offset;

  @override
  int get hashCode => offset.hashCode;

  @override
  String toString() => 'RelativeFill($offset)';
}
