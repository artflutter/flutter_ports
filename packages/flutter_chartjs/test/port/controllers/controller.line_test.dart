// Original code, not ported from Chart.js: line controller reference tests.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs/src/core/core.animator.dart' show animator;
import 'package:flutter_chartjs/src/core/core.config.dart' show themeConfigKey;
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/core/core.datasetController.dart'
    show stacksOf;
import 'package:flutter_chartjs/src/core/core.element.dart';
import 'package:flutter_chartjs/src/elements/element.line.dart';
import 'package:flutter_chartjs/src/helpers/helpers.collection.dart'
    show notifyArrayListeners;
import 'package:flutter_chartjs/src/js/js_array.dart'
    show jsObjectKeys, jsSplice;
import 'package:flutter_chartjs/src/js/js_class.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/theme/compile.dart';
import 'package:flutter_chartjs/src/theme/presets.dart';
import 'package:flutter_chartjs/src/types/basic.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import '../scales/scale_chart_harness.dart';
import 'controller_chart_harness.dart';
import 'controller_line_reference.dart';

// The port-only reference tests of lib/src/controllers/controller.line.dart
// (Chart.js ADR 0030). The spec port is test/specs/controller.line_test.dart.
//
// The reference group compares real line charts with the charts of
// tool/reference/controller_line_reference.mjs: a build of the pinned
// Chart.js in Node.js v24.12.0 on x64 (Chart.js ADR 0010), with a mock
// context that measures text in Liberation Sans 2.1.5. Each chart comes from
// acquireChart in a testWidgets case (Chart.js ADR 0022). The case runs its
// steps and compares the observations, the hit queries and the draw calls
// with the element draws (controller_chart_harness.dart).
//
// The 17 cases of Chart.js ADR 0030, section 7 run two times: unthemed, and
// with the light preset (theming.md section 8 test 3). The cases whose names
// start with `parsed:` (Chart.js ADR 0027, section 9) or `interfaces:`
// (Chart.js ADR 0028, section 8) run unthemed only. The case `interfaces: a
// dataset element of another class` runs in its own group: the group
// registers the element class `otherLine` of the generator and names it in
// the line defaults. The groups `parsed data` and `interfaces` hold the pin
// tests that need no generated value: relations between two charts of the
// port, and the reads of one chart.
//
// flutter_test_config.dart registers the line controller with the
// built-in components before main() (Chart.js ADR 0030, section 3 item 4).

/// The name of the case with a dataset element of another class.
const String _otherLineCase = 'interfaces: a dataset element of another class';

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

/// The probes of the key `extra` of the generator, with the same bodies.
final Map<String, Object? Function(Chart chart)> _extras = {
  'pointParsed': _pointParsed,
  'stackKeys': _stackKeys,
};

/// The probe `pointParsed` of the generator: the property `parsed` of each
/// point of the dataset 0.
Object? _pointParsed(Chart chart) => [
  for (final point in chart.getDatasetMeta(0).data)
    (point as types.ElementPropertyRead)['parsed'],
];

/// The probe `stackKeys` of the generator: the keys of `_stacks` of each
/// parsed item of the dataset 0 (`p._stacks || {}`).
Object? _stackKeys(Chart chart) => [
  for (final item in chart.getDatasetMeta(0).parsed)
    switch (stacksOf(item)) {
      final Map<String, Object?> stacks => jsObjectKeys(stacks),
      _ => const <String>[],
    },
];

/// The element class `OtherLine` of the generator: `class OtherLine extends
/// Element { static id = 'otherLine'; }`.
final JsClass _otherLine = JsClass(
  'OtherLine',
  superclass: Element.jsClass,
  statics: {'id': 'otherLine'},
  construct: (newTarget, args) => Element(),
);

/// `chart.data.datasets[index].data`.
List<Object?> _data(Chart chart, int index) =>
    jsGet(
          (jsGet(chart.data, 'datasets')! as List<Object?>)[index],
          'data',
        )!
        as List<Object?>;

