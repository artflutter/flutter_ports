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
import 'package:flutter_chartjs_port/src/js/js_undefined.dart' show undefined;
import 'package:flutter_chartjs_port/src/types/index.dart'
    show ActiveElement, ChartEvent, LegendElement, Tick;
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
/// A view of the context object of the chart.
extension type ChartContext._(Map<String, Object?> _context) {
  /// The chart.
  Chart get chart => _context['chart']! as Chart;

  /// The type of the context: `'chart'`, `'dataset'`, `'data'`, `'scale'`,
  /// `'tick'`, `'pointLabel'` or `'tooltip'`.
  String? get type => _string(_context['type']);

  /// The index of the dataset, or `null` in a chart context.
  int? get datasetIndex => _int(_context['datasetIndex']);

  /// The index of the data item, or `null` in a chart or a dataset context.
  int? get dataIndex => _int(_context['dataIndex']);

  /// Whether the element is active (hovered). `false` in a chart context.
  bool get active => _context['active'] == true;

  /// The data item of the dataset at [dataIndex], as the app gave it: a
  /// `num`, a `DataPoint` Map or another value. `null` outside a data
  /// context.
  Object? get raw => _defined(_context['raw']);

  /// The parsed values of the data item: a Map with a key for each axis,
  /// for example `x` and `y`, or a number for a pie or a doughnut. `null`
  /// outside a data context.
  Object? get parsed => _defined(_context['parsed']);
}

/// A tooltip item: the argument of the tooltip text callbacks
/// (`TooltipItem`, `index.d.ts:2978-3023`; `plugin.tooltip.js:127-146`).
///
/// A view of the item object of the tooltip.
extension type ChartTooltipItem._(Map<String, Object?> _item) {
  /// The chart.
  Chart get chart => _item['chart']! as Chart;

  /// The label of the data item: the label of `data.labels`, as the app
  /// gave it (a `String`, a `num`, a `DateTime` or a `List` of lines), or
  /// the formatted label of a time axis.
  Object? get label => _defined(_item['label']);

  /// The parsed values of the data item, as [ChartContext.parsed].
  Object? get parsed => _defined(_item['parsed']);

  /// The data item, as [ChartContext.raw].
  Object? get raw => _defined(_item['raw']);

  /// The value of the data item as the tooltip shows it.
  String get formattedValue => _string(_item['formattedValue']) ?? '';

  /// The index of the dataset in `data.datasets`.
  int get datasetIndex => _int(_item['datasetIndex'])!;

  /// The index of the data item in the dataset.
  int get dataIndex => _int(_item['dataIndex'])!;

  /// The `label` of the dataset, or `null` for a dataset without a String
  /// label.
  String? get datasetLabel {
    final dataset = _item['dataset'];
    return dataset is Map ? _string(dataset['label']) : null;
  }
}

/// A legend item: the argument of the legend handlers
/// (`LegendItem`, `index.d.ts:2326-2412`; `plugin.legend.js:675-701`).
///
/// A view of the item object of the legend.
extension type ChartLegendItem._(Map<Object?, Object?> _item) {
  /// The text of the item, or `null` for a text that is not a `String`.
  String? get text => _string(_item['text']);

  /// The index of the dataset of the item, or `null` for an item of a data
  /// item (pie, doughnut, polar area).
  int? get datasetIndex => _int(_item['datasetIndex']);

  /// The index of the data item of the item (pie, doughnut, polar area), or
  /// `null` for an item of a dataset.
  int? get index => _int(_item['index']);

  /// Whether the dataset or the data item of the item is hidden.
  bool get hidden => _item['hidden'] == true;
}

/// [value] as an `int`, or `null` for a value that is not a finite number.
int? _int(Object? value) =>
    value is num && value.isFinite ? value.toInt() : null;

/// [value] when it is a `String`, else `null`.
String? _string(Object? value) => value is String ? value : null;

/// [value], or `null` for the JS `undefined`.
Object? _defined(Object? value) => identical(value, undefined) ? null : value;
