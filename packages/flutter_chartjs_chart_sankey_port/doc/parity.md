# chartjs-chart-sankey parity tracker

This file tracks the port of chartjs-chart-sankey at the release pin `0.19.1`
([Sankey ADR 0001](adr/0001-upstream-sources.md)). The shallow git submodule
`third_party/chartjs-chart-sankey` holds the source. Run `dart run melos run upstream` to clone it.

A person writes this file. Each port change edits it in the same change as the code. The status
unit is one upstream file. The status values are those of the Chart.js port: `not started`,
`in progress`, `partial: <symbols>`, `ported` and `n/a: <reason>`. The column "Seams" gives the
host seams of [host-seams.md](host-seams.md) that the file uses.

## Sources

| Upstream file | Lines | Dart file | Seams | Status |
|---|---:|---|---|---|
| `src/types.ts` | 183 | `lib/src/types.dart` | S10, S14 | ported; the string unions are enums, the node and the data point are classes, and the option interfaces are facades |
| `src/lib/helpers.ts` | 30 | `lib/src/lib/helpers.dart` | none | ported |
| `src/lib/core.ts` | 111 | `lib/src/lib/core.dart` | S7, S10 | ported |
| `src/lib/layout.ts` | 662 | `lib/src/lib/layout.dart` | S7 | ported |
| `src/labels.ts` | 166 | `lib/src/labels.dart` | S10, S18 | ported |
| `src/flow.ts` | 303 | `lib/src/flow.dart` | S3, S5, S6, S12, S14, S17, S18, S19, S21 | ported |
| `src/controller.ts` | 622 | `lib/src/controller.dart` | S1, S2, S4, S8, S10, S11, S16, S20 | ported |
| `src/index.esm.ts` | 21 | `lib/src/index.esm.dart` | S16 | ported |
| `src/index.ts` | 27 | — | S16 | n/a: the entry that registers at its import (Sankey ADR 0002 item 2); an app calls `Chart.register` |
| `src/env.d.ts`, `src/content.config.ts` | 13 | — | none | n/a: the docs site |

## Tests

| Upstream file | Cases | Dart file | Status |
|---|---:|---|---|
| `src/lib/helpers.test.ts` | 18 | `test/specs/lib/helpers_test.dart` | ported; 1 case skips (`defined(null)`: Dart `null` is the JS `undefined` of a typed field) |
| `src/lib/core.test.ts` | 5 | `test/specs/lib/core_test.dart` | ported |
| `src/lib/layout.test.ts` | 37 | `test/specs/lib/layout_test.dart` | ported |
| `src/labels.test.ts` | 4 | `test/specs/labels_test.dart` | ported |
| `src/flow.test.ts` | 3 | `test/specs/flow_test.dart` | ported |
| `src/package.test.ts` | 2 | — | n/a: it tests the npm package file |
| `test/specs/fixtures.spec.js` | 4 and 44 fixtures | `test/specs/fixtures_test.dart` | ported; the 44 fixtures pass with no skip, and each number of their observations equals the number of the JavaScript chart (row `harness-fixture-observations`) |
| `test/specs/node-min-size.spec.js` | 2 | `test/specs/node-min-size_test.dart` | ported |
| `test/specs/node-padding.spec.js` | 3 | `test/specs/node-padding_test.dart` | ported |
| `test/specs/resize.spec.js` | 1 | `test/specs/resize_test.dart` | ported; it reads the progress of the flows, not pixels (row `harness-resize-ink`) |
| `test/specs/runtime-option-updates.spec.js` | 2 | `test/specs/runtime-option-updates_test.dart` | ported |
| `test/setup.js` | — | `test/flutter_test_config.dart` | ported |
| `test/utils/` | — | — | n/a: the image compare and a copy of chartjs-test-utils (Sankey ADR 0002 item 5) |
| `test/integration/`, `test/types/` | — | — | n/a: the npm bundles and the TypeScript declarations |
| `test/fixtures/**/*.js` | 44 | `test/fixtures/hand/**/*.dart` | ported: 25 fixtures and 19 issue fixtures |
