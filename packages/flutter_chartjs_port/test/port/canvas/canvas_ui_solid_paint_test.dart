// Original code, not ported from Chart.js: solid and shader paint twins.
@TestOn('vm')
library;

// Keep canvas state transitions and their observations as separate steps.
// ignore_for_file: cascade_invocations

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pixel_compare.dart';

const _blue = ui.Color(0xFF4F6BED);
const _teal = ui.Color(0xB011A098);
const _dark = ui.Color(0xFF1E293B);
const _red = ui.Color(0xFFDD4400);
const _black = ui.Color(0xFF000000);

const _gradient = ChartGradient.linear(ui.Offset.zero, ui.Offset(120, 0), [
  _red,
  _teal,
]);

// The exact-class guard of the bar draw declines this subclass. It takes the
// ordinary sequence of canvas calls, whose fills give the context no exact
// color.
class _ReferenceBar(super.cfg) extends BarElement;

// A color of another class than `ui.Color`.
class const _OddColor(super.value) extends ui.Color;

/// A new color object for each call, with the value of [color].
ui.Color _fresh(ui.Color color) =>
    ui.Color.from(alpha: color.a, red: color.r, green: color.g, blue: color.b);

/// [color] as a paint gives it back: its channels are 32-bit floats there.
ui.Color _painted(ui.Color color) => (ui.Paint()..color = color).color;

List<ui.Color> _paintedAll(List<ui.Color> colors) => [
  for (final color in colors) _painted(color),
];

/// One native call of a recording: its name, its text with each argument,
/// and its paint with the values at the call.
final class _Call(
  final String name,
  final String text,
  final ui.Paint? paint,
  final ui.Color? color,
  final bool shader,
  final ui.BlendMode? blend,
  final ui.PaintingStyle? style,
  final double? strokeWidth,
) {
  @override
  String toString() => text;
}

String _describe(Object? value) => switch (value) {
  final ui.Paint p =>
    'Paint(${p.color}, ${p.style}, ${p.strokeWidth}, ${p.blendMode}, '
        '${p.shader != null}, ${p.maskFilter}, ${p.colorFilter})',
  final ui.Path path => 'Path(${path.getBounds()})',
  _ => '$value',
};

/// A canvas that logs each native call with its arguments and draws nothing.
/// It starts the recording of its recorder, which the context ends.
final class _LogCanvas(final List<_Call> _log, ui.PictureRecorder recorder)
    implements ui.Canvas {
  this {
    ui.Canvas(recorder);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final positional = invocation.positionalArguments;
    final name = '${invocation.memberName}';
    final paint = positional.whereType<ui.Paint>().firstOrNull;
    _log.add(
      _Call(
        name.substring(8, name.length - 2),
        '$name(${positional.map(_describe).join(', ')})',
        paint,
        paint?.color,
        paint?.shader != null,
        paint?.blendMode,
        paint?.style,
        paint?.strokeWidth,
      ),
    );
    return null;
  }
}

/// What a context did in a scenario: its native calls, its pictures, its
/// final rectangle path and the count of the kept fill paints.
typedef _Observed = ({
  List<_Call> calls,
  int pictures,
  ui.Rect? path,
  int kept,
});

_Observed _observe(void Function(UiCanvasContext ctx) scenario) {
  final calls = <_Call>[];
  UiCanvasContext.debugRecordingCanvas = (recorder) =>
      _LogCanvas(calls, recorder);
  final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
  try {
    scenario(ctx);
    final path = ctx.debugPath.singleRect;
    final recorder = ui.PictureRecorder();
    ctx.paint(ui.Canvas(recorder), ui.Offset.zero, 1, 1);
    recorder.endRecording().dispose();
    return (
      calls: calls,
      pictures: ctx.debugPictureCount,
      path: path,
      kept: ctx.debugKeptFillPaints,
    );
  } finally {
    ctx.dispose();
    UiCanvasContext.debugRecordingCanvas = null;
  }
}

List<_Call> _draws(_Observed observed) => [
  for (final call in observed.calls)
    if (call.paint != null) call,
];

