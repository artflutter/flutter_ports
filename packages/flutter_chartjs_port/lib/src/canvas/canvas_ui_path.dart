// Original code, not ported from Chart.js: the dart:ui canvas paths.

/// The current transform and the path builder of the `dart:ui` canvas
/// context (Chart.js ADR 0013, porting-flow.md 2.2).
///
/// Canvas 2D has path semantics that `dart:ui` lacks. This library keeps
/// those that change behavior:
/// - The transform applies when a point is added: [UiPathBuilder] writes
///   each point in the space of the canvas bitmap, through the transform
///   that is current at that call.
/// - A path method with a non-finite argument does nothing. With a
///   transform that is not invertible, a path method does nothing (as
///   Chromium does).
/// - `lineTo`, `quadraticCurveTo`, `bezierCurveTo` and `arcTo` on a path
///   with no subpath start a subpath at their first point. `dart:ui` would
///   start it at the origin.
/// - `arc` connects to the current point with a line (`ui.Path.arcTo` with
///   `forceMoveTo: false`). A sweep of 2π or more draws a full circle.
///   `ui.Path.arcTo` draws nothing for a sweep of 2π, thus the builder adds
///   two half arcs.
/// - `arc` with a negative radius throws a [RangeError] (the DOM
///   `IndexSizeError`).
/// - `roundRect` follows [roundRectGeometry]. Under an axis-aligned
///   transform it adds one `ui.Path.addRRect`, which the context fills with
///   `drawRRect` and clips with `clipRRect`. This is a performance addition
///   (porting-flow.md §1.1), not a Canvas 2D rule.
///
/// The arc and ellipse curves are `dart:ui` arcs when the transform keeps
/// them circular or axis-aligned, else cubic Bézier curves. The layer has no
/// Chromium-exact arc math (Chart.js ADR 0034).
///
/// [UiPathBuilder] keeps the first [deferredPathCommands] commands of a path
/// and builds its `ui.Path` only when a reader needs it
/// (canvas-cuts-plan.md §7, N3). The build makes the `ui.Path` calls of an
/// eager build, in the same order and with the same values. Thus a path that
/// a fast path of the context draws (a rectangle, a rounded rectangle, a
/// ring, a circle) makes no `ui.Path` call. The current point and the start
/// of a subpath on an arc keep the arc, and get their coordinates at the
/// first read.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:meta/meta.dart';

const double _tau = 2 * math.pi;

/// The current transformation matrix of a canvas state: the DOM matrix
/// `[a c e; b d f; 0 0 1]`.
///
/// The derived flags tell the fast paths of the context when they apply.
final class UiTransform {
  /// The identity transform.
  UiTransform();

  /// The matrix component `a` (x scale).
  double a = 1;

  /// The matrix component `b` (y skew).
  double b = 0;

  /// The matrix component `c` (x skew).
  double c = 0;

  /// The matrix component `d` (y scale).
  double d = 1;

  /// The matrix component `e` (x translation).
  double e = 0;

  /// The matrix component `f` (y translation).
  double f = 0;

  /// `b == 0 && c == 0`: the transform maps rectangles to rectangles.
  bool isAxisAligned = true;

  /// The transform is a translation, a rotation, a reflection and one
  /// uniform scale: circles stay circles and line widths scale by
  /// [scaleFactor].
  bool isSimilarity = true;

  /// The uniform scale of a [isSimilarity] transform.
  double scaleFactor = 1;

  /// The rotation of a [isSimilarity] transform, in radians.
  double angle = 0;

  /// The determinant is negative: the transform mirrors.
  bool isReflected = false;

  /// The determinant is finite and not 0.
  bool isInvertible = true;

  /// `a == 1, b == 0, c == 0, d == 1`: the transform translates only.
  bool isTranslation = true;

  /// Copies the matrix and the flags of [other].
  void copyFrom(UiTransform other) {
    a = other.a;
    b = other.b;
    c = other.c;
    d = other.d;
    e = other.e;
    f = other.f;
    isAxisAligned = other.isAxisAligned;
    isSimilarity = other.isSimilarity;
    scaleFactor = other.scaleFactor;
    angle = other.angle;
    isReflected = other.isReflected;
    isInvertible = other.isInvertible;
    isTranslation = other.isTranslation;
  }

  /// `setTransform(a, b, c, d, e, f)`.
  void setValues(
    double a,
    double b,
    double c,
    double d,
    double e,
    double f,
  ) {
    this.a = a;
    this.b = b;
    this.c = c;
    this.d = d;
    this.e = e;
    this.f = f;
    _update();
  }

  /// `resetTransform()`.
  void reset() => setValues(1, 0, 0, 1, 0, 0);

  /// `translate(x, y)`: this matrix times the translation.
  void translate(double x, double y) {
    e += a * x + c * y;
    f += b * x + d * y;
  }

  /// `scale(x, y)`: this matrix times the scale.
  void scale(double x, double y) {
    a *= x;
    b *= x;
    c *= y;
    d *= y;
    _update();
  }

  /// `rotate(angle)`: this matrix times the rotation.
  void rotate(double radians) {
    final cos = math.cos(radians);
    final sin = math.sin(radians);
    final na = a * cos + c * sin;
    final nb = b * cos + d * sin;
    final nc = c * cos - a * sin;
    final nd = d * cos - b * sin;
    a = na;
    b = nb;
    c = nc;
    d = nd;
    _update();
  }

