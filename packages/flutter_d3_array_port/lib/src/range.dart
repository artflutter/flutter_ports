// Ported from d3-array v3.2.4 src/range.js (ISC, Mike Bostock).

/// Port of `src/range.js` of d3-array 3.2.4.
library;

import 'dart:typed_data';

/// Returns a list of an arithmetic progression of numbers starting at [start]
/// (inclusive) up to [stop] (exclusive) in increments of [step].
///
/// If [stop] is omitted, returns `[0, 1, ..., start - 1]`. If [step] is
/// omitted, defaults to `1`.
// DIVERGES(d3-array): adapt-array-typed-api, returns List<double> with optional
// stop and step parameters.
// DIVERGES(d3-array): adapt-array-fast-forms, unboxed Float64List output
// avoiding per-element double heap boxing on AOT and Wasm.
List<double> range(num start, [num? stop, num? step]) {
  final double s0;
  final double s1;
  final double st;
  if (stop == null) {
    s0 = 0.0;
    s1 = start.toDouble();
    st = 1.0;
  } else {
    s0 = start.toDouble();
    s1 = stop.toDouble();
    st = step?.toDouble() ?? 1.0;
  }
  final raw = (s1 - s0) / st;
  if (!raw.isFinite || raw <= 0) return Float64List(0);
  final n = raw.ceil();
  if (n <= 0) return Float64List(0);
  final out = Float64List(n);
  for (var i = 0; i < n; ++i) {
    out[i] = s0 + i * st;
  }
  return out;
}
