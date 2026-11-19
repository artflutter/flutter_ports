// Original code, not ported from Chart.js: fused rounded-bar twins.
@TestOn('vm')
library;

// Keep canvas state transitions and their observations as separate steps.
// ignore_for_file: cascade_invocations

import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:chartjs_test_utils/pure.dart' show MockContext;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pixel_compare.dart';

/// A bar of a subclass: `_builtIn` is false, so it draws with the ordinary
/// sequence of element.bar.js:179-200 (the reference of each twin).
class _ReferenceBar(super.cfg) extends BarElement;

/// A mock context that records each offer of a fused rounded bar as the
/// `roundRect` calls of the ordinary sequence, and declines it.
class _Probe() extends MockContext implements RectBarCanvas {
  final List<List<Object?>> offers = [];
  int rectProbes = 0;

  @override
  bool tryDrawRectBar({
    required double outerX,
    required double outerY,
    required double outerWidth,
    required double outerHeight,
    required double innerX,
    required double innerY,
    required double innerWidth,
    required double innerHeight,
    required Object? borderColor,
    required Object? backgroundColor,
  }) {
    rectProbes++;
    return false;
  }

  @override
  bool tryDrawRoundedBar({
    required bool border,
    required double outerX,
    required double outerY,
    required double outerWidth,
    required double outerHeight,
    required double outerUpperLeft,
    required double outerUpperRight,
    required double outerLowerRight,
    required double outerLowerLeft,
    required double innerX,
    required double innerY,
    required double innerWidth,
    required double innerHeight,
    required double innerUpperLeft,
    required double innerUpperRight,
    required double innerLowerRight,
    required double innerLowerLeft,
    required Object? borderColor,
    required Object? backgroundColor,
  }) {
    final inner = [
      innerX,
      innerY,
      innerWidth,
      innerHeight,
      [innerUpperLeft, innerUpperRight, innerLowerRight, innerLowerLeft],
    ];
    if (border) {
      offers.add([
        outerX,
        outerY,
        outerWidth,
        outerHeight,
        [outerUpperLeft, outerUpperRight, outerLowerRight, outerLowerLeft],
      ]);
      offers.add(inner);
    }
    offers.add(inner);
    return false;
  }
}

const _border = ui.Color(0xB04488CC);
const _background = ui.Color(0x70DD8855);
const _caller = ui.Color(0xFF33BB55);

BorderSkipped _skip(String edges) => BorderSkipped()
  ..top = edges.contains('t')
  ..right = edges.contains('r')
  ..bottom = edges.contains('b')
  ..left = edges.contains('l');

Map<String, Object?> _cfg({
  double width = 24,
  bool horizontal = false,
  Object? radius = 6.0,
  double inflate = 0,
  Object? borderColor = _border,
  Object? backgroundColor = _background,
  Object? borderWidth = 2.0,
  String skipped = 'b',
  bool enable = true,
}) => {
  'x': 60.25,
  'y': 35.5,
  'base': 110.25,
  'width': width,
  'height': width,
  'horizontal': horizontal,
  'enableBorderRadius': enable,
  'inflateAmount': inflate,
  'borderSkipped': _skip(skipped),
  'options': BarOptions({
    'borderWidth': borderWidth,
    'borderRadius': radius,
    'borderColor': borderColor,
    'backgroundColor': backgroundColor,
  }),
};

/// The geometry cases: thin and wide bars, a radius above half the width, a
/// border wider than the bar, each skipped edge, both orientations and a
/// bar with its corners off.
final List<Map<String, Object?>> _cases = [
  for (final horizontal in [false, true])
    for (final width in [0.04, 5.5, 24.0])
      for (final radius in [0.75, 6.0, 100.0])
        for (final borderWidth in [0.0, 1.5, 4.0, 40.0])
          for (final skipped in ['b', '', 'tl', 'trbl'])
            _cfg(
              width: width,
              horizontal: horizontal,
              radius: radius,
              borderWidth: borderWidth,
              skipped: skipped,
            ),
  _cfg(enable: false),
  _cfg(radius: 3),
  _cfg(radius: -4.0),
  _cfg(radius: double.nan),
  _cfg(radius: double.infinity, borderWidth: double.infinity),
];

String _describe(Map<String, Object?> cfg) {
  final options = cfg['options']! as BarOptions;
  final skip = cfg['borderSkipped']! as BorderSkipped;
  return 'w ${cfg['width']} h ${cfg['horizontal']} '
      'r ${options.borderRadiusValue} b ${options.borderWidthValue} '
      'skip ${skip.top}${skip.right}${skip.bottom}${skip.left} '
      'enable ${cfg['enableBorderRadius']}';
}

