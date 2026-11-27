// Original code, not ported from D3: flutter_d3_quadtree_port interactive demo.

import 'dart:math' as math;

import 'package:flutter_d3_quadtree_port/flutter_d3_quadtree_port.dart' as d3;
import 'package:material_ui/material_ui.dart';

enum _PointDistribution(final String label) {
  clustered('Clustered'),
  uniform('Uniform'),
  spiral('Spiral'),
  ring('Ring'),
}

/// Interactive showcase of `flutter_d3_quadtree_port`: live 2D quadtree
/// subdivision grid over 500–5,000 points, hover/tap nearest-neighbor `find`
/// with configurable search radius, and drag-to-select rectangular range query
/// using `visit` with pruned-quadrant highlighting.
class const QuadtreeDemoPage({super.key}) extends StatefulWidget {
  /// Creates the `d3-quadtree` demo page.
  this;

  @override
  State<QuadtreeDemoPage> createState() => _QuadtreeDemoPageState();
}

class _QuadtreeDemoPageState() extends State<QuadtreeDemoPage> {
  static const double _worldSize = 1000;

  _PointDistribution _distribution = _PointDistribution.clustered;
  int _pointCount = 1200;
  int _seed = 11;
  double _searchRadius = 110;
  bool _unboundedRadius = false;
  bool _showGrid = true;

  // Query state in world coordinates [0..1000].
  (double, double) _cursor = (510, 480);
  Rect _selection = const Rect.fromLTRB(260, 260, 620, 580);
  Offset? _dragStart;

  late List<(double, double)> _points = _generatePoints(
    _distribution,
    _pointCount,
    _seed,
  );
  late d3.Quadtree<(double, double)> _tree = _buildTree(_points);
  late _TreeSummary _summary = _summarizeTree(_tree);

  static List<(double, double)> _generatePoints(
    _PointDistribution dist,
    int count,
    int seed,
  ) {
    final rng = math.Random(seed * 7919 + dist.index * 131 + count);
    double gaussian() {
      final u1 = math.max(1e-9, rng.nextDouble());
      final u2 = rng.nextDouble();
      return math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2);
    }

    double clampWorld(double v) => v.clamp(12.0, _worldSize - 12.0);

    const centers = <(double, double)>[
      (230, 250),
      (740, 240),
      (500, 510),
      (280, 760),
      (750, 740),
    ];

