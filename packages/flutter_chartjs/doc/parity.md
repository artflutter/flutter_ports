# Chart.js parity tracker

One row per upstream source file of [Chart.js v4.5.1](https://github.com/chartjs/Chart.js/tree/v4.5.1)
(the pinned `third_party/Chart.js` submodule; run `melos run upstream` to check it out).
Port work updates the **Dart target** and **Status** columns in the same PR as the code.

Status values ([porting-flow.md](porting-flow.md) §1 step 7):

- `not started`: no Dart code yet.
- `in progress`: Dart code exists, but not all of the module is ported.
- `partial: <symbols>`: only the listed symbols are ported, because a ported module needs them.
- `ported`: code + ported specs pass; for a pure-layer module, on the VM, dart2js and dart2wasm.
  This is the last status of a module. The port has no `verified` status
  ([Chart.js ADR 0009](adr/0009-no-display-only-js-exactness.md)).
- `replaced`: a Flutter file replaces the upstream file, for example `platform.flutter.dart` for
  `platform.dom.js`.
- `distributed`: a type declaration file mirrored as `abstract interface class` declarations in
  `lib/src/types`, with members added as ported callers need them (porting-flow.md §2.4).
- `n/a: <reason>`: not ported, for the stated reason.

Line counts are `wc -l` of the upstream file at v4.5.1.

## Summary

The Ported column counts the rows with the status `ported`. It does not count `partial` rows. It
does not count `distributed` rows. The types area has 6 `distributed` rows. The last two rows
count the [Upstream tests](#upstream-tests) specs and the [@kurkle/color 0.3.2](#kurklecolor-032)
files.

| Area | Files | Lines | Ported |
|---|---:|---:|---:|
| helpers | 18 | 3435 | 14 |
| core | 21 | 7135 | 5 |
| elements | 5 | 1203 | 0 |
| scales | 8 | 2290 | 0 |
| controllers | 9 | 1935 | 0 |
| plugins | 15 | 3499 | 0 |
| platform | 4 | 508 | 0 |
| types | 7 | 4070 | 0 |
| entry points | 3 | 133 | 0 |
| upstream specs | 54 | 25962 | 14 |
| @kurkle/color | 11 | 1126 | 10 |

Runtime dependency: [`@kurkle/color`](https://github.com/kurkle/color) `^0.3.0` (MIT, Jukka Kurkela), resolved to **0.3.2** in the v4.5.1 `pnpm-lock.yaml`. It is wrapped by `src/helpers/helpers.color.ts`, parses and mixes CSS colours. The port of 0.3.2 is in `lib/src/kurkle_color/`. See [@kurkle/color 0.3.2](#kurklecolor-032).

## Helpers (`src/helpers`)

| Upstream file | Lines | Dart target | Status |
|---|---:|---|---|
| [`src/helpers/helpers.canvas.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/helpers.canvas.ts) | 527 | `lib/src/helpers/helpers.canvas.dart` | partial: `toFontString`, `_isPointInArea` (differences: 1 `adapt`, [differences.md](differences.md#adapt-point-in-area-bool)) |
| [`src/helpers/helpers.collection.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/helpers.collection.ts) | 192 | `lib/src/helpers/helpers.collection.dart` | ported (differences: 1 `platform`, [differences.md](differences.md#platform-array-events)) |
| [`src/helpers/helpers.color.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/helpers.color.ts) | 32 | `lib/src/helpers/helpers.color.dart` | ported (differences: 1 `platform`, [differences.md](differences.md#platform-color-brand)) |
| [`src/helpers/helpers.config.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/helpers.config.ts) | 456 | `lib/src/helpers/helpers.config.dart` | ported (differences: 1 `adapt`, 1 `js-semantics`, [differences.md](differences.md#adapt-resolver-cached-read), [differences.md](differences.md#js-semantics-resolver-objects)) |
| [`src/helpers/helpers.config.types.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/helpers.config.types.ts) | 60 | `lib/src/helpers/helpers.config.types.dart` | ported |
| [`src/helpers/helpers.core.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/helpers.core.ts) | 416 | `lib/src/helpers/helpers.core.dart` | ported (differences: 3 `js-semantics`, [differences.md](differences.md#js-semantics-to-upper-case), [differences.md](differences.md#js-semantics-set-equality), [differences.md](differences.md#js-semantics-resolver-cache)) |
| [`src/helpers/helpers.curve.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/helpers.curve.ts) | 223 | `lib/src/helpers/helpers.curve.dart` | ported |
| [`src/helpers/helpers.dataset.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/helpers.dataset.ts) | 33 | `lib/src/helpers/helpers.dataset.dart` | ported |
| [`src/helpers/helpers.dom.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/helpers.dom.ts) | 284 | | not started |
| [`src/helpers/helpers.easing.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/helpers.easing.ts) | 124 | `lib/src/helpers/helpers.easing.dart` | ported (differences: 1 `js-semantics`, [differences.md](differences.md#js-semantics-dart-math)) |
| [`src/helpers/helpers.extras.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/helpers.extras.ts) | 163 | `lib/src/helpers/helpers.extras.dart` | ported (differences: 2 `platform`, 1 `js-semantics`, [differences.md](differences.md#platform-request-anim-frame), [differences.md](differences.md#platform-debounce-cancel), [differences.md](differences.md#js-semantics-debounce-args)) |
| [`src/helpers/helpers.interpolation.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/helpers.interpolation.ts) | 41 | `lib/src/helpers/helpers.interpolation.dart` | ported |
| [`src/helpers/helpers.intl.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/helpers.intl.ts) | 17 | `lib/src/helpers/helpers.intl.dart` | ported (differences: 1 `adapt`, [differences.md](differences.md#adapt-intl-number-format)) |
| [`src/helpers/helpers.math.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/helpers.math.ts) | 207 | `lib/src/helpers/helpers.math.dart` | ported |
| [`src/helpers/helpers.options.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/helpers.options.ts) | 206 | `lib/src/helpers/helpers.options.dart` | ported (differences: 2 `adapt`, [differences.md](differences.md#adapt-options-typed-results), [differences.md](differences.md#adapt-create-context-prototype)) |
| [`src/helpers/helpers.rtl.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/helpers.rtl.ts) | 74 | `lib/src/helpers/helpers.rtl.dart` | in progress: `RTLAdapter` and `getRtlAdapter` are ported. `overrideTextDirection` and `restoreTextDirection` set the direction of the canvas. They wait for the canvas layer of phase 3 |
| [`src/helpers/helpers.segment.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/helpers.segment.js) | 364 | `lib/src/helpers/helpers.segment.dart` | ported (differences: 1 `js-semantics`, [differences.md](differences.md#js-semantics-segment-style-json)) |
| [`src/helpers/index.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/index.ts) | 16 | | not started: it re-exports `helpers.dom` and all of `helpers.canvas`. Phase 3 ports it |

## Core (`src/core`)

| Upstream file | Lines | Dart target | Status |
|---|---:|---|---|
| [`src/core/core.adapters.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.adapters.ts) | 138 | | not started |
| [`src/core/core.animation.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.animation.js) | 119 | | not started |
| [`src/core/core.animations.defaults.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.animations.defaults.js) | 72 | `lib/src/core/core.animations.defaults.dart` | ported |
| [`src/core/core.animations.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.animations.js) | 162 | | not started |
| [`src/core/core.animator.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.animator.js) | 214 | | not started |
| [`src/core/core.config.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.config.js) | 418 | | not started |
| [`src/core/core.controller.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.controller.js) | 1269 | | not started |
| [`src/core/core.datasetController.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.datasetController.js) | 1077 | | not started |
| [`src/core/core.defaults.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.defaults.js) | 175 | `lib/src/core/core.defaults.dart` | ported (differences: 2 `adapt`, [differences.md](differences.md#adapt-defaults-route), [differences.md](differences.md#adapt-defaults-scope-object)) |
| [`src/core/core.element.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.element.ts) | 45 | | not started |
| [`src/core/core.interaction.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.interaction.js) | 387 | | not started |
| [`src/core/core.layouts.defaults.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.layouts.defaults.js) | 11 | `lib/src/core/core.layouts.defaults.dart` | ported |
| [`src/core/core.layouts.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.layouts.js) | 455 | | not started |
| [`src/core/core.plugins.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.plugins.js) | 188 | | not started |
| [`src/core/core.registry.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.registry.js) | 186 | | not started |
| [`src/core/core.scale.autoskip.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.scale.autoskip.js) | 170 | | not started |
| [`src/core/core.scale.defaults.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.scale.defaults.js) | 105 | `lib/src/core/core.scale.defaults.dart` | ported |
| [`src/core/core.scale.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.scale.js) | 1710 | | not started |
| [`src/core/core.ticks.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.ticks.js) | 102 | `lib/src/core/core.ticks.dart` | ported |
| [`src/core/core.typedRegistry.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.typedRegistry.js) | 117 | | not started |
| [`src/core/index.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/index.ts) | 15 | | not started |

## Elements (`src/elements`)

| Upstream file | Lines | Dart target | Status |
|---|---:|---|---|
| [`src/elements/element.arc.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/elements/element.arc.ts) | 421 | | not started |
| [`src/elements/element.bar.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/elements/element.bar.js) | 226 | | not started |
| [`src/elements/element.line.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/elements/element.line.js) | 445 | | not started |
| [`src/elements/element.point.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/elements/element.point.ts) | 107 | | not started |
| [`src/elements/index.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/elements/index.js) | 4 | | not started |

## Scales (`src/scales`)

| Upstream file | Lines | Dart target | Status |
|---|---:|---|---|
| [`src/scales/index.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/scales/index.js) | 6 | | not started |
| [`src/scales/scale.category.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/scales/scale.category.js) | 158 | | not started |
| [`src/scales/scale.linear.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/scales/scale.linear.js) | 51 | | not started |
| [`src/scales/scale.linearbase.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/scales/scale.linearbase.js) | 313 | | not started |
| [`src/scales/scale.logarithmic.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/scales/scale.logarithmic.js) | 226 | | not started |
| [`src/scales/scale.radialLinear.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/scales/scale.radialLinear.js) | 684 | | not started |
| [`src/scales/scale.time.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/scales/scale.time.js) | 675 | | not started |
| [`src/scales/scale.timeseries.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/scales/scale.timeseries.js) | 177 | | not started |

## Dataset controllers (`src/controllers`)

| Upstream file | Lines | Dart target | Status |
|---|---:|---|---|
| [`src/controllers/controller.bar.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/controllers/controller.bar.js) | 682 | | not started |
| [`src/controllers/controller.bubble.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/controllers/controller.bubble.js) | 169 | | not started |
| [`src/controllers/controller.doughnut.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/controllers/controller.doughnut.js) | 399 | | not started |
| [`src/controllers/controller.line.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/controllers/controller.line.js) | 143 | | not started |
| [`src/controllers/controller.pie.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/controllers/controller.pie.js) | 24 | | not started |
| [`src/controllers/controller.polarArea.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/controllers/controller.polarArea.js) | 227 | | not started |
| [`src/controllers/controller.radar.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/controllers/controller.radar.js) | 104 | | not started |
| [`src/controllers/controller.scatter.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/controllers/controller.scatter.js) | 179 | | not started |
| [`src/controllers/index.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/controllers/index.js) | 8 | | not started |

## Plugins (`src/plugins`)

| Upstream file | Lines | Dart target | Status |
|---|---:|---|---|
| [`src/plugins/index.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/plugins/index.js) | 7 | | not started |
| [`src/plugins/plugin.colors.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/plugins/plugin.colors.ts) | 127 | | not started |
| [`src/plugins/plugin.decimation.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/plugins/plugin.decimation.js) | 287 | | not started |
| [`src/plugins/plugin.filler/filler.drawing.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/plugins/plugin.filler/filler.drawing.js) | 187 | | not started |
| [`src/plugins/plugin.filler/filler.helper.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/plugins/plugin.filler/filler.helper.js) | 38 | | not started |
| [`src/plugins/plugin.filler/filler.options.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/plugins/plugin.filler/filler.options.js) | 137 | | not started |
| [`src/plugins/plugin.filler/filler.segment.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/plugins/plugin.filler/filler.segment.js) | 99 | | not started |
| [`src/plugins/plugin.filler/filler.target.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/plugins/plugin.filler/filler.target.js) | 95 | | not started |
| [`src/plugins/plugin.filler/filler.target.stack.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/plugins/plugin.filler/filler.target.stack.js) | 109 | | not started |
| [`src/plugins/plugin.filler/index.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/plugins/plugin.filler/index.js) | 97 | | not started |
| [`src/plugins/plugin.filler/simpleArc.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/plugins/plugin.filler/simpleArc.js) | 27 | | not started |
| [`src/plugins/plugin.legend.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/plugins/plugin.legend.js) | 720 | | not started |
| [`src/plugins/plugin.subtitle.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/plugins/plugin.subtitle.js) | 53 | | not started |
| [`src/plugins/plugin.title.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/plugins/plugin.title.js) | 166 | | not started |
| [`src/plugins/plugin.tooltip.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/plugins/plugin.tooltip.js) | 1350 | | not started |

## Platform (`src/platform`)

| Upstream file | Lines | Dart target | Status |
|---|---:|---|---|
| [`src/platform/index.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/platform/index.js) | 13 | | not started |
| [`src/platform/platform.base.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/platform/platform.base.js) | 83 | | not started |
| [`src/platform/platform.basic.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/platform/platform.basic.js) | 23 | | not started |
| [`src/platform/platform.dom.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/platform/platform.dom.js) | 389 | | not started |

## Type declarations (`src/types`)

| Upstream file | Lines | Dart target | Status |
|---|---:|---|---|
| [`src/types/animation.d.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/types/animation.d.ts) | 34 | `lib/src/types/animation.dart` | distributed |
| [`src/types/basic.d.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/types/basic.d.ts) | 3 | `lib/src/types/basic.dart` | distributed |
| [`src/types/color.d.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/types/color.d.ts) | 1 | `lib/src/types/color.dart` | distributed |
| [`src/types/geometric.d.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/types/geometric.d.ts) | 52 | `lib/src/types/geometric.dart` | distributed |
| [`src/types/index.d.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/types/index.d.ts) | 3885 | `lib/src/types/index.dart` | distributed |
| [`src/types/layout.d.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/types/layout.d.ts) | 65 | `lib/src/types/layout.dart` | distributed |
| [`src/types/utils.d.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/types/utils.d.ts) | 30 | | n/a: TypeScript type operators (`DeepPartial`, `Merge` and others). Dart has no form for them. |

## Entry points

| Upstream file | Lines | Dart target | Status |
|---|---:|---|---|
| [`src/index.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/index.ts) | 25 | | not started |
| [`src/index.umd.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/index.umd.ts) | 54 | | not started |
| [`src/types.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/types.ts) | 54 | | not started |

## Upstream tests

Upstream tests come in two kinds. Both are ported with the module they cover.

- **Specs** (`test/specs`, Jasmine): 54 files, 25,962 lines. They mostly check computed state (scale ticks, element positions, resolved options) and the recorded canvas calls, so they translate to `flutter_test` unit tests.
- **Image fixtures** (`test/fixtures`): 1,324 files, of which 662 are PNG reference renders produced by Chrome/Firefox. The port compares no image with these PNGs ([Chart.js ADR 0009](adr/0009-no-display-only-js-exactness.md)). The fixture configs can run as smoke tests. A smoke test passes when one frame renders with no exception.

| Upstream spec | Lines | Dart test | Status |
|---|---:|---|---|
| [`test/specs/controller.bar.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/controller.bar.tests.js) | 1853 | | not started |
| [`test/specs/controller.bubble.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/controller.bubble.tests.js) | 426 | | not started |
| [`test/specs/controller.doughnut.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/controller.doughnut.tests.js) | 447 | | not started |
| [`test/specs/controller.line.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/controller.line.tests.js) | 1206 | | not started |
| [`test/specs/controller.polarArea.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/controller.polarArea.tests.js) | 396 | | not started |
| [`test/specs/controller.radar.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/controller.radar.tests.js) | 455 | | not started |
| [`test/specs/controller.scatter.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/controller.scatter.tests.js) | 205 | | not started |
| [`test/specs/core.animation.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/core.animation.tests.js) | 86 | | not started |
| [`test/specs/core.animations.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/core.animations.tests.js) | 175 | | not started |
| [`test/specs/core.animator.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/core.animator.tests.js) | 48 | | not started |
| [`test/specs/core.controller.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/core.controller.tests.js) | 2339 | | not started |
| [`test/specs/core.datasetController.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/core.datasetController.tests.js) | 1310 | | not started |
| [`test/specs/core.defaults.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/core.defaults.tests.js) | 38 | `test/specs/core.defaults_test.dart` | ported (3/3 cases) |
| [`test/specs/core.element.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/core.element.tests.js) | 16 | | not started |
| [`test/specs/core.helpers.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/core.helpers.tests.js) | 24 | `test/specs/core.helpers_test.dart` | ported (2/2 cases) |
| [`test/specs/core.interaction.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/core.interaction.tests.js) | 1025 | | not started |
| [`test/specs/core.layouts.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/core.layouts.tests.js) | 572 | | not started |
| [`test/specs/core.plugin.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/core.plugin.tests.js) | 510 | | not started |
| [`test/specs/core.registry.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/core.registry.tests.js) | 269 | | not started |
| [`test/specs/core.scale.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/core.scale.tests.js) | 820 | | not started |
| [`test/specs/core.ticks.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/core.ticks.tests.js) | 110 | `test/specs/core.ticks_test.dart` | ported (2/4 cases pass; 2 cases skipped, `blocked: core.controller`: they call `acquireChart`) |
| [`test/specs/element.arc.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/element.arc.tests.js) | 306 | | not started |
| [`test/specs/element.bar.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/element.bar.tests.js) | 67 | | not started |
| [`test/specs/element.line.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/element.line.tests.js) | 35 | | not started |
| [`test/specs/element.point.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/element.point.tests.js) | 69 | | not started |
| [`test/specs/global.defaults.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/global.defaults.tests.js) | 198 | | not started |
| [`test/specs/global.namespace.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/global.namespace.tests.js) | 39 | | not started |
| [`test/specs/helpers.canvas.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/helpers.canvas.tests.js) | 355 | `test/specs/helpers.canvas_test.dart` | ported (2/14 cases pass; 2 cases skipped, `blocked: core.controller`: they call `acquireChart`; 10 cases skipped, `blocked: helpers.canvas`: they need the canvas layer of phase 3) |
| [`test/specs/helpers.collection.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/helpers.collection.tests.js) | 46 | `test/specs/helpers.collection_test.dart` | ported (5/5 cases) |
| [`test/specs/helpers.color.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/helpers.color.tests.js) | 47 | `test/specs/helpers.color_test.dart` | ported (2/4 cases pass; 2 cases skipped, `blocked: helpers.canvas`: they need a canvas pattern and gradient) |
| [`test/specs/helpers.config.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/helpers.config.tests.js) | 877 | `test/specs/helpers.config_test.dart` | ported (31/31 cases; differences: 1 `js-semantics`, [differences.md](differences.md#js-semantics-resolver-objects)) |
| [`test/specs/helpers.core.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/helpers.core.tests.js) | 509 | `test/specs/helpers.core_test.dart` | ported (53/53 cases; differences: 1 `js-semantics`, [differences.md](differences.md#js-semantics-strict-this)) |
| [`test/specs/helpers.curve.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/helpers.curve.tests.js) | 183 | `test/specs/helpers.curve_test.dart` | ported (2/2 cases) |
| [`test/specs/helpers.dom.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/helpers.dom.tests.js) | 548 | | not started |
| [`test/specs/helpers.easing.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/helpers.easing.tests.js) | 61 | `test/specs/helpers.easing_test.dart` | ported (31/31 cases; differences: 1 `js-semantics`, [differences.md](differences.md#js-semantics-dart-math)) |
| [`test/specs/helpers.interpolation.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/helpers.interpolation.tests.js) | 35 | `test/specs/helpers.interpolation_test.dart` | ported (3/3 cases) |
| [`test/specs/helpers.math.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/helpers.math.tests.js) | 141 | `test/specs/helpers.math_test.dart` | ported (12/12 cases) |
| [`test/specs/helpers.options.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/helpers.options.tests.js) | 256 | `test/specs/helpers.options_test.dart` | ported (29/29 cases) |
| [`test/specs/helpers.segment.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/helpers.segment.tests.js) | 61 | `test/specs/helpers.segment_test.dart` | ported (11/11 cases) |
| [`test/specs/mixed.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/mixed.tests.js) | 46 | | not started |
| [`test/specs/platform.basic.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/platform.basic.tests.js) | 100 | | not started |
| [`test/specs/platform.dom.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/platform.dom.tests.js) | 432 | | not started |
| [`test/specs/plugin.colors.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/plugin.colors.tests.js) | 37 | | not started |
| [`test/specs/plugin.decimation.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/plugin.decimation.tests.js) | 219 | | not started |
| [`test/specs/plugin.filler.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/plugin.filler.tests.js) | 299 | | not started |
| [`test/specs/plugin.legend.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/plugin.legend.tests.js) | 1185 | | not started |
| [`test/specs/plugin.subtitle.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/plugin.subtitle.tests.js) | 3 | | not started |
| [`test/specs/plugin.title.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/plugin.title.tests.js) | 358 | | not started |
| [`test/specs/plugin.tooltip.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/plugin.tooltip.tests.js) | 1951 | | not started |
| [`test/specs/scale.category.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/scale.category.tests.js) | 571 | | not started |
| [`test/specs/scale.linear.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/scale.linear.tests.js) | 1398 | | not started |
| [`test/specs/scale.logarithmic.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/scale.logarithmic.tests.js) | 1208 | | not started |
| [`test/specs/scale.radialLinear.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/scale.radialLinear.tests.js) | 656 | | not started |
| [`test/specs/scale.time.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/scale.time.tests.js) | 1336 | | not started |

## @kurkle/color 0.3.2

The Chart.js runtime dependency [`@kurkle/color`](https://github.com/kurkle/color/tree/v0.3.2)
(MIT, Jukka Kurkela). The pinned `third_party/kurkle-color` submodule holds the source.
`tool/port_sources.yaml` maps each file. Each Dart file starts with
`// Ported from @kurkle/color v0.3.2 <path> (MIT, Jukka Kurkela).` Ported code imports
`index.esm.dart`, because the ES module build of the package starts from `src/index.esm.js`.

| Upstream file | Lines | Dart target | Status |
|---|---:|---|---|
| [`src/byte.js`](https://github.com/kurkle/color/blob/v0.3.2/src/byte.js) | 54 | `lib/src/kurkle_color/byte.dart` | ported |
| [`src/color.js`](https://github.com/kurkle/color/blob/v0.3.2/src/color.js) | 302 | `lib/src/kurkle_color/color.dart` | ported (differences: 1 `adapt`, [differences.md](differences.md#adapt-kurkle-rgba)) |
| [`src/hex.js`](https://github.com/kurkle/color/blob/v0.3.2/src/hex.js) | 83 | `lib/src/kurkle_color/hex.dart` | ported |
| [`src/hue.js`](https://github.com/kurkle/color/blob/v0.3.2/src/hue.js) | 229 | `lib/src/kurkle_color/hue.dart` | ported |
| [`src/index.esm.js`](https://github.com/kurkle/color/blob/v0.3.2/src/index.esm.js) | 31 | `lib/src/kurkle_color/index.esm.dart` | ported |
| [`src/index.js`](https://github.com/kurkle/color/blob/v0.3.2/src/index.js) | 8 | | n/a: the UMD entry. It attaches the exports to the default function, and a Dart function has no properties. Ported code imports `index.esm.dart`. |
| [`src/names.js`](https://github.com/kurkle/color/blob/v0.3.2/src/names.js) | 30 | `lib/src/kurkle_color/names.dart` | ported (differences: 1 `adapt`, [differences.md](differences.md#adapt-kurkle-names-proto)) |
| [`src/rgb.js`](https://github.com/kurkle/color/blob/v0.3.2/src/rgb.js) | 62 | `lib/src/kurkle_color/rgb.dart` | ported |
| [`src/srgb.js`](https://github.com/kurkle/color/blob/v0.3.2/src/srgb.js) | 26 | `lib/src/kurkle_color/srgb.dart` | ported (differences: 1 `js-semantics`, [differences.md](differences.md#js-semantics-dart-math)) |
| [`packed.js`](https://github.com/kurkle/color/blob/v0.3.2/packed.js) | 196 | `lib/src/kurkle_color/packed.dart` | ported |
| [`test/index.js`](https://github.com/kurkle/color/blob/v0.3.2/test/index.js) | 105 | `test/kurkle_color/index_test.dart` | ported (83/83 asserts pass, one test for each assert) |

## Port-only files

Files with no Chart.js counterpart. Each file starts with
`// Original code, not ported from Chart.js: <reason>.`, except the fdlibm ports, which have
the rule-2 headers of their own source. The fdlibm reference copies are in `third_party/fdlibm/`.
The reference engine of `lib/src/js` is V8 13.6 in Node.js v24.12.0 on x64
([Chart.js ADR 0010](adr/0010-js-numeric-semantics.md)).

| File | Contents | Tests |
|---|---|---|
| `lib/src/js/js_math.dart` | `Math` and `Number` builtins with the results of the reference engine: `numberEpsilon`, `jsRound`, `jsToInt32`, `jsMax`, `jsMin`, `jsSquare`, `jsLog10`, `jsAtan2`. `jsSquare(x)` is `Math.pow(x, 2)`: `x * x` (Chart.js ADR 0010). `jsMax` and `jsMin` are `Math.max` and `Math.min` for `double` operands (Chart.js ADR 0010). On dart2wasm they compare the operands in their own code (`jsMaxMinCompare`), because the generic `dart:math` `max` and `min` box `double` operands there. On the VM and dart2js they call `dart:math`. Ported code calls `dart:math` `sin`, `cos` and `pow` (Chart.js ADR 0010) | `test/port/js/js_math_test.dart`: `jsMax` and `jsMin` against `dart:math` `max` and `min`, bit for bit, over a grid of 40 operands in both orders (signed zeros, NaN, infinities, subnormals, random finites), and which code each test leg runs. It also pins `dart:math` `max` and `min` against the JS results, and `jsSquare` against `dart:math` `pow(x, 2.0)`, bit for bit, over the grid, overflow values near 1.4e154 and 20,000 seeded random bit patterns |
| `lib/src/js/js_number.dart` | The JS coercions: `jsToNumber`, `jsParseFloat`, `jsIsNaN`, `jsIsFinite`, `jsTruthy` (ToBoolean), `jsToString` (ToString) and `jsNumberToString` (Number::toString, radix 10) | `test/port/js/js_number_test.dart`: also 10,000 inputs of `jsNumberToString`, string for string against `String(x)` of the reference engine, and `jsToNumber` of each string of 0-5 characters from `0-9 . + - e E` (0-3 characters and a sample on the web) against a `StrDecimalLiteral` oracle, bit for bit |
| `lib/src/js/js_undefined.dart` | The JS value `undefined` as a value: `Undefined` and its one instance `undefined` (Chart.js ADR 0006, "The sentinel") | `test/port/js/js_number_test.dart`, `test/port/js/js_array_test.dart` |
| `lib/src/js/js_function.dart` | The JS call of a function value: `JsFunction` (a closure that gets `this` as its first parameter), `jsIsFunction` (`typeof value === 'function'`), `jsCall` (drops the extra arguments, pads the missing required arguments with `undefined`, passes `this` to a `JsFunction` only), `jsCall1` (`jsCall` with one argument, without the argument list on the VM) and `jsMaxArity`. On the VM, `jsCall` calls a closure that takes 0 to 4 arguments with a dynamic call, because `Function.apply` is about 10 times slower there. It uses `Function.apply` for 5 to 8 arguments and on the web. Its library documentation states the convention for users | `test/port/js/js_function_test.dart`: each arity from 0 to 8 with 0 to 10 arguments, with and without `this`, on both sides of the dynamic-call limit. `jsCall1` gives the `jsCall` results and errors for each arity, `this`, NaN, -0, `null` and `undefined` |
| `lib/src/js/js_object.dart` | The JS property read `object[key]`: `jsGet`. It gives the `get` trap of a resolver, the value of a Map key or `undefined` for an absent key, the canonical indices and the `length` of a List or a String, and `undefined` for other values. It throws a `TypeError` for `null` and `undefined`. The ported modules call it in place of their private copies. `jsGet` carries the marker of the `differences.md` row [`js-semantics-resolver-objects`](differences.md#js-semantics-resolver-objects): it knows only Map, List and String values | `test/port/js/js_object_test.dart`, with expected values from the reference engine |
| `test/port/helpers/helpers.core_test.dart` | `helpers.core` behavior that `test/specs/helpers.core.tests.js` does not check (AGENTS.md rule 3), with expected values from `src/helpers/helpers.core.ts` in Node.js v24.12.0 on x64. One test pins a port difference of Chart.js ADR 0006: a class instance is not an object. The groups `js-semantics-resolver-cache`, `js-semantics-to-upper-case` and `js-semantics-set-equality` pin the `differences.md` rows of the same names | — |
| `test/port/helpers/helpers.config_test.dart` | `helpers.config` behavior that `test/specs/helpers.config.tests.js` does not check (AGENTS.md rule 3). The group `null versus undefined` holds the resolver tests of Chart.js ADR 0006: for the plain, prefixed, `_fallback`, scriptable, indexable, `_cached`, sub-resolver, key enumeration, set and descriptor paths, an absent key and the `undefined` sentinel resolve alike, and `null` stops the resolution. One group shows that a stored sentinel blocks `mergeIf`. Other groups cover array scopes, `Object.keys` of a resolver through `jsObjectKeys` (also in `each`, `clone` and `merge`), `resolveObjectKey` of a prefixed resolver, a delete on a frozen scope, the `this` of the descriptor functions and `_parseObjectDataRadialScale`. The groups `adapt-resolver-cached-read` and `js-semantics-resolver-objects` pin the `differences.md` rows of the same names. The expected values come from `src/helpers/helpers.config.ts` and `src/helpers/helpers.core.ts` in Node.js v24.12.0 on x64 | — |
| `lib/src/js/js_array.dart` | `Array.prototype.sort` and `Object.keys`: `jsSort` (stable `mergeSort`, comparator sign, Chart.js ADR 0010) and `jsObjectKeys` (array-index keys first). `jsArrayIndex` is the one canonical array-index parser. `jsObjectKeys`, `jsGet` and the `in` test of `helpers.config` use it. `JsProxyObject` is a JS `Proxy` as a `Map`: the resolvers of `helpers.config` implement it, and `jsObjectKeys` and `jsGet` call its traps (Chart.js ADR 0006) | `test/port/js/js_array_test.dart`, with expected values from the reference engine |
| `test/port/js/number_to_string_reference.dart` | Generated data of `js_number_test.dart` | written by `tool/reference/number_to_string_reference.mjs` |
| `tool/reference/number_to_string_reference.mjs` | Dev-time Node.js generator of `number_to_string_reference.dart`. It stops unless Node.js is an x64 build | — |
| `lib/src/js/js_intl.dart` | `Intl.NumberFormat` on the `NumberFormat` of package:intl (Chart.js ADR 0008): `jsNumberFormat` (the option mapping, a `JsNumberFormat` with guards against package:intl failures), `maxFractionDigits` (the cap of 15 fraction digits that the guards give to package:intl), `jsNumberFormatLocale` (BCP 47 tag or tag list to intl locale, the current intl locale for `undefined`). The strings are the package:intl strings, not the V8 strings | `test/port/js/js_intl_test.dart`: the option and locale mapping against V8 strings of the reference engine, and the pinned differences from V8, per platform where dart2js differs. `test/port/js/js_intl_default_locale_test.dart` (VM only, it imports package:intl): `Intl.defaultLocale` and the formatter cache |
| `test/port/helpers/helpers.intl_test.dart` | The `helpers.intl` tests: upstream has no `helpers.intl` spec (AGENTS.md rule 3). The cache, and the `formatNumber` calls behind the labels of `core.ticks.tests.js` and the linear, logarithmic and radial linear scale specs, against V8 strings of the reference engine | — |
| `test/port/helpers/helpers.rtl_test.dart` | The `helpers.rtl` tests: upstream has no `helpers.rtl` spec (AGENTS.md rule 3). The expected values come from `helpers.rtl.ts` in Node.js v24.12.0 on x64 | — |
| `test/port/helpers/helpers.extras_test.dart` | The `helpers.extras` tests: upstream has no `helpers.extras` spec (AGENTS.md rule 3). The file has `@TestOn('vm')`, because `helpers.extras` imports `package:flutter/scheduler.dart` (Chart.js ADR 0007, decision 10). It covers the six pure exports with expected values from the chart.js 4.5.1 npm dist in Node.js v24.12.0 on x64. `testWidgets` tests with `tester.pump` cover `requestAnimFrame`, `throttled` and `debounce`. The groups `platform-request-anim-frame`, `js-semantics-debounce-args` and `platform-debounce-cancel` pin the `differences.md` rows of the same names (Chart.js ADR 0007, decision 11) | — |
| `lib/src/js/fdlibm_log.dart` | Ported from fdlibm 5.3 `e_log.c` and `e_log10.c` (SunPro, Sun Microsystems, Inc.): `ieee754Log`, `ieee754Log10` | `test/port/js/fdlibm_log_test.dart`: 5,909 inputs and 3 regression inputs, bit for bit against `Math.log10` of the reference engine |
| `lib/src/js/fdlibm_atan.dart` | Ported from fdlibm 5.3 `s_atan.c` and `e_atan2.c` (SunPro, Sun Microsystems, Inc.), plus one line that V8 has and netlib does not (`m &= 1` when abs(y/x) > 2**60): `atan`, `ieee754Atan2` | `test/port/js/fdlibm_atan_test.dart`: 3,000 inputs, bit for bit against `Math.atan2` of the reference engine |
| `test/port/js/log10_reference.dart` | Generated data of `fdlibm_log_test.dart` | written by `tool/reference/log10_reference.mjs` |
| `test/port/js/atan2_reference.dart` | Generated data of `fdlibm_atan_test.dart` | written by `tool/reference/atan2_reference.mjs` |
| `tool/reference/log10_reference.mjs`, `tool/reference/atan2_reference.mjs` | Dev-time Node.js generators of the two data files. They stop unless Node.js is an x64 build | — |
| `test/port/helpers/helpers.dataset_test.dart` | The `helpers.dataset` tests: upstream has no `helpers.dataset` spec (AGENTS.md rule 3). The expected values come from the upstream `helpers.dataset.ts` in Node.js v24.12.0 on x64 | — |
| `test/port/helpers/helpers.options_test.dart` | `helpers.options` behavior that `test/specs/helpers.options.tests.js` does not check (AGENTS.md rule 3): `_readValueToProps`, `toTRBL`, `_addGrace` and `createContext` have no spec case. The tests cover the anchored line height pattern, `ToNumber` and -0 in `_readValueToProps`, the font style warning, `parseInt` of a string font size, the fallback font object, `info.cacheable` and the array indices of `resolve`, and `beginAtZero` in `_addGrace`. The groups `adapt-options-typed-results` and `adapt-create-context-prototype` pin the `differences.md` rows of the same names. The expected values come from the chart.js 4.5.1 npm dist in Node.js v24.12.0 on x64 | — |
| `test/port/helpers/helpers.math_test.dart` | `helpers.math` behaviour that `test/specs/helpers.math.tests.js` does not check (AGENTS.md rule 3), with expected values from the chart.js 4.5.1 npm dist in Node.js v24.12.0 on x64. `distanceBetweenPoints` gives the bits of its earlier `jsToNumber` and `Math.pow` form, and `getAngleFromPoint` reads a JS `null` coordinate as `jsToNumber(null)`, over every pair of points from 16 coordinates (JS `null`, signed zeros, NaN, infinities, subnormals, +-1.4e154, finites) | — |
| `test/port/helpers/helpers.collection_test.dart` | `helpers.collection` behavior that `test/specs/helpers.collection.tests.js` does not check (AGENTS.md rule 3): empty tables, missing keys, JS `null` and string values, point elements, maps with other type arguments, the identity results of `filterBetween` and `arrayUnique`, SameValueZero and `-0` in `arrayUnique`. The group `platform-array-events` pins the `differences.md` row of the same name. The expected values come from `src/helpers/helpers.collection.ts` in Node.js v24.12.0 on x64 | — |
| `test/port/helpers/helpers.canvas_test.dart` | `toFontString` and `_isPointInArea` behaviour that `test/specs/helpers.canvas.tests.js` does not check (AGENTS.md rule 3): `toFontString` has no spec case. The tests cover falsy styles and weights, `Number::toString` of the size, a falsy margin, JS `null` and NaN coordinates, and a missing point. `_isPointInArea` gives the result of its earlier `jsToNumber` form for 16 x 16 coordinates, three areas and three margins. It pins `adapt-point-in-area-bool` (`differences.md`). The expected values come from the chart.js 4.5.1 npm dist in Node.js v24.12.0 on x64 | — |
| `test/port/helpers/helpers.color_test.dart` | `helpers.color` behaviour that `test/specs/helpers.color.tests.js` does not check, or checks only with a canvas: patterns and gradients as test classes, the `getHoverColor` strings and JS `null`. It pins `platform-color-brand` (`differences.md`). The expected strings come from @kurkle/color 0.3.2 in Node.js v24.12.0 on x64 | — |
| `test/port/kurkle_color/color_test.dart` | `Color` behaviour that the @kurkle/color `test/index.js` does not check: input types, invalid colors, `set rgb` and more manipulation results. It pins `adapt-kurkle-rgba` and `adapt-kurkle-names-proto` (`differences.md`). The expected values come from the @kurkle/color 0.3.2 sources in Node.js v24.12.0 on x64 | — |
| `test/port/kurkle_color/index.esm_test.dart` | The @kurkle/color module functions (`byte`, `hex`, `hue`, `names`, `rgb`, `srgb`), with expected values from the @kurkle/color 0.3.2 sources in Node.js v24.12.0 on x64 | — |
| `test/port/helpers/helpers.interpolation_test.dart` | `helpers.interpolation` behaviour that `test/specs/helpers.interpolation.tests.js` does not check (AGENTS.md rule 3): JS `null` members, `stepped: true`, NaN, unset control points and the result bits. `_pointInLine` and `_steppedInterpolation` give the result of their earlier `jsToNumber` form for 16 x 16 coordinates and five `t` values. The expected values come from `helpers.interpolation.ts` in Node.js v24.12.0 on x64 | — |
| `test/port/helpers/helpers.segment_test.dart` | `helpers.segment` behavior that `test/specs/helpers.segment.tests.js` does not check (AGENTS.md rule 3). The spec tests only `_boundSegment` with `x` and `y`. The tests cover `_computeSegments` (gaps, `spanGaps`, loops, `stop` points and the `null` start of `solidSegments`), `_boundSegments`, the `angle` property, and the segment styles: the context, the `this` of `setContext`, skipped points, `null` and `undefined`, NaN, gradients and strings with escapes in the JSON text. The group `js-semantics-segment-style-json` pins the `differences.md` row of the same name. The expected values come from `src/helpers/helpers.segment.js` in Node.js v24.12.0 on x64 | — |
| `test/port/core/core.ticks_test.dart` | `core.ticks` behavior that `test/specs/core.ticks.tests.js` does not check (AGENTS.md rule 3): `formatters.values`, the `formatters.numeric` branches (tick spacing, scientific notation, NaN, the chart locale, `ticks.format`, a missing `options.ticks`) and the `formatters.logarithmic` branches (shown significands, the last 20 % of the ticks, the `significand` of a tick, negative ticks, an index that is not a tick, a replaced `formatters.numeric`). The expected values come from the upstream `core.ticks.js` in Node.js v24.12.0 on x64 | — |
| `test/port/core/core.animations.defaults_test.dart`, `test/port/core/core.layouts.defaults_test.dart`, `test/port/core/core.scale.defaults_test.dart` | The `apply*Defaults` tests: upstream has no spec for these files (AGENTS.md rule 3). Each test compares the `set`, `describe` and `route` calls, in order and with their values, with the calls of the upstream function in Node.js v24.12.0 on x64. It also calls the functions in the values: the scriptable `tickWidth` and `tickColor`, the `_scriptable` and `_indexable` descriptors and the `fn` of the `hide` transition | — |
| `test/port/core/core.defaults_test.dart` | `core.defaults` behavior that `test/specs/core.defaults.tests.js` does not check (AGENTS.md rule 3): the keys, values and key order of the singleton, its descriptors and its function values (an `undefined` hover color for a color that does not parse, a resolver as `options`); `set`, `get`, `describe`, `override` and `apply`; the three states of Chart.js ADR 0006 (the `undefined` sentinel, `null` and an absent key) in `set`, `getScope` and the routed getter; `route` (a local object over the target object, `Object.assign` of a string or an array target, chained routes, a route on a scope that a route reads, key order, the `configurable` attribute, the target scope before the throw). The groups `adapt-defaults-route` and `adapt-defaults-scope-object` pin the `differences.md` rows of the same names. The group `harness restore` shows that a test that changes `defaults`, `overrides` and `descriptors` does not change the next test, in any test order. The expected values come from `src/core/core.defaults.js` in Node.js v24.12.0 on x64 | — |
| `test/port/core/core.defaults_load_test.dart` | The load of `core.defaults`: `descriptors` and `overrides` have their upstream content before any read of `defaults`, as the JavaScript import gives. The file does not call `setUpSpecs`. The expected keys come from `src/core/core.defaults.js` in Node.js v24.12.0 on x64 | — |
| `packages/chartjs_test_utils/lib/pure.dart` | `setUpSpecs()`, the spec set-up for `dart test` (porting-flow.md §3). A `setUpAll` takes a snapshot of `defaults`, `overrides` and `descriptors`, and a `tearDown` restores it after each test. The snapshot keeps the identity of each object and array, the `undefined` sentinel, the routes of each `RoutedScope` and the `RoutedScope` that took the place of each plain Map. Upstream `test/index.js` restores nothing. This restore is the port-only hunk of porting-flow.md §3 for `dart test` | `test/port/core/core.defaults_test.dart`, group `harness restore` |
| `test/port/core/recording_defaults.dart` | `RecordingDefaults`, a `Defaults` that records each call, and `probeJson`, the JSON form of the recorded calls that the Node.js probe prints. The `apply*Defaults` tests use it in place of the `core.defaults` singleton | — |
| `test/port/helpers/helpers.curve_test.dart` | `helpers.curve` behavior that `test/specs/helpers.curve.tests.js` does not check (AGENTS.md rule 3): `_updateBezierControlPoints` with and without a loop, `capBezierPoints`, `spanGaps`, the monotone mode on the y axis and on the radar axis `r`, an absent, `undefined` or `null` tension, and no points. `splineCurve` with equal points and with a skipped neighbor. The expected values come from the upstream `helpers.curve.ts` in Node.js v24.12.0 on x64 | — |
| `lib/flutter_chartjs.dart` | The public library of the package. It exports `lib/src/upstream.dart` | — |
| `lib/src/upstream.dart` | `chartJsVersion`, the pinned Chart.js release | `test/upstream_test.dart` |
| `test/upstream_test.dart` | Compares `chartJsVersion` with `third_party/Chart.js/package.json` | — |
| `tool/check_lib_imports.dart`, `tool/check_port_headers.dart`, `tool/check_js_semantics.dart` | The commands of tools 1-3 of [porting-flow.md](porting-flow.md) §4 | `test/tool/check_*_test.dart` |
| `tool/src/*.dart` (9 files) | The code of tools 1-3 and 5: the rules, a Dart lexer, the header grammar, small YAML and TOML readers, the shared command line, and the spec-case mapping of tool 5 (`spec_cases.dart`) | `test/tool/*_test.dart` |
| `test/tool/*.dart` (8 files) | The tests of tools 1-3 and 5, and `file_tree.dart`, their temporary file trees | — |
| `tool/upstream_manifest/upstream_manifest.mjs`, `tool/upstream_manifest/src/*.mjs` (1 + 8 files) | Tool 4 of [porting-flow.md](porting-flow.md) §4: the dev-time Node.js generator of the upstream manifest (`upstream:manifest`). It needs Node.js 22.18 or later, and gives the same bytes on every architecture | `tool/upstream_manifest/test/upstream_manifest.test.mjs` (`node --test`), CI job `upstream-manifest` |
| `doc/upstream/manifest.json`, `doc/upstream/fixtures.json` | Generated data of tool 4: the spec cases, fixtures, defaults inventory and JS builtin sites of Chart.js v4.5.1, and the pure-data fixture configs. See [`doc/upstream/README.md`](upstream/README.md) | written by `tool/upstream_manifest/upstream_manifest.mjs` |
| `tool/spec_cases.dart` | The command of tool 5 of [porting-flow.md](porting-flow.md) §4: spec-case tracking (`test:cases`). Its code is `tool/src/spec_cases.dart` | `test/tool/spec_cases_test.dart` |
