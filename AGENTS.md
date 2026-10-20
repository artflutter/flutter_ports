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
- `dart run melos run check:port`: the port checks of
  `packages/flutter_chartjs/doc/porting-flow.md` §4 (tools 1-3 and the checks of tools 6 and 8),
  as melos steps. The CI job `port-checks` runs the five checks with a shallow submodule checkout.
  Each check can also run alone:
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
    `double` and `num` values. It also fails on `DateTime.now(`: ported code reads the time with
    `jsDateNow`.
  - `port:next:check`: the check mode of tool 8 (`port:next`, below).
  - `parity:check`: the check mode of tool 6 (`parity`, below).
- `dart run melos run test:cases`: tool 5. It runs `test/specs/` and reports each upstream case of
  `doc/upstream/manifest.json` as passed, failed, skipped or missing. It fails on an unknown test
  name, a bad skip reason and a missing case of a `ported` module. CI runs it in the ubuntu `test`
  leg.
- `dart run melos run parity`: tool 6. It writes `packages/flutter_chartjs/doc/parity.md` from
  `doc/status.yaml`, the files of the pinned `third_party/` copies, the rule-2 headers, the spec
  case results of tool 5 and `doc/differences.md`. It runs the spec tests and needs the
  submodules (`upstream`). Do not edit `parity.md`. Edit `doc/status.yaml`. Placeholders in its
  texts give the derived values: `{{differences}}`, `{{passed}}`, `{{cases}}`,
  `{{skipped:<reason>}}`, `{{platforms}}`, `{{files:<glob>}}` and `{{rows:<area>:<status>}}`
  (`tool/src/parity.dart`). Put options after `--`. `-- --dry-run` prints the output.
  `-- --import` reads the cells of `parity.md` back into `doc/status.yaml`.
  `-- --import --base <file>` keeps the edits of both files. `-- --results <file>` reads the JSON
  reporter output of the spec tests from a file. `parity:check` fails when `parity.md` differs
  from the output, or on an error in `doc/status.yaml`. `check:port` and the CI job `port-checks`
  run it.
