import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:chartjs_gallery/demo/canvas_demo.dart'
    show chartColors, drawCaption, labelColor;
import 'package:chartjs_gallery/demo/demo_chart.dart';
import 'package:chartjs_gallery/demo/demo_common.dart';
import 'package:chartjs_gallery/demo/demo_controls.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart'
    hide PointOptions;
// Not public: _longestText, an upstream `_` helper (Chart.js ADR 0048).
import 'package:material_ui/material_ui.dart';

/// The `textAlign` values of the canvas.
const List<TextAlign> textAligns = [
  TextAlign.left,
  TextAlign.center,
  TextAlign.right,
  TextAlign.start,
  TextAlign.end,
];

/// The `textBaseline` values of the canvas.
const List<CanvasTextBaseline> textBaselines = CanvasTextBaseline.values;

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
class const TextDemo({super.key}) extends StatefulWidget {
  /// Creates the text tab.
  this;

  @override
  State<TextDemo> createState() => _TextDemoState();
}

class _TextDemoState() extends State<TextDemo> {
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

  ChartTextStyle get _font => toFont(ChartTextStyle(fontSize: _size));

  String get _text => _sample.text;

  /// Scopes the native direction to this drawing operation.
  void _withDirection(CanvasRenderingContext2D ctx, void Function() body) {
    final original = overrideTextDirection(
      ctx,
      _rtl ? TextDirection.rtl : null,
    );
    try {
      body();
    } finally {
      restoreTextDirection(ctx, original);
    }
  }

  // The textAlign x textBaseline grid.

  static double _labelWidth(double width) => width < 520 ? 74 : 96;

  double get _cellHeight => math.max(44, _size * 2.6);

  static const double _headerHeight = 24;

