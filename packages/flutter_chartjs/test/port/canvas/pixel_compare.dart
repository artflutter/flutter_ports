// Original code, not ported from Chart.js: pixel comparisons of the tests.

/// Renders a `dart:ui` canvas context into RGBA bytes and compares two
/// renders, for the `@TestOn('vm')` tests that compare two forms of one
/// drawing (the fast paths of the canvas layer and the arc paths).
///
/// The web legs cannot compile this file. Only `@TestOn('vm')` tests import
/// it.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_chartjs/src/canvas/canvas_ui.dart';

/// The RGBA bytes of a render of [width] x [height] pixels.
final class Render {
  /// The bytes of [width] x [height] pixels.
  Render(this.bytes, this.width, this.height);

  /// The RGBA bytes, row by row.
  final Uint8List bytes;

  /// The width in pixels.
  final int width;

  /// The height in pixels.
  final int height;

  /// The alpha of the pixel (x, y).
  int alpha(int x, int y) => bytes[(y * width + x) * 4 + 3];

  /// The sum of the alpha values over 255: the inked area in pixels.
  double get ink {
    var sum = 0;
    for (var i = 3; i < bytes.length; i += 4) {
      sum += bytes[i];
    }
    return sum / 255;
  }
}

/// Draws [draw] on a new context of [width] x [height] pixels at a device
/// pixel ratio of 1, and gives the rendered bytes.
Future<Render> renderContext(
  void Function(UiCanvasContext ctx) draw, {
  int width = 160,
  int height = 160,
}) async {
  final ctx = UiCanvasElement(width: width, height: height).getContext2d();
  draw(ctx);
  final recorder = ui.PictureRecorder();
  ctx.paint(ui.Canvas(recorder), ui.Offset.zero);
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final data = await image.toByteData();
  image.dispose();
  picture.dispose();
  ctx.dispose();
  return Render(data!.buffer.asUint8List(), width, height);
}

/// The difference of two renders of one size.
final class PixelDiff {
  PixelDiff._(
    this.maxChannel,
    this.differing,
    this.solidDiffering,
    this.opaqueFlips,
    this.inkA,
    this.inkB,
  );

  /// The largest difference of one channel, 0 to 255.
  final int maxChannel;

  /// The count of pixels that differ.
  final int differing;

  /// The count of pixels that differ although each render has them fully
  /// opaque or fully transparent: a difference of area, not of
  /// anti-aliasing.
  final int solidDiffering;

  /// The count of pixels that one render has fully opaque and the other
  /// fully transparent. Unlike [solidDiffering], it ignores two fills of
  /// other colors that overlap on an edge, whose anti-aliasing can change
  /// the color of an opaque pixel.
  final int opaqueFlips;

  /// The inked area of the first render, in pixels.
  final double inkA;

  /// The inked area of the second render, in pixels.
  final double inkB;

  /// The relative difference of the inked areas.
  double get inkRatio =>
      inkA == inkB ? 0 : (inkA - inkB).abs() / math.max(inkA, inkB);

  @override
  String toString() =>
      'PixelDiff(max $maxChannel, $differing differing, $solidDiffering '
      'solid, $opaqueFlips flips, ink $inkA / $inkB)';
}

/// Compares [a] and [b], two renders of one size.
PixelDiff comparePixels(Render a, Render b) {
  assert(a.width == b.width && a.height == b.height, 'sizes differ');
  var maxChannel = 0;
  var differing = 0;
  var solid = 0;
  var flips = 0;
  for (var i = 0; i < a.bytes.length; i += 4) {
    var worst = 0;
    for (var c = 0; c < 4; c++) {
      worst = math.max(worst, (a.bytes[i + c] - b.bytes[i + c]).abs());
    }
    if (worst == 0) continue;
    differing++;
    maxChannel = math.max(maxChannel, worst);
    final alphaA = a.bytes[i + 3];
    final alphaB = b.bytes[i + 3];
    bool isSolid(int alpha) => alpha == 0 || alpha == 255;
    if (isSolid(alphaA) && isSolid(alphaB)) solid++;
    if ((alphaA - alphaB).abs() == 255) flips++;
  }
  return PixelDiff._(maxChannel, differing, solid, flips, a.ink, b.ink);
}
