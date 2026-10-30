<!-- Original code, not ported from Chart.js: the guide of the upstream page of the P3 comparison. -->

# The upstream page of the P3 comparison

This folder holds the upstream side of the P3 comparison: Chart.js at the pin (V8) against the port
(dart2wasm) in the same browser ([performance.md](../../../doc/performance.md) §14.9,
[Chart.js ADR 0053](../../../doc/adr/0053-resolver-fast-paths.md)). The page of §14.9 was a working
file of phase 8 and is lost. This page replaces it (a decision of the porting lead, 2026-10-30), so
that P3-base and P3-final of ADR 0053 run from the repository.

The page runs the cases of `apps/chartjs_gallery/lib/bench/chart_bench.dart` that have an upstream
form. Each case has the config, the data, the steps and the timing loop of its Dart case. Nothing in
`lib/` or `test/` reads this folder.

## Files

| File | What it does |
|---|---|
| `cases.js` | The cases, the selection and the timing loop: the JS form of `chart_bench.dart`. It has no import: its caller gives the Chart.js values. |
| `bench.js` | The browser driver: it loads the dist, registers `registerables`, reads `field.json` and `build.json`, runs the selected cases and posts each line. |
| `bench.html` | The page. Its import map gives `@kurkle/color`. |
| `serve.mjs` | The local server: the page, the dist of the build, `@kurkle/color`, `field.json`, `/build.json` and `POST /log`, with the headers of cross-origin isolation. |
| `field_gen.dart` | Writes `field.json`, the start values of `StressPointField(20000)`. |
| `.gitignore` | `field.json` and `logs/` are build outputs. |

The dist of Chart.js stays in its build folder. The server reads it from there.

## The steps

All commands run from `packages/flutter_chartjs_port`.

1. **Build the dist at the pin.** The steps of the header of
   `tool/reference/scale_chart_common.mjs`: a clone of Chart.js outside the repository at the
   `commit` of the Chart.js entry of `tool/port_sources.yaml`, then
   `corepack pnpm install --frozen-lockfile` and `corepack pnpm exec rollup -c`. At `v4.6.1`
   (`76d8cf89`) the SHA-256 values are: `dist/chart.js`
   `5a059a341daded15d6333d1bda10f5d990c9458c4ef7f222a5b11c45913cd0df`, `dist/chunks/index.js`
   `7f8e207fc91dada433bd757fba6c551bc347305f2fddc9e3fdb4232edb8890cd` (the values of the header of
   `scale_chart_common.mjs`) and `dist/helpers.js`
   `2adc5d2ae63bf4f0dfba5cf433186d5fb7954d9726dea6ef6e3a1992fa412f8a`.
2. **Write the field.**
   `dart run tool/reference/p3_page/field_gen.dart tool/reference/p3_page/field.json`.
   The file has the SHA-256 `860d43d547e5371ec663fc3a12596dbe42bb1005234246e7e390876fe5b8b741`
   (Dart 3.13.5), the same bytes as the field of the step 7 page of phase 7.
3. **Serve the page.**
   `CHARTJS_DIST=<build>/dist/chart.js node tool/reference/p3_page/serve.mjs --port 8123 --log-dir <dir>`.
   The server stops unless the build is a clean checkout at the pinned commit with the release of the
   pin in its `package.json`. It prints the page URL, the SHA-256 of each dist file and of the field,
   and the log folder. The defaults are the port 8123, the field `tool/reference/p3_page/field.json`
   and the log folder `tool/reference/p3_page/logs/`.
4. **Run.** Open the URL in a visible tab of the dedicated Chrome of the night kit, with the query
   parameters below and `autostart=1`, or call `window.startBench()`. The driver waits for a frame
   before each case, so a hidden tab stops at the first case. Load `about:blank` before and after
   each run, as §14.9 does.

The URL of a run:

```text
http://127.0.0.1:8123/bench.html?cases=<selectors>&n=<counts>&run=<tag>&autostart=1
```

| Parameter | Default | The Dart define |
|---|---|---|
| `cases` | the cases that are not explicit | `CASES` |
| `n` | the counts of each case | `N` |
| `batches` | 15 | `BATCHES` |
| `batchMs` | 200 | `BATCH_MS` |
| `warmupMs` | 1000 | `WARMUP_MS` |
| `run` | `manual` | (the log file `<tag>.txt`) |

## The output

Each line goes to the console and to `POST /log?run=<tag>`. The server appends it to
`<log dir>/<tag>.txt`.

- `FIELD {json}`: the check of the field. The page runs 120 steps of 1/60 s of the first 5000 points
  and compares the sums with the sums of `field_gen.dart`. `equal` must be true.
- `ENV {json}`: the user agent, `crossOriginIsolated` (must be true), the device pixel ratio, the
  settings, `Chart.version` and the build of `/build.json` (the version, the commit and the SHA-256
  of each dist file).
