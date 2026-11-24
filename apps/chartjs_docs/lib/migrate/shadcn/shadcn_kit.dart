// Original code, not ported from Chart.js: the shadcn/ui parts of the replicas.
// ignore_for_file: public_member_api_docs
// #docregion shadcn-kit
import 'dart:math' as math;

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

/// The colors of the shadcn/ui site: `--chart-1` to `--chart-5` (Tailwind
/// blue 300, 500, 600, 700 and 800) and the gray tokens.
abstract final class Shadcn() {
  static const chart1 = Color(0xFF8EC5FF);
  static const chart2 = Color(0xFF2B7FFF);
  static const chart3 = Color(0xFF155DFC);
  static const chart4 = Color(0xFF1447E6);
  static const chart5 = Color(0xFF193CB8);
  static const background = Color(0xFFFFFFFF);
  static const foreground = Color(0xFF000000);
  static const muted = Color(0xFFF5F5F5);
  static const mutedForeground = Color(0xFF737373);
  static const border = Color(0xFFE5E5E5);
  // The grid lines: the border color at 50 % alpha.
  static const grid = Color(0x80E5E5E5);
}

/// `text-xs`: the axis labels, the tooltip, the legend and the labels.
const TextStyle shadcnTextXs = TextStyle(fontSize: 12);

/// The mount animation of a Recharts `Line`: 1500 ms, ease.
const ChartAnimation shadcnLineAnimation = ChartAnimation(
  duration: Duration(milliseconds: 1500),
  easing: Curves.ease,
);

/// The mount animation of a Recharts `Bar`: 400 ms, ease.
const ChartAnimation shadcnBarAnimation = ChartAnimation(
  duration: Duration(milliseconds: 400),
  easing: Curves.ease,
);

/// `type="natural"` of a Recharts `Line`: a natural cubic spline through
/// the points, in x and in y over the point index, with no bend at the two
/// ends.
final class const NaturalCurve() extends CubicInterpolationMode {
  @override
  bool drawsCurves(Object? tension) => true;

  @override
  void updateControlPoints(
    List<SplinePoint> points, {
    required double tension,
    required bool loop,
    required ScaleAxis indexAxis,
  }) {
    final n = points.length;
    if (n < 3) {
      _straight(points);
      return;
    }
    final (x1, x2) = _naturalControls([for (final p in points) p.x]);
    final (y1, y2) = _naturalControls([for (final p in points) p.y]);
    for (var i = 0; i < n; i++) {
      // The curve from point i to point i + 1 leaves point i toward the
      // first control point of segment i, and reaches point i + 1 from the
      // second.
      points[i]
        ..cp1x = i > 0 ? x2[i - 1] : points[i].x
        ..cp1y = i > 0 ? y2[i - 1] : points[i].y
        ..cp2x = i < n - 1 ? x1[i] : points[i].x
        ..cp2y = i < n - 1 ? y1[i] : points[i].y;
    }
  }
}

/// The two control points of each segment of the natural spline through
/// [k]: a tridiagonal system for the first control points (the Thomas
/// algorithm), and the second control points from the first.
(List<double>, List<double>) _naturalControls(List<double> k) {
  final n = k.length - 1;
  final a = List<double>.filled(n, 1);
  final b = List<double>.filled(n, 4);
  final c = List<double>.filled(n, 1);
  final r = List<double>.generate(n, (i) => 4 * k[i] + 2 * k[i + 1]);
  // No bend at the first point and at the last point.
  b[0] = 2;
  r[0] = k[0] + 2 * k[1];
  a[n - 1] = 2;
  b[n - 1] = 7;
  r[n - 1] = 8 * k[n - 1] + k[n];
  for (var i = 1; i < n; i++) {
    final m = a[i] / b[i - 1];
    b[i] -= m * c[i - 1];
    r[i] -= m * r[i - 1];
  }
  final p1 = List<double>.filled(n, 0);
  p1[n - 1] = r[n - 1] / b[n - 1];
  for (var i = n - 2; i >= 0; i--) {
    p1[i] = (r[i] - c[i] * p1[i + 1]) / b[i];
  }
  final p2 = [
    for (var i = 0; i < n - 1; i++) 2 * k[i + 1] - p1[i + 1],
    (k[n] + p1[n - 1]) / 2,
  ];
  return (p1, p2);
}

