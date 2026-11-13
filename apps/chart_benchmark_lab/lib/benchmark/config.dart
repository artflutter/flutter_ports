import 'package:material_ui/material_ui.dart';

/// Engines installed in this benchmark, with reproducible dependency versions.
enum ChartLibrary(
  /// Display name.
  final String label,

  /// Pinned dependency version.
  final String version,

  /// Engine identity color, independent of chart styling.
  final Color color,
) {
  /// Our native Chart.js port.
  chartjs('Chart.js port', '0.1.0', Color(0xff4f46e5)),

  /// FL Chart.
  flChart('fl_chart', '1.3.0', Color(0xff0891b2)),

  /// Graphic grammar of graphics.
  graphic('Graphic', '2.7.0', Color(0xffb45309)),

  /// Syncfusion's native Flutter charts.
  syncfusion('Syncfusion', '35.1.43', Color(0xffbe185d));

  /// Whether the public API of this library can draw [type].
  ///
  /// Syncfusion 35.1.43 has no radar or polar series. Only the Chart.js port
  /// has a sankey chart, through `flutter_chartjs_chart_sankey_port`, the port
  /// of chartjs-chart-sankey: fl_chart 1.3.0, Graphic 2.7.0 and Syncfusion
  /// 35.1.43 have none. The harness does not stand in another drawing for a
  /// missing chart, because that would measure the stand-in and not the
  /// library.
  bool supports(ChartType type) => switch (type) {
    ChartType.sankey => this == chartjs,
    ChartType.radar => this != syncfusion,
    _ => true,
  };

  /// The reason that a chart of [type] does not run on this library.
  String unsupportedReason(ChartType type) =>
      '$label $version has no ${type.label.toLowerCase()} chart.';

  /// Whether the public API of this library draws the series shadow of a
  /// chart of [type], with or without [blur].
  ///
  /// fl_chart has a shadow only on the line of a line chart. Graphic has
  /// only Material elevation: it always blurs, and on a line it shadows the
  /// filled polygon and not the stroke. Syncfusion has no public shadow.
  bool drawsShadow(ChartType type, {required bool blur}) => switch (this) {
    chartjs => true,
    flChart => type == ChartType.line,
    graphic => blur && !type.drawsLine,
    syncfusion => false,
  };

  /// Whether the public API of this library zooms and pans the x axis of a
  /// chart of [type], with the y axis fixed.
  ///
  /// Each library has it on each type with an x axis ([ChartType.hasZoom]):
  /// - the Chart.js port through the zoom port
  ///   `flutter_chartjs_plugin_zoom_port` (chartjs-plugin-zoom), with the
  ///   options `pan` and `zoom` (`wheel`, `pinch`) of mode `x`;
  /// - fl_chart through `transformationConfig` (`FlTransformationConfig`) of
  ///   `LineChart`, `BarChart` and `ScatterChart`, with
  ///   `FlScaleAxis.horizontal`;
  /// - Graphic through `horizontalRangeUpdater` of `RectCoord`, from
  ///   `Defaults.horizontalRangeEvent`;
  /// - Syncfusion through `ZoomPanBehavior` of `SfCartesianChart`, with
  ///   `ZoomMode.x`.
  ///
  /// The sankey chart of the Chart.js port zooms and pans its hidden x
  /// scale, the scale of the node columns, in the same way.
  ///
  /// A pie, a doughnut, a polar area and a radar have no x axis, and the
  /// settings hide the toggle for them.
  ///
  /// A touch pinch and the mouse wheel zoom each library, and a drag pans it.
  /// A desktop trackpad differs, because the native desktop sends its pinch
  /// and its two-finger scroll as pan-zoom events, not as a wheel:
  /// - a trackpad pinch zooms fl_chart and Graphic;
  /// - Syncfusion reads each pan-zoom step as a wheel step by its vertical
  ///   pan: a two-finger vertical scroll zooms, and a pinch only zooms out;
  /// - the host of the Chart.js port gives a trackpad scroll and pinch as
  ///   `wheel` events, as Chrome does (Chart.js ADR 0137), while
  ///   [BenchmarkConfig.trackpad] is on: a scroll and a pinch zoom it.
  bool zoomsWith(ChartType type) => type.hasZoom;

  /// Whether this library can run [config] with its public API.
  bool runs(BenchmarkConfig config) =>
      supports(config.type) &&
      (!config.shadows || drawsShadow(config.type, blur: config.shadowBlur)) &&
      (!config.zooms || zoomsWith(config.type));

  /// The reason that [config] does not run on this library.
  String reasonFor(BenchmarkConfig config) {
    final type = config.type.label.toLowerCase();
    if (!supports(config.type)) return unsupportedReason(config.type);
    if (config.shadows && !drawsShadow(config.type, blur: config.shadowBlur)) {
      return '$label $version has no '
          '${config.shadowBlur ? 'blurred' : 'sharp'} shadow on a $type chart.';
    }
    return '$label $version has no zoom and pan on a $type chart.';
  }

  /// The short form of [reasonFor], for the library selector.
  String shortReasonFor(BenchmarkConfig config) {
    if (!supports(config.type)) {
      return 'No ${config.type.label.toLowerCase()} chart';
    }
    return config.shadows && !drawsShadow(config.type, blur: config.shadowBlur)
        ? 'No shadow here'
        : 'No zoom here';
  }
}

