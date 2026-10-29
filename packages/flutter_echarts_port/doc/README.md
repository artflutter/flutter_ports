# ECharts port

`packages/flutter_echarts_port` is a native Dart port of [Apache ECharts](https://echarts.apache.org)
and of its renderer [zrender](https://github.com/ecomfe/zrender). The port translates the ECharts
modules to Dart: the option model, the data store, the scales, the coordinate systems, the series,
the components and the layouts. It also translates zrender: the display list, the elements, the
animation, the hit tests and the canvas painter. Flutter draws the zrender layers with its own
canvas. The port has no WebView and runs no JavaScript. The reasons for this approach, and the
packages that already exist, are in the [prior art](prior-art/README.md) and in
[ADR 0001](../../../docs/adr/0001-native-ports-not-wrappers.md).
[ADR 0007](../../../docs/adr/0007-package-names.md) (accepted 2026-10-22) gives the name form
`flutter_<library>_port`. The name `flutter_echarts` is taken on pub.dev by a WebView wrapper.
[ECharts ADR 0001](adr/0001-upstream-sources.md) records the name (ADR 0007 item 9).

- **Upstream:** Apache ECharts **6.1.0** (2026-05-13), Apache-2.0, and zrender **6.1.0**
  (2026-05-04), BSD-3-Clause. Each repository is a shallow git submodule
  ([ADR 0005](../../../docs/adr/0005-pin-upstream-sources.md),
  [ECharts ADR 0001](adr/0001-upstream-sources.md)):
  - `third_party/echarts` at the tag `6.1.0`, commit `c5a48f5f`.
  - `third_party/zrender` at the tag `6.1.0`, commit `32b66867`. The ECharts `package.json:77`
    requires this exact version (`"zrender": "6.1.0"`).
  - The tags have no `v` prefix. A commit pin writes `6.1.0+<sha8>`.
  - `echartsVersion` and `zrenderVersion` in `lib/src/upstream.dart` name the two versions.
    [`tool/port_sources.yaml`](../tool/port_sources.yaml) names the tag and the commit of each
    repository.
  - `dart run melos run upstream` clones the submodules. `dart run melos run upstream:check`
    compares the gitlinks with the pins.
  - Backports and commit pins follow
    [ADR 0006](../../../docs/adr/0006-follow-upstream-between-releases.md).
- **Progress:** [parity.md](parity.md), with one row for each directory in phase 0.
- **Differences:** [differences.md](differences.md), one row for each `DIVERGES` difference. It
  has no rows in phase 0.
- **Upstream after the pins:** [upstream-ledger.md](upstream-ledger.md) lists the upstream commits
  after each pinned tag. It has one section for each repository.
- **Porting flow:** [porting-flow.md](porting-flow.md) (proposed) gives the life cycle of one
  file, the decisions, the test harness, the tools and the phases.
- **Prior art:** [prior-art/](prior-art/README.md), the ECharts packages for Dart and Flutter and
  the ports in other languages. They are prior art only, not sources (AGENTS.md rule 1).
- **Gallery:** `apps/echarts_gallery`, from phase 6.
- **Test harness:** in `test/support/`. The harness package name `echarts_test_utils` is reserved.
  [ECharts ADR 0005](adr/0005-spec-harness-and-reference-tests.md) gives the triggers that create
  it.
- **License:** the code of the port is Apache-2.0, as upstream ([LICENSE](../LICENSE)).
  [NOTICE](../NOTICE) keeps the ECharts notice unchanged. ECharts ADR 0001 lists the other license
  components: zrender, the d3 code in five ECharts files, the ASF code in one zrender file,
  node-timsort, jsdiff and tween.js. The five d3 files are the four of the ECharts `LICENSE` and
  `src/scale/Time.ts`. Each component comes with the change that ports its first file.

## What gets ported

| Upstream (at the pins) | Files | Lines | Cases |
|---|---:|---:|---:|
| ECharts `src/` (`.ts`, with `global.d.ts`) | 596 | 138,275 | — |
| zrender `src/` (`.ts`, with `global.d.ts`) | 120 | 31,449 | — |
| ECharts specs `test/ut/spec/**/*.test.ts` | 24 | 9,274 | 191 |
| zrender specs `test/ut/spec/**/*.test.ts` | 12 | 1,042 | 68 |
| ECharts harness `test/ut/core/utHelper.ts` and `extendExpect.ts` | 2 | — | — |
| ECharts visual test pages `test/*.html` | 605 | — | — |

[parity.md](parity.md) gives the counts of each directory, the count script and the notes. The
cases are run-time counts of the jest cases. Loops make more cases than the static `it(` sites.

- The two `src/` folders have 716 files with 169,724 lines (`wc -l`).
- Each ECharts source file has an 18-line ASF license comment. The line counts include it.
- 10 ECharts spec files with 102 cases are pure. 14 ECharts spec files with 89 cases build a
  chart with `createChart` (`test/ut/core/utHelper.ts`). All 12 zrender spec files are pure.
- The port keeps all of `lib/src/echarts/` and `lib/src/zrender/` pure. Thus all 259 cases run
  on `package:test` on the VM, with dart2js and with dart2wasm
  ([ECharts ADR 0005](adr/0005-spec-harness-and-reference-tests.md)).
- The visual test pages are not specs. Upstream compares them as images of two builds. The port
  runs their charts as smoke tests from phase 6 (ECharts ADR 0005). zrender has 76 more pages.
- The port does not port these parts ([ECharts ADR 0001](adr/0001-upstream-sources.md)):
  `extension-src/`, `build/`, `ssr/client/`, the root `i18n/*.js` files (the build output of
  `src/i18n/`), `test/runTest/`, `test/types/`, `test/data/` and the npm test tools. `dist/` is
  input for the reference generators only. The 36 theme files directly in `theme/` are optional
  data for a later phase. `git ls-files 'theme/*.js'` gives 43 `.js` files with the subfolders.
  The 7 other files are in `theme/tool/`, the theme thumbnail tool. The port does not port them.
- All 36 themes and the 27 `src/i18n/*.ts` locales carry the ASF license comment. Thus they add
  no license component.

## How a file is ported

1. Translate from the pinned upstream file. Do not translate from memory, from upstream `master`
   or from another port (AGENTS.md rule 1). Keep the upstream structure and names (Dart-cased).
   Then a bump can replay the upstream changes file by file.
2. Put the Dart file at its mapped path
   ([ECharts ADR 0002](adr/0002-file-naming-and-layout.md)):
   - `third_party/echarts/src/<p>.ts` goes to `lib/src/echarts/<p>.dart`.
   - `third_party/zrender/src/<p>.ts` goes to `lib/src/zrender/<p>.dart`.
3. Start the Dart file with the header block
   ([ECharts ADR 0001](adr/0001-upstream-sources.md)):
   1. line 1 names the source, the license and the holder, for example
      `// Ported from Apache ECharts 6.1.0 src/util/number.ts (Apache-2.0, The Apache Software Foundation).`
      or `// Ported from zrender 6.1.0 src/core/matrix.ts (BSD-3-Clause, Baidu Inc.).`
   2. zero or more backport lines, for example
      `// Upstream backport: apache/echarts@<sha8> (#<PR>).`
   3. `// ignore_for_file: file_names` when the file name fails the lint.
   4. the upstream license comment block, unchanged, when the upstream file has one.
   - A file with no upstream source starts with
     `// Original code, not ported from Apache ECharts: <reason>.`
   - Code from another license component adds its notice to the package `LICENSE` and to
     `REUSE.toml` ([AGENTS.md](../../../AGENTS.md#licensing)).
4. Port the upstream spec of the file to `test/specs/echarts/<p>_test.dart` or
   `test/specs/zrender/<p>_test.dart`
   ([ECharts ADR 0005](adr/0005-spec-harness-and-reference-tests.md)). Behavior without an
   upstream spec gets port-only tests in `test/port/echarts/` or `test/port/zrender/`.
5. Update the row in [parity.md](parity.md) in the same change. From phase 2, update
   `doc/status.yaml` and run tool 6. Tool 6 writes `parity.md`.

[porting-flow.md](porting-flow.md) §1 gives all steps.

## Roadmap

**Status (2026-10-21).** Phase 0 is in progress. The port has no ported file yet.

The phases follow the import graph of the two `src/` folders. No file has a value import of a
file of a later phase. The Files, Lines and Cases columns count the upstream source files, their
`wc -l` lines and the upstream spec cases of each phase ([parity.md](parity.md#by-phase)).

| Phase | Files | Lines | Cases | Scope | Exit criteria |
|---|---:|---:|---:|---|---|
| 0. Scaffold and design | 0 | 0 | 0 | Package, two submodules, `port_sources.yaml`, the two version constants, `upstream_test.dart`, pin checks, `LICENSE`, `NOTICE`, `REUSE.toml`, docs, prior art, ECharts ADRs 0001-0009 (proposed), commit scope, workspace and CI entries. No change in the Chart.js packages and app | CI green. `upstream:check` passes for the Chart.js, D3 and ECharts pins. The root `pubspec.lock` does not change |
| 1. Decisions, tooling, pilot | 5 | 2,178 | 39 | ECharts `util/number.ts` and zrender `core/vector.ts`, `matrix.ts`, `util.ts`, `platform.ts`. The jest `expect` stand-in and `setUpSpecs()`. Stage 1 of ADR 0008 with an ECharts config. The `JsDate` subset and the zone files of ECharts ADR 0008 §3. The zrender and d3 license components | The 39 cases pass on the VM, dart2js and dart2wasm. Tools 1-3 green for ECharts with the Chart.js outputs unchanged. The number strings match x64 Node.js v24.12.0 reference strings. `reuse lint` passes |
| 2. Foundations | 88 | 26,564 | 39 | The renderer-free ECharts files of `util/`, `data/`, `scale/`, `model/`, `visual/`, `processor/`, `preprocessor/`, `core/`. The rest of zrender `core/`, `config.ts`, `tool/color.ts`. `partial:` ports of forward types. Tools 4, 5, 6 and 8. The node-timsort, jsdiff and `OrientedBoundingRect.ts` license components. fdlibm `acos` and `tan` | The 39 cases pass on three legs. `test:cases` finds a Dart test for each case of a ported file. Tool 6 writes `parity.md`. The manifest lists 191 and 68 cases |
| 3. Renderer (zrender) | 71 | 18,835 | 34 | zrender `Element`, `Storage`, `Handler`, `zrender.ts`, `animation/`, `graphic/`, `contain/`, `canvas/`, five `tool/` files, `svg/helper.ts`. The Flutter handler proxy. The Canvas 2D layer and the frame hook. The tween.js component. The test font, the text-metric probe and `doc/performance.md` with the large-data benchmark | The 34 cases pass on three legs. Reference tests of zrender scenes on a recorder canvas pass. A Flutter test paints a scene against its own golden. Widget tests show the zrender event names. `doc/performance.md` has the figures of the large-data benchmark |
| 4. Data and model | 47 | 19,034 | 53 | `Model`, `Component`, `Series`, `Global`, `SeriesData`, `Tree`, the `Interval`, `Log` and `Time` scales, the axis base of `coord/`, `label/`, `util/format`, `util/time`, `core/locale`, `langEN`, `langZH`. The other `JsDate` methods. The d3 `REUSE.toml` path of `scale/Time.ts` | The 53 cases pass on three legs in `Etc/UTC` and `America/Los_Angeles`. The `JsDate` methods are in `js_semantics` with their tests |
| 5. Core (the update pipeline) | 10 | 5,397 | 0 | `core/echarts.ts`, `core/Scheduler.ts`, `view/`, `extension.ts`, `loading/default.ts`, `theme/dark.ts`. `EChartsContainer`, `EChartsHost`, `createChart`, the base of the whole-chart generators | `init`, `setOption`, `resize` and `dispose` run on the pure harness container. A widget test mounts `EChartsHost` and paints. A whole-chart generator runs under x64 Node.js and its data loads in a Dart test |
| 6. First charts and the gallery | 117 | 26,274 | 0 | line, bar, scatter, pie. The axis and axis pointer components. Cartesian and polar coordinates. Dataset, grid, polar, title, legend, tooltip, aria. `layout/`, `export/`, `src/echarts.ts`, the canvas renderer install. The visual smoke runner. `apps/echarts_gallery`. The frame figures of the gallery in `doc/performance.md` (phase 3 creates the file) | Whole-chart reference tests of a curated set pass. The smoke pages of the ported files pass or skip with a valid reason. The gallery builds for Android, iOS, web (wasm) and macOS, with the chart above the fold at 412 x 915. `doc/performance.md` has the frame figures |
| 7. More cartesian and polar series, markers, graphic | 105 | 19,629 | 0 | boxplot, candlestick, effectScatter, heatmap, lines, custom, gauge, funnel, themeRiver, pictorialBar. Markers, graphic, transforms, single axis, axis breaks | Reference tests of each new series type pass. Their smoke pages pass or skip with a valid reason |
| 8. Other coordinate systems, hierarchy, graph and geo | 128 | 26,687 | 5 | radar, parallel, calendar, geo and map, matrix. Tree, treemap, sunburst, graph, sankey, chord. `RoamController`, `BrushController`. The zrender files `parseSVG.ts` and `parseXML.ts`. The d3 notices of the three phase 8 files | The 5 cases pass. Reference tests of each layout pass with a seeded random source. GeoJSON and SVG maps from the fixtures of ECharts ADR 0009 §7 item 8 register and draw in reference tests |
| 9. Interaction and transitions | 84 | 15,866 | 83 | dataZoom, brush, toolbox, visualMap, timeline, scroll legend, thumbnail. Universal transitions. `echarts.simple.ts` | The 83 cases pass or skip with a valid reason. Roam, slider and brush gestures work in widget tests. Transitions pass under a fake clock |
| 10. Release set and 0.1.0 | 61 | 9,260 | 6 | `echarts.all.ts`, `echarts.common.ts`, `echarts.blank.ts`, the `export/` bundles, 25 more locales, the SVG renderer install, the zrender SVG string painter. The public Flutter API. The release models of `js_semantics` and of the shared Canvas 2D layer. The pana score | All 259 cases pass or skip with a valid reason. `renderToSVGString` matches x64 Node.js SSR strings for the curated set. `flutter_echarts_port` 0.1.0 on pub.dev |
| **Total** | **716** | **169,724** | **259** | | |

The order follows the runtime dependencies of the files and the environment that they need:
- The pilot comes first. It tests the shared runtime and the tools on five small files.
- Pure data and the zrender renderer come before the update pipeline. The charts come after it.
- The 14 chart spec files import `test/ut/core/utHelper.ts`. This helper imports
  `src/echarts.all.ts`. Thus the roadmap counts their cases in phases 9 and 10. A chart case can
  pass earlier, when the files that its options name are ported.
- A case that needs a file of a later phase skips as `'blocked: echarts/src/<path>.ts'` or
  `'blocked: zrender/src/<path>.ts'`.

## Decisions

The decisions for all ports are in [docs/adr/](../../../docs/adr/). The ECharts ADRs are in
[adr/](adr/). New ADRs start as proposed. The porting lead (the agent that runs the phase) owns
the ADR statuses (AGENTS.md, the maintainer, 2026-10-21). It accepts an ADR when the phase
implements the decision and its gates are green. The maintainer selects only the package name of
ADR 0007 item 9 and the four points of ECharts ADR 0001 item 1. An accepted ADR does not change. A
changed decision gets a new ADR that supersedes the old ADR.

Cross-port ADRs that apply to this port:
- [ADR 0001: Native ports, not wrappers](../../../docs/adr/0001-native-ports-not-wrappers.md)
  (accepted)
- [ADR 0005: Pin upstream sources](../../../docs/adr/0005-pin-upstream-sources.md) (accepted)
- [ADR 0006: Follow upstream between releases](../../../docs/adr/0006-follow-upstream-between-releases.md)
  (accepted)
- [ADR 0007: Package names](../../../docs/adr/0007-package-names.md) (accepted 2026-10-22. It
  supersedes ADR 0003)
- [ADR 0008: Shared JS runtime and port tools](../../../docs/adr/0008-shared-js-runtime-and-port-tools.md)
  (proposed)

ECharts ADRs (all proposed, 2026-10-21). The gate is the first phase whose code depends on the
ADR:

| ADR | Title | Gate |
|---|---|---|
| [ECharts ADR 0001](adr/0001-upstream-sources.md) | Upstream sources | 0 |
| [ECharts ADR 0002](adr/0002-file-naming-and-layout.md) | File naming and package layout | 1 (forward types: 2) |
| [ECharts ADR 0003](adr/0003-numbers-and-js-semantics.md) | Numbers, number strings and JS semantics | 1 |
| [ECharts ADR 0004](adr/0004-js-values-classes-and-options.md) | JS values, classes and options | 1 (classes, element access and TS types: 2) |
| [ECharts ADR 0005](adr/0005-spec-harness-and-reference-tests.md) | Spec harness, reference tests and the visual pages | 1 (chart references: 5, smoke runner: 6) |
| [ECharts ADR 0006](adr/0006-renderer-and-canvas-layer.md) | Renderer: the zrender canvas painter on a Canvas 2D layer | 3 |
| [ECharts ADR 0007](adr/0007-environment-host-and-input-events.md) | Runtime environment, chart host and input events | 1 (env and platform API), 3 (handler proxy), 5 (container and host) |
| [ECharts ADR 0008](adr/0008-dates-locales-and-formatting.md) | Dates, time zones, locales and formatting | 4 |
| [ECharts ADR 0009](adr/0009-dom-features-app-hooks-and-theming.md) | DOM-bound features, app hooks and theming | 6 (heatmap: 7, XML: 8, toolbox: 9) |

A Chart.js ADR or a D3 ADR binds only its own port. Thus each ECharts ADR restates the rules that
it takes from them:
- ECharts ADR 0002 takes Chart.js ADRs 0012 and 0023 and D3 ADR 0002.
- ECharts ADR 0003 takes Chart.js ADRs 0032 and 0034 (both accepted 2026-10-21) and D3 ADR 0003.
- ECharts ADR 0004 takes Chart.js ADRs 0006, 0020 and 0021 and D3 ADR 0006.
- ECharts ADR 0005 takes Chart.js ADRs 0022, 0029, 0030, 0032 and 0034 and D3 ADR 0004.
- ECharts ADR 0006 takes Chart.js ADRs 0013, 0015, 0016 and 0019 and D3 ADR 0005.
- ECharts ADR 0007 takes Chart.js ADRs 0016 and 0037 (Chart.js ADR 0037 supersedes Chart.js ADR
  0014). Its event table keeps the stylus kinds of Chart.js ADR 0014 §6 until the ECharts lead
  decides (ECharts ADR 0007, Open).
- ECharts ADR 0008 takes Chart.js ADR 0024 and the D3 decision on dates and time zones. Chart.js
  ADR 0026 does not apply, because ECharts has no `Intl` call.
- ECharts ADR 0009 takes the four theming invariants of Chart.js ADR 0001 and the gallery layout
  rule of Chart.js ADR 0031.

Later decisions have no ADR file yet. [porting-flow.md](porting-flow.md) §2 gives the question,
the facts and a proposal for each:
- The shared Canvas 2D layer: a new root ADR by the method of ADR 0008, proposed before phase 3.
  ECharts ADR 0006 gives the fallback, a port-only `lib/src/canvas/`.
- Stage 1 of ADR 0008, if D3 phase 1 does not come before ECharts phase 1.
- The HTML tooltip overlay, after phase 6.
- The SVG string painter as an earlier reference oracle, after phase 6.
- The replay of the recorded `test/runTest/actions/`, after phase 9.
- The release models of `js_semantics` and of the shared Canvas 2D layer, in phase 10.
- The root `theme/*.js` themes and `extension-src/dataTool`, after phase 10.

## Open questions

The ADRs above are proposed. The porting lead accepts each of them when its phase implements the
decision and its gates are green. [porting-flow.md](porting-flow.md) §7 gives these open questions
with their facts:
1. Does the maintainer select the name `flutter_echarts_port` (ADR 0007 item 9)? The maintainer
   also selects the other points of ECharts ADR 0001 item 1.
2. Stage 1 of ADR 0008: ECharts phase 1 does it, with an edit of the gate of the proposed ADR
   0008, or ECharts phase 1 waits for D3 phase 1.
3. The header project name: `Apache ECharts` with a lazy project pattern in the shared tool 2, or
   the one token `ECharts` with the Chart.js pattern.
4. The holder check: the shared tool 2 reads the holder from `NOTICE`, or the package `LICENSE`
   gets copyright lines before the Apache text.
5. The 18-line ASF comment in each ported ECharts file, or `LICENSE` and `NOTICE` only.
6. node-timsort, jsdiff and tween.js: separate components (ECharts ADR 0001 item 1.4), or the fsum
   rule of D3 ADR 0001 item 11.
7. The Canvas 2D layer: a shared layer by a new root ADR before phase 3, or an ECharts-own
   `lib/src/canvas/`. Also the package names of ADR 0007 items 6 and 7.
8. The SVG string painter (`renderToSVGString`) in the scope of 0.1.0, and its use as an earlier
   reference oracle.
9. The HTML tooltip for 0.1.0: `renderMode: 'html'` as `richText`, or a Flutter overlay with an
   HTML and CSS subset.
10. Export: `getDataURL` and `getConnectedDataURL` as `Future`s. JPEG export as `n/a` or with a
    pure-Dart encoder.
11. The XML parser for SVG maps (phase 8): a port-only parser or `package:xml`.
12. The CJK width in the Flutter tests: the fixed advance for `'国'` of ECharts ADR 0006 §9, or a
    CJK test font. zrender takes the line height from the width of `'国'`
    (`zrender src/contain/text.ts:42,180-183`). Liberation Sans has no CJK glyph.
13. The reference engine: who installs the darwin-x64 build of Node.js v24.12.0, and before which
    phase. On 2026-10-21, the machine has only the arm64 build.
14. The module-level generators: Node.js type removal over both `src/` folders, or a built clone
    outside the repository.
15. The files that no ECharts file reaches: port them in their phases, or mark them `n/a`.
16. An ECharts `upstream-tracking.md`, or ADR 0006 and the ledger only.
17. `touchEventsSupported`: one value for each platform, or one value for each pointer kind.
    Trackpad `PointerPanZoom` as `pinch` or as `mousewheel`.
18. Dark mode: the host app selects the ECharts `'dark'` theme by default, or not.
19. Phase 6 stops at the `echarts.simple.ts` set (line, bar, pie, simple grid, dataset, aria), or
    not. If it stops there, tooltip, title, legend and the polar axes move to phase 7.
20. ADR 0008 item 8 lists one project and one version constant for each config. The ECharts
    config needs two projects, the holder source `NOTICE` and the lazy project pattern. The main
    session extends the proposed ADR 0008 before stage 1, or stage 1 waits.
