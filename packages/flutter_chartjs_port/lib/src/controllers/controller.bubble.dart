// Ported from Chart.js v4.6.1 src/controllers/controller.bubble.js (MIT, Chart.js Contributors).

/// Port of `src/controllers/controller.bubble.js`.
///
/// [BubbleController] is the dataset controller of the `bubble` charts. It
/// parses the radius of each item into `_custom`, computes the pixels of
/// each point from the index scale and the value scale, and writes the
/// properties of each `PointElement` through `updateElement`.
///
/// - A parsed item, a data item and `_custom` are any value (Chart.js ADR
///   0036). A read with a `String` key is [jsGetKey], a read with a number
///   index is [jsGetIndex], and the read `item[2]` of a data item is
///   [jsGet] with the key `'2'` (Chart.js ADR 0036, section 5). A read of a
///   resolver or of an option object is [jsGet] (Chart.js ADR 0017, section
///   8).
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
    show DatasetController, controllerArgs;
import 'package:flutter_chartjs_port/src/elements/element_options.dart'
    show copyOptions;
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show valueOrDefault;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_math.dart' show jsMax;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart'
    show jsGet, jsGetIndex, jsGetKey;
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

/// controller.bubble.js:4 `BubbleController extends DatasetController`.
class BubbleController extends DatasetController {
  /// `new BubbleController(chart, datasetIndex)`. Upstream declares no
  /// constructor in this class. [newTarget] is `new.target` (Chart.js ADR
  /// 0020, section 4).
  BubbleController(super.chart, super.datasetIndex, [super.newTarget]);

  /// controller.bubble.js:6 `static id = 'bubble'`.
  static const String id = 'bubble';

  /// controller.bubble.js:11 `static defaults`.
  static final AnyObject defaults = {
    'datasetElementType': false,
    'dataElementType': 'point',

    'animations': <String, Object?>{
      'numbers': <String, Object?>{
        'type': 'number',
        'properties': <String>['x', 'y', 'borderWidth', 'radius'],
      },
    },
  };

  /// controller.bubble.js:26 `static overrides`.
  static final AnyObject overrides = {
    'scales': <String, Object?>{
      'x': <String, Object?>{'type': 'linear'},
      'y': <String, Object?>{'type': 'linear'},
    },
  };

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
  List<AnyObject> parsePrimitiveData(
    types.ChartMeta meta,
    List<Object?> data,
    double start,
    double count,
  ) {
    final parsed = super.parsePrimitiveData(meta, data, start, count);
    for (var i = 0; i < parsed.length; i++) {
      parsed[i]['_custom'] = jsGet(
        resolveDataElementOptions(i + start),
        'radius',
      );
    }
    return parsed;
  }

  /// controller.bubble.js:58 `parseArrayData(meta, data, start, count)`.
  ///
  /// Parse array of arrays
  /// @protected
  ///
  /// `item[2]` is [jsGet] with the key `'2'`: the item is a List or another
  /// value (Chart.js ADR 0036, section 5).
  @override
  List<AnyObject> parseArrayData(
    types.ChartMeta meta,
    List<Object?> data,
    double start,
    double count,
  ) {
    final parsed = super.parseArrayData(meta, data, start, count);
    for (var i = 0; i < parsed.length; i++) {
      final item = jsGetIndex(data, start + i);
      parsed[i]['_custom'] = valueOrDefault(
        jsGet(item, '2'),
        jsGet(resolveDataElementOptions(i + start), 'radius'),
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
  /// section 7).
  @override
  List<AnyObject> parseObjectData(
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
        final value = jsGetKey(item, 'r');
        r = jsTruthy(value) ? jsToNumber(value) : value;
      }
      parsed[i]['_custom'] = valueOrDefault(
        r,
        jsGet(resolveDataElementOptions(i + start), 'radius'),
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
    final x = xScale!.getLabelForValue(jsGetKey(parsed, 'x'));
    final y = yScale!.getLabelForValue(jsGetKey(parsed, 'y'));
    final r = jsGetKey(parsed, '_custom');
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

    for (var i = start; i < start + count; i++) {
      final point = points[i.toInt()];
      final parsed = reset ? false : getParsed(i);
      final properties = <String, Object?>{};
      final iPixel = properties[iAxis] = reset
          ? iScale.getPixelForDecimal(0.5)
          : iScale.getPixelForValue(jsGetKey(parsed, iAxis));
      final vPixel = properties[vAxis] = reset
          ? vScale.getBasePixel()
          : vScale.getPixelForValue(jsGetKey(parsed, vAxis));

      properties['skip'] = iPixel.isNaN || vPixel.isNaN;

      if (includeOptions) {
        final options =
            sharedOptions ??
            resolveDataElementOptions(i, point.active ? 'active' : mode);
        properties['options'] = options;

        if (reset) {
          options['radius'] = 0.0;
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
  /// values, {$shared: false})` is `copyOptions(values)..[r'$shared'] =
  /// false`: the copy keeps the class of the options (Chart.js ADR 0021,
  /// section 3). `parsed && parsed._custom` is the value of `&&`, and `+=`
  /// is [jsAdd] (Chart.js ADR 0036, section 7).
  @override
  AnyObject resolveDataElementOptions(double index, [String? mode]) {
    final parsed = getParsed(index);
    var values = super.resolveDataElementOptions(index, mode);

    // In case values were cached (and thus frozen), we need to clone the
    // values
    if (jsTruthy(values[r'$shared'])) {
      // DIVERGES(chartjs): adapt-typed-element-options, a copy of the class.
      values = copyOptions(values)..[r'$shared'] = false;
    }

    // Custom radius resolution
    final radius = jsGet(values, 'radius');
    if (mode != 'active') {
      values['radius'] = 0.0;
    }
    values['radius'] = jsAdd(
      jsGet(values, 'radius'),
      valueOrDefault(
        jsTruthy(parsed) ? jsGetKey(parsed, '_custom') : parsed,
        radius,
      ),
    );

    return values;
  }
}
