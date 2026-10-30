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
| `src/types.ts` | 15 | `lib/src/types.dart` | none | 2 | not started |
| `src/options.ts` | 209 | `lib/src/options.dart` | H1 | 2 | not started |
| `src/defaults.ts` | 26 | `lib/src/defaults.dart` | none | 2 | not started |
| `src/state.ts` | 65 | `lib/src/state.dart` | H10 | 2 | not started |
| `src/utils.ts` | 111 | `lib/src/utils.dart` | H6, H11, H21 | 2 | not started |
| `src/scale.types.ts` | 288 | `lib/src/scale.types.dart` | H1, H13, H14, H21 | 2 | not started |
| `src/core.ts` | 286 | `lib/src/core.dart` | H1, H13, H14, H15, H21, H22 | 2 | not started |
| `src/handlers.ts` | 322 | `lib/src/handlers.dart` | H1, H2, H3, H4, H5, H6, H7, H11 | 3 | not started |
| `src/gestures.ts` | 395 | `lib/src/gestures.dart` | H1, H3, H4, H6, H7, H8 | 3 | not started |
| `src/plugin.ts` | 152 | `lib/src/plugin.dart` | H9, H12, H16, H17, H19 | 4 | not started |
| `src/index.ts` | 38 | `lib/src/index.dart` | H9, H18 | 4 | not started |
| `src/index.umd.ts` | 6 | `lib/src/index.umd.dart` | H16 | 4 | not started |

`src/utils.ts` uses H6 only for the types of its event parameters: `keyPressed` and
`keyNotPressed` read the modifier flags of an event.

## Tests

| Upstream file | `it` calls | Dart file | Seams | Phase | Status |
|---|---:|---|---|---:|---|
| `src/utils.test.ts` | 1 | `test/specs/utils_test.dart` | none | 2 | not started |
| `src/scale.types.test.ts` | 5 | `test/specs/scale.types_test.dart` | H13 | 2 | not started |
| `test/specs/api.spec.js` | 17 | `test/specs/api_test.dart` | H9, H20 | 2 | not started |
| `test/specs/defaults.spec.js` | 2 | `test/specs/defaults_test.dart` | H16 | 4 | not started |
| `test/specs/module.spec.js` | 4 | `test/specs/module_test.dart` | H16 | 4 | not started |
| `test/specs/zoom.wheel.spec.js` | 10 | `test/specs/zoom.wheel_test.dart` | H23 | 3 | not started |
| `test/specs/zoom.drag.spec.js` | 11 | `test/specs/zoom.drag_test.dart` | H23 | 3 | not started |
| `test/specs/pan.spec.js` | 12 | `test/specs/pan_test.dart` | H23 | 3 | not started |
| `test/specs/zoom.pinch.spec.js` | 4 | `test/specs/zoom.pinch_test.dart` | H23 | 3 | not started |
| `test/specs/gestures.spec.js` | 2 | `test/specs/gestures_test.dart` | H23 | 3 | not started |
| `test/specs/fixtures.spec.js` | 0 | `test/specs/fixtures_test.dart` | H24 | 4 | not started |
| `test/index.js` | — | `test/flutter_test_config.dart` | H3, H6, H7, H23 | 3 | not started |
| `test/fixtures/pan/*.js` (7) | — | `test/fixtures/hand/pan/*.dart` | H24 | 4 | not started |
| `test/fixtures/zoom/*.js` (5) | — | `test/fixtures/hand/zoom/*.dart` | H24 | 4 | not started |

`test/specs/fixtures.spec.js` has no `it` call. It calls `jasmine.fixture.specs('zoom')` and
`jasmine.fixture.specs('pan')`, one case for each fixture.
