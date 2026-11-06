// Original code, not ported from Chart.js: the items of a hidden legend.
@TestOn('vm')
library;

import 'dart:collection';
import 'dart:typed_data' show ByteData;
import 'dart:ui' as ui;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/widgets.dart' hide Element;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart' as typed;
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/controllers/controller.doughnut.dart';
import 'package:flutter_chartjs_port/src/controllers/controller.pie.dart';
import 'package:flutter_chartjs_port/src/controllers/controller.polarArea.dart';
import 'package:flutter_chartjs_port/src/core/core.animation.dart' as core;
import 'package:flutter_chartjs_port/src/core/core.config.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.datasetController.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart' show defaults;
import 'package:flutter_chartjs_port/src/core/core.element.dart' show Element;
import 'package:flutter_chartjs_port/src/core/core.registry.dart' show registry;
import 'package:flutter_chartjs_port/src/elements/element.arc.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show OptionResolver, createResolver, readOption;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ContextObject, ScriptableContext;
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart' show jsCall;
import 'package:flutter_chartjs_port/src/js/js_object.dart'
    show JsObjectFace, jsDeleteKey, jsGet, jsSet;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart' show undefined;
import 'package:flutter_chartjs_port/src/options/foreign_audit.dart'
    show foreignAudit;
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
import 'package:flutter_chartjs_port/src/options/parsed.dart' show ParsedItem;
import 'package:flutter_chartjs_port/src/platform/chart_host.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.legend.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart' show TRBL;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

// The tests of Chart.js ADR 0092 and of the row `adapt-hidden-legend-items`
// of differences.md. A hidden legend of a built-in slice chart leaves its
// items pending, and the first read of `legendItems` builds them.
//
// A twin of a chart is the same config with a `filter` that keeps each item:
// that guard fails, so the twin builds at each upstream point, as upstream.

const _kinds = ['pie', 'doughnut', 'polarArea'];

const _red = Color(0xffff0000);
const _green = Color(0xff00ff00);
const _blue = Color(0xff0000ff);
const _black = Color(0xff000000);

/// The config of a hidden legend of the type [type]. [legend], [labels],
/// [dataset] and [options] add keys to the matching objects.
Map<String, Object?> _config(
  String type, {
  Map<String, Object?> legend = const {},
  Map<String, Object?> labels = const {},
  Map<String, Object?> dataset = const {},
  Map<String, Object?> options = const {},
  Object? labelValues,
  Object? datasets,
  List<Object?>? plugins,
}) => <String, Object?>{
  'type': type,
  'data': <String, Object?>{
    'labels': labelValues ?? <Object?>['a', 'b', 'c'],
    'datasets':
        datasets ??
        <Object?>[
          <String, Object?>{
            'label': 'one',
            'data': <Object?>[1, 2, 3],
            'backgroundColor': _red,
            'borderColor': _blue,
            'borderWidth': 2,
            ...dataset,
          },
        ],
  },
  'options': <String, Object?>{
    'plugins': <String, Object?>{
      'legend': <String, Object?>{
        'display': false,
        'labels': <String, Object?>{...labels},
        ...legend,
      },
    },
    ...options,
  },
  'plugins': ?plugins,
};

bool _keepItem(Object? item, Object? data) => true;

/// The twin of a config of [_config]: it adds the `filter` that keeps each
/// item.
Map<String, Object?> _eager(
  String type, {
  Map<String, Object?> labels = const {},
  Map<String, Object?> legend = const {},
  Map<String, Object?> dataset = const {},
  Map<String, Object?> options = const {},
  List<Object?>? plugins,
}) => _config(
  type,
  labels: {'filter': _keepItem, ...labels},
  legend: legend,
  dataset: dataset,
  options: options,
  plugins: plugins,
);

Legend _legendOf(Chart chart) => chart.legend! as Legend;

/// The items of [legend] as plain data: the keys in order and the values.
List<Object?> _items(types.LegendElement legend) => [
  for (final item in legend.legendItems!)
    [
      for (final key in jsObjectKeys(item)) [key, jsGet(item, key)],
    ],
];

/// The texts of the items of the box of [chart].
List<Object?> _texts(Chart chart) => [
  for (final item in chart.legend!.legendItems!) jsGet(item, 'text'),
];

/// `data.labels` of [chart].
List<Object?> _labelsOf(Chart chart) =>
    jsGet(chart.data, 'labels')! as List<Object?>;

/// `data.datasets` of [chart].
List<Object?> _datasetsOf(Chart chart) =>
    jsGet(chart.data, 'datasets')! as List<Object?>;

/// `options.plugins.legend.labels` of the config of [chart].
Map<String, Object?> _labelOptionsOf(Chart chart) =>
    ((jsGet(chart.config.options, 'plugins')!
                as Map<String, Object?>)['legend']!
            as Map<String, Object?>)['labels']!
        as Map<String, Object?>;

/// An inline plugin with the hook [hook]. A plugin of a chart has one id for
/// each hook name.
Map<String, Object?> _hook(String hook, Object? Function(Chart chart) run) => {
  'id': 'hook-$hook',
  hook: (Chart chart, Object? args, Object? options) => run(chart),
};

/// A list of another class: each read can run user code.
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
  set length(int value) => values.length = value;

  @override
  Object? operator [](int index) {
    reads++;
    return values[index];
  }

  @override
  void operator []=(int index, Object? value) => values[index] = value;
}

/// A trivial user subclass of the pie controller.
final class _PieChild extends PieController {
  _PieChild(super.chart, super.datasetIndex, [super.newTarget]);
}

final JsClass _pieChild = JsClass(
  'PieChild',
  superclass: PieController.jsClass,
  statics: {'id': 'pieChild'},
  construct: (newTarget, args) {
    final (:chart, :datasetIndex) = controllerArgs(args);
    return _PieChild(chart, datasetIndex, newTarget);
  },
);

/// A trivial user subclass of the doughnut controller.
final class _DoughnutChild extends DoughnutController {
  _DoughnutChild(super.chart, super.datasetIndex, [super.newTarget]);
}

final JsClass _doughnutChild = JsClass(
  'DoughnutChild',
  superclass: DoughnutController.jsClass,
  statics: {'id': 'doughnutChild'},
  construct: (newTarget, args) {
    final (:chart, :datasetIndex) = controllerArgs(args);
    return _DoughnutChild(chart, datasetIndex, newTarget);
  },
);

/// A trivial user subclass of the polar area controller.
final class _PolarChild extends PolarAreaController {
  _PolarChild(super.chart, super.datasetIndex, [super.newTarget]);
}

final JsClass _polarChild = JsClass(
  'PolarChild',
  superclass: PolarAreaController.jsClass,
  statics: {'id': 'polarChild'},
  construct: (newTarget, args) {
    final (:chart, :datasetIndex) = controllerArgs(args);
    return _PolarChild(chart, datasetIndex, newTarget);
  },
);

/// A trivial user subclass of the chart.
final class _ChildChart extends Chart {
  _ChildChart(super.item, [super.userConfig]);
}

/// A user subclass of the box, with a count of its builds.
final class _CountingLegend extends Legend {
  _CountingLegend(super.config);

  int builds = 0;

  @override
  void buildLabels() {
    builds++;
    super.buildLabels();
  }
}

final class _Margins implements TRBL {
  @override
  double get top => 0;

  @override
  double get bottom => 0;

  @override
  double get left => 0;

  @override
  double get right => 0;
}

/// The hook names of an update, in their order, for a plugin that reads the
/// items in each one.
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
  'beforeRender',
  'afterRender',
  'beforeDraw',
  'afterDraw',
];

/// An inline plugin that reads the items in each hook of [_hooks], except
/// when [armed] gives false, and appends them to [log].
Map<String, Object?> _reader(List<Object?> log, bool Function() armed) => {
  'id': 'reader',
  for (final hook in _hooks)
    hook: (Chart chart, Object? args, Object? options) {
      if (armed()) log.add([hook, _items(chart.legend!)]);
      return null;
    },
};

// The tests of Chart.js ADR 0099: native indexed colors leave no cached entry,
// and the state that the skipped resolves leave in the contexts stays.

/// The colors of the raw twins.
const _indexedColors = <String, Object?>{
  'backgroundColor': <Object?>[_red, _green],
  'borderColor': <Object?>[_blue, _black, _red],
};

/// The plain form of a value that user code can read.
Object? _plain(Object? value) {
  if (value is Function) return 'function';
  if (value is core.Animation) return 'animation';
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

const _contextKeys = [
  'type',
  'index',
  'dataIndex',
  'datasetIndex',
  'mode',
  'active',
  'parsed',
  'raw',
];

/// A context as user code reads it: its own keys in order and its values.
Object? _contextState(ContextObject? context) => context == null
    ? null
    : [
        context.jsKeys(),
        for (final key in _contextKeys) _plain(jsGet(context, key)),
      ];

/// The context of each arc of dataset [index], and of the dataset itself.
List<Object?> _contexts(Chart chart, [int index = 0]) {
  final meta = chart.getDatasetMeta(index);
  final controller = meta.controller;
  return [
    for (final element in meta.data)
      _contextState((element as Element).$context),
    _contextState(controller?.$context),
  ];
}

/// The geometry, the state and the options of each arc of dataset [index].
List<Object?> _arcs(Chart chart, [int index = 0]) => [
  for (final element in chart.getDatasetMeta(index).data)
    if (element is ArcElement)
      [
        _plain(element.x),
        _plain(element.y),
        _plain(element.startAngle),
        _plain(element.endAngle),
        _plain(element.circumference),
        _plain(element.innerRadius),
        _plain(element.outerRadius),
        element.active,
        _plain(element.options),
      ],
];

/// All that a reader can see of dataset 0, without the items of the legend.
List<Object?> _state(Chart chart) => [_contexts(chart), _arcs(chart)];

/// The bytes of the bitmap of [chart], as the chart host paints it.
Future<ByteData> _pixels(WidgetTester tester, Chart chart) async {
  final canvas = chart.canvas! as UiCanvasElement;
  final recorder = ui.PictureRecorder();
  canvas.getContext2d().paint(ui.Canvas(recorder), Offset.zero, 1, 1);
  final picture = recorder.endRecording();
  final image = picture.toImageSync(canvas.width, canvas.height);
  try {
    return (await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawStraightRgba),
    ))!;
  } finally {
    image.dispose();
    picture.dispose();
  }
}

/// The first dataset of the config of [chart].
Map<String, Object?> _dataset0(Chart chart) =>
    _datasetsOf(chart)[0]! as Map<String, Object?>;

/// The steps of the twins of Chart.js ADR 0099. Each one gives a chart an
/// update of another state of the data or of the options.
final Map<String, void Function(Chart chart)> _steps = {
  'mode none': (chart) => chart.update('none'),
  'mode default': (chart) => chart.update(),
  'mode resize': (chart) => chart.update('resize'),
  'mode active': (chart) => chart.update('active'),
  'a new data List': (chart) {
    _dataset0(chart)['data'] = <Object?>[4.0, 5.0, 6.0];
    chart.update('none');
  },
  'an in-place value': (chart) {
    (_dataset0(chart)['data']! as List<Object?>)[1] = 9.0;
    chart.update('none');
  },
  'more data and labels': (chart) {
    _labelsOf(chart).addAll(<Object?>['d', 'e']);
    _dataset0(chart)['data'] = <Object?>[1.0, 2.0, 3.0, 4.0, 5.0];
    chart.update('none');
  },
  'less data and labels': (chart) {
    _labelsOf(chart).removeRange(3, 5);
    _dataset0(chart)['data'] = <Object?>[3.0, 2.0, 1.0];
    chart.update('none');
  },
  'more labels than data': (chart) {
    _labelsOf(chart).addAll(<Object?>['d', 'e']);
    chart.update('none');
  },
  'fewer labels than data': (chart) {
    _labelsOf(chart).removeRange(1, 5);
    chart.update('none');
  },
  'the same labels again': (chart) {
    _labelsOf(chart).addAll(<Object?>['b', 'c']);
    chart.update('none');
  },
  'a hidden item': (chart) {
    chart
      ..toggleDataVisibility(1)
      ..update('none');
  },
  'the item again': (chart) {
    chart
      ..toggleDataVisibility(1)
      ..update('none');
  },
  'new colors': (chart) {
    _dataset0(chart)['backgroundColor'] = <Object?>[_blue, _red, _green];
    chart.update('none');
  },
  'a number that varies': (chart) {
    _dataset0(chart)['borderWidth'] = <Object?>[1.0, 2.0];
    chart.update('none');
  },
  'a hidden dataset': (chart) {
    chart
      ..hide(0)
      ..update('none');
  },
  'the dataset again': (chart) {
    chart
      ..show(0)
      ..update('none');
  },
  'an active arc': (chart) {
    chart
      ..setActiveElements(<Object?>[
        <String, Object?>{'datasetIndex': 0, 'index': 1},
      ])
      ..update('none');
  },
  'no active arc': (chart) {
    chart
      ..setActiveElements(<Object?>[])
      ..update('none');
  },
};

/// A user subclass of the arc: its reads stay observable.
final class _UserArc extends ArcElement {
  _UserArc(this.reads, [this.onRead]);

  final List<Object?> reads;

  /// Runs at each read of the context.
  final void Function()? onRead;

  @override
  ScriptableContext? get $context {
    reads.add('context');
    onRead?.call();
    return super.$context;
  }
}

/// A Map of another class: each read can run user code.
final class _ObservedMap extends MapBase<String, Object?> {
  _ObservedMap(this.fields, [this.onRead]);

  final Map<String, Object?> fields;

  /// Runs at each read, with its key.
  final void Function(Object? key)? onRead;

  int reads = 0;

