// Original code, not ported from Chart.js: the root of the typed config.

/// The root of the typed config (Chart.js ADR 0052, sections 1 and 7):
/// [ChartConfig], the chart type [ChartKind] and the index axis
/// [IndexAxis].
library;

import 'package:flutter/foundation.dart'
    show DiagnosticPropertiesBuilder, Diagnosticable, ValueChanged, immutable;
import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_chartjs_port/src/typed/axes.dart' show ChartAxis;
import 'package:flutter_chartjs_port/src/typed/callbacks.dart'
    show ChartEventDetails;
import 'package:flutter_chartjs_port/src/typed/datasets.dart' show Dataset;
import 'package:flutter_chartjs_port/src/typed/groups.dart'
    show
        ChartAnimation,
        ChartInteraction,
        ChartLegend,
        ChartTitle,
        ChartTooltip;
import 'package:flutter_chartjs_port/src/typed/props.dart';

/// The config of a chart: the chart type, the data and the options of a
/// Chart.js config `{type, data, options, plugins}`
/// (`docs/configuration/index.md`).
///
/// ```dart
/// ChartConfig(
///   type: .bar,
///   labels: const ['Red', 'Blue', 'Yellow'],
///   datasets: [BarDataset(label: '# of Votes', data: votes)],
///   scales: const {'y': LinearAxis(beginAtZero: true)},
///   onClick: showVotes,
/// )
/// ```
///
/// The chart reads the Maps of the Chart.js config. The typed config
/// lowers to these Maps: each class lowers to a new Map with the keys of
/// its parameters, and a parameter that is `null` writes no key. Thus a
/// `const` config works. The Lists of the app (`data`, `points`, [labels]
/// and [plugins]) go to the chart by reference, with no copy. The
/// [Dataset] class gives the controller of the dataset: a dataset of
/// another type than [type] makes a mixed chart (`docs/charts/mixed.md`).
///
/// A config is immutable. `==` compares the parameters: the Lists of the
/// app by identity, the [datasets] by their items, the [scales] and the
/// `extra` Maps by their entries, and the callbacks [onClick] and
/// [onHover] only by their presence. The chart calls the callback of the
/// newest config. Thus a new config that is `==` to the last one does not
/// update the chart. For new data, give a new List. Or change the List and
/// call `chart.update()`.
///
/// The config of a live chart, `chart.config`, is a `ChartConfiguration`,
/// another type.
@immutable
final class ChartConfig with Diagnosticable {
  /// A chart config.
  const ChartConfig({
    required this.type,
    required this.datasets,
    this.labels,
    this.scales,
    this.indexAxis,
    this.responsive,
    this.maintainAspectRatio,
    this.aspectRatio,
    this.padding,
    this.legend,
    this.title,
    this.subtitle,
    this.tooltip,
    this.interaction,
    this.animation,
    this.onClick,
    this.onHover,
    this.plugins,
    this.extra,
  });

  /// The chart type: `type`. It gives the controller of each dataset that
  /// has the class of this type, and the defaults of the options.
  final ChartKind type;

  /// The datasets of the chart: `data.datasets`. The legend shows them in
  /// this order.
  final List<Dataset> datasets;

  /// The labels of the index axis: `data.labels`. An item is a `String`, a
  /// `num`, a `DateTime` or a `List<String>` of the lines of a label.
  ///
  /// The List goes to the chart by reference. The category scale adds a
  /// label to it for a data item with a label that is not in the List:
  /// `DataPoint.label` and `CategoryAxis.min` can do that. A `const` List
  /// then throws an `UnsupportedError`.
  final List<Object>? labels;

  /// The axes of the chart by id: `options.scales`, for example
  /// `{'x': CategoryAxis(), 'y': LinearAxis(beginAtZero: true)}`.
  ///
  /// The order of the entries is the order of the axes in the layout. A
  /// chart type has default axes: give only the axes with other options.
  final Map<String, ChartAxis>? scales;

  /// The index axis of the chart: `options.indexAxis`. [IndexAxis.y] gives
  /// a horizontal bar chart. It also sets the default axes.
  final IndexAxis? indexAxis;

  /// Whether the chart resizes with its box: `options.responsive`. The
  /// default is `true`.
  final bool? responsive;

  /// Whether the chart keeps its aspect ratio when it resizes:
  /// `options.maintainAspectRatio`. The default is `true`.
  final bool? maintainAspectRatio;

  /// The width divided by the height of the chart: `options.aspectRatio`.
  /// The default is 2, and 1 for a pie, a doughnut, a polar area and a
  /// radar chart.
  final double? aspectRatio;

  /// The space around the chart: `options.layout.padding`.
  final EdgeInsets? padding;

  /// The legend: `options.plugins.legend`.
  final ChartLegend? legend;

  /// The title: `options.plugins.title`.
  final ChartTitle? title;

  /// The subtitle below the title: `options.plugins.subtitle`.
  final ChartTitle? subtitle;

  /// The tooltip: `options.plugins.tooltip`.
  final ChartTooltip? tooltip;

  /// The elements that an event hits: `options.interaction`.
  final ChartInteraction? interaction;

  /// The animation: `options.animation`. [ChartAnimation.none] turns it
  /// off.
  final ChartAnimation? animation;

