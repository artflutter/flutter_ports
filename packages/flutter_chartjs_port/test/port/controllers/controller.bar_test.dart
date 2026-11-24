// Original code, not ported from Chart.js: bar controller reference tests.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/light_theme.dart';
import '../scales/scale_chart_harness.dart';
import '../scales/scale_time_harness.dart';
import 'controller_bar_reference.dart';
import 'controller_chart_harness.dart';

// The port-only reference tests of lib/src/controllers/controller.bar.dart
// (Chart.js ADR 0030). The spec port is test/specs/controller.bar_test.dart.
//
// The reference group compares real bar charts with the charts of
// tool/reference/controller_bar_reference.mjs: a build of the pinned
// Chart.js in Node.js v24.22.1 on arm64 (Chart.js ADR 0146), with a mock
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
      for (final element in chart.getDatasetMeta(i).data)
        _edges(element as ElementPropertyRead),
    ],
];

/// `[enableBorderRadius, borderSkipped, Number(inflateAmount)]` of [bar].
List<Object?> _edges(ElementPropertyRead bar) => [
  bar['enableBorderRadius'],
  bar['borderSkipped'],
  jsToNumber(bar['inflateAmount']),
];

/// The probe `stackKeys` of the generator: the keys of `_stacks` of each
/// parsed item of the dataset 0 (`p._stacks || {}`).
Object? _stackKeys(Chart chart) => [
  for (final item in chart.getDatasetMeta(0).parsed)
    switch (stacksOf(item)) {
      final Object stacks
          when stacks is Map<String, Object?> || stacks is JsObjectFace =>
        jsObjectKeys(stacks),
      _ => const <String>[],
    },
];

/// `chart.data.datasets.length`.
int _datasetCount(Chart chart) =>
    (jsGet(chart.data, 'datasets')! as List<Object?>).length;

/// The config of a bar chart with the labels a, b, c and one dataset with
/// [data] and the keys of [extra] (`one` of the generator).
ChartConfigurationScope _one(
  AnyObject extra, [
  List<Object?> data = const [10.0, 5.0, -3.0],
]) => ChartConfigurationScope()
  ..type = 'bar'
  ..data = (ChartDataScope()
    ..labels = <Object?>['a', 'b', 'c']
    ..datasets = <Object?>[
      scopeFromMap(
        BarControllerDatasetOptionsScope()..data = <Object?>[...data],
        extra,
      ),
    ]);

/// `x`, `y`, `base`, `width` and `height` of each bar of the dataset 0.
List<Object?> _bars(Chart chart) => [
  for (final element in chart.getDatasetMeta(0).data)
    [
      for (final key in const ['x', 'y', 'base', 'width', 'height'])
        (element as ElementPropertyRead)[key],
    ],
];

/// Expects the bars of the chart of [config] to equal the bars of the chart
/// of [same] (a relation of two charts of the port).
void _expectSameBars(
  ChartConfigurationScope config,
  ChartConfigurationScope same,
) {
  final bars = _bars(acquireChartRoot(config));
  expect(bars, referenceMatcher(_bars(acquireChartRoot(same))));
}

/// The cases that the port does not run: a text `barThickness` stops a
/// debug build (row adapt-bar-thickness-class), a parsing key that is not a
/// string stops a debug build or takes the default key (row
/// adapt-parsing-keys), and a data item of `parsing: false` that is not a
/// ParsedItem stops a debug build (row adapt-parsed-data-items).
const Map<String, String> _skips = {
  "parsed: barThickness '20'": 'diverges: adapt-bar-thickness-class',
  'parsed: xAxisKey null': 'diverges: adapt-parsing-keys',
  'parsed: xAxisKey 5': 'diverges: adapt-parsing-keys',
  'parsed: a bad yAxisKey on a category index axis':
      'diverges: adapt-parsing-keys',
  'parsed: stacked List items with parsing false':
      'diverges: adapt-parsed-data-items',
  'parsed: stacked numbers with parsing false':
      'diverges: adapt-parsed-data-items',
};

