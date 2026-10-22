// Original code, not ported from Chart.js: the dart:ui canvas styles.

/// The styles of the `dart:ui` canvas context (Chart.js ADR 0013,
/// porting-flow.md 2.2): CSS colors, gradients, patterns, images,
/// composite operations and line dashes.
///
/// - A CSS color string parses with the ported @kurkle/color
///   (`lib/src/kurkle_color/`), through a bounded cache of `ui.Color`
///   values. A string that does not parse is invalid: the DOM ignores it.
/// - A gradient builds its `ui.Gradient` when a draw uses it, with the
///   transform of that draw (the DOM rule: gradient coordinates are in the
///   user space of the draw). The shader is cached for the last matrix.
/// - A pattern is a `ui.ImageShader` with the tile modes of the repetition.
/// - A line dash cuts the path with `ui.PathMetric.extractPath`, the usual
///   Flutter recipe: `dart:ui` has no dash.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/kurkle_color/index.esm.dart' as kurkle;

/// The bound of the color cache. A full cache starts again empty.
const int _colorCacheSize = 512;

final Map<String, ui.Color?> _colorCache = {};

/// The `ui.Color` of the CSS color [value], or `null` when [value] does not
/// parse. The parser is the ported @kurkle/color. Results are cached.
ui.Color? parseCssColor(String value) {
  final cached = _colorCache[value];
  if (cached != null || _colorCache.containsKey(value)) return cached;
  if (_colorCache.length >= _colorCacheSize) _colorCache.clear();
  final parsed = kurkle.Color(value.trim());
  ui.Color? color;
  if (parsed.valid) {
    final rgb = parsed.rgb!;
    color = ui.Color.fromARGB(
      (rgb.a * 255).round().clamp(0, 255),
      rgb.r.round().clamp(0, 255),
      rgb.g.round().clamp(0, 255),
      rgb.b.round().clamp(0, 255),
    );
  }
  return _colorCache[value] = color;
}

String _hex2(int v) => v.toRadixString(16).padLeft(2, '0');

int _byte(double unit) => (unit * 255).round().clamp(0, 255);

/// The DOM serialization of a color style: `#rrggbb` when the color is
/// opaque, else `rgba(r, g, b, a)`.
String serializeCssColor(ui.Color color) {
  final r = _byte(color.r);
  final g = _byte(color.g);
  final b = _byte(color.b);
  final a = _byte(color.a);
  if (a == 255) return '#${_hex2(r)}${_hex2(g)}${_hex2(b)}';
  // The shortest alpha with 2 or 3 decimals that gives the same byte.
  var alpha = (a / 255).toStringAsFixed(2);
  if ((double.parse(alpha) * 255).round() != a) {
    alpha = (a / 255).toStringAsFixed(3);
  }
  if (alpha.contains('.')) {
    alpha = alpha.replaceFirst(RegExp(r'0+$'), '');
    if (alpha.endsWith('.')) alpha = alpha.substring(0, alpha.length - 1);
  }
  return 'rgba($r, $g, $b, $alpha)';
}

/// The `ui.BlendMode` of each `globalCompositeOperation` name.
const Map<String, ui.BlendMode> compositeOperations = {
  'source-over': ui.BlendMode.srcOver,
  'source-in': ui.BlendMode.srcIn,
  'source-out': ui.BlendMode.srcOut,
  'source-atop': ui.BlendMode.srcATop,
  'destination-over': ui.BlendMode.dstOver,
  'destination-in': ui.BlendMode.dstIn,
  'destination-out': ui.BlendMode.dstOut,
  'destination-atop': ui.BlendMode.dstATop,
  'lighter': ui.BlendMode.plus,
  'copy': ui.BlendMode.src,
  'xor': ui.BlendMode.xor,
  'multiply': ui.BlendMode.multiply,
  'screen': ui.BlendMode.screen,
  'overlay': ui.BlendMode.overlay,
  'darken': ui.BlendMode.darken,
  'lighten': ui.BlendMode.lighten,
  'color-dodge': ui.BlendMode.colorDodge,
  'color-burn': ui.BlendMode.colorBurn,
  'hard-light': ui.BlendMode.hardLight,
  'soft-light': ui.BlendMode.softLight,
  'difference': ui.BlendMode.difference,
  'exclusion': ui.BlendMode.exclusion,
  'hue': ui.BlendMode.hue,
  'saturation': ui.BlendMode.saturation,
  'color': ui.BlendMode.color,
  'luminosity': ui.BlendMode.luminosity,
};

