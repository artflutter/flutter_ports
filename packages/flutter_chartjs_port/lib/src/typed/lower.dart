// Original code, not ported from Chart.js: the lowering of the typed config.

/// The lowering of the typed config (Chart.js ADR 0052, section 2):
/// [ChartConfigLowering], the root Map of a config, the conversions of the
/// typed values to their option values, the merge of the `extra` Maps and
/// the trampolines of the callbacks.
///
/// The typed config lowers to the scope Maps of Chart.js ADR 0043. The
/// resolver does not change, and the chart reads only the Maps. Each class
/// of the typed config lowers to a new `<String, Object?>` Map in its
/// library (`lowerDataset` of `datasets.dart`, `lowerAxis` of `axes.dart`,
/// `lowerLegend` and the other functions of `groups.dart`), with these
/// rules:
/// 1. The keys come in the order of the constructor parameters. A
///    parameter that is `null` writes no key.
/// 2. A List of the app goes by reference: `data`, `points`, `labels`,
///    `CategoryAxis.labels` and `plugins`. A small style List
///    (`backgroundColors`, `borderColors`, `borderDash`) lowers to a new
///    List.
/// 3. A `Color` lowers through [colorValue], a `TextStyle` through
///    `fontSpecOf` of `css.dart`, a `Duration` through [millisecondsOf] and
///    an `EdgeInsets` through [paddingValue]. A name type lowers to its
///    name or its `optionValue`, `IndexAxis` to its `name`.
/// 4. A plain value never lowers to a closure. Only a function parameter
///    does: [colorScript] for the scriptable colors, a `JsFunction` for the
///    tick format, and a trampoline for each event and text callback.
/// 5. A trampoline reads the callback of the newest config of its
///    [ChartConfigLowering] at each call ([eventTrampoline],
///    [legendTrampoline], [tooltipItemsTrampoline], [tooltipItemTrampoline]
///    and [animationTrampoline]). Thus a new closure in a config that is
///    `==` to the last one needs no new lowering.
/// 6. `extra` merges last ([mergeExtra]).
///
/// Internal: no public library exports it.
library;

import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show ValueChanged;
import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_chartjs_port/src/core/core.controller.dart' show Chart;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart' show undefined;
import 'package:flutter_chartjs_port/src/theme/css.dart' show colorToRgba;
import 'package:flutter_chartjs_port/src/typed/axes.dart' show lowerAxis;
import 'package:flutter_chartjs_port/src/typed/callbacks.dart'
    show
        ChartAnimationDetails,
        ChartContext,
        ChartEventDetails,
        ChartHit,
        ChartLegendEventDetails,
        ChartLegendItem,
        ChartScript,
        ChartTooltipItem;
import 'package:flutter_chartjs_port/src/typed/config.dart' show ChartConfig;
import 'package:flutter_chartjs_port/src/typed/datasets.dart' show lowerDataset;
import 'package:flutter_chartjs_port/src/typed/groups.dart'
    show
        lowerAnimation,
        lowerInteraction,
        lowerLegend,
        lowerTitle,
        lowerTooltip;
import 'package:flutter_chartjs_port/src/types/animation.dart'
    show AnimationEvent;
import 'package:flutter_chartjs_port/src/types/index.dart'
    show ChartEvent, LegendElement;
import 'package:meta/meta.dart' show internal;

/// The lowering of a typed config to the root Map of a Chart.js config
/// `{type, data, options, plugins}` (Chart.js ADR 0052, sections 2 and 9).
///
/// The lowering keeps the newest [config]: the trampolines of the
/// callbacks read it at each call. A widget that gets a new config that is
/// `==` to the last one sets [config] and lowers nothing.
@internal
final class ChartConfigLowering {
  /// The lowering of [config].
  ChartConfigLowering(this.config);

  /// The newest config. The trampolines read its callbacks.
  ChartConfig config;

