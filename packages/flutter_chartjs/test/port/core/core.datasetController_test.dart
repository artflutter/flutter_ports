// Original code, not ported from Chart.js: DatasetController without a chart.
@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs/src/canvas/canvas.dart';
import 'package:flutter_chartjs/src/core/core.animation.dart';
import 'package:flutter_chartjs/src/core/core.animations.dart';
import 'package:flutter_chartjs/src/core/core.animator.dart';
import 'package:flutter_chartjs/src/core/core.config.dart';
import 'package:flutter_chartjs/src/core/core.datasetController.dart';
import 'package:flutter_chartjs/src/core/core.element.dart';
import 'package:flutter_chartjs/src/core/core.typedRegistry.dart';
import 'package:flutter_chartjs/src/elements/element.arc.dart';
import 'package:flutter_chartjs/src/elements/element.bar.dart';
import 'package:flutter_chartjs/src/elements/element.line.dart';
import 'package:flutter_chartjs/src/elements/element.point.dart';
import 'package:flutter_chartjs/src/elements/element_options.dart';
import 'package:flutter_chartjs/src/helpers/helpers.collection.dart'
    show notifyArrayListeners;
import 'package:flutter_chartjs/src/helpers/helpers.options.dart'
    show createContext;
import 'package:flutter_chartjs/src/js/js_array.dart';
import 'package:flutter_chartjs/src/js/js_class.dart';
import 'package:flutter_chartjs/src/js/js_function.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/types/basic.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import 'dataset_controller_reference.dart';

// The specs of core.datasetController.tests.js need the controllers of
// phase 7. These tests cover the DatasetController without a chart
// (AGENTS.md rule 3): the parse paths (`parse`, `parsePrimitiveData`,
// `parseArrayData`, `parseObjectData`, object data and `parsing: false`),
// the array listener and `_dataChanges`, the stacks, `getMinMax` with and
// without stacks, `applyStack`, `getLabelAndValue`, `linkScales`, the clip of
// `_update`, `draw`, the element options with and without sharing,
// `getSharedOptions`, the hover styles, the animations and `getContext`.
//
// The expected observations are in dataset_controller_reference.dart, which
// tool/reference/dataset_controller_reference.mjs writes from
// src/core/core.datasetController.js at v4.5.1 in Node.js v24.12.0 on x64
// (Chart.js ADR 0010). Both sides run the same scenarios: a test controller
// that follows the option calls of controller.line.js:41-120, on a fake chart
// with fake scales, with the element classes of the registry and a custom
// element class. The observations are texts: numbers as `String(x)`, objects
// with the keys of `Object.keys`, elements as their tags, and options objects
// with an id and the frozen state.
//
// The other groups test the parts of the Dart form: the typed options of
// Chart.js ADR 0021, section 7, the class value of Chart.js ADR 0020, and the
// rows adapt-component-class-role and platform-array-events.
//
// main() registers the element classes through a new TypedRegistry of
// core.typedRegistry.dart, as `registry.addElements` does. The upstream side
// uses the registry.

/// The element counter of the current scenario.
int _counter = 0;

/// The draw calls of the current scenario.
List<String> _trace = [];

/// The ids of the objects that the observations name.
Map<Object, String> _ids = Map.identity();

/// The id of [object]: `<prefix>#<k>` in the order of the first sight.
String _idOf(String prefix, Object object) =>
    _ids.putIfAbsent(object, () => '$prefix#${_ids.length}');

/// An element with the tag of the observations.
abstract interface class _Tagged {
  String get tag;
}

/// The tag of a new element of [kind]: `<kind>#<n>`.
String _newTag(String kind) {
  final n = _counter++;
  return '$kind#$n';
}

final class _SpyPoint extends PointElement implements _Tagged {
  _SpyPoint() : tag = _newTag('point');

  @override
  final String tag;

  @override
  void draw(CanvasRenderingContext2D ctx, [types.ChartArea? area]) {
    _trace.add('$tag.draw');
  }
}

final class _SpyLine extends LineElement implements _Tagged {
  _SpyLine() : tag = _newTag('line');

  @override
  final String tag;

  @override
  void draw(
    CanvasRenderingContext2D ctx, [
    types.ChartArea? area,
    double? start,
    double? count,
  ]) {
    final from = jsToString(start ?? undefined);
    final to = jsToString(count ?? undefined);
    _trace.add('$tag.draw($from,$to)');
  }
}

final class _SpyBar extends BarElement implements _Tagged {
  _SpyBar() : tag = _newTag('bar');

  @override
  final String tag;

  @override
  void draw(CanvasRenderingContext2D ctx, [types.ChartArea? area]) {
    _trace.add('$tag.draw');
  }
}

final class _SpyArc extends ArcElement implements _Tagged {
  _SpyArc() : tag = _newTag('arc');

  @override
  final String tag;

  @override
  void draw(CanvasRenderingContext2D ctx, [types.ChartArea? area]) {
    _trace.add('$tag.draw');
  }
}

final class _SpyCustom extends Element implements types.VisualElement, _Tagged {
  _SpyCustom() : tag = _newTag('custom');

  @override
  final String tag;

