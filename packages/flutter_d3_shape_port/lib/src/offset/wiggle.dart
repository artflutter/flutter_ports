// Ported from d3-shape v3.2.0 src/offset/wiggle.js (ISC, Mike Bostock).

/// Port of `src/offset/wiggle.js` of d3-shape 3.2.0: [stackOffsetWiggle].
library;

import 'package:flutter_d3_shape_port/src/offset/none.dart';
import 'package:flutter_d3_shape_port/src/stack.dart';

/// `offset/wiggle.js:3` default export: shifts the baseline to minimize the
/// weighted wiggle of layers (recommended for streamgraphs).
// DIVERGES(d3-shape): adapt-shape-fast-forms, O(n*m) running prefix sum instead
// of O(n^2*m) inner k-loop, plus cached ordered points lists.
void stackOffsetWiggle(
  List<StackSeries<Object?, Object?>> series,
  List<int> order,
) {
  final n = series.length;
  if (n <= 0) return;
  final p0s = series[order[0]].points;
  final m = p0s.length;
  if (m <= 0) return;

  final ordered = List<List<StackPoint<Object?>>>.filled(n, p0s);
  for (var i = 1; i < n; ++i) {
    ordered[i] = series[order[i]].points;
  }

  var y = 0.0;
  for (var j = 1; j < m; ++j) {
    var s1 = 0.0;
    var s2 = 0.0;
    var prefix = 0.0;
    for (var i = 0; i < n; ++i) {
      final pts = ordered[i];
      final v0 = pts[j].y1;
      final v1 = pts[j - 1].y1;
      final sij0 = v0 == v0 ? v0 : 0.0;
      final sij1 = v1 == v1 ? v1 : 0.0;
      final diff = sij0 - sij1;
      final s3 = diff * 0.5 + prefix;
      prefix += diff;
      s1 += sij0;
      s2 += s3 * sij0;
    }
    p0s[j - 1]
      ..y0 = y
      ..y1 += y;
    if (s1 != 0) y -= s2 / s1;
  }
  p0s[m - 1]
    ..y0 = y
    ..y1 += y;
  stackOffsetNone(series, order);
}
