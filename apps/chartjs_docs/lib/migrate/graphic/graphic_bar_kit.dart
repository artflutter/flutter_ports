// Original code, not ported from Chart.js: the Graphic parts of the bar replicas.
// ignore_for_file: lines_longer_than_80_chars
// #docregion graphic-bar-kit
import 'package:chartjs_docs/migrate/graphic/graphic_kit.dart';
import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart'
    show Mode, ModifierKey, ZoomChart;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

/// The width of a bar of an `IntervalMark`: `IntervalShape.defaultSize`.
const double barSize = 15;

/// The font of the bar labels: the 10 px text of Graphic, in the font of the
/// axis labels.
const TextStyle labelFont = TextStyle(
  fontFamily: 'Helvetica Neue',
  fontFamilyFallback: ['Helvetica', 'Arial', 'sans-serif'],
  fontSize: 10,
);

/// An `afterBuildTicks` hook that puts the ticks of an axis at [values].
/// With `min`, `max` and a `stepSize` that almost fit, Chart.js spreads the
/// ticks over the whole range: these ticks stay where Graphic puts them.
ScaleHook tickValues(List<double> values) =>
    (scale) => scale.ticks = [for (final value in values) Tick(value: value)];

/// The end of each selected bar is its `representPoint` in Graphic. The
/// tooltip and the crosshair stand at the mean of these points.
Offset _meanEnd(List<ActiveElement> items) {
  var sum = Offset.zero;
  for (final item in items) {
    final bar = item.element!;
    sum += Offset(bar.x, bar.y);
  }
  return sum / items.length.toDouble();
}

/// `TooltipGuide()` with no `anchor` and no `align`: the tooltip is centered
/// on the end of the selected bars.
final class const CenterPositioner() extends TooltipPositioner {
  /// The positioner.
  this;

  @override
  TooltipPosition? positionOf(
    TooltipModel tooltip,
    List<ActiveElement> items,
    Object? eventPosition,
  ) {
    if (items.isEmpty) return null;
    final end = _meanEnd(items);
    return TooltipPosition()
      ..x = end.dx
      ..y = end.dy
      ..xAlign = TooltipXAlign.center
      ..yAlign = TooltipYAlign.center;
  }
}

/// `CrosshairGuide()`: gray lines through the end of the selected bars.
final barCrosshair = Plugin<Object?>(
  id: 'barCrosshair',
  afterDatasetsDraw: (chart, args, options) {
    final active = (chart as Chart).getActiveElements();
    if (active.isEmpty) return;
    final area = chart.chartArea!;
    final end = _meanEnd(active);
    final x = end.dx.clamp(area.left, area.right);
    final y = end.dy.clamp(area.top, area.bottom);
    chart.ctx!
      ..save()
      ..strokeStyle = Gx.crosshair
      ..lineWidth = 1
      ..beginPath()
      ..moveTo(x, area.top)
      ..lineTo(x, area.bottom)
      ..moveTo(area.left, y)
      ..lineTo(area.right, y)
      ..stroke()
      ..restore();
  },
);

/// `LabelEncode` of an `IntervalMark`: the [text] of each bar at [position]
/// of the bar, from its start (0) to its end (1). At the end, the label
/// stands above a bar, or right of a horizontal bar. Else it is centered.
Plugin<Object?> barLabels(
  String Function(int datasetIndex, int index) text, {
  double position = 1,
  TextStyle font = labelFont,
  Color color = Gx.text,
}) => Plugin(
  id: 'barLabels',
  afterDatasetsDraw: (chart, args, options) {
    chart as Chart;
    final ctx = chart.ctx!
      ..save()
      ..font = font
      ..fillStyle = color;
    for (final meta in chart.getSortedVisibleDatasetMetas()) {
      for (final (index, element) in meta.data.indexed) {
        if (element is! BarElement || !chart.getDataVisibility(index)) {
          continue;
        }
        final horizontal = element.horizontal ?? false;
        final start = horizontal
            ? Offset(element.base, element.y)
            : Offset(element.x, element.base);
        final anchor = Offset.lerp(
          start,
          Offset(element.x, element.y),
          position,
        )!;
        if (position < 1) {
          ctx
            ..textAlign = TextAlign.center
            ..textBaseline = CanvasTextBaseline.middle;
        } else if (horizontal) {
          ctx
            ..textAlign = TextAlign.left
            ..textBaseline = CanvasTextBaseline.middle;
        } else {
          ctx
            ..textAlign = TextAlign.center
            ..textBaseline = CanvasTextBaseline.bottom;
        }
        ctx.fillText(text(meta.index, index), anchor.dx, anchor.dy);
      }
    }
    ctx.restore();
  },
);

