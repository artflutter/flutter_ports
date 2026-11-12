# Chart.js ADR 0120: The port has no UMD entry

- Status: accepted (2026-11-12): its code and the tests of section Tests pass.
- Date: 2026-11-12
- Supersedes: [Chart.js ADR 0048](0048-entry-points-and-public-library.md) §1 (`lib/src/index.umd.dart` and the lazy
  value `chartUmd`) and §7 (`Chart.platforms` and its `DomPlatform` key), and the rows of §9 for `src/index.umd.ts`.
- Related: Chart.js ADR [0037](0037-legend-and-tooltip-input-path.md) §1 (`platform.flutter.dart` replaces
  `platform.dom.js`), [0108](0108-input-surface-and-exports-for-add-on-plugins.md) (the public libraries of add-on ports), Zoom ADR 0002
  item 8 (revised the same day).

## Context

`src/index.umd.ts` builds the UMD bundle of Chart.js: it registers the four namespaces (:28), writes statics such as
`Chart.helpers`, `Chart.platforms` and `Chart.Ticks` on the class (:30-47), and sets `window.Chart` (:49-51). The specs
of upstream run on that bundle (karma.conf.cjs:110).

The port copied the bundle as `lib/src/index.umd.dart`: the lazy value `chartUmd`, whose first read ran the body. No
public library exported it, no app used it, and only tests read it: the spec `global.namespace`, the spec
`platform.dom` (for `Chart.platforms.DomPlatform`) and a reference test of the keys of the bundle. The zoom port had the
same form, `chartZoom` of its `lib/src/index.umd.dart`. A UMD bundle is a form of JS distribution. Dart has no global
object and no import side effects, and an app imports the public libraries.

## Decision

1. The port has no UMD entry. `lib/src/index.umd.dart`, `chartUmd`, `test/port/index.umd_test.dart`, its data and
   their generator `tool/reference/index_umd_reference.mjs` are gone. So are the zoom `lib/src/index.umd.dart` and
   `chartZoom`.
2. The status of `src/index.umd.ts` is `n/a`. The zoom file `src/index.umd.ts` has no Dart file either.
3. The spec `global.namespace` keeps its case of the constructor (:3-5). Its three cases of the namespace skip with
   `'n/a: the port has no UMD bundle (Chart.js ADR 0120)'`.
4. The spec `platform.dom` takes `FlutterPlatform.jsClass` as `DomPlatform`, with the row
   `platform-dom-platform-class`. The row `platform-umd-entry` is gone, and the row `platform-umd-dom-platform`
   becomes `platform-dom-platform-class`.
5. The test harness keeps its own registration of the built-in components (`harness-register-builtins`). The zoom test
   set-up registers `zoomPlugin` with `Chart.register`, and the zoom spec `module` reads `zoomPlugin`.

## Consequences

- `Chart.jsClass` keeps the statics of `core.controller.js:105-120`, and no code writes the statics of
  `src/index.umd.ts:30-47` into it.
- An upstream bump still compares `src/index.umd.ts`: a change there can change the registration order that the
  harness copies.

## Tests

- `test/specs/global.namespace_test.dart` and `test/specs/platform.dom_test.dart`.
- `packages/flutter_chartjs_plugin_zoom_port/test/specs/module_test.dart` and the zoom specs and fixtures, which run
  with the plugin that `test/flutter_test_config.dart` registers.
- `test/tool/check_lib_imports_test.dart`: the widget rule without the UMD file.
