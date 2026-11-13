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
/// It also exports the typed plugin API (Chart.js ADR 0108): `Plugin`, the
/// hook type `PluginHookFunction` and the argument classes of the hooks. A
/// plugin of user code or of an add-on port is a `Plugin`, or a Map. A hook
/// function can declare its chart parameter as `Object` and cast it to
/// `Chart` once: `Object? beforeEvent(Object chart, EventHookArgs args,
/// Object options)`.
///
/// It also exports the input surface of the canvas for plugins that listen
/// to the input themselves (Chart.js ADR 0108): `NativeEvent` (the DOM event
/// with its fields, `preventDefault()` and `stopPropagation()`),
/// `NativeTouch`, `NativeEventListener`, `NativeEventTarget`, `DOMRect`, the
/// extension `CanvasEventTarget` (`canvas.addEventListener`,
/// `removeEventListener`, `dispatchEvent`, `ownerDocument`, `eventTarget`
/// and `getBoundingClientRect()`) and the extension `CssStyleProperties`
/// (`style.touchAction`, `style.userSelect` and `removeProperty`).
///
/// It also exports the names that a chart type of user code or of an add-on
/// port needs (Chart.js ADR 0132): `ParsedItem`, the parsed item of the
/// parse functions of `DatasetController`, `ElementPoint`, the result of
/// `Element.tooltipPosition`, and `VisualElementRange`, the interface of an
/// element with `getRange`.
///
/// The Dart names of the upstream `_` exports, the other port-only
/// declarations of `lib/src/types/` and `LayoutItem` stay internal (Chart.js
/// ADR 0048, section 6).
library;

export 'package:flutter_chartjs_port/src/canvas/canvas.dart'
    show
        CSSStyleDeclaration,
        CanvasCompositeOperation,
        CanvasImageSource,
        CanvasPath,
        CanvasRenderingContext2D,
        CanvasTextBaseline,
        CssStyleProperties,
        HTMLCanvasElement,
        Path2D,
        TextMetrics;
export 'package:flutter_chartjs_port/src/core/core.animation.dart'
    show Interpolator;
export 'package:flutter_chartjs_port/src/core/core.controller.dart'
    show AnimationEventHandler, ChartEventHandler, ChartResizeHandler;
export 'package:flutter_chartjs_port/src/core/core.element.dart'
    show ElementPoint;
export 'package:flutter_chartjs_port/src/core/core.scale.dart'
    show PointLabelCallback, ScaleHook, TickCallback;
export 'package:flutter_chartjs_port/src/core/date_adapter.dart'
    show defaultDateZone, setDefaultDateZone;
export 'package:flutter_chartjs_port/src/core/scale_option_enums.dart'
    show ScaleBounds, TickAlign, TickCrossAlign, TickSource;
export 'package:flutter_chartjs_port/src/helpers/cubic_interpolation_mode.dart'
    show CubicInterpolationMode;
export 'package:flutter_chartjs_port/src/helpers/grace_length.dart'
    show GraceLength, PercentGrace, ValueGrace;
export 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart'
    show
        CirclePointStyle,
        CrossPointStyle,
        CrossRotPointStyle,
        DashPointStyle,
        ImagePointStyle,
        LinePointStyle,
        RectPointStyle,
        RectRotPointStyle,
        RectRoundedPointStyle,
        StarPointStyle,
        TrianglePointStyle;
export 'package:flutter_chartjs_port/src/helpers/helpers.collection.dart'
    show notifyArrayListeners;
export 'package:flutter_chartjs_port/src/helpers/helpers.curve.dart'
    show DefaultCubicInterpolationMode, MonotoneCubicInterpolationMode;
export 'package:flutter_chartjs_port/src/helpers/point_style.dart'
    show PathPointStyle, PointStyle;
export 'package:flutter_chartjs_port/src/helpers/radius_length.dart'
    show PercentRadius, PixelRadius, RadiusLength;
export 'package:flutter_chartjs_port/src/js/js_class.dart' show JsClass;
export 'package:flutter_chartjs_port/src/js/js_object.dart' show JsObjectFace;
export 'package:flutter_chartjs_port/src/js/js_undefined.dart'
    show Undefined, undefined;
