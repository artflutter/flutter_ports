// Original code, not ported from D3: flutter_d3_interpolate_port demo.

import 'dart:math' as math;

import 'package:flutter_d3_color_port/flutter_d3_color_port.dart' as d3;
import 'package:flutter_d3_interpolate_port/flutter_d3_interpolate_port.dart'
    as d3;
import 'package:material_ui/material_ui.dart';

/// Interactive showcase of `flutter_d3_interpolate_port`: smooth van Wijk &
/// Nuij camera flight (`interpolateZoom`), perceptual color space gradient
/// showdown, `quantize`, and 2D affine `interpolateTransform` with skew.
class const InterpolateDemoPage({super.key}) extends StatefulWidget {
  /// Creates the `d3-interpolate` demo page.
  this;

  @override
  State<InterpolateDemoPage> createState() => _InterpolateDemoPageState();
}

class _InterpolateDemoPageState()
    extends State<InterpolateDemoPage>
    with TickerProviderStateMixin {
  // --- 1. interpolateZoom state ---
  static const _landmarks = <(String, d3.ZoomView, Color)>[
    ('Overview', (500, 500, 960), Color(0xFF6366F1)),
    ('Orion Core', (185, 220, 140), Color(0xFFEC4899)),
    ('Cygnus Ring', (810, 240, 170), Color(0xFF06B6D4)),
    ('Lyra Micro', (760, 770, 85), Color(0xFFF59E0B)),
    ('Vela Deep', (215, 760, 110), Color(0xFF10B981)),
    ('Center Hub', (500, 500, 210), Color(0xFF8B5CF6)),
  ];

  late final List<(double, double, double, Color)> _stars = _generateStars();
  late final AnimationController _zoomAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..addListener(_onZoomTick);

  d3.ZoomView _currentView = _landmarks[0].$2;
  d3.ZoomView Function(double t)? _activeFlight;
  int _selectedLandmark = 0;
  bool _useD3Zoom = true;
  double _rho = math.sqrt2;
  double _lastDurationMs = 0;

  // --- 2. Color interpolation state ---
  static const _colorPairs = <(String, d3.Rgb, d3.Rgb)>[
    ('Red → Green', d3.Rgb(239, 68, 68), d3.Rgb(34, 197, 94)),
    ('Blue → Yellow', d3.Rgb(37, 99, 235), d3.Rgb(250, 204, 21)),
    ('Gray → Steelblue', d3.Rgb(128, 128, 128), d3.Rgb(70, 130, 180)),
    ('Purple → Orange', d3.Rgb(126, 34, 206), d3.Rgb(249, 115, 22)),
    ('Teal → Coral', d3.Rgb(13, 148, 136), d3.Rgb(255, 111, 97)),
  ];

  int _pairIndex = 0;
  double _gamma = 2.2;
  int _quantizeCount = 9;

  // --- 3. interpolateTransform state ---
  late final AnimationController _transformAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..addListener(() => setState(() => _transformT = _transformAnim.value));

  double _transformT = 0.5;
  double _endRotate = 10;
  double _endSkewX = 24;
  double _endScale = 1.25;

  static List<(double, double, double, Color)> _generateStars() {
    final rng = math.Random(42);
    const palette = [
      Color(0xFF94A3B8),
      Color(0xFF60A5FA),
      Color(0xFFF472B6),
      Color(0xFF34D399),
      Color(0xFFFBBF24),
    ];
    return [
      for (var i = 0; i < 200; i++)
        (
          40 + rng.nextDouble() * 920,
          40 + rng.nextDouble() * 920,
          2 + rng.nextDouble() * 5,
          palette[rng.nextInt(palette.length)],
        ),
    ];
  }

  @override
  void dispose() {
    _zoomAnim.dispose();
    _transformAnim.dispose();
    super.dispose();
  }

  void _onZoomTick() {
    final flight = _activeFlight;
    if (flight == null) return;
    setState(() {
      _currentView = flight(_zoomAnim.value);
    });
  }

  void _flyTo(int index) {
    final target = _landmarks[index].$2;
    final from = _currentView;
    if (_useD3Zoom) {
      final zoom = d3.interpolateZoom.rho(_rho)(from, target);
      _activeFlight = zoom.call;
      _lastDurationMs = zoom.duration;
      _zoomAnim.duration = Duration(
        milliseconds: zoom.duration.round().clamp(350, 3200),
      );
    } else {
      final ix = d3.interpolateNumber(from.$1, target.$1);
      final iy = d3.interpolateNumber(from.$2, target.$2);
      final iw = d3.interpolateNumber(from.$3, target.$3);
      _activeFlight = (t) => (ix(t), iy(t), iw(t));
      _lastDurationMs = 900;
      _zoomAnim.duration = const Duration(milliseconds: 900);
    }
    setState(() => _selectedLandmark = index);
    _zoomAnim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Smooth Pan-and-Zoom, Perceptual Blending & 2D Transforms',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Explore van Wijk & Nuij zoom flights, perceptual color '
                  'interpolation (Lab, HCL, Cubehelix, B-splines), and 2D '
                  'affine transform decomposition with skew.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                _buildZoomCard(theme),
                const SizedBox(height: 16),
                _buildColorShowdownCard(theme),
                const SizedBox(height: 16),
                _buildTransformCard(theme),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildZoomCard(ThemeData theme) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                'Smooth Camera Flight (interpolateZoom)',
                style: theme.textTheme.titleMedium,
              ),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('D3 interpolateZoom')),
                  ButtonSegment(
                    value: false,
                    label: Text('Linear (Matrix4Tween)'),
                  ),
                ],
                selected: {_useD3Zoom},
                onSelectionChanged: (s) => setState(() => _useD3Zoom = s.first),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Tap distant clusters (for example Orion Core → Lyra Micro). '
            'D3 zooms out while panning and zooms back in automatically.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _landmarks.length; i++)
                ChoiceChip(
                  label: Text(_landmarks[i].$1),
                  selected: _selectedLandmark == i,
                  onSelected: (_) => _flyTo(i),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 250,
              width: double.infinity,
              child: CustomPaint(
                painter: _ZoomMapPainter(
                  view: _currentView,
                  stars: _stars,
                  landmarks: _landmarks,
                  selectedLandmark: _selectedLandmark,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Curvature ρ = ${_rho.toStringAsFixed(2)}',
                style: theme.textTheme.labelMedium,
              ),
              Expanded(
                child: Slider(
                  value: _rho,
                  min: 0.6,
                  max: 2.8,
                  onChanged: _useD3Zoom
                      ? (v) => setState(() => _rho = v)
                      : null,
                ),
              ),
              Text(
                'view: (${_currentView.$1.toStringAsFixed(0)}, '
                '${_currentView.$2.toStringAsFixed(0)}, '
                'w:${_currentView.$3.toStringAsFixed(0)})'
                '${_lastDurationMs > 0 ? ' · ' : ''}'
                '${_lastDurationMs > 0 ? '${_lastDurationMs.round()} ms' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildColorShowdownCard(ThemeData theme) {
    final (_, start, end) = _colorPairs[_pairIndex];
    final startUi = start.toUiColor();
    final endUi = end.toUiColor();

    final hclInterp = d3.interpolateHcl(start, end);
    final rows = <(String, Color Function(double t))>[
      ('Flutter Color.lerp (sRGB)', (t) => Color.lerp(startUi, endUi, t)!),
      (
        'interpolateRgb.gamma(${_gamma.toStringAsFixed(1)})',
        (t) => d3.interpolateRgb.gamma(_gamma)(start, end)(t).toUiColor(),
      ),
      ('interpolateHsl', (t) => d3.interpolateHsl(start, end)(t).toUiColor()),
      (
        'interpolateHslLong',
        (t) => d3.interpolateHslLong(start, end)(t).toUiColor(),
      ),
      ('interpolateLab', (t) => d3.interpolateLab(start, end)(t).toUiColor()),
      ('interpolateHcl', (t) => hclInterp(t).toUiColor()),
      (
        'interpolateHclLong',
        (t) => d3.interpolateHclLong(start, end)(t).toUiColor(),
      ),
      (
        'interpolateCubehelix.gamma(${_gamma.toStringAsFixed(1)})',
        (t) => d3.interpolateCubehelix.gamma(_gamma)(start, end)(t).toUiColor(),
      ),
      (
        'interpolateRgbBasis (4-stop B-spline)',
        (t) => d3.interpolateRgbBasis([
          start,
          const d3.Rgb(250, 204, 21),
          const d3.Rgb(56, 189, 248),
          end,
        ])(t).toUiColor(),
      ),
    ];

    final quantized = d3.quantize(hclInterp, _quantizeCount);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Color Space Interpolation Showdown',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _colorPairs.length; i++)
                  ChoiceChip(
                    label: Text(_colorPairs[i].$1),
                    selected: _pairIndex == i,
                    onSelected: (_) => setState(() => _pairIndex = i),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Gamma: ${_gamma.toStringAsFixed(1)}'),
                Expanded(
                  child: Slider(
                    value: _gamma,
                    min: 0.5,
                    max: 4,
                    onChanged: (v) => setState(() => _gamma = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final (label, sample) in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 210,
                      child: Text(label, style: theme.textTheme.labelMedium),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 26,
                          child: CustomPaint(
                            painter: _GradientBarPainter(sample),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 24),
            Row(
              children: [
                Text(
                  'quantize(interpolateHcl, $_quantizeCount)',
                  style: theme.textTheme.labelMedium,
                ),
                Expanded(
                  child: Slider(
                    value: _quantizeCount.toDouble(),
                    min: 3,
                    max: 16,
                    divisions: 13,
                    onChanged: (v) =>
                        setState(() => _quantizeCount = v.round()),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                for (final c in quantized)
                  Expanded(
                    child: Container(
                      height: 30,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: c.toUiColor(),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransformCard(ThemeData theme) {
    const startParts = d3.TransformParts(-90, -10, 350, -12, 0.85, 0.85);
    final endParts = d3.TransformParts(
      90,
      10,
      _endRotate,
      _endSkewX,
      _endScale,
      _endScale,
    );
    final current = d3.interpolateTransform(startParts, endParts)(_transformT);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '2D Transform & Skew Animator (interpolateTransform)',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                FilledButton.tonalIcon(
                  icon: Icon(
                    _transformAnim.isAnimating ? Icons.pause : Icons.play_arrow,
                  ),
                  label: Text(_transformAnim.isAnimating ? 'Pause' : 'Play'),
                  onPressed: () {
                    if (_transformAnim.isAnimating) {
                      _transformAnim.stop();
                    } else {
                      _transformAnim.repeat(reverse: true);
                    }
                    setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Start angle is 350° and end is ${_endRotate.round()}° — '
              'interpolateTransform takes the shortest angular path and '
              'preserves 2D skewX cleanly into Matrix4 via .toMatrix4().',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 180,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Transform(
                alignment: Alignment.center,
                transform: current.toMatrix4(),
                child: Container(
                  width: 110,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6D28D9), Color(0xFF06B6D4)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'D3 2D',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('t = ${_transformT.toStringAsFixed(2)}'),
                Expanded(
                  child: Slider(
                    value: _transformT,
                    onChanged: (v) {
                      _transformAnim.stop();
                      setState(() => _transformT = v);
                    },
                  ),
                ),
                Text(
                  'rot ${current.rotate.toStringAsFixed(1)}° · '
                  'skewX ${current.skewX.toStringAsFixed(1)}° · '
                  'scale ${current.scaleX.toStringAsFixed(2)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 16,
              children: [
                SizedBox(
                  width: 240,
                  child: Row(
                    children: [
                      const Text('End rot'),
                      Expanded(
                        child: Slider(
                          value: _endRotate,
                          min: -180,
                          max: 180,
                          onChanged: (v) => setState(() => _endRotate = v),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: Row(
                    children: [
                      const Text('End skewX'),
                      Expanded(
                        child: Slider(
                          value: _endSkewX,
                          min: -45,
                          max: 45,
                          onChanged: (v) => setState(() => _endSkewX = v),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: Row(
                    children: [
                      const Text('End scale'),
                      Expanded(
                        child: Slider(
                          value: _endScale,
                          min: 0.4,
                          max: 1.8,
                          onChanged: (v) => setState(() => _endScale = v),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class const _ZoomMapPainter({
  required final d3.ZoomView view,
  required final List<(double, double, double, Color)> stars,
  required final List<(String, d3.ZoomView, Color)> landmarks,
  required final int selectedLandmark,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0F172A),
    );
    final (cx, cy, w) = view;
    final k = math.min(size.width, size.height) / w;

    Offset project(double x, double y) =>
        Offset(size.width / 2 + (x - cx) * k, size.height / 2 + (y - cy) * k);

    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1;
    for (var g = 0.0; g <= 1000; g += 100) {
      canvas
        ..drawLine(project(g, 0), project(g, 1000), gridPaint)
        ..drawLine(project(0, g), project(1000, g), gridPaint);
    }

    final starPaint = Paint();
    for (final (x, y, r, color) in stars) {
      final p = project(x, y);
      if (p.dx < -10 ||
          p.dx > size.width + 10 ||
          p.dy < -10 ||
          p.dy > size.height + 10) {
        continue;
      }
      starPaint.color = color.withValues(alpha: 0.72);
      canvas.drawCircle(p, (r * k).clamp(1.2, 12.0), starPaint);
    }

    for (var i = 1; i < landmarks.length; i++) {
      final (name, (lx, ly, lw), color) = landmarks[i];
      final p = project(lx, ly);
      final radius = (lw * 0.34 * k).clamp(8.0, 220.0);
      canvas
        ..drawCircle(
          p,
          radius,
          Paint()
            ..color = color.withValues(alpha: 0.14)
            ..style = PaintingStyle.fill,
        )
        ..drawCircle(
          p,
          radius,
          Paint()
            ..color = color.withValues(
              alpha: i == selectedLandmark ? 0.95 : 0.6,
            )
            ..style = PaintingStyle.stroke
            ..strokeWidth = i == selectedLandmark ? 2.2 : 1.2,
        );
      final tp = TextPainter(
        text: TextSpan(
          text: name,
          style: const TextStyle(
            color: Color(0xFFF8FAFC),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(p.dx - tp.width / 2, p.dy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_ZoomMapPainter oldDelegate) =>
      oldDelegate.view != view ||
      oldDelegate.selectedLandmark != selectedLandmark;
}

class const _GradientBarPainter(final Color Function(double t) sample)
    extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const steps = 128;
    final sw = size.width / steps;
    final paint = Paint();
    for (var i = 0; i < steps; i++) {
      paint.color = sample(i / (steps - 1));
      canvas.drawRect(Rect.fromLTWH(i * sw, 0, sw + 0.6, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_GradientBarPainter oldDelegate) => true;
}
