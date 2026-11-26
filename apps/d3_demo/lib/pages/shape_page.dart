// Original code, not ported from D3: flutter_d3_shape_port interactive demo.

import 'dart:math' as math;

import 'package:flutter_d3_color_port/flutter_d3_color_port.dart' as d3c;
import 'package:flutter_d3_path_port/flutter_d3_path_port.dart' as d3p;
import 'package:flutter_d3_scale_chromatic_port/flutter_d3_scale_chromatic_port.dart'
    as d3sc;
import 'package:flutter_d3_shape_port/flutter_d3_shape_port.dart' as d3s;
import 'package:material_ui/material_ui.dart';

enum _ShapeSection(final String label) {
  curves('Curves (Line & Area)'),
  arcPie('Arc & Pie'),
  streamgraph('Streamgraph Stack'),
  symbolsLinks('Symbols & Links'),
}

enum _CurveKind(final String label, {final bool hasParam = false}) {
  monotoneX('monotoneX'),
  catmullRom('catmullRom', hasParam: true),
  cardinal('cardinal', hasParam: true),
  basis('basis'),
  natural('natural'),
  bundle('bundle', hasParam: true),
  bumpX('bumpX'),
  bumpY('bumpY'),
  step('step'),
  stepBefore('stepBefore'),
  stepAfter('stepAfter'),
  linear('linear'),
  linearClosed('linearClosed'),
  basisClosed('basisClosed'),
  cardinalClosed('cardinalClosed', hasParam: true),
  catmullRomClosed('catmullRomClosed', hasParam: true),
}

enum _StackOffsetKind(final String label) {
  wiggle('wiggle'),
  silhouette('silhouette'),
  expand('expand'),
  none('none'),
  diverging('diverging'),
}

enum _StackOrderKind(final String label) {
  insideOut('insideOut'),
  appearance('appearance'),
  ascending('ascending'),
  descending('descending'),
  none('none'),
  reverse('reverse'),
}

enum _LinkMode(final String label) {
  horizontal('linkHorizontal'),
  vertical('linkVertical'),
  radial('linkRadial'),
}

/// Interactive showcase of `flutter_d3_shape_port`: curves, pie/donut arcs,
/// streamgraph stacks, and symbols/links drawn directly to Flutter `Canvas`
/// via `UiPathContext`.
class const ShapeDemoPage({super.key}) extends StatefulWidget {
  /// Creates the `d3-shape` demo page.
  this;

  @override
  State<ShapeDemoPage> createState() => _ShapeDemoPageState();
}

class _ShapeDemoPageState() extends State<ShapeDemoPage> {
  _ShapeSection _section = _ShapeSection.curves;

  // Curves controls.
  _CurveKind _curveKind = _CurveKind.monotoneX;
  bool _fillArea = true;
  bool _showPoints = true;
  double _curveParam = 0.5;

  // Arc / Pie controls.
  double _innerRatio = 0.45;
  double _cornerRadius = 8;
  double _padAngle = 0.03;
  bool _sortPie = true;

  // Streamgraph stack controls.
  _StackOffsetKind _offsetKind = _StackOffsetKind.wiggle;
  _StackOrderKind _orderKind = _StackOrderKind.insideOut;
  bool _smoothStack = true;

  // Symbols & Links controls.
  double _symbolSize = 180;
  _LinkMode _linkMode = _LinkMode.horizontal;

  d3s.CurveFactory _resolveCurve() => switch (_curveKind) {
    _CurveKind.monotoneX => d3s.curveMonotoneX,
    _CurveKind.catmullRom => d3s.curveCatmullRom.alpha(_curveParam).call,
    _CurveKind.cardinal => d3s.curveCardinal.tension(_curveParam).call,
    _CurveKind.basis => d3s.curveBasis,
    _CurveKind.natural => d3s.curveNatural,
    _CurveKind.bundle => d3s.curveBundle.beta(_curveParam).call,
    _CurveKind.bumpX => d3s.curveBumpX,
    _CurveKind.bumpY => d3s.curveBumpY,
    _CurveKind.step => d3s.curveStep,
    _CurveKind.stepBefore => d3s.curveStepBefore,
    _CurveKind.stepAfter => d3s.curveStepAfter,
    _CurveKind.linear => d3s.curveLinear,
    _CurveKind.linearClosed => d3s.curveLinearClosed,
    _CurveKind.basisClosed => d3s.curveBasisClosed,
    _CurveKind.cardinalClosed =>
      d3s.curveCardinalClosed.tension(_curveParam).call,
    _CurveKind.catmullRomClosed =>
      d3s.curveCatmullRomClosed.alpha(_curveParam).call,
  };

