// Original code, not ported from Chart.js: helpers.config cases with no spec.
import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/src/core/core.interaction.dart'
    show InteractionAxis, NearestInteractionMode, XInteractionMode;
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show clone, each, merge, mergeIf, resolveObjectKey;
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/option_scope.dart'
    show ScopeRoute;
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show ChartOptionsScope, InteractionOptionsScope;
import 'package:flutter_chartjs_port/src/types/chart_paint.dart'
    show ChartPaint;
import 'package:flutter_chartjs_port/src/types/chart_text_style.dart';
import 'package:flutter_chartjs_port/src/types/index.dart';
import 'package:test/test.dart';

// Upstream behavior that test/specs/helpers.config.tests.js does not check
// (AGENTS.md rule 3). The expected values come from src/helpers/helpers.config.ts
// and src/helpers/helpers.core.ts at v4.5.1, with the types stripped by
// node:module, in Node.js v24.12.0 on x64, unless a test says that it pins a
// difference of the port.
//
// The group "null versus undefined" holds the resolver tests of Chart.js ADR
// 0043 ("Tests"). A key of a scope has three states: absent, the undefined
// sentinel and Dart null (JS null). For each resolver path, the resolution
// reads an absent key and the sentinel alike, and null stops it. mergeIf,
// _cached and the key enumeration test own-key presence, so they keep the
// absent key and the sentinel apart.

/// A scope with the key `x` in one of the three states.
typedef _State = ({String name, Map<String, Object?> Function() scope});

/// The three states of the key `x`.
final List<_State> _states = [
  (name: 'absent', scope: () => <String, Object?>{}),
  (name: 'undefined', scope: () => <String, Object?>{'x': undefined}),
  (name: 'null', scope: () => <String, Object?>{'x': null}),
];

/// `proxy.key` for a value whose static type is `Object?`.
Object? _read(Object? object, String key) => jsGet(object, key);

/// `context.index * 10` of a scriptable option.
Object? _tenTimesIndex(Object? ctx) => jsToNumber(_read(ctx, 'index')) * 10;

/// The `parse` result of [_Scale]: the raw value and the index.
typedef _Parsed = (Object?, double?);

/// A scale whose `parse` returns its arguments.
final class _Scale implements Scale {
  @override
  Object? parse(Object? raw, [double? index]) => (raw, index);

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A chart meta with an index scale.
final class _Meta implements ChartMeta {
  _Meta(this.iScale);

  @override
  final Scale? iScale;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A dataset controller with the `_parsing` option.
final class _Controller implements DatasetController {
  _Controller(this.parsing);

