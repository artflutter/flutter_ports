// Original code, not ported from D3: flutter_d3_scale_chromatic_port demo.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_d3_color_port/flutter_d3_color_port.dart' as d3;
import 'package:flutter_d3_scale_chromatic_port/flutter_d3_scale_chromatic_port.dart'
    as d3;
import 'package:material_ui/material_ui.dart';

enum _VisionMode() {
  normal,
  grayscale,
  deuteranopia,
  protanopia,
}

enum _SchemeGroup() {
  categorical,
  diverging,
  sequentialSingle,
  sequentialMulti,
  cyclical,
}

/// Interactive showcase of `flutter_d3_scale_chromatic_port`: live animated
/// scalar heatmap with color-vision simulation and an interactive browser for
/// all 76 categorical, diverging, sequential, and cyclical color schemes.
class const ChromaticDemoPage({super.key}) extends StatefulWidget {
  /// Creates the `d3-scale-chromatic` demo page.
  this;

  @override
  State<ChromaticDemoPage> createState() => _ChromaticDemoPageState();
}

class _ChromaticDemoPageState()
    extends State<ChromaticDemoPage>
    with SingleTickerProviderStateMixin {
  static final _heatmapRamps = <(String, d3.Color Function(double t))>[
    ('Viridis', d3.interpolateViridis),
    ('Magma', d3.interpolateMagma),
    ('Inferno', d3.interpolateInferno),
    ('Plasma', d3.interpolatePlasma),
    ('Cividis', d3.interpolateCividis),
    ('Turbo', d3.interpolateTurbo),
    ('Cubehelix', d3.interpolateCubehelixDefault),
    ('Spectral', d3.interpolateSpectral),
    ('RdBu', d3.interpolateRdBu),
    ('YlGnBu', d3.interpolateYlGnBu),
    ('Blues', d3.interpolateBlues),
    ('Rainbow', d3.interpolateRainbow),
    ('Sinebow', d3.interpolateSinebow),
  ];

  static const _categoricalSchemes = <(String, List<d3.Rgb>)>[
    ('Category10', d3.schemeCategory10),
    ('Tableau10', d3.schemeTableau10),
    ('Observable10', d3.schemeObservable10),
    ('Accent', d3.schemeAccent),
    ('Dark2', d3.schemeDark2),
    ('Paired', d3.schemePaired),
    ('Pastel1', d3.schemePastel1),
    ('Pastel2', d3.schemePastel2),
    ('Set1', d3.schemeSet1),
    ('Set2', d3.schemeSet2),
    ('Set3', d3.schemeSet3),
  ];

  static final _divergingSchemes =
      <(String, List<List<d3.Rgb>?>, d3.Color Function(double))>[
        ('BrBG', d3.schemeBrBG, d3.interpolateBrBG),
        ('PRGn', d3.schemePRGn, d3.interpolatePRGn),
        ('PiYG', d3.schemePiYG, d3.interpolatePiYG),
        ('PuOr', d3.schemePuOr, d3.interpolatePuOr),
        ('RdBu', d3.schemeRdBu, d3.interpolateRdBu),
        ('RdGy', d3.schemeRdGy, d3.interpolateRdGy),
        ('RdYlBu', d3.schemeRdYlBu, d3.interpolateRdYlBu),
        ('RdYlGn', d3.schemeRdYlGn, d3.interpolateRdYlGn),
        ('Spectral', d3.schemeSpectral, d3.interpolateSpectral),
      ];

  static final _singleSchemes =
      <(String, List<List<d3.Rgb>?>, d3.Color Function(double))>[
        ('Blues', d3.schemeBlues, d3.interpolateBlues),
        ('Greens', d3.schemeGreens, d3.interpolateGreens),
        ('Greys', d3.schemeGreys, d3.interpolateGreys),
        ('Oranges', d3.schemeOranges, d3.interpolateOranges),
        ('Purples', d3.schemePurples, d3.interpolatePurples),
        ('Reds', d3.schemeReds, d3.interpolateReds),
      ];

  static final _multiColorBrewer =
      <(String, List<List<d3.Rgb>?>, d3.Color Function(double))>[
        ('BuGn', d3.schemeBuGn, d3.interpolateBuGn),
        ('BuPu', d3.schemeBuPu, d3.interpolateBuPu),
        ('GnBu', d3.schemeGnBu, d3.interpolateGnBu),
        ('OrRd', d3.schemeOrRd, d3.interpolateOrRd),
        ('PuBu', d3.schemePuBu, d3.interpolatePuBu),
        ('PuBuGn', d3.schemePuBuGn, d3.interpolatePuBuGn),
        ('PuRd', d3.schemePuRd, d3.interpolatePuRd),
        ('RdPu', d3.schemeRdPu, d3.interpolateRdPu),
        ('YlGn', d3.schemeYlGn, d3.interpolateYlGn),
        ('YlGnBu', d3.schemeYlGnBu, d3.interpolateYlGnBu),
        ('YlOrBr', d3.schemeYlOrBr, d3.interpolateYlOrBr),
        ('YlOrRd', d3.schemeYlOrRd, d3.interpolateYlOrRd),
      ];

  static final _multiContinuous = <(String, d3.Color Function(double))>[
    ('Viridis', d3.interpolateViridis),
    ('Magma', d3.interpolateMagma),
    ('Inferno', d3.interpolateInferno),
    ('Plasma', d3.interpolatePlasma),
    ('Cividis', d3.interpolateCividis),
    ('Turbo', d3.interpolateTurbo),
    ('CubehelixDefault', d3.interpolateCubehelixDefault),
    ('Warm', d3.interpolateWarm),
    ('Cool', d3.interpolateCool),
  ];

  static final _cyclicalSchemes = <(String, d3.Color Function(double))>[
    ('Rainbow', d3.interpolateRainbow),
    ('Sinebow', d3.interpolateSinebow),
  ];

  late final AnimationController _waveAnim = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  int _rampIndex = 0;
  _VisionMode _vision = _VisionMode.normal;
  _SchemeGroup _group = _SchemeGroup.categorical;
  int _brewerClasses = 7;
  Offset _hotspot = const Offset(0.55, 0.45);
  bool _animating = false;

  @override
  void dispose() {
    _waveAnim.dispose();
    super.dispose();
  }

  void _toggleAnimate() {
    setState(() {
      _animating = !_animating;
      if (_animating) {
        _waveAnim.repeat();
      } else {
        _waveAnim.stop();
      }
    });
  }

  void _copySwatch(d3.Rgb c) {
    final snippet =
        '${c.formatHex()}  // const Rgb(${c.r.round()}, ${c.g.round()}, '
        '${c.b.round()})';
    unawaited(Clipboard.setData(ClipboardData(text: snippet)));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied $snippet'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  ColorFilter _visionFilter() => switch (_vision) {
    _VisionMode.normal => const ColorFilter.mode(
      Colors.transparent,
      BlendMode.dst,
    ),
    _VisionMode.grayscale => const ColorFilter.matrix(<double>[
      0.2126, 0.7152, 0.0722, 0, 0, //
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0, 0, 0, 1, 0,
    ]),
    _VisionMode.deuteranopia => const ColorFilter.matrix(<double>[
      0.625, 0.375, 0, 0, 0, //
      0.7, 0.3, 0, 0, 0,
      0, 0.3, 0.7, 0, 0,
      0, 0, 0, 1, 0,
    ]),
    _VisionMode.protanopia => const ColorFilter.matrix(<double>[
      0.567, 0.433, 0, 0, 0, //
      0.558, 0.442, 0, 0, 0,
      0, 0.242, 0.758, 0, 0,
      0, 0, 0, 1, 0,
    ]),
  };

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
                  'Live Scalar Heatmap, Color-Vision Check & 76-Scheme Browser',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Viridis, Magma, Inferno and Plasma return shared const Rgb '
                  'values with zero allocation per call (~1.6 ns in AOT), and '
                  'all 38 palettes are compile-time const lists.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                _buildHeatmapCard(theme),
                const SizedBox(height: 16),
                _buildSchemeBrowserCard(theme),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeatmapCard(ThemeData theme) {
    final (rampName, rampFn) = _heatmapRamps[_rampIndex];
    return Card(
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
                  'Interactive Scalar Field — $rampName',
                  style: theme.textTheme.titleMedium,
                ),
                FilledButton.tonalIcon(
                  icon: Icon(_animating ? Icons.pause : Icons.play_arrow),
                  label: Text(_animating ? 'Pause waves' : 'Animate waves'),
                  onPressed: _toggleAnimate,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Drag on the heatmap to move the hotspot. Switch to Grayscale '
              'or Deuteranopia to compare Viridis/Cividis against Rainbow.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < _heatmapRamps.length; i++)
                  ChoiceChip(
                    label: Text(_heatmapRamps[i].$1),
                    selected: _rampIndex == i,
                    onSelected: (_) => setState(() => _rampIndex = i),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            SegmentedButton<_VisionMode>(
              segments: const [
                ButtonSegment(value: _VisionMode.normal, label: Text('Normal')),
                ButtonSegment(
                  value: _VisionMode.grayscale,
                  label: Text('Grayscale'),
                ),
                ButtonSegment(
                  value: _VisionMode.deuteranopia,
                  label: Text('Deuteranopia'),
                ),
                ButtonSegment(
                  value: _VisionMode.protanopia,
                  label: Text('Protanopia'),
                ),
              ],
              selected: {_vision},
              onSelectionChanged: (s) => setState(() => _vision = s.first),
            ),
            const SizedBox(height: 12),
            ColorFiltered(
              colorFilter: _visionFilter(),
              child: Column(
                children: [
                  SizedBox(
                    height: 220,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = Size(constraints.maxWidth, 220);
                        void move(Offset p) {
                          setState(() {
                            _hotspot = Offset(
                              (p.dx / size.width).clamp(0.0, 1.0),
                              (p.dy / size.height).clamp(0.0, 1.0),
                            );
                          });
                        }

                        return GestureDetector(
                          onPanDown: (d) => move(d.localPosition),
                          onPanUpdate: (d) => move(d.localPosition),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedBuilder(
                              animation: _waveAnim,
                              builder: (context, _) => CustomPaint(
                                size: size,
                                painter: _HeatmapPainter(
                                  ramp: rampFn,
                                  phase: _waveAnim.value * math.pi * 2,
                                  hotspot: _hotspot,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 18,
                      width: double.infinity,
                      child: CustomPaint(painter: _RampStripPainter(rampFn)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchemeBrowserCard(ThemeData theme) {
    final maxClasses = _group == _SchemeGroup.diverging ? 11 : 9;
    final k = _brewerClasses.clamp(3, maxClasses);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '76-Scheme Palette Explorer (tap any swatch to copy const Rgb)',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (g, label) in const [
                  (_SchemeGroup.categorical, 'Categorical (11)'),
                  (_SchemeGroup.diverging, 'Diverging (9)'),
                  (_SchemeGroup.sequentialSingle, 'Sequential Single (6)'),
                  (_SchemeGroup.sequentialMulti, 'Sequential Multi (21)'),
                  (_SchemeGroup.cyclical, 'Cyclical (2)'),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: _group == g,
                    onSelected: (_) => setState(() => _group = g),
                  ),
              ],
            ),
            if (_group == _SchemeGroup.diverging ||
                _group == _SchemeGroup.sequentialSingle ||
                _group == _SchemeGroup.sequentialMulti) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('ColorBrewer classes k = $k'),
                  Expanded(
                    child: Slider(
                      value: k.toDouble(),
                      min: 3,
                      max: maxClasses.toDouble(),
                      divisions: maxClasses - 3,
                      onChanged: (v) =>
                          setState(() => _brewerClasses = v.round()),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            ...switch (_group) {
              _SchemeGroup.categorical => [
                for (final (name, colors) in _categoricalSchemes)
                  _buildCategoricalRow(theme, name, colors),
              ],
              _SchemeGroup.diverging => [
                for (final (name, scheme, interp) in _divergingSchemes)
                  _buildBrewerRow(theme, name, scheme[k]!, interp),
              ],
              _SchemeGroup.sequentialSingle => [
                for (final (name, scheme, interp) in _singleSchemes)
                  _buildBrewerRow(theme, name, scheme[k]!, interp),
              ],
              _SchemeGroup.sequentialMulti => [
                for (final (name, interp) in _multiContinuous)
                  _buildContinuousRow(theme, name, interp),
                const Divider(height: 24),
                for (final (name, scheme, interp) in _multiColorBrewer)
                  _buildBrewerRow(theme, name, scheme[k]!, interp),
              ],
              _SchemeGroup.cyclical => [
                Wrap(
                  spacing: 24,
                  runSpacing: 20,
                  children: [
                    for (final (name, interp) in _cyclicalSchemes)
                      _buildCyclicWheelCard(theme, name, interp),
                  ],
                ),
              ],
            },
          ],
        ),
      ),
    );
  }

  Widget _buildCategoricalRow(
    ThemeData theme,
    String name,
    List<d3.Rgb> colors,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        SizedBox(
          width: 112,
          child: Text(name, style: theme.textTheme.labelMedium),
        ),
        Expanded(
          child: Row(
            children: [
              for (final c in colors)
                Expanded(
                  child: GestureDetector(
                    onTap: () => _copySwatch(c),
                    child: Tooltip(
                      message: c.formatHex(),
                      child: Container(
                        height: 30,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: c.toUiColor(),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildBrewerRow(
    ThemeData theme,
    String name,
    List<d3.Rgb> discrete,
    d3.Color Function(double) interp,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        SizedBox(
          width: 112,
          child: Text(name, style: theme.textTheme.labelMedium),
        ),
        Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  for (final c in discrete)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _copySwatch(c),
                        child: Tooltip(
                          message: c.formatHex(),
                          child: Container(
                            height: 22,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: c.toUiColor(),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 10,
                  width: double.infinity,
                  child: CustomPaint(painter: _RampStripPainter(interp)),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildContinuousRow(
    ThemeData theme,
    String name,
    d3.Color Function(double) interp,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        SizedBox(
          width: 132,
          child: Text(name, style: theme.textTheme.labelMedium),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 24,
              child: CustomPaint(painter: _RampStripPainter(interp)),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildCyclicWheelCard(
    ThemeData theme,
    String name,
    d3.Color Function(double) interp,
  ) => SizedBox(
    width: 240,
    child: Column(
      children: [
        Text('$name (wraps 0 ≡ 1)', style: theme.textTheme.titleSmall),
        const SizedBox(height: 10),
        SizedBox(
          width: 160,
          height: 160,
          child: CustomPaint(painter: _CyclicWheelPainter(interp)),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 16,
            width: 220,
            child: CustomPaint(painter: _RampStripPainter(interp)),
          ),
        ),
      ],
    ),
  );
}

class const _HeatmapPainter({
  required final d3.Color Function(double t) ramp,
  required final double phase,
  required final Offset hotspot,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cols = 64;
    const rows = 36;
    final cw = size.width / cols;
    final ch = size.height / rows;
    final paint = Paint();

    final hx = hotspot.dx;
    final hy = hotspot.dy;
    final sx = 0.25 + 0.12 * math.cos(phase);
    final sy = 0.65 + 0.14 * math.sin(phase);

    for (var r = 0; r < rows; r++) {
      final y = (r + 0.5) / rows;
      for (var c = 0; c < cols; c++) {
        final x = (c + 0.5) / cols;
        final d1 = (x - hx) * (x - hx) + (y - hy) * (y - hy);
        final d2 = (x - sx) * (x - sx) + (y - sy) * (y - sy);
        final wave =
            0.22 * math.sin(x * 7.5 + phase) * math.cos(y * 5.5 - phase * 0.7);
        final v =
            (math.exp(-d1 * 13) * 0.85 +
                    math.exp(-d2 * 10) * 0.65 +
                    0.22 +
                    wave)
                .clamp(0.0, 1.0);
        paint.color = ramp(v).toUiColor();
        canvas.drawRect(
          Rect.fromLTWH(c * cw, r * ch, cw + 0.6, ch + 0.6),
          paint,
        );
      }
    }

    final hp = Offset(hx * size.width, hy * size.height);
    canvas.drawCircle(
      hp,
      7,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_HeatmapPainter oldDelegate) =>
      oldDelegate.ramp != ramp ||
      oldDelegate.phase != phase ||
      oldDelegate.hotspot != hotspot;
}

class const _RampStripPainter(final d3.Color Function(double t) ramp)
    extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const steps = 128;
    final sw = size.width / steps;
    final paint = Paint();
    for (var i = 0; i < steps; i++) {
      paint.color = ramp(i / (steps - 1)).toUiColor();
      canvas.drawRect(Rect.fromLTWH(i * sw, 0, sw + 0.6, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_RampStripPainter oldDelegate) => oldDelegate.ramp != ramp;
}

class const _CyclicWheelPainter(final d3.Color Function(double t) ramp)
    extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const slices = 180;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const sweep = (math.pi * 2) / slices;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.44;
    final ringRect = Rect.fromCircle(center: center, radius: radius * 0.72);
    for (var i = 0; i < slices; i++) {
      paint.color = ramp(i / slices).toUiColor();
      canvas.drawArc(
        ringRect,
        -math.pi / 2 + i * sweep,
        sweep + 0.015,
        false,
        paint,
      );
    }
    canvas.drawOval(
      rect.deflate(2),
      Paint()
        ..color = const Color(0x22000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_CyclicWheelPainter oldDelegate) =>
      oldDelegate.ramp != ramp;
}
