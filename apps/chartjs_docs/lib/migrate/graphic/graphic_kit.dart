// Original code, not ported from Chart.js: the Graphic parts of the replicas.
// ignore_for_file: public_member_api_docs
// #docregion graphic-kit
import 'dart:math' as math;

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

/// The colors of `Defaults` of Graphic.
abstract final class Gx() {
  static const primary = Color(0xff1890ff);
  static const stroke = Color(0xffe8e8e8);
  static const text = Color(0xff808080);
  static const crosshair = Color(0xffbfbfbf);
  static const tooltipText = Color(0xff595959);
  static const tooltipBackground = Color(0xf0ffffff);
  static const colors10 = [
    Color(0xff5b8ff9),
    Color(0xff5ad8a6),
    Color(0xff5d7092),
    Color(0xfff6bd16),
    Color(0xff6f5ef9),
    Color(0xff6dc8ec),
    Color(0xff945fb9),
    Color(0xffff9845),
    Color(0xff1e9493),
    Color(0xffff99c3),
  ];
}

/// A Graphic chart is 350 x 300 in the demos.
Widget graphicBox(Widget chart) => Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 350),
    child: SizedBox(height: 300, child: chart),
  ),
);

/// The axis labels of Graphic: gray text of 10 px, 7.5 px from the axis.
AxisTicks graphicTicks({
  TickCallback? callback,
  double? stepSize,
  TickSource? source,
  Map<String, Object?> extra = const {},
}) => AxisTicks(
  color: const ChartPaint.solid(Gx.text),
  font: const TextStyle(fontSize: 10),
  padding: 7.5,
  maxRotation: 0,
  autoSkip: false,
  stepSize: stepSize,
  source: source,
  callback: callback,
  // The ticks at the ends of the range are not round numbers: Graphic
  // shows only the round ones.
  extra: {'includeBounds': false, ...extra},
);

/// The labels of a linear scale of Graphic: the Dart text of a double.
List<String>? numberLabel(
  Scale scale,
  double value,
  int index,
  List<Tick> ticks,
) => [value.toString()];

/// The horizontal axis of Graphic: a line, no grid, 20 px below the region.
const Map<String, Object?> bottomAxis = {
  'border': {'color': ChartPaint.solid(Gx.stroke)},
  'afterFit': _fitBottom,
};

/// The vertical axis of Graphic: a grid, no line, 40 px left of the region.
const Map<String, Object?> leftAxis = {
  'border': {'display': false},
  'afterFit': _fitLeft,
};

/// Graphic lets the labels at the ends overflow the region: no padding.
void _fitBottom(Scale scale) => scale
  ..height = 20
  ..paddingLeft = 0
  ..paddingRight = 0;

void _fitLeft(Scale scale) => scale
  ..width = 40
  ..paddingTop = 0
  ..paddingBottom = 0;

const AxisGrid noGrid = AxisGrid(display: false, drawTicks: false);

const AxisGrid lineGrid = AxisGrid(
  color: ChartPaint.solid(Gx.stroke),
  drawTicks: false,
);

/// The region of Graphic sits 5 px below the top and 10 px left of the
/// right edge.
const EdgeInsets regionPadding = EdgeInsets.only(top: 5, right: 10);

/// The range of a linear scale of Graphic: the range of the data with 10%
/// more on each side.
({double min, double max}) graphicRange(Iterable<num> values) {
  final finite = [
    for (final value in values)
      if (value.isFinite) value.toDouble(),
  ];
  final low = finite.reduce(math.min);
  final high = finite.reduce(math.max);
  final margin = (high - low) * 0.1;
  return (min: low - margin, max: high + margin);
}

/// Whether an `OrdinalScale(tickCount: count)` of Graphic labels the value
/// at [index] of [length] values: a regular step, centered in the list.
bool ordinalTick(int index, int length, int count) {
  final step = (length / count).ceil();
  final first = ((length - 1) % step) ~/ 2;
  return index >= first && (index - first) % step == 0;
}