  @override
  final Object? parsing;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('null versus undefined', () {
    group('plain get', () {
      final expected = {'absent': 'def', 'undefined': 'def', 'null': null};
      for (final state in _states) {
        test(state.name, () {
          final resolver = createResolver([
            state.scope(),
            <String, Object?>{'x': 'def'},
          ]);
          expect(resolver['x'], expected[state.name]);
        });
      }
    });

    group('prefixed get', () {
      final expected = {'absent': 'hdef', 'undefined': 'hdef', 'null': null};
      for (final state in _states) {
        test(state.name, () {
          final scope = state.scope();
          final options = <String, Object?>{
            if (scope.containsKey('x')) 'hoverX': scope['x'],
          };
          final resolver = createResolver(
            [
              options,
              <String, Object?>{'hoverX': 'hdef', 'x': 'def'},
            ],
            ['hover', ''],
          );
          expect(resolver['x'], expected[state.name]);
        });
      }
    });

    group('_fallback route', () {
      final expected = {'absent': 'fall', 'undefined': 'fall', 'null': null};
      for (final state in _states) {
        test(state.name, () {
          final scope = state.scope();
          final hover = <String, Object?>{
            if (scope.containsKey('x')) 'mode': scope['x'],
          };
          final resolver = createResolver([
            <String, Object?>{'hover': hover},
            <String, Object?>{
              'interaction': <String, Object?>{'mode': 'fall'},
              'hover': <String, Object?>{'_fallback': 'interaction'},
            },
          ]);
          expect(_read(resolver['hover'], 'mode'), expected[state.name]);
        });
      }
    });

    group('_fallback of a descriptor', () {
      // A JS null _fallback is a fallback key. createSubResolver gives false.
      for (final state in _states) {
        test(state.name, () {
          final scope = state.scope();
          final descriptors = <String, Object?>{
            'sub': <String, Object?>{
              if (scope.containsKey('x')) '_fallback': scope['x'],
            },
          };
          final resolver = createResolver([
            <String, Object?>{
              'sub': <String, Object?>{'a': 1},
            },
            <String, Object?>{
              'root': <String, Object?>{'b': 2},
              'sub': <String, Object?>{},
            },
            descriptors,
          ]);
          final sub = resolver['sub'];
          if (state.name == 'null') {
            expect(sub, false);
          } else {
            expect(sub, isA<Resolver>());
            expect(_read(sub, 'a'), 1);
            expect((sub! as Resolver).scopes, hasLength(3));
          }
        });
      }
    });

    group('_fallback of the root scope', () {
      for (final state in _states) {
        test(state.name, () {
          final scope = state.scope();
          final resolver = createResolver([
            <String, Object?>{
              if (scope.containsKey('x')) '_fallback': scope['x'],
              'sub': <String, Object?>{'a': 1},
            },
            <String, Object?>{'b': 'root'},
          ]);
          final sub = resolver['sub'];
          if (state.name == 'null') {
            expect(resolver.fallback, isNull);
            expect(sub, false);
          } else {
            expect(resolver.fallback, same(undefined));
            expect(_read(sub, 'a'), 1);
            expect(_read(sub, 'b'), same(undefined));
          }
        });
      }

      test('the fallback argument: undefined resolves, null is a value', () {
        final scopes = [
          <String, Object?>{'_fallback': 'root'},
        ];
        expect(createResolver(scopes).fallback, 'root');
        // The explicit undefined is the case under test.
        // ignore: avoid_redundant_argument_values
        expect(createResolver(scopes, [''], null, undefined).fallback, 'root');
        expect(createResolver(scopes, [''], null, null).fallback, isNull);
      });
    });

    group('scriptable', () {
      final expected = {'absent': 10, 'undefined': 10, 'null': null};
      for (final state in _states) {
        test(state.name, () {
          final opts = attachContext(
            createResolver([
              state.scope(),
              <String, Object?>{'x': _tenTimesIndex},
            ]),
            {'index': 1},
          );
          expect(opts['x'], expected[state.name]);
        });
      }

      test('a result of undefined or null is the value', () {
        final undefinedResult = attachContext(
          createResolver([
            <String, Object?>{'x': () => undefined},
            <String, Object?>{'x': 'def'},
          ]),
          {'index': 1},
        );
        expect(undefinedResult['x'], same(undefined));
        final nullResult = attachContext(
          createResolver([
            <String, Object?>{'x': () => null},
            <String, Object?>{'x': 'def'},
          ]),
          {'index': 1},
        );
        expect(nullResult['x'], isNull);
      });
    });

    group('indexable', () {
      final expected = {'absent': 'b', 'undefined': 'b', 'null': null};
      for (final state in _states) {
        test(state.name, () {
          final opts = attachContext(
            createResolver([
              state.scope(),
              <String, Object?>{
                'x': ['a', 'b'],
              },
            ]),
            {'index': 1},
          );
          expect(opts['x'], expected[state.name]);
        });
      }

      test('an element of undefined or null is the value', () {
        final undefinedElement = attachContext(
          createResolver([
            <String, Object?>{
              'x': ['a', undefined],
            },
            <String, Object?>{'x': 'def'},
          ]),
          {'index': 1},
        );
        expect(undefinedElement['x'], same(undefined));
        final nullElement = attachContext(
          createResolver([
            <String, Object?>{
              'x': ['a', null],
            },
            <String, Object?>{'x': 'def'},
          ]),
          {'index': 1},
        );
        expect(nullElement['x'], isNull);
      });

      test('context.index: absent and undefined skip, null is index 0', () {
        Object? read(Map<String, Object?> context) => attachContext(
          createResolver([
            <String, Object?>{
              'x': ['a', 'b'],
            },
          ]),
          context,
        )['x'];

        expect(read({}), ['a', 'b']);
        expect(read({'index': undefined}), ['a', 'b']);
        expect(read({'index': null}), 'a');
      });

      test('context.index that is not an integer index', () {
        Object? read(Object? index) => attachContext(
          createResolver([
            <String, Object?>{
              'x': ['a', 'b'],
            },
          ]),
          {'index': index},
        )['x'];

        expect(read(1.5), same(undefined));
        expect(read(-1), same(undefined));
        expect(read('3'), 'b');
        expect(read(-0.0), 'a');
      });
    });

    group('_cached', () {
      final expected = {
        'absent': undefined,
        'undefined': undefined,
        'null': null,
      };
      for (final state in _states) {
        test(state.name, () {
          final defaults = <String, Object?>{};
          final resolver = createResolver([state.scope(), defaults]);
          final first = resolver['x'];
          defaults['x'] = 'late';
          // The cache owns the resolved value, also undefined.
          expect(first, same(expected[state.name]));
          expect(resolver['x'], same(expected[state.name]));
        });
      }
    });

    group('sub-resolver', () {
      for (final state in _states) {
        test(state.name, () {
          final resolver = createResolver([
            state.scope(),
            <String, Object?>{
              'x': <String, Object?>{'a': 1},
            },
          ]);
          if (state.name == 'null') {
            expect(resolver['x'], isNull);
          } else {
            expect(resolver['x'], isA<Resolver>());
            expect(_read(resolver['x'], 'a'), 1);
          }
        });

        test('${state.name} key in a sub-scope', () {
          final scope = state.scope();
          final resolver = createResolver([
            <String, Object?>{
              'x': <String, Object?>{
                if (scope.containsKey('x')) 'a': scope['x'],
              },
            },
            <String, Object?>{
              'x': <String, Object?>{'a': 1},
            },
          ]);
          expect(
            _read(resolver['x'], 'a'),
            state.name == 'null' ? isNull : 1,
          );
        });

        test('${state.name} with a context', () {
          final opts = attachContext(
            createResolver([
              state.scope(),
              <String, Object?>{
                'x': <String, Object?>{'a': 1},
              },
            ]),
            {'index': 1},
          );
          if (state.name == 'null') {
            expect(opts['x'], isNull);
          } else {
            expect(opts['x'], isA<ContextResolver>());
            expect(_read(opts['x'], 'a'), 1);
          }
        });
      }
    });

    group('ownKeys and enumeration', () {
      // getOwnPropertyNames, Object.keys, `in` and hasOwnProperty.
      final expected = {
        'absent': (names: ['y'], keys: <String>[], has: false),
        'undefined': (names: ['x', 'y'], keys: ['x'], has: true),
        'null': (names: ['x', 'y'], keys: ['x'], has: true),
      };
      final expectedAllKeys = {
        'absent': (names: ['y'], keys: ['y'], has: false),
        'undefined': (names: ['y', 'x'], keys: ['y', 'x'], has: true),
        'null': (names: ['y', 'x'], keys: ['y', 'x'], has: true),
      };
      for (final state in _states) {
        test(state.name, () {
          final want = expected[state.name]!;
          final resolver = createResolver([
            state.scope(),
            <String, Object?>{'y': 1},
          ]);
          expect(resolver.ownKeys(), want.names);
          expect(jsObjectKeys(resolver), want.keys);
          expect(resolver.hasProperty('x'), want.has);
          expect(resolver.hasOwnProperty('x'), want.has);

          final opts = attachContext(
            createResolver([
              state.scope(),
              <String, Object?>{'y': 1},
            ]),
            {},
          );
          expect(opts.ownKeys(), want.names);
          expect(jsObjectKeys(opts), want.keys);
          expect(opts.hasProperty('x'), want.has);
          expect(opts.hasOwnProperty('x'), want.has);
        });

        test('${state.name} with allKeys', () {
          final want = expectedAllKeys[state.name]!;
          final opts = attachContext(
            createResolver([
              <String, Object?>{'y': 1},
              state.scope(),
            ]),
            {},
            undefined,
            const DescriptorDefaults(
              scriptable: true,
              indexable: true,
              allKeys: true,
            ),
          );
          expect(opts.ownKeys(), want.names);
          expect(jsObjectKeys(opts), want.keys);
          expect(opts.hasProperty('x'), want.has);
          expect(opts.hasOwnProperty('x'), want.has);
        });
      }
    });

    group('mergeIf', () {
      // A stored sentinel blocks the merge (Chart.js ADR 0043, "Tests").
      final expected = {'absent': 1, 'undefined': undefined, 'null': null};
      for (final state in _states) {
        test(state.name, () {
          final target = state.scope();
          mergeIf(target, <String, Object?>{'x': 1});
          expect(target.containsKey('x'), isTrue);
          expect(target['x'], same(expected[state.name]));
        });
      }
    });

    group('set', () {
      for (final value in [undefined, null]) {
        test('$value', () {
          final options = <String, Object?>{};
          final resolver = createResolver([
            options,
            <String, Object?>{'x': 'def'},
          ]);
          resolver['x'] = value;
          expect(options.containsKey('x'), isTrue);
          expect(options['x'], same(value));
          expect(resolver['x'], same(value));
          expect(resolver.ownKeys(), ['x']);
        });
      }
    });

    group('_scriptable descriptor', () {
      for (final state in _states) {
        test(state.name, () {
          String fn() => 'called';
          final scope = state.scope();
          final opts = attachContext(
            createResolver([
              <String, Object?>{
                if (scope.containsKey('x')) '_scriptable': scope['x'],
                'x': fn,
              },
              <String, Object?>{'_scriptable': true},
            ]),
            {'index': 1},
          );
          expect(opts['x'], state.name == 'null' ? same(fn) : 'called');
        });
      }

      test('a null _allKeys is a value', () {
        final descriptor = descriptors(
          createResolver([
            <String, Object?>{'_allKeys': null},
          ]),
        );
        expect(descriptor.allKeys, isNull);
        expect(descriptor.scriptable, true);
        expect(descriptor.indexable, true);
      });
    });
  });

