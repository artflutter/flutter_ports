// Ported from Chart.js v4.5.1+7169e651 test/specs/core.plugin.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart'
    show acquireChart, triggerMouseEvent, waitForDone;
import 'package:chartjs_test_utils/pure.dart' show toEqualOptions;
import 'package:flutter_chartjs_port/src/core/core.controller.dart' show Chart;
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_function.dart' show jsCall;
import 'package:flutter_chartjs_port/src/js/js_number.dart' show jsTruthy;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart' show undefined;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import '../support/jasmine.dart';

// Each case builds a chart with `acquireChart` (Chart.js ADR 0022): a chart
// without a type and without datasets, with inline or registered plugins.
// Thus it is a `testWidgets` case. `flutter_test_config.dart` registers the
// built-in components and releases the charts at the unmount of the harness
// body. In phase 5, no built-in plugin exists. Upstream, the built-in
// plugins have no hook `hook`, so the results of the cases do not depend on
// them.
//
// A plugin is a Map, and a hook is a Dart closure (Chart.js ADR 0020,
// section 8). `Chart.register(plugin)` is `Chart.register([plugin])`, and
// `Chart.register([a, b])` is `Chart.register([[a, b]])` (Chart.js ADR 0020,
// section 6). A spec map literal of a JS object has the type
// `<String, Object?>`, because `acquireChart` writes into it.
//
// `spyOn(plugin, 'hook')` is `spyOn(plugin, 'hook')` of
// test/support/jasmine.dart: it replaces the hook with a recording function
// value. `plugin.hook.calls` reads the calls of the spy through the hook of
// the plugin. `toBe` is `same` for objects,
// `toBeTruthy()` and `toBeFalsy()` test [jsTruthy].
//
// The case with `done` is `await waitForDone((done) { ... })`, and an
// `async` case awaits `triggerMouseEvent` (Chart.js ADR 0022, sections 2, 6
// and 7). The hook `start` runs in the constructor of the chart. Thus the
// `done` of `:425` comes before `acquireChart` returns.

