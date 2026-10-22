# D3 ADR 0004: Spec harness

- Status: proposed
- Date: 2026-10-20
- Gate: D3 phase 1. The pilot ports the specs of d3-array `ticks.js`, `nice.js` and `range.js`,
  of d3-path and of d3-format. The rules for time zones, image snapshots and the DOM wait for the
  decisions of gates 3, 5 and 7.
- Related: [ADR 0005](../../../../docs/adr/0005-pin-upstream-sources.md) (item 2: dev-time tools
  can evaluate reference sources),
  [ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) (tools 4 and 5),
  [Chart.js ADR 0034](../../../flutter_chartjs_port/doc/adr/0034-no-display-only-js-exactness.md) (no
  image comparison),
  [Chart.js ADR 0032](../../../flutter_chartjs_port/doc/adr/0032-js-numeric-semantics.md) (§2, the
  reference engine),
  [Chart.js ADR 0022](../../../flutter_chartjs_port/doc/adr/0022-chart-test-harness.md) (proposed: the
  chart harness of the Chart.js port), [D3 ADR 0001](0001-upstream-sources.md) (items 14, 15 and
  17), [D3 ADR 0002](0002-file-naming-and-layout.md) (the paths),
  [D3 ADR 0003](0003-number-to-string.md) (the number strings),
  [D3 ADR 0006](0006-generators-accessors-and-js-values.md) (the JS values and errors),
  [porting-flow.md](../porting-flow.md) §1, §3 and §4

## Context

AGENTS.md rule 3 asks for a port of the upstream specs. The D3 specs run under three runners, with
three assert libraries. The counts are at the pins of [D3 ADR 0001](0001-upstream-sources.md). The
comments are removed.

**Runners.**
- mocha runs the tests of 31 repositories: `d3`, internmap and the module repositories other than
  d3-format. 383 of their test files and 15 of their helpers have the line
  `import assert from "assert"`. This is the legacy mode of the Node module `assert`.
- d3-format v3.1.2 runs vitest (`d3-format package.json:49`). Its 24 test files import
  `{assert, test}` from `vitest`. That `assert` is the `assert` of chai.
- delaunator v5.1.0 runs `tsc && node test/test.js` (`package.json:30`). The `tsc` step writes
  the type declarations. It runs no test. robust-predicates v3.0.3 runs `node --test`
  (`package.json:21`). Both test files import `node:test` and `node:assert/strict`.

**Cases.** [parity.md](../parity.md) counts 434 test files and 3,837 static calls of `it(`,
`it.skip(` and `test(`. The names are full sentences, for example
`ticks(start, stop, count) returns the empty array if any argument is NaN`. Only
`d3-transition test/error-test.js:7` calls `describe`. One case skips upstream:
`d3-array test/bisector-test.js:165` (`it.skip`). Loops make more cases at run time:
- `d3 test/d3-test.js:10-11`: one case for each of the 30 dependencies of `package.json`
- `d3-geo test/snapshot-test.js:12-13`: one case for each of the 16 snapshots of `snapshots.js`
- `d3-geo test/projection/invert-test.js:5-38`: one case for each of 25 factories. The name comes
  from `factory.name`. 13 factories are anonymous default exports of `src/projection/*.js`, for
  example `geoAlbers`. JavaScript gives each of them the name `default`. The names
  `conicConformal`, `conicEqualArea` and `conicEquidistant` occur four times each (`:10-23`).
- `d3-axis test/snapshot-test.js:12-13` and `d3-contour test/snapshot.js:8-9`: 2 cases each
- internmap: `basicTest` makes one case in each of 4 calls, in each of its 2 test files
- `d3-time test/test-time-zones`: a shell script with 32 active checks. 6 of its names occur two
  times. The upstream test script does not run it.

**Assertions.** The pins have these calls. The second column counts the 434 test files. The third
column also counts the 41 helpers of [D3 ADR 0002](0002-file-naming-and-layout.md).

