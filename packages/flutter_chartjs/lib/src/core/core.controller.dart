// Ported from Chart.js v4.5.1+7169e651 src/core/core.controller.js (MIT, Chart.js Contributors).

/// Port of `src/core/core.controller.js`: the class [Chart].
///
/// The file keeps the upstream order and names. These parts have a Dart form
/// of their own:
/// - The statics of [Chart] follow Chart.js ADR 0020, section 6. A rest
///   parameter `...items` is one `List<Object?>`:
///   `Chart.register(A, B)` is `Chart.register([a, b])`. [Chart.instances]
///   is a Map from the `ToString` of each chart [Chart.id].
/// - `new ControllerClass(this, i)` and `new scaleClass({...})` are
///   [jsConstruct] of a class value, with a cast to the class of the role
///   (`adapt-component-class-role`, Chart.js ADR 0020, section 4).
/// - `resize` and `_eventHandler` are fields that hold a function
///   (`harness-method-fields`, Chart.js ADR 0022, section 5). A test
///   replaces the function of one chart, as it replaces a JS own property.
/// - The dataset meta, the object literal of `getDatasetMeta`, is a
///   [ChartMeta]. It is a `types.PropertyAccess`, because the animations
///   write its `visible` by name (Chart.js ADR 0019, section 9).
/// - `Object.keys` is [jsObjectKeys], `Array.prototype.sort` is [jsSort],
///   and `delete this._metasets[i]` leaves Dart `null` for the hole of the
///   array.
///
/// The underscore members that another module reads drop the underscore and
/// carry `@internal` (Chart.js ADR 0012). The dataset controllers read
/// [Chart.stacks], [Chart.animationsDisabled], [Chart.dataChanges] and
/// [Chart.getSortedDatasetMetas]. The specs read [Chart.metasets],
/// [Chart.sortedMetasets], [Chart.active], [Chart.plugins] and
/// [Chart.handleEvent]. The harness reads [Chart.eventHandler].
///
/// The library imports the platform layer and the chart host. Thus it is not
/// a pure layer.
library;

import 'package:flutter_chartjs/src/canvas/canvas.dart';
import 'package:flutter_chartjs/src/core/core.animator.dart';
import 'package:flutter_chartjs/src/core/core.config.dart'
    show Config, determineAxis, getIndexAxis;
import 'package:flutter_chartjs/src/core/core.datasetController.dart';
import 'package:flutter_chartjs/src/core/core.defaults.dart' as core_defaults;
import 'package:flutter_chartjs/src/core/core.element.dart';
import 'package:flutter_chartjs/src/core/core.interaction.dart';
import 'package:flutter_chartjs/src/core/core.layouts.dart';
import 'package:flutter_chartjs/src/core/core.plugins.dart';
import 'package:flutter_chartjs/src/core/core.registry.dart' as core_registry;
import 'package:flutter_chartjs/src/core/core.scale.dart';
import 'package:flutter_chartjs/src/helpers/helpers.core.dart'
    show
        callback,
        each,
        elementsEqual,
        isClickEvent,
        isFunction,
        isNullOrUndef,
        setsEqual,
        uid,
        valueOrDefault;
import 'package:flutter_chartjs/src/helpers/helpers.extras.dart'
    show Debounced, debounce;
import 'package:flutter_chartjs/src/helpers/index.dart'
    show
        clearCanvas,
        clipArea,
        createContext,
        getDatasetClipArea,
        isDomSupported,
        retinaScale,
        unclipArea;
import 'package:flutter_chartjs/src/helpers/index.dart'
    as helpers
    show isPointInArea;
import 'package:flutter_chartjs/src/js/js_array.dart';
import 'package:flutter_chartjs/src/js/js_class.dart';
import 'package:flutter_chartjs/src/js/js_function.dart' show jsCall;
import 'package:flutter_chartjs/src/js/js_math.dart' show jsMax;
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart' show jsGet, jsGetIndex;
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/platform/index.dart'
    show BasePlatform, detectPlatform;
import 'package:flutter_chartjs/src/types/basic.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;
import 'package:flutter_chartjs/src/types/layout.dart'
    show LayoutItem, LayoutItemConfigure, LayoutLayer;
import 'package:flutter_chartjs/src/upstream.dart' show chartJsPackageVersion;
import 'package:meta/meta.dart';

// core.controller.js:15-18: the JSDoc typedefs `ChartEvent` and `Point` are
// the interfaces of lib/src/types/index.dart.

/// core.controller.js:20 `KNOWN_POSITIONS`.
const List<String> _knownPositions = [
  'top',
  'bottom',
  'left',
  'right',
  'chartArea',
];

/// core.controller.js:21 `positionIsHorizontal(position, axis)`.
///
/// [position] is an option value. `KNOWN_POSITIONS.indexOf(position)`
/// compares with `===`, which is `==` for a `String`. Dart `null` for
/// [axis] stands for an absent argument.
bool _positionIsHorizontal(Object? position, [Object? axis]) {
  return position == 'top' ||
      position == 'bottom' ||
      (!_knownPositions.contains(position) && axis == 'x');
}

/// core.controller.js:25 `compare2Level(l1, l2)`.
///
/// The property reads `a[l1]` and `a[l2]` are the getters [l1] and [l2].
/// `a[l1] === b[l1]` of two numbers is `==`: NaN is not equal to NaN in
/// both.
num Function(T a, T b) _compare2Level<T>(
  double Function(T item) l1,
  double Function(T item) l2,
) {
  return (a, b) => l1(a) == l1(b) ? l2(a) - l2(b) : l1(a) - l1(b);
}

/// core.controller.js:33 `onAnimationsComplete(context)`.
///
/// `animationOptions && animationOptions.onComplete` gives the falsy
/// `animationOptions` itself, which is not a function.
void _onAnimationsComplete(AnimationEvent context) {
  final chart = context.chart;
  final animationOptions = chart.options['animation'];

  chart.notifyPlugins('afterRender');
  callback(
    jsTruthy(animationOptions)
        ? jsGet(animationOptions, 'onComplete')
        : animationOptions,
    [context],
    chart,
  );
}

/// core.controller.js:41 `onAnimationProgress(context)`.
void _onAnimationProgress(AnimationEvent context) {
  final chart = context.chart;
  final animationOptions = chart.options['animation'];
  callback(
    jsTruthy(animationOptions)
        ? jsGet(animationOptions, 'onProgress')
        : animationOptions,
    [context],
    chart,
  );
}

/// core.controller.js:51 `getCanvas(item)`.
///
/// Chart.js can take a string id of a canvas element, a 2d context, or a
/// canvas element itself.
/// Attempt to unwrap the item passed into the chart constructor so that it
/// is a canvas element (if possible).
///
/// [isDomSupported] is false in the port (`platform-dom-supported`). Thus
/// the first branch never looks up an id, as upstream outside a browser. A
/// non-empty string then gives its first character, as upstream.
/// `item.canvas` is [_canvasOf].
Object? _getCanvas(Object? item) {
  if (isDomSupported() && item is String) {
    // document.getElementById(item) has no port: the port has no DOM.
  } else if (jsTruthy(item) && jsTruthy(jsGet(item, 'length'))) {
    // Support for array based queries (such as jQuery)
    // Upstream reassigns its parameter.
    // ignore: parameter_assignments
    item = jsGet(item, 0);
  }

  if (jsTruthy(item) && jsTruthy(_canvasOf(item))) {
    // Support for any object associated to a canvas (including a context2d)
    // Upstream reassigns its parameter.
    // ignore: parameter_assignments
    item = _canvasOf(item);
  }
  return item;
}

/// The property read `item.canvas` of `getCanvas` (core.controller.js:59):
/// the `canvas` of a context and of a chart, else [jsGet].
Object? _canvasOf(Object? item) => switch (item) {
  final CanvasRenderingContext2D context => context.canvas,
  final types.Chart chart => chart.canvas,
  _ => jsGet(item, 'canvas'),
};

/// core.controller.js:66 `instances`: the charts by the `ToString` of their
/// [Chart.id].
///
/// The ids grow. Thus the insertion order of the Map is the `Object.keys`
/// order of the integer keys.
final Map<String, Chart> _instances = <String, Chart>{};

/// core.controller.js:67 `getChart(key)`.
///
/// `Object.values(instances)` gives the charts in the `Object.keys` order.
/// `filter(...).pop()` gives the last match. Dart `null` stands for the
/// `undefined` of no match. `c.canvas === canvas` is [identical].
Chart? _getChart(Object? key) {
  final canvas = _getCanvas(key);
  final keys = jsObjectKeys(_instances);
  for (var i = keys.length - 1; i >= 0; i--) {
    final chart = _instances[keys[i]]!;
    if (identical(chart.canvas, canvas)) {
      return chart;
    }
  }
  return null;
}

/// core.controller.js:72 `moveNumericKeys(obj, start, move)`.
///
/// The keys are the `ToString` of the indices. `+key` is [jsToNumber]. The
/// write `obj[intKey + move]` takes the key [jsNumberToString]. An absent
/// key reads as Dart `null`, as `undefined`.
void _moveNumericKeys(Map<String, Object?> obj, double start, double move) {
  final keys = jsObjectKeys(obj);
  for (final key in keys) {
    final intKey = jsToNumber(key);
    if (intKey >= start) {
      final value = obj[key];
      obj.remove(key);
      if (move > 0 || intKey > start) {
        obj[jsNumberToString(intKey + move)] = value;
      }
    }
  }
}

/// core.controller.js:93 `determineLastEvent(e, lastEvent, inChartArea,
/// isClick)`.
///
/// @param {ChartEvent} e
/// @param {ChartEvent|null} lastEvent
/// @param {boolean} inChartArea
/// @param {boolean} isClick
/// @returns {ChartEvent|null}
///
/// [inChartArea] is the value of `args.inChartArea`, which a plugin can
/// change. The test is its ToBoolean.
types.ChartEvent? _determineLastEvent(
  types.ChartEvent e,
  types.ChartEvent? lastEvent,
  Object? inChartArea,
  bool isClick,
) {
  if (!jsTruthy(inChartArea) || e.type == 'mouseout') {
    return null;
  }
  if (isClick) {
    return lastEvent;
  }
  return e;
}

