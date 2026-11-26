// Ported from d3-shape v3.2.0 src/offset/none.js (ISC, Mike Bostock).

/// Port of `src/offset/none.js` of d3-shape 3.2.0: [stackOffsetNone].
library;

import 'package:flutter_d3_shape_port/src/stack.dart';

/// `offset/none.js:1` default export: applies a zero baseline.
// DIVERGES(d3-shape): adapt-shape-fast-forms, direct points list indexing.
void stackOffsetNone(
  List<StackSeries<Object?, Object?>> series,
  List<int> order,
) {
  final n = series.length;
  if (n <= 1) return;
  var p1s = series[order[0]].points;
  final m = p1s.length;
  for (var i = 1; i < n; ++i) {
    final p0s = p1s;
    p1s = series[order[i]].points;
    for (var j = 0; j < m; ++j) {
      final p0 = p0s[j];
      final y1 = p0.y1;
      final y = y1 == y1 ? y1 : p0.y0;
      p1s[j]
        ..y0 = y
        ..y1 += y;
    }
  }
}
