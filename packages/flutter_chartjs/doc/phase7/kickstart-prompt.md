# Phase 7 (Controllers) of the Chart.js port

Start phase 7 (Controllers) of the Chart.js port in `packages/flutter_chartjs`. Work autonomously.
When you meet an open choice, choose the best option with the decision protocol below, and record
the decision. New ADRs start with the status "proposed". Do not change the status line of an
existing ADR. Do not edit an accepted ADR.

## Decision protocol

Use this protocol for every open choice: a design, an API form, a test strategy, a performance
change, or a deferred-plan trigger. Do not stop to ask for a choice that this protocol can decide.

1. List the options. Include the upstream form, the form that the existing ADRs give, and at least
   one faster form when performance is at stake.
2. Score the options in this order of priority (`porting-flow.md` §1.1):
   1. The upstream behavior that Chart.js ADR 0009 protects: the ticks, the hit element, the item
      order, the resolved option and a throw.
   2. Performance: the frame rate, the draw time and the raster time on the Pixel 8a, macOS,
      Chrome with dart2wasm and the iPhone.
   3. The upstream structure (AGENTS.md rule 2).
   4. Less code of our own.
3. Get evidence for each score. Read the pinned upstream source. Run a probe in the scratchpad.
   For performance, measure an A/B test (see "Measurement method"). A guess is not evidence.
4. For a choice with a large effect (a new ADR, a public type, a change of a shared layer), run a
   design panel: three independent drafts (fidelity first, performance first, simplicity first),
   then one judge that scores the drafts against the priority order and the evidence, then one
   synthesis that takes the winner and the best parts of the other drafts.
5. Choose the option with the best score. If two options are equal, choose the one with less code.
6. Record the decision:
   - a new design decision: a new ADR (proposed), self-contained, with the upstream file:line
     citations that you checked;
   - a behavior difference: a `// DIVERGES(chartjs): <row id>, <reason>` marker and a
     `differences.md` row;
   - a performance change: the figures before and after in `performance.md`;
   - every decision: one line in the final report, with the reason.
7. Stop and report only for these cases: a change of an ADR status line, an account or device
   problem that only the user can fix, a trigger of a deferred plan that this prompt does not
   decide, a push of commits that are not yours, or a gate that you cannot make green.

## Read first

- `packages/flutter_chartjs/doc/porting-flow.md`: §1 (the life cycle and §1.1 the performance
  rule), §1 step 6 (fixtures), §2 (the ADR table; §2.16 to §2.19), §3 (the test harness, "Frames
  in tests", "Fixture selection"), §4 (tools, tool 7 the fixture smoke runner, the
  `differences.md` schema), §5 (the phase table: phase 7 is Controllers) and §5.1 (deferred
  plans).
- `packages/flutter_chartjs/doc/upstream-tracking.md` §2.4 (the commit pin: the reference tools
  build Chart.js at the pinned commit) and the ledger `doc/upstream-ledger.md`.
- `packages/flutter_chartjs/doc/parity.md`: the rows of `src/controllers/*`,
  `test/specs/controller.*` and every row with a `blocked: controller.*` skip. Tool 6 writes
  `parity.md` from `doc/status.yaml`: edit `status.yaml` and run `dart run melos run parity`.
- Chart.js ADRs 0006, 0009, 0010, 0012, 0017 to 0026. Chart.js ADR 0021 (typed options in the
  resolver, §8 the gallery controller), ADR 0022 (the chart test harness), ADR 0025 (§7 the
  members of `types.Scale` that phase 7 adds, §8 the parsed read of the controllers: an absent key
  gives `undefined`) and ADR 0024 (the time scale and the 57 time twins) matter most.
- `packages/flutter_chartjs/doc/theming.md`: the phase 7 row of §10 (test 3 for elements and
  scales, test 5, the hover tests, the blue screen without plugins).
- `packages/flutter_chartjs/doc/performance.md`: §6 (how to measure, the frameless benchmark), §7
  (open), §10 and §11.6 to §11.8 (the scale path, the metrics cache, the open forms).
- The code that the controllers use: `lib/src/core/core.datasetController.dart`,
  `core.controller.dart`, `lib/src/elements/`, `lib/src/scales/`, and the harness in
  `packages/chartjs_test_utils/lib/`. Also the gallery controller
  `apps/chartjs_gallery/lib/demo/stress_point_controller.dart`, which phase 7 replaces.

## Before you start

