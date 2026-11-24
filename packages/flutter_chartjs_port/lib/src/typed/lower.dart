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
/// `lowerInteraction` and the other functions of `groups.dart`), with these
/// rules:
/// 1. The keys come in the order of the constructor parameters. A
///    parameter that is `null` writes no key.
/// 2. A List of the app goes by reference: `data`, `points`, `labels`,
///    `CategoryAxis.labels` and `plugins`. A small style List
///    (`ChartValue.indexed` or `borderDash`) and `ChartConfig.events` lower
///    to a new List.
/// 3. A `ChartPaint` passes unchanged. A `Duration` lowers through
///    [millisecondsOf], and an `EdgeInsets` stays a native value.
///    A name type lowers to its name or its `optionValue`.
///    An axis class (`XAxis`, `YAxis`) and a font (`TextStyle`, Chart.js ADR
///    0116) stay themselves, and so does a `FillTarget` (Chart.js ADR
///    0140). An object option value becomes a typed scope of the kind of its
///    key ([put]).
/// 4. A plain value never lowers to a closure. Only a function parameter
///    does: a ChartValue bridge for dataset colors, a function for the tick
///    format, and a trampoline for each event and text callback.
/// 5. A trampoline reads the callback of the newest config of its
///    [ChartConfigLowering] at each call ([eventTrampoline],
///    [tooltipCallbacksTrampoline]
///    and [animationTrampoline]). Thus a new closure in a config that is
///    `==` to the last one needs no new lowering.
/// 6. `extra` merges last ([mergeExtra]): each entry becomes a cell of the
///    shape of its key, and an object a typed scope of the kind of its key.
///
/// Internal: no public library exports it.
library;

