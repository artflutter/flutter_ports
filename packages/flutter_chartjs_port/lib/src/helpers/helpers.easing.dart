// Ported from Chart.js v4.6.1 src/helpers/helpers.easing.ts (MIT, Chart.js Contributors).
// Upstream reassigns the parameter t in many effects, as in (t /= 0.5) < 1.
// The port keeps these assignments, so the floating-point steps stay the same.
// ignore_for_file: parameter_assignments

/// Port of `src/helpers/helpers.easing.ts`.
///
/// Easing functions adapted from Robert Penner's easing equations.
library;

import 'dart:math' as math;

import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart'
    show halfPi, pi, tau;

/// helpers.easing.ts:3 `atEdge`.
bool _atEdge(double t) => t == 0 || t == 1;

/// helpers.easing.ts:4 `elasticIn`.
double _elasticIn(double t, double s, double p) =>
    // DIVERGES(chartjs): js-semantics-dart-math, dart:math sin and pow.
    // js-ok: pow with doubles, sin display only (Chart.js ADR 0045).
    -(math.pow(2.0, 10 * (t -= 1)) * math.sin((t - s) * tau / p));

/// helpers.easing.ts:5 `elasticOut`.
double _elasticOut(double t, double s, double p) =>
    // DIVERGES(chartjs): js-semantics-dart-math, dart:math sin and pow.
    // js-ok: pow with doubles, sin display only (Chart.js ADR 0045).
    math.pow(2.0, -10 * t) * math.sin((t - s) * tau / p) + 1;

