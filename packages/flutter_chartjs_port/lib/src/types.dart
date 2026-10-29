// Ported from Chart.js v4.6.1 src/types.ts (MIT, Chart.js Contributors).

/// Port of `src/types.ts`: the `chart.js` entry of the values and the types
/// (Chart.js ADR 0048, section 4).
///
/// - types.ts:6 `export * from './index.js'`: `lib/src/index.dart`.
/// - types.ts:10-54 export the names that `index.js` and `types/index.js`
///   both export from `types/index.js`, to resolve the ambiguity. Dart takes
///   the 8 classes of `lib/src/index.dart` (`BasePlatform`, `Chart`,
///   `DatasetController`, `Element`, `LineElement`, `PointElement`,
///   `RadialLinearScale` and `Scale`) and hides the 8 interfaces of the same
///   names (`adapt-types-entry`). Each class implements its interface, so
///   each typed reader of the interface accepts it. The analyzer reports a
///   new collision as `ambiguous_export`.
/// - The TypeScript-only names of :48-52 (`PluginOptionsByType`,
///   `ElementOptionsByType`, `ChartDatasetProperties`, `UpdateModeEnum` and
///   `ArcSpacingMode`) have no Dart form. The plugin names of :36-41 are the
///   plugin Maps of `lib/src/plugins/index.dart` (Chart.js ADR 0038, section
///   1). `DomPlatform` (:35) is `FlutterPlatform` (Chart.js ADR 0037).
/// - types.ts:55 `export * from './types/index.js'`:
///   `lib/src/types/index.dart` without the 8 names.
///
/// `lib/chartjs.dart` exports this library. It exports `lib/src/index.dart`,
/// which is not a pure layer.
library;

export 'package:flutter_chartjs_port/src/index.dart';
// DIVERGES(chartjs): adapt-types-entry, the classes take the 8 shared names.
export 'package:flutter_chartjs_port/src/types/index.dart'
    hide
        BasePlatform,
        Chart,
        DatasetController,
        Element,
        LineElement,
        PointElement,
        RadialLinearScale,
        Scale;
