// Original code, not ported from Chart.js: the Syncfusion parts of the column and bar replicas.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion sf-bar-kit
import 'dart:math' as math;

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

/// The colors of the Syncfusion light Material 3 theme.
abstract final class Sf() {
  // The first five colors of the series palette.
  static const blue = Color.fromRGBO(6, 174, 224, 1);
  static const purple = Color.fromRGBO(99, 85, 199, 1);
  static const slate = Color.fromRGBO(49, 90, 116, 1);
  static const amber = Color.fromRGBO(255, 180, 0, 1);
  static const plum = Color.fromRGBO(150, 60, 112, 1);
  static const text = Color(0xFF49454F);
  static const axisLine = Color(0xFFCAC4D0);
  static const grid = Color(0xFFE6E0E9);
  static const tooltip = Color(0xFF322F35);
  static const tooltipText = Color(0xFFF5EFF7);
}

/// The labels of the axes: `bodySmall` of Material 3.
const TextStyle sfLabelFont = TextStyle(fontSize: 12, letterSpacing: 0.4);

/// The margin of 10 px around the chart. Chart.js puts the tick padding of
/// an axis on both sides of its labels: the left and the bottom margins
/// take that part back.
const EdgeInsets sfPadding = EdgeInsets.fromLTRB(4, 10, 10, 5);

/// `ChartTitle(text: ...)`: the title over the plot area.
ChartTitle sfTitle(String text) => ChartTitle(
  display: true,
  text: [text],
  color: const .solid(Sf.text),
  font: const TextStyle(
    fontSize: 18,
    letterSpacing: 0.25,
    fontWeight: FontWeight.normal,
  ),
  padding: const EdgeInsets.only(top: 3, bottom: 12),
);

/// `AxisTitle(text: ...)`.
AxisTitle sfAxisTitle(String text) => AxisTitle(
  display: true,
  text: [text],
  color: const .solid(Sf.text),
  font: const TextStyle(
    fontSize: 15,
    letterSpacing: 0.25,
    fontWeight: FontWeight.normal,
  ),
  padding: const EdgeInsets.only(top: 6),
);

/// A `CategoryAxis` of Syncfusion: an axis line and tick marks between the
/// categories, no grid lines.
CategoryAxis sfCategoryAxis({
  CartesianAxis direction = .x,
  bool reverse = false,
  TickCallback? callback,
}) => CategoryAxis(
  direction,
  reverse: reverse,
  grid: const AxisGrid(
    drawOnChartArea: false,
    color: .solid(Sf.axisLine),
    offset: true,
    tickLength: 5,
  ),
  ticks: AxisTicks(
    color: const .solid(Sf.text),
    font: sfLabelFont,
    padding: 5,
    maxRotation: 0,
    callback: callback,
  ),
  border: const AxisBorder(color: ChartPaint.solid(Sf.axisLine)),
);

/// A `NumericAxis` of Syncfusion. [grid], [line] and [ticks] are the
/// `majorGridLines`, the `axisLine` and the `majorTickLines`.
LinearAxis sfValueAxis({
  CartesianAxis direction = .y,
  double? min,
  double? max,
  double? stepSize,
  TickCallback? callback,
  bool grid = true,
  bool line = false,
  bool ticks = false,
  String? title,
}) => LinearAxis(
  direction,
  min: min,
  max: max,
  grid: AxisGrid(
    display: grid || ticks,
    color: const .solid(Sf.grid),
    lineWidth: 0.7,
    drawOnChartArea: grid,
    drawTicks: ticks,
    offset: false,
    tickLength: 5,
    extra: const {'tickColor': ChartPaint.solid(Sf.axisLine)},
  ),
  ticks: AxisTicks(
    stepSize: stepSize,
    color: const .solid(Sf.text),
    font: sfLabelFont,
    padding: ticks ? 5 : 8,
    maxRotation: 0,
    callback: callback ?? sfNumberTick,
  ),
  border: AxisBorder(display: line, color: const .solid(Sf.axisLine)),
  title: title == null ? null : sfAxisTitle(title),
  // The ends of the range sit on the ends of the axis, also when the axis is
  // the index axis of the bars.
  extra: const {'offset': false},
);

