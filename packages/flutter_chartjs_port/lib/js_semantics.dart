// Original code, not ported from Chart.js: the JS runtime for add-on ports.
/// The JS runtime for the ports of Chart.js add-ons (Chart.js ADR 0132, ADR
/// 0009, item 4): the JavaScript semantics that ported add-on code needs
/// where a Dart form gives another result (Chart.js ADRs 0034 and 0146).
///
/// The library exports each library of `lib/src/js/` with each of its
/// names. Some examples:
///
/// - `jsObjectKeys`: the key order of `Object.keys`, with the array index
///   keys first.
/// - `jsSort`: the stable `Array.prototype.sort`, which reads only the sign
///   of the comparator result.
/// - `jsCall`: the call of a JavaScript function value with JavaScript
///   arity.
/// - `jsGet`: the property read `object[key]` of a Map, a typed object of
///   the port (`JsObjectFace`), a List or a String. An absent key gives
///   `undefined`.
/// - `Math.round` is `roundToDouble()` (Chart.js ADR 0146 §7). `Math.max`
///   and `Math.min` are `dart:math` `max` and `min` with `double` operands
///   (Chart.js ADR 0146 §4), and `Math.hypot(a, b)` is
///   `math.sqrt(a * a + b * b)` (Chart.js ADR 0146 §4).
/// - `jsToNumber`, `jsToString` and `jsTruthy`: the conversions `ToNumber`,
///   `ToString` and `ToBoolean`. `jsNumberToString`: the V8 text of a
///   number.
///
/// An app does not need this library. `chartjs.dart` and the app library do
/// not export it. When the shared package `js_semantics` of ADR 0008 exists,
/// this library exports that package.
library;

export 'package:flutter_chartjs_port/src/js/js_array.dart';
export 'package:flutter_chartjs_port/src/js/js_class.dart';
export 'package:flutter_chartjs_port/src/js/js_function.dart';
export 'package:flutter_chartjs_port/src/js/js_math.dart';
export 'package:flutter_chartjs_port/src/js/js_number.dart';
export 'package:flutter_chartjs_port/src/js/js_object.dart';
export 'package:flutter_chartjs_port/src/js/js_promise.dart';
export 'package:flutter_chartjs_port/src/js/js_undefined.dart';
export 'package:flutter_chartjs_port/src/js/js_webidl.dart';
