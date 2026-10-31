// Ported from Chart.js v4.6.1 src/controllers/controller.scatter.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-typed-parsed, the typed data of Chart.js ADR 0054.

/// Port of `src/controllers/controller.scatter.js`.
///
/// [ScatterController] is the dataset controller of the `scatter` charts.
/// It writes one `PointElement` for each data item. The pixels of a point
/// come from the index scale and the value scale. With the option
/// `showLine`, it also writes a `LineElement` as the dataset element.
///
/// - The parsed data is typed (Chart.js ADR 0054 §8): the reads of a parsed
///   value are [parsedValueOf], typed for a [ParsedItem]. A parsed item of
///   `parsing: false` is a data item of the user, read by name (Chart.js
///   ADR 0036). The dataset options read typed ([OptionView.readKey]), and
///   so do the [LineOptions] of the line.
/// - A pass of the loop of [ScatterController.updateElements] reads each
///   key of its parsed item once, and keeps no value for the next pass (the
///   3-read form of Chart.js ADR 0036, section 8). Each local of a parsed read
///   names the upstream lines that it serves.
/// - The properties of a point are a [PointProperties], and those of the
///   line a [LineProperties] (Chart.js ADR 0054 §9). The writes into the
///   point of a direct update and the four writes into the line
///   (`scatter.js:80-83`) take the typed setters of
///   `types.PointElementWrites` and `types.LineElementWrites` for an element
///   of a built-in class (`typedWrites`, the exact-class rule), and the
///   writes by name through `types.PropertyAccess` for an element of another
///   class (a user element class, Chart.js ADR 0017, section 5). The
///   controller imports no element module (Chart.js ADR 0028, section 1).
///   [ScatterController.getMaxOverflow] casts a point to
///   `types.PointElement` at `size`.
/// - `this.chart.registry` (`scatter.js:105`) is the singleton `registry`
///   of `core.registry.dart`, the object that the upstream getter gives
///   (row `adapt-chart-registry-getter`). Thus this library imports
///   `core.registry.dart`, and upstream does not import it.
/// - [ScatterController.jsClass] is the class as a value with the statics
///   `id`, `defaults` and `overrides` (Chart.js ADR 0020, section 3).
///
/// This library imports `core.datasetController.dart`, which imports
/// `core.animations.dart`. Thus it is not a pure layer.
library;

import 'package:flutter_chartjs_port/src/core/core.datasetController.dart'
    show DatasetController, controllerArgs, parsedValueOf, setPointAxis;
import 'package:flutter_chartjs_port/src/core/core.registry.dart' show registry;
import 'package:flutter_chartjs_port/src/elements/element_options.dart'
    show ElementOptions, LineOptions;
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show OptionView, readOption;
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show isNullOrUndef;
import 'package:flutter_chartjs_port/src/helpers/helpers.extras.dart'
    show getStartAndCountOfVisiblePoints, scaleRangesChanged;
import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart'
    show isNumber;
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
    show LineProperties, PointProperties;
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show
        ChartOptionsScope,
        InteractionOptionsScope,
        LineControllerDatasetOptionsScope,
        ScaleOptionsByIdScope,
        ScaleOptionsScope;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

/// The JS write `element[key] = value` by name into an element of a user
/// element class (Chart.js ADR 0017, section 5), or of a property that the
/// element class does not declare.
void _setProperty(types.PropertyAccess element, String key, Object? value) {
  element[key] = value;
}

/// The writes `properties[key] = value` of controller.scatter.js:127-140
/// (Chart.js ADR 0054 §9).
///
/// `properties` is the point of a direct update and a new object in the
/// other modes (:127). The new object is a [PointProperties]. A point of
/// the built-in class takes the typed setters of [types.PointElementWrites].
/// A point of another class (a user element class) takes the writes by name
/// of
/// [_setProperty], in the same order. The writes reach the point at once,
/// as upstream: the scriptable options of the user that run between two
/// writes see the earlier writes.
final class _PointWrites {
  _PointWrites({required this.direct});

