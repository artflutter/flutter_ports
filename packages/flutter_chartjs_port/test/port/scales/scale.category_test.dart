// Original code, not ported from Chart.js: category scale reference tests.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart' show defaults;
import 'package:flutter_chartjs_port/src/core/core.registry.dart' show registry;
import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/scales/scale.category.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_test/flutter_test.dart';

import 'scale_category_reference.dart';
import 'scale_chart_harness.dart';

// The port-only tests of lib/src/scales/scale.category.dart.
//
// The reference group compares real charts with the charts of
// tool/reference/scale_category_reference.mjs: a build of the pinned
// Chart.js in Node.js v24.22.1 on arm64 (Chart.js ADR 0045), with a mock
// context that measures text in Liberation Sans 2.1.5, the test font of the
// harness (scale_chart_harness.dart, tool/reference/scale_chart_common.mjs).
// Each chart comes from acquireChart in a testWidgets case (Chart.js ADR
// 0022).
//
// The value axis is the test scale `testLinear` of the generator. Thus the
// test sets the mapping of the value axis, and only the category scale of
// the port is under test. The cartesian test controller `categoryTest` has
// the category scale on the index axis. flutter_test_config.dart registers
// the built-in components before main(), and the category scale is one of
// them (`harness-register-builtins`). The generator registers the same
// built-in components and the seven plugins of the dist (registerBuiltins,
// Chart.js ADR 0041, section 1). main() registers
// only the test scale and the test controller through their class values,
// before the snapshot of the defaults restore (Chart.js ADR 0020, section 8,
// and Chart.js ADR 0022, section 8).
//
// The cases with Date labels pin the strict equality `===` of
// scale.category.js:15, :19 and :75: a copy of a label Date is not the
// label. Their actions put a DateTime for each label time in the labels, and
// [_dateObservations] parses copies of the labels.
//
// The groups of Chart.js ADR 0025 pin the fast path of getPixelForValue
// (section 3) and the relations of the value types (section 9) without
// generated values. The group js-semantics-narrow-labels pins the row of
// differences.md: a labels List with a narrow element type.

/// The test scale `testLinear` of the generator: the range of the data
/// (`getMinMax`), five ticks at equal steps from min to max, and a linear
/// mapping.
final class _TestLinearScale extends Scale {
  _TestLinearScale(super.cfg);

  @override
  void determineDataLimits() {
    final (:min, :max) = getMinMax(false);
    this.min = min;
    this.max = max;
  }

  @override
  List<Tick>? buildTicks() => [
    for (var i = 0; i <= 4; i++) Tick(value: min + ((max - min) * i) / 4),
  ];

  @override
  double getPixelForValue(Object? value, [double? index]) {
    return getPixelForDecimal((jsToNumber(value) - min) / (max - min));
  }

  @override
  double getValueForPixel(double pixel) {
    return min + getDecimalForPixel(pixel) * (max - min);
  }
}

/// `class TestLinearScale extends Scale` of the generator.
final JsClass _testLinearScale = JsClass(
  'TestLinearScale',
  superclass: Scale.jsClass,
  statics: {'id': 'testLinear', 'defaults': <String, Object?>{}},
  construct: (newTarget, args) => _TestLinearScale(scaleCfgArg(args)),
);

/// The cartesian test controller `categoryTest` of the generator: category
/// on the index axis and `testLinear` on the value axis.
final JsClass _categoryTestController = cartesianTestController(
  'categoryTest',
  {
    'scales': <String, Object?>{
      '_index_': <String, Object?>{'type': 'category'},
      '_value_': <String, Object?>{'type': 'testLinear'},
    },
  },
);

