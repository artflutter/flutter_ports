// Ported from d3-shape v3.2.0 src/curve/bundle.js (ISC, Mike Bostock).

/// Port of `src/curve/bundle.js` of d3-shape 3.2.0: [BundleCurve],
/// [CurveBundleFactory], and [curveBundle].
library;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:flutter_d3_shape_port/src/curve.dart';
import 'package:flutter_d3_shape_port/src/curve/basis.dart';

/// `curve/bundle.js:3` `Bundle`: straightened cubic basis spline with bundle
/// strength `beta`.
class BundleCurve(CanvasPath context, final double _beta) implements Curve {
  /// Creates a bundle curve writing into [context] with bundle strength
  /// [_beta].
  this;

  final BasisCurve _basis = BasisCurve(context);
  List<double>? _x;
  List<double>? _y;

  @override
  void areaStart() {}

  @override
  void areaEnd() {}

  @override
  void lineStart() {
    _x = <double>[];
    _y = <double>[];
    _basis.lineStart();
  }

  @override
  void lineEnd() {
    final x = _x!;
    final y = _y!;
    final j = x.length - 1;

    if (j > 0) {
      final x0 = x[0];
      final y0 = y[0];
      final dx = x[j] - x0;
      final dy = y[j] - y0;
      for (var i = 0; i <= j; ++i) {
        final t = i / j;
        _basis.point(
          _beta * x[i] + (1 - _beta) * (x0 + t * dx),
          _beta * y[i] + (1 - _beta) * (y0 + t * dy),
        );
      }
    }

    _x = _y = null;
    _basis.lineEnd();
  }

  @override
  void point(double x, double y) {
    _x!.add(x);
    _y!.add(y);
  }
}

/// `curve/bundle.js:45` callable bundle curve factory with configurable [beta].
// DIVERGES(d3-shape): adapt-shape-typed-api, const callable factory class.
final class const CurveBundleFactory._(final double _beta) {
  /// Creates a bundle curve factory with bundle strength [_beta].
  this;

  /// Creates a [Curve] for [context].
  Curve call(CanvasPath context) =>
      _beta == 1 ? BasisCurve(context) : BundleCurve(context, _beta);

  /// Returns a bundle curve factory with the specified [beta] in `[0, 1]`.
  CurveBundleFactory beta(double beta) => CurveBundleFactory._(beta);
}

/// `curve/bundle.js:45` default export: straightened cubic basis spline with
/// default `beta = 0.85`.
const CurveBundleFactory curveBundle = CurveBundleFactory._(0.85);
