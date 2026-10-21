// Original code, not ported from Chart.js: time scale reference tests.
@TestOn('vm')
library;

// The tests read the protected timestamp methods of the scale.
// ignore_for_file: invalid_use_of_protected_member

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart' show toBeCloseToPixel;
import 'package:flutter_chartjs/src/core/core.adapters.dart';
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/core/core.defaults.dart' show defaults;
import 'package:flutter_chartjs/src/core/core.registry.dart' show registry;
import 'package:flutter_chartjs/src/core/core.scale.dart';
import 'package:flutter_chartjs/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs/src/js/js_class.dart';
import 'package:flutter_chartjs/src/js/js_function.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/scales/scale.linear.dart';
import 'package:flutter_chartjs/src/scales/scale.time.dart';
import 'package:flutter_chartjs/src/scales/scale.timeseries.dart';
import 'package:flutter_chartjs/src/types/basic.dart';
import 'package:flutter_test/flutter_test.dart';

import 'scale_chart_harness.dart';
import 'scale_time_harness.dart';
import 'scale_time_reference.dart';

// The port-only tests of lib/src/scales/scale.time.dart.
//
// The reference group compares real charts with the charts of
// tool/reference/scale_time_reference.mjs: a build of the pinned Chart.js
// with chartjs-adapter-moment 1.0.1 on moment 2.29.4 in the zone 'Etc/UTC', in
// Node.js v24.12.0 on x64 (Chart.js ADR 0032, Chart.js ADR 0024), with a mock
// context that measures text in Liberation Sans 2.1.5, the test font of the
// harness (scale_chart_harness.dart, scale_time_harness.dart). Each chart
// comes from acquireChart in a testWidgets case (Chart.js ADR 0022), at the
// fixed time of `Date.now()` of the generator.
//
// The cartesian test controller `timeTest` has the time scale on the index
// axis and the linear scale on the value axis. lib/src/index.dart does not
// register the scales yet. Thus main() registers the time scale, the linear
// scale and the test controller through their class values, before the
// snapshot of the defaults restore (Chart.js ADR 0020, section 8, and
// Chart.js ADR 0022, section 8).
//
// The reference group also compares the times of each time scale exactly
// (expectExactTimes of scale_time_harness.dart): the tolerance of the
// harness accepts about 1.6 ms for a time of 2021. The case 'a parser format
// HH:mm' skips in a zone where the local date at the `Date.now()` of the
// generator is not its UTC date (_zoneSkips).
//
// The groups of Chart.js ADR 0025 pin the fast path of getDecimalForValue
// (section 3) and the relations of the value types (section 9). The groups
// adapt-time-generate-no-advance and adapt-time-null-timestamp pin the rows
// of differences.md. The group 'the throws of upstream' pins the errors of
// the upstream update for options that a reference case cannot hold.
//
// The group adapt-date-moment-format has the port-only twins of the 59 cases
// of test/specs/scale.time_test.dart that skip with the row
// adapt-date-moment-format of differences.md. A twin keeps the config and
// each assertion of its upstream case, with ICU patterns in place of the
// moment tokens.

/// The cartesian test controller `timeTest` of the generator: time on the
/// index axis and linear on the value axis.
final JsClass _timeTestController = cartesianTestController('timeTest', {
  'scales': <String, Object?>{
    '_index_': <String, Object?>{'type': 'time'},
    '_value_': <String, Object?>{'type': 'linear'},
  },
});

/// The named functions of the configs of the generator.
final Map<String, Object?> _functions = {
  // `(value, index) => 'T' + index`.
  'tickIndex': (Object? value, Object? index) => 'T${jsToString(index)}',
  // `index % 2 ? '' : this.format(value, 'HH:mm')`.
  'hourOrEmpty': JsFunction(
    (Object? self, Object? value, Object? index) =>
        jsTruthy(jsToNumber(index) % 2)
        ? ''
        : (self! as TimeScale).format(value, 'HH:mm'),
  ),
  // `(value) => value * 1000`.
  'seconds': (Object? value) => jsToNumber(value) * 1000,
  // `(value) => String(value)`.
  'valueString': jsToString,
};

/// The case of the generator whose times depend on the local date of the
/// process.
const String _localDateCase = 'a parser format HH:mm';

/// The cases that skip in the zone of the machine, with the reason.
///
/// A parse with a pattern that has no date takes the date of `Date.now()`
/// in the local zone of the process: the moment rule `currentDateArray`
/// (Chart.js ADR 0024, section 5, and `parseWithFormat` of date_parse.dart).
/// The generator runs with TZ=UTC. Thus the case [_localDateCase] gives the
/// reference times only where the local date at the `Date.now()` of the
/// generator is its UTC date. For 2021-06-15T12:34:56.789Z, these are the
/// offsets from UTC-12:34 to UTC+11:25.
Map<String, String> _zoneSkips() {
  final now = scaleTimeReferenceNow.toInt();
  final local = DateTime.fromMillisecondsSinceEpoch(now);
  final utc = DateTime.fromMillisecondsSinceEpoch(now, isUtc: true);
  if (local.year == utc.year &&
      local.month == utc.month &&
      local.day == utc.day) {
    return const {};
  }
  return {
    _localDateCase:
        'n/a: the local date at Date.now() of the generator is not its UTC '
        'date',
  };
}

/// The set-up of each case of the generator that changes the adapter, by
/// the case name. The test restores the adapter at its end.
final Map<String, void Function()> _setUps = {
  'an adapter add that gives NaN': () {
    final add = DateAdapterBase.prototype['add'];
    DateAdapterBase.override({
      'add': (Object? time, Object? amount, Object? unit) => double.nan,
    });
    addTearDown(() => DateAdapterBase.prototype['add'] = add);
  },
};

/// One day in ms.
const double _day = 86400000;

/// Monday 2021-01-04T00:00:00Z.
final double _t0 = DateTime.utc(2021, 1, 4).millisecondsSinceEpoch.toDouble();

