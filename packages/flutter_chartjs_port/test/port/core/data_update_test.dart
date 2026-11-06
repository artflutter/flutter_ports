// Original code, not ported from Chart.js: incremental-update reference twins.
@TestOn('vm')
library;

import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart' as typed;
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui_text.dart'
    show invalidateCanvasTextMetrics;
import 'package:flutter_chartjs_port/src/core/core.scale.dart' show scaleCfgArg;
import 'package:flutter_chartjs_port/src/core/data_update.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/platform/native_event.dart';
import 'package:flutter_chartjs_port/src/typed/lower.dart'
    show ChartConfigLowering;
import 'package:flutter_chartjs_port/src/types/data_item.dart'
    show TypedDataItem;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_chartjs_port/src/types/plugin.dart' show Plugin;
import 'package:flutter_test/flutter_test.dart';

final class _ObservedList extends ListBase<Object?> {
  _ObservedList(this.values);
  final List<Object?> values;
  int reads = 0;
  @override
  int get length {
    reads++;
    return values.length;
  }

  @override
  set length(int n) => values.length = n;
  @override
  Object? operator [](int i) {
    reads++;
    return values[i];
  }

  @override
  void operator []=(int i, Object? value) => values[i] = value;
}

class _CustomLinear extends LinearScale {
  _CustomLinear(super.cfg);
  static final value = JsClass(
    'DataCustomLinear',
    superclass: LinearScale.jsClass,
    statics: {'id': 'data-custom-linear'},
    construct: (_, args) => _CustomLinear(scaleCfgArg(args)),
  );
}

/// A point class that the typed lowering does not register.
final class _OtherPoint implements TypedDataItem {
  @override
  Object get x => 1.0;
  @override
  double? get y => 2;
  @override
  double? get r => null;
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Event implements types.ChartEvent {
  _Event(this.x, this.y)
    : native = NativeEvent(type: 'mousemove', offsetX: x!, offsetY: y!);
  @override
  String get type => 'mousemove';
  @override
  final double? x;
  @override
  final double? y;
  @override
  final NativeEvent native;
  @override
  types.Chart? get chart => null;
}

Map<String, Object?> config(
  String type, {
  bool bounded = true,
  bool prepared = false,
  bool horizontal = false,
  List<Object?> plugins = const [],
}) {
  final radial = type == 'radar' || type == 'polarArea';
  final circle = type == 'doughnut' || type == 'pie';
  final xy = type == 'scatter' || type == 'bubble' || prepared;
  return {
    'type': type,
    'data': <String, Object?>{
      'labels': <String>['a', 'b', 'c', 'd'],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            for (var i = 0; i < 4; i++)
              if (xy)
                <String, Object?>{
                  'x': i.toDouble(),
                  'y': i + 1.0,
                  if (type == 'bubble') 'r': 2.0,
                }
              else
                i + 1.0,
          ],
          'backgroundColor': const ui.Color(0x803366aa),
          'borderColor': const ui.Color(0xff3366aa),
          'borderWidth': 1.0,
          if (prepared) 'parsing': false,
        },
      ],
    },
    'options': <String, Object?>{
      'responsive': false,
      'animation': false,
      'indexAxis': horizontal ? 'y' : 'x',
      'plugins': <String, Object?>{
        'legend': false,
        'tooltip': false,
        'title': false,
        'subtitle': false,
        'colors': false,
        'decimation': false,
        'filler': false,
      },
      if (!circle)
        'scales': <String, Object?>{
          if (radial)
            'r': <String, Object?>{
              'type': 'radialLinear',
              if (bounded) ...{'min': 0.0, 'max': 10.0},
            }
          else ...{
            'x': <String, Object?>{
              'type': xy || horizontal ? 'linear' : 'category',
              if (bounded && (xy || horizontal)) ...{'min': 0.0, 'max': 10.0},
            },
            'y': <String, Object?>{
              'type': horizontal ? 'category' : 'linear',
              if (bounded && !horizontal) ...{'min': 0.0, 'max': 10.0},
            },
          },
        },
    },
    'plugins': plugins,
  };
}

