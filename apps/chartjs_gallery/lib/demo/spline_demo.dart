// The package exports nothing from lib/src yet; the public API comes in
// phase 9. The demo imports the ported files directly.
// ignore_for_file: implementation_imports

import 'package:chartjs_gallery/demo/demo_common.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chartjs/src/helpers/helpers.curve.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/types/geometric.dart';

/// A point `{x, y}` whose control points the curve helpers write, as the
/// port tests of `helpers.curve` pass it.
final class _DemoPoint implements SplinePoint {
  _DemoPoint(this.x, this.y);

  @override
  final double x;

  @override
  final double y;

  @override
  bool? get skip => null;

  @override
  double cp1x = double.nan;

  @override
  double cp1y = double.nan;

  @override
  double cp2x = double.nan;

  @override
  double cp2y = double.nan;
}

/// The chart area `{left, top, right, bottom}` that `capBezierPoints` uses.
final class _Area implements ChartArea {
  const _Area(this.left, this.top, this.right, this.bottom);

  @override
  final double left;

  @override
  final double top;

  @override
  final double right;

  @override
  final double bottom;

  @override
  double get width => right - left;

  @override
  double get height => bottom - top;
}

/// The starting points, in fractions of the canvas.
const List<Offset> _initialPoints = [
  Offset(0.04, 0.70),
  Offset(0.18, 0.30),
  Offset(0.32, 0.55),
  Offset(0.46, 0.20),
  Offset(0.60, 0.85),
  Offset(0.74, 0.60),
  Offset(0.88, 0.62),
  Offset(0.96, 0.10),
];

/// Drag-able points and the Bézier curve that the ported `helpers.curve`
/// builds through them.
///
/// The default mode is `_updateBezierControlPoints` with the `tension`
/// option, which calls `splineCurve` for each point. The monotone mode is
/// `splineCurveMonotone`, the `cubicInterpolationMode: 'monotone'` of line
/// charts. The canvas draws the curve with `cubicTo` from `cp2` of each
/// point to `cp1` of the next, as `helpers.canvas` `_bezierCurveTo` does.
class SplineDemo extends StatefulWidget {
  /// Creates the splines tab.
  const SplineDemo({super.key});

  @override
  State<SplineDemo> createState() => _SplineDemoState();
}

class _SplineDemoState extends State<SplineDemo> {
  final List<Offset> _points = [..._initialPoints];
  bool _monotone = false;
  bool _cap = true;
  bool _showControls = true;
  double _tension = 0.4;

  /// The index of the point under the pointer, while a drag runs.
  int? _dragging;

  /// The last dragged point, which the readout shows.
  int _active = 1;

  /// From the pointer to the center of the dragged point, so that the point
  /// does not jump to the pointer when the drag starts.
  Offset _grab = Offset.zero;

  /// The canvas points with the control points of the current mode.
  List<_DemoPoint> _compute(Size size) {
    final points = [
      for (final p in _points)
        _DemoPoint(p.dx * size.width, p.dy * size.height),
    ];
    final area = _Area(0, 0, size.width, size.height);
    // The entry point of the line element: it calls splineCurveMonotone
    // for the monotone mode, else splineCurve for each point, then caps the
    // control points to the area when capBezierPoints is set.
    updateBezierControlPoints(
      points,
      <String, Object?>{
        'tension': _tension,
        'cubicInterpolationMode': _monotone ? 'monotone' : 'default',
        'capBezierPoints': _cap,
      },
      area,
      false,
      'x',
    );
    return points;
  }

  int? _hit(Offset local, Size size) {
    int? best;
    var bestDistance = 32.0 * 32.0;
    for (var i = 0; i < _points.length; i++) {
      final p = Offset(
        _points[i].dx * size.width,
        _points[i].dy * size.height,
      );
      final d = (p - local).distanceSquared;
      if (d < bestDistance) {
        bestDistance = d;
        best = i;
      }
    }
    return best;
  }

  /// Starts a drag when [local] hits a point, and returns whether it did.
  bool _start(Offset local, Size size) {
    final i = _hit(local, size);
    if (i == null) return false;
    _grab =
        Offset(_points[i].dx * size.width, _points[i].dy * size.height) - local;
    setState(() {
      _dragging = i;
      _active = i;
    });
    return true;
  }

