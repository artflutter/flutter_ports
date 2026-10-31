// Original code, not ported from Chart.js: the callbacks of the typed API.

/// The callback types of the typed API (Chart.js ADR 0052, section 6).
///
/// - The details objects [ChartEventDetails], [ChartLegendEventDetails],
///   [ChartAnimationDetails] and [AxisTickInfo] hold the arguments of one
///   call. A new field is an addition that breaks no callback.
/// - The views [ChartHit], [ChartContext], [ChartTooltipItem] and
///   [ChartLegendItem] are extension types over the objects of the chart,
///   with no copy. Their indexes are `int`: Chart.js gives a JS number,
///   which the port holds as a `double`.
/// - [ChartScript] is the type of a scriptable option.
///
/// A view has no public constructor: at run time, a view is the object of
/// the chart, so the typed API casts that object to the view
/// (`context as ChartContext`). A nullable getter of a view gives Dart
/// `null` for the JS `undefined`, for an absent key and for a value of
/// another type.
library;

import 'package:flutter_chartjs_port/src/core/core.controller.dart' show Chart;
import 'package:flutter_chartjs_port/src/core/core.scale.dart' show Scale;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ContextObject, ScriptableChartContext, ScriptableContext;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart' show undefined;
import 'package:flutter_chartjs_port/src/types/basic.dart' show AnyObject;
import 'package:flutter_chartjs_port/src/types/index.dart'
    show
        ActiveElement,
        ChartEvent,
        LegendElement,
        Tick,
        TypedLegendItem,
        TypedTooltipItem;
import 'package:meta/meta.dart' show immutable;

/// A scriptable option: a function of the context of the element, the
/// dataset or the chart that gives the value.
///
/// Chart.js calls it in each resolution of the option, for each element. The
/// value has no fallback: Chart.js takes the value of the function as it is
/// (`helpers.config.ts:255-273`).
typedef ChartScript<T> = T Function(ChartContext context);

/// The arguments of the event callbacks `onClick` and `onHover` of a chart
/// (`options.onClick`, `options.onHover`; `core.controller.js:1222-1226`).
@immutable
final class ChartEventDetails {
  /// The details of one event.
  const ChartEventDetails({
    required this.event,
    required this.hits,
    required this.chart,
  });

  /// The chart event: its `type` (`'click'`, `'mousemove'`, ...) and its
  /// position `x` and `y` in the chart.
  final ChartEvent event;

  /// The active elements of the event by the interaction options, in the
  /// order of the interaction mode. Empty when the event hits no element.
  final List<ChartHit> hits;

  /// The chart of the event.
  final Chart chart;
}

/// The arguments of the legend handlers `onClick`, `onHover` and `onLeave`
/// (`plugins.legend.onClick`; `plugin.legend.js:539-550`).
@immutable
final class ChartLegendEventDetails {
  /// The details of one legend event.
  const ChartLegendEventDetails({
    required this.event,
    required this.item,
    required this.legend,
  });

  /// The chart event.
  final ChartEvent event;

  /// The legend item under the event, or the item that the pointer left
  /// for `onLeave`.
  final ChartLegendItem item;

  /// The legend box.
  final LegendElement legend;
}

/// The arguments of the animation callbacks `onProgress` and `onComplete`
/// of a chart (`options.animation.onProgress`; `AnimationEvent`,
/// `animation.d.ts:13-18`; `core.animator.js:27-32`).
///
/// For example, a progress bar shows `currentStep / numSteps` in
/// `onProgress` (`docs/configuration/animations.md`, "Animation
/// Callbacks").
@immutable
final class ChartAnimationDetails {
  /// The details of one animation step.
  const ChartAnimationDetails({
    required this.chart,
    required this.initial,
    this.numSteps,
    this.currentStep,
  });

  /// The chart of the animation.
  final Chart chart;

  /// Whether the animation is the first animation of the chart, from its
  /// start. `false` after the first `onComplete`.
  final bool initial;

  /// The duration of the animations of the chart in milliseconds. `null`
  /// in the `onComplete` of a chart that draws with no animation.
  final double? numSteps;

