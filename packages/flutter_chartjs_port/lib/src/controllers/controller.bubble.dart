// Ported from Chart.js v4.6.1 src/controllers/controller.bubble.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-typed-parsed, the typed data of Chart.js ADR 0054.

/// Port of `src/controllers/controller.bubble.js`.
///
/// [BubbleController] is the dataset controller of the `bubble` charts. It
/// parses the radius of each item into `_custom`, computes the pixels of
/// each point from the index scale and the value scale, and writes the
/// properties of each `PointElement` through `updateElement`.
///
/// - The parsed data is typed (Chart.js ADR 0054 §8): a parsed item of the
///   parse functions is a [ParsedItem], and its `_custom` the radius. The
///   reads of a parsed value are [parsedValueOf]. A data item is any value
///   (Chart.js ADR 0036): the read `item[2]` is [jsGetIndex], and the read
///   `item.r` is the typed field of a `TypedDataItem`, else a read by name.
///   A parsed item of `parsing: false` is a data item of the user, read by
///   name. The options of a point are a [PointOptions], and the
///   properties a [PointProperties] (Chart.js ADR 0054 §9). The exact
///   controller in a direct mode writes a built-in point with its typed
///   setters, with no object (row `adapt-direct-element-writes`, Chart.js ADR
///   0102).
/// - A raw option value stays `Object?` until its upstream operator. Then
///   the port applies the runtime form of that operator: [jsAdd] for `+=`
///   (Chart.js ADR 0036, section 7).
/// - The controller reads the members of other modules through
///   `lib/src/types/` and imports no concrete scale, element or chart
///   module (Chart.js ADR 0028, section 1). `getMaxOverflow` casts each data
///   element to `types.PointElement` at `size` (Chart.js ADR 0028, section
///   4).
/// - [BubbleController.jsClass] is the class as a value with the statics
///   `id`, `defaults` and `overrides` (Chart.js ADR 0020, section 3).
/// - The option copy for each item (the option resolution of each parse
///   and the copy of the shared options) is ported literally (Chart.js ADR
///   0036, section 8: the step 7 list), except inside the guarded native loops
///   of row `adapt-bubble-point-options` (Chart.js ADR 0094).
/// - `_custom` of a `TypedDataItem` under `parsing: false` is its typed `r`
///   (row `adapt-bubble-typed-radius`).
///
/// This library imports `core.datasetController.dart`, which imports
/// `core.animations.dart`. Thus it is not a pure layer.
library;

import 'package:flutter_chartjs_port/src/core/core.datasetController.dart'
    show DatasetController, controllerArgs, parsedValueOf, setPointAxis;
import 'package:flutter_chartjs_port/src/core/data_update.dart'
    show DataUpdateShape, nativeDataUpdateList, nativeDataUpdateObject;
import 'package:flutter_chartjs_port/src/core/point_option_preparation.dart';
import 'package:flutter_chartjs_port/src/core/point_options.dart';
import 'package:flutter_chartjs_port/src/elements/element_options.dart'
    show ElementOptions, PointOptions;
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show valueOrDefault;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_math.dart' show jsMax;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart'
    show jsGet, jsGetIndex, jsGetKey;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart'
    show OptionKey;
import 'package:flutter_chartjs_port/src/options/parsed.dart' show ParsedItem;
import 'package:flutter_chartjs_port/src/options/props.dart'
    show PointProperties;
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show
        AnimationOptionsScope,
        AnimationsSpecScope,
        BubbleControllerDatasetOptionsScope,
        ChartOptionsScope,
        ScaleOptionsByIdScope,
        ScaleOptionsScope;
import 'package:flutter_chartjs_port/src/types/chart_axis.dart';
import 'package:flutter_chartjs_port/src/types/data_item.dart'
    show TypedDataItem;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

/// `options.radius` of the resolved options of a data element: the raw
/// value ([ElementOptions.valueOf]), typed for a [PointOptions].
Object? _radiusOf(ElementOptions options) => options.valueOf(OptionKey.radius);

