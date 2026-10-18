// Original code, not ported from Chart.js: tests of lib/src/js/js_object.dart.
import 'dart:collection';

import 'package:flutter_chartjs/src/js/js_array.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:test/test.dart';

// The expected values come from Node.js v24.12.0: obj[key] for each input.

/// A Map that answers `operator []` for a key that it does not contain, as
/// an object with an inherited property.
final class _Inheriting extends MapBase<String, Object?> {
  @override
  Object? operator [](Object? key) => key == 'inherited' ? 'p' : null;

  @override
  void operator []=(String key, Object? value) {}

  @override
  Iterable<String> get keys => const [];

  @override
  Object? remove(Object? key) => null;

  @override
  void clear() {}
}

/// A proxy whose `get` trap gives Dart `null` for every key and whose `has`
/// trap knows no key.
final class _NullProxy extends MapBase<String, Object?>
    implements JsProxyObject {
  @override
  Object? operator [](Object? key) => null;

  @override
  void operator []=(String key, Object? value) {}

  @override
  Iterable<String> get keys => const [];

  @override
  List<String> objectKeys() => const [];

  @override
  Object? remove(Object? key) => null;

  @override
  void clear() {}
}

void main() {
  group('jsGet', () {
    test('reads the own keys of a Map', () {
      final object = <String, Object?>{'a': 1, 'n': null, 'u': undefined};
      expect(jsGet(object, 'a'), 1);
      // {n: null}.n is null. {u: undefined}.u and {}.x are undefined.
      expect(jsGet(object, 'n'), isNull);
      expect(jsGet(object, 'u'), same(undefined));
      expect(jsGet(object, 'x'), same(undefined));
    });

    test('converts a key that is not a string', () {
      // ({1: 'a', true: 'b'})[1] is 'a', and [true] is 'b'.
      final object = <String, Object?>{'1': 'a', 'true': 'b'};
      expect(jsGet(object, 1.0), 'a');
      expect(jsGet(object, true), 'b');
      expect(jsGet(['x', 'y'], 1.0), 'y');
    });

    test('reads an inherited value through operator []', () {
      expect(jsGet(_Inheriting(), 'inherited'), 'p');
      expect(jsGet(_Inheriting(), 'other'), same(undefined));
    });

    test('reads a Map and a List of any type arguments', () {
      // The Map and List cases match every type argument. The read is the
      // same for each one.
      final ints = <String, int>{'a': 1};
      expect(jsGet(ints, 'a'), 1);
      expect(jsGet(ints, 'b'), same(undefined));
      final objects = <Object?, Object?>{'a': 2.5, 1: 'int key'};
      expect(jsGet(objects, 'a'), 2.5);
      // The key 1.0 becomes '1'. The Map has the int key 1 only.
      expect(jsGet(objects, 1.0), same(undefined));
      expect(jsGet(const {'c': -0.0}, 'c'), isA<double>());
      expect((jsGet(const {'c': -0.0}, 'c')! as double).isNegative, isTrue);
      expect(
        jsGet(Map<String, Object?>.unmodifiable({'d': null}), 'd'),
        isNull,
      );
      final doubles = <double>[double.nan, 2];
      expect((jsGet(doubles, '0')! as double).isNaN, isTrue);
      expect(jsGet(doubles, 'length'), 2.0);
      expect(jsGet(const <String>['x'], '0'), 'x');
      expect(jsGet(const <String>['x'], '1'), same(undefined));
    });

    test('gives the get trap result of a proxy as it is', () {
      expect(jsGet(_NullProxy(), 'a'), isNull);
    });

    test('reads the indices and the length of an array', () {
      final array = <Object?>['a', null, undefined];
      expect(jsGet(array, '0'), 'a');
      expect(jsGet(array, '1'), isNull);
      expect(jsGet(array, '2'), same(undefined));
      expect(jsGet(array, 'length'), 3.0);
      expect(jsGet(array, 'length'), isA<double>());
      // ['a'][3], ['a']['01'], ['a']['-0'] and ['a']['+0'] are undefined.
      // ['a'].push is a function in JavaScript. The port has no member of
      // Array.prototype (differences.md js-semantics-resolver-objects).
      for (final key in ['3', '01', '-0', '+0', ' 0', '0.0', 'push']) {
        expect(jsGet(array, key), same(undefined), reason: key);
      }
    });

    test('reads the indices and the length of a string', () {
      expect(jsGet('abc', '1'), 'b');
      expect(jsGet('abc', 'length'), 3.0);
      expect(jsGet('abc', '3'), same(undefined));
      expect(jsGet('abc', 'size'), same(undefined));
    });

    test('gives undefined for other values', () {
      // (5).x and true.x are undefined. (() => 0).length is 0 in
      // JavaScript, and undefined in the port.
      expect(jsGet(5.0, 'x'), same(undefined));
      expect(jsGet(true, 'x'), same(undefined));
      expect(jsGet(() => 0, 'length'), same(undefined));
    });

    test('throws for null and undefined, as JavaScript does', () {
      // null.x and undefined.x throw a TypeError.
      expect(() => jsGet(null, 'x'), throwsA(isA<TypeError>()));
      expect(() => jsGet(undefined, 'x'), throwsA(isA<TypeError>()));
    });
  });
}
