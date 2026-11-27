// Ported from d3-array v3.2.4 src/zip.js (ISC, Mike Bostock).

/// Port of `src/zip.js` of d3-array 3.2.4.
library;

import 'dart:math' as math;

import 'package:flutter_d3_array_port/src/transpose.dart';

/// Returns a list of lists where the `i`-th list contains the `i`-th element
/// from each list in [arrays], truncated to the shortest list.
// DIVERGES(d3-array): adapt-array-typed-api, takes List<List<T>> plus typed
// tuple zip2 and zip3 helpers.
List<List<T>> zip<T>(List<List<T>> arrays) => transpose<T>(arrays);

/// Zips two lists [a] and [b] into a list of `(A, B)` records, truncated to
/// the shorter list.
List<(A, B)> zip2<A, B>(List<A> a, List<B> b) {
  final n = math.min(a.length, b.length);
  return List<(A, B)>.generate(n, (i) => (a[i], b[i]));
}

/// Zips three lists [a], [b], and [c] into a list of `(A, B, C)` records,
/// truncated to the shortest list.
List<(A, B, C)> zip3<A, B, C>(List<A> a, List<B> b, List<C> c) {
  final n = math.min(a.length, math.min(b.length, c.length));
  return List<(A, B, C)>.generate(n, (i) => (a[i], b[i], c[i]));
}
