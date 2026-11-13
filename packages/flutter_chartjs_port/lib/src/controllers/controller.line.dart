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
///   pass, unless the guards of Chart.js ADR 0109 prove that the x of the
///   previous pass is still its value.
/// - The properties of a point are a [PointProperties], and those of the
///   line a [LineProperties] (Chart.js ADR 0054 §9). The writes into the
///   point of a direct update and the four writes into the line
///   (`line.js:57-60`) take the typed setters of
///   `types.PointElementWrites` and `types.LineElementWrites` for an element
///   of a built-in class (`typedWrites`, the exact-class rule), and the
///   writes by name through `types.PropertyAccess` for an element of another
///   class (a user element class, Chart.js ADR 0017, section 5). The
///   controller imports no element module (Chart.js ADR 0028, section 1).
///   The draw casts the dataset
///   element to `types.LineElement`, and [LineController.getMaxOverflow]
///   casts a point to `types.PointElement` at `size`.
/// - [LineController.jsClass] is the class as a value with the statics
///   `id`, `defaults` and `overrides` (Chart.js ADR 0020, section 3).
///
/// This library imports `core.datasetController.dart`, which imports
/// `core.animations.dart`. Thus it is not a pure layer.
library;

import 'package:flutter_chartjs_port/src/core/chart_axis_reads.dart';
import 'package:flutter_chartjs_port/src/core/core.config.dart' show Config;
import 'package:flutter_chartjs_port/src/core/core.datasetController.dart'
    show DatasetController, controllerArgs, parsedValueOf, setPointAxis;
import 'package:flutter_chartjs_port/src/core/point_option_preparation.dart';
import 'package:flutter_chartjs_port/src/core/point_options.dart';
import 'package:flutter_chartjs_port/src/elements/element_options.dart'
    show ElementOptions, LineOptions, PointOptions;
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
import 'package:flutter_chartjs_port/src/options/parsed.dart' show ParsedItem;
import 'package:flutter_chartjs_port/src/options/props.dart'
    show LineProperties, PointProperties;
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show
        ChartOptionsScope,
        LineControllerDatasetOptionsScope,
        ScaleOptionsByIdScope,
        ScaleOptionsScope;
import 'package:flutter_chartjs_port/src/types/chart_axis.dart';
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
/// built-in class takes the typed setters of [types.PointElementWrites]. A
/// point of another class (a user element class) takes the writes by name of
/// [_setProperty], in the same order. The writes reach the point at once,
/// as upstream: the scriptable options of the user that run between two
/// writes see the earlier writes.
final class _PointWrites {
  _PointWrites({required this.direct});

  /// `directUpdate` (:88).
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

  /// Whether the point of this pass takes the typed writes: an exact point of
  /// a direct update, whose reads and writes run no user code.
  bool get typed => _element != null;

  /// :91 `const properties = directUpdate ? point : {};`.
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

  /// `properties[axis] = value` (:100-101).
  void axis(ScaleAxis axis, double value) {
    final object = this.object;
    if (object != null) {
      setPointAxis(object, axis, value);
      return;
    }
    final element = _element;
    switch ((element, axis)) {
      case (final types.PointElementWrites point, XAxis()):
        point.x = value;
      case (final types.PointElementWrites point, YAxis()):
        point.y = value;
      default:
        // The write by the key of the axis ([axisDataKey]).
        final key = axisDataKey(axis);
        if (key != null) _setProperty(_access, key, value);
    }
  }

  /// `properties.skip = value` (:94, :103).
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

  /// `properties.stop = value` (:104).
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

  /// `properties.parsed = value` (:106). A JS `null` or `undefined` value
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

  /// `properties.raw = value` (:107). A point does not declare `raw`: the
  /// write goes by name.
  void raw(Object? value) {
    final object = this.object;
    if (object != null) {
      object.raw = value;
    } else {
      _setProperty(_access, 'raw', value);
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
      _setProperty(_access, 'options', value);
    }
  }
}

/// controller.line.js:6 `LineController extends DatasetController`.
class LineController extends DatasetController {
  /// `new LineController(chart, datasetIndex)`. Upstream declares no
  /// constructor in this class. [newTarget] is `new.target` (Chart.js ADR
  /// 0020, section 4).
  LineController(super.chart, super.datasetIndex, [super.newTarget]);

