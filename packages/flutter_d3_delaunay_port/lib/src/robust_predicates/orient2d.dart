// Ported from robust-predicates v3.0.3 src/orient2d.js (Unlicense, Vladimir Agafonkin).

/// Port of `src/orient2d.js` of robust-predicates 3.0.3: Shewchuk adaptive
/// exact 2D orientation predicate [orient2d] and fast non-robust
/// [orient2dfast].
///
/// Build-time macros from `compile.js` are expanded inline per D3 ADR 0001
/// item 16.
library;

import 'dart:typed_data';

import 'package:flutter_d3_delaunay_port/src/robust_predicates/util.dart';

const double _ccwErrBoundA = (3 + 16 * predicatesEpsilon) * predicatesEpsilon;
const double _ccwErrBoundB = (2 + 12 * predicatesEpsilon) * predicatesEpsilon;
const double _ccwErrBoundC =
    (9 + 64 * predicatesEpsilon) * predicatesEpsilon * predicatesEpsilon;

final Float64List _b = predicatesVec(4);
final Float64List _c1 = predicatesVec(8);
final Float64List _c2 = predicatesVec(12);
final Float64List _d = predicatesVec(16);
final Float64List _u = predicatesVec(4);

// DIVERGES(d3-delaunay): adapt-delaunay-fast-forms, cold adaptive path split.
@pragma('vm:never-inline')
@pragma('wasm:never-inline')
double _orient2dAdapt(
  double ax,
  double ay,
  double bx,
  double by,
  double cx,
  double cy,
  double detsum,
) {
  double acxtail;
  double acytail;
  double bcxtail;
  double bcytail;
  double bvirt;
  double c;
  double ahi;
  double alo;
  double bhi;
  double blo;
  double iVar;
  double jVar;
  double z0;
  double s1;
  double s0;
  double t1;
  double t0;
  double u3;

  final b = _b;
  final u = _u;
  final acx = ax - cx;
  final bcx = bx - cx;
  final acy = ay - cy;
  final bcy = by - cy;

  // Cross_Product(acx, bcx, acy, bcy, b)
  s1 = acx * bcy;
  c = predicatesSplitter * acx;
  ahi = c - (c - acx);
  alo = acx - ahi;
  c = predicatesSplitter * bcy;
  bhi = c - (c - bcy);
  blo = bcy - bhi;
  s0 = alo * blo - (s1 - ahi * bhi - alo * bhi - ahi * blo);

  t1 = acy * bcx;
  c = predicatesSplitter * acy;
  ahi = c - (c - acy);
  alo = acy - ahi;
  c = predicatesSplitter * bcx;
  bhi = c - (c - bcx);
  blo = bcx - bhi;
  t0 = alo * blo - (t1 - ahi * bhi - alo * bhi - ahi * blo);

  iVar = s0 - t0;
  bvirt = s0 - iVar;
  final b0 = s0 - (iVar + bvirt) + (bvirt - t0);
  jVar = s1 + iVar;
  bvirt = jVar - s1;
  z0 = s1 - (jVar - bvirt) + (iVar - bvirt);
  iVar = z0 - t1;
  bvirt = z0 - iVar;
  final b1 = z0 - (iVar + bvirt) + (bvirt - t1);
  u3 = jVar + iVar;
  bvirt = u3 - jVar;
  final b2 = jVar - (u3 - bvirt) + (iVar - bvirt);
  b[0] = b0;
  b[1] = b1;
  b[2] = b2;
  b[3] = u3;

  var det = b0 + b1 + b2 + u3;
  var errbound = _ccwErrBoundB * detsum;
  if (det >= errbound || -det >= errbound) {
    return det;
  }

  // Two_Diff_Tail(ax, cx, acx, acxtail)
  bvirt = ax - acx;
  acxtail = ax - (acx + bvirt) + (bvirt - cx);
  // Two_Diff_Tail(bx, cx, bcx, bcxtail)
  bvirt = bx - bcx;
  bcxtail = bx - (bcx + bvirt) + (bvirt - cx);
  // Two_Diff_Tail(ay, cy, acy, acytail)
  bvirt = ay - acy;
  acytail = ay - (acy + bvirt) + (bvirt - cy);
  // Two_Diff_Tail(by, cy, bcy, bcytail)
  bvirt = by - bcy;
  bcytail = by - (bcy + bvirt) + (bvirt - cy);

  if (acxtail == 0 && acytail == 0 && bcxtail == 0 && bcytail == 0) {
    return det;
  }

  errbound = _ccwErrBoundC * detsum + predicatesResultErrBound * det.abs();
  det += (acx * bcytail + bcy * acxtail) - (acy * bcxtail + bcx * acytail);
  if (det >= errbound || -det >= errbound) return det;

  // Cross_Product(acxtail, bcx, acytail, bcy, u)
  s1 = acxtail * bcy;
  c = predicatesSplitter * acxtail;
  ahi = c - (c - acxtail);
  alo = acxtail - ahi;
  c = predicatesSplitter * bcy;
  bhi = c - (c - bcy);
  blo = bcy - bhi;
  s0 = alo * blo - (s1 - ahi * bhi - alo * bhi - ahi * blo);

  t1 = acytail * bcx;
  c = predicatesSplitter * acytail;
  ahi = c - (c - acytail);
  alo = acytail - ahi;
  c = predicatesSplitter * bcx;
  bhi = c - (c - bcx);
  blo = bcx - bhi;
  t0 = alo * blo - (t1 - ahi * bhi - alo * bhi - ahi * blo);

  iVar = s0 - t0;
  bvirt = s0 - iVar;
  u[0] = s0 - (iVar + bvirt) + (bvirt - t0);
  jVar = s1 + iVar;
  bvirt = jVar - s1;
  z0 = s1 - (jVar - bvirt) + (iVar - bvirt);
  iVar = z0 - t1;
  bvirt = z0 - iVar;
  u[1] = z0 - (iVar + bvirt) + (bvirt - t1);
  u3 = jVar + iVar;
  bvirt = u3 - jVar;
  u[2] = jVar - (u3 - bvirt) + (iVar - bvirt);
  u[3] = u3;
  final c1Len = predicatesSum(4, b, 4, u, _c1);

  // Cross_Product(acx, bcxtail, acy, bcytail, u)
  s1 = acx * bcytail;
  c = predicatesSplitter * acx;
  ahi = c - (c - acx);
  alo = acx - ahi;
  c = predicatesSplitter * bcytail;
  bhi = c - (c - bcytail);
  blo = bcytail - bhi;
  s0 = alo * blo - (s1 - ahi * bhi - alo * bhi - ahi * blo);

  t1 = acy * bcxtail;
  c = predicatesSplitter * acy;
  ahi = c - (c - acy);
  alo = acy - ahi;
  c = predicatesSplitter * bcxtail;
  bhi = c - (c - bcxtail);
  blo = bcxtail - bhi;
  t0 = alo * blo - (t1 - ahi * bhi - alo * bhi - ahi * blo);

  iVar = s0 - t0;
  bvirt = s0 - iVar;
  u[0] = s0 - (iVar + bvirt) + (bvirt - t0);
  jVar = s1 + iVar;
  bvirt = jVar - s1;
  z0 = s1 - (jVar - bvirt) + (iVar - bvirt);
  iVar = z0 - t1;
  bvirt = z0 - iVar;
  u[1] = z0 - (iVar + bvirt) + (bvirt - t1);
  u3 = jVar + iVar;
  bvirt = u3 - jVar;
  u[2] = jVar - (u3 - bvirt) + (iVar - bvirt);
  u[3] = u3;
  final c2Len = predicatesSum(c1Len, _c1, 4, u, _c2);

  // Cross_Product(acxtail, bcxtail, acytail, bcytail, u)
  s1 = acxtail * bcytail;
  c = predicatesSplitter * acxtail;
  ahi = c - (c - acxtail);
  alo = acxtail - ahi;
  c = predicatesSplitter * bcytail;
  bhi = c - (c - bcytail);
  blo = bcytail - bhi;
  s0 = alo * blo - (s1 - ahi * bhi - alo * bhi - ahi * blo);

  t1 = acytail * bcxtail;
  c = predicatesSplitter * acytail;
  ahi = c - (c - acytail);
  alo = acytail - ahi;
  c = predicatesSplitter * bcxtail;
  bhi = c - (c - bcxtail);
  blo = bcxtail - bhi;
  t0 = alo * blo - (t1 - ahi * bhi - alo * bhi - ahi * blo);

  iVar = s0 - t0;
  bvirt = s0 - iVar;
  u[0] = s0 - (iVar + bvirt) + (bvirt - t0);
  jVar = s1 + iVar;
  bvirt = jVar - s1;
  z0 = s1 - (jVar - bvirt) + (iVar - bvirt);
  iVar = z0 - t1;
  bvirt = z0 - iVar;
  u[1] = z0 - (iVar + bvirt) + (bvirt - t1);
  u3 = jVar + iVar;
  bvirt = u3 - jVar;
  u[2] = jVar - (u3 - bvirt) + (iVar - bvirt);
  u[3] = u3;
  final dLen = predicatesSum(c2Len, _c2, 4, u, _d);

  return _d[dLen - 1];
}

/// `orient2d.js:55` `orient2d`: returns a positive value if `(ax, ay)`,
/// `(bx, by)`, `(cx, cy)` occur in counterclockwise order (in y-down screen
/// coordinates, or clockwise in y-up coordinates — matching `robust-predicates`
/// sign convention), a negative value for the opposite orientation, and `0` if
/// collinear.
// DIVERGES(d3-delaunay): adapt-delaunay-typed-api, typed double parameters.
@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:tryInline')
double orient2d(
  double ax,
  double ay,
  double bx,
  double by,
  double cx,
  double cy,
) {
  final detleft = (ay - cy) * (bx - cx);
  final detright = (ax - cx) * (by - cy);
  final det = detleft - detright;

  final detsum = (detleft + detright).abs();
  if (det.abs() >= _ccwErrBoundA * detsum) return det;

  return -_orient2dAdapt(ax, ay, bx, by, cx, cy, detsum);
}

/// `orient2d.js:66` `orient2dfast`: fast non-robust 2D orientation test.
@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:tryInline')
double orient2dfast(
  double ax,
  double ay,
  double bx,
  double by,
  double cx,
  double cy,
) => (ay - cy) * (bx - cx) - (ax - cx) * (by - cy);
