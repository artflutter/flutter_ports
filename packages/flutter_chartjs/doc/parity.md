# Chart.js parity tracker

One row per upstream source file of [Chart.js v4.5.1](https://github.com/chartjs/Chart.js/tree/v4.5.1)
(the pinned `third_party/Chart.js` submodule; run `melos run upstream` to check it out).
Port work updates the **Dart target** and **Status** columns in the same PR as the code.

Status values ([porting-flow.md](porting-flow.md) §1 step 7):

- `not started`: no Dart code yet.
- `in progress`: Dart code exists, but not all of the module is ported.
- `partial: <symbols>`: only the listed symbols are ported, because a ported module needs them.
- `ported`: code + ported specs pass; for a pure-layer module, on the VM, dart2js and dart2wasm.
- `verified`: visual parity checked against upstream reference renders.
- `replaced`: a Flutter file replaces the upstream file, for example `platform.flutter.dart` for
  `platform.dom.js`.
- `distributed`: a type declaration file mirrored as `abstract interface class` declarations in
  `lib/src/types`, with members added as ported callers need them (porting-flow.md §2.4).
- `n/a: <reason>`: not ported, for the stated reason.

Line counts are `wc -l` of the upstream file at v4.5.1.

## Summary

| Area | Files | Lines | Ported |
|---|---:|---:|---:|
| helpers | 18 | 3435 | 1 |
| core | 21 | 7135 | 0 |
| elements | 5 | 1203 | 0 |
| scales | 8 | 2290 | 0 |
| controllers | 9 | 1935 | 0 |
| plugins | 15 | 3499 | 0 |
| platform | 4 | 508 | 0 |
| types | 7 | 4070 | 0 |
| entry points | 3 | 133 | 0 |

Runtime dependency: [`@kurkle/color`](https://github.com/kurkle/color) `^0.3.0` (MIT, Jukka Kurkela), resolved to **0.3.2** in the v4.5.1 `pnpm-lock.yaml`. It is wrapped by `src/helpers/helpers.color.ts`, parses and mixes CSS colours, and has to be ported (from 0.3.2) or replaced as well.

## Helpers (`src/helpers`)

| Upstream file | Lines | Dart target | Status |
|---|---:|---|---|
| [`src/helpers/helpers.canvas.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/helpers.canvas.ts) | 527 | | not started |
| [`src/helpers/helpers.collection.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/helpers.collection.ts) | 192 | | not started |
| [`src/helpers/helpers.color.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/helpers.color.ts) | 32 | | not started |
| [`src/helpers/helpers.config.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/helpers.config.ts) | 456 | | not started |
| [`src/helpers/helpers.config.types.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/helpers.config.types.ts) | 60 | | not started |
| [`src/helpers/helpers.core.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/helpers.core.ts) | 416 | `lib/src/helpers/helpers.core.dart` | partial: `isFinite` |
| [`src/helpers/helpers.curve.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/helpers.curve.ts) | 223 | | not started |
| [`src/helpers/helpers.dataset.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/helpers.dataset.ts) | 33 | | not started |
| [`src/helpers/helpers.dom.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/helpers.dom.ts) | 284 | | not started |
| [`src/helpers/helpers.easing.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/helpers.easing.ts) | 124 | | not started |
| [`src/helpers/helpers.extras.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/helpers.extras.ts) | 163 | | not started |
| [`src/helpers/helpers.interpolation.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/helpers.interpolation.ts) | 41 | | not started |
| [`src/helpers/helpers.intl.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/helpers.intl.ts) | 17 | | not started |
| [`src/helpers/helpers.math.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/helpers.math.ts) | 207 | `lib/src/helpers/helpers.math.dart` | ported |
| [`src/helpers/helpers.options.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/helpers.options.ts) | 206 | | not started |
| [`src/helpers/helpers.rtl.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/helpers.rtl.ts) | 74 | | not started |
| [`src/helpers/helpers.segment.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/helpers.segment.js) | 364 | | not started |
| [`src/helpers/index.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/helpers/index.ts) | 16 | | not started |

## Core (`src/core`)

| Upstream file | Lines | Dart target | Status |
|---|---:|---|---|
| [`src/core/core.adapters.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.adapters.ts) | 138 | | not started |
| [`src/core/core.animation.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.animation.js) | 119 | | not started |
| [`src/core/core.animations.defaults.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.animations.defaults.js) | 72 | | not started |
| [`src/core/core.animations.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.animations.js) | 162 | | not started |
| [`src/core/core.animator.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.animator.js) | 214 | | not started |
| [`src/core/core.config.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.config.js) | 418 | | not started |
| [`src/core/core.controller.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.controller.js) | 1269 | | not started |
| [`src/core/core.datasetController.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.datasetController.js) | 1077 | | not started |
| [`src/core/core.defaults.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.defaults.js) | 175 | | not started |
| [`src/core/core.element.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.element.ts) | 45 | | not started |
| [`src/core/core.interaction.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.interaction.js) | 387 | | not started |
| [`src/core/core.layouts.defaults.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.layouts.defaults.js) | 11 | | not started |
| [`src/core/core.layouts.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.layouts.js) | 455 | | not started |
| [`src/core/core.plugins.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.plugins.js) | 188 | | not started |
| [`src/core/core.registry.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.registry.js) | 186 | | not started |
| [`src/core/core.scale.autoskip.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.scale.autoskip.js) | 170 | | not started |
| [`src/core/core.scale.defaults.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.scale.defaults.js) | 105 | | not started |
| [`src/core/core.scale.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.scale.js) | 1710 | | not started |
| [`src/core/core.ticks.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/core/core.ticks.js) | 102 | | not started |
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
| [`src/types/animation.d.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/types/animation.d.ts) | 34 | | not started |
| [`src/types/basic.d.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/types/basic.d.ts) | 3 | | not started |
| [`src/types/color.d.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/types/color.d.ts) | 1 | | not started |
| [`src/types/geometric.d.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/types/geometric.d.ts) | 52 | `lib/src/types/geometric.dart` | distributed |
| [`src/types/index.d.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/types/index.d.ts) | 3885 | | not started |
| [`src/types/layout.d.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/types/layout.d.ts) | 65 | | not started |
| [`src/types/utils.d.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/types/utils.d.ts) | 30 | | not started |

## Entry points

| Upstream file | Lines | Dart target | Status |
|---|---:|---|---|
| [`src/index.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/index.ts) | 25 | | not started |
| [`src/index.umd.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/index.umd.ts) | 54 | | not started |
| [`src/types.ts`](https://github.com/chartjs/Chart.js/blob/v4.5.1/src/types.ts) | 54 | | not started |

## Upstream tests

Upstream tests come in two kinds. Both are ported with the module they cover.

- **Specs** (`test/specs`, Jasmine): 54 files, 25,962 lines. They mostly check computed state (scale ticks, element positions, resolved options) and the recorded canvas calls, so they translate to `flutter_test` unit tests.
- **Image fixtures** (`test/fixtures`): 1,324 files, of which 662 are PNG reference renders produced by Chrome/Firefox. Text antialiasing and fonts differ from Flutter's, so they serve as tolerance-based visual references, not pixel-exact goldens.

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
| [`test/specs/core.defaults.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/core.defaults.tests.js) | 38 | | not started |
| [`test/specs/core.element.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/core.element.tests.js) | 16 | | not started |
| [`test/specs/core.helpers.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/core.helpers.tests.js) | 24 | | not started |
| [`test/specs/core.interaction.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/core.interaction.tests.js) | 1025 | | not started |
| [`test/specs/core.layouts.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/core.layouts.tests.js) | 572 | | not started |
| [`test/specs/core.plugin.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/core.plugin.tests.js) | 510 | | not started |
| [`test/specs/core.registry.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/core.registry.tests.js) | 269 | | not started |
| [`test/specs/core.scale.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/core.scale.tests.js) | 820 | | not started |
| [`test/specs/core.ticks.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/core.ticks.tests.js) | 110 | | not started |
| [`test/specs/element.arc.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/element.arc.tests.js) | 306 | | not started |
| [`test/specs/element.bar.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/element.bar.tests.js) | 67 | | not started |
| [`test/specs/element.line.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/element.line.tests.js) | 35 | | not started |
| [`test/specs/element.point.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/element.point.tests.js) | 69 | | not started |
| [`test/specs/global.defaults.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/global.defaults.tests.js) | 198 | | not started |
| [`test/specs/global.namespace.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/global.namespace.tests.js) | 39 | | not started |
| [`test/specs/helpers.canvas.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/helpers.canvas.tests.js) | 355 | | not started |
| [`test/specs/helpers.collection.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/helpers.collection.tests.js) | 46 | | not started |
| [`test/specs/helpers.color.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/helpers.color.tests.js) | 47 | | not started |
| [`test/specs/helpers.config.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/helpers.config.tests.js) | 877 | | not started |
| [`test/specs/helpers.core.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/helpers.core.tests.js) | 509 | | not started |
| [`test/specs/helpers.curve.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/helpers.curve.tests.js) | 183 | | not started |
| [`test/specs/helpers.dom.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/helpers.dom.tests.js) | 548 | | not started |
| [`test/specs/helpers.easing.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/helpers.easing.tests.js) | 61 | | not started |
| [`test/specs/helpers.interpolation.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/helpers.interpolation.tests.js) | 35 | | not started |
| [`test/specs/helpers.math.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/helpers.math.tests.js) | 141 | `test/specs/helpers.math_test.dart` | ported (12/12 cases) |
| [`test/specs/helpers.options.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/helpers.options.tests.js) | 256 | | not started |
| [`test/specs/helpers.segment.tests.js`](https://github.com/chartjs/Chart.js/blob/v4.5.1/test/specs/helpers.segment.tests.js) | 61 | | not started |
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

## Port-only files

Files with no Chart.js counterpart. Each file starts with
`// Original code, not ported from Chart.js: <reason>.`, except the fdlibm ports, which have the
rule-2 headers of their own source. The fdlibm reference copies are in `third_party/fdlibm/`. The
reference engine of `lib/src/js` is V8 13.6 in Node.js v24.12.0 on x64 ([porting-flow.md](porting-flow.md)
§2.3).

| File | Contents | Tests |
|---|---|---|
| `lib/src/js/js_math.dart` | `Math` and `Number` builtins with the results of the reference engine: `numberEpsilon`, `jsRound`, `jsToInt32`, `jsLog10`, `jsAtan2`, `jsMax`, `jsMin` | `test/port/js/js_math_test.dart` |
| `lib/src/js/js_number.dart` | JS number coercion: `jsToNumber`, `jsParseFloat`, `jsIsNaN`, `jsIsFinite` | `test/port/js/js_number_test.dart` |
| `lib/src/js/fdlibm_log.dart` | Ported from fdlibm 5.3 `e_log.c` and `e_log10.c` (SunPro, Sun Microsystems, Inc.): `ieee754Log`, `ieee754Log10` | `test/port/js/fdlibm_log_test.dart`: 5,909 inputs and 3 regression inputs, bit for bit against `Math.log10` of the reference engine |
| `lib/src/js/fdlibm_atan.dart` | Ported from fdlibm 5.3 `s_atan.c` and `e_atan2.c` (SunPro, Sun Microsystems, Inc.), plus one line that V8 has and netlib does not (`m &= 1` when abs(y/x) > 2**60): `atan`, `ieee754Atan2` | `test/port/js/fdlibm_atan_test.dart`: 3,000 inputs, bit for bit against `Math.atan2` of the reference engine |
| `test/port/js/log10_reference.dart` | Generated data of `fdlibm_log_test.dart` | written by `tool/reference/log10_reference.mjs` |
| `test/port/js/atan2_reference.dart` | Generated data of `fdlibm_atan_test.dart` | written by `tool/reference/atan2_reference.mjs` |
| `tool/reference/log10_reference.mjs`, `tool/reference/atan2_reference.mjs` | Dev-time Node.js generators of the two data files; they stop unless Node.js is an x64 build | — |
| `test/port/helpers/helpers.math_test.dart` | `helpers.math` behaviour that `test/specs/helpers.math.tests.js` does not check (AGENTS.md rule 3), with expected values from the chart.js 4.5.1 npm dist in Node.js v24.12.0 on x64 | — |
| `lib/flutter_chartjs.dart` | The public library of the package. It exports `lib/src/upstream.dart` | — |
| `lib/src/upstream.dart` | `chartJsVersion`, the pinned Chart.js release | `test/upstream_test.dart` |
| `test/upstream_test.dart` | Compares `chartJsVersion` with `third_party/Chart.js/package.json` | — |
| `tool/check_lib_imports.dart`, `tool/check_port_headers.dart`, `tool/check_js_semantics.dart` | The commands of tools 1-3 of [porting-flow.md](porting-flow.md) §4 | `test/tool/check_*_test.dart` |
| `tool/src/*.dart` (8 files) | The code of tools 1-3: the rules, a Dart lexer, the header grammar, small YAML and TOML readers, and the shared command line | `test/tool/*_test.dart` |
| `test/tool/*.dart` (7 files) | The tests of tools 1-3, and `file_tree.dart`, their temporary file trees | — |