  void _drawGrid(DemoChart chart, CanvasRenderingContext2D ctx) {
    final labelWidth = _labelWidth(chart.width);
    final cellWidth = (chart.width - labelWidth) / textAligns.length;
    final cellHeight = _cellHeight;
    final small = toFont(const ChartTextStyle(fontSize: 12));
    final font = _font;
    for (var c = 0; c < textAligns.length; c++) {
      renderText(
        ctx,
        textAligns[c].name,
        labelWidth + (c + 0.5) * cellWidth,
        _headerHeight - 6,
        small,
        const RenderTextOpts(
          color: ChartPaint.solid(labelColor),
          textAlign: TextAlign.center,
          textBaseline: CanvasTextBaseline.bottom,
        ),
      );
    }
    _withDirection(ctx, () {
      for (var r = 0; r < textBaselines.length; r++) {
        final top = _headerHeight + r * cellHeight;
        renderText(
          ctx,
          textBaselines[r].name,
          4,
          top + cellHeight / 2,
          small,
          const RenderTextOpts(
            color: ChartPaint.solid(labelColor),
            textAlign: TextAlign.left,
            textBaseline: CanvasTextBaseline.middle,
          ),
        );
        for (var c = 0; c < textAligns.length; c++) {
          final left = labelWidth + c * cellWidth;
          final x = _anchorX(textAligns[c], left, cellWidth);
          final y = top + cellHeight / 2;
          ctx
            ..strokeStyle = const ui.Color.fromRGBO(0, 0, 0, 0.12)
            ..lineWidth = 1
            ..strokeRect(left + 0.5, top + 0.5, cellWidth - 1, cellHeight - 1);
          if (_clipCells) {
            clipArea(ctx, Box(left, top, left + cellWidth, top + cellHeight));
          }
          // The alignment point: the baseline and the x of the anchor.
          ctx
            ..strokeStyle = const ui.Color.fromRGBO(255, 99, 132, 0.45)
            ..beginPath()
            ..moveTo(left, y + 0.5)
            ..lineTo(left + cellWidth, y + 0.5)
            ..moveTo(x + 0.5, top)
            ..lineTo(x + 0.5, top + cellHeight)
            ..stroke()
            ..font = font
            ..textAlign = textAligns[c]
            ..textBaseline = textBaselines[r]
            ..fillStyle = const ui.Color(0xFF333333)
            ..fillText(_text, x, y);
          final m = ctx.measureText(_text);
          ctx
            ..strokeStyle = const ui.Color(0xFF36A2EB)
            ..strokeRect(
              x - m.actualBoundingBoxLeft,
              y - m.actualBoundingBoxAscent,
              m.actualBoundingBoxLeft + m.actualBoundingBoxRight,
              m.actualBoundingBoxAscent + m.actualBoundingBoxDescent,
            )
            ..fillStyle = const ui.Color(0xFFFF6384);
          drawPoint(
            ctx,
            const PointOptions(
              pointStyle: CirclePointStyle(),
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
  double _anchorX(TextAlign align, double left, double width) {
    const inset = 10.0;
    final side = switch (align) {
      TextAlign.left => -1,
      TextAlign.right => 1,
      TextAlign.start => _rtl ? 1 : -1,
      TextAlign.end => _rtl ? -1 : 1,
      TextAlign.center || TextAlign.justify => 0,
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
    final font = toFont(const ChartTextStyle(fontSize: 14));
    // plugin.legend.js:388 `getRtlAdapter(opts.rtl, this.left, this.width)`.
    final rtlHelper = getRtlAdapter(_rtl, 0, chart.width);
    _withDirection(ctx, () {
      ctx
        ..font = font
        ..textBaseline = CanvasTextBaseline.middle;
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
          ..textAlign = rtlHelper.textAlign(TextAlign.left)
          ..fillStyle = labelColor
          ..fillText(text, rtlHelper.x(x + boxWidth + 8), y);
        x += boxWidth + 8 + textWidth + 18;
      }
      // textAlign 'start' follows the native canvas direction.
      ctx
        ..textAlign = TextAlign.start
        ..fillStyle = const ui.Color(0xFF333333)
        ..fillText(
          "textAlign 'start', canvas direction: "
          '${_canvasDirection(ctx)}',
          rtlHelper.x(12),
          y + 32,
        );
    });
    drawCaption(
      ctx,
      'rtlHelper.x(x) = ${jsNumberText(rtlHelper.x(12))} for x = 12',
      chart.width / 2,
      chart.height - 4,
    );
  }

  static String _canvasDirection(CanvasRenderingContext2D ctx) =>
      ctx.direction?.name ?? 'inherit';

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
    final longest = longestText(ctx, font, _labels, _cache);
    ctx.font = font;
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
            ? const ui.Color.fromRGBO(255, 99, 132, 0.35)
            : const ui.Color.fromRGBO(54, 162, 235, 0.18)
        ..fillRect(x, y, width, rowHeight - 4)
        ..font = font
        ..textAlign = TextAlign.left
        ..textBaseline = CanvasTextBaseline.middle
        ..fillStyle = skipped
            ? const ui.Color(0xFF999999)
            : const ui.Color(0xFF333333)
        ..fillText(text, x, y + (rowHeight - 4) / 2);
    }
    ctx
      ..strokeStyle = const ui.Color(0xFFFF6384)
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
      ..font = font
      ..textAlign = TextAlign.left
      ..textBaseline = CanvasTextBaseline.alphabetic;
    final metrics = ctx.measureText(_text);
    final longest = longestText(ctx, font, _labels, _cache);
    // + 0 turns -0 into 0.
    String px(double v) => (v + 0).toStringAsFixed(2);
    final rows = _rows(_labels);

    return DemoPageBody(
      children: [
        DemoCard(
          title: 'Sample text and direction',
          source: 'ctx.font = toFont(ChartTextStyle(fontSize: size))',
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
                    label: 'overrideTextDirection(ctx, TextDirection.rtl)',
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
                '${font.fontFamily} · ${font.fontSize}px · lineHeight '
                '${font.lineHeight}px',
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
              'leftForLtr · textAlign · '
              'overrideTextDirection(ctx, TextDirection.rtl) · '
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