| Call | Test files (434) | Test files and helpers (475) |
|---|---:|---:|
| `assert.strictEqual` | 5,464 | 5,467 |
| `assert.deepStrictEqual` | 3,491 | 3,492 |
| `assert(value)` | 222 | 242 |
| `assert.throws` | 79 | 79 |
| `assert.ok` | 45 | 45 |
| `assert.deepEqual` | 12 | 12 |
| `assert.isNaN` (vitest only) | 12 | 12 |
| `assert.fail` | 5 | 5 |
| `assert.equal` | 2 | 2 |

- Node `assert.strictEqual` compares with `Object.is`. Thus NaN equals NaN. Also, −0 differs from
  +0.
- The Dart matcher `equals` compares with `==`. Thus NaN differs from NaN. Also, −0.0 equals 0.0.
- Node `assert.deepStrictEqual` also compares the prototypes, the own enumerable properties, the
  entries of a `Map` or a `Set` and the time value of a `Date`.
- The chai `assert.strictEqual` of vitest compares with `===`. Thus NaN differs from NaN. Also,
  −0 equals +0. d3-format tests NaN with `assert.isNaN`.
- In `node:assert/strict`, `equal` is `strictEqual`. `deepEqual` is `deepStrictEqual` there.
- `assert.throws` takes a RegExp, an error class or an object. Examples are `/negative radius/`
  (`d3-path test/path-test.js:247`), `TypeError` (17 calls), `RangeError` (3 calls) and
  `{name: "TypeError", message: /is not iterable/}` (`d3-array test/sort-test.js:64`).

**Helpers.** Test files import 35 upstream helpers ([D3 ADR 0002](0002-file-naming-and-layout.md)).
Examples are `assertPathEqual` (`d3-path test/asserts.js:3-15`), `assertInDelta`,
`assertRgbApproxEqual`, `OneTimeNumber`, the date builders `local` and `utc`, and the contexts of
d3-shape and d3-geo.

**Mutable defaults.** d3-format sets a default locale when it loads
(`d3-format src/defaultLocale.js:7-11`). The call writes the exported variables `format` and
`formatPrefix` (`:4-5`, `:13-18`). d3-time-format does the same for `timeFormat`, `timeParse`,
`utcFormat` and `utcParse` (`d3-time-format src/defaultLocale.js:4-27`).

In the files `test/defaultLocale-test.js`, the 3 cases of d3-format change the default. In d3-time-format, 5 of
the 9 cases change it (`:24-71`). The other 4 cases only read the en-US default (`:8-22`). Each
case that changes the default sets it back in a `finally` block, with an `enUs` definition of the
test (`d3-format test/defaultLocale-test.js:4-9`, `:24-26`). A failed or absent restore changes
the next tests.

**jsdom.** 78 of the 434 test files use jsdom: d3-selection 40, d3-transition 32, d3-zoom 3,
d3-contour 2 and d3-axis 1. Their cases call the wrapper `it` of `test/jsdom.js`. The wrapper
calls the global `it` when the file loads (`d3-selection test/jsdom.js:3-16`).

**Snapshots.** d3-geo has 16 PNG snapshots. node-canvas draws them. pixelmatch compares them
(`d3-geo test/snapshot-test.js:34-50`). d3-axis has 2 HTML snapshots. d3-contour has 2 SVG
snapshots. jsdom makes both kinds.

**Data files.** Some tests read files of the pin, for example `d3-array test/bin-test.js:227`
(`test/data/athletes.csv`). Other tests read npm packages that the pins do not hold
([D3 ADR 0001](0001-upstream-sources.md) item 14).

**Test files that a Node `vm` cannot evaluate as they are.**
- `d3-geo test/snapshot-test.js:10` calls `mkdirSync("./test/snapshots")` when the file loads.
  When the current directory is the submodule, the call writes into the submodule.
- `d3-geo test/projection/fit-test.js:3`, `:9` imports topojson-client and reads
  `node_modules/world-atlas/world/50m.json` when the file loads. `test/snapshots.js:1-2` imports
  node-canvas and topojson-client.
- `robust-predicates test/test.js:5-6` imports the npm packages robust-orientation and nextafter.
  Its `../index.js` re-exports `esm/` (`index.js:2-5`). `esm/` is not in git.