  /// `transform(a, b, c, d, e, f)`: this matrix times the given one.
  void multiply(
    double ma,
    double mb,
    double mc,
    double md,
    double me,
    double mf,
  ) {
    final na = a * ma + c * mb;
    final nb = b * ma + d * mb;
    final nc = a * mc + c * md;
    final nd = b * mc + d * md;
    final ne = a * me + c * mf + e;
    final nf = b * me + d * mf + f;
    a = na;
    b = nb;
    c = nc;
    d = nd;
    e = ne;
    f = nf;
    _update();
  }

  /// The x of the point (x, y) after the transform.
  double mapX(double x, double y) => a * x + c * y + e;

  /// The y of the point (x, y) after the transform.
  double mapY(double x, double y) => b * x + d * y + f;

  /// The determinant of the linear part.
  double get determinant => a * d - b * c;

  /// Writes the matrix as a column-major 4 x 4 matrix into [m] (16 values).
  Float64List writeMatrix4(Float64List m) {
    m
      ..fillRange(0, 16, 0)
      ..[0] = a
      ..[1] = b
      ..[4] = c
      ..[5] = d
      ..[10] = 1
      ..[12] = e
      ..[13] = f
      ..[15] = 1;
    return m;
  }

  /// Writes the inverse matrix as a column-major 4 x 4 matrix into [m]. The
  /// transform must be [isInvertible].
  Float64List writeInverseMatrix4(Float64List m) {
    final det = determinant;
    m
      ..fillRange(0, 16, 0)
      ..[0] = d / det
      ..[1] = -b / det
      ..[4] = -c / det
      ..[5] = a / det
      ..[10] = 1
      ..[12] = (c * f - d * e) / det
      ..[13] = (b * e - a * f) / det
      ..[15] = 1;
    return m;
  }

  void _update() {
    isAxisAligned = b == 0 && c == 0;
    isTranslation = isAxisAligned && a == 1 && d == 1;
    final det = determinant;
    isInvertible = det != 0 && det.isFinite;
    isReflected = det < 0;
    final col1 = a * a + b * b;
    final col2 = c * c + d * d;
    final tolerance = 1e-9 * (col1 + col2);
    isSimilarity =
        isInvertible &&
        (col1 - col2).abs() <= tolerance &&
        (a * c + b * d).abs() <= tolerance;
    if (isSimilarity) {
      scaleFactor = math.sqrt(col1);
      angle = isAxisAligned && a > 0 ? 0 : math.atan2(b, a);
    }
  }
}

/// The sweep of `arc(x, y, r, startAngle, endAngle, counterclockwise)`, as
/// Chromium canonicalizes the end angle (`AdjustEndAngle`): a sweep of 2π
/// or more is a full circle, else the sweep goes the given way round.
// The DOM argument order.
// ignore: avoid_positional_boolean_parameters
double canvasArcSweep(double startAngle, double endAngle, bool ccw) {
  if (!ccw && endAngle - startAngle >= _tau) return _tau;
  if (ccw && startAngle - endAngle >= _tau) return -_tau;
  if (!ccw && startAngle > endAngle) {
    return _tau - (startAngle - endAngle) % _tau;
  }
  if (ccw && startAngle < endAngle) {
    return -(_tau - (endAngle - startAngle) % _tau);
  }
  return endAngle - startAngle;
}

/// The count of commands that [UiPathBuilder] keeps before it builds its
/// `ui.Path` (canvas-cuts-plan.md §7, N3). A longer path, for example the
/// polyline of a line chart, builds its `ui.Path` at the next command and
/// sends the later commands to it directly.
const int deferredPathCommands = 32;

// The codes of the deferred commands. The numbers of each command follow in
// UiPathBuilder._numbers, in bitmap space.
const int _moveCode = 0; // x, y
const int _lineCode = 1; // x, y
const int _quadCode = 2; // x1, y1, x2, y2
const int _cubicCode = 3; // x1, y1, x2, y2, x3, y3
const int _arcCode = 4; // cx, cy, rx, ry, start, sweep, forceMoveTo (1 or 0)
const int _rrectCode = 5; // the ui.RRect in UiPathBuilder._rrects
const int _closeCode = 6;

/// The most numbers of one deferred command: an arc.
const int _maxCommandNumbers = 7;

/// A point of [UiPathBuilder] in bitmap space: the current point or the
/// start of the subpath. A point on an arc keeps its arc, and gets its
/// coordinates at the first read of [x] or [y], with the expressions of an
/// eager build: most arcs never need them, and each takes a cosine and a
/// sine.
final class _PathPoint {
  double _x = 0;
  double _y = 0;
  bool _onArc = false;
  double _cx = 0;
  double _cy = 0;
  double _rx = 0;
  double _ry = 0;
  double _angle = 0;

  double get x {
    if (_onArc) _resolve();
    return _x;
  }

  double get y {
    if (_onArc) _resolve();
    return _y;
  }

  void _resolve() {
    _onArc = false;
    _x = _cx + _rx * math.cos(_angle);
    _y = _cy + _ry * math.sin(_angle);
  }

  void set(double x, double y) {
    _x = x;
    _y = y;
    _onArc = false;
  }

  /// The point at the parametric [angle] of the ellipse at ([cx], [cy]) with
  /// the radii [rx] and [ry].
  void setOnArc(double cx, double cy, double rx, double ry, double angle) {
    _cx = cx;
    _cy = cy;
    _rx = rx;
    _ry = ry;
    _angle = angle;
    _onArc = true;
  }

  void copyFrom(_PathPoint other) {
    _x = other._x;
    _y = other._y;
    _onArc = other._onArc;
    _cx = other._cx;
    _cy = other._cy;
    _rx = other._rx;
    _ry = other._ry;
    _angle = other._angle;
  }
}

