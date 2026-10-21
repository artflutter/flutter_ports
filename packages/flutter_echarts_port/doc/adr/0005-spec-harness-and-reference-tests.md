# ECharts ADR 0005: Spec harness, reference tests and the visual pages

- Status: proposed
- Date: 2026-10-21
- Gate: ECharts phase 1 for the spec form, the `expect` stand-in and `setUpSpecs()`. The pilot of
  phase 1 ports the first 39 spec cases. ECharts phase 5 for `createChart` and the whole-chart
  reference generators. Phase 5 ports `init`. ECharts phase 6 for the visual smoke runner. Phase 6
  ports the first chart types.
- Related: [ADR 0005](../../../../docs/adr/0005-pin-upstream-sources.md) (item 2: dev-time tools
  can evaluate reference sources), [ADR 0007](../../../../docs/adr/0007-package-names.md) (item 3:
  the name of a harness package),
  [ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) (item 8: tools 4 and
  5, the config value of the harness package),
  [Chart.js ADR 0022](../../../flutter_chartjs/doc/adr/0022-chart-test-harness.md) (the chart
  harness of the Chart.js port),
  [Chart.js ADR 0023](../../../flutter_chartjs/doc/adr/0023-underscore-member-collisions.md) (the
  underscore members),
  [Chart.js ADR 0029](../../../flutter_chartjs/doc/adr/0029-fixture-smoke-runner.md) (the fixture
  smoke runner),
  [Chart.js ADR 0030](../../../flutter_chartjs/doc/adr/0030-controller-test-strategy.md) (the
  reference tests, the tolerance, the size of a data file),
  [Chart.js ADR 0032](../../../flutter_chartjs/doc/adr/0032-js-numeric-semantics.md) (accepted
  2026-10-21: §2, the reference engine),
  [Chart.js ADR 0034](../../../flutter_chartjs/doc/adr/0034-no-display-only-js-exactness.md)
  (accepted 2026-10-21: §4, no image comparison),
  [D3 ADR 0004](../../../flutter_d3_port/doc/adr/0004-spec-harness.md) (the stand-in form, the
  names, the skips, the test legs, no harness package),
  [ECharts ADR 0001](0001-upstream-sources.md) (the pins and the headers),
  [ECharts ADR 0002](0002-file-naming-and-layout.md) (the spec paths, the underscore members, the
  pure layers, `useAll()`),
  [ECharts ADR 0003](0003-numbers-and-js-semantics.md) (`jsMathRandom`, the protected behavior),
  [ECharts ADR 0004](0004-js-values-classes-and-options.md) (the two-state null rule, the
  `undefined` sentinel, `echartsDev`, the log sink),
  [ECharts ADR 0006](0006-renderer-and-canvas-layer.md) (the Canvas 2D interface, the frame hook),
  [ECharts ADR 0007](0007-environment-host-and-input-events.md) (the env values, the platform API,
  `EChartsContainer`, the handler proxy),
  [ECharts ADR 0008](0008-dates-locales-and-formatting.md) (the spec zones),
  [ECharts ADR 0009](0009-dom-features-app-hooks-and-theming.md) (the tooltip modes, aria),
  [porting-flow.md](../porting-flow.md) §3 and §4, [differences.md](../differences.md)

## Context

AGENTS.md rule 3 asks for a port of the upstream specs. The facts below are at the pins of
[ECharts ADR 0001](0001-upstream-sources.md): `third_party/echarts` at `6.1.0` (`c5a48f5f`) and
`third_party/zrender` at `6.1.0` (`32b66867`). The paths are relative to the submodule.

**Runners.** Both repositories run jest with ts-jest.

| | ECharts 6.1.0 | zrender 6.1.0 |
|---|---|---|
| Script | `npx jest --config test/ut/jest.config.cjs` (`package.json:57`) | `npx jest --config test/ut/jest.config.js` (`package.json:27`) |
| jest, ts-jest (`package-lock.json`) | 26.6.3, 26.5.6 | 27.2.5, 27.0.6 |
| TypeScript (lock) | 4.4.3 | 4.4.3 |
| Environment | `jsdom` 16.7.0 (`test/ut/jest.config.cjs:25`) | `node` (`test/ut/jest.config.js:3`) |
| `setupFiles` | `jest-canvas-mock` 2.5.0 and `core/setup.ts` (`jest.config.cjs:28-31`) | none |
| `setupFilesAfterEnv` | `core/extendExpect.ts`, 4 matchers (`:32-34`) | `extendExpect.ts`, an empty `expect.extend({})` |
| Globals | `__DEV__: true` (`:35-37`) | none |
| zrender of the specs | the npm `zrender` 6.1.0, compiled by ts-jest (`:39-41`) | its own `src/` |

- `test/ut/core/setup.ts:20` is `export {};`. It does nothing.
- The ECharts spec files import `@/src/...`. `test/ut/tsconfig.json` maps `@/*` to `../../*`.
- Upstream CI runs the ECharts specs on Node.js 20 (`.github/workflows/ci.yml:65`, `:87`).
- Neither repository has node-canvas in its `devDependencies`. No upstream spec reads pixels.

**Text widths.** The specs of the two repositories measure text in different ways:
- jest-canvas-mock 2.5.0 gives `measureText(text)` a `TextMetrics` with `width = text.length`
  (`lib/classes/TextMetrics.js:24` of the npm tarball). The count is in UTF-16 code units. Thus an
  ECharts spec measures each text at 1 px for each code unit, in every font.
- The mock context also records each call in `_events`. No spec at the pin reads that list.
- The zrender specs run in `node`. There, `platformApi.createCanvas()` gives `false`
  (`zrender src/core/platform.ts:56-59`). `measureText` then takes the fallback branch
  (`:76-92`). That branch reads the ASCII width map of `:33-52`. A `mono` font gives
  `fontSize * text.length`. Another character gives `fontSize`.
- `zrender test/ut/spec/core/platform.test.ts:38` asserts this branch:
  `measureText('A', 'normal normal 18px sans-serif').width` is `12.06`.

