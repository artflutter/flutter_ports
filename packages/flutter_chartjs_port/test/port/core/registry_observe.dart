// Original code, not ported from Chart.js: observations of the registry tests.

/// The observations of the scenarios of `registry_reference.dart`, in the
/// format of tool/reference/registry_reference.mjs.
///
/// `core.typedRegistry_test.dart`, `core.registry_test.dart` and
/// `core.plugins_test.dart` build the scenarios of the generator and compare
/// [Observations.text] with the lines of the reference. This library is a
/// pure layer, so the pure test can import it.
library;

import 'dart:convert';

import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';

/// The observations of one scenario: one line `<label>: <value>` for each
/// [observe] call, and the labels of the known objects.
final class Observations {
  final Map<Object?, String> _labels = Map<Object?, String>.identity();
  final List<String> _lines = [];

  /// Gives [value] the label [name] and returns [value].
  T label<T extends Object>(T value, String name) {
    _labels[value] = name;
    return value;
  }

  /// The label of [value], or Dart `null`: `labels.get(value)` of the
  /// generator, which gives `undefined` there.
  String? labelOf(Object? value) => _labels[value];

  /// Adds the line `<what>: <value>`.
  void observe(String what, Object? value) => _lines.add('$what: $value');

  /// The lines, as the generator joins them.
  String get text => _lines.join('\n');

  /// `JSON.stringify(value, replacer)` with the replacer of the generator:
  /// a labelled object is `"<label>"`, [undefined] is `"<undefined>"`, and
  /// another function value is `"<fn>"`. A Map gives its keys in the
  /// `Object.keys` order ([jsObjectKeys]), also a resolver.
  String json(Object? value) {
    final label = value is String || value is num || value is bool
        ? null
        : _labels[value];
    if (label != null) return jsonEncode('<$label>');
    return switch (value) {
      null => 'null',
      Undefined() => '"<undefined>"',
      final bool b => b ? 'true' : 'false',
      final num n => n.isFinite ? jsNumberToString(n) : 'null',
      final String s => jsonEncode(s),
      _ when jsIsFunction(value) => '"<fn>"',
      final List<Object?> list => '[${list.map(json).join(',')}]',
      final Object map
          when map is Map<String, Object?> || map is JsObjectFace =>
        '{${jsObjectKeys(map).map((k) => _entry(map, k)).join(',')}}',
      _ => throw ArgumentError.value(value, 'value', 'has no JSON form'),
    };
  }

  /// The JSON member `"key":value` of [key] in [map], a Map or a typed
  /// object with a face (Chart.js ADR 0054 §5).
  String _entry(Object map, String key) =>
      '${jsonEncode(key)}:${json(jsGet(map, key))}';
}

/// The observation of the call [body], as the generator writes it: `ok`,
/// `TypeError` for a [TypeError], and `Error: <message>` for a [StateError],
/// the `new Error(message)` of the port. Another error gives its type name,
/// for example `ArgumentError`.
String error(void Function() body) {
  try {
    body();
    return 'ok';
  } on Object catch (e) {
    return switch (e) {
      TypeError() => 'TypeError',
      StateError(:final message) => 'Error: $message',
      _ => '${e.runtimeType}',
    };
  }
}

/// `key in object` as an observation, for a Map or a typed object with a
/// face [object]: `'true'` or `'false'`. Another value gives `'false'`.
String has(Object? object, Object? key) =>
    (object is Map || object is JsObjectFace) &&
        jsHasOwn(object, key is String ? key : jsToString(key))
    ? 'true'
    : 'false';

/// The value of the dot path [path] in [root]: `root.a.b` for `'a.b'`.
Object? at(Object? root, String path) {
  var node = root;
  for (final key in path.split('.')) {
    node = jsGet(node, key);
  }
  return node;
}