/// The observations of a category scale: `categoryObservations` of the
/// generator, with the same keys and the same calls. The integer values are
/// Dart `int` values: they take the literal lines of
/// [CategoryScale.getPixelForValue], not the fast path.
Map<String, Object?> _categoryObservations(Scale scale, Chart chart) {
  if (scale is! CategoryScale) return const {};
  final labels = List<Object?>.of(scale.getLabels());
  final n = labels.length;
  final horizontal = scale.isHorizontal();
  final start = horizontal ? scale.left : scale.top;
  final end = horizontal ? scale.right : scale.bottom;
  return {
    'labels': labels,
    'labelForValue': [
      for (final v in <Object?>[0, 1, 1.5, '1', -1, n, 'x', true, null])
        scale.getLabelForValue(v),
    ],
    'parse': [
      for (final v in <Object?>[
        -10,
        -0.1,
        4.1,
        5,
        1,
        1.4,
        1.5,
        double.nan,
        double.infinity,
        double.negativeInfinity,
        true,
        false,
        null,
        undefined,
      ])
        scale.parse(v),
    ],
    'pixelForValue': [
      for (final v in <Object?>[
        0,
        1,
        2.5,
        -1,
        n,
        null,
        undefined,
        double.nan,
        true,
        double.infinity,
      ])
        scale.getPixelForValue(v),
    ],
    'pixelForLabel': [
      for (final label in labels) scale.getPixelForValue(label),
    ],
    'valuesForPixels': [
      for (final p in [start - 50, start + 0.37 * (end - start), end + 50])
        scale.getValueForPixel(p),
    ],
    'tickPixelsOutside': [
      scale.getPixelForTick(-1),
      scale.getPixelForTick(scale.ticks!.length),
    ],
  };
}

/// `addingObservations` of the generator: [_categoryObservations], then
/// `getPixelForValue` of 'zz', '1' and 'zz' again, and the labels after the
/// calls.
Map<String, Object?> _addingObservations(Scale scale, Chart chart) {
  final observations = _categoryObservations(scale, chart);
  if (scale is! CategoryScale) return observations;
  return {
    ...observations,
    'pixelForNewLabels': [
      for (final v in ['zz', '1', 'zz']) scale.getPixelForValue(v),
    ],
    'labelsAfter': List<Object?>.of(scale.getLabels()),
  };
}

/// A copy of the label Date [label]: a new DateTime with the same time, as
/// `new Date(d.getTime())` of the generator.
DateTime _copyOf(Object? label) => DateTime.fromMillisecondsSinceEpoch(
  (label! as DateTime).millisecondsSinceEpoch,
  isUtc: true,
);

/// `dateObservations` of the generator: the observations of a category
/// scale with Date labels, with the same keys and the same calls. A copy of
/// a label is not the label: `===` compares two Dates by identity.
Map<String, Object?> _dateObservations(Scale scale, Chart chart) {
  if (scale is! CategoryScale) return const {};
  final labels = List<Object?>.of(scale.getLabels());
  final copies = [for (final label in labels) _copyOf(label)];
  return {
    'labelTimes': [
      for (final label in labels)
        (label! as DateTime).millisecondsSinceEpoch.toDouble(),
    ],
    'parseLabel': [for (final label in labels) scale.parse(label)],
    'parseLabelAt0': [for (final label in labels) scale.parse(label, 0)],
    'parseCopy': [for (final copy in copies) scale.parse(copy)],
    'parseCopyAt0': [for (final copy in copies) scale.parse(copy, 0)],
    'pixelForLabel': [
      for (final label in labels) scale.getPixelForValue(label),
    ],
    'pixelForCopy': [for (final copy in copies) scale.getPixelForValue(copy)],
  };
}

/// The observations of each case that does not take [_categoryObservations],
/// by the case name.
///
/// The cases 'a y axis at the position of a label' and 'a y axis at the
/// position null' take [_categoryObservations]: [observeChart] records an
/// object position as a plain Map of the own keys of its resolver, as
/// `jsonValue` of scale_chart_common.mjs does.
final Map<String, ScaleObservations> _extras = {
  'getPixelForValue of strings that are not labels': _addingObservations,
  'Date labels and object data with copies of the labels': _dateObservations,
  'Date labels and a copy of a label as min': _dateObservations,
};

