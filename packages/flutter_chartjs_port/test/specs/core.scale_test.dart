// Ported from Chart.js v4.5.1+7169e651 test/specs/core.scale.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'dart:math' as math;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
// The spec builds charts of flutter_chartjs_port, which does not export lib/src
// yet.
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_math.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;
import '../support/jasmine.dart';

// The spec reads Chart.defaults, which is `defaults` of core.defaults.dart.
// Its chart cases call `acquireChart`. Thus they are `testWidgets` cases, and
// the file runs on the VM (Chart.js ADR 0022, sections 1 and 2).
// flutter_test_config.dart registers the built-in components before main().
// Thus the category and linear scales of phase 6 and the controllers of
// phase 7 are in the registry.
//
// `Object.keys(chart.scales).sort()` is `jsSort` of the keys with
// `String.compareTo`: the keys are strings, and the default comparator of
// `Array.prototype.sort` and `String.compareTo` both compare the UTF-16 code
// units.
// `expect(fn).not.toThrow()` is `expect(fn, returnsNormally)`.
//
// An option function of the spec, for example `afterBuildTicks`, is a Dart
// closure. The scale calls it through `jsCall` (Chart.js ADR 0043).
// `scale.ticks.slice(1)` is `scale.ticks!.sublist(1)`. `expect(fn).toThrow()`
// with no argument is `throwsA(anything)`.
//
// A class `class X extends Chart.Scale` of the spec is a Dart subclass of
// Scale and a class value that constructs it: `JsClass('X', superclass:
// Scale.jsClass, construct: ...)`. The static properties that the spec writes
// after the class are writes with `operator []=` (Chart.js ADR 0020, section
// 8). Dart has no local classes, so the classes of the spec are private
// classes of this file. `chart.scales.x` is `chart.scales['x']!`, and
// `scale._layers()` is `scale.layers!()` (Chart.js ADR 0012, Underscore
// members). `new Error(m)` is a StateError with the message m.
//
// The other spec forms:
// - `xScale.ctx = window.createMockContext()` is
//   `xScale.ctx = createMockContext()` of
//   package:chartjs_test_utils/pure.dart. A call of `getCalls()` is a Map
//   with the keys `name` and `args`.
// - `toEqual` is `jasmineEquals`. `toBeCloseTo` is `_toBeCloseTo`.
// - `new Array(300).fill(value)` is `List.filled(300, value)`.
// - `parseFloat(value.toFixed(2))` is
//   `jsParseFloat(value.toStringAsFixed(2))`.

/// The member read `object.key` of the option object [object].
Object? _member(Object? object, String key) =>
    (object! as Map<String, Object?>)[key];

/// core.scale.tests.js:1-3 `getLabels(scale)`: the labels of the ticks of
/// [scale].
List<Object?> _getLabels(Scale scale) {
  return scale.ticks!.map((t) => t.label).toList();
}

/// core.scale.tests.js:514-519 `class CustomScale extends Chart.Scale`.
final class _CustomScale extends Scale {
  _CustomScale(super.cfg);

  @override
  void draw([types.ChartArea? chartArea]) {}

  /// core.scale.tests.js:516 `convertTicksToLabels()`. Scale of v4.5.1 has
  /// no member with this name, and nothing calls it.
  List<Object?> convertTicksToLabels() {
    return ['tick'];
  }
}

/// core.scale.tests.js:547-552 `class CustomScale1 extends Chart.Scale`.
final class _CustomScale1 extends Scale {
  _CustomScale1(super.cfg);

  @override
  void draw([types.ChartArea? chartArea]) {}

  /// core.scale.tests.js:549 `convertTicksToLabels()`. Scale of v4.5.1 has
  /// no member with this name, and nothing calls it.
  List<Object?> convertTicksToLabels() {
    return ['tick'];
  }
}

/// core.scale.tests.js:580-582 `class CustomScale2 extends Chart.Scale`.
final class _CustomScale2 extends Scale {
  _CustomScale2(super.cfg);

  @override
  void draw([types.ChartArea? chartArea]) {}
}

