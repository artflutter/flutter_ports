// The package exports nothing from lib/src yet; the public API comes in
// phase 9. The demo imports the ported files directly.
// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/kurkle_color/index.esm.dart' as kc;

/// The JavaScript source form of an option value, for display: `undefined`,
/// `null`, a quoted string, a JS number string, or `{…}` and `[…]`.
String showJs(Object? value) => switch (value) {
  Undefined() => 'undefined',
  null => 'null',
  final String s => "'$s'",
  final double d => jsNumberToString(d),
  final num n => jsNumberToString(n.toDouble()),
  final bool b => '$b',
  final Map<Object?, Object?> _ => '{…}',
  final List<Object?> _ => '[…]',
  _ => value.toString(),
};

/// The Flutter color of a parsed `@kurkle/color` [kc.Color], or `null` when
/// the color is not valid.
Color? flutterColor(kc.Color color) {
  final rgb = color.valid ? color.rgb : null;
  if (rgb == null) return null;
  return Color.from(
    alpha: rgb.a.clamp(0, 1).toDouble(),
    red: rgb.r / 255,
    green: rgb.g / 255,
    blue: rgb.b / 255,
  );
}

/// The Flutter color of a CSS color string, parsed by the ported
/// `@kurkle/color`, or `null` when it does not parse.
Color? cssColor(String? css) =>
    css == null ? null : flutterColor(kc.Color(css));

/// A centered column with a readable maximum width, for wide screens.
///
/// The page builds all its sections at once, in a [SingleChildScrollView]:
/// a section that scrolls out of view keeps its state (its toggles, its
/// sliders and its chart). A tab has at most a few cards.
class DemoPageBody extends StatelessWidget {
  /// Creates the body with [children], padded and capped at [maxWidth].
  const DemoPageBody({
    required this.children,
    this.maxWidth = 1100,
    super.key,
  });

  /// The sections of the page.
  final List<Widget> children;

  /// The largest width of the content.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final child in children)
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: child,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A card with a title, an optional note on the ported source, and content.
class DemoCard extends StatelessWidget {
  /// Creates a card titled [title] around [child].
  const DemoCard({
    required this.title,
    required this.child,
    this.source,
    super.key,
  });

  /// The heading of the card.
  final String title;

  /// The ported function or file that the card calls, shown in monospace.
  final String? source;

  /// The content of the card.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            if (source != null) ...[
              const SizedBox(height: 4),
              Text(
                source!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// A color swatch over a checkerboard, so that alpha shows.
class ColorSwatchBox extends StatelessWidget {
  /// Creates a swatch of [color]; `null` shows a crossed-out box.
  const ColorSwatchBox({required this.color, this.size = 40, super.key});

  /// The color, or `null` for a color that did not parse.
  final Color? color;

  /// The side of the square.
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _SwatchPainter(
            color,
            Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
    );
  }
}

class _SwatchPainter extends CustomPainter {
  _SwatchPainter(this.color, this.outline);

  final Color? color;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 6.0;
    final light = Paint()..color = const Color(0xFFFFFFFF);
    final dark = Paint()..color = const Color(0xFFCCCCCC);
    for (var y = 0; y * cell < size.height; y++) {
      for (var x = 0; x * cell < size.width; x++) {
        canvas.drawRect(
          Rect.fromLTWH(x * cell, y * cell, cell, cell),
          (x + y).isEven ? light : dark,
        );
      }
    }
    final rect = Offset.zero & size;
    if (color != null) {
      canvas.drawRect(rect, Paint()..color = color!);
    } else {
      final cross = Paint()
        ..color = outline
        ..strokeWidth = 2;
      canvas
        ..drawLine(rect.topLeft, rect.bottomRight, cross)
        ..drawLine(rect.topRight, rect.bottomLeft, cross);
    }
    canvas.drawRect(
      rect.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = outline.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(_SwatchPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.outline != outline;
}

/// Monospace text.
class Mono extends StatelessWidget {
  /// Creates monospace [text].
  const Mono(
    this.text, {
    this.style,
    this.softWrap,
    this.overflow,
    this.maxLines,
    super.key,
  });

  /// The text.
  final String text;

  /// The style merged over the monospace body style.
  final TextStyle? style;

  /// The [Text.softWrap] of the text.
  final bool? softWrap;

  /// The [Text.overflow] of the text.
  final TextOverflow? overflow;

  /// The [Text.maxLines] of the text.
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium!.copyWith(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Menlo', 'Consolas', 'Roboto Mono'],
    );
    return Text(
      text,
      style: base.merge(style),
      softWrap: softWrap,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}

/// Keeps the state of a tab (a typed text, dragged points, a running
/// animation) when the user switches to another tab and back.
class KeepAliveTab extends StatefulWidget {
  /// Keeps [child] alive.
  const KeepAliveTab({required this.child, super.key});

  /// The content of the tab.
  final Widget child;

  @override
  State<KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// A [TabBarView] whose tabs keep their state ([KeepAliveTab]) and whose
/// hidden tabs have their tickers muted.
///
/// A kept-alive tab stays in the tree while another tab shows, and
/// [TabBarView] does not turn its [TickerMode] off. Without the mute, a
/// `Ticker` or a chart loop of a hidden tab draws in every frame, and the
/// app never goes idle. A chart host reads the [TickerMode] of its tab and
/// reports it through `ChartHost.onTickerModeChanged`.
///
/// It reads the controller of the enclosing [DefaultTabController]. During
/// a tab animation, both the old and the new tab run their tickers.
class DemoTabBarView extends StatefulWidget {
  /// Creates the view of [children], one for each tab.
  const DemoTabBarView({required this.children, super.key});

  /// The content of the tabs.
  final List<Widget> children;

  @override
  State<DemoTabBarView> createState() => _DemoTabBarViewState();
}

class _DemoTabBarViewState extends State<DemoTabBarView> {
  TabController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = DefaultTabController.of(context);
    if (identical(controller, _controller)) return;
    _controller?.removeListener(_changed);
    _controller = controller..addListener(_changed);
  }

  @override
  void dispose() {
    _controller?.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  bool _shows(int index) {
    final controller = _controller!;
    return index == controller.index ||
        (controller.indexIsChanging && index == controller.previousIndex);
  }

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      // Horizontal drags belong to the sliders, the canvases and the chart
      // hosts.
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var i = 0; i < widget.children.length; i++)
          TickerMode(
            enabled: _shows(i),
            child: KeepAliveTab(child: widget.children[i]),
          ),
      ],
    );
  }
}
