// Original code, not ported from Chart.js: helpers.core cases with no spec.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart' as helpers;
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/index.dart';
import 'package:test/test.dart';

// Upstream behavior that test/specs/helpers.core.tests.js does not check
// (AGENTS.md rule 3). The expected values come from src/helpers/helpers.core.ts
// at v4.5.1 in Node.js v24.12.0 on x64 (V8 13.6.233.17-node.37), unless a test
// says that it pins a difference of the port.

/// A JavaScript object literal `{datasetIndex, index}`, passed as an
/// [ActiveDataPoint].
final class _Active implements ActiveDataPoint {
  const _Active(this.datasetIndex, this.index);

  @override
  final double datasetIndex;

  @override
  final double index;
}

/// A JavaScript event object `{type}`, passed as a [ChartEvent]. Only
/// `type` is read.
final class _Event implements ChartEvent {
  const _Event(this.type);

  @override
  final String type;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// An instance of a Dart class: a leaf for clone and merge.
final class _Instance {
  const _Instance();
}

/// The object `{b: 1, 10: 2, a: 3, 2: 4}`, whose `Object.keys` order is
/// `['2', '10', 'b', 'a']`.
Map<String, Object?> _ordered() => {'b': 1, '10': 2, 'a': 3, '2': 4};

/// The lines that [body] prints.
List<String> _printed(void Function() body) {
  final lines = <String>[];
  runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => lines.add(line),
    ),
  );
  return lines;
}

