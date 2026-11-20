// Original code, not ported from Chart.js: helpers.core cases with no spec.
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_chartjs_port/chartjs_core.dart';
import 'package:test/test.dart';

// Upstream behavior that test/specs/helpers.core.tests.js does not check
// (AGENTS.md rule 3). The expected values come from src/helpers/helpers.core.ts
// at v4.5.1 in Node.js v24.12.0 on x64 (V8 13.6.233.17-node.37), unless a test
// says that it pins a difference of the port.

/// A JavaScript object literal `{datasetIndex, index}`, an [ActiveElement]
/// with no element (row `adapt-native-active-element`).
ActiveElement _active(int datasetIndex, int index) =>
    ActiveElement(datasetIndex: datasetIndex, index: index);

/// A JavaScript event object `{type}`, passed as a [ChartEvent]. Only
/// `type` is read.
final class const _Event(@override final String type) implements ChartEvent {
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// An instance of a Dart class: a leaf for clone and merge.
final class const _Instance();

/// An object with the access by name of [PropertyAccess] that is not an
/// element: a store of named values, with [undefined] for an absent name.
final class _ByName() implements PropertyAccess {
  final Map<String, Object?> values = {};

  @override
  Object? operator [](String prop) =>
      values.containsKey(prop) ? values[prop] : undefined;

  @override
  void operator []=(String prop, Object? value) => values[prop] = value;
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
  group('isObject', () {
    test('is false for a class instance, unlike JavaScript', () {
      // Port difference (Chart.js ADR 0043): in JavaScript an instance of a
      // class gives '[object Object]', so isObject is true.
      expect(isObject(const _Instance()), isFalse);
    });

    test('is true only for a Map with String keys', () {
      expect(isObject(jsonDecode('{"a": 1}')), isTrue);
      expect(isObject(<String, int>{'a': 1}), isTrue);
      expect(isObject(<dynamic, dynamic>{'a': 1}), isFalse);
      expect(isObject(<Object, Object?>{'a': 1}), isFalse);
    });
  });

  group('finiteOrDefault', () {
    test('returns finite numbers and else the default', () {
      expect(finiteOrDefault(1.5, 2), 1.5);
      expect(finiteOrDefault(double.nan, 2), 2);
      expect(finiteOrDefault(double.infinity, 2), 2);
      expect(finiteOrDefault('3', 2), 2);
      expect(finiteOrDefault(null, 2), 2);
      expect(finiteOrDefault(undefined, 2), 2);
      expect(finiteOrDefault(-0.0, 2).isNegative, isTrue);
    });

    test('returns an int value as a double', () {
      expect(finiteOrDefault(3, 2), isA<double>());
      expect(finiteOrDefault(3, 2), 3);
    });
  });

  group('valueOrDefault', () {
    test('returns the default for undefined only', () {
      expect(valueOrDefault<Object?>(undefined, 1), 1);
      expect(valueOrDefault<Object?>(null, 1), isNull);
      expect(valueOrDefault<Object?>(double.nan, 1), isNaN);
    });
  });

  group('callback', () {
    test('passes no argument for null args', () {
      final result = callback(([Object? a = 'none']) => [a]);
      expect(result, ['none']);
    });

    test('passes the exact arguments (Chart.js ADR 0173)', () {
      expect(callback((Object? a, Object? b) => [a, b], [1, 2]), [1, 2]);
      expect(() => callback((Object? a) => a, [1, 2]), throwsNoSuchMethodError);
    });

    test('counts each call of a function', () {
      final before = appFunctionCalls;
      callback(() => 1);
      callback('no function');
      expect(appFunctionCalls, before + 1);
    });
  });