/// A [CanvasImageSource] that wraps a `ui.Image`, for
/// [CanvasRenderingContext2D.drawImage] and
/// [CanvasRenderingContext2D.createPattern].
final class UiImageSource implements CanvasImageSource {
  /// Wraps [image]. Its size in CSS pixels is its size in pixels.
  UiImageSource(this.image);

  /// The image.
  final ui.Image image;

  @override
  double get width => image.width.toDouble();

  @override
  double get height => image.height.toDouble();
}

/// A paint source that builds a shader for a draw: a gradient or a
/// pattern.
sealed class UiShaderSource {
  Float64List? _lastMatrix;
  ui.Shader? _lastShader;
  bool _valid = false;

  /// Marks the cached shader stale.
  void _invalidate() => _valid = false;

  /// The shader for a draw whose local space maps to the user space of the
  /// style through [matrix] (a column-major 4 x 4 matrix, `null` for the
  /// identity). `null` when the style paints nothing.
  ui.Shader? shaderFor(Float64List? matrix) {
    if (_valid && _sameMatrix(_lastMatrix, matrix)) return _lastShader;
    _lastMatrix = matrix == null ? null : Float64List.fromList(matrix);
    _lastShader = _build(matrix);
    _valid = true;
    return _lastShader;
  }

  ui.Shader? _build(Float64List? matrix);

  static bool _sameMatrix(Float64List? a, Float64List? b) {
    if (a == null || b == null) return a == null && b == null;
    // A 2D affine matrix: the other entries are fixed.
    return a[0] == b[0] &&
        a[1] == b[1] &&
        a[4] == b[4] &&
        a[5] == b[5] &&
        a[12] == b[12] &&
        a[13] == b[13];
  }
}

/// The kinds of [UiCanvasGradient].
enum UiGradientKind {
  /// `createLinearGradient`.
  linear,

  /// `createRadialGradient`.
  radial,

  /// `createConicGradient`.
  conic,
}

/// The `dart:ui` [CanvasGradient].
final class UiCanvasGradient extends UiShaderSource implements CanvasGradient {
  /// `createLinearGradient(x0, y0, x1, y1)`.
  UiCanvasGradient.linear(this.x0, this.y0, this.x1, this.y1)
    : kind = UiGradientKind.linear,
      r0 = 0,
      r1 = 0;

  /// `createRadialGradient(x0, y0, r0, x1, y1, r1)`. A negative radius
  /// throws a [RangeError] (the DOM `IndexSizeError`).
  UiCanvasGradient.radial(this.x0, this.y0, this.r0, this.x1, this.y1, this.r1)
    : kind = UiGradientKind.radial {
    if (r0 < 0 || r1 < 0) throw RangeError('The radius is negative');
  }

  /// `createConicGradient(startAngle, x, y)`: [r0] holds the start angle.
  UiCanvasGradient.conic(double startAngle, this.x0, this.y0)
    : kind = UiGradientKind.conic,
      r0 = startAngle,
      x1 = x0,
      y1 = y0,
      r1 = 0;

  /// The kind.
  final UiGradientKind kind;

  /// The start point (the center of a conic gradient).
  final double x0;

  /// The start point (the center of a conic gradient).
  final double y0;

  /// The start radius, or the start angle of a conic gradient.
  final double r0;

