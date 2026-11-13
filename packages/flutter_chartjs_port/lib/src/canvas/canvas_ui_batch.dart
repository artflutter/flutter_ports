// Original code, not ported from Chart.js: batched circles of the canvas.

/// The circle batch of the `dart:ui` canvas context (Chart.js ADR 0013).
///
/// A chart draws most points as one full circle with a fill and a stroke
/// (`drawPointLegend`, helpers.canvas.ts:200-207, then :303-306). Each fill
/// and each stroke is one native `drawCircle` call, and the native
/// recording of these calls is the largest cost of a frame with many
/// points. [CircleBatch] keeps a run of such fills and strokes and draws it
/// with one `drawRawAtlas` call. The atlas image holds the filled circle
/// and the stroked circle, each at [subpixelSteps] x [subpixelSteps]
/// offsets inside its pixel. Each instance selects the sprite of its kind
/// and offset, and draws it at a whole pixel of the bitmap. The instances
/// keep their order: fill 1, stroke 1, fill 2, ... The
/// result is the result of the separate draws, because `srcOver` is
/// associative. Only the position differs, by at most half a step
/// (1 / 8 pixel), a display-only difference (Chart.js ADR 0034).
///
/// The atlas samples bilinearly. Where a whole bitmap pixel is a whole
/// device pixel, each sample is one texel, so no sprite is resampled. A
/// host at a fractional device pixel, or under a scale, resamples the
/// sprites and keeps the centers in place, as it does for the vector
/// content of the bitmap.
///
/// A run of fewer than [minAtlasRun] circles that meets a fill or a stroke
/// of another color goes on with a color for each instance
/// (canvas-cuts-plan.md §7, N5): points with a scriptable color, for
/// example. Such a run draws white sprites, and `drawRawAtlas` multiplies
/// each one by the color of its instance (`BlendMode.modulate`): white
/// times a color is that color. A run of one color keeps its colored
/// sprites.
///
/// A run of fills may also change its radius (Chart.js ADR 0097): bubbles.
/// Such a run keeps a radius for each instance. Fewer than [minLadderRun]
/// fills draw with `drawCircle`, each in its exact color. A longer run draws
/// with [_FillLadder], one atlas of masters for a ladder of radii. The
/// transform of each instance scales its master to the exact radius, at the
/// exact center.
///
/// A run of point markers (Chart.js ADR 0104) has one radius, one width and
/// the same colors for each circle. Once [CircleBatch.accepts] has taken a
/// circle of the run, [CircleBatch.hold] keeps the run, and
/// [CircleBatch.addHeld] adds each further circle with no test:
/// [CircleBatch.accepts] would take each one, and [CircleBatch.add] would
/// change only the instances. Any other add, a flush and the start of
/// another run end the held run.
///
/// The batch reads a color as 32 bits of sRGB, in `toARGB32`. A color that
/// these bits do not keep draws directly (see [batchKeepsColor]).
library;

import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// The largest outer radius, in bitmap pixels, that a batch accepts: the
/// radius plus half the line width of a stroke. A larger circle (a bubble,
/// or a wide border) draws directly: its sprite would be large, and a
/// chart draws few of them.
const double maxBatchRadius = 48;

/// The largest coordinate of a center, in bitmap pixels, that a batch
/// accepts. The atlas transforms are float32, whole pixels up to 2^24. A
/// center farther out cannot reach a bitmap, and draws directly.
const double maxBatchCenter = 8388608; // 2^23

/// The smallest run that draws with the atlas. A shorter run draws each
/// circle with `drawCircle`, so that a few circles cost no sprite.
const int minAtlasRun = 16;

/// The sub-pixel offsets of a sprite in each direction.
const int subpixelSteps = 4;

/// The most instances of one `drawRawAtlas` call. A longer run draws with
/// several calls, in order. Skwasm (dart2wasm) copies the transforms and
/// the rects of a call to the stack of its WebAssembly module, 32 bytes for
/// each instance. A call of 10000 instances (5000 points) overflowed that
/// stack and corrupted the heap of the renderer. 512 instances take 16 KB.
const int maxAtlasInstances = 512;

