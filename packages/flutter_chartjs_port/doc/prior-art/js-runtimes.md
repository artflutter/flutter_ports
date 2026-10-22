# Running real Chart.js without a WebView

Part of the [prior-art survey](README.md).

Can a Flutter app run the real Chart.js in an embedded JavaScript engine, with its `<canvas>` drawn by Flutter instead of a WebView? Apart from digia_ui, whose chart widget delegates to a WebView, none of the runtimes inspected ships Chart.js or has a Chart.js demo. WebF and flutter_fjs implement Canvas 2D on `dart:ui` but demonstrate ECharts, and on both the Chart.js config and callbacks would stay in JavaScript. The QuickJS builds checked lack `Intl`, which Chart.js uses for number formatting.

Facts that can change are as of 2026-10-16. Findings come from reading source code and were not independently re-checked; those for flutter_fjs, WebScene and the other bindings are the least certain.

## Summary

| Project | What it is | Canvas 2D drawn by Flutter | Chart.js | License | Maintenance (last publish) |
|---|---|---|---|---|---|
| WebF | QuickJS plus its own DOM/CSS | Yes | No (ECharts demoed) | GPL-3.0 with enterprise exception; earlier Apache-2.0 | Slowing; 0.22.44, 2026-06-24 |
| Kraken | WebF's predecessor | Small subset | No | Apache-2.0 | Unmaintained; 0.11.0, 2022-04-07 |
| flutter_fjs | Vue 3 renderer on QuickJS-ng | Yes | No (ECharts, F2 demoed) | MIT | New, active; 0.1.7, 2026-09-24 |
| WebScene | V8 plus a native DOM/Canvas engine | Partial coverage | No | Custom "MIT License with Restricted Party Clause" | Proof of concept; unpublished |
| lemon_js_ui | JS UI DSL on QuickJS | Non-standard API | No | Apache-2.0 | New, active; 0.3.1, 2026-10-08 |
| js_widget_runtime | JS that emits JSON widget trees | No | No (fl_chart) | MIT | Very active; 0.4.171, 2026-10-15 |
| flutter_js | QuickJS/JavaScriptCore binding | No | No | MIT | Infrequent; 0.8.7, 2026-01-27 |
| quickjs_runtime | Pure-Dart QuickJS binding | No | No | MIT | New, active; 0.3.6, 2026-10-14 |
| digia_ui | Server-driven UI SDK | No | Via chartjs_flutter (WebView) | Business Source License | Active; 1.10.0, 2026-05-19 |
| Other bindings | Bare JS engines | No | No | MIT or Apache-2.0 | Mixed |

## Runtimes with a Canvas 2D layer

### WebF

