// Original code, not ported from Chart.js: self-test of the controller harness.
@TestOn('vm')
library;

import 'dart:convert';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/draw_recorder.dart';
import '../../support/test_dataset.dart';
import '../canvas/path2d_record.dart';
import '../scales/scale_chart_harness.dart';
import 'controller_chart_harness.dart';

// The self-test of the controller harness (controller_chart_harness.dart,
// tool/reference/controller_chart_common.mjs, Chart.js ADR 0030) and of the
// recorders of test/support/draw_recorder.dart. Most charts use the cartesian test
// controller `scaleTest` of scale_chart_harness.dart: a point for each
// value, with the category scale on x and the linear scale on y. The cases
// of the plugin options (`hits: false`, `observeExtra` and the steps
// `click`, `setTooltip` and `setOption`, Chart.js ADR 0041, section 3) use a
// `line` chart with a title: flutter_test_config.dart registers the
// built-in controllers and plugins.
//
// A probe of U0 (wave 1 of phase 7) ran the generator side on the same test
// controllers in the x64 Node.js and compared each key with this harness:
// the observations, the hit queries, the steps (also `hover` and
// `mouseout` at the center of a point), the draw calls with the element
// draws, a probe of `extra`, the themed run with the light preset and the
// errors at `initial` and at a step. The case 'an error at initial' below
// keeps one record of that probe.

/// The test controller as a chart type.
const _scaleTest = ChartKind('scaleTest');

/// The config of a chart of the test controller: two datasets of four
/// points. A dataset class gives its own controller: `extra` gives the
/// test controller back. The data Lists are new and growable: the cases
/// change them.
ChartConfigurationScope _config({ChartAnimation? animation}) {
  final first = <num?>[1, 5, 3, 4];
  final second = <num?>[2, 1, 6, 2];
  return ChartConfigLowering(
    ChartConfig(
      datasets: [
        TestDataset(_scaleTest, data: first),
        TestDataset(_scaleTest, data: second),
      ],
      labels: const ['a', 'b', 'c', 'd'],
      animation: animation,
    ),
  ).lower();
}

