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
import 'package:flutter_chartjs/src/elements/element.point.dart';
import 'package:flutter_chartjs/src/helpers/helpers.core.dart'
    show isNullOrUndef;
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
/// Phase 5 has no concrete controller and no scale. Thus the gallery
/// registers this subclass of the ported `DatasetController` through its
/// class value [jsClass] (Chart.js ADR 0020, sections 3 and 8). The chart
/// type and the dataset type are [id].
///
/// - [initialize] sets `enableOptionSharing` as controller.line.js:36-38
///   does. The dataset option `optionSharing: false` turns the sharing off,
///   so that the stress mode can compare a line chart (each point holds the
///   copy of `getSharedOptions`) with a scatter chart (each point gets a copy
///   of the cache entry at each update).
/// - The defaults have `parsing: false`. [parse] is the branch of
///   `parsing: false` of core.datasetController.js:451-462: the data
///   objects `{x, y}` are the parsed items. The upstream method reads
///   `iScale.axis` first (:454), and the chart has no scale before phase 6.
///   With `parsing: false`, `_insertElements` also leaves the parsed items
///   as they are (:1012-1014): they are the data array.
/// - [updateElements] follows controller.line.js:76-120: the port of
///   `_getSharedOptions`, `resolveDataElementOptions` and `updateElement`.
///   It computes the pixel positions itself, because the scales come in
///   phase 6: `x` and `y` are fractions of the chart area, with `y` upward.
///   The base pixel of a reset is the bottom of the chart area.
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

  /// controller.line.js:35 `initialize()`.
  @override
  void initialize() {
    // controller.line.js:36 `this.enableOptionSharing = true`, unless the
    // dataset option `optionSharing` is false.
    enableOptionSharing = jsGet(getDataset(), 'optionSharing') != false;
    supportsDecimation = true;
    super.initialize();
  }

  /// core.datasetController.js:451 `parse(start, count)` with
  /// `parsing: false` (:460-462): `meta._parsed = data`, and the data is
  /// sorted. Another `parsing` option takes the upstream method, which
  /// needs the scales of phase 6.
  @override
  void parse(double start, double count) {
    if (parsing != false) {
      super.parse(start, count);
      return;
    }
    final data = jsGet(getDataset(), 'data')! as List<Object?>;
    cachedMeta
      ..parsed = data
      ..sorted = true;
  }

  /// controller.line.js:41 `update(mode)`, without the line: the points.
  @override
  void update(String mode) {
    final points = cachedMeta.data;
    updateElements(points, 0, points.length.toDouble(), mode);
  }

  /// controller.line.js:76 `updateElements(points, start, count, mode)`.
  ///
  /// The pixels come from the chart area, not from `iScale` and `vScale`
  /// (see the class). The keys `x` and `y` stand for `iAxis` and `vAxis`.
  /// A direct update writes the properties of the point with its setters,
  /// as `properties = point` of :91 writes them by name. The other modes
  /// give the object `properties` to `updateElement`, in the key order of
  /// :100-111.
  @override
  void updateElements(
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

/// Registers the built-in components of phase 5 (`registerables`, as
/// `src/index.umd.ts:28` does) and [StressPointController], once.
void registerGalleryComponents() {
  if (_registered) return;
  _registered = true;
  Chart.register(registerables);
  Chart.register([StressPointController.jsClass]);
}