**Cases.** The counts come from a probe. The probe evaluated each spec file in Node.js with
`module.stripTypeScriptTypes`, a stub for each import and a `describe` and `it` that record the
names. The pins have no `it.skip`, `xit`, `.only` or `.each`.
- ECharts `test/ut/spec/`: 24 files, 9,274 lines, 191 cases, 64 `describe` calls, 180 static `it`
  sites and 841 `expect(` calls.
- zrender `test/ut/spec/`: 12 files, 1,042 lines, 68 cases, 219 `expect(` calls. The helper
  `spec/zrender.ts` re-exports `src/export` and `src/zrender`.
- Total: 36 files and 259 cases.

| ECharts spec file | Cases | Makes a chart |
|---|---:|---|
| `api/containPixel` | 4 | yes |
| `api/converter` | 4 | yes |
| `api/getVisual` | 2 | yes |
| `component/dataZoom/helper` | 3 | yes |
| `component/graphic/setOption` | 12 | yes |
| `component/helper/sliderMove` | 5 | no |
| `component/matrix/event` | 2 | yes |
| `component/visualMap/setOption` | 7 | yes |
| `data/SeriesData` | 21 | no |
| `data/createDimensions` | 5 | no |
| `data/dataTransform` | 8 | yes |
| `data/dataValueHelper` | 10 | no |
| `model/Global` | 22 | yes |
| `model/componentDependency` | 9 | no |
| `model/componentMissing` | 6 | yes, with its own `createChart` |
| `model/timelineMediaOptions` | 11 | yes |
| `scale/interval` | 4 | yes |
| `series/aria-columns-exclude` | 2 | yes |
| `series/custom` | 2 | yes |
| `util/graphic` | 7 | no |
| `util/layout` | 1 | no |
| `util/model` | 5 | no |
| `util/number` | 24 | no |
| `util/time` | 15 | no |

The 10 pure ECharts files hold 102 cases. The 14 chart files hold 89 cases. The 12 zrender files
make no chart: `animation/ElementAnimation` 6, `contain/Sector` 1, `core/LRU` 1,
`core/arrayDiff` 3, `core/matrix` 1, `core/platform` 3, `core/util` 11, `graphic/Group` 10,
`graphic/Image` 3, `graphic/Path` 13, `graphic/Text` 1 and `tool/color` 15.

Loops make cases at run time:
- `data/dataValueHelper.test.ts:346` calls each entry of a local `testerMap`. Two `it` sites make
  10 cases.
- `data/dataTransform.test.ts:105-106`, `:136-137` and `:164-165` make 6 cases. Each name ends
  with `_${itIdx}`.
- `zrender test/ut/spec/tool/color.test.ts:22` makes 15 cases from a local list of colors.

No case name at the pins comes from an imported value. Three full names occur two times:
`util/time format should format hour`, `util/time format should format millisecond` and
`timelineMediaOptions parse_timeline_media_option parse_timeline_has_baseOption_compat`.

**How a chart spec makes a chart.** `createChart` (`test/ut/core/utHelper.ts:33-61`) does these
steps:
1. It calls `document.createElement('div')` of jsdom. It writes a hidden, absolute `cssText`.
2. It defines the getters `clientWidth` and `clientHeight` on the element. Their defaults are 500
   and 400. jsdom has no layout.
3. It calls `init(el, theme, opts)` of `src/echarts.all` (`utHelper.ts:20`). The import of
   `echarts.all` registers all charts and components as a side effect.

`removeChart` calls `chart.dispose()` (`:63-65`). `getViewGroup` reads the private members
`chart._chartsMap`, `chart._componentsMap` and `component.__viewId` (`:142-151`).
`model/Global.test.ts:57` reads `GlobalModel._componentsMap`. `:62` reads `chart._chartsMap`.

Each chart spec is synchronous. `setOption` renders at once. The specs read the model, the views,
the zrender display list, `getOption()` and the converters. They read no pixels, no client rects
and no animation frames. A layout value that depends on a label size has the mock width
upstream.

**The DOM in the specs.** jsdom gives a `window` and a `document`. The default user agent of
jsdom 16.7.0 names `jsdom`, not `Node.js` (`lib/jsdom/browser/resources/resource-loader.js:16-17`
of jsdom). Thus `zrender src/core/env.ts:50-52` calls `detect`. There,
`domSupported` becomes `true` (`env.ts:94`). Four places of the specs use the DOM directly:
- `series/aria-columns-exclude.test.ts:83-84` reads `chart.getDom().getAttribute('aria-label')`.
- `series/custom.test.ts:115-118` makes a `MouseEvent('mousemove')`. It assigns `zrX: 100` and
  `zrY: 270`. It dispatches the event on `chart.getDom().children.item(0)`. `normalizeEvent`
  returns such an event unchanged (`zrender src/core/event.ts:162-164`).
- `model/componentMissing.test.ts:35-48` has its own `createChart` on a jsdom `div`. It imports
  `use` and the components from `src/export/*` (`:21-31`), not `echarts.all`.
- `model/componentMissing.test.ts:69-106` replaces `console.error` with `jest.fn()`. It asserts the
  message with `toHaveBeenCalledWith` and `not.toBeCalled`. It restores `console.error` itself.

`component/matrix/event.test.ts:63` and `:113` call `chart.getZr()`. They trigger the events
through the zrender API, with no DOM.

**Asynchronous cases.**
- The 7 cases of `component/visualMap/setOption.test.ts:40-243` take a `done` callback. Each body
  calls `done()` at its end, synchronously.
- `zrender test/ut/spec/animation/ElementAnimation.test.ts:74-115` has 2 cases that return a
  `Promise`. One waits for the `done` callback of a 100 ms animation. One waits for the `aborted`
  callback after a `setTimeout` of 100 ms.
- In `node`, zrender gets its frames from `setTimeout(func, 16)`
  (`zrender src/animation/requestAnimationFrame.ts:7-19`).
- `util/number.test.ts:390-392` and `scale/interval.test.ts:121`, `:124` call `Math.random` for
  their inputs. Upstream does not seed it.

**Assertions.** The pins have these matcher calls. The counts are of `.<name>(` and
`.not.<name>(` in the spec files.