/// core.controller.js:835-848 the dataset meta: the object literal of
/// `getDatasetMeta`, the `ChartMeta` of index.d.ts:507.
///
/// The fields have the upstream names. The `_` properties that other
/// modules read drop the underscore (Chart.js ADR 0012): `_parsed` is
/// [parsed], `_sorted` is [sorted], `_stacked` is [stacked], `_clip` is
/// [clip] and `_scaleRanges` is [scaleRanges]. `_dataset` is [dataset_],
/// because [dataset] has the name without the underscore (Chart.js ADR
/// 0023).
///
/// The meta is also a `types.PropertyAccess`: the access by name of the JS
/// object. The animations read and write [visible] and `$animations` by name
/// (core.controller.js:903, Chart.js ADR 0019, section 9). A name that the
/// meta does not declare goes to a Map of extra properties.
final class ChartMeta implements types.ChartMeta, types.PropertyAccess {
  ChartMeta._({
    required this.order,
    required this.index,
    required this.dataset_,
  });

  /// core.controller.js:836 `type: null`, then the dataset type
  /// (core.controller.js:431). Dart `null` is the JS `null`. The value is
  /// `dataset.type || this.config.type`, which can be `undefined`.
  Object? _type;

  /// core.controller.js:836 `type`, as a `String`.
  ///
  /// `buildOrUpdateControllers` writes the dataset type before it
  /// constructs the controller (core.controller.js:431). The readers of
  /// other modules read it after that write. A read of another value throws
  /// a [TypeError].
  @override
  String get type => _type! as String;

  /// core.controller.js:837 `data: []`, the data elements.
  @override
  final List<types.Element> data = [];

  /// core.controller.js:838 `dataset: null`, the dataset element. Dart
  /// `null` stands for JS `null` and `undefined`.
  @override
  types.Element? dataset;

  /// core.controller.js:839 `controller: null`. Dart `null` stands for JS
  /// `null`.
  @override
  DatasetController? controller;

  /// core.controller.js:840 `hidden: null`. See [Chart.isDatasetVisible].
  @override
  bool? hidden;

  /// core.controller.js:841 `xAxisID: null`.
  @override
  Object? xAxisID;

  /// core.controller.js:842 `yAxisID: null`.
  @override
  Object? yAxisID;

  /// core.controller.js:843 `order: dataset && dataset.order || 0`.
  double order;

  /// core.controller.js:844 `index: datasetIndex`.
  @override
  double index;

  /// core.controller.js:845 `_dataset: dataset`, the dataset object of the
  /// meta. The name has a trailing underscore, because [dataset] has the
  /// name without the leading underscore (Chart.js ADR 0023). The specs read
  /// it (core.controller.tests.js:1973).
  @internal
  @override
  final Object? dataset_;

  /// core.controller.js:846 `_parsed: []`.
  @override
  List<Object?> parsed = <Object?>[];

  /// core.controller.js:847 `_sorted: false`.
  @override
  bool sorted = false;

  /// core.controller.js:432 `indexAxis`. Dart `null` stands for JS
  /// `undefined`, the value before `buildOrUpdateControllers`.
  @override
  String? indexAxis;

  /// core.controller.js:435 `meta.label = '' + dataset.label`. Dart `null`
  /// stands for JS `undefined`, the value before `buildOrUpdateControllers`.
  String? label;

  /// core.controller.js:436 `visible`, the result of
  /// [Chart.isDatasetVisible].
  ///
  /// The `hide` animation writes the numbers 1 and 0 of `v => v | 0`
  /// (core.animations.defaults.js:64-68). The readers apply ToBoolean
  /// (core.controller.js:744). The [undefined] sentinel is the value before
  /// `buildOrUpdateControllers`.
  Object? visible = undefined;

  /// core.datasetController.js:420 `stack`. See `types.ChartMeta.stack`.
  @override
  Object? stack = undefined;

  /// core.datasetController.js:284 `_stacked`. See
  /// `types.ChartMeta.stacked`.
  @override
  Object? stacked;

  /// core.datasetController.js:308 `rAxisID`.
  @override
  Object? rAxisID;

  /// core.datasetController.js:310 `iAxisID`.
  @override
  Object? iAxisID;

  /// core.datasetController.js:311 `vAxisID`.
  @override
  Object? vAxisID;

  /// core.datasetController.js:312 `xScale`.
  @override
  types.Scale? xScale;

  /// core.datasetController.js:313 `yScale`.
  @override
  types.Scale? yScale;

  /// core.datasetController.js:314 `rScale`.
  @override
  types.Scale? rScale;

  /// core.datasetController.js:315 `iScale`.
  @override
  types.Scale? iScale;

  /// core.datasetController.js:316 `vScale`.
  @override
  types.Scale? vScale;

  /// core.datasetController.js:704 `_clip`.
  ///
  /// The literal of `_getMetaForDataset` has no `_clip`
  /// (core.controller.js:836-853). Thus a read before the first `_update`
  /// throws a [TypeError], as the upstream readers throw for the property
  /// of `undefined`. The read by name gives [undefined] then ([operator
  /// []]).
  @override
  types.ChartMetaClip get clip => _clip ?? (throw TypeError());

  @override
  set clip(types.ChartMetaClip value) => _clip = value;

  /// The value of [clip], or Dart `null` for its JS `undefined` start
  /// value.
  types.ChartMetaClip? _clip;

  /// helpers.extras.ts:153 `_scaleRanges`.
  @override
  types.ScaleRanges? scaleRanges;

  /// index.d.ts:374 `DoughnutMetaExtensions.total`: the total of the
  /// doughnut or pie dataset. Dart `null` stands for JS `undefined`, the
  /// start value. controller.doughnut.js:235 writes it.
  @override
  double? total;

  /// core.animations.js:71 `$animations`, the running animations of the
  /// meta. The [undefined] sentinel is the absent property.
  Object? _animations = undefined;

  /// The extra properties of the access by name. Dart `null` until the
  /// first write of such a property.
  Map<String, Object?>? _extras;

  /// The JS property read `meta[prop]`.
  ///
  /// The names of the literal and of the later writes read their fields.
  /// Dart `null` stands for the JS `null` of a start value. [total] gives
  /// [undefined] for Dart `null`. Another name reads the Map of extra
  /// properties, and gives [undefined] for an absent property.
  @override
  Object? operator [](String prop) => switch (prop) {
    'type' => _type,
    'data' => data,
    'dataset' => dataset,
    'controller' => controller,
    'hidden' => hidden,
    'xAxisID' => xAxisID,
    'yAxisID' => yAxisID,
    'order' => order,
    'index' => index,
    '_dataset' => dataset_,
    '_parsed' => parsed,
    '_sorted' => sorted,
    'indexAxis' => indexAxis ?? undefined,
    'label' => label ?? undefined,
    'visible' => visible,
    'stack' => stack,
    '_stacked' => stacked ?? undefined,
    'rAxisID' => rAxisID ?? undefined,
    'iAxisID' => iAxisID ?? undefined,
    'vAxisID' => vAxisID ?? undefined,
    'xScale' => xScale ?? undefined,
    'yScale' => yScale ?? undefined,
    'rScale' => rScale ?? undefined,
    'iScale' => iScale ?? undefined,
    'vScale' => vScale ?? undefined,
    '_scaleRanges' => scaleRanges ?? undefined,
    '_clip' => _clip ?? undefined,
    'total' => total ?? undefined,
    r'$animations' => _animations,
    _ => _extra(prop),
  };

  /// The value of an extra property, or [undefined].
  Object? _extra(String prop) {
    final extras = _extras;
    if (extras == null || !extras.containsKey(prop)) {
      return undefined;
    }
    return extras[prop];
  }

  /// The JS property write `meta[prop] = value`.
  ///
  /// `visible`, `$animations`, `type`, `label` and the extra properties take
  /// any value. A typed field takes a value of its type: another value
  /// throws a [TypeError]. [total] takes a number or [undefined]. `data` and
  /// `_dataset` are final: a write throws an [UnsupportedError]. No ported
  /// code writes them by name.
  @override
  void operator []=(String prop, Object? value) {
    switch (prop) {
      case 'visible':
        visible = value;
      case r'$animations':
        _animations = value;
      case 'type':
        _type = value;
      case 'label':
        label = value is Undefined ? null : value as String?;
      case 'dataset':
        dataset = value is Undefined ? null : value as types.Element?;
      case 'controller':
        controller = value is Undefined ? null : value as DatasetController?;
      case 'hidden':
        hidden = value is Undefined ? null : value as bool?;
      case 'xAxisID':
        xAxisID = value is Undefined ? null : value;
      case 'yAxisID':
        yAxisID = value is Undefined ? null : value;
      case 'rAxisID':
        rAxisID = value is Undefined ? null : value;
      case 'iAxisID':
        iAxisID = value is Undefined ? null : value;
      case 'vAxisID':
        vAxisID = value is Undefined ? null : value;
      case 'order':
        order = jsToNumber(value);
      case 'index':
        index = jsToNumber(value);
      case 'indexAxis':
        indexAxis = value is Undefined ? null : value as String?;
      case 'stack':
        stack = value;
      case '_stacked':
        stacked = value is Undefined ? null : value;
      case '_parsed':
        parsed = value! as List<Object?>;
      case '_sorted':
        sorted = value! as bool;
      case 'xScale':
        xScale = value is Undefined ? null : value as types.Scale?;
      case 'yScale':
        yScale = value is Undefined ? null : value as types.Scale?;
      case 'rScale':
        rScale = value is Undefined ? null : value as types.Scale?;
      case 'iScale':
        iScale = value is Undefined ? null : value as types.Scale?;
      case 'vScale':
        vScale = value is Undefined ? null : value as types.Scale?;
      case '_clip':
        clip = value! as types.ChartMetaClip;
      case '_scaleRanges':
        scaleRanges = value is Undefined ? null : value as types.ScaleRanges?;
      case 'total':
        total = value is Undefined ? null : (value as num?)?.toDouble();
      case 'data' || '_dataset':
        throw UnsupportedError('The meta keeps its $prop.');
      default:
        (_extras ??= <String, Object?>{})[prop] = value;
    }
  }
}

/// core.controller.js:1104-1108 the object `{datasetIndex, element, index}`
/// of `setActiveElements`.
final class _ActiveElement implements types.ActiveElement {
  _ActiveElement({
    required this.datasetIndex,
    required this.element,
    required this.index,
  });

  @override
  final double datasetIndex;

