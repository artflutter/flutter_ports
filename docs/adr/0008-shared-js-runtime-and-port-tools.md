# ADR 0008: Shared JS runtime and port tools

- Status: proposed
- Date: 2026-10-20
- Gate: D3 phase 1 (item 9). Before the gate, this ADR changes no file.
- Related: [ADR 0001](0001-native-ports-not-wrappers.md) (no JavaScript at runtime),
  [ADR 0006](0006-follow-upstream-between-releases.md) (the backport line),
  [ADR 0007](0007-package-names.md) (the names `js_semantics` and `port_tools`),
  [Chart.js ADR 0010](../../packages/flutter_chartjs/doc/adr/0010-js-numeric-semantics.md) (the JS
  runtime of the Chart.js port),
  [Chart.js ADR 0011](../../packages/flutter_chartjs/doc/adr/0011-third-party-sources.md) (the
  fdlibm copy), [D3 ADR 0003](../../packages/flutter_d3_port/doc/adr/0003-number-to-string.md)
  (number strings in D3),
  [D3 ADR 0006](../../packages/flutter_d3_port/doc/adr/0006-generators-accessors-and-js-values.md)
  (JS values in D3)

## Context

**The runtime of the Chart.js port.** Chart.js ADR 0010 §1 (accepted 2026-10-19) puts the JS
runtime in "an unexported library in `packages/flutter_chartjs/lib/src/js/`". Ported files call
it "where upstream calls a builtin or relies on an implicit JS conversion". At commit `75178b5`
(2026-10-20), the folder has 14 files with 2,313 lines (`wc -l lib/src/js/*.dart`). 169 Dart
files import it (`git grep -l 'package:flutter_chartjs/src/js/' -- '*.dart'`):
- 149 files of `flutter_chartjs`: 56 in `lib/` (7 of them in `lib/src/js/`), 89 in `test/` and 4
  in `tool/bench/`
- 6 files of `chartjs_test_utils`
- 14 files of `apps/chartjs_gallery`

**The D3 port needs the same runtime.** The D3 pilot of phase 1 calls `Math.log10`
(`d3-array@v3.2.4 src/ticks.js:7`), `Math.round` (`d3-path@v3.1.0 src/path.js:21`) and
`Array.prototype.sort` with a comparator (`d3-array@v3.2.4 src/sort.js:12`). The runtime gives
these builtins as `jsLog10`, `jsRound` and `jsSort`. D3 also needs new builtins, for example the
number strings of D3 ADR 0003. D3 cannot import the runtime from `flutter_chartjs`. The
`implementation_imports` lint of `very_good_analysis` 10.3.0 (`analysis_options.10.3.0.yaml:90`)
flags an import of the `src/` of another package.

**The import closure.** The 14 files import each other as this table shows (at `75178b5`):

| File | Lines | Runtime imports | Other imports | Line 1 |
|---|---:|---|---|---|
| `js_undefined.dart` | 37 | none | none | port-only marker |
| `js_map.dart` | 56 | none | none | port-only marker |
| `js_number.dart` | 176 | `js_undefined` | none | port-only marker |
| `js_array.dart` | 184 | none | `package:collection` (`show mergeSort`) | port-only marker |
| `js_class.dart` | 243 | `js_array`, `js_undefined` | none | port-only marker |
| `js_function.dart` | 333 | `js_class` (`:85`), `js_undefined` | none | port-only marker |
| `js_object.dart` | 131 | `js_array`, `js_class` (`:10`), `js_function`, `js_number`, `js_undefined` | none | port-only marker |
| `js_math.dart` | 135 | `fdlibm_atan`, `fdlibm_log` | `dart:math` | port-only marker |
| `fdlibm_log.dart` | 260 | none | `dart:typed_data` | `// Ported from fdlibm 5.3 e_log.c (SunPro, Sun Microsystems, Inc.).` |
| `fdlibm_atan.dart` | 299 | none | `dart:typed_data` | `// Ported from fdlibm 5.3 s_atan.c (SunPro, Sun Microsystems, Inc.).` |
| `js_date.dart` | 27 | none | `package:clock` | port-only marker |
| `js_intl.dart` | 225 | `js_number`, `js_undefined` | `dart:math`, `package:intl` | port-only marker |
| `js_promise.dart` | 121 | none | `dart:async` | port-only marker |
| `js_webidl.dart` | 86 | `js_number`, `js_undefined` | none | port-only marker |