/// The smallest run of fills with varying radii that draws with the atlas. A
/// shorter run draws each circle with `drawCircle`: a few bubbles keep their
/// exact pixels and cost no atlas.
const int minLadderRun = 64;

/// The smallest radius, in bitmap pixels, of a fill that changes the radius
/// of its run. The edge ramp of a master is one bitmap pixel wide at each
/// radius, so its area is pi * (r * r + 1 / 12). A smaller circle would gain
/// more than 2 % of ink, and draws in the runs of one radius.
const double minLadderRadius = 2;

/// The bound of the sprite cache.
const int _spriteCacheSize = 32;

/// The ratio of two radii of the ladder. A master scales by about half of
/// this step, so its edge ramp stays about one bitmap pixel wide.
const double _ladderStep = 1.1;

/// The master pixels for each bitmap pixel. An edge ramp of one bitmap pixel
/// has two master pixels: bilinear sampling then keeps the ramp within 1 / 8
/// of the coverage.
const int _ladderResolution = 2;

/// The entries for each bitmap pixel of the radius in [_FillLadder._table].
const int _ladderTableScale = 8;

/// One atlas of filled discs for a fixed ladder of radii, white with an alpha
/// of the coverage of each pixel.
///
/// A master has no anti-aliased edge of the rasterizer. A radial gradient
/// paints its coverage: a ramp of one bitmap pixel across the radius. A
/// rasterized edge has half that width in a master of twice the resolution,
/// and a scaled copy of it would be too sharp.
final class _FillLadder._(
  /// The atlas image.
  final ui.Image image,
  final Uint8List _table,
  final Float32List _scales,
  final Float32List _tops,
  final Float32List _cells,
  final Float32List _centers,
) {
  factory _build() {
    final radii = <double>[];
    for (var r = minLadderRadius; ; r *= _ladderStep) {
      radii.add(r);
      if (r >= maxBatchRadius) break;
    }
    final n = radii.length;
    final scales = Float32List(n);
    final tops = Float32List(n);
    final cells = Float32List(n);
    final centers = Float32List(n);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint();
    const on = ui.Color(0xFFFFFFFF);
    const off = ui.Color(0x00FFFFFF);
    var top = 0.0;
    var width = 0.0;
    for (var i = 0; i < n; i++) {
      final radius = radii[i] * _ladderResolution;
      // The half of the ramp of one bitmap pixel, in master pixels.
      const half = _ladderResolution / 2;
      final outer = radius + half;
      final cell = (2 * outer + 4).ceilToDouble();
      final center = (cell / 2).floorToDouble();
      final inner = math.max<double>(0, radius - half);
      paint.shader = ui.Gradient.radial(
        ui.Offset(center, top + center),
        outer,
        const [on, on, off],
        [0, inner / outer, 1],
      );
      canvas.drawRect(ui.Rect.fromLTWH(0, top, cell, cell), paint);
      scales[i] = 1 / radius;
      tops[i] = top;
      cells[i] = cell;
      centers[i] = center;
      top += cell;
      width = math.max(width, cell);
    }
    final picture = recorder.endRecording();
    final image = picture.toImageSync(width.ceil(), top.ceil());
    picture.dispose();
    // The rung with the nearest ratio for each radius of the table.
    final table = Uint8List(maxBatchRadius.ceil() * _ladderTableScale + 1);
    var rung = 0;
    for (var k = 0; k < table.length; k++) {
      final r = (k + 0.5) / _ladderTableScale;
      while (rung + 1 < n && radii[rung + 1] / r < r / radii[rung]) {
        rung++;
      }
      table[k] = rung;
    }
    return _FillLadder._(image, table, scales, tops, cells, centers);
  }

  // For each rung: 1 over its radius in master pixels, the top of its cell,
  // the side of its cell and its center in the cell.
}

