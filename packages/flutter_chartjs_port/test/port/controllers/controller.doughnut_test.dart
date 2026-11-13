// Original code, not ported from Chart.js: doughnut controller reference tests.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/controllers/controller.doughnut.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart'
    show overrides;
import 'package:flutter_chartjs_port/src/elements/element.arc.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.collection.dart'
    show notifyArrayListeners;
import 'package:flutter_chartjs_port/src/js/js_function.dart' show jsCall;
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.legend.dart'
    show Legend;
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_chartjs_port/src/types/legend_item.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/light_theme.dart';
import '../scales/scale_chart_harness.dart';
import 'controller_chart_harness.dart';
import 'controller_doughnut_reference.dart';

// The port-only reference tests of
// lib/src/controllers/controller.doughnut.dart (Chart.js ADR 0030). The spec
// port is test/specs/controller.doughnut_test.dart.
//
// The reference group compares real doughnut charts with the charts of
// tool/reference/controller_doughnut_reference.mjs: a build of the pinned
// Chart.js in Node.js v24.22.1 on arm64 (Chart.js ADR 0045), with a mock
// context that measures text in Liberation Sans 2.1.5. Each chart comes from
// acquireChart in a testWidgets case (Chart.js ADR 0022). The case runs its
// steps and compares the observations, the hit queries and the draw calls
// with the element draws (controller_chart_harness.dart).
//
// The 15 cases of Chart.js ADR 0030, section 7 run two times: unthemed, and
// with the light preset (theming.md section 8 test 3). A doughnut chart has no
// scale. Thus the themed group has no check of the stale scale keys. The cases
// whose names start with `parsed:` (Chart.js ADR 0036, section 9) or
// `interfaces:` (Chart.js ADR 0028, section 8) run unthemed only. The cases
// whose names start with `legend:` (Chart.js ADR 0041, section 5) run the real
// legend with the legend functions of the overrides: the items, the hit boxes
// and a click on the item 1. They also run unthemed only. The groups `parsed
// data` and `interfaces` hold the pin tests that need no generated value:
// relations between two charts of the port, and the identity of values.
//
// flutter_test_config.dart registers the doughnut controller with the built-in
// components before main() (Chart.js ADR 0030, section 3 item 4), and the seven
// plugins with `defaults.plugins.colors.enabled = false` (Chart.js ADR 0041,
// section 1). The generator registers the same components (registerBuiltins).

/// The probes of the key `extra` of the generator, with the same bodies.
final Map<String, Object? Function(Chart chart)> _extras = {
  'parsedIsData': _parsedIsData,
  'ringGeometry': _ringGeometry,
  'realLegend': _realLegend,
};

/// `chart.data.datasets`.
List<Object?> _datasets(Chart chart) =>
    jsGet(chart.data, 'datasets')! as List<Object?>;

/// `chart.data.datasets[index]`.
AnyObject _dataset(Chart chart, int index) =>
    _datasets(chart)[index]! as AnyObject;

/// The probe `parsedIsData` of the generator: `meta._parsed ===
/// dataset.data` of the dataset 0.
Object? _parsedIsData(Chart chart) =>
    identical(chart.getDatasetMeta(0).parsed, _dataset(chart, 0)['data']);

/// The probe `ringGeometry` of the generator: `[offsetX, offsetY,
/// outerRadius, innerRadius]` of the controller of each dataset. Dart
/// `null` is the JS `undefined` of the constructor.
Object? _ringGeometry(Chart chart) => [
  for (var i = 0; i < _datasets(chart).length; i++)
    switch (chart.getDatasetMeta(i).controller! as DoughnutController) {
      final c => [
        c.offsetX ?? undefined,
        c.offsetY ?? undefined,
        c.outerRadius ?? undefined,
        c.innerRadius ?? undefined,
      ],
    },
];

/// `overrides.doughnut.plugins.legend`.
Object? _legendOverrides() =>
    jsGet(jsGet(overrides['doughnut'], 'plugins'), 'legend');

/// `generateLabels(chart)` of `overrides.doughnut.plugins.legend.labels`.
List<Object?> _generateLabels(Chart chart) =>
    jsCall(jsGet(jsGet(_legendOverrides(), 'labels'), 'generateLabels'), [
          chart,
        ])!
        as List<Object?>;

