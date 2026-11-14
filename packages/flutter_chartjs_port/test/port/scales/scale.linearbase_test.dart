// Original code, not ported from Chart.js: linear scale base tests.
@TestOn('vm')
library;

import 'dart:math' as math;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/core/core.ticks.dart' show formatters;
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show isFinite;
import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart'
    show toRadians;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/scales/scale.linearbase.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/tick_label.dart';
import 'scale_chart_harness.dart';

// The port-only tests of `LinearScaleBase` (scale.linearbase.js). Upstream
// has no spec for this file, and the class has no reference test: the
// linear and radial linear scale reference tests examine its two real
// subclasses. These tests pin the class value, `prototypeParse` and the row
// `adapt-linearbase-tick-bounds`.
//
// The test scales extend LinearScaleBase: `testLinearBase` (the data limits
// and the pixel mapping of the linear scale, scale.linear.js:20-50, and the
// computeTickLimit of LinearScaleBase) and `testLinearBaseLimit` (also the
// computeTickLimit of the linear scale, scale.linear.js:34-41). The
// cartesian test controller `linearBaseChart` puts testLinearBase on both
// axes. main() registers the three classes through their class values,
// before the snapshot of the defaults restore (Chart.js ADR 0020, section 8,
// and Chart.js ADR 0022, section 8).

/// The test scale `testLinearBase`: [LinearScaleBase] with
/// the data limits and the pixel mapping of the linear scale
/// (scale.linear.js:20-50).
class _TestLinearBaseScale(super.cfg) extends LinearScaleBase {
  @override
  void determineDataLimits() {
    final (:min, :max) = getMinMax(true);
    this.min = isFinite(min) ? min : 0;
    this.max = isFinite(max) ? max : 1;
    handleTickRangeOptions();
  }

  @override
  double getPixelForValue(Object? value, [int? index]) {
    return value == null
        ? double.nan
        : getPixelForDecimal((jsToNumber(value) - startValue) / valueRange);
  }

  @override
  double getValueForPixel(double pixel) {
    return startValue + getDecimalForPixel(pixel) * valueRange;
  }
}

/// The class value of `testLinearBase`.
final JsClass _testLinearBaseScale = JsClass(
  'TestLinearBaseScale',
  superclass: LinearScaleBase.jsClass,
  statics: {
    'id': 'testLinearBase',
    'defaults': <String, Object?>{
      'ticks': <String, Object?>{'callback': formatters['numeric']},
    },
  },
  construct: (newTarget, args) => _TestLinearBaseScale(scaleCfgArg(args)),
);

/// The test scale `testLinearBaseLimit`: `testLinearBase`
/// with the computeTickLimit of the linear scale (scale.linear.js:34-41).
final class _TestLinearBaseLimitScale(super.cfg) extends _TestLinearBaseScale {
  @override
  double computeTickLimit() {
    final horizontal = isHorizontal();
    final length = horizontal ? width : height;
    final minRotation = toRadians(
      jsToNumber(jsGet(options['ticks'], 'minRotation')),
    );
    final sinOrCos = horizontal ? math.sin(minRotation) : math.cos(minRotation);
    final ratio = jsTruthy(sinOrCos) ? sinOrCos : 0.001;
    final tickFont = resolveTickFontOptions(0);
    return (length /
            math.min<double>(40, jsToNumber(tickFont.lineHeight) / ratio))
        .ceilToDouble();
  }
}

/// The class value of `testLinearBaseLimit`.
final JsClass _testLinearBaseLimitScale = JsClass(
  'TestLinearBaseLimitScale',
  superclass: _testLinearBaseScale,
  statics: {'id': 'testLinearBaseLimit', 'defaults': <String, Object?>{}},
  construct: (newTarget, args) => _TestLinearBaseLimitScale(scaleCfgArg(args)),
);

/// The cartesian test controller `linearBaseChart`.
final JsClass _linearBaseChartController = cartesianTestController(
  'linearBaseChart',
  {
    'scales': <String, Object?>{
      '_index_': <String, Object?>{'type': 'testLinearBase'},
      '_value_': <String, Object?>{'type': 'testLinearBase'},
    },
  },
);

/// The JS values of the parse tests.
final List<Object?> _parseValues = [
  null,
  undefined,
  double.nan,
  double.infinity,
  double.negativeInfinity,
  12.0,
  -0.0,
  '12.5',
  ' 0x1A ',
  'Infinity',
  'abc',
  '',
  true,
  false,
  <Object?>[7.0],
  <String, Object?>{},
];

