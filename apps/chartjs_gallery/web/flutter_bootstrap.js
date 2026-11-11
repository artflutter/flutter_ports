{{flutter_js}}
{{flutter_build_config}}

// Native text (flutter/flutter#172561). With preferWebParagraph, the browser lays
// out and draws the text, so a page shows the fonts of the system. The engine
// has this path only in the CanvasKit renderer, and only in a browser with the
// Enhanced TextMetrics API (window.TextCluster). Chrome has that API behind the
// flag chrome://flags/#enable-experimental-web-platform-features. A --wasm build
// ignores the setting on skwasm. Thus a browser with the API takes the
// JavaScript build with CanvasKit. Each other browser keeps its default build.
const nativeTextConfig = {preferWebParagraph: true};
if (typeof window.TextCluster !== 'undefined') {
  nativeTextConfig.renderer = 'canvaskit';
}

// The service worker settings are those of the default script of Flutter.
_flutter.loader.load({
  config: nativeTextConfig,
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
});