  /// `directUpdate` (:121).
  final bool direct;

  /// The new object of a mode that is not direct, else Dart `null`.
  PointProperties? object;

  /// The point of a direct update that takes the typed writes: a point
  /// whose [types.PointElementWrites.typedWrites] is true, the class
  /// `PointElement` itself.
  types.PointElementWrites? _element;

  /// The point of a direct update, for the writes by name: a point of
  /// another class, and the keys and values that the typed setters do not
  /// take.
  late types.PropertyAccess _access;

  /// :127 `const properties = directUpdate ? point : {};`.
  void begin(types.Element point) {
    if (!direct) {
      object = PointProperties();
    } else {
      _element = switch (point) {
        final types.PointElementWrites point when point.typedWrites => point,
        _ => null,
      };
      // Each data element is an Element: the cast of `_insertElements`
      // (row adapt-component-class-role).
      _access = point as types.PropertyAccess;
    }
  }

  /// `properties[axis] = value` (:129-130), with [key] the key of [axis].
  void axis(AxisKey key, String axis, double value) {
    final object = this.object;
    if (object != null) {
      setPointAxis(object, key, axis, value);
      return;
    }
    final element = _element;
    if (element == null) {
      _setProperty(_access, axis, value);
    } else if (key == AxisKey.x) {
      element.x = value;
    } else if (key == AxisKey.y) {
      element.y = value;
    } else {
      _setProperty(_access, axis, value);
    }
  }

  /// `properties.skip = value` (:132).
  // The write of one boolean property.
  // ignore: avoid_positional_boolean_parameters
  void skip(bool value) {
    final object = this.object;
    if (object != null) {
      object.skip = value;
    } else if (_element case final element?) {
      element.skip = value;
    } else {
      _setProperty(_access, 'skip', value);
    }
  }

  /// `properties.stop = value` (:133).
  // The write of one boolean property.
  // ignore: avoid_positional_boolean_parameters
  void stop(bool value) {
    final object = this.object;
    if (object != null) {
      object.stop = value;
    } else if (_element case final element?) {
      element.stop = value;
    } else {
      _setProperty(_access, 'stop', value);
    }
  }

  /// `properties.parsed = value` (:135). A JS `null` or `undefined` value
  /// is outside the type of the typed setter of the point: it goes by name.
  void parsed(Object? value) {
    final object = this.object;
    if (object != null) {
      object.parsed = value;
    } else if (_element case final element? when value != null) {
      if (value is Undefined) {
        _setProperty(_access, 'parsed', value);
      } else {
        element.parsed = value;
      }
    } else {
      _setProperty(_access, 'parsed', value);
    }
  }

  /// `properties.raw = value` (:136). A point does not declare `raw`: the
  /// write goes by name.
  void raw(Object? value) {
    final object = this.object;
    if (object != null) {
      object.raw = value;
    } else {
      _setProperty(_access, 'raw', value);
    }
  }

  /// `properties.options = value` (:140).
  void options(ElementOptions value) {
    final object = this.object;
    if (object != null) {
      object.options = value;
    } else if (_element case final element?) {
      element.options = value;
    } else {
      _setProperty(_access, 'options', value);
    }
  }
}

/// controller.scatter.js:6 `ScatterController extends DatasetController`.
class ScatterController extends DatasetController {
  /// `new ScatterController(chart, datasetIndex)`. Upstream declares no
  /// constructor in this class. [newTarget] is `new.target` (Chart.js ADR
  /// 0020, section 4).
  ScatterController(super.chart, super.datasetIndex, [super.newTarget]);

  /// controller.scatter.js:8 `static id = 'scatter'`.
  static const String id = 'scatter';

  /// controller.scatter.js:13 `static defaults`, a typed scope of the kind
  /// `LineControllerDatasetOptions` (the kind of `datasets.scatter`,
  /// Chart.js ADR 0054 §3).
  static final LineControllerDatasetOptionsScope defaults =
      LineControllerDatasetOptionsScope()
        ..datasetElementType = false
        ..dataElementType = 'point'
        ..showLine = false
        ..fill = false;

