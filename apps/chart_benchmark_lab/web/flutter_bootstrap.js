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

// No serviceWorkerSettings. With them, the loader sees the worker of isolate.js
// and registers the worker of Flutter in the same scope. That worker unregisters
// itself and reloads the page, so that the page loses the COOP and COEP headers.
_flutter.loader.load({config: nativeTextConfig});