- `BENCH {json}` for each case and N, with the keys of `runChartBenchCase`: `mode`, `case`, `n`, the
  keys of the case, `call`, `primary` (when the case names it), `iterations`, `notifies`, the figures
  `updateMedianMs` / `P10Ms` / `P90Ms` (not for a draw), `draw…`, the parts (for example
  `layoutMedianMs`), `batches`, `batchIterations`, `batchMs`, `warmupMs`, `warmupIterations`,
  `width`, `height`, `dpr`, `build`, `platform` (`browser`), `startMs` and `wallMs`.
- `BENCH done` at the end, or `BENCH error <stack>`.

The differences from the Dart BENCH line:
- No `end` figures. A browser canvas has no picture recording. The upstream frame is
  `update + draw`; the port frame of §14.9 is `update + draw + end`.
- `build` names the Chart.js build, and `platform` is `browser`.

## The rules of the cases

- **Platform.** The Dart chart of a case has no host, so the port gives it the `BasicPlatform`. A
  case with animations has the `_AnimatedPlatform` of the Dart benchmark (a `BasicPlatform` with the
  no-op `updateConfig` of `BasePlatform`). The page gives each chart the same platform class:
  `BasicPlatform`, or `AnimatedBasicPlatform`. Thus no DOM listener and no style set-up of
  `DomPlatform` runs.
- **Components.** `Chart.register(...registerables)`, as `src/index.umd.ts:28` and
  `registerGalleryComponents` do. The page does not change `Chart.defaults`: the colors plugin keeps
  its default, as in the gallery.
- **Events.** `_benchEvent` sends an event to the event handler of the chart at once. The page builds
  the chart event of `fromNativeEvent` (`platform.dom.js:109-118`) with `getRelativePosition` of the
  dist and calls `chart._eventHandler`. No listener and no throttle runs.
- **Ticks.** `_benchTick(date)` is `animator._update(date)`. The end of the animations is two ticks
  one hour after `Date.now()`.
- **Loop.** `runChartBenchCase` and `_Loop`: a warm-up for `warmupMs`, a calibration, then
  `batches` batches of about `batchMs` each. A batch figure is the mean of its iterations. A motion
  iteration calls `chart.stop()` outside the timing and then `chart.update()`.

## The cases and the cells

The selectors are the selectors of `lib/main_bench.dart`: a mode, a name or both (`chart`,
`tooltip.fade`). An explicit case runs only when its full id is in the list.

| Group | Cases | Counts | Cells |
|---|---|---|---:|
| `chart.a`, `chart.b` (line, scatter), `chart.c` | 4 | 1000, 5000, 20000 | 12 |
| `chart.<type>` draw and update: `bar`, `bubble` | 4 | 1000, 5000, 20000 | 12 |
| `chart.<type>` draw and update: `doughnut`, `pie`, `polarArea`, `radar` | 8 | 100, 1000, 5000 | 24 |
| `plugins.line` configs A and B, 3 and 100 datasets, draw and update | 8 | 1000 (3 datasets), 100 (100 datasets) | 8 |
| `tooltip.hover`, `tooltip.still` (each with and without the tooltip), `tooltip.fade`; 3 and 10 datasets | 10 | 100, 1000 | 20 |
| `fill.gaps`, `fill.stack`, `fill.radar`, draw and update | 6 | 100, 1000 | 12 |
| `legend.line` (legend on and off), `title.line`, draw and update | 6 | 100, 1000 | 12 |
| **The cells of §14.9** | **46** | | **100** |
| `motion.line`, `motion.bar` | 2 | 1000, 20000 | 4 |
| Explicit: `motion.line.delay` | 1 | 1000, 20000 | 2 |
| Explicit: `chart.c.indexable`, `chart.line.primitive` | 2 | 1000, 5000, 20000 | 6 |

The selection `chart,plugins,tooltip,fill,legend,title` gives the 46 cases of the 100 cells of
§14.9 (48 cells of phase 7 and 52 plugin cells). The page has no form of these Dart cases:
- the mode `axes`: no cell of §14.9, and the time scale needs a date adapter;
- the mode `theme`: the theme switch of `ChartView` (Chart.js ADR 0050) has no upstream form.

## The checks of 2026-10-30

No timed run. With the dist of `v4.6.1` above and the field above:
- Node.js v24.22.1 with a no-op canvas: each of the 51 cases ran once at N 50 with `batches=1`,
  `batchMs=10` and `warmupMs=0`. The `FIELD` sums were equal.
- The VS Code browser (Chromium 150.0.7871.250): the page loaded with `crossOriginIsolated` true and
  `FIELD` equal, and each of the 51 cases ran once at N 50 with `getRelativePosition` of the dist.
- The `notifies` count of each of the 51 cases at N 50 was equal to the count of its Dart case
  (`runChartBenchCase` in `flutter test`). This count follows the plugins, the hooks and the steps of
  a case, so the two sides run the same plugin work.
