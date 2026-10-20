# Probe harness self-test

Date: 2026-10-20. Node.js v24.12.0 (x64, under Rosetta). Chart.js build at
the pin `7169e651`. Harness: `run_spec.mjs`, `compare.mjs` and `jasmine.mjs`
of this folder.

## Commands

```sh
ENV=<scratchpad>/env
NODE="/usr/bin/arch -x86_64 $ENV/node-v24.12.0-darwin-x64/bin/node"
DIST=$ENV/chartjs-build/dist/chart.js
cd packages/flutter_chartjs/doc/phase7/probe
$NODE compare.mjs $DIST controller.bubble.tests.js --out bubble.json --keep bubble
$NODE compare.mjs $DIST core.plugin.tests.js --out plugin.json --keep plugin
$NODE compare.mjs $DIST core.controller.tests.js --out controller.json --keep controller
```

The Dart side:

```sh
cd packages/flutter_chartjs
flutter test --reporter json test/specs/core.plugin_test.dart \
  test/specs/core.controller_test.dart
```

## Counts by status and mode

`compare.mjs` runs the `without:<id>` modes only for a file with a case that
changes between `all` and `none`. The `without:<id>` counts are for the
changed cases only.

| File | Cases | Mode | pass | fail | error | unsupported |
| --- | --- | --- | --- | --- | --- | --- |
| controller.bubble | 11 | all | 11 | 0 | 0 | 0 |
| controller.bubble | 11 | none | 10 | 0 | 1 | 0 |
| core.plugin | 19 | all | 19 | 0 | 0 | 0 |
| core.plugin | 19 | none | 19 | 0 | 0 | 0 |
| core.controller | 85 | all | 64 | 0 | 0 | 21 |
| core.controller | 85 | none | 60 | 1 | 3 | 21 |

The cases that change between `all` and `none`:

| File | Line | Case | all | none | changedBy |
| --- | --- | --- | --- | --- | --- |
| controller.bubble | 363 | should not override tooltip title and label callbacks | pass | error | tooltip |
| core.controller | 365 | should not change the active elements when outside chartArea, except for mouseout | pass | error | tooltip |
| core.controller | 1515 | controller.reset should reset the chart elements | pass | fail | legend |
| core.controller | 1668 | config update should update tooltip options | pass | error | tooltip |
| core.controller | 1692 | config update should update the tooltip on update | pass | error | tooltip |
| core.controller | 1936 | should not crash when accessing options of a blank inline plugin | pass | pass | all seven plugins |

Case 1515 fails without the legend: the legend takes space, thus the
points move (325.8 in place of 333). Case 1936 iterates over the
registered plugins, thus it has more expectations when more plugins are
registered. The other cases read the tooltip plugin or its options.

## The Dart cases in the mode `all`

The Dart port runs 62 cases of the two files without a skip (19 of
`core.plugin_test.dart` and 43 of `core.controller_test.dart`). All 62 pass
in Dart. Each case has a probe case with the same full name.

| File | Dart cases | pass in `all` | fail or error in `all` | unsupported in `all` |
| --- | --- | --- | --- | --- |
| core.plugin | 19 | 19 | 0 | 0 |
| core.controller | 43 | 23 | 0 | 20 |

No Dart case fails or has an error in the mode `all`. The 20 unsupported
cases are in `config.options.responsive: true` and `config.options.aspectRatio`
of `core.controller.tests.js`. Each case needs a DOM feature that the probe
does not have:

