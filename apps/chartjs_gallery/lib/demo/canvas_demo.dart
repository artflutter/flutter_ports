// The reason of each import of lib/src is the comment above it.
// ignore_for_file: implementation_imports

import 'dart:math' as math;

import 'package:chartjs_gallery/demo/demo_chart.dart';
import 'package:chartjs_gallery/demo/demo_common.dart';
import 'package:chartjs_gallery/demo/demo_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_chartjs_port/helpers.dart'
    show
        addRoundedRectPath,
        clipArea,
        drawPoint,
        drawPointLegend,
        renderText,
        splineCurveMonotone,
        toFont,
        unclipArea;
// Not public: UiCanvasElement, a canvas with no chart (Chart.js ADR 0048).
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
// Not public: the upstream `_` helpers _bezierCurveTo and _steppedLineTo.
import 'package:flutter_chartjs_port/src/helpers/index.dart'
    show bezierCurveTo, steppedLineTo;

/// The Chart.js sample colors.
const List<String> chartColors = [
  '#36A2EB',
  '#FF6384',
  '#4BC0C0',
  '#FF9F40',
  '#9966FF',
  '#FFCD56',
  '#C9CBCF',
];

/// The color of the labels that the demos draw on the canvas: the Chart.js
/// default `color`.
const String labelColor = '#666';

/// A label under a drawing, with `renderText` and the default font.
void drawCaption(
  CanvasRenderingContext2D ctx,
  String text,
  double x,
  double y,
) {
  renderText(
    ctx,
    text,
    x,
    y,
    toFont(<String, Object?>{'size': 12}),
    const TextOpts(
      color: labelColor,
      textAlign: 'center',
      textBaseline: 'bottom',
    ),
  );
}

/// The canvas layer and the canvas helpers: point styles, text, rounded
/// rectangles, stepped and Bézier lines, clipping, gradients, patterns and
/// line dashes.
///
/// Every drawing goes through the ported `helpers.canvas` on the
/// `UiCanvasContext` of a chart host.
class CanvasDemo extends StatelessWidget {
  /// Creates the canvas tab.
  const CanvasDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const DemoPageBody(
      children: [
        _PointStylesCard(),
        _RenderTextCard(),
        _RoundedRectCard(),
        _LinesCard(),
        _ClipCard(),
        _PaintCard(),
      ],
    );
  }
}

// Point styles.

/// The point styles of `PointStyle` (index.d.ts:2040), `false`, and an
/// image.
const List<String> pointStyleNames = [
  'circle',
  'cross',
  'crossRot',
  'dash',
  'line',
  'rect',
  'rectRounded',
  'rectRot',
  'star',
  'triangle',
  'false',
  'image',
];

class _PointStylesCard extends StatefulWidget {
  const _PointStylesCard();

  @override
  State<_PointStylesCard> createState() => _PointStylesCardState();
}

class _PointStylesCardState extends State<_PointStylesCard> {
  final Set<String> _on = {...pointStyleNames};
  double _radius = 14;
  double _rotation = 0;
  double _borderWidth = 2;
  double _w = 0;
  late final UiImageSource _image = _makeIcon();

  /// The image point style: a canvas drawn with the canvas helpers, then
  /// read back as an image (`UiCanvasElement.toImageSource`).
  static UiImageSource _makeIcon() {
    final canvas = UiCanvasElement(width: 32, height: 32);
    final ctx = canvas.getContext2d();
    final gradient = ctx.createRadialGradient(11, 10, 2, 16, 16, 16)
      ..addColorStop(0, '#FFE29A')
      ..addColorStop(1, '#FF6384');
    ctx
      ..fillStyle = gradient
      ..beginPath()
      ..arc(16, 16, 15, 0, 2 * math.pi)
      ..fill()
      ..fillStyle = '#FFFFFF'
      ..strokeStyle = '#FFFFFF'
      ..lineWidth = 2.5;
    drawPoint(
      ctx,
      const PointOptions(pointStyle: 'star', radius: 9, borderWidth: 2.5),
      16,
      16,
    );
    final source = canvas.toImageSource();
    ctx.dispose();
    return source;
  }

  @override
  void dispose() {
    _image.image.dispose();
    super.dispose();
  }

  Object? _style(String name) => switch (name) {
    'false' => false,
    'image' => _image,
    _ => name,
  };

