// Ported from Chart.js v4.5.1+7169e651 src/controllers/controller.scatter.js (MIT, Chart.js Contributors).

/// Port of `src/controllers/controller.scatter.js`.
///
/// [ScatterController] is the dataset controller of the `scatter` charts.
/// It writes one `PointElement` for each data item. The pixels of a point
/// come from the index scale and the value scale. With the option
/// `showLine`, it also writes a `LineElement` as the dataset element.
///
/// - A parsed item and a data item are any value (Chart.js ADR 0036). A
///   read with a `String` key is [jsGetKey], a read with a number index is
///   [jsGetIndex]. A read of a resolver or of an option object is [jsGet]
///   (Chart.js ADR 0017, section 8).
/// - A pass of the loop of [ScatterController.updateElements] reads each
///   key of its parsed item once, and keeps no value for the next pass (the
///   3-read form of Chart.js ADR 0036, section 8). Each local of a parsed read
///   names the upstream lines that it serves.
/// - The controller reads the members of other modules through
///   `lib/src/types/` and imports no concrete scale, element or chart
///   module (Chart.js ADR 0028, section 1). The four writes into the line
///   (`scatter.js:80-83`) are writes by name through `types.PropertyAccess`.
///   [ScatterController.getMaxOverflow] casts a point to
///   `types.PointElement` at `size`.
/// - `this.chart.registry` (`scatter.js:105`) is the singleton `registry`
///   of `core.registry.dart`, the object that the upstream getter gives
///   (row `adapt-chart-registry-getter`). Thus this library imports
///   `core.registry.dart`, and upstream does not import it.
/// - [ScatterController.jsClass] is the class as a value with the statics
///   `id`, `defaults` and `overrides` (Chart.js ADR 0020, section 3).
/// - The writes by name into the point of a direct update stay writes by
///   name (Chart.js ADR 0036, section 8: the step 7 list).
///
/// This library imports `core.datasetController.dart`, which imports
/// `core.animations.dart`. Thus it is not a pure layer.
library;

import 'package:flutter_chartjs_port/src/core/core.datasetController.dart'
    show DatasetController, controllerArgs;
import 'package:flutter_chartjs_port/src/core/core.registry.dart' show registry;
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
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