/// helpers.easing.ts:12 `effects`.
///
/// Easing functions adapted from Robert Penner's easing equations.
/// @namespace Chart.helpers.easing.effects
/// @see http://www.robertpenner.com/easing/
///
/// A JavaScript object literal keeps its keys in insertion order. The Dart map
/// literal is a `LinkedHashMap`, which keeps the same order. Ported code
/// enumerates the keys with `jsObjectKeys`. The map can change, as the
/// JavaScript object can: `as const` is a TypeScript type only.
final Map<String, double Function(double t)> effects = {
  'linear': (t) => t,

  'easeInQuad': (t) => t * t,

  'easeOutQuad': (t) => -t * (t - 2),

  'easeInOutQuad': (t) =>
      ((t /= 0.5) < 1) ? 0.5 * t * t : -0.5 * ((--t) * (t - 2) - 1),

  'easeInCubic': (t) => t * t * t,

  'easeOutCubic': (t) => (t -= 1) * t * t + 1,

  'easeInOutCubic': (t) =>
      ((t /= 0.5) < 1) ? 0.5 * t * t * t : 0.5 * ((t -= 2) * t * t + 2),

  'easeInQuart': (t) => t * t * t * t,

  'easeOutQuart': (t) => -((t -= 1) * t * t * t - 1),

  'easeInOutQuart': (t) => ((t /= 0.5) < 1)
      ? 0.5 * t * t * t * t
      : -0.5 * ((t -= 2) * t * t * t - 2),

  'easeInQuint': (t) => t * t * t * t * t,

  'easeOutQuint': (t) => (t -= 1) * t * t * t * t + 1,

  'easeInOutQuint': (t) => ((t /= 0.5) < 1)
      ? 0.5 * t * t * t * t * t
      : 0.5 * ((t -= 2) * t * t * t * t + 2),

  // DIVERGES(chartjs): js-semantics-dart-math, dart:math cos.
  // js-ok: display only (Chart.js ADR 0045)
  'easeInSine': (t) => -math.cos(t * halfPi) + 1,

  // DIVERGES(chartjs): js-semantics-dart-math, dart:math sin.
  // js-ok: display only (Chart.js ADR 0045)
  'easeOutSine': (t) => math.sin(t * halfPi),

  // DIVERGES(chartjs): js-semantics-dart-math, dart:math cos.
  // js-ok: display only (Chart.js ADR 0045)
  'easeInOutSine': (t) => -0.5 * (math.cos(pi * t) - 1),

  // DIVERGES(chartjs): js-semantics-dart-math, dart:math pow.
  'easeInExpo': (t) => (t == 0)
      ? 0
      // js-ok: double operands, dart:math pow (Chart.js ADR 0045).
      : math.pow(2.0, 10 * (t - 1)).toDouble(),

  // DIVERGES(chartjs): js-semantics-dart-math, dart:math pow.
  'easeOutExpo': (t) => (t == 1)
      ? 1
      // js-ok: double operands, dart:math pow (Chart.js ADR 0045).
      : -math.pow(2.0, -10 * t) + 1,

  // DIVERGES(chartjs): js-semantics-dart-math, dart:math pow.
  'easeInOutExpo': (t) => _atEdge(t)
      ? t
      : t < 0.5
      // js-ok: double operands, dart:math pow (Chart.js ADR 0045).
      ? 0.5 * math.pow(2.0, 10 * (t * 2 - 1))
      // js-ok: double operands, dart:math pow (Chart.js ADR 0045).
      : 0.5 * (-math.pow(2.0, -10 * (t * 2 - 1)) + 2),

  'easeInCirc': (t) => (t >= 1) ? t : -(math.sqrt(1 - t * t) - 1),

  'easeOutCirc': (t) => math.sqrt(1 - (t -= 1) * t),

  'easeInOutCirc': (t) => ((t /= 0.5) < 1)
      ? -0.5 * (math.sqrt(1 - t * t) - 1)
      : 0.5 * (math.sqrt(1 - (t -= 2) * t) + 1),

  'easeInElastic': (t) => _atEdge(t) ? t : _elasticIn(t, 0.075, 0.3),

  'easeOutElastic': (t) => _atEdge(t) ? t : _elasticOut(t, 0.075, 0.3),

  'easeInOutElastic': (t) {
    const s = 0.1125;
    const p = 0.45;
    return _atEdge(t)
        ? t
        : t < 0.5
        ? 0.5 * _elasticIn(t * 2, s, p)
        : 0.5 + 0.5 * _elasticOut(t * 2 - 1, s, p);
  },

  'easeInBack': (t) {
    const s = 1.70158;
    return t * t * ((s + 1) * t - s);
  },

  'easeOutBack': (t) {
    const s = 1.70158;
    return (t -= 1) * t * ((s + 1) * t + s) + 1;
  },

  'easeInOutBack': (t) {
    var s = 1.70158;
    if ((t /= 0.5) < 1) {
      return 0.5 * (t * t * (((s *= 1.525) + 1) * t - s));
    }
    return 0.5 * ((t -= 2) * t * (((s *= 1.525) + 1) * t + s) + 2);
  },

  // Upstream reads effects.easeOutBounce when the effect runs.
  'easeInBounce': (t) => 1 - effects['easeOutBounce']!(1 - t),

  'easeOutBounce': (t) {
    const m = 7.5625;
    const d = 2.75;
    if (t < (1 / d)) {
      return m * t * t;
    }
    if (t < (2 / d)) {
      return m * (t -= 1.5 / d) * t + 0.75;
    }
    if (t < (2.5 / d)) {
      return m * (t -= 2.25 / d) * t + 0.9375;
    }
    return m * (t -= 2.625 / d) * t + 0.984375;
  },

  'easeInOutBounce': (t) => (t < 0.5)
      ? effects['easeInBounce']!(t * 2) * 0.5
      : effects['easeOutBounce']!(t * 2 - 1) * 0.5 + 0.5,
};

/// helpers.easing.ts:122 `EasingFunction`: `keyof typeof effects`.
///
/// TypeScript gives the union of the key names of [effects]. Dart has no
/// type of string literals. Thus the type is [String].
typedef EasingFunction = String;

/// helpers.easing.ts:124 `export default effects`.
///
/// `src/helpers/index.ts:8` exports the default export as `easingEffects`.
/// Dart has no default export and no rename in `export`. Thus this file gives
/// the name. It is the same map as [effects].
final Map<String, double Function(double t)> easingEffects = effects;