  void _move(int i, Offset pointer, Size size) {
    final at = pointer + _grab;
    // Keep the x order, as the points of a line chart have it.
    const gap = 0.01;
    final lo = i == 0 ? 0.0 : _points[i - 1].dx + gap;
    final hi = i == _points.length - 1 ? 1.0 : _points[i + 1].dx - gap;
    setState(() {
      _points[i] = Offset(
        (at.dx / size.width).clamp(lo, hi),
        (at.dy / size.height).clamp(0.0, 1.0),
      );
    });
  }

  /// The last dragged point and its control points, in canvas pixels.
  String _readout(_DemoPoint p) {
    String n(double? v) =>
        v == null ? 'undefined' : (v.isNaN ? 'NaN' : v.toStringAsFixed(1));
    return 'point ${_active + 1} (${n(p.x)}, ${n(p.y)})   '
        'cp1 (${n(p.cp1x)}, ${n(p.cp1y)})   '
        'cp2 (${n(p.cp2x)}, ${n(p.cp2y)})';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DemoPageBody(
      children: [
        DemoCard(
          title: 'Drag the points',
          source: _monotone
              ? 'updateBezierControlPoints(points, {cubicInterpolationMode: '
                    "'monotone'}, …) → splineCurveMonotone"
              : 'updateBezierControlPoints(points, {tension: '
                    '${jsNumberToString(_tension)}}, …) → splineCurve',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SegmentedButton<bool>(
                    key: const ValueKey('spline.mode'),
                    segments: const [
                      ButtonSegment(value: false, label: Text('Tension')),
                      ButtonSegment(value: true, label: Text('Monotone')),
                    ],
                    selected: {_monotone},
                    onSelectionChanged: (s) =>
                        setState(() => _monotone = s.first),
                  ),
                  FilterChip(
                    key: const ValueKey('spline.cap'),
                    label: const Text('capBezierPoints'),
                    selected: _cap,
                    onSelected: (v) => setState(() => _cap = v),
                  ),
                  FilterChip(
                    key: const ValueKey('spline.controls'),
                    label: const Text('control points'),
                    selected: _showControls,
                    onSelected: (v) => setState(() => _showControls = v),
                  ),
                  TextButton.icon(
                    key: const ValueKey('spline.reset'),
                    onPressed: () => setState(() {
                      _points
                        ..clear()
                        ..addAll(_initialPoints);
                    }),
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Reset'),
                  ),
                ],
              ),
              if (!_monotone)
                Row(
                  children: [
                    const Text('tension'),
                    Expanded(
                      child: Slider(
                        key: const ValueKey('spline.tension'),
                        value: _tension,
                        divisions: 20,
                        label: _tension.toStringAsFixed(2),
                        onChanged: (v) => setState(() => _tension = v),
                      ),
                    ),
                    Mono(_tension.toStringAsFixed(2)),
                  ],
                ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, outer) {
                  // 16:10 on a phone, at most 460 high on a wide screen.
                  final size = Size(
                    outer.maxWidth,
                    (outer.maxWidth / 1.6).clamp(220.0, 460.0),
                  );
                  final points = _compute(size);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // A point drag must win at pointer down: the pan slop
                      // of a GestureDetector reports the start outside the
                      // hit radius, and a vertical touch drag goes to the
                      // page scroll first. A miss leaves the pointer to the
                      // page, so that it still scrolls.
                      RawGestureDetector(
                        key: const ValueKey('spline.canvas'),
                        gestures: {
                          _PointDragRecognizer:
                              GestureRecognizerFactoryWithHandlers<
                                _PointDragRecognizer
                              >(
                                _PointDragRecognizer.new,
                                (r) => r
                                  ..onDown = ((p) => _start(p, size))
                                  ..onUpdate = ((p) {
                                    final i = _dragging;
                                    if (i != null) _move(i, p, size);
                                  })
                                  ..onEnd = () {
                                    if (_dragging != null) {
                                      setState(() => _dragging = null);
                                    }
                                  },
                              ),
                        },
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerLowest,
                            border: Border.all(color: scheme.outlineVariant),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: CustomPaint(
                            size: size,
                            painter: _SplinePainter(
                              points: points,
                              active: _dragging,
                              showControls: _showControls,
                              curve: scheme.primary,
                              polyline: scheme.outline,
                              control: scheme.tertiary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Mono(
                        _readout(points[_active]),
                        key: const ValueKey('spline.readout'),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Grey: the polyline through the points. Colored: the Bézier '
                'curve from the control points that the port computes. '
                'Small rings: cp1 and cp2 of each point. With tension 0 the '
                'curve is the polyline. Monotone mode adds no extremum '
                'between two points.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SplinePainter extends CustomPainter {
  _SplinePainter({
    required this.points,
    required this.active,
    required this.showControls,
    required this.curve,
    required this.polyline,
    required this.control,
  });

  final List<_DemoPoint> points;
  final int? active;
  final bool showControls;
  final Color curve;
  final Color polyline;
  final Color control;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    Offset at(_DemoPoint p) => Offset(p.x, p.y);
    // splineCurveMonotone leaves cp1 of the first point and cp2 of the last
    // point undefined (Dart null).
    Offset? cp(double? x, double? y) =>
        x == null || y == null || x.isNaN || y.isNaN ? null : Offset(x, y);

    final line = Path()..moveTo(points.first.x, points.first.y);
    for (final p in points.skip(1)) {
      line.lineTo(p.x, p.y);
    }
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = polyline.withValues(alpha: 0.6),
    );

    // helpers.canvas _bezierCurveTo: from cp2 of the previous point to cp1
    // of the target point.
    final bezier = Path()..moveTo(points.first.x, points.first.y);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final p = points[i];
      final c2 = cp(prev.cp2x, prev.cp2y);
      final c1 = cp(p.cp1x, p.cp1y);
      if (c2 == null || c1 == null) {
        bezier.lineTo(p.x, p.y);
      } else {
        bezier.cubicTo(c2.dx, c2.dy, c1.dx, c1.dy, p.x, p.y);
      }
    }
    canvas.drawPath(
      bezier,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = curve,
    );

    if (showControls) {
      final arm = Paint()
        ..color = control.withValues(alpha: 0.7)
        ..strokeWidth = 1;
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = control;
      for (final p in points) {
        for (final c in [cp(p.cp1x, p.cp1y), cp(p.cp2x, p.cp2y)]) {
          if (c == null) continue;
          canvas
            ..drawLine(at(p), c, arm)
            ..drawCircle(c, 4, ring);
        }
      }
    }

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      if (i == active) {
        canvas.drawCircle(
          at(p),
          18,
          Paint()..color = curve.withValues(alpha: 0.2),
        );
      }
      canvas
        ..drawCircle(at(p), 9, Paint()..color = curve)
        ..drawCircle(at(p), 5, Paint()..color = const Color(0xFFFFFFFF));
    }
  }

  @override
  bool shouldRepaint(_SplinePainter oldDelegate) => true;
}

/// Drags a point of the spline canvas.
///
/// At pointer down it asks [onDown] whether the pointer hits a point. On a
/// hit it takes the pointer at once, before the page scroll or the pan slop
/// can claim it, and reports each move to [onUpdate]. On a miss it leaves
/// the pointer to the other recognizers, so that the page still scrolls.
class _PointDragRecognizer extends OneSequenceGestureRecognizer {
  _PointDragRecognizer({super.debugOwner});

  /// Whether the local position hits a point; `true` starts the drag.
  bool Function(Offset localPosition)? onDown;

  /// A move of the dragging pointer, in local coordinates.
  ValueChanged<Offset>? onUpdate;

  /// The end of the drag: pointer up, cancel or a lost arena.
  VoidCallback? onEnd;

  int? _pointer;

  @override
  bool isPointerAllowed(PointerDownEvent event) =>
      super.isPointerAllowed(event) &&
      (event.kind != PointerDeviceKind.mouse ||
          event.buttons == kPrimaryMouseButton);

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (_pointer != null || onDown?.call(event.localPosition) != true) return;
    _pointer = event.pointer;
    startTrackingPointer(event.pointer, event.transform);
    resolve(GestureDisposition.accepted);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer != _pointer) return;
    if (event is PointerMoveEvent) {
      onUpdate?.call(event.localPosition);
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void rejectGesture(int pointer) {
    stopTrackingPointer(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _pointer = null;
    onEnd?.call();
  }

  @override
  String get debugDescription => 'spline point drag';
}