  /// Dart `null` stands for the `undefined` of an index without an element.
  @override
  final types.Element? element;

  @override
  final double index;
}

/// core.controller.js:103 `Chart`.
class Chart implements types.Chart {
  /// core.controller.js:123 `constructor(item, userConfig)`.
  ///
  /// [item] is a canvas element, a context, an object with a `canvas`, or
  /// another value (`getCanvas`, core.controller.js:51). [userConfig] is the
  /// raw configuration: a Map, or a falsy value (Chart.js ADR 0006).
  ///
  /// `new Error(message)` is a [StateError] with the upstream message, as in
  /// `core.registry.dart`. `config.platform` is a class value
  /// ([jsConstruct]). `new (_detectPlatform(initialCanvas))()` calls the
  /// constructor tear-off of [detectPlatform] (Chart.js ADR 0014,
  /// section 1).
  ///
  /// `console.error` is a `print` of the message.
  // eslint-disable-next-line max-statements
  Chart(Object? item, [Object? userConfig]) : config = Config(userConfig) {
    final config = this.config;
    final initialCanvas = _getCanvas(item);
    final existingChart = _getChart(initialCanvas);
    if (existingChart != null) {
      throw StateError(
        'Canvas is already in use. Chart with ID '
        "'${jsNumberToString(existingChart.id)}'"
        ' must be destroyed before the canvas with ID '
        "'${existingChart.canvas!.getAttribute('id') ?? ''}' can be reused.",
      );
    }

    final options = config.createResolver(
      config.chartOptionScopes(),
      getContext(),
    );

    // `new (config.platform || _detectPlatform(initialCanvas))()`. A class
    // value of another role throws a TypeError at the cast. Upstream throws
    // a TypeError at the call of updateConfig, the next line.
    final configPlatform = config.platform;
    platform = jsTruthy(configPlatform)
        ? jsConstruct(configPlatform, const []) as BasePlatform
        : detectPlatform(initialCanvas)();
    platform.updateConfig(config);

    final context = platform.acquireContext(
      initialCanvas,
      _numberOrNull(options['aspectRatio']),
    );
    final canvas = context?.canvas;
    // `canvas && canvas.height`: 0 stands for the JS `null` of a chart
    // without a canvas. Its readers apply ToNumber or ToBoolean.
    final height = canvas?.height.toDouble() ?? 0;
    final width = canvas?.width.toDouble() ?? 0;

    id = uid();
    ctx = context;
    this.canvas = canvas;
    this.width = width;
    this.height = height;
    _options = options;
    // Store the previously used aspect ratio to determine if a resize
    // is needed during updates. Do this after _options is set since
    // aspectRatio uses a getter
    _aspectRatio = aspectRatio;
    // :154-172: the fields with a start value get it before the body. The
    // reset of `$context` (:172) stays here: `getContext()` above made one.
    $context = null;
    _doResize = debounce<Object?>(update, jsOrZero(options['resizeDelay']));

    // Add the chart instance to the global namespace
    instances[jsNumberToString(id)] = this;

    if (context == null || canvas == null) {
      // The given item is not a compatible context2d element, let's return
      // before finalizing the chart initialization but after setting basic
      // chart / controller properties that can help to figure out that the
      // chart is not valid (e.g chart.canvas !== null);
      // https://github.com/chartjs/Chart.js/issues/2807
      _consoleError(
        "Failed to create chart: can't acquire context from the "
        'given item',
      );
      return;
    }

    animator
      ..listen(this, 'complete', _onAnimationsComplete)
      ..listen(this, 'progress', _onAnimationProgress);

    _initialize();
    if (attached) {
      update();
    }
  }

  /// core.controller.js:105 `static defaults = defaults`.
  static final core_defaults.Defaults defaults = core_defaults.defaults;

  /// core.controller.js:106 `static instances = instances`: the charts by
  /// the `ToString` of their [id] (index.d.ts:594).
  static final Map<String, Chart> instances = _instances;

  /// core.controller.js:107 `static overrides = overrides`.
  static AnyObject get overrides => core_defaults.overrides;

  /// core.controller.js:108 `static registry = registry`.
  static final core_registry.Registry registry = core_registry.registry;

  /// core.controller.js:109 `static version = version`. Upstream reads the
  /// version from `package.json` (core.controller.js:12). The port has
  /// [chartJsPackageVersion] for it (Chart.js ADR 0020, section 6). Under a
  /// commit pin, `chartJsVersion` also names the commit, and `package.json`
  /// names the last release.
  static const String version = chartJsPackageVersion;

  /// core.controller.js:110 `static getChart = getChart`.
  ///
  /// Dart `null` stands for the `undefined` of no chart.
  static Chart? getChart(Object? key) => _getChart(key);

  /// core.controller.js:112 `static register(...items)`.
  ///
  /// The rest parameter is one List (Chart.js ADR 0020, section 6):
  /// `Chart.register(A, B)` is `Chart.register([a, b])`, and
  /// `Chart.register(...registerables)` is `Chart.register(registerables)`.
  static void register(List<Object?> items) {
    registry.add(items);
    _invalidatePlugins();
  }

  /// core.controller.js:117 `static unregister(...items)`.
  static void unregister(List<Object?> items) {
    registry.remove(items);
    _invalidatePlugins();
  }

  /// core.controller.js:124 `config`: the `Config` of the configuration.
  @override
  final Config config;

  /// core.controller.js:136 `platform`.
  @override
  late final BasePlatform platform;

  /// core.controller.js:144 `id`: a number of `uid()`.
  late final double id;

  /// core.controller.js:145 `ctx`. Dart `null` stands for JS `null`: the
  /// context of a failed `acquireContext`, and the context after [destroy].
  @override
  CanvasRenderingContext2D? ctx;

  /// core.controller.js:146 `canvas`. Dart `null` stands for JS `null`, as
  /// for [ctx].
  @override
  HTMLCanvasElement? canvas;

  /// core.controller.js:147 `width`.
  @override
  late double width;

  /// core.controller.js:148 `height`.
  @override
  late double height;

  /// core.controller.js:149 `_options`: the resolver of the chart options.
  late AnyObject _options;

  /// core.controller.js:153 `_aspectRatio`. Dart `null` stands for the JS
  /// `null` of [aspectRatio].
  double? _aspectRatio;

  /// core.controller.js:154 `_layers`: the drawing layers of the boxes.
  List<LayoutLayer> _layers = [];

  /// core.controller.js:155 `_metasets`: the dataset metas. Dart `null` is a
  /// hole of the JS array: `_destroyDatasetMeta` deletes an item
  /// (core.controller.js:924). The specs read it
  /// (core.controller.tests.js:1969).
  @internal
  final List<ChartMeta?> metasets = [];

  /// core.controller.js:156 `_stacks = undefined`. See `types.Chart.stacks`.
  @internal
  @override
  AnyObject? stacks;

  /// core.controller.js:157 `boxes = []`.
  @override
  final List<LayoutItem> boxes = [];

  /// core.controller.js:158 `currentDevicePixelRatio = undefined`. NaN
  /// stands for JS `undefined`: `retinaScale` compares it with `!==`
  /// (helpers.dom.ts:232), and NaN is not equal to any ratio.
  @override
  double currentDevicePixelRatio = double.nan;

  /// core.controller.js:159 `chartArea = undefined`. Dart `null` stands for
  /// JS `undefined` until the first layout.
  @override
  types.ChartArea? chartArea;

  /// core.controller.js:160 `_active = []`: the active elements. The specs
  /// read it (core.controller.tests.js:1718).
  @internal
  List<types.ActiveElement> active = [];

  /// core.controller.js:161 `_lastEvent = undefined`. Dart `null` stands for
  /// JS `null` and `undefined`. The readers test its truthiness.
  types.ChartEvent? _lastEvent;

  /// core.controller.js:162 `_listeners = {}`: the event listeners by type.
  Map<String, Function> _listeners = {};

  /// core.controller.js:164 `_responsiveListeners = undefined`. Dart `null`
  /// stands for JS `undefined`.
  ///
  /// @type {?{attach?: function, detach?: function, resize?: function}}
  Map<String, Function>? _responsiveListeners;

  /// core.controller.js:165 `_sortedMetasets = []`: the metas in the drawing
  /// order. The specs read it (core.controller.tests.js:1984).
  @internal
  List<ChartMeta?> sortedMetasets = [];

  /// core.controller.js:166 `scales = {}`: the scales by id.
  @override
  final Map<String, Scale> scales = {};

  /// core.controller.js:167 `_plugins = new PluginService()`. The specs read
  /// it (core.controller.tests.js:1944).
  @internal
  final PluginService plugins = PluginService();

  /// core.controller.js:168 `$proxies = {}`. See
  /// `types.Chart.platformProxies`.
  @override
  AnyObject? platformProxies = {};

  /// core.controller.js:169 `_hiddenIndices = {}`: the hidden data indices.
  /// The keys are the `ToString` of the indices.
  final Map<String, Object?> _hiddenIndices = {};

  /// core.controller.js:170 `attached = false`.
  bool attached = false;

  /// core.controller.js:171 `_animationsDisabled = undefined`. See
  /// `types.Chart.animationsDisabled`.
  @internal
  @override
  bool? animationsDisabled;

  /// core.controller.js:172 `$context = undefined`: the chart context of
  /// [getContext]. Dart `null` stands for JS `undefined`.
  AnyObject? $context;

  /// core.controller.js:173 `_doResize`: the debounced update of a resize.
  late Debounced<Object?> _doResize;

  /// core.controller.js:174 `_dataChanges = []`. See
  /// `types.Chart.dataChanges`.
  @internal
  @override
  List<List<Object?>> dataChanges = [];

  /// core.controller.js:273 `_resizeBeforeDraw`: the pending resize of
  /// [resize] during an animation. Dart `null` stands for JS `null` and
  /// `undefined`.
  ({double? width, double? height})? _resizeBeforeDraw;

  /// core.controller.js:509 `_minPadding`. Dart `null` stands for JS
  /// `undefined`, the value before the first update.
  double? _minPadding;

  /// index.d.ts:543 `legend`: the legend element. Dart `null` stands for JS
  /// `undefined`, the start value. The legend plugin of phase 8 writes it
  /// (plugin.legend.js:602) and deletes it (:609).
  @override
  types.LegendElement? legend;