| Matcher | ECharts | zrender |
|---|---:|---:|
| `toEqual` | 783 | 77 |
| `not.toEqual` | 7 | 0 |
| `toBe` | 2 | 111 |
| `not.toBe` | 0 | 1 |
| `toMatchObject` | 0 | 9 |
| `toBeFalsy` | 0 | 8 |
| `toBeCloseTo` | 1 | 6 |
| `toBeFinite` (custom) | 5 | 0 |
| `toContain`, `not.toContain` | 2, 4 | 0 |
| `toThrowError`, `not.toThrowError`, `toThrow` | 3, 0, 1 | 0, 1, 0 |
| `toHaveBeenCalledWith`, `not.toBeCalled` | 3, 3 | 0 |
| `toBeLessThanOrEqual`, `toBeGreaterThanOrEqual` | 3, 3 | 0 |
| `not.toBeGreaterThan` (custom), `not.toBeGreaterThanOrEqual` | 1, 1 | 0 |
| `toBeNaN` | 2 | 0 |
| `toBeNull`, `not.toBeNull`, `toBeDefined`, `toBeUndefined` | 1, 1, 1, 0 | 1, 0, 0, 3 |
| `toStrictEqual`, `toHaveLength` | 1, 0 | 0, 2 |

The jest semantics differ from the Dart matchers of `package:test`:
- `toBe` compares with `Object.is`. Thus NaN is NaN. Also, −0 is not +0.
- `toEqual` recurses. It compares numbers with `Object.is`. It ignores a property whose value is
  `undefined`. It ignores the class of an object. `toStrictEqual` compares both.
- `toBeCloseTo(n, digits = 2)` passes when `|a − b| < 10^−digits / 2`.
- `toThrowError(re)` matches the message of the error. `toMatchObject` compares a recursive subset.
- A `done` case of jest fails after the default timeout of 5,000 ms.

`test/ut/core/extendExpect.ts:27-69` adds 4 matchers:
- `toBeFinite`: `val != null && val !== '' && isFinite(val)` (`:21-23`, `:28-36`).
- `toBeGeaterThanOrEqualTo` (`:39-47`): the typo is upstream. No spec at the pin calls it.
- `toBeGreaterThan` (`:50-58`): it replaces the built-in matcher with a plain `>`. It has no type
  test.
- `toBeEmptyArray` (`:60-68`). No spec at the pin calls it.

**File isolation and module state.** jest gives each test file a new module registry. Thus the
`use()` of `componentMissing` does not see the registrations of `echarts.all` in other files.
`dart test` and `flutter test` load each test file in its own isolate on the VM. On the web legs,
each test file is its own compile. Thus the isolation of the files matches.

**The visual pages.** The visual tests are no specs. They are a manual tool.
- ECharts `test/*.html`: 605 pages. 595 of them load `lib/simpleRequire.js` and `lib/config.js`.
  The pages hold 1,000 calls of `testHelper.create(` and 444 calls of `echarts.init(` (grep, with
  comments).
- `test/lib/config.js:71` and `:77` map the AMD module `echarts` to `../dist/echarts`.
  `test/lib/testHelper.js` has 3,562 lines: inputs, buttons, data tables and recorders.
- `test/data/` holds 24 MB in 49 entries. No file records the origin of each entry.
- zrender `test/*.html`: 76 pages. They have no runner, no actions and no images.
- `package.json:55` starts the runner: `node test/runTest/server.js`. Upstream CI does not run it.
- `test/runTest/cli.js` runs each page two times in one headless Chrome. One run takes an
  `--expected` version, the other the `--actual` version (`:41-44`, `:379-380`). The default
  actual version is `local`, the `dist/` of the checkout (`:55`). The viewport is 800 x 600
  (`:303-304`).
- Thus upstream commits no reference image. The runner compares two builds in the same browser.
- `test/runTest/compareScreenshot.js:39`, `:57` calls pixelmatch with `threshold = 0.01`.
  `store.js:342` fails a result with a `diffRatio` above 0.0001.
- `test/runTest/util.js:29-34` replaces `Math.random` in the ECharts bundle with a seedrandom
  source. It also replaces `remainTime > 0` with `false`. That is the progressive loop at
  `src/core/echarts.ts:694`. Without the hack, the frozen `Date` of the runner makes it loop.
- `test/runTest/runtime/main.js:20-28` seeds the page `Math.random` with `'echarts-random'` and the
  bundle with `'echarts-random-inner'`. `runtime/timeline.js:26-28` runs `Date`, timers and frames
  on fixed frames of 16 ms from 1566458693300.
- `test/runTest/actions/` has 273 files: 271 action files, `__meta__.json` and `update.js`. The
  actions use the page coordinates of the Chrome layout of `testHelper`.
- `test/runTest/blacklist.js:20-45` lists 16 pages for all renderers. `:48-58` lists 8 more pages
  for SVG.

**The release build.** `dist/echarts.js` is committed at the tag. It is a UMD build of 3,847,293
bytes with zrender inside. Its ECharts version is `'6.1.0'` (`dist/echarts.js:28229`). Its
zrender version is `'6.1.0'` (`:7613`, `:28230-28231`). It keeps the `__DEV__` branches as
`"development" !== 'production'` (`:30270`). It exports `env`, `setPlatformAPI`, `version` and
`dependencies` (`:95792-95836`). `test/node/ssr.js:20-25` runs it in Node.js with
`init(null, null, {renderer: 'svg', ssr: true, width: 510, height: 510})`.

In Node.js, `zrender src/core/env.ts:40-49` sets `node` to `true`. `init` with no DOM throws in
`__DEV__` unless `ssr` is set (`echarts src/core/echarts.ts:2931-2936`). The `ssr` flag changes
these branches: `echarts.ts:808` (no flush after `setOption`), `model/Series.ts:552`,
`chart/line/LineView.ts:653`, `chart/pie/PieView.ts:81` and `zrender src/zrender.ts:123-153` (no
handler proxy, no animation loop). `TooltipView.ts:165`, `:184`, `:298` and `:1049` stop when
`env.node` is true or `getDom()` is null.

