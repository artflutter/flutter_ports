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

import 'package:flutter/foundation.dart' show Key, ValueChanged;
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
import 'package:flutter_chartjs_port/src/typed/config.dart'
    show ChartConfig, ChartKind, optionFieldsEqual, pluginsEqual;
import 'package:flutter_chartjs_port/src/typed/datasets.dart'
    show Dataset, lowerDataset;
import 'package:flutter_chartjs_port/src/typed/elements.dart'
    show lowerElements;
import 'package:flutter_chartjs_port/src/typed/groups.dart'
    show
        lowerAnimation,
        lowerFiller,
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
/// `{type, data, options, plugins}` (Chart.js ADR 0052, sections 2, 3 and
/// 9).
///
/// The lowering keeps the newest [config]: the trampolines of the
/// callbacks read it at each call. A widget that gets a new config that is
/// `==` to the last one sets [config] and lowers nothing.
///
/// It also keeps the live Maps of the last [lower] or [apply]: the root
/// Map, the `data` and `options` Maps and each dataset Map, with the keys
/// and the values that the lowering wrote into it. [apply] reconciles a new
/// config with these Maps (the keyed reconcile of Chart.js ADR 0052,
/// section 3).
@internal
final class ChartConfigLowering {
  /// The lowering of [config].
  ChartConfigLowering(this.config);

  /// The newest config. The trampolines read its callbacks.
  ChartConfig config;

  /// The config of the live Maps: the config of the last [lower] or
  /// [apply], or Dart `null` before the first.
  ChartConfig? _lowered;

  /// The root Map of the last [lower] or [apply].
  Map<String, Object?> _root = const {};

  /// The live dataset Maps of [_lowered], in dataset order.
  List<_LiveDataset> _datasets = const [];

  /// The root Map of [config]: a new Map at each call, with the keys
  /// `type`, `data` (`labels` by reference and a new `datasets` List),
  /// `options` (a new Map, `ChartConfig.extra` merged last) and `plugins`
  /// by reference.
  ///
  /// The new Maps become the live Maps of the next [apply].
  Map<String, Object?> lower() {
    final config = this.config;
    assert(
      _duplicateKey(config.datasets) == null,
      _duplicateKeyMessage(config.datasets),
    );
    _lowered = config;
    final datasets = _datasets = [
      for (final dataset in config.datasets)
        _LiveDataset.lower(dataset, config.type),
    ];
    return _root = <String, Object?>{
      'type': config.type.name,
      'data': _data(config, datasets),
      'options': _options(),
      'plugins': ?config.plugins,
    };
  }

  /// The root Map of [next] over the live Maps of the last [lower] or
  /// [apply] (Chart.js ADR 0052, sections 3 and 9). [next] becomes
  /// [config]. Before the first [lower], it is [lower].
  ///
  /// The root Map is new. Its values follow these rules:
  /// 1. `type`: the last value when the type is `==`, else the new name.
  /// 2. The datasets: each dataset of [next] takes a live Map by the match
  ///    rule. A dataset with a `key` takes the Map of the last dataset with
  ///    an `==` key and the same class. A dataset without a key takes the
  ///    Map at its index when the last dataset there has no key and the
  ///    same class (the rule of `Widget.canUpdate`). Each Map serves at most
  ///    one dataset. Else the dataset gets a new Map, and the chart a new
  ///    meta (`core.controller.js:829-853`).
  /// 3. A matched Map of an `==` dataset, in a chart of the same type, stays
  ///    as it is. Else the patch removes each key that the last lowering
  ///    wrote and the new one does not write, and writes each key whose new
  ///    value is not `==` to the value of the last lowering. The keys that
  ///    the lowering did not write stay: the keys of the plugins (the colors
  ///    of `plugin.colors.ts:35-52`, the `data` accessor of the decimation
  ///    plugin) and the edits of the app.
  /// 4. `data`: the last Map when the dataset Maps are the last Maps in the
  ///    same order and `labels` is the same List, else a new Map with
  ///    `labels` by reference and a new `datasets` List.
  /// 5. `options`: the last Map when the type and the option fields are
  ///    `==` (an imperative `chart.options` edit then stays), else a new
  ///    Map. A new type gives a new Map: `initOptions` merges the scale
  ///    defaults of the type into the live `options.scales`
  ///    (`core.config.js:115-120`), so the last Map would keep the axes of
  ///    the last type.
  /// 6. `plugins`: the last List when the plugins are `==`, else the new
  ///    List by reference.
  Map<String, Object?> apply(ChartConfig next) {
    config = next;
    final last = _lowered;
    if (last == null) return lower();
    if (next == last) {
      _lowered = next;
      return _root;
    }
    assert(
      _duplicateKey(next.datasets) == null,
      _duplicateKeyMessage(next.datasets),
    );
    _lowered = next;
    final sameType = next.type == last.type;
    final oldDatasets = _datasets;
    final datasets = _datasets = _reconcile(next, sameType: sameType);
    final old = _root;
    var sameMaps =
        identical(next.labels, last.labels) &&
        datasets.length == oldDatasets.length;
    for (var i = 0; sameMaps && i < datasets.length; i++) {
      sameMaps = identical(datasets[i].map, oldDatasets[i].map);
    }
    return _root = <String, Object?>{
      'type': sameType ? old['type'] : next.type.name,
      'data': sameMaps ? old['data'] : _data(next, datasets),
      'options': sameType && optionFieldsEqual(next, last)
          ? old['options']
          : _options(),
      'plugins': ?(pluginsEqual(next, last) ? old['plugins'] : next.plugins),
    };
  }