    return List<(double, double)>.generate(count, (i) {
      return switch (dist) {
        _PointDistribution.clustered => () {
          final (cx, cy) = centers[i % centers.length];
          return (
            clampWorld(cx + gaussian() * 78.0),
            clampWorld(cy + gaussian() * 78.0),
          );
        }(),
        _PointDistribution.uniform => (
          12.0 + rng.nextDouble() * (_worldSize - 24.0),
          12.0 + rng.nextDouble() * (_worldSize - 24.0),
        ),
        _PointDistribution.spiral => () {
          final t = i / count;
          final angle = t * math.pi * 10.0 + (i.isEven ? 0.0 : math.pi);
          final radius = 30.0 + t * 430.0 + gaussian() * 22.0;
          return (
            clampWorld(500.0 + math.cos(angle) * radius),
            clampWorld(500.0 + math.sin(angle) * radius),
          );
        }(),
        _PointDistribution.ring => () {
          final angle = rng.nextDouble() * math.pi * 2.0;
          final r = (i % 5 == 0 ? 150.0 : 340.0) + gaussian() * 34.0;
          return (
            clampWorld(500.0 + math.cos(angle) * r),
            clampWorld(500.0 + math.sin(angle) * r),
          );
        }(),
      };
    }, growable: false);
  }

  static d3.Quadtree<(double, double)> _buildTree(List<(double, double)> pts) =>
      d3.quadtree()
        ..setExtent(((0, 0), (_worldSize, _worldSize)))
        ..addAll(pts);

  static _TreeSummary _summarizeTree(d3.Quadtree<(double, double)> tree) {
    var internal = 0;
    var leaves = 0;
    final rects = <Rect>[];
    tree.visit((node, x0, y0, x1, y1) {
      rects.add(Rect.fromLTRB(x0, y0, x1, y1));
      switch (node) {
        case d3.QuadtreeInternalNode<(double, double)>():
          ++internal;
        case d3.QuadtreeLeafNode<(double, double)>():
          ++leaves;
      }
      return false;
    });
    return _TreeSummary(
      totalNodes: internal + leaves,
      internalNodes: internal,
      leafNodes: leaves,
      allRects: rects,
    );
  }

  void _rebuild({_PointDistribution? distribution, int? count, int? seed}) {
    setState(() {
      if (distribution != null) _distribution = distribution;
      if (count != null) _pointCount = count;
      if (seed != null) _seed = seed;
      _points = _generatePoints(_distribution, _pointCount, _seed);
      _tree = _buildTree(_points);
      _summary = _summarizeTree(_tree);
    });
  }

  (double, double) _toWorld(Offset local, Size size) => (
    (local.dx / size.width * _worldSize).clamp(0.0, _worldSize),
    (local.dy / size.height * _worldSize).clamp(0.0, _worldSize),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Nearest-neighbor query via quadtree.find.
    final radius = _unboundedRadius ? null : _searchRadius;
    final nearest = _tree.find(_cursor.$1, _cursor.$2, radius);
    final nearestDist = nearest == null
        ? null
        : math.sqrt(
            math.pow(nearest.$1 - _cursor.$1, 2) +
                math.pow(nearest.$2 - _cursor.$2, 2),
          );

    // Rectangular range query via quadtree.visit with pruning telemetry.
    final rx0 = _selection.left;
    final ry0 = _selection.top;
    final rx1 = _selection.right;
    final ry1 = _selection.bottom;
    final selectedPoints = <(double, double)>[];
    final visitedQuads = <Rect>[];
    final prunedQuads = <Rect>[];

    _tree.visit((node, x0, y0, x1, y1) {
      final outside = x0 >= rx1 || y0 >= ry1 || x1 < rx0 || y1 < ry0;
      if (outside) {
        prunedQuads.add(Rect.fromLTRB(x0, y0, x1, y1));
        return true;
      }
      visitedQuads.add(Rect.fromLTRB(x0, y0, x1, y1));
      if (node is d3.QuadtreeLeafNode<(double, double)>) {
        d3.QuadtreeLeafNode<(double, double)>? leaf = node;
        while (leaf != null) {
          final (px, py) = leaf.data;
          if (px >= rx0 && px < rx1 && py >= ry0 && py < ry1) {
            selectedPoints.add(leaf.data);
          }
          leaf = leaf.next;
        }
      }
      return false;
    });

    final totalNodes = _summary.totalNodes;
    final visitedTotal = visitedQuads.length + prunedQuads.length;
    final skippedNodes = math.max(0, totalNodes - visitedTotal);
    final skippedPct = totalNodes > 0 ? skippedNodes * 100.0 / totalNodes : 0.0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '2D Spatial Subdivision, Nearest-Neighbor & Pruned Range Queries',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pure Dart, fully statically typed port of d3-quadtree '
          'v${d3.d3QuadtreeVersion}: sealed QuadtreeNode<T> hierarchy, '
          'nearest-neighbor find(x, y, radius), and pruned pre-order visit. '
          'Hover or tap to query nearest point; drag to sweep a range box.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),

        // Controls card
        Card.outlined(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final dist in _PointDistribution.values)
                            ChoiceChip(
                              label: Text(dist.label),
                              selected: _distribution == dist,
                              onSelected: (_) => _rebuild(distribution: dist),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: () => _rebuild(seed: _seed + 1),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Resample'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 280,
                      child: Row(
                        children: [
                          Text('Points: $_pointCount'),
                          Expanded(
                            child: Slider(
                              value: _pointCount.toDouble(),
                              min: 500,
                              max: 5000,
                              divisions: 18,
                              label: '$_pointCount',
                              onChanged: (v) =>
                                  _rebuild(count: (v / 250).round() * 250),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 290,
                      child: Row(
                        children: [
                          Text(
                            _unboundedRadius
                                ? 'Radius: ∞'
                                : 'Radius: ${_searchRadius.round()}',
                          ),
                          Expanded(
                            child: Slider(
                              value: _searchRadius,
                              min: 20,
                              max: 250,
                              divisions: 46,
                              label: '${_searchRadius.round()}',
                              onChanged: _unboundedRadius
                                  ? null
                                  : (v) => setState(() => _searchRadius = v),
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilterChip(
                      label: const Text('Unbounded radius'),
                      selected: _unboundedRadius,
                      onSelected: (v) => setState(() => _unboundedRadius = v),
                    ),
                    FilterChip(
                      label: const Text('Subdivision grid'),
                      selected: _showGrid,
                      onSelected: (v) => setState(() => _showGrid = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Interactive Canvas Card
        Card.outlined(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final canvasWidth = constraints.maxWidth;
                  final canvasHeight = math.min<double>(
                    520,
                    canvasWidth * 0.68,
                  );
                  final canvasSize = Size(canvasWidth, canvasHeight);
                  return MouseRegion(
                    cursor: SystemMouseCursors.precise,
                    onHover: (event) {
                      setState(() {
                        _cursor = _toWorld(event.localPosition, canvasSize);
                      });
                    },
                    child: GestureDetector(
                      onTapDown: (details) {
                        setState(() {
                          _cursor = _toWorld(details.localPosition, canvasSize);
                        });
                      },
                      onPanStart: (details) {
                        final (wx, wy) = _toWorld(
                          details.localPosition,
                          canvasSize,
                        );
                        setState(() {
                          _dragStart = Offset(wx, wy);
                          _cursor = (wx, wy);
                          _selection = Rect.fromPoints(
                            _dragStart!,
                            _dragStart!,
                          );
                        });
                      },
                      onPanUpdate: (details) {
                        final (wx, wy) = _toWorld(
                          details.localPosition,
                          canvasSize,
                        );
                        final start = _dragStart ?? Offset(wx, wy);
                        setState(() {
                          _cursor = (wx, wy);
                          _selection = Rect.fromPoints(start, Offset(wx, wy));
                        });
                      },
                      onPanEnd: (_) => _dragStart = null,
                      child: SizedBox(
                        width: canvasWidth,
                        height: canvasHeight,
                        child: CustomPaint(
                          painter: _QuadtreePainter(
                            worldSize: _worldSize,
                            points: _points,
                            allQuads: _summary.allRects,
                            visitedQuads: visitedQuads,
                            prunedQuads: prunedQuads,
                            selectedPoints: selectedPoints,
                            selection: _selection,
                            cursor: _cursor,
                            nearest: nearest,
                            radius: radius,
                            showGrid: _showGrid,
                            colorScheme: cs,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  children: [
                    _StatPill(
                      label: 'Tree nodes',
                      value:
                          '$totalNodes (${_summary.internalNodes} branch, '
                          '${_summary.leafNodes} leaf)',
                    ),
                    _StatPill(
                      label: 'Nearest find',
                      value: nearest == null
                          ? 'none within radius ${_searchRadius.round()}'
                          : '(${nearest.$1.toStringAsFixed(1)}, '
                                '${nearest.$2.toStringAsFixed(1)}) · '
                                'd = ${nearestDist!.toStringAsFixed(1)}',
                    ),
                    _StatPill(
                      label: 'Range visit',
                      value:
                          '${selectedPoints.length} pts · '
                          '${visitedQuads.length} visited · '
                          '${prunedQuads.length} pruned '
                          '(${skippedPct.toStringAsFixed(1)}% tree skipped)',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _TreeSummary({
  required final int totalNodes,
  required final int internalNodes,
  required final int leafNodes,
  required final List<Rect> allRects,
});

class const _StatPill({
  required final String label,
  required final String value,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.labelMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _QuadtreePainter({
  required final double worldSize,
  required final List<(double, double)> points,
  required final List<Rect> allQuads,
  required final List<Rect> visitedQuads,
  required final List<Rect> prunedQuads,
  required final List<(double, double)> selectedPoints,
  required final Rect selection,
  required final (double, double) cursor,
  required final (double, double)? nearest,
  required final double? radius,
  required final bool showGrid,
  required final ColorScheme colorScheme,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / worldSize;
    final sy = size.height / worldSize;
    Rect mapRect(Rect r) =>
        Rect.fromLTRB(r.left * sx, r.top * sy, r.right * sx, r.bottom * sy);

    // 1. Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = colorScheme.surfaceContainerLowest,
    );

    // 2. Pruned quadrants shaded softly (subtrees skipped by visit).
    if (selection.width > 1 && selection.height > 1) {
      final prunedFill = Paint()
        ..color = colorScheme.error.withValues(alpha: 0.06)
        ..style = PaintingStyle.fill;
      final prunedStroke = Paint()
        ..color = colorScheme.error.withValues(alpha: 0.24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      for (final r in prunedQuads) {
        final mr = mapRect(r);
        canvas
          ..drawRect(mr, prunedFill)
          ..drawRect(mr, prunedStroke);
      }

      // 3. Visited quadrants intersecting the selection box.
      final visitedFill = Paint()
        ..color = colorScheme.primary.withValues(alpha: 0.05)
        ..style = PaintingStyle.fill;
      for (final r in visitedQuads) {
        canvas.drawRect(mapRect(r), visitedFill);
      }
    }

    // 4. Full subdivision grid overlay.
    if (showGrid) {
      final gridPaint = Paint()
        ..color = colorScheme.outlineVariant.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7;
      for (final r in allQuads) {
        canvas.drawRect(mapRect(r), gridPaint);
      }
    }

    // 5. All points (muted) and selected range points (bright).
    final dotRadius = points.length > 2500 ? 1.8 : 2.4;
    final baseDot = Paint()
      ..color = colorScheme.onSurfaceVariant.withValues(alpha: 0.45);
    for (final (px, py) in points) {
      canvas.drawCircle(Offset(px * sx, py * sy), dotRadius, baseDot);
    }

    final selDot = Paint()..color = colorScheme.primary;
    for (final (px, py) in selectedPoints) {
      canvas.drawCircle(Offset(px * sx, py * sy), dotRadius + 0.9, selDot);
    }

    // 6. Drag-selection range rectangle.
    if (selection.width > 1 && selection.height > 1) {
      final selRect = mapRect(selection);
      canvas
        ..drawRect(
          selRect,
          Paint()
            ..color = colorScheme.primary.withValues(alpha: 0.10)
            ..style = PaintingStyle.fill,
        )
        ..drawRect(
          selRect,
          Paint()
            ..color = colorScheme.primary
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );
    }

    // 7. Nearest-neighbor search radius circle & connector.
    final cx = cursor.$1 * sx;
    final cy = cursor.$2 * sy;
    final cursorOffset = Offset(cx, cy);
    final r = radius;
    if (r != null) {
      final oval = Rect.fromCenter(
        center: cursorOffset,
        width: r * 2 * sx,
        height: r * 2 * sy,
      );
      canvas
        ..drawOval(
          oval,
          Paint()
            ..color = colorScheme.tertiary.withValues(alpha: 0.10)
            ..style = PaintingStyle.fill,
        )
        ..drawOval(
          oval,
          Paint()
            ..color = colorScheme.tertiary.withValues(alpha: 0.75)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
    }

    final hit = nearest;
    if (hit != null) {
      final hitOffset = Offset(hit.$1 * sx, hit.$2 * sy);
      canvas
        ..drawLine(
          cursorOffset,
          hitOffset,
          Paint()
            ..color = colorScheme.tertiary
            ..strokeWidth = 1.8,
        )
        ..drawCircle(
          hitOffset,
          7,
          Paint()
            ..color = colorScheme.tertiary.withValues(alpha: 0.25)
            ..style = PaintingStyle.fill,
        )
        ..drawCircle(hitOffset, 4.5, Paint()..color = colorScheme.tertiary);
    }

    // Cursor crosshair.
    final crossPaint = Paint()
      ..color = colorScheme.tertiary
      ..strokeWidth = 1.4;
    canvas
      ..drawLine(Offset(cx - 6, cy), Offset(cx + 6, cy), crossPaint)
      ..drawLine(Offset(cx, cy - 6), Offset(cx, cy + 6), crossPaint);
  }

  @override
  bool shouldRepaint(covariant _QuadtreePainter oldDelegate) => true;
}
