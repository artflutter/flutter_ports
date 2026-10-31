// Original code, not ported from Chart.js: pie controller reference tests.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/controllers/controller.doughnut.dart';
import 'package:flutter_chartjs_port/src/controllers/controller.pie.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart'
    show defaults, overrides;
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_function.dart' show jsCall;
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.legend.dart'
    show Legend;
import 'package:flutter_chartjs_port/src/theme/compile.dart';
import 'package:flutter_chartjs_port/src/theme/presets.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_test/flutter_test.dart';

import '../scales/scale_chart_harness.dart';
import 'controller_chart_harness.dart';
import 'controller_pie_reference.dart';

// The port-only reference tests of lib/src/controllers/controller.pie.dart
// (Chart.js ADR 0030). Pie has no upstream spec file.
//
// The reference group compares real pie charts with the charts of
// tool/reference/controller_pie_reference.mjs: a build of the pinned
// Chart.js in Node.js v24.22.1 on arm64 (Chart.js ADR 0045), with a mock
// context that measures text in Liberation Sans 2.1.5. Each chart comes from
// acquireChart in a testWidgets case (Chart.js ADR 0022). The case runs its
// steps and compares the observations, the hit queries and the draw calls
// with the element draws (controller_chart_harness.dart).
//
// The 4 cases of Chart.js ADR 0030, section 7 run two times: unthemed, and with
// the light preset (theming.md section 8 test 3). A pie chart has no scale.
// Thus the themed group has no check of the stale scale keys. The cases whose
// names start with `interfaces:` (Chart.js ADR 0028, section 8) run unthemed
// only. The cases whose names start with `legend:` (Chart.js ADR 0041, section
// 5) run the real legend with the legend functions of the overrides: the items,
// the hit boxes and a click on the item 1. They also run unthemed only. The
// group `interfaces` holds the pin tests that need no generated value: the
// statics that the pie class value gets from the doughnut class value, the
// registered defaults, and the legend functions.
//
// flutter_test_config.dart registers the pie controller and its parent class,
// the doughnut controller, with the built-in components before main() (Chart.js
// ADR 0030, section 3 item 4), and the seven plugins with
// `defaults.plugins.colors.enabled = false` (Chart.js ADR 0041, section 1). The
// generator registers the same components (registerBuiltins).

/// The probes of the key `extra` of the generator, with the same bodies.
final Map<String, Object? Function(Chart chart)> _extras = {
  'ringGeometry': _ringGeometry,
  'realLegend': _realLegend,
};

/// `chart.data.datasets`.
List<Object?> _datasets(Chart chart) =>
    jsGet(chart.data, 'datasets')! as List<Object?>;

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

/// `overrides[type].plugins.legend`.
Object? _legendOverrides([String type = 'pie']) =>
    jsGet(jsGet(overrides[type], 'plugins'), 'legend');

/// `generateLabels(chart)` of `overrides.pie.plugins.legend.labels`.
List<Object?> _generateLabels(Chart chart) =>
    jsCall(jsGet(jsGet(_legendOverrides(), 'labels'), 'generateLabels'), [
          chart,
        ])!
        as List<Object?>;

/// The probe `realLegend` of the generator: the items and the hit boxes of
/// the real legend. It reads `legendItems` through `types.LegendElement`
/// (Chart.js ADR 0028 Open 2), and `legendHitBoxes` through a cast to
/// [Legend]: the member is not in index.d.ts (Chart.js ADR 0038, section 6;
/// Chart.js ADR 0041, section 5). `keys` is the key list of each item in
/// order (`Object.keys`): the harness compares only the expected keys of a
/// Map.
Object? _realLegend(Chart chart) {
  final legend = chart.legend!;
  return <String, Object?>{
    'items': legend.legendItems,
    'keys': [
      for (final item in legend.legendItems!) jsObjectKeys(item),
    ],
    'hitBoxes': (legend as Legend).legendHitBoxes,
  };
}

/// [cases] with `undefined` for each expected `xAxisID` and `yAxisID` of
/// JS `null`.
///
/// The rule of controller.doughnut_test.dart. The Dart field
/// `ChartMeta.xAxisID` is an `Object?`: Dart `null`
/// stands for the JS `null` of the start value (core.controller.js:841-842)
/// and for the JS `undefined` that `linkScales` of the dataset controller
/// writes for an absent scale (core.datasetController.js:306-307). The
/// harness reads Dart `null` as `undefined` (`_observeDataset` of
/// controller_chart_harness.dart). The pie controller has the empty
/// `linkScales` of the doughnut (controller.doughnut.js:143), which keeps
/// the JS `null`. Thus the expected `null` becomes `undefined` here. No
/// other key changes. No reader of the port sees the difference: the pie
/// reads no axis id.
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
  controllerPieReference,
);

