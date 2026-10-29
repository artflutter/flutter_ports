// Ported from Chart.js v4.6.1 src/helpers/helpers.dom.ts (MIT, Chart.js Contributors).

/// Port of `src/helpers/helpers.dom.ts`.
///
/// Upstream reads the DOM: the computed CSS of the canvas and of its parent
/// node, the parent node itself and the position of a DOM event. Flutter has
/// no DOM and no CSS (Chart.js ADR 0037, porting-flow.md 2.7):
/// - The canvas and its container have no margin, padding, border,
///   `max-width`, `max-height` or `box-sizing`. The Flutter layout above the
///   chart host (`Padding`, `ConstrainedBox`, `SizedBox`) applies them before
///   the host gets its constraints. Thus `parseMaxStyle` and
///   `getPositionedStyle` have no port, and [getMaximumSize] reads no style
///   (`platform-dom-no-css`, differences.md).
/// - The parent node of a canvas is the [CanvasContainer] that a chart host
///   gives through [CanvasNode] (`platform-dom-container`).
/// - [getRelativePosition] reads the position of a [NativeEvent], which is
///   already in the logical pixels of the chart
///   (`platform-relative-position`).
/// - The computed style of [getStyle] is the inline style of the canvas
///   (`platform-dom-computed-style`).
/// - [isDomSupported] is false (`platform-dom-supported`).
///
/// This file imports only pure layers. It is a pure-layer root
/// (`tool/src/lib_imports.dart`).
library;

import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart'
    show infinity;
import 'package:flutter_chartjs_port/src/js/js_math.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/platform/native_event.dart';
import 'package:flutter_chartjs_port/src/types/index.dart';

/// helpers.dom.ts:9 `_isDomSupported`.
/// @private
///
/// Upstream tests for the globals `window` and `document`. The port has no
/// DOM, so the result is `false`. Two upstream callers read it:
/// [supportsEventListenerOptions] runs no DOM test, and
/// `core.controller.js:52` looks up no element by id. `detectPlatform`
/// (platform/index.js:7) tests for a chart host instead (Chart.js ADR 0037).
bool isDomSupported() {
  // DIVERGES(chartjs): platform-dom-supported, Flutter has no DOM.
  return false;
}

/// helpers.dom.ts:16 `_getParentNode`.
/// @private
///
/// The parent node is the [CanvasContainer] of a canvas that implements
/// [CanvasNode]: the chart host that shows the canvas. Dart `null` is the JS
/// `null` of a canvas without a parent node.
CanvasContainer? getParentNode(HTMLCanvasElement domNode) {
  // DIVERGES(chartjs): platform-dom-container, the host is the parent node.
  // Flutter has no ShadowRoot, so the test of :18-20 has no port.
  return domNode is CanvasNode ? (domNode as CanvasNode).parentNode : null;
}

// helpers.dom.ts:29 `parseMaxStyle` has no port: Flutter has no `max-width`
// or `max-height` style (`platform-dom-no-css`).

/// helpers.dom.ts:45 `getComputedStyle`.
///
/// Flutter has no computed style. The style of the canvas is its inline
/// style, the [HTMLCanvasElement.style] that `retinaScale` writes.
CSSStyleDeclaration _getComputedStyle(HTMLCanvasElement element) =>
    // DIVERGES(chartjs): platform-dom-computed-style, the inline style.
    element.style;

/// helpers.dom.ts:48 `getStyle`.
///
/// [el] is an [HTMLCanvasElement], the only element of the port. The value
/// is the inline value of [property], `''` when it is not set
/// (`platform-dom-computed-style`, differences.md).
String getStyle(HTMLCanvasElement el, String property) {
  return _getComputedStyle(el).getPropertyValue(property);
}

// helpers.dom.ts:52-64 `positions` and `getPositionedStyle` have no port:
// Flutter has no margin, padding or border style (`platform-dom-no-css`).