  /// controller.scatter.js:23 `static overrides`, a typed scope of the kind
  /// `ChartOptions` (Chart.js ADR 0054 §3).
  static final ChartOptionsScope overrides = ChartOptionsScope()
    ..interaction = (InteractionOptionsScope()..mode = 'point')
    ..scales = (ScaleOptionsByIdScope()
      ..jsWrite('x', ScaleOptionsScope()..type = 'linear')
      ..jsWrite('y', ScaleOptionsScope()..type = 'linear'));

  /// controller.scatter.js:6 `class ScatterController extends
  /// DatasetController` as a value (Chart.js ADR 0020, section 3).
  ///
  /// It extends [DatasetController.jsClass]. Its statics are `id`
  /// (`'scatter'`), [defaults] and [overrides], in the upstream order of
  /// declaration (:8-37). Its `construct` calls `ScatterController(chart,
  /// datasetIndex, newTarget)` with the arguments of [controllerArgs].
  static final JsClass jsClass = JsClass(
    'ScatterController',
    superclass: DatasetController.jsClass,
    statics: {'id': id, 'defaults': defaults, 'overrides': overrides},
    construct: (newTarget, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return ScatterController(chart, datasetIndex, newTarget);
    },
  );

  /// controller.scatter.js:42 `getLabelAndValue(index)`.
  ///
  /// @protected
  ///
  /// The label is `labels[index] || ''`: any value (Chart.js ADR 0028,
  /// section 2). The `+` of the value joins the [jsToString] of each part.
  /// `chart.data.labels` is a property of the data object of the user.
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
    final label = jsGetIndex(labels, index);

