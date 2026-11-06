// Original code, not ported from Chart.js: native arc sector capability.

/// Optional fused drawing for an ordinary arc: a wedge or a ring sector, with
/// no offset, spacing, rounded corner or border (Chart.js ADR 0097).
///
/// A context that does not implement it gets the Canvas 2D calls of
/// `ArcElement.draw`.
abstract interface class ArcSectorCanvas {
  /// Whether `translate(0, 0)` changes nothing on this context, so that the
  /// element may skip the call and the angles of the call. A recording context
  /// gives false: the call is an observation.
  bool get zeroTranslateIsNoOp;

  /// Fills the sector between [innerRadius] and [outerRadius], from
  /// [startAngle] to [endAngle], in user space, with [backgroundColor].
  ///
  /// [borderColor] is the value of the `strokeStyle` setter of the ordinary
  /// sequence: a value that the setter would reject declines the call.
  ///
  /// A false result changes no observable canvas state and requests the
  /// normal Canvas 2D sequence. A true result keeps the pixels, the styles,
  /// the transform, the notifications and the paint order of that sequence,
  /// and leaves its path as the current path.
  bool tryDrawArcSector({
    required double x,
    required double y,
    required double outerRadius,
    required double innerRadius,
    required double startAngle,
    required double endAngle,
    required Object? backgroundColor,
    required Object? borderColor,
  });
}
