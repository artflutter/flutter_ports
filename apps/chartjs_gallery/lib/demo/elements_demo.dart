// The reason of each import of lib/src is the comment above it.
// ignore_for_file: implementation_imports

import 'dart:math' as math;

import 'package:chartjs_gallery/demo/canvas_demo.dart'
    show chartColors, drawCaption;
import 'package:chartjs_gallery/demo/demo_chart.dart' hide PointOptions;
import 'package:chartjs_gallery/demo/demo_common.dart';
import 'package:chartjs_gallery/demo/demo_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chartjs_port/chartjs.dart' as chartjs show Element;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_chartjs_port/helpers.dart' show getHoverColor;
// Not public: the typed element options of Chart.js ADR 0018.
import 'package:flutter_chartjs_port/src/elements/element_options.dart'
    show ArcOptions, BarOptions, LineOptions, PointOptions;
// Not public: jsOrZero, the JS `value || 0` (Chart.js ADR 0017, section 8).
import 'package:flutter_chartjs_port/src/js/js_number.dart' show jsOrZero;

/// The event types of the elements chart: the Chart.js default `events`
/// option (`core.defaults`): `mousemove`, `mouseout`, `click`, `touchstart`
/// and `touchmove`.
final List<String> elementsDemoEvents = [
  for (final type in defaults['events']! as List<Object?>) type! as String,
];

/// The values of the bars.
const List<double> _barValues = [12, 19, 7, 15, 22, 10];

/// The values of the line. Each point is far from the center of the bar
/// below it, so that a pointer on the center of a bar hits the bar.
const List<double> _lineValues = [17, 4, 14, 21, 18, 13];

/// The values of the doughnut.
const List<double> _arcValues = [30, 22, 18, 16, 14];

/// The value at the top of the bar and line area.
const double _maxValue = 25;

/// The chart width from which the doughnut goes to the right of the bars.
const double _wideWidth = 560;

/// The point styles of the selector. Each style except `circle` shows the
/// rotation.
const List<String> _pointStyles = [
  'circle',
  'cross',
  'crossRot',
  'dash',
  'line',
  'rect',
  'rectRounded',
  'rectRot',
  'star',
  'triangle',
];

/// The values of the `stepped` option of the line.
const List<Object> _steppedValues = [false, 'before', 'after', 'middle'];

/// The values of the `borderAlign` option of the arcs.
const List<Object> _borderAlignValues = ['center', 'inner'];

/// The values of the `borderJoinStyle` option of the arcs. [undefined] is
/// the default: the arc border then joins with `'bevel'`, or with
/// `'round'` for the inner border (element.arc.ts:330-336 `drawBorder`).
const List<Object> _borderJoinStyleValues = [
  undefined,
  'round',
  'bevel',
  'miter',
];

/// The colors of the bar dataset and of the line dataset.
const String _barColor = '#36A2EB';
const String _barBackground = 'rgba(54, 162, 235, 0.5)';
const String _lineColor = '#FF6384';
const String _lineBackground = 'rgba(255, 99, 132, 0.5)';

/// The hover offset of an arc minus its offset.
const double _arcHoverGain = 16;

/// The kinds of elements that the hit test finds.
enum _Kind { bar, point, arc }

/// The element under the pointer: its kind and its index in its dataset.
typedef _Hit = ({_Kind kind, int index});

/// The options of an element in its two states: `base` for the normal
/// state and `active` for the hover state.
typedef _Options = ({JsObjectFace base, JsObjectFace active});