  /// The milliseconds since the start of the animations, at most
  /// [numSteps]. `null` in the `onComplete` of a chart that draws with no
  /// animation.
  final double? currentStep;
}

/// The arguments of the tick label callback of an axis: the arguments
/// `value`, `index` and `ticks` and the `this` of the Chart.js `callback`
/// (`core.scale.js:574`).
@immutable
final class AxisTickInfo {
  /// The details of one tick.
  const AxisTickInfo({
    required this.value,
    required this.index,
    required this.ticks,
    required this.scale,
  });

  /// The value of the tick: a number of a linear or a logarithmic axis, the
  /// index of the label of a category axis, or the time value of a time
  /// axis in milliseconds.
  final double value;

  /// The index of the tick in [ticks].
  final int index;

  /// All ticks of the axis.
  final List<Tick> ticks;

  /// The scale of the axis. `scale.getLabelForValue(value)` gives the
  /// label of a category tick, as `this.getLabelForValue(value)` does in
  /// the Chart.js docs.
  final Scale scale;
}

/// An active element of an event: a hit of `onClick` and `onHover`.
///
/// A view of the `ActiveElement` of the chart, with `int` indexes. It
/// implements [ActiveElement], so a `List<ChartHit>` is a
/// `List<ActiveElement>`, for example for `chart.setActiveElements`.
extension type ChartHit._(ActiveElement _hit) implements ActiveElement {
  /// The index of the dataset in `data.datasets`.
  int get datasetIndex => _hit.datasetIndex.toInt();

  /// The index of the data item in the dataset.
  int get index => _hit.index.toInt();
}

/// The context of a scriptable option (`docs/general/options.md`, "Option
/// Context"): the chart context, a dataset context or a data context.
///
/// A view of the typed context object of the chart (Chart.js ADR 0054 §11):
/// the getters read the typed members of the dataset and the data context
/// (`ScriptableContext`) and of the chart context
/// (`ScriptableChartContext`). A context of another type has no dataset
/// member: its getters give `null` and `false`.
extension type ChartContext._(ContextObject _context) {
  /// The chart: the `chart` of the chart context, the first context of the
  /// prototype chain of each context (`createContext`).
  Chart get chart {
    for (
      AnyObject? context = _context;
      context is ContextObject;
      context = context.prototype
    ) {
      if (context is ScriptableChartContext) return context.chart! as Chart;
    }
    // A context without a chart context: the `TypeError` of a missing chart.
    throw TypeError();
  }

  /// The type of the context: `'chart'`, `'dataset'`, `'data'`, `'scale'`,
  /// `'tick'`, `'pointLabel'` or `'tooltip'`.
  String? get type => _string(_context.type);

  /// The dataset or the data context, or Dart `null` for a context of
  /// another type.
  ScriptableContext? get _dataContext => switch (_context) {
    final ScriptableContext context => context,
    _ => null,
  };

  /// The index of the dataset, or `null` in a chart context.
  int? get datasetIndex => _int(_dataContext?.datasetIndex);

  /// The index of the data item, or `null` in a chart or a dataset context.
  int? get dataIndex => _int(_dataContext?.dataIndex);

  /// Whether the element is active (hovered). `false` in a chart context.
  bool get active => _dataContext?.active == true;

  /// The data item of the dataset at [dataIndex], as the app gave it: a
  /// `num`, a `DataPoint` or another value. `null` outside a data context.
  Object? get raw => _defined(_dataContext?.raw);

  /// The parsed values of the data item: an object with a key for each
  /// axis, for example `x` and `y`, or a number for a pie or a doughnut.
  /// `null` outside a data context.
  Object? get parsed => _defined(_dataContext?.parsed);
}

/// A tooltip item: the argument of the tooltip text callbacks
/// (`TooltipItem`, `index.d.ts:2978-3023`; `plugin.tooltip.js:127-146`).
///
/// A view of the item object of the tooltip: the typed tooltip item of the
/// plugin ([TypedTooltipItem], Chart.js ADR 0054 §12), or an object of user
/// code, read by name.
extension type ChartTooltipItem._(Map<String, Object?> _item) {
  /// The chart.
  Chart get chart => _key(_TooltipKey.chart)! as Chart;