/// The tooltip window of Graphic: a white box with 12 px gray text.
ChartTooltip graphicTooltip({
  required TooltipPositioner position,
  String? Function(List<TooltipItem> items)? title,
  String? Function(TooltipItem item)? label,
  TooltipItemFilter? filter,
  Map<String, Object?> extra = const {},
}) => ChartTooltip(
  backgroundColor: const ChartPaint.solid(Gx.tooltipBackground),
  titleColor: const ChartPaint.solid(Gx.tooltipText),
  titleFont: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
  bodyColor: const ChartPaint.solid(Gx.tooltipText),
  bodyFont: const TextStyle(fontSize: 12),
  padding: const EdgeInsets.all(5),
  cornerRadius: _radius,
  displayColors: false,
  position: position,
  filter: filter,
  extra: {
    'caretSize': 0,
    'caretPadding': 0,
    'titleMarginBottom': 0,
    'titleSpacing': 0,
    'bodySpacing': 0,
    // No title line unless [title] gives one.
    if (title == null) 'callbacks': const TooltipCallbacks(title: _noTitle),
    ...extra,
  },
  callbacks: TooltipCallbacks(
    title: (tooltip, arg) {
      final text = title?.call(arg);
      return text == null
          ? null
          : text.isEmpty
          ? <String>[]
          : [text];
    },
    label: (tooltip, arg) {
      final text = label?.call(arg);
      return text == null
          ? null
          : text.isEmpty
          ? <String>[]
          : [text];
    },
  ),
);

const double _radius = 3;

List<String> _noTitle(TooltipModel tooltip, List<TooltipItem> items) =>
    const [];

/// The tooltip of Graphic has a shadow (`elevation: 3`).
final Map<String, Object?> tooltipShadow = {
  'id': 'tooltipShadow',
  'beforeTooltipDraw': (Chart chart, Object? args, Object? options) {
    final tip = chart.tooltip!;
    chart.ctx!
      ..save()
      ..globalAlpha = tip.opacity
      ..shadowColor = const Color(0x40000000)
      ..shadowBlur = 6
      ..shadowOffsetY = 2
      ..fillStyle = Gx.tooltipBackground
      ..fillRect(tip.x, tip.y, tip.width, tip.height)
      ..restore();
  },
};

/// The pointer of the event position of a positioner: a chart event or an
/// object with `x` and `y`. `null` for a selection without an event.
Offset? _pointer(Object? position) => switch (position) {
  ChartEvent(:final x?, :final y?) => Offset(x, y),
  final JsObjectFace face => switch ((face['x'], face['y'])) {
    (final num x, final num y) => Offset(x.toDouble(), y.toDouble()),
    _ => null,
  },
  _ => null,
};

/// `followPointer: [false, true]`, `align: topLeft`, `offset: (-20, -20)`:
/// the bottom right corner 20 px left of the point and 20 px above the
/// pointer.
final class const FollowYPositioner() extends TooltipPositioner {
  /// The positioner.
  this;

  @override
  TooltipPosition? positionOf(
    TooltipModel tooltip,
    List<ActiveElement> items,
    Object? eventPosition,
  ) {
    if (items.isEmpty) return null;
    final element = items.first.element!;
    return TooltipPosition()
      ..x = element.x - 20 - _radius
      ..y = (_pointer(eventPosition)?.dy ?? element.y) - 20
      ..xAlign = TooltipXAlign.right
      ..yAlign = TooltipYAlign.bottom;
  }
}

/// `followPointer: [true, true]`, `align: topLeft`: the bottom right corner
/// at the pointer.
final class const AtPointerPositioner() extends TooltipPositioner {
  /// The positioner.
  this;

  @override
  TooltipPosition? positionOf(
    TooltipModel tooltip,
    List<ActiveElement> items,
    Object? eventPosition,
  ) {
    final pointer = _pointer(eventPosition);
    if (items.isEmpty || pointer == null) return null;
    return TooltipPosition()
      ..x = pointer.dx - _radius
      ..y = pointer.dy
      ..xAlign = TooltipXAlign.right
      ..yAlign = TooltipYAlign.bottom;
  }
}

