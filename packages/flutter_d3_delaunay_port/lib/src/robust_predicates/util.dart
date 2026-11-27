// Ported from robust-predicates v3.0.3 src/util.js (Unlicense, Vladimir Agafonkin).

/// Port of `src/util.js` of robust-predicates 3.0.3: Shewchuk adaptive
/// floating-point expansion arithmetic helpers.
///
/// Build-time macros from `compile.js` are expanded inline per D3 ADR 0001
/// item 16.
library;

import 'dart:typed_data';

/// IEEE-754 binary64 machine epsilon divided by 2 (`2^-53`).
const double predicatesEpsilon = 1.1102230246251565e-16;

/// Veltkamp–Dekker splitting constant (`2^27 + 1`).
const double predicatesSplitter = 134217729;

/// Error bound constant for adaptive expansion estimates.
const double predicatesResultErrBound =
    (3 + 8 * predicatesEpsilon) * predicatesEpsilon;

/// `util.js:6` `sum`: Shewchuk `fast_expansion_sum_zeroelim` routine.
// DIVERGES(d3-delaunay): adapt-delaunay-typed-api, expanded macros & bounds.
int predicatesSum(
  int elen,
  Float64List e,
  int flen,
  Float64List f,
  Float64List h,
) {
  double q;
  double qnew;
  double hh;
  double bvirt;
  var enow = e[0];
  var fnow = f[0];
  var eindex = 0;
  var findex = 0;
  if ((fnow > enow) == (fnow > -enow)) {
    q = enow;
    if (++eindex < elen) enow = e[eindex];
  } else {
    q = fnow;
    if (++findex < flen) fnow = f[findex];
  }
  var hindex = 0;
  if (eindex < elen && findex < flen) {
    if ((fnow > enow) == (fnow > -enow)) {
      // Fast_Two_Sum(enow, q, qnew, hh)
      qnew = enow + q;
      hh = q - (qnew - enow);
      if (++eindex < elen) enow = e[eindex];
    } else {
      // Fast_Two_Sum(fnow, q, qnew, hh)
      qnew = fnow + q;
      hh = q - (qnew - fnow);
      if (++findex < flen) fnow = f[findex];
    }
    q = qnew;
    if (hh != 0) {
      h[hindex++] = hh;
    }
    while (eindex < elen && findex < flen) {
      if ((fnow > enow) == (fnow > -enow)) {
        // Two_Sum(q, enow, qnew, hh)
        qnew = q + enow;
        bvirt = qnew - q;
        hh = q - (qnew - bvirt) + (enow - bvirt);
        if (++eindex < elen) enow = e[eindex];
      } else {
        // Two_Sum(q, fnow, qnew, hh)
        qnew = q + fnow;
        bvirt = qnew - q;
        hh = q - (qnew - bvirt) + (fnow - bvirt);
        if (++findex < flen) fnow = f[findex];
      }
      q = qnew;
      if (hh != 0) {
        h[hindex++] = hh;
      }
    }
  }
  while (eindex < elen) {
    // Two_Sum(q, enow, qnew, hh)
    qnew = q + enow;
    bvirt = qnew - q;
    hh = q - (qnew - bvirt) + (enow - bvirt);
    if (++eindex < elen) enow = e[eindex];
    q = qnew;
    if (hh != 0) {
      h[hindex++] = hh;
    }
  }
  while (findex < flen) {
    // Two_Sum(q, fnow, qnew, hh)
    qnew = q + fnow;
    bvirt = qnew - q;
    hh = q - (qnew - bvirt) + (fnow - bvirt);
    if (++findex < flen) fnow = f[findex];
    q = qnew;
    if (hh != 0) {
      h[hindex++] = hh;
    }
  }
  if (q != 0 || hindex == 0) {
    h[hindex++] = q;
  }
  return hindex;
}

/// `util.js:68` `sum_three`: sums three expansions into [out] via [tmp].
int predicatesSumThree(
  int alen,
  Float64List a,
  int blen,
  Float64List b,
  int clen,
  Float64List c,
  Float64List tmp,
  Float64List out,
) => predicatesSum(predicatesSum(alen, a, blen, b, tmp), tmp, clen, c, out);

/// `util.js:73` `scale`: Shewchuk `scale_expansion_zeroelim` routine.
int predicatesScale(int elen, Float64List e, double b, Float64List h) {
  double q;
  double sumVal;
  double hh;
  double product1;
  double product0;
  double bvirt;
  double c;
  double ahi;
  double alo;

  // Split(b, bhi, blo)
  c = predicatesSplitter * b;
  final bhi = c - (c - b);
  final blo = b - bhi;

  var enow = e[0];
  // Two_Product_Presplit(enow, b, bhi, blo, q, hh)
  q = enow * b;
  c = predicatesSplitter * enow;
  ahi = c - (c - enow);
  alo = enow - ahi;
  hh = alo * blo - (q - ahi * bhi - alo * bhi - ahi * blo);

  var hindex = 0;
  if (hh != 0) {
    h[hindex++] = hh;
  }
  for (var i = 1; i < elen; i++) {
    enow = e[i];
    // Two_Product_Presplit(enow, b, bhi, blo, product1, product0)
    product1 = enow * b;
    c = predicatesSplitter * enow;
    ahi = c - (c - enow);
    alo = enow - ahi;
    product0 = alo * blo - (product1 - ahi * bhi - alo * bhi - ahi * blo);

    // Two_Sum(q, product0, sumVal, hh)
    sumVal = q + product0;
    bvirt = sumVal - q;
    hh = q - (sumVal - bvirt) + (product0 - bvirt);
    if (hh != 0) {
      h[hindex++] = hh;
    }

    // Fast_Two_Sum(product1, sumVal, q, hh)
    q = product1 + sumVal;
    hh = sumVal - (q - product1);
    if (hh != 0) {
      h[hindex++] = hh;
    }
  }
  if (q != 0 || hindex == 0) {
    h[hindex++] = q;
  }
  return hindex;
}

/// `util.js:102` `negate`: negates [elen] components of [e] in place.
int predicatesNegate(int elen, Float64List e) {
  for (var i = 0; i < elen; i++) {
    e[i] = -e[i];
  }
  return elen;
}

/// `util.js:107` `estimate`: sums the [elen] components of expansion [e].
double predicatesEstimate(int elen, Float64List e) {
  var q = e[0];
  for (var i = 1; i < elen; i++) {
    q += e[i];
  }
  return q;
}

/// `util.js:113` `vec`: allocates an [n]-element [Float64List].
Float64List predicatesVec(int n) => Float64List(n);
