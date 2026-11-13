// Original code, not ported from Chart.js: native bubble option-loop twins.
@TestOn('vm')
library;

import 'dart:collection';
import 'dart:ui' as ui;

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart'
    show Directionality, SizedBox, TextDirection;
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart'
    show
        BubbleDataset,
        ChartAnimation,
        ChartConfig,
        ChartThemeData,
        ChartValue,
        ChartView,
        DataPoint;
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/core/core.datasetController.dart'
    show controllerArgs;
import 'package:flutter_chartjs_port/src/core/core.scale.dart' show scaleCfgArg;
import 'package:flutter_chartjs_port/src/core/data_update.dart'
    show registerDataUpdateTypes;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/options/element_options_base.dart';
import 'package:flutter_chartjs_port/src/options/foreign_audit.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
import 'package:flutter_chartjs_port/src/options/resolved.g.dart'
    show PointOptions;
import 'package:flutter_chartjs_port/src/typed/lower.dart'
    show ChartConfigLowering;
import 'package:flutter_test/flutter_test.dart';

const red = ChartPaint.solid(ui.Color(0xffff0000));
const blue = ChartPaint.solid(ui.Color(0xff0000ff));
const green = ChartPaint.solid(ui.Color(0xff00ff00));
const _length = 8;

/// A trivial user subclass: the exact-class guard fails, and each call stays on
/// the ordinary path. Its charts are the reference of each twin.
class _ReferenceBubble(super.chart, super.datasetIndex, [super.newTarget])
    extends BubbleController {
  static final JsClass value = JsClass(
    'ReferenceBubble',
    superclass: BubbleController.jsClass,
    statics: {'id': 'referenceBubble'},
    construct: (newTarget, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return _ReferenceBubble(chart, datasetIndex, newTarget);
    },
  );
}

/// A user subclass that counts each option resolve.
class _CountingBubble(super.chart, super.datasetIndex, [super.newTarget])
    extends BubbleController {
  static int resolves = 0;

  static final JsClass value = JsClass(
    'CountingBubble',
    superclass: BubbleController.jsClass,
    statics: {'id': 'countingBubble'},
    construct: (newTarget, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return _CountingBubble(chart, datasetIndex, newTarget);
    },
  );

  @override
  ElementOptions resolveDataElementOptions(int index, [String? mode]) {
    resolves++;
    return super.resolveDataElementOptions(index, mode);
  }
}

class _ReferenceChart(super.item, super.userConfig) extends Chart {
  @override
  bool get supportsNativePointOptions => false;
}

/// A platform that keeps the option `animation`: an unhosted canvas otherwise
/// gets a [BasicPlatform], whose `updateConfig` writes `false` into it.
class _AnimatedPlatform() extends BasicPlatform {
  static final JsClass value = JsClass(
    'AnimatedPlatform',
    superclass: BasicPlatform.jsClass,
    construct: (_, _) => _AnimatedPlatform(),
  );

  @override
  void updateConfig(ChartConfiguration config) {}
}

// Explicit test opt-in: counters only, with native size/context behavior.
class _ProbePoint() extends PointElement {
  int planReads = 0;
  int sizeCalls = 0;
  @override
  bool get supportsNativePointOptions {
    planReads++;
    return true;
  }

  @override
  bool get typedWrites => true;

  @override
  double size([Object? options]) {
    sizeCalls++;
    return super.size(options);
  }
}

class _CustomSize() extends PointElement {
  void Function()? afterSize;
  int calls = 0;
  @override
  double size([Object? options]) {
    final result = super.size(options);
    calls++;
    afterSize?.call();
    return result;
  }
}

class _CustomScale(super.cfg) extends LinearScale {
  int calls = 0;
  static final value = JsClass(
    'BubbleCustomScale',
    superclass: LinearScale.jsClass,
    statics: {'id': 'bubble-custom-scale'},
    construct: (_, args) => _CustomScale(scaleCfgArg(args)),
  );
  @override
  double getPixelForValue(Object? value, [int? index]) {
    calls++;
    return super.getPixelForValue(value, index);
  }
}

class _ObservedMap(final Map<String, Object?> fields)
    extends MapBase<String, Object?> {
  final List<Object?> reads = [];
  void Function(Object?)? onRead;
  @override
  Object? operator [](Object? key) {
    reads.add(key);
    onRead?.call(key);
    return fields[key];
  }

  @override
  void operator []=(String key, Object? value) => fields[key] = value;
  @override
  Iterable<String> get keys => fields.keys;
  @override
  Object? remove(Object? key) => fields.remove(key);
  @override
  void clear() => fields.clear();
}

/// `{x, y, r}` items of one radius step.
List<Object?> _maps({double step = 0}) => [
  for (var i = 0; i < _length; i++)
    <String, Object?>{
      'x': i.toDouble(),
      'y': (i - 3).toDouble() + step,
      'r': 2.0 + i,
    },
];

/// [DataPoint.bubble] items of one radius step.
List<Object?> _points({double step = 0}) => [
  for (var i = 0; i < _length; i++)
    DataPoint.bubble(i.toDouble(), (i - 3).toDouble() + step, 2.0 + i),
];

Map<String, Object?> _config({
  String type = 'bubble',
  Object? parsing,
  List<Object?>? data,
  Object? backgroundColor = blue,
  Object? borderColor = blue,
  Map<String, Object?> dataset = const {},
}) => {
  'type': type,
  'data': <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{
        'data': data ?? _maps(),
        'backgroundColor': backgroundColor,
        'borderColor': borderColor,
        'borderWidth': 1.0,
        ...dataset,
      },
    ],
  },
  'options': <String, Object?>{
    'responsive': false,
    'animation': false,
    'parsing': ?parsing,
    'events': <String>[],
    'plugins': <String, Object?>{'legend': false, 'tooltip': false},
    'scales': <String, Object?>{
      'x': <String, Object?>{
        'type': 'linear',
        'display': false,
        'min': 0.0,
        'max': 8.0,
      },
      'y': <String, Object?>{
        'type': 'linear',
        'display': false,
        'min': -5.0,
        'max': 10.0,
      },
    },
  },
};