  void _draw(DemoChart chart, CanvasRenderingContext2D ctx) {
    final styles = [
      for (final name in pointStyleNames)
        if (_on.contains(name)) name,
    ];
    final (columns, cellWidth) = _grid(chart.width);
    const cellHeight = _cellHeight;
    for (var i = 0; i < styles.length; i++) {
      final left = (i % columns) * cellWidth;
      final top = (i ~/ columns) * cellHeight;
      final x = left + cellWidth / 2;
      final y = top + (cellHeight - 18) / 2;
      ctx
        ..strokeStyle = 'rgba(0, 0, 0, 0.08)'
        ..lineWidth = 1
        ..strokeRect(left + 3.5, top + 3.5, cellWidth - 7, cellHeight - 7)
        ..fillStyle = 'rgba(54, 162, 235, 0.35)'
        ..strokeStyle = '#36A2EB'
        ..lineWidth = _borderWidth;
      drawPointLegend(
        ctx,
        PointOptions(
          pointStyle: _style(styles[i]),
          radius: _radius,
          borderWidth: _borderWidth,
          rotation: _rotation,
        ),
        x,
        y,
        _w > 0 ? _w : null,
      );
      drawCaption(ctx, styles[i], x, top + cellHeight - 6);
    }
  }

  static const double _cellHeight = 96;

