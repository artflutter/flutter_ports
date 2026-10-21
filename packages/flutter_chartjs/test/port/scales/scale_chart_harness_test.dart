// Original code, not ported from Chart.js: self-test of the scale harness.
@TestOn('vm')
library;

import 'dart:convert';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/core/core.scale.dart';
import 'package:flutter_chartjs/src/elements/element.bar.dart';
import 'package:flutter_chartjs/src/js/js_class.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_test/flutter_test.dart';

import '../canvas/path2d_record.dart';
import 'scale_chart_harness.dart';
import 'scale_chart_harness_reference.dart';

// The self-test of the method of the phase 6 scale reference tests
// (scale_chart_harness.dart, tool/reference/scale_chart_common.mjs), with
// the cases of tool/reference/scale_chart_harness_reference.mjs. The
// generator builds each chart with a build of the pinned Chart.js in Node.js
// v24.12.0 on x64 (Chart.js ADR 0010). Its mock context measures text in
// Liberation Sans 2.1.5, the test font of the harness.
//
// Each chart comes from acquireChart in a testWidgets case (Chart.js ADR
// 0022). No phase 6 scale is ported yet. Thus main() registers test scales
// and test controllers through their class values: `harnessLinear` on both
// axes of the cartesian test controller `harnessTest`, `harnessMeasure` (a
// measure with no font write, as in the time scale), and `harnessRadial` on
// the axis r of the radial test controller `harnessRadialTest`. The
// registration runs before the snapshot of the defaults restore (Chart.js
// ADR 0020, section 8, and Chart.js ADR 0022, section 8). The generator
// registers the same classes after the six scales and the four elements of
// the dist. The scales of the dist do not change a chart of the test
// scales: a scale registers only its own defaults.
//
// The cases compare the chart area, each scale (ticks, labels, box, label
// rotation, paddings and the pixel mapping), the points and the calls of
// one draw, with the element draws (Chart.js ADR 0030). The group of widths
// measures each text of the generator on the canvas of the harness. The
// group 'drawCalls' checks that drawCalls records the element draws and
// puts back each context.

/// The test scale `harnessLinear` of the generator: the range of the data
/// (`getMinMax`), five ticks at equal steps from min to max, and a linear
/// mapping.
final class _HarnessLinearScale extends Scale {
  _HarnessLinearScale(super.cfg);

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

/// `class HarnessLinearScale extends Scale` of the generator.
final JsClass _harnessLinearScale = JsClass(
  'HarnessLinearScale',
  superclass: Scale.jsClass,
  statics: {'id': 'harnessLinear', 'defaults': <String, Object?>{}},
  construct: (newTarget, args) => _HarnessLinearScale(scaleCfgArg(args)),
);

/// The test scale `harnessMeasure` of the generator: `harnessLinear`, and in
/// `buildTicks` a measure of the text 'January' with no font write, as
/// `_getLabelSize` of the time scale (scale.time.js:591-593). The measure
/// takes the current font of the context: the first font of the canvas, or
/// the last tick font of the layout. Before the measure, a save, a font
/// write and a restore must leave that font. [measures] has the widths of
/// the measures, in order.
final class _HarnessMeasureScale extends _HarnessLinearScale {
  _HarnessMeasureScale(super.cfg);

  /// The width of each measure, in order.
  final List<double> measures = [];

  @override
  List<Tick>? buildTicks() {
    final ctx = this.ctx!
      ..save()
      ..font = 'normal bold 20px Arial'
      ..restore();
    measures.add(ctx.measureText('January').width);
    return super.buildTicks();
  }
}

/// `class HarnessMeasureScale extends HarnessLinearScale` of the generator.
final JsClass _harnessMeasureScale = JsClass(
  'HarnessMeasureScale',
  superclass: _harnessLinearScale,
  statics: {'id': 'harnessMeasure', 'defaults': <String, Object?>{}},
  construct: (newTarget, args) => _HarnessMeasureScale(scaleCfgArg(args)),
);

/// The observation `measures` of a `harnessMeasure` scale: `measures` of the
/// generator.
Map<String, Object?> _measures(Scale scale, Chart chart) =>
    scale is _HarnessMeasureScale
    ? {'measures': List.of(scale.measures)}
    : const {};

/// The test scale `harnessRadial` of the generator, for the axis r: the
/// range of the data, the ticks min and max, and a point position that
/// depends on the box, the index and the value. Its options have
/// `display: false`: the base class has no drawing for the position
/// `chartArea`.
final class _HarnessRadialScale extends Scale {
  _HarnessRadialScale(super.cfg);

  @override
  void determineDataLimits() {
    final (:min, :max) = getMinMax(false);
    this.min = min;
    this.max = max;
  }

  @override
  List<Tick>? buildTicks() => [Tick(value: min), Tick(value: max)];