/// `type="monotone"` of a Recharts `Line`: a cubic curve that keeps the
/// rise and the fall of the data in x, with the slopes of Steffen (1990)
/// inside and a one-sided slope at the two ends.
final class const MonotoneXCurve() extends CubicInterpolationMode {
  @override
  bool drawsCurves(Object? tension) => true;

  @override
  void updateControlPoints(
    List<SplinePoint> points, {
    required double tension,
    required bool loop,
    required ScaleAxis indexAxis,
  }) {
    final n = points.length;
    if (n < 3) {
      _straight(points);
      return;
    }
    double slope(int i) {
      final h = points[i + 1].x - points[i].x;
      return h == 0 ? 0 : (points[i + 1].y - points[i].y) / h;
    }

    final m = List<double>.filled(n, 0);
    for (var i = 1; i < n - 1; i++) {
      final h0 = points[i].x - points[i - 1].x;
      final h1 = points[i + 1].x - points[i].x;
      final s0 = slope(i - 1);
      final s1 = slope(i);
      final p = (s0 * h1 + s1 * h0) / (h0 + h1);
      final limit = math.min(math.min(s0.abs(), s1.abs()), 0.5 * p.abs());
      m[i] = (s0.sign + s1.sign) * limit;
    }
    m[0] = (3 * slope(0) - m[1]) / 2;
    m[n - 1] = (3 * slope(n - 2) - m[n - 2]) / 2;
    for (var i = 0; i < n; i++) {
      final p = points[i];
      final before = i > 0 ? (p.x - points[i - 1].x) / 3 : 0.0;
      final after = i < n - 1 ? (points[i + 1].x - p.x) / 3 : 0.0;
      p
        ..cp1x = p.x - before
        ..cp1y = p.y - m[i] * before
        ..cp2x = p.x + after
        ..cp2y = p.y + m[i] * after;
    }
  }
}

void _straight(List<SplinePoint> points) {
  for (final p in points) {
    p
      ..cp1x = p.x
      ..cp1y = p.y
      ..cp2x = p.x
      ..cp2y = p.y;
  }
}

/// The value axis of a Recharts chart with no visible `YAxis`: no labels,
/// and the lines of `CartesianGrid` at its 5 ticks when [grid] is true.
/// The axis goes from 0, or from below 0 for negative [values], in 4 equal
/// steps: Recharts rounds a quarter of the range up to a multiple of 0.05
/// of its power of ten.
LinearAxis shadcnValueAxis(
  List<num> values, {
  CartesianAxis direction = .y,
  bool grid = true,
  bool stacked = false,
}) {
  final (min, max, step) = rechartsRange(values);
  return LinearAxis(
    direction,
    min: min,
    max: max,
    stacked: stacked ? StackMode.on : StackMode.off,
    grid: AxisGrid(
      display: grid,
      color: const .constant(.solid(Shadcn.grid)),
      drawTicks: false,
    ),
    ticks: AxisTicks(display: false, stepSize: step),
    border: const AxisBorder(display: false),
  );
}

/// The range and the step of the 5 ticks of a Recharts number axis with the
/// domain `[0, 'auto']` for [values].
(double, double, double) rechartsRange(List<num> values) {
  final low = math.min<double>(0, values.reduce(math.min).toDouble());
  final high = math.max<double>(0, values.reduce(math.max).toDouble());
  final rough = (high - low) / 4;
  if (rough == 0) return (0, 4, 1);
  final unit = math.pow(10, (math.log(rough) / math.ln10).floor() + 1);
  // A multiple of 0.05 of the power of ten: twentieths, which keep whole
  // steps whole.
  for (var extra = 0; ; extra++) {
    final step = ((rough * 20 / unit).ceil() + extra) * unit / 20;
    final below = (-low / step).ceil();
    final above = (high / step).ceil();
    if (below + above > 4) continue;
    // The ticks that are left go above 0, or below 0 when no value is
    // above 0.
    final rest = 4 - below - above;
    return high > 0
        ? (-below * step, (above + rest) * step, step)
        : (-(below + rest) * step, above * step, step);
  }
}

