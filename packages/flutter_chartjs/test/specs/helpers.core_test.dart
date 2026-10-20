// Ported from Chart.js v4.5.1+7169e651 test/specs/helpers.core.tests.js (MIT, Chart.js Contributors).
import 'dart:convert';
import 'dart:typed_data';

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs/src/helpers/helpers.core.dart' as helpers;
import 'package:flutter_chartjs/src/js/js_function.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/types/index.dart';
import 'package:test/test.dart';

// The spec names Chart.helpers `helpers`. A JavaScript object literal is a
// `Map<String, Object?>` and an array is a `List<Object?>` (Chart.js ADR
// 0006). Jasmine `toBe` is `same` for objects and `equals` for primitives.
// `not.toBeDefined()` and `toBe(undefined)` are `same(undefined)`.

/// A JavaScript object literal `{datasetIndex, index}`, passed as an
/// [ActiveDataPoint].
final class _Active implements ActiveDataPoint {
  const _Active(this.datasetIndex, this.index);

  @override
  final double datasetIndex;

  @override
  final double index;
}

/// The marker of an argument that a call did not pass.
const Object _none = Object();

/// One call that a [_Spy] recorded: `this` and the arguments.
typedef _Call = ({Object? object, List<Object?> args});

/// A `jasmine.createSpy`: a [JsFunction] that records `this` and up to four
/// arguments of each call.
final class _Spy {
  /// The recorded calls, as `spy.calls.all()`.
  final List<_Call> calls = [];

  /// The function value of the spy.
  late final JsFunction fn = JsFunction(_record);

