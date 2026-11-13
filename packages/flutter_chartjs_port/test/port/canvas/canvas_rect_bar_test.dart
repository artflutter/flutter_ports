// Original code, not ported from Chart.js: native rectangle-bar pixel/state twins.
@TestOn('vm')
library;

// Keep canvas state transitions and their observations as separate steps.
// ignore_for_file: cascade_invocations

import 'dart:ui' as ui;

import 'package:chartjs_test_utils/pure.dart' show MockContext;
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_rect_bar.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/elements/element.bar.dart';
import 'package:flutter_chartjs_port/src/elements/element_options.dart';
import 'package:flutter_chartjs_port/src/options/props.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pixel_compare.dart';

class _ReferenceBar(super.cfg) extends BarElement;

class _Probe() extends MockContext implements RectBarCanvas {
  int probes = 0;
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
    probes++;
    return false;
  }
}

const _border = ui.Color(0xB04488CC);
const _background = ui.Color(0x70DD8855);
const _caller = ui.Color(0xFF33BB55);
Map<String, Object?> _cfg({
  double width = 24,
  bool horizontal = false,
  Object? radius = 0.0,
  double inflate = 0,
  Object? borderColor = _border,
  Object? backgroundColor = _background,
  double borderWidth = 1,
}) => {
  'x': 60.25,
  'y': 35.5,
  'base': 110.25,
  'width': width,
  'height': width,
  'horizontal': horizontal,
  'enableBorderRadius': true,
  'inflateAmount': inflate,
  'borderSkipped': BorderSkipped()..bottom = true,
  'options': BarOptions({
    'borderWidth': borderWidth,
    'borderRadius': radius,
    'borderColor': borderColor,
    'backgroundColor': backgroundColor,
  }),
};
bool _direct(
  UiCanvasContext ctx, {
  Object? border = _border,
  Object? fill = _background,
}) => ctx.tryDrawRectBar(
  outerX: 10,
  outerY: 10,
  outerWidth: 30,
  outerHeight: 60,
  innerX: 11,
  innerY: 11,
  innerWidth: 28,
  innerHeight: 59,
  borderColor: border,
  backgroundColor: fill,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'native capability accepts ordinary geometry without changing styles',
    () {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d()
        ..fillStyle = _caller
        ..strokeStyle = _border
        ..lineWidth = 3;
      addTearDown(ctx.dispose);
      expect(_direct(ctx), isTrue);
      expect(ctx.fillStyle, _caller);
      expect(ctx.strokeStyle, _border);
      expect(ctx.lineWidth, 3);
      expect(ctx.debugPath.singleRect, const ui.Rect.fromLTWH(11, 11, 28, 59));
    },
  );

  test(
    'element offers the capability and retains identical calls on decline',
    () {
      final probe = _Probe();
      final expected = MockContext();
      BarElement(_cfg()).draw(probe);
      _ReferenceBar(_cfg()).draw(expected);
      expect(probe.probes, 1);
      expect(probe.getCalls(), expected.getCalls());
      for (final cfg in [_cfg(radius: 4.0), _cfg(inflate: 0.33)]) {
        final other = _Probe();
        BarElement(cfg).draw(other);
        expect(other.probes, 0);
      }
    },
  );

  for (final blend in CanvasCompositeOperation.values) {
    test('exact pixels/state/path for $blend', () async {
      for (final horizontal in [false, true]) {
        for (final width in [0.04, 24.0]) {
          for (final alpha in [0.0, 0.65, 1.0]) {
            final cfg = _cfg(width: width, horizontal: horizontal);
            Future<Render> draw(BarElement bar) => renderContext((ctx) {
              ctx.fillStyle = const ui.Color(0xFFEEEEEE);
              ctx.fillRect(0, 0, 160, 160);
              ctx.save();
              ctx.setTransform(1.25, 0, 0, 0.75, 0.5, 1.5);
              ctx.beginPath();
              ctx.rect(4, 5, 110, 120);
              ctx.clip();
              ctx.fillStyle = _caller;
              ctx.globalAlpha = alpha;
              ctx.globalCompositeOperation = blend;
              bar.draw(ctx);
              expect(ctx.fillStyle, _caller);
              expect(ctx.globalAlpha, alpha);
              expect(ctx.globalCompositeOperation, blend);
              // The final inner path remains available to a later stroke.
              ctx.strokeStyle = const ui.Color(0x80443322);
              ctx.lineWidth = 0.5;
              ctx.stroke();
              ctx.restore();
              ctx.fillStyle = _caller;
              ctx.fillRect(1, 1, 3, 3);
            });
            final a = await draw(BarElement(cfg));
            final b = await draw(_ReferenceBar(cfg));
            expect(a.bytes, b.bytes, reason: '$horizontal $width $alpha');
          }
        }
      }
    });
  }

  test('rotations, gradients, invalid colors and callbacks '
      'decline without effects', () {
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
    expect(_direct(ctx, fill: gradient), isFalse);
    expect(_direct(ctx, fill: 'invalid'), isFalse);
    expect(ctx.debugPath.singleRect, path);
    expect(ctx.fillStyle, _caller);
    expect(ctx.debugPictureCount, 0);
    ctx.rotate(0.25);
    expect(_direct(ctx), isFalse);
    ctx.resetTransform();
    var notices = 0;
    ctx.onChanged = () => notices++;
    expect(_direct(ctx), isFalse);
    expect(notices, 0);
    BarElement(_cfg()).draw(ctx);
    expect(notices, 1);
    expect(_direct(ctx), isTrue);
    expect(notices, 1);
  });

  test(
    'caller gradient, reflection, clipping and path append survive',
    () async {
      for (final reflected in [false, true]) {
        Future<Render> draw(BarElement bar) => renderContext((ctx) {
          const gradient = ChartGradient.linear(
            Offset.zero,
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
        expect(a.bytes, b.bytes);
      }
    },
  );

  test(
    'notification reentrancy observes the original intermediate state',
    () async {
      final observations = <List<Object?>>[];
      Future<Render> draw(BarElement bar) {
        final seen = <Object?>[];
        observations.add(seen);
        return renderContext((ctx) {
          ctx.fillStyle = _caller;
          ctx.onChanged = () {
            seen.add(ctx.fillStyle);
            seen.add(ctx.debugPath.singleRect);
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
    },
  );

  test(
    'picture hooks retain the original sequence at a chunk boundary',
    () async {
      final observations = <List<Object?>>[];
      Future<Render> draw(BarElement bar) {
        final seen = <Object?>[];
        observations.add(seen);
        return renderContext((ctx) {
          ctx.fillStyle = _caller;
          ctx.fillRect(0, 0, 1, 1);
          final previous = ui.Picture.onCreate;
          try {
            ui.Picture.onCreate = (_) {
              seen.add(ctx.fillStyle);
              seen.add(ctx.debugPath.singleRect);
            };
            expect(_direct(ctx), isFalse);
            for (var i = 0; i < 130; i++) {
              bar.draw(ctx);
            }
          } finally {
            ui.Picture.onCreate = previous;
          }
        });
      }

      final a = await draw(BarElement(_cfg(width: 0.04)));
      final b = await draw(_ReferenceBar(_cfg(width: 0.04)));
      expect(observations[0], isNotEmpty);
      expect(observations[0], observations[1]);
      expect(a.bytes, b.bytes);
    },
  );

  test(
    'pending circles and recording splits preserve order and pixels',
    () async {
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
    },
  );

  test(
    'invalid background throws after the same border/state changes',
    () async {
      final states = <List<Object?>>[];
      Future<Render> draw(BarElement bar) => renderContext((ctx) {
        ctx.fillStyle = _caller;
        expect(() => bar.draw(ctx), throwsArgumentError);
        states.add([ctx.fillStyle, ctx.debugPath.singleRect]);
        ctx.restore();
        ctx.fillRect(2, 3, 4, 5);
      });
      final a = await draw(BarElement(_cfg(backgroundColor: 'invalid')));
      final b = await draw(_ReferenceBar(_cfg(backgroundColor: 'invalid')));
      expect(states[0], states[1]);
      expect(a.bytes, b.bytes);
    },
  );

  test(
    'disposed context declines and snapshot/clear lifecycles remain valid',
    () async {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      expect(_direct(ctx), isTrue);
      final source = ctx.canvas.toImageSource();
      expect(await source.image.toByteData(), isNotNull);
      source.image.dispose();
      ctx.clearRect(0, 0, 160, 160);
      expect(ctx.isEmpty, isTrue);
      expect(_direct(ctx), isTrue);
      ctx.dispose();
      expect(_direct(ctx), isFalse);
    },
  );
}
