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
///   namespace is an unmodifiable Map from the export name to the class
///   value of the class, or to the Map of the plugin. Each namespace has all
///   its entries.
/// - index.ts:13-18 exports the four namespaces by name.
///
/// `lib/flutter_chartjs_port.dart` does not export this library yet: the public
/// API comes in phase 9. The library exports `core/index.dart`, which is
/// not a pure layer.
library;

import 'package:flutter_chartjs_port/src/controllers/controller.bar.dart';
import 'package:flutter_chartjs_port/src/controllers/controller.bubble.dart';
import 'package:flutter_chartjs_port/src/controllers/controller.doughnut.dart';
import 'package:flutter_chartjs_port/src/controllers/controller.line.dart';
import 'package:flutter_chartjs_port/src/controllers/controller.pie.dart';
import 'package:flutter_chartjs_port/src/controllers/controller.polarArea.dart';
import 'package:flutter_chartjs_port/src/controllers/controller.radar.dart';
import 'package:flutter_chartjs_port/src/controllers/controller.scatter.dart';
import 'package:flutter_chartjs_port/src/elements/element.arc.dart';
import 'package:flutter_chartjs_port/src/elements/element.bar.dart';
import 'package:flutter_chartjs_port/src/elements/element.line.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/plugins/index.dart';
import 'package:flutter_chartjs_port/src/scales/scale.category.dart';
import 'package:flutter_chartjs_port/src/scales/scale.linear.dart';
import 'package:flutter_chartjs_port/src/scales/scale.logarithmic.dart';
import 'package:flutter_chartjs_port/src/scales/scale.radialLinear.dart';
import 'package:flutter_chartjs_port/src/scales/scale.time.dart';
import 'package:flutter_chartjs_port/src/scales/scale.timeseries.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';

export 'package:flutter_chartjs_port/src/controllers/index.dart';
export 'package:flutter_chartjs_port/src/core/index.dart';
export 'package:flutter_chartjs_port/src/elements/index.dart';
export 'package:flutter_chartjs_port/src/platform/index.dart';
export 'package:flutter_chartjs_port/src/plugins/index.dart';
export 'package:flutter_chartjs_port/src/scales/index.dart';

/// index.ts:8 `import * as controllers from './controllers/index.js'`.
///
/// The keys are the eight controllers of phase 7, in code unit order, as in
/// the bundle (Chart.js ADR 0020, section 6). That order puts
/// `PieController` before `PolarAreaController`, where `controllers/index.js`
/// lists `PolarAreaController` first (:5-6). `TypedRegistry.register`
/// registers the parent class of `PieController` first in any case
/// (core.typedRegistry.js:28-31).
final AnyObject controllers = Map<String, Object?>.unmodifiable(
  <String, Object?>{
    'BarController': BarController.jsClass,
    'BubbleController': BubbleController.jsClass,
    'DoughnutController': DoughnutController.jsClass,
    'LineController': LineController.jsClass,
    'PieController': PieController.jsClass,
    'PolarAreaController': PolarAreaController.jsClass,
    'RadarController': RadarController.jsClass,
    'ScatterController': ScatterController.jsClass,
  },
);

/// index.ts:9 `import * as elements from './elements/index.js'`.
///
/// The keys are in code unit order, as in the bundle. `elements/index.js`
/// lists `ArcElement`, `LineElement`, `PointElement` and `BarElement`
/// (:1-4). That source order would register `line` before `bar`.
final AnyObject elements = Map<String, Object?>.unmodifiable(
  <String, Object?>{
    'ArcElement': ArcElement.jsClass,
    'BarElement': BarElement.jsClass,
    'LineElement': LineElement.jsClass,
    'PointElement': PointElement.jsClass,
  },
);

/// index.ts:10 `import * as plugins from './plugins/index.js'`.
///
/// The keys are the seven plugins in code unit order, as in the bundle
/// (Chart.js ADR 0038, section 2). That order is also the source order of
/// `plugins/index.js` (:1-7). Each value is the plugin object of its module
/// (Chart.js ADR 0038, section 1).
final AnyObject plugins = Map<String, Object?>.unmodifiable(
  <String, Object?>{
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
final AnyObject scales = Map<String, Object?>.unmodifiable(
  <String, Object?>{
    'CategoryScale': CategoryScale.jsClass,
    'LinearScale': LinearScale.jsClass,
    'LogarithmicScale': LogarithmicScale.jsClass,
    'RadialLinearScale': RadialLinearScale.jsClass,
    'TimeScale': TimeScale.jsClass,
    'TimeSeriesScale': TimeSeriesScale.jsClass,
  },
);

/// index.ts:20 `registerables`: the four namespaces.
///
/// `Chart.register(...registerables)` of upstream is
/// `Chart.register(registerables)`: the List is the array of the rest
/// parameter (Chart.js ADR 0020, section 6). It registers the plugin ids in
/// the order `colors`, `decimation`, `filler`, `legend`, `subtitle`, `title`
/// and `tooltip`, as the pinned build does (Chart.js ADR 0038, section 2).
final List<AnyObject> registerables = [controllers, elements, plugins, scales];