/// The ported elements of phase 4: bars, a line through points, and a
/// doughnut of arcs.
///
/// The chart draws real `BarElement`, `LineElement`, `PointElement` and
/// `ArcElement` objects with their own `draw` methods, on the `dart:ui`
/// canvas (`UiCanvasContext`) of the internal chart host. A [DemoChart]
/// stands in for `core.controller`. The demo sets the properties of each
/// element as the controllers of phase 7 set them:
///
/// - A bar gets `horizontal`, `base`, `enableBorderRadius`, `x`, `y`,
///   `height`, `width`, `borderSkipped` and `inflateAmount`, as
///   `controller.bar.js` gives them for a vertical bar without a stack.
/// - A point gets `x`, `y`, `skip` and `stop`, and the line gets its points
///   and `animated: false`, as `controller.line.js` gives them for a chart
///   without animations. Before the line draws, the demo calls
///   `updateControlPoints` with the area of the bars and the line, as
///   `controller.line.js:140` does. Thus `tension` and `stepped` work.
/// - An arc gets `x`, `y`, `startAngle`, `endAngle`, `circumference`,
///   `innerRadius` and `outerRadius`, as `controller.doughnut.js` gives
///   them for a cutout of 50 %. The radius leaves room for the widest
///   border, the largest `offset` and the spacing
///   (controller.doughnut.js:216-217), not for the hover offset, because
///   the resolved options have no `hoverOffset` key. Thus the border
///   width, the offset, the spacing and the border alignment also change
///   the radii. The doughnut area has a padding of 16 px, as
///   `layout.padding`, so that the active arc stays in the canvas.
///
/// The `options` of each element is a Map like the resolved options that
/// the controllers of phase 7 make: the class defaults
/// (`XElement.defaults`), plus the routed colors, plus the control values.
/// The hover colors are `getHoverColor` of the colors, as `core.defaults`
/// gives them. The demo dataset also sets the point `hoverBorderWidth` to
/// the border width plus 1 and the arc `hoverOffset` to the offset plus 16.
/// Unlike the resolved options of upstream, the arc Map also holds the
/// dataset's `hoverOffset`, and each Map holds the hover colors, for
/// `_resolveActive`: the resolved options of upstream have neither key,
/// because the resolver reads only the keys of `XElement.defaults`
/// (core.datasetController.js:817). For an active element, each key that
/// has a `hover` form takes the value of that form (`hoverRadius` gives
/// `radius`), as the resolver reads the prefix `hover` first
/// (core.datasetController.js:815).
///
/// Each element gets typed options with the same entries: a `BarOptions`,
/// a `PointOptions`, a `LineOptions` and an `ArcOptions` (Chart.js ADR
/// 0018). The keys that are not keys of `XElement.defaults`, for example the
/// hover colors, go to the extra keys of these classes.
///
/// The chart listens to [elementsDemoEvents]. Each event goes through the
/// `inRange` of the elements, from the top of the drawing down: the points,
/// then the bars, then the arcs. The element that gives true becomes active
/// and draws with its hover options. An active point or arc draws on top
/// of its dataset (`drawActiveElementsOnTop`, core.datasetController.js:715).
/// An active bar draws in its place, as controller.bar.js:668 draws each
/// bar in index order. A `mouseout` makes no element active. The
/// chart draws again only when a control or the active element changes.
class ElementsDemo extends StatefulWidget {
  /// Creates the elements tab.
  const ElementsDemo({super.key});

  @override
  State<ElementsDemo> createState() => ElementsDemoState();
}

/// The state of [ElementsDemo]: the control values, the elements and the
/// element under the pointer.
class ElementsDemoState extends State<ElementsDemo> {
  DemoChart? _chart;

  /// Bumped when the hit readout changes, without a rebuild of the page.
  final ValueNotifier<int> _readout = ValueNotifier(0);

  // The control values.
  double _borderWidth = 2;
  double _radius = 6;
  double _hoverRadius = 9;
  double _rotation = 0;
  String _pointStyle = 'triangle';
  double _tension = 0.4;
  Object _stepped = false;
  double _borderRadius = 6;
  double _spacing = 0;
  double _offset = 0;
  Object _borderAlign = 'center';
  Object _borderJoinStyle = undefined;

