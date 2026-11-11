import 'dart:js_interop';

import 'package:flutter/foundation.dart' show kIsWasm;

@JS('crossOriginIsolated')
external bool? get _crossOriginIsolated;

@JS('TextCluster')
external JSAny? get _textCluster;

/// Whether the browser draws the text (Flutter issue 172561).
///
/// `web/flutter_bootstrap.js` gives a browser with the Enhanced TextMetrics API
/// the JavaScript build with `preferWebParagraph`. A WebAssembly build has no
/// such text path.
bool get _nativeText => !kIsWasm && _textCluster.isDefinedAndNotNull;

/// Whether the address of the page selects the JavaScript build.
///
/// `web/flutter_bootstrap.js` reads the query parameter `build`.
bool get _javaScriptByAddress => Uri.base.queryParameters['build'] == 'js';

/// How this page runs: a figure of one mode does not compare with another.
///
/// The Flutter loader gives skwasm its worker thread only on an isolated page.
String? webMode() {
  if (_nativeText) return 'JAVASCRIPT · NATIVE TEXT';
  if (!kIsWasm) return 'JAVASCRIPT';
  return _crossOriginIsolated == true ? 'WASM · THREADS' : 'WASM · 1 THREAD';
}

/// Why this page runs in its [webMode], for the note over the page.
String? webModeWhy() {
  if (!kIsWasm && _javaScriptByAddress) {
    return 'The address of this page has build=js, so the page runs the '
        'JavaScript build, which has no rendering thread. For WebAssembly, '
        'open the page with build=wasm in the address.'
        '${_nativeText ? ' This browser draws the text with the fonts of the '
                  'system.' : ''}';
  }
  if (_nativeText) {
    return 'This browser has the Enhanced TextMetrics API, so it lays out and '
        'draws the text with the fonts of the system. Flutter has this text '
        'path only in the JavaScript build, which has no rendering thread. '
        'For WebAssembly, open the page with ?build=wasm in the address, or '
        'turn off the Chrome flag "Experimental Web Platform features".';
  }
  if (!kIsWasm) {
    return 'This page uses WebAssembly in a current Chromium browser, in '
        'Firefox from 147 and in Safari from 26.2. This browser takes the '
        'JavaScript build, which has no rendering thread.';
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
