// Original code, not ported from Chart.js: native legend hit boxes.

/// The shared legend hit-box contract.
library;

import 'dart:ui' show Offset;

import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart'
    show isBetween;

/// The native, extensible hit box of a legend entry.
///
/// Layout mutates geometry in place. Exactly one integer membership index is
/// present. Plugins may extend or implement this contract; consumers retain
/// identity and dispatch hit testing and centers through the public methods.
class LegendHitBox {
  /// Creates a hit box in a horizontal legend row.
  new row({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required int row,
  }) : assert(row >= 0, 'The row index must be nonnegative.'),
       row = row,
       col = null;

  /// Creates a hit box in a vertical legend column.
  new col({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required int col,
  }) : assert(col >= 0, 'The column index must be nonnegative.'),
       row = null,
       col = col;

  /// The left coordinate in chart pixels.
  double left;

  /// The top coordinate in chart pixels.
  double top;

  /// The box width in chart pixels.
  double width;

  /// The box height in chart pixels.
  double height;

  /// The horizontal row index, absent for a column box.
  final int? row;

  /// The vertical column index, absent for a row box.
  final int? col;

  /// The right coordinate computed from the current geometry.
  double get right => left + width;

  /// The bottom coordinate computed from the current geometry.
  double get bottom => top + height;

  /// The current center used by keyboard navigation.
  Offset get center => Offset(left + width / 2, top + height / 2);

  /// Preserve upstream inclusive bounds and the 1e-6 tolerance.
  /// Reversed bounds retain isBetween semantics; NaN never hits.
  bool contains(double x, double y) =>
      isBetween(x, left, right) && isBetween(y, top, bottom);

  /// Copies this box. Subclasses override to retain their type and state.
  ///
  /// Null geometry arguments retain their values. Supplying row or col
  /// selects that membership; omitting both retains the current membership.
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

  /// A hit box is a complete layout result: other replaces its geometry
  /// and membership. Neither input is mutated; null returns this.
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