/// A number as Syncfusion shows it: no `.0` and no float noise.
String sfNumber(num value) {
  final rounded = (value * 1000).round() / 1000;
  return rounded == rounded.roundToDouble() ? '${rounded.round()}' : '$rounded';
}

/// `NumberFormat.compact()` for the values of the demos: 65M, 68.2M.
String sfCompact(num value) {
  const units = [(1e9, 'B'), (1e6, 'M'), (1e3, 'K')];
  for (final (size, unit) in units) {
    if (value.abs() >= size) {
      // Three digits, with no zeros at the end: 65M, 68.2M.
      var text = (value / size).toStringAsPrecision(3);
      if (text.contains('.')) text = text.replaceFirst(RegExp(r'\.?0+$'), '');
      return '$text$unit';
    }
  }
  return sfNumber(value);
}

List<String>? sfNumberTick(Scale scale, double v, int i, List<Tick> t) => [
  sfNumber(v),
];

List<String>? sfPercentTick(Scale scale, double v, int i, List<Tick> t) => [
  '${sfNumber(v)}%',
];

List<String>? sfCompactTick(Scale scale, double v, int i, List<Tick> t) => [
  sfCompact(v),
];

/// The value of a tooltip item: the raw number of the data.
num sfValue(TooltipItem item) => item.raw! as num;

/// `TooltipBehavior(enable: true)`. With [header], the tooltip shows the
/// series name, a line and a marker, as the default of Syncfusion. Without
/// it, it is `header: ''` and `canShowMarker: false`. The label callback
/// closes over [text]: a replica builds the options once, in a top-level
/// final, so they stay `==` across builds.
TooltipOptions sfTooltip({
  required String Function(TooltipItem item) text,
  bool header = false,
  InteractionMode? mode,
  TooltipItemFilter? filter,
}) => TooltipOptions(
  mode: mode,
  filter: filter,
  backgroundColor: const .solid(Sf.tooltip),
  titleColor: const .solid(Sf.tooltipText),
  titleFont: const TextStyle(
    fontSize: 12,
    letterSpacing: 0.4,
    fontWeight: FontWeight.bold,
  ),
  bodyColor: const .solid(Sf.tooltipText),
  bodyFont: sfLabelFont,
  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
  cornerRadius: const BorderRadius.all(Radius.circular(5)),
  displayColors: header,
  position: const SfTipPositioner(),
  yAlign: .bottom,
  caretSize: 6,
  caretPadding: 0,
  titleAlign: TextAlign.center,
  titleMarginBottom: 11,
  usePointStyle: true,
  boxPadding: 4,
  callbacks: TooltipCallbacks(
    title: header ? _seriesTitle : _noHeader,
    label: (tooltip, item) => [text(item)],
    labelColor: _marker,
    labelPointStyle: _circleMarker,
  ),
);

List<String> _seriesTitle(TooltipModel tooltip, List<TooltipItem> items) => [
  items.first.datasetLabel ?? '',
];

List<String> _noHeader(TooltipModel tooltip, List<TooltipItem> items) =>
    const [];

TooltipLabelPointStyle _circleMarker(TooltipModel tooltip, TooltipItem item) =>
    const .draw(CirclePointStyle());

// The marker: a circle of the series color with a white border.
TooltipLabelStyle _marker(TooltipModel tooltip, TooltipItem item) {
  final bar = item.element! as BarElement;
  return TooltipLabelStyle(
    borderColor: const .solid(Colors.white),
    backgroundColor: (bar.options! as BarOptions).backgroundColor!,
  );
}

/// The tooltip of Syncfusion points at the value end of a column, also of a
/// negative one, and at the middle of a horizontal bar, from above.
final class const SfTipPositioner() extends TooltipPositioner {
  @override
  TooltipPosition? positionOf(
    TooltipModel tooltip,
    List<ActiveElement> items,
    Object? eventPosition,
  ) {
    if (items.isEmpty) return null;
    final bar = items.first.element! as BarElement;
    final horizontal = bar.horizontal ?? false;
    return TooltipPosition()
      ..x = horizontal ? (bar.x + bar.base) / 2 : bar.x
      ..y = horizontal ? bar.y - bar.height / 2 : bar.y
      ..xAlign = .center
      ..yAlign = .bottom;
  }
}

