// Original code, not ported from Chart.js: the ApexCharts.js parts of the replicas.
// ignore_for_file: lines_longer_than_80_chars
// #docregion apexjs-kit
import 'package:chartjs_docs/migrate/apexcharts/apex_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

/// The default colors of ApexCharts.js 4.7.0 (`theme.palette: 'palette1'`).
const List<Color> apexJsPalette = [
  Apex.blue,
  Apex.green,
  Apex.yellow,
  Apex.red,
  Apex.purple,
];

/// `grid.borderColor`, `axisBorder.color` and `axisTicks.color`: #e0e0e0.
const Color apexJsGrid = Color(0xFFE0E0E0);

/// A series color with the opacity of ApexCharts.js: a line has
/// `stroke-opacity` 0.85, and a bar `fill.opacity: 0.85` by default.
ChartValue<ChartPaint> apexJsSeries(Color color, {double opacity = 0.85}) =>
    .constant(.solid(color.withValues(alpha: opacity)));

/// The hover color of a bar: `states.hover.filter: {type: 'lighten'}`.
ChartValue<ChartPaint> apexJsLighten(Color color, {double opacity = 0.85}) =>
    .constant(
      .solid(Color.lerp(color, Colors.white, 0.15)!.withValues(alpha: opacity)),
    );

/// `title: {text, align}`: 14 px, weight 900, the text color.
TitleOptions apexJsTitle(
  String text, {
  ChartAlign align = .start,
  ChartPosition position = .top,
  Color color = Apex.text,
  double size = 14,
}) => TitleOptions(
  display: true,
  text: [text],
  align: align,
  position: position,
  color: .solid(color),
  font: TextStyle(fontSize: size, fontWeight: FontWeight.w900),
  padding: const EdgeInsets.only(top: 4, bottom: 12),
);

/// `legend`: 12 px names under the plot, with a circle before the name of a
/// line and a square before the name of a bar series.
LegendOptions apexJsLegend({
  ChartPosition position = .bottom,
  ChartAlign align = .center,
  bool square = false,
}) => LegendOptions(
  position: position,
  align: align,
  labels: LegendLabelOptions(
    boxWidth: square ? 12 : 8,
    boxHeight: square ? 12 : 8,
    usePointStyle: !square,
    color: const .solid(Apex.text),
    font: const TextStyle(fontSize: 12),
    padding: 8,
  ),
);

/// The category axis of ApexCharts.js. Under a line or a column chart, it
/// has the axis line and a 6 px tick mark at each label (a line chart) or
/// between two bands (a column chart: Chart.js offsets the bar grid). Left
/// of horizontal bars, it has a grid line between two bands.
CategoryAxis apexJsCategoryAxis({
  String? title,
  bool horizontal = false,
  ChartPaint labelColor = const .solid(Apex.text),
  List<Color>? labelColors,
  TickCallback? callback,
  ChartPosition? position,
  double maxRotation = 45,
}) => CategoryAxis(
  horizontal ? .y : .x,
  position: position,
  grid: horizontal
      ? const AxisGrid(color: .solid(apexJsGrid), drawTicks: false)
      : const AxisGrid(
          color: .solid(apexJsGrid),
          drawOnChartArea: false,
          tickLength: 6,
        ),
  ticks: AxisTicks(
    color: labelColor,
    font: TextStyle(fontSize: horizontal ? 11 : 12),
    padding: horizontal ? 10 : 4,
    maxRotation: maxRotation,
    autoSkip: false,
    callback: callback,
    // xaxis.labels.style.colors: one color for each label.
    extra: {
      if (labelColors != null)
        'color': (Object? c) => ChartPaint.solid(
          labelColors[((c! as ScriptableScaleContext).index ?? 0) %
              labelColors.length],
        ),
    },
  ),
  border: AxisBorder(display: !horizontal, color: const .solid(apexJsGrid)),
  title: title == null ? null : apexJsAxisTitle(title),
);

/// The value axis of ApexCharts.js: a grid line at each tick, the labels
/// left of the plot (11 px) and no axis line. Under horizontal bars, it
/// has the axis line and no grid line.
LinearAxis apexJsValueAxis({
  double? min,
  double? max,
  double? stepSize,
  TickCallback? callback,
  String? title,
  bool stacked = false,
  bool horizontal = false,
  bool grid = true,
}) => LinearAxis(
  horizontal ? .x : .y,
  min: min,
  max: max,
  stacked: stacked ? StackMode.on : StackMode.off,
  grid: AxisGrid(
    display: grid && !horizontal,
    color: const .solid(apexJsGrid),
    drawTicks: false,
  ),
  ticks: AxisTicks(
    stepSize: stepSize,
    color: const .solid(Apex.text),
    font: TextStyle(fontSize: horizontal ? 12 : 11),
    padding: horizontal ? 6 : 12,
    maxRotation: 0,
    callback: callback ?? apexNumberTick,
  ),
  border: AxisBorder(display: horizontal, color: const .solid(apexJsGrid)),
  title: title == null ? null : apexJsAxisTitle(title),
);