  group('scope lists', () {
    test('an array of objects is a scope of its items', () {
      final options = <String, Object?>{
        'items': [
          <String, Object?>{'test': true},
          <String, Object?>{'b': 2},
        ],
      };
      final opts = attachContext(
        createResolver([
          options,
          <String, Object?>{
            'items': <String, Object?>{
              '_fallback': (Object? p, Object? v) => undefined,
            },
          },
        ]),
        {'d': 1},
      );
      final item0 = (opts['items']! as List<Object?>)[0]! as ContextResolver;
      expect(item0.ownKeys(), ['test', '0', '1']);
      expect(jsObjectKeys(item0), ['test']);
      expect(item0['length'], 2);
    });

    test('set through a sub-resolver creates the sub-object', () {
      final options = <String, Object?>{};
      final resolver = createResolver([
        options,
        <String, Object?>{
          'sub': <String, Object?>{'x': 1},
        },
      ]);
      (resolver['sub']! as Resolver)['y'] = 2;
      expect(options, {
        'sub': {'y': 2},
      });
    });
  });

  group('Object.keys of a resolver', () {
    // jsObjectKeys is Object.keys: the ownKeys trap result filtered through
    // the getOwnPropertyDescriptor trap, with no move of the array-index
    // keys. each, clone and merge of helpers.core enumerate with it.
    List<Object?> eachKeys(Object? object) {
      final seen = <Object?>[];
      each(object, (Object? value, Object? key) => seen.add(key));
      return seen;
    }

    test('a resolver gives the own keys of its first scope', () {
      final resolver = createResolver([
        <String, Object?>{'a': 1},
        <String, Object?>{'b': 2, '1': 3},
      ]);
      expect(resolver.ownKeys(), ['a', '1', 'b']);
      expect(jsObjectKeys(resolver), ['a']);
      expect(eachKeys(resolver), ['a']);
      expect(clone(resolver), {'a': 1});
    });

    test('the array-index keys keep the trap order', () {
      final resolver = createResolver([
        <String, Object?>{'b': 1, '1': 2},
        <String, Object?>{'0': 1},
      ]);
      expect(jsObjectKeys(resolver), ['1', 'b']);

      final allKeys = createResolver([
        <String, Object?>{'b': 1, '2': 1},
        <String, Object?>{'a': 1, '1': 1},
      ]);
      expect(allKeys.ownKeys(), ['2', 'b', '1', 'a']);
      expect(jsObjectKeys(allKeys), ['2', 'b']);
      final opts = attachContext(
        allKeys,
        {},
        undefined,
        const DescriptorDefaults(
          scriptable: true,
          indexable: true,
          allKeys: true,
        ),
      );
      expect(jsObjectKeys(opts), ['2', 'b', '1', 'a']);
    });

    test('a context resolver gives the own keys of its proxy', () {
      final opts = attachContext(
        createResolver([
          <String, Object?>{'a': 1},
          <String, Object?>{'b': 2},
        ]),
        {},
      );
      expect(opts.ownKeys(), ['a', 'b']);
      expect(jsObjectKeys(opts), ['a']);
      expect(eachKeys(opts), ['a']);
    });

    test('each, clone and merge of a sub-resolver skip the later scopes', () {
      // chart.options.scales has defaults.scales in its scopes
      // (core.controller.js:308, :328).
      final resolver = createResolver([
        <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{'a': 1},
          },
        },
        <String, Object?>{
          'scales': <String, Object?>{
            'linear': <String, Object?>{'type': 'linear'},
          },
        },
      ]);
      final scales = resolver['scales'];
      expect(jsObjectKeys(scales), ['x']);
      expect(eachKeys(scales), ['x']);
      expect(clone(scales), {
        'x': {'a': 1},
      });
      expect(merge(<String, Object?>{}, scales), {
        'x': {'a': 1},
      });

      final contextScales = attachContext(resolver, {})['scales'];
      expect(jsObjectKeys(contextScales), ['x']);
      expect(clone(contextScales), {
        'x': {'a': 1},
      });
    });
  });

