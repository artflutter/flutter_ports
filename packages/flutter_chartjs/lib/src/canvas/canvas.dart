// Original code, not ported from Chart.js: the Canvas 2D interface.

/// The Canvas 2D interface of the canvas layer (porting-flow.md 2.2).
///
/// Upstream draws on the DOM `CanvasRenderingContext2D` (lib.dom.d.ts).
/// This library declares the part of that interface that Chart.js v4.5.1
/// and the mock context of chartjs-test-utils 0.4.0 use (`src/context.js`).
/// The member names and the argument order are the DOM names and order.
///
/// This library is a pure layer: it reaches neither `dart:ui` nor
/// `package:flutter`. `helpers.canvas` imports it. The `dart:ui`
/// implementation is `canvas_ui.dart`. The harness implements the interface
/// as `MockContext` (`package:chartjs_test_utils`).
///
/// Values:
/// - A number is a `double` (Chart.js ADR 0010).
/// - A style property reads as `null` only on a context that never set it.
///   The mock context starts with `null` values (`src/context.js:7-15`). The
///   `dart:ui` context starts with the DOM defaults.
/// - A setter ignores a value that the DOM ignores: a non-finite or negative
///   line width, an unknown keyword, a font that does not parse. Dart `null`
///   is such a value.
/// - A path method with a non-finite argument does nothing, as in the DOM.
library;

import 'package:flutter_chartjs/src/types/color.dart';

export 'package:flutter_chartjs/src/types/color.dart'
    show CanvasGradient, CanvasPattern;

/// lib.dom.d.ts `CanvasPath`: the path methods that
/// [CanvasRenderingContext2D] and [Path2D] share.
abstract interface class CanvasPath {
  /// `closePath()`.
  void closePath();

  /// `moveTo(x, y)`.
  void moveTo(double x, double y);

  /// `lineTo(x, y)`.
  void lineTo(double x, double y);

  /// `bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y)`.
  void bezierCurveTo(
    double cp1x,
    double cp1y,
    double cp2x,
    double cp2y,
    double x,
    double y,
  );

  /// `quadraticCurveTo(cpx, cpy, x, y)`.
  void quadraticCurveTo(double cpx, double cpy, double x, double y);

  /// `arc(x, y, radius, startAngle, endAngle, counterclockwise)`.
  ///
  /// A negative [radius] throws an `IndexSizeError` in the DOM. Here it
  /// throws a [RangeError].
  void arc(
    double x,
    double y,
    double radius,
    double startAngle,
    double endAngle, [
    // The DOM signature.
    // ignore: avoid_positional_boolean_parameters
    bool counterclockwise = false,
  ]);

  /// `arcTo(x1, y1, x2, y2, radius)`.
  void arcTo(double x1, double y1, double x2, double y2, double radius);

  /// `ellipse(x, y, radiusX, radiusY, rotation, startAngle, endAngle,
  /// counterclockwise)`.
  void ellipse(
    double x,
    double y,
    double radiusX,
    double radiusY,
    double rotation,
    double startAngle,
    double endAngle, [
    // The DOM signature.
    // ignore: avoid_positional_boolean_parameters
    bool counterclockwise = false,
  ]);

  /// `rect(x, y, w, h)`.
  void rect(double x, double y, double w, double h);

  /// `roundRect(x, y, w, h, radii)`: a closed subpath of the rectangle with
  /// rounded corners, then a new subpath at (x, y).
  ///
  /// [roundRectGeometry] gives the rectangle and the radii. [radii] is a
  /// number or a list of 1 to 4 numbers, and `null` is the DOM default 0. A
  /// negative radius or a list of another length throws a [RangeError], as
  /// in the DOM. The DOM `DOMPointInit` radius is not supported: another
  /// value throws an [ArgumentError].
  ///
  /// The port calls it in place of the arcs and lines of
  /// `addRoundedRectPath` (helpers.canvas.ts:498, differences.md
  /// `adapt-rounded-rect-path`).
  void roundRect(double x, double y, double w, double h, [Object? radii]);
}

/// The rectangle and the corner radii of `roundRect(x, y, w, h, radii)`.
///
/// `left`, `top`, `width` and `height` give the rectangle with a width and
/// a height of 0 or more. The four radii are those of the corners of that
/// rectangle, after the scale. The path goes clockwise (the HTML order) when
/// `clockwise` is true, else the other way. It starts at
/// (left + upperLeft, top).
typedef RoundRectGeometry = ({
  double left,
  double top,
  double width,
  double height,
  double upperLeft,
  double upperRight,
  double lowerRight,
  double lowerLeft,
  bool clockwise,
});

