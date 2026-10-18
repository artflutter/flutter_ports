// Original code, not ported from Chart.js: JS Math builtins with V8 semantics.

/// `Math` and `Number` builtins for ported code, with the results of the
/// reference engine of Chart.js ADR 0002 (porting-flow.md 2.3):
/// V8 13.6 in Node.js v24.12.0 on x64.
///
/// Ported code calls these instead of the `dart:math` and `num` members whose
/// results differ from JavaScript. Numbers are `double`, as in JavaScript.
///
/// The transcendental functions are pure-Dart ports of fdlibm 5.3, so the VM,
/// dart2js and dart2wasm give the same bits. V8 on x64 compiles fdlibm
/// without fused multiply-add, as these ports compute. V8 on arm64 contracts
/// to fused multiply-add, and Chrome 155 computes `Math.log`, `Math.log10`
/// and `Math.atan2` another way, so both differ from the reference in the
/// last bit for some inputs.
library;

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
  if (!x.isFinite) return 0;
  const twoTo32 = 4294967296.0;
  // remainder() is exact; the result has the sign of the truncated value.
  var int32 = x.truncateToDouble().remainder(twoTo32);
  if (int32 < 0) int32 += twoTo32;
  if (int32 >= 2147483648) int32 -= twoTo32;
  // ToInt32 never returns -0.
  return int32 + 0;
}

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
