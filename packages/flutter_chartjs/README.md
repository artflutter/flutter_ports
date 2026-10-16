# flutter_chartjs

A native Dart port of [Chart.js](https://www.chartjs.org) for Flutter. The Chart.js logic
(scales, layout, dataset controllers, elements, plugins, animations) is translated to Dart and
drawn with Flutter's own canvas, so charts are plain Flutter widgets. There is no WebView, no
JavaScript, and no network access at runtime, and it works on every Flutter platform, including
web builds compiled to WebAssembly.

> **Status:** work in progress. Nothing renders yet and the package is not published. Progress is
> tracked per upstream file in the
> [parity tracker](https://github.com/artflutter/flutter_ports/blob/main/docs/chartjs/parity.md).

This is not [`chartjs_flutter`](https://pub.dev/packages/chartjs_flutter), which hosts the
JavaScript Chart.js in a WebView. For how the existing Chart.js packages work, see the
[prior-art survey](https://github.com/artflutter/flutter_ports/blob/main/docs/prior-art/README.md).

## Upstream

Ports Chart.js **4.5.1** (exposed as `chartJsVersion`). Chart.js is MIT-licensed by the Chart.js
Contributors, and its notice is kept in [LICENSE](LICENSE). This project is not affiliated with the
Chart.js project.