/// The steps 1 to 11 of the HTML `roundRect(x, y, w, h, radii)` algorithm
/// (https://html.spec.whatwg.org/multipage/canvas.html#dom-context-2d-roundrect),
/// or `null` when the call does nothing.
///
/// - A non-finite [x], [y], [w] or [h] gives `null` (step 1), before the
///   radii are examined.
/// - [radii] is a `num`, a `List` of 1 to 4 entries, or `null` (the DOM
///   default 0). A `null` entry is 0, as the DOM converts `null` to an empty
///   `DOMPointInit`. A list of another length throws a [RangeError]
///   (step 3). The entries are examined in order: a non-finite radius gives
///   `null` and a negative radius throws a [RangeError] (step 5). The DOM
///   `DOMPointInit` radius is not supported: another value throws an
///   [ArgumentError].
/// - One radius is all corners. Two radii are the upper-left and
///   lower-right corners, then the upper-right and lower-left corners. Three
///   radii are the upper-left corner, the upper-right and lower-left
///   corners, then the lower-right corner. Four radii are the upper-left,
///   upper-right, lower-right and lower-left corners (steps 7 to 10).
/// - A negative [w] or [h] flips the rectangle, as Chromium and Firefox do:
///   the HTML text has no such step, and with a negative width its scale is
///   negative. A negative [w] swaps the left and the right corners, a
///   negative [h] swaps the upper and the lower corners, and each flip
///   reverses the direction of the path.
/// - When the radii of one side add up to more than its length, all radii
///   scale by the smallest ratio of length to sum (step 11). A side whose
///   radii add up to 0 sets no ratio.
RoundRectGeometry? roundRectGeometry(
  double x,
  double y,
  double w,
  double h,
  Object? radii,
) {
  // Step 1.
  if (!x.isFinite || !y.isFinite || !w.isFinite || !h.isFinite) return null;
  // Steps 2 to 5.
  final count = radii is List ? radii.length : 1;
  if (count < 1 || count > 4) {
    throw RangeError.range(count, 1, 4, 'radii', 'The count of radii');
  }
  var r0 = 0.0;
  var r1 = 0.0;
  var r2 = 0.0;
  var r3 = 0.0;
  for (var i = 0; i < count; i++) {
    final value = radii is List ? radii[i] : radii;
    final radius = switch (value) {
      null => 0.0,
      final num n => n.toDouble(),
      _ => throw ArgumentError.value(
        value,
        'radii',
        'A radius is not a number (DOMPointInit is not supported)',
      ),
    };
    if (!radius.isFinite) return null;
    if (radius < 0) {
      throw RangeError.value(radius, 'radii', 'A radius is negative');
    }
    switch (i) {
      case 0:
        r0 = radius;
      case 1:
        r1 = radius;
      case 2:
        r2 = radius;
      default:
        r3 = radius;
    }
  }
  // Steps 6 to 10.
  var upperLeft = r0;
  var upperRight = count == 1 ? r0 : r1;
  var lowerRight = count < 3 ? r0 : r2;
  var lowerLeft = switch (count) {
    1 => r0,
    4 => r3,
    _ => r1,
  };
  // The flips of Chromium and Firefox.
  var left = x;
  var top = y;
  var width = w;
  var height = h;
  var clockwise = true;
  if (width < 0) {
    clockwise = false;
    left += width;
    width = -width;
    (upperLeft, upperRight) = (upperRight, upperLeft);
    (lowerLeft, lowerRight) = (lowerRight, lowerLeft);
  }
  if (height < 0) {
    clockwise = !clockwise;
    top += height;
    height = -height;
    (upperLeft, lowerLeft) = (lowerLeft, upperLeft);
    (upperRight, lowerRight) = (lowerRight, upperRight);
  }
  // Step 11.
  var scale = 1.0;
  scale = _limitScale(scale, width, upperLeft + upperRight);
  scale = _limitScale(scale, height, upperRight + lowerRight);
  scale = _limitScale(scale, width, lowerRight + lowerLeft);
  scale = _limitScale(scale, height, upperLeft + lowerLeft);
  if (scale < 1) {
    upperLeft *= scale;
    upperRight *= scale;
    lowerRight *= scale;
    lowerLeft *= scale;
  }
  return (
    left: left,
    top: top,
    width: width,
    height: height,
    upperLeft: upperLeft,
    upperRight: upperRight,
    lowerRight: lowerRight,
    lowerLeft: lowerLeft,
    clockwise: clockwise,
  );
}

