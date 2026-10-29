// Original code, not ported from Chart.js: the chart.js entry of the package.
/// The `chart.js` entry: the chart API, the components and their types, for
/// code that extends Chart.js (a plugin, a controller subclass, a scale).
///
/// Next to Flutter, import it with a prefix or with `hide Animation,
/// Element`: `Animation` and `Element` are also Flutter names. An app
/// imports `package:flutter_chartjs_port/flutter_chartjs_port.dart`, which
/// exports this library without the two names.
///
/// The library mirrors the code entry `.` of the `package.json` of Chart.js
/// (`src/types.ts`, Chart.js ADR 0048, section 5): the controllers, the
/// elements, the scales, the plugin objects, the platforms, the core
/// modules, the four namespaces and `registerables`, and the types of
/// `src/types/index.d.ts` that the port declares. Register the components
/// before the first chart: `Chart.register(registerables)`, or a List of
/// the class values and plugin Maps that the app needs (Chart.js ADR 0048,
/// section 3).
///
/// It also exports these port-only names: the Canvas 2D interface that a
/// plugin draws on (`chart.ctx`), the concrete `ChartMeta` of
/// `getDatasetMeta`, the zone functions of the default date adapter
/// (Chart.js ADR 0024), `notifyArrayListeners` (a change of a data array,
/// differences.md row `platform-array-events`), `JsClass` (the class value
/// of a user subclass, Chart.js ADR 0020) and `undefined` (the third state
/// of a config value, Chart.js ADR 0043).
///
/// The Dart names of the upstream `_` exports, the port-only declarations of
/// `lib/src/types/` and `LayoutItem` stay internal (Chart.js ADR 0048,
/// section 6).
library;

export 'package:flutter_chartjs_port/src/canvas/canvas.dart'
    show
        CSSStyleDeclaration,
        CanvasGradient,
        CanvasImageSource,
        CanvasPath,
        CanvasPattern,
        CanvasRenderingContext2D,
        HTMLCanvasElement,
        Path2D,
        TextMetrics;
export 'package:flutter_chartjs_port/src/core/core.controller.dart'
    show ChartMeta;
export 'package:flutter_chartjs_port/src/core/date_adapter.dart'
    show defaultDateZone, setDefaultDateZone;
export 'package:flutter_chartjs_port/src/helpers/helpers.collection.dart'
    show notifyArrayListeners;
export 'package:flutter_chartjs_port/src/js/js_class.dart' show JsClass;
export 'package:flutter_chartjs_port/src/js/js_undefined.dart'
    show Undefined, undefined;
export 'package:flutter_chartjs_port/src/types.dart'
    hide
        ChartMeta,
        ElementPropertyRead,
        LayoutItem,
        PluginService,
        PointElementProperty,
        PropertyAccess,
        RadialPointElement,
        ScaleRanges,
        SimpleArc,
        VisualElementRange,
        adapters,
        detectPlatform;
export 'package:flutter_chartjs_port/src/upstream.dart';
