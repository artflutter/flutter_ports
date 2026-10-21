// Original code, not ported from Chart.js: logarithmic scale reference tests.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/core/core.defaults.dart' show defaults;
import 'package:flutter_chartjs/src/core/core.registry.dart' show registry;
import 'package:flutter_chartjs/src/core/core.scale.dart';
import 'package:flutter_chartjs/src/core/core.ticks.dart' show formatters;
import 'package:flutter_chartjs/src/helpers/helpers.math.dart' show log10;
import 'package:flutter_chartjs/src/js/js_class.dart';
import 'package:flutter_chartjs/src/js/js_function.dart' show jsIsFunction;
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/scales/scale.logarithmic.dart';
import 'package:flutter_chartjs/src/types/basic.dart';
import 'package:flutter_test/flutter_test.dart';

import 'scale_chart_harness.dart';
import 'scale_logarithmic_reference.dart';

// The port-only tests of lib/src/scales/scale.logarithmic.dart.
//
// The reference group compares real charts with the charts of
// tool/reference/scale_logarithmic_reference.mjs: a build of the pinned
// Chart.js in Node.js v24.12.0 on x64 (Chart.js ADR 0032), with a mock
// context that measures text in Liberation Sans 2.1.5, the test font of the
// harness (scale_chart_harness.dart, tool/reference/scale_chart_common.mjs).
// Each chart comes from acquireChart in a testWidgets case (Chart.js ADR
// 0022).
// An action case changes the chart and calls chart.update() before the
// observations, with the action of the same case name in the generator.
//
// The cartesian test controller `logTest` has the logarithmic scale on both
// axes. `logValueTest` has the category scale on the index axis and the
// logarithmic scale on the value axis. test/flutter_test_config.dart
// registers the six scales of lib/src/index.dart before main() (the row
// harness-register-builtins). Thus main() registers only the two test
// controllers through their class values, before the snapshot of the
// defaults restore (Chart.js ADR 0020, section 8, and Chart.js ADR 0022,
// section 8). The generator registers the six scales and the four elements
// of the dist first. The other scales of the dist do not change these
// charts: a scale registers only its own defaults.
//
// The groups of Chart.js ADR 0025 pin the fast path of getPixelForValue
// (section 3) and the relations of the value types (section 9) without
// generated values.

/// The cartesian test controller `logTest` of the generator: the
/// logarithmic scale on both axes.
final JsClass _logTestController = cartesianTestController('logTest', {
  'scales': <String, Object?>{
    '_index_': <String, Object?>{'type': 'logarithmic'},
    '_value_': <String, Object?>{'type': 'logarithmic'},
  },
});

/// The cartesian test controller `logValueTest` of the generator: the
/// category scale on the index axis and the logarithmic scale on the value
/// axis.
final JsClass _logValueTestController = cartesianTestController(
  'logValueTest',
  {
    'scales': <String, Object?>{
      '_index_': <String, Object?>{'type': 'category'},
      '_value_': <String, Object?>{'type': 'logarithmic'},
    },
  },
);

/// [value] as an `int` when it is a finite integer, else [value]. An `int`
/// takes the literal lines of [LogarithmicScale.getPixelForValue], not the
/// fast path.
Object _intIfIntegral(double value) =>
    value.isFinite && value == value.truncateToDouble() ? value.toInt() : value;

/// The observations of a logarithmic scale: `logObservations` of the
/// generator, with the same keys and the same calls. The second 0, the
/// second 100 and the second min are `int` values here, where the
/// generator gives numbers: they take the literal lines of
/// [LogarithmicScale.getPixelForValue].
Map<String, Object?> _logObservations(Scale scale, Chart chart) {
  if (scale is! LogarithmicScale) return const {};
  final horizontal = scale.isHorizontal();
  final start = horizontal ? scale.left : scale.top;
  final end = horizontal ? scale.right : scale.bottom;
  return {
    'start': scale.start,
    'end': scale.end,
    'significands': [
      for (final t in scale.ticks!) t.significand ?? double.nan,
    ],
    'labelForValue': [
      for (final v in <Object?>[
        scale.min,
        scale.max,
        1234.5,
        0.000125,
        98765.4321,
        undefined,
        null,
        '7.5',
        true,
        0,
      ])
        scale.getLabelForValue(v),
    ],
    'parse': [
      for (final v in <Object?>[
        null,
        undefined,
        double.nan,
        double.infinity,
        double.negativeInfinity,
        12.0,
        -5.0,
        0.0,
        -0.0,
        '12.5',
        '0',
        'abc',
        '',
        true,
        false,
        <Object?>[7.0],
        <String, Object?>{},
      ])
        scale.parse(v, 0),
    ],
    'pixelForValue': [
      for (final v in <Object?>[
        undefined,
        0.0,
        0,
        -0.0,
        null,
        double.nan,
        '100',
        100.0,
        100,
        true,
        scale.min,
        _intIfIntegral(scale.min),
        scale.max,
        double.infinity,
        -5.0,
        1e-300,
        'abc',
        false,
        <Object?>[100.0],
        <String, Object?>{},
      ])
        scale.getPixelForValue(v),
    ],
    'valuesForPixels': [
      for (final p in [start - 50, start + 0.37 * (end - start), end + 50])
        scale.getValueForPixel(p),
    ],
  };
}

