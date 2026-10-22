// Original code, not ported from Chart.js: tests of the dart:ui canvas.
@TestOn('vm')
library;

// flutter_test and dart:ui: the web legs cannot compile this file.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui_text.dart';
import 'package:flutter_test/flutter_test.dart';

/// The rendered RGBA pixels of a canvas.
final class _Pixels {
  _Pixels(this.data, this.width, this.height);

  final ByteData data;
  final int width;
  final int height;

  int _offset(int x, int y) => (y * width + x) * 4;

  int r(int x, int y) => data.getUint8(_offset(x, y));
  int g(int x, int y) => data.getUint8(_offset(x, y) + 1);
  int b(int x, int y) => data.getUint8(_offset(x, y) + 2);
  int a(int x, int y) => data.getUint8(_offset(x, y) + 3);

  bool inked(int x, int y) => a(x, y) > 64;

  /// The number of pixels with ink.
  int inkCount() {
    var count = 0;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (inked(x, y)) count++;
      }
    }
    return count;
  }

  /// The number of runs of pixels with ink on the row [y].
  int runs(int y) {
    var count = 0;
    var previous = false;
    for (var x = 0; x < width; x++) {
      final ink = inked(x, y);
      if (ink && !previous) count++;
      previous = ink;
    }
    return count;
  }

  /// The bounds of the pixels with ink, or null.
  ui.Rect? ink() {
    var left = width;
    var top = height;
    var right = -1;
    var bottom = -1;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (inked(x, y)) {
          left = math.min(left, x);
          right = math.max(right, x);
          top = math.min(top, y);
          bottom = math.max(bottom, y);
        }
      }
    }
    if (right < 0) return null;
    return ui.Rect.fromLTRB(
      left.toDouble(),
      top.toDouble(),
      right + 1.0,
      bottom + 1.0,
    );
  }
}

/// Paints [ctx] into an image of [width] x [height] logical pixels, on top
/// of [background] when given. The bitmap shows at the scale `1 / dpr`, as
/// a host at the device pixel ratio [dpr] shows it after `retinaScale`.
Future<_Pixels> _render(
  UiCanvasContext ctx, {
  int? width,
  int? height,
  ui.Color? background,
  double dpr = 1,
}) async {
  final w = width ?? (ctx.canvas.width / dpr).round();
  final h = height ?? (ctx.canvas.height / dpr).round();
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  if (background != null) {
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      ui.Paint()..color = background,
    );
  }
  ctx.paint(canvas, ui.Offset.zero, 1 / dpr, 1 / dpr);
  final picture = recorder.endRecording();
  final image = await picture.toImage(w, h);
  final data = await image.toByteData();
  image.dispose();
  picture.dispose();
  return _Pixels(data!, w, h);
}

UiCanvasContext _context({int width = 100, int height = 100}) =>
    UiCanvasElement(width: width, height: height).getContext2d();

/// A circle of a reference drawing: a fill, a stroke or both.
typedef _Dot = ({
  ui.Offset c,
  double r,
  ui.Color? fill,
  ui.Color? stroke,
  double width,
});

/// The RGBA bytes of [dots] drawn with `drawCircle` on [width] x [height]
/// pixels. [at] draws before the dot of its index, and after the last dot.
///
/// With [snap], each center moves to the nearest 1 / 4 pixel, as the circle
/// batch places it. The drawing has a margin, so that a circle across the
/// border rasterizes as one inside.
Future<ByteData> _reference(
  List<_Dot> dots, {
  int width = 100,
  int height = 100,
  bool snap = true,
  void Function(ui.Canvas canvas, int index)? at,
}) async {
  const margin = 64;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)
    ..translate(margin.toDouble(), margin.toDouble());
  double place(double v) => snap ? (v * 4).roundToDouble() / 4 : v;
  for (var i = 0; i < dots.length; i++) {
    at?.call(canvas, i);
    final d = dots[i];
    final c = ui.Offset(place(d.c.dx), place(d.c.dy));
    if (d.fill != null) canvas.drawCircle(c, d.r, ui.Paint()..color = d.fill!);
    if (d.stroke != null) {
      canvas.drawCircle(
        c,
        d.r,
        ui.Paint()
          ..color = d.stroke!
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = d.width,
      );
    }
  }
  at?.call(canvas, dots.length);
  final picture = recorder.endRecording();
  final image = await picture.toImage(width + 2 * margin, height + 2 * margin);
  final full = (await image.toByteData())!;
  image.dispose();
  picture.dispose();
  final data = ByteData(width * height * 4);
  for (var y = 0; y < height; y++) {
    for (var i = 0; i < width * 4; i++) {
      data.setUint8(
        y * width * 4 + i,
        full.getUint8(((y + margin) * (width + 2 * margin) + margin) * 4 + i),
      );
    }
  }
  return data;
}