  static (int, double) _grid(double width) {
    final columns = math.max(1, (width / 96).floor());
    return (columns, width / columns);
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Point styles',
      source:
          'helpers.canvas: drawPointLegend(ctx, {pointStyle, radius, '
          'rotation, borderWidth}, x, y, w) · drawPoint · '
          'UiCanvasElement.toImageSource() for the image style',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ToggleChips(
            toggles: [
              for (final name in pointStyleNames)
                (
                  key: 'canvas.style.$name',
                  label: name,
                  value: _on.contains(name),
                  onChanged: (on) => setState(
                    () => on ? _on.add(name) : _on.remove(name),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          DemoControlGrid(
            children: [
              SliderControl(
                label: 'radius',
                sliderKey: const ValueKey('canvas.radius'),
                value: _radius,
                min: 0,
                max: 40,
                divisions: 40,
                onChanged: (v) => setState(() => _radius = v),
              ),
              SliderControl(
                label: 'rotation',
                sliderKey: const ValueKey('canvas.rotation'),
                value: _rotation,
                min: 0,
                max: 360,
                divisions: 72,
                format: (v) => '${v.toStringAsFixed(0)}°',
                onChanged: (v) => setState(() => _rotation = v),
              ),
              SliderControl(
                label: 'borderWidth',
                sliderKey: const ValueKey('canvas.borderWidth'),
                value: _borderWidth,
                min: 0,
                max: 8,
                divisions: 16,
                format: (v) => v.toStringAsFixed(1),
                onChanged: (v) => setState(() => _borderWidth = v),
              ),
              SliderControl(
                label: 'legend w',
                sliderKey: const ValueKey('canvas.legendWidth'),
                value: _w,
                min: 0,
                max: 80,
                divisions: 40,
                format: (v) => v == 0 ? 'null' : v.toStringAsFixed(0),
                onChanged: (v) => setState(() => _w = v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final (columns, _) = _grid(constraints.maxWidth);
              final count = _on.length;
              final rows = math.max(1, (count / columns).ceil());
              return DemoCanvas(
                key: const ValueKey('canvas.pointStyles'),
                height: rows * _cellHeight,
                draw: _draw,
              );
            },
          ),
        ],
      ),
    );
  }
}

// renderText.

class _RenderTextCard extends StatefulWidget {
  const _RenderTextCard();

  @override
  State<_RenderTextCard> createState() => _RenderTextCardState();
}

class _RenderTextCardState extends State<_RenderTextCard> {
  bool _underline = false;
  bool _strikethrough = false;
  bool _stroke = true;
  bool _backdrop = true;
  bool _maxWidth = false;
  bool _multiLine = false;
  double _rotation = 0;

  static const double _maxWidthValue = 140;

  void _draw(DemoChart chart, CanvasRenderingContext2D ctx) {
    final font = toFont(<String, Object?>{'size': 26, 'weight': 'bold'});
    final lines = _multiLine
        ? const ['Chart.js', 'renderText', 'on a canvas']
        : const ['Chart.js renderText'];
    final x = chart.width / 2;
    final y = chart.height / 2;
    final lineHeight = font.lineHeight;
    // renderText advances y by the line height after each line.
    final firstY = y - (lines.length - 1) * lineHeight / 2;

    // The backdrop is in the rotated space of the label, as core.scale
    // draws it: around the anchor.
    ctx.font = font.string;
    var widest = 0.0;
    for (final line in lines) {
      widest = math.max(widest, ctx.measureText(line).width);
    }
    if (_maxWidth) widest = math.min(widest, _maxWidthValue);
    final backdropTop = firstY - y - lineHeight / 2 - 4;
    final rotation = _rotation * math.pi / 180;

    // The anchor and, with maxWidth, its width.
    ctx
      ..save()
      ..translate(x, y)
      ..rotate(rotation)
      ..strokeStyle = 'rgba(255, 99, 132, 0.6)'
      ..lineWidth = 1
      ..setLineDash([4, 4])
      ..beginPath()
      ..moveTo(-chart.width, 0)
      ..lineTo(chart.width, 0)
      ..moveTo(0, -chart.height)
      ..lineTo(0, chart.height);
    if (_maxWidth) {
      ctx
        ..moveTo(-_maxWidthValue / 2, -chart.height)
        ..lineTo(-_maxWidthValue / 2, chart.height)
        ..moveTo(_maxWidthValue / 2, -chart.height)
        ..lineTo(_maxWidthValue / 2, chart.height);
    }
    ctx
      ..stroke()
      ..restore();

    renderText(
      ctx,
      lines.length == 1 ? lines.first : lines,
      0,
      firstY - y,
      font,
      TextOpts(
        translation: (x, y),
        rotation: rotation,
        color: '#36A2EB',
        textAlign: 'center',
        textBaseline: 'middle',
        underline: _underline,
        strikethrough: _strikethrough,
        decorationWidth: 3,
        strokeColor: _stroke ? '#FFFFFF' : null,
        strokeWidth: _stroke ? 6 : null,
        maxWidth: _maxWidth ? _maxWidthValue : null,
        backdrop: _backdrop
            ? Backdrop(
                -widest / 2 - 8,
                backdropTop,
                widest + 16,
                lines.length * lineHeight + 8,
                'rgba(255, 206, 86, 0.35)',
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'renderText',
      source:
          'helpers.canvas: renderText(ctx, text, x, y, toFont(…), '
          '{translation, rotation, color, strokeColor, strokeWidth, '
          'maxWidth, underline, strikethrough, backdrop})',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ToggleChips(
            toggles: [
              (
                key: 'canvas.text.underline',
                label: 'underline',
                value: _underline,
                onChanged: (v) => setState(() => _underline = v),
              ),
              (
                key: 'canvas.text.strikethrough',
                label: 'strikethrough',
                value: _strikethrough,
                onChanged: (v) => setState(() => _strikethrough = v),
              ),
              (
                key: 'canvas.text.stroke',
                label: 'stroke',
                value: _stroke,
                onChanged: (v) => setState(() => _stroke = v),
              ),
              (
                key: 'canvas.text.backdrop',
                label: 'backdrop',
                value: _backdrop,
                onChanged: (v) => setState(() => _backdrop = v),
              ),
              (
                key: 'canvas.text.maxWidth',
                label: 'maxWidth 140',
                value: _maxWidth,
                onChanged: (v) => setState(() => _maxWidth = v),
              ),
              (
                key: 'canvas.text.multiLine',
                label: 'multi-line',
                value: _multiLine,
                onChanged: (v) => setState(() => _multiLine = v),
              ),
            ],
          ),
          SliderControl(
            label: 'rotation',
            sliderKey: const ValueKey('canvas.text.rotation'),
            value: _rotation,
            min: -90,
            max: 90,
            divisions: 36,
            format: (v) => '${v.toStringAsFixed(0)}°',
            onChanged: (v) => setState(() => _rotation = v),
          ),
          DemoCanvas(
            key: const ValueKey('canvas.renderText'),
            height: 200,
            draw: _draw,
          ),
        ],
      ),
    );
  }
}

// addRoundedRectPath.

class _RoundedRectCard extends StatefulWidget {
  const _RoundedRectCard();

  @override
  State<_RoundedRectCard> createState() => _RoundedRectCardState();
}

class _RoundedRectCardState extends State<_RoundedRectCard> {
  final Map<String, double> _radii = {
    'topLeft': 24,
    'topRight': 4,
    'bottomLeft': 4,
    'bottomRight': 48,
  };

  void _draw(DemoChart chart, CanvasRenderingContext2D ctx) {
    final w = math.min(chart.width - 32, 420);
    const h = 128.0;
    final x = (chart.width - w) / 2;
    const y = 16.0;
    ctx
      ..fillStyle = 'rgba(75, 192, 192, 0.35)'
      ..strokeStyle = '#4BC0C0'
      ..lineWidth = 3
      ..beginPath();
    addRoundedRectPath(
      ctx,
      RoundedBox(
        x,
        y,
        w.toDouble(),
        h,
        Corners(
          topLeft: _radii['topLeft']!,
          topRight: _radii['topRight']!,
          bottomLeft: _radii['bottomLeft']!,
          bottomRight: _radii['bottomRight']!,
        ),
      ),
    );
    ctx
      ..fill()
      ..stroke();
    drawCaption(
      ctx,
      'addRoundedRectPath(ctx, {x, y, w, h, radius})',
      chart.width / 2,
      chart.height - 4,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Rounded rectangles',
      source:
          'helpers.canvas: addRoundedRectPath, the path of bars, legend '
          'boxes and tooltips',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DemoControlGrid(
            minColumnWidth: 240,
            maxColumns: 4,
            children: [
              for (final corner in _radii.keys)
                SliderControl(
                  label: corner,
                  sliderKey: ValueKey('canvas.radius.$corner'),
                  value: _radii[corner]!,
                  min: 0,
                  max: 64,
                  divisions: 32,
                  onChanged: (v) => setState(() => _radii[corner] = v),
                ),
            ],
          ),
          DemoCanvas(
            key: const ValueKey('canvas.roundedRect'),
            height: 172,
            draw: _draw,
          ),
        ],
      ),
    );
  }
}

// _steppedLineTo and _bezierCurveTo.

/// The points of the lines, in fractions of a lane.
const List<(double, double)> _linePoints = [
  (0.03, 0.75),
  (0.17, 0.30),
  (0.31, 0.55),
  (0.45, 0.20),
  (0.59, 0.85),
  (0.73, 0.60),
  (0.87, 0.65),
  (0.97, 0.15),
];

class _LinesCard extends StatefulWidget {
  const _LinesCard();

