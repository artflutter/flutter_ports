// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 src/defaults.ts (MIT, chartjs-plugin-zoom contributors).

/// The default options of the plugin, `zoomPlugin.defaults`.
///
/// The defaults are one immutable [ZoomPluginOptions] (Chart.js ADR 0148).
/// The registry of the host writes it into `defaults.plugins.zoom`, and the
/// plugin service merges the options of each chart over it. The public
/// library does not export it: the name clashes with `defaults` of the host.
library;

import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';

/// defaults.ts:3 `defaults`: the default `ZoomPluginOptions`.
///
/// `modifierKey: null` of upstream is a field that is not set: the
/// `modifierKey` fields stay null.
// DIVERGES(zoom): adapt-native-zoom-options, null is a field that is not set.
const ZoomPluginOptions defaults = ZoomPluginOptions(
  pan: PanOptions(enabled: false, mode: Mode.xy, threshold: 10),
  zoom: ZoomOptions(
    wheel: WheelOptions(enabled: false, speed: 0.1),
    drag: DragOptions(enabled: false, drawTime: DrawTime.beforeDatasetsDraw),
    pinch: PinchOptions(enabled: false),
    mode: Mode.xy,
  ),
);