/// The category axis of the months, under a line or a bar chart: the
/// labels in the muted color with no tick lines, no axis line and no grid
/// lines. [callback] is `tickFormatter`, by default the first three
/// letters, and null keeps the labels. Recharts gives the axis 30 px.
CategoryAxis shadcnCategoryAxis({
  CartesianAxis direction = .x,
  TickCallback? callback = shortLabel,
  double tickMargin = 8,
  bool display = true,
  bool stacked = false,
  double? autoSkipPadding,
}) => CategoryAxis(
  direction,
  display: display ? ScaleDisplay.on : ScaleDisplay.off,
  stacked: stacked ? StackMode.on : StackMode.off,
  grid: const AxisGrid(display: false, drawTicks: false),
  ticks: AxisTicks(
    color: const .constant(.solid(Shadcn.mutedForeground)),
    font: const .constant(shadcnTextXs),
    // The tick size of Recharts, 6 px, and the tick margin, less the space
    // above the text.
    padding: tickMargin + 4,
    maxRotation: 0,
    callback: callback,
    autoSkip: autoSkipPadding != null,
    autoSkipPadding: autoSkipPadding,
  ),
  border: const AxisBorder(display: false),
  extra: display ? const {'afterFit': _height30} : null,
);

void _height30(Scale scale) => scale.height = 30;

/// The category axis of a horizontal bar chart (`YAxis type="category"`):
/// the labels end [tickMargin] px and the tick size left of the bars, in an
/// axis of [width] px. [display] false is `hide`. [callback] is
/// `tickFormatter`, and null keeps the labels.
CategoryAxis shadcnCategoryYAxis({
  TickCallback? callback = shortLabel,
  double tickMargin = 10,
  double width = 60,
  bool display = true,
}) => CategoryAxis(
  .y,
  display: display ? ScaleDisplay.on : ScaleDisplay.off,
  grid: const AxisGrid(display: false, drawTicks: false),
  ticks: AxisTicks(
    color: const .constant(.solid(Shadcn.mutedForeground)),
    font: const .constant(shadcnTextXs),
    padding: tickMargin + 6,
    callback: callback,
  ),
  border: const AxisBorder(display: false),
  extra: display ? {'afterFit': (Scale scale) => scale.width = width} : null,
);

/// `tickFormatter={(value) => value.slice(0, 3)}`.
List<String>? shortLabel(Scale scale, double value, int index, List<Tick> t) {
  final label = (scale as CategoryScale).getLabelForValue(value);
  return [if (label.length > 3) label.substring(0, 3) else label];
}

/// The hover of a Recharts chart: the items of the hovered index, also
/// with the pointer between two points. [horizontal] is `layout="vertical"`:
/// the index is on the y axis.
ChartInteraction shadcnInteraction({bool horizontal = false}) =>
    ChartInteraction(
      mode: const IndexInteractionMode(),
      intersect: false,
      axis: horizontal ? .y : .x,
    );

/// The legend of `ChartLegendContent`: under the chart, an 8 px square of
/// 2 px corners before each name, 16 px between the items. A tap does
/// nothing, as in shadcn/ui.
const LegendOptions shadcnLegend = LegendOptions(
  position: ChartPosition.bottom,
  onClick: _shadcnLegendClick,
  labels: LegendLabelOptions(
    boxWidth: 8,
    boxHeight: 8,
    color: .solid(Shadcn.foreground),
    font: shadcnTextXs,
    padding: 16,
    useBorderRadius: true,
    borderRadius: BorderRadius.all(Radius.circular(2)),
  ),
);

/// A tap on a legend item of [shadcnLegend]: nothing.
void _shadcnLegendClick(
  ChartEvent event,
  LegendItem item,
  LegendElement legend,
) {}

/// The no-tooltip-of-Chart.js setting with no legend: the replicas draw the
/// tooltip with Flutter widgets.
const LegendOptions shadcnNoLegend = LegendOptions(display: false);

/// The look of an indicator of `ChartTooltipContent`.
enum ShadcnIndicator() {
  dot,
  line,
  dashed,
}