void main() {
  // Before the snapshot of the defaults restore (Chart.js ADR 0022, section
  // 8). The restore does not reset the items of the registry.
  Chart.register([
    _testLinearBaseScale,
    _testLinearBaseLimitScale,
    _linearBaseChartController,
  ]);

  group('the class value', () {
    test('LinearScaleBase.jsClass extends Scale.jsClass without statics', () {
      final value = LinearScaleBase.jsClass;
      expect(value.name, 'LinearScaleBase');
      expect(identical(value.superclass, Scale.jsClass), isTrue);
      // `'id' in LinearScaleBase` is false: the registry does not register
      // it as a component (core.typedRegistry.js:115-116).
      expect(value.id, same(undefined));
      expect(value['defaults'], same(Scale.jsClass['defaults']));
    });

    testWidgets('jsConstruct makes a LinearScaleBase from the cfg object', (
      tester,
    ) async {
      final chart = acquireChart(_config({}));
      final scale = jsConstruct(LinearScaleBase.jsClass, [
        <String, Object?>{
          'id': 'z',
          'type': 'testLinearBase',
          'ctx': null,
          'chart': chart,
        },
      ]);
      expect(scale, isA<LinearScaleBase>());
      expect((scale as LinearScaleBase).id, 'z');
      // scale.linearbase.js:159-167: the start values.
      expect(scale.start, isNaN);
      expect(scale.end, isNaN);
      expect(scale.startValue, isNaN);
      expect(scale.endValue, isNaN);
      expect(scale.valueRange, 0);
    });

    test('the registry has the test scales and not LinearScaleBase', () {
      final items = Chart.registry.scales.items;
      expect(items['testLinearBase'], same(_testLinearBaseScale));
      expect(items['testLinearBaseLimit'], same(_testLinearBaseLimitScale));
      expect(items.values, isNot(contains(same(LinearScaleBase.jsClass))));
    });
  });

  group('prototypeParse', () {
    testWidgets('parse is the body of LinearScaleBase.prototype.parse', (
      tester,
    ) async {
      // scale.logarithmic.js:104 calls the body with apply.
      final chart = acquireChart(_config({}));
      final scale = chart.scales['y']! as LinearScaleBase;
      for (final value in _parseValues) {
        final parsed = scale.parse(value, 0);
        final prototype = LinearScaleBase.prototypeParse(value, 0);
        if (parsed is double && parsed.isNaN) {
          expect(prototype, isNaN, reason: '$value');
        } else {
          expect(prototype, parsed, reason: '$value');
        }
      }
      expect(LinearScaleBase.prototypeParse(5), 5);
      expect(LinearScaleBase.prototypeParse(double.nan), isNull);
    });
  });

  group('adapt-linearbase-tick-bounds', () {
    // generateTicks gives the raw `min` and `max` options to the bound ticks
    // (scale.linearbase.js:111, :136, :138). Upstream keeps a string bound
    // as a string tick value. The port keeps its ToNumber: `Tick.value` is
    // a number (index.d.ts:1195). The probe of a build of the pinned
    // Chart.js on x64 Node.js v24.12.0 gave the upstream values of these
    // cases.
    const values = [0.0, 20.0, 40.0, 60.0, 80.0, 100.0];

    testWidgets('a string bound gives its number as the tick value', (
      tester,
    ) async {
      final chart = acquireChart(
        _config({
          'y': <String, Object?>{'min': '-15', 'max': '110'},
        }),
      );
      final scale = chart.scales['y']!;
      expect(scale.min, -15);
      expect(scale.max, 110);
      // Upstream: the values '-15' and '110' (strings).
      expect([for (final t in scale.ticks!) t.value], [-15, ...values, 110]);
      // Upstream: '-15.00000000000000000000' and '110.00000000000000000000'.
      // The numeric formatter compares the string value with its floor
      // (core.ticks.js:91), and the delta becomes 0.
      expect(
        [for (final t in scale.ticks!) upstreamTickLabel(t)],
        ['-15', '0', '20', '40', '60', '80', '100', '110'],
      );
    });

    for (final ticks in <Map<String, Object?>>[
      {'stepSize': 25.0},
      {'count': 6.0},
    ]) {
      testWidgets('string bounds with $ticks give the NaN ticks of upstream', (
        tester,
      ) async {
        // The cases 1 and 2 assign the raw bounds to niceMin and niceMax.
        // `_decimalPlaces('-15')` is undefined, so the factor is NaN, as
        // upstream gives.
        final chart = acquireChart(
          _config({
            'y': <String, Object?>{'min': '-15', 'max': '110', 'ticks': ticks},
          }),
        );
        final scale = chart.scales['y']!;
        final tickValues = [for (final t in scale.ticks!) t.value];
        expect(tickValues, hasLength(7));
        // Upstream: the values '-15' and '110' (strings).
        expect(tickValues.first, -15);
        expect(tickValues.last, 110);
        expect(tickValues.sublist(1, 6), everyElement(isNaN));
        // The labels of upstream.
        expect(
          [for (final t in scale.ticks!) upstreamTickLabel(t)],
          ['-15.0', 'NaN', 'NaN', 'NaN', 'NaN', 'NaN', '110.0'],
        );
      });
    }

    testWidgets('number bounds give number tick values', (tester) async {
      final chart = acquireChart(
        _config({
          'y': <String, Object?>{'min': -15, 'max': 110},
        }),
      );
      expect(
        [for (final t in chart.scales['y']!.ticks!) upstreamTickLabel(t)],
        ['-15', '0', '20', '40', '60', '80', '100', '110'],
      );
    });
  });
}

/// A chart config of the test controller with the scale options [scales].
AnyObject _config(Map<String, Object?> scales) => <String, Object?>{
  'type': 'linearBaseChart',
  'data': <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{
        'data': <Object?>[
          <String, Object?>{'x': -12.5, 'y': 3.0},
          <String, Object?>{'x': 40.0, 'y': 117.0},
          <String, Object?>{'x': 7.25, 'y': -20.0},
        ],
      },
    ],
  },
  'options': <String, Object?>{'scales': scales},
};
