// Original code, not ported from Chart.js: twins of the direct element writes.
@TestOn('vm')
library;

import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:clock/clock.dart';
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ScriptableContext;
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/options/foreign_audit.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
import 'package:flutter_chartjs_port/src/options/resolved.g.dart'
    show ArcOptions;
import 'package:flutter_chartjs_port/src/typed/axes.dart';
import 'package:flutter_chartjs_port/src/typed/chart_value.dart';
import 'package:flutter_chartjs_port/src/typed/config.dart';
import 'package:flutter_chartjs_port/src/typed/datasets.dart';
import 'package:flutter_chartjs_port/src/typed/groups.dart';
import 'package:flutter_chartjs_port/src/typed/lower.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

const red = ui.Color(0xffff0000);
const blue = ui.Color(0xff0000ff);
const green = ui.Color(0xff00ff00);

// Trivial user subclasses: the exact-class guard fails, and each element takes
// `updateElement`. Their charts are the reference of each twin.
class _RefDoughnut(super.chart, super.datasetIndex, [super.newTarget])
    extends DoughnutController {
  static final value = JsClass(
    'WritesRefDoughnut',
    superclass: DoughnutController.jsClass,
    statics: {'id': 'writes-ref-doughnut'},
    construct: (target, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return _RefDoughnut(chart, datasetIndex, target);
    },
  );
}

class _RefPie(super.chart, super.datasetIndex, [super.newTarget])
    extends PieController {
  static final value = JsClass(
    'WritesRefPie',
    superclass: PieController.jsClass,
    statics: {'id': 'writes-ref-pie'},
    construct: (target, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return _RefPie(chart, datasetIndex, target);
    },
  );
}

class _RefPolar(super.chart, super.datasetIndex, [super.newTarget])
    extends PolarAreaController {
  static final value = JsClass(
    'WritesRefPolar',
    superclass: PolarAreaController.jsClass,
    statics: {'id': 'writes-ref-polarArea'},
    construct: (target, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return _RefPolar(chart, datasetIndex, target);
    },
  );
}

class _RefBubble(super.chart, super.datasetIndex, [super.newTarget])
    extends BubbleController {
  static final value = JsClass(
    'WritesRefBubble',
    superclass: BubbleController.jsClass,
    statics: {'id': 'writes-ref-bubble'},
    construct: (target, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return _RefBubble(chart, datasetIndex, target);
    },
  );
}

/// A user controller: `updateElement` sees each element of each loop.
class _CountingPie(super.chart, super.datasetIndex, [super.newTarget])
    extends PieController {
  static int updates = 0;
  static final value = JsClass(
    'WritesCountingPie',
    superclass: PieController.jsClass,
    statics: {'id': 'writes-counting-pie'},
    construct: (target, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return _CountingPie(chart, datasetIndex, target);
    },
  );
  @override
  void updateElement(
    types.Element element,
    int? index,
    Object properties,
    String mode,
  ) {
    updates++;
    super.updateElement(element, index, properties, mode);
  }
}

// Explicit test opt-in: an arc that takes the typed setters and counts them.
class _ProbeArc() extends ArcElement {
  int assigns = 0;
  int startAngleWrites = 0;
  void Function()? onActive;
  @override
  bool get typedWrites => true;
  @override
  bool get supportsNativeArcOptions => true;
  @override
  void assign(Object source) {
    assigns++;
    super.assign(source);
  }

  @override
  set startAngle(double value) {
    startAngleWrites++;
    super.startAngle = value;
  }

  @override
  bool get active {
    onActive?.call();
    return super.active;
  }
}

// Explicit test opt-in, as the arc above.
class _ProbePoint() extends PointElement {
  int assigns = 0;
  int skipWrites = 0;
  @override
  bool get typedWrites => true;
  @override
  void assign(Object source) {
    assigns++;
    super.assign(source);
  }

  @override
  set skip(bool value) {
    skipWrites++;
    super.skip = value;
  }
}

void _clearCounts(_ProbeArc probe) {
  probe
    ..assigns = 0
    ..startAngleWrites = 0;
}

/// A user arc: its `operator []=` sees each write, by name, in the key order.
class _UserArc(final List<String> writes) extends ArcElement {
  @override
  void operator []=(String prop, Object? value) {
    writes.add(prop);
    super[prop] = value;
  }
}

/// A user point, as [_UserArc].
class _UserPoint(final List<String> writes) extends PointElement {
  @override
  void operator []=(String prop, Object? value) {
    writes.add(prop);
    super[prop] = value;
  }
}

class _ReferenceChart(super.item, super.userConfig) extends Chart {
  @override
  bool get supportsNativePointOptions => false;
}

class _UserRadial(super.cfg) extends RadialLinearScale {
  static final value = JsClass(
    'WritesUserRadial',
    superclass: RadialLinearScale.jsClass,
    statics: {'id': 'writes-user-radial'},
    construct: (_, args) => _UserRadial(scaleCfgArg(args)),
  );
}

class _CustomList(final List<types.Element> values)
    extends ListBase<types.Element> {
  @override
  int get length => values.length;
  @override
  set length(int value) => values.length = value;
  @override
  types.Element operator [](int index) => values[index];
  @override
  void operator []=(int index, types.Element value) => values[index] = value;
}

/// A parsed list of the user: the loop must not treat it as a native list.
class _CustomParsed(final List<Object?> values) extends ListBase<Object?> {
  @override
  int get length => values.length;
  @override
  set length(int value) => values.length = value;
  @override
  Object? operator [](int index) => values[index];
  @override
  void operator []=(int index, Object? value) => values[index] = value;
}

/// A scope of the user: each read of its `operator []` is user code.
class _CountingScope(final Map<String, Object?> own, final List<String> reads)
    extends MapBase<String, Object?> {
  @override
  Object? operator [](Object? key) {
    if (key == 'spacing' || key == 'spacingMode') reads.add(key! as String);
    return own[key];
  }

  @override
  void operator []=(String key, Object? value) => own[key] = value;
  @override
  void clear() => own.clear();
  @override
  Iterable<String> get keys => own.keys;
  @override
  Object? remove(Object? key) => own.remove(key);
}

/// A platform that keeps the option `animation`.
class _AnimatedPlatform() extends BasicPlatform {
  static final JsClass value = JsClass(
    'WritesAnimatedPlatform',
    superclass: BasicPlatform.jsClass,
    construct: (_, _) => _AnimatedPlatform(),
  );
  @override
  void updateConfig(ChartConfiguration config) {}
}

/// A value whose `ToNumber` is user code.
class _Counted(final List<Object?> calls) {
  @override
  String toString() {
    calls.add('toString');
    return '5';
  }
}

/// The arc defaults mask the values of the polar area: the fix-ups of the
/// controller store the values of the polar area into each arc.
Map<String, Object?> _maskedSpacing() => <String, Object?>{
  'spacing': 4.0,
  'spacingMode': ArcSpacingMode.parallel,
  'elements': <String, Object?>{
    'arc': <String, Object?>{
      'spacing': 0.0,
      'spacingMode': ArcSpacingMode.angular,
    },
  },
};

const _arcTypes = ['pie', 'doughnut', 'polarArea'];
const List<String> _allTypes = [..._arcTypes, 'bubble'];

String _refType(String type) => 'writes-ref-$type';

/// A number as a text: a NaN, an infinity and the sign of a zero stay distinct.
/// Two objects give the key order as a list of pairs.
Object? _plain(Object? value) {
  if (value is num) return '${value.toDouble()}';
  if (value is Function) return 'function';
  if (value is Animation) return ['animation', value.active()];
  if (value is JsObjectFace) {
    return [
      for (final key in value.jsKeys()) [key, _plain(value.jsRead(key))],
    ];
  }
  if (value is Map) {
    return [
      for (final entry in value.entries) [entry.key, _plain(entry.value)],
    ];
  }
  if (value is List) return value.map(_plain).toList();
  return value;
}

