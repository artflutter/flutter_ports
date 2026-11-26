// Ported from d3-shape v3.2.0 src/order/ascending.js (ISC, Mike Bostock).

/// Port of `src/order/ascending.js` of d3-shape 3.2.0: [stackOrderAscending]
/// and [stackOrderSum].
library;

import 'dart:typed_data';

import 'package:flutter_d3_shape_port/src/stack.dart';

/// `order/ascending.js:3` default export: orders series so the smallest sum
/// is at the bottom.
// DIVERGES(d3-shape): adapt-shape-fast-forms, Float64List sums and inline
// stable insertion sort for n <= 32.
List<int> stackOrderAscending(List<StackSeries<Object?, Object?>> series) {
  final n = series.length;
  final sums = Float64List(n);
  final order = List<int>.filled(n, 0);
  for (var k = 0; k < n; ++k) {
    order[k] = k;
    sums[k] = stackOrderSum(series[k]);
  }
  // DIVERGES(d3-shape): adapt-shape-stable-sort, tie-break by original index.
  if (n <= 32) {
    for (var i = 1; i < n; ++i) {
      final idx = order[i];
      final s = sums[idx];
      var j = i - 1;
      while (j >= 0 && sums[order[j]] > s) {
        order[j + 1] = order[j];
        --j;
      }
      order[j + 1] = idx;
    }
  } else {
    order.sort((a, b) {
      final d = sums[a] - sums[b];
      return d < 0 ? -1 : (d > 0 ? 1 : a - b);
    });
  }
  return order;
}

/// `order/ascending.js:8` `sum`: sums non-NaN topline values of [series].
double stackOrderSum(StackSeries<Object?, Object?> series) {
  var s = 0.0;
  final pts = series.points;
  final n = pts.length;
  for (var i = 0; i < n; ++i) {
    final v = pts[i].y1;
    if (v != 0 && v == v) s += v;
  }
  return s;
}
