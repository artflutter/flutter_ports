// Original code, not ported from Chart.js: pie controller tests.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/controllers/controller.doughnut.dart';
import 'package:flutter_chartjs_port/src/controllers/controller.pie.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart'
    show defaults, overrides;
import 'package:flutter_chartjs_port/src/helpers/radius_length.dart'
    show PixelRadius;
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_function.dart' show jsCall;
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/legend_item.dart';
import 'package:flutter_test/flutter_test.dart';

import 'controller_chart_harness.dart';

// The port-only tests of lib/src/controllers/controller.pie.dart. Pie has no
// upstream spec file and no reference test: controller.pie.js extends
// controller.doughnut.js and changes only the defaults, so the doughnut
// reference test covers the code. These tests pin the statics that the pie
// class value gets from the doughnut class value, the registered defaults,
// and the legend functions (Chart.js ADR 0028, section 7.3).
//
// flutter_test_config.dart registers the pie controller and its parent class,
// the doughnut controller, with the built-in components before main() (Chart.js
// ADR 0030, section 3 item 4), and the seven plugins with
// `defaults.plugins.colors.enabled = false` (Chart.js ADR 0041, section 1).

/// `overrides[type].plugins.legend`.
Object? _legendOverrides([String type = 'pie']) =>
    jsGet(jsGet(overrides[type], 'plugins'), 'legend');

/// `generateLabels(chart)` of `overrides.pie.plugins.legend.labels`.
List<Object?> _generateLabels(Chart chart) =>
    jsCall(jsGet(jsGet(_legendOverrides(), 'labels'), 'generateLabels'), [
          chart,
        ])!
        as List<Object?>;

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
          key == 'cutout'
              ? const PixelRadius(0)
              : plainValue(jsGet(doughnut, key)),
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