  /// The function of a click on the chart: `options.onClick`. The details
  /// give the elements under the pointer, with `int` indexes
  /// (`docs/configuration/interactions.md`, "Events").
  final ValueChanged<ChartEventDetails>? onClick;

  /// The function of a pointer move on the chart: `options.onHover`.
  final ValueChanged<ChartEventDetails>? onHover;

  /// The inline plugins of the chart: `plugins`, each a plugin Map with an
  /// `id` and its hooks (`docs/developers/plugins.md`). The List goes to
  /// the chart by reference.
  final List<Map<String, Object?>>? plugins;

  /// The Chart.js options that have no parameter, for example
  /// `{'locale': 'de-DE'}`.
  ///
  /// The entries go into `options` last: an entry wins over a parameter
  /// with the same key. A Map value merges into the Map of the key, a List
  /// or another value replaces it. The chart gets a copy of each Map and
  /// the Lists of the app.
  final Map<String, Object?>? extra;

  /// A copy of this config with the given parameters. A parameter that is
  /// `null` keeps its value.
  ChartConfig copyWith({
    ChartKind? type,
    List<Dataset>? datasets,
    List<Object>? labels,
    Map<String, ChartAxis>? scales,
    IndexAxis? indexAxis,
    bool? responsive,
    bool? maintainAspectRatio,
    double? aspectRatio,
    EdgeInsets? padding,
    ChartLegend? legend,
    ChartTitle? title,
    ChartTitle? subtitle,
    ChartTooltip? tooltip,
    ChartInteraction? interaction,
    ChartAnimation? animation,
    ValueChanged<ChartEventDetails>? onClick,
    ValueChanged<ChartEventDetails>? onHover,
    List<Map<String, Object?>>? plugins,
    Map<String, Object?>? extra,
  }) => ChartConfig(
    type: type ?? this.type,
    datasets: datasets ?? this.datasets,
    labels: labels ?? this.labels,
    scales: scales ?? this.scales,
    indexAxis: indexAxis ?? this.indexAxis,
    responsive: responsive ?? this.responsive,
    maintainAspectRatio: maintainAspectRatio ?? this.maintainAspectRatio,
    aspectRatio: aspectRatio ?? this.aspectRatio,
    padding: padding ?? this.padding,
    legend: legend ?? this.legend,
    title: title ?? this.title,
    subtitle: subtitle ?? this.subtitle,
    tooltip: tooltip ?? this.tooltip,
    interaction: interaction ?? this.interaction,
    animation: animation ?? this.animation,
    onClick: onClick ?? this.onClick,
    onHover: onHover ?? this.onHover,
    plugins: plugins ?? this.plugins,
    extra: extra ?? this.extra,
  );

  List<TypedProperty> get _props => [
    ('type', type),
    ('datasets', byItems(datasets)),
    ('labels', labels),
    ('scales', byEntries(scales)),
    ('indexAxis', indexAxis),
    ('responsive', responsive),
    ('maintainAspectRatio', maintainAspectRatio),
    ('aspectRatio', aspectRatio),
    ('padding', padding),
    ('legend', legend),
    ('title', title),
    ('subtitle', subtitle),
    ('tooltip', tooltip),
    ('interaction', interaction),
    ('animation', animation),
    ('onClick', byPresence(onClick)),
    ('onHover', byPresence(onHover)),
    ('plugins', plugins),
    ('extra', byEntries(extra)),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartConfig && propsEqual(_props, other._props);

  @override
  int get hashCode => propsHash(_props);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    addProps(properties, _props);
  }
}

/// The type of a chart or of a dataset: the id of a registered controller,
/// the `type` of a Chart.js config (`core.config.js:93-95`).
///
/// The constants name the 8 controllers of Chart.js. The constructor names
/// a custom controller that the app registers (`Chart.register`). For a
/// type with no registered controller, the chart throws the upstream error
/// `"line" is not a registered controller.`, with the name of the type.
extension type const ChartKind(String name) {
  /// `'bar'`, `BarController`.
  static const ChartKind bar = ChartKind('bar');

  /// `'line'`, `LineController`.
  static const ChartKind line = ChartKind('line');

  /// `'scatter'`, `ScatterController`.
  static const ChartKind scatter = ChartKind('scatter');

  /// `'bubble'`, `BubbleController`.
  static const ChartKind bubble = ChartKind('bubble');

  /// `'pie'`, `PieController`.
  static const ChartKind pie = ChartKind('pie');

  /// `'doughnut'`, `DoughnutController`.
  static const ChartKind doughnut = ChartKind('doughnut');

  /// `'polarArea'`, `PolarAreaController`.
  static const ChartKind polarArea = ChartKind('polarArea');

  /// `'radar'`, `RadarController`.
  static const ChartKind radar = ChartKind('radar');
}

/// The index axis of a chart or of a dataset: the `indexAxis` option. The
/// option value is the [name].
///
/// The index axis holds the labels, and the value axis the data. Thus [x]
/// gives vertical bars, and [y] gives horizontal bars
/// (`docs/charts/bar.md`, "Horizontal Bar Chart").
enum IndexAxis {
  /// `'x'`: the labels on the x axis.
  x,

  /// `'y'`: the labels on the y axis.
  y,
}
