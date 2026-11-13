// Original code, not ported from Chart.js: native arc option-loop twins.
@TestOn('vm')
library;

import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart'
    show Align, Alignment, Directionality, SizedBox, TextDirection;
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart'
    show ChartThemeData, ChartView;
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/core/arc_option_preparation.dart';
import 'package:flutter_chartjs_port/src/core/core.config.dart';
import 'package:flutter_chartjs_port/src/core/data_update.dart'
    show nativeOptionScope;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ScriptableContext;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/options/foreign_audit.dart';
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show ChartOptionsScope;
import 'package:flutter_chartjs_port/src/typed/chart_value.dart';
import 'package:flutter_chartjs_port/src/typed/config.dart';
import 'package:flutter_chartjs_port/src/typed/datasets.dart';
import 'package:flutter_chartjs_port/src/typed/groups.dart';
import 'package:flutter_chartjs_port/src/typed/lower.dart';
import 'package:flutter_test/flutter_test.dart';

const red = ChartPaint.solid(ui.Color(0xffff0000));
const blue = ChartPaint.solid(ui.Color(0xff0000ff));
const green = ChartPaint.solid(ui.Color(0xff00ff00));

// Trivial user subclasses: the same results, with no native loop.
class _RefDoughnut(super.chart, super.datasetIndex, [super.newTarget])
    extends DoughnutController {
  static final value = JsClass(
    'RefDoughnut',
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
    'RefPie',
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
    'RefPolar',
    superclass: PolarAreaController.jsClass,
    statics: {'id': 'ref-polarArea'},
    construct: (target, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return _RefPolar(chart, datasetIndex, target);
    },
  );
}

class _TrivialConfig(super.config) extends Config;

class _ConfigChart(Object item, final Config supplied) extends Chart {
  this : super(item, <String, Object?>{});
  @override
  Config get config => supplied;
}

/// The reference of a twin: a trivial Config in a chart subclass, a trivial
/// controller subclass, or both.
enum _Reference() {
  config,
  controller,
  both,
}

// Explicit test opt-in: counters only, with native reads and writes.
class _ProbeArc() extends ArcElement {
  int contextReads = 0;
  int hiddenReads = 0;
  void Function(int reads)? onHidden;
  @override
  bool get supportsNativeArcOptions => true;
  @override
  ScriptableContext? get $context {
    contextReads++;
    return super.$context;
  }

  @override
  Object? get hidden {
    onHidden?.call(++hiddenReads);
    return super.hidden;
  }
}

// A user subclass: its reads stay observable, so the native loops decline it.
class _UserArc(final List<Object?> trace) extends ArcElement {
  void Function()? onHidden;
  @override
  ScriptableContext? get $context {
    trace.add('context');
    return super.$context;
  }

  @override
  Object? get hidden {
    trace.add('hidden');
    onHidden?.call();
    return super.hidden;
  }
}

class _UserElement() extends ArcElement {
  static final value = JsClass(
    'ArcUserElement',
    superclass: ArcElement.jsClass,
    statics: {'id': 'arc-user-element'},
    construct: (_, _) => _UserElement(),
  );
}