/// The canvas shadow of a Flutter elevation, close to `Canvas.drawShadow`:
/// Graphic casts the shadow in a dark tone of the color of the shape.
void _castShadow(CanvasRenderingContext2D ctx, double elevation, Color color) =>
    ctx
      ..shadowColor = Color.lerp(
        color,
        const Color(0xFF000000),
        0.6,
      )!.withValues(alpha: 0.4)
      ..shadowBlur = elevation * 1.6
      ..shadowOffsetY = elevation * 0.4;

/// `ElevationEncode` with a `tap` updater: the selected vertical bars cast
/// the shadow of [elevation]. The shadow takes the [color] of the bars.
Plugin<Object?> selectedElevation({
  required Color color,
  double elevation = 5,
}) => Plugin(
  id: 'selectedElevation',
  beforeDatasetDraw: (chart, args, options) {
    final area = chart.chartArea!;
    final ctx = chart.ctx!;
    for (final item in (chart as Chart).getActiveElements()) {
      if (item.datasetIndex != args.index) continue;
      final bar = item.element! as BarElement;
      final half = bar.width / 2;
      // The marks of Graphic stay in the region: so does the shadow.
      final rect = Rect.fromLTRB(
        bar.x - half,
        bar.y,
        bar.x + half,
        bar.base,
      ).intersect(Rect.fromLTRB(area.left, area.top, area.right, area.bottom));
      ctx.save();
      _castShadow(ctx, elevation, color);
      ctx
        ..fillStyle = color
        ..fillRect(rect.left, rect.top, rect.width, rect.height)
        ..restore();
    }
    return true;
  },
);

/// The shadow of a tooltip window of [color] at [elevation].
Plugin<Object?> tooltipElevation({
  required Color color,
  required double elevation,
}) => Plugin(
  id: 'tooltipElevation',
  beforeTooltipDraw: (chart, args, options) {
    final tip = args.tooltip;
    final ctx = chart.ctx!
      ..save()
      ..globalAlpha = tip.opacity;
    _castShadow(ctx, elevation, color);
    ctx
      ..fillStyle = color
      ..beginPath()
      ..roundRect(tip.x, tip.y, tip.width, tip.height, 3)
      ..fill()
      ..restore();
    return true;
  },
);

/// The time of the last tap of each chart.
final Expando<DateTime> _lastTaps = Expando('last tap');

/// The selection of each chart after its last event.
final Expando<List<ActiveElement>> _selections = Expando('selection');

bool _sameSelection(List<ActiveElement>? a, List<ActiveElement> b) {
  if (a == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].datasetIndex != b[i].datasetIndex || a[i].index != b[i].index) {
      return false;
    }
  }
  return true;
}

/// The `clear` gesture of a Graphic selection: a double tap clears it, and
/// calls [onDoubleTap]. With [refresh], a new selection updates the chart,
/// so that the options of all the bars resolve again: an encode `updaters`
/// that changes the bars that are not selected.
Plugin<Object?> tapSelection({
  bool refresh = false,
  void Function(Chart chart)? onDoubleTap,
}) => Plugin(
  id: 'tapSelection',
  afterEvent: (chart, args, options) {
    chart as Chart;
    if (args.event.type == 'click') {
      final now = DateTime.now();
      final last = _lastTaps[chart];
      _lastTaps[chart] = now;
      if (last != null && now.difference(last) < kDoubleTapTimeout) {
        _lastTaps[chart] = null;
        chart.setActiveElements(const []);
        chart.tooltip?.setActiveElements(const []);
        onDoubleTap?.call(chart);
        args.changed = true;
      }
    }
    final selection = chart.getActiveElements();
    if (refresh && !_sameSelection(_selections[chart], selection)) {
      _selections[chart] = selection;
      chart.update('none');
    }
  },
);

/// `RectCoord(horizontalRangeUpdater: Defaults.horizontalRangeEvent)`: the
/// zoom and the pan of the x axis, with the port of chartjs-plugin-zoom. A
/// chart gives `zoomPlugin` in `plugins` and these options in `extra`. The
/// wheel zooms with the Ctrl key, so that the wheel still scrolls the page.
const Map<String, Object?> horizontalRange = {
  'plugins': {
    'zoom': {
      'zoom': {
        'wheel': {'enabled': true, 'modifierKey': ModifierKey.ctrl},
        'pinch': {'enabled': true},
        'mode': Mode.x,
      },
      'pan': {'enabled': true, 'mode': Mode.x},
    },
  },
};

/// A double tap puts back the first range, as in Graphic.
void resetRange(Chart chart) => chart.resetZoom();
// #enddocregion graphic-bar-kit