/// `dateLabels` of the generator: puts a DateTime for each time of the
/// labels of [chart] in the labels, and returns the labels.
List<Object?> _dateLabels(Chart chart) {
  final labels = (chart.data as AnyObject)['labels']! as List<Object?>;
  for (var i = 0; i < labels.length; i++) {
    labels[i] = DateTime.fromMillisecondsSinceEpoch(
      (labels[i]! as double).toInt(),
      isUtc: true,
    );
  }
  return labels;
}

/// The dataset [index] of [chart], as a Map.
Map<String, Object?> _dataset(Chart chart, int index) =>
    ((chart.data as AnyObject)['datasets']! as List<Object?>)[index]!
        as Map<String, Object?>;

/// The actions of the action cases of the generator (`runActionCase`), by
/// the case name. Each one changes the chart and calls `chart.update()`.
final Map<String, void Function(Chart chart)> _actions = {
  'the next update removes the added labels': (chart) {
    _dataset(chart, 0)['data'] = <Object?>[
      <String, Object?>{'x': 'a', 'y': 1.0},
      <String, Object?>{'x': 'b', 'y': 2.0},
    ];
    chart.update();
  },
  'the next update keeps the added labels at other indexes': (chart) {
    ((chart.data as AnyObject)['labels']! as List<Object?>).insert(0, 'z');
    chart.update();
  },
  'the next update removes a string min': (chart) {
    final scales =
        (chart.config.options as AnyObject)['scales']! as JsObjectFace;
    (scales['x']! as JsObjectFace)['min'] = 'b';
    chart.update();
  },
  'the next update removes the label of getPixelForValue': (chart) {
    chart.scales['x']!.getPixelForValue('D');
    chart.update();
  },
  'bounds data, then bounds ticks': (chart) {
    final scales =
        (chart.config.options as AnyObject)['scales']! as JsObjectFace;
    (scales['x']! as JsObjectFace)['bounds'] = 'ticks';
    chart.update();
  },
  'a later update keeps a label that the user adds': (chart) {
    _dataset(chart, 0)['data'] = <Object?>[
      <String, Object?>{'x': 'a', 'y': 1.0},
      <String, Object?>{'x': 'b', 'y': 2.0},
    ];
    chart.update();
    ((chart.data as AnyObject)['labels']! as List<Object?>).add('d');
    chart.update();
  },
  'the next update keeps a label that parse adds to options.labels': (chart) {
    chart.update();
  },
  'Date labels and object data with copies of the labels': (chart) {
    final labels = _dateLabels(chart);
    _dataset(chart, 0)['data'] = <Object?>[
      <String, Object?>{'x': _copyOf(labels[2]), 'y': 1.0},
      <String, Object?>{'x': _copyOf(labels[0]), 'y': 2.0},
      <String, Object?>{'x': labels[1], 'y': 3.0},
    ];
    chart.update();
  },
  'Date labels and a copy of a label as min': (chart) {
    final labels = _dateLabels(chart);
    final scales =
        (chart.config.options as AnyObject)['scales']! as JsObjectFace;
    (scales['x']! as JsObjectFace)['min'] = _copyOf(labels[1]);
    chart.update();
  },
};

/// The named functions of the configs of the generator.
final Map<String, Object?> _functions = {
  'upperLabel': JsFunction(
    (Object? self, Object? value) =>
        jsToString((self! as Scale).getLabelForValue(value)).toUpperCase(),
  ),
  'indexLabel': jsToString,
};

/// A chart of the test controller with the labels A, B and C, and the
/// options [options].
Chart _abcChart([AnyObject? options]) => acquireChart({
  'type': 'categoryTest',
  'data': <String, Object?>{
    'labels': <Object?>['A', 'B', 'C'],
    'datasets': <Object?>[
      <String, Object?>{
        'data': <Object?>[1.0, 3.0, 2.0],
      },
    ],
  },
  'options': ?options,
});

/// The category scale `x` of [chart].
CategoryScale _x(Chart chart) => chart.scales['x']! as CategoryScale;

/// A matcher of [pixel]: [isNaN] for NaN, else [equals].
Matcher _samePixel(double pixel) => pixel.isNaN ? isNaN : equals(pixel);