  /// core.controller.js:197 `get aspectRatio()`.
  ///
  /// The `aspectRatio` option gives its `ToNumber`: the readers divide by
  /// it (helpers.dom.ts:191). Dart `null` stands for the JS `null` result.
  double? get aspectRatio {
    final options = this.options;
    final aspectRatio = options['aspectRatio'];
    final maintainAspectRatio = options['maintainAspectRatio'];
    final width = this.width;
    final height = this.height;
    final aspectRatioBefore = _aspectRatio;
    if (!isNullOrUndef(aspectRatio)) {
      // If aspectRatio is defined in options, use that.
      return jsToNumber(aspectRatio);
    }

    if (jsTruthy(maintainAspectRatio) && jsTruthy(aspectRatioBefore)) {
      // If maintainAspectRatio is truthly and we had previously determined
      // _aspectRatio, use that
      return aspectRatioBefore;
    }

    // Calculate
    return jsTruthy(height) ? width / height : null;
  }

  /// core.controller.js:213 `get data()`.
  @override
  AnyObject get data {
    return config.data;
  }

  /// core.controller.js:217 `set data(data)`.
  set data(Object? data) {
    config.data = data;
  }

  /// core.controller.js:221 `get options()`.
  @override
  AnyObject get options {
    return _options;
  }

  /// core.controller.js:225 `set options(options)`.
  set options(Object? options) {
    config.options = options;
  }

  // core.controller.js:229-231 `get registry()`: Dart forbids an instance
  // getter beside the static `Chart.registry` (Chart.js ADR 0020, section
  // 6). Its one reader, controller.scatter.js:105, reads the singleton
  // `registry` of core.registry.dart, the same object.
  // DIVERGES(chartjs): adapt-chart-registry-getter, no instance getter.

  /// core.controller.js:236 `_initialize()`.
  /// @private
  Chart _initialize() {
    // Before init plugin notification
    notifyPlugins('beforeInit');

    if (jsTruthy(options['responsive'])) {
      resize();
    } else {
      retinaScale(this, _numberOrNull(options['devicePixelRatio']));
    }

    bindEvents();

    // After init plugin notification
    notifyPlugins('afterInit');

    // The upstream method returns this.
    // ignore: avoid_returning_this
    return this;
  }

  /// core.controller.js:254 `clear()`.
  Chart clear() {
    clearCanvas(canvas, ctx);
    // The upstream method returns this (index.d.ts:551).
    // ignore: avoid_returning_this
    return this;
  }

  /// core.controller.js:259 `stop()`.
  Chart stop() {
    animator.stop(this);
    // The upstream method returns this (index.d.ts:552).
    // ignore: avoid_returning_this
    return this;
  }

  /// core.controller.js:269 `resize(width, height)`.
  ///
  /// Resize the chart to its container or to explicit dimensions.
  /// @param {number} [width]
  /// @param {number} [height]
  ///
  /// A test can replace the function of one chart, as it replaces a JS own
  /// property (Chart.js ADR 0022, section 5). Each upstream call of
  /// `this.resize` calls this field. Dart `null` stands for an absent
  /// argument.
  // DIVERGES(chartjs): harness-method-fields, a test replaces it per chart.
  late void Function([double? width, double? height]) resize = _resizeMethod;

  /// The upstream body of `resize` (core.controller.js:269-275).
  void _resizeMethod([double? width, double? height]) {
    if (!animator.running(this)) {
      _resize(width, height);
    } else {
      _resizeBeforeDraw = (width: width, height: height);
    }
  }

  /// core.controller.js:277 `_resize(width, height)`.
  ///
  /// `options.maintainAspectRatio && this.aspectRatio` gives Dart `null`
  /// for a falsy option. `newSize` is the record of `getMaximumSize`. The
  /// hook `resize` and `onResize` get it as `size`.
  void _resize(double? width, double? height) {
    final options = this.options;
    final canvas = this.canvas;
    final aspectRatio = jsTruthy(options['maintainAspectRatio'])
        ? this.aspectRatio
        : null;
    final newSize = platform.getMaximumSize(
      canvas!,
      width,
      height,
      aspectRatio,
    );
    final devicePixelRatio = options['devicePixelRatio'];
    final newRatio = jsTruthy(devicePixelRatio)
        ? jsToNumber(devicePixelRatio)
        : platform.getDevicePixelRatio();
    final mode = jsTruthy(this.width) ? 'resize' : 'attach';

    this.width = newSize.width;
    this.height = newSize.height;
    _aspectRatio = this.aspectRatio;
    if (!retinaScale(this, newRatio, true)) {
      return;
    }

    notifyPlugins('resize', {'size': newSize});

    callback(options['onResize'], [this, newSize], this);

    if (attached) {
      if (_doResize(mode) != 0) {
        // The resize update is delayed, only draw without updating.
        render();
      }
    }
  }

  /// core.controller.js:304 `ensureScalesHaveIDs()`.
  void ensureScalesHaveIDs() {
    final options = this.options;
    final scalesOptions = _or(options['scales'], <String, Object?>{});

    each(scalesOptions, (Object? axisOptions, Object? axisID) {
      (axisOptions! as AnyObject)['id'] = axisID;
    });
  }

  /// core.controller.js:316 `buildOrUpdateScales()`.
  ///
  /// Builds a map of scale ID to scale object for future lookup.
  ///
  /// The items of :333-337 are records. `id in scales` is
  /// [Map.containsKey]. `delete scales[id]` is [Map.remove].
  void buildOrUpdateScales() {
    final options = this.options;
    final scaleOpts = options['scales'];
    final scales = this.scales;
    final updated = jsObjectKeys(scales).fold(<String, Object?>{}, (obj, id) {
      obj[id] = false;
      return obj;
    });
    var items = <({AnyObject options, String dposition, String dtype})>[];

    if (jsTruthy(scaleOpts)) {
      final scaleOptionsById = scaleOpts! as AnyObject;
      items = [
        ...items,
        ...jsObjectKeys(scaleOptionsById).map((id) {
          final scaleOptions = scaleOptionsById[id]! as AnyObject;
          final axis = determineAxis(id, [scaleOptions]);
          final isRadial = axis == 'r';
          final isHorizontal = axis == 'x';
          return (
            options: scaleOptions,
            dposition: isRadial
                ? 'chartArea'
                : isHorizontal
                ? 'bottom'
                : 'left',
            dtype: isRadial
                ? 'radialLinear'
                : isHorizontal
                ? 'category'
                : 'linear',
          );
        }),
      ];
    }

    each(items, (
      ({AnyObject options, String dposition, String dtype}) item,
    ) {
      final scaleOptions = item.options;
      final id = scaleOptions['id']! as String;
      final axis = determineAxis(id, [scaleOptions]);
      final scaleType = valueOrDefault<Object?>(
        scaleOptions['type'],
        item.dtype,
      );

      if (identical(scaleOptions['position'], undefined) ||
          _positionIsHorizontal(scaleOptions['position'], axis) !=
              _positionIsHorizontal(item.dposition)) {
        scaleOptions['position'] = item.dposition;
      }

      updated[id] = true;
      Scale? scale;
      if (scales.containsKey(id) && scales[id]!.type == scaleType) {
        scale = scales[id];
      } else {
        final scaleClass = registry.getScale(scaleType);
        // DIVERGES(chartjs): adapt-component-class-role, cast throws earlier.
        scale = jsConstruct(scaleClass, [
          <String, Object?>{
            'id': id,
            'type': scaleType,
            'ctx': ctx,
            'chart': this,
          },
        ]) as Scale;
        scales[scale.id] = scale;
      }

      scale!.init(scaleOptions, options);
    });
    // clear up discarded scales
    each(updated, (Object? hasUpdated, Object? id) {
      if (!jsTruthy(hasUpdated)) {
        scales.remove(id);
      }
    });

    each(scales, (Scale scale) {
      layouts
        ..configure(this, scale, scale.options)
        ..addBox(this, scale);
    });
  }

  /// core.controller.js:385 `_updateMetasets()`.
  /// @private
  ///
  /// The sort of :390 moves the holes to the end, as `Array.prototype.sort`
  /// does, and keeps the order of the other items for the same index.
  void _updateMetasets() {
    final metasets = this.metasets;
    final numData = _datasets.length;
    final numMeta = metasets.length;

    jsSort(metasets, _holesLast<ChartMeta>((a, b) => a.index - b.index));
    if (numMeta > numData) {
      for (var i = numData; i < numMeta; ++i) {
        _destroyDatasetMeta(i);
      }
      jsSplice(metasets, numData.toDouble(), (numMeta - numData).toDouble());
    }
    sortedMetasets = jsSort(
      List.of(metasets),
      _holesLast(
        _compare2Level<ChartMeta>((meta) => meta.order, (meta) => meta.index),
      ),
    );
  }

  /// core.controller.js:403 `_removeUnreferencedMetasets()`.
  /// @private
  ///
  /// `metasets.forEach` skips the holes and visits the indices below the
  /// length at the start. `x === meta._dataset` is [identical].
  void _removeUnreferencedMetasets() {
    final metasets = this.metasets;
    final datasets = _datasets;
    if (metasets.length > datasets.length) {
      stacks = null;
    }
    for (var index = 0, length = metasets.length; index < length; index++) {
      final meta = index < metasets.length ? metasets[index] : null;
      if (meta == null) continue;
      if (!datasets.any((x) => identical(x, meta.dataset_))) {
        _destroyDatasetMeta(index);
      }
    }
  }