/// The smaller of [scale] and [length] / [sum], for a [sum] above 0: the
/// ratio of step 11 of `roundRect`.
double _limitScale(double scale, double length, double sum) =>
    sum > 0 && length / sum < scale ? length / sum : scale;

/// lib.dom.d.ts `CanvasFillRule`: `'nonzero'` or `'evenodd'`.
///
/// Upstream passes the rule as a string (`element.bar.js:192`,
/// `element.arc.ts:37`, `filler.drawing.js:142`).
typedef CanvasFillRule = String;

/// lib.dom.d.ts `CanvasImageSource`: an image that
/// [CanvasRenderingContext2D.drawImage] and
/// [CanvasRenderingContext2D.createPattern] take.
///
/// The type is opaque, so this library stays free of `dart:ui`. The
/// `dart:ui` implementation wraps a `ui.Image`. A point style that is an
/// image (`drawPointLegend`, helpers.canvas.ts:181-191) reads [width] and
/// [height].
abstract interface class CanvasImageSource {
  /// The width in CSS pixels.
  double get width;

  /// The height in CSS pixels.
  double get height;
}

/// lib.dom.d.ts `TextMetrics`: the result of
/// [CanvasRenderingContext2D.measureText].
///
/// Upstream reads [width] (`_measureText`, helpers.canvas.ts:47) and the
/// four `actualBoundingBox*` values (`decorateText`, helpers.canvas.ts:391).
abstract interface class TextMetrics {
  /// `width`: the advance width of the text.
  double get width;

  /// `actualBoundingBoxLeft`: the distance from the alignment point to the
  /// left edge of the ink box, positive to the left.
  double get actualBoundingBoxLeft;

  /// `actualBoundingBoxRight`: the distance from the alignment point to the
  /// right edge of the ink box, positive to the right.
  double get actualBoundingBoxRight;

  /// `actualBoundingBoxAscent`: the distance from the baseline of
  /// `textBaseline` to the top of the ink box, positive up.
  double get actualBoundingBoxAscent;

  /// `actualBoundingBoxDescent`: the distance from the baseline of
  /// `textBaseline` to the bottom of the ink box, positive down.
  double get actualBoundingBoxDescent;
}

/// lib.dom.d.ts `CSSStyleDeclaration`: the part that `helpers.rtl`
/// (helpers.rtl.ts:56-73) uses on `canvas.style`.
///
/// The canvas layer reads the `direction` property of the canvas style when
/// [CanvasRenderingContext2D.direction] is `'inherit'`, as the DOM does.
abstract interface class CSSStyleDeclaration {
  /// `getPropertyValue(property)`. An unset property gives `''`.
  String getPropertyValue(String property);

  /// `getPropertyPriority(property)`: `'important'` or `''`.
  String getPropertyPriority(String property);

  /// `setProperty(property, value, priority)`. A `null` or empty [value]
  /// removes the property.
  ///
  /// As in the DOM, a [priority] other than `''`, `null` and `'important'`
  /// (ASCII case-insensitive) does nothing, and so does a [value] that does
  /// not parse for [property]. `restoreTextDirection` relies on it: its
  /// callers pass the direction String, so the call reads `'r'` and `'t'`
  /// (helpers.rtl.ts:72, `plugin.legend.js:437`).
  void setProperty(String property, String? value, [String? priority]);
}

/// lib.dom.d.ts `HTMLCanvasElement`: the part that the ported code reads
/// from `ctx.canvas` and from `chart.canvas`.
///
/// [width] and [height] are the render size in device pixels, the DOM
/// attributes `width` and `height`. The DOM converts an assigned number with
/// `ToUint32` (it truncates a fraction). A Dart caller that assigns a
/// fractional value calls `toInt()` first.
abstract interface class HTMLCanvasElement {
  /// `width`: the render width in device pixels. The DOM default is 300.
  abstract int width;

  /// `height`: the render height in device pixels. The DOM default is 150.
  abstract int height;

