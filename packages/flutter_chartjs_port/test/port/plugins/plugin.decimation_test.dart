// Original code, not ported from Chart.js: decimation plugin tests.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/light_theme.dart';
import '../../support/parsed_items.dart';
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
// Chart.js in Node.js v24.22.1 on arm64 (Chart.js ADR 0146), with the seven
// plugins registered and `colors.enabled: false` in the defaults. Each case
// is a unit case (the other plugins are `false`, Chart.js ADR 0041, section
// 4), except the full cases (the names that start with `full:`), which have
// the default plugin options (section 4 item 2). The observation has `boxes`
// and `plugins.decimation` (the keys, the accessor state and the data of each
// dataset), and the draw calls. The cases run two times: unthemed, and with the
// light preset (theming.md section 8 test 3, Chart.js ADR 0147).
//
// The group `adapt-decimation-data-accessor` pins the accessor of
// plugin.decimation.js:249-265 on real charts (Chart.js ADR 0038, section
// 8): the keys, the arrays and the throws after each hook, and the four
// results of the differences.md row. Each chart is a typed `ChartView`
// (Chart.js ADR 0194): a change of an option pumps the next `ChartConfig`, as
// an app does. The writes of `data`, `_data`, `_decimated` and `type` into
// the dataset object are the subject of the row: the app writes its dataset
// and calls `chart.update()`. Each upstream value in a comment
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
/// The items are parsed items, the data items of `parsing: false` (row
/// `adapt-parsed-data-items`).
List<Object?> _series(int n, int Function(int i) f) => <Object?>[
  for (var i = 0; i < n; i++)
    parsedItemOf(<String, Object?>{'x': i, 'y': f(i)}),
];

/// The own keys and values of the parsed item [item], for a compare with
/// the plain object of upstream.
Map<String, Object?> _itemKeys(Object? item) {
  final parsed = item! as ParsedItem;
  return {for (final key in parsed.jsKeys()) key: parsed[key]};
}

/// The `beforeUpdate` hook `writeData` of the inline plugin `writer` of the
/// generator: when its option `write` is true, it writes 80 new items into
/// `data` of the dataset 0.
void _writeData(IChart chart, Object? args, Object? options) {
  if (jsTruthy(jsGet(options, 'write'))) {
    final datasets = jsGet(chart.data, 'datasets')! as List<Object?>;
    (datasets[0]! as AnyObject)['data'] = _series(80, (i) => (i * 11) % 19);
  }
}

/// The named functions of the configs of the generator.
final Map<String, Object?> _functions = {'writeData': _writeData};

/// [n] data points `(i, f(i))`: the data items of `parsing: false`.
List<DataPoint> _points(int n, int Function(int i) f) => [
  for (var i = 0; i < n; i++) DataPoint(i, f(i)),
];

/// The options of the decimation of the group
/// `adapt-decimation-data-accessor` (`min-max` with `samples: 50` and
/// `threshold: 100`), with the fields of [decimation] over them.
DecimationOptions _accessorDecimation(DecimationOptions decimation) =>
    const DecimationOptions(
      enabled: true,
      algorithm: MinMaxDecimationAlgorithm(),
      samples: 50,
      threshold: 100,
    ).merge(decimation);

/// The config of the group `adapt-decimation-data-accessor`: the dataset
/// `{label, data, borderWidth, pointRadius}` of [data] with [indexAxis],
/// [parsing] (`false` by default), a linear x scale, no animation, the
/// options of [_accessorDecimation] of [decimation], and the decimation
/// plugin off when [pluginOff] is true.
ChartConfig _accessorConfig(
  List<DataPoint> data, {
  DecimationOptions decimation = const DecimationOptions(),
  bool parsing = false,
  CartesianAxis? indexAxis,
  bool pluginOff = false,
}) => ChartConfig(
  datasets: [
    LineDataset(
      label: 'd',
      data: .points(data),
      borderWidth: 1,
      pointRadius: const .constant(0),
      indexAxis: indexAxis,
    ),
  ],
  scales: const [LinearAxis(.x)],
  parsing: parsing,
  maintainAspectRatio: false,
  animation: ChartAnimation.none,
  pluginOptions: [_accessorDecimation(decimation)],
  disabledPlugins: pluginOff ? const [PluginOff<DecimationPlugin>()] : null,
);

/// A typed ChartView of [config] with [theme] in a box of 100 x 100 at the
/// top left.
Widget _view(ChartConfig config, {ChartThemeData? theme}) => Directionality(
  textDirection: TextDirection.ltr,
  child: Align(
    alignment: Alignment.topLeft,
    child: SizedBox(
      width: 100,
      height: 100,
      child: ChartView(config: config, theme: theme),
    ),
  ),
);

