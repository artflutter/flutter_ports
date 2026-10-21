// Original code, not ported from Chart.js: scatter controller reference tests.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs/src/controllers/controller.scatter.dart';
import 'package:flutter_chartjs/src/core/core.animator.dart' show animator;
import 'package:flutter_chartjs/src/core/core.config.dart' show themeConfigKey;
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/core/core.element.dart';
import 'package:flutter_chartjs/src/core/core.registry.dart' show registry;
import 'package:flutter_chartjs/src/elements/element.line.dart';
import 'package:flutter_chartjs/src/helpers/helpers.collection.dart'
    show notifyArrayListeners;
import 'package:flutter_chartjs/src/js/js_array.dart' show jsSplice;
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/theme/compile.dart';
import 'package:flutter_chartjs/src/theme/presets.dart';
import 'package:flutter_chartjs/src/types/basic.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import '../scales/scale_chart_harness.dart';
import 'controller_chart_harness.dart';
import 'controller_scatter_reference.dart';

// The port-only reference tests of
// lib/src/controllers/controller.scatter.dart (Chart.js ADR 0030). The spec
// port is test/specs/controller.scatter_test.dart.
//
// The reference group compares real scatter charts with the charts of
// tool/reference/controller_scatter_reference.mjs: a build of the pinned
// Chart.js in Node.js v24.12.0 on x64 (Chart.js ADR 0032), with a mock
// context that measures text in Liberation Sans 2.1.5. Each chart comes from
// acquireChart in a testWidgets case (Chart.js ADR 0022). The case runs its
// steps and compares the observations, the hit queries and the draw calls
// with the element draws (controller_chart_harness.dart).
//
// The 6 cases of Chart.js ADR 0030, section 7 run two times: unthemed, and
// with the light preset (theming.md section 8 test 3). The cases whose names
// start with `parsed:` (Chart.js ADR 0036, section 9) or `interfaces:`
// (Chart.js ADR 0028, section 8) run unthemed only. The groups `parsed
// data` and `interfaces` hold the pin tests that need no generated value:
// relations between two charts of the port, the reads of one chart, and the
// results of a probe on the pinned build (see the group `showLine`).
//
// flutter_test_config.dart registers the scatter controller with the
// built-in components before main() (Chart.js ADR 0030, section 3 item 4).

/// The named functions of the configs of the generator, with the same
/// bodies.
final Map<String, Object?> _functions = {
  // (ctx) => (ctx.p0DataIndex === 1 ? 'red' : undefined)
  'segColor': (Object? ctx) =>
      jsGet(ctx, 'p0DataIndex') == 1 ? 'red' : undefined,
  // (ctx) => (ctx.p1DataIndex === 3 ? 5 : undefined)
  'segWidth': (Object? ctx) => jsGet(ctx, 'p1DataIndex') == 3 ? 5.0 : undefined,
  // (ctx) => {
  //   if (ctx.dataIndex === 1) ctx.parsed.x = 10;
  //   return 3;
  // }
  'radiusWrite': (Object? ctx) {
    if (jsGet(ctx, 'dataIndex') == 1) {
      (jsGet(ctx, 'parsed')! as AnyObject)['x'] = 10.0;
    }
    return 3.0;
  },
};

/// `chart.data.datasets[index]`.
AnyObject _dataset(Chart chart, int index) =>
    (jsGet(chart.data, 'datasets')! as List<Object?>)[index]! as AnyObject;

/// `chart.data.datasets[index].data`.
List<Object?> _data(Chart chart, int index) =>
    jsGet(_dataset(chart, index), 'data')! as List<Object?>;

/// Object data `{x, y}` for the [points] `(x, y)`.
List<Object?> _xy(List<(double, double?)> points) => <Object?>[
  for (final (x, y) in points) <String, Object?>{'x': x, 'y': y},
];

/// The config of a scatter chart with the [datasets] and the [options].
AnyObject _scatter(List<Object?> datasets, [AnyObject? options]) =>
    <String, Object?>{
      'type': 'scatter',
      'data': <String, Object?>{'datasets': datasets},
      'options': ?options,
    };