/// The config of a pie chart with the labels a, b, c and one dataset with
/// [data].
AnyObject _one(List<Object?> data) => <String, Object?>{
  'type': 'pie',
  'data': <String, Object?>{
    'labels': <Object?>['a', 'b', 'c'],
    'datasets': <Object?>[
      <String, Object?>{
        'data': <Object?>[...data],
      },
    ],
  },
};

void main() {
  testReferenceOrigin(
    node: controllerPieReferenceNode,
    arch: controllerPieReferenceArch,
    dist: controllerPieReferenceDist,
    commit: controllerPieReferenceCommit,
  );
  testReferenceWidths(controllerPieReferenceWidths);

  test('the reference has the 4 cases of Chart.js ADR 0030 first, then the '
      '3 interfaces: cases and the 3 legend: cases', () {
    final names = [for (final c in controllerPieReference) c.name];
    expect(names, [
      'default',
      'the step toggleDataVisibility',
      'two datasets',
      'the step hover',
      'interfaces: two datasets with other rotation and circumference',
      'interfaces: the labels of getLabelAndValue, set 1',
      'interfaces: the labels of getLabelAndValue, set 2',
      'legend: items',
      'legend: click',
      'legend: click twice',
    ]);
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
      theme: compileChartTheme(ChartThemes.light),
    );
  });

  // The pin tests of the interfaces spec, section 7.3, that need no
  // generated value.
  group('interfaces', () {
    test('the class value extends the doughnut class value and gets its '
        'descriptors and overrides', () {
      final pie = PieController.jsClass;
      expect(identical(pie.superclass, DoughnutController.jsClass), isTrue);
      expect(pie['id'], 'pie');
      expect(identical(pie['defaults'], PieController.defaults), isTrue);
      expect(
        identical(pie['descriptors'], DoughnutController.descriptors),
        isTrue,
      );
      expect(identical(pie['overrides'], DoughnutController.overrides), isTrue);
      expect(jsObjectKeys(PieController.defaults), [
        'cutout',
        'rotation',
        'circumference',
        'radius',
      ]);
    });

    test('the registered pie defaults are the doughnut defaults with the pie '
        'values', () {
      final pie = defaults.get('datasets.pie');
      final doughnut = defaults.get('datasets.doughnut');
      expect(jsObjectKeys(pie), jsObjectKeys(doughnut));
      for (final key in jsObjectKeys(doughnut)) {
        // The plain Maps of the merge: `equals` compares them deeply.
        expect(
          plainValue(jsGet(pie, key)),
          key == 'cutout' ? 0.0 : plainValue(jsGet(doughnut, key)),
          reason: key,
        );
      }
    });

    testWidgets('a pie chart constructs a PieController', (tester) async {
      final chart = acquireChart(_one(const <Object?>[1.0, 2.0, 3.0]));
      final controller = chart.getDatasetMeta(0).controller;
      expect(controller, isA<PieController>());
      expect(chart.getDatasetMeta(0).type, 'pie');
    });

    testWidgets('generateLabels throws a TypeError without a legend', (
      tester,
    ) async {
      // The legend plugin is off, so it writes no `chart.legend`.
      final chart = acquireChart(
        _one(const <Object?>[1.0, 2.0, 3.0])
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
      final config = _one(const <Object?>[1.0, 2.0, 3.0])
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
        <String, Object?>{'index': 1.0},
        legend,
      ]);

      expect(updates, before + 1);
      expect(chart.getDataVisibility(1), isFalse);
      expect(
        [for (final item in _generateLabels(chart)) jsGet(item, 'hidden')],
        [false, true, false],
      );
    });

    test('the legend functions of overrides.pie are the doughnut functions in '
        'each read', () {
      Object? generateLabels([String type = 'pie']) =>
          jsGet(jsGet(_legendOverrides(type), 'labels'), 'generateLabels');
      Object? onClick([String type = 'pie']) =>
          jsGet(_legendOverrides(type), 'onClick');
      expect(generateLabels(), isA<Function>());
      expect(onClick(), isA<Function>());
      expect(identical(generateLabels(), generateLabels()), isTrue);
      expect(identical(onClick(), onClick()), isTrue);
      expect(identical(generateLabels(), generateLabels('doughnut')), isTrue);
      expect(identical(onClick(), onClick('doughnut')), isTrue);
    });
  });
}
