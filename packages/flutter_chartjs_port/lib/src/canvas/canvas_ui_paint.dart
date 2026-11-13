// Original code, not ported from Chart.js: the dart:ui canvas styles.

/// The styles of the `dart:ui` canvas context (Chart.js ADR 0013,
/// porting-flow.md 2.2): native colors, gradients, patterns, images,
/// composite operations and line dashes.
///
/// - Solid paints and gradient stops require `ui.Color`. Strings throw;
///   there is no CSS color parser or color-string cache (ADR 0057).
/// - A `ChartGradient` builds its `ui.Gradient` when a draw uses it, with
///   the transform of that draw (the DOM rule: gradient coordinates are in
///   the user space of the draw). The shader is cached for the last matrix
///   by the identity of the gradient (Chart.js ADR 0128).
/// - A `ChartPattern` is a `ui.ImageShader` with its tile modes.
/// - A line dash cuts the path with `ui.PathMetric.extractPath`, the usual
///   Flutter recipe: `dart:ui` has no dash.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart';

/// CSS color parsing is unsupported. Supply a Flutter Color instead.
ui.Color? parseCssColor(String value) => throw ArgumentError.value(
  value,
  'color',
  'CSS color strings are unsupported; use Flutter Color',
);

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

/// Maps the pure canvas operation when its property is assigned.
ui.BlendMode blendModeOf(CanvasCompositeOperation operation) =>
    switch (operation) {
      CanvasCompositeOperation.sourceOver => ui.BlendMode.srcOver,
      CanvasCompositeOperation.sourceIn => ui.BlendMode.srcIn,
      CanvasCompositeOperation.sourceOut => ui.BlendMode.srcOut,
      CanvasCompositeOperation.sourceAtop => ui.BlendMode.srcATop,
      CanvasCompositeOperation.destinationOver => ui.BlendMode.dstOver,
      CanvasCompositeOperation.destinationIn => ui.BlendMode.dstIn,
      CanvasCompositeOperation.destinationOut => ui.BlendMode.dstOut,
      CanvasCompositeOperation.destinationAtop => ui.BlendMode.dstATop,
      CanvasCompositeOperation.lighter => ui.BlendMode.plus,
      CanvasCompositeOperation.copy => ui.BlendMode.src,
      CanvasCompositeOperation.xor => ui.BlendMode.xor,
      CanvasCompositeOperation.multiply => ui.BlendMode.multiply,
      CanvasCompositeOperation.screen => ui.BlendMode.screen,
      CanvasCompositeOperation.overlay => ui.BlendMode.overlay,
      CanvasCompositeOperation.darken => ui.BlendMode.darken,
      CanvasCompositeOperation.lighten => ui.BlendMode.lighten,
      CanvasCompositeOperation.colorDodge => ui.BlendMode.colorDodge,
      CanvasCompositeOperation.colorBurn => ui.BlendMode.colorBurn,
      CanvasCompositeOperation.hardLight => ui.BlendMode.hardLight,
      CanvasCompositeOperation.softLight => ui.BlendMode.softLight,
      CanvasCompositeOperation.difference => ui.BlendMode.difference,
      CanvasCompositeOperation.exclusion => ui.BlendMode.exclusion,
      CanvasCompositeOperation.hue => ui.BlendMode.hue,
      CanvasCompositeOperation.saturation => ui.BlendMode.saturation,
      CanvasCompositeOperation.color => ui.BlendMode.color,
      CanvasCompositeOperation.luminosity => ui.BlendMode.luminosity,
    };

/// Reads the public operation from the canvas's native blend state.
CanvasCompositeOperation compositeOperationOf(ui.BlendMode mode) =>
    switch (mode) {
      ui.BlendMode.srcOver => CanvasCompositeOperation.sourceOver,
      ui.BlendMode.srcIn => CanvasCompositeOperation.sourceIn,
      ui.BlendMode.srcOut => CanvasCompositeOperation.sourceOut,
      ui.BlendMode.srcATop => CanvasCompositeOperation.sourceAtop,
      ui.BlendMode.dstOver => CanvasCompositeOperation.destinationOver,
      ui.BlendMode.dstIn => CanvasCompositeOperation.destinationIn,
      ui.BlendMode.dstOut => CanvasCompositeOperation.destinationOut,
      ui.BlendMode.dstATop => CanvasCompositeOperation.destinationAtop,
      ui.BlendMode.plus => CanvasCompositeOperation.lighter,
      ui.BlendMode.src => CanvasCompositeOperation.copy,
      ui.BlendMode.xor => CanvasCompositeOperation.xor,
      ui.BlendMode.multiply => CanvasCompositeOperation.multiply,
      ui.BlendMode.screen => CanvasCompositeOperation.screen,
      ui.BlendMode.overlay => CanvasCompositeOperation.overlay,
      ui.BlendMode.darken => CanvasCompositeOperation.darken,
      ui.BlendMode.lighten => CanvasCompositeOperation.lighten,
      ui.BlendMode.colorDodge => CanvasCompositeOperation.colorDodge,
      ui.BlendMode.colorBurn => CanvasCompositeOperation.colorBurn,
      ui.BlendMode.hardLight => CanvasCompositeOperation.hardLight,
      ui.BlendMode.softLight => CanvasCompositeOperation.softLight,
      ui.BlendMode.difference => CanvasCompositeOperation.difference,
      ui.BlendMode.exclusion => CanvasCompositeOperation.exclusion,
      ui.BlendMode.hue => CanvasCompositeOperation.hue,
      ui.BlendMode.saturation => CanvasCompositeOperation.saturation,
      ui.BlendMode.color => CanvasCompositeOperation.color,
      ui.BlendMode.luminosity => CanvasCompositeOperation.luminosity,
      _ => throw ArgumentError.value(mode, 'mode', 'Not a Canvas 2D operation'),
    };