**Precedents.**
- [Chart.js ADR 0022](../../../flutter_chartjs/doc/adr/0022-chart-test-harness.md): a chart spec
  of Chart.js is a `testWidgets` test with `@TestOn('vm')`. The harness package
  `chartjs_test_utils` has a DOM stand-in, frames of 16 ms and `waitForDone`.
- [Chart.js ADR 0029](../../../flutter_chartjs/doc/adr/0029-fixture-smoke-runner.md): the fixture
  smoke runner. Tool 4 writes `fixtures.json`. Hand ports go in `test/fixtures/hand/`. The tag is
  `fixtures`, the script `test:fixtures`, the CI job `fixtures`, the switch `FIXTURES_REQUIRED=1`.
- [Chart.js ADR 0030](../../../flutter_chartjs/doc/adr/0030-controller-test-strategy.md): Node.js
  generators run the pinned dist. Numbers compare at 1e-9 absolute or 1e-12 relative above 1e3.
  A data file has at most 2.5 MB.
- [Chart.js ADR 0032](../../../flutter_chartjs/doc/adr/0032-js-numeric-semantics.md) §2
  (accepted 2026-10-21): reference values come only from an x64 build of Node.js v24.12.0.
- [Chart.js ADR 0034](../../../flutter_chartjs/doc/adr/0034-no-display-only-js-exactness.md) §4
  (accepted 2026-10-21): no image comparison with upstream. A smoke test passes when no step throws.
- [D3 ADR 0004](../../../flutter_d3_port/doc/adr/0004-spec-harness.md): a stand-in keeps the
  upstream assertions line by line. The names follow the ` #2` rule. Loops stay loops. The harness
  stays in `test/support/` until a trigger.

A Chart.js ADR binds only the Chart.js port. A D3 ADR binds only the D3 port. This ADR restates
each rule that it takes.

**Reference engine.** On 2026-10-21, `~/.nvm/versions/node/v24.12.0/bin/node` of the machine of
the maintainer is an arm64 build. The case probe above ran on it. Case names are no reference
values. Thus the x64 rule does not apply to them.

## Decision

### 1. Spec form

1. The Dart path of a spec follows [ECharts ADR 0002](0002-file-naming-and-layout.md):
   `test/ut/spec/<p>.test.ts` becomes `test/specs/echarts/<p>_test.dart` or
   `test/specs/zrender/<p>_test.dart`. The header names the upstream file, for example
   `// Ported from Apache ECharts 6.1.0 test/ut/spec/util/number.test.ts (Apache-2.0, The Apache Software Foundation).`
2. A `describe` becomes a `group()`. An `it` becomes a `test()`. The names are the upstream
   strings, unchanged. jest and `package:test` both join the group names and the test name with a
   space. Thus tool 5 maps the full names one to one.
3. When a full name occurs again in one file, the later cases get ` #2`, ` #3` and the next
   numbers, in order. At the pins, this rule applies to the three names of the Context.
4. A loop that makes cases stays a loop. It gives the upstream names, for example
   `seriesLayoutBy_changed_transform_detection_0`.
5. A `beforeEach` becomes `setUp`. An `afterEach` becomes `tearDown`.
6. A `done` case becomes a `test()` with an async body. The body gets `done` from `jestDone()` of
   the stand-in (section 2). It awaits the `Future` of `done` with the jest timeout of 5,000 ms.
   The line `done();` stays.
7. A case that returns a `Promise` returns a `Future`. The 2 cases of `ElementAnimation` run on
   real timers, as upstream. Their timers come from the pure frame hook of
   [ECharts ADR 0006](0006-renderer-and-canvas-layer.md): a `Timer` of 16 ms.
8. A spec call of `Math.random` calls `jsMathRandom` of
   [ECharts ADR 0003](0003-numbers-and-js-semantics.md).
9. Each spec file calls `setUpSpecs()` (section 4) as the first statement of `main()`.
10. A spec file imports `package:test/test.dart` with `hide expect`. Thus the assertion lines stay
    `expect(x).toEqual(y);`. A reviewer compares the Dart file and the upstream file side by side.

### 2. The jest `expect` stand-in

The port-only library `test/support/jest_expect.dart` keeps the jest assertions. It is a pure
layer. It imports only `package:test` and the JS runtime.

1. `expect(actual)` gives an expectation object. Its member `not` gives the negated object.
2. The expectation has the matchers of the Context table. A failed matcher throws the
   `TestFailure` of `package:test`. Its message names the actual and the expected value.
3. The matchers keep the jest semantics:
   - `toBe` compares with `Object.is`. NaN is NaN. −0.0 is not 0.0. An `int` equals the `double`
     of the same value.
   - `toEqual` recurses into `List`, `Map`, typed lists and the value classes of zrender. It
     compares numbers with `Object.is`. It ignores the class.
   - `toStrictEqual` also compares the class and the keys.
   - `toBeCloseTo(n, [digits = 2])` passes when `|a − b| < 10^−digits / 2`.
   - `toThrowError(re)`, `toThrow()` and `not.toThrowError()` take a `RegExp`, a `String` or
     nothing. They match the message of a `JsError` ([ECharts ADR 0004](0004-js-values-classes-and-options.md)).
   - `toMatchObject` compares a recursive subset of the keys.
4. Null and `undefined` follow the two-state rule of
   [ECharts ADR 0004](0004-js-values-classes-and-options.md). Dart `null` stands for JS `null`
   and for JS `undefined`. These rules apply:
   - In each comparison, Dart `null` equals JS `null` and the `undefined` sentinel.
   - `toEqual` ignores a `Map` key whose value is Dart `null` or the sentinel.
   - `toBeUndefined` passes for Dart `null` and for the sentinel. `toBeDefined` fails for both.
   - `toBeNull` and `toBe(null)` pass for Dart `null` only.
5. `jest.fn()` gives a mock function. It records each call. `toHaveBeenCalledWith` and
   `toBeCalled` read the record.
6. `jestDone()` gives the `done` callback of section 1 item 6 and its `Future`.
7. `test/port/support/jest_expect_test.dart` tests the stand-in on the three legs. It covers NaN,
   ±0, `int` and `double`, `null` and the sentinel, the ignored keys, the class, `toBeCloseTo`
   digits and each form of `toThrowError`.

### 3. The ported harness files

