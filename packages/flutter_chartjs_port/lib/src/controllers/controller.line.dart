// Ported from Chart.js v4.6.1 src/controllers/controller.line.js (MIT, Chart.js Contributors).

/// Port of `src/controllers/controller.line.js`.
///
/// [LineController] is the dataset controller of the `line` charts. It
/// writes the dataset element (a `LineElement`) and one `PointElement` for
/// each data item. The pixels of a point come from the index scale and the
/// value scale.
///
/// - A parsed item and a data item are any value (Chart.js ADR 0036). A
///   read with a `String` key is [jsGetKey], a read with a number index is
///   [jsGetIndex]. A read of a resolver or of an option object is [jsGet]
///   (Chart.js ADR 0017, section 8).
/// - A pass of the loop of [LineController.updateElements] reads each key
///   of its parsed item once (the one-read rule of Chart.js ADR 0036,
///   section 8). Each local of a parsed read names the upstream lines that
///   it serves. The read of the previous item at :104 stays a read at each
///   pass (the 3-read form of Chart.js ADR 0036, section 8).
/// - The controller reads the members of other modules through
///   `lib/src/types/` and imports no concrete scale, element or chart
///   module (Chart.js ADR 0028, section 1). The four writes into the line
///   (`line.js:57-60`) are writes by name through `types.PropertyAccess`.
///   The draw casts the dataset element to `types.LineElement`, and
///   [LineController.getMaxOverflow] casts a point to `types.PointElement`
///   at `size`.
/// - [LineController.jsClass] is the class as a value with the statics
///   `id`, `defaults` and `overrides` (Chart.js ADR 0020, section 3).
/// - The writes by name into the point of a direct update stay writes by
///   name (Chart.js ADR 0036, section 8: the step 7 list).
///
/// This library imports `core.datasetController.dart`, which imports
/// `core.animations.dart`. Thus it is not a pure layer.
library;

import 'package:flutter_chartjs_port/src/core/core.datasetController.dart'
    show DatasetController, controllerArgs;
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
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show
        ChartOptionsScope,
        LineControllerDatasetOptionsScope,
        ScaleOptionsByIdScope,
        ScaleOptionsScope;
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

/// The JS write `properties[key] = value` of controller.line.js:94-111.
///
/// `properties` is the point of a direct update (:91): the write is a write
/// by name of the element (Chart.js ADR 0017, section 5). In the other
/// modes it is the new object that goes to `updateElement`.
void _setProperty(Object properties, String key, Object? value) {
  switch (properties) {
    case final AnyObject object:
      object[key] = value;
    case final types.PropertyAccess element:
      element[key] = value;
  }
}

/// controller.line.js:6 `LineController extends DatasetController`.
class LineController extends DatasetController {
  /// `new LineController(chart, datasetIndex)`. Upstream declares no
  /// constructor in this class. [newTarget] is `new.target` (Chart.js ADR
  /// 0020, section 4).
  LineController(super.chart, super.datasetIndex, [super.newTarget]);

  /// controller.line.js:8 `static id = 'line'`.
  static const String id = 'line';

  /// controller.line.js:13 `static defaults`, a typed scope of the kind
  /// `LineControllerDatasetOptions` (Chart.js ADR 0054 §3).
  static final LineControllerDatasetOptionsScope defaults =
      LineControllerDatasetOptionsScope()
        ..datasetElementType = 'line'
        ..dataElementType = 'point'
        ..showLine = true
        ..spanGaps = false;

  /// controller.line.js:24 `static overrides`, a typed scope of the kind
  /// `ChartOptions` (Chart.js ADR 0054 §3).
  static final ChartOptionsScope overrides = ChartOptionsScope()
    ..scales = (ScaleOptionsByIdScope()
      ..jsWrite('_index_', ScaleOptionsScope()..type = 'category')
      ..jsWrite('_value_', ScaleOptionsScope()..type = 'linear'));

