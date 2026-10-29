// Original code, not ported from Chart.js: timeseries scale reference tests.
@TestOn('vm')
library;

// The tests read the protected members of the scale, as the generator does.
// ignore_for_file: invalid_use_of_protected_member

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.registry.dart' show registry;
import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/scales/scale.linear.dart';
import 'package:flutter_chartjs_port/src/scales/scale.time.dart';
import 'package:flutter_chartjs_port/src/scales/scale.timeseries.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_test/flutter_test.dart';

import 'scale_chart_harness.dart';
import 'scale_time_harness.dart';
import 'scale_timeseries_reference.dart';

// The port-only tests of lib/src/scales/scale.timeseries.dart. Chart.js has
// no spec file for the timeseries scale (AGENTS.md rule 3).
//
// The reference group compares real charts with the charts of
// tool/reference/scale_timeseries_reference.mjs: a build of the pinned
// Chart.js with chartjs-adapter-moment 1.0.1 on moment 2.29.4 in the zone
// 'Etc/UTC', in Node.js v24.22.1 on arm64 (Chart.js ADR 0045, Chart.js ADR
// 0024), with a mock context that measures text in Liberation Sans 2.1.5
// (scale_chart_harness.dart, scale_time_harness.dart). Each chart comes
// from acquireChart in a testWidgets case (Chart.js ADR 0022), at the fixed
// time of `Date.now()` of the generator.
//
// The cartesian test controller `timeseriesTest` has the timeseries scale
// on the index axis and the linear scale on the value axis. main()
// registers the timeseries scale (the registry registers the time scale
// first), the linear scale and the test controller through their class
// values, before the snapshot of the defaults restore (Chart.js ADR 0020,
// section 8, and Chart.js ADR 0022, section 8).
//
// The group of Chart.js ADR 0025 pins the relations of the value types
// (section 9, probe P5). The timeseries scale has no fast path (Chart.js
// ADR 0025, Open 1).

/// The cartesian test controller `timeseriesTest` of the generator:
/// timeseries on the index axis and linear on the value axis.
final JsClass _timeseriesTestController = cartesianTestController(
  'timeseriesTest',
  {
    'scales': <String, Object?>{
      '_index_': <String, Object?>{'type': 'timeseries'},
      '_value_': <String, Object?>{'type': 'linear'},
    },
  },
);

/// The observations of a timeseries scale: `timeseriesObservations` of the
/// generator, with the same keys and the same calls.
Map<String, Object?> _timeseriesObservations(Scale scale, Chart chart) {
  if (scale is! TimeSeriesScale) return const {};
  final horizontal = scale.isHorizontal();
  final start = horizontal ? scale.left : scale.top;
  final end = horizontal ? scale.right : scale.bottom;
  List<Object?> table(List<double?> timestamps) => [
    for (final entry in scale.buildLookupTable(timestamps))
      [entry['time'], entry['pos']],
  ];
  return {
    'dataTable': table(scale.getDataTimestamps()),
    'labelTable': table(scale.getLabelTimestamps()),
    'decimalForData': [
      for (final t in scale.getDataTimestamps()) scale.getDecimalForValue(t),
    ],
    'valuesAlongAxis': [
      for (var i = 0; i < 11; i++)
        scale.getValueForPixel(start + (i / 10) * (end - start)),
    ],
  };
}

/// The named functions of the configs of the generator.
final Map<String, Object?> _functions = {
  // `(value, index) => 'T' + index`.
  'tickIndex': (Object? value, Object? index) => 'T${jsToString(index)}',
};

/// One day in ms.
const double _day = 86400000;

/// Monday 2021-01-04T00:00:00Z.
final double _t0 = DateTime.utc(2021, 1, 4).millisecondsSinceEpoch.toDouble();

/// The timeseries scale `x` of a chart of `{x, y}` points at [times], with
/// the options of the scale x [x].
TimeSeriesScale _x(List<double> times, [AnyObject? x]) {
  final chart = acquireChart({
    'type': 'timeseriesTest',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            for (final x in times) <String, Object?>{'x': x, 'y': 1.0},
          ],
        },
      ],
    },
    'options': <String, Object?>{
      'scales': <String, Object?>{'x': ?x},
    },
  });
  return chart.scales['x']! as TimeSeriesScale;
}

