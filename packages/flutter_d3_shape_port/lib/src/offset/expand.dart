// Ported from d3-shape v3.2.0 src/offset/expand.js (ISC, Mike Bostock).

/// Port of `src/offset/expand.js` of d3-shape 3.2.0: [stackOffsetExpand].
library;

import 'package:flutter_d3_shape_port/src/offset/none.dart';
import 'package:flutter_d3_shape_port/src/stack.dart';

/// `offset/expand.js:3` default export: applies a zero baseline and normalizes
/// values for each point such that the topline is always `1`.
void stackOffsetExpand(
  List<StackSeries<Object?, Object?>> series,
  List<int> order,
) {
  final n = series.length;
  if (n <= 0) return;
  final m = series[0].length;
  for (var j = 0; j < m; ++j) {
    var y = 0.0;
    for (var i = 0; i < n; ++i) {
      final v = series[i][j].y1;
      if (!v.isNaN) y += v;
    }
    if (y != 0) {
      for (var i = 0; i < n; ++i) {
        series[i][j].y1 /= y;
      }
    }
  }
  stackOffsetNone(series, order);
}