- The d3-axis and d3-contour snapshot tests import jsdom and js-beautify. d3-contour also needs
  htl and `module-alias` (`d3-contour package.json:59`). d3-dsv imports csv-spectrum
  (`test/csv-test.js:2`).

The port runs no `npm install`. No tool writes into `third_party/`
([ADR 0005](../../../../docs/adr/0005-pin-upstream-sources.md) item 2).

**Precedents.** The Chart.js port runs its pure specs on `package:test`. Each pure spec calls
`setUpSpecs()` of `package:chartjs_test_utils/pure.dart` first. That set-up restores `defaults`
after each test. The skip reasons are `'blocked: <module>'`, `'n/a: <reason>'` and
`'diverges: <row id>'`. The Chart.js tool 4 evaluates the specs in Node with module hooks
(`packages/flutter_chartjs_port/tool/upstream_manifest/src/chart_loader.mjs:20`). Tool 5 tracks the
state of each upstream case ([the Chart.js porting flow](../../../flutter_chartjs_port/doc/porting-flow.md)
§3 and §4).

**Reference engine.** Chart.js ADR 0032 §2 takes reference values only from an x64 build of Node.js
v24.12.0. On 2026-10-20, the machine of the maintainer had an arm64 v24.12.0 and a universal
v24.19.0 (`which -a node`). The probes of the research ran on the arm64 build. Thus their
results are indicative only.

## Decision

### 1. Spec form

- The Dart path of a test file follows [D3 ADR 0002](0002-file-naming-and-layout.md). Its header
  names the upstream test file, for example
  `// Ported from d3-path v3.1.0 test/path-test.js (ISC, Mike Bostock).`
- `test()` names are the upstream `it()` and `test()` names. A `describe` becomes a `group()`.
  When a name occurs again in one file, the later cases get ` #2`, ` #3` and the next numbers,
  in order.
- A loop that makes cases stays a loop. It gives the upstream names. When upstream takes a name
  from a JS value that Dart does not have, for example `Function.name`, the loop gives the name as
  a string. For an anonymous default export, this string is `default`, as in JavaScript. Thus 13
  cases of `invert-test.js` have the name
  `default(point) and default.invert(point) are symmetric`. The ` #2` rule numbers 12 of them.
- An async case `it(name, async () => {...})` becomes `test(name, () async {...})`.
- The upstream `it.skip` case skips as `'n/a: skipped upstream'`.
- A test file uses `package:test`. A test file that needs `dart:io`, `dart:ui` or `flutter_test`
  has `@TestOn('vm')` ([D3 ADR 0002](0002-file-naming-and-layout.md) section 2 gives its line).
- Each spec file calls `setUpSpecs()` (section 4) as the first statement of `main()`.

### 2. The assert stand-in

The port-only library `test/support/node_assert.dart` keeps the upstream assertions. It is a pure
layer. It imports only `package:test` and `js_semantics`. Dart reserves the word `assert`. Thus
the library gives three objects:

| Upstream import | Dart object | `strictEqual` | `equal`, `deepEqual` |
|---|---|---|---|
| `import assert from "assert"` (mocha) | `nodeAssert` | `Object.is` | the legacy forms of Node |
| `import assert from "node:assert/strict"` | `nodeAssertStrict` | `Object.is` | `strictEqual`, `deepStrictEqual` |
| `import {assert} from "vitest"` (d3-format) | `vitestAssert` | `===` (chai) | not used |

- **Members.** Each object has the members that the pins call: `strictEqual`, `notStrictEqual`,
  `deepStrictEqual`, `equal`, `deepEqual`, `ok`, `fail` and `throws`. `vitestAssert` also has
  `isNaN`. Each object is callable: `nodeAssert(value)` translates `assert(value)`.
- **Values.** The comparisons read the Dart forms of JS values of
  [D3 ADR 0006](0006-generators-accessors-and-js-values.md). A number is a number, with an `int`
  equal to the `double` of the same value. `null` and the `undefined` sentinel compare by
  identity. A string and a boolean compare by value. Other objects compare by identity in
  `strictEqual`.
