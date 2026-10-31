// Original code, not ported from Chart.js: the twin check of the typed API.

/// The check of a lowered Map against its raw twin (Chart.js ADR 0052,
/// section 11): the Map that the app writes for the same chart in the raw
/// form of the Chart.js docs.
///
/// The chart reads only the Maps, so equal Maps give equal charts. The
/// check compares:
/// - each object: the keys in the order of `jsObjectKeys`, and each value. An
///   object of the lowering is a typed scope (Chart.js ADR 0054 §7) or a
///   `<String, Object?>` Map that takes a write, because Chart.js writes
///   into the option objects;
/// - each List: the length and each item;
/// - a function of the twin: the lowered value is a function too. The
///   tests call the two functions apart;
/// - each other value, also a data point of the typed API: `==`. Thus the
///   number `2` of a raw twin equals the `2.0` of a typed `double`, as in
///   JavaScript.
///
/// A helper library of the typed tests, not a test file.
library;

import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart' show undefined;
import 'package:flutter_chartjs_port/src/types/data_item.dart'
    show TypedDataItem;
import 'package:flutter_test/flutter_test.dart';

/// Expects the lowered [actual] to be the raw twin [expected].
void expectTwin(Object? actual, Object? expected) =>
    _twin(actual, expected, r'$');

void _twin(Object? actual, Object? expected, String path) {
  if (expected is Map<String, Object?> ||
      (expected is JsObjectFace && expected is! TypedDataItem)) {
    expect(
      actual is Map<String, Object?> || actual is JsObjectFace,
      isTrue,
      reason: '$path is an object',
    );
    final map = actual!;
    _expectWritable(map, path);
    expect(jsObjectKeys(map), jsObjectKeys(expected), reason: '$path keys');
    for (final key in jsObjectKeys(expected)) {
      _twin(jsGet(map, key), jsGet(expected, key), '$path.$key');
    }
  } else if (expected is List<Object?>) {
    expect(actual, isA<List<Object?>>(), reason: path);
    final list = actual! as List<Object?>;
    expect(list, hasLength(expected.length), reason: path);
    for (var i = 0; i < expected.length; i++) {
      _twin(list[i], expected[i], '$path[$i]');
    }
  } else if (expected is Function) {
    expect(actual, isA<Function>(), reason: path);
  } else {
    expect(actual, expected, reason: path);
  }
}

/// Expects [map] to take a write of any value: a typed scope, or a
/// `<String, Object?>` Map that is not unmodifiable.
///
/// The probe writes the JS `undefined` (an `Undefined`, not a `String`):
/// a narrower Map throws its `TypeError`, an unmodifiable Map throws, and a
/// typed scope of the lowering (Chart.js ADR 0054 §7) keeps an own
/// `undefined` cell, which no option kind keeps in a foreign slot. Thus the
/// probe key adds no pair to the audit O2.
void _expectWritable(Object map, String path) {
  const probe = r'$twinProbe';
  expect(jsHasOwn(map, probe), isFalse, reason: path);
  expect(
    () => jsSet(map, probe, undefined),
    returnsNormally,
    reason: '$path takes a write',
  );
  jsDeleteKey(map, probe);
}
