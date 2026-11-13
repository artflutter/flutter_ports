// Original code, not ported from Chart.js: the bitmap scale of a dense curve.

/// The capability of a context that tells a line element the size of a bitmap
/// pixel, for the merge of the cubic curves of a dense line
/// (`line_dense_curve.dart`, Chart.js ADR 0114).
///
/// A context without this interface (a recording context of a test, a context
/// of user code) gets the upstream commands.
abstract interface class DenseCurveCanvas() {
  /// The count of bitmap pixels of one unit of x under the current transform.
  ///
  /// Null when the context takes only the upstream geometry: a transform that
  /// is not axis aligned or not invertible, or a shadow.
  double? get denseCurveScale;
}