BarOptions _options({
  Object? background = const ChartPaint.solid(_blue),
  Object? border = const ChartPaint.solid(_dark),
  Object? borderWidth = 0.0,
  Object? radius = 0.0,
}) => BarOptions({
  'borderWidth': borderWidth,
  'borderRadius': radius,
  'borderColor': border,
  'backgroundColor': background,
});

typedef _MakeBar = BarElement Function(Map<String, Object?> cfg);

BarElement _bar(
  _MakeBar make,
  Object? options, {
  required double x,
  double y = 40,
  double base = 120,
  double width = 1.2,
  bool horizontal = false,
  double inflate = 0,
}) => make({
  'x': x,
  'y': y,
  'base': base,
  'width': width,
  'height': width,
  'horizontal': horizontal,
  'enableBorderRadius': true,
  'inflateAmount': inflate,
  'borderSkipped': BorderSkipped()..bottom = true,
  'options': options,
});

/// Bars of each kind of the bar draw, between other fills and strokes that
/// change the paints. [make] makes each bar.
void _mixed(UiCanvasContext ctx, _MakeBar make) {
  ctx.fillStyle = const ui.Color(0xFFEEEEEE);
  ctx.fillRect(0, 0, 160, 160);
  // One options object for 300 thin bars: more than one recording.
  final plain = _options();
  for (var i = 0; i < 300; i++) {
    _bar(make, plain, x: 2 + i * 0.5, y: 30 + (i % 7) * 3).draw(ctx);
  }
  // Two colors in turn, and three colors in turn. The raw `ui.Color` is a
  // foreign value of the options: its typed field is empty.
  final other = _options(background: const ChartPaint.solid(_teal));
  final third = _options(background: _red, border: _dark);
  for (var i = 0; i < 40; i++) {
    _bar(make, i.isEven ? plain : other, x: 3 + i * 3.5, width: 3).draw(ctx);
  }
  for (var i = 0; i < 30; i++) {
    _bar(
      make,
      [plain, other, third][i % 3],
      x: 4 + i * 3.5,
      y: 100,
      width: 2,
    ).draw(ctx);
  }
  // A global alpha and a composite operation.
  ctx.globalAlpha = 0.5;
  _bar(make, plain, x: 20, width: 6).draw(ctx);
  _bar(make, plain, x: 30, width: 6).draw(ctx);
  ctx.globalAlpha = 1;
  _bar(make, plain, x: 40, width: 6).draw(ctx);
  ctx.globalCompositeOperation = CanvasCompositeOperation.multiply;
  _bar(make, plain, x: 44, width: 6).draw(ctx);
  _bar(make, plain, x: 46, width: 6).draw(ctx);
  ctx.globalCompositeOperation = CanvasCompositeOperation.sourceOver;
  _bar(make, plain, x: 48, width: 6).draw(ctx);
  ctx.globalAlpha = 0;
  _bar(make, plain, x: 52, width: 6).draw(ctx);
  ctx.globalAlpha = 1;
  // A gradient goes to the shader paint. The next bar has the color of the
  // bar before the gradient.
  ctx.fillStyle = _gradient;
  ctx.fillRect(10, 125, 60, 12);
  _bar(make, plain, x: 60, width: 6).draw(ctx);
  // The same under a composite operation and a global alpha: the gradient
  // and the solid fills after it have the values of the state.
  ctx.globalCompositeOperation = CanvasCompositeOperation.multiply;
  ctx.fillStyle = _gradient;
  ctx.fillRect(20, 138, 60, 8);
  _bar(make, plain, x: 64, width: 3).draw(ctx);
  ctx.strokeStyle = _gradient;
  ctx.lineWidth = 2;
  ctx.strokeRect(84, 138, 30, 8);
  ctx.globalAlpha = 0.6;
  ctx.fillRect(20, 148, 60, 6);
  ctx.strokeStyle = _dark;
  ctx.strokeRect(84, 148, 30, 6);
  ctx.globalAlpha = 1;
  ctx.globalCompositeOperation = CanvasCompositeOperation.sourceOver;
  ctx.fillRect(100, 100, 20, 6);
  _bar(make, plain, x: 66, width: 3).draw(ctx);
  ctx.beginPath();
  ctx.moveTo(5, 5);
  ctx.lineTo(150, 12);
  ctx.stroke();
  // A solid fill of the color of the bars, and of another color.
  ctx.fillStyle = _blue;
  ctx.fillRect(72, 125, 6, 12);
  _bar(make, plain, x: 68, width: 3).draw(ctx);
  ctx.fillStyle = _red;
  ctx.fillRect(80, 125, 20, 12);
  _bar(make, plain, x: 70, width: 6).draw(ctx);
  // A gradient bar, a rounded bar and an inflated bar take the ordinary
  // sequence.
  _bar(make, _options(background: _gradient), x: 80, width: 6).draw(ctx);
  _bar(make, _options(radius: 2.0), x: 90, width: 6).draw(ctx);
  _bar(make, plain, x: 96, width: 4, inflate: 0.33).draw(ctx);
  // Borders: a ring, a thin bar whose border takes all of it, a whole number
  // as the width, a horizontal bar.
  final ring = _options(
    borderWidth: 1.0,
    background: const ChartPaint.solid(_teal),
  );
  _bar(make, ring, x: 110, width: 8).draw(ctx);
  _bar(make, ring, x: 118, width: 1.5).draw(ctx);
  _bar(make, _options(borderWidth: 2), x: 126, width: 8).draw(ctx);
  _bar(
    make,
    ring,
    x: 40,
    y: 150,
    base: 90,
    width: 5,
    horizontal: true,
  ).draw(ctx);
  _bar(
    make,
    plain,
    x: 60,
    y: 144,
    base: 20,
    width: 3,
    horizontal: true,
  ).draw(ctx);
  // The path of the last bar stays for a stroke.
  ctx.strokeStyle = _red;
  ctx.lineWidth = 0.5;
  ctx.stroke();
  ctx.fillStyle = _dark;
  ctx.fillRect(1, 1, 3, 3);
}

