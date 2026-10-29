# ECharts porting flow

- Status: proposed
- Date: 2026-10-21
- Related: [ADR 0005](../../../docs/adr/0005-pin-upstream-sources.md),
  [ADR 0006](../../../docs/adr/0006-follow-upstream-between-releases.md),
  [ADR 0007](../../../docs/adr/0007-package-names.md),
  [ADR 0008](../../../docs/adr/0008-shared-js-runtime-and-port-tools.md),
  [ECharts ADR 0001](adr/0001-upstream-sources.md),
  [the D3 porting flow](../../flutter_d3_port/doc/porting-flow.md),
  [the Chart.js porting flow](../../flutter_chartjs_port/doc/porting-flow.md)

This document defines how one upstream source file of Apache ECharts or zrender becomes Dart code
in `packages/flutter_echarts_port`. It contains the steps, the decisions, the test harness, the
tools and the phase plan. It follows the form of the D3 porting flow. This document owns the
ECharts phase numbers and the names of the ECharts decisions. It also owns the status values of
the ECharts port and the ECharts `differences.md` schema. [upstream-ledger.md](upstream-ledger.md)
lists the upstream commits after the pins
([ADR 0006](../../../docs/adr/0006-follow-upstream-between-releases.md)).

Terms:
- "ADR NNNN" is a file in `docs/adr/`. "Chart.js ADR NNNN" is a file in
  `packages/flutter_chartjs_port/doc/adr/`. "D3 ADR NNNN" is a file in
  `packages/flutter_d3_port/doc/adr/`. "ECharts ADR NNNN" is a file in
  `packages/flutter_echarts_port/doc/adr/`.
- A "repository" is one of the two pinned git repositories of
  [ECharts ADR 0001](adr/0001-upstream-sources.md): `apache/echarts` at `third_party/echarts` and
  `ecomfe/zrender` at `third_party/zrender`.
- A "project" is the name in a header line: `Apache ECharts` or `zrender`.
- A "module" is one upstream source file. It is the status unit of ECharts ADR 0001.

## 1. Life cycle of one module port