  /// `style`: the inline style of the canvas.
  CSSStyleDeclaration get style;

  /// `getContext(contextId)`: the one context of [contextId], or `null` for
  /// a context type that the canvas does not support. `clearCanvas` calls
  /// `canvas.getContext('2d')` (helpers.canvas.ts:139).
  CanvasRenderingContext2D? getContext(String contextId);
}

/// lib.dom.d.ts `Node.parentNode` of a canvas element, as `helpers.dom`
/// reads it. Port-only.
///
/// In the DOM, the parent of a chart canvas is its container element. A
/// Flutter canvas has a container only while a chart host shows it. A
/// canvas element that a host can show implements this interface, and the
/// host sets [parentNode]. `_getParentNode` (`helpers.dom.dart`) gives
/// `null` for a canvas element that does not implement it.
abstract interface class CanvasNode {
  /// `parentNode`: the container that shows the canvas. Dart `null` is the
  /// JS `null` of a canvas outside the document.
  CanvasContainer? get parentNode;
}

/// The container of a canvas element: the box that a chart host lays the
/// canvas out in. Port-only. [CanvasNode.parentNode] gives it.
///
/// It is the part of the DOM parent node that `helpers.dom.ts` and
/// `platform.dom.js` read. Flutter has no CSS, so the container has no
/// padding, border, `max-width` or `max-height`. The Flutter layout above
/// the host (`Padding`, `ConstrainedBox`, `SizedBox`) applies them before
/// the host gets its constraints.
abstract interface class CanvasContainer {
  /// The width of the content box of the container, in logical pixels:
  /// `rect.width - containerPadding.width - containerBorder.width` at
  /// helpers.dom.ts:146. A chart host gives the max width of its incoming
  /// constraints, `double.infinity` when they are unbounded.
  double get contentWidth;

  /// The height of the content box of the container, in logical pixels:
  /// `rect.height - containerPadding.height - containerBorder.height` at
  /// helpers.dom.ts:147. A chart host gives the max height of its incoming
  /// constraints, `double.infinity` when they are unbounded.
  double get contentHeight;

  /// `isConnected`: whether the container is in the document, the test of
  /// `isAttached` (platform.dom.js:386-387). A chart host gives whether its
  /// render object is attached and laid out.
  bool get isConnected;
}

/// lib.dom.d.ts `CanvasRenderingContext2D`: the part that Chart.js v4.5.1
/// and the mock context of chartjs-test-utils 0.4.0 use.
///
/// The 24 methods and 9 setters of the mock context (`src/context.js`)
/// are here, plus the members that upstream source calls and the mock
/// context lacks: [ellipse], [resetTransform], [drawImage], [scale],
/// [globalAlpha], [createLinearGradient], [createRadialGradient],
/// [createConicGradient], [createPattern] and [direction]. The port also
/// calls [roundRect], which upstream source does not call
/// (differences.md `adapt-rounded-rect-path`).
abstract interface class CanvasRenderingContext2D implements CanvasPath {
  /// `canvas`: the canvas element of this context.
  HTMLCanvasElement get canvas;

  // State.

  /// `save()`.
  void save();

  /// `restore()`. A restore without a matching [save] does nothing.
  void restore();

  // Transforms.

  /// `scale(x, y)`.
  void scale(double x, double y);

  /// `rotate(angle)`, in radians.
  void rotate(double angle);

  /// `translate(x, y)`.
  void translate(double x, double y);

  /// `transform(a, b, c, d, e, f)`.
  void transform(double a, double b, double c, double d, double e, double f);

  /// `setTransform(a, b, c, d, e, f)`.
  void setTransform(
    double a,
    double b,
    double c,
    double d,
    double e,
    double f,
  );

  /// `resetTransform()`.
  void resetTransform();

  // Compositing.

  /// `globalAlpha`: a value in [0, 1]. The DOM default is 1.
  abstract double? globalAlpha;

  /// `globalCompositeOperation`. The DOM default is `'source-over'`.
  abstract String? globalCompositeOperation;

  // Fill and stroke styles.

  /// `fillStyle`: a CSS color `String`, a [CanvasGradient] or a
  /// [CanvasPattern]. The DOM default is `'#000000'`.
  abstract Object? fillStyle;

  /// `strokeStyle`: a CSS color `String`, a [CanvasGradient] or a
  /// [CanvasPattern]. The DOM default is `'#000000'`.
  abstract Object? strokeStyle;