Map<String, Object?> dataset(Map<String, Object?> cfg) =>
    ((cfg['data']! as Map)['datasets'] as List).first as Map<String, Object?>;
void change(Map<String, Object?> cfg, int step) {
  final values = dataset(cfg)['data']! as List<Object?>;
  for (var i = 0; i < values.length; i++) {
    final value = (9 - i - step).toDouble();
    final item = values[i];
    if (item is Map) {
      item['y'] = value;
    } else {
      values[i] = value;
    }
  }
}

Chart chart(Object cfg) {
  final canvas = UiCanvasElement(width: 640, height: 400);
  final chart = Chart(canvas, cfg);
  addTearDown(() {
    chart.destroy();
    canvas.getContext2d().dispose();
  });
  return chart;
}

Object? plain(Object? value) {
  if (value is double &&
      (!value.isFinite || (value == 0 && value.isNegative))) {
    return value.toString();
  }
  if (value is JsObjectFace) {
    return {for (final k in value.jsKeys()) k: plain(value.jsRead(k))};
  }
  if (value is Map) {
    return {for (final e in value.entries) e.key: plain(e.value)};
  }
  if (value is List) return value.map(plain).toList();
  return value;
}

Object observe(Chart chart) {
  final meta = chart.getDatasetMeta(0);
  return [
    plain(meta.parsed),
    meta.sorted,
    for (final e in meta.data)
      [
        for (final key in [
          'x',
          'y',
          'base',
          'width',
          'height',
          'startAngle',
          'endAngle',
          'circumference',
          'innerRadius',
          'outerRadius',
          'skip',
          'stop',
        ])
          plain((e as types.ElementPropertyRead)[key]),
      ],
    for (var i = 0; i < meta.data.length; i++)
      meta.controller!.getLabelAndValue(i.toDouble()),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Chart.register([...registerables, _CustomLinear.value]);
  for (final type in [
    'bar',
    'line',
    'scatter',
    'bubble',
    'doughnut',
    'pie',
    'radar',
    'polarArea',
  ]) {
    test('$type matches full updates and retains layout/ticks', () {
      final ca = config(type);
      final cb = config(type);
      final a = chart(ca);
      final b = chart(cb);
      final area = a.chartArea;
      final ticks = {for (final e in a.scales.entries) e.key: e.value.ticks};
      for (var step = 0; step < 3; step++) {
        change(ca, step);
        change(cb, step);
        expect(a.updateData(), isTrue, reason: type);
        b.update('none');
        expect(observe(a), observe(b));
        expect(a.chartArea, same(area));
        for (final key in ticks.keys) {
          expect(a.scales[key]!.ticks, same(ticks[key]));
        }
      }
    });
  }
  test('native prepared maps keep aliases, metadata and bulk geometry', () {
    final ca = config('bar', prepared: true);
    final cb = config('bar', prepared: true);
    final a = chart(ca);
    final b = chart(cb);
    change(ca, 0);
    change(cb, 0);
    expect(a.updateData(), isTrue);
    b.update('none');
    expect(observe(a), observe(b));
    expect(a.getDatasetMeta(0).parsed, same(dataset(ca)['data']));
  });
  test('horizontal numeric bars and same-length replacement arrays match', () {
    final ca = config('bar', horizontal: true);
    final cb = config('bar', horizontal: true);
    final a = chart(ca);
    final b = chart(cb);
    for (final cfg in [ca, cb]) {
      dataset(cfg)['data'] = <Object?>[8.0, 7.0, 6.0, 5.0];
    }
    expect(a.updateData(), isTrue);
    b.update('none');
    expect(observe(a), observe(b));
  });
  test('auto ranges fall back to a full update', () {
    final ca = config('line', bounded: false);
    final cb = config('line', bounded: false);
    final a = chart(ca);
    final b = chart(cb);
    change(ca, 0);
    change(cb, 0);
    expect(a.updateData(), isFalse);
    b.update('none');
    expect(observe(a), observe(b));
    expect(a.scales['y']!.max, b.scales['y']!.max);
  });
  test('shape, label replacement and visibility invalidate the plan', () {
    final cfg = config('bar');
    final a = chart(cfg);
    expect(a.updateData(), isTrue);
    (dataset(cfg)['data']! as List).add(5.0);
    expect(a.updateData(), isFalse);
    (cfg['data']! as Map)['labels'] = <String>['A', 'B', 'C', 'D', 'E'];
    expect(a.updateData(), isFalse);
    a.toggleDataVisibility(0);
    expect(a.updateData(), isFalse);
    expect(a.updateData(), isTrue);
  });
  test('scriptable styles fall back and see new parsed values', () {
    final cfg = config('bar');
    ui.Color background(Object? context) =>
        (jsGet(jsGet(context, 'parsed'), 'y')! as num) > 5
        ? const ui.Color(0xffff0000)
        : const ui.Color(0xff0000ff);
    dataset(cfg)['backgroundColor'] = background;
    final a = chart(cfg);
    change(cfg, 0);
    expect(a.updateData(), isFalse);
    expect(
      jsGet(a.getDatasetMeta(0).data.first.options, 'backgroundColor'),
      const ui.Color(0xffff0000),
    );
  });
  test(
    'unknown plugins use full hooks; approved plugins omit stable layout',
    () {
      for (final approved in [false, true]) {
        final calls = <String>[];
        final plugin = <String, Object?>{
          'id': 'dataUpdateProbe',
          if (approved) 'supportsDataUpdates': true,
          for (final hook in [
            'beforeUpdate',
            'beforeElementsUpdate',
            'beforeLayout',
            'afterLayout',
            'beforeDatasetsUpdate',
            'beforeDatasetUpdate',
            'afterDatasetUpdate',
            'afterDatasetsUpdate',
            'afterUpdate',
            'beforeDraw',
            'afterDraw',
          ])
            hook: (Object? c, Object? a, Object? o) {
              calls.add(hook);
            },
        };
        final cfg = config('bar', plugins: [plugin]);
        final a = chart(cfg);
        calls.clear();
        change(cfg, 0);
        expect(a.updateData(), approved);
        expect(calls.contains('beforeLayout'), !approved);
        expect(calls.contains('afterLayout'), !approved);
        expect(calls.first, 'beforeUpdate');
        expect(calls.last, 'afterDraw');
        expect(calls.where((h) => h == 'beforeDatasetUpdate'), hasLength(1));
      }
    },
  );
  test(
    'cancellation and exceptions do not leave a running incremental state',
    () {
      var cancel = false;
      var fail = false;
      final plugin = Plugin(supportsDataUpdates: true)
        ..id = 'cancelData'
        ..beforeUpdate = (chart, args, options) {
          if (fail) throw StateError('test');
          return !cancel;
        };
      final cfg = config('bar', plugins: [plugin]);
      final a = chart(cfg);
      final before = observe(a);
      change(cfg, 0);
      cancel = true;
      expect(a.updateData(), isTrue);
      expect(observe(a), before);
      cancel = false;
      fail = true;
      expect(a.updateData, throwsStateError);
      fail = false;
      expect(a.updateData(), isFalse);
      expect(a.updateData(), isTrue);
    },
  );
  test('preflight does not execute user numeric conversions', () {
    expect(dataUpdateValues(<Object?>[1, 2, Object()]), isNull);
  });
  group('preflight of a list of points', () {
    final point = typed.DataPoint(1, 2);
    setUpAll(() => registerDataUpdateTypes(const [], [typed.DataPoint]));

    test('the items after the first point classify as the first one', () {
      expect(dataUpdateValues(<Object?>[point, point, point]), isFalse);
      expect(dataUpdateValues(<Object?>[1.0, point, null, point]), isFalse);
      expect(
        dataUpdateValues(<Object?>[
          point,
          <String, Object?>{'x': 1.0, 'y': 2.0},
          point,
          <double>[1, 2],
          point,
        ]),
        isFalse,
      );
    });
    test('a point with a value that is not a number falls back', () {
      final label = typed.DataPoint.label('a', 1);
      final time = typed.DataPoint.time(DateTime.utc(2026), 1);
      expect(dataUpdateValues(<Object?>[point, label]), isNull);
      expect(dataUpdateValues(<Object?>[label, point]), isNull);
      expect(dataUpdateValues(<Object?>[point, time]), isNull);
      expect(dataUpdateValues(<Object?>[point, point, time, point]), isNull);
    });
    test('another class after a point falls back', () {
      expect(dataUpdateValues(<Object?>[point, Object()]), isNull);
      expect(dataUpdateValues(<Object?>[point, _OtherPoint()]), isNull);
      expect(
        dataUpdateValues(<Object?>[
          point,
          <String, Object?>{'x': 'a'},
        ]),
        isNull,
      );
    });
  });
  test('changed prepared x coordinates invalidate spacing caches', () {
    final ca = config('bar', prepared: true);
    final cb = config('bar', prepared: true);
    final a = chart(ca);
    final b = chart(cb);
    for (final cfg in [ca, cb]) {
      final values = dataset(cfg)['data']! as List;
      for (var i = 0; i < values.length; i++) {
        (values[i] as Map)['x'] = i * 1.5;
      }
    }
    expect(a.updateData(), isTrue);
    b.update('none');
    expect(observe(a), observe(b));
  });
  test('stacked numeric datasets refresh totals and geometry', () {
    Map<String, Object?> cfg() {
      final c = config('bar');
      final d = dataset(c);
      ((c['data']! as Map)['datasets'] as List).add(<String, Object?>{
        ...d,
        'data': <Object?>[2.0, 3.0, 1.0, 2.0],
      });
      final scales = (c['options']! as Map)['scales'] as Map;
      for (final scale in scales.values) {
        (scale as Map)['stacked'] = true;
      }
      return c;
    }

    final ca = cfg();
    final cb = cfg();
    final a = chart(ca);
    final b = chart(cb);
    change(ca, 0);
    change(cb, 0);
    expect(a.updateData(), isTrue);
    b.update('none');
    expect(observe(a), observe(b));
    for (var i = 0; i < 4; i++) {
      expect(a.getDatasetMeta(1).data[i].y, b.getDatasetMeta(1).data[i].y);
    }
  });
  test('resize and registered plugins invalidate eligibility', () {
    final a = chart(config('bar'));
    expect(a.updateData(), isTrue);
    a.resize(420, 300);
    a.updateData();
    expect(a.updateData(), isTrue);
    final p = <String, Object?>{'id': 'registeredUnknownData'};
    Chart.register([p]);
    addTearDown(() => Chart.unregister([p]));
    expect(a.updateData(), isFalse);
  });
  test('data hooks cannot recursively enter full or incremental updates', () {
    var enabled = false;
    late Chart a;
    final p = <String, Object?>{
      'id': 'recursiveData',
      'supportsDataUpdates': true,
      'beforeUpdate': (Object? c, Object? args, Object? o) {
        if (enabled) a.update('none');
      },
    };
    a = chart(config('bar', plugins: [p]));
    enabled = true;
    expect(a.updateData, throwsStateError);
    enabled = false;
    expect(a.updateData(), isFalse);
  });
  test('hover, hit tests and tooltip values stay synchronized', () {
    Map<String, Object?> cfg() {
      final c = config('bar');
      ((c['options']! as Map)['plugins'] as Map).addAll(<String, Object?>{
        'tooltip': true,
        'legend': true,
      });
      return c;
    }

    final ca = cfg();
    final cb = cfg();
    final a = chart(ca);
    final b = chart(cb);
    final point = a.getDatasetMeta(0).data[1];
    final event = _Event(point.x, point.y + 2);
    a.eventHandler(event);
    b.eventHandler(event);
    change(ca, 0);
    change(cb, 0);
    expect(a.updateData(), isTrue);
    b.update('none');
    Object active(Chart c) => [
      for (final e in c.getActiveElements()) [e.datasetIndex, e.index],
    ];
    Object tips(Chart c) => [
      for (final t in c.tooltip!.dataPoints ?? const <Object?>[])
        [jsGet(t, 'formattedValue'), plain(jsGet(t, 'parsed'))],
    ];
    expect(active(a), active(b));
    expect(tips(a), tips(b));
    expect(tips(a), isNotEmpty);
    expect(observe(a), observe(b));
    final e = a.getDatasetMeta(0).data[2];
    final hit = _Event(e.x, e.y + 1);
    final ao = a.getElementsAtEventForMode(hit, 'nearest', <String, Object?>{
      'intersect': true,
    }, false);
    final bo = b.getElementsAtEventForMode(hit, 'nearest', <String, Object?>{
      'intersect': true,
    }, false);
    expect(ao.map((x) => x.index), bo.map((x) => x.index));
  });
  test('typed immutable point input participates without copying its list', () {
    typed.ChartConfig cfg(List<typed.DataPoint> points) => typed.ChartConfig(
      type: typed.ChartKind.line,
      datasets: [typed.LineDataset(points: points)],
      scales: const {
        'x': typed.LinearAxis(min: 0, max: 10),
        'y': typed.LinearAxis(min: 0, max: 10),
      },
      responsive: false,
      animation: typed.ChartAnimation.none,
      extra: const {
        'parsing': false,
        'plugins': {
          'legend': false,
          'tooltip': false,
          'colors': false,
          'filler': false,
        },
      },
    );
    final first = [typed.DataPoint(1, 2), typed.DataPoint(2, 3)];
    final lowering = ChartConfigLowering(cfg(first));
    final a = chart(lowering.lower());
    final next = [typed.DataPoint(1, 8), typed.DataPoint(2, 7)];
    lowering.apply(cfg(next));
    expect(a.updateData(), isTrue);
    expect(a.getDatasetMeta(0).parsed, same(next));
    final before = observe(a);
    a.update('none');
    expect(observe(a), before);
  });
  test('nonfinite values and gaps match ordinary parsing', () {
    final ca = config('line');
    final cb = config('line');
    final a = chart(ca);
    final b = chart(cb);
    for (final c in [ca, cb]) {
      dataset(c)['data'] = <Object?>[null, double.nan, double.infinity, 5.0];
    }
    expect(a.updateData(), isTrue);
    b.update('none');
    expect(observe(a), observe(b));
  });
  test('custom scale and custom source containers retain full updates', () {
    final ca = config('bar');
    final cb = config('bar');
    final la = _ObservedList(<Object?>[1.0, 2.0, 3.0, 4.0]);
    final lb = _ObservedList(<Object?>[1.0, 2.0, 3.0, 4.0]);
    dataset(ca)['data'] = la;
    dataset(cb)['data'] = lb;
    final a = chart(ca);
    final b = chart(cb);
    la.reads = lb.reads = 0;
    expect(a.updateData(), isFalse);
    b.update('none');
    expect(la.reads, lb.reads);
    expect(observe(a), observe(b));
    final cfg = config('line');
    (((cfg['options']! as Map)['scales'] as Map)['y'] as Map)['type'] =
        'data-custom-linear';
    final custom = chart(cfg);
    change(cfg, 0);
    expect(custom.updateData(), isFalse);
  });
  test('builtin plugin state stays current without running layout hooks', () {
    final ca = config('line');
    final cb = config('line');
    for (final cfg in [ca, cb]) {
      ((cfg['options']! as Map)['plugins'] as Map).addAll(<String, Object?>{
        'legend': true,
        'title': <String, Object?>{'display': true, 'text': 'Fixed title'},
        'subtitle': <String, Object?>{
          'display': true,
          'text': 'Fixed subtitle',
        },
        'tooltip': true,
        'colors': true,
        'filler': true,
        'decimation': <String, Object?>{'enabled': false},
      });
      dataset(cfg)['fill'] = true;
    }
    final a = chart(ca);
    final b = chart(cb);
    final area = a.chartArea;
    change(ca, 0);
    change(cb, 0);
    expect(a.updateData(), isTrue);
    b.update('none');
    expect(observe(a), observe(b));
    expect(a.chartArea, same(area));
  });
  test('numeric typed buffers and views use the coherent native path', () {
    for (final values in <List<double>>[
      Float64List.fromList([1, 2, 3, 4]),
      Float32List.fromList([1, 2, 3, 4]),
      Float64List.view(Float64List.fromList([1, 2, 3, 4]).buffer),
    ]) {
      final cfg = config('bar');
      dataset(cfg)['data'] = values;
      final a = chart(cfg);
      values.setAll(0, [8, 7, 6, 5]);
      expect(a.updateData(), isTrue);
      final before = observe(a);
      a.update('none');
      expect(observe(a), before);
    }
  });
  test('native font changes invalidate the retained layout', () {
    final a = chart(config('bar'));
    expect(a.updateData(), isTrue);
    invalidateCanvasTextMetrics();
    expect(a.updateData(), isFalse);
    expect(a.updateData(), isTrue);
  });
  test('scriptable bounds and enabled decimation select full updates', () {
    final cfg = config('line');
    double maxBound(Object? context) => 10;
    (((cfg['options']! as Map)['scales'] as Map)['y'] as Map)['max'] = maxBound;
    final a = chart(cfg);
    expect(a.updateData(), isFalse);
    final decimated = config('line', prepared: true);
    ((decimated['options']! as Map)['plugins']
        as Map)['decimation'] = <String, Object?>{
      'enabled': true,
      'threshold': 2,
      'algorithm': 'lttb',
      'samples': 2,
    };
    final b = chart(decimated);
    expect(b.updateData(), isFalse);
  });
  test('bubble radius changes trigger the necessary layout refresh', () {
    final ca = config('bubble');
    final cb = config('bubble');
    final a = chart(ca);
    final b = chart(cb);
    for (final cfg in [ca, cb]) {
      ((dataset(cfg)['data']! as List)[0] as Map)['r'] = 20.0;
    }
    expect(a.updateData(), isTrue);
    b.update('none');
    expect(observe(a), observe(b));
    expect(a.chartArea!.left, b.chartArea!.left);
    expect(a.chartArea!.right, b.chartArea!.right);
  });
  test(
    'narrow prepared-map lists keep opaque attributes and current geometry',
    () {
      final cfg = config('bar', prepared: true);
      final values = <Map<String, Object?>>[
        for (var i = 0; i < 4; i++)
          <String, Object?>{
            'x': i.toDouble(),
            'y': i + 1.0,
            'id': 'p$i',
            'opaque': Object(),
          },
      ];
      dataset(cfg)['data'] = values;
      final a = chart(cfg);
      for (final v in values) {
        v['y'] = 8.0;
      }
      expect(a.updateData(), isTrue);
      final before = observe(a);
      a.update('none');
      expect(observe(a), before);
    },
  );
  test('custom object parsing keys retain the full lifecycle', () {
    final cfg = config('line');
    dataset(cfg)['data'] = <Object?>[
      for (var i = 0; i < 4; i++)
        <String, Object?>{'label': i.toDouble(), 'amount': i + 1.0},
    ];
    dataset(cfg)['parsing'] = <String, Object?>{
      'xAxisKey': 'label',
      'yAxisKey': 'amount',
    };
    final a = chart(cfg);
    expect(a.updateData(), isFalse);
  });
}
