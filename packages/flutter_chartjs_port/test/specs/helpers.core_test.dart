// Ported from Chart.js v4.6.1 test/specs/helpers.core.tests.js (MIT, Chart.js Contributors).
import 'dart:convert';
import 'dart:typed_data';

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/chartjs_core.dart';
import 'package:test/test.dart';

// The spec names Chart.helpers `helpers`. A JavaScript object literal is a
// `Map<String, Object?>` and an array is a `List<Object?>` (Chart.js ADR
// 0043). Jasmine `toBe` is `same` for objects and `equals` for primitives.
// `not.toBeDefined()` and `toBe(undefined)` are `same(undefined)`.

/// A JavaScript object literal `{datasetIndex, index}`, an [ActiveElement]
/// with no element (row `adapt-native-active-element`).
ActiveElement _active(int datasetIndex, int index) =>
    ActiveElement(datasetIndex: datasetIndex, index: index);

/// The marker of an argument that a call did not pass.
const Object _none = Object();

/// One call that a [_Spy] recorded: `this` and the arguments.
typedef _Call = ({Object? object, List<Object?> args});

/// A `jasmine.createSpy`: a function that records up to four arguments of
/// each call. A Dart function has no `this` (Chart.js ADR 0173).
final class _Spy() {
  /// The recorded calls, as `spy.calls.all()`.
  final List<_Call> calls = [];

  /// The function value of the spy.
  late final Function fn = _record;

  Object? _record([
    Object? a = _none,
    Object? b = _none,
    Object? c = _none,
    Object? d = _none,
  ]) {
    calls.add((
      object: null,
      args: [a, b, c, d].where((arg) => !identical(arg, _none)).toList(),
    ));
    return undefined;
  }

  /// `spy.calls.argsFor(index)`.
  List<Object?> argsFor(int index) => calls[index].args;
}

/// `{}.foo`: a read of an absent key, which is undefined in JavaScript. A Map
/// read gives Dart `null`, so the port gives the sentinel for an absent key.
Object? _get(Map<String, Object?> object, String key) =>
    object.containsKey(key) ? object[key] : undefined;

