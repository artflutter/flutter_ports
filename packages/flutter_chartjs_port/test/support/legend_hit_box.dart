// Original code, not ported from Chart.js: native legend hit-box expectations.

/// Decoding of frozen upstream hit-box expectations.
library;

import 'package:flutter_chartjs_port/src/types/legend_hit_box.dart';

/// Decodes a frozen upstream result into a native expected box.
LegendHitBox legendHitBoxFromReference(Map<String, Object?> reference) {
  final left = (reference['left']! as num).toDouble();
  final top = (reference['top']! as num).toDouble();
  final width = (reference['width']! as num).toDouble();
  final height = (reference['height']! as num).toDouble();
  if (reference['row'] case final num row) {
    return LegendHitBox.row(
      left: left,
      top: top,
      width: width,
      height: height,
      row: row.toInt(),
    );
  }
  return LegendHitBox.col(
    left: left,
    top: top,
    width: width,
    height: height,
    col: (reference['col']! as num).toInt(),
  );
}

/// Identifies the complete hit-box records in frozen upstream observations.
bool isLegendHitBoxReference(Map<String, Object?> value) =>
    value.containsKey('left') &&
    value.containsKey('top') &&
    value.containsKey('width') &&
    value.containsKey('height') &&
    (value.containsKey('row') || value.containsKey('col'));
