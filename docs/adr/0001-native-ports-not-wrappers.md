# ADR 0001: Native ports, not wrappers

- Status: accepted
- Date: 2026-10-16

## Context

A survey of pub.dev and GitHub ([prior art](../../packages/flutter_chartjs/doc/prior-art/README.md)) found no maintained native
Dart/Flutter port of Chart.js. Every Chart.js package usable from Flutter today runs the real
Chart.js JavaScript, in one of three ways:

- a WebView per chart on Android/iOS (`chartjs_flutter`, `js_widget`);
- a DOM `<canvas>` inside an `HtmlElementView` on Flutter web (`chartjs_flutter`, `js_widget`,
  the discontinued `flutter_web_chartjs`);
- JS-interop bindings for plain Dart web apps, not Flutter (Google's archived `chartjs`,
  `chartjs2`, `chart_engine`).

All of them pass a JSON config across a bridge, which gives:

- no Dart callbacks or scriptable options, and few or no events back to Dart;
- charts that are platform views, so Flutter golden tests can't capture them, Flutter theming and
  semantics don't reach them, and each chart adds compositing overhead;
- several breakages in the two current Flutter wrappers (`chartjs_flutter`, `js_widget`): a
  `flutter build web --wasm` build renders an "unsupported" stub, macOS fails at runtime,
  `chartjs_flutter` loads its bundled Chart.js under the wrong asset key, and both load Chart.js
  from an unpinned CDN on at least one platform.

The only genuine port, `chart` (2013-2015), translated Chart.js **0.2** to Dart 1 on `dart:html`
and is unusable today. One author discontinued their wrapper because "Flutter Web is currently fast
enough to handle charts natively".

## Decision

Each library in this repository is ported to Dart and renders through Flutter's own rendering
pipeline (`dart:ui` canvas, Flutter widgets). No WebView, no embedded JavaScript engine and no JS
interop at runtime, on any platform, including web (JS and WebAssembly builds).

Ports follow the upstream source tree module by module (same file split, same names in Dart
case, header comment naming the upstream file) so that upstream releases can be diffed and
replayed, and upstream specs can be ported next to the code.

A dev-time tool is not runtime. A port can use Node.js on the porter's machine or in a CI job, for
example to generate reference data from the pinned upstream source. Nothing in `lib/` or `test/`
loads such a tool.

## Consequences

- Much more work than a wrapper: Chart.js alone is about 20k lines of implementation and 26k lines
  of specs ([parity tracker](../../packages/flutter_chartjs/doc/parity.md)).
- The JavaScript runtime model has to be re-created where upstream relies on it: Canvas 2D
  semantics, `Proxy`-based option resolution, `requestAnimationFrame`, DOM events, CSS fonts and
  colours. These get their own ADRs.
- In return: one rendering path on every Flutter platform, WebAssembly-clean web builds, Dart
  callbacks, Flutter goldens and semantics, and no network or CSP requirements.
