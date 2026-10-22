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
library;

import 'dart:collection';
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

/// The bound of the sprite cache.
const int _spriteCacheSize = 32;

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

/// A run of full-circle fills and strokes with one radius, one fill color,
/// and one stroke color and width, in bitmap space.
final class CircleBatch {
  double _radius = 0;
  ui.Color? _fill;
  ui.Color? _stroke;
  double _width = 0;

  // For each instance: x, y (the center) and the kind (0 fill, 1 stroke).
  Float64List _xs = Float64List(256);
  Float64List _ys = Float64List(256);
  Uint8List _kinds = Uint8List(256);

  // The transforms and the rects of one atlas call.
  final Float32List _transforms = Float32List(maxAtlasInstances * 4);
  final Float32List _rects = Float32List(maxAtlasInstances * 4);

  final ui.Paint _fillPaint = ui.Paint();
  final ui.Paint _strokePaint = ui.Paint()..style = ui.PaintingStyle.stroke;
  // Bilinear: exact at a whole device pixel, see the library comment.
  final ui.Paint _atlasPaint = ui.Paint()..filterQuality = ui.FilterQuality.low;

  /// The count of fills and strokes in the run.
  int length = 0;

  /// Whether the run takes a fill ([stroke] false) or a stroke of a circle
  /// with [radius] in [color] (and the stroke [width]).
  bool accepts(
    double radius,
    ui.Color color, {
    required bool stroke,
    double width = 0,
  }) {
    if (length == 0) return true;
    if (radius != _radius) return false;
    if (stroke) {
      final current = _stroke;
      return current == null ||
          (_width == width && (identical(current, color) || current == color));
    }
    final current = _fill;
    return current == null || identical(current, color) || current == color;
  }

  /// Adds a fill or a stroke. The run must accept it (see [accepts]).
  void add(
    double x,
    double y,
    double radius,
    ui.Color color, {
    required bool stroke,
    double width = 0,
  }) {
    if (length == 0) {
      _radius = radius;
      _fill = null;
      _stroke = null;
    }
    if (stroke) {
      _stroke = color;
      _width = width;
    } else {
      _fill = color;
    }
    if (length == _xs.length) _grow();
    _xs[length] = x;
    _ys[length] = y;
    _kinds[length] = stroke ? 1 : 0;
    length++;
  }

  void _grow() {
    final size = _xs.length * 2;
    _xs = Float64List(size)..setRange(0, length, _xs);
    _ys = Float64List(size)..setRange(0, length, _ys);
    _kinds = Uint8List(size)..setRange(0, length, _kinds);
  }

  /// Empties the run without a draw.
  void clear() {
    length = 0;
  }

  /// Draws the run on [canvas], in order, and empties it.
  void flush(ui.Canvas canvas) {
    final n = length;
    if (n == 0) return;
    length = 0;
    if (n < minAtlasRun) {
      _drawDirect(canvas, n);
      return;
    }
    final fill = _fill?.toARGB32() ?? 0;
    final stroke = _stroke?.toARGB32() ?? 0;
    final width = _stroke == null ? 0.0 : _width;
    final cell = (2 * (_radius + width / 2) + 4).ceil();
    final image = _sprite((_radius, fill, stroke, width), cell);
    final center = (cell ~/ 2).toDouble();
    final size = cell.toDouble();
    const steps = subpixelSteps * 1.0;
    final transforms = _transforms;
    final rects = _rects;
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
      j += 4;
      if (j == transforms.length || i == n - 1) {
        final full = j == transforms.length;
        canvas.drawRawAtlas(
          image,
          full ? transforms : Float32List.sublistView(transforms, 0, j),
          full ? rects : Float32List.sublistView(rects, 0, j),
          null,
          null,
          null,
          _atlasPaint,
        );
        j = 0;
      }
    }
  }

  void _drawDirect(ui.Canvas canvas, int n) {
    final fill = _fill;
    if (fill != null) _fillPaint.color = fill;
    final stroke = _stroke;
    if (stroke != null) {
      _strokePaint
        ..color = stroke
        ..strokeWidth = _width;
    }
    for (var i = 0; i < n; i++) {
      canvas.drawCircle(
        ui.Offset(_xs[i], _ys[i]),
        _radius,
        _kinds[i] == 0 ? _fillPaint : _strokePaint,
      );
    }
  }
}
