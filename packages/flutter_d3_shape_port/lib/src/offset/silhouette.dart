// Ported from d3-shape v3.2.0 src/offset/silhouette.js (ISC, Mike Bostock).

/// Port of `src/offset/silhouette.js` of d3-shape 3.2.0:
/// [stackOffsetSilhouette].
library;

import 'package:flutter_d3_shape_port/src/offset/none.dart';
import 'package:flutter_d3_shape_port/src/stack.dart';

/// `offset/silhouette.js:3` default export: shifts the baseline down by half
/// the sum of the stream values so the stream is centered around zero.
void stackOffsetSilhouette(
  List<StackSeries<Object?, Object?>> series,
  List<int> order,
) {
  final n = series.length;
  if (n <= 0) return;
  final s0 = series[order[0]];
  final m = s0.length;
  for (var j = 0; j < m; ++j) {
    var y = 0.0;
    for (var i = 0; i < n; ++i) {
      final v = series[i][j].y1;
      if (!v.isNaN) y += v;
    }
    final base = -y / 2;
    s0[j].y0 = base;
    s0[j].y1 += base;
  }
  stackOffsetNone(series, order);
}
