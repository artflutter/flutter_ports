// Ported from chartjs-test-utils v0.4.0 src/context.js (MIT, chartjs-test-utils Contributors).

/// Port of `src/context.js`: the mock canvas context that records calls.
///
/// This library is a pure layer. It implements the canvas interface of
/// `flutter_chartjs` (`lib/src/canvas/canvas.dart`), which has no `dart:ui`.
library;

// The harness implements the canvas interface. flutter_chartjs does not
// export lib/src.
// ignore: implementation_imports
import 'package:flutter_chartjs/src/canvas/canvas.dart';

/// context.js:157 the object that `record` pushes: `{name, args}`.
///
/// A JS object literal is a `Map<String, Object?>` (Chart.js ADR 0006), with
/// the keys `'name'` and `'args'`. The `equals` matcher of `package:test`
/// compares maps and lists element by element, as `toEqual` does.
///
/// JS records the arguments that the caller passed
/// (`Array.prototype.slice.call(arguments)`). Dart cannot tell an absent
/// optional argument from a passed one. Thus the mock records each declared
/// parameter (`harness-mock-optional-args`, differences.md). Dart `null`
/// stands for an absent nullable optional argument, the JS `undefined`. A
/// non-nullable optional parameter records its default: an absent
/// `counterclockwise` of `arc` records `false`. An upstream expectation that
/// lists fewer arguments gets the trailing default values in the port.
typedef ContextCall = Map<String, Object?>;

/// context.js:122 the result of the mock `measureText`.
final class _MockTextMetrics implements TextMetrics {
  const _MockTextMetrics({
    required this.actualBoundingBoxAscent,
    required this.actualBoundingBoxDescent,
    required this.actualBoundingBoxLeft,
    required this.actualBoundingBoxRight,
    required this.width,
  });

  @override
  final double actualBoundingBoxAscent;

  @override
  final double actualBoundingBoxDescent;

  @override
  final double actualBoundingBoxLeft;

  @override
  final double actualBoundingBoxRight;

  @override
  final double width;
}

/// context.js:2 `Context`: a [CanvasRenderingContext2D] that records the
/// calls of 24 methods and the writes of 9 properties.
///
/// The mock defines only the members of `src/context.js`, plus the
/// port-only [roundRect], which records its calls too. A JS caller that
/// calls another method gets a `TypeError`, because the method is
/// `undefined`. Here such a method throws an [UnsupportedError]. A JS caller
/// that writes another property creates it without a record. Here such a
/// property stores the value and records nothing.
class MockContext implements CanvasRenderingContext2D {
  /// context.js:3 `constructor`.
  MockContext();

  // context.js:4 `this._calls = []`.
  List<ContextCall> _calls = [];

  // context.js:7-15 the recorded properties, `null` at the start.
  Object? _fillStyle;
  String? _font;
  String? _lineCap;
  double? _lineDashOffset;
  String? _lineJoin;
  double? _lineWidth;
  Object? _strokeStyle;
  String? _textAlign;
  String? _textBaseline;

  /// context.js:156 `record`.
  void record(String methodName, List<Object?> args) {
    _calls.add({'name': methodName, 'args': List<Object?>.unmodifiable(args)});
  }

  /// context.js:162 `getCalls`.
  List<ContextCall> getCalls() {
    return _calls;
  }

  /// context.js:165 `resetCalls`.
  void resetCalls() {
    _calls = [];
  }

  // context.js:18-100 the recorded properties.

  @override
  Object? get fillStyle => _fillStyle;

  @override
  set fillStyle(Object? style) {
    _fillStyle = style;
    record('setFillStyle', [style]);
  }

  @override
  String? get font => _font;

  @override
  set font(String? font) {
    _font = font;
    record('setFont', [font]);
  }

  @override
  String? get lineCap => _lineCap;

  @override
  set lineCap(String? cap) {
    _lineCap = cap;
    record('setLineCap', [cap]);
  }

  @override
  double? get lineDashOffset => _lineDashOffset;

  @override
  set lineDashOffset(double? offset) {
    _lineDashOffset = offset;
    record('setLineDashOffset', [offset]);
  }

  @override
  String? get lineJoin => _lineJoin;

  @override
  set lineJoin(String? join) {
    _lineJoin = join;
    record('setLineJoin', [join]);
  }

  @override
  double? get lineWidth => _lineWidth;

  @override
  set lineWidth(double? width) {
    _lineWidth = width;
    record('setLineWidth', [width]);
  }

  @override
  Object? get strokeStyle => _strokeStyle;

  @override
  set strokeStyle(Object? style) {
    _strokeStyle = style;
    record('setStrokeStyle', [style]);
  }

  @override
  String? get textAlign => _textAlign;

  @override
  set textAlign(String? align) {
    _textAlign = align;
    record('setTextAlign', [align]);
  }

  @override
  String? get textBaseline => _textBaseline;

  @override
  set textBaseline(String? baseline) {
    _textBaseline = baseline;
    record('setTextBaseline', [baseline]);
  }

  // context.js:106-147 the recorded methods. Each method records its name
  // and arguments, then runs the body of `methods[name]`.
  //
  // DIVERGES(chartjs): harness-mock-optional-args, all declared parameters.

  @override
  void arc(
    double x,
    double y,
    double radius,
    double startAngle,
    double endAngle, [
    bool counterclockwise = false,
  ]) {
    record('arc', [x, y, radius, startAngle, endAngle, counterclockwise]);
  }

  @override
  void arcTo(double x1, double y1, double x2, double y2, double radius) {
    record('arcTo', [x1, y1, x2, y2, radius]);
  }

