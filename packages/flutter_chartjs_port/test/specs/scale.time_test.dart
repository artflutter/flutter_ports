// Ported from Chart.js v4.6.1 test/specs/scale.time.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'dart:math' as math;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart' show toBeCloseToPixel;
// The spec builds charts of flutter_chartjs_port, which does not export lib/src
// yet.
import 'package:flutter_chartjs_port/src/core/core.adapters.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show clone, mergeIf;
import 'package:flutter_chartjs_port/src/js/js_date.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/scales/scale.time.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;
import '../support/jasmine.dart';

// The spec reads Chart.registry and Chart.defaults, the static members
// `Chart.registry` and `Chart.defaults` of core.controller.dart.
// flutter_test_config.dart registers the built-in components before
// `main()` (`harness-register-builtins`). Thus `registry.getScale('time')`
// gives the class value `TimeScale.jsClass`, and `defaults.scales.time` has
// the defaults of the time scale.
//
// The specs load moment 2.29.4 and chartjs-adapter-moment 1.0.1
// (karma.conf.cjs:106-111). The port has a default date adapter with the
// results of that adapter (Chart.js ADR 0024, row
// `adapt-date-default-adapter`). flutter_test_config.dart sets its default
// zone to UTC, the port of `moment.tz.setDefault('Etc/UTC')`
// (test/index.js:23).
//
// The chart cases call `acquireChart`. Thus they are `testWidgets` cases,
// and the file runs on the VM (Chart.js ADR 0022, sections 1 and 2). A
// case with a dataset needs the line controller of phase 7. The cases of
// the group at :246 also need the legend, which flutter_test_config.dart
// registers. The cases at :305, :390 and :490 assert the lower-case day
// period of moment, which the default adapter gives (Chart.js ADR 0024,
// decision 6).
//
// A case that asserts moment-token text or the moment `FORMATS`, or that
// asserts a value from a parse or a format with a moment format string,
// skips with the row `adapt-date-moment-format`: the port formats and parses
// with ICU patterns. Its port-only twin with ICU patterns is in
// test/port/scales/scale.time_test.dart, group `adapt-date-moment-format`.
// The cases at :639, :650 and :744 also parse their labels with 'YYYY', but
// they assert no value of that parse. Thus they have bodies.
//
// The spec forms:
// - `chart.scales.x` is `chart.scales['x']!`.
// - A property chain of the spec on an option object, for example
//   `Chart.defaults.scales.time`, is a chain of `jsGet`.
// - `Chart.helpers.clone` and `Chart.helpers.mergeIf` are `clone` and
//   `mergeIf` of helpers.core.dart.
// - `Chart._adapters._date` is the class value of `DateAdapterBase`
//   (`adapters['_date']` of core.adapters.dart). Its static `override` is
//   `DateAdapterBase.override`.
// - `typeof Constructor` is `jsTypeof(constructor)`. `not.toBe(undefined)`
//   is `isNot(same(undefined))`.
// - A `beforeEach` of a `describe` that writes no chart is a `setUp`.
//
// - `moment(value)` is `_moment(value)`, the parse of the default adapter.
//   `moment()` is `jsDateNow()`. `startOf`, `endOf` and `add` of a moment
//   are the members of the default adapter (`_startOf`, `_endOf`, `_add`).
// - `scale._unit` is the field `unit` of `TimeScale`.
// - `controller.getParsed(0)[xScale.id]` is
//   `jsGet(controller.getParsed(0), xScale.id)`.
// - `toBeTruthy()` is `jsTruthy(value)`.
// - A `beforeEach` of a `describe` that acquires a chart is a local function
//   that each case calls first. `this.chart` is a `late` variable of the
//   group.
// - The case of :84 parses 'Jan 01 1990' with the ICU pattern
//   'MMM dd yyyy' in place of the moment format 'MMM DD YYYY'. It asserts
//   only the unit. `Math.random()` is `math.Random().nextDouble()`.
// - The case of :548 gives timestamps to `ticks.min` and `ticks.max` in
//   place of moment objects. The time scale of v4 does not read them.

/// scale.time.tests.js:5-25 `createScale(data, options, dimensions)`.
Scale _createScale(
  Map<String, Object?> data, [
  Map<String, Object?>? options,
  Map<String, Object?>? dimensions,
]) {
  final width = jsTruthy(dimensions?['width']) ? dimensions!['width'] : 400;
  final height = jsTruthy(dimensions?['height']) ? dimensions!['height'] : 50;

  options ??= <String, Object?>{};
  options['type'] = 'time';
  options['id'] = 'xScale0';

  final chart = acquireChart(
    <String, Object?>{
      'type': 'line',
      'data': data,
      'options': <String, Object?>{
        'scales': <String, Object?>{'x': options},
      },
    },
    <String, Object?>{
      'canvas': <String, Object?>{'width': width, 'height': height},
    },
  );

  return chart.scales['x']!;
}

/// scale.time.tests.js:27-29 `getLabels(scale)`.
List<Object?> _getLabels(Scale scale) => [
  for (final t in scale.ticks!) t.label,
];

