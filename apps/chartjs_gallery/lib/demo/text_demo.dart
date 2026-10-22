// The package exports nothing from lib/src yet; the public API comes in
// phase 9. The demo imports the ported files directly.
// ignore_for_file: implementation_imports

import 'dart:math' as math;

import 'package:chartjs_gallery/demo/canvas_demo.dart'
    show chartColors, drawCaption, labelColor;
import 'package:chartjs_gallery/demo/demo_chart.dart';
import 'package:chartjs_gallery/demo/demo_common.dart';
import 'package:chartjs_gallery/demo/demo_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/helpers/index.dart'
    show
        LongestTextCache,
        ParsedFont,
        clipArea,
        drawPoint,
        getRtlAdapter,
        longestText,
        overrideTextDirection,
        prevTextDirectionOf,
        renderText,
        restoreTextDirection,
        toFont,
        unclipArea;
import 'package:flutter_chartjs_port/src/js/js_number.dart';

/// The `textAlign` values of the canvas.
const List<String> textAligns = ['left', 'center', 'right', 'start', 'end'];

/// The `textBaseline` values of the canvas.
const List<String> textBaselines = [
  'top',
  'hanging',
  'middle',
  'alphabetic',
  'ideographic',
  'bottom',
];

/// The labels of the `_longestText` card. A list is a multi-line label,
/// and `null` is skipped, as upstream.
const List<Object?> longestTextLabels = [
  'January',
  'February',
  ['Multi-line', 'label'],
  'Sept.',
  null,
  'December 2026',
];

/// Text on the canvas: `fillText` with every `textAlign` and
/// `textBaseline`, the `measureText` box, the RTL adapter and
/// `_longestText`.
class TextDemo extends StatefulWidget {
  /// Creates the text tab.
  const TextDemo({super.key});

  @override
  State<TextDemo> createState() => _TextDemoState();
}

class _TextDemoState extends State<TextDemo> {
  final TextEditingController _sample = TextEditingController(
    text: 'Hgjy Åb 12',
  );
  double _size = 18;
  bool _rtl = false;
  bool _clipCells = true;

  /// A canvas that no host shows, for the measurements of the readouts.
  final UiCanvasElement _measureCanvas = UiCanvasElement(width: 1, height: 1);
  final LongestTextCache _cache = LongestTextCache();

  @override
  void dispose() {
    _sample.dispose();
    _measureCanvas.getContext2d().dispose();
    super.dispose();
  }

  ParsedFont get _font => toFont(<String, Object?>{'size': _size});

  String get _text => _sample.text;

  /// `overrideTextDirection(ctx, 'rtl')` around [body], as the legend and
  /// the tooltip do (plugin.legend.js:391, :437). The restore passes the
  /// saved `[value, priority]`, so that the switch can turn RTL off again.
  void _withDirection(CanvasRenderingContext2D ctx, void Function() body) {
    if (_rtl) overrideTextDirection(ctx, 'rtl');
    body();
    final original = prevTextDirectionOf(ctx);
    if (original != null) restoreTextDirection(ctx, original);
  }

  // The textAlign x textBaseline grid.

  static double _labelWidth(double width) => width < 520 ? 74 : 96;

  double get _cellHeight => math.max(44, _size * 2.6);

  static const double _headerHeight = 24;