1. **Choose.** Pick a module of the current phase. Each module that it imports by value must be
   done. ECharts files import zrender files. [parity.md](parity.md) gives the phase of each
   directory and of each spec file.
   - The value import graph has no cycle. Thus a strict bottom-up order of files exists, with 30
     value levels. Directories are not layers. `util/` imports `model/`. `model/` imports `util/`
     (section 4, tool 8).
   - A type-only import of a later module does not block the port. The earlier phase ports the
     referenced class at its mapped path with the status `partial: <symbols>` (2.4).
   - Before the first module of a repository goes to `in progress`, apply ADR 0006 item 4 ("Bump
     first") to that repository. If the repository has a newer release tag, the bump PR comes
     first. The bump unit is in ECharts ADR 0001 (2.3).
   - Before a phase starts, apply ADR 0006 item 5 (commit pins) to each repository of the phase.
     The ECharts tag `6.1.0` is from 2026-05-13. The zrender tag `6.1.0` is from 2026-05-04. Thus
     the first condition of item 5 ("more than 12 months old") is false until 2027-05.
     [upstream-ledger.md](upstream-ledger.md) has the triage of the unreleased commits.
2. **Read the source** at its pin (AGENTS.md rule 1). Read the types that the file imports too.
   2,195 of the 5,184 import edges are type-only. Only 359 of them use `import type`.
3. **Write the Dart file.**
   - Map the path ([ECharts ADR 0002](adr/0002-file-naming-and-layout.md)):
     `third_party/echarts/src/<p>.ts` becomes `lib/src/echarts/<p>.dart`.
     `third_party/zrender/src/<p>.ts` becomes `lib/src/zrender/<p>.dart`.
   - The bare specifier `zrender/src/<p>` of an ECharts import becomes
     `package:flutter_echarts_port/src/zrender/<p>.dart`. Use package imports only.
   - Line 1 is the header of AGENTS.md rule 2. The project, the license and the holder come from
     `tool/port_sources.yaml`. The version has no `v`.
   - The header block has this order:
     1. line 1: the `// Ported from` line
     2. zero or more backport lines
     3. `// ignore_for_file: file_names` when the file name fails the lint
     4. the upstream license comment block, verbatim, when the upstream file has one
     5. then `library;`, the imports and the code
   - Each ECharts source file starts with an 18-line ASF license block. zrender files have no
     block, except `src/core/OrientedBoundingRect.ts:1-18`. The five d3 files also keep their d3
     notice block, for example `echarts src/util/number.ts:20-27`.
   - Keep the upstream order and names. Give each public symbol a `///` line that names the
     upstream symbol and file:line.
   - A TS member name can start with `_`. When another file or a spec reads the member, the Dart
     name drops the `_` and gets `@internal`. A collision adds a `_` at the end (Chart.js ADR
     0023, ECharts ADR 0002).
   - Call the JS runtime for JS builtins. Generic builtins come from `js_semantics`
     ([ADR 0008](../../../docs/adr/0008-shared-js-runtime-and-port-tools.md)). ECharts-only
     runtime is in `lib/src/js/`. [ECharts ADR 0003](adr/0003-numbers-and-js-semantics.md) gives
     the numbers and the number strings.
     [ECharts ADR 0004](adr/0004-js-values-classes-and-options.md) gives the option values,
     `null`, `undefined`, classes and callbacks.
   - `__DEV__` becomes the run-time switch `echartsDev` of `lib/src/dev.dart` (ECharts ADR 0004).
   - Mark each hunk that does not translate upstream lines with
     `// DIVERGES(echarts): <row id>, <reason>` and a [differences.md](differences.md) row
     (section 4). zrender files use the same tag.
   - Start a port-only file with `// Original code, not ported from Apache ECharts: <reason>.`
     The marker is the same for port-only files on the zrender side.
   - When two Dart forms give the upstream behavior, choose the faster form (1.1).

   The first lines of a ported ECharts file whose name fails the lint:

   ```dart
   // Ported from Apache ECharts 6.1.0 src/data/SeriesData.ts (Apache-2.0, The Apache Software Foundation).
   // ignore_for_file: file_names
   /*
   * Licensed to the Apache Software Foundation (ASF) under one
   * or more contributor license agreements.  See the NOTICE file
   ```

   The 18-line block continues verbatim up to `*/`. A zrender file starts with a line such as
   `// Ported from zrender 6.1.0 src/core/matrix.ts (BSD-3-Clause, Baidu Inc.).`
4. **Licensing** (AGENTS.md Licensing, [ECharts ADR 0001](adr/0001-upstream-sources.md)). The
   code of the port is Apache-2.0. The package `LICENSE` of phase 0 is the plain Apache-2.0 text.
   The package `NOTICE` has the port line `Copyright 2026 Vasiliy Ditsyak` and the ECharts
   `NOTICE` unchanged. The change that ports code of another license component adds that
   component:
   - its notice in the package `LICENSE`
   - a `REUSE.toml` table, last, with every holder of its paths
   - for a new license, the file `LICENSES/<SPDX-ID>.txt`
   - for an embedded notice, a `notices` item in the entry of `tool/port_sources.yaml` (D3 ADR
     0001 item 12)

   ECharts ADR 0001 (item 12) lists these components with their exact holder strings:
   - zrender, the whole repository (BSD-3-Clause, `Baidu Inc.`). First file: phase 1.
   - d3 in five ECharts files (BSD-3-Clause, `Mike Bostock`): `src/util/number.ts` (phase 1),
     `src/scale/Time.ts` (phase 4), `src/chart/treemap/treemapLayout.ts`,
     `src/chart/tree/layoutHelper.ts` and `src/chart/graph/forceHelper.ts` (phase 8). The source
     is the "Apache ECharts Subcomponents" section of the ECharts `LICENSE:209-222` and
     `licenses/LICENSE-d3`. That section names only four of the files. `src/scale/Time.ts:20-28`
     has the same d3 block.
   - node-timsort in `zrender src/core/timsort.ts` (MIT, `Marco Ziccardi`). First file: phase 2.
   - jsdiff in `zrender src/core/arrayDiff.ts` (BSD-3-Clause, `Kevin Decker`). First file:
     phase 2.
   - tween.js in `zrender src/animation/easing.ts` (MIT, `Tween.js authors`, with `Robert Penner`
     for the easing equations). First file: phase 3.
   - Apache ECharts code in `zrender src/core/OrientedBoundingRect.ts` (Apache-2.0,
     `The Apache Software Foundation`). First file: phase 2.

   The maintainer decides the node-timsort, jsdiff and tween.js items (section 7, question 6).

   Three sources get no component. The Zepto.js lines of `zrender src/core/env.ts:54-56` stay
   out, because the port replaces the detection. The snabbdom code of `zrender src/svg/patch.ts`
   is `n/a`. `tslib` 2.3.0 gives emit helpers only. The port translates none of it.
5. **Port the tests** ([ECharts ADR 0005](adr/0005-spec-harness-and-reference-tests.md)).
   - The Dart path of `<repo>/test/ut/spec/<p>.test.ts` is `test/specs/<repo>/<p>_test.dart`,
     where `<repo>` is `echarts` or `zrender`. The header names the upstream test file.
   - Two upstream harness files have file targets. `test/ut/core/utHelper.ts` becomes
     `test/support/echarts/utHelper.dart`. `test/ut/core/extendExpect.ts` becomes
     `test/support/echarts/extendExpect.dart`. The change that ports the first helper adds these
     targets to `tool/port_sources.yaml`.
   - The zrender helper `test/ut/spec/zrender.ts` becomes `test/specs/zrender/zrender.dart` by the
     directory rule. It is a library, not a test file.
   - Write one `group()` for each `describe` and one `test()` for each `it`, with the upstream
     strings. Three duplicate full names get the ` #2` rule of D3 ADR 0004. Loops that make cases
     stay loops.
   - Port the upstream assertions on the jest `expect` stand-in `test/support/jest_expect.dart`.
     A spec file imports `package:test/test.dart` with `hide expect`.
   - Call `setUpSpecs()` of `test/support/spec_setup.dart` first in `main()`.
   - The skip reasons are `'blocked: echarts/src/<path>.ts'`, `'blocked: zrender/src/<path>.ts'`
     (or a folder), `'n/a: <reason>'` and `'diverges: <row id>'`. A case that needs a module of a
     later phase skips as `blocked`. It names the absent module of the latest phase.
   - A test file whose name fails `file_names` carries the ignore line too.
   - The specs are pure. They use `package:test` and need no `@TestOn('vm')` (section 3). A test
     file that needs `dart:io`, `dart:ui` or `flutter_test` has `@TestOn('vm')` after its header
     lines. When the file has the ignore line, `@TestOn('vm')` comes after the ignore line.
   - Put the tests of port-only behavior in `test/port/echarts/<path>_test.dart` or
     `test/port/zrender/<path>_test.dart`. Also put there the tests of a module without an
     upstream spec (AGENTS.md rule 3).
6. **Data files.** The specs carry their expected values inline. No spec reads `test/data/`.
   `test/data/` has 24 MB. The origin of each file is not recorded. The port never copies it.
   The visual smoke runner of phase 6 reads the visual pages from the submodule (section 3).
7. **Status.** The values are `not started`, `in progress`, `partial: <symbols>`, `ported`,
   `replaced`, `distributed` and `n/a: <reason>`. These are the values of the Chart.js and D3
   ports. Thus tool 6 serves all ports with one list.
   - `replaced`: `zrender src/dom/HandlerProxy.ts`. A port-only Flutter handler proxy replaces
     it (ECharts ADR 0007).
   - `distributed`: a type-only file whose declarations the port gives as Dart types in other
     files (ECharts ADR 0002).
   - `n/a: import side-effect shim`: the 56 legacy shims `chart/<type>.ts` (23) and
     `component/<name>.ts` (33).

   Until tool 6 exists (phase 2), each port change edits [parity.md](parity.md) by hand. A
   directory with a started module then gets one row for each source file. From phase 2,
   `doc/status.yaml` holds the status text. Tool 6 writes `parity.md` from it.
8. **Gallery.** From phase 6, add a demo to `apps/echarts_gallery` when a chart type or a
   component works. The layout rule of Chart.js ADR 0031 applies: the chart is in view after the
   first frame.
9. **Gates.** Run `format:check`, `analyze`, `test --no-select`, `test:web`, `check:port` and
   `upstream:check`. From phase 2, also run `test:cases`. From phase 6, also run
   `test:fixtures`.
10. **PR and merge.** Write a signed-off Conventional Commit with the scope
    `flutter_echarts_port`. A backport adds one of these lines below the header (ADR 0006 item
    3):
    - `// Upstream backport: apache/echarts@<sha8> (#<PR>).`
    - `// Upstream backport: ecomfe/zrender@<sha8> (#<PR>).`

    The reviewer compares the Dart file with upstream, side by side.

### 1.1 Performance rule

The performance rule of the Chart.js porting flow (§1.1) applies to the ECharts port. When two or
more Dart forms give the upstream behavior, choose the form with the larger measured performance
gain. ECharts ADR 0003 names the upstream behavior in ECharts terms. Examples are the ticks, the
display-list order, the hit element and the merged option of `getOption()`.

The order of priority is:
1. The upstream behavior.
2. Performance: the figures of `doc/performance.md`. Phase 3 adds that file. Phase 6 adds the
   frame figures.
3. The upstream structure (AGENTS.md rule 2).
4. Less code of our own.

A form with no measured gain keeps the upstream structure. A faster form that changes the
upstream structure gets a `DIVERGES` marker and an `adapt` row in `differences.md`. Record each
measured change in `doc/performance.md`.

## 2. Decisions

"Gate" is the first phase whose code depends on the decision. The porting lead accepts an ADR
when the phase implements the decision and the gates are green (AGENTS.md).

Phase 0 writes the two gate 0 ADRs, ADR 0007 and ECharts ADR 0001. It applies them while they
are proposed, as D3 phase 0 did. ECharts ADR 0001 item 1 lists four points for the maintainer:
the package name, the license of the port, the pin rule and the components of node-timsort,
jsdiff and tween.js. Section 7 asks for the maintainer selection of the name (question 1) and of
the components (question 6).

[ADR 0001](../../../docs/adr/0001-native-ports-not-wrappers.md),
[ADR 0005](../../../docs/adr/0005-pin-upstream-sources.md) and
[ADR 0006](../../../docs/adr/0006-follow-upstream-between-releases.md) are accepted and common to
all ports. ADR 0007 (accepted 2026-10-22) and ADR 0008 (proposed) are cross-port decisions. The other decisions are for
ECharts only. Each ECharts-only decision becomes a file in [`adr/`](adr/) with the next free
number, at its gate or before it. If a later port needs the same decision, the decision moves to
`docs/adr/` as a new ADR. This is the rule of the Chart.js porting flow §2.

A Chart.js ADR binds only the Chart.js port. A D3 ADR binds only the D3 port. Thus each ECharts ADR
states the rules that it takes. The ECharts ADRs cite the current Chart.js numbers:
- [Chart.js ADR 0032](../../flutter_chartjs_port/doc/adr/0032-js-numeric-semantics.md): the JS numeric
  rules and the reference engine. It supersedes Chart.js ADR 0010.
- [Chart.js ADR 0034](../../flutter_chartjs_port/doc/adr/0034-no-display-only-js-exactness.md): no
  display-only JS exactness. It supersedes Chart.js ADR 0009.
- [Chart.js ADR 0035](../../flutter_chartjs_port/doc/adr/0035-third-party-sources.md): the third-party
  sources. It supersedes Chart.js ADR 0011.
- Chart.js ADRs 0012 and 0023: the file names and the underscore members (ECharts ADR 0002).
- Chart.js ADRs 0006, 0020 and 0021: the option values, the class values and the typed options
  (ECharts ADR 0004).
- Chart.js ADRs 0022, 0029 and 0030: the chart harness, the fixture smoke runner and the reference
  tests (ECharts ADR 0005).
- Chart.js ADRs 0013, 0015, 0016 and 0019: the canvas model, the text, the frames and the
  animation clock (ECharts ADR 0006).
- Chart.js ADR 0037: the input events and the chart host (ECharts ADR 0007). It supersedes
  Chart.js ADR 0014. The event table of ECharts ADR 0007 keeps the stylus kinds of Chart.js ADR
  0014 §6 until the ECharts lead decides (ECharts ADR 0007, Open).
- Chart.js ADRs 0024 and 0026: the dates and the number formatting (ECharts ADR 0008). Chart.js
  ADR 0026 does not apply to ECharts (2.10).
- Chart.js ADRs 0001 and 0031: the theming invariants and the gallery layout rule (ECharts ADR
  0009).

The ECharts ADRs also take rules from D3 ADRs 0002 to 0006. All D3 ADRs are proposed.

| Subsection | Decision | Gate | Status |
|---|---|---|---|
| 2.1 | [ADR 0007: Package names](../../../docs/adr/0007-package-names.md) | 0 | accepted 2026-10-22. It supersedes ADR 0003 |
| 2.2 | [ADR 0008: Shared JS runtime and port tools](../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) | 1 | proposed |
| 2.3 | [ECharts ADR 0001: Upstream sources](adr/0001-upstream-sources.md) | 0 | proposed |
| 2.4 | [ECharts ADR 0002: File naming and package layout](adr/0002-file-naming-and-layout.md) | 1, forward types 2 | proposed |
| 2.5 | [ECharts ADR 0003: Numbers, number strings and JS semantics](adr/0003-numbers-and-js-semantics.md) | 1 | proposed |
| 2.6 | [ECharts ADR 0004: JS values, classes and options](adr/0004-js-values-classes-and-options.md) | 1, classes, element access and TS types 2 | proposed |
| 2.7 | [ECharts ADR 0005: Spec harness, reference tests and the visual pages](adr/0005-spec-harness-and-reference-tests.md) | 1, chart references 5, smoke runner 6 | proposed |
| 2.8 | [ECharts ADR 0006: Renderer: the zrender canvas painter on a Canvas 2D layer](adr/0006-renderer-and-canvas-layer.md) | 3 | proposed |
| 2.9 | [ECharts ADR 0007: Runtime environment, chart host and input events](adr/0007-environment-host-and-input-events.md) | 1 env and platform API, 3 handler proxy, 5 container and host | proposed |
| 2.10 | [ECharts ADR 0008: Dates, time zones, locales and formatting](adr/0008-dates-locales-and-formatting.md) | 4 | proposed |
| 2.11 | [ECharts ADR 0009: DOM-bound features, app hooks and theming](adr/0009-dom-features-app-hooks-and-theming.md) | 6, heatmap 7, XML 8, toolbox 9 | proposed |
| 2.12 | The shared Canvas 2D layer (a root ADR) | 3 | no ADR file yet |
| 2.13 | The HTML tooltip overlay | after 6 | no ADR file yet |
| 2.14 | The release models of `js_semantics` and of the shared canvas layer | 10 | no ADR file yet |
| 2.15 | The replay of the recorded visual actions | after 9 | no ADR file yet |

Subsections 2.1 to 2.11 give a summary. The ADR file holds the decision and its evidence.
Subsections 2.12 to 2.15 give the question, the facts and the proposal of the research of
2026-10-21. Their ADR decides.

### 2.1 ADR 0007: Package names (gate 0)

[ADR 0007](../../../docs/adr/0007-package-names.md) (accepted 2026-10-22) states the naming rule of
the workspace. In short:
- The library package of a port is `flutter_<library>_port` (item 1).
- `flutter_echarts` is taken on pub.dev by a WebView wrapper of ECharts. Thus the port takes the
  form `flutter_echarts_port`.
- The examination of item 7 ran at 2026-10-21T07:51Z. `https://pub.dev/api/packages/<name>` gave
  404 for `flutter_echarts_port`, `echarts_gallery` and `echarts_test_utils`. ECharts ADR 0001
  records this result (item 9).
- The gallery app is `apps/echarts_gallery` from phase 6 (item 4).
- The harness name `echarts_test_utils` is reserved (item 3). Phase 0 does not create the
  package (section 3).
- The commit scope is `flutter_echarts_port` (item 8).

### 2.2 ADR 0008: Shared JS runtime and port tools (gate 1)

[ADR 0008](../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) (proposed) holds the
decision. Its gate is D3 phase 1. In short:
- The pure Dart package `js_semantics` holds the JS runtime that two or more ports use. Stage 1
  copies 11 files with 1,881 lines from `packages/flutter_chartjs_port/lib/src/js/`. A drift check
  compares the copies.
- The dev package `port_tools` gives tools 1-3 one implementation for all ports, with a config
  file for each port. Section 4 gives the ECharts config.
- No port depends on another port (item 1). Thus ECharts code never imports
  `package:flutter_chartjs_port` or `package:flutter_d3_port`.
- New runtime code goes into new files of `js_semantics` (item 6). ECharts ADR 0003 and ECharts ADR
  0008 name the new ECharts runtime symbols.
- ECharts phase 1 needs stage 1. If D3 phase 1 does not come first, the order is open
  (section 7).

### 2.3 ECharts ADR 0001: Upstream sources (gate 0)

[ECharts ADR 0001](adr/0001-upstream-sources.md) (proposed) holds the decision. In short:
- `apache/echarts` is the upstream repository of ADR 0005. It is pinned at the lightweight tag
  `6.1.0`, commit `c5a48f5f97d23e5379720870b8444cd05b50ffb4`.
- zrender is the second project. It is pinned at the tag `6.1.0`, commit
  `32b6686724832dcea026e9443d056ea216ed0ab2`. This is the exact version of the ECharts
  `package.json:77` (`"zrender": "6.1.0"`).
- `lib/src/upstream.dart` has two constants: `echartsVersion = '6.1.0'` and
  `zrenderVersion = '6.1.0'`. The tags and the header versions have no `v`. A commit pin writes
  `6.1.0+<sha8>`.
- Both entries of `tool/port_sources.yaml` have `language: js`. The scaffold value `ts` is a phase
  0 fix: tool 3 examines only `js` projects (2.5).
- The bump unit: an ECharts bump moves `third_party/echarts` and `echartsVersion`. When the new
  `package.json` names another zrender version, the same change moves `third_party/zrender` and
  `zrenderVersion`. A zrender bump alone goes only to the version that the pinned ECharts
  requires.
- The ledger has two sections, one for each repository. Both watch `master`.
- The port is Apache-2.0. Each ported file keeps the upstream license block after its header lines
  (Apache-2.0 section 4(c)). The `// Ported from` line states that the file is a changed file
  (section 4(b)). The `NOTICE` keeps the ECharts `NOTICE` (section 4(d)).
- The holders are `The Apache Software Foundation` and `Baidu Inc.`. The ECharts `LICENSE` has no
  copyright line. Thus the shared tool 2 reads the holder from the package `LICENSE` or `NOTICE`
  (section 4).
- The project name `Apache ECharts` has a space. The shared tool 2 reads the project lazily
  (section 4).
- `upstream:check` and `test/upstream_test.dart` compare the gitlinks with the pins. Both fail on
  a submodule of `.gitmodules` that no `packages/*/tool/port_sources.yaml` pins.
- The ADR lists the paths that the port does not pin or port. Examples are `extension-src/`,
  `dist/`, `build/`, `ssr/client/`, the root `i18n/` and `theme/` folders and `test/data/`.

### 2.4 ECharts ADR 0002: File naming and package layout (gate 1, forward types gate 2)

[ECharts ADR 0002](adr/0002-file-naming-and-layout.md) (proposed) adapts Chart.js ADR 0012 and D3
ADR 0002. In short:

| Upstream | Dart (in `packages/flutter_echarts_port/`) |
|---|---|
| `echarts src/<p>.ts` | `lib/src/echarts/<p>.dart` |
| `zrender src/<p>.ts` | `lib/src/zrender/<p>.dart` |
| `echarts test/ut/spec/<p>.test.ts` | `test/specs/echarts/<p>_test.dart` |
| `zrender test/ut/spec/<p>.test.ts` | `test/specs/zrender/<p>_test.dart` |
| `echarts test/ut/core/utHelper.ts` | `test/support/echarts/utHelper.dart` |
| `echarts test/ut/core/extendExpect.ts` | `test/support/echarts/extendExpect.dart` |
| `zrender test/ut/spec/zrender.ts` | `test/specs/zrender/zrender.dart` |
| port-only library code | `lib/src/js/`, `lib/src/platform/`, `lib/src/theme/`, `lib/src/dev.dart`, `lib/src/upstream.dart`, and `lib/src/canvas/` in the fallback of ECharts ADR 0006 only |
| port-only tests | `test/port/echarts/` and `test/port/zrender/` |
| port-only test support | `test/support/jest_expect.dart`, `test/support/spec_setup.dart` |

- File names keep the upstream form. 522 source files (442 ECharts, 80 zrender) and 22 spec
  files (14 ECharts, 8 zrender) fail `file_names`. The two harness files add 2. Thus 546 files
  carry the ignore line (ECharts ADR 0002). The lint accepts the dots of the four entry names, for
  example `echarts.all`.
- Seven directories are not snake case: `axisPointer`, `dataZoom`, `effectScatter`, `singleAxis`,
  `themeRiver`, `visualMap` (ECharts) and `svg-legacy` (zrender). Four file names have a hyphen:
  `i18n/langPT-br.ts`, `i18n/langnb-NO.ts`, `series/aria-columns-exclude.test.ts` and zrender
  `svg-legacy/svg-legacy.ts`.
- All of `lib/src/echarts/` and `lib/src/zrender/` is pure: no `dart:ui` and no
  `package:flutter`.
- Dart has no import side effects. The top-level `use(...)` statements of the entry files become
  idempotent functions, for example `useAll()` in `lib/src/echarts/echarts.all.dart`. The row is
  `adapt-module-side-effects`.
- Type-only files (10 files, 856 lines by `wc -l`) get `distributed` or `n/a`.
- Forward types (gate 2): phase 2 has 132 type-only edges to 46 files of later phases. Phase 4
  has 30 edges to 20 files. The earlier phase ports each referenced class at its mapped path with
  the status `partial: <symbols>`. The port has no port-only types folder.
- The public library `lib/flutter_echarts_port.dart` gets the export set of `src/export/core.ts`
  and `src/echarts.ts` from phase 6. Phase 10 decides the Flutter API.
- Names of port-only types: `EChartsContainer`, `ZrViewport`, `EChartsHost`, `useAll()` and
  `echartsDev`.

### 2.5 ECharts ADR 0003: Numbers, number strings and JS semantics (gate 1)

[ECharts ADR 0003](adr/0003-numbers-and-js-semantics.md) (proposed) holds the decision. In short:
- It takes the rules of Chart.js ADR 0032, Chart.js ADR 0034 and D3 ADR 0003.
- The protected behavior in ECharts terms: the ticks and their shown labels, the display-list
  order, the hit element, the layouts and the item order. Also protected: the merged option of
  `getOption()`, a throw and the public return values. Examples are `convertToPixel`,
  `convertFromPixel`, `containPixel` and, once ported, `renderToSVGString`.
- Number strings go through `jsToFixed`, `jsNumberToString` and `jsToStringRadix`. An example is
  `round` at `echarts src/util/number.ts:235` (`toFixed`).
- New runtime symbols: `jsParseInt`, `jsLooseEquals` (`util/number.ts:777`), `jsToUint32`,
  `jsToUint16`, `jsTypedArraySort`, `jsDefaultSort`, `jsSameValueZero`, `jsSameValueZeroHash`,
  `jsLog`, `jsAtan`, `jsMathRandom`, `setJsMathRandomSource`, `JsSeededRandom` and
  `jsJsonDecode`. Also new: fdlibm `acos`, `asin` and `tan` as `jsAcos`, `jsAsin` and `jsTan`.
- Typed arrays use `dart:typed_data`. `Float32List` keeps the float32 values of `PathProxy`
  (`zrender src/core/PathProxy.ts:375`), because hit tests read them.
- Each fdlibm port comes with its first caller: `acos` (`zrender src/core/curve.ts:115`) and `tan`
  (`zrender src/core/Transformable.ts:315-317`) in phase 2, `asin`
  (`echarts src/util/symbol.ts:113`) in phase 4. The C files go into `third_party/fdlibm` with
  the SunPro notice.
- `Math.random` becomes the replaceable source `jsMathRandom`. Tests and generators install a
  seeded port-only generator.
- ECharts has no `Intl` and no `toLocale*` call. Thus the port needs no `package:intl`.

### 2.6 ECharts ADR 0004: JS values, classes and options (gate 1, classes and TS types gate 2)

[ECharts ADR 0004](adr/0004-js-values-classes-and-options.md) (proposed) holds the decision. In
short:
- Option trees are raw JS values, as in Chart.js ADR 0006: insertion-ordered
  `Map<String, Object?>`, `List<Object?>`, `num`, `String`, `bool`, `null`, Dart closures, dates,
  typed lists and the zrender value classes.
- Dart `null` stands for both JS `null` and `undefined`. An absent key is a Map key that is not
  there. ECharts tests `== null` at 1,062 sites (876 ECharts, 186 zrender).
- The `undefined` sentinel appears only at the six strict `undefined` sites and in specs that
  assert `undefined`. This differs from Chart.js ADR 0006.
- `zrender src/core/util.ts` ports line by line with these value rules. `HashMap` keeps SameValueZero
  keys.
- zrender elements implement `JsObjectLike` for the by-name reads and writes of the animator,
  `attr` and the states. `shape` and `style` are Maps.
- A TS type parameter that only types an option or an event map goes away. An overload set
  becomes one Dart method. A string-literal union becomes `String` (item 18, gate 2).
- The class registry uses `JsClass` of Chart.js ADR 0020. Mixins become Dart `with` clauses. The
  instance mixin of `echarts src/coord/radar/RadarModel.ts:179` becomes a subclass (row
  `adapt-instance-mixin`).
- `makeInner` becomes an `Inner<T, Host>` over an `Expando`. `SeriesData.wrapMethod` becomes
  method slots.
- `Path.extend` works. The public `extend*` API waits until after 0.1.0 (row
  `adapt-legacy-extend`).
- User callbacks go through `jsCall`. Errors are `JsError`.
- TS runs a subclass field initializer after `super()`. Dart runs it before. zrender
  `Element.ts:529-533` calls `_init` from the constructor. Thus such an initializer moves into
  the constructor body. The review examines each such class.
- `__DEV__` (349 sites in 109 ECharts files, 0 in zrender) becomes `echartsDev`. Its default is on
  when asserts are on. `util/log.ts` gets a replaceable sink.

### 2.7 ECharts ADR 0005: Spec harness, reference tests and the visual pages (gates 1, 5 and 6)

[ECharts ADR 0005](adr/0005-spec-harness-and-reference-tests.md) (proposed) holds the decision.
In short:
- The 259 upstream jest cases (191 ECharts cases in 24 files, 68 zrender cases in 12 files) port
  to `package:test`. Section 1 step 5 gives the form.
- The jest `expect` stand-in keeps the jest semantics. `toBe` is `Object.is`. `toEqual` ignores
  properties with the value `undefined` and the class.
- `extendExpect.dart` ports the 4 custom matchers, with the upstream typo
  `toBeGeaterThanOrEqualTo`.
- All specs are pure. `createChart` of `utHelper.dart` builds an `EChartsContainer` of 500 x 400
  (`echarts test/ut/core/utHelper.ts:33-61`) and calls `useAll()`. It installs the
  jest-canvas-mock text width (`text.length`) through `setPlatformAPI` (row
  `harness-canvas-mock-text`). The specs run with `domSupported` false (row
  `harness-dom-supported`).
- Tool 4 writes `doc/upstream/manifest.json` with the two projects (section 4).
- Reference values come only from an x64 build of Node.js v24.12.0. The whole-chart generators
  run the committed `third_party/echarts/dist/echarts.js` with no DOM. Section 3 gives the rules.
- The 605 visual pages get no screenshot comparison. Tool 4 extracts their charts. A smoke runner
  in the form of Chart.js tool 7 builds each chart (phase 6).
- The harness stays in `test/support/`.

### 2.8 ECharts ADR 0006: Renderer: the zrender canvas painter on a Canvas 2D layer (gate 3)

[ECharts ADR 0006](adr/0006-renderer-and-canvas-layer.md) (proposed) holds the decision. In short:
- The port keeps zrender as the renderer. `zrender src/canvas/` ports line by line against a pure
  Canvas 2D interface. A `dart:ui` implementation draws it.
- Thus zrender and ECharts stay pure layers. Upstream diffs replay on the Dart files. Tests can
  record the canvas calls.
- The Canvas 2D layer comes from a shared layer that a new root ADR decides before phase 3 (2.12).
  The fallback is an ECharts-own port-only `lib/src/canvas/`.
- The gaps of the Chart.js layer: shadows, `CanvasPattern.setTransform` with a `DOMMatrix`, a
  canvas as image source, several canvases in one host, the DOM `unsigned long` truncation of
  `width * dpr` and the WebIDL setter conversions.
- One zrender `Layer` is one canvas with its retained picture list. `ZrViewport` keeps the layers
  in DOM order. The host paints them at `1/dpr`.
- The hover layer (`HOVER_LAYER_ZLEVEL = 1e5`, `zrender src/canvas/Painter.ts:22`), the
  progressive layers and the dirty rectangles stay as upstream. `useDirtyRect` stays false by
  default.
- Hit tests stay zrender math on the float32 `PathProxy` data. zrender calls no `isPointInPath`.
- Text measures through `platformApi.measureText` on a single-line `ui.Paragraph` (Chart.js ADR
  0015). zrender keeps its own wrap, truncation and rich-text layout.
- The measure stays fast enough for the ASCII width map of `zrender src/contain/text.ts:57-77`
  (the limit 5 at `:79`). Phase 3 adds the text-metric probe against Chrome and the test font. A
  Flutter test registers a fixed advance for `'国'`.
- Frames come from a frame hook (row `platform-request-anim-frame`, Chart.js ADR 0016).
  `TickerMode` mutes the instance.
- The SVG DOM painter and `svg-legacy/` are `n/a`. The SVG string parts port in phase 10 for
  `renderToSVGString`.

### 2.9 ECharts ADR 0007: Runtime environment, chart host and input events (gates 1, 3 and 5)

[ECharts ADR 0007](adr/0007-environment-host-and-input-events.md) (proposed) holds the decision.
In short:
- `zrender src/core/env.ts` ports with the hunk `platform-env-detect` (file in phase 2). The hunk
  gives `node`, `worker`, `wxa`, `domSupported`, `hasGlobalWindow`, `pointerEventsSupported`,
  `transformSupported` and each browser flag the value false. The Flutter layer sets
  `touchEventsSupported`.
- Without the hunk, the detection gives `node` true in a pure Dart run
  (`zrender src/core/env.ts:40-49`). Then ECharts turns off the animation, the tooltip, the hover
  layer and the handler proxy.
- `zrender src/core/platform.ts` ports as it is (phase 1). Its pure default is the Node branch
  with no canvas. The Flutter layer installs `createCanvas`, `measureText`, `loadImage` and
  `getTime` (`jsDateNow`) through `setPlatformAPI` (`platform.ts:111-118`).
- `zrender src/dom/HandlerProxy.ts` is `replaced` by a port-only Flutter handler proxy (phase 3).
  It keeps the `Eventful` contract and the event names.
- When zrender calls `eventTool.stop` (`zrender src/core/event.ts:296-299`), the host claims the
  pointer in the gesture arena. A stopped wheel registers with `pointerSignalResolver`. Without
  `stop`, the host stays out of the arena (Chart.js ADR 0037).
- `EChartsContainer` is the pure stand-in for the `init(dom)` element (phase 5). `EChartsHost` is
  the internal render object. It sizes in the first layout and calls `chart.resize()` on a size
  change.
- The public widget API waits for phase 10.

### 2.10 ECharts ADR 0008: Dates, time zones, locales and formatting (gate 4)

[ECharts ADR 0008](adr/0008-dates-locales-and-formatting.md) (proposed) holds the decision. In
short:
- ECharts changes dates through local and UTC setters that it selects by name
  (`echarts src/scale/Time.ts:495-531`, `src/util/time.ts:453-469`). Thus the port adds a mutable
  `JsDate` with the ECMAScript field algorithms and a `JsDateField` enum.
- Local time goes through a `DateZone` interface, as in Chart.js ADR 0024. `JsDate` and the zone
  code go into new `js_semantics` files. D3 phase 3 shares them. Phase 1 adds a `JsDate` subset
  and the zone files, because the pilot ports `parseDate` (ECharts ADR 0008 §3).
- `parseDate` (`echarts src/util/number.ts:502-561`) ports line by line. A user `DateTime` counts
  as a JS `Date`.
- `useUTC` is false by default (`echarts src/model/globalDefault.ts:127`). Thus the specs run in
  `Etc/UTC` and in `America/Los_Angeles`. The reference generators run with `TZ=UTC`.
- ECharts builds its number and date text by hand with no `Intl`. Thus Chart.js ADR 0026 does not
  apply. `addCommas` (`echarts src/util/format.ts:32-39`) and `formatTpl` port line by line with
  a new `jsStringReplace`.
- The 27 `src/i18n` locale files port as Dart data files: `langEN` and `langZH` in phase 4, the
  other 25 in phase 10.
- `SYSTEM_LANG` is `EN` with `domSupported` false (`echarts src/core/locale.ts:39-44`). The
  Flutter layer gives the app locale (`zh` gives `ZH`, else `EN`) unless the app sets one.

### 2.11 ECharts ADR 0009: DOM-bound features, app hooks and theming (gates 6, 7, 8 and 9)

[ECharts ADR 0009](adr/0009-dom-features-app-hooks-and-theming.md) (proposed) holds the decision.
In short:
- With `domSupported` false, `renderMode: 'auto'` gives the `richText` tooltip upstream
  (`echarts src/util/model.ts:1044-1052`). zrender draws it. This is the first target.
- An explicit `'html'` maps to `richText` with the row `platform-tooltip-html` until a later ADR
  decides a Flutter overlay (2.13). A formatter that returns an `HTMLElement` is `n/a`.
- The aria attributes of the container feed the host semantics.
- `getDataURL` and `getConnectedDataURL` return a `Future`, because `dart:ui` encodes images
  asynchronously (row `platform-data-url-async`).
- Browser actions become app hooks with no plugin in `lib/`: `openLink` (row
  `platform-window-open`) and `onSaveAsImage`. DataView becomes a Flutter overlay panel (row
  `platform-dataview-dom`).
- The heatmap computes its intensity field in Dart (row `platform-heatmap-pixels`). Decal tiles
  use `toImageSync`.
- Phase 8 selects the XML parser of the SVG maps: a port-only parser or `package:xml`. The GeoJSON
  `new Function` fallback becomes a JSON decode (row `platform-geojson-function`).
- The four theming invariants of Chart.js ADR 0001 carry over. ECharts themes are per instance
  (`init(dom, theme)`, `setTheme` at `echarts src/core/echarts.ts:826`). Thus the port needs no
  theme hunks and no `theme` category. `lib/src/theme/` maps a Flutter theme to an ECharts theme
  object.

### 2.12 The shared Canvas 2D layer (gate 3)

**Question.** Where do the Canvas 2D interface and its `dart:ui` implementation come from?

**Facts.**
- The zrender canvas painter needs the full Canvas 2D surface: styles, text, transforms, clips,
  images, a retained bitmap and the device pixel ratio.
- The Chart.js port has this layer in `packages/flutter_chartjs_port/lib/src/canvas/` (Chart.js ADRs
  0013 and 0015). ADR 0008 item 1 forbids an import of it.
- The D3 porting flow §5.1 keeps the deferred plan "A shared canvas layer". Its trigger is a caller
  that needs styles, text or transforms on a context. zrender is such a caller.
- The Chart.js layer parses colors with its `@kurkle/color` port. `js_webidl` stays in
  `flutter_chartjs_port` until a second port needs it (ADR 0008 item 3).

**Proposal.** A new root ADR with the next free number, proposed before phase 3, by the method of
ADR 0008:
1. Stage 1 copies the Chart.js `lib/src/canvas/` at one commit, with a drift check. It adds the
   gaps of 2.8. It changes no Chart.js file.
2. Stage 2 moves the Chart.js port onto the shared layer at a Chart.js phase boundary.
3. The pure interface and the `dart:ui` implementation get names by ADR 0007 items 6 and 7.
4. The ADR decides the license of the copied port-only files and the color parser dependency.

The fallback of ECharts ADR 0006 is an ECharts-own `lib/src/canvas/`.

### 2.13 The HTML tooltip overlay (after phase 6)

**Question.** Does the port draw the HTML tooltip of `renderMode: 'html'` as a Flutter overlay?

**Facts.**
- `TooltipHTMLContent.ts` (568 lines) builds a DOM element with CSS text. It reads `offsetWidth`
  for its size. The `TooltipRichContent.ts` (243 lines) draws with a zrender `Text`.
- ECharts ADR 0009 maps `'html'` to `richText` (row `platform-tooltip-html`).
- The gallery layout rule (Chart.js ADR 0031) asks that overlays fit at 360 x 640.

**Proposal.** A later ECharts ADR, when the gallery or a user needs `'html'`. Its scope: an HTML
and CSS subset, a synchronous size, `appendTo` as an `OverlayPortal`, `enterable` and the DOM
ownership test of the handler proxy.

### 2.14 The release models (phase 10)

**Question.** How does `flutter_echarts_port` 0.1.0 get `js_semantics` and the shared canvas
layer on pub.dev?

**Facts.** A package on pub.dev can depend only on packages on pub.dev. ADR 0008 (Consequences)
leaves the release model of `js_semantics` open. The two candidates are a release with a semver
contract and a copy in each released port. The shared canvas layer (2.12) has the same question.

**Proposal.** One new ADR for each shared package, at the first release plan of any port. Phase 10
of this port needs both.

### 2.15 The replay of the recorded visual actions (after phase 9)

**Question.** Does the port replay the recorded actions of the visual pages?

**Facts.**
- `echarts test/runTest/actions/` has 273 files. They record mouse moves, wheels, clicks and
  input changes in page coordinates of the Chrome layout of `testHelper`.
- A replay needs the chart rectangles of that layout. The port has no such layout.

**Proposal.** No replay before phase 9. A later ADR decides it. Until then, the smoke runner builds
each chart without its actions (ECharts ADR 0005).

## 3. Test harness

**Package.** Phase 0 adds no harness package. ECharts has no upstream harness package. Its
helpers `utHelper.ts` and `extendExpect.ts` belong to the ECharts repository. Thus the harness
goes to `test/support/`. The name `echarts_test_utils` is reserved (ADR 0007 item 3). A new
ECharts ADR moves the harness to that package on one of two triggers:
1. A second package needs the harness, for example the gallery or a design-system adapter.
2. The harness needs `flutter_test` as a regular dependency.

**Where tests run.**

| Suite | VM: `flutter test`, 3 OS | `dart test -p chrome -c dart2js` | `-c dart2wasm` |
|---|---|---|---|
| Upstream specs and pure port-only tests | yes | yes | yes |
| Other tests (`@TestOn('vm')`): `upstream_test.dart`, host widget tests, the smoke runner | yes | no | no |

- A pure-layer file reaches neither `dart:ui` nor `package:flutter` through its imports. All of
  `lib/src/echarts/` and `lib/src/zrender/` is pure. The Flutter layer in `lib/src/platform/` and
  the `dart:ui` canvas are not. Tool 1 computes the pure layers (section 4).
- zrender and ECharts reach `dart:ui` only through the Canvas 2D interface and the platform API.
  Thus all 259 upstream cases run on the VM, dart2js and dart2wasm.
- The first pure test of `flutter_echarts_port` adds the package to `test:web` (phase 1). Without
  a test to run, `dart test -p chrome` exits with code 79. Then the CI job `test-web` fails.

**Chart specs.** 14 ECharts spec files make a chart with `createChart`. Upstream runs them in
jsdom with jest-canvas-mock 2.5.0. No upstream spec reads pixels or layout. One spec dispatches a
DOM `MouseEvent` (`series/custom.test.ts:115-118`). One spec reads an attribute of the chart DOM
(`series/aria-columns-exclude.test.ts:82-83`). Thus the port runs them as pure tests with harness
stand-ins, with no `testWidgets`:
- `createChart` builds an `EChartsContainer` with `clientWidth` 500 and `clientHeight` 400. It
  calls `useAll()`, the port of the side effects of `src/echarts.all.ts`.
- The text width is `text.length` in UTF-16 code units, as jest-canvas-mock
  `lib/classes/TextMetrics.js:24` gives it (row `harness-canvas-mock-text`).
- The specs run with `domSupported` false. Upstream ran them in jsdom (row
  `harness-dom-supported`).
- A harness helper injects zrender events for `series/custom.test.ts:113-118`.
- The zrender specs ran in the jest environment `node`. They keep the no-canvas fallback width map
  of `zrender src/core/platform.ts:33-52`. `core/platform.test.ts` expects `12.06` for `'A'` at
  18px.

**Spec set-up.** `setUpSpecs()` of `test/support/spec_setup.dart` is the first call in each
`main()`. It turns on `echartsDev`, as the jest global `__DEV__: true` does. It pins the time zone.
After each test, it restores the log sink, the platform API, the random source and the theme and
locale registries.

**Time zones.** `useUTC` is false by default. The time specs read local dates. From phase 4, the
specs run in `Etc/UTC` and in `America/Los_Angeles` (ECharts ADR 0008). The harness installs the
zone in the test, as D3 does.

**Reference values.**
- Reference values come only from an x64 build of Node.js v24.12.0 (Chart.js ADR 0032). On Apple
  silicon, the darwin-x64 build runs under Rosetta. Test names are not reference values.
- The specs carry their expected values inline. Port-only reference tests in `test/port/` take
  their data from generators in `tool/reference/`.
- A whole-chart generator (from phase 5) loads the committed `third_party/echarts/dist/echarts.js`
  (`version = '6.1.0'`, zrender inlined) with no DOM. Thus both sides use the fallback width map
  of zrender.
- A generator stops unless the gitlink equals `commit` of `tool/port_sources.yaml`,
  `git status --porcelain` is empty and the version is `6.1.0`.
- A module-level generator strips the types from `src/` with `module.stripTypeScriptTypes`, or
  uses a clone outside the repository (section 7).
- Determinism: a frozen clock with 16 ms frames, a seeded port-only PRNG in the generator and in
  the harness, and the option `animation: false`.
- The observations are `getOption()`, the axis extents and ticks, `convertToPixel`,
  `containPixel`, hit queries and the zrender display list. Later they add the canvas calls and
  the SSR string.
- Numbers compare at 1e-9 absolute or 1e-12 relative. A data file has at most 2.5 MB.

**Visual pages (phase 6).** ECharts has 605 visual pages `test/*.html` with about 1,444 charts.
Upstream commits no reference image: `test/runTest/` compares two ECharts builds in one Chrome.
Thus the port compares no screenshots (Chart.js ADR 0034 §4). A smoke runner builds each chart:
- Tool 4 extracts the charts into `doc/upstream/fixtures.json`, with the SHA-256 of each page.
- The runner uses the tag `fixtures`, the script `test:fixtures`, the CI job `fixtures` and
  `FIXTURES_REQUIRED=1`, as Chart.js tool 7 does.
- Hand ports go to `test/fixtures/hand/<path>.dart`. Skips go to `test/fixtures/index.dart`.
- The runner reads the pages from the submodule. Thus it has `@TestOn('vm')`.
- Structural references cover a curated subset: one for each chart type and each major
  component.

**Skips.**
- A case that needs a module of a later phase skips as `'blocked: echarts/src/<path>.ts'` or
  `'blocked: zrender/src/<path>.ts'`.
- The 16 + 8 pages of `test/runTest/blacklist.js` skip as `'n/a: blacklisted upstream'`.
- Pages that need extensions, ecStat or bmap skip with an `n/a` reason.

## 4. Tooling

The Chart.js port has eight per-module tools in `packages/flutter_chartjs_port/tool/`
([the Chart.js porting flow](../../flutter_chartjs_port/doc/porting-flow.md) §4). They know only the
Chart.js port. At commit `4d50cd8`:
- The header pattern reads the project as `(\S+)` (`tool/src/headers.dart:13-16`). Thus it cannot
  read `Apache ECharts`.
- The port-only marker and the backport line are Chart.js patterns (`tool/src/headers.dart:19-25`).
- The harness `chartjs_test_utils` is a constant (`tool/src/port_headers.dart:62`).
- The `language` values are `js` and `c` (`tool/src/port_headers.dart:89`). Tool 3 examines only
  the files of a `js` project (`tool/src/js_semantics.dart:236-240`).
- The marker `DIVERGES(chartjs)` is fixed (`tool/src/port_headers.dart:551`).
- The holder check reads only the package `LICENSE` (`tool/src/port_headers.dart:632`, `:956-957`).
- The pure roots are a constant list (`tool/src/lib_imports.dart:119`).

[ADR 0008](../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) (proposed) makes one set
of tools serve all ports, in the dev package `port_tools`. The ECharts port uses it in this form:
1. Stage 1 copies tools 1-3 and their tests into `packages/port_tools`. Each tool reads a config
   file of each port. ADR 0008 gives the gate D3 phase 1. ECharts phase 1 also needs stage 1
   (section 7).
2. The ECharts config is in `packages/flutter_echarts_port/tool/`. It gives these values:
   - two projects with two version constants: `Apache ECharts` with `echartsVersion`, and
     `zrender` with `zrenderVersion`
   - the project name `Apache ECharts` in the port-only marker
   - the tag `DIVERGES(echarts)`, `doc/differences.md` and the categories `adapt`, `platform`,
     `js-semantics`, `harness` and `not-followed`
   - no harness package
   - the pure roots `lib/src/echarts/` and `lib/src/zrender/`, with `package:js_semantics/` in
     the allowlists
   - the theme directory `lib/src/theme/`
   - the ADR names of the messages
3. Two changes of the shared tool 2 serve ECharts. They leave each Chart.js and D3 header parse
   unchanged:
   - The project is read lazily: `(.+?)` before the version.
   - The holder check reads the package `LICENSE` or the package `NOTICE`. Apache-2.0 puts the
     attribution in `NOTICE`.
4. The backport line takes `<owner>/<repo>` from the `url` of the `port_sources.yaml` entry:
   `apache/echarts` or `ecomfe/zrender`.
5. A CI step runs both tool sets over the Chart.js packages. It compares their output byte for
   byte. Thus it tests the phase 1 exit criterion "with the Chart.js outputs unchanged".
6. Tools 5, 6 and 8 move to `port_tools` by the same method when a second port needs them. Tool 4
   is a Node.js tool. Each port keeps its own tool 4.

| Tool | Chart.js command | ECharts phase | What the ECharts port needs |
|---|---|---|---|
| 1. Library import guard | `check:lib-imports` | 1 | The allowlists of `lib/`, of the pure layers and of the web tests of `flutter_echarts_port`, with `package:js_semantics/`. The pure roots `lib/src/echarts/` and `lib/src/zrender/`. No ported file imports `lib/src/theme/` |
| 2. Header check | `check:headers` | 1 | The two entries of `tool/port_sources.yaml` with their targets. The lazy project `Apache ECharts`. The holder from `LICENSE` or `NOTICE`. `DIVERGES(echarts)`. The backport lines of `apache/echarts` and `ecomfe/zrender`. The ignore line and the upstream license block after the header lines. The two gitlinks |
| 3. JS-semantics check | `check:js-semantics` | 1 | Both projects with `language: js`. ECharts ADR 0003 and ECharts ADR 0004 can add ECharts forms |
| 4. Upstream manifest | `upstream:manifest` | 2, visual pages 6 | An ECharts Node.js tool of its own (ADR 0008). It reads the jest case names at run time. Output: `doc/upstream/manifest.json` with two projects (191 and 68 cases). From phase 6, also `doc/upstream/fixtures.json` |
| 5. Spec-case tracking | `test:cases` | 2 | The spec paths `test/specs/echarts/` and `test/specs/zrender/`, the manifest keyed by project and `--exclude-tags fixtures`. It moves to `port_tools` (ADR 0008) |
| 6. Parity generator | `parity`, `parity:check` | 2 | One row for each source file, grouped by repository and directory, from `doc/status.yaml`. It replaces the hand-written [parity.md](parity.md). It moves to `port_tools` (ADR 0008) |
| 7. Fixture smoke runner | `test:fixtures` | 6 | The charts of the 605 visual pages (section 3). Tool 5 with `--fixtures` reports them |
| 8. Port-order helper | `port:next` | 2 | The file-based order of both repositories, with the bare specifier `zrender/src/<p>`. The value graph has no cycle. Thus the file order fits ECharts. It moves to `port_tools` (ADR 0008) |

**Tool 4 and the upstream specs.** The specs are TypeScript files for jest. Tool 4 does not run
`npm install`. It reads the case names at run time:
- `module.stripTypeScriptTypes` of Node.js removes the types.
- Stub imports stand in for the `src/` modules.
- `describe` and `it` record the names.

The probe of the research gave 191 ECharts and 68 zrender cases this way. A one-time `jest --json`
run in a clone outside the repository can confirm the numbers. ADR 0005 item 2 lets a dev-time
tool read a reference source. No tool builds a source inside `third_party/`.

**ECharts checks.**
- **Pin checks** of phase 0 (ECharts ADR 0001): `upstream:check` (`tool/check_upstream_pin.sh`,
  CI job `upstream-pin`) and `packages/flutter_echarts_port/test/upstream_test.dart`. The script
  reads the tags with `git ls-remote` and the gitlinks from the index. The test compares both
  versions with the two `package.json` files.
- **Runtime drift check** `check:js-runtime-drift` (ADR 0008 stage 1). Until stage 2, it fails
  when a shared file and its Chart.js copy differ.
- **Canvas drift check** of the shared Canvas 2D layer (2.12), from its stage 1.

**`differences.md` schema.** The schema of the Chart.js porting flow §4 applies. Each row is one
difference. One or more `DIVERGES` hunks name it. The columns are ID, Dart file and symbol,
Upstream file@version:lines, Category, Reason, Upstream reference, `Pinning test` and Re-check on
bump.
- The ID starts with the lowercase category: `adapt`, `platform`, `js-semantics`, `harness` or
  `not-followed`. ECharts themes are per instance. Thus the port has no `theme` category
  (ECharts ADR 0009).
- One tag serves both repositories: `DIVERGES(echarts)`. ADR 0008 item 8 gives one tag and one
  `differences.md` to each port config. D3 uses one tag for 34 repositories. The Chart.js port
  uses `DIVERGES(chartjs)` in its `@kurkle/color` files too.
- The Upstream column names the repository, for example
  `echarts src/util/number.ts@6.1.0:222-237` or `zrender src/core/env.ts@6.1.0:41-47`.
- The marker text after `DIVERGES(echarts): ` starts with the ID. [differences.md](differences.md)
  exists from phase 0, with no rows. It lists the 19 row IDs that the ECharts ADRs reserve.

**Node and ADR 0001.** Tool 4 and the reference generators run Node.js on the machine of the
porter and in the CI job `upstream-manifest`. A dev-time Node tool is not runtime. Nothing in
`lib/` or `test/` loads it ([ADR 0001](../../../docs/adr/0001-native-ports-not-wrappers.md)).

## 5. Phases

The phase numbers are integers. The counts use `git ls-files` and `wc -l` at the pins
([parity.md](parity.md#by-phase)).

| Phase | Name | Files | Lines | Spec cases |
|---|---|---:|---:|---:|
| 0 | Scaffold and design | 0 | 0 | 0 |
| 1 | Decisions, tooling, pilot | 5 | 2,178 | 39 |
| 2 | Foundations | 88 | 26,564 | 39 |
| 3 | Renderer (zrender) | 71 | 18,835 | 34 |
| 4 | Data and model | 47 | 19,034 | 53 |
| 5 | Core (the update pipeline) | 10 | 5,397 | 0 |
| 6 | First charts and the gallery | 117 | 26,274 | 0 |
| 7 | More cartesian and polar series, markers, graphic | 105 | 19,629 | 0 |
| 8 | Other coordinate systems, hierarchy, graph and geo | 128 | 26,687 | 5 |
| 9 | Interaction and transitions | 84 | 15,866 | 83 |
| 10 | Release set and 0.1.0 | 61 | 9,260 | 6 |
| | total | 716 | 169,724 | 259 |

| Phase | Scope | Exit criteria |
|---|---|---|
| 0. Scaffold and design | The package, the two submodules, `port_sources.yaml`, `echartsVersion` and `zrenderVersion`, `upstream_test.dart`, the pin checks, `LICENSE`, `NOTICE`, `REUSE.toml`, `LICENSES/Apache-2.0.txt`, the docs, prior art, ECharts ADRs 0001-0009 (proposed), the commit scope, the workspace entry and the CI checkout. No ported file | CI green (format, analyze, `test` with the ECharts `upstream_test.dart` on ubuntu, `upstream-pin`, `reuse`). `upstream:check` passes for the Chart.js, D3 and ECharts pins. No change in the Chart.js packages and app. The root `pubspec.lock` is unchanged |
| 1. Decisions, tooling, pilot | `echarts src/util/number.ts` and zrender `core/vector.ts`, `matrix.ts`, `util.ts`, `platform.ts`. 39 cases. The jest `expect` stand-in, `spec_setup.dart` and `extendExpect.dart`. Stage 1 of ADR 0008 with the ECharts config. The `JsDate` subset and the zone files of ECharts ADR 0008 §3. The zrender and d3 components | The 39 cases pass on the VM, dart2js and dart2wasm. Tools 1-3 are green for ECharts with the Chart.js outputs unchanged. The number strings of `util/number.ts` match x64 Node.js v24.12.0 reference strings. `reuse lint` passes |
| 2. Foundations | 68 renderer-free ECharts files and 20 zrender files. 39 cases. The `partial` ports of the forward-referenced classes. Tools 4, 5, 6 and 8. The node-timsort, jsdiff and `OrientedBoundingRect.ts` notices. fdlibm `acos` and `tan` | The 39 cases pass on three legs. `test:cases` reports no `missing` case of a ported file. `parity` writes `parity.md` from `doc/status.yaml`. The manifest lists 191 ECharts and 68 zrender cases |
| 3. Renderer (zrender) | 71 zrender files: the scene graph, the animation, the shapes, `contain/`, the canvas painter and `svg/helper.ts`. The Flutter handler proxy. The Canvas 2D layer and the frame hook. The tween.js notice. The test font, the text-metric probe and `doc/performance.md` (ECharts ADR 0006 §9, risk 17). 34 cases | The 34 cases pass on three legs. Reference tests of zrender scenes on a canvas that records its calls pass. A Flutter test paints a scene through the `dart:ui` canvas against its own golden. Widget tests show the zrender event names. `doc/performance.md` has the figures of the large-data benchmark |
| 4. Data and model | 47 ECharts files: `util/graphic`, `format`, `time`, `label/`, `model/`, `data/SeriesData`, the scales, the axis base, `core/locale`, `langEN` and `langZH`. The other `JsDate` methods in `js_semantics`. The d3 `REUSE.toml` path of `lib/src/echarts/scale/Time.dart`. 53 cases | The 53 cases pass on three legs in `Etc/UTC` and in `America/Los_Angeles`. The `JsDate` methods are in `js_semantics` with their tests |
| 5. Core (the update pipeline) | 10 ECharts files with `core/echarts.ts` (3,433 lines) and `core/Scheduler.ts`. `EChartsContainer`, `EChartsHost`, `createChart` and the base of the whole-chart generators | `init`, `setOption`, `resize` and `dispose` run on the pure harness container with an empty option and with a registered test series. A widget test mounts `EChartsHost` and paints. A whole-chart generator runs under x64 Node.js v24.12.0. Its data loads in a Dart test |
| 6. First charts and the gallery | 117 ECharts files: line, bar, scatter, pie, the axis stack, grid, polar, dataset, title, plain legend, tooltip, aria, export and the canvas renderer. The smoke runner. `apps/echarts_gallery`. The frame figures of `doc/performance.md` | Whole-chart reference tests of a curated set pass. The chart-spec cases that need only ported modules pass. The smoke runner passes or skips with a valid reason. The gallery builds for Android, iOS, web (wasm) and macOS, with the chart in view at 412 x 915. Frame figures are in `doc/performance.md` |
| 7. More cartesian and polar series, markers, graphic | 105 ECharts files: boxplot, candlestick, effectScatter, heatmap, lines, custom, gauge, funnel, themeRiver, pictorialBar, markers, graphic, transform, singleAxis and axis break | Reference tests of each new series type pass. The smoke pages of these series pass or skip with a valid reason. The custom-series chart cases pass when their modules are ported |
| 8. Other coordinate systems, hierarchy, graph and geo | 126 ECharts files: radar, parallel, calendar, geo and map, matrix, tree, treemap, sunburst, graph, sankey, chord, the roam and brush controllers. zrender `tool/parseSVG.ts` and `tool/parseXML.ts`. 5 cases | The 5 cases pass. Reference tests of each layout pass with a seeded random source. GeoJSON and SVG maps register and draw in reference tests |
| 9. Interaction and transitions | 84 ECharts files: dataZoom, brush, toolbox, visualMap, timeline, scroll legend, thumbnail, universal transition, `echarts.simple.ts`, `export/features.ts` and 13 shims. 83 cases | The 83 cases pass or skip with a valid reason. Roam, slider and brush gestures work in widget tests with the arena rules. Transitions pass under a fake clock |
| 10. Release set and 0.1.0 | 38 ECharts files: the bundles, the export files, 25 locales and the SVG renderer install. 23 zrender files: the SVG string painter, `svg-legacy/` (`n/a`), `debug/` (`n/a`) and the barrels. 6 cases. The public Flutter API, the release models, pana | All 259 cases pass or skip with a valid reason. `renderToSVGString` matches x64 Node.js SSR strings for the curated set. `flutter_echarts_port` 0.1.0 is on pub.dev |

Notes on the phases:
- **Phase 1.** The pilot has 5 files with 2,178 lines: `util/number.ts` (835 lines) and zrender
  `core/vector.ts` (210), `matrix.ts` (156), `util.ts` (859) and `platform.ts` (118). Its 39
  cases are `util/number` 24, `core/matrix` 1, `core/platform` 3 and `core/util` 11.
  `util/number.ts` holds d3 code. Thus the d3 component comes with it.
- **Phase 1 and ADR 0008.** ADR 0008 names D3 phase 1 as the gate of stage 1. If ECharts phase 1
  starts first, the order is open (section 7). The ECharts pilot calls `toFixed`, `Math.log` and
  the loose `==` (`util/number.ts:235`, `:317-318`, `:777`).
- **Phase 2.** The 68 ECharts files are `util/` 14, `data/` 16, `scale/` 7, `model/` 9, `visual/`
  9, `processor/` 4, `preprocessor/` 2, `core/` 6 and `coord/AxisBaseModel.ts`. The 20 zrender
  files are 18 more files of `core/`, `config.ts` and `tool/color.ts`. The specs are
  `data/createDimensions` 5, `data/dataValueHelper` 10, `util/model` 5, zrender `core/LRU` 1,
  `core/arrayDiff` 3 and `tool/color` 15. The forward types of ECharts ADR 0002 apply first.
- **Phase 3.** The shared Canvas 2D layer (2.12) or the fallback comes first.
  `animation/Animator.ts:23` imports `svg/helper.ts`. Thus that file is in phase 3. The planner
  moved `tool/parseSVG.ts` (965 lines) and `tool/parseXML.ts` (22) to phase 8. Only
  `zrender src/export.ts:10` (phase 10) and `echarts src/coord/geo/GeoSVGResource.ts:20,26`
  (phase 8) import them. They need the XML decision of ECharts ADR 0009.
- **Phase 4.** The dates decision of ECharts ADR 0008 comes first. The fdlibm `asin` comes with
  `util/symbol.ts`.
- **Phase 5.** `core/echarts.ts` has 3,433 lines. The chart harness starts here. No spec file
  belongs to this phase.
- **Phase 6.** `export/api.ts` pulls `coord/geo/Region.ts` and `parseGeoJson.ts` into this phase.
- **Phases 9 and 10.** `test/ut/core/utHelper.ts` imports `src/echarts.all.ts`. Thus the 14 chart
  spec files belong to phase 9 (83 cases) and phase 10 (`model/componentMissing`, 6 cases). A
  chart case passes earlier when the modules that its options name are ported. Tool 5 reports it
  then.
- **Phase 10.** The unreferenced files port in their phases, unless the answer to question 15 of
  section 7 marks them `n/a`.

### 5.1 Deferred plans

A deferred plan records work that the port does not do now. The phases do not wait for a deferred
plan. Each deferred plan names its revisit point and its triggers. No ECharts plan file exists
yet. A row gets its own plan file at its revisit point, or when a trigger occurs.

| Plan | Revisit point | Triggers |
|---|---|---|
| The shared Canvas 2D layer: a new root ADR by the method of ADR 0008. The D3 deferred plan "A shared canvas layer" gets the ECharts trigger | Before phase 3 | The zrender canvas painter (phase 3) |
| Stage 1 of ADR 0008, if D3 phase 1 does not do it first | Before phase 1 | The first ECharts runtime call |
| The release model of `js_semantics` and of the shared canvas layer | Phase 10 | A release plan of any port |
| The HTML tooltip overlay (2.13) | After phase 6 | A gallery or user need for `renderMode: 'html'` |
| The SVG string painter as an earlier reference oracle | After phase 6 | A reference gap that the display list cannot close |
| The replay of the recorded `test/runTest/actions` (2.15) | After phase 9 | None yet |
| The root `theme/*.js` themes and `extension-src/dataTool` | After phase 10 | A user request |

The Chart.js port has the deferred plan
[`canvas-cuts-plan.md`](../../flutter_chartjs_port/doc/canvas-cuts-plan.md). It cites the root
`pubspec.lock`. Section 6 gives the rule for an ECharts change that changes that file.

## 6. Changes to other files

**Phase 0.** The scaffold changes these files outside `packages/flutter_echarts_port/`:
- the root `pubspec.yaml`: the workspace entry, and the descriptions of the melos scripts
  `upstream` and `upstream:check`
- `commitlint.yaml`: the scope `flutter_echarts_port`
- `.gitmodules` and the two submodules `third_party/echarts` and `third_party/zrender`
- `tool/check_upstream_pin.sh`: the pin checks of ECharts ADR 0001
- `.github/workflows/ci.yaml`: the checkout of the two submodules by path in the ubuntu `test`
  leg. The job `upstream-pin` needs no submodule.
- `REUSE.toml`: the `packages/flutter_echarts_port/**` table after the D3 table. Also the new
  `LICENSES/Apache-2.0.txt`
- `packages/flutter_d3_port/test/upstream_test.dart`: it reads every
  `packages/*/tool/port_sources.yaml`. This is the only D3 file that changes.

Phase 0 still has these changes, besides the docs:
- `language: js` in both entries of `tool/port_sources.yaml`
- the ECharts text of `AGENTS.md`: the intro, Commands (`test`, `upstream`, `upstream:check`),
  Layout, `third_party/`, the porting rules, Tests, Licensing and Conventions
- the ECharts text of the root `README.md`, `CONTRIBUTING.md`, `docs/README.md` and
  `docs/prior-art/other-chart-libraries.md`
- the D3 text of `AGENTS.md` "the two `tool/port_sources.yaml` files" becomes "the
  `tool/port_sources.yaml` files"

Another session works on the main checkout. It has newer versions of `AGENTS.md`,
`CONTRIBUTING.md`, `docs/README.md` and ADRs 0007 and 0008. Thus the ECharts changes of these
files are small insertions on the newer main versions.

Phase 0 changes nothing in `packages/flutter_chartjs_port/`, `packages/chartjs_test_utils/` or
`apps/chartjs_gallery/`. Phase 0 adds no dependency. Thus the root `pubspec.lock` does not
change.

**Later phases.**
- Phase 1: stage 1 of ADR 0008, if D3 phase 1 did not do it. The ECharts config of `port_tools`.
  The zrender and d3 components in the package `LICENSE` and in `REUSE.toml`. The package in
  `test:web`, with its first pure test. The AGENTS.md text for the ECharts tool commands. The
  `JsDate` subset and the zone files in `js_semantics` (ECharts ADR 0008 §3).
- Phase 2: `upstream:manifest`, `test:cases`, `parity` and `port:next` for ECharts, and the
  ECharts step of the CI job `upstream-manifest`. The node-timsort, jsdiff and
  `OrientedBoundingRect.ts` notices. The fdlibm files `e_acos.c`, `s_tan.c` and `k_tan.c` in
  `third_party/fdlibm`, with their `REUSE.toml` paths. `e_asin.c` follows in phase 4.
- Phase 3: the shared Canvas 2D layer by its root ADR, with its workspace entries and its commit
  scopes (ADR 0007), or the fallback `lib/src/canvas/`. The tween.js notice. The test font with
  its OFL notice and `REUSE.toml` table (ECharts ADR 0006 §9).
- Phase 4: the other `JsDate` methods in `js_semantics`, and the dependency of the zone source if
  ECharts ADR 0008 names one. The d3 notice and the `REUSE.toml` path of `src/scale/Time.ts`.
- Phase 6: `apps/echarts_gallery`, with its workspace entry, its commit scope `echarts_gallery`,
  its melos `gallery*` scripts and its CI gallery jobs. The ECharts part of `test:fixtures` and
  of the CI job `fixtures`.
- Phase 8: `package:xml`, if ECharts ADR 0009 selects it. The d3 notices of the three phase 8
  files.

**The deferred-plan rule.** A change that adds a dependency changes the root `pubspec.lock`.
`canvas-cuts-plan.md` of the Chart.js port cites that file. Thus that change also updates the plan
in the same commit (AGENTS.md). The Chart.js session owns the plan. Coordinate the change with it.

**ADRs.** An accepted ADR does not change. A changed decision gets a new ADR that states the
complete decision and supersedes the old ADR. A change of the gate of ADR 0008 is a change of a
proposed ADR. Coordinate it with the main session.

## 7. Risks and open questions

**Risks**

The numbers of the risks do not change, because other documents can cite them. A risk that no
longer applies stays in the list as closed.
1. **Shared work with the Chart.js and D3 sessions.** Stage 1 of ADR 0008 and the shared canvas
   layer copy Chart.js files. Until stage 2, a fix of a copied file needs the agreement of the
   Chart.js work (ADR 0008 item 6).
2. **Size.** The port has 716 files with 169,724 lines (116,142 code lines). Phase 6 ports 117
   files before the first chart draws. The value-import closure of line and bar on the simple grid
   with dataset, aria, the canvas renderer and `export/core` has 243 files with 79,612 lines.
   `src/echarts.simple.ts` has 253 files with 81,403 lines. Of them, one file is in phase 9: the
   entry itself. Phases 1-6 have 338 files with 98,282 lines. Thus a smaller milestone saves
   about 19% of the lines before the first chart. The largest files are `core/echarts.ts`
   (3,433), `util/types.ts` (2,211, type-only), zrender `Element.ts` (2,172),
   `component/axis/AxisBuilder.ts` (1,632), `data/SeriesData.ts` (1,507) and
   `chart/custom/CustomView.ts` (1,494). With type edges, one import cycle holds 248 ECharts
   files. Dart allows it. Thus the `partial:` ports of ECharts ADR 0002 grow over phases 2-6.
3. **Thin upstream coverage.** 259 upstream cases cover 714 modules. The visual pages give smoke
   tests only. The port-only reference tests carry most of the behavior (AGENTS.md rule 3).
4. **Forward type references.** Phase 2 has 132 type-only edges to 46 later files. A `partial`
   port of a class can grow over several phases (ECharts ADR 0002).
5. **Field initializers.** TS runs a subclass field initializer after `super()`. Dart runs it
   before. A base constructor that calls an overridden method sees other values in Dart
   (`zrender src/Element.ts:529-533`). The review examines each such class (ECharts ADR 0004).
6. **Text measure and CJK.** zrender takes the line height from the width of `'国'`
   (`zrender src/contain/text.ts:42`, `:180-183`). Liberation Sans has no CJK glyph. Thus the
   width comes from a fallback font that differs for each platform. The harness must pin it.
   `stWideCharWidth` also gives the width of every non-ASCII code unit in the wrap and the
   truncation (`contain/text.ts:84-95`). The ASCII width map depends on the measure time
   (`:57-77`, the limit 5 at `:79`). ECharts ADR 0006 §9 gives the rules.
7. **Float32 path data.** `PathProxy` stores its data in a `Float32Array`
   (`zrender src/core/PathProxy.ts:375`). Hit tests read the rounded values. A `List<double>` in
   place of `Float32List` changes the hit element (ECharts ADR 0003).
8. **Reference engine.** On 2026-10-21, the machine had only an arm64 Node.js v24.12.0
   (`~/.nvm/versions/node/v24.12.0/bin/node`, Mach-O arm64). Get the darwin-x64 v24.12.0 build
   before the first ECharts reference generator.
9. **Type removal in Node.js.** A module-level generator loads `src/` with
   `module.stripTypeScriptTypes`. A plain `import {X}` of a type-only name fails at the ESM link
   step. The fallback is a built clone outside the repository.
10. **Canvas layer gaps.** The Chart.js canvas layer has no shadows, no pattern transform, no
    canvas as image source and one canvas for each host. The shadow of an image or of a text on
    Impeller and skwasm needs a probe (ECharts ADR 0006).
11. **`file_names` lint.** 546 files carry the ignore line. Seven directories are not snake case.
    A future lint on directory names can fail on them. No probe ran `flutter test` on Windows or
    dart2wasm with a hyphen in a test file name (D3 risk 9).
12. **`pubspec.lock` and the deferred plan** of the Chart.js port (section 6). `package:xml` is
    the first candidate dependency (phase 8).
13. **Prior art.** [prior-art/](prior-art/README.md) lists the Dart packages and the ports in
    other languages. None is a source (AGENTS.md rule 1). A port without a license file gives
    ideas only.
14. **License notices.** Each ported ECharts file keeps the 18-line ASF block. The d3, zrender,
    node-timsort, jsdiff, tween.js and ASF-in-zrender components come with their first ported
    file (ECharts ADR 0001 item 12). A missed notice
    fails `reuse lint` or tool 2 only when the `REUSE.toml` table or the entry exists.
15. **Gesture arena.** The host claims the pointer only after `eventTool.stop`. Roam, slider and
    brush need this rule inside scroll views. Phase 9 tests it in widget tests (ECharts ADR 0007).
16. **Two pins move together.** An ECharts bump can move zrender. A zrender fix that ECharts does
    not require waits for the next ECharts release, or for a backport (ADR 0006 item 2).
17. **Large data and progressive rendering.** Large mode starts at `largeThreshold`: scatter and
    lines 2000, bar 400, candlestick 600 (`ScatterSeries.ts:138`, `LinesSeries.ts:423`,
    `BaseBarSeries.ts:216`, `CandlestickSeries.ts:141`). Progressive rendering starts at
    `progressiveThreshold` 3000, with chunks of 400 (`model/globalDefault.ts:116-117`). The
    15 ms budget of `zrender src/canvas/Painter.ts:675-682` measures the record time only.
    Flutter rasterizes later, on the raster thread. Thus one frame can record more raster work
    than one frame can draw. `LargeSymbolDraw.ts:160-170` records one `fillRect` for each point.
    Phase 3 creates `doc/performance.md` with a frameless benchmark, in the form of the Chart.js
    `main_bench.dart`. Its cases are 1e4, 1e5 and 1e6 scatter points in large mode, a line of 1e5
    points with `sampling: 'lttb'` and a chart of 3e4 bars. It records the record time, the
    raster time and the count of picture operations on the VM, dart2js and dart2wasm. A layer
    batch for runs of `fillRect` (the circle batch of the Chart.js canvas layer) comes only after
    that measurement. Phase 6 adds the frame figures of the gallery.

**Open questions**
1. Does the maintainer select the name `flutter_echarts_port` (ADR 0007 item 9)?
2. ADR 0008 names D3 phase 1 as the gate of stage 1. If ECharts phase 1 comes first, does it do
   stage 1, with an edit of the proposed ADR 0008 gate? Or does it wait for D3 phase 1?
3. Header grammar: keep `Apache ECharts` with a lazy project in the shared tool 2? Or use the
   one-token name `ECharts` and keep the Chart.js grammar (`headers.dart:13-16`)?
4. Holder check: can the shared tool 2 read the holder of an Apache-2.0 package from `NOTICE`? Or
   does the package `LICENSE` get copyright lines before the Apache text?
5. Per-file ASF blocks: does each ported ECharts file keep the 18-line upstream block (Apache-2.0
   section 4(c))? Or do `LICENSE` and `NOTICE` suffice?
6. node-timsort, jsdiff and tween.js: separate components (ECharts ADR 0001 item 1.4), or the
   fsum rule of D3 ADR 0001 item 11? zrender publishes the three files under BSD-3-Clause, with
   only a credit line or a URL.
7. The Canvas 2D layer: a new root ADR for a shared layer before phase 3, or an ECharts-own
   `lib/src/canvas/`? Which package names (ADR 0007 items 6 and 7)?
8. Is the zrender SVG string painter (`renderToSVGString`, SSR) in the scope of 0.1.0? Does it come
   earlier as a reference oracle?
9. HTML tooltip: does 0.1.0 map `renderMode: 'html'` to `richText`? Or does it need a Flutter
   overlay with an HTML and CSS subset?
10. Export: `getDataURL` and `getConnectedDataURL` as `Future`s. Is the JPEG export `n/a`, or a
    pure-Dart encoder?
11. The XML parser for SVG maps (phase 8): a port-only minimal parser or `package:xml`?
12. ECharts ADR 0006 §9 gives the Flutter tests a fixed advance for `'国'` (the em size). Is that
    enough, or do the Flutter tests need a CJK test font (risk 6)?
13. The reference engine: who installs the darwin-x64 build of Node.js v24.12.0? Before which
    phase (risk 8)?
14. Can the type removal of Node.js with module hooks load both `src/` trees for module-level
    generators? Or do they need a built clone outside the repository (risk 9)?
15. The files that no ECharts file reaches: port them in their phases, or mark them `n/a`? They
    are `util/KDTree.ts`, `util/quickSelect.ts`, `data/helper/linkList.ts`,
    `coord/geo/fix/geoCoord.ts`, `component/visualMap/typeDefaulter.ts`, and zrender
    `core/arrayDiff.ts`, `graphic/helper/smoothSpline.ts` and the six extra shapes. Only
    `KDTree.ts` imports `quickSelect.ts`. Only `svg-legacy/Painter.ts` imports `arrayDiff.ts`.
    Only `zrender src/export.ts` imports the six shapes.
    `coord/cartesian/defaultAxisExtentFromData.ts` is also unreferenced. It gets `n/a` (ECharts
    ADR 0002 §7).
16. Does the ECharts port need its own `upstream-tracking.md`, or do ADR 0006 and the ledger
    suffice?
17. `env.touchEventsSupported`: one value for each platform (true on Android and iOS), or one
    value for each pointer kind? Is a trackpad `PointerPanZoom` a `pinch` or a `mousewheel`?
18. Dark mode of the host app: does the widget select the ECharts `'dark'` theme by default?
19. Does phase 6 stop at the `echarts.simple.ts` set (line, bar, pie, simple grid, dataset, aria)?
    Do tooltip, title, legend and the polar axes then move to phase 7 (risk 2)?
20. ADR 0008 item 8 lists one project and one version constant for each config. The ECharts
    config needs two projects, the holder source `NOTICE` and the lazy project pattern
    (ECharts ADR 0001 Consequences). Does the main session extend the proposed ADR 0008 before
    stage 1?

## Appendix: evidence

The numbers of this document come from the research of 2026-10-21. It read the two submodules at
their tags and counted with `git ls-files` and `wc -l`. [parity.md](parity.md#count-script) has the
count script. The spec case counts come from a probe that ran the spec files with stub imports and
recording `describe` and `it`, on an arm64 Node.js. Case names are not reference values. The
research reports and the probes are outside the repository.

Upstream facts of this document, at the pins:
- `echarts package.json:3` (`"version": "6.1.0"`), `:76` (`"tslib": "2.3.0"`) and `:77`
  (`"zrender": "6.1.0"`)
- `echarts LICENSE:209-222` (the d3 subcomponents), `licenses/LICENSE-d3` (27 lines,
  `Copyright 2010-2016 Mike Bostock`) and `NOTICE`
  (`Copyright 2017-2026 The Apache Software Foundation`)
- `zrender LICENSE:3` (`Copyright (c) 2017, Baidu Inc.`) and `zrender src/core/timsort.ts:1`
  (`// https://github.com/mziccard/node-timsort`)
- `echarts src/` has 596 `.ts` files with 138,275 lines. `zrender src/` has 120 `.ts` files with
  31,449 lines. `echarts test/*.html` has 605 files. `zrender test/*.html` has 76 files.
  `echarts test/runTest/actions/` has 273 files.
- The commit dates of the tags: 2026-05-13 (`c5a48f5f`) and 2026-05-04 (`32b66867`).
