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
/// private function of the hook type `(types.Chart chart, AnyObject args,
/// AnyObject options)` (Chart.js ADR 0054 §12, in place of the upstream
/// parameter counts of Chart.js ADR 0038, section 3).
///
/// The `WeakMap` of `plugin.subtitle.js:4` is the file-private `Expando`
/// [_map] (Chart.js ADR 0038, section 5). An `Expando` holds its key
/// weakly, as a `WeakMap` does. `map.set` is `_map[chart] = title`,
/// `map.get` is `_map[chart]`, and `map.delete` is `_map[chart] = null`.
///
/// Not a pure layer: it imports `plugin.title.dart`, which imports
/// `helpers.extras`.
library;

import 'package:flutter_chartjs_port/src/core/core.layouts.dart' show layouts;
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show DescriptorsScope, FontSpecScope, TitleOptionsScope;
import 'package:flutter_chartjs_port/src/plugins/plugin.title.dart' show Title;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_chartjs_port/src/types/plugin.dart' show Plugin;

/// plugin.subtitle.js:4 `const map = new WeakMap()`.
///
/// The subtitle box of each chart. Dart `null` stands for the `undefined`
/// of `map.get` without an entry.
final Expando<Title> _map = Expando<Title>('subtitle');

/// plugin.subtitle.js:9 `start(chart, _args, options)`.
void _start(types.Chart chart, Object _, Object options) {
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
void _stop(types.Chart chart, Object _, Object _) {
  layouts.removeBox(chart, _map[chart]);
  _map[chart] = null;
}

/// plugin.subtitle.js:26 `beforeUpdate(chart, _args, options)`. Without a
/// subtitle, the null check throws the TypeError of the write into
/// `undefined` in `layouts.configure` (core.layouts.js:332).
void _beforeUpdate(types.Chart chart, Object _, Object options) {
  final title = _map[chart]!;
  layouts.configure(chart, title, options);
  title.options = options;
}

/// plugin.subtitle.js:6 the default export, `SubTitle` of
/// `src/plugins/index.js:5` (Chart.js ADR 0038, section 1).
///
/// A typed [Plugin] with the upstream keys in the upstream order. The hooks
/// read no args, so they take any args object.
final Plugin subTitle = Plugin()
  ..id = 'subtitle'
  ..start = _start
  ..stop = _stop
  ..beforeUpdate = _beforeUpdate
  // plugin.subtitle.js:32-43. A typed scope of the kind `TitleOptions`
  // (Chart.js ADR 0054 §3).
  ..defaults = (TitleOptionsScope()
    ..align = 'center'
    ..display = false
    ..font = (FontSpecScope()..weight = 'normal')
    ..fullSize = true
    ..padding = 0.0
    ..position = 'top'
    ..text = ''
    // by default greater than legend (1000) and smaller than title (2000)
    ..weight = 1500.0)
  // plugin.subtitle.js:45-47.
  ..defaultRoutes = <String, Object?>{'color': 'color'}
  // plugin.subtitle.js:49-52. A typed scope of the kind `Descriptors`.
  ..descriptors = (DescriptorsScope()
    ..descScriptable = true
    ..descIndexable = false);
