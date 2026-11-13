// Ported from chartjs-chart-sankey v0.19.1 src/flow.ts (MIT, Jukka Kurkela).

/// Port of `src/flow.ts`: the element `flow`, one flow between two nodes.
///
/// - A color is a `ChartPaint` of the host, or a Flutter `Color` (row
///   `adapt-sankey-native-colors`). The test `typeof option === 'string'` of
///   upstream is the test for a solid color. A gradient of the canvas is a
///   `ChartGradient`.
/// - [Flow] follows the element protocol of the host (Chart.js ADR 0017):
///   each property has a typed member and the access by name, which the
///   animations and `Object.assign` use.
/// - [Flow.jsClass] is the class as a value (Chart.js ADR 0020): the
///   registry of the host takes it.
library;

import 'dart:math' as math;
import 'dart:ui' show Color, Offset;

import 'package:flutter_chartjs_chart_sankey_port/src/labels.dart';
import 'package:flutter_chartjs_chart_sankey_port/src/types.dart';
import 'package:flutter_chartjs_port/chartjs.dart'
    show
        CanvasRenderingContext2D,
        ChartArea,
        ChartGradient,
        ChartPaint,
        Element,
        ElementPoint,
        JsClass,
        ScaleAxis,
        SolidChartPaint,
        Undefined,
        VisualElementRange,
        XAxis,
        elementCfgArg,
        undefined;
import 'package:flutter_chartjs_port/helpers.dart' show getHoverColor, toFont;
import 'package:flutter_chartjs_port/js_semantics.dart'
    show jsGet, jsNumberToString, jsToNumber, jsTruthy;

typedef _FlowPoint = ({double x, double y});
typedef _ControlPoints = ({_FlowPoint cp1, _FlowPoint cp2});

/// flow.ts:12 `controlPoints`.
_ControlPoints _controlPoints(
  double x,
  double y,
  double x2,
  double y2,
  bool vertical,
) => vertical
    ? y < y2
          ? (
              cp1: (x: x, y: y + ((y2 - y) / 3) * 2),
              cp2: (x: x2, y: y + (y2 - y) / 3),
            )
          : (
              cp1: (x: 0, y: y - (y - y2) / 3),
              cp2: (x: 0, y: y2 + (y - y2) / 3),
            )
    : x < x2
    ? (
        cp1: (x: x + ((x2 - x) / 3) * 2, y: y),
        cp2: (x: x + (x2 - x) / 3, y: y2),
      )
    : (cp1: (x: x - (x - x2) / 3, y: 0), cp2: (x: x2 + (x - x2) / 3, y: 0));

/// flow.ts:39 `pointInLine`.
_FlowPoint _pointInLine(_FlowPoint p1, _FlowPoint p2, double t) =>
    (x: p1.x + t * (p2.x - p1.x), y: p1.y + t * (p2.y - p1.y));

/// The color of [option] when it is a solid color, else Dart `null`: the
/// test `typeof option === 'string'` of flow.ts:47, :49 and :60.
// DIVERGES(sankey): adapt-sankey-native-colors, a solid paint is the string.
Color? _solidColor(Object? option) => switch (option) {
  SolidChartPaint(:final color) => color,
  final Color color => color,
  _ => null,
};

/// flow.ts:44 `applyAlpha`.
ChartPaint _applyAlpha(Color original, double alpha) =>
    ChartPaint.solid(original.withValues(alpha: alpha));

/// flow.ts:46 `getColorOption`.
Object? _getColorOption(Object? option, double alpha) {
  final color = _solidColor(option);
  return color != null ? _applyAlpha(color, alpha) : option;
}

/// flow.ts:48 `getHoverColorOption`.
Object? _getHoverColorOption(Object? option) =>
    _solidColor(option) != null ? getHoverColor(option) : option;

const ChartPaint _black = ChartPaint.solid(Color(0xFF000000));

/// The ends, the colors and the alpha of the gradient of a flow.
typedef _GradientKey = (
  bool vertical,
  double start,
  double end,
  Color from,
  Color to,
  double alpha,
);

/// The bound of [_gradients].
const int _maxGradients = 512;

