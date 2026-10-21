# Upstream manifest

This folder holds the output of tool 4 of [porting-flow.md](../porting-flow.md) §4. Do not edit
the JSON files by hand. Tool 4 writes them from the pinned `third_party/Chart.js` checkout.

| File | Contents |
|---|---|
| `manifest.json` | The spec cases, the image fixtures, the defaults inventory and the JS builtin sites of the pinned Chart.js (the commit pin v4.5.1+7169e651) |
| `fixtures.json` | The fixture configs that are pure data, by fixture path |

## Make the files again

1. Check out the submodules: `dart run melos run upstream`.
2. Run `dart run melos run upstream:manifest`. The script runs
   `node tool/upstream_manifest/upstream_manifest.mjs --src ../../third_party/Chart.js --out doc/upstream/manifest.json`
   in `packages/flutter_chartjs`.

The tool needs Node.js 22.18 or later, because Node.js strips the TypeScript types of `src/**/*.ts`
and the tool uses `module.registerHooks`. On an older Node.js, the tool stops with exit code 2.
The tool uses only `node:` modules. It gives the same bytes on x64 and on arm64. The CI job
`upstream-manifest` runs the tool with Node.js 24.12.0. The job fails when the committed files
differ from the output. Run the tool in each Chart.js bump PR.

The tool does not build Chart.js and writes nothing into `third_party/` (Chart.js ADR 0035). It
loads `src/index.umd.ts` through Node.js type stripping. Two module hooks resolve `./x.js` to
`./x.ts` and give the `version` of `package.json`. A stub replaces `@kurkle/color`.

## Spec cases

The tool runs each `test/specs/*.tests.js` file in a `node:vm` context. The `describe` bodies run.
The `it` bodies and the hooks do not run. Thus the tool finds the cases that a loop makes. A
missing global becomes a stub. The `stubbed` list of a spec file names these globals.

Each case has these fields:

| Field | Meaning |
|---|---|
| `describe` | The `describe` names, outermost first |
| `it` | The `it` name |
| `test` | The Dart `test()` name. A full name that an earlier case of the file has gets ` #2`, then ` #3` |
| `line` | The line of the `it` call in the spec file |
| `loop` | `true` when the `it` call site makes more than one case |
| `kind` | `chart` when the case calls `acquireChart`, else `non-chart` |
| `chartVia` | The first body that calls `acquireChart`: `beforeAll`, `beforeEach` or `it` |
| `constructsChart` | `true` when one of these bodies calls `new Chart(` itself. The `kind` does not change |
| `pending` | `true` for `xit`, `xdescribe` and an `it` without a body |

A case calls `acquireChart` when its `it` body, or a `beforeEach` or `beforeAll` body of its
`describe` chain, names `acquireChart`. A call of a function of the spec file that names
`acquireChart` also counts.

Each spec file also has `fixtureGroups`: the `describe` blocks whose body is
`jasmine.fixture.specs(<prefix>)`. These blocks make no spec cases. The fixtures are separate.

## Counts at the pin

The tool prints these counts. Tool 4 found at the commit pin v4.5.1+7169e651:
- 54 spec files and 1,036 cases. 707 cases are `chart` and 329 cases are `non-chart`. No case is
  `pending`. 10 cases have a ` #2` name. v4.5.1 had 1,022 cases (701 `chart`, 321 `non-chart`).
  The commit pin adds 3 `chart` cases to `core.scale`, 8 `non-chart` cases to `element.arc`, 1
  `chart` case to `controller.doughnut` and 2 `chart` cases to `controller.polarArea`.
- 163 `loop` cases from 26 call sites in 8 spec files. porting-flow.md names 31 loop-generated
  cases. That number is the 31 cases of `helpers.easing.tests.js` only. The other 132 cases come
  from loops in `controller.bar`, `core.datasetController`, `core.interaction`, `core.scale`,
  `plugin.tooltip`, `scale.logarithmic` and `scale.time`.
- 181 `non-chart` cases in the helper specs of phase 2: `helpers.collection` 5, `helpers.color` 4,
  `helpers.config` 31, `helpers.core` 53, `helpers.curve` 2, `helpers.easing` 31,
  `helpers.interpolation` 3, `helpers.math` 12, `helpers.options` 29 and `helpers.segment` 11. This
  number agrees with porting-flow.md. The count does not include `helpers.canvas` (12),
  `helpers.dom` (15) and `core.helpers` (2). With these files, the count is 210.
- 5 `non-chart` cases in `core.defaults` (3) and `core.ticks` (2). This number agrees with
  porting-flow.md.
- 667 fixtures. 519 fixture configs are pure data. v4.5.1 had 662 fixtures, with 516 pure data
  configs.

## Fixtures

A fixture is a config (`.js` or `.json`) under `test/fixtures` with its `.png` reference. The tool
groups the files as `specsFromFixtures` of chartjs-test-utils 0.4.0 groups them. A `.js` config
wins over a `.json` config of the same name. The fixture count of the manifest is authoritative.

