// Original code, not ported from Chart.js: pie controller tests.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/drop_extra_args.dart';
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
LegendOptions _legendOverrides([String type = 'pie']) =>
    jsGet(jsGet(overrides[type], 'plugins'), 'legend')! as LegendOptions;

/// `generateLabels(chart)` of `overrides.pie.plugins.legend.labels`.
List<Object?> _generateLabels(Chart chart) =>
    callDroppingExtraArgs(_legendOverrides().labels!.generateLabels, [chart])!
        as List<Object?>;

/// The config of a pie chart with the labels a, b, c and one dataset with
/// [data].
ChartConfig _one(List<num?> data) => ChartConfig(
  labels: const ['a', 'b', 'c'],
  datasets: [
    PieDataset(data: [...data]),
  ],
);

Chart _chart(ChartConfig config) =>
    acquireChartRoot(ChartConfigLowering(config).lower());

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
      final chart = _chart(_one(const [1.0, 2.0, 3.0]));
      final controller = chart.getDatasetMeta(0).controller;
      expect(controller, isA<PieController>());
      expect(chart.getDatasetMeta(0).type, 'pie');
    });

    testWidgets('generateLabels throws a TypeError without a legend', (
      tester,
    ) async {
      // The legend plugin is off, so it writes no `chart.legend`.
      final chart = _chart(
        _one(const [1.0, 2.0, 3.0])
            .copyWith(disabledPlugins: const [PluginOff<LegendPlugin>()]),
      );
      expect(chart.legend, isNull);
      expect(() => _generateLabels(chart), throwsA(isA<TypeError>()));
    });

    testWidgets('onClick toggles the index of the item and updates the chart '
        'once', (tester) async {
      var updates = 0;
      final config = _one(const [1.0, 2.0, 3.0]).copyWith(
        plugins: [
          Plugin<Object?>(
            id: 'countUpdates',
            afterUpdate: (chart, args, options) {
              updates++;
            },
          ),
        ],
      );
      final chart = _chart(config);
      final legend = chart.legend!;
      final before = updates;

      callDroppingExtraArgs(_legendOverrides().onClick, [
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
          _legendOverrides(type).labels!.generateLabels;
      Object? onClick([String type = 'pie']) => _legendOverrides(type).onClick;
      expect(generateLabels(), isA<Function>());
      expect(onClick(), isA<Function>());
      expect(identical(generateLabels(), generateLabels()), isTrue);
      expect(identical(onClick(), onClick()), isTrue);
      expect(identical(generateLabels(), generateLabels('doughnut')), isTrue);
      expect(identical(onClick(), onClick('doughnut')), isTrue);
    });
  });
}
