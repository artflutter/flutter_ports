{{flutter_js}}
{{flutter_build_config}}

// Native text (flutter/flutter#172561). With preferWebParagraph, the browser lays
// out and draws the text, so a page shows the fonts of the system. The engine
// has this path only in the CanvasKit renderer, and only in a browser with the
// Enhanced TextMetrics API (window.TextCluster). Chrome has that API behind the
// flag chrome://flags/#enable-experimental-web-platform-features. A --wasm build
// ignores the setting on skwasm. Thus a browser with the API takes the
// JavaScript build with CanvasKit.
const config = {preferWebParagraph: true};
if (typeof window.TextCluster !== 'undefined') {
  config.renderer = 'canvaskit';
}

// WebAssembly in Firefox and Safari. By default, the loader takes the
// WebAssembly build only in a Chromium browser (defaultWasmSupport of
// flutter_js). The loader of Flutter 3.50 keeps the JavaScript build for a
// browser that cannot run the WebAssembly build: Firefox before 147, and a
// Safari without the necessary WebAssembly features (before 26.2).
config.wasmAllowList = {gecko: true, webkit: true};

// The service worker settings are those of the default script of Flutter.
_flutter.loader.load({
  config,
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
});
