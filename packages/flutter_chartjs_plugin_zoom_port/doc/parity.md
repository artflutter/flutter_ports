# chartjs-plugin-zoom parity tracker

This file tracks the port of chartjs-plugin-zoom at the commit pin `2.2.0+fb81d331`
([Zoom ADR 0001](adr/0001-upstream-sources.md)). The shallow git submodule
`third_party/chartjs-plugin-zoom` holds the source. Run `dart run melos run upstream` to clone it.

A person writes this file. Each port change edits it in the same change as the code. The status
unit is one upstream file. The status values are those of the Chart.js port
(`packages/flutter_chartjs_port/doc/porting-flow.md` §1 step 7): `not started`, `in progress`,
`partial: <symbols>` and `ported`. A file that waits for the host has the status
`blocked: host <seam ids>`, with the ids of [host-seams.md](host-seams.md).

The column "Seams" gives the host seams that the file uses. A file can start when each of its
seams is `connects` or `zoom-side`. The column "Phase" gives the roadmap phase of
[README.md](README.md).

## Sources

| Upstream file | Lines | Dart file | Seams | Phase | Status |
|---|---:|---|---|---:|---|
| `src/types.ts` | 15 | `lib/src/types.dart` | none | 2 | ported |
| `src/options.ts` | 209 | `lib/src/options.dart` | H1, H28 | 2 | ported; the facade `ZoomPluginOptions` has the port-only getter `rangeOnlyUpdates` (row `adapt-range-only-updates`) |
| `src/defaults.ts` | 26 | `lib/src/defaults.dart` | none | 2 | ported |
| `src/state.ts` | 65 | `lib/src/state.dart` | H3, H6, H10 | 2 | ported |
| `src/utils.ts` | 111 | `lib/src/utils.dart` | H6, H11, H21, H26 | 2 | ported |
| `src/scale.types.ts` | 288 | `lib/src/scale.types.dart` | H1, H13, H14, H21 | 2 | ported |
| `src/core.ts` | 286 | `lib/src/core.dart` | H1, H13, H14, H15, H21, H22, H26, H28 | 2 | ported; with the port-only option `rangeOnlyUpdates`, the five updates take `chart.updateRanges` (Chart.js ADR 0111, row `adapt-range-only-updates`) |
| `src/handlers.ts` | 322 | `lib/src/handlers.dart` | H1, H2, H3, H4, H5, H6, H7, H11 | 3 | ported |
| `src/gestures.ts` | 395 | `lib/src/gestures.dart` | H1, H3, H4, H6, H7, H8 | 3 | ported |
| `src/plugin.ts` | 152 | `lib/src/plugin.dart` | H9, H12, H16, H17, H19 | 3 | ported |
| `src/index.ts` | 38 | `lib/src/index.dart` | H9, H18 | 3 | ported |
| `src/index.umd.ts` | 6 | — | H16 | 3 | n/a: the UMD bundle (Chart.js ADR 0120, Zoom ADR 0002 item 8); the test set-up registers `zoomPlugin` |

`src/utils.ts` uses H6 only for the types of its event parameters: `keyPressed` and
`keyNotPressed` read the modifier flags of an event. `src/state.ts` uses H3 and H6 for the types
of the listener targets and of the drag events.

`src/options.ts` imports the type `GestureEvent` from `src/gestures.ts`. Thus zoom phase 2 ported
the two public types of `src/gestures.ts`, `GestureEvent` and `ActivePointer`, and phase 3 the
gesture manager.

## Tests

| Upstream file | `it` calls | Dart file | Seams | Phase | Status |
|---|---:|---|---|---:|---|
| `src/utils.test.ts` | 1 | `test/specs/utils_test.dart` | none | 2 | ported |
| `src/scale.types.test.ts` | 5 | `test/specs/scale.types_test.dart` | H13 | 2 | ported |
| `test/specs/api.spec.js` | 17 | `test/specs/api_test.dart` | H9, H14, H20 | 3 | ported |
| `test/specs/defaults.spec.js` | 2 | `test/specs/defaults_test.dart` | H16 | 3 | ported |
| `test/specs/module.spec.js` | 4 | `test/specs/module_test.dart` | H16 | 3 | ported |
| `test/specs/zoom.wheel.spec.js` | 10 | `test/specs/zoom.wheel_test.dart` | H23 | 3 | ported |
| `test/specs/zoom.drag.spec.js` | 11 | `test/specs/zoom.drag_test.dart` | H23 | 3 | ported |
| `test/specs/pan.spec.js` | 12 | `test/specs/pan_test.dart` | H23 | 3 | ported |
| `test/specs/zoom.pinch.spec.js` | 4 | `test/specs/zoom.pinch_test.dart` | H23 | 3 | ported |
| `test/specs/gestures.spec.js` | 2 | `test/specs/gestures_test.dart` | H23 | 3 | ported |
| `test/specs/fixtures.spec.js` | 0 | `test/specs/fixtures_test.dart` | H24 | 4 | ported |
| `test/index.js` | — | `test/flutter_test_config.dart` | H3, H6, H7, H23 | 3 | ported |
| `test/fixtures/pan/*.js` (7) | — | `test/fixtures/hand/pan/*.dart` | H24 | 4 | ported |
| `test/fixtures/zoom/*.js` (5) | — | `test/fixtures/hand/zoom/*.dart` | H24 | 4 | ported |

