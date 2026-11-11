# chartjs_docs

The documentation site of `flutter_chartjs_port`. Each example on a page is a live `ChartView`.

Run `dart run melos run docs` to open the site in Chrome.

The code panels read the Dart files of `lib/examples/` and `lib/migrate/<library>/` as assets. The markers
`// #docregion <name>` and `// #enddocregion <name>` select the lines of a panel. Thus a panel shows the code
that draws its chart.

The pages "Migrate from fl_chart", "Migrate from Graphic" and "Migrate from Syncfusion" rebuild the line
chart demos of these libraries with the port. A browser address such as `#/migrate/fl_chart` opens a page.

GitHub Pages cannot send the COOP and COEP headers that the worker thread of skwasm needs. Thus `web/isolate.js`
adds them through a service worker, on `github.io` only. The first visit reloads the page once.
`web/flutter_bootstrap.js` gives the Flutter loader no service worker settings, because the worker of Flutter
removes any other worker in its scope. The code of both files is the code of the same files of
`apps/chart_benchmark_lab`.

`web/flutter_bootstrap.js` sets `wasmAllowList: {gecko: true, webkit: true}`. By default, the Flutter loader takes
the WebAssembly build only in a Chromium browser. With the key, Firefox from 147 and Safari from 26.2 take that
build too, and `web/isolate.js` also runs in them. As in the lab, `?build=js` in the address gives the JavaScript
build.

`web/flutter_bootstrap.js` also sets `preferWebParagraph: true`
([flutter/flutter#172561](https://github.com/flutter/flutter/issues/172561), from Flutter 3.50): the browser lays
out and draws the text with the fonts of the system. That path needs CanvasKit and the Enhanced TextMetrics API,
which Chrome has behind the flag `chrome://flags/#enable-experimental-web-platform-features`. A browser with the
API takes the JavaScript build with CanvasKit. Each other browser keeps its default build.
`dart run melos run docs` starts Chrome with the API.
