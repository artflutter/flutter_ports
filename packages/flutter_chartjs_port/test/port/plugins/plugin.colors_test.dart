// Original code, not ported from Chart.js: colors plugin reference tests.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/core/core.config.dart'
    show themeConfigKey;
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.colors.dart';
import 'package:flutter_chartjs_port/src/theme/compile.dart';
import 'package:flutter_chartjs_port/src/theme/presets.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_test/flutter_test.dart';

import '../scales/scale_chart_harness.dart';
import 'plugin_chart_harness.dart';
import 'plugin_colors_reference.dart';

// The port-only reference tests of lib/src/plugins/plugin.colors.dart
// (Chart.js ADR 0041, section 3). The spec port is
// test/specs/plugin.colors_test.dart.
//
// The reference group compares real charts with the charts of
// tool/reference/plugin_colors_reference.mjs: a build of the pinned Chart.js
// in Node.js v24.12.0 on x64 (Chart.js ADR 0032), with the seven plugins
// registered and `colors.enabled: false` in the defaults. Each case except
// `full: radar` is a unit case: the other plugins are `false` (Chart.js ADR
// 0041, section 4). The full case has the default plugin options.
// The observation has `boxes` and `plugins.colors` (the colors of each
// dataset after `beforeLayout`), and the draw calls.
//
// The cases run two times: unthemed, and with the light preset (theming.md
// section 8 test 3, Chart.js ADR 0042). In the themed run, hunk H5 takes the
// palette of the light preset, and the colors compare in their parsed form.
//
// The groups `plugin object`, `theme palette` and
// `js-semantics-narrow-datasets` hold the pin tests that need no generated
// value. test/port/theme/precedence_test.dart (group
// `palette`) compares the theme palette rows with the JavaScript prototype
// of the hunks H4a-H5.

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
bool _hasDoughnutType(AnyObject config) {
  bool isDoughnut(Object? type) => type == 'doughnut' || type == 'pie';
  final datasets = jsGet(config['data'], 'datasets');
  return isDoughnut(config['type']) ||
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
AnyObject _config(String type, {int datasets = 2, AnyObject? theme}) =>
    <String, Object?>{
      'type': type,
      'data': <String, Object?>{
        'labels': <Object?>['a', 'b', 'c'],
        'datasets': <Object?>[
          for (var d = 0; d < datasets; d++)
            <String, Object?>{
              'data': <Object?>[1, 2, 3],
            },
        ],
      },
      'options': <String, Object?>{
        'plugins': <String, Object?>{
          'colors': <String, Object?>{'enabled': true},
        },
      },
      themeConfigKey: ?theme,
    };

/// A raw theme map with the palettes [border] and [background] under
/// `plugins.colors` (the keys of hunk H4a).
AnyObject _paletteTheme(Object? border, Object? background) =>
    <String, Object?>{
      'plugins': <String, Object?>{
        'colors': <String, Object?>{
          themeBorderColorsKey: border,
          themeBackgroundColorsKey: background,
        },
      },
    };

/// A chart config of [type] with the one dataset [dataset] and the colors
/// plugin on when [enabled] is true.
AnyObject _datasetConfig(String type, Object? dataset, {bool enabled = true}) =>
    <String, Object?>{
      'type': type,
      'data': <String, Object?>{
        'labels': <Object?>['a', 'b', 'c'],
        'datasets': <Object?>[dataset],
      },
      'options': <String, Object?>{
        'plugins': <String, Object?>{
          'colors': <String, Object?>{'enabled': enabled},
        },
      },
    };

/// The dataset [index] of the config data of [chart].
AnyObject _dataset(Chart chart, int index) =>
    (jsGet(chart.config.data, 'datasets')! as List<Object?>)[index]!
        as AnyObject;

void main() {
  testReferenceOrigin(
    node: pluginColorsReferenceNode,
    arch: pluginColorsReferenceArch,
    dist: pluginColorsReferenceDist,
    commit: pluginColorsReferenceCommit,
  );
  testReferenceWidths(pluginColorsReferenceWidths);

  testPluginChartCases(
    _reference,
    observers: {'colors': _observeColors},
  );

  group('theming.md §8 test 3: the light preset', () {
    testPluginChartCases(
      _reference,
      observers: {'colors': _observeColors},
      theme: compileChartTheme(ChartThemes.light),
    );
  });

  group('plugin object', () {
    test('has the keys of plugin.colors.ts:94-126 in order', () {
      expect(jsObjectKeys(colors), ['id', 'defaults', 'beforeLayout']);
      expect(colors['id'], 'colors');
      expect(colors['defaults'], <String, Object?>{
        'enabled': true,
        'forceOverride': false,
      });
    });

    test('the palette keys of hunk H4a', () {
      expect(themeBorderColorsKey, r'$borderColors');
      expect(themeBackgroundColorsKey, r'$backgroundColors');
    });
  });

  group('theme palette', () {
    testWidgets('a theme palette colors the datasets', (tester) async {
      final chart = acquireChart(
        _config(
          'bar',
          datasets: 3,
          theme: _paletteTheme(['b0', 'b1'], ['g0', 'g1']),
        ),
      );
      expect(_dataset(chart, 0)['borderColor'], 'b0');
      expect(_dataset(chart, 1)['borderColor'], 'b1');
      expect(_dataset(chart, 2)['borderColor'], 'b0');
      expect(_dataset(chart, 2)['backgroundColor'], 'g0');
    });

    testWidgets('the doughnut and polar area colorizers read the palette', (
      tester,
    ) async {
      final doughnut = acquireChart(
        _config('doughnut', theme: _paletteTheme(['b0', 'b1'], ['g0'])),
      );
      expect(_dataset(doughnut, 0)['backgroundColor'], ['b0', 'b1', 'b0']);
      expect(_dataset(doughnut, 1)['backgroundColor'], ['b1', 'b0', 'b1']);
      final polar = acquireChart(
        _config('polarArea', theme: _paletteTheme(['b0'], ['g0', 'g1'])),
      );
      expect(_dataset(polar, 0)['backgroundColor'], ['g0', 'g1', 'g0']);
      expect(_dataset(polar, 1)['backgroundColor'], ['g1', 'g0', 'g1']);
    });

    testWidgets('H5 resets the palette: an unthemed chart after a themed '
        'chart gets the upstream palette', (tester) async {
      acquireChart(_config('bar', theme: _paletteTheme(['b0'], ['g0'])));
      final chart = acquireChart(_config('bar'));
      expect(_dataset(chart, 0)['borderColor'], 'rgb(54, 162, 235)');
      expect(_dataset(chart, 1)['borderColor'], 'rgb(255, 99, 132)');
      expect(_dataset(chart, 1)['backgroundColor'], 'rgba(255, 99, 132, 0.5)');
    });

    testWidgets('an empty List, a String or a Map palette gives the upstream '
        'palette', (tester) async {
      for (final value in <Object?>[<Object?>[], 'red', <String, Object?>{}]) {
        final chart = acquireChart(
          _config('bar', theme: _paletteTheme(value, value)),
        );
        expect(_dataset(chart, 0)['borderColor'], 'rgb(54, 162, 235)');
        expect(
          _dataset(chart, 0)['backgroundColor'],
          'rgba(54, 162, 235, 0.5)',
        );
      }
    });

    testWidgets('a palette key in the plugin options has no effect', (
      tester,
    ) async {
      final config = _config('bar');
      ((config['options']! as AnyObject)['plugins']!
          as AnyObject)['colors'] = <String, Object?>{
        'enabled': true,
        themeBorderColorsKey: <Object?>['u0'],
      };
      final chart = acquireChart(config);
      expect(_dataset(chart, 0)['borderColor'], 'rgb(54, 162, 235)');
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
      final chart = acquireChart(
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
          () => acquireChart(
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
        () => acquireChart(
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
      final chart = acquireChart(
        _datasetConfig('bar', <String, Object?>{
          'data': <Object?>[1, 2, 3],
        }),
      );
      expect(_dataset(chart, 0)['borderColor'], 'rgb(54, 162, 235)');
      expect(_dataset(chart, 0)['backgroundColor'], 'rgba(54, 162, 235, 0.5)');
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
      defaults['borderColor'] = 'red';
      final chart = acquireChart(_config('bar'));
      expect(jsGet(_dataset(chart, 1), 'borderColor'), same(undefined));
      expect(jsGet(_dataset(chart, 1), 'backgroundColor'), same(undefined));
      final options = (chart.getDatasetMeta(1).data[0] as Element).options!;
      expect(options['borderColor'], 'red');
      expect(options['backgroundColor'], 'rgba(0,0,0,0.1)');
    });

    testWidgets('forceOverride colorizes over a changed defaults.borderColor', (
      tester,
    ) async {
      defaults['borderColor'] = 'red';
      final config = _config('bar');
      ((config['options']! as AnyObject)['plugins']! as AnyObject)['colors'] =
          <String, Object?>{'enabled': true, 'forceOverride': true};
      final chart = acquireChart(config);
      expect(_dataset(chart, 1)['borderColor'], 'rgb(255, 99, 132)');
      expect(_dataset(chart, 1)['backgroundColor'], 'rgba(255, 99, 132, 0.5)');
    });
  });
}
