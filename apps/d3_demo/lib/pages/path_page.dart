// Original code, not ported from D3: flutter_d3_path_port interactive demo.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_d3_path_port/flutter_d3_path_port.dart' as d3;
import 'package:material_ui/material_ui.dart';

enum _PathPreset(final String label) {
  roundedBadge('Rounded Badge (arcTo)'),
  gaugeArc('Gauge Arc (arc)'),
  cubicWave('Cubic Wave (bezierCurveTo)'),
  quadRibbon('Quad & Rects (quadraticCurveTo + rect)'),
}

/// Interactive showcase of `flutter_d3_path_port`: one `CanvasPath` drawing
/// routine targeting both native Flutter `UiPathContext` (`dart:ui.Path`) and
/// live `path()` / `pathRound(digits)` SVG serialization.
class const PathDemoPage({super.key}) extends StatefulWidget {
  /// Creates the `d3-path` demo page.
  this;

  @override
  State<PathDemoPage> createState() => _PathDemoPageState();
}

class _PathDemoPageState() extends State<PathDemoPage> {
  _PathPreset _preset = _PathPreset.roundedBadge;
  int? _digits = 2; // null = full precision path(), 0..6 = pathRound(digits)
  double _radius = 36;
  double _sweepDegrees = 240;
  double _curveHeight = 72;
  bool _ccw = false;
  bool _showGuides = true;

  void _drawInto(d3.CanvasPath ctx, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    switch (_preset) {
      case _PathPreset.roundedBadge:
        final w = math.min<double>(size.width * 0.68, 340);
        final h = math.min<double>(size.height * 0.56, 170);
        final x0 = cx - w / 2;
        final y0 = cy - h / 2;
        final x1 = cx + w / 2;
        final y1 = cy + h / 2;
        final r = _radius.clamp(0.0, math.min(w, h) / 2);
        ctx
          ..moveTo(x0 + r, y0)
          ..arcTo(x1, y0, x1, y1, r)
          ..arcTo(x1, y1, x0, y1, r)
          ..arcTo(x0, y1, x0, y0, r)
          ..arcTo(x0, y0, x1, y0, r)
          ..closePath();
      case _PathPreset.gaugeArc:
        final outer = math.min(size.width, size.height) * 0.36;
        final inner = (outer - _radius.clamp(12.0, outer * 0.65)).clamp(
          16.0,
          outer - 8,
        );
        const start = -math.pi * 0.75;
        final sweep = _sweepDegrees * math.pi / 180;
        final end = _ccw ? start - sweep : start + sweep;
        ctx
          ..arc(cx, cy, outer, start, end, _ccw)
          ..arc(cx, cy, inner, end, start, !_ccw)
          ..closePath();
      case _PathPreset.cubicWave:
        final left = size.width * 0.1;
        final right = size.width * 0.9;
        final span = (right - left) / 3;
        final amp = _curveHeight;
        ctx
          ..moveTo(left, cy)
          ..bezierCurveTo(
            left + span * 0.45,
            cy - amp,
            left + span * 0.55,
            cy + amp,
            left + span,
            cy,
          )
          ..bezierCurveTo(
            left + span * 1.45,
            cy - amp,
            left + span * 1.55,
            cy + amp,
            left + span * 2,
            cy,
          )
          ..bezierCurveTo(
            left + span * 2.45,
            cy - amp,
            left + span * 2.55,
            cy + amp,
            right,
            cy,
          );
      case _PathPreset.quadRibbon:
        final left = size.width * 0.12;
        final right = size.width * 0.88;
        final lift = _curveHeight;
        ctx
          ..moveTo(left, cy + 36)
          ..quadraticCurveTo(cx, cy - lift, right, cy + 36)
          ..lineTo(right, cy + 60)
          ..quadraticCurveTo(cx, cy - lift + 28, left, cy + 60)
          ..closePath()
          ..rect(left, cy - 86, 48, 28)
          ..rect(right - 48, cy - 86, 48, 28);
    }
  }

