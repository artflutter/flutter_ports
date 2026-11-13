// Original code, not ported from Chart.js: the closed sets of scale options.

/// The scale options whose value is one of a closed set of keywords in
/// Chart.js (row `adapt-scale-option-enums`): `bounds`, `ticks.source`,
/// `ticks.align` and `ticks.crossAlign`.
///
/// Each option holds a value of its enum, also in a raw config. The scale
/// code reads the set, so a scale of an app or a plugin with another rule
/// reads its own option. The name of each value is the keyword of Chart.js.
///
/// This library is a pure layer.
library;

/// `bounds` of a cartesian scale (index.d.ts:3265 `'ticks' | 'data'`): what
/// the range of the scale keeps.
enum ScaleBounds() {
  /// `'data'`: the range keeps the data, and the ticks can lie inside it.
  data,

  /// `'ticks'`: the range keeps the ticks, and grows to the outer ticks.
  ticks;

  /// The value of [value], the value of an option `bounds`, or Dart `null`
  /// for a value that is not a [ScaleBounds]. A keyword of Chart.js is not
  /// a value: a debug build stops on it.
  static ScaleBounds? of(Object? value) {
    assert(
      value is! String,
      'The option bounds takes a ScaleBounds, not the name "$value".',
    );
    return value is ScaleBounds ? value : null;
  }
}

/// `ticks.source` of a time scale (index.d.ts:3476 `'labels' | 'auto' |
/// 'data'`): where the ticks come from.
enum TickSource() {
  /// `'auto'`: ticks that the scale makes from its unit and its size.
  auto,

  /// `'data'`: a tick at each time of the data.
  data,

  /// `'labels'`: a tick at each time of the labels.
  labels;

  /// The value of [value], the value of an option `ticks.source`, as
  /// [ScaleBounds.of] gives it.
  static TickSource? of(Object? value) {
    assert(
      value is! String,
      'The option ticks.source takes a TickSource, not the name "$value".',
    );
    return value is TickSource ? value : null;
  }
}

/// `ticks.align` of a cartesian scale (index.d.ts:3189 `Align | 'inner'`):
/// the place of a tick label along the axis.
enum TickAlign() {
  /// `'start'`: the label starts at its tick.
  start,

  /// `'center'`: the label is in the middle of its tick.
  center,

  /// `'end'`: the label ends at its tick.
  end,

  /// `'inner'`: the first and the last labels stay inside the axis.
  inner;

  /// The value of [value], the value of an option `ticks.align`, as
  /// [ScaleBounds.of] gives it.
  static TickAlign? of(Object? value) {
    assert(
      value is! String,
      'The option ticks.align takes a TickAlign, not the name "$value".',
    );
    return value is TickAlign ? value : null;
  }
}

/// `ticks.crossAlign` of a cartesian scale (index.d.ts:3206 `'near' |
/// 'center' | 'far'`): the place of a tick label across the axis.
enum TickCrossAlign() {
  /// `'near'`: the label is near the axis.
  near,

  /// `'center'`: the label is in the middle of the space of the labels.
  center,

  /// `'far'`: the label is far from the axis.
  far;

  /// The value of [value], the value of an option `ticks.crossAlign`, as
  /// [ScaleBounds.of] gives it.
  static TickCrossAlign? of(Object? value) {
    assert(
      value is! String,
      'The option ticks.crossAlign takes a TickCrossAlign, not the name '
      '"$value".',
    );
    return value is TickCrossAlign ? value : null;
  }
}
