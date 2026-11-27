// Original code, not ported from D3: flutter_d3_delaunay_port interactive demo.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_delaunay_port/flutter_d3_delaunay_port.dart' as d3;
import 'package:flutter_d3_path_port/flutter_d3_path_port.dart'
    show UiPathContext;
import 'package:flutter_d3_scale_chromatic_port/flutter_d3_scale_chromatic_port.dart'
    as chromatic;
import 'package:material_ui/material_ui.dart';

enum _DelaunayPalette(final String label) {
  turbo('Turbo'),
  viridis('Viridis'),
  plasma('Plasma'),
  spectral('Spectral'),
  ylGnBu('YlGnBu');

  Color sample(double t) {
    final c = t.clamp(0.0, 1.0);
    final rgb = switch (this) {
      _DelaunayPalette.turbo => chromatic.interpolateTurbo(c).rgb(),
      _DelaunayPalette.viridis => chromatic.interpolateViridis(c).rgb(),
      _DelaunayPalette.plasma => chromatic.interpolatePlasma(c).rgb(),
      _DelaunayPalette.spectral => chromatic.interpolateSpectral(c).rgb(),
      _DelaunayPalette.ylGnBu => chromatic.interpolateYlGnBu(c).rgb(),
    };
    return Color.fromARGB(
      255,
      rgb.r.round().clamp(0, 255),
      rgb.g.round().clamp(0, 255),
      rgb.b.round().clamp(0, 255),
    );
  }
}

/// Interactive showcase of `flutter_d3_delaunay_port`: live Voronoi & Delaunay
/// canvas with point-count slider, Lloyd's relaxation steps, toggles for
/// Voronoi cells / Delaunay mesh / convex hull / circumcenters, and real-time
/// pointer hover highlighting the nearest site, its Voronoi cell, and its
/// clipped neighbors via `find`/`neighbors` — colored with
/// `flutter_d3_scale_chromatic_port` and drawn directly with [UiPathContext].
class const DelaunayDemoPage({super.key}) extends StatefulWidget {
  /// Creates the `d3-delaunay` demo page.
  this;

  @override
  State<DelaunayDemoPage> createState() => _DelaunayDemoPageState();
}

class _DelaunayDemoPageState() extends State<DelaunayDemoPage> {
  static const double _worldW = 960;
  static const double _worldH = 560;

  int _pointCount = 120;
  int _seed = 7;
  int _lloydSteps = 0;
  _DelaunayPalette _palette = _DelaunayPalette.turbo;

  bool _showVoronoi = true;
  bool _showDelaunay = true;
  bool _showHull = true;
  bool _showCircumcenters = false;

  (double, double) _cursor = (480, 280);
  int _hoveredSite = 0;

  late Float64List _coords = _generateCoords(_pointCount, _seed);
  late d3.Delaunay _delaunay = d3.Delaunay(_coords);
  late d3.Voronoi _voronoi = _delaunay.voronoi((0, 0, _worldW, _worldH));
  late List<double> _cellAreas = _computeCellAreaRatios(_voronoi);

  static Float64List _generateCoords(int count, int seed) {
    final rng = math.Random(seed * 4999 + count * 31);
    final out = Float64List(count * 2);
    const pad = 28.0;
    for (var i = 0; i < count; ++i) {
      out[2 * i] = pad + rng.nextDouble() * (_worldW - pad * 2);
      out[2 * i + 1] = pad + rng.nextDouble() * (_worldH - pad * 2);
    }
    return out;
  }

  /// Normalized cell area ratio per site for chromatic coloring.
  static List<double> _computeCellAreaRatios(d3.Voronoi voronoi) {
    final n = voronoi.delaunay.points.length >> 1;
    final areas = List<double>.filled(n, 0);
    var maxArea = 1.0;
    for (var i = 0; i < n; ++i) {
      final poly = voronoi.cellPolygon(i);
      if (poly == null || poly.length < 3) continue;
      final area = _polygonArea(poly).abs();
      areas[i] = area;
      if (area > maxArea) maxArea = area;
    }
    return List<double>.generate(
      n,
      (i) => math.sqrt((areas[i] / maxArea).clamp(0.0, 1.0)),
      growable: false,
    );
  }

