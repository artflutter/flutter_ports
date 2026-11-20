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
/// pinned upstream `src/` folder is ported, and the library exports each of
/// them (ADR 0011). The `doc/` folder of this package has the roadmap and
/// the parity tracker.
library;

// The library hides `State` of `src/state.dart`, an internal name that
// clashes with the Flutter `State`, so that an app imports the library next
// to Flutter. A file of lib/src that uses it imports its file (ADR 0011).
export 'package:flutter_chartjs_plugin_zoom_port/src/core.dart';
export 'package:flutter_chartjs_plugin_zoom_port/src/defaults.dart';
export 'package:flutter_chartjs_plugin_zoom_port/src/gestures.dart';
export 'package:flutter_chartjs_plugin_zoom_port/src/handlers.dart';
export 'package:flutter_chartjs_plugin_zoom_port/src/index.dart';
export 'package:flutter_chartjs_plugin_zoom_port/src/options.dart';
export 'package:flutter_chartjs_plugin_zoom_port/src/plugin.dart';
export 'package:flutter_chartjs_plugin_zoom_port/src/scale.types.dart';
export 'package:flutter_chartjs_plugin_zoom_port/src/state.dart' hide State;
export 'package:flutter_chartjs_plugin_zoom_port/src/types.dart';
export 'package:flutter_chartjs_plugin_zoom_port/src/upstream.dart';
export 'package:flutter_chartjs_plugin_zoom_port/src/utils.dart';