  /// The label of the data item: the label of `data.labels`, as the app
  /// gave it (a `String`, a `num`, a `DateTime` or a `List` of lines), or
  /// the formatted label of a time axis.
  Object? get label => _defined(_key(_TooltipKey.label));

  /// The parsed values of the data item, as [ChartContext.parsed].
  Object? get parsed => _defined(_key(_TooltipKey.parsed));

  /// The data item, as [ChartContext.raw].
  Object? get raw => _defined(_key(_TooltipKey.raw));

  /// The value of the data item as the tooltip shows it.
  String get formattedValue => _string(_key(_TooltipKey.formattedValue)) ?? '';

  /// The index of the dataset in `data.datasets`.
  int get datasetIndex => _int(_key(_TooltipKey.datasetIndex))!;

  /// The index of the data item in the dataset.
  int get dataIndex => _int(_key(_TooltipKey.dataIndex))!;

  /// The `label` of the dataset, or `null` for a dataset without a String
  /// label. The dataset is the dataset object of the app: a Map, read by
  /// name.
  String? get datasetLabel {
    final dataset = _key(_TooltipKey.dataset);
    return dataset is Map ? _string(_byName(dataset, 'label')) : null;
  }

  /// The value of [key]: the typed field of a [TypedTooltipItem], else the
  /// read by name.
  Object? _key(_TooltipKey key) => switch (_item) {
    final TypedTooltipItem item => switch (key) {
      _TooltipKey.chart => item.chart,
      _TooltipKey.label => item.label,
      _TooltipKey.parsed => item.parsed,
      _TooltipKey.raw => item.raw,
      _TooltipKey.formattedValue => item.formattedValue,
      _TooltipKey.dataset => item.dataset,
      _TooltipKey.datasetIndex => item.datasetIndex,
      _TooltipKey.dataIndex => item.dataIndex,
    },
    final item => _byName(item, key.name),
  };
}

/// The keys of a tooltip item that [ChartTooltipItem] reads.
enum _TooltipKey {
  chart,
  label,
  parsed,
  raw,
  formattedValue,
  dataset,
  datasetIndex,
  dataIndex,
}

/// A legend item: the argument of the legend handlers
/// (`LegendItem`, `index.d.ts:2326-2412`; `plugin.legend.js:675-701`).
///
/// A view of the item object of the legend: the typed legend item of the
/// plugin ([TypedLegendItem], Chart.js ADR 0054 §12), or an item that a
/// user `generateLabels` gives, read by name.
extension type ChartLegendItem._(Map<Object?, Object?> _item) {
  /// The text of the item, or `null` for a text that is not a `String`.
  String? get text => _string(
    switch (_item) {
      final TypedLegendItem item => item.text,
      final item => _byName(item, 'text'),
    },
  );

  /// The index of the dataset of the item, or `null` for an item of a data
  /// item (pie, doughnut, polar area).
  int? get datasetIndex => _int(
    switch (_item) {
      final TypedLegendItem item => item.datasetIndex,
      final item => _byName(item, 'datasetIndex'),
    },
  );

  /// The index of the data item of the item (pie, doughnut, polar area), or
  /// `null` for an item of a dataset.
  int? get index => _int(
    switch (_item) {
      final TypedLegendItem item => item.index,
      final item => _byName(item, 'index'),
    },
  );

  /// Whether the dataset or the data item of the item is hidden.
  bool get hidden =>
      switch (_item) {
        final TypedLegendItem item => item.hidden,
        final item => _byName(item, 'hidden'),
      } ==
      true;
}

/// The read by name `object[key]` of an object of user code in the place
/// of a typed item, and of the dataset object of the app.
Object? _byName(Map<Object?, Object?> object, String key) => object[key];

/// [value] as an `int`, or `null` for a value that is not a finite number.
int? _int(Object? value) =>
    value is num && value.isFinite ? value.toInt() : null;

/// [value] when it is a `String`, else `null`.
String? _string(Object? value) => value is String ? value : null;

/// [value], or `null` for the JS `undefined`.
Object? _defined(Object? value) => identical(value, undefined) ? null : value;
