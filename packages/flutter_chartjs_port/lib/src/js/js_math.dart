// Original code, not ported from Chart.js: JS Math builtins with V8 semantics.

/// `Math` and `Number` builtins for ported code, with the results of the
/// reference engine of Chart.js ADR 0045: V8 13.6 in Node.js v24.22.1 on
/// arm64.
///
/// Ported code calls these instead of the `dart:math` and `num` members whose
/// results differ from JavaScript in a way that changes behavior. Numbers are
/// `double`, as in JavaScript. `sin`, `cos`, `atan2` and `log` are `dart:math`
/// as it is (Chart.js ADR 0122): their last bit can differ from V8.
///
/// `Math.max` and `Math.min` have no port here. Ported code calls
/// `dart:math` `max` and `min` with `double` operands, which give the JS
/// results on every target (Chart.js ADR 0134). An `int` literal operand or
/// an arithmetic context makes the type argument `num`, which boxes on
/// dart2wasm: write `math.max<double>(x, 0)`.
///
/// `Math.hypot(a, b)` has no port here. Ported code writes
/// `math.sqrt(a * a + b * b)`: only the last bit can differ (Chart.js ADR
/// 0135).
///
/// `Math.pow` has no port here. Ported code calls `dart:math` `pow` with
/// double operands (Chart.js ADR 0045), also for `Math.pow(x, 2)` (Chart.js
/// ADR 0136). `dart:math` `pow` gives 1 for
/// `pow(1, NaN)` and `pow(+-1, +-Infinity)`, where JavaScript gives NaN. A
/// `Math.sin` or `Math.cos` call whose result reaches only the canvas or an
/// easing value calls `dart:math` with a `js-ok` comment (Chart.js ADR 0045).
library;

/// `Number.EPSILON`: 2^-52, the gap between 1 and the next double.
const double numberEpsilon = 2.220446049250313e-16;

/// `Math.round(x)`: the integer closest to [x], with halves rounded up
/// (toward +Infinity).
///
/// Unlike `double.roundToDouble`, which rounds halves away from zero:
/// `jsRound(-2.5)` is -2, `jsRound(0.49999999999999994)` is 0, and results
/// in [-0.5, 0) are -0. NaN and the infinities return themselves.
double jsRound(double x) {
  final floor = x.floorToDouble();
  // x - floor is exact for every finite x.
  final rounded = x - floor >= 0.5 ? floor + 1 : floor;
  // In a double context, -0 is -0.0.
  if (rounded == 0 && x.isNegative) return -0;
  return rounded;
}

/// `x | 0`: ECMAScript ToInt32([x]), as a double.
///
/// NaN and the infinities give 0. Other values are truncated toward zero
/// and wrapped modulo 2^32 into [-2^31, 2^31).
double jsToInt32(double x) {
  // A value in (-2^31 - 1, 2^31) truncates to an int32: no wrap is needed.
  // NaN fails both tests. `+ 0` makes the -0 of (-1, 0) +0.
  if (x > -2147483649.0 && x < 2147483648.0) return x.truncateToDouble() + 0;
  if (!x.isFinite) return 0;
  const twoTo32 = 4294967296.0;
  // remainder() is exact; the result has the sign of the truncated value.
  var int32 = x.truncateToDouble().remainder(twoTo32);
  if (int32 < 0) int32 += twoTo32;
  if (int32 >= 2147483648) int32 -= twoTo32;
  // ToInt32 never returns -0.
  return int32 + 0;
}
