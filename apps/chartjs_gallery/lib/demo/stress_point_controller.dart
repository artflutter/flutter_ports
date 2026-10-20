// Original code, not ported from Chart.js: a gallery point controller.

// The package exports nothing from lib/src yet; the public API comes in
// phase 9. The demo imports the ported files directly.
// ignore_for_file: implementation_imports
// The controller is a subclass of DatasetController, as a port of a
// controller of phase 7 is. Such a subclass calls the @internal members of
// the base class (Chart.js ADR 0012 drops their underscore).
// ignore_for_file: invalid_use_of_internal_member

import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/core/core.datasetController.dart';
import 'package:flutter_chartjs/src/core/core.scale.dart' show Scale;
import 'package:flutter_chartjs/src/elements/element.point.dart';
import 'package:flutter_chartjs/src/helpers/helpers.core.dart'
    show isNullOrUndef;
import 'package:flutter_chartjs/src/helpers/helpers.extras.dart'
    show getStartAndCountOfVisiblePoints, scaleRangesChanged;
import 'package:flutter_chartjs/src/helpers/helpers.math.dart' show isNumber;
import 'package:flutter_chartjs/src/index.dart' show registerables;
import 'package:flutter_chartjs/src/js/js_class.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs/src/types/basic.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;

/// A dataset controller of points for the gallery (Chart.js ADR 0021,
/// section 8): the data element type is `PointElement`, and the dataset has
/// no dataset element.
///
/// The port has no concrete controller before phase 7. Thus the gallery
/// registers this subclass of the ported `DatasetController` through its
/// class value [jsClass] (Chart.js ADR 0020, sections 3 and 8). The chart
/// type and the dataset type are [id].
///
/// The controller has two paths:
/// - The scale path, for a chart with scales (the Axes tab and the stress
///   mode `axes`). The meta has an `iScale` and a `vScale`. [parse] is the
///   upstream method, and [update] and [updateElements] follow
///   controller.scatter.js:56-108 and controller.line.js:76-120: each point
///   gets the pixels of `iScale.getPixelForValue` and
///   `vScale.getPixelForValue`.
/// - The fraction path, for a chart without scales (the Core tab and the
///   stress mode `chart` of phase 5). The meta has no `iScale`. The data
///   objects `{x, y}` are fractions of the chart area, with `y` upward. This
///   path keeps the phase 5 figures of
///   `packages/flutter_chartjs/doc/performance.md` comparable.
///
/// - [initialize] sets `enableOptionSharing` as controller.line.js:36-38
///   does. The dataset option `optionSharing: false` turns the sharing off,
///   so that the stress mode can compare a line chart (each point holds the
///   copy of `getSharedOptions`) with a scatter chart (each point gets a copy
///   of the cache entry at each update).
/// - The defaults have `parsing: false`. A dataset can set another
///   `parsing` option, which needs the scale path.
///
/// Phase 7 measures the same scenarios with the ported `LineController` and
/// `ScatterController`. Then it removes this class.
final class StressPointController extends DatasetController {
  /// `new StressPointController(chart, datasetIndex)`. [newTarget] is
  /// `new.target` (Chart.js ADR 0020, section 4).
  StressPointController(super.chart, super.datasetIndex, [super.newTarget]);

  /// The id of the controller: `static id = 'stressPoint'`.
  static const String id = 'stressPoint';

  /// The defaults of the controller: points without a dataset element
  /// (controller.line.js:13-19 has `datasetElementType: 'line'`), and the
  /// data objects as the parsed items.
  static final AnyObject defaults = {
    'datasetElementType': false,
    'dataElementType': 'point',
    'parsing': false,
  };

  /// `class StressPointController extends DatasetController` as a value
  /// (Chart.js ADR 0020, section 3).
  static final JsClass jsClass = JsClass(
    'StressPointController',
    superclass: DatasetController.jsClass,
    statics: {'id': id, 'defaults': defaults},
    construct: (newTarget, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return StressPointController(chart, datasetIndex, newTarget);
    },
  );

  /// Whether the meta has the scales of the scale path.
  bool get _onScales => cachedMeta.iScale != null && cachedMeta.vScale != null;

  /// controller.line.js:35 `initialize()`.
  @override
  void initialize() {
    // controller.line.js:36 `this.enableOptionSharing = true`, unless the
    // dataset option `optionSharing` is false.
    enableOptionSharing = jsGet(getDataset(), 'optionSharing') != false;
    supportsDecimation = true;
    super.initialize();
  }

