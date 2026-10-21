// Original code, not ported from Chart.js: bar controller reference tests.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs/src/core/core.config.dart' show themeConfigKey;
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/core/core.datasetController.dart'
    show stacksOf;
import 'package:flutter_chartjs/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/theme/compile.dart';
import 'package:flutter_chartjs/src/theme/presets.dart';
import 'package:flutter_chartjs/src/types/basic.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import '../scales/scale_chart_harness.dart';
import '../scales/scale_time_harness.dart';
import 'controller_bar_reference.dart';
import 'controller_chart_harness.dart';

// The port-only reference tests of lib/src/controllers/controller.bar.dart
// (Chart.js ADR 0030). The spec port is test/specs/controller.bar_test.dart.
//
// The reference group compares real bar charts with the charts of
// tool/reference/controller_bar_reference.mjs: a build of the pinned
// Chart.js in Node.js v24.12.0 on x64 (Chart.js ADR 0032), with a mock
// context that measures text in Liberation Sans 2.1.5. Each chart comes from
// acquireChart in a testWidgets case (Chart.js ADR 0022). The case runs its
// steps and compares the observations, the hit queries and the draw calls
// with the element draws (controller_chart_harness.dart). The generator
// loads the date adapter of the specs for the timeseries case and fixes
// `Date.now()`. Thus each case runs at that time (`now`).
//
// The 23 cases of Chart.js ADR 0030, section 7 run two times: unthemed, and
// with the light preset (theming.md section 8 test 3). The cases whose names
// start with `parsed:` (Chart.js ADR 0036, section 9) or `interfaces:`
// (Chart.js ADR 0028, section 8) run unthemed only. The groups `parsed
// data` and `interfaces` hold the pin tests that need no generated value:
// relations between two charts of the port.
//
// flutter_test_config.dart registers the bar controller with the built-in
// components before main() (Chart.js ADR 0030, section 3 item 4).

/// The probes of the key `extra` of the generator, with the same bodies.
final Map<String, Object? Function(Chart chart)> _extras = {
  'barEdges': _barEdges,
  'stackKeys': _stackKeys,
};

/// The probe `barEdges` of the generator: for each dataset,
/// `[enableBorderRadius, borderSkipped, Number(inflateAmount)]` of each bar.
Object? _barEdges(Chart chart) => [
  for (var i = 0; i < _datasetCount(chart); i++)
    [
      for (final element in chart.getDatasetMeta(i.toDouble()).data)
        _edges(element as types.ElementPropertyRead),
    ],
];