/// `anchor: (_) => Offset.zero`, `align: bottomRight`: the top left corner
/// of the chart.
final class const TopLeftPositioner() extends TooltipPositioner {
  /// The positioner.
  this;

  @override
  TooltipPosition? positionOf(
    TooltipModel tooltip,
    List<ActiveElement> items,
    Object? eventPosition,
  ) {
    if (items.isEmpty) return null;
    return TooltipPosition()
      ..x = 0
      ..y = 0
      ..xAlign = TooltipXAlign.left
      ..yAlign = TooltipYAlign.top;
  }
}

/// The last pointer position of each chart, `null` after the pointer left.
final Expando<Offset> _pointers = Expando('graphic pointer');

void _trackPointer(Chart chart, Object? args, Object? options) {
  final event = (args! as JsObjectFace)['event']! as ChartEvent;
  _pointers[chart] = event.type == 'mouseout'
      ? null
      : Offset(event.x ?? 0, event.y ?? 0);
}

/// The `CrosshairGuide` of Graphic: gray lines through the selected point.
/// With [followX] or [followY], a line follows the pointer instead.
Map<String, Object?> crosshair({
  bool followX = false,
  bool followY = true,
  bool vertical = true,
  bool horizontal = true,
}) => {
  'id': 'crosshair',
  'afterEvent': _trackPointer,
  'afterDatasetsDraw': (Chart chart, Object? args, Object? options) {
    final active = chart.getActiveElements();
    if (active.isEmpty) return;
    final area = chart.chartArea!;
    final element = active.first.element!;
    final pointer = _pointers[chart] ?? Offset(element.x, element.y);
    final x = followX ? pointer.dx : element.x;
    final y = (followY ? pointer.dy : element.y).clamp(area.top, area.bottom);
    final ctx = chart.ctx!
      ..save()
      ..strokeStyle = Gx.crosshair
      ..lineWidth = 1
      ..beginPath();
    if (vertical) {
      ctx
        ..moveTo(x, area.top)
        ..lineTo(x, area.bottom);
    }
    if (horizontal) {
      ctx
        ..moveTo(area.left, y)
        ..lineTo(area.right, y);
    }
    ctx
      ..stroke()
      ..restore();
  },
};

/// The `CrosshairGuide` of Graphic in a `PolarCoord`: a spoke through the
/// selected index and a circle through the pointer.
final Map<String, Object?> polarCrosshair = {
  'id': 'polarCrosshair',
  'afterEvent': _trackPointer,
  'afterDatasetsDraw': (Chart chart, Object? args, Object? options) {
    final active = chart.getActiveElements();
    if (active.isEmpty) return;
    final scale = chart.scales['r']! as RadialLinearScale;
    final center = Offset(scale.xCenter!, scale.yCenter!);
    final element = active.first.element!;
    final pointer = _pointers[chart] ?? Offset(element.x, element.y);
    final radius = math.min((pointer - center).distance, scale.drawingArea);
    final end = scale.getPointPosition(
      active.first.index.toDouble(),
      scale.drawingArea,
    );
    chart.ctx!
      ..save()
      ..strokeStyle = Gx.crosshair
      ..lineWidth = 1
      ..beginPath()
      ..moveTo(center.dx, center.dy)
      ..lineTo(end.x, end.y)
      ..moveTo(center.dx + radius, center.dy)
      ..arc(center.dx, center.dy, radius, 0, 2 * math.pi)
      ..stroke()
      ..restore();
  },
};

/// `RectCoord(color: ...)`: a background color of the region.
Map<String, Object?> regionColor(Color color) => {
  'id': 'regionColor',
  'beforeDraw': (Chart chart, Object? args, Object? options) {
    final area = chart.chartArea!;
    chart.ctx!
      ..save()
      ..fillStyle = color
      ..fillRect(area.left, area.top, area.width, area.height)
      ..restore();
  },
};
// #enddocregion graphic-kit
