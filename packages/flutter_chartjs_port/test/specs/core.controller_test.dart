// Ported from Chart.js v4.6.1 test/specs/core.controller.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
// The spec builds charts of flutter_chartjs_port, which does not export lib/src
// yet.
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.collection.dart'
    show notifyArrayListeners;
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart' as helpers;
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/platform/platform.basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import '../support/jasmine.dart';

// `Chart` is the class of core.controller.dart. The spec runs on the VM: a
// chart reaches the chart host and dart:ui.
//
// Each chart case is a `testWidgets` case with the harness of Chart.js ADR
// 0022, section 2: `acquireChart`, `waitForResize`, `waitForDone`,
// `setTimeout` and `toBeChartOfSize`.
//
// The spec forms of Chart.js ADR 0022, section 2:
// - `chart.canvas.parentNode` is `chart.canvas!.parentElement`. The
//   `parentNode` of a harness element keeps its text.
// - `window.document.body` is `document.body`.
// - `new Chart(item, config)` is `Chart(item, config)`.
// - `fail()` is `fail('Failed')`, the message of Jasmine.
// - A spec object is a `Map<String, Object?>`. A property chain of the
//   spec, for example `config.data.labels`, is a chain of `jsGet`.
// - `toBeUndefined()` of `chart.chartArea` is `isNull`: Dart null stands
//   for JS undefined. `not.toBeDefined()` of a scale is `isNull` too.
// - `Chart.defaults` is `defaults` of core.defaults.dart, and
//   `Chart.helpers.merge` is `merge` of helpers.core.dart.
//   `delete object.key` is [Map.remove].
// - `toEqual` of two option objects is `jasmineEquals`, the deep equality
//   of Jasmine. `jasmine.objectContaining` is `objectContaining`. An
//   `expect` on a resolver gives it in a `JasmineOptions`
//   (test/support/jasmine.dart).
//   `new Error(m)` is a StateError with the message m.
//
// flutter_test_config.dart registers the built-in components before main().
// Thus the scales of phase 6, the controllers of phase 7 and the plugins of
// phase 8 are in the registry, and the defaults of the scales are in
// `defaults.scales`. The pie and line cases get their controller from the
// registry.
//
// Three cases without acquireChart build a chart with
// `Chart(canvas, config)` on a canvas of `document.createElement`. Its
// standby host gives FlutterPlatform, and the chart starts detached. The
// append to the harness body attaches it at the mutation checkpoint
// (Chart.js ADR 0022, sections 3 and 4).
//
// :3 `const overrides = Chart.overrides` is `Chart.overrides`; the cases
// read `overrides.line` (`_line`).
//
// The other spec forms of the chart cases:
// - `chart.getActiveElements()` in `toEqual` is `_activeElements(chart)`:
//   the object `{element, datasetIndex, index}` of each active element.
// - `chart._metasets`, `chart._sortedMetasets` and `meta._dataset` are
//   `chart.metasets`, `chart.sortedMetasets` and `meta.dataset_` (Chart.js
//   ADR 0012 and ADR 0023). A hole of the metasets is Dart null.
// - `chart.data.datasets.splice(...)` is `jsSplice`: no listener watches
//   the datasets array.
// - `[].concat(hooks.a, hooks.b)` is a list literal with spreads.
// - `'before-' + args.index` is `jsToString` of the index.
// - A `beforeEach` or an `afterEach` that reads a chart is a local function
//   that each case calls first or last.
// - `push`, `pop`, `shift`, `splice` and `unshift` of `chart.data.labels` or
//   of a data array are `_push`, `_pop`, `_shift`, `_splice` and `_unshift`:
//   the change of the List, then `notifyArrayListeners`, the body of the
//   hooked method (differences.md row platform-array-events). The labels
//   array has no listeners, so its notification does nothing, as upstream.
// - `chart.data.labels` is `_labels(chart)`, and
//   `chart.data.datasets[i].data` is `_data(chart, i)`.
// - `chart.tooltip` is the field of `Chart`, a `types.TooltipModel?`.
//   `chart._active` is `chart.active`, and `tooltip._active` is
//   `_tooltipActive(tooltip)`.
// - `chart.options.plugins.tooltip = value` writes the key `tooltip` of the
//   Map `chart.options['plugins']`.

/// :3 `const overrides = Chart.overrides`: `overrides.line`.
Map<String, Object?> get _line =>
    jsGet(Chart.overrides, 'line')! as Map<String, Object?>;

/// `chart.data.datasets`.
List<Object?> _datasets(Chart chart) =>
    jsGet(chart.data, 'datasets')! as List<Object?>;

/// `chart.getActiveElements()` as Jasmine `toEqual` reads it: each active
/// element is the object `{element, datasetIndex, index}`.
List<Object?> _activeElements(Chart chart) => [
  for (final active in chart.getActiveElements())
    <String, Object?>{
      'element': active.element,
      'datasetIndex': active.datasetIndex,
      'index': active.index,
    },
];

/// `tooltip._active`, the active elements of [tooltip], read by name
/// (core.controller.tests.js:1719). The `Tooltip` class of
/// plugin.tooltip.dart extends `Element` and gives the property by name.
List<types.ActiveElement> _tooltipActive(types.TooltipModel tooltip) =>
    (tooltip as Element)['_active']! as List<types.ActiveElement>;

/// `point.y` of a data element.
double _y(types.Element point) => (point as Element).y;

/// `chart.data.labels`.
List<Object?> _labels(Chart chart) =>
    jsGet(chart.data, 'labels')! as List<Object?>;

/// `chart.data.datasets[index].data`.
List<Object?> _data(Chart chart, int index) =>
    jsGet(_datasets(chart)[index], 'data')! as List<Object?>;

/// `array.push(...items)`: the change, then the notification of the hooked
/// method (differences.md row platform-array-events).
void _push(List<Object?> array, List<Object?> items) {
  array.addAll(items);
  notifyArrayListeners(array, 'push', items);
}

/// `array.pop()`.
void _pop(List<Object?> array) {
  if (array.isNotEmpty) array.removeLast();
  notifyArrayListeners(array, 'pop', const []);
}

/// `array.shift()`.
void _shift(List<Object?> array) {
  if (array.isNotEmpty) array.removeAt(0);
  notifyArrayListeners(array, 'shift', const []);
}

/// `array.splice(start, deleteCount, ...items)`.
void _splice(
  List<Object?> array,
  int start,
  int deleteCount, [
  List<Object?> items = const [],
]) {
  jsSplice(array, start.toDouble(), deleteCount.toDouble(), items);
  notifyArrayListeners(array, 'splice', [start, deleteCount, ...items]);
}

/// `array.unshift(...items)`.
void _unshift(List<Object?> array, List<Object?> items) {
  array.insertAll(0, items);
  notifyArrayListeners(array, 'unshift', items);
}