/// A [CanvasImageSource] that wraps a `ui.Image`, for
/// [CanvasRenderingContext2D.drawImage].
final class UiImageSource(
  /// The image.
  final ui.Image image,
) implements CanvasImageSource {
  /// Wraps [image]. Its size in CSS pixels is its size in pixels.
  this;

  @override
  double get width => image.width.toDouble();

  @override
  double get height => image.height.toDouble();
}

/// The last shader of a [ChartShaderPaint], with the matrix of its draw.
final class _ShaderCache() {
  Float64List? matrix;
  ui.Shader? shader;
  List<ui.Color>? colors;
  List<double>? stops;
}

/// The cache of each paint, including snapshots of its gradient lists.
final Expando<_ShaderCache> _shaderCaches = Expando('ChartShaderPaint');

/// The shader of [source] for a draw whose local space maps to the user
/// space of the style through [matrix] (a column-major 4 x 4 matrix, `null`
/// for the identity). `null` when the style paints nothing.
///
/// A `stops` list of another length than the colors, and a negative radius
/// of a radial gradient, throw.
ui.Shader? shaderFor(ChartShaderPaint source, Float64List? matrix) {
  final cache = _shaderCaches[source];
  if (cache != null && _sameMatrix(cache.matrix, matrix)) {
    if (source is! ChartGradient ||
        (_sameItems(cache.colors, source.colors) &&
            _sameItems(cache.stops, source.stops))) {
      return cache.shader;
    }
  }
  // Publish only after a successful build: a rejected paint must keep
  // throwing on later draws instead of caching a null shader.
  final shader = switch (source) {
    final ChartGradient gradient => _gradientShader(gradient, matrix),
    final ChartPattern pattern => ui.ImageShader(
      pattern.image,
      pattern.tileModeX,
      pattern.tileModeY,
      matrix ?? _identityMatrix,
      filterQuality: ui.FilterQuality.low,
    ),
  };
  _shaderCaches[source] = _ShaderCache()
    ..matrix = matrix == null ? null : Float64List.fromList(matrix)
    ..shader = shader
    ..colors = source is ChartGradient ? List.of(source.colors) : null
    ..stops = source is ChartGradient && source.stops != null
        ? List.of(source.stops!)
        : null;
  return shader;
}

bool _sameItems<T>(List<T>? a, List<T>? b) {
  if (a == null || b == null) return a == null && b == null;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _sameMatrix(Float64List? a, Float64List? b) {
  if (a == null || b == null) return a == null && b == null;
  // A 2D affine matrix: the other entries are fixed.
  return a[0] == b[0] &&
      a[1] == b[1] &&
      a[4] == b[4] &&
      a[5] == b[5] &&
      a[12] == b[12] &&
      a[13] == b[13];
}

/// The offsets of [count] colors with equal distances.
List<double> _evenStops(int count) => [
  for (var i = 0; i < count; i++) i / (count - 1),
];

ui.Shader? _gradientShader(ChartGradient gradient, Float64List? matrix) {
  var colors = gradient.colors;
  var stops = gradient.stops;
  if (stops != null && stops.length != colors.length) {
    throw ArgumentError.value(
      stops,
      'stops',
      'Expected one offset for each of the ${colors.length} colors',
    );
  }
  if (stops != null) {
    var previous = 0.0;
    for (final stop in stops) {
      if (!stop.isFinite || stop < previous || stop > 1) {
        throw ArgumentError.value(
          stops,
          'stops',
          'Expected ascending offsets in [0, 1]',
        );
      }
      previous = stop;
    }
  }
  if (gradient case RadialChartGradient(:final radius, :final focalRadius)) {
    if (!radius.isFinite ||
        !focalRadius.isFinite ||
        radius < 0 ||
        focalRadius < 0) {
      throw RangeError('The radius must be finite and non-negative');
    }
  }
  if (colors.isEmpty) return null;
  if (colors.length == 1) {
    colors = [colors[0], colors[0]];
    stops = const [0, 1];
  }
  stops ??= _evenStops(colors.length);
  switch (gradient) {
    case LinearChartGradient(:final from, :final to):
      if (from == to) return null;
      return ui.Gradient.linear(
        from,
        to,
        colors,
        stops,
        ui.TileMode.clamp,
        matrix,
      );
    case RadialChartGradient(:final center, :final radius, :final focalRadius):
      final focal = gradient.focal ?? center;
      if (radius < 0 || focalRadius < 0) {
        throw RangeError('The radius is negative');
      }
      if (focal == center && focalRadius == radius) return null;
      // The engine rejects a conical gradient with both centers at the
      // origin: draw it shifted, with a matrix that shifts it back.
      var shift = 0.0;
      if (focal == ui.Offset.zero &&
          center == ui.Offset.zero &&
          focalRadius != 0) {
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
        center.translate(shift, shift),
        radius,
        colors,
        stops,
        ui.TileMode.clamp,
        m,
        focal.translate(shift, shift),
        focalRadius,
      );
    case SweepChartGradient(:final center, :final startAngle):
      // The angle 0 of a sweep gradient is the positive x axis. The start
      // angle rotates it around the center.
      final cos = math.cos(startAngle);
      final sin = math.sin(startAngle);
      final x0 = center.dx;
      final y0 = center.dy;
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
        center,
        colors,
        stops,
        ui.TileMode.clamp,
        0,
        2 * math.pi,
        matrix == null ? rotation : _multiply(matrix, rotation),
      );
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