  @override
  State<_LinesCard> createState() => _LinesCardState();
}

class _LinesCardState extends State<_LinesCard> {
  bool _path2d = false;

  static const List<(String, String)> _modes = [
    ('before', "_steppedLineTo, stepped: 'before'"),
    ('after', "_steppedLineTo, stepped: 'after'"),
    ('middle', "_steppedLineTo, stepped: 'middle'"),
    ('bezier', "_bezierCurveTo, cubicInterpolationMode: 'monotone'"),
  ];

  static const double _laneHeight = 92;

  void _draw(DemoChart chart, CanvasRenderingContext2D ctx) {
    for (var lane = 0; lane < _modes.length; lane++) {
      final (mode, caption) = _modes[lane];
      final top = lane * _laneHeight;
      final points = [
        for (final (fx, fy) in _linePoints)
          CurvePoint(
            12 + fx * (chart.width - 24),
            top + 20 + fy * (_laneHeight - 30),
          ),
      ];
      if (mode == 'bezier') {
        splineCurveMonotone(points);
      }
      final color = chartColors[lane];
      // A Path2D or the current path: _steppedLineTo and _bezierCurveTo
      // take a CanvasPath, as element.line.js passes both.
      final path = _path2d ? Path2D() : ctx;
      if (!_path2d) ctx.beginPath();
      path.moveTo(points.first.x, points.first.y);
      for (var i = 1; i < points.length; i++) {
        if (mode == 'bezier') {
          bezierCurveTo(path, points[i - 1], points[i]);
        } else {
          steppedLineTo(path, points[i - 1], points[i], false, mode);
        }
      }
      ctx
        ..strokeStyle = color
        ..lineWidth = 2.5
        ..lineJoin = 'round';
      if (path is Path2D) {
        ctx.stroke(path);
      } else {
        ctx.stroke();
      }
      ctx
        ..fillStyle = '#FFFFFF'
        ..lineWidth = 2;
      for (final point in points) {
        drawPoint(
          ctx,
          const PointOptions(pointStyle: 'circle', radius: 3.5, borderWidth: 2),
          point.x,
          point.y,
        );
      }
      renderText(
        ctx,
        caption,
        12,
        top + 4,
        toFont(<String, Object?>{'size': 12}),
        const TextOpts(color: labelColor, textBaseline: 'top'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Stepped and Bézier lines',
      source:
          'helpers.canvas: _steppedLineTo(ctx, previous, target, flip, mode) · '
          '_bezierCurveTo(ctx, previous, target) · helpers.curve: '
          'splineCurveMonotone',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ToggleChips(
            toggles: [
              (
                key: 'canvas.lines.path2d',
                label: 'draw into a Path2D',
                value: _path2d,
                onChanged: (v) => setState(() => _path2d = v),
              ),
            ],
          ),
          DemoCanvas(
            key: const ValueKey('canvas.lines'),
            height: _modes.length * _laneHeight,
            draw: _draw,
          ),
        ],
      ),
    );
  }
}

// clipArea.

class _ClipCard extends StatefulWidget {
  const _ClipCard();

