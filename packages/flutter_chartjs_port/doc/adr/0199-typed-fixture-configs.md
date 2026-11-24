# Chart.js ADR 0199: Typed fixture configs

- Status: proposed
- Date: 2026-11-24
- Supersedes: [Chart.js ADR 0029](0029-fixture-smoke-runner.md) §3 items 2 and 4 (the runner reads the pure data
  configs of `fixtures.json`) and §4 items 3 and 4 (a hand port returns a Map literal)
- Related: [Chart.js ADR 0115](0115-hand-ports-of-typed-data-fixtures.md),
  [Chart.js ADR 0198](0198-remove-raw-chart-view.md), [Chart.js ADR 0190](0190-chart-type-from-first-dataset.md)

## Context

The fixture runner of Chart.js ADR 0029 builds each fixture chart from a Map config: the decoded subtree of
`doc/upstream/fixtures.json` for a pure data fixture, and the Map literal of `fixture()` for a hand port. The
runner gives the Map the native values of `nativeFixtureColors` at run time: a CSS color text becomes a paint, a
keyword an enum value. The observation oracle O1 runs the same configs. The typed API of `lib/src/typed/` is the
config form of the port (Chart.js ADR 0198), so the largest corpus of real charts does not exercise it.

## Decision

1. A fixture config is a `FixtureConfig` of `chartjs_test_utils`: `FixtureConfig.typed(ChartConfig config,
   {options, run, description})`, or `FixtureConfig.map(Map config, {options, run, description})` for a config that
   a `ChartConfig` cannot hold. `options` is the typed `AcquireOptions` of Chart.js ADR 0200, and `run` the hook
   (`FutureOr<void> Function(Chart)`); `spriteText` and the keys of the image comparison have no port. The runner
   lowers a typed config with `ChartConfigLowering(config).lower()` and applies the plugin rule of `fixture.js:45-48`
   to the root scope (`fixtureInput`). Only a `FixtureConfig.map` goes through `nativeFixtureColors`.

   ```dart
   // Before
   Map<String, Object?> fixture() => <String, Object?>{
     'config': <String, Object?>{'type': 'bar', 'data': ..., 'options': ...},
     'options': <String, Object?>{'canvas': ...},
   };

   // After
   FixtureConfig fixture() => FixtureConfig.typed(
     ChartConfig(datasets: [BarDataset(data: .values([1, 2]))], ...),
     options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 256)),
   );
   ```

2. `tool/fixture_configs_gen.dart` (`fixtures:gen`) writes `test/fixtures/data_fixtures.g.dart` from
   `fixtures.json`: the config of each pure data fixture without a hand port (`dataFixtures`, with the first 12 hex
   digits of the manifest `sha256`), and the ICU twin of each data fixture with a moment pattern (`momentTwins`, row
   `adapt-date-moment-format`). `fixtures:gen:check` is a step of `check:port` and of the CI job `port-checks`.
   `fixtures.json` stays the source of truth, and the SHA-256 checks of the upstream files stay.
3. The writer (`tool/src/fixture_configs.dart`) gives each option with a typed parameter of the same value type to
   that parameter, and each other option to the `extra` Map of the nearest typed class, in the upstream key order.
   A value takes the native form of `nativeFixtureColors`: a CSS color is `ChartPaint.solid(Color(...))`, a keyword
   the enum value, `fill: false` is `FillTarget.none`. The axes are typed when the scale ids of Chart.js ADR 0191 are
   the upstream ids; else they all go to `extra['scales']`.
4. A config keeps its Map when a `ChartConfig` cannot hold it: no dataset (Chart.js ADR 0190), no chart type, a
   first dataset of another type than the chart, or a key of `config` or `data` with no parameter. The generated
   function and the hand port name the reason.
5. Each hand port returns a `FixtureConfig`. Its code is plain: no helper converts a Map at run time. A function of
   a color option returns a `ChartPaint`, and a run hook writes into a typed dataset scope by name (`jsSet`). A typed
   hand port ignores `prefer_const_constructors` and `prefer_const_literals_to_create_immutables`: each call gives
   new objects (`fixture.js:24`), and the chart keeps the Lists of its config and writes into some of them.
6. The runner takes the generated configs as `data` of `specsFromFixtures`. A skip wins over a hand port, and a
   hand port over a generated config. O1 runs each hand port and each generated config through `fixtureInput`, and
   its trace records the function of a typed `ChartValue.resolver` with the context only.
7. The plugin rule writes `plugins: false` into the typed options scope; a dataset can keep a number label, and the
   chart options a number `radius`, in their `extra`. `test/port/options/foreign_audit.dart` lists the three pairs.

## Consequences

- The fixtures exercise the typed API and its lowering; the O1 digests stay the same. At the pin, 414 of the 433 hand
  ports and 189 of the 231 generated configs are typed; 19 hand ports and 42 generated configs keep a Map (most have
  no dataset).
- A Chart.js bump runs `upstream:manifest` and `fixtures:gen`. A changed hand-ported fixture still fails at its
  stale `sha256`.
- The `extra` entries show the options with no typed parameter: the input of later typed parameters.

## Tests

- `test/tool/fixture_configs_test.dart`: the CSS colors against `paintOfCss`, the ICU patterns and the writer.
- `test/port/fixtures/index_test.dart`: each pure data fixture has a hand port or a generated config.
- `test/port/options/observation_test.dart`: the digests do not change.
- `dart run melos run test:fixtures` and `fixtures:gen:check`.
