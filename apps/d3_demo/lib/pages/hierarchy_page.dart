// Original code, not ported from D3: d3-hierarchy interactive demo.

import 'dart:math' as math;

import 'package:flutter_d3_color_port/flutter_d3_color_port.dart' as d3c;
import 'package:flutter_d3_hierarchy_port/flutter_d3_hierarchy_port.dart'
    as d3h;
import 'package:flutter_d3_path_port/flutter_d3_path_port.dart' as d3p;
import 'package:flutter_d3_scale_chromatic_port/flutter_d3_scale_chromatic_port.dart'
    as d3sc;
import 'package:flutter_d3_shape_port/flutter_d3_shape_port.dart' as d3s;
import 'package:material_ui/material_ui.dart';

final class const _NodeDatum({
  required final String name,
  final double size = 0,
  @override final List<_NodeDatum>? children,
}) implements d3h.HierarchyDatum<_NodeDatum>;

const _sampleTree = _NodeDatum(
  name: 'd3',
  children: [
    _NodeDatum(
      name: 'layout',
      children: [
        _NodeDatum(
          name: 'hierarchy',
          children: [
            _NodeDatum(name: 'treemap', size: 420),
            _NodeDatum(name: 'pack', size: 360),
            _NodeDatum(name: 'partition', size: 220),
            _NodeDatum(name: 'tree', size: 310),
            _NodeDatum(name: 'cluster', size: 190),
          ],
        ),
        _NodeDatum(
          name: 'spatial',
          children: [
            _NodeDatum(name: 'quadtree', size: 290),
            _NodeDatum(name: 'contour', size: 340),
            _NodeDatum(name: 'density', size: 260),
          ],
        ),
      ],
    ),
    _NodeDatum(
      name: 'shape',
      children: [
        _NodeDatum(
          name: 'curves',
          children: [
            _NodeDatum(name: 'monotone', size: 280),
            _NodeDatum(name: 'catmull', size: 240),
            _NodeDatum(name: 'basis', size: 210),
            _NodeDatum(name: 'cardinal', size: 180),
          ],
        ),
        _NodeDatum(
          name: 'marks',
          children: [
            _NodeDatum(name: 'arc', size: 350),
            _NodeDatum(name: 'area', size: 300),
            _NodeDatum(name: 'stack', size: 270),
            _NodeDatum(name: 'link', size: 195),
          ],
        ),
      ],
    ),
    _NodeDatum(
      name: 'color',
      children: [
        _NodeDatum(
          name: 'spaces',
          children: [
            _NodeDatum(name: 'rgb', size: 190),
            _NodeDatum(name: 'hsl', size: 165),
            _NodeDatum(name: 'lab', size: 230),
            _NodeDatum(name: 'hcl', size: 215),
          ],
        ),
        _NodeDatum(
          name: 'schemes',
          children: [
            _NodeDatum(name: 'viridis', size: 260),
            _NodeDatum(name: 'turbo', size: 240),
            _NodeDatum(name: 'tableau10', size: 185),
          ],
        ),
      ],
    ),
    _NodeDatum(
      name: 'data',
      children: [
        _NodeDatum(
          name: 'array',
          children: [
            _NodeDatum(name: 'bin', size: 295),
            _NodeDatum(name: 'quantile', size: 250),
            _NodeDatum(name: 'rollup', size: 275),
            _NodeDatum(name: 'blur', size: 210),
          ],
        ),
        _NodeDatum(
          name: 'format',
          children: [
            _NodeDatum(name: 'locale', size: 225),
            _NodeDatum(name: 'siPrefix', size: 180),
          ],
        ),
      ],
    ),
  ],
);

enum _HierarchyView(final String label) {
  treemap('Treemap'),
  sunburst('Sunburst'),
  pack('Circle Packing'),
  tree('Tidy Tree / Dendrogram'),
}