  /// `createLinearGradient(x0, y0, x1, y1)`.
  CanvasGradient createLinearGradient(
    double x0,
    double y0,
    double x1,
    double y1,
  );

  /// `createRadialGradient(x0, y0, r0, x1, y1, r1)`.
  CanvasGradient createRadialGradient(
    double x0,
    double y0,
    double r0,
    double x1,
    double y1,
    double r1,
  );

  /// `createConicGradient(startAngle, x, y)`.
  CanvasGradient createConicGradient(double startAngle, double x, double y);

  /// `createPattern(image, repetition)`. [repetition] is `'repeat'`,
  /// `'repeat-x'`, `'repeat-y'` or `'no-repeat'`. A `null` or empty
  /// [repetition] is `'repeat'`.
  CanvasPattern? createPattern(CanvasImageSource image, String? repetition);

  // Rectangles.

  /// `clearRect(x, y, w, h)`.
  void clearRect(double x, double y, double w, double h);

  /// `fillRect(x, y, w, h)`.
  void fillRect(double x, double y, double w, double h);

  /// `strokeRect(x, y, w, h)`.
  void strokeRect(double x, double y, double w, double h);

  // Paths.

  /// `beginPath()`.
  void beginPath();

  /// `fill()`, `fill(fillRule)` or `fill(path, fillRule)`.
  ///
  /// [pathOrFillRule] is a [Path2D], a [CanvasFillRule] or `null`. When it
  /// is a [Path2D], [fillRule] is the rule.
  void fill([Object? pathOrFillRule, CanvasFillRule? fillRule]);

  /// `stroke()` or `stroke(path)`.
  void stroke([Path2D? path]);

  /// `clip()`, `clip(fillRule)` or `clip(path, fillRule)`.
  ///
  /// [pathOrFillRule] is a [Path2D], a [CanvasFillRule] or `null`. When it
  /// is a [Path2D], [fillRule] is the rule.
  void clip([Object? pathOrFillRule, CanvasFillRule? fillRule]);

  // Line styles.

  /// `lineWidth`. The DOM default is 1.
  abstract double? lineWidth;

  /// `lineCap`: `'butt'`, `'round'` or `'square'`. The DOM default is
  /// `'butt'`.
  abstract String? lineCap;

  /// `lineJoin`: `'miter'`, `'round'` or `'bevel'`. The DOM default is
  /// `'miter'`.
  abstract String? lineJoin;

  /// `miterLimit`. The DOM default is 10.
  abstract double? miterLimit;

  /// `setLineDash(segments)`. A list with a non-finite or negative value
  /// does nothing. A list with an odd length repeats itself once.
  void setLineDash(List<double> segments);

  /// `getLineDash()`.
  List<double> getLineDash();

  /// `lineDashOffset`. The DOM default is 0.
  abstract double? lineDashOffset;

  // Text.

  /// `font`: a CSS font shorthand, as `toFontString` gives it. The DOM
  /// default is `'10px sans-serif'`.
  abstract String? font;

  /// `textAlign`: `'start'`, `'end'`, `'left'`, `'right'` or `'center'`.
  /// The DOM default is `'start'`.
  abstract String? textAlign;

  /// `textBaseline`: `'top'`, `'hanging'`, `'middle'`, `'alphabetic'`,
  /// `'ideographic'` or `'bottom'`. The DOM default is `'alphabetic'`.
  abstract String? textBaseline;

  /// `direction`: `'ltr'`, `'rtl'` or `'inherit'`. The DOM default is
  /// `'inherit'`: the direction of [HTMLCanvasElement.style].
  abstract String? direction;

  /// `fillText(text, x, y, maxWidth)`. A `null` [maxWidth] is the JS
  /// `undefined` of an absent argument.
  void fillText(String text, double x, double y, [double? maxWidth]);

  /// `strokeText(text, x, y, maxWidth)`. A `null` [maxWidth] is the JS
  /// `undefined` of an absent argument.
  void strokeText(String text, double x, double y, [double? maxWidth]);

  /// `measureText(text)`, with the current [font].
  TextMetrics measureText(String text);

  // Images.

  /// `drawImage(image, dx, dy)` or `drawImage(image, dx, dy, dw, dh)`.
  void drawImage(
    CanvasImageSource image,
    double dx,
    double dy, [
    double? dw,
    double? dh,
  ]);
}