/// One fused bar with no border at [x], with the fill [fill].
bool _fused(
  UiCanvasContext ctx,
  double x,
  Object? fill, {
  Object? border = _dark,
}) => ctx.tryDrawRectBar(
  outerX: x,
  outerY: 10,
  outerWidth: 4,
  outerHeight: 60,
  innerX: x,
  innerY: 10,
  innerWidth: 4,
  innerHeight: 60,
  borderColor: border,
  backgroundColor: fill,
);

/// One fused bar with a border of 1 on each side at [x].
bool _ringed(UiCanvasContext ctx, double x, Object? fill, Object? border) =>
    ctx.tryDrawRectBar(
      outerX: x,
      outerY: 10,
      outerWidth: 8,
      outerHeight: 60,
      innerX: x + 1,
      innerY: 11,
      innerWidth: 6,
      innerHeight: 58,
      borderColor: border,
      backgroundColor: fill,
    );

/// The calls of `pathArc` (element.arc.ts:230-286) for a ring sector with no
/// border radius, no spacing and no offset.
void _sector(CanvasPath p, double x, double y, double start, double end) {
  const outer = 30.0;
  const inner = 15.0;
  final middle = (start + end) / 2;
  p
    ..arc(x, y, outer, start, middle)
    ..arc(x, y, outer, middle, end)
    ..lineTo(x + math.cos(end) * inner, y + math.sin(end) * inner)
    ..arc(x, y, inner, end, middle, true)
    ..arc(x, y, inner, middle, start, true)
    ..lineTo(x + math.cos(start) * outer, y + math.sin(start) * outer)
    ..closePath();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    UiCanvasContext.debugRecordingCanvas = null;
  });

  group('the colors that a fused bar takes', () {
    // No color passed the full test on a new context. A null color must
    // not pass as one of the last two colors, which are null then.
    test('a null color declines', () {
      final observed = _observe((ctx) {
        expect(_fused(ctx, 2, null), isFalse);
        expect(_fused(ctx, 2, _blue, border: null), isFalse);
        expect(_fused(ctx, 2, _blue, border: const _NoColor()), isFalse);
        expect(_ringed(ctx, 2, _blue, null), isFalse);
      });
      expect(observed.calls, isEmpty);
    });

    test('three colors in turn draw fused, each with its color', () {
      final colors = [_fresh(_blue), _fresh(_teal), _fresh(_red)];
      final observed = _observe((ctx) {
        for (var i = 0; i < 12; i++) {
          expect(_fused(ctx, 2.0 + i * 6, colors[i % 3]), isTrue);
        }
      });
      expect([
        for (final call in _draws(observed)) call.color,
      ], _paintedAll([for (var i = 0; i < 12; i++) colors[i % 3]]));
    });

    test('a color that the full test declines stays declined after other '
        'colors passed', () {
      final declined = <Object?>[
        null,
        'red',
        12,
        const _OddColor(0xFF4F6BED),
        const ui.Color.from(alpha: 1, red: 1.5, green: 0, blue: 0),
        const ui.Color.from(alpha: 1, red: 0, green: double.nan, blue: 0),
        const ui.Color.from(
          alpha: 1,
          red: 0.5,
          green: 0.5,
          blue: 0.5,
          colorSpace: ui.ColorSpace.displayP3,
        ),
        _gradient,
      ];
      final observed = _observe((ctx) {
        for (var round = 0; round < 3; round++) {
          for (final color in declined) {
            expect(_fused(ctx, 2, color), isFalse, reason: '$color');
            expect(_fused(ctx, 2, _blue, border: color), isFalse);
            expect(_ringed(ctx, 2, _teal, color), isFalse, reason: '$color');
          }
          // Two colors pass the full test between the rounds.
          expect(_fused(ctx, 20, _fresh(_blue)), isTrue);
          expect(_fused(ctx, 26, _fresh(_teal)), isTrue);
        }
      });
      expect(_draws(observed).length, 6);
    });
  });

  group('the bar draw against the ordinary sequence of a subclass', () {
    test('the native calls, the pictures and the path are equal', () {
      final reference = _observe((ctx) => _mixed(ctx, _ReferenceBar.new));
      final fused = _observe((ctx) => _mixed(ctx, BarElement.new));
      expect(
        reference.calls.where((c) => c.name == 'drawRect').length,
        greaterThan(370),
      );
      expect(fused.calls.length, reference.calls.length);
      for (var i = 0; i < reference.calls.length; i++) {
        expect(fused.calls[i].text, reference.calls[i].text, reason: 'call $i');
      }
      expect(fused.pictures, reference.pictures);
      expect(fused.pictures, greaterThan(1));
      expect(fused.path, reference.path);
      // The fused bars took the kept paint. The ordinary sequence gives the
      // context no exact color, so it keeps none.
      expect(reference.kept, 0);
      expect(fused.kept, greaterThan(290));
    });

    test('the pixels are equal', () async {
      final reference = await renderContext(
        (ctx) => _mixed(ctx, _ReferenceBar.new),
      );
      final fused = await renderContext((ctx) => _mixed(ctx, BarElement.new));
      expect(fused.bytes, reference.bytes);
      expect(reference.ink, greaterThan(1000));
    });
  });

  group('the solid paint and the shader paint', () {
    // A fill or a stroke with a color or a gradient, a global alpha and a
    // composite operation.
    final steps =
        <
          ({
            bool stroke,
            bool gradient,
            ui.Color color,
            double alpha,
            CanvasCompositeOperation operation,
            ui.BlendMode blend,
          })
        >[
          for (final (operation, blend) in [
            (CanvasCompositeOperation.sourceOver, ui.BlendMode.srcOver),
            (CanvasCompositeOperation.multiply, ui.BlendMode.multiply),
          ])
            for (final alpha in [1.0, 0.5, 1.0])
              for (final (stroke, gradient, color) in [
                (false, false, _blue),
                (false, true, _blue),
                (false, false, _blue),
                (false, false, _teal),
                (true, false, _dark),
                (true, true, _dark),
                (true, false, _dark),
                (false, true, _red),
                (true, false, _red),
                (false, false, _teal),
              ])
                (
                  stroke: stroke,
                  gradient: gradient,
                  color: color,
                  alpha: alpha,
                  operation: operation,
                  blend: blend,
                ),
        ];

    _Observed run() => _observe((ctx) {
      for (final (i, step) in steps.indexed) {
        ctx.globalAlpha = step.alpha;
        ctx.globalCompositeOperation = step.operation;
        final style = step.gradient ? _gradient : step.color;
        final y = 2.0 + i * 2;
        if (step.stroke) {
          ctx.strokeStyle = style;
          ctx.lineWidth = 1.5;
          ctx.strokeRect(10, y, 100, 1);
        } else {
          ctx.fillStyle = style;
          ctx.fillRect(10, y, 100, 1);
        }
      }
    });

    test('each draw has the paint values of its style', () {
      final draws = _draws(run());
      expect(draws.length, steps.length);
      for (final (i, step) in steps.indexed) {
        final call = draws[i];
        final reason = 'step $i: $call';
        // The HTML rule: a color times the global alpha; a shader draws
        // with black times the global alpha.
        final base = step.gradient ? _black : step.color;
        expect(
          call.color,
          _painted(
            step.alpha == 1
                ? base
                : base.withValues(alpha: base.a * step.alpha),
          ),
          reason: reason,
        );
        expect(call.shader, step.gradient, reason: reason);
        expect(call.blend, step.blend, reason: reason);
        expect(
          call.style,
          step.stroke ? ui.PaintingStyle.stroke : ui.PaintingStyle.fill,
          reason: reason,
        );
        if (step.stroke) expect(call.strokeWidth, 1.5, reason: reason);
      }
    });

    test('a solid draw and a shader draw have paints of their own', () {
      final draws = _draws(run());
      Set<ui.Paint> paints({required bool stroke, required bool gradient}) =>
          Set.identity()..addAll([
            for (final (i, step) in steps.indexed)
              if (step.stroke == stroke && step.gradient == gradient)
                draws[i].paint!,
          ]);

      final all = <ui.Paint>{};
      for (final stroke in [false, true]) {
        for (final gradient in [false, true]) {
          final set = paints(stroke: stroke, gradient: gradient);
          expect(set.length, 1, reason: 'stroke $stroke, gradient $gradient');
          all.add(set.single);
        }
      }
      // Four paints: no solid draw has the paint of a shader draw.
      expect(Set<ui.Paint>.identity()..addAll(all), hasLength(4));
      // A solid paint has no shader at the end either.
      expect(paints(stroke: false, gradient: false).single.shader, isNull);
      expect(paints(stroke: true, gradient: false).single.shader, isNull);
    });

    test('a ring sector has a solid paint and a shader paint', () {
      final draws = _draws(
        _observe((ctx) {
          for (final (i, gradient) in [false, true, false, true].indexed) {
            ctx.fillStyle = gradient ? _gradient : _teal;
            ctx.globalAlpha = i < 2 ? 1 : 0.5;
            ctx.beginPath();
            _sector(ctx, 80, 80, 0.3 + i, 1.1 + i);
            ctx.fill();
          }
        }),
      );
      expect([for (final call in draws) call.name], List.filled(4, 'drawArc'));
      expect(
        [for (final call in draws) call.shader],
        [false, true, false, true],
      );
      expect(
        [for (final call in draws) call.color],
        _paintedAll([
          _teal,
          _black,
          _teal.withValues(alpha: _teal.a * 0.5),
          _black.withValues(alpha: 0.5),
        ]),
      );
      for (final call in draws) {
        expect(call.style, ui.PaintingStyle.stroke);
        expect(call.strokeWidth, 15);
        expect(call.blend, ui.BlendMode.srcOver);
      }
      expect(identical(draws[0].paint, draws[2].paint), isTrue);
      expect(identical(draws[1].paint, draws[3].paint), isTrue);
      expect(identical(draws[0].paint, draws[1].paint), isFalse);
      expect(draws[0].paint!.shader, isNull);
    });
  });

  group('the kept color of the solid fill paint', () {
    test('bars of one color object write the paint one time', () {
      final observed = _observe((ctx) {
        for (var i = 0; i < 50; i++) {
          expect(_fused(ctx, 2.0 + i * 3, _blue), isTrue);
        }
      });
      expect(observed.kept, 49);
      final draws = _draws(observed);
      expect(draws.length, 50);
      for (final call in draws) {
        expect(call.color, _painted(_blue));
        expect(call.blend, ui.BlendMode.srcOver);
        expect(call.shader, isFalse);
      }
    });

    test('a color of a paint object is kept as its color object', () {
      const paint = ChartPaint.solid(_teal);
      final observed = _observe((ctx) {
        _fused(ctx, 2, paint);
        _fused(ctx, 8, _teal);
        _fused(ctx, 14, paint);
      });
      expect(observed.kept, 2);
      expect([
        for (final call in _draws(observed)) call.color,
      ], _paintedAll([_teal, _teal, _teal]));
    });

    test('another color object of the same value writes the paint', () {
      final observed = _observe((ctx) {
        for (var i = 0; i < 6; i++) {
          _fused(ctx, 2.0 + i * 6, _fresh(_blue));
        }
      });
      expect(observed.kept, 0);
      for (final call in _draws(observed)) {
        expect(call.color, _painted(_blue));
      }
    });

    test('a global alpha below 1 writes the paint, and the next bar at 1 '
        'writes it again', () {
      final observed = _observe((ctx) {
        _fused(ctx, 2, _blue);
        _fused(ctx, 8, _blue);
        ctx.globalAlpha = 0.5;
        _fused(ctx, 14, _blue);
        _fused(ctx, 20, _blue);
        ctx.globalAlpha = 1;
        _fused(ctx, 26, _blue);
        _fused(ctx, 32, _blue);
      });
      // Bars 2 and 6 only.
      expect(observed.kept, 2);
      final half = _blue.withValues(alpha: 0.5);
      expect([
        for (final call in _draws(observed)) call.color,
      ], _paintedAll([_blue, _blue, half, half, _blue, _blue]));
    });

    test('another composite operation writes the paint', () {
      final observed = _observe((ctx) {
        _fused(ctx, 2, _blue);
        ctx.globalCompositeOperation = CanvasCompositeOperation.multiply;
        _fused(ctx, 8, _blue);
        _fused(ctx, 14, _blue);
        ctx.globalCompositeOperation = CanvasCompositeOperation.sourceOver;
        _fused(ctx, 20, _blue);
        _fused(ctx, 26, _blue);
      });
      // Bars 3 and 5 only.
      expect(observed.kept, 2);
      expect(
        [for (final call in _draws(observed)) call.blend],
        [
          ui.BlendMode.srcOver,
          ui.BlendMode.multiply,
          ui.BlendMode.multiply,
          ui.BlendMode.srcOver,
          ui.BlendMode.srcOver,
        ],
      );
      for (final call in _draws(observed)) {
        expect(call.color, _painted(_blue));
      }
    });

    test('a fill of the context with the same color object writes the paint, '
        'and so does the bar after it', () {
      final observed = _observe((ctx) {
        _fused(ctx, 2, _blue);
        ctx.fillStyle = _blue;
        ctx.fillRect(8, 10, 4, 60);
        ctx.fillRect(14, 10, 4, 60);
        _fused(ctx, 20, _blue);
        _fused(ctx, 26, _blue);
      });
      // The last bar only: the context checked no class for its own fills.
      expect(observed.kept, 1);
      for (final call in _draws(observed)) {
        expect(call.color, _painted(_blue));
      }
    });

    test('a color of another class as the style of the context draws with '
        'its values at each fill', () {
      const odd = _OddColor(0xFF4F6BED);
      final observed = _observe((ctx) {
        ctx.fillStyle = odd;
        ctx.fillRect(2, 10, 4, 60);
        ctx.fillRect(8, 10, 4, 60);
        // The fused draw declines the class, also after a bar of the same
        // value.
        expect(_fused(ctx, 14, odd), isFalse);
        expect(_fused(ctx, 14, _blue), isTrue);
        expect(_fused(ctx, 20, odd), isFalse);
        ctx.fillRect(26, 10, 4, 60);
      });
      expect(observed.kept, 0);
      expect(_draws(observed).length, 4);
    });

    test('a gradient fill between two bars keeps the color of the solid '
        'paint', () {
      final observed = _observe((ctx) {
        _fused(ctx, 2, _blue);
        ctx.fillStyle = _gradient;
        ctx.fillRect(8, 10, 4, 60);
        _fused(ctx, 14, _blue);
        ctx.strokeStyle = _red;
        ctx.strokeRect(20, 10, 4, 60);
        _fused(ctx, 26, _blue);
      });
      expect(observed.kept, 2);
      final draws = _draws(observed);
      expect(
        [for (final call in draws) call.shader],
        [false, true, false, false, false],
      );
      expect([
        for (final call in draws) call.color,
      ], _paintedAll([_blue, _black, _blue, _red, _blue]));
      expect(identical(draws[0].paint, draws[2].paint), isTrue);
      expect(identical(draws[0].paint, draws[1].paint), isFalse);
    });

    test('a bar with a border writes its two colors in turn', () {
      final observed = _observe((ctx) {
        for (var i = 0; i < 4; i++) {
          expect(_ringed(ctx, 2.0 + i * 10, _teal, _dark), isTrue);
        }
      });
      expect(observed.kept, 0);
      final draws = _draws(observed);
      expect(
        [for (final call in draws) call.name],
        [
          for (var i = 0; i < 4; i++) ...['drawDRRect', 'drawRect'],
        ],
      );
      expect(
        [for (final call in draws) call.color],
        _paintedAll([
          for (var i = 0; i < 4; i++) ...[_dark, _teal],
        ]),
      );
    });
  });

  group('the rectangles of a fused bar', () {
    test('a bar with no border makes one rectangle draw', () {
      final observed = _observe((ctx) {
        ctx.setTransform(2, 0, 0, 2, 3, 5);
        expect(_fused(ctx, 4, _blue), isTrue);
      });
      expect([for (final call in observed.calls) call.name], ['drawRect']);
      expect(
        observed.calls.single.text,
        contains('${const ui.Rect.fromLTWH(11, 25, 8, 120)}'),
      );
      expect(observed.path, const ui.Rect.fromLTWH(11, 25, 8, 120));
    });

    test('equal sizes at another position map both rectangles', () {
      // The element never asks for this. The outer rectangle is not the
      // inner one, so it gets its own finite test.
      final observed = _observe((ctx) {
        ctx.scale(1e150, 1);
        expect(
          ctx.tryDrawRectBar(
            outerX: 1.6e158,
            outerY: 10,
            outerWidth: 1e157,
            outerHeight: 60,
            innerX: 1.6e158,
            innerY: 10,
            innerWidth: 1e157,
            innerHeight: 60,
            borderColor: _dark,
            backgroundColor: _blue,
          ),
          isTrue,
        );
        expect(
          ctx.tryDrawRectBar(
            outerX: 1.75e158,
            outerY: 10,
            outerWidth: 1e157,
            outerHeight: 60,
            innerX: 1.6e158,
            innerY: 10,
            innerWidth: 1e157,
            innerHeight: 60,
            borderColor: _dark,
            backgroundColor: _blue,
          ),
          isFalse,
        );
      });
      expect([for (final call in observed.calls) call.name], ['drawRect']);
    });

    test('a border whose outer rectangle is not finite declines', () {
      final observed = _observe((ctx) {
        ctx.scale(1e150, 1);
        bool ask(double outerWidth) => ctx.tryDrawRectBar(
          outerX: 0,
          outerY: 10,
          outerWidth: outerWidth,
          outerHeight: 60,
          innerX: 0,
          innerY: 10,
          innerWidth: 1.79e158,
          innerHeight: 60,
          borderColor: _dark,
          backgroundColor: _blue,
        );
        // The outer right edge maps to infinity, the inner one does not.
        expect(ask(1.8e158), isFalse);
        expect(ask(1.795e158), isTrue);
      });
      expect(_draws(observed), isNotEmpty);
    });
  });
}

// An object that is no color.
final class const _NoColor();
