// Ported from Chart.js v4.6.1 src/plugins/plugin.subtitle.js (MIT, Chart.js Contributors).

/// Port of `src/plugins/plugin.subtitle.js`.
///
/// [subTitle] is the plugin object, the default export of the upstream file
/// and `SubTitle` of `src/plugins/index.js:5` (Chart.js ADR 0038, section
/// 1). It is a typed `Plugin` (Chart.js ADR 0054 §12) with the upstream
/// keys in the upstream order: `id`, `start`, `stop`, `beforeUpdate`,
/// `defaults`, `defaultRoutes` and `descriptors`. It has no `_element`.
///
/// The subtitle box is a [Title] of `plugin.title.dart`. Each hook is a
/// private function of the hook type `(types.Chart chart, args,
/// TitleOptions options)` (Chart.js ADR 0150, in place of the upstream
/// parameter counts of Chart.js ADR 0038, section 3): the argument class of
/// its hook, and the facade of the resolved options.
///
/// The `WeakMap` of `plugin.subtitle.js:4` is the file-private `Expando`
/// [_map] (Chart.js ADR 0038, section 5). An `Expando` holds its key
/// weakly, as a `WeakMap` does. `map.set` is `_map[chart] = title`,
/// `map.get` is `_map[chart]`, and `map.delete` is `_map[chart] = null`.
///
/// Not a pure layer: it imports `plugin.title.dart`, which imports
/// `helpers.extras`.
library;

import 'dart:ui' show FontWeight;

import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_chartjs_port/chartjs.dart';

/// plugin.subtitle.js:4 `const map = new WeakMap()`.
///
/// The subtitle box of each chart. Dart `null` stands for the `undefined`
/// of `map.get` without an entry.
final Expando<Title> _map = Expando<Title>('subtitle');

/// plugin.subtitle.js:9 `start(chart, _args, options)`. The box keeps the
/// resolved options of the facade.
void _start(IChart chart, PluginHookArgs _, TitleOptions options) {
  final resolved = options.object!;
  final title = Title((ctx: chart.ctx, options: resolved, chart: chart));

  layouts
    ..configure(chart, title, resolved)
    ..addBox(chart, title);
  _map[chart] = title;
}

/// plugin.subtitle.js:21 `stop(chart)`. Dart `null` stands for the
/// `undefined` of `map.get` on a chart without a subtitle: `removeBox` then
/// changes nothing (core.layouts.js:318-323). `map.delete(chart)` is the
/// write of Dart `null`.
void _stop(IChart chart, PluginHookArgs _, TitleOptions _) {
  layouts.removeBox(chart, _map[chart]);
  _map[chart] = null;
}

/// plugin.subtitle.js:26 `beforeUpdate(chart, _args, options)`. Without a
/// subtitle, the null check throws the TypeError of the write into
/// `undefined` in `layouts.configure` (core.layouts.js:332).
bool _beforeUpdate(IChart chart, UpdateHookArgs _, TitleOptions options) {
  final title = _map[chart]!;
  final resolved = options.object!;
  layouts.configure(chart, title, resolved);
  title.options = resolved;
  return true;
}

/// plugin.subtitle.js:6 the default export, `SubTitle` of
/// `src/plugins/index.js:5` (Chart.js ADR 0038, section 1).
///
/// A native [Plugin] (Chart.js ADR 0144) with the upstream keys in the
/// upstream order. The hooks get the facade [TitleOptions] (Chart.js ADR
/// 0150).
final subTitle = SubtitlePlugin();

/// The subtitle plugin: a class of its own, so
/// `registry.getPlugin<SubtitlePlugin>()`
/// finds it by its type.
// DIVERGES(chartjs): adapt-typed-plugins, a class for each plugin.
final class SubtitlePlugin() extends Plugin<TitleOptions> {
  /// The subtitle plugin.
  this
    : super(
        id: 'subtitle',
        // The hooks get the facade of the resolved options (Chart.js ADR 0150).
        options: TitleOptions.new,
        start: _start,
        stop: _stop,
        beforeUpdate: _beforeUpdate,
        // plugin.subtitle.js:32-43. A typed scope of the kind `TitleOptions`
        // (Chart.js ADR 0054 §3).
        defaults: TitleOptionsScope()
          // DIVERGES(chartjs): adapt-chart-align-enum, the enum value.
          ..align = ChartAlign.center
          ..display = false
          // DIVERGES(chartjs): adapt-text-style-fonts, the font is a
          // ChartTextStyle.
          ..font = const ChartTextStyle(fontWeight: FontWeight.normal)
          ..fullSize = true
          ..padding = EdgeInsets.zero
          ..position = ChartPosition.top
          // DIVERGES(chartjs): adapt-title-text-lines, the lines of `''`.
          ..text = const ['']
          // by default greater than legend (1000) and smaller than title (2000)
          ..weight = 1500.0,
        // plugin.subtitle.js:45-47.
        defaultRoutes: const {'color': 'color'},
        // plugin.subtitle.js:49-52. A typed scope of the kind `Descriptors`.
        descriptors: DescriptorsScope()
          ..descScriptable = true
          ..descIndexable = false,
        // DIVERGES(chartjs): adapt-incremental-data-update, partial-lifecycle
        // opt-in.
        supportsDataUpdates: true,
      );
}
