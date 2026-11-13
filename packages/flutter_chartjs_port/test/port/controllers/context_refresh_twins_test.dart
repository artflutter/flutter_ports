// Original code, not ported from Chart.js: context refresh twins (ADR 0101).
@TestOn('vm')
library;

import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ContextObject, ScriptableContext;
import 'package:flutter_chartjs_port/src/options/props.dart' show BorderSkipped;
import 'package:flutter_test/flutter_test.dart';

const red = ui.Color(0xffff0000);
const blue = ui.Color(0xff0000ff);
const green = ui.Color(0xff00ff00);

// Trivial user subclasses: the exact-class guards fail, with the same results.
class _RefScatter(super.chart, super.datasetIndex, [super.newTarget])
    extends ScatterController {
  static final value = JsClass(
    'RefContextScatter',
    superclass: ScatterController.jsClass,
    statics: {'id': 'ref-scatter'},
    construct: (target, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return _RefScatter(chart, datasetIndex, target);
    },
  );
}

class _RefBubble(super.chart, super.datasetIndex, [super.newTarget])
    extends BubbleController {
  static final value = JsClass(
    'RefContextBubble',
    superclass: BubbleController.jsClass,
    statics: {'id': 'ref-bubble'},
    construct: (target, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return _RefBubble(chart, datasetIndex, target);
    },
  );
}

class _RefLine(super.chart, super.datasetIndex, [super.newTarget])
    extends LineController {
  static final value = JsClass(
    'RefContextLine',
    superclass: LineController.jsClass,
    statics: {'id': 'ref-line'},
    construct: (target, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return _RefLine(chart, datasetIndex, target);
    },
  );
}

class _RefBar(super.chart, super.datasetIndex, [super.newTarget])
    extends BarController {
  static final value = JsClass(
    'RefContextBar',
    superclass: BarController.jsClass,
    statics: {'id': 'ref-bar'},
    construct: (target, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return _RefBar(chart, datasetIndex, target);
    },
  );
}

class _RefDoughnut(super.chart, super.datasetIndex, [super.newTarget])
    extends DoughnutController {
  static final value = JsClass(
    'RefContextDoughnut',
    superclass: DoughnutController.jsClass,
    statics: {'id': 'ref-doughnut'},
    construct: (target, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return _RefDoughnut(chart, datasetIndex, target);
    },
  );
}

class _RefPie(super.chart, super.datasetIndex, [super.newTarget])
    extends PieController {
  static final value = JsClass(
    'RefContextPie',
    superclass: PieController.jsClass,
    statics: {'id': 'ref-pie'},
    construct: (target, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return _RefPie(chart, datasetIndex, target);
    },
  );
}

class _RefPolar(super.chart, super.datasetIndex, [super.newTarget])
    extends PolarAreaController {
  static final value = JsClass(
    'RefContextPolar',
    superclass: PolarAreaController.jsClass,
    statics: {'id': 'ref-polarArea'},
    construct: (target, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return _RefPolar(chart, datasetIndex, target);
    },
  );
}

/// A subclass with its own context reader: each ordinary refresh reaches it.
class _ReadingScatter(super.chart, super.datasetIndex, [super.newTarget])
    extends ScatterController {
  static int reads = 0;
  static final value = JsClass(
    'ReadingContextScatter',
    superclass: ScatterController.jsClass,
    statics: {'id': 'reading-scatter'},
    construct: (target, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return _ReadingScatter(chart, datasetIndex, target);
    },
  );

  @override
  ContextObject getContext([int? index, bool? active, String? mode]) {
    if (index != null) reads++;
    return super.getContext(index, active, mode);
  }
}

// Explicit test opt-in: a counter of the context reads, with native behavior.
class _ProbePoint() extends PointElement {
  int contextReads = 0;
  @override
  bool get supportsNativePointOptions => true;
  @override
  bool get typedWrites => true;
  @override
  ScriptableContext? get $context {
    contextReads++;
    return super.$context;
  }
}

// Test-only opt-in, as in bar_bulk_update_test.dart.
class _ProbeBar() extends BarElement {
  int contextReads = 0;
  int bulkWrites = 0;
  @override
  bool get supportsBulkBarWrites => true;
  @override
  ScriptableContext? get $context {
    contextReads++;
    return super.$context;
  }

