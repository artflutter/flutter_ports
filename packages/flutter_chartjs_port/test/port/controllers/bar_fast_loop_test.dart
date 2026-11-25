// Original code, not ported from Chart.js: fast bar loop twins (ADR 0152).
@TestOn('vm')
library;

import 'dart:collection';
import 'dart:ui' as ui;

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter/widgets.dart' show ValueKey;
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/context_keys.dart';
import '../../support/parsed_items.dart';

// Each case builds two charts from equal configs. Chart `a` is a `Chart`: it
// takes the fast loop where the guards allow it. Chart `b` never takes
// the fast loop: it is the ordinary loop of upstream for each bar. The case
// compares the properties, the options and the contexts of each bar, and it
// reads the counters of the fast loop to show which loop ran.

class _ReferenceChart(super.item, super.userConfig) extends Chart {
  @override
  bool get supportsNativeBarIndexReads => true;
  @override
  bool get supportsBulkBarUpdate => false;
}

/// The upstream reads for each bar and each stack item: no native read
/// proof, no fast loop, no search plan and no hoist in `updateStacks`.
class _UpstreamChart(super.item, super.userConfig) extends Chart {
  @override
  bool get supportsNativeBarIndexReads => false;
  @override
  bool get supportsBulkBarUpdate => false;
}

/// A platform that keeps the option `animation`: `BasicPlatform`, the
/// platform of a chart with no host, writes `animation: false`.
final class _AnimatedPlatform() extends BasicPlatform {
  @override
  void updateConfig(ChartConfiguration config) {}
}

class _CountingMap(final Map<String, Object?> fields)
    extends MapBase<String, Object?> {
  int reads = 0;
  @override
  Object? operator [](Object? key) {
    reads++;
    return fields[key];
  }

  @override
  void operator []=(String key, Object? value) => fields[key] = value;
  @override
  Iterable<String> get keys => fields.keys;
  @override
  void clear() => fields.clear();
  @override
  Object? remove(Object? key) => fields.remove(key);
}

const _colors = <ui.Color>[
  ui.Color(0xff3366aa),
  ui.Color(0xffaa6633),
  ui.Color(0xff33aa66),
  ui.Color(0xff9933aa),
];

// Dataset Maps remain replaceable by the counting Maps used by the guards.
ChartConfigurationScope _config({
  int datasets = 1,
  bool horizontal = false,
  bool visible = true,
  Object? animation = false,
  bool hasAnimation = true,
  Map<String, Object?> Function(int k)? extra,
  Map<String, Object?> indexScale = const {},
  Map<String, Object?> valueScale = const {},
  Map<String, Object?> scales = const {},
}) => (ChartConfigurationScope()
  ..type = 'bar'
  ..data = (ChartDataScope()
    ..labels = <String>['a', 'b', 'c', 'd', 'e', 'f']
    ..datasets = <Object?>[
      for (var k = 0; k < datasets; k++)
        <String, Object?>{
          'data': <Object?>[1.0 + k, 0.0, -0.0, -2.0 - k, 3.0, 4.0 + k],
          'backgroundColor': ChartPaint.solid(_colors[k % 4]),
          'borderWidth': 1.0,
          ...?extra?.call(k),
        },
    ])
  ..options = scopeFromMap(ChartOptionsScope(), {
    'responsive': false,
    if (hasAnimation) 'animation': animation,
    'indexAxis': horizontal ? const YAxis() : const XAxis(),
    'plugins': <String, Object?>{'legend': false, 'tooltip': false},
    'scales': <String, Object?>{
      'x': <String, Object?>{
        'type': horizontal ? 'linear' : 'category',
        'display': visible ? ScaleDisplay.on : ScaleDisplay.off,
        if (horizontal) ...{'min': -8.0, 'max': 12.0},
        ...(horizontal ? valueScale : indexScale),
      },
      'y': <String, Object?>{
        'type': horizontal ? 'category' : 'linear',
        'display': visible ? ScaleDisplay.on : ScaleDisplay.off,
        if (!horizontal) ...{'min': -8.0, 'max': 12.0},
        ...(horizontal ? indexScale : valueScale),
      },
      ...scales,
    },
  }));

