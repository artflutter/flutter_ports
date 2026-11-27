// Original code, not ported from D3: flutter_d3_chord_port interactive demo.

import 'dart:math' as math;

import 'package:flutter_d3_chord_port/flutter_d3_chord_port.dart' as d3;
import 'package:flutter_d3_path_port/flutter_d3_path_port.dart' as d3p;
import 'package:flutter_d3_scale_chromatic_port/flutter_d3_scale_chromatic_port.dart'
    as chromatic;
import 'package:flutter_d3_shape_port/flutter_d3_shape_port.dart' as d3s;
import 'package:material_ui/material_ui.dart';

enum _ChordMode(final String label) {
  undirected('Undirected (chord)'),
  directed('Directed (ribbonArrow)'),
  transpose('Transpose (chordTranspose)'),
}

enum _SortMode(final String label) {
  none('Matrix order'),
  descending('Descending'),
  ascending('Ascending'),
}

enum _DatasetPreset(final String label) {
  trade('Global Trade (6)'),
  circos('Circos (4)'),
  services('Services RPC (8)'),
}

enum _ChordPalette(final String label) {
  tableau10('Tableau 10'),
  paired('Paired'),
  set2('Set 2'),
  dark2('Dark 2');

  List<Color> colors() {
    final src = switch (this) {
      _ChordPalette.tableau10 => chromatic.schemeTableau10,
      _ChordPalette.paired => chromatic.schemePaired,
      _ChordPalette.set2 => chromatic.schemeSet2,
      _ChordPalette.dark2 => chromatic.schemeDark2,
    };
    return [
      for (final c in src)
        Color.fromARGB(
          255,
          c.r.round().clamp(0, 255),
          c.g.round().clamp(0, 255),
          c.b.round().clamp(0, 255),
        ),
    ];
  }
}

final class const _ChordDataset({
  required final List<String> labels,
  required final List<List<double>> matrix,
  required final String unit,
});

const _ChordDataset _tradeData = _ChordDataset(
  labels: [
    'N. America',
    'Europe',
    'East Asia',
    'South Asia',
    'LatAm',
    'Africa',
  ],
  matrix: [
    [140, 265, 310, 82, 175, 44],
    [290, 210, 240, 96, 118, 132],
    [345, 270, 195, 168, 124, 98],
    [68, 88, 142, 40, 36, 54],
    [152, 94, 110, 28, 65, 32],
    [38, 116, 86, 48, 26, 30],
  ],
  unit: 'B USD',
);

const _ChordDataset _circosData = _ChordDataset(
  labels: ['Black', 'Blond', 'Brown', 'Red'],
  matrix: [
    [11975, 5871, 8916, 2868],
    [1951, 10048, 2060, 6171],
    [8010, 16145, 8090, 8045],
    [1013, 990, 940, 6907],
  ],
  unit: 'flows',
);

const _ChordDataset _servicesData = _ChordDataset(
  labels: [
    'Gateway',
    'Auth',
    'Catalog',
    'Orders',
    'Billing',
    'Search',
    'Cache',
    'Events',
  ],
  matrix: [
    [0, 180, 220, 160, 45, 195, 30, 0],
    [12, 0, 15, 28, 35, 10, 140, 42],
    [0, 10, 25, 48, 0, 130, 165, 55],
    [0, 42, 95, 18, 145, 22, 75, 120],
    [0, 30, 0, 64, 10, 0, 40, 110],
    [0, 8, 88, 14, 0, 12, 155, 34],
    [0, 20, 40, 16, 12, 30, 0, 0],
    [0, 25, 32, 85, 78, 46, 0, 15],
  ],
  unit: 'k req/s',
);

/// Interactive showcase of `flutter_d3_chord_port`: live chord diagrams with
/// mode switching (`chord`, `chordDirected` + `ribbonArrow`, `chordTranspose`),
/// pad-angle and arrowhead-radius sliders, group/subgroup sort toggles, and
/// hover/tap group highlighting rendered directly on Flutter `Canvas` via
/// `UiPathContext`, `flutter_d3_shape_port`'s `arc`, and
/// `flutter_d3_scale_chromatic_port`.
class const ChordDemoPage({super.key}) extends StatefulWidget {
  /// Creates the `d3-chord` demo page.
  this;

  @override
  State<ChordDemoPage> createState() => _ChordDemoPageState();
}