Each fixture has these fields:

| Field | Meaning |
|---|---|
| `path` | The config path, relative to `test/fixtures` |
| `sha256` | The sha256 of the config file |
| `png`, `pngSha256` | The reference image and its sha256 |
| `specs` | The spec files whose fixture groups run the fixture. The prefix is a regular expression. Thus `scale.time.tests.js` also runs the `scale.timeseries` fixtures |
| `data` | `true` when the config is pure data |
| `impure` | The reasons when `data` is `false` |
| `threshold`, `tolerance` | The comparison values of the fixture, when the fixture sets them |

A pure config is a tree of plain objects, arrays, strings, finite numbers other than -0, booleans
and null. The reasons are `function`, `undefined`, `non-finite`, `negative-zero`, `hole`, `object`,
`accessor`, `global` (a value from a stub, for example `moment(...)`), `cycle` and `error`.

`fixtures.json` keeps each pure config as one line of compact JSON, in source key order. The key
order of a config can change the result of Chart.js. Thus the tool does not sort these keys. The
tool does not apply the changes of `specFromFixture` (the `description` and the `plugins: false`
default).

## Defaults inventory

`defaults.sites` lists the registration sites in `src/`, with file and line:
- the static class fields `defaults`, `defaultRoutes`, `overrides` and `descriptors`, with the class
  and its `id`
- the plugin object fields with the same names, with the plugin `id`
- the calls `defaults.set`, `defaults.describe`, `defaults.route` and `defaults.override`
- the `Defaults` constructor and the `new Defaults(...)` call of `core.defaults.js`.

A site gives the top-level keys of an object literal. A site keeps any other value as its source
text.

`defaults.values` is a snapshot of `defaults`, `overrides` and `descriptors` after the registration
of all controllers, scales, elements and plugins. Each map goes from a key path to a leaf. A
function leaf is the first 12 hex digits of the sha256 of its source. A `route` leaf is a property
that `defaults.route` made, with the value that it gives now.

Limits:
- The static scan does not follow a value through a variable. For example
  `core.typedRegistry.js` calls `defaults.set(scope, itemDefaults)`. The snapshot has the values of
  such calls.
- The snapshot does not name the target of a route. The `defaults.route` sites and the
  `defaultRoutes` sites give the targets.
- Node.js loops over the keys of a module namespace in code-unit order. Rollup keeps the export
  order. Thus the tool registers `PieController` before `PolarAreaController`, and the bundle does
  the opposite. The snapshot sorts its keys, so the order does not change the output.

## JS builtin sites

`builtins.sites` lists each site in `src/` of `Math.*`, `Number.*`, `Intl.*`, `Date.now`, the
global `parseFloat`, `parseInt`, `isNaN` and `isFinite`, `.sort(` and `.toFixed(`. `builtins.counts`
gives the count for each name. The scan reads tokens, so comments and strings do not count. The
scan reads a `.ts` file without its types. A bare name that the file imports or declares is not a
site. For example `core.scale.js` imports `isFinite` from `helpers.core`. The pin has no `.toFixed(`
site.

Limits: the scan does not resolve values. It does not find a builtin that the code reads through a
variable, and it does not find `sort` through a computed member.

## Consumers

- Tool 5 (`dart run melos run test:cases`) maps the Dart tests of `test/specs` onto the cases.
  See [Dart test names for tool 5](#dart-test-names-for-tool-5).
- The bump report and the watch preview of [upstream-tracking.md](../upstream-tracking.md) read the
  committed manifests.

## Dart test names for tool 5

Tool 5 matches a Dart test to a case by the group names and the test name. The rules are:

- The group names are the `describe` names. The test name is the `test` field of the case.
- A skipped case is a plain `test()` with a `skip:` string: `'blocked: <module>'`,
  `'n/a: <reason>'` or `'diverges: <row id>'`. Use this form also for a chart case that is a
  `testWidgets` test when it runs. `testWidgets` takes only `skip: true`, and the JSON reporter then
  gives no skip reason. Tool 5 reports such a test as an error. Do not put a skipped case in an
  extra `group(skip: ...)`. The extra group changes the name, and tool 5 then reports an unknown
  name.
- A fixture test is in the group of its fixture group, for example `group('auto', ...)` in the
  `describe` path of the spec file. Its name is the config path relative to `test/fixtures`, for
  example `controller.bar/aligned-pixels.js`. Tool 5 also accepts the upstream `it` name, which is
  the Karma URL `/base/test/fixtures/controller.bar/aligned-pixels.js` (`specFromFixture`,
  chartjs-test-utils `src/fixture.js:37`).
- A failed `setUpAll` or `tearDownAll` is one error that names the hook and its group. The tests of
  a group whose `setUpAll` failed do not run. Thus tool 5 can also report them as missing.
