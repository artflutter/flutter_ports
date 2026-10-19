# Agent onboarding

Dart pub workspace + Melos 8 monorepo of native Dart/Flutter ports of JavaScript chart
libraries. First port: Chart.js v4.5.1 → `packages/flutter_chartjs`.

## Commands

Run from the repository root. `melos` is a dev dependency: use `dart run melos …`.

- `flutter pub get`: resolve the whole workspace (single root `pubspec.lock`).
- `dart run melos run format` / `format:check`
- `dart run melos run analyze`: `dart analyze --fatal-infos` over the workspace.
- `dart run melos run test --no-select`: `flutter test` in every package with a `test/` dir.
  `--no-select` skips the interactive package picker. On ubuntu, CI also fetches the submodules,
  for `packages/flutter_chartjs/test/upstream_test.dart`.
- `dart run melos run test:web`: the `flutter_chartjs` and `chartjs_test_utils` tests without
  `@TestOn('vm')`, in Chrome, compiled with dart2js and with dart2wasm. It needs a local Google
  Chrome. CI job: `test-web`.
- `dart run melos run check:port`: the three port checks of
  `packages/flutter_chartjs/doc/porting-flow.md` §4 (tools 1-3), as melos steps. The CI job
  `port-checks` runs the three checks with a shallow submodule checkout. Each check can also run
  alone:
  - `check:lib-imports`: the import allowlists of `lib/`, of the pure layers and of the tests that
    the web legs compile. It also fails when a ported file imports `lib/src/theme/`. It keeps the
    `lib/pure.dart` closure of `packages/chartjs_test_utils` a pure layer.
  - `check:headers`: the line-1 header of each Dart file in `lib/`, `test/` and `tool/` of
    `flutter_chartjs` and `chartjs_test_utils`. It compares the project, license and holder with
    `packages/flutter_chartjs/tool/port_sources.yaml`, the `LICENSE` of the package that contains
    the file and `REUSE.toml`. It also fails on a source path that is not at the pin, or on a Dart
    path that is not the mapped path. A port-only file at the mapped path of a pinned source also
    fails. It compares each submodule gitlink with its `commit` in `port_sources.yaml`.
  - `check:js-semantics`: Dart forms that give other results than JavaScript. It examines the
    `lib/` and `test/` files of both packages whose header names a `js` project of
    `port_sources.yaml`. It resolves types with `package:analyzer` to find the interpolation of
    `double` and `num` values.
- `dart run melos run test:cases`: tool 5. It runs `test/specs/` and reports each upstream case of
  `doc/upstream/manifest.json` as passed, failed, skipped or missing. It fails on an unknown test
  name, a bad skip reason and a missing case of a `ported` module. CI runs it in the ubuntu `test`
  leg.
- `dart run melos run upstream`: check out the pinned reference sources (every `third_party/`
  submodule, at depth 1).
- `dart run melos run upstream:manifest`: tool 4. It writes
  `packages/flutter_chartjs/doc/upstream/` from `third_party/Chart.js`. It needs Node.js 22.18 or
  later. The CI job `upstream-manifest` fails when the committed files differ.
- `dart run melos run upstream:check`: fail unless `third_party/Chart.js` is pinned to the release
  tag named by `chartJsVersion`. CI runs it too.
- `dart run melos run gallery` (Chrome) / `gallery:macos` / `gallery:device` (Android/iOS):
  run the gallery.
- `dart run melos run gallery:build:web` / `gallery:build:android` / `gallery:build:ios`: build the
  gallery the way CI does (web with WebAssembly, debug APK, iOS without code signing).

Before a push, run `format:check`, `analyze`, `test --no-select`, `test:web`, `test:cases` and
`check:port`.

## Layout