  void _copySvg(String svg) {
    unawaited(Clipboard.setData(ClipboardData(text: svg)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied SVG path data'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const previewSize = Size(560, 260);
    final fullPath = d3.path();
    _drawInto(fullPath, previewSize);
    final fullSvg = '$fullPath';

    final activePath = _digits == null ? fullPath : d3.pathRound(_digits!);
    if (_digits != null) {
      _drawInto(activePath, previewSize);
    }
    final activeSvg = '$activePath';
    final savedPct = fullSvg.isEmpty
        ? 0
        : ((1 - activeSvg.length / fullSvg.length) * 100).round();

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
                  'CanvasPath Studio, Live SVG Serializer & '
                  'Native dart:ui.Path',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'One CanvasPath routine renders directly onto Flutter Canvas '
                  'via UiPathContext (zero SVG parsing) while path() and '
                  'pathRound(digits) serialize the exact SVG d="..." string.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final preset in _PathPreset.values)
                      ChoiceChip(
                        label: Text(preset.label),
                        selected: _preset == preset,
                        onSelected: (_) => setState(() => _preset = preset),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 260,
                        child: CustomPaint(
                          painter: _D3PathPainter(
                            drawInto: _drawInto,
                            strokeColor: theme.colorScheme.primary,
                            fillColor: theme.colorScheme.primary.withValues(
                              alpha: 0.14,
                            ),
                            gridColor: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.4),
                            showGrid: _showGuides,
                            fillShape: _preset != _PathPreset.cubicWave,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_preset == _PathPreset.roundedBadge ||
                                _preset == _PathPreset.gaugeArc)
                              _SliderRow(
                                label: _preset == _PathPreset.roundedBadge
                                    ? 'Corner radius'
                                    : 'Ring thickness',
                                value: _radius,
                                min: 0,
                                max: 80,
                                display: '${_radius.round()} px',
                                onChanged: (v) => setState(() => _radius = v),
                              ),
                            if (_preset == _PathPreset.gaugeArc) ...[
                              _SliderRow(
                                label: 'Sweep angle',
                                value: _sweepDegrees,
                                min: 15,
                                max: 360,
                                display: '${_sweepDegrees.round()}°',
                                onChanged: (v) =>
                                    setState(() => _sweepDegrees = v),
                              ),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Counter-clockwise (ccw)'),
                                value: _ccw,
                                onChanged: (v) => setState(() => _ccw = v),
                              ),
                            ],
                            if (_preset == _PathPreset.cubicWave ||
                                _preset == _PathPreset.quadRibbon)
                              _SliderRow(
                                label: 'Curve amplitude',
                                value: _curveHeight,
                                min: 10,
                                max: 110,
                                display: '${_curveHeight.round()} px',
                                onChanged: (v) =>
                                    setState(() => _curveHeight = v),
                              ),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Show coordinate grid'),
                              value: _showGuides,
                              onChanged: (v) => setState(() => _showGuides = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _digits != null && savedPct > 0
                                    ? 'SVG Path Output (${activeSvg.length} '
                                          'chars, -$savedPct% vs full)'
                                    : 'SVG Path Output (${activeSvg.length} '
                                          'chars)',
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: () => _copySvg(activeSvg),
                              icon: const Icon(Icons.copy, size: 18),
                              label: const Text('Copy d'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('path() full'),
                              selected: _digits == null,
                              onSelected: (_) => setState(() => _digits = null),
                            ),
                            for (final d in const [0, 1, 2, 3, 6])
                              ChoiceChip(
                                label: Text('pathRound($d)'),
                                selected: _digits == d,
                                onSelected: (_) => setState(() => _digits = d),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            activeSvg,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class const _SliderRow({
  required final String label,
  required final double value,
  required final double min,
  required final double max,
  required final String display,
  required final ValueChanged<double> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 64,
          child: Text(
            display,
            textAlign: TextAlign.end,
            style: theme.textTheme.labelMedium,
          ),
        ),
      ],
    );
  }
}

class _D3PathPainter({
  required final void Function(d3.CanvasPath ctx, Size size) drawInto,
  required final Color strokeColor,
  required final Color fillColor,
  required final Color gridColor,
  required final bool showGrid,
  required final bool fillShape,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (showGrid) {
      final gridPaint = Paint()
        ..color = gridColor
        ..strokeWidth = 1;
      for (var x = 20.0; x < size.width; x += 20) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
      for (var y = 20.0; y < size.height; y += 20) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }

    final uiCtx = d3.uiPathContext();
    drawInto(uiCtx, size);

    if (fillShape) {
      canvas.drawPath(
        uiCtx.path,
        Paint()
          ..color = fillColor
          ..style = PaintingStyle.fill,
      );
    }
    canvas.drawPath(
      uiCtx.path,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _D3PathPainter oldDelegate) => true;
}
