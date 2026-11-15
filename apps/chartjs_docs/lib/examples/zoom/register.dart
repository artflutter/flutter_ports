// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 docs/guide/integration.md (MIT, chartjs-plugin-zoom contributors).

import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// Registers the zoom plugin for each chart of the app.
void registerZoom() {
  // #docregion zoom-register
  Chart.register([zoomPlugin]);
  // #enddocregion zoom-register
}
