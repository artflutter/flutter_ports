// Original code, not ported from Chart.js: the lowering of the typed config.

/// The lowering of the typed config (Chart.js ADR 0052, section 2):
/// [ChartConfigLowering], the root scope of a config, the conversions of
/// the typed values to their option values, the merge of the `extra` Maps
/// and the trampolines of the callbacks.
///
/// The typed config lowers to the typed option scopes of Chart.js ADR 0054
/// (§7): the scope classes of `lib/src/options/scopes.g.dart`, with one
/// cell for each key by the shape of the key ([put]). The resolver reads
/// them with typed reads, and the typed API makes no Map of options. Each
/// class of the typed config lowers to a new scope of its kind in its
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
///    `fontScopeOf` of `css.dart` (a `FontSpecScope`), a `Duration` through
///    [millisecondsOf] and an `EdgeInsets` through [paddingScope] (a
///    `PaddingScope`). A name type lowers to its name or its `optionValue`,
///    `IndexAxis` to its `name`. An object option value of a name type (the
///    `{value}` of `ChartFill.value`) becomes a typed scope of the kind of
///    its key ([put]).
/// 4. A plain value never lowers to a closure. Only a function parameter
///    does: [colorScript] for the scriptable colors, a `JsFunction` for the
///    tick format, and a trampoline for each event and text callback.
/// 5. A trampoline reads the callback of the newest config of its
///    [ChartConfigLowering] at each call ([eventTrampoline],
///    [legendTrampoline], [tooltipItemsTrampoline], [tooltipItemTrampoline]
///    and [animationTrampoline]). Thus a new closure in a config that is
///    `==` to the last one needs no new lowering.
/// 6. `extra` merges last ([mergeExtra]): each entry becomes a cell of the
///    shape of its key, and an object a typed scope of the kind of its key.
///
/// Internal: no public library exports it.
library;

import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show Key, ValueChanged;
import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_chartjs_port/src/core/core.controller.dart' show Chart;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart' show undefined;
import 'package:flutter_chartjs_port/src/options/option_scope.dart'
    show OptScope, OptionKey, OptionScope, ScopeKind;
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show
        ChartConfigurationScope,
        ChartDataScope,
        ChartOptionsScope,
        LayoutOptionsScope,
        PaddingScope,
        PluginOptionsByTypeScope,
        ScaleOptionsByIdScope,
        ScaleOptionsScope;
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

/// The lowering of a typed config to the root scope of a Chart.js config
/// `{type, data, options, plugins}` (Chart.js ADR 0052, sections 2, 3 and
/// 9; Chart.js ADR 0054 §7).
///
/// The lowering keeps the newest [config]: the trampolines of the
/// callbacks read it at each call. A widget that gets a new config that is
/// `==` to the last one sets [config] and lowers nothing.
///
/// It also keeps the live scopes of the last [lower] or [apply]: the root
/// scope, the `data` and `options` scopes and each dataset scope, with the
/// keys and the cells that the lowering wrote into it. [apply] reconciles a
/// new config with these scopes (the keyed reconcile of Chart.js ADR 0052,
/// section 3).
@internal
final class ChartConfigLowering {
  /// The lowering of [config].
  ChartConfigLowering(this.config);

  /// The newest config. The trampolines read its callbacks.
  ChartConfig config;

  /// The config of the live scopes: the config of the last [lower] or
  /// [apply], or Dart `null` before the first.
  ChartConfig? _lowered;

  /// The root scope of the last [lower] or [apply].
  ChartConfigurationScope _root = ChartConfigurationScope();

  /// The live dataset scopes of [_lowered], in dataset order.
  List<_LiveDataset> _datasets = const [];

