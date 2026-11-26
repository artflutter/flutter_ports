// Ported from d3-shape v3.2.0 src/offset/diverging.js (ISC, Mike Bostock).

/// Port of `src/offset/diverging.js` of d3-shape 3.2.0: [stackOffsetDiverging].
library;

import 'package:flutter_d3_shape_port/src/stack.dart';

/// `offset/diverging.js:1` default export: stacks positive values above zero
/// and negative values below zero.
void stackOffsetDiverging(
  List<StackSeries<Object?, Object?>> series,
  List<int> order,
) {
  final n = series.length;
  if (n <= 0) return;
  final m = series[order[0]].length;
  for (var j = 0; j < m; ++j) {
    var yp = 0.0;
    var yn = 0.0;
    for (var i = 0; i < n; ++i) {
      final d = series[order[i]][j];
      final dy = d.y1 - d.y0;
      if (dy > 0) {
        d.y0 = yp;
        yp += dy;
        d.y1 = yp;
      } else if (dy < 0) {
        d.y1 = yn;
        yn += dy;
        d.y0 = yn;
      } else {
        d
          ..y0 = 0
          ..y1 = dy;
      }
    }
  }
}