/// `parsed._custom` of a parsed item: the typed field of a [ParsedItem], the
/// typed `r` of a [TypedDataItem] of `parsing: false` (Dart `null` is an absent
/// value), else the read by name of a data item of `parsing: false`.
Object? _customOf(Object? parsed) => switch (parsed) {
  final ParsedItem item => item.custom,
  // DIVERGES(chartjs): adapt-bubble-typed-radius, a typed item has its radius.
  final TypedDataItem item => item.r ?? undefined,
  _ => jsGetKey(parsed, '_custom'),
};

/// The result of [_plainCustomOf] for a value that a native loop leaves to the
/// ordinary path.
// DIVERGES(chartjs): adapt-bubble-point-options, the end of a native loop.
const Object _notPlain = Object();

/// `parsed._custom` when its read and the `+=` of controller.bubble.js:165 run
/// no user code: a number or `undefined` in a native item. Else [_notPlain].
// DIVERGES(chartjs): adapt-bubble-point-options, the guard of a native loop.
Object? _plainCustomOf(Object? parsed, NativeTypedItems typedItems) {
  if (parsed is ParsedItem ||
      (parsed is TypedDataItem && typedItems.accepts(parsed)) ||
      (parsed is Map<String, Object?> && nativeDataUpdateObject(parsed))) {
    final custom = _customOf(parsed);
    return custom is num || custom is Undefined ? custom : _notPlain;
  }
  return _notPlain;
}

/// Whether the `+=` of controller.bubble.js:165 on the radius of [options] runs
/// no user code: an absent or primitive radius. An object has its `toString`.
// DIVERGES(chartjs): adapt-bubble-point-options, the guard of a native loop.
bool _primitiveRadius(ElementOptions options) {
  final radius = _radiusOf(options);
  return radius == null ||
      radius is num ||
      radius is String ||
      radius is bool ||
      radius is Undefined;
}

/// One parse loop's permission to leave out the eager option resolve of
/// `valueOrDefault(item.r, this.resolveDataElementOptions(i).radius)`.
///
/// The result of that resolve is unused for an item with its own radius. It
/// can be left out while it has no other effect: the frozen `point-default`
/// entry exists, so that it only copies the entry, or a prepared indexed color
/// plan exists, so that it only refreshes the context of the item. This class
/// keeps that context refresh. A value that could run user code ends the
/// permission for good, before the code runs: each later item resolves. The
/// `+=` of that resolve converts the radius of the entry or the `_custom` of
/// the old parsed item, so both are part of the permission.
// DIVERGES(chartjs): adapt-bubble-point-options, one synchronous parse loop.
final class _ParseRadii(final BubbleController _owner, List<Object?> data) {
  this {
    if (_open) _takeEntry();
  }

  final NativeTypedItems _typedItems = NativeTypedItems();
  bool _open =
      _owner._exact &&
      nativePointClass(_owner.dataElementType) &&
      nativeDataUpdateList(data) &&
      nativeDataUpdateList(_owner.cachedMeta.parsed);
  bool _skips = false;
  bool _indexed = false;
  int _resolves = 0;
  NativePointContextReader? _contexts;

  void _end() {
    _open = false;
    _skips = false;
    _indexed = false;
  }

  /// Whether the entry of a resolve exists. Its radius decides the permission.
  bool _takeEntry() {
    final entry = _owner.cachedPointOptions('default');
    if (entry == null) return false;
    if (_primitiveRadius(entry)) {
      _skips = true;
    } else {
      _end();
    }
    return true;
  }

  /// A data item of `parseObjectData`, before the read of its `r`.
  void objectItem(Object? item) {
    if (!_open) return;
    if (item is TypedDataItem) {
      if (!_typedItems.accepts(item)) _end();
    } else if (item != null &&
        item is! Undefined &&
        (item is! Map<String, Object?> || !nativeDataUpdateObject(item))) {
      _end();
    }
  }

  /// `item.r`, before its `ToNumber`.
  void objectRadius(Object? value) {
    if (_open && value != null && value is! num && value is! Undefined) _end();
  }

