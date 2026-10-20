# Phase 7 probe harness

The probe runs one upstream spec file of Chart.js in Node.js. It records what
each case asserts. Phase 7 uses it to find the cases whose asserted values
change when a plugin of phase 8 is not registered. The phase 8 plugins are
legend, title, subtitle, tooltip, filler, decimation and colors.

The probe is a tool of the phase. Nothing in `lib/`, `test/` or `tool/` uses
it.

## Files

- `run_spec.mjs`: runs one spec file in one mode and writes a JSON record of
  each case.
- `compare.mjs`: runs `run_spec.mjs` in the modes `all` and `none`, each in
  its own process. When the result of a case differs, it also runs
  `without:<id>` for each plugin id. It writes one JSON for the file.
- `jasmine.mjs`: the Jasmine stand-in (describe, it, hooks, `done`, spies,
  matchers, asymmetric testers). The deep equality is a port of
  `MatchersUtil.eq_` of jasmine-core 3.99.1, the version of the Chart.js
  lockfile.
- `selftest.md`: the self-test of the harness.

## Environment

- The x64 Node.js v24.12.0 (Chart.js ADR 0010). On Apple silicon, run it
  under Rosetta with `/usr/bin/arch -x86_64`.
- A build of Chart.js at the pinned commit, and the moment packages
  (moment 2.29.4, moment-timezone 0.5.42, chartjs-adapter-moment 1.0.1).
  `../env-setup.sh <folder>` makes both. The probe loads them with
  `loadChartJs` of `tool/reference/scale_chart_common.mjs` and
  `loadMomentAdapter` of `tool/reference/scale_time_common.mjs`. These
  functions stop the process unless Node.js is x64 and the build is at the
  pin.
- The submodules `third_party/Chart.js` and `third_party/chartjs-test-utils`.

## Commands

Set the paths first:

```sh
NODE="/usr/bin/arch -x86_64 <env>/node-v24.12.0-darwin-x64/bin/node"
DIST=<env>/chartjs-build/dist/chart.js
```

Run one file in one mode:

```sh
$NODE run_spec.mjs $DIST core.plugin --mode all --out plugin-all.json
$NODE run_spec.mjs $DIST core.plugin --mode none
$NODE run_spec.mjs $DIST plugin.legend --mode without:tooltip
$NODE run_spec.mjs $DIST plugin.legend --mode only:legend --filter 'should draw'
```

Compare the modes for one file:

```sh
$NODE compare.mjs $DIST core.controller --out core.controller.json
```

The spec argument is a name (`core.plugin`, `core.plugin.tests.js`) or a
path. The moment packages come from `--moment <node_modules>`, from
`MOMENT_NODE_MODULES`, or from `<dist>/../../moment/node_modules` (the layout
of `env-setup.sh`). `compare.mjs --keep <folder>` keeps the JSON of each
mode.

## Modes

| Mode | Registration |
| --- | --- |
| `all` | `Chart.register(...registerables)`. The `beforeAll` of `test/index.js` sets `Chart.defaults.plugins.colors.enabled = false`. |
| `none` | The controllers, elements and scales. No plugin. |
| `without:<id>` | All the registerables except the plugin `<id>`. |
| `only:<id>` | The controllers, elements and scales, and the plugin `<id>`. |

Each mode runs in its own process. Thus the cases of a file share their
state in file order, as in Karma.

## Output

`run_spec.mjs` gives one record for each case: `fullName` (the describe
names and the it name, joined with spaces), `describe`, `it`, `line` (the
line of the `it` call), `status`, `reason` (for `unsupported`), `error`,
`notes` and `values`. The status is one of these:

- `pass`: no failed expectation and no error.
- `fail`: a failed expectation, a `fail()` call or a timeout of 5000 ms.
- `error`: an exception in the case or in its hooks.
- `unsupported`: the case needs a feature that the probe does not have. The
  reason tells which feature.
- `skipped`: an `xit` or an `xdescribe`.

When the spec file throws at load time (for example, it reads a plugin that
the mode does not register), no case runs and `loadError` has the error.
`compare.mjs` then gives the status `load-error` to each case of that
mode.

