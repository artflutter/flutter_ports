// Ported from d3-shape v3.2.0 src/order/appearance.js (ISC, Mike Bostock).

/// Port of `src/order/appearance.js` of d3-shape 3.2.0: [stackOrderAppearance].
library;

import 'dart:typed_data';

import 'package:flutter_d3_shape_port/src/stack.dart';

/// `order/appearance.js:3` default export: orders series by the index of their
/// earliest maximum value.
// DIVERGES(d3-shape): adapt-shape-fast-forms, Int32List peaks and inline stable
// insertion sort for n <= 32.
List<int> stackOrderAppearance(List<StackSeries<Object?, Object?>> series) {
  final n = series.length;
  final peaks = Int32List(n);
  final order = List<int>.filled(n, 0);
  for (var k = 0; k < n; ++k) {
    order[k] = k;
    peaks[k] = _peak(series[k]);
  }
  // DIVERGES(d3-shape): adapt-shape-stable-sort, tie-break by original index.
  if (n <= 32) {
    for (var i = 1; i < n; ++i) {
      final idx = order[i];
      final pk = peaks[idx];
      var j = i - 1;
      while (j >= 0 && peaks[order[j]] > pk) {
        order[j + 1] = order[j];
        --j;
      }
      order[j + 1] = idx;
    }
  } else {
    order.sort((a, b) {
      final diff = peaks[a] - peaks[b];
      return diff != 0 ? diff : a - b;
    });
  }
  return order;
}

int _peak(StackSeries<Object?, Object?> series) {
  var j = 0;
  final pts = series.points;
  final n = pts.length;
  var vj = double.negativeInfinity;
  for (var i = 0; i < n; ++i) {
    final vi = pts[i].y1;
    if (vi > vj) {
      vj = vi;
      j = i;
    }
  }
  return j;
}
