// Original code, not ported from Chart.js: the set of the skipped bar edges.

/// The keywords of the bar option `borderSkipped` (row
/// `adapt-border-skipped-enum`).
///
/// The option holds a boolean or a value of [BorderSkippedEdge], also in a
/// raw config: `false` skips no border and `true` skips each border, as
/// upstream. The bar controller closes the set: `setBorderSkipped` gives
/// each value its edges. The name of each value is the keyword of Chart.js.
///
/// This library is a pure layer.
library;

/// `borderSkipped` of a bar (index.d.ts:2158 `'start' | 'end' | 'left' |
/// 'right' | 'bottom' | 'top' | 'middle'`, with `boolean`): the edge of the
/// bar that draws no border.
enum BorderSkippedEdge {
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