- `dart run melos run port:next`: tool 8. It lists the modules of `third_party/Chart.js/src` that
  are ready to port, in the phase order of `packages/flutter_chartjs/doc/porting-flow.md` §5. Each
  ready module comes with its line count and the interfaces that its type-only imports need. The
  list also gives the modules in progress, and the blocked modules with their missing imports. The
  port state comes from the rule-2 headers of the Dart files in `lib/` and from the status column
  of `doc/parity.md`. It needs the submodule (`upstream`). Without it, the tool exits with 2. Put
  options after `--`: `-- --json` prints the same data as JSON. `port:next:check` runs
  `-- --check`. It fails when tool 8 cannot read a module, a header line of `lib/` or a
  `parity.md` status. It also fails when an import does not resolve. `check:port` and the CI job
  `port-checks` run it.
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
    `js_class.dart` has the JS class values (Chart.js ADR 0020). `js_date.dart`, `js_map.dart` and
    `js_promise.dart` have `Date.now()`, the `Map` iteration and the promise jobs (Chart.js ADRs
    0010 and 0019).
  - `lib/src/core/core.element.dart` and `lib/src/elements/` (Chart.js ADR 0017): the port of
    `core.element.ts`, and the four elements (`element.point.dart`, `element.line.dart`,
    `element.bar.dart`, `element.arc.dart`) with `index.dart`. The port-only
    `element_options.dart` (Chart.js ADR 0018) has the typed element options: `PointOptions`,
    `LineOptions`, `BarOptions` and `ArcOptions`, Maps with a field for each known key. It also has
    `GenericElementOptions`, `clone`, the frozen state, `createElementOptions` and `copyOptions`
    (Chart.js ADR 0021). These files are pure layers. `Element` and each element class have a
    static `jsClass`, the class as a value (Chart.js ADR 0020). `PointElement` and `BarElement`
    implement `types.VisualElementRange`, the interface of `getRange`.
  - `lib/src/core/` also has these files:
    - `core.config.dart` has the theme hunks H0-H3 (Chart.js ADR 0001) and the `into` parameter
      of `resolveNamedOptions` (Chart.js ADR 0021). `core.adapters.dart` has `DateAdapter` and
      `DateAdapterBase`. `DateAdapterBase.jsClass` is the `_date` of `adapters`. Both files are
      pure layers.
    - `core.interaction.dart` and `core.layouts.dart` are pure layers. `Interaction` is a class with
      the static members `evaluateInteractionItems` and `modes`. `layouts` is a record of `addBox`,
      `removeBox`, `configure` and `update`. A box is a `LayoutItem` of `lib/src/types/layout.dart`.
    - `core.animation.dart` and the port-only `animation_spec.dart` (`AnimationSpec`, the typed
      animation config) are pure layers. `core.animations.dart` and `core.animator.dart` are not:
      `core.animator` imports `helpers.extras` (Chart.js ADR 0019).
    - `core.scale.dart` has `Scale`, `Scale.jsClass` and the port-only `Tick` class of the typedef
      at `core.scale.js:15`. `core.scale.dart` and `core.scale.autoskip.dart` are not pure layers:
      `core.scale` imports `helpers.extras`, and `core.scale.autoskip` imports `core.scale`.
    - `core.datasetController.dart` has `DatasetController`, with the mixin `ArrayListener` and
      the class value `DatasetController.jsClass` (Chart.js ADR 0020). `_update` is `update_`, and
      `_getSharedOptions` is `getSharedOptions_` (Chart.js ADR 0023). `cloneIfNotShared` and
      `getSharedOptions` copy the typed element options with `copyOptions` (Chart.js ADR 0021).
      It is not a pure layer: it imports `core.animations`.
    - `core.typedRegistry.dart` (`TypedRegistry`) is a pure layer. `core.registry.dart`
      (`Registry` and the singleton `registry`) and `core.plugins.dart` (`PluginService` and the
      record `PluginDescriptor`) are not pure layers: `core.registry` imports
      `core.datasetController` and `core.scale` (Chart.js ADR 0020).
    - `core.controller.dart` has `Chart`. `resize` and `eventHandler` are fields that hold a
      function (Chart.js ADR 0022). `Chart.register` and `Chart.unregister` take one List.
      `Chart.registry` is a static field (Chart.js ADR 0020). The dataset meta is the class
      `ChartMeta`. Its `_dataset` is `dataset_` (Chart.js ADR 0023). It is not a pure layer: it
      imports the platform layer.
    - `index.dart` has the exports of `src/core/index.ts`. `lib/src/index.dart` is the partial
      port of `src/index.ts`, with the four namespaces and `registerables`.
  - `lib/src/canvas/`: the port-only canvas layer (Chart.js ADRs 0013 and 0015). `canvas.dart` is
    the Canvas 2D interface, a pure layer. `canvas_ui.dart` and its four parts
    (`canvas_ui_path.dart`, `canvas_ui_paint.dart`, `canvas_ui_text.dart` and
    `canvas_ui_batch.dart`, the circle batch) are the `dart:ui` implementation. No helper imports
    them. `canvas_ui.dart` reflects the `style` attribute of the canvas. Other attributes keep their
    values as strings (Chart.js ADR 0022).
  - `lib/src/platform/` (Chart.js ADR 0014): the ports of `index.js`, `platform.base.js` and
    `platform.basic.js`, and three port-only files. `platform.flutter.dart` replaces
    `platform.dom.js`. `chart_host.dart` is the internal chart host (`ChartHost`,
    `RenderChartHost`). A resize observer gets its first notification at the next layout of the
    host. `flushCanvasMutations` is the mutation checkpoint of the harness (Chart.js ADR 0022).
    `native_event.dart` is the stand-in for the DOM event, a pure layer.
  - `lib/src/theme/` (Chart.js ADR 0001, port-only): `compile.dart` has `compileChartTheme` over
    raw Map themes, the emission guard and the deep freeze. `presets.dart` has the internal
    `ChartThemes.light` and `ChartThemes.none`. Both files are pure layers. Ported files never
    import them.
  - `test/flutter_test_config.dart`: the port of `test/index.js`. `flutter test` runs it around
    each test file of the package ([Tests](#tests)).
  - `test/specs/`: ported upstream specs. `test/kurkle_color/`: the ported `@kurkle/color` tests.
    `test/port/`: port-only tests, at the path of the `lib/src/` file that they test.
    `test/tool/`: tests of the port tools.
  - `tool/`: the port checks (`check_*.dart`), tool 5 (`spec_cases.dart`), tool 6 (`parity.dart`),
    tool 8 (`port_order.dart`), shared code in `tool/src/`, `port_sources.yaml` (one entry for each project that the package ports code
    from, with its pin), `upstream_manifest/` (tool 4, Node.js) and `reference/` (the Node.js
    generators of reference data).
  - `doc/`: all Chart.js port docs: roadmap, parity tracker, design docs, Chart.js-only decisions
    (`doc/adr/`, numbered from 0001) and the Chart.js prior-art survey (`doc/prior-art/`).
    - `doc/adr/`: Chart.js ADRs 0001-0023. Three of them are superseded: Chart.js ADR 0010
      supersedes Chart.js ADR 0002, Chart.js ADR 0011 supersedes Chart.js ADR 0005, and Chart.js
      ADR 0012 supersedes Chart.js ADR 0004. Chart.js ADR 0001 is accepted for its four theming
      invariants only. Chart.js ADRs 0013 (canvas model), 0014 (input events and the chart host),
      0015 (text), 0016 (frame scheduling), 0017 (element properties), 0018 (typed element
      options), 0019 (animation), 0020 (registry and component classes), 0021 (typed options in
      the resolver), 0022 (chart test harness on Flutter) and 0023 (underscore members with a
      colliding name) are proposed. Chart.js ADR 0016 supersedes Chart.js ADR 0007 when it is
      accepted.
      The other ADRs are accepted. Docs name them "Chart.js ADR NNNN". "ADR NNNN" alone is a
      `docs/adr/` file. An accepted ADR does not change. A changed decision gets a new ADR that
      states the complete decision and supersedes the old ADR.
    - `doc/differences.md`: one row for each `DIVERGES` difference.
    - `doc/status.yaml`: the hand-written parts of `parity.md`: the text outside the tables, the
      status text of each row, the Dart targets that no header gives and the port-only rows. Tool 6
      writes `doc/parity.md` from it. Do not edit `parity.md` by hand.
    - `doc/upstream/`: the output of tool 4 (`manifest.json`, `fixtures.json`). Do not edit it by
      hand.
    - `doc/porting-flow.md`: the porting plan (proposed). It has the module life cycle, the
      decisions, the test harness, the tools and the phases.
    - `doc/upstream-tracking.md`: how the port follows upstream after the pin (proposed).
    - `doc/upstream-ledger.md`: the upstream commits after the pin, with their triage.
    - `doc/text-metrics.md`: the text-metric probe, the canvas layer against the Chrome canvas.
- `packages/chartjs_test_utils`: the test harness, a port of chartjs-test-utils 0.4.0
  (`publish_to: none`, a dev_dependency of `flutter_chartjs`). The ported files are in `lib/src/`.
  `flutter_test` and `clock` are regular dependencies of the package, for `lib/src/dom.dart`.
  - `lib/pure.dart`: the pure part. It has `setUpSpecs()`, the spec set-up for `dart test`,
    `setUpDefaultsRestore()`, `createMockContext`, `MockContext` and the matchers
    (`toBeCloseToPixel`, `toBeCloseToPoint`, `toEqualOneOf`, `toEqualOptions`, `toBeValidChart`,
    `toBeChartOfSize`). `createMockContext` is in `lib/src/context.dart` (the row
    `harness-index-pure-split`). It also has `setUpBuiltins()` and `removeBuiltins()` (the row
    `harness-register-builtins`). `setUpSpecs()` calls `removeBuiltins()` and then
    `setUpDefaultsRestore()`.
  - `lib/flutter.dart`: the part that needs the Flutter engine, for `flutter test` only. It has
    `installTestFont()`. It also has the DOM stand-in of `lib/src/dom.dart` and the chart helpers
    `acquireChart`, `releaseChart`, `releaseCharts`, `afterEvent`, `waitForResize` and
    `triggerMouseEvent` (Chart.js ADR 0022). The DOM stand-in exports are `document`, `window`,
    `HarnessDocument`, `HarnessElement`, `HarnessWindow`, `setTimeout`, `afterEachChart`,
    `pumpFrames`, `waitForDone`, `frameInterval`, `specTimeout`, and the extensions
    `CanvasParentElement` and `CssProperties`.
  - `lib/src/utils.dart` ports `src/utils.js`: `acquireChart` and `releaseChart` (the ports of
    `_acquireChart` and `_releaseChart`), `waitForResize`, `afterEvent`, `_resolveElementPoint` and
    `triggerMouseEvent`. `lib/src/index.dart` ports `src/index.js`: `acquireChart`, `releaseChart`,
    `releaseCharts` and the registry `charts`. It imports `utils.dart` with the prefix `utils`
    (Chart.js ADR 0012, Collisions). Neither file is a pure layer.
  - `lib/fonts/`: the test font, Liberation Sans 2.1.5 (SIL OFL 1.1), with its `LICENSE`
    (Chart.js ADR 0015).
- `apps/chartjs_gallery`: gallery app (Android, iOS, web, macOS); every Chart.js chart type,
  marked pending until ported.
  - The page "Phase 3: canvas and host" has the tabs Canvas, Events, Text, Stress, Elements and
    Core. The Core tab (`lib/demo/core_demo.dart`) runs a real `Chart` of phase 5. Its type is the
    gallery controller `StressPointController` (`lib/demo/stress_point_controller.dart`, Chart.js
    ADR 0021 §8), registered through its class value.
  - `lib/demo/chart_canvas.dart` hosts a real chart. It connects `ChartHost.onTickerModeChanged`
    to `animator.mute` and `animator.unmute`.
  - The mode `chart` of the Stress tab measures the real chart path. `lib/main_stress.dart` is the
    profiling entry (`packages/flutter_chartjs/doc/performance.md` §6).
  - Each control has a `ValueKey`. Phase 7 replaces `StressPointController` with the ported
    `LineController` and `ScatterController`.
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
4. **Track parity.** Update the status text of the module in
   `packages/flutter_chartjs/doc/status.yaml` in the same change. Then run
   `dart run melos run parity`. Tool 6 writes `doc/parity.md`. Do not edit it by hand.
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
   (`packages/flutter_chartjs/doc/upstream-tracking.md` §4.8). Update the status texts in
   `doc/status.yaml` and run `dart run melos run parity`. Backports follow ADR 0006. They never move the submodule.
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
- Performance (`porting-flow.md` §1.1, proposed): when two Dart forms give the upstream behavior,
  choose the form with the larger measured gain. The priority is the upstream behavior, then
  performance, then the upstream structure, then less code of our own. A faster form that changes
  the upstream structure gets a `DIVERGES` marker and an `adapt` row. Record the figures in
  `performance.md`.
- The JS runtime in `lib/src/js/`: `jsObjectKeys` (`Object.keys` order), `jsSort` (the stable
  `Array.prototype.sort`), `jsCall` (a call of a JS function value with JS arity), `jsGet` (the
  property read `object[key]`), `jsOrZero` (`value || 0` before arithmetic, Chart.js ADR 0017
  §8, proposed) and the `undefined` sentinel (Chart.js ADR 0006). The conversions of
  `js_webidl.dart` (`canvasStyle`, `canvasNumber`, `canvasKeyword` and `canvasLineDash`) apply the
  WebIDL conversion of a Canvas 2D setter or of `setLineDash` to an option value (Chart.js ADR
  0017 §8, proposed). Ported code calls them where upstream uses the JS builtin or gives an option
  value to the canvas. A typed Map read stays `map[key]`. Use `jsGet` when the receiver can be a
  value that is not a Map, or when an absent key must give `undefined` and not `null`. Ported code
  tests for the sentinel with `identical(value, undefined)`. The runtime also has these parts:
  - `JsClass` of `js_class.dart`: a JS class as a value (Chart.js ADR 0020, proposed). A read of a
    static property follows the superclass chain. `jsConstruct` is `new target(...args)`.
    `jsAssign` is `Object.assign` on a class value or a Map.
  - `jsIsFunction` (`typeof value === 'function'`) is true for a class value. `jsCall` throws an
    `ArgumentError` for a class value. `jsTypeof` is `typeof`.
  - `jsObjectFreeze` and `jsObjectIsFrozen` are `Object.freeze` and `Object.isFrozen` (Chart.js
    ADR 0021 §5, proposed). Only a `JsFreezable` freezes. A write into frozen options throws a
    `TypeError`.
  - `jsOwnPropertyNames` is `Object.getOwnPropertyNames`. For a resolver, it gives the keys of the
    `ownKeys` trap. `jsMapForEach` is `Map.prototype.forEach` while the callback changes the Map.
  - `jsSplice` is `Array.prototype.splice`. `start` and `deleteCount` go through
    `ToIntegerOrInfinity`. Dart `null` stands for an absent `deleteCount`.
  - `jsDateNow` of `js_date.dart` is `Date.now()` on `clock.now()` (Chart.js ADR 0010 §6). Ported
    code never calls `DateTime.now()`.
  - `js_promise.dart` has the promise jobs of Chart.js ADR 0019 §7 (proposed):
    `jsEnqueuePromiseJob`, `jsRunWithMicrotaskCheckpoint` (the checkpoint after an animator frame
    callback) and `jsPromiseAll` (`Promise.all`).
- File names in the upstream spelling and the `_` rules: Chart.js ADR 0012.
  `check:headers` already compares each Dart path with the mapped path.
- Spec names and skip reasons: `porting-flow.md` §1 step 5 (proposed). The skip reasons are
  `'blocked: <module>'`, `'n/a: <reason>'` and `'diverges: <row id>'`. `test:cases` fails on
  other reasons. A chart case that needs only ported modules has a body and passes through the
  harness of Chart.js ADR 0022. The temporary reason `'blocked: harness'` of the phase 5 port step
  is gone.
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
  `lib/src/types/`, `lib/src/kurkle_color/`, the helpers except `helpers.extras`, the files of
  `lib/src/elements/`, and `platform.base`, `platform.basic` and `native_event` of
  `lib/src/platform/`. Of `lib/src/core/`, the roots are `core.defaults`, `core.element`,
  `core.config`, `core.adapters`, `core.interaction`, `core.layouts`, `core.animation`,
  `animation_spec` and `core.typedRegistry`. Of `lib/src/theme/`, the roots are `compile.dart`
  and `presets.dart`. The
  canvas interface `lib/src/canvas/canvas.dart` is pure, because `helpers.canvas` imports it.
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
- `flutter_test_config.dart` registers the built-in components before `main()` of each test file
  and before the snapshot of the restore (`setUpBuiltins()`, the row `harness-register-builtins`,
  Chart.js ADR 0022 §8). `setUpSpecs()` and `removeBuiltins()` remove them again. Thus a
  pure-layer file has the same state under `flutter test` and `dart test`.
- The unmount of the harness body calls `releaseCharts` (the row `harness-release-at-unmount`).
  This runs before the end-of-test checks of flutter_test and before the `tearDown` functions. A
  `tearDown(releaseCharts)` is the fallback after a failed test. `releaseCharts` never deletes a
  chart. Thus each test destroys the charts of the earlier tests of its file again, as upstream.
- A spec case that creates a chart is a `testWidgets` test (Chart.js ADR 0022 §2). Its file
  imports `flutter_test` and `package:chartjs_test_utils/flutter.dart`, and has `@TestOn('vm')`.
  `acquireChart` is synchronous. It throws a `StateError` outside the body of a `testWidgets`
  test. Thus a ported `beforeEach` or `afterEach` that acquires or reads a chart is a local
  function. Each test calls it first or last in its body.
- A pure-layer spec file that gets a chart case moves to `@TestOn('vm')` and `flutter_test` as a
  whole. Its pure cases then run on the VM only. A spec file with chart cases does not call
  `setUpSpecs()`, because its charts need the built-in components.
- A nested Map literal of a spec config needs the type `<String, Object?>`. `acquireChart` and
  `Config` write into it. A narrower Map, for example `{'responsive': true}`, throws a
  `TypeError` at the write.
- A chart spec ports a Jasmine spy as a recording function value of the test file. The spec
  stores it in place of the spied property, as `core.plugin_test.dart` and
  `helpers.core_test.dart` do.
- `toEqualOptions` reads the keys of an expected object with `jsObjectKeys`, as the upstream
  `for...in` with `hasOwnProperty` does. Thus it compares only the keys of the first scope of an
  expected resolver.
- It also installs the test font (Chart.js ADR 0015, the row `harness-test-font`): Liberation Sans
  under `Helvetica Neue`, `Helvetica`, `Arial`, `Liberation Sans` and `sans-serif`. A text style
  with another family, or with no family, measures with the square FlutterTest font. A test file
  of `chartjs_test_utils` that measures text calls `installTestFont()` itself.
- The defaults restore does not reset `Interaction.modes`. A test that adds a custom mode removes
  it at its end, for example with `addTearDown`.
- The defaults restore does not reset the `items` of `registry` (Chart.js ADR 0022 §8). A
  component that several tests of a file need registers in the `main()` of the file, before the
  snapshot of the restore. A component of one test registers in the test and unregisters at its
  end. A pure-layer test file registers its components through a new `TypedRegistry`. A file that
  compares the scopes or the registry with a run of the modules alone calls `setUpSpecs()` or
  `removeBuiltins()` first in `main()`.
- A spec with `setTimeout` or a Jasmine `done` callback is a `testWidgets` case with
  `@TestOn('vm')`. It uses `setTimeout` and `waitForDone` of
  `package:chartjs_test_utils/flutter.dart` (Chart.js ADR 0022 §7). `waitForDone` pumps frames of
  16 ms and fails after the Jasmine timeout of 5000 ms. Do not port a `setTimeout` as one long
  pump.
- The DOM stand-in of `chartjs_test_utils` keeps its element tree between the tests of a file. A
  DOM write outside a `testWidgets` body changes only the element tree. A spec gives the node type
  as a type argument: `document.createElement<HTMLCanvasElement>('canvas')`. The lint
  `omit_local_variable_types` flags a declared variable type.
- The Node.js generators in `packages/flutter_chartjs/tool/reference/` write
  `test/port/js/*_reference.dart`, `test/port/helpers/draw_point_reference.dart`,
  `test/port/elements/*_reference.dart` (point, line, bar and arc),
  `test/port/core/*_reference.dart` (animation, interaction, layouts, scale, scale autoskip,
  dataset controller, registry and controller) and `test/port/theme/*_reference.dart` (light and
  precedence). They stop unless Node.js is an x64 build.
  `tool/reference/text_metrics/` writes `test/port/canvas/text_metrics_reference.dart` from
  headless Chrome. The x64 rule does not apply to it. Do not edit the generated files by
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