_FillLadder? _fillLadder;

/// Whether a batch keeps [color]: it reads a color as 32 bits of sRGB. Another
/// color space would lose its color, and a channel that is not finite has no
/// such form. These colors draw directly, with their exact values.
bool batchKeepsColor(ui.Color color) =>
    color.colorSpace == ui.ColorSpace.sRGB &&
    (color.a + color.r + color.g + color.b).isFinite;

typedef _SpriteKey = (double radius, int fill, int stroke, double width);

final LinkedHashMap<_SpriteKey, ui.Image> _sprites = LinkedHashMap();

/// The atlas image of [key], of square cells of [cell] pixels. The cell in
/// column `kind * subpixelSteps + px` and row `py` holds the filled
/// (`kind` 0) or the stroked (`kind` 1) circle with its center at
/// (`cell ~/ 2 + px / subpixelSteps`, `cell ~/ 2 + py / subpixelSteps`)
/// inside the cell.
ui.Image _sprite(_SpriteKey key, int cell) {
  final hit = _sprites.remove(key);
  if (hit != null) {
    _sprites[key] = hit;
    return hit;
  }
  final (radius, fill, stroke, width) = key;
  final center = (cell ~/ 2).toDouble();
  final fillPaint = ui.Paint()..color = ui.Color(fill);
  final strokePaint = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = width
    ..color = ui.Color(stroke);
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  for (var kind = 0; kind < 2; kind++) {
    for (var px = 0; px < subpixelSteps; px++) {
      for (var py = 0; py < subpixelSteps; py++) {
        canvas.drawCircle(
          ui.Offset(
            (kind * subpixelSteps + px) * cell + center + px / subpixelSteps,
            py * cell + center + py / subpixelSteps,
          ),
          radius,
          kind == 0 ? fillPaint : strokePaint,
        );
      }
    }
  }
  final picture = recorder.endRecording();
  final image = picture.toImageSync(
    2 * subpixelSteps * cell,
    subpixelSteps * cell,
  );
  picture.dispose();
  _sprites[key] = image;
  if (_sprites.length > _spriteCacheSize) {
    // A recorded picture keeps its own reference to the image.
    _sprites.remove(_sprites.keys.first)!.dispose();
  }
  return image;
}

/// A run of full-circle fills and strokes with one radius and one stroke
/// width, in bitmap space: with one fill color and one stroke color, or
/// with a color for each instance.
final class CircleBatch() {
  /// A new [CircleBatch].
  this;

  // The radius of a run of one radius, else the last radius of a run with a
  // radius for each instance ([_varying]).
  double _radius = 0;
  ui.Color? _fill;
  ui.Color? _stroke;
  double _width = 0;
  // The run has a color for each instance in [_colors].
  bool _colored = false;
  // The run has a radius for each instance in [_radii]. It has fills only.
  bool _varying = false;
  // The fills at the end of a varying run with its last radius.
  int _streak = 0;
  // A run of circles that [hold] took: see [addHeld]. [add], [flush] and
  // [clear] end it.
  bool _held = false;
  // The stroke color of the held run, or `null` for a run of fills only.
  ui.Color? _heldStroke;
  // The ARGB colors of the held run, for a run with a color for each
  // instance: the values of `toARGB32` that [add] stores.
  int _heldFillArgb = 0;
  int _heldStrokeArgb = 0;

  // For each instance: x, y (the center), the kind (0 fill, 1 stroke) and,
  // in a run with a color for each instance, the ARGB color.
  Float64List _xs = Float64List(256);
  Float64List _ys = Float64List(256);
  Uint8List _kinds = Uint8List(256);
  Int32List _colors = Int32List(256);
  Float64List _radii = Float64List(256);

  // The exact color of each of the first instances: a run with varying radii
  // that draws directly has at most this many.
  final List<ui.Color?> _exact = List<ui.Color?>.filled(minLadderRun, null);

