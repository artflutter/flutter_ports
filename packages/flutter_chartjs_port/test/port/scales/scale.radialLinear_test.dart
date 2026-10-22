// Original code, not ported from Chart.js: radial linear scale reference tests.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart' show defaults;
import 'package:flutter_chartjs_port/src/core/core.registry.dart' show registry;
import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/core/core.ticks.dart' show formatters;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/scales/scale.linearbase.dart';
import 'package:flutter_chartjs_port/src/scales/scale.radialLinear.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import 'scale_chart_harness.dart';
import 'scale_radial_linear_reference.dart';

// The port-only tests of lib/src/scales/scale.radialLinear.dart.
//
// The reference group compares real charts with the charts of
// tool/reference/scale_radial_linear_reference.mjs: a build of the pinned
// Chart.js in Node.js v24.12.0 on x64 (Chart.js ADR 0032), with a mock
// context that measures text in Liberation Sans 2.1.5, the test font of the
// harness (scale_chart_harness.dart, tool/reference/scale_chart_common.mjs).
// Each chart comes from acquireChart in a testWidgets case (Chart.js ADR
// 0022).
//
// The radar and polar area controllers are not ported yet. Thus the charts
// use the radial test controller `radialTest` of the harness, with the
// radial linear scale on the axis r. It gives the parsed value r to
// getPointPositionForValue unchanged, as upstream does (Chart.js ADR 0025,
// section 9): the parse of null, undefined and NaN is null, and the point
// of null is at NaN. test/flutter_test_config.dart registers the six scales
// and the four elements of lib/src/index.dart before main() (the row
// harness-register-builtins). Thus main() registers only the test
// controller, through its class value, before the snapshot of the defaults
// restore (Chart.js ADR 0020, section 8, and Chart.js ADR 0022, section 8).
// The generator also registers the six scales and the four elements of the
// dist first.
//
// The group of Chart.js ADR 0025 pins the relations of the value types
// (section 9) without generated values. The radial methods have no fast
// path (Chart.js ADR 0025, Open 1). Thus they have no pin group.

/// The named functions of the configs of the generator.
final Map<String, Object?> _functions = {
  'pointLabelCallback': (Object? label, double index) => switch (index) {
    0.0 => 0.0,
    1.0 => '',
    2.0 => null,
    3.0 => <Object?>[label, 'x${jsNumberToString(index)}'],
    _ => '${jsToString(label)}!',
  },
  'pointLabelColor': (Object? ctx) =>
      jsToNumber(jsGet(ctx, 'index')) % 2 != 0 ? 'red' : 'blue',
  'angleLineColor': (Object? ctx) =>
      jsGet(ctx, 'label') == 'B' ? 'green' : 'gray',
  'gridColor': (Object? ctx) =>
      jsToNumber(jsGet(ctx, 'index')) > 2 ? 'orange' : 'purple',
  'pointLabelPadding': (Object? ctx) => 2 + 3 * jsToNumber(jsGet(ctx, 'index')),
  'angleLineWidth': (Object? ctx) => jsGet(ctx, 'index') == 0 ? 0.0 : 1.0,
  'angleLineEmptyColor': (Object? ctx) =>
      jsGet(ctx, 'index') == 1 ? '' : 'black',
  'tickUnit': (Object? value) => '${jsToString(value)} u',
  'hideOneAndThree': (Object? chart) {
    (chart! as Chart)
      ..toggleDataVisibility(1)
      ..toggleDataVisibility(3);
  },
  'tickLines': (Object? value) => <Object?>[value, 'x'],
  'pointLabelFontByIndex': (Object? ctx) => <String, Object?>{
    'size': 8 + jsToNumber(jsGet(ctx, 'index')) * 2,
  },
  // JS `ctx.index % 2 === 0`: the context of the scale has no index, and
  // NaN % 2 is NaN in both languages.
  'circularEven': (Object? ctx) => jsToNumber(jsGet(ctx, 'index')) % 2 == 0,
};

/// `[x, y, angle]` of a position of the radial scale.
List<double> _position(({double x, double y, double angle}) p) => [
  p.x,
  p.y,
  p.angle,
];

