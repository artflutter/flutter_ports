// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 src/index.umd.ts (MIT, chartjs-plugin-zoom contributors).

/// The UMD entry of the plugin: [chartZoom], the plugin object that registers
/// itself (Zoom ADR 0002 item 8).
///
/// Dart has no import side effects and no global object. Thus the body of
/// the module (index.umd.ts:4) runs at the first read of [chartZoom], once in
/// each isolate, not at the import, as the UMD entry `chartUmd` of the host
/// does. A second read gives the same object and registers nothing.
/// `window.ChartZoom` has no form. The public library does not export the
/// value: an app calls `Chart.register([zoomPlugin])` itself.
library;

import 'package:flutter_chartjs_plugin_zoom_port/src/plugin.dart';
import 'package:flutter_chartjs_port/chartjs.dart' show Chart, Plugin;

/// index.umd.ts:6 the default export, [zoomPlugin]. The first read runs
/// index.umd.ts:4 `Chart.register(Zoom)`.
final Plugin chartZoom = (() {
  Chart.register([zoomPlugin]);
  return zoomPlugin;
})();
