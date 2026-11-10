// Original code, not ported from chartjs-plugin-zoom: the public library.
/// A native Dart port of
/// [chartjs-plugin-zoom](https://github.com/chartjs/chartjs-plugin-zoom)
/// for `flutter_chartjs_port`: zoom and pan of a chart with the mouse wheel,
/// a drag, a pinch or the API.
///
/// Register the plugin before the first chart, as the upstream docs do:
///
/// ```dart
/// Chart.register([zoomPlugin]);
/// ```
///
/// Its options are `options.plugins.zoom` of a chart (`ZoomPluginOptions`):
/// in the config of `ChartView.raw`, or in `ChartConfig.extra` as
/// `{'plugins': {'zoom': {...}}}`. The methods of `ZoomChart` zoom and pan a
/// chart from code, for example `chart.zoom(.all(1.5))` and
/// `chart.resetZoom()`.
///
/// The port follows the upstream modules file by file. The `doc/` folder of
/// this package has the roadmap and the parity tracker.
library;

export 'src/gestures.dart' show ActivePointer, GestureEvent;
export 'src/index.dart'
    show ZoomChart, pan, resetZoom, zoom, zoomPlugin, zoomRect, zoomScale;
export 'src/options.dart'
    show
        DragOptions,
        DrawTime,
        GenericEvent,
        LimitOptions,
        Mode,
        ModeFn,
        ModifierKey,
        PanOptions,
        PinchOptions,
        RejectEvent,
        RejectableStartEvent,
        ScaleLimits,
        WheelOptions,
        ZoomCallback,
        ZoomChartContext,
        ZoomEventContext,
        ZoomOptions,
        ZoomPluginOptions,
        ZoomStartContext,
        ZoomTrigger,
        ZoomTriggerContext;
export 'src/scale.types.dart'
    show
        PanFunction,
        ZoomFunction,
        ZoomRectFunction,
        panFunctions,
        zoomFunctions,
        zoomRectFunctions;
export 'src/types.dart' show PanAmount, ScaleRange, ZoomAmount;
export 'src/upstream.dart';
