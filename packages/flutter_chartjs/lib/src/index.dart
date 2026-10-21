// Ported from Chart.js v4.5.1+7169e651 src/index.ts (MIT, Chart.js Contributors).

/// Port of `src/index.ts`, the part of phases 6 and 7: the exports of the
/// ported modules, the four namespaces and [registerables] (Chart.js ADR
/// 0020, section 6).
///
/// - index.ts:1-6 `export * from` the six `index` modules. The port exports
///   `controllers/index.dart` (:1), `core/index.dart` (:2),
///   `elements/index.dart` (:3), `platform/index.dart` (:4) and
///   `scales/index.dart` (:6). The module of `plugins` (:5, phase 8) comes
///   in its phase.
/// - index.ts:8-11 `import * as` the four namespaces. In the published
///   bundle, a namespace is a frozen object with the export names as its
///   keys, in code unit order (Chart.js ADR 0020, probe 2). Thus each
///   namespace is an unmodifiable Map from the export name to the class
///   value of the class, or to the Map of the plugin. [elements] and
///   [scales] have all their entries. [controllers] gets the entries of the
///   controllers of each wave of phase 7, and [plugins] gets its entries in
///   phase 8.
/// - index.ts:13-18 exports the four namespaces by name.
///
/// `lib/flutter_chartjs.dart` does not export this library yet: the public
/// API comes in phase 9. The library exports `core/index.dart`, which is
/// not a pure layer.
library;

import 'package:flutter_chartjs/src/controllers/controller.bar.dart';
import 'package:flutter_chartjs/src/controllers/controller.bubble.dart';
import 'package:flutter_chartjs/src/controllers/controller.doughnut.dart';
import 'package:flutter_chartjs/src/controllers/controller.line.dart';
import 'package:flutter_chartjs/src/controllers/controller.polarArea.dart';
import 'package:flutter_chartjs/src/controllers/controller.radar.dart';
import 'package:flutter_chartjs/src/elements/element.arc.dart';
import 'package:flutter_chartjs/src/elements/element.bar.dart';
import 'package:flutter_chartjs/src/elements/element.line.dart';
import 'package:flutter_chartjs/src/elements/element.point.dart';
import 'package:flutter_chartjs/src/scales/scale.category.dart';
import 'package:flutter_chartjs/src/scales/scale.linear.dart';
import 'package:flutter_chartjs/src/scales/scale.logarithmic.dart';
import 'package:flutter_chartjs/src/scales/scale.radialLinear.dart';
import 'package:flutter_chartjs/src/scales/scale.time.dart';
import 'package:flutter_chartjs/src/scales/scale.timeseries.dart';
import 'package:flutter_chartjs/src/types/basic.dart';

export 'package:flutter_chartjs/src/controllers/index.dart';
export 'package:flutter_chartjs/src/core/index.dart';
export 'package:flutter_chartjs/src/elements/index.dart';
export 'package:flutter_chartjs/src/platform/index.dart';
export 'package:flutter_chartjs/src/scales/index.dart';

/// index.ts:8 `import * as controllers from './controllers/index.js'`.
///
/// The bundle keys are `BarController`, `BubbleController`,
/// `DoughnutController`, `LineController`, `PieController`,
/// `PolarAreaController`, `RadarController` and `ScatterController`. The
/// keys are in code unit order, as in the bundle (Chart.js ADR 0020,
/// section 6). The controllers come in the three waves of phase 7. Thus the
/// Map has the entries of the ported controllers only: `BarController` of
/// wave 1, and `BubbleController`, `DoughnutController`, `LineController`,
/// `PolarAreaController` and `RadarController` of wave 2.
final AnyObject controllers = Map<String, Object?>.unmodifiable(
  <String, Object?>{
    'BarController': BarController.jsClass,
    'BubbleController': BubbleController.jsClass,
    'DoughnutController': DoughnutController.jsClass,
    'LineController': LineController.jsClass,
    'PolarAreaController': PolarAreaController.jsClass,
    'RadarController': RadarController.jsClass,
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
/// The bundle keys are `Colors`, `Decimation`, `Filler`, `Legend`,
/// `SubTitle`, `Title` and `Tooltip`. The plugins come in phase 8. Thus the
/// Map has no entry yet.
final AnyObject plugins = Map<String, Object?>.unmodifiable(
  <String, Object?>{},
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
/// parameter (Chart.js ADR 0020, section 6).
final List<AnyObject> registerables = [controllers, elements, plugins, scales];
