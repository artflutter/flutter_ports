// Original code, not ported from Chart.js: incremental-update reference twins.
@TestOn('vm')
library;

import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart' as typed;
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui_text.dart'
    show invalidateCanvasTextMetrics;
import 'package:flutter_chartjs_port/src/core/core.config.dart' show Config;
import 'package:flutter_chartjs_port/src/core/core.datasetController.dart'
    show controllerArgs;
import 'package:flutter_chartjs_port/src/core/core.defaults.dart'
    show defaults, overrides;
import 'package:flutter_chartjs_port/src/core/core.scale.dart' show scaleCfgArg;
import 'package:flutter_chartjs_port/src/core/data_update.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet, jsSet;
import 'package:flutter_chartjs_port/src/options/option_scope.dart'
    show ScopeRoute;
import 'package:flutter_chartjs_port/src/typed/lower.dart'
    show ChartConfigLowering;
import 'package:flutter_chartjs_port/src/types/data_item.dart'
    show TypedDataItem;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import '../../support/legend_item.dart';

final class _ObservedList(final List<Object?> values)
    extends ListBase<Object?> {
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

class _CustomLinear(super.cfg) extends LinearScale {
  static final value = JsClass(
    'DataCustomLinear',
    superclass: LinearScale.jsClass,
    statics: {'id': 'data-custom-linear'},
    construct: (_, args) => _CustomLinear(scaleCfgArg(args)),
  );
}

/// A point class that the typed lowering does not register.
final class _OtherPoint() implements TypedDataItem {
  @override
  Object get x => 1.0;
  @override
  double? get y => 2;
  @override
  double? get r => null;
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Event(@override final double? x, @override final double? y)
    implements types.ChartEvent {
  @override
  String get type => 'mousemove';
  @override
  final NativeEvent native = NativeEvent(
    type: 'mousemove',
    offsetX: x!,
    offsetY: y!,
  );
  @override
  types.Chart? get chart => null;
}

// The user subclasses of Chart.js ADR 0100: the same results, the full path.
final class _UserPie(super.chart, super.datasetIndex, [super.newTarget])
    extends PieController {
  static final value = JsClass(
    'UserPie',
    superclass: PieController.jsClass,
    statics: {'id': 'user-pie'},
    construct: (target, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return _UserPie(chart, datasetIndex, target);
    },
  );
}

final class _UserArc() extends ArcElement;

final class _UserChart(super.item, super.userConfig) extends Chart;

final class _UserConfig(super.config) extends Config;

final class _ConfigChart(Object item, final Config supplied) extends Chart {
  this : super(item, <String, Object?>{});
  @override
  Config get config => supplied;
}

/// A user Map: each read is user code.
final class _UserMap(final Map<String, Object?> store)
    extends MapBase<String, Object?> {
  @override
  Object? operator [](Object? key) => store[key];
  @override
  void operator []=(String key, Object? value) => store[key] = value;
  @override
  void clear() => store.clear();
  @override
  Iterable<String> get keys => store.keys;
  @override
  Object? remove(Object? key) => store.remove(key);
}

/// A user subclass of a color.
final class const _UserColor(super.value) extends ui.Color;

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
          'backgroundColor': const ChartPaint.solid(ui.Color(0x803366aa)),
          'borderColor': const ChartPaint.solid(ui.Color(0xff3366aa)),
          'borderWidth': 1.0,
          if (prepared) 'parsing': false,
        },
      ],
    },
    'options': <String, Object?>{
      'responsive': false,
      'animation': false,
      'indexAxis': horizontal ? const YAxis() : const XAxis(),
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
    ChartPaint background(Object? context) => ChartPaint.solid(
      (jsGet(jsGet(context, 'parsed'), 'y')! as num) > 5
          ? const ui.Color(0xffff0000)
          : const ui.Color(0xff0000ff),
    );
    dataset(cfg)['backgroundColor'] = background;
    final a = chart(cfg);
    change(cfg, 0);
    expect(a.updateData(), isFalse);
    expect(
      jsGet(a.getDatasetMeta(0).data.first.options, 'backgroundColor'),
      const ChartPaint.solid(ui.Color(0xffff0000)),
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
  group('a callback of the replay', () {
    void move(Chart a) {
      final point = a.getDatasetMeta(0).data[1];
      a.eventHandler(_Event(point.x, point.y + 2));
    }

    /// A bar chart with [onHover], and a mouse over its bar 1.
    (Chart, Map<String, Object?>) hovered(void Function(Chart chart) onHover) {
      final cfg = config('bar');
      void hover(Object? e, Object? active, Object? c) => onHover(c! as Chart);
      (cfg['options']! as Map<String, Object?>)['onHover'] = hover;
      final a = chart(cfg);
      move(a);
      return (a, cfg);
    }

    test('may run update, as in a full update', () {
      var armed = false;
      void nested(Chart c) {
        if (armed) {
          armed = false;
          c.update('none');
        }
      }

      final (a, ca) = hovered(nested);
      final (b, cb) = hovered(nested);
      change(ca, 0);
      change(cb, 0);
      armed = true;
      expect(a.updateData(), isTrue);
      expect(armed, isFalse, reason: 'the callback ran');
      armed = true;
      b.update('none');
      expect(armed, isFalse, reason: 'the callback ran');
      expect(observe(a), observe(b));

      // The nested update made a plan, and the state of the data update ended.
      change(ca, 1);
      change(cb, 1);
      expect(a.updateData(), isTrue);
      b.update('none');
      expect(observe(a), observe(b));
    });

    test('cannot run updateData, as in a full update', () {
      var armed = false;
      final (a, ca) = hovered((c) {
        if (armed) {
          armed = false;
          c.updateData();
        }
      });
      armed = true;
      expect(() => a.update('none'), throwsStateError);
      expect(a.updateData(), isFalse, reason: 'the throw ended the plan');

      // A throw in the callback also ends the last event, as upstream.
      move(a);
      change(ca, 0);
      armed = true;
      expect(a.updateData, throwsStateError);
      expect(a.updateData(), isFalse, reason: 'the throw ended the plan');
      expect(a.updateData(), isTrue);
    });

    test('a draw hook may run update, as in a full update', () {
      var armed = false;
      Chart? hooked;
      final plugin = <String, Object?>{
        'id': 'updateInDraw',
        'supportsDataUpdates': true,
        'afterDraw': (Object? c, Object? args, Object? o) {
          if (armed) {
            armed = false;
            hooked = c! as Chart;
            hooked!.update('none');
          }
        },
      };
      final a = chart(config('bar', plugins: [plugin]));
      expect(a.updateData(), isTrue);
      armed = true;
      expect(a.updateData(), isTrue);
      expect(hooked, same(a));
      expect(a.updateData(), isTrue);
    });
  });
  group('a plugin that cancels beforeLayout', () {
    (Chart, void Function({bool on})) cancelled(String type) {
      var cancel = false;
      final plugin = <String, Object?>{
        'id': 'cancelLayout',
        'supportsDataUpdates': true,
        'beforeLayout': (Object? c, Object? args, Object? o) => !cancel,
      };
      final cfg = config(type, plugins: [plugin]);
      ((cfg['options']! as Map)['plugins'] as Map)['legend'] =
          <String, Object?>{'display': true};
      return (chart(cfg), ({bool on = true}) => cancel = on);
    }

    double top(Chart a) => a.legend!.legendHitBoxes.first.top;

    for (final type in const ['pie', 'doughnut', 'polarArea', 'bar']) {
      test('a cancelled layout goes to the full update, a $type', () {
        final (a, cancel) = cancelled(type);
        final start = top(a);
        expect(a.updateData(), isTrue);
        expect(top(a), start);
        cancel();
        a.update('none');
        final moved = top(a);
        expect(moved, greaterThan(start), reason: 'as upstream: no fit ran');
        expect(a.updateData(), isFalse, reason: 'no layout ran');
        expect(top(a), greaterThan(moved), reason: 'as upstream: no fit ran');
        cancel(on: false);
        expect(
          a.updateData(),
          isFalse,
          reason: 'the last layout was cancelled',
        );
        expect(a.updateData(), isTrue);
      });

      test(
        'a size that a cancelled layout missed reaches the chart, a $type',
        () {
          final (a, cancel) = cancelled(type);
          final start = a.chartArea!.width;
          cancel();
          a.resize(start / 2, a.height);
          expect(a.chartArea!.width, start, reason: 'no layout ran');
          cancel(on: false);
          expect(a.updateData(), isFalse);
          expect(a.chartArea!.width, lessThan(start));
        },
      );
    }

    test('a layout that a tick cancels makes the next tick a full update', () {
      var cancel = false;
      final plugin = <String, Object?>{
        'id': 'cancelTickLayout',
        'supportsDataUpdates': true,
        'beforeLayout': (Object? c, Object? args, Object? o) => !cancel,
      };
      List<Object?> points(double r) => [
        for (var i = 0; i < 4; i++)
          <String, Object?>{'x': i.toDouble(), 'y': 1.0, 'r': r},
      ];
      final cfg = config('bubble', plugins: [plugin]);
      dataset(cfg)['data'] = points(2);
      final a = chart(cfg);
      expect(a.updateData(), isTrue);
      cancel = true;
      dataset(cfg)['data'] = points(40);
      expect(a.updateData(), isTrue, reason: 'the overflow needs a layout');
      cancel = false;
      expect(a.updateData(), isFalse, reason: 'that layout was cancelled');
      expect(a.updateData(), isTrue);
    });
  });
  test('a tick writes the dataset context as configure does', () {
    for (final type in const ['pie', 'line', 'bar']) {
      final cfg = config(type);
      final a = chart(cfg);
      final controller = a.getDatasetMeta(0).controller!;
      final context = controller.getContext(null, true, 'resize');
      expect(jsGet(context, 'active'), isTrue);
      change(cfg, 0);
      expect(a.updateData(), isTrue, reason: type);
      expect(jsGet(context, 'active'), isFalse, reason: type);
      expect(jsGet(context, 'mode'), same(undefined), reason: type);
    }
  });
  test('the arguments of afterUpdate have only the key mode', () {
    final seen = <List<String>>[];
    final plugin = <String, Object?>{
      'id': 'updateArgs',
      'supportsDataUpdates': true,
      'afterUpdate': (Object? c, Object? args, Object? o) {
        seen.add((args! as JsObjectFace).jsKeys().toList());
      },
    };
    final a = chart(config('bar', plugins: [plugin]));
    expect(a.updateData(), isTrue);
    expect(seen, [
      ['mode'],
      ['mode'],
    ]);
  });
  test('a category scale with bounds data falls back', () {
    final cfg = config('bar');
    (((cfg['options']! as Map)['scales'] as Map)['x'] as Map)['bounds'] =
        ScaleBounds.data;
    expect(chart(cfg).updateData(), isFalse);
  });
  test('a category scale with bounds of a function falls back', () {
    final cfg = config('bar');
    ScaleBounds bounds(Object? context) => ScaleBounds.ticks;
    (((cfg['options']! as Map)['scales'] as Map)['x'] as Map)['bounds'] =
        bounds;
    expect(chart(cfg).updateData(), isFalse);
  });
  test('a category scale with an added label falls back once', () {
    final cfg = config('bar');
    final a = chart(cfg);
    final labels = (cfg['data']! as Map)['labels'] as List<String>;
    final numbers = dataset(cfg)['data'];
    // A full update parses the string, and adds it to the labels. The plan of
    // this update has the new length of the labels.
    dataset(cfg)['data'] = <Object?>[
      <String, Object?>{'x': 'new', 'y': 1.0},
      2.0,
      3.0,
      4.0,
    ];
    a.update('none');
    expect(labels, hasLength(5));
    dataset(cfg)['data'] = numbers;
    expect(a.updateData(), isFalse, reason: 'the added label needs an update');
    expect(labels, hasLength(4));
    expect(a.updateData(), isTrue);
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
    final ao = a.getElementsAtEventForMode(
      hit,
      const NearestInteractionMode(),
      <String, Object?>{'intersect': true},
      false,
    );
    final bo = b.getElementsAtEventForMode(
      hit,
      const NearestInteractionMode(),
      <String, Object?>{'intersect': true},
      false,
    );
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
      'algorithm': const LttbDecimationAlgorithm(),
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
  group('native indexed styles (Chart.js ADR 0100)', () {
    const red = ChartPaint.solid(ui.Color(0xffff0000));
    const green = ChartPaint.solid(ui.Color(0xff00ff00));
    const blue = ChartPaint.solid(ui.Color(0xff0000ff));
    const types = ['bar', 'scatter', 'bubble', 'pie', 'doughnut', 'polarArea'];

    /// The defaults key of the data element of a chart type.
    String elementOf(String type) => switch (type) {
      'bar' => 'bar',
      'scatter' || 'bubble' || 'line' || 'radar' => 'point',
      _ => 'arc',
    };

    Map<String, Object?> indexed(
      String type, {
      bool prepared = false,
      bool plugins = false,
      Object? background,
      Object? border,
    }) {
      final cfg = config(type, prepared: prepared);
      dataset(cfg)
        ..['backgroundColor'] = background ?? <Object?>[red, green, blue]
        ..['borderColor'] = border ?? <Object?>[blue, red];
      if (plugins) {
        ((cfg['options']! as Map)['plugins'] as Map).addAll(<String, Object?>{
          'tooltip': true,
          'legend': true,
        });
      }
      return cfg;
    }

    /// [observe] of each dataset, with the options, their key order and the
    /// context of each element.
    Object deep(Chart chart) => [
      observe(chart),
      for (final meta in chart.getSortedVisibleDatasetMetas())
        for (final element in meta.data)
          () {
            final context = (element as Element).$context;
            final options = element.options;
            return [
              plain(options),
              (options! as JsObjectFace).jsKeys(),
              element.active,
              context?.jsKeys(),
              for (final key in const [
                'active',
                'dataIndex',
                'datasetIndex',
                'index',
                'mode',
                'parsed',
                'raw',
                'type',
              ])
                plain(context?.jsRead(key)),
            ];
          }(),
    ];

    /// The twin of [make] over the data ticks: `updateData` with the path
    /// [path], or with any path for Dart `null`, against `update('none')` with
    /// the same values.
    void expectTwin(
      Map<String, Object?> Function() make, {
      required bool? path,
      int ticks = 3,
    }) {
      final ca = make();
      final cb = make();
      final a = chart(ca);
      final b = chart(cb);
      for (var step = 0; step < ticks; step++) {
        change(ca, step);
        change(cb, step);
        final selected = a.updateData();
        if (path != null) expect(selected, path, reason: 'tick $step');
        b.update('none');
        expect(deep(a), deep(b), reason: 'tick $step');
      }
    }

    for (final type in types) {
      group(type, () {
        test('takes the data-only path with the results of a full update', () {
          final ca = indexed(type);
          final cb = indexed(type);
          final a = chart(ca);
          final b = chart(cb);
          final area = a.chartArea;
          expect(deep(a), deep(b));
          for (var step = 0; step < 3; step++) {
            change(ca, step);
            change(cb, step);
            expect(a.updateData(), isTrue, reason: 'tick $step');
            b.update('none');
            expect(deep(a), deep(b), reason: 'tick $step');
            expect(a.chartArea, same(area));
          }
        });

        test(
          'a later full update has the results of a chart of full updates',
          () {
            final ca = indexed(type);
            final cb = indexed(type);
            final a = chart(ca);
            final b = chart(cb);
            change(ca, 0);
            change(cb, 0);
            expect(a.updateData(), isTrue);
            b.update('none');
            change(ca, 1);
            change(cb, 1);
            a.update();
            b.update();
            expect(deep(a), deep(b));
            change(ca, 2);
            change(cb, 2);
            expect(a.updateData(), isTrue);
            b.update('none');
            expect(deep(a), deep(b));
          },
        );

        test('a hidden item', () {
          final ca = indexed(type);
          final cb = indexed(type);
          final a = chart(ca);
          final b = chart(cb);
          for (final c in [a, b]) {
            c.hide(0, 1);
          }
          expect(deep(a), deep(b));
          change(ca, 0);
          change(cb, 0);
          expect(a.updateData(), isTrue);
          b.update('none');
          expect(deep(a), deep(b));
          for (final c in [a, b]) {
            c.toggleDataVisibility(2);
          }
          change(ca, 1);
          change(cb, 1);
          expect(a.updateData(), isFalse, reason: 'no update after the toggle');
          b.update('none');
          expect(deep(a), deep(b));
          change(ca, 2);
          change(cb, 2);
          expect(a.updateData(), isTrue);
          b.update('none');
          expect(deep(a), deep(b));
        });

        test('active elements, the legend and the tooltip', () {
          Map<String, Object?> make() => indexed(type, plugins: true);
          final ca = make();
          final cb = make();
          final a = chart(ca);
          final b = chart(cb);
          for (final c in [a, b]) {
            c.setActiveElements([
              <String, Object?>{'datasetIndex': 0.0, 'index': 1.0},
            ]);
          }
          change(ca, 0);
          change(cb, 0);
          expect(a.updateData(), isTrue);
          b.update('none');
          expect(deep(a), deep(b));
          expect((a.getDatasetMeta(0).data[1] as Element).active, isTrue);
          final point = a.getDatasetMeta(0).data[2];
          final event = _Event(point.x, point.y);
          a.eventHandler(event);
          b.eventHandler(event);
          change(ca, 1);
          change(cb, 1);
          expect(a.updateData(), isTrue);
          b.update('none');
          expect(deep(a), deep(b));
          Object legend(Chart c) => [
            for (final item in c.legend!.legendItems ?? const <LegendItem>[])
              item,
          ];
          expect(legend(a), legendObservationMatcher(legend(b)));
        });

        test('two datasets, one of them with a plain style', () {
          Map<String, Object?> make() {
            final cfg = indexed(type);
            final datasets = (cfg['data']! as Map)['datasets']! as List;
            final plainStyle = config(type);
            datasets.add(dataset(plainStyle));
            return cfg;
          }

          expectTwin(make, path: true);
        });

        test('a dataset of one item stays equal to a full update', () {
          final ca = indexed(type);
          final cb = indexed(type);
          for (final c in [ca, cb]) {
            final item = (dataset(c)['data']! as List).first;
            dataset(c)['data'] = <Object?>[item];
          }
          final a = chart(ca);
          final b = chart(cb);
          for (var step = 0; step < 2; step++) {
            change(ca, step);
            change(cb, step);
            a.updateData();
            b.update('none');
            expect(deep(a), deep(b));
          }
        });

        test('an indexed style that is not a color', () {
          expectTwin(() {
            final cfg = indexed(type);
            dataset(cfg)['borderWidth'] = <num>[1, 2.5];
            return cfg;
          }, path: true);
        });

        test(
          'a function in the defaults of the element keeps the full path',
          () {
            final calls = <Object?>[];
            jsSet(
              jsGet(jsGet(defaults, 'elements'), elementOf(type)),
              'borderWidth',
              (Object? context) {
                calls.add(jsGet(context, 'index'));
                return 2.0;
              },
            );
            expectTwin(() {
              final cfg = indexed(type);
              dataset(cfg).remove('borderWidth');
              return cfg;
            }, path: false);
            expect(calls, isNotEmpty);
          },
        );

        test('a function in the overrides of the type keeps the full path', () {
          final calls = <Object?>[];
          jsSet(jsGet(overrides, type), 'borderWidth', (Object? context) {
            calls.add(jsGet(context, 'index'));
            return 2.0;
          });
          expectTwin(() {
            final cfg = indexed(type);
            dataset(cfg).remove('borderWidth');
            return cfg;
          }, path: false);
          expect(calls, isNotEmpty);
        });

        test('a function that the dataset hides runs in neither path', () {
          final calls = <Object?>[];
          jsSet(
            jsGet(jsGet(defaults, 'elements'), elementOf(type)),
            'borderWidth',
            (Object? context) {
              calls.add(context);
              return 2.0;
            },
          );
          expectTwin(() => indexed(type), path: true);
          expect(calls, isEmpty);
        });

        test('an indexed list in the defaults, with the native values', () {
          jsSet(
            jsGet(jsGet(defaults, 'elements'), elementOf(type)),
            'borderWidth',
            <Object?>[1.0, 3.0],
          );
          expectTwin(() {
            final cfg = indexed(type);
            dataset(cfg).remove('borderWidth');
            return cfg;
          }, path: true);
        });

        test(
          'a foreign item in a list of the defaults keeps the full path',
          () {
            jsSet(
              jsGet(jsGet(defaults, 'elements'), elementOf(type)),
              'borderWidth',
              <Object?>[1.0, '3'],
            );
            expectTwin(() {
              final cfg = indexed(type);
              dataset(cfg).remove('borderWidth');
              return cfg;
            }, path: false);
          },
        );
      });
    }

    test('a bar chart of prepared maps', () {
      expectTwin(() => indexed('bar', prepared: true), path: true);
    });

    test('stacked bars', () {
      expectTwin(() {
        final cfg = indexed('bar');
        ((cfg['data']! as Map)['datasets']! as List).add(<String, Object?>{
          ...dataset(cfg),
          'data': <Object?>[2.0, 3.0, 1.0, 2.0],
        });
        final scales = (cfg['options']! as Map)['scales'] as Map;
        for (final scale in scales.values) {
          (scale as Map)['stacked'] = true;
        }
        return cfg;
      }, path: true);
    });

    test('a line dataset beside indexed bars', () {
      expectTwin(() {
        final cfg = indexed('bar');
        ((cfg['data']! as Map)['datasets']! as List).add(<String, Object?>{
          'type': 'line',
          'data': <Object?>[2.0, 3.0, 1.0, 2.0],
          'borderColor': blue,
        });
        return cfg;
      }, path: true);
    });

    test('a hidden dataset beside an indexed one', () {
      for (final type in types) {
        expectTwin(() {
          final cfg = indexed(type);
          ((cfg['data']! as Map)['datasets']! as List).add(<String, Object?>{
            ...dataset(config(type)),
            'backgroundColor': <Object?>[green, blue],
            'hidden': true,
          });
          return cfg;
        }, path: null);
      }
    });

    test('an indexed radius takes part in the overflow', () {
      for (final type in const ['scatter', 'bubble']) {
        expectTwin(() {
          final cfg = indexed(type);
          dataset(cfg)['pointRadius'] = <num>[3, 8];
          dataset(cfg)['hoverRadius'] = <num>[4, 9];
          return cfg;
        }, path: true);
      }
    });

    test('a horizontal bar chart', () {
      expectTwin(() {
        final cfg = config('bar', horizontal: true);
        dataset(cfg)['backgroundColor'] = <Object?>[red, green];
        return cfg;
      }, path: true);
    });

    test('a line or a radar with indexed point colors', () {
      for (final type in const ['line', 'radar']) {
        expectTwin(() {
          final cfg = config(type);
          dataset(cfg)['pointBackgroundColor'] = <Object?>[red, green];
          return cfg;
        }, path: true);
      }
    });

    test('a scatter chart with a line and indexed point colors', () {
      expectTwin(() {
        final cfg = config('scatter');
        dataset(cfg)
          ..['showLine'] = true
          ..['pointBackgroundColor'] = <Object?>[red, green];
        return cfg;
      }, path: true);
    });

    test('an indexed style of a dataset element keeps the full path', () {
      for (final type in const ['line', 'radar']) {
        expectTwin(() {
          final cfg = config(type);
          dataset(cfg)['borderColor'] = <Object?>[red, green];
          return cfg;
        }, path: false);
      }
    });

    test('each native form of a color list of a raw config', () {
      final forms = <String, Object? Function()>{
        'Object?': () => <Object?>[red, green],
        'Object': () => <Object>[red, green],
        'Color': () => <ChartPaint>[red, green],
        'Color?': () => <ChartPaint?>[red, null, green],
        'const Color': () => const <ChartPaint>[red, green],
        'const Object': () => const <Object>[red, green],
      };
      for (final MapEntry(key: name, value: form) in forms.entries) {
        for (final type in types) {
          final ca = indexed(type, background: form());
          final cb = indexed(type, background: form());
          final a = chart(ca);
          final b = chart(cb);
          change(ca, 0);
          change(cb, 0);
          expect(a.updateData(), isTrue, reason: '$name, $type');
          b.update('none');
          expect(deep(a), deep(b), reason: '$name, $type');
        }
      }
    });

    group('falls back with the results of a full update', () {
      // A list longer than the data: the draw reads no foreign item, so the two
      // paths differ only in the proof, which reads each item.
      List<Object?> withItem(Object? item) => <Object?>[
        red,
        green,
        blue,
        red,
        item,
      ];

      final foreign = <String, Object? Function()>{
        'a number': () => 5.0,
        'a boolean': () => true,
        'a string': () => 'red',
        'a function': () =>
            (Object? _) => red,
        'a map': () => <String, Object?>{'a': 1.0},
        'an object': Object.new,
        'a nested list': () => <Object?>[red],
        'a subclass of a color': () =>
            const ChartPaint.solid(_UserColor(0xff112233)),
      };

      // The controls of the groups below: the same list with a native item.
      test('a color list of the defaults or the overrides with a color', () {
        for (final type in types) {
          jsSet(
            jsGet(jsGet(defaults, 'elements'), elementOf(type)),
            'backgroundColor',
            withItem(blue),
          );
          jsSet(jsGet(overrides, type), 'borderColor', withItem(green));
          expectTwin(
            () {
              final cfg = indexed(type);
              dataset(cfg)
                ..remove('backgroundColor')
                ..remove('borderColor');
              return cfg;
            },
            path: true,
            ticks: 2,
          );
        }
      });

      // The constructor refuses a value that is no color in the options and
      // in the datasets (Chart.js ADR 0061). The scopes that it does not walk
      // are the ones that the walk of the settings does not read either.
      for (final MapEntry(key: name, value: item) in foreign.entries) {
        test('a color list of the defaults with $name', () {
          for (final type in types) {
            jsSet(
              jsGet(jsGet(defaults, 'elements'), elementOf(type)),
              'backgroundColor',
              withItem(item()),
            );
            expectTwin(
              () {
                final cfg = indexed(type);
                dataset(cfg).remove('backgroundColor');
                return cfg;
              },
              path: false,
              ticks: 2,
            );
          }
        });

        test('a color list of the overrides with $name', () {
          for (final type in types) {
            jsSet(jsGet(overrides, type), 'backgroundColor', withItem(item()));
            expectTwin(
              () {
                final cfg = indexed(type);
                dataset(cfg).remove('backgroundColor');
                return cfg;
              },
              path: false,
              ticks: 2,
            );
          }
        });
      }

      for (final (name, item) in <(String, Object? Function())>[
        (
          'a function',
          () =>
              (Object? _) => red,
        ),
        ('a nested list', () => <Object?>[red]),
        (
          'a subclass of a color',
          () => const ChartPaint.solid(_UserColor(0xff112233)),
        ),
      ]) {
        test('a color list of the dataset with $name', () {
          for (final type in types) {
            expectTwin(
              () => indexed(type, background: withItem(item())),
              path: false,
              ticks: 2,
            );
          }
        });
      }

      for (final (name, item) in <(String, Object? Function())>[
        ('a string', () => '3'),
        ('a boolean', () => true),
        (
          'a function',
          () =>
              (Object? _) => 1.0,
        ),
        ('a map', () => <String, Object?>{'a': 1.0}),
        ('a nested list', () => <Object?>[1.0]),
      ]) {
        test('a list of a number key of the dataset with $name', () {
          for (final type in types) {
            expectTwin(
              () {
                final cfg = indexed(type);
                dataset(cfg)['borderWidth'] = <Object?>[
                  1.0,
                  2.0,
                  1.0,
                  2.0,
                  item(),
                ];
                return cfg;
              },
              path: false,
              ticks: 2,
            );
          }
        });
      }

      test('an empty list of a number key of the dataset', () {
        for (final type in types) {
          expectTwin(
            () {
              final cfg = indexed(type);
              dataset(cfg)['borderWidth'] = <Object?>[];
              return cfg;
            },
            path: false,
            ticks: 2,
          );
        }
      });

      test('a custom list', () {
        for (final type in types) {
          expectTwin(
            () =>
                indexed(type, background: _ObservedList(<Object?>[red, blue])),
            path: false,
            ticks: 2,
          );
        }
      });

      test('a scriptable color', () {
        for (final type in types) {
          final calls = <Object?>[];
          expectTwin(
            () => indexed(
              type,
              background: (Object? context) {
                calls.add(jsGet(context, 'index'));
                return red;
              },
            ),
            path: false,
            ticks: 2,
          );
          expect(calls, isNotEmpty);
        }
      });

      test('a scriptable color beside an indexed one', () {
        for (final type in types) {
          expectTwin(
            () => indexed(type, border: (Object? _) => blue),
            path: false,
            ticks: 2,
          );
        }
      });

      test('a user Map in the overrides, with no read of it to qualify', () {
        final saved = jsGet(overrides, 'pie');
        final scope = _UserMap(<String, Object?>{});
        jsSet(overrides, 'pie', scope);
        addTearDown(() => jsSet(overrides, 'pie', saved));
        expectTwin(() => indexed('pie'), path: false, ticks: 2);
      });

      test('a function of a dataset option in the overrides', () {
        for (final cfg in <Map<String, Object?> Function()>[
          () => indexed('pie'),
          () => config('pie'),
        ]) {
          final calls = <Object?>[];
          final pie = jsGet(overrides, 'pie');
          jsSet(pie, 'rotation', (Object? context) {
            calls.add(jsGet(jsGet(context, 'dataset'), 'data'));
            return 30.0;
          });
          expectTwin(cfg, path: false, ticks: 2);
          expect(calls, isNotEmpty);
        }
      });

      test(
        'a function of a dataset option in the defaults of the datasets',
        () {
          final datasets = jsGet(jsGet(defaults, 'datasets'), 'doughnut');
          jsSet(datasets, 'cutout', (Object? _) => const PercentRadius(40));
          expectTwin(() => indexed('doughnut'), path: false, ticks: 2);
        },
      );

      test('a user subclass of the controller', () {
        Chart.register([_UserPie.value]);
        addTearDown(() => Chart.unregister([_UserPie.value]));
        final ca = indexed('pie');
        final cb = indexed('pie');
        ca['type'] = 'user-pie';
        final a = chart(ca);
        final b = chart(cb);
        change(ca, 0);
        change(cb, 0);
        expect(a.updateData(), isFalse);
        b.update('none');
        expect(deep(a), deep(b));
      });

      test('a user subclass of the element', () {
        final ca = indexed('pie');
        final cb = indexed('pie');
        final a = chart(ca);
        final b = chart(cb);
        for (final c in [a, b]) {
          final data = c.getDatasetMeta(0).data;
          data[1] = _UserArc()..options = data[1].options;
          c.update('none');
        }
        change(ca, 0);
        change(cb, 0);
        expect(a.updateData(), isFalse);
        b.update('none');
        expect(deep(a), deep(b));
      });

      test('a user subclass of the chart', () {
        final canvas = UiCanvasElement(width: 640, height: 400);
        addTearDown(() => canvas.getContext2d().dispose());
        final user = _UserChart(canvas, indexed('pie'));
        addTearDown(user.destroy);
        expect(user.updateData(), isFalse);
      });

      // An exact Chart always makes an exact Config, so `updateData` meets a
      // user Config only with a user Chart, and its first test declines that.
      test('a user subclass of the config', () {
        expect(Config(indexed('pie')).supportsDataUpdates, isTrue);
        expect(_UserConfig(indexed('pie')).supportsDataUpdates, isFalse);

        final canvas = UiCanvasElement(width: 640, height: 400);
        addTearDown(() => canvas.getContext2d().dispose());
        final chart = _ConfigChart(canvas, _UserConfig(indexed('pie')));
        addTearDown(chart.destroy);
        chart.update();
        expect(chart.updateData(), isFalse);
      });
    });

    group('the proof of the options', () {
      test('runs again after the config clears its caches', () {
        final cfg = indexed('pie');
        final a = chart(cfg);
        expect(a.updateData(), isTrue);
        a.config.clearCache();
        expect(a.updateData(), isFalse, reason: 'no plan after the clear');
        expect(a.updateData(), isTrue, reason: 'the full update made a plan');
      });

      test('a new list with a foreign item takes the full path after a full '
          'update', () {
        final cfg = indexed('pie');
        final a = chart(cfg);
        expect(a.updateData(), isTrue);
        dataset(cfg)['backgroundColor'] = <Object?>[
          red,
          green,
          blue,
          red,
          (Object? _) => blue,
        ];
        a.update('none');
        expect(a.updateData(), isFalse);
      });

      test('a new list of native colors takes the data-only path after a full '
          'update', () {
        final cfg = indexed('pie');
        final a = chart(cfg);
        expect(a.updateData(), isTrue);
        dataset(cfg)['backgroundColor'] = <Object?>[green];
        a.update('none');
        expect(a.updateData(), isTrue);
        final options = a.getDatasetMeta(0).data[1].options;
        expect(jsGet(options, 'backgroundColor'), green);
      });

      test('a chart of a plain style stays on its path', () {
        expectTwin(() => config('pie'), path: true);
      });

      test('the proof does not make a legend build wait', () {
        // `hasStaticDataUpdateOptions` also serves Chart.js ADR 0092: an
        // indexed chart has no cached entry, and its getStyle needs a context.
        final a = chart(indexed('pie'));
        expect(a.getDatasetMeta(0).controller!.hasDataUpdateOptions, isTrue);
        expect(
          a.getDatasetMeta(0).controller!.hasStaticDataUpdateOptions,
          isFalse,
        );
      });
    });

    // The proof covers the keys of an element and of a dataset view. A function
    // of a chart or plugin option in a shared scope keeps the contract of
    // Chart.js ADR 0074: a data-dependent one needs a full update. A chart with
    // a plain style had this rule first.
    group('a function of the chart or of a plugin in a shared scope', () {
      for (final type in const ['bar', 'pie']) {
        for (final indexedStyle in const [true, false]) {
          final style = indexedStyle ? 'indexed' : 'plain';
          test('layout.padding waits for a full update, a $style $type', () {
            var calls = 0;
            defaults.override(type, <String, Object?>{
              'layout': <String, Object?>{
                'padding': (Object? _) {
                  calls++;
                  return const EdgeInsets.all(1);
                },
              },
            });
            final cfg = indexed(type, plugins: true);
            if (!indexedStyle) {
              dataset(cfg)
                ..['backgroundColor'] = red
                ..['borderColor'] = blue;
            }
            final a = chart(cfg);
            final atStart = calls;
            expect(atStart, greaterThan(0));
            change(cfg, 0);
            expect(a.updateData(), isTrue);
            expect(calls, atStart);
            a.update('none');
            expect(calls, greaterThan(atStart));
          });
        }
      }

      test('a tick callback of the overrides waits for a full update', () {
        var calls = 0;
        List<String>? tick(Object? scale, double value, int _, Object? _) {
          calls++;
          return ['$value'];
        }

        defaults.override('bar', <String, Object?>{
          'scales': <String, Object?>{
            'y': <String, Object?>{
              'ticks': <String, Object?>{'callback': tick},
            },
          },
        });
        final cfg = indexed('bar');
        final a = chart(cfg);
        final atStart = calls;
        expect(atStart, greaterThan(0));
        change(cfg, 0);
        expect(a.updateData(), isTrue);
        expect(calls, atStart);
        a.update('none');
        expect(calls, greaterThan(atStart));
      });
    });

    group('each guard of the proof takes the full path', () {
      /// The own keys and values of the typed scope [scope].
      Map<String, Object?> copyOf(Object? scope) {
        final face = scope! as JsObjectFace;
        return {for (final key in face.jsKeys()) key: face.jsRead(key)};
      }

      /// A chart of [make], with [edit] after the last full update of each
      /// twin, then one tick: no `updateData` came before the edit.
      void expectEdit(
        Map<String, Object?> Function() make,
        void Function(Chart) edit,
      ) {
        final ca = make();
        final cb = make();
        final a = chart(ca);
        final b = chart(cb);
        edit(a);
        edit(b);
        change(ca, 0);
        change(cb, 0);
        expect(a.updateData(), isFalse);
        b.update('none');
        expect(deep(a), deep(b));
        change(ca, 1);
        change(cb, 1);
        a.updateData();
        b.update('none');
        expect(deep(a), deep(b));
      }

      /// A bar chart with a line dataset, the second type of [expectTwin].
      Map<String, Object?> mixed() {
        final cfg = config('bar');
        ((cfg['data']! as Map)['datasets']! as List).add(<String, Object?>{
          'type': 'line',
          'data': <Object?>[2.0, 3.0, 1.0, 2.0],
          'borderColor': blue,
        });
        return cfg;
      }

      test('the control of the edits: a chart with no edit', () {
        expectTwin(() => indexed('pie'), path: true);
        expectTwin(mixed, path: true);
      });

      test('a plain chart with a user Map in the overrides', () {
        final saved = jsGet(overrides, 'pie');
        jsSet(overrides, 'pie', _UserMap(<String, Object?>{}));
        addTearDown(() => jsSet(overrides, 'pie', saved));
        expectTwin(() => config('pie'), path: false, ticks: 2);
      });

      test('a user Map that only the view of a dataset reads', () {
        final datasets = jsGet(defaults, 'datasets');
        jsSet(datasets, 'line', _UserMap(copyOf(jsGet(datasets, 'line'))));
        expectTwin(mixed, path: false, ticks: 2);
      });

      test('a user Map that only the resolver of an element reads', () {
        jsSet(jsGet(overrides, 'pie'), 'elements', <String, Object?>{
          'arc': _UserMap(<String, Object?>{}),
        });
        expectTwin(() => indexed('pie'), path: false, ticks: 2);
      });

      test('a function that only the view of a dataset reads', () {
        defaults.set('datasets.line', <String, Object?>{
          'showLine': (Object? _) => true,
        });
        expectTwin(mixed, path: false, ticks: 2);
      });

      test('a new key in the defaults of the element', () {
        expectEdit(
          () => indexed('pie'),
          (_) => jsSet(
            jsGet(jsGet(defaults, 'elements'), 'arc'),
            'newKeyOfTheProof',
            1.0,
          ),
        );
      });

      test('a route on the elements of the defaults', () {
        var routed = false;
        expectEdit(() => indexed('pie'), (_) {
          if (routed) return;
          routed = true;
          defaults.route('', 'elements', '', 'color');
        });
      });

      test('a Map in the place of the elements of the defaults', () {
        var replaced = false;
        expectEdit(() => indexed('pie'), (_) {
          if (replaced) return;
          replaced = true;
          jsSet(defaults, 'elements', copyOf(jsGet(defaults, 'elements')));
        });
      });

      test('a Map in the place of the defaults of the element', () {
        var replaced = false;
        expectEdit(() => indexed('pie'), (_) {
          if (replaced) return;
          replaced = true;
          final elements = jsGet(defaults, 'elements');
          jsSet(elements, 'arc', copyOf(jsGet(elements, 'arc')));
        });
      });

      test('a route on the type of a typed root', () {
        typed.ChartConfig make() => const typed.ChartConfig(
          type: typed.ChartKind.pie,
          labels: <Object>['a', 'b', 'c'],
          datasets: [
            typed.PieDataset(
              data: [1, 2, 3],
              backgroundColor: typed.ChartValue.indexed([red, blue]),
            ),
          ],
          responsive: false,
          animation: typed.ChartAnimation.none,
          extra: {
            'plugins': {'legend': false, 'tooltip': false, 'colors': false},
          },
        );
        expect(chart(ChartConfigLowering(make()).lower()).updateData(), isTrue);
        final root = ChartConfigLowering(make()).lower();
        final a = chart(root);
        root.addRoute(
          'type',
          ScopeRoute(
            (_) => 'pie',
            targetScope: <String, Object?>{'type': 'pie'},
            targetName: 'type',
          ),
        );
        expect(a.updateData(), isFalse);
      });

      test('a raw borderDash with a foreign item after the first one', () {
        expectTwin(
          () {
            final cfg = indexed('pie');
            dataset(cfg)['borderDash'] = <Object?>[
              1.0,
              <String, Object?>{'a': 1.0},
            ];
            return cfg;
          },
          path: false,
          ticks: 2,
        );
      });

      test('a color in a key of another kind', () {
        expectTwin(
          () {
            final cfg = indexed('scatter');
            dataset(cfg)['pointStyle'] = <Object?>[
              const CirclePointStyle(),
              red,
            ];
            return cfg;
          },
          path: false,
          ticks: 2,
        );
      });

      test('a scalar of a subclass of a color in the defaults', () {
        jsSet(
          jsGet(jsGet(defaults, 'elements'), 'arc'),
          'borderColor',
          const ChartPaint.solid(_UserColor(0xff112233)),
        );
        expectTwin(
          () {
            final cfg = indexed('pie');
            dataset(cfg).remove('borderColor');
            return cfg;
          },
          path: false,
          ticks: 2,
        );
      });

      test('a write of a slot name into the view of the dataset', () {
        expectEdit(() => indexed('pie'), (c) {
          c.getDatasetMeta(0).controller!.options['setContext'] = 1.0;
        });
      });

      test('a write of a slot name into the resolver of the dataset', () {
        expectEdit(() => indexed('pie'), (c) {
          final resolver = c.getDatasetMeta(0).controller!.options['_proxy'];
          jsSet(resolver, '_slotOfTheProof', 1.0);
        });
      });

      test('a write into the resolver of the element', () {
        expectEdit(() => indexed('pie'), (c) {
          final config = c.config;
          final resolver = config.createResolver(
            config.getOptionScopes(
              jsGet(jsGet(c.data, 'datasets'), 0),
              config.datasetElementScopeKeys('pie', 'arc'),
            ),
            null,
            const ['arc', ''],
          );
          jsSet(resolver, 'borderWidth', 2.0);
        });
      });

      test('scopes with no resolver after a clear of the caches', () {
        expectEdit(() => indexed('pie'), (c) {
          final config = c.config..clearCache();
          config.getOptionScopes(
            jsGet(jsGet(c.data, 'datasets'), 0),
            config.datasetElementScopeKeys('pie', 'arc'),
          );
        });
      });

      test('an element type with no native options', () {
        final a = chart(indexed('pie'));
        final config = a.config;
        expect(
          config.hasStaticIndexedElementOptions(
            0,
            controllerType: 'pie',
            elementType: 'arc',
          ),
          isTrue,
        );
        expect(
          config.hasStaticIndexedElementOptions(
            0,
            controllerType: 'pie',
            elementType: 'line',
          ),
          isFalse,
        );
      });

      test('the proof holds for its generation of the caches', () {
        // Chart.js ADR 0100, the contract: an edit in place of an option List
        // waits for the next full update, which proves again.
        final cfg = indexed('pie');
        final a = chart(cfg);
        expect(a.updateData(), isTrue);
        final colors = dataset(cfg)['backgroundColor']! as List<Object?>;
        for (var i = colors.length; i < 8; i++) {
          colors.add(red);
        }
        colors.add((Object? _) => red);
        expect(a.updateData(), isTrue);
        a.update('none');
        expect(a.updateData(), isFalse);
      });
    });

    test('a bubble whose overflow grows runs a layout, as a full update', () {
      final calls = <String>[];
      final plugin = <String, Object?>{
        'id': 'indexedLayoutProbe',
        'supportsDataUpdates': true,
        'beforeLayout': (Object? c, Object? a, Object? o) {
          calls.add('beforeLayout');
        },
      };
      final ca = indexed('bubble');
      final cb = indexed('bubble');
      (ca['plugins'] = <Object?>[plugin]) as List;
      final a = chart(ca);
      final b = chart(cb);
      calls.clear();
      for (final cfg in [ca, cb]) {
        ((dataset(cfg)['data']! as List)[0] as Map)['r'] = 20.0;
      }
      expect(a.updateData(), isTrue);
      expect(calls, ['beforeLayout']);
      b.update('none');
      expect(deep(a), deep(b));
      expect(a.chartArea!.left, b.chartArea!.left);
      calls.clear();
      change(ca, 0);
      change(cb, 0);
      expect(a.updateData(), isTrue);
      expect(calls, isEmpty, reason: 'the same overflow keeps the new layout');
      b.update('none');
      expect(deep(a), deep(b));
    });

    test('the typed lowering of an equal indexed color reaches the path', () {
      typed.ChartConfig cfg(
        List<double> values,
        typed.ChartValue<ChartPaint> c,
      ) => typed.ChartConfig(
        type: typed.ChartKind.pie,
        labels: const <Object>['a', 'b', 'c'],
        datasets: [typed.PieDataset(data: values, backgroundColor: c)],
        responsive: false,
        animation: typed.ChartAnimation.none,
        extra: const {
          'plugins': {'legend': false, 'tooltip': false, 'colors': false},
        },
      );
      final lowering = ChartConfigLowering(
        cfg(const [1, 2, 3], const typed.ChartValue.indexed([red, blue])),
      );
      final a = chart(lowering.lower());
      lowering.apply(
        cfg(const [
          3,
          2,
          1,
        ], typed.ChartValue.indexed(List<ChartPaint>.of(const [red, blue]))),
      );
      expect(lowering.lastApplyDataOnly, isTrue);
      expect(a.updateData(), isTrue);
      expect(
        jsGet(a.getDatasetMeta(0).data[1].options, 'backgroundColor'),
        blue,
      );
      lowering.apply(
        cfg(const [2, 2, 2], const typed.ChartValue.indexed([green, blue])),
      );
      expect(lowering.lastApplyDataOnly, isFalse);
    });
  });

  // Chart.js ADR 0111, section 7: a range update ends as a full update ends,
  // with the tokens of the data-only lifecycle.
  group('after a range update (Chart.js ADR 0111)', () {
    for (final type in ['line', 'bar', 'scatter', 'radar']) {
      test(
        '$type: updateData takes the data-only path with the new ranges',
        () {
          final ca = config(type);
          final cb = config(type);
          final a = chart(ca);
          final b = chart(cb);
          final id = type == 'radar' ? 'r' : 'y';
          for (final c in [a, b]) {
            c.scales[id]!.options
              ..jsWrite('min', 2.0)
              ..jsWrite('max', 8.0);
          }
          expect(a.updateRanges('none'), isTrue);
          b.update('none');
          expect(a.scales[id]!.min, 2);
          expect(a.scales[id]!.max, 8);
          for (var step = 0; step < 2; step++) {
            change(ca, step);
            change(cb, step);
            expect(a.updateData(), isTrue, reason: type);
            b.update('none');
            expect(observe(a), observe(b));
            expect(a.scales[id]!.min, 2);
            expect(a.scales[id]!.max, 8);
          }
        },
      );
    }

    test('a range update after updateData takes the range path', () {
      final cfg = config('line');
      final a = chart(cfg);
      change(cfg, 0);
      expect(a.updateData(), isTrue);
      a.scales['y']!.options.jsWrite('max', 9.0);
      expect(a.updateRanges('none'), isTrue);
      expect(a.scales['y']!.max, 9);
      change(cfg, 1);
      expect(a.updateData(), isTrue);
    });
  });
}
