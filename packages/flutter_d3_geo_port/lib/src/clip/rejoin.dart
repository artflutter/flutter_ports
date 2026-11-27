// Ported from d3-geo v3.1.1 src/clip/rejoin.js (ISC, Mike Bostock).

/// Port of `src/clip/rejoin.js` of d3-geo 3.1.1: generalized polygon clipping
/// intersection rejoining (Greiner-Hormann / Weiler-Atherton style).
library;

import 'package:flutter_d3_geo_port/src/clip/buffer.dart';
import 'package:flutter_d3_geo_port/src/geojson.dart';
import 'package:flutter_d3_geo_port/src/math.dart';
import 'package:flutter_d3_geo_port/src/stream.dart';

/// Boundary interpolation callback used by polygon clippers when rejoining cut
/// segments along the clip boundary.
typedef GeoClipInterpolate = void Function(
  GeoPosition? from,
  GeoPosition? to,
  double direction,
  GeoStream stream,
);

/// An intersection node along the subject or clip boundary ring.
final class GeoClipIntersection(
  /// Intersection point coordinates.
  final GeoClipPoint x,

  /// Subject segment vertices (non-null for subject ring nodes).
  final List<GeoClipPoint>? z,

  /// Paired intersection in the opposite ring (clip ↔ subject).
  var GeoClipIntersection? o,

  /// Whether this intersection is an entry point.
  var bool e,
) {
  /// Creates a [GeoClipIntersection].
  this;

  /// Whether this intersection has been visited.
  bool v = false;

  /// Next node in the circular linked list.
  GeoClipIntersection? n;

  /// Previous node in the circular linked list.
  GeoClipIntersection? p;
}

@pragma('vm:prefer-inline')
bool _clipPointEqual(GeoClipPoint a, GeoClipPoint b) =>
    (a.x - b.x).abs() < geoEpsilon && (a.y - b.y).abs() < geoEpsilon;

void _link(List<GeoClipIntersection> array) {
  final n = array.length;
  if (n == 0) return;
  var a = array[0];
  for (var i = 1; i < n; ++i) {
    final b = array[i];
    a.n = b;
    b.p = a;
    a = b;
  }
  final first = array[0];
  a.n = first;
  first.p = a;
}

/// `clip/rejoin.js:16` default export: rejoins clipped polygon [segments]
/// along the clip boundary using [compareIntersection] and [interpolate],
/// streaming closed rings into [stream].
void geoClipRejoin(
  List<List<GeoClipPoint>> segments,
  int Function(GeoClipIntersection a, GeoClipIntersection b)
  compareIntersection,
  bool startInside,
  GeoClipInterpolate interpolate,
  GeoStream stream,
) {
  final subject = <GeoClipIntersection>[];
  final clip = <GeoClipIntersection>[];

  for (var s = 0, sn = segments.length; s < sn; ++s) {
    final segment = segments[s];
    final n = segment.length - 1;
    if (n <= 0) continue;
    final p0 = segment[0];
    final p1 = segment[n];

    if (_clipPointEqual(p0, p1)) {
      if (p0.m == 0 && p1.m == 0) {
        stream.lineStart();
        for (var i = 0; i < n; ++i) {
          final pt = segment[i];
          stream.point(pt.x, pt.y);
        }
        stream.lineEnd();
        continue;
      }
      // Handle degenerate cases by moving the endpoint slightly.
      p1.x += 2 * geoEpsilon;
    }

    final x0 = GeoClipIntersection(p0, segment, null, true);
    final c0 = GeoClipIntersection(p0, null, x0, false);
    x0.o = c0;
    subject.add(x0);
    clip.add(c0);

    final x1 = GeoClipIntersection(p1, segment, null, false);
    final c1 = GeoClipIntersection(p1, null, x1, true);
    x1.o = c1;
    subject.add(x1);
    clip.add(c1);
  }

  if (subject.isEmpty) return;

  clip.sort(compareIntersection);
  _link(subject);
  _link(clip);

  var inside = startInside;
  for (var i = 0, n = clip.length; i < n; ++i) {
    inside = !inside;
    clip[i].e = inside;
  }

  final start = subject[0];

  while (true) {
    var current = start;
    var isSubject = true;
    while (current.v) {
      current = current.n!;
      if (identical(current, start)) return;
    }
    var points = current.z;
    stream.lineStart();
    do {
      current.v = true;
      current.o!.v = true;
      if (current.e) {
        if (isSubject) {
          final pts = points!;
          for (var i = 0, n = pts.length; i < n; ++i) {
            final pt = pts[i];
            stream.point(pt.x, pt.y);
          }
        } else {
          final from = current.x;
          final to = current.n!.x;
          interpolate((from.x, from.y), (to.x, to.y), 1, stream);
        }
        current = current.n!;
      } else {
        if (isSubject) {
          final pts = current.p!.z!;
          for (var i = pts.length - 1; i >= 0; --i) {
            final pt = pts[i];
            stream.point(pt.x, pt.y);
          }
        } else {
          final from = current.x;
          final to = current.p!.x;
          interpolate((from.x, from.y), (to.x, to.y), -1, stream);
        }
        current = current.p!;
      }
      current = current.o!;
      points = current.z;
      isSubject = !isSubject;
    } while (!current.v);
    stream.lineEnd();
  }
}