/// The default date adapter, the `moment` of the spec (Chart.js ADR 0024).
final DateAdapterBase _adapter = DateAdapterBase();

/// `moment(value).valueOf()` and `+moment(value, format)`: the parse of the
/// default adapter. A [format] is an ICU pattern in place of the moment
/// format (Chart.js ADR 0024).
double _moment(Object? value, [String? format]) =>
    jsToNumber(_adapter.parse(value, format ?? undefined));

/// `moment(time).startOf(unit)` of the default adapter, as a number.
double _startOf(Object? time, String unit) =>
    jsToNumber(_adapter.startOf(time, unit));

/// `moment(time).endOf(unit)` of the default adapter, as a number.
double _endOf(Object? time, String unit) =>
    jsToNumber(_adapter.endOf(time, unit));

/// `moment(time).add(amount, unit)` of the default adapter, as a number.
double _add(Object? time, num amount, String unit) =>
    jsToNumber(_adapter.add(time, amount, unit));

/// `+new Date(value)`: the time value of the JS Date of [value].
double _dateValue(String value) =>
    DateTime.parse(value).millisecondsSinceEpoch.toDouble();

/// `Math.random()`.
final math.Random _random = math.Random();

/// `chart.data.labels`.
List<Object?> _labels(Chart chart) =>
    jsGet(chart.data, 'labels')! as List<Object?>;

/// `chart.options.scales.x`: a resolver of the chart options. A write goes
/// through it.
AnyObject _scaleOptionsX(Chart chart) =>
    jsGet(jsGet(chart.options, 'scales'), 'x')! as AnyObject;

/// scale.time.tests.js:31-48 the matcher `toBeCloseToTime`:
/// `Math.abs(moment(time).diff(value, unit, true)) < threshold`, with the
/// default threshold 0.01. The precise moment diff of the unit `hour` is
/// the difference in ms over 3600000. The precise moment diff of the unit
/// `day` is the difference in ms over 86400000, because the default zone of
/// the tests is UTC: no zone offset changes between the two times. The
/// cases use only these two units.
Matcher _toBeCloseToTime(double value, String unit, [double threshold = 0.01]) {
  final msPerUnit = switch (unit) {
    'hour' => 3600000,
    'day' => 86400000,
    _ => throw ArgumentError.value(unit, 'unit'),
  };
  return predicate<Object?>(
    (time) => ((jsToNumber(time) - value) / msPerUnit).abs() < threshold,
    'a time close to ${jsToString(value)} (unit $unit, threshold '
    '${jsToString(threshold)})',
  );
}

/// `Chart.helpers.clone(Chart.defaults.scales.time)` (scale.time.tests.js:
/// 125): a deep copy of the defaults of the time scale.
Map<String, Object?> _cloneTimeDefaults() =>
    clone(jsGet(jsGet(Chart.defaults, 'scales'), 'time'))!
        as Map<String, Object?>;

