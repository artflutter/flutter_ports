// Original code, not ported from Chart.js: native curves for upstream fixtures.

/// The option `easing` of the port takes a Flutter `Curve` only, and the
/// library has no easing names. Frozen upstream data give an easing as a key
/// of the upstream `effects`. This test-only adapter gives a curve with the
/// formula of that effect. Production charts do not import this module.
library;

import 'package:flutter/animation.dart' show Curve;
// Test-only access to the ported easing formulas.
// ignore: implementation_imports
import 'package:flutter_chartjs_port/src/helpers/helpers.easing.dart'
    show effects;

/// A curve with the formula of the upstream effect [effect], or of the
/// linear effect when `effects` has no such key, as
/// `effects[cfg.easing] || effects.linear` gives (core.animation.js:36).
final class EffectCurve extends Curve {
  /// The curve of the effect [effect].
  const EffectCurve(this.effect);

  /// The key of the upstream `effects`.
  final String effect;

  /// The effect at [t], also at 0 and 1: `Curve.transform` gives [t] there,
  /// and an effect can give -0.
  @override
  double transform(double t) => (effects[effect] ?? effects['linear']!)(t);

  @override
  String toString() => 'EffectCurve($effect)';
}

/// The value of `easing` of an upstream config as a value of the port: an
/// [EffectCurve] for a String, else [value] itself.
Object? nativeFixtureEasing(Object? value) =>
    value is String ? EffectCurve(value) : value;