  void _drawGrid(DemoChart chart, CanvasRenderingContext2D ctx) {
    final labelWidth = _labelWidth(chart.width);
    final cellWidth = (chart.width - labelWidth) / textAligns.length;
    final cellHeight = _cellHeight;
    final small = toFont(<String, Object?>{'size': 12});
    final font = _font;
    for (var c = 0; c < textAligns.length; c++) {
      renderText(
        ctx,
        textAligns[c],
        labelWidth + (c + 0.5) * cellWidth,
        _headerHeight - 6,
        small,
        const TextOpts(
          color: labelColor,
          textAlign: 'center',
          textBaseline: 'bottom',
        ),
      );
    }
    _withDirection(ctx, () {
      for (var r = 0; r < textBaselines.length; r++) {
        final top = _headerHeight + r * cellHeight;
        renderText(
          ctx,
          textBaselines[r],
          4,
          top + cellHeight / 2,
          small,
          const TextOpts(
            color: labelColor,
            textAlign: 'left',
            textBaseline: 'middle',
          ),
        );
        for (var c = 0; c < textAligns.length; c++) {
          final left = labelWidth + c * cellWidth;
          final x = _anchorX(textAligns[c], left, cellWidth);
          final y = top + cellHeight / 2;
          ctx
            ..strokeStyle = 'rgba(0, 0, 0, 0.12)'
            ..lineWidth = 1
            ..strokeRect(left + 0.5, top + 0.5, cellWidth - 1, cellHeight - 1);
          if (_clipCells) {
            clipArea(ctx, Box(left, top, left + cellWidth, top + cellHeight));
          }
          // The alignment point: the baseline and the x of the anchor.
          ctx
            ..strokeStyle = 'rgba(255, 99, 132, 0.45)'
            ..beginPath()
            ..moveTo(left, y + 0.5)
            ..lineTo(left + cellWidth, y + 0.5)
            ..moveTo(x + 0.5, top)
            ..lineTo(x + 0.5, top + cellHeight)
            ..stroke()
            ..font = font.string
            ..textAlign = textAligns[c]
            ..textBaseline = textBaselines[r]
            ..fillStyle = '#333333'
            ..fillText(_text, x, y);
          final m = ctx.measureText(_text);
          ctx
            ..strokeStyle = '#36A2EB'
            ..strokeRect(
              x - m.actualBoundingBoxLeft,
              y - m.actualBoundingBoxAscent,
              m.actualBoundingBoxLeft + m.actualBoundingBoxRight,
              m.actualBoundingBoxAscent + m.actualBoundingBoxDescent,
            )
            ..fillStyle = '#FF6384';
          drawPoint(
            ctx,
            const PointOptions(
              pointStyle: 'circle',
              radius: 2.5,
              borderWidth: 0,
            ),
            x,
            y,
          );
          if (_clipCells) unclipArea(ctx);
        }
      }
    });
  }

  /// The x of the alignment point in a cell: the side that [align] puts
  /// the text against (`start` and `end` follow the direction).
  double _anchorX(String align, double left, double width) {
    const inset = 10.0;
    final side = switch (align) {
      'left' => -1,
      'right' => 1,
      'start' => _rtl ? 1 : -1,
      'end' => _rtl ? -1 : 1,
      _ => 0,
    };
    return left + width / 2 + side * (width / 2 - inset);
  }

  /// The width of the grid: each cell fits the sample text. A phone scrolls
  /// the grid sideways.
  double _gridWidth(double available, double textWidth) {
    final labelWidth = _labelWidth(available);
    final cellWidth = math.max(
      (available - labelWidth) / textAligns.length,
      textWidth + 28,
    );
    return labelWidth + cellWidth * textAligns.length;
  }

  // The RTL adapter.

  static const List<String> _legendItems = ['Red', 'Blue', 'Yellow', 'Green'];
  static const List<int> _legendColors = [1, 0, 5, 2];