  // The scene: the size of the chart for the last layout, the area of the
  // bars and the line, and the elements.
  double _sceneWidth = double.nan;
  double _sceneHeight = double.nan;
  Box _plot = const Box(0, 0, 0, 0);
  Box _doughnutArea = const Box(0, 0, 0, 0);
  List<BarElement> _bars = const [];
  List<PointElement> _points = const [];
  LineElement? _line;
  List<ArcElement> _arcs = const [];

  // The options of the elements. All bars share one pair, and all points
  // share one pair. Each arc has its own color, thus its own pair.
  _Options? _barOptions;
  _Options? _pointOptions;
  List<_Options> _arcOptions = const [];

  // The pointer and the element under it.
  Offset? _pointer;
  String _event = '-';
  _Hit? _hit;

  /// The chart, once it exists.
  @visibleForTesting
  DemoChart? get chart => _chart;

  /// The bar elements, empty before the first draw.
  @visibleForTesting
  List<BarElement> get bars => _bars;

  /// The point elements of the line, empty before the first draw.
  @visibleForTesting
  List<PointElement> get points => _points;

  /// The line element, `null` before the first draw.
  @visibleForTesting
  LineElement? get line => _line;

  /// The arc elements of the doughnut, empty before the first draw.
  @visibleForTesting
  List<ArcElement> get arcs => _arcs;

  /// The name of the element under the pointer: `bar i`, `point i`,
  /// `arc i` or `none`.
  @visibleForTesting
  String get hitLabel => switch (_hit) {
    null => 'none',
    final hit => '${hit.kind.name} ${hit.index}',
  };

  @override
  void dispose() {
    _readout.dispose();
    super.dispose();
  }

  // Options.

  /// The options of an element in the normal state and in the hover state.
  ///
  /// [form] gives the options object of each state from its Map: a typed
  /// class of the resolved options (Chart.js ADR 0054 §9), for example
  /// `PointOptions.new`.
  static _Options _pair(
    Map<String, Object?> base,
    JsObjectFace Function(Map<String, Object?>) form,
  ) => (base: form(base), active: form(_resolveActive(base)));

  /// The defaults of an element class as a plain Map: the own keys of the
  /// typed scope [defaults] in their order, read through its face.
  static Map<String, Object?> _plain(JsObjectFace defaults) => {
    for (final key in defaults.jsKeys()) key: defaults[key],
  };

  /// The options of an active element: [options] with the value of each
  /// `hover` key over its base key, for example `hoverRadius` over
  /// `radius`.
  static Map<String, Object?> _resolveActive(Map<String, Object?> options) {
    final resolved = {...options};
    for (final key in options.keys) {
      final hover = options['hover${key[0].toUpperCase()}${key.substring(1)}'];
      if (hover != null && hover is! Undefined) resolved[key] = hover;
    }
    return resolved;
  }

  /// The options of a bar.
  Map<String, Object?> _barBase() => {
    ..._plain(BarElement.defaults),
    'backgroundColor': _barBackground,
    'borderColor': _barColor,
    'hoverBackgroundColor': getHoverColor(_barBackground),
    'hoverBorderColor': getHoverColor(_barColor),
    'borderWidth': _borderWidth,
    'borderRadius': _borderRadius,
  };

  /// The options of a point.
  Map<String, Object?> _pointBase() => {
    ..._plain(PointElement.defaults),
    'backgroundColor': _lineBackground,
    'borderColor': _lineColor,
    'hoverBackgroundColor': getHoverColor(_lineBackground),
    'hoverBorderColor': getHoverColor(_lineColor),
    'borderWidth': _borderWidth,
    'hoverBorderWidth': _borderWidth + 1,
    'pointStyle': _pointStyle,
    'radius': _radius,
    'hoverRadius': _hoverRadius,
    'rotation': _rotation,
  };

  /// The options of the line.
  Map<String, Object?> _lineBase() => {
    ..._plain(LineElement.defaults),
    'backgroundColor': _lineBackground,
    'borderColor': _lineColor,
    'borderWidth': _borderWidth,
    'stepped': _stepped,
    'tension': _tension,
  };