/// Draws a bar the way a chart does, inside a clip, under a transform, with
/// the composite operation [blend] and the alpha [alpha], then strokes the
/// final path and fills one more rectangle with the caller color.
Future<Render> _render(
  BarElement bar, {
  CanvasCompositeOperation blend = CanvasCompositeOperation.sourceOver,
  double alpha = 1,
  bool reflected = false,
  List<Object?>? state,
}) => renderContext((ctx) {
  ctx.fillStyle = const ui.Color(0xFFEEEEEE);
  ctx.fillRect(0, 0, 160, 160);
  ctx.save();
  ctx.setTransform(
    reflected ? -1.25 : 1.25,
    0,
    0,
    0.75,
    reflected ? 159.5 : 0.5,
    1.5,
  );
  ctx.beginPath();
  ctx.rect(4, 5, 110, 120);
  ctx.clip();
  ctx.fillStyle = _caller;
  ctx.globalAlpha = alpha;
  ctx.globalCompositeOperation = blend;
  bar.draw(ctx);
  state?.addAll([
    ctx.fillStyle,
    ctx.globalAlpha,
    ctx.globalCompositeOperation,
    ctx.debugPath.singleRRect,
    ctx.debugPath.singleRect,
    // The final path itself: an RRect, or the segments of a reflection.
    ctx.debugPath.path.getBounds(),
    ctx.debugPath.path.computeMetrics().map((m) => m.length).toList(),
  ]);
  // The final inner path remains available to a later stroke.
  ctx.strokeStyle = const ui.Color(0x80443322);
  ctx.lineWidth = 0.5;
  ctx.stroke();
  ctx.restore();
  ctx.fillStyle = _caller;
  ctx.fillRect(1, 1, 3, 3);
});

