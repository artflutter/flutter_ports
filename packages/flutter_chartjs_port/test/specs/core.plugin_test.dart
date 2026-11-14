// Ported from Chart.js v4.6.1 test/specs/core.plugin.tests.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-typed-plugins, the native plugins of the cases.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart'
    show acquireChart, triggerMouseEvent, waitForDone;
import 'package:chartjs_test_utils/pure.dart' show toEqualOptions;
import 'package:flutter_chartjs_port/src/core/core.controller.dart' show Chart;
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_function.dart' show jsCall;
import 'package:flutter_chartjs_port/src/js/js_object.dart'
    show JsObjectFace, jsGet;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart' show undefined;
import 'package:flutter_chartjs_port/src/types/plugin.dart'
    show Plugin, PluginHook, PluginHookArgs, TooltipDrawHookArgs;
import 'package:flutter_test/flutter_test.dart';

import '../support/jasmine.dart';

// Each case builds a chart with `acquireChart` (Chart.js ADR 0022): a chart
// without a type and without datasets, with inline or registered plugins.
// Thus it is a `testWidgets` case. `flutter_test_config.dart` registers the
// built-in components and releases the charts at the unmount of the harness
// body.
//
// A plugin is a native `Plugin` (Chart.js ADR 0144): an object with an `id`
// and a field for each hook of the `Plugin` interface. A hook has the type
// of its hook: a cancelable hook returns a bool, and each other hook returns
// nothing. `Plugin.id` is a required String, so an inline plugin of upstream
// without `id` gets an id here that no option names: its options are those
// of upstream. `Chart.register(plugin)` is `Chart.register([plugin])`, and
// `Chart.register([a, b])` is `Chart.register([[a, b]])` (Chart.js ADR 0020,
// section 6). A spec map literal of a JS object has the type
// `<String, Object?>`, because `acquireChart` writes into it.
//
// No hook has the name `hook` of upstream: `chart.notifyPlugins` takes a
// `PluginHook`. A case that does not cancel takes the hook `reset` in place
// of `hook`: only `chart.reset()` notifies it, so the chart does not call it
// between the spy and the expectations. A case of the result of a notify
// takes the cancelable hook `beforeTooltipDraw` with the arguments
// `TooltipDrawHookArgs` of the tooltip of the chart: the chart draws no
// tooltip in these cases. The args objects `{value: 42}`, `{arg1: 'bla'}`
// and `{arg1: 'bla', arg2: 42}` of upstream are objects of [_SpecArgs], a
// `PluginHookArgs` with these fields.
//
// `spyOn(plugin, 'hook')` is [_spyOnReset] or [_spyOnTooltipDraw]: it puts a
// spy of `hookSpy` (test/support/jasmine.dart) into the hook field.
// `plugin.hook.calls` reads the calls of the spy through the hook field of
// the plugin. `toBe` is `same` for objects. A notify returns a `bool?`:
// `toBeTruthy()` and `toBeFalsy()` are `isTrue` and `isFalse`.
//
// The case with `done` is `await waitForDone((done) { ... })`, and an
// `async` case awaits `triggerMouseEvent` (Chart.js ADR 0022, sections 2, 6
// and 7). The hook `start` runs in the constructor of the chart. Thus the
// `done` of `:425` comes before `acquireChart` returns.

/// The args objects of the spec: `{value: 42}` (:8, :23), and `{arg1: 'bla'}`
/// and `{arg1: 'bla', arg2: 42}` (:182-183). A notify passes them to each
/// hook by identity.
final class _SpecArgs({
  /// `value`.
  final Object? value,

  /// `arg1`.
  final Object? arg1,

  /// `arg2`.
  final Object? arg2,
}) extends PluginHookArgs;

/// `spyOn(plugin, 'hook')`: puts a spy into the hook `reset` of [plugin].
JasmineSpy _spyOnReset(Plugin<Object?> plugin) {
  final spy = hookSpy(plugin.reset);
  plugin.reset = spy.hook;
  return spy;
}