/// The options of `ChartTooltipContent`.
final class const ShadcnTooltipContent({
  /// `hideLabel`.
  final bool hideLabel = false,

  /// `hideIndicator`.
  final bool hideIndicator = false,

  /// `indicator`.
  final ShadcnIndicator indicator = ShadcnIndicator.dot,

  /// The text of `nameKey`: the name of each row. By default, the label of
  /// the dataset.
  final String? name,

  /// `labelFormatter`.
  final String Function(String label)? labelFormatter,

  /// The width of `className="w-[150px]"`.
  final double? width,
});

/// One row of the tooltip: the indicator color, the name and the value.
typedef ShadcnTipRow = ({Color color, String name, String value});

/// What the tooltip shows: the point of the hovered index under the
/// pointer, the label and the rows.
typedef ShadcnTipState = ({
  Offset at,
  String? label,
  List<ShadcnTipRow> rows,
  ShadcnTooltipContent content,
});

/// The tooltip of a chart: the chart writes it in the option `external`,
/// and a Flutter widget shows it.
final class ShadcnTip() {
  final ValueNotifier<ShadcnTipState?> state = ValueNotifier(null);

  /// The options of `ChartTooltipContent` that [external] shows.
  ShadcnTooltipContent content = const ShadcnTooltipContent();

  /// The option `external` of the chart. Two tear-offs of the same tip are
  /// `==`, so a new config of each build gives no chart update.
  void external(TooltipModel tooltip, bool replay) => show(tooltip, content);

  void show(TooltipModel tooltip, ShadcnTooltipContent content) {
    final items = tooltip.dataPoints ?? const <TooltipItem>[];
    if (tooltip.opacity == 0 || items.isEmpty) {
      state.value = null;
      return;
    }
    final label = items.first.label.join(' ');
    state.value = (
      at: Offset(tooltip.caretX, tooltip.caretY),
      label: content.hideLabel
          ? null
          : content.labelFormatter?.call(label) ?? label,
      rows: [
        for (final item in items)
          (
            color: _tipColorOf(item),
            name: content.name ?? item.datasetLabel ?? '',
            value: item.formattedValue,
          ),
      ],
      content: content,
    );
  }

  void dispose() => state.dispose();
}

/// The color of an item: the fill of its bar or its point, with no alpha.
Color _tipColorOf(TooltipItem item) {
  final paint = switch (item.element?.options) {
    PointOptions(:final backgroundColor) => backgroundColor,
    BarOptions(:final backgroundColor) => backgroundColor,
    _ => null,
  };
  return paint is SolidChartPaint
      ? paint.color.withValues(alpha: 1)
      : Shadcn.chart1;
}

/// `ChartTooltip` with `ChartTooltipContent`: Chart.js draws no tooltip,
/// and gives each change to [tip], which shows [content].
///
/// The options are `==` for the same [tip] and [horizontal]: the config
/// function of [ShadcnChart] runs at each build, and equal options give no
/// chart update.
TooltipOptions shadcnTooltip(
  ShadcnTip tip, [
  ShadcnTooltipContent content = const ShadcnTooltipContent(),
  bool horizontal = false,
]) {
  tip.content = content;
  return TooltipOptions(
    enabled: false,
    mode: const IndexInteractionMode(),
    intersect: false,
    axis: horizontal ? .y : .x,
    position: horizontal
        ? const ShadcnTipPositioner(horizontal: true)
        : const ShadcnTipPositioner(),
    external: tip.external,
  );
}

/// The place of the Recharts tooltip: the hovered index on the index axis,
/// and the pointer on the value axis.
final class const ShadcnTipPositioner({final bool horizontal = false})
    extends TooltipPositioner {
  @override
  TooltipPosition? positionOf(
    TooltipModel tooltip,
    List<ActiveElement> items,
    Object? eventPosition,
  ) {
    if (items.isEmpty) return null;
    final chart = tooltip.chart as Chart;
    final index = shadcnIndexPixel(chart, items.first.index, horizontal);
    final element = items.first.element!;
    final pointer = eventPosition is TooltipPosition ? eventPosition : null;
    final px = pointer?.x;
    final py = pointer?.y;
    return TooltipPosition()
      ..x = horizontal ? (px is num ? px.toDouble() : element.x) : index
      ..y = horizontal ? index : (py is num ? py.toDouble() : element.y);
  }
}

