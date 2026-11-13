# LegendHitBox — migration draft

```dart
import 'dart:ui' show Offset;

import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart'
    show isBetween;

class LegendHitBox {
  LegendHitBox.row({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required int row,
  }) : assert(row >= 0),
       row = row,
       col = null;

  LegendHitBox.col({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required int col,
  }) : assert(col >= 0),
       row = null,
       col = col;

  double left;
  double top;
  double width;
  double height;

  // Exactly one index is present. Membership stays fixed for this layout.
  final int? row;
  final int? col;

  double get right => left + width;
  double get bottom => top + height;
  Offset get center => Offset(left + width / 2, top + height / 2);

  // Preserve upstream inclusive bounds and the 1e-6 tolerance.
  // Reversed bounds retain isBetween semantics; NaN never hits.
  bool contains(double x, double y) =>
      isBetween(x, left, right) && isBetween(y, top, bottom);

  // Null geometry arguments retain their values. Supplying row or col
  // selects that membership; omitting both retains the current membership.
  LegendHitBox copyWith({
    double? left,
    double? top,
    double? width,
    double? height,
    int? row,
    int? col,
  }) {
    if (row != null && col != null) {
      throw ArgumentError('Supply only one of row and col.');
    }
    final targetRow = row ?? (col == null ? this.row : null);
    if (targetRow != null) {
      return LegendHitBox.row(
        left: left ?? this.left,
        top: top ?? this.top,
        width: width ?? this.width,
        height: height ?? this.height,
        row: targetRow,
      );
    }
    return LegendHitBox.col(
      left: left ?? this.left,
      top: top ?? this.top,
      width: width ?? this.width,
      height: height ?? this.height,
      col: col ?? this.col!,
    );
  }

  // A hit box is a complete layout result: other replaces its geometry
  // and membership. Neither input is mutated; null returns this.
  LegendHitBox merge(LegendHitBox? other) {
    if (other == null) return this;
    return copyWith(
      left: other.left,
      top: other.top,
      width: other.width,
      height: other.height,
      row: other.row,
      col: other.col,
    );
  }
}

/// Field comparison using the reference tests' numeric tolerance.
/// Identity-based `==` and `hashCode` remain unchanged.
extension LegendHitBoxX on LegendHitBox {
  /// Compares shared geometry and membership, excluding subclass-only fields.
  bool equalsTo(LegendHitBox other) =>
      _equalCoordinate(left, other.left) &&
      _equalCoordinate(top, other.top) &&
      _equalCoordinate(width, other.width) &&
      _equalCoordinate(height, other.height) &&
      row == other.row &&
      col == other.col;

  static bool _equalCoordinate(double actual, double expected) {
    if (expected.isNaN) return actual.isNaN;
    if (expected.isInfinite) return actual == expected;
    final tolerance = expected.abs() > 1e3 ? expected.abs() * 1e-12 : 1e-9;
    return (actual - expected).abs() <= tolerance;
  }
}
```

Place the public class in `lib/src/types/legend_hit_box.dart`. Both `Legend` and
`LegendElement` expose `List<LegendHitBox>`; remove `TypedLegendHitBox` and the
`TypedRecord` implementation. Row and column counters become integers.

Layout mutates geometry in place. Pointer handling calls `contains` after the existing
legend-area check; keyboard navigation reads the same boxes and their centers.
Keep hit order, RTL placement and object identity. Plugins can extend or implement
the class and override its getters and methods. Subclasses override `copyWith` to retain
their type and additional state, and `merge` when that state participates in merging.
The inherited `merge` dispatches through the overridden `copyWith`.

Tests compare native fields directly. No `Object?` fields, property bags, by-name
access, or item-to-Map adapters.

`LegendHitBoxX.equalsTo` lives beside the class. It compares the shared fields
with the existing reference-test numeric tolerance and leaves identity equality
and hashing unchanged. Unused extension code can be tree-shaken from release builds.