/// lib.dom.d.ts `Path2D`: a path that the code builds once and then fills,
/// strokes or clips many times (`element.line.js:210-216`).
///
/// The class is pure Dart. It records the path commands in [commands]. A
/// context replays them. A context can keep a converted form of the path in
/// [cache] and reuse it while [version] does not change.
final class Path2D implements CanvasPath {
  /// `new Path2D()`: an empty path.
  Path2D();

  /// The recorded commands, in order.
  final List<PathCommand> commands = [];

  /// A slot for the converted form of this path, for the context that drew
  /// it last.
  Object? cache;

  /// The count of changes. A context compares it with the version of its
  /// [cache].
  int get version => commands.length;

  @override
  void closePath() => commands.add(const ClosePathCommand());

  @override
  void moveTo(double x, double y) => commands.add(MoveToCommand(x, y));

  @override
  void lineTo(double x, double y) => commands.add(LineToCommand(x, y));

  @override
  void bezierCurveTo(
    double cp1x,
    double cp1y,
    double cp2x,
    double cp2y,
    double x,
    double y,
  ) => commands.add(BezierCurveToCommand(cp1x, cp1y, cp2x, cp2y, x, y));

  @override
  void quadraticCurveTo(double cpx, double cpy, double x, double y) =>
      commands.add(QuadraticCurveToCommand(cpx, cpy, x, y));

  @override
  void arc(
    double x,
    double y,
    double radius,
    double startAngle,
    double endAngle, [
    bool counterclockwise = false,
  ]) {
    if (radius < 0) {
      throw RangeError.value(radius, 'radius', 'The radius is negative');
    }
    commands.add(
      ArcCommand(x, y, radius, startAngle, endAngle, counterclockwise),
    );
  }

  @override
  void arcTo(double x1, double y1, double x2, double y2, double radius) {
    if (radius < 0) {
      throw RangeError.value(radius, 'radius', 'The radius is negative');
    }
    commands.add(ArcToCommand(x1, y1, x2, y2, radius));
  }

  @override
  void ellipse(
    double x,
    double y,
    double radiusX,
    double radiusY,
    double rotation,
    double startAngle,
    double endAngle, [
    bool counterclockwise = false,
  ]) {
    if (radiusX < 0 || radiusY < 0) {
      throw RangeError('The radius is negative');
    }
    commands.add(
      EllipseCommand(
        x,
        y,
        radiusX,
        radiusY,
        rotation,
        startAngle,
        endAngle,
        counterclockwise,
      ),
    );
  }

  @override
  void rect(double x, double y, double w, double h) =>
      commands.add(RectCommand(x, y, w, h));

  /// Throws at this call, as the DOM does: [roundRectGeometry] examines the
  /// arguments. The command keeps a copy of a [radii] list, as the DOM
  /// converts the sequence at the call.
  @override
  void roundRect(double x, double y, double w, double h, [Object? radii]) {
    roundRectGeometry(x, y, w, h, radii);
    commands.add(
      RoundRectCommand(
        x,
        y,
        w,
        h,
        radii is List ? List<Object?>.unmodifiable(radii) : radii,
      ),
    );
  }

  /// Replays [commands] on [target], in order.
  void replay(CanvasPath target) {
    for (final command in commands) {
      command.applyTo(target);
    }
  }
}

/// One recorded command of a [Path2D].
sealed class PathCommand {
  const PathCommand();

  /// Calls the method of this command on [target].
  void applyTo(CanvasPath target);
}

/// A recorded [CanvasPath.closePath].
final class ClosePathCommand extends PathCommand {
  /// Creates the command.
  const ClosePathCommand();

  @override
  void applyTo(CanvasPath target) => target.closePath();
}

/// A recorded [CanvasPath.moveTo].
final class MoveToCommand extends PathCommand {
  /// Creates the command.
  const MoveToCommand(this.x, this.y);

  /// An argument.
  final double x;

  /// An argument.
  final double y;

  @override
  void applyTo(CanvasPath target) => target.moveTo(x, y);
}

/// A recorded [CanvasPath.lineTo].
final class LineToCommand extends PathCommand {
  /// Creates the command.
  const LineToCommand(this.x, this.y);

  /// An argument.
  final double x;

  /// An argument.
  final double y;

