// Original code, not ported from Chart.js: type members of Chart.js ADR 0028.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/core/core.element.dart';
import 'package:flutter_chartjs/src/js/js_array.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/scales/scale.radialLinear.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import '../scales/scale_chart_harness.dart';

// The members that Chart.js ADR 0028 (section 1) adds to the interfaces of
// lib/src/types/index.dart. Each case reads the new members through a
// variable of the interface type and compares the result with the concrete
// member. The analyzer is the compile-time check of the signatures: each
// `@override` of the concrete classes fails when the interface and the
// concrete member differ.
//
// The bar and polar area controllers are not ported yet. Thus the charts use
// the test controllers of scale_chart_harness.dart: `scaleTest` (category on
// the index axis, linear on the value axis) and `radialTest` (radialLinear on
// the axis r). test/flutter_test_config.dart registers the scales and the
// elements of lib/src/index.dart before main().

/// A chart of the test controller [type] with the labels [labels] and one
/// dataset of [data].
Chart _chart(String type, List<Object?> labels, List<Object?> data) =>
    acquireChart(<String, Object?>{
      'type': type,
      'data': <String, Object?>{
        'labels': labels,
        'datasets': <Object?>[
          <String, Object?>{'data': data},
        ],
      },
    });

/// Whether the option objects [a] and [b] have the same keys in the same
/// order and the same values (`jsObjectKeys` and `jsGet`, so that no
/// resolver goes into a failure message).
bool _sameOptions(Map<String, Object?> a, Map<String, Object?> b) {
  final keys = jsObjectKeys(a);
  final other = jsObjectKeys(b);
  if (keys.length != other.length) return false;
  for (var i = 0; i < keys.length; i++) {
    if (keys[i] != other[i]) return false;
    final x = jsGet(a, keys[i]);
    final y = jsGet(b, keys[i]);
    if (!identical(x, y) && x != y) return false;
  }
  return true;
}