  static double _polygonArea(List<(double, double)> poly) {
    var sum = 0.0;
    for (var i = 0; i < poly.length - 1; ++i) {
      final (x0, y0) = poly[i];
      final (x1, y1) = poly[i + 1];
      sum += x0 * y1 - x1 * y0;
    }
    return sum * 0.5;
  }

  static (double, double) _polygonCentroid(List<(double, double)> poly) {
    var area2 = 0.0;
    var cx = 0.0;
    var cy = 0.0;
    for (var i = 0; i < poly.length - 1; ++i) {
      final (x0, y0) = poly[i];
      final (x1, y1) = poly[i + 1];
      final cross = x0 * y1 - x1 * y0;
      area2 += cross;
      cx += (x0 + x1) * cross;
      cy += (y0 + y1) * cross;
    }
    if (area2.abs() < 1e-9) {
      var sx = 0.0;
      var sy = 0.0;
      final m = poly.length - 1;
      for (var i = 0; i < m; ++i) {
        sx += poly[i].$1;
        sy += poly[i].$2;
      }
      return (sx / m, sy / m);
    }
    final inv = 1.0 / (3.0 * area2);
    return (cx * inv, cy * inv);
  }

  void _rebuild({int? count, int? seed}) {
    setState(() {
      if (count != null) _pointCount = count;
      if (seed != null) _seed = seed;
      _lloydSteps = 0;
      _coords = _generateCoords(_pointCount, _seed);
      _delaunay = d3.Delaunay(_coords);
      _voronoi = _delaunay.voronoi((0, 0, _worldW, _worldH));
      _cellAreas = _computeCellAreaRatios(_voronoi);
      _hoveredSite = _delaunay.find(_cursor.$1, _cursor.$2);
    });
  }

  void _stepLloyd() {
    setState(() {
      final n = _coords.length >> 1;
      for (var i = 0; i < n; ++i) {
        final poly = _voronoi.cellPolygon(i);
        if (poly == null || poly.length < 3) continue;
        final (cx, cy) = _polygonCentroid(poly);
        _coords[2 * i] = cx.clamp(4.0, _worldW - 4.0);
        _coords[2 * i + 1] = cy.clamp(4.0, _worldH - 4.0);
      }
      _voronoi.update();
      _cellAreas = _computeCellAreaRatios(_voronoi);
      _lloydSteps++;
      _hoveredSite = _delaunay.find(_cursor.$1, _cursor.$2, _hoveredSite);
    });
  }