import 'package:flutter/foundation.dart' show Key, listEquals;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

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
final class ChartConfigLowering(
  /// The newest config. The trampolines read its callbacks.
  var ChartConfig config,
) {
  /// The lowering of [config].
  this;

  /// The config of the live scopes: the config of the last [lower] or
  /// [apply], or Dart `null` before the first.
  ChartConfig? _lowered;

  /// The root scope of the last [lower] or [apply].
  ChartConfigurationScope _root = ChartConfigurationScope();

  /// The live dataset scopes of [_lowered], in dataset order.
  List<_LiveDataset> _datasets = const [];

  /// The scale id of each axis of the config of the last [lower] or [apply]
  /// (Chart.js ADR 0191, item 3), by `==`.
  Map<ChartAxis, String> get scaleIds => _scaleIds;
  Map<ChartAxis, String> _scaleIds = const {};

  /// Whether the last [apply] changed only dataset data Lists (Chart.js ADR
  /// 0098): the type, the labels, the option fields and the plugins are `==`,
  /// each dataset kept its scope at its index, and each patch changed only
  /// `data` or stored a style List with equal items. A [lower] gives `false`.
  ///
  /// It proves the part of the contract of `Chart.updateData` that a config
  /// shows. An imperative edit of a live scope, a write into
  /// `Chart.defaults` and a change in place of the labels are not in a config.
  bool get lastApplyDataOnly => _lastApplyDataOnly;
  bool _lastApplyDataOnly = false;

  /// Whether the `options` scope of the last [lower] or [apply] holds
  /// `animation: false`: from `ChartAnimation.none`, from `extra`, or from an
  /// imperative write into the live scope.
  bool get animationOff {
    final options = _root.optionsCell?.raw;
    return options is ChartOptionsScope &&
        identical(options.animationCell?.raw, false);
  }

  /// The root scope of [config]: a new scope at each call, with the keys
  /// `type`, `data` (`labels` by reference and a new `datasets` List),
  /// `options` (a new scope, `ChartConfig.extra` merged last) and `plugins`
  /// by reference.
  ///
  /// The new scopes become the live scopes of the next [apply].
  ChartConfigurationScope lower() {
    final config = this.config;
    assert(config.datasets.isNotEmpty, _noDatasetMessage);
    assert(
      _duplicateKey(config.datasets) == null,
      _duplicateKeyMessage(config.datasets),
    );
    _lowered = config;
    _lastApplyDataOnly = false;
    _scaleIds = scaleIdsOf(config.scales);
    final datasets = _datasets = _withScaleIds(
      () => [
        for (final dataset in config.datasets)
          _LiveDataset.lower(dataset, config.type),
      ],
    );
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
  ///
  /// [lastApplyDataOnly] reports whether these rules kept all but the data.
  ChartConfigurationScope apply(ChartConfig next) {
    config = next;
    final last = _lowered;
    if (last == null) return lower();
    if (next == last) {
      _lowered = next;
      _lastApplyDataOnly = false;
      return _root;
    }
    assert(next.datasets.isNotEmpty, _noDatasetMessage);
    assert(
      _duplicateKey(next.datasets) == null,
      _duplicateKeyMessage(next.datasets),
    );
    _lowered = next;
    final sameType = next.type == last.type;
    // The ids of the axes depend on the List of axes: an `==` dataset keeps
    // its scope only under the same axes (Chart.js ADR 0191, item 5).
    final sameScales = byItems(next.scales) == byItems(last.scales);
    _scaleIds = scaleIdsOf(next.scales);
    final oldDatasets = _datasets;
    final datasets = _datasets = _withScaleIds(
      () => _reconcile(next, sameType: sameType, sameScales: sameScales),
    );
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
    final sameOptions = sameType && optionFieldsEqual(next, last);
    if (sameOptions) {
      root.optionsCell = old.optionsCell;
    } else {
      root.options = _options();
    }
    final samePlugins = pluginsEqual(next, last);
    if (samePlugins) {
      root.pluginsCell = old.pluginsCell;
    } else {
      put(root, OptionKey.plugins, next.plugins);
    }
    _lastApplyDataOnly =
        sameMaps &&
        sameOptions &&
        samePlugins &&
        datasets.every((dataset) => dataset.dataOnly);
    return _root = root;
  }

  /// The live datasets of [next] by the match rule of [apply].
  List<_LiveDataset> _reconcile(
    ChartConfig next, {
    required bool sameType,
    required bool sameScales,
  }) {
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
        datasets.add(
          old[j].patch(
            dataset,
            next.type,
            sameType: sameType,
            sameScales: sameScales,
          ),
        );
      }
    }
    return datasets;
  }

  /// The result of [lowerDatasets] while [currentScaleIds] holds the ids of
  /// the axes of the config, for the axis fields of the datasets.
  T _withScaleIds<T>(T Function() lowerDatasets) {
    final outer = currentScaleIds;
    currentScaleIds = _scaleIds;
    try {
      return lowerDatasets();
    } finally {
      currentScaleIds = outer;
    }
  }

  /// The `data` scope of [config]: `labels` by reference and a new
  /// `datasets` List of the live dataset scopes.
  static ChartDataScope _data(ChartConfig config, List<_LiveDataset> datasets) {
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
    // The options objects of add-on plugins, each under its plugin id
    // (Chart.js ADR 0148).
    for (final options
        in config.pluginOptions ?? const <PluginOptions<Object?>>[]) {
      plugins.jsWrite(options.pluginId, options);
    }
    // `options.plugins.<id>: false` for each plugin that an item of
    // `disabledPlugins` matches, as an `extra` entry
    // `{'plugins': {<id>: false}}` stores it (`core.plugins.js:146-172`).
    if (config.disabledPlugins case final offs?) {
      for (final plugin in [
        ...registry.plugins.items.values.whereType<Plugin<Object?>>(),
        ...?config.plugins,
      ]) {
        if (offs.any((off) => off.matches(plugin))) {
          _store(plugins, plugin.id, false);
        }
      }
    }
    final options = ChartOptionsScope();
    if (config.scales case final scales?) {
      final byId = ScaleOptionsByIdScope();
      for (final axis in scales) {
        final id = _scaleIds[axis]!;
        byId.store(
          id,
          OptScope<ScaleOptionsScope>(
            lowerAxis(axis, writeAxis: id.length > 1),
          ),
        );
      }
      options.scales = byId;
    }
    put(options, OptionKey.indexAxis, config.indexAxis);
    put(options, OptionKey.parsing, config.parsing);
    put(options, OptionKey.responsive, config.responsive);
    put(options, OptionKey.maintainAspectRatio, config.maintainAspectRatio);
    put(options, OptionKey.aspectRatio, config.aspectRatio);
    put(options, OptionKey.devicePixelRatio, config.devicePixelRatio);
    put(options, OptionKey.locale, config.locale);
    put(options, OptionKey.normalized, config.normalized);
    put(options, OptionKey.color, config.color);
    if (config.datasetDefaults case final defaults? when defaults.isNotEmpty) {
      final byType = DatasetOptionsByTypeScope();
      for (final dataset in defaults) {
        // The lowering of the typed API reads the kind (Chart.js ADR 0189).
        // ignore: invalid_use_of_protected_member
        final kind = dataset.kind;
        final name = kind.name;
        assert(
          byType.ownCell(name) == null,
          'ChartConfig.datasetDefaults has two items of the type $name.',
        );
        byType.store(
          name,
          byType.classifyName(name, lowerDataset(dataset, kind)),
        );
      }
      options.datasets = byType;
    }
    if (config.padding case final padding?) {
      options.layout = LayoutOptionsScope()..padding = padding;
    }
    if (plugins.ownKeyCount != 0) options.plugins = plugins;
    if (config.interaction case final interaction?) {
      options.interaction = lowerInteraction(interaction);
    }
    if (config.animation case final animation?) {
      options.animation = lowerAnimation(animation, this);
    }
    if (config.transitions case final transitions?) {
      if (lowerTransitions(transitions) case final spec?) {
        options.transitions = spec;
      }
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
    if (config.events case final events?) {
      put(options, OptionKey.events, List<String>.of(events));
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

/// The message of a [ChartConfig] with no dataset (Chart.js ADR 0190).
const String _noDatasetMessage =
    'A ChartConfig needs at least one dataset: the class of the first '
    'dataset gives the chart type. For a chart with no data yet, give a '
    'dataset with no data, for example LineDataset(data: .values([])).';

/// The newest typed dataset of one live dataset scope: the tooltip
/// callback trampolines of its scope read their callbacks from it.
final class _DatasetCallbacks(var Dataset dataset);

/// One live dataset scope of a [ChartConfigLowering]: the typed dataset,
/// the scope of the chart and the cells that the lowering wrote into it.
final class _LiveDataset(
  /// The typed dataset of [scope].
  final Dataset dataset,

  /// The dataset scope of the chart.
  final OptionScope scope,

  /// A scope of the kind of [scope] with the keys and the cells that the
  /// lowering wrote into [scope].
  final OptionScope lowered, {
  required final _DatasetCallbacks callbacks,

  /// Whether this is the result of a [patch] that changed no value but
  /// `data` (Chart.js ADR 0098).
  final bool dataOnly = false,
}) {
  /// The live dataset of a new scope: the lowering of [dataset] in a chart
  /// of the type [type].
  factory lower(Dataset dataset, ChartKind type) {
    final callbacks = _DatasetCallbacks(dataset);
    final scope = lowerDataset(
      dataset,
      type,
      currentTooltipCallbacks: () => callbacks.dataset.tooltipCallbacks,
    );
    return _LiveDataset(
      dataset,
      scope,
      _shallowCopy(scope),
      callbacks: callbacks,
    );
  }

  /// This scope with the values of [next] in a chart of the type [type]
  /// (rule 3 of [ChartConfigLowering.apply]). Two cells are equal when
  /// their JS values are `==`, as the values of the Maps of Chart.js ADR
  /// 0052: an object, a List and a function by identity.
  _LiveDataset patch(
    Dataset next,
    ChartKind type, {
    required bool sameType,
    required bool sameScales,
  }) {
    final scope = this.scope;
    callbacks.dataset = next;
    if (sameType && sameScales && next == dataset) {
      return _LiveDataset(
        next,
        scope,
        lowered,
        callbacks: callbacks,
        dataOnly: true,
      );
    }
    final written = lowerDataset(
      next,
      type,
      currentTooltipCallbacks: () => callbacks.dataset.tooltipCallbacks,
    );
    final last = lowered;
    // An `extra` List goes by reference, so a new one is a new value even
    // with the same items.
    var dataOnly = byEntries(next.extra) == byEntries(dataset.extra);
    for (final key in last.ownKeys) {
      if (written.ownCell(key) == null) {
        scope.delete(key);
        dataOnly = false;
      }
    }
    for (final key in written.ownKeys) {
      final cell = written.ownCell(key)!;
      final old = last.ownCell(key);
      if (old == null || old.raw != cell.raw) {
        scope.store(key, cell);
        dataOnly =
            dataOnly &&
            old != null &&
            (key == OptionKey.data || _sameStyleList(old.raw, cell.raw));
      }
    }
    return _LiveDataset(
      next,
      scope,
      written,
      callbacks: callbacks,
      dataOnly: dataOnly,
    );
  }

  /// Whether [a] and [b] are the Lists of two lowerings of one style List
  /// (`ChartValue.indexed`, `borderDash`): each lowering makes a new List, so
  /// their items compare, as `ChartIndexed ==` does.
  static bool _sameStyleList(Object? a, Object? b) =>
      a is List<Object?> && b is List<Object?> && listEquals(a, b);
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

/// Keeps typed tooltip callbacks connected to the newest config.
/// Internal lowering detail, matching the existing event trampolines.
TooltipCallbacks tooltipCallbacksTrampoline(
  TooltipCallbacks callbacks,
  TooltipCallbacks? Function() newest,
) => TooltipCallbacks(
  beforeTitle: callbacks.beforeTitle == null
      ? null
      : (tooltip, arg) => newest()?.beforeTitle?.call(tooltip, arg),
  title: callbacks.title == null
      ? null
      : (tooltip, arg) => newest()?.title?.call(tooltip, arg),
  afterTitle: callbacks.afterTitle == null
      ? null
      : (tooltip, arg) => newest()?.afterTitle?.call(tooltip, arg),
  beforeBody: callbacks.beforeBody == null
      ? null
      : (tooltip, arg) => newest()?.beforeBody?.call(tooltip, arg),
  afterBody: callbacks.afterBody == null
      ? null
      : (tooltip, arg) => newest()?.afterBody?.call(tooltip, arg),
  beforeLabel: callbacks.beforeLabel == null
      ? null
      : (tooltip, arg) => newest()?.beforeLabel?.call(tooltip, arg),
  label: callbacks.label == null
      ? null
      : (tooltip, arg) => newest()?.label?.call(tooltip, arg),
  afterLabel: callbacks.afterLabel == null
      ? null
      : (tooltip, arg) => newest()?.afterLabel?.call(tooltip, arg),
  beforeFooter: callbacks.beforeFooter == null
      ? null
      : (tooltip, arg) => newest()?.beforeFooter?.call(tooltip, arg),
  footer: callbacks.footer == null
      ? null
      : (tooltip, arg) => newest()?.footer?.call(tooltip, arg),
  afterFooter: callbacks.afterFooter == null
      ? null
      : (tooltip, arg) => newest()?.afterFooter?.call(tooltip, arg),
  labelColor: callbacks.labelColor == null
      ? null
      : (tooltip, arg) => newest()?.labelColor?.call(tooltip, arg),
  labelTextColor: callbacks.labelTextColor == null
      ? null
      : (tooltip, arg) => newest()?.labelTextColor?.call(tooltip, arg),
  labelPointStyle: callbacks.labelPointStyle == null
      ? null
      : (tooltip, arg) => newest()?.labelPointStyle?.call(tooltip, arg),
);

/// The trampoline of the chart callback that [newest] reads:
/// `options.onClick` or `options.onHover`.
///
/// Chart.js calls it with the event, the active elements and the chart
/// (`core.controller.js:1222-1226`). It calls the callback of the newest
/// config with the same arguments.
ChartEventHandler eventTrampoline(ChartEventHandler? Function() newest) =>
    (event, elements, chart) => newest()?.call(event, elements, chart);

/// The trampoline of the animation callback that [newest] reads:
/// `onProgress` or `onComplete` of `options.animation`.
///
/// The chart calls it with the `AnimationEvent` of the animator
/// (`core.controller.js:33-46`).
AnimationEventHandler animationTrampoline(
  AnimationEventHandler? Function() newest,
) =>
    (event) => newest()?.call(event);

/// The option value of [duration]: the milliseconds, with the fraction of
/// the microseconds. Dart `null` for `null`.
double? millisecondsOf(Duration? duration) =>
    duration == null ? null : duration.inMicroseconds / 1000;

/// The option value of [skip], the value of `borderSkipped` (row
/// `adapt-border-skipped-enum`): `false` for [BorderSkip.none], `true` for
/// [BorderSkip.all] and the [BorderSkippedEdge] of the same name for an
/// edge. Dart `null` for `null`.
Object? borderSkippedOf(BorderSkip? skip) => switch (skip) {
  null => null,
  BorderSkip.none => false,
  BorderSkip.all => true,
  BorderSkip.start => BorderSkippedEdge.start,
  BorderSkip.end => BorderSkippedEdge.end,
  BorderSkip.middle => BorderSkippedEdge.middle,
  BorderSkip.bottom => BorderSkippedEdge.bottom,
  BorderSkip.left => BorderSkippedEdge.left,
  BorderSkip.top => BorderSkippedEdge.top,
  BorderSkip.right => BorderSkippedEdge.right,
};

/// A new List of the numbers of [list], or Dart `null` for `null`.
List<double>? numberList(List<double>? list) =>
    list == null ? null : List<double>.of(list);

/// The scale ids of the typed config of each canvas of a `ChartView`
/// (Chart.js ADR 0191, item 6).
final Expando<Map<ChartAxis, String>> _canvasScaleIds = Expando(
  'ChartAxis scale ids',
);

/// Records [ids], the scale ids of the typed config of the chart on
/// [canvas]. `ChartView` calls it at each lowering.
void recordScaleIds(Object canvas, Map<ChartAxis, String> ids) {
  _canvasScaleIds[canvas] = ids;
}

/// The scales of the axes of a typed config (Chart.js ADR 0191, item 6).
///
/// ```dart
/// const right = LinearAxis(.y, position: .right);
/// final scale = chart.scaleOf(right); // chart.scales['y1']
/// ```
extension TypedChartAxes on Chart {
  /// The scale of [axis]: `scales[scaleIdOf(axis)]`.
  Scale? scaleOf(ChartAxis axis) => switch (scaleIdOf(axis)) {
    final id? => this.scales[id],
    null => null,
  };
}

/// The scale ids of the axes of a typed config (Chart.js ADR 0191, item 6).
/// An add-on reads them through the chart interface, as the zoom limits do.
extension TypedChartAxisIds on IChart {
  /// The scale id of [axis], an axis of the current typed config of the
  /// `ChartView` of this chart, by `==`. Dart `null` for another axis, a
  /// raw config and a chart with no `ChartView`.
  String? scaleIdOf(ChartAxis axis) => switch (canvas) {
    final canvas? => _canvasScaleIds[canvas]?[axis],
    null => null,
  };
}

/// The scale ids of the axes of the config that the lowering lowers now,
/// for [scaleIdOfAxis]: set only while the datasets lower (Chart.js ADR
/// 0191).
Map<ChartAxis, String>? currentScaleIds;

/// The scale id of each axis of [scales] by `==` (Chart.js ADR 0191, item
/// 3): the first axis of a direction has the id `x`, `y` or `r`, the next
/// ones `x1`, `x2`, `y1` and so on. The axes are distinct by `==`.
Map<ChartAxis, String> scaleIdsOf(List<ChartAxis>? scales) {
  final ids = <ChartAxis, String>{};
  if (scales == null) return ids;
  final counts = <String, int>{};
  for (final axis in scales) {
    final letter = switch (axis.axis) {
      XAxis() => 'x',
      YAxis() => 'y',
      _ => 'r',
    };
    final n = counts[letter] ?? 0;
    counts[letter] = n + 1;
    assert(
      !ids.containsKey(axis),
      'The axes of ChartConfig.scales are distinct by ==, but $axis is there '
      'twice (Chart.js ADR 0191). Give the second one a field that differs, '
      'for example position.',
    );
    ids[axis] = n == 0 ? letter : '$letter$n';
  }
  return ids;
}

/// The scale id of the axis [axis] of a dataset (`xAxisID` or `yAxisID`),
/// or Dart `null` for no axis: the default of Chart.js, the first scale of
/// the direction (Chart.js ADR 0191, item 5). A dataset class of a package
/// calls it in `lowerOwn`. The axis is `==` to an axis of
/// `ChartConfig.scales`.
String? scaleIdOfAxis(ChartAxis? axis) {
  if (axis == null) return null;
  final id = currentScaleIds?[axis];
  assert(
    id != null,
    'The axis $axis of a dataset is not an axis of ChartConfig.scales '
    '(Chart.js ADR 0191). Give the same axis object in scales.',
  );
  return id;
}

/// Writes the option value [value] under [key] of [scope] when it is not
/// Dart `null` (Chart.js ADR 0054 §7): the cell of the shape of the key in
/// the kind of [scope]. A key that the kind does not declare is an extra.
///
/// An object value of the conversions (a Map) becomes a typed scope of the
/// kind of the key when the key has one, else a new `<String, Object?>` Map.
/// A typed scope, a List and a function go by reference.
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
    final previous = target.ownCell(name)?.raw;
    _store(
      target,
      name,
      previous is TooltipCallbacks && value is TooltipCallbacks
          ? previous.merge(value)
          : value,
    );
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