/// The shadow of the tooltip, and the line under its header.
final sfTooltipLook = Plugin<Object?>(
  id: 'sfTooltipLook',
  beforeTooltipDraw: (chart, args, options) {
    final tip = args.tooltip;
    if (tip.opacity == 0) return true;
    chart.ctx!
      ..save()
      ..globalAlpha = tip.opacity
      ..shadowColor = const Color(0x40000000)
      ..shadowBlur = 6
      ..shadowOffsetY = 2
      ..fillStyle = Sf.tooltip
      ..beginPath()
      ..roundRect(tip.x, tip.y, tip.width, tip.height, 5)
      ..fill()
      ..restore();
    return true;
  },
  afterTooltipDraw: (chart, args, options) {
    final tip = args.tooltip;
    if ((tip.title ?? const []).isEmpty || tip.opacity == 0) return;
    // padding 7, one title line of 12 * 1.2, half of titleMarginBottom.
    final y = tip.y + 7 + 14.4 + 5.5;
    chart.ctx!
      ..save()
      ..globalAlpha = tip.opacity * 0.6
      ..strokeStyle = Sf.tooltipText
      ..lineWidth = 0.5
      ..beginPath()
      ..moveTo(tip.x + 6, y)
      ..lineTo(tip.x + tip.width - 6, y)
      ..stroke()
      ..restore();
  },
);

/// The `plotAreaBorderWidth` of a chart that keeps it: a thin frame.
final sfPlotBorder = Plugin<Object?>(
  id: 'sfPlotBorder',
  beforeDatasetsDraw: (chart, args, options) {
    final area = chart.chartArea!;
    chart.ctx!
      ..save()
      ..strokeStyle = Sf.grid
      ..lineWidth = 0.7
      ..strokeRect(area.left, area.top, area.width, area.height)
      ..restore();
    return true;
  },
);

/// Where `DataLabelSettings` puts a label: past the end of the bar
/// (`outer`, the default), inside the end (`top`), in the middle, or inside
/// the base.
enum SfLabelAlign() {
  outer,
  top,
  middle,
  bottom,
}

/// `DataLabelSettings(isVisible: true)` of the first series: [texts] has one
/// label for each bar. A label inside a bar takes black or white, whichever
/// stands out from [fills], the colors of the bars. Syncfusion shows the
/// labels after the animation.
Plugin<Object?> sfDataLabels(
  List<String> texts, {
  String id = 'sfDataLabels',
  SfLabelAlign align = .outer,
  double fontSize = 12,
  List<Color> fills = const [Sf.blue],
  Color? color,
}) => Plugin(
  id: id,
  afterDatasetsDraw: (chart, args, options) {
    final c = chart as Chart;
    if (!c.isDatasetVisible(0)) return;
    // The default family of the chart, with the size of the label.
    final font = toFont(TextStyle(fontSize: fontSize, letterSpacing: 0.4));
    final ctx = c.ctx!
      ..save()
      ..font = font
      ..textAlign = TextAlign.center
      ..textBaseline = CanvasTextBaseline.middle;
    final bars = c.getDatasetMeta(0).data;
    for (final (i, element) in bars.indexed) {
      final bar = element as BarElement;
      final end = bar.tooltipPosition(true);
      if (end.dx != bar.x || end.dy != bar.y || i >= texts.length) continue;
      final horizontal = bar.horizontal ?? false;
      final text = texts[i];
      // The size of the label along the bar, with a margin of 5 on each
      // side, and a gap of 5 from the end of the bar.
      final size = horizontal
          ? ctx.measureText(text).width
          : font.lineHeight ?? fontSize * 1.2;
      final gap = 5 + (size + 10) / 2;
      final tip = horizontal ? bar.x : bar.y;
      final direction = tip >= bar.base ? 1 : -1;
      final at = switch (align) {
        .outer => tip + direction * gap,
        .top => tip - direction * gap,
        .middle => (tip + bar.base) / 2,
        .bottom => bar.base + direction * (size / 2 + 4),
      };
      final fill = fills[i % fills.length];
      ctx
        ..fillStyle =
            color ?? (align == .outer ? Colors.black : sfContrast(fill))
        ..fillText(text, horizontal ? at : bar.x, horizontal ? bar.y : at);
    }
    ctx.restore();
  },
);

