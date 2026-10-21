// Original code, not ported from Chart.js: self-test of the controller harness.
@TestOn('vm')
library;

import 'dart:convert';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs/src/canvas/canvas.dart';
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/elements/element.line.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import '../../support/jasmine.dart';
import '../canvas/path2d_record.dart';
import '../scales/scale_chart_harness.dart';
import 'controller_chart_harness.dart';

// The self-test of the controller harness (controller_chart_harness.dart,
// tool/reference/controller_chart_common.mjs, Chart.js ADR 0030) and of the
// spies of test/support/jasmine.dart. No controller of phase 7 is
// registered yet. Thus the charts use the cartesian test controller
// `scaleTest` of scale_chart_harness.dart: a point for each value, with the
// category scale on x and the linear scale on y.
//
// A probe of U0 (wave 1 of phase 7) ran the generator side on the same test
// controllers in the x64 Node.js and compared each key with this harness:
// the observations, the hit queries, the steps (also `hover` and
// `mouseout` at the center of a point), the draw calls with the element
// draws, a probe of `extra`, the themed run with the light preset and the
// errors at `initial` and at a step. The case 'an error at initial' below
// keeps one record of that probe.

/// The config of a chart of the test controller: two datasets of four
/// points.
Map<String, Object?> _config() => <String, Object?>{
  'type': 'scaleTest',
  'data': <String, Object?>{
    'labels': <Object?>['a', 'b', 'c', 'd'],
    'datasets': <Object?>[
      <String, Object?>{
        'data': <Object?>[1, 5, 3, 4],
      },
      <String, Object?>{
        'data': <Object?>[2, 1, 6, 2],
      },
    ],
  },
};

/// The data List of the dataset [index] of [chart].
List<Object?> _data(Chart chart, int index) =>
    jsGet((jsGet(chart.data, 'datasets')! as List<Object?>)[index], 'data')!
        as List<Object?>;

/// The rounded center of the element [index] of the dataset [dataset].
(double, double) _center(Chart chart, int dataset, int index) {
  final element =
      chart.getDatasetMeta(dataset.toDouble()).data[index]
          as types.VisualElement;
  final center = element.getCenterPoint();
  return (center.x!.roundToDouble(), center.y!.roundToDouble());
}

/// The active elements of [chart] as `[datasetIndex, index]`.
List<List<double>> _active(Chart chart) => [
  for (final item in chart.getActiveElements()) [item.datasetIndex, item.index],
];

/// [observation] in the form of the generator: `hits.items` as text.
Map<String, Object?> _asExpected(Map<String, Object?> observation) {
  final hits = observation['hits']! as Map<String, Object?>;
  return <String, Object?>{
    ...observation,
    'hits': <String, Object?>{
      ...hits,
      'items': [
        for (final item in hits['items']! as List<Object?>) jsonEncode(item),
      ].join('\n'),
    },
  };
}

