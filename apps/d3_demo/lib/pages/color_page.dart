// Original code, not ported from D3: flutter_d3_color_port interactive demo.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_d3_color_port/flutter_d3_color_port.dart' as d3;
import 'package:material_ui/material_ui.dart';

/// Interactive showcase of `flutter_d3_color_port`: CSS Color 3/4 parsing,
/// CIELCh (`Hcl`) gamut slicing, `.copyWith(...)` sliders, and perceptual
/// `brighter`/`darker` ladders.
class const ColorDemoPage({super.key}) extends StatefulWidget {
  /// Creates the `d3-color` demo page.
  this;

  @override
  State<ColorDemoPage> createState() => _ColorDemoPageState();
}

class _ColorDemoPageState() extends State<ColorDemoPage> {
  static const _presets = <String>[
    'steelblue',
    'rebeccapurple',
    'tomato',
    '#f0a',
    'rgba(12%, 34%, 56%, 0.7)',
    'hsla(48, 95%, 52%, 1)',
    'mediumseagreen',
    'gold',
  ];

  final TextEditingController _input = TextEditingController(text: 'steelblue');
  d3.Hcl _hcl = d3.Hcl.parse('steelblue');
  String? _parseError;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _parseInput(String text) {
    final parsed = d3.color(text);
    if (parsed == null) {
      setState(() => _parseError = 'Not a valid CSS Color 3/4 specifier');
      return;
    }
    final hcl = d3.Hcl.from(parsed);
    setState(() {
      _parseError = null;
      _hcl = d3.Hcl(
        hcl.h.isNaN ? 0 : hcl.h,
        hcl.c.isNaN ? 0 : hcl.c,
        hcl.l.isNaN ? 50 : hcl.l,
        hcl.opacity.isNaN ? 1 : hcl.opacity,
      );
    });
  }

  void _updateHcl(d3.Hcl next) {
    setState(() {
      _hcl = next;
      _parseError = null;
      _input.text = next.formatHex();
    });
  }