  String get _paramLabel => switch (_curveKind) {
    _CurveKind.bundle => 'beta',
    _CurveKind.cardinal || _CurveKind.cardinalClosed => 'tension',
    _ => 'alpha',
  };

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
                  'Curves, Arcs, Streamgraph Stacks, Symbols & Links',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Every generator renders straight onto Flutter Canvas via '
                  'UiPathContext (zero SVG string allocation or parsing).',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in _ShapeSection.values)
                      ChoiceChip(
                        label: Text(s.label),
                        selected: _section == s,
                        onSelected: (_) => setState(() => _section = s),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                switch (_section) {
                  _ShapeSection.curves => _buildCurvesCard(theme),
                  _ShapeSection.arcPie => _buildArcPieCard(theme, palette),
                  _ShapeSection.streamgraph => _buildStackCard(theme, palette),
                  _ShapeSection.symbolsLinks => _buildSymbolsLinksCard(
                    theme,
                    palette,
                  ),
                },
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurvesCard(ThemeData theme) {
    final allowArea =
        _curveKind != _CurveKind.bundle &&
        _curveKind != _CurveKind.linearClosed &&
        _curveKind != _CurveKind.basisClosed &&
        _curveKind != _CurveKind.cardinalClosed &&
        _curveKind != _CurveKind.catmullRomClosed;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 280,
            child: CustomPaint(
              painter: _CurvesPainter(
                curve: _resolveCurve(),
                fillArea: _fillArea && allowArea,
                showPoints: _showPoints,
                strokeColor: theme.colorScheme.primary,
                fillColor: theme.colorScheme.primary.withValues(alpha: 0.16),
                dotColor: theme.colorScheme.tertiary,
                gridColor: theme.colorScheme.outlineVariant.withValues(
                  alpha: 0.35,
                ),
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
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final k in _CurveKind.values)
                      ChoiceChip(
                        label: Text(k.label),
                        selected: _curveKind == k,
                        onSelected: (_) => setState(() => _curveKind = k),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_curveKind.hasParam)
                  _SliderRow(
                    label: 'Curve $_paramLabel',
                    value: _curveParam,
                    min: 0,
                    max: 1,
                    display: _curveParam.toStringAsFixed(2),
                    onChanged: (v) => setState(() => _curveParam = v),
                  ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fill area beneath curve'),
                  value: _fillArea && allowArea,
                  onChanged: allowArea
                      ? (v) => setState(() => _fillArea = v)
                      : null,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show data points'),
                  value: _showPoints,
                  onChanged: (v) => setState(() => _showPoints = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArcPieCard(ThemeData theme, List<Color> palette) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 300,
            child: CustomPaint(
              painter: _ArcPiePainter(
                innerRatio: _innerRatio,
                cornerRadius: _cornerRadius,
                padAngle: _padAngle,
                sortPie: _sortPie,
                palette: palette,
                labelColor: theme.colorScheme.onPrimary,
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
                  label: 'Inner radius',
                  value: _innerRatio,
                  min: 0,
                  max: 0.78,
                  display: '${(_innerRatio * 100).round()}%',
                  onChanged: (v) => setState(() => _innerRatio = v),
                ),
                _SliderRow(
                  label: 'Corner radius',
                  value: _cornerRadius,
                  min: 0,
                  max: 24,
                  display: '${_cornerRadius.round()} px',
                  onChanged: (v) => setState(() => _cornerRadius = v),
                ),
                _SliderRow(
                  label: 'Pad angle',
                  value: _padAngle,
                  min: 0,
                  max: 0.12,
                  display: '${(_padAngle * 180 / math.pi).toStringAsFixed(1)}°',
                  onChanged: (v) => setState(() => _padAngle = v),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sort slices descending'),
                  value: _sortPie,
                  onChanged: (v) => setState(() => _sortPie = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStackCard(ThemeData theme, List<Color> palette) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 300,
            child: CustomPaint(
              painter: _StreamgraphPainter(
                offsetKind: _offsetKind,
                orderKind: _orderKind,
                smooth: _smoothStack,
                palette: palette,
                axisColor: theme.colorScheme.outlineVariant,
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
                Text('Stack offset', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final o in _StackOffsetKind.values)
                      ChoiceChip(
                        label: Text(o.label),
                        selected: _offsetKind == o,
                        onSelected: (_) => setState(() => _offsetKind = o),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Stack order', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final r in _StackOrderKind.values)
                      ChoiceChip(
                        label: Text(r.label),
                        selected: _orderKind == r,
                        onSelected: (_) => setState(() => _orderKind = r),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Smooth basis curve'),
                  value: _smoothStack,
                  onChanged: (v) => setState(() => _smoothStack = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymbolsLinksCard(ThemeData theme, List<Color> palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Text(
                  'All 13 Built-In Symbols (7 Fill + 7 Stroke)',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              SizedBox(
                height: 180,
                child: CustomPaint(
                  painter: _SymbolsPainter(
                    symbolSize: _symbolSize,
                    palette: palette,
                    labelColor: theme.colorScheme.onSurfaceVariant,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: _SliderRow(
                  label: 'Symbol area',
                  value: _symbolSize,
                  min: 32,
                  max: 420,
                  display: '${_symbolSize.round()} px²',
                  onChanged: (v) => setState(() => _symbolSize = v),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Text(
                  'Tree & Hierarchy Links',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              SizedBox(
                height: 240,
                child: CustomPaint(
                  painter: _LinksPainter(
                    mode: _linkMode,
                    strokeColor: theme.colorScheme.primary,
                    nodeColor: theme.colorScheme.tertiary,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in _LinkMode.values)
                      ChoiceChip(
                        label: Text(m.label),
                        selected: _linkMode == m,
                        onSelected: (_) => setState(() => _linkMode = m),
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

class _CurvesPainter({
  required final d3s.CurveFactory curve,
  required final bool fillArea,
  required final bool showPoints,
  required final Color strokeColor,
  required final Color fillColor,
  required final Color dotColor,
  required final Color gridColor,
}) extends CustomPainter {
  static const _normY = <double>[
    0.72,
    0.26,
    0.58,
    0.16,
    0.64,
    0.34,
    0.80,
    0.22,
    0.48,
    0.30,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const padX = 36.0;
    const padY = 28.0;
    final w = size.width - padX * 2;
    final h = size.height - padY * 2;
    final baseY = size.height - padY;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; ++i) {
      final y = padY + h * i / 4;
      canvas.drawLine(Offset(padX, y), Offset(size.width - padX, y), gridPaint);
    }

    final pts = <(double, double)>[
      for (var i = 0; i < _normY.length; ++i)
        (padX + w * i / (_normY.length - 1), padY + h * _normY[i]),
    ];

    if (fillArea) {
      final areaGen = d3s.area<(double, double)>()
        ..x = ((p, _, _) => p.$1)
        ..y0Const(baseY)
        ..y1 = ((p, _, _) => p.$2)
        ..curve = curve;
      canvas.drawPath(
        areaGen.toUiPath(pts),
        Paint()
          ..color = fillColor
          ..style = PaintingStyle.fill,
      );
    }

    final lineGen = d3s.line<(double, double)>()
      ..x = ((p, _, _) => p.$1)
      ..y = ((p, _, _) => p.$2)
      ..curve = curve;
    canvas.drawPath(
      lineGen.toUiPath(pts),
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    if (showPoints) {
      final dotPaint = Paint()..color = dotColor;
      for (final (px, py) in pts) {
        canvas.drawCircle(Offset(px, py), 4.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CurvesPainter oldDelegate) => true;
}

class _ArcPiePainter({
  required final double innerRatio,
  required final double cornerRadius,
  required final double padAngle,
  required final bool sortPie,
  required final List<Color> palette,
  required final Color labelColor,
}) extends CustomPainter {
  static const _slices = <(String, double)>[
    ('A', 28),
    ('B', 19),
    ('C', 15),
    ('D', 12),
    ('E', 9),
    ('F', 6),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final outer = math.min(size.width, size.height) * 0.41;
    final inner = outer * innerRatio;
    final pieGen = d3s.pie<(String, double)>()
      ..value = ((d, _, _) => d.$2)
      ..padAngleConst(padAngle);
    if (!sortPie) pieGen.sortValues = null;

    final arcs = pieGen(_slices);
    final arcGen = d3s.arc<d3s.PieArc<(String, double)>>()
      ..innerRadiusConst(inner)
      ..outerRadiusConst(outer)
      ..cornerRadiusConst(cornerRadius);

    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2);

    final ctx = d3p.uiPathContext();
    arcGen.context = ctx;
    for (var i = 0; i < arcs.length; ++i) {
      final slice = arcs[i];
      ctx.reset();
      arcGen(slice);
      canvas.drawPath(
        ctx.path,
        Paint()
          ..color = palette[i % palette.length]
          ..style = PaintingStyle.fill,
      );

      final (cx, cy) = arcGen.centroid(slice);
      final tp = TextPainter(
        text: TextSpan(
          text: '${slice.data.$1} ${slice.data.$2.round()}',
          style: TextStyle(
            color: labelColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ArcPiePainter oldDelegate) => true;
}

class _StreamgraphPainter({
  required final _StackOffsetKind offsetKind,
  required final _StackOrderKind orderKind,
  required final bool smooth,
  required final List<Color> palette,
  required final Color axisColor,
}) extends CustomPainter {
  static final _rows = List<List<double>>.generate(18, (x) {
    return List<double>.generate(6, (k) {
      final phase = (x - k * 2.3) / 3.4;
      final base =
          12.0 +
          28.0 * math.exp(-phase * phase * 0.45) +
          6.0 * math.sin(x * 0.6 + k);
      return base;
    });
  });

  static final _divergingRows = List<List<double>>.generate(18, (x) {
    return List<double>.generate(6, (k) {
      final v = 10.0 + 18.0 * math.sin(x * 0.55 + k * 1.1);
      return k.isEven ? v : -v * 0.85;
    });
  });

  @override
  void paint(Canvas canvas, Size size) {
    const padX = 24.0;
    const padY = 20.0;
    final data = offsetKind == _StackOffsetKind.diverging
        ? _divergingRows
        : _rows;

    final offset = switch (offsetKind) {
      _StackOffsetKind.wiggle => d3s.stackOffsetWiggle,
      _StackOffsetKind.silhouette => d3s.stackOffsetSilhouette,
      _StackOffsetKind.expand => d3s.stackOffsetExpand,
      _StackOffsetKind.none => d3s.stackOffsetNone,
      _StackOffsetKind.diverging => d3s.stackOffsetDiverging,
    };
    final order = switch (orderKind) {
      _StackOrderKind.insideOut => d3s.stackOrderInsideOut,
      _StackOrderKind.appearance => d3s.stackOrderAppearance,
      _StackOrderKind.ascending => d3s.stackOrderAscending,
      _StackOrderKind.descending => d3s.stackOrderDescending,
      _StackOrderKind.none => d3s.stackOrderNone,
      _StackOrderKind.reverse => d3s.stackOrderReverse,
    };

    final stacked = (d3s.stack<List<double>, int>()
      ..keysConst([0, 1, 2, 3, 4, 5])
      ..value = ((d, k, _, _) => d[k])
      ..order = order
      ..offset = offset)(data);

    var minY = double.infinity;
    var maxY = double.negativeInfinity;
    for (final s in stacked) {
      for (final p in s.points) {
        if (p.y0 < minY) minY = p.y0;
        if (p.y1 > maxY) maxY = p.y1;
        if (p.y1 < minY) minY = p.y1;
        if (p.y0 > maxY) maxY = p.y0;
      }
    }
    final spanY = (maxY - minY).abs() < 1e-6 ? 1.0 : maxY - minY;
    final w = size.width - padX * 2;
    final h = size.height - padY * 2;
    double mapX(int i) => padX + w * i / (data.length - 1);
    double mapY(double v) => padY + h * (1 - (v - minY) / spanY);

    if (minY < 0 && maxY > 0) {
      final zeroY = mapY(0);
      canvas.drawLine(
        Offset(padX, zeroY),
        Offset(size.width - padX, zeroY),
        Paint()
          ..color = axisColor
          ..strokeWidth = 1,
      );
    }

    final ctx = d3p.uiPathContext();
    final areaGen = d3s.area<d3s.StackPoint<List<double>>>()
      ..x = ((_, i, _) => mapX(i))
      ..y0 = ((p, _, _) => mapY(p.y0))
      ..y1 = ((p, _, _) => mapY(p.y1))
      ..curve = smooth ? d3s.curveBasis : d3s.curveLinear
      ..context = ctx;

    for (var i = 0; i < stacked.length; ++i) {
      ctx.reset();
      areaGen(stacked[i].points);
      canvas.drawPath(
        ctx.path,
        Paint()
          ..color = palette[i % palette.length].withValues(alpha: 0.88)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StreamgraphPainter oldDelegate) => true;
}

class _SymbolsPainter({
  required final double symbolSize,
  required final List<Color> palette,
  required final Color labelColor,
}) extends CustomPainter {
  static const _fillNames = [
    'circle',
    'cross',
    'diamond',
    'square',
    'star',
    'triangle',
    'wye',
  ];
  static const _strokeNames = [
    'circle',
    'plus',
    'times',
    'triangle2',
    'asterisk',
    'square2',
    'diamond2',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final ctx = d3p.uiPathContext();

    void drawRow(
      List<d3s.SymbolType> types,
      List<String> names,
      double y,
      bool stroked,
    ) {
      final step = size.width / (types.length + 1);
      for (var i = 0; i < types.length; ++i) {
        final x = step * (i + 1);
        final gen = d3s.symbol<Object?>(types[i], symbolSize)..context = ctx;
        ctx.reset();
        gen();

        canvas
          ..save()
          ..translate(x, y);
        final paint = Paint()
          ..color = palette[i % palette.length]
          ..style = stroked ? PaintingStyle.stroke : PaintingStyle.fill
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        canvas
          ..drawPath(ctx.path, paint)
          ..restore();

        final tp = TextPainter(
          text: TextSpan(
            text: names[i],
            style: TextStyle(color: labelColor, fontSize: 11),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, y + 22));
      }
    }

    drawRow(d3s.symbolsFill, _fillNames, 48, false);
    drawRow(d3s.symbolsStroke, _strokeNames, 130, true);
  }

  @override
  bool shouldRepaint(covariant _SymbolsPainter oldDelegate) => true;
}

class _LinksPainter({
  required final _LinkMode mode,
  required final Color strokeColor,
  required final Color nodeColor,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = strokeColor.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final dot = Paint()..color = nodeColor;
    final ctx = d3p.uiPathContext();

    if (mode == _LinkMode.radial) {
      final r1 = math.min(size.width, size.height) * 0.20;
      final r2 = math.min(size.width, size.height) * 0.42;
      final gen =
          d3s.linkRadial<d3s.LinkData<(double, double)>, (double, double)>()
            ..context = ctx;

      canvas
        ..save()
        ..translate(size.width / 2, size.height / 2);

      const branches = 3;
      const leavesPerBranch = 4;
      for (var b = 0; b < branches; ++b) {
        final ba = (b / branches) * math.pi * 2;
        ctx.reset();
        gen(d3s.LinkData(source: (ba, 0), target: (ba, r1)));
        canvas.drawPath(ctx.path, stroke);

        final (bx, by) = d3s.pointRadial(ba, r1);
        canvas.drawCircle(Offset(bx, by), 4.5, dot);

        for (var l = 0; l < leavesPerBranch; ++l) {
          final spread = (l - (leavesPerBranch - 1) / 2) * 0.36;
          final la = ba + spread;
          ctx.reset();
          gen(d3s.LinkData(source: (ba, r1), target: (la, r2)));
          canvas.drawPath(ctx.path, stroke);
          final (lx, ly) = d3s.pointRadial(la, r2);
          canvas.drawCircle(Offset(lx, ly), 3.5, dot);
        }
      }
      canvas
        ..drawCircle(Offset.zero, 5.5, dot)
        ..restore();
      return;
    }

    final horiz = mode == _LinkMode.horizontal;
    final gen =
        (horiz
              ? d3s
                    .linkHorizontal<
                      d3s.LinkData<(double, double)>,
                      (double, double)
                    >()
              : d3s
                    .linkVertical<
                      d3s.LinkData<(double, double)>,
                      (double, double)
                    >())
          ..context = ctx;

    const pad = 32.0;
    final root = horiz ? (pad, size.height / 2) : (size.width / 2, pad);
    final midNodes = [
      for (var i = 0; i < 3; ++i)
        if (horiz)
          (size.width * 0.48, pad + (size.height - pad * 2) * (i + 0.5) / 3)
        else
          (pad + (size.width - pad * 2) * (i + 0.5) / 3, size.height * 0.5),
    ];
    final leaves = [
      for (var i = 0; i < 6; ++i)
        if (horiz)
          (size.width - pad, pad + (size.height - pad * 2) * (i + 0.5) / 6)
        else
          (pad + (size.width - pad * 2) * (i + 0.5) / 6, size.height - pad),
    ];

    for (var i = 0; i < midNodes.length; ++i) {
      ctx.reset();
      gen(d3s.LinkData(source: root, target: midNodes[i]));
      canvas.drawPath(ctx.path, stroke);
      for (var k = 0; k < 2; ++k) {
        final leaf = leaves[i * 2 + k];
        ctx.reset();
        gen(d3s.LinkData(source: midNodes[i], target: leaf));
        canvas
          ..drawPath(ctx.path, stroke)
          ..drawCircle(Offset(leaf.$1, leaf.$2), 3.5, dot);
      }
      canvas.drawCircle(Offset(midNodes[i].$1, midNodes[i].$2), 4.5, dot);
    }
    canvas.drawCircle(Offset(root.$1, root.$2), 5.5, dot);
  }

  @override
  bool shouldRepaint(covariant _LinksPainter oldDelegate) => true;
}
