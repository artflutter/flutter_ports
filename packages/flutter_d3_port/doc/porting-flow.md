# D3 porting flow

- Status: proposed
- Date: 2026-10-20
- Related: [ADR 0005](../../../docs/adr/0005-pin-upstream-sources.md),
  [ADR 0006](../../../docs/adr/0006-follow-upstream-between-releases.md),
  [ADR 0007](../../../docs/adr/0007-package-names.md),
  [ADR 0008](../../../docs/adr/0008-shared-js-runtime-and-port-tools.md),
  [D3 ADR 0001](adr/0001-upstream-sources.md),
  [the Chart.js porting flow](../../flutter_chartjs/doc/porting-flow.md)

This document defines how one upstream D3 file becomes Dart code in `packages/flutter_d3_port`.
It contains the steps, the decisions, the test harness, the tools and the phase plan. It follows
the form of the Chart.js porting flow. This document owns the D3 phase numbers, the names of the
D3 decisions, the status values of the D3 port and the D3 `differences.md` schema.
[upstream-ledger.md](upstream-ledger.md) lists the upstream commits after the pins
([ADR 0006](../../../docs/adr/0006-follow-upstream-between-releases.md)).

Terms:
- "ADR NNNN" is a file in `docs/adr/`. "Chart.js ADR NNNN" is a file in
  `packages/flutter_chartjs/doc/adr/`. "D3 ADR NNNN" is a file in
  `packages/flutter_d3_port/doc/adr/`.
- A "repository" is one of the 34 pinned git repositories of
  [D3 ADR 0001](adr/0001-upstream-sources.md).
- A "module" is one upstream source file. It is the status unit of D3 ADR 0001.

## 1. Life cycle of one module port