  /// A data item of `parseArrayData`, before the read of `item[2]`.
  void arrayItem(Object? item) {
    if (_open && !nativeDataUpdateList(item)) _end();
  }

  /// The old parsed item of [index], before the resolve of any item reads it:
  /// `parsed && parsed._custom`. A falsy item has no read. `item[2]` of the new
  /// item needs no check: the parse only keeps it, with no conversion.
  void oldItem(int index) {
    if (!_open) return;
    final parsed = _owner.getParsed(index);
    if (jsTruthy(parsed) &&
        identical(_plainCustomOf(parsed, _typedItems), _notPlain)) {
      _end();
    }
  }

  /// Whether the eager resolve of [index] can stay out. With an indexed plan,
  /// this refreshes the context of the item, as the resolve would.
  bool skips(int index) {
    if (!_skips) return false;
    if (_indexed) {
      final i = index;
      final points = _owner.cachedMeta.data;
      if (i >= points.length || !nativePointElement(points[i])) {
        _end();
        return false;
      }
      if (_contexts?.read(i) == null) {
        _owner.getContext(index, false, 'default');
      }
    }
    return true;
  }

  /// One ordinary resolve ran: it may have made the entry, and two warm the
  /// indexed plan. There is one attempt for each loop.
  void resolved() {
    if (!_open || _skips) return;
    _resolves++;
    if (_resolves > 2 || _takeEntry()) return;
    if (_resolves == 2) {
      if (_owner._preparePointColors(_owner.cachedMeta.data) == null) {
        _end();
      } else {
        _skips = true;
        _indexed = true;
        _contexts = prepareNativePointContexts(_owner, 'default');
      }
    }
  }
}