/// `xaxis.title` and `yaxis.title`: 12 px, weight 900.
AxisTitle apexJsAxisTitle(String text) => AxisTitle(
  display: true,
  text: [text],
  color: const .solid(Apex.text),
  font: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
  padding: const EdgeInsets.only(top: 6),
);

/// A line series of ApexCharts.js: `stroke.width` 5, the series color at
/// 0.85 alpha, no markers, and a marker of 6 px radius on a hover.
LineDataset apexJsLine(
  String? name,
  List<num> values,
  Color color, {
  double width = 5,
  List<double>? dash,
  double markers = 0,
  double tension = 0,
  SteppedLine? stepped,
  ChartShadow? shadow,
}) => LineDataset(
  label: name,
  data: .values(values),
  borderColor: apexJsSeries(color),
  backgroundColor: .constant(.solid(color)),
  borderWidth: width,
  borderDash: dash,
  tension: tension,
  stepped: stepped,
  shadow: shadow,
  pointRadius: .constant(markers),
  pointHoverRadius: const .constant(0),
  pointBackgroundColor: .constant(.solid(color)),
  pointBorderColor: const .constant(.solid(Colors.white)),
  pointBorderWidth: markers == 0 ? 0 : 1,
);

/// A bar series of ApexCharts.js: the fill at [opacity] (`fill.opacity`,
/// 0.85 by default), a lighter fill on a hover, and a border of [stroke]
/// (`stroke.width` 0 by default). [percentage] is `columnWidth` or
/// `barHeight`: the part of the band that the bars of a group take.
BarDataset apexJsBar(
  String? name,
  List<num> values,
  Color color, {
  double opacity = 0.85,
  double percentage = 0.7,
  double? radius,
  double stroke = 0,
  Color strokeColor = Colors.white,
}) => BarDataset(
  label: name,
  data: .values(values),
  backgroundColor: apexJsSeries(color, opacity: opacity),
  hoverBackgroundColor: apexJsLighten(color, opacity: opacity),
  borderColor: .constant(.solid(strokeColor)),
  hoverBorderColor: .constant(.solid(strokeColor)),
  borderWidth: stroke,
  borderRadius: radius,
  categoryPercentage: percentage,
  barPercentage: 1,
);

/// The tooltip of a bar series: `tooltip: {shared: false, intersect: true}`,
/// the defaults of a bar chart. One row for the bar under the pointer.
TooltipOptions apexJsBarTooltip({
  String Function(num value) value = apexNumber,
  bool horizontal = false,
}) => apexTooltip(
  value: value,
  horizontal: horizontal,
).merge(const TooltipOptions(mode: NearestInteractionMode(), intersect: true));

/// `grid.row.colors` with `grid.row.opacity`: bands of the colors between
/// the grid lines of the y axis, from the top.
Plugin<Object?> apexJsRowStripes(List<Color> colors, {double opacity = 0.5}) =>
    Plugin(
      id: 'apexJsRowStripes',
      beforeDatasetsDraw: (chart, args, options) {
        final c = chart as Chart;
        final area = c.chartArea!;
        final scale = c.scales['y']!;
        final pixels = [
          for (final tick in scale.ticks ?? const <Tick>[])
            scale.getPixelForValue(tick.value),
        ]..sort();
        final ctx = c.ctx!..save();
        for (var i = 0; i + 1 < pixels.length; i++) {
          ctx
            ..fillStyle = colors[i % colors.length].withValues(
              alpha: colors[i % colors.length].a * opacity,
            )
            ..fillRect(
              area.left,
              pixels[i],
              area.width,
              pixels[i + 1] - pixels[i],
            );
        }
        ctx.restore();
        return true;
      },
    );

/// `dataLabels: {enabled: true}` on a line: the value of each point in a
/// box of the series color, white 12 px text of weight 600.
final apexJsLineLabels = Plugin<Object?>(
  id: 'apexJsLineLabels',
  afterDatasetsDraw: (chart, args, options) {
    final c = chart as Chart;
    final ctx = c.ctx!
      ..save()
      ..font = toFont(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      )
      ..textAlign = TextAlign.center
      ..textBaseline = CanvasTextBaseline.middle;
    for (final meta in c.getSortedVisibleDatasetMetas()) {
      final color = apexSeriesColor(c, meta.index);
      for (final (j, point) in meta.data.indexed) {
        final parsed = meta.controller!.getParsed(j)! as JsObjectFace;
        final text = apexNumber(parsed['y']! as num);
        final width = ctx.measureText(text).width + 8;
        ctx
          ..fillStyle = color.withValues(alpha: 0.9)
          ..strokeStyle = Colors.white
          ..lineWidth = 1
          ..beginPath()
          ..roundRect(point.x - width / 2, point.y - 9, width, 18, 2)
          ..fill()
          ..stroke()
          ..fillStyle = Colors.white
          ..fillText(text, point.x, point.y);
      }
    }
    ctx.restore();
  },
);