/// The gradients of the last draws, by their ends, colors and alpha.
///
/// `setStyle` of flow.ts:61-66 makes a new gradient for each flow at each draw,
/// and the canvas makes a shader for each new gradient. The flows between
/// two columns with the same colors have equal gradients. One gradient
/// object for them paints the same pixels with one shader.
// DIVERGES(sankey): adapt-sankey-shared-gradients, one object for equal ones.
final Map<_GradientKey, ChartGradient> _gradients = {};

/// flow.ts:63 `ctx.createLinearGradient` with its two color stops: the
/// gradient from [from] at [start] to [to] at [end], along x, or along y for
/// a [vertical] flow.
ChartGradient _gradient(
  double start,
  double end,
  Color from,
  Color to,
  double alpha, {
  required bool vertical,
}) {
  final key = (vertical, start, end, from, to, alpha);
  final known = _gradients[key];
  if (known != null) return known;
  // An animation gives new ends in each frame: the cache starts again.
  if (_gradients.length >= _maxGradients) _gradients.clear();
  return _gradients[key] = ChartGradient.linear(
    vertical ? Offset(0, start) : Offset(start, 0),
    vertical ? Offset(0, end) : Offset(end, 0),
    List.unmodifiable([
      from.withValues(alpha: alpha),
      to.withValues(alpha: alpha),
    ]),
  );
}

/// flow.ts:51 `setStyle`.
///
/// A `flowColor` that is `undefined` gives the canvas no new style, as the
/// write of `undefined` to `fillStyle` does.
void _setStyle(CanvasRenderingContext2D ctx, Flow flow, bool vertical) {
  final options = FlowOptionsFace(flow.options);
  final alpha = jsToNumber(options.alpha);
  Object? fill = _black;

  final flowColor = options.flowColor;
  if (flowColor != null) {
    fill = flowColor is Undefined ? null : flowColor;
  } else if (options.colorMode == SankeyColorMode.from) {
    fill = _getColorOption(options.colorFrom, alpha);
  } else if (options.colorMode == SankeyColorMode.to) {
    fill = _getColorOption(options.colorTo, alpha);
  } else {
    final from = _solidColor(options.colorFrom);
    final to = _solidColor(options.colorTo);
    if (from != null && to != null) {
      fill = _gradient(
        vertical ? flow.y : flow.x,
        vertical ? flow.y2 : flow.x2,
        from,
        to,
        alpha,
        vertical: vertical,
      );
    }
  }

  ctx
    ..fillStyle = fill
    ..strokeStyle = fill
    ..lineWidth = 0.5;
}

typedef _FlowGeometry = ({
  double height,
  double width,
  double x,
  double x2,
  double y,
  double y2,
});

/// flow.ts:76 `clipFlow`.
void _clipFlow(
  CanvasRenderingContext2D ctx,
  _FlowGeometry geometry,
  double progress,
  bool vertical,
) {
  final (:height, :width, :x, :x2, :y, :y2) = geometry;
  ctx.beginPath();
  if (vertical) {
    ctx.rect(
      math.min(x, x2),
      y,
      (x2 - x).abs() + width + 1,
      (y2 - y) * progress + 1,
    );
  } else {
    ctx.rect(
      x,
      math.min(y, y2),
      (x2 - x) * progress + 1,
      (y2 - y).abs() + height + 1,
    );
  }
  ctx.clip();
}

/// flow.ts:91 `drawFlowPath`.
void _drawFlowPath(
  CanvasRenderingContext2D ctx,
  _FlowGeometry geometry,
  _ControlPoints controls,
  bool vertical,
) {
  final (:height, :width, :x, :x2, :y, :y2) = geometry;
  final (:cp1, :cp2) = controls;
  ctx
    ..beginPath()
    ..moveTo(x, y)
    ..bezierCurveTo(cp1.x, cp1.y, cp2.x, cp2.y, x2, y2);
  if (vertical) {
    ctx
      ..lineTo(x2 + width, y2)
      ..bezierCurveTo(cp2.x + width, cp2.y, cp1.x + width, cp1.y, x + width, y);
  } else {
    ctx
      ..lineTo(x2, y2 + height)
      ..bezierCurveTo(
        cp2.x,
        cp2.y + height,
        cp1.x,
        cp1.y + height,
        x,
        y + height,
      );
  }
  ctx
    ..lineTo(x, y)
    ..stroke()
    ..closePath()
    ..fill();
}