- Another session can work in the same working tree (the d3 port). Run `git status` first. Do
  not stash, reset, check out or commit files that are not yours. Commit with explicit paths.
  Before a push, compare `main` with `origin/main`. If the push would also send commits of
  another session, stop and ask.
- The commit pin landed before this phase, in its own change: `chartJsVersion` is
  `<last version>+<sha8>`, the headers say `Chart.js v<version>+<sha8>`, and the ledger rows of
  the range are closed. Confirm it with `dart run melos run upstream:check`. Then run the
  module-start check (`upstream-tracking.md` §4.3) for the modules of phase 7. If a newer tag
  exists, report it and stop.
- ADR statuses: list in the report each ADR that the phase depends on, with its status. Chart.js
  ADRs 0024, 0025 and 0026 are accepted. Chart.js ADR 0026 supersedes Chart.js ADR 0008.
- The scratchpad folder can disappear at a session restart, and it belongs to one session of one
  account. Keep every input that a later step needs in the repository, as "Progress record"
  below says. Use the scratchpad only for downloads, builds and probes that a command can make
  again.
- Classify the chart cases first, read-only, before any port: for each case of the seven
  `controller.*.tests.js` files (143 cases, 11 without a chart), the modules that its assertions
  need, and the verdict (`phase7`, `blocked: <module of phase 8>` or `n/a: <reason>`). Do the same
  for every ported case that skips as `blocked: controller.*` (about 241 skip sites in
  `test/specs/` and `test/port/`, plus the 57 time twins of `test/port/scales/scale.time_test.dart`
  behind its `_lineTwin` helper). A plugin of phase 8 can still block a case: probe each doubtful
  case in the x64 Node.js with all components registered and with the plugins left out, and
  compare the values that the assertions read. The legend is displayed by default and changes the
  chart area.

## Progress record (resume from another account)

The phase can stop at a usage limit. A new session of another Claude account, possibly on
another machine, then continues it. That session has no access to this scratchpad, to the agent
transcripts in `~/.claude`, or to a workflow `resumeFromRunId`. Thus keep the full progress in
the repository:

- Create `packages/flutter_chartjs/doc/phase7-progress.md` in the first step. Update it after each
  step of the Method, after each wave and each unit, and before you stop for any reason. It has
  these parts:
  1. **State:** the current step of the Method, and each unit with its status (done, in
     progress, not started), its files and its last green check.
  2. **Decisions:** one line for each decision, with the reason and the ADR, row or figure that
     records it.
  3. **Inputs:** the paths of the working files of `doc/phase7/` (below) that the next steps
     read.
  4. **Environment:** the scratchpad files that a resume must make again (the x64 Node.js, the
     Chart.js build at the pin, the adapter packages, the probe harness), with the exact commands
     and checksums.
  5. **Next action:** one sentence that a new session can do first.
- Keep the working files that agents read and write in `packages/flutter_chartjs/doc/phase7/`,
  not in the scratchpad: the classification of the cases (JSON), the implementation specs of the
  design panels, the integration list (open defects and doc notes), the review findings with
  their verdicts, and the summaries of the performance runs with the paths of their raw data.
  Give each agent prompt these paths. An agent writes its result there before it ends.
- Commit at green checkpoints: after each wave or step whose gates pass, commit its files, the
  progress file and `doc/phase7/` with explicit paths, and push. First compare `main` with
  `origin/main`: another session can have commits there. A checkpoint commit passes all gates.
  Work that is not green stays uncommitted, and the progress file names it with its state.
- At the end of the phase, move each decision and fact to its permanent place (an ADR,
  `differences.md`, `performance.md`, `porting-flow.md` §5, `status.yaml`, the final report).
  Then delete `phase7-progress.md` and `doc/phase7/` in the last commit of the phase.

To resume: at the start, look for `packages/flutter_chartjs/doc/phase7-progress.md` in the working
tree and on `origin/main`. If it exists, read it and the files that it names first. Do not do a
step again that it marks done. Confirm its state with `git log`, `git status` and the gates, make
the environment again from its commands, and continue with its next action. Start an unfinished
unit again from its last recorded state.

## Scope

Port these files from the pinned sources in `third_party/Chart.js` at their mapped paths, with the
rule-2 headers, the `///` lines with the upstream file:line, and `DIVERGES` markers with
`differences.md` rows only where needed:
- `controller.bar`, `controller.line`, `controller.scatter`, `controller.bubble`,
  `controller.doughnut`, `controller.pie`, `controller.polarArea`, `controller.radar`;
