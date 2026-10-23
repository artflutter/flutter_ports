// Original code, not ported from Chart.js: decimation plugin tests.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/core/core.config.dart'
    show themeConfigKey;
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_number.dart' show jsTruthy;
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.decimation.dart';
import 'package:flutter_chartjs_port/src/theme/compile.dart';
import 'package:flutter_chartjs_port/src/theme/presets.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import '../controllers/controller_chart_harness.dart' show plainValue;
import '../scales/scale_chart_harness.dart';
import 'plugin_chart_harness.dart';
import 'plugin_decimation_reference.dart';

// The port-only tests of lib/src/plugins/plugin.decimation.dart. The spec
// port is test/specs/plugin.decimation_test.dart. The pure tests of the two
// algorithms are in plugin.decimation_algorithms_test.dart.
//
// The reference group compares real charts with the charts of
// tool/reference/plugin_decimation_reference.mjs: a build of the pinned
// Chart.js in Node.js v24.12.0 on x64 (Chart.js ADR 0032), with the seven
// plugins registered and `colors.enabled: false` in the defaults. Each case
// is a unit case (the other plugins are `false`, Chart.js ADR 0041, section
// 4), except the full cases (the names that start with `full:`), which have
// the default plugin options (section 4 item 2). The observation has `boxes`
// and `plugins.decimation` (the keys, the accessor state and the data of each
// dataset), and the draw calls. The cases run two times: unthemed, and with the
// light preset (theming.md section 8 test 3, Chart.js ADR 0042).
//
// The group `adapt-decimation-data-accessor` pins the accessor of
// plugin.decimation.js:249-265 on real charts (Chart.js ADR 0038, section
// 8): the keys, the arrays and the throws after each hook, and the four
// results of the differences.md row. Each upstream value in a comment
// comes from a probe on the pinned build in Node.js v24.12.0 on x64
// (controller_chart_common.mjs: loadChartJs, registerBuiltins, makeChart)
// that made the chart of the test, ran its steps and logged the keys of
// the dataset, the lengths of `data`, `_data` and `_decimated`, their
// identities and the element count: the probe p3_accessor (line A<n>), and
// the review probes review-upstream (line R<n>) and fix-upstream (line
// F<n>). Each comment gives the logged values that the test pins.

/// The observer `plugins.decimation` of the generator: for each dataset of
/// `chart.data.datasets`, its keys in order, whether `_decimated` is a key,
/// whether `_data` is an own key, whether `data` is the `_decimated` array,
/// and the plain `data`.
Object? _observeDecimation(Chart chart) => [
  for (final ds in _datasets(chart).cast<AnyObject>())
    <String, Object?>{
      'keys': jsObjectKeys(ds),
      'decimated': ds.containsKey('_decimated'),
      'ownData': ds.containsKey('_data'),
      'dataIsDecimated': identical(jsGet(ds, 'data'), jsGet(ds, '_decimated')),
      'data': plainValue(jsGet(ds, 'data')),
    },
];

/// `chart.data.datasets`.
List<Object?> _datasets(Chart chart) =>
    jsGet(chart.data, 'datasets')! as List<Object?>;

/// [n] items `{x: i, y: f(i)}` (`series` of the generator).
List<Object?> _series(int n, int Function(int i) f) => <Object?>[
  for (var i = 0; i < n; i++) <String, Object?>{'x': i, 'y': f(i)},
];

/// The `beforeUpdate` hook `writeData` of the inline plugin `writer` of the
/// generator: when its option `write` is true, it writes 80 new items into
/// `data` of the dataset 0.
void _writeData(types.Chart chart, AnyObject args, AnyObject options) {
  if (jsTruthy(jsGet(options, 'write'))) {
    final datasets = jsGet(chart.data, 'datasets')! as List<Object?>;
    (datasets[0]! as AnyObject)['data'] = _series(80, (i) => (i * 11) % 19);
  }
}

/// The named functions of the configs of the generator.
final Map<String, Object?> _functions = {'writeData': _writeData};