  /// The end point.
  final double x1;

  /// The end point.
  final double y1;

  /// The end radius.
  final double r1;

  final List<double> _offsets = [];
  final List<ui.Color> _colors = [];

  /// The color stops: offsets in [0, 1], ascending.
  List<double> get offsets => List.unmodifiable(_offsets);

  /// The colors of the stops.
  List<ui.Color> get colors => List.unmodifiable(_colors);

  /// `addColorStop(offset, color)`. An offset outside [0, 1] throws a
  /// [RangeError] (the DOM `IndexSizeError`). A color that does not parse
  /// throws a [FormatException] (the DOM `SyntaxError`). A stop with the
  /// same offset as earlier stops goes after them.
  @override
  void addColorStop(double offset, String color) {
    if (!(offset >= 0 && offset <= 1)) {
      throw RangeError.range(offset, 0, 1, 'offset');
    }
    final parsed = parseCssColor(color);
    if (parsed == null) {
      throw FormatException('The color does not parse', color);
    }
    var i = _offsets.length;
    while (i > 0 && _offsets[i - 1] > offset) {
      i--;
    }
    _offsets.insert(i, offset);
    _colors.insert(i, parsed);
    _invalidate();
  }

  @override
  ui.Shader? _build(Float64List? matrix) {
    if (_colors.isEmpty) return null;
    var colors = _colors;
    var stops = _offsets;
    if (colors.length == 1) {
      colors = [colors[0], colors[0]];
      stops = const [0, 1];
    }
    switch (kind) {
      case UiGradientKind.linear:
        if (x0 == x1 && y0 == y1) return null;
        return ui.Gradient.linear(
          ui.Offset(x0, y0),
          ui.Offset(x1, y1),
          colors,
          stops,
          ui.TileMode.clamp,
          matrix,
        );
      case UiGradientKind.radial:
        if (x0 == x1 && y0 == y1 && r0 == r1) return null;
        // The engine rejects a conical gradient with both centers at the
        // origin: draw it shifted, with a matrix that shifts it back.
        var shift = 0.0;
        if (x0 == 0 && y0 == 0 && x1 == 0 && y1 == 0 && r0 != 0) {
          shift = 1;
        }
        var m = matrix;
        if (shift != 0) {
          m = Float64List(16)
            ..[0] = 1
            ..[5] = 1
            ..[10] = 1
            ..[12] = -shift
            ..[13] = -shift
            ..[15] = 1;
          if (matrix != null) m = _multiply(matrix, m);
        }
        return ui.Gradient.radial(
          ui.Offset(x1 + shift, y1 + shift),
          r1,
          colors,
          stops,
          ui.TileMode.clamp,
          m,
          ui.Offset(x0 + shift, y0 + shift),
          r0,
        );
      case UiGradientKind.conic:
        // The angle 0 of a conic gradient is the positive x axis, as for a
        // sweep gradient. The start angle rotates it around the center.
        final cos = math.cos(r0);
        final sin = math.sin(r0);
        final rotation = Float64List(16)
          ..[0] = cos
          ..[1] = sin
          ..[4] = -sin
          ..[5] = cos
          ..[10] = 1
          ..[12] = x0 - cos * x0 + sin * y0
          ..[13] = y0 - sin * x0 - cos * y0
          ..[15] = 1;
        return ui.Gradient.sweep(
          ui.Offset(x0, y0),
          colors,
          stops,
          ui.TileMode.clamp,
          0,
          2 * math.pi,
          matrix == null ? rotation : _multiply(matrix, rotation),
        );
    }
  }
}