void main() {
  // Before the snapshot of the defaults restore (Chart.js ADR 0022, section
  // 8). The restore does not reset the items of the registry.
  Chart.register([
    TimeSeriesScale.jsClass,
    LinearScale.jsClass,
    _timeseriesTestController,
  ]);

  testReferenceOrigin(
    node: scaleTimeseriesReferenceNode,
    arch: scaleTimeseriesReferenceArch,
    dist: scaleTimeseriesReferenceDist,
    commit: scaleTimeseriesReferenceCommit,
  );
  testAdapterOrigin(scaleTimeseriesReferenceAdapter);

  group('the class value (Chart.js ADR 0020)', () {
    test('the registry gives the class values of timeseries and of its '
        'parent time', () {
      expect(registry.getScale('timeseries'), same(TimeSeriesScale.jsClass));
      expect(registry.getScale('time'), same(TimeScale.jsClass));
      expect(TimeSeriesScale.jsClass['id'], 'timeseries');
      expect(TimeSeriesScale.jsClass['defaults'], same(TimeScale.defaults));
    });
  });

  group('timeseries scale charts against upstream', () {
    testTimeScaleCases(
      scaleTimeseriesReference,
      now: scaleTimeseriesReferenceNow,
      functions: _functions,
      extra: _timeseriesObservations,
    );
  });

  group('value types (Chart.js ADR 0025)', () {
    testWidgets('null and false act as 0', (tester) async {
      final x = _x([_t0, _t0 + _day, _t0 + 9 * _day]);
      final zero = x.getDecimalForValue(0);
      expect(zero, isNot(isNaN));
      expect(x.getDecimalForValue(null), zero);
      expect(x.getDecimalForValue(false), zero);
      expect(x.getDecimalForValue(0.0), zero);
    });

    testWidgets('undefined and NaN give NaN', (tester) async {
      final x = _x([_t0, _t0 + _day, _t0 + 9 * _day]);
      expect(x.getDecimalForValue(undefined), isNaN);
      expect(x.getDecimalForValue(double.nan), isNaN);
      expect(x.getPixelForValue(undefined), isNaN);
    });

    testWidgets('the data timestamps have equal distances', (tester) async {
      final x = _x([_t0, _t0 + _day, _t0 + 9 * _day, _t0 + 40 * _day]);
      expect(
        [
          for (final t in [_t0, _t0 + _day, _t0 + 9 * _day, _t0 + 40 * _day])
            x.getDecimalForValue(t),
        ],
        [0, closeTo(1 / 3, 1e-12), closeTo(2 / 3, 1e-12), 1],
      );
      expect(
        x.getValueForPixel(x.getPixelForValue(_t0 + 9 * _day)),
        _t0 + 9 * _day,
      );
    });
  });

  // differences.md row adapt-time-null-timestamp. The reference cases with
  // ticks source labels and a label that does not parse give the upstream
  // layout.
  group('adapt-time-null-timestamp', () {
    testWidgets('the pixel of a null tick is the pixel of 0', (tester) async {
      final chart = acquireChart({
        'type': 'timeseriesTest',
        'data': <String, Object?>{
          'labels': <Object?>['2021-01-04', 'garbage', '2021-01-20'],
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[1.0, 2.0, 3.0],
            },
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{
              'ticks': <String, Object?>{'source': 'labels'},
            },
          },
        },
      });
      final x = chart.scales['x']! as TimeSeriesScale;
      // Upstream gives the tick the value null, and getDecimalForValue of
      // the timeseries scale reads null as 0 (scale.timeseries.js:162-163).
      expect(x.ticks!.first.value, isNaN);
      expect(x.getPixelForTick(0), isNotNaN);
      expect(x.getPixelForTick(0), x.getPixelForValue(0));
      expect(x.getPixelForTick(0), x.getPixelForValue(null));
      expect(x.paddingLeft, isNotNaN);
    });
  });

  group('the generated timestamps', () {
    testWidgets('generate adds min and max to the data cache in place', (
      tester,
    ) async {
      // scale.timeseries.js:122-129: splice(0, 0, min), push(max) and sort
      // on the List of getDataTimestamps.
      final x = _x(
        [_t0 + _day, _t0 + 3 * _day],
        {
          'min': _t0,
          'max': _t0 + 5 * _day,
        },
      );
      final data = x.getDataTimestamps();
      expect(data, same(x.cache['data']));
      expect((x.min, x.max), (_t0, _t0 + 5 * _day));
      expect(data, [_t0, _t0 + _day, _t0 + 3 * _day, _t0 + 5 * _day]);
    });

    testWidgets('generate adds no bound that the data has', (tester) async {
      final x = _x([_t0 + _day, _t0 + 3 * _day]);
      expect((x.min, x.max), (_t0 + _day, _t0 + 3 * _day));
      expect(x.getDataTimestamps(), [_t0 + _day, _t0 + 3 * _day]);
    });
  });

  group('Liberation Sans widths of the generator', () {
    testReferenceWidths(scaleTimeseriesReferenceWidths);
  });
}