void main() {
  // Before the snapshot of the defaults restore (Chart.js ADR 0022, section
  // 8). The restore does not reset the items of the registry.
  Chart.register([
    scaleTestController,
    radialLinearTestController(
      (scale, index, value) => (scale as types.RadialLinearScale)
          .getPointPositionForValue(index, value),
    ),
  ]);

  group('types.Chart', () {
    testWidgets('the visibility members, legend and update', (tester) async {
      final chart = _chart('scaleTest', ['a', 'b', 'c'], [1.0, 2.0, 3.0]);
      final types.Chart t = chart;
      expect(t.isDatasetVisible(0), isTrue);
      expect(t.isDatasetVisible(0), chart.isDatasetVisible(0));
      expect(t.isDatasetVisible(1), isFalse);
      expect(t.getVisibleDatasetCount(), 1);
      expect(t.getVisibleDatasetCount(), chart.getVisibleDatasetCount());
      expect(t.legend, isNull);
      expect(t.legend, same(chart.legend));

      t.toggleDataVisibility(1);
      expect(t.getDataVisibility(1), isFalse);
      expect(chart.getDataVisibility(1), isFalse);
      expect(t.getDataVisibility(0), isTrue);

      // update() through the interface builds the element of a new item.
      final meta = chart.getDatasetMeta(0);
      expect(meta.data, hasLength(3));
      (jsGet(jsGet(chart.data['datasets'], 0.0), 'data')! as List<Object?>).add(
        4.0,
      );
      (chart.data['labels']! as List<Object?>).add('d');
      t.update();
      expect(meta.data, hasLength(4));
    });
  });

  group('types.ChartMeta', () {
    testWidgets('dataset_ and total', (tester) async {
      final chart = _chart('scaleTest', ['a', 'b'], [1.0, 2.0]);
      final meta = chart.getDatasetMeta(0);
      final types.ChartMeta t = meta;
      final dataset = jsGet(chart.data['datasets'], 0.0);
      expect(identical(t.dataset_, dataset), isTrue);
      expect(identical(t.dataset_, meta.dataset_), isTrue);
      // No doughnut update wrote the total.
      expect(t.total, isNull);
      expect(meta['total'], same(undefined));
      t.total = 3;
      expect(meta.total, 3.0);
      expect(meta['total'], 3.0);
    });
  });

  group('types.DatasetController', () {
    testWidgets('options, getParsed, getStyle and resolveDataElementOptions', (
      tester,
    ) async {
      final chart = _chart('scaleTest', ['a', 'b'], [1.0, 2.0]);
      final controller = chart.getDatasetMeta(0).controller!;
      final types.DatasetController t = controller;
      expect(identical(t.options, controller.options), isTrue);
      expect(identical(t.getParsed(0), controller.getParsed(0)), isTrue);
      expect(jsGet(t.getParsed(1), 'y'), 2.0);
      expect(t.getParsed(2), same(undefined));
      expect(
        _sameOptions(t.getStyle(0), controller.getStyle(0)),
        isTrue,
        reason: 'getStyle(0)',
      );
      expect(
        _sameOptions(t.getStyle(0, true), controller.getStyle(0, true)),
        isTrue,
        reason: 'getStyle(0, true)',
      );
      expect(
        _sameOptions(
          t.resolveDataElementOptions(0),
          controller.resolveDataElementOptions(0),
        ),
        isTrue,
        reason: 'resolveDataElementOptions(0)',
      );
      expect(jsObjectKeys(t.resolveDataElementOptions(1)), isNotEmpty);
    });
  });

  group('types.Element', () {
    testWidgets('active and hidden', (tester) async {
      final chart = _chart('scaleTest', ['a', 'b'], [1.0, 2.0]);
      final element = chart.getDatasetMeta(0).data[0] as Element;
      final types.Element t = element;
      expect(t.active, isFalse);
      expect(t.active, element.active);
      expect(t.hidden, same(undefined));
      element
        ..active = true
        ..hidden = null;
      expect(t.active, isTrue);
      expect(t.hidden, isNull);
    });
  });

  group('types.Scale', () {
    testWidgets('the 9 members of Chart.js ADR 0028', (tester) async {
      final chart = _chart('scaleTest', ['a', 'b', 'c'], [1.0, 5.0, 3.0]);
      for (final id in ['x', 'y']) {
        final scale = chart.scales[id]!;
        final types.Scale t = scale;
        expect(identical(t.cache, scale.cache), isTrue, reason: id);
        expect(identical(t.ticks, scale.ticks), isTrue, reason: id);
        expect(t.ticks, isNotEmpty, reason: id);
        expect(t.getPixelForTick(0), scale.getPixelForTick(0), reason: id);
        expect(t.getPixelForTick(99), isNull, reason: id);
        expect(t.getBasePixel(), scale.getBasePixel(), reason: id);
        expect(t.startPixel, scale.startPixel, reason: id);
        expect(t.startPixel, isNot(isNaN), reason: id);
        expect(t.endPixel, scale.endPixel, reason: id);
        expect(
          t.getPixelForDecimal(0.25),
          scale.getPixelForDecimal(0.25),
          reason: id,
        );
        final pixel = (t.startPixel + t.endPixel) / 2;
        expect(
          t.getValueForPixel(pixel),
          scale.getValueForPixel(pixel),
          reason: id,
        );
        final value = t.ticks!.first.value;
        expect(
          t.getLineWidthForValue(value),
          scale.getLineWidthForValue(value),
          reason: id,
        );
      }
    });
  });

  group('types.RadialLinearScale', () {
    testWidgets('the 5 members and the type test', (tester) async {
      final chart = _chart('radialTest', ['a', 'b', 'c'], [1.0, 5.0, 3.0]);
      expect(chart.scales['r'] is types.RadialLinearScale, isTrue);
      expect(chart.scales['x'], isNull);
      final scale = chart.scales['r']! as RadialLinearScale;
      final t = chart.scales['r']! as types.RadialLinearScale;
      expect(t.xCenter, scale.xCenter);
      expect(t.xCenter, isNot(isNaN));
      expect(t.yCenter, scale.yCenter);
      expect(t.getIndexAngle(1), scale.getIndexAngle(1));
      expect(
        t.getDistanceFromCenterForValue(4.0),
        scale.getDistanceFromCenterForValue(4.0),
      );
      expect(t.getDistanceFromCenterForValue(null), isNaN);
      expect(
        t.getPointPositionForValue(1, 4.0),
        scale.getPointPositionForValue(1, 4.0),
      );
    });

    testWidgets('a cartesian scale is not a types.RadialLinearScale', (
      tester,
    ) async {
      final chart = _chart('scaleTest', ['a'], [1.0]);
      expect(chart.scales['x'] is types.RadialLinearScale, isFalse);
      expect(chart.scales['y'] is types.RadialLinearScale, isFalse);
    });
  });

  group('DatasetController.updateElement', () {
    testWidgets('takes a types.Element', (tester) async {
      final chart = _chart('scaleTest', ['a'], [1.0]);
      final controller = chart.getDatasetMeta(0).controller!;
      final element = chart.getDatasetMeta(0).data[0];
      controller.updateElement(element, 0, {'x': 7.0, 'y': 8.0}, 'none');
      expect(element.x, 7.0);
      expect(element.y, 8.0);
    });
  });

  group('DatasetController.getLabelAndValue', () {
    testWidgets('gives an Object? label and a String value', (tester) async {
      final chart = _chart('scaleTest', ['a', 'b'], [1.0, 2.0]);
      final controller = chart.getDatasetMeta(0).controller!;
      final result = controller.getLabelAndValue(1);
      // The record type of Chart.js ADR 0028, section 2. The runtime type of
      // a record comes from its field values, so the test examines the type
      // of the torn-off method: the old type ({String label, String value})
      // fails this test.
      expect(
        controller.getLabelAndValue
            is ({String label, String value}) Function(double),
        isFalse,
      );
      expect(result.label, 'b');
      expect(result.value, '2');
    });
  });
}
