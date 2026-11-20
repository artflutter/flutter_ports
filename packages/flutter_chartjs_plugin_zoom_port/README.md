# flutter_chartjs_plugin_zoom_port

A native Dart port of [chartjs-plugin-zoom](https://github.com/chartjs/chartjs-plugin-zoom) for
[`flutter_chartjs_port`](https://github.com/artflutter/flutter_ports/tree/main/packages/flutter_chartjs_port),
the native Dart port of Chart.js. The port translates the plugin modules to Dart: the zoom and pan
API, the wheel and drag zoom, the pointer pan and pinch, and the scale limits. The plugin runs on
the Dart chart of `flutter_chartjs_port`. The package uses no WebView, no JavaScript and no network
access at runtime.

The port also tests the connection between a third-party plugin and the Chart.js port. The plugin
uses only the public libraries of `flutter_chartjs_port`.
[doc/host-seams.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_chartjs_plugin_zoom_port/doc/host-seams.md)
lists each place where the plugin needs a part of the host port.

## Use

Register the plugin once, and give each chart its options as one `ZoomPluginOptions`:

```dart
Chart.register([zoomPlugin]);

ChartView(
  config: ChartConfig(
    datasets: [LineDataset(data: values)],
    pluginOptions: const [
      ZoomPluginOptions(
        pan: PanOptions(enabled: true, mode: Mode.x),
        zoom: ZoomOptions(wheel: WheelOptions(enabled: true), mode: Mode.x),
        limits: LimitOptions(x: ScaleLimits(min: ScaleLimit.original, max: ScaleLimit.original)),
      ),
    ],
  ),
  onChartCreated: (chart) => this.chart = chart,
);

// Later: zoom and reset from code.
chart.zoom(const .all(1.5));
chart.resetZoom();
```

A raw config of `ChartView.raw` holds the same object in `options.plugins.zoom`.

## Stable axes during zoom and pan

Each zoom or pan step sets a new `min` and `max` on the scales. By default, a linear scale adds
these two bounds as ticks (`ticks.includeBounds`). Their labels, for example `12.37`, change in
each step. Then the axis width or height changes, and the plot area moves in each step: the chart
shakes. The x axis also asks for room at its sides for half of its first and last label, from the
positions of these ticks, and a pan moves them. Chart.js in a browser acts the same way.

For a steady plot area, give the chart these options:

```dart
'layout': {
  // Room for half of the last x label.
  'padding': {'right': 24},
},
'scales': {
  'x': {
    'type': 'linear',
    // No bound ticks, and no rotation of the x labels.
    'ticks': {'includeBounds': false, 'maxRotation': 0, 'minRotation': 0},
    // No room at the sides that changes with the tick positions.
    'afterFit': (Object? scale) {
      (scale! as Scale)
        ..paddingLeft = 0
        ..paddingRight = 0;
    },
  },
  'y': {
    'type': 'linear',
    'ticks': {'includeBounds': false},
    // A fixed width, so that a wider label does not move the plot area.
    'afterFit': (Object? scale) {
      (scale! as Scale).width = 56;
    },
  },
},
```

Choose the y-axis width and the right padding for the widest labels of your data. The input
probe of the gallery (`apps/chartjs_gallery/lib/main_input_probe.dart`) uses these options, and
its test pins a plot area that stays in place during zoom and pan steps.

## Upstream

The port tracks chartjs-plugin-zoom **2.2.0+fb81d331** (`chartjsPluginZoomVersion`): the commit
`fb81d331` of `master`, 34 commits after the release tag `v2.2.0`. The release `v2.2.0` depends on
Hammer.js. The pinned commit uses the DOM Pointer Events in place of Hammer.js. A git submodule
under `third_party/` pins the repository. [tool/port_sources.yaml](tool/port_sources.yaml) gives
the pin with its license and holder.

## License

MIT, the license of chartjs-plugin-zoom. [LICENSE](LICENSE) keeps the notice of the
chartjs-plugin-zoom contributors with the notice of the port. This project is not affiliated with
the Chart.js project.
