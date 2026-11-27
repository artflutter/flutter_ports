// Ported from d3-contour v4.0.2 src/area.js (ISC, Mike Bostock).

/// Port of `src/area.js` of d3-contour 4.0.2.
library;

/// Returns twice the signed area of a closed contour [ring].
///
/// Positive area indicates an exterior ring; non-positive area indicates a
/// hole.
// DIVERGES(d3-contour): adapt-contour-typed-api, contour-prefixed helper taking
// typed `List<(double, double)>` to avoid colliding with `d3-shape`'s `area`.
// DIVERGES(d3-contour): adapt-contour-fast-forms, carries previous vertex in
// unboxed local variables to avoid double-indexing each element.
double contourRingArea(List<(double, double)> ring) {
  final n = ring.length;
  if (n == 0) return 0;
  var (px, py) = ring[n - 1];
  var area = 0.0;
  for (var i = 0; i < n; ++i) {
    final (cx, cy) = ring[i];
    area += py * cx - px * cy;
    px = cx;
    py = cy;
  }
  return area;
}