/// The config of a line chart with the labels a to e and the [datasets].
AnyObject _lines(List<Object?> datasets, [AnyObject? options]) =>
    <String, Object?>{
      'type': 'line',
      'data': <String, Object?>{
        'labels': <Object?>['a', 'b', 'c', 'd', 'e'],
        'datasets': datasets,
      },
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
    node: controllerLineReferenceNode,
    arch: controllerLineReferenceArch,
    dist: controllerLineReferenceDist,
    commit: controllerLineReferenceCommit,
  );
  testReferenceWidths(controllerLineReferenceWidths);

  test('the reference has the 17 cases of Chart.js ADR 0030 first', () {
    final names = [for (final c in controllerLineReference) c.name];
    bool prefixed(String n) =>
        n.startsWith('parsed:') || n.startsWith('interfaces:');
    expect(names.first, 'default');
    expect(names.length, greaterThanOrEqualTo(17));
    expect(names.take(17).where(prefixed), isEmpty);
    expect(names.skip(17).where((n) => !prefixed(n)), isEmpty);
    expect(names, contains(_otherLineCase));
  });

  final cases = [
    for (final c in controllerLineReference)
      if (c.name != _otherLineCase) c,
  ];

  testControllerChartCases(cases, functions: _functions, extras: _extras);

  group('a dataset element of another class', () {
    setUp(() {
      // The defaults restore of flutter_test_config.dart puts the line
      // defaults back after the test. It does not reset the registry.
      Chart.register([_otherLine]);
      addTearDown(() => Chart.unregister([_otherLine]));
      (jsGet(jsGet(Chart.defaults, 'datasets'), 'line')!
              as AnyObject)['datasetElementType'] =
          'otherLine';
    });

    testControllerChartCases(
      [
        for (final c in controllerLineReference)
          if (c.name == _otherLineCase) c,
      ],
      functions: _functions,
      extras: _extras,
    );

    testWidgets('the update writes the four properties of the line by name, '
        'and the draw throws a TypeError', (tester) async {
      // A plugin that cancels the draw of the chart: the update runs, the
      // draw of the line controller does not.
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'labels': <Object?>['a', 'b', 'c'],
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[1.0, 2.0, 3.0],
            },
          ],
        },
        'plugins': <Object?>[
          <String, Object?>{'id': 'noDraw', 'beforeDraw': (Object? _) => false},
        ],
      });
      final meta = chart.getDatasetMeta(0);
      final line = meta.dataset! as types.PropertyAccess;
      expect(line, isNot(isA<types.LineElement>()));
      expect(line['_chart'], same(chart));
      expect(line['_datasetIndex'], 0);
      expect(line['_decimated'], isFalse);
      // `line.points = points`: the same array (controller.line.js:60).
      expect(line['points'], same(meta.data));
      expect(meta.controller!.draw, throwsA(isA<TypeError>()));
    });
  });

  group('theming.md §8 test 3: the light preset', () {
    testControllerChartCases(
      cases,
      functions: _functions,
      extras: _extras,
      theme: compileChartTheme(ChartThemes.light),
    );

    testWidgets('the light preset leaves no stale scale key', (tester) async {
      final snapshot =
          jsonDecode(
                File(
                  'test/port/theme/light_snapshot.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      final config =
          copyReference(controllerLineReference.first.config, _functions)!
              as AnyObject;
      config[themeConfigKey] = compileChartTheme(ChartThemes.light);
      expectNoStaleScaleKeys(acquireChart(config), snapshot);
    });
  });

  // The pin tests of the parsed-data spec, section 7.3, that need no
  // generated value. The generated cases `parsed: ...` give the upstream
  // values of the same configs.
  group('parsed data', () {
    testWidgets('stacked List items with parsing false take a stack object '
        'with the key of the value axis', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'labels': <Object?>['a', 'b'],
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[
                <Object?>[0.0, 1.0],
                <Object?>[1.0, 2.0],
              ],
              'parsing': false,
            },
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'y': <String, Object?>{'stacked': true},
          },
        },
      });
      final meta = chart.getDatasetMeta(0);
      for (final item in meta.parsed) {
        expect(item, isA<List<Object?>>());
        expect(jsObjectKeys(stacksOf(item)! as AnyObject), ['y']);
      }
      for (final point in meta.data) {
        final read = point as types.ElementPropertyRead;
        expect(read['x'], isNaN);
        expect(read['skip'], isTrue);
      }
    });

    testWidgets("spanGaps '2' gives the points of spanGaps 2", (
      tester,
    ) async {
      AnyObject config(Object? spanGaps) => <String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[
                for (final (x, y) in const [
                  (0.0, 3.0),
                  (1.0, 5.0),
                  (4.0, 2.0),
                  (6.0, 4.0),
                  (9.0, 1.0),
                ])
                  <String, Object?>{'x': x, 'y': y},
              ],
              'spanGaps': spanGaps,
            },
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{'type': 'linear'},
          },
        },
      };
      final points = _points(acquireChart(config('2')));
      expect(points, referenceMatcher(_points(acquireChart(config(2.0)))));
      // The stops of the gaps 3 and 2.5: the compare is not empty.
      expect(
        [for (final p in (points[0]! as List).cast<List<Object?>>()) p[3]],
        [false, false, true, false, true],
      );
    });

    testWidgets('an animated update ends at the points of an update without '
        'animation', (tester) async {
      // Without animation, each update writes into the points (:91). With
      // animation, the update gives a new object to updateElement. The
      // first update of an animated chart resets the points first (a direct
      // update). The second update with new data of the same length has no
      // reset: only the new object writes `raw` and `parsed`.
      AnyObject config(Object? animation) => _lines(
        <Object?>[
          <String, Object?>{
            'data': <Object?>[3.0, 1.0, null, 4.0, 2.0],
            'segment': <String, Object?>{'borderColor': _functions['segColor']},
          },
          <String, Object?>{
            'data': <Object?>[1.0, 2.0, 3.0, 2.0, 1.0],
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
        (jsGet(chart.data, 'datasets')! as List<Object?>).cast<AnyObject>()
          ..[0]['data'] = <Object?>[2.0, 7.0, 5.0, null, 1.0]
          ..[1]['data'] = <Object?>[4.0, 3.0, 2.0, 1.0, 0.0];
        chart.update();
      }
      expect(animator.running(animated), isTrue);
      await pumpFrames(() => !animator.running(animated));
      expect(_points(animated), referenceMatcher(_points(direct)));
      // The writes of :106-107 with `segment`.
      final point = animated.getDatasetMeta(0).data[1] as Element;
      expect(point['raw'], 7.0);
      expect(point['parsed'], same(animated.getDatasetMeta(0).parsed[1]));
    });
  });

  // The pin tests of the interfaces spec, section 7.3, that need no
  // generated value.
  group('interfaces', () {
    group('line.points', () {
      AnyObject config() => _lines(<Object?>[
        <String, Object?>{
          'data': <Object?>[1.0, 2.0, 3.0, 4.0],
        },
      ]);

      testWidgets('after chart.update()', (tester) async {
        final chart = acquireChart(config())..update();
        _expectLinePoints(chart);
      });

      testWidgets('after data.push and chart.update()', (tester) async {
        final chart = acquireChart(config());
        final data = _data(chart, 0)..add(5.0);
        notifyArrayListeners(data, 'push', [5.0]);
        chart.update();
        expect(chart.getDatasetMeta(0).data.length, 5);
        _expectLinePoints(chart);
      });

      testWidgets('after a splice and chart.update()', (tester) async {
        final chart = acquireChart(config());
        final data = _data(chart, 0);
        jsSplice(data, 1, 2, [9.0]);
        notifyArrayListeners(data, 'splice', [1.0, 2.0, 9.0]);
        chart.update();
        expect(chart.getDatasetMeta(0).data.length, 3);
        _expectLinePoints(chart);
      });
    });

    // U-line-R1 of the wave 2 review: a plugin that returns false from
    // `beforeLayout` leaves `chart.chartArea` unset, and the draw of the
    // line (:140) gives it to `updateControlPoints`. The expected results
    // come from the pinned build in Node.js v24.12.0 on x64 (a probe of the
    // fix of U-line-R1, recorded in phase7/review/wave2/U-line-report.md):
    // only `capBezierPoints` with two points or more throws. The generator
    // cannot give these cases: its observation reads `chartArea.left`.
    group('a plugin cancels the first layout', () {
      AnyObject config(Map<String, Object?> dataset) => <String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'labels': <Object?>['a', 'b', 'c'],
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[1.0, 2.0, 3.0],
              ...dataset,
            },
          ],
        },
        'plugins': <Object?>[
          <String, Object?>{
            'id': 'noLayout',
            'beforeLayout': (Object? _) => false,
          },
        ],
      };

      testWidgets('tension 0.4: the draw throws a TypeError', (tester) async {
        expect(
          () => acquireChart(config(<String, Object?>{'tension': 0.4})),
          throwsA(isA<TypeError>()),
        );
      });

      // Open item 1 of U-line-report.md: W2-int changed the shared layer
      // (`ChartArea?` in `updateControlPoints`), and these cases run.
      group('the draw does not throw', () {
        for (final (name, dataset) in <(String, Map<String, Object?>)>[
          ('no tension', {}),
          ('clip false', {'clip': false}),
          (
            'tension 0.4 and capBezierPoints false',
            {'tension': 0.4, 'capBezierPoints': false},
          ),
          (
            'tension 0.4 and one point',
            {
              'tension': 0.4,
              'data': <Object?>[1.0],
            },
          ),
        ]) {
          testWidgets(name, (tester) async {
            final chart = acquireChart(config(dataset));
            expect(chart.chartArea, isNull);
          });
        }
      });
    });

    testWidgets('getLabelAndValue gives a String label', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'labels': <Object?>[
            <Object?>['line 1', 'line 2'],
            5.0,
            0.0,
            'd',
            undefined,
          ],
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[1.0, 2.0, 3.0, 4.0, 5.0, 6.0],
            },
          ],
        },
      });
      final controller = chart.getDatasetMeta(0).controller!;
      expect(
        [
          for (var i = 0; i < 6; i++)
            controller.getLabelAndValue(i.toDouble()).label,
        ],
        ['line 1,line 2', '5', '0', 'd', 'undefined', 'undefined'],
      );
    });
  });
}