class _ChordDemoPageState() extends State<ChordDemoPage> {
  _ChordMode _mode = _ChordMode.undirected;
  _DatasetPreset _dataset = _DatasetPreset.trade;
  _ChordPalette _palette = _ChordPalette.tableau10;
  _SortMode _groupSort = _SortMode.none;
  _SortMode _subgroupSort = _SortMode.descending;
  bool _sortChordsDesc = true;
  double _padAngle = 0.05;
  double _headRadius = 11;
  int? _hoveredGroup;
  int? _pinnedGroup;

  _ChordDataset get _currentData => switch (_dataset) {
    _DatasetPreset.trade => _tradeData,
    _DatasetPreset.circos => _circosData,
    _DatasetPreset.services => _servicesData,
  };

  d3.ChordComparator? _comparatorOf(_SortMode mode) => switch (mode) {
    _SortMode.none => null,
    _SortMode.descending => (a, b) => b - a,
    _SortMode.ascending => (a, b) => a - b,
  };

  int? get _activeGroup => _hoveredGroup ?? _pinnedGroup;

  int? _hitTestGroup(
    Offset localPosition,
    Size size,
    List<d3.ChordGroup> groups,
  ) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) * 0.38;
    final innerRadius = outerRadius - 22;
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < innerRadius - 8 || dist > outerRadius + 24) return null;
    // Convert standard atan2 (0 at +x) to D3 angle (0 at -y, clockwise).
    var angle = math.atan2(dy, dx) + math.pi / 2;
    if (angle < 0) angle += math.pi * 2;
    for (final g in groups) {
      if (angle >= g.startAngle && angle <= g.endAngle) {
        return g.index;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final data = _currentData;
    final colors = _palette.colors();

    final sw = Stopwatch()..start();
    final layout = switch (_mode) {
      _ChordMode.undirected => d3.chord(
        padAngle: _padAngle,
        sortGroups: _comparatorOf(_groupSort),
        sortSubgroups: _comparatorOf(_subgroupSort),
        sortChords: _sortChordsDesc ? (a, b) => b - a : null,
      ),
      _ChordMode.directed => d3.chordDirected(
        padAngle: _padAngle,
        sortGroups: _comparatorOf(_groupSort),
        sortSubgroups: _comparatorOf(_subgroupSort),
        sortChords: _sortChordsDesc ? (a, b) => b - a : null,
      ),
      _ChordMode.transpose => d3.chordTranspose(
        padAngle: _padAngle,
        sortGroups: _comparatorOf(_groupSort),
        sortSubgroups: _comparatorOf(_subgroupSort),
        sortChords: _sortChordsDesc ? (a, b) => b - a : null,
      ),
    };
    final chords = layout(data.matrix);
    sw.stop();

    final active = _activeGroup;
    final safeActive = active != null && active < data.labels.length
        ? active
        : null;

    final elapsedUs = sw.elapsedMicroseconds;
    final elapsedLabel = elapsedUs >= 1000
        ? '${(elapsedUs / 1000).toStringAsFixed(2)} ms'
        : '$elapsedUs µs';
    final activeLabel = safeActive == null
        ? null
        : '${data.labels[safeActive]}: '
              '${chords.groups[safeActive].value.round()} ${data.unit}';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Circular Flow Diagrams & Directed Ribbons',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Fully statically typed native Dart port of d3-chord '
          'v${d3.d3ChordVersion}: chord, chordDirected, chordTranspose, '
          'ribbon, and ribbonArrow drawn directly to Flutter Canvas via '
          'UiPathContext and flutter_d3_shape_port arc.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),

        // Controls card.
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
                    SegmentedButton<_ChordMode>(
                      segments: [
                        for (final m in _ChordMode.values)
                          ButtonSegment<_ChordMode>(
                            value: m,
                            label: Text(m.label),
                          ),
                      ],
                      selected: <_ChordMode>{_mode},
                      onSelectionChanged: (s) =>
                          setState(() => _mode = s.first),
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final preset in _DatasetPreset.values)
                          ChoiceChip(
                            label: Text(preset.label),
                            selected: _dataset == preset,
                            onSelected: (_) => setState(() {
                              _dataset = preset;
                              _hoveredGroup = null;
                              _pinnedGroup = null;
                            }),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 24,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 240,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pad angle: ${_padAngle.toStringAsFixed(3)} rad',
                            style: theme.textTheme.labelLarge,
                          ),
                          Slider(
                            value: _padAngle,
                            max: 0.15,
                            divisions: 30,
                            onChanged: (v) => setState(() => _padAngle = v),
                          ),
                        ],
                      ),
                    ),
                    if (_mode == _ChordMode.directed)
                      SizedBox(
                        width: 240,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Arrowhead radius: ${_headRadius.round()} px',
                              style: theme.textTheme.labelLarge,
                            ),
                            Slider(
                              value: _headRadius,
                              min: 4,
                              max: 24,
                              divisions: 20,
                              onChanged: (v) => setState(() => _headRadius = v),
                            ),
                          ],
                        ),
                      ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('Group sort:', style: theme.textTheme.labelMedium),
                        for (final s in _SortMode.values)
                          ChoiceChip(
                            label: Text(s.label),
                            selected: _groupSort == s,
                            onSelected: (_) => setState(() => _groupSort = s),
                          ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Subgroup sort:',
                          style: theme.textTheme.labelMedium,
                        ),
                        for (final s in _SortMode.values)
                          ChoiceChip(
                            label: Text(s.label),
                            selected: _subgroupSort == s,
                            onSelected: (_) =>
                                setState(() => _subgroupSort = s),
                          ),
                        FilterChip(
                          label: const Text('Sort chords'),
                          selected: _sortChordsDesc,
                          onSelected: (v) =>
                              setState(() => _sortChordsDesc = v),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('Palette:', style: theme.textTheme.labelMedium),
                        for (final p in _ChordPalette.values)
                          ChoiceChip(
                            label: Text(p.label),
                            selected: _palette == p,
                            onSelected: (_) => setState(() => _palette = p),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Interactive chord canvas card.
        Card.outlined(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 28,
                  child: Row(
                    children: [
                      Text(
                        '${chords.groups.length} groups · ${chords.length} '
                        '${_mode == _ChordMode.directed ? 'arrows' : 'chords'} '
                        '· layout $elapsedLabel',
                        maxLines: 1,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: safeActive != null
                            ? Align(
                                alignment: Alignment.centerLeft,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHighest
                                        .withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: cs.outlineVariant,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 10,
                                          height: 10,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              color:
                                                  colors[safeActive %
                                                      colors.length],
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            activeLabel!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.labelMedium,
                                          ),
                                        ),
                                        if (_pinnedGroup != null) ...[
                                          const SizedBox(width: 4),
                                          GestureDetector(
                                            onTap: () => setState(() {
                                              _pinnedGroup = null;
                                              _hoveredGroup = null;
                                            }),
                                            child: Icon(
                                              Icons.close,
                                              size: 14,
                                              color: cs.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : Text(
                                'Hover or tap any outer arc or legend chip to '
                                'isolate its ribbons',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final side = math.min<double>(constraints.maxWidth, 500);
                    final canvasSize = Size(constraints.maxWidth, side);
                    return SizedBox(
                      width: canvasSize.width,
                      height: canvasSize.height,
                      child: MouseRegion(
                        onHover: (e) {
                          final hit = _hitTestGroup(
                            e.localPosition,
                            canvasSize,
                            chords.groups,
                          );
                          if (hit != _hoveredGroup) {
                            setState(() => _hoveredGroup = hit);
                          }
                        },
                        onExit: (_) {
                          if (_hoveredGroup != null) {
                            setState(() => _hoveredGroup = null);
                          }
                        },
                        child: GestureDetector(
                          onTapDown: (d) {
                            final hit = _hitTestGroup(
                              d.localPosition,
                              canvasSize,
                              chords.groups,
                            );
                            setState(() {
                              _pinnedGroup = hit == _pinnedGroup ? null : hit;
                            });
                          },
                          child: CustomPaint(
                            size: canvasSize,
                            painter: _ChordDiagramPainter(
                              chords: chords,
                              labels: data.labels,
                              colors: colors,
                              directed: _mode == _ChordMode.directed,
                              headRadius: _headRadius,
                              activeGroup: safeActive,
                              textColor: cs.onSurface,
                              surfaceColor: cs.surface,
                              outlineColor: cs.outlineVariant,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (var i = 0; i < data.labels.length; ++i)
                      FilterChip(
                        showCheckmark: false,
                        avatar: CircleAvatar(
                          backgroundColor: colors[i % colors.length],
                        ),
                        label: Text(data.labels[i]),
                        selected: safeActive == i,
                        onSelected: (selected) => setState(() {
                          _pinnedGroup = selected ? i : null;
                          _hoveredGroup = null;
                        }),
                      ),
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

final class _ChordDiagramPainter({
  required final d3.Chords chords,
  required final List<String> labels,
  required final List<Color> colors,
  required final bool directed,
  required final double headRadius,
  required final int? activeGroup,
  required final Color textColor,
  required final Color surfaceColor,
  required final Color outlineColor,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) * 0.38;
    final innerRadius = math.max<double>(24, outerRadius - 22);
    final ribbonRadius = math.max<double>(16, innerRadius - 3);

    canvas
      ..save()
      ..translate(center.dx, center.dy);

    final ctx = d3p.uiPathContext();

    // 1. Draw ribbons directly to Flutter Canvas via UiPathContext.
    final ribGen = directed
        ? d3.ribbonArrow(
            sourceRadius: ribbonRadius,
            targetRadius: math.max<double>(12, ribbonRadius - 6),
            headRadius: headRadius,
            padAngle: 0.008,
          )
        : d3.ribbon(radius: ribbonRadius, padAngle: 0.004);

    final fillPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (final c in chords) {
      final isHighlighted =
          activeGroup == null ||
          c.source.index == activeGroup ||
          c.target.index == activeGroup;
      final baseColor = colors[c.source.index % colors.length];
      fillPaint.color = baseColor.withValues(
        alpha: activeGroup == null ? 0.62 : (isHighlighted ? 0.82 : 0.08),
      );
      strokePaint.color = baseColor.withValues(
        alpha: activeGroup == null ? 0.85 : (isHighlighted ? 0.95 : 0.12),
      );

      ctx.reset();
      ribGen.drawToUiPath(c, ctx);
      canvas
        ..drawPath(ctx.path, fillPaint)
        ..drawPath(ctx.path, strokePaint);
    }

    // 2. Draw outer group arcs via flutter_d3_shape_port arc + UiPathContext.
    final groupArc =
        d3s.arc<d3.ChordGroup>(
            innerRadius: innerRadius,
            outerRadius: outerRadius,
            cornerRadius: 3,
          )
          ..startAngle = ((g) => g.startAngle)
          ..endAngle = ((g) => g.endAngle)
          ..padAngleConst(0);

    final arcStroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = surfaceColor
      ..strokeWidth = 1.5;

    final tickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = outlineColor
      ..strokeWidth = 1;

    for (final g in chords.groups) {
      final isDimmed = activeGroup != null && activeGroup != g.index;
      final baseColor = colors[g.index % colors.length];
      fillPaint.color = baseColor.withValues(alpha: isDimmed ? 0.28 : 0.95);

      ctx.reset();
      groupArc.toUiPath(g, ctx);
      canvas
        ..drawPath(ctx.path, fillPaint)
        ..drawPath(ctx.path, arcStroke);

      // Draw group label outside the outer ring.
      final midAngle = (g.startAngle + g.endAngle) / 2 - math.pi / 2;
      final cosA = math.cos(midAngle);
      final sinA = math.sin(midAngle);
      canvas.drawLine(
        Offset(outerRadius * cosA, outerRadius * sinA),
        Offset((outerRadius + 6) * cosA, (outerRadius + 6) * sinA),
        tickPaint,
      );

      final label = g.index < labels.length ? labels[g.index] : 'G${g.index}';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: textColor.withValues(alpha: isDimmed ? 0.45 : 0.92),
            fontSize: 12,
            fontWeight: activeGroup == g.index
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelR = outerRadius + 10;
      final lx = labelR * cosA;
      final ly = labelR * sinA;
      final onLeft = cosA < -0.15;
      final centered = cosA.abs() <= 0.15;
      final dx = onLeft ? lx - tp.width : (centered ? lx - tp.width / 2 : lx);
      final dy = ly - tp.height / 2;
      tp.paint(canvas, Offset(dx, dy));
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ChordDiagramPainter oldDelegate) =>
      oldDelegate.chords != chords ||
      oldDelegate.directed != directed ||
      oldDelegate.headRadius != headRadius ||
      oldDelegate.activeGroup != activeGroup ||
      oldDelegate.colors != colors ||
      oldDelegate.textColor != textColor;
}