  group('resolveObjectKey of a resolver', () {
    // The property read goes through the get trap, which also finds the
    // prefixed keys.
    test('finds a prefixed key', () {
      final resolver = createResolver(
        [
          <String, Object?>{
            'hoverColor': const ChartPaint.solid(
              ui.Color.fromRGBO(255, 0, 0, 1),
            ),
          },
        ],
        ['hover', ''],
      );
      expect(
        resolveObjectKey(resolver, 'color'),
        const ChartPaint.solid(ui.Color.fromRGBO(255, 0, 0, 1)),
      );
      expect(
        resolveObjectKey({'o': resolver}, 'o.color'),
        const ChartPaint.solid(ui.Color.fromRGBO(255, 0, 0, 1)),
      );
      expect(
        resolveObjectKey(attachContext(resolver, {}), 'color'),
        const ChartPaint.solid(ui.Color.fromRGBO(255, 0, 0, 1)),
      );
      expect(resolveObjectKey(resolver, '_fallback'), same(undefined));
    });

    test('a null prefixed value is null', () {
      final resolver = createResolver(
        [
          <String, Object?>{'hoverColor': null},
        ],
        ['hover', ''],
      );
      expect(resolveObjectKey(resolver, 'color'), isNull);
    });
  });

  group('delete on a frozen scope', () {
    // Object.freeze is Map.unmodifiable. In strict mode, a delete of an
    // absent key succeeds, and a delete of an own key throws a TypeError
    // (an UnsupportedError in the port).
    test('an absent key', () {
      final resolver = createResolver([
        Map<String, Object?>.unmodifiable({'a': 1}),
      ]);
      expect(() => resolver.jsDelete('zzz'), returnsNormally);
      final opts = attachContext(
        createResolver([
          Map<String, Object?>.unmodifiable({'a': 1}),
        ]),
        {},
      );
      expect(() => opts.jsDelete('zzz'), returnsNormally);
    });

    test('an own key throws', () {
      final resolver = createResolver([
        Map<String, Object?>.unmodifiable({'a': 1}),
      ]);
      expect(() => resolver.jsDelete('a'), throwsUnsupportedError);
    });
  });

