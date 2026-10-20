// Original code, not ported from Chart.js: tests of lib/src/js/js_object.dart.
import 'dart:collection';

import 'package:flutter_chartjs/src/js/js_array.dart';
import 'package:flutter_chartjs/src/js/js_class.dart';
import 'package:flutter_chartjs/src/js/js_function.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:test/test.dart';

// The expected values come from Node.js v24.12.0: obj[key] for each input,
// and Object.freeze and Object.isFrozen in an ES module (strict mode) on x64.

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

/// An object with the frozen state of Chart.js ADR 0021.
final class _Freezable implements JsFreezable {
  @override
  bool isFrozen = false;

  /// The count of the calls of [freeze].
  int freezes = 0;

  @override
  void freeze() {
    isFrozen = true;
    freezes++;
  }
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

    test('reads the static properties of a class value', () {
      // class A { static id = 'a'; static n = null; } class B extends A {}
      // B.id is 'a', B.n is null and B.x is undefined.
      final a = JsClass('A', statics: {'id': 'a', 'n': null});
      final b = JsClass('B', superclass: a);
      expect(jsGet(b, 'id'), 'a');
      expect(jsGet(b, 'n'), isNull);
      expect(jsGet(b, 'x'), same(undefined));
      // ({1: 'one'})[1] reads the key '1' of a class value too.
      b['1'] = 'one';
      expect(jsGet(b, 1.0), 'one');
      // A.name is 'A' in JavaScript. The function properties are not static
      // properties of a class value (Chart.js ADR 0020, section 1).
      expect(jsGet(a, 'name'), same(undefined));
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
  group('jsObjectFreeze', () {
    test('freezes a JsFreezable and returns it', () {
      // Object.freeze(o) === o, and Object.isFrozen(o) is then true.
      final object = _Freezable();
      expect(jsObjectFreeze(object), same(object));
      expect(object.isFrozen, isTrue);
      expect(jsObjectIsFrozen(object), isTrue);
      // A second freeze returns the object again.
      expect(jsObjectFreeze(object), same(object));
      expect(object.freezes, 2);
    });

    test('returns another value with no change', () {
      // Object.freeze(5) is 5, Object.freeze('s') is 's', Object.freeze(null)
      // is null and Object.freeze(undefined) is undefined.
      expect(jsObjectFreeze(5), 5);
      expect(jsObjectFreeze('s'), 's');
      expect(jsObjectFreeze(null), isNull);
      expect(jsObjectFreeze(undefined), same(undefined));
      final list = [1.0];
      expect(jsObjectFreeze(list), same(list));
    });

    test('js-semantics-object-freeze: a plain Map stays writable', () {
      // const o = {a: 1}; Object.freeze(o); o.a = 2 throws a TypeError in
      // strict mode, and Object.isFrozen(o) is true. The port freezes only a
      // JsFreezable.
      final map = <String, Object?>{'a': 1.0};
      expect(jsObjectFreeze(map), same(map));
      map['a'] = 2.0;
      expect(map['a'], 2.0);
      expect(jsObjectIsFrozen(map), isFalse);
    });
  });

  group('jsObjectIsFrozen', () {
    test('is true for a primitive', () {
      // Object.isFrozen of null, undefined, 1, NaN, 's' and true is true.
      for (final value in <Object?>[
        null,
        undefined,
        1.0,
        double.nan,
        's',
        '',
        true,
        false,
      ]) {
        expect(jsObjectIsFrozen(value), isTrue, reason: '$value');
      }
    });

    test('is the frozen state of a JsFreezable', () {
      final object = _Freezable();
      expect(jsObjectIsFrozen(object), isFalse);
      object.freeze();
      expect(jsObjectIsFrozen(object), isTrue);
    });

    test('is false for each other value', () {
      // Object.isFrozen({}), Object.isFrozen([]), Object.isFrozen(() => 1)
      // and Object.isFrozen(class A {}) are false. A Map.unmodifiable is
      // not a JsFreezable (js-semantics-object-freeze).
      for (final value in <Object?>[
        <String, Object?>{},
        Map<String, Object?>.unmodifiable({'a': 1.0}),
        <Object?>[],
        () => 1.0,
        JsClass('A'),
      ]) {
        expect(jsObjectIsFrozen(value), isFalse, reason: '$value');
      }
    });
  });

  group('jsTypeof', () {
    test('gives the typeof of each kind of value', () {
      // typeof undefined, null, true, 0, NaN, 's', {}, [], () => 1 and
      // class C {} in Node.js v24.12.0 on x64.
      final values = <Object?>[
        undefined,
        null,
        true,
        0.0,
        double.nan,
        's',
        <String, Object?>{},
        <Object?>[],
        () => 1.0,
        JsClass('C'),
      ];
      expect(values.map(jsTypeof), [
        'undefined',
        'object',
        'boolean',
        'number',
        'number',
        'string',
        'object',
        'object',
        'function',
        'function',
      ]);
    });

    test('gives function for a JsFunction and number for an int', () {
      expect(jsTypeof(JsFunction((Object? self) => self)), 'function');
      expect(jsTypeof(1), 'number');
      expect(jsTypeof(false), 'boolean');
      expect(jsTypeof(''), 'string');
      expect(jsTypeof(Object()), 'object');
    });

    test('gives object for a DateTime, as for a JS Date', () {
      // typeof new Date(2015, 0) (Chart.js ADR 0024, decision 2).
      expect(jsTypeof(DateTime.utc(2015)), 'object');
    });
  });
}