/// `{x, y}` points at the times [times].
List<Object?> _xy(List<double> times) => [
  for (var i = 0; i < times.length; i++)
    <String, Object?>{'x': times[i], 'y': ((i * 37) % 11).toDouble()},
];

/// A chart of the test controller with the data [data] and the options of
/// the scale x [x].
Chart _chart(List<Object?> data, [AnyObject? x]) => acquireChart({
  'type': 'timeTest',
  'data': <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{'data': data},
    ],
  },
  'options': <String, Object?>{
    'scales': <String, Object?>{'x': ?x},
  },
});

/// The time scale `x` of [chart].
TimeScale _x(Chart chart) => chart.scales['x']! as TimeScale;

/// A matcher of [value]: [isNaN] for NaN, else [equals].
Matcher _same(double value) => value.isNaN ? isNaN : equals(value);

/// `moment(value).valueOf()` and `+moment(value, format)` of
/// scale.time.tests.js: the parse of the default adapter, with an ICU
/// pattern in place of the moment format.
double _ms(String value, [String? format]) =>
    jsToNumber(DateAdapterBase().parse(value, format ?? undefined));

/// scale.time.tests.js:27-29 `getLabels(scale)`.
List<Object?> _getLabels(Scale scale) => [
  for (final tick in scale.ticks!) tick.label,
];

/// `chart.options.scales.x` of scale.time.tests.js. A write goes into the
/// config of the scale x.
Map<String, Object?> _scaleOptions(Chart chart) =>
    jsGet(chart.options['scales'], 'x')! as Map<String, Object?>;

/// `options.time.displayFormats` of scale.time.tests.js, as Jasmine
/// `toEqual` reads it: the keys of `Object.keys` (`jsObjectKeys`) and their
/// values.
///
/// For a resolver, `Object.keys` gives the keys of its first scope. The
/// `Map.keys` of a resolver give the keys of all its scopes, also the keys
/// of `defaults.scale`. Thus `equals` on the resolver fails, and the text of
/// its mismatch reads the nested resolvers without end.
Map<String, Object?> _displayFormats(Object? options) {
  final formats =
      jsGet(jsGet(options, 'time'), 'displayFormats')! as Map<String, Object?>;
  return {for (final key in jsObjectKeys(formats)) key: formats[key]};
}

/// A twin of a spec case that makes a chart of the type `line` with a
/// dataset: a `testWidgets` case with the line controller of phase 7.
void _lineTwin(String name, void Function() body) =>
    testWidgets(name, (tester) async => body());

