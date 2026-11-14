// Original code, not ported from Chart.js: self-test of the scale harness.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:ui' as native_ui;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/elements/element.bar.dart';
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart'
    show ChartPaint;
import 'package:flutter_test/flutter_test.dart';

import '../../support/color_json.dart';
import '../canvas/path2d_record.dart';
import 'scale_chart_harness.dart';

// The self-test of scale_chart_harness.dart, the harness of the scale
// reference tests: `drawCalls` records the element draws and puts back each
// context, and `expectCalls` removes the reference `clip` of the border ring
// of a bar that the port draws without a `clip` (the row `adapt-bar-clip`).
//
// main() registers the test scale `harnessLinear` on both axes of the
// cartesian test controller `harnessTest`, before the snapshot of the
// defaults restore (Chart.js ADR 0020, section 8, and Chart.js ADR 0022,
// section 8).

/// The test scale `harnessLinear`: the range of the data
/// (`getMinMax`), five ticks at equal steps from min to max, and a linear
/// mapping.
final class _HarnessLinearScale(super.cfg) extends Scale {
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
  double getPixelForValue(Object? value, [int? index]) {
    return getPixelForDecimal((jsToNumber(value) - min) / (max - min));
  }

  @override
  double getValueForPixel(double pixel) {
    return min + getDecimalForPixel(pixel) * (max - min);
  }
}

/// The class value of `harnessLinear`.
final JsClass _harnessLinearScale = JsClass(
  'HarnessLinearScale',
  superclass: Scale.jsClass,
  statics: {'id': 'harnessLinear', 'defaults': <String, Object?>{}},
  construct: (newTarget, args) => _HarnessLinearScale(scaleCfgArg(args)),
);

/// The cartesian test controller `harnessTest`.
final JsClass _harnessTestController = cartesianTestController('harnessTest', {
  'scales': <String, Object?>{
    '_index_': <String, Object?>{'type': 'harnessLinear'},
    '_value_': <String, Object?>{'type': 'harnessLinear'},
  },
});

/// The reference text of [calls]: one JSON line `[name, ...args]` for each
/// call, as the generators write it.
String _callsText(List<List<Object?>> calls) => calls
    .map(
      (call) => jsonEncode(
        call,
        toEncodable: (value) => referenceParsedColor(value).rgbString(),
      ),
    )
    .join('\n');

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
  Chart.register([_harnessLinearScale, _harnessTestController]);

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
      final other = ReferenceRecordingContext(chart.ctx!);
      controller.ctx = other;
      addTearDown(() => controller.ctx = chart.ctx);

      final calls = drawCalls(chart);

      expect(
        calls.cast<Map<String, Object?>>().where((c) => c['name'] == 'arc'),
        isEmpty,
        reason: 'the points draw on the other context',
      );
      expect(other.getCalls().where((c) => c['name'] == 'arc'), hasLength(2));
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
          'borderColor': const ChartPaint.solid(
            native_ui.Color.fromRGBO(255, 0, 0, 1),
          ),
          'backgroundColor': const ChartPaint.solid(
            native_ui.Color.fromRGBO(0, 0, 255, 1),
          ),
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