1. `test/ut/core/extendExpect.ts` becomes `test/support/echarts/extendExpect.dart`. It ports the 4
   matchers line by line, with the typo `toBeGeaterThanOrEqualTo`. Its `toBeGreaterThan` replaces
   the built-in matcher of the stand-in with a plain `>`, as upstream does. The ECharts spec files
   import it. The zrender spec files do not.
2. `test/ut/core/utHelper.ts` becomes `test/support/echarts/utHelper.dart` (phase 5). Its
   functions keep their names: `createChart`, `removeChart`, `getGraphicElements`,
   `getViewGroup`, `getECModel`.
3. Both files carry the header of [ECharts ADR 0001](0001-upstream-sources.md) and the ignore
   line for `file_names` ([ECharts ADR 0002](0002-file-naming-and-layout.md)). Their upstream
   license block stays after the header lines.
4. These upstream files get no port: `test/ut/core/setup.ts` (empty), `test/ut/index.d.ts` (types
   only), zrender `test/ut/extendExpect.ts` (empty) and the jest configs. Their status is
   `n/a: <reason>`.
5. zrender `test/ut/spec/zrender.ts` becomes `test/specs/zrender/zrender.dart`. It is a library
   with the two re-exports, not a test file.

### 4. Spec set-up

The port-only library `test/support/spec_setup.dart` has `setUpSpecs()`. It is a pure layer. Each
spec file calls it, also under `flutter test`.

1. `setUpSpecs()` sets `echartsDev` to `true` ([ECharts ADR 0004](0004-js-values-classes-and-options.md)).
   This is the global `__DEV__: true` of the ECharts jest config. zrender has no `__DEV__` site.
2. It installs the spec zone of [ECharts ADR 0008](0008-dates-locales-and-formatting.md).
3. It installs a seeded source for `jsMathRandom`. Thus a failed case repeats with the same
   inputs.
4. It takes the parameter `canvasMock`. The ECharts spec files call `setUpSpecs(canvasMock: true)`.
   This is the port of the `setupFiles` entry `jest-canvas-mock`. Section 5 gives the mock. The
   zrender spec files call `setUpSpecs()` with no mock. They keep the fallback branch of
   `zrender src/core/platform.ts:76-92`, as upstream in `node`.
5. When it runs, it keeps the values of the module state below. In `tearDown`, it writes them back:
   - the members of `platformApi` (`zrender src/core/platform.ts:54-109`)
   - the log sink of [ECharts ADR 0004](0004-js-values-classes-and-options.md), the port of
     `console`
   - the source of `jsMathRandom`
   - the registered themes and locales
   - the text caches of `zrender src/contain/text.ts`: `_fontMeasureInfoCache` (`:26-49`, an LRU
     of 100 fonts with 500 widths each) and `_getASCIIWidthMapLongCount` (`:78`)
   - the image cache `globalImageCache` of `zrender src/graphic/helper/image.ts:6`

   These caches hold values that came through `platformApi`. Thus a test that installs the canvas
   mock after a test with the fallback widths reads no stale width. Each cache resets through a
   `@visibleForTesting` reset function next to it. A reset function is port-only code in the
   ported file. It changes no upstream line. Thus it needs no `DIVERGES` marker.
6. The restore runs after the restore code of a ported case. Such code stays as upstream wrote it,
   for example `zrender test/ut/spec/core/platform.test.ts:30-34`.
7. It does not reset the registered charts and components. Upstream keeps them for the whole file
   too.
8. `spec_setup.dart` is a port-only file. Thus the set-up needs no `DIVERGES` marker.

### 5. Pure chart specs

zrender and ECharts reach `dart:ui` only through interfaces. These are the Canvas 2D interface of
[ECharts ADR 0006](0006-renderer-and-canvas-layer.md) and the platform API of
[ECharts ADR 0007](0007-environment-host-and-input-events.md). Thus every spec is pure. No spec
uses `testWidgets`. This differs from Chart.js ADR 0022 §2.

1. **The canvas mock.** The port-only library `test/support/canvas_mock.dart` gives a pure
   mock canvas. Its 2D context implements the Canvas 2D interface. It records each call in a
   list. Its `measureText(text)` gives `width = text.length` in UTF-16 code units, as
   jest-canvas-mock 2.5.0 does. `setUpSpecs(canvasMock: true)` installs it through
   `setPlatformAPI({createCanvas})`. `platformApi.measureText` then measures on its context, as
   upstream.
   - Phase 1 adds the parameter `canvasMock`. Phase 3 adds the mock with the Canvas 2D
     interface. Before phase 3, the parameter installs nothing. No file of phases 1 and 2 measures
     text.
2. **`createChart`.** The port of `utHelper.ts:33-61` does these steps:
   1. It makes an `EChartsContainer` ([ECharts ADR 0007](0007-environment-host-and-input-events.md)).
      It sets the client width to `params.width` or 500. It sets the client height to
      `params.height` or 400. It writes the same `cssText` as upstream.
   2. It calls `useAll()`, the port of the import side effects of `src/echarts.all.ts`
      ([ECharts ADR 0002](0002-file-naming-and-layout.md)). `useAll()` does nothing on a second
      call.
   3. It calls `init(el, theme, opts)`.
   4. It throws a `StateError` when the canvas mock is not installed.
3. **`componentMissing`.** Its own `createChart` makes an `EChartsContainer` of 500 x 400. It calls
   only its own `use([...])`, as upstream (`model/componentMissing.test.ts:21-48`). The line
   `console.error = jest.fn()` writes the log sink.
4. **The env values.** The specs run with the env values of
   [ECharts ADR 0007](0007-environment-host-and-input-events.md): `domSupported`, `node` and
   `hasGlobalWindow` are `false`. Upstream ran in jsdom with `domSupported` `true`. Thus
   `getTooltipRenderMode` gives `'richText'` where upstream gives `'html'`
   (`src/util/model.ts:1047`). `SYSTEM_LANG` is `EN` in both runs (`src/core/locale.ts:39`).