void main() {
  group('Time scale tests', () {
    group('auto', fixture.specs('scale.time'));

    // The upstream test environment loads moment.js and
    // chartjs-adapter-moment, the date library of the time scale
    // (karma.conf.cjs). The port has no moment.js: its date library is the
    // default adapter of Chart.js ADR 0024, which DateAdapterBase.prototype
    // holds from the start. Thus the case asserts that the default adapter
    // is loaded.
    test('should load moment.js as a dependency', () {
      expect(jsGet(DateAdapterBase.prototype, 'parse'), isNot(undefined));
    });

    test('should register the constructor with the registry', () {
      final constructor = Chart.registry.getScale('time');
      expect(constructor, isNot(same(undefined)));
      expect(jsTypeof(constructor), 'function');
    });

    test('should have the correct default config', () {
      final defaultConfig = jsGet(jsGet(Chart.defaults, 'scales'), 'time');
      expect(
        defaultConfig,
        equals(<String, Object?>{
          'bounds': 'data',
          'adapters': <String, Object?>{},
          'time': <String, Object?>{
            // false == a pattern string from or a custom callback that
            // converts its argument to a timestamp
            'parser': false,
            // false == automatic or override with week, month, year, etc.
            'unit': false,
            // none, or override with week, month, year, etc.
            'round': false,
            // override week start day
            'isoWeekday': false,
            'minUnit': 'millisecond',
            'displayFormats': <String, Object?>{},
          },
          'ticks': <String, Object?>{
            'source': 'auto',
            'callback': false,
            'major': <String, Object?>{'enabled': false},
          },
        }),
      );
    });

    testWidgets('should correctly determine the unit', (tester) async {
      var date = _moment('Jan 01 1990', 'MMM dd yyyy');
      final data = <Object?>[];
      for (var i = 0; i < 60; i++) {
        data.add(<String, Object?>{'x': date, 'y': _random.nextDouble()});
        date = _add(date, 1, 'month');
      }

      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{'xAxisID': 'x', 'data': data},
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{
              'type': 'time',
              'ticks': <String, Object?>{'source': 'data', 'autoSkip': true},
            },
          },
        },
      });

      final scale = chart.scales['x']! as TimeScale;

      expect(scale.unit, jasmineEquals('month'));
    });

    group('when specifying limits', () {
      final mockData = <String, Object?>{
        'labels': <Object?>[
          '2015-01-01T20:00:00',
          '2015-01-02T20:00:00',
          '2015-01-03T20:00:00',
        ],
      };

      late Map<String, Object?> config;
      setUp(() {
        config = _cloneTimeDefaults();
        (config['ticks']! as Map<String, Object?>)['source'] = 'labels';
        (config['time']! as Map<String, Object?>)['unit'] = 'day';
      });

      testWidgets(
        'should use the min option when less than first label for building '
        'ticks',
        (tester) async {
          config['min'] = '2014-12-29T04:00:00';

          final labels = _getLabels(_createScale(mockData, config));
          expect(labels[0], equals('Jan 1'));
        },
      );

      testWidgets(
        'should use the min option when greater than first label for '
        'building ticks',
        (tester) async {
          config['min'] = '2015-01-02T04:00:00';

          final labels = _getLabels(_createScale(mockData, config));
          expect(labels[0], equals('Jan 2'));
        },
      );

      testWidgets(
        'should use the max option when greater than last label for building '
        'ticks',
        (tester) async {
          config['max'] = '2015-01-05T06:00:00';

          final labels = _getLabels(_createScale(mockData, config));
          expect(labels[labels.length - 1], equals('Jan 3'));
        },
      );

      testWidgets(
        'should use the max option when less than last label for building '
        'ticks',
        (tester) async {
          config['max'] = '2015-01-02T23:00:00';

          final labels = _getLabels(_createScale(mockData, config));
          expect(labels[labels.length - 1], equals('Jan 2'));
        },
      );
    });

    testWidgets('should use the isoWeekday option', (tester) async {
      final mockData = <String, Object?>{
        'labels': <Object?>[
          '2015-01-01T20:00:00', // Thursday
          '2015-01-02T20:00:00', // Friday
          '2015-01-03T20:00:00', // Saturday
        ],
      };

      final config =
          mergeIf(<String, Object?>{
                'bounds': 'ticks',
                'time': <String, Object?>{
                  'unit': 'week',
                  'isoWeekday': 3, // Wednesday
                },
              }, jsGet(jsGet(Chart.defaults, 'scales'), 'time'))!
              as Map<String, Object?>;

      final scale = _createScale(mockData, config);
      final ticks = _getLabels(scale);

      expect(ticks, equals(['Dec 31, 2014', 'Jan 7, 2015']));
    });

    group('when rendering several days', () {
      late Chart chart;
      late Scale scale;

      // The beforeEach acquires a chart: a local function that each case
      // calls first in its body.
      void beforeEach() {
        chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'xAxisID': 'x', 'data': <Object?>[]},
            ],
            'labels': <Object?>[
              '2015-01-01T20:00:00',
              '2015-01-02T21:00:00',
              '2015-01-03T22:00:00',
              '2015-01-05T23:00:00',
              '2015-01-07T03:00',
              '2015-01-08T10:00',
              '2015-01-10T12:00',
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'type': 'time', 'position': 'bottom'},
            },
          },
        });

        scale = chart.scales['x']!;
      }

      testWidgets('should be bounded by the nearest week beginnings', (
        tester,
      ) async {
        beforeEach();
        final labels = _labels(chart);
        expect(
          scale.getValueForPixel(scale.left),
          greaterThan(_startOf(_moment(labels[0]), 'week')),
        );
        expect(
          scale.getValueForPixel(scale.right),
          lessThan(
            _endOf(
              _add(_moment(labels[labels.length - 1]), 1, 'week'),
              'week',
            ),
          ),
        );
      });

      testWidgets('should convert between screen coordinates and times', (
        tester,
      ) async {
        beforeEach();
        final timeRange = scale.max - scale.min;
        final msPerPix = timeRange / scale.width;
        final labels = _labels(chart);
        final configLabels =
            jsGet(chart.config.data, 'labels')! as List<Object?>;
        final firstPointOffsetMs = _moment(configLabels[0]) - scale.min;
        final firstPointPixel = scale.left + firstPointOffsetMs / msPerPix;
        final lastPointOffsetMs =
            _moment(configLabels[configLabels.length - 1]) - scale.min;
        final lastPointPixel = scale.left + lastPointOffsetMs / msPerPix;

        expect(
          scale.getPixelForValue(_moment('2015-01-01T20:00:00')),
          toBeCloseToPixel(firstPointPixel),
        );
        expect(
          scale.getPixelForValue(_moment(labels[0])),
          toBeCloseToPixel(firstPointPixel),
        );
        expect(
          scale.getValueForPixel(firstPointPixel),
          _toBeCloseToTime(_moment(labels[0]), 'hour'),
        );

        expect(
          scale.getPixelForValue(_moment('2015-01-10T12:00')),
          toBeCloseToPixel(lastPointPixel),
        );
        expect(
          scale.getValueForPixel(lastPointPixel),
          _toBeCloseToTime(_moment(labels[6]), 'hour'),
        );
      });
    });

    group('when rendering several years', () {
      late Chart chart;
      late Scale scale;

      // The chart has no dataset. Its labels depend on the font that the
      // legend sets before the fit of the x scale (plugin.legend.js:143).
      // The beforeEach acquires a chart: a local function that each case
      // calls first in its body.
      void beforeEach() {
        chart = acquireChart(
          <String, Object?>{
            'type': 'line',
            'data': <String, Object?>{
              'labels': <Object?>['2005-07-04', '2017-01-20'],
            },
            'options': <String, Object?>{
              'scales': <String, Object?>{
                'x': <String, Object?>{
                  'type': 'time',
                  'bounds': 'ticks',
                  'position': 'bottom',
                },
              },
            },
          },
          <String, Object?>{
            'canvas': <String, Object?>{'width': 800, 'height': 200},
          },
        );

        scale = chart.scales['x']!;
      }

      testWidgets("should be bounded by nearest step's year start and end", (
        tester,
      ) async {
        beforeEach();
        final ticks = scale.getTicks()!;
        final step = ticks[1].value - ticks[0].value;
        final stepsAmount = ((scale.max - scale.min) / step).floorToDouble();

        expect(
          scale.getValueForPixel(scale.left),
          _toBeCloseToTime(_startOf(scale.min, 'year'), 'hour'),
        );
        expect(
          scale.getValueForPixel(scale.right),
          _toBeCloseToTime(
            _endOf(scale.min + step * stepsAmount, 'year'),
            'hour',
          ),
        );
      });

      testWidgets('should build the correct ticks', (tester) async {
        beforeEach();
        expect(
          _getLabels(scale),
          jasmineEquals(<Object?>[
            '2005',
            '2006',
            '2007',
            '2008',
            '2009',
            '2010',
            '2011',
            '2012',
            '2013',
            '2014',
            '2015',
            '2016',
            '2017',
            '2018',
          ]),
        );
      });

      testWidgets('should have ticks with accurate labels', (tester) async {
        beforeEach();
        final ticks = scale.getTicks()!;
        // pixelsPerTick is an approximation which assumes same number of
        // milliseconds per year (not true)
        // we use a threshold of 1 day so that we still match these values
        final pixelsPerTick = scale.width / (ticks.length - 1);

        for (var i = 0; i < ticks.length - 1; i++) {
          final offset = pixelsPerTick * i;
          expect(
            scale.getValueForPixel(scale.left + offset),
            _toBeCloseToTime(
              _moment(jsAdd(ticks[i].label, '-01-01')),
              'day',
              1,
            ),
          );
        }
      });
    });

    testWidgets('should get the correct label for a data value', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'xAxisID': 'x',
              'data': <Object?>[null, 10, 3],
            },
          ],
          'labels': <Object?>[
            '2015-01-01T20:00:00',
            '2015-01-02T21:00:00',
            '2015-01-03T22:00:00',
            '2015-01-05T23:00:00',
            '2015-01-07T03:00',
            '2015-01-08T10:00',
            '2015-01-10T12:00',
          ], // days
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{
              'type': 'time',
              'position': 'bottom',
              'ticks': <String, Object?>{'source': 'labels', 'autoSkip': false},
            },
          },
        },
      });

      final xScale = chart.scales['x']!;
      final controller = chart.getDatasetMeta(0).controller!;
      expect(
        jsTruthy(
          xScale.getLabelForValue(jsGet(controller.getParsed(0), xScale.id)),
        ),
        isTrue,
      );
      expect(
        xScale.getLabelForValue(jsGet(controller.getParsed(0), xScale.id)),
        'Jan 1, 2015, 8:00:00 pm',
      );
      expect(
        xScale.getLabelForValue(
          xScale.getValueForPixel(xScale.getPixelForTick(6)!),
        ),
        'Jan 10, 2015, 12:00:00 pm',
      );
    });

    group('when ticks.callback is specified', () {
      late Chart chart;
      late Scale scale;

      // The beforeEach acquires a chart: a local function that each case
      // calls first in its body.
      void beforeEach() {
        chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'xAxisID': 'x',
                'data': <Object?>[0, 0],
              },
            ],
            'labels': <Object?>['2015-01-01T20:00:00', '2015-01-01T20:01:00'],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{
                'type': 'time',
                'time': <String, Object?>{
                  'displayFormats': <String, Object?>{'second': 'h:mm:ss'},
                },
                'ticks': <String, Object?>{
                  'callback': (Object? _, Object? i) => '<${jsToString(i)}>',
                },
              },
            },
          },
        });
        scale = chart.scales['x']!;
      }

      testWidgets('should get the correct labels for ticks', (tester) async {
        beforeEach();
        final labels = _getLabels(scale);

        expect(labels.length, jasmineEquals(21));
        expect(labels[0], jasmineEquals('<0>'));
        expect(labels[labels.length - 1], jasmineEquals('<60>'));
      });

      testWidgets('should update ticks.callback correctly', (tester) async {
        beforeEach();
        String callback(Object? _, Object? i) => '{${jsToString(i)}}';
        (jsGet(_scaleOptionsX(chart), 'ticks')! as AnyObject)['callback'] =
            callback;
        chart.update();

        final labels = _getLabels(scale);
        expect(labels.length, jasmineEquals(21));
        expect(labels[0], jasmineEquals('{0}'));
        expect(labels[labels.length - 1], jasmineEquals('{60}'));
      });
    });

    testWidgets(
      'should get the correct label when time is specified as a string',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'xAxisID': 'x',
                'data': <Object?>[
                  <String, Object?>{'x': '2015-01-01T20:00:00', 'y': 10},
                  <String, Object?>{'x': '2015-01-02T21:00:00', 'y': 3},
                ],
              },
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'type': 'time', 'position': 'bottom'},
            },
          },
        });

        final xScale = chart.scales['x']!;
        final controller = chart.getDatasetMeta(0).controller!;
        final value = jsGet(controller.getParsed(0), xScale.id);
        expect(jsTruthy(xScale.getLabelForValue(value)), isTrue);
        expect(xScale.getLabelForValue(value), 'Jan 1, 2015, 8:00:00 pm');
      },
    );

    test(
      'should get the correct label for a data value by format',
      () {},
      skip: 'diverges: adapt-date-moment-format',
    );

    test(
      'should round to isoWeekday',
      () {},
      skip: 'diverges: adapt-date-moment-format',
    );

    testWidgets('should get the correct label for a timestamp', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'xAxisID': 'x',
              'data': <Object?>[
                // Normally (at least with the moment.js adapter), times would
                // be in the user's local time zone.  To allow for more stable
                // tests, our tests/index.js sets moment.js to use UTC; use `Z`
                // here to match.
                <String, Object?>{
                  't': _dateValue('2018-01-08 05:14:23.234Z'),
                  'y': 10,
                },
                <String, Object?>{
                  't': _dateValue('2018-01-09 06:17:43.426Z'),
                  'y': 3,
                },
              ],
            },
          ],
        },
        'options': <String, Object?>{
          'parsing': <String, Object?>{'xAxisKey': 't'},
          'scales': <String, Object?>{
            'x': <String, Object?>{'type': 'time', 'position': 'bottom'},
          },
        },
      });

      final xScale = chart.scales['x']!;
      final controller = chart.getDatasetMeta(0).controller!;
      final label = xScale.getLabelForValue(
        jsGet(controller.getParsed(0), xScale.id),
      );
      expect(label, jasmineEquals('Jan 8, 2018, 5:14:23 am'));
    });

    testWidgets(
      'should get the correct pixel for only one data in the dataset',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'labels': <Object?>['2016-05-27'],
            'datasets': <Object?>[
              <String, Object?>{
                'xAxisID': 'x',
                'data': <Object?>[5],
              },
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'display': true, 'type': 'time'},
            },
          },
        });

        final xScale = chart.scales['x']!;
        final pixel = xScale.getPixelForValue(_moment('2016-05-27'));

        expect(
          xScale.getValueForPixel(pixel),
          jasmineEquals(_moment(_labels(chart)[0])),
        );
      },
    );

    testWidgets('does not create a negative width chart when hidden', (
      tester,
    ) async {
      final chart = acquireChart(
        <String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': <Object?>[]},
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{
                'type': 'time',
                'ticks': <String, Object?>{
                  'min': _add(jsDateNow(), -1, 'months'),
                  'max': jsDateNow(),
                },
              },
            },
            'responsive': true,
          },
        },
        <String, Object?>{
          'wrapper': <String, Object?>{'style': 'display: none'},
        },
      );
      expect(chart.scales['y']!.width, jasmineEquals(0));
      expect(chart.scales['y']!.maxWidth, jasmineEquals(0));
      expect(chart.width, jasmineEquals(0));
    });

    group('when ticks.source', () {
      group('is "labels"', () {
        late Chart chart;

        // The beforeEach acquires a chart: a local function that each case
        // with a body calls first. `parser: 'YYYY'` is the moment format of
        // upstream. The cases with a body assert no value of that parse.
        void beforeEach() {
          chart = acquireChart(<String, Object?>{
            'type': 'line',
            'data': <String, Object?>{
              'labels': <Object?>['2017', '2019', '2020', '2025', '2042'],
              'datasets': <Object?>[
                <String, Object?>{
                  'data': <Object?>[0, 1, 2, 3, 4, 5],
                },
              ],
            },
            'options': <String, Object?>{
              'scales': <String, Object?>{
                'x': <String, Object?>{
                  'type': 'time',
                  'time': <String, Object?>{'parser': 'YYYY'},
                  'ticks': <String, Object?>{'source': 'labels'},
                },
              },
            },
          });
        }

        test(
          'should generate ticks from "data.labels"',
          () {},
          skip: 'diverges: adapt-date-moment-format',
        );

        test(
          'should not add ticks for min and max if they extend the labels '
          'range',
          () {},
          skip: 'diverges: adapt-date-moment-format',
        );

        test(
          'should not duplicate ticks if min and max are the labels limits',
          () {},
          skip: 'diverges: adapt-date-moment-format',
        );

        // The assertions read only `Date.now()` and an empty label list.
        // No asserted value comes from the parse with 'YYYY'.
        testWidgets(
          'should correctly handle empty `data.labels` using "day" if '
          '`time.unit` is undefined`',
          (tester) async {
            beforeEach();
            final scale = chart.scales['x']!;

            chart.data['labels'] = <Object?>[];
            chart.update();

            expect(
              scale.min,
              jasmineEquals(_startOf(jsDateNow(), 'day')),
            );
            expect(
              scale.max,
              jasmineEquals(_endOf(jsDateNow(), 'day') + 1),
            );
            expect(_getLabels(scale), jasmineEquals(<Object?>[]));
          },
        );

        testWidgets(
          'should correctly handle empty `data.labels` using `time.unit`',
          (tester) async {
            beforeEach();
            final scale = chart.scales['x']!;
            final options = _scaleOptionsX(chart);

            (jsGet(options, 'time')! as AnyObject)['unit'] = 'year';
            chart.data['labels'] = <Object?>[];
            chart.update();

            expect(
              scale.min,
              jasmineEquals(_startOf(jsDateNow(), 'year')),
            );
            expect(
              scale.max,
              jasmineEquals(_endOf(jsDateNow(), 'year') + 1),
            );
            expect(_getLabels(scale), jasmineEquals(<Object?>[]));
          },
        );
      });

      group('is "data"', () {
        late Chart chart;

        // The beforeEach acquires a chart: a local function that the case
        // with a body calls first.
        void beforeEach() {
          chart = acquireChart(<String, Object?>{
            'type': 'line',
            'data': <String, Object?>{
              'labels': <Object?>['2017', '2019', '2020', '2025', '2042'],
              'datasets': <Object?>[
                <String, Object?>{
                  'data': <Object?>[0, 1, 2, 3, 4, 5],
                },
                <String, Object?>{
                  'data': <Object?>[
                    <String, Object?>{'x': '2018', 'y': 6},
                    <String, Object?>{'x': '2020', 'y': 7},
                    <String, Object?>{'x': '2043', 'y': 8},
                  ],
                },
              ],
            },
            'options': <String, Object?>{
              'scales': <String, Object?>{
                'x': <String, Object?>{
                  'type': 'time',
                  'time': <String, Object?>{'parser': 'YYYY'},
                  'ticks': <String, Object?>{'source': 'data'},
                },
              },
            },
          });
        }

        test(
          'should generate ticks from "datasets.data"',
          () {},
          skip: 'diverges: adapt-date-moment-format',
        );

        test(
          'should not add ticks for min and max if they extend the labels '
          'range',
          () {},
          skip: 'diverges: adapt-date-moment-format',
        );

        test(
          'should not duplicate ticks if min and max are the labels limits',
          () {},
          skip: 'diverges: adapt-date-moment-format',
        );

        test(
          'should correctly handle empty `data.labels` using "day" if '
          '`time.unit` is undefined`',
          () {},
          skip: 'diverges: adapt-date-moment-format',
        );

        testWidgets(
          'should correctly handle empty `data.labels` and hidden datasets '
          'using `time.unit`',
          (tester) async {
            beforeEach();
            final scale = chart.scales['x']!;
            final options = _scaleOptionsX(chart);

            (jsGet(options, 'time')! as AnyObject)['unit'] = 'year';
            chart.data['labels'] = <Object?>[];
            chart.getDatasetMeta(1).hidden = true;
            chart.update();

            expect(
              scale.min,
              jasmineEquals(_startOf(jsDateNow(), 'year')),
            );
            expect(
              scale.max,
              jasmineEquals(_endOf(jsDateNow(), 'year') + 1),
            );
            expect(_getLabels(scale), jasmineEquals(<Object?>[]));
          },
        );
      });
    });

    for (final normalized in [true, false]) {
      group('when normalized is $normalized and scale type', () {
        group('is "timeseries"', () {
          test(
            'should space data out with the same gap, whatever their time '
            'values',
            () {},
            skip: 'diverges: adapt-date-moment-format',
          );

          test(
            'should add a step before if scale.min is before the first data',
            () {},
            skip: 'diverges: adapt-date-moment-format',
          );

          test(
            'should add a step after if scale.max is after the last data',
            () {},
            skip: 'diverges: adapt-date-moment-format',
          );

          test(
            'should add steps before and after if scale.min/max are outside '
            'the data range',
            () {},
            skip: 'diverges: adapt-date-moment-format',
          );
        });

        group('is "time"', () {
          test(
            'should space data out with a gap relative to their time values',
            () {},
            skip: 'diverges: adapt-date-moment-format',
          );

          test(
            'should take in account scale min and max if outside the ticks '
            'range',
            () {},
            skip: 'diverges: adapt-date-moment-format',
          );
        });
      });
    }

    group('when bounds', () {
      group('is "data"', () {
        test(
          'should preserve the data range',
          () {},
          skip: 'diverges: adapt-date-moment-format',
        );
      });

      group('is "labels"', () {
        test(
          'should preserve the label range',
          () {},
          skip: 'diverges: adapt-date-moment-format',
        );
      });
    });

    group('when min and/or max are defined', () {
      for (final source in ['auto', 'data', 'labels']) {
        for (final bounds in ['data', 'ticks']) {
          group('and ticks.source is "$source" and bounds "$bounds"', () {
            test(
              'should expand scale to the min/max range',
              () {},
              skip: 'diverges: adapt-date-moment-format',
            );

            test(
              'should shrink scale to the min/max range',
              () {},
              skip: 'diverges: adapt-date-moment-format',
            );
          });
        }
      }
    });

    for (final source in ['auto', 'data', 'labels']) {
      for (final type in ['timeseries', 'time']) {
        group('when ticks.source is "$source" and scale type is "$type"', () {
          test(
            'should not add offset from the edges',
            () {},
            skip: 'diverges: adapt-date-moment-format',
          );

          test(
            'should add offset from the edges if offset is true',
            () {},
            skip: 'diverges: adapt-date-moment-format',
          );

          test(
            'should not add offset if min and max extend the labels range',
            () {},
            skip: 'diverges: adapt-date-moment-format',
          );
        });
      }
    }

    testWidgets(
      'should handle offset when there are more data points than ticks',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[
                  <String, Object?>{'x': 631180800000, 'y': '31.84'},
                  <String, Object?>{'x': 631267200000, 'y': '30.89'},
                  <String, Object?>{'x': 631353600000, 'y': '33.00'},
                  <String, Object?>{'x': 631440000000, 'y': '33.52'},
                  <String, Object?>{'x': 631526400000, 'y': '32.24'},
                  <String, Object?>{'x': 631785600000, 'y': '32.74'},
                  <String, Object?>{'x': 631872000000, 'y': '31.45'},
                  <String, Object?>{'x': 631958400000, 'y': '32.60'},
                  <String, Object?>{'x': 632044800000, 'y': '31.77'},
                  <String, Object?>{'x': 632131200000, 'y': '32.45'},
                  <String, Object?>{'x': 632390400000, 'y': '31.13'},
                  <String, Object?>{'x': 632476800000, 'y': '31.82'},
                  <String, Object?>{'x': 632563200000, 'y': '30.81'},
                  <String, Object?>{'x': 632649600000, 'y': '30.07'},
                  <String, Object?>{'x': 632736000000, 'y': '29.31'},
                  <String, Object?>{'x': 632995200000, 'y': '29.82'},
                  <String, Object?>{'x': 633081600000, 'y': '30.20'},
                  <String, Object?>{'x': 633168000000, 'y': '30.78'},
                  <String, Object?>{'x': 633254400000, 'y': '30.72'},
                  <String, Object?>{'x': 633340800000, 'y': '31.62'},
                  <String, Object?>{'x': 633600000000, 'y': '30.64'},
                  <String, Object?>{'x': 633686400000, 'y': '32.36'},
                  <String, Object?>{'x': 633772800000, 'y': '34.66'},
                  <String, Object?>{'x': 633859200000, 'y': '33.96'},
                  <String, Object?>{'x': 633945600000, 'y': '34.20'},
                  <String, Object?>{'x': 634204800000, 'y': '32.20'},
                  <String, Object?>{'x': 634291200000, 'y': '32.44'},
                  <String, Object?>{'x': 634377600000, 'y': '32.72'},
                  <String, Object?>{'x': 634464000000, 'y': '32.95'},
                  <String, Object?>{'x': 634550400000, 'y': '32.95'},
                  <String, Object?>{'x': 634809600000, 'y': '30.88'},
                  <String, Object?>{'x': 634896000000, 'y': '29.44'},
                  <String, Object?>{'x': 634982400000, 'y': '29.36'},
                  <String, Object?>{'x': 635068800000, 'y': '28.84'},
                  <String, Object?>{'x': 635155200000, 'y': '30.85'},
                  <String, Object?>{'x': 635414400000, 'y': '32.00'},
                  <String, Object?>{'x': 635500800000, 'y': '32.74'},
                  <String, Object?>{'x': 635587200000, 'y': '33.16'},
                  <String, Object?>{'x': 635673600000, 'y': '34.73'},
                  <String, Object?>{'x': 635760000000, 'y': '32.89'},
                  <String, Object?>{'x': 636019200000, 'y': '32.41'},
                  <String, Object?>{'x': 636105600000, 'y': '31.15'},
                  <String, Object?>{'x': 636192000000, 'y': '30.63'},
                  <String, Object?>{'x': 636278400000, 'y': '29.60'},
                  <String, Object?>{'x': 636364800000, 'y': '29.31'},
                  <String, Object?>{'x': 636624000000, 'y': '29.83'},
                  <String, Object?>{'x': 636710400000, 'y': '27.97'},
                  <String, Object?>{'x': 636796800000, 'y': '26.18'},
                  <String, Object?>{'x': 636883200000, 'y': '26.06'},
                  <String, Object?>{'x': 636969600000, 'y': '26.34'},
                  <String, Object?>{'x': 637228800000, 'y': '27.75'},
                  <String, Object?>{'x': 637315200000, 'y': '29.05'},
                  <String, Object?>{'x': 637401600000, 'y': '28.82'},
                  <String, Object?>{'x': 637488000000, 'y': '29.43'},
                  <String, Object?>{'x': 637574400000, 'y': '29.53'},
                  <String, Object?>{'x': 637833600000, 'y': '28.50'},
                  <String, Object?>{'x': 637920000000, 'y': '28.87'},
                  <String, Object?>{'x': 638006400000, 'y': '28.11'},
                  <String, Object?>{'x': 638092800000, 'y': '27.79'},
                  <String, Object?>{'x': 638179200000, 'y': '28.18'},
                  <String, Object?>{'x': 638438400000, 'y': '28.27'},
                  <String, Object?>{'x': 638524800000, 'y': '28.29'},
                  <String, Object?>{'x': 638611200000, 'y': '29.63'},
                  <String, Object?>{'x': 638697600000, 'y': '29.13'},
                  <String, Object?>{'x': 638784000000, 'y': '26.57'},
                  <String, Object?>{'x': 639039600000, 'y': '27.19'},
                  <String, Object?>{'x': 639126000000, 'y': '27.48'},
                  <String, Object?>{'x': 639212400000, 'y': '27.79'},
                  <String, Object?>{'x': 639298800000, 'y': '28.48'},
                  <String, Object?>{'x': 639385200000, 'y': '27.88'},
                  <String, Object?>{'x': 639644400000, 'y': '25.63'},
                  <String, Object?>{'x': 639730800000, 'y': '25.02'},
                  <String, Object?>{'x': 639817200000, 'y': '25.26'},
                  <String, Object?>{'x': 639903600000, 'y': '25.00'},
                  <String, Object?>{'x': 639990000000, 'y': '26.23'},
                  <String, Object?>{'x': 640249200000, 'y': '26.22'},
                  <String, Object?>{'x': 640335600000, 'y': '26.36'},
                  <String, Object?>{'x': 640422000000, 'y': '25.45'},
                  <String, Object?>{'x': 640508400000, 'y': '24.62'},
                  <String, Object?>{'x': 640594800000, 'y': '26.65'},
                  <String, Object?>{'x': 640854000000, 'y': '26.28'},
                  <String, Object?>{'x': 640940400000, 'y': '27.25'},
                  <String, Object?>{'x': 641026800000, 'y': '25.93'},
                ],
                'backgroundColor': '#ff6666',
              },
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{
                'type': 'timeseries',
                'offset': true,
                'ticks': <String, Object?>{
                  'source': 'data',
                  'autoSkip': true,
                  'autoSkipPadding': 0,
                  'maxRotation': 0,
                },
              },
              'y': <String, Object?>{
                'type': 'linear',
                'border': <String, Object?>{'display': false},
              },
            },
          },
          'plugins': <String, Object?>{'legend': false},
        });
        final scale = chart.scales['x']!;
        expect(scale.getPixelForDecimal(0), toBeCloseToPixel(29));
        expect(scale.getPixelForDecimal(1), toBeCloseToPixel(512));
      },
    );

    for (final source in ['data', 'labels']) {
      for (final type in ['timeseries', 'time']) {
        group('when ticks.source is "$source" and scale type is "$type"', () {
          test(
            'should add offset if min and max extend the labels range and '
            'offset is true',
            () {},
            skip: 'diverges: adapt-date-moment-format',
          );
        });
      }
    }

    group('Deprecations', () {
      group('options.time.displayFormats', () {
        test(
          'should generate defaults from adapter presets',
          () {},
          skip: 'diverges: adapt-date-moment-format',
        );

        test(
          'should merge user formats with adapter presets',
          () {},
          skip: 'diverges: adapt-date-moment-format',
        );
      });
    });

    testWidgets('should pass chart options to date adapter', (tester) async {
      Object? chartOptions;

      DateAdapterBase.override(<String, Object?>{
        'init': (Object? options) {
          chartOptions = options;
        },
      });
      // Upstream keeps the member. The defaults restore does not cover
      // `DateAdapterBase.prototype`, and the default members have no
      // `init`. Thus the test removes the member at its end.
      addTearDown(() => DateAdapterBase.prototype.remove('init'));

      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{},
        'options': <String, Object?>{
          'locale': 'es',
          'scales': <String, Object?>{
            'x': <String, Object?>{'type': 'time'},
          },
        },
      });

      // `chart.options` is a resolver. When `equals` fails, its message
      // reads the nested resolvers of the expected value without end, and
      // the test process does not stop. Thus the test applies the same
      // `equals` with `matches`, and a failure shows only `false`. Upstream
      // and the port give `init` the resolver of `chart.options` itself
      // (scale.time.js:271, core.controller.js:367).
      expect(
        equals(chart.options).matches(chartOptions, <Object?, Object?>{}),
        isTrue,
        reason: 'chartOptions is not equal to chart.options',
      );
    });

    testWidgets('should pass timestamp to ticks callback', (tester) async {
      Object? callbackValue = undefined;
      acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'xAxisID': 'x',
              'data': <Object?>[0, 0],
            },
          ],
          'labels': <Object?>['2015-01-01T20:00:00', '2015-01-01T20:01:00'],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{
              'type': 'time',
              'ticks': <String, Object?>{
                'callback': (Object? value) {
                  callbackValue = value;
                  return value;
                },
              },
            },
          },
        },
      });

      expect(jsTypeof(callbackValue), 'number');
    });
  });
}