bool _direct(
  UiCanvasContext ctx, {
  bool border = true,
  Object? borderColor = _border,
  Object? backgroundColor = _background,
  double outerWidth = 30,
  double innerWidth = 26,
  double radius = 6,
}) => ctx.tryDrawRoundedBar(
  border: border,
  outerX: 10,
  outerY: 10,
  outerWidth: outerWidth,
  outerHeight: 60,
  outerUpperLeft: radius,
  outerUpperRight: radius,
  outerLowerRight: 0,
  outerLowerLeft: 0,
  innerX: 12,
  innerY: 12,
  innerWidth: innerWidth,
  innerHeight: 58,
  innerUpperLeft: 4,
  innerUpperRight: 4,
  innerLowerRight: 0,
  innerLowerLeft: 0,
  borderColor: borderColor,
  backgroundColor: backgroundColor,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('CHART_IMPELLER=1 runs on Impeller', () {
    if (Platform.environment['CHART_IMPELLER'] == '1') {
      expect(ui.ImageFilter.isShaderFilterSupported, isTrue);
    }
  });

  test('the element offers the roundRect numbers of the ordinary sequence '
      'and keeps its calls on a decline', () {
    var offered = 0;
    for (final cfg in _cases) {
      final probe = _Probe();
      final expected = MockContext();
      BarElement(cfg).draw(probe);
      _ReferenceBar(cfg).draw(expected);
      final reason = _describe(cfg);
      expect(probe.getCalls(), expected.getCalls(), reason: reason);
      if (probe.offers.isEmpty) continue;
      offered++;
      final roundRects = [
        for (final call in expected.getCalls())
          if (call['name'] == 'roundRect') call['args'],
      ];
      expect(probe.offers, roundRects, reason: reason);
      expect(probe.rectProbes, 0, reason: reason);
    }
    // Each rounded case with an area offers the fused bar.
    expect(offered, greaterThan(150));
    // A bar with its corners off, or each corner skipped, is a plain bar.
    for (final cfg in [
      _cfg(enable: false),
      _cfg(skipped: 'trbl'),
      _cfg(radius: double.nan),
    ]) {
      final probe = _Probe();
      BarElement(cfg).draw(probe);
      expect(probe.offers, isEmpty, reason: _describe(cfg));
      expect(probe.rectProbes, 1, reason: _describe(cfg));
    }
    // An inflated bar and a radius object keep the ordinary sequence.
    for (final cfg in [
      _cfg(inflate: 0.33),
      _cfg(radius: <String, Object?>{'topLeft': 5}),
    ]) {
      final probe = _Probe();
      BarElement(cfg).draw(probe);
      expect(probe.offers, isEmpty);
      expect(probe.rectProbes, 0);
    }
  });

  test('exact pixels, state and final path for each geometry case', () async {
    for (final cfg in _cases) {
      for (final reflected in [false, true]) {
        final stateA = <Object?>[];
        final stateB = <Object?>[];
        final a = await _render(
          BarElement(cfg),
          reflected: reflected,
          state: stateA,
        );
        final b = await _render(
          _ReferenceBar(cfg),
          reflected: reflected,
          state: stateB,
        );
        final reason = '${_describe(cfg)} reflected $reflected';
        expect(stateA, stateB, reason: reason);
        expect(a.bytes, b.bytes, reason: reason);
      }
    }
  });

  for (final blend in CanvasCompositeOperation.values) {
    test('exact pixels and state for $blend', () async {
      for (final cfg in [
        _cfg(),
        _cfg(borderWidth: 0.0, skipped: ''),
        _cfg(width: 0.04, horizontal: true),
        _cfg(borderWidth: 40.0, radius: 100.0),
      ]) {
        for (final alpha in [0.0, 0.65, 1.0]) {
          final stateA = <Object?>[];
          final stateB = <Object?>[];
          final a = await _render(
            BarElement(cfg),
            blend: blend,
            alpha: alpha,
            state: stateA,
          );
          final b = await _render(
            _ReferenceBar(cfg),
            blend: blend,
            alpha: alpha,
            state: stateB,
          );
          final reason = '${_describe(cfg)} $alpha';
          expect(stateA, stateB, reason: reason);
          expect(a.bytes, b.bytes, reason: reason);
        }
      }
    });
  }

  test('the native context takes the bar and keeps the caller styles', () {
    final ctx = UiCanvasElement(width: 160, height: 160).getContext2d()
      ..fillStyle = _caller
      ..strokeStyle = _border
      ..lineWidth = 3;
    addTearDown(ctx.dispose);
    expect(_direct(ctx), isTrue);
    expect(ctx.fillStyle, _caller);
    expect(ctx.strokeStyle, _border);
    expect(ctx.lineWidth, 3);
    expect(
      ctx.debugPath.singleRRect,
      ui.RRect.fromLTRBAndCorners(
        12,
        12,
        38,
        70,
        topLeft: const ui.Radius.circular(4),
        topRight: const ui.Radius.circular(4),
      ),
    );
    // The element takes the fused bar: the second fill of the same color
    // keeps the solid paint, which the ordinary fill never does.
    for (final (bar, kept) in [
      (BarElement(_cfg(borderWidth: 0.0)), true),
      (_ReferenceBar(_cfg(borderWidth: 0.0)), false),
    ]) {
      final other = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(other.dispose);
      bar.draw(other);
      final before = other.debugKeptFillPaints;
      bar.draw(other);
      expect(other.debugKeptFillPaints > before, kept);
    }
  });

  test('shadows, rotations, gradients, invalid colors, rings that are not '
      'nested and callbacks decline with no effect', () {
    final ctx = UiCanvasElement(width: 160, height: 160).getContext2d()
      ..fillStyle = _caller
      ..beginPath()
      ..rect(1, 2, 3, 4);
    addTearDown(ctx.dispose);
    final path = ctx.debugPath.singleRect;
    const gradient = ChartGradient.linear(ui.Offset.zero, ui.Offset(30, 0), [
      _border,
      _background,
    ]);
    expect(_direct(ctx, backgroundColor: gradient), isFalse);
    expect(_direct(ctx, borderColor: 'invalid'), isFalse);
    expect(_direct(ctx, backgroundColor: 'invalid'), isFalse);
    // The inner shape is wider than the outer shape: no ring.
    expect(_direct(ctx, innerWidth: 40), isFalse);
    expect(_direct(ctx, radius: -1), isFalse);
    expect(_direct(ctx, radius: double.infinity), isFalse);
    expect(ctx.debugPath.singleRect, path);
    expect(ctx.fillStyle, _caller);
    expect(ctx.debugPictureCount, 0);
    // Without a border, the border color is not read.
    expect(_direct(ctx, border: false, borderColor: 'invalid'), isTrue);
    ctx.beginPath();
    ctx.rect(1, 2, 3, 4);
    ctx.save();
    ctx.shadowColor = const ui.Color(0x80000000);
    ctx.shadowBlur = 4;
    expect(_direct(ctx), isFalse);
    ctx.restore();
    ctx.rotate(0.25);
    expect(_direct(ctx), isFalse);
    ctx.resetTransform();
    expect(ctx.debugPath.singleRect, path);
    var notices = 0;
    ctx.onChanged = () => notices++;
    expect(_direct(ctx), isFalse);
    expect(notices, 0);
    BarElement(_cfg()).draw(ctx);
    expect(notices, 1);
    expect(_direct(ctx), isTrue);
    expect(notices, 1);
  });

  test('a shadow, a reflection, a clip and a path append keep the pixels '
      'of the ordinary sequence', () async {
    for (final reflected in [false, true]) {
      for (final shadow in [false, true]) {
        Future<Render> draw(BarElement bar) => renderContext((ctx) {
          const gradient = ChartGradient.linear(
            ui.Offset.zero,
            ui.Offset(120, 0),
            [_border, _background],
          );
          ctx.fillStyle = gradient;
          ctx.setTransform(
            reflected ? -1.0 : 1.0,
            0,
            0,
            1,
            reflected ? 150 : 0,
            0,
          );
          ctx.save();
          if (shadow) {
            ctx.shadowColor = const ui.Color(0x80000000);
            ctx.shadowBlur = 3;
            ctx.shadowOffsetX = 2;
          }
          ctx.beginPath();
          ctx.roundRect(4, 4, 135, 135, 8);
          ctx.clip();
          bar.draw(ctx);
          expect(identical(ctx.fillStyle, gradient), isTrue);
          ctx.rect(20, 30, 12, 17);
          ctx.fill('evenodd');
          ctx.restore();
        });
        final a = await draw(BarElement(_cfg()));
        final b = await draw(_ReferenceBar(_cfg()));
        expect(a.bytes, b.bytes, reason: '$reflected $shadow');
      }
    }
  });

  test('notifications see the original intermediate state', () async {
    final observations = <List<Object?>>[];
    Future<Render> draw(BarElement bar) {
      final seen = <Object?>[];
      observations.add(seen);
      return renderContext((ctx) {
        ctx.fillStyle = _caller;
        ctx.onChanged = () {
          seen.add(ctx.fillStyle);
          seen.add(ctx.debugPath.singleRRect);
          ctx.translate(2, 1);
          ctx.fillStyle = _caller;
        };
        bar.draw(ctx);
        ctx.onChanged = null;
        ctx.fillRect(2, 3, 4, 5);
      });
    }

    final a = await draw(BarElement(_cfg()));
    final b = await draw(_ReferenceBar(_cfg()));
    expect(observations[0], observations[1]);
    expect(a.bytes, b.bytes);
  });

  test('pending circles and recording splits keep the order and the '
      'pixels', () async {
    final counts = <int>[];
    Future<Render> draw(BarElement bar) => renderContext((ctx) {
      ctx.fillStyle = _caller;
      for (var i = 0; i < 30; i++) {
        ctx.beginPath();
        ctx.arc(60, 60, 8, 0, 6.283185307179586);
        ctx.fill();
      }
      for (var i = 0; i < 400; i++) {
        bar.draw(ctx);
      }
      counts.add(ctx.debugPictureCount);
      ctx.fillStyle = _caller;
      ctx.fillRect(2, 3, 4, 5);
    });
    final a = await draw(BarElement(_cfg(width: 0.04)));
    final b = await draw(_ReferenceBar(_cfg(width: 0.04)));
    expect(counts[0], counts[1]);
    expect(counts[0], greaterThan(1));
    expect(a.bytes, b.bytes);
  });

  test('an invalid background throws after the same border and state '
      'changes', () async {
    final states = <List<Object?>>[];
    Future<Render> draw(BarElement bar) => renderContext((ctx) {
      ctx.fillStyle = _caller;
      expect(() => bar.draw(ctx), throwsArgumentError);
      states.add([ctx.fillStyle, ctx.debugPath.singleRRect]);
      ctx.restore();
      ctx.fillRect(2, 3, 4, 5);
    });
    final a = await draw(BarElement(_cfg(backgroundColor: 'invalid')));
    final b = await draw(_ReferenceBar(_cfg(backgroundColor: 'invalid')));
    expect(states[0], states[1]);
    expect(a.bytes, b.bytes);
  });

  test('a disposed context declines', () {
    final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
    expect(_direct(ctx), isTrue);
    ctx.dispose();
    expect(_direct(ctx), isFalse);
  });
}