/// `spyOn(plugin, 'hook')`: puts a spy into the cancelable hook
/// `beforeTooltipDraw` of [plugin].
JasmineSpy _spyOnTooltipDraw(Plugin<Object?> plugin) {
  final spy = hookSpy(plugin.beforeTooltipDraw);
  plugin.beforeTooltipDraw = spy.cancelableHook;
  return spy;
}

/// `chart.notifyPlugins('hook', {cancelable: true})`: a notify of the
/// cancelable hook `beforeTooltipDraw`.
bool? _notifyCancelable(Chart chart) => chart.notifyPlugins(
  PluginHook.beforeTooltipDraw,
  TooltipDrawHookArgs(tooltip: chart.tooltip!),
);

/// The inline plugins of [chart], `chart.config.plugins`.
List<Plugin<Object?>> _inlinePlugins(Chart chart) =>
    (chart.config.plugins! as List<Object?>).cast<Plugin<Object?>>();

void main() {
  group('Chart.plugins', () {
    group('Chart.notifyPlugins', () {
      testWidgets('should call inline plugins with arguments', (tester) async {
        final plugin = Plugin<Object?>(id: 'inline', reset: (_, _, _) {});
        final chart = acquireChart(<String, Object?>{
          'plugins': [plugin],
        });
        final args = _SpecArgs(value: 42);

        _spyOnReset(plugin);

        chart.notifyPlugins(PluginHook.reset, args);
        expect(plugin.reset.calls.count(), 1);
        expect(plugin.reset.calls.first().args[0], same(chart));
        expect(plugin.reset.calls.first().args[1], same(args));
        expect(
          plugin.reset.calls.first().args[2],
          toEqualOptions(<String, Object?>{}),
        );
      });

      testWidgets('should call global plugins with arguments', (tester) async {
        final plugin = Plugin<Object?>(id: 'a', reset: (_, _, _) {});
        final chart = acquireChart(<String, Object?>{});
        final args = _SpecArgs(value: 42);

        _spyOnReset(plugin);

        Chart.register([plugin]);
        chart.notifyPlugins(PluginHook.reset, args);
        expect(plugin.reset.calls.count(), 1);
        expect(plugin.reset.calls.first().args[0], same(chart));
        expect(plugin.reset.calls.first().args[1], same(args));
        expect(
          plugin.reset.calls.first().args[2],
          toEqualOptions(<String, Object?>{}),
        );
        Chart.unregister([plugin]);
      });

      testWidgets(
        'should call plugin only once even if registered multiple times',
        (tester) async {
          final plugin = Plugin<Object?>(id: 'test', reset: (_, _, _) {});
          final chart = acquireChart(<String, Object?>{
            'plugins': [plugin, plugin],
          });

          _spyOnReset(plugin);

          Chart.register([
            [plugin, plugin],
          ]);
          chart.notifyPlugins(PluginHook.reset);
          expect(plugin.reset.calls.count(), 1);
          Chart.unregister([plugin]);
        },
      );

      testWidgets('should call plugins in the correct order (global first)', (
        tester,
      ) async {
        final results = <Object?>[];
        final chart = acquireChart(<String, Object?>{
          'plugins': [
            Plugin<Object?>(
              id: 'inline1',
              reset: (_, _, _) {
                results.add(1);
              },
            ),
            Plugin<Object?>(
              id: 'inline2',
              reset: (_, _, _) {
                results.add(2);
              },
            ),
            Plugin<Object?>(
              id: 'inline3',
              reset: (_, _, _) {
                results.add(3);
              },
            ),
          ],
        });

        final plugins = [
          Plugin<Object?>(
            id: 'a',
            reset: (_, _, _) {
              results.add(4);
            },
          ),
          Plugin<Object?>(
            id: 'b',
            reset: (_, _, _) {
              results.add(5);
            },
          ),
          Plugin<Object?>(
            id: 'c',
            reset: (_, _, _) {
              results.add(6);
            },
          ),
        ];
        Chart.register([plugins]);

        final ret = chart.notifyPlugins(PluginHook.reset);
        expect(ret, isTrue);
        expect(results, [4, 5, 6, 1, 2, 3]);
        Chart.unregister([plugins]);
      });

      // The hooks of upstream return `undefined`, `null`, `0`, `true` and
      // `1`: no `false`. A cancelable hook returns a bool, so each of them
      // returns `true` here.
      testWidgets('should return TRUE if no plugin explicitly returns FALSE', (
        tester,
      ) async {
        final chart = acquireChart(<String, Object?>{
          'plugins': [
            Plugin<Object?>(
              id: 'inline1',
              beforeTooltipDraw: (_, _, _) => true,
            ),
            Plugin<Object?>(
              id: 'inline2',
              beforeTooltipDraw: (_, _, _) {
                return true;
              },
            ),
            Plugin<Object?>(
              id: 'inline3',
              beforeTooltipDraw: (_, _, _) {
                return true;
              },
            ),
            Plugin<Object?>(
              id: 'inline4',
              beforeTooltipDraw: (_, _, _) {
                return true;
              },
            ),
            Plugin<Object?>(
              id: 'inline5',
              beforeTooltipDraw: (_, _, _) {
                return true;
              },
            ),
          ],
        });

        final plugins = _inlinePlugins(chart);
        for (final plugin in plugins) {
          _spyOnTooltipDraw(plugin).and.callThrough();
        }

        final ret = _notifyCancelable(chart);
        expect(ret, isTrue);
        for (final plugin in plugins) {
          expect(plugin.beforeTooltipDraw, toHaveBeenCalled());
        }
      });

      // The hooks of upstream return `undefined`, `null`, `false`, `42` and
      // `'bar'`, and the notify gives `{cancelable: true}`. Here the hook is
      // cancelable, and its hooks return `true`, `true`, `false`, `true` and
      // `true`.
      testWidgets(
        'should return FALSE if any plugin explicitly returns FALSE',
        (tester) async {
          final chart = acquireChart(<String, Object?>{
            'plugins': [
              Plugin<Object?>(
                id: 'inline1',
                beforeTooltipDraw: (_, _, _) => true,
              ),
              Plugin<Object?>(
                id: 'inline2',
                beforeTooltipDraw: (_, _, _) {
                  return true;
                },
              ),
              Plugin<Object?>(
                id: 'inline3',
                beforeTooltipDraw: (_, _, _) {
                  return false;
                },
              ),
              Plugin<Object?>(
                id: 'inline4',
                beforeTooltipDraw: (_, _, _) {
                  return true;
                },
              ),
              Plugin<Object?>(
                id: 'inline5',
                beforeTooltipDraw: (_, _, _) {
                  return true;
                },
              ),
            ],
          });

          final plugins = _inlinePlugins(chart);
          for (final plugin in plugins) {
            _spyOnTooltipDraw(plugin).and.callThrough();
          }

          final ret = _notifyCancelable(chart);
          expect(ret, isFalse);
          expect(plugins[0].beforeTooltipDraw, toHaveBeenCalled());
          expect(plugins[1].beforeTooltipDraw, toHaveBeenCalled());
          expect(plugins[2].beforeTooltipDraw, toHaveBeenCalled());
          expect(plugins[3].beforeTooltipDraw, isNot(toHaveBeenCalled()));
          expect(plugins[4].beforeTooltipDraw, isNot(toHaveBeenCalled()));
        },
      );
    });

    group('config.options.plugins', () {
      testWidgets('should call plugins with options at last argument', (
        tester,
      ) async {
        final plugin = Plugin<Object?>(id: 'foo', reset: (_, _, _) {});

        final chart = acquireChart(<String, Object?>{
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'foo': <String, Object?>{'a': '123'},
            },
          },
        });

        _spyOnReset(plugin);

        Chart.register([plugin]);
        chart
          ..notifyPlugins(PluginHook.reset)
          ..notifyPlugins(PluginHook.reset, _SpecArgs(arg1: 'bla'))
          ..notifyPlugins(PluginHook.reset, _SpecArgs(arg1: 'bla', arg2: 42));

        expect(plugin.reset.calls.count(), 3);
        expect(
          plugin.reset.calls.argsFor(0)[2],
          toEqualOptions(<String, Object?>{'a': '123'}),
        );
        expect(
          plugin.reset.calls.argsFor(1)[2],
          toEqualOptions(<String, Object?>{'a': '123'}),
        );
        expect(
          plugin.reset.calls.argsFor(2)[2],
          toEqualOptions(<String, Object?>{'a': '123'}),
        );

        Chart.unregister([plugin]);
      });

      testWidgets(
        'should call plugins with options associated to their identifier',
        (tester) async {
          final plugins = <String, Plugin<Object?>>{
            'a': Plugin<Object?>(id: 'a', reset: (_, _, _) {}),
            'b': Plugin<Object?>(id: 'b', reset: (_, _, _) {}),
            'c': Plugin<Object?>(id: 'c', reset: (_, _, _) {}),
          };

          Chart.register([plugins['a']]);

          final chart = acquireChart(<String, Object?>{
            'plugins': [plugins['b'], plugins['c']],
            'options': <String, Object?>{
              'plugins': <String, Object?>{
                'a': <String, Object?>{'a': '123'},
                'b': <String, Object?>{'b': '456'},
                'c': <String, Object?>{'c': '789'},
              },
            },
          });

          _spyOnReset(plugins['a']!);
          _spyOnReset(plugins['b']!);
          _spyOnReset(plugins['c']!);

          chart.notifyPlugins(PluginHook.reset);

          expect(plugins['a']!.reset, toHaveBeenCalled());
          expect(plugins['b']!.reset, toHaveBeenCalled());
          expect(plugins['c']!.reset, toHaveBeenCalled());
          expect(
            plugins['a']!.reset.calls.first().args[2],
            toEqualOptions(<String, Object?>{'a': '123'}),
          );
          expect(
            plugins['b']!.reset.calls.first().args[2],
            toEqualOptions(<String, Object?>{'b': '456'}),
          );
          expect(
            plugins['c']!.reset.calls.first().args[2],
            toEqualOptions(<String, Object?>{'c': '789'}),
          );

          Chart.unregister([plugins['a']]);
        },
      );

      testWidgets(
        'should not call plugins when config.options.plugins.{id} is FALSE',
        (tester) async {
          final plugins = <String, Plugin<Object?>>{
            'a': Plugin<Object?>(id: 'a', reset: (_, _, _) {}),
            'b': Plugin<Object?>(id: 'b', reset: (_, _, _) {}),
            'c': Plugin<Object?>(id: 'c', reset: (_, _, _) {}),
          };

          Chart.register([plugins['a']]);

          final chart = acquireChart(<String, Object?>{
            'plugins': [plugins['b'], plugins['c']],
            'options': <String, Object?>{
              'plugins': <String, Object?>{'a': false, 'b': false},
            },
          });

          _spyOnReset(plugins['a']!);
          _spyOnReset(plugins['b']!);
          _spyOnReset(plugins['c']!);

          chart.notifyPlugins(PluginHook.reset);

          expect(plugins['a']!.reset, isNot(toHaveBeenCalled()));
          expect(plugins['b']!.reset, isNot(toHaveBeenCalled()));
          expect(plugins['c']!.reset, toHaveBeenCalled());

          Chart.unregister([plugins['a']]);
        },
      );

      testWidgets(
        'should call plugins with default options when plugin options is TRUE',
        (tester) async {
          final plugin = Plugin<Object?>(
            id: 'a',
            reset: (_, _, _) {},
            defaults: <String, Object?>{'a': 42},
          );

          Chart.register([plugin]);

          final chart = acquireChart(<String, Object?>{
            'options': <String, Object?>{
              'plugins': <String, Object?>{'a': true},
            },
          });

          _spyOnReset(plugin);

          chart.notifyPlugins(PluginHook.reset);

          expect(plugin.reset, toHaveBeenCalled());
          expect(jsObjectKeys(plugin.reset.calls.first().args[2]), ['a']);
          // jasmine.objectContaining({a: 42})
          expect(
            plugin.reset.calls.first().args[2],
            objectContaining({'a': 42}),
          );

          Chart.unregister([plugin]);
        },
      );

      testWidgets(
        'should call plugins with default options if plugin config options '
        'is undefined',
        (tester) async {
          final plugin = Plugin<Object?>(
            id: 'a',
            reset: (_, _, _) {},
            defaults: <String, Object?>{'a': 'foobar'},
          );

          Chart.register([plugin]);
          _spyOnReset(plugin);

          acquireChart().notifyPlugins(PluginHook.reset);

          expect(plugin.reset, toHaveBeenCalled());
          expect(
            plugin.reset.calls.first().args[2],
            toEqualOptions(<String, Object?>{'a': 'foobar'}),
          );

          Chart.unregister([plugin]);
        },
      );

      // https://github.com/chartjs/Chart.js/issues/10482
      testWidgets('should resolve defaults for local plugins', (tester) async {
        final plugin = Plugin<Object?>(
          id: 'a',
          reset: (_, _, _) {},
          defaults: <String, Object?>{'bar': 'bar'},
        );
        final chart = acquireChart(<String, Object?>{
          'plugins': [plugin],
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'a': <String, Object?>{'foo': 'foo'},
            },
          },
        });

        _spyOnReset(plugin);
        chart.notifyPlugins(PluginHook.reset);

        expect(plugin.reset, toHaveBeenCalled());
        expect(
          plugin.reset.calls.first().args[2],
          toEqualOptions(<String, Object?>{'foo': 'foo', 'bar': 'bar'}),
        );

        Chart.unregister([plugin]);
      });

      // https://github.com/chartjs/Chart.js/issues/5111#issuecomment-355934167
      testWidgets('should update plugin options', (tester) async {
        final plugin = Plugin<Object?>(id: 'a', reset: (_, _, _) {});
        final chart = acquireChart(<String, Object?>{
          'plugins': [plugin],
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'a': <String, Object?>{'foo': 'foo'},
            },
          },
        });

        _spyOnReset(plugin);

        chart.notifyPlugins(PluginHook.reset);

        expect(plugin.reset, toHaveBeenCalled());
        expect(
          plugin.reset.calls.first().args[2],
          toEqualOptions(<String, Object?>{'foo': 'foo'}),
        );

        (chart.options['plugins']! as JsObjectFace)['a'] = <String, Object?>{
          'bar': 'bar',
        };
        chart.update();

        plugin.reset.calls.reset();
        chart.notifyPlugins(PluginHook.reset);

        expect(plugin.reset, toHaveBeenCalled());
        expect(
          plugin.reset.calls.first().args[2],
          toEqualOptions(<String, Object?>{'bar': 'bar'}),
        );
      });

      // https://github.com/chartjs/Chart.js/issues/10654
      testWidgets(
        'should resolve options even if some subnodes are set as undefined',
        (tester) async {
          Object? runtimeOptions;
          final plugin = Plugin<Object?>(
            id: 'a',
            afterUpdate: (chart, args, options) {
              (jsGet(jsGet(jsGet(options, 'l1'), 'l2'), 'l3')!
                      as JsObjectFace)['display'] =
                  true;
              runtimeOptions = options;
            },
            defaults: <String, Object?>{
              'l1': <String, Object?>{
                'l2': <String, Object?>{
                  'l3': <String, Object?>{'display': false},
                },
              },
            },
          );
          acquireChart(<String, Object?>{
            'plugins': [plugin],
            'options': <String, Object?>{
              'plugins': <String, Object?>{
                'a': <String, Object?>{
                  'l1': <String, Object?>{'l2': undefined},
                },
              },
            },
          });

          expect(
            jsGet(
              jsGet(jsGet(jsGet(runtimeOptions, 'l1'), 'l2'), 'l3'),
              'display',
            ),
            true,
          );
          Chart.unregister([plugin]);
        },
      );

      testWidgets('should disable all plugins', (tester) async {
        final plugin = Plugin<Object?>(id: 'a', reset: (_, _, _) {});
        final chart = acquireChart(<String, Object?>{
          'plugins': [plugin],
          'options': <String, Object?>{'plugins': false},
        });

        _spyOnReset(plugin);

        chart.notifyPlugins(PluginHook.reset);

        expect(plugin.reset, isNot(toHaveBeenCalled()));
      });

      testWidgets('should not restart plugins when a double register occurs', (
        tester,
      ) async {
        final results = <Object?>[];
        final chart = acquireChart(<String, Object?>{
          'plugins': [
            Plugin<Object?>(
              id: 'inline',
              start: (_, _, _) {
                results.add(1);
              },
            ),
          ],
        });

        Chart.register([Plugin<Object?>(id: 'abc', reset: (_, _, _) {})]);
        Chart.register([Plugin<Object?>(id: 'def', reset: (_, _, _) {})]);

        chart.update();

        // The plugin on the chart should only be started once
        expect(results, [1]);
      });

      testWidgets('should default to false for _scriptable, _indexable', (
        tester,
      ) async {
        await waitForDone((done) {
          final plugin = Plugin<Object?>(
            id: 'test',
            start: (chart, args, opts) {
              expect(jsGet(opts, 'fun'), isA<Function>());
              expect(jsCall(jsGet(opts, 'fun'), const []), 'test');
              expect(jsGet(opts, 'arr'), [1, 2, 3]);

              expect(jsGet(jsGet(opts, 'sub'), 'subfun'), isA<Function>());
              expect(
                jsCall(jsGet(jsGet(opts, 'sub'), 'subfun'), const []),
                'subtest',
              );
              expect(jsGet(jsGet(opts, 'sub'), 'subarr'), [3, 2, 1]);
              done();
            },
          );
          acquireChart(<String, Object?>{
            'options': <String, Object?>{
              'plugins': <String, Object?>{
                'test': <String, Object?>{
                  'fun': () => 'test',
                  'arr': [1, 2, 3],
                  'sub': <String, Object?>{
                    'subfun': () => 'subtest',
                    'subarr': [3, 2, 1],
                  },
                },
              },
            },
            'plugins': [plugin],
          });
        });
      });

      testWidgets('should filter event callbacks by plugin events array', (
        tester,
      ) async {
        final results = <String>[];
        final chart = acquireChart(<String, Object?>{
          'options': <String, Object?>{
            'events': ['mousemove', 'test', 'test2', 'pointerleave'],
            'plugins': <String, Object?>{
              'testPlugin': <String, Object?>{
                'events': ['test', 'pointerleave'],
              },
            },
          },
          'plugins': [
            Plugin<Object?>(
              id: 'testPlugin',
              beforeEvent: (_, args, _) {
                results.add('before${args.event.type}');
                return true;
              },
              afterEvent: (_, args, _) {
                results.add('after${args.event.type}');
              },
            ),
          ],
        });
        await triggerMouseEvent(chart, 'mousemove', <String, Object?>{
          'x': 0,
          'y': 0,
        });
        await triggerMouseEvent(chart, 'test', <String, Object?>{
          'x': 0,
          'y': 0,
        });
        await triggerMouseEvent(chart, 'test2', <String, Object?>{
          'x': 0,
          'y': 0,
        });
        await triggerMouseEvent(chart, 'pointerleave', <String, Object?>{
          'x': 0,
          'y': 0,
        });
        expect(results, [
          'beforetest',
          'aftertest',
          'beforemouseout',
          'aftermouseout',
        ]);
      });

      testWidgets('should not call plugins after uninstall', (tester) async {
        final results = <String>[];
        final chart = acquireChart(<String, Object?>{
          'options': <String, Object?>{
            'events': ['test'],
            'plugins': <String, Object?>{
              'testPlugin': <String, Object?>{
                'events': ['test'],
              },
            },
          },
          'plugins': [
            Plugin<Object?>(
              id: 'testPlugin',
              reset: (_, _, _) => results.add('reset'),
              afterDestroy: (_, _, _) => results.add('afterDestroy'),
              uninstall: (_, _, _) => results.add('uninstall'),
            ),
          ],
        })..reset();
        expect(results, ['reset']);
        chart.destroy();
        expect(results, ['reset', 'afterDestroy', 'uninstall']);
        chart.reset();
        expect(results, ['reset', 'afterDestroy', 'uninstall']);
      });
    });
  });
}
