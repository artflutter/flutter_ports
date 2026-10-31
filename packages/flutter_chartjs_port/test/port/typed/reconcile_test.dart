// Original code, not ported from Chart.js: tests of the typed reconcile.
@TestOn('vm')
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_chartjs_port/src/platform/chart_host.dart';
import 'package:flutter_test/flutter_test.dart';

// Chart.js ADR 0052, sections 3 and 9: a new typed config that is not `==`
// to the last one reconciles with the live Maps of the chart. A dataset
// takes the live Map of the last dataset with the same key and class, or,
// without a key, the Map at its index of the same class. The patch writes
// the keys of the lowering and removes the keys that the last lowering
// wrote and the new one does not write; the keys of the plugins stay. The
// `data` Map stays when its Maps and its labels stay, the `options` Map
// when the type and the option fields are `==`. Probes J2a and J2b of the
// design panel are the first two cases.
//
// flutter_test_config.dart registers the built-in components with the seven
// plugins and sets `defaults.plugins.colors.enabled = false`. The palette
// cases turn the colors plugin on through `extra`.

const ValueKey<String> _a = ValueKey('a');
const ValueKey<String> _b = ValueKey('b');
const ValueKey<String> _c = ValueKey('c');

const Color _red = Color(0xFFFF0000);
const Color _green = Color(0xFF008000);
const Color _blue = Color(0xFF0000FF);

/// The three labels of the bar charts.
final List<Object> _labels = ['x', 'y', 'z'];

/// The option `plugins.colors.enabled: true`, through `extra`.
const Map<String, Object?> _colorsOn = {
  'plugins': {
    'colors': {'enabled': true},
  },
};

/// A bar chart of [datasets] with no animation unless [animated], a fixed y
/// axis from 0 to 50, and the labels `x` to `z`.
ChartConfig _bars(
  List<Dataset> datasets, {
  bool animated = false,
  ChartTitle? title,
  Map<String, Object?>? extra,
}) => ChartConfig(
  type: ChartKind.bar,
  labels: _labels,
  datasets: datasets,
  scales: const {'y': LinearAxis(min: 0, max: 50)},
  title: title,
  animation: animated ? null : ChartAnimation.none,
  extra: extra,
);

/// [child] at the top left of a box of 400 x 300.
Widget _box(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: Align(
    alignment: Alignment.topLeft,
    child: SizedBox(width: 400, height: 300, child: child),
  ),
);

/// A typed ChartView of [config] with [theme] in [_box].
Widget _view(ChartConfig config, {ChartThemeData? theme}) =>
    _box(ChartView(config: config, theme: theme));

/// The chart of the one ChartView of the tree.
Chart _chart(WidgetTester tester) {
  final host = tester.renderObject<RenderChartHost>(find.byType(ChartHost));
  return Chart.getChart(host.canvas)!;
}

/// The dataset Maps of [chart].
List<Object?> _datasets(Chart chart) =>
    _byName(chart.data, 'datasets')! as List;

/// The dataset Map [i] of [chart].
JsObjectFace _dataset(Chart chart, int i) =>
    _datasets(chart)[i]! as JsObjectFace;

/// The labels of the dataset Maps of [chart].
List<Object?> _labelsOf(Chart chart) => [
  for (final dataset in _datasets(chart)) _byName(dataset, 'label'),
];

/// A registered plugin whose `beforeUpdate` records the mode of each update
/// and calls [onBeforeUpdate]. It unregisters at the end of the test.
List<Object?> _spyOnUpdates([void Function(Chart chart)? onBeforeUpdate]) {
  final modes = <Object?>[];
  final plugin = <String, Object?>{
    'id': r'$updateSpy',
    'beforeUpdate': (Chart chart, JsObjectFace args, Object? options) {
      modes.add(args['mode']);
      onBeforeUpdate?.call(chart);
    },
  };
  Chart.register([plugin]);
  addTearDown(() => Chart.unregister([plugin]));
  return modes;
}

/// The `rgba()` string of [color].
String _rgba(Color color) {
  int channel(double v) => (v * 255).round();
  return 'rgba(${channel(color.r)}, ${channel(color.g)}, '
      '${channel(color.b)}, 1)';
}

/// A host whose state sets the config and the theme of its ChartView in one
/// `setState`.
class _Host extends StatefulWidget {
  const _Host({required this.config, this.theme});

  final ChartConfig config;
  final ChartThemeData? theme;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late ChartConfig config = widget.config;
  late ChartThemeData? theme = widget.theme;