  void _updateHover(Offset local, Size size) {
    final wx = (local.dx / size.width * _worldW).clamp(0.0, _worldW);
    final wy = (local.dy / size.height * _worldH).clamp(0.0, _worldH);
    final start = _hoveredSite >= 0 && _hoveredSite < _pointCount
        ? _hoveredSite
        : 0;
    final found = _delaunay.find(wx, wy, start);
    setState(() {
      _cursor = (wx, wy);
      _hoveredSite = found;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final site = _hoveredSite >= 0 && _hoveredSite < _pointCount
        ? _hoveredSite
        : _delaunay.find(_cursor.$1, _cursor.$2);
    final voronoiNeighbors = site >= 0
        ? _voronoi.neighbors(site).toSet()
        : const <int>{};
    final delaunayNeighbors = site >= 0
        ? _delaunay.neighbors(site).toList()
        : const <int>[];
    final triangleCount = _delaunay.triangles.length ~/ 3;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Delaunay Triangulation, Clipped Voronoi & Lloyd Relaxation',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Native Dart port of d3-delaunay v${d3.d3DelaunayVersion} '
          '(delaunator v${d3.delaunatorVersion}, robust-predicates '
          'v${d3.robustPredicatesVersion} orient2d) drawn directly to Canvas '
          'via UiPathContext. Hover or tap to inspect the nearest site, its '
          'Voronoi cell, and clipped neighbors.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Card.outlined(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 260,
                      child: Row(
                        children: [
                          Text('Sites: $_pointCount'),
                          Expanded(
                            child: Slider(
                              value: _pointCount.toDouble(),
                              min: 20,
                              max: 500,
                              divisions: 24,
                              label: '$_pointCount',
                              onChanged: (v) =>
                                  _rebuild(count: (v / 20).round() * 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _stepLloyd,
                      icon: const Icon(Icons.auto_fix_high, size: 18),
                      label: Text(
                        _lloydSteps == 0
                            ? "Lloyd's step"
                            : "Lloyd's step ($_lloydSteps)",
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => _rebuild(seed: _seed + 1),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Resample'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Voronoi cells'),
                      selected: _showVoronoi,
                      onSelected: (v) => setState(() => _showVoronoi = v),
                    ),
                    FilterChip(
                      label: const Text('Delaunay mesh'),
                      selected: _showDelaunay,
                      onSelected: (v) => setState(() => _showDelaunay = v),
                    ),
                    FilterChip(
                      label: const Text('Convex hull'),
                      selected: _showHull,
                      onSelected: (v) => setState(() => _showHull = v),
                    ),
                    FilterChip(
                      label: const Text('Circumcenters'),
                      selected: _showCircumcenters,
                      onSelected: (v) => setState(() => _showCircumcenters = v),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in _DelaunayPalette.values)
                      ChoiceChip(
                        label: Text(p.label),
                        selected: _palette == p,
                        onSelected: (_) => setState(() => _palette = p),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card.outlined(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final height = math.min<double>(540, width * 0.62);
                  final size = Size(width, height);
                  return MouseRegion(
                    cursor: SystemMouseCursors.precise,
                    onHover: (e) => _updateHover(e.localPosition, size),
                    child: GestureDetector(
                      onTapDown: (d) => _updateHover(d.localPosition, size),
                      onPanUpdate: (d) => _updateHover(d.localPosition, size),
                      child: SizedBox(
                        width: width,
                        height: height,
                        child: CustomPaint(
                          painter: _DelaunayPainter(
                            worldW: _worldW,
                            worldH: _worldH,
                            delaunay: _delaunay,
                            voronoi: _voronoi,
                            cellAreas: _cellAreas,
                            palette: _palette,
                            showVoronoi: _showVoronoi,
                            showDelaunay: _showDelaunay,
                            showHull: _showHull,
                            showCircumcenters: _showCircumcenters,
                            hoveredSite: site,
                            voronoiNeighbors: voronoiNeighbors,
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
                    _StatPill(label: 'Triangles', value: '$triangleCount'),
                    _StatPill(
                      label: 'Hull vertices',
                      value: '${_delaunay.hull.length}',
                    ),
                    _StatPill(
                      label: 'Nearest site',
                      value: site >= 0
                          ? '#$site '
                                '(${_coords[2 * site].toStringAsFixed(0)}, '
                                '${_coords[2 * site + 1].toStringAsFixed(0)})'
                          : 'none',
                    ),
                    _StatPill(
                      label: 'Neighbors',
                      value:
                          '${voronoiNeighbors.length} Voronoi · '
                          '${delaunayNeighbors.length} Delaunay',
                    ),
                    _StatPill(label: 'Lloyd steps', value: '$_lloydSteps'),
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

class _DelaunayPainter({
  required final double worldW,
  required final double worldH,
  required final d3.Delaunay delaunay,
  required final d3.Voronoi voronoi,
  required final List<double> cellAreas,
  required final _DelaunayPalette palette,
  required final bool showVoronoi,
  required final bool showDelaunay,
  required final bool showHull,
  required final bool showCircumcenters,
  required final int hoveredSite,
  required final Set<int> voronoiNeighbors,
  required final ColorScheme colorScheme,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / worldW;
    final sy = size.height / worldH;

    canvas
      ..drawRect(
        Offset.zero & size,
        Paint()..color = colorScheme.surfaceContainerLowest,
      )
      ..save()
      ..scale(sx, sy);

    final ctx = UiPathContext();
    final n = delaunay.points.length >> 1;

    // 1. Filled Voronoi cells colored by normalized cell area via
    //    flutter_d3_scale_chromatic_port and drawn directly with UiPathContext.
    if (showVoronoi) {
      final fillPaint = Paint()..style = PaintingStyle.fill;
      for (var i = 0; i < n; ++i) {
        ctx.reset();
        voronoi.renderCell(i, ctx);
        final isHovered = i == hoveredSite;
        final isNeighbor = voronoiNeighbors.contains(i);
        final baseColor = palette.sample(cellAreas[i]);
        fillPaint.color = isHovered
            ? baseColor.withValues(alpha: 0.78)
            : isNeighbor
            ? baseColor.withValues(alpha: 0.48)
            : baseColor.withValues(alpha: 0.24);
        canvas.drawPath(ctx.path, fillPaint);
      }

      // Clipped Voronoi mesh edges in one UiPathContext pass.
      ctx.reset();
      voronoi.render(ctx);
      canvas.drawPath(
        ctx.path,
        Paint()
          ..color = colorScheme.onSurface.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1 / sx,
      );
    }

    // 2. Delaunay triangulation mesh directly via UiPathContext.
    if (showDelaunay) {
      ctx.reset();
      delaunay.render(ctx);
      canvas.drawPath(
        ctx.path,
        Paint()
          ..color = colorScheme.primary.withValues(alpha: 0.42)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9 / sx,
      );
    }

    // 3. Convex hull directly via UiPathContext.
    if (showHull) {
      ctx.reset();
      delaunay.renderHull(ctx);
      canvas.drawPath(
        ctx.path,
        Paint()
          ..color = colorScheme.tertiary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2 / sx,
      );
    }

    // 4. Hovered cell outline + neighbor outlines.
    if (hoveredSite >= 0 && hoveredSite < n) {
      final neighborStroke = Paint()
        ..color = colorScheme.secondary.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8 / sx;
      for (final nb in voronoiNeighbors) {
        ctx.reset();
        voronoi.renderCell(nb, ctx);
        canvas.drawPath(ctx.path, neighborStroke);
      }

      ctx.reset();
      voronoi.renderCell(hoveredSite, ctx);
      canvas.drawPath(
        ctx.path,
        Paint()
          ..color = colorScheme.onSurface
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6 / sx,
      );
    }

    // 5. Optional circumcenters.
    if (showCircumcenters) {
      final cc = voronoi.circumcenters;
      final ccPaint = Paint()
        ..color = colorScheme.error.withValues(alpha: 0.72)
        ..style = PaintingStyle.fill;
      final r = 2.5 / sx;
      for (var i = 0; i < cc.length; i += 2) {
        final x = cc[i];
        final y = cc[i + 1];
        if (x >= 0 && x <= worldW && y >= 0 && y <= worldH) {
          canvas.drawCircle(Offset(x, y), r, ccPaint);
        }
      }
    }

    // 6. Input sites (all sites via UiPathContext, plus highlighted hover/neighbors).
    ctx.reset();
    delaunay.renderPoints(ctx, 2.5 / sx);
    canvas.drawPath(
      ctx.path,
      Paint()
        ..color = colorScheme.onSurface.withValues(alpha: 0.78)
        ..style = PaintingStyle.fill,
    );

    final pts = delaunay.points;
    if (hoveredSite >= 0 && hoveredSite < n) {
      final nbDot = Paint()..color = colorScheme.secondary;
      for (final nb in voronoiNeighbors) {
        canvas.drawCircle(
          Offset(pts[2 * nb], pts[2 * nb + 1]),
          4.2 / sx,
          nbDot,
        );
      }
      final hx = pts[2 * hoveredSite];
      final hy = pts[2 * hoveredSite + 1];
      canvas
        ..drawCircle(
          Offset(hx, hy),
          8.0 / sx,
          Paint()..color = colorScheme.primary.withValues(alpha: 0.25),
        )
        ..drawCircle(
          Offset(hx, hy),
          4.8 / sx,
          Paint()..color = colorScheme.primary,
        );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DelaunayPainter oldDelegate) => true;
}