/// The observations of a radial linear scale: `radialObservations` of the
/// generator, with the same keys and the same calls.
Map<String, Object?> _radialObservations(Scale scale, Chart chart) {
  if (scale is! RadialLinearScale) return const {};
  final s = scale;
  final n = s.pointLabels.length;
  final mid = (s.min + s.max) / 2;
  Object? context(int i) {
    final c = s.getPointLabelContext(i);
    return c == null ? 'undefined' : [c['type'], c['index'], c['label']];
  }

  return {
    'xCenter': s.xCenter,
    'yCenter': s.yCenter,
    'drawingArea': s.drawingArea,
    'startValue': s.startValue,
    'endValue': s.endValue,
    'valueRange': s.valueRange,
    'tickLimit': s.getTickLimit(),
    'labels': List<Object?>.of(s.getLabels()),
    'pointLabels': List<Object?>.of(s.pointLabels),
    'pointLabelItems': [
      for (final it in s.pointLabelItems)
        [
          it.visible,
          it.x,
          it.y,
          it.textAlign,
          it.left,
          it.top,
          it.right,
          it.bottom,
        ],
    ],
    'pointLabelPositions': [
      for (var i = 0; i < s.pointLabelItems.length; i++)
        switch (s.getPointLabelPosition(i)) {
          (:final left, :final top, :final right, :final bottom) => [
            left,
            top,
            right,
            bottom,
          ],
        },
    ],
    'pointLabelContexts': [
      for (final i in [-1, 0, n - 1, n]) context(i),
    ],
    'indexAngles': [
      for (final i in [0.0, 1.0, 2.0, 0.5, n.toDouble(), -1.0])
        s.getIndexAngle(i),
    ],
    'distances': [
      for (final v in <Object?>[
        s.min,
        mid,
        s.max,
        s.min - 10,
        0.0,
        null,
        undefined,
        double.nan,
        '5',
        true,
        double.infinity,
      ])
        s.getDistanceFromCenterForValue(v),
    ],
    // JS undefined is Dart null for the `double?` parameter.
    'valuesForDistances': [
      for (final d in <double?>[
        0,
        s.drawingArea / 2,
        s.drawingArea,
        -10,
        null,
        null,
      ])
        s.getValueForDistanceFromCenter(d),
    ],
    'pointPositions': [
      for (final (i, v) in <(double, Object?)>[
        (0, s.min),
        (1, mid),
        (2.5, s.max),
        (0, null),
        (n.toDouble(), '5'),
      ])
        _position(s.getPointPositionForValue(i, v)),
    ],
    'pointPosition': _position(s.getPointPosition(1, 50, 0.3)),
    // JS undefined is Dart null for the `double?` parameter.
    'basePositions': [
      for (final i in <double?>[null, null, 0, 1, 2.5, double.nan])
        _position(s.getBasePosition(i)),
    ],
  };
}

/// A chart of the test controller `radialTest` with the labels [labels], one
/// dataset of [data] and the scale options [r].
Chart _chart(
  List<Object?> labels,
  List<Object?> data, [
  Map<String, Object?> r = const {},
]) => acquireChart(<String, Object?>{
  'type': 'radialTest',
  'data': <String, Object?>{
    'labels': labels,
    'datasets': <Object?>[
      <String, Object?>{'data': data},
    ],
  },
  'options': <String, Object?>{
    'scales': <String, Object?>{
      'r': <String, Object?>{...r},
    },
  },
});

/// The scale r of [chart].
RadialLinearScale _r(Chart chart) => chart.scales['r']! as RadialLinearScale;

/// Expects the positions [actual] and [expected] to be equal, NaN equal to
/// NaN.
void _expectSamePosition(
  ({double x, double y, double angle}) actual,
  ({double x, double y, double angle}) expected,
) {
  for (final (a, e) in [
    (actual.x, expected.x),
    (actual.y, expected.y),
    (actual.angle, expected.angle),
  ]) {
    if (e.isNaN) {
      expect(a, isNaN);
    } else {
      expect(a, e);
    }
  }
}