/// `x`, `y`, `skip` and `stop` of each point of each dataset of [chart].
List<Object?> _points(Chart chart) => [
  for (var i = 0; i < (jsGet(chart.data, 'datasets')! as List).length; i++)
    [
      for (final point in chart.getDatasetMeta(i.toDouble()).data)
        [
          for (final key in const ['x', 'y', 'skip', 'stop'])
            (point as types.ElementPropertyRead)[key],
        ],
    ],
];

/// Expects `line.points` of the dataset 0 of [chart] to have the elements
/// of `meta.data` in the same order (Chart.js ADR 0028, section 3).
void _expectLinePoints(Chart chart) {
  final meta = chart.getDatasetMeta(0);
  final line = meta.dataset! as LineElement;
  expect(line.points.length, meta.data.length);
  for (var i = 0; i < meta.data.length; i++) {
    expect(line.points[i], same(meta.data[i]), reason: 'point $i');
  }
}

void main() {
  testReferenceOrigin(
    node: controllerScatterReferenceNode,
    arch: controllerScatterReferenceArch,
    dist: controllerScatterReferenceDist,
    commit: controllerScatterReferenceCommit,
  );
  testReferenceWidths(controllerScatterReferenceWidths);

  test('the reference has the 6 cases of Chart.js ADR 0030 first', () {
    final names = [for (final c in controllerScatterReference) c.name];
    bool prefixed(String n) =>
        n.startsWith('parsed:') || n.startsWith('interfaces:');
    expect(names.take(6), [
      'default',
      'showLine true',
      'a visible x range',
      'object data',
      'getLabelAndValue with labels',
      'a hidden dataset',
    ]);
    expect(names.length, greaterThan(6));
    expect(names.skip(6).where((n) => !prefixed(n)), isEmpty);
  });

  testControllerChartCases(controllerScatterReference, functions: _functions);

  group('theming.md §8 test 3: the light preset', () {
    testControllerChartCases(
      controllerScatterReference,
      functions: _functions,
      theme: compileChartTheme(ChartThemes.light),
    );

    testWidgets('the light preset leaves no stale scale key', (tester) async {
      final snapshot = jsonDecode(
        File(
          'test/port/theme/light_snapshot.json',
        ).readAsStringSync(),
      ) as Map<String, Object?>;
      final config =
          copyReference(controllerScatterReference.first.config, _functions)!
              as AnyObject;
      config[themeConfigKey] = compileChartTheme(ChartThemes.light);
      expectNoStaleScaleKeys(acquireChart(config), snapshot);
    });
  });

  // The pin tests of the parsed-data spec, section 7.3, that need no
  // generated value. The generated cases `parsed: ...` give the upstream
  // values of the same configs.
  group('parsed data', () {
    testWidgets('parsing false and a null item throw a TypeError', (
      tester,
    ) async {
      expect(
        () => acquireChart(
          _scatter(<Object?>[
            <String, Object?>{
              'data': <Object?>[
                <String, Object?>{'x': 0.0, 'y': 1.0},
                null,
              ],
              'parsing': false,
            },
          ]),
        ),
        throwsA(isA<TypeError>()),
      );
    });

    testWidgets('a logarithmic x and parsing false: an item without x gives '
        'the min pixel and skip false, an item with x null gives NaN and '
        'skip true', (tester) async {
      Chart chart(AnyObject first) => acquireChart(
        _scatter(
          <Object?>[
            <String, Object?>{
              'data': <Object?>[
                first,
                <String, Object?>{'x': 10.0, 'y': 1.0},
                <String, Object?>{'x': 100.0, 'y': 2.0},
              ],
              'parsing': false,
            },
          ],
          <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'type': 'logarithmic'},
            },
          },
        ),
      );

      final without = chart(<String, Object?>{'y': 5.0});
      final point =
          without.getDatasetMeta(0).data[0] as types.ElementPropertyRead;
      expect(point['x'], without.scales['x']!.getPixelForDecimal(0));
      expect(point['skip'], isFalse);

      final withNull = chart(<String, Object?>{'x': null, 'y': 5.0});
      final nullPoint =
          withNull.getDatasetMeta(0).data[0] as types.ElementPropertyRead;
      expect(nullPoint['x'], isNaN);
      expect(nullPoint['skip'], isTrue);
    });

    testWidgets('an animated update ends at the points of an update without '
        'animation', (tester) async {
      // Without animation, each update writes into the points (:127). With
      // animation, the update gives a new object to updateElement (:144).
      // The first update of an animated chart resets the points first (a
      // direct update). The second update with new data of the same length
      // has no reset: only the new object writes `raw` and `parsed`.
      AnyObject config(Object? animation) => _scatter(
        <Object?>[
          <String, Object?>{
            'data': _xy(const [
              (0.0, 3.0),
              (1.0, 1.0),
              (2.0, null),
              (3.0, 4.0),
              (4.0, 2.0),
            ]),
            'showLine': true,
            'segment': <String, Object?>{'borderColor': _functions['segColor']},
          },
          <String, Object?>{
            'data': _xy(const [
              (0.0, 1.0),
              (1.0, 2.0),
              (4.0, 3.0),
              (5.0, 2.0),
              (6.0, 1.0),
            ]),
            'spanGaps': 1.0,
          },
        ],
        <String, Object?>{'animation': animation},
      );
      final animated = acquireChart(
        config(<String, Object?>{'duration': 100.0}),
      );
      final direct = acquireChart(config(false));
      await pumpFrames(() => !animator.running(animated));
      expect(_points(animated), referenceMatcher(_points(direct)));

      for (final chart in [animated, direct]) {
        _dataset(chart, 0)['data'] = _xy(const [
          (0.0, 2.0),
          (1.0, 7.0),
          (2.0, 5.0),
          (3.0, null),
          (4.0, 1.0),
        ]);
        _dataset(chart, 1)['data'] = _xy(const [
          (0.0, 4.0),
          (2.0, 3.0),
          (3.0, 2.0),
          (5.0, 1.0),
          (6.0, 0.0),
        ]);
        chart.update();
      }
      expect(animator.running(animated), isTrue);
      await pumpFrames(() => !animator.running(animated));
      expect(_points(animated), referenceMatcher(_points(direct)));
      // The writes of :135-136 with `segment`.
      final point = animated.getDatasetMeta(0).data[1] as Element;
      expect(point['raw'], same(_data(animated, 0)[1]));
      expect(point['parsed'], same(animated.getDatasetMeta(0).parsed[1]));
    });
  });

  // The pin tests of the interfaces spec, section 7.3, that need no
  // generated value.
  group('interfaces', () {
    group('line.points with showLine true', () {
      AnyObject config() => _scatter(<Object?>[
        <String, Object?>{
          'data': _xy(const [(1.0, 1.0), (2.0, 4.0), (3.0, 2.0), (4.0, 3.0)]),
          'showLine': true,
        },
      ]);

      testWidgets('after chart.update()', (tester) async {
        final chart = acquireChart(config())..update();
        _expectLinePoints(chart);
      });

      testWidgets('after data.push and chart.update()', (tester) async {
        final chart = acquireChart(config());
        final item = <String, Object?>{'x': 5.0, 'y': 1.0};
        final data = _data(chart, 0)..add(item);
        notifyArrayListeners(data, 'push', [item]);
        chart.update();
        expect(chart.getDatasetMeta(0).data.length, 5);
        _expectLinePoints(chart);
      });

      testWidgets('after a splice and chart.update()', (tester) async {
        final chart = acquireChart(config());
        final data = _data(chart, 0);
        final item = <String, Object?>{'x': 2.5, 'y': 9.0};
        jsSplice(data, 1, 2, [item]);
        notifyArrayListeners(data, 'splice', [1.0, 2.0, item]);
        chart.update();
        expect(chart.getDatasetMeta(0).data.length, 3);
        _expectLinePoints(chart);
      });
    });

    // The switch of controller.scatter.js:71-95 (Chart.js issue #11333).
    // The expected results come from a probe on the pinned build in Node.js
    // v24.12.0 on x64 (controller_chart_common.mjs, makeChart): a dataset
    // `showLine` switched on, off and on (with `borderWidth: 4`), the root
    // option `showLine` switched on, and `showLine` at creation, then off.
    // After each update it logged `meta.dataset instanceof LineElement`,
    // `'dataset' in meta`, `datasetElementType`, the points and
    // `getMaxOverflow()`. Its output: the dataset element is a `LineElement`
    // exactly while `showLine` is truthy, a new element after each switch on,
    // no `dataset` key after a switch off, and `getMaxOverflow()` 8 (with
    // `borderWidth: 4`) and 5 (the defaults).
    // The generator cannot give these cases: it has no step that writes an
    // option.
    group('showLine', () {
      AnyObject config(AnyObject extra) => _scatter(<Object?>[
        <String, Object?>{
          'data': _xy(const [(1.0, 2.0), (2.0, 4.0), (3.0, 1.0)]),
          ...extra,
        },
      ]);

      /// Expects the dataset element of the dataset 0 of [chart]: a
      /// `LineElement` with the points of `meta.data` and the dataset
      /// element type `LineElement` for [line], else no dataset element and
      /// the type `false`. Expects `getMaxOverflow()` to be [maxOverflow].
      void expectState(Chart chart, {required bool line, num? maxOverflow}) {
        final meta = chart.getDatasetMeta(0);
        final controller = meta.controller! as ScatterController;
        if (line) {
          expect(meta.dataset, isA<LineElement>());
          expect(
            controller.datasetElementType,
            same(registry.getElement('line')),
          );
          expect(controller.datasetElementType, same(LineElement.jsClass));
          _expectLinePoints(chart);
        } else {
          expect(meta.dataset, isNull);
          expect(controller.datasetElementType, isFalse);
        }
        expect(controller.getMaxOverflow(), maxOverflow);
      }

      testWidgets('a dataset showLine switched on, off and on', (
        tester,
      ) async {
        final chart = acquireChart(
          config(<String, Object?>{'borderWidth': 4.0}),
        );
        expectState(chart, line: false, maxOverflow: 8);

        _dataset(chart, 0)['showLine'] = true;
        chart.update();
        expectState(chart, line: true, maxOverflow: 8);
        final first = chart.getDatasetMeta(0).dataset;

        _dataset(chart, 0)['showLine'] = false;
        chart.update();
        expectState(chart, line: false, maxOverflow: 8);

        _dataset(chart, 0)['showLine'] = true;
        chart.update();
        expectState(chart, line: true, maxOverflow: 8);
        expect(chart.getDatasetMeta(0).dataset, isNot(same(first)));
      });

      testWidgets('the root option showLine switched on', (tester) async {
        final chart = acquireChart(config(<String, Object?>{}));
        chart.options['showLine'] = true;
        chart.update();
        expectState(chart, line: true, maxOverflow: 5);
      });

      testWidgets('a dataset showLine at the creation, then off', (
        tester,
      ) async {
        final chart = acquireChart(
          config(<String, Object?>{'showLine': true}),
        );
        expectState(chart, line: true, maxOverflow: 5);

        _dataset(chart, 0)['showLine'] = false;
        chart.update();
        expectState(chart, line: false, maxOverflow: 5);
      });
    });

    testWidgets('getLabelAndValue gives the label value, or an empty string '
        'for a falsy label', (tester) async {
      for (final (labels, expected) in <(List<Object?>, List<Object?>)>[
        (
          <Object?>[
            <Object?>['line 1', 'line 2'],
            5.0,
            0.0,
            'd',
            undefined,
          ],
          <Object?>[5.0, '', 'd', '', ''],
        ),
        (
          <Object?>[
            <Object?>['line 1', 'line 2'],
            7.0,
            '',
            null,
            'e',
          ],
          <Object?>[7.0, '', '', 'e', ''],
        ),
      ]) {
        final chart = acquireChart(<String, Object?>{
          'type': 'scatter',
          'data': <String, Object?>{
            'labels': labels,
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[
                  for (var v = 1.0; v <= 6; v++)
                    <String, Object?>{'x': v, 'y': 7 - v},
                ],
              },
            ],
          },
        });
        final chartLabels = jsGet(chart.data, 'labels')! as List<Object?>;
        final controller = chart.getDatasetMeta(0).controller!;
        final first = controller.getLabelAndValue(0).label;
        expect(first, same(chartLabels[0]));
        expect(first, isA<List<Object?>>());
        expect([
          for (var i = 1; i < 6; i++)
            controller.getLabelAndValue(i.toDouble()).label,
        ], expected);
        expect(controller.getLabelAndValue(0).value, '(1, 6)');
      }
    });
  });
}