  @override
  void writeBulkBar({
    required bool horizontal,
    required double base,
    required double x,
    required double y,
    required double height,
    required double width,
    required Object options,
    required BorderSkipped skipped,
    required double inflate,
  }) {
    bulkWrites++;
    super.writeBulkBar(
      horizontal: horizontal,
      base: base,
      x: x,
      y: y,
      height: height,
      width: width,
      options: options,
      skipped: skipped,
      inflate: inflate,
    );
  }
}

/// A user point: its size and its coordinate writes are user code.
class _UserPoint() extends PointElement {
  void Function()? onUser;
  @override
  double size([Object? options]) {
    onUser?.call();
    return super.size(options);
  }

  @override
  set x(double value) {
    onUser?.call();
    super.x = value;
  }
}

class _ObservedMap(final Map<String, Object?> fields)
    extends MapBase<String, Object?> {
  void Function()? onRead;
  @override
  Object? operator [](Object? key) {
    onRead?.call();
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

const _hooks = [
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
];

const _length = 12;

Object? _plain(Object? value) {
  if (value is double) {
    if (!value.isFinite) return value.toString();
    if (value == 0 && value.isNegative) return '-0';
    return value;
  }
  if (value is Element) return value.runtimeType.toString();
  if (value is JsObjectFace) {
    return {for (final k in value.jsKeys()) k: _plain(value.jsRead(k))};
  }
  if (value is Map) {
    return {for (final e in value.entries) e.key: _plain(e.value)};
  }
  return value;
}

/// The context of each element of each dataset, with its key order, as user
/// code can read it.
String _state(Chart chart) {
  final out = StringBuffer();
  final data = chart.data as Map<String, Object?>;
  final datasets = data['datasets']! as List<Object?>;
  for (var d = 0; d < datasets.length; d++) {
    final elements = chart.getDatasetMeta(d).data;
    for (var i = 0; i < elements.length; i++) {
      final context = (elements[i] as Element).$context;
      if (context == null) {
        out.write('-;');
        continue;
      }
      out
        ..write(context.jsKeys().join(','))
        ..write('|');
      for (final key in context.jsKeys()) {
        if (key == 'element') continue;
        out
          ..write(_plain(context.jsRead(key)))
          ..write('|');
      }
      out.write(';');
    }
    final own = chart.getDatasetMeta(d).controller?.$context;
    if (own != null) {
      out
        ..write('dataset:')
        ..write(own.jsKeys().join(','))
        ..write('|')
        ..write(_plain(own.jsRead('active')))
        ..write(_plain(own.jsRead('mode')))
        ..write(_plain(own.jsRead('index')))
        ..write(';');
    }
  }
  return out.toString();
}

/// The observable results of the elements beside the contexts.
String _results(Chart chart) {
  final out = StringBuffer();
  final data = chart.data as Map<String, Object?>;
  final datasets = data['datasets']! as List<Object?>;
  for (var d = 0; d < datasets.length; d++) {
    final meta = chart.getDatasetMeta(d);
    out.write('clip ${_plain(meta.clip)};');
    for (final element in meta.data.cast<Element>()) {
      out
        ..write(_plain(element.options))
        ..write(_plain(element['x']))
        ..write(_plain(element['y']))
        ..write(';');
    }
  }
  return out.toString();
}

List<Object?> _items(String type, int round, int length) => [
  for (var i = 0; i < length; i++)
    switch (type) {
      'scatter' => <String, Object?>{
        'x': i.toDouble(),
        'y': ((i * 7 + round) % 11).toDouble(),
      },
      'bubble' => <String, Object?>{
        'x': i.toDouble(),
        'y': ((i * 7 + round) % 11).toDouble(),
        'r': (i % 4 + round + 1).toDouble(),
      },
      _ => ((i * 7 + round) % 11 + 1).toDouble(),
    },
];

Map<String, Object?> _config(
  String type, {
  required String id,
  List<Object?> plugins = const [],
  Map<String, Object?> dataset = const {},
  Map<String, Object?> options = const {},
  List<String>? Function(Object?, double, int, Object?)? tickCallback,
  int length = _length,
  int datasets = 1,
}) {
  final scales = switch (type) {
    'scatter' || 'bubble' => <String, Object?>{
      'x': <String, Object?>{
        'type': 'linear',
        if (tickCallback != null)
          'ticks': <String, Object?>{'callback': tickCallback},
      },
      'y': <String, Object?>{'type': 'linear'},
    },
    'line' || 'bar' => <String, Object?>{
      'x': <String, Object?>{
        if (tickCallback != null)
          'ticks': <String, Object?>{'callback': tickCallback},
      },
    },
    'polarArea' => <String, Object?>{
      'r': <String, Object?>{
        if (tickCallback != null)
          'ticks': <String, Object?>{'callback': tickCallback},
      },
    },
    _ => <String, Object?>{},
  };
  return {
    'type': id,
    'data': <String, Object?>{
      if (type != 'scatter' && type != 'bubble')
        'labels': <Object?>[for (var i = 0; i < length; i++) 'item $i'],
      'datasets': <Object?>[
        for (var d = 0; d < datasets; d++)
          <String, Object?>{
            'data': _items(type, d, length),
            'backgroundColor': <ChartPaint>[
              const ChartPaint.solid(red),
              const ChartPaint.solid(blue),
              const ChartPaint.solid(green),
            ],
            'borderColor': <ChartPaint>[
              const ChartPaint.solid(blue),
              const ChartPaint.solid(red),
            ],
            ...dataset,
          },
      ],
    },
    'options': <String, Object?>{
      'responsive': false,
      'animation': false,
      'events': <String>[],
      'plugins': <String, Object?>{
        'legend': false,
        'tooltip': false,
        'title': false,
      },
      if (scales.isNotEmpty) 'scales': scales,
      ...options,
    },
    if (plugins.isNotEmpty) 'plugins': plugins,
  };
}

Chart _chart(Map<String, Object?> config) {
  final chart = Chart(UiCanvasElement(width: 640, height: 400), config);
  addTearDown(chart.destroy);
  return chart;
}

void _replaceData(
  Map<String, Object?> config,
  String type,
  int round, {
  int? length,
}) {
  final data = config['data']! as Map<String, Object?>;
  final datasets = data['datasets']! as List<Object?>;
  for (var d = 0; d < datasets.length; d++) {
    final dataset = datasets[d]! as Map<String, Object?>;
    dataset['data'] = _items(
      type,
      round + d,
      length ?? (dataset['data']! as List<Object?>).length,
    );
  }
}

const _refIds = {
  'scatter': 'ref-scatter',
  'bubble': 'ref-bubble',
  'line': 'ref-line',
  'bar': 'ref-bar',
  'doughnut': 'ref-doughnut',
  'pie': 'ref-pie',
  'polarArea': 'ref-polarArea',
};

/// Runs one chart: the trace has the contexts at each user observation point.
List<String> _run(
  String type,
  String id, {
  required void Function(Chart chart, Map<String, Object?> cfg, String type)
  steps,
  Map<String, Object?> dataset = const {},
  Map<String, Object?> options = const {},
  void Function(Chart chart, String hook)? onHook,
  bool ticks = true,
  int datasets = 1,
}) {
  final trace = <String>[];
  late Chart chart;
  var created = false;
  final plugin = <String, Object?>{
    'id': 'contextTracer',
    for (final hook in _hooks)
      hook: (Object? c, Object? a, Object? o) {
        trace.add('$hook ${_state(c! as Chart)}');
        onHook?.call(c as Chart, hook);
      },
  };
  final cfg = _config(
    type,
    id: id,
    plugins: [plugin],
    dataset: dataset,
    options: options,
    datasets: datasets,
    tickCallback: ticks
        ? (scale, value, index, all) {
            if (created) trace.add('tick $index ${_state(chart)}');
            return ['$value'];
          }
        : null,
  );
  chart = _chart(cfg);
  created = true;
  steps(chart, cfg, type);
  trace
    ..add('end ${_state(chart)}')
    ..add('results ${_results(chart)}');
  return trace;
}

void _rounds(Chart chart, Map<String, Object?> cfg, String type) {
  for (var round = 1; round <= 3; round++) {
    _replaceData(cfg, type, round);
    chart.update('none');
  }
  _replaceData(cfg, type, 4, length: _length - 2);
  chart.update('none');
  _replaceData(cfg, type, 5, length: _length + 3);
  chart
    ..update('none')
    ..update();
  _replaceData(cfg, type, 6);
  chart.update('none');
}

void _expectTwin(
  String type, {
  void Function(Chart chart, Map<String, Object?> cfg, String type) steps =
      _rounds,
  Map<String, Object?> dataset = const {},
  Map<String, Object?> options = const {},
  void Function(Chart chart, String hook)? onHook,
  int datasets = 1,
}) {
  final native = _run(
    type,
    type,
    steps: steps,
    dataset: dataset,
    options: options,
    onHook: onHook,
    datasets: datasets,
  );
  final reference = _run(
    type,
    _refIds[type]!,
    steps: steps,
    dataset: dataset,
    options: options,
    onHook: onHook,
    datasets: datasets,
  );
  expect(native.length, reference.length);
  for (var i = 0; i < native.length; i++) {
    expect(native[i], reference[i], reason: 'trace line $i');
  }
}

List<_ProbePoint> _probes(Chart chart, [int dataset = 0]) {
  final points = chart.getDatasetMeta(dataset).data;
  return [for (var i = 0; i < points.length; i++) points[i] = _ProbePoint()];
}

/// Deletes and reinserts keys of the contexts at a hook, as user code can.
void _editContexts(Chart chart, String hook) {
  if (hook != 'afterLayout' && hook != 'beforeDatasetUpdate') return;
  final elements = chart.getDatasetMeta(0).data;
  if (elements.length < 8) return;
  final first = (elements[3] as Element).$context;
  final second = (elements[5] as Element).$context;
  final third = (elements[6] as Element).$context;
  first?.jsDelete('parsed');
  second?.jsDelete('mode');
  second?.jsDelete('index');
  second?.jsWrite('index', 99.0);
  third
    ?..jsWrite('note', hook)
    ..jsDelete('raw')
    ..jsDelete('active');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Chart.register([
    _RefScatter.value,
    _RefBubble.value,
    _RefLine.value,
    _RefBar.value,
    _RefDoughnut.value,
    _RefPie.value,
    _RefPolar.value,
    _ReadingScatter.value,
  ]);

  group('twins with indexed colors', () {
    for (final type in _refIds.keys) {
      test('$type: contexts at each hook and tick, key order, results', () {
        _expectTwin(type);
      });

      test('$type: deletion and reinsertion of keys by user code', () {
        _expectTwin(type, onHook: _editContexts);
      });

      test('$type: two datasets read each other through the hooks', () {
        _expectTwin(type, datasets: 2);
      });
    }
  });

  group('scatter: the refreshes that wait for the overflow pass', () {
    test('a whole-dataset loop leaves them to the pass, all last written', () {
      final config = _config('scatter', id: 'scatter');
      final chart = _chart(config);
      final probes = _probes(chart);
      chart.update('none');
      for (final probe in probes) {
        probe.contextReads = 0;
      }
      final meta = chart.getDatasetMeta(0);
      meta.controller!.update_('none');
      // The first two items take the ordinary resolve, and the pass reads the
      // context of each item once. A loop that kept its refresh reads twice.
      expect(probes[5].contextReads, 1);
      for (var i = 0; i < _length; i++) {
        final context = probes[i].$context!;
        expect(context.jsRead('mode'), 'default');
        expect(context.jsRead('index'), i);
        expect(context.jsRead('dataIndex'), i);
        expect(context.jsRead('active'), false);
      }
    });

    test('a public call of update keeps each write: no pass follows it', () {
      final config = _config('scatter', id: 'scatter');
      final chart = _chart(config);
      final probes = _probes(chart);
      chart.update('none');
      final meta = chart.getDatasetMeta(0);
      meta.controller!.update('none');
      for (var i = 0; i < _length; i++) {
        expect(probes[i].$context!.jsRead('mode'), 'none', reason: 'item $i');
      }
      final pass = meta.controller!.getMaxOverflow();
      expect(pass, isNot(false));
      for (var i = 0; i < _length; i++) {
        expect(probes[i].$context!.jsRead('mode'), 'default');
      }
    });

    test('a public loop in a scriptable showLine keeps every write', () {
      List<Object?> run(String id) {
        final seen = <Object?>[];
        Chart? chart;
        var active = false;
        final config = _config(
          'scatter',
          id: id,
          dataset: {
            'showLine': (Object? context) {
              final c = chart;
              if (c != null && active) {
                final meta = c.getDatasetMeta(0);
                meta.controller!.updateElements(
                  meta.data,
                  0,
                  meta.data.length,
                  'none',
                );
                seen.add([
                  for (final point in meta.data)
                    (point as Element).$context?.jsRead('mode'),
                ]);
              }
              return false;
            },
          },
        );
        chart = _chart(config);
        active = true;
        chart.update('none');
        seen.add(_state(chart));
        return seen;
      }

      final native = run('scatter');
      final reference = run('ref-scatter');
      expect(native, isNotEmpty);
      expect(
        (native.first! as List<Object?>).every((mode) => mode == 'none'),
        isTrue,
      );
      expect(native, reference);
    });

    test('a public update in the read of a first item keeps every write', () {
      List<Object?> run(String id) {
        final seen = <Object?>[];
        var armed = false;
        var ran = false;
        final config = _config(
          'scatter',
          id: id,
          options: {'parsing': false},
          plugins: [
            <String, Object?>{
              'id': 'arm',
              'beforeDatasetUpdate': (Object? c, Object? a, Object? o) {
                armed = !ran;
              },
            },
          ],
        );
        final chart = _chart(config);
        ran = false;
        armed = false;
        final data = config['data']! as Map<String, Object?>;
        final dataset =
            (data['datasets']! as List<Object?>)[0]! as Map<String, Object?>;
        final items = List<Object?>.of(dataset['data']! as List<Object?>);
        final observed = _ObservedMap(
          Map.of(items[0]! as Map<String, Object?>),
        );
        items[0] = observed;
        dataset['data'] = items;
        observed.onRead = () {
          if (!armed) return;
          armed = false;
          ran = true;
          final meta = chart.getDatasetMeta(0);
          meta.controller!.update('none');
          seen.add([
            for (final point in meta.data)
              (point as Element).$context?.jsRead('mode'),
          ]);
        };
        chart.update('none');
        return seen
          ..add(ran)
          ..add(_results(chart));
      }

      final native = run('scatter');
      expect(native[1], isTrue);
      expect((native[0]! as List<Object?>).skip(2), everyElement('none'));
      expect(native, run('ref-scatter'));
    });

    test('showLine keeps the loop as the last writer', () {
      _expectTwin('scatter', dataset: {'showLine': true});
    });

    test('a scriptable clip reads the contexts of the loop', () {
      List<String> run(String id) {
        final seen = <String>[];
        late Chart chart;
        var ready = false;
        final config = _config(
          'scatter',
          id: id,
          dataset: {
            'clip': (Object? context) {
              if (ready) seen.add(_state(chart));
              return false;
            },
          },
        );
        chart = _chart(config);
        ready = true;
        for (var round = 1; round <= 3; round++) {
          _replaceData(config, 'scatter', round);
          chart.update('none');
        }
        return seen..add(_results(chart));
      }

      final native = run('scatter');
      expect(native.length, greaterThan(3));
      // The read of `clip` stands between the loop and the overflow pass.
      expect(native.first, contains('none'));
      expect(native, run('ref-scatter'));
    });

    test('a constant clip keeps the window and its result', () {
      for (final clip in <Object?>[false, 4.0, 'x']) {
        _expectTwin('scatter', dataset: {'clip': clip});
      }
    });

    test('a clip object declines and keeps its result', () {
      _expectTwin(
        'scatter',
        dataset: {
          'clip': <String, Object?>{'left': 1.0, 'top': 2.0},
        },
      );
    });

    test('the fallback of a clip object runs at the read of clip', () {
      List<String> run(String id) {
        final seen = <String>[];
        late Chart chart;
        var ready = false;
        final config = _config(
          'scatter',
          id: id,
          dataset: {
            'clip': <String, Object?>{
              'left': 1.0,
              '_fallback': (Object? name, Object? value) {
                if (ready) seen.add(_state(chart));
                return false;
              },
            },
          },
        );
        chart = _chart(config);
        ready = true;
        for (var round = 1; round <= 2; round++) {
          _replaceData(config, 'scatter', round);
          chart.update('none');
        }
        return seen..add(_results(chart));
      }

      final native = run('scatter');
      expect(native.length, greaterThan(1));
      expect(native, run('ref-scatter'));
    });

    test('a user Map scope keeps its reads of clip', () {
      final reads = <int>[];
      for (final id in ['scatter', 'ref-scatter']) {
        var count = 0;
        final config = _config('scatter', id: id);
        final data = config['data']! as Map<String, Object?>;
        final dataset =
            (data['datasets']! as List<Object?>)[0]! as Map<String, Object?>;
        final observed = _ObservedMap(Map.of(dataset));
        (data['datasets']! as List<Object?>)[0] = observed;
        final chart = _chart(config);
        observed.onRead = () => count++;
        chart.update('none');
        reads.add(count);
      }
      expect(reads[0], greaterThan(0));
      expect(reads[1], greaterThan(0));
    });

    test('the end of a plan writes the waiting contexts before user code', () {
      for (final at in [0, 1, 2, 3, 7, _length - 1]) {
        List<String> run(String id) {
          final seen = <String>[];
          final config = _config('scatter', id: id);
          final chart = _chart(config);
          final points = chart.getDatasetMeta(0).data;
          final user = _UserPoint();
          points[at] = user;
          user.onUser = () => seen.add(_state(chart));
          chart.update('none');
          _replaceData(config, 'scatter', 1);
          chart.update('none');
          seen
            ..add('end ${_state(chart)}')
            ..add(_results(chart));
          return seen;
        }

        final native = run('scatter');
        final reference = run('ref-scatter');
        expect(native, isNotEmpty);
        expect(native, reference, reason: 'user point at $at');
      }
    });

    test(
      'an active point with a hover callback reads the waiting contexts',
      () {
        for (final at in [2, 6, _length - 1]) {
          List<String> run(String id) {
            final seen = <String>[];
            late Chart chart;
            var ready = false;
            final config = _config(
              'scatter',
              id: id,
              dataset: {
                'hoverBackgroundColor': (Object? context) {
                  if (ready) seen.add(_state(chart));
                  return const ChartPaint.solid(red);
                },
              },
            );
            chart = _chart(config);
            (chart.getDatasetMeta(0).data[at] as PointElement).active = true;
            ready = true;
            chart.update('none');
            _replaceData(config, 'scatter', 1);
            chart.update('none');
            seen
              ..add('end ${_state(chart)}')
              ..add(_results(chart));
            return seen;
          }

          final native = run('scatter');
          final reference = run('ref-scatter');
          expect(native.length, greaterThan(2));
          expect(native, reference, reason: 'active point at $at');
        }
      },
    );

    test('a foreign coordinate reads the waiting contexts', () {
      List<String> run(String id) {
        final seen = <String>[];
        final config = _config('scatter', id: id, options: {'parsing': false});
        final chart = _chart(config);
        final data = config['data']! as Map<String, Object?>;
        final dataset =
            (data['datasets']! as List<Object?>)[0]! as Map<String, Object?>;
        final items = List<Object?>.of(dataset['data']! as List<Object?>);
        final observed = _ObservedMap(
          Map.of(items[8]! as Map<String, Object?>),
        );
        items[8] = observed;
        dataset['data'] = items;
        chart.update('none');
        var busy = false;
        observed.onRead = () {
          if (busy) return;
          busy = true;
          seen.add(_state(chart));
          busy = false;
        };
        chart.update('none');
        seen
          ..add('end ${_state(chart)}')
          ..add(_results(chart));
        return seen;
      }

      final native = run('scatter');
      final reference = run('ref-scatter');
      expect(native.length, greaterThan(2));
      expect(native, reference);
    });

    test('a partial loop keeps its writes: the visible range', () {
      void steps(Chart chart, Map<String, Object?> cfg, String type) {
        for (var round = 1; round <= 3; round++) {
          chart.update('none');
        }
      }

      _expectTwin(
        'scatter',
        steps: steps,
        options: {
          'parsing': false,
          'scales': <String, Object?>{
            'x': <String, Object?>{'type': 'linear', 'min': 3.0, 'max': 6.0},
            'y': <String, Object?>{'type': 'linear'},
          },
        },
      );
    });

    test('a custom point outside a partial loop keeps its calls', () {
      // The visible range of each case leaves out the last points, or also the
      // first: a pass of the whole dataset would leave out their `size`.
      for (final (min, max) in [(3.0, 6.0), (-1.0, 4.0)]) {
        List<String> run(String id) {
          final seen = <String>[];
          final config = _config(
            'scatter',
            id: id,
            options: {
              'parsing': false,
              'scales': <String, Object?>{
                'x': <String, Object?>{
                  'type': 'linear',
                  'min': min,
                  'max': max,
                },
                'y': <String, Object?>{'type': 'linear'},
              },
            },
          );
          final chart = _chart(config);
          final user = _UserPoint();
          chart.getDatasetMeta(0).data[11] = user;
          chart.update('none');
          user.onUser = () => seen.add(_state(chart));
          chart
            ..update('none')
            ..update('none');
          return seen
            ..add('end ${_state(chart)}')
            ..add(_results(chart));
        }

        final native = run('scatter');
        expect(native.length, greaterThan(2));
        expect(native, run('ref-scatter'), reason: 'range $min to $max');
      }
    });

    test('a user context reader takes each refresh', () {
      final config = _config('scatter', id: 'reading-scatter');
      final chart = _chart(config);
      _ReadingScatter.reads = 0;
      chart.update('none');
      // Each of the three passes refreshes each context, and the first resolve
      // of the loop reads the context of its item once more, as upstream.
      expect(_ReadingScatter.reads, _length * 3 + 1);
    });

    test('other modes keep the writes of the loop', () {
      void steps(Chart chart, Map<String, Object?> cfg, String type) {
        for (final mode in ['default', 'resize', 'show', 'reset']) {
          _replaceData(cfg, type, mode.length);
          chart.update(mode);
        }
      }

      _expectTwin('scatter', steps: steps);
    });

    test('an updateData call has the contexts of a full update', () {
      void steps(Chart chart, Map<String, Object?> cfg, String type) {
        for (var round = 1; round <= 3; round++) {
          _replaceData(cfg, type, round);
          chart.updateData();
        }
      }

      _expectTwin('scatter', steps: steps);
    });

    test('a replaced context takes the ordinary factory in the pass', () {
      final config = _config('scatter', id: 'scatter');
      final chart = _chart(config);
      final probes = _probes(chart);
      chart.update('none');
      final old = probes[7].$context;
      probes[7].$context = null;
      chart.getDatasetMeta(0).controller!.update_('none');
      expect(probes[7].$context, isNotNull);
      expect(identical(probes[7].$context, old), isFalse);
      expect(probes[7].$context!.jsRead('mode'), 'default');
      expect(probes[7].$context!.jsRead('index'), 7);
    });
  });

  group('reader sources', () {
    test('line: the prepared loop reads each context once per pass', () {
      final config = _config('line', id: 'line');
      final chart = _chart(config);
      final probes = _probes(chart);
      chart.update('none');
      for (final probe in probes) {
        probe.contextReads = 0;
      }
      chart.update('none');
      expect(probes[6].contextReads, 1);
      expect(probes[6].$context!.jsRead('mode'), 'none');
    });

    test('bubble: the two scans and the loop refresh, the pass is last', () {
      final config = _config('bubble', id: 'bubble');
      final chart = _chart(config);
      final probes = _probes(chart);
      chart.update('none');
      expect(probes[6].$context!.jsRead('mode'), 'default');
      expect(probes[6].$context!.jsRead('index'), 6);
    });

    test('bar: the bulk loop writes through the reader', () {
      final config = _config('bar', id: 'bar');
      final chart = _chart(config);
      final data = chart.getDatasetMeta(0).data;
      final probes = <_ProbeBar>[
        for (var i = 0; i < data.length; i++) data[i] = _ProbeBar(),
      ];
      chart.update('none');
      expect(probes[6].bulkWrites, greaterThan(0));
      expect(probes[6].$context!.jsRead('mode'), 'none');
      expect(probes[6].$context!.jsRead('index'), 6);
      expect(probes[6].$context!.jsRead('dataIndex'), 6);
      expect(probes[6].$context!.jsRead('raw'), isA<double>());
    });
  });
}
