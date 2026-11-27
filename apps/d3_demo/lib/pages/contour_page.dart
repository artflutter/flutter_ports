// Original code, not ported from D3: flutter_d3_contour_port interactive demo.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_contour_port/flutter_d3_contour_port.dart' as d3;
import 'package:flutter_d3_scale_chromatic_port/flutter_d3_scale_chromatic_port.dart'
    as chromatic;
import 'package:material_ui/material_ui.dart';

enum _ContourMode(final String label) {
  scalar('Scalar Field Contours'),
  density('2D Kernel Density'),
}

enum _TerrainPreset(final String label) {
  volcano('Volcano & Caldera'),
  twinPeaks('Twin Peaks'),
  saddle('Saddle Waves'),
}

enum _ContourPalette(final String label) {
  viridis('Viridis'),
  turbo('Turbo'),
  magma('Magma'),
  plasma('Plasma'),
  ylGnBu('YlGnBu'),
  spectral('Spectral');

  Color sample(double t) {
    final c = t.clamp(0.0, 1.0);
    final rgb = switch (this) {
      _ContourPalette.viridis => chromatic.interpolateViridis(c).rgb(),
      _ContourPalette.turbo => chromatic.interpolateTurbo(c).rgb(),
      _ContourPalette.magma => chromatic.interpolateMagma(c).rgb(),
      _ContourPalette.plasma => chromatic.interpolatePlasma(c).rgb(),
      _ContourPalette.ylGnBu => chromatic.interpolateYlGnBu(c).rgb(),
      _ContourPalette.spectral => chromatic.interpolateSpectral(1.0 - c).rgb(),
    };
    return Color.fromARGB(
      255,
      rgb.r.round().clamp(0, 255),
      rgb.g.round().clamp(0, 255),
      rgb.b.round().clamp(0, 255),
    );
  }
}

/// Interactive showcase of `flutter_d3_contour_port`: live switcher between
/// **Scalar Field Contours** over synthetic topographic peaks/volcano grids
/// (with `smooth` toggle and threshold-count slider) and **2D Kernel Density**
/// (`contourDensity`) over seeded multi-cluster scatter points (with live
/// `bandwidth`, `cellSize`, and `thresholds` sliders), rendered directly to
/// Flutter `Canvas` with `flutter_d3_scale_chromatic_port` palettes.
class const ContourDemoPage({super.key}) extends StatefulWidget {
  /// Creates the `d3-contour` demo page.
  this;

  @override
  State<ContourDemoPage> createState() => _ContourDemoPageState();
}

class _ContourDemoPageState() extends State<ContourDemoPage> {
  static const int _gridW = 64;
  static const int _gridH = 44;
  static const double _densityW = 480;
  static const double _densityH = 300;
  static const List<int> _cellSizes = <int>[2, 4, 8, 16];

  _ContourMode _mode = _ContourMode.scalar;
  _TerrainPreset _terrain = _TerrainPreset.volcano;
  _ContourPalette _palette = _ContourPalette.viridis;

  // Scalar field controls.
  bool _smooth = true;
  int _scalarThresholds = 12;
  bool _showIsolines = true;

  // 2D kernel density controls.
  double _bandwidth = 22;
  int _cellSizeIndex = 1; // 4
  int _densityThresholds = 12;
  bool _showPoints = true;
  int _clusterSeed = 7;

  late Float64List _scalarGrid = _generateTerrain(_terrain);
  late List<(double, double)> _points = _generateClusters(_clusterSeed);

  static Float64List _generateTerrain(_TerrainPreset preset) {
    final out = Float64List(_gridW * _gridH);
    for (var y = 0; y < _gridH; ++y) {
      final ny = y / (_gridH - 1);
      for (var x = 0; x < _gridW; ++x) {
        final nx = x / (_gridW - 1);
        final double v;
        switch (preset) {
          case _TerrainPreset.volcano:
            final dx1 = (nx - 0.52) / 0.25;
            final dy1 = (ny - 0.52) / 0.27;
            final dxC = (nx - 0.51) / 0.085;
            final dyC = (ny - 0.50) / 0.095;
            final dx2 = (nx - 0.24) / 0.16;
            final dy2 = (ny - 0.34) / 0.17;
            v =
                185.0 * math.exp(-(dx1 * dx1 + dy1 * dy1)) -
                105.0 * math.exp(-(dxC * dxC + dyC * dyC)) +
                110.0 * math.exp(-(dx2 * dx2 + dy2 * dy2)) +
                12.0 * math.sin(nx * 10.0) * math.cos(ny * 8.0) +
                25.0;
          case _TerrainPreset.twinPeaks:
            final dx1 = (nx - 0.31) / 0.17;
            final dy1 = (ny - 0.44) / 0.20;
            final dx2 = (nx - 0.70) / 0.19;
            final dy2 = (ny - 0.56) / 0.21;
            final dx3 = (nx - 0.50) / 0.32;
            final dy3 = (ny - 0.50) / 0.30;
            v =
                150.0 * math.exp(-(dx1 * dx1 + dy1 * dy1)) +
                165.0 * math.exp(-(dx2 * dx2 + dy2 * dy2)) +
                35.0 * math.exp(-(dx3 * dx3 + dy3 * dy3));
          case _TerrainPreset.saddle:
            final sx = (nx - 0.5) * 4.4;
            final sy = (ny - 0.5) * 3.4;
            v =
                60.0 +
                32.0 * math.sin(sx + sy) * math.cos(sx - sy) +
                24.0 * math.exp(-(sx * sx + sy * sy) * 0.28);
        }
        out[y * _gridW + x] = v;
      }
    }
    return out;
  }