- `src/controllers/index.js`, and the controllers part of `registerables` in `lib/src/index.dart`;
- the members of `types.Scale`, `types.RadialLinearScale` and the other type interfaces that a
  ported controller reads first (Chart.js ADR 0003, Chart.js ADR 0025 §7).

Also:
- Tool 7, the fixture smoke runner (`porting-flow.md` §4): the port of `src/fixture.js` of
  chartjs-test-utils 0.4.0 as a smoke runner (prefix match, the plugin rule, the `run` hook, no
  image comparison), the `fixtures` tag in `dart_test.yaml`, `--exclude-tags fixtures` in the
  melos `test` script, the melos script `test:fixtures`, and the CI job `fixtures` with the
  submodule checkout and `FIXTURES_REQUIRED=1`. Hand-port the fixture configs with functions to
  `test/fixtures/hand/`. The fixtures of the ported chart types must pass.
- Port-only reference tests for each controller: build real charts with `acquireChart` and
  compare them with Chart.js built at the pinned commit in the x64 Node.js. Reuse the
  infrastructure of phase 6: `tool/reference/scale_chart_common.mjs` (the Liberation Sans mock
  context and the draw calls) and `test/port/scales/scale_chart_harness.dart`. Compare the
  element properties, the resolved options, the parsed items, the stacks, the draw calls and the
  hit elements of `getElementsAtEventForMode`.
- The theme tests of the phase 7 row of `theming.md` §10.
- The gallery: each chart type renders, and the chart type list of `lib/main.dart` shows it.
  `LineController` and `ScatterController` replace `StressPointController` in the Core and Axes
  tabs, in the stress modes and in the frameless benchmark. Keep the phase 5 and phase 6 figures
  comparable: record the before figures first.
- The open performance work of `performance.md` §11.8: the tick font for each tick, the Map reads
  of `getMinMax`, the fdlibm `log10` of the logarithmic scale. Measure each with an A/B before you
  keep it.
- The macOS, Chrome and iPhone series of the scale path (§11.6), and the open macOS and Chrome
  series of phase 5, only in a time window that the maintainer gives for an idle Mac and with the
  iPhone on the cable.

Port the specs `test/specs/controller.*.tests.js` with the exact `describe` and `it` names. A case
that needs a module of a later phase skips as `'blocked: <module>'`. Do not change a spec port to
run variants: put variant coverage in port-only tests under `test/port/`. Lift the skips of the
earlier cases and of the time twins that the classification marks `phase7`.

## Exit criteria

- The 11 non-chart cases of the seven controller spec files pass.
- Each chart case that needs no module of phase 8 passes, in the controller specs and in the
  earlier spec files. Every other case skips with a valid reason. `test:cases` reports 0 missing
  cases in the ported spec files.
- The fixture smoke tests pass for the ported chart types, also in the CI job `fixtures`.
- Each controller has port-only reference tests through real charts, and they pass on the VM.
- The gallery shows every chart type.
- `performance.md` has the figures of the controller paths on the phones, and on macOS and
  Chrome when the maintainer gave a window.
- All gates pass, and CI passes after the push.

## Method

1. **Scout.** Read the sources and the code that the controllers use. Make the read-only
   classification. List the type members that each controller reads first.
2. **Design.** Run a design panel for each choice with a large effect, for example the fixture
   smoke runner and its hand-ported configs, the parsed read of Chart.js ADR 0025 §8 in the hot
   loops, and the replacement of `StressPointController`. Write each decision as a new Chart.js
   ADR (proposed).
3. **Port workflow.** Port in waves that follow the real imports: `controller.bar` first, then
   `controller.line`, `controller.bubble`, `controller.doughnut`, `controller.polarArea` and
   `controller.radar`, then `controller.scatter` (it extends line), `controller.pie` (it extends
   doughnut) and `index.js`. Agents of one wave work in parallel only on disjoint files. Each unit
   gets an adversarial fidelity reviewer that proves each defect with a probe. Then one
   integration agent registers the controllers, fixes cross-file errors, recounts `parity.md`
   through tool 6, applies the doc notes, and runs every gate.
4. **Spec bodies and fixtures.** Port the bodies of the cases that the classification marks
   `phase7`, lift the earlier skips, and run the fixture smoke runner.
5. **Gallery.** Show the chart types. Give each control a `ValueKey`.
6. **Adversarial review workflow.** Finders for each dimension (upstream fidelity for each
   controller, the fixture runner, JS semantics and the ADRs, tests and reference data, gallery,
   docs), one judge for each finder that tries to refute each finding, fixers on disjoint file
   groups, then all gates.