  /// The root Map of [config]: a new Map at each call, with the keys
  /// `type`, `data` (`labels` by reference and a new `datasets` List),
  /// `options` (a new Map, `ChartConfig.extra` merged last) and `plugins`
  /// by reference.
  Map<String, Object?> lower() {
    final config = this.config;
    final plugins = <String, Object?>{
      if (config.legend case final legend?) 'legend': lowerLegend(legend, this),
      if (config.title case final title?) 'title': lowerTitle(title),
      if (config.subtitle case final subtitle?)
        'subtitle': lowerTitle(subtitle),
      if (config.tooltip case final tooltip?)
        'tooltip': lowerTooltip(tooltip, this),
    };
    final options = <String, Object?>{
      if (config.scales case final scales?)
        'scales': <String, Object?>{
          for (final MapEntry(key: id, value: axis) in scales.entries)
            id: lowerAxis(axis),
        },
      'indexAxis': ?config.indexAxis?.name,
      'responsive': ?config.responsive,
      'maintainAspectRatio': ?config.maintainAspectRatio,
      'aspectRatio': ?config.aspectRatio,
      if (config.padding case final padding?)
        'layout': <String, Object?>{'padding': paddingValue(padding)},
      if (plugins.isNotEmpty) 'plugins': plugins,
      if (config.interaction case final interaction?)
        'interaction': lowerInteraction(interaction),
      if (config.animation case final animation?)
        'animation': lowerAnimation(animation, this),
      if (config.onClick != null)
        'onClick': eventTrampoline(() => this.config.onClick),
      if (config.onHover != null)
        'onHover': eventTrampoline(() => this.config.onHover),
    };
    return <String, Object?>{
      'type': config.type.name,
      'data': <String, Object?>{
        'labels': ?config.labels,
        'datasets': <Object?>[
          for (final dataset in config.datasets)
            lowerDataset(dataset, config.type),
        ],
      },
      'options': mergeExtra(options, config.extra),
      'plugins': ?config.plugins,
    };
  }
}

/// The trampoline of the chart callback that [newest] reads:
/// `options.onClick` or `options.onHover`.
///
/// Chart.js calls it with the event, the active elements and the chart
/// (`core.controller.js:1222-1226`). It calls the callback of the newest
/// config with a [ChartEventDetails]. The active elements are the List of
/// the chart, with no copy: a `ChartHit` is an `ActiveElement` at run time.
Object? Function(Object?, Object?, Object?) eventTrampoline(
  ValueChanged<ChartEventDetails>? Function() newest,
) => (event, active, chart) {
  newest()?.call(
    ChartEventDetails(
      event: event! as ChartEvent,
      hits: active! as List<ChartHit>,
      chart: chart! as Chart,
    ),
  );
  return null;
};

/// The trampoline of the legend handler that [newest] reads: `onClick`,
/// `onHover` or `onLeave` of `plugins.legend`.
///
/// The legend calls it with the event, the legend item and the legend
/// (`plugin.legend.js:539-550`).
Object? Function(Object?, Object?, Object?) legendTrampoline(
  ValueChanged<ChartLegendEventDetails>? Function() newest,
) => (event, item, legend) {
  newest()?.call(
    ChartLegendEventDetails(
      event: event! as ChartEvent,
      item: item! as ChartLegendItem,
      legend: legend! as LegendElement,
    ),
  );
  return null;
};

/// The trampoline of a tooltip callback of the items that [newest] reads:
/// `callbacks.title` or `callbacks.footer` of `plugins.tooltip`.
///
/// The tooltip calls it with the List of the tooltip items. A callback
/// that gives Dart `null`, and a newest config without the callback, give
/// `undefined`: the tooltip then calls its default callback
/// (`plugin.tooltip.js:447-455`).
Object? Function(Object?) tooltipItemsTrampoline(
  String? Function(List<ChartTooltipItem> items)? Function() newest,
) => (items) {
  final callback = newest();
  if (callback == null) return undefined;
  return callback((items! as List<Object?>).cast<ChartTooltipItem>()) ??
      undefined;
};

/// The trampoline of the tooltip callback of one item that [newest] reads:
/// `callbacks.label` of `plugins.tooltip`. Dart `null` gives `undefined`,
/// as in [tooltipItemsTrampoline].
Object? Function(Object?) tooltipItemTrampoline(
  String? Function(ChartTooltipItem item)? Function() newest,
) => (item) {
  final callback = newest();
  if (callback == null) return undefined;
  return callback(item! as ChartTooltipItem) ?? undefined;
};