/// The named functions of the configs of the generator.
final Map<String, Object?> _functions = {
  'withUnit': (Object? value) => '${jsToString(value)} kg',
};

/// The dataset [index] of [chart].
Map<String, Object?> _dataset(Chart chart, int index) =>
    (chart.data['datasets']! as List<Object?>)[index]! as Map<String, Object?>;

/// The options of the scale [id] in the config of [chart].
Map<String, Object?> _scaleConfig(Chart chart, String id) {
  final scales = chart.config.options['scales']! as Map<String, Object?>;
  return scales[id]! as Map<String, Object?>;
}

/// The actions of the action cases of the generator (`runAction`), by the
/// case name. Each one changes the chart and calls `chart.update()`.
final Map<String, void Function(Chart chart)> _actions = {
  'data without zeros after data with zeros': (chart) {
    _dataset(chart, 0)['data'] = <Object?>[10.0, 100.0, 50.0];
    chart.update();
  },
  'beginAtZero removed after the creation': (chart) {
    _scaleConfig(chart, 'y')['beginAtZero'] = false;
    _dataset(chart, 0)['data'] = <Object?>[20.0, 100.0];
    chart.update();
  },
};

/// A chart of `logValueTest` with the labels a, b and c, the data [data]
/// and the options [options].
Chart _chart(List<Object?> data, [AnyObject? options]) => acquireChart({
  'type': 'logValueTest',
  'data': <String, Object?>{
    'labels': <Object?>['a', 'b', 'c'],
    'datasets': <Object?>[
      <String, Object?>{'data': data},
    ],
  },
  'options': ?options,
});

/// The logarithmic scale `y` of [chart].
LogarithmicScale _y(Chart chart) => chart.scales['y']! as LogarithmicScale;

/// A matcher of [pixel]: [isNaN] for NaN, else [equals].
Matcher _samePixel(double pixel) => pixel.isNaN ? isNaN : equals(pixel);