/// The eight chart types of Chart.js, on every adapter that has them, and the
/// sankey chart of the add-on chartjs-chart-sankey.
enum ChartType(
  /// Display name.
  final String label,

  /// Control icon.
  final IconData icon,
) {
  /// Ordered x/y line.
  line('Line', Icons.show_chart),

  /// Vertical bars, one per value.
  bar('Bar', Icons.bar_chart),

  /// Independent x/y points.
  scatter('Scatter', Icons.scatter_plot),

  /// Independent x/y points with a radius for each point.
  bubble('Bubble', Icons.bubble_chart),

  /// Positive values rendered as slices.
  pie('Pie', Icons.pie_chart_outline),

  /// Positive values rendered as slices of a ring.
  doughnut('Doughnut', Icons.donut_large),

  /// Equal-angle slices with a radius for each value.
  polarArea('Polar area', Icons.incomplete_circle),

  /// A closed line around a center, with one spoke per value.
  radar('Radar', Icons.radar),

  /// Flows between nodes in columns, one flow per value.
  sankey('Sankey', Icons.account_tree_outlined);

  /// Whether the line settings for point markers and area fill apply.
  bool get drawsLine => this == line || this == radar;

  /// Whether the axis and grid settings apply on every library with this type.
  ///
  /// A polar area has no axes here: fl_chart and Syncfusion draw it with a pie
  /// chart, which has no axis or grid.
  ///
  /// A sankey chart has no axes: its scales are hidden.
  bool get hasAxes =>
      this != pie && this != doughnut && this != polarArea && this != sankey;

  /// Whether the alternating item colors apply. On a sankey chart, they are
  /// the two colors of the gradient of each flow.
  bool get hasItemColors => !drawsLine;

  /// Whether the series shadow applies. The shadow of the Chart.js port is an
  /// option of its typed datasets, and a sankey chart has no typed dataset.
  bool get hasShadow => this != sankey;

  /// Whether zoom and pan apply: the types with an x axis, and the sankey
  /// chart, whose hidden x scale places the node columns.
  bool get hasZoom =>
      this == line ||
      this == bar ||
      this == scatter ||
      this == bubble ||
      this == sankey;
}

/// Public-widget workload; these are not internal renderer draw-only calls.
enum Workload(
  /// Display name.
  final String label,
) {
  /// New values on every display tick.
  live('Live data'),

  /// Dispose and recreate the chart with unchanged values.
  rebuild('Recreate chart'),
}

/// Shared chart appearance, with no engine-specific defaults.
const chartBlue = Color(0xff4f6bed);

/// Alternating item color.
const chartTeal = Color(0xff12a89d);

/// Common grid stroke.
const chartGrid = Color(0xffe5e9f1);

/// Common series shadow color.
const chartShadow = Color(0x59000000);

/// Common series shadow offset, in logical pixels.
const chartShadowOffset = Offset(0, 3);

/// Common Gaussian sigma of a blurred series shadow, in logical pixels.
const chartShadowSigma = 4.0;

/// The largest zoom of the x axis, as a share of the full range: the default
/// of Syncfusion (`maximumZoomLevel` 0.01). Each library takes the same limit.
const chartMaxZoom = 100.0;