`test/specs/fixtures.spec.js` has no `it` call. It calls `jasmine.fixture.specs('zoom')` and
`jasmine.fixture.specs('pan')`, one case for each fixture. The port runs the 12 fixtures through
`specsFromFixtures` of the host harness with the tag `fixtures`
(`dart run melos run test:fixtures:zoom`). A fixture compares the ranges of the scales at its
snapshot points with the data of the generator `tool/reference/fixtures_reference.mjs`, not an
image (row `harness-fixture-observations` of [differences.md](differences.md), seam H24).

The `it` calls of the two unit tests in `src/` run in loops: `src/utils.test.ts` has 6 cases and
`src/scale.types.test.ts` has 14 (10 cases of `zoomDelta` and 4 of `panFunctions.category`). The 4
cases of `panFunctions.category` are `testWidgets` cases on the category scale of a real chart
(row `harness-category-scale-fake` of [differences.md](differences.md)). The port-only
`test/support/jasmine.dart` has the Jasmine spies and matchers of the specs, with the
`toBeCloseTo` formula of jasmine-core 5.4.0.

`test/flutter_test_config.dart` has the set-up of `test/index.js` (the device pixel ratio, the
date zone, the built-in components and the plugin, the colors plugin, the restore of the defaults,
the release of the charts and the test font) and its event helpers.

The 83 cases of the eight specs of phase 3 pass, with no skip: `api` 17, `defaults` 2, `module` 4,
`zoom.wheel` 17, `zoom.drag` 25, `pan` 12, `zoom.pinch` 4 and `gestures` 2. Some `it` calls of
`zoom.wheel` and `zoom.drag` run in loops over the four modifier keys, pressed and not pressed. The
port-only `test/port/plugin_test.dart` tests the plugin object on the host: the data-only updates of
a `ChartView` (seam H25), the warnings of `start` (H12, H17) and the range in the scale options
(H14).

Three port-only test files drive a `ChartView` with the pointer and key events of Flutter
(`WidgetTester`), through the input path of the host (Chart.js ADR 0108), where the specs dispatch
synthetic events on the canvas:

- `test/port/handlers_test.dart` (`src/handlers.ts`): a wheel over a chart in a `ListView` zooms
  and does not scroll the list, and `onZoomComplete` runs 250 ms after each wheel event; without
  wheel zoom, the wheel scrolls the list; a mouse drag that leaves the box and lifts outside it
  zooms (the document `mouseup`); a press on the legend starts no drag; Escape cancels a drag with
  no focus on the chart; Enter, Enter on a keyboard target of the chart leaves no drag state.
- `test/port/gestures_test.dart` (`src/gestures.ts`): a one-finger pan with `touch-action: none`
  in a vertical `ListView` pans and does not scroll the list; without pan and pinch, the same drag
  scrolls it; a two-finger pinch zooms both axes on a diagonal and only x in a row.
- `test/port/index_test.dart` (`src/index.ts`): a rebuild with an equal config or with new data
  keeps the zoomed range, a config with another option loses it, and a theme switch loses it (row
  `theme-switch-zoom-range`, seam H20).

`test/port/handlers_smoke_test.dart` tests the listeners of `addListeners` with synthetic events,
`test/port/public_library_test.dart` the public library next to the app library of the host and
Material, and `test/port/plugin_test.dart` the plugin object on the host (above).

The zoom page of `apps/chartjs_gallery` (seam H20) shows samples of the upstream `docs/samples/`
folder, in files with rule-2 headers.

Open after zoom phase 4: the device check of `touch-action: none` (seam H8) on Android and iOS
(Chart.js ADR 0108 Open 1).