enum _TreemapTileKind(final String label) {
  squarify('Squarify'),
  binary('Binary'),
  dice('Dice'),
  slice('Slice'),
  sliceDice('SliceDice'),
  resquarify('Resquarify'),
}

enum _PackHighlight(final String label) {
  all('All depths'),
  depth1('Depth 1'),
  depth2('Depth 2'),
  leaves('Leaves'),
}

enum _TreeAlgorithm(final String label) {
  tidy('Tidy Tree (tree)'),
  dendrogram('Dendrogram (cluster)'),
}

enum _TreeOrientation(final String label) {
  horizontal('Horizontal (linkHorizontal)'),
  radial('Radial (linkRadial)'),
}

int _topCategoryIndex(d3h.HierarchyNode<_NodeDatum> node) {
  var current = node;
  while (current.depth > 1 && current.parent != null) {
    current = current.parent!;
  }
  final siblings = current.parent?.children;
  if (siblings == null) return 0;
  final idx = siblings.indexOf(current);
  return idx < 0 ? 0 : idx;
}

/// Interactive showcase of `flutter_d3_hierarchy_port`: Treemap with all 6
/// tiling algorithms, Sunburst via `partition` + `flutter_d3_shape_port` `arc`,
/// Circle Packing with interactive zoom and depth highlight, and Tidy Tree /
/// Dendrogram via `tree` / `cluster` + `linkHorizontal` / `linkRadial`.
class const HierarchyDemoPage({super.key}) extends StatefulWidget {
  /// Creates the `d3-hierarchy` demo page.
  this;

  @override
  State<HierarchyDemoPage> createState() => _HierarchyDemoPageState();
}

class _HierarchyDemoPageState() extends State<HierarchyDemoPage> {
  _HierarchyView _view = _HierarchyView.treemap;

  // Treemap state.
  _TreemapTileKind _tileKind = _TreemapTileKind.squarify;
  double _paddingInner = 2;
  double _paddingOuter = 4;
  double _paddingTop = 18;
  bool _roundTreemap = true;

  // Sunburst state.
  double _sunburstInnerHole = 0.22;
  double _sunburstPadAngle = 0.008;
  double _sunburstCornerRadius = 3;

  // Circle packing state.
  double _packPadding = 4;
  _PackHighlight _packHighlight = _PackHighlight.all;
  String? _packFocusPath;

  // Tree / Dendrogram state.
  _TreeAlgorithm _treeAlgorithm = _TreeAlgorithm.tidy;
  _TreeOrientation _treeOrientation = _TreeOrientation.horizontal;

  late final d3h.HierarchyNode<_NodeDatum> _baseHierarchy =
      d3h.hierarchy(_sampleTree)
        ..sum((d) => d.size)
        ..sort((a, b) => (b.value ?? 0).compareTo(a.value ?? 0));

  d3h.TreemapTile<_NodeDatum> _resolveTile() => switch (_tileKind) {
    _TreemapTileKind.squarify => d3h.treemapSquarify.call,
    _TreemapTileKind.binary => d3h.treemapBinary,
    _TreemapTileKind.dice => d3h.treemapDice,
    _TreemapTileKind.slice => d3h.treemapSlice,
    _TreemapTileKind.sliceDice => d3h.treemapSliceDice,
    _TreemapTileKind.resquarify => d3h.treemapResquarify.call,
  };