  @override
  void beginPath() {
    record('beginPath', const []);
  }

  @override
  void bezierCurveTo(
    double cp1x,
    double cp1y,
    double cp2x,
    double cp2y,
    double x,
    double y,
  ) {
    record('bezierCurveTo', [cp1x, cp1y, cp2x, cp2y, x, y]);
  }

  @override
  void clearRect(double x, double y, double w, double h) {
    record('clearRect', [x, y, w, h]);
  }

  @override
  void clip([Object? pathOrFillRule, CanvasFillRule? fillRule]) {
    record('clip', [pathOrFillRule, fillRule]);
  }

  @override
  void closePath() {
    record('closePath', const []);
  }

  @override
  void fill([Object? pathOrFillRule, CanvasFillRule? fillRule]) {
    record('fill', [pathOrFillRule, fillRule]);
  }

  @override
  void fillRect(double x, double y, double w, double h) {
    record('fillRect', [x, y, w, h]);
  }

  @override
  void fillText(String text, double x, double y, [double? maxWidth]) {
    record('fillText', [text, x, y, maxWidth]);
  }

  @override
  void strokeText(String text, double x, double y, [double? maxWidth]) {
    record('strokeText', [text, x, y, maxWidth]);
  }

  @override
  void lineTo(double x, double y) {
    record('lineTo', [x, y]);
  }

  /// context.js:119 `measureText`: the number of characters times 10, with
  /// fixed bounding box values. An empty text (a falsy JS string) gives
  /// zeros.
  @override
  TextMetrics measureText(String text) {
    record('measureText', [text]);
    // return the number of characters * fixed size
    // Uses fake numbers for the bounding box
    return text.isNotEmpty
        ? _MockTextMetrics(
            actualBoundingBoxAscent: 4,
            actualBoundingBoxDescent: 8,
            actualBoundingBoxLeft: 15,
            actualBoundingBoxRight: 25,
            // `text.length` counts UTF-16 code units, as in JS.
            width: text.length * 10,
          )
        : const _MockTextMetrics(
            actualBoundingBoxAscent: 0,
            actualBoundingBoxDescent: 0,
            actualBoundingBoxLeft: 0,
            actualBoundingBoxRight: 0,
            width: 0,
          );
  }

  @override
  void moveTo(double x, double y) {
    record('moveTo', [x, y]);
  }

  @override
  void quadraticCurveTo(double cpx, double cpy, double x, double y) {
    record('quadraticCurveTo', [cpx, cpy, x, y]);
  }

  @override
  void rect(double x, double y, double w, double h) {
    record('rect', [x, y, w, h]);
  }

  /// Port-only: `src/context.js` has no `roundRect`. It records the call as
  /// the other path methods do, with [radii] as passed (`null` for an
  /// absent argument), and examines no argument.
  ///
  /// `addRoundedRectPath` calls it in place of the upstream arcs and lines
  /// (differences.md `adapt-rounded-rect-path` of `flutter_chartjs`). A test
  /// that compares the calls with an upstream run translates the call back
  /// into those arcs and lines.
  @override
  void roundRect(double x, double y, double w, double h, [Object? radii]) {
    record('roundRect', [x, y, w, h, radii]);
  }

  @override
  void restore() {
    record('restore', const []);
  }

  @override
  void rotate(double angle) {
    record('rotate', [angle]);
  }

  @override
  void save() {
    record('save', const []);
  }

  @override
  void setLineDash(List<double> segments) {
    // context.js:156-160 copies the argument list, not the array.
    record('setLineDash', [segments]);
  }

  @override
  void stroke([Path2D? path]) {
    record('stroke', [path]);
  }

  @override
  void strokeRect(double x, double y, double w, double h) {
    record('strokeRect', [x, y, w, h]);
  }

  @override
  void setTransform(
    double a,
    double b,
    double c,
    double d,
    double e,
    double f,
  ) {
    record('setTransform', [a, b, c, d, e, f]);
  }

  @override
  void translate(double x, double y) {
    record('translate', [x, y]);
  }

  // The members that `src/context.js` does not define.

  Never _missing(String name) {
    throw UnsupportedError('The mock context has no method $name');
  }

  @override
  HTMLCanvasElement get canvas => _missing('canvas');

  @override
  double? globalAlpha;

  @override
  String? globalCompositeOperation;

  @override
  double? miterLimit;

  @override
  String? direction;

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
  ]) => _missing('ellipse');

  @override
  void scale(double x, double y) => _missing('scale');

  @override
  void transform(
    double a,
    double b,
    double c,
    double d,
    double e,
    double f,
  ) => _missing('transform');

  @override
  void resetTransform() => _missing('resetTransform');

  @override
  CanvasGradient createLinearGradient(
    double x0,
    double y0,
    double x1,
    double y1,
  ) => _missing('createLinearGradient');

  @override
  CanvasGradient createRadialGradient(
    double x0,
    double y0,
    double r0,
    double x1,
    double y1,
    double r1,
  ) => _missing('createRadialGradient');

  @override
  CanvasGradient createConicGradient(double startAngle, double x, double y) =>
      _missing('createConicGradient');

  @override
  CanvasPattern? createPattern(CanvasImageSource image, String? repetition) =>
      _missing('createPattern');

  @override
  List<double> getLineDash() => _missing('getLineDash');

  @override
  void drawImage(
    CanvasImageSource image,
    double dx,
    double dy, [
    double? dw,
    double? dh,
  ]) => _missing('drawImage');
}
