import 'dart:js_interop';

import 'package:flutter/foundation.dart' show kIsWasm;

@JS('crossOriginIsolated')
external bool? get _crossOriginIsolated;

/// How this page runs: a figure of one mode does not compare with another.
///
/// The Flutter loader gives skwasm its worker thread only on an isolated page.
String? webMode() {
  if (!kIsWasm) return 'JAVASCRIPT';
  return _crossOriginIsolated == true ? 'WASM · THREADS' : 'WASM · 1 THREAD';
}

/// Why this page runs in its [webMode], for the note over the page.
String? webModeWhy() {
  if (!kIsWasm) {
    return 'By default, Flutter uses WebAssembly only in a current Chromium '
        'browser. This browser takes the JavaScript build, which has no '
        'rendering thread. Open this page in a current Chrome or Edge for '
        'WebAssembly.';
  }
  if (_crossOriginIsolated == true) {
    return 'A worker thread does the rendering, so the main thread stays free '
        'for the chart code. GitHub Pages cannot send the headers that threads '
        'need, so a small service worker adds them. That is why the first '
        'visit reloads once.';
  }
  return 'This page is not cross-origin isolated, so the main thread does all '
      'the rendering, and a heavy chart can drop frames. On GitHub Pages, a '
      'service worker adds the missing headers, so reload the page once. If '
      'this mode stays, the browser blocks that worker.';
}