1. **Choose.** Pick a module of the current phase. Each module that it imports must be done.
   Imports can cross repositories, for example d3-array imports internmap. [parity.md](parity.md)
   gives the phase of each repository.
   - Before the first module of a repository goes to `in progress`, apply ADR 0006 item 4 ("Bump
     first") to that repository. If the repository has a newer release tag, the bump PR comes
     first. For a repository other than `d3`, only a tag inside the ranges of the pinned d3
     `package.json` counts (D3 ADR 0001 item 7). A bump moves one repository.
   - Before a phase starts, apply ADR 0006 item 5 (commit pins) to each repository of the phase.
     The `d3` tag v7.9.0 is from 2024-03-12. Thus it is more than 12 months old.
     [upstream-ledger.md](upstream-ledger.md) has the triage of the unreleased commits and the
     steps of a phase start.
2. **Read the source** at its pin (AGENTS.md rule 1). Also read the page of the function on the
   D3 docs site, in `third_party/d3/docs/`. D3 ADR 0001 gives the rule for doc text that the Dart
   file adapts.
3. **Write the Dart file.**
   - Map the path ([D3 ADR 0002](adr/0002-file-naming-and-layout.md)):
     `third_party/<repo>/src/<path>.js` becomes `lib/src/<repo>/<path>.dart`.
   - Line 1 is the header of AGENTS.md rule 2. The project, the license and the holder come from
     `tool/port_sources.yaml`.
   - When the file name fails the `file_names` lint, add `// ignore_for_file: file_names` after
     the header lines.
   - Keep the upstream order and names. Use package imports only.
   - Give each public symbol a `///` line that names the upstream symbol and file:line.
   - Call the JS runtime of `js_semantics` for JS builtins
     ([ADR 0008](../../../docs/adr/0008-shared-js-runtime-and-port-tools.md)).
     [D3 ADR 0003](adr/0003-number-to-string.md) gives the number strings.
     [D3 ADR 0006](adr/0006-generators-accessors-and-js-values.md) gives the accessors, the arity
     of user functions, `this`, `undefined` and `null`.
   - Mark each hunk that does not translate upstream lines with
     `// DIVERGES(d3): <row id>, <reason>` and a [differences.md](differences.md) row (section 4).
   - Start a port-only file with `// Original code, not ported from D3: <reason>.`
   - When two Dart forms give the upstream behavior, choose the faster form (1.1).

   The first lines of a ported file whose name fails the lint:

   ```dart
   // Ported from d3-format v3.1.2 src/formatDecimal.js (ISC, Mike Bostock).
   // ignore_for_file: file_names
   ```
4. **Licensing** (AGENTS.md Licensing, [D3 ADR 0001](adr/0001-upstream-sources.md)). The package
   `LICENSE` of phase 0 has only the ISC text of D3 and of the port. The change that ports code of
   another license component adds that component:
   - its notice in the package `LICENSE`
   - a `REUSE.toml` table, last, with every holder of its paths
   - for a new license, the file `LICENSES/<SPDX-ID>.txt`

   D3 ADR 0001 (item 10) lists these components with their exact holder strings:
   - d3-ease (BSD-3-Clause, the holder strings `Mike Bostock` and `Robert Penner`)
   - the ColorBrewer schemes of d3-scale-chromatic (Apache-2.0,
     `Cynthia Brewer, Mark Harrower, and The Pennsylvania State University`)
   - the GeographicLib notice of d3-geo (MIT, `Charles Karney`)
   - `quickselect.js` of d3-array (ISC, `Vladimir Agafonkin`)
   - d3-delaunay (ISC, the holder strings `Observable, Inc.` and `Mapbox`)
   - delaunator (ISC, `Mapbox`)
   - robust-predicates (Unlicense, `Vladimir Agafonkin`)

   `src/fsum.js` of d3-array follows upstream. It gets no PSF notice (the decision of the
   maintainer in D3 ADR 0001).
5. **Port the tests** ([D3 ADR 0004](adr/0004-spec-harness.md)).
   - The Dart path of `<repo>/test/<path>-test.js` is `test/specs/<repo>/<path>_test.dart`. An
     upstream test helper goes to `test/specs/<repo>/<helper>.dart`. The header names the
     upstream test file.
   - `test()` names equal the upstream `it()` and `test()` names. D3 ADR 0004 gives the rule for
     duplicate names and for the names that loops make.
   - Port the upstream assertions on the port-only stand-in of the Node `assert` module. Port the
     `test/asserts.js` helpers of the repository as ported files.
   - The skip reasons are `'blocked: <module>'`, `'n/a: <reason>'` and `'diverges: <row id>'`.
     A case that needs a module of a later phase skips as `'blocked: <module>'`. It names the
     missing module of the latest phase.
   - A test file whose name fails `file_names` carries the ignore line too.
   - A test file that needs `dart:io`, `dart:ui` or `flutter_test` has `@TestOn('vm')` after its
     header lines. When the file has the ignore line, `@TestOn('vm')` comes after the ignore line
     (D3 ADR 0002 section 2). The other test files use `package:test` (section 3).
   - A test of d3-format or d3-time-format restores the default locale after each test.
   - Put the tests of port-only behavior in `test/port/<repo>/<path>_test.dart`. Also put there
     the tests of a module without an upstream test (AGENTS.md rule 3).
6. **Data files.** Some tests read the data files of the pin, for example d3-array
   `test/bin-test.js:227` reads `test/data/athletes.csv`. D3 ADR 0004 gives the rules for these
   tests. D3 ADR 0001 (item 14) gives the rules for the test data from npm packages:
   world-atlas, topojson-client, csv-spectrum, robust-orientation and nextafter.
7. **Status.** The values are `not started`, `in progress`, `partial` (with a symbol list),
   `ported`, `replaced`, `distributed` and `n/a` (with a reason). These are the values of the
   Chart.js port. Thus tool 6 serves both ports with one list.

   Until tool 6 exists (phase 2), each port change edits [parity.md](parity.md) by hand. A
   repository with a started module then gets one row for each source file. From phase 2,
   `doc/status.yaml` holds the status text. Tool 6 writes `parity.md` from it.
8. **Gallery.** From phase 4, add a demo to `apps/d3_gallery` when a module draws.
9. **Gates.** Run `format:check`, `analyze`, `test --no-select`, `test:web`, `check:port` and
   `upstream:check`. From phase 2, also run `test:cases`.
10. **PR and merge.** Write a signed-off Conventional Commit with the scope `flutter_d3_port`. A
    backport adds the line `// Upstream backport: <owner>/<repo>@<sha8> (#<PR>).` below the
    header (ADR 0006 item 3), for example `d3/d3-shape@<sha8>`. The reviewer compares the Dart
    file with upstream, side by side.

### 1.1 Performance rule

The performance rule of the Chart.js porting flow (§1.1) applies to the D3 port. When two or more
Dart forms give the upstream behavior, choose the form with the larger measured performance gain.
In D3, the upstream behavior includes the exact strings of the modules whose result is a string
([D3 ADR 0003](adr/0003-number-to-string.md)).

The order of priority is:
1. The upstream behavior.
2. Performance: the frame figures of `doc/performance.md`. Phase 4 adds that file.
3. The upstream structure (AGENTS.md rule 2).
4. Less code of our own.

A form with no measured gain keeps the upstream structure. A faster form that changes the
upstream structure gets a `DIVERGES` marker and an `adapt` row in `differences.md`. Record each
measured change in `doc/performance.md`.

## 2. Decisions

"Gate" is the first phase whose code depends on the decision. The maintainer accepts each ADR
before the first change that depends on it. The gate 1 ADRs follow this rule: the roadmap asks for
their acceptance in phase 1 (section 5).

Phase 0 is the exception. It writes the two gate 0 ADRs, ADR 0007 and D3 ADR 0001. It applies
them while they are proposed. The maintainer decided their main points on 2026-10-20: the package
name, the license, the pin rule and the fsum rule (D3 ADR 0001 item 1). Section 7 asks when the
maintainer accepts the two ADRs.

[ADR 0001](../../../docs/adr/0001-native-ports-not-wrappers.md),
[ADR 0005](../../../docs/adr/0005-pin-upstream-sources.md) and
[ADR 0006](../../../docs/adr/0006-follow-upstream-between-releases.md) are accepted and common to
all ports. ADR 0007 and ADR 0008 are new cross-port decisions of this port. The other decisions
are for D3 only. Each D3-only decision becomes a file in [`adr/`](adr/) with the next free
number, at its gate or before it. If a later port needs the same decision, the decision moves to
`docs/adr/` as a new ADR. This is the rule of the Chart.js porting flow §2.

The D3 ADRs take rules from three Chart.js ADRs. A Chart.js ADR binds only the Chart.js port.
Thus each D3 ADR states the rules that it takes:
- [Chart.js ADR 0034](../../flutter_chartjs/doc/adr/0034-no-display-only-js-exactness.md): no
  display-only JS exactness. D3 ADR 0003 names the D3 results that are not display-only.
- [Chart.js ADR 0032](../../flutter_chartjs/doc/adr/0032-js-numeric-semantics.md): the JS
  numeric rules and the reference engine. D3 ADR 0003 and D3 ADR 0004 take them.
- [Chart.js ADR 0012](../../flutter_chartjs/doc/adr/0012-dart-file-naming.md): the upstream
  spelling of file names. D3 ADR 0002 adapts it.

| Subsection | Decision | Gate | Status |
|---|---|---|---|
| 2.1 | [ADR 0007: Package names](../../../docs/adr/0007-package-names.md) | 0 | proposed. It supersedes ADR 0003 on acceptance |
| 2.2 | [ADR 0008: Shared JS runtime and port tools](../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) | 1 | proposed |
| 2.3 | [D3 ADR 0001: Upstream sources](adr/0001-upstream-sources.md) | 0 | proposed |
| 2.4 | [D3 ADR 0002: File naming and package layout](adr/0002-file-naming-and-layout.md) | 1 | proposed |
| 2.5 | [D3 ADR 0003: Number to string and number formatting](adr/0003-number-to-string.md) | 1 | proposed |
| 2.6 | [D3 ADR 0004: Spec harness](adr/0004-spec-harness.md) | 1 | proposed |
| 2.7 | [D3 ADR 0005: Path context and drawing](adr/0005-path-context.md) | 1 for the pure interface, 4 for the `dart:ui` builder | proposed |
| 2.8 | [D3 ADR 0006: Generators, accessors and JS values](adr/0006-generators-accessors-and-js-values.md) | 1 | proposed |
| 2.9 | Collections and iteration | 2 | no ADR file yet |
| 2.10 | Locale data | 2 | no ADR file yet |
| 2.11 | Dates and time zones | 3 | no ADR file yet |
| 2.12 | `new Function` in d3-dsv | 3 | no ADR file yet |
| 2.13 | Image snapshots | 5 | no ADR file yet |
| 2.14 | Timers and frames | 6 | no ADR file yet |
| 2.15 | DOM layer, after the design document `doc/dom-layer.md` | 7 | no ADR file yet |
| 2.16 | d3-transition's prototype patch | 7 | no ADR file yet |
| 2.17 | Fetch | 7 | no ADR file yet |

Subsections 2.1 to 2.8 give a summary. The ADR file holds the decision and its evidence.
Subsections 2.9 to 2.17 give the question, the facts and the proposal of the research of
2026-10-20. Their ADR decides.

### 2.1 ADR 0007: Package names (gate 0)

[ADR 0007](../../../docs/adr/0007-package-names.md) (proposed) states the complete naming rule of
the workspace. It supersedes ADR 0003 on acceptance. In short:
- The library package of a port is `flutter_<library>` or `flutter_<library>_port`. The
  maintainer selects the form.
- The maintainer selected `flutter_d3_port` on 2026-10-20. On that day, `flutter_d3` was free on
  pub.dev. Thus the D3 name deviates from the rule of ADR 0003. ADR 0007 makes the form
  `flutter_<library>_port` a part of the rule.
- It also gives the names `flutter_chartjs`, `chartjs_test_utils`, `chartjs_gallery`, the adapter
  rule `flutter_chartjs_<system>`, the gallery `d3_gallery` and the shared packages `js_semantics`
  and `port_tools` of ADR 0008. The Chart.js porting flow §6 asks for the record of
  `chartjs_test_utils`.
- A port-only harness package of D3 has the name `d3_test_utils`.
- Each package and app of the workspace has a scope in `commitlint.yaml`. The ADR also gives the
  rule for later ports.

### 2.2 ADR 0008: Shared JS runtime and port tools (gate 1)

[ADR 0008](../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) (proposed) holds the
decision. It changes no file before D3 phase 1. In short:
- The pure Dart workspace package `js_semantics` holds the JS runtime that two or more ports use.
  It starts with the import closure of the generic runtime files of `flutter_chartjs`: 11 files.
  The closure contains `js_class.dart`, because `js_function.dart:85` and `js_object.dart:10`
  import it.
- **Stage 1 (D3 phase 1)** copies these files and their tests into `js_semantics`.
  `flutter_d3_port` depends on it. The drift check `check:js-runtime-drift` fails when a shared
  file and its Chart.js copy differ. Stage 1 changes no file of `flutter_chartjs`.
- **Stage 2** is the Chart.js migration, one change of the Chart.js port. The Chart.js work
  selects its time. It also writes a new ADR that supersedes Chart.js ADR 0032.
- A port-only file of `js_semantics` starts with
  `// Original code, not ported from any project: <reason>.` A difference there carries
  `// DIVERGES(ecmascript): <row id>, <reason>`, with its row in
  `packages/js_semantics/doc/differences.md`.
- The dev package `port_tools` gives tools 1-3 one implementation for all ports, with a config
  file for each port. Section 4 gives what each tool needs for D3.

### 2.3 D3 ADR 0001: Upstream sources (gate 0)

[D3 ADR 0001](adr/0001-upstream-sources.md) (proposed) holds the decision. In short:
- 34 shallow submodules, flat: `third_party/d3`, the 30 module repositories `third_party/d3-*`,
  `third_party/internmap`, `third_party/delaunator` and `third_party/robust-predicates`.
- The pin rule: the newest release tag inside the semver ranges of the d3 v7.9.0 `package.json`.
  Thus d3-format is at v3.1.2, delaunator at v5.1.0 and robust-predicates at v3.0.3. The d3
  v7.9.0 `yarn.lock` locks older versions of these three.
- The `d3` bundle repository is the upstream repository of ADR 0005. `d3Version = '7.9.0'` is in
  the port-only `lib/src/upstream.dart`. The 33 other repositories are the "other projects" of the
  port, as in Chart.js ADR 0035. Each one is an entry of `tool/port_sources.yaml`.
- The status unit is one upstream source file. The newest tag is per repository. A bump moves one
  repository. The ledger has one section for each repository.
- The license of the code of the port is ISC, as upstream. The ADR lists each license component
  with one exact holder string. It also gives the embedded notices, the source of the dartdoc text
  and the test data of later phases.
- `upstream:check` and `test/upstream_test.dart` compare the gitlinks with the pins. Each CI job
  fetches only the submodules that it needs, by path.

### 2.4 D3 ADR 0002: File naming and package layout (gate 1)

[D3 ADR 0002](adr/0002-file-naming-and-layout.md) (proposed) adapts Chart.js ADR 0012. In short:

| Upstream | Dart (in `packages/flutter_d3_port/`) |
|---|---|
| `<repo>/src/<path>.js` | `lib/src/<repo>/<path>.dart` |
| `delaunator/index.js` | `lib/src/delaunator/index.dart` |
| `d3/src/index.js` | `lib/src/d3/index.dart` (the bundle index) |
| `<repo>/test/<path>-test.js` | `test/specs/<repo>/<path>_test.dart` |
| the four test entries without `-test.js`, for example `delaunator/test/test.js` | `test/specs/<repo>/<name>_test.dart`, for example `test/specs/delaunator/test_test.dart` |
| `<repo>/test/<helper>.js` | `test/specs/<repo>/<helper>.dart` |
| port-only tests | `test/port/<repo>/<path>_test.dart` |
| port-only library code | `lib/src/<topic>/`, where `<topic>` is not a repository name |
| port-only test support | `test/support/` |

- Directory names keep the repository name with its hyphen. File names keep the upstream
  spelling.
- At the pins, 218 Dart files carry `// ignore_for_file: file_names` after their header lines:
  107 source files, 106 spec files, 4 helpers and `test-time-zones_test.dart` (D3 ADR 0002
  section 2, [parity.md](parity.md#notes)).
- The ADR also covers the renamed exports, the aliases and the bundle index check (section 4).
- Public libraries: `package:flutter_d3_port/d3.dart` is the pure barrel of `d3/src/index.js`
  from phase 1. `package:flutter_d3_port/flutter_d3_port.dart` adds the Flutter layer. Users write
  `import 'package:flutter_d3_port/d3.dart' as d3;`.
- The `%` in `d3-format/test/format-type-%-test.js` is an open probe of phase 1: `flutter test`,
  Windows and dart2wasm.

### 2.5 D3 ADR 0003: Number to string and number formatting (gate 1)

[D3 ADR 0003](adr/0003-number-to-string.md) (proposed) holds the decision. In short:
- In some modules, a string is the result: d3-format, the path strings of d3-path and d3-geo,
  d3-color and d3-time-format. In these modules, JS-exact digits are behavior.
- Thus the principle of Chart.js ADR 0034 does not exempt these strings. The ADR takes the rules
  of Chart.js ADR 0032.
- Evidence: the 24 d3-format test files have 168 cases with 711 `assert.strictEqual` calls, most
  of them on strings. 6 more calls are in line comments. The pilot of phase 1 compares the number strings with reference strings of
  an x64 Node.js.

### 2.6 D3 ADR 0004: Spec harness (gate 1)

[D3 ADR 0004](adr/0004-spec-harness.md) (proposed) holds the decision. In short:
- The specs use `package:test` with the upstream test names. A port-only stand-in of the Node
  `assert` module and the ported `test/asserts.js` helpers keep the upstream assertions.
- Reference values come only from an x64 build of Node.js v24.12.0 (Chart.js ADR 0032).
- The skip reasons are `blocked:`, `n/a:` and `diverges:`.
- The harness restores the default locales of d3-format and d3-time-format after each test. Both
  modules set a mutable default locale when they load (d3-format `src/defaultLocale.js:7`,
  d3-time-format `src/defaultLocale.js:9`).
- The ADR gives the rules for the jsdom cases and the image snapshots.
- It says how a tool reads the test names: mocha `it`, vitest `test` (d3-format) and `node:test`
  (delaunator, robust-predicates). A Node `vm` cannot run some test files as they are (section 4,
  tool 4).

### 2.7 D3 ADR 0005: Path context and drawing (gate 1 for the interface, gate 4 for the builder)

[D3 ADR 0005](adr/0005-path-context.md) (proposed) holds the decision. In short:
- D3 calls seven path methods on a context: `lineTo` (82 sites), `moveTo` (53), `closePath`
  (33), `arc` (17), `bezierCurveTo` (9), `quadraticCurveTo` (3) and `rect` (2). The d3-path `Path`
  also has `arcTo` (`d3-path src/path.js:51`).
- A pure port-only interface declares these methods. The d3-path `Path` implements it (phase 1).
- A port-only `dart:ui` builder implements it in phase 4. Then a Flutter painter can draw a D3
  generator.
- The Chart.js canvas layer stays in `flutter_chartjs` (section 5.1).

### 2.8 D3 ADR 0006: Generators, accessors and JS values (gate 1)

[D3 ADR 0006](adr/0006-generators-accessors-and-js-values.md) (proposed) holds the decision. It
covers:
- callable classes for the D3 generators
- getter and setter accessors, and cascades in place of the method chains
- the arity of user functions
- the `Function.length` overloads of d3-array: the parameter count chooses an accessor or a
  comparator
- the `this` binding of callbacks
- `undefined` and `null`

### 2.9 Collections and iteration (gate 2)

**Question.** How do JS iterables, generators, `Map` and `Set`, `InternMap` and typed arrays
become Dart?

**Facts.**
- A JS `Map` compares keys with SameValueZero. Thus NaN equals NaN. A Dart `Map` compares keys
  with `==`.
- `InternMap` and `InternSet` key an object through `valueOf()` (`internmap src/index.js:59-61`).
  Thus two dates with one time value are one key.
- delaunator, d3-delaunay and d3-contour use typed arrays. d3-array, d3-delaunay and d3-hierarchy
  use generators.
- Some arrays carry properties, for example the bins of d3-array (`x0`, `x1`) and the series of
  d3-shape `stack` (`key`, `index`).

**Proposal.**
- Dart collections, with JS adapters where the semantics differ: a `LinkedHashMap` with
  SameValueZero equality, and line-by-line ports of `InternMap` and `InternSet`.
- `sync*` functions for generators. A JS generator object iterates one time. A Dart `sync*`
  iterable iterates again. A site that iterates a result two times calls `.toList()`.
- Typed lists, with explicit `ToInt32` and `ToUint32` conversions on a store.
- `ListBase` subclasses for arrays with properties.
- Measure the maps with custom equality against the default maps (1.1).

### 2.10 Locale data (gate 2)

**Question.** Where do the locale definitions of d3-format and d3-time-format go?

**Facts.**
- d3-format has 59 locale files in `locale/` (379 lines). d3-time-format has 34 (340 lines). They
  are JSON data outside `src/`.
- The locale tests read all of them with `readdirSync` (d3-format `test/locale-test.js:83-85`,
  d3-time-format `test/locale-test.js:7-9`).
- The d3-format tests also read single locale files (`test/locale-test.js:7`). d3-format is a
  pilot module of phase 1.

**Options.**
1. Generated Dart constants under `lib/src/<repo>/locale/`. A tool writes them from the pin.
2. Test data only. The VM tests read the JSON files of the pin. An app gives its own locale
   definition, as in JavaScript.

### 2.11 Dates and time zones (gate 3)

**Question.** How do d3-time, d3-time-format, d3-scale and d3-dsv get the behavior of the JS
`Date`?

**Facts.**
- d3-time changes `Date` objects in place (`src/interval.js`). It reads `getTimezoneOffset()`
  (`src/day.js:7`). It tests for an Invalid Date with `date >= date` (`src/interval.js:39`).
- d3-time-format makes dates in the years 0-99 with `setFullYear` (`src/locale.js:14-31`).
- d3-dsv `autoType` parses ISO strings with `new Date`. It examines the engine with `fixtz` when
  it loads (`src/autoType.js:9-20`).
- Four repositories run their tests with `TZ=America/Los_Angeles`: d3-time (`package.json:46`),
  d3-time-format (`:53`), d3-scale (`:50`) and d3-dsv (`:50`).
- `d3-time/test/test-time-zones` has 32 active checks in other zones. The upstream test script
  does not run it.
- A Dart `DateTime` is immutable. It has no Invalid Date. It maps the years 0-99 to other dates
  than JavaScript does.

**Proposal.** A port-only mutable `JsDate` with a `double` time value and the ECMAScript date
algorithms, over a local-zone source. The default source reads the host. The test harness
installs `America/Los_Angeles` from a time-zone database. Thus the time tests run on every OS and
on the web legs. The ADR names the zone source and its dependency (section 6).

### 2.12 `new Function` in d3-dsv (gate 3)

**Question.** How does the port translate the row converter of d3-dsv?

**Facts.** `objectConverter` builds the converter with `new Function` (`d3-dsv src/dsv.js:7-11`).
The converter returns an object literal with one key for each column, in column order. Each value
is `d[i] || ""`. The port has no JS engine (ADR 0001).

**Proposal.** A Dart closure that builds a `Map` in column order. The ADR examines the inputs
where an object literal and a `Map` differ. An example is a column with the name `__proto__`: the
object literal does not get an own property for it. A difference that stays gets a `differences.md`
row.

### 2.13 Image snapshots (gate 5)

**Question.** What do the image snapshot cases of D3 become?

**Facts.**
- d3-geo has 16 PNG snapshots. node-canvas draws them. pixelmatch compares them
  (`d3-geo test/snapshot-test.js`). They need the npm package world-atlas
  (`test/snapshots.js:28`).
- d3-axis has 2 HTML snapshots. d3-contour has 2 SVG snapshots. jsdom makes them.
- The Chart.js port compares no images
  ([Chart.js ADR 0034](../../flutter_chartjs/doc/adr/0034-no-display-only-js-exactness.md)).

**Proposal.** The image snapshot cases skip with an `n/a` reason. A port-only smoke test draws
the same projections through the `dart:ui` builder. Path-string goldens from a pinned world-atlas
can come later, with a reference generator. They need a data pin and its notice (D3 ADR 0001
item 14). Section 5.1 keeps them as a deferred plan.

### 2.14 Timers and frames (gate 6)

**Question.** How does d3-timer get its clock and its frames?

**Facts.**
- `d3-timer src/timer.js:10-11` reads `performance.now()` (else `Date`). It uses
  `window.requestAnimationFrame` (else `setTimeout(f, 17)`).
- `sleep` uses `setTimeout`, `setInterval` and frames (`src/timer.js:99-110`).
- The upstream tests run in Node, in real time, with tolerances.
- d3-force and d3-transition import d3-timer.
- [Chart.js ADR 0016](../../flutter_chartjs/doc/adr/0016-frame-scheduling.md) (proposed) puts the
  frames of the Chart.js port on `SchedulerBinding.scheduleFrameCallback`.

**Proposal.** d3-timer stays a pure layer. `performance.now()` reads `package:clock`. A port-only
frame hook has the upstream fallback as its default. The Flutter layer installs a frame callback.
The tests run with a fake clock, as the exit criterion of phase 6 asks.

### 2.15 DOM layer (gate 7)

**Question.** What do d3-selection, d3-transition, d3-axis, d3-zoom, d3-drag and d3-brush become?

**Facts.**
- These modules need a DOM: elements with namespaces, attributes, styles, events and SVG
  geometry. For example, `d3-selection src/pointer.js:8-11` calls `createSVGPoint` and
  `getScreenCTM`.
- `d3-interpolate src/transform/parse.js` uses `DOMMatrix` (`:7`) and the SVG DOM (`:13-15`).
- 78 of the 434 upstream test files use jsdom.
- Phase 7 has 113 source files, 3773 lines and 444 cases ([parity.md](parity.md#by-phase)).

**Steps.**
1. Write the design document `doc/dom-layer.md`. It compares three options with figures and a
   d3-axis prototype: a retained DOM stand-in that a RenderObject draws, a Flutter widget layer,
   and `n/a`.
2. Read the DOM stand-in of the Chart.js harness, `packages/chartjs_test_utils/lib/src/dom.dart`,
   as prior art for the document.
3. Write the DOM ADR from the document.
4. Port the modules of the chosen option.

Until then, the DOM modules stay `not started`. Their jsdom cases skip as `'blocked: <module>'`.

### 2.16 d3-transition's prototype patch (gate 7)

**Question.** How does d3-transition add its methods to the selections of d3-selection?

**Facts.** When it loads, d3-transition writes `selection.prototype.interrupt` and
`selection.prototype.transition` (`d3-transition src/selection/index.js:5-6`). Its index imports
that file first (`src/index.js:1`). A Dart program cannot add members to a class at run time.

**Options.**
1. Extension methods on the selection class.
2. Members of the selection class, with an implementation that d3-transition registers.
3. One library for both modules.

### 2.17 Fetch (gate 7)

**Question.** What does d3-fetch become?

**Facts.** d3-fetch calls `fetch` (for example `src/text.js:7`), `new Image` (`src/image.js:3`)
and `DOMParser` (`src/xml.js:5`). AGENTS.md rule 5 forbids `dart:js_interop` in library code.
Library code must compile for every Flutter platform.

**Options.**
1. A dependency on `package:http`.
2. Conditional imports for the web and for `dart:io`.
3. `n/a` for the module.

## 3. Test harness

**Package.** Phase 0 adds no harness package. D3 has no upstream test-utils package. Its helpers
are per repository, for example `test/asserts.js`. Thus the ported helpers go under
`test/specs/<repo>/`. A harness package becomes useful when the DOM layer needs a shared stand-in
(phase 7). D3 ADR 0004 decides. The name of a D3 harness package is `d3_test_utils` (ADR 0007).

**Where tests run.**

| Suite | VM: `flutter test`, 3 OS | `dart test -p chrome -c dart2js` | `-c dart2wasm` |
|---|---|---|---|
| Pure-layer tests | yes | yes | yes |
| Other tests (`@TestOn('vm')`) | yes | no | no |

- A pure-layer file reaches neither `dart:ui` nor `package:flutter` through its imports. The pure
  layers are all modules except the DOM layer, the `dart:ui` builder and the Flutter layer. Tool 1
  computes them (section 4).
- The melos script `test:web` runs only the two Chart.js packages now. The first pure test of
  `flutter_d3_port` adds the package to `test:web` (phase 1). Without a test to run,
  `dart test -p chrome` exits with code 79. Then the CI job `test-web` fails.

**Time zones.** The time and scale tests of phase 3 install `America/Los_Angeles` on all legs
(2.11). The upstream scripts set `TZ`. No probe examined whether `TZ` sets the zone of Windows
and of Chrome. Thus the harness installs the zone in the test.

**Reference values.** Reference values come only from an x64 build of Node.js v24.12.0 (Chart.js
ADR 0032, D3 ADR 0004). On Apple silicon, the darwin-x64 build runs under Rosetta. The D3 tests
carry their expected values inline. Thus a reference generator is necessary only for port-only
tests, for example the number strings of D3 ADR 0003.

**Default locales.** d3-format and d3-time-format set a default locale when they load. The harness
restores it after each test, as `setUpDefaultsRestore()` of the Chart.js harness does for
`defaults`.

**Data files and skips.**
- The tests that read data files of the pin follow D3 ADR 0004.
- The jsdom cases skip as `'blocked: <module>'` until phase 7 (2.15).
- The image snapshot cases follow 2.13.

## 4. Tooling

The Chart.js port has eight per-module tools in `packages/flutter_chartjs/tool/`
([the Chart.js porting flow](../../flutter_chartjs/doc/porting-flow.md) §4). They know only the
Chart.js port:
- The port-only marker and the backport line are Chart.js patterns
  (`tool/src/headers.dart:15`, `:20`).
- The marker `DIVERGES(chartjs)` is fixed (`tool/src/port_headers.dart:88`).
- The pure roots are a constant list (`tool/src/lib_imports.dart:117`).

[ADR 0008](../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) (proposed) makes one set
of tools serve both ports, in the dev package `port_tools`. In short:
1. Stage 1 (D3 phase 1) copies tools 1-3 and their tests into `packages/port_tools`. Each tool
   reads a config file of each port. The config gives the project and its version constant, the
   port-only marker, the `DIVERGES` tag and the `differences.md` categories. It also gives the
   harness package, the pure roots, the allowlists and the ADR names of the messages.
2. The D3 config is in `packages/flutter_d3_port/tool/`. In stage 1, the Chart.js config is in
   `packages/port_tools`, because stage 1 changes no Chart.js file.
3. A CI step runs both tool sets over the Chart.js packages. It compares their outputs byte for
   byte. Thus it tests the phase 1 exit criterion "with the Chart.js outputs unchanged".
4. The backport line takes `<owner>/<repo>` from the `url` of the `port_sources.yaml` entry.
5. Tools 5, 6 and 8 move to `port_tools` by the same method when the D3 port needs them (D3 phase
   2). Tool 4 is a Node.js tool. Each port keeps its own tool 4.
6. Stage 2 (the Chart.js migration) deletes tools 1-3 from `packages/flutter_chartjs/tool/`. The
   melos scripts then run `port_tools` for each port.

The roadmap gives tools 1-3 for both ports to phase 1, and tools 4-6 to phase 2 (section 5).

| Tool | Chart.js command | D3 phase | What the D3 port needs |
|---|---|---|---|
| 1. Library import guard | `check:lib-imports` | 1 | The allowlists of `lib/`, of the pure layers and of the web tests of `flutter_d3_port`, with `package:js_semantics/`. The pure roots: the modules of phases 1-6 and the pure parts of phase 7. A test file without `@TestOn('vm')` imports only pure layers and `package:test` |
| 2. Header check | `check:headers` | 1 | The 34 entries of `tool/port_sources.yaml` with their targets. The D3 port-only marker. `DIVERGES(d3)`. The backport lines of the four GitHub owners `d3`, `mbostock`, `mapbox` and `mourner`, from the `url` of each entry. The ignore line after the header lines. The gitlinks of the 34 submodules |
| 3. JS-semantics check | `check:js-semantics` | 1 | The `js` projects of the D3 `port_sources.yaml`: all 34 repositories. D3 ADR 0003 and D3 ADR 0006 can add D3 forms |
| 4. Upstream manifest | `upstream:manifest` | 2 | A D3 tool of its own (ADR 0008). It reads the test names of three runners: mocha `it`, vitest `test` and `node:test` `test`, with the names that loops make. Output: `packages/flutter_d3_port/doc/upstream/manifest.json` |
| 5. Spec-case tracking | `test:cases` | 2 | The D3 spec paths `test/specs/<repo>/` and the manifest of tool 4. It moves to `port_tools` (ADR 0008) |
| 6. Parity generator | `parity`, `parity:check` | 2 | One row for each source file, grouped by repository, from `doc/status.yaml`. It replaces the hand-written [parity.md](parity.md). It moves to `port_tools` (ADR 0008) |
| 7. Fixture smoke runner | `test:fixtures` (Chart.js phase 7) | none | D3 has no fixture configs. The decision "Image snapshots" (2.13) can add a smoke test of the d3-geo projections |
| 8. Port-order helper | `port:next` | not in the roadmap | It reads the imports of one repository. D3 imports cross repositories. ADR 0008 moves it to `port_tools` when the D3 port needs it. Section 7 has the open question |

**Tool 4 and the upstream test files.** A Node `vm` cannot run some D3 test files as they are:
- `d3-geo test/snapshot-test.js:10` calls `mkdirSync("./test/snapshots")` at load time. Thus it
  writes into the submodule.
- `d3-geo test/projection/fit-test.js:9` reads `node_modules/world-atlas/world/50m.json` at load
  time.
- `robust-predicates test/test.js:5-6` imports the npm packages robust-orientation and nextafter.

ADR 0005 item 2 lets a dev-time tool run a reference source. No tool builds a source inside
`third_party/`. The port does not run `npm install`. Thus tool 4 stubs these calls or reads the
names statically (D3 ADR 0004).

**D3 checks.**
- **Bundle index check** ([D3 ADR 0002](adr/0002-file-naming-and-layout.md)). It compares the
  names of each module index with the exports of the bundle index, with `package:analyzer`. It
  stands in for `d3/test/d3-test.js`, because Dart cannot list the exports of a library at run
  time.
- **Runtime drift check** `check:js-runtime-drift` (ADR 0008, phase 1). Until stage 2, it fails
  when a shared file and its Chart.js copy differ.
- **Pin checks** of phase 0 (D3 ADR 0001): `upstream:check` (`tool/check_upstream_pin.sh`, CI job
  `upstream-pin`) and `packages/flutter_d3_port/test/upstream_test.dart`.

**`differences.md` schema.** The schema of the Chart.js porting flow §4 applies. Each row is one
difference. One or more `DIVERGES` hunks name it. The columns are ID, Dart file and symbol,
Upstream file@version:lines, Category, Reason, Upstream reference, Pinning test and Re-check on
bump.

The ID starts with the lowercase category: `adapt`, `platform`, `js-semantics`, `harness` or
`not-followed`. D3 has no theme decision. Thus it has no `theme` category. The marker text after
`DIVERGES(d3): ` starts with the ID. [differences.md](differences.md) exists from phase 0, with no
rows.

**Node and ADR 0001.** Tool 4 and the reference generators run Node.js on the machine of the
porter and in the CI job `upstream-manifest`. A dev-time Node tool is not runtime. Nothing in
`lib/` or `test/` loads it ([ADR 0001](../../../docs/adr/0001-native-ports-not-wrappers.md)).

## 5. Phases

| Phase | Scope | Exit criteria |
|---|---|---|
| 0. Scaffold and design | Package, 34 submodules, `port_sources.yaml`, `d3Version`, `upstream_test.dart`, pin checks, `LICENSE`, `REUSE.toml`, docs, prior art, ADR 0007, ADR 0008 and D3 ADRs 0001-0006 (proposed), commit scope, melos and CI entries. No change in `flutter_chartjs` | CI green; `upstream:check` passes for Chart.js and D3 |
| 1. Decisions, tooling, pilot | Gate 1 ADRs accepted; the shared JS runtime (staged, ADR 0008); tools 1-3 for both ports; the Node `assert` stand-in; the pure path context; pilot by hand: d3-array `ticks.js`, `nice.js`, `range.js`, d3-path, d3-format | The pilot cases pass on the VM, dart2js and dart2wasm; number strings match x64 Node.js reference strings; tools 1-3 green for both ports with the Chart.js outputs unchanged |
| 2. Pure data | internmap, the rest of d3-array, d3-color, d3-interpolate without `transform/`, d3-ease, d3-random, d3-scale-chromatic, d3-dispatch, d3-polygon, d3-quadtree, d3-hierarchy; tools 4-6 | All cases of these modules pass or skip with a valid reason on the three legs; `test:cases` reports none missing |
| 3. Time, DSV and scales | the JS `Date` runtime and time zones, d3-time, d3-time-format, d3-dsv, d3-scale | The time and scale cases pass with `America/Los_Angeles` installed on all legs |
| 4. Shapes and drawing on Flutter | d3-shape, d3-chord, the `dart:ui` path builder, `apps/d3_gallery`, `doc/performance.md` | Shape and chord cases pass; the gallery builds for Android, iOS, web (wasm) and macOS; frame figures recorded |
| 5. Geometry | d3-geo, robust-predicates (`orient2d`), delaunator, d3-delaunay, d3-contour | Non-snapshot cases pass; image snapshots skip with a valid reason |
| 6. Motion and simulation | d3-timer, d3-force, the pure parts of d3-zoom and `interpolateZoom` | d3-timer cases pass under a fake clock; d3-force cases pass |
| 7. DOM layer | `doc/dom-layer.md`, the DOM ADR, then d3-selection, d3-transition, d3-axis, d3-zoom, d3-drag, d3-brush, d3-fetch, d3-interpolate `transform/` | The cases of the chosen option pass; the others skip with a valid reason |
| 8. Flutter API and release | Public widgets and painters, semantics, docs, the release model of the shared runtime, pana | `flutter_d3_port` 0.1.0 on pub.dev |

[parity.md](parity.md#by-phase) gives the source files, lines and cases of each phase. Notes on
the phases:
- **Phase 1.** The pilot has 21 source files, 587 lines and 274 cases. These are d3-array
  `ticks.js`, `nice.js` and `range.js` (42 cases), d3-path (64 cases) and d3-format (168 cases).
  The pilot tests the number rules. `tickSpec` calls `Math.log10`, `Math.pow` and `Math.round`
  (`d3-array src/ticks.js:5-27`). d3-format compares strings.
- **Phase 2.** The 24 cases of d3-array `test/bin-test.js` include a case that reads
  `athletes.csv` with `csvParse` of d3-dsv (`:226-227`). Until phase 3, that case skips as
  `'blocked: <module>'`. On the ledger rows of 2026-10-20, a commit pin of d3-quadtree (#43, a
  feature) is due before phase 2. It is the first commit pin of the port
  ([upstream-ledger.md](upstream-ledger.md)).
- **Phase 2 and phase 6.** `interpolateZoom` is `src/zoom.js` of d3-interpolate. The roadmap
  names it in phase 6. Thus [parity.md](parity.md) gives `zoom.js` (71 lines, 5 cases) to phase 6.
  Section 7 has the open question.
- **Phase 3.** The Dates and time zones decision (2.11) comes first.
- **Phase 5.** robust-predicates `src/*.js` is macro source. The port expands the macros by hand.
  `compile.js` gives their definitions (D3 ADR 0001 item 16). D3 calls only `orient2d`
  (delaunator v5.1.0 `index.js:5`). Thus D3 ADR 0001 item 17 gives `orient3d.js`, `incircle.js`
  and `insphere.js` the status `n/a`.
- **Phase 5 and the ledger.** d3-delaunay `dc894a1` (#145) makes `Delaunay.find` return -1 in
  place of NaN in edge cases. It is a behavior change, not a backport. Thus a commit pin of
  d3-delaunay is due before phase 5 ([upstream-ledger.md](upstream-ledger.md)).
- **Phase 7.** The DOM layer decision (2.15) comes first.

### 5.1 Deferred plans

A deferred plan records work that the port does not do now. The phases do not wait for a deferred
plan. Each deferred plan names its revisit point and its triggers. No D3 plan file exists yet. A
row gets its own plan file at its revisit point, or when a trigger occurs.

| Plan | Revisit point | Triggers |
|---|---|---|
| Stage 2 of ADR 0008: the migration of `flutter_chartjs` onto `js_semantics` and `port_tools`. The Chart.js work selects its time | The first phase boundary of the Chart.js port after stage 1 | A runtime fix that both ports need. A failure of the drift check that blocks a Chart.js change |
| The release model of `js_semantics`: a release with a semver contract, or a copy in each released port. A new ADR decides it (ADR 0008, Consequences) | D3 phase 8, or the first release of `flutter_chartjs` before it | A release plan of either port |
| A shared canvas layer: the Chart.js canvas layer as a package that both ports use | Phase 7 | A D3 caller that needs styles, text or transforms on a context, for example the DOM layer |
| Path-string goldens of d3-geo from a pinned world-atlas (2.13) | After phase 5 | None yet |

The Chart.js port has the deferred plan
[`canvas-cuts-plan.md`](../../flutter_chartjs/doc/canvas-cuts-plan.md). It cites the root
`pubspec.lock`. Section 6 gives the rule for a D3 change that changes that file.

## 6. Changes to other files

**Phase 0.** The scaffold changes these files outside `packages/flutter_d3_port/`:
- the root `pubspec.yaml`: the workspace entry, and the descriptions of the melos scripts
  `upstream` and `upstream:check`
- `commitlint.yaml`: the scope `flutter_d3_port`
- `.gitmodules` and the 34 submodules under `third_party/`
- `tool/check_upstream_pin.sh`: the pin checks of D3 ADR 0001
- `.github/workflows/ci.yaml`: the submodule checkout by path
- `REUSE.toml` and `LICENSES/ISC.txt`
- `docs/adr/0007-package-names.md` and `docs/adr/0008-shared-js-runtime-and-port-tools.md`
- `docs/prior-art/other-chart-libraries.md`: a short addition to its D3 section
- `AGENTS.md`: the D3 text in Commands, Layout, the porting rules, Tests, Licensing and
  Conventions
- the root `README.md`, `docs/README.md` and `CONTRIBUTING.md`, where they list the ports, the
  scopes or the ADRs

Phase 0 changes nothing in `packages/flutter_chartjs/`, `packages/chartjs_test_utils/` or
`apps/chartjs_gallery/`. Phase 0 adds no dependency. Thus the root `pubspec.lock` does not
change.

**Later phases.**
- Phase 1 (stage 1 of ADR 0008): the packages `js_semantics` and `port_tools`, with their
  workspace entries and their `commitlint.yaml` scopes (ADR 0007). `js_semantics` and
  `flutter_d3_port` in `test:web`, the latter with its first pure test. The drift check in
  `check:port` and in the CI job `port-checks`. The CI step that compares the tool outputs. The
  AGENTS.md text for `js_semantics`, `port_tools` and the D3 tool commands.
- Phase 2: `upstream:manifest`, `test:cases` and `parity` for D3, and the D3 step of the CI job
  `upstream-manifest`.
- Phase 3: the dependency of the zone source, if the decision 2.11 names one.
- Phase 4: `apps/d3_gallery`, with its workspace entry, its commit scope `d3_gallery`, its melos
  `gallery*` scripts and its CI gallery jobs.
- Phase 7: `doc/dom-layer.md` and the DOM ADR.

**The deferred-plan rule.** A change that adds a dependency changes the root `pubspec.lock`.
`canvas-cuts-plan.md` of the Chart.js port cites that file. Thus that change also updates the plan
in the same commit (AGENTS.md). The Chart.js session owns the plan. Coordinate the change with it.

**ADRs.** An accepted ADR does not change. A changed decision gets a new ADR that states the
complete decision and supersedes the old ADR. Stage 2 of ADR 0008 changes the runtime location of
Chart.js ADR 0032 §1 and the tool 1 allowlist of the Chart.js porting flow §4. Thus stage 2 writes
a new ADR that supersedes Chart.js ADR 0032 (ADR 0008 item 7).

## 7. Risks and open questions

**Risks**

The numbers of the risks do not change, because other documents can cite them. A risk that no
longer applies stays in the list as closed.
1. **Shared work with the Chart.js session.** Stage 1 of ADR 0008 changes no Chart.js file. Stage
   2 changes the runtime imports and the tools of `flutter_chartjs`. Until stage 2, a fix of a
   copied runtime file needs the agreement of the Chart.js work (ADR 0008 item 6).
2. **Accepted Chart.js ADRs.** Stage 2 needs a new ADR that supersedes Chart.js ADR 0032
   (section 6).
3. **Many small upstreams.** The port has 34 repositories and 34 ledger sections. Each phase start
   applies the bump-first and commit-pin rules of ADR 0006 to each repository of the phase.
4. **Local time.** The time tests depend on `America/Los_Angeles`. A probe of the research found
   that the VM and dart2wasm give no local mean time for dates before the first zone rule. JS and
   dart2js give it. A zone source from a time-zone database avoids the host (2.11).
5. **Iterative growth of last-bit errors in d3-force.** d3-force starts the node positions with
   `Math.cos` and `Math.sin` (`d3-force src/simulation.js:69-71`). Its tests compare within 1e-6
   (`test/asserts.js:3`). If the 16 d3-force cases fail on a leg, a D3-only decision can use fdlibm
   `sin` and `cos` for d3-force.
6. **`file_names` lint.** 218 files carry the ignore line (2.4). A future lint on directory names
   can fail on the hyphenated directories (Chart.js risk 5).
7. **Speed of JS-like collections and accessors.** SameValueZero maps and adapted accessors cost
   time. Measure them in phase 2 (1.1).
8. **Reference engine.** On 2026-10-20, the `PATH` of the machine of the maintainer had no
   darwin-x64 build of Node.js v24.12.0 (`file $(which -a node)`). It had an arm64 v24.12.0 and a
   universal v24.19.0. Get the darwin-x64 v24.12.0 build before the first D3 reference generator.
9. **Test file names.** No probe ran `flutter test` on Windows or dart2wasm with a test file name
   that has a hyphen or a `%`. Phase 1 runs this probe (2.4).
10. **Upstream test files that a Node `vm` cannot run as they are** (section 4, tool 4).
11. **CI checkout cost.** 34 more submodules make each full checkout larger. Each CI job fetches
    only the submodules that it needs, by path (D3 ADR 0001).
12. **`pubspec.lock` and the deferred plan** of the Chart.js port (section 6).
13. **Prior art.** d4 is prior art only, neither a source nor a dependency. AGENTS.md rule 1
    forbids a port from another Dart library ([prior art](prior-art/README.md)).
14. **Thin upstream coverage.** Some modules have no test file of their own name. Examples are
    `tree.js`, `cluster.js` and `partition.js` of d3-hierarchy. Others are `link.js`,
    `manyBody.js` and `radial.js` of d3-force. d3-brush, d3-drag, d3-fetch and d3-scale-chromatic have one case each, the
    export list. AGENTS.md rule 3 asks for port-only tests.
15. **Pin churn.** d3-format released v3.1.2 on 2026-01-14. delaunator and robust-predicates
    released v5.1.0 and v3.0.3 on 2026-03-22. The `d3` bundle released v7.9.0 on 2024-03-12.

**Open questions**
- `interpolateZoom`: phase 2 ports "d3-interpolate without `transform/`". Phase 6 names
  `interpolateZoom`. This document gives `src/zoom.js` to phase 6. Is that the intent of the
  roadmap?
- Does D3 need tool 8 (the port-order helper) across repositories, and in which phase? ADR 0008
  moves it to `port_tools` when the D3 port needs it. The roadmap does not list it.
- The d3-format pilot of phase 1 has cases that read `locale/*.json` (2.10). The Locale data
  decision has gate 2. Do these cases pass on the VM with the files of the pin in phase 1, or skip
  until phase 2?
- The gate 0 ADRs (ADR 0007, D3 ADR 0001) are proposed. Phase 0 applies them (section 2). Does
  the maintainer accept them before the phase 0 commit?
- Does the D3 port need its own `upstream-tracking.md`, or do ADR 0006 and the ledger suffice?
- The release model of `js_semantics`: a release with a semver contract, or a copy in each
  released port (5.1)? A new ADR decides it.
- Is the DOM layer in the scope of 0.1.0 (2.15)?

## Appendix: evidence

The numbers of this document come from the research of 2026-10-20. It read shallow clones of the
34 repositories at their tags and ran no upstream code. [parity.md](parity.md#count-script) has
the count script. The research reports, the probes and the other scripts are outside the
repository.
