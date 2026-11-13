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
///   key of its parsed item once (the one-read rule of Chart.js ADR 0036,
///   section 8). It keeps its x for the next pass only under the guards of
///   Chart.js ADR 0109. Each local of a parsed read names the upstream lines
///   that it serves.
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

import 'dart:math' as math;

import 'package:flutter_chartjs_port/src/core/chart_axis_reads.dart';
import 'package:flutter_chartjs_port/src/core/core.datasetController.dart'
    show DatasetController, controllerArgs, parsedValueOf, setPointAxis;
import 'package:flutter_chartjs_port/src/core/core.interaction.dart'
    show PointInteractionMode;
import 'package:flutter_chartjs_port/src/core/core.registry.dart' show registry;
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
        InteractionOptionsScope,
        LineControllerDatasetOptionsScope,
        ScaleOptionsByIdScope,
        ScaleOptionsScope;
import 'package:flutter_chartjs_port/src/plugins/fill_target.dart'
    show FillTarget;
import 'package:flutter_chartjs_port/src/types/chart_axis.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_chartjs_port/src/types/tooltip_item.dart'
    show dataLabelLinesOf;

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
final class _PointWrites({
  /// `directUpdate` (:121).
  required final bool direct,
}) {
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

  /// `properties[axis] = value` (:129-130).
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

  /// `properties.skip = value` (:132).
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

/// What the overflow pass of `update_` needs after a loop that left the context
/// refresh of its points to it: the one size and a context reader of the mode
/// `default`.
// DIVERGES(chartjs): adapt-scatter-overflow-refresh, within one `update_`.
typedef _OverflowPass = ({double? overflow, NativePointContextReader contexts});

/// controller.scatter.js:6 `ScatterController extends DatasetController`.
class ScatterController(super.chart, super.datasetIndex, [super.newTarget])
    extends DatasetController {
  /// `new ScatterController(chart, datasetIndex)`. Upstream declares no
  /// constructor in this class. `newTarget` is `new.target` (Chart.js ADR
  /// 0020, section 4).
  this;

  /// Native support for the explicit data-only lifecycle.
  @override
  // DIVERGES(chartjs): adapt-incremental-data-update, native opt-in.
  bool get supportsDataUpdates => super.runtimeType == ScatterController;

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
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        ..fill = FillTarget.none;

  /// controller.scatter.js:23 `static overrides`, a typed scope of the kind
  /// `ChartOptions` (Chart.js ADR 0054 §3).
  static final ChartOptionsScope overrides = ChartOptionsScope()
    ..interaction = (InteractionOptionsScope()
      ..mode = const PointInteractionMode())
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
  ({List<String> label, String value}) getLabelAndValue(int index) {
    final meta = cachedMeta;
    final dataLabels = jsGet(chart.data, 'labels');
    final labels = jsTruthy(dataLabels) ? dataLabels : <Object?>[];
    final xScale = meta.xScale;
    final yScale = meta.yScale;
    final parsed = getParsed(index);
    final x = xScale!.getLabelForValue(parsedValueOf(parsed, const XAxis()));
    final y = yScale!.getLabelForValue(parsedValueOf(parsed, const YAxis()));
    final label = jsGetIndex(labels, index);

    return (
      label: dataLabelLinesOf(label),
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
    // DIVERGES(chartjs): adapt-scatter-overflow-refresh, taken before any read
    // that can run user code: a public call in it finds it false.
    final overflowFollows = overflowFollowsUpdate;
    overflowFollowsUpdate = false;
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
      count = points.length;
    }

    if (jsTruthy(options.readKey(OptionKey.showLine))) {
      // https://github.com/chartjs/Chart.js/issues/11333
      if (!jsTruthy(datasetElementType)) {
        addElements();
      }
      final line = meta.dataset;
      final dataset = meta.datasetConfig;

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
    // DIVERGES(chartjs): adapt-scatter-overflow-refresh, names this loop.
    _loopBeforeOverflow = overflowFollows;
    updateElements(points, start, count, mode);
  }

  /// Whether the [updateElements] that starts now is the loop of an [update]
  /// that [overflowFollowsUpdate] named. The loop takes it first.
  // DIVERGES(chartjs): adapt-scatter-overflow-refresh, the caller of the loop.
  bool _loopBeforeOverflow = false;

  /// The pass that the last loop left its context refreshes to, until the
  /// [getMaxOverflow] of the same `update_`.
  // DIVERGES(chartjs): adapt-scatter-overflow-refresh, within one `update_`.
  _OverflowPass? _overflowPass;

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
  /// - The read `prevParsed[iAxis]` of :133 is a read at each pass, unless
  ///   the guards of Chart.js ADR 0109 prove that no user code ran since the
  ///   read of `parsed[iAxis]` of the previous pass ([NativeGapReads]). Then
  ///   the pass takes the x of the previous pass. Without that proof a local
  ///   of the previous pass does not obey the one-read rule:
  ///   `resolveDataElementOptions` (:140) and the animated `updateElement`
  ///   (:144) can run the scriptable options of the user. Their context holds
  ///   the parsed item (`ctx.parsed`), and a scriptable option can write its
  ///   keys. The pin case `parsed: a scriptable option writes ctx.parsed`
  ///   shows the upstream result.
  @override
  void updateElements(
    List<types.Element> points,
    int start,
    int count,
    String mode,
  ) {
    // DIVERGES(chartjs): adapt-scatter-overflow-refresh, taken before any read.
    final overflowFollows = _loopBeforeOverflow;
    _loopBeforeOverflow = false;
    final reset = mode == 'reset';
    final meta = cachedMeta;
    final iScale = meta.iScale;
    final vScale = meta.vScale;
    final stacked = meta.stacked;
    final dataset = meta.datasetConfig;
    final firstOpts = resolveDataElementOptions(start, mode);
    final sharedOptions = getSharedOptions(firstOpts);
    final includeOptions = this.includeOptions(mode, sharedOptions);
    final iAxis = iScale!.axis;
    final vAxis = vScale!.axis;
    final options = this.options;
    final spanGaps = options.readKey(OptionKey.spanGaps);
    final segment = options.readKey(OptionKey.segment);
    // DIVERGES(chartjs): adapt-loop-invariant-truthiness, `_stacked ?` (:130)
    // and `if (segment)` (:134) test two locals of this call: once here.
    final hasStack = stacked != types.StackMode.off;
    final hasSegment = jsTruthy(segment);
    final maxGapLength = isNumber(spanGaps)
        ? jsToNumber(spanGaps)
        : double.infinity;
    final directUpdate =
        jsTruthy(chart.animationsDisabled) || reset || mode == 'none';
    var prevParsed = start > 0 ? getParsed(start - 1) : false;
    final writes = _PointWrites(direct: directUpdate);

    // DIVERGES(chartjs): adapt-scatter-point-options, prepare only within this
    // synchronous loop. Unknown geometry drops the plan before invoking it.
    PointOptions Function(int)? colors;
    NativePointContextReader? contexts;
    // DIVERGES(chartjs): adapt-scatter-overflow-refresh, the first index whose
    // refresh waits for the overflow pass, or -1. Code that can read a context
    // finds these refreshes done: see [_catchUpContexts].
    _OverflowPass? overflowPass;
    var waitingFrom = -1;
    final coordinates = NativePointCoordinates();
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
    // in place of the read of `prevParsed[iAxis]` (:133) under the guards.
    final gaps = super.runtimeType == ScatterController
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

    for (var i = start; i < start + count; ++i) {
      final point = points[i];
      final parsed = getParsed(i);
      // The catch-up of the contexts is not part of the proof.
      var caughtUp = false;
      if (colors != null &&
          (!nativePointElement(point) ||
              point.active ||
              !coordinates.accepts(parsed))) {
        colors = null;
        if (waitingFrom >= 0) {
          _catchUpContexts(contexts!, waitingFrom, i, mode);
          waitingFrom = -1;
          caughtUp = true;
        }
      }
      writes.begin(point);
      // :128, also :130 (one-read rule).
      final vValue = parsedValueOf(parsed, vAxis);
      final nullData = isNullOrUndef(vValue);
      // :129, also :133 (one-read rule).
      final iValue = parsedValueOf(parsed, iAxis);
      final iPixel = iScale.getPixelForValue(iValue, i);
      writes.axis(iAxis, iPixel);
      final vPixel = reset || nullData
          ? vScale.getBasePixel()
          : vScale.getPixelForValue(
              hasStack ? applyStack(vScale, parsed, stacked) : vValue,
              i,
            );
      // The x of a pass that qualifies (Chart.js ADR 0109), and the gap test
      // from the x of the previous pass when that pass held it.
      final x = gaps != null && !caughtUp && writes.typed
          ? gaps.qualify(parsed, iValue, vValue)
          : null;
      final held = x == null ? null : gaps!.stopOf(x);
      writes
        ..axis(vAxis, vPixel)
        ..skip(iPixel.isNaN || vPixel.isNaN || nullData)
        // :133 `i > 0 && (Math.abs(parsed[iAxis] - prevParsed[iAxis])) >
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
          ..raw(jsGetIndex(jsGet(dataset, 'data'), i));
      }

      // Whether the options of this pass can run user code: only the shared
      // options and the prepared native plan cannot.
      var userCode = false;
      if (includeOptions) {
        // `sharedOptions || ...`: Dart `null` is the JS `undefined` of no
        // shared options.
        final prepared = colors;
        if (prepared != null) {
          if (waitingFrom < 0 && contexts?.readQualified(point, i) == null) {
            getContext(i, false, mode);
          }
          writes.options(prepared(i));
        } else {
          userCode = sharedOptions == null;
          writes.options(
            sharedOptions ??
                resolveDataElementOptions(i, point.active ? 'active' : mode),
          );
        }
      }

      if (!directUpdate) {
        updateElement(point, i, writes.object!, mode);
      }

      prevParsed = parsed;
      gaps?.held = userCode ? null : x;
      // Two ordinary resolutions populate the cached raw indexed plan. There
      // is one preparation attempt, never another after custom code runs.
      if (tryColors &&
          i == start + 1 &&
          coordinates.accepts(parsed) &&
          _nativeProjection(iScale) &&
          _nativeProjection(vScale)) {
        // The preparation is not part of the proof.
        gaps?.held = null;
        colors = _preparePointColors(points);
        if (colors != null) {
          contexts = prepareNativePointContexts(this, mode);
          if (overflowFollows && contexts != null) {
            overflowPass = _prepareOverflowPass(points, start, count, colors);
            if (overflowPass != null) waitingFrom = i + 1;
          }
        }
      }
    }

    // DIVERGES(chartjs): adapt-scatter-overflow-refresh, the plan held to the
    // end: the overflow pass of this `update_` writes each waiting context.
    _overflowPass = waitingFrom >= 0 ? overflowPass : null;
    gaps?.finish();
    updateSharedOptions(sharedOptions, mode, firstOpts);
  }

  /// The refreshes that the loop left out, for the indexes from [from] until
  /// [to], in their order, before code that can read a context runs.
  // DIVERGES(chartjs): adapt-scatter-overflow-refresh, the end of a plan.
  void _catchUpContexts(
    NativePointContextReader contexts,
    int from,
    int to,
    String mode,
  ) {
    for (var i = from; i < to; i++) {
      if (contexts.read(i) == null) getContext(i, false, mode);
    }
  }

  /// The overflow pass that can take the context refreshes of a loop in the
  /// mode `none`, or Dart `null`: then the loop keeps them.
  ///
  /// The caller has a prepared color plan and is the loop of an [update] under
  /// `update_`. Between its last point and the first context of the pass, only
  /// the read of `clip` stands (core.datasetController.js:705): a scalar raw
  /// value in native scopes runs no user code. Each point of a whole-dataset
  /// loop has qualified as native at its own iteration, or below, if the plan
  /// holds to the end. Thus the pass reads no options object and calls no
  /// `size`: the options of each index differ in their colors only.
  // DIVERGES(chartjs): adapt-scatter-overflow-refresh, the window of the proof.
  _OverflowPass? _prepareOverflowPass(
    List<types.Element> points,
    int start,
    int count,
    PointOptions Function(int) colors,
  ) {
    if (start != 0 ||
        count != points.length ||
        jsTruthy(options.readKey(OptionKey.showLine)) ||
        !nativePointElement(points[0]) ||
        !nativePointElement(points[1]) ||
        !options.rawOptionsAreScalar(const [OptionKey.clip])) {
      return null;
    }
    final fields = NativePointSizeFields.of(colors(1));
    final contexts = prepareNativePointContexts(this, 'default');
    if (fields == null || contexts == null) return null;
    // `max = Math.max(max, size / 2)` from 0, and `max > 0 && max`, of one size.
    final max = math.max<double>(
      0,
      nativePointSize(fields.radius, fields.hoverRadius, fields.borderWidth) /
          2,
    );
    return (overflow: max > 0 ? max : null, contexts: contexts);
  }

  /// controller.scatter.js:156 `getMaxOverflow()`.
  ///
  /// @protected
  ///
  /// - Without `showLine` (:160-166): `max > 0 && max` gives the number or
  ///   `false`, that is, Dart `null` (row `adapt-max-overflow`). `Math.max`
  ///   gives NaN when a size is NaN, and `NaN > 0` is false.
  /// - With `showLine` (:168-177): `dataset.options &&
  ///   dataset.options.borderWidth || 0` keeps the raw value: a truthy
  ///   `borderWidth` is the result, also for an empty data, where the port
  ///   gives its `ToNumber`. `Math.max` applies `ToNumber` to it. A dataset
  ///   element that is Dart `null` throws a [TypeError], as
  ///   `undefined.options` does. The options of a line are a [LineOptions];
  ///   the options of a user element type read by name.
  /// - The cast to `types.PointElement` stands at the upstream read of
  ///   `size` (Chart.js ADR 0028, section 1).
  /// - The size of a native point depends only on three static fields of its
  ///   options. Inside this loop such a point takes one size, of the frozen
  ///   entry or of one plan result (row `adapt-native-point-size`).
  /// - The overflow of `update_` after a loop that left its context refreshes
  ///   to it writes them, in this order (row `adapt-scatter-overflow-refresh`).
  @override
  double? getMaxOverflow() {
    final meta = cachedMeta;
    final data = meta.data;
    // DIVERGES(chartjs): adapt-scatter-overflow-refresh, the last writer of the
    // contexts of a loop that left its refreshes to this pass.
    final pass = _overflowPass;
    _overflowPass = null;
    if (pass != null) {
      final contexts = pass.contexts;
      for (var i = data.length - 1; i >= 0; --i) {
        if (contexts.readQualified(data[i], i) == null) {
          getContext(i, false, 'default');
        }
      }
      return pass.overflow;
    }

    if (!jsTruthy(options.readKey(OptionKey.showLine))) {
      var max = 0.0;
      // DIVERGES(chartjs): adapt-native-point-size, one size inside this loop.
      // A custom point ends it before its options or its `size` can run.
      double? nativeSize;
      NativePointContextReader? contexts;
      var indexed = false;
      final last = data.length - 1;
      for (var i = last; i >= 0; --i) {
        final point = data[i] as types.PointElement;
        if (i == last) nativeSize = _cachedPointSize();
        if (nativeSize != null && !nativePointElement(point)) {
          nativeSize = null;
          indexed = false;
        }
        if (nativeSize == null) {
          max = math.max(max, point.size(resolveDataElementOptions(i)) / 2);
          // The first ordinary resolution makes the entry of constant options.
          if (i == last) nativeSize = _cachedPointSize();
          // No coordinate conversion occurs here: parsed/raw values are only
          // copied into contexts, so qualifying their containers is sufficient.
          if (nativeSize == null && i == last - 1) {
            final prepared = _preparePointColors(data);
            final fields = prepared == null
                ? null
                : NativePointSizeFields.of(prepared(i));
            if (fields != null) {
              nativeSize = nativePointSize(
                fields.radius,
                fields.hoverRadius,
                fields.borderWidth,
              );
              indexed = true;
              contexts = prepareNativePointContexts(this, 'default');
            }
          }
        } else {
          // Indexed options refresh the context of each point, as upstream.
          if (indexed && contexts?.readQualified(point, i) == null) {
            getContext(i, false, 'default');
          }
          max = math.max(max, nativeSize / 2);
        }
      }
      return max > 0 ? max : null;
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
      return jsToNumber(border);
    }

    final firstPoint = (data[0] as types.PointElement).size(
      resolveDataElementOptions(0),
    );
    final lastPoint = (data[data.length - 1] as types.PointElement).size(
      resolveDataElementOptions(data.length - 1),
    );
    return math.max(math.max(jsToNumber(border), firstPoint), lastPoint) / 2;
  }

  /// The size of the frozen `point-default` entry for the exact controller:
  /// its ordinary resolve only copies that entry. Dart `null` without one.
  // DIVERGES(chartjs): adapt-native-point-size, one size inside the loop.
  double? _cachedPointSize() {
    if (super.runtimeType != ScatterController) return null;
    final fields = cachedNativePointSizeFields(this);
    return fields == null
        ? null
        : nativePointSize(
            fields.radius,
            fields.hoverRadius,
            fields.borderWidth,
          );
  }

  // The existing numeric-scale capability guarantees built-in projection and
  // base-pixel reads. The scale's chart must provide the same native DPR reads.
  bool _nativeProjection(types.Scale scale) =>
      nativePointProjection(scale) && identical(scale.chart, chart);

  // DIVERGES(chartjs): adapt-native-point-contracts, shared preparation rules.
  PointOptions Function(int)? _preparePointColors(List<types.Element> points) {
    if (super.runtimeType != ScatterController || type != 'scatter') {
      return null;
    }
    return prepareNativePointColors(this, points, controllerType: 'scatter');
  }
}