  @override
  void applyTo(CanvasPath target) => target.lineTo(x, y);
}

/// A recorded [CanvasPath.bezierCurveTo].
final class BezierCurveToCommand extends PathCommand {
  /// Creates the command.
  const BezierCurveToCommand(
    this.cp1x,
    this.cp1y,
    this.cp2x,
    this.cp2y,
    this.x,
    this.y,
  );

  /// An argument.
  final double cp1x;

  /// An argument.
  final double cp1y;

  /// An argument.
  final double cp2x;

  /// An argument.
  final double cp2y;

  /// An argument.
  final double x;

  /// An argument.
  final double y;

  @override
  void applyTo(CanvasPath target) =>
      target.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y);
}

/// A recorded [CanvasPath.quadraticCurveTo].
final class QuadraticCurveToCommand extends PathCommand {
  /// Creates the command.
  const QuadraticCurveToCommand(this.cpx, this.cpy, this.x, this.y);

  /// An argument.
  final double cpx;

  /// An argument.
  final double cpy;

  /// An argument.
  final double x;

  /// An argument.
  final double y;

  @override
  void applyTo(CanvasPath target) => target.quadraticCurveTo(cpx, cpy, x, y);
}

/// A recorded [CanvasPath.arc].
final class ArcCommand extends PathCommand {
  /// Creates the command.
  const ArcCommand(
    this.x,
    this.y,
    this.radius,
    this.startAngle,
    this.endAngle,
    // The DOM argument order.
    // ignore: avoid_positional_boolean_parameters
    this.counterclockwise,
  );

  /// An argument.
  final double x;

  /// An argument.
  final double y;

  /// An argument.
  final double radius;

  /// An argument.
  final double startAngle;

  /// An argument.
  final double endAngle;

  /// The direction argument.
  final bool counterclockwise;

  @override
  void applyTo(CanvasPath target) =>
      target.arc(x, y, radius, startAngle, endAngle, counterclockwise);
}

/// A recorded [CanvasPath.arcTo].
final class ArcToCommand extends PathCommand {
  /// Creates the command.
  const ArcToCommand(this.x1, this.y1, this.x2, this.y2, this.radius);

  /// An argument.
  final double x1;

  /// An argument.
  final double y1;

  /// An argument.
  final double x2;

  /// An argument.
  final double y2;

  /// An argument.
  final double radius;

  @override
  void applyTo(CanvasPath target) => target.arcTo(x1, y1, x2, y2, radius);
}

/// A recorded [CanvasPath.ellipse].
final class EllipseCommand extends PathCommand {
  /// Creates the command.
  const EllipseCommand(
    this.x,
    this.y,
    this.radiusX,
    this.radiusY,
    this.rotation,
    this.startAngle,
    this.endAngle,
    // The DOM argument order.
    // ignore: avoid_positional_boolean_parameters
    this.counterclockwise,
  );

  /// An argument.
  final double x;

  /// An argument.
  final double y;

  /// An argument.
  final double radiusX;

  /// An argument.
  final double radiusY;

  /// An argument.
  final double rotation;

  /// An argument.
  final double startAngle;

  /// An argument.
  final double endAngle;

  /// The direction argument.
  final bool counterclockwise;

  @override
  void applyTo(CanvasPath target) => target.ellipse(
    x,
    y,
    radiusX,
    radiusY,
    rotation,
    startAngle,
    endAngle,
    counterclockwise,
  );
}

/// A recorded [CanvasPath.rect].
final class RectCommand extends PathCommand {
  /// Creates the command.
  const RectCommand(this.x, this.y, this.w, this.h);

  /// An argument.
  final double x;

  /// An argument.
  final double y;

  /// An argument.
  final double w;

  /// An argument.
  final double h;

  @override
  void applyTo(CanvasPath target) => target.rect(x, y, w, h);
}

/// A recorded [CanvasPath.roundRect].
final class RoundRectCommand extends PathCommand {
  /// Creates the command.
  const RoundRectCommand(this.x, this.y, this.w, this.h, this.radii);

  /// An argument.
  final double x;

  /// An argument.
  final double y;

  /// An argument.
  final double w;

  /// An argument.
  final double h;

  /// The radii argument: a number, an unmodifiable list or `null`.
  final Object? radii;

  @override
  void applyTo(CanvasPath target) => target.roundRect(x, y, w, h, radii);
}