/// controller.bubble.js:4 `BubbleController extends DatasetController`.
class BubbleController(super.chart, super.datasetIndex, [super.newTarget])
    extends DatasetController {
  /// `new BubbleController(chart, datasetIndex)`. Upstream declares no
  /// constructor in this class. `newTarget` is `new.target` (Chart.js ADR
  /// 0020, section 4).
  this;

  /// Native support for the explicit data-only lifecycle.
  @override
  // DIVERGES(chartjs): adapt-incremental-data-update, native opt-in.
  bool get supportsDataUpdates => super.runtimeType == BubbleController;

  @override
  DataUpdateShape get dataUpdateShape => DataUpdateShape.bubble;

  /// The exact class: no override of a resolve, of a parse or of `getParsed`.
  // DIVERGES(chartjs): adapt-bubble-point-options, the guard of a native loop.
  bool get _exact => super.runtimeType == BubbleController;

  /// controller.bubble.js:6 `static id = 'bubble'`.

  static const String id = 'bubble';

  /// controller.bubble.js:11 `static defaults`, a typed scope of the kind
  /// `BubbleControllerDatasetOptions` (Chart.js ADR 0054 §3).
  static final BubbleControllerDatasetOptionsScope defaults =
      BubbleControllerDatasetOptionsScope()
        ..datasetElementType = false
        ..dataElementType = 'point'
        ..animations = (AnimationsSpecScope()
          ..numbers = (AnimationOptionsScope()
            ..type = 'number'
            ..properties = <String>['x', 'y', 'borderWidth', 'radius']));

  /// controller.bubble.js:26 `static overrides`, a typed scope of the kind
  /// `ChartOptions` (Chart.js ADR 0054 §3).
  static final ChartOptionsScope overrides = ChartOptionsScope()
    ..scales = (ScaleOptionsByIdScope()
      ..jsWrite('x', ScaleOptionsScope()..type = 'linear')
      ..jsWrite('y', ScaleOptionsScope()..type = 'linear'));

  /// controller.bubble.js:4 `class BubbleController extends
  /// DatasetController` as a value (Chart.js ADR 0020, section 3).
  ///
  /// It extends [DatasetController.jsClass]. Its statics are `id`
  /// (`'bubble'`), [defaults] and [overrides], in the upstream order of
  /// declaration (:6-35). Its `construct` calls `BubbleController(chart,
  /// datasetIndex, newTarget)` with the arguments of [controllerArgs].
  static final JsClass jsClass = JsClass(
    'BubbleController',
    superclass: DatasetController.jsClass,
    statics: {'id': id, 'defaults': defaults, 'overrides': overrides},
    construct: (newTarget, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return BubbleController(chart, datasetIndex, newTarget);
    },
  );

  /// controller.bubble.js:37 `initialize()`.
  @override
  void initialize() {
    enableOptionSharing = true;
    super.initialize();
  }

  /// controller.bubble.js:46 `parsePrimitiveData(meta, data, start,
  /// count)`.
  ///
  /// Parse array of primitive values
  /// @protected
  @override
  List<ParsedItem> parsePrimitiveData(
    types.ChartMeta meta,
    List<Object?> data,
    int start,
    int count,
  ) {
    final parsed = super.parsePrimitiveData(meta, data, start, count);
    for (var i = 0; i < parsed.length; i++) {
      parsed[i].custom = _radiusOf(resolveDataElementOptions(i + start));
    }
    return parsed;
  }

  /// controller.bubble.js:58 `parseArrayData(meta, data, start, count)`.
  ///
  /// Parse array of arrays
  /// @protected
  ///
  /// `item[2]` is [jsGetIndex]: the item is a List or another value
  /// (Chart.js ADR 0036, section 5).
  @override
  List<ParsedItem> parseArrayData(
    types.ChartMeta meta,
    List<Object?> data,
    int start,
    int count,
  ) {
    final parsed = super.parseArrayData(meta, data, start, count);
    final radii = _ParseRadii(this, data);
    for (var i = 0; i < parsed.length; i++) {
      final item = jsGetIndex(data, start + i);
      radii.arrayItem(item);
      parsed[i].custom = _radiusOrDefault(
        jsGetIndex(item, 2),
        i + start,
        radii,
      );
    }
    return parsed;
  }

  /// controller.bubble.js:71 `parseObjectData(meta, data, start, count)`.
  ///
  /// Parse array of objects
  /// @protected
  ///
  /// `item && item.r && +item.r` is the value of the `&&` chain: a falsy
  /// item, else a falsy `r`, else the `ToNumber` of `r` (Chart.js ADR 0036,
  /// section 7). `item.r` is the typed field of a `TypedDataItem` (Dart
  /// `null` is an absent `r`), else the read by name of the data item of
  /// the user.
  @override
  List<ParsedItem> parseObjectData(
    types.ChartMeta meta,
    List<Object?> data,
    int start,
    int count,
  ) {
    final parsed = super.parseObjectData(meta, data, start, count);
    final radii = _ParseRadii(this, data);
    for (var i = 0; i < parsed.length; i++) {
      final item = jsGetIndex(data, start + i);
      radii.objectItem(item);
      final Object? r;
      if (!jsTruthy(item)) {
        r = item;
      } else {
        final value = item is TypedDataItem
            ? item.r ?? undefined
            : jsGetKey(item, 'r');
        radii.objectRadius(value);
        r = jsTruthy(value) ? jsToNumber(value) : value;
      }
      parsed[i].custom = _radiusOrDefault(r, i + start, radii);
    }
    return parsed;
  }

  /// `valueOrDefault(own, this.resolveDataElementOptions(index).radius)`,
  /// without the resolve when [radii] finds that it has no effect to keep.
  // DIVERGES(chartjs): adapt-bubble-point-options, upstream always resolves.
  Object? _radiusOrDefault(Object? own, int index, _ParseRadii radii) {
    radii.oldItem(index);
    if (own is! Undefined && radii.skips(index)) return own;
    final result = valueOrDefault(
      own,
      _radiusOf(resolveDataElementOptions(index)),
    );
    radii.resolved();
    return result;
  }

  /// controller.bubble.js:83 `getMaxOverflow()`.
  ///
  /// @protected
  ///
  /// `max > 0 && max` gives the number or `false`. `Math.max` gives NaN
  /// when a size is NaN, and `NaN > 0` is false. The cast to
  /// `types.PointElement` stands at the read of `size` (Chart.js ADR 0028,
  /// section 4).
  ///
  /// A native point inside a native loop computes `size` from its own radius
  /// and the fields of the frozen entry or of one indexed plan result, with no
  /// options object (row `adapt-bubble-point-options`). An indexed plan keeps
  /// the context refresh of each point.
  @override
  Object? getMaxOverflow() {
    final data = cachedMeta.data;

    var max = 0.0;
    // DIVERGES(chartjs): adapt-bubble-point-options, scalars inside this loop.
    // A custom point or a value with user code ends them before it can run.
    NativePointSizeFields? fields;
    NativePointContextReader? contexts;
    final typedItems = NativeTypedItems();
    var indexed = false;
    final last = data.length - 1;
    for (var i = last; i >= 0; --i) {
      final point = data[i] as types.PointElement;
      if (i == last) fields = _cachedSizeFields();
      final plan = fields;
      if (plan != null) {
        // `getParsed(i)` of the exact controller on a native list.
        final items = cachedMeta.parsed;
        final custom = nativePointElement(point)
            ? _plainCustomOf(
                i < items.length ? items[i] : undefined,
                typedItems,
              )
            : _notPlain;
        if (!identical(custom, _notPlain)) {
          if (indexed && contexts?.readQualified(point, i) == null) {
            getContext(i, false, 'default');
          }
          max = jsMax(
            max,
            nativePointSize(
                  // The `+=` of :165 from the 0 of :163.
                  0.0 + (custom is num ? custom : plan.radius),
                  plan.hoverRadius,
                  plan.borderWidth,
                ) /
                2,
          );
          continue;
        }
        fields = null;
        indexed = false;
      }
      max = jsMax(max, point.size(resolveDataElementOptions(i)) / 2);
      // The first ordinary resolution makes the entry of constant options, and
      // two warm the indexed plan. There is one attempt for each loop.
      if (i == last) {
        fields = _cachedSizeFields();
      } else if (fields == null && i == last - 1) {
        final prepared = _preparePointColors(data);
        if (prepared != null) {
          fields = NativePointSizeFields.of(prepared(i));
          if (fields != null) {
            indexed = true;
            contexts = prepareNativePointContexts(this, 'default');
          }
        }
      }
    }
    return max > 0 ? max : false;
  }

  /// controller.bubble.js:96 `getLabelAndValue(index)`.
  ///
  /// @protected
  ///
  /// The label is `labels[index] || ''`: any value (Chart.js ADR 0028,
  /// section 2). The `+` of the value joins the [jsToString] of each part.
  @override
  ({Object? label, String value}) getLabelAndValue(int index) {
    final meta = cachedMeta;
    final dataLabels = jsGet(chart.data, 'labels');
    final labels = jsTruthy(dataLabels) ? dataLabels : <Object?>[];
    final xScale = meta.xScale;
    final yScale = meta.yScale;
    final parsed = getParsed(index);
    final x = xScale!.getLabelForValue(parsedValueOf(parsed, const XAxis()));
    final y = yScale!.getLabelForValue(parsedValueOf(parsed, const YAxis()));
    final r = _customOf(parsed);
    final label = jsGetIndex(labels, index);

    return (
      label: jsTruthy(label) ? label : '',
      value:
          '(${jsToString(x)}, ${jsToString(y)}'
          '${jsTruthy(r) ? ', ${jsToString(r)}' : ''})',
    );
  }

  /// controller.bubble.js:111 `update(mode)`.
  @override
  void update(String mode) {
    final points = cachedMeta.data;

    // Update Points
    updateElements(points, 0, points.length, mode);
  }

  /// controller.bubble.js:118 `updateElements(points, start, count, mode)`.
  ///
  /// `!reset && this.getParsed(i)` is `false` in the mode `reset`: no code
  /// reads it then. `sharedOptions || ...`: Dart `null` is the JS
  /// `undefined` of no shared options. `properties.options.radius = 0`
  /// writes into the shared options or into the result of
  /// [resolveDataElementOptions], as upstream.
  ///
  /// The exact controller in the mode `none` prepares fresh options once inside
  /// this loop, after two ordinary resolutions (row
  /// `adapt-bubble-point-options`). Each iteration still checks its point and
  /// its parsed item first, and the plan ends for good before user code.
  @override
  void updateElements(
    List<types.Element> points,
    int start,
    int count,
    String mode,
  ) {
    final reset = mode == 'reset';
    final iScale = cachedMeta.iScale!;
    final vScale = cachedMeta.vScale!;
    final (:sharedOptions, :includeOptions) = getSharedOptions_(start, mode);
    final iAxis = iScale.axis;
    final vAxis = vScale.axis;
    // DIVERGES(chartjs): adapt-direct-element-writes, `updateElement` of the
    // exact controller only assigns in these modes, into two typed axes.
    final direct =
        _exact &&
        (reset || mode == 'none') &&
        (iAxis is XAxis || iAxis is YAxis) &&
        (vAxis is XAxis || vAxis is YAxis);
    // DIVERGES(chartjs): adapt-bubble-point-options, one synchronous loop.
    PointOptions Function(int)? prepared;
    NativePointContextReader? contexts;
    var indexed = false;
    final coordinates = NativePointCoordinates();
    final typedItems = NativeTypedItems();
    final tryPrepare =
        _exact &&
        canPrepareNativePointUpdate(
          mode: mode,
          sharedOptions: sharedOptions,
          includeOptions: includeOptions,
          stacked: cachedMeta.stacked,
          segment: null,
          iAxis: iAxis,
          vAxis: vAxis,
          start: start,
          count: count,
        );

    for (var i = start; i < start + count; i++) {
      final point = points[i];
      final parsed = reset ? false : getParsed(i);
      if (prepared != null &&
          (!nativePointElement(point) ||
              point.active ||
              !coordinates.accepts(parsed) ||
              identical(_plainCustomOf(parsed, typedItems), _notPlain))) {
        prepared = null;
      }
      final iPixel = reset
          ? iScale.getPixelForDecimal(0.5)
          : iScale.getPixelForValue(parsedValueOf(parsed, iAxis));
      final vPixel = reset
          ? vScale.getBasePixel()
          : vScale.getPixelForValue(parsedValueOf(parsed, vAxis));

      final skip = iPixel.isNaN || vPixel.isNaN;

      ElementOptions? options;
      if (includeOptions) {
        final plan = prepared;
        if (plan != null) {
          if (indexed && contexts?.read(i) == null) {
            getContext(i, false, mode);
          }
          options = _customRadius(plan(i), parsed, mode);
        } else {
          options =
              sharedOptions ??
              resolveDataElementOptions(i, point.active ? 'active' : mode);
        }

        if (reset) {
          options.storeKey(OptionKey.radius, 0.0);
        }
      }

      // DIVERGES(chartjs): adapt-direct-element-writes, the assign of the
      // properties with no object: the writes stay after the resolve above.
      if (point case final types.PointElementWrites target
          when direct && options != null && target.typedWrites) {
        if (iAxis is XAxis) {
          target.x = iPixel;
        } else {
          target.y = iPixel;
        }
        if (vAxis is XAxis) {
          target.x = vPixel;
        } else {
          target.y = vPixel;
        }
        target
          ..skip = skip
          ..options = options;
      } else {
        final properties = PointProperties();
        setPointAxis(properties, iAxis, iPixel);
        setPointAxis(properties, vAxis, vPixel);
        properties.skip = skip;
        if (options != null) properties.options = options;

        updateElement(point, i, properties, mode);
      }

      // Two ordinary resolutions populate the entry or the indexed plan. There
      // is one attempt for each loop, never another after custom code runs.
      if (tryPrepare &&
          i == start + 1 &&
          coordinates.accepts(parsed) &&
          _nativeProjection(iScale) &&
          _nativeProjection(vScale)) {
        prepared = _prepareConstantOptions(mode);
        if (prepared == null) {
          prepared = _preparePointColors(points);
          if (prepared != null) {
            indexed = true;
            contexts = prepareNativePointContexts(this, mode);
          }
        }
      }
    }
  }

  // The existing numeric-scale capability guarantees built-in projection and
  // base-pixel reads. The scale's chart must provide the same native DPR reads.
  // DIVERGES(chartjs): adapt-bubble-point-options, the guard of a native loop.
  bool _nativeProjection(types.Scale scale) =>
      nativePointProjection(scale) && identical(scale.chart, chart);

  /// The size fields of the frozen `point-default` entry for the exact
  /// controller, whose ordinary resolve only copies that entry.
  // DIVERGES(chartjs): adapt-bubble-point-options, the fields of a native loop.
  NativePointSizeFields? _cachedSizeFields() =>
      _exact && nativeDataUpdateList(cachedMeta.parsed)
      ? cachedNativePointSizeFields(this)
      : null;

  /// A fresh copy of the frozen `point-<mode>` entry for each point, as the
  /// ordinary resolve of the exact controller makes. Without an entry, or with
  /// a radius whose `+=` runs user code, Dart `null`.
  // DIVERGES(chartjs): adapt-bubble-point-options, one synchronous loop.
  PointOptions Function(int)? _prepareConstantOptions(String mode) {
    if (!nativePointClass(dataElementType) ||
        !nativeDataUpdateList(cachedMeta.parsed)) {
      return null;
    }
    final entry = cachedPointOptions(mode);
    if (entry is! PointOptions || !_primitiveRadius(entry)) return null;
    final template = entry.clone()..storeKey(OptionKey.dollarShared, false);
    return (_) => template.clone();
  }

  // DIVERGES(chartjs): adapt-native-point-contracts, shared preparation rules.
  PointOptions Function(int)? _preparePointColors(List<types.Element> points) {
    if (!_exact || type != 'bubble') return null;
    return prepareNativePointColors(this, points, controllerType: 'bubble');
  }

  /// controller.bubble.js:151 `resolveDataElementOptions(index, mode)`.
  ///
  /// @param {number} index
  /// @param {string} [mode]
  /// @protected
  ///
  /// Dart `null` for [mode] stands for JS `undefined`. `Object.assign({},
  /// values, {$shared: false})` is `values.clone()` with `$shared` false:
  /// the copy keeps the class of the options (Chart.js ADR 0021, section
  /// 3). `parsed && parsed._custom` is the value of `&&`, and `+=` is
  /// [jsAdd] of the raw `radius` (Chart.js ADR 0036, section 7): a string
  /// radius joins.
  @override
  ElementOptions resolveDataElementOptions(int index, [String? mode]) {
    final parsed = getParsed(index);
    var values = super.resolveDataElementOptions(index, mode);

    // In case values were cached (and thus frozen), we need to clone the
    // values
    if (jsTruthy(values.$sharedValue)) {
      // DIVERGES(chartjs): adapt-typed-element-options, a copy of the class.
      values = values.clone()..storeKey(OptionKey.dollarShared, false);
    }

    return _customRadius(values, parsed, mode);
  }

  /// controller.bubble.js:161-165, the end of `resolveDataElementOptions`.
  // DIVERGES(chartjs): adapt-bubble-point-options, shared with the update plan.
  ElementOptions _customRadius(
    ElementOptions values,
    Object? parsed,
    String? mode,
  ) {
    // Custom radius resolution
    final radius = _radiusOf(values);
    if (mode != 'active') {
      values.storeKey(OptionKey.radius, 0.0);
    }
    values.storeKey(
      OptionKey.radius,
      jsAdd(
        _radiusOf(values),
        valueOrDefault(jsTruthy(parsed) ? _customOf(parsed) : parsed, radius),
      ),
    );

    return values;
  }
}