  group('this of the descriptor functions', () {
    // helpers.config.ts:242 calls descriptors.isScriptable(prop) as a method.
    // :246 passes descriptors.isIndexable without its object.
    test('_scriptable gets the descriptor, _indexable gets undefined', () {
      Object? scriptableThis;
      Object? indexableThis = 'not called';
      final scriptable = JsFunction((Object? self, Object? name) {
        scriptableThis = self;
        return name == 'v';
      });
      final indexable = JsFunction((Object? self, Object? name) {
        indexableThis = self;
        return true;
      });
      final opts = attachContext(
        createResolver([
          <String, Object?>{
            '_scriptable': scriptable,
            '_indexable': indexable,
            'v': () => 7,
            'w': <Object?>[1, 2],
          },
        ]),
        {'index': 1},
      );
      expect(opts['v'], 7);
      expect(scriptableThis, isA<Descriptor>());
      expect((scriptableThis! as Descriptor).scriptable, same(scriptable));
      expect(opts['w'], 2);
      expect(indexableThis, same(undefined));
    });
  });

  group('adapt-resolver-cached-read', () {
    // Pins that the read before _cached in the get traps gives the _cached
    // results: an owned value is the result, also null and undefined, and
    // each key resolves once.
    for (final state in _states) {
      test('Resolver, ${state.name}', () {
        final defaults = <String, Object?>{'y': 'y0'};
        final resolver = createResolver([state.scope(), defaults]);
        final first = resolver['x'];
        expect(resolver['y'], 'y0');
        defaults
          ..['x'] = 'late'
          ..['y'] = 'y1';
        expect(resolver['x'], same(first));
        expect(resolver['y'], 'y0');
        expect(resolver['_scopes'], isA<List<Object?>>());
        expect(resolver['constructor'], same(undefined));
      });
    }

    for (final (name, result) in <(String, Object?)>[
      ('a value', 'v'),
      ('null', null),
      ('undefined', undefined),
      ('NaN', double.nan),
      ('-0', -0.0),
    ]) {
      test('ContextResolver calls a scriptable option once, $name', () {
        var calls = 0;
        final opts = attachContext(
          createResolver([
            <String, Object?>{
              'x': (Object? ctx) {
                calls++;
                return result;
              },
            },
          ]),
          {'index': 1},
        );
        final first = opts['x'];
        final second = opts['x'];
        expect(calls, 1);
        expect(
          identical(second, first) || (first is double && first.isNaN),
          isTrue,
        );
        if (result is double && !result.isNaN) {
          expect((second! as double).isNegative, result.isNegative);
        }
        expect(opts['_context'], {'index': 1});
        expect(opts['constructor'], same(undefined));
      });
    }

    test('a set value is the next read, also null', () {
      final resolver = createResolver([
        <String, Object?>{'x': 1},
      ]);
      expect(resolver['x'], 1);
      resolver['x'] = 2;
      expect(resolver['x'], 2);
      resolver['x'] = null;
      expect(resolver['x'], isNull);
      resolver.jsDelete('x');
      expect(resolver['x'], same(undefined));
    });
  });