  /// The options of the arc [index].
  Map<String, Object?> _arcBase(int index) {
    final color = chartColors[index % chartColors.length];
    return {
      ..._plain(ArcElement.defaults),
      'backgroundColor': color,
      'hoverBackgroundColor': getHoverColor(color),
      'hoverBorderColor': getHoverColor(ArcElement.defaults['borderColor']),
      'borderWidth': _borderWidth,
      'borderAlign': _borderAlign,
      'borderJoinStyle': _borderJoinStyle,
      'offset': _offset,
      'hoverOffset': _offset + _arcHoverGain,
      'spacing': _spacing,
    };
  }

  /// Gives each element the options of the control values and of its
  /// state. The line also gets its points again: the setter drops the
  /// cached path and the control points, so that the next
  /// `updateControlPoints` uses the new `tension` and `stepped`. The arcs
  /// get the radii of the new options.
  void _applyOptions() {
    final barOptions = _barOptions = _pair(_barBase(), BarOptions.new);
    final pointOptions = _pointOptions = _pair(
      _pointBase(),
      PointOptions.new,
    );
    final arcOptions = _arcOptions = [
      for (var i = 0; i < _arcValues.length; i++)
        _pair(_arcBase(i), ArcOptions.new),
    ];
    for (final bar in _bars) {
      bar.options = bar.active ? barOptions.active : barOptions.base;
    }
    for (final point in _points) {
      point.options = point.active ? pointOptions.active : pointOptions.base;
    }

    // controller.doughnut.js:216-217: the radius leaves room for the widest
    // border that is not inner (`getMaxBorderWidth`), the largest offset
    // (`getMaxOffset`) and the spacing. getMaxBorderWidth and getMaxOffset
    // also read `hoverBorderWidth` and `hoverOffset`, but the resolved arc
    // options hold only the keys of `ArcElement.defaults`
    // (core.datasetController.js:817), thus both are undefined: the hover
    // offset gets no room. The radius option is '100%', and the cutout is
    // '50%'.
    var maxBorderWidth = 0.0;
    var maxOffset = 0.0;
    for (final (:base, active: _) in arcOptions) {
      if (base['borderAlign'] != 'inner') {
        maxBorderWidth = math.max(
          maxBorderWidth,
          jsOrZero(base['borderWidth']),
        );
      }
      maxOffset = math.max(maxOffset, jsOrZero(base['offset']));
    }
    final room = maxBorderWidth + maxOffset + _spacing;
    final size = math.min(_doughnutArea.width, _doughnutArea.height);
    final outerRadius = math.max((size - room) / 2, 0).toDouble();
    for (var i = 0; i < _arcs.length; i++) {
      _arcs[i]
        ..options = _arcs[i].active ? arcOptions[i].active : arcOptions[i].base
        ..outerRadius = outerRadius
        ..innerRadius = outerRadius * 0.5;
    }
    final line = _line;
    if (line != null) {
      line
        ..options = LineOptions(_lineBase())
        ..points = _points;
    }
  }

  // Layout.

  /// The y pixel of [value] in the area of the bars and the line.
  double _valueY(double value) =>
      _plot.bottom - value / _maxValue * _plot.height;

