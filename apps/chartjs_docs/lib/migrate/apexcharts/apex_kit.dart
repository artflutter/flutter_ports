// Original code, not ported from Chart.js: the apexcharts_flutter parts of the replicas.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion apex-kit
import 'dart:math' as math;

import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart'
    show
        DragOptions,
        Mode,
        ModifierKey,
        PanOptions,
        ScaleLimit,
        ScaleLimits,
        WheelOptions,
        ZoomAmount,
        ZoomChart,
        ZoomOptions,
        ZoomPluginOptions,
        zoomPlugin;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

/// The colors of apexcharts_flutter: the first five colors of the
/// ApexCharts palette, the text, the grid and the tooltip.
abstract final class Apex() {
  static const blue = Color(0xFF008FFB);
  static const green = Color(0xFF00E396);
  static const yellow = Color(0xFFFEB019);
  static const red = Color(0xFFFF4560);
  static const purple = Color(0xFF775DD0);
  static const text = Color(0xFF373D3F);
  // The axis labels: the text color at 85 % alpha.
  static const label = Color(0xD9373D3F);
  static const grid = Color(0xFFE0E6ED);
  static const icon = Color(0xFF6E8192);
  static const tooltip = Color(0xF5FFFFFF);
  static const tooltipBorder = Color(0xFFE3E3E3);
  static const tooltipTitle = Color(0xFFECEFF1);
  static const tooltipTitleBorder = Color(0xFFDDDDDD);
}

/// The axis labels: 11 px.
const TextStyle apexLabelFont = TextStyle(fontSize: 11);

/// The space of apexcharts_flutter around the plot: 10 px on the top and
/// 12 px on the right. The bottom keeps the 34 px of the x labels with the
/// tick padding of the x axis.
const EdgeInsets apexPadding = EdgeInsets.fromLTRB(0, 10, 12, 13);