/// flow.ts:113 `getLabelRect`.
({double height, double width, double x, double y}) _getLabelRect(
  _FlowGeometry geometry,
  bool vertical,
) {
  final (:height, :width, :x, :x2, :y, :y2) = geometry;
  if (vertical) {
    return (
      height: y2 - y,
      width: (x2 - x).abs() + width,
      x: math.min(x, x2),
      y: y,
    );
  }
  return (
    height: (y2 - y).abs() + height,
    width: x2 - x,
    x: x,
    y: math.min(y, y2),
  );
}

/// flow.ts:133 `class Flow extends Element<FlowProps, FlowOptions>`.
class Flow([Map<String, Object?>? cfg])
    extends Element
    implements VisualElementRange {
  /// flow.ts:169 `constructor(cfg: FlowConfig)`: copies the properties of
  /// [cfg] by name.
  this {
    if (cfg != null) assign(cfg);
  }

  /// flow.ts:134 `static readonly id = 'flow'`.
  static const String id = 'flow';

  /// flow.ts:135 `static override readonly defaults`.
  static final Map<String, Object?> defaults = <String, Object?>{
    'alpha': 0.5,
    'colorFrom': const ChartPaint.solid(Color(0xFFFF0000)),
    'colorMode': SankeyColorMode.gradient,
    'colorTo': const ChartPaint.solid(Color(0xFF008000)),
    'flowColor': null,
    'flowLabels': <String, Object?>{
      'borderRadius': 0.0,
      'color': _black,
      'display': false,
      'padding': 4.0,
      'position': SankeyLabelPosition.center,
    },
    'hoverColorFrom': (Object? ctx, Object? options) =>
        _getHoverColorOption(jsGet(options, 'colorFrom')),
    'hoverColorTo': (Object? ctx, Object? options) =>
        _getHoverColorOption(jsGet(options, 'colorTo')),
    'orientation': SankeyOrientation.horizontal,
  };

  /// flow.ts:153 `static readonly descriptors`.
  static final Map<String, Object?> descriptors = <String, Object?>{
    '_scriptable': true,
    'flowLabels': <String, Object?>{'_scriptable': true},
  };

  /// flow.ts:133 `class Flow extends Element` as a value (Chart.js ADR
  /// 0020): its statics are [id], [defaults] and [descriptors], and its
  /// `construct` calls [Flow.new] with the `cfg` of its arguments.
  static final JsClass jsClass = JsClass(
    'Flow',
    superclass: Element.jsClass,
    statics: {'id': id, 'defaults': defaults, 'descriptors': descriptors},
    construct: (newTarget, args) => Flow(elementCfgArg(args)),
  );

  static const int _flowBit = 1;
  static const int _x2Bit = 2;
  static const int _y2Bit = 4;
  static const int _widthBit = 8;
  static const int _heightBit = 16;
  static const int _progressBit = 32;

  double _flow = 0;
  double _x2 = 0;
  double _y2 = 0;
  double _width = 0;
  double _height = 0;
  double _progress = 1;

  /// The bits of the numeric properties in the `undefined` state.
  int _undefinedBits = 0;

  /// flow.ts:160 `flow = 0`: the size of the flow.
  double get flow => _flow;
  set flow(double value) {
    _flow = value;
    _undefinedBits &= ~_flowBit;
  }

  /// flow.ts:161 `x2 = 0`: the x of the target end.
  double get x2 => _x2;
  set x2(double value) {
    _x2 = value;
    _undefinedBits &= ~_x2Bit;
  }

  /// flow.ts:162 `y2 = 0`: the y of the target end.
  double get y2 => _y2;
  set y2(double value) {
    _y2 = value;
    _undefinedBits &= ~_y2Bit;
  }

  /// flow.ts:163 `width = 0`: the size of a vertical flow, in pixels.
  double get width => _width;
  set width(double value) {
    _width = value;
    _undefinedBits &= ~_widthBit;
  }

  /// flow.ts:164 `height = 0`: the size of a horizontal flow, in pixels.
  double get height => _height;
  set height(double value) {
    _height = value;
    _undefinedBits &= ~_heightBit;
  }

  /// flow.ts:165 `progress = 1`: the drawn part of the flow, from 0 to 1.
  double get progress => _progress;
  set progress(double value) {
    _progress = value;
    _undefinedBits &= ~_progressBit;
  }

  /// flow.ts:166 `from?: SankeyNode`: the source node.
  SankeyNode? from;

  /// flow.ts:167 `to?: SankeyNode`: the target node.
  SankeyNode? to;

  Object? _read(double value, int bit) =>
      _undefinedBits & bit != 0 ? undefined : value;

  double _write(String prop, Object? value, int bit) {
    final number = toNumberProp(prop, value);
    _undefinedBits = number == null
        ? _undefinedBits | bit
        : _undefinedBits & ~bit;
    return number ?? double.nan;
  }

  @override
  Object? operator [](String prop) => switch (prop) {
    'flow' => _read(_flow, _flowBit),
    'x2' => _read(_x2, _x2Bit),
    'y2' => _read(_y2, _y2Bit),
    'width' => _read(_width, _widthBit),
    'height' => _read(_height, _heightBit),
    'progress' => _read(_progress, _progressBit),
    'from' => from ?? undefined,
    'to' => to ?? undefined,
    _ => super[prop],
  };

  @override
  void operator []=(String prop, Object? value) {
    switch (prop) {
      case 'flow':
        _flow = _write(prop, value, _flowBit);
      case 'x2':
        _x2 = _write(prop, value, _x2Bit);
      case 'y2':
        _y2 = _write(prop, value, _y2Bit);
      case 'width':
        _width = _write(prop, value, _widthBit);
      case 'height':
        _height = _write(prop, value, _heightBit);
      case 'progress':
        _progress = _write(prop, value, _progressBit);
      case 'from':
        from = toObjectProp<SankeyNode>(prop, value);
      case 'to':
        to = toObjectProp<SankeyNode>(prop, value);
      default:
        super[prop] = value;
    }
  }

  bool get _vertical =>
      FlowOptionsFace(options).orientation == SankeyOrientation.vertical;

  /// flow.ts:180 `draw(ctx)`.
  ///
  /// @param {CanvasRenderingContext2D} ctx
  @override
  void draw(CanvasRenderingContext2D ctx, [ChartArea? area]) {
    final vertical = _vertical;
    final controls = _controlPoints(x, y, x2, y2, vertical);
    final geometry = (height: height, width: width, x: x, x2: x2, y: y, y2: y2);

    if (progress == 0) {
      return;
    }
    ctx.save();
    if (progress < 1) {
      _clipFlow(ctx, geometry, progress, vertical);
    }

    _setStyle(ctx, this, vertical);
    _drawFlowPath(ctx, geometry, controls, vertical);

    final labels = FlowOptionsFace(options).flowLabels;
    if (jsTruthy(labels.display)) {
      final font = toFont(labels.font);
      final labelRect = _getLabelRect(geometry, vertical);
      final backgroundColor = labels.backgroundColor;
      drawLabel(
        ctx,
        jsNumberToString(flow),
        DrawLabelOptions(
          autoPosition: SankeyLabelPosition.center,
          backgroundColor: backgroundColor is Undefined
              ? null
              : backgroundColor,
          borderRadius: jsToNumber(labels.borderRadius),
          borderWidth: 0,
          color: labels.color,
          font: font,
          height: labelRect.height,
          lineOffset: (font.lineHeight ?? double.nan) / 2,
          padding: jsToNumber(labels.padding),
          position: labels.position ?? SankeyLabelPosition.center,
          width: labelRect.width,
          x: labelRect.x,
          y: labelRect.y,
        ),
      );
    }

    ctx.restore();
  }

  /// The number of the property [prop] of `getProps(props,
  /// useFinalPosition)`.
  double _prop(String prop, bool? useFinalPosition) =>
      jsToNumber(getProps([prop], useFinalPosition)[prop]);

  /// flow.ts:227 `inRange(mouseX, mouseY, useFinalPosition)`.
  ///
  /// @param {number} mouseX
  /// @param {number} mouseY
  /// @param {boolean} useFinalPosition
  /// @return {boolean}
  @override
  bool inRange(double? mouseX, double? mouseY, [bool? useFinalPosition]) {
    final mx = mouseX ?? 0;
    final my = mouseY ?? 0;
    final x = _prop('x', useFinalPosition);
    final y = _prop('y', useFinalPosition);
    final x2 = _prop('x2', useFinalPosition);
    final y2 = _prop('y2', useFinalPosition);
    final height = _prop('height', useFinalPosition);
    final width = _prop('width', useFinalPosition);
    final vertical = _vertical;
    if (vertical ? my < y || my > y2 : mx < x || mx > x2) return false;

    final (:cp1, :cp2) = _controlPoints(x, y, x2, y2, vertical);
    final t = vertical ? (my - y) / (y2 - y) : (mx - x) / (x2 - x);
    final p1 = (x: x, y: y);
    final p2 = (x: x2, y: y2);
    final a = _pointInLine(p1, cp1, t);
    final b = _pointInLine(cp1, cp2, t);
    final c = _pointInLine(cp2, p2, t);
    final d = _pointInLine(a, b, t);
    final e = _pointInLine(b, c, t);
    final edge = _pointInLine(d, e, t);
    return vertical
        ? mx >= edge.x && mx <= edge.x + width
        : my >= edge.y && my <= edge.y + height;
  }

  /// flow.ts:255 `inXRange(mouseX, useFinalPosition)`.
  ///
  /// @param {number} mouseX
  /// @param {boolean} useFinalPosition
  /// @return {boolean}
  @override
  bool inXRange(double? mouseX, [bool? useFinalPosition]) {
    final mx = mouseX ?? 0;
    final x = _prop('x', useFinalPosition);
    final x2 = _prop('x2', useFinalPosition);
    final width = _prop('width', useFinalPosition);
    final min = math.min(x, x2);
    final max = math.max(x, x2) + (_vertical ? width : 0);
    return mx >= min && mx <= max;
  }

  /// flow.ts:267 `inYRange(mouseY, useFinalPosition)`.
  ///
  /// @param {number} mouseY
  /// @param {boolean} useFinalPosition
  /// @return {boolean}
  @override
  bool inYRange(double? mouseY, [bool? useFinalPosition]) {
    final my = mouseY ?? 0;
    final y = _prop('y', useFinalPosition);
    final y2 = _prop('y2', useFinalPosition);
    final height = _prop('height', useFinalPosition);
    final minY = math.min(y, y2);
    final maxY = math.max(y, y2) + (_vertical ? 0 : height);
    return my >= minY && my <= maxY;
  }

  /// flow.ts:278 `getCenterPoint(useFinalPosition)`.
  ///
  /// @param {boolean} useFinalPosition
  /// @return {{x: number, y:number}}
  @override
  ElementPoint getCenterPoint([bool? useFinalPosition]) {
    final x = _prop('x', useFinalPosition);
    final y = _prop('y', useFinalPosition);
    final x2 = _prop('x2', useFinalPosition);
    final y2 = _prop('y2', useFinalPosition);
    final height = _prop('height', useFinalPosition);
    final width = _prop('width', useFinalPosition);
    final vertical = _vertical;
    return ElementPoint(
      (x + x2 + (vertical ? width : 0)) / 2,
      (y + y2 + (vertical ? 0 : height)) / 2,
    );
  }

  /// flow.ts:290 `tooltipPosition(useFinalPosition = false)`.
  @override
  ElementPoint tooltipPosition([bool? useFinalPosition]) =>
      getCenterPoint(useFinalPosition ?? false);

  /// flow.ts:298 `getRange(axis)`.
  ///
  /// @param {"x" | "y"} axis
  /// @return {number}
  @override
  Object getRange(ScaleAxis axis) {
    final vertical = _vertical;
    if (axis is XAxis) return vertical ? width / 2 : 0.0;
    return vertical ? 0.0 : height / 2;
  }
}