/// A [CanvasPath] that builds a `ui.Path` in the space of the canvas bitmap,
/// through [transform].
///
/// The context keeps one builder for its current path. A [Path2D] replays
/// into a builder with the identity transform, which gives a path in user
/// space.
final class UiPathBuilder implements CanvasPath {
  /// A builder that maps its points through [transform].
  UiPathBuilder(this.transform);

  /// The transform that maps the added points. The context points it at
  /// the transform of its current state.
  UiTransform transform;

  final ui.Path _path = ui.Path();

  // The deferred commands (canvas-cuts-plan.md §7, N3): the code of each
  // command, the numbers of the commands in order, and the rounded rectangle
  // of each `addRRect`. [_path] gets them at the first read of [path], or
  // when the buffer is full.
  final Uint8List _codes = Uint8List(deferredPathCommands);
  final Float64List _numbers = Float64List(
    deferredPathCommands * _maxCommandNumbers,
  );
  final List<ui.RRect?> _rrects = List<ui.RRect?>.filled(
    deferredPathCommands,
    null,
  );
  int _deferred = 0;
  int _numberCount = 0;

  // Whether [_path] has the commands of the path so far: then a new command
  // goes to it directly. Only then does [_path] have commands.
  bool _built = false;

  /// The built path.
  ///
  /// The first read builds it from the deferred commands and the pending
  /// full circle (see [singleCircle]). The later commands of the path go to
  /// it directly.
  ui.Path get path {
    if (!_built) _build();
    return _path;
  }

  /// Whether the `ui.Path` of the path is built, for tests: a path that a
  /// fast path of the context draws never builds it.
  @visibleForTesting
  bool get debugBuilt => _built;

  void _build() {
    if (_circle) _deferCircle();
    _replay();
    _built = true;
  }

  /// Gives the deferred commands to [_path], in order.
  void _replay() {
    final p = _path;
    final n = _numbers;
    var j = 0;
    for (var i = 0; i < _deferred; i++) {
      switch (_codes[i]) {
        case _moveCode:
          p.moveTo(n[j], n[j + 1]);
          j += 2;
        case _lineCode:
          p.lineTo(n[j], n[j + 1]);
          j += 2;
        case _quadCode:
          p.quadraticBezierTo(n[j], n[j + 1], n[j + 2], n[j + 3]);
          j += 4;
        case _cubicCode:
          p.cubicTo(n[j], n[j + 1], n[j + 2], n[j + 3], n[j + 4], n[j + 5]);
          j += 6;
        case _arcCode:
          final cx = n[j];
          final cy = n[j + 1];
          final rx = n[j + 2];
          final ry = n[j + 3];
          // The oval of an eager build: Rect.fromCircle(center, r) gives the
          // same four values as fromLTRB(cx - r, cy - r, cx + r, cy + r).
          p.arcTo(
            ui.Rect.fromLTRB(cx - rx, cy - ry, cx + rx, cy + ry),
            n[j + 4],
            n[j + 5],
            n[j + 6] != 0,
          );
          j += 7;
        case _rrectCode:
          p.addRRect(_rrects[i]!);
        case _closeCode:
          p.close();
      }
    }
    _deferred = 0;
    _numberCount = 0;
  }

  /// Whether the next command goes to [_path] directly: the path is built,
  /// or the buffer is full, which builds it. A pending circle becomes
  /// deferred commands first.
  bool _direct() {
    if (_circle) _deferCircle();
    if (_built) return true;
    if (_deferred < deferredPathCommands) return false;
    _build();
    return true;
  }

  void _pathMoveTo(double x, double y) {
    if (_direct()) {
      _path.moveTo(x, y);
      return;
    }
    _codes[_deferred++] = _moveCode;
    _numbers
      ..[_numberCount++] = x
      ..[_numberCount++] = y;
  }

  void _pathLineTo(double x, double y) {
    if (_direct()) {
      _path.lineTo(x, y);
      return;
    }
    _codes[_deferred++] = _lineCode;
    _numbers
      ..[_numberCount++] = x
      ..[_numberCount++] = y;
  }

  void _pathQuadraticTo(double x1, double y1, double x2, double y2) {
    if (_direct()) {
      _path.quadraticBezierTo(x1, y1, x2, y2);
      return;
    }
    _codes[_deferred++] = _quadCode;
    _numbers
      ..[_numberCount++] = x1
      ..[_numberCount++] = y1
      ..[_numberCount++] = x2
      ..[_numberCount++] = y2;
  }