  /// core.datasetController.js:451 `parse(start, count)`.
  ///
  /// The scale path and a `parsing` option other than false take the
  /// upstream method. The fraction path with `parsing: false` takes the
  /// branch of :460-462 alone: `meta._parsed = data`, and the data is
  /// sorted. The upstream method reads `iScale.axis` first (:454), and the
  /// fraction path has no scale. With `parsing: false`, `_insertElements`
  /// also leaves the parsed items as they are (:1012-1014): they are the
  /// data array.
  @override
  void parse(double start, double count) {
    if (parsing != false || _onScales) {
      super.parse(start, count);
      return;
    }
    final data = jsGet(getDataset(), 'data')! as List<Object?>;
    cachedMeta
      ..parsed = data
      ..sorted = true;
  }

  /// controller.scatter.js:56 `update(mode)` with `showLine: false`, and
  /// controller.line.js:41 without the line: the points.
  ///
  /// The scale path gets the visible range of the points from the user
  /// bounds of `iScale` (:60-64), and all points when the ranges of the
  /// scales change (:66-69). The fraction path updates all points.
  @override
  void update(String mode) {
    final meta = cachedMeta;
    final points = meta.data;
    if (!_onScales) {
      updateElements(points, 0, points.length.toDouble(), mode);
      return;
    }
    final animationsDisabled = jsTruthy(chart.animationsDisabled);
    var (:start, :count) = getStartAndCountOfVisiblePoints(
      meta,
      points.cast<PointElement>(),
      animationsDisabled,
    );

    drawStart = start;
    drawCount = count;

    if (scaleRangesChanged(meta)) {
      start = 0;
      count = points.length.toDouble();
    }

    // Update Points
    updateElements(points, start, count, mode);
  }

  /// controller.line.js:76 `updateElements(points, start, count, mode)`.
  ///
  /// The port of `_getSharedOptions`, `resolveDataElementOptions` and
  /// `updateElement`. A direct update writes the properties of the point
  /// with its setters, as `properties = point` of :91 writes them by name.
  /// The other modes give the object `properties` to `updateElement`, in the
  /// key order of :100-111.
  ///
  /// The scale path maps the parsed values with the scales (:97-98). The
  /// fraction path computes the pixels from the chart area: the keys `x`
  /// and `y` stand for `iAxis` and `vAxis`, and the base pixel of a reset is
  /// the bottom of the chart area. Neither path has the `segment` option:
  /// the points have no line.
  @override
  void updateElements(
    List<types.Element> points,
    double start,
    double count,
    String mode,
  ) {
    final meta = cachedMeta;
    final iScale = meta.iScale;
    final vScale = meta.vScale;
    if (iScale != null && vScale != null) {
      _updateOnScales(points, start, count, mode, iScale, vScale);
    } else {
      _updateFractions(points, start, count, mode);
    }
  }