    return (
      label: jsTruthy(label) ? label : '',
      value: '(${jsToString(x)}, ${jsToString(y)})',
    );
  }

  /// controller.scatter.js:56 `update(mode)`.
  ///
  /// `const {data: points = []} = meta`: the data elements of the meta are a
  /// List (the default `[]` does not occur).
  ///
  /// - With a truthy `showLine`, the update adds the dataset element when
  ///   [datasetElementType] is falsy (:74-76, Chart.js issue #11333). The
  ///   four writes of :80-83 are the typed setters of
  ///   [types.LineElementWrites] for a line of the built-in class, and writes
  ///   by name of an untyped property for a
  ///   line of another class (Chart.js ADR 0017, section 5; Chart.js ADR
  ///   0028, section 1). The null check throws a [TypeError] for Dart
  ///   `null`, as `undefined._chart = ...` does. The write `points` goes to
  ///   the setter of the row `adapt-line-points-elements`: a typed copy of
  ///   `meta.data`. `_dataset._decimated` is a property of the dataset
  ///   object of the user that the decimation plugin writes: a read by
  ///   name.
  /// - Else, a truthy [datasetElementType] removes the dataset element
  ///   (:91-95). `delete meta.dataset` is Dart `null`: the type of
  ///   `meta.dataset` holds the JS `undefined` as Dart `null`.
  @override
  void update(String mode) {
    final meta = cachedMeta;
    final points = meta.data;
    final animationsDisabled = chart.animationsDisabled;
    var (:start, :count) = getStartAndCountOfVisiblePoints(
      meta,
      points,
      jsTruthy(animationsDisabled),
    );

    drawStart = start;
    drawCount = count;

    if (scaleRangesChanged(meta)) {
      start = 0;
      count = points.length.toDouble();
    }

    if (jsTruthy(options.readKey(OptionKey.showLine))) {
      // https://github.com/chartjs/Chart.js/issues/11333
      if (!jsTruthy(datasetElementType)) {
        addElements();
      }
      final line = meta.dataset;
      final dataset = meta.dataset_;

      // Update Line
      final target = line!;
      final decimated = jsTruthy(jsGetKey(dataset, '_decimated'));
      if (target case final types.LineElementWrites line
          when line.typedWrites) {
        line
          ..chart = chart
          ..datasetIndex = index
          ..decimated = decimated
          ..points = points;
      } else {
        final access = target as types.PropertyAccess;
        _setProperty(access, '_chart', chart);
        _setProperty(access, '_datasetIndex', index);
        _setProperty(access, '_decimated', decimated);
        _setProperty(access, 'points', points);
      }

      final options = resolveDatasetElementOptions(mode)
        ..storeKey(OptionKey.segment, this.options.readKey(OptionKey.segment));
      updateElement(
        target,
        null,
        LineProperties()
          ..animated = !jsTruthy(animationsDisabled)
          ..options = options,
        mode,
      );
    } else if (jsTruthy(datasetElementType)) {
      // https://github.com/chartjs/Chart.js/issues/11333
      meta.dataset = null;
      datasetElementType = false;
    }

    // Update Points
    updateElements(points, start, count, mode);
  }

  /// controller.scatter.js:101 `addElements()`.
  ///
  /// `this.chart.registry.getElement('line')` reads the singleton
  /// `registry` (row `adapt-chart-registry-getter`).
  @override
  void addElements() {
    final showLine = options.readKey(OptionKey.showLine);

    if (!jsTruthy(datasetElementType) && jsTruthy(showLine)) {
      // DIVERGES(chartjs): adapt-chart-registry-getter, the registry singleton.
      datasetElementType = registry.getElement('line');
    }

    super.addElements();
  }

  /// controller.scatter.js:111 `updateElements(points, start, count,
  /// mode)`.
  ///
  /// - `properties` is the point of a direct update and a new object in the
  ///   other modes (:127). The writes into it are [_PointWrites].
  /// - `isNumber(spanGaps) ? spanGaps : Infinity` gets its `ToNumber` once:
  ///   its only use, the `>` of :133, applies `ToNumber` to it.
  /// - `start > 0 && this.getParsed(start - 1)` is `false` or the parsed
  ///   item. `parsed[iAxis] - prevParsed[iAxis]` applies `ToNumber` to both
  ///   reads. `false[iAxis]` is `undefined`, as [parsedValueOf] gives.
  /// - The one-read rule in one pass (Chart.js ADR 0036, section 8):
  ///   `vValue` serves the reads of `parsed[vAxis]` at :128 and :130, and
  ///   `iValue` the reads of `parsed[iAxis]` at :129 and :133. Between :128
  ///   and :133 no statement writes the parsed item: `applyStack` only reads
  ///   it (core.datasetController.js:593-605), and the writes go to
  ///   `properties`.
  /// - The read `prevParsed[iAxis]` of :133 stays a read at each pass (the
  ///   3-read form of Chart.js ADR 0036, section 8). A local of the previous
  ///   pass does not obey the one-read rule here: between the two reads,
  ///   `resolveDataElementOptions` (:140) and the animated `updateElement`
  ///   (:144) run the scriptable options of the user. Their context holds
  ///   the parsed item (`ctx.parsed`), and a scriptable option can write
  ///   its keys. The pin case `parsed: a scriptable option writes
  ///   ctx.parsed` shows the upstream result.
  @override
  void updateElements(
    List<types.Element> points,
    double start,
    double count,
    String mode,
  ) {
    final reset = mode == 'reset';
    final meta = cachedMeta;
    final iScale = meta.iScale;
    final vScale = meta.vScale;
    final stacked = meta.stacked;
    final dataset = meta.dataset_;
    final firstOpts = resolveDataElementOptions(start, mode);
    final sharedOptions = getSharedOptions(firstOpts);
    final includeOptions = this.includeOptions(mode, sharedOptions);
    final iAxis = iScale!.axis;
    final vAxis = vScale!.axis;
    final iKey = AxisKey.of(iAxis);
    final vKey = AxisKey.of(vAxis);
    final options = this.options;
    final spanGaps = options.readKey(OptionKey.spanGaps);
    final segment = options.readKey(OptionKey.segment);
    final maxGapLength = isNumber(spanGaps)
        ? jsToNumber(spanGaps)
        : double.infinity;
    final directUpdate =
        jsTruthy(chart.animationsDisabled) || reset || mode == 'none';
    var prevParsed = start > 0 ? getParsed(start - 1) : false;
    final writes = _PointWrites(direct: directUpdate);

    for (var i = start; i < start + count; ++i) {
      final point = points[i.toInt()];
      final parsed = getParsed(i);
      writes.begin(point);
      // :128, also :130 (one-read rule).
      final vValue = parsedValueOf(parsed, vKey, vAxis);
      final nullData = isNullOrUndef(vValue);
      // :129, also :133 (one-read rule).
      final iValue = parsedValueOf(parsed, iKey, iAxis);
      final iPixel = iScale.getPixelForValue(iValue, i);
      writes.axis(iKey, iAxis, iPixel);
      final vPixel = reset || nullData
          ? vScale.getBasePixel()
          : vScale.getPixelForValue(
              jsTruthy(stacked) ? applyStack(vScale, parsed, stacked) : vValue,
              i,
            );
      writes
        ..axis(vKey, vAxis, vPixel)
        ..skip(iPixel.isNaN || vPixel.isNaN || nullData)
        // :133 `i > 0 && (Math.abs(parsed[iAxis] - prevParsed[iAxis])) >
        // maxGapLength`. `prevParsed[iAxis]` is a read at each pass (the
        // 3-read form, see above).
        ..stop(
          i > 0 &&
              (jsToNumber(iValue) -
                          jsToNumber(parsedValueOf(prevParsed, iKey, iAxis)))
                      .abs() >
                  maxGapLength,
        );
      if (jsTruthy(segment)) {
        writes
          ..parsed(parsed)
          // `_dataset.data[i]`: the data of the dataset object of the user.
          ..raw(jsGetIndex(jsGet(dataset, 'data'), i));
      }

      if (includeOptions) {
        // `sharedOptions || ...`: Dart `null` is the JS `undefined` of no
        // shared options.
        writes.options(
          sharedOptions ??
              resolveDataElementOptions(i, point.active ? 'active' : mode),
        );
      }

      if (!directUpdate) {
        updateElement(point, i, writes.object!, mode);
      }

      prevParsed = parsed;
    }

    updateSharedOptions(sharedOptions, mode, firstOpts);
  }

  /// controller.scatter.js:156 `getMaxOverflow()`.
  ///
  /// @protected
  ///
  /// - Without `showLine` (:160-166): `max > 0 && max` gives the number or
  ///   `false`. `Math.max` gives NaN when a size is NaN, and `NaN > 0` is
  ///   false.
  /// - With `showLine` (:168-177): `dataset.options &&
  ///   dataset.options.borderWidth || 0` keeps the raw value: a truthy
  ///   `borderWidth` is the result, also for an empty data. `Math.max`
  ///   applies `ToNumber` to it. A dataset element that is Dart `null`
  ///   throws a [TypeError], as `undefined.options` does. The options of a
  ///   line are a [LineOptions]; the options of a user element type read
  ///   by name.
  /// - The cast to `types.PointElement` stands at the upstream read of
  ///   `size` (Chart.js ADR 0028, section 1).
  @override
  Object? getMaxOverflow() {
    final meta = cachedMeta;
    final data = meta.data;

    if (!jsTruthy(options.readKey(OptionKey.showLine))) {
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

    final dataset = meta.dataset;
    final datasetOptions = dataset!.options;
    final Object? border;
    if (!jsTruthy(datasetOptions)) {
      border = 0.0;
    } else {
      final borderWidth = readOption(datasetOptions, OptionKey.borderWidth);
      border = jsTruthy(borderWidth) ? borderWidth : 0.0;
    }

    if (data.isEmpty) {
      return border;
    }

    final firstPoint = (data[0] as types.PointElement).size(
      resolveDataElementOptions(0),
    );
    final lastPoint = (data[data.length - 1] as types.PointElement).size(
      resolveDataElementOptions((data.length - 1).toDouble()),
    );
    return jsMax(jsMax(jsToNumber(border), firstPoint), lastPoint) / 2;
  }
}
