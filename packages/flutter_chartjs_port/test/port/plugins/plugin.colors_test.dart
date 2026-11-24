// Original code, not ported from Chart.js: colors plugin reference tests.
@TestOn('vm')
library;

import 'dart:ui' as native_ui;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/light_theme.dart';
import '../scales/scale_chart_harness.dart';
import 'plugin_chart_harness.dart';
import 'plugin_colors_reference.dart';

// The port-only reference tests of lib/src/plugins/plugin.colors.dart
// (Chart.js ADR 0041, section 3). The spec port is
// test/specs/plugin.colors_test.dart.
//
// The reference group compares real charts with the charts of
// tool/reference/plugin_colors_reference.mjs: a build of the pinned Chart.js
// in Node.js v24.22.1 on arm64 (Chart.js ADR 0146), with the seven plugins
// registered and `colors.enabled: false` in the defaults. Each case except
// `full: radar` is a unit case: the other plugins are `false` (Chart.js ADR
// 0041, section 4). The full case has the default plugin options.
// The observation has `boxes` and `plugins.colors` (the colors of each
// dataset after `beforeLayout`), and the draw calls.
//
// The cases run two times: unthemed, and with the light preset (theming.md
// section 8 test 3, Chart.js ADR 0147). In the themed run, hunk H5 takes the
// palette of the light preset, and the colors compare in their parsed form.
//
// The groups `plugin object`, `theme palette` and
// `js-semantics-narrow-datasets` hold the pin tests that need no generated
// value.

/// [cases] with `undefined` for each expected `xAxisID` and `yAxisID` of
/// JS `null` in the cases with a `doughnut` or `pie` chart type or dataset
/// type, the form of `_undefinedAxisIds` of
/// test/port/controllers/controller.doughnut_test.dart.
///
/// The Dart field `ChartMeta.xAxisID` is an `Object?`: Dart `null` stands for
/// the JS `null` of the start value (core.controller.js:841-842) and for the
/// JS `undefined` that `linkScales` of the dataset controller writes for an
/// absent scale (core.datasetController.js:306-307). The harness reads Dart
/// `null` as `undefined`. The empty `linkScales` of the doughnut
/// (controller.doughnut.js:143) keeps the JS `null`. No reader of the port
/// sees the difference: the doughnut reads no axis id.
List<ScaleChartCase> _undefinedAxisIds(List<ScaleChartCase> cases) => [
  for (final c in cases)
    if (_hasDoughnutType(c.config))
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
      )
    else
      c,
];

/// Whether the chart type or a dataset type of [config] is `doughnut` or
/// `pie`.
bool _hasDoughnutType(Object config) {
  bool isDoughnut(Object? type) => type == 'doughnut' || type == 'pie';
  if (config case final ChartConfig Function() make) {
    return make().datasets.any((d) => d is DoughnutDataset || d is PieDataset);
  }
  final map = config as AnyObject;
  final datasets = jsGet(map['data'], 'datasets');
  return isDoughnut(map['type']) ||
      (datasets is List<Object?> &&
          datasets.any((dataset) => isDoughnut(jsGet(dataset, 'type'))));
}

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
  pluginColorsReference,
);

/// The observer `plugins.colors` of the generator: the `backgroundColor`
/// and the `borderColor` of each dataset of `chart.config.data.datasets`.
Object? _observeColors(Chart chart) => [
  for (final ds in jsGet(chart.config.data, 'datasets')! as List<Object?>)
    <String, Object?>{
      'backgroundColor': jsGet(ds, 'backgroundColor'),
      'borderColor': jsGet(ds, 'borderColor'),
    },
];

/// A chart config of [type] with [datasets] datasets of 3 items each, the
/// colors plugin on, and the raw theme map [theme] when it is not null.
ChartConfigurationScope _config(
  String type, {
  int datasets = 2,
  AnyObject? theme,
}) {
  Dataset dataset() => switch (type) {
    'bar' => const BarDataset(data: .values([1, 2, 3])),
    'doughnut' => const DoughnutDataset(data: [1, 2, 3]),
    'polarArea' => const PolarAreaDataset(data: [1, 2, 3]),
    _ => throw ArgumentError.value(type, 'type'),
  };
  final root = lowerForTest(
    ChartConfig(
      labels: const ['a', 'b', 'c'],
      datasets: [for (var d = 0; d < datasets; d++) dataset()],
      pluginOptions: const [ColorsPluginOptions(enabled: true)],
    ),
  );
  if (theme != null) root.dollarTheme = theme;
  return root;
}