5. **Events.** The port-only library `test/support/harness_events.dart` has
   `dispatchHarnessEvent(target, type, fields)`. It stands in for `new MouseEvent(type)`,
   `Object.assign` and `dispatchEvent` (`series/custom.test.ts:116-118`). It gives the raw event
   with its `zrX` and `zrY` to the handler proxy of `target`. The proxy then triggers the event
   name, as `zrender src/dom/HandlerProxy.ts:202-210` does. `chart.getDom().children.item(0)` is the
   `ZrViewport` of the container ([ECharts ADR 0007](0007-environment-host-and-input-events.md)).
6. **Attributes.** `chart.getDom().getAttribute('aria-label')` reads the attribute of the pure
   `EChartsContainer` ([ECharts ADR 0009](0009-dom-features-app-hooks-and-theming.md)).
7. **Rows.** Two `harness` rows of [differences.md](../differences.md) record the differences:
   - `harness-canvas-mock-text`: the ECharts specs measure text with `text.length`. The Flutter
     layer measures with `ui.Paragraph`. The change that adds the canvas mock adds the row.
   - `harness-dom-supported`: the specs run with the env values of item 4, not with jsdom. A
     harness event replaces a DOM event (item 5). The change that ports the first chart spec adds
     the row.
8. **Fallback.** If a later decision makes a mapped tree impure, the chart specs take the form of
   Chart.js ADR 0022: `testWidgets`, `@TestOn('vm')` and a Flutter harness. A new ECharts ADR then
   records the change.

### 6. Private members

1. The ported `utHelper.dart` reads `_chartsMap`, `_componentsMap` and `__viewId`.
   `model/Global_test.dart` reads `_componentsMap` of `GlobalModel` and `_chartsMap`.
2. A Dart library cannot read a private member of another library. Thus these members drop the
   underscores at their start. Each carries `@internal`.
3. This is the rule of [ECharts ADR 0002](0002-file-naming-and-layout.md), after Chart.js ADR 0012
   and 0023. `_chartsMap` becomes `chartsMap`. `__viewId` becomes `viewId`.
4. A collision with another member gets an underscore at the end.

### 7. Test legs

| Suite | VM: `flutter test`, 3 OS | `dart test -p chrome -c dart2js` | `-c dart2wasm` |
|---|---|---|---|
| The 36 spec files and the pure tests of `test/port/` | yes | yes | yes |
| Tests with `@TestOn('vm')` | yes | no | no |

1. All 259 upstream cases run on the three legs.
2. The first pure test of phase 1 adds `flutter_echarts_port` to the melos script `test:web`.
   Without a test, `dart test -p chrome` exits with code 79 (D3 ADR 0004 §9).
3. A test that imports `dart:io`, `dart:ui` or `flutter_test` has `@TestOn('vm')`.
   [ECharts ADR 0002](0002-file-naming-and-layout.md) gives its line in the header block.

### 8. Skip reasons

Tool 5 accepts only these reasons:
- `'blocked: echarts/src/<path>.ts'` or `'blocked: zrender/src/<path>.ts'`: the case needs a
  file that is not ported. When several files of one folder block the case, the reason names the
  folder. When files of two phases block it, the reason names the file of the later phase.
- `'n/a: <reason>'`: the port does not port the behavior of the case.
- `'diverges: <row id>'`: the case asserts a difference with a row in
  [differences.md](../differences.md).

A chart case uses `utHelper.dart`, and thus `echarts.all.dart` of phase 10. A chart case passes
before phase 10 when the modules of its options are ported. Until then, it skips with the file
of the latest phase that its options need.

### 9. Tool 4 and tool 5

1. Tool 4 is a Node.js tool of the ECharts port in `tool/upstream_manifest/`
   ([ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) item 8). It needs
   Node.js 22.18 or later, as the Chart.js tool 4. Phase 2 adds it.
2. It evaluates each spec file of the pins in a Node.js module context. It strips the types with
   `module.stripTypeScriptTypes`. Each import resolves to a stub module. A stub export is a
   `Proxy` that accepts each call and each property read. `describe` and `it` record the names
   and do not run the bodies.
3. It runs no `npm install`. It writes no file into `third_party/`
   ([ADR 0005](../../../../docs/adr/0005-pin-upstream-sources.md) item 2).
4. It writes `doc/upstream/manifest.json`. The manifest has one key for each project: `echarts`
   with 24 files and 191 cases, `zrender` with 12 files and 68 cases. Each case has its file, its
   order and its full name with the ` #2` rule.
5. It fails on a spec file that it cannot evaluate. It never drops a file. A new npm import in an
   upstream bump fails until the tool has a stub for it.
6. Tool 5 (`test:cases`, phase 2) runs `test/specs/echarts/` and `test/specs/zrender/` with the
   JSON reporter and `--exclude-tags fixtures`. It reports each case as `passed`, `failed`,
   `skipped(<reason>)` or `missing`. It fails on an unknown name, on a bad skip reason and on
   a case of a ported file with no Dart test.
7. Tools 5, 6 and 8 key the cases by project. Their move to `port_tools` follows ADR 0008 item 8.
   The ECharts config gives no harness package.

### 10. Reference generators (gate 5)

The upstream specs carry their expected values inline. They need no generator. Port-only reference
tests need JS values. These rules apply to them:

1. **Engine.** Reference values come only from an x64 build of Node.js v24.12.0, as Chart.js ADR
   0032 §2 states. They never come from a browser or from an arm64 build. On Apple silicon, the
   darwin-x64 build runs under Rosetta.
2. **Place.** The generators are in `packages/flutter_echarts_port/tool/reference/`. Each stops
   unless `process.arch` is `x64`. Each output records the Node.js version, the V8 version and the
   architecture. Do not edit a generated file by hand.
3. **Pins.** A generator stops unless these conditions hold:
   - the gitlinks of `third_party/echarts` and `third_party/zrender` equal their `commit` in
     `tool/port_sources.yaml`
   - `git status --porcelain` of each submodule is empty
   - `echarts.version`, `echarts.dependencies.zrender` and `echarts.zrender.version` are `'6.1.0'`