/// The trampoline of the animation callback that [newest] reads:
/// `onProgress` or `onComplete` of `options.animation`.
///
/// The chart calls it with the `AnimationEvent` of the animator
/// (`core.controller.js:33-46`).
Object? Function(Object?) animationTrampoline(
  ValueChanged<ChartAnimationDetails>? Function() newest,
) => (event) {
  final animation = event! as AnimationEvent;
  newest()?.call(
    ChartAnimationDetails(
      chart: animation.chart as Chart,
      initial: animation.initial ?? false,
      numSteps: animation.numSteps,
      currentStep: animation.currentStep,
    ),
  );
  return null;
};

/// The option value of [color]: its `rgba()` string through `colorToRgba`
/// of `css.dart`, the conversion of the theme (Chart.js ADR 0050). Dart
/// `null` for `null`.
String? colorValue(Color? color) => color == null ? null : colorToRgba(color);

/// The option value of a color with three forms: [color] as its string,
/// [colors] as a new List of strings, or [colorFor] as a scriptable
/// closure ([colorScript]). Dart `null` when the three are `null`.
///
/// The constructors of the typed classes assert that at most one is set.
Object? colorOption(
  Color? color,
  List<Color>? colors,
  ChartScript<Color>? colorFor,
) {
  if (color != null) return colorToRgba(color);
  if (colors != null) {
    return <Object?>[for (final color in colors) colorToRgba(color)];
  }
  if (colorFor != null) return colorScript(colorFor);
  return null;
}

/// The scriptable option of [colorFor]: a closure that gives the `rgba()`
/// string of the color of each context.
///
/// The closure takes the 2 arguments of a Chart.js scriptable option, the
/// context and the options resolver, and `jsCall` calls it with JS arity
/// (`js_function.dart`). The context is the context object of the chart,
/// so the cast to the view [ChartContext] makes no copy. The resolver sees a
/// function, so it resolves the options of each data item, as for a raw
/// closure (`core.config.js:351-366`, `:405-418`).
Object? Function(Object?, Object?) colorScript(ChartScript<Color> colorFor) =>
    (context, options) => colorToRgba(colorFor(context! as ChartContext));

/// The option value of [padding]: a new Map `{top, right, bottom, left}`
/// (`index.d.ts`, `Padding`). Dart `null` for `null`.
Map<String, Object?>? paddingValue(EdgeInsets? padding) => padding == null
    ? null
    : <String, Object?>{
        'top': padding.top,
        'right': padding.right,
        'bottom': padding.bottom,
        'left': padding.left,
      };

/// The option value of [duration]: the milliseconds, with the fraction of
/// the microseconds. Dart `null` for `null`.
double? millisecondsOf(Duration? duration) =>
    duration == null ? null : duration.inMicroseconds / 1000;

/// A new List of the numbers of [list], or Dart `null` for `null`.
List<Object?>? numberList(List<double>? list) =>
    list == null ? null : <Object?>[...list];

/// Merges [extra] into [map] and gives [map] (Chart.js ADR 0052, section 2
/// rule 9).
///
/// Each entry of [extra] goes into [map] after the typed keys, so an entry
/// wins over a typed key of the same name. A Map value merges into the Map
/// of the key when [map] has one, else it replaces the value with a new
/// copy. A List or another value replaces the value by reference. Each Map
/// of the result is a new `<String, Object?>` Map: Chart.js writes into the
/// option Maps, and a `const` Map of the app would throw. The keys of a Map
/// of [extra] are Strings, as the keys of a JS object.
Map<String, Object?> mergeExtra(
  Map<String, Object?> map,
  Map<String, Object?>? extra,
) {
  if (extra != null) _merge(map, extra);
  return map;
}

/// Merges [source] into [target], a Map that the lowering made.
void _merge(Map<String, Object?> target, Map<Object?, Object?> source) {
  for (final MapEntry(:key, :value) in source.entries) {
    final name = key! as String;
    if (value is Map<Object?, Object?>) {
      final current = target[name];
      if (current is Map<String, Object?>) {
        _merge(current, value);
      } else {
        target[name] = _copy(value);
      }
    } else {
      target[name] = value;
    }
  }
}

/// A new `<String, Object?>` copy of [map], with a new copy of each Map
/// value and the other values by reference.
Map<String, Object?> _copy(Map<Object?, Object?> map) => <String, Object?>{
  for (final MapEntry(:key, :value) in map.entries)
    key! as String: value is Map<Object?, Object?> ? _copy(value) : value,
};
