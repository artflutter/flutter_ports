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
///   properties a [PointProperties] (Chart.js ADR 0054 §9).
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
///   0036, section 8: the step 7 list).
///
/// This library imports `core.datasetController.dart`, which imports
/// `core.animations.dart`. Thus it is not a pure layer.
library;

import 'package:flutter_chartjs_port/src/core/core.datasetController.dart'
    show DatasetController, controllerArgs, parsedValueOf, setPointAxis;
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
import 'package:flutter_chartjs_port/src/options/parsed.dart'
    show AxisKey, ParsedItem;
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
import 'package:flutter_chartjs_port/src/types/data_item.dart'
    show TypedDataItem;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

/// `options.radius` of the resolved options of a data element: the raw
/// value ([ElementOptions.valueOf]), typed for a [PointOptions].
Object? _radiusOf(ElementOptions options) => options.valueOf(OptionKey.radius);

/// `parsed._custom` of a parsed item: the typed field of a [ParsedItem],
/// else the read by name of a data item of `parsing: false`.
Object? _customOf(Object? parsed) =>
    parsed is ParsedItem ? parsed.custom : jsGetKey(parsed, '_custom');

/// controller.bubble.js:4 `BubbleController extends DatasetController`.
class BubbleController extends DatasetController {
  /// `new BubbleController(chart, datasetIndex)`. Upstream declares no
  /// constructor in this class. [newTarget] is `new.target` (Chart.js ADR
  /// 0020, section 4).
  BubbleController(super.chart, super.datasetIndex, [super.newTarget]);

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
    double start,
    double count,
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
    double start,
    double count,
  ) {
    final parsed = super.parseArrayData(meta, data, start, count);
    for (var i = 0; i < parsed.length; i++) {
      final item = jsGetIndex(data, start + i);
      parsed[i].custom = valueOrDefault(
        jsGetIndex(item, 2),
        _radiusOf(resolveDataElementOptions(i + start)),
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
    double start,
    double count,
  ) {
    final parsed = super.parseObjectData(meta, data, start, count);
    for (var i = 0; i < parsed.length; i++) {
      final item = jsGetIndex(data, start + i);
      final Object? r;
      if (!jsTruthy(item)) {
        r = item;
      } else {
        final value = item is TypedDataItem
            ? item.r ?? undefined
            : jsGetKey(item, 'r');
        r = jsTruthy(value) ? jsToNumber(value) : value;
      }
      parsed[i].custom = valueOrDefault(
        r,
        _radiusOf(resolveDataElementOptions(i + start)),
      );
    }
    return parsed;
  }

  /// controller.bubble.js:83 `getMaxOverflow()`.
  ///
  /// @protected
  ///
  /// `max > 0 && max` gives the number or `false`. `Math.max` gives NaN
  /// when a size is NaN, and `NaN > 0` is false. The cast to
  /// `types.PointElement` stands at the read of `size` (Chart.js ADR 0028,
  /// section 4).
  @override
  Object? getMaxOverflow() {
    final data = cachedMeta.data;

    var max = 0.0;
    for (var i = data.length - 1; i >= 0; --i) {
      max = jsMax(
        max,
        (data[i] as types.PointElement).size(
              resolveDataElementOptions(i.toDouble()),
            ) /
            2,
      );
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
  ({Object? label, String value}) getLabelAndValue(double index) {
    final meta = cachedMeta;
    final dataLabels = jsGet(chart.data, 'labels');
    final labels = jsTruthy(dataLabels) ? dataLabels : <Object?>[];
    final xScale = meta.xScale;
    final yScale = meta.yScale;
    final parsed = getParsed(index);
    final x = xScale!.getLabelForValue(parsedValueOf(parsed, AxisKey.x, 'x'));
    final y = yScale!.getLabelForValue(parsedValueOf(parsed, AxisKey.y, 'y'));
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
    updateElements(points, 0, points.length.toDouble(), mode);
  }

  /// controller.bubble.js:118 `updateElements(points, start, count, mode)`.
  ///
  /// `!reset && this.getParsed(i)` is `false` in the mode `reset`: no code
  /// reads it then. `sharedOptions || ...`: Dart `null` is the JS
  /// `undefined` of no shared options. `properties.options.radius = 0`
  /// writes into the shared options or into the result of
  /// [resolveDataElementOptions], as upstream.
  @override
  void updateElements(
    List<types.Element> points,
    double start,
    double count,
    String mode,
  ) {
    final reset = mode == 'reset';
    final iScale = cachedMeta.iScale!;
    final vScale = cachedMeta.vScale!;
    final (:sharedOptions, :includeOptions) = getSharedOptions_(start, mode);
    final iAxis = iScale.axis;
    final vAxis = vScale.axis;
    final iKey = AxisKey.of(iAxis);
    final vKey = AxisKey.of(vAxis);

    for (var i = start; i < start + count; i++) {
      final point = points[i.toInt()];
      final parsed = reset ? false : getParsed(i);
      final properties = PointProperties();
      final iPixel = reset
          ? iScale.getPixelForDecimal(0.5)
          : iScale.getPixelForValue(parsedValueOf(parsed, iKey, iAxis));
      setPointAxis(properties, iKey, iAxis, iPixel);
      final vPixel = reset
          ? vScale.getBasePixel()
          : vScale.getPixelForValue(parsedValueOf(parsed, vKey, vAxis));
      setPointAxis(properties, vKey, vAxis, vPixel);

      properties.skip = iPixel.isNaN || vPixel.isNaN;

      if (includeOptions) {
        final options =
            sharedOptions ??
            resolveDataElementOptions(i, point.active ? 'active' : mode);
        properties.options = options;

        if (reset) {
          options.storeKey(OptionKey.radius, 0.0);
        }
      }

      updateElement(point, i, properties, mode);
    }
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
  ElementOptions resolveDataElementOptions(double index, [String? mode]) {
    final parsed = getParsed(index);
    var values = super.resolveDataElementOptions(index, mode);

    // In case values were cached (and thus frozen), we need to clone the
    // values
    if (jsTruthy(values.$sharedValue)) {
      // DIVERGES(chartjs): adapt-typed-element-options, a copy of the class.
      values = values.clone()..storeKey(OptionKey.dollarShared, false);
    }

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