- **`deepStrictEqual`** follows the Node algorithm. For a `List`, it compares the length and each
  element. Phase 1 needs numbers, strings, booleans, `null`, the `undefined` sentinel and lists.
  The gate 2 decision "Collections and iteration" adds the rules for objects, `Map`, `Set`, typed
  lists, records and arrays with properties ([porting-flow.md](../porting-flow.md) §2.9). The
  gate 3 decision adds dates.
- **`throws(fn, [expected])`** accepts these forms of `expected`:
  - a `RegExp`. `nodeAssert` tests it against the `toString()` of the error. `vitestAssert` tests
    it against the `message`, as chai does.
  - a `Type`, for a JS error class. `JsTypeError` stands for `TypeError`. `JsRangeError` stands
    for `RangeError` ([D3 ADR 0006](0006-generators-accessors-and-js-values.md) section 8).
  - a `Map` for the object form, for example
    `{'name': 'TypeError', 'message': RegExp('is not iterable')}`. It compares `name` and
    `message` of the error.
  - no argument: each throw passes.
- **Failures.** A failed assertion throws the `TestFailure` of `package:test`. Its message names
  the actual and the expected values.
- `test/port/support/node_assert_test.dart` tests the stand-in on the three legs. It covers NaN,
  ±0, `int` and `double`, `null` and the `undefined` sentinel, and each form of `throws`.

### 3. Ported helpers

- Each upstream helper that a test file imports is a ported file at the path of
  [D3 ADR 0002](0002-file-naming-and-layout.md). Its header names the helper, for example
  `// Ported from d3-shape v3.2.0 test/asserts.js (ISC, Mike Bostock).`
- A ported helper calls the stand-in where upstream calls `assert`. Its numbers follow
  [D3 ADR 0003](0003-number-to-string.md). For example, the normalizer of `assertPathEqual` calls
  `jsToFixed` and `jsRound`.
- The 5 jsdom wrappers wait for the DOM layer decision (gate 7). The snapshot generators wait for
  the image snapshot decision (gate 5). The date builders `local` and `utc` wait for the dates
  decision (gate 3).

### 4. Spec set-up and the default locales

- The port-only library `test/support/spec_setup.dart` has `setUpSpecs()`. It is a pure layer.
  Each spec file calls it, also under `flutter test`. `dart test` reads no
  `flutter_test_config.dart`. Thus the set-up is a call in each file, as in the Chart.js port.
- `setUpSpecs()` keeps the values of a list of module-level variables when it runs. In `tearDown`,
  it writes them back. The list:
  - d3-format (phase 1): `format` and `formatPrefix` of `src/defaultLocale.dart`
  - d3-time-format (phase 3): `timeFormat`, `timeParse`, `utcFormat` and `utcParse` of
    `src/defaultLocale.dart`
- A later port that adds a module-level variable that a spec changes adds it to the list.
- The restore runs after the `finally` blocks of the ported cases. These blocks stay as upstream
  wrote them.
- `spec_setup.dart` is a port-only file. Thus the restore needs no `DIVERGES` marker and no row.
- The D3 package has no `test/flutter_test_config.dart`. D3 has no `test/index.js`. The Flutter
  layer of phase 4 can add the file if a widget test needs a fixed test view.

### 5. Reference values

- Reference values come only from an x64 build of Node.js v24.12.0, as Chart.js ADR 0032 §2
  states. They never come from a browser or from an arm64 build. On Apple silicon, the darwin-x64
  build runs under Rosetta.
- The upstream specs carry their expected values inline. Thus a spec needs no generator.
- A port-only test that needs JS values gets them from a reference generator. Examples are the
  number methods of [D3 ADR 0003](0003-number-to-string.md) (in `js_semantics`), the date values
  of gate 3 and new fdlibm builtins.
- The D3 generators are in `packages/flutter_d3_port/tool/reference/`. They stop unless
  `process.arch` is `x64`. Each output records the Node.js version, the V8 version and the
  architecture. Do not edit a generated file by hand.
- A result of a probe on another engine is indicative only. A document that cites such a result
  says so.

### 6. Data files

These rules apply [D3 ADR 0001](0001-upstream-sources.md) item 14:
1. A test that reads a data file of the pin has `@TestOn('vm')`. It reads the file from
   `third_party/<repo>/test/` at test time, not when the file loads.
