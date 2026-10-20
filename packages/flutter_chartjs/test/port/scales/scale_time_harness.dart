// Original code, not ported from Chart.js: time scale test harness.

/// The shared parts of the port-only reference tests of the time scale and
/// of the timeseries scale (`scale.time_test.dart`,
/// `scale.timeseries_test.dart`): the time observations, the fixed clock
/// and the origin of the date adapter of the generators.
///
/// The generators (`tool/reference/scale_time_reference.mjs`,
/// `tool/reference/scale_timeseries_reference.mjs`) run a build of the
/// pinned Chart.js with chartjs-adapter-moment 1.0.1 on moment 2.29.4 and
/// moment-timezone 0.5.42 in the zone 'Etc/UTC', the date adapter of the
/// specs (`tool/reference/scale_time_common.mjs`). The Dart charts use the
/// default date adapter of the port (Chart.js ADR 0024) in UTC: the
/// harness sets the default zone (`test/flutter_test_config.dart`).
///
/// `Date.now()` of the generators gives a fixed time. A Dart chart runs in
/// `withClock` with the same time (Chart.js ADR 0024, section 7).
///
/// [testTimeScaleCases] also compares the times of each time scale exactly
/// ([expectExactTimes]). The tolerance of [referenceMatcher] accepts a
/// relative difference of 1e-12, about 1.6 ms for a time of 2021.
///
/// This library is not a test file. It is not a pure layer. A test that
/// imports it needs `@TestOn('vm')`.
library;

// The observations call the protected timestamp methods of the scale, as
// the generators do.
// ignore_for_file: invalid_use_of_protected_member

import 'package:chartjs_test_utils/flutter.dart';
import 'package:clock/clock.dart';
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/core/core.scale.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/scales/scale.time.dart';
import 'package:flutter_chartjs/src/types/basic.dart';
import 'package:flutter_test/flutter_test.dart';

import 'scale_chart_harness.dart';

/// One day in ms.
const double _day = 86400000;

/// `PARSE_PROBES` of `scale_time_common.mjs`.
final List<Object?> parseProbes = [
  '2021-03-04',
  '2021-03-04T05:06:07',
  '2021-03-04T05:06:07.890Z',
  '2021-03-04T05:06:07+02:00',
  '2021-W10-3',
  '2021-063',
  'Thu, 04 Mar 2021 05:06:07 +0000',
  '/Date(1614834367000)/',
  'garbage',
  '',
  1614834367000.0,
  0.0,
  -1.0,
  double.nan,
  double.infinity,
  null,
  undefined,
  true,
];

/// The observations of a time scale: `timeObservations` of
/// `scale_time_common.mjs`, with the same keys and the same calls.
///
/// - `unit`: [TimeScale.unit].
/// - `offsets`: `[start, end, factor]` of [TimeScale.offsets].
/// - `dataTimestamps`, `labelTimestamps`: copies of the caches.
/// - `decimalForValue`, `pixelForValue`, `valuesForPixels`,
///   `labelForValue`, `format` and `parse`: the results of the value
///   methods for the same values. An integral value of the generator is a
///   Dart `int` here when the generator gives a number literal: it takes
///   the literal lines of [TimeScale.getDecimalForValue].
///
/// A scale of another type gives no observation.
Map<String, Object?> timeObservations(Scale scale, Chart chart) {
  if (scale is! TimeScale) return const {};
  final horizontal = scale.isHorizontal();
  final start = horizontal ? scale.left : scale.top;
  final end = horizontal ? scale.right : scale.bottom;
  final min = scale.min;
  final max = scale.max;
  final mid = (min + max) / 2;
  final parse = jsTruthy(jsGet(scale.options['time'], 'parser'))
      ? const <Object?>[]
      : [
          for (final v in [
            ...parseProbes,
            DateTime.utc(2021, 3, 4, 5, 6, 7, 8),
          ])
            scale.parse(v),
        ];
  final offsets = scale.offsets;
  return {
    'unit': scale.unit,
    'offsets': [offsets.start, offsets.end, offsets.factor],
    'dataTimestamps': List<Object?>.of(scale.getDataTimestamps()),
    'labelTimestamps': List<Object?>.of(scale.getLabelTimestamps()),
    'decimalForValue': [
      for (final v in <Object?>[
        min,
        max,
        mid,
        min - _day,
        max + _day,
        null,
        undefined,
        double.nan,
        0,
        false,
        jsNumberToString(mid),
        true,
      ])
        scale.getDecimalForValue(v),
    ],
    'pixelForValue': [
      for (final v in <Object?>[
        null,
        undefined,
        double.nan,
        jsNumberToString(mid),
        true,
      ])
        scale.getPixelForValue(v),
    ],
    'valuesForPixels': [
      for (final p in [start - 20, start + 0.3 * (end - start), end + 20])
        scale.getValueForPixel(p),
    ],
    'labelForValue': [
      for (final v in <Object?>[min, max, mid, null]) scale.getLabelForValue(v),
    ],
    'format': [
      scale.format(min),
      scale.format(max),
      scale.format(min, 'HH:mm'),
    ],
    'parse': parse,
  };
}