- An earlier design split the runtime into generic files and Chart.js files. It put `js_class`
  with the Chart.js files. That split does not hold. `jsCall` (`js_function.dart:85`) and `jsGet`
  (`js_object.dart:10`) import `js_class.dart`. `jsIsFunction` and `jsGet` test for a `JsClass`.
- The closure of the generic files (`js_undefined`, `js_map`, `js_number`, `js_array`,
  `js_object`, `js_function`, `js_math`, `js_date`) has 11 files with 1,881 lines. It contains
  `js_class` and the two fdlibm ports. Its only packages are `collection` and `clock`.
- The other 3 files (432 lines) serve Chart.js only. `js_intl` gives `Intl.NumberFormat` on
  package:intl (Chart.js ADR 0008). `js_promise` gives the promise jobs of Chart.js ADR 0019.
  `js_webidl` gives the Canvas 2D setter conversions of Chart.js ADR 0017.
- `JsProxyObject` (`js_array.dart:52`) models a JS `Proxy` as a Map. The Chart.js resolvers of
  `helpers.config` implement it. `jsObjectKeys` and `jsGet` test for it.

**Headers and markers.** 12 of the 14 files start with the Chart.js port-only marker
`// Original code, not ported from Chart.js: <reason>.`. The two fdlibm ports start with two
`// Ported from fdlibm 5.3` lines each. The closure carries five `DIVERGES(chartjs)` markers for
four rows of `packages/flutter_chartjs/doc/differences.md`:

| Marker | Row | Other Dart files of the row |
|---|---|---|
| `js_class.dart:176` | `js-semantics-class-source` (`differences.md:67`) | none |
| `js_number.dart:87` | `js-semantics-function-source` (`differences.md:68`) | none |
| `js_object.dart:35` | `js-semantics-resolver-objects` (`differences.md:40`) | `helpers.config.dart`, `core.datasetController.dart`, specs |
| `js_object.dart:93`, `:105` | `js-semantics-object-freeze` (`differences.md:69`) | none |

A sixth marker, `js_promise.dart:60`, is outside the closure
(`platform-animation-promise-checkpoint`).

**Tests.** 10 test files in `packages/flutter_chartjs/test/port/js/` test the closure. They have
2,325 lines. Three generated files with 18,971 lines hold their reference data:
`log10_reference.dart`, `atan2_reference.dart` and `number_to_string_reference.dart`. The x64
generators of Chart.js ADR 0010 §2 write them. Two tests import more than the runtime.
`js_array_test.dart:2-3` imports `createResolver` of `helpers.config`. `js_date_test.dart` uses
`flutter_test` with `@TestOn('vm')`.

**The tools.** The port checks are in `packages/flutter_chartjs/tool/`, with 8,609 lines in
`tool/*.dart` and `tool/src/*.dart`. Tools 1-3 (`check:lib-imports`, `check:headers`,
`check:js-semantics`) and their support code are 11 files with 3,423 lines. Their tests in
`test/tool/` are 7 files with 2,636 lines. The tools hard-code the Chart.js port:
- `tool/src/headers.dart:14-16`: the port-only marker with `Chart\.js`. `:19-21`: the backport
  line with `chartjs/Chart\.js@`. `:30`: the project name `Chart.js`.
- `tool/src/port_headers.dart:40-47`: the `differences.md` categories, with `theme`. `:54` and
  `:61-71`: the harness `chartjs_test_utils`. The check adds it to any first package. `:88`: the
  marker `DIVERGES(chartjs)`. `:89-92` and `:601-609`: the constant `chartJsVersion` and the
  `Chart.js` entry of `port_sources.yaml`.
- `tool/src/lib_imports.dart:117-137`: the pure roots of the Chart.js port. `:71-81`: the forbidden
  imports, with Chart.js ADR 0001 as the rule. `:148-151`: `package:chartjs_test_utils/pure.dart`
  in the web-test allowlist. `:154`: the theme directory.
- The messages of `tool/src/js_semantics.dart` cite Chart.js ADR 0010 (for example `:98`, `:181`
  and `:267`).
- Tool 1 follows only the imports of the examined package (`lib_imports.dart:424-435`). An import
  of another workspace package must be in an allowlist.