/// Where a bar label goes: `plotOptions.bar.dataLabels.position`.
enum ApexJsLabelAt() {
  /// In the middle of the bar: `'center'`, the default.
  center,

  /// Inside the end of the bar: `'top'` of a horizontal bar.
  insideEnd,

  /// Past the end of the bar: `'top'` of a column with an `offsetY`.
  outsideEnd,
}

/// `dataLabels: {enabled: true}` on bars: the value of each bar, 12 px of
/// weight 600, in [color]. [offset] moves a label away from the base, and
/// [totals] writes the sum of each stack past its end
/// (`plotOptions.bar.dataLabels.total`).
Plugin<Object?> apexJsBarLabels({
  String Function(num value) format = apexNumber,
  Color color = Colors.white,
  ApexJsLabelAt at = .center,
  double offset = 0,
  bool totals = false,
}) => Plugin(
  id: 'apexJsBarLabels',
  afterDatasetsDraw: (chart, args, options) {
    final c = chart as Chart;
    final ctx = c.ctx!
      ..save()
      ..font = toFont(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      )
      ..fillStyle = color
      ..textAlign = TextAlign.center
      ..textBaseline = CanvasTextBaseline.middle;
    final sums = <int, num>{};
    var horizontal = false;
    for (final meta in c.getSortedVisibleDatasetMetas()) {
      for (final (j, element) in meta.data.indexed) {
        final bar = element as BarElement;
        horizontal = bar.horizontal ?? false;
        final parsed = meta.controller!.getParsed(j)! as JsObjectFace;
        final value = parsed[horizontal ? 'x' : 'y']! as num;
        sums[j] = (sums[j] ?? 0) + value;
        // The direction from the base to the end of the bar.
        final sign = horizontal
            ? (bar.x >= bar.base ? 1 : -1)
            : (bar.y <= bar.base ? -1 : 1);
        final end = horizontal ? bar.x : bar.y;
        final middle = (end + bar.base) / 2;
        final at_ = switch (at) {
          ApexJsLabelAt.center => middle,
          ApexJsLabelAt.insideEnd => end - sign * 12,
          ApexJsLabelAt.outsideEnd => end + sign * 10,
        };
        final along = at_ + sign * offset;
        ctx.fillText(
          format(value),
          horizontal ? along : bar.x,
          horizontal ? bar.y : along,
        );
      }
    }
    if (totals) {
      final scale = c.scales[horizontal ? 'x' : 'y']!;
      final index = c.scales[horizontal ? 'y' : 'x']!;
      ctx
        ..font = toFont(
          const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        )
        ..fillStyle = Apex.text
        ..textAlign = horizontal ? TextAlign.left : TextAlign.center
        ..textBaseline = horizontal
            ? CanvasTextBaseline.middle
            : CanvasTextBaseline.bottom;
      for (final MapEntry(key: j, value: sum) in sums.entries) {
        final end = scale.getPixelForValue(sum.toDouble());
        final across = index.getPixelForValue(j.toDouble());
        ctx.fillText(
          apexNumber(sum),
          horizontal ? end + 4 : across,
          horizontal ? across : end - 4,
        );
      }
    }
    ctx.restore();
  },
);

/// `xaxis.crosshairs` of a column chart: a band of a light blue gradient
/// behind the hovered column, as wide as the column.
final apexJsColumnCrosshair = Plugin<Object?>(
  id: 'apexJsColumnCrosshair',
  beforeDatasetsDraw: (chart, args, options) {
    final c = chart as Chart;
    final active = c.getActiveElements();
    if (active.isEmpty) return true;
    final bar = active.first.element;
    if (bar is! BarElement || (bar.horizontal ?? false)) return true;
    final area = c.chartArea!;
    final left = bar.x - bar.width / 2;
    c.ctx!
      ..save()
      ..fillStyle = ChartGradient.linear(
        Offset(0, area.top),
        Offset(0, area.bottom),
        const [Color(0x66D8E3F0), Color(0x80BED1E6)],
      )
      ..fillRect(left, area.top, bar.width, area.height)
      ..restore();
    return true;
  },
);
// #enddocregion apexjs-kit