  /// Makes the elements for a chart of [width] x [height] logical pixels.
  ///
  /// Below [_wideWidth], the doughnut is under the bars. From [_wideWidth],
  /// it is to the right of the bars.
  void _layout(double width, double height) {
    _sceneWidth = width;
    _sceneHeight = height;
    const pad = 12.0;
    const caption = 18.0;
    if (width >= _wideWidth) {
      final split = (width * 0.58).floorToDouble();
      _plot = Box(pad, pad + 4, split - pad, height - pad - caption);
      _doughnutArea = Box(split + pad, pad, width - pad, height - caption);
    } else {
      final split = (height * 0.5).floorToDouble();
      _plot = Box(pad, pad + 4, width - pad, split - caption);
      _doughnutArea = Box(pad, split + pad, width - pad, height - caption);
    }
    // The `layout.padding` of the doughnut: the radius leaves no room for
    // the hover offset, so the padding keeps the active arc in the canvas.
    final area = _doughnutArea;
    _doughnutArea = Box(
      area.left + _arcHoverGain,
      area.top + _arcHoverGain,
      area.right - _arcHoverGain,
      area.bottom - _arcHoverGain,
    );

    // controller.bar.js: the bars of one dataset, without a stack. The
    // ratio of `inflateAmount: 'auto'` is categoryPercentage (0.8) times
    // barPercentage (0.9), not 1, thus the amount is 0.
    final count = _barValues.length;
    final category = _plot.width / count;
    final barWidth = category * 0.8 * 0.9;
    final base = _plot.bottom;
    _bars = [
      for (var i = 0; i < count; i++)
        BarElement({
          'horizontal': false,
          'base': base,
          'enableBorderRadius': true,
          'x': _plot.left + (i + 0.5) * category,
          'y': _valueY(_barValues[i]),
          'height': (base - _valueY(_barValues[i])).abs(),
          'width': barWidth,
          'borderSkipped': _borderSkipped(
            BarElement.defaults['borderSkipped'],
          ),
          'inflateAmount': 0.0,
        }),
    ];

    // controller.line.js: the points, then the line.
    _points = [
      for (var i = 0; i < _lineValues.length; i++)
        PointElement({
          'x': _plot.left + (i + 0.5) * category,
          'y': _valueY(_lineValues[i]),
          'skip': false,
          'stop': false,
        }),
    ];
    _line = LineElement({'animated': false});

    // controller.doughnut.js: the arcs from the top, clockwise, at the
    // center of their area. [_applyOptions] sets the radii.
    final total = _arcValues.reduce((a, b) => a + b);
    final arcs = <ArcElement>[];
    var startAngle = -math.pi / 2;
    for (final value in _arcValues) {
      final circumference = value / total * 2 * math.pi;
      arcs.add(
        ArcElement({
          'x': (_doughnutArea.left + _doughnutArea.right) / 2,
          'y': (_doughnutArea.top + _doughnutArea.bottom) / 2,
          'startAngle': startAngle,
          'endAngle': startAngle + circumference,
          'circumference': circumference,
        }),
      );
      startAngle += circumference;
    }
    _arcs = arcs;

    _applyOptions();
    final hit = _hit;
    if (hit != null) _setActive(hit, active: true);
  }

  /// controller.bar.js:202 `setBorderSkipped` for a vertical bar without a
  /// stack: the skipped edges of the `borderSkipped` option [edge].
  ///
  /// Each demo value is positive. Thus no bar is reversed: `'start'` is the
  /// bottom edge and `'end'` the top edge.
  static Map<String, Object?> _borderSkipped(Object? edge) {
    if (edge == false || edge == null) return {};
    if (edge == true) {
      return {'top': true, 'right': true, 'bottom': true, 'left': true};
    }
    final name = switch (edge) {
      'start' => 'bottom',
      'end' => 'top',
      _ => '$edge',
    };
    return {name: true};
  }

  // Drawing.

