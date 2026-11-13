// Ported from chartjs-chart-sankey v0.19.1 src/labels.ts (MIT, Jukka Kurkela).

/// Port of `src/labels.ts`: the node-scoped options and the label of a node
/// or of a flow.
///
/// `isPatternOrGradient` (labels.ts:6) is the helper of the host with the
/// same name: a gradient or a pattern is a `ChartShaderPaint` there.
library;

import 'dart:math' as math;
import 'dart:ui' show TextAlign;

import 'package:flutter_chartjs_chart_sankey_port/src/lib/helpers.dart';
import 'package:flutter_chartjs_chart_sankey_port/src/types.dart';
import 'package:flutter_chartjs_port/chartjs.dart'
    show
        CanvasRenderingContext2D,
        CanvasTextBaseline,
        ChartTextStyle,
        JsObjectFace,
        Undefined;
import 'package:flutter_chartjs_port/js_semantics.dart' show jsGet;

/// labels.ts:13 `DrawLabelOptions`.
final class const DrawLabelOptions({
  /// The position of a label with the position `auto`.
  required final SankeyLabelPosition autoPosition,

  /// The radius of the corners of the background.
  required final double borderRadius,

  /// The border width of the node: the label of a node at its left or right
  /// side stays clear of it.
  required final double borderWidth,

  /// The fill of the text: a `ChartPaint` or a `Color`.
  required final Object? color,

  /// The font.
  required final ChartTextStyle font,

  /// The height of the node or of the flow.
  required final double height,

  /// The offset of the first line of a label of several lines.
  required final double lineOffset,

  /// The distance of the label from its node, and the padding of the
  /// background.
  required final double padding,

  /// The position of the label.
  required final SankeyLabelPosition position,

  /// The width of the node or of the flow.
  required final double width,

  /// The left side of the node or of the flow.
  required final double x,

  /// The top side of the node or of the flow.
  required final double y,

  /// The fill of the background, or Dart `null` for no background.
  final Object? backgroundColor,
}) {
  /// The options of one label.
  this;
}

/// labels.ts:29 `resolveNodeOption`: the value of the node-scoped option
/// [option] for [node].
///
/// - A [SankeyNodeCallback] gives its result for [node].
/// - A Map, or the view of a Map that the resolver of the host gives, gives
///   its value at the key of [node].
/// - Another value is the value for each node.
///
/// Dart `null` is the JavaScript `undefined`: the caller takes its default.
/// A value that is not a [T], also the `undefined` of an absent option,
/// gives Dart `null`. A function of another type is not a callback: a debug
/// build stops on it, and a release build gives Dart `null`.
// DIVERGES(sankey): adapt-sankey-node-option, a typed result.
T? resolveNodeOption<T extends Object>(Object? option, SankeyNode node) {
  final Object? value;
  if (option is Function) {
    assert(
      option is SankeyNodeCallback<T>,
      'A node option function is a SankeyNodeCallback<$T>, not '
      '${option.runtimeType}.',
    );
    value = option is SankeyNodeCallback<T> ? option(node) : null;
  } else if (option is Map || option is JsObjectFace) {
    // A Map of a raw config comes from the resolver of the host as a view
    // of the Map (a `Proxy` upstream).
    value = jsGet(option, node.key);
  } else {
    value = option;
  }
  return value is T && value is! Undefined ? value : null;
}

/// labels.ts:42 `addRoundedRectPath`.
void _addRoundedRectPath(
  CanvasRenderingContext2D ctx,
  double x,
  double y,
  double width,
  double height,
  double radius,
) {
  final r = math.max<double>(
    0,
    math.min(math.min(radius, width / 2), height / 2),
  );
  ctx
    ..beginPath()
    ..moveTo(x + r, y)
    ..lineTo(x + width - r, y)
    ..quadraticCurveTo(x + width, y, x + width, y + r)
    ..lineTo(x + width, y + height - r)
    ..quadraticCurveTo(x + width, y + height, x + width - r, y + height)
    ..lineTo(x + r, y + height)
    ..quadraticCurveTo(x, y + height, x, y + height - r)
    ..lineTo(x, y + r)
    ..quadraticCurveTo(x, y, x + r, y)
    ..closePath();
}

