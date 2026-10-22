// Ported from Chart.js v4.5.1+7169e651 test/specs/helpers.config.tests.js (MIT, Chart.js Contributors).
import 'dart:collection';

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.color.dart'
    show getHoverColor;
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show isObject;
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:test/test.dart';

// A JavaScript object literal is a `Map<String, Object?>` and an array is a
// `List<Object?>` (Chart.js ADR 0006). The `_createResolver` and
// `_attachContext` proxies are the `Resolver` and `ContextResolver` Maps.
// `proxy.key` is `proxy['key']`, `'key' in proxy` is `containsKey`,
// `Object.getOwnPropertyNames(proxy)` is `keys`, `Object.keys(proxy)` is
// `jsObjectKeys`, and `Object.prototype.hasOwnProperty.call(proxy, key)` is
// `hasOwnProperty`.
// `Object.freeze` is `Map.unmodifiable`. A call of a function value goes
// through `jsCall`. Jasmine `toEqual` is `equals`, `toBe` is `same` for
// objects and `equals` for primitives, and `toBeUndefined()` is
// `same(undefined)`.

/// The JavaScript property read `object.key` of a value whose static type is
/// `Object?`.
extension on Object? {
  /// `this[key]`: the `get` trap of a resolver, or the value of a Map key.
  /// The [undefined] sentinel for a key that a Map does not contain.
  Object? operator [](String key) {
    final object = this! as Map<String, Object?>;
    if (object is Resolver || object is ContextResolver) return object[key];
    return object.containsKey(key) ? object[key] : undefined;
  }
}

/// The JavaScript class `Options` of the two "should support common object
/// methods" cases: an object with the own property `option2`, and the
/// getter `getter` on its prototype.
///
/// `operator []` is `[[Get]]`, which also finds the inherited getter.
/// [keys] and [containsKey] give the own properties only.
final class _Options extends MapBase<String, Object?> {
  _Options(Object? option2) {
    _own['option2'] = option2;
  }

  final Map<String, Object?> _own = {};

  @override
  Object? operator [](Object? key) =>
      key == 'getter' ? 'options getter' : _own[key];

  @override
  void operator []=(String key, Object? value) => _own[key] = value;

  @override
  Iterable<String> get keys => _own.keys;

  @override
  Object? remove(Object? key) => _own.remove(key);

  @override
  void clear() => _own.clear();
}

/// The JavaScript class `MyClass` of the case "should not create proxy for
/// objects with custom constructor".
final class _MyClass {
  final String string = 'test string';

  Object? method([Object? arg = undefined]) {
    return identical(arg, undefined) ? 'ok' : 'fail';
  }
}

/// A `jasmine.createSpy` that records the two arguments of each call and
/// returns [undefined].
final class _Spy {
  /// The arguments of each call.
  final List<List<Object?>> calls = [];

  /// The function value of the spy.
  Object? call(Object? prop, Object? value) {
    calls.add([prop, value]);
    return undefined;
  }
}