/// The eight items of `gridLineTests` (core.scale.tests.js:110-150). The
/// last four repeat the flags of the first four with one label. Their test
/// names get ` #2` (porting-flow.md section 1, step 5).
const List<
  ({
    List<Object?> labels,
    bool offsetGridLines,
    bool offset,
    List<Object?> expected,
  })
>
_gridLineTests = [
  (
    labels: ['tick1', 'tick2', 'tick3', 'tick4', 'tick5'],
    offsetGridLines: false,
    offset: false,
    expected: [0.5, 128.5, 256.5, 384.5, 512.5],
  ),
  (
    labels: ['tick1', 'tick2', 'tick3', 'tick4', 'tick5'],
    offsetGridLines: false,
    offset: true,
    expected: [51.5, 153.5, 256.5, 358.5, 460.5],
  ),
  (
    labels: ['tick1', 'tick2', 'tick3', 'tick4', 'tick5'],
    offsetGridLines: true,
    offset: false,
    expected: [64.5, 192.5, 320.5, 448.5],
  ),
  (
    labels: ['tick1', 'tick2', 'tick3', 'tick4', 'tick5'],
    offsetGridLines: true,
    offset: true,
    expected: [0.5, 102.5, 204.5, 307.5, 409.5, 512.5],
  ),
  (
    labels: ['tick1'],
    offsetGridLines: false,
    offset: false,
    expected: [0.5],
  ),
  (
    labels: ['tick1'],
    offsetGridLines: false,
    offset: true,
    expected: [256.5],
  ),
  (
    labels: ['tick1'],
    offsetGridLines: true,
    offset: false,
    expected: [512.5],
  ),
  (
    labels: ['tick1'],
    offsetGridLines: true,
    offset: true,
    expected: [0.5, 512.5],
  ),
];

/// `x.args[index]` of a call of the mock context.
Object? _arg(ContextCall call, int index) =>
    (call['args']! as List<Object?>)[index];

/// Jasmine `toBeCloseTo(expected, precision)` of jasmine-core 3.99.1:
/// `Math.round(delta * 10^(precision + 1)) <= 10^-precision / 2 *
/// 10^(precision + 1)`, with `delta = |expected - actual|`.
Matcher _toBeCloseTo(num expected, [int precision = 2]) {
  // js-ok: the exponents are ints, as in Jasmine's Math.pow.
  final pow = math.pow(10.0, precision + 1);
  // js-ok: the exponent is an int, as in Jasmine's Math.pow.
  final maxDelta = math.pow(10.0, -precision) / 2;
  return predicate<Object?>(
    (actual) =>
        actual is num &&
        jsRound(((expected - actual).abs() * pow).toDouble()) <= maxDelta * pow,
    'a number close to ${jsToString(expected)} (Jasmine toBeCloseTo, '
    'precision ${jsToString(precision)})',
  );
}

/// The names of the cases that `gridLineTests.forEach` makes from [prefix],
/// with ` #2` for a repeated name.
List<String> _gridLineNames(String prefix) {
  final names = <String>[];
  for (final test in _gridLineTests) {
    final name =
        '$prefix when offsetGridLines is ${test.offsetGridLines} and offset '
        'is ${test.offset}';
    names.add(names.contains(name) ? '$name #2' : name);
  }
  return names;
}

