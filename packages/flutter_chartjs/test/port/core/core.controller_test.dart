// Original code, not ported from Chart.js: Chart cases with no spec.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart'
    show Directionality, SizedBox, TextDirection, TickerMode, Widget;
import 'package:flutter_chartjs/src/canvas/canvas.dart';
import 'package:flutter_chartjs/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs/src/core/core.animator.dart';
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/core/core.datasetController.dart';
import 'package:flutter_chartjs/src/core/core.defaults.dart' as core_defaults;
import 'package:flutter_chartjs/src/core/core.element.dart';
import 'package:flutter_chartjs/src/core/core.interaction.dart';
import 'package:flutter_chartjs/src/core/core.registry.dart';
import 'package:flutter_chartjs/src/core/core.scale.dart';
import 'package:flutter_chartjs/src/index.dart' show registerables;
import 'package:flutter_chartjs/src/js/js_array.dart';
import 'package:flutter_chartjs/src/js/js_class.dart';
import 'package:flutter_chartjs/src/js/js_function.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/platform/chart_host.dart';
import 'package:flutter_chartjs/src/platform/native_event.dart';
import 'package:flutter_chartjs/src/platform/platform.base.dart';
import 'package:flutter_chartjs/src/platform/platform.basic.dart';
import 'package:flutter_chartjs/src/platform/platform.flutter.dart';
import 'package:flutter_chartjs/src/types/basic.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import 'controller_reference.dart';
import 'registry_observe.dart';

// The Chart of src/core/core.controller.js with the scenarios of
// tool/reference/controller_reference.mjs: the construction, the hooks of an
// update and a render, a plugin that cancels a hook, the metasets, destroy,
// getChart, the visibility, the events and the active elements, the
// interaction modes, resize, the options and data aliases and the statics.
// The expected lines come from the pinned sources in Node.js v24.12.0 on
// x64.
//
// A chart of a scenario draws on a fake canvas with the mock context of the
// harness. No chart host shows the canvas. Thus the chart gets
// BasicPlatform, as in Node.js, which has no DOM. BasicPlatform disables the
// animations. The scenarios register the four element classes, the dataset
// controller `test` and the scale `testlinear` in main(), before the
// snapshot of the defaults restore (Chart.js ADR 0022, section 8).
//
// The other groups test the hunks of the port: the rows of differences.md
// (`adapt-component-class-role`, `adapt-chart-registry-getter`,
// `harness-method-fields`, `platform-destroy-cancel-resize`,
// `platform-to-base64-image`, `js-semantics-debounce-args` and the TickerMode
// mute of Chart.js ADR 0016, decision 7) and the forms of `Chart.register`
// (Chart.js ADR 0020, section 6).

// ---------------------------------------------------------------------------
// The fixtures of the scenarios.

/// The inline style of [_Canvas]: a Map of the properties.
final class _Style implements CSSStyleDeclaration {
  final Map<String, String> _properties = {};

  @override
  String getPropertyValue(String property) => _properties[property] ?? '';

  @override
  String getPropertyPriority(String property) => '';

  @override
  void setProperty(String property, String? value, [String? priority]) {
    if (value == null || value.isEmpty) {
      _properties.remove(property);
    } else {
      _properties[property] = value;
    }
  }
}

/// The mock context of the harness with a recorded `resetTransform`, as the
/// fake context of the generator.
final class _Context extends MockContext {
  @override
  late final HTMLCanvasElement canvas;

  @override
  void resetTransform() => record('resetTransform', const []);
}

/// The fake canvas of the generator: a canvas of [width] x [height] with a
/// mock context and no attributes.
final class _Canvas implements HTMLCanvasElement {
  _Canvas([this.width = 300, this.height = 150]) {
    context.canvas = this;
  }

  final _Context context = _Context();

  @override
  int width;

  @override
  int height;

  @override
  final _Style style = _Style();

  @override
  CanvasRenderingContext2D? getContext(String contextId) =>
      contextId == '2d' ? context : null;

  @override
  String? getAttribute(String name) => null;

  @override
  void setAttribute(String name, String value) {}

  @override
  void removeAttribute(String name) {}
}

/// The dataset controller `test` of the generator: it places each point at
/// its parsed x and y.
final class _TestController extends DatasetController {
  _TestController(super.chart, super.datasetIndex, [super.newTarget]);

  @override
  void update(String mode) {
    final meta = cachedMeta;
    updateElements(meta.data, 0, meta.data.length.toDouble(), mode);
  }

  @override
  void updateElements(
    List<types.Element> points,
    double start,
    double count,
    String mode,
  ) {
    final meta = cachedMeta;
    final iScale = meta.iScale!;
    final vScale = meta.vScale!;
    final (:sharedOptions, :includeOptions) = getSharedOptions_(start, mode);
    for (var i = start; i < start + count; ++i) {
      final point = points[i.toInt()] as Element;
      final parsed = getParsed(i);
      final properties = <String, Object?>{
        'x': iScale.getPixelForValue(jsToNumber(jsGet(parsed, 'x')), i),
        'y': vScale.getPixelForValue(jsToNumber(jsGet(parsed, 'y')), i),
      };
      if (includeOptions) {
        properties['options'] =
            sharedOptions ??
            resolveDataElementOptions(i, point.active ? 'active' : mode);
      }
      updateElement(point, i, properties, mode);
    }
  }
}

/// `class TestController extends DatasetController` of the generator.
final JsClass _testController = JsClass(
  'TestController',
  superclass: DatasetController.jsClass,
  statics: {
    'id': 'test',
    'defaults': <String, Object?>{
      'datasetElementType': false,
      'dataElementType': 'point',
    },
  },
  construct: (newTarget, args) {
    final (:chart, :datasetIndex) = controllerArgs(args);
    return _TestController(chart, datasetIndex, newTarget);
  },
);

/// The scale `testlinear` of the generator: the range 0 to 10, with the
/// ticks 0, 5 and 10.
final class _TestScale extends Scale {
  _TestScale(super.cfg);

  @override
  void determineDataLimits() {
    min = 0;
    max = 10;
  }

  @override
  List<Tick>? buildTicks() => [Tick(value: 0), Tick(value: 5), Tick(value: 10)];

  @override
  double getPixelForValue(double value, [double? index]) {
    return getPixelForDecimal((value - min) / (max - min));
  }
}

/// `class TestScale extends Scale` of the generator.
final JsClass _testScale = JsClass(
  'TestScale',
  superclass: Scale.jsClass,
  statics: {'id': 'testlinear', 'defaults': <String, Object?>{}},
  construct: (newTarget, args) => _TestScale(scaleCfgArg(args)),
);