7. **Performance.** Profile the update and the draw of each chart type on the Pixel 8a, rank the
   port overhead against the upstream cost, and fix the real hot spots with the performance rule.
   Record the figures in a new section of `performance.md`.
8. **Commit and push** at each green checkpoint ("Progress record"), and at the end when the exit
   criteria hold. Split the final commits as phase 6 did (the package, the gallery, each
   performance change). Check that the tree of each commit passes analyze and the tests on its
   own, in a worktree.

Rules for every agent prompt: ADR status lines never change; an accepted ADR never changes; new
ADRs start proposed; docs in ASD-STE100 Simplified Technical English; no commit and no git
command that changes the index or the tree; re-read a shared file directly before each edit; run
`dart analyze` on `apps/chartjs_gallery` too, because the gallery implements `types.Chart`.

Lessons of phase 6 for the agent prompts:
- A failure message of `expect` that prints a resolver can walk its keys without end and hang the
  test process. Compare resolvers through `jsObjectKeys` and `jsGet`, or with
  `equals(x).matches(...)` and a short `reason`. Never pass a resolver to `equals` directly.
- Kill the hung `flutter_tester` processes that an agent leaves, before the next test run.
- In a shell script, quote a list of paths or use an array: zsh does not split an unquoted
  variable.
- A reference generator stops unless Node.js is the x64 build and the Chart.js build has the
  version of the pin. A rerun gives byte-identical data. Never edit generated data by hand.
- Each finder and each fixer of a review gets the exact files of its group. A fix that the docs
  group cannot make goes into its report for the owner of that file.

## Measurement method

- "Before" is the previous commit, or the snapshot of the phase work, in a git worktree in the
  scratchpad, measured in the same session as "after". Remove the worktree at the end.
- A variant changes one thing. Make it in a worktree, not in the main tree.
- Builds share the build folder of the app: build one at a time. An iOS `flutter run` also builds
  there.
- The frameless benchmark (`lib/main_bench.dart`) is the instrument of an A/B. Write the protocol
  before the first run: ABBA order (pair i runs A then B when i is odd, B then A when i is even),
  a gate before each pair (the battery at 33.0 °C or less and the big core at 2.8 GHz or more in a
  busy loop, at most 10 minutes of wait), the exclusion of a run whose case window ran below
  2.5 GHz, 6 pairs and 6 more when the interval includes 0, the mean of the pair differences of
  the run medians with a 95 % bootstrap interval of 20000 resamples, and the decision rule. An
  independent agent then recomputes the figures from the raw data.
- The stress entry gives the frame figures. It averages the windows after the first 30 frames. A
  scenario below about 4 FPS needs `--dart-define=SECONDS=60`.
- Pixel 8a: adb device `4B071JEKB17363`. Check that it is unlocked. Record the battery
  temperature and the big-core frequency of each run.
- macOS: one fresh process for each scenario, with the app window in front. Run macOS and Chrome
  only in a window when the maintainer confirms an idle Mac.
- Chrome: a dart2wasm profile build for each mode, each served at the root of its own free port
  with COOP and COEP headers. A separate Chrome instance with its own profile and
  `--enable-logging=stderr` prints the `STRESS` line to its log. Check the owner of a port with
  `lsof`.
- iPhone 17 Pro (Home_26+): use the cable. Before each run, check the lock state with
  `xcrun devicectl device info lockState`. Give each run a watchdog. Set
  `DEVELOPMENT_TEAM = T5447D382T` in `project.pbxproj` only for the runs, and restore the file
  byte for byte.
- Reference values come only from the x64 build of Node.js v24.12.0. Download
  `node-v24.12.0-darwin-x64.tar.gz` from nodejs.org into the scratchpad, compare its SHA-256 with
  `SHASUMS256.txt`, and run it with `/usr/bin/arch -x86_64`. Build Chart.js at the pinned commit
  in a throwaway clone outside the repository, because npm has no build of a commit.

## Gates

Before each commit, run from the repository root: `dart run melos run format:check`, `analyze`,
`test --no-select`, `test:web`, `test:cases`, `test:fixtures`, `check:port` (it runs tools 1-3,
`port:next:check` and `parity:check`), `gallery:build:web`, `gallery:build:android`, and
`uvx --from 'reuse[charset-normalizer]' reuse lint`. Before the push, also run the web tests
(dart2js and dart2wasm, through a stand-in `CHROME_EXECUTABLE` that records the URL) and the
gallery wasm build in the VS Code integrated browser, and read the VS Code diagnostics.