  /// core.controller.js:415 `buildOrUpdateControllers()`.
  ///
  /// `Object.assign(ControllerClass, {...})` is [jsAssign]. The map literal
  /// keeps the key order of upstream: both `getElement` calls occur first.
  /// `new ControllerClass(this, i)` is [jsConstruct] with the index as a
  /// `double` (Chart.js ADR 0020, section 4).
  List<DatasetController> buildOrUpdateControllers() {
    final newControllers = <DatasetController>[];
    final datasets = _datasets;

    _removeUnreferencedMetasets();

    for (var i = 0, ilen = datasets.length; i < ilen; i++) {
      final dataset = jsGetIndex(datasets, i.toDouble());
      var meta = getDatasetMeta(i.toDouble());
      final datasetType = jsGet(dataset, 'type');
      final type = jsTruthy(datasetType) ? datasetType : config.type;

      if (jsTruthy(meta._type) && meta._type != type) {
        _destroyDatasetMeta(i);
        meta = getDatasetMeta(i.toDouble());
      }
      meta._type = type;
      final indexAxis = jsGet(dataset, 'indexAxis');
      meta
        ..indexAxis =
            (jsTruthy(indexAxis) ? indexAxis : getIndexAxis(type, options))!
                as String
        ..order = jsOrZero(jsGet(dataset, 'order'))
        ..index = i.toDouble()
        ..label = jsToString(jsGet(dataset, 'label'))
        ..visible = isDatasetVisible(i.toDouble());

      final controller = meta.controller;
      if (controller != null) {
        controller
          ..updateIndex(i.toDouble())
          ..linkScales();
      } else {
        final controllerClass = registry.getController(type);
        final datasetDefaults = jsGet(defaults['datasets'], type);
        final datasetElementType = jsGet(datasetDefaults, 'datasetElementType');
        final dataElementType = jsGet(datasetDefaults, 'dataElementType');
        jsAssign(controllerClass, {
          'dataElementType': registry.getElement(dataElementType),
          'datasetElementType': jsTruthy(datasetElementType)
              ? registry.getElement(datasetElementType)
              : datasetElementType,
        });
        // DIVERGES(chartjs): adapt-component-class-role, cast throws earlier.
        meta.controller = jsConstruct(controllerClass, [
          this,
          i.toDouble(),
        ]) as DatasetController;
        newControllers.add(meta.controller!);
      }
    }

    _updateMetasets();
    return newControllers;
  }

  /// core.controller.js:461 `_resetElements()`.
  ///
  /// Reset the elements of all datasets
  /// @private
  void _resetElements() {
    each(_datasets, (Object? dataset, double datasetIndex) {
      getDatasetMeta(datasetIndex).controller!.reset();
    }, this);
  }

  /// core.controller.js:470 `reset()`.
  ///
  /// Resets the chart back to its state before the initial animation
  void reset() {
    _resetElements();
    notifyPlugins('reset');
  }

  /// core.controller.js:475 `update(mode)`.
  ///
  /// [mode] is an update mode `String`, a function of the context
  /// `{datasetIndex}`, or [undefined] for an absent argument (index.d.ts:559).
  /// The hooks get it as it is.
  @override
  void update([Object? mode = undefined]) {
    final config = this.config..update();
    final options = _options = config.createResolver(
      config.chartOptionScopes(),
      getContext(),
    );
    final animsDisabled = animationsDisabled = !jsTruthy(options['animation']);

    _updateScales();
    _checkEventBindings();
    _updateHiddenIndices();

    // plugins options references might have change, let's invalidate the
    // cache
    // https://github.com/chartjs/Chart.js/issues/5111#issuecomment-355934167
    plugins.invalidate();

    if (notifyPlugins('beforeUpdate', {'mode': mode, 'cancelable': true}) ==
        false) {
      return;
    }

    // Make sure dataset controllers are updated and new controllers are
    // reset
    final newControllers = buildOrUpdateControllers();

    notifyPlugins('beforeElementsUpdate');

    // Make sure all dataset controllers have correct meta data counts
    var minPadding = 0.0;
    for (var i = 0, ilen = _datasets.length; i < ilen; i++) {
      final controller = getDatasetMeta(i.toDouble()).controller;
      final reset = !animsDisabled && !newControllers.contains(controller);
      // New controllers will be reset after the layout pass, so we only want
      // to modify elements added to new datasets
      controller!.buildOrUpdateElements(reset);
      minPadding = jsMax(jsToNumber(controller.getMaxOverflow()), minPadding);
    }
    minPadding = _minPadding = jsTruthy(jsGet(options['layout'], 'autoPadding'))
        ? minPadding
        : 0;
    _updateLayout(minPadding);

    // Only reset the controllers if we have animations
    if (!animsDisabled) {
      // Can only reset the new controllers after the scales have been
      // updated
      // Reset is done to get the starting point for the initial animation
      each(newControllers, (DatasetController controller) {
        controller.reset();
      });
    }

    _updateDatasets(mode);

    // Do this before render so that any plugins that need final scale
    // updates can use it
    notifyPlugins('afterUpdate', {'mode': mode});

    jsSort(
      _layers,
      _compare2Level<LayoutLayer>((layer) => layer.z, (layer) => layer.idx),
    );

    // Replay last event from before update, or set hover styles on active
    // elements
    final active = this.active;
    final lastEvent = _lastEvent;
    if (lastEvent != null) {
      eventHandler(lastEvent, true);
    } else if (active.isNotEmpty) {
      _updateHoverStyles(active, active, true);
    }

    render();
  }

  /// core.controller.js:542 `_updateScales()`.
  /// @private
  void _updateScales() {
    each(scales, (Scale scale) {
      layouts.removeBox(this, scale);
    });

    ensureScalesHaveIDs();
    buildOrUpdateScales();
  }

  /// core.controller.js:554 `_checkEventBindings()`.
  /// @private
  ///
  /// `new Set(options.events)` takes the items of the List. `!!x !==
  /// options.responsive` is `!=`: a `bool` is not equal to a value of
  /// another type, as for `!==`.
  void _checkEventBindings() {
    final options = this.options;
    final existingEvents = Set<Object?>.of(jsObjectKeys(_listeners));
    final newEvents = _setOf(options['events']);

    if (!setsEqual(existingEvents, newEvents) ||
        (_responsiveListeners != null) != options['responsive']) {
      // The configured events have changed. Rebind.
      unbindEvents();
      bindEvents();
    }
  }

  /// core.controller.js:569 `_updateHiddenIndices()`.
  /// @private
  void _updateHiddenIndices() {
    final hiddenIndices = _hiddenIndices;
    final changes = _getUniformDataChanges() ?? const [];
    for (final (:method, :start, :count) in changes) {
      final move = method == '_removeElements' ? -count : count;
      _moveNumericKeys(hiddenIndices, start, move);
    }
  }

  /// core.controller.js:581 `_getUniformDataChanges()`.
  /// @private
  ///
  /// Dart `null` stands for the `undefined` result. `c.splice(1)` changes
  /// the change array `c`, as upstream. `join(',')` gives the `ToString` of
  /// each item. `+a[2]` is [jsToNumber]. The objects `{method, start,
  /// count}` are records.
  List<({String method, double start, double count})>?
  _getUniformDataChanges() {
    final dataChanges = this.dataChanges;
    if (dataChanges.isEmpty) {
      return null;
    }

    this.dataChanges = [];
    final datasetCount = _datasets.length;
    Set<String> makeSet(int idx) {
      final set = <String>{};
      var i = 0;
      for (final c in dataChanges) {
        if (c[0] == idx) {
          set.add('$i,${_join(jsSplice(c, 1))}');
          i++;
        }
      }
      return set;
    }

    final changeSet = makeSet(0);
    for (var i = 1; i < datasetCount; i++) {
      if (!setsEqual(changeSet, makeSet(i))) {
        return null;
      }
    }
    return changeSet
        .map((c) => c.split(','))
        .map(
          (a) =>
              (method: a[1], start: jsToNumber(a[2]), count: jsToNumber(a[3])),
        )
        .toList();
  }

  /// core.controller.js:611 `_updateLayout(minPadding)`.
  ///
  /// Updates the chart layout unless a plugin returns `false` to the
  /// `beforeLayout` hook, in which case, plugins will not be called on
  /// `afterLayout`.
  /// @private
  ///
  /// `box.configure` is the test for [LayoutItemConfigure]. `box._layers()`
  /// is the function of [LayoutItem.layers], which `layouts.addBox` always
  /// writes. `item._idx` is [LayoutLayer.idx].
  void _updateLayout(double minPadding) {
    if (notifyPlugins('beforeLayout', {'cancelable': true}) == false) {
      return;
    }

    layouts.update(this, width, height, minPadding);

    final area = chartArea!;
    final noArea = area.width <= 0 || area.height <= 0;

    _layers = [];
    each(boxes, (LayoutItem box) {
      if (noArea && box.position == 'chartArea') {
        // Skip drawing and configuring chartArea boxes when chartArea is
        // zero or negative
        return;
      }

      // configure is called twice, once in core.scale.update and once here.
      // Here the boxes are fully updated and at their final positions.
      if (box is LayoutItemConfigure) {
        box.configure();
      }
      _layers.addAll(box.layers!());
    }, this);

    for (var index = 0; index < _layers.length; index++) {
      _layers[index].idx = index.toDouble();
    }

    notifyPlugins('afterLayout');
  }

  /// core.controller.js:648 `_updateDatasets(mode)`.
  ///
  /// Updates all datasets unless a plugin returns `false` to the
  /// `beforeDatasetsUpdate` hook, in which case, plugins will not be called
  /// on `afterDatasetsUpdate`.
  /// @private
  ///
  /// `mode({datasetIndex: i})` is [jsCall] of the function value.
  void _updateDatasets(Object? mode) {
    if (notifyPlugins('beforeDatasetsUpdate', {
          'mode': mode,
          'cancelable': true,
        }) ==
        false) {
      return;
    }

    for (var i = 0, ilen = _datasets.length; i < ilen; ++i) {
      getDatasetMeta(i.toDouble()).controller!.configure();
    }

    for (var i = 0, ilen = _datasets.length; i < ilen; ++i) {
      _updateDataset(
        i,
        isFunction(mode)
            ? jsCall(mode, [
                <String, Object?>{'datasetIndex': i.toDouble()},
              ])
            : mode,
      );
    }

    notifyPlugins('afterDatasetsUpdate', {'mode': mode});
  }

  /// core.controller.js:669 `_updateDataset(index, mode)`.
  ///
  /// Updates dataset at index unless a plugin returns `false` to the
  /// `beforeDatasetUpdate` hook, in which case, plugins will not be called
  /// on `afterDatasetUpdate`.
  /// @private
  ///
  /// `meta.controller._update(mode)` is `update_` (Chart.js ADR 0023). It
  /// takes a `String`: [_modeArg] gives the falsy modes as Dart `null`.
  void _updateDataset(int index, Object? mode) {
    final meta = getDatasetMeta(index.toDouble());
    final args = <String, Object?>{
      'meta': meta,
      'index': index.toDouble(),
      'mode': mode,
      'cancelable': true,
    };

    if (notifyPlugins('beforeDatasetUpdate', args) == false) {
      return;
    }

    meta.controller!.update_(_modeArg(mode));

    args['cancelable'] = false;
    notifyPlugins('afterDatasetUpdate', args);
  }