  void _pathCubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) {
    if (_direct()) {
      _path.cubicTo(x1, y1, x2, y2, x3, y3);
      return;
    }
    _codes[_deferred++] = _cubicCode;
    _numbers
      ..[_numberCount++] = x1
      ..[_numberCount++] = y1
      ..[_numberCount++] = x2
      ..[_numberCount++] = y2
      ..[_numberCount++] = x3
      ..[_numberCount++] = y3;
  }

  /// `ui.Path.arcTo` on the oval at ([cx], [cy]) with the radii [rx] and
  /// [ry].
  void _pathArcTo(
    double cx,
    double cy,
    double rx,
    double ry,
    double start,
    double sweep, {
    required bool forceMoveTo,
  }) {
    if (_direct()) {
      _path.arcTo(
        ui.Rect.fromLTRB(cx - rx, cy - ry, cx + rx, cy + ry),
        start,
        sweep,
        forceMoveTo,
      );
      return;
    }
    _codes[_deferred++] = _arcCode;
    _numbers
      ..[_numberCount++] = cx
      ..[_numberCount++] = cy
      ..[_numberCount++] = rx
      ..[_numberCount++] = ry
      ..[_numberCount++] = start
      ..[_numberCount++] = sweep
      ..[_numberCount++] = forceMoveTo ? 1 : 0;
  }

  void _pathAddRRect(ui.RRect rrect) {
    if (_direct()) {
      _path.addRRect(rrect);
      return;
    }
    _rrects[_deferred] = rrect;
    _codes[_deferred++] = _rrectCode;
  }

  void _pathClose() {
    if (_direct()) {
      _path.close();
      return;
    }
    _codes[_deferred++] = _closeCode;
  }

  // A full circle that `arc` added to an empty path, in bitmap space. It
  // stays out of [_path] until another command or a read of [path] needs
  // it, so that the context can draw it with `drawCircle`: a chart draws
  // most points as one full circle (`drawPointLegend`,
  // helpers.canvas.ts:200-207).
  bool _circle = false;
  bool _circleClosed = false;
  double _circleX = 0;
  double _circleY = 0;
  double _circleR = 0;
  double _circleStart = 0;
  double _circleSweep = 0;

  /// The path has a subpath: a current point exists.
  bool hasSubpath = false;

  // The current point and the start of the subpath.
  final _PathPoint _last = _PathPoint();
  final _PathPoint _start = _PathPoint();
  int _ops = 0;
  ui.Rect? _rect;
  ui.RRect? _rrect;
  // The first two commands, each a `ui.Rect` of a `rect` or a `ui.RRect` of
  // a `roundRect` under an axis-aligned transform, else null.
  Object? _shape0;
  Object? _shape1;

  /// The path has no command.
  bool get isEmpty => _ops == 0;

  /// The rectangle of the path, when the path is one `rect` that an
  /// axis-aligned transform mapped. The context fills and clips it with
  /// `drawRect` and `clipRect`.
  ui.Rect? get singleRect => _ops == 1 ? _rect : null;

  /// The rounded rectangle of the path in bitmap space, when the path is one
  /// `roundRect` that an axis-aligned transform mapped. The context fills
  /// and clips it with `drawRRect` and `clipRRect`.
  ui.RRect? get singleRRect => _ops == 1 ? _rrect : null;

  /// The two shapes of the path in bitmap space, in path order, when the
  /// path is exactly two `rect` or `roundRect` commands that an
  /// axis-aligned transform mapped. A rectangle has radii of 0. Each shape
  /// is one closed subpath. The context fills the ring of a bar border
  /// (`element.bar.js:188-192`) with `drawDRRect` when one shape is inside
  /// the other ([rrectContains]).
  ({ui.RRect first, ui.RRect second})? get shapePair {
    if (_ops != 2) return null;
    final first = _shape0;
    final second = _shape1;
    if (first == null || second == null) return null;
    return (first: _asRRect(first), second: _asRRect(second));
  }

  static ui.RRect _asRRect(Object shape) =>
      shape is ui.RRect ? shape : ui.RRect.fromRectAndCorners(shape as ui.Rect);

  /// Keeps [shape] as the shape of the current command, when it is one of
  /// the first two. Call it before `_ops++`.
  void _trackShape(Object? shape) {
    if (_ops == 0) {
      _shape0 = shape;
    } else if (_ops == 1) {
      _shape1 = shape;
    }
  }

  /// The circle of the path in bitmap space, when the path is one full
  /// circle that a similarity transform mapped, with or without a
  /// `closePath`. The context fills and strokes it with `drawCircle`.
  ({double x, double y, double radius})? get singleCircle =>
      _circle ? (x: _circleX, y: _circleY, radius: _circleR) : null;

  /// `beginPath()`: empties the path. The `ui.Path` resets only when it has
  /// commands.
  void reset() {
    if (_built) {
      _path.reset();
      _built = false;
    }
    _deferred = 0;
    _numberCount = 0;
    hasSubpath = false;
    _ops = 0;
    _rect = null;
    _rrect = null;
    _shape0 = null;
    _shape1 = null;
    _circle = false;
  }

  /// Adds the pending circle to the commands, as [_nativeArc] adds a full
  /// sweep. It is the first command of the path, so the buffer has room.
  void _deferCircle() {
    _circle = false;
    final half = _circleSweep / 2;
    _pathArcTo(
      _circleX,
      _circleY,
      _circleR,
      _circleR,
      _circleStart,
      half,
      forceMoveTo: true,
    );
    _pathArcTo(
      _circleX,
      _circleY,
      _circleR,
      _circleR,
      _circleStart + half,
      half,
      forceMoveTo: false,
    );
    if (_circleClosed) _pathClose();
  }

  void _moveToMapped(double px, double py) {
    _pathMoveTo(px, py);
    _start.set(px, py);
    _last.set(px, py);
    hasSubpath = true;
  }

  void _lineToMapped(double px, double py) {
    _pathLineTo(px, py);
    _last.set(px, py);
  }

  /// A line to the user point (x, y), or a move to it when the path has no
  /// subpath.
  void _lineOrMove(double x, double y) {
    final t = transform;
    final px = t.mapX(x, y);
    final py = t.mapY(x, y);
    if (hasSubpath) {
      _lineToMapped(px, py);
    } else {
      _moveToMapped(px, py);
    }
  }

  @override
  void closePath() {
    if (!hasSubpath) return;
    if (_circle && !_circleClosed) {
      _circleClosed = true;
    } else {
      _pathClose();
    }
    _last.copyFrom(_start);
    _ops++;
  }

  @override
  void moveTo(double x, double y) {
    if (!x.isFinite || !y.isFinite || !transform.isInvertible) return;
    final t = transform;
    _moveToMapped(t.mapX(x, y), t.mapY(x, y));
    _ops++;
  }

  @override
  void lineTo(double x, double y) {
    if (!x.isFinite || !y.isFinite || !transform.isInvertible) return;
    _lineOrMove(x, y);
    _ops++;
  }

  @override
  void quadraticCurveTo(double cpx, double cpy, double x, double y) {
    if (!cpx.isFinite ||
        !cpy.isFinite ||
        !x.isFinite ||
        !y.isFinite ||
        !transform.isInvertible) {
      return;
    }
    final t = transform;
    final pcx = t.mapX(cpx, cpy);
    final pcy = t.mapY(cpx, cpy);
    if (!hasSubpath) _moveToMapped(pcx, pcy);
    final px = t.mapX(x, y);
    final py = t.mapY(x, y);
    _pathQuadraticTo(pcx, pcy, px, py);
    _last.set(px, py);
    _ops++;
  }

  @override
  void bezierCurveTo(
    double cp1x,
    double cp1y,
    double cp2x,
    double cp2y,
    double x,
    double y,
  ) {
    if (!cp1x.isFinite ||
        !cp1y.isFinite ||
        !cp2x.isFinite ||
        !cp2y.isFinite ||
        !x.isFinite ||
        !y.isFinite ||
        !transform.isInvertible) {
      return;
    }
    final t = transform;
    final p1x = t.mapX(cp1x, cp1y);
    final p1y = t.mapY(cp1x, cp1y);
    if (!hasSubpath) _moveToMapped(p1x, p1y);
    final px = t.mapX(x, y);
    final py = t.mapY(x, y);
    _pathCubicTo(p1x, p1y, t.mapX(cp2x, cp2y), t.mapY(cp2x, cp2y), px, py);
    _last.set(px, py);
    _ops++;
  }

  @override
  void rect(double x, double y, double w, double h) {
    if (!x.isFinite ||
        !y.isFinite ||
        !w.isFinite ||
        !h.isFinite ||
        !transform.isInvertible) {
      return;
    }
    final t = transform;
    final x0 = t.mapX(x, y);
    final y0 = t.mapY(x, y);
    final x2 = t.mapX(x + w, y + h);
    final y2 = t.mapY(x + w, y + h);
    _moveToMapped(x0, y0);
    // The DOM order of the corners: the direction counts for the nonzero
    // rule when rectangles overlap.
    _pathLineTo(t.mapX(x + w, y), t.mapY(x + w, y));
    _pathLineTo(x2, y2);
    _pathLineTo(t.mapX(x, y + h), t.mapY(x, y + h));
    _pathClose();
    _rect = t.isAxisAligned
        ? ui.Rect.fromLTRB(
            math.min(x0, x2),
            math.min(y0, y2),
            math.max(x0, x2),
            math.max(y0, y2),
          )
        : null;
    _rrect = null;
    _trackShape(_rect);
    _ops++;
  }

  /// See [CanvasPath.roundRect] and [roundRectGeometry]. The arguments are
  /// examined first: a [RangeError] comes before the test of the transform.
  ///
  /// Under an axis-aligned transform, the path gets one `ui.Path.addRRect`
  /// of the mapped rectangle when the path goes clockwise in bitmap space
  /// (`addRRect` has no direction argument). Its contour starts at another
  /// point of the outline than the HTML path: a dashed stroke starts its
  /// pattern there, a display-only difference (Chart.js ADR 0034). Else, and
  /// under another transform, the path gets the segments of
  /// [_roundRectSegments]. Then a new subpath starts at (x, y).
  @override
  void roundRect(double x, double y, double w, double h, [Object? radii]) {
    final g = roundRectGeometry(x, y, w, h, radii);
    final t = transform;
    if (g == null || !t.isInvertible) return;
    ui.RRect? rrect;
    if (t.isAxisAligned) {
      rrect = _mappedRRect(g);
      if (g.clockwise != t.isReflected) {
        _pathAddRRect(rrect);
      } else {
        _roundRectSegments(g);
      }
    } else {
      _roundRectSegments(g);
    }
    _moveToMapped(t.mapX(x, y), t.mapY(x, y));
    _rect = null;
    _rrect = rrect;
    _trackShape(rrect);
    _ops++;
  }

  /// The rounded rectangle of [g] in bitmap space, for an axis-aligned
  /// transform. A mirror moves each radius to the mirrored corner, and a
  /// scale makes it elliptical.
  ui.RRect _mappedRRect(RoundRectGeometry g) {
    final t = transform;
    final x0 = t.mapX(g.left, g.top);
    final y0 = t.mapY(g.left, g.top);
    final x1 = t.mapX(g.left + g.width, g.top + g.height);
    final y1 = t.mapY(g.left + g.width, g.top + g.height);
    final sx = t.a.abs();
    final sy = t.d.abs();
    final flipX = t.a < 0;
    final flipY = t.d < 0;
    // The user corner at each bitmap corner.
    final tl = flipY
        ? (flipX ? g.lowerRight : g.lowerLeft)
        : (flipX ? g.upperRight : g.upperLeft);
    final tr = flipY
        ? (flipX ? g.lowerLeft : g.lowerRight)
        : (flipX ? g.upperLeft : g.upperRight);
    final br = flipY
        ? (flipX ? g.upperLeft : g.upperRight)
        : (flipX ? g.lowerLeft : g.lowerRight);
    final bl = flipY
        ? (flipX ? g.upperRight : g.upperLeft)
        : (flipX ? g.lowerRight : g.lowerLeft);
    return ui.RRect.fromLTRBAndCorners(
      math.min(x0, x1),
      math.min(y0, y1),
      math.max(x0, x1),
      math.max(y0, y1),
      topLeft: ui.Radius.elliptical(tl * sx, tl * sy),
      topRight: ui.Radius.elliptical(tr * sx, tr * sy),
      bottomRight: ui.Radius.elliptical(br * sx, br * sy),
      bottomLeft: ui.Radius.elliptical(bl * sx, bl * sy),
    );
  }

  /// The segments of [g]: from (left + upperLeft, top), a line and an arc
  /// for each corner, then the close. They go in the HTML order (step 12)
  /// when `g.clockwise` is true, else in the other direction, as Chromium
  /// adds a flipped rectangle. An arc connects to the current point with a
  /// line ([_addArc]), and an arc of radius 0 is that line alone.
  void _roundRectSegments(RoundRectGeometry g) {
    final t = transform;
    final l = g.left;
    final tp = g.top;
    final r = l + g.width;
    final b = tp + g.height;
    final ul = g.upperLeft;
    final ur = g.upperRight;
    final lr = g.lowerRight;
    final ll = g.lowerLeft;
    const quarter = math.pi / 2;
    _moveToMapped(t.mapX(l + ul, tp), t.mapY(l + ul, tp));
    if (g.clockwise) {
      _addArc(r - ur, tp + ur, ur, ur, 0, -quarter, quarter);
      _addArc(r - lr, b - lr, lr, lr, 0, 0, quarter);
      _addArc(l + ll, b - ll, ll, ll, 0, quarter, quarter);
      _addArc(l + ul, tp + ul, ul, ul, 0, math.pi, quarter);
    } else {
      _addArc(l + ul, tp + ul, ul, ul, 0, -quarter, -quarter);
      _addArc(l + ll, b - ll, ll, ll, 0, math.pi, -quarter);
      _addArc(r - lr, b - lr, lr, lr, 0, quarter, -quarter);
      _addArc(r - ur, tp + ur, ur, ur, 0, 0, -quarter);
    }
    _pathClose();
  }

  @override
  void arc(
    double x,
    double y,
    double radius,
    double startAngle,
    double endAngle, [
    bool counterclockwise = false,
  ]) {
    if (!x.isFinite ||
        !y.isFinite ||
        !radius.isFinite ||
        !startAngle.isFinite ||
        !endAngle.isFinite) {
      return;
    }
    if (radius < 0) {
      throw RangeError.value(radius, 'radius', 'The radius is negative');
    }
    if (!transform.isInvertible) return;
    final sweep = canvasArcSweep(startAngle, endAngle, counterclockwise);
    final t = transform;
    if (_ops == 0 && radius > 0 && t.isSimilarity && sweep.abs() >= _tau) {
      // A full circle on an empty path: keep it pending (see [_circle]).
      // The angles are those of [_addArc] for a similarity transform.
      final pcx = t.mapX(x, y);
      final pcy = t.mapY(x, y);
      final r = radius * t.scaleFactor;
      final a0 = t.isReflected ? t.angle - startAngle : t.angle + startAngle;
      _circle = true;
      _circleClosed = false;
      _circleX = pcx;
      _circleY = pcy;
      _circleR = r;
      _circleStart = a0;
      _circleSweep = t.isReflected ? -sweep : sweep;
      _start.setOnArc(pcx, pcy, r, r, a0);
      _last.setOnArc(pcx, pcy, r, r, a0 + _circleSweep);
      hasSubpath = true;
      _ops++;
      return;
    }
    _addArc(x, y, radius, radius, 0, startAngle, sweep);
    _ops++;
  }

  @override
  void ellipse(
    double x,
    double y,
    double radiusX,
    double radiusY,
    double rotation,
    double startAngle,
    double endAngle, [
    bool counterclockwise = false,
  ]) {
    if (!x.isFinite ||
        !y.isFinite ||
        !radiusX.isFinite ||
        !radiusY.isFinite ||
        !rotation.isFinite ||
        !startAngle.isFinite ||
        !endAngle.isFinite) {
      return;
    }
    if (radiusX < 0 || radiusY < 0) {
      throw RangeError('The radius is negative');
    }
    if (!transform.isInvertible) return;
    final sweep = canvasArcSweep(startAngle, endAngle, counterclockwise);
    _addArc(x, y, radiusX, radiusY, rotation, startAngle, sweep);
    _ops++;
  }

  @override
  void arcTo(double x1, double y1, double x2, double y2, double radius) {
    if (!x1.isFinite ||
        !y1.isFinite ||
        !x2.isFinite ||
        !y2.isFinite ||
        !radius.isFinite) {
      return;
    }
    if (radius < 0) {
      throw RangeError.value(radius, 'radius', 'The radius is negative');
    }
    final t = transform;
    if (!t.isInvertible) return;
    _ops++;
    if (!hasSubpath) {
      _moveToMapped(t.mapX(x1, y1), t.mapY(x1, y1));
    }
    // The current point, back in user space.
    final det = t.determinant;
    final lx = _last.x - t.e;
    final ly = _last.y - t.f;
    final x0 = (t.d * lx - t.c * ly) / det;
    final y0 = (t.a * ly - t.b * lx) / det;
    final v1x = x0 - x1;
    final v1y = y0 - y1;
    final v2x = x2 - x1;
    final v2y = y2 - y1;
    final len1 = math.sqrt(v1x * v1x + v1y * v1y);
    final len2 = math.sqrt(v2x * v2x + v2y * v2y);
    final cross = v1x * v2y - v1y * v2x;
    if (len1 == 0 ||
        len2 == 0 ||
        radius == 0 ||
        cross.abs() <= 1e-12 * len1 * len2) {
      _lineOrMove(x1, y1);
      return;
    }
    final u1x = v1x / len1;
    final u1y = v1y / len1;
    final u2x = v2x / len2;
    final u2y = v2y / len2;
    // The angle between the two lines at (x1, y1).
    final cos = (u1x * u2x + u1y * u2y).clamp(-1.0, 1.0);
    final half = math.acos(cos) / 2;
    final tangent = radius / math.tan(half);
    final t1x = x1 + u1x * tangent;
    final t1y = y1 + u1y * tangent;
    final t2x = x1 + u2x * tangent;
    final t2y = y1 + u2y * tangent;
    var bx = u1x + u2x;
    var by = u1y + u2y;
    final blen = math.sqrt(bx * bx + by * by);
    bx /= blen;
    by /= blen;
    final centerDistance = radius / math.sin(half);
    final cx = x1 + bx * centerDistance;
    final cy = y1 + by * centerDistance;
    final start = math.atan2(t1y - cy, t1x - cx);
    var sweep = math.atan2(t2y - cy, t2x - cx) - start;
    if (sweep > math.pi) sweep -= _tau;
    if (sweep < -math.pi) sweep += _tau;
    _addArc(cx, cy, radius, radius, 0, start, sweep);
  }

  /// Adds the arc of the ellipse at (cx, cy) with the radii rx and ry,
  /// rotated by [rotation], from the parametric angle [start] over [sweep]
  /// radians, all in user space. A line connects the current point to the
  /// start of the arc.
  void _addArc(
    double cx,
    double cy,
    double rx,
    double ry,
    double rotation,
    double start,
    double sweep,
  ) {
    final t = transform;
    if (rx == 0 && ry == 0) {
      _lineOrMove(cx, cy);
      return;
    }
    if (rx == ry && t.isSimilarity) {
      final pcx = t.mapX(cx, cy);
      final pcy = t.mapY(cx, cy);
      final r = rx * t.scaleFactor;
      final a0 = t.isReflected
          ? t.angle - (start + rotation)
          : t.angle + start + rotation;
      _nativeArc(pcx, pcy, r, r, a0, t.isReflected ? -sweep : sweep);
      return;
    }
    if (rotation == 0 && t.isAxisAligned) {
      final pcx = t.mapX(cx, cy);
      final pcy = t.mapY(cx, cy);
      final hx = rx * t.a.abs();
      final hy = ry * t.d.abs();
      double a0;
      double sw;
      if (t.a < 0 && t.d < 0) {
        a0 = start + math.pi;
        sw = sweep;
      } else if (t.a < 0) {
        a0 = math.pi - start;
        sw = -sweep;
      } else if (t.d < 0) {
        a0 = -start;
        sw = -sweep;
      } else {
        a0 = start;
        sw = sweep;
      }
      _nativeArc(pcx, pcy, hx, hy, a0, sw);
      return;
    }
    _bezierArc(cx, cy, rx, ry, rotation, start, sweep);
  }

  /// A `ui.Path.arcTo` in bitmap space, on the oval at ([cx], [cy]) with the
  /// radii [rx] and [ry]. A sweep of more than half a turn is two half arcs:
  /// `arcTo` takes the sweep in float degrees, and a sweep that rounds to 360
  /// degrees adds only a point. Chromium draws a circle for it. The current
  /// point and a new subpath start stay on the arc ([_PathPoint]).
  void _nativeArc(
    double cx,
    double cy,
    double rx,
    double ry,
    double start,
    double sweep,
  ) {
    if (sweep == 0) {
      final sx = cx + rx * math.cos(start);
      final sy = cy + ry * math.sin(start);
      if (hasSubpath) {
        _lineToMapped(sx, sy);
      } else {
        _moveToMapped(sx, sy);
      }
      return;
    }
    final forceMoveTo = !hasSubpath;
    if (forceMoveTo) {
      _start.setOnArc(cx, cy, rx, ry, start);
      hasSubpath = true;
    }
    if (sweep.abs() > math.pi) {
      final half = sweep / 2;
      _pathArcTo(cx, cy, rx, ry, start, half, forceMoveTo: forceMoveTo);
      _pathArcTo(cx, cy, rx, ry, start + half, half, forceMoveTo: false);
    } else {
      _pathArcTo(cx, cy, rx, ry, start, sweep, forceMoveTo: forceMoveTo);
    }
    _last.setOnArc(cx, cy, rx, ry, start + sweep);
  }

  /// The arc as cubic Bézier curves of at most 90 degrees each, for a
  /// transform that skews or scales unevenly, or a rotated ellipse.
  void _bezierArc(
    double cx,
    double cy,
    double rx,
    double ry,
    double rotation,
    double start,
    double sweep,
  ) {
    final t = transform;
    final cosR = math.cos(rotation);
    final sinR = math.sin(rotation);
    final segments = math.max(1, (sweep.abs() / (math.pi / 2) - 1e-9).ceil());
    final delta = sweep / segments;
    final k = 4 / 3 * math.tan(delta / 4);
    var cosP = math.cos(start);
    var sinP = math.sin(start);
    var x0 = cx + rx * cosP * cosR - ry * sinP * sinR;
    var y0 = cy + rx * cosP * sinR + ry * sinP * cosR;
    _lineOrMove(x0, y0);
    for (var i = 1; i <= segments; i++) {
      final phi = start + delta * i;
      final cos1 = math.cos(phi);
      final sin1 = math.sin(phi);
      final x1 = cx + rx * cos1 * cosR - ry * sin1 * sinR;
      final y1 = cy + rx * cos1 * sinR + ry * sin1 * cosR;
      final d0x = -rx * sinP * cosR - ry * cosP * sinR;
      final d0y = -rx * sinP * sinR + ry * cosP * cosR;
      final d1x = -rx * sin1 * cosR - ry * cos1 * sinR;
      final d1y = -rx * sin1 * sinR + ry * cos1 * cosR;
      final c1x = x0 + k * d0x;
      final c1y = y0 + k * d0y;
      final c2x = x1 - k * d1x;
      final c2y = y1 - k * d1y;
      final px = t.mapX(x1, y1);
      final py = t.mapY(x1, y1);
      _pathCubicTo(
        t.mapX(c1x, c1y),
        t.mapY(c1x, c1y),
        t.mapX(c2x, c2y),
        t.mapY(c2x, c2y),
        px,
        py,
      );
      _last.set(px, py);
      x0 = x1;
      y0 = y1;
      cosP = cos1;
      sinP = sin1;
    }
  }
}

