# ECharts parity tracker

This file tracks the port of the two pinned repositories: Apache ECharts and its renderer zrender.
Each repository is a shallow git submodule at the tag of
[`tool/port_sources.yaml`](../tool/port_sources.yaml)
([ECharts ADR 0001](adr/0001-upstream-sources.md)):

- `third_party/echarts`: tag `6.1.0`, commit `c5a48f5f` (2026-05-13).
- `third_party/zrender`: tag `6.1.0`, commit `32b66867` (2026-05-04).

Run `dart run melos run upstream` to clone them.

Phase 0 ports no file. Thus each row has the status `not started`. In phase 0, this file has one
row for each top-level directory of the two `src/` folders. A person writes it by hand. The status
unit is one upstream source file (ECharts ADR 0001). Thus the status of a directory row applies to
each of its source files.

From phase 2, tool 6 ([porting-flow.md](porting-flow.md) §4) writes this file from
`doc/status.yaml`, with one row for each upstream source file. Until then, each port change edits
this file in the same change as the code.

Status values ([porting-flow.md](porting-flow.md) §1, the values of the Chart.js and D3 ports):

- `not started`: the file has no Dart code.
- `in progress`: Dart code exists for a part of the file.
- `partial: <symbols>`: the port has only the listed symbols, because a ported file of an earlier
  phase needs them. An example is a class that an earlier phase names as a type
  ([ECharts ADR 0002](adr/0002-file-naming-and-layout.md)).
- `ported`: the Dart code and the ported tests pass. All of `lib/src/echarts/` and
  `lib/src/zrender/` is pure. Thus the tests pass on the VM, with dart2js and with dart2wasm. This
  is the last status of a file. The port has no `verified` status
  ([ADR 0006](../../../docs/adr/0006-follow-upstream-between-releases.md)).
- `replaced`: a port-only Flutter file replaces the upstream file. An example is
  `zrender src/dom/HandlerProxy.ts`
  ([ECharts ADR 0007](adr/0007-environment-host-and-input-events.md)).
- `distributed`: the port mirrors a type declaration file as Dart types in the files that use
  them. ECharts and zrender have 10 type-only files with 856 lines (`wc -l`, ECharts ADR 0002).
- `n/a: <reason>`: the port does not port the file, for the stated reason. Examples are the 56
  legacy shims (`n/a: import side-effect shim`) and `zrender src/svg-legacy/`.

## Apache ECharts `src/`

The columns:

- **Source files** and **Lines**: the `src/**/*.ts` files that git tracks at the tag, and the sum
  of their `wc -l` counts. The count includes `src/global.d.ts`.