void main() {
  setUpSpecs();
  group('Chart.helpers.core', () {
    // helpers.core.ts:11 `noop` is gone: a tooltip callback that is null
    // takes the built-in default (differences.md row
    // `adapt-tooltip-callback-objects`).
    group('noop', () {
      test(
        'should be callable',
        () {},
        skip: 'diverges: adapt-tooltip-callback-objects',
      );
      test(
        'should returns "undefined"',
        () {},
        skip: 'diverges: adapt-tooltip-callback-objects',
      );
    });

    group('isArray', () {
      test('should return true if value is an array', () {
        expect(isArray(<Object?>[]), isTrue);
        expect(isArray(<Object?>[42]), isTrue);
        // new Array()
        expect(isArray(List<Object?>.empty(growable: true)), isTrue);
        // Array.prototype: Dart has no prototypes.
        expect(isArray(Int8List(2)), isTrue);
        expect(isArray(Uint8List(0)), isTrue);
        expect(isArray(Uint8ClampedList.fromList([128, 244])), isTrue);
        expect(isArray(Int16List(0)), isTrue);
        expect(isArray(Uint16List(0)), isTrue);
        expect(isArray(Int32List(0)), isTrue);
        expect(isArray(Uint32List(0)), isTrue);
        expect(isArray(Float32List.fromList([1.2])), isTrue);
        expect(isArray(Float64List.fromList([])), isTrue);
      });
      test('should return false if value is not an array', () {
        // helpers.isArray(): the missing argument is undefined.
        expect(isArray(undefined), isFalse);
        expect(isArray(<String, Object?>{}), isFalse);
        expect(isArray(undefined), isFalse);
        expect(isArray(null), isFalse);
        expect(isArray(true), isFalse);
        expect(isArray(false), isFalse);
        expect(isArray(42), isFalse);
        expect(isArray('Array'), isFalse);
        // {__proto__: Array.prototype}: Dart has no prototypes. A Map is not
        // an array.
        expect(isArray(<String, Object?>{'__proto__': []}), isFalse);
      });
    });

    group('isObject', () {
      test('should return true if value is an object', () {
        expect(isObject(<String, Object?>{}), isTrue);
        expect(isObject(<String, Object?>{'a': 42}), isTrue);
        // new Object()
        expect(isObject(<String, Object?>{}), isTrue);
      });
      test('should return false if value is not an object', () {
        // helpers.isObject(): the missing argument is undefined.
        expect(isObject(undefined), isFalse);
        expect(isObject(undefined), isFalse);
        expect(isObject(null), isFalse);
        expect(isObject(true), isFalse);
        expect(isObject(false), isFalse);
        expect(isObject(42), isFalse);
        expect(isObject('Object'), isFalse);
        expect(isObject(<Object?>[]), isFalse);
        expect(isObject(<Object?>[42]), isFalse);
        // new Array()
        expect(isObject(List<Object?>.empty(growable: true)), isFalse);
        // new Date(): any date. Ported code never reads the wall clock.
        expect(isObject(DateTime.utc(2026)), isFalse);
      });
    });

    group('isFinite', () {
      test('should return true if value is a finite number', () {
        expect(isFinite(0), isTrue);
        // new Number(10): Dart has no Number wrapper objects.
        expect(isFinite(10), isTrue);
      });

      test('should return false if the value is infinite', () {
        expect(isFinite(double.infinity), isFalse);
        expect(isFinite(double.negativeInfinity), isFalse);
      });

      test('should return false if the value is not a number', () {
        expect(isFinite('a'), isFalse);
        expect(isFinite(<String, Object?>{}), isFalse);
      });
    });

    group('isNullOrUndef', () {
      test('should return true if value is null/undefined', () {
        expect(isNullOrUndef(null), isTrue);
        expect(isNullOrUndef(undefined), isTrue);
      });
      test('should return false if value is not null/undefined', () {
        expect(isNullOrUndef(true), isFalse);
        expect(isNullOrUndef(false), isFalse);
        expect(isNullOrUndef(''), isFalse);
        expect(isNullOrUndef('String'), isFalse);
        expect(isNullOrUndef(0), isFalse);
        expect(isNullOrUndef(<Object?>[]), isFalse);
        expect(isNullOrUndef(<String, Object?>{}), isFalse);
        expect(isNullOrUndef(<Object?>[42]), isFalse);
        // new Date(): any date. Ported code never reads the wall clock.
        expect(isNullOrUndef(DateTime.utc(2026)), isFalse);
      });
    });

    group('valueOrDefault', () {
      test('should return value if defined', () {
        final object = <String, Object?>{};
        final array = <Object?>[];

        expect(valueOrDefault<Object?>(null, 42), isNull);
        expect(valueOrDefault<Object?>(false, 42), false);
        expect(valueOrDefault<Object?>(object, 42), same(object));
        expect(valueOrDefault<Object?>(array, 42), same(array));
        expect(valueOrDefault<Object?>('', 42), '');
        expect(valueOrDefault<Object?>(0, 42), 0);
      });
      test('should return default if undefined', () {
        expect(valueOrDefault<Object?>(undefined, 42), 42);
        expect(valueOrDefault(_get(<String, Object?>{}, 'foo'), 42), 42);
      });
    });

    group('callback', () {
      test('should return undefined if fn is not a function', () {
        // helpers.callback(): the missing argument is undefined.
        expect(callback(undefined), same(undefined));
        expect(callback(null), same(undefined));
        expect(callback(42), same(undefined));
        expect(callback(<Object?>[]), same(undefined));
        expect(callback(<String, Object?>{}), same(undefined));
      });
      test('should call fn with the given args', () {
        final spy = _Spy();
        callback(spy.fn);
        callback(spy.fn, []);
        callback(spy.fn, ['foo']);
        callback(spy.fn, [42, 'bar']);

        expect(spy.argsFor(0), <Object?>[]);
        expect(spy.argsFor(1), <Object?>[]);
        expect(spy.argsFor(2), ['foo']);
        expect(spy.argsFor(3), [42, 'bar']);
      });
      test('should call fn with the given scope', () {
        // A Dart function has no `this`: callback has no thisArg.
        final spy = _Spy();
        callback(spy.fn);
        expect(spy.calls, hasLength(1));
      }, skip: 'diverges: adapt-option-function-types');
      test('should return the value returned by fn', () {
        // helpers.noop: an empty function, which returns undefined.
        // A Dart function takes the exact arguments (Chart.js ADR 0173).
        expect(callback((Object? _) => undefined, [41]), same(undefined));
        expect(callback((double i) => i + 1, [41.0]), 42);
      });
    });

    group('each', () {
      test('should iterate over an array forward if reverse === false', () {
        // DIVERGES(chartjs): adapt-option-function-types, no scope.
        final items = <Object?>[];
        final keys = <Object?>[];

        each<Object?, Object?>(<Object?>['foo', 'bar', 42], (item, key) {
          items.add(item);
          keys.add(key);
        });

        expect(items, ['foo', 'bar', 42]);
        expect(keys, [0, 1, 2]);
      });
      test('should iterate over an array backward if reverse === true', () {
        // DIVERGES(chartjs): adapt-option-function-types, no scope.
        final items = <Object?>[];
        final keys = <Object?>[];

        each<Object?, Object?>(<Object?>['foo', 'bar', 42], (item, key) {
          items.add(item);
          keys.add(key);
        }, true);

        expect(items, [42, 'bar', 'foo']);
        expect(keys, [2, 1, 0]);
      });
      test('should iterate over object properties', () {
        // DIVERGES(chartjs): adapt-option-function-types, no scope.
        // Upstream sets the keys on an array: `items[key] = item`.
        final items = <String, Object?>{};

        each<Object?, String>(
          <String, Object?>{'a': 'foo', 'b': 'bar', 'c': 42},
          (item, key) {
            items[key] = item;
          },
        );

        // jasmine.objectContaining({a: 'foo', b: 'bar', c: 42})
        expect(
          items,
          allOf(
            containsPair('a', 'foo'),
            containsPair('b', 'bar'),
            containsPair('c', 42),
          ),
        );
      });
      test('should not throw when called with a non iterable object', () {
        // helpers.each(x) passes no fn. Dart requires one: this fn fails the
        // test if each calls it.
        void fn(Object? _, Object? _) => fail('each called fn');
        expect(() => each(undefined, fn), returnsNormally);
        expect(() => each(null, fn), returnsNormally);
        expect(() => each(42, fn), returnsNormally);
      });
    });

    group('_elementsEqual', () {
      test('should return true if arrays are the same', () {
        expect(
          elementsEqual(
            [_active(0, 1), _active(0, 2)],
            [_active(0, 1), _active(0, 2)],
          ),
          isTrue,
        );
      });
      test('should return false if arrays are not the same', () {
        expect(elementsEqual([], [_active(0, 1)]), isFalse);
        expect(elementsEqual([_active(0, 2)], [_active(0, 1)]), isFalse);
      });
    });

    group('clone', () {
      test('should clone primitive values', () {
        // helpers.clone(): the missing argument is undefined.
        expect(clone(undefined), same(undefined));
        expect(clone(null), isNull);
        expect(clone(true), true);
        expect(clone(42), 42);
        expect(clone('foo'), 'foo');
      });
      test('should perform a deep copy of arrays', () {
        final o0 = <String, Object?>{'a': 42};
        final o1 = <String, Object?>{'s': 's'};
        final a0 = <Object?>['bar'];
        final a1 = <Object?>[a0, o0, 2];
        void f0() {}
        final input = <Object?>[a1, o1, f0, 42, 'foo'];
        final output = clone(input)! as List<Object?>;

        expect(output, input);
        expect(output, isNot(same(input)));
        expect(output[0], isNot(same(a1)));
        expect((output[0]! as List<Object?>)[0], isNot(same(a0)));
        expect(output[1], isNot(same(o1)));
      });
      test('should perform a deep copy of objects', () {
        final a0 = <Object?>['bar'];
        final a1 = <Object?>[1, 2, 3];
        final o0 = <String, Object?>{'a': a1, 'i': 42};
        void f0() {}
        final input = <String, Object?>{
          'o': o0,
          'a': a0,
          'f': f0,
          's': 'foo',
          'i': 42,
        };
        final output = clone(input)! as Map<String, Object?>;

        expect(output, input);
        expect(output, isNot(same(input)));
        expect(output['o'], isNot(same(o0)));
        expect((output['o']! as Map<String, Object?>)['a'], isNot(same(a1)));
        expect(output['a'], isNot(same(a0)));
      });
    });

    group('merge', () {
      test('should not allow prototype pollution', () {
        final test =
            merge(
                  <String, Object?>{},
                  jsonDecode('{"__proto__":{"polluted": true}}'),
                )!
                as Map<String, Object?>;
        // test.prototype: merge skips the key `__proto__` (isValidKey).
        expect(_get(test, 'prototype'), same(undefined));
        // Object.prototype.polluted: Dart has no shared prototype that a key
        // can change. Without the guard, merge copies `__proto__` as an own
        // key. Thus this expect checks the guard.
        expect(test.containsKey('__proto__'), isFalse);
      });
      test('should update target and return it', () {
        final target = <String, Object?>{'a': 1};
        final result = merge(target, <String, Object?>{'a': 2, 'b': 'foo'});
        expect(target, {'a': 2, 'b': 'foo'});
        expect(target, same(result));
      });
      test('should return target if not an object', () {
        final source = <String, Object?>{'a': 42};
        expect(merge(undefined, source), same(undefined));
        expect(merge(null, source), isNull);
        expect(merge('foo', source), 'foo');
        expect(merge(<Object?>['foo', 'bar'], source), ['foo', 'bar']);
      });
      test('should ignore sources which are not objects', () {
        expect(merge(<String, Object?>{'a': 42}), {'a': 42});
        expect(merge(<String, Object?>{'a': 42}, null), {'a': 42});
        expect(merge(<String, Object?>{'a': 42}, 42), {'a': 42});
      });
      test('should recursively overwrite target with source properties', () {
        expect(
          merge(
            <String, Object?>{
              'a': <String, Object?>{'b': 1},
            },
            <String, Object?>{
              'a': <String, Object?>{'c': 2},
            },
          ),
          {
            'a': {'b': 1, 'c': 2},
          },
        );
        expect(
          merge(
            <String, Object?>{
              'a': <String, Object?>{'b': 1},
            },
            <String, Object?>{
              'a': <String, Object?>{'b': 2},
            },
          ),
          {
            'a': {'b': 2},
          },
        );
        expect(
          merge(
            <String, Object?>{
              'a': <Object?>[1, 2],
            },
            <String, Object?>{
              'a': <Object?>[3, 4],
            },
          ),
          {
            'a': [3, 4],
          },
        );
        expect(
          merge(
            <String, Object?>{'a': 42},
            <String, Object?>{
              'a': <String, Object?>{'b': 0},
            },
          ),
          {
            'a': {'b': 0},
          },
        );
        expect(
          merge(<String, Object?>{'a': 42}, <String, Object?>{'a': null}),
          {'a': null},
        );
        final result =
            merge(
                  <String, Object?>{'a': 42},
                  <String, Object?>{'a': undefined},
                )!
                as Map<String, Object?>;
        expect(result, {'a': same(undefined)});
        expect(result.containsKey('a'), isTrue);
      });
      test('should merge multiple sources in the correct order', () {
        final t0 = <String, Object?>{
          'a': <String, Object?>{
            'b': 1,
            'c': <Object?>[1, 2],
          },
        };
        final s0 = <String, Object?>{
          'a': <String, Object?>{'d': 3},
          'e': <String, Object?>{'f': 4},
        };
        final s1 = <String, Object?>{
          'a': <String, Object?>{'b': 5},
        };
        final s2 = <String, Object?>{
          'a': <String, Object?>{
            'c': <Object?>[6, 7],
          },
          'e': 'foo',
        };

        expect(merge(t0, <Object?>[s0, s1, s2]), {
          'a': {
            'b': 5,
            'c': [6, 7],
            'd': 3,
          },
          'e': 'foo',
        });
      });
      test('should deep copy merged values from sources', () {
        final a0 = <Object?>['foo'];
        final a1 = <Object?>[1, 2, 3];
        final o0 = <String, Object?>{'a': a1, 'i': 42};
        final output =
            merge(<String, Object?>{}, <String, Object?>{'a': a0, 'o': o0})!
                as Map<String, Object?>;

        expect(output, {'a': a0, 'o': o0});
        expect(output['a'], isNot(same(a0)));
        expect(output['o'], isNot(same(o0)));
        expect((output['o']! as Map<String, Object?>)['a'], isNot(same(a1)));
      });
    });

    group('mergeIf', () {
      test('should not allow prototype pollution', () {
        final test =
            mergeIf(
                  <String, Object?>{},
                  jsonDecode('{"__proto__":{"polluted": true}}'),
                )!
                as Map<String, Object?>;
        // test.prototype: mergeIf skips the key `__proto__` (isValidKey).
        expect(_get(test, 'prototype'), same(undefined));
        // Object.prototype.polluted: Dart has no shared prototype that a key
        // can change. Without the guard, mergeIf copies `__proto__` as an own
        // key. Thus this expect checks the guard.
        expect(test.containsKey('__proto__'), isFalse);
      });
      test('should update target and return it', () {
        final target = <String, Object?>{'a': 1};
        final result = mergeIf(target, <String, Object?>{'a': 2, 'b': 'foo'});
        expect(target, {'a': 1, 'b': 'foo'});
        expect(target, same(result));
      });
      test('should return target if not an object', () {
        final source = <String, Object?>{'a': 42};
        expect(mergeIf(undefined, source), same(undefined));
        expect(mergeIf(null, source), isNull);
        expect(mergeIf('foo', source), 'foo');
        expect(mergeIf(<Object?>['foo', 'bar'], source), ['foo', 'bar']);
      });
      test('should ignore sources which are not objects', () {
        expect(mergeIf(<String, Object?>{'a': 42}), {'a': 42});
        expect(mergeIf(<String, Object?>{'a': 42}, null), {'a': 42});
        expect(mergeIf(<String, Object?>{'a': 42}, 42), {'a': 42});
      });
      test(
        'should recursively copy source properties in target only if they do '
        'not exist in target',
        () {
          expect(
            mergeIf(
              <String, Object?>{
                'a': <String, Object?>{'b': 1},
              },
              <String, Object?>{
                'a': <String, Object?>{'c': 2},
              },
            ),
            {
              'a': {'b': 1, 'c': 2},
            },
          );
          expect(
            mergeIf(
              <String, Object?>{
                'a': <String, Object?>{'b': 1},
              },
              <String, Object?>{
                'a': <String, Object?>{'b': 2},
              },
            ),
            {
              'a': {'b': 1},
            },
          );
          expect(
            mergeIf(
              <String, Object?>{
                'a': <Object?>[1, 2],
              },
              <String, Object?>{
                'a': <Object?>[3, 4],
              },
            ),
            {
              'a': [1, 2],
            },
          );
          expect(
            mergeIf(
              <String, Object?>{'a': 0},
              <String, Object?>{
                'a': <String, Object?>{'b': 2},
              },
            ),
            {'a': 0},
          );
          expect(
            mergeIf(<String, Object?>{'a': null}, <String, Object?>{'a': 42}),
            {'a': null},
          );
          expect(
            mergeIf(
              <String, Object?>{'a': undefined},
              <String, Object?>{'a': 42},
            ),
            {'a': same(undefined)},
          );
        },
      );
      test('should merge multiple sources in the correct order', () {
        final t0 = <String, Object?>{
          'a': <String, Object?>{
            'b': 1,
            'c': <Object?>[1, 2],
          },
        };
        final s0 = <String, Object?>{
          'a': <String, Object?>{'d': 3},
          'e': <String, Object?>{'f': 4},
        };
        final s1 = <String, Object?>{
          'a': <String, Object?>{'b': 5},
        };
        final s2 = <String, Object?>{
          'a': <String, Object?>{
            'c': <Object?>[6, 7],
          },
          'e': 'foo',
        };

        expect(mergeIf(t0, <Object?>[s0, s1, s2]), {
          'a': {
            'b': 1,
            'c': [1, 2],
            'd': 3,
          },
          'e': {'f': 4},
        });
      });
      test('should deep copy merged values from sources', () {
        final a0 = <Object?>['foo'];
        final a1 = <Object?>[1, 2, 3];
        final o0 = <String, Object?>{'a': a1, 'i': 42};
        final output =
            mergeIf(<String, Object?>{}, <String, Object?>{'a': a0, 'o': o0})!
                as Map<String, Object?>;

        expect(output, {'a': a0, 'o': o0});
        expect(output['a'], isNot(same(a0)));
        expect(output['o'], isNot(same(o0)));
        expect((output['o']! as Map<String, Object?>)['a'], isNot(same(a1)));
      });
    });

    group('resolveObjectKey', () {
      test('should resolve empty key to root object', () {
        final obj = <String, Object?>{'test': true};
        expect(resolveObjectKey(obj, ''), obj);
      });
      test('should resolve one level', () {
        final obj = <String, Object?>{
          'bool': true,
          'str': 'test',
          'int': 42,
          'obj': <String, Object?>{'name': 'object'},
        };
        expect(resolveObjectKey(obj, 'bool'), true);
        expect(resolveObjectKey(obj, 'str'), 'test');
        expect(resolveObjectKey(obj, 'int'), 42);
        expect(resolveObjectKey(obj, 'obj'), obj['obj']);
      });
      test('should resolve multiple levels', () {
        final obj = <String, Object?>{
          'child': <String, Object?>{
            'level': 1,
            'child': <String, Object?>{
              'level': 2,
              'child': <String, Object?>{'level': 3},
            },
          },
        };
        expect(resolveObjectKey(obj, 'child.level'), 1);
        expect(resolveObjectKey(obj, 'child.child.level'), 2);
        expect(resolveObjectKey(obj, 'child.child.child.level'), 3);
      });
      test('should resolve circular reference', () {
        final root = <String, Object?>{};
        final child = <String, Object?>{'root': root};
        child['child'] = child;
        root['child'] = child;
        // Jasmine `toEqual` of the same object. The `equals` matcher does
        // not stop on a cycle, so the port tests identity.
        expect(resolveObjectKey(root, 'child'), same(child));
        expect(
          resolveObjectKey(root, 'child.child.child.child.child.child'),
          same(child),
        );
        expect(resolveObjectKey(root, 'child.child.root'), same(root));
      });
      test('should break at empty key', () {
        final obj = <String, Object?>{
          'child': <String, Object?>{
            'level': 1,
            'child': <String, Object?>{
              'level': 2,
              'child': <String, Object?>{'level': 3},
            },
          },
        };
        expect(resolveObjectKey(obj, 'child..level'), obj['child']);
        expect(resolveObjectKey(obj, 'child.child.level...'), 2);
        expect(resolveObjectKey(obj, '.'), obj);
        expect(resolveObjectKey(obj, '..'), obj);
      });
      test('should resolve undefined', () {
        final obj = <String, Object?>{
          'child': <String, Object?>{
            'level': 1,
            'child': <String, Object?>{
              'level': 2,
              'child': <String, Object?>{'level': 3},
            },
          },
        };
        expect(resolveObjectKey(obj, 'level'), same(undefined));
        expect(resolveObjectKey(obj, 'child.level.a'), same(undefined));
      });
      test('should throw on invalid input', () {
        // The key parameter is a String, so these calls do not compile.
        // Function.apply makes each call dynamic, as the JavaScript call is.
        // The parameter type then throws a TypeError, as `key.split` does in
        // JavaScript.
        Object? resolve(Object? obj, Object? key) =>
            Function.apply(resolveObjectKey, [obj, key]);
        expect(() => resolve(undefined, undefined), throwsA(isA<TypeError>()));
        expect(
          () => resolve(<String, Object?>{}, null),
          throwsA(isA<TypeError>()),
        );
        expect(
          () => resolve(<String, Object?>{}, false),
          throwsA(isA<TypeError>()),
        );
        expect(
          () => resolve(<String, Object?>{}, true),
          throwsA(isA<TypeError>()),
        );
        expect(
          () => resolve(<String, Object?>{}, 1),
          throwsA(isA<TypeError>()),
        );
      });
      test('should allow escaping dot symbol', () {
        expect(
          resolveObjectKey(<String, Object?>{'test.dot': 10}, r'test\.dot'),
          10,
        );
        expect(
          resolveObjectKey(<String, Object?>{
            'test': <String, Object?>{'dot': 10},
          }, r'test\.dot'),
          same(undefined),
        );
      });
      test('should allow nested keys with a dot', () {
        expect(
          resolveObjectKey(<String, Object?>{
            'a': <String, Object?>{
              'bb.ccc': 'works',
              'bb': <String, Object?>{'ccc': 'fails'},
            },
          }, r'a.bb\.ccc'),
          'works',
        );
      });
    });

    group('_splitKey', () {
      test('should return array with one entry for string without a dot', () {
        expect(splitKey(''), ['']);
        expect(splitKey('test'), ['test']);
        const asciiWithoutDot =
            // The two parts are one string.
            // ignore: missing_whitespace_between_adjacent_strings
            ' !"#\$%&\'()*+,-/0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ'
            r'[\]^_`abcdefghijklmnopqrstuvwxyz{|}~';
        expect(splitKey(asciiWithoutDot), [asciiWithoutDot]);
      });

      test('should split on dot', () {
        expect(splitKey('test1.test2'), ['test1', 'test2']);
        expect(splitKey('a.b.c'), ['a', 'b', 'c']);
        expect(splitKey('a.b.'), ['a', 'b', '']);
        expect(splitKey('a..c'), ['a', '', 'c']);
      });

      test('should preserve escaped dot', () {
        expect(splitKey(r'test1\.test2'), ['test1.test2']);
        expect(splitKey(r'a\.b.c'), ['a.b', 'c']);
        expect(splitKey(r'a.b\.c'), ['a', 'b.c']);
        expect(splitKey(r'a.\.c'), ['a', '.c']);
      });
    });

    group('setsEqual', () {
      test('should handle set comparison', () {
        final a = <Object?>{1};
        final b = <Object?>{'1'};
        final c = <Object?>{1};

        expect(setsEqual(a, b), isFalse);
        expect(setsEqual(a, c), isTrue);
      });
    });
  });
}
