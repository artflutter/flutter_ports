// Ported from Chart.js v4.5.1+7169e651 src/core/index.ts (MIT, Chart.js Contributors).

/// Port of `src/core/index.ts`: the exports of the core modules (Chart.js
/// ADR 0020, section 6).
///
/// Each line of upstream exports the default export of a module, or two
/// types. Dart has no default export and no `export ... as`. Thus each
/// `export` directive shows the Dart name of the upstream export, with the
/// rules of Chart.js ADR 0012:
/// - index.ts:1 `export type {DateAdapter, TimeUnit} from
///   './core.adapters.js'`: the interface `DateAdapter` and the typedef
///   `TimeUnit`.
/// - index.ts:2 `export {default as _adapters} from './core.adapters.js'`:
///   `adapters`. The name drops the underscore, because another module
///   reads it.
/// - index.ts:3 `Animation`, index.ts:4 `Animations` and index.ts:5
///   `animator`.
/// - index.ts:6 `Chart`. The class values of the components are static
///   members (`jsClass`). They need no export of their own.
/// - index.ts:7 `DatasetController`, index.ts:8 `defaults`, index.ts:9
///   `Element`, index.ts:10 `Interaction` and index.ts:11 `layouts`.
/// - index.ts:12 `export {default as plugins} from './core.plugins.js'`:
///   the class name `PluginService`. In `src/index.ts`, the local export
///   `plugins` (:13-18) takes the place of that name in any case.
/// - index.ts:13 `registry` and index.ts:14 `Scale`.
/// - index.ts:15 `export {default as Ticks} from './core.ticks.js'`: the
///   object `ticks`, a variable with a lowerCamelCase name (Chart.js ADR
///   0012).
///
/// The `directives_ordering` lint sorts the list. The library exports
/// `core.animator`, which imports `helpers.extras`. Thus it is not a pure
/// layer.
library;

export 'package:flutter_chartjs/src/core/core.adapters.dart'
    show DateAdapter, TimeUnit, adapters;
export 'package:flutter_chartjs/src/core/core.animation.dart' show Animation;
export 'package:flutter_chartjs/src/core/core.animations.dart' show Animations;
export 'package:flutter_chartjs/src/core/core.animator.dart' show animator;
export 'package:flutter_chartjs/src/core/core.controller.dart' show Chart;
export 'package:flutter_chartjs/src/core/core.datasetController.dart'
    show DatasetController;
export 'package:flutter_chartjs/src/core/core.defaults.dart' show defaults;
export 'package:flutter_chartjs/src/core/core.element.dart' show Element;
export 'package:flutter_chartjs/src/core/core.interaction.dart'
    show Interaction;
export 'package:flutter_chartjs/src/core/core.layouts.dart' show layouts;
export 'package:flutter_chartjs/src/core/core.plugins.dart' show PluginService;
export 'package:flutter_chartjs/src/core/core.registry.dart' show registry;
export 'package:flutter_chartjs/src/core/core.scale.dart' show Scale;
export 'package:flutter_chartjs/src/core/core.ticks.dart' show ticks;
