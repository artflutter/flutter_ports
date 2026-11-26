// Ported from d3-shape v3.2.0 src/order/insideOut.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/order/insideOut.js` of d3-shape 3.2.0: [stackOrderInsideOut].
library;

import 'dart:typed_data';

import 'package:flutter_d3_shape_port/src/stack.dart';

/// `order/insideOut.js:4` default export: orders series by earliest maximum
/// with larger series inside and smaller series on the outside (recommended
/// for streamgraphs).
// DIVERGES(d3-shape): adapt-shape-fast-forms, single-pass sums+peaks with
// Float64List/Int32List and inline stable insertion sort for n <= 32.
List<int> stackOrderInsideOut(List<StackSeries<Object?, Object?>> series) {
  final n = series.length;
  if (n == 0) return const [];
  final sums = Float64List(n);
  final peaks = Int32List(n);
  final order = Int32List(n);

  for (var k = 0; k < n; ++k) {
    order[k] = k;
    final pts = series[k].points;
    final m = pts.length;
    var sum = 0.0;
    var peakIdx = 0;
    var peakVal = double.negativeInfinity;
    for (var i = 0; i < m; ++i) {
      final v = pts[i].y1;
      if (v != 0 && v == v) sum += v;
      if (v > peakVal) {
        peakVal = v;
        peakIdx = i;
      }
    }
    sums[k] = sum;
    peaks[k] = peakIdx;
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

  var top = 0.0;
  var bottom = 0.0;
  final result = List<int>.filled(n, 0);
  var bottomCount = 0;
  var topCount = 0;
  final tops = Int32List(n);

  for (var i = 0; i < n; ++i) {
    final j = order[i];
    if (top < bottom) {
      top += sums[j];
      tops[topCount++] = j;
    } else {
      bottom += sums[j];
      result[bottomCount++] = j;
    }
  }

  // Reverse the bottoms prefix in place, then append tops.
  for (var l = 0, r = bottomCount - 1; l < r; ++l, --r) {
    final tmp = result[l];
    result[l] = result[r];
    result[r] = tmp;
  }
  for (var i = 0; i < topCount; ++i) {
    result[bottomCount + i] = tops[i];
  }
  return result;
}