4. **Whole-chart generators** load the committed `third_party/echarts/dist/echarts.js`. They need
   no build. They run the chart with no DOM: `init(null, null, {ssr: true, renderer: 'svg', width,
   height})`, as `test/node/ssr.js:20-25`.
   - Before the first `init`, the generator writes the env values of
     [ECharts ADR 0007](0007-environment-host-and-input-events.md) into the exported `env` object.
   - The Dart reference test calls `init` with `ssr: true` too. Thus the branches of the Context
     that read `ssr` take the same path on both sides.
   - With no DOM, zrender measures with the fallback branch of `platform.ts:76-92`. The Dart test
     installs the same branch. Thus the layouts match with no font.
   - Some observations need a DOM in Node.js, for example the tooltip content or an event. They
     wait for a probe of a stub element and a mock canvas through `setPlatformAPI`. Phase 5 runs the
     probe. A new ECharts ADR records its result.
5. **Module-level generators** observe files that the dist does not export, for example
   `scale/Interval.ts`. They load `src/**/*.ts` of both pins with `module.stripTypeScriptTypes` and
   module hooks. The hooks resolve the specifiers without an extension. They map `zrender/src/` to
   `third_party/zrender/src/`. They define `__DEV__`. A type-only name in a plain `import {X}` can
   fail the ESM link. The hook then drops the names that the target module does not export.
   - The fallback is the Chart.js method: a clone outside the repository at the pinned commit,
     `npm ci` and a build. The generator stops unless the clone is at the `commit` with a clean
     `src/`.
6. **Determinism.** Both sides run with:
   - a frozen clock. The generator replaces `Date.now`. The Dart test runs its body in `withClock`.
     With a frozen clock, the progressive loop at `src/core/echarts.ts:694` finishes in one frame.
     No hack of the source is necessary.
   - frames of 16 ms when a case steps the time.
   - a port-only seeded random source for `Math.random` and `jsMathRandom`. It is a 32-bit
     xorshift generator (Marsaglia, 2003). It is an algorithm, not copied code. Both sides
     implement it. The port does not port seedrandom.
   - `animation: false`, or the end state of the animation.
   - `TZ=UTC` in the generator and the zone `Etc/UTC` in the Dart test.
7. **Observations.** A reference case can compare these values:
   - `getOption()` (the merged option)
   - the extent and the ticks of each axis of the model
   - `convertToPixel`, `convertFromPixel` and `containPixel`
   - the zrender display list of `getZr().storage.getDisplayList(true)`: for each displayable its
     type, id, name, `z`, `z2`, `zlevel`, transform, shape, style keys, text, `invisible`,
     `ignore` and `silent`
   - later, the canvas calls of the mock context and the string of `renderToSVGString()`
     ([ECharts ADR 0006](0006-renderer-and-canvas-layer.md), phase 10)
8. **Tolerance.** A number compares at 1e-9 absolute, or at 1e-12 relative above 1e3. A list
   compares in order. A string, a name and a hit compare exactly. These are the rules of Chart.js
   ADR 0030.
9. **Size.** A data file has at most 2.5 MB. A generator with more data writes more files.

### 11. The visual pages (gate 6)

1. **No screenshots.** The port compares no image with Chrome. Upstream commits no reference
   image. Its tolerance holds only for one engine. Chrome and Flutter differ in text raster,
   hints, fonts and antialias. This is the rule of Chart.js ADR 0034 §4.
2. **Extraction.** Tool 4 also reads the 605 ECharts pages (phase 6). It runs the scripts of each
   page in a Node.js `vm` context with these stubs:
   - an AMD `require`: `echarts` is the pinned dist in the mode of section 10 item 4. The modules
     `data`, `map`, `geoJson`, `theme` and `i18n` read the files of the pin.
   - a `document`, a `$`, a `testHelper.create` and an `echarts.init` that record the DOM id, the
     title, the size, the option and each later `setOption` call
   - the seeded random source and a frozen clock at 1566458693300 (`runtime/timeline.js:28`)
3. Tool 4 writes the pure-data options into `doc/upstream/fixtures.json`. The manifest records the
   SHA-256 of each page.
   - Tool 4 does not inline a value that a page loads from `test/data/**`. Such values come from
     the AMD modules `data`, `map` and `geoJson`, and from `$.get` and `$.getJSON`. ECharts ADR
     0001 item 16 keeps these files out of the package.
   - `fixtures.json` records such a value as
     `{"$upstreamData": "test/data/<path>", "sha256": "<hex>"}`. The smoke runner reads the file
     from the submodule on the VM. It compares the SHA-256 with the record.
   - Each file of `doc/upstream/` has at most 2.5 MB, the limit of section 10 item 9. A larger
     `fixtures.json` splits into more files.
4. **Smoke runner.** The runner has the form of Chart.js tool 7:
   - one test for each extracted chart, with the tag `fixtures`
   - the melos script `test:fixtures`, the CI job `fixtures` and `FIXTURES_REQUIRED=1`
   - the test builds the chart on an `EChartsContainer` of the recorded size. It applies the
     recorded `setOption` calls. It paints one frame through the `dart:ui` implementation of the
     Canvas 2D interface. It passes when no step throws.
   - the runner compares the SHA-256 of each page in the submodule with the manifest. A
     difference fails the test.
   - without the submodule, each test skips as
     `'n/a: the submodule third_party/echarts is not checked out'`. With `FIXTURES_REQUIRED=1`, it
     fails.
   - the runner reads the submodule. Thus each smoke test file has `@TestOn('vm')`.
5. **Hand ports.** A chart whose option holds a function gets a hand port
   `test/fixtures/hand/<path>.dart` with the header of
   [ECharts ADR 0001](0001-upstream-sources.md). `test/fixtures/index.dart` is the registry of the
   hand ports and the skips.
6. **Skips.** The 16 pages and the 8 SVG pages of `test/runTest/blacklist.js` skip as
   `'n/a: blacklisted upstream'`. A page that needs `extension/`, ecStat or bmap skips as
   `'n/a: <reason>'`. A page that needs a file that is not ported skips as `'blocked: <file>'`.
   Phase 6 gives the skip list.
7. **Structural references.** A curated subset gets the reference tests of section 10: one chart
   for each chart type and each major component. The set does not cover all pages.
8. **Actions.** The 271 action files wait for a later ECharts ADR. Their coordinates need the
   Chrome layout of `testHelper`.