  // The transforms, the rects and the colors of one atlas call.
  final Float32List _transforms = Float32List(maxAtlasInstances * 4);
  final Float32List _rects = Float32List(maxAtlasInstances * 4);
  final Int32List _atlasColors = Int32List(maxAtlasInstances);

  final ui.Paint _fillPaint = ui.Paint();
  final ui.Paint _strokePaint = ui.Paint()..style = ui.PaintingStyle.stroke;
  // Bilinear: exact at a whole device pixel, see the library comment.
  final ui.Paint _atlasPaint = ui.Paint()..filterQuality = ui.FilterQuality.low;

  /// The count of fills and strokes in the run.
  int length = 0;

  /// Whether the run takes a fill ([stroke] false) or a stroke of a circle
  /// with [radius] in [color] (and the stroke [width]). A run of fewer than
  /// [minAtlasRun] circles takes another color (see [add]).
  ///
  /// A run of fills takes another radius below [minAtlasRun] circles or once
  /// it has varying radii. A stroke ends a run with varying radii, and a run
  /// with a stroke keeps one radius: a scaled stroke differs too much from
  /// `drawCircle` (Chart.js ADR 0097). A run with varying radii ends after
  /// [minAtlasRun] fills of one radius: the next one takes the sprites of that
  /// radius.
  bool accepts(
    double radius,
    ui.Color color, {
    required bool stroke,
    double width = 0,
  }) {
    if (length == 0) return true;
    if (radius != _radius) {
      if (stroke ||
          _stroke != null ||
          radius < minLadderRadius ||
          _radius < minLadderRadius) {
        return false;
      }
      return _varying || length < minAtlasRun;
    }
    if (_varying) return !stroke && _streak < minAtlasRun;
    final current = stroke ? _stroke : _fill;
    if (current == null) return true;
    if (stroke && _width != width) return false;
    if (_colored || identical(current, color) || current == color) return true;
    return length < minAtlasRun;
  }

  /// The count of the circles that [flush] draws with `drawCircle`.
  int get directLength =>
      length < (_varying ? minLadderRun : minAtlasRun) ? length : 0;

  /// Adds a fill or a stroke. The run must accept it (see [accepts]). A
  /// color that is not the color of the run for its kind gives each
  /// instance of the run its color, and the run then takes any color.
  void add(
    double x,
    double y,
    double radius,
    ui.Color color, {
    required bool stroke,
    double width = 0,
  }) {
    _held = false;
    if (length == 0) {
      _radius = radius;
      _fill = null;
      _stroke = null;
      _colored = false;
      _varying = false;
    }
    if (radius != _radius) {
      if (!_varying) {
        _varying = true;
        _radii.fillRange(0, length, _radius);
      }
      _radius = radius;
      _streak = 1;
    } else if (_varying) {
      _streak++;
    }
    if (!_colored) {
      final current = stroke ? _stroke : _fill;
      if (current != null && !identical(current, color) && current != color) {
        _colorEach();
      }
    }
    if (stroke) {
      _stroke = color;
      _width = width;
    } else {
      _fill = color;
    }
    final n = length;
    _push(x, y, stroke ? 1 : 0, _colored ? color.toARGB32() : 0, color);
    if (_varying) _radii[n] = radius;
  }

  /// Whether a run of circles of [radius] holds: [accepts] gives true for
  /// each further fill in [fill] and, for a [stroke] color, each further
  /// stroke in [stroke] of [width], and [add] then changes no state of the run
  /// but its instances. The run holds while it has one radius and its last
  /// fill and stroke were these colors, and it has no varying radii. A held
  /// run takes [addHeld] until [add], [flush], [clear] or [release].
  ///
  /// The caller gives the radius, the colors and the width of the circles of
  /// its last [add] calls, which [accepts] took.
  bool hold(double radius, ui.Color fill, ui.Color? stroke, double width) {
    if (length == 0 ||
        _varying ||
        radius != _radius ||
        !identical(_fill, fill) ||
        (stroke != null && (!identical(_stroke, stroke) || _width != width))) {
      return false;
    }
    _held = true;
    _heldStroke = stroke;
    if (_colored) {
      _heldFillArgb = fill.toARGB32();
      _heldStrokeArgb = stroke == null ? 0 : stroke.toARGB32();
    }
    return true;
  }