List<Object?> _datasets(ChartConfigurationScope cfg) =>
    jsGet(cfg['data'], 'datasets')! as List<Object?>;

Chart _chart(Object cfg, {bool reference = false, bool upstream = false}) {
  final canvas = UiCanvasElement(width: 640, height: 400);
  final chart = upstream
      ? _UpstreamChart(canvas, withParsedDataItems(cfg))
      : reference
      ? _ReferenceChart(canvas, withParsedDataItems(cfg))
      : Chart(canvas, withParsedDataItems(cfg));
  addTearDown(chart.destroy);
  return chart;
}

Object? _plain(Object? value) {
  if (value is double) {
    if (!value.isFinite) return value.toString();
    if (value == 0 && value.isNegative) return '-0';
  }
  if (value is JsObjectFace) {
    return {for (final key in value.jsKeys()) key: _plain(value.jsRead(key))};
  }
  return value;
}

/// The properties, the options and the context of each bar of each dataset,
/// and for each bar whether it has the options object of the bar before it.
Object _observe(Chart chart) => [
  for (var k = 0; k < chart.getSortedVisibleDatasetMetas().length; k++) k,
  for (final meta in chart.sortedMetasets)
    if (meta!.type == 'bar')
      [
        for (final (i, e) in meta.data.indexed)
          [
            for (final key in [
              'x',
              'y',
              'base',
              'width',
              'height',
              'horizontal',
              'enableBorderRadius',
              'borderSkipped',
              'inflateAmount',
            ])
              _plain((e as ElementPropertyRead)[key]),
            _plain(e.options),
            i > 0 && identical(e.options, meta.data[i - 1].options),
            if ((e as BarElement).$context case final context?)
              for (final key in [
                'index',
                'dataIndex',
                'raw',
                'parsed',
                'mode',
                'active',
              ])
                _plain(contextField(context, key)),
          ],
      ],
];

/// The stack tables of [chart]: for each stack key and index key, the keys
/// and the values of the stack object, in the `Object.keys` order.
Object _stackTables(Chart chart) {
  Object? plainDeep(Object? value) => value is JsObjectFace
      ? {for (final key in value.jsKeys()) key: plainDeep(value.jsRead(key))}
      : _plain(value);
  final stacks = chart.stacks;
  if (stacks == null) return const <Object?>[];
  return {
    for (final key in stacks.keys)
      key: {
        for (final entry in stacks[key]!.entries)
          entry.key: plainDeep(entry.value),
      },
  };
}

