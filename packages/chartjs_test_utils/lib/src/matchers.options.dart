// Ported from chartjs-test-utils v0.4.0 src/matchers.options.js (MIT, chartjs-test-utils Contributors).

/// Port of `src/matchers.options.js`: the `toEqualOptions` matcher.
///
/// A Jasmine matcher `{compare(actual, expected)}` is a `package:matcher`
/// [Matcher] here. `expect(actual).toEqualOptions(expected)` is
/// `expect(actual, toEqualOptions(expected))`.
///
/// A JS object is a `Map<String, Object?>` and an array is a `List`
/// (Chart.js ADR 0006). A resolver of `helpers.config` is a Map too. The
/// property read `actual[key]` is [jsGet]: it runs the `get` trap of a
/// resolver, and it gives [undefined] for an absent key.
///
/// This library is a pure layer.
library;

// The harness reads the JS runtime of flutter_chartjs_port, which does not
// export lib/src.
// ignore_for_file: implementation_imports

import 'dart:convert';

import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:test/test.dart';

/// matchers.options.js:2 `isObject`: `Object.prototype.toString.call(value)
/// === '[object Object]'`.
///
/// A JS object is a `Map<String, Object?>` (Chart.js ADR 0006). A Dart
/// object of another class has no properties that [jsGet] can read. Thus it
/// is not an object here.
bool _isObject(Object? value) {
  return value is Map<String, Object?>;
}

/// matchers.options.js:6 `isArray`.
bool _isArray(Object? value) {
  return value is List<Object?>;
}

/// The strict equality `actual === expected` of JavaScript.
///
/// Numbers compare by value: `0 === -0` is true and `NaN === NaN` is false,
/// as Dart `==` on `num` gives. Strings compare by value. Every other value
/// compares by identity: `true`, `false`, `null` and [undefined] are single
/// instances, and objects, arrays and functions compare by reference.
bool strictEquals(Object? actual, Object? expected) {
  if (actual is num && expected is num) return actual == expected;
  if (actual is String && expected is String) return actual == expected;
  return identical(actual, expected);
}

/// matchers.options.js:10 `fmt`: a string in double quotes, an object or an
/// array as JSON, any other value as `${val}` ([jsToString]).
///
/// `JSON.stringify` drops a function or an [undefined] member of an object
/// and writes `null` for one in an array. Here both give `null`. The
/// message is only a report.
String _fmt(Object? val) {
  if (val is String) {
    return '"$val"';
  }
  if (_isArray(val) || _isObject(val)) {
    return jsonEncode(val, toEncodable: (_) => null);
  }
  return jsToString(val);
}

/// The result of [_compareArray] and [_compareObject]: `{pass, message}`.
typedef _Comparison = ({bool pass, String message});

/// matchers.options.js:20 `compareArray`.
_Comparison _compareArray(Object? actual, List<Object?> expected, String path) {
  var ret = true;
  final diff = <String>[];

  // JS replaces a non-array `actual` with `{}`. Its `length` and its
  // elements are `undefined`.
  final array = _isArray(actual) ? actual! as List<Object?> : null;
  if (array == null) {
    diff.add('$path: Expected ${_fmt(actual)} to be an array');
    ret = false;
  }

  final length = array == null ? undefined : array.length.toDouble();
  if (!strictEquals(length, expected.length)) {
    diff.add(
      '$path.length: Expected ${jsToString(length)} to equal '
      '${jsToString(expected.length)}',
    );
    ret = false;
  }
  for (var i = 0; i < expected.length; i++) {
    final act = array != null && i < array.length ? array[i] : undefined;
    final exp = expected[i];
    final cmp = _compareOption(act, exp, '$path[$i]');
    if (cmp.message != null) {
      if (!cmp.pass) {
        diff.add(cmp.message!);
        ret = false;
      }
    } else if (!cmp.pass) {
      diff.add('$path[$i]: Expected ${_fmt(act)} to equal ${_fmt(exp)}');
      ret = false;
    }
  }
  return (pass: ret, message: diff.join('\n'));
}

/// matchers.options.js:54 `compareObject`.
_Comparison _compareObject(
  Object? actual,
  Map<String, Object?> expected, [
  String path = '',
]) {
  var ret = true;
  final diff = <String>[];

  // JS replaces a non-object `actual` with `{}`. Its members are
  // `undefined`.
  var object = actual;
  if (!_isObject(object)) {
    diff.add('$path: Expected ${_fmt(actual)} to be an object');
    ret = false;
    object = <String, Object?>{};
  }

  var prefix = path;
  if (prefix != '') {
    prefix = '$prefix.';
  }

  // `for (const key in expected)` with the `hasOwnProperty` test: the keys
  // of `Object.keys` (jsObjectKeys). For a resolver of helpers.config, the
  // `getOwnPropertyDescriptor` trap gives only the keys of its first scope.
  for (final key in jsObjectKeys(expected)) {
    if (key.startsWith('_')) {
      continue;
    }
    final act = jsGet(object, key);
    final exp = expected[key];
    final cmp = _compareOption(act, exp, '$prefix$key');
    if (cmp.message != null) {
      if (!cmp.pass) {
        diff.add(cmp.message!);
        ret = false;
      }
    } else if (!cmp.pass) {
      diff.add('$prefix$key: Expected ${_fmt(act)} to equal ${_fmt(exp)}');
      ret = false;
    }
  }
  return (pass: ret, message: diff.join('\n'));
}

/// matchers.options.js:94 `compareOption`: the [_Comparison] of an object or
/// an array, or the `===` result of any other value with a null message.
({bool pass, String? message}) _compareOption(
  Object? actual,
  Object? expected,
  String path,
) {
  if (_isObject(expected)) {
    return _compareObject(actual, expected! as Map<String, Object?>, path);
  } else if (_isArray(expected)) {
    return _compareArray(actual, expected! as List<Object?>, path);
  }
  return (pass: strictEquals(actual, expected), message: null);
}

/// matchers.options.js:107 `toEqualOptions`: whether each key of [expected]
/// that does not start with `_` has the expected value in the actual value.
///
/// An object in [expected] compares its keys in the same way, an array
/// compares its length and its elements, and any other value compares with
/// `===` ([strictEquals]). Keys of the actual value that [expected] does not
/// name do not count.
Matcher toEqualOptions(Map<String, Object?> expected) =>
    _ToEqualOptions(expected);

final class _ToEqualOptions extends Matcher {
  const _ToEqualOptions(this.expected);

  final Map<String, Object?> expected;

  @override
  bool matches(Object? item, Map<Object?, Object?> matchState) {
    final result = _compareObject(item, expected);
    matchState['message'] = result.message;
    return result.pass;
  }

  @override
  Description describe(Description description) =>
      description.add('options equal to ').add(_fmt(expected));

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) => mismatchDescription.add(matchState['message'] as String? ?? '');
}