/// The hooks that the spy plugin logs, in the order of the generator.
const List<String> _hooks = [
  'install',
  'start',
  'stop',
  'uninstall',
  'beforeInit',
  'afterInit',
  'resize',
  'reset',
  'beforeUpdate',
  'beforeElementsUpdate',
  'beforeLayout',
  'beforeDataLimits',
  'afterDataLimits',
  'beforeBuildTicks',
  'afterBuildTicks',
  'afterLayout',
  'beforeDatasetsUpdate',
  'beforeDatasetUpdate',
  'afterDatasetUpdate',
  'afterDatasetsUpdate',
  'afterUpdate',
  'beforeRender',
  'beforeDraw',
  'beforeDatasetsDraw',
  'beforeDatasetDraw',
  'afterDatasetDraw',
  'afterDatasetsDraw',
  'afterDraw',
  'afterRender',
  'beforeEvent',
  'afterEvent',
  'beforeDestroy',
  'afterDestroy',
];

/// The text of a value of a hook argument, as `argText` of the generator.
String _argText(Object? value, Observations o) {
  if (value == null) return 'null';
  if (value is Undefined) return 'undefined';
  if (jsIsFunction(value)) return '<fn>';
  if (value is String || value is num || value is bool) {
    return jsToString(value);
  }
  final label = o.labelOf(value);
  return label != null ? '<$label>' : '<obj>';
}

/// The text `hook(key=value,...)` of one hook call.
String _hookText(String hook, Object? args, Observations o) {
  final map = args! as AnyObject;
  final keys = jsObjectKeys(map);
  return '$hook(${keys.map((k) => '$k=${_argText(map[k], o)}').join(',')})';
}

/// The plugin `{id}` of the generator that logs each hook into [log].
/// [results] gives the result of a hook by name.
AnyObject _spy(
  String id,
  List<String> log,
  Observations o, [
  Map<String, Object?> results = const {},
]) {
  final plugin = <String, Object?>{'id': id};
  for (final hook in _hooks) {
    Object? logHook(Object? chart, Object? args, Object? options) {
      log.add(_hookText(hook, args, o));
      return results[hook];
    }

    plugin[hook] = logHook;
  }
  return plugin;
}

/// The config of a `test` chart with [datasets] on two `testlinear` scales.
AnyObject _testConfig(
  List<Object?> datasets, {
  List<Object?>? plugins,
  AnyObject? options,
}) {
  return <String, Object?>{
    'type': 'test',
    'data': <String, Object?>{'datasets': datasets},
    'plugins': ?plugins,
    'options': <String, Object?>{
      'scales': <String, Object?>{
        'x': <String, Object?>{'type': 'testlinear'},
        'y': <String, Object?>{'type': 'testlinear'},
      },
      ...?options,
    },
  };
}

/// The dataset `{label, data}` of three points.
AnyObject _points(String name, [double? order]) {
  return <String, Object?>{
    'label': name,
    'data': <Object?>[
      <String, Object?>{'x': 1, 'y': 2},
      <String, Object?>{'x': 5, 'y': 8},
      <String, Object?>{'x': 9, 'y': 4},
    ],
    'order': ?order,
  };
}

/// `String(value)` of a number.
String _n(num value) => jsNumberToString(value);

/// The text of a chart area or a box: `left,top,right,bottom`.
String _edges(Object? area) => switch (area) {
  null => 'undefined',
  final types.TRBL a =>
    '${_n(a.left)},${_n(a.top)},${_n(a.right)},${_n(a.bottom)}',
  final types.LayoutItem b =>
    '${_n(b.left)},${_n(b.top)},${_n(b.right)},${_n(b.bottom)}',
  _ => throw ArgumentError.value(area, 'area'),
};

/// The text of the metas of [list]: `index/order/label` for each.
String _metas(List<ChartMeta?> list) => list
    .map(
      (m) => m == null ? 'hole' : '${_n(m.index)}/${_n(m.order)}/${m.label}',
    )
    .join(' ');

/// The text of the active elements [items].
String _activeText(List<Object?> items, Observations o) => items
    .cast<types.ActiveElement>()
    .map((item) {
      final element = item.element;
      final name = o.labelOf(element) ?? (element == null ? 'undefined' : '?');
      return '${_n(item.datasetIndex)}:${_n(item.index)}:$name';
    })
    .join(' ');

/// Labels the data elements of the metas of [chart] `d<i>p<j>`.
void _labelElements(Chart chart, Observations o) {
  for (var i = 0; i < chart.metasets.length; i++) {
    final meta = chart.metasets[i];
    if (meta == null) continue;
    for (var j = 0; j < meta.data.length; j++) {
      o.label(meta.data[j], 'd${i}p$j');
    }
  }
}

/// The `active` flags of the data elements of the datasets 0 and 1.
String _activeFlags(Chart chart) => [0.0, 1.0]
    .map(
      (d) => chart
          .getDatasetMeta(d)
          .data
          .map((el) => '${(el as Element).active}')
          .join(','),
    )
    .join(' ');

/// The chart event `{type, native: {type}, x, y}` of the generator.
final class _Event implements types.ChartEvent {
  _Event(this.type, this.x, this.y)
    : native = NativeEvent(type: type, offsetX: x!, offsetY: y!);

  @override
  final String type;

  @override
  final NativeEvent native;

  @override
  final double? x;

  @override
  final double? y;

  @override
  types.Chart? get chart => null;
}

/// A point `{x, y}`.
final class _Point implements types.Point {
  const _Point(this.x, this.y);

  @override
  final double? x;

  @override
  final double? y;
}

/// Runs the scenario [name] of the reference: [body] observes, and the
/// charts of [body] are destroyed at the end, as in the generator.
void _scenario(
  String name,
  void Function(Observations o, List<Chart> charts) body,
) {
  test(name, () {
    final o = Observations();
    final charts = <Chart>[];
    try {
      body(o, charts);
    } finally {
      for (final chart in charts) {
        chart.destroy();
      }
    }
    expect(o.text, controllerReference[name]);
  });
}

// ---------------------------------------------------------------------------
// The fixtures of the groups of the port.

/// The chart of [config] on a canvas of `document.createElement`, in a
/// wrapper of 300 x 200 in the harness body. [replace] runs on the chart
/// before the append, which attaches the chart.
Chart _hostedChart(
  AnyObject config, {
  void Function(Chart chart)? replace,
}) {
  final canvas = document.createElement<HTMLCanvasElement>('canvas');
  final wrapper = document.createElement<HarnessElement>('div');
  final chart = Chart(canvas, config);
  replace?.call(chart);
  wrapper.style.cssText = 'width: 300px; height: 200px';
  wrapper.appendChild(canvas);
  document.body.appendChild(wrapper);
  addTearDown(() {
    chart.destroy();
    wrapper.remove();
  });
  return chart;
}

/// `class X {}` with the static `id`, as a plain class of a spec.
JsClass _plainClass(String name, String id, [AnyObject? defaults]) {
  final value = JsClass(name)..['id'] = id;
  if (defaults != null) value['defaults'] = defaults;
  return value;
}