  /// Whether the batch holds a run ([hold]).
  bool get holdsRun => _held;

  /// Ends the held run: the next circle takes [accepts] and [add].
  void release() {
    _held = false;
  }

  /// Adds the fill in [fill] and, for a [stroke] color, the stroke in
  /// [stroke] of one more circle of the held run at (x, y), as [accepts] and
  /// [add] would. Returns false, with no change, unless the batch holds a run
  /// of these identical colors ([hold]).
  bool addHeld(double x, double y, ui.Color fill, ui.Color? stroke) {
    if (!_held || !identical(fill, _fill) || !identical(stroke, _heldStroke)) {
      return false;
    }
    _push(x, y, 0, _heldFillArgb, fill);
    if (stroke != null) _push(x, y, 1, _heldStrokeArgb, stroke);
    return true;
  }

  /// Appends one instance: its center, its kind, its ARGB color (read only in
  /// a run with a color for each instance) and its exact color.
  void _push(double x, double y, int kind, int argb, ui.Color color) {
    final n = length;
    if (n == _xs.length) _grow();
    _xs[n] = x;
    _ys[n] = y;
    _kinds[n] = kind;
    if (_colored) _colors[n] = argb;
    if (n < minLadderRun) _exact[n] = color;
    length = n + 1;
  }

  /// Gives each instance of the run the fill or the stroke color of the run.
  void _colorEach() {
    _colored = true;
    final fill = _fill?.toARGB32() ?? 0;
    final stroke = _stroke?.toARGB32() ?? 0;
    for (var i = 0; i < length; i++) {
      _colors[i] = _kinds[i] == 0 ? fill : stroke;
    }
  }

  void _grow() {
    final size = _xs.length * 2;
    _xs = Float64List(size)..setRange(0, length, _xs);
    _ys = Float64List(size)..setRange(0, length, _ys);
    _kinds = Uint8List(size)..setRange(0, length, _kinds);
    _colors = Int32List(size)..setRange(0, length, _colors);
    _radii = Float64List(size)..setRange(0, length, _radii);
  }

  /// Empties the run without a draw.
  void clear() {
    _held = false;
    length = 0;
  }

  /// Draws the run on [canvas], in order, and empties it.
  void flush(ui.Canvas canvas) {
    _held = false;
    final n = length;
    if (n == 0) return;
    final direct = directLength;
    length = 0;
    if (direct > 0) {
      _drawDirect(canvas, n);
      return;
    }
    if (_varying) {
      _drawLadder(canvas, n);
      return;
    }
    // A run with a color for each instance has white sprites, and the atlas
    // multiplies them by the colors.
    final colored = _colored;
    const white = 0xFFFFFFFF;
    final fill = colored ? (_fill == null ? 0 : white) : _fill?.toARGB32() ?? 0;
    final stroke = colored
        ? (_stroke == null ? 0 : white)
        : _stroke?.toARGB32() ?? 0;
    final width = _stroke == null ? 0.0 : _width;
    final cell = (2 * (_radius + width / 2) + 4).ceil();
    final image = _sprite((_radius, fill, stroke, width), cell);
    final center = (cell ~/ 2).toDouble();
    final size = cell.toDouble();
    const steps = subpixelSteps * 1.0;
    final transforms = _transforms;
    final rects = _rects;
    final colors = _atlasColors;
    var j = 0;
    for (var i = 0; i < n; i++) {
      // The center in steps of 1 / subpixelSteps pixel: a whole pixel and
      // the offset inside it.
      final qx = (_xs[i] * steps).roundToDouble();
      final qy = (_ys[i] * steps).roundToDouble();
      final bx = (qx / steps).floorToDouble();
      final by = (qy / steps).floorToDouble();
      final left = (_kinds[i] * steps + (qx - bx * steps)) * size;
      final top = (qy - by * steps) * size;
      transforms
        ..[j] = 1
        ..[j + 1] = 0
        ..[j + 2] = bx - center
        ..[j + 3] = by - center;
      rects
        ..[j] = left
        ..[j + 1] = top
        ..[j + 2] = left + size
        ..[j + 3] = top + size;
      if (colored) colors[j >> 2] = _colors[i];
      j += 4;
      if (j == transforms.length || i == n - 1) {
        final full = j == transforms.length;
        canvas.drawRawAtlas(
          image,
          full ? transforms : Float32List.sublistView(transforms, 0, j),
          full ? rects : Float32List.sublistView(rects, 0, j),
          colored
              ? (full ? colors : Int32List.sublistView(colors, 0, j >> 2))
              : null,
          colored ? ui.BlendMode.modulate : null,
          null,
          _atlasPaint,
        );
        j = 0;
      }
    }
  }