/// labels.ts:64 `resolvePosition`.
SankeyLabelPosition _resolvePosition(
  SankeyLabelPosition position,
  SankeyLabelPosition autoPosition,
) => position == SankeyLabelPosition.auto ? autoPosition : position;

/// labels.ts:71 `getTextPosition`.
({TextAlign align, double x, double y}) _getTextPosition(
  SankeyLabelPosition position,
  DrawLabelOptions options,
  double totalTextHeight,
) {
  final DrawLabelOptions(:borderWidth, :height, :padding, :width, :x, :y) =
      options;
  var align = TextAlign.center;
  var textX = x + width / 2;
  var textY = y + height / 2;
  if (position == SankeyLabelPosition.left) {
    align = TextAlign.right;
    textX = x - borderWidth - padding;
  } else if (position == SankeyLabelPosition.right) {
    align = TextAlign.left;
    textX = x + width + borderWidth + padding;
  } else if (position == SankeyLabelPosition.top) {
    textY = y - padding - totalTextHeight / 2;
  } else if (position == SankeyLabelPosition.bottom) {
    textY = y + height + padding + totalTextHeight / 2;
  }
  return (align: align, x: textX, y: textY);
}

/// labels.ts:96 `getBackgroundX`.
double _getBackgroundX(
  TextAlign textAlign,
  double textX,
  double textWidth,
  double backgroundWidth,
  double padding,
) {
  if (textAlign == TextAlign.left) return textX - padding;
  if (textAlign == TextAlign.right) return textX - textWidth - padding;
  return textX - backgroundWidth / 2;
}

/// labels.ts:108 `drawBackground`.
void _drawBackground(
  CanvasRenderingContext2D ctx,
  Object? color,
  double x,
  double y,
  double width,
  double height,
  double borderRadius,
) {
  ctx
    ..save()
    ..fillStyle = color;
  if (borderRadius > 0) {
    _addRoundedRectPath(ctx, x, y, width, height, borderRadius);
    ctx.fill();
  } else {
    ctx.fillRect(x, y, width, height);
  }
  ctx.restore();
}

/// labels.ts:128 `drawLabel`: draws the lines of [label] at the node or the
/// flow of [options].
///
/// [label] is a string, a number or a List of them (`toTextLines`).
void drawLabel(
  CanvasRenderingContext2D ctx,
  Object? label,
  DrawLabelOptions options,
) {
  final lines = toTextLines(label);
  if (lines.isEmpty) return;

  final DrawLabelOptions(
    :backgroundColor,
    :borderRadius,
    :color,
    :font,
    :lineOffset,
    :padding,
  ) = options;
  final position = _resolvePosition(options.position, options.autoPosition);
  final textHeight = font.lineHeight ?? double.nan;
  ctx.font = font;
  var textWidth = double.negativeInfinity;
  for (final line in lines) {
    textWidth = math.max(textWidth, ctx.measureText(line).width);
  }
  final totalTextHeight = textHeight * lines.length;
  final text = _getTextPosition(position, options, totalTextHeight);

  ctx
    ..textAlign = text.align
    ..textBaseline = CanvasTextBaseline.middle;

  final backgroundWidth = textWidth + padding * 2;
  final backgroundHeight = totalTextHeight + padding * 2;
  final backgroundX = _getBackgroundX(
    text.align,
    text.x,
    textWidth,
    backgroundWidth,
    padding,
  );
  final firstLineY = lines.length == 1
      ? text.y
      : text.y - totalTextHeight / 2 + lineOffset;
  final textCenterY = firstLineY + ((lines.length - 1) * textHeight) / 2;
  final backgroundY = textCenterY - backgroundHeight / 2;

  if (backgroundColor != null) {
    _drawBackground(
      ctx,
      backgroundColor,
      backgroundX,
      backgroundY,
      backgroundWidth,
      backgroundHeight,
      borderRadius,
    );
  }

  ctx.fillStyle = color;
  for (var i = 0; i < lines.length; i++) {
    ctx.fillText(lines[i], text.x, firstLineY + i * textHeight);
  }
}