/// New values in both configs, the same in both.
void _step(List<ChartConfigurationScope> configs, int step) {
  for (final cfg in configs) {
    for (final (k, dataset) in _datasets(cfg).indexed) {
      final data = (dataset! as Map<String, Object?>)['data'];
      if (data is List<Object?>) {
        data[1] = step + 1.5 + k;
        data[4] = -1.0 - step;
      }
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Chart.register([
    BarController.component,
    BarElement.component,
    LineController.component,
    LineElement.component,
    PointElement.component,
    CategoryScale.component,
    LinearScale.component,
  ]);

  group('update modes with animation false', () {
    for (final horizontal in [false, true]) {
      for (final mode in <UpdateMode?>[
        null,
        UpdateMode.defaultMode,
        UpdateMode.resize,
        const UpdateMode('zoom'),
        UpdateMode.show,
        UpdateMode.hide,
      ]) {
        test('mode $mode with animation false takes the fast loop and gives '
            'the bars of the ordinary loop, horizontal $horizontal', () {
          final ca = _config(horizontal: horizontal);
          final cb = _config(horizontal: horizontal);
          final a = _chart(ca);
          final b = _chart(cb, reference: true);
          for (var step = 0; step < 3; step++) {
            _step([ca, cb], step);
            if (step == 1) {
              a.toggleDataVisibility(3);
              b.toggleDataVisibility(3);
            }
            final before = fastBarModesTaken;
            a.update(mode);
            expect(fastBarModesTaken, before + 1);
            b.update(mode);
            expect(fastBarModesTaken, before + 1);
            expect(_observe(a), _observe(b));
          }
        });
      }
    }

    test('the first build takes the fast loop in its update', () {
      final before = fastBarModesTaken;
      final a = _chart(_config());
      expect(fastBarModesTaken, before + 1);
      final b = _chart(_config(), reference: true);
      expect(fastBarModesTaken, before + 1);
      expect(_observe(a), _observe(b));
    });

    test('a resize takes the fast loop', () {
      final a = _chart(_config());
      final b = _chart(_config(), reference: true);
      final before = fastBarModesTaken;
      a.resize(600, 380);
      expect(fastBarModesTaken, before + 1);
      b.resize(600, 380);
      expect(fastBarModesTaken, before + 1);
      expect(a.width, 600);
      expect(_observe(a), _observe(b));
    });

    test('a color for each bar keeps the mode in the context of each bar', () {
      ChartConfigurationScope config() => _config(
        extra: (_) => {
          'backgroundColor': <ChartPaint>[
            const ChartPaint.solid(ui.Color(0xffff0000)),
            const ChartPaint.solid(ui.Color(0xff0000ff)),
          ],
        },
      );
      final ca = config();
      final cb = config();
      final a = _chart(ca);
      final b = _chart(cb, reference: true);
      for (final mode in [UpdateMode.defaultMode, UpdateMode.resize]) {
        _step([ca, cb], 0);
        final before = fastBarModesTaken;
        a.update(mode);
        b.update(mode);
        expect(fastBarModesTaken, before + 1);
        expect(_observe(a), _observe(b));
        expect(
          (a.getDatasetMeta(0).data[3] as BarElement).$context!.mode,
          mode,
        );
      }
    });

    test('the modes reset and active keep the ordinary loop', () {
      final ca = _config();
      final cb = _config();
      final a = _chart(ca);
      final b = _chart(cb, reference: true);
      for (final mode in [UpdateMode.reset, UpdateMode.active]) {
        _step([ca, cb], 0);
        final before = fastBarModesTaken;
        a.update(mode);
        b.update(mode);
        expect(fastBarModesTaken, before);
        expect(_observe(a), _observe(b));
      }
    });

    test('an animation option other than the value false keeps the ordinary '
        'loop', () {
      for (final cfg in [
        _config(hasAnimation: false),
        _config(animation: <String, Object?>{'duration': 0.0}),
        _config(animation: <String, Object?>{'duration': 400.0}),
      ]) {
        cfg['platform'] = _AnimatedPlatform.new;
        final before = fastBarModesTaken;
        final a = _chart(cfg);
        _step([cfg], 0);
        a
          ..update()
          ..update(UpdateMode.resize);
        expect(fastBarModesTaken, before);
        a.stop();
      }
    });

    test('the value false on a platform that keeps the option', () {
      final ca = _config()..['platform'] = _AnimatedPlatform.new;
      final cb = _config()..['platform'] = _AnimatedPlatform.new;
      final a = _chart(ca);
      final b = _chart(cb, reference: true);
      _step([ca, cb], 0);
      final before = fastBarModesTaken;
      a.update();
      b.update();
      expect(fastBarModesTaken, before + 1);
      expect(_observe(a), _observe(b));
    });
  });

  group('several datasets', () {
    for (final horizontal in [false, true]) {
      for (final mode in <UpdateMode?>[UpdateMode.none, null]) {
        test('three grouped datasets take the fast loop and give the bars of '
            'the ordinary loop, mode $mode, horizontal $horizontal', () {
          final ca = _config(datasets: 3, horizontal: horizontal);
          final cb = _config(datasets: 3, horizontal: horizontal);
          final a = _chart(ca);
          final b = _chart(cb, reference: true);
          for (var step = 0; step < 4; step++) {
            _step([ca, cb], step);
            if (step == 1) {
              a.toggleDataVisibility(3);
              b.toggleDataVisibility(3);
            }
            if (step == 2) {
              // One hidden dataset: two stacks.
              a.setDatasetVisibility(1, false);
              b.setDatasetVisibility(1, false);
            }
            if (step == 3) {
              a.setDatasetVisibility(1, true);
              b.setDatasetVisibility(1, true);
            }
            final before = fastBarMultiTaken;
            a.update(mode);
            expect(fastBarMultiTaken, before + 3);
            b.update(mode);
            expect(fastBarMultiTaken, before + 3);
            expect(_observe(a), _observe(b));
          }
        });
      }
    }

    test('two index axes: the axis count and the axis number of the plan', () {
      ChartConfigurationScope config() => _config(
        datasets: 4,
        extra: (k) => {if (k == 1) 'xAxisID': 'x2', if (k == 2) 'xAxisID': 'x'},
        scales: {
          'x2': <String, Object?>{
            'type': 'category',
            'display': ScaleDisplay.off,
          },
        },
      );
      final ca = config();
      final cb = config();
      final a = _chart(ca);
      final b = _chart(cb, reference: true);
      for (var step = 0; step < 2; step++) {
        _step([ca, cb], step);
        final before = fastBarMultiTaken;
        a.update(UpdateMode.none);
        b.update(UpdateMode.none);
        expect(fastBarMultiTaken, before + 4);
        expect(_observe(a), _observe(b));
      }
    });

    test('stack names with stacked false on both scales', () {
      ChartConfigurationScope config() => _config(
        datasets: 4,
        extra: (k) => {'stack': k < 2 ? 'left' : 'right'},
        indexScale: {'stacked': StackMode.off},
        valueScale: {'stacked': StackMode.off},
      );
      final ca = config();
      final cb = config();
      final a = _chart(ca);
      final b = _chart(cb, reference: true);
      _step([ca, cb], 0);
      final before = fastBarMultiTaken;
      a.update(UpdateMode.none);
      b.update(UpdateMode.none);
      expect(fastBarMultiTaken, before + 4);
      expect(_observe(a), _observe(b));
    });

    test('a fixed bar thickness, a base option and a hidden dataset', () {
      ChartConfigurationScope config() => _config(
        datasets: 4,
        horizontal: true,
        extra: (k) => {
          'barThickness': const BarThickness.pixels(7),
          'maxBarThickness': 5.0 + k,
          'base': 2.0,
          'borderSkipped': k.isEven ? BorderSkippedEdge.end : false,
          if (k == 2) 'hidden': true,
        },
      );
      final ca = config();
      final cb = config();
      final a = _chart(ca);
      final b = _chart(cb, reference: true);
      for (var step = 0; step < 2; step++) {
        _step([ca, cb], step);
        final before = fastBarMultiTaken;
        a.update(UpdateMode.none);
        b.update(UpdateMode.none);
        expect(fastBarMultiTaken, before + 4);
        expect(_observe(a), _observe(b));
      }
    });

    test('a combo chart: the bar datasets take the fast loop', () {
      ChartConfigurationScope config() =>
          _config(datasets: 3, extra: (k) => {if (k == 1) 'type': 'line'});
      final ca = config();
      final cb = config();
      final a = _chart(ca);
      final b = _chart(cb, reference: true);
      _step([ca, cb], 0);
      final before = fastBarMultiTaken;
      a.update(UpdateMode.none);
      b.update(UpdateMode.none);
      expect(fastBarMultiTaken, before + 2);
      expect(_observe(a), _observe(b));
    });

    test('the typed API: three BarDataset objects take the fast loop', () {
      ChartConfig config(int step) => ChartConfig(
        labels: const <Object>['a', 'b', 'c', 'd'],
        datasets: [
          for (var k = 0; k < 3; k++)
            BarDataset(
              key: ValueKey('series$k'),
              data: .values(<double>[1.0 + k, step + 2.0, 3, 4.0 + k]),
              backgroundColor: ChartValue.constant(
                ChartPaint.solid(_colors[k]),
              ),
              barPercentage: .8,
              categoryPercentage: 1,
            ),
        ],
        scales: const [CategoryAxis(.x), LinearAxis(.y, min: 0, max: 10)],
        animation: ChartAnimation.none,
        responsive: false,
      );
      final la = ChartConfigLowering(config(0));
      final lb = ChartConfigLowering(config(0));
      final a = _chart(la.lower());
      final b = _chart(lb.lower(), reference: true);
      for (var step = 1; step < 3; step++) {
        la.apply(config(step));
        lb.apply(config(step));
        final before = fastBarMultiTaken;
        a.update(UpdateMode.none);
        b.update(UpdateMode.none);
        expect(fastBarMultiTaken, before + 3);
        expect(_observe(a), _observe(b));
      }
      // Data-only updates of chart a against full updates of chart b. Chart a
      // keeps the rulers of its three controllers.
      for (var step = 3; step < 7; step++) {
        la.apply(config(step));
        lb.apply(config(step));
        final before = fastBarMultiTaken;
        final kept = fastBarRulersKept;
        expect(a.updateData(), isTrue);
        expect(fastBarRulersKept, kept + 1);
        expect(fastBarMultiTaken, before + 3);
        b.update(UpdateMode.none);
        expect(fastBarRulersKept, kept + 1);
        expect(_observe(a), _observe(b));
      }
    });

    for (final (name, extra, indexScale, valueScale, taken) in [
      (
        'stacked scales',
        null,
        const {'stacked': StackMode.on},
        const {'stacked': StackMode.on},
        0,
      ),
      (
        'a stack name with no stacked option',
        (int k) => <String, Object?>{'stack': 's$k'},
        const <String, Object?>{},
        const <String, Object?>{},
        0,
      ),
      (
        'grouped false in one dataset',
        (int k) => <String, Object?>{if (k == 1) 'grouped': false},
        const <String, Object?>{},
        const <String, Object?>{},
        2,
      ),
      (
        'skipNull in one dataset',
        (int k) => <String, Object?>{if (k == 1) 'skipNull': true},
        const <String, Object?>{},
        const <String, Object?>{},
        2,
      ),
      (
        'an axis id that is not a String',
        (int k) => <String, Object?>{if (k == 1) 'xAxisID': 7.0},
        const <String, Object?>{},
        const <String, Object?>{},
        -1,
      ),
    ]) {
      test('$name: the datasets outside the guard keep the ordinary loop', () {
        ChartConfigurationScope config() => _config(
          datasets: 3,
          extra: extra,
          indexScale: indexScale,
          valueScale: valueScale,
        );
        final ca = config();
        final cb = config();
        final Chart a;
        final Chart b;
        try {
          a = _chart(ca);
        } on Object {
          // The config does not build a chart: nothing to compare.
          expect(taken, -1);
          return;
        }
        b = _chart(cb, reference: true);
        _step([ca, cb], 0);
        final before = fastBarMultiTaken;
        a.update(UpdateMode.none);
        b.update(UpdateMode.none);
        if (taken >= 0) expect(fastBarMultiTaken, before + taken);
        if (taken < 0) expect(fastBarMultiTaken, before);
        expect(_observe(a), _observe(b));
      });
    }

    test('object data in one dataset: a data-only update keeps no ruler', () {
      ChartConfigurationScope config() => _config(
        datasets: 2,
        extra: (k) => {
          if (k == 1)
            'data': <Object?>[
              for (var i = 0; i < 6; i++)
                <String, Object?>{'x': 'abcdef'[i], 'y': 1.0 + i},
            ],
        },
      );
      final ca = config();
      final cb = config();
      final a = _chart(ca);
      final b = _chart(cb, reference: true);
      for (var step = 0; step < 3; step++) {
        _step([ca, cb], step);
        final kept = fastBarRulersKept;
        a.updateData();
        b.update(UpdateMode.none);
        expect(fastBarRulersKept, kept);
        expect(_observe(a), _observe(b));
      }
    });

    test('a dataset object with its own reads declines with no extra read', () {
      (ChartConfigurationScope, _CountingMap) config() {
        final cfg = _config(datasets: 3);
        final list = _datasets(cfg);
        final counting = _CountingMap(list[1]! as Map<String, Object?>);
        list[1] = counting;
        return (cfg, counting);
      }

      final (ca, countA) = config();
      final (cb, countB) = config();
      final a = _chart(ca);
      final b = _chart(cb, reference: true);
      expect(countA.reads, countB.reads);
      final before = fastBarMultiTaken;
      a.update(UpdateMode.none);
      b.update(UpdateMode.none);
      expect(fastBarMultiTaken, before);
      expect(countA.reads, countB.reads);
      expect(_observe(a), _observe(b));
    });
  });

  group('stacked datasets', () {
    for (final horizontal in [false, true]) {
      for (final mode in <UpdateMode?>[UpdateMode.none, null]) {
        test('stacked datasets take one search and give the bars and the '
            'stack tables of the ordinary loop, mode $mode, horizontal '
            '$horizontal', () {
          ChartConfigurationScope config() => _config(
            datasets: 4,
            horizontal: horizontal,
            indexScale: {'stacked': StackMode.on},
            valueScale: {'stacked': StackMode.on},
            extra: (k) => {'borderSkipped': BorderSkippedEdge.middle},
          );
          final ca = config();
          final cb = config();
          final a = _chart(ca);
          final b = _chart(cb, upstream: true);
          for (var step = 0; step < 4; step++) {
            _step([ca, cb], step);
            if (step == 1) {
              a.toggleDataVisibility(3);
              b.toggleDataVisibility(3);
            }
            if (step == 2) {
              a.setDatasetVisibility(1, false);
              b.setDatasetVisibility(1, false);
            }
            if (step == 3) {
              a.setDatasetVisibility(1, true);
              b.setDatasetVisibility(1, true);
            }
            final before = fastBarPlansTaken;
            a.update(mode);
            expect(fastBarPlansTaken, before + 4);
            b.update(mode);
            expect(fastBarPlansTaken, before + 4);
            expect(_observe(a), _observe(b));
            expect(_stackTables(a), _stackTables(b));
          }
        });
      }
    }

    for (final (name, extra, indexScale, valueScale, taken) in [
      (
        'stack groups',
        (int k) => <String, Object?>{'stack': k.isEven ? 'even' : 'odd'},
        const <String, Object?>{'stacked': StackMode.on},
        const <String, Object?>{'stacked': StackMode.on},
        4,
      ),
      (
        'stack names with no stacked option',
        (int k) => <String, Object?>{'stack': k < 2 ? 'left' : 'right'},
        const <String, Object?>{},
        const <String, Object?>{},
        4,
      ),
      (
        'the single stack mode',
        null,
        const <String, Object?>{'stacked': StackMode.on},
        const <String, Object?>{'stacked': StackMode.single},
        4,
      ),
      (
        'a hidden dataset and a fixed thickness',
        (int k) => <String, Object?>{
          if (k == 2) 'hidden': true,
          'barThickness': const BarThickness.pixels(6),
          'maxBarThickness': 4.0 + k,
        },
        const <String, Object?>{'stacked': StackMode.on},
        const <String, Object?>{'stacked': StackMode.on},
        4,
      ),
      (
        'flex bars decline (no cached bulk options)',
        (int k) => <String, Object?>{'barThickness': BarThickness.flex},
        const <String, Object?>{'stacked': StackMode.on},
        const <String, Object?>{'stacked': StackMode.on},
        0,
      ),
      (
        'null values',
        (int k) => <String, Object?>{
          'data': <Object?>[1.0 + k, null, -3.0, null, 2.0, -1.0 - k],
        },
        const <String, Object?>{'stacked': StackMode.on},
        const <String, Object?>{'stacked': StackMode.on},
        4,
      ),
      (
        'a scriptable color: no shared options',
        (int k) => <String, Object?>{
          'backgroundColor': (Object? ctx, Object? _) =>
              ChartPaint.solid(_colors[k]),
        },
        const <String, Object?>{'stacked': StackMode.on},
        const <String, Object?>{'stacked': StackMode.on},
        0,
      ),
      (
        'a minimum bar length',
        (int k) => <String, Object?>{'minBarLength': 4.0},
        const <String, Object?>{'stacked': StackMode.on},
        const <String, Object?>{'stacked': StackMode.on},
        0,
      ),
      (
        'a scriptable grid line width of the value scale',
        null,
        const <String, Object?>{'stacked': StackMode.on},
        <String, Object?>{
          'stacked': StackMode.on,
          'grid': <String, Object?>{
            'lineWidth': (Object? ctx, Object? _) => 2.0,
          },
        },
        0,
      ),
      (
        'skipNull',
        (int k) => <String, Object?>{'skipNull': true},
        const <String, Object?>{'stacked': StackMode.on},
        const <String, Object?>{'stacked': StackMode.on},
        0,
      ),
      (
        'floating bars in one dataset',
        (int k) => <String, Object?>{
          if (k == 1)
            'data': <Object?>[
              for (var i = 0; i < 6; i++) <double>[1.0 * i, 2.0 + i],
            ],
        },
        const <String, Object?>{'stacked': StackMode.on},
        const <String, Object?>{'stacked': StackMode.on},
        3,
      ),
    ]) {
      test('$name: the bars and the stack tables of the ordinary loop', () {
        ChartConfigurationScope config() => _config(
          datasets: 4,
          extra: extra,
          indexScale: indexScale,
          valueScale: valueScale,
        );
        final ca = config();
        final cb = config();
        final a = _chart(ca);
        final b = _chart(cb, upstream: true);
        for (var step = 0; step < 2; step++) {
          _step([ca, cb], step);
          for (final mode in <UpdateMode?>[UpdateMode.none, null]) {
            final before = fastBarPlansTaken;
            a.update(mode);
            b.update(mode);
            expect(fastBarPlansTaken, before + taken);
            expect(_observe(a), _observe(b));
            expect(_stackTables(a), _stackTables(b));
          }
        }
      });
    }

    test('an animated update keeps the search of each bar', () {
      ChartConfigurationScope config() => _config(
        datasets: 3,
        animation: <String, Object?>{'duration': 0.0},
        indexScale: {'stacked': StackMode.on},
        valueScale: {'stacked': StackMode.on},
      )..['platform'] = _AnimatedPlatform.new;
      final ca = config();
      final cb = config();
      final a = _chart(ca);
      final b = _chart(cb, upstream: true);
      _step([ca, cb], 0);
      final before = fastBarPlansTaken;
      a.update();
      b.update();
      expect(fastBarPlansTaken, before);
      a
        ..update(UpdateMode.none)
        ..stop();
      b
        ..update(UpdateMode.none)
        ..stop();
      expect(fastBarPlansTaken, before + 3);
      expect(_observe(a), _observe(b));
    });

    test('a dataset object with its own reads declines with no extra read', () {
      (ChartConfigurationScope, _CountingMap) config() {
        final cfg = _config(
          datasets: 3,
          indexScale: {'stacked': StackMode.on},
          valueScale: {'stacked': StackMode.on},
        );
        final list = _datasets(cfg);
        final counting = _CountingMap(list[1]! as Map<String, Object?>);
        list[1] = counting;
        return (cfg, counting);
      }

      final (ca, countA) = config();
      final (cb, countB) = config();
      final a = _chart(ca);
      final b = _chart(cb, upstream: true);
      expect(countA.reads, countB.reads);
      final before = fastBarPlansTaken;
      a.update(UpdateMode.none);
      b.update(UpdateMode.none);
      expect(fastBarPlansTaken, before);
      expect(countA.reads, countB.reads);
      expect(_observe(a), _observe(b));
    });
    test('stacked line datasets: the stack tables of upstream', () {
      ChartConfigurationScope config() => _config(
        datasets: 4,
        extra: (k) => {'type': 'line'},
        valueScale: {'stacked': StackMode.on},
      );
      final ca = config();
      final cb = config();
      final a = _chart(ca);
      final b = _chart(cb, upstream: true);
      for (var step = 0; step < 3; step++) {
        _step([ca, cb], step);
        if (step == 1) {
          a.setDatasetVisibility(2, false);
          b.setDatasetVisibility(2, false);
        }
        a.update(UpdateMode.none);
        b.update(UpdateMode.none);
        expect(_stackTables(a), _stackTables(b));
      }
    });

    test('a _visualValues object of the user in a stack', () {
      ChartConfigurationScope config() => _config(
        datasets: 3,
        indexScale: {'stacked': StackMode.on},
        valueScale: {'stacked': StackMode.on},
      );
      final ca = config();
      final cb = config();
      final a = _chart(ca);
      final b = _chart(cb, upstream: true);
      final maps = <_CountingMap>[];
      for (final chart in [a, b]) {
        final stacks = chart.stacks!;
        final sub = stacks[stacks.keys.first]!;
        final map = _CountingMap(<String, Object?>{});
        sub['2']!.jsWrite('_visualValues', map);
        maps.add(map);
      }
      _step([ca, cb], 0);
      a.update(UpdateMode.none);
      b.update(UpdateMode.none);
      expect(maps[0].fields, maps[1].fields);
      expect(maps[0].fields, isNotEmpty);
      expect(_observe(a), _observe(b));
      expect(_stackTables(a), _stackTables(b));
    });

    test('an empty dataset in its own stack makes no sub-stack', () {
      // `getOrCreateStack` makes the sub-stack at the first item only.
      for (final stacked in [true, false]) {
        ChartConfigurationScope config() => _config(
          datasets: 2,
          extra: (k) => {'stack': 's$k', if (k == 1) 'data': <Object?>[]},
          indexScale: {'stacked': stacked ? StackMode.on : StackMode.off},
          valueScale: {'stacked': stacked ? StackMode.on : StackMode.off},
        );
        final ca = config();
        final cb = config();
        final a = _chart(ca);
        final b = _chart(cb, upstream: true);
        expect(_stackTables(a), _stackTables(b));
        for (final cfg in [ca, cb]) {
          (_datasets(cfg)[1]! as Map<String, Object?>)['stack'] = 's9';
        }
        for (final mode in <UpdateMode?>[UpdateMode.none, null]) {
          a.update(mode);
          b.update(mode);
          expect(_stackTables(a), _stackTables(b));
          expect(_observe(a), _observe(b));
        }
      }
    });

    test('a high dataset index alone in its stack', () {
      // Dataset 19 has a stack of its own: its stack values keep the tree.
      ChartConfigurationScope config() => _config(
        datasets: 20,
        extra: (k) => {'stack': k == 19 ? 'solo' : 'main'},
        indexScale: {'stacked': StackMode.on},
        valueScale: {'stacked': StackMode.on},
      );
      final ca = config();
      final cb = config();
      final a = _chart(ca);
      final b = _chart(cb, upstream: true);
      for (var step = 0; step < 3; step++) {
        _step([ca, cb], step);
        if (step == 1) {
          a.setDatasetVisibility(4, false);
          b.setDatasetVisibility(4, false);
        }
        a.update(UpdateMode.none);
        b.update(UpdateMode.none);
        expect(_observe(a), _observe(b));
        expect(_stackTables(a), _stackTables(b));
      }
      final soloKey = a.stacks!.keys.firstWhere((k) => k.endsWith('.solo'));
      final solo = a.stacks![soloKey]!;
      for (final entry in solo.values) {
        expect(entry.datasetValues.denseSlots, 0);
      }
    });
  });
}