  /// The live datasets of [next] by the match rule of [apply].
  List<_LiveDataset> _reconcile(ChartConfig next, {required bool sameType}) {
    final old = _datasets;
    final used = List<bool>.filled(old.length, false);
    // The index of the first live dataset of each key.
    final keyed = <Key, int>{};
    for (final (j, live) in old.indexed) {
      if (live.dataset.key case final key?) keyed.putIfAbsent(key, () => j);
    }
    final datasets = <_LiveDataset>[];
    for (final (i, dataset) in next.datasets.indexed) {
      final key = dataset.key;
      final j = key == null
          ? (i < old.length && old[i].dataset.key == null ? i : null)
          : keyed[key];
      if (j == null ||
          used[j] ||
          old[j].dataset.runtimeType != dataset.runtimeType) {
        datasets.add(_LiveDataset.lower(dataset, next.type));
      } else {
        used[j] = true;
        datasets.add(old[j].patch(dataset, next.type, sameType: sameType));
      }
    }
    return datasets;
  }

  /// The `data` Map of [config]: `labels` by reference and a new `datasets`
  /// List of the live dataset Maps.
  static Map<String, Object?> _data(
    ChartConfig config,
    List<_LiveDataset> datasets,
  ) => <String, Object?>{
    'labels': ?config.labels,
    'datasets': <Object?>[for (final dataset in datasets) dataset.map],
  };

  /// The `options` Map of [config]: a new Map, `ChartConfig.extra` merged
  /// last.
  Map<String, Object?> _options() {
    final config = this.config;
    final plugins = <String, Object?>{
      if (config.legend case final legend?) 'legend': lowerLegend(legend, this),
      if (config.title case final title?) 'title': lowerTitle(title),
      if (config.subtitle case final subtitle?)
        'subtitle': lowerTitle(subtitle),
      if (config.tooltip case final tooltip?)
        'tooltip': lowerTooltip(tooltip, this),
      if (config.filler case final filler?) 'filler': lowerFiller(filler),
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
      if (config.elements case final elements?)
        'elements': lowerElements(elements),
      if (config.onClick != null)
        'onClick': eventTrampoline(() => this.config.onClick),
      if (config.onHover != null)
        'onHover': eventTrampoline(() => this.config.onHover),
    };
    return mergeExtra(options, config.extra);
  }
}

/// The first dataset key of [datasets] that two datasets have, or Dart
/// `null` when the keys are unique, as the keys of the children of a
/// widget.
Key? _duplicateKey(List<Dataset> datasets) {
  final keys = <Key>{};
  for (final dataset in datasets) {
    final key = dataset.key;
    if (key != null && !keys.add(key)) return key;
  }
  return null;
}

/// The message of the debug assert of a key of [datasets] that two datasets
/// have.
String _duplicateKeyMessage(List<Dataset> datasets) =>
    'Two datasets of the ChartConfig have the key '
    '${_duplicateKey(datasets)}. A key is the identity of a dataset from one '
    'config to the next: give each dataset its own key.';

/// One live dataset Map of a [ChartConfigLowering]: the typed dataset, the
/// Map of the chart and the entries that the lowering wrote into it.
final class _LiveDataset {
  _LiveDataset(this.dataset, this.map, this.lowered);

  /// The live dataset of a new Map: the lowering of [dataset] in a chart of
  /// the type [type].
  factory _LiveDataset.lower(Dataset dataset, ChartKind type) {
    final map = lowerDataset(dataset, type);
    return _LiveDataset(dataset, map, Map<String, Object?>.of(map));
  }

  /// The typed dataset of [map].
  final Dataset dataset;

  /// The dataset Map of the chart.
  final Map<String, Object?> map;

  /// The keys and the values that the lowering wrote into [map].
  final Map<String, Object?> lowered;

  /// This Map with the values of [next] in a chart of the type [type]
  /// (rule 3 of [ChartConfigLowering.apply]).
  _LiveDataset patch(Dataset next, ChartKind type, {required bool sameType}) {
    final map = this.map;
    if (sameType && next == dataset) return _LiveDataset(next, map, lowered);
    final written = lowerDataset(next, type);
    final last = lowered;
    for (final key in last.keys) {
      if (!written.containsKey(key)) map.remove(key);
    }
    for (final MapEntry(:key, :value) in written.entries) {
      if (!last.containsKey(key) || last[key] != value) map[key] = value;
    }
    return _LiveDataset(next, map, written);
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
/// of [extra] are Strings, as the keys of a JS object: in debug mode, a key
/// of a nested Map that is not a `String` fails an assert that names the
/// key.
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
    final name = _key(key);
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
    _key(key): value is Map<Object?, Object?> ? _copy(value) : value,
};

/// [key], a key of a Map of `extra`, as a `String`.
String _key(Object? key) {
  assert(
    key is String,
    'The key $key of an extra Map is a ${key.runtimeType}, not a String. '
    'Chart.js options are objects with String keys: write the key as '
    "'$key'.",
  );
  return key! as String;
}