  static List<(double, double)> _generateClusters(int seed) {
    final rng = math.Random(seed * 9973 + 41);
    double gaussian() {
      final u1 = math.max(1e-9, rng.nextDouble());
      final u2 = rng.nextDouble();
      return math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2);
    }

    const clusters = <(double, double, double, double, int)>[
      (135, 118, 34, 28, 150),
      (332, 185, 42, 34, 170),
      (255, 86, 26, 22, 100),
    ];
    final out = <(double, double)>[];
    for (final (cx, cy, sx, sy, count) in clusters) {
      for (var i = 0; i < count; ++i) {
        final px = (cx + gaussian() * sx).clamp(16.0, _densityW - 16.0);
        final py = (cy + gaussian() * sy).clamp(16.0, _densityH - 16.0);
        out.add((px, py));
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final sw = Stopwatch()..start();
    final List<d3.ContourMultiPolygon> computedContours;
    var peakDensity = 0.0;
    final cellSize = _cellSizes[_cellSizeIndex];

    if (_mode == _ContourMode.scalar) {
      computedContours = d3.contours(
        size: (_gridW, _gridH),
        smooth: _smooth,
        thresholdsCount: _scalarThresholds,
      )(_scalarGrid);
    } else {
      final estimator = d3.contourDensityPoints(
        size: (_densityW, _densityH),
        bandwidth: _bandwidth,
        cellSize: cellSize,
        thresholdsCount: _densityThresholds,
      );
      computedContours = estimator(_points);
      peakDensity = estimator.contours(_points).max;
    }
    sw.stop();

    final elapsedUs = sw.elapsedMicroseconds;
    final elapsedLabel = elapsedUs >= 1000
        ? '${(elapsedUs / 1000).toStringAsFixed(2)} ms'
        : '$elapsedUs µs';

    var polygonCount = 0;
    var holeCount = 0;
    var vertexCount = 0;
    for (final mp in computedContours) {
      polygonCount += mp.coordinates.length;
      for (final poly in mp.coordinates) {
        if (poly.length > 1) holeCount += poly.length - 1;
        for (final ring in poly) {
          vertexCount += ring.length;
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Marching-Squares Contours & 2D Kernel Density',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pure Dart, fully statically typed port of d3-contour '
          'v${d3.d3ContourVersion}: zero dynamic, zero JS runtime — flat-array '
          'marching squares, smoothLinear interpolation, hole assignment, and '
          'blur2-backed 2D kernel density rendered directly to Flutter Canvas.',
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
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SegmentedButton<_ContourMode>(
                      segments: [
                        for (final m in _ContourMode.values)
                          ButtonSegment<_ContourMode>(
                            value: m,
                            label: Text(m.label),
                          ),
                      ],
                      selected: <_ContourMode>{_mode},
                      onSelectionChanged: (s) =>
                          setState(() => _mode = s.first),
                    ),
                    if (_mode == _ContourMode.density)
                      FilledButton.tonalIcon(
                        onPressed: () {
                          setState(() {
                            _clusterSeed += 1;
                            _points = _generateClusters(_clusterSeed);
                          });
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Resample'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Palette picker (d3-scale-chromatic).
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final pal in _ContourPalette.values)
                      ChoiceChip(
                        label: Text(pal.label),
                        selected: _palette == pal,
                        onSelected: (_) => setState(() => _palette = pal),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_mode == _ContourMode.scalar) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final preset in _TerrainPreset.values)
                        FilterChip(
                          label: Text(preset.label),
                          selected: _terrain == preset,
                          onSelected: (_) => setState(() {
                            _terrain = preset;
                            _scalarGrid = _generateTerrain(preset);
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                        width: 140,
                        child: Text('Thresholds: $_scalarThresholds'),
                      ),
                      Expanded(
                        child: Slider(
                          value: _scalarThresholds.toDouble(),
                          min: 4,
                          max: 24,
                          divisions: 20,
                          label: '$_scalarThresholds',
                          onChanged: (v) =>
                              setState(() => _scalarThresholds = v.round()),
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 20,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('smoothLinear'),
                          const SizedBox(width: 8),
                          Switch(
                            value: _smooth,
                            onChanged: (v) => setState(() => _smooth = v),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Isoline strokes'),
                          const SizedBox(width: 8),
                          Switch(
                            value: _showIsolines,
                            onChanged: (v) => setState(() => _showIsolines = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      SizedBox(
                        width: 140,
                        child: Text('Bandwidth: ${_bandwidth.round()}'),
                      ),
                      Expanded(
                        child: Slider(
                          value: _bandwidth,
                          min: 6,
                          max: 48,
                          divisions: 42,
                          label: '${_bandwidth.round()}',
                          onChanged: (v) => setState(() => _bandwidth = v),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 140,
                        child: Text('Cell size: $cellSize px'),
                      ),
                      Expanded(
                        child: Slider(
                          value: _cellSizeIndex.toDouble(),
                          max: (_cellSizes.length - 1).toDouble(),
                          divisions: _cellSizes.length - 1,
                          label: '$cellSize',
                          onChanged: (v) =>
                              setState(() => _cellSizeIndex = v.round()),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 140,
                        child: Text('Thresholds: $_densityThresholds'),
                      ),
                      Expanded(
                        child: Slider(
                          value: _densityThresholds.toDouble(),
                          min: 4,
                          max: 24,
                          divisions: 20,
                          label: '$_densityThresholds',
                          onChanged: (v) =>
                              setState(() => _densityThresholds = v.round()),
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 20,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Scatter points'),
                          const SizedBox(width: 8),
                          Switch(
                            value: _showPoints,
                            onChanged: (v) => setState(() => _showPoints = v),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Isoline strokes'),
                          const SizedBox(width: 8),
                          Switch(
                            value: _showIsolines,
                            onChanged: (v) => setState(() => _showIsolines = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 360,
                    width: double.infinity,
                    color: _palette.sample(0),
                    child: CustomPaint(
                      painter: _ContourCanvasPainter(
                        contours: computedContours,
                        domainW: _mode == _ContourMode.scalar
                            ? _gridW.toDouble()
                            : _densityW,
                        domainH: _mode == _ContourMode.scalar
                            ? _gridH.toDouble()
                            : _densityH,
                        palette: _palette,
                        showIsolines: _showIsolines,
                        points: _mode == _ContourMode.density && _showPoints
                            ? _points
                            : const <(double, double)>[],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _StatChip('Levels', '${computedContours.length}', cs),
                    _StatChip('Polygons', '$polygonCount', cs),
                    _StatChip('Holes', '$holeCount', cs),
                    _StatChip('Vertices', '$vertexCount', cs),
                    if (_mode == _ContourMode.density)
                      _StatChip(
                        'Peak density',
                        peakDensity.toStringAsExponential(2),
                        cs,
                      ),
                    _StatChip('Compute', elapsedLabel, cs),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class const _StatChip(
  final String label,
  final String value,
  final ColorScheme cs,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ContourCanvasPainter({
  required final List<d3.ContourMultiPolygon> contours,
  required final double domainW,
  required final double domainH,
  required final _ContourPalette palette,
  required final bool showIsolines,
  required final List<(double, double)> points,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final sx = size.width / domainW;
    final sy = size.height / domainH;
    final count = contours.length;

    final fillPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85
      ..color = Colors.black.withValues(alpha: 0.24);

    for (var idx = 0; idx < count; ++idx) {
      final mp = contours[idx];
      if (mp.coordinates.isEmpty) continue;
      final t = count <= 1 ? 1.0 : (idx + 1) / count;
      fillPaint.color = palette.sample(t);

      final path = Path()..fillType = PathFillType.evenOdd;
      for (final poly in mp.coordinates) {
        for (final ring in poly) {
          if (ring.isEmpty) continue;
          path.moveTo(ring[0].$1 * sx, ring[0].$2 * sy);
          for (var i = 1; i < ring.length; ++i) {
            path.lineTo(ring[i].$1 * sx, ring[i].$2 * sy);
          }
          path.close();
        }
      }
      canvas.drawPath(path, fillPaint);
      if (showIsolines) {
        canvas.drawPath(path, strokePaint);
      }
    }

    if (points.isNotEmpty) {
      final dotBg = Paint()..color = Colors.black.withValues(alpha: 0.45);
      final dotFg = Paint()..color = Colors.white.withValues(alpha: 0.88);
      for (final (px, py) in points) {
        final center = Offset(px * sx, py * sy);
        canvas
          ..drawCircle(center, 2.4, dotBg)
          ..drawCircle(center, 1.5, dotFg);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ContourCanvasPainter oldDelegate) =>
      oldDelegate.contours != contours ||
      oldDelegate.palette != palette ||
      oldDelegate.showIsolines != showIsolines ||
      oldDelegate.points != points;
}