/// The decimated chart of the group `adapt-decimation-data-accessor`: 2000
/// items `{x: i, y: (i * 37) % 101}` in the dataset `{label, borderWidth,
/// data, pointRadius}` and the keys of [dataset], `parsing: false`, a linear
/// x scale, `min-max` with `samples: 50` and `threshold: 100` and the
/// options of [decimation], a canvas of 100 x 100.
({Chart chart, AnyObject dataset, List<Object?> data}) _accessorChart({
  AnyObject decimation = const {},
  AnyObject dataset = const {},
  AnyObject? theme,
}) {
  final data = _series(2000, (i) => (i * 37) % 101);
  final ds = <String, Object?>{
    'label': 'd',
    'borderWidth': 1,
    'data': data,
    'pointRadius': 0,
    ...dataset,
  };
  final chart = acquireChart(
    <String, Object?>{
      'type': 'line',
      'data': <String, Object?>{
        'datasets': <Object?>[ds],
      },
      'options': <String, Object?>{
        'parsing': false,
        'scales': <String, Object?>{
          'x': <String, Object?>{'type': 'linear'},
        },
        'plugins': <String, Object?>{
          'decimation': <String, Object?>{
            'enabled': true,
            'algorithm': 'min-max',
            'samples': 50,
            'threshold': 100,
            ...decimation,
          },
        },
      },
      themeConfigKey: ?theme,
    },
    <String, Object?>{
      'canvas': <String, Object?>{'width': 100, 'height': 100},
    },
  );
  return (chart: chart, dataset: ds, data: data);
}

/// `chart.options.plugins`, the option resolver of the plugins.
AnyObject _plugins(Chart chart) =>
    jsGet(chart.options, 'plugins')! as AnyObject;

/// `chart.options.plugins.decimation`.
AnyObject _decimationOptions(Chart chart) =>
    jsGet(_plugins(chart), 'decimation')! as AnyObject;

/// `chart.getDatasetMeta(0).data.length`.
int _metaCount(Chart chart) => chart.getDatasetMeta(0).data.length;

/// The length of the List [value].
int _length(Object? value) => (value! as List<Object?>).length;

/// The keys of the decimated dataset after the first decimation (A1).
const List<String> _decimatedKeys = [
  'label',
  'borderWidth',
  'pointRadius',
  '_data',
  'data',
  '_decimated',
];