/// The tolerance of [rrectContains] in units of a corner radius: 1e-9 of
/// the radius, below 1e-5 pixels for a radius below 10000 pixels.
const double _containsTolerance = 1e-9;

/// Whether [inner] is inside [outer], both with a width and a height of 0
/// or more. A `false` result does not mean that [inner] sticks out: the
/// test is sufficient, not necessary. A shape with a coordinate or a radius
/// that is not finite gives `false`.
///
/// When it is true, the even-odd fill of the two shapes is `outer` without
/// `inner`, and `Canvas.drawDRRect(outer, inner)` fills the same area. The
/// bounds of [inner] must be inside those of [outer] with no tolerance,
/// because Skia draws nothing for a `drawDRRect` whose inner bounds stick
/// out. Then, for each corner of [outer] with radii above 0, the points of
/// [inner] in the box of that corner must be inside its ellipse. In the
/// units of that ellipse, with its center at the origin and with C the
/// center and a the radii of the [inner] corner arc on the same side, the
/// test is:
/// - the two ends of the [inner] edges next to the corner are inside the
///   unit circle;
/// - |min(C, 0)| + max(a) <= 1: the corner arc of [inner] is inside it, by
///   the triangle inequality, for the part of the arc in the corner box.
///
/// Each comparison of the corner allows [_containsTolerance], so that the
/// border ring of a bar, whose corner arcs have one center, passes after
/// the rounding of the transform.
bool rrectContains(ui.RRect outer, ui.RRect inner) {
  if (!outer.isFinite ||
      !inner.isFinite ||
      inner.left < outer.left ||
      inner.top < outer.top ||
      inner.right > outer.right ||
      inner.bottom > outer.bottom) {
    return false;
  }
  // Each corner, mirrored into the place of the upper-left corner.
  return _cornerContains(
        outer.left,
        outer.top,
        outer.tlRadiusX,
        outer.tlRadiusY,
        inner.left,
        inner.top,
        inner.tlRadiusX,
        inner.tlRadiusY,
      ) &&
      _cornerContains(
        -outer.right,
        outer.top,
        outer.trRadiusX,
        outer.trRadiusY,
        -inner.right,
        inner.top,
        inner.trRadiusX,
        inner.trRadiusY,
      ) &&
      _cornerContains(
        -outer.right,
        -outer.bottom,
        outer.brRadiusX,
        outer.brRadiusY,
        -inner.right,
        -inner.bottom,
        inner.brRadiusX,
        inner.brRadiusY,
      ) &&
      _cornerContains(
        outer.left,
        -outer.bottom,
        outer.blRadiusX,
        outer.blRadiusY,
        inner.left,
        -inner.bottom,
        inner.blRadiusX,
        inner.blRadiusY,
      );
}