/// The JS write `properties[key] = value` of controller.scatter.js:129-140.
///
/// `properties` is the point of a direct update (:127): the write is a
/// write by name of the element (Chart.js ADR 0017, section 5). In the other
/// modes it is the new object that goes to `updateElement`.
void _setProperty(Object properties, String key, Object? value) {
  switch (properties) {
    case final AnyObject object:
      object[key] = value;
    case final types.PropertyAccess element:
      element[key] = value;
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

  /// controller.scatter.js:13 `static defaults`.
  static final AnyObject defaults = {
    'datasetElementType': false,
    'dataElementType': 'point',
    'showLine': false,
    'fill': false,
  };

  /// controller.scatter.js:23 `static overrides`.
  static final AnyObject overrides = {
    'interaction': <String, Object?>{'mode': 'point'},

    'scales': <String, Object?>{
      'x': <String, Object?>{'type': 'linear'},
      'y': <String, Object?>{'type': 'linear'},
    },
  };

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
  ///   four writes of :80-83 are writes by name of an untyped property
  ///   (Chart.js ADR 0017, section 5; Chart.js ADR 0028, section 1). The
  ///   null check before the cast to `types.PropertyAccess` throws a
  ///   [TypeError] for Dart `null`, as `undefined._chart = ...` does. The
  ///   write `points` goes to the setter of the row
  ///   `adapt-line-points-elements`: a typed copy of `meta.data`.
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

    if (jsTruthy(jsGet(options, 'showLine'))) {
      // https://github.com/chartjs/Chart.js/issues/11333
      if (!jsTruthy(datasetElementType)) {
        addElements();
      }
      final line = meta.dataset;
      final dataset = meta.dataset_;

      // Update Line
      final access = line! as types.PropertyAccess;
      access['_chart'] = chart;
      access['_datasetIndex'] = index;
      access['_decimated'] = jsTruthy(jsGetKey(dataset, '_decimated'));
      access['points'] = points;

      final options = resolveDatasetElementOptions(mode);
      options['segment'] = jsGet(this.options, 'segment');
      updateElement(line, null, <String, Object?>{
        'animated': !jsTruthy(animationsDisabled),
        'options': options,
      }, mode);
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
    final showLine = jsGet(options, 'showLine');

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
  ///   other modes (:127). The writes into it are [_setProperty].
  /// - `isNumber(spanGaps) ? spanGaps : Infinity` gets its `ToNumber` once:
  ///   its only use, the `>` of :133, applies `ToNumber` to it.
  /// - `start > 0 && this.getParsed(start - 1)` is `false` or the parsed
  ///   item. `parsed[iAxis] - prevParsed[iAxis]` applies `ToNumber` to both
  ///   reads. `false[iAxis]` is `undefined`, as [jsGetKey] gives.
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
    final spanGaps = jsGet(options, 'spanGaps');
    final segment = jsGet(options, 'segment');
    final maxGapLength = isNumber(spanGaps)
        ? jsToNumber(spanGaps)
        : double.infinity;
    final directUpdate =
        jsTruthy(chart.animationsDisabled) || reset || mode == 'none';
    var prevParsed = start > 0 ? getParsed(start - 1) : false;

    for (var i = start; i < start + count; ++i) {
      final point = points[i.toInt()];
      final parsed = getParsed(i);
      // :127 `const properties = directUpdate ? point : {};`. `object` is
      // the new object, Dart `null` for a direct update.
      final object = directUpdate ? null : <String, Object?>{};
      final properties = object ?? point as types.PropertyAccess;
      // :128, also :130 (one-read rule).
      final vValue = jsGetKey(parsed, vAxis);
      final nullData = isNullOrUndef(vValue);
      // :129, also :133 (one-read rule).
      final iValue = jsGetKey(parsed, iAxis);
      final iPixel = iScale.getPixelForValue(iValue, i);
      _setProperty(properties, iAxis, iPixel);
      final vPixel = reset || nullData
          ? vScale.getBasePixel()
          : vScale.getPixelForValue(
              jsTruthy(stacked) ? applyStack(vScale, parsed, stacked) : vValue,
              i,
            );
      _setProperty(properties, vAxis, vPixel);

      _setProperty(
        properties,
        'skip',
        iPixel.isNaN || vPixel.isNaN || nullData,
      );
      // :133 `i > 0 && (Math.abs(parsed[iAxis] - prevParsed[iAxis])) >
      // maxGapLength`. `prevParsed[iAxis]` is a read at each pass (the
      // 3-read form, see above).
      _setProperty(
        properties,
        'stop',
        i > 0 &&
            (jsToNumber(iValue) - jsToNumber(jsGetKey(prevParsed, iAxis)))
                    .abs() >
                maxGapLength,
      );
      if (jsTruthy(segment)) {
        _setProperty(properties, 'parsed', parsed);
        _setProperty(properties, 'raw', jsGetIndex(jsGet(dataset, 'data'), i));
      }

      if (includeOptions) {
        // `sharedOptions || ...`: Dart `null` is the JS `undefined` of no
        // shared options.
        _setProperty(
          properties,
          'options',
          sharedOptions ??
              resolveDataElementOptions(i, point.active ? 'active' : mode),
        );
      }

      if (!directUpdate) {
        updateElement(point, i, object!, mode);
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
  ///   throws a [TypeError], as `undefined.options` does.
  /// - The cast to `types.PointElement` stands at the upstream read of
  ///   `size` (Chart.js ADR 0028, section 1).
  @override
  Object? getMaxOverflow() {
    final meta = cachedMeta;
    final data = meta.data;

    if (!jsTruthy(jsGet(options, 'showLine'))) {
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
      final borderWidth = jsGet(datasetOptions, 'borderWidth');
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