  static String _nodePath(d3h.HierarchyNode<_NodeDatum> node) =>
      node.ancestors().reversed.map((n) => n.data.name).join('/');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = [for (final c in d3sc.schemeTableau10) c.toUiColor()];

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
                  'Treemap, Sunburst, Circle Packing & Tidy Tree Layouts',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Fully typed HierarchyNode<T> layouts paired with '
                  'd3-shape arcs/links and d3-scale-chromatic palettes.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final v in _HierarchyView.values)
                      ChoiceChip(
                        label: Text(v.label),
                        selected: _view == v,
                        onSelected: (_) => setState(() => _view = v),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                switch (_view) {
                  _HierarchyView.treemap => _buildTreemapCard(theme, palette),
                  _HierarchyView.sunburst => _buildSunburstCard(theme, palette),
                  _HierarchyView.pack => _buildPackCard(theme, palette),
                  _HierarchyView.tree => _buildTreeCard(theme, palette),
                },
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTreemapCard(ThemeData theme, List<Color> palette) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 380,
            child: CustomPaint(
              painter: _TreemapPainter(
                root: _baseHierarchy,
                tile: _resolveTile(),
                paddingInner: _paddingInner,
                paddingOuter: _paddingOuter,
                paddingTop: _paddingTop,
                round: _roundTreemap,
                palette: palette,
                surfaceColor: theme.colorScheme.surfaceContainerLow,
                borderColor: theme.colorScheme.surface,
                textColor: theme.colorScheme.onSurface,
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
                Text('Tiling algorithm', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final k in _TreemapTileKind.values)
                      ChoiceChip(
                        label: Text(k.label),
                        selected: _tileKind == k,
                        onSelected: (_) => setState(() => _tileKind = k),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _SliderRow(
                  label: 'Inner padding',
                  value: _paddingInner,
                  min: 0,
                  max: 8,
                  display: '${_paddingInner.toStringAsFixed(1)} px',
                  onChanged: (v) => setState(() => _paddingInner = v),
                ),
                _SliderRow(
                  label: 'Outer padding',
                  value: _paddingOuter,
                  min: 0,
                  max: 12,
                  display: '${_paddingOuter.toStringAsFixed(1)} px',
                  onChanged: (v) => setState(() => _paddingOuter = v),
                ),
                _SliderRow(
                  label: 'Top padding',
                  value: _paddingTop,
                  min: 0,
                  max: 24,
                  display: '${_paddingTop.round()} px',
                  onChanged: (v) => setState(() => _paddingTop = v),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Round pixel coordinates'),
                  value: _roundTreemap,
                  onChanged: (v) => setState(() => _roundTreemap = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSunburstCard(ThemeData theme, List<Color> palette) {
    final padDeg = (_sunburstPadAngle * 180 / math.pi).toStringAsFixed(1);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 380,
            child: CustomPaint(
              painter: _SunburstPainter(
                root: _baseHierarchy,
                innerHoleRatio: _sunburstInnerHole,
                padAngle: _sunburstPadAngle,
                cornerRadius: _sunburstCornerRadius,
                palette: palette,
                labelColor: theme.colorScheme.onSurface,
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
                _SliderRow(
                  label: 'Center hole',
                  value: _sunburstInnerHole,
                  min: 0.05,
                  max: 0.45,
                  display: '${(_sunburstInnerHole * 100).round()}%',
                  onChanged: (v) => setState(() => _sunburstInnerHole = v),
                ),
                _SliderRow(
                  label: 'Pad angle',
                  value: _sunburstPadAngle,
                  min: 0,
                  max: 0.03,
                  display: '$padDeg°',
                  onChanged: (v) => setState(() => _sunburstPadAngle = v),
                ),
                _SliderRow(
                  label: 'Corner radius',
                  value: _sunburstCornerRadius,
                  min: 0,
                  max: 10,
                  display: '${_sunburstCornerRadius.toStringAsFixed(1)} px',
                  onChanged: (v) => setState(() => _sunburstCornerRadius = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackCard(ThemeData theme, List<Color> palette) {
    final focusLabel = _packFocusPath ?? 'd3 (root)';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 400,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                final diameter = math.min(size.width, size.height) - 24;
                final packed = d3h.pack<_NodeDatum>(
                  size: (diameter, diameter),
                  padding: (_) => _packPadding,
                )(_baseHierarchy);
                final focusNode =
                    (_packFocusPath != null
                        ? packed.find((n) => _nodePath(n) == _packFocusPath)
                        : null) ??
                    packed;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) {
                    final local = details.localPosition;
                    final scale =
                        (diameter * 0.5) /
                        (focusNode.r > 0 ? focusNode.r : 1.0);
                    final wx =
                        (local.dx - size.width / 2) / scale + focusNode.x;
                    final wy =
                        (local.dy - size.height / 2) / scale + focusNode.y;
                    d3h.HierarchyCircularNode<_NodeDatum>? hit;
                    for (final node in packed.descendants()) {
                      if (node.depth == 0) continue;
                      final dx = wx - node.x;
                      final dy = wy - node.y;
                      if (dx * dx + dy * dy <= node.r * node.r) {
                        if (hit == null || node.depth >= hit.depth) {
                          hit = node;
                        }
                      }
                    }
                    setState(() {
                      if (hit == null) {
                        _packFocusPath = null;
                      } else {
                        final nextPath = _nodePath(hit);
                        _packFocusPath = nextPath == _packFocusPath
                            ? (hit.parent != null && hit.parent!.depth > 0
                                  ? _nodePath(hit.parent!)
                                  : null)
                            : nextPath;
                      }
                    });
                  },
                  child: CustomPaint(
                    painter: _PackPainter(
                      packedRoot: packed,
                      focusNode: focusNode,
                      diameter: diameter,
                      highlight: _packHighlight,
                      palette: palette,
                      borderColor: theme.colorScheme.outlineVariant,
                      labelColor: theme.colorScheme.onSurface,
                    ),
                    child: const SizedBox.expand(),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Zoom focus: $focusLabel (tap any circle to zoom)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (_packFocusPath != null)
                      TextButton.icon(
                        onPressed: () => setState(() => _packFocusPath = null),
                        icon: const Icon(Icons.zoom_out_map, size: 16),
                        label: const Text('Reset zoom'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Depth highlight', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final h in _PackHighlight.values)
                      ChoiceChip(
                        label: Text(h.label),
                        selected: _packHighlight == h,
                        onSelected: (_) => setState(() => _packHighlight = h),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _SliderRow(
                  label: 'Circle padding',
                  value: _packPadding,
                  min: 0,
                  max: 14,
                  display: '${_packPadding.toStringAsFixed(1)} px',
                  onChanged: (v) => setState(() => _packPadding = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeCard(ThemeData theme, List<Color> palette) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 430,
            child: CustomPaint(
              painter: _TreePainter(
                root: _baseHierarchy,
                algorithm: _treeAlgorithm,
                orientation: _treeOrientation,
                palette: palette,
                linkColor: theme.colorScheme.outline,
                labelColor: theme.colorScheme.onSurface,
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
                Text('Layout algorithm', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final a in _TreeAlgorithm.values)
                      ChoiceChip(
                        label: Text(a.label),
                        selected: _treeAlgorithm == a,
                        onSelected: (_) => setState(() => _treeAlgorithm = a),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Link projection', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final o in _TreeOrientation.values)
                      ChoiceChip(
                        label: Text(o.label),
                        selected: _treeOrientation == o,
                        onSelected: (_) => setState(() => _treeOrientation = o),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
          width: 68,
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

class _TreemapPainter({
  required final d3h.HierarchyNode<_NodeDatum> root,
  required final d3h.TreemapTile<_NodeDatum> tile,
  required final double paddingInner,
  required final double paddingOuter,
  required final double paddingTop,
  required final bool round,
  required final List<Color> palette,
  required final Color surfaceColor,
  required final Color borderColor,
  required final Color textColor,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const margin = 12.0;
    final w = math.max<double>(10, size.width - margin * 2);
    final h = math.max<double>(10, size.height - margin * 2);

    final layout = d3h.treemap<_NodeDatum>(
      tile: tile,
      size: (w, h),
      round: round,
      paddingInner: (_) => paddingInner,
      paddingOuter: (_) => paddingOuter,
      paddingTop: (_) => paddingTop,
    );
    final rectRoot = layout(root);

    canvas
      ..save()
      ..translate(margin, margin);

    final strokePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final node in rectRoot.descendants()) {
      if (node.depth == 0) continue;
      final bw = node.x1 - node.x0;
      final bh = node.y1 - node.y0;
      if (bw <= 0 || bh <= 0) continue;
      final rect = Rect.fromLTRB(node.x0, node.y0, node.x1, node.y1);
      final base = palette[_topCategoryIndex(node) % palette.length];
      final fill = node.children == null
          ? base.withValues(alpha: 0.78)
          : Color.lerp(surfaceColor, base, node.depth == 1 ? 0.22 : 0.38)!;

      canvas
        ..drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          Paint()..color = fill,
        )
        ..drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          strokePaint,
        );

      if (node.children != null && bw > 44 && paddingTop >= 12) {
        (TextPainter(
          text: TextSpan(
            text: node.data.name,
            style: TextStyle(
              color: textColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          maxLines: 1,
          ellipsis: '…',
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: math.max(0, bw - 8))).paint(
          canvas,
          Offset(node.x0 + 5, node.y0 + 2),
        );
      } else if (node.children == null && bw > 34 && bh > 18) {
        (TextPainter(
          text: TextSpan(
            text: '${node.data.name}\n${(node.value ?? 0).round()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
          maxLines: bh > 32 ? 2 : 1,
          ellipsis: '…',
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: math.max(0, bw - 8))).paint(
          canvas,
          Offset(node.x0 + 4, node.y0 + 3),
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TreemapPainter oldDelegate) => true;
}

class _SunburstPainter({
  required final d3h.HierarchyNode<_NodeDatum> root,
  required final double innerHoleRatio,
  required final double padAngle,
  required final double cornerRadius,
  required final List<Color> palette,
  required final Color labelColor,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final maxR = math.min(size.width, size.height) * 0.45;
    final holeR = maxR * innerHoleRatio;
    final partRoot = d3h.partition<_NodeDatum>(
      size: (math.pi * 2, maxR - holeR),
    )(root);

    final ctx = d3p.uiPathContext();
    final arcGen = d3s.arc<d3h.HierarchyRectangularNode<_NodeDatum>>()
      ..startAngle = ((d) => d.x0)
      ..endAngle = ((d) => d.x1)
      ..innerRadius = ((d) => holeR + d.y0)
      ..outerRadius = ((d) => math.max(holeR + d.y0, holeR + d.y1 - 1.5))
      ..padAngleConst(padAngle)
      ..padRadiusConst(maxR * 0.5)
      ..cornerRadiusConst(cornerRadius)
      ..context = ctx;

    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2);

    for (final node in partRoot.descendants()) {
      if (node.depth == 0) continue;
      if (node.x1 - node.x0 <= 1e-4) continue;
      final base = palette[_topCategoryIndex(node) % palette.length];
      final alpha = switch (node.depth) {
        1 => 0.92,
        2 => 0.72,
        _ => 0.52,
      };
      ctx.reset();
      arcGen(node);
      canvas.drawPath(
        ctx.path,
        Paint()
          ..color = base.withValues(alpha: alpha)
          ..style = PaintingStyle.fill,
      );

      final span = node.x1 - node.x0;
      if (span > 0.20) {
        final (cx, cy) = arcGen.centroid(node);
        final tp = TextPainter(
          text: TextSpan(
            text: node.data.name,
            style: TextStyle(
              color: node.depth <= 2 ? Colors.white : labelColor,
              fontSize: node.depth == 1 ? 11 : 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
      }
    }

    final centerText = TextPainter(
      text: TextSpan(
        text: '${(partRoot.value ?? 0).round()}\ntotal',
        style: TextStyle(
          color: labelColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    centerText.paint(
      canvas,
      Offset(-centerText.width / 2, -centerText.height / 2),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SunburstPainter oldDelegate) => true;
}

class _PackPainter({
  required final d3h.HierarchyCircularNode<_NodeDatum> packedRoot,
  required final d3h.HierarchyCircularNode<_NodeDatum> focusNode,
  required final double diameter,
  required final _PackHighlight highlight,
  required final List<Color> palette,
  required final Color borderColor,
  required final Color labelColor,
}) extends CustomPainter {
  bool _isHighlighted(d3h.HierarchyCircularNode<_NodeDatum> node) =>
      switch (highlight) {
        _PackHighlight.all => true,
        _PackHighlight.depth1 => node.depth == 1,
        _PackHighlight.depth2 => node.depth == 2,
        _PackHighlight.leaves => node.children == null,
      };

  @override
  void paint(Canvas canvas, Size size) {
    final scale = (diameter * 0.5) / (focusNode.r > 0 ? focusNode.r : 1.0);
    final cx0 = size.width / 2;
    final cy0 = size.height / 2;

    for (final node in packedRoot.descendants()) {
      final sx = (node.x - focusNode.x) * scale + cx0;
      final sy = (node.y - focusNode.y) * scale + cy0;
      final sr = node.r * scale;
      if (sr < 0.8) continue;

      final active = _isHighlighted(node);
      if (node.depth == 0) {
        canvas.drawCircle(
          Offset(sx, sy),
          sr,
          Paint()
            ..color = borderColor.withValues(alpha: 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
        continue;
      }

      final base = node.children == null
          ? d3sc
                .interpolateViridis(
                  ((_topCategoryIndex(node) + 0.5) / 4.0).clamp(0.12, 0.88),
                )
                .toUiColor()
          : palette[_topCategoryIndex(node) % palette.length];
      final fillAlpha = node.children == null
          ? (active ? 0.85 : 0.16)
          : (active ? (node.depth == 1 ? 0.18 : 0.30) : 0.06);

      canvas
        ..drawCircle(
          Offset(sx, sy),
          sr,
          Paint()
            ..color = base.withValues(alpha: fillAlpha)
            ..style = PaintingStyle.fill,
        )
        ..drawCircle(
          Offset(sx, sy),
          sr,
          Paint()
            ..color = base.withValues(alpha: active ? 0.85 : 0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = identical(node, focusNode) ? 2.4 : 1.1,
        );

      if (node.children == null && sr >= 16) {
        final tp = TextPainter(
          text: TextSpan(
            text: node.data.name,
            style: TextStyle(
              color: active ? Colors.white : labelColor.withValues(alpha: 0.4),
              fontSize: math.min(11.5, sr * 0.42),
              fontWeight: FontWeight.w600,
            ),
          ),
          maxLines: 1,
          ellipsis: '…',
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: sr * 1.75);
        tp.paint(canvas, Offset(sx - tp.width / 2, sy - tp.height / 2));
      } else if (node.children != null && sr >= 34 && active) {
        final tp = TextPainter(
          text: TextSpan(
            text: node.data.name,
            style: TextStyle(
              color: labelColor.withValues(alpha: 0.85),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(sx - tp.width / 2, sy - sr + 4));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PackPainter oldDelegate) => true;
}

class _TreePainter({
  required final d3h.HierarchyNode<_NodeDatum> root,
  required final _TreeAlgorithm algorithm,
  required final _TreeOrientation orientation,
  required final List<Color> palette,
  required final Color linkColor,
  required final Color labelColor,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linkPaint = Paint()
      ..color = linkColor.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final ctx = d3p.uiPathContext();

    if (orientation == _TreeOrientation.radial) {
      final radius = math.min(size.width, size.height) * 0.37;
      final pointRoot = algorithm == _TreeAlgorithm.tidy
          ? d3h.tree<_NodeDatum>(
              size: (math.pi * 2, radius),
              separation: (a, b) =>
                  (identical(a.parent, b.parent) ? 1.0 : 2.0) /
                  math.max(1, a.depth),
            )(root)
          : d3h.cluster<_NodeDatum>(
              size: (math.pi * 2, radius),
              separation: (a, b) =>
                  (identical(a.parent, b.parent) ? 1.0 : 2.0) /
                  math.max(1, a.depth),
            )(root);

      final linkGen =
          d3s
              .linkRadial<
                d3h.HierarchyPointLink<_NodeDatum>,
                d3h.HierarchyPointNode<_NodeDatum>
              >()
            ..source = ((l) => l.source)
            ..target = ((l) => l.target)
            ..angle = ((n) => n.x)
            ..radius = ((n) => n.y)
            ..context = ctx;

      canvas
        ..save()
        ..translate(size.width / 2, size.height / 2);

      for (final link in pointRoot.links()) {
        ctx.reset();
        linkGen(link);
        canvas.drawPath(ctx.path, linkPaint);
      }

      for (final node in pointRoot.descendants()) {
        final (px, py) = d3s.pointRadial(node.x, node.y);
        final color = node.depth == 0
            ? labelColor
            : palette[_topCategoryIndex(node) % palette.length];
        canvas.drawCircle(
          Offset(px, py),
          node.children == null ? 3.5 : 4.8,
          Paint()..color = color,
        );

        if (node.children == null) {
          final (lx, ly) = d3s.pointRadial(node.x, node.y + 8);
          final leftSide = node.x > math.pi;
          final tp = TextPainter(
            text: TextSpan(
              text: node.data.name,
              style: TextStyle(color: labelColor, fontSize: 9.5),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          canvas
            ..save()
            ..translate(lx, ly)
            ..rotate(node.x - math.pi / 2 + (leftSide ? math.pi : 0));
          tp.paint(canvas, Offset(leftSide ? -tp.width : 0, -tp.height / 2));
          canvas.restore();
        }
      }

      canvas.restore();
      return;
    }

    const padLeft = 48.0;
    const padRight = 84.0;
    const padY = 18.0;
    final layoutW = math.max<double>(40, size.width - padLeft - padRight);
    final layoutH = math.max<double>(40, size.height - padY * 2);

    final pointRoot = algorithm == _TreeAlgorithm.tidy
        ? d3h.tree<_NodeDatum>(size: (layoutH, layoutW))(root)
        : d3h.cluster<_NodeDatum>(size: (layoutH, layoutW))(root);

    final linkGen =
        d3s
            .linkHorizontal<
              d3h.HierarchyPointLink<_NodeDatum>,
              d3h.HierarchyPointNode<_NodeDatum>
            >()
          ..source = ((l) => l.source)
          ..target = ((l) => l.target)
          ..x = ((n) => padLeft + n.y)
          ..y = ((n) => padY + n.x)
          ..context = ctx;

    for (final link in pointRoot.links()) {
      ctx.reset();
      linkGen(link);
      canvas.drawPath(ctx.path, linkPaint);
    }

    for (final node in pointRoot.descendants()) {
      final px = padLeft + node.y;
      final py = padY + node.x;
      final color = node.depth == 0
          ? labelColor
          : palette[_topCategoryIndex(node) % palette.length];
      canvas.drawCircle(
        Offset(px, py),
        node.children == null ? 3.5 : 4.8,
        Paint()..color = color,
      );

      final isLeaf = node.children == null;
      final tp = TextPainter(
        text: TextSpan(
          text: node.data.name,
          style: TextStyle(
            color: labelColor,
            fontSize: isLeaf ? 10 : 10.5,
            fontWeight: isLeaf ? FontWeight.normal : FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(isLeaf ? px + 7 : px - tp.width - 7, py - tp.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TreePainter oldDelegate) => true;
}