const _arcNames = [
  'x',
  'y',
  'startAngle',
  'endAngle',
  'circumference',
  'innerRadius',
  'outerRadius',
  'fullCircles',
  'pixelMargin',
  'circular',
];

const _pointNames = ['x', 'y', 'skip', 'stop', 'parsed', 'angle'];

/// What user code can read of an element: each property by name (a property in
/// the `undefined` state stays distinct from NaN), its own keys, its options
/// with their key order, `getProps`, the animation state and its context.
Object? _observeElement(Object? value) {
  final element = value! as Element;
  final names = element is ArcElement ? _arcNames : _pointNames;
  return [
    for (final name in names) _plain(element[name]),
    _plain(element['active']),
    _plain(element['hidden']),
    _plain(element['extra']),
    jsObjectKeys(element),
    _plain(element.options),
    [for (final name in names) _plain(element.getProps(names)[name])],
    [for (final name in names) _plain(element.getProps(names, true)[name])],
    element.$animations?.keys.toList(),
    [
      for (final animation in element.$animations?.values ?? <Animation>[])
        animation.active(),
    ],
    element.$context?.jsKeys(),
    for (final key in const ['index', 'dataIndex', 'mode', 'active', 'parsed'])
      _plain(element.$context?.jsRead(key)),
  ];
}

Object _observe(Chart chart, Map<String, Object?> cfg) {
  final datasets = _datasets(cfg).length;
  return [
    for (var d = 0; d < datasets; d++)
      [
        // controller.doughnut.js:235 `meta.total`, a field of the doughnut
        // controller (row `adapt-native-chart-meta`).
        _plain(switch (chart.getDatasetMeta(d).controller) {
          final DoughnutController doughnut => doughnut.total,
          _ => undefined,
        }),
        for (final element in chart.getDatasetMeta(d).data)
          _observeElement(element),
      ],
  ];
}

Future<Uint8List> _pixels(Chart chart) async {
  chart.draw();
  final canvas = chart.canvas! as UiCanvasElement;
  final recorder = ui.PictureRecorder();
  canvas.getContext2d().paint(ui.Canvas(recorder), ui.Offset.zero, 1, 1);
  final picture = recorder.endRecording();
  final image = await picture.toImage(canvas.width, canvas.height);
  final data = await image.toByteData();
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}

List<Object?> _values(double step, [int length = 8]) => [
  for (var i = 0; i < length; i++) (i + 1) * step + 1,
];

List<Object?> _bubbles(double step, [int length = 8]) => [
  for (var i = 0; i < length; i++)
    <String, Object?>{
      'x': i.toDouble(),
      'y': (i - 3).toDouble() + step,
      'r': 2.0 + i,
    },
];

List<Object?> _data(String type, double step, [int length = 8]) =>
    type.endsWith('bubble') ? _bubbles(step, length) : _values(step, length);

Map<String, Object?> _config(
  String type,
  Map<String, Object?> dataset, {
  Map<String, Object?>? options,
  int length = 8,
}) => {
  'type': type,
  'data': <String, Object?>{
    'labels': <Object?>[for (var i = 0; i < 10; i++) 'L$i'],
    'datasets': <Object?>[
      <String, Object?>{'data': _data(type, 1, length), ...dataset},
    ],
  },
  'options': <String, Object?>{
    'responsive': false,
    'animation': false,
    'events': <String>[],
    'plugins': <String, Object?>{'legend': false, 'tooltip': false},
    ...?options,
  },
};

/// A config of the data-only lifecycle, as the live polar area of the benchmark
/// lab: a fixed radial axis and no plugin.
Map<String, Object?> _liveConfig(
  String type,
  Map<String, Object?> dataset, {
  Map<String, Object?>? options,
}) => _config(
  type,
  dataset,
  options: {
    'scales': <String, Object?>{
      'r': <String, Object?>{'min': 0.0, 'max': 100.0, 'display': false},
    },
    'plugins': <String, Object?>{
      'legend': false,
      'tooltip': false,
      'title': false,
      'subtitle': false,
      'colors': false,
      'decimation': false,
      'filler': false,
    },
    ...?options,
  },
);

List<Object?> _datasets(Map<String, Object?> cfg) =>
    (cfg['data']! as Map<String, Object?>)['datasets']! as List<Object?>;
Map<String, Object?> _first(Map<String, Object?> cfg) =>
    _datasets(cfg)[0]! as Map<String, Object?>;

Chart _chart(Map<String, Object?> cfg) {
  final chart = Chart(UiCanvasElement(width: 480, height: 320), cfg);
  addTearDown(chart.destroy);
  return chart;
}

String _baseType(Map<String, Object?> cfg) =>
    (cfg['type']! as String).replaceFirst('writes-ref-', '');

void _setData(Map<String, Object?> cfg, double step, int length) {
  _first(cfg)['data'] = _data(_baseType(cfg), step, length);
}

/// The steps of a twin: each mode, and each change of the task.
final Map<String, void Function(Chart chart, Map<String, Object?> cfg)> _steps =
    {
      'none': (chart, cfg) => chart.update('none'),
      'new data': (chart, cfg) {
        _setData(cfg, 2, 8);
        chart.update('none');
      },
      'default': (chart, cfg) => chart.update(),
      'reset': (chart, cfg) => chart.update('reset'),
      'after reset': (chart, cfg) => chart.update('none'),
      'chart.reset': (chart, cfg) => chart.reset(),
      'active mode': (chart, cfg) => chart.update('active'),
      'resize mode': (chart, cfg) => chart.update('resize'),
      'resize': (chart, cfg) => chart.resize(400, 300),
      'an item hidden': (chart, cfg) {
        chart
          ..toggleDataVisibility(2)
          ..update('none');
      },
      'an element hidden': (chart, cfg) {
        (chart.getDatasetMeta(0).data[3] as Element).hidden = true;
        chart.update('none');
      },
      'visible again': (chart, cfg) {
        (chart.getDatasetMeta(0).data[3] as Element).hidden = false;
        chart
          ..toggleDataVisibility(2)
          ..update('none');
      },
      'hide a dataset item': (chart, cfg) => chart.hide(0, 1),
      'show a dataset item': (chart, cfg) => chart.show(0, 1),
      'an active element': (chart, cfg) {
        chart
          ..setActiveElements([const ActiveElement(datasetIndex: 0, index: 4)])
          ..update('none');
      },
      'no active element': (chart, cfg) {
        chart
          ..setActiveElements([])
          ..update('none');
      },
      'growing data': (chart, cfg) {
        _setData(cfg, 3, 10);
        chart.update('none');
      },
      'shrinking data': (chart, cfg) {
        _setData(cfg, 4, 5);
        chart.update('none');
      },
      'a NaN and a null value': (chart, cfg) {
        final data = _data(_baseType(cfg), 5);
        if (_baseType(cfg) == 'bubble') {
          data[2] = <String, Object?>{'x': double.nan, 'y': 1.0, 'r': 3.0};
          data[5] = <String, Object?>{'x': 1.0, 'y': null, 'r': 3.0};
        } else {
          data[2] = double.nan;
          data[5] = null;
        }
        _first(cfg)['data'] = data;
        chart.update('none');
      },
      'reset of a NaN value': (chart, cfg) => chart.update('reset'),
      'back to numbers': (chart, cfg) {
        _setData(cfg, 6, 8);
        chart.update('none');
      },
    };

