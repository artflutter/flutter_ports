# Chart.js ADR 0115: Hand ports of data fixtures with a class value

- Status: accepted (2026-11-12, by the porting lead). The code and the tests of section Tests pass.
- Date: 2026-11-12
- Supersedes: parts of [Chart.js ADR 0029](0029-fixture-smoke-runner.md): §4 item 1 (a hand port only for an impure
  fixture), the last sentence of §4 item 2 (`PortTarget.sourcesOf` takes no `.json` config) and the last sentence of
  §5 item 7 (the test of §10 item 6 keeps a hand port of a data config away).
- Related: Chart.js ADR [0054](0054-typed-internal-model.md) (the typed internal model). The rows
  `harness-fixture-sources` and `adapt-cubic-interpolation-mode-objects`.

## Context

The port replaces the keyword values of the options with native Dart values. A closed set becomes an enum. A value
that does work that a plugin can write becomes a class with a method: the interaction mode, the tooltip positioner and
the decimation algorithm are such classes. The maintainer allows no table from a name to a value, in `lib/` and in the
test harness.

The fixture adapter `nativeFixtureColors` of `chartjs_test_utils` gives an upstream JSON fixture the native values. For
an enum, it takes the value by its own name (`Enum.asNameMap`): this needs no table. For a class, a name has no value
to take: a map from the name to the class is the table that the maintainer rejects.

Chart.js ADR 0029 lets only an impure fixture (a `.js` config with a function or a value that JSON does not have) have
a hand port. A pure data fixture (a `.json` config, or a `.js` config that tool 4 could write as data) runs from
`doc/upstream/fixtures.json`. Thus a data fixture that holds a keyword of an option with a class value has no path
that keeps the rule.

The first such option is `cubicInterpolationMode`: 22 data fixtures hold `'monotone'`. 12 of them are `.json` files of
`plugin.filler`, and 10 are `.js` files of `controller.line`, `element.line` and `plugin.filler`. The observation
oracle O1 of Chart.js ADR 0054 also runs each data fixture from `fixtures.json`.

## Decision

1. A pure data fixture whose config holds a keyword of an option with a class value gets a hand port.
   `test/fixtures/<path>.json` or `test/fixtures/<path>.js` becomes
   `packages/flutter_chartjs_port/test/fixtures/hand/<path>.dart`. The file follows §4 items 2 to 4 of Chart.js ADR
   0029: the header names the upstream path, and the literals are the config of `fixtures.json` in its key order. The
   option value is the class value, with the marker of the row of the option.
2. The hand port wins over the data config of the same path (Chart.js ADR 0029 §5 item 7). `fixtures.json` keeps the
   config: tool 4 and the CI job `upstream-manifest` do not change.
3. `PortTarget.sourcesOf` of `tool/src/port_headers.dart` also gives `<path>.json` as a source of a Dart path. Thus
   `check:headers` accepts the header of item 1.
4. `test/port/fixtures/index_test.dart` maps each file of `test/fixtures/hand/` to the fixture of the manifest with the
   same path and the extension `.js` or `.json`. The test "no key of handFixtures is a pure data fixture" goes. In its
   place, a test fails on a hand port of a data fixture whose upstream file holds no keyword of an option with a class
   value: the list of these option keys is in the test.
5. The fixture adapter keeps the conversion of an enum by its own name. It has no rule for an option with a class
   value.
6. O1 runs a data fixture with a hand port from its hand port only. The name of its case stays `fixture <path>`.

## Consequences

- A later option with a class value (the point style, the fill target) adds its JSON fixtures as hand ports in the
  same way, and its key to the list of item 4.
- A Chart.js bump that changes such a JSON fixture fails at the stale `sha256` of its hand port (Chart.js ADR 0029 §5
  item 5), as for an impure fixture.

## Tests

- `test/port/fixtures/index_test.dart`: the registry, the mapping of item 4 and the list of the option keys.
- `test/port/options/observation_test.dart`: the 22 cases of item 6 run from the hand ports.
- `dart run melos run test:fixtures`: each hand port of item 1 runs and passes.
- `dart run melos run check:headers`: the headers of the hand ports of item 1.