  group('js-semantics-resolver-objects', () {
    // differences.md `js-semantics-resolver-objects`. In the reference
    // engine, `resolver.constructor === Object` and `resolver.toString` is a
    // function. A Map has no prototype.
    test('constructor and Object.prototype members resolve as absent', () {
      final resolver = createResolver([
        <String, Object?>{'a': 1},
      ]);
      expect(resolver['constructor'], same(undefined));
      expect(resolver['toString'], same(undefined));
      expect(attachContext(resolver, {})['constructor'], same(undefined));
    });

    test('a class value scope has no key, and a read gives its static', () {
      // The reference engine, for the first scope
      // `class A { static id = 'a'; static defaults = {x: 1}; }`: `r.id` is
      // 'a', `'id' in r` is true and `Object.keys(r)` is ['id', 'defaults'].
      // In the port, a class value is a function scope without keys.
      final classValue = JsClass(
        'A',
        statics: {
          'id': 'a',
          'defaults': <String, Object?>{'x': 1},
        },
      );
      final resolver = createResolver([
        classValue,
        <String, Object?>{'y': 2},
      ]);
      expect(resolver['id'], 'a');
      expect(resolver['y'], 2);
      expect(resolver.hasProperty('id'), isFalse);
      expect(resolver.hasOwnProperty('id'), isFalse);
      expect(resolver.objectKeys(), isEmpty);
    });

    test('a set on a target that is not a Map throws a TypeError', () {
      final resolver = createResolver(
        [
          <String, Object?>{},
        ],
        [''],
        null,
        undefined,
        () => 'abc',
      );
      expect(() => resolver['x'] = 1, throwsA(isA<TypeError>()));
    });

    test('a write into a Map with a narrow value type throws', () {
      // The reference engine gives {sub: {a: 1, b: 'x'}} and
      // {plugins: {legend: {a: 1}, tooltip: {y: 2}}}.
      final options = <String, Object?>{
        'sub': {'a': 1},
      };
      expect(options['sub'], isA<Map<String, int>>());
      final resolver = createResolver([options, <String, Object?>{}]);
      expect(
        () => (resolver['sub']! as Resolver)['b'] = 'x',
        throwsA(isA<TypeError>()),
      );

      final options2 = <String, Object?>{
        'plugins': {
          'legend': {'a': 1},
        },
      };
      final resolver2 = createResolver([
        options2,
        <String, Object?>{
          'plugins': <String, Object?>{
            'tooltip': <String, Object?>{'x': 1},
          },
        },
      ]);
      final tooltip =
          (resolver2['plugins']! as Resolver)['tooltip']! as Resolver;
      expect(() => tooltip['y'] = 2, throwsA(isA<TypeError>()));
    });
  });

  group('adapt-text-style-fonts', () {
    // A font is a ChartTextStyle (Chart.js ADR 0116). The resolver merges
    // the fonts of the scopes that upstream gathers for a font object with
    // TextStyle.merge: a field of a scope with a higher priority wins.
    test('merges the fonts of the scopes of the key', () {
      final resolver = createResolver([
        <String, Object?>{'font': const ChartTextStyle(fontSize: 20)},
        <String, Object?>{
          'font': const ChartTextStyle(
            fontFamily: 'serif',
            fontSize: 10,
            height: 1.5,
          ),
        },
      ]);
      final font = resolver['font']! as ChartTextStyle;
      expect(
        font,
        const ChartTextStyle(fontFamily: 'serif', fontSize: 20, height: 1.5),
      );
      expect(font.lineHeight, 30);
    });

    test('merges the fonts of the _fallback key', () {
      final resolver = createResolver(
        [
          <String, Object?>{
            'titleFont': const ChartTextStyle(fontWeight: ui.FontWeight.bold),
            'font': const ChartTextStyle(fontFamily: 'serif', fontSize: 10),
          },
        ],
        [''],
        null,
        'font',
      );
      expect(
        resolver['titleFont'],
        const ChartTextStyle(
          fontFamily: 'serif',
          fontSize: 10,
          fontWeight: ui.FontWeight.bold,
        ),
      );
    });

    test('one font is the font itself', () {
      const font = ChartTextStyle(fontSize: 12);
      final resolver = createResolver([
        <String, Object?>{'font': font},
      ]);
      expect(resolver['font'], same(font));
    });
  });