  void _draw(DemoChart chart, CanvasRenderingContext2D ctx) {
    if (chart.width != _sceneWidth || chart.height != _sceneHeight) {
      _layout(chart.width, chart.height);
    }

    // The value lines of the bar and line area.
    ctx
      ..strokeStyle = 'rgba(0, 0, 0, 0.1)'
      ..lineWidth = 1
      ..beginPath();
    for (var value = 0.0; value <= _maxValue; value += 5) {
      final y = _valueY(value).roundToDouble() + 0.5;
      ctx
        ..moveTo(_plot.left, y)
        ..lineTo(_plot.right, y);
    }
    ctx.stroke();

    // The bar dataset: controller.bar.js:668-680 `draw`, each bar in index
    // order with draw(ctx), without drawActiveElementsOnTop.
    for (final bar in _bars) {
      bar.draw(ctx);
    }

    // The line dataset: controller.line.js:138 `draw`.
    final line = _line;
    if (line != null) {
      line
        ..updateControlPoints(_plot, 'x')
        ..draw(ctx, _plot);
    }
    _drawElements(ctx, _points, _plot);

    // The doughnut dataset.
    _drawElements(ctx, _arcs, null);

    drawCaption(
      ctx,
      'BarElement · LineElement · PointElement',
      (_plot.left + _plot.right) / 2,
      _plot.bottom + 18,
    );
    if (_arcs.isNotEmpty) {
      drawCaption(ctx, 'ArcElement', _arcs.first.x, chart.height - 2);
    }
  }

  /// core.datasetController.js:715-741 `draw`, the draw of the line and
  /// doughnut datasets: the elements in their order, then the active
  /// elements on top (`drawActiveElementsOnTop`).
  static void _drawElements(
    CanvasRenderingContext2D ctx,
    List<VisualElement> elements,
    ChartArea? area,
  ) {
    final active = <VisualElement>[];
    for (final element in elements) {
      if ((element as chartjs.Element).active) {
        active.add(element);
      } else {
        element.draw(ctx, area);
      }
    }
    for (final element in active) {
      element.draw(ctx, area);
    }
  }

  // Hit test.

  /// The element under the position ([x], [y]): the first element whose
  /// `inRange` gives true, from the top of the drawing down.
  _Hit? _hitTest(double x, double y) {
    for (var i = _points.length - 1; i >= 0; i--) {
      if (_points[i].inRange(x, y)) return (kind: _Kind.point, index: i);
    }
    for (var i = _bars.length - 1; i >= 0; i--) {
      if (_bars[i].inRange(x, y)) return (kind: _Kind.bar, index: i);
    }
    for (var i = _arcs.length - 1; i >= 0; i--) {
      if (_arcs[i].inRange(x, y)) return (kind: _Kind.arc, index: i);
    }
    return null;
  }

  chartjs.Element _elementOf(_Hit hit) => switch (hit.kind) {
    _Kind.bar => _bars[hit.index],
    _Kind.point => _points[hit.index],
    _Kind.arc => _arcs[hit.index],
  };

  _Options? _optionsOf(_Hit hit) => switch (hit.kind) {
    _Kind.bar => _barOptions,
    _Kind.point => _pointOptions,
    _Kind.arc => hit.index < _arcOptions.length ? _arcOptions[hit.index] : null,
  };

  /// Sets the state of the element of [hit] and gives it the options of
  /// that state.
  void _setActive(_Hit hit, {required bool active}) {
    final options = _optionsOf(hit);
    final element = _elementOf(hit)..active = active;
    if (options != null) {
      element.options = active ? options.active : options.base;
    }
  }

  /// Tests the element under the last pointer position again. Gives true
  /// when the active element changed.
  bool _updateHit() {
    final pointer = _pointer;
    final hit = pointer == null ? null : _hitTest(pointer.dx, pointer.dy);
    final old = _hit;
    if (hit == old) return false;
    if (old != null) _setActive(old, active: false);
    _hit = hit;
    if (hit != null) _setActive(hit, active: true);
    return true;
  }

  // Events.

  void _onChart(DemoChart chart) {
    _chart = chart;
    _readout.value++;
  }

  void _onResize() {
    // The elements move. The next event finds the element under the
    // pointer again.
    _pointer = null;
    _updateHit();
    _readout.value++;
  }

  void _onEvent(ChartEvent event) {
    final x = event.x;
    final y = event.y;
    _event = event.native?.type ?? event.type;
    _pointer =
        event.type == 'mouseout' ||
            x == null ||
            y == null ||
            !x.isFinite ||
            !y.isFinite
        ? null
        : Offset(x, y);
    if (_updateHit()) _chart?.render();
    _readout.value++;
  }