**The Chart.js work.** Another session works on `flutter_chartjs` now. Commit `0baaec2`
(2026-10-20) changed `lib/src/js/`. A move of the runtime edits 169 files of that work. It also
changes Chart.js ADR 0010 §1, an accepted ADR. The deferred plan
`packages/flutter_chartjs/doc/canvas-cuts-plan.md` cites 8 of the 169 files.

## Decision

1. **End state.** One pure Dart workspace package, `js_semantics`
   ([ADR 0007](0007-package-names.md)), holds the JS runtime that two or more ports use. Each port
   depends on it. No port depends on another port. Runtime code that only one port uses stays in
   that port.
2. **Package form.**
   - `packages/js_semantics` has no Flutter dependency. Its dependencies are `collection` and
     `clock`, with the constraints of `flutter_chartjs`. Its dev dependency is `test`. Thus the
     package is a pure layer by construction. `dart test` runs its tests on the VM, with dart2js
     and with dart2wasm.
   - Each runtime file is a public library in `lib/`, for example
     `package:js_semantics/js_math.dart`. Thus a port moves an import from
     `package:flutter_chartjs/src/js/` to `package:js_semantics/` with a prefix replacement.
   - The package stays `publish_to: none`. The release model is open (see Consequences).
   - The package `LICENSE` keeps the notices that the copied files have now:
     - the MIT text with `2014-2024 Chart.js Contributors` and `2026 Vasiliy Ditsyak` (the
       `packages/flutter_chartjs/**` table of `REUSE.toml`)
     - the SunPro component of the two fdlibm ports

     `REUSE.toml` gets a table for the package. The fdlibm table gets the two new paths.
3. **Contents.** The package starts with the closure of the generic files: the 11 files with
   1,881 lines.
   - `js_class.dart` is a part of the closure, because `js_function.dart` and `js_object.dart`
     import it.
   - `JsProxyObject` stays in `js_array.dart`. It models a JS `Proxy`, not a Chart.js type.
   - `js_intl`, `js_promise` and `js_webidl` stay in `flutter_chartjs`. If a D3 caller needs one
     of them, that file moves by the method of item 5.
4. **Headers, markers and rows.**
   - The port-only marker of the shared package is
     `// Original code, not ported from any project: <reason>.`
   - The fdlibm ports keep their `// Ported from fdlibm 5.3 <file> (SunPro, Sun Microsystems,
     Inc.).` lines. The shared package has its own `tool/port_sources.yaml` with one fdlibm
     entry. The targets of that entry are the two shared files. The copy `third_party/fdlibm`
     does not move.
   - A difference in the shared package carries `// DIVERGES(ecmascript): <row id>, <reason>`. Its
     row is in `packages/js_semantics/doc/differences.md`, in the table form of the Chart.js
     `differences.md`. The upstream column of the row names the ECMAScript section.
   - The shared rows keep the four row ids of the five markers. Thus stage 2 moves the Chart.js
     rows with no new ids.
   - A row of a port that depends on a runtime difference links the shared row.
5. **Stage 1 (D3 phase 1).** Do these steps in one change:
   1. Copy the 11 files from `packages/flutter_chartjs/lib/src/js/` at one commit. Record that
      commit in `packages/js_semantics/README.md`.
   2. Copy the 10 tests of these files and the generators `log10_reference.mjs`,
      `atan2_reference.mjs` and `number_to_string_reference.mjs`. Run the copied generators to
      write the copies of the three reference files (Chart.js ADR 0010 §2).
   3. In the copy of `js_array_test.dart`, replace `createResolver` with a port-only
      `JsProxyObject`. Write the copy of `js_date_test.dart` with `package:test` and `withClock`.
   4. Give the copies the headers and markers of item 4. The copies can rewrite their doc
      comments without Chart.js references.
   5. Make `packages/flutter_d3_port` depend on `js_semantics`.
   6. Add the drift check `check:js-runtime-drift` to `check:port` and to the CI job
      `port-checks`. It fails when a shared file and its Chart.js copy differ. It ignores the
      header lines, the `///` doc comments, the `DIVERGES` lines and the prefix of the runtime
      imports. It also compares the three reference files below their header lines.
   7. Change no file in `packages/flutter_chartjs/`, `packages/chartjs_test_utils/` or
      `apps/chartjs_gallery/`.