/// The largest difference of one channel between [a] and [b].
int _worstDifference(ByteData a, ByteData b) {
  expect(a.lengthInBytes, b.lengthInBytes);
  var worst = 0;
  for (var i = 0; i < a.lengthInBytes; i++) {
    worst = math.max(worst, (a.getUint8(i) - b.getUint8(i)).abs());
  }
  return worst;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('element', () {
    test('has the DOM default size and one context', () {
      final element = UiCanvasElement();
      expect(element.width, 300);
      expect(element.height, 150);
      expect(element.getContext2d(), same(element.getContext('2d')));
      expect(element.getContext('webgl'), isNull);
      expect(element.getContext2d().canvas, same(element));
    });

    test('style is a property map', () {
      final style = UiCanvasElement().style;
      expect(style.getPropertyValue('direction'), '');
      style.setProperty('direction', 'rtl', 'important');
      expect(style.getPropertyValue('direction'), 'rtl');
      expect(style.getPropertyPriority('direction'), 'important');
      style.setProperty('direction', 'ltr', 'bogus');
      expect(style.getPropertyValue('direction'), 'rtl');
      style.setProperty('direction', null);
      expect(style.getPropertyValue('direction'), '');
    });

    test('setting width or height resets the state and the bitmap', () {
      final element = UiCanvasElement(width: 50, height: 50);
      final ctx = element.getContext2d()
        ..fillStyle = 'red'
        ..lineWidth = 5
        ..font = 'bold 20px Arial'
        ..translate(10, 10)
        ..save()
        ..fillRect(0, 0, 10, 10);
      expect(ctx.isEmpty, isFalse);
      element.width = 50;
      expect(ctx.isEmpty, isTrue);
      expect(ctx.fillStyle, '#000000');
      expect(ctx.lineWidth, 1);
      expect(ctx.font, '10px sans-serif');
      // The stack is empty: this restore does nothing, and a fill at the
      // origin lands at the origin.
      ctx
        ..restore()
        ..fillRect(0, 0, 5, 5);
      element.height = 40;
      expect(ctx.isEmpty, isTrue);
      expect(element.height, 40);
    });
  });

  group('attributes', () {
    // platform.dom.js:45-46 reads the attributes, and :300-307 restores
    // them. The DOM reflects the width and height properties into them.
    test('a canvas without attributes has the default size', () {
      final element = UiCanvasElement();
      expect(element.getAttribute('width'), isNull);
      expect(element.getAttribute('height'), isNull);
      expect((element.width, element.height), (300, 150));
      final sized = UiCanvasElement(width: 512, height: 512);
      expect(sized.getAttribute('width'), '512');
      expect(sized.getAttribute('HEIGHT'), '512');
      expect(sized.getAttribute('style'), isNull);
      expect(UiCanvasElement(height: 80).getAttribute('width'), isNull);
    });

    test('a write of width or height sets the attribute', () {
      final element = UiCanvasElement()
        ..width = 640
        ..height = -5;
      expect(element.getAttribute('width'), '640');
      expect(element.getAttribute('height'), '0');
      expect((element.width, element.height), (640, 0));
    });

    test('removeAttribute gives the default size and clears the bitmap', () {
      final element = UiCanvasElement(width: 50, height: 40);
      final ctx = element.getContext2d()
        ..fillStyle = 'red'
        ..fillRect(0, 0, 10, 10);
      element.removeAttribute('width');
      expect(element.getAttribute('width'), isNull);
      expect((element.width, element.height), (300, 40));
      expect(ctx.isEmpty, isTrue);
      expect(ctx.fillStyle, '#000000');

      // An absent attribute and the style attribute do not reset the
      // context, as in the DOM. The style attribute reflects the inline
      // style (Chart.js ADR 0022, section 4).
      ctx
        ..fillStyle = 'red'
        ..fillRect(0, 0, 10, 10);
      element
        ..removeAttribute('width')
        ..removeAttribute('style')
        ..setAttribute('style', 'width: 10px');
      expect(ctx.isEmpty, isFalse);
      expect(element.getAttribute('style'), 'width: 10px');
      element.removeAttribute('height');
      expect((element.width, element.height), (300, 150));
      expect(ctx.isEmpty, isTrue);
    });

    test('setAttribute parses a non-negative integer, else the default', () {
      final element = UiCanvasElement();
      final ctx = element.getContext2d()..fillRect(0, 0, 10, 10);
      element.setAttribute('width', '180');
      expect(element.getAttribute('width'), '180');
      expect(element.width, 180);
      expect(ctx.isEmpty, isTrue);
      for (final (value, width) in const [
        (' \n+42px', 42),
        ('007', 7),
        ('0', 0),
        ('-5', 300),
        ('', 300),
        ('px', 300),
        ('2147483648', 300),
      ]) {
        element.setAttribute('width', value);
        expect(element.getAttribute('width'), value);
        expect(element.width, width, reason: value);
      }
      element.setAttribute('height', 'auto');
      expect((element.getAttribute('height'), element.height), ('auto', 150));
    });
  });

  group('the style attribute and the other attributes', () {
    // Chart.js ADR 0022, section 4: chartjs-test-utils src/utils.js:46-50
    // sets the canvas attributes of a spec with setAttribute, also `style`,
    // and platform.dom.tests.js:10 sets `id`.
    test('setAttribute of style replaces the inline style', () {
      final element = UiCanvasElement();
      element.style.setProperty('display', 'block');
      element.setAttribute('style', 'width: 512px; HEIGHT:480px');
      expect(element.style.getPropertyValue('width'), '512px');
      expect(element.style.getPropertyValue('height'), '480px');
      expect(element.style.getPropertyValue('display'), '');
      // The attribute keeps the text as it was set.
      expect(element.getAttribute('style'), 'width: 512px; HEIGHT:480px');
      expect((element.width, element.height), (300, 150));
    });

    test('a CSSOM write makes the attribute the serialization', () {
      final element = UiCanvasElement()..setAttribute('style', 'width:10px');
      expect(element.getAttribute('style'), 'width:10px');
      // Also a write that changes nothing.
      element.style.setProperty('height', '');
      expect(element.getAttribute('style'), 'width: 10px;');
      element.style.setProperty('display', 'block');
      expect(element.getAttribute('style'), 'width: 10px; display: block;');
      element.style.setProperty('display', null);
      expect(element.getAttribute('style'), 'width: 10px;');
      element.style.setProperty('width', '');
      // The attribute stays, with no declarations.
      expect(element.getAttribute('style'), '');

      final other = UiCanvasElement();
      other.style.setProperty('width', '20px', 'important');
      expect(other.getAttribute('style'), 'width: 20px !important;');
    });

    test('removeAttribute of style empties the inline style', () {
      final element = UiCanvasElement()
        ..setAttribute('style', 'width: 512px')
        ..removeAttribute('STYLE');
      expect(element.getAttribute('style'), isNull);
      expect(element.style.getPropertyValue('width'), '');
      element.setAttribute('style', '');
      expect(element.getAttribute('style'), '');
    });

    test('the declarations of a style text', () {
      final style = UiCanvasElement().style
        ..cssText =
            ' width : 455px ; ; height: 355px !IMPORTANT; color; :red; '
            'background: url("a;b") no-repeat; font-family: x(a;b); '
            '--Custom: 1; height: 1px';
      expect(style.getPropertyValue('width'), '455px');
      expect(style.getPropertyValue('height'), '355px');
      expect(style.getPropertyPriority('height'), 'important');
      expect(style.getPropertyValue('color'), '');
      expect(style.getPropertyValue('background'), 'url("a;b") no-repeat');
      expect(style.getPropertyValue('font-family'), 'x(a;b)');
      expect(style.getPropertyValue('--Custom'), '1');
      expect(style.getPropertyValue('--custom'), '');
      expect(
        style.cssText,
        'width: 455px; height: 355px !important; '
        'background: url("a;b") no-repeat; font-family: x(a;b); --Custom: 1;',
      );
      // The setter replaces the declarations and the attribute.
      style.cssText = 'width: 640px; height: 480px';
      expect(style.cssText, 'width: 640px; height: 480px;');
      expect(style.styleAttribute, 'width: 640px; height: 480px;');
      expect(style.getPropertyValue('background'), '');
    });

    test('another attribute keeps its value as a string', () {
      final element = UiCanvasElement(width: 40, height: 20);
      final ctx = element.getContext2d()..fillRect(0, 0, 10, 10);
      element
        ..setAttribute('id', 'chart-canvas')
        ..setAttribute('Class', 'a b');
      expect(element.getAttribute('ID'), 'chart-canvas');
      expect(element.getAttribute('class'), 'a b');
      expect(element.getAttribute('title'), isNull);
      element.removeAttribute('id');
      expect(element.getAttribute('id'), isNull);
      // The writes do not reset the context.
      expect(ctx.isEmpty, isFalse);
      expect((element.width, element.height), (40, 20));
    });
  });

  group('transforms', () {
    test('apply when a point is added', () async {
      final ctx = _context()
        ..beginPath()
        ..rect(0, 0, 10, 10)
        ..translate(20, 0)
        ..rect(0, 0, 10, 10)
        // A transform after the points does not move them.
        ..translate(40, 0)
        ..fill();
      final pixels = await _render(ctx);
      expect(pixels.inked(5, 5), isTrue);
      expect(pixels.inked(25, 5), isTrue);
      expect(pixels.inked(15, 5), isFalse);
      expect(pixels.inked(65, 5), isFalse);
    });

    test('scale the line width of a stroke', () async {
      final ctx = _context()
        ..scale(2, 2)
        ..lineWidth = 4
        ..beginPath()
        ..moveTo(0, 20)
        ..lineTo(50, 20)
        ..stroke();
      final pixels = await _render(ctx);
      // The line is 8 pixels wide around y = 40.
      expect(pixels.inked(50, 37), isTrue);
      expect(pixels.inked(50, 43), isTrue);
      expect(pixels.inked(50, 33), isFalse);
      expect(pixels.inked(50, 47), isFalse);
    });

    test('a skew strokes in user space', () async {
      final ctx = _context()
        ..transform(1, 0, 0, 3, 0, 0)
        ..lineWidth = 2
        ..beginPath()
        ..moveTo(0, 10)
        ..lineTo(100, 10)
        ..stroke();
      final pixels = await _render(ctx);
      // The line is 6 pixels high around y = 30.
      expect(pixels.inked(50, 28), isTrue);
      expect(pixels.inked(50, 32), isTrue);
      expect(pixels.inked(50, 25), isFalse);
      expect(pixels.inked(50, 35), isFalse);
    });

    test('non-finite arguments do nothing', () async {
      final ctx = _context()
        ..translate(double.nan, 0)
        ..scale(double.infinity, 1)
        ..rotate(double.nan)
        ..setTransform(double.nan, 0, 0, 1, 0, 0)
        ..beginPath()
        ..moveTo(10, 10)
        ..lineTo(double.nan, 50)
        ..lineTo(90, double.infinity)
        ..rect(double.nan, 0, 10, 10)
        ..arc(double.nan, 0, 10, 0, 1)
        ..fillRect(double.nan, 0, 10, 10)
        ..strokeRect(0, double.infinity, 10, 10)
        ..clearRect(double.nan, 0, 10, 10);
      expect(ctx.isEmpty, isTrue);
      ctx.fillRect(0, 0, 10, 10);
      final pixels = await _render(ctx);
      // The transform is still the identity.
      expect(pixels.inked(5, 5), isTrue);
      expect(pixels.inked(15, 5), isFalse);
    });

    test('a singular transform draws nothing', () {
      final ctx = _context()
        ..scale(0, 1)
        ..fillRect(0, 0, 10, 10)
        ..beginPath()
        ..rect(0, 0, 10, 10)
        ..fill()
        ..fillText('A', 10, 10);
      expect(ctx.isEmpty, isTrue);
    });
  });

  group('state', () {
    test('save and restore keep styles but not the path', () async {
      final ctx = _context()
        ..fillStyle = 'red'
        ..save()
        ..fillStyle = 'blue'
        ..lineWidth = 3
        ..beginPath()
        ..rect(0, 0, 20, 20)
        ..restore();
      expect(ctx.fillStyle, '#ff0000');
      expect(ctx.lineWidth, 1);
      ctx.fill();
      final pixels = await _render(ctx);
      expect(pixels.r(10, 10), 255);
      expect(pixels.b(10, 10), 0);
    });

    test('a restore without a save does nothing', () {
      final ctx = _context()
        ..fillStyle = 'red'
        ..restore();
      expect(ctx.fillStyle, '#ff0000');
    });

    test('invalid values are ignored', () {
      final ctx = _context()
        ..fillStyle = 'red'
        ..fillStyle = 'not a color'
        ..fillStyle = 12
        ..strokeStyle = 'rgba(0, 0, 255, 0.5)'
        ..strokeStyle = null
        ..lineWidth = -1
        ..lineWidth = double.nan
        ..lineWidth = 0
        ..lineCap = 'bogus'
        ..lineJoin = 'bogus'
        ..miterLimit = 0
        ..globalAlpha = 2
        ..globalAlpha = double.nan
        ..globalCompositeOperation = 'bogus'
        ..font = 'not a font'
        ..textAlign = 'bogus'
        ..textBaseline = 'bogus'
        ..direction = 'bogus';
      expect(ctx.fillStyle, '#ff0000');
      expect(ctx.strokeStyle, 'rgba(0, 0, 255, 0.5)');
      expect(ctx.lineWidth, 1);
      expect(ctx.lineCap, 'butt');
      expect(ctx.lineJoin, 'miter');
      expect(ctx.miterLimit, 10);
      expect(ctx.globalAlpha, 1);
      expect(ctx.globalCompositeOperation, 'source-over');
      expect(ctx.font, '10px sans-serif');
      expect(ctx.textAlign, 'start');
      expect(ctx.textBaseline, 'alphabetic');
      expect(ctx.direction, 'inherit');
    });

    test('valid values read back', () {
      final ctx = _context()
        ..fillStyle = '#ABC'
        ..lineCap = 'round'
        ..lineJoin = 'bevel'
        ..globalCompositeOperation = 'destination-over'
        ..textAlign = 'center'
        ..textBaseline = 'middle'
        ..direction = 'rtl';
      expect(ctx.fillStyle, '#aabbcc');
      expect(ctx.lineCap, 'round');
      expect(ctx.lineJoin, 'bevel');
      expect(ctx.globalCompositeOperation, 'destination-over');
      expect(ctx.textAlign, 'center');
      expect(ctx.textBaseline, 'middle');
      expect(ctx.direction, 'rtl');
    });
  });

  group('paint maps the bitmap pixels with the given scale', () {
    test('a scale of 1 / ratio after retinaScale is the identity', () async {
      final element = UiCanvasElement(width: 200, height: 200);
      final ctx = element.getContext2d()
        // retinaScale: the net transform is the identity in logical pixels.
        ..setTransform(2, 0, 0, 2, 0, 0)
        ..fillRect(0, 0, 50, 50);
      var pixels = await _render(ctx, dpr: 2);
      expect((pixels.width, pixels.height), (100, 100));
      expect(pixels.inked(45, 45), isTrue);
      expect(pixels.inked(55, 55), isFalse);

      ctx
        ..resetTransform()
        ..clearRect(0, 0, 200, 200)
        ..fillRect(0, 0, 50, 50);
      pixels = await _render(ctx, dpr: 2);
      // Without retinaScale, 50 device pixels are 25 logical pixels.
      expect(pixels.inked(20, 20), isTrue);
      expect(pixels.inked(30, 30), isFalse);
    });

    test('the content stays in bitmap pixels at another scale', () async {
      final element = UiCanvasElement(width: 100, height: 100);
      final ctx = element.getContext2d()..fillRect(0, 0, 50, 50);
      // As a DOM bitmap: 50 bitmap pixels show as 25 logical pixels at a
      // ratio of 2, also when they were drawn at a ratio of 1.
      var pixels = await _render(ctx, dpr: 2);
      expect(pixels.inked(20, 20), isTrue);
      expect(pixels.inked(30, 30), isFalse);
      ctx.fillRect(50, 50, 50, 50);
      pixels = await _render(ctx, dpr: 2);
      expect(pixels.inked(45, 45), isTrue);
      expect(pixels.inked(35, 15), isFalse);
      pixels = await _render(ctx);
      expect(pixels.inked(45, 45), isTrue);
      expect(pixels.inked(55, 55), isTrue);
      expect(pixels.inked(75, 25), isFalse);
    });

    test('a scale for each axis stretches the bitmap', () async {
      // The DOM stretch of a bitmap of 100 x 100 to a display of 200 x 50,
      // at the offset (10, 5).
      final ctx = _context()
        ..fillRect(0, 0, 50, 50)
        ..fillRect(50, 50, 100, 100);
      final recorder = ui.PictureRecorder();
      ctx.paint(ui.Canvas(recorder), const ui.Offset(10, 5), 2, 0.5);
      final image = await recorder.endRecording().toImage(220, 60);
      final pixels = _Pixels((await image.toByteData())!, 220, 60);
      image.dispose();
      expect(pixels.inked(11, 6), isTrue);
      expect(pixels.inked(108, 29), isTrue);
      expect(pixels.inked(112, 20), isFalse);
      expect(pixels.inked(108, 31), isFalse);
      expect(pixels.inked(205, 52), isTrue);
      // The clip is the bitmap, at the display size.
      expect(pixels.inked(215, 52), isFalse);
      expect(pixels.inked(205, 57), isFalse);
    });
  });

  group('clearRect', () {
    test('a full clear drops the pictures', () async {
      final ctx = _context()..fillRect(0, 0, 10, 10);
      await _render(ctx);
      ctx.fillRect(20, 20, 10, 10);
      expect(ctx.debugPictureCount, 2);
      ctx
        ..save()
        ..translate(5, 5)
        ..resetTransform()
        ..clearRect(0, 0, 100, 100)
        ..restore();
      expect(ctx.isEmpty, isTrue);
      expect(ctx.debugPictureCount, 0);
      final pixels = await _render(ctx);
      expect(pixels.ink(), isNull);
    });

    test('a partial clear clears pixels, not what is below', () async {
      final ctx = _context()
        ..fillStyle = 'red'
        ..fillRect(0, 0, 100, 100)
        ..clearRect(0, 0, 10, 10);
      final pixels = await _render(ctx, background: const ui.Color(0xFF0000FF));
      expect(pixels.b(5, 5), 255);
      expect(pixels.r(5, 5), 0);
      expect(pixels.r(50, 50), 255);
    });

    test('a clear inside a clip clears the clip only', () async {
      final ctx = _context()
        ..fillRect(0, 0, 100, 100)
        ..beginPath()
        ..rect(0, 0, 50, 100)
        ..clip()
        ..clearRect(0, 0, 100, 100);
      expect(ctx.isEmpty, isFalse);
      final pixels = await _render(ctx);
      expect(pixels.inked(25, 50), isFalse);
      expect(pixels.inked(75, 50), isTrue);
    });
  });

  group('paths', () {
    test('evenodd leaves the inner square empty', () async {
      final ctx = _context()
        ..beginPath()
        ..rect(10, 10, 80, 80)
        ..rect(30, 30, 40, 40)
        ..fill('evenodd');
      var pixels = await _render(ctx);
      expect(pixels.inked(20, 20), isTrue);
      expect(pixels.inked(50, 50), isFalse);

      ctx
        ..clearRect(0, 0, 100, 100)
        ..fill();
      pixels = await _render(ctx);
      expect(pixels.inked(50, 50), isTrue);
    });

    test('clip limits the drawing until restore', () async {
      final ctx = _context()
        ..save()
        ..beginPath()
        ..arc(50, 50, 20, 0, 2 * math.pi)
        ..clip()
        ..fillRect(0, 0, 100, 100)
        ..restore()
        ..fillRect(0, 0, 10, 10);
      final pixels = await _render(ctx);
      expect(pixels.inked(50, 50), isTrue);
      expect(pixels.inked(50, 25), isFalse);
      expect(pixels.inked(5, 5), isTrue);
    });

    test('a clip survives the end of a recording', () async {
      final ctx = _context()
        ..beginPath()
        ..rect(0, 0, 50, 100)
        ..clip()
        ..fillRect(0, 0, 10, 10);
      await _render(ctx);
      ctx.fillRect(0, 0, 100, 100);
      final pixels = await _render(ctx);
      expect(pixels.inked(25, 50), isTrue);
      expect(pixels.inked(75, 50), isFalse);
    });

    test('a full circle and a negative radius', () async {
      final ctx = _context()
        ..beginPath()
        ..arc(50, 50, 30, 1, 1 + 2 * math.pi)
        ..fill();
      final pixels = await _render(ctx);
      expect(pixels.inked(50, 50), isTrue);
      expect(pixels.inked(50, 25), isTrue);
      expect(pixels.inked(50, 85), isFalse);
      expect(() => ctx.arc(0, 0, -1, 0, 1), throwsRangeError);
      expect(
        () => ctx.ellipse(0, 0, 1, -1, 0, 0, 1),
        throwsRangeError,
      );
      expect(() => ctx.arcTo(0, 0, 1, 1, -1), throwsRangeError);
    });

    test('a sweep just under a full turn fills a circle', () async {
      Future<int> inkOf(
        double sweep, {
        required bool move,
        bool ccw = false,
      }) async {
        final ctx = _context(width: 200, height: 150)..beginPath();
        if (move) ctx.moveTo(100, 70);
        ctx
          ..arc(100, 70, 40, 0, sweep, ccw)
          ..fill();
        return (await _render(ctx)).inkCount();
      }

      const tau = 2 * math.pi;
      final full = await inkOf(tau, move: true);
      expect(full, greaterThan(4800));
      for (final move in [true, false]) {
        for (final gap in [1e-12, 1e-9, 1e-7]) {
          expect(
            await inkOf(tau - gap, move: move),
            closeTo(full, full * 0.02),
            reason: 'gap $gap, move $move',
          );
          expect(
            await inkOf(-(tau - gap), move: move, ccw: true),
            closeTo(full, full * 0.02),
            reason: 'gap -$gap, move $move',
          );
        }
      }
      // A non-uniform scale takes the same native arc.
      final ellipse = _context(width: 200, height: 150)
        ..scale(1, 0.5)
        ..beginPath()
        ..moveTo(100, 140)
        ..arc(100, 140, 40, 0, tau - 1e-12)
        ..fill();
      expect(
        (await _render(ellipse)).inkCount(),
        closeTo(full / 2, full * 0.02),
      );
    });

    group('a full circle on an empty path', () {
      test('fills and strokes as a circle', () async {
        final ctx = _context()
          ..translate(10, 0)
          ..scale(2, 2)
          ..fillStyle = '#ff0000'
          ..strokeStyle = '#0000ff'
          ..lineWidth = 2
          ..beginPath()
          ..arc(20, 25, 10, 0, 2 * math.pi)
          ..closePath()
          ..fill()
          ..stroke();
        final pixels = await _render(ctx);
        // Center (50, 50), radius 20, stroke 4 wide in bitmap pixels.
        expect(pixels.r(50, 50), 255);
        expect(pixels.b(50, 50), 0);
        expect(pixels.b(50, 30), 255);
        expect(pixels.b(70, 50), 255);
        expect(pixels.inked(50, 25), isFalse);
        expect(pixels.inked(76, 50), isFalse);
      });

      test('later commands extend the same path', () async {
        final ctx = _context()
          ..lineWidth = 2
          ..beginPath()
          ..arc(50, 50, 20, 0, 2 * math.pi)
          // The current point is the end of the circle, at (70, 50).
          ..lineTo(95, 50)
          ..stroke();
        final pixels = await _render(ctx);
        expect(pixels.inked(85, 50), isTrue);
        expect(pixels.inked(50, 30), isTrue);
        expect(pixels.inked(50, 50), isFalse);
      });

      test('a second circle makes an evenodd ring', () async {
        final ctx = _context()
          ..beginPath()
          ..arc(50, 50, 40, 0, 2 * math.pi)
          ..arc(50, 50, 20, 0, 2 * math.pi)
          ..fill('evenodd');
        final pixels = await _render(ctx);
        expect(pixels.inked(50, 50), isFalse);
        expect(pixels.inked(50, 20), isTrue);
      });

      test('a dashed circle strokes the dash pattern', () async {
        final ctx = _context()
          ..lineWidth = 4
          ..setLineDash([10, 1000])
          ..beginPath()
          ..arc(50, 50, 30, 0, 2 * math.pi)
          ..stroke();
        final pixels = await _render(ctx);
        // Only the first 10 pixels from the start angle 0 are inked.
        expect(pixels.inked(80, 52), isTrue);
        expect(pixels.inked(20, 50), isFalse);
        expect(pixels.inked(50, 80), isFalse);
      });

      test('a reflected transform keeps the start point', () async {
        final ctx = _context()
          ..translate(100, 0)
          ..scale(-1, 1)
          ..lineWidth = 2
          ..beginPath()
          ..arc(50, 50, 20, 0, 2 * math.pi)
          ..lineTo(50, 50)
          ..stroke();
        final pixels = await _render(ctx);
        // The start point (70, 50) in user space is (30, 50) in bitmap
        // space, and the line runs from it to the center.
        expect(pixels.inked(40, 50), isTrue);
        expect(pixels.inked(60, 50), isFalse);
      });
    });

    test('arc connects to the current point with a line', () async {
      final ctx = _context()
        ..lineWidth = 2
        ..beginPath()
        ..moveTo(10, 50)
        ..arc(80, 50, 10, math.pi, 1.5 * math.pi)
        ..stroke();
      final pixels = await _render(ctx);
      expect(pixels.inked(40, 50), isTrue);
    });

    test('lineTo on an empty path starts the path there', () async {
      final ctx = _context()
        ..lineWidth = 2
        ..beginPath()
        ..lineTo(50, 50)
        ..lineTo(90, 50)
        ..stroke();
      final pixels = await _render(ctx);
      expect(pixels.inked(70, 50), isTrue);
      // No line from the origin.
      expect(pixels.inked(25, 25), isFalse);
    });

    test('a rotated ellipse and arcTo draw', () async {
      final ctx = _context()
        ..beginPath()
        ..ellipse(50, 50, 40, 10, math.pi / 2, 0, 2 * math.pi)
        ..fill();
      var pixels = await _render(ctx);
      expect(pixels.inked(50, 15), isTrue);
      expect(pixels.inked(15, 50), isFalse);

      ctx
        ..clearRect(0, 0, 100, 100)
        ..lineWidth = 2
        ..beginPath()
        ..moveTo(10, 10)
        ..arcTo(90, 10, 90, 90, 20)
        ..lineTo(90, 90)
        ..stroke();
      pixels = await _render(ctx);
      expect(pixels.inked(50, 10), isTrue);
      expect(pixels.inked(90, 60), isTrue);
      // The corner is rounded.
      expect(pixels.inked(89, 11), isFalse);
    });

    test('fill and stroke a Path2D under the transform', () async {
      final path = Path2D()..rect(0, 0, 10, 10);
      final ctx = _context()
        ..translate(50, 50)
        ..fill(path);
      final pixels = await _render(ctx);
      expect(pixels.inked(55, 55), isTrue);
      expect(pixels.inked(5, 5), isFalse);
      // The converted path is cached on the Path2D.
      expect(path.cache, isNotNull);
      final cache = path.cache;
      ctx.stroke(path);
      expect(path.cache, same(cache));
    });
  });

  group('styles', () {
    test('globalAlpha multiplies the alpha', () async {
      final ctx = _context()
        ..globalAlpha = 0.5
        ..fillRect(0, 0, 10, 10);
      final pixels = await _render(ctx);
      expect(pixels.a(5, 5), closeTo(128, 2));
    });

    test('a linear gradient', () async {
      final gradient = _context().createLinearGradient(0, 0, 100, 0)
        ..addColorStop(0, 'red')
        ..addColorStop(1, 'blue');
      final ctx = _context()
        ..fillStyle = gradient
        ..fillRect(0, 0, 100, 100);
      expect(ctx.fillStyle, same(gradient));
      final pixels = await _render(ctx);
      expect(pixels.r(2, 50), greaterThan(240));
      expect(pixels.b(97, 50), greaterThan(240));
      expect(() => gradient.addColorStop(1.5, 'red'), throwsRangeError);
      expect(
        () => gradient.addColorStop(0.5, 'not a color'),
        throwsFormatException,
      );
    });

    test('a gradient is in user space at fill time', () async {
      final ctx = _context();
      final gradient = ctx.createLinearGradient(0, 0, 50, 0)
        ..addColorStop(0, 'red')
        ..addColorStop(1, 'blue');
      ctx
        ..translate(50, 0)
        ..fillStyle = gradient
        ..fillRect(0, 0, 50, 100);
      final pixels = await _render(ctx);
      expect(pixels.r(52, 50), greaterThan(230));
      expect(pixels.b(98, 50), greaterThan(230));
    });

    test('radial and conic gradients paint', () async {
      final ctx = _context();
      final radial = ctx.createRadialGradient(0, 0, 10, 0, 0, 100)
        ..addColorStop(0, 'red')
        ..addColorStop(1, 'blue');
      ctx
        ..fillStyle = radial
        ..fillRect(0, 0, 100, 100);
      var pixels = await _render(ctx);
      expect(pixels.r(3, 3), greaterThan(240));
      expect(pixels.b(99, 99), greaterThan(200));

      final conic = ctx.createConicGradient(0, 50, 50)
        ..addColorStop(0, 'red')
        ..addColorStop(1, 'blue');
      ctx
        ..clearRect(0, 0, 100, 100)
        ..fillStyle = conic
        ..fillRect(0, 0, 100, 100);
      pixels = await _render(ctx);
      expect(pixels.a(50, 80), 255);
      expect(
        () => ctx.createRadialGradient(0, 0, -1, 0, 0, 1),
        throwsRangeError,
      );
    });

    test('a pattern repeats an image', () async {
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawRect(
        const ui.Rect.fromLTWH(0, 0, 5, 5),
        ui.Paint()..color = const ui.Color(0xFF00FF00),
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(10, 10);
      final source = UiImageSource(image);
      final ctx = _context();
      final pattern = ctx.createPattern(source, null)!;
      ctx
        ..fillStyle = pattern
        ..fillRect(0, 0, 100, 100);
      var pixels = await _render(ctx);
      expect(pixels.g(2, 2), 255);
      expect(pixels.g(12, 12), 255);
      expect(pixels.inked(7, 7), isFalse);

      ctx
        ..clearRect(0, 0, 100, 100)
        ..drawImage(source, 50, 50, 20, 20);
      pixels = await _render(ctx);
      expect(pixels.g(55, 55), 255);
      expect(pixels.inked(65, 65), isFalse);
      expect(
        () => ctx.createPattern(source, 'bogus'),
        throwsFormatException,
      );
    });

    test('toImageSource snapshots the bitmap in device pixels', () async {
      final canvas = UiCanvasElement(width: 20, height: 10);
      final ctx = canvas.getContext2d()
        ..fillStyle = '#0000ff'
        ..fillRect(0, 0, 5, 5);
      final source = canvas.toImageSource();
      expect(source.width, 20);
      expect(source.height, 10);
      final data = (await source.image.toByteData())!;
      // Without a transform, user units are bitmap pixels (the DOM
      // rule), whatever the paint scale of the host.
      expect(data.getUint8((2 * 20 + 2) * 4 + 2), 255);
      expect(data.getUint8((4 * 20 + 4) * 4 + 3), 255);
      expect(data.getUint8((2 * 20 + 7) * 4 + 3), 0);

      // The snapshot draws like an image, and the canvas keeps drawing.
      final target = _context()..drawImage(source, 0, 0);
      final pixels = await _render(target);
      expect(pixels.b(4, 4), 255);
      expect(pixels.inked(7, 2), isFalse);
      ctx.fillRect(5, 0, 5, 5);
      final again = canvas.toImageSource();
      final more = (await again.image.toByteData())!;
      expect(more.getUint8((2 * 20 + 7) * 4 + 3), 255);
      source.image.dispose();
      again.image.dispose();

      expect(
        () => UiCanvasElement(width: 0).toImageSource(),
        throwsStateError,
      );
    });

    test('a line dash', () async {
      final ctx = _context()
        ..setLineDash([10, 10])
        ..lineWidth = 4
        ..beginPath()
        ..moveTo(0, 50)
        ..lineTo(100, 50)
        ..stroke();
      expect(ctx.getLineDash(), [10, 10]);
      final pixels = await _render(ctx);
      expect(pixels.inked(5, 50), isTrue);
      expect(pixels.inked(15, 50), isFalse);
      expect(pixels.inked(25, 50), isTrue);

      ctx
        ..setLineDash([5])
        ..setLineDash([1, -1])
        ..setLineDash([1, double.nan]);
      expect(ctx.getLineDash(), [5, 5]);
    });

    test('zero-length dashes draw the caps as dots', () async {
      Future<_Pixels> dots(String cap) {
        final ctx = _context(width: 200)
          ..lineWidth = 6
          ..lineCap = cap
          ..setLineDash([0, 12])
          ..beginPath()
          ..moveTo(10, 50)
          ..lineTo(190, 50)
          ..stroke();
        return _render(ctx);
      }

      // A dot at each 12 pixels from x = 10: 10, 22, ..., 178.
      final round = await dots('round');
      expect(round.runs(50), 15);
      expect(round.inked(10, 50), isTrue);
      expect(round.inked(178, 50), isTrue);
      expect(round.inked(16, 50), isFalse);
      final square = await dots('square');
      expect(square.runs(50), 15);
      // A square cap is 6 x 6, along the line: (19, 47) to (25, 53).
      expect(square.inked(22, 48), isTrue);
      expect(square.inked(20, 52), isTrue);
      expect(square.inked(26, 50), isFalse);
      expect((await dots('butt')).ink(), isNull);

      // The same for a Path2D and for strokeRect.
      final path = Path2D()
        ..moveTo(10, 50)
        ..lineTo(190, 50);
      final ctx = _context(width: 200)
        ..lineWidth = 6
        ..lineCap = 'round'
        ..setLineDash([0, 12])
        ..stroke(path)
        ..strokeRect(10, 80, 120, 0);
      final pixels = await _render(ctx);
      expect(pixels.runs(50), 15);
      expect(pixels.inked(10, 80), isTrue);
      expect(pixels.inked(16, 80), isFalse);
    });

    test('setLineDash keeps the value when it does not change', () {
      final ctx = _context()..setLineDash([]);
      expect(ctx.getLineDash(), isEmpty);
      ctx.setLineDash([4, 2]);
      final first = ctx.getLineDash();
      ctx.setLineDash([4, 2]);
      expect(ctx.getLineDash(), first);
      ctx.setLineDash([3]);
      expect(ctx.getLineDash(), [3, 3]);
      ctx.setLineDash([3, 3]);
      expect(ctx.getLineDash(), [3, 3]);
      ctx.setLineDash([3, 3, 3]);
      expect(ctx.getLineDash(), [3, 3, 3, 3, 3, 3]);
      ctx.setLineDash([]);
      expect(ctx.getLineDash(), isEmpty);
    });

    test('a line dash offset shifts the pattern', () async {
      final ctx = _context()
        ..setLineDash([10, 10])
        ..lineDashOffset = 10
        ..lineWidth = 4
        ..beginPath()
        ..moveTo(0, 50)
        ..lineTo(100, 50)
        ..stroke();
      final pixels = await _render(ctx);
      expect(pixels.inked(5, 50), isFalse);
      expect(pixels.inked(15, 50), isTrue);
    });

    test('a composite operation draws inside a layer', () async {
      final ctx = _context()
        ..fillStyle = 'red'
        ..fillRect(0, 0, 50, 50)
        ..globalCompositeOperation = 'destination-over'
        ..fillStyle = 'lime'
        ..fillRect(0, 0, 100, 100);
      final pixels = await _render(ctx);
      expect(pixels.r(25, 25), 255);
      expect(pixels.g(25, 25), 0);
      expect(pixels.g(75, 75), 255);
    });
  });

  group('text', () {
    Future<ui.Rect> inkOf(void Function(UiCanvasContext ctx) draw) async {
      final ctx = _context(width: 200)..font = '20px Arial';
      draw(ctx);
      final pixels = await _render(ctx);
      return pixels.ink()!;
    }

    test('textAlign places the text around the anchor', () async {
      final left = await inkOf(
        (ctx) => ctx
          ..textAlign = 'left'
          ..fillText('HHH', 100, 50),
      );
      final right = await inkOf(
        (ctx) => ctx
          ..textAlign = 'right'
          ..fillText('HHH', 100, 50),
      );
      final center = await inkOf(
        (ctx) => ctx
          ..textAlign = 'center'
          ..fillText('HHH', 100, 50),
      );
      expect(left.left, greaterThanOrEqualTo(99));
      expect(right.right, lessThanOrEqualTo(101));
      expect(center.left, lessThan(100));
      expect(center.right, greaterThan(100));
      final end = await inkOf(
        (ctx) => ctx
          ..textAlign = 'end'
          ..fillText('HHH', 100, 50),
      );
      expect(end.right, closeTo(right.right, 1));
      final rtlStart = await inkOf(
        (ctx) => ctx
          ..direction = 'rtl'
          ..fillText('HHH', 100, 50),
      );
      expect(rtlStart.right, closeTo(right.right, 1));
    });

    test('textBaseline places the text around the anchor', () async {
      Future<ui.Rect> at(String baseline) => inkOf(
        (ctx) => ctx
          ..textBaseline = baseline
          ..fillText('H', 100, 50),
      );
      final top = await at('top');
      final middle = await at('middle');
      final alphabetic = await at('alphabetic');
      final bottom = await at('bottom');
      expect(top.top, greaterThanOrEqualTo(49));
      expect(alphabetic.bottom, lessThanOrEqualTo(51));
      expect(middle.top, lessThan(50));
      expect(middle.bottom, greaterThan(50));
      expect(bottom.bottom, lessThan(alphabetic.bottom));
    });

    test('measureText has the signs of the DOM', () {
      final ctx = _context()..font = '20px Arial';
      final metrics = ctx.measureText('Hello');
      expect(metrics.width, greaterThan(0));
      expect(metrics.actualBoundingBoxLeft, 0);
      expect(metrics.actualBoundingBoxRight, metrics.width);
      expect(metrics.actualBoundingBoxAscent, greaterThan(0));
      expect(metrics.actualBoundingBoxDescent, greaterThan(0));

      ctx.textAlign = 'center';
      final centered = ctx.measureText('Hello');
      expect(centered.actualBoundingBoxLeft, closeTo(metrics.width / 2, 1e-9));
      expect(centered.actualBoundingBoxRight, closeTo(metrics.width / 2, 1e-9));

      final ascents = [
        for (final baseline in ['top', 'middle', 'alphabetic', 'bottom'])
          (ctx..textBaseline = baseline).measureText('Hello'),
      ];
      for (var i = 1; i < ascents.length; i++) {
        expect(
          ascents[i].actualBoundingBoxAscent,
          greaterThan(ascents[i - 1].actualBoundingBoxAscent),
        );
        expect(
          ascents[i].actualBoundingBoxDescent,
          lessThan(ascents[i - 1].actualBoundingBoxDescent),
        );
      }
      expect(ctx.measureText('').width, 0);
      // A bigger font is wider.
      ctx.font = '40px Arial';
      expect(ctx.measureText('Hello').width, greaterThan(metrics.width * 1.5));
    });

    group('rotated text', () {
      Future<_Pixels> rotated(
        double angle, {
        double x = 0,
        double shift = 0,
      }) async {
        final ctx = _context()
          ..font = '16px Arial'
          ..fillStyle = '#000000'
          ..translate(50, 50)
          ..rotate(angle)
          ..translate(shift, 0)
          ..fillText('HHHH', x, 0);
        return _render(ctx);
      }

      bool same(_Pixels a, _Pixels b) {
        for (var i = 0; i < a.data.lengthInBytes; i++) {
          if (a.data.getUint8(i) != b.data.getUint8(i)) return false;
        }
        return true;
      }

      test('snaps the rotation to steps of 2 degrees', () async {
        // 0.2 rad is 11.46 degrees and 0.21 rad is 12.03 degrees: both
        // round to 12 degrees.
        final a = await rotated(0.2);
        final b = await rotated(0.21);
        expect(same(a, b), isTrue);
        // 0.24 rad is 13.75 degrees: it rounds to 14 degrees.
        final c = await rotated(0.24);
        expect(same(a, c), isFalse);
      });

      test('keeps the anchor point exact', () async {
        // The anchor (10, 0) after the rotation, given as the text point
        // or as a translation, draws the same pixels.
        final point = await rotated(0.2, x: 10);
        final translated = await rotated(0.2, shift: 10);
        expect(same(point, translated), isTrue);
        expect(point.ink(), isNotNull);
      });
    });

    test('maxWidth scales the text down', () async {
      final full = await inkOf((ctx) => ctx.fillText('HHHHHH', 10, 50));
      final scaled = await inkOf(
        (ctx) => ctx.fillText('HHHHHH', 10, 50, full.width / 2),
      );
      expect(scaled.width, closeTo(full.width / 2, 3));
      expect(scaled.height, closeTo(full.height, 1));
      final ctx = _context()..fillText('H', 10, 50, 0);
      expect(ctx.isEmpty, isTrue);
    });

    test('strokeText and a gradient text draw', () async {
      final stroked = await inkOf(
        (ctx) => ctx
          ..lineWidth = 2
          ..strokeText('H', 100, 50),
      );
      expect(stroked.width, greaterThan(0));
      final gradientText = await inkOf((ctx) {
        final gradient = ctx.createLinearGradient(0, 0, 200, 0)
          ..addColorStop(0, 'red')
          ..addColorStop(1, 'blue');
        ctx
          ..fillStyle = gradient
          ..fillText('HHH', 100, 50);
      });
      expect(gradientText.width, greaterThan(0));
    });

    group('a gradient or a pattern is in user space', () {
      // Red left of x = 100, blue right of it, in user space.
      UiCanvasGradient halves(UiCanvasContext ctx) =>
          ctx.createLinearGradient(0, 0, 200, 0)
            ..addColorStop(0, 'red')
            ..addColorStop(0.5, 'red')
            ..addColorStop(0.5, 'blue')
            ..addColorStop(1, 'blue');

      Future<UiCanvasPattern> halvesPattern(UiCanvasContext ctx) async {
        final recorder = ui.PictureRecorder();
        ui.Canvas(recorder)
          ..drawRect(
            const ui.Rect.fromLTWH(0, 0, 100, 100),
            ui.Paint()..color = const ui.Color(0xFFFF0000),
          )
          ..drawRect(
            const ui.Rect.fromLTWH(100, 0, 100, 100),
            ui.Paint()..color = const ui.Color(0xFF0000FF),
          );
        final picture = recorder.endRecording();
        final image = await picture.toImage(200, 100);
        picture.dispose();
        return ctx.createPattern(UiImageSource(image), 'no-repeat')!;
      }

      /// Expects red ink left of [split] and blue ink right of it, in the
      /// text that [draw] draws.
      Future<void> expectHalves(
        void Function(UiCanvasContext ctx) draw, {
        double split = 100,
      }) async {
        final ctx = _context(width: 200)..font = '20px Arial';
        draw(ctx);
        final pixels = await _render(ctx);
        var red = 0;
        var blue = 0;
        for (var y = 0; y < pixels.height; y++) {
          for (var x = 0; x < pixels.width; x++) {
            if (pixels.a(x, y) < 250) continue;
            if (x < split - 3) {
              expect(pixels.r(x, y), greaterThan(200), reason: '($x, $y)');
              expect(pixels.b(x, y), lessThan(50), reason: '($x, $y)');
              red++;
            } else if (x > split + 3) {
              expect(pixels.b(x, y), greaterThan(200), reason: '($x, $y)');
              expect(pixels.r(x, y), lessThan(50), reason: '($x, $y)');
              blue++;
            }
          }
        }
        expect(red, greaterThan(20));
        expect(blue, greaterThan(20));
      }

      test('fillText with a gradient', () async {
        await expectHalves(
          (ctx) => ctx
            ..fillStyle = halves(ctx)
            ..fillText('HHHHH', 60, 50),
        );
        // A translation moves the gradient with the text.
        await expectHalves(
          (ctx) => ctx
            ..translate(20, 0)
            ..fillStyle = halves(ctx)
            ..fillText('HHHHHHHH', 40, 50),
          split: 120,
        );
        // maxWidth scales the text, not the gradient.
        await expectHalves(
          (ctx) => ctx
            ..fillStyle = halves(ctx)
            ..fillText('HHHHHHHHHH', 50, 50, 100),
        );
      });

      test('strokeText with a gradient', () async {
        await expectHalves(
          (ctx) => ctx
            ..lineWidth = 3
            ..strokeStyle = halves(ctx)
            ..strokeText('HHHHH', 60, 50),
        );
      });

      test('fillText with a pattern', () async {
        final ctx = _context(width: 200);
        final pattern = await halvesPattern(ctx);
        await expectHalves(
          (ctx) => ctx
            ..fillStyle = pattern
            ..fillText('HHHHH', 60, 50),
        );
        await expectHalves(
          (ctx) => ctx
            ..lineWidth = 3
            ..strokeStyle = pattern
            ..strokeText('HHHHH', 60, 50),
        );
      });
    });

    test('a disposed paragraph still paints in the recording', () async {
      final ctx = _context(width: 200)
        ..font = '20px sans-serif'
        ..fillStyle = '#ff0000'
        ..fillText('HH', 10, 50);
      // The paragraph that the context drew, from the cache.
      final first = layoutCanvasText(
        parseCanvasFont('20px sans-serif')!,
        'HH',
        ui.TextDirection.ltr,
        color: const ui.Color(0xFFFF0000),
        cacheKey: const ui.Color(0xFFFF0000),
      );
      // Distinct texts, outside the bitmap, evict and dispose it.
      ctx.fillStyle = '#00ff00';
      for (var i = 0; i <= paragraphCacheSize; i++) {
        ctx.fillText('evict $i', 300, 300);
      }
      expect(first.paragraph.debugDisposed, isTrue);
      // A gradient paragraph is disposed after its draw.
      ctx
        ..fillStyle = (ctx.createLinearGradient(0, 0, 200, 0)
          ..addColorStop(0, 'blue')
          ..addColorStop(1, 'blue'))
        ..fillText('HH', 110, 50);
      // The left stem of each first H.
      var pixels = await _render(ctx);
      expect(pixels.r(12, 47), 255);
      expect(pixels.a(12, 47), 255);
      expect(pixels.b(112, 47), 255);
      expect(pixels.a(112, 47), 255);
      // Flattening paints the recorded pictures again, into an image.
      for (var i = 0; i < 20; i++) {
        ctx.fillRect(i.toDouble(), 99, 1, 1);
        await _render(ctx);
      }
      expect(ctx.debugPictureCount, lessThanOrEqualTo(9));
      pixels = await _render(ctx);
      expect(pixels.r(12, 47), 255);
      expect(pixels.a(12, 47), 255);
      expect(pixels.b(112, 47), 255);
      expect(pixels.a(112, 47), 255);
    });
  });

  group('font', () {
    test('parses the toFontString outputs', () {
      final arial = parseCanvasFont('12px arial')!;
      expect(arial.size, 12);
      expect(arial.family, 'arial');
      expect(arial.fallback, isEmpty);
      expect(arial.weight, ui.FontWeight.normal);
      expect(arial.style, ui.FontStyle.normal);

      final defaults = parseCanvasFont(
        "normal 12px 'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",
      )!;
      expect(defaults.size, 12);
      expect(defaults.family, 'Helvetica Neue');
      expect(defaults.fallback, ['Helvetica', 'Arial', 'sans-serif']);
      expect(defaults.weight, ui.FontWeight.normal);

      final bold = parseCanvasFont('italic bold 16px Arial')!;
      expect(bold.size, 16);
      expect(bold.family, 'Arial');
      expect(bold.weight, ui.FontWeight.bold);
      expect(bold.style, ui.FontStyle.italic);
    });

    test('parses weights, units, line heights and quotes', () {
      expect(parseCanvasFont('600 10px a')!.weight, ui.FontWeight.w600);
      expect(parseCanvasFont('lighter 10px a')!.weight, ui.FontWeight.w100);
      expect(parseCanvasFont('12pt a')!.size, 16);
      expect(parseCanvasFont('1.5e1px a')!.size, 15);
      expect(parseCanvasFont('12px/1.2 a')!.family, 'a');
      expect(parseCanvasFont('12px / 1.2 a b')!.family, 'a b');
      expect(parseCanvasFont('12px "Times New Roman", serif')!.families, [
        'Times New Roman',
        'serif',
      ]);
      expect(parseCanvasFont('10px sans-serif')!.families, ['sans-serif']);
    });

    test('a font that does not parse is null', () {
      expect(parseCanvasFont(''), isNull);
      expect(parseCanvasFont('12px'), isNull);
      expect(parseCanvasFont('Arial'), isNull);
      expect(parseCanvasFont('bogus 12px Arial'), isNull);
      expect(parseCanvasFont('12em Arial'), isNull);
      expect(parseCanvasFont("12px 'Arial"), isNull);
      expect(parseCanvasFont('12px Arial,'), isNull);
      expect(parseCanvasFont('2000 12px Arial'), isNull);
    });
  });

  group('circle batch', () {
    /// Draws [count] points as `drawPointLegend` does: a full circle, a
    /// fill and a stroke for each point.
    void points(UiCanvasContext ctx, List<ui.Offset> centers) {
      for (final c in centers) {
        ctx
          ..beginPath()
          ..arc(c.dx, c.dy, 3, 0, 2 * math.pi)
          ..closePath()
          ..fill()
          ..stroke();
      }
    }

    final centers = [
      for (var i = 0; i < 40; i++)
        ui.Offset(10 + (i % 10) * 9.37, 10 + (i ~/ 10) * 21.13),
    ];

    test('gives the pixels of the separate draws', () async {
      final ctx = _context()
        ..fillStyle = 'rgba(54, 162, 235, 0.45)'
        ..strokeStyle = '#36A2EB'
        ..lineWidth = 1;
      points(ctx, centers);
      final batched = await _render(
        ctx,
        background: const ui.Color(0xFFFFFFFF),
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder)
        ..drawRect(
          const ui.Rect.fromLTWH(0, 0, 100, 100),
          ui.Paint()..color = const ui.Color(0xFFFFFFFF),
        );
      final fill = ui.Paint()..color = const ui.Color(0x7336A2EB);
      final stroke = ui.Paint()
        ..color = const ui.Color(0xFF36A2EB)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1;
      for (final c in centers) {
        canvas
          ..drawCircle(c, 3, fill)
          ..drawCircle(c, 3, stroke);
      }
      final image = await recorder.endRecording().toImage(100, 100);
      final data = (await image.toByteData())!;
      var worst = 0;
      for (var i = 0; i < data.lengthInBytes; i++) {
        worst = math.max(
          worst,
          (data.getUint8(i) - batched.data.getUint8(i)).abs(),
        );
      }
      // A sprite draws its circle up to 1 / 8 pixel away from the exact
      // center. That moves the antialiased edge a little, never the color
      // of a point.
      expect(worst, lessThan(64));
      for (final c in centers) {
        final x = c.dx.round();
        final y = c.dy.round();
        expect(batched.b(x, y), greaterThan(200));
        expect(batched.r(x, y), lessThan(200));
      }
    });

    test('keeps the order of fills and strokes', () async {
      // 20 red points, then 20 blue points at the same places: blue on top.
      final ctx = _context()
        ..lineWidth = 2
        ..fillStyle = '#ff0000'
        ..strokeStyle = '#ff0000';
      points(ctx, centers.take(20).toList());
      ctx
        ..fillStyle = '#0000ff'
        ..strokeStyle = '#0000ff';
      points(ctx, centers.take(20).toList());
      final pixels = await _render(ctx);
      for (final c in centers.take(20)) {
        expect(pixels.b(c.dx.round(), c.dy.round()), 255);
        expect(pixels.r(c.dx.round(), c.dy.round()), 0);
      }
    });

    test('draws before a later draw, a clip and a restore', () async {
      final ctx = _context()
        ..fillStyle = '#ff0000'
        ..strokeStyle = '#ff0000';
      points(ctx, centers);
      ctx
        ..save()
        ..beginPath()
        ..rect(0, 0, 50, 100)
        ..clip()
        ..fillStyle = '#00ff00'
        ..fillRect(0, 0, 100, 5)
        ..restore();
      final pixels = await _render(ctx);
      // The clip does not cut the earlier points on the right.
      final right = centers.last;
      expect(pixels.r(right.dx.round(), right.dy.round()), 255);
      // The later rectangle covers the points under it, only left of 50.
      expect(pixels.g(10, 2), 255);
      expect(pixels.g(80, 2), 0);
    });

    test('a full clear drops the pending circles', () async {
      final ctx = _context()
        ..fillStyle = '#ff0000'
        ..strokeStyle = '#ff0000';
      points(ctx, centers);
      ctx.clearRect(0, 0, 100, 100);
      expect(ctx.isEmpty, isTrue);
      final pixels = await _render(ctx);
      expect(pixels.ink(), isNull);
    });

    test('a dashed stroke does not join the batch', () async {
      final ctx = _context()
        ..lineWidth = 4
        ..strokeStyle = '#000000'
        ..setLineDash([10, 1000]);
      for (var i = 0; i < 20; i++) {
        ctx
          ..beginPath()
          ..arc(50, 50, 30, 0, 2 * math.pi)
          ..stroke();
      }
      final pixels = await _render(ctx);
      expect(pixels.inked(80, 52), isTrue);
      expect(pixels.inked(20, 50), isFalse);
    });

    // The largest difference of one channel from the reference, with the
    // centers at the 1 / 4 pixel of the batch.
    const tolerance = 8;
    const red = ui.Color(0xFFFF0000);
    const green = ui.Color(0xFF00FF00);
    const blue = ui.Color(0xFF0000FF);
    const black = ui.Color(0xFF000000);

    /// A full circle at (x, y) with the radius [r], filled and stroked.
    void circle(
      UiCanvasContext ctx,
      double x,
      double y,
      double r, {
      bool fill = true,
      bool stroke = true,
    }) {
      ctx
        ..beginPath()
        ..arc(x, y, r, 0, 2 * math.pi)
        ..closePath();
      if (fill) ctx.fill();
      if (stroke) ctx.stroke();
    }

    /// The reference dot of [circle] in bitmap space.
    _Dot dot(
      double x,
      double y,
      double r, {
      ui.Color? fill = red,
      ui.Color? stroke = blue,
      double width = 1,
    }) => (c: ui.Offset(x, y), r: r, fill: fill, stroke: stroke, width: width);

    UiCanvasContext styled() => _context()
      ..fillStyle = '#ff0000'
      ..strokeStyle = '#0000ff'
      ..lineWidth = 1;

    test('a transform change in a run moves only the later points', () async {
      final ctx = styled();
      final dots = <_Dot>[];
      void run(double dx, double dy, double s) {
        for (final c in centers.take(20)) {
          circle(ctx, c.dx, c.dy, 3);
          dots.add(dot(c.dx * s + dx, c.dy * s + dy, 3 * s, width: s));
        }
      }

      run(0, 0, 1);
      // The radius stays: the run goes on.
      ctx.translate(5.3, 37.1);
      run(5.3, 37.1, 1);
      ctx.scale(0.5, 0.5);
      run(5.3, 37.1, 0.5);
      ctx.setTransform(1, 0, 0, 1, 0, 70);
      run(0, 70, 1);
      final pixels = await _render(ctx);
      expect(
        _worstDifference(pixels.data, await _reference(dots)),
        lessThanOrEqualTo(tolerance),
      );
    });

    test('globalAlpha and style changes split the run', () async {
      final ctx = styled();
      final dots = <_Dot>[];
      void run(double dy, ui.Color fill, ui.Color stroke) {
        for (final c in centers.take(20)) {
          circle(ctx, c.dx, c.dy + dy, 3);
          dots.add(dot(c.dx, c.dy + dy, 3, fill: fill, stroke: stroke));
        }
      }

      run(0, red, blue);
      ctx.globalAlpha = 0.5;
      run(22, red.withValues(alpha: 0.5), blue.withValues(alpha: 0.5));
      ctx.fillStyle = '#00ff00';
      run(44, green.withValues(alpha: 0.5), blue.withValues(alpha: 0.5));
      ctx
        ..globalAlpha = 1
        ..strokeStyle = '#000000';
      run(66, green, black);
      final pixels = await _render(ctx);
      expect(
        _worstDifference(pixels.data, await _reference(dots)),
        lessThanOrEqualTo(tolerance),
      );
    });

    test('a circle fill and a later fill of the same color', () async {
      const half = ui.Color.from(alpha: 0.5, red: 1, green: 0, blue: 0);
      final ctx = _context()..fillStyle = 'rgba(255, 0, 0, 0.5)';
      final dots = <_Dot>[];
      for (final c in centers.take(20)) {
        circle(ctx, c.dx, c.dy, 3, stroke: false);
        dots.add(dot(c.dx, c.dy, 3, fill: half, stroke: null));
      }
      ctx.fillRect(0, 0, 100, 20);
      for (final c in centers.take(20)) {
        circle(ctx, c.dx, c.dy + 30, 3, stroke: false);
        dots.add(dot(c.dx, c.dy + 30, 3, fill: half, stroke: null));
      }
      final pixels = await _render(ctx);
      final reference = await _reference(
        dots,
        at: (canvas, i) {
          if (i == 20) {
            canvas.drawRect(
              const ui.Rect.fromLTWH(0, 0, 100, 20),
              ui.Paint()..color = half,
            );
          }
        },
      );
      expect(
        _worstDifference(pixels.data, reference),
        lessThanOrEqualTo(tolerance),
      );
      // Two layers of 0.5 at a center under the rectangle.
      expect(pixels.a(10, 10), inInclusiveRange(188, 194));
    });

    test('interleaved fills and strokes of other points', () async {
      final ctx = styled()..lineWidth = 2;
      final dots = <_Dot>[];
      for (var i = 0; i < centers.length; i++) {
        final c = centers[i];
        final fill = i.isEven;
        circle(ctx, c.dx, c.dy, 3, fill: fill, stroke: !fill);
        dots.add(
          dot(
            c.dx,
            c.dy,
            3,
            fill: fill ? red : null,
            stroke: fill ? null : blue,
            width: 2,
          ),
        );
      }
      final pixels = await _render(ctx);
      expect(
        _worstDifference(pixels.data, await _reference(dots)),
        lessThanOrEqualTo(tolerance),
      );
    });

    test('a radius or a line width change in a run', () async {
      final ctx = styled();
      final dots = <_Dot>[];
      for (var i = 0; i < centers.length; i++) {
        final c = centers[i];
        final r = i >= 10 && i < 30 ? 4.0 : 3.0;
        final width = i < 20 ? 1.0 : 3.0;
        ctx.lineWidth = width;
        circle(ctx, c.dx, c.dy, r);
        dots.add(dot(c.dx, c.dy, r, width: width));
      }
      final pixels = await _render(ctx);
      expect(
        _worstDifference(pixels.data, await _reference(dots)),
        lessThanOrEqualTo(tolerance),
      );
    });

    test('a run around save, clip and restore', () async {
      final ctx = styled();
      final dots = <_Dot>[];
      void run(double dy) {
        for (final c in centers.take(20)) {
          circle(ctx, c.dx, c.dy + dy, 3);
          dots.add(dot(c.dx, c.dy + dy, 3));
        }
      }

      run(0);
      ctx
        ..save()
        ..beginPath()
        ..rect(0, 0, 50, 100)
        ..clip();
      run(33);
      ctx.restore();
      run(66);
      final pixels = await _render(ctx);
      final reference = await _reference(
        dots,
        at: (canvas, i) {
          if (i == 20) {
            canvas
              ..save()
              ..clipRect(const ui.Rect.fromLTWH(0, 0, 50, 100));
          }
          if (i == 40) canvas.restore();
        },
      );
      expect(
        _worstDifference(pixels.data, reference),
        lessThanOrEqualTo(tolerance),
      );
      final right = centers[18];
      expect(pixels.inked(right.dx.round(), right.dy.round() + 33), isFalse);
      expect(pixels.inked(right.dx.round(), right.dy.round() + 66), isTrue);
    });

    test('a snapshot and a paint in the middle of a run', () async {
      final ctx = styled();
      final dots = <_Dot>[];
      for (final c in centers.take(20)) {
        circle(ctx, c.dx, c.dy, 3);
        dots.add(dot(c.dx, c.dy, 3));
      }
      final snapshot = ctx.canvas.toImageSource().image;
      final data = (await snapshot.toByteData())!;
      expect(
        _worstDifference(data, await _reference(dots)),
        lessThanOrEqualTo(tolerance),
      );
      for (final c in centers.skip(20).take(10)) {
        circle(ctx, c.dx, c.dy, 3);
        dots.add(dot(c.dx, c.dy, 3));
      }
      await _render(ctx);
      for (final c in centers.skip(30)) {
        circle(ctx, c.dx, c.dy, 3);
        dots.add(dot(c.dx, c.dy, 3));
      }
      final pixels = await _render(ctx);
      expect(
        _worstDifference(pixels.data, await _reference(dots)),
        lessThanOrEqualTo(tolerance),
      );
    });

    test('flattened pictures keep the runs', () async {
      final ctx = styled();
      final dots = <_Dot>[];
      for (var k = 0; k < 12; k++) {
        for (var i = 0; i < 10; i++) {
          final x = 5 + i * 9.5 + k * 0.13;
          final y = 4 + k * 8.0 + i * 0.07;
          circle(ctx, x, y, 3);
          dots.add(dot(x, y, 3));
        }
        if (k < 11) await _render(ctx);
      }
      final pixels = await _render(ctx);
      expect(ctx.debugPictureCount, lessThanOrEqualTo(9));
      expect(
        _worstDifference(pixels.data, await _reference(dots)),
        lessThanOrEqualTo(tolerance),
      );
    });

    test('a partial clearRect covers the run before it', () async {
      final ctx = styled();
      final dots = <_Dot>[];
      for (final c in centers.take(20)) {
        circle(ctx, c.dx, c.dy, 3);
        dots.add(dot(c.dx, c.dy, 3));
      }
      ctx.clearRect(0, 0, 50, 100);
      for (final c in centers.take(20)) {
        circle(ctx, c.dx, c.dy + 40, 3);
        dots.add(dot(c.dx, c.dy + 40, 3));
      }
      final pixels = await _render(ctx);
      final reference = await _reference(
        dots,
        at: (canvas, i) {
          if (i == 20) {
            canvas.drawRect(
              const ui.Rect.fromLTWH(0, 0, 50, 100),
              ui.Paint()..blendMode = ui.BlendMode.clear,
            );
          }
        },
      );
      expect(
        _worstDifference(pixels.data, reference),
        lessThanOrEqualTo(tolerance),
      );
      expect(pixels.inked(10, 10), isFalse);
      expect(pixels.inked(10, 50), isTrue);
    });

    test('dispose and a resize drop a pending run', () async {
      final ctx = styled();
      points(ctx, centers);
      ctx.dispose();
      expect(ctx.isEmpty, isTrue);
      expect((await _render(ctx)).ink(), isNull);

      final element = UiCanvasElement(width: 100, height: 100);
      final resized = element.getContext2d()
        ..fillStyle = '#ff0000'
        ..strokeStyle = '#0000ff';
      points(resized, centers);
      element.width = 100;
      expect(resized.isEmpty, isTrue);
      expect((await _render(resized)).ink(), isNull);
      // The reset state draws black.
      final dots = <_Dot>[];
      for (final c in centers) {
        circle(resized, c.dx, c.dy, 3);
        dots.add(dot(c.dx, c.dy, 3, fill: black, stroke: black));
      }
      final pixels = await _render(resized);
      expect(
        _worstDifference(pixels.data, await _reference(dots)),
        lessThanOrEqualTo(tolerance),
      );
    });

    test('a Path2D circle draws in user space and in order', () async {
      final ctx = styled()..scale(2, 2);
      final dots = <_Dot>[];
      // Inside the bitmap: a direct draw across the border rasterizes
      // otherwise under the clip of paint.
      for (final c in centers.take(20)) {
        final x = c.dx * 0.4;
        final y = c.dy / 2;
        ctx
          ..fillStyle = '#ff0000'
          ..fill(Path2D()..arc(x, y, 1.5, 0, 2 * math.pi));
        dots.add(dot(2 * x, c.dy, 3, stroke: null));
        circle(ctx, x + 1, y, 1.5);
        dots.add(dot(2 * x + 2, c.dy, 3, width: 2));
        ctx.fillStyle = '#00ff00';
        circle(ctx, x + 2, y, 1.5, stroke: false);
        dots.add(dot(2 * x + 4, c.dy, 3, fill: green, stroke: null));
      }
      final pixels = await _render(ctx);
      // Each run is short: the circles draw at their exact centers.
      expect(
        _worstDifference(pixels.data, await _reference(dots, snap: false)),
        lessThanOrEqualTo(tolerance),
      );
    });

    test('an evenodd fill of one circle', () async {
      final ctx = styled();
      final dots = <_Dot>[];
      for (final c in centers) {
        ctx
          ..beginPath()
          ..arc(c.dx, c.dy, 3, 0, 2 * math.pi)
          ..fill('evenodd')
          ..stroke();
        dots.add(dot(c.dx, c.dy, 3));
      }
      final pixels = await _render(ctx);
      expect(
        _worstDifference(pixels.data, await _reference(dots)),
        lessThanOrEqualTo(tolerance),
      );
    });

    test('a center out of range does not drop the run', () async {
      final ctx = styled();
      final dots = <_Dot>[];
      for (final c in centers.take(10)) {
        circle(ctx, c.dx, c.dy, 3);
        dots.add(dot(c.dx, c.dy, 3));
      }
      // Powers of two keep the radius at 3 and the line width at 1: the
      // run goes on. 1e9 * 2^100 is finite but above the float32 range;
      // 1e160 * 2^500 is infinite.
      for (final e in [100, 500]) {
        final s = math.pow(2.0, e).toDouble();
        final far = e == 100 ? 1e9 : 1e160;
        ctx
          ..setTransform(s, 0, 0, s, 0, 0)
          ..lineWidth = 1 / s;
        circle(ctx, far, 1 / s, 3 / s);
        circle(ctx, -1 / s, -far, 3 / s);
      }
      ctx
        ..resetTransform()
        ..lineWidth = 1;
      for (final c in centers.skip(10).take(10)) {
        circle(ctx, c.dx, c.dy, 3);
        dots.add(dot(c.dx, c.dy, 3));
      }
      final pixels = await _render(ctx);
      expect(
        _worstDifference(pixels.data, await _reference(dots)),
        lessThanOrEqualTo(tolerance),
      );
    });

    test('a NaN center draws nothing', () async {
      final ctx = styled();
      final dots = <_Dot>[];
      // A rotation of 3-4-5 with a scale of 5 * 2^500 keeps the radius at 3
      // and the line width at 1. The center is (NaN, infinity).
      final s = math.pow(2.0, 500).toDouble();
      void nan() {
        ctx
          ..setTransform(3 * s, 4 * s, -4 * s, 3 * s, 0, 0)
          ..lineWidth = 0.2 / s;
        circle(ctx, 1e160, 1e160, 0.6 / s);
        ctx
          ..resetTransform()
          ..lineWidth = 1;
      }

      // Alone, then inside a run.
      nan();
      for (final c in centers.take(10)) {
        circle(ctx, c.dx, c.dy, 3);
        dots.add(dot(c.dx, c.dy, 3));
      }
      nan();
      for (final c in centers.skip(10).take(10)) {
        circle(ctx, c.dx, c.dy, 3);
        dots.add(dot(c.dx, c.dy, 3));
      }
      final pixels = await _render(ctx);
      expect(
        _worstDifference(pixels.data, await _reference(dots)),
        lessThanOrEqualTo(tolerance),
      );
    });

    test('negative and fractional centers', () async {
      final ctx = styled();
      final dots = <_Dot>[];
      for (var i = 0; i < 24; i++) {
        final x = -2.9 + i * 0.37;
        final y = 3 + i * 4.1;
        circle(ctx, x, y, 3);
        dots.add(dot(x, y, 3));
        circle(ctx, y, x, 3);
        dots.add(dot(y, x, 3));
      }
      final pixels = await _render(ctx);
      expect(
        _worstDifference(pixels.data, await _reference(dots)),
        lessThanOrEqualTo(tolerance),
      );
    });

    test('many points', () async {
      final ctx = _context(width: 200, height: 200)
        ..fillStyle = '#ff0000'
        ..strokeStyle = '#0000ff';
      final dots = <_Dot>[];
      final random = math.Random(7);
      for (var i = 0; i < 3000; i++) {
        final x = random.nextDouble() * 200;
        final y = random.nextDouble() * 200;
        circle(ctx, x, y, 2);
        dots.add(dot(x, y, 2));
      }
      final pixels = await _render(ctx);
      final reference = await _reference(dots, width: 200, height: 200);
      expect(
        _worstDifference(pixels.data, reference),
        lessThanOrEqualTo(tolerance),
      );
    });

    test('a recorded run survives the eviction of its sprite', () async {
      final ctx = styled();
      final dots = <_Dot>[];
      for (final c in centers) {
        circle(ctx, c.dx, c.dy, 3);
        dots.add(dot(c.dx, c.dy, 3));
      }
      await _render(ctx);
      final other = _context();
      for (var k = 0; k < 40; k++) {
        other
          ..clearRect(0, 0, 100, 100)
          ..fillStyle = 'rgb($k, 200, 0)'
          ..strokeStyle = '#00ff00';
        points(other, centers.take(10).toList());
        await _render(other);
      }
      final pixels = await _render(ctx);
      expect(
        _worstDifference(pixels.data, await _reference(dots)),
        lessThanOrEqualTo(tolerance),
      );
      final snapshot = ctx.canvas.toImageSource().image;
      final data = (await snapshot.toByteData())!;
      expect(
        _worstDifference(data, await _reference(dots)),
        lessThanOrEqualTo(tolerance),
      );
    });

    test('the pictures are in bitmap space at a device pixel ratio', () async {
      const dpr = 2.625;
      final element = UiCanvasElement(width: 263, height: 263);
      final ctx = element.getContext2d()
        ..setTransform(dpr, 0, 0, dpr, 0, 0)
        ..fillStyle = '#ff0000'
        ..strokeStyle = '#0000ff';
      points(ctx, centers);
      // RenderView scales the scene by the ratio, and the host paints the
      // bitmap at 1 / ratio.
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder)..scale(dpr);
      ctx.paint(canvas, ui.Offset.zero, 1 / dpr, 1 / dpr);
      final image = await recorder.endRecording().toImage(263, 263);
      final data = (await image.toByteData())!;
      final reference = await _reference(
        [
          for (final c in centers)
            dot(c.dx * dpr, c.dy * dpr, 3 * dpr, width: dpr),
        ],
        width: 263,
        height: 263,
      );
      expect(_worstDifference(data, reference), lessThanOrEqualTo(tolerance));
    });
    test('a composite operation after a run erases it in order', () async {
      final ctx = styled();
      final dots = <_Dot>[];
      for (final c in centers) {
        circle(ctx, c.dx, c.dy, 3);
        dots.add(dot(c.dx, c.dy, 3));
      }
      ctx.globalCompositeOperation = 'destination-out';
      for (final c in centers.take(10)) {
        circle(ctx, c.dx, c.dy, 4, stroke: false);
      }
      ctx.globalCompositeOperation = 'source-over';
      for (final c in centers.take(20)) {
        circle(ctx, c.dx, c.dy + 2, 3);
        dots.add(dot(c.dx, c.dy + 2, 3));
      }
      final pixels = await _render(ctx);
      final reference = await _reference(
        dots,
        at: (canvas, i) {
          if (i == 0) {
            canvas.saveLayer(null, ui.Paint());
          }
          if (i == 40) {
            for (final c in centers.take(10)) {
              canvas.drawCircle(
                ui.Offset(
                  (c.dx * 4).roundToDouble() / 4,
                  (c.dy * 4).roundToDouble() / 4,
                ),
                4,
                ui.Paint()..blendMode = ui.BlendMode.dstOut,
              );
            }
          }
          if (i == 60) canvas.restore();
        },
      );
      // The erasing circles draw directly, at their exact centers.
      expect(_worstDifference(pixels.data, reference), lessThan(64));
      final first = centers.first;
      expect(pixels.inked(first.dx.round(), first.dy.round() - 3), isFalse);
    });

    test('a zero radius draws nothing', () async {
      final ctx = styled()..lineWidth = 4;
      for (final c in centers) {
        circle(ctx, c.dx, c.dy, 0);
      }
      expect((await _render(ctx)).ink(), isNull);
    });

    test('a wide stroke draws directly', () async {
      // The sprite would hold the line width: 16880 pixels wide.
      final ctx = _context()
        ..strokeStyle = '#0000ff'
        ..lineWidth = 2100;
      for (var i = 0; i < 20; i++) {
        circle(ctx, 50 + i * 0.1, 50, 3, fill: false);
      }
      final pixels = await _render(ctx);
      final reference = await _reference(
        [
          for (var i = 0; i < 20; i++)
            dot(50 + i * 0.1, 50, 3, fill: null, width: 2100),
        ],
        snap: false,
      );
      expect(
        _worstDifference(pixels.data, reference),
        lessThanOrEqualTo(tolerance),
      );
    });

    test('a run in a recording keeps its evicted sprite', () async {
      final ctx = styled();
      final dots = <_Dot>[];
      for (final c in centers) {
        circle(ctx, c.dx, c.dy, 3);
        dots.add(dot(c.dx, c.dy, 3));
      }
      // 40 runs of other colors in the same recording, outside the bitmap.
      for (var k = 0; k < 40; k++) {
        ctx.fillStyle = 'rgb($k, 200, 0)';
        for (var i = 0; i < 10; i++) {
          circle(ctx, 200.0 + i, 200, 3);
        }
      }
      final pixels = await _render(ctx);
      expect(
        _worstDifference(pixels.data, await _reference(dots)),
        lessThanOrEqualTo(tolerance),
      );
    });

    test('the points stay in place under the transform of the host', () async {
      /// The center of the ink of [data] near [at], weighted by alpha.
      ui.Offset centroid(ByteData data, int width, ui.Offset at) {
        var sum = 0.0;
        var sx = 0.0;
        var sy = 0.0;
        for (var y = at.dy.floor() - 7; y <= at.dy.floor() + 7; y++) {
          for (var x = at.dx.floor() - 7; x <= at.dx.floor() + 7; x++) {
            final a = data.getUint8((y * width + x) * 4 + 3).toDouble();
            sum += a;
            sx += a * (x + 0.5);
            sy += a * (y + 0.5);
          }
        }
        return ui.Offset(sx / sum, sy / sum);
      }

      final ctx = _context()..fillStyle = '#ff0000';
      for (final c in centers) {
        circle(ctx, c.dx, c.dy, 3, stroke: false);
      }
      final dots = [for (final c in centers) dot(c.dx, c.dy, 3, stroke: null)];
      // A host at a fractional device pixel (a layout offset times a ratio
      // of 2.625), and a scale (a page transition).
      for (final (offset, scale) in [
        (const ui.Offset(0.4, 0.3), 1.0),
        (const ui.Offset(0.5, 0.5), 1.0),
        (ui.Offset.zero, 1.1),
        (ui.Offset.zero, 0.9),
      ]) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder)..scale(scale);
        ctx.paint(canvas, offset, 1, 1);
        final image = await recorder.endRecording().toImage(120, 120);
        final data = (await image.toByteData())!;
        image.dispose();
        final reference = await _reference(
          dots,
          width: 120,
          height: 120,
          at: (canvas, i) {
            if (i == 0) {
              canvas
                ..scale(scale)
                ..translate(offset.dx, offset.dy);
            }
          },
        );
        for (final c in centers) {
          final at = (c + offset) * scale;
          final error = centroid(data, 120, at) - centroid(reference, 120, at);
          // A resampled sprite moves its circle by about the 1 / 8 pixel
          // of the batch; a sprite at the nearest pixel by up to 1 / 2.
          expect(
            error.distance,
            lessThan(0.2),
            reason: '$c at $offset x $scale',
          );
        }
      }
    });
  });

  group('picture model', () {
    test('onChanged fires once until the next paint', () async {
      var calls = 0;
      final ctx = _context()
        ..onChanged = (() => calls++)
        ..fillRect(0, 0, 10, 10)
        ..fillRect(10, 10, 10, 10);
      expect(calls, 1);
      await _render(ctx);
      ctx.fillRect(0, 0, 10, 10);
      expect(calls, 2);
      // State changes are not content changes.
      await _render(ctx);
      ctx
        ..save()
        ..translate(1, 1)
        ..restore();
      expect(calls, 2);
    });

    test('many pictures without a clear are flattened', () async {
      final ctx = _context();
      for (var i = 0; i < 20; i++) {
        ctx.fillRect(i * 5.0, 0, 5, 5);
        await _render(ctx);
      }
      expect(ctx.debugPictureCount, lessThanOrEqualTo(9));
      final pixels = await _render(ctx);
      for (var i = 0; i < 20; i++) {
        expect(pixels.inked(i * 5 + 2, 2), isTrue, reason: 'square $i');
      }
    });

    test('dispose drops the content', () {
      final ctx = _context()
        ..fillRect(0, 0, 10, 10)
        ..dispose();
      expect(ctx.isEmpty, isTrue);
      ctx.fillRect(0, 0, 10, 10);
      expect(ctx.isEmpty, isTrue);
    });
  });
}