  /// core.controller.js:683 `render()`.
  void render() {
    if (notifyPlugins('beforeRender', {'cancelable': true}) == false) {
      return;
    }

    if (animator.has(this)) {
      if (attached && !animator.running(this)) {
        animator.start(this);
      }
    } else {
      draw();
      _onAnimationsComplete(AnimationEvent(chart: this));
    }
  }

  /// core.controller.js:698 `draw()`.
  @override
  void draw() {
    int i;
    final resizeBeforeDraw = _resizeBeforeDraw;
    if (resizeBeforeDraw != null) {
      final (:width, :height) = resizeBeforeDraw;
      // Unset pending resize request now to avoid possible recursion within
      // _resize
      _resizeBeforeDraw = null;
      _resize(width, height);
    }
    clear();

    if (width <= 0 || height <= 0) {
      return;
    }

    if (notifyPlugins('beforeDraw', {'cancelable': true}) == false) {
      return;
    }

    // Because of plugin hooks (before/afterDatasetsDraw), datasets can't
    // currently be part of layers. Instead, we draw
    // layers <= 0 before(default, backward compat), and the rest after
    final layers = _layers;
    for (i = 0; i < layers.length && layers[i].z <= 0; ++i) {
      layers[i].draw(chartArea!);
    }

    _drawDatasets();

    // Rest of layers
    for (; i < layers.length; ++i) {
      layers[i].draw(chartArea!);
    }

    notifyPlugins('afterDraw');
  }

  /// core.controller.js:737 `_getSortedDatasetMetas(filterVisible)`.
  /// @private
  ///
  /// `meta.visible` is a ToBoolean test: the `hide` animation writes
  /// numbers (Chart.js ADR 0019, section 9). A hole of the sorted metas
  /// throws a [TypeError], as the read `meta.visible` of `undefined` does.
  @internal
  @override
  List<ChartMeta> getSortedDatasetMetas(
    bool filterVisible,
  ) {
    final metasets = sortedMetasets;
    final result = <ChartMeta>[];

    for (var i = 0, ilen = metasets.length; i < ilen; ++i) {
      final meta = metasets[i]!;
      if (!filterVisible || jsTruthy(meta.visible)) {
        result.add(meta);
      }
    }

    return result;
  }

  /// core.controller.js:756 `getSortedVisibleDatasetMetas()`.
  ///
  /// Gets the visible dataset metas in drawing order
  /// @return {object[]}
  @override
  List<ChartMeta> getSortedVisibleDatasetMetas() {
    return getSortedDatasetMetas(true);
  }

  /// core.controller.js:765 `_drawDatasets()`.
  ///
  /// Draws all datasets unless a plugin returns `false` to the
  /// `beforeDatasetsDraw` hook, in which case, plugins will not be called on
  /// `afterDatasetsDraw`.
  /// @private
  void _drawDatasets() {
    if (notifyPlugins('beforeDatasetsDraw', {'cancelable': true}) == false) {
      return;
    }

    final metasets = getSortedVisibleDatasetMetas();
    for (var i = metasets.length - 1; i >= 0; --i) {
      _drawDataset(metasets[i]);
    }

    notifyPlugins('afterDatasetsDraw');
  }

  /// core.controller.js:783 `_drawDataset(meta)`.
  ///
  /// Draws dataset at index unless a plugin returns `false` to the
  /// `beforeDatasetDraw` hook, in which case, plugins will not be called on
  /// `afterDatasetDraw`.
  /// @private
  ///
  /// `getDatasetClipArea` gives Dart `null` for the upstream `false`.
  void _drawDataset(ChartMeta meta) {
    final ctx = this.ctx;
    final args = <String, Object?>{
      'meta': meta,
      'index': meta.index,
      'cancelable': true,
    };
    final clip = getDatasetClipArea(this, meta);

    if (notifyPlugins('beforeDatasetDraw', args) == false) {
      return;
    }

    if (clip != null) {
      clipArea(ctx!, clip);
    }

    meta.controller!.draw();

    if (clip != null) {
      unclipArea(ctx!);
    }

    args['cancelable'] = false;
    notifyPlugins('afterDatasetDraw', args);
  }

  /// core.controller.js:816 `isPointInArea(point)`.
  ///
  /// Checks whether the given point is in the chart area.
  /// @param {Point} point - in relative coordinates (see, e.g.,
  /// getRelativePosition)
  /// @returns {boolean}
  @override
  bool isPointInArea(types.Point point) {
    return helpers.isPointInArea(point, chartArea, _minPadding);
  }

  /// core.controller.js:820 `getElementsAtEventForMode(e, mode, options,
  /// useFinalPosition)`.
  ///
  /// [e] is a `types.ChartEvent` or a `NativeEvent`, as the modes take it.
  /// `Interaction.modes[mode]` reads the key `ToString(mode)`. A mode
  /// function needs the options as a Map: another value throws a
  /// [TypeError].
  List<InteractionItem> getElementsAtEventForMode(
    Object e,
    Object? mode,
    Object? options, [
    // The upstream signature has a positional `useFinalPosition`.
    // ignore: avoid_positional_boolean_parameters
    bool? useFinalPosition,
  ]) {
    final method = Interaction.modes[mode is String ? mode : jsToString(mode)];
    if (method != null) {
      return method(this, e, options! as AnyObject, useFinalPosition);
    }

    return [];
  }

  /// core.controller.js:829 `getDatasetMeta(datasetIndex)`.
  ///
  /// `filter(x => x && x._dataset === dataset).pop()` gives the last meta of
  /// the dataset object, by [identical].
  @override
  ChartMeta getDatasetMeta(double datasetIndex) {
    final dataset = jsGetIndex(_datasets, datasetIndex);
    final metasets = this.metasets;
    ChartMeta? meta;
    for (var i = metasets.length - 1; i >= 0; i--) {
      final x = metasets[i];
      if (x != null && identical(x.dataset_, dataset)) {
        meta = x;
        break;
      }
    }

    if (meta == null) {
      meta = ChartMeta._(
        // See isDatasetVisible() comment
        order: jsTruthy(dataset) ? jsOrZero(jsGet(dataset, 'order')) : 0,
        index: datasetIndex,
        dataset_: dataset,
      );
      metasets.add(meta);
    }

    return meta;
  }

  /// core.controller.js:855 `getContext()`.
  @override
  AnyObject getContext() {
    return $context ??= createContext(null, {'chart': this, 'type': 'chart'});
  }

  /// core.controller.js:859 `getVisibleDatasetCount()`.
  @override
  double getVisibleDatasetCount() {
    return getSortedVisibleDatasetMetas().length.toDouble();
  }

  /// core.controller.js:863 `isDatasetVisible(datasetIndex)`.
  @override
  bool isDatasetVisible(double datasetIndex) {
    final dataset = jsGetIndex(_datasets, datasetIndex);
    if (!jsTruthy(dataset)) {
      return false;
    }

    final meta = getDatasetMeta(datasetIndex);

    // meta.hidden is a per chart dataset hidden flag override with 3 states:
    // if true or false, the dataset.hidden value is ignored, else if null,
    // the dataset hidden state is returned.
    final hidden = meta.hidden;
    return hidden != null ? !hidden : !jsTruthy(jsGet(dataset, 'hidden'));
  }

  /// core.controller.js:876 `setDatasetVisibility(datasetIndex, visible)`.
  void setDatasetVisibility(
    double datasetIndex,
    // The upstream signature has a positional `visible`.
    // ignore: avoid_positional_boolean_parameters
    bool visible,
  ) {
    getDatasetMeta(datasetIndex).hidden = !visible;
  }

  /// core.controller.js:881 `toggleDataVisibility(index)`.
  ///
  /// [index] is any JS value: `_hiddenIndices[index]` uses the property key
  /// `ToString(index)` ([jsToString]). Thus the legend item index `'01'`
  /// writes the key `'01'`, and the item index `null` writes `'null'`. No
  /// data index has these keys, but `_updateHiddenIndices` moves the key
  /// `'01'` after a data insert or remove, as upstream (core.controller.js:72).
  @override
  void toggleDataVisibility(Object? index) {
    final key = jsToString(index);
    _hiddenIndices[key] = !jsTruthy(_hiddenIndices[key]);
  }

  /// core.controller.js:885 `getDataVisibility(index)`.
  ///
  /// An empty `_hiddenIndices` gives `undefined` for each key, and the
  /// upstream line gives true. The early return skips the key string in that
  /// state (Chart.js ADR 0028, section 4).
  @override
  bool getDataVisibility(double index) {
    // Port-only fast path with the upstream result (Chart.js ADR 0028,
    // section 4).
    if (_hiddenIndices.isEmpty) return true;
    return !jsTruthy(_hiddenIndices[jsNumberToString(index)]);
  }

  /// core.controller.js:892 `_updateVisibility(datasetIndex, dataIndex,
  /// visible)`.
  /// @private
  ///
  /// Dart `null` for [dataIndex] stands for JS `undefined`. Thus
  /// `defined(dataIndex)` is a test for a value.
  /// `meta.controller._resolveAnimations(undefined, mode)` is
  /// `resolveAnimations` (Chart.js ADR 0012). `meta.data[dataIndex].hidden`
  /// is a write of [Element.hidden]. An index without an element throws
  /// a [TypeError], as in JavaScript.
  void _updateVisibility(
    double datasetIndex,
    double? dataIndex,
    bool visible,
  ) {
    final mode = visible ? 'show' : 'hide';
    final meta = getDatasetMeta(datasetIndex);
    final anims = meta.controller!.resolveAnimations(null, mode);

    if (dataIndex != null) {
      (_elementAt(meta.data, dataIndex)! as Element).hidden = !visible;
      update();
    } else {
      setDatasetVisibility(datasetIndex, visible);
      // Animate visible state, so hide animation can be seen. This could be
      // handled better if update / updateDataset returned a Promise.
      anims.update(meta, {'visible': visible});
      update(
        (Object? ctx) =>
            jsGet(ctx, 'datasetIndex') == datasetIndex ? mode : undefined,
      );
    }
  }

  /// core.controller.js:908 `hide(datasetIndex, dataIndex)`.
  ///
  /// Dart `null` for [dataIndex] stands for an absent argument.
  void hide(double datasetIndex, [double? dataIndex]) {
    _updateVisibility(datasetIndex, dataIndex, false);
  }