void main() {
  testReferenceOrigin(
    node: pluginDecimationReferenceNode,
    arch: pluginDecimationReferenceArch,
    dist: pluginDecimationReferenceDist,
    commit: pluginDecimationReferenceCommit,
  );
  testReferenceWidths(pluginDecimationReferenceWidths);

  testPluginChartCases(
    pluginDecimationReference,
    observers: {'decimation': _observeDecimation},
    functions: _functions,
  );

  group('theming.md §8 test 3: the light preset', () {
    testPluginChartCases(
      pluginDecimationReference,
      observers: {'decimation': _observeDecimation},
      functions: _functions,
      theme: compileChartTheme(ChartThemes.light),
    );
  });

  group('plugin object', () {
    test('has the keys of plugin.decimation.js:197-287 in order', () {
      expect(jsObjectKeys(decimation), [
        'id',
        'defaults',
        'beforeElementsUpdate',
        'destroy',
      ]);
      expect(decimation['id'], 'decimation');
      expect(decimation['defaults'], <String, Object?>{
        'algorithm': 'min-max',
        'enabled': false,
      });
    });
  });

  group('adapt-decimation-data-accessor', () {
    testWidgets('the first decimation', (tester) async {
      final (:chart, :dataset, :data) = _accessorChart();
      // A1: the user Map is the dataset of the chart (plugins spec risk 4).
      expect(_datasets(chart)[0], same(dataset));
      expect(jsObjectKeys(dataset), _decimatedKeys);
      expect(_length(dataset['data']), 386);
      expect(dataset['data'], same(dataset['_decimated']));
      expect(dataset['_data'], same(data));
      expect(_metaCount(chart), 386);
      expect((dataset['data']! as List<Object?>)[1], {'x': 19, 'y': 97});
    });

    testWidgets('a user write, then the next update', (tester) async {
      final (:chart, :dataset, :data) = _accessorChart();
      final decimated = dataset['data'];
      final written = _series(3000, (i) => i % 7);
      dataset['data'] = written;
      // Difference 1 of the row: before the next hook, `data` is the written
      // array and `_data` the old raw data. Upstream (A2), the read gives
      // the old decimated array, and `_data` is the written array.
      expect(dataset['data'], same(written));
      expect(dataset['data'], isNot(same(decimated)));
      expect(dataset['_data'], same(data));
      expect(jsObjectKeys(dataset), _decimatedKeys);

      chart.update();
      // A2 after the update.
      expect(jsObjectKeys(dataset), _decimatedKeys);
      expect(_length(dataset['data']), 372);
      expect(dataset['data'], same(dataset['_decimated']));
      expect(dataset['_data'], same(written));
      expect(_metaCount(chart), 372);
    });

    testWidgets('difference 2: the write of the decimated array itself', (
      tester,
    ) async {
      final (:chart, :dataset, data: _) = _accessorChart();
      final written = _series(3000, (i) => i % 7);
      dataset['data'] = written;
      chart.update();
      dataset['data'] = dataset['data'];
      chart.update();
      // Upstream (A3), `_data` is the decimated array of 372 items, and the
      // update decimates it again. The port keeps the raw data.
      expect(dataset['_data'], same(written));
      expect(_length(dataset['data']), 372);
      expect(_metaCount(chart), 372);
    });

    testWidgets('below the threshold, the clean restores the raw data', (
      tester,
    ) async {
      final (:chart, :dataset, :data) = _accessorChart();
      _decimationOptions(chart)['threshold'] = 100000;
      chart.update();
      // A4.
      expect(jsObjectKeys(dataset), [
        'label',
        'borderWidth',
        'pointRadius',
        'data',
      ]);
      expect(dataset['data'], same(data));
      expect(_metaCount(chart), 2000);
    });

    testWidgets('the clean keeps the place of data', (tester) async {
      final (:chart, :dataset, data: _) = _accessorChart();
      dataset['foo'] = 1;
      expect(jsObjectKeys(dataset), [..._decimatedKeys, 'foo']);
      final written = _series(3, (i) => i);
      dataset['data'] = written;
      chart.update();
      // A5.
      expect(jsObjectKeys(dataset), [
        'label',
        'borderWidth',
        'pointRadius',
        'data',
        'foo',
      ]);
      expect(dataset['data'], same(written));
      expect(_metaCount(chart), 3);
    });

    testWidgets('a write, then enabled: false', (tester) async {
      final (:chart, :dataset, data: _) = _accessorChart();
      final written = _series(2, (i) => i + 1);
      dataset['data'] = written;
      _decimationOptions(chart)['enabled'] = false;
      chart.update();
      // A6.
      expect(jsObjectKeys(dataset), [
        'label',
        'borderWidth',
        'pointRadius',
        'data',
      ]);
      expect(dataset['data'], same(written));
      expect(_metaCount(chart), 2);
    });

    for (final (name, change, keys) in [
      (
        'parsing: true',
        (Chart chart, AnyObject dataset) => chart.options['parsing'] = true,
        _decimatedKeys,
      ),
      (
        "indexAxis: 'y'",
        (Chart chart, AnyObject dataset) => dataset['indexAxis'] = 'y',
        [..._decimatedKeys, 'indexAxis'],
      ),
      // plugin.decimation.js:225. The new bar controller runs `_dataCheck`
      // before the hook (difference 1 of the row). Upstream: line R5 of the
      // probe review-upstream.
      (
        'a controller without supportsDecimation',
        (Chart chart, AnyObject dataset) => dataset['type'] = 'bar',
        [..._decimatedKeys, 'type'],
      ),
    ]) {
      testWidgets('an early return after a write: $name', (tester) async {
        final (:chart, :dataset, data: _) = _accessorChart();
        final decimated = dataset['data'];
        final written = _series(2, (i) => i + 1);
        dataset['data'] = written;
        change(chart, dataset);
        chart.update();
        // A7: the sync runs before the early return.
        expect(dataset['data'], same(decimated));
        expect(dataset['_data'], same(written));
        expect(jsObjectKeys(dataset), keys);
        expect(_metaCount(chart), 386);
      });
    }

    testWidgets('difference 3: a write while the plugin is off', (
      tester,
    ) async {
      final (:chart, :dataset, data: _) = _accessorChart();
      _plugins(chart)['decimation'] = false;
      chart.update();
      final written = _series(2, (i) => i + 1);
      dataset['data'] = written;
      chart.update();
      // Upstream (A8), the accessor stays: `data` gives the old decimated
      // array, and the chart keeps 386 elements. The port shows the written
      // data.
      expect(dataset['data'], same(written));
      expect(_metaCount(chart), 2);
    });

    testWidgets('difference 4: a delete of data, then a write before the '
        'update', (tester) async {
      final (:chart, :dataset, :data) = _accessorChart();
      dataset.remove('data');
      final written = _series(3000, (i) => i % 7);
      dataset['data'] = written;
      chart.update();
      // Upstream (line R3 of the probe review-upstream), the delete removes
      // the accessor and the write
      // makes a plain property: `data` is the written array (3000 items),
      // `_data` is the old raw data, and the chart has 3000 elements. The
      // port sees no delete at the sync: it takes the write as a setter
      // write and decimates the written array.
      expect(jsObjectKeys(dataset), [
        'label',
        'borderWidth',
        'pointRadius',
        '_data',
        '_decimated',
        'data',
      ]);
      expect(_length(dataset['data']), 372);
      expect(dataset['data'], same(dataset['_decimated']));
      expect(dataset['_data'], same(written));
      expect(dataset['_data'], isNot(same(data)));
      expect(_metaCount(chart), 372);
    });

    // The cases of a user write or delete of `_decimated`. The upstream
    // values come from the lines F3a to F3d of the probe fix-upstream.
    testWidgets('a write of _decimated keeps _data', (tester) async {
      final (:chart, :dataset, :data) = _accessorChart();
      final decimated = dataset['data'];
      final empty = <Object?>[];
      dataset['_decimated'] = empty;
      // Difference 1 of the row: before the next hook, `data` is the old
      // decimated array. Upstream (F3a), the getter gives the new array.
      expect(dataset['data'], same(decimated));
      expect(dataset['_data'], same(data));
      for (var k = 0; k < 2; k++) {
        chart.update();
        // F3a.
        expect(jsObjectKeys(dataset), _decimatedKeys);
        expect(dataset['_data'], same(data));
        expect(_length(dataset['data']), 386);
        expect(dataset['data'], same(dataset['_decimated']));
        expect(_metaCount(chart), 386);
      }
    });

    testWidgets('a write of _decimated, then an early return', (tester) async {
      final (:chart, :dataset, :data) = _accessorChart();
      final empty = <Object?>[];
      dataset['_decimated'] = empty;
      chart.options['parsing'] = true;
      chart.update();
      // F3b: the sync gives the getter value, and `_data` stays.
      expect(jsObjectKeys(dataset), _decimatedKeys);
      expect(dataset['data'], same(empty));
      expect(dataset['_data'], same(data));
      expect(_metaCount(chart), 0);
    });

    testWidgets('a delete of _decimated, then the update', (tester) async {
      final (:chart, :dataset, :data) = _accessorChart();
      final decimated = dataset['data'];
      dataset.remove('_decimated');
      // Difference 1 of the row: before the next hook, `data` is the old
      // decimated array. Upstream (F3c), the getter gives `undefined`.
      expect(dataset['data'], same(decimated));
      expect(jsObjectKeys(dataset), [
        'label',
        'borderWidth',
        'pointRadius',
        '_data',
        'data',
      ]);
      chart.update();
      // F3c.
      expect(jsObjectKeys(dataset), _decimatedKeys);
      expect(dataset['_data'], same(data));
      expect(_length(dataset['data']), 386);
      expect(_metaCount(chart), 386);
    });

    testWidgets('a delete of _decimated, then enabled: false', (tester) async {
      final (:chart, :dataset, :data) = _accessorChart();
      dataset.remove('_decimated');
      _decimationOptions(chart)['enabled'] = false;
      chart.update();
      // The clean sees no `_decimated` (plugin.decimation.js:157), so the
      // accessor stays. The sync writes the getter value `undefined` into
      // `data`, and `_dataCheck` (core.datasetController.js:367) then writes
      // a new empty array into `data`. Upstream (F3d), that write goes
      // through the setter: `_data` is the empty array, and `data` gives
      // `undefined`. The port keeps the plain write until the next hook
      // (difference 1 of the row): `data` is the empty array, and `_data`
      // the old raw data.
      expect(jsObjectKeys(dataset), [
        'label',
        'borderWidth',
        'pointRadius',
        '_data',
        'data',
      ]);
      expect(dataset['data'], isEmpty);
      expect(dataset['_data'], same(data));
      expect(_metaCount(chart), 0);
      chart.update();
      // At the next hook, the sync moves the empty array into `_data`, as
      // the upstream setter did.
      expect(_length(dataset['_data']), 0);
      expect(_metaCount(chart), 0);
    });

    testWidgets('an unknown algorithm throws at two updates in a row', (
      tester,
    ) async {
      final (:chart, :dataset, data: _) = _accessorChart(
        decimation: {'enabled': false},
      );
      _decimationOptions(chart)
        ..['enabled'] = true
        ..['algorithm'] = 'nope';
      for (var k = 0; k < 2; k++) {
        // A9: the JS Error of plugin.decimation.js:277 is a StateError.
        expect(
          chart.update,
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              "Unsupported decimation algorithm 'nope'",
            ),
          ),
        );
        expect(jsObjectKeys(dataset), [
          'label',
          'borderWidth',
          'pointRadius',
          '_data',
          'data',
        ]);
        expect(dataset['data'], same(undefined));
        expect(_length(dataset['_data']), 2000);
        expect(_metaCount(chart), 2000);
      }
      _decimationOptions(chart)['algorithm'] = 'lttb';
      chart.update();
      expect(jsObjectKeys(dataset), _decimatedKeys);
      expect(_length(dataset['data']), 50);
      expect(_metaCount(chart), 50);
    });

    testWidgets('a delete of data removes the accessor', (tester) async {
      final (:chart, :dataset, data: _) = _accessorChart();
      dataset.remove('data');
      for (var k = 0; k < 2; k++) {
        chart.update();
        // A11: `_dataCheck` writes a new empty array into a plain `data`.
        expect(jsObjectKeys(dataset), [
          'label',
          'borderWidth',
          'pointRadius',
          '_data',
          '_decimated',
          'data',
        ]);
        expect(dataset['data'], isEmpty);
        expect(_length(dataset['_decimated']), 386);
        expect(_metaCount(chart), 0);
      }
    });

    testWidgets('a user _data key without the accessor', (tester) async {
      final own = _series(200, (i) => i % 9);
      final (:chart, :dataset, :data) = _accessorChart(
        dataset: {'_data': own},
      );
      // A12: `_data` is set, so plugin.decimation.js:249 sees no first time
      // and `data` stays the plain raw data.
      expect(jsObjectKeys(dataset), [
        'label',
        'borderWidth',
        'data',
        'pointRadius',
        '_data',
        '_decimated',
      ]);
      expect(dataset['data'], same(data));
      expect(_length(dataset['_decimated']), 200);
      expect((dataset['_decimated']! as List<Object?>)[1], {'x': 1, 'y': 1});
      expect(_metaCount(chart), 2000);
    });

    testWidgets('lttb on the same data', (tester) async {
      final (:chart, :dataset, data: _) = _accessorChart(
        decimation: {'algorithm': 'lttb'},
      );
      // A13.
      expect(_length(dataset['data']), 50);
      expect(_metaCount(chart), 50);
      expect((dataset['data']! as List<Object?>)[1], {'x': 8, 'y': 94});
    });

    testWidgets('destroy does not clean: no code notifies the hook', (
      tester,
    ) async {
      final (:chart, :dataset, :data) = _accessorChart();
      chart.destroy();
      // A14: Chart.destroy notifies beforeDestroy and afterDestroy, not
      // destroy (core.controller.js), so the keys stay.
      expect(jsObjectKeys(dataset), _decimatedKeys);
      expect(dataset['data'], isNot(same(data)));
    });

    testWidgets('a theme leaves data, _data and _decimated unchanged', (
      tester,
    ) async {
      final (chart: _, :dataset, :data) = _accessorChart(
        theme: compileChartTheme(ChartThemes.light),
      );
      expect(jsObjectKeys(dataset), _decimatedKeys);
      expect(_length(dataset['data']), 386);
      expect(dataset['data'], same(dataset['_decimated']));
      expect(dataset['_data'], same(data));
    });
  });

  // differences.md row js-semantics-narrow-datasets: the plugin writes
  // `_data`, `data` and `_decimated` into the dataset Map of the user
  // (plugin.decimation.js:156-168, 253-264, 280). Upstream sets the
  // properties of any dataset object.
  group('js-semantics-narrow-datasets', () {
    /// A line chart with the dataset [dataset] and the decimation on when
    /// [enabled] is true.
    Chart narrowChart(Object dataset, {bool enabled = true}) => acquireChart(
      <String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[dataset],
        },
        'options': <String, Object?>{
          'parsing': false,
          'scales': <String, Object?>{
            'x': <String, Object?>{'type': 'linear'},
          },
          'plugins': <String, Object?>{
            'decimation': <String, Object?>{
              'enabled': enabled,
              'algorithm': 'lttb',
              'samples': 10,
              'threshold': 20,
            },
          },
        },
      },
    );

    /// 40 items `{x: i, y: i % 7}` with the narrow type `Map<String, int>`.
    List<Map<String, int>> narrowData() => [
      for (var i = 0; i < 40; i++) {'x': i, 'y': i % 7},
    ];

    testWidgets('a narrow dataset Map works when the plugin is off', (
      tester,
    ) async {
      final chart = narrowChart(<String, List<Map<String, int>>>{
        'data': narrowData(),
      }, enabled: false);
      expect(_metaCount(chart), 40);
    });

    testWidgets('a Map<String, List<Map<String, int>>> dataset throws a '
        'TypeError at the write of the getter value', (tester) async {
      expect(
        () => narrowChart(<String, List<Map<String, int>>>{
          'data': narrowData(),
        }),
        throwsA(isA<TypeError>()),
      );
    });

    testWidgets('an unmodifiable dataset Map throws an UnsupportedError', (
      tester,
    ) async {
      expect(
        () => narrowChart(
          Map<String, Object?>.unmodifiable(<String, Object?>{
            'data': narrowData(),
          }),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    testWidgets('a Map<String, Object?> dataset takes the writes', (
      tester,
    ) async {
      final chart = narrowChart(<String, Object?>{'data': narrowData()});
      expect(_length(jsGet(_datasets(chart)[0], 'data')), 10);
    });
  });

  // plugin.decimation.js:231: the decimation runs only on a `linear` or a
  // `time` x scale. A probe on the pinned build in Node.js v24.12.0 on x64
  // (moment 2.29.4 and chartjs-adapter-moment 1.0.1, TZ=UTC) made the chart
  // of the group on each scale type and logged the keys of the dataset, the
  // length of `data`, whether `data` is the input array, the element count
  // and the hours of the items after 2020-01-01Z:
  // `time keys [label,_data,data,_decimated] n 8 same input false meta 8
  // hours [0,3,10,21,33,41,51,59]` and `timeseries keys [label,data] n 60
  // same input true meta 60`.
  group('x scale types', () {
    final t0 = DateTime.utc(2020).millisecondsSinceEpoch;

    /// A line chart of 60 hourly items `{x, y: (i * 37) % 23}` on the x
    /// scale [type], with `lttb`, `samples: 8` and `threshold: 10`, the
    /// other plugins off, and a canvas of 30 x 100.
    ({Chart chart, AnyObject dataset, List<Object?> input}) typeChart(
      String type,
    ) {
      final input = <Object?>[
        for (var i = 0; i < 60; i++)
          <String, Object?>{'x': t0 + i * 3600000, 'y': (i * 37) % 23},
      ];
      final ds = <String, Object?>{'label': 'd0', 'data': input};
      final chart = acquireChart(
        <String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[ds],
          },
          'options': <String, Object?>{
            'parsing': false,
            'scales': <String, Object?>{
              'x': <String, Object?>{'type': type},
            },
            'plugins': <String, Object?>{
              'colors': false,
              'filler': false,
              'legend': false,
              'subtitle': false,
              'title': false,
              'tooltip': false,
              'decimation': <String, Object?>{
                'enabled': true,
                'algorithm': 'lttb',
                'samples': 8,
                'threshold': 10,
              },
            },
          },
        },
        <String, Object?>{
          'canvas': <String, Object?>{'width': 30, 'height': 100},
        },
      );
      return (chart: chart, dataset: ds, input: input);
    }

    testWidgets('time: the decimation runs', (tester) async {
      final (:chart, :dataset, :input) = typeChart('time');
      expect(jsObjectKeys(dataset), ['label', '_data', 'data', '_decimated']);
      final data = jsGet(dataset, 'data')! as List<Object?>;
      expect(identical(data, input), isFalse);
      expect(
        [for (final p in data) ((jsGet(p, 'x')! as num) - t0) / 3600000],
        [0, 3, 10, 21, 33, 41, 51, 59],
      );
      expect(_metaCount(chart), 8);
    });

    testWidgets('timeseries: the decimation does not run', (tester) async {
      final (:chart, :dataset, :input) = typeChart('timeseries');
      expect(jsObjectKeys(dataset), ['label', 'data']);
      expect(identical(jsGet(dataset, 'data'), input), isTrue);
      expect(_metaCount(chart), 60);
    });
  });
}