  Object? _record(
    Object? self, [
    Object? a = _none,
    Object? b = _none,
    Object? c = _none,
    Object? d = _none,
  ]) {
    calls.add((
      object: self,
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
    group('noop', () {
      test('should be callable', () {
        expect(helpers.noop, isNotNull);
        expect(helpers.isFunction(helpers.noop), isTrue);
        // typeof helpers.noop.call: Dart calls a function value through
        // jsCall.
        expect(jsIsFunction(helpers.noop), isTrue);
      });
      test('should returns "undefined"', () {
        // helpers.noop(42): ported code calls a function value with jsCall.
        expect(jsCall(helpers.noop, [42]), same(undefined));
        expect(
          jsCall(helpers.noop, [42], thisArg: <String, Object?>{}),
          same(undefined),
        );
      });
    });

    group('isArray', () {
      test('should return true if value is an array', () {
        expect(helpers.isArray(<Object?>[]), isTrue);
        expect(helpers.isArray(<Object?>[42]), isTrue);
        // new Array()
        expect(helpers.isArray(List<Object?>.empty(growable: true)), isTrue);
        // Array.prototype: Dart has no prototypes.
        expect(helpers.isArray(Int8List(2)), isTrue);
        expect(helpers.isArray(Uint8List(0)), isTrue);
        expect(helpers.isArray(Uint8ClampedList.fromList([128, 244])), isTrue);
        expect(helpers.isArray(Int16List(0)), isTrue);
        expect(helpers.isArray(Uint16List(0)), isTrue);
        expect(helpers.isArray(Int32List(0)), isTrue);
        expect(helpers.isArray(Uint32List(0)), isTrue);
        expect(helpers.isArray(Float32List.fromList([1.2])), isTrue);
        expect(helpers.isArray(Float64List.fromList([])), isTrue);
      });
      test('should return false if value is not an array', () {
        // helpers.isArray(): the missing argument is undefined.
        expect(helpers.isArray(undefined), isFalse);
        expect(helpers.isArray(<String, Object?>{}), isFalse);
        expect(helpers.isArray(undefined), isFalse);
        expect(helpers.isArray(null), isFalse);
        expect(helpers.isArray(true), isFalse);
        expect(helpers.isArray(false), isFalse);
        expect(helpers.isArray(42), isFalse);
        expect(helpers.isArray('Array'), isFalse);
        // {__proto__: Array.prototype}: Dart has no prototypes. A Map is not
        // an array.
        expect(helpers.isArray(<String, Object?>{'__proto__': []}), isFalse);
      });
    });

    group('isObject', () {
      test('should return true if value is an object', () {
        expect(helpers.isObject(<String, Object?>{}), isTrue);
        expect(helpers.isObject(<String, Object?>{'a': 42}), isTrue);
        // new Object()
        expect(helpers.isObject(<String, Object?>{}), isTrue);
      });
      test('should return false if value is not an object', () {
        // helpers.isObject(): the missing argument is undefined.
        expect(helpers.isObject(undefined), isFalse);
        expect(helpers.isObject(undefined), isFalse);
        expect(helpers.isObject(null), isFalse);
        expect(helpers.isObject(true), isFalse);
        expect(helpers.isObject(false), isFalse);
        expect(helpers.isObject(42), isFalse);
        expect(helpers.isObject('Object'), isFalse);
        expect(helpers.isObject(<Object?>[]), isFalse);
        expect(helpers.isObject(<Object?>[42]), isFalse);
        // new Array()
        expect(helpers.isObject(List<Object?>.empty(growable: true)), isFalse);
        // new Date(): any date. Ported code never reads the wall clock.
        expect(helpers.isObject(DateTime.utc(2026)), isFalse);
      });
    });

    group('isFinite', () {
      test('should return true if value is a finite number', () {
        expect(helpers.isFinite(0), isTrue);
        // new Number(10): Dart has no Number wrapper objects.
        expect(helpers.isFinite(10), isTrue);
      });

      test('should return false if the value is infinite', () {
        expect(helpers.isFinite(double.infinity), isFalse);
        expect(helpers.isFinite(double.negativeInfinity), isFalse);
      });

      test('should return false if the value is not a number', () {
        expect(helpers.isFinite('a'), isFalse);
        expect(helpers.isFinite(<String, Object?>{}), isFalse);
      });
    });

    group('isNullOrUndef', () {
      test('should return true if value is null/undefined', () {
        expect(helpers.isNullOrUndef(null), isTrue);
        expect(helpers.isNullOrUndef(undefined), isTrue);
      });
      test('should return false if value is not null/undefined', () {
        expect(helpers.isNullOrUndef(true), isFalse);
        expect(helpers.isNullOrUndef(false), isFalse);
        expect(helpers.isNullOrUndef(''), isFalse);
        expect(helpers.isNullOrUndef('String'), isFalse);
        expect(helpers.isNullOrUndef(0), isFalse);
        expect(helpers.isNullOrUndef(<Object?>[]), isFalse);
        expect(helpers.isNullOrUndef(<String, Object?>{}), isFalse);
        expect(helpers.isNullOrUndef(<Object?>[42]), isFalse);
        // new Date(): any date. Ported code never reads the wall clock.
        expect(helpers.isNullOrUndef(DateTime.utc(2026)), isFalse);
      });
    });

    group('valueOrDefault', () {
      test('should return value if defined', () {
        final object = <String, Object?>{};
        final array = <Object?>[];

        expect(helpers.valueOrDefault<Object?>(null, 42), isNull);
        expect(helpers.valueOrDefault<Object?>(false, 42), false);
        expect(helpers.valueOrDefault<Object?>(object, 42), same(object));
        expect(helpers.valueOrDefault<Object?>(array, 42), same(array));
        expect(helpers.valueOrDefault<Object?>('', 42), '');
        expect(helpers.valueOrDefault<Object?>(0, 42), 0);
      });
      test('should return default if undefined', () {
        expect(helpers.valueOrDefault<Object?>(undefined, 42), 42);
        expect(
          helpers.valueOrDefault(_get(<String, Object?>{}, 'foo'), 42),
          42,
        );
      });
    });

    group('callback', () {
      test('should return undefined if fn is not a function', () {
        // helpers.callback(): the missing argument is undefined.
        expect(helpers.callback(undefined), same(undefined));
        expect(helpers.callback(null), same(undefined));
        expect(helpers.callback(42), same(undefined));
        expect(helpers.callback(<Object?>[]), same(undefined));
        expect(helpers.callback(<String, Object?>{}), same(undefined));
      });
      test('should call fn with the given args', () {
        final spy = _Spy();
        helpers.callback(spy.fn);
        helpers.callback(spy.fn, []);
        helpers.callback(spy.fn, ['foo']);
        helpers.callback(spy.fn, [42, 'bar']);

        expect(spy.argsFor(0), <Object?>[]);
        expect(spy.argsFor(1), <Object?>[]);
        expect(spy.argsFor(2), ['foo']);
        expect(spy.argsFor(3), [42, 'bar']);
      });
      test('should call fn with the given scope', () {
        final spy = _Spy();
        final scope = <String, Object?>{};

        helpers.callback(spy.fn);
        helpers.callback(spy.fn, [], null);
        // The explicit undefined is the upstream call.
        // ignore: avoid_redundant_argument_values
        helpers.callback(spy.fn, [], undefined);
        helpers.callback(spy.fn, [], scope);

        // Upstream expects `window` for the first three calls: the Jasmine
        // spy is a sloppy-mode function, so JavaScript makes a null or
        // undefined `this` the global object. Dart has no global object. A
        // JsFunction gets `this` as the caller gives it, as a strict-mode
        // function does (lib/src/js/js_function.dart). callback passes
        // thisArg unchanged, as fn.apply(thisArg, args) does.
        // DIVERGES(chartjs): js-semantics-strict-this, no global this.
        expect(spy.calls[0].object, same(undefined));
        expect(spy.calls[1].object, isNull);
        expect(spy.calls[2].object, same(undefined));
        expect(spy.calls[3].object, same(scope));
      });
      test('should return the value returned by fn', () {
        expect(helpers.callback(helpers.noop, [41]), same(undefined));
        expect(helpers.callback((double i) => i + 1, [41.0]), 42);
      });
    });

    group('each', () {
      test('should iterate over an array forward if reverse === false', () {
        final scope = <String, Object?>{};
        final scopes = <Object?>[];
        final items = <Object?>[];
        final keys = <Object?>[];

        helpers.each(
          <Object?>['foo', 'bar', 42],
          JsFunction((Object? self, Object? item, Object? key) {
            scopes.add(self);
            items.add(item);
            keys.add(key);
          }),
          scope,
        );

        expect(scopes, [scope, scope, scope]);
        expect(scopes, everyElement(same(scope)));
        expect(items, ['foo', 'bar', 42]);
        expect(keys, [0, 1, 2]);
      });
      test('should iterate over an array backward if reverse === true', () {
        final scope = <String, Object?>{};
        final scopes = <Object?>[];
        final items = <Object?>[];
        final keys = <Object?>[];

        helpers.each(
          <Object?>['foo', 'bar', 42],
          JsFunction((Object? self, Object? item, Object? key) {
            scopes.add(self);
            items.add(item);
            keys.add(key);
          }),
          scope,
          true,
        );

        expect(scopes, [scope, scope, scope]);
        expect(scopes, everyElement(same(scope)));
        expect(items, [42, 'bar', 'foo']);
        expect(keys, [2, 1, 0]);
      });
      test('should iterate over object properties', () {
        final scope = <String, Object?>{};
        final scopes = <Object?>[];
        // Upstream sets the keys on an array: `items[key] = item`.
        final items = <String, Object?>{};

        helpers.each(
          <String, Object?>{'a': 'foo', 'b': 'bar', 'c': 42},
          JsFunction((Object? self, Object? item, Object? key) {
            scopes.add(self);
            items[key! as String] = item;
          }),
          scope,
        );

        expect(scopes, [scope, scope, scope]);
        expect(scopes, everyElement(same(scope)));
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
        void fn() => fail('each called fn');
        expect(() => helpers.each(undefined, fn), returnsNormally);
        expect(() => helpers.each(null, fn), returnsNormally);
        expect(() => helpers.each(42, fn), returnsNormally);
      });
    });

    group('_elementsEqual', () {
      test('should return true if arrays are the same', () {
        expect(
          helpers.elementsEqual(
            [const _Active(0, 1), const _Active(0, 2)],
            [const _Active(0, 1), const _Active(0, 2)],
          ),
          isTrue,
        );
      });
      test('should return false if arrays are not the same', () {
        expect(helpers.elementsEqual([], [const _Active(0, 1)]), isFalse);
        expect(
          helpers.elementsEqual([const _Active(0, 2)], [const _Active(0, 1)]),
          isFalse,
        );
      });
    });

    group('clone', () {
      test('should clone primitive values', () {
        // helpers.clone(): the missing argument is undefined.
        expect(helpers.clone(undefined), same(undefined));
        expect(helpers.clone(null), isNull);
        expect(helpers.clone(true), true);
        expect(helpers.clone(42), 42);
        expect(helpers.clone('foo'), 'foo');
      });
      test('should perform a deep copy of arrays', () {
        final o0 = <String, Object?>{'a': 42};
        final o1 = <String, Object?>{'s': 's'};
        final a0 = <Object?>['bar'];
        final a1 = <Object?>[a0, o0, 2];
        void f0() {}
        final input = <Object?>[a1, o1, f0, 42, 'foo'];
        final output = helpers.clone(input)! as List<Object?>;

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
        final output = helpers.clone(input)! as Map<String, Object?>;

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
            helpers.merge(
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
        final result = helpers.merge(target, <String, Object?>{
          'a': 2,
          'b': 'foo',
        });
        expect(target, {'a': 2, 'b': 'foo'});
        expect(target, same(result));
      });
      test('should return target if not an object', () {
        final source = <String, Object?>{'a': 42};
        expect(helpers.merge(undefined, source), same(undefined));
        expect(helpers.merge(null, source), isNull);
        expect(helpers.merge('foo', source), 'foo');
        expect(helpers.merge(<Object?>['foo', 'bar'], source), ['foo', 'bar']);
      });
      test('should ignore sources which are not objects', () {
        expect(helpers.merge(<String, Object?>{'a': 42}), {'a': 42});
        expect(helpers.merge(<String, Object?>{'a': 42}, null), {'a': 42});
        expect(helpers.merge(<String, Object?>{'a': 42}, 42), {'a': 42});
      });
      test('should recursively overwrite target with source properties', () {
        expect(
          helpers.merge(
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
          helpers.merge(
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
          helpers.merge(
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
          helpers.merge(
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
          helpers.merge(
            <String, Object?>{'a': 42},
            <String, Object?>{
              'a': null,
            },
          ),
          {'a': null},
        );
        final result =
            helpers.merge(
                  <String, Object?>{'a': 42},
                  <String, Object?>{
                    'a': undefined,
                  },
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

        expect(helpers.merge(t0, <Object?>[s0, s1, s2]), {
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
            helpers.merge(<String, Object?>{}, <String, Object?>{
                  'a': a0,
                  'o': o0,
                })!
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
            helpers.mergeIf(
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
        final result = helpers.mergeIf(target, <String, Object?>{
          'a': 2,
          'b': 'foo',
        });
        expect(target, {'a': 1, 'b': 'foo'});
        expect(target, same(result));
      });
      test('should return target if not an object', () {
        final source = <String, Object?>{'a': 42};
        expect(helpers.mergeIf(undefined, source), same(undefined));
        expect(helpers.mergeIf(null, source), isNull);
        expect(helpers.mergeIf('foo', source), 'foo');
        expect(helpers.mergeIf(<Object?>['foo', 'bar'], source), [
          'foo',
          'bar',
        ]);
      });
      test('should ignore sources which are not objects', () {
        expect(helpers.mergeIf(<String, Object?>{'a': 42}), {'a': 42});
        expect(helpers.mergeIf(<String, Object?>{'a': 42}, null), {'a': 42});
        expect(helpers.mergeIf(<String, Object?>{'a': 42}, 42), {'a': 42});
      });
      test(
        'should recursively copy source properties in target only if they do '
        'not exist in target',
        () {
          expect(
            helpers.mergeIf(
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
            helpers.mergeIf(
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
            helpers.mergeIf(
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
            helpers.mergeIf(
              <String, Object?>{'a': 0},
              <String, Object?>{
                'a': <String, Object?>{'b': 2},
              },
            ),
            {'a': 0},
          );
          expect(
            helpers.mergeIf(
              <String, Object?>{'a': null},
              <String, Object?>{
                'a': 42,
              },
            ),
            {'a': null},
          );
          expect(
            helpers.mergeIf(
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

        expect(helpers.mergeIf(t0, <Object?>[s0, s1, s2]), {
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
            helpers.mergeIf(<String, Object?>{}, <String, Object?>{
                  'a': a0,
                  'o': o0,
                })!
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
        expect(helpers.resolveObjectKey(obj, ''), obj);
      });
      test('should resolve one level', () {
        final obj = <String, Object?>{
          'bool': true,
          'str': 'test',
          'int': 42,
          'obj': <String, Object?>{'name': 'object'},
        };
        expect(helpers.resolveObjectKey(obj, 'bool'), true);
        expect(helpers.resolveObjectKey(obj, 'str'), 'test');
        expect(helpers.resolveObjectKey(obj, 'int'), 42);
        expect(helpers.resolveObjectKey(obj, 'obj'), obj['obj']);
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
        expect(helpers.resolveObjectKey(obj, 'child.level'), 1);
        expect(helpers.resolveObjectKey(obj, 'child.child.level'), 2);
        expect(helpers.resolveObjectKey(obj, 'child.child.child.level'), 3);
      });
      test('should resolve circular reference', () {
        final root = <String, Object?>{};
        final child = <String, Object?>{'root': root};
        child['child'] = child;
        root['child'] = child;
        // Jasmine `toEqual` of the same object. The `equals` matcher does
        // not stop on a cycle, so the port tests identity.
        expect(helpers.resolveObjectKey(root, 'child'), same(child));
        expect(
          helpers.resolveObjectKey(root, 'child.child.child.child.child.child'),
          same(child),
        );
        expect(helpers.resolveObjectKey(root, 'child.child.root'), same(root));
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
        expect(helpers.resolveObjectKey(obj, 'child..level'), obj['child']);
        expect(helpers.resolveObjectKey(obj, 'child.child.level...'), 2);
        expect(helpers.resolveObjectKey(obj, '.'), obj);
        expect(helpers.resolveObjectKey(obj, '..'), obj);
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
        expect(helpers.resolveObjectKey(obj, 'level'), same(undefined));
        expect(helpers.resolveObjectKey(obj, 'child.level.a'), same(undefined));
      });
      test('should throw on invalid input', () {
        // The key parameter is a String, so these calls do not compile.
        // Function.apply makes each call dynamic, as the JavaScript call is.
        // The parameter type then throws a TypeError, as `key.split` does in
        // JavaScript.
        Object? resolve(Object? obj, Object? key) =>
            Function.apply(helpers.resolveObjectKey, [obj, key]);
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
          helpers.resolveObjectKey(<String, Object?>{
            'test.dot': 10,
          }, r'test\.dot'),
          10,
        );
        expect(
          helpers.resolveObjectKey(<String, Object?>{
            'test': <String, Object?>{'dot': 10},
          }, r'test\.dot'),
          same(undefined),
        );
      });
      test('should allow nested keys with a dot', () {
        expect(
          helpers.resolveObjectKey(<String, Object?>{
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
        expect(helpers.splitKey(''), ['']);
        expect(helpers.splitKey('test'), ['test']);
        const asciiWithoutDot =
            // The two parts are one string.
            // ignore: missing_whitespace_between_adjacent_strings
            ' !"#\$%&\'()*+,-/0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ'
            r'[\]^_`abcdefghijklmnopqrstuvwxyz{|}~';
        expect(helpers.splitKey(asciiWithoutDot), [asciiWithoutDot]);
      });

      test('should split on dot', () {
        expect(helpers.splitKey('test1.test2'), ['test1', 'test2']);
        expect(helpers.splitKey('a.b.c'), ['a', 'b', 'c']);
        expect(helpers.splitKey('a.b.'), ['a', 'b', '']);
        expect(helpers.splitKey('a..c'), ['a', '', 'c']);
      });

      test('should preserve escaped dot', () {
        expect(helpers.splitKey(r'test1\.test2'), ['test1.test2']);
        expect(helpers.splitKey(r'a\.b.c'), ['a.b', 'c']);
        expect(helpers.splitKey(r'a.b\.c'), ['a', 'b.c']);
        expect(helpers.splitKey(r'a.\.c'), ['a', '.c']);
      });
    });

    group('setsEqual', () {
      test('should handle set comparison', () {
        final a = <Object?>{1};
        final b = <Object?>{'1'};
        final c = <Object?>{1};

        expect(helpers.setsEqual(a, b), isFalse);
        expect(helpers.setsEqual(a, c), isTrue);
      });
    });
  });
}