void main() {
  group('noop', () {
    test('returns undefined for any arguments', () {
      expect(helpers.noop(), same(undefined));
      expect(jsCall(helpers.noop, [1, 2, 3]), same(undefined));
    });
  });

  group('isObject', () {
    test('is false for a class instance, unlike JavaScript', () {
      // Port difference (Chart.js ADR 0006): in JavaScript an instance of a
      // class gives '[object Object]', so isObject is true.
      expect(helpers.isObject(const _Instance()), isFalse);
    });

    test('is true only for a Map with String keys', () {
      expect(helpers.isObject(jsonDecode('{"a": 1}')), isTrue);
      expect(helpers.isObject(<String, int>{'a': 1}), isTrue);
      expect(helpers.isObject(<dynamic, dynamic>{'a': 1}), isFalse);
      expect(helpers.isObject(<Object, Object?>{'a': 1}), isFalse);
    });
  });

  group('finiteOrDefault', () {
    test('returns finite numbers and else the default', () {
      expect(helpers.finiteOrDefault(1.5, 2), 1.5);
      expect(helpers.finiteOrDefault(double.nan, 2), 2);
      expect(helpers.finiteOrDefault(double.infinity, 2), 2);
      expect(helpers.finiteOrDefault('3', 2), 2);
      expect(helpers.finiteOrDefault(null, 2), 2);
      expect(helpers.finiteOrDefault(undefined, 2), 2);
      expect(helpers.finiteOrDefault(-0.0, 2).isNegative, isTrue);
    });

    test('returns an int value as a double', () {
      expect(helpers.finiteOrDefault(3, 2), isA<double>());
      expect(helpers.finiteOrDefault(3, 2), 3);
    });
  });

  group('valueOrDefault', () {
    test('returns the default for undefined only', () {
      expect(helpers.valueOrDefault<Object?>(undefined, 1), 1);
      expect(helpers.valueOrDefault<Object?>(null, 1), isNull);
      expect(helpers.valueOrDefault<Object?>(double.nan, 1), isNaN);
    });
  });

  group('toPercentage', () {
    test('reads a percentage string or divides a number', () {
      expect(helpers.toPercentage('50%', 200), 0.5);
      expect(helpers.toPercentage(50, 200), 0.25);
      expect(helpers.toPercentage('50', 200), 0.25);
      expect(helpers.toPercentage(' 12.5%', 10), 0.125);
      expect(helpers.toPercentage('abc%', 10), isNaN);
      expect(helpers.toPercentage(null, 10), 0);
      expect(helpers.toPercentage(undefined, 10), isNaN);
      expect(helpers.toPercentage(true, 4), 0.25);
    });
  });

  group('toDimension', () {
    test('reads a percentage string or returns the number', () {
      expect(helpers.toDimension('50%', 200), 100);
      expect(helpers.toDimension(50, 200), 50);
      expect(helpers.toDimension('50', 200), 50);
      expect(helpers.toDimension('1e2%', 10), 10);
      expect(helpers.toDimension('', 10), 0);
      expect(helpers.toDimension(null, 10), 0);
      expect(helpers.toDimension(undefined, 10), isNaN);
    });
  });

  group('callback', () {
    test('passes no argument for null args, and thisArg', () {
      final result = helpers.callback(
        JsFunction((Object? self, [Object? a = 'none']) => [self, a]),
        null,
        7,
      );
      expect(result, [7, 'none']);
    });

    test('drops the arguments that a Dart function does not take', () {
      expect(helpers.callback((Object? a) => a, [1, 2]), 1);
    });
  });

  group('each', () {
    test('visits object keys in the Object.keys order', () {
      final keys = <Object?>[];
      final values = <Object?>[];
      helpers.each(_ordered(), (Object? value, Object? key) {
        keys.add(key);
        values.add(value);
      });
      expect(keys, ['2', '10', 'b', 'a']);
      expect(values, [4, 2, 1, 3]);
    });

    test('reads a removed key as undefined', () {
      final object = <String, Object?>{'a': 1, 'b': 2};
      final seen = <Object?>[];
      helpers.each(object, (Object? value, Object? key) {
        seen.add([key, value]);
        object.remove('b');
      });
      expect(seen, [
        ['a', 1],
        ['b', same(undefined)],
      ]);
    });

    test('reads an index past a shortened array as undefined', () {
      final array = <Object?>[1, 2, 3];
      final seen = <Object?>[];
      helpers.each(array, (Object? value, Object? index) {
        seen.add([value, index]);
        array.length = 1;
      });
      expect(seen, [
        [1, 0],
        [same(undefined), 1],
        [same(undefined), 2],
      ]);
    });

    test('passes the index as a double', () {
      final indices = <Object?>[];
      helpers.each(<Object?>['a'], (Object? value, Object? index) {
        indices.add(index);
      });
      expect(indices.single, isA<double>());
    });

    test('calls a function that takes only the item', () {
      final items = <Object?>[];
      helpers.each(<Object?>['a', 'b'], items.add);
      expect(items, ['a', 'b']);
    });

    test('iterates over a typed list', () {
      final items = <Object?>[];
      helpers.each(Float64List.fromList([1.5, 2]), items.add);
      expect(items, [1.5, 2]);
    });
  });

  group('_elementsEqual', () {
    test('compares null and empty lists as upstream', () {
      expect(helpers.elementsEqual(null, []), isFalse);
      expect(helpers.elementsEqual([], null), isFalse);
      expect(helpers.elementsEqual([], []), isTrue);
    });

    test('compares the indices with !==', () {
      expect(
        helpers.elementsEqual(
          [const _Active(double.nan, 0)],
          [const _Active(double.nan, 0)],
        ),
        isFalse,
      );
      expect(
        helpers.elementsEqual(
          // The int literal -0 is 0, not -0.
          // ignore: prefer_int_literals
          [const _Active(0, -0.0)],
          [const _Active(0, 0)],
        ),
        isTrue,
      );
    });
  });

  group('clone', () {
    test('copies the keys in the Object.keys order', () {
      final output = helpers.clone(_ordered())! as Map<String, Object?>;
      expect(output.keys, ['2', '10', 'b', 'a']);
      expect(jsObjectKeys(output), ['2', '10', 'b', 'a']);
    });

    test('copies the key __proto__ as an own key', () {
      final output =
          helpers.clone(jsonDecode('{"__proto__":{"polluted": true}}'))!
              as Map<String, Object?>;
      expect(output.keys, ['__proto__']);
      expect(output['__proto__'], {'polluted': true});
    });

    test('copies a typed list into a new list of the same type', () {
      final input = Float32List.fromList([1.5, 2]);
      final output = helpers.clone(input);
      expect(output, isA<Float32List>());
      expect(output, isNot(same(input)));
      expect(output, [1.5, 2]);
    });

    test('gives plain lists and objects', () {
      final output =
          helpers.clone(<String, Object?>{
                'list': <double>[1, 2],
                'map': <String, int>{'a': 1},
              })!
              as Map<String, Object?>;
      expect(output['list'], isA<List<Object?>>());
      expect(output['map'], isA<Map<String, Object?>>());
      // A plain object takes any value.
      (output['map']! as Map<String, Object?>)['b'] = 'text';
    });

    test('keeps the reference of a leaf', () {
      const instance = _Instance();
      final untyped = <dynamic, dynamic>{'a': 1};
      final output = helpers.clone(<Object?>[instance, untyped])! as List;
      expect(output[0], same(instance));
      expect(output[1], same(untyped));
    });
  });

  group('merge', () {
    test('skips the keys __proto__, prototype and constructor', () {
      final output =
          helpers.merge(
                <String, Object?>{},
                jsonDecode(
                  '{"__proto__":{"p":1},"prototype":2,"constructor":3,"ok":4}',
                ),
              )!
              as Map<String, Object?>;
      expect(output.keys, ['ok']);
    });

    test('merges the keys in the Object.keys order', () {
      final output =
          helpers.merge(<String, Object?>{'z': 0}, _ordered())!
              as Map<String, Object?>;
      expect(jsObjectKeys(output), ['2', '10', 'z', 'b', 'a']);
    });

    test('skips the sources that are not objects in a list', () {
      final output = helpers.merge(
        <String, Object?>{'a': 1},
        <Object?>[
          null,
          5,
          <String, Object?>{'b': 2},
        ],
      );
      expect(output, {'a': 1, 'b': 2});
    });

    test('calls the merger of the options, also for nested objects', () {
      final calls = <String>[];
      final options = helpers.MergeOptions(
        merger: (key, target, source, options) {
          calls.add(key);
          helpers.merger(key, target, source, options);
        },
      );
      final output = helpers.merge(
        <String, Object?>{
          'a': <String, Object?>{'b': 1},
        },
        <String, Object?>{
          'a': <String, Object?>{'c': 2},
          'd': 3,
        },
        options,
      );
      expect(calls, ['a', 'c', 'd']);
      expect(output, {
        'a': {'b': 1, 'c': 2},
        'd': 3,
      });
    });

    test('does not enter a class instance', () {
      const instance = _Instance();
      final output = helpers.merge(
        <String, Object?>{'a': 1},
        <String, Object?>{
          'a': instance,
        },
      );
      expect((output! as Map<String, Object?>)['a'], same(instance));
    });
  });

  group('mergeIf', () {
    test('keeps a key that holds the undefined sentinel', () {
      // Chart.js ADR 0006: a stored sentinel blocks mergeIf.
      final output =
          helpers.mergeIf(
                <String, Object?>{'a': undefined},
                <String, Object?>{
                  'a': <String, Object?>{'b': 1},
                },
              )!
              as Map<String, Object?>;
      expect(output['a'], same(undefined));
    });

    test('adds a key that the target does not own', () {
      final output =
          helpers.mergeIf(<String, Object?>{}, <String, Object?>{
                'a': undefined,
              })!
              as Map<String, Object?>;
      expect(output.containsKey('a'), isTrue);
      expect(output['a'], same(undefined));
    });

    test('skips the keys __proto__, prototype and constructor', () {
      final output =
          helpers.mergeIf(
                <String, Object?>{},
                jsonDecode(
                  '{"__proto__":{"p":1},"prototype":2,"constructor":3,"ok":4}',
                ),
              )!
              as Map<String, Object?>;
      expect(output.keys, ['ok']);
    });
  });

  group('_deprecated', () {
    test('warns unless the value is undefined', () {
      final lines = _printed(() {
        helpers.deprecated('Chart', 1, 'old', 'new');
        helpers.deprecated('Chart', undefined, 'a', 'b');
        helpers.deprecated('Chart', null, 'x', 'y');
        helpers.deprecated('Chart', 0, 'p', 'q');
      });
      expect(lines, [
        'Chart: "old" is deprecated. Please use "new" instead',
        'Chart: "x" is deprecated. Please use "y" instead',
        'Chart: "p" is deprecated. Please use "q" instead',
      ]);
    });
  });

  group('resolveObjectKey', () {
    test('reads array and string elements and length', () {
      final data = <String, Object?>{
        'a': <Object?>[10, 20],
        's': 'xyz',
      };
      expect(helpers.resolveObjectKey(data, 'a.1'), 20);
      expect(helpers.resolveObjectKey(data, 'a.length'), 2);
      expect(helpers.resolveObjectKey(data, 'a.2'), same(undefined));
      expect(helpers.resolveObjectKey(data, 'a.01'), same(undefined));
      expect(helpers.resolveObjectKey(data, 's.1'), 'y');
      expect(helpers.resolveObjectKey(data, 's.length'), 3);
    });

    test('returns a falsy value on the path', () {
      expect(
        helpers.resolveObjectKey(<String, Object?>{'a': 0}, 'a.b'),
        0,
      );
      expect(
        helpers.resolveObjectKey(<String, Object?>{'a': null}, 'a.b'),
        isNull,
      );
      expect(
        helpers.resolveObjectKey(<String, Object?>{'a': ''}, 'a.b'),
        '',
      );
      expect(
        helpers.resolveObjectKey(<String, Object?>{'a': true}, 'a.b'),
        same(undefined),
      );
      expect(helpers.resolveObjectKey(undefined, 'a'), same(undefined));
      expect(helpers.resolveObjectKey(null, 'a.b'), isNull);
      expect(helpers.resolveObjectKey(undefined, ''), same(undefined));
    });

    test('reads x and y with the default resolvers', () {
      final point = <String, Object?>{'x': 1, 'y': 2};
      expect(helpers.resolveObjectKey(point, 'x'), 1);
      expect(helpers.resolveObjectKey(point, 'y'), 2);
      expect(helpers.resolveObjectKey(5, 'x'), same(undefined));
      // `o.x` of undefined or null throws a TypeError in JavaScript.
      expect(
        () => helpers.resolveObjectKey(undefined, 'x'),
        throwsA(isA<TypeError>()),
      );
      expect(
        () => helpers.resolveObjectKey(null, 'y'),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('js-semantics-resolver-cache', () {
    test('resolves the names of Object.prototype as own keys', () {
      // Pins a port difference: upstream finds these names in the prototype
      // of its resolver cache. In the reference engine, 'constructor' gives
      // the object, 'toString' gives '[object Undefined]' and the other
      // names throw a TypeError. A Map has no prototype (Chart.js ADR 0006).
      for (final key in [
        'constructor',
        'toString',
        '__proto__',
        'hasOwnProperty',
        'valueOf',
      ]) {
        expect(helpers.resolveObjectKey(<String, Object?>{key: 5}, key), 5);
      }
    });
  });

  group('_splitKey', () {
    test('handles a trailing backslash and empty parts', () {
      expect(helpers.splitKey(r'a\'), <String>[]);
      expect(helpers.splitKey(r'\'), <String>[]);
      expect(helpers.splitKey(r'a\\.b'), [r'a\.b']);
      expect(helpers.splitKey('.'), ['', '']);
      expect(helpers.splitKey(r'a\.'), ['a.']);
    });
  });

  group('_capitalize', () {
    test('upper-cases the first code unit', () {
      expect(helpers.capitalize('register'), 'Register');
      expect(helpers.capitalize(''), '');
      expect(helpers.capitalize('a'), 'A');
      expect(helpers.capitalize('éclair'), 'Éclair');
      expect(helpers.capitalize('1abc'), '1abc');
      expect(helpers.capitalize('Abc'), 'Abc');
    });
  });

  group('js-semantics-to-upper-case', () {
    test('upper-cases with the String.toUpperCase of the platform', () {
      // Pins a port difference: JavaScript gives 'SSa' and 'FIx' (the full
      // Unicode case mappings). The Dart VM gives 'ßa' and 'ﬁx'. dart2js
      // and dart2wasm call the toUpperCase of the JavaScript engine.
      expect(helpers.capitalize('ßa'), '${'ß'.toUpperCase()}a');
      expect(helpers.capitalize('ﬁx'), '${'ﬁ'.toUpperCase()}x');
      // ASCII names give the JavaScript result on every platform.
      expect(helpers.capitalize('backgroundColor'), 'BackgroundColor');
      expect(helpers.capitalize('zIndex'), 'ZIndex');
    });
  });

  group('defined', () {
    test('is false only for undefined', () {
      expect(helpers.defined(undefined), isFalse);
      expect(helpers.defined(null), isTrue);
      expect(helpers.defined(0), isTrue);
      expect(helpers.defined(''), isTrue);
    });
  });

  group('isFunction', () {
    test('is true for a Dart function and a JsFunction', () {
      expect(helpers.isFunction(() => 1), isTrue);
      expect(helpers.isFunction(JsFunction((Object? self) => self)), isTrue);
      expect(helpers.isFunction(<String, Object?>{}), isFalse);
      expect(helpers.isFunction(null), isFalse);
      expect(helpers.isFunction(undefined), isFalse);
      expect(helpers.isFunction('f'), isFalse);
    });
  });

  group('setsEqual', () {
    test('compares string sets in any order', () {
      expect(helpers.setsEqual(<String>{}, <String>{}), isTrue);
      expect(helpers.setsEqual({'a', 'b'}, {'b', 'a'}), isTrue);
      expect(helpers.setsEqual({'a'}, {'a', 'b'}), isFalse);
    });
  });

  group('js-semantics-set-equality', () {
    test('compares the elements with == and not with SameValueZero', () {
      // Pins a port difference: `setsEqual(new Set([NaN]), new Set([NaN]))`
      // is true in JavaScript. A Dart Set finds NaN with ==, and NaN == NaN
      // is false on the VM, dart2js and dart2wasm.
      expect(helpers.setsEqual({double.nan}, {double.nan}), isFalse);
      // 0 and -0 are the same element, as in a JavaScript Set.
      expect(helpers.setsEqual({0.0}, {-0.0}), isTrue);
    });
  });

  group('_isClickEvent', () {
    test('is true for mouseup, click and contextmenu', () {
      final types = [
        'mouseup',
        'click',
        'contextmenu',
        'mousedown',
        'mousemove',
        'touchend',
        '',
      ];
      expect(
        [for (final type in types) helpers.isClickEvent(_Event(type))],
        [true, true, true, false, false, false, false],
      );
    });
  });
}
