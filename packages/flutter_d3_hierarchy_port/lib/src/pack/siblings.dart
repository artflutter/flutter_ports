// Ported from d3-hierarchy v3.1.2 src/pack/siblings.js (ISC, Mike Bostock).

/// Port of `src/pack/siblings.js` of d3-hierarchy 3.1.2: [packSiblings] and
/// [packSiblingsRandom].
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_hierarchy_port/src/lcg.dart';
import 'package:flutter_d3_hierarchy_port/src/pack/enclose.dart';

// DIVERGES(d3-hierarchy): adapt-hierarchy-fast-forms, unboxed `Float64List`
// coordinates and `Int32List` doubly-linked front-chain eliminating per-circle
// `_ChainNode` allocations and interface dispatch in inner loops.

@pragma('vm:prefer-inline')
void _placeIdx(
  Float64List xs,
  Float64List ys,
  Float64List rs,
  int b,
  int a,
  int c,
) {
  final ax = xs[a];
  final ay = ys[a];
  final bx = xs[b];
  final by = ys[b];
  final cr = rs[c];
  final dx = bx - ax;
  final dy = by - ay;
  final d2 = dx * dx + dy * dy;
  if (d2 != 0) {
    var a2 = rs[a] + cr;
    a2 *= a2;
    var b2 = rs[b] + cr;
    b2 *= b2;
    if (a2 > b2) {
      final x = (d2 + b2 - a2) / (2 * d2);
      final rad = b2 / d2 - x * x;
      final y = rad > 0 ? math.sqrt(rad) : 0.0;
      xs[c] = bx - x * dx - y * dy;
      ys[c] = by - x * dy + y * dx;
    } else {
      final x = (d2 + a2 - b2) / (2 * d2);
      final rad = a2 / d2 - x * x;
      final y = rad > 0 ? math.sqrt(rad) : 0.0;
      xs[c] = ax + x * dx - y * dy;
      ys[c] = ay + x * dy + y * dx;
    }
  } else {
    xs[c] = ax + cr;
    ys[c] = ay;
  }
}

/// Packs [circles] in-place using Wang et al.'s front-chain algorithm with
/// [random] for enclosing circle calculation, returning the enclosing radius.
double packSiblingsRandom<C extends PackCircle>(
  List<C> circles,
  double Function() random,
) {
  final n = circles.length;
  if (n == 0) return 0;

  // Place the first circle.
  final c0 = circles[0]
    ..x = 0
    ..y = 0;
  if (n == 1) return c0.r;

  // Place the second circle.
  final c1 = circles[1];
  c0.x = -c1.r;
  c1
    ..x = c0.r
    ..y = 0;
  if (n == 2) return c0.r + c1.r;

  final xs = Float64List(n);
  final ys = Float64List(n);
  final rs = Float64List(n);
  for (var i = 0; i < n; ++i) {
    rs[i] = circles[i].r;
  }
  xs[0] = -rs[1];
  xs[1] = rs[0];

  // Place the third circle.
  _placeIdx(xs, ys, rs, 1, 0, 2);

  // Initialize the flat Int32List front-chain using indices 0, 1, 2.
  final next = Int32List(n);
  final prev = Int32List(n);
  next[0] = 1;
  prev[2] = 1;
  next[1] = 2;
  prev[0] = 2;
  next[2] = 0;
  prev[1] = 0;

  var a = 0;
  var b = 1;

  // Attempt to place each remaining circle...
  pack:
  for (var i = 3; i < n; ++i) {
    _placeIdx(xs, ys, rs, a, b, i);
    final cx = xs[i];
    final cy = ys[i];
    final cr = rs[i];

    // Find the closest intersecting circle on the front-chain, if any.
    var j = next[b];
    var k = prev[a];
    var sj = rs[b];
    var sk = rs[a];
    do {
      if (sj <= sk) {
        final dr = rs[j] + cr - 1e-6;
        if (dr > 0) {
          final dx = cx - xs[j];
          final dy = cy - ys[j];
          if (dr * dr > dx * dx + dy * dy) {
            b = j;
            next[a] = b;
            prev[b] = a;
            --i;
            continue pack;
          }
        }
        sj += rs[j];
        j = next[j];
      } else {
        final dr = rs[k] + cr - 1e-6;
        if (dr > 0) {
          final dx = cx - xs[k];
          final dy = cy - ys[k];
          if (dr * dr > dx * dx + dy * dy) {
            a = k;
            next[a] = b;
            prev[b] = a;
            --i;
            continue pack;
          }
        }
        sk += rs[k];
        k = prev[k];
      }
    } while (j != next[k]);

    // Success! Insert circle i between a and b.
    prev[i] = a;
    next[i] = b;
    next[a] = i;
    prev[b] = i;
    b = i;

    // Compute the new closest circle pair to the centroid.
    var aa = _scoreIdx(xs, ys, rs, a, next[a]);
    var c = i;
    while ((c = next[c]) != b) {
      final ca = _scoreIdx(xs, ys, rs, c, next[c]);
      if (ca < aa) {
        a = c;
        aa = ca;
      }
    }
    b = next[a];
  }

  // Extract front-chain circles into compact Float64Lists and enclose.
  var chainLen = 1;
  var c = b;
  while ((c = next[c]) != b) {
    ++chainLen;
  }
  final chainX = Float64List(chainLen);
  final chainY = Float64List(chainLen);
  final chainR = Float64List(chainLen);
  chainX[0] = xs[b];
  chainY[0] = ys[b];
  chainR[0] = rs[b];
  c = b;
  var idx = 1;
  while ((c = next[c]) != b) {
    chainX[idx] = xs[c];
    chainY[idx] = ys[c];
    chainR[idx] = rs[c];
    ++idx;
  }
  final (ex, ey, er) = packEncloseFloat64(
    chainX,
    chainY,
    chainR,
    chainLen,
    random,
  );

  // Translate the circles to put the enclosing circle around the origin.
  for (var i = 0; i < n; ++i) {
    circles[i]
      ..x = xs[i] - ex
      ..y = ys[i] - ey;
  }

  return er;
}

@pragma('vm:prefer-inline')
double _scoreIdx(Float64List xs, Float64List ys, Float64List rs, int a, int b) {
  final ar = rs[a];
  final br = rs[b];
  final ab = ar + br;
  final dx = (xs[a] * br + xs[b] * ar) / ab;
  final dy = (ys[a] * br + ys[b] * ar) / ab;
  return dx * dx + dy * dy;
}

/// Packs [circles] in-place around the origin with a deterministic LCG and
/// returns [circles].
List<C> packSiblings<C extends PackCircle>(List<C> circles) {
  packSiblingsRandom<C>(circles, hierarchyLcg());
  return circles;
}