/// Immutable test configuration; library selection is deliberately separate.
@immutable
class const BenchmarkConfig({
  /// Selected chart type.
  final ChartType type = ChartType.line,

  /// Number of actual data items; never downsampled by the harness.
  final int count = 1000,

  /// Shared update workload.
  final Workload workload = Workload.live,

  /// Point markers of a line or a radar.
  final bool markers = false,

  /// Library-native smooth line geometry.
  final bool curved = false,

  /// Fill under a line or inside a radar.
  final bool fill = false,

  /// Axis labels, of cartesian axes or around a radar.
  final bool axes = false,

  /// Grid lines, of cartesian axes or the rings and spokes of a radar.
  final bool grid = false,

  /// Alternating colors for bars, points, bubbles and slices.
  final bool alternateColors = false,

  /// Enable the selected library's pointer tooltip behavior.
  final bool tooltips = false,

  /// A shadow under the series, offset by [chartShadowOffset].
  final bool shadow = false,

  /// Blur the [shadow] with [chartShadowSigma].
  final bool shadowBlur = false,

  /// Zoom and pan of the x axis with the input of a person: a pinch or the
  /// mouse wheel zooms, a drag pans. It applies only to a type with an x axis
  /// ([zooms]). Each test starts with a new chart at the full range.
  final bool zoom = false,

  /// Whether the trackpad of the Chart.js port gives `wheel` events
  /// (`ChartView.trackpadGestures`, Chart.js ADR 0137): a two-finger scroll
  /// and a pinch then zoom it. The other libraries read the trackpad in
  /// their own way.
  final bool trackpad = true,

  /// Common overlay text count, outside each library's renderer.
  final int overlayLabels = 0,

  /// Rotate overlay labels with the shared frame index.
  final bool rotateLabels = false,

  /// Stable dataset seed.
  final int seed = 7,
}) {
  /// A repeatable line workload by default.
  this;

  /// Modify controls without losing the other settings.
  BenchmarkConfig copyWith({
    ChartType? type,
    int? count,
    Workload? workload,
    bool? markers,
    bool? curved,
    bool? fill,
    bool? axes,
    bool? grid,
    bool? alternateColors,
    bool? tooltips,
    bool? shadow,
    bool? shadowBlur,
    bool? zoom,
    bool? trackpad,
    int? overlayLabels,
    bool? rotateLabels,
    int? seed,
  }) => BenchmarkConfig(
    type: type ?? this.type,
    count: count ?? this.count,
    workload: workload ?? this.workload,
    markers: markers ?? this.markers,
    curved: curved ?? this.curved,
    fill: fill ?? this.fill,
    axes: axes ?? this.axes,
    grid: grid ?? this.grid,
    alternateColors: alternateColors ?? this.alternateColors,
    tooltips: tooltips ?? this.tooltips,
    shadow: shadow ?? this.shadow,
    shadowBlur: shadowBlur ?? this.shadowBlur,
    zoom: zoom ?? this.zoom,
    trackpad: trackpad ?? this.trackpad,
    overlayLabels: overlayLabels ?? this.overlayLabels,
    rotateLabels: rotateLabels ?? this.rotateLabels,
    seed: seed ?? this.seed,
  );

  @override
  bool operator ==(Object other) =>
      other is BenchmarkConfig &&
      other.type == type &&
      other.count == count &&
      other.workload == workload &&
      other.markers == markers &&
      other.curved == curved &&
      other.fill == fill &&
      other.axes == axes &&
      other.grid == grid &&
      other.alternateColors == alternateColors &&
      other.tooltips == tooltips &&
      other.shadow == shadow &&
      other.shadowBlur == shadowBlur &&
      other.zoom == zoom &&
      other.trackpad == trackpad &&
      other.overlayLabels == overlayLabels &&
      other.rotateLabels == rotateLabels &&
      other.seed == seed;

  @override
  int get hashCode => Object.hash(
    type,
    count,
    workload,
    markers,
    curved,
    fill,
    axes,
    grid,
    alternateColors,
    tooltips,
    shadow,
    shadowBlur,
    zoom,
    trackpad,
    overlayLabels,
    rotateLabels,
    seed,
  );

  /// Whether the chart zooms and pans: [zoom] on a type with an x axis.
  bool get zooms => zoom && type.hasZoom;

  /// Whether the series has a shadow: [shadow] on a type with a shadow.
  bool get shadows => shadow && type.hasShadow;

  /// Effective settings only; disabled controls cannot change comparability.
  Map<String, Object> toJson() => {
    'chart': type.name,
    'items': count,
    'workload': workload.name,
    'seed': seed,
    'markers': type.drawsLine && markers,
    'curved': type == ChartType.line && curved,
    'fill': type.drawsLine && fill,
    'axes': type.hasAxes && axes,
    'grid': type.hasAxes && grid,
    'alternateColors': type.hasItemColors && alternateColors,
    'tooltips': tooltips,
    // Only a set shadow adds a key, so the saved runs without one keep
    // their comparison keys.
    if (shadows) 'shadow': shadowBlur ? 'blurred' : 'sharp',
    // The same rule for zoom.
    if (zooms) 'zoom': true,
    if (zooms && !trackpad) 'trackpad': false,
    'overlayLabels': overlayLabels,
    'rotateLabels': overlayLabels > 0 && rotateLabels,
    'nativeTransitions': false,
  };
}