2. If the submodule is absent, the case skips as `'n/a: no checkout of third_party/<repo>'`.
3. If the variable `D3_DATA_REQUIRED` is `1`, the case fails instead. The CI leg that runs
   `test:cases` fetches these submodules by path ([D3 ADR 0001](0001-upstream-sources.md) item
   15). It also sets the variable.
4. The port copies no data file into the package.

### 7. Skip reasons

The skip reasons are those of the Chart.js port. Tool 5 rejects other reasons.
- `'blocked: <module>'`: the case needs a module that is not ported. `<module>` is the path of
  the source file, `<repo>/src/<path>.js`, when one file blocks the case. It is the repository
  name when the case needs several files of it. When modules of two phases block the case, the
  skip names the module of the later phase. An example is `'blocked: d3-dsv/src/csv.js'` for the
  `athletes.csv` case of d3-array.
- `'n/a: <reason>'`: the port does not port the behavior of the case. Examples are the upstream
  `it.skip` case, the docs case and the export cases of the `d3` bundle
  ([D3 ADR 0002](0002-file-naming-and-layout.md) section 7).
- `'diverges: <row id>'`: the case asserts a difference with a row in
  [differences.md](../differences.md).

These rules apply to the special cases:
- **jsdom.** A case that needs a DOM skips as `'blocked: d3-selection'`. The DOM layer decision
  (gate 7) gives each such case its final state.
- **Image snapshots.** The port compares no pixels with the PNG files of node-canvas. Pixels are
  display values (the principle of
  [Chart.js ADR 0034](../../../flutter_chartjs_port/doc/adr/0034-no-display-only-js-exactness.md)).
  The gate 5 decision "Image snapshots" gives the state of the 16 d3-geo cases
  ([porting-flow.md](../porting-flow.md) §2.13).
- **Time zones.** The time cases of phase 3 follow the gate 3 decision "Dates and time zones"
  ([porting-flow.md](../porting-flow.md) §2.11).

### 8. How tool 4 reads the test names

The D3 tool 4 is a Node.js tool of the D3 port
([ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) item 8). Phase 2 adds
it. It writes `packages/flutter_d3_port/doc/upstream/manifest.json` with the cases of each test
file at the pins. It reads the names in this way:
1. It evaluates each test file as an ES module in Node.js. Module hooks resolve the imports, as in
   the Chart.js tool 4. ADR 0005 item 2 allows this evaluation.
2. The globals and imports `it`, `it.skip`, `it.only`, `describe` and `test` (mocha, vitest and
   `node:test`) are stubs. A stub records the name and does not run the body.
3. A bare import of a pinned repository resolves to its `src/index.js` in `third_party/`. Thus the
   loop of `invert-test.js` gets the real factories and their names.
4. Each other bare import resolves to a stub module: `assert`, `vitest`, `node:test`, jsdom,
   js-beautify, htl, `module-alias`, node-canvas, pngjs, pixelmatch, topojson-client, csv-spectrum,
   robust-orientation and nextafter. A stub export is a `Proxy` that accepts each call and each
   property read.
5. The root `index.js` of robust-predicates resolves to a stub, because `esm/` is not in git.
6. The `fs` module of a test file is a stub over the real `fs`. A read of a file of the pin is
   real. A read of an absent file gives a stub value. A write does nothing. Thus no tool writes into
   `third_party/`.
7. The tool reads `d3-time/test/test-time-zones` as text. Each line that starts with `[` and ends
   with `test $? "<name>"` is one case. A line that starts with `#` is no case. Thus the script
   gives 32 cases.
8. The manifest gives each name with its file and its order. It applies the ` #2` rule of section
   1. The tool fails on a test file that it cannot evaluate. It never drops a file.

The count of [parity.md](../parity.md) is a static count of call sites. The manifest gives the cases
at run time. Tool 5 (phase 2) compares the manifest with the results of the Dart tests. It reports
each case as `passed`, `failed`, `skipped(<reason>)` or `missing`.

### 9. Test legs

| Suite | VM: `flutter test`, 3 OS | `dart test -p chrome -c dart2js` | `-c dart2wasm` |
|---|---|---|---|
| Tests without `@TestOn('vm')` | yes | yes | yes |
| Tests with `@TestOn('vm')` | yes | no | no |

