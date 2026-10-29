// Original code, not ported from Chart.js: linear scale reference tests.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart' show defaults;
import 'package:flutter_chartjs_port/src/core/core.registry.dart' show registry;
import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/core/core.ticks.dart' show formatters;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/scales/scale.category.dart';
import 'package:flutter_chartjs_port/src/scales/scale.linear.dart';
import 'package:flutter_chartjs_port/src/scales/scale.linearbase.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_test/flutter_test.dart';

import 'scale_chart_harness.dart';
import 'scale_linear_reference.dart';

// The port-only tests of lib/src/scales/scale.linear.dart.
//
// The reference group compares real charts with the charts of
// tool/reference/scale_linear_reference.mjs: a build of the pinned Chart.js
// in Node.js v24.22.1 on arm64 (Chart.js ADR 0045), with a mock context that
// measures text in Liberation Sans 2.1.5, the test font of the harness
// (scale_chart_harness.dart, tool/reference/scale_chart_common.mjs). Each
// chart comes from acquireChart in a testWidgets case (Chart.js ADR 0022).
//
// The charts use three cartesian test controllers: `scaleTest` of the
// harness (category on the index axis and linear on the value axis),
// `scaleTest2` with the same overrides (a dataset of this type gets its own
// stacks), and `linearTest` (linear on both axes). lib/src/index.dart does
// not register the scales yet. Thus main() registers the category scale, the
// linear scale and the test controllers through their class values, before
// the snapshot of the defaults restore (Chart.js ADR 0020, section 8, and
// Chart.js ADR 0022, section 8). The generator registers the built-in
// components and the seven plugins of the dist first (registerBuiltins,
// Chart.js ADR 0041, section 1), as flutter_test_config.dart does. The other
// scales of the dist do not change these charts: a scale registers only its
// own defaults.
//
// The groups of Chart.js ADR 0025 pin the fast path of getPixelForValue
// (section 3) and the relations of the value types (section 9) without
// generated values.

/// The test controller `scaleTest2` of the generator: the overrides of
/// `scaleTest`.
final JsClass _scaleTest2Controller = cartesianTestController('scaleTest2', {
  'scales': <String, Object?>{
    '_index_': <String, Object?>{'type': 'category'},
    '_value_': <String, Object?>{'type': 'linear'},
  },
});

/// The test controller `linearTest` of the generator: linear on both axes.
final JsClass _linearTestController = cartesianTestController('linearTest', {
  'scales': <String, Object?>{
    '_index_': <String, Object?>{'type': 'linear'},
    '_value_': <String, Object?>{'type': 'linear'},
  },
});

/// The values of the observation `pixelForValue`: `pixelValues` of the
/// generator. The integers below 1e6 are Dart `int` values: they take the
/// literal lines of [LinearScale.getPixelForValue], not the fast path. The
/// other numbers are `double` values: they take the fast path. The JS Date
/// is a `DateTime` (Chart.js ADR 0024).
final List<Object?> _pixelValues = [
  0,
  1,
  -1,
  5,
  1e6,
  -2.5,
  null,
  undefined,
  double.nan,
  double.infinity,
  double.negativeInfinity,
  '5',
  ' 12.5 ',
  '0x10',
  'abc',
  '',
  true,
  false,
  <Object?>[7.0],
  <String, Object?>{},
  DateTime.fromMillisecondsSinceEpoch(7, isUtc: true),
];

/// The observations of a linear scale: `linearObservations` of the
/// generator, with the same keys and the same calls.
Map<String, Object?> _linearObservations(Scale scale, Chart chart) {
  if (scale is! LinearScale) return const {};
  final horizontal = scale.isHorizontal();
  final start = horizontal ? scale.left : scale.top;
  final end = horizontal ? scale.right : scale.bottom;
  return {
    'startValue': scale.startValue,
    'endValue': scale.endValue,
    'valueRange': scale.valueRange,
    'tickLimit': scale.getTickLimit(),
    'pixelForValue': [for (final v in _pixelValues) scale.getPixelForValue(v)],
    'valuesForPixels': [
      for (final p in [start - 50, start + 0.37 * (end - start), end + 50])
        scale.getValueForPixel(p),
    ],
  };
}

