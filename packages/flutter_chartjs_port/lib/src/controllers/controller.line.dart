// Ported from Chart.js v4.6.1 src/controllers/controller.line.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-typed-parsed, the typed data of Chart.js ADR 0054.

/// Port of `src/controllers/controller.line.js`.
///
/// [LineController] is the dataset controller of the `line` charts. It
/// writes the dataset element (a `LineElement`) and one `PointElement` for
/// each data item. The pixels of a point come from the index scale and the
/// value scale.
///
/// - The parsed data is typed (Chart.js ADR 0054 §8): the reads of a parsed
///   value are [parsedValueOf], typed for a [ParsedItem]. A parsed item of
///   `parsing: false` is a data item of the user, read by name (Chart.js
///   ADR 0036). The dataset options read typed ([OptionView.readKey]), and
///   so do the [LineOptions] of the line.
/// - A pass of the loop of [LineController.updateElements] reads each key
///   of its parsed item once (the one-read rule of Chart.js ADR 0036,
///   section 8). Each local of a parsed read names the upstream lines that
///   it serves. The read of the previous item at :104 stays a read at each
///   pass (the 3-read form of Chart.js ADR 0036, section 8).
/// - The properties of a point are a [PointProperties], and those of the
///   line a [LineProperties] (Chart.js ADR 0054 §9). The writes into the
///   point of a direct update and the four writes into the line
///   (`line.js:57-60`) take the typed setters for an element of the exact
///   class [PointElement] or [LineElement], and the writes by name through
///   `types.PropertyAccess` for an element of another class (a user element
///   class, Chart.js ADR 0017, section 5). The draw casts the dataset
///   element to `types.LineElement`, and [LineController.getMaxOverflow]
///   casts a point to `types.PointElement` at `size`.
/// - [LineController.jsClass] is the class as a value with the statics
///   `id`, `defaults` and `overrides` (Chart.js ADR 0020, section 3).
///
/// This library imports `core.datasetController.dart`, which imports
/// `core.animations.dart`. Thus it is not a pure layer.
library;

import 'package:flutter_chartjs_port/src/core/core.datasetController.dart'
    show DatasetController, controllerArgs, parsedValueOf, setPointAxis;
import 'package:flutter_chartjs_port/src/elements/element.line.dart'
    show LineElement;
import 'package:flutter_chartjs_port/src/elements/element.point.dart'
    show PointElement;
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

/// The writes `properties[key] = value` of controller.line.js:91-111
/// (Chart.js ADR 0054 §9).
///
/// `properties` is the point of a direct update and a new object in the
/// other modes (:91). The new object is a [PointProperties]. A point of the
/// exact class [PointElement] takes the typed setters. A point of another
/// class (a user element class) takes the writes by name of
/// [_setProperty], in the same order. The writes reach the point at once,
/// as upstream: the scriptable options of the user that run between two
/// writes see the earlier writes.
final class _PointWrites {
  _PointWrites({required this.direct});

  /// `directUpdate` (:88).
  final bool direct;

  /// The new object of a mode that is not direct, else Dart `null`.
  PointProperties? object;

  /// The point of the exact class [PointElement] of a direct update.
  PointElement? _element;

  /// The point of another class of a direct update.
  types.PropertyAccess? _access;

  /// :91 `const properties = directUpdate ? point : {};`.
  void begin(types.Element point) {
    if (!direct) {
      object = PointProperties();
    } else if (identical(point.runtimeType, PointElement)) {
      _element = point as PointElement;
      _access = null;
    } else {
      _element = null;
      // Each data element is an Element: the cast of `_insertElements`
      // (row adapt-component-class-role).
      _access = point as types.PropertyAccess;
    }
  }

  /// `properties[axis] = value` (:100-101), with [key] the key of [axis].
  void axis(AxisKey key, String axis, double value) {
    final object = this.object;
    if (object != null) {
      setPointAxis(object, key, axis, value);
      return;
    }
    final element = _element;
    if (element == null) {
      _setProperty(_access!, axis, value);
    } else if (key == AxisKey.x) {
      element.x = value;
    } else if (key == AxisKey.y) {
      element.y = value;
    } else {
      _setProperty(element, axis, value);
    }
  }

  /// `properties.skip = value` (:94, :103).
  // The write of one boolean property.
  // ignore: avoid_positional_boolean_parameters
  void skip(bool value) {
    final object = this.object;
    if (object != null) {
      object.skip = value;
    } else if (_element case final element?) {
      element.skip = value;
    } else {
      _setProperty(_access!, 'skip', value);
    }
  }

  /// `properties.stop = value` (:104).
  // The write of one boolean property.
  // ignore: avoid_positional_boolean_parameters
  void stop(bool value) {
    final object = this.object;
    if (object != null) {
      object.stop = value;
    } else if (_element case final element?) {
      element.stop = value;
    } else {
      _setProperty(_access!, 'stop', value);
    }
  }

  /// `properties.parsed = value` (:106). A JS `null` or `undefined` value
  /// is outside the type of the typed setter of the point: it goes by name.
  void parsed(Object? value) {
    final object = this.object;
    if (object != null) {
      object.parsed = value;
    } else if (_element case final element? when value != null) {
      if (value is Undefined) {
        _setProperty(element, 'parsed', value);
      } else {
        element.parsed = value;
      }
    } else {
      _setProperty(_element ?? _access!, 'parsed', value);
    }
  }