  /// `getPointPositionForValue(index, value)` of the generator.
  ///
  /// [value] is the parsed value r, unchanged (Chart.js ADR 0025, section
  /// 9). The data of the cases are numbers. For a number, and also for
  /// null, undefined and a boolean, the JS `left + value` is the sum with
  /// ToNumber of [value].
  RadialPointPosition getPointPositionForValue(double index, Object? value) =>
      (x: left + jsToNumber(value), y: top + 10 * index, angle: index / 2);
}

/// `class HarnessRadialScale extends Scale` of the generator.
final JsClass _harnessRadialScale = JsClass(
  'HarnessRadialScale',
  superclass: Scale.jsClass,
  statics: {
    'id': 'harnessRadial',
    'defaults': <String, Object?>{'display': false},
  },
  construct: (newTarget, args) => _HarnessRadialScale(scaleCfgArg(args)),
);

/// The cartesian test controller `harnessTest` of the generator.
final JsClass _harnessTestController = cartesianTestController('harnessTest', {
  'scales': <String, Object?>{
    '_index_': <String, Object?>{'type': 'harnessLinear'},
    '_value_': <String, Object?>{'type': 'harnessLinear'},
  },
});

/// The radial test controller `harnessRadialTest` of the generator.
final JsClass _harnessRadialTestController = radialTestController(
  'harnessRadialTest',
  {
    'aspectRatio': 1.0,
    'scales': <String, Object?>{
      'r': <String, Object?>{'type': 'harnessRadial'},
    },
  },
  (scale, index, value) =>
      (scale as _HarnessRadialScale).getPointPositionForValue(index, value),
);

/// The named functions of the configs of the generator.
final Map<String, Object?> _functions = {
  'withUnit': (Object? value) => '${jsToString(value)} kg',
};

/// The reference text of [calls]: one JSON line `[name, ...args]` for each
/// call, as the generators write it.
String _callsText(List<List<Object?>> calls) =>
    calls.map(jsonEncode).join('\n');

/// The records `{name, args}` of [calls], the form of `recordedCalls`.
List<Object?> _records(List<List<Object?>> calls) => [
  for (final call in calls)
    <String, Object?>{'name': call.first, 'args': call.sublist(1)},
];

/// The upstream calls of a bar with a border (element.bar.js:179-200): the
/// ring with the `clip` and the fill. [outer] is the outer rectangle as
/// `inflateRect` gives it.
List<List<Object?>> _upstreamBar({
  List<Object?> outer = const [0, 0, 10, 10],
  bool clip = true,
}) => [
  ['save'],
  ['beginPath'],
  ['rect', ...outer],
  if (clip) ['clip', null, null],
  ['rect', 2, 2, 6, 6],
  ['setFillStyle', 'red'],
  ['fill', 'evenodd', null],
  ['beginPath'],
  ['rect', 2, 2, 6, 6],
  ['setFillStyle', 'blue'],
  ['fill', null, null],
  ['restore'],
];

void main() {
  // Before the snapshot of the defaults restore (Chart.js ADR 0022, section
  // 8). The restore does not reset the items of the registry.
  Chart.register([
    _harnessLinearScale,
    _harnessMeasureScale,
    _harnessRadialScale,
    _harnessTestController,
    _harnessRadialTestController,
  ]);

  testReferenceOrigin(
    node: scaleChartHarnessReferenceNode,
    arch: scaleChartHarnessReferenceArch,
    dist: scaleChartHarnessReferenceDist,
    commit: scaleChartHarnessReferenceCommit,
  );

  group('test scale charts against upstream', () {
    testScaleChartCases(
      scaleChartHarnessReference,
      functions: _functions,
      extra: _measures,
    );
  });

  group('Liberation Sans widths of the generator', () {
    testReferenceWidths(scaleChartHarnessReferenceWidths);
  });

  group('drawCalls', () {
    testWidgets('records the point draws of the test controller and puts '
        'back each context', (tester) async {
      final chart = acquireChart({
        'type': 'harnessTest',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[
                <String, Object?>{'x': 0, 'y': 1},
                <String, Object?>{'x': 5, 'y': 3},
                <String, Object?>{'x': 10, 'y': 2},
              ],
            },
          ],
        },
      });
      final context = chart.ctx;
      final scales = chart.scales.values.toList();
      final scaleContexts = [for (final scale in scales) scale.ctx];
      final controller = chart.getDatasetMeta(0).controller!;
      expect(identical(controller.ctx, context), isTrue);

      final calls = drawCalls(chart);

      // One `arc` for each point: the circle of drawPoint
      // (helpers.canvas.ts). The scales draw no arc.
      final arcs = [
        for (final call in calls.cast<Map<String, Object?>>())
          if (call['name'] == 'arc') call['args']! as List<Object?>,
      ];
      expect(arcs, hasLength(3));
      final points = chart.getDatasetMeta(0).data;
      for (var i = 0; i < 3; i++) {
        expect(arcs[i][0], points[i].x, reason: 'arc $i: x');
        expect(arcs[i][1], points[i].y, reason: 'arc $i: y');
      }
      expect(identical(chart.ctx, context), isTrue, reason: 'chart.ctx');
      for (var i = 0; i < scales.length; i++) {
        expect(
          identical(scales[i].ctx, scaleContexts[i]),
          isTrue,
          reason: 'scales.${scales[i].id}.ctx',
        );
      }
      expect(
        identical(controller.ctx, context),
        isTrue,
        reason: 'controller.ctx',
      );
    });