  void _drawLegend(DemoChart chart, CanvasRenderingContext2D ctx) {
    final font = toFont(<String, Object?>{'size': 14});
    // plugin.legend.js:388 `getRtlAdapter(opts.rtl, this.left, this.width)`.
    final rtlHelper = getRtlAdapter(_rtl, 0, chart.width);
    _withDirection(ctx, () {
      ctx
        ..font = font.string
        ..textBaseline = 'middle';
      const boxWidth = 30.0;
      const boxHeight = 12.0;
      const y = 26.0;
      var x = 12.0;
      for (var i = 0; i < _legendItems.length; i++) {
        final text = _legendItems[i];
        final color = chartColors[_legendColors[i]];
        final textWidth = ctx.measureText(text).width;
        // plugin.legend.js:304 `rtlHelper.leftForLtr(x, boxWidth)`.
        final boxLeft = rtlHelper.leftForLtr(rtlHelper.x(x), boxWidth);
        ctx
          ..fillStyle = color
          ..globalAlpha = 0.4
          ..fillRect(boxLeft, y - boxHeight / 2, boxWidth, boxHeight)
          ..globalAlpha = 1
          ..strokeStyle = color
          ..lineWidth = 2
          ..strokeRect(boxLeft, y - boxHeight / 2, boxWidth, boxHeight)
          ..textAlign = rtlHelper.textAlign('left')! as String
          ..fillStyle = labelColor
          ..fillText(text, rtlHelper.x(x + boxWidth + 8), y);
        x += boxWidth + 8 + textWidth + 18;
      }
      // textAlign 'start' follows the direction of the canvas style.
      ctx
        ..textAlign = 'start'
        ..fillStyle = '#333333'
        ..fillText(
          "textAlign 'start', canvas style direction: "
          '${_styleDirection(ctx)}',
          rtlHelper.x(12),
          y + 32,
        );
    });
    drawCaption(
      ctx,
      'rtlHelper.x(x) = ${jsNumberToString(rtlHelper.x(12))} for x = 12',
      chart.width / 2,
      chart.height - 4,
    );
  }

  static String _styleDirection(CanvasRenderingContext2D ctx) {
    final value = ctx.canvas.style.getPropertyValue('direction');
    return value.isEmpty ? '(none)' : value;
  }

  // _longestText.

  static List<(String, bool)> _rows(List<Object?> labels) => [
    for (final label in labels)
      if (label is List)
        for (final line in label) ('$line', true)
      else if (label == null)
        ('null (skipped)', false)
      else
        (label as String, false),
  ];

  List<Object?> get _labels => [_text, ...longestTextLabels];

  void _drawLongest(DemoChart chart, CanvasRenderingContext2D ctx) {
    final font = _font;
    final rows = _rows(_labels);
    final rowHeight = _size * 1.5;
    final longest = longestText(ctx, font.string, _labels, _cache);
    ctx.font = font.string;
    var longestX = 8.0;
    for (var i = 0; i < rows.length; i++) {
      final (text, nested) = rows[i];
      final y = 8 + i * rowHeight;
      final skipped = text.startsWith('null');
      final width = skipped ? 0.0 : ctx.measureText(text).width;
      final isLongest = !skipped && (width - longest).abs() < 1e-9;
      final x = nested ? 20.0 : 8.0;
      if (isLongest) longestX = x;
      ctx
        ..fillStyle = isLongest
            ? 'rgba(255, 99, 132, 0.35)'
            : 'rgba(54, 162, 235, 0.18)'
        ..fillRect(x, y, width, rowHeight - 4)
        ..font = font.string
        ..textAlign = 'left'
        ..textBaseline = 'middle'
        ..fillStyle = skipped ? '#999999' : '#333333'
        ..fillText(text, x, y + (rowHeight - 4) / 2);
    }
    ctx
      ..strokeStyle = '#FF6384'
      ..lineWidth = 1.5
      ..setLineDash([4, 3])
      ..beginPath()
      ..moveTo(longestX + longest, 4)
      ..lineTo(longestX + longest, 8 + rows.length * rowHeight)
      ..stroke()
      ..setLineDash([]);
  }