  /// Changes a control value. The elements get their new options, and the
  /// last pointer position is tested again, as `chart.update()` replays the
  /// last event.
  void _change(VoidCallback change) {
    setState(change);
    _applyOptions();
    _updateHit();
    _readout.value++;
  }

  // Readout.

  static String _f(double value) => value.toStringAsFixed(1);

  /// The test that gave true for the element under the pointer.
  String _testText() {
    final pointer = _pointer;
    final hit = _hit;
    if (pointer == null) return '-';
    if (hit == null) return 'no inRange gives true';
    final x = pointer.dx;
    final y = pointer.dy;
    switch (hit.kind) {
      case _Kind.point:
        final point = _points[hit.index];
        final options = point.options! as JsObjectFace;
        final distance = math.sqrt(
          math.pow(x - point.x, 2) + math.pow(y - point.y, 2),
        );
        return 'PointElement.inRange: distance ${_f(distance)} < radius '
            '${showJs(options['radius'])} + hitRadius '
            '${showJs(options['hitRadius'])}';
      case _Kind.bar:
        final bar = _bars[hit.index];
        return 'BarElement.inRange: x in [${_f(bar.x - bar.width / 2)}, '
            '${_f(bar.x + bar.width / 2)}], y in '
            '[${_f(math.min(bar.y, bar.base))}, '
            '${_f(math.max(bar.y, bar.base))}]';
      case _Kind.arc:
        final arc = _arcs[hit.index];
        final options = arc.options! as JsObjectFace;
        final adjust =
            ((options['spacing']! as double) +
                (options['borderWidth']! as double)) /
            2;
        final distance = math.sqrt(
          math.pow(x - arc.x, 2) + math.pow(y - arc.y, 2),
        );
        return 'ArcElement.inRange: angle between startAngle and endAngle, '
            'distance ${_f(distance)} in '
            '[${_f(arc.innerRadius + adjust)}, '
            '${_f(arc.outerRadius + adjust)}]';
    }
  }

  /// The options that the hover state changes for the element under the
  /// pointer.
  String _hoverText() {
    final hit = _hit;
    final options = hit == null ? null : _optionsOf(hit);
    if (options == null) return '-';
    final changed = [
      for (final key in options.active.jsKeys())
        if (options.active[key] != options.base[key])
          '$key ${showJs(options.active[key])}',
    ];
    return changed.isEmpty ? 'none' : changed.join(' · ');
  }

  Widget _buildReadout() {
    final pointer = _pointer;
    return ReadoutTable(
      key: const ValueKey('elements.hit'),
      rows: [
        ('hit', hitLabel),
        ('test', _testText()),
        ('hover options', _hoverText()),
        (
          'pointer',
          pointer == null ? 'none' : '(${_f(pointer.dx)}, ${_f(pointer.dy)})',
        ),
        ('event', _event),
      ],
    );
  }

  // Controls.

  Widget _slider(
    String name,
    double value,
    double min,
    double max,
    int divisions,
    ValueChanged<double> onChanged, {
    String Function(double value)? format,
  }) => SliderControl(
    label: name,
    sliderKey: ValueKey('elements.$name'),
    value: value,
    min: min,
    max: max,
    divisions: divisions,
    format: format,
    onChanged: (v) => _change(() => onChanged(v)),
  );

