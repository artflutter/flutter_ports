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
/// The options of a chart are one immutable `ZoomPluginOptions`: in
/// `ChartConfig.pluginOptions` of a typed config, or in
/// `options.plugins.zoom` of the config of `ChartView.raw`:
///
/// ```dart
/// ChartView(
///   config: ChartConfig(
///     type: .line,
///     datasets: [LineDataset(data: values)],
///     pluginOptions: const [
///       ZoomPluginOptions(
///         pan: PanOptions(enabled: true, mode: Mode.x),
///         zoom: ZoomOptions(wheel: WheelOptions(enabled: true), mode: Mode.x),
///         limits: {'x': ScaleLimits(min: ScaleLimit.original)},
///       ),
///     ],
///   ),
/// );
/// ```
///
/// The methods of `ZoomChart` zoom and pan a chart from code, for example
/// `chart.zoom(.all(1.5))` and `chart.resetZoom()`.
///
/// The plugin takes part in the data-only updates of the host
/// (`ChartView.dataOnlyUpdates`): new data keeps the zoom range.
///
/// The port follows the upstream modules file by file: each module of the
/// pinned upstream `src/` folder is ported. The `doc/` folder of this
/// package has the roadmap and the parity tracker.
library;

export 'src/gestures.dart' show ActivePointer, GestureEvent;
export 'src/index.dart'
    show
        ZoomChart,
        pan,
        resetZoom,
        zoom,
        zoomPlugin,
        zoomRect,
        zoomScale,
        zoomUpdateMode;
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
        ScaleLimit,
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
