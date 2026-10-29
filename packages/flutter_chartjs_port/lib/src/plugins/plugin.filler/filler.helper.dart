// Ported from Chart.js v4.6.1 src/plugins/plugin.filler/filler.helper.js (MIT, Chart.js Contributors).

/// Port of `src/plugins/plugin.filler/filler.helper.js`.
///
/// `filler.helper.js:7` imports `LineElement` from `elements/index.js`. This
/// file imports `element.line.dart` for the class.
///
/// This library is a pure layer (Chart.js ADR 0038, section 9).
library;

import 'package:flutter_chartjs_port/src/elements/element.line.dart'
    show LineElement;
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show isArray;
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/filler.segment.dart'
    show pointsFromSegments;
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/index.dart'
    show FillerSource;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

/// filler.helper.js:16 `_createBoundaryLine(boundary, line)`.
///
/// @param {PointElement[] | { x: number; y: number; }} boundary
/// @param {LineElement} line
/// @return {LineElement?}
///
/// [boundary] is a `List<types.PointElement>` (the polygon of
/// filler.target.js:90-93), the record of `computeLinearBoundary` or of
/// filler.target.stack.js:21, or Dart `null`. The line config is the
/// literal upstream form (Chart.js ADR 0040, section 1).
types.LineElement? createBoundaryLine(
  Object? boundary,
  types.LineElement line,
) {
  var points = <types.PointElement>[];
  var loop = false;

  if (isArray(boundary)) {
    loop = true;
    points = boundary! as List<types.PointElement>;
  } else {
    points = pointsFromSegments(boundary as ({double? x, double? y})?, line);
  }

  return points.isNotEmpty
      ? LineElement(<String, Object?>{
          'points': points,
          'options': <String, Object?>{'tension': 0.0},
          '_loop': loop,
          '_fullLoop': loop,
        })
      : null;
}

/// filler.helper.js:36 `_shouldApplyFill(source)`.
///
/// `source && source.fill !== false`: the port writes only Dart `null` and
/// a [FillerSource] into `meta.$filler`, and an absent property reads
/// `undefined` (Chart.js ADR 0040, section 6).
bool shouldApplyFill(Object? source) =>
    source is FillerSource && source.fill != false;