void main() {
  // Before the snapshot of the defaults restore (Chart.js ADR 0022, section
  // 8). The restore does not reset the items of the registry.
  Chart.register([_logTestController, _logValueTestController]);

  testReferenceOrigin(
    node: scaleLogarithmicReferenceNode,
    arch: scaleLogarithmicReferenceArch,
    dist: scaleLogarithmicReferenceDist,
    commit: scaleLogarithmicReferenceCommit,
  );

  group('the class value (Chart.js ADR 0020)', () {
    test('the registry gives the class value of the id logarithmic', () {
      expect(registry.getScale('logarithmic'), same(LogarithmicScale.jsClass));
      expect(LogarithmicScale.jsClass.name, 'LogarithmicScale');
      expect(LogarithmicScale.jsClass['id'], 'logarithmic');
      expect(
        LogarithmicScale.jsClass['defaults'],
        same(LogarithmicScale.defaults),
      );
      expect(LogarithmicScale.jsClass.superclass, same(Scale.jsClass));
      expect(jsTypeof(LogarithmicScale.jsClass), 'function');
    });

    test('defaults.scales.logarithmic has the callback and major ticks', () {
      // scale.logarithmic.tests.js:14-27.
      final scales = defaults['scales']! as Map<String, Object?>;
      final logarithmic = scales['logarithmic']! as Map<String, Object?>;
      expect(logarithmic.keys, ['ticks']);
      final ticks = logarithmic['ticks']! as Map<String, Object?>;
      expect(ticks.keys, ['callback', 'major']);
      expect(ticks['callback'], same(formatters['logarithmic']));
      expect(jsIsFunction(ticks['callback']), isTrue);
      expect(ticks['major'], {'enabled': true});
    });

    testWidgets('jsConstruct makes a LogarithmicScale with the start values', (
      tester,
    ) async {
      final chart = _chart([1.0, 10.0, 100.0]);
      final scale = jsConstruct(LogarithmicScale.jsClass, [
        <String, Object?>{
          'id': 'z',
          'type': 'logarithmic',
          'ctx': null,
          'chart': chart,
        },
      ]);
      expect(scale, isA<LogarithmicScale>());
      expect((scale as LogarithmicScale).id, 'z');
      // scale.logarithmic.js:94-100.
      expect(scale.start, isNaN);
      expect(scale.end, isNaN);
    });
  });

  group('logarithmic scale charts against upstream', () {
    test('each action names a case', () {
      final names = [for (final c in scaleLogarithmicReference) c.name];
      expect(_actions.keys, everyElement(isIn(names)));
    });

    for (final c in scaleLogarithmicReference) {
      testWidgets(c.name, (tester) async {
        final chart = acquireChart(
          copyReference(c.config, _functions)! as AnyObject,
          copyReference(c.options)! as AnyObject,
        );
        _actions[c.name]?.call(chart);
        expectScaleChart(chart, c.expected, extra: _logObservations);
      });
    }
  });

  group('fast path (Chart.js ADR 0025)', () {
    for (final (name, data) in [
      ('a range from 1 to 100', <Object?>[1.0, 10.0, 100.0]),
      ('a range from 0.001 to 1000', <Object?>[0.001, 3.0, 1000.0]),
      ('a range from 2 to 700', <Object?>[2.0, 50.0, 700.0]),
    ]) {
      testWidgets('a double and an int give the same pixel, $name', (
        tester,
      ) async {
        final y = _y(_chart(data));
        final min = y.min;
        final max = y.max;
        final startValue = log10(min);
        final valueRange = log10(max) - log10(min);
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
          10.0,
          100.0,
          1000.0,
          -7.0,
        ]) {
          final pixel = y.getPixelForValue(value);
          // scale.logarithmic.js:211-219 with a number.
          final number = value == 0 ? min : value;
          expect(
            pixel,
            _samePixel(
              number.isNaN
                  ? double.nan
                  : y.getPixelForDecimal(
                      number == min
                          ? 0
                          : (log10(number) - startValue) / valueRange,
                    ),
            ),
            reason: '$value',
          );
          if (value.isFinite && value == value.truncateToDouble()) {
            expect(
              y.getPixelForValue(value.toInt()),
              _samePixel(pixel),
              reason: '${value.toInt()} as an int',
            );
          }
        }
        // 0 and 0.0 give the pixel of min. An integral min gives the same
        // pixel as an int.
        expect(y.getPixelForValue(0), y.getPixelForValue(min));
        expect(y.getPixelForValue(0.0), y.getPixelForValue(min));
        expect(
          y.getPixelForValue(_intIfIntegral(min)),
          y.getPixelForValue(min),
        );
      });
    }
  });

  group('value types (Chart.js ADR 0025)', () {
    testWidgets('undefined, 0, 0.0 and -0.0 give the pixel of min', (
      tester,
    ) async {
      final y = _y(_chart([0.0, 10.0, 100.0]));
      final pixel = y.getPixelForValue(y.min);
      expect(pixel, isNot(isNaN));
      expect(y.getPixelForValue(undefined), pixel);
      expect(y.getPixelForValue(0), pixel);
      expect(y.getPixelForValue(0.0), pixel);
      expect(y.getPixelForValue(-0.0), pixel);
    });

    testWidgets('null and NaN give NaN', (tester) async {
      final y = _y(_chart([1.0, 10.0, 100.0]));
      expect(y.getPixelForValue(null), isNaN);
      expect(y.getPixelForValue(double.nan), isNaN);
      expect(y.getPixelForValue('abc'), isNaN);
    });

    testWidgets("'100' gives the pixel of 100", (tester) async {
      final y = _y(_chart([1.0, 10.0, 1000.0]));
      expect(y.getPixelForValue('100'), y.getPixelForValue(100.0));
      expect(y.getPixelForValue('100'), y.getPixelForValue(100));
      expect(y.getPixelForValue(true), y.getPixelForValue(1.0));
    });

    testWidgets('the parse of a 0 is undefined, and its label is 0', (
      tester,
    ) async {
      final chart = _chart([0.0, 10.0, 100.0]);
      final y = _y(chart);
      final parsed = chart.getDatasetMeta(0).parsed;
      // scale.logarithmic.js:105-108: the parsed value of the 0.
      expect(jsGet(parsed[0], 'y'), same(undefined));
      expect(y.parse(0), same(undefined));
      expect(y.parse(-0.0), same(undefined));
      expect(y.getLabelForValue(undefined), '0');
      // The point of the 0 is at the pixel of min.
      expect(
        chart.getDatasetMeta(0).data[0].y,
        y.getPixelForValue(y.min),
      );
    });
  });

  group('Liberation Sans widths of the generator', () {
    testReferenceWidths(scaleLogarithmicReferenceWidths);
  });
}