  @override
  void draw(CanvasRenderingContext2D ctx, [types.ChartArea? area]) {
    _trace.add('$tag.draw');
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// `class CustomElement extends Element` with the id `custom` and its own
/// defaults.
final JsClass _customElementClass = JsClass(
  'CustomElement',
  superclass: Element.jsClass,
  statics: {
    'id': 'custom',
    'defaults': <String, Object?>{'size': 3.0, 'label': 'c'},
  },
);

final JsClass _spyPointClass = JsClass(
  'SpyPoint',
  superclass: PointElement.jsClass,
  construct: (newTarget, args) => _SpyPoint(),
);

final JsClass _spyLineClass = JsClass(
  'SpyLine',
  superclass: LineElement.jsClass,
  construct: (newTarget, args) => _SpyLine(),
);

final JsClass _spyBarClass = JsClass(
  'SpyBar',
  superclass: BarElement.jsClass,
  construct: (newTarget, args) => _SpyBar(),
);

final JsClass _spyArcClass = JsClass(
  'SpyArc',
  superclass: ArcElement.jsClass,
  construct: (newTarget, args) => _SpyArc(),
);

final JsClass _spyCustomClass = JsClass(
  'SpyCustom',
  superclass: _customElementClass,
  construct: (newTarget, args) => _SpyCustom(),
);

/// The element classes of the scenarios by name.
final Map<String, JsClass> _elementTypes = {
  'point': _spyPointClass,
  'line': _spyLineClass,
  'bar': _spyBarClass,
  'arc': _spyArcClass,
  'custom': _spyCustomClass,
};

/// The `enableOptionSharing` of the test controller in this scenario.
bool _sharing = true;

/// The `getMaxOverflow` result of the test controller, or Dart `null` for
/// the result of the base class.
Object? _maxOverflow;

/// The test controller: the option calls of controller.line.js:41-120. The
/// pixels are 10 times the parsed values.
final class _TestController extends DatasetController {
  _TestController(super.chart, super.datasetIndex, [super.newTarget]);

  @override
  void initialize() {
    enableOptionSharing = _sharing;
    super.initialize();
  }

  @override
  Object? getMaxOverflow() => _maxOverflow ?? super.getMaxOverflow();

  @override
  void update(String mode) {
    final meta = cachedMeta;
    final line = meta.dataset;
    final points = meta.data;
    if (line != null) {
      final options = resolveDatasetElementOptions(mode);
      updateElement(line as Element, null, {'options': options}, mode);
    }
    updateElements(points, 0, points.length.toDouble(), mode);
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
    final stacked = meta.stacked;
    final (:sharedOptions, :includeOptions) = getSharedOptions_(start, mode);
    final iAxis = iScale.axis;
    final vAxis = vScale.axis;
    for (var i = start; i < start + count; ++i) {
      final point = points[i.toInt()] as Element;
      final parsed = getParsed(i)!;
      final properties = <String, Object?>{};
      properties[iAxis] = iScale.getPixelForValue(jsGet(parsed, iAxis), i);
      properties[vAxis] = vScale.getPixelForValue(
        jsTruthy(stacked)
            ? applyStack(vScale, parsed, stacked)
            : jsGet(parsed, vAxis),
        i,
      );
      if (includeOptions) {
        properties['options'] =
            sharedOptions ??
            resolveDataElementOptions(i, point.active ? 'active' : mode);
      }
      updateElement(point, i, properties, mode);
    }
  }
}

/// `class TestController extends DatasetController` as a value.
final JsClass _testControllerClass = JsClass(
  'TestController',
  superclass: DatasetController.jsClass,
  construct: (newTarget, args) {
    final (:chart, :datasetIndex) = controllerArgs(args);
    return _TestController(chart, datasetIndex, newTarget);
  },
);

/// A rectangle `{left, top, right, bottom, width, height}`.
final class _Area implements types.ChartArea {
  _Area(this.left, this.top, this.right, this.bottom);

  @override
  final double left;

  @override
  final double top;

  @override
  final double right;

  @override
  final double bottom;

  @override
  double get width => right - left;

  @override
  double get height => bottom - top;
}

/// A fake scale: a linear, category or raw parse, labels and user bounds.
/// The raw parse returns the value as it is, for the `<` of the sorted
/// test.
final class _FakeScale implements types.Scale {
  _FakeScale(this.chart, AnyObject spec)
    : id = spec['id']! as String,
      axis = spec['axis']! as String,
      kind = spec['kind']! as String,
      options =
          _materialize(spec['options'] ?? <String, Object?>{})! as AnyObject,
      labels = spec.containsKey('labels')
          ? _materialize(spec['labels'])! as List<Object?>
          : null,
      bounds = spec['bounds'] as AnyObject?;

  @override
  final types.Chart chart;

  @override
  final String id;

  @override
  final String axis;

  final String kind;

  @override
  final AnyObject options;

  final List<Object?>? labels;

  final AnyObject? bounds;

  @override
  Object? parse(Object? raw, [double? index]) {
    if (kind == 'raw') {
      return raw;
    }
    if (raw == null || raw is Undefined) {
      return null;
    }
    if (kind == 'category') {
      if (raw is String) {
        final i = getLabels().indexOf(raw);
        return i == -1 ? (index ?? undefined) : i.toDouble();
      }
      return raw is num ? raw.toDouble() : null;
    }
    if (raw is num && !raw.isFinite) {
      return null;
    }
    return jsToNumber(raw);
  }

  @override
  List<Object?> getLabels() =>
      labels ?? jsGet(chart.data, 'labels')! as List<Object?>;

  @override
  Object? getLabelForValue(Object? value) {
    if (kind == 'category') {
      final labels = getLabels();
      if (value is num &&
          value.isFinite &&
          value == value.truncateToDouble() &&
          value >= 0 &&
          value < labels.length) {
        return labels[value.toInt()];
      }
    }
    return value;
  }

  @override
  ({double min, double max, bool minDefined, bool maxDefined}) getUserBounds() {
    final bounds = this.bounds;
    if (bounds == null) {
      return (min: 0, max: 0, minDefined: false, maxDefined: false);
    }
    return (
      min: jsToNumber(bounds['min']),
      max: jsToNumber(bounds['max']),
      minDefined: bounds['minDefined']! as bool,
      maxDefined: bounds['maxDefined']! as bool,
    );
  }

  @override
  List<types.ChartMeta> getMatchingVisibleMetas([String? type]) {
    final metas = chart.getSortedVisibleDatasetMetas();
    final result = <types.ChartMeta>[];
    for (final meta in metas) {
      final axisID = switch (axis) {
        'x' => meta.xAxisID,
        'y' => meta.yAxisID,
        'r' => meta.rAxisID,
        _ => null,
      };
      if (axisID == id && (type == null || type.isEmpty || meta.type == type)) {
        result.add(meta);
      }
    }
    return result;
  }

  @override
  double getPixelForValue(Object? value, [double? index]) =>
      jsToNumber(value) * 10;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The meta of core.controller.js:835-848, and the members that the fake
/// chart writes.
final class _Meta implements types.ChartMeta {
  _Meta(this.datasetObject, this.index)
    : order = jsTruthy(datasetObject) && jsTruthy(jsGet(datasetObject, 'order'))
          ? jsToNumber(jsGet(datasetObject, 'order'))
          : 0;

  /// `_dataset`.
  final Object? datasetObject;

  @override
  late String type;

  @override
  final List<types.Element> data = [];

  @override
  types.Element? dataset;

  /// `controller`: Dart `null` for the JS `null` start value.
  DatasetController? controllerValue;

  @override
  types.DatasetController get controller => controllerValue!;

  @override
  bool? hidden;

  @override
  String? xAxisID;

  @override
  String? yAxisID;

  @override
  String? rAxisID;

  @override
  String? iAxisID;

  @override
  String? vAxisID;

  double order;

  @override
  double index;

  @override
  List<Object?> parsed = [];

  @override
  bool sorted = false;

  @override
  Object? stack = undefined;

  @override
  String? indexAxis;

  @override
  Object? stacked;

  @override
  types.Scale? xScale;

  @override
  types.Scale? yScale;

  @override
  types.Scale? rScale;

  @override
  types.Scale? iScale;

  @override
  types.Scale? vScale;

  @override
  late types.ChartMetaClip clip;

  @override
  types.ScaleRanges? scaleRanges;

  String label = '';

  bool visible = false;
}

/// A fake chart: the members that core.datasetController.js reads.
final class _FakeChart implements types.Chart {
  _FakeChart(this.config, AnyObject spec)
    : animationsDisabled = spec['animationsDisabled'] as bool?,
      _plugins = (spec['plugins'] ?? <Object?>[]) as List<Object?> {
    for (final scale in spec['scales']! as List<Object?>) {
      final scaleSpec = scale! as AnyObject;
      scales[scaleSpec['id']! as String] = _FakeScale(this, scaleSpec);
    }
  }

  @override
  final Config config;

  @override
  final CanvasRenderingContext2D? ctx = createMockContext();

  @override
  AnyObject get data => config.data;

  @override
  final Map<String, types.Scale> scales = {};

  @override
  types.ChartArea chartArea = _Area(0, 0, 100, 100);

  @override
  AnyObject? stacks;

  @override
  final List<List<Object?>> dataChanges = [];

  @override
  final bool? animationsDisabled;

  final List<_Meta> _metasets = [];

  final List<Object?> _plugins;

  @override
  late final AnyObject options = config.createResolver(
    config.chartOptionScopes(),
    getContext(),
  );

  AnyObject? _context;

  @override
  AnyObject getContext() =>
      _context ??= createContext(null, {'chart': this, 'type': 'chart'});

  // core.controller.js:829-853.
  @override
  types.ChartMeta getDatasetMeta(double datasetIndex) {
    final dataset = jsGet(jsGet(data, 'datasets'), datasetIndex);
    final metasets = _metasets;
    final meta = metasets
        .where((x) => identical(x.datasetObject, dataset))
        .lastOrNull;
    if (meta != null) {
      return meta;
    }
    final created = _Meta(dataset, datasetIndex);
    metasets.add(created);
    return created;
  }

  // core.controller.js:737-750, with the sort of :397.
  @override
  List<types.ChartMeta> getSortedDatasetMetas(bool filterVisible) {
    final metasets = jsSort(
      List<_Meta>.of(_metasets),
      (a, b) => a.order == b.order ? a.index - b.index : a.order - b.order,
    );
    return [
      for (final meta in metasets)
        if (!filterVisible || meta.visible) meta,
    ];
  }

  @override
  List<types.ChartMeta> getSortedVisibleDatasetMetas() =>
      getSortedDatasetMetas(true);

  // core.controller.js:866-875.
  bool isDatasetVisible(double datasetIndex) {
    final dataset = jsGet(jsGet(data, 'datasets'), datasetIndex);
    if (!jsTruthy(dataset)) {
      return false;
    }
    final meta = getDatasetMeta(datasetIndex) as _Meta;
    final hidden = meta.hidden;
    return hidden != null ? !hidden : !jsTruthy(jsGet(dataset, 'hidden'));
  }

  @override
  bool isPluginEnabled(String pluginId) => _plugins.contains(pluginId);

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The functions of the `{$fn: name}` markers.
final Map<Object?, Object?> _functions = {
  'colorByIndex': (Object? ctx) =>
      jsGet(ctx, 'dataIndex') == 1 ? 'red' : 'blue',
  'typeIsDataset': (Object? ctx) =>
      jsGet(ctx, 'type') == 'dataset' ? 75.0 : 0.0,
};

/// A new value from a spec value: `{$fn: name}` gives a function,
/// `{$undefined: true}` gives [undefined], and the Lists and Maps are new.
Object? _materialize(Object? value) => switch (value) {
  final List<Object?> list => <Object?>[
    for (final item in list) _materialize(item),
  ],
  final AnyObject map when map.containsKey(r'$fn') => _functions[map[r'$fn']],
  final AnyObject map when map.containsKey(r'$undefined') => undefined,
  final AnyObject map => <String, Object?>{
    for (final key in jsObjectKeys(map)) key: _materialize(map[key]),
  },
  _ => value,
};

/// The text of a value in the observations, as the generator gives it.
String _enc(Object? v) => switch (v) {
  Undefined() => 'undefined',
  null => 'null',
  bool() => '$v',
  final num n => n.isNaN ? 'NaN' : jsNumberToString(n),
  final String s => jsonEncode(s),
  final JsClass c => 'class:${c.name}',
  Function() || JsFunction() => 'fn',
  final _Tagged t => t.tag,
  Element() => 'element',
  Animation() => 'animation',
  final Animations a => _idOf('anims', a),
  final List<Object?> l => '[${l.map(_enc).join(',')}]',
  final Map<String, Object?> m => _encMap(m),
  _ => throw ArgumentError.value(v, 'v', 'No text'),
};

/// The text of the object [m]: the keys of `Object.keys` with their values.
String _encMap(Map<String, Object?> m) {
  final entries = [
    for (final key in jsObjectKeys(m)) '${jsonEncode(key)}:${_enc(m[key])}',
  ];
  return '{${entries.join(',')}}';
}

/// The text of an options object: its id, frozen state and value.
String _encOptions(AnyObject? options) => options == null
    ? 'undefined'
    : '${_idOf('opt', options)} frozen=${jsObjectIsFrozen(options)} '
          '${_enc(options)}';

/// An id or a scale of a meta: `'none'` for JS `null` and `undefined`.
Object _none(Object? value) => value ?? 'none';

/// `String(value)` of a step argument.
String _s(Object? value) => value is num ? jsNumberToString(value) : '$value';

/// The name of the error [error], as `error.name` of JavaScript.
String _errorName(Object error) => switch (error) {
  TypeError() => 'TypeError',
  RangeError() => 'RangeError',
  _ => error.runtimeType.toString(),
};

/// A scenario in progress: the fake chart, the steps and the observations.
final class _Run {
  _Run(this.spec)
    : config = Config(<String, Object?>{
        'type': spec['chartType'] ?? 'test',
        'data': <String, Object?>{
          'labels': _materialize(spec['labels'] ?? <Object?>[]),
          'datasets': _materialize(spec['datasets']),
        },
        'options': _materialize(spec['options'] ?? <String, Object?>{}),
      }) {
    _counter = 0;
    _trace = [];
    _ids = Map.identity();
    _sharing = spec['sharing'] != false;
    _maxOverflow = spec['maxOverflow'];
    chart = _FakeChart(config, spec);
  }

  final AnyObject spec;

  final Config config;

  late final _FakeChart chart;

  final List<String> out = [];

  AnyObject get _elements =>
      (spec['elements'] ??
              <String, Object?>{'dataset': 'line', 'data': 'point'})
          as AnyObject;

  List<Object?> get _datasets =>
      jsGet(chart.data, 'datasets')! as List<Object?>;

  /// The meta of the dataset [ds].
  _Meta meta(Object? ds) => chart.getDatasetMeta(jsToNumber(ds)) as _Meta;

  /// The controller of the dataset [ds].
  DatasetController controller(Object? ds) => meta(ds).controllerValue!;

  AnyObject _dataset(Object? ds) => _datasets[_int(ds)]! as AnyObject;

  List<Object?> _dataOf(Object? ds) => _dataset(ds)['data']! as List<Object?>;

  types.Element? _element(Object? ds, Object? index) =>
      index == null ? meta(ds).dataset : meta(ds).data[_int(index)];

  /// Runs each step of the spec, and ends the animations of the chart.
  List<String> runAll() {
    for (final s in spec['steps']! as List<Object?>) {
      step(s! as List<Object?>);
    }
    animator.remove(chart);
    return out;
  }

  /// Runs the step [s].
  void step(List<Object?> s) {
    final op = s[0]! as String;
    final args = s.sublist(1);
    switch (op) {
      case 'build':
        _build();
      case 'elements':
        for (var i = 0; i < _datasets.length; i++) {
          controller(i).buildOrUpdateElements(args[0] as bool?);
        }
      case 'update':
        for (var i = 0; i < _datasets.length; i++) {
          controller(i).update_(args[0] as String?);
        }
      case 'updateIndex':
        controller(args[0]).updateIndex(jsToNumber(args[1]));
      case 'linkScales':
        controller(args[0]).linkScales();
      case 'configure':
        controller(args[0]).configure();
      case 'destroy':
        controller(args[0]).destroy();
      case 'draw':
        controller(args[0]).draw();
      case 'drawRange':
        controller(args[0])
          ..drawStart = (args[1] as num?)?.toDouble()
          ..drawCount = (args[2] as num?)?.toDouble();
      case 'push':
        final data = _dataOf(args[0]);
        final items = _materialize(args.sublist(1))! as List<Object?>;
        data.addAll(items);
        notifyArrayListeners(data, 'push', items);
      case 'pop':
        final data = _dataOf(args[0])..removeLast();
        notifyArrayListeners(data, 'pop', const []);
      case 'shift':
        final data = _dataOf(args[0])..removeAt(0);
        notifyArrayListeners(data, 'shift', const []);
      case 'splice':
        final data = _dataOf(args[0]);
        final items = _materialize(args.sublist(3))! as List<Object?>;
        jsSplice(data, jsToNumber(args[1]), jsToNumber(args[2]), items);
        notifyArrayListeners(data, 'splice', [args[1], args[2], ...items]);
      case 'unshift':
        final data = _dataOf(args[0]);
        final items = _materialize(args.sublist(1))! as List<Object?>;
        data.insertAll(0, items);
        notifyArrayListeners(data, 'unshift', items);
      case 'setData':
        _dataset(args[0])['data'] = _materialize(args[1]);
      case 'setItemKey':
        (_dataOf(args[0])[_int(args[1])]! as AnyObject)[args[2]! as String] =
            _materialize(args[3]);
      case 'setDataset':
        _dataset(args[0])[args[1]! as String] = _materialize(args[2]);
      case 'hidden':
        meta(args[0])
          ..hidden = args[1] as bool?
          ..visible = chart.isDatasetVisible(jsToNumber(args[0]));
      case 'setActive':
        (_element(args[0], args[1])! as Element).active = args[2]! as bool;
      case 'setHidden':
        (_element(args[0], args[1])! as Element)['hidden'] = _materialize(
          args[2],
        );
      case 'hover':
        controller(args[0]).setHoverStyle(
          _element(args[0], args[1])! as Element,
          jsToNumber(args[0]),
          jsToNumber(args[1]),
        );
      case 'unhover':
        controller(args[0]).removeHoverStyle(
          _element(args[0], args[1])! as Element,
          jsToNumber(args[0]),
          jsToNumber(args[1]),
        );
      case 'hoverDataset':
        controller(args[0]).setDatasetHoverStyle();
      case 'unhoverDataset':
        controller(args[0]).removeDatasetHoverStyle();
      case 'writeOptions':
        _options(args[0], args[1], args[2])[args[3]! as String] = args[4];
      case 'writeElementOptions':
        _element(args[0], args[1])!.options![args[2]! as String] = args[3];
      // Observations.
      case 'throws':
        final inner = args[0]! as List<Object?>;
        try {
          step(inner);
          out.add('throws ${inner[0]}: none');
        } on Object catch (e) {
          out.add('throws ${inner[0]}: ${_errorName(e)}');
        }
      case 'parsed':
        out.add('parsed ${_s(args[0])}: ${_enc(meta(args[0]).parsed)}');
      case 'sorted':
        out.add('sorted ${_s(args[0])}: ${_enc(meta(args[0]).sorted)}');
      case 'stacked':
        out.add('stacked ${_s(args[0])}: ${_enc(meta(args[0]).stacked)}');
      case 'stacks':
        out.add('stacks: ${_enc(chart.stacks ?? undefined)}');
      case 'minmax':
        final range = controller(
          args[0],
        ).getMinMax(chart.scales[args[1]]!, args[2] as bool?);
        out.add(
          'minmax ${_s(args[0])} ${args[1]} ${_s(args[2])}: '
          '${_enc({'min': range.min, 'max': range.max})}',
        );
      case 'applyStack':
        final c = controller(args[0]);
        final value = c.applyStack(
          chart.scales[args[1]]!,
          c.getParsed(jsToNumber(args[2])),
          args[3],
        );
        out.add(
          'applyStack ${_s(args[0])} ${args[1]} ${_s(args[2])} '
          '${_s(args[3])}: ${_enc(value)}',
        );
      case 'labelAndValue':
        final (:label, :value) = controller(
          args[0],
        ).getLabelAndValue(jsToNumber(args[1]));
        out.add(
          'labelAndValue ${_s(args[0])} ${_s(args[1])}: '
          '${_enc({'label': label, 'value': value})}',
        );
      case 'allParsed':
        final values = controller(
          args[0],
        ).getAllParsedValues(chart.scales[args[1]]!);
        out.add('allParsed ${_s(args[0])} ${args[1]}: ${_enc(values)}');
      case 'meta':
        final m = meta(args[0]);
        Object scale(types.Scale? s) => s?.id ?? 'none';
        out.add(
          'meta ${_s(args[0])}: ${_enc({
            'xAxisID': _none(m.xAxisID),
            'yAxisID': _none(m.yAxisID),
            'rAxisID': _none(m.rAxisID),
            'iAxisID': _none(m.iAxisID),
            'vAxisID': _none(m.vAxisID),
            'xScale': scale(m.xScale),
            'yScale': scale(m.yScale),
            'rScale': scale(m.rScale),
            'iScale': scale(m.iScale),
            'vScale': scale(m.vScale),
            'indexAxis': m.indexAxis ?? undefined,
            'stack': m.stack,
            'stacked': m.stacked,
          })}',
        );
      case 'clip':
        final clip = meta(args[0]).clip;
        final edges = {
          'top': clip.top,
          'right': clip.right,
          'bottom': clip.bottom,
          'left': clip.left,
          'disabled': clip.disabled,
        };
        out.add('clip ${_s(args[0])}: ${_enc(edges)}');
      case 'elementsList':
        final m = meta(args[0]);
        out.add('elements ${_s(args[0])}: ${_enc(m.dataset)} ${_enc(m.data)}');
      case 'elementProps':
        final element = _element(args[0], args[1])! as Element;
        final props = args[2]! as List<Object?>;
        out.add(
          'props ${_s(args[0])} ${_s(args[1])}: '
          '${_enc([for (final p in props) element[p! as String]])}',
        );
      case 'dataChanges':
        out.add('dataChanges: ${_enc(chart.dataChanges)}');
      case 'trace':
        out.add('trace: ${_enc(_trace)}');
        _trace = [];
      case 'options':
        out.add(
          'options ${_s(args[0])} ${_s(args[1])} ${_s(args[2])}: '
          '${_encOptions(_options(args[0], args[1], args[2]))}',
        );
      case 'style':
        final options = controller(args[0]).getStyle(
          (args[1] as num?)?.toDouble(),
          args[2] as bool?,
        );
        out.add(
          'style ${_s(args[0])} ${_s(args[1])} ${_s(args[2])}: '
          '${_encOptions(options)}',
        );
      case 'elementOptions':
        out.add(
          'elementOptions ${_s(args[0])} ${_s(args[1])}: '
          '${_encOptions(_element(args[0], args[1])!.options)}',
        );
      case 'sharedOptions':
        out.add(
          'sharedOptions ${_s(args[0])}: '
          '${_encOptions(controller(args[0]).sharedOptions)}',
        );
      case 'getSharedOptions':
        final (:sharedOptions, :includeOptions) = controller(
          args[0],
        ).getSharedOptions_(jsToNumber(args[1]), args[2]! as String);
        out.add(
          'getSharedOptions ${_s(args[0])} ${_s(args[1])} ${args[2]}: '
          '${_encOptions(sharedOptions)} include=$includeOptions',
        );
      case 'includeOptions':
        final value = controller(args[0]).includeOptions(
          args[1]! as String,
          args[2] == true ? <String, Object?>{} : null,
        );
        out.add('includeOptions ${_s(args[0])} ${args[1]} ${args[2]}: $value');
      case 'context':
        final context = controller(args[0]).getContext(
          (args[1] as num?)?.toDouble(),
          args[2] as bool?,
          args[3] as String?,
        );
        out.add(
          'context ${_s(args[0])} ${_s(args[1])} ${_s(args[2])} '
          '${_s(args[3])}: ${_idOf('ctx', context)} ${_enc(context)}',
        );
      case 'animations':
        final anims = controller(args[0]).resolveAnimations(
          (args[1] as num?)?.toDouble(),
          args[2] as String?,
          args[3] as bool?,
        );
        final entries = [
          for (final MapEntry(:key, :value) in anims.properties.entries)
            <Object?>[key, value],
        ];
        out.add(
          'animations ${_s(args[0])} ${_s(args[1])} ${_s(args[2])}: '
          '${_idOf('anims', anims)} ${_enc(entries)}',
        );
      default:
        throw ArgumentError.value(op, 'op', 'Unknown step');
    }
  }

  /// The options of the element type of the dataset [ds] at [index]: the
  /// dataset element options for a null [index].
  AnyObject _options(Object? ds, Object? index, Object? mode) => index == null
      ? controller(ds).resolveDatasetElementOptions(mode as String?)
      : controller(
          ds,
        ).resolveDataElementOptions(jsToNumber(index), mode as String?);

  // core.controller.js:415-451, without the registry.
  void _build() {
    final datasets = _datasets;
    final elements = _elements;
    for (var i = 0; i < datasets.length; i++) {
      final dataset = datasets[i]! as AnyObject;
      final meta = chart.getDatasetMeta(i.toDouble()) as _Meta;
      final datasetType = jsGet(dataset, 'type');
      final type = (jsTruthy(datasetType) ? datasetType : config.type)!;
      final indexAxis = jsGet(dataset, 'indexAxis');
      meta
        ..type = type as String
        ..indexAxis =
            (jsTruthy(indexAxis)
                    ? indexAxis
                    : getIndexAxis(type, chart.options))
                as String?
        ..order = jsOrZero(jsGet(dataset, 'order'))
        ..index = i.toDouble()
        ..label = jsToString(jsGet(dataset, 'label'))
        ..visible = chart.isDatasetVisible(i.toDouble());
      final existing = meta.controllerValue;
      if (existing != null) {
        existing
          ..updateIndex(i.toDouble())
          ..linkScales();
      } else {
        final datasetElement = elements['dataset'];
        jsAssign(_testControllerClass, {
          'dataElementType': _elementTypes[elements['data']],
          'datasetElementType': datasetElement is String
              ? _elementTypes[datasetElement]
              : datasetElement,
        });
        meta.controllerValue =
            jsConstruct(_testControllerClass, [chart, i.toDouble()])
                as DatasetController;
      }
    }
  }
}

/// The `int` of a step argument.
int _int(Object? value) => (value! as num).toInt();

/// The spec of the reference scenario [name].
AnyObject _spec(String name) =>
    datasetControllerReference.firstWhere((s) => s.spec['name'] == name).spec;

/// A run of the scenario [name] with its steps up to the step [count].
_Run _runTo(String name, int count) {
  final run = _Run(_spec(name));
  final steps = run.spec['steps']! as List<Object?>;
  for (final s in steps.take(count)) {
    run.step(s! as List<Object?>);
  }
  return run;
}

void main() {
  setUpSpecs();

  // A TypedRegistry of the elements registers the element classes before the
  // snapshot of the restore (Chart.js ADR 0022, section 8). An element class
  // has no parent scope: `Element` has no `id` (core.typedRegistry.js:115).
  [
    PointElement.jsClass,
    LineElement.jsClass,
    BarElement.jsClass,
    ArcElement.jsClass,
    _customElementClass,
  ].forEach(TypedRegistry(Element.jsClass, 'elements').register);

  tearDown(() {
    _counter = 0;
    _trace = [];
    _ids = Map.identity();
  });

  test('the reference comes from Node.js v24.12.0 on x64', () {
    expect(datasetControllerReferenceNode, 'v24.12.0');
    expect(datasetControllerReferenceArch, 'x64');
  });

  group('upstream scenarios', () {
    for (final (:spec, :observations) in datasetControllerReference) {
      test(spec['name']! as String, () {
        final run = _Run(spec);
        expect(run.runAll(), observations.split('\n'));
      });
    }
  });

  group('class value', () {
    test('the statics of DatasetController', () {
      // core.datasetController.js:239-249.
      final value = DatasetController.jsClass;
      expect(value.name, 'DatasetController');
      expect(value.superclass, isNull);
      expect(value['defaults'], same(DatasetController.defaults));
      expect(value['defaults'], isEmpty);
      expect(value.has('datasetElementType'), isTrue);
      expect(value['datasetElementType'], isNull);
      expect(value.has('dataElementType'), isTrue);
      expect(value['dataElementType'], isNull);
      expect(jsIsFunction(value), isTrue);
    });

    test('new.target gives the element types of the subclass', () {
      // A subclass value without a Dart class constructs a
      // DatasetController with its own class value as new.target
      // (Chart.js ADR 0020, section 4).
      final run = _runTo('parsePrimitiveData with labels', 0);
      final subclass = JsClass('Sub', superclass: DatasetController.jsClass)
        ..['dataElementType'] = _spyPointClass
        ..['datasetElementType'] = false;
      final meta = run.chart.getDatasetMeta(0) as _Meta
        ..type = 'test'
        ..indexAxis = 'x';
      final controller =
          jsConstruct(subclass, [run.chart, 0.0]) as DatasetController;
      meta.controllerValue = controller;
      expect(controller.runtimeType, DatasetController);
      expect(controller.dataElementType, same(_spyPointClass));
      expect(controller.datasetElementType, false);
      expect(controller.index, 0);
      expect(controller.cachedMeta, same(meta));
      expect(controller.type, 'test');
      // `if (this.datasetElementType)`: false gives no dataset element.
      expect(meta.dataset, isNull);
      // A direct Dart call stands for `new DatasetController(chart, 0)`.
      final direct = DatasetController(run.chart, 0);
      expect(direct.dataElementType, isNull);
      expect(direct.datasetElementType, isNull);
    });
  });

  group('adapt-component-class-role', () {
    test('a chart argument that is not a Chart throws a TypeError', () {
      expect(
        () => controllerArgs([<String, Object?>{}, 0.0]),
        throwsA(isA<TypeError>()),
      );
      expect(() => controllerArgs(const []), throwsA(isA<TypeError>()));
      final run = _runTo('parsePrimitiveData with labels', 0);
      final (:chart, :datasetIndex) = controllerArgs([run.chart]);
      expect(chart, same(run.chart));
      expect(datasetIndex, isNaN);
    });

    test('a data element class of another role throws at the cast', () {
      // A class value that constructs a plain object. Upstream keeps the
      // object in meta.data and throws later, at the first absent method.
      final run = _runTo('parsePrimitiveData with labels', 1);
      final plain = JsClass('Plain');
      run.controller(0).dataElementType = plain;
      expect(
        () => run.controller(0).buildOrUpdateElements(false),
        throwsA(isA<TypeError>()),
      );
    });

    test('a dataset element class of another role throws at the cast', () {
      final run = _runTo('parsePrimitiveData with labels', 1);
      run.controller(0).datasetElementType = JsClass('Plain');
      expect(() => run.controller(0).addElements(), throwsA(isA<TypeError>()));
    });
  });

  group('platform-array-events', () {
    test('an unmodifiable data List gets a listener', () {
      // Upstream skips the listener of a non-extensible array
      // (core.datasetController.js:386). A Dart List has no such state.
      final run = _runTo('parsePrimitiveData with labels', 1);
      final data = List<Object?>.unmodifiable(<Object?>[1.0, 2.0]);
      run
        ..step(<Object?>['setData', 0.0, <Object?>[]])
        ..step(<Object?>['elements', false]);
      run._dataset(0)['data'] = data;
      run.step(<Object?>['elements', false]);
      expect(run.meta(0).data, hasLength(2));
      notifyArrayListeners(data, 'pop', const []);
      expect(run.chart.dataChanges, [
        [0.0, '_removeElements', 1.0, 1.0],
      ]);
    });

    test('a change without a notification resyncs at the next update', () {
      final run = _runTo('array listener with parsing', 2);
      run._dataOf(0)
        ..removeAt(0)
        ..add(6.0)
        ..add(7.0);
      run.step(<Object?>['elements', true]);
      expect(run.chart.dataChanges, isEmpty);
      expect(run.meta(0).data, hasLength(7));
      expect(
        [for (final item in run.meta(0).parsed) jsGet(item, 'y')],
        [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0],
      );
    });

    test('a splice start past the length throws a RangeError at the build', () {
      // `_onDataSplice` passes the start unchanged (:1064-1071). Upstream
      // leaves holes in `meta.data`, and its next `_update` throws a
      // TypeError. The port throws at the insert of the elements.
      final run = _runTo('array listener with parsing', 2)
        ..step(<Object?>['splice', 0.0, 10.0, 0.0, 9.0]);
      expect(run.chart.dataChanges, [
        [0.0, '_insertElements', 10.0, 1.0],
      ]);
      expect(
        () => run.step(<Object?>['elements', true]),
        throwsA(isA<RangeError>()),
      );
    });

    test('with parsing false, a splice start past the length throws at the '
        'notification', () {
      final run = _runTo('parsing false and the array listener', 2);
      expect(
        () => run.step(<Object?>[
          'splice',
          0.0,
          10.0,
          0.0,
          <String, Object?>{'x': 9.0, 'y': 9.0},
        ]),
        throwsA(isA<RangeError>()),
      );
    });
  });

  group('js-semantics-resolver-objects', () {
    // With parsing false and a stacked scale, updateStacks writes
    // `item._stacks = {}` into each data item (core.datasetController.js:165).
    Map<String, Object?> spec(Object? data) => {
      'name': 'stacked data items',
      'scales': <Object?>[
        <String, Object?>{'id': 'x', 'axis': 'x', 'kind': 'linear'},
        <String, Object?>{
          'id': 'y',
          'axis': 'y',
          'kind': 'linear',
          'options': <String, Object?>{'stacked': true},
        },
      ],
      'options': <String, Object?>{'parsing': false},
      'datasets': <Object?>[
        <String, Object?>{'data': data},
      ],
      'steps': <Object?>[],
    };

    test('a data item of a narrow Map type throws a TypeError', () {
      final items = [
        {'x': 0.0, 'y': 1.0},
        {'x': 1.0, 'y': 2.0},
      ];
      expect(items, isA<List<Map<String, double>>>());
      final run = _Run(spec(<Object?>[]))..step(<Object?>['build']);
      run._dataset(0)['data'] = items;
      expect(
        () => run.step(<Object?>['elements', false]),
        throwsA(isA<TypeError>()),
      );
    });

    test('a data item of the type Map<String, Object?> takes the stacks', () {
      final items = <Object?>[
        <String, Object?>{'x': 0.0, 'y': 1.0},
        <String, Object?>{'x': 1.0, 'y': 2.0},
      ];
      final run = _Run(spec(<Object?>[]))..step(<Object?>['build']);
      run._dataset(0)['data'] = items;
      run.step(<Object?>['elements', false]);
      expect(
        (items[0]! as Map<String, Object?>)['_stacks'],
        isA<Map<String, Object?>>(),
      );
    });
  });

  group('adapt-typed-element-options', () {
    // Chart.js ADR 0021, section 7, with the fake chart of this file.

    test('the shared data options are a frozen PointOptions', () {
      // core.datasetController.tests.js:956-976 in the typed form.
      final run = _runTo('shared options of a line chart', 2);
      final controller = run.controller(0);
      final opts0 = controller.resolveDataElementOptions(0);
      final opts1 = controller.resolveDataElementOptions(1);
      expect(opts0, isA<PointOptions>());
      expect(opts0, same(opts1));
      expect(opts0[r'$shared'], isTrue);
      expect(jsObjectIsFrozen(opts0), isTrue);
    });

    test('without sharing, each call gives a new PointOptions', () {
      final run = _runTo('options without sharing', 2);
      final controller = run.controller(0);
      final opts0 = controller.resolveDataElementOptions(0);
      final opts1 = controller.resolveDataElementOptions(0);
      expect(opts0, isA<PointOptions>());
      expect(opts1, isA<PointOptions>());
      expect(opts0, isNot(same(opts1)));
      expect(opts0[r'$shared'], isFalse);
      expect(jsObjectIsFrozen(opts0), isFalse);
      expect(jsObjectIsFrozen(opts1), isFalse);
    });

    test('a scriptable option gives a PointOptions that is not frozen', () {
      // core.datasetController.tests.js:1000-1019 in the typed form.
      final run = _runTo('scriptable options', 2);
      final opts0 = run.controller(0).resolveDataElementOptions(0);
      final opts1 = run.controller(0).resolveDataElementOptions(1);
      expect(opts0, isA<PointOptions>());
      expect(opts0, isNot(same(opts1)));
      expect(opts0[r'$shared'], isFalse);
      expect(jsObjectIsFrozen(opts0), isFalse);
      expect(opts1['backgroundColor'], 'red');
    });

    test('the dataset options are a new LineOptions for each call', () {
      final run = _runTo('shared options of a line chart', 2);
      final controller = run.controller(0);
      final first = controller.resolveDatasetElementOptions();
      final second = controller.resolveDatasetElementOptions();
      expect(first, isA<LineOptions>());
      expect(second, isA<LineOptions>());
      expect(first, isNot(same(second)));
      expect(jsObjectIsFrozen(first), isFalse);
      expect(first[r'$shared'], isFalse);
      run.step(<Object?>['update', 'reset']);
      final line = run.meta(0).dataset!;
      expect(line.options, isA<LineOptions>());
      expect(jsObjectKeys(line.options!).first, r'$shared');
    });

    test('getSharedOptions keeps the class and the key order', () {
      final run = _runTo('shared options of a line chart', 2);
      final controller = run.controller(0);
      final source = controller.resolveDataElementOptions(0);
      final shared = controller.getSharedOptions(source)!;
      expect(shared, isA<PointOptions>());
      expect(shared, isNot(same(source)));
      expect(jsObjectIsFrozen(shared), isFalse);
      expect(jsObjectKeys(shared), jsObjectKeys(source));
      expect(controller.sharedOptions, same(shared));
      run.step(<Object?>['update', 'none']);
      for (final point in run.meta(0).data) {
        expect(point.options, same(shared));
      }
      // A write into the frozen cache entry throws. A write into the options
      // of a point does not throw.
      expect(() => source['radius'] = 9.0, throwsA(isA<TypeError>()));
      run.meta(0).data[0].options!['radius'] = 9.0;
      expect(shared['radius'], 9.0);
    });

    test(r'after setHoverStyle, the point holds a copy with $shared false', () {
      final run = _runTo('shared options of a line chart', 2)
        ..step(<Object?>['update', 'reset'])
        ..step(<Object?>['hover', 0.0, 0.0]);
      final options = run.meta(0).data[0].options;
      expect(options, isA<PointOptions>());
      expect(options![r'$shared'], isFalse);
      expect(jsObjectIsFrozen(options), isFalse);
      expect(options, isNot(same(run.controller(0).sharedOptions)));
    });

    test('bar, arc and custom element types', () {
      final bar = _runTo('draw without a dataset element', 2);
      final barOptions = bar.controller(0).resolveDataElementOptions(0);
      expect(barOptions, isA<BarOptions>());
      expect(jsObjectIsFrozen(barOptions), isTrue);
      final arc = _runTo('arc element options', 2);
      final arcOptions = arc.controller(0).resolveDataElementOptions(0);
      expect(arcOptions, isA<ArcOptions>());
      final custom = _runTo('custom element options', 2);
      final customOptions = custom.controller(0).resolveDataElementOptions(0);
      expect(customOptions, isA<GenericElementOptions>());
      expect(jsObjectIsFrozen(customOptions), isTrue);
      expect(jsObjectKeys(customOptions), [r'$shared', 'size', 'label']);
    });

    test('case 6: an animated write into frozen options throws', () {
      // Chart.js ADR 0021, section 5: the cache entry of the dataset call
      // has `$shared` false, and the data call returns it.
      final run = _runTo(r'frozen options with $shared false', 3);
      final options = run.meta(0).data[0].options;
      expect(options, isA<PointOptions>());
      expect(jsObjectIsFrozen(options), isTrue);
      expect(options![r'$shared'], isFalse);
      expect(
        () => run.step(<Object?>['update', 'default']),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('initialize', () {
    test('the fill option without the filler plugin prints a warning', () {
      final printed = <String>[];
      runZoned(
        () => _runTo('scriptable options', 1),
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) => printed.add(line),
        ),
      );
      const warning =
          "Tried to use the 'fill' option without the 'Filler' plugin "
          "enabled. Please import and register the 'Filler' plugin and make "
          'sure it is not disabled in the options';
      expect(printed, [warning]);
    });

    test('the filler plugin removes the warning', () {
      final printed = <String>[];
      final spec = {
        ..._spec('scriptable options'),
        'plugins': ['filler'],
      };
      runZoned(
        () => _Run(spec).step(<Object?>['build']),
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) => printed.add(line),
        ),
      );
      expect(printed, isEmpty);
    });
  });

  group('the Dart forms', () {
    test('getDataset gives undefined for an index without a dataset', () {
      final run = _runTo('parsePrimitiveData with labels', 2);
      final controller = run.controller(0)..index = 4;
      expect(controller.getDataset(), same(undefined));
      controller.index = 0;
      expect(controller.getDataset(), isA<AnyObject>());
    });

    test('getParsed gives undefined and getDataElement null for a missing '
        'index', () {
      final run = _runTo('parsePrimitiveData with labels', 2);
      final controller = run.controller(0);
      expect(controller.getParsed(0), isA<Map<String, Object?>>());
      // A parsed item can be JS null. Thus a missing index gives the
      // undefined sentinel.
      expect(controller.getParsed(9), same(undefined));
      expect(controller.getParsed(0.5), same(undefined));
      expect(controller.getParsed(-1), same(undefined));
      expect(controller.getDataElement(4), isA<PointElement>());
      expect(controller.getDataElement(5), isNull);
    });

    test('update_ gives the mode default to update for no mode', () {
      final modes = <String>[];
      final run = _runTo('clip without an overflow', 2);
      final controller = _ModeController(run.chart, 0, modes);
      run.meta(0).controllerValue = controller;
      controller
        ..update_()
        ..update_('')
        ..update_('none');
      expect(modes, ['default', 'default', 'none']);
    });

    test('the parsing keys must be strings', () {
      final spec = {
        ..._spec('parseObjectData with parsing keys'),
        'options': <String, Object?>{
          'parsing': <String, Object?>{'xAxisKey': 5.0},
        },
      };
      final run = _Run(spec)..step(<Object?>['build']);
      expect(
        () => run.step(<Object?>['elements', false]),
        throwsA(isA<TypeError>()),
      );
    });

    test('an axis id that is not a string throws an ArgumentError', () {
      final run = _runTo('linkScales', 1)
        ..step(<Object?>['setDataset', 0.0, 'xAxisID', 5.0]);
      expect(
        () => run.step(<Object?>['linkScales', 0.0]),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

/// A controller that records the modes of [update].
final class _ModeController extends DatasetController {
  _ModeController(super.chart, super.datasetIndex, this.modes);

  final List<String> modes;

  @override
  void update(String mode) {
    modes.add(mode);
  }
}