/// [body] with `clock.now()` at [now], the fixed `Date.now()` of the
/// generators (ms since the epoch).
T atNow<T>(double now, T Function() body) => withClock(
  Clock.fixed(DateTime.fromMillisecondsSinceEpoch(now.toInt(), isUtc: true)),
  body,
);

/// The keys of the observations of a time scale that hold times: the
/// bounds, the timestamp caches, the results of `parse` and the lookup
/// tables of the timeseries scale. The scale gets these values from the
/// data and from the adapter, and computes them with the same IEEE
/// arithmetic as JavaScript. Thus the port must give the same doubles as
/// the generator.
const List<String> _exactKeys = [
  'min',
  'max',
  'dataTimestamps',
  'labelTimestamps',
  'parse',
  'dataTable',
  'labelTable',
];

/// The matcher of a reference value that the port must give exactly: NaN
/// for NaN, `==` for another number (0 and -0 are equal), and item by item
/// for a List. A Map `{'num': s}` of a number that JSON cannot hold goes to
/// [referenceMatcher].
Object? exactReferenceMatcher(Object? expected) => switch (expected) {
  final num n when n.isNaN => isNaN,
  final num n => equals(n),
  final Map<String, Object?> map => referenceMatcher(map),
  final List<Object?> list => [
    for (final item in list) exactReferenceMatcher(item),
  ],
  _ => expected,
};

/// Expects the times of each time scale of [chart] to equal the times of
/// [expected], the `expected` of a reference case, exactly: the keys of
/// [_exactKeys] and the value of each tick.
///
/// [referenceMatcher] of [expectScaleChart] accepts a relative difference
/// of 1e-12. For a time of 2021 (about 1.6e12 ms), this is about 1.6 ms.
/// Thus a time that is 1 ms off passes there, unless it changes a label or
/// a pixel. [extra] gives the same observations as for [expectScaleChart].
void expectExactTimes(
  Chart chart,
  Map<String, Object?> expected, {
  ScaleObservations? extra,
}) {
  final observed =
      observeChart(chart, extra: extra)['scales']! as Map<String, Object?>;
  final expectedScales = expected['scales']! as Map<String, Object?>;
  for (final MapEntry(key: id, :value) in expectedScales.entries) {
    final expectedScale = value! as Map<String, Object?>;
    // Only a time scale has the time observations.
    if (!expectedScale.containsKey('unit')) continue;
    final scale = observed[id]! as Map<String, Object?>;
    for (final key in _exactKeys) {
      if (!expectedScale.containsKey(key)) continue;
      expect(
        scale[key],
        exactReferenceMatcher(expectedScale[key]),
        reason: 'scales.$id.$key (exact)',
      );
    }
    List<Object?> values(Object? ticks) => [
      for (final tick in ticks! as List<Object?>) (tick! as List<Object?>)[0],
    ];
    expect(
      values(scale['ticks']),
      exactReferenceMatcher(values(expectedScale['ticks'])),
      reason: 'scales.$id.ticks: the values (exact)',
    );
  }
}