  @override
  State<_ClipCard> createState() => _ClipCardState();
}

class _ClipCardState extends State<_ClipCard> {
  bool _clip = true;
  double _inset = 36;

  void _draw(DemoChart chart, CanvasRenderingContext2D ctx) {
    final area = Box(
      _inset * 1.6,
      _inset,
      chart.width - _inset * 1.6,
      chart.height - _inset,
    );
    if (_clip) clipArea(ctx, area);
    // Content that overflows the area on every side.
    ctx.lineWidth = 6;
    for (var i = -10; i < 40; i++) {
      ctx
        ..strokeStyle = chartColors[i % chartColors.length]
        ..beginPath()
        ..moveTo(i * 28.0, 0)
        ..lineTo(i * 28.0 - chart.height, chart.height)
        ..stroke();
    }
    ctx
      ..fillStyle = 'rgba(255, 99, 132, 0.55)'
      ..beginPath()
      ..arc(area.left, area.top, 48, 0, 2 * math.pi)
      ..fill()
      ..beginPath()
      ..arc(area.right, area.bottom, 48, 0, 2 * math.pi)
      ..fill();
    if (_clip) unclipArea(ctx);
    ctx
      ..strokeStyle = '#333333'
      ..lineWidth = 1.5
      ..setLineDash([6, 4])
      ..strokeRect(area.left, area.top, area.width, area.height)
      ..setLineDash([]);
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Clipping',
      source:
          'helpers.canvas: clipArea(ctx, area) · unclipArea(ctx), the '
          'chart area clip of the dataset draw',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ToggleChips(
            toggles: [
              (
                key: 'canvas.clip.on',
                label: 'clipArea',
                value: _clip,
                onChanged: (v) => setState(() => _clip = v),
              ),
            ],
          ),
          SliderControl(
            label: 'inset',
            sliderKey: const ValueKey('canvas.clip.inset'),
            value: _inset,
            min: 0,
            max: 64,
            divisions: 32,
            onChanged: (v) => setState(() => _inset = v),
          ),
          DemoCanvas(
            key: const ValueKey('canvas.clip'),
            height: 200,
            draw: _draw,
          ),
        ],
      ),
    );
  }
}

// Gradients, patterns and line dashes.

class _PaintCard extends StatefulWidget {
  const _PaintCard();

  @override
  State<_PaintCard> createState() => _PaintCardState();
}