6. **Rules during stage 1.**
   - New runtime code for D3 goes into new files of `js_semantics`.
   - A change to a file that has a Chart.js copy changes both copies in one commit. Before that
     commit, the maintainer or the Chart.js work agrees to the edit of
     `packages/flutter_chartjs/lib/src/js/`.
   - This ADR decides where the runtime is. It does not change what a runtime function does. The
     rules of Chart.js ADR 0010 apply to the copies. D3 ADR 0003 states how D3 applies these
     rules.
7. **Stage 2 (the Chart.js migration).** Stage 2 is one change of the Chart.js port. The Chart.js
   work selects its time. Its revisit point is the first Chart.js phase boundary after stage 1.

   Two triggers start it earlier. One trigger is a runtime fix that both ports need. The other
   trigger is a failure of the drift check that blocks a Chart.js change.

   The change does these steps:
   1. Replace the runtime imports of the closure with `package:js_semantics/` imports. At
      `75178b5`, 169 files import the runtime. `canvas-cuts-plan.md` cites 8 of them. Thus the
      change also updates that deferred plan.
   2. Delete the 11 copies, their 10 tests, the three generators and the three reference files
      from `flutter_chartjs`.
   3. Move the rows `js-semantics-class-source`, `js-semantics-function-source` and
      `js-semantics-object-freeze` to the shared `differences.md`. All their Dart files are
      runtime files.
   4. Keep the row `js-semantics-resolver-objects` with its Chart.js files. Link the shared row
      from it.
   5. Remove the fdlibm targets of `flutter_chartjs` from its `tool/port_sources.yaml`. Remove
      the two old paths from the fdlibm table of `REUSE.toml`. Remove the fdlibm component from
      `packages/flutter_chartjs/LICENSE`.
   6. Write a new ADR that supersedes Chart.js ADR 0010. It restates that ADR with the new
      runtime location of §1.
   7. Update the other citations. These are AGENTS.md (Layout and the JS runtime rule), the tool
      1 allowlist of `packages/flutter_chartjs/doc/porting-flow.md` §4 and the tool messages that
      name `lib/src/js`.
   8. Remove the drift check.
8. **Port tools.** Tools 1-3 get one implementation for all ports, in the dev package
   `port_tools` ([ADR 0007](0007-package-names.md)). The package stays `publish_to: none`. Its
   stages follow the stages of the runtime.
   - **Stage 1 (D3 phase 1).** Copy the 11 files of tools 1-3 and the 7 files of their tests into
     `packages/port_tools`. Replace each Chart.js constant with a value from a config file of
     each port. The config gives these values:
     1. The project and the version constant: `Chart.js` and `chartJsVersion`, or `d3` and
        `d3Version`, in `lib/src/upstream.dart`.
     2. The project name in the port-only marker: `Chart.js`, `D3` or `any project`.
     3. The `DIVERGES` tag (`chartjs`, `d3` or `ecmascript`), the path of `differences.md` and
        its categories.
     4. The harness package, or none.
     5. The pure roots, their exceptions, and the allowlists of `lib/`, of pure layers and of
        web tests.
     6. The forbidden imports with their rules, and the theme directory, or none.
     7. The ADR names in the messages, for example `Chart.js ADR 0010`.
   - The backport line takes `<owner>/<repo>` from the `url` of the `port_sources.yaml` entry
     that its `// Ported from` line names. The grammar stays that of
     [ADR 0006](0006-follow-upstream-between-releases.md) item 3.
   - The D3 config is in `packages/flutter_d3_port/tool/`. In stage 1, the Chart.js config is in
     `packages/port_tools`, because stage 1 changes no Chart.js file.
   - The copied tool tests run with the Chart.js config. They pass with changes of imports only.
     A CI step runs both tool sets over the Chart.js packages. It compares their output byte for
     byte. This step tests the phase 1 exit criterion "tools 1-3 green for both ports with the
     Chart.js outputs unchanged".
   - Tool 1 follows only the imports of the examined package. Thus each port config adds
     `package:js_semantics/` to the allowlists of `lib/`, of pure layers and of web tests. Tool 1
     also examines `packages/js_semantics` with its own config. All of its `lib/` is a pure root.
     Its allowlist is the pure `dart:` libraries, `collection` with `show mergeSort`, and
     `clock`.
   - **Stage 2.** The Chart.js migration, or its own Chart.js change, deletes tools 1-3 from
     `packages/flutter_chartjs/tool/`. The Chart.js config moves to that folder. The melos
     scripts `check:lib-imports`, `check:headers` and `check:js-semantics` then run `port_tools`
     for each port.
   - Tools 5, 6 and 8 (`test:cases`, `parity`, `port:next`) move to `port_tools` by the same
     method when the D3 port needs them (D3 phase 2). Tool 4 is a Node.js tool. It reads the
     specs in the format of the upstream test runner. Each port keeps its own tool 4.