  void show(ChartConfig nextConfig, ChartThemeData? nextTheme) => setState(() {
    config = nextConfig;
    theme = nextTheme;
  });

  @override
  Widget build(BuildContext context) => _view(config, theme: theme);
}

void main() {
  group('the match rule', () {
    testWidgets('J2b: a key keeps the Map, the meta and the hidden state of '
        'a dataset after a removal at index 0', (tester) async {
      const a = BarDataset(key: _a, label: 'A', data: [1, 2, 3]);
      const b = BarDataset(key: _b, label: 'B', data: [4, 5, 6]);
      const c = BarDataset(key: _c, label: 'C', data: [7, 8, 9]);
      await tester.pumpWidget(_view(_bars([a, b, c])));
      final chart = _chart(tester)..hide(1);
      final mapB = _dataset(chart, 1);
      final mapC = _dataset(chart, 2);
      final metaB = chart.getDatasetMeta(1);
      final metaC = chart.getDatasetMeta(2);
      expect(chart.isDatasetVisible(1), isFalse);

      await tester.pumpWidget(_view(_bars([b, c])));
      expect(_labelsOf(chart), ['B', 'C']);
      expect(_dataset(chart, 0), same(mapB));
      expect(_dataset(chart, 1), same(mapC));
      expect(chart.getDatasetMeta(0), same(metaB));
      expect(chart.getDatasetMeta(1), same(metaC));
      expect(chart.isDatasetVisible(0), isFalse);
      expect(chart.isDatasetVisible(1), isTrue);
    });

    testWidgets('J2a: without keys, the index rule gives the hidden state of '
        'B to the dataset C', (tester) async {
      const a = BarDataset(label: 'A', data: [1, 2, 3]);
      const b = BarDataset(label: 'B', data: [4, 5, 6]);
      const c = BarDataset(label: 'C', data: [7, 8, 9]);
      await tester.pumpWidget(_view(_bars([a, b, c])));
      final chart = _chart(tester)..hide(1);
      final mapA = _dataset(chart, 0);
      final mapB = _dataset(chart, 1);

      await tester.pumpWidget(_view(_bars([b, c])));
      expect(_labelsOf(chart), ['B', 'C']);
      // The Maps at the indexes 0 and 1 stay, with new values.
      expect(_dataset(chart, 0), same(mapA));
      expect(_dataset(chart, 1), same(mapB));
      expect(chart.isDatasetVisible(0), isTrue);
      expect(chart.isDatasetVisible(1), isFalse);
    });

    testWidgets('a class change at an index gives a new Map and a new meta', (
      tester,
    ) async {
      await tester.pumpWidget(
        _view(
          _bars([
            const BarDataset(data: [1, 2, 3]),
          ]),
        ),
      );
      final chart = _chart(tester);
      final map = _dataset(chart, 0);
      final meta = chart.getDatasetMeta(0);
      expect(meta.type, 'bar');

      await tester.pumpWidget(
        _view(
          _bars([
            const LineDataset(data: [1, 2, 3]),
          ]),
        ),
      );
      expect(_dataset(chart, 0), isNot(same(map)));
      expect(_dataset(chart, 0)['type'], 'line');
      expect(chart.getDatasetMeta(0), isNot(same(meta)));
      expect(chart.getDatasetMeta(0).type, 'line');
    });

    testWidgets('a new key, and a key against no key, give a new Map', (
      tester,
    ) async {
      final data = [1, 2, 3];
      await tester.pumpWidget(
        _view(_bars([BarDataset(key: _a, data: data)])),
      );
      final chart = _chart(tester);
      final first = _dataset(chart, 0);
      await tester.pumpWidget(
        _view(_bars([BarDataset(key: _b, data: data)])),
      );
      final second = _dataset(chart, 0);
      expect(second, isNot(same(first)));
      await tester.pumpWidget(_view(_bars([BarDataset(data: data)])));
      expect(_dataset(chart, 0), isNot(same(second)));
    });

    testWidgets('an append keeps the Maps and adds a new Map; a removal of '
        'the last dataset keeps the others', (tester) async {
      const a = BarDataset(label: 'A', data: [1, 2, 3]);
      const b = BarDataset(label: 'B', data: [4, 5, 6]);
      await tester.pumpWidget(_view(_bars([a])));
      final chart = _chart(tester);
      final mapA = _dataset(chart, 0);
      final metaA = chart.getDatasetMeta(0);

      await tester.pumpWidget(_view(_bars([a, b])));
      expect(_labelsOf(chart), ['A', 'B']);
      expect(_dataset(chart, 0), same(mapA));
      expect(chart.getDatasetMeta(0), same(metaA));
      expect(chart.getDatasetMeta(1).data, hasLength(3));

      await tester.pumpWidget(_view(_bars([a])));
      expect(_labelsOf(chart), ['A']);
      expect(_dataset(chart, 0), same(mapA));
      expect(chart.getDatasetMeta(0), same(metaA));
    });

    testWidgets('a keyed reorder moves the Maps and the metas', (tester) async {
      const a = BarDataset(key: _a, label: 'A', data: [1, 2, 3]);
      const b = BarDataset(key: _b, label: 'B', data: [4, 5, 6]);
      await tester.pumpWidget(_view(_bars([a, b])));
      final chart = _chart(tester)..hide(0);
      final mapA = _dataset(chart, 0);
      final mapB = _dataset(chart, 1);
      final metaA = chart.getDatasetMeta(0);

      await tester.pumpWidget(_view(_bars([b, a])));
      expect(_labelsOf(chart), ['B', 'A']);
      expect(_dataset(chart, 0), same(mapB));
      expect(_dataset(chart, 1), same(mapA));
      expect(chart.getDatasetMeta(1), same(metaA));
      expect(chart.isDatasetVisible(0), isTrue);
      expect(chart.isDatasetVisible(1), isFalse);
    });

    testWidgets('two datasets with one key fail the debug assert at the '
        'start and at an update', (tester) async {
      await tester.pumpWidget(
        _view(
          _bars([
            const BarDataset(key: _a, data: [1]),
            const BarDataset(key: _a, data: [2]),
          ]),
        ),
      );
      expect(
        '${tester.takeException()}',
        contains('Two datasets of the ChartConfig have the key'),
      );
      expect(tester.any(find.byType(ChartHost)), isTrue);

      // The next config starts the chart.
      await tester.pumpWidget(
        _view(
          _bars([
            const BarDataset(key: _a, data: [1]),
          ]),
        ),
      );
      expect(tester.takeException(), isNull);
      final chart = _chart(tester);
      await tester.pumpWidget(
        _view(
          _bars([
            const BarDataset(key: _b, data: [1]),
            const BarDataset(key: _b, data: [2]),
          ]),
        ),
      );
      expect(
        '${tester.takeException()}',
        contains('Two datasets of the ChartConfig have the key'),
      );
      expect(_datasets(chart), hasLength(1));
    });
  });

  group('the patch', () {
    testWidgets('a removed typed key leaves the Map, a changed key gets the '
        'new value, and an equal dataset keeps its Map as it is', (
      tester,
    ) async {
      final data = [1, 2, 3];
      await tester.pumpWidget(
        _view(
          _bars([
            BarDataset(label: 'A', borderWidth: 1, data: data),
            BarDataset(label: 'B', data: data),
          ]),
        ),
      );
      final chart = _chart(tester);
      final map = _dataset(chart, 0);
      final other = _dataset(chart, 1);
      // An app edit of the live Maps: a key that the lowering did not write.
      map['clip'] = 4;
      other['clip'] = 5;

      await tester.pumpWidget(
        _view(
          _bars([
            BarDataset(borderWidth: 2, data: data),
            BarDataset(label: 'B', data: data),
          ]),
        ),
      );
      expect(_dataset(chart, 0), same(map));
      expect(map.jsHas('label'), isFalse);
      expect(map['borderWidth'], 2);
      expect(map['clip'], 4);
      expect(map['data'], same(data));
      expect(
        (chart.getDatasetMeta(0).data.first.options!
            as JsObjectFace)['borderWidth'],
        2,
      );
      expect(_dataset(chart, 1), same(other));
      expect(
        {for (final key in other.jsKeys()) key: other[key]},
        {
          'label': 'B',
          'data': data,
          'clip': 5,
        },
      );
    });

    testWidgets('a key that the colors plugin wrote stays in the Map', (
      tester,
    ) async {
      final atUpdate = <Object?>[];
      _spyOnUpdates((chart) => atUpdate.add(_dataset(chart, 0)['borderColor']));
      final data = [1, 2, 3];
      await tester.pumpWidget(
        _view(
          _bars([BarDataset(label: 'A', data: data)], extra: _colorsOn),
        ),
      );
      final chart = _chart(tester);
      final written = _dataset(chart, 0)['borderColor'];
      expect(written, 'rgb(54, 162, 235)');

      await tester.pumpWidget(
        _view(
          _bars([BarDataset(label: 'B', data: data)], extra: _colorsOn),
        ),
      );
      expect(_dataset(chart, 0)['label'], 'B');
      // The reconcile kept the key: `beforeUpdate` runs before the colors
      // plugin writes again (`beforeLayout`). The key is absent at the first
      // update: the face reads `undefined` (Chart.js ADR 0054 §5).
      expect(atUpdate, [undefined, written]);
      expect(_dataset(chart, 0)['borderColor'], written);
    });

    testWidgets('a kept meta animates from the old value, a new Map from '
        'the base (probe t-c P5)', (tester) async {
      await tester.pumpWidget(
        _view(
          _bars([
            const BarDataset(key: _a, data: [10, 20, 30]),
          ], animated: true),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      final chart = _chart(tester);
      final yOld = chart.getDatasetMeta(0).data[1].y;
      final yBase = chart.scales['y']!.bottom;

      await tester.pumpWidget(
        _view(
          _bars([
            const BarDataset(key: _a, data: [10, 40, 30]),
          ], animated: true),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final yNew = chart.scales['y']!.getPixelForValue(40);
      expect(
        chart.getDatasetMeta(0).data[1].y,
        inExclusiveRange(yNew, yOld),
      );
      await tester.pump(const Duration(seconds: 2));
      expect(chart.getDatasetMeta(0).data[1].y, closeTo(yNew, 1e-9));

      // A new key: a new Map, a new meta, the bar grows from the base.
      await tester.pumpWidget(
        _view(
          _bars([
            const BarDataset(key: _b, data: [10, 20, 30]),
          ], animated: true),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        chart.getDatasetMeta(0).data[1].y,
        inExclusiveRange(yOld, yBase),
      );
      await tester.pump(const Duration(seconds: 2));
    });
  });

  group('the data and the options Maps', () {
    testWidgets('the options Map stays for a data change, with an imperative '
        'edit; an option change gives a new options Map', (tester) async {
      const title = ChartTitle(display: true, text: 'T');
      await tester.pumpWidget(
        _view(
          _bars([
            const BarDataset(data: [1, 2, 3]),
          ], title: title),
        ),
      );
      final chart = _chart(tester);
      final options = chart.config.options;
      chart.options['indexAxis'] = 'y';
      chart.update();

      await tester.pumpWidget(
        _view(
          _bars([
            const BarDataset(data: [4, 5, 6]),
          ], title: title),
        ),
      );
      expect(chart.config.options, same(options));
      expect(chart.options['indexAxis'], 'y');
      expect(chart.getDatasetMeta(0).indexAxis, 'y');

      await tester.pumpWidget(
        _view(
          _bars([
            const BarDataset(data: [4, 5, 6]),
          ], title: const ChartTitle(display: true, text: 'U')),
        ),
      );
      expect(chart.config.options, isNot(same(options)));
      expect(chart.options['indexAxis'], 'x');
      expect(chart.titleBlock, isNotNull);
    });

    testWidgets('the data Map stays for an option change and goes for a new '
        'dataset List or new labels', (tester) async {
      final datasets = [
        const BarDataset(data: [1, 2, 3]),
      ];
      await tester.pumpWidget(_view(_bars(datasets)));
      final chart = _chart(tester);
      final data = chart.data;

      await tester.pumpWidget(
        _view(_bars(datasets, title: const ChartTitle(text: 'T'))),
      );
      expect(chart.data, same(data));

      // New data in the dataset: the same dataset Map, the same data Map.
      await tester.pumpWidget(
        _view(
          _bars([
            const BarDataset(data: [4, 5, 6]),
          ]),
        ),
      );
      expect(chart.data, same(data));

      await tester.pumpWidget(
        _view(
          _bars([
            const BarDataset(data: [4, 5, 6]),
            const BarDataset(data: [7, 8, 9]),
          ]),
        ),
      );
      expect(chart.data, isNot(same(data)));
      expect(_datasets(chart), hasLength(2));

      final labels = <Object>['p', 'q', 'r'];
      final before = chart.data;
      await tester.pumpWidget(
        _view(
          ChartConfig(
            type: ChartKind.bar,
            labels: labels,
            datasets: const [
              BarDataset(data: [4, 5, 6]),
              BarDataset(data: [7, 8, 9]),
            ],
            scales: const {'y': LinearAxis(min: 0, max: 50)},
            animation: ChartAnimation.none,
          ),
        ),
      );
      expect(chart.data, isNot(same(before)));
      expect(_byName(chart.data, 'labels'), same(labels));
    });

    testWidgets('a new type gives a new options Map: the axes of the new '
        'type, as a new chart', (tester) async {
      final datasets = [
        const LineDataset(data: [1, 2, 3]),
      ];
      // The x axis of the app takes the scale defaults of the chart type:
      // `offset: true` of the bar overrides (`core.config.js:89`).
      ChartConfig config(ChartKind type) => ChartConfig(
        type: type,
        labels: _labels,
        datasets: datasets,
        scales: const {'x': CategoryAxis()},
        animation: ChartAnimation.none,
      );
      await tester.pumpWidget(_view(config(ChartKind.bar)));
      final chart = _chart(tester);
      final map = _dataset(chart, 0);
      expect(map['type'], 'line');
      expect(chart.scales['x']!.options['offset'], isTrue);

      await tester.pumpWidget(_view(config(ChartKind.line)));
      expect(_dataset(chart, 0), same(map));
      expect(map.jsHas('type'), isFalse);
      expect(chart.config.type, 'line');
      expect(chart.scales['x']!.options['offset'], isFalse);
    });
  });

  group('the theme switch', () {
    testWidgets('a theme change and a data change in one frame give one '
        'update with the theme mode and keep the dataset Map', (tester) async {
      final modes = _spyOnUpdates();
      const themeA = ChartThemeData(palette: [_green]);
      const themeB = ChartThemeData(palette: [_blue]);
      ChartConfig config(List<num?> data, {Color? borderColor}) => _bars(
        [BarDataset(data: data, borderColor: borderColor)],
        extra: _colorsOn,
      );
      await tester.pumpWidget(_Host(config: config([1, 2, 3]), theme: themeA));
      final host = tester.state<_HostState>(find.byType(_Host));
      final chart = _chart(tester);
      final map = _dataset(chart, 0);
      expect(map['borderColor'], _rgba(_green));
      expect(modes, [undefined]);

      final data = [4, 5, 6];
      host.show(config(data), themeB);
      await tester.pump();
      expect(modes, [undefined, 'theme']);
      expect(_dataset(chart, 0), same(map));
      expect(map['data'], same(data));
      expect(map['borderColor'], _rgba(_blue));

      // A typed color in the frame of a switch wins over the palette: the
      // switch restores only a value that the colors plugin wrote.
      host.show(config(data, borderColor: _red), themeA);
      await tester.pump();
      expect(modes, [undefined, 'theme', 'theme']);
      expect(map['borderColor'], _rgba(_red));
    });
  });

  group('the decimation plugin', () {
    testWidgets('a new data List goes to _data, and a change of another key '
        'keeps the decimated data', (tester) async {
      final input = [
        for (var i = 0; i < 5000; i++) DataPoint(i, (i * 37) % 101),
      ];
      ChartConfig config(List<DataPoint> points, String label) => ChartConfig(
        type: ChartKind.line,
        datasets: [
          LineDataset(label: label, points: points, pointRadius: 0),
        ],
        scales: const {'x': LinearAxis()},
        animation: ChartAnimation.none,
        extra: const {
          'parsing': false,
          'plugins': {
            'decimation': {'enabled': true, 'algorithm': 'lttb', 'samples': 50},
          },
        },
      );
      await tester.pumpWidget(_view(config(input, 'a')));
      final chart = _chart(tester);
      final map = _dataset(chart, 0);
      final meta = chart.getDatasetMeta(0);
      expect(map['_data'], same(input));
      expect(map['data'], hasLength(50));
      expect(meta.data, hasLength(50));

      await tester.pumpWidget(_view(config(input, 'b')));
      expect(_dataset(chart, 0), same(map));
      expect(map['label'], 'b');
      expect(map['_data'], same(input));
      expect(map['data'], hasLength(50));
      expect(chart.getDatasetMeta(0), same(meta));

      final next = input.sublist(0, 4000);
      await tester.pumpWidget(_view(config(next, 'b')));
      expect(map['_data'], same(next));
      expect(map['data'], hasLength(50));
      expect((map['data']! as List).last, same(next.last));
      expect(chart.getDatasetMeta(0), same(meta));
    });
  });
}

/// The read by name `object[key]` of an object of a chart: a Map of a raw
/// config, or a typed object through its face (Chart.js ADR 0054 §5).
Object? _byName(Object? object, String key) => switch (object) {
  final Map<Object?, Object?> map => map[key],
  final JsObjectFace face => face[key],
  _ => null,
};