  void _drawDirect(ui.Canvas canvas, int n) {
    final colored = _colored;
    final varying = _varying;
    final fill = _fill;
    if (fill != null) _fillPaint.color = fill;
    final stroke = _stroke;
    if (stroke != null) {
      _strokePaint
        ..color = stroke
        ..strokeWidth = _width;
    }
    for (var i = 0; i < n; i++) {
      final paint = _kinds[i] == 0 ? _fillPaint : _strokePaint;
      if (colored) paint.color = varying ? _exact[i]! : ui.Color(_colors[i]);
      canvas.drawCircle(
        ui.Offset(_xs[i], _ys[i]),
        varying ? _radii[i] : _radius,
        paint,
      );
    }
  }

  /// Draws a run of fills with varying radii, in order. Each instance takes
  /// the master with the nearest radius, and its transform scales the master
  /// to the exact radius at the exact center. The atlas multiplies the white
  /// masters by the colors.
  // DIVERGES(chartjs): adapt-circle-fill-ladder, one atlas for varying radii.
  void _drawLadder(ui.Canvas canvas, int n) {
    final ladder = _fillLadder ??= _FillLadder._build();
    final table = ladder._table;
    final scales = ladder._scales;
    final tops = ladder._tops;
    final cells = ladder._cells;
    final centers = ladder._centers;
    final image = ladder.image;
    final xs = _xs;
    final ys = _ys;
    final radii = _radii;
    final colored = _colored;
    final instanceColors = _colors;
    final constant = colored ? 0 : _fill!.toARGB32();
    final transforms = _transforms;
    final rects = _rects;
    final colors = _atlasColors;
    final tableEnd = table.length - 1;
    var j = 0;
    for (var i = 0; i < n; i++) {
      final radius = radii[i];
      final index = (radius * _ladderTableScale).toInt();
      final rung = table[index < tableEnd ? index : tableEnd];
      final scale = radius * scales[rung];
      final center = centers[rung];
      final top = tops[rung];
      final cell = cells[rung];
      transforms
        ..[j] = scale
        ..[j + 1] = 0
        ..[j + 2] = xs[i] - scale * center
        ..[j + 3] = ys[i] - scale * center;
      rects
        ..[j] = 0
        ..[j + 1] = top
        ..[j + 2] = cell
        ..[j + 3] = top + cell;
      colors[j >> 2] = colored ? instanceColors[i] : constant;
      j += 4;
      if (j == transforms.length || i == n - 1) {
        final full = j == transforms.length;
        canvas.drawRawAtlas(
          image,
          full ? transforms : Float32List.sublistView(transforms, 0, j),
          full ? rects : Float32List.sublistView(rects, 0, j),
          full ? colors : Int32List.sublistView(colors, 0, j >> 2),
          ui.BlendMode.modulate,
          null,
          _atlasPaint,
        );
        j = 0;
      }
    }
  }
}