  /// core.controller.js:912 `show(datasetIndex, dataIndex)`.
  ///
  /// Dart `null` for [dataIndex] stands for an absent argument.
  void show(double datasetIndex, [double? dataIndex]) {
    _updateVisibility(datasetIndex, dataIndex, true);
  }

  /// core.controller.js:919 `_destroyDatasetMeta(datasetIndex)`.
  /// @private
  ///
  /// `meta.controller._destroy()` is `destroy` (Chart.js ADR 0012).
  /// `delete this._metasets[datasetIndex]` leaves a hole, Dart `null`, for
  /// an index below the length, and changes nothing for another index.
  void _destroyDatasetMeta(int datasetIndex) {
    final metasets = this.metasets;
    final meta = datasetIndex < metasets.length ? metasets[datasetIndex] : null;
    if (meta != null && meta.controller != null) {
      meta.controller!.destroy();
    }
    if (datasetIndex < metasets.length) {
      metasets[datasetIndex] = null;
    }
  }

  /// core.controller.js:927 `_stop()`.
  void _stop() {
    stop();
    animator.remove(this);

    for (var i = 0, ilen = _datasets.length; i < ilen; ++i) {
      _destroyDatasetMeta(i);
    }
  }

  /// core.controller.js:937 `destroy()`.
  ///
  /// A second call does not throw: the canvas part runs only while the chart
  /// has a canvas, and the plugins get no hook after `uninstall`.
  ///
  /// The port also cancels the pending debounced update of a resize, so
  /// that no `update()` reaches a destroyed chart and no `Timer` stays
  /// pending (Chart.js ADR 0016, decision 4).
  void destroy() {
    notifyPlugins('beforeDestroy');
    final canvas = this.canvas;
    final ctx = this.ctx;

    _stop();
    // DIVERGES(chartjs): platform-destroy-cancel-resize, cancel the timer.
    _doResize.cancel();
    config.clearCache();

    if (canvas != null) {
      unbindEvents();
      clearCanvas(canvas, ctx);
      platform.releaseContext(ctx!);
      this.canvas = null;
      this.ctx = null;
    }

    instances.remove(jsNumberToString(id));

    notifyPlugins('afterDestroy');
  }

  /// core.controller.js:957 `toBase64Image(...args)`.
  ///
  /// Upstream returns `this.canvas.toDataURL(...args)`, a synchronous data
  /// URL of the bitmap. `dart:ui` encodes an image only asynchronously, and
  /// the canvas layer has no `toDataURL` (Chart.js ADR 0013). Thus the port
  /// throws an [UnsupportedError]. The public API of phase 9 decides an
  /// asynchronous form.
  String toBase64Image([String? type, Object? quality]) {
    // DIVERGES(chartjs): platform-to-base64-image, no synchronous toDataURL.
    throw UnsupportedError(
      'toBase64Image: the canvas layer has no synchronous toDataURL.',
    );
  }

  /// core.controller.js:964 `bindEvents()`.
  /// @private
  void bindEvents() {
    bindUserEvents();
    if (jsTruthy(options['responsive'])) {
      bindResponsiveEvents();
    } else {
      attached = true;
    }
  }

  /// core.controller.js:976 `bindUserEvents()`.
  /// @private
  ///
  /// The event listener of a platform takes the chart event alone (Chart.js
  /// ADR 0014, section 8). Thus `(e, x, y)` and the writes `e.offsetX = x`
  /// and `e.offsetY = y` (:985-987) have no Dart form. The platforms of
  /// upstream also pass one argument (platform.dom.js:247-249). Thus `x` and
  /// `y` are `undefined` there, and a read of `e.offsetX` gives
  /// `undefined` in both.
  void bindUserEvents() {
    final listeners = _listeners;
    final platform = this.platform;

    void add(String type, Function listener) {
      platform.addEventListener(this, type, listener);
      listeners[type] = listener;
    }

    void listener(types.ChartEvent e) {
      eventHandler(e);
    }

    each(options['events'], (Object? type) {
      add(type is String ? type : jsToString(type), listener);
    });
  }

  /// core.controller.js:997 `bindResponsiveEvents()`.
  /// @private
  ///
  /// The listeners have the shapes of Chart.js ADR 0014, section 8:
  /// `void Function([double? width, double? height])` for `'resize'`, and
  /// `void Function()` for `'attach'` and `'detach'`.
  void bindResponsiveEvents() {
    final listeners = _responsiveListeners ??= {};
    final platform = this.platform;

    void add(String type, Function listener) {
      platform.addEventListener(this, type, listener);
      listeners[type] = listener;
    }

    void remove(String type, Function listener) {
      if (listeners[type] != null) {
        platform.removeEventListener(this, type, listener);
        listeners.remove(type);
      }
    }

    void listener([double? width, double? height]) {
      if (canvas != null) {
        resize(width, height);
      }
    }

    late final void Function() detached;
    void attached() {
      remove('attach', attached);

      this.attached = true;
      resize();

      add('resize', listener);
      add('detach', detached);
    }

    detached = () {
      this.attached = false;

      remove('resize', listener);

      // Stop animating and remove metasets, so when re-attached, the
      // animations start from beginning.
      _stop();
      _resize(0, 0);

      add('attach', attached);
    };

    if (platform.isAttached(canvas)) {
      attached();
    } else {
      detached();
    }
  }

  /// core.controller.js:1054 `unbindEvents()`.
  /// @private
  void unbindEvents() {
    each(_listeners, (Function listener, String type) {
      platform.removeEventListener(this, type, listener);
    });
    _listeners = {};

    each(_responsiveListeners, (Function listener, String type) {
      platform.removeEventListener(this, type, listener);
    });
    _responsiveListeners = null;
  }

  /// core.controller.js:1066 `updateHoverStyle(items, mode, enabled)`.
  ///
  /// `controller['_' + prefix + 'DatasetHoverStyle']()` and
  /// `controller[prefix + 'HoverStyle'](...)` call the method of the prefix:
  /// `setDatasetHoverStyle` or `removeDatasetHoverStyle` (Chart.js ADR
  /// 0012), and `setHoverStyle` or `removeHoverStyle`. An item without an
  /// element throws a [TypeError], as the hover style of `undefined` does.
  void updateHoverStyle(
    List<types.ActiveElement> items,
    Object? mode,
    // The upstream signature has a positional `enabled`.
    // ignore: avoid_positional_boolean_parameters
    bool enabled,
  ) {
    final prefix = enabled ? 'set' : 'remove';
    ChartMeta meta;

    if (mode == 'dataset') {
      meta = getDatasetMeta((items.isNotEmpty ? items[0] : null)!.datasetIndex);
      final controller = meta.controller!;
      if (prefix == 'set') {
        controller.setDatasetHoverStyle();
      } else {
        controller.removeDatasetHoverStyle();
      }
    }

    for (var i = 0, ilen = items.length; i < ilen; ++i) {
      final item = items[i];
      final controller = getDatasetMeta(item.datasetIndex).controller;
      if (controller != null) {
        final element = item.element! as Element;
        if (prefix == 'set') {
          controller.setHoverStyle(element, item.datasetIndex, item.index);
        } else {
          controller.removeHoverStyle(element, item.datasetIndex, item.index);
        }
      }
    }
  }

  /// core.controller.js:1088 `getActiveElements()`.
  ///
  /// Get active (hovered) elements
  /// @returns array
  List<types.ActiveElement> getActiveElements() {
    return active;
  }

  /// core.controller.js:1096 `setActiveElements(activeElements)`.
  ///
  /// Set active (hovered) elements
  /// @param {array} activeElements New active data points
  ///
  /// An item is a `types.ActiveDataPoint` or an object `{datasetIndex,
  /// index}`, a Map (Chart.js ADR 0006). The destructuring reads the Map
  /// with [jsGet] and gives the `ToNumber` of each value.
  void setActiveElements(List<Object?> activeElements) {
    final lastActive = active;
    final newActive = activeElements.map((item) {
      final double datasetIndex;
      final double index;
      if (item is types.ActiveDataPoint) {
        datasetIndex = item.datasetIndex;
        index = item.index;
      } else {
        datasetIndex = jsToNumber(jsGet(item, 'datasetIndex'));
        index = jsToNumber(jsGet(item, 'index'));
      }
      final meta = getDatasetMeta(datasetIndex);
      // `if (!meta) throw new Error('No dataset found at index ' + ...)`:
      // getDatasetMeta always gives a meta. Thus upstream never throws here.

      return _ActiveElement(
        datasetIndex: datasetIndex,
        element: _elementAt(meta.data, index),
        index: index,
      );
    }).toList();
    final changed = !elementsEqual(newActive, lastActive);

    if (changed) {
      active = newActive;
      // Make sure we don't use the previous mouse event to override the
      // active elements in update.
      _lastEvent = null;
      _updateHoverStyles(newActive, lastActive);
    }
  }

  /// core.controller.js:1129 `notifyPlugins(hook, args, filter)`.
  ///
  /// Calls enabled plugins on the specified hook and with the given args.
  /// This method immediately returns as soon as a plugin explicitly returns
  /// false. The returned value can be used, for instance, to interrupt the
  /// current action.
  /// @param {string} hook - The name of the plugin method to call (e.g.
  /// 'beforeUpdate').
  /// @param {Object} [args] - Extra arguments to apply to the hook call.
  /// @param {import('./core.plugins.js').filterCallback} [filter] -
  /// Filtering function for limiting which plugins are notified
  /// @returns {boolean} false if any of the plugins return false, else
  /// returns true.
  ///
  /// Dart `null` for the result stands for the `undefined` of
  /// `PluginService.notify` before `install` and after `uninstall`.
  @override
  bool? notifyPlugins(String hook, [AnyObject? args, FilterCallback? filter]) {
    return plugins.notify(this, hook, args, filter);
  }

  /// core.controller.js:1138 `isPluginEnabled(pluginId)`.
  ///
  /// Check if a plugin with the specific ID is registered and enabled
  /// @param {string} pluginId - The ID of the plugin of which to check if it
  /// is enabled
  /// @returns {boolean}
  ///
  /// `_cache` is `cache` (Chart.js ADR 0020, section 7). Before the first
  /// notify, it is Dart `null`: the read throws a [TypeError], as the
  /// `filter` of `undefined` does.
  @override
  bool isPluginEnabled(String pluginId) {
    return plugins.cache!
            .where((p) => jsGet(p.plugin, 'id') == pluginId)
            .length ==
        1;
  }