/// The probe `realLegend` of the generator: the items and the hit boxes of
/// the real legend. It reads `legendItems` through `types.LegendElement`
/// (Chart.js ADR 0028 Open 2), and `legendHitBoxes` through a cast to
/// [Legend]: the member is not in index.d.ts (Chart.js ADR 0038, section 6;
/// Chart.js ADR 0041, section 5). Items remain native for field comparisons;
/// upstream own-key enumeration is outside the native item contract.
Object? _realLegend(Chart chart) {
  final legend = chart.legend!;
  return <String, Object?>{
    'items': legend.legendItems,
    'hitBoxes': (legend as Legend).legendHitBoxes,
  };
}

/// [cases] with `undefined` for each expected `xAxisID` and `yAxisID` of
/// JS `null`.
///
/// The Dart field `ChartMeta.xAxisID` is an `Object?`: Dart `null` stands for
/// the JS `null` of the start value (core.controller.js:841-842) and for the
/// JS `undefined` that `linkScales` of the dataset controller writes for an
/// absent scale (core.datasetController.js:306-307). The harness reads
/// Dart `null` as `undefined` (`_observeDataset` of
/// controller_chart_harness.dart). The empty `linkScales` of the doughnut
/// (controller.doughnut.js:143) keeps the JS `null`. Thus the expected
/// `null` becomes `undefined` here. No other key changes. No reader of the
/// port sees the difference: the doughnut reads no axis id.
List<ScaleChartCase> _undefinedAxisIds(List<ScaleChartCase> cases) => [
  for (final c in cases)
    (
      name: c.name,
      config: c.config,
      options: c.options,
      expected: <String, Object?>{
        for (final MapEntry(:key, :value) in c.expected.entries)
          key: switch (key) {
            'initial' => _observationAxisIds(value),
            'steps' => [
              for (final step in (value! as List<Object?>).cast<AnyObject>())
                <String, Object?>{
                  for (final MapEntry(:key, :value) in step.entries)
                    key: key == 'observations'
                        ? _observationAxisIds(value)
                        : value,
                },
            ],
            _ => value,
          },
      },
    ),
];

/// The observation [observation] with `undefined` for each `xAxisID` and
/// `yAxisID` of JS `null` in `datasets` ([_undefinedAxisIds]).
Object? _observationAxisIds(Object? observation) {
  final map = observation! as AnyObject;
  return <String, Object?>{
    ...map,
    'datasets': [
      for (final dataset
          in (map['datasets']! as List<Object?>).cast<AnyObject>())
        <String, Object?>{
          for (final MapEntry(:key, :value) in dataset.entries)
            key: (key == 'xAxisID' || key == 'yAxisID') && value == null
                ? undefined
                : value,
        },
    ],
  };
}

/// The reference cases with the axis ids of [_undefinedAxisIds].
final List<ScaleChartCase> _reference = _undefinedAxisIds(
  controllerDoughnutReference,
);