/// The options of the scale [id] in the config of [chart], as a Map.
Map<String, Object?> _scaleConfig(Chart chart, String id) {
  final scales = chart.config.options['scales']! as Map<String, Object?>;
  return scales[id]! as Map<String, Object?>;
}

/// The actions of the action cases of the generator (`runActionCase`), by
/// the case name. Each one changes the chart and calls `chart.update()`.
final Map<String, void Function(Chart chart)> _actions = {
  'stacked and beginAtZero after the creation': (chart) {
    _scaleConfig(chart, 'y')['stacked'] = true;
    chart.update();
    _scaleConfig(chart, 'y')['beginAtZero'] = true;
    chart.update();
  },
  'a dataset hidden after the creation': (chart) {
    chart
      ..setDatasetVisibility(1, false)
      ..update();
  },
  'maxTicksLimit, stepSize, min and max after the creation': (chart) {
    _scaleConfig(chart, 'y')
      ..['ticks'] = <String, Object?>{'maxTicksLimit': 11.0, 'stepSize': 0.01}
      ..['min'] = 0.3
      ..['max'] = 2.8;
    chart.update();
  },
  'reverse after the creation': (chart) {
    _scaleConfig(chart, 'x')['reverse'] = true;
    chart.update();
  },
};

/// The named functions of the configs of the generator.
final Map<String, Object?> _functions = {
  'indexLabel': (Object? value, Object? index) => jsToString(index),
  'withUnit': (Object? value) => '${jsToString(value)} kg',
  'labelOfThis': JsFunction(
    (Object? self, Object? value) =>
        '[${jsToString((self! as Scale).getLabelForValue(value))}]',
  ),
};

/// A chart of the test controller `linearTest` with the points [points]
/// and the options [options].
Chart _linearChart(List<Object?> points, [AnyObject? options]) => acquireChart({
  'type': 'linearTest',
  'data': <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{'data': points},
    ],
  },
  'options': ?options,
});

/// The points of the case 'objects on two linear axes' of the generator.
List<Object?> _scatter() => <Object?>[
  <String, Object?>{'x': 10.0, 'y': 100.0},
  <String, Object?>{'x': -10.0, 'y': 0.0},
  <String, Object?>{'x': 0.0, 'y': 0.0},
  <String, Object?>{'x': 99.0, 'y': 7.0},
];

/// The linear scale [id] of [chart].
LinearScale _scale(Chart chart, String id) => chart.scales[id]! as LinearScale;

/// A matcher of [pixel]: [isNaN] for NaN, else [equals].
Matcher _samePixel(double pixel) => pixel.isNaN ? isNaN : equals(pixel);