void main() {
  group('Chart', () {
    // https://github.com/chartjs/Chart.js/issues/2481
    // See global.deprecations.tests.js for backward compatibility
    testWidgets('should be defined and prototype of chart instances', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{});
      expect(Chart, isNotNull);
      expect(Chart, isA<Object>());
      // `chart.constructor` is the runtime type.
      expect(chart.runtimeType, Chart);
      expect(chart, isA<Chart>());
    });

    testWidgets('should throw an error if the canvas is already in use', (
      tester,
    ) async {
      final config = <String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[1, 2, 3, 4],
            },
          ],
          'labels': <Object?>['A', 'B', 'C', 'D'],
        },
      };
      final chart = acquireChart(config);
      final canvas = chart.canvas;

      Chart createChart() {
        return Chart(canvas, config);
      }

      // `chart.canvas.id` is the reflection of the attribute `id`: '' for a
      // canvas without it.
      expect(
        createChart,
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Canvas is already in use. '
                "Chart with ID '${jsToString(chart.id)}'"
                ' must be destroyed before the canvas with ID '
                "'${chart.canvas!.getAttribute('id') ?? ''}' can be reused.",
          ),
        ),
      );

      chart.destroy();
      expect(createChart, returnsNormally);
    });

    group('config initialization', () {
      testWidgets('should create missing config.data properties', (
        tester,
      ) async {
        final chart = acquireChart(<String, Object?>{});
        final data = chart.data;

        expect(data, isA<Map<String, Object?>>());
        expect(data['labels'], isA<List<Object?>>());
        expect(jsGet(data['labels'], 'length'), 0);
        expect(data['datasets'], isA<List<Object?>>());
        expect(jsGet(data['datasets'], 'length'), 0);
      });

      testWidgets('should not alter config.data references', (tester) async {
        final ds0 = <String, Object?>{
          'data': <Object?>[10, 11, 12, 13],
        };
        final ds1 = <String, Object?>{
          'data': <Object?>[20, 21, 22, 23],
        };
        final datasets = <Object?>[ds0, ds1];
        final labels = <Object?>[0, 1, 2, 3];
        final data = <String, Object?>{'labels': labels, 'datasets': datasets};

        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': data,
        });

        expect(chart.data, same(data));
        expect(chart.data['labels'], same(labels));
        expect(chart.data['datasets'], same(datasets));
        expect(jsGet(chart.data['datasets'], 0), same(ds0));
        expect(jsGet(chart.data['datasets'], 1), same(ds1));
        expect(
          jsGet(jsGet(chart.data['datasets'], 0), 'data'),
          same(ds0['data']),
        );
        expect(
          jsGet(jsGet(chart.data['datasets'], 1), 'data'),
          same(ds1['data']),
        );
      });

      testWidgets('should define chart.data as an alias for config.data', (
        tester,
      ) async {
        final config = <String, Object?>{
          'data': <String, Object?>{
            'labels': <Object?>[],
            'datasets': <Object?>[],
          },
        };
        final chart = acquireChart(config);

        expect(chart.data, same(config['data']));

        chart.data = <String, Object?>{
          'labels': <Object?>[1, 2, 3],
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[4, 5, 6],
            },
          ],
        };

        expect(config['data'], same(chart.data));
        expect(jsGet(config['data'], 'labels'), [1, 2, 3]);
        expect(
          jsGet(jsGet(jsGet(config['data'], 'datasets'), 0), 'data'),
          [4, 5, 6],
        );

        config['data'] = <String, Object?>{
          'labels': <Object?>[7, 8, 9],
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[10, 11, 12],
            },
          ],
        };

        expect(chart.data, same(config['data']));
        expect(jsGet(chart.data, 'labels'), [7, 8, 9]);
        expect(
          jsGet(jsGet(jsGet(chart.data, 'datasets'), 0), 'data'),
          [10, 11, 12],
        );
      });

      testWidgets('should initialize config with default interaction options', (
        tester,
      ) async {
        void callback() {}
        final defaults = Chart.defaults;

        defaults['onHover'] = callback;
        _line['interaction'] = <String, Object?>{'mode': 'test'};

        final chart = acquireChart(<String, Object?>{'type': 'line'});

        final options = chart.options;
        expect(
          jsGet(options['font'], 'size'),
          jsGet(defaults['font'], 'size'),
        );
        expect(options['onHover'], same(callback));
        expect(jsGet(options['hover'], 'mode'), 'test');

        defaults['onHover'] = null;
        _line.remove('interaction');
      });

      testWidgets('should initialize config with default hover options', (
        tester,
      ) async {
        void callback() {}
        final defaults = Chart.defaults;

        defaults['onHover'] = callback;
        _line['hover'] = <String, Object?>{'mode': 'test'};

        final chart = acquireChart(<String, Object?>{'type': 'line'});

        final options = chart.options;
        expect(
          jsGet(options['font'], 'size'),
          jsGet(defaults['font'], 'size'),
        );
        expect(options['onHover'], same(callback));
        expect(jsGet(options['hover'], 'mode'), 'test');

        defaults['onHover'] = null;
        _line.remove('hover');
      });

      testWidgets('should override default options', (tester) async {
        void callback() {}
        final defaults = Chart.defaults;
        final lineDefaults =
            jsGet(defaults['datasets'], 'line')! as Map<String, Object?>;
        final defaultSpanGaps = jsGet(lineDefaults, 'spanGaps');

        defaults['onHover'] = callback;
        _line['hover'] = <String, Object?>{'mode': 'x-axis'};
        lineDefaults['spanGaps'] = true;

        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'options': <String, Object?>{
            'spanGaps': false,
            'hover': <String, Object?>{'mode': 'dataset'},
            'plugins': <String, Object?>{
              'title': <String, Object?>{'position': 'bottom'},
            },
          },
        });

        final options = chart.options;
        expect(options['spanGaps'], false);
        expect(jsGet(options['hover'], 'mode'), 'dataset');
        expect(
          jsGet(jsGet(options['plugins'], 'title'), 'position'),
          'bottom',
        );

        defaults['onHover'] = null;
        _line.remove('hover');
        lineDefaults['spanGaps'] = defaultSpanGaps;
      });

      testWidgets('should initialize config with default dataset options', (
        tester,
      ) async {
        final pieDefaults = jsGet(defaults['datasets'], 'pie');

        final chart = acquireChart(<String, Object?>{'type': 'pie'});

        final options = chart.options;
        expect(options['circumference'], jsGet(pieDefaults, 'circumference'));
      });

      testWidgets('should override axis positions that are incorrect', (
        tester,
      ) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'position': 'left'},
              'y': <String, Object?>{'position': 'bottom'},
            },
          },
        });

        final scaleOptions = chart.options['scales'];
        expect(jsGet(jsGet(scaleOptions, 'x'), 'position'), 'bottom');
        expect(jsGet(jsGet(scaleOptions, 'y'), 'position'), 'left');
      });

      // update() builds the scales before the controllers. Thus the case
      // needs the linear and category scales, but no controller: the
      // expected error is the missing controller 'area'.
      testWidgets('should throw an error if the chart type is incorrect', (
        tester,
      ) async {
        void createChart() {
          acquireChart(<String, Object?>{
            'type': 'area',
            'data': <String, Object?>{
              'datasets': <Object?>[
                <String, Object?>{
                  'label': 'first',
                  'data': <Object?>[10, 20],
                },
              ],
              'labels': <Object?>['0', '1'],
            },
            'options': <String, Object?>{
              'scales': <String, Object?>{
                'x': <String, Object?>{'type': 'linear', 'position': 'left'},
                'y': <String, Object?>{
                  'type': 'category',
                  'position': 'bottom',
                },
              },
            },
          });
        }

        expect(
          createChart,
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              '"area" is not a registered controller.',
            ),
          ),
        );
      });

      testWidgets('should initialize the data object', (tester) async {
        final chart = acquireChart(<String, Object?>{'type': 'bar'});
        expect(
          chart.data,
          objectContaining({'labels': <Object?>[], 'datasets': <Object?>[]}),
        );
        chart.data = <String, Object?>{};
        expect(
          chart.data,
          objectContaining({'labels': <Object?>[], 'datasets': <Object?>[]}),
        );
        chart.data = null;
        expect(
          chart.data,
          objectContaining({'labels': <Object?>[], 'datasets': <Object?>[]}),
        );
        chart.data = undefined;
        expect(
          chart.data,
          objectContaining({'labels': <Object?>[], 'datasets': <Object?>[]}),
        );
      });

      group('should disable hover', () {
        testWidgets('when options.hover=false', (tester) async {
          final chart = acquireChart(<String, Object?>{
            'type': 'line',
            'options': <String, Object?>{'hover': false},
          });
          expect(chart.options['hover'], isFalse);
        });

        testWidgets(
          'when options.interaction=false and options.hover is not defined',
          (tester) async {
            final chart = acquireChart(<String, Object?>{
              'type': 'line',
              'options': <String, Object?>{'interaction': false},
            });
            expect(chart.options['hover'], isFalse);
          },
        );

        testWidgets(
          'when options.interaction=false and options.hover is defined',
          (tester) async {
            final chart = acquireChart(<String, Object?>{
              'type': 'line',
              'options': <String, Object?>{
                'interaction': false,
                'hover': <String, Object?>{'mode': 'nearest'},
              },
            });
            expect(chart.options['hover'], isFalse);
          },
        );
      });

      testWidgets('should activate element on hover', (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'labels': <Object?>['A', 'B', 'C', 'D'],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 20, 30, 100],
              },
            ],
          },
        });

        final point = chart.getDatasetMeta(0).data[1];

        await triggerMouseEvent(chart, 'mousemove', point);
        expect(
          _activeElements(chart),
          jasmineEquals(<Object?>[
            <String, Object?>{'datasetIndex': 0, 'index': 1, 'element': point},
          ]),
        );
      });

      testWidgets('should handle changing the events at runtime', (
        tester,
      ) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'labels': <Object?>['A', 'B', 'C', 'D'],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 20, 30, 100],
              },
            ],
          },
          'options': <String, Object?>{
            'events': <Object?>['click'],
          },
        });

        final point1 = chart.getDatasetMeta(0).data[1];
        final point2 = chart.getDatasetMeta(0).data[2];

        await triggerMouseEvent(chart, 'click', point1);
        expect(
          _activeElements(chart),
          jasmineEquals(<Object?>[
            <String, Object?>{
              'datasetIndex': 0,
              'index': 1,
              'element': point1,
            },
          ]),
        );

        chart.options['events'] = <Object?>['mousemove'];
        chart.update();

        await triggerMouseEvent(chart, 'mousemove', point2);
        expect(
          _activeElements(chart),
          jasmineEquals(<Object?>[
            <String, Object?>{
              'datasetIndex': 0,
              'index': 2,
              'element': point2,
            },
          ]),
        );
      });

      testWidgets(
        'should activate element on hover when minPadding pixels outside '
        'chart area',
        (tester) async {
          final chart = acquireChart(<String, Object?>{
            'type': 'line',
            'data': <String, Object?>{
              'labels': <Object?>['A', 'B', 'C', 'D'],
              'datasets': <Object?>[
                <String, Object?>{
                  'data': <Object?>[10, 20, 30, 100],
                  'hoverRadius': 0,
                },
              ],
            },
            'options': <String, Object?>{
              'scales': <String, Object?>{
                'x': <String, Object?>{'display': false},
                'y': <String, Object?>{'display': false},
              },
            },
          });

          final point = chart.getDatasetMeta(0).data[0];

          await triggerMouseEvent(chart, 'mousemove', <String, Object?>{
            'x': 1,
            'y': _y(point),
          });
          expect(
            _activeElements(chart),
            jasmineEquals(<Object?>[
              <String, Object?>{
                'datasetIndex': 0,
                'index': 0,
                'element': point,
              },
            ]),
          );
        },
      );

      testWidgets('should not activate elements when hover is disabled', (
        tester,
      ) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'labels': <Object?>['A', 'B', 'C', 'D'],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 20, 30, 100],
              },
            ],
          },
          'options': <String, Object?>{'hover': false},
        });

        final point = chart.getDatasetMeta(0).data[1];

        await triggerMouseEvent(chart, 'mousemove', point);
        expect(_activeElements(chart), jasmineEquals(<Object?>[]));
      });

      testWidgets(
        'should not change the active elements when outside chartArea, except '
        'for mouseout',
        (tester) async {
          final chart = acquireChart(<String, Object?>{
            'type': 'line',
            'data': <String, Object?>{
              'labels': <Object?>['A', 'B', 'C', 'D'],
              'datasets': <Object?>[
                <String, Object?>{
                  'data': <Object?>[10, 20, 30, 100],
                  'hoverRadius': 0,
                },
              ],
            },
            'options': <String, Object?>{
              'scales': <String, Object?>{
                'x': <String, Object?>{'display': false},
                'y': <String, Object?>{'display': false},
              },
              'layout': <String, Object?>{'padding': 5},
            },
          });

          final point = chart.getDatasetMeta(0).data[0];

          await triggerMouseEvent(chart, 'mousemove', <String, Object?>{
            'x': point.x,
            'y': _y(point),
          });
          expect(
            _activeElements(chart),
            jasmineEquals(<Object?>[
              <String, Object?>{
                'datasetIndex': 0,
                'index': 0,
                'element': point,
              },
            ]),
          );

          await triggerMouseEvent(chart, 'mousemove', <String, Object?>{
            'x': 1,
            'y': 1,
          });
          expect(
            _activeElements(chart),
            jasmineEquals(<Object?>[
              <String, Object?>{
                'datasetIndex': 0,
                'index': 0,
                'element': point,
              },
            ]),
          );

          await triggerMouseEvent(chart, 'mouseout', <String, Object?>{
            'x': 1,
            'y': 1,
          });
          expect(
            chart.tooltip!.getActiveElements(),
            jasmineEquals(<Object?>[]),
          );
        },
      );
    });

    group('when merging scale options', () {
      // :400-419 the beforeEach and afterEach are a setUp and a tearDown:
      // they read no chart. The restore of flutter_test_config.dart also
      // puts back `defaults` after each test.
      setUp(() {
        helpers.merge(defaults['scale'], <String, Object?>{
          '_jasmineCheckA': 'a0',
          '_jasmineCheckB': 'b0',
          '_jasmineCheckC': 'c0',
        });

        helpers.merge(
          jsGet(defaults['scales'], 'logarithmic'),
          <String, Object?>{'_jasmineCheckB': 'b1', '_jasmineCheckC': 'c1'},
        );
      });

      tearDown(() {
        (defaults['scale']! as Map<String, Object?>)
          ..remove('_jasmineCheckA')
          ..remove('_jasmineCheckB')
          ..remove('_jasmineCheckC');
        (jsGet(defaults['scales'], 'logarithmic')! as Map<String, Object?>)
          ..remove('_jasmineCheckB')
          ..remove('_jasmineCheckC');
      });

      testWidgets(
        'should default to "category" for x scales and "linear" for y scales',
        (tester) async {
          final chart = acquireChart(<String, Object?>{
            'type': 'line',
            'options': <String, Object?>{
              'scales': <String, Object?>{
                'xFoo0': <String, Object?>{},
                'xFoo1': <String, Object?>{},
                'yBar0': <String, Object?>{},
                'yBar1': <String, Object?>{},
              },
            },
          });

          expect(chart.scales['xFoo0']!.type, 'category');
          expect(chart.scales['xFoo1']!.type, 'category');
          expect(chart.scales['yBar0']!.type, 'linear');
          expect(chart.scales['yBar1']!.type, 'linear');
        },
      );

      testWidgets('should correctly apply defaults on central scale', (
        tester,
      ) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'foo': <String, Object?>{
                'axis': 'x',
                'type': 'logarithmic',
                '_jasmineCheckC': 'c2',
                '_jasmineCheckD': 'd2',
              },
            },
          },
        });

        // let's check a few values from the user options and defaults

        expect(chart.scales['foo']!.type, 'logarithmic');
        expect(
          JasmineOptions(chart.scales['foo']!.options),
          jasmineEquals(jsGet(chart.options['scales'], 'foo')),
        );
        expect(
          JasmineOptions(chart.scales['foo']!.options),
          objectContaining({
            '_jasmineCheckA': 'a0',
            '_jasmineCheckB': 'b1',
            '_jasmineCheckC': 'c2',
            '_jasmineCheckD': 'd2',
          }),
        );
      });

      testWidgets('should correctly apply defaults on xy scales', (
        tester,
      ) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{
                'type': 'logarithmic',
                '_jasmineCheckC': 'c2',
                '_jasmineCheckD': 'd2',
              },
              'y': <String, Object?>{
                'type': 'time',
                '_jasmineCheckC': 'c2',
                '_jasmineCheckE': 'e2',
              },
            },
          },
        });

        expect(chart.scales['x']!.type, 'logarithmic');
        expect(
          JasmineOptions(chart.scales['x']!.options),
          jasmineEquals(jsGet(chart.options['scales'], 'x')),
        );
        expect(
          JasmineOptions(chart.scales['x']!.options),
          objectContaining({
            '_jasmineCheckA': 'a0',
            '_jasmineCheckB': 'b1',
            '_jasmineCheckC': 'c2',
            '_jasmineCheckD': 'd2',
          }),
        );

        expect(chart.scales['y']!.type, 'time');
        expect(
          JasmineOptions(chart.scales['y']!.options),
          jasmineEquals(jsGet(chart.options['scales'], 'y')),
        );
        expect(
          JasmineOptions(chart.scales['y']!.options),
          objectContaining({
            '_jasmineCheckA': 'a0',
            '_jasmineCheckB': 'b0',
            '_jasmineCheckC': 'c2',
            '_jasmineCheckE': 'e2',
          }),
        );
      });

      testWidgets('should not alter defaults when merging config', (
        tester,
      ) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'options': <String, Object?>{
            '_jasmineCheck': 42,
            'scales': <String, Object?>{
              'x': <String, Object?>{'type': 'linear', '_jasmineCheck': 42},
              'y': <String, Object?>{'type': 'category', '_jasmineCheck': 42},
            },
          },
        });

        expect(chart.options['_jasmineCheck'], isNot(same(undefined)));
        expect(
          chart.scales['x']!.options['_jasmineCheck'],
          isNot(same(undefined)),
        );
        expect(
          chart.scales['y']!.options['_jasmineCheck'],
          isNot(same(undefined)),
        );

        expect(jsGet(_line, '_jasmineCheck'), same(undefined));
        expect(jsGet(defaults, '_jasmineCheck'), same(undefined));
        expect(
          jsGet(jsGet(defaults['scales'], 'linear'), '_jasmineCheck'),
          same(undefined),
        );
        expect(
          jsGet(jsGet(defaults['scales'], 'category'), '_jasmineCheck'),
          same(undefined),
        );
      });

      // :536 and :566 give `data: []`. An array data gives a new Map (row
      // adapt-config-objects), and no Chart.js code reads the items of the
      // array. Thus the two cases need no diverges skip.
      testWidgets('should ignore proxy passed as scale options', (
        tester,
      ) async {
        var failure = false;
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <Object?>[],
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{
                'grid': <String, Object?>{
                  'color': (Object? ctx) {
                    if (!jsTruthy(jsGet(ctx, 'tick'))) {
                      failure = true;
                    }
                  },
                },
              },
            },
          },
        });
        chart
          ..options['scales'] = <String, Object?>{
            'x': jsGet(chart.options['scales'], 'x'),
            'y': <String, Object?>{'type': 'linear', 'position': 'right'},
          }
          ..update();
        expect(failure, false);
      });

      testWidgets('should ignore array passed as scale options', (
        tester,
      ) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <Object?>[],
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'xAxes': <Object?>[
                <String, Object?>{'id': 'xAxes', 'type': 'category'},
              ],
            },
          },
        });
        expect(chart.scales['xAxes'], isNull);
      });
    });

    group('Updating options', () {
      // :584 the config has `data: []`. Upstream writes `datasets` and
      // `labels` into the array. The port gives a new Map (row
      // adapt-config-objects). The case reads only the options.
      testWidgets('update should result to same set of options as construct', (
        tester,
      ) async {
        final chart = acquireChart({
          'type': 'line',
          'data': <Object?>[],
          'options': <String, Object?>{
            'animation': false,
            'locale': 'en-US',
            'responsive': false,
          },
        });
        final options = chart.options;
        chart
          ..options = <String, Object?>{
            'animation': false,
            'locale': 'en-US',
            'responsive': false,
          }
          ..update();
        expect(chart.options, toEqualOptions(options));
      });
    });

    group('config.options.responsive: true (maintainAspectRatio: false)', () {
      testWidgets('should fill parent width and height', (tester) async {
        final chart = acquireChart(
          <String, Object?>{
            'options': <String, Object?>{
              'responsive': true,
              'maintainAspectRatio': false,
            },
          },
          <String, Object?>{
            'canvas': <String, Object?>{'style': 'width: 150px; height: 245px'},
            'wrapper': <String, Object?>{
              'style': 'width: 300px; height: 350px',
            },
          },
        );

        expect(
          chart,
          toBeChartOfSize({'dw': 300, 'dh': 350, 'rw': 300, 'rh': 350}),
        );
      });

      testWidgets('should call onResize with correct arguments and context', (
        tester,
      ) async {
        var count = 0;
        var correctThis = false;
        final size = <String, Object?>{'width': 0, 'height': 0};
        acquireChart(
          <String, Object?>{
            'options': <String, Object?>{
              'responsive': true,
              'maintainAspectRatio': false,
              // `onResize(chart, newSize)` reads `this`. `newSize` is the
              // record of `getMaximumSize`.
              'onResize': JsFunction((
                Object? self,
                Object? chart,
                Object? newSize,
              ) {
                count++;
                correctThis = identical(self, chart);
                final (:width, :height) =
                    newSize! as ({double width, double height});
                size['width'] = width;
                size['height'] = height;
              }),
            },
          },
          <String, Object?>{
            'canvas': <String, Object?>{'style': 'width: 150px; height: 245px'},
            'wrapper': <String, Object?>{
              'style': 'width: 300px; height: 350px',
            },
          },
        );

        expect(count, 1);
        expect(correctThis, isTrue);
        expect(size, {'width': 300, 'height': 350});
      });

      testWidgets('should resize the canvas when parent width changes', (
        tester,
      ) async {
        await waitForDone((done) {
          final chart = acquireChart(
            <String, Object?>{
              'options': <String, Object?>{
                'responsive': true,
                'maintainAspectRatio': false,
              },
            },
            <String, Object?>{
              'canvas': <String, Object?>{'style': ''},
              'wrapper': <String, Object?>{
                'style': 'width: 300px; height: 350px; position: relative',
              },
            },
          );

          expect(
            chart,
            toBeChartOfSize({'dw': 300, 'dh': 350, 'rw': 300, 'rh': 350}),
          );

          final wrapper = chart.canvas!.parentElement!;
          waitForResize(chart, () {
            expect(
              chart,
              toBeChartOfSize({'dw': 455, 'dh': 350, 'rw': 455, 'rh': 350}),
            );

            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 150, 'dh': 350, 'rw': 150, 'rh': 350}),
              );

              done();
            });
            wrapper.style.width = '150px';
          });
          wrapper.style.width = '455px';
        });
      });

      testWidgets(
        'should restore the original size when parent became invisible',
        (tester) async {
          await waitForDone((done) {
            final chart = acquireChart(
              <String, Object?>{
                'options': <String, Object?>{
                  'responsive': true,
                  'maintainAspectRatio': false,
                },
              },
              <String, Object?>{
                'canvas': <String, Object?>{'style': ''},
                'wrapper': <String, Object?>{
                  'style': 'width: 300px; height: 350px; position: relative',
                },
              },
            );

            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 300, 'dh': 350, 'rw': 300, 'rh': 350}),
              );

              final original = chart.resize;
              chart.resize = ([width, height]) {
                fail('resize should not have been called');
              };

              final wrapper = chart.canvas!.parentElement!;
              wrapper.style.display = 'none';

              setTimeout(() {
                expect(wrapper.clientWidth, 0);
                expect(wrapper.clientHeight, 0);

                expect(
                  chart,
                  toBeChartOfSize({
                    'dw': 300,
                    'dh': 350,
                    'rw': 300,
                    'rh': 350,
                  }),
                );

                chart.resize = original;

                waitForResize(chart, () {
                  expect(
                    chart,
                    toBeChartOfSize({
                      'dw': 300,
                      'dh': 350,
                      'rw': 300,
                      'rh': 350,
                    }),
                  );

                  done();
                });
                wrapper.style.display = 'block';
              }, 200);
            });
          });
        },
      );

      testWidgets(
        'should resize the canvas when parent is RTL and width changes',
        (tester) async {
          await waitForDone((done) {
            final chart = acquireChart(
              <String, Object?>{
                'options': <String, Object?>{
                  'responsive': true,
                  'maintainAspectRatio': false,
                },
              },
              <String, Object?>{
                'canvas': <String, Object?>{'style': ''},
                'wrapper': <String, Object?>{
                  'style':
                      'width: 300px; height: 350px; position: relative; '
                      'direction: rtl',
                },
              },
            );

            expect(
              chart,
              toBeChartOfSize({'dw': 300, 'dh': 350, 'rw': 300, 'rh': 350}),
            );

            final wrapper = chart.canvas!.parentElement!;
            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 455, 'dh': 350, 'rw': 455, 'rh': 350}),
              );

              waitForResize(chart, () {
                expect(
                  chart,
                  toBeChartOfSize({
                    'dw': 150,
                    'dh': 350,
                    'rw': 150,
                    'rh': 350,
                  }),
                );

                done();
              });
              wrapper.style.width = '150px';
            });
            wrapper.style.width = '455px';
          });
        },
      );

      testWidgets('should resize the canvas when parent height changes', (
        tester,
      ) async {
        await waitForDone((done) {
          final chart = acquireChart(
            <String, Object?>{
              'options': <String, Object?>{
                'responsive': true,
                'maintainAspectRatio': false,
              },
            },
            <String, Object?>{
              'canvas': <String, Object?>{'style': ''},
              'wrapper': <String, Object?>{
                'style': 'width: 300px; height: 350px; position: relative',
              },
            },
          );

          expect(
            chart,
            toBeChartOfSize({'dw': 300, 'dh': 350, 'rw': 300, 'rh': 350}),
          );

          final wrapper = chart.canvas!.parentElement!;
          waitForResize(chart, () {
            expect(
              chart,
              toBeChartOfSize({'dw': 300, 'dh': 455, 'rw': 300, 'rh': 455}),
            );

            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 300, 'dh': 150, 'rw': 300, 'rh': 150}),
              );

              done();
            });
            wrapper.style.height = '150px';
          });
          wrapper.style.height = '455px';
        });
      });

      testWidgets(
        'should not include parent padding when resizing the canvas',
        (tester) async {
          await waitForDone((done) {
            final chart = acquireChart(
              <String, Object?>{
                'type': 'line',
                'options': <String, Object?>{
                  'responsive': true,
                  'maintainAspectRatio': false,
                },
              },
              <String, Object?>{
                'canvas': <String, Object?>{'style': ''},
                'wrapper': <String, Object?>{
                  'style':
                      'padding: 50px; width: 320px; height: 350px; '
                      'position: relative',
                },
              },
            );

            expect(
              chart,
              toBeChartOfSize({'dw': 320, 'dh': 350, 'rw': 320, 'rh': 350}),
            );

            final wrapper = chart.canvas!.parentElement!;
            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 455, 'dh': 355, 'rw': 455, 'rh': 355}),
              );

              done();
            });
            wrapper.style
              ..height = '355px'
              ..width = '455px';
          });
        },
      );

      testWidgets(
        'should resize the canvas when the canvas display style changes from '
        '"none" to "block"',
        (tester) async {
          await waitForDone((done) {
            final chart = acquireChart(
              <String, Object?>{
                'options': <String, Object?>{
                  'responsive': true,
                  'maintainAspectRatio': false,
                },
              },
              <String, Object?>{
                'canvas': <String, Object?>{'style': 'display: none;'},
                'wrapper': <String, Object?>{
                  'style': 'width: 320px; height: 350px',
                },
              },
            );

            final canvas = chart.canvas!;
            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 320, 'dh': 350, 'rw': 320, 'rh': 350}),
              );

              done();
            });
            canvas.style.display = 'block';
          });
        },
      );

      testWidgets(
        'should resize the canvas when the wrapper display style changes from '
        '"none" to "block"',
        (tester) async {
          await waitForDone((done) {
            final chart = acquireChart(
              <String, Object?>{
                'options': <String, Object?>{
                  'responsive': true,
                  'maintainAspectRatio': false,
                },
              },
              <String, Object?>{
                'canvas': <String, Object?>{'style': ''},
                'wrapper': <String, Object?>{
                  'style': 'display: none; width: 460px; height: 380px',
                },
              },
            );

            final wrapper = chart.canvas!.parentElement!;
            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 460, 'dh': 380, 'rw': 460, 'rh': 380}),
              );

              done();
            });
            wrapper.style.display = 'block';
          });
        },
      );

      testWidgets(
        'should resize the canvas when the wrapper has display style changes '
        'from "none" to "block"',
        (tester) async {
          await waitForDone((done) {
            // https://github.com/chartjs/Chart.js/issues/4659
            final chart = acquireChart(
              <String, Object?>{
                'options': <String, Object?>{
                  'responsive': true,
                  'maintainAspectRatio': false,
                },
              },
              <String, Object?>{
                'canvas': <String, Object?>{'style': ''},
                'wrapper': <String, Object?>{
                  'style':
                      'display: none; max-width: 600px; max-height: 400px;',
                },
              },
            );

            final wrapper = chart.canvas!.parentElement!;
            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 600, 'dh': 300, 'rw': 600, 'rh': 300}),
              );

              done();
            });
            wrapper.style.display = 'block';
          });
        },
      );

      // https://github.com/chartjs/Chart.js/issues/5485
      testWidgets(
        'should resize the canvas when the devicePixelRatio changes',
        (tester) async {
          await waitForDone((done) {
            final chart = acquireChart(
              <String, Object?>{
                'options': <String, Object?>{
                  'responsive': true,
                  'maintainAspectRatio': false,
                  'devicePixelRatio': 1,
                },
              },
              <String, Object?>{
                'canvas': <String, Object?>{'style': ''},
                'wrapper': <String, Object?>{
                  'style': 'width: 400px; height: 200px; position: relative',
                },
              },
            );

            expect(
              chart,
              toBeChartOfSize({'dw': 400, 'dh': 200, 'rw': 400, 'rh': 200}),
            );

            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 400, 'dh': 200, 'rw': 800, 'rh': 400}),
              );

              done();
            });
            chart.options['devicePixelRatio'] = 2;
            chart.resize();
          });
        },
      );

      // https://github.com/chartjs/Chart.js/issues/3790
      testWidgets(
        'should resize the canvas if attached to the DOM after construction',
        (tester) async {
          await waitForDone((done) {
            final canvas = document.createElement<HTMLCanvasElement>('canvas');
            final wrapper = document.createElement<HarnessElement>('div');
            final body = document.body;
            final chart = Chart(canvas, <String, Object?>{
              'type': 'line',
              'options': <String, Object?>{
                'responsive': true,
                'maintainAspectRatio': false,
              },
            });

            expect(
              chart,
              toBeChartOfSize({'dw': 0, 'dh': 0, 'rw': 0, 'rh': 0}),
            );
            expect(chart.chartArea, isNull);

            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 455, 'dh': 355, 'rw': 455, 'rh': 355}),
              );

              expect(chart.chartArea, isNotNull);

              body.removeChild(wrapper);
              chart.destroy();
              done();
            });

            wrapper.style.cssText = 'width: 455px; height: 355px';
            wrapper.appendChild(canvas);
            body.appendChild(wrapper);
          });
        },
      );

      testWidgets(
        'should resize the canvas when attached to a different parent',
        (tester) async {
          await waitForDone((done) {
            final canvas = document.createElement<HTMLCanvasElement>('canvas');
            final wrapper = document.createElement<HarnessElement>('div');
            final body = document.body;
            final chart = Chart(canvas, <String, Object?>{
              'type': 'line',
              'options': <String, Object?>{
                'responsive': true,
                'maintainAspectRatio': false,
              },
            });

            expect(
              chart,
              toBeChartOfSize({'dw': 0, 'dh': 0, 'rw': 0, 'rh': 0}),
            );

            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 455, 'dh': 355, 'rw': 455, 'rh': 355}),
              );

              final target = document.createElement<HarnessElement>('div');

              waitForResize(chart, () {
                expect(
                  chart,
                  toBeChartOfSize({'dw': 640, 'dh': 480, 'rw': 640, 'rh': 480}),
                );

                body
                  ..removeChild(wrapper)
                  ..removeChild(target);
                chart.destroy();
                done();
              });

              target.style.cssText = 'width: 640px; height: 480px';
              target.appendChild(canvas);
              body.appendChild(target);
            });

            wrapper.style.cssText = 'width: 455px; height: 355px';
            wrapper.appendChild(canvas);
            body.appendChild(wrapper);
          });
        },
      );

      // https://github.com/chartjs/Chart.js/issues/3521
      testWidgets(
        'should resize the canvas after the wrapper has been re-attached to '
        'the DOM',
        (tester) async {
          await waitForDone((done) {
            final chart = acquireChart(
              <String, Object?>{
                'options': <String, Object?>{
                  'responsive': true,
                  'maintainAspectRatio': false,
                },
              },
              <String, Object?>{
                'canvas': <String, Object?>{'style': ''},
                'wrapper': <String, Object?>{
                  'style': 'width: 320px; height: 350px',
                },
              },
            );

            expect(
              chart,
              toBeChartOfSize({'dw': 320, 'dh': 350, 'rw': 320, 'rh': 350}),
            );

            final wrapper = chart.canvas!.parentElement!;
            final parent = wrapper.parentNode!;

            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 320, 'dh': 355, 'rw': 320, 'rh': 355}),
              );

              waitForResize(chart, () {
                expect(
                  chart,
                  toBeChartOfSize({'dw': 455, 'dh': 355, 'rw': 455, 'rh': 355}),
                );

                done();
              });

              parent.removeChild(wrapper);
              wrapper.style.width = '455px';
              parent.appendChild(wrapper);
            });

            parent.removeChild(wrapper);
            setTimeout(
              () {
                parent.appendChild(wrapper);
                wrapper.style.height = '355px';
              },
              // The upstream text passes the delay 0.
              // ignore: avoid_redundant_argument_values
              0,
            );
          });
        },
      );

      // https://github.com/chartjs/Chart.js/issues/9875
      testWidgets('should detect detach/attach in series', (tester) async {
        await waitForDone((done) {
          final chart = acquireChart(
            <String, Object?>{
              'options': <String, Object?>{
                'responsive': true,
                'maintainAspectRatio': false,
              },
            },
            <String, Object?>{
              'canvas': <String, Object?>{'style': ''},
              'wrapper': <String, Object?>{
                'style': 'width: 320px; height: 350px',
              },
            },
          );

          final wrapper = chart.canvas!.parentElement!;
          final parent = wrapper.parentNode!;

          waitForResize(chart, () {
            expect(
              chart,
              toBeChartOfSize({'dw': 320, 'dh': 350, 'rw': 320, 'rh': 350}),
            );

            done();
          });

          parent
            ..removeChild(wrapper)
            ..appendChild(wrapper);
        });
      });

      testWidgets('should detect detach/attach/detach in series', (
        tester,
      ) async {
        await waitForDone((done) {
          final chart = acquireChart(
            <String, Object?>{
              'options': <String, Object?>{
                'responsive': true,
                'maintainAspectRatio': false,
              },
            },
            <String, Object?>{
              'canvas': <String, Object?>{'style': ''},
              'wrapper': <String, Object?>{
                'style': 'width: 320px; height: 350px',
              },
            },
          );

          final wrapper = chart.canvas!.parentElement!;
          final parent = wrapper.parentNode!;

          waitForResize(chart, () {
            fail('Failed');
          });

          parent
            ..removeChild(wrapper)
            ..appendChild(wrapper)
            ..removeChild(wrapper);

          setTimeout(() {
            expect(chart.attached, isFalse);
            done();
          }, 100);
        });
      });

      testWidgets('should detect attach/detach in series', (tester) async {
        await waitForDone((done) {
          final chart = acquireChart(
            <String, Object?>{
              'options': <String, Object?>{
                'responsive': true,
                'maintainAspectRatio': false,
              },
            },
            <String, Object?>{
              'canvas': <String, Object?>{'style': ''},
              'wrapper': <String, Object?>{
                'style': 'width: 320px; height: 350px',
              },
            },
          );

          final wrapper = chart.canvas!.parentElement!;
          final parent = wrapper.parentNode!;

          // The upstream statements stay apart.
          // ignore: cascade_invocations
          parent.removeChild(wrapper);

          setTimeout(() {
            expect(chart.attached, isFalse);

            waitForResize(chart, () {
              fail('Failed');
            });

            parent
              ..appendChild(wrapper)
              ..removeChild(wrapper);

            setTimeout(() {
              expect(chart.attached, isFalse);

              done();
            }, 100);
          }, 100);
        });
      });

      // https://github.com/chartjs/Chart.js/issues/4737
      testWidgets('should resize the canvas when re-creating the chart', (
        tester,
      ) async {
        await waitForDone((done) {
          var chart = acquireChart(
            <String, Object?>{
              'options': <String, Object?>{'responsive': true},
            },
            <String, Object?>{
              'wrapper': <String, Object?>{'style': 'width: 320px'},
            },
          );

          final wrapper = chart.canvas!.parentElement!;

          waitForResize(chart, () {
            final canvas = chart.canvas!;
            expect(
              chart,
              toBeChartOfSize({'dw': 320, 'dh': 320, 'rw': 320, 'rh': 320}),
            );

            chart.destroy();
            chart = Chart(canvas, <String, Object?>{
              'type': 'line',
              'options': <String, Object?>{'responsive': true},
            });

            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 455, 'dh': 455, 'rw': 455, 'rh': 455}),
              );

              chart.destroy();
              document.body.removeChild(wrapper);
              done();
            });
            canvas.parentElement!.style.width = '455px';
            canvas.parentElement!.style.height = '455px';
          });
        });
      });

      testWidgets(
        'should resize the canvas if attached to the DOM after construction '
        'with multiple parents',
        (tester) async {
          await waitForDone((done) {
            final canvas = document.createElement<HTMLCanvasElement>('canvas');
            final wrapper = document.createElement<HarnessElement>('div');
            final wrapper2 = document.createElement<HarnessElement>('div');
            final wrapper3 = document.createElement<HarnessElement>('div');
            final body = document.body;

            final chart = Chart(canvas, <String, Object?>{
              'type': 'line',
              'options': <String, Object?>{
                'responsive': true,
                'maintainAspectRatio': false,
              },
            });

            expect(
              chart,
              toBeChartOfSize({'dw': 0, 'dh': 0, 'rw': 0, 'rh': 0}),
            );
            expect(chart.chartArea, isNull);

            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 455, 'dh': 355, 'rw': 455, 'rh': 355}),
              );

              expect(chart.chartArea, isNotNull);

              body.removeChild(wrapper3);
              chart.destroy();
              done();
            });

            wrapper3.appendChild(wrapper2);
            wrapper2.appendChild(wrapper);
            wrapper.style.cssText = 'width: 455px; height: 355px';
            wrapper.appendChild(canvas);
            body.appendChild(wrapper3);
          });
        },
      );
    });

    group('config.options.responsive: true (maintainAspectRatio: true)', () {
      testWidgets(
        'should resize the canvas with correct aspect ratio when parent width '
        'changes',
        (tester) async {
          await waitForDone((done) {
            final chart = acquireChart(
              <String, Object?>{
                'type': 'line', // AR == 2
                'options': <String, Object?>{
                  'responsive': true,
                  'maintainAspectRatio': true,
                },
              },
              <String, Object?>{
                'canvas': <String, Object?>{'style': ''},
                'wrapper': <String, Object?>{
                  'style': 'width: 300px; height: 350px; position: relative',
                },
              },
            );

            expect(
              chart,
              toBeChartOfSize({'dw': 300, 'dh': 150, 'rw': 300, 'rh': 150}),
            );

            final wrapper = chart.canvas!.parentElement!;
            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 450, 'dh': 225, 'rw': 450, 'rh': 225}),
              );

              waitForResize(chart, () {
                expect(
                  chart,
                  toBeChartOfSize({'dw': 150, 'dh': 75, 'rw': 150, 'rh': 75}),
                );

                done();
              });
              wrapper.style.width = '150px';
            });
            wrapper.style.width = '450px';
          });
        },
      );

      testWidgets('should maintain aspect ratio when parent height changes', (
        tester,
      ) async {
        await waitForDone((done) {
          final chart = acquireChart(
            <String, Object?>{
              'options': <String, Object?>{
                'responsive': true,
                'maintainAspectRatio': true,
              },
            },
            <String, Object?>{
              'canvas': <String, Object?>{'style': ''},
              'wrapper': <String, Object?>{
                'style': 'width: 320px; height: 350px; position: relative',
              },
            },
          );

          expect(
            chart,
            toBeChartOfSize({'dw': 320, 'dh': 160, 'rw': 320, 'rh': 160}),
          );

          final wrapper = chart.canvas!.parentElement!;
          waitForResize(chart, () {
            expect(
              chart,
              toBeChartOfSize({'dw': 320, 'dh': 160, 'rw': 320, 'rh': 160}),
            );

            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 300, 'dh': 150, 'rw': 300, 'rh': 150}),
              );

              done();
            });
            wrapper.style.height = '150px';
          });
          wrapper.style.height = '455px';
        });
      });
    });

    group('Retina scale (a.k.a. device pixel ratio)', () {
      late double devicePixelRatio;

      setUp(() {
        devicePixelRatio = window.devicePixelRatio;
        window.devicePixelRatio = 3;
      });

      tearDown(() {
        window.devicePixelRatio = devicePixelRatio;
      });

      // see https://github.com/chartjs/Chart.js/issues/3575
      testWidgets(
        'should scale the render size but not the "implicit" display size',
        (tester) async {
          final chart = acquireChart(
            <String, Object?>{
              'options': <String, Object?>{'responsive': false},
            },
            <String, Object?>{
              'canvas': <String, Object?>{'width': 320, 'height': 240},
            },
          );

          expect(
            chart,
            toBeChartOfSize({'dw': 320, 'dh': 240, 'rw': 960, 'rh': 720}),
          );
        },
      );

      testWidgets(
        'should scale the render size but not the "explicit" display size',
        (tester) async {
          final chart = acquireChart(
            <String, Object?>{
              'options': <String, Object?>{'responsive': false},
            },
            <String, Object?>{
              'canvas': <String, Object?>{
                'style': 'width: 320px; height: 240px',
              },
            },
          );

          expect(
            chart,
            toBeChartOfSize({'dw': 320, 'dh': 240, 'rw': 960, 'rh': 720}),
          );
        },
      );
    });

    group('config.options.devicePixelRatio', () {
      late double devicePixelRatio;

      setUp(() {
        devicePixelRatio = window.devicePixelRatio;
        window.devicePixelRatio = 1;
      });

      tearDown(() {
        window.devicePixelRatio = devicePixelRatio;
      });

      // see https://github.com/chartjs/Chart.js/issues/3575
      testWidgets(
        'should scale the render size but not the "implicit" display size',
        (tester) async {
          final chart = acquireChart(
            <String, Object?>{
              'options': <String, Object?>{
                'responsive': false,
                'devicePixelRatio': 3,
              },
            },
            <String, Object?>{
              'canvas': <String, Object?>{'width': 320, 'height': 240},
            },
          );

          expect(
            chart,
            toBeChartOfSize({'dw': 320, 'dh': 240, 'rw': 960, 'rh': 720}),
          );
        },
      );

      testWidgets(
        'should scale the render size but not the "explicit" display size',
        (tester) async {
          final chart = acquireChart(
            <String, Object?>{
              'options': <String, Object?>{
                'responsive': false,
                'devicePixelRatio': 3,
              },
            },
            <String, Object?>{
              'canvas': <String, Object?>{
                'style': 'width: 320px; height: 240px',
              },
            },
          );

          expect(
            chart,
            toBeChartOfSize({'dw': 320, 'dh': 240, 'rw': 960, 'rh': 720}),
          );
        },
      );
    });

    group('config.options.aspectRatio', () {
      testWidgets(
        'should resize the canvas when the aspectRatio option changes',
        (tester) async {
          await waitForDone((done) {
            final chart = acquireChart(
              <String, Object?>{
                'options': <String, Object?>{
                  'responsive': true,
                  'aspectRatio': 1,
                },
              },
              <String, Object?>{
                'canvas': <String, Object?>{'style': '', 'width': 400},
              },
            );

            expect(
              chart,
              toBeChartOfSize({'dw': 400, 'dh': 400, 'rw': 400, 'rh': 400}),
            );

            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 400, 'dh': 200, 'rw': 400, 'rh': 200}),
              );

              done();
            });
            chart.options['aspectRatio'] = 2;
            chart.resize();
          });
        },
      );
    });

    group('controller.reset', () {
      // :1515 The y values include the legend box at the top of the chart.
      testWidgets('should reset the chart elements', (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'labels': <Object?>['A', 'B', 'C', 'D'],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 20, 30, 0],
              },
            ],
          },
          'options': <String, Object?>{'responsive': true},
        });

        final meta = chart.getDatasetMeta(0);

        // Verify that points are at their initial correct location,
        // then we will reset and see that they moved
        expect(_y(meta.data[0]), toBeCloseToPixel(333));
        expect(_y(meta.data[1]), toBeCloseToPixel(183));
        expect(_y(meta.data[2]), toBeCloseToPixel(32));
        expect(_y(meta.data[3]), toBeCloseToPixel(482));

        chart.reset();

        // For a line chart, the animation state is the bottom
        expect(_y(meta.data[0]), toBeCloseToPixel(482));
        expect(_y(meta.data[1]), toBeCloseToPixel(482));
        expect(_y(meta.data[2]), toBeCloseToPixel(482));
        expect(_y(meta.data[3]), toBeCloseToPixel(482));
      });
    });

    group('config update', () {
      testWidgets('should update options', (tester) async {
        final chart =
            acquireChart(<String, Object?>{
                'type': 'line',
                'data': <String, Object?>{
                  'labels': <Object?>['A', 'B', 'C', 'D'],
                  'datasets': <Object?>[
                    <String, Object?>{
                      'data': <Object?>[10, 20, 30, 100],
                    },
                  ],
                },
                'options': <String, Object?>{'responsive': true},
              })
              ..options = <String, Object?>{
                'responsive': false,
                'scales': <String, Object?>{
                  'y': <String, Object?>{'min': 0, 'max': 10},
                },
              }
              ..update();

        final yScale = chart.scales['y']!;
        expect(yScale.options['min'], 0);
        expect(yScale.options['max'], 10);
      });

      testWidgets('should update scales options', (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'labels': <Object?>['A', 'B', 'C', 'D'],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 20, 30, 100],
              },
            ],
          },
          'options': <String, Object?>{'responsive': true},
        });

        final y = jsGet(chart.options['scales'], 'y')! as Map<String, Object?>;
        y['min'] = 0;
        y['max'] = 10;
        chart.update();

        final yScale = chart.scales['y']!;
        expect(yScale.options['min'], 0);
        expect(yScale.options['max'], 10);
      });

      testWidgets('should update scales options from new object', (
        tester,
      ) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'labels': <Object?>['A', 'B', 'C', 'D'],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 20, 30, 100],
              },
            ],
          },
          'options': <String, Object?>{'responsive': true},
        });

        final newScalesConfig = <String, Object?>{
          'y': <String, Object?>{'min': 0, 'max': 10},
        };
        chart.options['scales'] = newScalesConfig;

        chart.update();

        final yScale = chart.scales['y']!;
        expect(yScale.options['min'], 0);
        expect(yScale.options['max'], 10);
      });

      testWidgets('should remove discarded scale', (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'labels': <Object?>['A', 'B', 'C', 'D'],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 20, 30, 100],
              },
            ],
          },
          'options': <String, Object?>{
            'responsive': true,
            'scales': <String, Object?>{
              'yAxis0': <String, Object?>{'min': 0, 'max': 10},
            },
          },
        });

        final newScalesConfig = <String, Object?>{
          'y': <String, Object?>{'min': 0, 'max': 10},
        };
        chart.options['scales'] = newScalesConfig;

        chart.update();

        final yScale = chart.scales['yAxis0'];
        expect(yScale, isNull);
        final newyScale = chart.scales['y']!;
        expect(newyScale.options['min'], 0);
        expect(newyScale.options['max'], 10);
      });

      testWidgets('should update tooltip options', (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'labels': <Object?>['A', 'B', 'C', 'D'],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 20, 30, 100],
              },
            ],
          },
          'options': <String, Object?>{'responsive': true},
        });

        final newTooltipConfig = <String, Object?>{
          'mode': 'dataset',
          'intersect': false,
        };
        (chart.options['plugins']! as Map<String, Object?>)['tooltip'] =
            newTooltipConfig;

        chart.update();
        expect(chart.tooltip!.options, toEqualOptions(newTooltipConfig));
      });

      testWidgets('should update the tooltip on update', (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'labels': <Object?>['A', 'B', 'C', 'D'],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 20, 30, 100],
              },
            ],
          },
          'options': <String, Object?>{
            'responsive': true,
            'tooltip': <String, Object?>{'mode': 'nearest'},
          },
        });

        // Trigger an event over top of a point to
        // put an item into the tooltip
        final meta = chart.getDatasetMeta(0);
        final point = meta.data[1];

        await triggerMouseEvent(chart, 'mousemove', point);
        // Check and see if tooltip was displayed
        final tooltip = chart.tooltip!;

        expect(chart.active[0].element, jasmineEquals(point));
        expect(_tooltipActive(tooltip)[0].element, jasmineEquals(point));

        // Update and confirm tooltip is updated
        chart.update();
        expect(chart.active[0].element, jasmineEquals(point));
        expect(_tooltipActive(tooltip)[0].element, jasmineEquals(point));
      });

      testWidgets('should update the metadata', (tester) async {
        final cfg = <String, Object?>{
          'data': <String, Object?>{
            'labels': <Object?>['A', 'B', 'C', 'D'],
            'datasets': <Object?>[
              <String, Object?>{
                'type': 'line',
                'data': <Object?>[10, 20, 30, 0],
              },
            ],
          },
          'options': <String, Object?>{
            'responsive': true,
            'scales': <String, Object?>{
              'x': <String, Object?>{'type': 'category'},
              'y': <String, Object?>{
                'type': 'linear',
                'title': <String, Object?>{'display': true, 'text': 'Value'},
              },
            },
          },
        };
        final chart = acquireChart(cfg);
        var meta = chart.getDatasetMeta(0);
        expect(meta.type, 'line');

        // change the dataset to bar and check that meta was updated
        (jsGet(jsGet(chart.config.data, 'datasets'), 0)!
                as Map<String, Object?>)['type'] =
            'bar';
        chart.update();
        meta = chart.getDatasetMeta(0);
        expect(meta.type, 'bar');
      });
    });

    group('plugin.extensions', () {
      final hooks = <String, List<String>>{
        'install': ['install'],
        'uninstall': ['uninstall'],
        'init': ['beforeInit', 'resize', 'afterInit'],
        'start': ['start'],
        'stop': ['stop'],
        'update': [
          'beforeUpdate',
          'beforeLayout',
          'beforeDataLimits', // y-axis fit
          'afterDataLimits',
          'beforeBuildTicks',
          'afterBuildTicks',
          'beforeDataLimits', // x-axis fit
          'afterDataLimits',
          'beforeBuildTicks',
          'afterBuildTicks',
          // 'beforeBuildTicks', // y-axis re-fit
          // 'afterBuildTicks',
          'afterLayout',
          'beforeDatasetsUpdate',
          'beforeDatasetUpdate',
          'afterDatasetUpdate',
          'afterDatasetsUpdate',
          'afterUpdate',
        ],
        'render': [
          'beforeRender',
          'beforeDraw',
          'beforeDatasetsDraw',
          'beforeDatasetDraw',
          'afterDatasetDraw',
          'afterDatasetsDraw',
          // 'beforeTooltipDraw',
          // 'afterTooltipDraw',
          'afterDraw',
          'afterRender',
        ],
        'resize': ['resize'],
        'destroy': ['beforeDestroy', 'afterDestroy'],
      };

      testWidgets('should notify plugin in correct order', (tester) async {
        await waitForDone((done) {
          final plugin = <String, Object?>{};
          final sequence = <Object?>[];

          for (final group in jsObjectKeys(hooks)) {
            for (final name in hooks[group]!) {
              plugin[name] = () {
                sequence.add(name);
              };
            }
          }

          final chart = acquireChart(
            <String, Object?>{
              'type': 'line',
              'data': <String, Object?>{
                'datasets': <Object?>[<String, Object?>{}],
              },
              'plugins': <Object?>[plugin],
              'options': <String, Object?>{'responsive': true},
            },
            <String, Object?>{
              'wrapper': <String, Object?>{'style': 'width: 300px'},
            },
          );

          waitForResize(chart, () {
            chart.destroy();

            expect(
              sequence,
              jasmineEquals(<Object?>[
                ...hooks['install']!,
                ...hooks['start']!,
                ...hooks['init']!,
                ...hooks['update']!,
                ...hooks['render']!,
                ...hooks['resize']!,
                ...hooks['update']!,
                ...hooks['render']!,
                ...hooks['destroy']!,
                ...hooks['stop']!,
                ...hooks['uninstall']!,
              ]),
            );

            done();
          });
          chart.canvas!.parentElement!.style.width = '400px';
          chart.canvas!.parentElement!.style.height = '400px';
        });
      });

      testWidgets('should notify initially disabled plugin in correct order', (
        tester,
      ) async {
        final plugin = <String, Object?>{'id': 'plugin'};
        var sequence = <Object?>[];

        for (final group in jsObjectKeys(hooks)) {
          for (final name in hooks[group]!) {
            plugin[name] = () {
              sequence.add(name);
            };
          }
        }

        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[<String, Object?>{}],
          },
          'plugins': <Object?>[plugin],
          'options': <String, Object?>{
            'plugins': <String, Object?>{'plugin': false},
          },
        });

        expect(sequence, jasmineEquals(<Object?>[...hooks['install']!]));

        sequence = [];
        (chart.options['plugins']! as Map<String, Object?>)['plugin'] = true;
        chart.update();

        expect(
          sequence,
          jasmineEquals(<Object?>[
            ...hooks['start']!,
            ...hooks['update']!,
            ...hooks['render']!,
          ]),
        );

        sequence = [];
        (chart.options['plugins']! as Map<String, Object?>)['plugin'] = false;
        chart.update();

        expect(sequence, jasmineEquals(hooks['stop']));

        sequence = [];
        chart.destroy();

        expect(sequence, jasmineEquals(hooks['uninstall']));
      });

      testWidgets(
        'should not notify before/afterDatasetDraw if dataset is hidden',
        (tester) async {
          final sequence = <Object?>[];
          final plugin = <String, Object?>{
            'beforeDatasetDraw': (Object? chart, Object? args) {
              sequence.add('before-${jsToString(jsGet(args, 'index'))}');
            },
            'afterDatasetDraw': (Object? chart, Object? args) {
              sequence.add('after-${jsToString(jsGet(args, 'index'))}');
            },
          };

          acquireChart(<String, Object?>{
            'type': 'line',
            'data': <String, Object?>{
              'datasets': <Object?>[
                <String, Object?>{},
                <String, Object?>{'hidden': true},
                <String, Object?>{},
              ],
            },
            'plugins': <Object?>[plugin],
          });

          expect(
            sequence,
            jasmineEquals(<Object?>[
              'before-2',
              'after-2',
              'before-0',
              'after-0',
            ]),
          );
        },
      );

      // `chart._plugins._init` is `chart.plugins.cache`. `PluginService._init`
      // of core.plugins.dart is private, and `cache` (core.plugins.js:94
      // `_cache`) is public. For this chart both lists hold one descriptor
      // with the same plugin and an options resolver without keys, in the
      // port and upstream: the chart disables no plugin
      // (core.plugins.js:101-107). `Object.getPrototypeOf(plugin.options)` is
      // null: the options are a resolver of helpers.config, a Map, and a Map
      // has no prototype (the trap table of helpers.config.dart,
      // differences.md row js-semantics-resolver-objects).
      testWidgets(
        'should not crash when accessing options of a blank inline plugin',
        (tester) async {
          final chart = acquireChart(<String, Object?>{
            'type': 'line',
            'data': <String, Object?>{
              'datasets': <Object?>[<String, Object?>{}],
            },
            'plugins': <Object?>[<String, Object?>{}],
          });

          void iterateOptions() {
            for (final plugin in chart.plugins.cache!) {
              // triggering bug https://github.com/chartjs/Chart.js/issues/9368
              expect(plugin.options, isA<Map<String, Object?>>());
            }
          }

          expect(iterateOptions, returnsNormally);
        },
      );
    });

    group('metasets', () {
      late Chart chart;

      // The beforeEach acquires a chart, and the afterEach reads it: local
      // functions that each case calls first and last (Chart.js ADR 0022,
      // section 2).
      void beforeEach() {
        chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'label': '1', 'order': 2},
              <String, Object?>{'label': '2', 'order': 1},
              <String, Object?>{'label': '3', 'order': 4},
              <String, Object?>{'label': '4', 'order': 3},
            ],
          },
        });
      }

      void afterEach() {
        final metasets = chart.metasets;
        expect(metasets.length, jasmineEquals(_datasets(chart).length));
        for (var i = 0; i < metasets.length; i++) {
          expect(metasets[i]!.index, jasmineEquals(i));
          expect(metasets[i]!.dataset_, jasmineEquals(_datasets(chart)[i]));
        }
      }

      testWidgets('should build metasets array in order', (tester) async {
        beforeEach();
        final metasets = chart.metasets;
        expect(metasets[0]!.order, jasmineEquals(2));
        expect(metasets[1]!.order, jasmineEquals(1));
        expect(metasets[2]!.order, jasmineEquals(4));
        expect(metasets[3]!.order, jasmineEquals(3));
        afterEach();
      });

      testWidgets('should build sorted metasets array in correct order', (
        tester,
      ) async {
        beforeEach();
        final metasets = chart.sortedMetasets;
        expect(metasets[0]!.order, jasmineEquals(1));
        expect(metasets[1]!.order, jasmineEquals(2));
        expect(metasets[2]!.order, jasmineEquals(3));
        expect(metasets[3]!.order, jasmineEquals(4));
        afterEach();
      });

      testWidgets('should be moved when datasets are removed from beginning', (
        tester,
      ) async {
        beforeEach();
        jsSplice(_datasets(chart), 0, 2);
        chart.update();
        final metasets = chart.metasets;
        expect(metasets[0]!.order, jasmineEquals(4));
        expect(metasets[1]!.order, jasmineEquals(3));
        afterEach();
      });

      testWidgets('should be moved when datasets are removed from middle', (
        tester,
      ) async {
        beforeEach();
        jsSplice(_datasets(chart), 1, 2);
        chart.update();
        final metasets = chart.metasets;
        expect(metasets[0]!.order, jasmineEquals(2));
        expect(metasets[1]!.order, jasmineEquals(3));
        afterEach();
      });

      testWidgets('should be moved when datasets are inserted', (tester) async {
        beforeEach();
        jsSplice(_datasets(chart), 1, 0, [
          <String, Object?>{'label': '1.5', 'order': 5},
        ]);
        chart.update();
        final metasets = chart.metasets;
        expect(metasets[0]!.order, jasmineEquals(2));
        expect(metasets[1]!.order, jasmineEquals(5));
        expect(metasets[2]!.order, jasmineEquals(1));
        expect(metasets[3]!.order, jasmineEquals(4));
        expect(metasets[4]!.order, jasmineEquals(3));
        afterEach();
      });

      testWidgets('should be replaced when dataset is replaced', (
        tester,
      ) async {
        beforeEach();
        jsSplice(_datasets(chart), 1, 1, [
          <String, Object?>{'label': '1.5', 'order': 5},
        ]);
        chart.update();
        final metasets = chart.metasets;
        expect(metasets[0]!.order, jasmineEquals(2));
        expect(metasets[1]!.order, jasmineEquals(5));
        expect(metasets[2]!.order, jasmineEquals(4));
        expect(metasets[3]!.order, jasmineEquals(3));
        afterEach();
      });

      testWidgets('should update properly when dataset locations are swapped', (
        tester,
      ) async {
        beforeEach();
        final orig = _datasets(chart);
        chart.data['datasets'] = <Object?>[orig[0], orig[2], orig[1], orig[3]];
        chart.update();
        var metasets = chart.metasets;
        expect(metasets[0]!.label, jasmineEquals('1'));
        expect(metasets[1]!.label, jasmineEquals('3'));
        expect(metasets[2]!.label, jasmineEquals('2'));
        expect(metasets[3]!.label, jasmineEquals('4'));

        chart.data['datasets'] = <Object?>[
          <String, Object?>{'label': 'new', 'order': 10},
          orig[3],
          orig[2],
          orig[1],
          orig[0],
        ];
        chart.update();
        metasets = chart.metasets;
        expect(metasets[0]!.label, jasmineEquals('new'));
        expect(metasets[1]!.label, jasmineEquals('4'));
        expect(metasets[2]!.label, jasmineEquals('3'));
        expect(metasets[3]!.label, jasmineEquals('2'));
        expect(metasets[4]!.label, jasmineEquals('1'));

        chart.data['datasets'] = <Object?>[
          orig[3],
          orig[2],
          orig[1],
          <String, Object?>{'label': 'new', 'order': 10},
        ];
        chart.update();
        metasets = chart.metasets;
        expect(metasets[0]!.label, jasmineEquals('4'));
        expect(metasets[1]!.label, jasmineEquals('3'));
        expect(metasets[2]!.label, jasmineEquals('2'));
        expect(metasets[3]!.label, jasmineEquals('new'));
        afterEach();
      });
    });

    group('_destroyDatasetMeta', () {
      late Chart chart;

      // The beforeEach acquires a chart: a local function that the case
      // calls first (Chart.js ADR 0022, section 2).
      void beforeEach() {
        chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'label': '1', 'order': 2},
              <String, Object?>{'label': '2', 'order': 1},
              <String, Object?>{'label': '3', 'order': 4},
              <String, Object?>{'label': '4', 'order': 3},
            ],
          },
        });
      }

      testWidgets('cleans up metasets when the chart is destroyed', (
        tester,
      ) async {
        beforeEach();
        chart.destroy();
        // `delete this._metasets[i]` leaves a hole, which reads as
        // `undefined`. Dart null stands for the hole (core.controller.dart).
        expect(
          chart.metasets,
          jasmineEquals(<Object?>[null, null, null, null]),
        );
      });
    });

    group('data visibility', () {
      testWidgets('should hide a dataset', (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[0, 1, 2],
              },
            ],
            'labels': <Object?>['a', 'b', 'c'],
          },
        })..setDatasetVisibility(0, false);

        final meta = chart.getDatasetMeta(0);
        expect(meta.hidden, true);
      });

      testWidgets('should toggle data visibility by index', (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'pie',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[1, 2, 3],
              },
            ],
          },
        });

        expect(chart.getDataVisibility(1), true);

        chart.toggleDataVisibility(1);
        expect(chart.getDataVisibility(1), false);

        chart.update();
        expect(chart.getDataVisibility(1), false);
      });

      testWidgets(
        'should maintain data visibility indices when data changes',
        (tester) async {
          final chart = acquireChart(<String, Object?>{
            'type': 'pie',
            'data': <String, Object?>{
              'labels': <Object?>['0', '1', '2', '3'],
              'datasets': <Object?>[
                <String, Object?>{
                  'data': <Object?>[0, 1, 2, 3],
                },
                <String, Object?>{
                  'data': <Object?>[0, 1, 2, 3],
                },
              ],
            },
          })..toggleDataVisibility(3);

          _splice(_labels(chart), 1, 1);
          _splice(_data(chart, 0), 1, 1);
          _splice(_data(chart, 1), 1, 1);
          chart.update();

          expect(chart.getDataVisibility(0), true);
          expect(chart.getDataVisibility(1), true);
          expect(chart.getDataVisibility(2), false);

          _unshift(_labels(chart), <Object?>['-1', '-2']);
          _unshift(_data(chart, 0), <Object?>[-1, -2]);
          _unshift(_data(chart, 1), <Object?>[-1, -2]);
          chart.update();

          expect(chart.getDataVisibility(0), true);
          expect(chart.getDataVisibility(1), true);
          expect(chart.getDataVisibility(2), true);
          expect(chart.getDataVisibility(3), true);
          expect(chart.getDataVisibility(4), false);

          _shift(_labels(chart));
          _shift(_data(chart, 0));
          _shift(_data(chart, 1));
          chart.update();

          expect(chart.getDataVisibility(0), true);
          expect(chart.getDataVisibility(1), true);
          expect(chart.getDataVisibility(2), true);
          expect(chart.getDataVisibility(3), false);

          _pop(_labels(chart));
          _pop(_data(chart, 0));
          _pop(_data(chart, 1));
          chart.update();

          expect(chart.getDataVisibility(0), true);
          expect(chart.getDataVisibility(1), true);
          expect(chart.getDataVisibility(2), true);
          expect(chart.getDataVisibility(3), true);

          chart.toggleDataVisibility(1);
          _splice(_labels(chart), 1, 0, <Object?>['b']);
          _splice(_data(chart, 0), 1, 0, <Object?>[1]);
          _splice(_data(chart, 1), 1, 0, <Object?>[1]);
          chart.update();

          expect(chart.getDataVisibility(0), true);
          expect(chart.getDataVisibility(1), true);
          expect(chart.getDataVisibility(2), false);
          expect(chart.getDataVisibility(3), true);
        },
      );

      testWidgets(
        'should leave data visibility indices intact when data changes in '
        'non-uniform way',
        (tester) async {
          final chart = acquireChart(<String, Object?>{
            'type': 'pie',
            'data': <String, Object?>{
              'labels': <Object?>['0', '1', '2', '3'],
              'datasets': <Object?>[
                <String, Object?>{
                  'data': <Object?>[0, 1, 2, 3],
                },
                <String, Object?>{
                  'data': <Object?>[0, 1, 2, 3],
                },
              ],
            },
          })..toggleDataVisibility(0);

          _push(_labels(chart), <Object?>['a']);
          _pop(_data(chart, 0));
          _push(_data(chart, 1), <Object?>[5]);
          chart.update();

          expect(chart.getDataVisibility(0), false);
          expect(chart.getDataVisibility(1), true);
          expect(chart.getDataVisibility(2), true);
          expect(chart.getDataVisibility(3), true);
        },
      );
    });

    group('isDatasetVisible', () {
      testWidgets('should return false if index is out of bounds', (
        tester,
      ) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[0, 1, 2],
              },
            ],
            'labels': <Object?>['a', 'b', 'c'],
          },
        });

        expect(chart.isDatasetVisible(1), false);
      });
    });

    group('getChart', () {
      test(
        'should get the chart from the canvas ID',
        () {},
        skip: 'n/a: Flutter has no DOM element ids',
      );

      testWidgets('should get the chart from an HTMLCanvasElement', (
        tester,
      ) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'pie',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[1, 2, 3],
              },
            ],
          },
        });
        expect(Chart.getChart(chart.canvas), same(chart));
      });

      testWidgets('should get the chart from an CanvasRenderingContext2D', (
        tester,
      ) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'pie',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[1, 2, 3],
              },
            ],
          },
        });
        expect(Chart.getChart(chart.ctx), same(chart));
      });

      test(
        'should return undefined when a chart is not found or bad data is '
        'provided',
        () {
          expect(Chart.getChart(1), isNull);
        },
      );
    });

    group('active elements', () {
      testWidgets('should set the active elements', (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'pie',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[1, 2, 3],
                'borderColor': 'red',
                'hoverBorderColor': 'blue',
              },
            ],
          },
        });

        final meta = chart.getDatasetMeta(0);
        final arc0 = meta.data[0] as Element;
        var props = arc0.getProps(const ['borderColor']);
        expect(jsGet(props['options'], 'borderColor'), jasmineEquals('red'));

        chart.setActiveElements(<Object?>[
          <String, Object?>{'datasetIndex': 0, 'index': 0},
        ]);

        props = arc0.getProps(const ['borderColor']);
        expect(jsGet(props['options'], 'borderColor'), jasmineEquals('blue'));

        final active = chart.getActiveElements();
        expect(active.length, jasmineEquals(1));
        expect(active[0].element, same(meta.data[0]));
      });
    });

    testWidgets(
      'should not replace the user set active elements by event replay',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'labels': <Object?>[1, 2, 3],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[1, 2, 3],
                'borderColor': 'red',
                'hoverBorderColor': 'blue',
              },
            ],
          },
        });

        final meta = chart.getDatasetMeta(0);
        final point0 = meta.data[0] as Element;
        final point1 = meta.data[1] as Element;

        final props = point0.getProps(const ['borderColor']);
        expect(jsGet(props['options'], 'borderColor'), jasmineEquals('red'));

        await triggerMouseEvent(chart, 'mousemove', <String, Object?>{
          'x': point0.x,
          'y': point0.y,
        });
        expect(
          _activeElements(chart),
          jasmineEquals(<Object?>[
            <String, Object?>{
              'datasetIndex': 0,
              'index': 0,
              'element': point0,
            },
          ]),
        );
        expect(point0.options!['borderColor'], jasmineEquals('blue'));
        expect(point1.options!['borderColor'], jasmineEquals('red'));

        chart.setActiveElements(<Object?>[
          <String, Object?>{'datasetIndex': 0, 'index': 1},
        ]);
        expect(
          _activeElements(chart),
          jasmineEquals(<Object?>[
            <String, Object?>{
              'datasetIndex': 0,
              'index': 1,
              'element': point1,
            },
          ]),
        );
        expect(point0.options!['borderColor'], jasmineEquals('red'));
        expect(point1.options!['borderColor'], jasmineEquals('blue'));

        chart.update();
        expect(
          _activeElements(chart),
          jasmineEquals(<Object?>[
            <String, Object?>{
              'datasetIndex': 0,
              'index': 1,
              'element': point1,
            },
          ]),
        );
        expect(point0.options!['borderColor'], jasmineEquals('red'));
        expect(point1.options!['borderColor'], jasmineEquals('blue'));
      },
    );

    group('platform', () {
      testWidgets('should use the platform constructor provided in config', (
        tester,
      ) async {
        // `Chart.platforms.BasicPlatform` (src/index.umd.ts:41) is the class
        // value `BasicPlatform.jsClass` (Chart.js ADR 0020, section 3).
        final chart = acquireChart(<String, Object?>{
          'platform': BasicPlatform.jsClass,
          'type': 'line',
        });
        expect(chart.platform, isA<BasicPlatform>());
      });
    });
  });
}