void main() {
  setUpSpecs();
  group('Chart.helpers.config', () {
    group('_createResolver', () {
      test('should resolve to raw values', () {
        final defaults = <String, Object?>{
          'color': 'red',
          'backgroundColor': 'green',
          'hoverColor': (Object? ctx, Object? options) =>
              getHoverColor(options['color']),
        };
        final options = <String, Object?>{'color': 'blue'};
        final resolver = createResolver([options, defaults]);
        expect(resolver['color'], 'blue');
        expect(resolver['backgroundColor'], 'green');
        expect(resolver['hoverColor'], same(defaults['hoverColor']));
      });

      test('should resolve to parent scopes, when _fallback is true', () {
        final descriptors = <String, Object?>{'_fallback': true};
        final defaults = <String, Object?>{
          'root': true,
          'sub': <String, Object?>{'child': true},
        };
        final options = <String, Object?>{
          'child': 'sub default comes before this',
          'opt': 'opt',
        };
        final resolver = createResolver([options, defaults, descriptors]);
        final sub = resolver['sub'];
        expect(sub['root'], true);
        expect(sub['child'], true);
        expect(sub['opt'], 'opt');
      });

      test('should support overriding options', () {
        final defaults = <String, Object?>{
          'option1': 'defaults1',
          'option2': 'defaults2',
          'option3': 'defaults3',
        };
        final options = <String, Object?>{
          'option1': 'options1',
          'option2': 'options2',
        };
        final overrides = <String, Object?>{'option1': 'override1'};
        final resolver = createResolver([options, defaults]);
        expect(
          resolver,
          toEqualOptions({
            'option1': 'options1',
            'option2': 'options2',
            'option3': 'defaults3',
          }),
        );
        expect(
          resolver.override(overrides),
          toEqualOptions({
            'option1': 'override1',
            'option2': 'options2',
            'option3': 'defaults3',
          }),
        );
      });

      test('should support common object methods', () {
        final defaults = <String, Object?>{'option1': 'defaults'};
        final options = _Options('options');

        final resolver = createResolver([options, defaults]);

        expect(resolver.hasOwnProperty('option2'), isTrue);

        expect(resolver.hasOwnProperty('option1'), isFalse);
        expect(resolver.hasOwnProperty('getter'), isFalse);
        expect(resolver.hasOwnProperty('nonexistent'), isFalse);

        expect(jsObjectKeys(resolver), ['option2']);
        expect(resolver.keys, ['option2', 'option1']);

        expect(resolver.containsKey('option2'), isTrue);
        expect(resolver.containsKey('option1'), isTrue);
        expect(resolver.containsKey('getter'), isFalse);
        expect(resolver.containsKey('nonexistent'), isFalse);

        // `expect(resolver instanceof Options).toBeTrue()` has no Dart form.
        // DIVERGES(chartjs): js-semantics-resolver-objects, no instanceof.

        expect(resolver['getter'], 'options getter');
      });

      test('should not fail on when options are frozen', () {
        Resolver create() {
          final defaults = Map<String, Object?>.unmodifiable({
            'default': true,
          });
          final options = Map<String, Object?>.unmodifiable({'value': true});
          return createResolver([options, defaults]);
        }

        expect(create, returnsNormally);
      });

      group('_fallback', () {
        test('should follow simple _fallback', () {
          final defaults = <String, Object?>{
            'interaction': <String, Object?>{
              'mode': 'test',
              'priority': 'fall',
            },
            'hover': <String, Object?>{
              '_fallback': 'interaction',
              'priority': 'main',
            },
          };
          final options = <String, Object?>{
            'interaction': <String, Object?>{'a': 1},
            'hover': <String, Object?>{'b': 2},
          };
          final resolver = createResolver([options, defaults]);
          expect(
            resolver['hover'],
            toEqualOptions({
              'mode': 'test',
              'priority': 'main',
              'a': 1,
              'b': 2,
            }),
          );
        });

        test('should support _fallback as function', () {
          final descriptors = <String, Object?>{
            // `prop === 'hover' && value.shouldFall && 'interaction'`.
            '_fallback': (Object? prop, Object? value) {
              if (prop != 'hover') return false;
              final shouldFall = value['shouldFall'];
              return jsTruthy(shouldFall) ? 'interaction' : shouldFall;
            },
          };
          final defaults = <String, Object?>{
            'interaction': <String, Object?>{
              'mode': 'test',
              'priority': 'fall',
            },
            'hover': <String, Object?>{'priority': 'main'},
          };
          final options = <String, Object?>{
            'interaction': <String, Object?>{'a': 1},
            'hover': <String, Object?>{'shouldFall': true, 'b': 2},
          };
          final resolver = createResolver([options, defaults, descriptors]);
          expect(
            resolver['hover'],
            toEqualOptions({
              'mode': 'test',
              'priority': 'main',
              'a': 1,
              'b': 2,
            }),
          );
        });

        test('should not fallback by default', () {
          final defaults = <String, Object?>{
            'hover': <String, Object?>{'a': 'defaults.hover'},
            'controllers': <String, Object?>{
              'y': 'defaults.controllers',
              'bar': <String, Object?>{
                'z': 'defaults.controllers.bar',
                'hover': <String, Object?>{
                  'b': 'defaults.controllers.bar.hover',
                },
              },
            },
            'x': 'defaults root',
          };
          final options = <String, Object?>{
            'x': 'options',
            'hover': <String, Object?>{
              'c': 'options.hover',
              'sub': <String, Object?>{'f': 'options.hover.sub'},
            },
            'controllers': <String, Object?>{
              'y': 'options.controllers',
              'bar': <String, Object?>{
                'z': 'options.controllers.bar',
                'hover': <String, Object?>{
                  'd': 'options.controllers.bar.hover',
                  'sub': <String, Object?>{
                    'e': 'options.controllers.bar.hover.sub',
                  },
                },
              },
            },
          };
          final resolver = createResolver([
            options,
            options['controllers']['bar'],
            options['controllers'],
            defaults['controllers']['bar'],
            defaults['controllers'],
            defaults,
          ]);
          expect(
            resolver['hover'],
            toEqualOptions({
              'a': 'defaults.hover',
              'b': 'defaults.controllers.bar.hover',
              'c': 'options.hover',
              'd': 'options.controllers.bar.hover',
              'e': undefined,
              'f': undefined,
              'x': undefined,
              'y': undefined,
              'z': undefined,
            }),
          );
          expect(
            resolver['hover']['sub'],
            toEqualOptions({
              'a': undefined,
              'b': undefined,
              'c': undefined,
              'd': undefined,
              'e': 'options.controllers.bar.hover.sub',
              'f': 'options.hover.sub',
              'x': undefined,
              'y': undefined,
              'z': undefined,
            }),
          );
        });

        test('should fallback to specific scope', () {
          final defaults = <String, Object?>{
            'hover': <String, Object?>{
              '_fallback': 'hover',
              'a': 'defaults.hover',
            },
            'controllers': <String, Object?>{
              'y': 'defaults.controllers',
              'bar': <String, Object?>{
                'z': 'defaults.controllers.bar',
                'hover': <String, Object?>{
                  'b': 'defaults.controllers.bar.hover',
                },
              },
            },
            'x': 'defaults root',
          };
          final options = <String, Object?>{
            'x': 'options',
            'hover': <String, Object?>{
              'c': 'options.hover',
              'sub': <String, Object?>{'f': 'options.hover.sub'},
            },
            'controllers': <String, Object?>{
              'y': 'options.controllers',
              'bar': <String, Object?>{
                'z': 'options.controllers.bar',
                'hover': <String, Object?>{
                  'd': 'options.controllers.bar.hover',
                  'sub': <String, Object?>{
                    'e': 'options.controllers.bar.hover.sub',
                  },
                },
              },
            },
          };
          final resolver = createResolver([
            options,
            options['controllers']['bar'],
            options['controllers'],
            defaults['controllers']['bar'],
            defaults['controllers'],
            defaults,
          ]);
          expect(
            resolver['hover'],
            toEqualOptions({
              'a': 'defaults.hover',
              'b': 'defaults.controllers.bar.hover',
              'c': 'options.hover',
              'd': 'options.controllers.bar.hover',
              'e': undefined,
              'f': undefined,
              'x': undefined,
              'y': undefined,
              'z': undefined,
            }),
          );
          expect(
            resolver['hover']['sub'],
            toEqualOptions({
              'a': 'defaults.hover',
              'b': 'defaults.controllers.bar.hover',
              'c': 'options.hover',
              'd': 'options.controllers.bar.hover',
              'e': 'options.controllers.bar.hover.sub',
              'f': 'options.hover.sub',
              'x': undefined,
              'y': undefined,
              'z': undefined,
            }),
          );
        });

        test('should fallback through multiple routes', () {
          final descriptors = <String, Object?>{
            '_fallback': 'level1',
            'level1': <String, Object?>{'_fallback': 'root'},
            'level2': <String, Object?>{'_fallback': 'level1'},
          };
          final defaults = <String, Object?>{
            'root': <String, Object?>{'a': 'root'},
            'level1': <String, Object?>{'b': 'level1'},
            'level2': <String, Object?>{
              'level1': <String, Object?>{'g': 'level2.level1'},
              'c': 'level2',
              'sublevel1': <String, Object?>{'d': 'sublevel1'},
              'sublevel2': <String, Object?>{
                'e': 'sublevel2',
                'level1': <String, Object?>{'f': 'sublevel2.level1'},
              },
            },
          };
          final resolver = createResolver([defaults, descriptors]);
          expect(
            resolver['level1'],
            toEqualOptions({'a': 'root', 'b': 'level1', 'c': undefined}),
          );
          expect(
            resolver['level2'],
            toEqualOptions({
              'a': 'root',
              'b': 'level1',
              'c': 'level2',
              'd': undefined,
            }),
          );
          expect(
            resolver['level2']['sublevel1'],
            toEqualOptions({
              'a': 'root',
              'b': 'level1',
              'c': undefined,
              'd': 'sublevel1',
              'e': undefined,
              'f': undefined,
              'g': 'level2.level1',
            }),
          );
          expect(
            resolver['level2']['sublevel2'],
            toEqualOptions({
              'a': 'root',
              'b': 'level1',
              'c': undefined,
              'd': undefined,
              'e': 'sublevel2',
              'f': undefined,
              'g': 'level2.level1',
            }),
          );
          expect(
            resolver['level2']['sublevel2']['level1'],
            toEqualOptions({
              'a': 'root',
              'b': 'level1',
              'c': undefined,
              'd': undefined,
              'e': undefined,
              'f': 'sublevel2.level1',
              // same key only included from immediate parents and root
              'g': undefined,
            }),
          );
        });

        test('should fallback through multiple routes (animations)', () {
          final descriptors = <String, Object?>{
            'animations': <String, Object?>{'_fallback': 'animation'},
          };
          final defaults = <String, Object?>{
            'animation': <String, Object?>{
              'duration': 1000,
              'easing': 'easeInQuad',
            },
            'animations': <String, Object?>{
              'colors': <String, Object?>{
                'properties': ['color', 'backgroundColor'],
                'type': 'color',
              },
              'numbers': <String, Object?>{
                'properties': ['x', 'y'],
                'type': 'number',
              },
            },
            'transitions': <String, Object?>{
              'resize': <String, Object?>{
                'animation': <String, Object?>{'duration': 0},
              },
              'show': <String, Object?>{
                'animation': <String, Object?>{'duration': 400},
                'animations': <String, Object?>{
                  'colors': <String, Object?>{'from': 'transparent'},
                },
              },
            },
          };
          final options = <String, Object?>{
            'animation': <String, Object?>{'easing': 'linear'},
            'animations': <String, Object?>{
              'colors': <String, Object?>{
                'properties': ['color', 'borderColor', 'backgroundColor'],
              },
              'duration': <String, Object?>{
                'properties': ['a', 'b'],
                'type': 'boolean',
              },
            },
          };

          final show = createResolver([
            options,
            defaults['transitions']['show'],
            defaults,
            descriptors,
          ]);
          expect(
            show['animation'],
            toEqualOptions({'duration': 400, 'easing': 'linear'}),
          );
          expect(show['animations']['colors']['_scopes'], [
            options['animations']['colors'],
            defaults['transitions']['show']['animations']['colors'],
            defaults['animations']['colors'],
            options['animation'],
            defaults['transitions']['show']['animation'],
            defaults['animation'],
          ]);
          expect(
            show['animations']['colors'],
            toEqualOptions({
              'duration': 400,
              'from': 'transparent',
              'easing': 'linear',
              'type': 'color',
              'properties': ['color', 'borderColor', 'backgroundColor'],
            }),
          );
          expect(
            show['animations']['duration'],
            toEqualOptions({
              'duration': 400,
              'easing': 'linear',
              'type': 'boolean',
              'properties': ['a', 'b'],
            }),
          );
          expect(
            (show['animations']! as Map<String, Object?>).keys.where(
              (k) => isObject(show['animations'][k]),
            ),
            ['colors', 'duration', 'numbers'],
          );
          final def = createResolver([options, defaults, descriptors]);
          expect(
            def['animation'],
            toEqualOptions({'duration': 1000, 'easing': 'linear'}),
          );
          expect(def['animations']['colors']['_scopes'], [
            options['animations']['colors'],
            defaults['animations']['colors'],
            options['animation'],
            defaults['animation'],
          ]);
          expect(
            def['animations']['colors'],
            toEqualOptions({
              'duration': 1000,
              'easing': 'linear',
              'type': 'color',
              'properties': ['color', 'borderColor', 'backgroundColor'],
            }),
          );
          expect(
            def['animations']['duration'],
            toEqualOptions({
              'duration': 1000,
              'easing': 'linear',
              'type': 'boolean',
              'properties': ['a', 'b'],
            }),
          );
          // Upstream filters the keys of `def.animations` with
          // `show.animations`.
          expect(
            (def['animations']! as Map<String, Object?>).keys.where(
              (k) => isObject(show['animations'][k]),
            ),
            ['colors', 'duration', 'numbers'],
          );
        });
      });

      group('setting values', () {
        test('should set values to first scope', () {
          final defaults = <String, Object?>{'value': true};
          final options = <String, Object?>{};
          final resolver = createResolver([options, defaults]);
          resolver['value'] = false;
          expect(options['value'], isFalse);
          expect(defaults['value'], isTrue);
          expect(resolver['value'], isFalse);
        });

        test('should set values of sub-objects to first scope', () {
          final defaults = <String, Object?>{
            'sub': <String, Object?>{'value': true},
          };
          final options = <String, Object?>{};
          final resolver = createResolver([options, defaults]);
          (resolver['sub']! as Map<String, Object?>)['value'] = false;
          expect(options['sub']['value'], isFalse);
          expect(defaults['sub']['value'], isTrue);
          expect(resolver['sub']['value'], isFalse);
        });

        test('should throw when setting a value and options is frozen', () {
          final defaults = Map<String, Object?>.unmodifiable({'default': true});
          final options = Map<String, Object?>.unmodifiable({'value': true});
          final resolver = createResolver([options, defaults]);
          void set() {
            resolver['value'] = false;
          }

          expect(set, throwsA(anything));
        });
      });
    });

    group('_attachContext', () {
      test('should resolve to final values', () {
        final defaults = <String, Object?>{
          'color': 'red',
          'backgroundColor': 'green',
          'hoverColor': (Object? ctx, Object? options) =>
              getHoverColor(options['color']),
        };
        final options = <String, Object?>{
          'color': ['white', 'blue'],
        };
        final resolver = createResolver([options, defaults]);
        final opts = attachContext(resolver, {'index': 1});
        expect(opts['color'], 'blue');
        expect(opts['backgroundColor'], 'green');
        expect(opts['hoverColor'], getHoverColor('blue'));
      });

      test('should thrown on recursion', () {
        final options = <String, Object?>{
          'foo': (Object? ctx, Object? opts) => opts['bar'],
          'bar': (Object? ctx, Object? opts) => opts['xyz'],
          'xyz': (Object? ctx, Object? opts) => opts['foo'],
        };
        final resolver = createResolver([options]);
        final opts = attachContext(resolver, {'test': true});
        expect(
          () => opts['foo'],
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              'Recursion detected: foo->bar->xyz->foo',
            ),
          ),
        );
      });

      test('should support scriptable options in subscopes', () {
        final defaults = <String, Object?>{
          'elements': <String, Object?>{
            'point': <String, Object?>{'backgroundColor': 'red'},
          },
        };
        final options = <String, Object?>{
          'elements': <String, Object?>{
            'point': <String, Object?>{
              'borderColor': (Object? ctx, Object? opts) =>
                  getHoverColor(opts['backgroundColor']),
            },
          },
        };
        final resolver = createResolver([options, defaults]);
        final opts = attachContext(resolver, {});
        expect(
          opts['elements']['point']['borderColor'],
          getHoverColor('red'),
        );
        expect(opts['elements']['point']['backgroundColor'], 'red');
      });

      test('same resolver should be usable with multiple contexts', () {
        final defaults = <String, Object?>{
          'animation': <String, Object?>{'delay': 10},
        };
        final options = <String, Object?>{
          'animation': (Object? ctx) => ctx['index'] == 0
              ? <String, Object?>{'duration': 1000}
              : <String, Object?>{'duration': 500},
        };
        final resolver = createResolver([options, defaults]);
        final opts1 = attachContext(resolver, {'index': 0});
        final opts2 = attachContext(resolver, {'index': 1});

        expect(opts1['animation']['duration'], 1000);
        expect(opts1['animation']['delay'], 10);

        expect(opts2['animation']['duration'], 500);
        expect(opts2['animation']['delay'], 10);
      });

      test('should fall back from object returned from scriptable option', () {
        final defaults = <String, Object?>{
          'mainScope': <String, Object?>{
            'main': true,
            'subScope': <String, Object?>{'sub': true},
          },
        };
        final options = <String, Object?>{
          'mainScope': (Object? ctx) => <String, Object?>{
            'mainTest': ctx['contextValue'],
            'subScope': <String, Object?>{'subText': 'a'},
          },
        };
        final opts = attachContext(createResolver([options, defaults]), {
          'contextValue': 'test',
        });
        expect(
          opts['mainScope'],
          toEqualOptions({
            'main': true,
            'mainTest': 'test',
            'subScope': {'sub': true, 'subText': 'a'},
          }),
        );
      });

      test('should resolve array of non-indexable objects properly', () {
        final defaults = <String, Object?>{
          'label': <String, Object?>{
            'value': 42,
            'text': (Object? ctx) => ctx['text'],
          },
          'labels': <String, Object?>{
            '_fallback': 'label',
            '_indexable': false,
          },
        };

        final options = <String, Object?>{
          'labels': [
            <String, Object?>{'text': 'a'},
            <String, Object?>{'text': 'b'},
            <String, Object?>{'value': 1},
          ],
        };
        final opts = attachContext(createResolver([options, defaults]), {
          'text': 'context',
        });
        expect(
          opts,
          toEqualOptions({
            'labels': [
              {'text': 'a', 'value': 42},
              {'text': 'b', 'value': 42},
              {'text': 'context', 'value': 1},
            ],
          }),
        );
      });

      test(
        'should call _fallback with proper value from array when descriptor is '
        'object',
        () {
          final spy = _Spy();
          final descriptors = <String, Object?>{
            'items': <String, Object?>{'_fallback': spy.call},
          };
          final options = <String, Object?>{
            'items': [
              <String, Object?>{'test': true},
            ],
          };
          final resolver = createResolver([options, descriptors]);
          final opts = attachContext(resolver, {'dymmy': true});
          final item0 = (opts['items']! as List<Object?>)[0];
          expect(item0['test'], true);
          expect(
            spy.calls,
            contains(
              equals(['items', (options['items']! as List<Object?>)[0]]),
            ),
          );
        },
      );

      test(
        'should call _fallback with proper value from array when descriptor '
        'and defaults are objects',
        () {
          final spy = _Spy();
          final descriptors = <String, Object?>{
            'items': <String, Object?>{'_fallback': spy.call},
          };
          final defaults = <String, Object?>{
            'items': <String, Object?>{'type': 'defaultType'},
          };
          final options = <String, Object?>{
            'items': [
              <String, Object?>{'test': true},
            ],
          };
          final resolver = createResolver([options, defaults, descriptors]);
          final opts = attachContext(resolver, {'dymmy': true});
          final item0 = (opts['items']! as List<Object?>)[0];
          expect(item0['test'], true);
          expect(
            spy.calls,
            contains(
              equals(['items', (options['items']! as List<Object?>)[0]]),
            ),
          );
        },
      );

      test('should support overriding options', () {
        final options = <String, Object?>{
          'fn1': (Object? ctx) => ctx['index'],
          'fn2': (Object? ctx) => ctx['type'],
        };
        final override = <String, Object?>{
          'fn1': (Object? ctx) => jsToNumber(ctx['index']) * 2,
        };
        final opts = attachContext(createResolver([options]), {
          'index': 2,
          'type': 'test',
        });
        expect(opts, toEqualOptions({'fn1': 2, 'fn2': 'test'}));
        expect(
          opts.override(override),
          toEqualOptions({'fn1': 4, 'fn2': 'test'}),
        );
      });

      test('should support changing context', () {
        final opts = attachContext(
          createResolver([
            <String, Object?>{'fn': (Object? ctx) => ctx['test']},
          ]),
          {'test': 1},
        );
        expect(opts['fn'], 1);
        expect(opts.setContext({'test': 2})['fn'], 2);
        expect(opts['fn'], 1);
      });

      test('should support common object methods', () {
        final defaults = <String, Object?>{'option1': 'defaults'};
        final options = _Options(() => 'options');
        final resolver = createResolver([options, defaults]);
        final opts = attachContext(resolver, {'index': 1});

        expect(opts.hasOwnProperty('option2'), isTrue);

        expect(opts.hasOwnProperty('option1'), isFalse);
        expect(opts.hasOwnProperty('getter'), isFalse);
        expect(opts.hasOwnProperty('nonexistent'), isFalse);

        expect(jsObjectKeys(opts), ['option2']);
        expect(opts.keys, ['option2', 'option1']);

        expect(opts.containsKey('option2'), isTrue);
        expect(opts.containsKey('option1'), isTrue);
        expect(opts.containsKey('getter'), isFalse);
        expect(opts.containsKey('nonexistent'), isFalse);

        // `expect(opts instanceof Options).toBeTrue()` has no Dart form.
        // DIVERGES(chartjs): js-semantics-resolver-objects, no instanceof.

        expect(opts['getter'], 'options getter');

        expect(opts.containsKey('test'), isFalse);
        expect(opts['test'], same(undefined));

        opts['test'] = true;
        expect(opts.containsKey('test'), isTrue);
        expect(opts['test'], isTrue);

        opts.remove('test');
        expect(opts.containsKey('test'), isFalse);

        Object? test(Object? ctx) => ctx['index'];
        opts['test'] = test;
        expect(opts.containsKey('test'), isTrue);
        expect(opts['test'], 1);

        opts.remove('test');
        expect(opts.containsKey('test'), isFalse);
      });

      test('should not create proxy for adapters', () {
        final defaults = <String, Object?>{
          'scales': <String, Object?>{
            'time': <String, Object?>{
              'adapters': <String, Object?>{
                'date': <String, Object?>{
                  'locale': <String, Object?>{
                    'method': ([Object? arg = undefined]) =>
                        identical(arg, undefined) ? 'ok' : 'fail',
                  },
                },
              },
            },
          },
        };

        final resolver = createResolver([<String, Object?>{}, defaults]);
        final opts = attachContext(resolver, {'index': 1});
        final fn =
            opts['scales']['time']['adapters']['date']['locale']['method'];
        expect(jsIsFunction(fn), isTrue);
        expect(jsCall(fn, const []), 'ok');
      });

      test('should not create proxy for objects with custom constructor', () {
        final defaults = <String, Object?>{'test': _MyClass()};

        final resolver = createResolver([<String, Object?>{}, defaults]);
        final opts = attachContext(resolver, {'index': 1});
        final fn = (opts['test']! as _MyClass).method;
        expect(jsIsFunction(fn), isTrue);
        expect(jsCall(fn, const []), 'ok');
        expect((opts['test']! as _MyClass).string, 'test string');
        expect(opts['test'].runtimeType, _MyClass);
      });

      test('should properly set value to object in array of objects', () {
        final defaults = <String, Object?>{};
        final options = <String, Object?>{
          'annotations': [
            <String, Object?>{'value': 10},
            <String, Object?>{'value': 20},
          ],
        };
        final resolver = attachContext(createResolver([options, defaults]), {
          'test': true,
        });
        expect((resolver['annotations']! as List<Object?>)[0]['value'], 10);

        ((resolver['annotations']! as List<Object?>)[0]!
                as Map<String, Object?>)['value'] =
            15;
        expect((options['annotations']! as List<Object?>)[0]['value'], 15);
        expect((options['annotations']! as List<Object?>)[1]['value'], 20);
      });

      group('_indexable and _scriptable', () {
        test('should default to true', () {
          final options = <String, Object?>{
            'array': [1, 2, 3],
            'func': (Object? ctx) => jsToNumber(ctx['index']) * 10,
          };
          final opts = attachContext(createResolver([options]), {'index': 1});
          expect(opts['array'], 2);
          expect(opts['func'], 10);
        });

        test('should allow false', () {
          String fn() => 'test';
          final options = <String, Object?>{
            '_indexable': false,
            '_scriptable': false,
            'array': [1, 2, 3],
            'func': fn,
          };
          final opts = attachContext(createResolver([options]), {'index': 1});
          expect(opts['array'], [1, 2, 3]);
          expect(opts['func'], same(fn));
          expect(jsCall(opts['func'], const []), 'test');
        });

        test('should allow function', () {
          String fn() => 'test';
          final options = <String, Object?>{
            '_indexable': (Object? prop) => prop != 'array',
            '_scriptable': (Object? prop) => prop == 'func',
            'array': [1, 2, 3],
            'array2': ['a', 'b', 'c'],
            'func': fn,
          };
          final opts = attachContext(createResolver([options]), {'index': 1});
          expect(opts['array'], [1, 2, 3]);
          expect(opts['func'], 'test');
          expect(opts['array2'], 'b');
        });
      });
    });
  });
}
