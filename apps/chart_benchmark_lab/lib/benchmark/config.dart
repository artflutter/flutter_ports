import 'package:flutter/material.dart';

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
}

/// Common chart types implemented by every adapter.
enum ChartType {
  /// Ordered x/y line.
  line('Line', Icons.show_chart),

  /// Vertical bars, one per value.
  bar('Bar', Icons.bar_chart),

  /// Independent x/y points.
  scatter('Scatter', Icons.scatter_plot),

  /// Positive values rendered as slices.
  pie('Pie', Icons.pie_chart_outline);

  const ChartType(this.label, this.icon);

  /// Display name.
  final String label;

  /// Control icon.
  final IconData icon;
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

  /// Line point markers.
  final bool markers;

  /// Library-native smooth line geometry.
  final bool curved;

  /// Fill under a line.
  final bool fill;

  /// Cartesian axis labels.
  final bool axes;

  /// Cartesian grid lines.
  final bool grid;

  /// Alternating colors for bars, scatter points and slices.
  final bool alternateColors;

  /// Enable the selected library's pointer tooltip behavior.
  final bool tooltips;

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
    overlayLabels: overlayLabels ?? this.overlayLabels,
    rotateLabels: rotateLabels ?? this.rotateLabels,
    seed: seed ?? this.seed,
  );

  /// Effective settings only; disabled controls cannot change comparability.
  Map<String, Object> toJson() => {
    'chart': type.name,
    'items': count,
    'workload': workload.name,
    'seed': seed,
    'markers': type == ChartType.line && markers,
    'curved': type == ChartType.line && curved,
    'fill': type == ChartType.line && fill,
    'axes': type != ChartType.pie && axes,
    'grid': type != ChartType.pie && grid,
    'alternateColors': type != ChartType.line && alternateColors,
    'tooltips': tooltips,
    'overlayLabels': overlayLabels,
    'rotateLabels': overlayLabels > 0 && rotateLabels,
    'nativeTransitions': false,
  };
}