void main() {
  group('Chart.plugins', () {
    group('Chart.notifyPlugins', () {
      testWidgets('should call inline plugins with arguments', (tester) async {
        final plugin = <String, Object?>{'hook': () {}};
        final chart = acquireChart(<String, Object?>{
          'plugins': [plugin],
        });
        final args = <String, Object?>{'value': 42};

        spyOn(plugin, 'hook');

        chart.notifyPlugins('hook', args);
        expect(plugin['hook'].calls.count(), 1);
        expect(plugin['hook'].calls.first().args[0], same(chart));
        expect(plugin['hook'].calls.first().args[1], same(args));
        expect(
          plugin['hook'].calls.first().args[2],
          toEqualOptions(<String, Object?>{}),
        );
      });

      testWidgets('should call global plugins with arguments', (tester) async {
        final plugin = <String, Object?>{'id': 'a', 'hook': () {}};
        final chart = acquireChart(<String, Object?>{});
        final args = <String, Object?>{'value': 42};

        spyOn(plugin, 'hook');

        Chart.register([plugin]);
        chart.notifyPlugins('hook', args);
        expect(plugin['hook'].calls.count(), 1);
        expect(plugin['hook'].calls.first().args[0], same(chart));
        expect(plugin['hook'].calls.first().args[1], same(args));
        expect(
          plugin['hook'].calls.first().args[2],
          toEqualOptions(<String, Object?>{}),
        );
        Chart.unregister([plugin]);
      });

      testWidgets(
        'should call plugin only once even if registered multiple times',
        (tester) async {
          final plugin = <String, Object?>{'id': 'test', 'hook': () {}};
          final chart = acquireChart(<String, Object?>{
            'plugins': [plugin, plugin],
          });

          spyOn(plugin, 'hook');

          Chart.register([
            [plugin, plugin],
          ]);
          chart.notifyPlugins('hook');
          expect(plugin['hook'].calls.count(), 1);
          Chart.unregister([plugin]);
        },
      );

      testWidgets('should call plugins in the correct order (global first)', (
        tester,
      ) async {
        final results = <Object?>[];
        final chart = acquireChart(<String, Object?>{
          'plugins': [
            <String, Object?>{
              'hook': () {
                results.add(1);
              },
            },
            <String, Object?>{
              'hook': () {
                results.add(2);
              },
            },
            <String, Object?>{
              'hook': () {
                results.add(3);
              },
            },
          ],
        });

        final plugins = [
          <String, Object?>{
            'id': 'a',
            'hook': () {
              results.add(4);
            },
          },
          <String, Object?>{
            'id': 'b',
            'hook': () {
              results.add(5);
            },
          },
          <String, Object?>{
            'id': 'c',
            'hook': () {
              results.add(6);
            },
          },
        ];
        Chart.register([plugins]);

        final ret = chart.notifyPlugins('hook');
        expect(jsTruthy(ret), isTrue);
        expect(results, [4, 5, 6, 1, 2, 3]);
        Chart.unregister([plugins]);
      });

      testWidgets('should return TRUE if no plugin explicitly returns FALSE', (
        tester,
      ) async {
        final chart = acquireChart(<String, Object?>{
          'plugins': [
            <String, Object?>{'hook': () => undefined},
            <String, Object?>{
              'hook': () {
                return null;
              },
            },
            <String, Object?>{
              'hook': () {
                return 0;
              },
            },
            <String, Object?>{
              'hook': () {
                return true;
              },
            },
            <String, Object?>{
              'hook': () {
                return 1;
              },
            },
          ],
        });

        final plugins = chart.config.plugins! as List<Object?>;
        for (final plugin in plugins) {
          spyOn(plugin! as Map<String, Object?>, 'hook').and.callThrough();
        }

        final ret = chart.notifyPlugins('hook');
        expect(jsTruthy(ret), isTrue);
        for (final plugin in plugins) {
          expect(jsGet(plugin, 'hook'), toHaveBeenCalled());
        }
      });

      testWidgets(
        'should return FALSE if any plugin explicitly returns FALSE',
        (
          tester,
        ) async {
          final chart = acquireChart(<String, Object?>{
            'plugins': [
              <String, Object?>{'hook': () => undefined},
              <String, Object?>{
                'hook': () {
                  return null;
                },
              },
              <String, Object?>{
                'hook': () {
                  return false;
                },
              },
              <String, Object?>{
                'hook': () {
                  return 42;
                },
              },
              <String, Object?>{
                'hook': () {
                  return 'bar';
                },
              },
            ],
          });

          final plugins = chart.config.plugins! as List<Object?>;
          for (final plugin in plugins) {
            spyOn(plugin! as Map<String, Object?>, 'hook').and.callThrough();
          }

          final ret = chart.notifyPlugins('hook', <String, Object?>{
            'cancelable': true,
          });
          expect(jsTruthy(ret), isFalse);
          expect(jsGet(plugins[0], 'hook'), toHaveBeenCalled());
          expect(jsGet(plugins[1], 'hook'), toHaveBeenCalled());
          expect(jsGet(plugins[2], 'hook'), toHaveBeenCalled());
          expect(jsGet(plugins[3], 'hook'), isNot(toHaveBeenCalled()));
          expect(jsGet(plugins[4], 'hook'), isNot(toHaveBeenCalled()));
        },
      );
    });

    group('config.options.plugins', () {
      testWidgets('should call plugins with options at last argument', (
        tester,
      ) async {
        final plugin = <String, Object?>{'id': 'foo', 'hook': () {}};

        final chart = acquireChart(<String, Object?>{
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'foo': <String, Object?>{'a': '123'},
            },
          },
        });

        spyOn(plugin, 'hook');

        Chart.register([plugin]);
        chart
          ..notifyPlugins('hook')
          ..notifyPlugins('hook', <String, Object?>{'arg1': 'bla'})
          ..notifyPlugins('hook', <String, Object?>{'arg1': 'bla', 'arg2': 42});

        expect(plugin['hook'].calls.count(), 3);
        expect(
          plugin['hook'].calls.argsFor(0)[2],
          toEqualOptions(<String, Object?>{'a': '123'}),
        );
        expect(
          plugin['hook'].calls.argsFor(1)[2],
          toEqualOptions(<String, Object?>{'a': '123'}),
        );
        expect(
          plugin['hook'].calls.argsFor(2)[2],
          toEqualOptions(<String, Object?>{'a': '123'}),
        );

        Chart.unregister([plugin]);
      });

      testWidgets(
        'should call plugins with options associated to their identifier',
        (tester) async {
          final plugins = <String, Map<String, Object?>>{
            'a': <String, Object?>{'id': 'a', 'hook': () {}},
            'b': <String, Object?>{'id': 'b', 'hook': () {}},
            'c': <String, Object?>{'id': 'c', 'hook': () {}},
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

          spyOn(plugins['a']!, 'hook');
          spyOn(plugins['b']!, 'hook');
          spyOn(plugins['c']!, 'hook');

          chart.notifyPlugins('hook');

          expect(plugins['a']!['hook'], toHaveBeenCalled());
          expect(plugins['b']!['hook'], toHaveBeenCalled());
          expect(plugins['c']!['hook'], toHaveBeenCalled());
          expect(
            plugins['a']!['hook'].calls.first().args[2],
            toEqualOptions(<String, Object?>{'a': '123'}),
          );
          expect(
            plugins['b']!['hook'].calls.first().args[2],
            toEqualOptions(<String, Object?>{'b': '456'}),
          );
          expect(
            plugins['c']!['hook'].calls.first().args[2],
            toEqualOptions(<String, Object?>{'c': '789'}),
          );

          Chart.unregister([plugins['a']]);
        },
      );

      testWidgets(
        'should not call plugins when config.options.plugins.{id} is FALSE',
        (tester) async {
          final plugins = <String, Map<String, Object?>>{
            'a': <String, Object?>{'id': 'a', 'hook': () {}},
            'b': <String, Object?>{'id': 'b', 'hook': () {}},
            'c': <String, Object?>{'id': 'c', 'hook': () {}},
          };

          Chart.register([plugins['a']]);

          final chart = acquireChart(<String, Object?>{
            'plugins': [plugins['b'], plugins['c']],
            'options': <String, Object?>{
              'plugins': <String, Object?>{'a': false, 'b': false},
            },
          });

          spyOn(plugins['a']!, 'hook');
          spyOn(plugins['b']!, 'hook');
          spyOn(plugins['c']!, 'hook');

          chart.notifyPlugins('hook');

          expect(plugins['a']!['hook'], isNot(toHaveBeenCalled()));
          expect(plugins['b']!['hook'], isNot(toHaveBeenCalled()));
          expect(plugins['c']!['hook'], toHaveBeenCalled());

          Chart.unregister([plugins['a']]);
        },
      );

      testWidgets(
        'should call plugins with default options when plugin options is TRUE',
        (tester) async {
          final plugin = <String, Object?>{
            'id': 'a',
            'hook': () {},
            'defaults': <String, Object?>{'a': 42},
          };

          Chart.register([plugin]);

          final chart = acquireChart(<String, Object?>{
            'options': <String, Object?>{
              'plugins': <String, Object?>{'a': true},
            },
          });

          spyOn(plugin, 'hook');

          chart.notifyPlugins('hook');

          expect(plugin['hook'], toHaveBeenCalled());
          expect(
            jsObjectKeys(
              plugin['hook'].calls.first().args[2]! as Map<String, Object?>,
            ),
            ['a'],
          );
          // jasmine.objectContaining({a: 42})
          expect(plugin['hook'].calls.first().args[2], containsPair('a', 42));

          Chart.unregister([plugin]);
        },
      );

      testWidgets(
        'should call plugins with default options if plugin config options '
        'is undefined',
        (tester) async {
          final plugin = <String, Object?>{
            'id': 'a',
            'hook': () {},
            'defaults': <String, Object?>{'a': 'foobar'},
          };

          Chart.register([plugin]);
          spyOn(plugin, 'hook');

          acquireChart().notifyPlugins('hook');

          expect(plugin['hook'], toHaveBeenCalled());
          expect(
            plugin['hook'].calls.first().args[2],
            toEqualOptions(<String, Object?>{'a': 'foobar'}),
          );

          Chart.unregister([plugin]);
        },
      );

      // https://github.com/chartjs/Chart.js/issues/10482
      testWidgets('should resolve defaults for local plugins', (tester) async {
        final plugin = <String, Object?>{
          'id': 'a',
          'hook': () {},
          'defaults': <String, Object?>{'bar': 'bar'},
        };
        final chart = acquireChart(<String, Object?>{
          'plugins': [plugin],
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'a': <String, Object?>{'foo': 'foo'},
            },
          },
        });

        spyOn(plugin, 'hook');
        chart.notifyPlugins('hook');

        expect(plugin['hook'], toHaveBeenCalled());
        expect(
          plugin['hook'].calls.first().args[2],
          toEqualOptions(<String, Object?>{'foo': 'foo', 'bar': 'bar'}),
        );

        Chart.unregister([plugin]);
      });

      // https://github.com/chartjs/Chart.js/issues/5111#issuecomment-355934167
      testWidgets('should update plugin options', (tester) async {
        final plugin = <String, Object?>{'id': 'a', 'hook': () {}};
        final chart = acquireChart(<String, Object?>{
          'plugins': [plugin],
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'a': <String, Object?>{'foo': 'foo'},
            },
          },
        });

        spyOn(plugin, 'hook');

        chart.notifyPlugins('hook');

        expect(plugin['hook'], toHaveBeenCalled());
        expect(
          plugin['hook'].calls.first().args[2],
          toEqualOptions(<String, Object?>{'foo': 'foo'}),
        );

        (chart.options['plugins']! as Map<String, Object?>)['a'] =
            <String, Object?>{'bar': 'bar'};
        chart.update();

        plugin['hook'].calls.reset();
        chart.notifyPlugins('hook');

        expect(plugin['hook'], toHaveBeenCalled());
        expect(
          plugin['hook'].calls.first().args[2],
          toEqualOptions(<String, Object?>{'bar': 'bar'}),
        );
      });

      // https://github.com/chartjs/Chart.js/issues/10654
      testWidgets(
        'should resolve options even if some subnodes are set as undefined',
        (tester) async {
          Object? runtimeOptions;
          final plugin = <String, Object?>{
            'id': 'a',
            'afterUpdate': (Object? chart, Object? args, Object? options) {
              (jsGet(jsGet(jsGet(options, 'l1'), 'l2'), 'l3')!
                      as Map<String, Object?>)['display'] =
                  true;
              runtimeOptions = options;
            },
            'defaults': <String, Object?>{
              'l1': <String, Object?>{
                'l2': <String, Object?>{
                  'l3': <String, Object?>{'display': false},
                },
              },
            },
          };
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
        final plugin = <String, Object?>{'id': 'a', 'hook': () {}};
        final chart = acquireChart(<String, Object?>{
          'plugins': [plugin],
          'options': <String, Object?>{'plugins': false},
        });

        spyOn(plugin, 'hook');

        chart.notifyPlugins('hook');

        expect(plugin['hook'], isNot(toHaveBeenCalled()));
      });

      testWidgets('should not restart plugins when a double register occurs', (
        tester,
      ) async {
        final results = <Object?>[];
        final chart = acquireChart(<String, Object?>{
          'plugins': [
            <String, Object?>{
              'start': () {
                results.add(1);
              },
            },
          ],
        });

        Chart.register([
          <String, Object?>{'id': 'abc', 'hook': () {}},
        ]);
        Chart.register([
          <String, Object?>{'id': 'def', 'hook': () {}},
        ]);

        chart.update();

        // The plugin on the chart should only be started once
        expect(results, [1]);
      });

      testWidgets('should default to false for _scriptable, _indexable', (
        tester,
      ) async {
        await waitForDone((done) {
          final plugin = <String, Object?>{
            'id': 'test',
            'start': (Object? chart, Object? args, Object? opts) {
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
          };
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
            <String, Object?>{
              'id': 'testPlugin',
              'beforeEvent': (Object? chart, Object? args) {
                results.add(
                  'before${(jsGet(args, 'event')! as types.ChartEvent).type}',
                );
              },
              'afterEvent': (Object? chart, Object? args) {
                results.add(
                  'after${(jsGet(args, 'event')! as types.ChartEvent).type}',
                );
              },
            },
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
            <String, Object?>{
              'id': 'testPlugin',
              'reset': () => results.add('reset'),
              'afterDestroy': () => results.add('afterDestroy'),
              'uninstall': () => results.add('uninstall'),
            },
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
