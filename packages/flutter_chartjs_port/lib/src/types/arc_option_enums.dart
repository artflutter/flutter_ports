// Original code, not ported from Chart.js: the closed sets of arc options.

/// The arc options whose value is one of a closed set of keywords in
/// Chart.js (row `adapt-arc-option-enums`): `borderAlign` and `spacingMode`.
///
/// Each option holds a value of its enum, also in a raw config. The arc code
/// reads the set. The name of each value is the keyword of Chart.js.
///
/// This library is a pure layer.
library;

/// `borderAlign` of an arc (index.d.ts:1892 `'center' | 'inner'`): where
/// the border of an arc lies.
enum ArcBorderAlign() {
  /// `'center'`: the border lies on the edge of the arc, half inside.
  center,

  /// `'inner'`: the border lies inside the arc, and the arcs do not
  /// overlap.
  inner;

  /// The value of [value], the value of an option `borderAlign`, or Dart
  /// `null` for a value that is not an [ArcBorderAlign]: the arc then draws
  /// as `center`, as upstream does for a value that is not `'inner'`. A
  /// keyword of Chart.js is not a value: a debug build stops on it.
  static ArcBorderAlign? of(Object? value) {
    assert(
      value is! String,
      'The option borderAlign takes an ArcBorderAlign, not the name "$value".',
    );
    return value is ArcBorderAlign ? value : null;
  }
}

/// `spacingMode` of an arc (index.d.ts:1880 `ArcSpacingMode`, `'angular' |
/// 'proportional' | 'parallel'`): the geometry of the space between two
/// arcs.
enum ArcSpacingMode() {
  /// `'angular'`: the same angle at each radius.
  angular,

  /// `'proportional'`: an angle that grows with the radius.
  proportional,

  /// `'parallel'`: edges that stay parallel.
  parallel;

  /// The value of [value], the value of an option `spacingMode`, or Dart
  /// `null` for a value that is not an [ArcSpacingMode]: the arc then takes
  /// the `angular` geometry, as upstream does for a value that is not
  /// `'parallel'` or `'proportional'`. A keyword of Chart.js is not a value:
  /// a debug build stops on it.
  static ArcSpacingMode? of(Object? value) {
    assert(
      value is! String,
      'The option spacingMode takes an ArcSpacingMode, not the name '
      '"$value".',
    );
    return value is ArcSpacingMode ? value : null;
  }
}