// helpers.dom.ts:65 `useOffsetPos` has no port: a NativeEvent always has
// its position in the logical pixels of the chart
// (`platform-relative-position`).

/// helpers.dom.ts:73 `getCanvasPosition`.
///
/// Upstream takes the position from `offsetX` and `offsetY` when
/// `useOffsetPos` allows it, else from `clientX` and `clientY` minus the
/// bounding rectangle of the canvas, and then sets `box`. A [NativeEvent]
/// and its [NativeEvent.touches] always have the position relative to the
/// chart, so the port has no fallback and no `box`. A `touchend` after the
/// last finger lifts has no touches and NaN offsets: the position is NaN, as
/// upstream gives `undefined - rect.left`.
({double x, double y}) _getCanvasPosition(NativeEvent e) {
  final touches = e.touches;
  // DIVERGES(chartjs): platform-relative-position, no clientX fallback.
  if (touches.isNotEmpty) {
    final source = touches[0];
    return (x: source.x, y: source.y);
  }
  return (x: e.offsetX, y: e.offsetY);
}

/// helpers.dom.ts:105 `getRelativePosition`.
///
/// Gets an event's x, y coordinates, relative to the chart area
/// @param event
/// @param chart
/// @returns x and y coordinates of the event
///
/// [event] is a [ChartEvent] or a [NativeEvent]. Upstream tests
/// `'native' in event`: every [ChartEvent] has `native`, so the port tests
/// the type. Upstream then returns the chart event itself, and the callers
/// read its `x` and `y`. The port returns a [Point] that reads the `x` and
/// `y` of the chart event. Any other object throws a `TypeError`.
///
/// For a [NativeEvent], the result keeps the `Math.round` of the
/// coordinates ([jsRound]). The canvas has no padding, border or
/// `box-sizing`, and the event position is in the logical pixels of the
/// chart. Thus the factor `/ width * canvas.width / currentDevicePixelRatio`
/// of :128-129 has no port. `retinaScale` gives the canvas
/// `floor(round1(width * dpr))` device pixels, so the factor is
/// `floor(round1(width * dpr)) / (width * dpr)`. For a fractional device
/// width the result can differ from upstream by 1 px
/// (`platform-relative-position`, differences.md).
Point getRelativePosition(Object event, Chart chart) {
  if (event is ChartEvent) {
    return _ChartEventPosition(event);
  }

  // DIVERGES(chartjs): platform-relative-position, no CSS, no scale factor.
  final (:x, :y) = _getCanvasPosition(event as NativeEvent);
  return _RelativePosition(jsRound(x), jsRound(y));
}

/// The chart event of helpers.dom.ts:110, as a [Point].
final class _ChartEventPosition implements Point {
  const _ChartEventPosition(this._event);

  final ChartEvent _event;

  @override
  double? get x => _event.x;

  @override
  double? get y => _event.y;
}

/// The object literal `{x, y}` of helpers.dom.ts:127-130.
final class _RelativePosition implements Point {
  const _RelativePosition(this.x, this.y);

  @override
  final double x;

  @override
  final double y;
}

/// helpers.dom.ts:133 `getContainerSize`.
///
/// The `Partial<Scale>` result is a record. `maxWidth` and `maxHeight` are
/// always [infinity]: the container has no `max-width` or `max-height` style
/// (`platform-dom-no-css`). A Dart `null` [bbWidth] or [bbHeight] is JS
/// `undefined`. Upstream names the parameters `width` and `height` and
/// reassigns them. The port assigns the locals `width` and `height`.
({double width, double height, double maxWidth, double maxHeight})
_getContainerSize(HTMLCanvasElement canvas, double? bbWidth, double? bbHeight) {
  var width = bbWidth;
  var height = bbHeight;
  if (width == null || height == null) {
    final container = getParentNode(canvas);
    if (container == null) {
      // DIVERGES(chartjs): platform-dom-container, no canvas clientWidth.
      // A canvas without a parent node is outside the document, where the
      // DOM gives 0 for `clientWidth` and `clientHeight`.
      width = 0;
      height = 0;
    } else {
      // DIVERGES(chartjs): platform-dom-container, the host content box.
      // The container has no border, padding, max-width or max-height
      // (`platform-dom-no-css`).
      width = container.contentWidth;
      height = container.contentHeight;
    }
  }
  return (
    width: width,
    height: height,
    maxWidth: infinity,
    maxHeight: infinity,
  );
}

