// Original code, not ported from Chart.js: native line option-loop twins.
@TestOn('vm')
library;

import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/core/core.scale.dart' show scaleCfgArg;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/options/element_options_base.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
import 'package:flutter_test/flutter_test.dart';

const red = ChartPaint.solid(ui.Color(0xffff0000));
const blue = ChartPaint.solid(ui.Color(0xff0000ff));
const green = ChartPaint.solid(ui.Color(0xff00ff00));

class _ReferenceChart(super.item, super.userConfig) extends Chart {
  @override
  bool get supportsNativePointOptions => false;
}

// Explicit test opt-in: counters only, with native size/context/property behavior.
class _ProbePoint() extends PointElement {
  int planReads = 0;
  @override
  bool get supportsNativePointOptions {
    planReads++;
    return true;
  }

  @override
  bool get typedWrites => true;
}

class _CustomScale(super.cfg) extends LinearScale {
  int calls = 0;
  static final value = JsClass(
    'ScatterCustomScale',
    superclass: LinearScale.jsClass,
    statics: {'id': 'scatter-custom-scale'},
    construct: (_, args) => _CustomScale(scaleCfgArg(args)),
  );
  @override
  double getPixelForValue(Object? value, [double? index]) {
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

Map<String, Object?> _config({bool line = false, int datasets = 1}) => {
  'type': 'line',
  'data': <String, Object?>{
    'datasets': <Object?>[
      for (var d = 0; d < datasets; d++)
        <String, Object?>{
          'data': <Object?>[
            for (var i = 0; i < 8; i++)
              <String, Object?>{'x': i.toDouble(), 'y': (i - 3).toDouble()},
          ],
          'backgroundColor': <ChartPaint>[if (d == 0) red else green, blue],
          'borderColor': blue,
          'radius': 3.0,
          'borderWidth': 1.0,
          'showLine': line,
        },
    ],
  },
  'options': <String, Object?>{
    'responsive': false,
    'animation': false,
    'parsing': false,
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
Map<String, Object?> _dataset(Map<String, Object?> cfg, [int index = 0]) =>
    ((cfg['data']! as Map<String, Object?>)['datasets']!
            as List<Object?>)[index]!
        as Map<String, Object?>;
Chart _chart(Object cfg, {bool reference = false}) {
  final canvas = UiCanvasElement(width: 640, height: 400);
  final chart = reference ? _ReferenceChart(canvas, cfg) : Chart(canvas, cfg);
  addTearDown(chart.destroy);
  return chart;
}

List<_ProbePoint> _probes(Chart chart, [int dataset = 0]) {
  final points = chart.getDatasetMeta(dataset).data;
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

Object _observe(Chart chart, [int dataset = 0]) => [
  for (final point in chart.getDatasetMeta(dataset).data.cast<PointElement>())
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Chart.register([
    LineController.jsClass,
    PointElement.jsClass,
    LineElement.jsClass,
    LinearScale.jsClass,
  ]);

  for (final line in [false, true]) {
    test(
      'fresh indexed options and contexts across updates, showLine=$line',
      () {
        final ca = _config(line: line, datasets: 2);
        final cb = _config(line: line, datasets: 2);
        final a = _chart(ca);
        final b = _chart(cb, reference: true);
        final probes = [_probes(a), _probes(a, 1)];
        for (var step = 0; step < 3; step++) {
          for (final cfg in [ca, cb]) {
            for (var d = 0; d < 2; d++) {
              final ds = _dataset(cfg, d);
              (ds['backgroundColor']! as List<ChartPaint>)[0] =
                  ChartPaint.solid(ui.Color(0xff001100 + step + d));
              ((ds['data']! as List<Object?>)[3]!
                  as Map<String, Object?>)['y'] = step
                  .toDouble();
            }
          }
          a.update('none');
          b.update('none');
          for (var d = 0; d < 2; d++) {
            expect(_observe(a, d), _observe(b, d));
            expect(
              identical(probes[d][3].options, probes[d][4].options),
              isFalse,
            );
            expect(jsGet(probes[d][3].options, r'$shared'), isFalse);
            (probes[d][3].options! as ElementOptions).storeKey(
              OptionKey.radius,
              77.0,
            );
          }
        }
        expect(probes.expand((x) => x).any((p) => p.planReads > 0), isTrue);
      },
    );
  }

  test('effectful parsed reads terminate reuse before conversion', () {
    final states = <Object>[];
    final logs = <List<Object?>>[];
    for (final reference in [false, true]) {
      final cfg = _config();
      final chart = _chart(cfg, reference: reference);
      final probes = _probes(chart);
      final observed = _ObservedMap({'x': 3.0, 'y': 4.0});
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
      meta.controller!.updateElements(meta.data, 0, 8, 'none');
      logs.add(List.of(observed.reads));
      states.add(_observe(chart));
      if (!reference) {
        expect(probes[2].planReads, greaterThan(0));
        expect(probes[5].planReads, 0);
      }
    }
    expect(logs[0], logs[1]);
    expect(states[0], states[1]);
  });

  test('active point callback sees geometry and ends prepared resolution', () {
    final states = <Object>[];
    final logs = <List<Object?>>[];
    for (final reference in [false, true]) {
      final cfg = _config();
      final calls = <Object?>[];
      ChartPaint hover(Object? ctx) {
        final e = jsGet(ctx, 'element')! as PointElement;
        calls.add([jsGet(ctx, 'dataIndex'), e.x, e.y]);
        return green;
      }

      _dataset(cfg)['hoverBackgroundColor'] = hover;
      final chart = _chart(cfg, reference: reference);
      final probes = _probes(chart);
      probes[4].active = true;
      final meta = chart.getDatasetMeta(0);
      meta.controller!.updateElements(meta.data, 0, 8, 'none');
      logs.add(calls);
      states.add(_observe(chart));
      if (!reference) {
        expect(probes[3].planReads, greaterThan(0));
        expect(probes[6].planReads, 0);
      }
    }
    expect(logs[0], isNotEmpty);
    expect(logs[0], logs[1]);
    expect(states[0], states[1]);
  });

  test('scriptable and indexed numeric options preserve ordinary calls', () {
    for (final callback in [false, true]) {
      final states = <Object>[];
      final counts = <int>[];
      for (final reference in [false, true]) {
        final cfg = _config();
        var calls = 0;
        double radius(Object? ctx) {
          calls++;
          return 2 + (jsGet(ctx, 'dataIndex')! as num).toDouble();
        }

        _dataset(cfg)['radius'] = callback ? radius : <double>[2, 4];
        final chart = _chart(cfg, reference: reference);
        final probes = _probes(chart);
        calls = 0;
        chart.update('none');
        states.add(_observe(chart));
        counts.add(calls);
        expect(probes.every((p) => p.planReads == 0), isTrue);
      }
      expect(states[0], states[1]);
      expect(counts[0], counts[1]);
    }
  });

  test('partial updates keep absolute indices and untouched points', () {
    final a = _chart(_config());
    final b = _chart(_config(), reference: true);
    final probes = _probes(a);
    _probes(b);
    for (final chart in [a, b]) {
      final meta = chart.getDatasetMeta(0);
      meta.controller!.updateElements(meta.data, 2, 5, 'none');
    }
    expect(_observe(a), _observe(b));
    expect(probes[4].planReads, greaterThan(0));
    expect(probes[0].$context, isNull);
    expect(probes[7].$context, isNull);
  });

  test('custom class id getters retain their ordinary read count', () {
    final states = <Object>[];
    final counts = <int>[];
    for (final reference in [false, true]) {
      final chart = _chart(_config(), reference: reference);
      final probes = _probes(chart);
      final cls = _ObservedMap({'id': 'point'});
      final meta = chart.getDatasetMeta(0);
      (meta.controller! as LineController)
        ..dataElementType = cls
        ..getMaxOverflow()
        ..updateElements(meta.data, 0, 8, 'none');
      counts.add(cls.reads.length);
      states.add(_observe(chart));
      expect(probes.every((p) => p.planReads == 0), isTrue);
    }
    expect(counts[0], counts[1]);
    expect(states[0], states[1]);
  });

  test('custom scale projections retain ordinary option resolution', () {
    Chart.register([_CustomScale.value]);
    addTearDown(() => Chart.unregister([_CustomScale.value]));
    final states = <Object>[];
    final calls = <int>[];
    for (final reference in [false, true]) {
      final cfg = _config();
      final scales = (cfg['options']! as Map)['scales']! as Map;
      (scales['y']! as Map)['type'] = 'scatter-custom-scale';
      final chart = _chart(cfg, reference: reference);
      final probes = _probes(chart);
      final scale = (chart.scales['y']! as _CustomScale)..calls = 0;
      final meta = chart.getDatasetMeta(0);
      meta.controller!.updateElements(meta.data, 0, 8, 'none');
      expect(probes.every((p) => p.planReads == 0), isTrue);
      calls.add(scale.calls);
      states.add(_observe(chart));
    }
    expect(calls[0], greaterThan(0));
    expect(calls[0], calls[1]);
    expect(states[0], states[1]);
  });
  test(
    'warm identity slots survive replacement, resizing and mode changes',
    () {
      final ca = _config(line: true);
      final cb = _config(line: true);
      final a = _chart(ca);
      final b = _chart(cb, reference: true);
      for (var step = 0; step < 9; step++) {
        for (final cfg in [ca, cb]) {
          final ds = _dataset(cfg);
          final data = ds['data']! as List<Object?>;
          switch (step) {
            case 1:
              (data[4]! as Map<String, Object?>)['y'] = null;
            case 2:
              (data[4]! as Map<String, Object?>)['y'] = '2';
            case 3:
              ds['data'] = <Object?>[
                for (var i = 0; i < 12; i++)
                  <String, double>{'x': i / 2, 'y': i / 3},
              ];
            case 4:
              data.removeRange(5, data.length);
            case 5:
              ds['backgroundColor'] = green;
            case 6:
              ds['backgroundColor'] = <ChartPaint>[green, red];
              ds['data'] = <Object?>[
                ...data,
                for (var i = 5; i < 10; i++)
                  <String, Object?>{'x': i / 2, 'y': -0.0},
              ];
            case 7:
              for (var i = 0; i < data.length; i += 2) {
                data[i] = Map<String, Object?>.of(
                  data[i]! as Map<String, Object?>,
                );
              }
            case 8:
              data[3] = _ObservedMap({'x': 1.5, 'y': 2.0});
          }
        }
        final mode = step == 5 ? 'reset' : 'none';
        a.update(mode);
        b.update(mode);
        expect(_observe(a), _observe(b), reason: 'step $step');
        for (final chart in [a, b]) {
          final meta = chart.getDatasetMeta(0);
          meta.controller!.updateElements(meta.data, 1, 4, 'none');
        }
        expect(_observe(a), _observe(b), reason: 'partial step $step');
      }
    },
  );

  test(
    'warm cache preserves active callback mutation, failure and recovery',
    () {
      final states = <Object>[];
      final logs = <List<Object?>>[];
      for (final reference in [false, true]) {
        final cfg = _config();
        final ds = _dataset(cfg);
        final calls = <Object?>[];
        var fail = false;
        ChartPaint hover(Object? context) {
          calls.add(jsGet(context, 'dataIndex'));
          if (fail) throw StateError('hover failure');
          ((ds['data']! as List<Object?>)[6]! as Map<String, Object?>)['y'] =
              '3';
          (ds['backgroundColor']! as List<ChartPaint>)[0] = green;
          return green;
        }

        ds['hoverBackgroundColor'] = hover;
        final chart = _chart(cfg, reference: reference)
          ..update('none')
          ..update('none');
        final meta = chart.getDatasetMeta(0);
        final point = (meta.data[4] as PointElement)..active = true;
        fail = true;
        expect(
          () => meta.controller!.updateElements(meta.data, 0, 8, 'none'),
          throwsStateError,
        );
        fail = false;
        meta.controller!.updateElements(meta.data, 0, 8, 'none');
        states.add(_observe(chart));
        point.active = false;
        chart.update('none');
        states.add(_observe(chart));
        ((ds['data']! as List<Object?>)[6]! as Map<String, Object?>)['y'] = 3.0;
        chart.update('none');
        states.add(_observe(chart));
        logs.add(calls);
      }
      expect(states.sublist(0, 3), states.sublist(3));
      expect(logs[0], logs[1]);
      expect(logs[0], [4.0, 4.0]);
    },
  );
}