void main() {
  // Before the snapshot of the defaults restore (Chart.js ADR 0022, section
  // 8). The restore does not reset the items of the registry.
  Chart.register([
    CategoryScale.jsClass,
    LinearScale.jsClass,
    scaleTestController,
    _scaleTest2Controller,
    _linearTestController,
  ]);

  testReferenceOrigin(
    node: scaleLinearReferenceNode,
    arch: scaleLinearReferenceArch,
    dist: scaleLinearReferenceDist,
    commit: scaleLinearReferenceCommit,
  );

  group('the class value (Chart.js ADR 0020)', () {
    test('the registry gives the class value of the id linear', () {
      // scale.linear.tests.js:8-12.
      final scale = registry.getScale('linear');
      expect(scale, same(LinearScale.jsClass));
      expect(jsTypeof(scale), 'function');
      expect(LinearScale.jsClass['id'], 'linear');
      expect(LinearScale.jsClass['defaults'], same(LinearScale.defaults));
      expect(LinearScale.jsClass.superclass, same(LinearScaleBase.jsClass));
    });

    test('defaults.scales.linear has the numeric tick callback', () {
      // scale.linear.tests.js:14-18: the callback is the function object of
      // Ticks.formatters.numeric.
      final scales = defaults['scales']! as Map<String, Object?>;
      final linear = scales['linear']! as Map<String, Object?>;
      expect(linear.keys, ['ticks']);
      final ticks = linear['ticks']! as Map<String, Object?>;
      expect(ticks.keys, ['callback']);
      expect(ticks['callback'], same(formatters['numeric']));
      expect(jsTypeof(ticks['callback']), 'function');
    });

    testWidgets('jsConstruct makes a LinearScale from the cfg object', (
      tester,
    ) async {
      final chart = _linearChart(_scatter());
      final scale = jsConstruct(LinearScale.jsClass, [
        <String, Object?>{
          'id': 'z',
          'type': 'linear',
          'ctx': null,
          'chart': chart,
        },
      ]);
      expect(scale, isA<LinearScale>());
      expect((scale as LinearScale).id, 'z');
      expect(scale.startValue, isNaN);
      expect(scale.valueRange, 0);
    });
  });

  group('linear scale charts against upstream', () {
    test('each action names a case', () {
      final names = [for (final c in scaleLinearReference) c.name];
      expect(_actions.keys, everyElement(isIn(names)));
    });

    for (final c in scaleLinearReference) {
      testWidgets(c.name, (tester) async {
        final chart = acquireChart(
          copyReference(c.config, _functions)! as AnyObject,
          copyReference(c.options)! as AnyObject,
        );
        _actions[c.name]?.call(chart);
        expectScaleChart(chart, c.expected, extra: _linearObservations);
      });
    }
  });

  group('fast path (Chart.js ADR 0025)', () {
    for (final (name, options) in <(String, AnyObject)>[
      ('a horizontal scale', <String, Object?>{}),
      (
        'a reversed vertical scale with offset',
        <String, Object?>{
          'scales': <String, Object?>{
            'y': <String, Object?>{'reverse': true, 'offset': true},
          },
        },
      ),
    ]) {
      testWidgets('a double and an int give the same pixel, $name', (
        tester,
      ) async {
        final chart = _linearChart(_scatter(), options);
        for (final id in ['x', 'y']) {
          final s = _scale(chart, id);
          final min = s.min;
          final max = s.max;
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
            3.0,
            -7.0,
            100.0,
          ]) {
            final pixel = s.getPixelForValue(value);
            expect(
              pixel,
              _samePixel(
                s.getPixelForDecimal((value - s.startValue) / s.valueRange),
              ),
              reason: '$id: $value',
            );
            if (value.isFinite && value == value.truncateToDouble()) {
              expect(
                s.getPixelForValue(value.toInt()),
                _samePixel(pixel),
                reason: '$id: ${value.toInt()} as an int',
              );
            }
          }
        }
      });
    }
  });

  group('value types (Chart.js ADR 0025)', () {
    testWidgets('null gives NaN', (tester) async {
      final y = _scale(_linearChart(_scatter()), 'y');
      expect(y.getPixelForValue(null), isNaN);
      expect(y.getPixelForValue(null, 0), isNaN);
    });

    testWidgets("undefined and 'B' give NaN", (tester) async {
      final y = _scale(_linearChart(_scatter()), 'y');
      expect(y.getPixelForValue(undefined), isNaN);
      expect(y.getPixelForValue('B'), isNaN);
    });

    testWidgets("'5' and 5 give the same pixel", (tester) async {
      final y = _scale(_linearChart(_scatter()), 'y');
      expect(y.getPixelForValue('5'), y.getPixelForValue(5.0));
      expect(y.getPixelForValue('5'), y.getPixelForValue(5));
      expect(y.getPixelForValue('5'), isNot(isNaN));
    });

    testWidgets('true equals 1 and false equals 0', (tester) async {
      final y = _scale(_linearChart(_scatter()), 'y');
      expect(y.getPixelForValue(true), y.getPixelForValue(1.0));
      expect(y.getPixelForValue(false), y.getPixelForValue(0.0));
    });

    testWidgets('getValueForPixel inverts getPixelForValue', (tester) async {
      final chart = _linearChart(_scatter());
      for (final id in ['x', 'y']) {
        final s = _scale(chart, id);
        for (final value in [s.min, s.max, (s.min + s.max) / 2, 17.25]) {
          expect(
            s.getValueForPixel(s.getPixelForValue(value)),
            closeTo(value, 1e-9),
            reason: '$id: $value',
          );
        }
      }
    });
  });

  group('Liberation Sans widths of the generator', () {
    testReferenceWidths(scaleLinearReferenceWidths);
  });
}