/// The text color of Syncfusion on [fill]: black on a light color, white on
/// a dark one.
Color sfContrast(Color fill) {
  final brightness =
      (fill.r * 255 * 299 + fill.g * 255 * 587 + fill.b * 255 * 114) / 1000;
  return brightness.round() >= 128 ? Colors.black : Colors.white;
}

/// `isTrackVisible: true` and `trackColor`: a bar of [color] behind each bar
/// of the first series, over the whole value axis, with [radius] corners.
Plugin<Object?> sfTrack({
  Color color = const Color.fromRGBO(198, 201, 207, 1),
  double radius = 0,
}) => Plugin(
  id: 'sfTrack',
  beforeDatasetsDraw: (chart, args, options) {
    final c = chart as Chart;
    final ctx = c.ctx!
      ..save()
      ..fillStyle = color;
    final area = c.chartArea!;
    for (final element in c.getDatasetMeta(0).data) {
      final bar = element as BarElement;
      ctx.beginPath();
      if (bar.horizontal ?? false) {
        final r = math.min<double>(radius, bar.height / 2);
        ctx.roundRect(
          area.left,
          bar.y - bar.height / 2,
          area.width,
          bar.height,
          r,
        );
      } else {
        final r = math.min<double>(radius, bar.width / 2);
        ctx.roundRect(
          bar.x - bar.width / 2,
          area.top,
          bar.width,
          area.height,
          r,
        );
      }
      ctx.fill();
    }
    ctx.restore();
    return true;
  },
);

/// The legend icon of a `ColumnSeries`: three columns.
final class const SfColumnIcon() extends PathPointStyle {
  @override
  void addPath(
    CanvasRenderingContext2D ctx, {
    required double x,
    required double y,
    required double radius,
    required double rad,
    required bool rotated,
    required double? width,
  }) {
    final size = radius * math.sqrt2;
    final left = x - size / 2;
    final bottom = y + size / 2;
    final bar = size * 0.24;
    final gap = (size - 3 * bar) / 2;
    for (final (i, height) in const [0.6, 1.0, 0.4].indexed) {
      ctx.rect(
        left + i * (bar + gap),
        bottom - size * height,
        bar,
        size * height,
      );
    }
  }
}

/// The legend icon of a `BarSeries`: three bars.
final class const SfBarIcon() extends PathPointStyle {
  @override
  void addPath(
    CanvasRenderingContext2D ctx, {
    required double x,
    required double y,
    required double radius,
    required double rad,
    required bool rotated,
    required double? width,
  }) {
    final size = radius * math.sqrt2;
    final left = x - size / 2;
    final top = y - size / 2;
    final bar = size * 0.24;
    final gap = (size - 3 * bar) / 2;
    for (final (i, length) in const [0.6, 1.0, 0.4].indexed) {
      ctx.rect(left, top + i * (bar + gap), size * length, bar);
    }
  }
}

/// `Legend(isVisible: true)`: the series names under the title, with the
/// icon of the series type.
LegendOptions sfLegend(PointStyle icon, {bool reverse = false}) =>
    LegendOptions(
      reverse: reverse,
      labels: LegendLabelOptions(
        usePointStyle: true,
        color: const .solid(Sf.text),
        font: const TextStyle(fontSize: 13, letterSpacing: 0.4),
        pointStyle: icon,
      ),
    );

/// One setting of the property panel of a demo: `CustomDirectionalButtons`
/// from 0 to 1 in steps of 0.1.
class const SfStepper({
  /// The prefix of the keys of the two buttons.
  required final String id,
  required final String label,
  required final double value,
  required final ValueChanged<double> onChanged,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tenths = (value * 10).round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        IconButton(
          key: ValueKey('$id.less'),
          icon: const Icon(Icons.chevron_left),
          onPressed: tenths > 0 ? () => onChanged((tenths - 1) / 10) : null,
        ),
        Text(value.toStringAsFixed(1)),
        IconButton(
          key: ValueKey('$id.more'),
          icon: const Icon(Icons.chevron_right),
          onPressed: tenths < 10 ? () => onChanged((tenths + 1) / 10) : null,
        ),
      ],
    );
  }
}
// #enddocregion sf-bar-kit