/// The corner test of [rrectContains], for an upper-left corner: the outer
/// shape has its edges at x = [ox] and y = [oy] and the corner radii [rx]
/// and [ry]. The inner shape has its edges at x = [ix] >= [ox] and
/// y = [iy] >= [oy] and the corner radii [irx] and [iry].
bool _cornerContains(
  double ox,
  double oy,
  double rx,
  double ry,
  double ix,
  double iy,
  double irx,
  double iry,
) {
  // A square corner: the test of the bounds covers it.
  if (!(rx > 0 && ry > 0)) return true;
  const limit = 1 + _containsTolerance;
  final centerX = ox + rx;
  final centerY = oy + ry;
  // The center of the inner corner arc, and the inner edges, in the units
  // of the outer corner ellipse.
  final cx = (ix + irx - centerX) / rx;
  final cy = (iy + iry - centerY) / ry;
  final edgeX = math.min((ix - centerX) / rx, 0);
  final edgeY = math.min((iy - centerY) / ry, 0);
  final nearX = math.min(cx, 0);
  final nearY = math.min(cy, 0);
  // The ends of the inner edges at the corner box: (cx, top) and
  // (left, cy).
  if (nearX * nearX + edgeY * edgeY > limit * limit) return false;
  if (edgeX * edgeX + nearY * nearY > limit * limit) return false;
  final reach = math.sqrt(nearX * nearX + nearY * nearY);
  return reach + math.max(irx / rx, iry / ry) <= limit;
}

/// The `ui.Path` of a [Path2D], in user space, kept in [Path2D.cache].
final class _CachedPath {
  _CachedPath(this.version, this.path);

  final int version;
  final ui.Path path;
}

final UiTransform _identity = UiTransform();

/// The `ui.Path` of [path2d] in user space. The result is cached on the
/// path while [Path2D.version] does not change.
ui.Path uiPathOf(Path2D path2d) {
  final cache = path2d.cache;
  if (cache is _CachedPath && cache.version == path2d.version) {
    return cache.path;
  }
  final builder = UiPathBuilder(_identity);
  path2d
    ..replay(builder)
    ..cache = _CachedPath(path2d.version, builder.path);
  return builder.path;
}