/// A raw theme map with the palettes [border] and [background] in the
/// `ColorsPluginOptions` of `plugins.colors` (Chart.js ADR 0196).
AnyObject _paletteTheme(
  List<native_ui.Color> border,
  List<native_ui.Color> background,
) => <String, Object?>{
  'plugins': <String, Object?>{
    'colors': ColorsPluginOptions(
      borderColors: border,
      backgroundColors: background,
    ),
  },
};

/// A chart config of [type] with the one dataset [dataset] and the colors
/// plugin on when [enabled] is true.
ChartConfigurationScope _datasetConfig(
  String type,
  Object? dataset, {
  bool enabled = true,
}) {
  final root = lowerForTest(
    ChartConfig(
      labels: const ['a', 'b', 'c'],
      // The dataset of the lowering gives the chart type. The raw dataset
      // below replaces it.
      datasets: [
        switch (type) {
          'bar' => const BarDataset(),
          'doughnut' => const DoughnutDataset(),
          'polarArea' => const PolarAreaDataset(),
          _ => throw ArgumentError.value(type, 'type'),
        },
      ],
      pluginOptions: [ColorsPluginOptions(enabled: enabled)],
    ),
  );
  // The narrow and unmodifiable Map cases must keep the caller's dataset.
  (root.dataCell!.raw! as ChartDataScope).datasets = <Object?>[dataset];
  return root;
}

/// The dataset is a typed scope or the raw object of a boundary case.
Object _dataset(Chart chart, int index) =>
    (jsGet(chart.config.data, 'datasets')! as List<Object?>)[index]!;

