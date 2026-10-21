# Fixture smoke runner: judgment of the panel

Panel: "Fixture smoke runner" (future Chart.js ADR 0029), phase 7, step 2 (Design). Drafts:
[draft-fidelity.md](draft-fidelity.md) (F), [draft-performance.md](draft-performance.md) (P) and
[draft-simplicity.md](draft-simplicity.md) (S).

Judge evidence folder (below: `<j>`):
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/design/fixture-runner-judge/`.

## Scoring method

Each answer gets a mark for each priority of the decision protocol: `+` (best of the three), `=`
(equal to the best), `-` (worse), `x` (breaks a protected behavior, an accepted ADR or a rule of
an existing doc). Priority 1 decides first. A lower priority decides only when the higher
priorities are equal. Test wall time is not a priority 2 figure: the protocol names frame rate,
draw time and raster time of the library. Test wall time only breaks a tie after priority 4.

## Upstream lines that the judge read at the pin

- chartjs-test-utils 0.4.0 `src/fixture.js:15-34` (`loadConfig`, `new Function` at `:24`),
  `:36-71` (`specFromFixture`; the plugin rule at `:45-48`; `Promise.resolve(run(chart))
  .finally(_done)` at `:63-68`), `:73-93` (`specsFromFixtures`, the regex at `:74`).
- `src/utils.js:77` (`useOffscreenCanvas`), `:90-92` (`spritingOn`), `:108` (`spritingOff`).
- Chart.js `test/fixtures/`: 667 `.js` and `.json` files, 667 PNGs, no two configs with the
  same base path, no `index.js`. `scale.time/invalid-data.js:8-36`: the data `'25:15:00'` with
  `parser: 'HH:mm:ss'`. `core.interaction/drawActiveElementsOnTop-false.js:23-26`: `plugins` is an
  object that turns off only `tooltip` and `legend`.
- `src/core/core.animator.js:38` (`_refresh`), `:57` (`_update`), `:112` (`_getAnims`). The port
  has no public `update`, `refresh` or `getAnims` in `Animator` (`lib/src/core/core.animator.dart`),
  thus no name collision (Chart.js ADR 0023).

## Facts that the judge checked

| Claim | Draft | Check | Result |
|---|---|---|---|
| 529 phase 7 fixtures, 401 data, 128 impure, 110 with a function | F, P, S | `doc/upstream/manifest.json` | correct |
| 25 phase 7 fixtures have a `run` hook | F, P | grep of the fixture folder | correct |
| 29 phase 7 fixtures have a `run` hook | S | same grep | wrong: 29 includes 4 `plugin.*` fixtures |
| 6 fixtures use `_getAnims`, `_refresh`, `_update` | F, P, S | grep | correct |
| 39 phase 7 fixtures parse with a moment format string | P | grep of `parser` (17 `controller.bar`, 12 `scale.time`, 10 `scale.timeseries`) | correct |
| 38 parse with a moment format; `scale.time/invalid-data.js` runs because `HH:mm:ss` has the same meaning in ICU | F | `invalid-data.js:14` and the row `adapt-date-moment-format` | wrong, see Q5 |
| `drawActiveElementsOnTop-false.js` gives other y ticks without the phase 8 plugins | F | `v2/dae/all.json` and `none.json` in the evidence folder of F | correct: the plugins `title` and `subtitle` are layout boxes |
| A registry import in `flutter_test_config.dart` costs about 14 s for 144 test files | P | re-run of the 20-file probe of F (`<j>/cfgprobe_rerun.txt`) | wrong, see Q1 |
| The config import costs 0.1-0.4 s for 20 test files | F | same re-run: 12.93 against 13.17 s, 13.02 against 13.39 s | confirmed: +0.24 s and +0.37 s |
| A function field in place of `_refresh` costs below 0.1 ns for each frame | F | re-run of `hooks_bench.dart` in AOT (`<j>/hooks_bench`) | confirmed: field 0.886 ns, method 0.829 ns, one call for each frame |
| `spritingOn` and `spritingOff` have no port | ADR 0022 (proposed) | `adr/0022-chart-test-harness.md:436-437` | F contradicts this item |
| A smoke test "passes when no exception occurs" | ADR 0009 §4 (accepted) | `adr/0009-no-display-only-js-exactness.md:75-77` | F adds an assertion (the canvas size) |

## Q1. Where the runner lives and where the spec files call it

All three drafts put the port in `packages/chartjs_test_utils/lib/src/fixture.dart`, re-export it
from `lib/src/index.dart` (`index.js:5`) and from `lib/flutter.dart`, and import `utils.dart` with
the prefix `utils` (Chart.js ADR 0022). All three keep the `auto` group at the upstream line of
each spec file. The drafts differ only at the call site.

| Draft | Call site | P1 | P2 | P3 | P4 | Evidence |
|---|---|---|---|---|---|---|
| F | `setUpFixtures(fixtureFiles)` in `flutter_test_config.dart`; `group('auto', specsFromFixtures('controller.bar'))` | = | = | = | - | 20-file compile probe (confirmed) |
| P | `test/fixtures/index.dart` imported as `fixture`; `group('auto', fixture.specs('controller.bar'))` | = | = | = | + | 20 files against 1 file (P1); compile figure P4 wrong |
| S | `group('auto', specsFromFixtures('controller.bar', hand: handFixtures))` | = | = | - | = | none for the call site |

Notes:
- P3: F maps `test/index.js:15-17` to the config file. P keeps the call text
  `fixture.specs(...)` of `jasmine.fixture.specs(...)`. Both keep the structure. S adds an
  argument that the upstream call does not have.
- P4: F needs a global set-up, the class `FixtureFiles` and the function `setUpFixtures`. P needs
  one import line in each of the 20 spec files and no global state.
- Flag: P extrapolates the one-file delta of P4 (0.08 s) to 144 files (14 s). The re-run of the
  20-file probe gives +0.24 s and +0.37 s for 20 files. The one-file delta is mostly a one-time
  compile. This error does not change the choice, because priority 4 already decides for P.

Winner: P.

## Q2. The source of the configs, the hand-port form and the header rule

All three read the data configs from `doc/upstream/fixtures.json` and the list from
`doc/upstream/manifest.json`, at run time, without the submodule. All three use one Dart file for
each impure fixture, with a function `fixture()` that runs the module body again at each call
(`fixture.js:24`), and a port-only index.

| Draft | Path of a hand port | Index | Stale check | Other parts | P1 | P2 | P3 | P4 |
|---|---|---|---|---|---|---|---|---|
| F | `test/fixtures/<path>.dart` | `test/fixture_index.dart` | full sha256 | restores shared object identity (5 phase 7 fixtures); hand-ports all 128 | = | = | = | - |
| P | `test/fixtures/hand/<path>.dart` | `test/fixtures/index.dart` (outside the mapped folder) | 12 hex digits of the sha256 | decodes `fixtures.json` once for each test file; hand-ports only the fixtures that run (118) | = | = | = | + |
| S | `test/fixtures/hand/<path>.dart` | `test/fixtures/hand/index.dart` (inside the mapped folder) | none | `jsonEncode`/`jsonDecode` copy for each test; `StateError` for an unknown key | = | = | = | - |

Notes:
- The path: the kickstart prompt (scope, tool 7) and `porting-flow.md` §1 step 6 name
  `test/fixtures/hand/`. F leaves the named folder for no gain: each form needs one target line in
  `tool/port_sources.yaml`. Use P.
- The identity restore of F: F's own probe (`identity_probe.mjs`) shows equal observations and
  draw calls for all 9 shared-object fixtures. No result changes at the pin. The restore adds code
  for a future case only. Reject. The ADR records the probe result.
- The copy for each test (S): each fixture config feeds exactly one test, so one decode for each
  test file (P) is enough. The copy is not necessary.
- P adds `.json` to `PortTarget.sourcesOf`. A `.json` config is always pure data, so no `.json`
  file ever gets a hand port. Reject that change.
- The six animator fixtures: see "Q2a" below.

Winner: P.

### Q2a. The six fixtures that drive the animator

Chart.js ADR 0019 (proposed) leaves two forms open: `@internal` members `getAnims` and `update`
with a test switch for `_refresh`, or pumps.

| Draft | Form | P1 | P2 | P3 | P4 |
|---|---|---|---|---|---|
| F | `getAnims`, `update`, `refresh` as a field that holds a function (the form of `Chart.resize`, Chart.js ADR 0022); `_Anims` becomes the `@internal` class `Anims` | = | = | + | - |
| P | `pumpFrame(500 ms)` for each `_update` call; no `_refresh` port | = | = | - | = |
| S | `pumpFrames(() => !running)`; the loop of images goes away | = | = | - | + |

- P1: the smoke test asserts no result of the animation. Equal.
- P2: the field form costs 0.06 ns for each frame (re-run, AOT; F also gives dart2wasm 0.337
  against 0.336 ns). One call for each frame. Equal.
- P3: F keeps the control flow of the six hooks and the patched-property read of
  `core.animator.js:38-52`. P and S change the hook bodies and need a `DIVERGES` marker at each
  site.
- Priority 3 decides. Winner: F.

## Q3. Test names and tool 5

| Draft | Name | Tool 5 | P1 | P2 | P3 | P4 |
|---|---|---|---|---|---|---|
| F | Karma URL `/base/test/fixtures/<path>` | new `--fixtures` mode with all checks; `--exclude-tags fixtures` in the case mode and in tool 6 | = | = | = | - |
| P | `<path>` relative to `test/fixtures/` | same mode; it compiles only the spec files with a fixture group; it prints the 10 slowest fixtures | = | = | = | + |
| S | `<path>` | no change; tool 5 only counts fixture tests | = | = | - | + |

Notes:
- Tool 5 accepts both names (`tool/src/spec_cases.dart:24-30`, `:144-156`). The tool 4 doc
  (`doc/upstream/README.md`, "Dart test names for tool 5") names the relative path as the Dart
  name. The `/base/` prefix comes from the Karma server (`karma.conf.cjs:102-105`), not from the
  Chart.js test structure. The relative path is also the key of `fixtures.json`, of the manifest
  and of the index. Use the relative path.
- S leaves a gap that S itself names: tool 5 does not report a failed fixture, a bad skip reason
  or a missing fixture (`spec_cases.dart:654-661`). The `--fixtures` mode closes it. The kickstart
  gates name `test:fixtures`.

Winner: P.

## Q4. Tag, scripts, CI job and the submodule

| Draft | Tag and exclusion | Script | CI job | Submodule, `FIXTURES_REQUIRED` | P1 | P3 | P4 | Docs |
|---|---|---|---|---|---|---|---|---|
| F | `dart_test.yaml`, `--exclude-tags fixtures` in `test` | `test:fixtures` (tool 5 `--fixtures`) | `fixtures`, no submodule | none | = | = | = | deviation recorded |
| P | same | same | same, with the YAML | none | = | = | = | deviation recorded |
| S | tag only, no exclusion | `flutter test --tags fixtures` | none | none | = | = | + | x: drops the CI job of the exit criteria |

Notes:
- All three drop the submodule checkout, the skip without the submodule and
  `FIXTURES_REQUIRED=1`. This is a deviation from the kickstart scope and from `porting-flow.md`
  §3 "Fixture selection". The reason of that rule (the runner reads the submodule) is gone: the
  runner reads only committed files, and the CI job `upstream-manifest` keeps them at the pin.
  Accept. ADR 0029 records it, and `porting-flow.md` §3, §4 item 7 and §5 change in the same
  commit.
- P gives evidence for the drop: the shallow fetch takes 1.86 s and 33 MB and adds a network
  failure mode, and `--exclude-tags fixtures` in a package without the tag excludes nothing and
  prints no warning.
- S breaks the exit criterion "The fixture smoke tests pass ..., also in the CI job `fixtures`"
  (kickstart prompt). S also runs each fixture on three OS legs and again in `test:cases` and
  `parity`, with a cost estimate from a proxy controller only.

Winner: P (F is equal on the decision; P has the evidence and the YAML).

## Q5. The set of phase 7, the phase 8 skips and "one frame"

All three run the 529 fixtures of the non-plugin prefixes and leave `plugin.*` to phase 8.

| Draft | Phase 8 rule | Moment rule | Skips | P1 | P3 | P4 |
|---|---|---|---|---|---|---|
| F | skip when the upstream observations (chart area, boxes, scales, ticks, element geometry, draw counts) change without the phase 8 plugins: 33 | 38 skip as `diverges`, with ICU twins | 71 | x (invalid-data) / + (dae) | = | - |
| P | skip when the removal of one plugin changes the canvas calls: 32; a stale `blocked: plugin.<id>` skip fails | 39 skip as `diverges` | 71 | - (dae) | = | = |
| S | skip only on a throw: 0 | not addressed | 0 | x | - | + |

Notes:
- `core.interaction/drawActiveElementsOnTop-false.js`: F shows that the hidden y scale has 4
  ticks with the plugins and 7 ticks without them, and that `title` or `subtitle` alone restores
  the 4 ticks. Ticks are a protected result (Chart.js ADR 0009). P runs this fixture, because no
  single removal changes it. The F criterion is the correct one: compare `all` with the set of
  phase 7, then name the first plugin whose removal changes the result, else the first plugin
  whose presence alone restores it.
- `scale.time/invalid-data.js`: F lets it run. The data `'25:15:00'` gives an invalid date in
  moment and the next day in intl, because the `tryParse` of intl does not check the field ranges
  (row `adapt-date-moment-format`). The min, the max and the ticks change. The row also says: "A
  spec case that ... parses a moment format string ... skips with this row." P is correct: 39
  skips.
- S runs the fixtures that need the filler, the title or the legend, and reports them as
  passed. The task asks for a skip with a reason. The result is a false `passed` in tool 5 and
  in `parity.md`. S also could not build 54 configs in its probe (moment and non-ASCII text).
- Merged set: 33 `blocked: plugin.<id>` (F, Appendix A) and 39
  `diverges: adapt-date-moment-format` (P), no overlap: 72 skips, 457 fixtures run. Hand ports:
  128 impure minus 11 impure skips = 117.
- Twins (F): the row `adapt-date-moment-format` gives each skipped case a port-only twin with ICU
  patterns. 36 of the 39 moment fixtures are data configs. A port-only test file runs them with
  `YYYY` to `yyyy` and `YYYY-MM` to `yyyy-MM`. This keeps the 17 `bar-thickness-*` configs as
  smoke tests of `controller.bar`. The 3 impure ones keep only the skip.
- One frame: F and P agree. `utils.acquireChart` (the constructor draws), the `run` hook settles
  through `pumpFrames` (frames of 16 ms, the Jasmine timeout of 5000 ms), then one frame through
  a new `pumpFrame()` of `dom.dart`, then `utils.releaseChart` in a `finally`. P measured the
  frame at 0.6 ms for each fixture (P5). S pumps inside the `finally`, also after a hook that
  threw. That frame can add a second error to the report. Use the F/P order.

Winner: F for the skip criterion, with the moment count and the stale-skip check of P.

## Q6. The fixture options

| Draft | `spriteText` | `tolerance`, `threshold`, `debug` | Other | P1 | P2 | P3 | P4 |
|---|---|---|---|---|---|---|---|
| F | port `spriting.js` (widths only) with a `debugTextOverride` field in `canvas_ui.dart` | `tolerance` feeds a canvas size check against the PNG size (tool 4 adds `pngWidth`, `pngHeight`) | complete table | = | - | x (ADR 0022 item 5) | - |
| P | ignored (n/a) | n/a | complete table, with `persistent`, `useShadowDOM` and the `width` typo | = | = | = | + |
| S | ignored | n/a | complete table | = | = | = | + |

Notes:
- `spriteText`: F shows that the sprite widths change the ticks of 4 fixtures and the layout of
  121 more. The smoke test asserts neither. The library behavior that Chart.js ADR 0009 protects
  does not change: only the text metrics of the harness change (Chart.js ADR 0015). The port
  adds a test hook to `lib/src/canvas/canvas_ui.dart` (+0.1 % to +0.2 % for each `measureText`
  and `fillText` call, re-run 9.606 against 9.665 ns in AOT, within noise) and contradicts
  Chart.js ADR 0022 item 5 (proposed). It also touches a file of the deferred
  `canvas-cuts-plan.md`. Reject.
- The canvas size check of F: Chart.js ADR 0009 §4 (accepted) says a smoke test "passes when no
  exception occurs". F itself calls the check a refinement. It needs a tool 4 change for 3 DPR
  fixtures. Reject for phase 7.
- `useOffscreenCanvas`, `canvas`, `wrapper`, `persistent`: all three pass them to `acquireChart`,
  which already reads them (Chart.js ADR 0022).

Winner: P (S is equal).

## Overall

| Question | F | P | S | Winner |
|---|---|---|---|---|
| Q1 location and call | 2nd | 1st | 3rd | P |
| Q2 sources, hand form, header | 2nd | 1st | 3rd | P |
| Q2a animator fixtures | 1st | 2nd | 3rd | F |
| Q3 names, tool 5 | 2nd | 1st | 3rd | P |
| Q4 tag, scripts, CI | 1st (tie) | 1st | 3rd (x) | P |
| Q5 set, skips, frame | 1st (x on one fixture) | 2nd | 3rd (x) | F |
| Q6 options | 3rd (x) | 1st | 1st | P |

Overall winner: **draft-performance.md (P)**. It breaks no ADR and no existing rule, and it has
the most complete evidence. Its errors (the 14 s compile figure, the missed
`drawActiveElementsOnTop-false.js` skip, the unneeded `.json` source map) do not change its
structure.

### Parts to take from the other drafts

From F:
1. The animator form of Q2a: `getAnims` and `update` as `@internal` members, `refresh` as a field
   that holds a function, `_Anims` as the `@internal` class `Anims`. The six hand ports stay 1:1.
   Add `test/port/core/core.animator_test.dart` cases (a replaced `refresh` stops the
   self-scheduling; `update(date)` ticks at that date).
2. The phase 8 skip criterion of Q5 (observations, not canvas calls, and the "presence alone"
   fallback): 33 `blocked: plugin.<id>` skips, with `drawActiveElementsOnTop-false.js` as
   `blocked: plugin.subtitle`. Keep the machine-readable list and the probe in the ADR evidence.
3. The ICU twins of the 36 data moment fixtures in a port-only test file with the tag
   `fixtures`, as the row `adapt-date-moment-format` asks.
4. The 20-file compile figure in place of the 14 s figure of P.
5. The shared-object probe result (9 fixtures, no change of a result) goes into the ADR. Tool 4
   does not change: no `pngWidth`, `pngHeight` or `shared`.

From S:
1. A `StateError` at the call of `specsFromFixtures` when a key of the hand index or of the skip
   Map is not a fixture of the manifest (fail early, in addition to the index test of P).
2. The runner parameter for the folder of the two JSON files (`upstream`, P names it
   `FixtureSource`), so that `chartjs_test_utils/test/fixture_test.dart` runs on a small
   temporary manifest.
3. The upstream citations `core.plugins.js:104-106` (`plugins: false` gives no descriptor) and
   `core.datasetController.js:288` (a `fill` option without the filler warns, not throws) in the
   ADR context.

### Corrections to P before the ADR

- Skips: 72 (33 `blocked`, 39 `diverges`), 457 fixtures run, 117 hand ports.
- Remove the `.json` candidate in `PortTarget.sourcesOf`.
- The `core.animator.dart` change of item F1 is in `lib/`: the ADR cites the AOT and dart2wasm
  figures of F (`hooks_bench.dart`) and the re-run of the judge.
- `differences.md`: keep `harness-fixture-sources` and `harness-fixture-frame` of P. The
  animator steps are no longer a difference.