| Line | Case | Cause |
| --- | --- | --- |
| 657 | should resize the canvas when parent width changes | `waitForResize` (resize observer) |
| 697 | should restore the original size when parent became invisible | `waitForResize` (resize observer) |
| 750 | should resize the canvas when parent is RTL and width changes | container layout (`direction: rtl`) |
| 790 | should resize the canvas when parent height changes | `waitForResize` (resize observer) |
| 830 | should not include parent padding when resizing the canvas | container layout (padding) |
| 864 | should resize the canvas when the canvas display style changes from "none" to "block" | container layout (`display: none`) |
| 891 | should resize the canvas when the wrapper display style changes from "none" to "block" | container layout (`display: none`) |
| 918 | should resize the canvas when the wrapper has display style changes from "none" to "block" | container layout (`display: none`) |
| 947 | should resize the canvas when the devicePixelRatio changes | `waitForResize` (resize observer) |
| 981 | should resize the canvas if attached to the DOM after construction | `waitForResize` (resize observer) |
| 1017 | should resize the canvas when attached to a different parent | `waitForResize` (resize observer) |
| 1065 | should resize the canvas after the wrapper has been re-attached to the DOM | `waitForResize` (resize observer) |
| 1116 | should detect detach/attach in series | `waitForResize` (resize observer) |
| 1147 | should detect detach/attach/detach in series | `waitForResize` (resize observer) |
| 1179 | should detect attach/detach in series | `waitForResize` (resize observer) |
| 1218 | should resize the canvas when re-creating the chart | `waitForResize` (resize observer) |
| 1261 | should resize the canvas if attached to the DOM after construction with multiple parents | `waitForResize` (resize observer) |
| 1304 | should resize the canvas with correct aspect ratio when parent width changes | `waitForResize` (resize observer) |
| 1345 | should maintain aspect ratio when parent height changes | `waitForResize` (resize observer) |
| 1483 | should resize the canvas when the aspectRatio option changes | `waitForResize` (resize observer) |

The 21st unsupported case of `core.controller` in `all` is line 1816
(`plugin.extensions should notify plugin in correct order`, `waitForResize`).
The Dart port skips it (`blocked: controller.line`).

## Fixes of the harness during the self-test

1. `jasmine.fixture.specs` returned undefined. A `describe` with it then had
   a declaration error. It now returns an empty describe body.
2. A responsive chart in the default wrapper was unsupported. The wrapper
   with the class `chartjs-wrapper` has `position: absolute` and shrink-wraps
   the canvas. The probe now gives it the CSS box of the canvas. A div of the
   body with an inline px width (and height) also gets that size.
3. `toBe`, `not.toBe(undefined)` and the other identity matchers recorded
   the full object. Then a plugin that adds a property to a controller or a
   meta changed the values of the case, but not what the case asserts. These
   matchers now record `'[ref <class>]'`.
4. `toEqual` with the same element object on both sides recorded the
   element coordinates. The legend changes them, but not the result. The
   record now keeps a ref where both sides are the same object, and only the
   sample keys of `jasmine.objectContaining`.
5. A spy function was in strict mode. Then `this` of a call without a
   receiver was undefined, not `window` (`helpers.core.tests.js:142`). The
   spy is now a sloppy-mode function, as in jasmine.js.
6. `helpers.dom.ts` reads `element.ownerDocument.defaultView`. The DOM
   stand-in now has `ownerDocument` and `defaultView`.
7. A spec file that throws at load time (for example
   `plugin.title.tests.js` in the mode `none`) stopped the process without
   output. The probe now writes `loadError`, and `compare.mjs` gives the
   status `load-error`.
8. A responsive chart on a canvas outside the document was unsupported. In
   a browser, its size is 0 x 0 (`clientWidth` of a canvas without a
   container, or the rect of a container outside the document). The probe
   now gives 0 x 0. Thus the cases 981, 1017 and 1261 record their first
   expectations and stop at `waitForResize`.

## A check of all spec files

`compare.mjs` ran on the 54 spec files (1036 cases) after the fixes. No run
crashed. In the mode `all`: 981 pass and 55 unsupported, with no fail and no
error. In the mode `none`: 877 pass, 24 fail, 38 error, 55 unsupported and
42 load-error (`plugin.title.tests.js` and `plugin.tooltip.tests.js` read
their plugin at load time). 879 cases are equal in both modes and 157 cases
change. Two runs of
`core.controller`, `scale.time`, `core.animations`, `plugin.tooltip` and
`controller.line` in the mode `all` gave the same JSON.