void main() {
  testReferenceOrigin(
    node: pluginColorsReferenceNode,
    arch: pluginColorsReferenceArch,
    dist: pluginColorsReferenceDist,
    commit: pluginColorsReferenceCommit,
  );
  testReferenceWidths(pluginColorsReferenceWidths);

  testPluginChartCases(_reference, observers: {'colors': _observeColors});

  group('theming.md §8 test 3: the light preset', () {
    testPluginChartCases(
      _reference,
      observers: {'colors': _observeColors},
      theme: compileLightTheme(),
    );
  });

  group('plugin object', () {
    test('has the keys of plugin.colors.ts:94-126', () {
      // The native plugin of Chart.js ADR 0144: the upstream keys are `id`,
      // `defaults` and the hook `beforeLayout`.
      expect(pluginHookNames(colors), ['beforeLayout']);
      expect(colors.id, 'colors');
      // plugin.colors.ts:97-100, one options object (Chart.js ADR 0196).
      expect(
        colors.defaults,
        const ColorsPluginOptions(enabled: true, forceOverride: false),
      );
    });
  });

  group('theme palette', () {
    testWidgets('a theme palette colors the datasets', (tester) async {
      final chart = acquireChartRoot(
        _config(
          'bar',
          datasets: 3,
          theme: _paletteTheme(
            [
              const native_ui.Color(0xff000001),
              const native_ui.Color(0xff000002),
            ],
            [
              const native_ui.Color(0xff000003),
              const native_ui.Color(0xff000004),
            ],
          ),
        ),
      );
      expect(
        jsGet(_dataset(chart, 0), 'borderColor'),
        const ChartPaint.solid(native_ui.Color(0xff000001)),
      );
      expect(
        jsGet(_dataset(chart, 1), 'borderColor'),
        const ChartPaint.solid(native_ui.Color(0xff000002)),
      );
      expect(
        jsGet(_dataset(chart, 2), 'borderColor'),
        const ChartPaint.solid(native_ui.Color(0xff000001)),
      );
      expect(
        jsGet(_dataset(chart, 2), 'backgroundColor'),
        const ChartPaint.solid(native_ui.Color(0xff000003)),
      );
    });

    testWidgets('the doughnut and polar area colorizers read the palette', (
      tester,
    ) async {
      final doughnut = acquireChartRoot(
        _config(
          'doughnut',
          theme: _paletteTheme(
            [
              const native_ui.Color(0xff000001),
              const native_ui.Color(0xff000002),
            ],
            [const native_ui.Color(0xff000003)],
          ),
        ),
      );
      expect(jsGet(_dataset(doughnut, 0), 'backgroundColor'), [
        const ChartPaint.solid(native_ui.Color(0xff000001)),
        const ChartPaint.solid(native_ui.Color(0xff000002)),
        const ChartPaint.solid(native_ui.Color(0xff000001)),
      ]);
      expect(jsGet(_dataset(doughnut, 1), 'backgroundColor'), [
        const ChartPaint.solid(native_ui.Color(0xff000002)),
        const ChartPaint.solid(native_ui.Color(0xff000001)),
        const ChartPaint.solid(native_ui.Color(0xff000002)),
      ]);
      final polar = acquireChartRoot(
        _config(
          'polarArea',
          theme: _paletteTheme(
            [const native_ui.Color(0xff000001)],
            [
              const native_ui.Color(0xff000003),
              const native_ui.Color(0xff000004),
            ],
          ),
        ),
      );
      expect(jsGet(_dataset(polar, 0), 'backgroundColor'), [
        const ChartPaint.solid(native_ui.Color(0xff000003)),
        const ChartPaint.solid(native_ui.Color(0xff000004)),
        const ChartPaint.solid(native_ui.Color(0xff000003)),
      ]);
      expect(jsGet(_dataset(polar, 1), 'backgroundColor'), [
        const ChartPaint.solid(native_ui.Color(0xff000004)),
        const ChartPaint.solid(native_ui.Color(0xff000003)),
        const ChartPaint.solid(native_ui.Color(0xff000004)),
      ]);
    });

    testWidgets('H5 resets the palette: an unthemed chart after a themed '
        'chart gets the upstream palette', (tester) async {
      acquireChartRoot(
        _config(
          'bar',
          theme: _paletteTheme(
            [const native_ui.Color(0xff000001)],
            [const native_ui.Color(0xff000003)],
          ),
        ),
      );
      final chart = acquireChartRoot(_config('bar'));
      expect(
        jsGet(_dataset(chart, 0), 'borderColor'),
        const ChartPaint.solid(native_ui.Color.fromRGBO(54, 162, 235, 1)),
      );
      expect(
        jsGet(_dataset(chart, 1), 'borderColor'),
        const ChartPaint.solid(native_ui.Color.fromRGBO(255, 99, 132, 1)),
      );
      expect(
        jsGet(_dataset(chart, 1), 'backgroundColor'),
        const ChartPaint.solid(native_ui.Color.fromRGBO(255, 99, 132, 0.5)),
      );
    });

    testWidgets('an empty palette gives the upstream palette', (tester) async {
      // A palette is a List<Color> (Chart.js ADR 0196): a String or a Map
      // does not compile.
      for (final value in [<native_ui.Color>[]]) {
        final chart = acquireChartRoot(
          _config('bar', theme: _paletteTheme(value, value)),
        );
        expect(
          jsGet(_dataset(chart, 0), 'borderColor'),
          const ChartPaint.solid(native_ui.Color.fromRGBO(54, 162, 235, 1)),
        );
        expect(
          jsGet(_dataset(chart, 0), 'backgroundColor'),
          const ChartPaint.solid(native_ui.Color.fromRGBO(54, 162, 235, 0.5)),
        );
      }
    });

    testWidgets('a palette in the options of the chart comes over the '
        'palette of the theme', (tester) async {
      // The palette is a field of the merged ColorsPluginOptions (Chart.js
      // ADR 0196): the options of the chart come over the theme.
      final chart = acquireChartRoot(
        lowerForTest(
            const ChartConfig(
              labels: ['a', 'b', 'c'],
              datasets: [
                BarDataset(data: .values([1, 2, 3])),
              ],
              pluginOptions: [
                ColorsPluginOptions(
                  enabled: true,
                  borderColors: [native_ui.Color(0xff000005)],
                ),
              ],
            ),
          )
          ..dollarTheme = _paletteTheme(
            [const native_ui.Color(0xff000001)],
            [const native_ui.Color(0xff000003)],
          ),
      );
      expect(
        jsGet(_dataset(chart, 0), 'borderColor'),
        const ChartPaint.solid(native_ui.Color(0xff000005)),
      );
      expect(
        jsGet(_dataset(chart, 0), 'backgroundColor'),
        const ChartPaint.solid(native_ui.Color(0xff000003)),
      );
    });
  });

  // differences.md row js-semantics-narrow-datasets: the colorizers write
  // into the dataset Map of the user (plugin.colors.ts:36-37, 43, 49).
  // Upstream sets the properties of each of these datasets. A probe on the
  // pinned build in Node.js v24.12.0 on x64 made a bar chart and a doughnut
  // chart with `plugins.colors.enabled: true` and no dataset colors, and
  // logged the borderColor and backgroundColor of each dataset: the bar
  // dataset gets ["rgb(54, 162, 235)", "rgba(54, 162, 235, 0.5)"], and the
  // doughnut dataset gets [null, ["rgb(54, 162, 235)", "rgb(255, 99, 132)",
  // "rgb(255, 159, 64)"]] (no borderColor, a backgroundColor array).
  group('js-semantics-narrow-datasets', () {
    testWidgets('a narrow dataset Map works when the plugin is off', (
      tester,
    ) async {
      final chart = acquireChartRoot(
        _datasetConfig('bar', <String, List<int>>{
          'data': [1, 2, 3],
        }, enabled: false),
      );
      expect(jsGet(_dataset(chart, 0), 'borderColor'), same(undefined));
    });

    for (final type in ['bar', 'doughnut', 'polarArea']) {
      testWidgets('$type: a Map<String, List<int>> dataset throws a '
          'TypeError at the color write', (tester) async {
        expect(
          () => acquireChartRoot(
            _datasetConfig(type, <String, List<int>>{
              'data': [1, 2, 3],
            }),
          ),
          throwsA(isA<TypeError>()),
        );
      });
    }

    testWidgets('an unmodifiable dataset Map throws an UnsupportedError', (
      tester,
    ) async {
      expect(
        () => acquireChartRoot(
          _datasetConfig(
            'bar',
            Map<String, Object?>.unmodifiable(<String, Object?>{
              'data': <Object?>[1, 2, 3],
            }),
          ),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    testWidgets('a Map<String, Object?> dataset takes the colors', (
      tester,
    ) async {
      final chart = acquireChartRoot(
        _datasetConfig('bar', <String, Object?>{
          'data': <Object?>[1, 2, 3],
        }),
      );
      expect(
        jsGet(_dataset(chart, 0), 'borderColor'),
        const ChartPaint.solid(native_ui.Color.fromRGBO(54, 162, 235, 1)),
      );
      expect(
        jsGet(_dataset(chart, 0), 'backgroundColor'),
        const ChartPaint.solid(native_ui.Color.fromRGBO(54, 162, 235, 0.5)),
      );
    });
  });

  // plugin.colors.ts:90-92 `containsDefaultColorsDefenitions()` and :119.
  // A probe on the pinned build in Node.js v24.12.0 on x64 set
  // `defaults.borderColor = 'red'`, made a bar chart with 2 datasets and
  // `plugins.colors.enabled: true`, and logged the colors of the datasets
  // and the options of the first bar of dataset 1: [[undefined, undefined],
  // [undefined, undefined]] and ["red", "rgba(0,0,0,0.1)"]. With
  // `forceOverride: true`, dataset 1 gets ["rgb(255, 99, 132)",
  // "rgba(255, 99, 132, 0.5)"].
  group('containsDefaultColorsDefenitions', () {
    testWidgets('a changed defaults.borderColor stops the colorize', (
      tester,
    ) async {
      defaults['borderColor'] = const ChartPaint.solid(
        native_ui.Color.fromRGBO(255, 0, 0, 1),
      );
      final chart = acquireChartRoot(_config('bar'));
      expect(jsGet(_dataset(chart, 1), 'borderColor'), same(undefined));
      expect(jsGet(_dataset(chart, 1), 'backgroundColor'), same(undefined));
      final options =
          (chart.getDatasetMeta(1).data[0] as Element).options! as JsObjectFace;
      expect(
        options['borderColor'],
        const ChartPaint.solid(native_ui.Color.fromRGBO(255, 0, 0, 1)),
      );
      expect(
        options['backgroundColor'],
        const ChartPaint.solid(native_ui.Color.fromRGBO(0, 0, 0, 0.1)),
      );
    });

    testWidgets('forceOverride colorizes over a changed defaults.borderColor', (
      tester,
    ) async {
      defaults['borderColor'] = const ChartPaint.solid(
        native_ui.Color.fromRGBO(255, 0, 0, 1),
      );
      final config = _config('bar');
      ((config['options']! as JsObjectFace)['plugins']!
          as JsObjectFace)['colors'] = const ColorsPluginOptions(
        enabled: true,
        forceOverride: true,
      );
      final chart = acquireChartRoot(config);
      expect(
        jsGet(_dataset(chart, 1), 'borderColor'),
        const ChartPaint.solid(native_ui.Color.fromRGBO(255, 99, 132, 1)),
      );
      expect(
        jsGet(_dataset(chart, 1), 'backgroundColor'),
        const ChartPaint.solid(native_ui.Color.fromRGBO(255, 99, 132, 0.5)),
      );
    });
  });
}