/// The config of a doughnut chart with the labels a, b, c and one dataset
/// with [data] and the keys of [extra].
AnyObject _one(AnyObject extra, List<Object?> data) => <String, Object?>{
  'type': 'doughnut',
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

/// The arc properties of each arc of the dataset 0.
List<Object?> _arcs(Chart chart) => [
  for (final element in chart.getDatasetMeta(0).data)
    [
      for (final key in const [
        'x',
        'y',
        'startAngle',
        'endAngle',
        'circumference',
        'innerRadius',
        'outerRadius',
      ])
        (element as types.ElementPropertyRead)[key],
    ],
];

void main() {
  group('hit probes stay off platform-sensitive ties', () {
    // Windows shard 1 of CI run 43391456447 selected different arcs at these
    // exact ties. Tiny center perturbations reproduce the ambiguity locally.
    for (final (name, stepIndex, pointIndex) in [
      ('parsed: object items with the default key', -1, 2),
      ('legend: click', 0, 1),
      ('legend: click twice', 0, 1),
    ]) {
      testWidgets(name, (tester) async {
        final c = _reference.firstWhere((c) => c.name == name);
        final config = copyReference(c.config)! as AnyObject;
        nativeFixtureColors(config);
        final chart = acquireChart(
          config,
          copyReference(c.options)! as AnyObject,
        );
        var observation = c.expected['initial']! as AnyObject;
        if (stepIndex >= 0) {
          final step =
              (c.expected['steps']! as List<Object?>)[stepIndex]! as AnyObject;
          await runStep(tester, chart, step['do']! as List<Object?>);
          observation = step['observations']! as AnyObject;
        }
        final hits = observation['hits']! as AnyObject;
        final expected = hitItems(hits['items'])[pointIndex];
        final arcs = chart.getDatasetMeta(0).data.cast<ArcElement>();
        final centers = [for (final arc in arcs) (x: arc.x, y: arc.y)];
        for (final dx in [-1e-10, 0.0, 1e-10]) {
          for (final dy in [-1e-10, 0.0, 1e-10]) {
            for (var i = 0; i < arcs.length; i++) {
              arcs[i]
                ..x = centers[i].x + dx
                ..y = centers[i].y + dy;
            }
            final actual = observeHits(chart, hits)['items']! as List<Object?>;
            expect(
              actual[pointIndex],
              expected,
              reason: 'point $pointIndex; center shift ($dx, $dy)',
            );
          }
        }
      });
    }
  });

  testReferenceOrigin(
    node: controllerDoughnutReferenceNode,
    arch: controllerDoughnutReferenceArch,
    dist: controllerDoughnutReferenceDist,
    commit: controllerDoughnutReferenceCommit,
  );
  testReferenceWidths(controllerDoughnutReferenceWidths);

  test('the reference has the 15 cases of Chart.js ADR 0030 first', () {
    final names = [for (final c in controllerDoughnutReference) c.name];
    bool prefixed(String n) =>
        n.startsWith('parsed:') ||
        n.startsWith('interfaces:') ||
        n.startsWith('legend:');
    expect(names.first, 'default');
    expect(names.length, greaterThanOrEqualTo(15));
    expect(names.take(15).where(prefixed), isEmpty);
    expect(names.skip(15).where((n) => !prefixed(n)), isEmpty);
  });

  testControllerChartCases(_reference, extras: _extras);

  group('theming.md §8 test 3: the light preset', () {
    // The `legend:` cases run unthemed only, as the `interfaces:` cases:
    // their probe compares the item colors as strings, and
    // test/port/plugins/plugin.legend_test.dart runs the legend with the
    // light preset.
    testControllerChartCases(
      [
        for (final c in _reference)
          if (!c.name.startsWith('legend:')) c,
      ],
      extras: _extras,
      theme: compileLightTheme(),
    );
  });

  // The pin tests of the parsed-data spec, section 7.3, that need no
  // generated value. The generated cases `parsed: ...` give the upstream
  // values.
  group('parsed data', () {
    // A string `data` (Chart.js ADR 0036 §5 item 4). `_dataCheck` keeps the
    // string (core.datasetController.js:386), and `parse` reads its
    // characters. The values come from a probe of the build at the pin in
    // x64 Node.js v24.12.0.
    AnyObject stringData(AnyObject extra, String data) {
      final config = _one(extra, const []);
      final datasets = jsGet(config['data'], 'datasets')! as List<Object?>;
      (datasets[0]! as AnyObject)['data'] = data;
      return config;
    }

    testWidgets("the string data 'abc' gives 3 arcs with the parsed values "
        'NaN', (tester) async {
      final chart = acquireChart(stringData(const {}, 'abc'));
      final meta = chart.getDatasetMeta(0);
      expect(_dataset(chart, 0)['data'], 'abc');
      expect(meta.data, hasLength(3));
      expect(meta.parsed, [isNaN, isNaN, isNaN]);
      expect(meta.total, 0);
      expect(
        [
          for (final arc in meta.data)
            (arc as types.ElementPropertyRead)['circumference'],
        ],
        [0, 0, 0],
      );
    });

    testWidgets("the string data '123' with parsing false gives the arcs of "
        '[1, 2, 3]', (tester) async {
      final chart = acquireChart(
        stringData(<String, Object?>{'parsing': false}, '123'),
      );
      final meta = chart.getDatasetMeta(0);
      expect(meta.data, hasLength(3));
      expect(meta.parsed, ['1', '2', '3']);
      expect(meta.total, 6);
      expect(
        [
          for (final arc in meta.data)
            (arc as types.ElementPropertyRead)['circumference'],
        ],
        [1.0471975511965976, 2.0943951023931953, 3.141592653589793],
      );
      expect(meta.controller!.getContext(1)['raw'], '2');
      expect(
        _arcs(chart),
        referenceMatcher(
          _arcs(
            acquireChart(
              _one(
                <String, Object?>{'parsing': false},
                <Object?>[1.0, 2.0, 3.0],
              ),
            ),
          ),
        ),
      );
    });

    testWidgets("parsing false with [1, '2', null] gives the arcs of "
        '[1, 2, null] and keeps the data List', (tester) async {
      final chart = acquireChart(
        _one(<String, Object?>{'parsing': false}, <Object?>[1.0, '2', null]),
      );
      expect(
        identical(chart.getDatasetMeta(0).parsed, _dataset(chart, 0)['data']),
        isTrue,
      );
      expect(
        _arcs(chart),
        referenceMatcher(
          _arcs(acquireChart(_one(const {}, <Object?>[1.0, 2.0, null]))),
        ),
      );
    });

    testWidgets('object items with a parsing key give the arcs of the '
        'numbers', (tester) async {
      final chart = acquireChart(
        _one(
          <String, Object?>{
            'parsing': <String, Object?>{'key': 'v'},
          },
          <Object?>[
            <String, Object?>{'v': 1.0},
            <String, Object?>{'v': '2'},
            <String, Object?>{'v': 3.0},
          ],
        ),
      );
      expect(chart.getDatasetMeta(0).parsed, [1.0, 2.0, 3.0]);
      expect(
        _arcs(chart),
        referenceMatcher(
          _arcs(acquireChart(_one(const {}, <Object?>[1.0, 2.0, 3.0]))),
        ),
      );
    });
  });

  // The pin tests of the interfaces spec, section 7.3, that need no
  // generated value.
  group('interfaces', () {
    testWidgets('meta.total after an update is calculateTotal(), and the '
        'read by name gives it', (tester) async {
      final chart = acquireChart(
        _one(const {}, <Object?>[10.0, -5.0, null, 20.0]),
      );
      final meta = chart.getDatasetMeta(0);
      final controller = meta.controller! as DoughnutController;
      expect(meta.total, 35);
      expect(meta.total, controller.calculateTotal());
      expect(meta['total'], 35);

      chart
        ..toggleDataVisibility(3)
        ..update();
      expect(meta.total, 15);
      expect(meta['total'], 15);
    });

    testWidgets('getLabelAndValue gives the label of chart.data.labels as it '
        'is', (tester) async {
      final label0 = <Object?>['line 1', 'line 2'];
      final chart = acquireChart(<String, Object?>{
        'type': 'doughnut',
        'data': <String, Object?>{
          'labels': <Object?>[label0, 5.0, 0.0, 'd', undefined],
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[1.0, 2.0, 3.0, 4.0, 5.0, 6.0],
            },
          ],
        },
      });
      final controller = chart.getDatasetMeta(0).controller!;
      final labels = [
        for (var i = 0; i < 6; i++)
          controller.getLabelAndValue(i.toDouble()).label,
      ];
      expect(identical(labels[0], label0), isTrue);
      expect(labels.sublist(1), [5.0, '', 'd', '', '']);
      expect(controller.getLabelAndValue(0).value, '1');
    });

    testWidgets('generateLabels throws a TypeError without a legend', (
      tester,
    ) async {
      // The legend plugin is off, so it writes no `chart.legend`.
      final chart = acquireChart(
        _one(const {}, <Object?>[1.0, 2.0, 3.0])
          ..['options'] = <String, Object?>{
            'plugins': <String, Object?>{'legend': false},
          },
      );
      expect(chart.legend, isNull);
      expect(() => _generateLabels(chart), throwsA(isA<TypeError>()));
    });

    testWidgets('onClick toggles the index of the item and updates the chart '
        'once', (tester) async {
      var updates = 0;
      final config = _one(const {}, <Object?>[1.0, 2.0, 3.0])
        ..['plugins'] = <Object?>[
          <String, Object?>{
            'id': 'countUpdates',
            'afterUpdate': (Object? chart, Object? args, Object? options) {
              updates++;
            },
          },
        ];
      final chart = acquireChart(config);
      final legend = chart.legend!;
      final before = updates;

      jsCall(jsGet(_legendOverrides(), 'onClick'), [
        <String, Object?>{},
        LegendItem(text: ['item'], index: 1),
        legend,
      ]);

      expect(updates, before + 1);
      expect(chart.getDataVisibility(1), isFalse);
      expect(
        [
          for (final item in _generateLabels(chart))
            (item! as LegendItem).hidden,
        ],
        [false, true, false],
      );
    });

    // Native items expose integer indexes; a missing index is descriptive.
    for (final (name, index, visible) in <(String, int?, String)>[
      ('null', null, '111'),
      ('0', 0, '011'),
      ('1', 1, '101'),
      ('2', 2, '110'),
    ]) {
      testWidgets('onClick with the index $name uses the native index', (
        tester,
      ) async {
        final chart = acquireChart(_one(const {}, <Object?>[1.0, 2.0, 3.0]));
        final legend = chart.legend!;
        jsCall(jsGet(_legendOverrides(), 'onClick'), [
          <String, Object?>{},
          LegendItem(text: ['item'], index: index),
          legend,
        ]);
        expect(
          [
            for (var i = 0; i < 3; i++)
              if (chart.getDataVisibility(i)) '1' else '0',
          ].join(),
          visible,
        );
      });
    }

    // A data insertion or removal moves integer visibility indexes.
    for (final (name, index, unshift, shift, push)
        in <(String, int?, String, String, String)>[
          ('null', null, '11111', '111', '11111'),
          ('1', 1, '11011', '011', '10111'),
        ]) {
      for (final (change, visible) in [
        ('unshift', unshift),
        ('shift', shift),
        ('push', push),
      ]) {
        testWidgets('onClick with the index $name, then $change, moves the '
            'visibility index', (tester) async {
          final chart = acquireChart(
            _one(const {}, <Object?>[1.0, 2.0, 3.0, 4.0]),
          );
          final legend = chart.legend!;
          jsCall(jsGet(_legendOverrides(), 'onClick'), [
            <String, Object?>{},
            LegendItem(text: ['item'], index: index),
            legend,
          ]);
          final data = _dataset(chart, 0)['data']! as List<Object?>;
          switch (change) {
            case 'unshift':
              data.insert(0, 9.0);
              notifyArrayListeners(data, 'unshift', const [9.0]);
            case 'shift':
              data.removeAt(0);
              notifyArrayListeners(data, 'shift', const <Object?>[]);
            case 'push':
              data.add(9.0);
              notifyArrayListeners(data, 'push', const [9.0]);
          }
          chart.update();
          expect(
            [
              for (var i = 0; i < data.length; i++)
                if (chart.getDataVisibility(i)) '1' else '0',
            ].join(),
            visible,
          );
        });
      }
    }

    test('the legend functions are the same function in each read', () {
      final legend = _legendOverrides();
      final generateLabels = jsGet(jsGet(legend, 'labels'), 'generateLabels');
      final onClick = jsGet(legend, 'onClick');
      expect(generateLabels, isA<Function>());
      expect(onClick, isA<Function>());
      expect(
        identical(
          jsGet(jsGet(_legendOverrides(), 'labels'), 'generateLabels'),
          generateLabels,
        ),
        isTrue,
      );
      expect(identical(jsGet(_legendOverrides(), 'onClick'), onClick), isTrue);
      final statics = jsGet(
        jsGet(DoughnutController.overrides, 'plugins'),
        'legend',
      );
      expect(
        identical(
          jsGet(jsGet(statics, 'labels'), 'generateLabels'),
          generateLabels,
        ),
        isTrue,
      );
      expect(identical(jsGet(statics, 'onClick'), onClick), isTrue);
    });
  });
}