Map<String, Object?> _dataset(Map<String, Object?> cfg) =>
    ((cfg['data']! as Map<String, Object?>)['datasets']! as List<Object?>)[0]!
        as Map<String, Object?>;

Chart _chart(Object cfg, {bool reference = false}) {
  final canvas = UiCanvasElement(width: 640, height: 400);
  final chart = reference ? _ReferenceChart(canvas, cfg) : Chart(canvas, cfg);
  addTearDown(chart.destroy);
  return chart;
}

/// The pair of charts of one twin: native, then the ordinary reference.
List<Map<String, Object?>> _pair(
  Map<String, Object?> Function(String type) config,
) => [config('bubble'), config('referenceBubble')];

List<_ProbePoint> _probes(Chart chart) {
  final points = chart.getDatasetMeta(0).data;
  return [for (var i = 0; i < points.length; i++) points[i] = _ProbePoint()];
}

Object? _plain(Object? value) {
  if (value is double && !value.isFinite) return value.toString();
  if (value is JsObjectFace) {
    return {for (final k in value.jsKeys()) k: _plain(value.jsRead(k))};
  }
  if (value is Map) {
    return {for (final e in value.entries) e.key: _plain(e.value)};
  }
  return value;
}

Object _observe(Chart chart) {
  final meta = chart.getDatasetMeta(0);
  return [
    _plain(meta.controller!.getMaxOverflow()),
    for (final point in meta.data.cast<PointElement>())
      [
        _plain(point.x),
        _plain(point.y),
        point.skip,
        point.stop,
        _plain(point.options),
        point.$context?.jsKeys(),
        for (final key in [
          'index',
          'dataIndex',
          'mode',
          'active',
          'parsed',
          'raw',
        ])
          _plain(point.$context?.jsRead(key)),
      ],
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Chart.register([
    BubbleController.jsClass,
    _ReferenceBubble.value,
    _CountingBubble.value,
    PointElement.jsClass,
    LinearScale.jsClass,
  ]);
  registerDataUpdateTypes([<DataPoint>[].runtimeType], [DataPoint]);

  /// The cases of the data and of the indexed colors, in two forms of parsing.
  final datas = <String, List<Object?> Function({double step})>{
    'maps': _maps,
    'points': _points,
  };
  final colors = <String, Object?>{
    'constant': blue,
    'indexed': <ChartPaint>[red, blue],
  };
  for (final data in datas.entries) {
    for (final color in colors.entries) {
      for (final parsing in [null, false]) {
        test('twin ${data.key}, ${color.key}, parsing $parsing', () {
          final configs = _pair(
            (type) => _config(
              type: type,
              data: data.value(),
              backgroundColor: color.value,
              parsing: parsing,
            ),
          );
          final a = _chart(configs[0]);
          final b = _chart(configs[1], reference: true);
          expect(_observe(a), _observe(b));
          for (var step = 1; step < 4; step++) {
            for (final cfg in configs) {
              _dataset(cfg)['data'] = data.value(step: step.toDouble());
            }
            a.update('none');
            b.update('none');
            expect(_observe(a), _observe(b));
            final points = a.getDatasetMeta(0).data;
            final first = points[3] as PointElement;
            final next = points[4] as PointElement;
            expect(identical(first.options, next.options), isFalse);
            expect(jsGet(first.options, r'$shared'), isFalse);
          }
          // Each result is fresh and unfrozen, in the reference too.
          final options = a.getDatasetMeta(0).data[3].options! as ElementOptions
            ..storeKey(OptionKey.radius, 77.0);
          expect(
            jsGet(a.getDatasetMeta(0).data[4].options, 'radius'),
            isNot(77.0),
          );
          expect(options.isFrozen, isFalse);
        });
      }
    }
  }

  for (final parsing in [null, false]) {
    test('twin with a data length change, parsing $parsing', () {
      List<Object?> data(int length, {double step = 0}) => [
        for (var i = 0; i < length; i++)
          DataPoint.bubble(i.toDouble(), 1 + step, 2.0 + i),
      ];
      final configs = _pair(
        (type) => _config(
          type: type,
          parsing: parsing,
          data: data(_length),
          backgroundColor: <ChartPaint>[red, blue],
        ),
      );
      final a = _chart(configs[0]);
      final b = _chart(configs[1], reference: true);
      for (final length in [12, 3, 2, 1, 0, 6]) {
        for (final cfg in configs) {
          _dataset(cfg)['data'] = data(length, step: length.toDouble());
        }
        a.update('none');
        b.update('none');
        expect(_observe(a), _observe(b));
      }
    });
  }

  test('twin of the two datasets of one chart, by index', () {
    final configs = _pair((type) {
      final cfg = _config(type: type, backgroundColor: <ChartPaint>[red, blue]);
      ((cfg['data']! as Map<String, Object?>)['datasets']! as List<Object?>)
          .add(<String, Object?>{
            'data': _maps(step: 2),
            'backgroundColor': <ChartPaint>[green, red],
            'borderColor': red,
            'borderWidth': 2.0,
          });
      return cfg;
    });
    final a = _chart(configs[0]);
    final b = _chart(configs[1], reference: true);
    a.update('none');
    b.update('none');
    expect(_observe(a), _observe(b));
    final second = a.getDatasetMeta(1);
    final other = b.getDatasetMeta(1);
    expect(
      second.controller!.getMaxOverflow(),
      other.controller!.getMaxOverflow(),
    );
    for (var i = 0; i < _length; i++) {
      expect(_plain(second.data[i].options), _plain(other.data[i].options));
    }
  });

  test('twin of the mode default and of a queued animation', () {
    for (final animation in <Object>[false, true]) {
      // `stop` writes the value at its time: both charts stop at one time.
      var now = DateTime.utc(2026);
      withClock(Clock(() => now), () {
        final configs = _pair((type) {
          final cfg = _config(type: type);
          (cfg['options']! as Map)['animation'] = animation;
          cfg['platform'] = _AnimatedPlatform.value;
          return cfg;
        });
        final a = _chart(configs[0]);
        final b = _chart(configs[1], reference: true);
        for (final cfg in configs) {
          _dataset(cfg)['data'] = _maps(step: 1);
        }
        a.update();
        b.update();
        for (final chart in [a, b]) {
          expect(chart.animationsDisabled, animation == false);
          expect(animator.has(chart), animation == true);
        }
        now = now.add(const Duration(milliseconds: 250));
        a.stop();
        b.stop();
        expect(
          a.getDatasetMeta(0).controller!.getMaxOverflow(),
          b.getDatasetMeta(0).controller!.getMaxOverflow(),
        );
        for (var i = 0; i < _length; i++) {
          final first = a.getDatasetMeta(0).data[i] as PointElement;
          final second = b.getDatasetMeta(0).data[i] as PointElement;
          expect(first.x, second.x);
          expect(first.y, second.y);
          expect(
            jsGet(first.options, 'radius'),
            jsGet(second.options, 'radius'),
          );
        }
      });
    }
  });

  group('the update loop', () {
    for (final color in <Object?>[
      blue,
      <ChartPaint>[red, blue],
    ]) {
      test('prepares fresh options after two resolves, color $color', () {
        final configs = _pair(
          (type) => _config(type: type, backgroundColor: color),
        );
        final a = _chart(configs[0]);
        final b = _chart(configs[1], reference: true);
        final probes = _probes(a);
        final others = _probes(b);
        final meta = a.getDatasetMeta(0);
        meta.controller!.updateElements(meta.data, 0, _length, 'none');
        final other = b.getDatasetMeta(0);
        other.controller!.updateElements(other.data, 0, _length, 'none');
        expect(probes[0].planReads, 0);
        expect(probes[1].planReads, 0);
        expect(probes.skip(2).every((p) => p.planReads > 0), isTrue);
        expect(others.every((p) => p.planReads == 0), isTrue);
        for (var i = 0; i < _length; i++) {
          expect(_plain(probes[i].options), _plain(others[i].options));
          expect(probes[i].x, others[i].x);
          expect(probes[i].y, others[i].y);
          expect(probes[i].skip, others[i].skip);
          if (color is List) {
            expect(probes[i].$context?.jsRead('mode'), 'none');
          }
        }
        (probes[3].options! as ElementOptions).storeKey(
          OptionKey.borderWidth,
          77.0,
        );
        expect(jsGet(probes[4].options, 'borderWidth'), 1);
      });
    }

    test('an effectful parsed item ends the plan before its read', () {
      final states = <Object>[];
      final logs = <List<Object?>>[];
      for (final type in ['bubble', 'referenceBubble']) {
        final cfg = _config(
          type: type,
          backgroundColor: <ChartPaint>[red, blue],
        );
        final chart = _chart(cfg, reference: type != 'bubble');
        final probes = _probes(chart);
        final observed = _ObservedMap({'x': 3.0, 'y': 4.0, '_custom': 6.0});
        var changed = false;
        observed.onRead = (key) {
          if (key == 'y' && !changed) {
            changed = true;
            _dataset(cfg)['radius'] = 7.0;
            (_dataset(cfg)['backgroundColor']! as List<ChartPaint>)[0] = green;
            chart.config.clearCache();
          }
        };
        final meta = chart.getDatasetMeta(0);
        meta.parsed[3] = observed;
        meta.controller!.updateElements(meta.data, 0, _length, 'none');
        logs.add(List.of(observed.reads));
        if (type == 'bubble') {
          expect(probes[2].planReads, greaterThan(0));
          expect(probes[5].planReads, 0);
        }
        states.add(_observe(chart));
      }
      expect(logs[0], isNotEmpty);
      expect(logs[0], logs[1]);
      expect(states[0], states[1]);
    });

    test('a partial update keeps absolute indexes and untouched points', () {
      final a = _chart(_config(backgroundColor: <ChartPaint>[red, blue]));
      final b = _chart(
        _config(
          type: 'referenceBubble',
          backgroundColor: <ChartPaint>[red, blue],
        ),
        reference: true,
      );
      final probes = _probes(a);
      final others = _probes(b);
      for (final chart in [a, b]) {
        final meta = chart.getDatasetMeta(0);
        meta.controller!.updateElements(meta.data, 2, 5, 'none');
      }
      for (var i = 0; i < _length; i++) {
        expect(_plain(probes[i].options), _plain(others[i].options));
        expect(
          probes[i].$context?.jsRead('index'),
          others[i].$context?.jsRead('index'),
        );
      }
      expect(probes[4].planReads, greaterThan(0));
      expect(probes[0].$context, isNull);
      expect(probes[7].$context, isNull);
    });

    test('a stacked or reset update keeps the ordinary path', () {
      final chart = _chart(_config());
      final probes = _probes(chart);
      final meta = chart.getDatasetMeta(0);
      meta.controller!.updateElements(meta.data, 0, _length, 'reset');
      expect(probes.every((p) => p.planReads == 0), isTrue);
      expect(probes.every((p) => jsGet(p.options, 'radius') == 0), isTrue);
    });
  });

  test('overflow takes one set of fields with no size call or resolve', () {
    final cfg = _config();
    final chart = _chart(cfg);
    final probes = _probes(chart);
    final controller = chart.getDatasetMeta(0).controller!;
    final overflow = controller.getMaxOverflow();
    expect(probes.every((p) => p.sizeCalls == 0), isTrue);
    expect(probes.every((p) => p.planReads == 1), isTrue);

    final reference = _chart(_config(type: 'referenceBubble'), reference: true);
    final others = _probes(reference);
    expect(reference.getDatasetMeta(0).controller!.getMaxOverflow(), overflow);
    expect(others.every((p) => p.sizeCalls == 1), isTrue);
    expect(others.every((p) => p.planReads == 0), isTrue);
  });

  test('a cold overflow resolves its first item, then takes the entry', () {
    final chart = _chart(_config());
    final meta = chart.getDatasetMeta(0);
    final controller = meta.controller!..configure();
    final probes = _probes(chart);
    controller.getMaxOverflow();
    expect(probes.last.sizeCalls, 1);
    expect(probes.take(_length - 1).every((p) => p.sizeCalls == 0), isTrue);
  });

  test('an indexed overflow keeps each context write and the mode', () {
    final chart = _chart(_config(backgroundColor: <ChartPaint>[red, blue]));
    final meta = chart.getDatasetMeta(0);
    final controller = meta.controller!;
    final probes = _probes(chart);
    controller.getMaxOverflow();
    expect(probes[_length - 1].sizeCalls, 1);
    expect(probes[_length - 2].sizeCalls, 1);
    expect(probes.take(_length - 2).every((p) => p.sizeCalls == 0), isTrue);
    for (final point in probes) {
      expect(point.$context?.jsRead('mode'), 'default');
    }
    expect(probes[2].$context?.jsRead('index'), 2);
    expect(probes[2].$context?.jsRead('active'), isFalse);
  });

  group('the parse resolve', () {
    test('an item with its radius leaves out a resolve of an entry', () {
      for (final reference in [false, true]) {
        final cfg = _config(
          type: reference ? 'referenceBubble' : 'bubble',
          dataset: const {'radius': '5'},
        );
        final chart = _chart(cfg, reference: reference);
        final meta = chart.getDatasetMeta(0);
        final saved = foreignAudit;
        addTearDown(() => foreignAudit = saved);
        var stores = 0;
        foreignAudit = (owner, key, raw) {
          if (owner == 'PointOptions' && key == 'radius') stores++;
        };
        // A new data List drops the old parsed items, so that each ordinary
        // resolve joins the string radius: one foreign store for each resolve.
        _dataset(cfg)['data'] = _maps(step: 1);
        meta.controller!.buildOrUpdateElements(false);
        foreignAudit = saved;
        expect(stores, reference ? _length : 0);
        final parsed = meta.parsed.cast<ParsedItem>();
        expect(parsed.map((p) => p.custom), [
          for (var i = 0; i < _length; i++) 2.0 + i,
        ]);
      }
    });

    test('an item with no radius keeps its ordinary resolve', () {
      for (final reference in [false, true]) {
        final cfg = _config(
          type: reference ? 'referenceBubble' : 'bubble',
          dataset: const {'radius': '5'},
        );
        final chart = _chart(cfg, reference: reference);
        final meta = chart.getDatasetMeta(0);
        final saved = foreignAudit;
        addTearDown(() => foreignAudit = saved);
        var stores = 0;
        foreignAudit = (owner, key, raw) {
          if (owner == 'PointOptions' && key == 'radius') stores++;
        };
        final data = _maps(step: 1);
        (data[3]! as Map<String, Object?>).remove('r');
        (data[5]! as Map<String, Object?>)['r'] = null;
        _dataset(cfg)['data'] = data;
        meta.controller!.buildOrUpdateElements(false);
        foreignAudit = saved;
        expect(stores, reference ? _length : 1);
        final parsed = meta.parsed.cast<ParsedItem>();
        expect(parsed[3].custom, '05');
        expect(parsed[5].custom, isNull);
        expect(parsed[6].custom, 8.0);
      }
    });

    test('indexed colors keep the context writes of the resolve', () {
      final configs = _pair(
        (type) => _config(type: type, backgroundColor: <ChartPaint>[red, blue]),
      );
      final a = _chart(configs[0]);
      final b = _chart(configs[1], reference: true);
      final probes = _probes(a);
      final others = _probes(b);
      for (final cfg in configs) {
        _dataset(cfg)['data'] = _maps(step: 1);
      }
      a.getDatasetMeta(0).controller!.buildOrUpdateElements(false);
      b.getDatasetMeta(0).controller!.buildOrUpdateElements(false);
      for (var i = 0; i < _length; i++) {
        final context = probes[i].$context;
        final other = others[i].$context;
        expect(context, isNotNull);
        expect(context!.jsKeys(), other!.jsKeys());
        for (final key in context.jsKeys()) {
          if (key == 'element' || key == 'dataset' || key == 'chart') continue;
          expect(_plain(context.jsRead(key)), _plain(other.jsRead(key)));
        }
      }
      expect(probes.any((p) => p.planReads > 0), isTrue);
      expect(others.every((p) => p.planReads == 0), isTrue);
    });

    test('a scriptable radius keeps each call in the same order', () {
      final logs = <List<Object?>>[];
      final states = <Object>[];
      for (final type in ['bubble', 'referenceBubble']) {
        final calls = <Object?>[];
        double radius(Object? ctx) {
          calls.add([jsGet(ctx, 'dataIndex'), jsGet(ctx, 'mode')]);
          return 2 + (jsGet(ctx, 'dataIndex')! as num).toDouble();
        }

        final cfg = _config(type: type, dataset: {'radius': radius});
        final chart = _chart(cfg, reference: type != 'bubble');
        _dataset(cfg)['data'] = _maps(step: 1);
        chart.update('none');
        logs.add(calls);
        states.add(_observe(chart));
      }
      expect(logs[0], isNotEmpty);
      expect(logs[0], logs[1]);
      expect(states[0], states[1]);
    });

    test('an effectful item ends the skip before its read', () {
      final logs = <List<Object?>>[];
      final states = <Object>[];
      final counts = <int>[];
      for (final type in ['bubble', 'referenceBubble']) {
        final cfg = _config(type: type);
        final chart = _chart(cfg, reference: type != 'bubble');
        var calls = 0;
        double radius(Object? ctx) {
          calls++;
          return 4;
        }

        final data = _maps(step: 1);
        final observed = _ObservedMap({'x': 3.0, 'y': 1.0, 'r': 5.0});
        var changed = false;
        observed.onRead = (key) {
          if (key == 'r' && !changed) {
            changed = true;
            _dataset(cfg)['radius'] = radius;
            final controller = chart.getDatasetMeta(0).controller!;
            chart.config.clearCache();
            controller.configure();
          }
        };
        data[3] = observed;
        _dataset(cfg)['data'] = data;
        chart.getDatasetMeta(0).controller!.buildOrUpdateElements(false);
        logs.add(List.of(observed.reads));
        counts.add(calls);
        states.add([
          for (final p in chart.getDatasetMeta(0).parsed.cast<ParsedItem>())
            p.custom,
        ]);
      }
      expect(counts[0], greaterThan(0));
      expect(counts[0], counts[1]);
      expect(logs[0], logs[1]);
      expect(states[0], states[1]);
    });

    test('array items skip a resolve and keep their value', () {
      for (final reference in [false, true]) {
        final cfg = _config(
          type: reference ? 'referenceBubble' : 'bubble',
          dataset: const {'radius': '5'},
          data: [
            for (var i = 0; i < _length; i++)
              <double>[i.toDouble(), 1, 2.0 + i],
          ],
        );
        final chart = _chart(cfg, reference: reference);
        final meta = chart.getDatasetMeta(0);
        final saved = foreignAudit;
        addTearDown(() => foreignAudit = saved);
        var stores = 0;
        foreignAudit = (owner, key, raw) {
          if (owner == 'PointOptions' && key == 'radius') stores++;
        };
        _dataset(cfg)['data'] = <Object?>[
          for (var i = 0; i < _length; i++) <double>[i.toDouble(), 2, 3.0 + i],
          // A short item has no own radius: it resolves.
        ]..[2] = <double>[2, 2];
        meta.controller!.buildOrUpdateElements(false);
        foreignAudit = saved;
        expect(stores, reference ? _length : 1);
        final parsed = meta.parsed.cast<ParsedItem>();
        expect(parsed[2].custom, '05');
        expect(parsed[3].custom, 6.0);
      }
    });
  });

  group('a radius conversion with user code', () {
    /// `_custom` of an array item, with [custom] at index 4.
    List<Object?> arrays(_Custom custom) => [
      for (var i = 0; i < _length; i++)
        <Object?>[i.toDouble(), 1.0, if (i == 4) custom else 2.0 + i],
    ];

    /// The results that do not hold the object of one chart of a twin.
    List<Object?> radii(Chart chart) {
      final meta = chart.getDatasetMeta(0);
      return [
        for (final point in meta.data) jsGet(point.options, 'radius'),
        meta.controller!.getMaxOverflow(),
      ];
    }

    test('a radius option keeps each conversion of a parse resolve', () {
      allowForeign();
      final counts = <List<int>>[];
      final results = <Object?>[];
      for (final type in ['bubble', 'referenceBubble']) {
        final custom = _Custom();
        final cfg = _config(type: type, dataset: {'radius': custom});
        final chart = _chart(cfg, reference: type != 'bubble');
        final created = custom.calls;
        chart.update('none');
        final kept = custom.calls - created;
        // A new data List drops the old parsed items: each resolve converts.
        _dataset(cfg)['data'] = _maps(step: 1);
        chart.update('none');
        counts.add([created, kept, custom.calls - created - kept]);
        results.add(radii(chart));
      }
      expect(counts[0], counts[1]);
      expect(counts[1][0], greaterThanOrEqualTo(_length));
      expect(counts[1][2], greaterThanOrEqualTo(_length));
      expect(results[0], results[1]);
    });

    test('an old _custom of an item that stays keeps its conversion', () {
      allowForeign();
      final counts = <List<int>>[];
      final results = <Object?>[];
      for (final type in ['bubble', 'referenceBubble']) {
        final custom = _Custom();
        final cfg = _config(type: type, data: arrays(custom));
        final chart = _chart(cfg, reference: type != 'bubble');
        final created = custom.calls;
        chart.update('none');
        counts.add([created, custom.calls - created]);
        results.add(radii(chart));
      }
      expect(counts[0], counts[1]);
      expect(results[0], results[1]);
    });

    test('an old _custom of a replaced item keeps its conversion', () {
      allowForeign();
      final counts = <int>[];
      final results = <Object?>[];
      for (final type in ['bubble', 'referenceBubble']) {
        final custom = _Custom();
        final data = arrays(custom);
        final cfg = _config(type: type, data: data);
        final chart = _chart(cfg, reference: type != 'bubble');
        final meta = chart.getDatasetMeta(0);
        data[4] = <Object?>[4.0, 1.0, 2.0];
        final before = custom.calls;
        meta.controller!.buildOrUpdateElements(false);
        counts.add(custom.calls - before);
        results.add([for (final p in meta.parsed.cast<ParsedItem>()) p.custom]);
      }
      expect(counts[1], 1);
      expect(counts[0], counts[1]);
      expect(results[0], results[1]);
    });

    test('a new foreign item[2] with no old _custom keeps the twin', () {
      allowForeign();
      final counts = <int>[];
      final results = <Object?>[];
      for (final type in ['bubble', 'referenceBubble']) {
        final custom = _Custom();
        final cfg = _config(type: type);
        final chart = _chart(cfg, reference: type != 'bubble');
        final meta = chart.getDatasetMeta(0);
        _dataset(cfg)['data'] = arrays(custom);
        meta.controller!.buildOrUpdateElements(false);
        counts.add(custom.calls);
        results.add([
          for (final p in meta.parsed.cast<ParsedItem>())
            if (identical(p.custom, custom)) 'custom' else p.custom,
        ]);
      }
      expect(counts[1], 0);
      expect(counts[0], counts[1]);
      expect(results[0], results[1]);
    });

    test('an old _custom of an item with no radius ends the skip first', () {
      allowForeign();
      final counts = <int>[];
      final results = <Object?>[];
      for (final type in ['bubble', 'referenceBubble']) {
        final custom = _Custom();
        final data = arrays(custom);
        final cfg = _config(type: type, data: data);
        final chart = _chart(cfg, reference: type != 'bubble');
        final meta = chart.getDatasetMeta(0);
        var calls = 0;
        double radius(Object? ctx) {
          calls++;
          return 4;
        }

        data[4] = <Object?>[4.0, 1.0];
        custom.onConvert = () {
          custom.onConvert = null;
          _dataset(cfg)['radius'] = radius;
          chart.config.clearCache();
          meta.controller!.configure();
        };
        meta.controller!.buildOrUpdateElements(false);
        counts.add(calls);
        results.add([for (final p in meta.parsed.cast<ParsedItem>()) p.custom]);
      }
      expect(counts[1], greaterThan(0));
      expect(counts[0], counts[1]);
      expect(results[0], results[1]);
    });

    test('a radius option leaves the constant plan out of the update', () {
      allowForeign();
      List<Object?> items() => [
        for (var i = 0; i < _length; i++)
          <String, Object?>{'x': i.toDouble(), 'y': 1.0},
      ];
      for (var n = 1; n <= _length; n++) {
        final widths = <List<Object?>>[];
        final probed = <bool>[];
        for (final type in ['bubble', 'referenceBubble']) {
          final custom = _Custom();
          final cfg = _config(
            type: type,
            parsing: false,
            data: items(),
            dataset: {'radius': custom},
          );
          final chart = _chart(cfg, reference: type != 'bubble');
          final probes = _probes(chart);
          final meta = chart.getDatasetMeta(0);
          var left = n;
          custom.onConvert = () {
            if (--left != 0) return;
            _dataset(cfg)['borderWidth'] = 7.0;
            chart.config.clearCache();
            meta.controller!.configure();
          };
          meta.controller!.updateElements(meta.data, 0, _length, 'none');
          custom.onConvert = null;
          widths.add([
            for (final point in meta.data) jsGet(point.options, 'borderWidth'),
          ]);
          probed.add(probes.any((p) => p.planReads > 0));
        }
        expect(widths[0], widths[1], reason: 'conversion $n');
        expect(probed, [false, false], reason: 'conversion $n');
      }
    });

    test('a primitive radius option keeps the constant plan', () {
      allowForeign();
      List<Object?> items() => [
        for (var i = 0; i < _length; i++)
          <String, Object?>{'x': i.toDouble(), 'y': 1.0},
      ];
      final results = <Object>[];
      final probed = <bool>[];
      for (final type in ['bubble', 'referenceBubble']) {
        final cfg = _config(
          type: type,
          parsing: false,
          data: items(),
          dataset: const {'radius': '5'},
        );
        final chart = _chart(cfg, reference: type != 'bubble');
        final probes = _probes(chart);
        final meta = chart.getDatasetMeta(0);
        meta.controller!.updateElements(meta.data, 0, _length, 'none');
        probed.add(probes.any((p) => p.planReads > 0));
        results.add(_observe(chart));
      }
      expect(probed, [true, false]);
      expect(results[0], results[1]);
    });
  });

  group('guards keep the ordinary path', () {
    test('a user subclass keeps each resolve', () {
      _CountingBubble.resolves = 0;
      final cfg = _config(type: 'countingBubble');
      final chart = _chart(cfg);
      final created = _CountingBubble.resolves;
      // Two overflow passes, the parse in the first update, the first resolve
      // and the update loop of each chart update.
      expect(created, greaterThanOrEqualTo(_length * 3));
      _CountingBubble.resolves = 0;
      _dataset(cfg)['data'] = _maps(step: 1);
      chart.update('none');
      expect(_CountingBubble.resolves, _length * 4 + 1);
    });

    test('a custom size keeps its call for each point and ends the plan', () {
      final values = <Object?>[];
      final states = <Object>[];
      for (final type in ['bubble', 'referenceBubble']) {
        final cfg = _config(type: type);
        final chart = _chart(cfg, reference: type != 'bubble');
        final probes = _probes(chart);
        final custom = _CustomSize()
          ..afterSize = () {
            _dataset(cfg)['radius'] = 9.0;
            chart.config.clearCache();
            chart.getDatasetMeta(0).controller!.configure();
          };
        chart.getDatasetMeta(0).data[4] = custom;
        values.add(chart.getDatasetMeta(0).controller!.getMaxOverflow());
        states.add(_observe(chart));
        expect(custom.calls, 2);
        expect(probes[3].planReads, 0);
      }
      expect(values[0], values[1]);
      expect(states[0], states[1]);
    });

    test('a user PointElement class overrides size at each point', () {
      for (final type in ['bubble', 'referenceBubble']) {
        final chart = _chart(_config(type: type), reference: type != 'bubble');
        final points = chart.getDatasetMeta(0).data;
        final customs = [
          for (var i = 0; i < points.length; i++) points[i] = _CustomSize(),
        ];
        chart.getDatasetMeta(0).controller!.getMaxOverflow();
        expect(customs.every((p) => p.calls == 1), isTrue);
      }
    });

    test('indexed radius and borderWidth keep ordinary resolution', () {
      for (final options in [
        <String, Object?>{
          'radius': <double>[2, 4],
        },
        <String, Object?>{
          'borderWidth': <double>[1, 3],
        },
      ]) {
        final configs = _pair(
          (type) => _config(
            type: type,
            dataset: options,
            backgroundColor: <ChartPaint>[red, blue],
          ),
        );
        final a = _chart(configs[0]);
        final b = _chart(configs[1], reference: true);
        final probes = _probes(a);
        _probes(b);
        for (final cfg in configs) {
          _dataset(cfg)['data'] = _maps(step: 1);
        }
        a.update('none');
        b.update('none');
        expect(_observe(a), _observe(b));
        expect(probes.every((p) => p.planReads == 0), isTrue);
      }
    });

    test('an active point callback ends prepared resolution', () {
      final states = <Object>[];
      final logs = <List<Object?>>[];
      for (final type in ['bubble', 'referenceBubble']) {
        final cfg = _config(
          type: type,
          backgroundColor: <ChartPaint>[red, blue],
        );
        final calls = <Object?>[];
        ChartPaint hover(Object? ctx) {
          calls.add(jsGet(ctx, 'dataIndex'));
          return green;
        }

        _dataset(cfg)['hoverBackgroundColor'] = hover;
        final chart = _chart(cfg, reference: type != 'bubble');
        final probes = _probes(chart);
        probes[4].active = true;
        final meta = chart.getDatasetMeta(0);
        calls.clear();
        meta.controller!.updateElements(meta.data, 0, _length, 'none');
        logs.add(List.of(calls));
        states.add(_observe(chart));
        if (type == 'bubble') {
          expect(probes[3].planReads, greaterThan(0));
          // The plan ends at the active point; overflow starts its own later.
          expect(probes[6].planReads, 0);
        }
      }
      expect(logs[0], isNotEmpty);
      expect(logs[0], logs[1]);
      expect(states[0], states[1]);
    });

    test('an active point takes the default options in overflow', () {
      final configs = _pair((type) => _config(type: type));
      final a = _chart(configs[0]);
      final b = _chart(configs[1], reference: true);
      (a.getDatasetMeta(0).data[2] as PointElement).active = true;
      (b.getDatasetMeta(0).data[2] as PointElement).active = true;
      expect(
        a.getDatasetMeta(0).controller!.getMaxOverflow(),
        b.getDatasetMeta(0).controller!.getMaxOverflow(),
      );
    });

    test('a custom projection keeps ordinary option resolution', () {
      Chart.register([_CustomScale.value]);
      addTearDown(() => Chart.unregister([_CustomScale.value]));
      final states = <Object>[];
      for (final type in ['bubble', 'referenceBubble']) {
        final cfg = _config(type: type);
        final scales = (cfg['options']! as Map)['scales']! as Map;
        (scales['y']! as Map)['type'] = 'bubble-custom-scale';
        final chart = _chart(cfg, reference: type != 'bubble');
        final probes = _probes(chart);
        final meta = chart.getDatasetMeta(0);
        meta.controller!.updateElements(meta.data, 0, _length, 'none');
        expect(probes.every((p) => p.planReads == 0), isTrue);
        states.add(_observe(chart));
      }
      expect(states[0], states[1]);
    });

    test('foreign radius and hover radius keep the options object', () {
      for (final options in [
        <String, Object?>{'radius': '5'},
        <String, Object?>{'hoverRadius': '7'},
        <String, Object?>{'borderWidth': '3'},
      ]) {
        final configs = _pair(
          (type) => _config(
            type: type,
            dataset: options,
            data: [
              for (var i = 0; i < _length; i++)
                <String, Object?>{'x': i.toDouble(), 'y': 1.0},
            ],
          ),
        );
        final a = _chart(configs[0]);
        final b = _chart(configs[1], reference: true);
        final saved = foreignAudit;
        addTearDown(() => foreignAudit = saved);
        foreignAudit = (_, _, _) {};
        expect(_observe(a), _observe(b));
        a.update('none');
        b.update('none');
        expect(_observe(a), _observe(b));
        foreignAudit = saved;
      }
    });
  });

  group('the parsed values of a native overflow', () {
    test('a data item with no r takes the default radius', () {
      for (final parsing in [null, false]) {
        final configs = _pair(
          (type) => _config(
            type: type,
            parsing: parsing,
            data: [
              for (var i = 0; i < _length; i++)
                if (i.isEven)
                  DataPoint(i.toDouble(), 1.0)
                else
                  DataPoint.bubble(i.toDouble(), 1.0, 2.0 + i),
            ],
          ),
        );
        final a = _chart(configs[0]);
        final b = _chart(configs[1], reference: true);
        expect(_observe(a), _observe(b));
        // The default radius of `controller.bubble.js:165`: 3 and its border.
        final options = a.getDatasetMeta(0).data[0].options! as PointOptions;
        expect(options.radius, 3);
      }
    });

    test('a null item throws as upstream under the default parsing keys', () {
      final data = _maps(step: 1)..[3] = null;
      for (final parsing in [null, false]) {
        for (final type in ['bubble', 'referenceBubble']) {
          expect(
            () => _chart(
              _config(
                type: type,
                parsing: parsing,
                data: List<Object?>.of(data),
              ),
              reference: type != 'bubble',
            ),
            throwsA(isA<TypeError>()),
          );
        }
      }
    });

    test('a null item gives a null radius with the empty parsing keys', () {
      final data = _maps(step: 1)..[3] = null;
      final configs = _pair(
        (type) => _config(
          type: type,
          parsing: <String, Object?>{'xAxisKey': '', 'yAxisKey': ''},
          data: List<Object?>.of(data),
        ),
      );
      final a = _chart(configs[0]);
      final b = _chart(configs[1], reference: true);
      for (final cfg in configs) {
        _dataset(cfg)['data'] = List<Object?>.of(data);
      }
      a.update('none');
      b.update('none');
      expect(_observe(a), _observe(b));
      final parsed = a.getDatasetMeta(0).parsed.cast<ParsedItem>();
      expect(parsed[3].custom, isNull);
      expect(parsed[4].custom, 6.0);
    });

    test('NaN, zero and negative radii follow the ordinary formula', () {
      final radii = <Object?>[double.nan, 0.0, -0.0, -2.0, 4.0, 1e300];
      final data = [
        for (var i = 0; i < radii.length; i++)
          <String, Object?>{'x': i.toDouble(), 'y': 1.0, '_custom': radii[i]},
      ];
      final configs = _pair(
        (type) => _config(
          type: type,
          parsing: false,
          data: [for (final item in data) Map<String, Object?>.of(item)],
        ),
      );
      final a = _chart(configs[0]);
      final b = _chart(configs[1], reference: true);
      expect(_observe(a), _observe(b));
    });

    test('a string _custom joins in the ordinary path', () {
      final saved = foreignAudit;
      addTearDown(() => foreignAudit = saved);
      foreignAudit = (_, _, _) {};
      final configs = _pair(
        (type) => _config(
          type: type,
          parsing: false,
          data: [
            for (var i = 0; i < _length; i++)
              <String, Object?>{
                'x': i.toDouble(),
                'y': 1.0,
                '_custom': i == 3 ? '7' : 2.0,
              },
          ],
        ),
      );
      final a = _chart(configs[0]);
      final b = _chart(configs[1], reference: true);
      expect(_observe(a), _observe(b));
      expect(jsGet(a.getDatasetMeta(0).data[3].options, 'radius'), '07');
      foreignAudit = saved;
    });

    test('the size formula keeps its result over the option values', () {
      for (final radius in <double>[0, 3, -2]) {
        for (final hoverRadius in <double>[0, 4, -1, double.nan]) {
          for (final borderWidth in <double>[0, 1, -3, double.nan]) {
            final options = <String, Object?>{
              'radius': radius,
              'hoverRadius': hoverRadius,
              'borderWidth': borderWidth,
            };
            for (final parsing in [null, false]) {
              final configs = _pair(
                (type) => _config(
                  type: type,
                  parsing: parsing,
                  dataset: options,
                  data: [
                    for (var i = 0; i < _length; i++)
                      if (i.isEven)
                        DataPoint(i.toDouble(), 1.0)
                      else
                        DataPoint.bubble(i.toDouble(), 1.0, i - 3.0),
                  ],
                ),
              );
              final a = _chart(configs[0]);
              final b = _chart(configs[1], reference: true);
              a.update('none');
              b.update('none');
              expect(_observe(a), _observe(b), reason: '$options, $parsing');
            }
          }
        }
      }
    });

    test('a user object in _custom keeps its conversion and its order', () {
      final logs = <List<String>>[];
      for (final type in ['bubble', 'referenceBubble']) {
        final log = <String>[];
        final cfg = _config(
          type: type,
          parsing: false,
          data: [
            for (var i = 0; i < _length; i++)
              <String, Object?>{
                'x': i.toDouble(),
                'y': 1.0,
                '_custom': i == 3 ? _Custom(log) : 2.0,
              },
          ],
        );
        final saved = foreignAudit;
        addTearDown(() => foreignAudit = saved);
        foreignAudit = (_, _, _) {};
        final chart = _chart(cfg, reference: type != 'bubble');
        log.clear();
        chart.update('none');
        foreignAudit = saved;
        logs.add(log);
      }
      expect(logs[0], logs[1]);
    });
  });

  for (final color in <ChartValue<ChartPaint>>[
    const ChartValue.constant(blue),
    const ChartValue.indexed([red, blue]),
  ]) {
    testWidgets('a ChartView with parsing false takes each native loop, '
        '${color.runtimeType}', (tester) async {
      Chart? chart;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 400,
            height: 300,
            child: ChartView(
              updateMode: 'none',
              theme: const ChartThemeData(),
              excludeFromSemantics: true,
              onChartCreated: (created) => chart = created,
              config: ChartConfig(
                type: .bubble,
                datasets: [
                  BubbleDataset(
                    points: [
                      for (var i = 0; i < _length; i++)
                        DataPoint.bubble(i.toDouble(), 1.0, 2.0 + i),
                    ],
                    backgroundColor: color,
                    borderWidth: 0,
                  ),
                ],
                animation: ChartAnimation.none,
                extra: const {'parsing': false},
              ),
            ),
          ),
        ),
      );
      final live = chart!;
      final meta = live.getDatasetMeta(0);
      final probes = _probes(live);
      live.update('none');
      expect(probes.every((p) => p.planReads > 0), isTrue);
      // Only its draw: neither overflow pass called `size` on this point.
      expect(probes[0].sizeCalls, 1);
      expect(jsGet(probes[3].options, 'radius'), 5);
      expect(meta.parsed.first, isA<DataPoint>());
      live.stop();
    });
  }

  group('adapt-bubble-typed-radius', () {
    test('DataPoint.bubble gives its radius under parsing false', () {
      final cfg = _config(parsing: false, data: _points());
      final chart = _chart(cfg);
      final meta = chart.getDatasetMeta(0);
      final point = meta.data[3] as PointElement;
      expect((point.options! as PointOptions).radius, 5);
      final label = meta.controller!.getLabelAndValue(3);
      expect(label.value, contains(', 5)'));
      // The last radius 9 and the border width 1.
      expect(chart.getDatasetMeta(0).controller!.getMaxOverflow(), 10);
    });

    test('a Map item keeps the default radius of upstream', () {
      final chart = _chart(_config(parsing: false));
      final meta = chart.getDatasetMeta(0);
      expect((meta.data[3].options! as PointOptions).radius, 3);
      expect(meta.controller!.getLabelAndValue(3).value, isNot(contains('5')));
    });

    test('a Map item with _custom keeps its own radius', () {
      final chart = _chart(
        _config(
          parsing: false,
          data: [
            for (var i = 0; i < _length; i++)
              <String, Object?>{'x': i.toDouble(), 'y': 1.0, '_custom': 6.0},
          ],
        ),
      );
      final meta = chart.getDatasetMeta(0);
      expect((meta.data[3].options! as PointOptions).radius, 6);
    });

    test('a typed config with parsing false draws the radius of each item', () {
      List<DataPoint> points() => [
        for (var i = 0; i < _length; i++)
          DataPoint.bubble(i.toDouble(), 1.0, 2.0 + i),
      ];
      final parsed = Chart(
        UiCanvasElement(width: 640, height: 400),
        ChartConfigLowering(
          ChartConfig(
            type: .bubble,
            datasets: [BubbleDataset(points: points())],
            animation: ChartAnimation.none,
          ),
        ).lower(),
      );
      addTearDown(parsed.destroy);
      final raw = Chart(
        UiCanvasElement(width: 640, height: 400),
        ChartConfigLowering(
          ChartConfig(
            type: .bubble,
            datasets: [BubbleDataset(points: points())],
            animation: ChartAnimation.none,
            extra: const {'parsing': false},
          ),
        ).lower(),
      );
      addTearDown(raw.destroy);
      final first = parsed.getDatasetMeta(0);
      final second = raw.getDatasetMeta(0);
      expect(second.parsed.first, isA<DataPoint>());
      expect(first.parsed.first, isA<ParsedItem>());
      for (var i = 0; i < _length; i++) {
        expect(_plain(second.data[i].options), _plain(first.data[i].options));
        expect(
          (second.data[i] as PointElement).x,
          (first.data[i] as PointElement).x,
        );
        expect(
          (second.data[i] as PointElement).y,
          (first.data[i] as PointElement).y,
        );
      }
      expect(
        second.controller!.getMaxOverflow(),
        first.controller!.getMaxOverflow(),
      );
    });
  });
}

/// A test that stores a user object in typed options on purpose: its pairs are
/// not reviewed foreign pairs. The hook comes back at the end of the test.
void allowForeign() {
  final saved = foreignAudit;
  addTearDown(() => foreignAudit = saved);
  foreignAudit = (_, _, _) {};
}

/// A user object whose JS conversion runs user code.
class _Custom([List<String>? log]) {
  final List<String> log = log ?? [];

  /// Runs at each conversion, as a `toString` of the user can.
  void Function()? onConvert;

  int get calls => log.length;

  @override
  String toString() {
    log.add('toString');
    onConvert?.call();
    return '4';
  }
}