  /// The root scope of [config]: a new scope at each call, with the keys
  /// `type`, `data` (`labels` by reference and a new `datasets` List),
  /// `options` (a new scope, `ChartConfig.extra` merged last) and `plugins`
  /// by reference.
  ///
  /// The new scopes become the live scopes of the next [apply].
  ChartConfigurationScope lower() {
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
    final root = ChartConfigurationScope()
      ..type = config.type.name
      ..data = _data(config, datasets)
      ..options = _options();
    put(root, OptionKey.plugins, config.plugins);
    return _root = root;
  }

  /// The root scope of [next] over the live scopes of the last [lower] or
  /// [apply] (Chart.js ADR 0052, sections 3 and 9). [next] becomes
  /// [config]. Before the first [lower], it is [lower].
  ///
  /// The root scope is new. Its cells follow these rules:
  /// 1. `type`: the last cell when the type is `==`, else the new name.
  /// 2. The datasets: each dataset of [next] takes a live scope by the match
  ///    rule. A dataset with a `key` takes the scope of the last dataset with
  ///    an `==` key and the same class. A dataset without a key takes the
  ///    scope at its index when the last dataset there has no key and the
  ///    same class (the rule of `Widget.canUpdate`). Each scope serves at
  ///    most one dataset. Else the dataset gets a new scope, and the chart a
  ///    new meta (`core.controller.js:829-853`).
  /// 3. A matched scope of an `==` dataset, in a chart of the same type,
  ///    stays as it is. Else the patch removes each key that the last
  ///    lowering wrote and the new one does not write, and writes each key
  ///    whose new value is not `==` to the value of the last lowering. The
  ///    keys that the lowering did not write stay: the keys of the plugins
  ///    (the colors of `plugin.colors.ts:35-52`, the `data` accessor of the
  ///    decimation plugin) and the edits of the app.
  /// 4. `data`: the last scope when the dataset scopes are the last scopes
  ///    in the same order and `labels` is the same List, else a new scope
  ///    with `labels` by reference and a new `datasets` List.
  /// 5. `options`: the last scope when the type and the option fields are
  ///    `==` (an imperative `chart.options` edit then stays), else a new
  ///    scope. A new type gives a new scope: `initOptions` merges the scale
  ///    defaults of the type into the live `options.scales`
  ///    (`core.config.js:115-120`), so the last scope would keep the axes of
  ///    the last type.
  /// 6. `plugins`: the last List when the plugins are `==`, else the new
  ///    List by reference.
  ChartConfigurationScope apply(ChartConfig next) {
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
      sameMaps = identical(datasets[i].scope, oldDatasets[i].scope);
    }
    final root = ChartConfigurationScope();
    if (sameType) {
      root.typeCell = old.typeCell;
    } else {
      root.type = next.type.name;
    }
    if (sameMaps) {
      root.dataCell = old.dataCell;
    } else {
      root.data = _data(next, datasets);
    }
    if (sameType && optionFieldsEqual(next, last)) {
      root.optionsCell = old.optionsCell;
    } else {
      root.options = _options();
    }
    if (pluginsEqual(next, last)) {
      root.pluginsCell = old.pluginsCell;
    } else {
      put(root, OptionKey.plugins, next.plugins);
    }
    return _root = root;
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

  /// The `data` scope of [config]: `labels` by reference and a new
  /// `datasets` List of the live dataset scopes.
  static ChartDataScope _data(
    ChartConfig config,
    List<_LiveDataset> datasets,
  ) {
    final data = ChartDataScope();
    put(data, OptionKey.labels, config.labels);
    data.datasets = <Object?>[for (final dataset in datasets) dataset.scope];
    return data;
  }