/// helpers.dom.ts:160 `round1`.
double _round1(double v) => jsRound(v * 10) / 10;

/// helpers.dom.ts:163 `getMaximumSize`.
///
/// A Dart `null` [bbWidth], [bbHeight] or [aspectRatio] is JS `undefined`.
/// `_resize` passes `options.maintainAspectRatio && this.aspectRatio` as
/// [aspectRatio] (core.controller.js:280). Its falsy values are `null`, 0
/// and NaN.
///
/// The canvas has no margin, `max-width`, `max-height` or `box-sizing`
/// (`platform-dom-no-css`, differences.md). Thus the margins are 0, the max
/// sizes are [infinity], and the `content-box` branch of :176-181 does not
/// run.
({double width, double height}) getMaximumSize(
  HTMLCanvasElement canvas, [
  double? bbWidth,
  double? bbHeight,
  double? aspectRatio,
]) {
  // DIVERGES(chartjs): platform-dom-no-css, no margin, max size or box-sizing.
  final containerSize = _getContainerSize(canvas, bbWidth, bbHeight);
  var width = containerSize.width;
  var height = containerSize.height;

  width = jsMax(0, width);
  height = jsMax(0, jsTruthy(aspectRatio) ? width / aspectRatio! : height);
  width = _round1(jsMin(width, containerSize.maxWidth));
  height = _round1(jsMin(height, containerSize.maxHeight));
  if (jsTruthy(width) && !jsTruthy(height)) {
    // https://github.com/chartjs/Chart.js/issues/4659
    // If the canvas has width, but no height, default to aspectRatio of 2
    // (canvas default)
    height = _round1(width / 2);
  }

  final maintainHeight = bbWidth != null || bbHeight != null;

  if (maintainHeight &&
      jsTruthy(aspectRatio) &&
      jsTruthy(containerSize.height) &&
      height > containerSize.height) {
    height = containerSize.height;
    width = _round1((height * aspectRatio!).floorToDouble());
  }

  return (width: width, height: height);
}

/// The WebIDL conversion of a number to `unsigned long`, ECMAScript
/// `ToUint32`: the assignment `canvas.width = canvasWidth` converts with it.
/// It truncates a fraction, and NaN and the infinities give 0.
int _toUint32(double value) {
  if (!value.isFinite) return 0;
  const twoTo32 = 4294967296.0;
  var uint32 = value.truncateToDouble().remainder(twoTo32);
  if (uint32 < 0) uint32 += twoTo32;
  return uint32.toInt();
}