  group('parseObjectDataRadialScale', () {
    List<Object?> parse(
      Object? parsing,
      List<Object?> data,
      double start,
      double count,
    ) {
      final parsed =
          jsCall(parseObjectDataRadialScale, [
                _Meta(_Scale()),
                data,
                start,
                count,
              ], thisArg: _Controller(parsing))!
              as List<Object?>;
      return [for (final item in parsed) jsGet(item, 'r')];
    }

    test('the default key r', () {
      expect(
        parse(
          <String, Object?>{},
          [
            <String, Object?>{'r': 5},
            <String, Object?>{'r': 6},
            <String, Object?>{'r': 7},
          ],
          1,
          2,
        ),
        <_Parsed>[(6, 1), (7, 2)],
      );
    });

    test('a nested key', () {
      expect(
        parse(
          <String, Object?>{'key': 'v.w'},
          [
            <String, Object?>{
              'v': <String, Object?>{'w': 'a'},
            },
            <String, Object?>{
              'v': <String, Object?>{'w': 'b'},
            },
          ],
          0,
          2,
        ),
        <_Parsed>[('a', 0), ('b', 1)],
      );
    });

    test('parsing false and a missing item', () {
      expect(
        parse(
          false,
          [
            <String, Object?>{'r': 1},
          ],
          0,
          1,
        ),
        <_Parsed>[(1, 0)],
      );
      expect(
        parse(
          <String, Object?>{},
          [
            <String, Object?>{'r': 1},
          ],
          0,
          2,
        ),
        <_Parsed>[(1, 0), (undefined, 1)],
      );
    });
  });

  test('a resolver prints no option', () {
    final resolver = createResolver([
      <String, Object?>{'a': 1},
    ]);
    expect(jsToString(resolver), '[object Object]');
    expect('$resolver', startsWith('Resolver(cache: '));
  });