`values` has one record for each expectation, in order:
`{matcher, not, actual, expected, pass}`. A failed expectation does not stop
the case, as in Jasmine. The serializer is deterministic: cycles give
`'[Circular]'`, functions `'[Function <name>]'`, Chart instances `'[Chart]'`,
undefined `'[undefined]'`, and NaN, -0 and the infinities give strings. The
depth limit is 6. A class instance gives `'[class]'` and its own enumerable
keys. A Map gives `{'[Map]': entries}`.

The record keeps the part of a value that the matcher asserts:

- `toBe`, `toBeDefined`, `toBeUndefined`, `toBeNull`, `toBeTruthy`,
  `toBeFalsy`, `toBeTrue`, `toBeFalse`, `toBeNaN` and `toBeInstanceOf` keep
  `'[ref <class>]'` for an object.
- `toEqual` keeps a ref where both sides are the same object, and only the
  sample keys of `jasmine.objectContaining`.
- `toThrow` and `toThrowError` keep `{threw, error}`. The spy matchers keep
  the arguments of the calls.

`compare.mjs` gives, for each case, `status` (for each mode that ran),
`reason`, `error` and `values` (of `all` and `none`), `equal` and
`changedBy`. `equal` is true when `all` and `none` give the same status,
values and error. `changedBy` has the plugin ids whose removal changes the
status, the values or the error of the case.

## How the probe replaces the browser

- `window` is the global object, with `devicePixelRatio` 1 and a
  `requestAnimationFrame` of 16 ms on real timers.
- `document` is a small DOM stand-in: div and canvas elements, `body`,
  `appendChild`, `removeChild`, attributes, inline styles and
  `getElementById`.
- A canvas element is the `fakeCanvas` of `scale_chart_common.mjs`: its
  context is the `LiberationContext` (the mock context of chartjs-test-utils
  with the text widths of Liberation Sans 2.1.5). `createMockContext()` gives
  the upstream mock context.
- The default platform is `ProbePlatform`, a subclass of `DomPlatform` that
  overrides each method. It keeps the canvas set-up and restore of
  `platform.dom.js`, and the throttled event listeners on the canvas.
  `instanceof DomPlatform` is true. A chart with an explicit `platform` keeps
  it.
- `acquireChart`, `releaseChart`, `afterEvent` and `triggerMouseEvent`
  follow `src/utils.js` and `src/index.js` of chartjs-test-utils 0.4.0. The
  mouse event has `offsetX` and `offsetY` at the point. The platform rounds
  the position, as `getRelativePosition` does.
- The matchers of `src/matchers.js` and `src/matchers.options.js` are in
  `run_spec.mjs`.
- `Date.now()` starts at 2021-06-15T12:34:56.789Z (the `NOW` of
  `scale_time_common.mjs`) and moves with the process clock. The time zone
  of the process and of moment is UTC.

## Limits

- No CSS and no layout. `getComputedStyle` works only for a canvas without
  CSS rules: its size is the inline px size or the canvas size. A responsive
  chart gets a size only in a div of the body with an inline px width (or
  with the class `chartjs-wrapper`, which shrink-wraps the canvas), an
  optional px height, and no other inline style except `position`. A
  canvas outside the document gets 0 x 0, as in a browser. Other layouts
  give `unsupported`.
- No `ResizeObserver` and no `MutationObserver`. `waitForResize` gives
  `unsupported`. The attach, detach and resize listeners of a responsive
  chart never fire.
- No pixels, images, gradients or patterns. `toEqualImageData`, `Image`,
  `createLinearGradient`, `createRadialGradient` and `createPattern` give
  `unsupported`. `jasmine.fixture.specs` gives an empty describe body: the
  image fixtures do not run.
- No shadow DOM, iframe, OffscreenCanvas or web worker. These give
  `unsupported`.
- Text widths come from Liberation Sans, not from a browser font. A font or
  text outside the limits of the `LiberationContext` gets the width of the
  upstream mock (10 px for each character) and a note on the case.
- The cases run in file order. Karma runs the specs in a random order with
  a seed, and all files in one page.
- `all` registers `registerables` (controllers, elements, plugins, scales).
  The UMD build of Karma registers controllers, scales, elements, plugins.
  The order changes only the key order of the registry and of the
  defaults.
- The probe makes one chart with `BasicPlatform` at start-up, to find the
  `Config` class. Thus the chart ids start at 1.
- The values of a case can change between runs when they depend on the
  clock (animations, `Date.now()`).