The first pure test of phase 1 adds `flutter_d3_port` to the melos script `test:web`. Without a
test, `dart test -p chrome` exits with code 79 ([porting-flow.md](../porting-flow.md) §3).

### 10. No harness package now

The port-only harness is in `test/support/`. D3 has no upstream test-utils package. Its helpers
belong to single repositories. A package `d3_test_utils`
([ADR 0007](../../../../docs/adr/0007-package-names.md)) takes the harness when one of these
conditions occurs:
- The DOM layer needs a shared DOM stand-in (gate 7).
- A second package needs the stand-in.

A new D3 ADR records that move.

## Alternatives considered

- **`package:test` matchers by hand.** Rejected. `equals` hides the sign of −0 and fails for NaN.
  Each hand translation can make an assertion weaker. The reviewer cannot compare the files line
  by line.
- **One stand-in with the Node semantics for d3-format too.** Rejected. The chai `strictEqual` of
  vitest passes for −0 and +0. `Object.is` fails there. The vitest cases keep their upstream
  semantics with `vitestAssert`.
- **Generate the Dart tests from the JS tests.** Rejected. The tests call JS APIs freely. A
  generator cannot translate them in general.
- **A harness package in phase 1.** Rejected for now. It adds a workspace entry, a commit scope
  and a pubspec. The helpers belong to single repositories.
- **A static reader of the test names.** Rejected. The names of 6 loops come from run-time values,
  for example `factory.name` and the keys of `snapshots.js`.
- **`npm install` in a clone, then the upstream runner.** Rejected. The port runs no
  `npm install`. Some tests write into the clone. node-canvas needs a native build.
- **The restore in `test/flutter_test_config.dart`.** Rejected. The web legs run `dart test`.
  `dart test` does not read that file.
- **Copies of the data files in the package.** Rejected. The origin of some files is unknown. Each
  copy also needs a notice ([D3 ADR 0001](0001-upstream-sources.md) item 14).
- **Reference values from the arm64 build or from a browser.** Rejected. Chart.js ADR 0032 found
  last-bit differences between them and the x64 build.

## Consequences

- The specs port line by line. A reviewer compares the Dart file with the upstream file side by
  side.
- Phase 1 adds `test/support/node_assert.dart`, `test/support/spec_setup.dart` and their tests in
  `test/port/support/`.
- A test without `@TestOn('vm')` imports the pure files of `test/support/` and the pure helpers
  of `test/specs/` with relative imports. The D3 config of tool 1 allows these imports
  ([ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) item 8).
- Tool 4 of phase 2 needs a stub for each npm package of the upstream tests. A new npm import in an
  upstream bump makes tool 4 fail until the stub list has it.
- The reference generators need the darwin-x64 build of Node.js v24.12.0
  ([porting-flow.md](../porting-flow.md) §7, risk 8).
- A later phase that ports a test with data files adds its submodule path to the CI leg of
  `test:cases`.
- The jsdom cases, the image snapshot cases and the time-zone cases get their final rules from the
  decisions of gates 7, 5 and 3.

## Evidence

- The runners: the `scripts.test` entries of the 34 `package.json` files at the pins.
- The assertion counts: a scan of the `assert.<name>(` and `assert(` calls of the test files and
  the helpers at the pins, with the comments removed. With the comments, the count of
  `assert.strictEqual` is 5,471 in the test files and 5,474 with the helpers. delaunator is at
  v5.1.0 and robust-predicates at v3.0.3.
- The jsdom count: the test files of [parity.md](../parity.md) that contain `jsdom`.
- The loops: `d3 test/d3-test.js:10-19`, `d3-geo test/snapshot-test.js:12-13`,
  `test/projection/invert-test.js:5-38`, `d3-axis test/snapshot-test.js:12-13`,
  `d3-contour test/snapshot.js:8-9`, `internmap test/InternMap-test.js:21-27` and
  `test/InternSet-test.js:21-27`.
- The shell script: `d3-time test/test-time-zones` at v3.1.0. 32 lines start with `[`. 6 lines
  start with `#`.
