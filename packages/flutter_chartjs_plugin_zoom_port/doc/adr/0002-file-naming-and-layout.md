# Zoom ADR 0002: File naming and package layout

- Status: proposed
- Date: 2026-10-30
- Gate: zoom phase 1, the first ported file. Phase 0 writes the targets of
  `tool/port_sources.yaml` from this ADR.
- Related: [ADR 0009](../../../../docs/adr/0009-add-on-ports.md) (add-on ports),
  [Chart.js ADR 0012](../../../flutter_chartjs_port/doc/adr/0012-dart-file-naming.md) (the file
  names of the host port), [Chart.js ADR 0029](../../../flutter_chartjs_port/doc/adr/0029-fixture-smoke-runner.md)
  (the fixture runner and the hand ports),
  [Chart.js ADR 0048](../../../flutter_chartjs_port/doc/adr/0048-entry-points-and-public-library.md)
  (the entry points and the lazy UMD value), [Zoom ADR 0001](0001-upstream-sources.md) (the pin),
  [Zoom ADR 0003](0003-host-connection.md) (the host connection)

## Context

At the pin of [Zoom ADR 0001](0001-upstream-sources.md), upstream has this layout:

| Upstream path | Files | Role |
|---|---:|---|
| `src/*.ts` | 12 | the plugin: `core`, `defaults`, `gestures`, `handlers`, `index`, `index.umd`, `options`, `plugin`, `scale.types`, `state`, `types`, `utils` |
| `src/*.test.ts` | 2 | unit tests next to the sources: `scale.types.test.ts`, `utils.test.ts` |
| `test/specs/*.spec.js` | 9 | the Jasmine specs |
| `test/fixtures/{pan,zoom}/*.js` | 12 | the fixture configs, each with a PNG image |
| `test/index.js` | 1 | the set-up of the specs and the event helpers |

All upstream names are in lower case. Some have dots, for example `scale.types.ts` and
`zoom.wheel.spec.js`. The `file_names` lint accepts a lower-case name with dots. Thus no file needs
an `ignore_for_file` line.

`src/index.ts` exports the plugin object as the default export, and the functions `pan`, `zoom`,
`zoomRect`, `zoomScale` and `resetZoom`. It also augments the `chart.js` types: the plugin options
`zoom`, the update mode `'zoom'` and ten methods of `Chart`. The upstream docs import the default
export as `zoomPlugin` (`docs/guide/integration.md:19-21`). The UMD build names it `ChartZoom`
(`rollup.config.js:21`), and `src/index.umd.ts` calls `Chart.register(Zoom)` at import time. Dart
has no default export and no import side effect.

## Decision

1. **Sources.** `src/<name>.ts` becomes `lib/src/<name>.dart`, with the upstream spelling, for
   example `lib/src/scale.types.dart`. The package has no subfolder in `lib/src/`, as upstream has
   none.
2. **Unit tests in `src/`.** `src/<name>.test.ts` becomes `test/specs/<name>_test.dart`, for
   example `test/specs/scale.types_test.dart`. File targets in `tool/port_sources.yaml` map them
   before the directory target of `src/`.
3. **Specs.** `test/specs/<name>.spec.js` becomes `test/specs/<name>_test.dart`, for example
   `test/specs/zoom.wheel_test.dart`. The spec names and the skip reasons follow the Chart.js port
   (`porting-flow.md` §1 step 5 of the Chart.js port): `'blocked: <module>'`, `'n/a: <reason>'`
   and `'diverges: <row id>'`.
4. **The test set-up.** `test/index.js` becomes `test/flutter_test_config.dart`. The file holds
   `testExecutable` (the `beforeAll`, `beforeEach` and `afterEach` of upstream) and the helpers
   `triggerWheelEvent`, `dispatchEvent`, `dispatchPointer`, `simulatePan` and `simulatePinch`. A
   spec imports it for the helpers. Thus one upstream file stays one Dart file.
5. **Fixtures.** `test/fixtures/<path>.js` becomes the hand port
   `test/fixtures/hand/<path>.dart`, in the form of Chart.js ADR 0029 §4, with the function
   `fixture()`. The fixture runner of `chartjs_test_utils` runs them with the tag `fixtures`.
6. **Port-only tests.** A test without an upstream source goes in `test/port/`, at the path of
   the `lib/src/` file that it tests.
7. **The public library.** `lib/flutter_chartjs_plugin_zoom_port.dart` is the entry of the
   package. It exports the names of `src/index.ts`:
   - the plugin object, under the Dart name `zoomPlugin`, the name of the upstream docs
   - the functions `pan`, `zoom`, `zoomRect`, `zoomScale` and `resetZoom`
   - the Dart form of the `Chart` methods and of the option types, by
     [Zoom ADR 0003](0003-host-connection.md)
   - `chartjsPluginZoomVersion` and `chartjsPluginZoomPackageVersion`
8. **The UMD entry.** `src/index.umd.ts` becomes `lib/src/index.umd.dart` with a lazy value: its
   first read calls `Chart.register` with the plugin and gives the plugin, as `chartUmd` of the
   Chart.js port (Chart.js ADR 0048 §1). The public library does not export it. An app calls
   `Chart.register([zoomPlugin])`, as the upstream docs do.
9. **The version import.** `src/plugin.ts:18` imports `version` from `package.json`. The Dart
   plugin reads `chartjsPluginZoomPackageVersion` of `lib/src/upstream.dart`.
10. **Headers.** Each ported file starts with
    `// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 <path> (MIT, chartjs-plugin-zoom contributors).`
    A port-only file starts with
    `// Original code, not ported from chartjs-plugin-zoom: <reason>.` A hunk that does not
    translate the upstream lines carries `// DIVERGES(zoom): <row id>, <reason>` and a row in
    `doc/differences.md`.

## Alternatives considered

- **Dart names without dots** (`scale_types.dart`). Rejected. The upstream spelling keeps the
  diff of a bump simple. The lint accepts the dots. The Chart.js port uses the same rule.
- **The unit tests of `src/` in `test/src/`.** Rejected. Upstream runs them with the specs. One
  folder of upstream tests is simpler for tool 5 of the Chart.js port.
- **The helpers of `test/index.js` in a separate library.** Rejected. One upstream file becomes
  two Dart files. `flutter_test_config.dart` is a library that a spec can import.
- **The plugin under the Dart name `chartZoom`** (the UMD name). Rejected. The upstream docs and
  the bundler examples use `zoomPlugin`. The function `zoom` blocks the name `zoom`.

## Consequences

- `tool/port_sources.yaml` maps `src/`, the two `src/*.test.ts` files, `test/specs/`,
  `test/fixtures/` and `test/index.js` by items 1 to 5.
- The first ported file adds the header check of the package (ADR 0009 item 6).