  /// `properties.raw = value` (:107). A point does not declare `raw`: the
  /// write goes by name.
  void raw(Object? value) {
    final object = this.object;
    if (object != null) {
      object.raw = value;
    } else {
      _setProperty(_element ?? _access!, 'raw', value);
    }
  }

  /// `properties.options = value` (:111).
  void options(ElementOptions value) {
    final object = this.object;
    if (object != null) {
      object.options = value;
    } else if (_element case final element?) {
      element.options = value;
    } else {
      _setProperty(_access!, 'options', value);
    }
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
  /// The four writes of :57-60 are the typed setters of a line of the exact
  /// class [LineElement], and writes by name of an untyped property for a
  /// line of another class (Chart.js ADR 0017, section 5; Chart.js ADR 0028,
  /// section 1). The null check throws a [TypeError] for Dart `null`, as
  /// `undefined._chart = ...` does. A dataset element of another class
  /// takes the writes, and the draw throws. The write `points` goes to the
  /// setter of the row `adapt-line-points-elements`: a typed copy of
  /// `meta.data`. `_dataset._decimated` is a property of the dataset object
  /// of the user that the decimation plugin writes: a read by name.
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
    final target = line!;
    final decimated = jsTruthy(jsGetKey(dataset, '_decimated'));
    if (identical(target.runtimeType, LineElement)) {
      (target as LineElement)
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

    final options = resolveDatasetElementOptions(mode);
    if (!jsTruthy(this.options.readKey(OptionKey.showLine))) {
      options.storeKey(OptionKey.borderWidth, 0.0);
    }
    options.storeKey(
      OptionKey.segment,
      this.options.readKey(OptionKey.segment),
    );
    updateElement(
      target,
      null,
      LineProperties()
        ..animated = !jsTruthy(animationsDisabled)
        ..options = options,
      mode,
    );

    // Update Points
    updateElements(points, start, count, mode);
  }

  /// controller.line.js:76 `updateElements(points, start, count, mode)`.
  ///
  /// - `properties` is the point of a direct update and a new object in the
  ///   other modes (:91). The writes into it are [_PointWrites].
  /// - `isNumber(spanGaps) ? spanGaps : Infinity` gets its `ToNumber` once:
  ///   its only use, the `>` of :104, applies `ToNumber` to it.
  /// - `start > 0 && this.getParsed(start - 1)` is `false` or the parsed
  ///   item. `parsed[iAxis] - prevParsed[iAxis]` applies `ToNumber` to both
  ///   reads. `false[iAxis]` is `undefined`, as [parsedValueOf] gives.
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
  /// - A point out of the range takes `skip` only in a direct update: the
  ///   new object of another mode goes to no element (:93-95).
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
    final end = start + count;
    final pointsCount = points.length;
    var prevParsed = start > 0 ? getParsed(start - 1) : false;
    final writes = _PointWrites(direct: directUpdate);

    for (var i = 0; i < pointsCount; ++i) {
      final point = points[i];
      final index = i.toDouble();

      if (i < start || i >= end) {
        if (directUpdate) {
          writes
            ..begin(point)
            ..skip(true);
        }
        continue;
      }

      writes.begin(point);
      final parsed = getParsed(index);
      // :99, also :101 (one-read rule).
      final vValue = parsedValueOf(parsed, vKey, vAxis);
      final nullData = isNullOrUndef(vValue);
      // :100, also :104 (one-read rule).
      final iValue = parsedValueOf(parsed, iKey, iAxis);
      final iPixel = iScale.getPixelForValue(iValue, index);
      writes.axis(iKey, iAxis, iPixel);
      final vPixel = reset || nullData
          ? vScale.getBasePixel()
          : vScale.getPixelForValue(
              jsTruthy(stacked) ? applyStack(vScale, parsed, stacked) : vValue,
              index,
            );
      writes
        ..axis(vKey, vAxis, vPixel)
        ..skip(iPixel.isNaN || vPixel.isNaN || nullData)
        // :104 `i > 0 && Math.abs(parsed[iAxis] - prevParsed[iAxis]) >
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
          ..raw(jsGetIndex(jsGet(dataset, 'data'), index));
      }

      if (includeOptions) {
        // `sharedOptions || ...`: Dart `null` is the JS `undefined` of no
        // shared options.
        writes.options(
          sharedOptions ??
              resolveDataElementOptions(index, point.active ? 'active' : mode),
        );
      }

      if (!directUpdate) {
        updateElement(point, index, writes.object!, mode);
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
  /// at the upstream read of `size` (Chart.js ADR 0028, section 1). The
  /// options of a line are a [LineOptions]; the options of a user element
  /// type read by name.
  @override
  Object? getMaxOverflow() {
    final meta = cachedMeta;
    final dataset = meta.dataset;
    final datasetOptions = dataset!.options;
    final Object? border;
    if (!jsTruthy(datasetOptions)) {
      border = 0.0;
    } else {
      final borderWidth = readOption(datasetOptions, OptionKey.borderWidth);
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