[pub.dev](https://pub.dev/packages/webf), [GitHub](https://github.com/openwebf/webf)

A web runtime: a QuickJS fork plus WebF's own DOM and CSS engine, on Android, iOS, macOS, Linux and Windows (no web or WASM). Canvas calls are forwarded to Dart over FFI and replayed by a `CustomPainter`.

Its canvas guide suggests exploring Chart.js, but no Chart.js code, demo, test or issue was found; WebF's showcase uses ECharts. Static reading (WebF was not run) finds these problems for unmodified Chart.js 4.5.1:

- The context has no `canvas` property and each `getContext('2d')` creates a new one, so Chart.js would fail with "can't acquire context" unless patched in JS.
- Without `Intl`, numeric tick labels and pie/doughnut tooltips throw unless a polyfill or custom callbacks are supplied.
- `textBaseline` is ignored, `fill()` and `fillText()` skip gradients and patterns, the last `setLineDash` in a frame applies to all its strokes, and `measureText` returns width only.

**License.** Current releases are GPL-3.0 with the OpenWebF Enterprise Exception, plus a paid Enterprise License for closed-source apps; GPL obligations apply to any distributed app without one. WebF was relicensed from Apache-2.0 in commit 90c27826 (2025-11-26). Apache-2.0 snapshots include pub 0.16.3+1, pub 0.16.4-beta.4 (2025-01-12) and commit a83942bf (2025-04-25); later pub releases are GPL (checked for 0.22.44 and 0.24.27).

**Maintenance.** 143 versions since 2022-07-25. The latest are 0.24.27 (2026-04-13) and 0.22.44 (2026-06-24), with no repository push since then.

### Kraken

[pub.dev](https://pub.dev/packages/kraken), [GitHub](https://github.com/openkraken/kraken)

WebF's predecessor (WebF forked it in 2022). Its canvas is a small subset: the JS API has no `measureText`, `setLineDash`, `globalAlpha`, compositing, shadows, gradients or `ctx.canvas`, so Chart.js cannot run, and frames are rasterized at logical size (blurry above 1x pixel ratio unless scaled manually). Apache-2.0. The last release, 0.11.0, is from 2022-04-07, and its `<3.0.0` SDK constraint does not resolve on Dart 3.

### flutter_fjs (ufjs)

[pub.dev](https://pub.dev/packages/flutter_fjs), [GitHub](https://github.com/snice/ufjs)

QuickJS-ng (or PrimJS) driving a Vue 3 custom renderer, on Android, iOS and macOS (no Flutter web or WASM). The 2D context is written in JS: it keeps the full state and encodes commands into a binary display list that a Dart `CustomPainter` replays each frame. `measureText` is a synchronous call into Dart that returns width and bounding-box metrics.

No attempt to run Chart.js on it was found; the example app runs ECharts 6 and AntV F2. Chart.js would need an `Intl.NumberFormat` polyfill; a custom Chart.js platform, because without `window` or `document` Chart.js falls back to one with no animation or events; and a writable canvas wrapper, as `canvas.width` and `height` are read-only. MIT. Repo created 2026-08-28, last pushed 2026-10-15.

### WebScene (Flutter backend)

[GitHub](https://github.com/SceneTech/WebScene), not on pub.dev

V8 plus a bounded native DOM/CSS/Canvas/SVG engine, whose scene snapshots the Flutter backend replays with `dart:ui`. Its Canvas 2D has no gradients or patterns. V8 ships ICU data, so `Intl` is probably available, but Chart.js has never been demonstrated (demos: TradingView, Monaco). The README calls the Flutter integration roadmap work, not supported; it runs only on Apple-silicon macOS. Last commit 2026-09-23.

## Runtimes without a Canvas 2D layer

- **[lemon_js_ui](https://pub.dev/packages/lemon_js_ui)** (Apache-2.0): QuickJS (FFI, or WebAssembly on web) driving a JS UI DSL. Its canvas is a non-standard command list (`ctx.clear`, `fillCircle`) with an estimated `measureText`; the docs do not promise full browser Canvas 2D compatibility.
- **[js_widget_runtime](https://pub.dev/packages/js_widget_runtime)** (MIT): JS emits a JSON tree rendered as Flutter widgets; charts use fl_chart or small `CustomPainter`s. No Canvas 2D or DOM; its `webView` node is a WebView (an iframe on web).
- **[flutter_js](https://pub.dev/packages/flutter_js)** (MIT): QuickJS on Android, Windows and Linux, and the system JavaScriptCore (which has `Intl`) on iOS and macOS; no web, DOM or canvas. Chart.js would need a hand-written Canvas 2D object with `ctx.canvas`, a Dart painter, synchronous `measureText`, an `Intl` polyfill on QuickJS and, for animation or events, a custom Chart.js platform; each call marshals a JSON string.
- **[quickjs_runtime](https://pub.dev/packages/quickjs_runtime)** (MIT): pure-Dart FFI bindings to QuickJS 2024-01-13; the native library is user-built. No DOM, canvas or `Intl`.
- **[digia_ui](https://pub.dev/packages/digia_ui)** (Business Source License): a server-driven UI SDK whose chart widget delegates to chartjs_flutter, a WebView wrapper. Its flutter_js dependency only evaluates user functions.
- **Other bindings** (MIT or Apache-2.0): flutter_qjs, flutter_qjs_next, quickjs_engine, flutter_jscore, fjs, jsf, flutter_jolt, mercuryjs, quickjs, qjs, dart_qjs and javascript_flutter only evaluate JS, with no DOM or canvas. Activity varies; flutter_qjs and flutter_jscore are Dart 2 only.

## Canvas 2D prior art for our port

Ranked by usefulness for mapping Canvas 2D semantics onto `dart:ui`:

1. **flutter_fjs (MIT): study, and reuse with attribution.** The best prior art found. In the ufjs repo, `packages/flutter_fjs/lib/src/canvas/replay.dart` maps Canvas 2D onto `dart:ui`, with documented handling of shadows, compositing and text origin; `host_module.dart` builds `TextMetrics`, including `actualBoundingBox*`, from `TextPainter`; `packages/fjs-runtime/src/canvas/context-2d.ts` has the state machine, property de-duplication, `arcTo` rewritten as `lineTo` plus `arc` (Flutter's `arcToPoint` has SVG semantics) and single-stop gradients padded to two stops; `measure.ts` is an LRU text-measurement cache; and `docs/canvas-compat.md` is a template for a compatibility ledger.
2. **WebF (GPL-3.0 with enterprise exception): design ideas only.** Do not copy current WebF code into an MIT port. Worth studying: the deferred action list with `needsPaint` markers and persistent root transforms, the `Picture` cache dropped on a full-canvas `clearRect`, `PathMetric` dashing, `MaskFilter.blur` shadows, `saveLayer` with a `BlendMode` for compositing, and the `Path2D` builders (`arc`, `arcTo`, `ellipse`, `roundRect`). Avoid its `textBaseline` and `setLineDash` handling, `Alignment`-based gradients and width-only `TextMetrics`. The Apache-2.0 snapshots lack some of these parts: their pub releases return null from `measureText`, and commit a83942bf lacks `globalAlpha`, dashes and compositing, which landed after the GPL switch (2025-11-30 to 2025-12-01).
3. **Kraken (Apache-2.0): reusable with a NOTICE file, but the least useful**: a small subset with no text metrics, and the origin of WebF's action-queue painter and `Path2D` code.

Also: WebScene's `CANVAS2D_COVERAGE.md` models a WPT-pinned compatibility ledger (non-standard license; reuse with caution), and lemon_js_ui caches static content as a retained `ui.Picture`. The other packages have nothing canvas-related to reuse.
