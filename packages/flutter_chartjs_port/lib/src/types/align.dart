// Original code, not ported from Chart.js: the align enums of the options.

/// The align enums of the options: the place of a box along its side (row
/// `adapt-chart-align-enum`) and the place of the tooltip box beside its
/// caret (row `adapt-tooltip-align-enums`).
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
enum ChartAlign() {
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

/// index.d.ts:2655 `TooltipXAlignment` (`'left' | 'center' | 'right'`):
/// the place of the tooltip box beside its caret along x. The value of the
/// tooltip option `xAlign`, of `xAlign` of the tooltip model and of a
/// `TooltipPosition` of a positioner.
///
/// Upstream holds the keyword and tests it as text (plugin.tooltip.js:223-
/// 330, 397-460). The port holds this enum (row `adapt-tooltip-align-enums`).
/// The name of each value is the keyword. The tooltip code closes the set.
enum TooltipXAlign() {
  /// `'left'`: the box is at the right of the caret.
  left,

  /// `'center'`: the box is above or below the caret.
  center,

  /// `'right'`: the box is at the left of the caret.
  right;

  /// The value of [value], or Dart `null` for a value that is not a
  /// [TooltipXAlign]: the tooltip then finds the align, as upstream does
  /// for a falsy value. A keyword of Chart.js is not a value: a debug build
  /// stops on it.
  static TooltipXAlign? of(Object? value) {
    assert(
      value is! String,
      'The option xAlign takes a TooltipXAlign, not the name "$value".',
    );
    return value is TooltipXAlign ? value : null;
  }
}

/// index.d.ts:2656 `TooltipYAlignment` (`'top' | 'center' | 'bottom'`):
/// the place of the tooltip box beside its caret along y, as
/// [TooltipXAlign] along x.
enum TooltipYAlign() {
  /// `'top'`: the box is below the caret.
  top,

  /// `'center'`: the box is at the side of the caret.
  center,

  /// `'bottom'`: the box is above the caret.
  bottom;

  /// The value of [value], as [TooltipXAlign.of] gives it.
  static TooltipYAlign? of(Object? value) {
    assert(
      value is! String,
      'The option yAlign takes a TooltipYAlign, not the name "$value".',
    );
    return value is TooltipYAlign ? value : null;
  }
}