  /// controller.line.js:6 `class LineController extends DatasetController`
  /// as a value (Chart.js ADR 0020, section 3).
  ///
  /// It extends [DatasetController.jsClass]. Its statics are `id`
  /// (`'line'`), [defaults] and [overrides], in the upstream order of
  /// declaration (:8-33). Its `construct` calls `LineController(chart,
  /// datasetIndex, newTarget)` with the arguments of [controllerArgs].
  static final JsClass jsClass = JsClass(
    'LineController',
    superclass: DatasetController.jsClass,
    statics: {'id': id, 'defaults': defaults, 'overrides': overrides},
    construct: (newTarget, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return LineController(chart, datasetIndex, newTarget);
    },
  );

  /// controller.line.js:35 `initialize()`.
  @override
  void initialize() {
    enableOptionSharing = true;
    supportsDecimation = true;
    super.initialize();
  }

  /// controller.line.js:41 `update(mode)`.
  ///
  /// `const {dataset: line, data: points = [], _dataset} = meta`: the data
  /// elements of the meta are a List (the default `[]` does not occur).
  ///
  /// The four writes of :57-60 are writes by name of an untyped property
  /// (Chart.js ADR 0017, section 5; Chart.js ADR 0028, section 1). The
  /// null check before the cast to `types.PropertyAccess` throws a
  /// [TypeError] for Dart `null`, as `undefined._chart = ...` does. A
  /// dataset element of another class takes the writes, and the draw
  /// throws. The write `points` goes to the setter of the row
  /// `adapt-line-points-elements`: a typed copy of `meta.data`.
  @override
  void update(String mode) {
    final meta = cachedMeta;
    final line = meta.dataset;
    final points = meta.data;
    final dataset = meta.dataset_;
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

    // Update Line
    final access = line! as types.PropertyAccess;
    access['_chart'] = chart;
    access['_datasetIndex'] = index;
    access['_decimated'] = jsTruthy(jsGetKey(dataset, '_decimated'));
    access['points'] = points;

    final options = resolveDatasetElementOptions(mode);
    if (!jsTruthy(jsGet(this.options, 'showLine'))) {
      options['borderWidth'] = 0.0;
    }
    options['segment'] = jsGet(this.options, 'segment');
    updateElement(line, null, <String, Object?>{
      'animated': !jsTruthy(animationsDisabled),
      'options': options,
    }, mode);

    // Update Points
    updateElements(points, start, count, mode);
  }

  /// controller.line.js:76 `updateElements(points, start, count, mode)`.
  ///
  /// - `properties` is the point of a direct update and a new object in the
  ///   other modes (:91). The writes into it are [_setProperty].
  /// - `isNumber(spanGaps) ? spanGaps : Infinity` gets its `ToNumber` once:
  ///   its only use, the `>` of :104, applies `ToNumber` to it.
  /// - `start > 0 && this.getParsed(start - 1)` is `false` or the parsed
  ///   item. `parsed[iAxis] - prevParsed[iAxis]` applies `ToNumber` to both
  ///   reads. `false[iAxis]` is `undefined`, as [jsGetKey] gives.
  /// - The one-read rule (Chart.js ADR 0036, section 8): `vValue` serves
  ///   the reads of `parsed[vAxis]` at :99 and :101, and `iValue` the reads
  ///   of `parsed[iAxis]` at :100 and :104. Between :99 and :104 no
  ///   statement writes the parsed item: `applyStack` only reads it
  ///   (core.datasetController.js:593-605), and the writes go to
  ///   `properties`.
  /// - The read `prevParsed[iAxis]` of :104 stays a read at each pass (the
  ///   3-read form of Chart.js ADR 0036, section 8). A local of the previous
  ///   pass does not obey the one-read rule here: between the two reads,
  ///   `resolveDataElementOptions` (:111) and the animated `updateElement`
  ///   (:115) run the scriptable options of the user. Their context holds
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
    final (:sharedOptions, :includeOptions) = getSharedOptions_(start, mode);
    final iAxis = iScale!.axis;
    final vAxis = vScale!.axis;
    final spanGaps = jsGet(options, 'spanGaps');
    final segment = jsGet(options, 'segment');
    final maxGapLength = isNumber(spanGaps)
        ? jsToNumber(spanGaps)
        : double.infinity;
    final directUpdate =
        jsTruthy(chart.animationsDisabled) || reset || mode == 'none';
    final end = start + count;
    final pointsCount = points.length;
    var prevParsed = start > 0 ? getParsed(start - 1) : false;