  /// controller.line.js:76-120, the scale path.
  ///
  /// Each scale gets the raw parsed value `parsed[axis]` (Chart.js ADR 0025,
  /// section 9). The index axis of the gallery charts is `x`. The writes of
  /// a direct update go to the setters of the axes of `iScale` and `vScale`.
  void _updateOnScales(
    List<types.Element> points,
    double start,
    double count,
    String mode,
    types.Scale iScale,
    types.Scale vScale,
  ) {
    final reset = mode == 'reset';
    final stacked = cachedMeta.stacked;
    final (:sharedOptions, :includeOptions) = getSharedOptions_(start, mode);
    final iAxis = iScale.axis;
    final vAxis = vScale.axis;
    final indexIsX = iAxis == 'x';
    final spanGaps = jsGet(options, 'spanGaps');
    final maxGapLength = isNumber(spanGaps)
        ? jsToNumber(spanGaps)
        : double.infinity;
    final directUpdate =
        jsTruthy(chart.animationsDisabled) || reset || mode == 'none';
    final end = start + count;
    final pointsCount = points.length;
    var prevParsed = start > 0 ? getParsed(start - 1) : null;

    for (var i = 0; i < pointsCount; ++i) {
      final point = points[i] as PointElement;

      if (i < start || i >= end) {
        // `properties.skip = true`: a write into the point only for a
        // direct update.
        if (directUpdate) point.skip = true;
        continue;
      }

      final index = i.toDouble();
      final parsed = getParsed(index);
      final iValue = jsGet(parsed, iAxis);
      final vValue = jsGet(parsed, vAxis);
      final nullData = isNullOrUndef(vValue);
      final iPixel = iScale.getPixelForValue(iValue, index);
      final vPixel = reset || nullData
          ? (vScale as Scale).getBasePixel()
          : vScale.getPixelForValue(
              jsTruthy(stacked) ? applyStack(vScale, parsed, stacked) : vValue,
              index,
            );
      final skip = iPixel.isNaN || vPixel.isNaN || nullData;
      final stop =
          i > 0 &&
          (jsToNumber(iValue) - jsToNumber(jsGet(prevParsed, iAxis))).abs() >
              maxGapLength;
      final Object? elementOptions = includeOptions
          ? sharedOptions ??
                resolveDataElementOptions(
                  index,
                  point.active ? 'active' : mode,
                )
          : null;

      if (directUpdate) {
        if (indexIsX) {
          point
            ..x = iPixel
            ..y = vPixel;
        } else {
          point
            ..x = vPixel
            ..y = iPixel;
        }
        point
          ..skip = skip
          ..stop = stop;
        if (includeOptions) point.options = elementOptions! as AnyObject;
      } else {
        final properties = <String, Object?>{
          iAxis: iPixel,
          vAxis: vPixel,
          'skip': skip,
          'stop': stop,
          'options': ?elementOptions,
        };
        updateElement(point, index, properties, mode);
      }

      prevParsed = parsed;
    }
  }

  /// controller.line.js:76-120, the fraction path: `x` and `y` are
  /// fractions of the chart area.
  void _updateFractions(
    List<types.Element> points,
    double start,
    double count,
    String mode,
  ) {
    final reset = mode == 'reset';
    final (:sharedOptions, :includeOptions) = getSharedOptions_(start, mode);
    final area = chart.chartArea;
    final left = area?.left ?? 0;
    final width = area?.width ?? chart.width;
    final bottom = area?.bottom ?? chart.height;
    final height = area?.height ?? chart.height;
    final spanGaps = jsGet(options, 'spanGaps');
    final maxGapLength = isNumber(spanGaps)
        ? jsToNumber(spanGaps)
        : double.infinity;
    final directUpdate =
        jsTruthy(chart.animationsDisabled) || reset || mode == 'none';
    final end = start + count;
    final pointsCount = points.length;
    var prevParsed = start > 0 ? getParsed(start - 1) : null;

    for (var i = 0; i < pointsCount; ++i) {
      final point = points[i] as PointElement;

      if (i < start || i >= end) {
        // `properties.skip = true`: a write into the point only for a
        // direct update.
        if (directUpdate) point.skip = true;
        continue;
      }

      final index = i.toDouble();
      // The data objects of the stress scene are Maps.
      final parsed = getParsed(index)! as Map<dynamic, dynamic>;
      final parsedX = parsed['x'];
      final parsedY = parsed['y'];
      final nullData = isNullOrUndef(parsedY);
      final iPixel = left + jsToNumber(parsedX) * width;
      final vPixel = reset || nullData
          ? bottom
          : bottom - jsToNumber(parsedY) * height;
      final skip = iPixel.isNaN || vPixel.isNaN || nullData;
      final stop =
          i > 0 &&
          (jsToNumber(parsedX) - jsToNumber(jsGet(prevParsed, 'x'))).abs() >
              maxGapLength;
      final Object? elementOptions = includeOptions
          ? sharedOptions ??
                resolveDataElementOptions(
                  index,
                  point.active ? 'active' : mode,
                )
          : null;

      if (directUpdate) {
        point
          ..x = iPixel
          ..y = vPixel
          ..skip = skip
          ..stop = stop;
        if (includeOptions) point.options = elementOptions! as AnyObject;
      } else {
        final properties = <String, Object?>{
          'x': iPixel,
          'y': vPixel,
          'skip': skip,
          'stop': stop,
          'options': ?elementOptions,
        };
        updateElement(point, index, properties, mode);
      }

      prevParsed = parsed;
    }
  }
}

bool _registered = false;

/// Registers the built-in components (`registerables`, as
/// `src/index.umd.ts:28` does: the elements and the scales of phase 6) and
/// [StressPointController], once.
void registerGalleryComponents() {
  if (_registered) return;
  _registered = true;
  Chart.register(registerables);
  Chart.register([StressPointController.jsClass]);
}