  @override
  Widget build(BuildContext context) {
    final font = _font;
    final ctx = _measureCanvas.getContext2d()
      ..font = font.string
      ..textAlign = 'left'
      ..textBaseline = 'alphabetic';
    final metrics = ctx.measureText(_text);
    final longest = longestText(ctx, font.string, _labels, _cache);
    // + 0 turns -0 into 0.
    String px(double v) => (v + 0).toStringAsFixed(2);
    final rows = _rows(_labels);

    return DemoPageBody(
      children: [
        DemoCard(
          title: 'Sample text and direction',
          source: 'ctx.font = toFont({size}).string',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const ValueKey('text.sample'),
                controller: _sample,
                decoration: const InputDecoration(
                  labelText: 'Sample text',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              SliderControl(
                label: 'font size',
                sliderKey: const ValueKey('text.size'),
                value: _size,
                min: 8,
                max: 48,
                divisions: 40,
                format: (v) => '${v.toStringAsFixed(0)}px',
                onChanged: (v) => setState(() => _size = v),
              ),
              ToggleChips(
                toggles: [
                  (
                    key: 'text.rtl',
                    label: "overrideTextDirection(ctx, 'rtl')",
                    value: _rtl,
                    onChanged: (v) => setState(() => _rtl = v),
                  ),
                  (
                    key: 'text.clip',
                    label: 'clip each cell',
                    value: _clipCells,
                    onChanged: (v) => setState(() => _clipCells = v),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Mono(
                font.string ?? 'null',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        DemoCard(
          title: 'textAlign × textBaseline',
          source:
              'fillText at the red point (a phone scrolls the grid '
              'sideways); blue: the measureText box '
              '(x - actualBoundingBoxLeft … x + actualBoundingBoxRight, '
              'y - actualBoundingBoxAscent … y + actualBoundingBoxDescent)',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final available = constraints.maxWidth;
              final width = _gridWidth(available, metrics.width);
              final grid = SizedBox(
                width: width,
                child: DemoCanvas(
                  key: const ValueKey('text.grid'),
                  height:
                      _headerHeight + textBaselines.length * _cellHeight + 2,
                  draw: _drawGrid,
                ),
              );
              return width <= available
                  ? grid
                  : SingleChildScrollView(
                      key: const ValueKey('text.gridScroll'),
                      scrollDirection: Axis.horizontal,
                      child: grid,
                    );
            },
          ),
        ),
        DemoCard(
          title: 'measureText',
          source:
              "measureText(sample), textAlign 'left', "
              "textBaseline 'alphabetic'",
          child: ReadoutTable(
            key: const ValueKey('text.metrics'),
            rows: [
              ('width', px(metrics.width)),
              ('actualBoundingBoxLeft', px(metrics.actualBoundingBoxLeft)),
              ('actualBoundingBoxRight', px(metrics.actualBoundingBoxRight)),
              ('actualBoundingBoxAscent', px(metrics.actualBoundingBoxAscent)),
              (
                'actualBoundingBoxDescent',
                px(metrics.actualBoundingBoxDescent),
              ),
            ],
          ),
        ),
        DemoCard(
          title: 'RTL adapter',
          source:
              'helpers.rtl: getRtlAdapter(rtl, left, width) · x · '
              "leftForLtr · textAlign · overrideTextDirection(ctx, 'rtl') · "
              'restoreTextDirection',
          child: DemoCanvas(
            key: const ValueKey('text.rtlLegend'),
            height: 92,
            draw: _drawLegend,
          ),
        ),
        DemoCard(
          title: '_longestText',
          source:
              'helpers.canvas: _longestText(ctx, font, arrayOfThings, cache) '
              '· _measureText; the sample is the first label',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ReadoutTable(
                key: const ValueKey('text.longest'),
                rows: [
                  ('longestText', '${px(longest)} px'),
                  ('cache.data', '${_cache.data?.length ?? 0} widths'),
                  (
                    'cache.garbageCollect',
                    '${_cache.garbageCollect?.length ?? 0} texts',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DemoCanvas(
                key: const ValueKey('text.longestCanvas'),
                height: 16 + rows.length * _size * 1.5,
                draw: _drawLongest,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