9. **Gate.** "Gate" is the first D3 phase whose code depends on this ADR (the meaning of
   `packages/flutter_chartjs/doc/porting-flow.md:138`). The gate is D3 phase 1. The first D3 file
   that calls a runtime symbol needs stage 1 of the runtime. The first ported D3 file needs stage
   1 of tools 1-3.

   Before the gate, this ADR changes no file. D3 phase 0 changes no file of `flutter_chartjs`.

## Alternatives considered

- **Copy the runtime into `packages/flutter_d3_port/lib/src/js/`.** Rejected. The two copies
  drift with no check. A fix lands twice, with two test sets. The D3 copy also needs D3 rows for
  the five markers.
- **Depend on `flutter_chartjs`.** Rejected. The `implementation_imports` lint flags
  `package:flutter_chartjs/src/`. Each D3 user gets the Chart.js port and its Flutter layers. The
  two ports then share one release cycle.
- **Move the runtime at once, with no stage 1.** Rejected for now. The move edits 169 files while
  another session works on them. It also supersedes the accepted Chart.js ADR 0010 at once. Stage
  2 gives the same end state, at a time that the Chart.js work selects.
- **Leave `js_class.dart` out of the shared package.** Rejected. Without that file, the shared
  `js_function.dart` and `js_object.dart` differ from their Chart.js copies. The drift check then
  cannot compare them.
- **Copy the tools into `packages/flutter_d3_port/tool/`.** Rejected. Two copies of 3,423 lines
  drift. The full tool set has 8,609 lines.
- **New tools for D3.** Rejected. They repeat the Chart.js work.
- **The tools in the root `tool/`.** Rejected. Tool 3 needs `package:analyzer`. The tool tests
  need `package:test`. The root `pubspec.yaml` is the workspace root. A package gives the tools
  their own dependencies and tests. The melos script `test` runs these tests.

## Consequences

- D3 phase 1 adds two workspace packages and their `commitlint.yaml` scopes
  ([ADR 0007](0007-package-names.md)). It also adds the drift check, the CI comparison of the tool
  outputs, and `js_semantics` in the melos script `test:web`.
- Until stage 2, the generic runtime exists twice. The drift check keeps the two copies equal.
  Each fix of a copied file waits for an agreement with the Chart.js work.
- New D3 builtins go only into `js_semantics`, for example the number strings of D3 ADR 0003. The
  Chart.js port can use them after stage 2.
- Stage 1 needs the x64 build of Node.js v24.12.0 for the copied generators (Chart.js ADR 0010
  §2).
- The new packages use only packages that the root `pubspec.lock` has: `analyzer` 12.1.0
  (`pubspec.lock:12-19`), `clock` 1.1.2 (`:116-123`), `collection` 1.19.1 (`:124-131`) and
  `test` 1.31.0 (`:539-546`). If the lock changes, the change follows the deferred-plan rule,
  because the work package I of `canvas-cuts-plan.md` §5 cites the root `pubspec.lock`.
- A package on pub.dev can depend only on packages on pub.dev. Thus the first release of either
  port needs a release model for `js_semantics`. The two candidates are a release with a semver
  contract and a copy in each released port. A new ADR decides the model. D3 phase 8 has this
  item on its roadmap.
- Stage 2 also changes files outside the runtime: AGENTS.md, `REUSE.toml`, and the
  `porting-flow.md` §4, `differences.md`, `port_sources.yaml` and `canvas-cuts-plan.md` of the
  Chart.js port. It adds a new ADR that supersedes Chart.js ADR 0010.
- The [D3 porting flow](../../packages/flutter_d3_port/doc/porting-flow.md) records stage 2 as a
  deferred plan (§5.1). Its roadmap puts the release model in D3 phase 8.