  /// The `options` scope of [config]: a new scope, `ChartConfig.extra`
  /// merged last.
  ChartOptionsScope _options() {
    final config = this.config;
    final plugins = PluginOptionsByTypeScope();
    if (config.legend case final legend?) {
      plugins.legend = lowerLegend(legend, this);
    }
    if (config.title case final title?) plugins.title = lowerTitle(title);
    if (config.subtitle case final subtitle?) {
      plugins.subtitle = lowerTitle(subtitle);
    }
    if (config.tooltip case final tooltip?) {
      plugins.tooltip = lowerTooltip(tooltip, this);
    }
    if (config.filler case final filler?) plugins.filler = lowerFiller(filler);
    final options = ChartOptionsScope();
    if (config.scales case final scales?) {
      final byId = ScaleOptionsByIdScope();
      for (final MapEntry(key: id, value: axis) in scales.entries) {
        byId.store(id, OptScope<ScaleOptionsScope>(lowerAxis(axis)));
      }
      options.scales = byId;
    }
    put(options, OptionKey.indexAxis, config.indexAxis?.name);
    put(options, OptionKey.responsive, config.responsive);
    put(options, OptionKey.maintainAspectRatio, config.maintainAspectRatio);
    put(options, OptionKey.aspectRatio, config.aspectRatio);
    if (paddingScope(config.padding) case final padding?) {
      options.layout = LayoutOptionsScope()..padding = padding;
    }
    if (plugins.ownKeyCount != 0) options.plugins = plugins;
    if (config.interaction case final interaction?) {
      options.interaction = lowerInteraction(interaction);
    }
    if (config.animation case final animation?) {
      options.animation = lowerAnimation(animation, this);
    }
    if (config.elements case final elements?) {
      options.elements = lowerElements(elements);
    }
    if (config.onClick != null) {
      options.onClick = eventTrampoline(() => this.config.onClick);
    }
    if (config.onHover != null) {
      options.onHover = eventTrampoline(() => this.config.onHover);
    }
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

/// One live dataset scope of a [ChartConfigLowering]: the typed dataset,
/// the scope of the chart and the cells that the lowering wrote into it.
final class _LiveDataset {
  _LiveDataset(this.dataset, this.scope, this.lowered);

  /// The live dataset of a new scope: the lowering of [dataset] in a chart
  /// of the type [type].
  factory _LiveDataset.lower(Dataset dataset, ChartKind type) {
    final scope = lowerDataset(dataset, type);
    return _LiveDataset(dataset, scope, _shallowCopy(scope));
  }

  /// The typed dataset of [scope].
  final Dataset dataset;

  /// The dataset scope of the chart.
  final OptionScope scope;

  /// A scope of the kind of [scope] with the keys and the cells that the
  /// lowering wrote into [scope].
  final OptionScope lowered;

  /// This scope with the values of [next] in a chart of the type [type]
  /// (rule 3 of [ChartConfigLowering.apply]). Two cells are equal when
  /// their JS values are `==`, as the values of the Maps of Chart.js ADR
  /// 0052: an object, a List and a function by identity.
  _LiveDataset patch(Dataset next, ChartKind type, {required bool sameType}) {
    final scope = this.scope;
    if (sameType && next == dataset) return _LiveDataset(next, scope, lowered);
    final written = lowerDataset(next, type);
    final last = lowered;
    for (final key in last.ownKeys) {
      if (written.ownCell(key) == null) scope.delete(key);
    }
    for (final key in written.ownKeys) {
      final cell = written.ownCell(key)!;
      final old = last.ownCell(key);
      if (old == null || old.raw != cell.raw) scope.store(key, cell);
    }
    return _LiveDataset(next, scope, written);
  }
}

/// A new scope of the kind of [scope] with each own key of [scope] in its
/// order and the same cell: the record of the cells that a lowering wrote.
OptionScope _shallowCopy(OptionScope scope) {
  final copy = scope.kind.create();
  for (final key in scope.ownKeys) {
    copy.store(key, scope.ownCell(key)!);
  }
  return copy;
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

/// The option value of [padding]: a new `PaddingScope` with the keys
/// `top`, `right`, `bottom` and `left` (`index.d.ts`, `Padding`). Dart
/// `null` for `null`.
PaddingScope? paddingScope(EdgeInsets? padding) => padding == null
    ? null
    : (PaddingScope()
        ..top = padding.top
        ..right = padding.right
        ..bottom = padding.bottom
        ..left = padding.left);

/// The option value of [duration]: the milliseconds, with the fraction of
/// the microseconds. Dart `null` for `null`.
double? millisecondsOf(Duration? duration) =>
    duration == null ? null : duration.inMicroseconds / 1000;

/// A new List of the numbers of [list], or Dart `null` for `null`.
List<Object?>? numberList(List<double>? list) =>
    list == null ? null : <Object?>[...list];

/// Writes the option value [value] under [key] of [scope] when it is not
/// Dart `null` (Chart.js ADR 0054 §7): the cell of the shape of the key in
/// the kind of [scope]. A key that the kind does not declare is an extra.
///
/// An object value of the conversions (a Map, for example the `{value}` of
/// `ChartFill.value`) becomes a typed scope of the kind of the key when the
/// key has one, else a new `<String, Object?>` Map. A typed scope, a List and
/// a function go by reference.
void put(OptionScope scope, OptionKey key, Object? value) {
  if (value == null) return;
  _store(scope, key.jsName, value);
}

/// Stores the cell of [value] under the name [name] of [scope]: an object
/// as [put] gives it, any other value by reference. A value outside the
/// shape of the key is foreign, and the audit of the oracle O2 sees it
/// (`OptionScope.classifyName`).
void _store(OptionScope scope, String name, Object? value) {
  // A typed scope is not a Map (Chart.js ADR 0054 §5): it goes by
  // reference.
  final cell = value is Map<Object?, Object?>
      ? scope.classifyName(name, _objectFor(scope, name, value))
      : scope.classifyName(name, value);
  scope.store(name, cell);
}

/// The object of the Map [map] under the name [name] of [scope]: a typed
/// scope of the kind of the key when the key has one, else a new
/// `<String, Object?>` copy (a key of an object that no kind declares).
Object _objectFor(OptionScope scope, String name, Map<Object?, Object?> map) {
  final kind = scope.childKindFor(name);
  return kind == null ? _copy(map) : _scopeOf(kind, map);
}

/// A new typed scope of [kind] with the entries of [map] in their order:
/// each entry as [_store] stores it.
OptionScope _scopeOf(ScopeKind kind, Map<Object?, Object?> map) {
  final scope = kind.create();
  for (final MapEntry(:key, :value) in map.entries) {
    _store(scope, _key(key), value);
  }
  return scope;
}

/// Merges [extra] into [scope] and gives [scope] (Chart.js ADR 0052, section
/// 2 rule 9; Chart.js ADR 0054 §7).
///
/// Each entry of [extra] goes into [scope] after the typed keys, so an entry
/// wins over a typed key of the same name. A Map value merges into the
/// object of the key when [scope] has one (a typed scope or a Map), else it
/// replaces the value with a new typed scope of the kind of the key, or a
/// new `<String, Object?>` Map for a key with no kind. A List or another
/// value replaces the value by reference. Each object of the result is new:
/// Chart.js writes into the option objects, and a `const` Map of the app
/// would throw. The keys of a Map of [extra] are Strings, as the keys of a
/// JS object: in debug mode, a key of a nested Map that is not a `String`
/// fails an assert that names the key.
T mergeExtra<T extends OptionScope>(T scope, Map<String, Object?>? extra) {
  if (extra != null) _mergeInto(scope, extra);
  return scope;
}

/// Merges [source] into [target], a scope that the lowering made.
void _mergeInto(OptionScope target, Map<Object?, Object?> source) {
  for (final MapEntry(:key, :value) in source.entries) {
    final name = _key(key);
    if (value is Map<Object?, Object?>) {
      final current = target.ownCell(name)?.raw;
      if (current is OptionScope) {
        _mergeInto(current, value);
        continue;
      }
      if (current is Map<String, Object?>) {
        _merge(current, value);
        continue;
      }
    }
    _store(target, name, value);
  }
}

/// Merges [source] into [target], a Map of the lowering under a key that no
/// kind declares.
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
