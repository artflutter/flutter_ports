// Ported from Chart.js v4.6.1 src/index.ts (MIT, Chart.js Contributors).

/// Port of `src/index.ts`: the exports of the ported modules, the four
/// namespaces and [registerables] (Chart.js ADR 0020, section 6, and Chart.js
/// ADR 0038, section 2).
///
/// - index.ts:1-6 `export * from` the six `index` modules. The port exports
///   `controllers/index.dart` (:1), `core/index.dart` (:2),
///   `elements/index.dart` (:3), `platform/index.dart` (:4),
///   `plugins/index.dart` (:5) and `scales/index.dart` (:6).
/// - index.ts:8-11 `import * as` the four namespaces. In the published
///   bundle, a namespace is a frozen object with the export names as its
///   keys, in code unit order (Chart.js ADR 0020, probe 2). Thus each
///   namespace is an unmodifiable Map from the export name to the typed
///   component of the class (Chart.js ADR 0204), or to the plugin. Each
///   namespace has all its entries.
/// - index.ts:13-18 exports the four namespaces by name.
///
/// `lib/chartjs.dart` exports this library through `lib/src/types.dart`
/// (Chart.js ADR 0048, section 5). The library exports `core/index.dart`,
/// which is not a pure layer.
library;

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

export 'package:flutter_chartjs_port/src/controllers/index.dart';
export 'package:flutter_chartjs_port/src/core/index.dart';
export 'package:flutter_chartjs_port/src/elements/index.dart';
export 'package:flutter_chartjs_port/src/platform/index.dart';
export 'package:flutter_chartjs_port/src/plugins/index.dart';
export 'package:flutter_chartjs_port/src/scales/index.dart';

/// index.ts:8 `import * as controllers from './controllers/index.js'`.
///
/// The keys are the eight controllers of phase 7, in code unit order, as in
/// the bundle (Chart.js ADR 0204). That order puts
/// `PieController` before `PolarAreaController`, where `controllers/index.js`
/// lists `PolarAreaController` first (:5-6). `TypedRegistry.register`
/// registers the parent class of `PieController` first in any case
/// (core.typedRegistry.js:28-31).
final Map<String, ControllerType> controllers = Map.unmodifiable(
  <String, ControllerType>{
    'BarController': BarController.component,
    'BubbleController': BubbleController.component,
    'DoughnutController': DoughnutController.component,
    'LineController': LineController.component,
    'PieController': PieController.component,
    'PolarAreaController': PolarAreaController.component,
    'RadarController': RadarController.component,
    'ScatterController': ScatterController.component,
  },
);

/// index.ts:9 `import * as elements from './elements/index.js'`.
///
/// The keys are in code unit order, as in the bundle. `elements/index.js`
/// lists `ArcElement`, `LineElement`, `PointElement` and `BarElement`
/// (:1-4). That source order would register `line` before `bar`.
final Map<String, ElementType> elements = Map.unmodifiable(
  <String, ElementType>{
    'ArcElement': ArcElement.component,
    'BarElement': BarElement.component,
    'LineElement': LineElement.component,
    'PointElement': PointElement.component,
  },
);

/// index.ts:10 `import * as plugins from './plugins/index.js'`.
///
/// The keys are the seven plugins in code unit order, as in the bundle
/// (Chart.js ADR 0038, section 2). That order is also the source order of
/// `plugins/index.js` (:1-7). Each value is the plugin object of its module
/// (Chart.js ADR 0038, section 1).
final Map<String, Plugin<Object?>> plugins = Map.unmodifiable(
  <String, Plugin<Object?>>{
    'Colors': colors,
    'Decimation': decimation,
    'Filler': filler,
    'Legend': legend,
    'SubTitle': subTitle,
    'Title': title,
    'Tooltip': tooltip,
  },
);

/// index.ts:11 `import * as scales from './scales/index.js'`.
///
/// The keys are in code unit order, as in the bundle. That order is also the
/// source order of `scales/index.js` (:1-6). `LinearScaleBase` is not an
/// export of `scales/index.js`. Thus it is not a key.
final Map<String, ScaleType> scales = Map.unmodifiable(<String, ScaleType>{
  'CategoryScale': CategoryScale.component,
  'LinearScale': LinearScale.component,
  'LogarithmicScale': LogarithmicScale.component,
  'RadialLinearScale': RadialLinearScale.component,
  'TimeScale': TimeScale.component,
  'TimeSeriesScale': TimeSeriesScale.component,
});

/// index.ts:20 `registerables`: the items of the four namespaces, in their
/// order.
///
/// `Chart.register(...registerables)` of upstream is
/// `Chart.register(registerables)`: the List holds the items of the
/// namespaces, not the namespaces (Chart.js ADR 0204). It registers the
/// plugin ids in the order `colors`, `decimation`, `filler`, `legend`,
/// `subtitle`, `title` and `tooltip`, as the pinned build does (Chart.js ADR
/// 0038, section 2).
// DIVERGES(chartjs): adapt-typed-components, the items, not the namespaces.
final List<IChartComponent> registerables = List.unmodifiable(<IChartComponent>[
  ...controllers.values,
  ...elements.values,
  ...plugins.values,
  ...scales.values,
]);