/// helpers.dom.ts:208 `retinaScale`.
///
/// @param chart
/// @param forceRatio
/// @param forceStyle
/// @returns True if the canvas context size or transformation has changed.
///
/// A Dart `null` [forceRatio] is JS `undefined`, the `options.devicePixelRatio`
/// that a chart does not set (core.controller.js:243). A falsy [forceRatio]
/// gives 1. Upstream returns `boolean | void`, and every path returns a
/// boolean.
///
/// [HTMLCanvasElement.style] is a [CSSStyleDeclaration], so the property
/// reads and writes of `canvas.style.height` and `canvas.style.width` call
/// `getPropertyValue` and `setProperty`. The template literal formats the
/// size with `Number::toString` ([jsNumberToString]): 400 gives `'400px'`.
/// The canvas width and height take the `Math.floor` of the device size
/// (:230-231). The test of :232-234 compares these integers, so a fractional
/// device size that does not change gives `false`. The assignment converts
/// the value with `ToUint32`, as the DOM attributes do: NaN and the
/// infinities give 0.
///
/// The `dart:ui` context paints its bitmap with
/// `scale(1 / devicePixelRatio)`, so the `setTransform` of the pixel ratio
/// gives the identity in logical pixels (Chart.js ADR 0013).
bool retinaScale(
  Chart chart,
  double? forceRatio, [
  // The upstream signature has a positional `forceStyle`.
  // ignore: avoid_positional_boolean_parameters
  bool? forceStyle,
]) {
  final pixelRatio = jsTruthy(forceRatio) ? forceRatio! : 1.0;
  final deviceHeight = _round1(chart.height * pixelRatio);
  final deviceWidth = _round1(chart.width * pixelRatio);

  chart
    ..height = _round1(chart.height)
    ..width = _round1(chart.width);

  final canvas = chart.canvas!;

  // If no style has been set on the canvas, the render size is used as
  // display size, making the chart visually bigger, so let's enforce it to
  // the "correct" values.
  // See https://github.com/chartjs/Chart.js/issues/3575
  // The test `canvas.style &&` has no port: every HTMLCanvasElement has a
  // style.
  final style = canvas.style;
  if ((forceStyle ?? false) ||
      (style.getPropertyValue('height').isEmpty &&
          style.getPropertyValue('width').isEmpty)) {
    style
      ..setProperty('height', '${jsNumberToString(chart.height)}px')
      ..setProperty('width', '${jsNumberToString(chart.width)}px');
  }

  final canvasHeight = deviceHeight.floorToDouble();
  final canvasWidth = deviceWidth.floorToDouble();
  if (chart.currentDevicePixelRatio != pixelRatio ||
      canvas.height.toDouble() != canvasHeight ||
      canvas.width.toDouble() != canvasWidth) {
    chart.currentDevicePixelRatio = pixelRatio;
    canvas
      ..height = _toUint32(canvasHeight)
      ..width = _toUint32(canvasWidth);
    chart.ctx!.setTransform(pixelRatio, 0, 0, pixelRatio, 0, 0);
    return true;
  }
  return false;
}

/// helpers.dom.ts:249 `supportsEventListenerOptions`.
/// Detects support for options object argument in addEventListener.
/// https://developer.mozilla.org/en-US/docs/Web/API/EventTarget/addEventListener#Safely_detecting_option_support
/// @private
///
/// Upstream runs the DOM test only when `_isDomSupported()` is true
/// (:259-262). [isDomSupported] is false, so the value is the start value
/// `false` (`platform-dom-supported`, differences.md). `platform.flutter`
/// has no listener options.
const bool supportsEventListenerOptions = false;

/// The pattern of helpers.dom.ts:284. Dart `\d` is `[0-9]`, as in
/// JavaScript without the `u` flag.
final RegExp _usedSizePattern = RegExp(r'^(\d+)(\.\d+)?px$');

/// helpers.dom.ts:279 `readUsedSize`.
///
/// The "used" size is the final value of a dimension property after all
/// calculations have been performed. This method uses the computed style of
/// `element` but returns undefined if the computed style is not expressed in
/// pixels. That can happen in some cases where `element` has a size relative
/// to its parent and this last one is not yet displayed, for example because
/// of `display: none` on a parent node.
/// @see https://developer.mozilla.org/en-US/docs/Web/CSS/used_value
/// @returns Size in pixels or undefined if unknown.
///
/// The style is the inline style of [element] ([getStyle],
/// `platform-dom-computed-style`). The result is the integer part of a
/// pixel value, as `+matches[1]` gives. Dart `null` is JS `undefined`.
double? readUsedSize(HTMLCanvasElement element, String property) {
  final value = getStyle(element, property);
  final matches = value.isEmpty ? null : _usedSizePattern.firstMatch(value);
  return matches != null ? double.parse(matches[1]!) : null;
}
