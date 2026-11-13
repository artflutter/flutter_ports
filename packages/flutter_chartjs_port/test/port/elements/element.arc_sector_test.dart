// Original code, not ported from Chart.js: the fused native arc sector twins.
@TestOn('vm')
library;

// Keep canvas state transitions and their observations as separate steps.
// ignore_for_file: cascade_invocations

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:chartjs_test_utils/pure.dart' show MockContext;
import 'package:flutter_chartjs_port/src/canvas/canvas.dart'
    show CanvasCompositeOperation;
import 'package:flutter_chartjs_port/src/canvas/canvas_arc_sector.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/elements/element.arc.dart';
import 'package:flutter_chartjs_port/src/elements/element_options.dart';
import 'package:flutter_chartjs_port/src/types/arc_option_enums.dart'
    show ArcBorderAlign;
import 'package:flutter_chartjs_port/src/types/chart_paint.dart';
import 'package:flutter_test/flutter_test.dart';

import '../canvas/pixel_compare.dart';

/// A user subclass: it always takes the ordinary Canvas 2D sequence.
class _ReferenceArc extends ArcElement {
  _ReferenceArc(super.cfg);
}

/// A user subclass with a start angle that moves at each read: a read that the
/// ordinary path has must stay.
class _DriftingArc extends ArcElement {
  _DriftingArc(super.cfg);

  int reads = 0;

  @override
  double get startAngle {
    reads++;
    return super.startAngle + (reads - 1) * 0.1;
  }
}

/// A recording context that offers the capability and declines it.
class _Probe extends MockContext implements ArcSectorCanvas {
  _Probe({this.zeroTranslateIsNoOp = false});

  int probes = 0;

  @override
  final bool zeroTranslateIsNoOp;

  @override
  bool tryDrawArcSector({
    required double x,
    required double y,
    required double outerRadius,
    required double innerRadius,
    required double startAngle,
    required double endAngle,
    required Object? backgroundColor,
    required Object? borderColor,
  }) {
    probes++;
    return false;
  }
}

const _colors = [
  ui.Color(0xFF3366CC),
  ui.Color(0xFFDC3912),
  ui.Color(0xFFFF9900),
  ui.Color(0xFF109618),
  ui.Color(0xB0990099),
  ui.Color(0xFF0099C6),
];

Map<String, Object?> _options({
  Object? backgroundColor = const ui.Color(0xFF3366CC),
  Object? borderColor = const ui.Color(0xFFFFFFFF),
  Object? borderWidth = 0.0,
  Object? borderRadius = 0.0,
  Object? offset = 0.0,
  Object? spacing = 0.0,
  Object? borderAlign = ArcBorderAlign.center,
  Object? circular = true,
}) => {
  'backgroundColor': backgroundColor,
  'borderColor': borderColor,
  'borderWidth': borderWidth,
  'borderRadius': borderRadius,
  'offset': offset,
  'spacing': spacing,
  'borderAlign': borderAlign,
  'circular': circular,
  'selfJoin': false,
  'borderDash': <Object?>[],
  'borderDashOffset': 0.0,
};

Map<String, Object?> _cfg({
  double start = 0.3,
  double sweep = 1.1,
  double inner = 0,
  double outer = 60,
  double x = 80.25,
  double y = 79.5,
  Map<String, Object?>? options,
}) => {
  'x': x,
  'y': y,
  'startAngle': start,
  'endAngle': start + sweep,
  'circumference': sweep,
  'innerRadius': inner,
  'outerRadius': outer,
  'options': ArcOptions(options ?? _options()),
};

/// The slices of a chart, each with its own color, so that no two join.
List<Map<String, Object?>> _slices({double inner = 0}) => [
  for (var i = 0; i < 6; i++)
    _cfg(
      start: i * 1.047 - 1.5,
      sweep: 1.047,
      inner: inner,
      options: _options(backgroundColor: _colors[i]),
    ),
];

void _draw(UiCanvasContext ctx, List<Map<String, Object?>> cfgs, bool native) {
  for (final cfg in cfgs) {
    (native ? ArcElement(cfg) : _ReferenceArc(cfg)).draw(ctx);
  }
}

