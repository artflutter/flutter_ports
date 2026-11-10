import 'package:material_ui/material_ui.dart';

/// Engines installed in this benchmark, with reproducible dependency versions.
enum ChartLibrary {
  /// Our native Chart.js port.
  chartjs('Chart.js port', '0.1.0', Color(0xff4f46e5)),

  /// FL Chart.
  flChart('fl_chart', '1.3.0', Color(0xff0891b2)),

  /// Graphic grammar of graphics.
  graphic('Graphic', '2.7.0', Color(0xffb45309)),

  /// Syncfusion's native Flutter charts.
  syncfusion('Syncfusion', '35.1.43', Color(0xffbe185d));

  const ChartLibrary(this.label, this.version, this.color);

  /// Display name.
  final String label;

  /// Pinned dependency version.
  final String version;

  /// Engine identity color, independent of chart styling.
  final Color color;

  /// Whether the public API of this library can draw [type].
  ///
  /// Syncfusion 35.1.43 has no radar or polar series. The harness does not
  /// stand in another drawing for a missing chart, because that would measure
  /// the stand-in and not the library.
  bool supports(ChartType type) =>
      !(this == syncfusion && type == ChartType.radar);

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
  /// A pie, a doughnut, a polar area and a radar have no x axis, and the
  /// settings hide the toggle for them.
  ///
  /// A touch pinch and the mouse wheel zoom each library, and a drag pans it.
  /// A desktop trackpad differs, because the native desktop sends its pinch
  /// and its two-finger scroll as pan-zoom events, not as a wheel:
  /// - a trackpad pinch zooms fl_chart and Graphic;
  /// - Syncfusion reads each pan-zoom step as a wheel step by its vertical
  ///   pan: a two-finger vertical scroll zooms, and a pinch only zooms out;
  /// - the host of the Chart.js port maps no pan-zoom event (Chart.js ADR
  ///   0108 Open 5): a trackpad does not zoom or pan it.
  bool zoomsWith(ChartType type) => type.hasZoom;

  /// Whether this library can run [config] with its public API.
  bool runs(BenchmarkConfig config) =>
      supports(config.type) &&
      (!config.shadow || drawsShadow(config.type, blur: config.shadowBlur)) &&
      (!config.zooms || zoomsWith(config.type));

  /// The reason that [config] does not run on this library.
  String reasonFor(BenchmarkConfig config) {
    final type = config.type.label.toLowerCase();
    if (!supports(config.type)) return unsupportedReason(config.type);
    if (config.shadow && !drawsShadow(config.type, blur: config.shadowBlur)) {
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
    return config.shadow && !drawsShadow(config.type, blur: config.shadowBlur)
        ? 'No shadow here'
        : 'No zoom here';
  }
}

/// The eight chart types of Chart.js, on every adapter that has them.
enum ChartType {
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
  radar('Radar', Icons.radar);

  const ChartType(this.label, this.icon);

  /// Display name.
  final String label;

  /// Control icon.
  final IconData icon;

  /// Whether the line settings for point markers and area fill apply.
  bool get drawsLine => this == line || this == radar;

  /// Whether the axis and grid settings apply on every library with this type.
  ///
  /// A polar area has no axes here: fl_chart and Syncfusion draw it with a pie
  /// chart, which has no axis or grid.
  bool get hasAxes => this != pie && this != doughnut && this != polarArea;

  /// Whether the alternating item colors apply.
  bool get hasItemColors => !drawsLine;

  /// Whether zoom and pan apply: the types with an x axis.
  bool get hasZoom =>
      this == line || this == bar || this == scatter || this == bubble;
}

/// Public-widget workload; these are not internal renderer draw-only calls.
enum Workload {
  /// New values on every display tick.
  live('Live data'),

  /// Dispose and recreate the chart with unchanged values.
  rebuild('Recreate chart');

  const Workload(this.label);

  /// Display name.
  final String label;
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
class BenchmarkConfig {
  /// A repeatable line workload by default.
  const BenchmarkConfig({
    this.type = ChartType.line,
    this.count = 1000,
    this.workload = Workload.live,
    this.markers = false,
    this.curved = false,
    this.fill = false,
    this.axes = false,
    this.grid = false,
    this.alternateColors = false,
    this.tooltips = false,
    this.shadow = false,
    this.shadowBlur = false,
    this.zoom = false,
    this.overlayLabels = 0,
    this.rotateLabels = false,
    this.seed = 7,
  });

  /// Selected chart type.
  final ChartType type;

  /// Number of actual data items; never downsampled by the harness.
  final int count;

  /// Shared update workload.
  final Workload workload;

  /// Point markers of a line or a radar.
  final bool markers;

  /// Library-native smooth line geometry.
  final bool curved;

  /// Fill under a line or inside a radar.
  final bool fill;

  /// Axis labels, of cartesian axes or around a radar.
  final bool axes;

  /// Grid lines, of cartesian axes or the rings and spokes of a radar.
  final bool grid;

  /// Alternating colors for bars, points, bubbles and slices.
  final bool alternateColors;

  /// Enable the selected library's pointer tooltip behavior.
  final bool tooltips;

  /// A shadow under the series, offset by [chartShadowOffset].
  final bool shadow;

  /// Blur the [shadow] with [chartShadowSigma].
  final bool shadowBlur;

  /// Zoom and pan of the x axis with the input of a person: a pinch or the
  /// mouse wheel zooms, a drag pans. It applies only to a type with an x axis
  /// ([zooms]). Each test starts with a new chart at the full range.
  final bool zoom;

  /// Common overlay text count, outside each library's renderer.
  final int overlayLabels;

  /// Rotate overlay labels with the shared frame index.
  final bool rotateLabels;

  /// Stable dataset seed.
  final int seed;

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
    overlayLabels,
    rotateLabels,
    seed,
  );

  /// Whether the chart zooms and pans: [zoom] on a type with an x axis.
  bool get zooms => zoom && type.hasZoom;

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
    if (shadow) 'shadow': shadowBlur ? 'blurred' : 'sharp',
    // The same rule for zoom.
    if (zooms) 'zoom': true,
    'overlayLabels': overlayLabels,
    'rotateLabels': overlayLabels > 0 && rotateLabels,
    'nativeTransitions': false,
  };
}