/// The pixel of the index [index] on the index axis: a point, or the middle
/// of a band of bars.
double shadcnIndexPixel(Chart chart, int index, bool horizontal) =>
    chart.scales[horizontal ? 'y' : 'x']!.getPixelForValue(index.toDouble());

/// A chart in a shadcn/ui `ChartContainer`: 16:9, or [height] px high,
/// with the tooltip of `ChartTooltipContent` as a Flutter widget over it.
/// [config] gets the tooltip state for `shadcnTooltip`.
class const ShadcnChart({
  required final ChartConfig Function(ShadcnTip tip) config,
  required final String semanticLabel,
  final double? height,
  super.key,
}) extends StatefulWidget {
  @override
  State<ShadcnChart> createState() => _ShadcnChartState();
}

class _ShadcnChartState() extends State<ShadcnChart> {
  final ShadcnTip _tip = ShadcnTip();

  @override
  void dispose() {
    _tip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget chart = ChartView(
      config: widget.config(_tip),
      semanticLabel: widget.semanticLabel,
    );
    if (widget.height case final height?) {
      chart = SizedBox(height: height, child: chart);
    }
    return Stack(
      fit: StackFit.passthrough,
      children: [
        chart,
        Positioned.fill(
          child: IgnorePointer(
            child: ValueListenableBuilder(
              valueListenable: _tip.state,
              builder: (context, tip, _) => tip == null
                  ? const SizedBox.shrink()
                  : CustomSingleChildLayout(
                      delegate: _TipLayout(tip.at),
                      child: ShadcnTooltipBox(tip: tip),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The place of the tooltip box: 10 px right of and below the point, or
/// left of and above it when the box does not fit in the chart.
final class _TipLayout(final Offset at) extends SingleChildLayoutDelegate {
  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    const offset = 10.0;
    var x = at.dx + offset;
    if (x + childSize.width > size.width) {
      x = math.max(0, at.dx - offset - childSize.width);
    }
    var y = at.dy + offset;
    if (y + childSize.height > size.height) {
      y = math.max(0, at.dy - offset - childSize.height);
    }
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_TipLayout oldDelegate) => oldDelegate.at != at;
}

/// The box of `ChartTooltipContent`: the label, then one row for each
/// item with its indicator, its name and its value.
class const ShadcnTooltipBox({required final ShadcnTipState tip, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final content = tip.content;
    final nest = tip.rows.length == 1 && content.indicator != .dot;
    final label = tip.label == null
        ? null
        : Text(
            tip.label!,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Shadcn.foreground,
              height: 1,
            ),
          );
    return Container(
      width: content.width,
      constraints: const BoxConstraints(minWidth: 128),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Shadcn.background,
        border: Border.all(color: Shadcn.grid),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 20),
            blurRadius: 25,
            spreadRadius: -5,
          ),
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 8),
            blurRadius: 10,
            spreadRadius: -6,
          ),
        ],
      ),
      child: DefaultTextStyle.merge(
        style: shadcnTextXs,
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 6,
            children: [
              if (!nest && label != null) label,
              for (final row in tip.rows)
                _TipRow(row: row, content: content, label: nest ? label : null),
            ],
          ),
        ),
      ),
    );
  }
}