export 'package:flutter_chartjs_port/src/options/parsed.dart' show ParsedItem;
export 'package:flutter_chartjs_port/src/platform/chart_host.dart'
    show CanvasEventTarget;
export 'package:flutter_chartjs_port/src/platform/native_event.dart'
    show
        DOMRect,
        NativeEvent,
        NativeEventListener,
        NativeEventTarget,
        NativeTouch;
export 'package:flutter_chartjs_port/src/plugins/decimation_algorithm.dart'
    show DecimationAlgorithm;
export 'package:flutter_chartjs_port/src/plugins/fill_target.dart'
    show FillBoundary, FillTarget, RelativeFill;
export 'package:flutter_chartjs_port/src/plugins/filler_draw_time.dart'
    show FillerDrawTime;
export 'package:flutter_chartjs_port/src/plugins/plugin.decimation.dart'
    show LttbDecimationAlgorithm, MinMaxDecimationAlgorithm;
export 'package:flutter_chartjs_port/src/plugins/plugin.legend.dart'
    show LegendLabelsGenerator;
export 'package:flutter_chartjs_port/src/plugins/plugin.tooltip.dart'
    show AverageTooltipPositioner, NearestTooltipPositioner;
export 'package:flutter_chartjs_port/src/plugins/tooltip_position.dart'
    show TooltipPosition, TooltipPositioner;
export 'package:flutter_chartjs_port/src/scales/scale.time.dart'
    show TimeParser;
export 'package:flutter_chartjs_port/src/types.dart'
    hide
        ArcElementWrites,
        ElementPropertyRead,
        LayoutItem,
        LineElementWrites,
        PluginService,
        PointCircleRun,
        PointElementProperty,
        PointElementWrites,
        PropertyAccess,
        RadialPointElement,
        ScaleCache,
        ScaleRanges,
        SimpleArc,
        adapters,
        detectPlatform;
export 'package:flutter_chartjs_port/src/types/align.dart'
    show ChartAlign, TooltipXAlign, TooltipYAlign;
export 'package:flutter_chartjs_port/src/types/animation.dart'
    show AnimationEvent;
export 'package:flutter_chartjs_port/src/types/arc_option_enums.dart'
    show ArcBorderAlign, ArcSpacingMode;
export 'package:flutter_chartjs_port/src/types/bar_option_enums.dart'
    show BorderSkippedEdge;
export 'package:flutter_chartjs_port/src/types/chart_axis.dart'
    show CartesianAxis, RAxis, ScaleAxis, XAxis, YAxis;
export 'package:flutter_chartjs_port/src/types/chart_paint.dart'
    hide chartPaintOf;
export 'package:flutter_chartjs_port/src/types/chart_text_style.dart'
    show ChartTextStyle;
export 'package:flutter_chartjs_port/src/types/geometric.dart'
    show SplinePoint, TRBLCorners;
export 'package:flutter_chartjs_port/src/types/layout.dart'
    show ChartPosition, LayoutPosition, ScaleValuePosition;
export 'package:flutter_chartjs_port/src/types/legend_callbacks.dart';
export 'package:flutter_chartjs_port/src/types/legend_hit_box.dart';
export 'package:flutter_chartjs_port/src/types/legend_item.dart';
export 'package:flutter_chartjs_port/src/types/line_option_enums.dart'
    show SteppedLine;
export 'package:flutter_chartjs_port/src/types/plugin.dart'
    show
        CancelableHookArgs,
        DatasetDrawHookArgs,
        DatasetUpdateHookArgs,
        EventHookArgs,
        Plugin,
        PluginHookArgs,
        PluginHookFunction,
        ResizeHookArgs,
        TooltipDrawHookArgs,
        UpdateHookArgs;
export 'package:flutter_chartjs_port/src/types/tooltip_callbacks.dart'
    hide tooltipCallbacksOf, tooltipCallbacksPresence;
export 'package:flutter_chartjs_port/src/upstream.dart';