  void _copyText(String label, String value) {
    unawaited(Clipboard.setData(ClipboardData(text: value)));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied $label: $value'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rgb = _hcl.rgb();
    final hsl = d3.Hsl.from(_hcl);
    final lab = d3.Lab.from(_hcl);
    final cube = d3.Cubehelix.from(_hcl);
    final inGamut = _hcl.displayable();
    final uiColor = _hcl.toUiColor();

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
                  'CSS Color Parser, 5 Color Spaces & CIELCh Gamut Slicer',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Parse any CSS Color 3/4 text, inspect Lab / HCL / Cubehelix '
                  'channels, edit with immutable .copyWith(...), and explore '
                  'the real sRGB gamut boundary via displayable().',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                _buildInspectorCard(
                  theme,
                  uiColor: uiColor,
                  inGamut: inGamut,
                  rgb: rgb,
                  hsl: hsl,
                  lab: lab,
                  cube: cube,
                ),
                const SizedBox(height: 16),
                _buildGamutSlicerCard(theme),
                const SizedBox(height: 16),
                _buildPerceptualLadderCard(theme, rgb: rgb, hsl: hsl, lab: lab),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInspectorCard(
    ThemeData theme, {
    required Color uiColor,
    required bool inGamut,
    required d3.Rgb rgb,
    required d3.Hsl hsl,
    required d3.Lab lab,
    required d3.Cubehelix cube,
  }) {
    String fmt(double v) => v.isNaN ? 'NaN' : v.toStringAsFixed(2);
    final h = _hcl.h.isNaN ? 0.0 : _hcl.h.clamp(0.0, 360.0);
    final c = _hcl.c.isNaN ? 0.0 : _hcl.c.clamp(0.0, 140.0);
    final l = _hcl.l.isNaN ? 50.0 : _hcl.l.clamp(0.0, 100.0);
    final a = _hcl.opacity.isNaN ? 1.0 : _hcl.opacity.clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 84,
                  height: 84,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CustomPaint(painter: _CheckerColorPainter(uiColor)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _input,
                        decoration: InputDecoration(
                          labelText: 'CSS color input (d3.color)',
                          hintText: 'steelblue, #f0a, rgba(12%, 34%, 56%, 0.4)',
                          errorText: _parseError,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: _parseInput,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Chip(
                            avatar: Icon(
                              inGamut
                                  ? Icons.check_circle_outline
                                  : Icons.warning_amber_rounded,
                              size: 18,
                            ),
                            label: Text(
                              inGamut
                                  ? 'In sRGB gamut'
                                  : 'Out of sRGB gamut (clamped on screen)',
                            ),
                          ),
                          for (final preset in _presets)
                            ActionChip(
                              label: Text(preset),
                              onPressed: () {
                                _input.text = preset;
                                _parseInput(preset);
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _copyChip('formatHex', _hcl.formatHex()),
                _copyChip('formatHex8', _hcl.formatHex8()),
                _copyChip('formatRgb', _hcl.formatRgb()),
                _copyChip('formatHsl', _hcl.formatHsl()),
              ],
            ),
            const Divider(height: 28),
            Text(
              'HCL channels (immutable .copyWith)',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _sliderRow(
              label: 'Hue (h)',
              valueText: '${h.toStringAsFixed(1)}°',
              value: h,
              max: 360,
              onChanged: (v) => _updateHcl(_hcl.copyWith(h: v)),
            ),
            _sliderRow(
              label: 'Chroma (c)',
              valueText: c.toStringAsFixed(1),
              value: c,
              max: 140,
              onChanged: (v) => _updateHcl(_hcl.copyWith(c: v)),
            ),
            _sliderRow(
              label: 'Lightness (l)',
              valueText: l.toStringAsFixed(1),
              value: l,
              max: 100,
              onChanged: (v) => _updateHcl(_hcl.copyWith(l: v)),
            ),
            _sliderRow(
              label: 'Opacity',
              valueText: a.toStringAsFixed(2),
              value: a,
              max: 1,
              onChanged: (v) => _updateHcl(_hcl.copyWith(opacity: v)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _spaceBadge(
                  theme,
                  'Rgb',
                  'r:${fmt(rgb.r)}  g:${fmt(rgb.g)}  b:${fmt(rgb.b)}',
                ),
                _spaceBadge(
                  theme,
                  'Hsl',
                  'h:${fmt(hsl.h)}°  s:${fmt(hsl.s)}  l:${fmt(hsl.l)}',
                ),
                _spaceBadge(
                  theme,
                  'Lab',
                  'l:${fmt(lab.l)}  a:${fmt(lab.a)}  b:${fmt(lab.b)}',
                ),
                _spaceBadge(
                  theme,
                  'Cubehelix',
                  'h:${fmt(cube.h)}°  s:${fmt(cube.s)}  l:${fmt(cube.l)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamutSlicerCard(ThemeData theme) {
    final l = _hcl.l.isNaN ? 50.0 : _hcl.l.clamp(0.0, 100.0);
    final h = _hcl.h.isNaN ? 0.0 : _hcl.h.clamp(0.0, 360.0);
    final c = _hcl.c.isNaN ? 0.0 : _hcl.c.clamp(0.0, 140.0);

    void pickAt(Offset local, Size size) {
      final hue = (local.dx / size.width).clamp(0.0, 1.0) * 360.0;
      final chroma = (1.0 - (local.dy / size.height).clamp(0.0, 1.0)) * 140.0;
      _updateHcl(_hcl.copyWith(h: hue, c: chroma));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CIELCh (HCL) sRGB Gamut Slice at L* = ${l.toStringAsFixed(0)}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Drag across Hue (x) × Chroma (y). Muted regions are outside '
              'sRGB (!displayable()) — notice how high-chroma yellows appear '
              'at high L* while blues peak at low L*.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 210,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, 210);
                  return GestureDetector(
                    onPanDown: (d) => pickAt(d.localPosition, size),
                    onPanUpdate: (d) => pickAt(d.localPosition, size),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CustomPaint(
                        size: size,
                        painter: _HclGamutPainter(
                          lightness: l,
                          selectedHue: h,
                          selectedChroma: c,
                          outOfGamutColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerceptualLadderCard(
    ThemeData theme, {
    required d3.Rgb rgb,
    required d3.Hsl hsl,
    required d3.Lab lab,
  }) {
    const steps = <double>[-2, -1.2, -0.6, 0, 0.6, 1.2, 2];
    d3.Color shift(d3.Color base, double k) =>
        k == 0 ? base : (k > 0 ? base.brighter(k) : base.darker(-k));

    final rows = <(String, String, List<d3.Color>)>[
      ('HCL (perceptual)', 'd3.Hcl', [for (final k in steps) shift(_hcl, k)]),
      ('CIELAB (perceptual)', 'd3.Lab', [for (final k in steps) shift(lab, k)]),
      ('HSL (non-uniform)', 'd3.Hsl', [for (final k in steps) shift(hsl, k)]),
      (
        'sRGB (channel scale)',
        'd3.Rgb',
        [for (final k in steps) shift(rgb, k)],
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Perceptual Lightness Ladder: darker(k) ← base → brighter(k)',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Try "gold" or "steelblue" above: HCL and Lab keep perceptual '
              'contrast steady across steps, while HSL and RGB blow out or '
              'crush highlights.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            for (final (label, _, colors) in rows) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 148,
                      child: Text(label, style: theme.textTheme.labelMedium),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          for (var i = 0; i < colors.length; i++)
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _copyText(
                                  '$label step ${steps[i]}',
                                  colors[i].formatHex(),
                                ),
                                child: Container(
                                  height: 36,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors[i].toUiColor(),
                                    borderRadius: BorderRadius.circular(6),
                                    border: steps[i] == 0
                                        ? Border.all(
                                            color: theme.colorScheme.onSurface,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _copyChip(String label, String value) => ActionChip(
    avatar: const Icon(Icons.copy, size: 15),
    label: Text('$label: $value'),
    onPressed: () => _copyText(label, value),
  );

  Widget _sliderRow({
    required String label,
    required String valueText,
    required double value,
    required double max,
    required ValueChanged<double> onChanged,
  }) => Row(
    children: [
      SizedBox(width: 96, child: Text(label)),
      Expanded(
        child: Slider(
          value: value.clamp(0.0, max),
          max: max,
          onChanged: onChanged,
        ),
      ),
      SizedBox(
        width: 58,
        child: Text(
          valueText,
          textAlign: TextAlign.end,
          style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
        ),
      ),
    ],
  );

  Widget _spaceBadge(ThemeData theme, String title, String values) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.labelSmall),
        const SizedBox(height: 2),
        Text(
          values,
          style: theme.textTheme.bodySmall?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );
}

class const _CheckerColorPainter(final Color color) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cell = 10.0;
    final light = Paint()..color = const Color(0xFFE5E7EB);
    final dark = Paint()..color = const Color(0xFFCBD5E1);
    for (var y = 0.0; y < size.height; y += cell) {
      for (var x = 0.0; x < size.width; x += cell) {
        final odd = ((x ~/ cell) + (y ~/ cell)).isOdd;
        canvas.drawRect(Rect.fromLTWH(x, y, cell, cell), odd ? dark : light);
      }
    }
    canvas.drawRect(Offset.zero & size, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_CheckerColorPainter oldDelegate) =>
      oldDelegate.color != color;
}

class const _HclGamutPainter({
  required final double lightness,
  required final double selectedHue,
  required final double selectedChroma,
  required final Color outOfGamutColor,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cols = 90;
    const rows = 42;
    final cw = size.width / cols;
    final ch = size.height / rows;
    final paint = Paint();

    canvas.drawRect(Offset.zero & size, Paint()..color = outOfGamutColor);

    for (var r = 0; r < rows; r++) {
      final chroma = (1.0 - (r + 0.5) / rows) * 140.0;
      for (var c = 0; c < cols; c++) {
        final hue = (c + 0.5) / cols * 360.0;
        final color = d3.Hcl(hue, chroma, lightness);
        if (!color.displayable()) continue;
        paint.color = color.toUiColor();
        canvas.drawRect(
          Rect.fromLTWH(c * cw, r * ch, cw + 0.6, ch + 0.6),
          paint,
        );
      }
    }

    final sx = (selectedHue / 360.0).clamp(0.0, 1.0) * size.width;
    final sy = (1.0 - (selectedChroma / 140.0).clamp(0.0, 1.0)) * size.height;
    canvas
      ..drawCircle(
        Offset(sx, sy),
        7,
        Paint()
          ..color = const Color(0xFFFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      )
      ..drawCircle(
        Offset(sx, sy),
        8.5,
        Paint()
          ..color = const Color(0xFF000000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
  }

  @override
  bool shouldRepaint(_HclGamutPainter oldDelegate) =>
      oldDelegate.lightness != lightness ||
      oldDelegate.selectedHue != selectedHue ||
      oldDelegate.selectedChroma != selectedChroma ||
      oldDelegate.outOfGamutColor != outOfGamutColor;
}