  /// core.controller.js:1145 `_updateHoverStyles(active, lastActive,
  /// replay)`.
  /// @private
  void _updateHoverStyles(
    List<types.ActiveElement> active,
    List<types.ActiveElement> lastActive, [
    bool? replay,
  ]) {
    final hoverOptions = options['hover'];
    List<types.ActiveElement> diff(
      List<types.ActiveElement> a,
      List<types.ActiveElement> b,
    ) => a
        .where(
          (x) => !b.any(
            (y) => x.datasetIndex == y.datasetIndex && x.index == y.index,
          ),
        )
        .toList();
    final deactivated = diff(lastActive, active);
    final activated = jsTruthy(replay) ? active : diff(active, lastActive);

    if (deactivated.isNotEmpty) {
      updateHoverStyle(deactivated, jsGet(hoverOptions, 'mode'), false);
    }

    if (activated.isNotEmpty && jsTruthy(jsGet(hoverOptions, 'mode'))) {
      updateHoverStyle(activated, jsGet(hoverOptions, 'mode'), true);
    }
  }

  /// core.controller.js:1163 `_eventHandler(e, replay)`.
  ///
  /// It drops the underscore, because chartjs-test-utils reads it
  /// (`src/utils.js:140-141`, Chart.js ADR 0012). A test can replace the
  /// function of one chart, as it replaces a JS own property (Chart.js ADR
  /// 0022, section 5). Each upstream call of `this._eventHandler` calls
  /// this field. Dart `null` for `replay` stands for an absent argument.
  // DIVERGES(chartjs): harness-method-fields, a test replaces it per chart.
  @internal
  // The upstream signature has a positional `replay`.
  // ignore: avoid_positional_boolean_parameters
  late void Function(types.ChartEvent e, [bool? replay]) eventHandler =
      _eventHandlerMethod;

  /// The upstream body of `_eventHandler` (core.controller.js:1163-1186).
  ///
  /// The event filter reads `plugin.options.events || this.options.events`
  /// and `includes` the type of the native event. Upstream returns `this`.
  void _eventHandlerMethod(
    types.ChartEvent e, [
    bool? replay,
  ]) {
    final args = <String, Object?>{
      'event': e,
      'replay': replay ?? undefined,
      'cancelable': true,
      'inChartArea': isPointInArea(e),
    };
    bool eventFilter(PluginDescriptor plugin) => _includes(
      _or(jsGet(plugin.options, 'events'), options['events']),
      e.native!.type,
    );

    if (notifyPlugins('beforeEvent', args, eventFilter) == false) {
      return;
    }

    final changed = handleEvent(e, replay, args['inChartArea']);

    args['cancelable'] = false;
    notifyPlugins('afterEvent', args, eventFilter);

    if (changed || jsTruthy(args['changed'])) {
      render();
    }
  }

  /// core.controller.js:1196 `_handleEvent(e, replay, inChartArea)`.
  ///
  /// Handle an event
  /// @param {ChartEvent} e the event to handle
  /// @param {boolean} [replay] - true if the event was replayed by `update`
  /// @param {boolean} [inChartArea] - true if the event is inside chartArea
  /// @return {boolean} true if the chart needs to re-render
  /// @private
  ///
  /// It drops the underscore, because a spec reads it
  /// (controller.line.tests.js:1067, Chart.js ADR 0012). [inChartArea] is the
  /// value of `args.inChartArea`: the tests are ToBoolean tests.
  @internal
  bool handleEvent(
    types.ChartEvent e, [
    // The upstream signature has a positional `replay`.
    // ignore: avoid_positional_boolean_parameters
    bool? replay,
    Object? inChartArea,
  ]) {
    final lastActive = this.active;
    final options = this.options;

    // If the event is replayed from `update`, we should evaluate with the
    // final positions.
    //
    // The `replay`:
    // It's the last event (excluding click) that has occurred before
    // `update`. So mouse has not moved. It's also over the chart, because
    // there is a `replay`.
    //
    // The why:
    // If animations are active, the elements haven't moved yet compared to
    // state before update. But if they will, we are activating the elements
    // that would be active, if this check was done after the animations have
    // completed. => "final positions". If there is no animations, the
    // "final" and "current" positions are equal. This is done so we do not
    // have to evaluate the active elements each animation frame - it would
    // be expensive.
    final useFinalPosition = replay;
    final active = _getActiveElements(
      e,
      lastActive,
      inChartArea,
      useFinalPosition,
    );
    final isClick = isClickEvent(e);
    final lastEvent = _determineLastEvent(e, _lastEvent, inChartArea, isClick);

    if (jsTruthy(inChartArea)) {
      // Set _lastEvent to null while we are processing the event handlers.
      // This prevents recursion if the handler calls chart.update()
      _lastEvent = null;

      // Invoke onHover hook
      callback(options['onHover'], [e, active, this], this);

      if (isClick) {
        callback(options['onClick'], [e, active, this], this);
      }
    }

    final changed = !elementsEqual(active, lastActive);
    if (changed || jsTruthy(replay)) {
      this.active = active;
      _updateHoverStyles(active, lastActive, replay);
    }

    _lastEvent = lastEvent;

    return changed;
  }

  /// core.controller.js:1249 `_getActiveElements(e, lastActive,
  /// inChartArea, useFinalPosition)`.
  ///
  /// @param {ChartEvent} e - The event
  /// @param {import('../types/index.js').ActiveElement[]} lastActive -
  /// Previously active elements
  /// @param {boolean} inChartArea - Is the event inside chartArea
  /// @param {boolean} useFinalPosition - Should the evaluation be done with
  /// current or final (after animation) element positions
  /// @returns {import('../types/index.js').ActiveElement[]} - The active
  /// elements
  /// @pravate
  List<types.ActiveElement> _getActiveElements(
    types.ChartEvent e,
    List<types.ActiveElement> lastActive,
    Object? inChartArea, [
    bool? useFinalPosition,
  ]) {
    if (e.type == 'mouseout') {
      return [];
    }

    if (!jsTruthy(inChartArea)) {
      // Let user control the active elements outside chartArea. Eg. using
      // Legend.
      return lastActive;
    }

    final hoverOptions = options['hover'];
    return getElementsAtEventForMode(
      e,
      jsGet(hoverOptions, 'mode'),
      hoverOptions,
      useFinalPosition,
    );
  }

  /// `this.data.datasets`: the List of the datasets. `initData` makes it a
  /// List (core.config.js:124). Another value throws a [TypeError].
  List<Object?> get _datasets => data['datasets']! as List<Object?>;
}

/// core.controller.js:1265 `invalidatePlugins()`.
///
/// `each(Chart.instances, ...)` takes the charts in the `Object.keys` order.
void _invalidatePlugins() {
  each(Chart.instances, (Chart chart) => chart.plugins.invalidate());
}

/// The read `meta.data[index]` of a data element: the element at a whole
/// index below the length, else Dart `null` for JS `undefined`.
types.Element? _elementAt(List<types.Element> data, double index) {
  if (index >= 0 && index < data.length && index == index.truncateToDouble()) {
    return data[index.toInt()];
  }
  return null;
}

/// `value || other`: [value] when it is truthy, else [other].
Object? _or(Object? value, Object? other) => jsTruthy(value) ? value : other;

/// The number of an option for a parameter of type `double?`: Dart `null`
/// for JS `null` and `undefined`, else the `ToNumber` of the value. A falsy
/// value stays falsy.
double? _numberOrNull(Object? value) => switch (value) {
  null || Undefined() => null,
  final num number => number.toDouble(),
  _ => jsToNumber(value),
};

/// The update mode of `DatasetController.update_`: a `String`, or Dart
/// `null` for a falsy mode, which `_update` replaces with `'default'`
/// (core.datasetController.js:703). A truthy value of another type gives its
/// `ToString`, which compares with the mode names as the value does.
String? _modeArg(Object? mode) =>
    mode is String ? mode : (jsTruthy(mode) ? jsToString(mode) : null);

/// `new Set(iterable)` of an option value: the items of a List. JS `null`
/// and `undefined` give an empty set. Another value throws a [TypeError].
///
/// The `Set` constructor throws a `TypeError` for a value that is not
/// iterable. A JS string is iterable, and upstream makes a Set of its
/// characters (core.controller.js:557). The port throws for a string too:
/// `events` is `(keyof HTMLElementEventMap)[]` (index.d.ts:1723). A value
/// that is not a List is outside the upstream type contract, and its throw
/// is not a `DIVERGES` hunk (Chart.js ADR 0017, section 5).
Set<Object?> _setOf(Object? iterable) => switch (iterable) {
  null || Undefined() => <Object?>{},
  final List<Object?> list => Set<Object?>.of(list),
  _ => throw TypeError(),
};

/// `array.includes(value)` of the event filter (core.controller.js:1170).
/// A value that is not a List throws a [TypeError].
///
/// Upstream calls `String.prototype.includes` for a string, a substring
/// test that does not throw. The `events` of a chart and of a plugin are
/// `(keyof HTMLElementEventMap)[]` (index.d.ts:1723, :863). A value that is
/// not a List is outside the upstream type contract, and its throw is not a
/// `DIVERGES` hunk (Chart.js ADR 0017, section 5).
bool _includes(Object? array, Object? value) => switch (array) {
  final List<Object?> list => list.contains(value),
  _ => throw TypeError(),
};

/// `array.join(',')`: the `ToString` of each item, with `''` for JS `null`
/// and `undefined`.
String _join(List<Object?> array) =>
    array.map((item) => isNullOrUndef(item) ? '' : jsToString(item)).join(',');

/// A comparator of the sort of a JS array with holes: the holes, Dart
/// `null`, go to the end, and [compare] orders the other items, as
/// `Array.prototype.sort` does (ECMAScript 23.1.3.30.1).
num Function(T? a, T? b) _holesLast<T extends Object>(
  num Function(T a, T b) compare,
) {
  return (a, b) {
    if (a == null) return b == null ? 0 : 1;
    if (b == null) return -1;
    return compare(a, b);
  };
}

/// `console.error(message)`.
void _consoleError(String message) {
  // console.error has no other counterpart in this layer.
  // ignore: avoid_print
  print(message);
}
