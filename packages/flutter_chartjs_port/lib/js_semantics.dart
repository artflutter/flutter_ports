// Original code, not ported from Chart.js: the JS runtime for add-on ports.
/// The JS runtime for the ports of Chart.js add-ons (Chart.js ADR 0108, ADR
/// 0009, item 4): the JavaScript semantics that ported add-on code needs
/// where a Dart form gives another result (Chart.js ADRs 0034 and 0045).
///
/// - `jsObjectKeys`: the key order of `Object.keys`, with the array index
///   keys first.
/// - `jsCall`: the call of a JavaScript function value with JavaScript
///   arity.
/// - `jsGet`: the property read `object[key]` of a Map, a typed object of
///   the port (`JsObjectFace`), a List or a String. An absent key gives
///   `undefined`.
/// - `jsHypot`, `jsMax`, `jsMin` and `jsRound`: `Math.hypot`, `Math.max`,
///   `Math.min` and `Math.round` with the V8 results.
/// - `jsToNumber`, `jsToString` and `jsTruthy`: the conversions `ToNumber`,
///   `ToString` and `ToBoolean`. `jsNumberToString`: the V8 text of a
///   number.
///
/// An app does not need this library. `chartjs.dart` and the app library do
/// not export it. When the shared package `js_semantics` of ADR 0008 exists,
/// this library exports that package.
library;

export 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
export 'package:flutter_chartjs_port/src/js/js_function.dart' show jsCall;
export 'package:flutter_chartjs_port/src/js/js_math.dart'
    show jsHypot, jsMax, jsMin, jsRound;
export 'package:flutter_chartjs_port/src/js/js_number.dart'
    show jsNumberToString, jsToNumber, jsToString, jsTruthy;
export 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