/// A copy of [expected], the `expected` of a reference case, where the
/// value `null` of a tick of a time scale is NaN.
///
/// Upstream gives the tick of a label that the adapter cannot parse the
/// value `null` (scale.time.js:185-191). `Tick.value` of the port is a
/// `double`, and such a tick holds NaN (differences.md row
/// `adapt-time-null-timestamp`). The other observations of the tick, for
/// example its label and its pixel, compare with the upstream values.
Map<String, Object?> _nullTickValuesAsNaN(Map<String, Object?> expected) {
  final scales = expected['scales']! as Map<String, Object?>;
  List<Object?> ticks(Object? list) => [
    for (final tick in list! as List<Object?>)
      switch (tick! as List<Object?>) {
        [null, ...final rest] => <Object?>[
          <String, Object?>{'num': 'NaN'},
          ...rest,
        ],
        final other => other,
      },
  ];
  return {
    ...expected,
    'scales': <String, Object?>{
      for (final MapEntry(:key, :value) in scales.entries)
        key: switch (value! as Map<String, Object?>) {
          // Only a time scale has the time observations.
          final scale when scale.containsKey('unit') => <String, Object?>{
            ...scale,
            'ticks': ticks(scale['ticks']),
          },
          final scale => scale,
        },
    },
  };
}

/// A `testWidgets` case for each of [cases]: [setUps] for the name of the
/// case, then the chart of `acquireChart` at [now], with the config and the
/// options of the case ([copyReference] with [functions]), then
/// [expectScaleChart] and [expectExactTimes] with [timeObservations] and
/// [extra]. The expected value of a tick of a time scale is NaN where the
/// reference gives `null` (row `adapt-time-null-timestamp`).
///
/// A case with a name of [skips] skips with the reason that [skips] gives.
void testTimeScaleCases(
  List<ScaleChartCase> cases, {
  required double now,
  Map<String, Object?> functions = const {},
  Map<String, void Function()> setUps = const {},
  Map<String, String> skips = const {},
  ScaleObservations? extra,
}) {
  for (final c in cases) {
    final skip = skips[c.name];
    if (skip != null) {
      test(c.name, () {}, skip: skip);
      continue;
    }
    testWidgets(c.name, (tester) async {
      setUps[c.name]?.call();
      atNow(now, () {
        final chart = acquireChart(
          copyReference(c.config, functions)! as AnyObject,
          copyReference(c.options)! as AnyObject,
        );
        Map<String, Object?> observations(Scale scale, Chart chart) => {
          ...timeObservations(scale, chart),
          ...?extra?.call(scale, chart),
        };
        final expected = _nullTickValuesAsNaN(c.expected);
        expectScaleChart(chart, expected, extra: observations);
        expectExactTimes(chart, expected, extra: observations);
      });
    });
  }
}

/// A test that the date adapter of the generator is chartjs-adapter-moment
/// 1.0.1 on moment 2.29.4 with moment-timezone 0.5.42, the packages of the
/// Chart.js lockfile (pnpm-lock.yaml:48-50, :123-128).
void testAdapterOrigin(
  Map<String, ({String version, String file, String sha256})> adapter,
) {
  test('the date adapter of the generator is the adapter of the specs', () {
    expect(
      {
        for (final MapEntry(:key, :value) in adapter.entries)
          key: value.version,
      },
      {
        'moment': '2.29.4',
        'moment-timezone': '0.5.42',
        'chartjs-adapter-moment': '1.0.1',
      },
    );
  });
}