/// Runs a twin of each type against its trivial user subclass.
void _twins(
  String name,
  Map<String, Object?> Function(String type, List<Object?> trace) build, {
  List<String> types = _allTypes,
}) {
  for (final type in types) {
    test('$name: $type', () async {
      final traces = [<Object?>[], <Object?>[]];
      final configs = [
        build(type, traces[0]),
        build(_refType(type), traces[1]),
      ];
      final charts = [_chart(configs[0]), _chart(configs[1])];
      expect(_observe(charts[0], configs[0]), _observe(charts[1], configs[1]));
      for (final MapEntry(key: step, value: run) in _steps.entries) {
        for (var j = 0; j < 2; j++) {
          run(charts[j], configs[j]);
        }
        expect(
          _observe(charts[0], configs[0]),
          _observe(charts[1], configs[1]),
          reason: step,
        );
        expect(traces[0], traces[1], reason: 'trace of $step');
        expect(
          await _pixels(charts[0]),
          await _pixels(charts[1]),
          reason: 'pixels of $step',
        );
      }
    });
  }
}

/// A chart whose arcs or points are [element], after one update.
Chart _withElements(
  Map<String, Object?> cfg,
  Element Function(int index) element,
) {
  final chart = _chart(cfg);
  final data = chart.getDatasetMeta(0).data;
  for (var i = 0; i < data.length; i++) {
    data[i] = element(i);
  }
  return chart;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Chart.register([
    ...registerables,
    _RefDoughnut.value,
    _RefPie.value,
    _RefPolar.value,
    _RefBubble.value,
    _CountingPie.value,
    _UserRadial.value,
  ]);

  setUp(() {
    final saved = foreignAudit;
    foreignAudit = (_, _, _) {};
    addTearDown(() => foreignAudit = saved);
  });

  _twins(
    'constants',
    (type, _) => _config(type, {
      'backgroundColor': const ChartPaint.solid(red),
      'borderColor': const ChartPaint.solid(blue),
      'borderWidth': 2.0,
    }),
  );

  _twins(
    'no border, the fused sector',
    (type, _) => _config(type, {
      'backgroundColor': const ChartPaint.solid(red),
      'borderWidth': 0.0,
    }),
  );

  _twins(
    'indexed colors',
    (type, _) => _config(type, {
      'backgroundColor': <ChartPaint>[
        const ChartPaint.solid(red),
        const ChartPaint.solid(blue),
        const ChartPaint.solid(green),
      ],
      'borderWidth': 0.0,
    }),
  );

  _twins(
    'dataset spacing and offset',
    (type, _) => _config(type, {
      'backgroundColor': const ChartPaint.solid(red),
      'spacing': 3.0,
      'spacingMode': ArcSpacingMode.parallel,
      'offset': 2.0,
    }),
    types: _arcTypes,
  );

  _twins(
    'the spacing of the polar area under the arc defaults',
    (type, _) => _config(type, {
      'backgroundColor': const ChartPaint.solid(red),
    }, options: _maskedSpacing()),
    types: const ['polarArea'],
  );

  _twins(
    'a string spacing',
    (type, _) => _config(type, {
      'backgroundColor': const ChartPaint.solid(red),
      'spacing': '3',
    }),
    types: _arcTypes,
  );

  _twins(
    'a user callback reads the old properties of its element',
    (type, trace) => _config(type, {
      'backgroundColor': (Object? ctx) {
        final context = ctx! as ScriptableContext;
        final element = context.jsRead('element')! as Element;
        trace.add([
          context.index,
          context.mode,
          for (final name in element is ArcElement ? _arcNames : _pointNames)
            _plain(element[name]),
          _plain(element.options),
        ]);
        return ChartPaint.solid(context.index == 1 ? blue : red);
      },
    }),
  );

  _twins(
    'a scriptable dataset option',
    (type, trace) => _config(type, {
      'backgroundColor': const ChartPaint.solid(red),
      'spacing': (Object? ctx) {
        trace.add('spacing');
        return 2.0;
      },
    }),
    types: _arcTypes,
  );

  _twins(
    'a polar area at a start angle of the scale',
    (type, _) => _config(
      type,
      {'backgroundColor': const ChartPaint.solid(red), 'angle': 40.0},
      options: {
        'scales': <String, Object?>{
          'r': <String, Object?>{'startAngle': 30.0, 'display': false},
        },
      },
    ),
    types: const ['polarArea'],
  );

  _twins(
    'a polar area on a user scale',
    (type, _) => _config(
      type,
      {'backgroundColor': const ChartPaint.solid(red)},
      options: {
        'scales': <String, Object?>{
          'r': <String, Object?>{
            'type': 'writes-user-radial',
            'display': false,
          },
        },
      },
    ),
    types: const ['polarArea'],
  );

  _twins(
    'parsing false',
    (type, _) => _config(
      type,
      {'backgroundColor': const ChartPaint.solid(red)},
      options: {'parsing': false},
    ),
    types: const ['pie', 'doughnut'],
  );

  _twins(
    'a bubble chart with a horizontal index axis',
    (type, _) => _config(
      type,
      {'backgroundColor': const ChartPaint.solid(red)},
      options: {'indexAxis': const YAxis()},
    ),
    types: const ['bubble'],
  );

  _twins('two datasets', (type, _) {
    final cfg = _config(type, {'backgroundColor': const ChartPaint.solid(red)});
    _datasets(cfg).add(<String, Object?>{
      'data': _data(type, 2),
      'backgroundColor': const ChartPaint.solid(blue),
    });
    return cfg;
  });

  group('a throw in a resolve', () {
    for (final type in _allTypes) {
      test('leaves the same elements: $type', () {
        var armed = false;
        final results = <Object?>[];
        for (final kind in [type, _refType(type)]) {
          final cfg = _config(kind, {
            'backgroundColor': (Object? ctx) {
              if (armed && (ctx! as ScriptableContext).index == 3) {
                throw StateError('stop');
              }
              return const ChartPaint.solid(red);
            },
          });
          final chart = _chart(cfg);
          _setData(cfg, 2, 8);
          armed = true;
          expect(() => chart.update('none'), throwsStateError);
          armed = false;
          results.add(_observe(chart, cfg));
        }
        expect(results[0], results[1]);
      });
    }
  });

  group('the state of an element', () {
    for (final type in _allTypes) {
      test('an extra key stays: $type', () {
        final results = <Object?>[];
        for (final kind in [type, _refType(type)]) {
          final cfg = _config(kind, {
            'backgroundColor': const ChartPaint.solid(red),
          });
          final chart = _chart(cfg);
          final data = chart.getDatasetMeta(0).data;
          (data[2] as Element)['extra'] = 7.0;
          chart.update('none');
          expect((data[2] as Element)['extra'], 7.0);
          results.add(_observe(chart, cfg));
        }
        expect(results[0], results[1]);
      });
    }

    for (final type in _arcTypes) {
      test('a queued animation runs out equally: $type', () {
        var now = DateTime.utc(2026);
        withClock(Clock(() => now), () {
          final configs = [type, _refType(type)].map((kind) {
            final cfg = _config(kind, {
              'backgroundColor': const ChartPaint.solid(red),
            });
            (cfg['options']! as Map)['animation'] = <String, Object?>{
              'duration': 1000.0,
            };
            cfg['platform'] = _AnimatedPlatform.value;
            return cfg;
          }).toList();
          final charts = configs.map(_chart).toList();
          for (final cfg in configs) {
            _setData(cfg, 2, 8);
          }
          charts[0].update();
          charts[1].update();
          expect(animator.has(charts[0]), isTrue);
          expect(
            _observe(charts[0], configs[0]),
            _observe(charts[1], configs[1]),
          );
          // A direct update over running animations.
          for (final cfg in configs) {
            _setData(cfg, 3, 8);
          }
          charts[0].update('none');
          charts[1].update('none');
          expect(
            _observe(charts[0], configs[0]),
            _observe(charts[1], configs[1]),
          );
          now = now.add(const Duration(milliseconds: 250));
          charts[0].stop();
          charts[1].stop();
          expect(
            _observe(charts[0], configs[0]),
            _observe(charts[1], configs[1]),
          );
        });
      });
    }

    test('the undefined center of a polar area stays undefined', () {
      final results = <Object?>[];
      for (final kind in ['polarArea', _refType('polarArea')]) {
        final cfg = _config(kind, {
          'backgroundColor': const ChartPaint.solid(red),
        });
        final chart = _chart(cfg);
        final meta = chart.getDatasetMeta(0);
        (meta.rScale! as RadialLinearScale)
          ..xCenter = null
          ..yCenter = null;
        meta.controller!.updateElements(meta.data, 0, 8, 'none');
        final arc = meta.data[1] as ArcElement;
        expect(arc['x'], same(undefined));
        expect(arc['y'], same(undefined));
        expect(arc['outerRadius'], isNot(same(undefined)));
        results.add(_observe(chart, cfg));
      }
      expect(results[0], results[1]);
    });

    for (final type in const ['pie', 'doughnut']) {
      test('the undefined radii of a $type stay undefined', () {
        final results = <Object?>[];
        for (final kind in [type, _refType(type)]) {
          final cfg = _config(kind, {
            'backgroundColor': const ChartPaint.solid(red),
          });
          final chart = _chart(cfg);
          final meta = chart.getDatasetMeta(0);
          (meta.controller! as DoughnutController)
            ..innerRadius = null
            ..outerRadius = null
            ..updateElements(meta.data, 0, 8, 'none');
          final arc = meta.data[1] as ArcElement;
          expect(arc['innerRadius'], same(undefined));
          expect(arc['outerRadius'], same(undefined));
          expect(arc['startAngle'], isNot(same(undefined)));
          results.add(_observe(chart, cfg));
        }
        expect(results[0], results[1]);
      });

      test('an undefined offset of a $type gives a NaN center', () {
        final results = <Object?>[];
        for (final kind in [type, _refType(type)]) {
          final cfg = _config(kind, {
            'backgroundColor': const ChartPaint.solid(red),
          });
          final chart = _chart(cfg);
          final meta = chart.getDatasetMeta(0);
          (meta.controller! as DoughnutController)
            ..offsetX = null
            ..offsetY = null
            ..updateElements(meta.data, 0, 8, 'none');
          final arc = meta.data[1] as ArcElement;
          expect(arc.x, isNaN);
          expect(arc['x'], isNot(same(undefined)));
          results.add(_observe(chart, cfg));
        }
        expect(results[0], results[1]);
      });
    }

    test('a partial loop of new arcs after the start', () {
      final results = <Object?>[];
      for (final kind in ['doughnut', _refType('doughnut')]) {
        final cfg = _config(kind, {
          'backgroundColor': const ChartPaint.solid(red),
        });
        final chart = _chart(cfg);
        final meta = chart.getDatasetMeta(0);
        meta.controller!.updateElements(meta.data, 3, 2, 'reset');
        results.add(_observe(chart, cfg));
        meta.controller!.updateElements(meta.data, 3, 2, 'none');
        results.add(_observe(chart, cfg));
      }
      expect(results[0], results[2]);
      expect(results[1], results[3]);
    });
  });

  group('the guards', () {
    for (final type in _arcTypes) {
      Chart probed(String kind, List<_ProbeArc> probes) => _withElements(
        _config(kind, {
          'backgroundColor': const ChartPaint.solid(red),
          'borderWidth': 0.0,
        }),
        (_) {
          final probe = _ProbeArc();
          probes.add(probe);
          return probe;
        },
      );

      test('$type writes with the typed setters in the mode none', () {
        final probes = <_ProbeArc>[];
        final chart = probed(type, probes)..update('none');
        for (final probe in probes) {
          expect(probe.assigns, 0);
          expect(probe.startAngleWrites, 1);
        }
        chart.update('reset');
        for (final probe in probes) {
          expect(probe.assigns, 0);
          expect(probe.startAngleWrites, 2);
        }
      });

      test('a user subclass of $type takes updateElement', () {
        final probes = <_ProbeArc>[];
        probed(_refType(type), probes).update('none');
        for (final probe in probes) {
          expect(probe.assigns, 1);
        }
      });

      test('$type in another mode takes updateElement', () {
        final probes = <_ProbeArc>[];
        probed(type, probes).update();
        for (final probe in probes) {
          // `Animations.update` with no animation assigns the values.
          expect(probe.assigns, 1);
          expect(probe.startAngleWrites, 0);
          expect(probe.startAngle, isNot(isNaN));
        }
      });

      test('a user arc of $type gets each write by name, in the key order', () {
        final expected = type == 'polarArea'
            ? const [
                'x',
                'y',
                'innerRadius',
                'outerRadius',
                'startAngle',
                'endAngle',
                'options',
              ]
            : const [
                'x',
                'y',
                'startAngle',
                'endAngle',
                'circumference',
                'outerRadius',
                'innerRadius',
                'options',
              ];
        final results = <List<String>>[];
        for (final kind in [type, _refType(type)]) {
          final writes = <String>[];
          final chart = _withElements(
            _config(kind, {'backgroundColor': const ChartPaint.solid(red)}),
            (index) => index == 4 ? _UserArc(writes) : ArcElement(),
          );
          writes.clear();
          chart.update('none');
          expect(writes.sublist(writes.length - expected.length), expected);
          results.add(writes);
        }
        expect(results[0], results[1]);
      });
    }

    test('a user override of updateElement sees each arc of a loop', () {
      _CountingPie.updates = 0;
      final chart = _chart(
        _config('writes-counting-pie', {
          'backgroundColor': const ChartPaint.solid(red),
        }),
      );
      final before = _CountingPie.updates;
      chart.update('none');
      expect(_CountingPie.updates - before, 8);
    });

    test('bubble writes with the typed setters in the mode none', () {
      final probes = <_ProbePoint>[];
      final chart = _withElements(
        _config('bubble', {'backgroundColor': const ChartPaint.solid(red)}),
        (_) {
          final probe = _ProbePoint();
          probes.add(probe);
          return probe;
        },
      )..update('none');
      for (final probe in probes) {
        expect(probe.assigns, 0);
        expect(probe.skipWrites, 1);
      }
      chart.update('reset');
      for (final probe in probes) {
        expect(probe.assigns, 0);
        expect(probe.skipWrites, 2);
      }
    });

    test('a user subclass of bubble takes updateElement', () {
      final probes = <_ProbePoint>[];
      _withElements(
        _config(_refType('bubble'), {
          'backgroundColor': const ChartPaint.solid(red),
        }),
        (_) {
          final probe = _ProbePoint();
          probes.add(probe);
          return probe;
        },
      ).update('none');
      for (final probe in probes) {
        expect(probe.assigns, 1);
      }
    });

    test('a user point gets each write by name, in the key order', () {
      final results = <List<String>>[];
      for (final kind in ['bubble', _refType('bubble')]) {
        final writes = <String>[];
        final chart = _withElements(
          _config(kind, {'backgroundColor': const ChartPaint.solid(red)}),
          (index) => index == 4 ? _UserPoint(writes) : PointElement(),
        );
        writes.clear();
        chart.update('none');
        expect(writes, ['x', 'y', 'skip', 'options']);
        results.add(writes);
      }
      expect(results[0], results[1]);
    });

    test('a bubble axis of another class takes the ordinary path', () {
      final results = <Object?>[];
      for (final kind in ['bubble', _refType('bubble')]) {
        final cfg = _config(kind, {
          'backgroundColor': const ChartPaint.solid(red),
        });
        final chart = _chart(cfg);
        final meta = chart.getDatasetMeta(0);
        final writes = <String>[];
        meta.data[2] = _UserPoint(writes);
        // A scale of an axis class that the core does not know: the ordinary
        // path, which writes no value for that axis (row adapt-axis-objects).
        final scale = (meta.vScale! as Scale)..axis = _OtherAxis();
        meta.controller!.updateElements(meta.data, 0, 8, 'none');
        expect(writes, <String>['x', 'skip', 'options']);
        scale.axis = const YAxis();
        results.add(writes);
      }
      expect(results[0], results[1]);
    });

    test('the app library does not export the interface of the writes', () {
      final arc = ArcElement();
      expect(arc.typedWrites, isTrue);
      expect(_UserArc([]).typedWrites, isFalse);
    });
  });

  group('the constant options of a polar area', () {
    /// The value of [key] of each arc, when the arc at index 5 writes a new
    /// value of it into the options while the loop reads its `active`. The plan
    /// has its value already. An ordinary loop reads the new value. With
    /// [invalidate], the write also clears the cache of the controller, for the
    /// options that no fix-up reads: an ordinary loop then resolves again.
    List<Object?> planProbe(
      Map<String, Object?> cfg, {
      Chart Function(Map<String, Object?>)? create,
      OptionKey key = OptionKey.spacing,
      Object? written = 9.0,
      bool invalidate = false,
    }) {
      final chart = (create ?? _chart)(cfg);
      final meta = chart.getDatasetMeta(0);
      var armed = false;
      for (var i = 0; i < meta.data.length; i++) {
        final probe = _ProbeArc();
        if (i == 5) {
          probe.onActive = () {
            if (!armed) return;
            armed = false;
            if (invalidate) {
              _first(cfg)[key.jsName] = written;
              meta.controller!.configure();
            } else {
              meta.controller!.options.jsWrite(key.jsName, written);
            }
          };
        }
        meta.data[i] = probe;
      }
      chart.update('none');
      armed = true;
      chart.update('none');
      return [
        for (final arc in meta.data.cast<ArcElement>())
          (arc.options! as ArcOptions).valueOf(key),
      ];
    }

    const planned = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    const ordinary = [0.0, 0.0, 0.0, 0.0, 0.0, 9.0, 9.0, 9.0];

    test('takes the plan', () {
      expect(
        planProbe(
          _config('polarArea', {
            'backgroundColor': const ChartPaint.solid(red),
          }),
        ),
        planned,
      );
    });

    test('a typed config takes the plan', () {
      const config = ChartConfig(
        type: ChartKind.polarArea,
        labels: ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'],
        datasets: [
          PolarAreaDataset(
            data: [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0],
            backgroundColor: ChartValue.constant(.solid(red)),
            borderWidth: 0,
          ),
        ],
        animation: ChartAnimation.none,
        tooltip: ChartTooltip(enabled: false),
        responsive: false,
        extra: {
          'plugins': {'legend': false},
        },
      );
      final chart = Chart(
        UiCanvasElement(width: 480, height: 320),
        ChartConfigLowering(config).lower(),
      );
      addTearDown(chart.destroy);
      final meta = chart.getDatasetMeta(0);
      final probes = <_ProbeArc>[];
      for (var i = 0; i < meta.data.length; i++) {
        final probe = _ProbeArc();
        probes.add(probe);
        meta.data[i] = probe;
      }
      var armed = true;
      probes[5].onActive = () {
        if (!armed) return;
        armed = false;
        meta.controller!.options.jsWrite('spacing', 9.0);
      };
      chart.update('none');
      expect(armed, isFalse);
      for (final probe in probes) {
        expect((probe.options! as ArcOptions).spacing, 0.0);
        expect(probe.assigns, 0);
        expect(probe.startAngleWrites, 1);
      }
    });

    test('a user subclass declines it', () {
      expect(
        planProbe(
          _config(_refType('polarArea'), {
            'backgroundColor': const ChartPaint.solid(red),
          }),
        ),
        ordinary,
      );
    });

    test('a user chart declines it', () {
      expect(
        planProbe(
          _config('polarArea', {
            'backgroundColor': const ChartPaint.solid(red),
          }),
          create: (cfg) {
            final chart = _ReferenceChart(
              UiCanvasElement(width: 480, height: 320),
              cfg,
            );
            addTearDown(chart.destroy);
            return chart;
          },
        ),
        ordinary,
      );
    });

    test('a user scale declines it', () {
      expect(
        planProbe(
          _config(
            'polarArea',
            {'backgroundColor': const ChartPaint.solid(red)},
            options: {
              'scales': <String, Object?>{
                'r': <String, Object?>{
                  'type': 'writes-user-radial',
                  'display': false,
                },
              },
            },
          ),
        ),
        ordinary,
      );
    });

    test('a custom list of arcs declines it', () async {
      final chart = _chart(
        _config('polarArea', {'backgroundColor': const ChartPaint.solid(red)}),
      );
      final meta = chart.getDatasetMeta(0);
      final probe = _ProbeArc();
      var armed = false;
      probe.onActive = () {
        if (!armed) return;
        armed = false;
        meta.controller!.options.jsWrite('spacing', 9.0);
      };
      final arcs = _CustomList([...meta.data])..[5] = probe;
      // The list of the loop is not the list of the meta: no plan either.
      meta.controller!.update('none');
      meta.data[5] = probe;
      armed = true;
      meta.controller!.updateElements(arcs, 0, 8, 'none');
      expect((arcs[7] as ArcElement).options, isA<ArcOptions>());
      expect(((arcs[7] as ArcElement).options! as ArcOptions).spacing, 9.0);
    });

    test('a native list that is not the list of the meta declines it', () {
      final chart = _chart(
        _config('polarArea', {'backgroundColor': const ChartPaint.solid(red)}),
      );
      final meta = chart.getDatasetMeta(0);
      final probe = _ProbeArc();
      var armed = false;
      probe.onActive = () {
        if (!armed) return;
        armed = false;
        meta.controller!.options.jsWrite('spacing', 9.0);
      };
      final arcs = <types.Element>[...meta.data]..[5] = probe;
      armed = true;
      meta.controller!.updateElements(arcs, 0, 8, 'none');
      expect(armed, isFalse);
      expect(((arcs[7] as ArcElement).options! as ArcOptions).spacing, 9.0);
    });

    test('a shared result declines it: its fix-up throws, as upstream', () {
      for (final kind in ['polarArea', _refType('polarArea')]) {
        final chart = _chart(
          _config(kind, {'backgroundColor': const ChartPaint.solid(red)}),
        );
        chart.getDatasetMeta(0).controller!.enableOptionSharing = true;
        expect(() => chart.update('none'), throwsA(isA<TypeError>()));
      }
    });

    test('a scriptable spacing is called for each arc', () {
      final results = <Object?>[];
      for (final kind in ['polarArea', _refType('polarArea')]) {
        final calls = <Object?>[];
        final chart = _chart(
          _config(kind, {
            'backgroundColor': const ChartPaint.solid(red),
            'spacing': (Object? ctx) {
              calls.add((ctx! as ScriptableContext).index);
              return 0.0;
            },
          }),
        );
        calls.clear();
        chart.update('none');
        expect(calls, isNotEmpty);
        results.add(calls);
      }
      expect(results[0], results[1]);
    });

    test('an angle with a user toString keeps each conversion', () {
      final results = <Object?>[];
      for (final kind in ['polarArea', _refType('polarArea')]) {
        final calls = <Object?>[];
        final chart = _chart(
          _config(kind, {
            'backgroundColor': const ChartPaint.solid(red),
            'angle': _Counted(calls),
          }),
        );
        calls.clear();
        chart.update('none');
        expect(calls, isNotEmpty);
        results.add(calls.length);
      }
      expect(results[0], results[1]);
    });

    test('an active arc ends the plan before its resolve', () {
      final results = <Object?>[];
      for (final kind in ['polarArea', _refType('polarArea')]) {
        final cfg = _config(kind, {
          'backgroundColor': const ChartPaint.solid(red),
          'hoverBorderWidth': 5.0,
        });
        final chart = _chart(cfg)
          ..setActiveElements([const ActiveElement(datasetIndex: 0, index: 4)])
          ..update('none');
        results.add(_observe(chart, cfg));
      }
      expect(results[0], results[1]);
    });

    test('a parsed list of the user declines it', () {
      final results = <Object?>[];
      for (final kind in ['polarArea', _refType('polarArea')]) {
        final cfg = _config(
          kind,
          {
            'backgroundColor': const ChartPaint.solid(red),
            'data': <Object?>[
              for (var i = 0; i < 8; i++) <String, Object?>{'r': i + 1.0},
            ],
          },
          options: {'parsing': false},
        );
        final chart = _chart(cfg)..update('none');
        results.add(_observe(chart, cfg));
      }
      expect(results[0], results[1]);
    });

    test('the template has the fix-ups of each arc', () {
      for (final kind in ['polarArea', _refType('polarArea')]) {
        final chart = _chart(
          _config(kind, {
            'backgroundColor': const ChartPaint.solid(red),
          }, options: _maskedSpacing()),
        )..update('none');
        final arcs = chart.getDatasetMeta(0).data.cast<ArcElement>();
        for (final arc in arcs) {
          final options = arc.options! as ArcOptions;
          expect(options.valueOf(OptionKey.spacing), 4.0, reason: kind);
          expect(
            options.valueOf(OptionKey.spacingMode),
            ArcSpacingMode.parallel,
            reason: kind,
          );
        }
      }
    });

    /// Each arc holds one frozen object, as the shared result upstream.
    void expectShared(Chart chart) {
      final arcs = chart.getDatasetMeta(0).data.cast<ArcElement>();
      final first = arcs.first.options! as ArcOptions;
      expect(first.isFrozen, isTrue);
      for (final arc in arcs) {
        expect(arc.options, same(first));
      }
    }

    test('a shared result with its own spacing declines it', () {
      final results = <Object?>[];
      for (final kind in ['polarArea', _refType('polarArea')]) {
        final cfg = _config(kind, {
          'backgroundColor': const ChartPaint.solid(red),
          'spacing': 3.0,
          'spacingMode': ArcSpacingMode.parallel,
        });
        final chart = _chart(cfg);
        chart.getDatasetMeta(0).controller!.enableOptionSharing = true;
        chart.update('none');
        expectShared(chart);
        results.add(_observe(chart, cfg));
      }
      expect(results[0], results[1]);
    });

    test(
      'a scriptable spacing of the polar area under a fix-up declines it',
      () {
        final results = <Object?>[];
        for (final kind in ['polarArea', _refType('polarArea')]) {
          final calls = <Object?>[];
          results.add(
            planProbe(
              _config(
                kind,
                {'backgroundColor': const ChartPaint.solid(red)},
                options: {
                  'spacing': (Object? ctx) {
                    calls.add('spacing');
                    return 4.0;
                  },
                  'elements': <String, Object?>{
                    'arc': <String, Object?>{'spacing': 0.0},
                  },
                },
              ),
            ),
          );
          expect(calls, isNotEmpty);
        }
        expect(results[0], const [4.0, 4.0, 4.0, 4.0, 4.0, 9.0, 9.0, 9.0]);
        expect(results[0], results[1]);
      },
    );

    test('a scriptable mode of the polar area under a fix-up declines it', () {
      final results = <Object?>[];
      for (final kind in ['polarArea', _refType('polarArea')]) {
        final calls = <Object?>[];
        results.add(
          planProbe(
            _config(
              kind,
              {'backgroundColor': const ChartPaint.solid(red), 'spacing': 3.0},
              options: {
                'spacingMode': (Object? ctx) {
                  calls.add('spacingMode');
                  return ArcSpacingMode.parallel;
                },
                'elements': <String, Object?>{
                  'arc': <String, Object?>{
                    'spacingMode': ArcSpacingMode.angular,
                  },
                },
              },
            ),
            key: OptionKey.spacingMode,
            written: ArcSpacingMode.proportional,
          ),
        );
        expect(calls, isNotEmpty);
      }
      expect(results[0], const [
        ArcSpacingMode.parallel,
        ArcSpacingMode.parallel,
        ArcSpacingMode.parallel,
        ArcSpacingMode.parallel,
        ArcSpacingMode.parallel,
        ArcSpacingMode.proportional,
        ArcSpacingMode.proportional,
        ArcSpacingMode.proportional,
      ]);
      expect(results[0], results[1]);
    });

    test('a scope of the user under a fix-up declines it', () {
      final results = <Object?>[];
      for (final kind in ['polarArea', _refType('polarArea')]) {
        final reads = <String>[];
        final values = planProbe(
          _config(
            kind,
            {'backgroundColor': const ChartPaint.solid(red)},
            options: {
              'datasets': <String, Object?>{
                kind: _CountingScope(<String, Object?>{}, reads),
              },
            },
          ),
        );
        expect(values, ordinary, reason: kind);
        expect(reads, isNotEmpty);
        results.add(reads);
      }
      expect(results[0], results[1]);
    });

    test(
      'a function that no fix-up reads stays uncalled, and the plan runs',
      () {
        final calls = <Object?>[];
        Object? call(Object? ctx) {
          calls.add('called');
          return 1.0;
        }

        final options = <String, Object?>{'spacing': call, 'spacingMode': call};
        final own = <String, Object?>{
          'backgroundColor': const ChartPaint.solid(red),
          'spacing': 3.0,
          'spacingMode': ArcSpacingMode.parallel,
        };
        expect(
          planProbe(
            _config('polarArea', own, options: options),
            invalidate: true,
          ),
          const [3.0, 3.0, 3.0, 3.0, 3.0, 3.0, 3.0, 3.0],
        );
        expect(calls, isEmpty);
        expect(
          planProbe(
            _config(_refType('polarArea'), own, options: options),
            invalidate: true,
          ),
          const [3.0, 3.0, 3.0, 3.0, 3.0, 9.0, 9.0, 9.0],
        );
        expect(calls, isEmpty);
      },
    );

    test('a custom parsed list declines it', () {
      final chart = _chart(
        _config('polarArea', {'backgroundColor': const ChartPaint.solid(red)}),
      );
      final meta = chart.getDatasetMeta(0);
      meta.parsed = _CustomParsed([...meta.parsed]);
      final probe = _ProbeArc();
      var armed = false;
      probe.onActive = () {
        if (!armed) return;
        armed = false;
        meta.controller!.options.jsWrite('spacing', 9.0);
      };
      meta.data[5] = probe;
      chart.update('none');
      expect(meta.parsed, isA<_CustomParsed>());
      armed = true;
      chart.update('none');
      expect(armed, isFalse);
      expect(
        [
          for (final arc in meta.data.cast<ArcElement>())
            (arc.options! as ArcOptions).spacing,
        ],
        const [0.0, 0.0, 0.0, 0.0, 0.0, 9.0, 9.0, 9.0],
      );
    });

    test('two active arcs first: no read ahead of a callback', () {
      final results = <Object?>[];
      for (final kind in ['polarArea', _refType('polarArea')]) {
        var armed = false;
        late final Map<String, Object?> cfg;
        cfg = _config(kind, {
          'backgroundColor': const ChartPaint.solid(red),
          // The active arcs have their own spacing: no fix-up of the first two
          // arcs reads the spacing of the polar area.
          'hoverSpacing': 5.0,
          // The third active arc writes the spacing of the polar area in a
          // callback. The fix-up of the fourth arc is its first read.
          'hoverBorderWidth': (Object? ctx) {
            if (armed && (ctx! as ScriptableContext).index == 2) {
              armed = false;
              _first(cfg)['spacing'] = 7.0;
            }
            return 1.0;
          },
        });
        final chart = _chart(cfg)
          ..setActiveElements([
            const ActiveElement(datasetIndex: 0, index: 0),
            const ActiveElement(datasetIndex: 0, index: 1),
            const ActiveElement(datasetIndex: 0, index: 2),
          ]);
        armed = true;
        chart.update('none');
        expect(armed, isFalse);
        results.add([
          for (final arc in chart.getDatasetMeta(0).data.cast<ArcElement>())
            (arc.options! as ArcOptions).valueOf(OptionKey.spacing),
        ]);
      }
      expect(results[0], results[1]);
      expect(results[0], const [5.0, 5.0, 5.0, 7.0, 7.0, 7.0, 7.0, 7.0]);
    });

    group('the guard reads no key that no fix-up reads', () {
      // The mode that the plugin writes at each value: no write is `angular`,
      // the mode of the fix-up of a polar area, and a stale read of the second
      // write gives the mode of the first.
      final modeAt = {
        10.0: ArcSpacingMode.proportional,
        20.0: ArcSpacingMode.parallel,
        30.0: ArcSpacingMode.proportional,
      };
      for (final MapEntry(key: name, value: own)
          in const <String, Map<String, Object?>>{
            'both own': {
              'spacing': 3.0,
              'spacingMode': ArcSpacingMode.parallel,
            },
            'spacing own': {'spacing': 3.0},
            'mode own': {'spacingMode': ArcSpacingMode.parallel},
            'none own': {},
          }.entries) {
        test(name, () {
          final results = <Object?>[];
          for (final kind in ['polarArea', _refType('polarArea')]) {
            var value = 10.0;
            final trace = <Object?>[];
            final cfg = _config(kind, {
              'backgroundColor': const ChartPaint.solid(red),
              ...own,
            });
            final dataset = _first(cfg);
            cfg['plugins'] = <Object?>[
              Plugin<Object?>(
                id: 'writes-read-back',
                afterDatasetUpdate: (chart, args, options) {
                  final view = (chart as Chart)
                      .getDatasetMeta(0)
                      .controller!
                      .options;
                  if (own.containsKey('spacing')) {
                    dataset['spacing'] = value;
                  }
                  if (own.containsKey('spacingMode')) {
                    dataset['spacingMode'] = modeAt[value];
                  }
                  trace.add([view['spacing'], view['spacingMode']]);
                },
              ),
            ];
            final chart = _chart(cfg);
            value = 20.0;
            chart.update('none');
            value = 30.0;
            chart.update('reset');
            results.add(trace);
          }
          expect(results[0], results[1]);
          final last = (results[0]! as List)[1] as List;
          if (own.containsKey('spacing')) expect(last[0], 20.0);
          if (own.containsKey('spacingMode')) {
            expect(last[1], ArcSpacingMode.parallel);
          }
        });
      }
    });

    group('over a kept entry', () {
      List<Object?> arcValues(Chart chart, OptionKey key) => [
        for (final arc in chart.getDatasetMeta(0).data.cast<ArcElement>())
          (arc.options! as ArcOptions).valueOf(key),
      ];

      /// Probe arcs, with one full update on them. After each call of the
      /// result, the arc at index 5 writes `spacing` while the loop reads its
      /// `active`: first 9, then 10, and so on.
      void Function() armedProbes(Chart chart) {
        final meta = chart.getDatasetMeta(0);
        final probes = <_ProbeArc>[];
        for (var i = 0; i < meta.data.length; i++) {
          final probe = _ProbeArc();
          probes.add(probe);
          meta.data[i] = probe;
        }
        chart.update('none');
        var armed = false;
        var written = 9.0;
        probes[5].onActive = () {
          if (!armed) return;
          armed = false;
          meta.controller!.options.jsWrite('spacing', written++);
        };
        return () {
          probes.forEach(_clearCounts);
          armed = true;
        };
      }

      test('a data-only tick takes the plan', () {
        final cfg = _liveConfig('polarArea', {
          'backgroundColor': const ChartPaint.solid(red),
        });
        final chart = _chart(cfg);
        final arm = armedProbes(chart);
        // A plan has the value of the last tick: it stays in the options.
        var expected = 0.0;
        for (final step in const [2.0, 3.0, 4.0]) {
          _setData(cfg, step, 8);
          arm();
          expect(chart.updateData(), isTrue);
          expect(arcValues(chart, OptionKey.spacing), List.filled(8, expected));
          expected = expected == 0 ? 9 : expected + 1;
          for (final arc in chart.getDatasetMeta(0).data.cast<_ProbeArc>()) {
            expect(arc.assigns, 0);
            expect(arc.startAngleWrites, 1);
          }
        }
      });

      test('a typed config takes the plan on a data-only tick', () {
        // The polar area of the benchmark lab, with a fixed size.
        ChartConfig config(List<double> values) => ChartConfig(
          type: ChartKind.polarArea,
          labels: const ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'],
          datasets: [
            PolarAreaDataset(
              data: values,
              backgroundColor: const ChartValue.constant(.solid(red)),
              borderWidth: 0,
            ),
          ],
          scales: const {
            'r': RadialLinearAxis(
              min: 0,
              max: 100,
              display: false,
              pointLabelsDisplay: false,
              angleLinesDisplay: false,
            ),
          },
          animation: ChartAnimation.none,
          legend: const ChartLegend(display: false),
          tooltip: const ChartTooltip(enabled: false),
          responsive: false,
          extra: const {'events': <String>[]},
        );
        final lowering = ChartConfigLowering(config([1, 2, 3, 4, 5, 6, 7, 8]));
        final chart = Chart(
          UiCanvasElement(width: 480, height: 320),
          lowering.lower(),
        );
        addTearDown(chart.destroy);
        final arm = armedProbes(chart);
        lowering.apply(config([8, 7, 6, 5, 4, 3, 2, 1]));
        expect(lowering.lastApplyDataOnly, isTrue);
        arm();
        expect(chart.updateData(), isTrue);
        expect(arcValues(chart, OptionKey.spacing), planned);
      });

      test('a user subclass ticks through the full update', () {
        final cfg = _liveConfig(_refType('polarArea'), {
          'backgroundColor': const ChartPaint.solid(red),
        });
        final chart = _chart(cfg);
        final arm = armedProbes(chart);
        _setData(cfg, 2, 8);
        arm();
        expect(chart.updateData(), isFalse);
        expect(arcValues(chart, OptionKey.spacing), ordinary);
      });

      /// One data-only tick on the exact chart and one full update on the
      /// trivial user subclass give the same elements and pixels.
      void dataOnlyTwin(
        String name,
        Map<String, Object?> dataset, {
        Map<String, Object?>? options,
        void Function(Chart chart)? prepare,
      }) {
        test('a data-only twin: $name', () async {
          final configs = [
            _liveConfig('polarArea', dataset, options: options),
            _liveConfig(_refType('polarArea'), dataset, options: options),
          ];
          final charts = configs.map(_chart).toList();
          if (prepare != null) charts.forEach(prepare);
          for (final tick in [2.0, 3.0, 4.0, 5.0]) {
            for (final cfg in configs) {
              _setData(cfg, tick, 8);
            }
            expect(charts[0].updateData(), isTrue, reason: '$tick');
            expect(charts[1].updateData(), isFalse, reason: '$tick');
            expect(
              _observe(charts[0], configs[0]),
              _observe(charts[1], configs[1]),
              reason: '$tick',
            );
            expect(await _pixels(charts[0]), await _pixels(charts[1]));
          }
          for (final cfg in configs) {
            final data = _data('polarArea', 6);
            data[2] = double.nan;
            data[5] = null;
            _first(cfg)['data'] = data;
          }
          expect(charts[0].updateData(), isTrue);
          charts[1].updateData();
          expect(
            _observe(charts[0], configs[0]),
            _observe(charts[1], configs[1]),
          );
          expect(await _pixels(charts[0]), await _pixels(charts[1]));
        });
      }

      dataOnlyTwin('constants', {
        'backgroundColor': const ChartPaint.solid(red),
        'borderColor': const ChartPaint.solid(blue),
        'borderWidth': 2.0,
      });
      dataOnlyTwin('no border', {
        'backgroundColor': const ChartPaint.solid(red),
        'borderWidth': 0.0,
      });
      dataOnlyTwin('an own spacing', {
        'backgroundColor': const ChartPaint.solid(red),
        'spacing': 3.0,
        'spacingMode': ArcSpacingMode.parallel,
        'offset': 2.0,
      });
      dataOnlyTwin('a static angle', {
        'backgroundColor': const ChartPaint.solid(red),
        'angle': 40.0,
      });
      dataOnlyTwin('the fix-ups', {
        'backgroundColor': const ChartPaint.solid(red),
      }, options: _maskedSpacing());
      dataOnlyTwin(
        'an active arc',
        {
          'backgroundColor': const ChartPaint.solid(red),
          'hoverBorderWidth': 5.0,
        },
        prepare: (chart) => chart
          ..setActiveElements([const ActiveElement(datasetIndex: 0, index: 4)])
          ..update('none'),
      );
      dataOnlyTwin(
        'a shared result',
        {
          'backgroundColor': const ChartPaint.solid(red),
          'spacing': 3.0,
          'spacingMode': ArcSpacingMode.parallel,
        },
        prepare: (chart) {
          chart.getDatasetMeta(0).controller!.enableOptionSharing = true;
          chart.update('none');
          expectShared(chart);
        },
      );

      test('a direct loop keeps the same arcs', () {
        final results = <Object?>[];
        for (final kind in ['polarArea', _refType('polarArea')]) {
          final cfg = _config(kind, {
            'backgroundColor': const ChartPaint.solid(red),
          }, options: _maskedSpacing());
          final chart = _chart(cfg);
          final meta = chart.getDatasetMeta(0);
          final controller = meta.controller!;
          void loop(int start, int count) {
            controller.updateElements(meta.data, start, count, 'none');
            results.add(_observe(chart, cfg));
          }

          // Over the kept entry: the whole loop, a part of it and two arcs.
          loop(0, 8);
          loop(3, 2);
          loop(0, 2);
          // A write after the entry: each resolve stays a hit of the entry.
          _first(cfg)['spacing'] = 7.0;
          loop(0, 8);
          // An arc that is not native ends the plan before its first read.
          meta.data[4] = _UserArc([]);
          loop(0, 8);
        }
        final half = results.length ~/ 2;
        expect(results.sublist(0, half), results.sublist(half));
      });
    });

    test('each arc has its own options, and a write stays in one arc', () {
      final results = <Object?>[];
      for (final kind in ['polarArea', _refType('polarArea')]) {
        final cfg = _config(kind, {
          'backgroundColor': const ChartPaint.solid(red),
        });
        final chart = _chart(cfg)..update('none');
        final data = chart.getDatasetMeta(0).data.cast<ArcElement>();
        final seen = <Object?>{};
        for (final arc in data) {
          expect(arc.options, isA<ArcOptions>());
          expect(seen.add(arc.options), isTrue);
          expect((arc.options! as ArcOptions).isFrozen, isFalse);
          expect(
            (arc.options! as ArcOptions).valueOf(OptionKey.spacingMode),
            ArcSpacingMode.proportional,
          );
        }
        (data[3].options! as ArcOptions).storeKey(OptionKey.spacing, 4.0);
        results.add(_observe(chart, cfg));
        chart.update('none');
        results.add(_observe(chart, cfg));
      }
      expect(results[0], results[2]);
      expect(results[1], results[3]);
    });
  });

  group('the typed raw reads of an arc', () {
    test('give the value of rawOption in each state of a key', () {
      Object? rawOf(ArcOptions options, OptionKey key) => options.valueOf(key);
      final absent = ArcOptions();
      final foreign = ArcOptions()
        ..storeKey(OptionKey.borderAlign, 7.0)
        ..storeKey(OptionKey.spacingMode, 3.0)
        ..storeKey(OptionKey.borderJoinStyle, 1.0)
        ..storeKey(OptionKey.borderColor, 5.0)
        ..storeKey(OptionKey.backgroundColor, 6.0)
        ..storeKey(OptionKey.borderRadius, 'a')
        ..storeKey(OptionKey.borderDash, 2.0);
      final plain = ArcOptions()
        ..storeKey(OptionKey.borderAlign, ArcBorderAlign.inner)
        ..storeKey(OptionKey.spacingMode, ArcSpacingMode.parallel)
        ..storeKey(OptionKey.borderJoinStyle, 'round')
        ..storeKey(OptionKey.borderColor, red)
        ..storeKey(OptionKey.backgroundColor, blue)
        ..storeKey(OptionKey.borderRadius, 3.0)
        ..storeKey(OptionKey.borderDash, const <double>[1, 2]);
      for (final options in [absent, foreign, plain]) {
        final pairs = <OptionKey, Object?>{
          OptionKey.borderAlign: options.borderAlignValue,
          OptionKey.spacingMode: options.spacingModeValue,
          OptionKey.borderJoinStyle: options.borderJoinStyleValue,
          OptionKey.borderColor: options.borderColorValue,
          OptionKey.backgroundColor: options.backgroundColorValue,
          OptionKey.borderRadius: options.borderRadiusValue,
          OptionKey.borderDash: options.borderDashValue,
        };
        for (final MapEntry(:key, :value) in pairs.entries) {
          expect(value, rawOf(options, key), reason: key.name);
          expect(value, options.jsRead(key.jsName), reason: key.name);
        }
      }
      expect(absent.borderAlignValue, same(undefined));
      expect(foreign.borderRadiusValue, 'a');
      expect(foreign.borderAlignValue, 7.0);
      expect(plain.borderColorValue, red);
    });

    _twins(
      'an inner border, a join style, a dash and a corner',
      (type, _) => _config(type, {
        'backgroundColor': const ChartPaint.solid(red),
        'borderColor': const ChartPaint.solid(blue),
        'borderWidth': 3.0,
        'borderAlign': ArcBorderAlign.inner,
        'borderJoinStyle': ui.StrokeJoin.round,
        'borderDash': <double>[2, 3],
        'borderRadius': 4.0,
      }),
      types: _arcTypes,
    );

    test('the raw options of a drawn arc keep their pixels', () async {
      final bytes = <Uint8List>[];
      for (final fields in [
        <String, Object?>{
          'backgroundColor': const ChartPaint.solid(red),
          'borderWidth': 0.0,
        },
        <String, Object?>{
          'backgroundColor': const ChartPaint.solid(red),
          'borderWidth': 2.0,
          'borderRadius': <String, Object?>{'outerStart': 3.0},
        },
      ]) {
        final chart = _chart(_config('polarArea', fields));
        bytes.add(await _pixels(chart));
      }
      expect(bytes[0], isNot(bytes[1]));
    });
  });
}

/// An axis of a class that the core does not know.
final class _OtherAxis() implements ScaleAxis;