    for (var i = 0; i < pointsCount; ++i) {
      final point = points[i];
      final index = i.toDouble();
      // :91 `const properties = directUpdate ? point : {};`. `object` is
      // the new object, Dart `null` for a direct update.
      final object = directUpdate ? null : <String, Object?>{};
      final properties = object ?? point as types.PropertyAccess;

      if (i < start || i >= end) {
        _setProperty(properties, 'skip', true);
        continue;
      }

      final parsed = getParsed(index);
      // :99, also :101 (one-read rule).
      final vValue = jsGetKey(parsed, vAxis);
      final nullData = isNullOrUndef(vValue);
      // :100, also :104 (one-read rule).
      final iValue = jsGetKey(parsed, iAxis);
      final iPixel = iScale.getPixelForValue(iValue, index);
      _setProperty(properties, iAxis, iPixel);
      final vPixel = reset || nullData
          ? vScale.getBasePixel()
          : vScale.getPixelForValue(
              jsTruthy(stacked) ? applyStack(vScale, parsed, stacked) : vValue,
              index,
            );
      _setProperty(properties, vAxis, vPixel);

      _setProperty(
        properties,
        'skip',
        iPixel.isNaN || vPixel.isNaN || nullData,
      );
      // :104 `i > 0 && Math.abs(parsed[iAxis] - prevParsed[iAxis]) >
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
        _setProperty(
          properties,
          'raw',
          jsGetIndex(jsGet(dataset, 'data'), index),
        );
      }

      if (includeOptions) {
        // `sharedOptions || ...`: Dart `null` is the JS `undefined` of no
        // shared options.
        _setProperty(
          properties,
          'options',
          sharedOptions ??
              resolveDataElementOptions(index, point.active ? 'active' : mode),
        );
      }

      if (!directUpdate) {
        updateElement(point, index, object!, mode);
      }

      prevParsed = parsed;
    }
  }

  /// controller.line.js:125 `getMaxOverflow()`.
  /// @protected
  ///
  /// `dataset.options && dataset.options.borderWidth || 0` keeps the raw
  /// value: a truthy `borderWidth` is the result, also for an empty data.
  /// `Math.max` applies `ToNumber` to it. The dataset element of a line
  /// chart is never Dart `null` here: `meta.dataset.options` of `undefined`
  /// throws a [TypeError] in both. The cast to `types.PointElement` stands
  /// at the upstream read of `size` (Chart.js ADR 0028, section 1).
  @override
  Object? getMaxOverflow() {
    final meta = cachedMeta;
    final dataset = meta.dataset;
    final datasetOptions = dataset!.options;
    final Object? border;
    if (!jsTruthy(datasetOptions)) {
      border = 0.0;
    } else {
      final borderWidth = jsGet(datasetOptions, 'borderWidth');
      border = jsTruthy(borderWidth) ? borderWidth : 0.0;
    }
    final data = meta.data;
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

  /// controller.line.js:138 `draw()`.
  ///
  /// The cast stands at the upstream read of `updateControlPoints`
  /// (Chart.js ADR 0028, section 1).
  ///
  /// `chart.chartArea` can be Dart `null` here, JS `undefined`: a plugin
  /// that returns `false` from `beforeLayout` at the first update leaves it
  /// unset, and the chart draw does not read it before the draw of a
  /// dataset. `updateControlPoints` takes a `ChartArea?`, and it throws a
  /// [TypeError] only when the line caps its control points
  /// (`capBezierPoints`), as upstream does. The cases `interfaces: a plugin
  /// cancels the first layout` of
  /// test/port/controllers/controller.line_test.dart pin the upstream
  /// result.
  @override
  void draw() {
    final meta = cachedMeta;
    (meta.dataset! as types.LineElement).updateControlPoints(
      chart.chartArea,
      meta.iScale!.axis,
    );
    super.draw();
  }
}