void main() {
  Chart.register(registerables);
  Chart.register([_testController, _testScale]);

  test('the reference comes from Node.js v24.12.0 on x64', () {
    expect(controllerReferenceNode, 'v24.12.0');
    expect(controllerReferenceArch, 'x64');
  });

  group('the scenarios of the generator', () {
    _scenario('construction', (o, charts) {
      final log = <String>[];
      final canvas = _Canvas();
      final chart = Chart(
        canvas,
        _testConfig([_points('a')], plugins: [_spy('spy', log, o)]),
      );
      charts.add(chart);
      o
        ..label(chart, 'chart')
        ..observe('hooks', log.join(' '))
        ..observe('platform', chart.platform.runtimeType)
        ..observe('attached', chart.attached)
        ..observe('size', '${_n(chart.width)}x${_n(chart.height)}')
        ..observe('canvas', '${canvas.width}x${canvas.height}')
        ..observe(
          'style',
          '${canvas.style.getPropertyValue('width')} '
              '${canvas.style.getPropertyValue('height')}',
        )
        ..observe(
          'currentDevicePixelRatio',
          _n(chart.currentDevicePixelRatio),
        )
        ..observe('aspectRatio', _n(chart.aspectRatio!))
        ..observe('chartArea', _edges(chart.chartArea))
        ..observe(
          'boxes',
          chart.boxes
              .map((b) => '${(b as Scale).id}@${b.position}:${_edges(b)}')
              .join(' '),
        )
        ..observe('scales', jsObjectKeys(chart.scales).join(','));
      final meta = chart.getDatasetMeta(0);
      _labelElements(chart, o);
      o
        ..observe(
          'meta',
          '${meta.type} ${_n(meta.index)} ${_n(meta.order)} ${meta.label} '
              '${meta.visible} ${meta.indexAxis} ${meta.xAxisID} '
              '${meta.yAxisID}',
        )
        ..observe(
          'elements',
          meta.data.map((el) => '${_n(el.x)},${_n(el.y)}').join(' '),
        )
        ..observe('dataset element', '${meta.dataset}')
        ..observe(
          'context',
          '${chart.getContext()['type']} '
              '${identical(chart.getContext()['chart'], chart)}',
        )
        ..observe(
          'same context',
          identical(chart.getContext(), chart.getContext()),
        )
        ..observe(
          'instances',
          identical(Chart.instances[_n(chart.id)], chart),
        )
        ..observe('visible count', _n(chart.getVisibleDatasetCount()))
        ..observe(
          'draw calls',
          canvas.context.getCalls().map((c) => c['name']).join(','),
        );
    });

    _scenario('update modes', (o, charts) {
      final log = <String>[];
      final chart = Chart(
        _Canvas(),
        _testConfig(
          [_points('a'), _points('b')],
          plugins: [_spy('spy', log, o)],
        ),
      );
      charts.add(chart);
      log.clear();
      chart.update('none');
      o.observe('none', log.join(' '));
      log.clear();
      chart.update(
        (Object? ctx) => jsGet(ctx, 'datasetIndex') == 0 ? 'resize' : 'active',
      );
      o.observe(
        'function',
        log
            .where(
              (l) =>
                  l.startsWith('beforeDatasetUpdate') ||
                  l.startsWith('beforeUpdate') ||
                  l.startsWith('afterUpdate'),
            )
            .join(' '),
      );
      log.clear();
      chart.reset();
      o.observe('reset', log.join(' '));
      log.clear();
      chart.render();
      o.observe('render', log.join(' '));
    });

    _scenario('plugin cancel', (o, charts) {
      final log = <String>[];
      final chart = Chart(
        _Canvas(),
        _testConfig([_points('a')], plugins: [_spy('spy', log, o)]),
      );
      charts.add(chart);
      for (final hook in [
        'beforeUpdate',
        'beforeLayout',
        'beforeDatasetsUpdate',
        'beforeDatasetUpdate',
        'beforeRender',
        'beforeDraw',
        'beforeDatasetsDraw',
        'beforeDatasetDraw',
      ]) {
        // The plugin cancels the hook from the second update on, as in the
        // generator.
        final cancelLog = <String>[];
        final results = <String, Object?>{};
        final cancel = Chart(
          _Canvas(),
          _testConfig(
            [_points('a')],
            plugins: [_spy('spy', cancelLog, o, results)],
          ),
        );
        charts.add(cancel);
        results[hook] = false;
        cancelLog.clear();
        cancel.update();
        o.observe(hook, cancelLog.join(' '));
      }
      o.observe(
        'notify',
        chart.notifyPlugins('beforeUpdate', {'cancelable': true}),
      );
      final falseLog = <String>[];
      final falsy = Chart(
        _Canvas(),
        _testConfig(
          [],
          plugins: [
            _spy('spy', falseLog, o, {'beforeUpdate': false}),
          ],
        ),
      );
      charts.add(falsy);
      o
        ..observe(
          'notify false cancelable',
          falsy.notifyPlugins('beforeUpdate', {'cancelable': true}),
        )
        ..observe('notify false', falsy.notifyPlugins('beforeUpdate', {}))
        ..observe('notify no args', falsy.notifyPlugins('beforeUpdate'))
        ..observe('enabled spy', chart.isPluginEnabled('spy'))
        ..observe('enabled other', chart.isPluginEnabled('other'));
      final failed = Chart(<String, Object?>{}, <String, Object?>{});
      charts.add(failed);
      o
        ..observe(
          'failed notify',
          failed.notifyPlugins('beforeUpdate', {'cancelable': true}) ??
              'undefined',
        )
        ..observe(
          'failed isPluginEnabled',
          error(() => failed.isPluginEnabled('spy')),
        );
    });

    _scenario('metasets', (o, charts) {
      final chart = Chart(
        _Canvas(),
        _testConfig([
          _points('1', 2),
          _points('2', 1),
          _points('3', 4),
          _points('4', 3),
        ]),
      );
      charts.add(chart);
      List<Object?> datasets() => chart.data['datasets']! as List<Object?>;
      o
        ..observe('metasets', _metas(chart.metasets))
        ..observe('sorted', _metas(chart.sortedMetasets))
        ..observe('visible', _metas(chart.getSortedVisibleDatasetMetas()));
      final orig = List<Object?>.of(datasets());
      datasets().removeRange(0, 2);
      chart.update();
      o.observe('removed from beginning', _metas(chart.metasets));
      chart
        ..data = <String, Object?>{'datasets': List<Object?>.of(orig)}
        ..update();
      o.observe('restored', _metas(chart.metasets));
      datasets().removeRange(1, 3);
      chart.update();
      o.observe('removed from middle', _metas(chart.metasets));
      chart
        ..data = <String, Object?>{'datasets': List<Object?>.of(orig)}
        ..update();
      datasets().insert(1, _points('1.5', 5));
      chart.update();
      o.observe('inserted', _metas(chart.metasets));
      datasets()[1] = _points('r', 6);
      chart.update();
      o.observe('replaced', _metas(chart.metasets));
      chart
        ..data = <String, Object?>{
          'datasets': [orig[3], orig[2], orig[1], _points('new', 10)],
        }
        ..update();
      o
        ..observe('swapped', _metas(chart.metasets))
        ..observe('sorted swapped', _metas(chart.sortedMetasets));
      (datasets()[0]! as AnyObject)['type'] = 'test';
      (datasets()[1]! as AnyObject)['hidden'] = true;
      chart.update();
      o
        ..observe('hidden', _metas(chart.getSortedVisibleDatasetMetas()))
        ..observe(
          'meta 5',
          '${_n(chart.getDatasetMeta(5).index)} '
              '${identical(chart.getDatasetMeta(5), chart.getDatasetMeta(5))} '
              '${chart.metasets.length}',
        );
    });

    _scenario('destroy', (o, charts) {
      final log = <String>[];
      final canvas = _Canvas();
      final chart = Chart(
        canvas,
        _testConfig(
          [_points('1'), _points('2')],
          plugins: [_spy('spy', log, o)],
        ),
      );
      final id = _n(chart.id);
      log.clear();
      chart.destroy();
      o
        ..observe('hooks', log.join(' '))
        ..observe(
          'metasets',
          o.json([for (final m in chart.metasets) m ?? undefined]),
        )
        ..observe('canvas', '${chart.canvas} ${chart.ctx}')
        ..observe('instances', Chart.instances.containsKey(id))
        ..observe('getChart', Chart.getChart(canvas) ?? 'undefined')
        ..observe(
          'style',
          '${canvas.style.getPropertyValue('width')} '
              '${canvas.style.getPropertyValue('height')}',
        );
      log.clear();
      o
        ..observe('again', error(chart.destroy))
        ..observe('hooks again', log.join(' '));
      final second = Chart(canvas, _testConfig([]));
      o.observe('reuse', identical(second.canvas, canvas));
      second.destroy();
    });

    _scenario('getChart', (o, charts) {
      final canvas = _Canvas();
      final chart = Chart(canvas, _testConfig([]));
      charts.add(chart);
      o.label(chart, 'chart');
      final ctx = canvas.getContext('2d');
      String find(Object? key) => o.json(Chart.getChart(key) ?? undefined);
      String inUse(Object? item) => error(
        () => Chart(item, _testConfig([])),
      ).replaceFirst("'${_n(chart.id)}'", "'<id>'");
      o
        ..observe('canvas', find(canvas))
        ..observe('context', find(ctx))
        ..observe('chart', find(chart))
        ..observe('array', find([canvas]))
        ..observe('object', find(<String, Object?>{'canvas': canvas}))
        ..observe('number', find(1))
        ..observe('string', find('abc'))
        ..observe('null', find(null))
        ..observe('in use', inUse(canvas))
        ..observe('in use by context', inUse(ctx));
    });

    _scenario('visibility', (o, charts) {
      final chart = Chart(
        _Canvas(),
        _testConfig([
          _points('a'),
          {..._points('b'), 'hidden': true},
        ]),
      );
      charts.add(chart);
      String meta0() =>
          '${chart.isDatasetVisible(0)} ${chart.getDatasetMeta(0).visible} '
          '${chart.getDatasetMeta(0).hidden}';
      String elementHidden(int index) => jsToString(
        (chart.getDatasetMeta(0).data[index] as Element)['hidden'],
      );
      String visibilities(int count) => [
        for (var i = 0; i < count; i++) chart.getDataVisibility(i.toDouble()),
      ].join(' ');
      o.observe(
        'visible',
        '${chart.isDatasetVisible(0)} ${chart.isDatasetVisible(1)} '
            '${chart.isDatasetVisible(5)}',
      );
      chart.setDatasetVisibility(1, true);
      o.observe(
        'set visible',
        '${chart.isDatasetVisible(1)} ${chart.getDatasetMeta(1).hidden}',
      );
      chart.hide(0);
      o.observe('hide', meta0());
      chart.show(0);
      o.observe('show', meta0());
      chart.hide(0, 1);
      o.observe('hide element', '${elementHidden(1)} ${elementHidden(0)}');
      chart.show(0, 1);
      o
        ..observe('show element', elementHidden(1))
        ..observe('hide missing element', error(() => chart.hide(0, 7)));
      chart
        ..toggleDataVisibility(1)
        ..toggleDataVisibility(2)
        ..toggleDataVisibility(2);
      o.observe('data visibility', visibilities(4));
      chart
        ..toggleDataVisibility(3)
        ..dataChanges.addAll([
          [0.0, '_insertElements', 0.0, 1.0],
          [1.0, '_insertElements', 0.0, 1.0],
        ])
        ..update();
      o.observe('after insert', visibilities(5));
      chart
        ..dataChanges.addAll([
          [0.0, '_removeElements', 1.0, 1.0],
          [1.0, '_removeElements', 1.0, 1.0],
        ])
        ..update();
      o.observe('after remove', visibilities(5));
      chart
        ..dataChanges.addAll([
          [0.0, '_insertElements', 0.0, 1.0],
          [1.0, '_removeElements', 0.0, 1.0],
        ])
        ..update();
      o
        ..observe('not uniform', visibilities(5))
        ..observe('changes cleared', chart.dataChanges.length);
    });

    _scenario('events', (o, charts) {
      final log = <String>[];
      final hover = <String>[];
      final options = <String, Object?>{
        'onHover': JsFunction(
          (Object? self, Object? e, Object? active, Object? chart) {
            hover.add(
              'hover ${(e! as types.ChartEvent).type} '
              '${_activeText(active! as List<Object?>, o)} '
              '${identical(self, chart)}',
            );
          },
        ),
        'onClick': (Object? e, Object? active) {
          hover.add(
            'click ${(e! as types.ChartEvent).type} '
            '${_activeText(active! as List<Object?>, o)}',
          );
        },
        // The plugin `clicks` gets the click events only.
        'plugins': <String, Object?>{
          'clicks': <String, Object?>{
            'events': ['click'],
          },
        },
      };
      final chart = Chart(
        _Canvas(),
        _testConfig(
          [_points('a'), _points('b')],
          plugins: [
            _spy('spy', log, o),
            <String, Object?>{
              'id': 'clicks',
              'beforeEvent': (Object? c, Object? args) {
                log.add(
                  'clicks ${(jsGet(args, 'event')! as types.ChartEvent).type}',
                );
              },
            },
          ],
          options: options,
        ),
      );
      charts.add(chart);
      _labelElements(chart, o);
      final p1 = chart.getDatasetMeta(0).data[1];
      void run(String name, types.ChartEvent e) {
        log.clear();
        hover.clear();
        chart.eventHandler(e);
        o.observe(
          name,
          '${log.join(' ')} | ${hover.join(' ')} | '
          '${_activeText(chart.getActiveElements(), o)} | '
          '${_activeFlags(chart)}',
        );
      }

      final area = chart.chartArea!;
      run('move on point', _Event('mousemove', p1.x, p1.y));
      run('move same', _Event('mousemove', p1.x, p1.y));
      run('move outside area', _Event('mousemove', -50, -50));
      run('move away', _Event('mousemove', area.left + 1, area.top + 1));
      run('click on point', _Event('click', p1.x, p1.y));
      run('move back', _Event('mousemove', p1.x, p1.y));
      log.clear();
      chart.update();
      o.observe('replay', log.where((l) => l.contains('Event')).join(' '));
      run('mouseout', _Event('mouseout', p1.x, p1.y));
      log.clear();
      chart.setActiveElements([
        <String, Object?>{'datasetIndex': 1, 'index': 2},
      ]);
      o.observe(
        'set active',
        '${_activeText(chart.getActiveElements(), o)} | '
            '${_activeFlags(chart)}',
      );
      chart.update();
      // An index without an element: setActiveElements keeps the item, and
      // the hover style of `undefined` throws.
      o
        ..observe(
          'update keeps active',
          '${_activeText(chart.getActiveElements(), o)} | '
              '${log.where((l) => l.contains('Event')).join(' ')}',
        )
        ..observe(
          'set missing',
          error(
            () => chart.setActiveElements([
              <String, Object?>{'datasetIndex': 0, 'index': 7},
            ]),
          ),
        )
        ..observe('missing active', _activeText(chart.getActiveElements(), o))
        ..observe('set missing update', error(chart.update));
      chart
        ..active = []
        ..setActiveElements([]);
      o.observe('cleared', _activeText(chart.getActiveElements(), o));
      (chart.options['hover']! as AnyObject)['mode'] = 'dataset';
      run('dataset mode', _Event('mousemove', p1.x, p1.y));
    });

    _scenario('interaction modes', (o, charts) {
      final chart = Chart(
        _Canvas(),
        _testConfig([_points('a'), _points('b')]),
      );
      charts.add(chart);
      _labelElements(chart, o);
      final p1 = chart.getDatasetMeta(0).data[1];
      String items(List<InteractionItem> list) => list
          .map(
            (i) =>
                '${_n(i.datasetIndex)}:${_n(i.index)}:'
                '${o.labelOf(i.element)}',
          )
          .join(' ');
      for (final mode in [
        'point',
        'nearest',
        'index',
        'dataset',
        'x',
        'y',
        'nope',
      ]) {
        for (final intersect in [true, false]) {
          final e = _Event('mousemove', p1.x + 2, p1.y + 2);
          o.observe(
            '$mode $intersect',
            items(
              chart.getElementsAtEventForMode(e, mode, <String, Object?>{
                'intersect': intersect,
              }, false),
            ),
          );
        }
      }
      o
        ..observe(
          'axis xy',
          items(
            chart.getElementsAtEventForMode(
              _Event('mousemove', p1.x + 30, p1.y),
              'nearest',
              <String, Object?>{'intersect': false, 'axis': 'xy'},
              false,
            ),
          ),
        )
        ..observe(
          'axis y',
          items(
            chart.getElementsAtEventForMode(
              _Event('mousemove', p1.x + 30, p1.y),
              'nearest',
              <String, Object?>{'intersect': false, 'axis': 'y'},
              false,
            ),
          ),
        )
        ..observe(
          'in area',
          '${chart.isPointInArea(_Point(p1.x, p1.y))} '
              '${chart.isPointInArea(const _Point(-1, -1))}',
        );
    });

    _scenario('resize', (o, charts) {
      final log = <String>[];
      final sizes = <String>[];
      final canvas = _Canvas(400, 200);
      final chart = Chart(
        canvas,
        _testConfig(
          [_points('a')],
          plugins: [_spy('spy', log, o)],
          options: <String, Object?>{
            'onResize': JsFunction((Object? self, Object? c, Object? size) {
              final (:width, :height) =
                  size! as ({double width, double height});
              sizes.add('${_n(width)}x${_n(height)} ${identical(self, c)}');
            }),
          },
        ),
      );
      charts.add(chart);
      String sizeOf() =>
          '${_n(chart.width)}x${_n(chart.height)} '
          '${canvas.width}x${canvas.height}';
      String styleOf() =>
          '${canvas.style.getPropertyValue('width')} '
          '${canvas.style.getPropertyValue('height')}';
      o.observe('initial', '${sizeOf()} ${sizes.join(' ')}');
      log.clear();
      sizes.clear();
      chart.resize(200, 100);
      o.observe(
        'resize 200x100',
        '${sizeOf()} ${styleOf()} ${sizes.join(' ')} | ${log.join(' ')}',
      );
      log.clear();
      sizes.clear();
      chart.resize(200, 100);
      o.observe('same size', '${sizes.join(' ')} | ${log.join(' ')}');
      chart.options['maintainAspectRatio'] = false;
      chart.resize(250.4, 125.6);
      o.observe('fraction', '${sizeOf()} ${styleOf()}');
      chart.options['devicePixelRatio'] = 2;
      chart.resize(100, 50);
      o.observe(
        'ratio 2',
        '${sizeOf()} ${_n(chart.currentDevicePixelRatio)}',
      );
      chart
        ..options['aspectRatio'] = 4
        ..options['maintainAspectRatio'] = true
        ..resize(200);
      o.observe(
        'aspect ratio',
        '${_n(chart.width)}x${_n(chart.height)} ${_n(chart.aspectRatio!)}',
      );
    });

    _scenario('options and data', (o, charts) {
      final config = _testConfig([_points('a')]);
      final chart = Chart(_Canvas(), config);
      charts.add(chart);
      o.observe('data alias', identical(chart.data, config['data']));
      final data = <String, Object?>{
        'datasets': [_points('b')],
      };
      chart.data = data;
      o.observe(
        'set data',
        '${identical(chart.data, data)} ${identical(config['data'], data)} '
            '${o.json(jsObjectKeys(chart.data))}',
      );
      chart.data = null;
      o.observe('set null', o.json(chart.data));
      chart.data = <String, Object?>{
        'datasets': [_points('c')],
      };
      final before = chart.options;
      // A new options object has the animations of the defaults:
      // BasicPlatform disabled them in the options of the constructor only.
      chart.options = <String, Object?>{
        'animation': false,
        'scales': <String, Object?>{
          'y': <String, Object?>{'type': 'testlinear', 'position': 'bottom'},
          'x2': <String, Object?>{'type': 'testlinear', 'axis': 'x'},
        },
        'layout': <String, Object?>{'padding': 10},
      };
      o.observe(
        'options before update',
        '${identical(chart.options, before)} '
            '${o.json(jsGet(chart.options['layout'], 'padding'))}',
      );
      chart.update();
      o
        ..observe(
          'options after update',
          '${identical(chart.options, before)} '
              '${o.json(jsGet(chart.options['layout'], 'padding'))}',
        )
        ..observe(
          'scale ids',
          jsObjectKeys(chart.scales)
              .map(
                (id) =>
                    '$id:${chart.scales[id]!.options['id']}:'
                    '${chart.scales[id]!.position}',
              )
              .join(' '),
        )
        ..observe(
          'boxes',
          chart.boxes.map((b) => (b as Scale).id).join(','),
        )
        ..observe('chartArea', _edges(chart.chartArea))
        ..observe(
          'scale type error',
          error(() {
            chart
              ..options = <String, Object?>{
                'animation': false,
                'scales': <String, Object?>{
                  'x': <String, Object?>{'type': 'nope'},
                },
              }
              ..update();
          }),
        )
        ..observe(
          'controller type error',
          error(
            () => Chart(_Canvas(), <String, Object?>{
              'type': 'nope',
              'data': <String, Object?>{
                'datasets': [<String, Object?>{}],
              },
            }),
          ),
        );
    });

    _scenario('statics', (o, charts) {
      o
        ..observe('version', Chart.version)
        ..observe(
          'register forms',
          error(
            () => Chart.register([
              [
                [
                  <String, Object?>{'id': 'x'},
                ],
              ],
            ]),
          ),
        );
      final log = <String>[];
      final chart = Chart(_Canvas(), _testConfig([]));
      charts.add(chart);
      chart.notifyPlugins('afterRender');
      final plugin = _spy('late', log, o);
      Chart.register([plugin]);
      o.observe('cache after register', chart.plugins.cache ?? 'undefined');
      chart.notifyPlugins('afterDraw');
      o.observe('late plugin', log.join(' '));
      Chart.unregister([plugin]);
      log.clear();
      chart.notifyPlugins('afterDraw');
      o
        ..observe('after unregister', log.join(' '))
        ..observe(
          'getElementsAtEventForMode modes',
          jsObjectKeys(Interaction.modes).join(','),
        )
        ..observe('BasicPlatform', chart.platform is BasicPlatform);
      final own = Chart(_Canvas(), <String, Object?>{
        'platform': BasicPlatform.jsClass,
        'type': 'test',
      });
      charts.add(own);
      o.observe('config platform', own.platform.runtimeType);
    });
  });

  group('the meta read by name', () {
    test('_clip reads undefined before the first write, then the clip', () {
      // core.datasetController.js:704 writes `meta._clip`. The literal of
      // `_getMetaForDataset` has no `_clip` (core.controller.js:836-853).
      final chart = Chart(5, <String, Object?>{});
      addTearDown(chart.destroy);
      final meta = chart.getDatasetMeta(0);
      expect(meta['_clip'], same(undefined));
      expect(() => meta.clip, throwsA(isA<TypeError>()));
      final clip = _TestClip();
      meta['_clip'] = clip;
      expect(meta['_clip'], same(clip));
      expect(meta.clip, same(clip));
    });
  });

  group('construction', () {
    test('a canvas without a chart host gives BasicPlatform', () {
      final chart = Chart(UiCanvasElement(), <String, Object?>{});
      addTearDown(chart.destroy);
      expect(chart.platform, isA<BasicPlatform>());
      expect(chart.attached, isTrue);
      expect(chart.chartArea, isNotNull);
    });

    test('an item without a context gives a chart without a canvas', () {
      final chart = Chart(5, <String, Object?>{});
      addTearDown(chart.destroy);
      expect(chart.canvas, isNull);
      expect(chart.ctx, isNull);
      expect(chart.width, 0);
      expect(chart.height, 0);
      expect(chart.attached, isFalse);
      expect(chart.chartArea, isNull);
      expect(Chart.instances[_n(chart.id)], same(chart));
      // getCanvas(null) is null, and the chart has the canvas null
      // (core.controller.js:67-70).
      expect(Chart.getChart(null), same(chart));
    });

    test('the ids grow, and getContext is a new context after :172', () {
      final first = Chart(_Canvas(), <String, Object?>{});
      final second = Chart(_Canvas(), <String, Object?>{});
      addTearDown(first.destroy);
      addTearDown(second.destroy);
      expect(second.id, first.id + 1);
      final context = first.getContext();
      expect(context['chart'], same(first));
      expect(context['type'], 'chart');
      expect(first.getContext(), same(context));
    });

    test('a platform class value of another role throws a TypeError', () {
      // `new (config.platform)()` of a plain class gives a plain object, and
      // upstream throws a TypeError at `this.platform.updateConfig`, the
      // next line. The port throws it at the cast.
      expect(
        () => Chart(_Canvas(), <String, Object?>{
          'platform': JsClass('PlainPlatform'),
        }),
        throwsA(isA<TypeError>()),
      );
      // A Dart function is not a class value: `new` throws a TypeError.
      expect(
        () => Chart(_Canvas(), <String, Object?>{
          'platform': BasicPlatform.new,
        }),
        throwsA(isA<TypeError>()),
      );
    });

    test('a subclass of a platform class value constructs its superclass', () {
      final sub = JsClass('SubPlatform', superclass: BasicPlatform.jsClass);
      final chart = Chart(_Canvas(), <String, Object?>{'platform': sub});
      addTearDown(chart.destroy);
      expect(chart.platform, isA<BasicPlatform>());
      expect(BasicPlatform.jsClass.isSubclassOf(BasePlatform.jsClass), isTrue);
    });
  });

  group('statics and the forms of Chart.register', () {
    test('the statics are the objects of the modules', () {
      expect(Chart.defaults, same(core_defaults.defaults));
      expect(Chart.overrides, same(core_defaults.overrides));
      expect(Chart.version, '4.5.1');
    });

    test('a List of items registers each item in its order', () {
      final a = <String, Object?>{'id': 'formA'};
      final b = <String, Object?>{'id': 'formB'};
      final c = <String, Object?>{'id': 'formC'};
      final d = <String, Object?>{'id': 'formD'};
      final e = <String, Object?>{'id': 'formE'};
      Chart.register([a]);
      Chart.register([b, c]);
      Chart.register([
        [d],
      ]);
      Chart.register([
        <String, Object?>{'E': e},
      ]);
      addTearDown(
        () => Chart.unregister([
          [a, b, c, d, e],
        ]),
      );
      final ids = jsObjectKeys(Chart.registry.plugins.items);
      expect(
        ids.where((id) => id.startsWith('form')),
        ['formA', 'formB', 'formC', 'formD', 'formE'],
      );
    });

    test('a nested List and Dart null throw', () {
      expect(
        () => Chart.register([
          [
            [
              <String, Object?>{'id': 'nested'},
            ],
          ],
        ]),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'class does not have id: [object Object]',
          ),
        ),
      );
      expect(() => Chart.register([null]), throwsA(isA<TypeError>()));
    });

    test('a register invalidates the plugins of each chart', () {
      final chart = Chart(_Canvas(), <String, Object?>{});
      addTearDown(chart.destroy);
      chart.notifyPlugins('afterRender');
      expect(chart.plugins.cache, isNotNull);
      final plugin = <String, Object?>{'id': 'invalidates'};
      Chart.register([plugin]);
      addTearDown(() => Chart.unregister([plugin]));
      expect(chart.plugins.cache, isNull);
    });
  });

  group('adapt-chart-registry-getter', () {
    test('Chart.registry is the singleton registry', () {
      expect(Chart.registry, same(registry));
    });
  });

  group('adapt-component-class-role', () {
    test('a plain controller class throws a TypeError in update()', () {
      // Upstream constructs the plain class and keeps it in meta.controller.
      // It notifies beforeElementsUpdate and throws a TypeError at
      // `controller.buildOrUpdateElements` (core.controller.js:497-506). The
      // port throws the TypeError at the cast.
      final plain = _plainClass('plain', 'plainController', {
        'dataElementType': 'point',
      });
      Chart.registry.addControllers([plain]);
      addTearDown(() => Chart.registry.removeControllers([plain]));
      final log = <String>[];
      final chart = Chart(
        _Canvas(),
        _testConfig([], plugins: [_spy('spy', log, Observations())]),
      );
      addTearDown(chart.destroy);
      (chart.data['datasets']! as List<Object?>).add(<String, Object?>{
        'type': 'plainController',
        'data': <Object?>[],
      });
      log.clear();
      expect(chart.update, throwsA(isA<TypeError>()));
      expect(log, isNot(contains('beforeElementsUpdate()')));
      expect(chart.getDatasetMeta(0).controller, isNull);
    });

    test('a plain scale class throws a TypeError in update()', () {
      // Upstream writes `scales[scale.id]` before the TypeError of
      // `scale.init` (core.controller.js:364-367). The port has no entry.
      final plain = _plainClass('plainScale', 'plainScale');
      Chart.registry.addScales([plain]);
      addTearDown(() => Chart.registry.removeScales([plain]));
      final chart = Chart(_Canvas(), <String, Object?>{});
      addTearDown(chart.destroy);
      chart.options = <String, Object?>{
        'animation': false,
        'scales': <String, Object?>{
          'x': <String, Object?>{'type': 'plainScale'},
        },
      };
      expect(chart.update, throwsA(isA<TypeError>()));
      expect(chart.scales, isEmpty);
    });
  });

  group('platform-to-base64-image', () {
    test('toBase64Image throws an UnsupportedError', () {
      final chart = Chart(_Canvas(), <String, Object?>{});
      addTearDown(chart.destroy);
      expect(chart.toBase64Image, throwsA(isA<UnsupportedError>()));
    });
  });

  group('harness-method-fields', () {
    test('_initialize and the attach listener call the resize field', () {
      final chart = _ResizeSpyChart(_Canvas(), <String, Object?>{});
      addTearDown(chart.destroy);
      // core.controller.js:241, then :1026 in `attached()`.
      expect(chart.calls, ['resize(null, null)', 'resize(null, null)']);
      chart.resize(200, 100);
      expect(chart.calls.last, 'resize(200.0, 100.0)');
      expect(chart.width, 200);
    });

    testWidgets('a replacement sees the calls of the resize listener and '
        'the restore gives the method again', (tester) async {
      final calls = <String>[];
      late void Function([double? width, double? height]) original;
      final chart = _hostedChart(
        <String, Object?>{
          'options': <String, Object?>{'maintainAspectRatio': false},
        },
        replace: (chart) {
          original = chart.resize;
          chart.resize = ([width, height]) {
            calls.add('resize($width, $height)');
            original(width, height);
          };
        },
      );
      // The attach at the mutation checkpoint (core.controller.js:1026),
      // then the first notification of the resize observer at the next
      // layout (:1017).
      await pumpFrames(() => calls.length >= 2);
      expect(calls, ['resize(null, null)', 'resize(300.0, 200.0)']);
      expect(chart.width, 300);

      chart.canvas!.parentElement!.style.width = '400px';
      await pumpFrames(() => calls.length >= 3);
      expect(calls.last, 'resize(400.0, 200.0)');

      chart.resize = original;
      chart.resize(250, 150);
      expect(calls, hasLength(3));
      expect(chart.width, 250);
    });

    testWidgets('a replacement of eventHandler sees the events of the '
        'platform and the replay of update', (tester) async {
      final calls = <String>[];
      final chart = _hostedChart(<String, Object?>{});
      await pumpFrames(() => chart.attached);
      final original = chart.eventHandler;
      chart.eventHandler = (e, [replay]) {
        calls.add('${e.type} $replay');
        original(e, replay);
      };
      // The listener of the platform (core.controller.js:988), after the
      // throttle of one frame.
      dispatchCanvasEvent(
        chart.canvas!,
        NativeEvent(
          type: 'mousemove',
          offsetX: 20,
          offsetY: 20,
          target: chart.canvas,
        ),
      );
      await pumpFrames(() => calls.isNotEmpty);
      expect(calls, ['mousemove null']);
      // The replay of the last event in update (core.controller.js:531).
      chart.update();
      expect(calls, ['mousemove null', 'mousemove true']);
      chart
        ..eventHandler = original
        ..update();
      expect(calls, hasLength(2));
    });
  });

  group('platform-destroy-cancel-resize', () {
    testWidgets('destroy cancels the delayed update of a resize', (
      tester,
    ) async {
      final log = <String>[];
      final chart = Chart(
        _Canvas(),
        <String, Object?>{
          'plugins': [_spy('spy', log, Observations())],
          'options': <String, Object?>{'resizeDelay': 50},
        },
      );
      log.clear();
      chart.resize(200, 100);
      expect(log, isNot(contains(startsWith('beforeUpdate'))));
      chart.destroy();
      log.clear();
      await tester.pump(const Duration(milliseconds: 60));
      expect(log, isEmpty);
    });
  });

  group('js-semantics-debounce-args', () {
    testWidgets('a delayed resize updates with the mode resize', (
      tester,
    ) async {
      final log = <String>[];
      final chart = Chart(
        _Canvas(),
        <String, Object?>{
          'plugins': [_spy('spy', log, Observations())],
          'options': <String, Object?>{'resizeDelay': 50},
        },
      );
      addTearDown(chart.destroy);
      log.clear();
      chart.resize(200, 100);
      // The delayed branch draws without an update (core.controller.js:299).
      expect(log, contains('beforeRender(cancelable=true)'));
      expect(log, isNot(contains(startsWith('beforeUpdate'))));
      log.clear();
      await tester.pump(const Duration(milliseconds: 60));
      expect(log, contains('beforeUpdate(mode=resize,cancelable=true)'));
      expect(log, contains('afterUpdate(mode=resize)'));
    });
  });

  group('platform-animator-mute', () {
    testWidgets('a looping chart under TickerMode(enabled: false) schedules '
        'no frame, and it continues when TickerMode turns on', (
      tester,
    ) async {
      // The owner of the chart connects the ticker state of its host to the
      // animator (Chart.js ADR 0016, decision 7): it mutes the chart that it
      // creates under TickerMode(enabled: false).
      final canvas = UiCanvasElement();
      late Chart chart;
      // The callback of ChartHost.onTickerModeChanged.
      // ignore: avoid_positional_boolean_parameters
      void onTickerModeChanged(bool enabled) =>
          enabled ? animator.unmute(chart) : animator.mute(chart);
      Widget host({required bool enabled}) => Directionality(
        textDirection: TextDirection.ltr,
        child: TickerMode(
          enabled: enabled,
          child: SizedBox(
            width: 300,
            height: 200,
            child: ChartHost(
              canvas: canvas,
              onTickerModeChanged: onTickerModeChanged,
            ),
          ),
        ),
      );
      await tester.pumpWidget(host(enabled: false));
      var draws = 0;
      chart = Chart(
        canvas,
        _testConfig(
          [_points('a')],
          plugins: [
            <String, Object?>{
              'id': 'draws',
              'afterDraw': (Object? c, Object? args) => draws++,
            },
          ],
          options: <String, Object?>{
            'animation': <String, Object?>{'duration': 100, 'loop': true},
          },
        ),
      );
      expect(chart.platform, isA<FlutterPlatform>());
      final renderHost = canvas.parentNode! as RenderChartHost;
      if (!renderHost.tickerEnabled) animator.mute(chart);
      // The test controller places a point at the same pixel in the reset
      // and in the update. A new value gives a looping animation of y.
      final dataset =
          (chart.data['datasets']! as List<Object?>)[0]! as AnyObject;
      ((dataset['data']! as List<Object?>)[0]! as AnyObject)['y'] = 9;
      chart.update();
      expect(animator.running(chart), isTrue);

      // The frame that the start scheduled skips the muted chart. Then the
      // loop ends. The first frames also give the first notification of the
      // resize observer and the paint of the host.
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      final mutedDraws = draws;
      expect(SchedulerBinding.instance.hasScheduledFrame, isFalse);
      await tester.pump(const Duration(milliseconds: 16));
      expect(draws, mutedDraws);

      await tester.pumpWidget(host(enabled: true));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(draws, greaterThan(mutedDraws + 3));
      expect(SchedulerBinding.instance.hasScheduledFrame, isTrue);

      chart.destroy();
      await tester.pump(const Duration(milliseconds: 16));
      expect(SchedulerBinding.instance.hasScheduledFrame, isFalse);
    });
  });

  group('adapt-config-objects', () {
    // core.controller.tests.js:581-599 gives `data: []`. Upstream writes
    // `datasets` and `labels` into the array. The port gives a new Map.
    test('a data array gives a new data Map at the construction', () {
      final array = <Object?>[];
      final chart = Chart(_Canvas(), <String, Object?>{
        'type': 'line',
        'data': array,
      });
      expect(chart.data, isNot(same(array)));
      expect(chart.data['datasets'], isEmpty);
      expect(chart.data['labels'], isEmpty);
      chart.destroy();
    });

    testWidgets('with a data Map, update gives the options of the '
        'construction (core.controller.tests.js:581)', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{},
        'options': <String, Object?>{
          'animation': false,
          'locale': 'en-US',
          'responsive': false,
        },
      });
      final options = chart.options;
      chart
        ..options = <String, Object?>{
          'animation': false,
          'locale': 'en-US',
          'responsive': false,
        }
        ..update();
      expect(chart.options, isNot(same(options)));
      expect(chart.options, toEqualOptions(options));
    });
  });

  group('platform-canvas-no-shadow', () {
    // platform.dom.tests.js:299-329 "should reset context to default values"
    // reads 13 attributes of the context after destroy(). The canvas layer
    // has no shadow attributes (Chart.js ADR 0013, section 1). Thus the spec
    // case skips. This test runs the case with the other 9 attributes. The
    // chart starts detached and draws nothing before destroy(). Thus the
    // test first gives each attribute a value that is not the default.
    testWidgets('destroy() resets the 9 attributes of the context', (
      tester,
    ) async {
      final wrapper = document.createElement<HarnessElement>('div');
      final canvas = document.createElement<HTMLCanvasElement>('canvas');
      wrapper.appendChild(canvas);
      document.body.appendChild(wrapper);
      final chart = Chart(canvas, <String, Object?>{});
      final context = chart.ctx!
        ..fillStyle = '#ff0000'
        ..font = 'bold 12px Arial'
        ..lineJoin = 'round'
        ..lineCap = 'square'
        ..lineWidth = 3
        ..miterLimit = 4
        ..strokeStyle = '#00ff00'
        ..textAlign = 'center'
        ..textBaseline = 'top';

      chart.destroy();

      // https://www.w3.org/TR/2dcontext/#conformance-requirements
      expect(context.fillStyle, '#000000');
      expect(context.font, '10px sans-serif');
      expect(context.lineJoin, 'miter');
      expect(context.lineCap, 'butt');
      expect(context.lineWidth, 1);
      expect(context.miterLimit, 10);
      expect(context.strokeStyle, '#000000');
      expect(context.textAlign, 'start');
      expect(context.textBaseline, 'alphabetic');

      // The context has none of the 4 shadow attributes of the spec. A
      // change here makes the spec case pass: remove its skip and the row.
      final dynamic object = context;
      // A dynamic read of shadowBlur, which the context does not declare.
      // ignore: avoid_dynamic_calls
      expect(() => object.shadowBlur, throwsNoSuchMethodError);
      // The same read of shadowColor.
      // ignore: avoid_dynamic_calls
      expect(() => object.shadowColor, throwsNoSuchMethodError);
      // The same read of shadowOffsetX.
      // ignore: avoid_dynamic_calls
      expect(() => object.shadowOffsetX, throwsNoSuchMethodError);
      // The same read of shadowOffsetY.
      // ignore: avoid_dynamic_calls
      expect(() => object.shadowOffsetY, throwsNoSuchMethodError);

      wrapper.parentNode!.removeChild(wrapper);
    });
  });

  group('the platform.dom spec cases', () {
    // platform.dom.tests.js:274-297 "should fit parent using aspect ratio to
    // calculate size" has no `done`. Upstream, the global afterEach destroys
    // the chart before its first resize. Thus the callback of waitForResize
    // never runs. The spec port keeps this form. This test waits for the
    // callback, and also reads the size after the construction.
    //
    // The construction calls resize() without a size: getMaximumSize gives
    // the container width 300 and the height 300 / (150 / 245) = 490
    // (helpers.dom.ts:182-185). The first notification of the resize
    // observer gives the container size: the height is then 350, and the
    // width is floor(350 * 150 / 245) = 214 (helpers.dom.ts:192-197). The
    // x64 Node.js v24.12.0 gives the same values for these lines.
    testWidgets('a chart that fits its parent gets the container height at '
        'the first resize', (tester) async {
      await waitForDone((done) {
        final chart = acquireChart(
          <String, Object?>{
            'options': <String, Object?>{
              'responsive': true,
              'maintainAspectRatio': true,
            },
          },
          <String, Object?>{
            'canvas': <String, Object?>{'style': 'width: 150px; height: 245px'},
            'wrapper': <String, Object?>{
              'style': 'width: 300px; height: 350px',
            },
          },
        );

        expect(
          chart,
          toBeChartOfSize({'dw': 300, 'dh': 490, 'rw': 300, 'rh': 490}),
        );

        waitForResize(chart, () {
          expect(
            chart,
            toBeChartOfSize({'dw': 214, 'dh': 350, 'rw': 214, 'rh': 350}),
          );
          done();
        });
      });
    });
  });
}

/// A chart whose `resize` field records each call, from the construction on
/// (core.controller.js:241, `harness-method-fields`).
final class _ResizeSpyChart extends Chart {
  _ResizeSpyChart(super.item, [super.userConfig]);

  final List<String> calls = [];

  @override
  // The test overrides the field of the function, as a test of upstream
  // replaces the own property `resize`.
  // ignore: overridden_fields
  late void Function([double? width, double? height]) resize = ([w, h]) {
    calls.add('resize($w, $h)');
    super.resize(w, h);
  };
}

/// A clip `{left, top, right, bottom, disabled}`.
final class _TestClip implements types.ChartMetaClip {
  @override
  Object? get left => 1;

  @override
  Object? get top => 2;

  @override
  Object? get right => 3;

  @override
  Object? get bottom => 4;

  @override
  bool get disabled => false;
}
