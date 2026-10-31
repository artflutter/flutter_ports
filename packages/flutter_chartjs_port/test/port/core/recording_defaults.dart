// Original code, not ported from Chart.js: a Defaults fake for tests.
import 'dart:convert';

import 'package:flutter_chartjs_port/src/core/core.ticks.dart';
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart'
    show JsObjectFace, jsGet;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/index.dart';

/// A [Defaults] that records each call with its arguments, as
/// `[method, ...arguments]`. It changes nothing.
///
/// It stands in for the `core.defaults` singleton. Thus each test sees only
/// the calls of one `apply*Defaults` function. The tests compare
/// the recorded calls with the calls that the upstream functions make on a
/// recording object in Node.js v24.12.0 on x64.
final class RecordingDefaults implements Defaults {
  /// The recorded calls, in call order.
  final List<List<Object?>> calls = [];

  @override
  Object set(String scope, Object values) {
    calls.add(['set', scope, values]);
    return values;
  }

  @override
  Object describe(String scope, Object values) {
    calls.add(['describe', scope, values]);
    return values;
  }

  @override
  void route(String scope, String name, String targetScope, String targetName) {
    calls.add(['route', scope, name, targetScope, targetName]);
  }
}

/// `JSON.stringify(value, replacer)` with the replacer of the Node.js probe:
/// `undefined` is `"<undefined>"`, `Ticks.formatters.values` is
/// `"<values>"` and any other function is `"<fn>"`.
///
/// A number must be a `double` (Chart.js ADR 0045). An `int` gives
/// `"<int>"`, so the comparison with the probe fails.
String probeJson(Object? value) => switch (value) {
  null => 'null',
  Undefined() => '"<undefined>"',
  final bool b => b ? 'true' : 'false',
  final double d => jsNumberToString(d),
  num() => '"<int>"',
  final String s => jsonEncode(s),
  _ when identical(value, formatters['values']) => '"<values>"',
  Function() => '"<fn>"',
  final List<Object?> list => '[${list.map(probeJson).join(',')}]',
  final Object map when map is Map<String, Object?> || map is JsObjectFace =>
    '{${jsObjectKeys(map).map((key) => _entry(map, key)).join(',')}}',
  _ => throw ArgumentError.value(value, 'value', 'has no JSON form'),
};

/// The JSON member `"key":value` of [key] in [map], a Map or a typed scope
/// with a face (Chart.js ADR 0054 §5).
String _entry(Object map, String key) =>
    '${jsonEncode(key)}:${probeJson(jsGet(map, key))}';