/// A number as apexcharts_flutter writes it: no `.0`, at most 3 decimals.
String apexNumber(num value) {
  if (value == value.truncate()) return '${value.toInt()}';
  return value
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

List<String>? apexNumberTick(Scale scale, double v, int i, List<Tick> t) => [
  apexNumber(v),
];

/// The value axis: a grid line at each tick and the labels 10 px left of
/// the plot, with no axis line and no tick marks. The labels take at least
/// 50 px, as the left gutter of apexcharts_flutter.
LinearAxis apexValueAxis({
  double? min,
  double? max,
  double? stepSize,
  TickCallback callback = apexNumberTick,
  String? title,
  bool stacked = false,
  bool horizontal = false,
}) => LinearAxis(
  min: min,
  max: max,
  stacked: stacked ? StackMode.on : StackMode.off,
  grid: const AxisGrid(color: .solid(Apex.grid), drawTicks: false),
  ticks: AxisTicks(
    stepSize: stepSize,
    color: const .solid(Apex.label),
    font: apexLabelFont,
    padding: horizontal ? 8 : 10,
    maxRotation: 0,
    callback: callback,
  ),
  border: const AxisBorder(display: false),
  title: title == null ? null : apexAxisTitle(title),
  extra: {if (!horizontal) 'afterFit': _leftGutter},
);

void _leftGutter(Scale scale) {
  scale.width = math.max<double>(50, scale.width + 6);
}

/// The category axis: labels under the plot, with no grid line, no axis
/// line and no tick marks. A label turns when the labels do not fit.
CategoryAxis apexCategoryAxis({String? title, bool horizontal = false}) =>
    CategoryAxis(
      grid: const AxisGrid(display: false, drawTicks: false),
      ticks: AxisTicks(
        color: const .solid(Apex.label),
        font: apexLabelFont,
        padding: horizontal ? 10 : 8,
        maxRotation: 45,
        autoSkip: false,
      ),
      border: const AxisBorder(display: false),
      title: title == null ? null : apexAxisTitle(title),
      extra: {if (horizontal) 'afterFit': _leftGutter},
    );

/// `xaxis.title` and `yaxis.title`: 12 px, semibold.
AxisTitle apexAxisTitle(String text) => AxisTitle(
  display: true,
  text: text,
  color: const .solid(Apex.text),
  font: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
  padding: const EdgeInsets.only(top: 4),
);

/// The legend of apexcharts_flutter: under the chart, only with more than
/// one series, with a 12 px square of 3 px corners before each name.
const ChartLegend apexLegend = ChartLegend(
  position: .bottom,
  boxWidth: 12,
  boxHeight: 12,
  labelColor: .solid(Apex.text),
  labelFont: TextStyle(fontSize: 12),
  labelPadding: 7,
  extra: {
    'labels': {'useBorderRadius': true, 'borderRadius': 3},
  },
);

/// The mount animation of apexcharts_flutter: 800 ms, ease out.
const ChartAnimation apexAnimation = ChartAnimation(
  duration: Duration(milliseconds: 800),
  easing: Curves.easeOutCubic,
);

/// The shared tooltip of apexcharts_flutter: one row for each series at the
/// hovered index, under a title bar. [value] writes a value, and [title]
/// writes the title of the hovered items.
ChartTooltip apexTooltip({
  String Function(num value) value = apexNumber,
  String Function(List<TooltipItem> items)? title,
  bool horizontal = false,
}) => ChartTooltip(
  mode: const IndexInteractionMode(),
  intersect: false,
  axis: horizontal ? .y : .x,
  position: ApexTipPositioner(horizontal: horizontal),
  // The plugin `apexTooltipLook` draws the box.
  backgroundColor: const .solid(Color(0x00000000)),
  titleColor: const .solid(Apex.text),
  titleFont: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
  bodyColor: const .solid(Apex.text),
  bodyFont: const TextStyle(fontSize: 13),
  padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
  cornerRadius: 5,
  extra: const {
    'caretSize': 0,
    'caretPadding': 8,
    'titleMarginBottom': 13,
    'bodySpacing': 4,
    'boxWidth': 10,
    'boxHeight': 10,
    'boxPadding': 6,
    'usePointStyle': true,
  },
  callbacks: TooltipCallbacks(
    title: (tooltip, items) => [
      title?.call(items) ?? items.first.label.join(' '),
    ],
    label: (tooltip, item) => [
      '${item.datasetLabel}: ${value(_valueOf(item, horizontal))}',
    ],
    labelColor: (tooltip, item) {
      final color = apexSeriesColor(tooltip.chart as Chart, item.datasetIndex);
      return TooltipLabelStyle(
        borderColor: .solid(color),
        backgroundColor: .solid(color),
      );
    },
    labelPointStyle: (tooltip, item) => const .draw(CirclePointStyle()),
  ),
);

num _valueOf(TooltipItem item, bool horizontal) {
  final parsed = item.parsed! as JsObjectFace;
  return parsed[horizontal ? 'x' : 'y']! as num;
}

/// The color of the series [datasetIndex]: the line color, or the color of
/// the first bar.
Color apexSeriesColor(Chart chart, int datasetIndex) {
  final meta = chart.getDatasetMeta(datasetIndex);
  final paint = switch (meta.dataset?.options) {
    LineOptions(:final borderColor) => borderColor,
    _ => switch (meta.data.firstOrNull?.options) {
      BarOptions(:final backgroundColor) => backgroundColor,
      _ => null,
    },
  };
  return paint is SolidChartPaint ? paint.color : Apex.blue;
}

/// The place of the tooltip of apexcharts_flutter: 12 px right of the
/// hovered index and 8 px above its highest point, or left of it when the
/// tooltip does not fit. Over horizontal bars, it follows the pointer.
final class const ApexTipPositioner({final bool horizontal = false})
    extends TooltipPositioner {
  @override
  TooltipPosition? positionOf(
    TooltipModel tooltip,
    List<ActiveElement> items,
    Object? eventPosition,
  ) {
    if (items.isEmpty) return null;
    final chart = tooltip.chart as Chart;
    final double x;
    double y;
    if (horizontal) {
      final area = chart.chartArea!;
      final at = eventPosition is TooltipPosition ? eventPosition.x : null;
      final pointer = at is num ? at.toDouble() : area.left;
      x = pointer.clamp(area.left, area.right);
      final bar = items.first.element! as BarElement;
      y = bar.y;
    } else {
      x = apexFocusX(chart, items.first);
      y = double.infinity;
      for (final item in items) {
        y = math.min(y, item.element!.y);
      }
    }
    // The approximate width of apexcharts_flutter decides the side.
    final right = x + 12 + 160 <= chart.width;
    return TooltipPosition()
      ..x = right ? x + 12 + 5 : x - 12 - 5
      ..y = y
      ..xAlign = right ? .left : .right
      ..yAlign = .bottom;
  }
}

/// The x of a hovered index: the point, or the middle of the band of the
/// bars.
double apexFocusX(Chart chart, ActiveElement item) {
  final element = item.element!;
  if (element is! BarElement) return element.x;
  return chart.scales['x']!.getPixelForValue(item.index.toDouble());
}

/// The box of the tooltip: a white box with a gray border, a shadow and a
/// gray title bar. Chart.js draws the text over it.
final apexTooltipLook = Plugin<Object?>(
  id: 'apexTooltipLook',
  beforeTooltipDraw: (chart, args, options) {
    final tip = args.tooltip;
    if (tip.opacity == 0) return true;
    // The padding, one title line of 13 * 1.2 and the padding.
    const bar = 6 + 15.6 + 6;
    chart.ctx!
      ..save()
      ..globalAlpha = tip.opacity
      ..shadowColor = const Color(0x66999999)
      ..shadowBlur = 4
      ..shadowOffsetX = 2
      ..shadowOffsetY = 2
      ..fillStyle = Apex.tooltip
      ..beginPath()
      ..roundRect(tip.x, tip.y, tip.width, tip.height, 5)
      ..fill()
      ..shadowColor = const Color(0x00000000)
      ..save()
      ..clip()
      ..fillStyle = Apex.tooltipTitle
      ..fillRect(tip.x, tip.y, tip.width, bar)
      ..strokeStyle = Apex.tooltipTitleBorder
      ..lineWidth = 1
      ..beginPath()
      ..moveTo(tip.x, tip.y + bar + 0.5)
      ..lineTo(tip.x + tip.width, tip.y + bar + 0.5)
      ..stroke()
      ..restore()
      ..strokeStyle = Apex.tooltipBorder
      ..beginPath()
      ..roundRect(tip.x + 0.5, tip.y + 0.5, tip.width - 1, tip.height - 1, 5)
      ..stroke()
      ..restore();
    return true;
  },
);

/// The hover of apexcharts_flutter: a light vertical line at the hovered
/// index, and over a line a marker of the series color with a white ring
/// and a halo.
final apexHover = Plugin<Object?>(
  id: 'apexHover',
  afterDatasetsDraw: (chart, args, options) {
    final c = chart as Chart;
    final active = c.getActiveElements();
    if (active.isEmpty) return;
    final area = c.chartArea!;
    final ctx = c.ctx!..save();
    final first = active.first.element!;
    final horizontal = first is BarElement && (first.horizontal ?? false);
    if (!horizontal) {
      final x = apexFocusX(c, active.first);
      ctx
        ..strokeStyle = const Color(0x14000000)
        ..lineWidth = 1
        ..beginPath()
        ..moveTo(x, area.top)
        ..lineTo(x, area.bottom)
        ..stroke();
    }
    for (final item in active) {
      final element = item.element;
      if (element is! PointElement) continue;
      final solid = apexSeriesColor(c, item.datasetIndex);
      ctx
        ..fillStyle = solid.withValues(alpha: 0.25)
        ..beginPath()
        ..arc(element.x, element.y, 6, 0, 2 * math.pi)
        ..fill()
        ..fillStyle = solid
        ..beginPath()
        ..arc(element.x, element.y, 4, 0, 2 * math.pi)
        ..fill()
        ..strokeStyle = Colors.white
        ..lineWidth = 1.5
        ..stroke();
    }
    ctx.restore();
  },
);

/// `dataLabels: {enabled: true}`: the value of each point or bar, 11 px
/// semibold. A label is 8 px above a point, 2 px above a column, in the
/// middle of a stacked part, and 6 px past the end of a horizontal bar.
Plugin<Object?> apexDataLabels({bool stacked = false}) => Plugin(
  id: 'apexDataLabels',
  afterDatasetsDraw: (chart, args, options) {
    final c = chart as Chart;
    final ctx = c.ctx!
      ..save()
      ..font = toFont(
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      )
      ..fillStyle = Apex.text
      ..textAlign = TextAlign.center;
    for (final meta in c.getSortedVisibleDatasetMetas()) {
      for (final (j, element) in meta.data.indexed) {
        final parsed = meta.controller!.getParsed(j)! as JsObjectFace;
        if (element is BarElement) {
          final horizontal = element.horizontal ?? false;
          final v = parsed[horizontal ? 'x' : 'y']! as num;
          final text = apexNumber(v);
          if (horizontal) {
            ctx
              ..textAlign = TextAlign.left
              ..textBaseline = CanvasTextBaseline.middle
              ..fillText(text, element.x + 6, element.y);
          } else if (stacked) {
            ctx
              ..textBaseline = CanvasTextBaseline.middle
              ..fillText(text, element.x, (element.y + element.base) / 2);
          } else {
            ctx
              ..textBaseline = CanvasTextBaseline.bottom
              ..fillText(text, element.x, element.y - 2);
          }
        } else {
          ctx
            ..textBaseline = CanvasTextBaseline.top
            ..fillText(
              apexNumber(parsed['y']! as num),
              element.x,
              element.y - 8,
            );
        }
      }
    }
    ctx.restore();
  },
);

/// The area fill of apexcharts_flutter: a gradient over the plot from the
/// series color at [from] alpha on the top to a lighter color at [to]
/// alpha on the bottom. [shade] moves the lower color toward white.
ChartValue<ChartPaint> apexAreaFill(
  Color color, {
  double from = 0.65,
  double to = 0.5,
  double shade = 0.5,
}) {
  final lower = Color.lerp(color, Colors.white, shade)!;
  return .resolver((context) {
    final area = context.chart.chartArea;
    if (area == null) return ChartPaint.solid(color.withValues(alpha: from));
    return ChartGradient.linear(Offset(0, area.top), Offset(0, area.bottom), [
      color.withValues(alpha: from),
      lower.withValues(alpha: to),
    ]);
  });
}

/// The zoom of a line or an area chart, as in apexcharts_flutter: a drag
/// selects a range of the x axis, or pans it in the pan mode of the
/// toolbar. The wheel zooms with the Ctrl key, so that the wheel still
/// scrolls the page. The range stays inside the data.
final class ApexZoom() {
  /// The chart, from `onChartCreated`.
  Chart? chart;

  /// Whether a drag pans the x axis. Else it selects a range.
  final ValueNotifier<bool> panMode = ValueNotifier(false);

  /// Whether the x axis shows a part of the data.
  final ValueNotifier<bool> zoomed = ValueNotifier(false);

  /// The options of the zoom plugin, in `ChartConfig.pluginOptions`.
  late final ZoomPluginOptions options = ZoomPluginOptions(
    zoom: ZoomOptions(
      wheel: const WheelOptions(enabled: true, modifierKey: ModifierKey.ctrl),
      drag: const DragOptions(
        enabled: true,
        backgroundColor: .solid(Color(0x1A008FFB)),
        borderColor: .solid(Color(0x66008FFB)),
        borderWidth: 1,
      ),
      mode: Mode.x,
      // A drag zooms only in the selection mode. The wheel always zooms.
      onZoomStart: (context) => context.event.type == 'wheel' || !panMode.value,
      onZoomComplete: (context) => _update(context.chart),
    ),
    pan: PanOptions(
      enabled: true,
      mode: Mode.x,
      onPanStart: (context) => panMode.value,
      onPanComplete: (context) => _update(context.chart),
    ),
    limits: const {
      'x': ScaleLimits(min: ScaleLimit.original, max: ScaleLimit.original),
    },
  );

  void _update(Chart chart) => zoomed.value = chart.isZoomedOrPanned();

  /// The toolbar buttons: zoom in and out by 0.6 around the middle.
  void zoomIn() => _zoomBy(1 / 0.6);
  void zoomOut() => _zoomBy(0.6);

  void _zoomBy(double amount) {
    if (chart case final chart?) {
      chart.zoom(ZoomAmount(x: amount));
      _update(chart);
    }
  }

  void reset() {
    chart?.resetZoom();
    zoomed.value = false;
  }

  /// Zooms the x axis to the range from [min] to [max].
  void zoomTo(double min, double max) {
    chart?.zoomScale('x', (min: min, max: max));
    if (chart case final chart?) _update(chart);
  }

  void dispose() {
    panMode.dispose();
    zoomed.dispose();
  }
}

/// A line or an area chart with zoom: the chart of [config] and the zoom
/// toolbar of apexcharts_flutter in its top right corner. [config] gets the
/// zoom state, and gives `zoomPlugin` and its options to the chart.
class const ApexZoomChart({
  required final ChartConfig Function(ApexZoom zoom) config,
  required final String semanticLabel,
  final ApexZoom? zoom,
  final double height = 320,
  super.key,
}) extends StatefulWidget {
  @override
  State<ApexZoomChart> createState() => _ApexZoomChartState();
}

class _ApexZoomChartState() extends State<ApexZoomChart> {
  late final ApexZoom _zoom = widget.zoom ?? ApexZoom();
  late final ChartConfig _config = widget.config(_zoom);

  @override
  void dispose() {
    if (widget.zoom == null) _zoom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: widget.height,
    child: Stack(
      children: [
        Positioned.fill(
          child: ChartView(
            config: _config,
            semanticLabel: widget.semanticLabel,
            onChartCreated: (chart) => _zoom.chart = chart,
          ),
        ),
        Positioned(top: 4, right: 8, child: ApexToolbar(zoom: _zoom)),
      ],
    ),
  );
}

/// The plugins of a chart with zoom.
List<Plugin<Object?>> apexZoomPlugins(List<Plugin<Object?>> plugins) => [
  zoomPlugin,
  ...plugins,
];

/// The zoom toolbar of apexcharts_flutter: zoom in, zoom out, the
/// selection mode, the pan mode and reset.
class const ApexToolbar({required final ApexZoom zoom, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xF7FFFFFF),
    borderRadius: BorderRadius.circular(6),
    elevation: 1,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: ListenableBuilder(
        listenable: Listenable.merge([zoom.panMode, zoom.zoomed]),
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToolButton(Icons.add, 'Zoom in', zoom.zoomIn),
            _ToolButton(Icons.remove, 'Zoom out', zoom.zoomOut),
            _ToolButton(
              Icons.search,
              'Selection zoom',
              () => zoom.panMode.value = false,
              active: !zoom.panMode.value,
            ),
            _ToolButton(
              Icons.pan_tool_outlined,
              'Panning',
              () => zoom.panMode.value = true,
              active: zoom.panMode.value,
            ),
            _ToolButton(
              Icons.home_outlined,
              'Reset zoom',
              zoom.zoomed.value ? zoom.reset : null,
              active: zoom.zoomed.value,
            ),
          ],
        ),
      ),
    ),
  );
}

class const _ToolButton(
  final IconData icon,
  final String label,
  final VoidCallback? onTap, {
  final bool active = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    button: true,
    child: InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Icon(
          icon,
          size: 16,
          color: active
              ? Apex.blue
              : onTap == null
              ? Apex.icon.withValues(alpha: 0.4)
              : Apex.icon,
        ),
      ),
    ),
  );
}
// #enddocregion apex-kit