  @override
  Object? operator [](Object? key) {
    reads++;
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

final class _TrivialConfig extends Config {
  _TrivialConfig(super.config);
}

/// A chart of [config] of the exact class, or of a trivial user subclass, which
/// takes the ordinary path at each point. Both have the same canvas size.
Chart _chartOf(Map<String, Object?> config, {required bool exact}) {
  (config['options']! as Map<String, Object?>)
    ..['animation'] = false
    ..['responsive'] = false;
  final canvas = UiCanvasElement(width: 300, height: 300);
  final chart = exact ? Chart(canvas, config) : _ChildChart(canvas, config);
  addTearDown(chart.destroy);
  return chart;
}

/// `fillStyle` of each item of the box of [chart].
List<Object?> _fillStyles(Chart chart) => [
  for (final item in chart.legend!.legendItems!) jsGet(item, 'fillStyle'),
];

/// `fillStyle` and `lineWidth` of each item of the box of [chart].
List<Object?> _fillAndWidth(Chart chart) => [
  for (final item in chart.legend!.legendItems!)
    [jsGet(item, 'fillStyle'), jsGet(item, 'lineWidth')],
];

/// The state of the context of arc 0 of [chart], as user code reads it.
String _firstArcState(Chart chart) {
  final context = (chart.getDatasetMeta(0).data[0] as ArcElement).$context!;
  return '${context.mode}/${context.active}/raw=${context.raw}';
}

/// Makes arc 0 of [chart] active and gives it a new value, for an update that
/// must write the new state into its context.
void _changeFirstArc(Chart chart) {
  chart.setActiveElements(<Object?>[
    <String, Object?>{'datasetIndex': 0, 'index': 0},
  ]);
  (_dataset0(chart)['data']! as List<Object?>)[0] = 9.0;
}

void main() {
  group('a read gives the items of the eager build', () {
    for (final type in _kinds) {
      testWidgets('$type: after the update and after a second update', (
        tester,
      ) async {
        final chart = acquireChart(_config(type));
        final twin = acquireChart(_eager(type));
        expect(_legendOf(chart).legendItemsPending, isTrue);
        expect(_legendOf(twin).legendItemsPending, isFalse);
        expect(_items(chart.legend!), _items(twin.legend!));
        expect(_legendOf(chart).legendItemsPending, isFalse);
        expect(chart.legend!.legendItems, hasLength(3));

        for (final each in [chart, twin]) {
          (jsGet(each.data, 'labels')! as List<Object?>).add('d');
          final dataset =
              (jsGet(each.data, 'datasets')! as List<Object?>)[0]!
                  as Map<String, Object?>;
          (dataset['data']! as List<Object?>).add(4);
          each.update();
        }
        expect(_legendOf(chart).legendItemsPending, isTrue);
        expect(_items(chart.legend!), _items(twin.legend!));
        expect(chart.legend!.legendItems, hasLength(4));
      });

      testWidgets('$type: in each mode of an update', (tester) async {
        final chart = acquireChart(_config(type));
        final twin = acquireChart(_eager(type));
        for (final mode in ['none', 'resize', 'default', 'active', 'none']) {
          chart.update(mode);
          twin.update(mode);
          expect(_items(chart.legend!), _items(twin.legend!), reason: mode);
        }
      });

      testWidgets('$type: reverse without user code', (tester) async {
        final chart = acquireChart(_config(type, legend: {'reverse': true}));
        final twin = acquireChart(_eager(type, legend: {'reverse': true}));
        expect(_legendOf(chart).legendItemsPending, isTrue);
        expect(jsGet(chart.legend!.legendItems![0], 'text'), 'c');
        expect(_items(chart.legend!), _items(twin.legend!));
      });

      testWidgets('$type: a plain label option and a theme-free chart color', (
        tester,
      ) async {
        final labels = <String, Object?>{
          'pointStyle': 'star',
          'textAlign': 'right',
          'color': _green,
          'useBorderRadius': true,
          'borderRadius': 3,
        };
        final chart = acquireChart(_config(type, labels: labels));
        final twin = acquireChart(_eager(type, labels: labels));
        expect(_legendOf(chart).legendItemsPending, isTrue);
        expect(_items(chart.legend!), _items(twin.legend!));
      });

      testWidgets('$type: the read of a plugin in each hook', (tester) async {
        var armed = false;
        final log = <Object?>[];
        final twinLog = <Object?>[];
        final chart = acquireChart(
          _config(type, plugins: [_reader(log, () => armed)]),
        );
        final twin = acquireChart(
          _eager(type, plugins: [_reader(twinLog, () => armed)]),
        );
        armed = true;
        chart
          ..update()
          ..draw();
        twin
          ..update()
          ..draw();
        expect(log, isNotEmpty);
        expect(log, twinLog);
      });

      testWidgets('$type: a plugin that reads in afterUpdate', (tester) async {
        Object? seen;
        Object? twinSeen;
        Map<String, Object?> reader(void Function(Object?) keep) => {
          'id': 'afterUpdateReader',
          'afterUpdate': (Chart chart, Object? args, Object? options) {
            keep(_items(chart.legend!));
            return null;
          },
        };
        final chart = acquireChart(
          _config(type, plugins: [reader((items) => seen = items)]),
        );
        final twin = acquireChart(
          _eager(type, plugins: [reader((items) => twinSeen = items)]),
        );
        expect(seen, isNotNull);
        expect(seen, twinSeen);
        // The read in the hook ended the wait. The items stay.
        expect(_legendOf(chart).legendItemsPending, isFalse);
        expect(_items(chart.legend!), _items(twin.legend!));
      });

      testWidgets('$type: a toggle of display', (tester) async {
        final chart = acquireChart(_config(type));
        final twin = acquireChart(_eager(type));
        void set(Object? display) {
          for (final each in [chart, twin]) {
            ((jsGet(each.config.options, 'plugins')!
                        as Map<String, Object?>)['legend']!
                    as Map<String, Object?>)['display'] =
                display;
            each.update();
          }
        }

        expect(_legendOf(chart).legendItemsPending, isTrue);
        set(true);
        expect(_legendOf(chart).legendItemsPending, isFalse);
        expect(chart.legend!.legendHitBoxes, hasLength(3));
        expect(_legendOf(chart).height, greaterThan(0));
        expect(_items(chart.legend!), _items(twin.legend!));
        set(false);
        expect(_legendOf(chart).legendItemsPending, isTrue);
        expect(_legendOf(chart).height, 0);
        expect(_items(chart.legend!), _items(twin.legend!));
        set(true);
        expect(_legendOf(chart).width, _legendOf(twin).width);
        expect(_legendOf(chart).height, _legendOf(twin).height);
        expect(_items(chart.legend!), _items(twin.legend!));
      });

      testWidgets('$type: a visibility change with an update', (tester) async {
        final chart = acquireChart(_config(type));
        final twin = acquireChart(_eager(type));
        for (final each in [chart, twin]) {
          each
            ..toggleDataVisibility(1)
            ..update();
        }
        expect(_legendOf(chart).legendItemsPending, isTrue);
        expect(jsGet(chart.legend!.legendItems![1], 'hidden'), isTrue);
        expect(_items(chart.legend!), _items(twin.legend!));
      });
    }

    for (final type in _kinds) {
      testWidgets('$type: a data-only update marks and reads', (tester) async {
        Map<String, Object?> make() => _config(
          type,
          options: {
            'responsive': false,
            'animation': false,
            'plugins': <String, Object?>{
              'legend': <String, Object?>{'display': false},
              'tooltip': false,
              'title': false,
              'subtitle': false,
              'colors': false,
              'decimation': false,
              'filler': false,
            },
            if (type == 'polarArea')
              'scales': <String, Object?>{
                'r': <String, Object?>{
                  'type': 'radialLinear',
                  'min': 0.0,
                  'max': 10.0,
                },
              },
          },
          labelValues: <String>['a', 'b', 'c'],
          dataset: {
            'data': <Object?>[1.0, 2.0, 3.0],
          },
        );
        void change(Chart chart) {
          final dataset =
              (jsGet(chart.data, 'datasets')! as List<Object?>)[0]!
                  as Map<String, Object?>;
          final values = dataset['data']! as List<Object?>;
          for (var i = 0; i < values.length; i++) {
            values[i] = 4.0 + i;
          }
        }

        final chart = acquireChart(make());
        final twin = acquireChart(make());
        final legend = _legendOf(chart);
        change(chart);
        change(twin);
        expect(chart.updateData(), isTrue);
        twin
          ..update('none')
          ..legend!.legendItems;
        expect(legend.legendItemsPending, isTrue);
        final items = _items(legend);
        expect(items, _items(twin.legend!));
        // An eager build in the same state is the twin of the deferred build.
        legend.buildLabels();
        expect(_items(legend), items);
      });
    }
  });

  group('the polar area update in the mode none', () {
    testWidgets('it writes the default entry that the ordinary build writes', (
      tester,
    ) async {
      final chart = acquireChart(_config('polarArea'));
      final controller = chart.getDatasetMeta(0).controller!;
      chart.update('none');
      expect(_legendOf(chart).legendItemsPending, isTrue);
      expect(controller.hasCachedDefaultDataOptions, isTrue);
      expect(controller.hasStaticDataUpdateOptions, isTrue);
      final twin = acquireChart(_eager('polarArea'))..update('none');
      expect(
        twin.getDatasetMeta(0).controller!.hasCachedDefaultDataOptions,
        isTrue,
      );
      expect(_items(chart.legend!), _items(twin.legend!));
    });

    testWidgets('the proof holds for the layout of the next update', (
      tester,
    ) async {
      var pendingAfterLayout = false;
      final chart =
          acquireChart(
              _config(
                'polarArea',
                plugins: [
                  {
                    'id': 'layoutProbe',
                    'afterLayout':
                        (Chart chart, Object? args, Object? options) {
                          pendingAfterLayout = _legendOf(chart)
                              .legendItemsPending;
                          return null;
                        },
                  },
                ],
              ),
            )
            ..update('none')
            ..update('none');
      expect(_legendOf(chart).legendItemsPending, isTrue);
      expect(pendingAfterLayout, isTrue);
    });
  });

  group('each guard keeps the ordinary path', () {
    /// Runs one update on the config [config] and on its twin with a [filter],
    /// and compares the calls of a counter and the items.
    Future<void> expectEager(
      Map<String, Object?> Function({
        Map<String, Object?> labels,
        Map<String, Object?> legend,
        Map<String, Object?> dataset,
        Map<String, Object?> options,
      })
      make, {
      required int Function() calls,
      required void Function() reset,
      required String type,
      Map<String, Object?> labels = const {},
      Map<String, Object?> legend = const {},
      Map<String, Object?> dataset = const {},
      Map<String, Object?> options = const {},
    }) async {
      reset();
      final chart = acquireChart(
        make(
          labels: labels,
          legend: legend,
          dataset: dataset,
          options: options,
        ),
      )..update();
      final seen = calls();
      expect(_legendOf(chart).legendItemsPending, isFalse);
      reset();
      final twin = acquireChart(
        _eager(
          type,
          labels: labels,
          legend: legend,
          dataset: dataset,
          options: options,
        ),
      )..update();
      expect(seen, calls());
      expect(seen, greaterThan(0));
      expect(_items(chart.legend!), _items(twin.legend!));
    }

    for (final type in _kinds) {
      Map<String, Object?> make({
        Map<String, Object?> labels = const {},
        Map<String, Object?> legend = const {},
        Map<String, Object?> dataset = const {},
        Map<String, Object?> options = const {},
      }) => _config(
        type,
        labels: labels,
        legend: legend,
        dataset: dataset,
        options: options,
      );

      testWidgets('$type: a user generateLabels: 3 calls for each update', (
        tester,
      ) async {
        var calls = 0;
        final chart = acquireChart(
          _config(
            type,
            labels: {
              'generateLabels': (Object? chart) {
                calls++;
                return <Object?>[
                  <String, Object?>{'text': 'x'},
                ];
              },
            },
          ),
        );
        expect(calls, 3);
        expect(_legendOf(chart).legendItemsPending, isFalse);
        chart.update();
        expect(calls, 6);
        expect(_items(chart.legend!), [
          [
            ['text', 'x'],
          ],
        ]);
      });

      testWidgets('$type: filter: one call for each item of each build', (
        tester,
      ) async {
        var calls = 0;
        final chart = acquireChart(
          _config(
            type,
            labels: {
              'filter': (Object? item, Object? data) {
                calls++;
                return true;
              },
            },
          ),
        );
        expect(calls, 9);
        expect(_legendOf(chart).legendItemsPending, isFalse);
      });

      testWidgets('$type: sort: the comparator runs in each build', (
        tester,
      ) async {
        var calls = 0;
        final chart = acquireChart(
          _config(
            type,
            labels: {
              'sort': (Object? a, Object? b, Object? data) {
                calls++;
                return 0;
              },
            },
          ),
        );
        expect(calls, greaterThan(0));
        final first = calls;
        calls = 0;
        chart.update();
        expect(calls, first);
        expect(_legendOf(chart).legendItemsPending, isFalse);
      });

      testWidgets('$type: display true', (tester) async {
        final chart = acquireChart(_config(type, legend: {'display': true}));
        expect(_legendOf(chart).legendItemsPending, isFalse);
        expect(chart.legend!.legendHitBoxes, hasLength(3));
      });

      for (final (name, value) in [
        ('null', null),
        ('0', 0),
        ('an empty string', ''),
      ]) {
        testWidgets('$type: a falsy display that is not false: $name', (
          tester,
        ) async {
          final chart = acquireChart(_config(type, legend: {'display': value}));
          expect(_legendOf(chart).legendItemsPending, isFalse);
          expect(_legendOf(chart).height, 0);
        });
      }

      testWidgets('$type: a scriptable display', (tester) async {
        var calls = 0;
        await expectEager(
          make,
          type: type,
          legend: {
            'display': (Object? context, Object? options) {
              calls++;
              return false;
            },
          },
          calls: () => calls,
          reset: () => calls = 0,
        );
      });

      testWidgets('$type: a scriptable reverse', (tester) async {
        var calls = 0;
        await expectEager(
          make,
          type: type,
          legend: {
            'reverse': (Object? context, Object? options) {
              calls++;
              return true;
            },
          },
          calls: () => calls,
          reset: () => calls = 0,
        );
      });

      for (final key in const ['pointStyle', 'color']) {
        testWidgets('$type: a scriptable label option: $key', (tester) async {
          var calls = 0;
          await expectEager(
            make,
            type: type,
            labels: {
              key: (Object? context, Object? options) {
                calls++;
                return key == 'color' ? _red : 'star';
              },
            },
            calls: () => calls,
            reset: () => calls = 0,
          );
        });
      }

      testWidgets('$type: a function in a key of the generator', (
        tester,
      ) async {
        final chart = acquireChart(
          _config(
            type,
            labels: {
              // A polar area generator does not read it, a doughnut one does.
              'textAlign': (Object? context, Object? options) => 'left',
            },
          ),
        );
        expect(_legendOf(chart).legendItemsPending, type == 'polarArea');
      });

      testWidgets('$type: a scriptable color of the chart', (tester) async {
        var calls = 0;
        await expectEager(
          make,
          type: type,
          options: {
            'color': (Object? context, Object? options) {
              calls++;
              return _red;
            },
          },
          calls: () => calls,
          reset: () => calls = 0,
        );
      });

      testWidgets('$type: scriptable colors: the same calls', (tester) async {
        var calls = 0;
        await expectEager(
          make,
          type: type,
          dataset: {
            'backgroundColor': (Object? context, Object? options) {
              calls++;
              return _red;
            },
          },
          calls: () => calls,
          reset: () => calls = 0,
        );
      });

      testWidgets('$type: a List of another class for the labels', (
        tester,
      ) async {
        final labels = _ObservedList(['a', 'b', 'c']);
        final chart = acquireChart(_config(type, labelValues: labels));
        expect(_legendOf(chart).legendItemsPending, isFalse);
        expect(chart.legend!.legendItems, hasLength(3));
      });

      testWidgets('$type: a List of another class for the datasets', (
        tester,
      ) async {
        final datasets = _ObservedList([
          <String, Object?>{
            'data': <Object?>[1, 2, 3],
            'backgroundColor': _red,
          },
        ]);
        final chart = acquireChart(_config(type, datasets: datasets));
        expect(_legendOf(chart).legendItemsPending, isFalse);
      });

      testWidgets('$type: empty labels and no datasets', (tester) async {
        final noLabels = acquireChart(_config(type, labelValues: <Object?>[]));
        expect(_legendOf(noLabels).legendItemsPending, isFalse);
        expect(noLabels.legend!.legendItems, isEmpty);
        final noDatasets = acquireChart(_config(type, datasets: <Object?>[]));
        expect(_legendOf(noDatasets).legendItemsPending, isFalse);
        expect(noDatasets.legend!.legendItems, isEmpty);
      });

      testWidgets('$type: xLabels stand in the list of the category source', (
        tester,
      ) async {
        final config = _config(type);
        (config['data']! as Map<String, Object?>)['xLabels'] = <Object?>[
          'x',
          'y',
          'z',
        ];
        final chart = acquireChart(config);
        expect(_legendOf(chart).legendItemsPending, isFalse);
        expect(jsGet(chart.legend!.legendItems![0], 'text'), 'a');
      });

      testWidgets('$type: a subclass of the chart', (tester) async {
        final canvas = UiCanvasElement(width: 300, height: 300);
        final chart = _ChildChart(canvas, _config(type));
        addTearDown(chart.destroy);
        final reference = acquireChart(_eager(type));
        expect(_legendOf(chart).legendItemsPending, isFalse);
        expect(_items(chart.legend!), _items(reference.legend!));
      });
    }

    for (final (key, value) in <(String, Object?)>[
      ('textAlign', 'left'),
      ('useBorderRadius', true),
      ('borderRadius', 2),
    ]) {
      testWidgets('doughnut: a scriptable label option: $key', (tester) async {
        var calls = 0;
        Object? script(Object? context, Object? options) {
          calls++;
          return value;
        }

        final chart = acquireChart(_config('doughnut', labels: {key: script}))
          ..update();
        final seen = calls;
        expect(_legendOf(chart).legendItemsPending, isFalse);
        calls = 0;
        final twin = acquireChart(_eager('doughnut', labels: {key: script}))
          ..update();
        expect(seen, calls);
        // One call for each update, at the first read of the first build.
        expect(seen, 2);
        expect(_items(chart.legend!), _items(twin.legend!));
      });
    }

    for (final (id, parent, child) in [
      ('pieChild', 'pie', _pieChild),
      ('doughnutChild', 'doughnut', _doughnutChild),
      ('polarChild', 'polarArea', _polarChild),
    ]) {
      testWidgets('a subclass of the controller: $id', (tester) async {
        registry.addControllers([child]);
        addTearDown(() => registry.removeControllers([child]));
        // The same input through the exact class and through the subclass.
        final chart = acquireChart(_config(id));
        final exact = acquireChart(_config(parent));
        final controller = chart.getDatasetMeta(0).controller!;
        expect(controller.nativeLegendGenerator, isNull);
        expect(
          exact.getDatasetMeta(0).controller!.nativeLegendGenerator,
          isNotNull,
        );
        for (final mode in ['none', 'default']) {
          chart.update(mode);
          exact.update(mode);
          expect(_legendOf(chart).legendItemsPending, isFalse);
          expect(_legendOf(exact).legendItemsPending, isTrue);
          expect(_items(chart.legend!), _items(exact.legend!));
        }
      });
    }

    testWidgets('a first dataset of another controller', (tester) async {
      final chart = acquireChart(
        _config(
          'polarArea',
          dataset: {'type': 'doughnut'},
          options: {
            'scales': <String, Object?>{
              'r': <String, Object?>{'type': 'radialLinear'},
            },
          },
        ),
      );
      final controller = chart.getDatasetMeta(0).controller!;
      expect(controller.nativeLegendGenerator, isNotNull);
      expect(_legendOf(chart).legendItemsPending, isFalse);
      expect(chart.legend!.legendItems, hasLength(3));
    });

    testWidgets('a line chart has its generator of the file', (tester) async {
      final chart = acquireChart(_config('line'));
      expect(_legendOf(chart).legendItemsPending, isFalse);
      expect(chart.legend!.legendItems, hasLength(1));
    });

    testWidgets('a subclass of the box builds at each update', (tester) async {
      final chart = acquireChart(_config('pie'));
      final box = _CountingLegend((
        chart: chart,
        options: _legendOf(chart).options,
        ctx: chart.ctx,
      ));
      chart.legend = box;
      box.update(100, 100, _Margins());
      expect(box.builds, 1);
      expect(box.legendItemsPending, isFalse);
    });

    testWidgets('a box that is not chart.legend builds at each update', (
      tester,
    ) async {
      final chart = acquireChart(_config('pie'));
      final box = Legend((
        chart: chart,
        options: _legendOf(chart).options,
        ctx: chart.ctx,
      ))..update(100, 100, _Margins());
      expect(box.legendItemsPending, isFalse);
      expect(box.legendItems, hasLength(3));
    });

    testWidgets('a direct buildLabels stays eager', (tester) async {
      final chart = acquireChart(_config('pie'));
      final legend = _legendOf(chart);
      expect(legend.legendItemsPending, isTrue);
      legend.buildLabels();
      expect(legend.legendItemsPending, isFalse);
      final items = legend.legendItems;
      expect(items, hasLength(3));
      expect(legend.legendItems, same(items));
    });

    testWidgets('a write ends the wait', (tester) async {
      final chart = acquireChart(_config('pie'));
      final legend = _legendOf(chart);
      expect(legend.legendItemsPending, isTrue);
      final mine = <Object?>[];
      legend.legendItems = mine;
      expect(legend.legendItemsPending, isFalse);
      expect(legend.legendItems, same(mine));
      // As an upstream build, the next update takes the place of the write.
      chart.update();
      expect(legend.legendItems, hasLength(3));
    });
  });

  group('a read with a new first dataset', () {
    Map<String, Object?> dataset() => <String, Object?>{
      'label': 'new',
      'data': <Object?>[7, 8, 9],
      'backgroundColor': _green,
    };

    final replacements = <String, void Function(Chart)>{
      'a write at index 0': (chart) => _datasetsOf(chart)[0] = dataset(),
      'a new List': (chart) =>
          (chart.data as Map<String, Object?>)['datasets'] = <Object?>[
            dataset(),
          ],
      'the data setter': (chart) => chart.data = <String, Object?>{
        'labels': <Object?>['p', 'q', 'r'],
        'datasets': <Object?>[dataset()],
      },
      'an insert at index 0': (chart) =>
          _datasetsOf(chart).insert(0, dataset()),
    };

    for (final type in _kinds) {
      for (final MapEntry(key: name, value: replace) in replacements.entries) {
        testWidgets('$type: $name', (tester) async {
          final chart = acquireChart(_config(type));
          final twin = acquireChart(_eager(type));
          expect(_legendOf(chart).legendItemsPending, isTrue);
          final metas = chart.metasets.length;
          replace(chart);
          replace(twin);
          // The last built items: here they are the snapshot of upstream.
          expect(_items(chart.legend!), _items(twin.legend!));
          // The read adds no meta, as the snapshot of upstream does not.
          expect(chart.metasets, hasLength(metas));
          // The build still waits for a read that can run it.
          expect(_legendOf(chart).legendItemsPending, isTrue);
          chart.update();
          twin.update();
          expect(chart.getDatasetMeta(0).controller, isNotNull);
          expect(_items(chart.legend!), _items(twin.legend!));
        });
      }

      testWidgets('$type: a read in beforeUpdate keeps the update', (
        tester,
      ) async {
        var armed = false;
        final seen = <Object?>[];
        final twinSeen = <Object?>[];
        Map<String, Object?> reader(List<Object?> log) =>
            _hook('beforeUpdate', (
              chart,
            ) {
              if (armed) log.add(chart.legend!.legendItems!.length);
              return null;
            });
        final chart = acquireChart(_config(type, plugins: [reader(seen)]));
        final twin = acquireChart(_eager(type, plugins: [reader(twinSeen)]));
        armed = true;
        for (final each in [chart, twin]) {
          _labelsOf(each).add('d');
          _datasetsOf(each)[0] = <String, Object?>{
            'data': <Object?>[1, 2, 3, 4],
          };
          each.update();
          expect(each.getDatasetMeta(0).controller, isNotNull);
          expect(each.getDatasetMeta(0).data, hasLength(4));
          expect(each.legend!.legendItems, hasLength(4));
        }
        expect(seen, [3]);
        expect(seen, twinSeen);
      });
    }
  });

  group('a read after an option change', () {
    /// Runs [change] on a chart and on its twin, with a reader in [hook], and
    /// then the update. [read] gives the value of a read.
    Future<void> compare({
      required String type,
      required String hook,
      required void Function(Chart chart, void Function() count) change,
      Object? Function(Chart chart)? read,
    }) async {
      final seen = <Object?>[];
      final twinSeen = <Object?>[];
      var armed = false;
      Map<String, Object?> reader(List<Object?> log) => _hook(hook, (chart) {
        if (armed) log.add((read ?? _texts)(chart));
        return null;
      });
      var calls = 0;
      var twinCalls = 0;
      final chart = acquireChart(_config(type, plugins: [reader(seen)]));
      final twin = acquireChart(_eager(type, plugins: [reader(twinSeen)]));
      armed = true;
      // An update that the snapshot of upstream has and no build of a read.
      _labelsOf(chart)[0] = 'x';
      _labelsOf(twin)[0] = 'x';
      chart.update();
      twin.update();
      seen.clear();
      twinSeen.clear();
      change(chart, () => calls++);
      change(twin, () => twinCalls++);
      chart.update();
      twin.update();
      expect(seen, twinSeen);
      expect(calls, twinCalls);
      expect(_items(chart.legend!), _items(twin.legend!));
    }

    for (final type in _kinds) {
      for (final hook in const [
        'beforeUpdate',
        'beforeElementsUpdate',
        'beforeLayout',
      ]) {
        testWidgets('$type: $hook: a new filter', (tester) async {
          await compare(
            type: type,
            hook: hook,
            change: (chart, count) =>
                _labelOptionsOf(chart)['filter'] = (item, data) {
                  count();
                  return false;
                },
          );
        });

        testWidgets('$type: $hook: a new generateLabels', (tester) async {
          await compare(
            type: type,
            hook: hook,
            change: (chart, count) =>
                _labelOptionsOf(chart)['generateLabels'] = (chart) {
                  count();
                  return <Object?>[
                    <String, Object?>{'text': 'u'},
                  ];
                },
          );
        });

        testWidgets('$type: $hook: a new plain label option', (tester) async {
          await compare(
            type: type,
            hook: hook,
            change: (chart, count) =>
                _labelOptionsOf(chart)['pointStyle'] = 'star',
            read: (chart) => jsGet(chart.legend!.legendItems![0], 'pointStyle'),
          );
        });

        testWidgets('$type: $hook: a sort that throws at the update', (
          tester,
        ) async {
          Object? atRead;
          var armed = false;
          Map<String, Object?> reader() => _hook(hook, (chart) {
            if (!armed) return null;
            try {
              chart.legend!.legendItems;
            } on Object catch (error) {
              atRead = error;
              rethrow;
            }
            return null;
          });
          final chart = acquireChart(_config(type, plugins: [reader()]));
          final twin = acquireChart(_eager(type, plugins: [reader()]));
          armed = true;
          for (final each in [chart, twin]) {
            _labelsOf(each)[0] = 'x';
            each.update();
            _labelOptionsOf(each)['sort'] = (a, b, data) =>
                throw StateError('sort');
            expect(each.update, throwsStateError);
          }
          expect(atRead, isNull);
          // The snapshot of the last update.
          expect(_texts(chart), ['x', 'b', 'c']);
          expect(_items(chart.legend!), _items(twin.legend!));
        });
      }

      testWidgets('$type: beforeUpdate: a new color of the chart', (
        tester,
      ) async {
        await compare(
          type: type,
          hook: 'beforeUpdate',
          change: (chart, count) =>
              (chart.config.options as Map<String, Object?>)['color'] = _green,
          read: (chart) => jsGet(chart.legend!.legendItems![0], 'fontColor'),
        );
      });

      testWidgets('$type: a read in a hook keeps the options of the update', (
        tester,
      ) async {
        var armed = false;
        Object? before;
        Object? after;
        final chart = acquireChart(
          _config(
            type,
            plugins: [
              _hook('beforeUpdate', (chart) {
                if (armed) {
                  before = chart.legend!.options;
                  chart.legend!.legendItems;
                  after = chart.legend!.options;
                }
                return null;
              }),
            ],
          ),
        );
        armed = true;
        chart.update();
        expect(before, isNotNull);
        expect(after, same(before));
        expect(chart.legend!.options, same(before));
      });

      testWidgets('$type: a read inside a new generateLabels', (tester) async {
        final seen = <Object?>[];
        final chart = acquireChart(_config(type));
        final twin = acquireChart(_eager(type));
        for (final each in [chart, twin]) {
          _labelsOf(each)[0] = 'x';
          each.update();
          _labelOptionsOf(each)['generateLabels'] = (legendChart) {
            seen.add(_texts(each));
            return <Object?>[
              <String, Object?>{'text': 'u'},
            ];
          };
          each.update();
          expect(_texts(each), ['u']);
        }
        // Three builds on each chart: the snapshot of the last update, and
        // then the items of the build before.
        expect(seen, hasLength(6));
        expect(seen.sublist(0, 3), seen.sublist(3));
        expect(seen.first, ['x', 'b', 'c']);
      });

      testWidgets('$type: a style read before the first build', (tester) async {
        final chart = acquireChart(
          _config(
            type,
            plugins: [
              _hook('beforeLayout', (chart) {
                chart.getDatasetMeta(0).controller!.getStyle(0);
                return null;
              }),
            ],
          ),
        );
        // The box has items for a read that cannot run the build.
        expect(chart.legend!.legendItems, hasLength(3));
      });

      testWidgets('$type: a cancelled update with a new filter', (
        tester,
      ) async {
        var armed = false;
        Map<String, Object?> cancel() => _hook(
          'beforeUpdate',
          (chart) => armed ? false : null,
        );
        var calls = 0;
        final chart = acquireChart(_config(type, plugins: [cancel()]));
        final twin = acquireChart(_eager(type, plugins: [cancel()]));
        for (final each in [chart, twin]) {
          _labelsOf(each)[0] = 'x';
          each.update();
        }
        armed = true;
        for (final each in [chart, twin]) {
          _labelOptionsOf(each)['filter'] = (item, data) {
            calls++;
            return false;
          };
          each.update();
        }
        expect(_texts(chart), ['x', 'b', 'c']);
        expect(_items(chart.legend!), _items(twin.legend!));
        expect(calls, 0);
      });

      testWidgets('$type: a read leaves an in-place write of a later hook', (
        tester,
      ) async {
        var armed = false;
        Map<String, Object?> reader() => _hook('beforeUpdate', (chart) {
          if (armed) chart.legend!.legendItems;
          return null;
        });
        Map<String, Object?> writer() => _hook('beforeLayout', (chart) {
          if (armed) {
            _labelOptionsOf(chart)['pointStyle'] = 'star';
            (chart.config.options as Map<String, Object?>)['color'] = _green;
          }
          return null;
        });
        final chart = acquireChart(
          _config(type, plugins: [reader(), writer()]),
        );
        final twin = acquireChart(_eager(type, plugins: [reader(), writer()]));
        armed = true;
        for (final each in [chart, twin]) {
          each.update();
          expect(jsGet(each.legend!.legendItems![0], 'pointStyle'), 'star');
          expect(jsGet(each.legend!.legendItems![0], 'fontColor'), _green);
          expect(readOption(each.options, OptionKey.color), _green);
        }
        expect(_items(chart.legend!), _items(twin.legend!));
      });
    }
  });

  group('the guard reads only what the ordinary build reads', () {
    const written = <String, Object?>{
      'pointStyle': 'star',
      'textAlign': 'right',
      'color': _green,
      'useBorderRadius': true,
      'borderRadius': 7,
    };

    /// Writes [key] of the label options in `afterLayout`, and reads it in
    /// `afterUpdate` through the options of the box.
    Map<String, Object?> writeThenRead(
      String key,
      void Function(Object?) keep,
    ) => <String, Object?>{
      'id': 'writeThenRead',
      'afterLayout': (Chart chart, Object? args, Object? options) {
        _labelOptionsOf(chart)[key] = written[key];
        return null;
      },
      'afterUpdate': (Chart chart, Object? args, Object? options) {
        keep(
          readOption(
            readOption(chart.legend!.options, OptionKey.labels),
            optionKeyOf(key)!,
          ),
        );
        return null;
      },
    };

    for (final type in const ['pie', 'polarArea', 'bar', 'line']) {
      for (final display in const [true, false]) {
        for (final key in written.keys) {
          testWidgets('$type: display $display: a user generator: $key', (
            tester,
          ) async {
            Object? seen;
            acquireChart(
              _config(
                type,
                legend: {'display': display},
                labels: {
                  'generateLabels': (Object? chart) => <Object?>[
                    <String, Object?>{'text': 'x'},
                  ],
                },
                plugins: [writeThenRead(key, (value) => seen = value)],
              ),
            );
            expect(seen, written[key]);
          });
        }
      }
    }

    for (final display in const [true, false]) {
      for (final key in const [
        'textAlign',
        'useBorderRadius',
        'borderRadius',
      ]) {
        testWidgets('polarArea: display $display: a key of no read: $key', (
          tester,
        ) async {
          Object? seen;
          acquireChart(
            _config(
              'polarArea',
              legend: {'display': display},
              plugins: [writeThenRead(key, (value) => seen = value)],
            ),
          );
          expect(seen, written[key]);
        });
      }
    }

    testWidgets('a user generator leaves the chart color unread', (
      tester,
    ) async {
      Object? seen;
      acquireChart(
        _config(
          'pie',
          labels: {
            'generateLabels': (Object? chart) => <Object?>[
              <String, Object?>{'text': 'x'},
            ],
          },
          plugins: [
            <String, Object?>{
              'id': 'writeThenRead',
              'afterLayout': (Chart chart, Object? args, Object? options) {
                (chart.config.options as Map<String, Object?>)['color'] =
                    _green;
                return null;
              },
              'afterUpdate': (Chart chart, Object? args, Object? options) {
                seen = readOption(chart.options, OptionKey.color);
                return null;
              },
            },
          ],
        ),
      );
      expect(seen, _green);
    });

    testWidgets('a visible doughnut with a generator that delegates', (
      tester,
    ) async {
      final overrides = DoughnutController.overrides;
      final builtIn = readOption(
        readOption(
          readOption(overrides.jsRead('plugins'), OptionKey.legend),
          OptionKey.labels,
        ),
        OptionKey.generateLabels,
      );
      final chart = acquireChart(
        _config(
          'doughnut',
          legend: {'display': true},
          labels: {
            'generateLabels': (Object? chart) {
              _labelOptionsOf(chart! as Chart)['color'] = _green;
              return jsCall(builtIn, [chart]);
            },
          },
        ),
      );
      expect(jsGet(chart.legend!.legendItems![0], 'fontColor'), _green);
    });
  });

  group('no read and no guard calls an option', () {
    for (final (type, mode) in const [
      ('pie', 'default'),
      ('doughnut', 'default'),
      ('polarArea', 'default'),
      ('polarArea', 'none'),
    ]) {
      testWidgets('$type $mode: a scriptable color at a read', (tester) async {
        var armed = false;
        Map<String, Object?> reader() => _hook('afterDatasetsUpdate', (chart) {
          if (armed) chart.legend!.legendItems;
          return null;
        });
        var calls = 0;
        final chart = acquireChart(_config(type, plugins: [reader()]));
        final twin = acquireChart(_eager(type, plugins: [reader()]));
        armed = true;
        chart.update(mode);
        twin.update(mode);
        Object? script(Object? context, Object? options) {
          calls++;
          return _black;
        }

        (_datasetsOf(chart)[0]! as Map<String, Object?>)['backgroundColor'] =
            script;
        chart.update(mode);
        final seen = calls;
        calls = 0;
        (_datasetsOf(twin)[0]! as Map<String, Object?>)['backgroundColor'] =
            script;
        twin.update(mode);
        expect(seen, calls);
        expect(seen, greaterThan(0));
        expect(_items(chart.legend!), _items(twin.legend!));
      });
    }

    testWidgets('polarArea none: a cache clear and a scriptable color', (
      tester,
    ) async {
      var armed = false;
      var calls = 0;
      Object? script(Object? context, Object? options) {
        calls++;
        return _black;
      }

      Map<String, Object?> clear() => _hook('afterDatasetsUpdate', (chart) {
        if (armed) {
          chart.config.clearCache();
          (_datasetsOf(chart)[0]! as Map<String, Object?>)['backgroundColor'] =
              script;
          armed = false;
        }
        return null;
      });
      final chart = acquireChart(_config('polarArea', plugins: [clear()]));
      final twin = acquireChart(_eager('polarArea', plugins: [clear()]));
      chart.update('none');
      twin.update('none');
      armed = true;
      chart.update('none');
      final seen = calls;
      calls = 0;
      armed = true;
      twin.update('none');
      expect(seen, calls);
      expect(seen, 3);
      expect(_items(chart.legend!), _items(twin.legend!));
    });
  });

  group('a user descriptor function keeps its calls', () {
    for (final (id, parent, child) in [
      ('pieChild', 'pie', _pieChild),
      ('doughnutChild', 'doughnut', _doughnutChild),
      ('polarChild', 'polarArea', _polarChild),
    ]) {
      for (final where in const ['labels', 'dataset']) {
        for (final mode in const ['default', 'none']) {
          testWidgets('$parent: $where: $mode', (tester) async {
            // A subclass of the controller keeps the ordinary path.
            registry.addControllers([child]);
            addTearDown(() => registry.removeControllers([child]));
            var calls = 0;
            bool descriptor(Object? key) {
              calls++;
              return false;
            }

            Map<String, Object?> make(String type) => _config(
              type,
              labels: where == 'labels'
                  ? {'_scriptable': descriptor}
                  : const {},
              dataset: where == 'dataset'
                  ? {'_scriptable': descriptor}
                  : const {},
            );
            final chart = acquireChart(make(parent))
              ..update(mode)
              ..update(mode);
            final seen = calls;
            calls = 0;
            final twin = acquireChart(make(id))
              ..update(mode)
              ..update(mode);
            expect(seen, calls);
            expect(seen, greaterThan(0));
            expect(_items(chart.legend!), _items(twin.legend!));
          });
        }
      }
    }
  });

  group('a box that is not chart.legend any more', () {
    testWidgets('a read gives the last built items and throws nothing', (
      tester,
    ) async {
      final chart = acquireChart(_config('pie'));
      final legend = _legendOf(chart);
      final built = legend.legendItems;
      chart.update();
      expect(legend.legendItemsPending, isTrue);
      final other = _CountingLegend((
        chart: chart,
        options: legend.options,
        ctx: chart.ctx,
      ));
      chart.legend = other;
      expect(legend.legendItems, same(built));
      // The build still waits for a read that can run it.
      expect(legend.legendItemsPending, isTrue);
      expect(other.builds, 0);
      chart.legend = legend;
      expect(legend.legendItems, isNot(same(built)));
      expect(legend.legendItemsPending, isFalse);
    });
  });

  group('the list of a read', () {
    testWidgets('the same List until the next mark, then a new List', (
      tester,
    ) async {
      final chart = acquireChart(_config('doughnut'));
      final legend = _legendOf(chart);
      final first = legend.legendItems;
      expect(legend.legendItems, same(first));
      chart.update();
      final second = legend.legendItems;
      expect(second, isNot(same(first)));
      expect(legend.legendItems, same(second));
    });
  });

  group('differences.md adapt-hidden-legend-items', () {
    for (final type in _kinds) {
      testWidgets('$type: an in-place change with no update', (tester) async {
        final chart = acquireChart(_config(type));
        final twin = acquireChart(_eager(type));
        for (final each in [chart, twin]) {
          (jsGet(each.data, 'labels')! as List<Object?>)[0] = 'changed';
          each.toggleDataVisibility(2);
        }
        // Upstream, and the twin: the snapshot of the last update.
        expect(jsGet(twin.legend!.legendItems![0], 'text'), 'a');
        expect(jsGet(twin.legend!.legendItems![2], 'hidden'), isFalse);
        // A pending build: the values at the first read.
        expect(jsGet(chart.legend!.legendItems![0], 'text'), 'changed');
        expect(jsGet(chart.legend!.legendItems![2], 'hidden'), isTrue);
        // The read is a snapshot until the next mark.
        (jsGet(chart.data, 'labels')! as List<Object?>)[0] = 'again';
        expect(jsGet(chart.legend!.legendItems![0], 'text'), 'changed');
        // The next update gives the values of upstream again.
        chart.update();
        twin.update();
        (jsGet(twin.data, 'labels')! as List<Object?>)[0] = 'again';
        twin.update();
        expect(_items(chart.legend!), _items(twin.legend!));
      });

      testWidgets('$type: an in-place style change keeps the cached entry', (
        tester,
      ) async {
        final chart = acquireChart(_config(type));
        final twin = acquireChart(_eager(type));
        for (final each in [chart, twin]) {
          ((jsGet(each.data, 'datasets')! as List<Object?>)[0]!
                  as Map<String, Object?>)['backgroundColor'] =
              _black;
        }
        // The cached entry of the last update answers both builds.
        expect(jsGet(chart.legend!.legendItems![0], 'fillStyle'), _red);
        expect(_items(chart.legend!), _items(twin.legend!));
      });
    }

    testWidgets('a read in a hook after a dataset color change', (
      tester,
    ) async {
      var armed = false;
      final seen = <Object?>[];
      final twinSeen = <Object?>[];
      Map<String, Object?> reader(List<Object?> log) => {
        'id': 'colorReader',
        'afterDatasetsUpdate': (Chart chart, Object? args, Object? options) {
          if (armed) log.add(jsGet(chart.legend!.legendItems![0], 'fillStyle'));
          return null;
        },
      };
      final chart = acquireChart(_config('pie', plugins: [reader(seen)]));
      final twin = acquireChart(_eager('pie', plugins: [reader(twinSeen)]));
      armed = true;
      for (final each in [chart, twin]) {
        ((jsGet(each.data, 'datasets')! as List<Object?>)[0]!
                as Map<String, Object?>)['backgroundColor'] =
            _black;
        each.update();
      }
      // Upstream: the layout build, with the entry of the last update.
      expect(twinSeen, [_red]);
      // A pending build: the entry of this update, at the read.
      expect(seen, [_black]);
      // Both give the value of upstream after the update.
      expect(_items(chart.legend!), _items(twin.legend!));
    });

    for (final type in _kinds) {
      testWidgets('$type: a read after a failed guard: older than upstream', (
        tester,
      ) async {
        final chart = acquireChart(_config(type));
        final twin = acquireChart(_eager(type));
        // The last build: a, b and c.
        expect(_texts(chart), ['a', 'b', 'c']);
        for (final each in [chart, twin]) {
          _labelsOf(each)[0] = 'x';
          each.update();
          (each.data as Map<String, Object?>)['labels'] = null;
        }
        // Upstream, and the twin: the snapshot of the last update, each time.
        expect(_texts(twin), ['x', 'b', 'c']);
        expect(_texts(twin), ['x', 'b', 'c']);
        // No throw and no user code: the last built items, each time.
        expect(_texts(chart), ['a', 'b', 'c']);
        expect(_texts(chart), ['a', 'b', 'c']);
        expect(_legendOf(chart).legendItemsPending, isTrue);
        // A string for the labels is no native List either.
        (chart.data as Map<String, Object?>)['labels'] = 'mn';
        expect(_texts(chart), ['a', 'b', 'c']);
        // The build still waits: a read in a good state runs it.
        (chart.data as Map<String, Object?>)['labels'] = <Object?>[
          'y',
          'b',
          'c',
        ];
        expect(_texts(chart), ['y', 'b', 'c']);
        expect(_legendOf(chart).legendItemsPending, isFalse);
      });

      testWidgets('$type: a kept box and a failed guard at stop', (
        tester,
      ) async {
        final chart = acquireChart(_config(type));
        final twin = acquireChart(_eager(type));
        final legend = _legendOf(chart);
        final twinLegend = _legendOf(twin);
        expect(legend.legendItems, hasLength(3));
        for (final each in [chart, twin]) {
          _labelsOf(each)[0] = 'x';
          each.update();
          (each.data as Map<String, Object?>)['labels'] = <Object?>[];
        }
        releaseChart(chart);
        releaseChart(twin);
        // Upstream, and the twin: the snapshot of the last update.
        expect(jsGet(twinLegend.legendItems![0], 'text'), 'x');
        // The last built items.
        expect(jsGet(legend.legendItems![0], 'text'), 'a');
        expect(legend.legendItemsPending, isFalse);
      });

      testWidgets(
        '$type: a read between the configure and the dataset update',
        (
          tester,
        ) async {
          var armed = false;
          final seen = <Object?>[];
          final twinSeen = <Object?>[];
          Map<String, Object?> reader(List<Object?> log) => _hook(
            'beforeDatasetUpdate',
            (chart) {
              if (armed) log.add(_texts(chart));
              return null;
            },
          );
          final chart = acquireChart(_config(type, plugins: [reader(seen)]));
          final twin = acquireChart(_eager(type, plugins: [reader(twinSeen)]));
          expect(_texts(chart), ['a', 'b', 'c']);
          armed = true;
          for (final each in [chart, twin]) {
            _labelsOf(each)[0] = 'x';
            each.update();
          }
          // Upstream, and the twin: the layout build of this update.
          expect(twinSeen, [
            ['x', 'b', 'c'],
          ]);
          // The element options of the last update are gone: the last built
          // items. No option runs at this read.
          expect(seen, [
            ['a', 'b', 'c'],
          ]);
          expect(_items(chart.legend!), _items(twin.legend!));
        },
      );

      testWidgets('$type: a read after the first dataset goes', (tester) async {
        Map<String, Object?> two() => _config(
          type,
          datasets: <Object?>[
            <String, Object?>{
              'data': <Object?>[1, 2, 3],
              'backgroundColor': _blue,
            },
            <String, Object?>{
              'data': <Object?>[1, 2, 3],
              'backgroundColor': _green,
            },
          ],
        );
        for (final mode in const ['default', 'none']) {
          final chart = acquireChart(two())..update(mode);
          final expected = jsGet(chart.legend!.legendItems![0], 'fillStyle');
          expect(expected, _blue);
          chart.update(mode);
          expect(_legendOf(chart).legendItemsPending, isTrue);
          _datasetsOf(chart).removeAt(0);
          // The controller of the remaining dataset has another index: the
          // last built items, as the snapshot of upstream here. Never a default
          // color, and never a color of the dataset behind another index.
          expect(jsGet(chart.legend!.legendItems![0], 'fillStyle'), _blue);
          expect(_legendOf(chart).legendItemsPending, isTrue);
          chart.update(mode);
          expect(jsGet(chart.legend!.legendItems![0], 'fillStyle'), _green);
          releaseChart(chart);
        }
      });
    }

    testWidgets('polarArea none: a function added to the element defaults', (
      tester,
    ) async {
      // A hook adds a key after the dataset update. The proof of the mode none
      // does not see a new key, so its getStyle(0) calls the function once more
      // than the ordinary build, which the failed proof then runs.
      registry.addControllers([_polarChild]);
      addTearDown(() => registry.removeControllers([_polarChild]));
      var armed = false;
      var calls = 0;
      Object? function(Object? context, Object? options) {
        calls++;
        return 1;
      }

      final arc = jsGet(jsGet(defaults, 'elements'), 'arc');
      Map<String, Object?> add() => _hook('afterDatasetsUpdate', (chart) {
        if (armed) jsSet(arc, 'pinned', function);
        return null;
      });
      int callsOf(String type) {
        final chart = acquireChart(_config(type, plugins: [add()]))
          ..update('none');
        calls = 0;
        armed = true;
        chart.update('none');
        armed = false;
        jsDeleteKey(arc, 'pinned');
        final seen = calls;
        releaseChart(chart);
        return seen;
      }

      final ordinary = callsOf('polarChild');
      expect(ordinary, 3);
      expect(callsOf('polarArea'), ordinary + 1);
    });
  });

  group('stop', () {
    for (final type in _kinds) {
      testWidgets('$type: a kept box after destroy gives its items', (
        tester,
      ) async {
        final chart = acquireChart(_config(type));
        final twin = acquireChart(_eager(type));
        final legend = _legendOf(chart);
        final twinItems = _items(twin.legend!);
        expect(legend.legendItemsPending, isTrue);
        releaseChart(chart);
        expect(chart.legend, isNull);
        expect(legend.legendItemsPending, isFalse);
        expect(_items(legend), twinItems);
      });

      testWidgets('$type: the plugin goes in an update', (tester) async {
        final chart = acquireChart(_config(type));
        final legend = _legendOf(chart);
        expect(legend.legendItemsPending, isTrue);
        (jsGet(chart.config.options, 'plugins')!
                as Map<String, Object?>)['legend'] =
            false;
        chart.update();
        expect(chart.legend, isNull);
        expect(legend.legendItems, hasLength(3));
      });
    }

    testWidgets('a broken data state at stop keeps the last built items', (
      tester,
    ) async {
      final chart = acquireChart(_config('pie'));
      final legend = _legendOf(chart);
      final built = legend.legendItems;
      chart.update();
      expect(legend.legendItemsPending, isTrue);
      (chart.data as Map<String, Object?>)['labels'] = <String, Object?>{
        'length': 1,
      };
      releaseChart(chart);
      expect(legend.legendItemsPending, isFalse);
      expect(legend.legendItems, same(built));
    });
  });

  group('ChartView', () {
    typed.ChartConfig config(
      List<double> data, {
      typed.ChartKind kind = typed.ChartKind.pie,
      typed.ChartValue<Color> color = const typed.ChartValue.constant(
        Color(0xff4f6bed),
      ),
    }) => typed.ChartConfig(
      type: kind,
      labels: const ['a', 'b', 'c'],
      datasets: [
        switch (kind) {
          typed.ChartKind.polarArea => typed.PolarAreaDataset(
            data: data,
            backgroundColor: color,
            borderWidth: 0,
          ),
          typed.ChartKind.doughnut => typed.DoughnutDataset(
            data: data,
            backgroundColor: color,
            borderWidth: 0,
          ),
          _ => typed.PieDataset(
            data: data,
            backgroundColor: color,
            borderWidth: 0,
          ),
        },
      ],
      animation: typed.ChartAnimation.none,
      legend: const typed.ChartLegend(display: false),
    );

    Widget view(typed.ChartConfig config, [typed.ChartThemeData? theme]) {
      final Widget chart = Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            height: 300,
            child: typed.ChartView(config: config, updateMode: 'none'),
          ),
        ),
      );
      return theme == null
          ? chart
          : typed.ChartTheme(data: theme, child: chart);
    }

    Chart chartOf(WidgetTester tester) => Chart.getChart(
      tester.renderObject<RenderChartHost>(find.byType(ChartHost)).canvas,
    )!;

    // The config of a live slice chart of apps/chart_benchmark_lab: a stable
    // label List, a new data List in each frame and an empty theme.
    for (final kind in const [
      typed.ChartKind.pie,
      typed.ChartKind.doughnut,
      typed.ChartKind.polarArea,
    ]) {
      testWidgets('$kind: the config of a live chart of the lab', (
        tester,
      ) async {
        final labels = <String>[for (var i = 0; i < 200; i++) '$i'];
        const color = typed.ChartValue<Color>.constant(Color(0xff4f6bed));
        const radius = typed.ChartLength.percent(90);
        Widget frame(int step) {
          final data = <double>[for (var i = 0; i < 200; i++) 1.0 + step + i];
          return Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 400,
                height: 300,
                child: typed.ChartView(
                  config: typed.ChartConfig(
                    type: kind,
                    labels: labels,
                    datasets: [
                      switch (kind) {
                        typed.ChartKind.polarArea => typed.PolarAreaDataset(
                          key: const ValueKey('series'),
                          label: 'Values',
                          data: data,
                          backgroundColor: color,
                          borderWidth: 0,
                        ),
                        typed.ChartKind.doughnut => typed.DoughnutDataset(
                          key: const ValueKey('series'),
                          label: 'Values',
                          data: data,
                          backgroundColor: color,
                          borderWidth: 0,
                          radius: radius,
                          cutout: const typed.ChartLength.percent(50),
                        ),
                        _ => typed.PieDataset(
                          key: const ValueKey('series'),
                          label: 'Values',
                          data: data,
                          backgroundColor: color,
                          borderWidth: 0,
                          radius: radius,
                        ),
                      },
                    ],
                    scales: kind == typed.ChartKind.polarArea
                        ? const {
                            'r': typed.RadialLinearAxis(
                              min: 0,
                              max: 100,
                              display: false,
                              pointLabelsDisplay: false,
                              angleLinesDisplay: false,
                            ),
                          }
                        : null,
                    animation: typed.ChartAnimation.none,
                    legend: const typed.ChartLegend(display: false),
                    tooltip: const typed.ChartTooltip(enabled: false),
                    responsive: true,
                    maintainAspectRatio: false,
                    extra: const {'events': <String>[]},
                  ),
                  updateMode: 'none',
                  theme: const typed.ChartThemeData(),
                  excludeFromSemantics: true,
                ),
              ),
            ),
          );
        }

        var pendingFrames = 0;
        await tester.pumpWidget(frame(0));
        final chart = chartOf(tester);
        final legend = _legendOf(chart);
        for (var step = 1; step < 4; step++) {
          await tester.pumpWidget(frame(step));
          if (legend.legendItemsPending) pendingFrames++;
        }
        expect(pendingFrames, 3);
        final items = _items(legend);
        expect(items, hasLength(200));
        legend.buildLabels();
        expect(_items(legend), items);
      });
    }

    for (final type in _kinds) {
      testWidgets(
        '$type: ChartView.raw: a new config and a beforeUpdate read',
        (
          tester,
        ) async {
          var reads = 0;
          final plugin = _hook('beforeUpdate', (chart) {
            chart.legend!.legendItems;
            reads++;
            return null;
          });
          Map<String, Object?> rawConfig(int count) => _config(
            type,
            labelValues: <Object?>[for (var i = 0; i < count; i++) 'l$i'],
            datasets: <Object?>[
              <String, Object?>{
                'data': <Object?>[for (var i = 0; i < count; i++) 1.0 + i],
                'backgroundColor': _red,
              },
            ],
            plugins: [plugin],
          );
          Widget frame(Map<String, Object?> config) => Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 400,
                height: 300,
                child: typed.ChartView.raw(config: config, updateMode: 'none'),
              ),
            ),
          );

          await tester.pumpWidget(frame(rawConfig(3)));
          final chart = chartOf(tester)..update('none');
          expect(_legendOf(chart).legendItemsPending, isTrue);
          await tester.pumpWidget(frame(rawConfig(4)));
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(reads, greaterThanOrEqualTo(2));
          final meta = chartOf(tester).getDatasetMeta(0);
          expect(meta.controller, isNotNull);
          expect(meta.data, hasLength(4));
          expect(chartOf(tester).legend!.legendItems, hasLength(4));
        },
      );
    }

    for (final kind in const [
      typed.ChartKind.pie,
      typed.ChartKind.doughnut,
      typed.ChartKind.polarArea,
    ]) {
      testWidgets('$kind: a new dataset key and a beforeUpdate read', (
        tester,
      ) async {
        final plugin = _hook('beforeUpdate', (chart) {
          chart.legend!.legendItems;
          return null;
        });
        typed.ChartConfig keyed(String key, List<double> data) =>
            config(data, kind: kind).copyWith(
              plugins: [plugin],
              datasets: [
                switch (kind) {
                  typed.ChartKind.polarArea => typed.PolarAreaDataset(
                    key: ValueKey(key),
                    data: data,
                    borderWidth: 0,
                  ),
                  typed.ChartKind.doughnut => typed.DoughnutDataset(
                    key: ValueKey(key),
                    data: data,
                    borderWidth: 0,
                  ),
                  _ => typed.PieDataset(
                    key: ValueKey(key),
                    data: data,
                    borderWidth: 0,
                  ),
                },
              ],
            );

        await tester.pumpWidget(view(keyed('a', [1, 2, 3])));
        await tester.pumpWidget(view(keyed('a', [2, 3, 4])));
        expect(_legendOf(chartOf(tester)).legendItemsPending, isTrue);
        await tester.pumpWidget(view(keyed('b', [3, 4, 5])));
        await tester.pump();
        expect(tester.takeException(), isNull);
        final meta = chartOf(tester).getDatasetMeta(0);
        expect(meta.controller, isNotNull);
        expect(meta.data, hasLength(3));
      });
    }

    for (final kind in const [
      typed.ChartKind.pie,
      typed.ChartKind.doughnut,
      typed.ChartKind.polarArea,
    ]) {
      for (final (name, theme) in [
        ('unthemed', null),
        ('light', const typed.ChartThemeData.light()),
        ('dark', const typed.ChartThemeData.dark()),
      ]) {
        testWidgets('$kind $name: a live chart marks and reads', (
          tester,
        ) async {
          await tester.pumpWidget(view(config([1, 2, 3], kind: kind), theme));
          await tester.pumpWidget(view(config([2, 3, 4], kind: kind), theme));
          await tester.pumpWidget(view(config([3, 4, 5], kind: kind), theme));
          final legend = _legendOf(chartOf(tester));
          expect(legend.legendItemsPending, isTrue);
          final items = _items(legend);
          expect(items, hasLength(3));
          legend.buildLabels();
          expect(_items(legend), items);
        });
      }

      for (final theme in const [
        typed.ChartThemeData.light(),
        typed.ChartThemeData.dark(),
      ]) {
        testWidgets('$kind: indexed colors wait under a theme', (tester) async {
          const indexed = typed.ChartValue<Color>.indexed([_red, _green]);
          await tester.pumpWidget(
            view(config([1, 2, 3], kind: kind, color: indexed), theme),
          );
          await tester.pumpWidget(
            view(config([2, 3, 4], kind: kind, color: indexed), theme),
          );
          final legend = _legendOf(chartOf(tester));
          expect(legend.legendItemsPending, isTrue);
          expect(jsGet(legend.legendItems![1], 'fillStyle'), _green);
        });
      }

      testWidgets('$kind: a resolver color stays eager', (tester) async {
        var calls = 0;
        final resolver = typed.ChartValue<Color>.resolver((context) {
          calls++;
          return _red;
        });
        await tester.pumpWidget(
          view(config([1, 2, 3], kind: kind, color: resolver)),
        );
        calls = 0;
        await tester.pumpWidget(
          view(config([2, 3, 4], kind: kind, color: resolver)),
        );
        expect(_legendOf(chartOf(tester)).legendItemsPending, isFalse);
        expect(calls, greaterThan(0));
      });

      testWidgets('$kind: indexed colors wait', (tester) async {
        const second = Color(0xffed4f6b);
        const indexed = typed.ChartValue<Color>.indexed([
          Color(0xff4f6bed),
          second,
        ]);
        await tester.pumpWidget(
          view(config([1, 2, 3], kind: kind, color: indexed)),
        );
        await tester.pumpWidget(
          view(config([2, 3, 4], kind: kind, color: indexed)),
        );
        final legend = _legendOf(chartOf(tester));
        expect(legend.legendItemsPending, isTrue);
        expect(legend.legendItems, hasLength(3));
        expect(jsGet(legend.legendItems![1], 'fillStyle'), second);
      });
    }
  });

  group('Chart.js ADR 0099: raw indexed Lists', () {
    for (final type in _kinds) {
      for (final step in _steps.keys) {
        testWidgets('$type: the twins of each step up to: $step', (
          tester,
        ) async {
          final chart = acquireChart(_config(type, dataset: _indexedColors));
          final twin = acquireChart(_eager(type, dataset: _indexedColors));
          expect(_state(chart), _state(twin), reason: 'the construction');
          for (final entry in _steps.entries) {
            entry.value(chart);
            entry.value(twin);
            expect(
              _legendOf(chart).legendItemsPending,
              isTrue,
              reason: entry.key,
            );
            expect(_legendOf(twin).legendItemsPending, isFalse);
            expect(_state(chart), _state(twin), reason: entry.key);
            if (entry.key == step) break;
          }
          expect(_items(chart.legend!), _items(twin.legend!));
          final (a, b) = (
            await _pixels(tester, chart..draw()),
            await _pixels(tester, twin..draw()),
          );
          expect(a.buffer.asUint8List(), b.buffer.asUint8List());
        });
      }

      testWidgets('$type: after an update in the mode none, an arc has the '
          'state of the last resolve of the build', (tester) async {
        final chart = acquireChart(_config(type, dataset: _indexedColors))
          ..update('none');
        expect(_legendOf(chart).legendItemsPending, isTrue);
        final arc = chart.getDatasetMeta(0).data[2] as ArcElement;
        final context = arc.$context!;
        expect(context.mode, 'default');
        expect(context.active, isFalse);
        expect(context.index, 2);
        expect(context.dataIndex, 2);
        expect(context.parsed, type == 'polarArea' ? isA<ParsedItem>() : 3);
        expect(context.raw, 3);
      });

      testWidgets('$type: a new arc and a dataset context in the layout', (
        tester,
      ) async {
        // With more labels than arcs, the build writes the dataset context. A
        // new arc gets its context in the first build of its update.
        final log = <Object?>[];
        final twinLog = <Object?>[];
        Map<String, Object?> probe(List<Object?> into) => {
          'id': 'layoutContexts',
          'afterLayout': (Chart chart, Object? args, Object? options) {
            into.add(_contexts(chart));
            return null;
          },
        };
        final chart = acquireChart(
          _config(type, dataset: _indexedColors, plugins: [probe(log)]),
        );
        final twin = acquireChart(
          _eager(type, dataset: _indexedColors, plugins: [probe(twinLog)]),
        );
        for (final each in [chart, twin]) {
          (_dataset0(each)['data']! as List<Object?>).add(4.0);
          _labelsOf(each).addAll(<Object?>['d', 'e', 'f']);
          each.update('none');
        }
        expect(_legendOf(chart).legendItemsPending, isTrue);
        expect(log, twinLog);
        expect(log.last, hasLength(5));
        expect(_state(chart), _state(twin));
      });

      testWidgets('$type: a dataset with no arcs and with labels', (
        tester,
      ) async {
        final dataset = {
          ..._indexedColors,
          'data': <Object?>[],
        };
        final chart = acquireChart(_config(type, dataset: dataset));
        final twin = acquireChart(_eager(type, dataset: dataset));
        chart.update('none');
        twin.update('none');
        expect(_legendOf(chart).legendItemsPending, isTrue);
        expect(_state(chart), _state(twin));
        expect(_items(chart.legend!), _items(twin.legend!));
      });

      testWidgets('$type: a second dataset keeps its own path', (tester) async {
        var calls = 0;
        var twinCalls = 0;
        List<Object?> datasets(void Function() count) => <Object?>[
          <String, Object?>{
            'data': <Object?>[1.0, 2.0, 3.0],
            ..._indexedColors,
          },
          <String, Object?>{
            'data': <Object?>[3.0, 2.0, 1.0],
            'backgroundColor': (Object? ctx) {
              count();
              return _green;
            },
          },
        ];
        final chart = acquireChart(
          _config(type, datasets: datasets(() => calls++)),
        );
        final twin = acquireChart(
          _config(
            type,
            datasets: datasets(() => twinCalls++),
            labels: {'filter': _keepItem},
          ),
        );
        chart.update('none');
        twin.update('none');
        expect(_legendOf(chart).legendItemsPending, isTrue);
        expect(calls, twinCalls);
        expect(_state(chart), _state(twin));
        expect(_contexts(chart, 1), _contexts(twin, 1));
        expect(_arcs(chart, 1), _arcs(twin, 1));
      });

      testWidgets('$type: an animated update', (tester) async {
        Map<String, Object?> options() => {
          'animation': <String, Object?>{'duration': 40.0},
        };
        final chart = acquireChart(
          _config(type, dataset: _indexedColors, options: options()),
          <String, Object?>{'animation': true},
        );
        final twin = acquireChart(
          _eager(type, dataset: _indexedColors, options: options()),
          <String, Object?>{'animation': true},
        );
        for (final each in [chart, twin]) {
          _dataset0(each)['data'] = <Object?>[7.0, 8.0, 9.0];
          each.update();
        }
        expect(_legendOf(chart).legendItemsPending, isTrue);
        expect(_contexts(chart), _contexts(twin));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
        expect(_state(chart), _state(twin));
        expect(_items(chart.legend!), _items(twin.legend!));
      });

      testWidgets('$type: a hover option with a function, and hover events', (
        tester,
      ) async {
        final calls = <Object?>[];
        final twinCalls = <Object?>[];
        Map<String, Object?> dataset(List<Object?> into) => {
          ..._indexedColors,
          'hoverBackgroundColor': (ScriptableContext ctx) {
            into.add([ctx.index, ctx.mode, ctx.active]);
            return _black;
          },
        };
        final chart = acquireChart(_config(type, dataset: dataset(calls)));
        final twin = acquireChart(_eager(type, dataset: dataset(twinCalls)));
        expect(_legendOf(chart).legendItemsPending, isTrue);
        final element = chart.getDatasetMeta(0).data[1];
        final twinElement = twin.getDatasetMeta(0).data[1];
        for (final (each, arc) in [(chart, element), (twin, twinElement)]) {
          await triggerMouseEvent(each, 'mousemove', arc);
          await tester.pump();
        }
        expect(calls, isNotEmpty);
        expect(calls, twinCalls);
        expect(chart.getActiveElements(), hasLength(1));
        expect(_state(chart), _state(twin));
        for (final each in [chart, twin]) {
          each.update('none');
        }
        expect(_legendOf(chart).legendItemsPending, isTrue);
        expect(calls, twinCalls);
        expect(_state(chart), _state(twin));
        final state = _contexts(chart);
        // The read of the items writes no context.
        expect(_items(chart.legend!), _items(twin.legend!));
        expect(_contexts(chart), state);
        for (final each in [chart, twin]) {
          each.setActiveElements(<Object?>[]);
        }
        expect(calls, twinCalls);
        expect(_state(chart), _state(twin));
        final (a, b) = (
          await _pixels(tester, chart..draw()),
          await _pixels(tester, twin..draw()),
        );
        expect(a.buffer.asUint8List(), b.buffer.asUint8List());
      });
    }

    testWidgets('a label that repeats keeps the index of its item', (
      tester,
    ) async {
      final labels = <Object?>['x', 'x', 'x'];
      final chart = acquireChart(
        _config('pie', dataset: _indexedColors, labelValues: labels),
      );
      final twin = acquireChart(
        _config(
          'pie',
          dataset: _indexedColors,
          labels: {'filter': _keepItem},
          labelValues: <Object?>['x', 'x', 'x'],
        ),
      );
      expect(_items(chart.legend!), _items(twin.legend!));
    });

    testWidgets('a function past the entries of the labels is no read', (
      tester,
    ) async {
      final chart = acquireChart(
        _config(
          'pie',
          dataset: {
            'backgroundColor': <Object?>[_red, _green, _blue, _keepItem],
          },
        ),
      )..update('none');
      expect(_legendOf(chart).legendItemsPending, isTrue);
      expect(jsGet(chart.legend!.legendItems![2], 'fillStyle'), _blue);
    });

    // `configure` of the update starts new scopes and a new resolver: a write
    // after the layout reaches the update, and the layout builds do not see it.
    for (final hook in const ['afterLayout', 'beforeDatasetsUpdate']) {
      testWidgets('a write in $hook', (tester) async {
        var armed = false;
        final seen = <Object?>[];
        final twinSeen = <Object?>[];
        Map<String, Object?> plugin(List<Object?> into) => {
          'id': 'writer',
          hook: (Chart chart, Object? args, Object? options) {
            if (armed) {
              into.add(_items(chart.legend!));
              _dataset0(chart)['borderWidth'] = 9.0;
              _dataset0(chart)['backgroundColor'] = <Object?>[_black];
            }
            return null;
          },
        };
        final chart = acquireChart(
          _config('pie', dataset: _indexedColors, plugins: [plugin(seen)]),
        );
        final twin = acquireChart(
          _eager('pie', dataset: _indexedColors, plugins: [plugin(twinSeen)]),
        );
        armed = true;
        chart.update('none');
        twin.update('none');
        expect(seen, twinSeen);
        expect(_state(chart), _state(twin));
        final options = (chart.getDatasetMeta(0).data[1] as ArcElement).options;
        expect(jsGet(options, 'borderWidth'), 9);
        armed = false;
        chart.update('none');
        twin.update('none');
        expect(_legendOf(chart).legendItemsPending, isTrue);
        expect(_state(chart), _state(twin));
        expect(_items(chart.legend!), _items(twin.legend!));
        expect(jsGet(chart.legend!.legendItems![1], 'fillStyle'), _black);
      });

      testWidgets('a write of a function in $hook', (tester) async {
        var armed = false;
        var calls = 0;
        Object? color(Object? ctx) {
          calls++;
          return _black;
        }

        Map<String, Object?> plugin() => {
          'id': 'writer',
          hook: (Chart chart, Object? args, Object? options) {
            if (armed) _dataset0(chart)['backgroundColor'] = color;
            return null;
          },
        };
        final chart = acquireChart(
          _config('pie', dataset: _indexedColors, plugins: [plugin()]),
        );
        final twin = acquireChart(
          _eager('pie', dataset: _indexedColors, plugins: [plugin()]),
        );
        armed = true;
        chart.update('none');
        final seen = calls;
        calls = 0;
        twin.update('none');
        expect(seen, greaterThan(0));
        expect(seen, calls);
        // The dataset update resolves the function: the last build is eager.
        expect(_legendOf(chart).legendItemsPending, isFalse);
        expect(_state(chart), _state(twin));
        expect(_items(chart.legend!), _items(twin.legend!));
      });
    }

    testWidgets('a read in beforeUpdate leaves the new resolver cold', (
      tester,
    ) async {
      var armed = false;
      Map<String, Object?> plugin() => {
        'id': 'readThenWrite',
        'beforeUpdate': (Chart chart, Object? args, Object? options) {
          if (armed) {
            chart.legend!.legendItems;
            _dataset0(chart)['borderWidth'] = 9.0;
          }
          return null;
        },
      };
      final chart = acquireChart(
        _config('pie', dataset: _indexedColors, plugins: [plugin()]),
      );
      final twin = acquireChart(
        _eager('pie', dataset: _indexedColors, plugins: [plugin()]),
      );
      armed = true;
      chart.update('none');
      twin.update('none');
      expect(_state(chart), _state(twin));
      expect(
        jsGet(
          (chart.getDatasetMeta(0).data[1] as ArcElement).options,
          'borderWidth',
        ),
        9,
      );
    });

    testWidgets('a write through the resolver ends the plan', (tester) async {
      var calls = 0;
      final chart = acquireChart(_config('pie', dataset: _indexedColors));
      final twin = acquireChart(_eager('pie', dataset: _indexedColors));
      Object? color(Object? ctx) {
        calls++;
        return _black;
      }

      expect(_legendOf(chart).legendItemsPending, isTrue);
      for (final each in [chart, twin]) {
        final config = each.config;
        final dataset = _dataset0(each);
        final scopes = config.getOptionScopes(
          dataset,
          config.datasetElementScopeKeys('pie', 'arc'),
        );
        final resolver =
            config.createResolver(scopes, null, ['arc', '']) as OptionResolver;
        resolver['backgroundColor'] = color;
      }
      // The chart read with the plan gives the last built items: the plan is
      // gone, and a read does not ask the new options.
      final built = _items(chart.legend!);
      expect(built, hasLength(3));
      expect(calls, 0);
      for (final each in [chart, twin]) {
        calls = 0;
        each.update('none');
        expect(calls, greaterThan(0));
        if (identical(each, chart)) {
          expect(_legendOf(chart).legendItemsPending, isFalse);
        }
      }
      expect(_state(chart), _state(twin));
    });
  });

  group('Chart.js ADR 0099: the reads of each hook', () {
    /// An inline plugin that logs the state in each hook of [_hooks], except
    /// when [armed] gives false. With [read], each hook reads the items first.
    Map<String, Object?> logger(
      List<Object?> log,
      bool Function() armed, {
      required bool read,
    }) => {
      'id': 'logger',
      for (final hook in _hooks)
        hook: (Chart chart, Object? args, Object? options) {
          if (armed()) {
            log.add([
              hook,
              if (read) _items(chart.legend!),
              _contexts(chart),
            ]);
          }
          return null;
        },
    };

    for (final type in _kinds) {
      for (final read in const [false, true]) {
        testWidgets('$type: the contexts in each hook: read $read', (
          tester,
        ) async {
          var armed = false;
          final log = <Object?>[];
          final twinLog = <Object?>[];
          final chart = acquireChart(
            _config(
              type,
              dataset: _indexedColors,
              plugins: [logger(log, () => armed, read: read)],
            ),
          );
          final twin = acquireChart(
            _eager(
              type,
              dataset: _indexedColors,
              plugins: [logger(twinLog, () => armed, read: read)],
            ),
          );
          armed = true;
          for (final each in [chart, twin]) {
            each.update('none');
            (_dataset0(each)['data']! as List<Object?>).add(4.0);
            _labelsOf(each).add('d');
            each
              ..update('none')
              ..update()
              ..setActiveElements(<Object?>[
                <String, Object?>{'datasetIndex': 0, 'index': 1},
              ])
              ..update('none')
              ..draw();
          }
          expect(log, isNotEmpty);
          expect(log, twinLog);
          expect(_state(chart), _state(twin));
        });
      }

      testWidgets('$type: a scale or box callback in the layout reads the '
          'contexts of this update', (tester) async {
        final log = <Object?>[];
        final twinLog = <Object?>[];
        Map<String, Object?> options(List<Object?> into) => {
          'plugins': <String, Object?>{
            'title': <String, Object?>{
              'display': true,
              'text': (Object? ctx) {
                into.add(_contexts(jsGet(ctx, 'chart')! as Chart));
                return 'title';
              },
            },
            'legend': <String, Object?>{
              'display': false,
              'labels': <String, Object?>{},
            },
          },
        };
        final chart = acquireChart(
          _config(type, dataset: _indexedColors, options: options(log)),
        );
        final twin = acquireChart(
          _config(
            type,
            dataset: _indexedColors,
            options: options(twinLog),
          ),
        );
        // The twin takes the filter through its own label options.
        _labelOptionsOf(twin)['filter'] = _keepItem;
        for (final each in [chart, twin]) {
          (_dataset0(each)['data']! as List<Object?>)[0] = 5.0;
          each.update('none');
        }
        expect(_legendOf(chart).legendItemsPending, isTrue);
        expect(_legendOf(twin).legendItemsPending, isFalse);
        expect(log.last, twinLog.last);
        expect(_state(chart), _state(twin));
      });
    }
  });

  group('Chart.js ADR 0099: each guard keeps the ordinary path', () {
    for (final type in _kinds) {
      for (final (name, build)
          in <
            (String, Map<String, Object?> Function(Object? Function(Object?)))
          >[
            (
              'a scriptable color',
              (function) => {
                'backgroundColor': (Object? ctx) {
                  function(ctx);
                  return _red;
                },
                'borderColor': <Object?>[_blue, _black],
              },
            ),
            (
              'a function on another key',
              (function) => {
                'backgroundColor': <Object?>[_red, _green],
                'borderWidth': function,
              },
            ),
          ]) {
        testWidgets('$type: $name', (tester) async {
          var calls = 0;
          Object? function(Object? ctx) {
            calls++;
            return 1.0;
          }

          final chart = acquireChart(_config(type, dataset: build(function)))
            ..update('none');
          final seen = calls;
          expect(_legendOf(chart).legendItemsPending, isFalse);
          calls = 0;
          final twin = acquireChart(_eager(type, dataset: build(function)))
            ..update('none');
          expect(seen, greaterThan(0));
          expect(seen, calls);
          expect(_state(chart), _state(twin));
          expect(_items(chart.legend!), _items(twin.legend!));
        });
      }

      testWidgets('$type: a function in defaults.elements.arc', (tester) async {
        var calls = 0;
        defaults.set('elements.arc', <String, Object?>{
          'offset': (Object? ctx) {
            calls++;
            return 1.0;
          },
        });
        final chart = acquireChart(_config(type, dataset: _indexedColors))
          ..update('none');
        final seen = calls;
        expect(_legendOf(chart).legendItemsPending, isFalse);
        calls = 0;
        final twin = acquireChart(_eager(type, dataset: _indexedColors))
          ..update('none');
        expect(seen, calls);
        expect(seen, greaterThan(0));
        expect(_state(chart), _state(twin));
      });

      testWidgets('$type: a function under a new key of the arc defaults', (
        tester,
      ) async {
        var calls = 0;
        final arcDefaults =
            readOption(defaults.lookup(OptionKey.elements)?.raw, OptionKey.arc)!
                  as JsObjectFace
              ..jsWrite('userKey', (Object? ctx) {
                calls++;
                return 1.0;
              });
        addTearDown(() => arcDefaults.jsDelete('userKey'));
        final chart = acquireChart(_config(type, dataset: _indexedColors))
          ..update('none');
        final seen = calls;
        expect(_legendOf(chart).legendItemsPending, isFalse);
        calls = 0;
        final twin = acquireChart(_eager(type, dataset: _indexedColors))
          ..update('none');
        expect(seen, calls);
        expect(seen, greaterThan(0));
        expect(_state(chart), _state(twin));
      });

      testWidgets('$type: a function in the options of the elements', (
        tester,
      ) async {
        var calls = 0;
        Map<String, Object?> options() => {
          'elements': <String, Object?>{
            'arc': <String, Object?>{
              'offset': (Object? ctx) {
                calls++;
                return 1.0;
              },
            },
          },
        };
        final chart = acquireChart(
          _config(type, dataset: _indexedColors, options: options()),
        )..update('none');
        final seen = calls;
        expect(_legendOf(chart).legendItemsPending, isFalse);
        calls = 0;
        final twin = acquireChart(
          _eager(type, dataset: _indexedColors, options: options()),
        )..update('none');
        expect(seen, calls);
        expect(seen, greaterThan(0));
        expect(_state(chart), _state(twin));
      });

      testWidgets('$type: a filter, a sort and a user generator', (
        tester,
      ) async {
        var filters = 0;
        var sorts = 0;
        var generators = 0;
        final labels = <Map<String, Object?>>[
          {
            'filter': (Object? item, Object? data) {
              filters++;
              return true;
            },
          },
          {
            'sort': (Object? a, Object? b, Object? data) {
              sorts++;
              return 0;
            },
          },
          {
            'generateLabels': (Object? chart) {
              generators++;
              return <Object?>[
                <String, Object?>{'text': 'x'},
              ];
            },
          },
        ];
        for (final each in labels) {
          final chart = acquireChart(
            _config(type, dataset: _indexedColors, labels: each),
          );
          expect(_legendOf(chart).legendItemsPending, isFalse);
          chart.update('none');
          expect(_legendOf(chart).legendItemsPending, isFalse);
        }
        expect(filters, 18, reason: 'each item of each of 6 builds');
        expect(sorts, greaterThanOrEqualTo(12), reason: 'each of 6 builds');
        expect(generators, 6);
      });

      testWidgets('$type: foreign values', (tester) async {
        // These values are foreign on purpose: no review of the oracle O2.
        final audit = foreignAudit;
        foreignAudit = (owner, key, raw) {};
        addTearDown(() => foreignAudit = audit);
        for (final dataset in <Map<String, Object?>>[
          {
            // An object entry gives a sub resolver.
            'borderAlign': <Object?>[
              <String, Object?>{'a': 1},
              'inner',
            ],
          },
          {
            // A function entry is a value.
            'borderAlign': <Object?>[_keepItem, 'inner'],
          },
          {
            // A function entry past the first item.
            'borderAlign': <Object?>['inner', _keepItem],
          },
          {
            // A number key with a string.
            'borderWidth': '3',
            'backgroundColor': <Object?>[_red, _green],
          },
          {
            'borderWidth': <Object?>['3', 2.0],
            'backgroundColor': <Object?>[_red, _green],
          },
          {
            // An empty list has no value for an index.
            'borderAlign': <Object?>[],
            'backgroundColor': <Object?>[_red, _green],
          },
          {
            // A list of another class can run user code at each read.
            'backgroundColor': _ObservedList(<Object?>[_red, _green]),
          },
          {
            // A list of a key that its descriptor makes not indexable.
            'borderAlign': <Object?>['inner', 'center'],
            'backgroundColor': <Object?>[_red, _green],
            '_indexable': (String name) => name != 'borderAlign',
          },
          {
            'backgroundColor': <Object?>[_red, _green],
            '_scriptable': (String name) => true,
          },
          {
            'backgroundColor': <Object?>[_red, _green],
            '_indexable': (String name) => true,
          },
          {
            // A raw list of `borderDash` with an object at item 0.
            'backgroundColor': <Object?>[_red, _green],
            'borderDash': <Object?>[
              <String, Object?>{'a': 1},
            ],
          },
        ]) {
          final chart = acquireChart(_config(type, dataset: dataset))
            ..update('none');
          expect(
            _legendOf(chart).legendItemsPending,
            isFalse,
            reason: '$dataset',
          );
          final twin = acquireChart(_eager(type, dataset: dataset))
            ..update('none');
          expect(_state(chart), _state(twin), reason: '$dataset');
          expect(
            _plain(_items(chart.legend!)),
            _plain(_items(twin.legend!)),
            reason: '$dataset',
          );
        }
      });

      testWidgets('$type: a list that stays a value', (tester) async {
        // With `_indexable: false`, no value needs a context: the entry of the
        // cached options is the proof of Chart.js ADR 0092.
        final dataset = <String, Object?>{
          'borderAlign': <Object?>['inner', 'center'],
          '_indexable': false,
        };
        final chart = acquireChart(_config(type, dataset: dataset))
          ..update('none');
        final twin = acquireChart(_eager(type, dataset: dataset))
          ..update('none');
        expect(_state(chart), _state(twin));
        expect(_items(chart.legend!), _items(twin.legend!));
      });

      testWidgets('$type: a dataset and an options Map of another class', (
        tester,
      ) async {
        final dataset = _ObservedMap({
          'data': <Object?>[1.0, 2.0, 3.0],
          ..._indexedColors,
        });
        final chart = acquireChart(_config(type, datasets: <Object?>[dataset]))
          ..update('none');
        expect(_legendOf(chart).legendItemsPending, isFalse);
        final twin = acquireChart(
          _config(
            type,
            datasets: <Object?>[
              _ObservedMap({
                'data': <Object?>[1.0, 2.0, 3.0],
                ..._indexedColors,
              }),
            ],
            labels: {'filter': _keepItem},
          ),
        )..update('none');
        expect(_state(chart), _state(twin));

        final options = _ObservedMap({
          'elements': <String, Object?>{},
          'plugins': <String, Object?>{
            'legend': <String, Object?>{
              'display': false,
              'labels': <String, Object?>{},
            },
          },
        });
        final other = acquireChart(<String, Object?>{
          'type': type,
          'data': <String, Object?>{
            'labels': <Object?>['a', 'b', 'c'],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[1.0, 2.0, 3.0],
                ..._indexedColors,
              },
            ],
          },
          'options': options,
        })..update('none');
        expect(_legendOf(other).legendItemsPending, isFalse);
      });

      testWidgets('$type: a user subclass of the arc', (tester) async {
        // Each read of the context of the user arc stays where it was.
        List<Object?> run(Chart chart) {
          final reads = <Object?>[];
          final meta = chart.getDatasetMeta(0);
          final arc = _UserArc(reads);
          meta.data[1] = arc;
          chart.update('none');
          expect(_legendOf(chart).legendItemsPending, isFalse);
          return reads;
        }

        final chart = acquireChart(_config(type, dataset: _indexedColors));
        final twin = acquireChart(_eager(type, dataset: _indexedColors));
        final reads = run(chart);
        expect(reads, isNotEmpty);
        expect(reads, run(twin));
        expect(_state(chart), _state(twin));
        expect(_items(chart.legend!), _items(twin.legend!));
      });

      testWidgets('$type: the scalar context and a user context', (
        tester,
      ) async {
        // A deleted key takes its place at the end of the keys again. A value
        // that is not a context gets a new context.
        final chart = acquireChart(_config(type, dataset: _indexedColors));
        final twin = acquireChart(_eager(type, dataset: _indexedColors));
        for (final each in [chart, twin]) {
          final data = each.getDatasetMeta(0).data;
          (data[0] as ArcElement).$context!.jsDelete('mode');
          (data[1] as ArcElement)[r'$context'] = 'text';
          (data[2] as ArcElement).$context!
            ..jsWrite('index', -0.0)
            ..jsWrite('dataIndex', 7.0);
          each.update('none');
        }
        expect(_legendOf(chart).legendItemsPending, isTrue);
        expect(_state(chart), _state(twin));
      });

      testWidgets('$type: a user subclass of the chart', (tester) async {
        final canvas = UiCanvasElement(width: 300, height: 300);
        final chart = _ChildChart(
          canvas,
          _config(type, dataset: _indexedColors),
        );
        addTearDown(chart.destroy);
        chart.update('none');
        expect(_legendOf(chart).legendItemsPending, isFalse);
        final twin = acquireChart(_config(type, dataset: _indexedColors));
        expect(_legendOf(twin).legendItemsPending, isTrue);
      });
    }

    for (final (id, parent, child) in [
      ('pieChild', 'pie', _pieChild),
      ('doughnutChild', 'doughnut', _doughnutChild),
      ('polarChild', 'polarArea', _polarChild),
    ]) {
      testWidgets('a subclass of the controller: $id', (tester) async {
        registry.addControllers([child]);
        addTearDown(() => registry.removeControllers([child]));
        final chart = acquireChart(_config(id, dataset: _indexedColors));
        final exact = acquireChart(_config(parent, dataset: _indexedColors));
        for (final mode in ['none', 'default']) {
          chart.update(mode);
          exact.update(mode);
          expect(_legendOf(chart).legendItemsPending, isFalse);
          expect(_legendOf(exact).legendItemsPending, isTrue);
          expect(_contexts(chart)[0], _contexts(exact)[0]);
          expect(_arcs(chart), _arcs(exact));
          expect(_items(chart.legend!), _items(exact.legend!));
        }
      });
    }

    test('the proof takes the exact Config', () {
      Map<String, Object?> make() => _config('pie', dataset: _indexedColors);
      expect(
        Config(make()).prepareIndexedArcStyles(
          0,
          controllerType: 'pie',
          count: 3,
        ),
        isNotNull,
      );
      expect(
        _TrivialConfig(make()).prepareIndexedArcStyles(
          0,
          controllerType: 'pie',
          count: 3,
        ),
        isNull,
      );
    });
  });

  group('Chart.js ADR 0099: a read before the mark of the layout', () {
    // The update rebuilds the arcs before the layout, and the mark of the
    // layout comes after them. A read in this window gives what the last
    // `afterUpdate` built: the index of each item comes from the arcs of that
    // mark, not from the arcs of the update.
    const cases =
        <(String, List<Object?>, List<Object?>, List<Object?>, List<Object?>)>[
          (
            'fewer arcs',
            <Object?>['a', 'b', 'c'],
            <Object?>[1.0, 2.0, 3.0],
            <Object?>[1.0],
            <Object?>[_red, _green, _blue],
          ),
          (
            'more arcs',
            <Object?>['a', 'b', 'c', 'd'],
            <Object?>[1.0, 2.0],
            <Object?>[1.0, 2.0, 3.0, 4.0],
            <Object?>[_red, _green, _red, _red],
          ),
        ];

    for (final type in _kinds) {
      for (final (name, labels, before, after, expected) in cases) {
        testWidgets('$type: $name: a read in beforeLayout', (tester) async {
          List<Object?> run({required bool exact}) {
            var armed = false;
            final log = <Object?>[];
            final chart = _chartOf(
              _config(
                type,
                labelValues: <Object?>[...labels],
                dataset: {
                  'data': <Object?>[...before],
                  'backgroundColor': <Object?>[_red, _green, _blue],
                },
                plugins: [
                  _hook('beforeLayout', (chart) {
                    if (armed) log.add(_fillStyles(chart));
                    return null;
                  }),
                ],
              ),
              exact: exact,
            );
            expect(_legendOf(chart).legendItemsPending, exact);
            armed = true;
            _dataset0(chart)['data'] = <Object?>[...after];
            chart.update('none');
            expect(_legendOf(chart).legendItemsPending, exact);
            return [...log, _items(chart.legend!), _state(chart)];
          }

          final exact = run(exact: true);
          expect(exact.first, expected);
          expect(exact, run(exact: false));
        });

        testWidgets('$type: $name: a read in a title function', (tester) async {
          List<Object?> run({required bool exact}) {
            var armed = false;
            final log = <Object?>[];
            final chart = _chartOf(
              _config(
                type,
                labelValues: <Object?>[...labels],
                dataset: {
                  'data': <Object?>[...before],
                  'backgroundColor': <Object?>[_red, _green, _blue],
                },
                options: {
                  'plugins': <String, Object?>{
                    'title': <String, Object?>{
                      'display': true,
                      'text': (Object? ctx) {
                        if (armed) {
                          log.add(_fillStyles(jsGet(ctx, 'chart')! as Chart));
                        }
                        return 'title';
                      },
                    },
                    'legend': <String, Object?>{
                      'display': false,
                      'labels': <String, Object?>{},
                    },
                  },
                },
              ),
              exact: exact,
            );
            armed = true;
            _dataset0(chart)['data'] = <Object?>[...after];
            chart.update('none');
            expect(_legendOf(chart).legendItemsPending, exact);
            return [...log, _items(chart.legend!), _state(chart)];
          }

          final exact = run(exact: true);
          expect(exact.first, expected);
          expect(exact, run(exact: false));
        });
      }

      for (final hook in const [
        'beforeElementsUpdate',
        'beforeLayout',
        'afterLayout',
        'beforeDatasetsUpdate',
        'afterUpdate',
      ]) {
        testWidgets('$type: the twins with a read in $hook', (tester) async {
          // The steps leave the labels: their List is live in each read.
          final steps = <void Function(Chart chart)>[
            (chart) => _dataset0(chart)['data'] = <Object?>[5.0],
            (chart) => _dataset0(chart)['data'] = <Object?>[],
            (chart) => _dataset0(chart)['data'] = <Object?>[
              1.0,
              2.0,
              3.0,
              4.0,
              5.0,
            ],
            (chart) => _dataset0(chart)['backgroundColor'] = <Object?>[
              _blue,
              _red,
              _green,
            ],
            (chart) => _dataset0(chart)['borderWidth'] = <Object?>[1.0, 2.0],
            (chart) => _dataset0(chart)['data'] = <Object?>[4.0, 3.0],
            (chart) => (_dataset0(chart)['data']! as List<Object?>).add(1.0),
            (chart) => _dataset0(chart)['backgroundColor'] = <Object?>[_black],
          ];

          List<Object?> run({required bool exact}) {
            var armed = false;
            final log = <Object?>[];
            final chart = _chartOf(
              _config(
                type,
                dataset: _indexedColors,
                plugins: [
                  _hook(hook, (chart) {
                    if (armed) log.add(_items(chart.legend!));
                    return null;
                  }),
                ],
              ),
              exact: exact,
            );
            armed = true;
            for (final step in steps) {
              step(chart);
              chart.update('none');
              expect(
                _legendOf(chart).legendItemsPending,
                exact && hook != 'afterUpdate',
              );
              log.add(_state(chart));
            }
            log.add(_items(chart.legend!));
            return log;
          }

          expect(run(exact: true), run(exact: false));
        });
      }
    }
  });

  group('Chart.js ADR 0099: the first resolve of a build keeps its order', () {
    test('a peek gives the raw value with no effect', () {
      var calls = 0;
      final object = <String, Object?>{'outerStart': 1.0};
      final scope = <String, Object?>{
        'borderRadius': object,
        'borderWidth': 2.0,
        '_fallback': (Object? prop, Object? value) {
          calls++;
          return undefined;
        },
      };
      final resolver = createResolver([scope]);
      expect(resolver.scopesAreNative, isTrue);
      expect(resolver.peekKey(OptionKey.borderRadius), same(object));
      expect(resolver.peekKey(OptionKey.borderWidth), 2.0);
      expect(resolver.peekKey(OptionKey.spacing), same(undefined));
      expect(calls, 0, reason: 'no sub resolver');
      scope['borderWidth'] = 3.0;
      expect(resolver.peekKey(OptionKey.borderWidth), 3.0, reason: 'no cache');
      expect(resolver.readKey(OptionKey.borderWidth), 3.0);
      scope['borderWidth'] = 4.0;
      expect(resolver.peekKey(OptionKey.borderWidth), 3.0, reason: 'its cache');
      expect(resolver.readKey(OptionKey.borderRadius), isA<OptionResolver>());
      expect(calls, 1);
      expect(resolver.peekKey(OptionKey.borderRadius), isA<OptionResolver>());
    });

    test('a Map of another class and a write of a slot are not native', () {
      expect(
        createResolver([_ObservedMap(<String, Object?>{})]).scopesAreNative,
        isFalse,
      );
      final resolver = createResolver([<String, Object?>{}]);
      expect(resolver.scopesAreNative, isTrue);
      resolver['_scopes'] = <Object?>[];
      expect(resolver.scopesAreNative, isFalse);
    });

    for (final type in _kinds) {
      for (final display in const [false, true]) {
        final name = '$type: display $display';

        testWidgets('$name: a function _fallback past the first list', (
          tester,
        ) async {
          // A sub resolver of the option `borderRadius` calls the function.
          // The ordinary build makes it after the context of the first resolve.
          List<Object?> run({required bool exact}) {
            var armed = false;
            final log = <Object?>[];
            late final Chart chart;
            chart = _chartOf(
              _config(
                type,
                legend: {'display': display},
                dataset: {
                  'borderColor': <Object?>[_blue, _black],
                  'borderRadius': <String, Object?>{'outerStart': 1.0},
                  '_fallback': (Object? prop, Object? value) {
                    if (armed) log.add([prop, _firstArcState(chart)]);
                    return undefined;
                  },
                },
              ),
              exact: exact,
            );
            _changeFirstArc(chart);
            armed = true;
            chart.update('none');
            armed = false;
            return log;
          }

          final exact = run(exact: true);
          expect(exact, isNotEmpty);
          expect((exact.first! as List<Object?>)[1], 'default/false/raw=9.0');
          expect(exact, run(exact: false));
        });

        testWidgets('$name: a throwing _fallback past the first list', (
          tester,
        ) async {
          List<Object?> run({required bool exact}) {
            var armed = false;
            final chart = _chartOf(
              _config(
                type,
                legend: {'display': display},
                dataset: {
                  'borderColor': <Object?>[_blue, _black],
                  'borderRadius': <String, Object?>{'outerStart': 1.0},
                  '_fallback': (Object? prop, Object? value) {
                    if (armed) throw StateError('fallback');
                    return undefined;
                  },
                },
              ),
              exact: exact,
            );
            _changeFirstArc(chart);
            armed = true;
            expect(() => chart.update('none'), throwsStateError);
            armed = false;
            return [_firstArcState(chart)];
          }

          final exact = run(exact: true);
          expect(exact, ['default/false/raw=9.0']);
          expect(exact, run(exact: false));
        });

        testWidgets('$name: a Map of another class past the first list', (
          tester,
        ) async {
          List<Object?> run({required bool exact}) {
            var armed = false;
            final log = <Object?>[];
            late final Chart chart;
            chart = _chartOf(
              _config(
                type,
                legend: {'display': display},
                dataset: {
                  'borderColor': <Object?>[_blue, _black],
                  'borderRadius': _ObservedMap(
                    <String, Object?>{'outerStart': 1.0},
                    (key) {
                      if (armed) log.add([key, _firstArcState(chart)]);
                    },
                  ),
                },
              ),
              exact: exact,
            );
            _changeFirstArc(chart);
            armed = true;
            chart.update('none');
            armed = false;
            return log;
          }

          final exact = run(exact: true);
          expect(exact, isNotEmpty);
          expect((exact.first! as List<Object?>)[1], 'default/false/raw=9.0');
          expect(exact, run(exact: false));
        });
      }

      testWidgets('$type: a Map of another class in the labels', (
        tester,
      ) async {
        // The ordinary build reads `filter` after the contexts of a resolve.
        List<Object?> run({required bool exact}) {
          var armed = false;
          final log = <Object?>[];
          late final Chart chart;
          chart = _chartOf(
            _config(
              type,
              legend: {
                'labels': _ObservedMap(<String, Object?>{}, (key) {
                  if (armed && key == 'filter') {
                    log.add(_firstArcState(chart));
                  }
                }),
              },
              dataset: _indexedColors,
            ),
            exact: exact,
          );
          _changeFirstArc(chart);
          armed = true;
          chart.update('none');
          armed = false;
          return [log, _state(chart)];
        }

        final exact = run(exact: true);
        expect((exact.first! as List<Object?>).first, 'default/false/raw=9.0');
        expect(exact, run(exact: false));
      });

      testWidgets('$type: a Map of another class in the legend', (
        tester,
      ) async {
        // The ordinary build reads `reverse` after the contexts of a resolve.
        List<Object?> run({required bool exact}) {
          var armed = false;
          final log = <Object?>[];
          late final Chart chart;
          chart = _chartOf(
            _config(
              type,
              dataset: _indexedColors,
              options: {
                'plugins': <String, Object?>{
                  'legend': _ObservedMap(
                    <String, Object?>{
                      'display': false,
                      'labels': <String, Object?>{},
                    },
                    (key) {
                      if (armed && key == 'reverse') {
                        log.add(_firstArcState(chart));
                      }
                    },
                  ),
                },
              },
            ),
            exact: exact,
          );
          _changeFirstArc(chart);
          armed = true;
          chart.update('none');
          armed = false;
          return [log, _state(chart)];
        }

        final exact = run(exact: true);
        expect((exact.first! as List<Object?>).first, 'default/false/raw=9.0');
        expect(exact, run(exact: false));
      });

      for (final key in const ['reverse', 'display']) {
        testWidgets('$type: an object at the legend key $key', (tester) async {
          // Its read makes a sub resolver, which calls the function _fallback.
          List<Object?> run({required bool exact}) {
            var armed = false;
            final log = <Object?>[];
            late final Chart chart;
            chart = _chartOf(
              _config(
                type,
                dataset: _indexedColors,
                legend: {
                  key: <String, Object?>{},
                  '_fallback': (Object? prop, Object? value) {
                    if (armed && prop == key) log.add(_firstArcState(chart));
                    return undefined;
                  },
                },
              ),
              exact: exact,
            );
            _changeFirstArc(chart);
            armed = true;
            chart.update('none');
            armed = false;
            return [log, _state(chart)];
          }

          final exact = run(exact: true);
          expect(
            (exact.first! as List<Object?>).first,
            'default/false/raw=9.0',
          );
          expect(exact, run(exact: false));
        });
      }

      testWidgets('$type: a user arc at index 0 changes an option', (
        tester,
      ) async {
        // The ordinary resolve stops at the first list. It reads `borderWidth`
        // after the context of that arc, where user code can change it. The
        // layout build gives the item; the dataset update has a new resolver.
        List<Object?> run({required bool exact}) {
          var armed = false;
          final log = <Object?>[];
          final chart = _chartOf(
            _config(
              type,
              dataset: _indexedColors,
              plugins: [
                _hook('afterLayout', (chart) {
                  if (armed) log.add(_fillAndWidth(chart));
                  return null;
                }),
              ],
            ),
            exact: exact,
          );
          final dataset = _dataset0(chart);
          chart.getDatasetMeta(0).data[0] = _UserArc(<Object?>[], () {
            if (armed) dataset['borderWidth'] = 9.0;
          });
          armed = true;
          chart.update('none');
          armed = false;
          return [log, _arcs(chart)];
        }

        final exact = run(exact: true);
        expect(
          ((exact.first! as List<Object?>).first! as List<Object?>).first,
          [
            _red,
            9.0,
          ],
        );
        expect(exact, run(exact: false));
      });
    }
  });

  group('Chart.js ADR 0099: the rows of differences.md', () {
    testWidgets('a read after an in-place change of a color list', (
      tester,
    ) async {
      final chart = acquireChart(_config('pie', dataset: _indexedColors));
      final twin = acquireChart(_eager('pie', dataset: _indexedColors));
      for (final each in [chart, twin]) {
        final colors = <Object?>[_red, _green];
        _dataset0(each)['backgroundColor'] = colors;
        each.update('none');
        colors[1] = _black;
      }
      // Upstream, and the twin: the snapshot of the last update.
      expect(jsGet(twin.legend!.legendItems![1], 'fillStyle'), _green);
      // A pending build: the entry of the list at the first read.
      expect(jsGet(chart.legend!.legendItems![1], 'fillStyle'), _black);
    });

    testWidgets('a read after an entry became an object', (tester) async {
      final chart = acquireChart(_config('pie', dataset: _indexedColors));
      final colors = <Object?>[_red, _green];
      _dataset0(chart)['backgroundColor'] = colors;
      chart.update('none');
      final built = _items(chart.legend!);
      colors[1] = _blue;
      chart.update('none');
      colors[1] = <String, Object?>{'a': 1};
      // The read cannot run the build: it gives the last built items, and the
      // build still waits.
      expect(_legendOf(chart).legendItemsPending, isTrue);
      expect(_items(chart.legend!), built);
      expect(_legendOf(chart).legendItemsPending, isTrue);
      colors[1] = _black;
      expect(jsGet(chart.legend!.legendItems![1], 'fillStyle'), _black);
      expect(_legendOf(chart).legendItemsPending, isFalse);
    });

    // The read cannot run the build when an index of a label reaches an entry
    // that is no native value of its key, a List has no entries, or item 0 of
    // the raw `borderDash` List is an object. No update ran after the edit.
    for (final (name, edit)
        in <
          (String, void Function(List<Object?>, List<Object?>, List<Object?>))
        >[
          (
            'a color List became empty',
            (colors, widths, dash) => colors.clear(),
          ),
          (
            'a color entry became an object',
            (colors, widths, dash) => colors[1] = <String, Object?>{'a': 1},
          ),
          (
            'a color entry became a function',
            (colors, widths, dash) => colors[1] = _keepItem,
          ),
          (
            'a width List became empty',
            (colors, widths, dash) => widths.clear(),
          ),
          (
            'a width entry became a String',
            (colors, widths, dash) => widths[1] = '3',
          ),
          (
            'a width entry became null',
            (colors, widths, dash) => widths[1] = null,
          ),
          (
            'a width entry became an object',
            (colors, widths, dash) => widths[1] = <String, Object?>{'a': 1},
          ),
          (
            'a width entry became a function',
            (colors, widths, dash) => widths[1] = _keepItem,
          ),
          (
            'item 0 of the dash List became an object',
            (colors, widths, dash) => dash[0] = <String, Object?>{'a': 1},
          ),
        ]) {
      testWidgets('a read after $name gives the last built items', (
        tester,
      ) async {
        (List<Object?>, bool) run({required bool exact}) {
          final chart = _chartOf(
            _config(
              'pie',
              dataset: {
                'backgroundColor': <Object?>[_red, _red, _red],
                'borderWidth': <Object?>[1.0, 1.0, 1.0],
                'borderDash': <Object?>[1.0, 1.0],
              },
            ),
            exact: exact,
          );
          final colors = <Object?>[_green, _blue, _green];
          final widths = <Object?>[2.0, 3.0, 4.0];
          final dash = <Object?>[2.0, 2.0];
          _dataset0(chart)
            ..['backgroundColor'] = colors
            ..['borderWidth'] = widths
            ..['borderDash'] = dash;
          chart.update('none');
          edit(colors, widths, dash);
          return (_fillAndWidth(chart), _legendOf(chart).legendItemsPending);
        }

        // The items of the last build, from before the last update. The build
        // still waits.
        final (items, pending) = run(exact: true);
        expect(items, const [
          [_red, 1.0],
          [_red, 1.0],
          [_red, 1.0],
        ]);
        expect(pending, isTrue);
        // Upstream, and the twin: the snapshot of the last update.
        final (twinItems, twinPending) = run(exact: false);
        expect(twinItems, const [
          [_green, 2.0],
          [_blue, 3.0],
          [_green, 4.0],
        ]);
        expect(twinPending, isFalse);
      });
    }

    testWidgets('a read gives the plan of the mark after a clear of the '
        'caches, as the snapshot does', (tester) async {
      final chart = acquireChart(_config('pie', dataset: _indexedColors));
      final twin = acquireChart(_eager('pie', dataset: _indexedColors));
      for (final each in [chart, twin]) {
        each.update('none');
        _dataset0(each)['backgroundColor'] = <Object?>[_black];
        each.config.clearCache();
      }
      expect(_items(chart.legend!), _items(twin.legend!));
      expect(jsGet(chart.legend!.legendItems![1], 'fillStyle'), _green);
    });

    testWidgets('a read with more labels than the mark', (tester) async {
      final chart = acquireChart(_config('pie', dataset: _indexedColors));
      final state = _state(chart);
      _labelsOf(chart).add('d');
      // No index of a new label has an arc: the index of the dataset context.
      final items = chart.legend!.legendItems!;
      expect(items, hasLength(4));
      expect(jsGet(items[3], 'fillStyle'), _red);
      expect(_state(chart), state);
    });

    testWidgets('a read with a new first dataset', (tester) async {
      final chart = acquireChart(_config('pie', dataset: _indexedColors));
      final built = _items(chart.legend!);
      chart.update('none');
      _datasetsOf(chart)[0] = <String, Object?>{
        'data': <Object?>[9.0, 9.0, 9.0],
        'backgroundColor': _black,
      };
      expect(_items(chart.legend!), built);
      expect(_legendOf(chart).legendItemsPending, isTrue);
      chart.update('none');
      expect(jsGet(chart.legend!.legendItems![0], 'fillStyle'), _black);
    });

    testWidgets('a direct build writes the contexts of a resolve', (
      tester,
    ) async {
      Object? mode(Chart chart) =>
          jsGet((chart.getDatasetMeta(0).data[1] as Element).$context, 'mode');
      final chart = acquireChart(_config('pie', dataset: _indexedColors))
        ..update('none')
        ..setActiveElements(<Object?>[
          <String, Object?>{'datasetIndex': 0, 'index': 1},
        ]);
      final twin = acquireChart(_eager('pie', dataset: _indexedColors))
        ..update('none')
        ..setActiveElements(<Object?>[
          <String, Object?>{'datasetIndex': 0, 'index': 1},
        ]);
      // The hover wrote the state of the mode `active` into the context.
      final hover = _contexts(chart);
      expect(hover, _contexts(twin));
      expect(mode(chart), 'active');
      // A read of the snapshot writes no context.
      expect(chart.legend!.legendItems, twin.legend!.legendItems);
      expect(_contexts(chart), hover);
      expect(_contexts(twin), hover);
      // A direct build is the upstream call: each resolve writes its context.
      _legendOf(chart).buildLabels();
      _legendOf(twin).buildLabels();
      expect(_contexts(chart), _contexts(twin));
      expect(mode(chart), 'default');
    });

    testWidgets('the stop hook settles the pending items', (tester) async {
      final chart = acquireChart(_config('pie', dataset: _indexedColors))
        ..update('none');
      final legend = _legendOf(chart);
      expect(legend.legendItemsPending, isTrue);
      (jsGet(chart.config.options, 'plugins')!
              as Map<String, Object?>)['legend'] =
          false;
      chart.update('none');
      // The box left the chart, with the items of the last state.
      expect(chart.legend, isNull);
      expect(legend.legendItemsPending, isFalse);
      expect(legend.legendItems, hasLength(3));
      expect(jsGet(legend.legendItems![1], 'fillStyle'), _green);
    });
  });

  group('Chart.js ADR 0099: the config of a live chart of the lab', () {
    for (final kind in const [
      typed.ChartKind.pie,
      typed.ChartKind.doughnut,
      typed.ChartKind.polarArea,
    ]) {
      for (final tooltips in const [false, true]) {
        testWidgets('$kind: ChartValue.indexed: tooltips $tooltips', (
          tester,
        ) async {
          const blue = Color(0xff4f6bed);
          const teal = Color(0xff14b8a6);
          const color = typed.ChartValue<Color>.indexed([blue, teal]);
          const radius = typed.ChartLength.percent(90);
          final labels = <String>[for (var i = 0; i < 200; i++) '$i'];

          Widget frame(int step, {required bool eager}) {
            final data = <double>[
              for (var i = 0; i < 200; i++) 1.0 + step + (i % 7),
            ];
            return Directionality(
              textDirection: TextDirection.ltr,
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 400,
                  height: 300,
                  child: typed.ChartView(
                    config: typed.ChartConfig(
                      type: kind,
                      labels: labels,
                      datasets: [
                        switch (kind) {
                          typed.ChartKind.polarArea => typed.PolarAreaDataset(
                            key: const ValueKey('series'),
                            label: 'Values',
                            data: data,
                            backgroundColor: color,
                            borderWidth: 0,
                          ),
                          typed.ChartKind.doughnut => typed.DoughnutDataset(
                            key: const ValueKey('series'),
                            label: 'Values',
                            data: data,
                            backgroundColor: color,
                            borderWidth: 0,
                            radius: radius,
                            cutout: const typed.ChartLength.percent(50),
                          ),
                          _ => typed.PieDataset(
                            key: const ValueKey('series'),
                            label: 'Values',
                            data: data,
                            backgroundColor: color,
                            borderWidth: 0,
                            radius: radius,
                          ),
                        },
                      ],
                      scales: kind == typed.ChartKind.polarArea
                          ? const {
                              'r': typed.RadialLinearAxis(
                                min: 0,
                                max: 100,
                                display: false,
                                pointLabelsDisplay: false,
                                angleLinesDisplay: false,
                              ),
                            }
                          : null,
                      animation: typed.ChartAnimation.none,
                      legend: typed.ChartLegend(
                        display: false,
                        extra: eager
                            ? const {
                                'labels': {'filter': _keepItem},
                              }
                            : null,
                      ),
                      tooltip: typed.ChartTooltip(enabled: tooltips),
                      responsive: true,
                      maintainAspectRatio: false,
                      extra: {
                        'events': tooltips
                            ? [
                                'mousemove',
                                'mouseout',
                                'click',
                                'touchstart',
                                'touchmove',
                              ]
                            : <String>[],
                      },
                    ),
                    updateMode: 'none',
                    theme: const typed.ChartThemeData(),
                    excludeFromSemantics: true,
                  ),
                ),
              ),
            );
          }

          Chart chartOf() => Chart.getChart(
            tester.renderObject<RenderChartHost>(find.byType(ChartHost)).canvas,
          )!;

          Future<(List<Object?>, List<Object?>, ByteData)> run({
            required bool eager,
          }) async {
            final states = <Object?>[];
            var pendingFrames = 0;
            await tester.pumpWidget(frame(0, eager: eager));
            final chart = chartOf();
            for (var step = 1; step < 5; step++) {
              await tester.pumpWidget(frame(step, eager: eager));
              if (_legendOf(chart).legendItemsPending) pendingFrames++;
              states.add(_state(chart));
            }
            expect(pendingFrames, eager ? 0 : 4);
            final context =
                (chart.getDatasetMeta(0).data[3] as ArcElement).$context!;
            expect(context.mode, 'default');
            expect(context.active, isFalse);
            expect(context.raw, 8);
            final pixels = await _pixels(tester, chart);
            final items = _items(chart.legend!);
            expect(items, hasLength(200));
            // The unmount of the chart. The next run starts a new one.
            await tester.pumpWidget(const SizedBox());
            return (states, items, pixels);
          }

          final (states, items, pixels) = await run(eager: false);
          final (twinStates, twinItems, twinPixels) = await run(eager: true);
          expect(states, twinStates);
          expect(items, twinItems);
          expect(pixels.buffer.asUint8List(), twinPixels.buffer.asUint8List());
        });
      }
    }
  });
}