void main() {
  // Before the snapshot of the defaults restore (Chart.js ADR 0022, section
  // 8). The restore does not reset the items of the registry.
  // flutter_test_config.dart registers the category scale.
  Chart.register([_testLinearScale, _categoryTestController]);

  testReferenceOrigin(
    node: scaleCategoryReferenceNode,
    arch: scaleCategoryReferenceArch,
    dist: scaleCategoryReferenceDist,
    commit: scaleCategoryReferenceCommit,
  );

  group('the class value (Chart.js ADR 0020)', () {
    test('the registry gives the class value of the id category', () {
      expect(registry.getScale('category'), same(CategoryScale.jsClass));
      expect(CategoryScale.jsClass['id'], 'category');
      expect(CategoryScale.jsClass['defaults'], same(CategoryScale.defaults));
      expect(CategoryScale.jsClass.superclass, same(Scale.jsClass));
    });

    test('defaults.scales.category has the tick callback only', () {
      final scales = defaults['scales']! as JsObjectFace;
      final category = scales['category']! as JsObjectFace;
      expect(category.jsKeys(), ['ticks']);
      final ticks = category['ticks']! as JsObjectFace;
      expect(ticks.jsKeys(), ['callback']);
      expect(
        ticks['callback'],
        same(jsGet(CategoryScale.defaults['ticks'], 'callback')),
      );
    });
  });

  group('category scale charts against upstream', () {
    test('each action and observation names a case', () {
      final names = [for (final c in scaleCategoryReference) c.name];
      expect(_actions.keys, everyElement(isIn(names)));
      expect(_extras.keys, everyElement(isIn(names)));
    });

    for (final c in scaleCategoryReference) {
      testWidgets(c.name, (tester) async {
        final chart = acquireChart(
          copyReference(c.config, _functions)! as AnyObject,
          copyReference(c.options)! as AnyObject,
        );
        _actions[c.name]?.call(chart);
        expectScaleChart(
          chart,
          c.expected,
          extra: _extras[c.name] ?? _categoryObservations,
        );
      });
    }
  });

  group('fast path (Chart.js ADR 0025)', () {
    // Without offset, the labels A, B and C give the start value 0 and the
    // value range 2. With offset, they give -0.5 and 3.
    for (final (offset, startValue, valueRange) in [
      (false, 0.0, 2.0),
      (true, -0.5, 3.0),
    ]) {
      testWidgets('a double and an int give the same pixel, offset $offset', (
        tester,
      ) async {
        final x = _x(
          _abcChart({
            'scales': <String, Object?>{
              'x': <String, Object?>{'offset': offset},
            },
          }),
        );
        final min = x.min;
        final max = x.max;
        expect((min, max), (0.0, 2.0));
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
        ]) {
          final pixel = x.getPixelForValue(value);
          expect(
            pixel,
            _samePixel(x.getPixelForDecimal((value - startValue) / valueRange)),
            reason: '$value',
          );
          if (value.isFinite && value == value.truncateToDouble()) {
            expect(
              x.getPixelForValue(value.toInt()),
              _samePixel(pixel),
              reason: '${value.toInt()} as an int',
            );
          }
        }
      });
    }
  });

  group('value types (Chart.js ADR 0025)', () {
    testWidgets('a label gives the pixel of its index', (tester) async {
      final x = _x(_abcChart());
      expect(x.getPixelForValue('B'), x.getPixelForValue(1.0));
      expect(x.getPixelForValue('B'), x.getPixelForValue(1));
      expect(x.getPixelForValue('C'), x.getPixelForValue(2.0));
      expect(x.getLabels(), ['A', 'B', 'C']);
    });

    testWidgets('null, undefined and NaN give NaN', (tester) async {
      final x = _x(_abcChart());
      expect(x.getPixelForValue(null), isNaN);
      expect(x.getPixelForValue(undefined), isNaN);
      expect(x.getPixelForValue(double.nan), isNaN);
      expect(x.getLabels(), ['A', 'B', 'C']);
    });

    testWidgets('a string that is not a label adds a label', (tester) async {
      final x = _x(_abcChart());
      expect(x.getPixelForValue('D'), x.getPixelForValue(3.0));
      expect(x.getLabels(), ['A', 'B', 'C', 'D']);
    });

    testWidgets("'1' adds the label '1' and is not the index 1", (
      tester,
    ) async {
      final x = _x(_abcChart());
      final pixel = x.getPixelForValue('1');
      expect(pixel, x.getPixelForValue(3.0));
      expect(pixel, isNot(x.getPixelForValue(1.0)));
      expect(x.getLabels(), ['A', 'B', 'C', '1']);
    });

    testWidgets('a y axis at the position of a label', (tester) async {
      final chart = _abcChart({
        'scales': <String, Object?>{
          'y': <String, Object?>{
            'position': <String, Object?>{'x': 'B'},
          },
        },
      });
      final pixel = _x(chart).getPixelForValue('B');
      final items = chart.scales['y']!.getLabelItems();
      expect(items, isNotEmpty);
      for (final item in items) {
        expect(item.options.translation!.$1, pixel);
      }
    });

    testWidgets('a y axis at the position null', (tester) async {
      final chart = _abcChart({
        'scales': <String, Object?>{
          'y': <String, Object?>{
            'position': <String, Object?>{'x': null},
          },
        },
      });
      final items = chart.scales['y']!.getLabelItems();
      expect(items, isNotEmpty);
      for (final item in items) {
        expect(item.options.translation!.$1, isNaN);
      }
    });
  });

  // differences.md row js-semantics-narrow-labels. The reference case
  // 'numeric string data on numeric labels' gives the upstream result for
  // labels of the runtime type of a growable List<Object?>.
  group('js-semantics-narrow-labels', () {
    /// A chart of the test controller with the labels [labels] and the data
    /// item `{x: x, y: 1}`.
    Chart labelsChart(List<Object?> labels, Object? x) => acquireChart({
      'type': 'categoryTest',
      'data': <String, Object?>{
        'labels': labels,
        'datasets': <Object?>[
          <String, Object?>{
            'data': <Object?>[
              <String, Object?>{'x': x, 'y': 1.0},
            ],
          },
        ],
      },
    });

    testWidgets('a List<int> of labels throws at a string that is not a '
        'label', (tester) async {
      expect(
        () => labelsChart(<int>[2020, 2021, 2022], '2021'),
        throwsA(isA<TypeError>()),
      );
    });

    testWidgets('a List<int> of labels finds a number', (tester) async {
      final chart = labelsChart(<int>[2020, 2021, 2022], 2022.0);
      final x = _x(chart);
      // The item 0 has the label 2022: parse gives its index 2, and no
      // label is added.
      expect(x.parse(2022.0, 0), 2.0);
      expect(x.parse(1999.0), 2.0);
      expect(x.getLabels(), [2020, 2021, 2022]);
      expect(
        chart.getDatasetMeta(0).data.single.x,
        x.getPixelForValue(2.0),
      );
    });

    testWidgets('a List of labels that cannot grow throws at a string that '
        'is not a label', (tester) async {
      for (final labels in <List<Object?>>[
        const <Object?>['a', 'b'],
        List<Object?>.unmodifiable(['a', 'b']),
        List<Object?>.filled(2, 'a'),
      ]) {
        expect(
          () => labelsChart(labels, 'c'),
          throwsA(isA<UnsupportedError>()),
        );
      }
    });

    testWidgets('a List<String> of labels takes the strings that parse '
        'adds', (tester) async {
      final x = _x(labelsChart(<String>['a', 'b', 'c'], 'd'));
      expect(x.getLabels(), ['a', 'b', 'c', 'd']);
      expect(x.getPixelForValue('d'), x.getPixelForValue(3.0));
    });
  });

  group('Liberation Sans widths of the generator', () {
    testReferenceWidths(scaleCategoryReferenceWidths);
  });
}