/// `[enableBorderRadius, borderSkipped, Number(inflateAmount)]` of [bar].
List<Object?> _edges(types.ElementPropertyRead bar) => [
  bar['enableBorderRadius'],
  bar['borderSkipped'],
  jsToNumber(bar['inflateAmount']),
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

/// `chart.data.datasets.length`.
int _datasetCount(Chart chart) =>
    (jsGet(chart.data, 'datasets')! as List<Object?>).length;

/// The config of a bar chart with the labels a, b, c and one dataset with
/// [data] and the keys of [extra] (`one` of the generator).
AnyObject _one(
  AnyObject extra, [
  List<Object?> data = const [10.0, 5.0, -3.0],
]) => <String, Object?>{
  'type': 'bar',
  'data': <String, Object?>{
    'labels': <Object?>['a', 'b', 'c'],
    'datasets': <Object?>[
      <String, Object?>{
        'data': <Object?>[...data],
        ...extra,
      },
    ],
  },
};

/// `x`, `y`, `base`, `width` and `height` of each bar of the dataset 0.
List<Object?> _bars(Chart chart) => [
  for (final element in chart.getDatasetMeta(0).data)
    [
      for (final key in const ['x', 'y', 'base', 'width', 'height'])
        (element as types.ElementPropertyRead)[key],
    ],
];

/// Expects the bars of the chart of [config] to equal the bars of the chart
/// of [same] (a relation of two charts of the port).
void _expectSameBars(AnyObject config, AnyObject same) {
  final bars = _bars(acquireChart(config));
  expect(bars, referenceMatcher(_bars(acquireChart(same))));
}

void main() {
  testReferenceOrigin(
    node: controllerBarReferenceNode,
    arch: controllerBarReferenceArch,
    dist: controllerBarReferenceDist,
    commit: controllerBarReferenceCommit,
  );
  testAdapterOrigin(controllerBarReferenceAdapter);
  testReferenceWidths(controllerBarReferenceWidths);

  test('the reference has the 23 cases of Chart.js ADR 0030 first', () {
    final names = [for (final c in controllerBarReference) c.name];
    bool prefixed(String n) =>
        n.startsWith('parsed:') || n.startsWith('interfaces:');
    expect(names.first, 'default');
    expect(names.length, greaterThanOrEqualTo(23));
    expect(names.take(23).where(prefixed), isEmpty);
    expect(names.skip(23).where((n) => !prefixed(n)), isEmpty);
  });

  testControllerChartCases(
    controllerBarReference,
    extras: _extras,
    now: controllerBarReferenceNow,
  );

  group('theming.md §8 test 3: the light preset', () {
    testControllerChartCases(
      controllerBarReference,
      extras: _extras,
      theme: compileChartTheme(ChartThemes.light),
      now: controllerBarReferenceNow,
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
          copyReference(controllerBarReference.first.config)! as AnyObject;
      config[themeConfigKey] = compileChartTheme(ChartThemes.light);
      expectNoStaleScaleKeys(acquireChart(config), snapshot);
    });
  });

  // The pin tests of the parsed-data spec, section 7.3, that need no
  // generated value. The generated cases `parsed: ...` give the upstream
  // values of the same configs.
  group('parsed data', () {
    testWidgets(
      "inflateAmount '2', null, true and 'abc' give the rect and clip calls "
      'of 2, 0, 1 and NaN',
      (tester) async {
        List<Object?> calls(Object? inflateAmount) => [
          for (final call in drawCalls(
            acquireChart(
              _one(<String, Object?>{
                'inflateAmount': inflateAmount,
                'borderWidth': 1.0,
              }),
            ),
          ).cast<Map<String, Object?>>())
            if (call['name'] == 'rect' || call['name'] == 'clip') call,
        ];
        for (final (raw, number) in <(Object?, double)>[
          ('2', 2),
          (null, 0),
          (true, 1),
          ('abc', double.nan),
        ]) {
          final rawCalls = calls(raw);
          expect(rawCalls, isNotEmpty, reason: '$raw');
          expect(rawCalls, referenceMatcher(calls(number)), reason: '$raw');
        }
      },
    );

    testWidgets('base true gives the bars of base 1', (tester) async {
      _expectSameBars(
        _one(<String, Object?>{'base': true}),
        _one(<String, Object?>{'base': 1.0}),
      );
    });

    testWidgets("minBarLength '20' gives the bars of 20", (tester) async {
      const data = <Object?>[0.01, 0.0, -0.01];
      _expectSameBars(
        _one(<String, Object?>{'minBarLength': '20'}, data),
        _one(<String, Object?>{'minBarLength': 20.0}, data),
      );
    });

    testWidgets("barThickness '20' gives the bars of 20", (tester) async {
      _expectSameBars(
        _one(<String, Object?>{'barThickness': '20'}),
        _one(<String, Object?>{'barThickness': 20.0}),
      );
    });

    testWidgets('a bad yAxisKey on a category index axis throws after the '
        'first label parse', (tester) async {
      final data = <String, Object?>{
        'datasets': <Object?>[
          <String, Object?>{
            'data': <Object?>[
              <String, Object?>{'x': 'q', 'y': 1.0},
              <String, Object?>{'x': 'r', 'y': 2.0},
            ],
            'parsing': <String, Object?>{'yAxisKey': 5.0},
          },
        ],
      };
      expect(
        () => acquireChart(<String, Object?>{'type': 'bar', 'data': data}),
        throwsA(isA<TypeError>()),
      );
      // The category scale parsed the label of the first item before the
      // throw (category.js addIfString): the labels hold it.
      expect(data['labels'], ['q']);
    });

    // controller.bar.js:334-335: the index key and then the value key throw
    // at their `resolveObjectKey` reads (helpers.core.ts:379), so a bad value
    // key throws after the category index scale added the label of item 0,
    // and a bad index key throws before it. The pinned build in x64 Node.js
    // v24.12.0 gives the labels ['b', 'a'], ['b', 'a'] and ['b'] (a probe
    // of these three configs on the pinned build). A parse of no item reads
    // no key and does not throw.
    for (final (name, indexAxis, parsing, labels) in [
      ('a yAxisKey null', 'x', {'yAxisKey': null}, ['b', 'a']),
      ('an xAxisKey 5 with indexAxis y', 'y', {'xAxisKey': 5.0}, ['b', 'a']),
      ('a yAxisKey 5 with indexAxis y', 'y', {'yAxisKey': 5.0}, ['b']),
    ]) {
      testWidgets('$name throws in the order of the key reads', (
        tester,
      ) async {
        final valueAxis = indexAxis == 'x' ? 'y' : 'x';
        final chartLabels = <Object?>['b'];
        expect(
          () => acquireChart(<String, Object?>{
            'type': 'bar',
            'data': <String, Object?>{
              'labels': chartLabels,
              'datasets': <Object?>[
                <String, Object?>{
                  'data': <Object?>[
                    <String, Object?>{indexAxis: 'a', valueAxis: 1.0},
                  ],
                },
              ],
            },
            'options': <String, Object?>{
              'indexAxis': indexAxis,
              'parsing': <String, Object?>{...parsing},
              'scales': <String, Object?>{
                indexAxis: <String, Object?>{'type': 'category'},
                valueAxis: <String, Object?>{'type': 'linear'},
              },
            },
          }),
          throwsA(isA<TypeError>()),
        );
        expect(chartLabels, labels);
      });
    }

    testWidgets('stacked List items with parsing false take a stack object '
        'with the key of the value axis', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'bar',
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
            'x': <String, Object?>{'stacked': true},
            'y': <String, Object?>{'stacked': true},
          },
        },
      });
      final meta = chart.getDatasetMeta(0);
      for (final item in meta.parsed) {
        expect(item, isA<List<Object?>>());
        expect(jsObjectKeys(stacksOf(item)! as AnyObject), ['y']);
      }
      for (final bar in meta.data) {
        final edges = _edges(bar as types.ElementPropertyRead);
        expect(edges[0], isFalse);
        expect(plainValue(edges[1]), {'bottom': true});
        expect((bar as types.ElementPropertyRead)['x'], isNaN);
      }
    });
  });

  // The pin tests of the interfaces spec, section 7.3, that need no
  // generated value: the label of the bar is a String.
  group('interfaces', () {
    testWidgets('getLabelAndValue gives a String label', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'bar',
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