void main() {
  // Before the snapshot of the defaults restore (Chart.js ADR 0022, section
  // 8).
  Chart.register([scaleTestController]);

  group('Path2D arguments', () {
    test('a Path2D argument records as {path, calls}', () {
      final ctx = createMockContext();
      final a = Path2D()
        ..moveTo(1, 2)
        ..lineTo(3, 4)
        ..closePath();
      final b = Path2D()..moveTo(5, 6);
      ctx
        ..stroke(a)
        ..fill(b)
        ..stroke(a);
      final calls = recordedCalls(ctx.getCalls());
      final pathA = <String, Object?>{
        'path': 1,
        'calls': [
          {
            'name': 'moveTo',
            'args': [1.0, 2.0],
          },
          {
            'name': 'lineTo',
            'args': [3.0, 4.0],
          },
          {'name': 'closePath', 'args': <Object?>[]},
        ],
      };
      expect(calls, [
        {
          'name': 'stroke',
          'args': [pathA],
        },
        {
          'name': 'fill',
          'args': [
            {
              'path': 2,
              'calls': [
                {
                  'name': 'moveTo',
                  'args': [5.0, 6.0],
                },
              ],
            },
            null,
          ],
        },
        {
          'name': 'stroke',
          'args': [pathA],
        },
      ]);
    });

    test('a shared PathIds numbers the paths of several records', () {
      final ids = PathIds();
      final a = Path2D();
      final b = Path2D();
      expect(ids.of(b), 1);
      expect(ids.of(a), 2);
      expect(ids.of(b), 1);
      expect(ids.of(null), isNull);
    });

    test('expectCalls compares a {path, calls} argument of the generator', () {
      final ctx = createMockContext();
      final path = Path2D()
        ..moveTo(1, 2)
        ..lineTo(3, 4);
      ctx
        ..stroke(path)
        ..stroke(path);
      final calls = recordedCalls(ctx.getCalls());
      const line =
          '["stroke",{"path":1,"calls":[["moveTo",1,2],["lineTo",3,4]]}]';
      expectCalls(calls, '$line\n$line');
      expect(
        () => expectCalls(
          calls,
          '$line\n${line.replaceFirst('"path":1', '"path":2')}',
        ),
        throwsA(isA<TestFailure>()),
        reason: 'the second call has the id 1',
      );
      expect(
        () => expectCalls(calls, '$line\n${line.replaceFirst('4]', '5]')}'),
        throwsA(isA<TestFailure>()),
        reason: 'a number of a command differs',
      );
    });
  });

  group('the hit queries', () {
    testWidgets('ReferenceEvent gives the hit of a point center with the '
        'mode point', (tester) async {
      final chart = acquireChart(_config());
      final (x, y) = _center(chart, 0, 1);
      final items = chart.getElementsAtEventForMode(
        ReferenceEvent(x, y),
        'point',
        <String, Object?>{'intersect': true, 'axis': 'xy'},
        false,
      );
      expect(
        [
          for (final item in items) [item.datasetIndex, item.index],
        ],
        [
          [0.0, 1.0],
        ],
      );

      final hits = observeHits(chart, <String, Object?>{
        'points': <Object?>[
          <Object?>[x, y],
          <Object?>[-5.0, -5.0],
        ],
        'queries': <Object?>[
          <Object?>['point', true, 'xy', false],
          <Object?>['index', false, 'x', false],
        ],
        'items': '',
      });
      expect(hits['items'], [
        [
          [
            [0.0, 1.0],
          ],
          [
            [0.0, 1.0],
            [1.0, 1.0],
          ],
        ],
        [<Object?>[], <Object?>[]],
      ]);
      expect(
        hitItems('[[[0,1]],[[0,1],[1,1]]]\n[[],[]]\n'),
        hits['items'],
        reason: 'the JSON lines of the generator',
      );
    });
  });

  group('runStep', () {
    testWidgets('update, update with a mode and reset', (tester) async {
      final chart = acquireChart(_config());
      _data(chart, 0).add(7);
      await runStep(tester, chart, ['update']);
      expect(chart.getDatasetMeta(0).data, hasLength(5));
      _data(chart, 0).add(8);
      await runStep(tester, chart, ['update', 'none']);
      expect(chart.getDatasetMeta(0).data, hasLength(6));
      await runStep(tester, chart, ['reset']);
      expect(chart.getDatasetMeta(0).data, hasLength(6));
    });

    testWidgets('setDatasetVisibility and toggleDataVisibility', (
      tester,
    ) async {
      final chart = acquireChart(_config());
      await runStep(tester, chart, ['setDatasetVisibility', 1.0, false]);
      expect(chart.isDatasetVisible(1), isFalse);
      expect(chart.isDatasetVisible(0), isTrue);
      await runStep(tester, chart, ['toggleDataVisibility', 2.0]);
      expect(chart.getDataVisibility(2), isFalse);
      expect(chart.getDataVisibility(1), isTrue);
    });

    testWidgets('setActive', (tester) async {
      final chart = acquireChart(_config());
      await runStep(tester, chart, [
        'setActive',
        <Object?>[
          <Object?>[0.0, 1.0],
          <Object?>[1.0, 3.0],
        ],
      ]);
      expect(_active(chart), [
        [0.0, 1.0],
        [1.0, 3.0],
      ]);
      expect(chart.getDatasetMeta(0).data[1].active, isTrue);
    });

    testWidgets('push and splice notify the controller', (tester) async {
      final chart = acquireChart(_config());
      await runStep(tester, chart, ['push', 0.0, 7.0, 8.0]);
      expect(_data(chart, 0), [1, 5, 3, 4, 7.0, 8.0]);
      expect(chart.getDatasetMeta(0).data, hasLength(6));
      await runStep(tester, chart, ['splice', 1.0, 1.0, 2.0, 9.0]);
      expect(_data(chart, 1), [2, 9.0, 2]);
      expect(chart.getDatasetMeta(1).data, hasLength(3));
      expect(
        jsGet(chart.getDatasetMeta(1).parsed[1], 'y'),
        9.0,
        reason: 'the controller parsed the new item',
      );
      expect(
        () => runStep(tester, chart, ['push', 5.0, 1.0]),
        throwsA(isA<TypeError>()),
        reason: 'chart.data.datasets[5].data reads a property of undefined',
      );
    });

    testWidgets('hover and mouseout', (tester) async {
      final chart = acquireChart(_config());
      final (x, y) = _center(chart, 0, 1);
      await runStep(tester, chart, ['hover', x, y]);
      expect(_active(chart), [
        [0.0, 1.0],
      ]);
      await runStep(tester, chart, ['mouseout', x, y]);
      expect(_active(chart), isEmpty);
    });

    testWidgets('an unknown step throws', (tester) async {
      final chart = acquireChart(_config());
      expect(
        () => runStep(tester, chart, ['jump']),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('expectControllerObservations', () {
    testWidgets('passes for the observation of the chart', (tester) async {
      final chart = acquireChart(_config());
      final (x, y) = _center(chart, 0, 1);
      final observed = observeControllers(
        chart,
        expectedHits: <String, Object?>{
          'points': <Object?>[
            <Object?>[x, y],
          ],
          'queries': <Object?>[
            <Object?>['point', true, 'xy', false],
          ],
          'items': '',
        },
        scaleOptions: true,
      );
      expect(observed.keys, [
        'chartArea',
        'scales',
        'stacks',
        'datasets',
        'hits',
      ]);
      final dataset = (observed['datasets']! as List<Object?>).first!;
      expect((dataset as Map<String, Object?>).keys, [
        'type',
        'indexAxis',
        'xAxisID',
        'yAxisID',
        'rAxisID',
        'stack',
        'order',
        'visible',
        'hidden',
        '_clip',
        'maxOverflow',
        'datasetOptions',
        'parsed',
        'dataset',
        'data',
        'options',
        'active',
        'labelAndValue',
      ]);
      expectControllerObservations(chart, _asExpected(observed), 'self');
      expectControllerObservations(
        chart,
        _asExpected(observed),
        'self',
        parseColors: true,
      );
    });

    testWidgets('an unknown expected key fails', (tester) async {
      final chart = acquireChart(_config());
      final observed = _asExpected(
        observeControllers(
          chart,
          expectedHits: <String, Object?>{
            'points': <Object?>[],
            'queries': <Object?>[],
            'items': '',
          },
        ),
      );
      expectControllerObservations(chart, observed, 'self');
      expect(
        () => expectControllerObservations(chart, <String, Object?>{
          ...observed,
          'legend': null,
        }, 'self'),
        throwsA(isA<TestFailure>()),
        reason: 'a key of the observation',
      );
      final datasets = observed['datasets']! as List<Object?>;
      expect(
        () => expectControllerObservations(chart, <String, Object?>{
          ...observed,
          'datasets': [
            <String, Object?>{
              ...datasets.first! as Map<String, Object?>,
              'radius': 3.0,
            },
            datasets[1],
          ],
        }, 'self'),
        throwsA(isA<TestFailure>()),
        reason: 'a key of a dataset',
      );
      expect(
        () => expectControllerObservations(chart, <String, Object?>{
          ...observed,
          'scales': <String, Object?>{
            ...observed['scales']! as Map<String, Object?>,
            'r': <String, Object?>{},
          },
        }, 'self'),
        throwsA(isA<TestFailure>()),
        reason: 'a scale id',
      );
    });

    testWidgets('a changed value fails', (tester) async {
      final chart = acquireChart(_config());
      final observed = _asExpected(
        observeControllers(
          chart,
          expectedHits: <String, Object?>{
            'points': <Object?>[],
            'queries': <Object?>[],
            'items': '',
          },
        ),
      );
      final datasets = observed['datasets']! as List<Object?>;
      final first = datasets.first! as Map<String, Object?>;
      expect(
        () => expectControllerObservations(chart, <String, Object?>{
          ...observed,
          'datasets': [
            <String, Object?>{...first, 'visible': false},
            datasets[1],
          ],
        }, 'self'),
        throwsA(isA<TestFailure>()),
      );
    });
  });

  group('testControllerChartCases', () {
    // A record of the probe of U0: `datasets: [null]` throws a TypeError in
    // `mergeScaleConfig` of `initConfig` (core.config.js:94,
    // `dataset.type`), on both sides.
    testControllerChartCases([
      (
        name: 'an error at initial',
        config: <String, Object?>{
          'type': 'scaleTest',
          'data': <String, Object?>{
            'datasets': <Object?>[null],
          },
        },
        options: <String, Object?>{},
        expected: <String, Object?>{
          'error': <String, Object?>{'at': 'initial', 'name': 'TypeError'},
        },
      ),
    ]);
  });

  group('expectNoStaleScaleKeys', () {
    testWidgets('finds an emitted path in the scale options', (tester) async {
      final chart = acquireChart(_config());
      expectNoStaleScaleKeys(chart, <String, Object?>{
        'color': 'x',
        'scale.ticks.padding': 3.0,
        'scales.category.grid.display': true,
        'scales.radialLinear.angleLines.color': 'x',
      });
      expect(
        () => expectNoStaleScaleKeys(chart, <String, Object?>{
          'scale.ticks.unknownKey': 1.0,
        }),
        throwsA(isA<TestFailure>()),
      );
    });
  });

  group('the spies of test/support/jasmine.dart', () {
    testWidgets('spyOnElementDraw takes the slot of a point', (tester) async {
      final chart = acquireChart(_config());
      final meta = chart.getDatasetMeta(0);
      final original = meta.data[1];
      final calls = spyOnElementDraw(meta, 1);
      expect(meta.data[1], isNot(same(original)));
      expect(meta.data[1].x, original.x);
      chart.draw();
      expect(calls.count(), 1);
      expect(calls.mostRecent().args.first, same(chart.ctx));
      // An update renders: with `animation: false`, it draws at once.
      chart.update();
      expect(calls.count(), 2, reason: 'an update keeps the slot');

      final recording = createMockContext();
      final through = spyOnElementDraw(meta, 2, callThrough: true);
      chart.getDatasetMeta(0).controller!.ctx = recording;
      chart.draw();
      expect(through.count(), 1);
      expect(
        recording.getCalls().where((c) => c['name'] == 'arc'),
        hasLength(3),
        reason:
            'the points 0, 2 (a spy with callThrough) and 3 draw; the spy of '
            'the point 1 does not call through',
      );
    });

    testWidgets('a draw spy of an element with a running animation throws', (
      tester,
    ) async {
      // Upstream, spyOn keeps the object that the animation moves. The spy
      // is a new object: the animation would move the original element.
      final chart = acquireChart({
        ..._config(),
        'options': <String, Object?>{
          'animation': <String, Object?>{'duration': 500},
        },
      });
      final meta = chart.getDatasetMeta(0);
      await tester.pump(const Duration(seconds: 1));
      _data(chart, 0)[1] = 0;
      chart.update();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 100));
      expect(() => spyOnElementDraw(meta, 1), throwsStateError);
      // After the end of the animations, a spy takes the slot.
      await tester.pump(const Duration(seconds: 1));
      spyOnElementDraw(meta, 1);
    });

    testWidgets('spyOnDataset takes the slot of the line', (tester) async {
      final chart = acquireChart(_config());
      final meta = chart.getDatasetMeta(0);
      meta.dataset = LineElement(<String, Object?>{
        'points': meta.data,
        'options': <String, Object?>{'borderWidth': 1},
      });
      final spy = spyOnDataset(meta);
      chart.draw();
      expect(spy.draw.count(), 1);
      expect(spy.draw.mostRecent().args.first, same(chart.ctx));
      (meta.dataset! as LineElement).updateControlPoints(chart.chartArea!);
      expect(spy.updateControlPoints.count(), 1);
    });

    testWidgets('spyOnArrayListener records the _onData calls', (
      tester,
    ) async {
      final chart = acquireChart(_config());
      final data = _data(chart, 0);
      final calls = spyOnArrayListener(
        data,
        chart.getDatasetMeta(0).controller!,
      );
      await runStep(tester, chart, ['push', 0.0, 7.0, 8.0]);
      await runStep(tester, chart, ['splice', 0.0, 1.0, 1.0]);
      expect(calls['_onDataPush']!.count(), 1);
      expect(calls['_onDataPush']!.argsFor(0), [7.0, 8.0]);
      expect(calls['_onDataSplice']!.count(), 1);
      expect(calls['_onDataSplice']!.argsFor(0), [1.0, 1.0]);
      expect(calls['_onDataPop']!.count(), 0);
    });

    test('spyOn replaces a function value of a Map', () {
      final object = <String, Object?>{'hook': (Object? a) => 'original'};
      final spy = spyOn(object, 'hook');
      expect(object['hook'], anyFunction);
      expect(object['hook'], isNot(toHaveBeenCalled()));
      expect(object['hook'].calls, same(spy.calls));
      expect(spyOf(object['hook']), same(spy));
    });

    test('jasmineEquals and objectContaining', () {
      expect(
        <String, Object?>{'a': 1, 'b': double.nan},
        jasmineEquals({
          'a': 1.0,
          'b': double.nan,
        }),
      );
      expect(0.0, isNot(jasmineEquals(-0.0)));
      expect(<String, Object?>{'a': 1, 'b': 2}, objectContaining({'a': 1}));
      expect(
        <String, Object?>{'a': 1},
        isNot(objectContaining({'a': 1, 'b': 2})),
      );
    });
  });
}