/// The chart of the one ChartView of the tree.
Chart _chart(WidgetTester tester) {
  final host = tester.renderObject<RenderChartHost>(find.byType(ChartHost));
  return Chart.getChart(host.canvas)!;
}

/// The decimated chart of the group `adapt-decimation-data-accessor`: 2000
/// points `(i, (i * 37) % 101)` in the config of [_accessorConfig] with
/// [decimation], in a box of 100 x 100.
Future<({Chart chart, JsObjectFace dataset, List<DataPoint> data})>
_accessorChart(
  WidgetTester tester, {
  DecimationOptions decimation = const DecimationOptions(),
  ChartThemeData? theme,
}) async {
  final data = _points(2000, (i) => (i * 37) % 101);
  await tester.pumpWidget(
    _view(_accessorConfig(data, decimation: decimation), theme: theme),
  );
  final chart = _chart(tester);
  return (
    chart: chart,
    dataset: _datasets(chart)[0]! as JsObjectFace,
    data: data,
  );
}

/// Pumps the ChartView with the next config [config]: one update of the
/// chart, as an app gives a new config.
Future<void> _next(WidgetTester tester, ChartConfig config) =>
    tester.pumpWidget(_view(config));

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
      theme: compileLightTheme(),
    );
  });

  group('plugin object', () {
    test('has the keys of plugin.decimation.js:197-287', () {
      // The native plugin of Chart.js ADR 0144: the upstream keys are `id`,
      // `defaults`, `beforeElementsUpdate` and `destroy`. `destroy` is no
      // hook of the `Plugin` interface (`index.d.ts:856`), so no chart calls
      // it, and the native plugin has no field for it. The defaults of
      // :200-203 are one DecimationOptions (Chart.js ADR 0194).
      expect(pluginHookNames(decimation), ['beforeElementsUpdate']);
      expect(decimation.id, 'decimation');
      expect(
        decimation.defaults,
        const DecimationOptions(
          algorithm: MinMaxDecimationAlgorithm(),
          enabled: false,
        ),
      );
    });
  });

  group('adapt-decimation-data-accessor', () {
    testWidgets('the first decimation', (tester) async {
      final (:chart, :dataset, :data) = await _accessorChart(tester);
      // A1: the dataset scope is the dataset of the chart (plugins spec risk
      // 4).
      expect(jsObjectKeys(dataset), _decimatedKeys);
      expect(_length(dataset['data']), 386);
      expect(dataset['data'], same(dataset['_decimated']));
      expect(dataset['_data'], same(data));
      expect(_metaCount(chart), 386);
      expect(_itemKeys((dataset['data']! as List<Object?>)[1]), {
        'x': 19,
        'y': 97,
      });
    });

    testWidgets('a user write, then the next update', (tester) async {
      final (:chart, :dataset, :data) = await _accessorChart(tester);
      final decimated = dataset['data'];
      final written = _points(3000, (i) => i % 7);
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
      final (:chart, :dataset, data: _) = await _accessorChart(tester);
      final written = _points(3000, (i) => i % 7);
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
      final (:chart, :dataset, :data) = await _accessorChart(tester);
      await _next(
        tester,
        _accessorConfig(
          data,
          decimation: const DecimationOptions(threshold: 100000),
        ),
      );
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
      final (:chart, :dataset, data: _) = await _accessorChart(tester);
      dataset['foo'] = 1;
      expect(jsObjectKeys(dataset), [..._decimatedKeys, 'foo']);
      final written = _points(3, (i) => i);
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
      final (:chart, :dataset, :data) = await _accessorChart(tester);
      final written = _points(2, (i) => i + 1);
      dataset['data'] = written;
      await _next(
        tester,
        _accessorConfig(
          data,
          decimation: const DecimationOptions(enabled: false),
        ),
      );
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

    for (final (name, change, keys)
        in <
          (
            String,
            Future<void> Function(
              WidgetTester tester,
              Chart chart,
              JsObjectFace dataset,
              List<DataPoint> data,
            ),
            List<String>,
          )
        >[
          (
            'parsing: true',
            (tester, chart, dataset, data) =>
                _next(tester, _accessorConfig(data, parsing: true)),
            _decimatedKeys,
          ),
          (
            'indexAxis: YAxis()',
            (tester, chart, dataset, data) =>
                _next(tester, _accessorConfig(data, indexAxis: const YAxis())),
            [..._decimatedKeys, 'indexAxis'],
          ),
          // plugin.decimation.js:225. The new bar controller runs `_dataCheck`
          // before the hook (difference 1 of the row). Upstream: line R5 of the
          // probe review-upstream. The type of the dataset changes in place: a
          // typed config with a BarDataset makes a new dataset object.
          (
            'a controller without supportsDecimation',
            (tester, chart, dataset, data) async {
              dataset['type'] = 'bar';
              chart.update();
            },
            [..._decimatedKeys, 'type'],
          ),
        ]) {
      testWidgets('an early return after a write: $name', (tester) async {
        final (:chart, :dataset, :data) = await _accessorChart(tester);
        final decimated = dataset['data'];
        final written = _points(2, (i) => i + 1);
        dataset['data'] = written;
        await change(tester, chart, dataset, data);
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
      final (:chart, :dataset, :data) = await _accessorChart(tester);
      await _next(tester, _accessorConfig(data, pluginOff: true));
      final written = _points(2, (i) => i + 1);
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
      final (:chart, :dataset, :data) = await _accessorChart(tester);
      dataset.jsDelete('data');
      final written = _points(3000, (i) => i % 7);
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
      final (:chart, :dataset, :data) = await _accessorChart(tester);
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
      final (:chart, :dataset, :data) = await _accessorChart(tester);
      final empty = <Object?>[];
      dataset['_decimated'] = empty;
      await _next(tester, _accessorConfig(data, parsing: true));
      // F3b: the sync gives the getter value, and `_data` stays.
      expect(jsObjectKeys(dataset), _decimatedKeys);
      expect(dataset['data'], same(empty));
      expect(dataset['_data'], same(data));
      expect(_metaCount(chart), 0);
    });

    testWidgets('a delete of _decimated, then the update', (tester) async {
      final (:chart, :dataset, :data) = await _accessorChart(tester);
      final decimated = dataset['data'];
      dataset.jsDelete('_decimated');
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
      final (:chart, :dataset, :data) = await _accessorChart(tester);
      dataset.jsDelete('_decimated');
      await _next(
        tester,
        _accessorConfig(
          data,
          decimation: const DecimationOptions(enabled: false),
        ),
      );
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

    testWidgets('an algorithm of a program decimates the data', (tester) async {
      // The option holds a subclass of a program, with no registration: the
      // plugin calls its `decimate`.
      final (:chart, :dataset, :data) = await _accessorChart(
        tester,
        decimation: const DecimationOptions(enabled: false),
      );
      await _next(
        tester,
        _accessorConfig(
          data,
          decimation: const DecimationOptions(algorithm: _EveryNth(100)),
        ),
      );
      expect(_length(dataset['data']), 20);
      expect(_metaCount(chart), 20);
    });

    testWidgets('a delete of data removes the accessor', (tester) async {
      final (:chart, :dataset, data: _) = await _accessorChart(tester);
      dataset.jsDelete('data');
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
      // The chart starts with the plugin off, and the app writes `_data`
      // into the dataset before the plugin runs.
      final (:chart, :dataset, :data) = await _accessorChart(
        tester,
        decimation: const DecimationOptions(enabled: false),
      );
      final own = _points(200, (i) => i % 9);
      dataset['_data'] = own;
      await _next(tester, _accessorConfig(data));
      // A12: `_data` is set, so plugin.decimation.js:249 sees no first time
      // and `data` stays the plain raw data. The keys are in the order of
      // the typed dataset, `{label, data, borderWidth, pointRadius}`.
      expect(jsObjectKeys(dataset), [
        'label',
        'data',
        'borderWidth',
        'pointRadius',
        '_data',
        '_decimated',
      ]);
      expect(dataset['data'], same(data));
      expect(_length(dataset['_decimated']), 200);
      expect(_itemKeys((dataset['_decimated']! as List<Object?>)[1]), {
        'x': 1,
        'y': 1,
      });
      expect(_metaCount(chart), 2000);
    });

    testWidgets('lttb on the same data', (tester) async {
      final (:chart, :dataset, data: _) = await _accessorChart(
        tester,
        decimation: const DecimationOptions(
          algorithm: LttbDecimationAlgorithm(),
        ),
      );
      // A13.
      expect(_length(dataset['data']), 50);
      expect(_metaCount(chart), 50);
      expect(_itemKeys((dataset['data']! as List<Object?>)[1]), {
        'x': 8,
        'y': 94,
      });
    });

    testWidgets('destroy does not clean: no code notifies the hook', (
      tester,
    ) async {
      final (:chart, :dataset, :data) = await _accessorChart(tester);
      chart.destroy();
      // A14: Chart.destroy notifies beforeDestroy and afterDestroy, not
      // destroy (core.controller.js), so the keys stay.
      expect(jsObjectKeys(dataset), _decimatedKeys);
      expect(dataset['data'], isNot(same(data)));
    });

    testWidgets('a theme leaves data, _data and _decimated unchanged', (
      tester,
    ) async {
      final (chart: _, :dataset, :data) = await _accessorChart(
        tester,
        theme: const ChartThemeData.light(),
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
  // properties of any dataset object. The subject is a dataset Map of a raw
  // config: the typed config of the chart gets it in place of its typed
  // dataset, the one raw part of the group.
  group('js-semantics-narrow-datasets', () {
    /// A line chart with the dataset [dataset] and the decimation on when
    /// [enabled] is true.
    Chart narrowChart(Object dataset, {bool enabled = true}) {
      final root = ChartConfigLowering(
        ChartConfig(
          datasets: const [LineDataset()],
          scales: const [LinearAxis(.x)],
          parsing: false,
          pluginOptions: [
            DecimationOptions(
              enabled: enabled,
              algorithm: const LttbDecimationAlgorithm(),
              samples: 10,
              threshold: 20,
            ),
          ],
        ),
      ).lower();
      // Preserve the dataset's Map type and mutability for the write guards.
      (root.dataCell!.raw! as ChartDataScope).datasets = <Object?>[dataset];
      return acquireChartRoot(root);
    }

    /// 40 parsed items `{x: i, y: i % 7}` in a List of the narrow type
    /// `List<ParsedItem>`.
    List<ParsedItem> narrowData() => _points(40, (i) => i % 7);

    testWidgets('a narrow dataset Map works when the plugin is off', (
      tester,
    ) async {
      final chart = narrowChart({'data': narrowData()}, enabled: false);
      expect(_metaCount(chart), 40);
    });

    testWidgets('a Map<String, List<ParsedItem>> dataset throws a '
        'TypeError at the write of the getter value', (tester) async {
      expect(
        () => narrowChart(<String, List<ParsedItem>>{'data': narrowData()}),
        throwsA(isA<TypeError>()),
      );
    });

    testWidgets('an unmodifiable dataset Map throws an UnsupportedError', (
      tester,
    ) async {
      expect(
        () => narrowChart(
          Map<String, Object?>.unmodifiable({'data': narrowData()}),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    testWidgets('a Map<String, Object?> dataset takes the writes', (
      tester,
    ) async {
      final chart = narrowChart(
        Map<String, Object?>.of({'data': narrowData()}),
      );
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

    /// A line chart of 60 hourly points `(x, (i * 37) % 23)` on the x scale
    /// [type], with `lttb`, `samples: 8` and `threshold: 10`, the other
    /// plugins off, and a canvas of 30 x 100.
    ({Chart chart, JsObjectFace dataset, List<DataPoint> input}) typeChart(
      String type,
    ) {
      final input = [
        for (var i = 0; i < 60; i++) DataPoint(t0 + i * 3600000, (i * 37) % 23),
      ];
      final chart = acquireChartRoot(
        ChartConfigLowering(
          ChartConfig(
            datasets: [LineDataset(label: 'd0', data: .points(input))],
            scales: [
              if (type == 'time')
                const TimeAxis(.x)
              else
                const TimeSeriesAxis(.x),
            ],
            parsing: false,
            disabledPlugins: const [
              PluginOff<ColorsPlugin>(),
              PluginOff<FillerPlugin>(),
              PluginOff<LegendPlugin>(),
              PluginOff<SubtitlePlugin>(),
              PluginOff<TitlePlugin>(),
              PluginOff<TooltipPlugin>(),
            ],
            pluginOptions: const [
              DecimationOptions(
                enabled: true,
                algorithm: LttbDecimationAlgorithm(),
                samples: 8,
                threshold: 10,
              ),
            ],
          ),
        ).lower(),
        _canvas(30, 100),
      );
      return (
        chart: chart,
        dataset: _datasets(chart)[0]! as JsObjectFace,
        input: input,
      );
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

/// The acquireChart options of a canvas of [width] x [height] (the second
/// argument of `acquireChart`, not a chart config).
AnyObject _canvas(int width, int height) => <String, Object?>{
  'canvas': <String, Object?>{'width': width, 'height': height},
};

/// An algorithm of a program: each [n]-th item.
final class const _EveryNth(final int n) extends DecimationAlgorithm {
  @override
  List<ParsedItem?> decimate(
    List<ParsedItem?> data,
    int start,
    int count,
    double availableWidth,
    Object options,
  ) => [for (var i = start; i < start + count; i += n) data[i]];
}