void main() {
  group('Core.scale', () {
    group('auto', fixture.specs('core.scale'));

    test('should provide default scale label options', () {
      final scale = _member(defaults, 'scale');
      expect(
        _member(scale, 'title'),
        equals(<String, Object?>{
          'color': defaults['color'],
          'display': false,
          'text': '',
          'padding': <String, Object?>{'top': 4, 'bottom': 4},
        }),
      );
    });

    group('displaying xAxis ticks with autoSkip=true', () {
      Chart getChart(Map<String, Object?> data) {
        return acquireChart(<String, Object?>{
          'type': 'line',
          'data': data,
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{
                'ticks': <String, Object?>{'autoSkip': true},
              },
            },
          },
        });
      }

      Chart getChartBigData(int maxTicksLimit) {
        return acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'labels': List<Object?>.filled(300, 'red'),
            'datasets': <Object?>[
              <String, Object?>{'data': List<Object?>.filled(300, 5)},
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{
                'ticks': <String, Object?>{
                  'autoSkip': true,
                  'maxTicksLimit': maxTicksLimit,
                },
              },
            },
          },
        });
      }

      Tick lastTick(Chart chart) {
        final xAxis = chart.scales['x']!;
        final ticks = xAxis.getTicks()!;
        return ticks[ticks.length - 1];
      }

      testWidgets(
        'should use autoSkip amount of ticks when maxTicksLimit is set to a '
        'larger number as autoSkip calculation',
        (tester) async {
          final chart = getChartBigData(300);
          expect(chart.scales['x']!.ticks!.length, jasmineEquals(20));
        },
      );

      testWidgets(
        'should use maxTicksLimit amount of ticks when maxTicksLimit is set '
        'to a smaller number as autoSkip calculation',
        (tester) async {
          final chart = getChartBigData(3);
          expect(chart.scales['x']!.ticks!.length, jasmineEquals(3));
        },
      );

      testWidgets(
        'should display the last tick if it fits evenly with other ticks',
        (tester) async {
          final chart = getChart(<String, Object?>{
            'labels': <Object?>[
              'January 2018', 'February 2018', 'March 2018', 'April 2018', //
              'May 2018', 'June 2018', 'July 2018', 'August 2018',
              'September 2018',
            ],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[12, 19, 3, 5, 2, 3, 7, 8, 9],
              },
            ],
          });

          expect(lastTick(chart).label, jasmineEquals('September 2018'));
        },
      );

      testWidgets(
        'should not display the last tick if it does not fit evenly',
        (tester) async {
          final chart = getChart(<String, Object?>{
            'labels': <Object?>[
              'January 2018', 'February 2018', 'March 2018', 'April 2018', //
              'May 2018', 'June 2018', 'July 2018', 'August 2018',
              'September 2018', 'October 2018', 'November 2018',
              'December 2018',
              'January 2019', 'February 2019', 'March 2019', 'April 2019',
              'May 2019', 'June 2019', 'July 2019', 'August 2019',
              'September 2019', 'October 2019', 'November 2019',
              'December 2019',
              'January 2020', 'February 2020', 'March 2020', 'April 2020',
            ],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[
                  1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, //
                  6, 6, 6, 6, 7, 7, 7, 7,
                ],
              },
            ],
          });

          expect(lastTick(chart).label, jasmineEquals('March 2020'));
        },
      );
    });

    final horizontalNames = _gridLineNames(
      'should get the correct pixels for gridLine(s) for the horizontal scale',
    );
    for (var t = 0; t < _gridLineTests.length; t++) {
      final test = _gridLineTests[t];
      testWidgets(horizontalNames[t], (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': <Object?>[]},
            ],
            'labels': test.labels,
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{
                'grid': <String, Object?>{
                  'offset': test.offsetGridLines,
                  'drawTicks': false,
                },
                'ticks': <String, Object?>{'display': false},
                'offset': test.offset,
              },
              'y': <String, Object?>{'display': false},
            },
            'plugins': <String, Object?>{'legend': false},
          },
        });

        final xScale = chart.scales['x']!;
        final ctx = createMockContext();
        xScale.ctx = ctx;
        chart.draw();

        expect(
          ctx
              .getCalls()
              .where((x) => x['name'] == 'moveTo' && _arg(x, 1) == 0)
              .map((x) => _arg(x, 0))
              .toList(),
          jasmineEquals(test.expected),
        );
      });
    }

    final verticalNames = _gridLineNames(
      'should get the correct pixels for gridLine(s) for the vertical scale',
    );
    for (var t = 0; t < _gridLineTests.length; t++) {
      final test = _gridLineTests[t];
      testWidgets(verticalNames[t], (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': <Object?>[]},
            ],
            'labels': test.labels,
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'display': false},
              'y': <String, Object?>{
                'type': 'category',
                'grid': <String, Object?>{
                  'offset': test.offsetGridLines,
                  'drawTicks': false,
                },
                'ticks': <String, Object?>{'display': false},
                'offset': test.offset,
              },
            },
            'plugins': <String, Object?>{'legend': false},
          },
        });

        final yScale = chart.scales['y']!;
        final ctx = createMockContext();
        yScale.ctx = ctx;
        chart.draw();

        expect(
          ctx
              .getCalls()
              .where((x) => x['name'] == 'moveTo' && _arg(x, 0) == 1)
              .map((x) => _arg(x, 1))
              .toList(),
          jasmineEquals(test.expected),
        );
      });
    }

    testWidgets('should add the correct padding for long tick labels', (
      tester,
    ) async {
      final chart = acquireChart(
        <String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'labels': <Object?>[
              'This is a very long label',
              'This is a very long label',
            ],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[0, 1],
              },
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{'display': false},
            },
            'plugins': <String, Object?>{'legend': false},
          },
        },
        <String, Object?>{
          'canvas': <String, Object?>{'height': 100, 'width': 200},
        },
      );

      final scale = chart.scales['x']!;
      expect(scale.left, greaterThan(100));
      expect(scale.right, greaterThan(190));
    });

    group('given the axes display option is set to auto', () {
      group('for the x axes', () {
        testWidgets(
          'should draw the axes if at least one associated dataset is '
          'visible',
          (tester) async {
            final chart = acquireChart(<String, Object?>{
              'type': 'line',
              'data': <String, Object?>{
                'datasets': <Object?>[
                  <String, Object?>{
                    'data': <Object?>[100, 200, 100, 50],
                    'xAxisId': 'foo',
                    'hidden': true,
                    'labels': <Object?>['Q1', 'Q2', 'Q3', 'Q4'],
                  },
                  <String, Object?>{
                    'data': <Object?>[100, 200, 100, 50],
                    'xAxisId': 'foo',
                    'labels': <Object?>['Q1', 'Q2', 'Q3', 'Q4'],
                  },
                ],
              },
              'options': <String, Object?>{
                'scales': <String, Object?>{
                  'x': <String, Object?>{'display': 'auto'},
                  'y': <String, Object?>{'type': 'category'},
                },
              },
            });

            final scale = chart.scales['x']!;
            final ctx = createMockContext();
            scale.ctx = ctx;
            chart.draw();

            expect(ctx.getCalls().length, greaterThan(0));
            expect(scale.height, greaterThan(0));
          },
        );

        testWidgets(
          'should not draw the axes if no associated datasets are visible',
          (tester) async {
            final chart = acquireChart(<String, Object?>{
              'type': 'line',
              'data': <String, Object?>{
                'datasets': <Object?>[
                  <String, Object?>{
                    'data': <Object?>[100, 200, 100, 50],
                    'xAxisId': 'foo',
                    'hidden': true,
                    'labels': <Object?>['Q1', 'Q2', 'Q3', 'Q4'],
                  },
                ],
              },
              'options': <String, Object?>{
                'scales': <String, Object?>{
                  'x': <String, Object?>{'display': 'auto'},
                },
              },
            });

            final scale = chart.scales['x']!;
            final ctx = createMockContext();
            scale.ctx = ctx;
            chart.draw();

            expect(ctx.getCalls().length, 0);
            expect(scale.height, 0);
          },
        );
      });

      group('for the y axes', () {
        testWidgets(
          'should draw the axes if at least one associated dataset is '
          'visible',
          (tester) async {
            final chart = acquireChart(<String, Object?>{
              'type': 'line',
              'data': <String, Object?>{
                'datasets': <Object?>[
                  <String, Object?>{
                    'data': <Object?>[100, 200, 100, 50],
                    'yAxisId': 'foo',
                    'hidden': true,
                    'labels': <Object?>['Q1', 'Q2', 'Q3', 'Q4'],
                  },
                  <String, Object?>{
                    'data': <Object?>[100, 200, 100, 50],
                    'yAxisId': 'foo',
                    'labels': <Object?>['Q1', 'Q2', 'Q3', 'Q4'],
                  },
                ],
              },
              'options': <String, Object?>{
                'scales': <String, Object?>{
                  'y': <String, Object?>{'display': 'auto'},
                },
              },
            });

            final scale = chart.scales['y']!;
            final ctx = createMockContext();
            scale.ctx = ctx;
            chart.draw();

            expect(ctx.getCalls().length, greaterThan(0));
            expect(scale.width, greaterThan(0));
          },
        );

        testWidgets(
          'should not draw the axes if no associated datasets are visible',
          (tester) async {
            final chart = acquireChart(<String, Object?>{
              'type': 'line',
              'data': <String, Object?>{
                'datasets': <Object?>[
                  <String, Object?>{
                    'data': <Object?>[100, 200, 100, 50],
                    'yAxisId': 'foo',
                    'hidden': true,
                    'labels': <Object?>['Q1', 'Q2', 'Q3', 'Q4'],
                  },
                ],
              },
              'options': <String, Object?>{
                'scales': <String, Object?>{
                  'y': <String, Object?>{'display': 'auto'},
                },
              },
            });

            final scale = chart.scales['y']!;
            final ctx = createMockContext();
            scale.ctx = ctx;
            chart.draw();

            expect(ctx.getCalls().length, 0);
            expect(scale.width, 0);
          },
        );
      });
    });

    group('afterBuildTicks', () {
      testWidgets('should allow filtering of ticks', (tester) async {
        final labels = <Object?>['tick1', 'tick2', 'tick3', 'tick4', 'tick5'];
        final chart = acquireChart({
          'type': 'line',
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{
                'type': 'category',
                'labels': labels,
                'afterBuildTicks': (Scale scale) {
                  scale.ticks = scale.ticks!.sublist(1);
                },
              },
            },
          },
        });

        final scale = chart.scales['x']!;
        expect(_getLabels(scale), labels.sublist(1));
      });

      testWidgets('should allow no return value from callback', (
        tester,
      ) async {
        final labels = <Object?>['tick1', 'tick2', 'tick3', 'tick4', 'tick5'];
        final chart = acquireChart({
          'type': 'line',
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{
                'type': 'category',
                'labels': labels,
                'afterBuildTicks': () {},
              },
            },
          },
        });

        final scale = chart.scales['x']!;
        expect(_getLabels(scale), labels);
      });

      testWidgets('should allow empty ticks', (tester) async {
        final labels = <Object?>['tick1', 'tick2', 'tick3', 'tick4', 'tick5'];
        final chart = acquireChart({
          'type': 'line',
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{
                'type': 'category',
                'labels': labels,
                'afterBuildTicks': (Scale scale) {
                  scale.ticks = [];
                },
              },
            },
          },
        });

        final scale = chart.scales['x']!;
        expect(scale.ticks!.length, 0);
      });
    });

    group('_layers', () {
      testWidgets('should default to three layers', (tester) async {
        final chart = acquireChart({
          'type': 'line',
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'type': 'linear'},
            },
          },
        });

        final scale = chart.scales['x']!;
        expect(scale.layers!().length, 3);
      });

      testWidgets(
        'should create the chart with custom scale ids without axis or '
        'position options',
        (tester) async {
          Chart createChart() {
            return acquireChart(<String, Object?>{
              'type': 'scatter',
              'data': <String, Object?>{
                'datasets': <Object?>[
                  <String, Object?>{
                    'data': <Object?>[
                      <String, Object?>{'x': 0, 'y': 0},
                      <String, Object?>{'x': 1, 'y': 1},
                      <String, Object?>{'x': 2, 'y': 2},
                    ],
                    'xAxisID': 'customIDx',
                    'yAxisID': 'customIDy',
                  },
                ],
              },
              'options': <String, Object?>{
                'scales': <String, Object?>{
                  'customIDx': <String, Object?>{
                    'type': 'linear',
                    'display': false,
                  },
                  'customIDy': <String, Object?>{
                    'type': 'linear',
                    'display': false,
                  },
                },
              },
            });
          }

          expect(createChart, returnsNormally);
        },
      );

      testWidgets('should default to one layer for custom scales', (
        tester,
      ) async {
        final customScale = JsClass(
          'CustomScale',
          superclass: Scale.jsClass,
          construct: (newTarget, args) => _CustomScale(scaleCfgArg(args)),
        );
        customScale['id'] = 'customScale';
        customScale['defaults'] = <String, Object?>{};
        Chart.register([customScale]);

        final chart = acquireChart({
          'type': 'line',
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{
                'type': 'customScale',
                'grid': <String, Object?>{'z': 10},
                'ticks': <String, Object?>{'z': 20},
              },
            },
          },
        });

        final scale = chart.scales['x']!;
        expect(scale.layers!().length, 1);
        expect(scale.layers!()[0].z, 20);
      });

      testWidgets('should default to one layer for custom scales for axis', (
        tester,
      ) async {
        final customScale1 = JsClass(
          'CustomScale1',
          superclass: Scale.jsClass,
          construct: (newTarget, args) => _CustomScale1(scaleCfgArg(args)),
        );
        customScale1['id'] = 'customScale1';
        customScale1['defaults'] = <String, Object?>{'axis': 'x'};
        Chart.register([customScale1]);

        final chart = acquireChart({
          'type': 'line',
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'my': <String, Object?>{
                'type': 'customScale1',
                'grid': <String, Object?>{'z': 10},
                'ticks': <String, Object?>{'z': 20},
              },
            },
          },
        });

        final scale = chart.scales['my']!;
        expect(scale.layers!().length, 1);
        expect(scale.layers!()[0].z, 20);
      });

      testWidgets(
        'should fail for custom scales without any axis or position',
        (tester) async {
          final customScale2 = JsClass(
            'CustomScale2',
            superclass: Scale.jsClass,
            construct: (newTarget, args) => _CustomScale2(scaleCfgArg(args)),
          );
          customScale2['id'] = 'customScale2';
          customScale2['defaults'] = <String, Object?>{};
          Chart.register([customScale2]);

          Chart createChart() {
            return acquireChart({
              'type': 'line',
              'options': <String, Object?>{
                'scales': <String, Object?>{
                  'my': <String, Object?>{'type': 'customScale2'},
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
                "Cannot determine type of 'my' axis. Please provide 'axis' "
                    "or 'position' option.",
              ),
            ),
          );
        },
      );

      testWidgets(
        'should return 3 layers when z is not equal between ticks and grid',
        (tester) async {
          var chart = acquireChart({
            'type': 'line',
            'options': <String, Object?>{
              'scales': <String, Object?>{
                'x': <String, Object?>{
                  'type': 'linear',
                  'ticks': <String, Object?>{'z': 10},
                },
              },
            },
          });

          expect(chart.scales['x']!.layers!().length, 3);

          chart = acquireChart({
            'type': 'line',
            'options': <String, Object?>{
              'scales': <String, Object?>{
                'x': <String, Object?>{
                  'type': 'linear',
                  'grid': <String, Object?>{'z': 11},
                },
              },
            },
          });

          expect(chart.scales['x']!.layers!().length, 3);

          chart = acquireChart({
            'type': 'line',
            'options': <String, Object?>{
              'scales': <String, Object?>{
                'x': <String, Object?>{
                  'type': 'linear',
                  'ticks': <String, Object?>{'z': 10},
                  'grid': <String, Object?>{'z': 11},
                },
              },
            },
          });

          expect(chart.scales['x']!.layers!().length, 3);
        },
      );
    });

    group('min and max', () {
      testWidgets('should be limited to visible data', (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'scatter',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[
                  <String, Object?>{'x': 100, 'y': 100},
                  <String, Object?>{'x': -100, 'y': -100},
                ],
              },
              <String, Object?>{
                'data': <Object?>[
                  <String, Object?>{'x': 10, 'y': 10},
                  <String, Object?>{'x': -10, 'y': -10},
                ],
              },
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{
                'id': 'x',
                'type': 'linear',
                'min': -20,
                'max': 20,
              },
              'y': <String, Object?>{'id': 'y', 'type': 'linear'},
            },
          },
        });

        expect(chart.scales['x']!.min, jasmineEquals(-20));
        expect(chart.scales['x']!.max, jasmineEquals(20));
        expect(chart.scales['y']!.min, jasmineEquals(-10));
        expect(chart.scales['y']!.max, jasmineEquals(10));
      });
    });

    group('overrides', () {
      testWidgets('should create new scale', (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'scatter',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[
                  <String, Object?>{'x': 100, 'y': 100},
                  <String, Object?>{'x': -100, 'y': -100},
                ],
              },
              <String, Object?>{
                'data': <Object?>[
                  <String, Object?>{'x': 10, 'y': 10},
                  <String, Object?>{'x': -10, 'y': -10},
                ],
              },
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x2': <String, Object?>{'type': 'linear', 'min': -20, 'max': 20},
            },
          },
        });

        expect(
          jsSort(chart.scales.keys.toList(), (a, b) => a.compareTo(b)),
          jasmineEquals(<Object?>['x', 'x2', 'y']),
        );
      });

      testWidgets('should create new scale with custom name', (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'scatter',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[
                  <String, Object?>{'x': 100, 'y': 100},
                  <String, Object?>{'x': -100, 'y': -100},
                ],
              },
              <String, Object?>{
                'data': <Object?>[
                  <String, Object?>{'x': 10, 'y': 10},
                  <String, Object?>{'x': -10, 'y': -10},
                ],
              },
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'scaleX': <String, Object?>{
                'axis': 'x',
                'type': 'linear',
                'min': -20,
                'max': 20,
              },
            },
          },
        });

        expect(
          jsSort(chart.scales.keys.toList(), (a, b) => a.compareTo(b)),
          jasmineEquals(<Object?>['scaleX', 'x', 'y']),
        );
      });

      // :743-763 the Error comes from determineAxis (core.config.js:52), in
      // the first loop of mergeScaleConfig. That loop runs in the Config
      // constructor, before the chart reads its controller. It needs
      // `defaults.scales.linear`: without it, determineAxis throws a
      // TypeError first. The bare `toThrow()` of upstream can only catch the
      // determineAxis Error. The matcher checks the message of
      // determineAxis, so another Error does not pass the case.
      testWidgets(
        'should throw error on scale with custom name without axis type',
        (tester) async {
          expect(
            () => acquireChart({
              'type': 'scatter',
              'data': <String, Object?>{
                'datasets': <Object?>[
                  <String, Object?>{
                    'data': <Object?>[
                      <String, Object?>{'x': 100, 'y': 100},
                      <String, Object?>{'x': -100, 'y': -100},
                    ],
                  },
                  <String, Object?>{
                    'data': <Object?>[
                      <String, Object?>{'x': 10, 'y': 10},
                      <String, Object?>{'x': -10, 'y': -10},
                    ],
                  },
                ],
              },
              'options': <String, Object?>{
                'scales': <String, Object?>{
                  'scaleX': <String, Object?>{
                    'type': 'linear',
                    'min': -20,
                    'max': 20,
                  },
                },
              },
            }),
            throwsA(
              isA<StateError>().having(
                (error) => error.message,
                'message',
                "Cannot determine type of 'scaleX' axis. Please provide "
                    "'axis' or 'position' option.",
              ),
            ),
          );
        },
      );

      testWidgets('should read options first to determine axis', (
        tester,
      ) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'scatter',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[
                  <String, Object?>{'x': 100, 'y': 100},
                  <String, Object?>{'x': -100, 'y': -100},
                ],
              },
              <String, Object?>{
                'data': <Object?>[
                  <String, Object?>{'x': 10, 'y': 10},
                  <String, Object?>{'x': -10, 'y': -10},
                ],
              },
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'xavier': <String, Object?>{
                'axis': 'y',
                'type': 'linear',
                'min': -20,
                'max': 20,
              },
            },
          },
        });

        expect(chart.scales['xavier']!.axis, 'y');
      });

      testWidgets('should center labels when rotated in x axis', (
        tester,
      ) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'labels': <Object?>[
              'Red',
              'Blue',
              'Yellow',
              'Green',
              'Purple',
              'Orange',
            ],
            'datasets': <Object?>[
              <String, Object?>{
                'label': '# of Votes',
                'data': <Object?>[12, 19, 3, 5, 2, 3],
              },
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{
                'ticks': <String, Object?>{'minRotation': 90},
              },
            },
          },
        });
        // `parseFloat(value.toFixed(2))`.
        double mapper(types.LabelItem item) =>
            jsParseFloat(item.options.translation!.$1.toStringAsFixed(2));
        const expected = <double>[20.15, 113.6, 207.05, 300.5, 393.95, 487.4];
        final actual = chart.scales['x']!.getLabelItems().map(mapper).toList();
        final len = expected.length;
        for (var i = 0; i < len; ++i) {
          final actualValue = actual[i];
          final expectedValue = expected[i];
          expect(actualValue, _toBeCloseTo(expectedValue, 1));
        }
      });
    });

    // :820-899. The charts have no datasets. Thus they need the linear
    // scale of phase 6 and no controller of phase 7. `scale.options.title`
    // is a resolver, and `toBeUndefined()` is `same(undefined)`.
    group('Scale Title stroke', () {
      /// core.scale.tests.js:821-849 `getChartWithScaleTitleStroke()`.
      Chart getChartWithScaleTitleStroke() {
        return acquireChart({
          'type': 'line',
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{
                'type': 'linear',
                'title': <String, Object?>{
                  'display': true,
                  'text': 'title-x',
                  'color': '#ddd',
                  'strokeWidth': 1,
                  'strokeColor': '#333',
                },
              },
              'y': <String, Object?>{
                'type': 'linear',
                'title': <String, Object?>{
                  'display': true,
                  'text': 'title-y',
                  'color': '#ddd',
                  'strokeWidth': 2,
                  'strokeColor': '#222',
                },
              },
            },
          },
        });
      }

      /// core.scale.tests.js:851-875 `getChartWithoutScaleTitleStroke()`.
      Chart getChartWithoutScaleTitleStroke() {
        return acquireChart({
          'type': 'line',
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{
                'type': 'linear',
                'title': <String, Object?>{
                  'display': true,
                  'text': 'title-x',
                  'color': '#ddd',
                },
              },
              'y': <String, Object?>{
                'type': 'linear',
                'title': <String, Object?>{
                  'display': true,
                  'text': 'title-y',
                  'color': '#ddd',
                },
              },
            },
          },
        });
      }

      testWidgets('should draw a scale title stroke when provided x-axis', (
        tester,
      ) async {
        final chart = getChartWithScaleTitleStroke();
        final scale = chart.scales['x']!;
        expect(_member(scale.options['title'], 'strokeColor'), '#333');
        expect(_member(scale.options['title'], 'strokeWidth'), 1);
      });

      testWidgets('should draw a scale title stroke when provided y-axis', (
        tester,
      ) async {
        final chart = getChartWithScaleTitleStroke();
        final scale = chart.scales['y']!;
        expect(_member(scale.options['title'], 'strokeColor'), '#222');
        expect(_member(scale.options['title'], 'strokeWidth'), 2);
      });

      testWidgets('should not draw a scale title stroke when not provided', (
        tester,
      ) async {
        final chart = getChartWithoutScaleTitleStroke();
        final scales = chart.scales;
        final yTitle = scales['y']!.options['title'];
        final xTitle = scales['x']!.options['title'];
        expect(_member(yTitle, 'strokeColor'), same(undefined));
        expect(_member(yTitle, 'strokeWidth'), same(undefined));
        expect(_member(xTitle, 'strokeColor'), same(undefined));
        expect(_member(xTitle, 'strokeWidth'), same(undefined));
      });
    });
  });
}
