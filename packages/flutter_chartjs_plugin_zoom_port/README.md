# flutter_chartjs_plugin_zoom_port

A native Dart port of [chartjs-plugin-zoom](https://github.com/chartjs/chartjs-plugin-zoom) for
[`flutter_chartjs_port`](https://github.com/artflutter/flutter_ports/tree/main/packages/flutter_chartjs_port),
the native Dart port of Chart.js. The port translates the plugin modules to Dart: the zoom and pan
API, the wheel and drag zoom, the pointer pan and pinch, and the scale limits. The plugin runs on
the Dart chart of `flutter_chartjs_port`. The package uses no WebView, no JavaScript and no network
access at runtime.

> **Status:** phase 0, scaffold and design. The package has no ported code. It is not published.
> The plan, the roadmap and the decisions are in
> [doc/README.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_chartjs_plugin_zoom_port/doc/README.md).

The port also tests the connection between a third-party plugin and the Chart.js port. The plugin
uses only the public libraries of `flutter_chartjs_port`.
[doc/host-seams.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_chartjs_plugin_zoom_port/doc/host-seams.md)
lists each place where the plugin needs a part of the host port.

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