/// The two renders of [cfgs] on a context that [setUp] prepares.
Future<(Render, Render)> _twin(
  List<Map<String, Object?>> cfgs, {
  void Function(UiCanvasContext ctx)? setUp,
  void Function(UiCanvasContext ctx)? after,
}) async {
  Future<Render> render({required bool native}) => renderContext((ctx) {
    setUp?.call(ctx);
    _draw(ctx, cfgs, native);
    after?.call(ctx);
  });
  return (await render(native: true), await render(native: false));
}

void _expectSame(Render a, Render b) {
  final diff = comparePixels(a, b);
  expect(diff.differing, 0, reason: '$diff');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('twin of the ordinary sequence', () {
    for (final inner in [0.0, 24.5]) {
      final name = inner == 0 ? 'wedges' : 'ring sectors';

      test('$name: the same pixels', () async {
        final (a, b) = await _twin(_slices(inner: inner));
        _expectSame(a, b);
        expect(a.ink, greaterThan(1000));
      });

      for (final (label, transform)
          in <(String, void Function(UiCanvasContext))>[
            ('a translation', (c) => c.translate(3.25, -4.5)),
            (
              'a device pixel ratio',
              (c) => c.setTransform(2.625, 0, 0, 2.625, 0, 0),
            ),
            ('a small scale', (c) => c.scale(0.5, 0.5)),
            (
              'a rotation',
              (c) {
                c.translate(80, 80);
                c.rotate(0.7);
                c.translate(-80, -80);
              },
            ),
            (
              'a mirror',
              (c) {
                c.translate(160, 0);
                c.scale(-1, 1);
              },
            ),
            (
              'a mirror and a rotation',
              (c) {
                c.translate(80, 80);
                c.rotate(0.7);
                c.scale(1, -1);
                c.translate(-80, -80);
              },
            ),
          ]) {
        test('$name: the same pixels under $label', () async {
          final (a, b) = await _twin(_slices(inner: inner), setUp: transform);
          _expectSame(a, b);
        });
      }

      test('$name: the same pixels with globalAlpha', () async {
        final (a, b) = await _twin(
          _slices(inner: inner),
          setUp: (c) => c.globalAlpha = 0.45,
        );
        _expectSame(a, b);
      });

      test('$name: no pixels with globalAlpha 0, and no content', () async {
        final (a, b) = await _twin(
          _slices(inner: inner),
          setUp: (c) => c.globalAlpha = 0,
        );
        _expectSame(a, b);
        expect(a.ink, 0);
      });

      test('$name: the same pixels under each composite operation', () async {
        for (final op in CanvasCompositeOperation.values) {
          final (a, b) = await _twin(
            _slices(inner: inner),
            setUp: (c) {
              c.fillStyle = const ui.Color(0x8022AA44);
              c.fillRect(10, 10, 120, 70);
              c.globalCompositeOperation = op;
            },
          );
          final diff = comparePixels(a, b);
          expect(diff.differing, 0, reason: '$op: $diff');
        }
      });

      test('$name: the same pixels under a clip', () async {
        final (a, b) = await _twin(
          _slices(inner: inner),
          setUp: (c) {
            c.save();
            c.beginPath();
            c.rect(30.5, 20, 90, 100);
            c.clip();
          },
          after: (c) {
            c.restore();
            c.fillStyle = const ui.Color(0x80000000);
            c.fillRect(0, 0, 40, 40);
          },
        );
        _expectSame(a, b);
      });

      test('$name: the path of the sequence stays', () async {
        // Each later use of the current path, on the path of the last arc.
        for (final (label, use) in <(String, void Function(UiCanvasContext))>[
          ('stroke', (c) => c.stroke()),
          ('fill', (c) => c.fill()),
          ('evenodd fill', (c) => c.fill('evenodd')),
          (
            'a clip',
            (c) {
              c.clip();
              c.fillStyle = const ui.Color(0xFF000000);
              c.fillRect(0, 0, 160, 160);
            },
          ),
          (
            'lineTo after the close',
            (c) {
              c.lineTo(5, 7);
              c.stroke();
            },
          ),
          (
            'moveTo and lineTo',
            (c) {
              c.moveTo(5, 7);
              c.lineTo(50, 7);
              c.stroke();
            },
          ),
          (
            'an arc',
            (c) {
              c.arc(40, 40, 10, 0, 1);
              c.stroke();
            },
          ),
          (
            'arcTo from the current point',
            (c) {
              c.arcTo(20, 20, 40, 5, 6);
              c.stroke();
            },
          ),
          (
            'a rect',
            (c) {
              c.rect(5, 5, 20, 20);
              c.fill();
            },
          ),
          (
            'closePath',
            (c) {
              c.closePath();
              c.stroke();
            },
          ),
        ]) {
          final (a, b) = await _twin(
            _slices(inner: inner),
            setUp: (c) => c.strokeStyle = const ui.Color(0xFFAA2200),
            after: use,
          );
          final diff = comparePixels(a, b);
          expect(diff.differing, 0, reason: '$label: $diff');
        }
      });

      test('$name: the commands of the path are the ordinary ones', () {
        for (final transform in <void Function(UiCanvasContext)>[
          (_) {},
          (c) => c.setTransform(2, 0, 0, 2, 3, 4),
          (c) => c.rotate(0.4),
        ]) {
          final native = UiCanvasElement(
            width: 200,
            height: 200,
          ).getContext2d();
          final ordinary = UiCanvasElement(
            width: 200,
            height: 200,
          ).getContext2d();
          addTearDown(native.dispose);
          addTearDown(ordinary.dispose);
          transform(native);
          transform(ordinary);
          final cfg = _cfg(start: 0.4, sweep: 0.9, inner: inner);
          ArcElement(cfg).draw(native);
          _ReferenceArc(cfg).draw(ordinary);
          expect(native.debugPendingSectors, 1);
          expect(native.debugPath.debugBuilt, isFalse);
          expect(native.debugPath.isEmpty, isFalse);
          expect(native.debugPath.hasSubpath, isTrue);
          expect(native.debugPath.hasSingleCircle, isFalse);
          expect(native.debugPath.singleRect, isNull);
          expect(native.debugPath.singleRRect, isNull);
          expect(native.debugPath.shapePair, isNull);
          expect(
            native.debugPath.singleSector,
            ordinary.debugPath.singleSector,
          );
          expect(native.debugPath.singleSector, isNotNull);
          final a = native.debugPath.path;
          final b = ordinary.debugPath.path;
          expect(a.getBounds(), b.getBounds());
          final ma = a.computeMetrics().toList();
          final mb = b.computeMetrics().toList();
          expect(ma.length, mb.length);
          for (var i = 0; i < ma.length; i++) {
            expect(ma[i].length, mb[i].length);
            expect(ma[i].isClosed, mb[i].isClosed);
          }
        }
      });
    }

    test('a slice below the width of beta, as pathArc widens it', () async {
      // alpha * outerRadius below 0.001: beta is wider than the slice.
      final cfgs = [
        for (var i = 0; i < 6; i++)
          _cfg(
            start: i * 0.5,
            sweep: 1e-6,
            options: _options(backgroundColor: _colors[i]),
          ),
      ];
      final (a, b) = await _twin(cfgs);
      _expectSame(a, b);
      final native = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(native.dispose);
      ArcElement(cfgs.first).draw(native);
      expect(native.debugPendingSectors, 1);
    });

    test('pending circles and fused arcs keep their order', () async {
      final (a, b) = await _twin(
        _slices(),
        setUp: (c) {
          c.fillStyle = const ui.Color(0x80000000);
          for (var i = 0; i < 40; i++) {
            c.beginPath();
            c.arc(40.0 + i, 60, 6, 0, 2 * math.pi);
            c.fill();
          }
        },
        after: (c) {
          c.fillStyle = const ui.Color(0x8000AA00);
          for (var i = 0; i < 40; i++) {
            c.beginPath();
            c.arc(40.0 + i, 90, 6, 0, 2 * math.pi);
            c.fill();
          }
        },
      );
      _expectSame(a, b);
    });

    test('a long frame splits its recording and keeps its pixels', () async {
      final cfgs = [
        for (var i = 0; i < 700; i++)
          _cfg(
            start: i * 2 * math.pi / 700,
            sweep: 2 * math.pi / 700,
            inner: 20,
            options: _options(backgroundColor: _colors[i % 2]),
          ),
      ];
      final (a, b) = await _twin(cfgs);
      _expectSame(a, b);
      final native = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(native.dispose);
      _draw(native, cfgs, true);
      expect(native.debugPictureCount, greaterThan(1));
    });

    test('the styles, the transform and the save depth stay', () {
      const caller = ui.Color(0xFF33BB55);
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d()
        ..fillStyle = caller
        ..strokeStyle = caller
        ..lineWidth = 3;
      addTearDown(ctx.dispose);
      ctx.translate(1, 2);
      ArcElement(_cfg()).draw(ctx);
      expect(ctx.debugPendingSectors, 1);
      expect(ctx.fillStyle, caller);
      expect(ctx.strokeStyle, caller);
      expect(ctx.lineWidth, 3);
      // restore() with no save does nothing: the depth is 0.
      ctx.restore();
      expect(ctx.debugPendingSectors, 1);
    });

    test('the element writes pixelMargin and fullCircles first', () {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      final arc = ArcElement(_cfg());
      arc.pixelMargin = 5;
      arc.fullCircles = 7;
      arc.draw(ctx);
      expect(ctx.debugPendingSectors, 1);
      expect(arc.pixelMargin, 0);
      expect(arc.fullCircles, 0);
    });
  });

  group('slices of one color', () {
    test('join across the rounding of the angles of pathArc', () {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      final random = math.Random(3);
      final sweeps = [
        for (var i = 0; i < 400; i++) 0.002 + random.nextDouble() * 0.02,
      ];
      final total = sweeps.reduce((a, b) => a + b);
      expect(total, lessThan(2 * math.pi - 0.01));
      var start = -math.pi / 2;
      for (final sweep in sweeps) {
        ArcElement(_cfg(start: start, sweep: sweep, inner: 15)).draw(ctx);
        start += sweep;
      }
      expect(ctx.debugPendingSectors, sweeps.length);
    });

    test('do not join when pathArc widens a slice', () {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      var start = 0.0;
      for (var i = 0; i < 4; i++) {
        ArcElement(_cfg(start: start, sweep: 1e-6)).draw(ctx);
        start += 1e-6;
      }
      expect(ctx.debugPendingSectors, 1);
    });
  });

  group('each guard falls back', () {
    final declines = <String, Map<String, Object?>>{
      'a border': _cfg(options: _options(borderWidth: 2.0)),
      'an offset': _cfg(options: _options(offset: 8.0)),
      'a spacing': _cfg(options: _options(spacing: 4.0)),
      'rounded corners': _cfg(options: _options(borderRadius: 3.0)),
      'corners of an object': _cfg(
        options: _options(
          borderRadius: <String, Object?>{'outerStart': 0.0},
        ),
      ),
      'the inner border align': _cfg(
        options: _options(borderAlign: ArcBorderAlign.inner),
      ),
      'a non-circular arc': _cfg(options: _options(circular: false)),
      'a foreign border width': _cfg(options: _options(borderWidth: '0')),
      'a full circle': _cfg(start: 0, sweep: 2 * math.pi),
      'more than a full circle': _cfg(start: 0, sweep: 7),
      'a negative sweep': {..._cfg(), 'endAngle': -1.0},
      'no radius': _cfg(outer: 0),
      'the undefined outer radius': {..._cfg()}..remove('outerRadius'),
    };

    for (final MapEntry(key: name, value: cfg) in declines.entries) {
      test('$name: no capability call, and the same calls', () {
        final probe = _Probe();
        final expected = MockContext();
        ArcElement(cfg).draw(probe);
        _ReferenceArc(cfg).draw(expected);
        expect(probe.probes, 0);
        expect(probe.getCalls(), expected.getCalls());
      });
    }

    test('a user subclass does not offer the capability', () {
      final probe = _Probe();
      _ReferenceArc(_cfg()).draw(probe);
      expect(probe.probes, 0);
    });

    test('a decline gives the calls of a context with no capability', () {
      final probe = _Probe();
      final expected = MockContext();
      ArcElement(_cfg()).draw(probe);
      _ReferenceArc(_cfg()).draw(expected);
      expect(probe.probes, 1);
      expect(probe.getCalls(), expected.getCalls());
      final calls = [for (final c in expected.getCalls()) c['name']];
      expect(calls, contains('translate'));
    });

    test('colors that the canvas declines take the setter path', () {
      final expectThrows = [
        _cfg(options: _options(backgroundColor: 'red')),
        _cfg(options: _options(borderColor: 'red')),
      ];
      for (final cfg in expectThrows) {
        final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
        addTearDown(ctx.dispose);
        expect(() => ArcElement(cfg).draw(ctx), throwsArgumentError);
        expect(ctx.debugPendingSectors, 0);
      }
    });

    test('an absent color keeps the style of the canvas', () async {
      final options = _options()..remove('backgroundColor');
      final cfg = _cfg(options: options);
      final (a, b) = await _twin(
        [cfg],
        setUp: (c) => c.fillStyle = const ui.Color(0xFF00AA00),
      );
      _expectSame(a, b);
      expect(a.ink, greaterThan(100));
    });

    test(
      'a color of a subclass and a gradient take the ordinary path',
      () async {
        for (final background in <Object Function(UiCanvasContext)>[
          (_) => const _OtherColor(0xFF118822),
          (c) => const ChartGradient.linear(
            ui.Offset.zero,
            ui.Offset(160, 0),
            [ui.Color(0xFFFF0000), ui.Color(0xFF0000FF)],
          ),
        ]) {
          Future<Render> render({required bool native}) => renderContext((ctx) {
            final cfg = _cfg(
              options: _options(backgroundColor: background(ctx)),
            );
            (native ? ArcElement(cfg) : _ReferenceArc(cfg)).draw(ctx);
            expect(ctx.debugPendingSectors, 0);
          });
          _expectSame(await render(native: true), await render(native: false));
        }
      },
    );

    test('a transform that is no similarity takes the ordinary path', () async {
      final (a, b) = await _twin(
        _slices(),
        setUp: (c) => c.scale(1.5, 0.5),
      );
      _expectSame(a, b);
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      ctx.scale(1.5, 0.5);
      ArcElement(_cfg()).draw(ctx);
      expect(ctx.debugPendingSectors, 0);
    });

    test('a singular transform draws nothing on both paths', () async {
      final (a, b) = await _twin(_slices(), setUp: (c) => c.scale(0, 0));
      _expectSame(a, b);
      expect(a.ink, 0);
    });

    test('a center that is not finite or too far takes the ordinary path', () {
      for (final x in [double.nan, double.infinity, 2e5]) {
        final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
        addTearDown(ctx.dispose);
        ArcElement(_cfg(x: x)).draw(ctx);
        expect(ctx.debugPendingSectors, 0);
      }
    });

    test('a first change notification takes the ordinary path', () {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      var notified = 0;
      Object? style;
      ctx.onChanged = () {
        notified++;
        // The observer sees the temporary style of the sequence.
        style = ctx.fillStyle;
      };
      ArcElement(_cfg()).draw(ctx);
      expect(notified, 1);
      expect(style, _options()['backgroundColor']);
      expect(ctx.debugPendingSectors, 0);
      // Later arcs of the frame take the fused route.
      ArcElement(_cfg(start: 2)).draw(ctx);
      expect(notified, 1);
      expect(ctx.debugPendingSectors, 1);
    });

    test('a picture or image observer takes the ordinary path', () {
      final hooks = <void Function()>[
        () => ui.Picture.onCreate = (_) {},
        () => ui.Picture.onDispose = (_) {},
        () => ui.Image.onCreate = (_) {},
        () => ui.Image.onDispose = (_) {},
      ];
      for (final set in hooks) {
        final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
        addTearDown(ctx.dispose);
        set();
        try {
          ArcElement(_cfg()).draw(ctx);
          expect(ctx.debugPendingSectors, 0);
        } finally {
          ui.Picture.onCreate = null;
          ui.Picture.onDispose = null;
          ui.Image.onCreate = null;
          ui.Image.onDispose = null;
        }
      }
    });

    test('a disposed context does nothing', () {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      ctx.dispose();
      ArcElement(_cfg()).draw(ctx);
      expect(ctx.debugPendingSectors, 0);
      expect(ctx.isEmpty, isTrue);
    });
  });

  group('a circumference of -Infinity', () {
    // `Math.sin(-Infinity)` is NaN, so `fix` and `offset * fix` are NaN, also
    // for an offset of 0 (element.arc.ts:483-484): the arc has no radius.
    Map<String, Object?> cfg({double borderWidth = 0}) => {
      ..._cfg(
        start: 0,
        sweep: 1,
        x: 80,
        y: 80,
        options: _options(borderWidth: borderWidth),
      ),
      'circumference': double.negativeInfinity,
    };

    for (final borderWidth in const [0.0, 2.0]) {
      test('a border width of $borderWidth: a recording context gets NaN', () {
        for (final element in [
          ArcElement(cfg(borderWidth: borderWidth)),
          _ReferenceArc(cfg(borderWidth: borderWidth)),
        ]) {
          final ctx = MockContext();
          element.draw(ctx);
          final arc = ctx.getCalls().firstWhere((c) => c['name'] == 'arc');
          final args = arc['args']! as List<Object?>;
          expect((args[2]! as double).isNaN, isTrue, reason: '$args');
        }
      });

      test(
        'a border width of $borderWidth: the native canvas draws nothing',
        () async {
          for (final native in [true, false]) {
            final render = await renderContext(
              (ctx) => _draw(ctx, [cfg(borderWidth: borderWidth)], native),
            );
            expect(render.ink, 0, reason: 'exact class: $native');
          }
        },
      );
    }

    test('the exact class offers no sector', () {
      final probe = _Probe();
      ArcElement(cfg()).draw(probe);
      expect(probe.probes, 0);
      final finite = _Probe();
      ArcElement(_cfg()).draw(finite);
      expect(finite.probes, 1);
    });

    test('another circumference does not change the arc', () async {
      for (final circumference in const [-1.0, double.nan, 0.5]) {
        final (a, b) = await _twin([
          {..._cfg(start: 0, sweep: 1), 'circumference': circumference},
        ]);
        _expectSame(a, b);
        expect(a.ink, greaterThan(100), reason: '$circumference');
      }
    });
  });

  group('no zero translation on the native canvas', () {
    test('a bordered arc gives the pixels of the ordinary path', () async {
      final cfgs = [
        for (var i = 0; i < 6; i++)
          _cfg(
            start: i * 1.047 - 1.5,
            sweep: 1.047,
            inner: i.isEven ? 0 : 20,
            options: _options(
              backgroundColor: _colors[i],
              borderWidth: 2.0,
            ),
          ),
      ];
      // The ordinary sequence translates by zero: the arc comes out the same.
      Future<Render> render({required bool translated}) => renderContext((ctx) {
        ctx.setTransform(2, 0, 0, 2, -82.5, -77);
        for (final cfg in cfgs) {
          if (translated) ctx.translate(-0, 0);
          ArcElement(cfg).draw(ctx);
        }
      });
      final a = await render(translated: false);
      final b = await render(translated: true);
      _expectSame(a, b);
      expect(a.ink, greaterThan(1000));
    });

    test('an offset still translates', () async {
      final cfg = _cfg(options: _options(offset: 16.0));
      final (a, b) = await _twin([cfg]);
      _expectSame(a, b);
      expect(a.ink, greaterThan(100));
    });

    test('a recording context keeps the translate with an offset of 0', () {
      final ctx = MockContext();
      ArcElement(_cfg(options: _options(borderWidth: 2.0))).draw(ctx);
      final calls = [for (final c in ctx.getCalls()) c['name']];
      expect(calls.first, 'save');
      expect(calls[1], 'translate');
    });

    test('only the exact class skips the translation', () {
      List<Object?> calls(ArcElement element) {
        final probe = _Probe(zeroTranslateIsNoOp: true);
        element.draw(probe);
        return [for (final c in probe.getCalls()) c['name']];
      }

      final cfg = _cfg(options: _options(borderWidth: 2.0));
      expect(calls(ArcElement(cfg)), isNot(contains('translate')));
      expect(calls(_ReferenceArc(cfg)), contains('translate'));
    });

    test('a user subclass keeps its reads of the ordinary path', () {
      for (final options in [_options(), _options(borderWidth: 2.0)]) {
        final recorded = _DriftingArc(_cfg(options: options));
        final calls = MockContext();
        recorded.draw(calls);
        expect(
          [for (final c in calls.getCalls()) c['name']],
          contains('translate'),
        );
        final native = _DriftingArc(_cfg(options: options));
        final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
        addTearDown(ctx.dispose);
        native.draw(ctx);
        expect(native.reads, recorded.reads);
      }
    });

    test('the canvas answers for a finite matrix only', () {
      final ctx = UiCanvasElement(width: 16, height: 16).getContext2d();
      addTearDown(ctx.dispose);
      expect(ctx.zeroTranslateIsNoOp, isTrue);
      ctx.scale(1e308, 1e308);
      expect(ctx.zeroTranslateIsNoOp, isTrue);
      ctx.scale(1e308, 1e308);
      expect(ctx.zeroTranslateIsNoOp, isFalse);
    });
  });
}

class _OtherColor extends ui.Color {
  const _OtherColor(super.value);
}
