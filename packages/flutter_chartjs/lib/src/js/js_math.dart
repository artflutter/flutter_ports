// Original code, not ported from Chart.js: JS Math builtins with V8 semantics.

/// `Math` and `Number` builtins for ported code, with the results of the
/// reference engine of Chart.js ADR 0010: V8 13.6 in Node.js v24.12.0 on
/// x64.
///
/// Ported code calls these instead of the `dart:math` and `num` members whose
/// results differ from JavaScript. Numbers are `double`, as in JavaScript.
///
/// [jsLog10] and [jsAtan2] are pure-Dart ports of fdlibm 5.3, so the VM,
/// dart2js and dart2wasm give the same bits. V8 on x64 compiles fdlibm
/// without fused multiply-add, as these ports compute. V8 on arm64 contracts
/// to fused multiply-add, and Chrome 155 computes `Math.log`, `Math.log10`
/// and `Math.atan2` another way, so both differ from the reference in the
/// last bit for some inputs.
///
/// [jsMax] and [jsMin] take `double` operands, as `Math.max` and `Math.min`
/// do. Ported code calls `dart:math` `max` and `min` only for `int` operands
/// (Chart.js ADR 0010).
///
/// `Math.sin`, `Math.cos` and `Math.pow` have no port here. Ported code calls
/// `dart:math` `sin`, `cos` and `pow` with double operands (Chart.js ADR
/// 0010). Their last bit can differ from V8, and no chart behavior depends
/// on it. `dart:math` `pow` gives 1 for `pow(1, NaN)` and
/// `pow(+-1, +-Infinity)`, where JavaScript gives NaN.
library;

import 'dart:math' as math;

import 'package:flutter_chartjs/src/js/fdlibm_atan.dart';
import 'package:flutter_chartjs/src/js/fdlibm_log.dart';

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

/// Whether [jsMax] and [jsMin] compare their operands in their own code.
///
/// It is true on dart2wasm only. There, the generic `dart:math` `max` and
/// `min` box their `double` operands, and `limitValue` is about 15 times
/// slower than with the comparisons. On the VM and dart2js, the comparisons
/// are slower than `dart:math`, so [jsMax] and [jsMin] call `max` and `min`.
/// Tests read this value to confirm which code a test leg runs.
const bool jsMaxMinCompare = bool.fromEnvironment('dart.tool.dart2wasm');

/// `Math.max(a, b)` for two doubles: NaN if [a] or [b] is NaN, and +0 for
/// +0 and -0 in either order (Chart.js ADR 0010).
///
/// The results are the `dart:math` `max` results on every target (see
/// [jsMaxMinCompare]).
@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
double jsMax(double a, double b) {
  if (!jsMaxMinCompare) return math.max(a, b);
  if (a > b) return a;
  if (a < b) return b;
  // Equal values, or a NaN operand. +0 + -0 is +0, and -0 + -0 is -0.
  if (a == b) return a == 0 ? a + b : a;
  return double.nan;
}

/// `Math.min(a, b)` for two doubles: NaN if [a] or [b] is NaN, and -0 for
/// +0 and -0 in either order (Chart.js ADR 0010).
///
/// The results are the `dart:math` `min` results on every target (see
/// [jsMaxMinCompare]).
@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
double jsMin(double a, double b) {
  if (!jsMaxMinCompare) return math.min(a, b);
  if (a < b) return a;
  if (a > b) return b;
  // Equal values, or a NaN operand. Of +0 and -0, the result is -0.
  if (a == b) return a == 0 && b.isNegative ? b : a;
  return double.nan;
}

/// `Math.pow(x, 2)`: [x] times [x] (Chart.js ADR 0010).
///
/// The product is correctly rounded on every target. On the reference
/// engine, `Math.pow(x, 2)` gave the bits of `x * x` for all of 23 million
/// probe inputs (Chart.js ADR 0010, section 4). Thus the result is the JS
/// result: NaN for NaN, +0 for -0, +Infinity for -Infinity and for overflow.
/// On dart2wasm, `dart:math` `pow` costs about 8 times as much.
@pragma('vm:prefer-inline')
@pragma('dart2js:prefer-inline')
@pragma('wasm:prefer-inline')
double jsSquare(double x) => x * x;

/// `Math.log10(x)`: the fdlibm 5.3 base-10 logarithm, as V8 13.6 on x64
/// computes it.
///
/// `log(x) / ln10` differs from V8 in the last bit for many inputs, also at
/// powers of ten.
double jsLog10(double x) => ieee754Log10(x);

/// `Math.atan2(y, x)`: the fdlibm 5.3 angle of the point ([x], [y]), as V8
/// 13.6 on x64 computes it.
///
/// `dart:math` `atan2` calls the host C library on the VM and the browser's
/// `Math.atan2` on the web. Both differ from V8 in the last bit for about one
/// input in ten, and the VM differs from the web.
double jsAtan2(double y, double x) => ieee754Atan2(y, x);