9. **Image report.** An optional report can put Chrome screenshots of the pinned dist beside
   Flutter goldens of the port. It reports the `diffRatio`. It never fails a gate.
10. The zrender pages have no extraction. They hold no option data.

### 12. No harness package now

1. The harness is in `test/support/`. It is pure, except the smoke runner of section 11.
2. ECharts has no upstream harness package. `utHelper.ts` and `extendExpect.ts` belong to the
   ECharts repository.
3. The name `echarts_test_utils` is reserved ([ADR 0007](../../../../docs/adr/0007-package-names.md)
   item 3). pub.dev gave 404 for it at 2026-10-21T07:51Z
   ([ECharts ADR 0001](0001-upstream-sources.md)).
4. The harness moves into that package when one of these conditions occurs:
   - A second package needs the harness, for example `apps/echarts_gallery` or a design-system
     adapter.
   - The harness needs `flutter_test` as a regular dependency.
5. A new ECharts ADR records the move.

## Alternatives considered

- **Chart specs as `testWidgets` (the Chart.js form).** Rejected. The specs need no layout, no
  pixels and no DOM event. The pure form runs all 259 cases on dart2js and dart2wasm too. Chart.js
  ADR 0022 needed `testWidgets` because its harness ported a DOM.
- **`package:test` matchers by hand.** Rejected. `equals` hides the sign of −0 and fails for NaN.
  Each hand translation can weaken an assertion. The reviewer cannot compare the files line by
  line (D3 ADR 0004).
- **Liberation Sans widths in the specs.** Rejected. The upstream specs ran with `text.length`.
  Their expected layout values hold only for the mock widths. Another width fails cases that pass
  upstream.
- **The zrender fallback widths for the ECharts specs.** Rejected. Upstream ran the ECharts specs
  with jest-canvas-mock, not with the fallback branch.
- **node-canvas images as references.** Rejected. Upstream does not use node-canvas. It draws with
  Cairo, not with the engine of Chrome. It needs a native build.
- **A port of seedrandom.** Rejected. The port compares no upstream image. Thus it needs no
  seedrandom sequence. A port also adds a notice.
- **Chrome screenshots as a gate.** Rejected. Chrome and Flutter raster text in different ways.
  The upstream tolerance holds only for one engine (Chart.js ADR 0034 §4).
- **A fake clock for the two `Promise` cases.** Rejected. It changes the text of the cases. The
  real wait is about 300 ms in all.
- **A harness package now.** Rejected. It adds a workspace entry, a commit scope and a pubspec. It
  adds the cycle of a library and its harness, as in the Chart.js port.
- **A static reader of the case names.** Rejected. Loops make 31 of the 259 cases at run time.
- **Generator runs on the arm64 build.** Rejected. Chart.js ADR 0032 found last-bit differences
  between the arm64 and the x64 builds.

## Consequences

- The specs port line by line. A reviewer compares the Dart file with the upstream file side by
  side.
- Phase 1 adds `test/support/jest_expect.dart`, `test/support/spec_setup.dart`,
  `test/support/echarts/extendExpect.dart` and the stand-in tests in `test/port/support/`.
- Phase 1 adds `flutter_echarts_port` to `test:web`.
- Phase 2 adds tool 4 and tool 5 with the manifest of two projects.
- Phase 3 adds `canvas_mock.dart`. Phase 5 adds `utHelper.dart`, `harness_events.dart` and the
  first whole-chart generator.
- Phase 6 adds the extraction, `fixtures.json`, the smoke runner and the CI job `fixtures`.
- The two-state null rule weakens a few assertions that tell `null` from `undefined`. Examples are
  `util/model.test.ts:149` and `component/graphic/setOption.test.ts:765-766`. Such a case passes
  in the port when it passes upstream.
- The reference generators need the darwin-x64 build of Node.js v24.12.0. The machine has only
  the arm64 build on 2026-10-21.
- The module-level generators carry a risk: Node.js can fail to strip a type-only import. The
  fallback is a built clone outside the repository.
- The two `ElementAnimation` cases wait about 300 ms of real time on each leg.
- The whole-chart references cover only the `ssr: true` path on a frozen clock. No reference runs
  the branches that `ssr` turns off: `src/core/echarts.ts:808`, `src/model/Series.ts:552`,
  `src/chart/line/LineView.ts:653`, `src/chart/pie/PieView.ts:81` and
  `zrender src/zrender.ts:123-153`. No reference runs progressive painting across frames either.
- Port-only tests with a stepping fake clock cover these branches in the phase of each file
  (phases 3 to 6). A step of 16 ms for each `getTime()` call stops the 15 ms budget of
  `zrender src/canvas/Painter.ts:674-686` after one element.

## Evidence

- The runners: `package.json:57` and `test/ut/jest.config.cjs:22-54` of ECharts,
  `package.json:27` and `test/ut/jest.config.js:1-11` of zrender, the `package-lock.json` entries
  of `jest`, `ts-jest`, `jsdom`, `jest-canvas-mock` and `typescript`.
- The mock widths: `lib/classes/TextMetrics.js:24` and
  `lib/classes/CanvasRenderingContext2D.js:767-776` of the npm tarball of jest-canvas-mock 2.5.0.
- The fallback widths: `zrender src/core/platform.ts:33-109` and
  `test/ut/spec/core/platform.test.ts:37-39`.
- The case counts: the probe of the planner notes. It evaluated the 36 spec files with
  `module.stripTypeScriptTypes` and stub imports on Node.js v24.12.0 (arm64).
- The line counts: `git ls-files test/ut/spec` and `wc -l` at the pins.
- The matcher counts: `grep -rhoE '\.(not\.)?to<Name>\('` over the spec files at the pins.
- The page counts: `git ls-files 'test/*.html'`, then `grep -l` and `grep -o` over the pages.
- The runner: `test/runTest/cli.js`, `compareScreenshot.js`, `store.js`, `util.js`,
  `blacklist.js`, `runtime/main.js` and `runtime/timeline.js` at the ECharts pin.
- The release build: `dist/echarts.js` at the ECharts pin, read with `grep -n`.