class _PaintCardState extends State<_PaintCard>
    with SingleTickerProviderStateMixin {
  late final UiImageSource _tile = _makeTile();
  late final _ticker = createTicker(_tick);
  DemoChart? _chart;
  bool _animate = true;
  double _offset = 0;

  static const List<String> _panels = [
    'createLinearGradient',
    'createRadialGradient',
    'createConicGradient',
    'createPattern',
    'setLineDash',
  ];

  /// The pattern tile: a small canvas with stripes, read back as an image.
  static UiImageSource _makeTile() {
    final canvas = UiCanvasElement(width: 16, height: 16);
    final ctx = canvas.getContext2d()
      ..fillStyle = '#FFF4E0'
      ..fillRect(0, 0, 16, 16)
      ..strokeStyle = '#FF9F40'
      ..lineWidth = 3
      ..lineCap = 'square'
      ..beginPath()
      ..moveTo(-4, 4)
      ..lineTo(4, -4)
      ..moveTo(-4, 20)
      ..lineTo(20, -4)
      ..moveTo(12, 20)
      ..lineTo(20, 12)
      ..stroke();
    final source = canvas.toImageSource();
    ctx.dispose();
    return source;
  }

  @override
  void initState() {
    super.initState();
    if (_animate) _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _tile.image.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    _offset = elapsed.inMicroseconds / 1e6 * 24;
    // Only the chart draws again: no rebuild.
    _chart?.render();
  }

  static (int, double) _grid(double width) {
    final columns = width >= 760
        ? 5
        : width >= 440
        ? 3
        : 2;
    return (columns, width / columns);
  }

  static double _panelSize(double cellWidth) => math.min(cellWidth - 20, 140);

  void _draw(DemoChart chart, CanvasRenderingContext2D ctx) {
    final (columns, cellWidth) = _grid(chart.width);
    final size = _panelSize(cellWidth);
    final cellHeight = size + 36;
    for (var i = 0; i < _panels.length; i++) {
      final cx = (i % columns) * cellWidth + cellWidth / 2;
      final top = (i ~/ columns) * cellHeight + 8;
      final left = cx - size / 2;
      final cy = top + size / 2;
      switch (_panels[i]) {
        case 'createLinearGradient':
          final g = ctx.createLinearGradient(left, top, left + size, top + size)
            ..addColorStop(0, '#36A2EB')
            ..addColorStop(0.5, '#9966FF')
            ..addColorStop(1, '#FF6384');
          ctx
            ..fillStyle = g
            ..fillRect(left, top, size, size);
        case 'createRadialGradient':
          final g =
              ctx.createRadialGradient(
                  cx - size * 0.15,
                  cy - size * 0.15,
                  size * 0.05,
                  cx,
                  cy,
                  size / 2,
                )
                ..addColorStop(0, '#FFFFFF')
                ..addColorStop(0.4, '#FFCD56')
                ..addColorStop(1, '#FF9F40');
          ctx
            ..fillStyle = g
            ..beginPath()
            ..arc(cx, cy, size / 2, 0, 2 * math.pi)
            ..fill();
        case 'createConicGradient':
          final g = ctx.createConicGradient(-math.pi / 2, cx, cy);
          for (var c = 0; c < 6; c++) {
            g.addColorStop(c / 6, chartColors[c]);
          }
          g.addColorStop(1, chartColors[0]);
          ctx
            ..fillStyle = g
            ..beginPath()
            ..arc(cx, cy, size / 2, 0, 2 * math.pi)
            ..fill();
        case 'createPattern':
          ctx
            ..fillStyle = ctx.createPattern(_tile, 'repeat')
            ..strokeStyle = '#FF9F40'
            ..lineWidth = 2
            ..beginPath();
          addRoundedRectPath(
            ctx,
            RoundedBox(
              left,
              top,
              size,
              size,
              Corners(
                topLeft: size / 5,
                topRight: size / 5,
                bottomLeft: size / 5,
                bottomRight: size / 5,
              ),
            ),
          );
          ctx
            ..fill()
            ..stroke();
        case 'setLineDash':
          ctx
            ..strokeStyle = '#4BC0C0'
            ..lineWidth = 3
            ..setLineDash([10, 6])
            ..lineDashOffset = -_offset
            ..strokeRect(left + 2, top + 2, size - 4, size - 4)
            ..strokeStyle = '#9966FF'
            ..lineCap = 'round'
            ..setLineDash([0.5, 9])
            ..lineWidth = 6
            ..lineDashOffset = _offset
            ..beginPath()
            ..arc(cx, cy, size * 0.3, 0, 2 * math.pi)
            ..stroke()
            ..setLineDash([])
            ..lineCap = 'butt';
      }
      drawCaption(ctx, _panels[i], cx, top + size + 24);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Gradients, patterns and line dashes',
      source:
          'UiCanvasContext: createLinearGradient · createRadialGradient · '
          'createConicGradient · addColorStop · createPattern(image, '
          "'repeat') · setLineDash · lineDashOffset (animated)",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ToggleChips(
            toggles: [
              (
                key: 'canvas.dash.animate',
                label: 'animate lineDashOffset',
                value: _animate,
                onChanged: (v) => setState(() {
                  _animate = v;
                  if (v) {
                    _ticker.start();
                  } else {
                    _ticker.stop();
                  }
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final (columns, cellWidth) = _grid(constraints.maxWidth);
              final rows = (_panels.length / columns).ceil();
              return DemoCanvas(
                key: const ValueKey('canvas.paint'),
                height: rows * (_panelSize(cellWidth) + 36) + 8,
                draw: _draw,
                onChart: (chart) => _chart = chart,
              );
            },
          ),
        ],
      ),
    );
  }
}
