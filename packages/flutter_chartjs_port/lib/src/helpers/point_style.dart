// Original code, not ported from Chart.js: the base classes of point styles.

/// The value of the option `pointStyle` (row `adapt-point-style-objects`).
///
/// Upstream holds a style name (`'circle'`, `'cross'`, `'crossRot'`,
/// `'dash'`, `'line'`, `'rect'`, `'rectRounded'`, `'rectRot'`, `'star'`,
/// `'triangle'`), `false` or an image (`PointStyle` of index.d.ts:2040), and
/// `drawPointLegend` (helpers.canvas.ts:167) switches on it. In the port,
/// the option holds a `PointStyle` or `false`, also in a raw config: an
/// object with the method `draw`. The ten styles of upstream and the image
/// style are the classes of `helpers.canvas.dart`. An app or a plugin gives
/// its own style as a subclass, with no registration.
///
/// This library is a pure layer.
library;

import 'package:flutter_chartjs_port/src/canvas/canvas.dart'
    show CanvasRenderingContext2D;

/// The style of a point: the option `pointStyle`.
///
/// The parameters of [draw] are the values of `drawPointLegend`
/// (helpers.canvas.ts:167) after its first lines: the center (`x`, `y`),
/// the option `radius`, the option `rotation` in radians (`rad`, 0 for no
/// rotation) and whether that option is truthy (`rotated`), the width of
/// the style in the legend (`width`, Dart `null` when the style draws with
/// the radius alone) and the option `borderWidth`.
///
/// ```dart
/// final class DiamondPointStyle extends PathPointStyle {
///   const DiamondPointStyle();
///
///   @override
///   void addPath(
///     CanvasRenderingContext2D ctx, {
///     required double x,
///     required double y,
///     required double radius,
///     required double rad,
///     required bool rotated,
///     required double? width,
///   }) {
///     ctx
///       ..moveTo(x, y - radius)
///       ..lineTo(x + radius / 2, y)
///       ..lineTo(x, y + radius)
///       ..lineTo(x - radius / 2, y)
///       ..closePath();
///   }
/// }
/// ```
abstract class const PointStyle() {
  /// A style.
  this;

  /// Draws one point of this style on [ctx].
  void draw(
    CanvasRenderingContext2D ctx, {
    required double x,
    required double y,
    required double radius,
    required double rad,
    required bool rotated,
    required double? width,
    required double borderWidth,
  });

  /// The style of [value], the value of the option, or Dart `null` for a
  /// value that is not a [PointStyle] (`false` among them). A style name of
  /// Chart.js is not a style: a debug build stops on it.
  static PointStyle? of(Object? value) {
    assert(
      value is! String,
      'The option pointStyle takes a PointStyle, not the name "$value".',
    );
    return value is PointStyle ? value : null;
  }
}

/// A style that adds a path, which the context then fills and strokes: the
/// path branch of `drawPointLegend` (helpers.canvas.ts:188-292).
abstract class const PathPointStyle() extends PointStyle {
  /// A path style.
  this;

  /// Draws nothing for a radius that is NaN or not above 0
  /// (helpers.canvas.ts:188). Else begins a path, adds the path of the
  /// style ([addPath]), fills it, and strokes it when [borderWidth] is
  /// above 0.
  @override
  void draw(
    CanvasRenderingContext2D ctx, {
    required double x,
    required double y,
    required double radius,
    required double rad,
    required bool rotated,
    required double? width,
    required double borderWidth,
  }) {
    if (radius.isNaN || radius <= 0) return;
    ctx.beginPath();
    addPath(
      ctx,
      x: x,
      y: y,
      radius: radius,
      rad: rad,
      rotated: rotated,
      width: width,
    );
    ctx.fill();
    if (borderWidth > 0) ctx.stroke();
  }

  /// Adds the path of the style to the current path of [ctx]. The
  /// parameters are those of [draw].
  void addPath(
    CanvasRenderingContext2D ctx, {
    required double x,
    required double y,
    required double radius,
    required double rad,
    required bool rotated,
    required double? width,
  });
}