- **Phases**: each phase of the [roadmap](README.md#roadmap) that ports files of the row. The
  number in parentheses is the count of files of that phase.

| Directory | Source files | Lines | Phases | Status |
|---|---:|---:|---|---|
| root files | 7 | 710 | 5 (1), 6 (1), 9 (1), 10 (4) | not started |
| `animation/` | 5 | 2197 | 4 (1), 7 (2), 9 (2) | not started |
| `chart/` | 171 | 34385 | 5 (2), 6 (33), 7 (61), 8 (75) | not started |
| `component/` | 187 | 36522 | 4 (2), 6 (48), 7 (30), 8 (26), 9 (80), 10 (1) | not started |
| `coord/` | 71 | 16961 | 2 (1), 4 (10), 6 (21), 7 (12), 8 (25), 10 (2) | not started |
| `core/` | 9 | 5277 | 2 (6), 4 (1), 5 (2) | not started |
| `data/` | 19 | 8801 | 2 (16), 4 (3) | not started |
| `export/` | 14 | 1120 | 6 (8), 9 (1), 10 (5) | not started |
| `i18n/` | 27 | 3901 | 4 (2), 10 (25) | not started |
| `label/` | 6 | 3053 | 4 (5), 6 (1) | not started |
| `layout/` | 4 | 1087 | 6 (4) | not started |
| `legacy/` | 2 | 160 | 4 (1), 5 (1) | not started |
| `loading/` | 1 | 168 | 5 (1) | not started |
| `model/` | 15 | 4300 | 2 (9), 4 (6) | not started |
| `preprocessor/` | 2 | 626 | 2 (2) | not started |
| `processor/` | 4 | 381 | 2 (4) | not started |
| `renderer/` | 2 | 48 | 6 (1), 10 (1) | not started |
| `scale/` | 10 | 3768 | 2 (7), 4 (3) | not started |
| `theme/` | 1 | 329 | 5 (1) | not started |
| `util/` | 26 | 11813 | 1 (1), 2 (14), 4 (11) | not started |
| `view/` | 2 | 464 | 5 (2) | not started |
| `visual/` | 11 | 2204 | 2 (9), 4 (2) | not started |
| **All of `src/`** | **596** | **138275** | | |

### `chart/`, `component/` and `coord/` by subdirectory

These three directories have files in four or more phases. This table splits them. The "files"
row of a directory counts the files directly in it. In `chart/` and `component/`, these are the
56 legacy shims: 23 `chart/<type>.ts` files and 33 `component/<name>.ts` files.

| Directory | Source files | Lines | Phases | Status |
|---|---:|---:|---|---|
| `chart/` files | 23 | 516 | 6 (4), 7 (10), 8 (9) | not started |
| `chart/bar/` | 7 | 2959 | 6 (4), 7 (3) | not started |
| `chart/boxplot/` | 6 | 782 | 7 (6) | not started |
| `chart/candlestick/` | 6 | 1065 | 7 (6) | not started |
| `chart/chord/` | 6 | 1200 | 8 (6) | not started |
| `chart/custom/` | 4 | 2023 | 5 (1), 7 (3) | not started |
| `chart/effectScatter/` | 3 | 272 | 7 (3) | not started |
| `chart/funnel/` | 4 | 865 | 7 (4) | not started |
| `chart/gauge/` | 4 | 1154 | 7 (4) | not started |
| `chart/graph/` | 15 | 2353 | 8 (15) | not started |
| `chart/heatmap/` | 4 | 769 | 7 (4) | not started |
| `chart/helper/` | 24 | 4669 | 5 (1), 6 (10), 7 (9), 8 (4) | not started |
| `chart/line/` | 6 | 2548 | 6 (6) | not started |
| `chart/lines/` | 5 | 866 | 7 (5) | not started |
| `chart/map/` | 5 | 839 | 8 (5) | not started |
| `chart/parallel/` | 4 | 535 | 8 (4) | not started |
| `chart/pie/` | 5 | 1536 | 6 (5) | not started |
| `chart/radar/` | 5 | 617 | 8 (5) | not started |
| `chart/sankey/` | 5 | 1490 | 8 (5) | not started |
| `chart/scatter/` | 4 | 445 | 6 (4) | not started |
| `chart/sunburst/` | 7 | 1366 | 8 (7) | not started |
| `chart/themeRiver/` | 4 | 733 | 7 (4) | not started |
| `chart/tree/` | 8 | 1712 | 8 (8) | not started |
| `chart/treemap/` | 7 | 3071 | 8 (7) | not started |
| `component/` files | 33 | 757 | 6 (9), 7 (6), 8 (5), 9 (13) | not started |
| `component/aria/` | 2 | 67 | 6 (2) | not started |
| `component/axis/` | 13 | 4090 | 6 (8), 7 (3), 8 (2) | not started |
| `component/axisPointer/` | 13 | 3043 | 6 (12), 7 (1) | not started |
| `component/brush/` | 6 | 1049 | 9 (6) | not started |
| `component/calendar/` | 2 | 590 | 8 (2) | not started |
| `component/dataZoom/` | 19 | 3980 | 9 (19) | not started |
| `component/dataset/` | 1 | 98 | 6 (1) | not started |
| `component/geo/` | 2 | 272 | 8 (2) | not started |
| `component/graphic/` | 3 | 1026 | 7 (3) | not started |
| `component/grid/` | 2 | 103 | 6 (2) | not started |
| `component/helper/` | 11 | 3858 | 6 (1), 8 (9), 9 (1) | not started |
| `component/legend/` | 10 | 2293 | 6 (5), 9 (5) | not started |
| `component/marker/` | 13 | 2371 | 7 (13) | not started |
| `component/matrix/` | 2 | 487 | 8 (2) | not started |
| `component/parallel/` | 2 | 181 | 8 (2) | not started |
| `component/polar/` | 1 | 84 | 6 (1) | not started |
| `component/radar/` | 2 | 248 | 8 (2) | not started |
| `component/singleAxis/` | 1 | 48 | 7 (1) | not started |
| `component/thumbnail/` | 4 | 615 | 9 (4) | not started |
| `component/timeline/` | 8 | 1678 | 9 (8) | not started |
| `component/title/` | 1 | 292 | 6 (1) | not started |
| `component/toolbox/` | 10 | 2282 | 9 (10) | not started |
| `component/tooltip/` | 8 | 3130 | 4 (2), 6 (6) | not started |
| `component/transform/` | 3 | 331 | 7 (3) | not started |
| `component/visualMap/` | 15 | 3549 | 9 (14), 10 (1) | not started |
| `coord/` files | 16 | 5708 | 2 (1), 4 (7), 6 (7), 7 (1) | not started |
| `coord/calendar/` | 3 | 933 | 7 (1), 8 (2) | not started |
| `coord/cartesian/` | 10 | 2418 | 4 (2), 6 (5), 7 (2), 10 (1) | not started |
| `coord/geo/` | 14 | 2590 | 6 (3), 7 (1), 8 (9), 10 (1) | not started |
| `coord/matrix/` | 6 | 2190 | 7 (1), 8 (5) | not started |
| `coord/parallel/` | 6 | 1084 | 8 (6) | not started |
| `coord/polar/` | 7 | 872 | 6 (6), 7 (1) | not started |
| `coord/radar/` | 3 | 504 | 8 (3) | not started |
| `coord/single/` | 6 | 662 | 4 (1), 7 (5) | not started |

## zrender `src/`

The columns are the columns of the ECharts table. The count includes `src/global.d.ts`.

| Directory | Source files | Lines | Phases | Status |
|---|---:|---:|---|---|
| root files | 9 | 3718 | 2 (1), 3 (5), 10 (3) | not started |
| `animation/` | 6 | 1952 | 3 (6) | not started |
| `canvas/` | 6 | 2909 | 3 (6) | not started |
| `contain/` | 9 | 947 | 3 (9) | not started |
| `core/` | 22 | 6800 | 1 (4), 2 (18) | not started |
| `debug/` | 1 | 122 | 10 (1) | not started |
| `dom/` | 1 | 633 | 3 (1) | not started |
| `graphic/` | 37 | 6283 | 3 (37) | not started |
| `mixin/` | 1 | 117 | 3 (1) | not started |
| `svg/` | 12 | 2549 | 3 (1), 10 (11) | not started |
| `svg-legacy/` | 8 | 1617 | 10 (8) | not started |
| `tool/` | 8 | 3802 | 2 (1), 3 (5), 8 (2) | not started |
| **All of `src/`** | **120** | **31449** | | |

`graphic/` includes `graphic/helper/` (8 files) and `graphic/shape/` (16 files).

## Outside `src/`

This table gives the status of the upstream areas outside the two `src/` folders. The Files
column counts the files that `git ls-files` gives at the pin, with the stated suffix. The counts
of the other tables do not include these files.

| Path | Files | Status | Decision |
|---|---:|---|---|
| `echarts extension-src/bmap/` | 4 `.ts` | `n/a: needs the Baidu Maps JS SDK` | [ECharts ADR 0009](adr/0009-dom-features-app-hooks-and-theming.md) §9 |
| `echarts extension-src/dataTool/` | 3 `.ts` | not started | not for 0.1.0: ECharts ADR 0009 §9 |
| `echarts theme/*.js`, top level only | 36 `.js` | not started | not for 0.1.0: ECharts ADR 0009 §8 item 6 |
| `echarts i18n/` | 55 | `n/a: build output of src/i18n/` | [ECharts ADR 0001](adr/0001-upstream-sources.md) item 16 |
| `echarts ssr/client/` | 1 `.ts` | `n/a: browser hydration of a server SVG` | ECharts ADR 0001 item 16 |
| `echarts test/runTest/actions/` | 273 | not started | no replay before phase 9: [porting-flow.md](porting-flow.md) §2.15 |
| `echarts dist/` | 22 | `n/a: build output, read by the reference generators` | ECharts ADR 0001 item 16, [ECharts ADR 0005](adr/0005-spec-harness-and-reference-tests.md) §10 |

## Upstream specs

The upstream specs are the `test/ut/spec/**/*.test.ts` files of the two repositories. Jest runs
them. The columns:

- **Lines**: the `wc -l` count of the file.
- **Cases**: the run-time count of the jest cases ([Count script](#count-script)). Loops make
  more cases at run time than the static count of `it(` calls.
- **Kind**: `chart` for a spec that calls `createChart` of `test/ut/core/utHelper.ts`, else
  `pure`. The port runs both kinds on `package:test`, with no `testWidgets`
  ([ECharts ADR 0005](adr/0005-spec-harness-and-reference-tests.md)).
- **Phase**: the phase of the roadmap that ports the spec.

| Spec file | Lines | Cases | Kind | Phase | Status |
|---|---:|---:|---|---:|---|
| `echarts api/containPixel.test.ts` | 428 | 4 | chart | 9 | not started |
| `echarts api/converter.test.ts` | 430 | 4 | chart | 9 | not started |
| `echarts api/getVisual.test.ts` | 213 | 2 | chart | 9 | not started |
| `echarts component/dataZoom/helper.test.ts` | 104 | 3 | chart | 9 | not started |
| `echarts component/graphic/setOption.test.ts` | 1355 | 12 | chart | 9 | not started |
| `echarts component/helper/sliderMove.test.ts` | 122 | 5 | pure | 8 | not started |
| `echarts component/matrix/event.test.ts` | 132 | 2 | chart | 9 | not started |
| `echarts component/visualMap/setOption.test.ts` | 289 | 7 | chart | 9 | not started |
| `echarts data/SeriesData.test.ts` | 564 | 21 | pure | 4 | not started |
| `echarts data/createDimensions.test.ts` | 975 | 5 | pure | 2 | not started |
| `echarts data/dataTransform.test.ts` | 185 | 8 | chart | 9 | not started |
| `echarts data/dataValueHelper.test.ts` | 405 | 10 | pure | 2 | not started |
| `echarts model/Global.test.ts` | 855 | 22 | chart | 9 | not started |
| `echarts model/componentDependency.test.ts` | 239 | 9 | pure | 4 | not started |
| `echarts model/componentMissing.test.ts` | 151 | 6 | chart | 10 | not started |
| `echarts model/timelineMediaOptions.test.ts` | 441 | 11 | chart | 9 | not started |
| `echarts scale/interval.test.ts` | 236 | 4 | chart | 9 | not started |
| `echarts series/aria-columns-exclude.test.ts` | 100 | 2 | chart | 9 | not started |
| `echarts series/custom.test.ts` | 121 | 2 | chart | 9 | not started |
| `echarts util/graphic.test.ts` | 190 | 7 | pure | 4 | not started |
| `echarts util/layout.test.ts` | 202 | 1 | pure | 4 | not started |
| `echarts util/model.test.ts` | 258 | 5 | pure | 2 | not started |
| `echarts util/number.test.ts` | 1089 | 24 | pure | 1 | not started |
| `echarts util/time.test.ts` | 190 | 15 | pure | 4 | not started |
| `zrender animation/ElementAnimation.test.ts` | 115 | 6 | pure | 3 | not started |
| `zrender contain/Sector.test.ts` | 39 | 1 | pure | 3 | not started |
| `zrender core/LRU.test.ts` | 25 | 1 | pure | 2 | not started |
| `zrender core/arrayDiff.test.ts` | 40 | 3 | pure | 2 | not started |
| `zrender core/matrix.test.ts` | 21 | 1 | pure | 1 | not started |
| `zrender core/platform.test.ts` | 39 | 3 | pure | 1 | not started |
| `zrender core/util.test.ts` | 149 | 11 | pure | 1 | not started |
| `zrender graphic/Group.test.ts` | 181 | 10 | pure | 3 | not started |
| `zrender graphic/Image.test.ts` | 64 | 3 | pure | 3 | not started |
| `zrender graphic/Path.test.ts` | 312 | 13 | pure | 3 | not started |
| `zrender graphic/Text.test.ts` | 31 | 1 | pure | 3 | not started |
| `zrender tool/color.test.ts` | 26 | 15 | pure | 2 | not started |
| **ECharts: 24 files** | **9274** | **191** | | | |
| **zrender: 12 files** | **1042** | **68** | | | |
| **All: 36 files** | **10316** | **259** | | | |

ECharts has 10 pure spec files with 102 cases and 14 chart spec files with 89 cases. All 12
zrender spec files are pure.

## By phase

The source counts of the two `src/` folders and the spec counts, grouped by phase. Phase 0 ports
no upstream file.

| Phase | Source files | Lines | Spec files | Cases |
|---|---:|---:|---:|---:|
| 0. Scaffold and design | 0 | 0 | 0 | 0 |
| 1. Decisions, tooling, pilot | 5 | 2178 | 4 | 39 |
| 2. Foundations | 88 | 26564 | 6 | 39 |
| 3. Renderer (zrender) | 71 | 18835 | 6 | 34 |
| 4. Data and model | 47 | 19034 | 5 | 53 |
| 5. Core (the update pipeline) | 10 | 5397 | 0 | 0 |
| 6. First charts and the gallery | 117 | 26274 | 0 | 0 |
| 7. More cartesian and polar series, markers, graphic | 105 | 19629 | 0 | 0 |
| 8. Other coordinate systems, hierarchy, graph and geo | 128 | 26687 | 1 | 5 |
| 9. Interaction and transitions | 84 | 15866 | 13 | 83 |
| 10. Release set and 0.1.0 | 61 | 9260 | 1 | 6 |
| **Total** | **716** | **169724** | **36** | **259** |

## Notes

- **Type declarations.** Each `src/` folder has one `global.d.ts`. The counts include them.
  Without them, ECharts has 595 modules with 138255 lines. zrender has 119 modules with 31445
  lines. Both `global.d.ts` files get `n/a` ([ECharts ADR 0002](adr/0002-file-naming-and-layout.md)).
- **License comments.** Each of the 596 ECharts source files has the 18-line ASF license comment.
  The line counts include it. In 589 files, the comment starts at line 1. In 6 files, a blank
  line comes first. In `src/visual/LegendVisualProvider.ts`, an import and a blank line come first
  (`src/visual/LegendVisualProvider.ts:1-3`). Of the zrender files, only
  `src/core/OrientedBoundingRect.ts` has the ASF comment.
- **Code lines.** The research of 2026-10-21 also counted the lines with code, without blank
  lines and comment-only lines: 93310 for ECharts and 22832 for zrender, 116142 in total.
- **Phases.** The import graph of the two `src/` folders gives the phase of each file. A phase is
  the value-import closure of its root files without the files of the earlier phases. No file
  has a value import of a file of a later phase. Two changes apply to the computed phases:
  - `zrender src/tool/parseSVG.ts` (965 lines) and `src/tool/parseXML.ts` (22 lines) move from
    phase 3 to phase 8. Only `zrender src/export.ts:10` (phase 10) and
    `echarts src/coord/geo/GeoSVGResource.ts:20,26` (phase 8) import them. They need the XML
    decision of [ECharts ADR 0009](adr/0009-dom-features-app-hooks-and-theming.md).
  - The research named the last four phases 7a, 7b, 8 and 9. The roadmap numbers them 7 to 10.
- **Chart specs.** The 14 chart spec files import `test/ut/core/utHelper.ts`. This helper imports
  `src/echarts.all.ts` (phase 10). Thus the table gives these files phase 9 or 10. A chart case
  can pass earlier, when the files that its options name are ported. Tool 5 reports it then.
- **Cases.** The static count of `it(` calls differs from the run-time count in three files,
  because of loops: `data/dataValueHelper.test.ts` (2 sites, 10 cases),
  `data/dataTransform.test.ts` (5 sites, 8 cases) and zrender `tool/color.test.ts` (1 site,
  15 cases). No spec uses `it.skip`, `.only` or `.each`. Three full case names occur twice. They
  get the suffix ` #2` (ECharts ADR 0005).
- **The zrender spec helper.** zrender `test/ut/spec/zrender.ts` re-exports `src/export.ts` and
  `src/zrender.ts`. It is not a spec. The count does not include it.
- **The five d3 files.** Five ECharts files have d3 code under BSD-3-Clause:
  `src/util/number.ts` (phase 1), `src/scale/Time.ts` (phase 4),
  `src/chart/treemap/treemapLayout.ts`, `src/chart/tree/layoutHelper.ts` and
  `src/chart/graph/forceHelper.ts` (phase 8). The ECharts `LICENSE:209-222` names only four of
  them. `src/scale/Time.ts:20-28` has the same d3 block. Their ports add the d3 notice
  ([ECharts ADR 0001](adr/0001-upstream-sources.md) item 12).
- **File names.** The `file_names` lint accepts dots. With the lint, 442 ECharts and 80 zrender
  source names fail. 14 ECharts and 8 zrender spec names fail too. Thus 544 Dart files fail the
  lint, 546 with the two harness files. The four entry names with a dot, for example
  `echarts.all`, pass the lint. The stricter pattern `^[a-z_][a-z0-9_]*$` rejects the dots. It
  gives 446 ECharts sources (548 files without the harness files).
  [ECharts ADR 0002](adr/0002-file-naming-and-layout.md) gives the probe and the rule. Seven
  directory names are not snake case: `axisPointer`, `dataZoom`, `effectScatter`, `singleAxis`,
  `themeRiver`, `visualMap` and `svg-legacy`.
- **Files that no ECharts file reaches.** The count includes them: ECharts `util/KDTree.ts`,
  `util/quickSelect.ts`, `data/helper/linkList.ts`, `coord/geo/fix/geoCoord.ts` and
  `component/visualMap/typeDefaulter.ts`, and zrender `core/arrayDiff.ts`,
  `graphic/helper/smoothSpline.ts` and six shapes. Only `util/KDTree.ts:20` imports
  `quickSelect.ts`. Only `svg-legacy/Painter.ts:11` imports `arrayDiff.ts`. Only
  `zrender src/export.ts:38-50` imports the six shapes (Droplet, Heart, Isogon, Rose, Star and
  Trochoid). No file imports the other files of the list. The roadmap ports them in their phases.
  Open question 15 of the [README](README.md#open-questions) asks for a decision.
  `coord/cartesian/defaultAxisExtentFromData.ts` is also unreferenced. It gets `n/a`
  ([ECharts ADR 0002](adr/0002-file-naming-and-layout.md) §7).
- **Files outside `src/`.** The count does not include these files:
  - ECharts `i18n/` (55 files): the build output of the 27 `src/i18n/` locales.
  - ECharts `theme/` (36 theme files directly in `theme/`, 43 `.js` files with the subfolders,
    `git ls-files 'theme/*.js'`), `extension-src/` (7 `.ts` files), `ssr/client/` and
    `dist/`. ECharts ADR 0001 gives their use. The table [Outside `src/`](#outside-src) gives
    their status.
  - the visual test pages: 605 ECharts `test/*.html` files and 76 zrender `test/*.html` files.
    The upstream suite `test/runTest/` compares them as images. It has 273 files in
    `test/runTest/actions/`. ECharts ADR 0005 gives their use from phase 6.
  - the harness files `test/ut/core/utHelper.ts` and `test/ut/core/extendExpect.ts`. Their ports
    go to `test/support/echarts/` (ECharts ADR 0002).

## Count script

The source and spec counts come from this script. Save it as `count.sh` outside the repository.
Then run it from the repository root after `dart run melos run upstream`:

```sh
bash count.sh third_party/echarts
bash count.sh third_party/zrender
```

For each top-level directory of `src/`, it prints the name, the source files and the lines. Then
it prints each spec file with its lines. It reads only the files that git tracks. It runs no
upstream code.

```sh
r=$1
git -C "$r" ls-files src | grep '\.ts$' | while IFS= read -r p; do
  d=${p#src/}
  case $d in */*) d=${d%%/*}/ ;; *) d='(root)' ;; esac
  echo "$d $(wc -l < "$r/$p" | tr -d ' ')"
done | awk '{f[$1]++; l[$1] += $2; F++; L += $2}
  END {for (d in f) print d, f[d], l[d]; print "total", F, L}' | sort
git -C "$r" ls-files test/ut/spec | grep '\.test\.ts$' | while IFS= read -r p; do
  echo "${p#test/ut/spec/} $(wc -l < "$r/$p" | tr -d ' ')"
done
```

On 2026-10-21, the script ran over the two submodules of this repository at the pins. Two more
scripts of the same research gave the other figures:

- The Cases column comes from a probe that ran each spec file under Node.js v24.12.0. The probe
  removes the types with `module.stripTypeScriptTypes`. It replaces each import with a stub
  object. Its `describe` runs the body. Its `it` records the name. It does not run the case
  bodies. It needs no `npm install`. Case names are not reference values. Thus the arm64 build of
  Node.js was sufficient. From phase 2, tool 4 records the cases in `doc/upstream/manifest.json`
  ([ECharts ADR 0005](adr/0005-spec-harness-and-reference-tests.md)).
- The Phases columns, the subdirectory table and the [By phase](#by-phase) table come from two
  steps. First, a script parses the imports of both `src/` folders with the TypeScript 5.9.3
  parser and gives the phase of each file. Second, a script applies the two changes of the
  [Notes](#notes) to this phase list. Then it counts the files and the `wc -l` lines of each
  phase and directory over the git file lists of `count.sh`.