void main() {
  // Before the snapshot of the defaults restore (Chart.js ADR 0022, section
  // 8). The restore does not reset the items of the registry.
  Chart.register([
    radialLinearTestController(
      (scale, index, value) =>
          (scale as RadialLinearScale).getPointPositionForValue(index, value),
    ),
  ]);

  testReferenceOrigin(
    node: scaleRadialLinearReferenceNode,
    arch: scaleRadialLinearReferenceArch,
    dist: scaleRadialLinearReferenceDist,
    commit: scaleRadialLinearReferenceCommit,
  );

  group('the class value (Chart.js ADR 0020)', () {
    test('the registry gives the class value of the id radialLinear', () {
      expect(
        registry.getScale('radialLinear'),
        same(RadialLinearScale.jsClass),
      );
      final value = RadialLinearScale.jsClass;
      expect(value.name, 'RadialLinearScale');
      expect(value.superclass, same(LinearScaleBase.jsClass));
      expect(value['id'], 'radialLinear');
      expect(value['defaults'], same(RadialLinearScale.defaults));
      expect(value['defaultRoutes'], same(RadialLinearScale.defaultRoutes));
      expect(value['descriptors'], same(RadialLinearScale.descriptors));
    });

    testWidgets('jsConstruct makes a RadialLinearScale from the cfg object', (
      tester,
    ) async {
      final chart = _chart(['A'], [1.0]);
      final scale = jsConstruct(RadialLinearScale.jsClass, [
        <String, Object?>{
          'id': 'z',
          'type': 'radialLinear',
          'ctx': null,
          'chart': chart,
        },
      ]);
      expect(scale, isA<RadialLinearScale>());
      final s = scale as RadialLinearScale;
      expect(s.id, 'z');
      // scale.radialLinear.js:415-423: the start values. Dart null stands
      // for the `undefined` of `xCenter` and `yCenter`, NaN for the
      // `undefined` of `drawingArea`.
      expect(s.xCenter, isNull);
      expect(s.yCenter, isNull);
      expect(s.drawingArea, isNaN);
      expect(s.pointLabels, isEmpty);
      expect(s.pointLabelItems, isEmpty);
    });

    test(
      'defaults.scales.radialLinear has the keys of the static defaults',
      () {
        final scales = defaults['scales']! as Map<String, Object?>;
        final radial = scales['radialLinear']! as Map<String, Object?>;
        expect(radial.keys, [
          'display',
          'animate',
          'position',
          'angleLines',
          'grid',
          'startAngle',
          'ticks',
          'pointLabels',
        ]);
        // The key order of the dist (Node.js v24.12.0 on x64). The routes of
        // defaultRoutes add the key color last (core.defaults.js:130-157).
        final ticks = radial['ticks']! as Map<String, Object?>;
        expect(ticks.keys, ['showLabelBackdrop', 'callback', 'color']);
        expect(ticks['callback'], same(formatters['numeric']));
        final angleLines = radial['angleLines']! as Map<String, Object?>;
        expect(angleLines.keys, [
          'display',
          'lineWidth',
          'borderDash',
          'borderDashOffset',
          'color',
        ]);
        final pointLabels = radial['pointLabels']! as Map<String, Object?>;
        expect(pointLabels.keys, [
          'backdropColor',
          'backdropPadding',
          'display',
          'font',
          'callback',
          'padding',
          'centerPointLabels',
          'color',
        ]);
        expect(pointLabels['backdropColor'], same(undefined));
        // The routes read the colors of the root scope.
        expect(angleLines['color'], defaults['borderColor']);
        expect(pointLabels['color'], defaults['color']);
        expect(ticks['color'], defaults['color']);
      },
    );
  });

  group('radial linear scale charts against upstream', () {
    testScaleChartCases(
      scaleRadialLinearReference,
      functions: _functions,
      extra: _radialObservations,
    );
  });

  group('value types (Chart.js ADR 0025)', () {
    testWidgets('null and undefined give NaN distances', (tester) async {
      final r = _r(_chart(['A', 'B', 'C'], [1.0, 5.0, 9.0]));
      expect(r.getDistanceFromCenterForValue(null), isNaN);
      expect(r.getDistanceFromCenterForValue(undefined), isNaN);
      expect(r.getValueForDistanceFromCenter(null), isNaN);
      for (final i in [0.0, 1.0]) {
        final p = r.getPointPositionForValue(i, null);
        expect(p.x, isNaN);
        expect(p.y, isNaN);
        expect(p.angle, r.getPointPosition(i, 0).angle);
      }
    });

    // The reference case 'null, undefined, NaN and string data' compares the
    // same chart with the dist.
    testWidgets('the test controller gives the parsed value unchanged', (
      tester,
    ) async {
      final chart = _chart(
        ['A', 'B', 'C', 'D', 'E'],
        [65.0, null, double.nan, undefined, '70'],
      );
      final r = _r(chart);
      final meta = chart.getDatasetMeta(0);
      final points = meta.data;
      // The parse of null, NaN and undefined is null: the point is at NaN,
      // not at the position of the value 0.
      for (final i in [1, 2, 3]) {
        expect(jsGet(meta.controller!.getParsed(i.toDouble()), 'r'), isNull);
        expect(points[i].x, isNaN, reason: 'x of $i');
        expect(points[i].y, isNaN, reason: 'y of $i');
        expect(r.getPointPositionForValue(i.toDouble(), 0).x, isNot(isNaN));
      }
      final p = r.getPointPositionForValue(4, 70);
      expect([points[4].x, points[4].y], [p.x, p.y]);
    });

    testWidgets('a value that is not a number gives its ToNumber', (
      tester,
    ) async {
      final r = _r(_chart(['A', 'B', 'C'], [1.0, 5.0, 9.0]));
      expect(
        r.getDistanceFromCenterForValue('5'),
        r.getDistanceFromCenterForValue(5.0),
      );
      expect(
        r.getDistanceFromCenterForValue(5),
        r.getDistanceFromCenterForValue(5.0),
      );
      expect(
        r.getDistanceFromCenterForValue(true),
        r.getDistanceFromCenterForValue(1.0),
      );
      expect(r.getDistanceFromCenterForValue('B'), isNaN);
      _expectSamePosition(
        r.getPointPositionForValue(2, '7'),
        r.getPointPositionForValue(2, 7.0),
      );
    });

    testWidgets('getBasePosition of null and NaN is the position of index 0', (
      tester,
    ) async {
      final r = _r(_chart(['A', 'B', 'C'], [1.0, 5.0, 9.0]));
      final zero = r.getBasePosition(0);
      // Dart null, the default value, stands for JS null and undefined.
      _expectSamePosition(r.getBasePosition(), zero);
      _expectSamePosition(r.getBasePosition(double.nan), zero);
      _expectSamePosition(
        zero,
        r.getPointPositionForValue(0, r.getBaseValue()),
      );
    });

    testWidgets('a reverse scale maps the distances back to the values', (
      tester,
    ) async {
      final r = _r(
        _chart(
          ['A', 'B', 'C'],
          [1.0, 5.0, 9.0],
          {'reverse': true, 'min': 0.0, 'max': 10.0},
        ),
      );
      expect(r.getDistanceFromCenterForValue(10), 0);
      expect(r.getDistanceFromCenterForValue(0), r.drawingArea);
      expect(r.getValueForDistanceFromCenter(0), 10);
      expect(r.getValueForDistanceFromCenter(r.drawingArea), 0);
    });
  });

  group('point labels', () {
    testWidgets('getPointLabelContext is null out of the range', (
      tester,
    ) async {
      final r = _r(_chart(['A', 'B', 'C'], [1.0, 5.0, 9.0]));
      expect(r.getPointLabelContext(-1), isNull);
      expect(r.getPointLabelContext(3), isNull);
      final context = r.getPointLabelContext(1)!;
      expect(context['type'], 'pointLabel');
      expect(context['index'], 1.0);
      expect(context['label'], 'B');
      expect(context['scale'], same(r));
    });

    testWidgets('a point label item is the TRBL of getPointLabelPosition', (
      tester,
    ) async {
      final r = _r(_chart(['A', 'B', 'C', 'D'], [1.0, 5.0, 9.0, 2.0]));
      expect(r.pointLabelItems, hasLength(4));
      for (var i = 0; i < 4; i++) {
        final types.TRBL item = r.pointLabelItems[i];
        final p = r.getPointLabelPosition(i);
        expect(
          [p.left, p.top, p.right, p.bottom],
          [
            item.left,
            item.top,
            item.right,
            item.bottom,
          ],
        );
      }
      expect(() => r.getPointLabelPosition(4), throwsRangeError);
    });
  });

  group('Liberation Sans widths of the generator', () {
    testReferenceWidths(scaleRadialLinearReferenceWidths);
  });
}