class _ObservedMap(final Map<String, Object?> fields, final List<Object?> reads)
    extends MapBase<String, Object?> {
  void Function(Object? key)? onRead;
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

final class _UserScope() extends ChartOptionsScope;

class _UserRadial(super.cfg) extends RadialLinearScale {
  static List<Object?> trace = [];
  static final value = JsClass(
    'ArcUserRadial',
    superclass: RadialLinearScale.jsClass,
    statics: {'id': 'arc-user-radial'},
    construct: (_, args) => _UserRadial(scaleCfgArg(args)),
  );
  @override
  double getDistanceFromCenterForValue(Object? value) {
    final data = chart.getDatasetMeta(0).data;
    trace.add(data.isEmpty ? null : _contextState(data.last));
    return super.getDistanceFromCenterForValue(value);
  }
}

Object? _contextState(Object? element) {
  final context = (element! as ArcElement).$context;
  return context == null
      ? null
      : [context.jsRead('mode'), context.jsRead('index')];
}

/// The context of each arc of ring 0, as user code can read it.
List<Object?> _arcContexts(Chart chart) => [
  for (final element in chart.getDatasetMeta(0).data)
    if ((element as ArcElement).$context case final context?)
      [
        for (final key in ['index', 'mode', 'active', 'parsed', 'raw'])
          _plain(context.jsRead(key)),
      ]
    else
      null,
];

/// The dataset options that `update` reads between the scans and the loop.
const _updateOptionNames = {
  'spacing',
  'cutout',
  'rotation',
  'circumference',
  'radius',
};

class _ObservedList(final List<Object?> values, final List<Object?> reads)
    extends ListBase<Object?> {
  @override
  int get length {
    reads.add('length');
    return values.length;
  }

  @override
  set length(int value) => values.length = value;
  @override
  Object? operator [](int index) {
    reads.add(index);
    return values[index];
  }

  @override
  void operator []=(int index, Object? value) => values[index] = value;
}

Map<String, Object?> _dataset([Map<String, Object?>? fields]) => {
  'data': <Object?>[3.0, 1.0, 4.0, 1.0, 5.0, 9.0, 2.0, 6.0],
  'borderWidth': 0.0,
  ...?fields,
};

Map<String, Object?> _config(
  String type,
  List<Map<String, Object?>> datasets, [
  Map<String, Object?>? options,
]) => {
  'type': type,
  'data': <String, Object?>{
    'labels': <Object?>['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'],
    'datasets': <Object?>[...datasets],
  },
  'options': <String, Object?>{
    'responsive': false,
    'animation': false,
    'events': <String>[],
    'plugins': <String, Object?>{'legend': false, 'tooltip': false},
    ...?options,
  },
};

List<Object?> _datasets(Map<String, Object?> cfg) =>
    (cfg['data']! as Map<String, Object?>)['datasets']! as List<Object?>;
Map<String, Object?> _first(Map<String, Object?> cfg) =>
    _datasets(cfg)[0]! as Map<String, Object?>;

String _refType(String type) => 'ref-$type';

Chart _native(Map<String, Object?> cfg) {
  final chart = Chart(UiCanvasElement(width: 640, height: 400), cfg);
  addTearDown(chart.destroy);
  return chart;
}

Chart _reference(Map<String, Object?> cfg, _Reference reference) {
  final canvas = UiCanvasElement(width: 640, height: 400);
  final Chart chart;
  if (reference == _Reference.controller) {
    chart = Chart(canvas, cfg);
  } else {
    chart = _ConfigChart(canvas, _TrivialConfig(cfg));
  }
  addTearDown(chart.destroy);
  return chart;
}

Object? _plain(Object? value) {
  if (value is Function) return 'function';
  if (value is double && !value.isFinite) return '$value';
  if (value is JsObjectFace) {
    return {for (final k in value.jsKeys()) k: _plain(value.jsRead(k))};
  }
  if (value is Map) {
    return {for (final e in value.entries) e.key: _plain(e.value)};
  }
  if (value is List) return value.map(_plain).toList();
  return value;
}

Object _observe(Chart chart) {
  final count = _datasets(_rawConfig[chart]!).length;
  return [
    for (var d = 0; d < count; d++)
      [
        for (final element in chart.getDatasetMeta(d).data)
          if (element is ArcElement)
            [
              _plain(element.x),
              _plain(element.y),
              _plain(element.startAngle),
              _plain(element.endAngle),
              _plain(element.circumference),
              _plain(element.innerRadius),
              _plain(element.outerRadius),
              _plain(element.options),
              element.$context?.jsKeys(),
              for (final key in [
                'index',
                'dataIndex',
                'mode',
                'active',
                'parsed',
                'raw',
              ])
                _plain(element.$context?.jsRead(key)),
            ],
      ],
  ];
}

final _rawConfig = Expando<Map<String, Object?>>();

typedef _Step = void Function(Chart chart, Map<String, Object?> cfg);

void _none(Chart chart, Map<String, Object?> cfg) => chart.update('none');

void _newData(Chart chart, Map<String, Object?> cfg) {
  for (final dataset in _datasets(cfg)) {
    (dataset! as Map<String, Object?>)['data'] = <Object?>[
      for (var i = 0; i < 8; i++) (i * 3 + 1).toDouble(),
    ];
  }
  chart.update('none');
}

// New data with two new arcs.
void _growData(Chart chart, Map<String, Object?> cfg) {
  _first(cfg)['data'] = <Object?>[
    for (var i = 0; i < 10; i++) (i * 5 + 2).toDouble(),
  ];
  chart.update('none');
}

// New data, and a `borderColor` that the hover default of an active arc cannot
// read: `getHoverColor(null)` throws in the update loop. The twin compares the
// contexts after the throw.
void _throwInActiveResolve(Chart chart, Map<String, Object?> cfg) {
  _first(cfg)
    ..['data'] = <Object?>[for (var i = 0; i < 8; i++) (i * 7 + 3).toDouble()]
    ..['borderColor'] = null;
  expect(() => chart.update('none'), throwsArgumentError);
  _first(cfg).remove('borderColor');
}

void _activate(Chart chart, double index) => chart.setActiveElements([
  ActiveElement(datasetIndex: 0, index: index.toInt()),
]);

/// The update steps of a twin in the modes of a live chart and of the others.
const List<_Step> _steps = [
  _none,
  _newData,
  _none,
  _default,
  _none,
  _reset,
  _none,
  _scans,
  _none,
];

void _default(Chart chart, Map<String, Object?> cfg) => chart.update();
void _reset(Chart chart, Map<String, Object?> cfg) => chart.update('reset');

// The public calls of the scans outside `update`: each one refreshes each
// context, as upstream.
void _scans(Chart chart, Map<String, Object?> cfg) {
  final controller = chart.getDatasetMeta(0).controller;
  if (controller is DoughnutController) {
    controller
      ..getMaxBorderWidth()
      ..getMaxOffset(chart.getDatasetMeta(0).data);
  }
}

/// Runs a twin of each arc type against each reference.
void _twins(
  String name,
  Map<String, Object?> Function(String type, List<Object?> trace) build, {
  List<_Step> steps = _steps,
  List<String> types = const ['pie', 'doughnut', 'polarArea'],
  List<_Reference> references = _Reference.values,
  void Function(Chart chart, List<Object?> trace)? prepare,
}) {
  for (final type in types) {
    for (final reference in references) {
      test('$name: $type against the ordinary ${reference.name}', () {
        final traces = [<Object?>[], <Object?>[]];
        final refType = reference == _Reference.config ? type : _refType(type);
        final configs = [build(type, traces[0]), build(refType, traces[1])];
        final charts = [_native(configs[0]), _reference(configs[1], reference)];
        _rawConfig[charts[0]] = configs[0];
        _rawConfig[charts[1]] = configs[1];
        expect(_observe(charts[0]), _observe(charts[1]));
        for (var j = 0; j < 2; j++) {
          // The color check of the Chart constructor reads a custom list.
          traces[j].clear();
          prepare?.call(charts[j], traces[j]);
        }
        for (final (index, step) in steps.indexed) {
          for (var j = 0; j < 2; j++) {
            step(charts[j], configs[j]);
          }
          expect(
            _observe(charts[0]),
            _observe(charts[1]),
            reason: 'step $index',
          );
          expect(traces[0], traces[1], reason: 'trace of step $index');
        }
      });
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Chart.register([
    _RefDoughnut.value,
    _RefPie.value,
    _RefPolar.value,
    _UserRadial.value,
    _UserElement.value,
  ]);

  setUp(() {
    final saved = foreignAudit;
    foreignAudit = (_, _, _) {};
    addTearDown(() => foreignAudit = saved);
  });

  _twins(
    'constants',
    (type, _) => _config(type, [
      _dataset({'backgroundColor': red, 'borderColor': blue, 'offset': 2.0}),
    ]),
  );

  _twins(
    'indexed colors',
    (type, _) => _config(type, [
      _dataset({
        'backgroundColor': <ChartPaint>[red, blue, green],
        'borderColor': const <ChartPaint>[blue, red],
      }),
    ]),
  );

  _twins(
    'a non-empty borderDash',
    (type, _) => _config(type, [
      _dataset({
        'backgroundColor': <ChartPaint>[red, blue],
        'borderDash': <double>[2, 3],
        'borderWidth': 2.0,
      }),
    ]),
  );

  _twins(
    'a borderDash of objects',
    (type, _) => _config(type, [
      _dataset({
        'backgroundColor': <ChartPaint>[red, blue],
        'borderDash': <Object?>[
          <String, Object?>{'a': 1.0},
        ],
      }),
    ]),
  );

  _twins(
    'hover options of active arcs',
    (type, _) => _config(type, [
      _dataset({
        'backgroundColor': <ChartPaint>[red, blue, green],
        'hoverBackgroundColor': green,
        'hoverBorderWidth': 5.0,
        'hoverOffset': 7.0,
      }),
    ]),
    prepare: (chart, _) {
      chart.setActiveElements([const ActiveElement(datasetIndex: 0, index: 4)]);
    },
  );

  _twins(
    'an active first arc',
    (type, _) => _config(type, [
      _dataset({
        'backgroundColor': <ChartPaint>[red, blue, green],
        'hoverBackgroundColor': (Object? ctx) => green,
      }),
    ]),
    prepare: (chart, _) {
      chart.setActiveElements([const ActiveElement(datasetIndex: 0, index: 0)]);
    },
  );

  _twins(
    'a scriptable color with one parameter',
    (type, trace) => _config(type, [
      _dataset({
        'backgroundColor': (Object? ctx) {
          final context = ctx! as ScriptableContext;
          trace.add(['color', context.index, context.mode, context.active]);
          return context.index == 1 ? blue : red;
        },
      }),
    ]),
  );

  _twins(
    'a scriptable color with two parameters',
    (type, trace) => _config(type, [
      _dataset({
        'borderColor': (Object? ctx, Object? options) {
          trace.add(jsGet(options, 'borderAlign'));
          return (ctx! as ScriptableContext).index == 1 ? blue : red;
        },
      }),
    ]),
  );

  _twins(
    'an indexed borderWidth and offset',
    (type, _) => _config(type, [
      _dataset({
        'backgroundColor': <ChartPaint>[red, blue],
        'borderWidth': <double>[1, 2, 7],
        'offset': <double>[0, 4, 9, 1],
      }),
    ]),
  );

  _twins(
    'a user indexable predicate',
    (type, trace) => _config(type, [
      _dataset({
        'backgroundColor': <ChartPaint>[red, blue],
        '_indexable': (String name) {
          trace.add(name);
          return name != 'borderDash';
        },
      }),
    ]),
  );

  _twins(
    'a user scriptable predicate',
    (type, trace) => _config(type, [
      _dataset({
        'backgroundColor': <ChartPaint>[red, blue],
        '_scriptable': (String name) {
          trace.add(name);
          return true;
        },
      }),
    ]),
  );

  _twins(
    'a foreign borderWidth, a foreign borderAlign and a string offset',
    (type, _) => _config(type, [
      _dataset({
        'backgroundColor': <ChartPaint>[red, blue],
        'borderWidth': '3',
        'borderAlign': ArcBorderAlign.inner,
        'offset': '2',
      }),
    ]),
  );

  _twins(
    'an inner border',
    (type, _) => _config(type, [
      _dataset({
        'backgroundColor': <ChartPaint>[red, blue],
        'borderWidth': 9.0,
        'borderAlign': ArcBorderAlign.inner,
      }),
    ]),
  );

  _twins(
    'a custom color list',
    (type, trace) => _config(type, [
      _dataset({
        'backgroundColor': _ObservedList(<Object?>[red, blue], trace),
      }),
    ]),
  );

  _twins(
    'color lists that change between the updates',
    (type, _) => _config(type, [
      _dataset({
        'backgroundColor': <ChartPaint>[red, blue],
      }),
    ]),
    steps: [
      _none,
      (chart, cfg) {
        (_first(cfg)['backgroundColor']! as List<ChartPaint>).add(green);
        chart.update('none');
      },
      (chart, cfg) {
        _first(cfg)['backgroundColor'] = <ChartPaint>[blue];
        chart.update('none');
      },
      (chart, cfg) {
        _first(cfg)['backgroundColor'] = green;
        chart.update('none');
      },
      (chart, cfg) {
        _first(cfg)['borderWidth'] = <double>[1, 2];
        chart.update('none');
      },
    ],
  );

  _twins(
    'hidden data',
    (type, _) => _config(type, [
      _dataset({
        'backgroundColor': <ChartPaint>[red, blue, green],
      }),
    ]),
    prepare: (chart, _) {
      chart
        ..toggleDataVisibility(0)
        ..toggleDataVisibility(1)
        ..toggleDataVisibility(5);
    },
  );

  _twins(
    'hidden data under constants',
    (type, _) => _config(type, [
      _dataset({'backgroundColor': red}),
    ]),
    prepare: (chart, _) {
      chart
        ..toggleDataVisibility(1)
        ..toggleDataVisibility(5);
    },
  );

  _twins(
    'a hidden arc through its property',
    (type, _) => _config(type, [
      _dataset({
        'backgroundColor': <ChartPaint>[red, blue],
      }),
    ]),
    prepare: (chart, _) {
      (chart.getDatasetMeta(0).data[3] as ArcElement).hidden = true;
    },
  );

  _twins(
    'a raw angle and spacing of a polar area',
    (type, _) => _config(type, [
      _dataset({
        'backgroundColor': <ChartPaint>[red, blue],
        'angle': 30.0,
        'spacing': 2.0,
        'spacingMode': ArcSpacingMode.proportional,
      }),
    ]),
    types: const ['polarArea'],
  );

  _twins(
    'a constant angle of a polar area',
    (type, _) => _config(type, [
      _dataset({'backgroundColor': red, 'angle': 30.0}),
    ]),
    types: const ['polarArea'],
  );

  _twins(
    'an indexed and a scriptable angle of a polar area',
    (type, trace) => _config(type, [
      _dataset({
        'backgroundColor': <ChartPaint>[red, blue],
        'angle': <double>[10, 20, 30],
      }),
      _dataset({
        'angle': (Object? ctx) {
          trace.add((ctx! as ScriptableContext).index);
          return 45.0;
        },
      }),
    ]),
    types: const ['polarArea'],
  );

  _twins(
    'the first visible dataset of another ring gives the border',
    (type, _) => _config(type, [
      _dataset({
        'backgroundColor': <ChartPaint>[red, blue],
        'borderWidth': 6.0,
      }),
      _dataset({'backgroundColor': green, 'borderWidth': 1.0}),
      _dataset({
        'backgroundColor': <ChartPaint>[blue, green],
        'offset': 3.0,
      }),
    ]),
  );

  _twins(
    'a hidden first dataset',
    (type, _) => _config(type, [
      _dataset({
        'backgroundColor': <ChartPaint>[red, blue],
        'borderWidth': 6.0,
        'hidden': true,
      }),
      _dataset({
        'backgroundColor': <ChartPaint>[green, blue],
        'borderWidth': 2.0,
      }),
    ]),
  );

  _twins(
    'a first dataset of constants before indexed colors',
    (type, _) => _config(type, [
      _dataset({'backgroundColor': red, 'borderWidth': 6.0}),
      _dataset({
        'backgroundColor': <ChartPaint>[green, blue],
        'borderWidth': 2.0,
      }),
    ]),
  );

  _twins(
    'a dataset option that reads an arc context during the update',
    (type, trace) => _config(type, [
      _dataset({
        'backgroundColor': <ChartPaint>[red, blue],
        'cutout': (Object? ctx) {
          final chart = jsGet(ctx, 'chart')! as Chart;
          final data = chart.getDatasetMeta(0).data;
          trace.add(data.isEmpty ? null : _contextState(data.last));
          return const PercentRadius(40);
        },
        'circumference': (Object? ctx) {
          trace.add('circumference');
          return 270.0;
        },
        'rotation': 45.0,
      }),
    ]),
    types: const ['pie', 'doughnut'],
  );

  _twins(
    'parsing false',
    (type, _) => _config(type, [
      _dataset({
        'backgroundColor': <ChartPaint>[red, blue],
        'parsing': false,
        'data': type.endsWith('polarArea')
            ? <Object?>[
                for (var i = 0; i < 8; i++)
                  <String, Object?>{'r': i.toDouble()},
              ]
            : <Object?>[1.0, '2', 3.0, 4.0, null, 6.0, 7.0, 8.0],
      }),
    ]),
  );

  _twins(
    'a rotation, a circumference and a ring weight',
    (type, _) => _config(type, [
      _dataset({
        'backgroundColor': <ChartPaint>[red, blue],
        'rotation': 30.0,
        'circumference': 180.0,
        'weight': 2.0,
      }),
    ]),
    types: const ['pie', 'doughnut'],
  );

  _twins(
    'a key that the arc defaults gain',
    (type, _) => _config(type, [
      _dataset({
        'backgroundColor': <ChartPaint>[red, blue],
        'hoverOffset': <double>[4, 8],
        'hoverBorderWidth': 3.0,
      }),
    ]),
    prepare: (chart, _) {
      final arc = defaults.get('elements.arc');
      (arc as JsObjectFace)
        ..jsWrite('hoverOffset', 0.0)
        ..jsWrite('hoverBorderWidth', 0.0);
    },
    types: const ['pie', 'doughnut'],
  );

  _twins(
    'a custom data list',
    (type, trace) => _config(type, [
      _dataset({
        'backgroundColor': <ChartPaint>[red, blue],
        'data': _ObservedList(<Object?>[1.0, 2.0, 3.0, 4.0, 5.0, 6.0], trace),
      }),
    ]),
    steps: const [_none, _none, _default, _none],
  );

  _twins(
    'a custom dataset Map',
    (type, trace) => _config(type, [
      _ObservedMap(
        _dataset({
          'backgroundColor': <ChartPaint>[red, blue],
        }),
        trace,
      ),
    ]),
    steps: const [_none, _none, _default, _none],
  );

  _twins('a user element class with its own id', (type, _) {
    (defaults.get('datasets.$type') as JsObjectFace).jsWrite(
      'dataElementType',
      'arc-user-element',
    );
    return _config(type, [
      _dataset({
        'backgroundColor': <ChartPaint>[red, blue],
        'offset': 3.0,
        'borderWidth': 2.0,
      }),
    ]);
  });

  _twins(
    'static hover colors of an active arc after the first two',
    (type, _) => _config(type, [
      _dataset({
        'backgroundColor': <ChartPaint>[red, blue, green],
        'hoverBackgroundColor': red,
        'hoverBorderColor': blue,
      }),
    ]),
    prepare: (chart, _) => _activate(chart, 4),
    steps: const [_none, _newData, _growData, _none],
  );

  _twins(
    'a hover callback reads the contexts of the other arcs',
    (type, trace) => _config(type, [
      _dataset({
        'backgroundColor': <ChartPaint>[red, blue, green],
        'hoverBorderWidth': (Object? ctx) {
          trace.add(_arcContexts(jsGet(ctx, 'chart')! as Chart));
          return 3.0;
        },
      }),
    ]),
    prepare: (chart, _) => _activate(chart, 1),
    steps: const [_none, _newData, _growData, _none],
  );

  _twins(
    'a throw in the resolve of an active arc',
    (type, _) => _config(type, [
      _dataset({
        'backgroundColor': <ChartPaint>[red, blue, green],
      }),
    ]),
    prepare: (chart, _) => _activate(chart, 2),
    steps: const [_none, _throwInActiveResolve, _none, _newData],
  );

  for (final (name, fields) in [
    ('a visible dataset', <String, Object?>{}),
    ('a hidden dataset', <String, Object?>{'hidden': true}),
  ]) {
    Map<String, Object?> observed(String type, List<Object?> trace) {
      final cfg = _config(type, [
        _dataset({
          'backgroundColor': <ChartPaint>[red, blue, green],
          ...fields,
        }),
      ]);
      cfg['options'] = _ObservedMap(
        cfg['options']! as Map<String, Object?>,
        trace,
      );
      return cfg;
    }

    // The reads of a controller with another id also name that id.
    _twins(
      'each read of a user options Map, $name',
      observed,
      references: const [_Reference.config],
    );

    // A read of the Map is user code: it sees the contexts of the ordinary path
    // and it can throw there.
    _twins(
      'a user options Map reads the contexts at each read, $name',
      (type, _) => observed(type, <Object?>[]),
      prepare: (chart, trace) {
        (_rawConfig[chart]!['options']! as _ObservedMap).onRead = (key) {
          if (_updateOptionNames.contains(key)) {
            trace.add([key, _arcContexts(chart)]);
          }
        };
      },
      steps: const [_none, _newData, _growData, _none],
    );
  }

  group('user subclasses', () {
    for (final type in ['pie', 'doughnut', 'polarArea']) {
      test('a user arc keeps its reads: $type', () {
        final traces = [<Object?>[], <Object?>[]];
        final configs = [
          _config(type, [
            _dataset({
              'backgroundColor': <ChartPaint>[red, blue, green],
            }),
          ]),
          _config(_refType(type), [
            _dataset({
              'backgroundColor': <ChartPaint>[red, blue, green],
            }),
          ]),
        ];
        final charts = [
          _native(configs[0]),
          _reference(configs[1], _Reference.both),
        ];
        for (var j = 0; j < 2; j++) {
          _rawConfig[charts[j]] = configs[j];
          // One user arc in the middle of native arcs.
          final data = charts[j].getDatasetMeta(0).data;
          data[4] = _UserArc(traces[j]);
        }
        for (var step = 0; step < 3; step++) {
          for (final chart in charts) {
            chart.update('none');
          }
          expect(traces[0], traces[1], reason: 'step $step');
          expect(_observe(charts[0]), _observe(charts[1]));
        }
        expect(traces[0], isNotEmpty);
      });
    }

    for (final type in ['pie', 'doughnut']) {
      for (final (name, fields) in [
        ('shared options', <String, Object?>{'backgroundColor': red}),
        (
          'indexed colors',
          <String, Object?>{
            'backgroundColor': <ChartPaint>[red, blue],
          },
        ),
      ]) {
        test('a user arc that changes the circumference: $type, $name', () {
          final angles = <Object?>[];
          for (final kind in [type, _refType(type)]) {
            final cfg = _config(kind, [_dataset(fields)]);
            final chart = kind == type
                ? _native(cfg)
                : _reference(cfg, _Reference.both);
            final meta = chart.getDatasetMeta(0);
            var armed = false;
            final user = _UserArc(<Object?>[])
              ..onHidden = () {
                if (!armed) return;
                armed = false;
                meta.controller!.options.jsWrite('circumference', 90.0);
              };
            meta.data[4] = user;
            chart.update('none');
            // `calculateTotal` reads the arcs first: arm the read of the loop.
            final controller = meta.controller! as DoughnutController;
            armed = false;
            controller.updateElements(meta.data, 0, 8, 'none');
            armed = true;
            controller.updateElements(meta.data, 0, 8, 'none');
            angles.add([
              for (final arc in meta.data.cast<ArcElement>())
                _plain(arc.circumference),
            ]);
          }
          expect(angles[0], angles[1]);
        });
      }
    }

    test('a user radial scale sees each context refresh of the polar area', () {
      final traces = <List<Object?>>[];
      final results = <Object>[];
      for (final type in ['polarArea', _refType('polarArea')]) {
        final trace = _UserRadial.trace = <Object?>[];
        final cfg = _config(
          type,
          [
            _dataset({
              'backgroundColor': <ChartPaint>[red, blue],
            }),
          ],
          {
            'scales': <String, Object?>{
              'r': <String, Object?>{
                'type': 'arc-user-radial',
                'display': false,
              },
            },
          },
        );
        final chart = type == 'polarArea'
            ? _native(cfg)
            : _reference(cfg, _Reference.both);
        _rawConfig[chart] = cfg;
        chart
          ..update('none')
          ..update('none');
        traces.add(trace);
        results.add(_observe(chart));
      }
      expect(traces[0], traces[1]);
      expect(traces[0], isNotEmpty);
      expect(results[0], results[1]);
    });
  });

  group('the native loops', () {
    Chart probeChart(
      String type,
      List<_ProbeArc> probes, {
      Map<String, Object?>? fields,
    }) {
      final cfg = _config(type, [
        _dataset({
          'backgroundColor': <ChartPaint>[red, blue, green],
          ...?fields,
        }),
      ]);
      final chart = type.startsWith('ref-')
          ? _reference(cfg, _Reference.controller)
          : _native(cfg);
      _rawConfig[chart] = cfg;
      final data = chart.getDatasetMeta(0).data;
      for (var i = 0; i < data.length; i++) {
        final probe = _ProbeArc();
        probes.add(probe);
        data[i] = probe;
      }
      chart.update('none');
      for (final probe in probes) {
        probe.contextReads = 0;
      }
      return chart;
    }

    for (final type in ['pie', 'doughnut']) {
      test('the scans of $type stop after a plan of native colors', () {
        final probes = <_ProbeArc>[];
        probeChart(type, probes).update('none');
        // Scan one reads arcs 0 and 1, scan two arc 0, the shared check arc 0.
        expect(probes.map((p) => p.contextReads), [4, 2, 1, 1, 1, 1, 1, 1]);
      });

      test('the scans of a user subclass of $type read each arc', () {
        final probes = <_ProbeArc>[];
        probeChart(_refType(type), probes).update('none');
        expect(probes.map((p) => p.contextReads), [4, 3, 3, 3, 3, 3, 3, 3]);
      });

      test('the scans of $type in another mode read each arc', () {
        final probes = <_ProbeArc>[];
        probeChart(type, probes).update('resize');
        expect(probes.map((p) => p.contextReads), [4, 3, 3, 3, 3, 3, 3, 3]);
      });

      test('a scriptable dataset option keeps each scan of $type', () {
        final probes = <_ProbeArc>[];
        probeChart(
          type,
          probes,
          fields: {'cutout': (Object? ctx) => const PercentRadius(30)},
        ).update('none');
        expect(probes.map((p) => p.contextReads), [4, 3, 3, 3, 3, 3, 3, 3]);
      });

      test('a second dataset keeps each scan of $type', () {
        final cfg = _config(type, [
          _dataset({
            'backgroundColor': <ChartPaint>[red, blue],
          }),
          _dataset({
            'backgroundColor': <ChartPaint>[red, green],
          }),
        ]);
        final chart = _native(cfg);
        _rawConfig[chart] = cfg;
        final rings = [<_ProbeArc>[], <_ProbeArc>[]];
        for (var d = 0; d < 2; d++) {
          final data = chart.getDatasetMeta(d).data;
          for (var i = 0; i < data.length; i++) {
            final probe = _ProbeArc();
            rings[d].add(probe);
            data[i] = probe;
          }
        }
        chart.update('none');
        // Ring 0: its two scans, its loop, and the border scan of ring 1.
        expect(rings[0].map((p) => p.contextReads), [5, 4, 4, 4, 4, 4, 4, 4]);
        // Ring 1: its offset scan and its loop.
        expect(rings[1].map((p) => p.contextReads), [3, 2, 2, 2, 2, 2, 2, 2]);
      });

      test('a user arc keeps each scan of $type', () {
        final probes = <_ProbeArc>[];
        final chart = probeChart(type, probes);
        chart.getDatasetMeta(0).data[5] = _UserArc(<Object?>[]);
        probes.removeAt(5);
        chart.update('none');
        expect(probes.map((p) => p.contextReads), [4, 3, 3, 3, 3, 3, 3]);
      });

      test('an active arc keeps each scan of $type', () {
        final probes = <_ProbeArc>[];
        final chart = probeChart(type, probes);
        (chart.getDatasetMeta(0).data[5] as ArcElement).active = true;
        chart.update('none');
        expect(probes.map((p) => p.contextReads), [4, 3, 3, 3, 3, 3, 3, 3]);
      });

      test('a user options Map keeps each scan of $type', () {
        final cfg = _config(type, [
          _dataset({
            'backgroundColor': <ChartPaint>[red, blue, green],
          }),
        ]);
        cfg['options'] = _ObservedMap(
          cfg['options']! as Map<String, Object?>,
          <Object?>[],
        );
        final chart = _native(cfg);
        final data = chart.getDatasetMeta(0).data;
        final probes = <_ProbeArc>[];
        for (var i = 0; i < data.length; i++) {
          final probe = _ProbeArc();
          probes.add(probe);
          data[i] = probe;
        }
        chart.update('none');
        for (final probe in probes) {
          probe.contextReads = 0;
        }
        chart.update('none');
        expect(probes.map((p) => p.contextReads), [4, 3, 3, 3, 3, 3, 3, 3]);
      });

      test('parsing false keeps each scan of $type', () {
        final probes = <_ProbeArc>[];
        probeChart(type, probes, fields: {'parsing': false}).update('none');
        expect(probes.map((p) => p.contextReads), [4, 3, 3, 3, 3, 3, 3, 3]);
      });

      test('the loop of $type reads the circumference once', () {
        // A test opt-in that breaks the contract: the probe changes the option
        // in the middle of the loop. The hoisted value does not see it.
        final probes = <_ProbeArc>[];
        final chart = probeChart(
          type,
          probes,
          fields: {'backgroundColor': red},
        );
        final meta = chart.getDatasetMeta(0);
        final controller = meta.controller! as DoughnutController;
        final before = (meta.data[5] as ArcElement).circumference;
        probes[3].onHidden = (_) =>
            controller.options.jsWrite('circumference', 90.0);
        controller.updateElements(meta.data, 0, 8, 'none');
        expect((meta.data[5] as ArcElement).circumference, before);
      });

      test('a user subclass of $type reads the circumference each time', () {
        final probes = <_ProbeArc>[];
        final chart = probeChart(
          _refType(type),
          probes,
          fields: {'backgroundColor': red},
        );
        final meta = chart.getDatasetMeta(0);
        final controller = meta.controller! as DoughnutController;
        final before = (meta.data[5] as ArcElement).circumference;
        probes[3].onHidden = (_) =>
            controller.options.jsWrite('circumference', 90.0);
        controller.updateElements(meta.data, 0, 8, 'none');
        expect((meta.data[5] as ArcElement).circumference, lessThan(before));
      });

      test('constants of $type repeat their frozen cached entry', () {
        final cfg = _config(type, [
          _dataset({'backgroundColor': red}),
        ]);
        final chart = _native(cfg);
        final controller = chart.getDatasetMeta(0).controller!;
        final options = controller.resolveDataElementOptions(0);
        expect(options.isFrozen, isTrue);
        expect(controller.isCachedElementOptions(options), isTrue);
        expect(controller.resolveDataElementOptions(5), same(options));
      });

      for (final (name, kind, expected) in [
        ('uses', type, blue),
        ('does not use', _refType(type), green),
      ]) {
        test('the loop of $kind $name its prepared colors', () {
          // A test opt-in that breaks the contract: the probe changes the
          // source in the middle of the loop. A plan does not see it, a
          // resolve does.
          final probes = <_ProbeArc>[];
          final chart = probeChart(kind, probes);
          final cfg = _rawConfig[chart]!;
          probes[3]
            ..hiddenReads = 0
            ..onHidden = (reads) {
              // Read 1 is `calculateTotal`, read 2 is the loop.
              if (reads != 2) return;
              _first(cfg)['backgroundColor'] = <ChartPaint>[green];
              chart.config.clearCache();
            };
          chart.update('none');
          final arc = chart.getDatasetMeta(0).data[4] as ArcElement;
          expect(jsGet(arc.options, 'backgroundColor'), expected);
        });
      }

      test('prepared colors give fresh options equal to a resolve', () {
        final cfg = _config(type, [
          _dataset({
            'backgroundColor': <ChartPaint>[red, blue, green],
            'borderColor': <ChartPaint>[blue, red],
            'offset': 2.0,
          }),
        ]);
        final chart = _native(cfg);
        final meta = chart.getDatasetMeta(0);
        final controller = meta.controller!;
        final prepared = prepareNativeArcColors(controller, meta.data);
        expect(prepared, isNotNull);
        final seen = <Object>{};
        for (var i = 0; i < 8; i++) {
          final a = prepared!(i);
          final b = controller.resolveDataElementOptions(i, 'none');
          expect(_plain(a), _plain(b));
          expect(a.isFrozen, isFalse);
          expect(seen.add(a), isTrue);
        }
      });
    }

    test('the polar area loop refreshes each context once with a plan', () {
      final probes = <_ProbeArc>[];
      probeChart('polarArea', probes).update('none');
      // Arcs 0 and 1 warm the plan with two resolves each.
      expect(probes.map((p) => p.contextReads), [2, 2, 1, 1, 1, 1, 1, 1]);
    });

    test('a user subclass of the polar area refreshes each context twice', () {
      final probes = <_ProbeArc>[];
      probeChart(_refType('polarArea'), probes).update('none');
      expect(probes.map((p) => p.contextReads), [2, 2, 2, 2, 2, 2, 2, 2]);
    });

    test('another mode refreshes each context of a polar area twice', () {
      final probes = <_ProbeArc>[];
      probeChart('polarArea', probes).update('resize');
      expect(probes.map((p) => p.contextReads), [2, 2, 2, 2, 2, 2, 2, 2]);
    });

    test('a scriptable reverse keeps each context refresh of a polar area', () {
      final cfg = _config(
        'polarArea',
        [
          _dataset({
            'backgroundColor': <ChartPaint>[red, blue],
          }),
        ],
        {
          'scales': <String, Object?>{
            'r': <String, Object?>{'reverse': (Object? ctx) => false},
          },
        },
      );
      final chart = _native(cfg);
      final data = chart.getDatasetMeta(0).data;
      final probes = <_ProbeArc>[];
      for (var i = 0; i < data.length; i++) {
        final probe = _ProbeArc();
        probes.add(probe);
        data[i] = probe;
      }
      chart.update('none');
      expect(probes.map((p) => p.contextReads), [2, 2, 2, 2, 2, 2, 2, 2]);
    });

    test('a user arc ends the plan of a polar area for good', () {
      final probes = <_ProbeArc>[];
      final chart = probeChart('polarArea', probes);
      chart.getDatasetMeta(0).data[3] = _UserArc(<Object?>[]);
      probes.removeAt(3);
      chart.update('none');
      expect(probes.map((p) => p.contextReads), [2, 2, 1, 2, 2, 2, 2]);
    });

    test('parsing false refreshes each context of a polar area twice', () {
      final probes = <_ProbeArc>[];
      probeChart(
        'polarArea',
        probes,
        fields: {
          'parsing': false,
          'data': <Object?>[
            for (var i = 0; i < 8; i++) <String, Object?>{'r': i.toDouble()},
          ],
        },
      ).update('none');
      expect(probes.map((p) => p.contextReads), [2, 2, 2, 2, 2, 2, 2, 2]);
    });

    test('hidden arcs of a polar area keep the one resolve', () {
      final probes = <_ProbeArc>[];
      final chart = probeChart('polarArea', probes)
        ..toggleDataVisibility(0)
        ..toggleDataVisibility(4)
        ..update('none');
      for (final probe in probes) {
        probe.contextReads = 0;
      }
      chart.update('none');
      expect(probes.map((p) => p.contextReads), [1, 2, 1, 1, 1, 1, 1, 1]);
    });

    test('an active arc ends the plan of a polar area for good', () {
      final probes = <_ProbeArc>[];
      final chart = probeChart('polarArea', probes);
      (chart.getDatasetMeta(0).data[3] as ArcElement).active = true;
      chart.update('none');
      expect(probes.map((p) => p.contextReads), [2, 2, 1, 2, 2, 2, 2, 2]);
    });

    group('a typed config with indexed colors', () {
      List<double> values(int shift) => [
        for (var i = 0; i < 8; i++) (i + shift + 1).toDouble(),
      ];
      const color = ChartValue<ChartPaint>.indexed([red, blue]);
      final datasets = <String, Dataset Function(List<double>)>{
        'pie': (data) =>
            PieDataset(data: data, backgroundColor: color, borderWidth: 0),
        'doughnut': (data) =>
            DoughnutDataset(data: data, backgroundColor: color, borderWidth: 0),
        'polarArea': (data) => PolarAreaDataset(
          data: data,
          backgroundColor: color,
          borderWidth: 0,
        ),
      };
      const kinds = {
        'pie': ChartKind.pie,
        'doughnut': ChartKind.doughnut,
        'polarArea': ChartKind.polarArea,
      };
      const expected = {
        'pie': [4, 2, 1, 1, 1, 1, 1, 1],
        'doughnut': [4, 2, 1, 1, 1, 1, 1, 1],
        'polarArea': [2, 2, 1, 1, 1, 1, 1, 1],
      };

      for (final type in kinds.keys) {
        test('$type takes the native loop', () {
          final config = ChartConfig(
            type: kinds[type]!,
            labels: const ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'],
            datasets: [datasets[type]!(values(0))],
            animation: ChartAnimation.none,
            tooltip: const ChartTooltip(enabled: false),
            responsive: false,
            // The labels of a legend read each arc in the layout, also with
            // `display: false`: this test counts the reads of the update.
            extra: const {
              'plugins': {'legend': false},
            },
          );
          final canvas = UiCanvasElement(width: 640, height: 400);
          final chart = Chart(canvas, ChartConfigLowering(config).lower());
          addTearDown(chart.destroy);
          final meta = chart.getDatasetMeta(0);
          final probes = <_ProbeArc>[];
          for (var i = 0; i < meta.data.length; i++) {
            final probe = _ProbeArc();
            probes.add(probe);
            meta.data[i] = probe;
          }
          chart.update('none');
          for (final probe in probes) {
            probe.contextReads = 0;
          }
          chart.update('none');
          expect(probes.map((p) => p.contextReads), expected[type]);
          final arc = meta.data[3] as ArcElement;
          expect(jsGet(arc.options, 'backgroundColor'), blue);
          expect(jsGet(arc.options, r'$shared'), isFalse);
        });

        // The scopes of a chart in a view with a theme are native too.
        testWidgets('$type takes the native loop in a themed view', (
          tester,
        ) async {
          late Chart chart;
          await tester.pumpWidget(
            Directionality(
              textDirection: TextDirection.ltr,
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 640,
                  height: 400,
                  child: ChartView(
                    config: ChartConfig(
                      type: kinds[type]!,
                      labels: const ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'],
                      datasets: [datasets[type]!(values(0))],
                      animation: ChartAnimation.none,
                      tooltip: const ChartTooltip(enabled: false),
                      extra: const {
                        'plugins': {'legend': false},
                      },
                    ),
                    updateMode: 'none',
                    theme: const ChartThemeData(),
                    excludeFromSemantics: true,
                    onChartCreated: (value) => chart = value,
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          final meta = chart.getDatasetMeta(0);
          final probes = <_ProbeArc>[];
          for (var i = 0; i < meta.data.length; i++) {
            final probe = _ProbeArc();
            probes.add(probe);
            meta.data[i] = probe;
          }
          chart.update('none');
          for (final probe in probes) {
            probe.contextReads = 0;
          }
          chart.update('none');
          expect(probes.map((p) => p.contextReads), expected[type]);
        });
      }
    });

    test('a read of a native option scope runs no user code', () {
      expect(nativeOptionScope(<String, Object?>{}), isTrue);
      expect(nativeOptionScope(ChartOptionsScope()), isTrue);
      expect(nativeOptionScope(defaults), isTrue);
      expect(nativeOptionScope(_ObservedMap({}, [])), isFalse);
      expect(nativeOptionScope(_UserScope()), isFalse);
      expect(nativeOptionScope(null), isFalse);
    });

    test('no plan exists for a custom Config', () {
      final cfg = _config('pie', [
        _dataset({
          'backgroundColor': <ChartPaint>[red, blue],
        }),
      ]);
      final chart = _reference(cfg, _Reference.config);
      final meta = chart.getDatasetMeta(0);
      expect(prepareNativeArcColors(meta.controller!, meta.data), isNull);
    });

    test('no plan exists for a varying non-color key', () {
      final cfg = _config('pie', [
        _dataset({
          'backgroundColor': <ChartPaint>[red, blue],
          'offset': <double>[1, 2],
        }),
      ]);
      final chart = _native(cfg);
      final meta = chart.getDatasetMeta(0);
      expect(prepareNativeArcColors(meta.controller!, meta.data), isNull);
    });
  });
}