/// [_config] as a Map: the steps `push` and `splice` add the `List<Object?>`
/// of their arguments to the data List, which a typed `List<num?>` rejects.
Map<String, Object?> _mapConfig() => <String, Object?>{
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

/// The config of a line chart with a title: two datasets of four points.
ChartConfigurationScope _lineConfig() => ChartConfigLowering(
  const ChartConfig(
    datasets: [
      LineDataset(label: 'one', data: .values([1, 5, 3, 4])),
      LineDataset(label: 'two', data: .values([2, 1, 6, 2])),
    ],
    labels: ['a', 'b', 'c', 'd'],
    pluginOptions: [
      TitleOptions(display: true, text: ['T']),
    ],
  ),
).lower();

/// The `observeExtra` of the plugin cases: `plugins.title.display`.
Map<String, Object?> _titleExtra(Chart chart) => <String, Object?>{
  'plugins.title': <String, Object?>{
    'display': jsGet(
      jsGet(jsGet(chart.options, 'plugins'), 'title'),
      'display',
    ),
  },
};

/// The data List of the dataset [index] of [chart].
List<Object?> _data(Chart chart, int index) =>
    jsGet((jsGet(chart.data, 'datasets')! as List<Object?>)[index], 'data')!
        as List<Object?>;

/// The rounded center of the element [index] of the dataset [dataset].
(double, double) _center(Chart chart, int dataset, int index) {
  final element = chart.getDatasetMeta(dataset).data[index] as VisualElement;
  final center = element.getCenterPoint();
  return (center.dx.roundToDouble(), center.dy.roundToDouble());
}

/// The active elements of [chart] as `[datasetIndex, index]`.
List<List<int>> _active(Chart chart) => [
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
      final chart = acquireChartRoot(_config());
      final (x, y) = _center(chart, 0, 1);
      final items = chart.getElementsAtEventForMode(
        ReferenceEvent(x, y),
        const PointInteractionMode(),
        <String, Object?>{'intersect': true, 'axis': InteractionAxis.xy},
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
          <Object?>[
            const PointInteractionMode(),
            true,
            InteractionAxis.xy,
            false,
          ],
          <Object?>[
            const IndexInteractionMode(),
            false,
            InteractionAxis.x,
            false,
          ],
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
      final chart = acquireChartRoot(_config());
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
      final chart = acquireChartRoot(_config());
      await runStep(tester, chart, ['setDatasetVisibility', 1.0, false]);
      expect(chart.isDatasetVisible(1), isFalse);
      expect(chart.isDatasetVisible(0), isTrue);
      await runStep(tester, chart, ['toggleDataVisibility', 2.0]);
      expect(chart.getDataVisibility(2), isFalse);
      expect(chart.getDataVisibility(1), isTrue);
    });

    testWidgets('setActive', (tester) async {
      final chart = acquireChartRoot(_config());
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
      final chart = acquireChart(_mapConfig());
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
      final chart = acquireChartRoot(_config());
      final (x, y) = _center(chart, 0, 1);
      await runStep(tester, chart, ['hover', x, y]);
      expect(_active(chart), [
        [0.0, 1.0],
      ]);
      await runStep(tester, chart, ['mouseout', x, y]);
      expect(_active(chart), isEmpty);
    });

    testWidgets('click, setTooltip and setOption', (tester) async {
      final chart = acquireChartRoot(_lineConfig());
      final box = (chart.legend! as Legend).legendHitBoxes[1];
      expect(chart.isDatasetVisible(1), isTrue);
      // A click on legend item 1 calls the default onClick of the legend.
      await runStep(tester, chart, [
        'click',
        box.center.dx.roundToDouble(),
        box.center.dy.roundToDouble(),
      ]);
      expect(chart.isDatasetVisible(1), isFalse);
      expect(chart.isDatasetVisible(0), isTrue);
      await runStep(tester, chart, [
        'setTooltip',
        <Object?>[
          <Object?>[0.0, 1.0],
        ],
        10.0,
        10.0,
      ]);
      final tooltip = chart.tooltip!;
      expect(
        [
          for (final item in tooltip.getActiveElements())
            [item.datasetIndex, item.index],
        ],
        [
          [0.0, 1.0],
        ],
      );
      expect(tooltip.opacity, 1.0);
      final top = chart.chartArea!.top;
      await runStep(tester, chart, [
        'setOption',
        'plugins.title.display',
        false,
      ]);
      // The title options are one object (Chart.js ADR 0197).
      expect(
        (jsGet(jsGet(chart.options, 'plugins'), 'title')! as TitleOptions)
            .display,
        isFalse,
      );
      expect(
        chart.chartArea!.top,
        lessThan(top),
        reason: 'the update after the write removes the title box',
      );
    });

    testWidgets('an unknown step throws', (tester) async {
      final chart = acquireChartRoot(_config());
      expect(
        () => runStep(tester, chart, ['jump']),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('expectControllerObservations', () {
    testWidgets('passes for the observation of the chart', (tester) async {
      final chart = acquireChartRoot(_config());
      final (x, y) = _center(chart, 0, 1);
      final observed = observeControllers(
        chart,
        expectedHits: <String, Object?>{
          'points': <Object?>[
            <Object?>[x, y],
          ],
          'queries': <Object?>[
            <Object?>[
              const PointInteractionMode(),
              true,
              InteractionAxis.xy,
              false,
            ],
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
      final chart = acquireChartRoot(_config());
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

    testWidgets('hits false and observeExtra', (tester) async {
      final chart = acquireChartRoot(_lineConfig());
      final own = observeControllers(
        chart,
        expectedHits: null,
        observeExtra: _titleExtra,
      );
      expect(own.keys, [
        'chartArea',
        'scales',
        'stacks',
        'datasets',
        'plugins.title',
      ]);
      expectControllerObservations(
        chart,
        own,
        'self',
        hits: false,
        observeExtra: _titleExtra,
      );
      void fails(
        Map<String, Object?> expected,
        String reason, {
        bool extra = true,
      }) {
        expect(
          () => expectControllerObservations(
            chart,
            expected,
            'self',
            hits: false,
            observeExtra: extra ? _titleExtra : null,
          ),
          throwsA(isA<TestFailure>()),
          reason: reason,
        );
      }

      fails(<String, Object?>{
        ...own,
        'plugins.title': <String, Object?>{'display': false},
      }, 'a changed extra value');
      fails(
        <String, Object?>{...own}..remove('plugins.title'),
        'a missing extra key',
      );
      fails(<String, Object?>{
        ...own,
        'plugins.legend': null,
      }, 'an extra expected key');
      fails(own, 'no observeExtra', extra: false);
      fails(<String, Object?>{
        ...own,
        'hits': <String, Object?>{},
      }, 'a hits key with hits: false');
    });

    testWidgets('a changed value fails', (tester) async {
      final chart = acquireChartRoot(_config());
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
    // A Map config: the dataset null, which no typed config holds.
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
      final chart = acquireChartRoot(_config());
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

  group('the recorders of test/support/draw_recorder.dart', () {
    testWidgets('recordElementDraws takes the slot of a point', (tester) async {
      final chart = acquireChartRoot(_config());
      final meta = chart.getDatasetMeta(0);
      final original = meta.data[1];
      final draws = recordElementDraws(meta, 1);
      expect(meta.data[1], isNot(same(original)));
      expect(meta.data[1].x, original.x);
      chart.draw();
      expect(draws, hasLength(1));
      expect(draws.last.ctx, same(chart.ctx));
      // An update renders: with `animation: false`, it draws at once.
      chart.update();
      expect(draws, hasLength(2), reason: 'an update keeps the slot');

      final recording = createMockContext();
      final through = recordElementDraws(meta, 2, drawThrough: true);
      chart.getDatasetMeta(0).controller!.ctx = recording;
      chart.draw();
      expect(through, hasLength(1));
      expect(
        recording.getCalls().where((c) => c['name'] == 'arc'),
        hasLength(3),
        reason:
            'the points 0, 2 (a recorder with drawThrough) and 3 draw; the '
            'recorder of the point 1 does not draw through',
      );
    });

    testWidgets('a draw recorder of an element with a running animation '
        'throws', (tester) async {
      // Upstream, spyOn keeps the object that the animation moves. The
      // recorder is a new object: the animation would move the original
      // element.
      final chart = acquireChartRoot(
        _config(
          animation: const ChartAnimation(
            duration: Duration(milliseconds: 500),
          ),
        ),
      );
      final meta = chart.getDatasetMeta(0);
      await tester.pump(const Duration(seconds: 1));
      _data(chart, 0)[1] = 0;
      chart.update();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 100));
      expect(() => recordElementDraws(meta, 1), throwsStateError);
      // After the end of the animations, a recorder takes the slot.
      await tester.pump(const Duration(seconds: 1));
      recordElementDraws(meta, 1);
    });

    testWidgets('recordLineCalls takes the slot of the line', (tester) async {
      final chart = acquireChartRoot(_config());
      final meta = chart.getDatasetMeta(0);
      meta.dataset = LineElement(<String, Object?>{
        'points': meta.data,
        'options': LineOptions({'borderWidth': 1}),
      });
      final calls = recordLineCalls(meta);
      chart.draw();
      expect(calls.draws, hasLength(1));
      expect(calls.draws.last.ctx, same(chart.ctx));
      (meta.dataset! as LineElement).updateControlPoints(chart.chartArea);
      expect(calls.updates, hasLength(1));
    });

    testWidgets('recordArrayCalls records the array calls', (tester) async {
      final chart = acquireChart(_mapConfig());
      final data = _data(chart, 0);
      final calls = recordArrayCalls(data, chart.getDatasetMeta(0).controller!);
      await runStep(tester, chart, ['push', 0.0, 7.0, 8.0]);
      await runStep(tester, chart, ['splice', 0.0, 1.0, 1.0]);
      expect(calls.pushes, [
        [7.0, 8.0],
      ]);
      expect(calls.splices, hasLength(1));
      expect(calls.splices.single.index, 1);
      expect(calls.splices.single.deleteCount, 1);
      expect(calls.splices.single.items, isEmpty);
      expect(calls.pops, 0);
    });
  });
}
