// Ported from Chart.js v4.6.1 test/specs/core.plugin.tests.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-typed-plugins, the native plugins of the cases.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/drop_extra_args.dart';
import '../support/plugin_defaults.dart';

// Each case builds a chart with `acquireChartRoot` (Chart.js ADR 0022): a chart
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
// section 6). The chart receives mutable native configuration scopes.
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
// recording closure into the hook field and returns the list of the calls,
// a `_HookCall` record `(chart, args, options)` for each call.
// `plugin.hook.calls.count()` is the length of the list, `calls.first()` its
// first item, and `toHaveBeenCalled()` a list that is not empty. `toBe` is
// `same` for objects. A notify returns a `bool?`:
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

/// One call of a hook: the chart, the args object and the options.
typedef _HookCall = ({IChart chart, Object args, Object? options});

/// `spyOn(plugin, 'hook')`: puts a recording closure into the hook `reset`
/// of [plugin] and returns its calls. As a Jasmine spy without
/// `callThrough`, the closure does not call the original hook.
List<_HookCall> _spyOnReset(Plugin<Object?> plugin) {
  final calls = <_HookCall>[];
  plugin.reset = (chart, args, options) {
    calls.add((chart: chart, args: args, options: options));
  };
  return calls;
}

/// `spyOn(plugin, 'hook').and.callThrough()`: puts a recording closure into
/// the cancelable hook `beforeTooltipDraw` of [plugin] and returns its
/// calls. The closure calls the original hook and returns its result, or
/// `true` when the plugin has no such hook (a JS `undefined` does not
/// cancel).
List<_HookCall> _spyOnTooltipDraw(Plugin<Object?> plugin) {
  final calls = <_HookCall>[];
  final original = plugin.beforeTooltipDraw;
  plugin.beforeTooltipDraw = (chart, args, options) {
    calls.add((chart: chart, args: args, options: options));
    return original?.call(chart, args, options) ?? true;
  };
  return calls;
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
        final chart = acquireChartRoot(
          ChartConfigurationScope()..plugins = [plugin],
        );
        final args = _SpecArgs(value: 42);

        final calls = _spyOnReset(plugin);

        chart.notifyPlugins(PluginHook.reset, args);
        expect(calls, hasLength(1));
        expect(calls.first.chart, same(chart));
        expect(calls.first.args, same(args));
        expect(calls.first.options, toEqualOptions(<String, Object?>{}));
      });

      testWidgets('should call global plugins with arguments', (tester) async {
        final plugin = Plugin<Object?>(id: 'a', reset: (_, _, _) {});
        final chart = acquireChartRoot(ChartConfigurationScope());
        final args = _SpecArgs(value: 42);

        final calls = _spyOnReset(plugin);

        Chart.register([plugin]);
        chart.notifyPlugins(PluginHook.reset, args);
        expect(calls, hasLength(1));
        expect(calls.first.chart, same(chart));
        expect(calls.first.args, same(args));
        expect(calls.first.options, toEqualOptions(<String, Object?>{}));
        Chart.unregister([plugin]);
      });

      testWidgets(
        'should call plugin only once even if registered multiple times',
        (tester) async {
          final plugin = Plugin<Object?>(id: 'test', reset: (_, _, _) {});
          final chart = acquireChartRoot(
            ChartConfigurationScope()..plugins = [plugin, plugin],
          );

          final calls = _spyOnReset(plugin);

          Chart.register([
            [plugin, plugin],
          ]);
          chart.notifyPlugins(PluginHook.reset);
          expect(calls, hasLength(1));
          Chart.unregister([plugin]);
        },
      );

      testWidgets('should call plugins in the correct order (global first)', (
        tester,
      ) async {
        final results = <Object?>[];
        final chart = acquireChartRoot(
          ChartConfigurationScope()
            ..plugins = [
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
        );

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
        final chart = acquireChartRoot(
          ChartConfigurationScope()
            ..plugins = [
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
        );

        final plugins = _inlinePlugins(chart);
        final calls = [for (final plugin in plugins) _spyOnTooltipDraw(plugin)];

        final ret = _notifyCancelable(chart);
        expect(ret, isTrue);
        for (final pluginCalls in calls) {
          expect(pluginCalls, isNotEmpty);
        }
      });

      // The hooks of upstream return `undefined`, `null`, `false`, `42` and
      // `'bar'`, and the notify gives `{cancelable: true}`. Here the hook is
      // cancelable, and its hooks return `true`, `true`, `false`, `true` and
      // `true`.
      testWidgets(
        'should return FALSE if any plugin explicitly returns FALSE',
        (tester) async {
          final chart = acquireChartRoot(
            ChartConfigurationScope()
              ..plugins = [
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
          );

          final plugins = _inlinePlugins(chart);
          final calls = [
            for (final plugin in plugins) _spyOnTooltipDraw(plugin),
          ];

          final ret = _notifyCancelable(chart);
          expect(ret, isFalse);
          expect(calls[0], isNotEmpty);
          expect(calls[1], isNotEmpty);
          expect(calls[2], isNotEmpty);
          expect(calls[3], isEmpty);
          expect(calls[4], isEmpty);
        },
      );
    });

    group('config.options.plugins', () {
      testWidgets('should call plugins with options at last argument', (
        tester,
      ) async {
        final plugin = Plugin<Object?>(id: 'foo', reset: (_, _, _) {});

        final chart = acquireChartRoot(
          ChartConfigurationScope()
            ..options = scopeFromMap(ChartOptionsScope(), <String, Object?>{
              'plugins': <String, Object?>{
                'foo': <String, Object?>{'a': '123'},
              },
            }),
        );

        final calls = _spyOnReset(plugin);

        Chart.register([plugin]);
        chart
          ..notifyPlugins(PluginHook.reset)
          ..notifyPlugins(PluginHook.reset, _SpecArgs(arg1: 'bla'))
          ..notifyPlugins(PluginHook.reset, _SpecArgs(arg1: 'bla', arg2: 42));

        expect(calls, hasLength(3));
        expect(calls[0].options, toEqualOptions(<String, Object?>{'a': '123'}));
        expect(calls[1].options, toEqualOptions(<String, Object?>{'a': '123'}));
        expect(calls[2].options, toEqualOptions(<String, Object?>{'a': '123'}));

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

          final chart = acquireChartRoot(
            ChartConfigurationScope()
              ..plugins = <Plugin<Object?>>[plugins['b']!, plugins['c']!]
              ..options = scopeFromMap(ChartOptionsScope(), <String, Object?>{
                'plugins': <String, Object?>{
                  'a': <String, Object?>{'a': '123'},
                  'b': <String, Object?>{'b': '456'},
                  'c': <String, Object?>{'c': '789'},
                },
              }),
          );

          final callsA = _spyOnReset(plugins['a']!);
          final callsB = _spyOnReset(plugins['b']!);
          final callsC = _spyOnReset(plugins['c']!);

          chart.notifyPlugins(PluginHook.reset);

          expect(callsA, isNotEmpty);
          expect(callsB, isNotEmpty);
          expect(callsC, isNotEmpty);
          expect(
            callsA.first.options,
            toEqualOptions(<String, Object?>{'a': '123'}),
          );
          expect(
            callsB.first.options,
            toEqualOptions(<String, Object?>{'b': '456'}),
          );
          expect(
            callsC.first.options,
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

          final chart = acquireChartRoot(
            ChartConfigurationScope()
              ..plugins = <Plugin<Object?>>[plugins['b']!, plugins['c']!]
              ..options = scopeFromMap(ChartOptionsScope(), <String, Object?>{
                'plugins': <String, Object?>{'a': false, 'b': false},
              }),
          );

          final callsA = _spyOnReset(plugins['a']!);
          final callsB = _spyOnReset(plugins['b']!);
          final callsC = _spyOnReset(plugins['c']!);

          chart.notifyPlugins(PluginHook.reset);

          expect(callsA, isEmpty);
          expect(callsB, isEmpty);
          expect(callsC, isNotEmpty);

          Chart.unregister([plugins['a']]);
        },
      );

      testWidgets(
        'should call plugins with default options when plugin options is TRUE',
        (tester) async {
          final plugin = Plugin<Object?>(
            id: 'a',
            reset: (_, _, _) {},
            defaults: pluginDefaults(<String, Object?>{'a': 42}),
          );

          Chart.register([plugin]);

          final chart = acquireChartRoot(
            ChartConfigurationScope()
              ..options = scopeFromMap(ChartOptionsScope(), <String, Object?>{
                'plugins': <String, Object?>{'a': true},
              }),
          );

          final calls = _spyOnReset(plugin);

          chart.notifyPlugins(PluginHook.reset);

          expect(calls, isNotEmpty);
          expect(jsObjectKeys(calls.first.options), ['a']);
          // jasmine.objectContaining({a: 42}): the keys are `['a']`, so the
          // compare of the key `a` is the whole check.
          expect(
            calls.first.options,
            toEqualOptions(<String, Object?>{'a': 42}),
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
            defaults: pluginDefaults(<String, Object?>{'a': 'foobar'}),
          );

          Chart.register([plugin]);
          final calls = _spyOnReset(plugin);

          acquireChartRoot(ChartConfigurationScope())
              .notifyPlugins(PluginHook.reset);

          expect(calls, isNotEmpty);
          expect(
            calls.first.options,
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
          defaults: pluginDefaults(<String, Object?>{'bar': 'bar'}),
        );
        final chart = acquireChartRoot(
          ChartConfigurationScope()
            ..plugins = [plugin]
            ..options = scopeFromMap(ChartOptionsScope(), <String, Object?>{
              'plugins': <String, Object?>{
                'a': <String, Object?>{'foo': 'foo'},
              },
            }),
        );

        final calls = _spyOnReset(plugin);
        chart.notifyPlugins(PluginHook.reset);

        expect(calls, isNotEmpty);
        expect(
          calls.first.options,
          toEqualOptions(<String, Object?>{'foo': 'foo', 'bar': 'bar'}),
        );

        Chart.unregister([plugin]);
      });

      // https://github.com/chartjs/Chart.js/issues/5111#issuecomment-355934167
      testWidgets('should update plugin options', (tester) async {
        final plugin = Plugin<Object?>(id: 'a', reset: (_, _, _) {});
        final chart = acquireChartRoot(
          ChartConfigurationScope()
            ..plugins = [plugin]
            ..options = scopeFromMap(ChartOptionsScope(), <String, Object?>{
              'plugins': <String, Object?>{
                'a': <String, Object?>{'foo': 'foo'},
              },
            }),
        );

        final calls = _spyOnReset(plugin);

        chart.notifyPlugins(PluginHook.reset);

        expect(calls, isNotEmpty);
        expect(
          calls.first.options,
          toEqualOptions(<String, Object?>{'foo': 'foo'}),
        );

        (chart.options['plugins']! as JsObjectFace)['a'] = <String, Object?>{
          'bar': 'bar',
        };
        chart.update();

        calls.clear();
        chart.notifyPlugins(PluginHook.reset);

        expect(calls, isNotEmpty);
        expect(
          calls.first.options,
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
            defaults: pluginDefaults(<String, Object?>{
              'l1': <String, Object?>{
                'l2': <String, Object?>{
                  'l3': <String, Object?>{'display': false},
                },
              },
            }),
          );
          acquireChartRoot(
            ChartConfigurationScope()
              ..plugins = [plugin]
              ..options = scopeFromMap(ChartOptionsScope(), <String, Object?>{
                'plugins': <String, Object?>{
                  'a': <String, Object?>{
                    'l1': <String, Object?>{'l2': undefined},
                  },
                },
              }),
          );

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
        // The core explicitly accepts false to disable every plugin. The
        // scope's dictionary cell keeps that sentinel as a foreign value.
        final saved = foreignAudit;
        foreignAudit = (owner, key, raw) {
          if (owner == 'ChartOptionsScope' &&
              key == 'plugins' &&
              raw == false) {
            return;
          }
          saved?.call(owner, key, raw);
        };
        addTearDown(() => foreignAudit = saved);
        final plugin = Plugin<Object?>(id: 'a', reset: (_, _, _) {});
        final chart = acquireChartRoot(
          ChartConfigurationScope()
            ..plugins = [plugin]
            ..options = scopeFromMap(ChartOptionsScope(), <String, Object?>{
              'plugins': false,
            }),
        );

        final calls = _spyOnReset(plugin);

        chart.notifyPlugins(PluginHook.reset);

        expect(calls, isEmpty);
      });

      testWidgets('should not restart plugins when a double register occurs', (
        tester,
      ) async {
        final results = <Object?>[];
        final chart = acquireChartRoot(
          ChartConfigurationScope()
            ..plugins = [
              Plugin<Object?>(
                id: 'inline',
                start: (_, _, _) {
                  results.add(1);
                },
              ),
            ],
        );

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
              expect(
                callDroppingExtraArgs(jsGet(opts, 'fun'), const []),
                'test',
              );
              expect(jsGet(opts, 'arr'), [1, 2, 3]);

              expect(jsGet(jsGet(opts, 'sub'), 'subfun'), isA<Function>());
              expect(
                callDroppingExtraArgs(
                  jsGet(jsGet(opts, 'sub'), 'subfun'),
                  const [],
                ),
                'subtest',
              );
              expect(jsGet(jsGet(opts, 'sub'), 'subarr'), [3, 2, 1]);
              done();
            },
          );
          acquireChartRoot(
            ChartConfigurationScope()
              ..options = scopeFromMap(ChartOptionsScope(), <String, Object?>{
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
              })
              ..plugins = [plugin],
          );
        });
      });

      testWidgets('should filter event callbacks by plugin events array', (
        tester,
      ) async {
        final results = <String>[];
        final chart = acquireChartRoot(
          ChartConfigurationScope()
            ..options = scopeFromMap(ChartOptionsScope(), <String, Object?>{
              'events': ['mousemove', 'test', 'test2', 'pointerleave'],
              'plugins': <String, Object?>{
                'testPlugin': <String, Object?>{
                  'events': ['test', 'pointerleave'],
                },
              },
            })
            ..plugins = [
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
        );
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
        final chart = acquireChartRoot(
          ChartConfigurationScope()
            ..options = scopeFromMap(ChartOptionsScope(), <String, Object?>{
              'events': ['test'],
              'plugins': <String, Object?>{
                'testPlugin': <String, Object?>{
                  'events': ['test'],
                },
              },
            })
            ..plugins = [
              Plugin<Object?>(
                id: 'testPlugin',
                reset: (_, _, _) => results.add('reset'),
                afterDestroy: (_, _, _) => results.add('afterDestroy'),
                uninstall: (_, _, _) => results.add('uninstall'),
              ),
            ],
        )..reset();
        expect(results, ['reset']);
        chart.destroy();
        expect(results, ['reset', 'afterDestroy', 'uninstall']);
        chart.reset();
        expect(results, ['reset', 'afterDestroy', 'uninstall']);
      });
    });
  });
}