  group('each', () {
    test('visits object keys in the Object.keys order', () {
      final keys = <Object?>[];
      final values = <Object?>[];
      each<Object?, Object?>(_ordered(), (value, key) {
        keys.add(key);
        values.add(value);
      });
      expect(keys, ['2', '10', 'b', 'a']);
      expect(values, [4, 2, 1, 3]);
    });

    test('reads a removed key as undefined', () {
      final object = <String, Object?>{'a': 1, 'b': 2};
      final seen = <Object?>[];
      each<Object?, Object?>(object, (value, key) {
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
      each<Object?, Object?>(array, (value, index) {
        seen.add([value, index]);
        array.length = 1;
      });
      expect(seen, [
        [1, 0],
        [same(undefined), 1],
        [same(undefined), 2],
      ]);
    });

    test('passes the index as an int', () {
      final indices = <Object?>[];
      each<Object?, Object?>(<Object?>['a'], (value, index) {
        indices.add(index);
      });
      expect(indices.single, isA<int>());
    });

    test('casts the item and the key to the parameter types', () {
      final items = <String>[];
      final keys = <int>[];
      each<String, int>(<Object?>['a', 'b'], (item, key) {
        items.add(item);
        keys.add(key);
      });
      expect(items, ['a', 'b']);
      expect(keys, [0, 1]);
      expect(
        () => each<String, int>(<Object?>[1], (item, key) {}),
        throwsA(isA<TypeError>()),
      );
    });

    test('iterates over a typed list', () {
      final items = <Object?>[];
      each<Object?, Object?>(
        Float64List.fromList([1.5, 2]),
        (item, _) => items.add(item),
      );
      expect(items, [1.5, 2]);
    });
  });

  group('_elementsEqual', () {
    test('compares null and empty lists as upstream', () {
      expect(elementsEqual(null, []), isFalse);
      expect(elementsEqual([], null), isFalse);
      expect(elementsEqual([], []), isTrue);
    });

    test('compares the two indexes of each item', () {
      expect(elementsEqual([_active(0, 1)], [_active(0, 1)]), isTrue);
      expect(elementsEqual([_active(0, 1)], [_active(1, 1)]), isFalse);
      expect(elementsEqual([_active(0, 1)], [_active(0, 2)]), isFalse);
    });
  });

  group('clone', () {
    test('copies the keys in the Object.keys order', () {
      final output = clone(_ordered())! as Map<String, Object?>;
      expect(output.keys, ['2', '10', 'b', 'a']);
      expect(jsObjectKeys(output), ['2', '10', 'b', 'a']);
    });

    test('copies the key __proto__ as an own key', () {
      final output =
          clone(jsonDecode('{"__proto__":{"polluted": true}}'))!
              as Map<String, Object?>;
      expect(output.keys, ['__proto__']);
      expect(output['__proto__'], {'polluted': true});
    });

    test('copies a typed list into a new list of the same type', () {
      final input = Float32List.fromList([1.5, 2]);
      final output = clone(input);
      expect(output, isA<Float32List>());
      expect(output, isNot(same(input)));
      expect(output, [1.5, 2]);
    });

    test('gives plain lists and objects', () {
      final output =
          clone(<String, Object?>{
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
      final output = clone(<Object?>[instance, untyped])! as List;
      expect(output[0], same(instance));
      expect(output[1], same(untyped));
    });
  });

  group('merge', () {
    test('skips the keys __proto__, prototype and constructor', () {
      final output =
          merge(
                <String, Object?>{},
                jsonDecode(
                  '{"__proto__":{"p":1},"prototype":2,"constructor":3,"ok":4}',
                ),
              )!
              as Map<String, Object?>;
      expect(output.keys, ['ok']);
    });

    test('merges the names that only resemble the reserved keys', () {
      // isValidKey compares with ===: only the three exact names are skipped.
      final output =
          merge(
                <String, Object?>{},
                jsonDecode(
                  '{"__proto":1,"Prototype":2,"constructor ":3,"":4, '
                  '"__proto__x":5}',
                ),
              )!
              as Map<String, Object?>;
      expect(output.keys, [
        '__proto',
        'Prototype',
        'constructor ',
        '',
        '__proto__x',
      ]);
    });

    test('merges the keys in the Object.keys order', () {
      final output =
          merge(<String, Object?>{'z': 0}, _ordered())! as Map<String, Object?>;
      expect(jsObjectKeys(output), ['2', '10', 'z', 'b', 'a']);
    });

    test('skips the sources that are not objects in a list', () {
      final output = merge(
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
      final options = MergeOptions(
        merger: (key, target, source, options) {
          calls.add(key);
          merger(key, target, source, options);
        },
      );
      final output = merge(
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
      final output = merge(
        <String, Object?>{'a': 1},
        <String, Object?>{'a': instance},
      );
      expect((output! as Map<String, Object?>)['a'], same(instance));
    });
  });

  group('mergeIf', () {
    test('keeps a key that holds the undefined sentinel', () {
      // Chart.js ADR 0043: a stored sentinel blocks mergeIf.
      final output =
          mergeIf(
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
          mergeIf(<String, Object?>{}, <String, Object?>{'a': undefined})!
              as Map<String, Object?>;
      expect(output.containsKey('a'), isTrue);
      expect(output['a'], same(undefined));
    });

    test('skips the keys __proto__, prototype and constructor', () {
      final output =
          mergeIf(
                <String, Object?>{},
                jsonDecode(
                  '{"__proto__":{"p":1},"prototype":2,"constructor":3,"ok":4}',
                ),
              )!
              as Map<String, Object?>;
      expect(output.keys, ['ok']);
    });
  });

  // The row adapt-merge-element-target (Chart.js ADR 0039, section 10).
  // The upstream values come from a probe of phase 8: the pinned Chart.js
  // build in Node.js v24.12.0 on x64.
  group('adapt-merge-element-target', () {
    /// The two `merge` calls of the probe into [target]. It gives the
    /// `options` object after the first call.
    Object? mergeTwice(PropertyAccess target) {
      final view1 = <String, Object?>{
        'x': 100,
        'options': <String, Object?>{
          'a': 1,
          'nested': <String, Object?>{'b': 2},
        },
        'title': <Object?>['t1'],
      };
      expect(merge(target, view1), same(target));
      expect(target['x'], 100.0);
      expect(target['options'], isNot(same(view1['options'])));
      expect(target['options'], {
        'a': 1,
        'nested': {'b': 2},
      });
      expect(target['title'], isNot(same(view1['title'])));
      expect(target['title'], ['t1']);
      final options1 = target['options'];

      final view2 = <String, Object?>{
        'options': <String, Object?>{
          'nested': <String, Object?>{'c': 3},
          'd': 4,
        },
        'title': <Object?>['t2'],
      };
      expect(merge(target, view2), same(target));
      expect(target['options'], same(options1));
      expect(target['options'], {
        'a': 1,
        'nested': {'b': 2, 'c': 3},
        'd': 4,
      });
      expect(target['title'], isNot(same(view2['title'])));
      expect(target['title'], ['t2']);
      return options1;
    }

    // A merge writes a plain Map into `options`, which a typed element
    // rejects (Chart.js ADR 0185).
    test(
      'merges into an element target, as upstream',
      skip: 'diverges: adapt-native-element-options',
      () {
        final element = PointElement({'x': 1, 'y': 2});
        mergeTwice(element);
        expect(element.x, 100.0);
        expect(element.y, 2.0);
        expect(element.options, isA<Map<String, Object?>>());
      },
    );

    test('merges into another PropertyAccess target', () {
      final target = _ByName();
      mergeTwice(target);
      expect(target.values.keys, ['x', 'options', 'title']);
    });

    // A merge writes a plain Map into `options`, which a typed element
    // rejects (Chart.js ADR 0185).
    test(
      'the default merger enters a PropertyAccess value',
      skip: 'diverges: adapt-native-element-options',
      () {
        final element = PointElement({'x': 1});
        final host = <String, Object?>{'el': element};
        final output =
            merge(host, <String, Object?>{
                  'el': <String, Object?>{
                    'x': 5,
                    'options': <String, Object?>{'r': 1},
                  },
                })!
                as Map<String, Object?>;
        expect(output['el'], same(element));
        expect(element.x, 5.0);
        expect(element.options, {'r': 1});

        // A leaf source value replaces the element.
        merge(host, <String, Object?>{'el': 3});
        expect(host['el'], 3);
      },
    );

    test('a target that is not an object is the result', () {
      expect(merge(5, <String, Object?>{'a': 1}), 5);
      const instance = _Instance();
      expect(merge(instance, <String, Object?>{'a': 1}), same(instance));
    });

    test('clone keeps an element as a reference, unlike upstream', () {
      // Port difference: upstream clone(element) gives a new object without
      // a prototype, with the own keys of the element.
      final element = PointElement({'x': 1});
      expect(clone(element), same(element));
      final list = clone(<Object?>[element])! as List;
      expect(list.single, same(element));
    });

    test('mergeIf writes nothing into an element, unlike upstream', () {
      // Port difference: upstream mergeIf(element, {x: 5, z: 7}) keeps x 1
      // and adds z 7.
      final element = PointElement({'x': 1});
      expect(
        mergeIf(element, <String, Object?>{'x': 5, 'z': 7}),
        same(element),
      );
      expect(element.x, 1.0);
      expect(element['z'], same(undefined));
    });

    // The upstream values of the next two tests come from a probe of phase 8
    // (the pinned Chart.js build in Node.js v24.12.0 on x64).
    test('merge skips an element source, unlike upstream', () {
      // Port difference: upstream merge({}, element) copies the 8 own keys
      // x, y, active, options, $animations, parsed, skip and stop.
      final element = PointElement({'x': 1, 'y': 2});
      final output =
          merge(<String, Object?>{}, element)! as Map<String, Object?>;
      expect(jsObjectKeys(output), isEmpty);
    });

    test('an element source value replaces an element target value, '
        'unlike upstream', () {
      // Port difference: upstream merge({el: t}, {el: s}) keeps t in el,
      // writes x 9 into t (the own key of s) and writes y undefined into t.
      final t = PointElement({'x': 1, 'y': 2});
      final s = PointElement({'x': 9});
      final host = <String, Object?>{'el': t};
      merge(host, <String, Object?>{'el': s});
      expect(host['el'], same(s));
      expect(t.x, 1.0);
      expect(t.y, 2.0);
    });

    test('a custom merger finds no own keys of an element target', () {
      // Upstream gives the own keys of the element. The merger gets the
      // element itself, which has no list of own keys: `Object.keys` gives
      // none, and the own-key test of mergerIf throws.
      final element = PointElement({'x': 1});
      final listed = <List<String>>[];
      void keysMerger(
        String key,
        Object target,
        Object source,
        MergeOptions options,
      ) {
        listed.add(jsObjectKeys(target));
      }

      merge(element, <String, Object?>{
        'q': 1,
      }, MergeOptions(merger: keysMerger));
      expect(listed, [<String>[]]);
      expect(
        () => merge(element, <String, Object?>{
          'q': 1,
        }, const MergeOptions(merger: mergerIf)),
        throwsUnsupportedError,
      );
    });

    test('a custom merger that reads and writes by name works', () {
      final element = PointElement({'x': 1});
      merge(
        element,
        <String, Object?>{'x': 2},
        MergeOptions(
          merger: (key, target, source, options) {
            final element = target as PropertyAccess;
            element[key] =
                jsToNumber(element[key]) + jsToNumber(jsGet(source, key));
          },
        ),
      );
      expect(element.x, 3.0);
    });

    test('the Map path gives the upstream config merge', () {
      final output = merge(
        <String, Object?>{
          'a': <String, Object?>{
            'b': 1,
            'c': <Object?>[
              1,
              <String, Object?>{'d': 2},
            ],
          },
          'e': 3,
        },
        <Object?>[
          <String, Object?>{
            'a': <String, Object?>{
              'c': <Object?>[9],
              'f': <String, Object?>{'g': 1},
            },
          },
          <String, Object?>{
            'e': <String, Object?>{'h': 1},
          },
        ],
      );
      expect(output, {
        'a': {
          'b': 1,
          'c': [9],
          'f': {'g': 1},
        },
        'e': {'h': 1},
      });
    });
  });

  group('_deprecated', () {
    test('warns unless the value is undefined', () {
      final lines = _printed(() {
        deprecated('Chart', 1, 'old', 'new');
        deprecated('Chart', undefined, 'a', 'b');
        deprecated('Chart', null, 'x', 'y');
        deprecated('Chart', 0, 'p', 'q');
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
      expect(resolveObjectKey(data, 'a.1'), 20);
      expect(resolveObjectKey(data, 'a.length'), 2);
      expect(resolveObjectKey(data, 'a.2'), same(undefined));
      expect(resolveObjectKey(data, 'a.01'), same(undefined));
      expect(resolveObjectKey(data, 's.1'), 'y');
      expect(resolveObjectKey(data, 's.length'), 3);
    });

    test('returns a falsy value on the path', () {
      expect(resolveObjectKey(<String, Object?>{'a': 0}, 'a.b'), 0);
      expect(resolveObjectKey(<String, Object?>{'a': null}, 'a.b'), isNull);
      expect(resolveObjectKey(<String, Object?>{'a': ''}, 'a.b'), '');
      expect(
        resolveObjectKey(<String, Object?>{'a': true}, 'a.b'),
        same(undefined),
      );
      expect(resolveObjectKey(undefined, 'a'), same(undefined));
      expect(resolveObjectKey(null, 'a.b'), isNull);
      expect(resolveObjectKey(undefined, ''), same(undefined));
    });

    test('reads x and y with the default resolvers', () {
      final point = <String, Object?>{'x': 1, 'y': 2};
      expect(resolveObjectKey(point, 'x'), 1);
      expect(resolveObjectKey(point, 'y'), 2);
      expect(resolveObjectKey(5, 'x'), same(undefined));
      // `o.x` of undefined or null throws a TypeError in JavaScript.
      expect(() => resolveObjectKey(undefined, 'x'), throwsA(isA<TypeError>()));
      expect(() => resolveObjectKey(null, 'y'), throwsA(isA<TypeError>()));
    });
  });

  group('js-semantics-resolver-cache', () {
    test('resolves the names of Object.prototype as own keys', () {
      // Pins a port difference: upstream finds these names in the prototype
      // of its resolver cache. In the reference engine, 'constructor' gives
      // the object, 'toString' gives '[object Undefined]' and the other
      // names throw a TypeError. A Map has no prototype (Chart.js ADR 0043).
      for (final key in [
        'constructor',
        'toString',
        '__proto__',
        'hasOwnProperty',
        'valueOf',
      ]) {
        expect(resolveObjectKey(<String, Object?>{key: 5}, key), 5);
      }
    });
  });

  group('_splitKey', () {
    test('handles a trailing backslash and empty parts', () {
      expect(splitKey(r'a\'), <String>[]);
      expect(splitKey(r'\'), <String>[]);
      expect(splitKey(r'a\\.b'), [r'a\.b']);
      expect(splitKey('.'), ['', '']);
      expect(splitKey(r'a\.'), ['a.']);
    });
  });

  group('_capitalize', () {
    test('upper-cases the first code unit', () {
      expect(capitalize('register'), 'Register');
      expect(capitalize(''), '');
      expect(capitalize('a'), 'A');
      expect(capitalize('éclair'), 'Éclair');
      expect(capitalize('1abc'), '1abc');
      expect(capitalize('Abc'), 'Abc');
    });
  });

  group('js-semantics-to-upper-case', () {
    test('upper-cases with the String.toUpperCase of the platform', () {
      // Pins a port difference: JavaScript gives 'SSa' and 'FIx' (the full
      // Unicode case mappings). The Dart VM gives 'ßa' and 'ﬁx'. dart2js
      // and dart2wasm call the toUpperCase of the JavaScript engine.
      expect(capitalize('ßa'), '${'ß'.toUpperCase()}a');
      expect(capitalize('ﬁx'), '${'ﬁ'.toUpperCase()}x');
      // ASCII names give the JavaScript result on every platform.
      expect(capitalize('backgroundColor'), 'BackgroundColor');
      expect(capitalize('zIndex'), 'ZIndex');
    });
  });

  group('defined', () {
    test('is false only for undefined', () {
      expect(defined(undefined), isFalse);
      expect(defined(null), isTrue);
      expect(defined(0), isTrue);
      expect(defined(''), isTrue);
    });
  });

  group('isFunction', () {
    test('is true for a Dart function', () {
      expect(isFunction(() => 1), isTrue);
      expect(isFunction(<String, Object?>{}), isFalse);
      expect(isFunction(null), isFalse);
      expect(isFunction(undefined), isFalse);
      expect(isFunction('f'), isFalse);
    });
  });

  group('setsEqual', () {
    test('compares string sets in any order', () {
      expect(setsEqual(<String>{}, <String>{}), isTrue);
      expect(setsEqual({'a', 'b'}, {'b', 'a'}), isTrue);
      expect(setsEqual({'a'}, {'a', 'b'}), isFalse);
    });
  });

  group('js-semantics-set-equality', () {
    test('respects the set equality policy', () {
      // Make the equality policy explicit: default sets handle NaN differently
      // in DDC. The helper must honor the supplied Set's comparator.
      Set<double> strict() =>
          HashSet<double>(equals: (a, b) => a == b, hashCode: (_) => 0)
            ..add(double.nan);
      expect(setsEqual(strict(), strict()), isFalse);
      // 0 and -0 are the same element, as in a JavaScript Set.
      expect(setsEqual({0.0}, {-0.0}), isTrue);
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
        [for (final type in types) isClickEvent(_Event(type))],
        [true, true, true, false, false, false, false],
      );
    });
  });
}
