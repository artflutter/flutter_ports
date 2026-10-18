// The package exports nothing from lib/src yet; the public API comes in
// phase 9. The demo imports the ported files directly.
// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:math' as math;

import 'package:chartjs_gallery/demo/demo_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chartjs/src/helpers/helpers.easing.dart';

/// The lowest value that the curve plots show. `easeInElastic` and
/// `easeInBack` dip below 0.
const double _yMin = -0.5;

/// The highest value that the curve plots show. `easeOutElastic` and
/// `easeOutBack` overshoot 1.
const double _yMax = 1.5;

/// A grid of the 31 ported easing effects of `helpers.easing`.
///
/// Each cell plots `effect(t)` for `t` in 0..1. A tap plays the effect: an
/// [AnimationController] runs `t` from 0 to 1, and a dot moves with
/// `effect(t)`, on the curve and on a track.
class EasingDemo extends StatefulWidget {
  /// Creates the easing tab.
  const EasingDemo({super.key});

  @override
  State<EasingDemo> createState() => _EasingDemoState();
}

class _EasingDemoState extends State<EasingDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  final List<String> _names = easingEffects.keys.toList();
  String _selected = 'easeOutBounce';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _play(String name) {
    setState(() => _selected = name);
    unawaited(_controller.forward(from: 0));
  }

  @override
  Widget build(BuildContext context) {
    final effect = easingEffects[_selected]!;
    final scheme = Theme.of(context).colorScheme;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: DemoCard(
                  title: 'Now playing: $_selected',
                  source:
                      'helpers.easing.dart easingEffects '
                      '(${easingEffects.length} effects) · '
                      'value = effect(t), t = 0 → 1',
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final t = _controller.value;
                      final v = effect(t);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 36,
                            child: CustomPaint(
                              painter: _TrackPainter(
                                value: v,
                                track: scheme.surfaceContainerHighest,
                                dot: scheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Mono(
                                  't = ${t.toStringAsFixed(3)}   '
                                  'effect(t) = ${v.toStringAsFixed(4)}',
                                ),
                              ),
                              FilledButton.tonalIcon(
                                key: const ValueKey('easing.replay'),
                                onPressed: () => _play(_selected),
                                icon: const Icon(Icons.replay),
                                label: const Text('Replay'),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        // The grid takes the 1100 px width cap of the card above it.
        SliverLayoutBuilder(
          builder: (context, constraints) {
            final side =
                math.max<double>(0, (constraints.crossAxisExtent - 1100) / 2) +
                12;
            return SliverPadding(
              padding: EdgeInsets.fromLTRB(side, 6, side, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 190,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.95,
                ),
                delegate: SliverChildBuilderDelegate(
                  childCount: easingEffects.length,
                  (context, index) {
                    final name = _names[index];
                    return _EffectCell(
                      key: ValueKey('easing.$name'),
                      name: name,
                      effect: easingEffects[name]!,
                      selected: name == _selected,
                      animation: _controller,
                      onTap: () => _play(name),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _EffectCell extends StatelessWidget {
  const _EffectCell({
    required this.name,
    required this.effect,
    required this.selected,
    required this.animation,
    required this.onTap,
    super.key,
  });

  final String name;
  final double Function(double t) effect;
  final bool selected;
  final Animation<double> animation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    CustomPaint paintAt(double? t) => CustomPaint(
      painter: _CurvePainter(
        effect: effect,
        curve: selected ? scheme.primary : scheme.onSurfaceVariant,
        grid: scheme.outlineVariant,
        dot: scheme.primary,
        t: t,
      ),
      size: Size.infinite,
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      color: selected ? scheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Expanded(
                child: selected
                    ? AnimatedBuilder(
                        animation: animation,
                        builder: (context, _) => paintAt(animation.value),
                      )
                    : paintAt(null),
              ),
              const SizedBox(height: 6),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Plots one effect over t = 0..1, with the unit box and an optional dot.
class _CurvePainter extends CustomPainter {
  _CurvePainter({
    required this.effect,
    required this.curve,
    required this.grid,
    required this.dot,
    this.t,
  });

  final double Function(double t) effect;
  final Color curve;
  final Color grid;
  final Color dot;
  final double? t;

  Offset _at(Size size, double t, double v) => Offset(
    t * size.width,
    size.height * (_yMax - v) / (_yMax - _yMin),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    canvas
      ..drawLine(_at(size, 0, 0), _at(size, 1, 0), gridPaint)
      ..drawLine(_at(size, 0, 1), _at(size, 1, 1), gridPaint);

    const steps = 120;
    final start = _at(size, 0, effect(0));
    final path = Path()..moveTo(start.dx, start.dy);
    for (var i = 1; i <= steps; i++) {
      final x = i / steps;
      final p = _at(size, x, effect(x));
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = curve,
    );
    final t = this.t;
    if (t != null) {
      canvas.drawCircle(_at(size, t, effect(t)), 5, Paint()..color = dot);
    }
  }

  @override
  bool shouldRepaint(_CurvePainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.curve != curve ||
      oldDelegate.effect != effect;
}

/// A horizontal track with a dot at `value` (0 = left end, 1 = right end).
class _TrackPainter extends CustomPainter {
  _TrackPainter({required this.value, required this.track, required this.dot});

  final double value;
  final Color track;
  final Color dot;

  @override
  void paint(Canvas canvas, Size size) {
    const r = 12.0;
    final y = size.height / 2;
    final left = size.width * 0.12 + r;
    final right = size.width * 0.88 - r;
    canvas
      ..drawRRect(
        RRect.fromLTRBR(
          left - r,
          y - 4,
          right + r,
          y + 4,
          const Radius.circular(4),
        ),
        Paint()..color = track,
      )
      ..drawCircle(
        Offset(left + (right - left) * value, y),
        r,
        Paint()..color = dot,
      );
  }

  @override
  bool shouldRepaint(_TrackPainter oldDelegate) => oldDelegate.value != value;
}