void main() {
  // Before the snapshot of the defaults restore (Chart.js ADR 0022, section
  // 8). The restore does not reset the items of the registry.
  Chart.register([
    TimeScale.jsClass,
    LinearScale.jsClass,
    _timeTestController,
  ]);

  testReferenceOrigin(
    node: scaleTimeReferenceNode,
    arch: scaleTimeReferenceArch,
    dist: scaleTimeReferenceDist,
    commit: scaleTimeReferenceCommit,
  );
  testAdapterOrigin(scaleTimeReferenceAdapter);

  group('the class value (Chart.js ADR 0020)', () {
    test('the registry gives the class value of the id time', () {
      expect(registry.getScale('time'), same(TimeScale.jsClass));
      expect(TimeScale.jsClass['id'], 'time');
      expect(TimeScale.jsClass['defaults'], same(TimeScale.defaults));
      expect(TimeScale.jsClass.superclass, same(Scale.jsClass));
    });

    test('defaults.scales.time has the static defaults', () {
      final scales = defaults['scales']! as Map<String, Object?>;
      final time = scales['time']! as Map<String, Object?>;
      expect(time.keys, ['bounds', 'adapters', 'time', 'ticks']);
      expect(time['bounds'], 'data');
      expect(time['time'], {
        'parser': false,
        'unit': false,
        'round': false,
        'isoWeekday': false,
        'minUnit': 'millisecond',
        'displayFormats': <String, Object?>{},
      });
      expect(time['ticks'], {
        'source': 'auto',
        'callback': false,
        'major': {'enabled': false},
      });
    });

    test('the timeseries scale shares the defaults Map', () {
      expect(TimeSeriesScale.defaults, same(TimeScale.defaults));
      expect(TimeSeriesScale.jsClass.superclass, same(TimeScale.jsClass));
    });
  });

  group('time scale charts against upstream', () {
    test('each set-up and the case of the local date name a case', () {
      final names = [for (final c in scaleTimeReference) c.name];
      expect(_setUps.keys, everyElement(isIn(names)));
      expect(names, contains(_localDateCase));
    });

    testTimeScaleCases(
      scaleTimeReference,
      now: scaleTimeReferenceNow,
      functions: _functions,
      setUps: _setUps,
      skips: _zoneSkips(),
    );
  });

  group('fast path (Chart.js ADR 0025)', () {
    testWidgets('a double and an int give the same decimal', (tester) async {
      final x = _x(_chart(_xy([_t0, _t0 + 3 * _day, _t0 + 10 * _day])));
      final min = x.min;
      final max = x.max;
      expect((min, max), (_t0, _t0 + 10 * _day));
      for (final value in [
        0.0,
        -0.0,
        double.nan,
        double.infinity,
        double.negativeInfinity,
        min,
        max,
        (min + max) / 2,
        min - 1,
        max + 1,
        1.0,
        2.0,
        1e15,
      ]) {
        final decimal = x.getDecimalForValue(value);
        expect(
          decimal,
          _same((value - min) / (max - min)),
          reason: jsNumberToString(value),
        );
        if (value.isFinite && value == value.truncateToDouble()) {
          expect(
            x.getDecimalForValue(value.toInt()),
            _same(decimal),
            reason: '${value.toInt()} as an int',
          );
        }
      }
    });
  });

  group('value types (Chart.js ADR 0025)', () {
    testWidgets('null and undefined give NaN', (tester) async {
      final x = _x(_chart(_xy([_t0, _t0 + _day])));
      expect(x.getDecimalForValue(null), isNaN);
      expect(x.getPixelForValue(null), isNaN);
      expect(x.getDecimalForValue(undefined), isNaN);
      expect(x.getPixelForValue(undefined), isNaN);
    });

    testWidgets('a numeric string equals its number', (tester) async {
      final x = _x(_chart(_xy([_t0, _t0 + _day])));
      final value = _t0 + _day / 3;
      expect(
        x.getDecimalForValue(jsNumberToString(value)),
        x.getDecimalForValue(value),
      );
      expect(
        x.getPixelForValue(jsNumberToString(value)),
        x.getPixelForValue(value),
      );
    });

    testWidgets('a DateTime x is a JS Date: its time value', (tester) async {
      final chart = _chart([
        <String, Object?>{'x': DateTime.utc(2021, 1, 4), 'y': 1.0},
        <String, Object?>{'x': DateTime.utc(2021, 1, 6, 12), 'y': 2.0},
      ]);
      final x = _x(chart);
      expect((x.min, x.max), (_t0, _t0 + 2.5 * _day));
      final points = chart.getDatasetMeta(0).data;
      expect(points[0].x, x.getPixelForValue(_t0));
      expect(points[1].x, x.getPixelForValue(_t0 + 2.5 * _day));
    });
  });

  // differences.md row adapt-time-generate-no-advance. Upstream loops
  // without end for these steps. The reference case 'an adapter add that
  // gives NaN' pins the end of the loop at a NaN step.
  group('adapt-time-generate-no-advance', () {
    /// The chart of the times [times] with the unit [unit] and the step
    /// [stepSize].
    Chart stepChart(List<double> times, String unit, Object? stepSize) =>
        _chart(_xy(times), {
          'time': <String, Object?>{'unit': unit},
          'ticks': <String, Object?>{'stepSize': stepSize},
        });

    for (final (unit, stepSize, times) in [
      ('day', 0.4, [_t0, _t0 + 5 * _day]),
      ('month', 0.4, [_t0, _t0 + 90 * _day]),
      ('millisecond', 0.5, [_t0 + 0.5, _t0 + 20]),
      ('hour', 0.0, [_t0 + 60000, _t0 + 120000]),
      ('day', double.nan, [_t0, _t0 + 5 * _day]),
    ]) {
      testWidgets('the step $stepSize $unit throws a StateError', (
        tester,
      ) async {
        expect(
          () => stepChart(times, unit, stepSize),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              endsWith(
                'the step of ${jsToString(stepSize)} $unit does not advance',
              ),
            ),
          ),
        );
      });
    }

    testWidgets('a step that advances gives the ticks of the unit', (
      tester,
    ) async {
      final x = _x(stepChart([_t0, _t0 + 4 * _day], 'day', 1.5));
      expect(
        [for (final tick in x.ticks!) tick.value],
        [_t0, _t0 + 2 * _day, _t0 + 4 * _day],
      );
    });

    testWidgets('a range of more than 100000 steps throws the upstream '
        'error', (tester) async {
      expect(
        () => stepChart([_t0, _t0 + 200001], 'millisecond', 2.0),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            '${jsNumberToString(_t0)} and ${jsNumberToString(_t0 + 200001)} '
                'are too far apart with stepSize of 2 millisecond',
          ),
        ),
      );
    });
  });

  // The throws of the upstream update for options that the reference cases
  // cannot hold. The Node.js probe gave each result with a build of the
  // pinned Chart.js and chartjs-adapter-moment 1.0.1.
  group('the throws of upstream', () {
    final times = [_t0, _t0 + 5 * _day];

    testWidgets('a minUnit that is not a unit throws a TypeError', (
      tester,
    ) async {
      // INTERVALS[UNITS[-1]].steps (scale.time.js:90-92): "Cannot read
      // properties of undefined (reading 'steps')".
      expect(
        () => _chart(_xy(times), {
          'time': <String, Object?>{'minUnit': 'days'},
        }),
        throwsA(isA<TypeError>()),
      );
    });

    for (final time in [false, null]) {
      testWidgets('the time option $time throws a TypeError', (tester) async {
        // init writes `scaleOpts.time = {}` (scale.time.js:267). The new
        // object has no displayFormats: "Cannot read properties of
        // undefined (reading 'undefined')" (scale.time.js:615).
        expect(
          () => _chart(_xy(times), {'time': time}),
          throwsA(isA<TypeError>()),
        );
      });
    }

    for (final (stepSize, text) in [(null, 'null'), (-1.0, '-1')]) {
      testWidgets('the stepSize $text throws the upstream error', (
        tester,
      ) async {
        // 100000 * stepSize is 0 or negative (scale.time.js:474-476).
        expect(
          () => _chart(_xy(times), {
            'time': <String, Object?>{'unit': 'day'},
            'ticks': <String, Object?>{'stepSize': stepSize},
          }),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              '1609718400000 and 1610150400000 are too far apart with '
                  'stepSize of $text day',
            ),
          ),
        );
      });
    }
  });

  // differences.md row adapt-time-null-timestamp. Upstream keeps the JS
  // null timestamp of a label that does not parse. The reference case 'a
  // label that does not parse' gives the upstream results where the port
  // keeps null.
  group('adapt-time-null-timestamp', () {
    /// The chart of the labels A, garbage and B with the options of the
    /// scale x [x].
    Chart labelsChart(AnyObject x) => acquireChart({
      'type': 'timeTest',
      'data': <String, Object?>{
        'labels': <Object?>['2021-01-04', 'garbage', '2021-01-20'],
        'datasets': <Object?>[
          <String, Object?>{
            'data': <Object?>[1.0, 2.0, 3.0],
          },
        ],
      },
      'options': <String, Object?>{
        'scales': <String, Object?>{'x': x},
      },
    });

    testWidgets('the label timestamps keep null and sort it as 0', (
      tester,
    ) async {
      final x = _x(labelsChart({}));
      expect(x.getLabelTimestamps(), [
        null,
        _t0,
        _t0 + 16 * _day,
      ]);
      // Math.min(min, null) is Math.min(min, 0).
      expect(x.min, 0);
    });

    testWidgets('a null tick of the labels has the value NaN', (
      tester,
    ) async {
      final x = _x(
        labelsChart({
          'ticks': <String, Object?>{'source': 'labels'},
        }),
      );
      final ticks = x.ticks!;
      // Upstream gives the tick value null. The scale reads the value of the
      // tick back as null: the adapter formats null as an invalid date, and
      // getDecimalForValue gives NaN for null.
      expect(ticks.first.value, isNaN);
      expect(ticks.first.label, 'Invalid date');
      expect(x.getPixelForTick(0), isNaN);
      expect(
        [for (final tick in ticks.skip(1)) tick.value],
        [
          _t0,
          _t0 + 16 * _day,
        ],
      );
    });

    testWidgets('the tick callback gets null for a null tick', (tester) async {
      final values = <Object?>[];
      final x = _x(
        labelsChart({
          'ticks': <String, Object?>{
            'source': 'labels',
            'callback': (Object? value) {
              values.add(value);
              return jsToString(value);
            },
          },
        }),
      );
      expect(values, contains(null));
      expect(values, everyElement(isNot(isNaN)));
      expect(x.ticks!.first.label, 'null');
    });

    testWidgets('afterAutoSkip reads a null tick value as 0', (tester) async {
      final x = _x(
        labelsChart({
          'offset': true,
          'offsetAfterAutoskip': true,
          'ticks': <String, Object?>{'source': 'labels'},
        }),
      );
      // `+tick.value` is `+null`, 0 (scale.time.js:405). Thus the offsets
      // and the pixels stay finite.
      final (:start, :end, :factor) = x.offsets;
      expect([start, end, factor], everyElement(isNotNaN));
      expect(x.getPixelForValue(_t0), isNotNaN);
    });

    testWidgets('a null bound of bounds ticks is 0', (tester) async {
      final x = _x(
        labelsChart({
          'bounds': 'ticks',
          'ticks': <String, Object?>{'source': 'labels'},
        }),
      );
      // Upstream gives min the value null, which the arithmetic reads as 0.
      expect(x.min, 0);
      expect(x.max, _t0 + 16 * _day);
    });
  });

  group('the timestamp caches', () {
    testWidgets('getDataTimestamps gives the List of the cache', (
      tester,
    ) async {
      final x = _x(_chart(_xy([_t0 + _day, _t0, _t0 + _day])));
      final data = x.getDataTimestamps();
      expect(data, [_t0, _t0 + _day]);
      expect(x.getDataTimestamps(), same(data));
      expect(x.cache['data'], same(data));
    });

    testWidgets('beforeLayout clears the caches', (tester) async {
      final x = _x(_chart(_xy([_t0, _t0 + _day])))..beforeLayout();
      expect(x.cache, {
        'data': <double>[],
        'labels': <double?>[],
        'all': <double?>[],
      });
    });
  });

  group('the date adapter', () {
    testWidgets('init gives the chart options to the adapter, and the '
        'scale gets a new adapter in each update', (tester) async {
      final options = <Object?>[];
      DateAdapterBase.override({
        'init': options.add,
      });
      addTearDown(() => DateAdapterBase.prototype.remove('init'));
      final chart = _chart(_xy([_t0, _t0 + _day]));
      final first = _x(chart).adapter;
      expect(options, isNotEmpty);
      // Not `same(chart.options)`: the text of a failed matcher reads the
      // nested resolvers without end (see _displayFormats).
      expect(
        identical(options.last, chart.options),
        isTrue,
        reason: 'init gets chart.options',
      );
      chart.update();
      expect(_x(chart).adapter, isNot(same(first)));
    });

    testWidgets('the display formats of the adapter fill the options', (
      tester,
    ) async {
      final x = _x(
        _chart(_xy([_t0, _t0 + _day]), {
          'time': <String, Object?>{
            'displayFormats': <String, Object?>{'day': 'MMM'},
          },
        }),
      );
      final time = x.options['time']! as Map<String, Object?>;
      final formats = time['displayFormats']! as Map<String, Object?>;
      expect(formats['day'], 'MMM');
      expect(formats['hour'], 'ha');
      expect(formats['datetime'], 'MMM d, yyyy, h:mm:ss a');
    });

    testWidgets('mergeIf writes the formats into the scale config and not '
        'into the defaults', (tester) async {
      // The Node.js probe of the review: after the chart, the merged config
      // of the scale x has the ten formats of the adapter, and
      // `defaults.scales.time.time.displayFormats` stays `{}`
      // (scale.time.js:277, helpers.config.ts:101-106, :373-386).
      final chart = _chart(_xy([_t0, _t0 + _day]));
      final scales = chart.config.options['scales']! as Map<String, Object?>;
      final x = scales['x']! as Map<String, Object?>;
      final time = x['time']! as Map<String, Object?>;
      final formats = time['displayFormats']! as Map<String, Object?>;
      expect(formats.keys, [
        'datetime',
        'millisecond',
        'second',
        'minute',
        'hour',
        'day',
        'week',
        'month',
        'quarter',
        'year',
      ]);
      final defaultScales = defaults['scales']! as Map<String, Object?>;
      final defaultTime =
          (defaultScales['time']! as Map<String, Object?>)['time']!
              as Map<String, Object?>;
      expect(defaultTime['displayFormats'], isEmpty);
    });
  });

  // differences.md row adapt-date-moment-format. The port-only twins of the
  // 59 cases of test/specs/scale.time_test.dart that skip with this row
  // (dates-impl section 5). A twin has the name, the config and each
  // assertion of its upstream case, with ICU patterns in place of the moment
  // tokens: 'YYYY' is 'yyyy', 'MM/DD HH:mm' is 'MM/dd HH:mm', 'YYYY-MM-DD'
  // is 'yyyy-MM-dd' and 'YYYY-MM' is 'yyyy-MM'. `moment(x).valueOf()` and
  // `+moment(x, f)` are `_ms(x)` and `_ms(x, f)`. The groups follow the
  // `describe` blocks of scale.time.tests.js. A `beforeEach` that makes a
  // chart is a local function that each twin calls first (Chart.js ADR
  // 0022, section 2).
  //
  // Each twin with a dataset needs the line controller: it is a
  // `testWidgets` case of _lineTwin. The two twins of 'Deprecations' have no
  // dataset.
  group('adapt-date-moment-format', () {
    _lineTwin('should get the correct label for a data value by format', () {
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
              'time': <String, Object?>{
                'unit': 'day',
                'displayFormats': <String, Object?>{'day': 'yyyy-MM-dd'},
              },
              'position': 'bottom',
              'ticks': <String, Object?>{
                'source': 'labels',
                'autoSkip': false,
              },
            },
          },
        },
      });

      final xScale = _x(chart);
      final labels = chart.data['labels']! as List<Object?>;
      for (final lbl in labels) {
        final dd = xScale.adapter.parse(lbl);
        final parsed = (lbl! as String).split('T');
        expect(xScale.format(dd), parsed[0]);
      }
      for (final lbl in labels) {
        final mm = xScale.adapter.parse(lbl);
        final yearMonth = (lbl! as String).substring(0, 7);
        expect(xScale.format(mm, 'yyyy-MM'), yearMonth);
      }
    });

    // The moment token 'WW' (the ISO week number) has no ICU pattern. Thus
    // the twin has no display format, and it asserts the tick values: the
    // Mondays of the ISO weeks 15 and 16 of 2020, the labels '15' and '16'
    // of upstream.
    _lineTwin('should round to isoWeekday', () {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[
                <String, Object?>{'x': '2020-04-12T20:00:00', 'y': 1},
                <String, Object?>{'x': '2020-04-13T20:00:00', 'y': 2},
              ],
            },
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{
              'type': 'time',
              'ticks': <String, Object?>{'source': 'data'},
              'time': <String, Object?>{
                'unit': 'week',
                'round': 'week',
                'isoWeekday': 1,
              },
            },
          },
        },
      });

      expect(
        [for (final tick in _x(chart).ticks!) tick.value],
        [_ms('2020-04-06'), _ms('2020-04-13')],
      );
    });

    group('when ticks.source', () {
      group('is "labels"', () {
        /// scale.time.tests.js:584-601 `beforeEach`.
        Chart labelsChart() => acquireChart(<String, Object?>{
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
                'time': <String, Object?>{'parser': 'yyyy'},
                'ticks': <String, Object?>{'source': 'labels'},
              },
            },
          },
        });

        _lineTwin('should generate ticks from "data.labels"', () {
          final scale = labelsChart().scales['x']!;

          expect(scale.min, _ms('2017', 'yyyy'));
          expect(scale.max, _ms('2042', 'yyyy'));
          expect(_getLabels(scale), ['2017', '2019', '2020', '2025', '2042']);
        });

        _lineTwin(
          'should not add ticks for min and max if they extend the labels '
          'range',
          () {
            final chart = labelsChart();
            final scale = chart.scales['x']!;
            final options = _scaleOptions(chart);

            options['min'] = '2012';
            options['max'] = '2051';
            chart.update();

            expect(scale.min, _ms('2012', 'yyyy'));
            expect(scale.max, _ms('2051', 'yyyy'));
            expect(_getLabels(scale), [
              '2017',
              '2019',
              '2020',
              '2025',
              '2042',
            ]);
          },
        );

        _lineTwin(
          'should not duplicate ticks if min and max are the labels limits',
          () {
            final chart = labelsChart();
            final scale = chart.scales['x']!;
            final options = _scaleOptions(chart);

            options['min'] = '2017';
            options['max'] = '2042';
            chart.update();

            expect(scale.min, _ms('2017', 'yyyy'));
            expect(scale.max, _ms('2042', 'yyyy'));
            expect(_getLabels(scale), [
              '2017',
              '2019',
              '2020',
              '2025',
              '2042',
            ]);
          },
        );
      });

      group('is "data"', () {
        /// scale.time.tests.js:668-694 `beforeEach`.
        Chart dataChart() => acquireChart(<String, Object?>{
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
                'time': <String, Object?>{'parser': 'yyyy'},
                'ticks': <String, Object?>{'source': 'data'},
              },
            },
          },
        });

        _lineTwin('should generate ticks from "datasets.data"', () {
          final scale = dataChart().scales['x']!;

          expect(scale.min, _ms('2017', 'yyyy'));
          expect(scale.max, _ms('2043', 'yyyy'));
          expect(_getLabels(scale), [
            '2017',
            '2018',
            '2019',
            '2020',
            '2025',
            '2042',
            '2043',
          ]);
        });

        _lineTwin(
          'should not add ticks for min and max if they extend the labels '
          'range',
          () {
            final chart = dataChart();
            final scale = chart.scales['x']!;
            final options = _scaleOptions(chart);

            options['min'] = '2012';
            options['max'] = '2051';
            chart.update();

            expect(scale.min, _ms('2012', 'yyyy'));
            expect(scale.max, _ms('2051', 'yyyy'));
            expect(_getLabels(scale), [
              '2017',
              '2018',
              '2019',
              '2020',
              '2025',
              '2042',
              '2043',
            ]);
          },
        );

        _lineTwin(
          'should not duplicate ticks if min and max are the labels limits',
          () {
            final chart = dataChart();
            final scale = chart.scales['x']!;
            final options = _scaleOptions(chart);

            options['min'] = '2017';
            options['max'] = '2043';
            chart.update();

            expect(scale.min, _ms('2017', 'yyyy'));
            expect(scale.max, _ms('2043', 'yyyy'));
            expect(_getLabels(scale), [
              '2017',
              '2018',
              '2019',
              '2020',
              '2025',
              '2042',
              '2043',
            ]);
          },
        );

        _lineTwin(
          'should correctly handle empty `data.labels` using "day" if '
          '`time.unit` is undefined`',
          () {
            final chart = dataChart();
            final scale = chart.scales['x']!;

            chart.data['labels'] = <Object?>[];
            chart.update();

            expect(scale.min, _ms('2018', 'yyyy'));
            expect(scale.max, _ms('2043', 'yyyy'));
            expect(_getLabels(scale), ['2018', '2020', '2043']);
          },
        );
      });
    });

    for (final normalized in [true, false]) {
      group('when normalized is $normalized and scale type', () {
        group('is "timeseries"', () {
          /// scale.time.tests.js:765-790 `beforeEach`.
          Chart seriesChart() => acquireChart(<String, Object?>{
            'type': 'line',
            'data': <String, Object?>{
              'labels': <Object?>['2017', '2019', '2020', '2025', '2042'],
              'datasets': <Object?>[
                <String, Object?>{
                  'data': <Object?>[0, 1, 2, 3, 4],
                },
              ],
            },
            'options': <String, Object?>{
              'normalized': normalized,
              'scales': <String, Object?>{
                'x': <String, Object?>{
                  'type': 'timeseries',
                  'time': <String, Object?>{'parser': 'yyyy'},
                  'ticks': <String, Object?>{'source': 'labels'},
                },
                'y': <String, Object?>{'display': false},
              },
            },
          });

          _lineTwin(
            'should space data out with the same gap, whatever their time '
            'values',
            () {
              final scale = seriesChart().scales['x']!;
              final start = scale.left;
              final slice = scale.width / 4;

              expect(
                scale.getPixelForValue(_ms('2017'), 0),
                toBeCloseToPixel(start),
              );
              expect(
                scale.getPixelForValue(_ms('2019'), 1),
                toBeCloseToPixel(start + slice),
              );
              expect(
                scale.getPixelForValue(_ms('2020'), 2),
                toBeCloseToPixel(start + slice * 2),
              );
              expect(
                scale.getPixelForValue(_ms('2025'), 3),
                toBeCloseToPixel(start + slice * 3),
              );
              expect(
                scale.getPixelForValue(_ms('2042'), 4),
                toBeCloseToPixel(start + slice * 4),
              );
            },
          );

          _lineTwin(
            'should add a step before if scale.min is before the first data',
            () {
              final chart = seriesChart();
              final scale = chart.scales['x']!;
              final options = _scaleOptions(chart);

              options['min'] = '2012';
              chart.update();

              final start = scale.left;
              final slice = scale.width / 5;

              expect(
                scale.getPixelForValue(_ms('2017'), 1),
                toBeCloseToPixel(86),
              );
              expect(
                scale.getPixelForValue(_ms('2042'), 5),
                toBeCloseToPixel(start + slice * 5),
              );
            },
          );

          _lineTwin(
            'should add a step after if scale.max is after the last data',
            () {
              final chart = seriesChart();
              final scale = chart.scales['x']!;
              final options = _scaleOptions(chart);

              options['max'] = '2050';
              chart.update();

              final start = scale.left;

              expect(
                scale.getPixelForValue(_ms('2017'), 0),
                toBeCloseToPixel(start),
              );
              expect(
                scale.getPixelForValue(_ms('2042'), 4),
                toBeCloseToPixel(388),
              );
            },
          );

          _lineTwin(
            'should add steps before and after if scale.min/max are outside '
            'the data range',
            () {
              final chart = seriesChart();
              final scale = chart.scales['x']!;
              final options = _scaleOptions(chart);

              options['min'] = '2012';
              options['max'] = '2050';
              chart.update();

              expect(
                scale.getPixelForValue(_ms('2017'), 1),
                toBeCloseToPixel(71),
              );
              expect(
                scale.getPixelForValue(_ms('2042'), 5),
                toBeCloseToPixel(401),
              );
            },
          );
        });

        group('is "time"', () {
          /// scale.time.tests.js:842-866 `beforeEach`.
          Chart timeChart() => acquireChart(<String, Object?>{
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
                  'time': <String, Object?>{'parser': 'yyyy'},
                  'ticks': <String, Object?>{'source': 'labels'},
                },
                'y': <String, Object?>{'display': false},
              },
            },
          });

          _lineTwin(
            'should space data out with a gap relative to their time values',
            () {
              final scale = timeChart().scales['x']!;
              final start = scale.left;
              final slice = scale.width / (2042 - 2017);

              expect(
                scale.getPixelForValue(_ms('2017'), 0),
                toBeCloseToPixel(start),
              );
              expect(
                scale.getPixelForValue(_ms('2019'), 1),
                toBeCloseToPixel(start + slice * (2019 - 2017)),
              );
              expect(
                scale.getPixelForValue(_ms('2020'), 2),
                toBeCloseToPixel(start + slice * (2020 - 2017)),
              );
              expect(
                scale.getPixelForValue(_ms('2025'), 3),
                toBeCloseToPixel(start + slice * (2025 - 2017)),
              );
              expect(
                scale.getPixelForValue(_ms('2042'), 4),
                toBeCloseToPixel(start + slice * (2042 - 2017)),
              );
            },
          );

          _lineTwin(
            'should take in account scale min and max if outside the ticks '
            'range',
            () {
              final chart = timeChart();
              final scale = chart.scales['x']!;
              final options = _scaleOptions(chart);

              options['min'] = '2012';
              options['max'] = '2050';
              chart.update();

              final start = scale.left;
              final slice = scale.width / (2050 - 2012);

              expect(
                scale.getPixelForValue(_ms('2017'), 0),
                toBeCloseToPixel(start + slice * (2017 - 2012)),
              );
              expect(
                scale.getPixelForValue(_ms('2019'), 1),
                toBeCloseToPixel(start + slice * (2019 - 2012)),
              );
              expect(
                scale.getPixelForValue(_ms('2020'), 2),
                toBeCloseToPixel(start + slice * (2020 - 2012)),
              );
              expect(
                scale.getPixelForValue(_ms('2025'), 3),
                toBeCloseToPixel(start + slice * (2025 - 2012)),
              );
              expect(
                scale.getPixelForValue(_ms('2042'), 4),
                toBeCloseToPixel(start + slice * (2042 - 2012)),
              );
            },
          );
        });
      });
    }

    group('when bounds', () {
      group('is "data"', () {
        _lineTwin('should preserve the data range', () {
          final chart = acquireChart(<String, Object?>{
            'type': 'line',
            'data': <String, Object?>{
              'labels': <Object?>[
                '02/20 08:00',
                '02/21 09:00',
                '02/22 10:00',
                '02/23 11:00',
              ],
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
                  'bounds': 'data',
                  'time': <String, Object?>{
                    'parser': 'MM/dd HH:mm',
                    'unit': 'day',
                  },
                },
                'y': <String, Object?>{'display': false},
              },
            },
          });

          final scale = chart.scales['x']!;

          expect(scale.min, _ms('02/20 08:00', 'MM/dd HH:mm'));
          expect(scale.max, _ms('02/23 11:00', 'MM/dd HH:mm'));
          expect(
            scale.getPixelForValue(_ms('02/20 08:00', 'MM/dd HH:mm')),
            toBeCloseToPixel(scale.left),
          );
          expect(
            scale.getPixelForValue(_ms('02/23 11:00', 'MM/dd HH:mm')),
            toBeCloseToPixel(scale.left + scale.width),
          );
          expect(_getLabels(scale), ['Feb 21', 'Feb 22', 'Feb 23']);
        });
      });

      group('is "labels"', () {
        _lineTwin('should preserve the label range', () {
          final chart = acquireChart(<String, Object?>{
            'type': 'line',
            'data': <String, Object?>{
              'labels': <Object?>[
                '02/20 08:00',
                '02/21 09:00',
                '02/22 10:00',
                '02/23 11:00',
              ],
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
                  'bounds': 'ticks',
                  'time': <String, Object?>{
                    'parser': 'MM/dd HH:mm',
                    'unit': 'day',
                  },
                },
                'y': <String, Object?>{'display': false},
              },
            },
          });

          final scale = chart.scales['x']!;
          final ticks = scale.getTicks()!;

          expect(scale.min, ticks[0].value);
          expect(scale.max, ticks[ticks.length - 1].value);
          expect(
            scale.getPixelForValue(_ms('02/20 08:00', 'MM/dd HH:mm')),
            toBeCloseToPixel(60),
          );
          expect(
            scale.getPixelForValue(_ms('02/23 11:00', 'MM/dd HH:mm')),
            toBeCloseToPixel(426),
          );
          expect(_getLabels(scale), [
            'Feb 20',
            'Feb 21',
            'Feb 22',
            'Feb 23',
            'Feb 24',
          ]);
        });
      });
    });

    group('when min and/or max are defined', () {
      for (final source in ['auto', 'data', 'labels']) {
        for (final bounds in ['data', 'ticks']) {
          group('and ticks.source is "$source" and bounds "$bounds"', () {
            /// scale.time.tests.js:983-1008 `beforeEach`.
            Chart rangeChart() => acquireChart(<String, Object?>{
              'type': 'line',
              'data': <String, Object?>{
                'labels': <Object?>[
                  '02/20 08:00',
                  '02/21 09:00',
                  '02/22 10:00',
                  '02/23 11:00',
                ],
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
                    'bounds': bounds,
                    'time': <String, Object?>{
                      'parser': 'MM/dd HH:mm',
                      'unit': 'day',
                    },
                    'ticks': <String, Object?>{'source': source},
                  },
                  'y': <String, Object?>{'display': false},
                },
              },
            });

            _lineTwin('should expand scale to the min/max range', () {
              final chart = rangeChart();
              final scale = chart.scales['x']!;
              final options = _scaleOptions(chart);
              const min = '02/19 07:00';
              const max = '02/24 08:00';
              final minMillis = _ms(min, 'MM/dd HH:mm');
              final maxMillis = _ms(max, 'MM/dd HH:mm');

              options['min'] = min;
              options['max'] = max;
              chart.update();

              expect(scale.min, minMillis);
              expect(scale.max, maxMillis);
              expect(
                scale.getPixelForValue(minMillis),
                toBeCloseToPixel(scale.left),
              );
              expect(
                scale.getPixelForValue(maxMillis),
                toBeCloseToPixel(scale.left + scale.width),
              );
              for (final tick in scale.getTicks()!) {
                expect(tick.value >= minMillis, isTrue);
                expect(tick.value <= maxMillis, isTrue);
              }
            });

            _lineTwin('should shrink scale to the min/max range', () {
              final chart = rangeChart();
              final scale = chart.scales['x']!;
              final options = _scaleOptions(chart);
              const min = '02/21 07:00';
              const max = '02/22 20:00';
              final minMillis = _ms(min, 'MM/dd HH:mm');
              final maxMillis = _ms(max, 'MM/dd HH:mm');

              options['min'] = min;
              options['max'] = max;
              chart.update();

              expect(scale.min, minMillis);
              expect(scale.max, maxMillis);
              expect(
                scale.getPixelForValue(minMillis),
                toBeCloseToPixel(scale.left),
              );
              expect(
                scale.getPixelForValue(maxMillis),
                toBeCloseToPixel(scale.left + scale.width),
              );
              for (final tick in scale.getTicks()!) {
                expect(tick.value >= minMillis, isTrue);
                expect(tick.value <= maxMillis, isTrue);
              }
            });
          });
        }
      }
    });

    for (final source in ['auto', 'data', 'labels']) {
      for (final type in ['timeseries', 'time']) {
        group('when ticks.source is "$source" and scale type is "$type"', () {
          /// scale.time.tests.js:1062-1084 `beforeEach`.
          Chart offsetChart() => acquireChart(<String, Object?>{
            'type': 'line',
            'data': <String, Object?>{
              'labels': <Object?>['2017', '2018', '2019', '2020', '2021'],
              'datasets': <Object?>[
                <String, Object?>{
                  'data': <Object?>[0, 1, 2, 3, 4],
                },
              ],
            },
            'options': <String, Object?>{
              'scales': <String, Object?>{
                'x': <String, Object?>{
                  'type': type,
                  'time': <String, Object?>{
                    'parser': 'yyyy',
                    'unit': 'year',
                  },
                  'ticks': <String, Object?>{'source': source},
                },
              },
            },
          });

          _lineTwin('should not add offset from the edges', () {
            final scale = offsetChart().scales['x']!;

            expect(
              scale.getPixelForValue(_ms('2017')),
              toBeCloseToPixel(scale.left),
            );
            expect(
              scale.getPixelForValue(_ms('2021')),
              toBeCloseToPixel(scale.left + scale.width),
            );
          });

          _lineTwin('should add offset from the edges if offset is true', () {
            final chart = offsetChart();
            final scale = chart.scales['x']!;
            final options = _scaleOptions(chart);

            options['offset'] = true;
            chart.update();

            final numTicks = scale.ticks!.length;
            final firstTickInterval =
                scale.getPixelForTick(1)! - scale.getPixelForTick(0)!;
            final lastTickInterval =
                scale.getPixelForTick(numTicks - 1)! -
                scale.getPixelForTick(numTicks - 2)!;

            expect(
              scale.getPixelForValue(_ms('2017')),
              toBeCloseToPixel(scale.left + firstTickInterval / 2),
            );
            expect(
              scale.getPixelForValue(_ms('2021')),
              toBeCloseToPixel(
                scale.left + scale.width - lastTickInterval / 2,
              ),
            );
          });

          _lineTwin(
            'should not add offset if min and max extend the labels range',
            () {
              final chart = offsetChart();
              final scale = chart.scales['x']!;
              final options = _scaleOptions(chart);

              options['min'] = '2012';
              options['max'] = '2051';
              chart.update();

              expect(
                scale.getPixelForValue(_ms('2012')),
                toBeCloseToPixel(scale.left),
              );
              expect(
                scale.getPixelForValue(_ms('2051')),
                toBeCloseToPixel(scale.left + scale.width),
              );
            },
          );
        });
      }
    }

    for (final source in ['data', 'labels']) {
      for (final type in ['timeseries', 'time']) {
        group('when ticks.source is "$source" and scale type is "$type"', () {
          /// scale.time.tests.js:1164-1188 `beforeEach`.
          Chart offsetChart() => acquireChart(<String, Object?>{
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
                  'id': 'x',
                  'type': type,
                  'time': <String, Object?>{'parser': 'yyyy'},
                  'ticks': <String, Object?>{'source': source},
                },
              },
            },
          });

          _lineTwin(
            'should add offset if min and max extend the labels range and '
            'offset is true',
            () {
              final chart = offsetChart();
              final scale = chart.scales['x']!;
              final options = _scaleOptions(chart);

              options['min'] = '2012';
              options['max'] = '2051';
              options['offset'] = true;
              chart.update();

              final numTicks = scale.ticks!.length;
              final firstTickInterval =
                  scale.getPixelForTick(1)! - scale.getPixelForTick(0)!;
              final lastTickInterval =
                  scale.getPixelForTick(numTicks - 1)! -
                  scale.getPixelForTick(numTicks - 2)!;
              expect(
                scale.getPixelForValue(_ms('2012')),
                toBeCloseToPixel(scale.left + firstTickInterval / 2),
              );
              expect(
                scale.getPixelForValue(_ms('2051')),
                toBeCloseToPixel(
                  scale.left + scale.width - lastTickInterval / 2,
                ),
              );
            },
          );
        });
      }
    }

    group('Deprecations', () {
      group('options.time.displayFormats', () {
        testWidgets('should generate defaults from adapter presets', (
          tester,
        ) async {
          final chart = acquireChart(<String, Object?>{
            'type': 'line',
            'data': <String, Object?>{},
            'options': <String, Object?>{
              'scales': <String, Object?>{
                'x': <String, Object?>{'type': 'time'},
              },
            },
          });

          // NOTE: the test suite is configured to use moment
          // The default adapter gives the moment presets as ICU patterns
          // (date_format.dart).
          final expected = <String, Object?>{
            'datetime': 'MMM d, yyyy, h:mm:ss a',
            'millisecond': 'h:mm:ss.SSS a',
            'second': 'h:mm:ss a',
            'minute': 'h:mm a',
            'hour': 'ha',
            'day': 'MMM d',
            'week': 'MMM d, yyyy',
            'month': 'MMM yyyy',
            'quarter': "'Q'Q - yyyy",
            'year': 'yyyy',
          };

          expect(
            _displayFormats(chart.scales['x']!.options),
            equals(expected),
          );
          expect(_displayFormats(_scaleOptions(chart)), equals(expected));
        });

        testWidgets('should merge user formats with adapter presets', (
          tester,
        ) async {
          final chart = acquireChart(<String, Object?>{
            'type': 'line',
            'data': <String, Object?>{},
            'options': <String, Object?>{
              'scales': <String, Object?>{
                'x': <String, Object?>{
                  'type': 'time',
                  'time': <String, Object?>{
                    'displayFormats': <String, Object?>{
                      'millisecond': 'foo',
                      'hour': 'bar',
                      'month': 'bla',
                    },
                  },
                },
              },
            },
          });

          // NOTE: the test suite is configured to use moment
          // The default adapter gives the moment presets as ICU patterns
          // (date_format.dart).
          final expected = <String, Object?>{
            'datetime': 'MMM d, yyyy, h:mm:ss a',
            'millisecond': 'foo',
            'second': 'h:mm:ss a',
            'minute': 'h:mm a',
            'hour': 'bar',
            'day': 'MMM d',
            'week': 'MMM d, yyyy',
            'month': 'bla',
            'quarter': "'Q'Q - yyyy",
            'year': 'yyyy',
          };

          expect(
            _displayFormats(chart.scales['x']!.options),
            equals(expected),
          );
          expect(_displayFormats(_scaleOptions(chart)), equals(expected));
        });
      });
    });
  });

  group('Liberation Sans widths of the generator', () {
    testReferenceWidths(scaleTimeReferenceWidths);
  });
}