  Widget _choices(
    String name,
    List<Object> values,
    Object value,
    ValueChanged<Object> onSelected,
  ) => _Choices(
    name: name,
    values: values,
    value: value,
    onSelected: (v) => _change(() => onSelected(v)),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DemoPageBody(
      children: [
        DemoCard(
          title: 'Elements',
          source:
              'elements: BarElement · LineElement (updateControlPoints) · '
              'PointElement · ArcElement → draw(ctx, chartArea) · '
              'inRange(x, y) · getCenterPoint()',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'The ported element classes draw on the dart:ui canvas of '
                'the chart host. Move the mouse over an element, or touch '
                'it: its inRange gives true and it draws with its hover '
                'options.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) => DemoCanvas(
                  key: const ValueKey('elements.host'),
                  height: constraints.maxWidth >= _wideWidth ? 320 : 460,
                  events: elementsDemoEvents,
                  onEvent: _onEvent,
                  onChart: _onChart,
                  onResize: _onResize,
                  draw: _draw,
                ),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<int>(
                valueListenable: _readout,
                builder: (context, _, _) => _buildReadout(),
              ),
            ],
          ),
        ),
        DemoCard(
          title: 'Element options',
          source:
              'options: XElement.defaults + routed colors + control values; '
              'active: the hover keys (hoverRadius → radius)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _GroupTitle('All elements'),
              DemoControlGrid(
                children: [
                  _slider(
                    'borderWidth',
                    _borderWidth,
                    0,
                    8,
                    16,
                    (v) => _borderWidth = v,
                    format: (v) => v.toStringAsFixed(1),
                  ),
                ],
              ),
              const _GroupTitle('PointElement'),
              DemoControlGrid(
                children: [
                  _slider('radius', _radius, 0, 16, 32, (v) => _radius = v),
                  _slider(
                    'hoverRadius',
                    _hoverRadius,
                    0,
                    20,
                    20,
                    (v) => _hoverRadius = v,
                  ),
                  _slider(
                    'rotation',
                    _rotation,
                    0,
                    360,
                    72,
                    (v) => _rotation = v,
                    format: (v) => '${v.toStringAsFixed(0)}°',
                  ),
                ],
              ),
              _choices(
                'pointStyle',
                _pointStyles,
                _pointStyle,
                (v) => _pointStyle = v as String,
              ),
              const _GroupTitle('LineElement'),
              DemoControlGrid(
                children: [
                  _slider(
                    'tension',
                    _tension,
                    0,
                    1,
                    20,
                    (v) => _tension = v,
                    format: (v) => v.toStringAsFixed(2),
                  ),
                ],
              ),
              _choices(
                'stepped',
                _steppedValues,
                _stepped,
                (v) => _stepped = v,
              ),
              const _GroupTitle('BarElement'),
              DemoControlGrid(
                children: [
                  _slider(
                    'borderRadius',
                    _borderRadius,
                    0,
                    24,
                    24,
                    (v) => _borderRadius = v,
                  ),
                ],
              ),
              const _GroupTitle('ArcElement'),
              DemoControlGrid(
                children: [
                  _slider('spacing', _spacing, 0, 20, 20, (v) => _spacing = v),
                  _slider('offset', _offset, 0, 40, 20, (v) => _offset = v),
                ],
              ),
              _choices(
                'borderAlign',
                _borderAlignValues,
                _borderAlign,
                (v) => _borderAlign = v,
              ),
              const SizedBox(height: 8),
              _choices(
                'borderJoinStyle',
                _borderJoinStyleValues,
                _borderJoinStyle,
                (v) => _borderJoinStyle = v,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The heading of a group of controls.
class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

/// A labelled row of choice chips for the option [name].
///
/// The row has the key `elements.<name>`, and each chip has the key
/// `elements.<name>.<value>`.
class _Choices extends StatelessWidget {
  const _Choices({
    required this.name,
    required this.values,
    required this.value,
    required this.onSelected,
  });

  final String name;
  final List<Object> values;
  final Object value;
  final ValueChanged<Object> onSelected;

  /// The text of [value]: `undefined` for the sentinel.
  static String _text(Object value) =>
      value is Undefined ? 'undefined' : '$value';

  @override
  Widget build(BuildContext context) {
    return Row(
      key: ValueKey('elements.$name'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(name, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final v in values)
                ChoiceChip(
                  key: ValueKey('elements.$name.${_text(v)}'),
                  label: Text(_text(v)),
                  selected: v == value,
                  onSelected: (_) => onSelected(v),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