/// Audit only the deliberately coercible input slot of the current case.
void _coercionInput(String name, Set<Object> values) {
  final savedAudit = foreignAudit;
  foreignAudit = (owner, key, raw) {
    if (owner == 'BarControllerDatasetOptionsScope' && key == name) {
      expect(values, contains(raw));
    } else {
      savedAudit?.call(owner, key, raw);
    }
  };
  addTearDown(() => foreignAudit = savedAudit);
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
    skips: _skips,
  );

  group('theming.md §8 test 3: the light preset', () {
    testControllerChartCases(
      controllerBarReference,
      extras: _extras,
      theme: compileLightTheme(),
      now: controllerBarReferenceNow,
      skips: _skips,
    );

    testWidgets('the light preset leaves no stale scale key', (tester) async {
      final snapshot = jsonDecode(
        File('test/port/theme/light_snapshot.json').readAsStringSync(),
      ) as Map<String, Object?>;
      expectNoStaleScaleKeys(
        acquireReferenceChart(
          controllerBarReference.first.config,
          const AcquireOptions(),
          theme: compileLightTheme(),
        ),
        snapshot,
      );
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
        _coercionInput('inflateAmount', {'2', true, 'abc'});
        List<Object?> calls(Object? inflateAmount) => [
          for (final call in drawCalls(
            acquireChartRoot(
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
      _coercionInput('base', {true});
      _expectSameBars(
        _one(<String, Object?>{'base': true}),
        _one(<String, Object?>{'base': 1.0}),
      );
    });

    testWidgets("minBarLength '20' gives the bars of 20", (tester) async {
      _coercionInput('minBarLength', {'20'});
      const data = <Object?>[0.01, 0.0, -0.01];
      _expectSameBars(
        _one(<String, Object?>{'minBarLength': '20'}, data),
        _one(<String, Object?>{'minBarLength': 20.0}, data),
      );
    });

    testWidgets('barThickness 20 gives the bars of 20', (tester) async {
      // A text stops a debug build (row adapt-bar-thickness-class).
      _expectSameBars(
        _one(<String, Object?>{'barThickness': const BarThickness.pixels(20)}),
        _one(<String, Object?>{'barThickness': const BarThickness.pixels(20)}),
      );
    });

    // A parsing key that is not a string stops a debug build when the
    // controller reads the option, before any parse (row adapt-parsing-keys).
    // Upstream throws at the `resolveObjectKey` read of the bad key.
    for (final (name, indexAxis, axisClass, parsing) in [
      ('an xAxisKey 5 with indexAxis y', 'y', const YAxis(), {'xAxisKey': 5.0}),
      ('a yAxisKey 5 with indexAxis y', 'y', const YAxis(), {'yAxisKey': 5.0}),
      ('a yAxisKey 5 with indexAxis x', 'x', const XAxis(), {'yAxisKey': 5.0}),
    ]) {
      testWidgets('$name stops a debug build', (tester) async {
        final valueAxis = indexAxis == 'x' ? 'y' : 'x';
        expect(
          () => acquireChartRoot(<String, Object?>{
            'type': 'bar',
            'data': <String, Object?>{
              'labels': <Object?>['b'],
              'datasets': <Object?>[
                <String, Object?>{
                  'data': <Object?>[
                    <String, Object?>{indexAxis: 'a', valueAxis: 1.0},
                  ],
                },
              ],
            },
            'options': <String, Object?>{
              'indexAxis': axisClass,
              'parsing': <String, Object?>{...parsing},
              'scales': <String, Object?>{
                indexAxis: <String, Object?>{'type': 'category'},
                valueAxis: <String, Object?>{'type': 'linear'},
              },
            },
          }),
          throwsA(isA<AssertionError>()),
        );
      });
    }
  });

  // The pin tests of the interfaces spec, section 7.3, that need no
  // generated value: the label of the bar is a String.
  group('interfaces', () {
    testWidgets('getLabelAndValue gives the String label as one line', (
      tester,
    ) async {
      final chart = acquireChartRoot(<String, Object?>{
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
        [for (var i = 0; i < 6; i++) controller.getLabelAndValue(i).label],
        [
          ['line 1,line 2'],
          ['5'],
          ['0'],
          ['d'],
          ['undefined'],
          ['undefined'],
        ],
      );
    });
  });
}
