// Ported from Chart.js v4.6.1 src/plugins/plugin.subtitle.js (MIT, Chart.js Contributors).

/// Port of `src/plugins/plugin.subtitle.js`.
///
/// [subTitle] is the plugin object, the default export of the upstream file
/// and `SubTitle` of `src/plugins/index.js:5` (Chart.js ADR 0038, section
/// 1). It is a typed `Plugin` (Chart.js ADR 0054 §12) with the upstream
/// keys in the upstream order: `id`, `start`, `stop`, `beforeUpdate` and
/// `defaults`; the `defaultRoutes` and the `descriptors` have no field
/// (Chart.js ADR 0197). It has no `_element`.
///
/// The subtitle box is a [Title] of `plugin.title.dart`. Each hook is a
/// private function of the hook type `(types.Chart chart, args,
/// SubtitleOptions options)` (Chart.js ADR 0150, in place of the upstream
/// parameter counts of Chart.js ADR 0038, section 3): the argument class of
/// its hook, and the merged [SubtitleOptions] (Chart.js ADR 0197).
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
/// merged options until `beforeUpdate` of the same update gives it the
/// options with their fallbacks.
void _start(IChart chart, PluginHookArgs _, SubtitleOptions options) {
  final title = Title((ctx: chart.ctx, options: options, chart: chart));

  layouts
    ..configure(chart, title, options)
    ..addBox(chart, title);
  _map[chart] = title;
}

/// plugin.subtitle.js:21 `stop(chart)`. Dart `null` stands for the
/// `undefined` of `map.get` on a chart without a subtitle: `removeBox` then
/// changes nothing (core.layouts.js:318-323). `map.delete(chart)` is the
/// write of Dart `null`.
void _stop(IChart chart, PluginHookArgs _, SubtitleOptions _) {
  layouts.removeBox(chart, _map[chart]);
  _map[chart] = null;
}

/// plugin.subtitle.js:26 `beforeUpdate(chart, _args, options)`. Without a
/// subtitle, the null check throws the TypeError of the write into
/// `undefined` in `layouts.configure` (core.layouts.js:332).
bool _beforeUpdate(IChart chart, UpdateHookArgs _, SubtitleOptions options) {
  final title = _map[chart]!;
  // The fallbacks of upstream and `scripted` (Chart.js ADR 0197).
  final resolved = resolvedTitleOptions(
    chart,
    options,
    (color) => SubtitleOptions(color: color),
  );
  layouts.configure(chart, title, resolved);
  title.options = resolved;
  return true;
}

/// plugin.subtitle.js:6 the default export, `SubTitle` of
/// `src/plugins/index.js:5` (Chart.js ADR 0038, section 1).
///
/// A native [Plugin] (Chart.js ADR 0144) with the upstream keys in the
/// upstream order. The hooks get the merged [SubtitleOptions] (Chart.js ADR
/// 0197).
final subTitle = SubtitlePlugin();

/// The subtitle plugin: a class of its own, so
/// `registry.getPlugin<SubtitlePlugin>()`
/// finds it by its type.
// DIVERGES(chartjs): adapt-typed-plugins, a class for each plugin.
final class SubtitlePlugin() extends Plugin<SubtitleOptions> {
  /// The subtitle plugin.
  this
    : super(
        id: 'subtitle',
        // The hooks get the merged SubtitleOptions (Chart.js ADR 0197).
        start: _start,
        stop: _stop,
        beforeUpdate: _beforeUpdate,
        // plugin.subtitle.js:32-43: one SubtitleOptions with each default
        // (Chart.js ADR 0197). The route of the `color` (:45-47) and the
        // descriptors (:49-52) have no field: the plugin gives the `color` of
        // `Chart.defaults` where no options set one, and the one function
        // `scripted` takes the place of the scriptable options
        // ([resolvedTitleOptions]).
        // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
        defaults: const SubtitleOptions(
          // DIVERGES(chartjs): adapt-chart-align-enum, the enum value.
          align: ChartAlign.center,
          display: false,
          // DIVERGES(chartjs): adapt-text-style-fonts, the font is a
          // ChartTextStyle.
          font: ChartTextStyle(fontWeight: FontWeight.normal),
          fullSize: true,
          padding: EdgeInsets.zero,
          position: ChartPosition.top,
          // DIVERGES(chartjs): adapt-title-text-lines, the lines of `''`.
          text: [''],
          // by default greater than legend (1000) and smaller than title (2000)
          weight: 1500,
        ),
        // DIVERGES(chartjs): adapt-incremental-data-update, partial-lifecycle
        // opt-in.
        supportsDataUpdates: true,
      );
}