    testWidgets('leaves a controller with another context as it is', (
      tester,
    ) async {
      final chart = acquireChart({
        'type': 'harnessTest',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[
                <String, Object?>{'x': 0, 'y': 1},
                <String, Object?>{'x': 10, 'y': 2},
              ],
            },
          ],
        },
      });
      final controller = chart.getDatasetMeta(0).controller!;
      final other = RecordingContext(chart.ctx!);
      controller.ctx = other;
      addTearDown(() => controller.ctx = chart.ctx);

      final calls = drawCalls(chart);

      expect(
        calls.cast<Map<String, Object?>>().where((c) => c['name'] == 'arc'),
        isEmpty,
        reason: 'the points draw on the other context',
      );
      expect(
        other.getCalls().where((c) => c['name'] == 'arc'),
        hasLength(2),
      );
      expect(identical(controller.ctx, other), isTrue);
    });
  });

  group('expectCalls: adapt-bar-clip', () {
    test('removes the clip of a ring that the port draws without it', () {
      expectCalls(
        _records(_upstreamBar(clip: false)),
        _callsText(_upstreamBar()),
      );
    });

    test('keeps the clip of a ring that the port draws with it', () {
      expectCalls(_records(_upstreamBar()), _callsText(_upstreamBar()));
      expect(
        () => expectCalls(
          _records(_upstreamBar()),
          _callsText(_upstreamBar(clip: false)),
        ),
        throwsA(isA<TestFailure>()),
      );
    });

    test('fails at the outer path for a reference amount that is not 0', () {
      // inflateRect(outer, 0.33, inner) moves each edge of the outer
      // rectangle that differs from the inner one (element.bar.js:127-139).
      expect(
        () => expectCalls(
          _records(_upstreamBar(clip: false)),
          _callsText(_upstreamBar(outer: [-0.33, -0.33, 10.66, 10.66])),
        ),
        throwsA(isA<TestFailure>()),
      );
    });

    test('keeps a clip that is not in a ring', () {
      // clipArea (helpers.canvas.ts): no fill('evenodd') after the clip.
      final reference = [
        ['save'],
        ['beginPath'],
        ['rect', 0, 0, 10, 10],
        ['clip', null, null],
        ['fillRect', 0, 0, 5, 5],
        ['restore'],
      ];
      expect(
        () => expectCalls(
          _records([
            for (final call in reference)
              if (call.first != 'clip') call,
          ]),
          _callsText(reference),
        ),
        throwsA(isA<TestFailure>()),
      );
    });

    test('removes nothing when the counts of the rings differ', () {
      expect(
        () => expectCalls(
          _records(_upstreamBar(clip: false)),
          _callsText([..._upstreamBar(), ..._upstreamBar()]),
        ),
        throwsA(isA<TestFailure>()),
      );
    });

    test('pairs the draw of a port bar with the amount 0 with upstream', () {
      // A bar of 30 x 80 pixels with a border of 2 and the bottom edge
      // skipped: the port draws the ring without a clip.
      final bar = BarElement({
        'horizontal': false,
        'x': 50,
        'y': 20,
        'base': 100,
        'width': 30,
        'height': 80,
        'options': <String, Object?>{
          'borderColor': 'red',
          'backgroundColor': 'blue',
          'borderWidth': 2,
          'borderRadius': 0,
        },
        'borderSkipped': <String, Object?>{'bottom': true},
        'inflateAmount': 0,
      });
      final ctx = createMockContext();
      bar.draw(ctx);
      final actual = recordedCalls(ctx.getCalls());
      final calls = [
        for (final call in actual.cast<Map<String, Object?>>())
          [call['name'], ...call['args']! as List<Object?>],
      ];
      expect(calls.where((call) => call.first == 'clip'), isEmpty);
      // The upstream form: the clip after the outer rectangle
      // (element.bar.js:187-189).
      final upstream = [...calls]
        ..insert(calls.indexWhere((c) => c.first == 'rect') + 1, [
          'clip',
          null,
          null,
        ]);
      expectCalls(actual, _callsText(upstream));
    });
  });
}
