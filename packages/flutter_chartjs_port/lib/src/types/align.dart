// Original code, not ported from Chart.js: the align of a box.

/// The place of a box along its side (row `adapt-chart-align-enum`).
///
/// This library is a pure layer.
library;

/// index.d.ts:1844 `Align` (`'start' | 'center' | 'end'`): the place of a
/// box along its side. The value of the option `align` of the legend, the
/// title, the subtitle and an axis title, and of `position` of the legend
/// title.
///
/// Upstream holds the keyword and tests it as text (`_alignStartEnd`,
/// `_toLeftRightCenter`, helpers.extras.ts:67-77). The port holds this enum,
/// also in a raw config. The name of each value is the keyword. The layout
/// code closes the set.
enum ChartAlign {
  /// `'start'`: the left or the top end.
  start,

  /// `'center'`: the middle.
  center,

  /// `'end'`: the right or the bottom end.
  end;

  /// The value of [value], the value of an option `align`, or Dart `null`
  /// for a value that is not a [ChartAlign]: the readers then take the
  /// middle, as upstream does for a value that is not `'start'` or
  /// `'end'`. A keyword of Chart.js is not a value: a debug build stops on
  /// it.
  static ChartAlign? of(Object? value) {
    assert(
      value is! String,
      'The option align takes a ChartAlign, not the name "$value".',
    );
    return value is ChartAlign ? value : null;
  }
}
