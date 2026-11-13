// Original code, not ported from Chart.js: the gallery chart components.

import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart'
    show sankeyRegisterables;
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart'
    show zoomPlugin;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart'
    show Chart, registerables;

bool _registered = false;
bool _zoomRegistered = false;
bool _sankeyRegistered = false;

/// Registers the built-in components once: `registerables`, as
/// `src/index.umd.ts:28` does. They include the eight controllers and the
/// seven plugins.
void registerGalleryComponents() {
  if (_registered) return;
  _registered = true;
  Chart.register(registerables);
}

/// Registers the built-in components ([registerGalleryComponents]), then
/// the plugin of chartjs-plugin-zoom once, for all charts, as the docs of
/// the plugin do (`docs/scripts/register.js:5` of chartjs-plugin-zoom).
///
/// Two callers call it: the page "Zoom and pan" at its first build, which
/// gives the plugin its options, and the input probe of Chart.js ADR 0112
/// (`main_input_probe.dart`) at its start. The stress and benchmark
/// entries (`main_stress.dart`, `main_bench.dart`) never build that page:
/// their charts run no hook of the plugin, so their figures stay
/// comparable with the figures of earlier runs. Only the cases of the mode
/// `zoom` of the benchmark (`chartBenchZoomCases` of
/// `lib/bench/chart_bench.dart`) register the plugin, each for its own run,
/// and unregister it at its end. After a visit
/// of the page, the plugin runs on each chart of the app. With its default
/// options, each zoom and pan is off: the plugin adds
/// no event listener and changes no chart. It takes part in the data-only
/// updates of the host (`supportsDataUpdates`), so it keeps each chart on
/// that path.
void registerZoomComponents() {
  registerGalleryComponents();
  if (_zoomRegistered) return;
  _zoomRegistered = true;
  Chart.register([zoomPlugin]);
}

/// Registers the built-in components ([registerGalleryComponents]), then
/// the controller and the element of chartjs-chart-sankey once, as the docs
/// of that chart type do (`docs/chart-runtime.js:7` of chartjs-chart-sankey).
///
/// Only the page "Sankey" calls it, at its first build. The two components
/// add the chart type `sankey` and the element `flow` to the registry. They
/// run no code in a chart of another type.
void registerSankeyComponents() {
  registerGalleryComponents();
  if (_sankeyRegistered) return;
  _sankeyRegistered = true;
  Chart.register(sankeyRegisterables);
}

/// Two hidden linear scales of the fractions 0 to 1 (Chart.js ADR 0031
/// section 3). x has suggested bounds: a user `min` or `max` on unsorted
/// data with `parsing: false` drops points (helpers.extras.ts:94-133).
/// y has user bounds: `getMinMax` does not read the data
/// (core.scale.js:307-309). [hideTicks] adds `ticks: {display: false}`,
/// which skips the auto skip of a hidden scale (core.scale.js:457).
Map<String, Object?> unitScales({bool hideTicks = false}) => <String, Object?>{
  'x': <String, Object?>{
    'type': 'linear',
    'display': false,
    if (hideTicks) 'ticks': <String, Object?>{'display': false},
    'suggestedMin': 0.0,
    'suggestedMax': 1.0,
  },
  'y': <String, Object?>{
    'type': 'linear',
    'display': false,
    if (hideTicks) 'ticks': <String, Object?>{'display': false},
    'min': 0.0,
    'max': 1.0,
  },
};