class const _TipRow({
  required final ShadcnTipRow row,
  required final ShadcnTooltipContent content,
  required final Widget? label,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dot = content.indicator == .dot;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: dot
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          if (!content.hideIndicator)
            _Indicator(content.indicator, row.color, nested: label != null),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: label != null
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.center,
              spacing: 8,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    spacing: 6,
                    children: [
                      ?label,
                      Text(
                        row.name,
                        style: const TextStyle(
                          color: Shadcn.mutedForeground,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  row.value,
                  style: const TextStyle(
                    fontFamily: 'RobotoMono',
                    fontWeight: FontWeight.w500,
                    fontFeatures: [FontFeature.tabularFigures()],
                    color: Shadcn.foreground,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class const _Indicator(
  final ShadcnIndicator kind,
  final Color color, {
  required final bool nested,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (kind) {
    .dot => Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
    .line => Container(
      width: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
    .dashed => Padding(
      padding: EdgeInsets.symmetric(vertical: nested ? 2 : 0),
      child: CustomPaint(size: const Size(3, 0), painter: _DashPainter(color)),
    ),
  };
}

/// `border-[1.5px] border-dashed` of a box with no width: a dashed line
/// 3 px wide.
final class _DashPainter(final Color color) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width;
    for (var y = 0.0; y < size.height; y += 6) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, math.min(y + 3, size.height)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) => oldDelegate.color != color;
}

/// The `cursor` of `ChartTooltip` (when it is not `false`): a line of the
/// border color at the hovered index of a line chart, or a band of the
/// muted color under the hovered bars.
final shadcnCursor = Plugin<Object?>(
  id: 'shadcnCursor',
  beforeDatasetsDraw: (chart, args, options) {
    final c = chart as Chart;
    final active = c.getActiveElements();
    if (active.isEmpty) return true;
    final area = c.chartArea!;
    final ctx = c.ctx!..save();
    final index = active.first.index;
    final x = shadcnIndexPixel(c, index, false);
    if (active.first.element is BarElement) {
      final scale = c.scales['x']!;
      final left = scale.getPixelForValue(index - 0.5);
      final right = scale.getPixelForValue(index + 0.5);
      ctx
        ..fillStyle = Shadcn.muted
        ..fillRect(left, area.top, right - left, area.bottom - area.top);
    } else {
      ctx
        ..strokeStyle = Shadcn.border
        ..lineWidth = 1
        ..beginPath()
        ..moveTo(x, area.top)
        ..lineTo(x, area.bottom)
        ..stroke();
    }
    ctx.restore();
    return true;
  },
);

/// The place of a `LabelList`.
enum ShadcnLabelPosition() {
  top,
  insideLeft,
  right,
}

/// `LabelList` of a `Line` or a `Bar` of the dataset [datasetIndex]: one
/// 12 px text for each point or bar, [offset] px from the [position] of the
/// item. [text] gives the text of the item at an index, by default its
/// value, and [color] its color, by default the foreground color.
Plugin<Object?> shadcnLabels({
  required String id,
  ShadcnLabelPosition position = .top,
  double offset = 12,
  String Function(int index, num value)? text,
  Color Function(int index)? color,
  int datasetIndex = 0,
}) => Plugin(
  id: id,
  afterDatasetsDraw: (chart, args, options) {
    final c = chart as Chart;
    final meta = c.getDatasetMeta(datasetIndex);
    if (!meta.visible) return;
    final ctx = c.ctx!
      ..save()
      ..font = toFont(shadcnTextXs)
      ..textBaseline = CanvasTextBaseline.alphabetic;
    for (final (i, element) in meta.data.indexed) {
      final parsed = meta.controller!.getParsed(i)! as JsObjectFace;
      final horizontal = element is BarElement && (element.horizontal ?? false);
      final value = parsed[horizontal ? 'x' : 'y']! as num;
      final double x;
      final double y;
      // Recharts puts the baseline at the anchor for `verticalAnchor`
      // end, 0.355 em below it for middle and 0.71 em below it for start.
      switch (position) {
        case .top:
          // Below the end of a bar under 0.
          final sign = element is BarElement && element.base < element.y
              ? -1
              : 1;
          x = element.x;
          y = element.y - sign * offset + (sign < 0 ? 0.71 * 12 : 0);
          ctx.textAlign = TextAlign.center;
        case .insideLeft:
          x = (element as BarElement).base + offset;
          y = element.y + 0.355 * 12;
          ctx.textAlign = TextAlign.left;
        case .right:
          x = element.x + offset;
          y = element.y + 0.355 * 12;
          ctx.textAlign = TextAlign.left;
      }
      ctx
        ..fillStyle = color?.call(i) ?? Shadcn.foreground
        ..fillText(text?.call(i, value) ?? _number(value), x, y);
    }
    ctx.restore();
  },
);

String _number(num value) =>
    value == value.truncate() ? '${value.toInt()}' : '$value';

/// The card of a shadcn/ui chart demo (`Card`, `CardHeader`, `CardContent`
/// and `CardFooter`): the title, the dates, the chart and the two lines of
/// the footer.
class const ShadcnCard({
  required final String title,
  required final Widget chart,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: _CardBox(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 24,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _CardTitle(
                title: title,
                description: 'January - June 2024',
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: chart,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: DefaultTextStyle.merge(
                style: const TextStyle(fontSize: 14, height: 1),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    Row(
                      spacing: 8,
                      children: [
                        Flexible(
                          child: Text(
                            'Trending up by 5.2% this month',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Icon(Icons.trending_up, size: 16),
                      ],
                    ),
                    Text(
                      'Showing total visitors for the last 6 months',
                      style: TextStyle(color: Shadcn.mutedForeground),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// `Card`: white, a 1 px border, 14 px corners and a small shadow.
class const _CardBox({
  required final EdgeInsets padding,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Shadcn.background,
      border: Border.all(color: Shadcn.border),
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1A000000),
          offset: Offset(0, 1),
          blurRadius: 3,
        ),
        BoxShadow(
          color: Color(0x1A000000),
          offset: Offset(0, 1),
          blurRadius: 2,
          spreadRadius: -1,
        ),
      ],
    ),
    child: Padding(
      padding: padding,
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Shadcn.foreground),
        child: child,
      ),
    ),
  );
}

/// `CardTitle` and `CardDescription`.
class const _CardTitle({
  required final String title,
  required final String description,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 8,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
      Text(
        description,
        style: const TextStyle(
          fontSize: 14,
          height: 20 / 14,
          color: Shadcn.mutedForeground,
        ),
      ),
    ],
  );
}

/// The card of the interactive demos: the title and the description, then
/// one button for each series with its total. A tap on a button shows its
/// series. From 640 px, the buttons are right of the title.
class const ShadcnInteractiveCard({
  required final String title,
  required final List<(String, int)> series,
  required final int active,
  required final ValueChanged<int> onSelect,
  required final Widget chart,
  required final String buttonKey,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 640;
      final heading = _CardTitle(
        title: title,
        description: 'Showing total visitors for the last 3 months',
      );
      final buttons = [
        for (final (i, (label, total)) in series.indexed)
          Expanded(
            flex: wide ? 0 : 1,
            child: _SeriesButton(
              key: ValueKey('$buttonKey.$i'),
              label: label,
              total: total,
              active: i == active,
              wide: wide,
              leftBorder: wide || i > 0,
              onTap: () => onSelect(i),
            ),
          ),
      ];
      return _CardBox(
        padding: EdgeInsets.symmetric(vertical: wide ? 0 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 24,
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Shadcn.border)),
              ),
              child: wide
                  ? IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: heading,
                              ),
                            ),
                          ),
                          for (final button in buttons) button.child,
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                          child: heading,
                        ),
                        DecoratedBox(
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Shadcn.border),
                            ),
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: buttons,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            Padding(
              padding: wide
                  ? const EdgeInsets.all(24)
                  : const EdgeInsets.symmetric(horizontal: 8),
              child: chart,
            ),
          ],
        ),
      );
    },
  );
}