- `packages/flutter_chartjs`: the Chart.js port (library, `publish_to: none` until 0.1.0).
  - `lib/src/`: ported modules at their upstream paths (`core/`, `elements/`, `helpers/`,
    `platform/`, `types/`), `kurkle_color/` (the `@kurkle/color` 0.3.2 port), and `js/`, the JS
    runtime: port-only `js_*.dart` files and the fdlibm ports `fdlibm_log.dart` and
    `fdlibm_atan.dart`. `js_webidl.dart` has the WebIDL conversions of the Canvas 2D setters.
  - `lib/src/core/core.element.dart` and `lib/src/elements/` (Chart.js ADR 0017): the port of
    `core.element.ts`, and the four elements (`element.point.dart`, `element.line.dart`,
    `element.bar.dart`, `element.arc.dart`) with `index.dart`. These files are pure layers.
  - `lib/src/canvas/`: the port-only canvas layer (Chart.js ADRs 0013 and 0015). `canvas.dart` is
    the Canvas 2D interface, a pure layer. `canvas_ui.dart` and its four parts
    (`canvas_ui_path.dart`, `canvas_ui_paint.dart`, `canvas_ui_text.dart` and
    `canvas_ui_batch.dart`, the circle batch) are the `dart:ui` implementation. No helper imports
    them.
  - `lib/src/platform/` (Chart.js ADR 0014): the ports of `index.js`, `platform.base.js` and
    `platform.basic.js`, and three port-only files. `platform.flutter.dart` replaces
    `platform.dom.js`. `chart_host.dart` is the internal chart host (`ChartHost`,
    `RenderChartHost`). `native_event.dart` is the stand-in for the DOM event, a pure layer.
  - `test/flutter_test_config.dart`: the port of `test/index.js`. `flutter test` runs it around
    each test file of the package ([Tests](#tests)).
  - `test/specs/`: ported upstream specs. `test/kurkle_color/`: the ported `@kurkle/color` tests.
    `test/port/`: port-only tests, at the path of the `lib/src/` file that they test.
    `test/tool/`: tests of the port tools.
  - `tool/`: the port checks (`check_*.dart`), tool 5 (`spec_cases.dart`), shared code in
    `tool/src/`, `port_sources.yaml` (one entry for each project that the package ports code
    from, with its pin), `upstream_manifest/` (tool 4, Node.js) and `reference/` (the Node.js
    generators of reference data).
  - `doc/`: all Chart.js port docs: roadmap, parity tracker, design docs, Chart.js-only decisions
    (`doc/adr/`, numbered from 0001) and the Chart.js prior-art survey (`doc/prior-art/`).
    - `doc/adr/`: Chart.js ADRs 0001-0017. Three of them are superseded: Chart.js ADR 0010
      supersedes Chart.js ADR 0002, Chart.js ADR 0011 supersedes Chart.js ADR 0005, and Chart.js
      ADR 0012 supersedes Chart.js ADR 0004. Chart.js ADR 0001 is accepted for its four theming
      invariants only. Chart.js ADRs 0013 (canvas model), 0014 (input events and the chart host),
      0015 (text), 0016 (frame scheduling) and 0017 (element properties) are proposed. Chart.js
      ADR 0016 supersedes Chart.js ADR 0007 when it is accepted. The other ADRs are accepted. Docs
      name them "Chart.js ADR NNNN". "ADR NNNN" alone is a `docs/adr/` file. An accepted ADR does
      not change. A changed decision gets a new ADR that states the complete decision and
      supersedes the old ADR.
    - `doc/differences.md`: one row for each `DIVERGES` difference.
    - `doc/upstream/`: the output of tool 4 (`manifest.json`, `fixtures.json`). Do not edit it by
      hand.
    - `doc/porting-flow.md`: the porting plan (proposed). It has the module life cycle, the
      decisions, the test harness, the tools and the phases.
    - `doc/upstream-tracking.md`: how the port follows upstream after the pin (proposed).
    - `doc/upstream-ledger.md`: the upstream commits after the pin, with their triage.
    - `doc/text-metrics.md`: the text-metric probe, the canvas layer against the Chrome canvas.
- `packages/chartjs_test_utils`: the test harness, a port of chartjs-test-utils 0.4.0
  (`publish_to: none`, a dev_dependency of `flutter_chartjs`). The ported files are in `lib/src/`.
  - `lib/pure.dart`: the pure part. It has `setUpSpecs()`, the spec set-up for `dart test`,
    `setUpDefaultsRestore()`, `createMockContext`, `MockContext` and the matchers
    (`toBeCloseToPixel`, `toBeCloseToPoint`, `toEqualOneOf`, `toEqualOptions`).
  - `lib/flutter.dart`: the part that needs the Flutter engine, for `flutter test` only. It has
    `installTestFont()`. Phase 5 adds `acquireChart` and the event helpers here.
  - `lib/fonts/`: the test font, Liberation Sans 2.1.5 (SIL OFL 1.1), with its `LICENSE`
    (Chart.js ADR 0015).
- `apps/chartjs_gallery`: gallery app (Android, iOS, web, macOS); every Chart.js chart type,
  marked pending until ported.
- `third_party/`: reference sources only: never imported, built or shipped. Excluded from
  analysis.
  - Shallow git submodules at release tags: `Chart.js` (`v4.5.1`), `kurkle-color` (`v0.3.2`) and
    `chartjs-test-utils` (`v0.4.0`). The last two come from Chart.js ADR 0011.
  - `fdlibm/`: unchanged netlib fdlibm 5.3 files (`e_log.c`, `e_log10.c`, `e_atan2.c`, `s_atan.c`)
    for `fdlibm_log.dart` and `fdlibm_atan.dart`. fdlibm has no git repository. Thus these files
    are a committed copy. `REUSE.toml` annotates them.
- `tool/`: repository scripts (`check_upstream_pin.sh`).
- `docs/`: docs for all ports only. `docs/adr/`: decisions for all ports. `docs/prior-art/`: prior
  art for future ports. Docs for one port go in the `doc/` folder of its package.

## Porting rules

1. **Port from the pinned source.** Read the upstream file in `third_party/Chart.js` (check it out
   first). Never port from memory, from upstream `master`, or from other Dart chart libraries.
2. **Mirror upstream structure.** Same module split and names (Dart-cased), so upstream releases can
   be diffed and replayed. Each ported file starts with a header naming its source, license and
   holder, `// Ported from <project> <version> <path> (<SPDX license>, <copyright holder>).`, e.g.
   `// Ported from Chart.js v4.5.1 src/helpers/helpers.math.ts (MIT, Chart.js Contributors).`
   A file with no upstream source starts with the port-only marker
   `// Original code, not ported from Chart.js: <reason>.` instead. All files under `test/port/`
   and `tool/` are port-only. `check:headers` enforces line 1.
3. **Port the specs.** Upstream `test/specs/<module>.tests.js` becomes a test file in `test/specs/`
   (see below). Behaviour without an upstream spec still needs tests.
4. **Track parity.** Update the module's row in `packages/flutter_chartjs/doc/parity.md` in the same change.
5. **No JavaScript at runtime.** No WebView, no JS engine, no `dart:js_interop` in library code
   (ADR 0001). Library code must compile for every Flutter platform and for web WebAssembly.
   `check:lib-imports` fails on a `lib/` import outside its allowlist.
6. **Bumping upstream** is its own change (ADR 0005). The submodule is a shallow clone without
   tags, so fetch both tags first:
   `git -C third_party/Chart.js fetch --depth 1 origin tag <old-tag> tag <new-tag>`,
   `git -C third_party/Chart.js checkout <new-tag>`, review
   `git -C third_party/Chart.js diff <old-tag> <new-tag> -- src test/specs test/fixtures`, and the
   bump report once it exists. Then run `git add third_party/Chart.js` and update `chartJsVersion`
   and the Chart.js `version`, `ref` and `commit` in
   `packages/flutter_chartjs/tool/port_sources.yaml`. Run `upstream:manifest`. Port the diff for
   every started module. Close the ledger rows of the range. Restamp the headers
   (`packages/flutter_chartjs/doc/upstream-tracking.md` §4.8). Update `parity.md`. Backports
   follow ADR 0006. They never move the submodule.
   `upstream:check` and `packages/flutter_chartjs/test/upstream_test.dart` fail on a mismatch.

The rules below come from the accepted ADRs and from two plans. The plans, `porting-flow.md` and
`upstream-tracking.md`, are still proposed. The doc paths are relative to
`packages/flutter_chartjs/doc/`.

- Backports from upstream `master`: ADR 0006 and `upstream-tracking.md` §2.2 (proposed).
- The backport header line `// Upstream backport: chartjs/Chart.js@<sha8> (#<PR>).`:
  `upstream-tracking.md` §2.5 (proposed). `check:headers` already accepts the line.
- The module status values of the `parity.md` legend: `porting-flow.md` §1 step 7 (proposed).
- `// DIVERGES(chartjs): <row id>, <reason>` markers and their `differences.md` rows:
  `porting-flow.md` §4 (proposed). `check:headers` already pairs markers with rows.
- The JS numeric translation rules: Chart.js ADR 0010. Number formatting: Chart.js ADR 0008.
  Emulate JavaScript only where the result changes behavior (Chart.js ADR 0009): the ticks, the
  hit element, the item order, the resolved option, or a throw. Do not emulate JavaScript for
  exact digits or pixels only. `check:js-semantics` already fails on the flagged forms. A kept
  form carries `// js-ok: <reason>`.
- Deferred plans (`porting-flow.md` §5.1), for example
  `packages/flutter_chartjs/doc/canvas-cuts-plan.md`: do not do their work in a phase. A change
  that edits a file that a deferred plan cites updates the plan in the same commit (the
  references, the inventory, the pinning tests, the estimates). A trigger of §5.1 brings the plan
  forward.
- The JS runtime in `lib/src/js/`: `jsObjectKeys` (`Object.keys` order), `jsSort` (the stable
  `Array.prototype.sort`), `jsCall` (a call of a JS function value with JS arity), `jsGet` (the
  property read `object[key]`), `jsOrZero` (`value || 0` before arithmetic, Chart.js ADR 0017
  §8, proposed) and the `undefined` sentinel (Chart.js ADR 0006). The conversions of
  `js_webidl.dart` (`canvasStyle`, `canvasNumber`, `canvasKeyword` and `canvasLineDash`) apply the
  WebIDL conversion of a Canvas 2D setter or of `setLineDash` to an option value (Chart.js ADR
  0017 §8, proposed). Ported code calls them where upstream uses the JS builtin or gives an option
  value to the canvas. A typed Map read stays `map[key]`. Use `jsGet` when the receiver can be a
  value that is not a Map, or when an absent key must give `undefined` and not `null`. Ported code
  tests for the sentinel with `identical(value, undefined)`.
- File names in the upstream spelling and the `_` rules: Chart.js ADR 0012.
  `check:headers` already compares each Dart path with the mapped path.
- Spec names and skip reasons: `porting-flow.md` §1 step 5 (proposed). The skip reasons are
  `'blocked: <module>'`, `'n/a: <reason>'` and `'diverges: <row id>'`. `test:cases` fails on
  other reasons.
- The spec paths and the test folders: Chart.js ADR 0012 and `porting-flow.md` §1 step 5
  (proposed). Upstream `test/specs/<base>.tests.js` becomes
  `packages/flutter_chartjs/test/specs/<base>_test.dart`. A pure-layer spec imports `package:test`,
  not `flutter_test` ([Tests](#tests)). It calls `setUpSpecs()` of
  `package:chartjs_test_utils/pure.dart` first in `main()`. Tests of behavior without an upstream
  spec go in `test/port/`. `check:headers` already compares each spec path with the mapped path.
- The source list `packages/flutter_chartjs/tool/port_sources.yaml`: Chart.js ADR 0011. It has
  one entry for each project that the package ports code from: Chart.js, fdlibm, `@kurkle/color`
  and chartjs-test-utils. Code from another project also needs an entry, with the license and
  holder of the header. A Chart.js bump (rule 6) also updates the Chart.js `version`, `ref` and
  `commit` in the entry. `check:headers` already fails on a
  mismatch.
- The notice of chartjs-test-utils goes in the `LICENSE` of
  `packages/chartjs_test_utils`, not in `packages/flutter_chartjs/LICENSE` (Licensing item 1):
  Chart.js ADR 0011. `check:headers` reads the `LICENSE` of the package that contains
  the file.
- The reference engine: Chart.js ADR 0010. Take JavaScript reference values only from
  an x64 build of Node.js v24.12.0. On Apple silicon, run the darwin-x64 build under Rosetta.
  Never take reference values from a browser or an arm64 Node.js.
- The four theming invariants (specs run unthemed, no forui or Material in `lib/`, no
  `Chart.defaults` writes for theming, no `lib/src/theme/` import in ported files): Chart.js ADR
  0001. `check:lib-imports` already fails on the two import invariants.

## Tests

- A pure-layer file reaches neither `dart:ui` nor `package:flutter` through its direct or indirect
  imports. `check:lib-imports` computes the pure layers from the roots in
  `packages/flutter_chartjs/tool/src/lib_imports.dart`. The roots include `lib/src/js/`,
  `lib/src/types/`, `lib/src/kurkle_color/`, `core.defaults`, the helpers except `helpers.extras`,
  `core.element`, the files of `lib/src/elements/`, and `platform.base`, `platform.basic` and
  `native_event` of `lib/src/platform/`. The canvas interface `lib/src/canvas/canvas.dart` is
  pure, because `helpers.canvas` imports it.
- Write the tests of pure layers with `package:test`, not `flutter_test`. These tests run on the
  VM (`test`) and in Chrome with dart2js and dart2wasm (`test:web`).
- A test file that imports `flutter_test`, `dart:io`, `dart:ui` or other non-pure code needs
  `@TestOn('vm')` after its header line. `test:web` does not compile it. `check:lib-imports` fails
  on a test file without `@TestOn('vm')` that imports more than pure layers, `package:test` and
  `package:chartjs_test_utils/pure.dart`. It does not examine the tests of `chartjs_test_utils`.
  Keep the same rule there by hand.
- `flutter test` runs `packages/flutter_chartjs/test/flutter_test_config.dart` around each test
  file of `flutter_chartjs`. It sets the test view to DPR 1 and 800 x 600 before each test, also
  after a test calls `tester.view.reset()`. It restores `defaults`, `overrides` and `descriptors`
  after each test (`setUpDefaultsRestore()`, the row `harness-defaults-restore`). Thus a test that
  changes them does not change the next test.
- It also installs the test font (Chart.js ADR 0015, the row `harness-test-font`): Liberation Sans
  under `Helvetica Neue`, `Helvetica`, `Arial`, `Liberation Sans` and `sans-serif`. A text style
  with another family, or with no family, measures with the square FlutterTest font. A test file
  of `chartjs_test_utils` that measures text calls `installTestFont()` itself.
- The Node.js generators in `packages/flutter_chartjs/tool/reference/` write
  `test/port/js/*_reference.dart`, `test/port/helpers/draw_point_reference.dart` and
  `test/port/elements/*_reference.dart` (point, line, bar and arc). They stop unless Node.js is an
  x64 build. `tool/reference/text_metrics/` writes `test/port/canvas/text_metrics_reference.dart`
  from headless Chrome. The x64 rule does not apply to it. Do not edit the generated files by
  hand.

## Licensing

- Chart.js is MIT. `packages/flutter_chartjs/LICENSE` lists both copyright holders and
  `REUSE.toml` annotates the paths. CI runs `reuse lint`.
- Code taken from any other project needs three things in the same change:
  1. its notice in the `LICENSE` of the package that contains the code;
  2. a `REUSE.toml` annotation for the files, placed last because the last matching table wins
     and must list every holder;
  3. the file header from rule 2.

  For an MIT source, the notice is its copyright line, added to the existing MIT text. For example,
  the `@kurkle/color` port added `Copyright (c) 2018-2021 Jukka Kurkela`
  (`third_party/kurkle-color/LICENSE.md` at `v0.3.2`). For an Apache-2.0 source, include the full
  license text as a separate component of the package LICENSE, along with its `NOTICE` content,
  and add `LICENSES/Apache-2.0.txt`. For another license, add its notice as a separate component
  of the package LICENSE. Also add `LICENSES/<SPDX-ID>.txt`. The fdlibm ports did this for SunPro.
  The test font did this for SIL OFL 1.1: the OFL notice is a separate component of
  `packages/chartjs_test_utils/LICENSE`, `LICENSES/OFL-1.1.txt` has the license text, and the last
  table of `REUSE.toml` annotates `packages/chartjs_test_utils/lib/fonts/**`. The font files and
  their `LICENSE` stay unchanged.
- Never copy code from GPL or otherwise incompatible projects, even for "small" helpers.
  `flutter_web_chartjs` is GPL-3.0; current WebF is GPL-3.0 with an enterprise exception. Ideas
  only. See `packages/flutter_chartjs/doc/prior-art/`.

## Conventions

- Lints: `very_good_analysis` (root `analysis_options.yaml`, which also carries its formatter
  settings, so run Dart tools after `flutter pub get`). Public APIs are documented.
- Commits: Conventional Commits, signed off (`git commit -s`, DCO), for example
  `feat(flutter_chartjs): port helpers.math`. Checks:
  - lefthook ≥ 1.0 `commit-msg` hook (`lefthook install`): `commitlint_cli` checks the type, and
    the scope when one is given, against the list in `commitlint.yaml`; a second command requires a
    `Signed-off-by` trailer;
  - CI `dco` job: checks the sign-off on every pull-request commit.
- CI jobs (`.github/workflows/ci.yaml`): `format`, `analyze`, `test` (ubuntu, macOS, Windows),
  `test-web`, `port-checks`, `upstream-manifest`, `gallery-web`, `gallery-android`, `gallery-ios`,
  `upstream-pin`, `reuse` and `dco`.
- Toolchain: Flutter 3.44.9, pinned in `.fvmrc`; CI reads the same file.