/// The product of two column-major 4 x 4 matrices that hold 2D affine
/// transforms.
Float64List _multiply(Float64List m, Float64List n) {
  final a = m[0] * n[0] + m[4] * n[1];
  final b = m[1] * n[0] + m[5] * n[1];
  final c = m[0] * n[4] + m[4] * n[5];
  final d = m[1] * n[4] + m[5] * n[5];
  final e = m[0] * n[12] + m[4] * n[13] + m[12];
  final f = m[1] * n[12] + m[5] * n[13] + m[13];
  return Float64List(16)
    ..[0] = a
    ..[1] = b
    ..[4] = c
    ..[5] = d
    ..[10] = 1
    ..[12] = e
    ..[13] = f
    ..[15] = 1;
}

final Float64List _identityMatrix = Float64List(16)
  ..[0] = 1
  ..[5] = 1
  ..[10] = 1
  ..[15] = 1;

/// The `dart:ui` [CanvasPattern]: an image repeated in user space.
final class UiCanvasPattern extends UiShaderSource implements CanvasPattern {
  /// `createPattern(image, repetition)`. [repetition] is `'repeat'`,
  /// `'repeat-x'`, `'repeat-y'` or `'no-repeat'`. Another value throws a
  /// [FormatException] (the DOM `SyntaxError`).
  UiCanvasPattern(this.image, String repetition)
    : repeatX = repetition == 'repeat' || repetition == 'repeat-x',
      repeatY = repetition == 'repeat' || repetition == 'repeat-y' {
    if (!const {
      'repeat',
      'repeat-x',
      'repeat-y',
      'no-repeat',
    }.contains(repetition)) {
      throw FormatException('Unknown repetition', repetition);
    }
  }

  /// The image.
  final ui.Image image;

  /// The pattern repeats along x.
  final bool repeatX;

  /// The pattern repeats along y.
  final bool repeatY;

  @override
  ui.Shader? _build(Float64List? matrix) => ui.ImageShader(
    image,
    repeatX ? ui.TileMode.repeated : ui.TileMode.decal,
    repeatY ? ui.TileMode.repeated : ui.TileMode.decal,
    matrix ?? _identityMatrix,
    filterQuality: ui.FilterQuality.low,
  );
}

/// [source] cut into the dashes of [dash] (an even-length list), with the
/// lengths and [offset] multiplied by [scale]. The pattern restarts at each
/// subpath, as in the DOM. A pattern with no length gives [source].
///
/// A dash of length 0 is a cap only. With [caps] (a `round` or `square`
/// line cap), it is a line of 0.001 units in the direction of the path,
/// so that the stroke draws its caps, as Chromium does: `[0, n]` with
/// round caps is a dotted line. Without caps, it draws nothing.
ui.Path dashPath(
  ui.Path source,
  List<double> dash,
  double scale,
  double offset, {
  bool caps = false,
}) {
  var total = 0.0;
  for (final length in dash) {
    total += length;
  }
  total *= scale;
  if (!(total > 0) || !total.isFinite) return source;
  final out = ui.Path();
  final n = dash.length;
  for (final metric in source.computeMetrics()) {
    var phase = (offset * scale) % total;
    var i = 0;
    // As Skia: the phase stops at a dash of length 0, which then draws
    // its caps at the start.
    while (phase > dash[i] * scale || (phase == dash[i] * scale && phase > 0)) {
      phase -= dash[i] * scale;
      i = (i + 1) % n;
    }
    var remaining = dash[i] * scale - phase;
    var distance = 0.0;
    final length = metric.length;
    while (distance < length) {
      final end = math.min(distance + remaining, length);
      if (i.isEven) {
        if (end > distance) {
          out.addPath(metric.extractPath(distance, end), ui.Offset.zero);
        } else if (caps) {
          final tangent = metric.getTangentForOffset(distance);
          if (tangent != null) {
            final p = tangent.position;
            final v = tangent.vector;
            out
              ..moveTo(p.dx, p.dy)
              ..lineTo(p.dx + v.dx * 1e-3, p.dy + v.dy * 1e-3);
          }
        }
      }
      distance = end;
      i = (i + 1) % n;
      remaining = dash[i] * scale;
    }
  }
  return out;
}