  // The row adapt-resolver-single-walk: the sub-resolver of a top-level
  // resolver (its parent scopes are its root scopes) walks the list one time
  // when a second time adds nothing. Each case compares the resolver of a
  // list (the new path) with the resolver of the same list and a copy of it
  // as the root scopes: `[...parentScopes, ...rootScopes]` of the walk over
  // the list two times, the old path.
  group('adapt-resolver-single-walk', () {
    /// The resolver of [scopes] (one list) and its twin with a copy of
    /// [scopes] as the root scopes.
    (Resolver, Resolver) twins(List<Object?> scopes) => (
      createResolver(scopes),
      createResolver(scopes, const [''], [...scopes]),
    );

    /// The `_scopes` of the sub-resolver [prop] of [resolver].
    List<Object?> subScopes(Resolver resolver, String prop) =>
        (resolver[prop]! as Resolver).scopes;

    test('gives the scopes and values of plain Maps and typed scopes', () {
      List<Object?> scopes() => [
        <String, Object?>{
          'hover': <String, Object?>{'mode': const XInteractionMode()},
          'plugins': <String, Object?>{
            'zoom': <String, Object?>{'speed': 0.2},
          },
        },
        ChartOptionsScope()
          ..jsWrite(
            'hover',
            InteractionOptionsScope()..jsWrite('axis', InteractionAxis.y),
          )
          ..jsWrite(
            'interaction',
            InteractionOptionsScope()..jsWrite('intersect', false),
          ),
        <String, Object?>{
          'hover': <String, Object?>{'_fallback': 'interaction'},
          'plugins': <String, Object?>{
            'zoom': <String, Object?>{'_fallback': false},
          },
          'interaction': <String, Object?>{
            'mode': const NearestInteractionMode(),
          },
        },
      ];
      final (single, full) = twins(scopes());
      for (final prop in ['hover', 'interaction', 'plugins']) {
        final a = subScopes(single, prop);
        final b = subScopes(full, prop);
        expect(a.length, b.length, reason: prop);
        for (var i = 0; i < a.length; i++) {
          expect(a[i], same(b[i]), reason: '$prop $i');
        }
      }
      final hover = single['hover']! as Resolver;
      expect(hover['mode'], const XInteractionMode());
      expect(hover['axis'], InteractionAxis.y);
      expect(hover['intersect'], false);
      final zoom = (single['plugins']! as Resolver)['zoom']! as Resolver;
      expect(zoom['speed'], 0.2);
    });

    test('calls a function _fallback as the walk two times does', () {
      var calls = 0;
      Object? fallback(Object? prop, Object? value) {
        calls++;
        return undefined;
      }

      List<Object?> scopes() => [
        <String, Object?>{
          'x': <String, Object?>{'a': 1},
        },
        <String, Object?>{
          'x': <String, Object?>{'_fallback': fallback},
        },
      ];
      final (single, full) = twins(scopes());
      expect(single['x'], isA<Resolver>());
      final singleCalls = calls;
      calls = 0;
      expect(full['x'], isA<Resolver>());
      expect(singleCalls, calls);
      expect(calls, 2);
    });

    test('reads a Map of a user class as the walk two times does', () {
      final first = _CountingMap({
        'x': <String, Object?>{'a': 1},
      });
      final second = _CountingMap({
        'x': <String, Object?>{'a': 1},
      });
      final (single, _) = twins([first]);
      expect(single['x'], isA<Resolver>());
      final (_, full) = twins([second]);
      expect(full['x'], isA<Resolver>());
      expect(first.reads, second.reads);
      expect(first.reads, greaterThan(2));
    });

    test('reads a subclass of a scope class as the walk two times does', () {
      final first = _CountingScope()
        ..jsWrite('hover', <String, Object?>{'mode': const XInteractionMode()});
      final second = _CountingScope()
        ..jsWrite('hover', <String, Object?>{'mode': const XInteractionMode()});
      expect(first.nativeFace, isFalse);
      final (single, _) = twins([first]);
      expect(single['hover'], isA<Resolver>());
      final (_, full) = twins([second]);
      expect(full['hover'], isA<Resolver>());
      expect(first.reads, second.reads);
    });

    test('adds each new object of a route as the walk two times does', () {
      // A route whose local value is an object gives a new merged object at
      // each read (core.defaults.js:144-153).
      List<Object?> scopes() => [
        ChartOptionsScope()
          ..jsWrite('layout', <String, Object?>{'padding': 12})
          ..addRoute(
            'layout',
            ScopeRoute(
              (local) => <String, Object?>{...local! as Map<String, Object?>},
              targetScope: null,
              targetName: 'layout',
            ),
          ),
      ];

      final (single, full) = twins(scopes());
      final a = subScopes(single, 'layout');
      final b = subScopes(full, 'layout');
      expect(a.length, b.length);
      expect(a.length, 3);
      expect(a.toSet().length, 3);
    });

    test('reads a dotted _fallback as the walk two times does', () {
      final first = _CountingMap({
        'x': <String, Object?>{'_fallback': 'y.z'},
        'y': <String, Object?>{
          'z': <String, Object?>{'a': 1},
        },
      });
      final second = _CountingMap({
        'x': <String, Object?>{'_fallback': 'y.z'},
        'y': <String, Object?>{
          'z': <String, Object?>{'a': 1},
        },
      });
      final (single, _) = twins([first]);
      expect((single['x']! as Resolver)['a'], 1);
      final (_, full) = twins([second]);
      expect(full['x'], isA<Resolver>());
      expect(first.reads, second.reads);
    });

    test('walks a list of plain scopes one time', () {
      // A Map literal is a LinkedHashMap. Its key equality is a Dart thing
      // with no JavaScript counterpart; its calls show the skipped second
      // time.
      var calls = 0;
      LinkedHashMap<String, Object?> counted(Map<String, Object?> values) =>
          LinkedHashMap<String, Object?>(
            equals: (a, b) {
              calls++;
              return a == b;
            },
            hashCode: (key) => key.hashCode,
          )..addAll(values);
      final scopes = [
        counted({
          'x': <String, Object?>{'a': 1},
        }),
        <String, Object?>{
          'x': <String, Object?>{'b': 2},
        },
      ];
      final (single, full) = twins(scopes);
      calls = 0;
      final a = subScopes(single, 'x');
      final singleCalls = calls;
      calls = 0;
      final b = subScopes(full, 'x');
      expect(singleCalls, lessThan(calls));
      expect(a.length, b.length);
      for (var i = 0; i < a.length; i++) {
        expect(a[i], same(b[i]));
      }
    });
  });
}

/// A Map of a user class that counts its reads.
final class _CountingMap extends MapBase<String, Object?> {
  _CountingMap(this._values);

  final Map<String, Object?> _values;

  int reads = 0;

  @override
  Object? operator [](Object? key) {
    reads++;
    return _values[key];
  }

  @override
  void operator []=(String key, Object? value) => _values[key] = value;

  @override
  void clear() => _values.clear();

  @override
  Iterable<String> get keys => _values.keys;

  @override
  Object? remove(Object? key) => _values.remove(key);
}

/// A subclass of a scope class that counts its reads by name.
final class _CountingScope extends ChartOptionsScope {
  int reads = 0;

  @override
  Object? jsRead(String name) {
    reads++;
    return super.jsRead(name);
  }
}
