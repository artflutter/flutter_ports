// Ported from d3-contour v4.0.2 src/contains.js (ISC, Mike Bostock).

/// Port of `src/contains.js` of d3-contour 4.0.2.
library;

/// Tests whether [ring] contains [hole].
///
/// Returns `1` if [hole] is strictly inside [ring], `-1` if outside, or `0` if
/// all vertices of [hole] lie on the boundary of [ring].
// DIVERGES(d3-contour): adapt-contour-typed-api, contour-prefixed typed helper
// operating on `List<(double, double)>`.
// DIVERGES(d3-contour): adapt-contour-fast-forms, inlined edge-box pre-filter
// and unboxed local coordinates avoiding per-edge collinearity multiplications
// and unnecessary ray divisions.
int contourContains(List<(double, double)> ring, List<(double, double)> hole) {
  final hn = hole.length;
  final rn = ring.length;
  if (rn == 0) return -1;
  for (var k = 0; k < hn; ++k) {
    final (x, y) = hole[k];
    final c = _ringContains(ring, rn, x, y);
    if (c != 0) return c;
  }
  return 0;
}

@pragma('vm:prefer-inline')
int _ringContains(List<(double, double)> ring, int n, double x, double y) {
  var contains = -1;
  var (xj, yj) = ring[n - 1];
  for (var i = 0; i < n; ++i) {
    final (xi, yi) = ring[i];
    // Fast segment-bounds check before exact collinearity test.
    if (((xi <= x && x <= xj) || (xj <= x && x <= xi)) &&
        ((yi <= y && y <= yj) || (yj <= y && y <= yi)) &&
        (xj - xi) * (y - yi) == (x - xi) * (yj - yi)) {
      return 0;
    }
    if ((yi > y) != (yj > y)) {
      if (x < xi && x < xj) {
        contains = -contains;
      } else if ((x < xi || x < xj) &&
          x < (xj - xi) * (y - yi) / (yj - yi) + xi) {
        contains = -contains;
      }
    }
    xj = xi;
    yj = yi;
  }
  return contains;
}
