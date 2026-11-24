// Original code, not ported from Chart.js: the root of the typed config.

/// The root of the typed config (Chart.js ADR 0052, sections 1 and 7):
/// [ChartConfig] and the chart type [ChartKind]. The index axis is a
/// [CartesianAxis] of the core (row `adapt-axis-objects`).
library;

import 'dart:ui';

import 'package:flutter/foundation.dart'
    show DiagnosticPropertiesBuilder, Diagnosticable, immutable;
import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The config of a chart: the chart type, the data and the options of a
/// Chart.js config `{type, data, options, plugins}`
/// (`docs/configuration/index.md`).
///
/// ```dart
/// ChartConfig(
///   labels: const ['Red', 'Blue', 'Yellow'],
///   datasets: [BarDataset(label: '# of Votes', data: .values(votes))],
///   scales: const [LinearAxis(.y, beginAtZero: true)],
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
/// app by identity, the [datasets] by their items, the [plugins] by the
/// identity of their items, the [scales], the [events] and the
/// [disabledPlugins] by their items, the `extra` Maps by their entries, and
/// the callbacks [onClick] and [onHover] only by their presence. The chart
/// calls the callback of the newest config. Thus a new config that is `==`
/// to the last one does not update the chart. For new data, give a new List.
/// Or change the List and call `chart.update()`.
///
/// The config of a live chart, `chart.config`, is a `ChartConfiguration`,
/// another type.
@immutable
final class const ChartConfig({
  /// The datasets of the chart: `data.datasets`. The legend shows them in
  /// this order.
  ///
  /// The class of the first dataset gives the chart type ([type]). A chart
  /// needs one dataset at least: a debug build stops on an empty List. For
  /// a chart with no data yet, give a dataset with no data, for example
  /// `LineDataset(data: .values([]))`.
  required final List<Dataset> datasets,

  /// The labels of the index axis: `data.labels`. An item is a `String`, a
  /// `num`, a `DateTime` or a `List<String>` of the lines of a label.
  ///
  /// The List goes to the chart by reference. The category scale adds a
  /// label to it for a data item with a label that is not in the List:
  /// `DataPoint.label` and `CategoryAxis.min` can do that. A `const` List
  /// then throws an `UnsupportedError`.
  final List<Object>? labels,

  /// The axes of the chart: `options.scales`, for example
  /// `[CategoryAxis(.x), LinearAxis(.y, beginAtZero: true)]`.
  ///
  /// The order of the axes is the order of the layout. The first axis of a
  /// direction has the scale id `x`, `y` or `r`, the next ones `x1`, `y1`
  /// and so on (Chart.js ADR 0191). A dataset names its axis by the axis
  /// object (`LineDataset.yAxis`). The axes are distinct by `==`. A chart
  /// type has default axes: give only the axes with other options.
  final List<ChartAxis>? scales,

  /// The index axis of the chart: `options.indexAxis`, [XAxis] or [YAxis].
  /// `const YAxis()` gives a horizontal bar chart. It also sets the default
  /// axes.
  final CartesianAxis? indexAxis,

  /// Whether the chart parses the data items: `options.parsing`. The default
  /// is `true`. With `false`, the chart reads the [DataPoint] items of the
  /// datasets with no copy (`docs/general/performance.md`, "Data structure
  /// and format"). The decimation plugin needs `false`.
  final bool? parsing,

  /// Whether the chart resizes with its box: `options.responsive`. The
  /// default is `true`.
  final bool? responsive,

  /// Whether the chart keeps its aspect ratio when it resizes:
  /// `options.maintainAspectRatio`. The default is `true`.
  final bool? maintainAspectRatio,

  /// The width divided by the height of the chart: `options.aspectRatio`.
  /// The default is 2, and 1 for a pie, a doughnut, a polar area and a
  /// radar chart.
  final double? aspectRatio,

  /// The pixel ratio of the canvas: `options.devicePixelRatio`. The default
  /// is the device pixel ratio of the view.
  final double? devicePixelRatio,

  /// The locale of the number format of the ticks and the tooltip:
  /// `options.locale` (row `adapt-intl-number-format`), for example
  /// `Locale('de', 'DE')`. The default is the platform locale.
  final Locale? locale,

  /// Whether the data of each dataset is sorted by its index value and
  /// unique: `options.normalized`. Then the chart skips the sort and the
  /// search for the unique values (`docs/general/performance.md`).
  final bool? normalized,

  /// The default text color of the legend, the title and the ticks:
  /// `options.color`. The default is `#666`.
  final ChartPaint? color,

  /// The options of all datasets of a type: `options.datasets.<type>`
  /// (`docs/configuration/index.md`, "Dataset Configuration"). Each item
  /// gives the options of its class for each dataset of that type, for
  /// example `[LineDataset(spanGaps: true)]`. The `data` and the `label` of
  /// an item have no effect. A dataset option of a dataset wins.
  final List<Dataset>? datasetDefaults,

  /// Whether the layout adds the space that the points of the datasets need
  /// at the edges of the chart area: `options.layout.autoPadding`. The
  /// default is `true`.
  final bool? autoPadding,

  /// The space around the chart: `options.layout.padding`.
  final EdgeInsets? padding,

  /// The elements that an event hits: `options.interaction`.
  final ChartInteraction? interaction,

  /// The animation: `options.animation`. [ChartAnimation.none] turns it
  /// off.
  final ChartAnimation? animation,

  /// The animation of single properties of the elements:
  /// `options.animations`, for example
  /// `[RadiusAnimation(easing: Curves.elasticOut), YAnimation.off()]`.
  ///
  /// Each property has its ready class ([PropertyAnimation]). A parameter of
  /// an item that is `null` takes the value that the property has without
  /// the item. The List has one item for each class. The animations of the
  /// chart read each item as the object of this List: no option holds a
  /// copy of it.
  final List<PropertyAnimation>? animations,

  /// The animation of single update modes: `options.transitions`, for
  /// example `[HoverTransition(duration: Duration(milliseconds: 150))]`.
  ///
  /// Each mode has its ready class ([ChartTransition]): the hover, the show
  /// and the hide of a dataset, the resize and the reset. A parameter of an
  /// item goes before the parameter of [animation] in its mode. The List has
  /// one item for each class. The animations of the chart read each item as
  /// the object of this List.
  final List<ChartTransition>? transitions,

  /// The options of the element types, a default of all datasets of the
  /// chart: `options.elements`, for example
  /// `ChartElements(line: LineElementStyle(borderWidth: 3))`.
  final ChartElements? elements,

  /// The function of a click on the chart: `options.onClick`. It gets the
  /// event, the elements under the pointer with `int` indexes and the chart
  /// (`docs/configuration/interactions.md`, "Events").
  final ChartEventHandler? onClick,

  /// The function of a pointer move on the chart: `options.onHover`.
  final ChartEventHandler? onHover,

  /// The names of the input events that the chart listens to:
  /// `options.events`, for example `['click']`. The default is
  /// `['mousemove', 'mouseout', 'click', 'touchstart', 'touchmove']`
  /// (`docs/configuration/interactions.md`, "Events"). An empty List turns
  /// the input events off: no hover, no tooltip and no click.
  ///
  /// The chart gets a copy of the List. `==` compares its items.
  final List<String>? events,

  /// The options of the plugins as objects: each goes to
  /// `options.plugins.<pluginId>` (Chart.js ADRs 0148, 0192, 0193, 0196
  /// and 0197), for example the [TitleOptions] and [SubtitleOptions] of the
  /// title and the subtitle, the [LegendOptions] of the legend, the
  /// [TooltipOptions] of the tooltip, the [FillerOptions] of the filler, the
  /// [ColorsPluginOptions] of the colors plugin and the options of an add-on
  /// plugin. A plugin and its options come apart: a plugin that
  /// `Chart.register` adds for all charts takes the options of each chart
  /// here.
  ///
  /// ```dart
  /// pluginOptions: const [
  ///   TitleOptions(display: true, text: ['Sales']),
  ///   LegendOptions(position: ChartPosition.bottom),
  ///   TooltipOptions(mode: IndexInteractionMode()),
  /// ],
  /// ```
  ///
  /// `==` compares the options one by one with `==`.
  final List<PluginOptions<Object?>>? pluginOptions,

  /// The inline plugins of the chart: `plugins`, each a [Plugin] with an
  /// `id` and its hooks (`docs/developers/plugins.md`, Chart.js ADR 0144).
  /// The List goes to the chart by reference.
  ///
  /// `==` compares the plugins one by one by identity. Thus
  /// `plugins: [plugin]` in each build gives no update while `plugin` is
  /// the same object, for example a field or a top-level constant.
  final List<Plugin<Object?>>? plugins,

  /// The plugins that this chart turns off, by their class:
  /// `options.plugins.<id>: false` for each registered plugin and each
  /// inline plugin of [plugins] that an item matches
  /// (`docs/developers/plugins.md`, "Disable plugins"), for example
  /// `[PluginOff<LegendPlugin>()]`. An item that matches no plugin writes
  /// nothing.
  ///
  /// `==` compares the items one by one with `==`.
  final List<PluginOff<Plugin<Object?>>>? disabledPlugins,

  /// The Chart.js options that have no parameter, for example
  /// `{'locale': 'de-DE'}`.
  ///
  /// The entries go into `options` last: an entry wins over a parameter
  /// with the same key. A Map value merges into the Map of the key, a List
  /// or another value replaces it. The chart gets a copy of each Map and
  /// the Lists of the app.
  final Map<String, Object?>? extra,
}) with Diagnosticable {
  /// A chart config.
  this;

  /// The chart type, the `type` of the Chart.js config: the `kind` of the
  /// first dataset (Chart.js ADR 0190). It selects the chart-level defaults
  /// of the options, for example the default axes. A dataset of another
  /// class in a mixed chart writes its own `type`. An empty [datasets] List
  /// gives [ChartKind.line].
  ChartKind get type => datasets.isEmpty
      ? ChartKind.line
      // The lowering of the typed API reads the kind (Chart.js ADR 0189).
      // ignore: invalid_use_of_protected_member
      : datasets.first.kind;

  /// A copy of this config with the given parameters. A parameter that is
  /// `null` keeps its value.
  ChartConfig copyWith({
    List<Dataset>? datasets,
    List<Object>? labels,
    List<ChartAxis>? scales,
    CartesianAxis? indexAxis,
    bool? parsing,
    bool? responsive,
    bool? maintainAspectRatio,
    double? aspectRatio,
    double? devicePixelRatio,
    Locale? locale,
    bool? normalized,
    ChartPaint? color,
    List<Dataset>? datasetDefaults,
    bool? autoPadding,
    EdgeInsets? padding,
    ChartInteraction? interaction,
    ChartAnimation? animation,
    List<PropertyAnimation>? animations,
    List<ChartTransition>? transitions,
    ChartElements? elements,
    ChartEventHandler? onClick,
    ChartEventHandler? onHover,
    List<String>? events,
    List<PluginOptions<Object?>>? pluginOptions,
    List<Plugin<Object?>>? plugins,
    List<PluginOff<Plugin<Object?>>>? disabledPlugins,
    Map<String, Object?>? extra,
  }) => ChartConfig(
    datasets: datasets ?? this.datasets,
    labels: labels ?? this.labels,
    scales: scales ?? this.scales,
    indexAxis: indexAxis ?? this.indexAxis,
    parsing: parsing ?? this.parsing,
    responsive: responsive ?? this.responsive,
    maintainAspectRatio: maintainAspectRatio ?? this.maintainAspectRatio,
    aspectRatio: aspectRatio ?? this.aspectRatio,
    devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
    locale: locale ?? this.locale,
    normalized: normalized ?? this.normalized,
    color: color ?? this.color,
    datasetDefaults: datasetDefaults ?? this.datasetDefaults,
    autoPadding: autoPadding ?? this.autoPadding,
    padding: padding ?? this.padding,
    interaction: interaction ?? this.interaction,
    animation: animation ?? this.animation,
    animations: animations ?? this.animations,
    transitions: transitions ?? this.transitions,
    elements: elements ?? this.elements,
    onClick: onClick ?? this.onClick,
    onHover: onHover ?? this.onHover,
    events: events ?? this.events,
    pluginOptions: pluginOptions ?? this.pluginOptions,
    plugins: plugins ?? this.plugins,
    disabledPlugins: disabledPlugins ?? this.disabledPlugins,
    extra: extra ?? this.extra,
  );

  List<TypedProperty> get _props => [
    ('datasets', byItems(datasets)),
    ('labels', labels),
    ..._optionProps,
    _pluginsProp,
    _disabledPluginsProp,
    _extraProp,
  ];

  /// The properties of the parameters that lower into `options`, before
  /// [plugins].
  List<TypedProperty> get _optionProps => [
    ('scales', byItems(scales)),
    ('indexAxis', indexAxis),
    ('parsing', parsing),
    ('responsive', responsive),
    ('maintainAspectRatio', maintainAspectRatio),
    ('aspectRatio', aspectRatio),
    ('devicePixelRatio', devicePixelRatio),
    ('locale', locale),
    ('normalized', normalized),
    ('color', color),
    ('datasetDefaults', byItems(datasetDefaults)),
    ('autoPadding', autoPadding),
    ('padding', padding),
    ('interaction', interaction),
    ('animation', animation),
    ('animations', byItems(animations)),
    ('transitions', byItems(transitions)),
    ('elements', elements),
    ('onClick', byPresence(onClick)),
    ('onHover', byPresence(onHover)),
    ('events', byItems(events)),
    ('pluginOptions', byItems(pluginOptions)),
  ];

  /// The property of [plugins].
  TypedProperty get _pluginsProp => ('plugins', byIdentityItems(plugins));

  /// The property of [disabledPlugins], which lowers into `options` too.
  TypedProperty get _disabledPluginsProp =>
      ('disabledPlugins', byItems(disabledPlugins));

  /// The property of [extra], which lowers into `options` too.
  TypedProperty get _extraProp => ('extra', byEntries(extra));

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

/// Whether the parameters of [a] and [b] that lower into `options` are `==`:
/// all parameters but `type`, `datasets`, `labels` and `plugins`, with the
/// compare rules of `==` (Chart.js ADR 0052, section 9, step 4). Then the
/// reconcile keeps the live `options` Map.
bool optionFieldsEqual(ChartConfig a, ChartConfig b) =>
    propsEqual(a._optionProps, b._optionProps) &&
    a._disabledPluginsProp.$2 == b._disabledPluginsProp.$2 &&
    a._extraProp.$2 == b._extraProp.$2;

/// Whether the [ChartConfig.plugins] of [a] and [b] are `==`, by the compare
/// rule of `==`. Then the reconcile keeps the live `plugins` List.
bool pluginsEqual(ChartConfig a, ChartConfig b) =>
    a._pluginsProp.$2 == b._pluginsProp.$2;

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