  /// Native support for the explicit data-only lifecycle.
  @override
  // DIVERGES(chartjs): adapt-incremental-data-update, native opt-in.
  bool get supportsDataUpdates => super.runtimeType == LineController;

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
  /// The four writes of :57-60 are the typed setters of
  /// [types.LineElementWrites] for a line of the built-in class, and writes
  /// by name of an untyped property for a
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
    if (target case final types.LineElementWrites line when line.typedWrites) {
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

  // DIVERGES(chartjs): adapt-line-coordinate-cache, weak native map identities.
  final _coordinateCache = NativePointCoordinateCache();

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
  /// - The read `prevParsed[iAxis]` of :104 is a read at each pass, unless
  ///   the guards of Chart.js ADR 0109 prove that no user code ran since the
  ///   read of `parsed[iAxis]` of the previous pass ([NativeGapReads]). Then
  ///   the pass takes the x of the previous pass. Without that proof a local
  ///   of the previous pass does not obey the one-read rule:
  ///   `resolveDataElementOptions` (:111) and the animated `updateElement`
  ///   (:115) can run the scriptable options of the user. Their context holds
  ///   the parsed item (`ctx.parsed`), and a scriptable option can write its
  ///   keys. The pin case `parsed: a scriptable option writes ctx.parsed`
  ///   shows the upstream result.
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
    final options = this.options;
    final spanGaps = options.readKey(OptionKey.spanGaps);
    final segment = options.readKey(OptionKey.segment);
    // DIVERGES(chartjs): adapt-loop-invariant-truthiness, `_stacked ?` (:101)
    // and `if (segment)` (:105) test two locals of this call: once here.
    final hasStack = jsTruthy(stacked);
    final hasSegment = jsTruthy(segment);
    final maxGapLength = isNumber(spanGaps)
        ? jsToNumber(spanGaps)
        : double.infinity;
    final directUpdate =
        jsTruthy(chart.animationsDisabled) || reset || mode == 'none';
    final end = start + count;
    final pointsCount = points.length;
    var prevParsed = start > 0 ? getParsed(start - 1) : false;
    final writes = _PointWrites(direct: directUpdate);
    // DIVERGES(chartjs): adapt-line-point-options, reuse native indexed colors
    // only inside this loop, with guards at each original observation point.
    PointOptions Function(int)? colors;
    // DIVERGES(chartjs): adapt-native-line-resolution, loop-local source plan.
    NativePointResolution? resolution;
    NativePointContextReader? contextReader;
    JsClass? resolutionClass;
    Config? resolutionConfig;
    var resolutionDataset = index;
    var resolutionIndex = 0;
    Object context() => getContext(resolutionIndex * 1.0, false, mode);
    Object preparedContext() =>
        contextReader?.read(resolutionIndex) ?? context();
    bool resolutionOwnerValid() =>
        !hasCachedPointNoneOptions &&
        identical(dataElementType, resolutionClass) &&
        nativePointClass(resolutionClass) &&
        index == resolutionDataset &&
        identical(chart.config, resolutionConfig) &&
        identical(chart.data, resolution?.data);
    final coordinates = NativePointCoordinates(cache: _coordinateCache);
    final tryColors = canPrepareNativePointUpdate(
      mode: mode,
      sharedOptions: sharedOptions,
      includeOptions: includeOptions,
      stacked: stacked,
      segment: segment,
      iAxis: iAxis,
      vAxis: vAxis,
      start: start,
      count: count,
    );

    // DIVERGES(chartjs): adapt-native-gap-reads, the x of the previous pass
    // in place of the read of `prevParsed[iAxis]` (:104) under the guards.
    final gaps = super.runtimeType == LineController
        ? prepareNativeGapReads(
            this,
            points,
            directUpdate: directUpdate,
            hasStack: hasStack,
            hasSegment: hasSegment,
            iScale: iScale,
            vScale: vScale,
            maxGapLength: maxGapLength,
          )
        : null;

    if (!tryColors) _coordinateCache.clear();
    for (var i = 0; i < pointsCount; ++i) {
      final point = points[i];
      final index = i * 1.0;

      if (i < start || i >= end) {
        if (directUpdate) {
          writes
            ..begin(point)
            ..skip(true);
        }
        gaps?.held = null;
        continue;
      }

      if (colors != null && (!nativePointElement(point) || point.active)) {
        colors = null;
      }
      writes.begin(point);
      final parsed = getParsed(index);
      if (colors != null && !coordinates.accepts(parsed, i)) colors = null;
      // :99, also :101 (one-read rule).
      final vValue = parsedValueOf(parsed, vAxis);
      final nullData = isNullOrUndef(vValue);
      // :100, also :104 (one-read rule).
      final iValue = parsedValueOf(parsed, iAxis);
      final iPixel = iScale.getPixelForValue(iValue, index);
      writes.axis(iAxis, iPixel);
      final vPixel = reset || nullData
          ? vScale.getBasePixel()
          : vScale.getPixelForValue(
              hasStack ? applyStack(vScale, parsed, stacked) : vValue,
              index,
            );
      // The x of a pass that qualifies (Chart.js ADR 0109), and the gap test
      // from the x of the previous pass when that pass held it.
      final x = gaps != null && writes.typed
          ? gaps.qualify(parsed, iValue, vValue)
          : null;
      final held = x == null ? null : gaps!.stopOf(x);
      writes
        ..axis(vAxis, vPixel)
        ..skip(iPixel.isNaN || vPixel.isNaN || nullData)
        // :104 `i > 0 && Math.abs(parsed[iAxis] - prevParsed[iAxis]) >
        // maxGapLength`. `prevParsed[iAxis]` is a read at each pass without
        // a held x (see above).
        ..stop(
          held ??
              (i > 0 &&
                  (jsToNumber(iValue) -
                              jsToNumber(parsedValueOf(prevParsed, iAxis)))
                          .abs() >
                      maxGapLength),
        );
      if (hasSegment) {
        writes
          ..parsed(parsed)
          // `_dataset.data[i]`: the data of the dataset object of the user.
          ..raw(jsGetIndex(jsGet(dataset, 'data'), index));
      }

      // Whether the options of this pass can run user code: only the shared
      // options and the prepared native plan cannot.
      var userCode = false;
      if (includeOptions) {
        // `sharedOptions || ...`: Dart `null` is the JS `undefined` of no
        // shared options.
        final prepared = colors;
        if (prepared != null) {
          if (contextReader?.readQualified(point, i) == null) {
            getContext(index, false, mode);
          }
          writes.options(prepared(i));
        } else if (sharedOptions != null) {
          writes.options(sharedOptions);
        } else {
          userCode = true;
          final optionMode = point.active ? 'active' : mode;
          resolutionIndex = i;
          ElementOptions? result;
          final plan = resolution;
          if (plan != null) {
            if (optionMode != 'none' || !resolutionOwnerValid()) {
              resolution = null;
            } else {
              result = plan.resolve(context, preparedContext);
              if (result == null) resolution = null;
            }
          }
          writes.options(
            result ?? resolveDataElementOptions(index, optionMode),
          );
        }
      }

      if (!directUpdate) {
        updateElement(point, index, writes.object!, mode);
      }

      prevParsed = parsed;
      gaps?.held = userCode ? null : x;
      if (tryColors &&
          i == start + 1 &&
          coordinates.accepts(parsed) &&
          _nativeProjection(iScale) &&
          _nativeProjection(vScale)) {
        // The preparation is not part of the proof.
        gaps?.held = null;
        colors = _preparePointColors(points);
        if (colors != null) _coordinateCache.prepare(pointsCount);
        resolution = _prepareLineResolution();
        if (resolution != null) {
          resolutionConfig = chart.config as Config;
          resolutionClass = dataElementType! as JsClass;
          resolutionDataset = this.index;
          contextReader = NativePointContextReader.prepare(
            meta,
            resolution.raw,
            mode,
          );
        }
      }
    }
    if (colors == null) _coordinateCache.clear();
    gaps?.finish();
  }

  NativePointResolution? _prepareLineResolution() {
    if (super.runtimeType != LineController || type != 'line') return null;
    return prepareNativePointResolution(this);
  }

  bool _nativeProjection(types.Scale scale) =>
      nativePointProjection(scale) && identical(scale.chart, chart);

  // DIVERGES(chartjs): adapt-native-point-contracts, shared preparation rules.
  PointOptions Function(int)? _preparePointColors(List<types.Element> points) {
    if (super.runtimeType != LineController || type != 'line') return null;
    return prepareNativePointColors(this, points, controllerType: 'line');
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