class const _SeriesButton({
  required final String label,
  required final int total,
  required final bool active,
  required final bool wide,
  required final bool leftBorder,
  required final VoidCallback onTap,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: active,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: wide
            ? const EdgeInsets.symmetric(horizontal: 32, vertical: 24)
            : const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          // `data-[active=true]:bg-muted/50`.
          color: active ? Shadcn.muted.withValues(alpha: 0.5) : null,
          border: leftBorder
              ? const Border(left: BorderSide(color: Shadcn.border))
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Shadcn.mutedForeground,
              ),
            ),
            Text(
              thousands(total),
              style: TextStyle(
                fontSize: wide ? 30 : 18,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// `toLocaleString()` of a whole number in en-US: a comma between each
/// group of three digits.
String thousands(int value) {
  final digits = value.abs().toString();
  final groups = <String>[
    for (var end = digits.length; end > 0; end -= 3)
      digits.substring(math.max(0, end - 3), end),
  ];
  return '${value < 0 ? '-' : ''}${groups.reversed.join(',')}';
}

const List<String> _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// `toLocaleDateString("en-US", {month: "short", day: "numeric"})` of an
/// ISO date, with `year: "numeric"` when [year] is true.
String shortDate(String iso, {bool year = false}) {
  final date = DateTime.parse(iso);
  final text = '${_monthNames[date.month - 1]} ${date.day}';
  return year ? '$text, ${date.year}' : text;
}
// #enddocregion shadcn-kit
