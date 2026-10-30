# Agent onboarding

Dart pub workspace + Melos 8 monorepo of native Dart/Flutter ports of JavaScript chart
libraries. First port: Chart.js v4.6.1 →
`packages/flutter_chartjs_port`. Second port: D3 v7.9.0 →
`packages/flutter_d3_port`, in phase 0 (scaffold and design, no ported code). Third port: Apache
ECharts 6.1.0 with its renderer zrender 6.1.0 → `packages/flutter_echarts_port`, in phase 0
(scaffold and design, no ported code).

## Commands

Run from the repository root. `melos` is a dev dependency: use `dart run melos …`.

- `flutter pub get`: resolve the whole workspace (single root `pubspec.lock`).
- `dart run melos run format` / `format:check`
- `dart run melos run analyze`: `dart analyze --fatal-infos` over the workspace.
- `dart run melos run test --no-select`: `flutter test --exclude-tags fixtures,golden` in every
  package with a `test/` dir. `--no-select` skips the interactive package picker. Options after
  `--` go to each `flutter test` call, for example
  `dart run melos run test --no-select -- --experimental-faster-testing --total-shards=3 --shard-index=0`.
  Without `--`, melos stops with an error. The CI job `test` runs this command with the shard
  indexes 0, 1 and 2 on each OS, in bash. `--experimental-faster-testing` compiles the test files of a package into one test app and runs
  each file in its own engine. Flutter ignores the flag for a package with one test file. On a
  16-core Mac, the flag makes the local run slower. Thus the script does not set it. The flag writes
  Dart files into `build/isolate_spawning_tester/` of each package, and `format:check` fails on
  them. Delete these folders before `format:check`. package:test puts a part of the tests of each
  file in each shard, in the order of the file ([Tests](#tests)). A shard with no tests fails. On
  ubuntu, CI also fetches the three Chart.js submodules, `third_party/d3` and the two ECharts
  submodules by path in each shard, for the `test/upstream_test.dart` of `flutter_chartjs_port`,
  `flutter_d3_port` and `flutter_echarts_port`.
- `dart run melos run test:web`: the `flutter_chartjs_port` and `chartjs_test_utils` tests without
  `@TestOn('vm')`, in Chrome, compiled with dart2js and with dart2wasm. It needs a local Google
  Chrome. CI job: `test-web`.
- `dart run melos run check:port`: the port checks of
  `packages/flutter_chartjs_port/doc/porting-flow.md` §4 (tools 1-3 and the checks of tools 6 and 8),
  as melos steps. The CI job `port-checks` runs the five checks with a shallow checkout of the
  three Chart.js submodules.
  Each check can also run alone:
  - `check:lib-imports`: the import allowlists of `lib/`, of the pure layers and of the tests that
    the web legs compile. It also fails when a ported file imports `lib/src/theme/`, and when a
    file of `lib/src/widgets/` imports a file of `controllers/`, `scales/`, `elements/` or
    `plugins/`, or `lib/src/index.dart` or `lib/src/index.umd.dart`: the widget registers no
    component (Chart.js ADR 0048 §3). It keeps the `lib/pure.dart` closure of
    `packages/chartjs_test_utils` a pure layer.
  - `check:headers`: the line-1 header of each Dart file in `lib/`, `test/` and `tool/` of
    `flutter_chartjs_port` and `chartjs_test_utils`. It compares the project, license and holder with
    `packages/flutter_chartjs_port/tool/port_sources.yaml`, the `LICENSE` of the package that contains
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
  leg of shard 0. It passes `--exclude-tags fixtures`, as tool 6 does. It also fails on a stale
  `blocked: <module>` skip literal in `test/` (each `src/` row of the module `ported`), on an
  unknown module and on a `blocked:` literal in another form than `blocked: <module>` (Chart.js ADR
  0041). The check reads the string literals of `test/` without `test/tool/` and without the
  generated `*_reference*.dart` files. `test:fixtures` runs the same check.
- `dart run melos run test:fixtures`: tool 7, the fixture smoke tests of `flutter_chartjs_port`
  (Chart.js ADR 0029). It is tool 5 with `--fixtures`: it runs the tests with the tag `fixtures` of
  the spec files with a fixture group and of `test/port/fixtures/`. It reports each upstream fixture
  as passed, failed, skipped or missing, and prints the 10 slowest tests. It fails on a failed,
  missing or unknown fixture, on a fixture group that no Dart file calls and on a bad skip reason.
  It also runs the stale-block check of `test:cases` (Chart.js ADR 0041). The runner compares the
  SHA-256 of each upstream fixture file `third_party/Chart.js/test/fixtures/<path>` with the
  manifest. Without the submodule, each fixture skips with `'n/a: the submodule third_party/Chart.js
  is not checked out'`. With `FIXTURES_REQUIRED=1`, it fails. The CI job `fixtures` makes a shallow
  checkout of `third_party/Chart.js` and sets `FIXTURES_REQUIRED=1`.
- `dart run melos run test:goldens`: the theme goldens of `flutter_chartjs_port`
  (`test/port/theme/goldens_test.dart`, the tag `golden`, theming.md §8 test 9, Chart.js ADR 0050).
  They skip unless `CHART_GOLDENS=1`. Their pinned runner is the CI job `fixtures` on
  `ubuntu-24.04`, because the font manager of the platform rasterizes the text. A local Mac never
  writes the golden files. Only a `workflow_dispatch` run of CI with the input `update_goldens`
  writes them (`-- --update-goldens`). That run uploads them as the artifact `theme-goldens`. The
  input `flutter_version` writes `.fvmrc` first, for a move to a new Flutter. The golden files are
  `test/port/theme/goldens/bar_light.png` and `bar_dark.png`. On each other run, the job `fixtures`
  compares them after `test:fixtures`. A failed compare uploads the `failures/` images.
- `dart run melos run parity`: tool 6. It writes `packages/flutter_chartjs_port/doc/parity.md` from
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
  are ready to port, in the phase order of `packages/flutter_chartjs_port/doc/porting-flow.md` §5. Each
  ready module comes with its line count and the interfaces that its type-only imports need. The
  list also gives the modules in progress, and the blocked modules with their missing imports. The
  port state comes from the rule-2 headers of the Dart files in `lib/` and from the status column
  of `doc/parity.md`. It needs the submodule (`upstream`). Without it, the tool exits with 2. Put
  options after `--`: `-- --json` prints the same data as JSON. `port:next:check` runs
  `-- --check`. It fails when tool 8 cannot read a module, a header line of `lib/` or a
  `parity.md` status. It also fails when an import does not resolve. `check:port` and the CI job
  `port-checks` run it.
- `dart run melos run upstream`: check out the pinned reference sources (every `third_party/`
  submodule, at depth 1). These are the three Chart.js submodules, the 34 D3 submodules and the
  two ECharts submodules.
- `dart run melos run upstream:manifest`: tool 4. It writes
  `packages/flutter_chartjs_port/doc/upstream/` from `third_party/Chart.js`. It needs Node.js 22.18 or
  later. The CI job `upstream-manifest` fails when the committed files differ.
- `dart run melos run upstream:check`: fail unless `third_party/Chart.js` is pinned to the release
  tag named by `chartJsVersion`. For a commit pin (`<last version>+<sha8>`), the gitlink must
  start with `<sha8>`, and the tag `v<last version>` must exist. CI runs it too. It also fails
  unless `third_party/d3` is at the tag `v<d3Version>`. Each other D3 gitlink must be the commit
  of its `ref` and equal its `commit` in `packages/flutter_d3_port/tool/port_sources.yaml`. It
  also fails unless `third_party/echarts` and `third_party/zrender` are at the tags
  `<echartsVersion>` and `<zrenderVersion>` (no `v` prefix) and equal their `commit` in
  `packages/flutter_echarts_port/tool/port_sources.yaml`. The script reads the gitlinks from the index and the tags with `git ls-remote`. It needs no
  submodule checkout. It also fails on a submodule of `.gitmodules` that no entry of a
  `packages/*/tool/port_sources.yaml` pins.
- `dart run melos run gallery` (Chrome) / `gallery:macos` / `gallery:device` (Android/iOS):
  run the gallery.
- `dart run melos run gallery:build:web` / `gallery:build:android` / `gallery:build:ios`: build the
  gallery the way CI does (web with WebAssembly, debug APK, iOS without code signing).

Before a push, run `format:check`, `analyze`, `test --no-select`, `test:web`, `test:cases`,
`test:fixtures` and `check:port`.

## Layout

- `packages/flutter_chartjs_port`: the Chart.js port (library, `publish_to: none` until 0.1.0).
  Its `analysis_options.yaml` includes the rules of the root file, and its `.pubignore` keeps
  `doc/`, `test/`, `tool/`, `dart_test.yaml` and `build/` out of the published archive (Chart.js
  ADR 0047). The harness and the gallery name it as a path dependency. `README.md` is the README
  of pub.dev. It names a file outside the archive by an absolute GitHub URL (Chart.js ADR 0047).
  `example/main.dart` (port-only, no pubspec, Chart.js ADR 0047 §5) is the example of the archive:
  one `ChartView` with a data update. The workspace formats and analyzes it with the package
  rules. `check:headers` and `check:lib-imports` do not examine `example/`.
  - The public libraries (Chart.js ADR 0048 §5), port-only and not pure layers:
    `lib/flutter_chartjs_port.dart` (the app library: `chartjs.dart` without `Animation` and
    `Element`, the two Flutter names, and `ChartView`, `ChartTheme` and `ChartThemeData`),
    `lib/chartjs.dart` (the `chart.js` entry: `lib/src/types.dart` with a hide list, the Canvas 2D
    interface, `ChartMeta`, `defaultDateZone`, `setDefaultDateZone`, `notifyArrayListeners`,
    `JsClass`, `Undefined`, `undefined` and `lib/src/upstream.dart`) and `lib/helpers.dart` (the
    `chart.js/helpers` entry: `lib/src/helpers/index.dart` without the Dart names of the upstream
    `_` exports). An app imports the app library next to `material.dart` with no prefix.
    `doc/public_api.txt` is the committed list of their export names.
    `test/tool/public_api_test.dart` compares the list, checks that the app library shares no name
    with the Flutter libraries and `dart:ui`, checks the `@internal` rule of Chart.js ADR 0048 §6,
    and checks that the libraries cover the `exports` of `doc/upstream/manifest.json` (the
    allowlist `_notExported` has the reasons). After a change of the public API,
    `PUBLIC_API_UPDATE=1 flutter test test/tool/public_api_test.dart` writes the list again.
    `test/port/public_library_test.dart` imports the app library next to `material.dart`,
    registers the line set and pumps a `ChartView`.
  - `lib/src/`: ported modules at their upstream paths (`controllers/`, `core/`, `elements/`,
    `helpers/`, `platform/`, `plugins/`, `scales/`, `types/`), `kurkle_color/` (the `@kurkle/color`
    0.3.2 port), and `js/`, the JS runtime: port-only `js_*.dart` files and the fdlibm ports
    `fdlibm_log.dart`, `fdlibm_atan.dart` and `fdlibm_trig.dart`. `js_webidl.dart` has the WebIDL
    conversions of the Canvas 2D setters. `js_class.dart` has the JS class values (Chart.js ADR
    0020). `js_date.dart`, `js_map.dart` and `js_promise.dart` have `Date.now()`, the `Map`
    iteration and the promise jobs (Chart.js ADRs 0019 and 0045).
  - `lib/src/core/core.element.dart` and `lib/src/elements/` (Chart.js ADR 0017): the port of
    `core.element.ts`, and the four elements (`element.point.dart`, `element.line.dart`,
    `element.bar.dart`, `element.arc.dart`) with `index.dart`. The port-only `element_options.dart`
    (Chart.js ADR 0018) has the typed element options: `PointOptions`, `LineOptions`, `BarOptions`
    and `ArcOptions`, Maps with a field for each known key. It also has `GenericElementOptions`,
    `clone`, the frozen state, `createElementOptions` and `copyOptions` (Chart.js ADR 0021). These
    files are pure layers. `Element` and each element class have a static `jsClass`, the class as a
    value (Chart.js ADR 0020). `PointElement` and `BarElement` implement `types.VisualElementRange`,
    the interface of `getRange`. `getRange` gives an `Object`: the `PointElement` result is the JS
    `+` of `radius` and `hitRadius` (`jsAdd`), a `String` when an option is a string. The hit tests
    and `size` of `PointElement` and the `rAdjust` and `getCenterPoint` of `ArcElement` also add
    their options with `jsAdd`. `LineElement.updateControlPoints` takes a `ChartArea?`: Dart `null`
    is the JS `undefined` of a chart without a layout. The `points` setter of `LineElement` takes
    `List<types.Element>` and copies a list that is not a `List<types.PointElement>` (Chart.js ADR
    0028). `lib/src/types/index.dart` also has `RadialLinearScale` and `LegendElement` (Chart.js ADR
    0028), and `TooltipModel` (Chart.js ADR 0039 §14). `Chart.tooltip` is a `TooltipModel?` field:
    the tooltip plugin writes it, and `core.controller.dart` does not import the plugin.
    `RadialLinearScale` of `scale.radialLinear.dart` implements `types.RadialLinearScale`. Its
    `xCenter` and `yCenter` are `double?`: Dart `null` is the `undefined` before the first layout
    (Chart.js ADR 0033). The scale reads `xCenter ?? double.nan` in arithmetic, and the radar and
    polar area controllers write it into a new element as `undefined`.
  - `lib/src/core/` also has these files:
    - `core.config.dart` has the theme hunks H0-H3 and the public H0 reader `chartThemeOf` (Chart.js
      ADR 0050) and the `into` parameter of `resolveNamedOptions` (Chart.js ADR 0021).
      `core.adapters.dart` has `DateAdapter` and `DateAdapterBase`. `DateAdapterBase.jsClass` is the
      `_date` of `adapters`. Both files are pure layers.
    - `date_adapter.dart`, `date_calendar.dart`, `date_zone.dart`, `date_parse.dart` and
      `date_format.dart` are the port-only default date adapter (Chart.js ADR 0024), pure layers.
      `DateAdapterBase.prototype` starts with `dateAdapterMembers`, the rules of
      chartjs-adapter-moment 1.0.1 on moment 2.29.4 with ICU patterns. `setDefaultDateZone`
      selects local time (the default) or UTC.
    - `core.interaction.dart` and `core.layouts.dart` are pure layers. `Interaction` is a class with
      the static members `evaluateInteractionItems` and `modes`. `layouts` is a record of `addBox`,
      `removeBox`, `configure` and `update`. A box is a `LayoutItem` of `lib/src/types/layout.dart`.
      `layouts.removeBox` takes a `LayoutItem?` (Dart `null` is the JS `undefined` of a stop hook).
    - `core.animation.dart` and the port-only `animation_spec.dart` (`AnimationSpec`, the typed
      animation config) are pure layers. `core.animations.dart` and `core.animator.dart` are not:
      `core.animator` imports `helpers.extras` (Chart.js ADR 0019). `core.animator.dart` has
      `getAnims`, `update`, the `@internal` class `Anims` and the field `refresh` (Chart.js ADR
      0029 §6). A fixture replaces `refresh` on the singleton (`harness-method-fields`).
    - The port-only `reduced_motion.dart` (a pure layer) has the reduced-motion flag of a canvas,
      an `Expando` (Chart.js ADR 0049 §7). Only `ChartView` sets it, from
      `MediaQuery.maybeDisableAnimationsOf`. `_createAnimations` of `core.animations.dart` reads
      it: with the flag, it reads no animation config (row `platform-reduced-motion`). No spec and
      no reference test sets it.
    - `core.scale.dart` has `Scale`, `Scale.jsClass` and the port-only `Tick` class of the typedef
      at `core.scale.js:15`. `core.scale.dart` and `core.scale.autoskip.dart` are not pure layers:
      `core.scale` imports `helpers.extras`, and `core.scale.autoskip` imports `core.scale`.
      `Scale` implements `MinMax`. Its value methods take `Object?` (Chart.js ADR 0025).
    - `core.datasetController.dart` has `DatasetController`, with the mixin `ArrayListener` and
      the class value `DatasetController.jsClass` (Chart.js ADR 0020). `_update` is `update_`, and
      `_getSharedOptions` is `getSharedOptions_` (Chart.js ADR 0023). `cloneIfNotShared` and
      `getSharedOptions` copy the typed element options with `copyOptions` (Chart.js ADR 0021).
      `ctx` is writable, as the JS property `_ctx` (Chart.js ADR 0030). `updateElement` takes a
      `types.Element`, and `getLabelAndValue` gives `({Object? label, String value})` (Chart.js
      ADR 0028). The reads of parsed items and stack objects use `jsGetKey`, and the index reads
      use `jsGetIndex` and `jsSetIndex`. `stacksOf` (`@internal`) reads `item._stacks` of a
      parsed item, also of a List item, through an `Expando` (Chart.js ADR 0036).
      `_insertElements` keeps the old parsed item at each new index below the old length, as the
      upstream `move` does. `_dataCheck` keeps a string `data` as a `JsStringList`, with no array
      listener (`core.datasetController.js:386`).
      It is not a pure layer: it imports `core.animations`.
    - `core.typedRegistry.dart` (`TypedRegistry`) is a pure layer. `core.registry.dart`
      (`Registry` and the singleton `registry`) and `core.plugins.dart` (`PluginService` and the
      record `PluginDescriptor`) are not pure layers: `core.registry` imports
      `core.datasetController` and `core.scale` (Chart.js ADR 0020).
    - `core.controller.dart` has `Chart`. `resize` and `eventHandler` are fields that hold a
      function (Chart.js ADR 0022). `Chart.register` and `Chart.unregister` take one List.
      `Chart.registry` is a static field (Chart.js ADR 0020). `Chart.jsClass` is the class value
      with the statics of `core.controller.js:105-120` (Chart.js ADR 0048 §2), as are
      `Animation.jsClass`, `Animations.jsClass` and `FlutterPlatform.jsClass`. `toBase64Image`
      returns a `Future<String>` from `HTMLCanvasElement.toDataURL` (row
      `platform-to-base64-image`): each fake canvas of the tests has that member. The dataset meta is the class
      `ChartMeta`. Its `_dataset` is `dataset_` (Chart.js ADR 0023). `getDataVisibility` returns
      `true` at once for an empty `_hiddenIndices`. `toggleDataVisibility` takes any JS value
      (`Object?`) and writes the key `ToString(index)`, as upstream. `ChartMeta.total` is a typed
      field (Chart.js ADR 0028). The axis ids of `ChartMeta` (`xAxisID`, `yAxisID`, `rAxisID`,
      `iAxisID` and `vAxisID`) are `Object?`: `linkScales` keeps the raw id of the dataset, and
      `getScaleForId` reads `chart.scales[ToString(id)]`. `_lastEvent` is `lastEvent` with
      `@internal`: the input reference test reads it after each step. `Chart.legend` is a field that
      the legend plugin writes. It is not a pure layer: it imports the platform layer.
    - `index.dart` has the exports of `src/core/index.ts`. `lib/src/index.dart` is the port of
      `src/index.ts`, with the four namespaces and `registerables`. The namespace `controllers` has
      the eight controllers of phase 7 and the namespace `plugins` has the seven plugins of
      `lib/src/plugins/index.dart`, both in code unit order. Thus `flutter_test_config.dart`
      registers them with the built-in components. `lib/src/index.umd.dart` is the port of
      `src/index.umd.ts` (Chart.js ADR 0048 §1): the lazy `chartUmd`, the value `Chart.jsClass`
      with the UMD statics, which registers the four namespaces at its first read (row
      `platform-umd-entry`). `Chart.platforms.DomPlatform` is `FlutterPlatform.jsClass` (row
      `platform-umd-dom-platform`). No public library exports the file, and no widget imports it.
      The specs read the UMD statics through `chartUmd`. `test/port/index.umd_test.dart` compares
      its keys with `index_umd_reference.dart` of `tool/reference/index_umd_reference.mjs`.
      `lib/src/types.dart` is the port of `src/types.ts`: `lib/src/index.dart` and
      `lib/src/types/index.dart` without the 8 names that both declare (row `adapt-types-entry`).
  - `lib/src/controllers/`: the eight dataset controllers of phase 7. `index.dart` exports them
    (the port of `src/controllers/index.js`). Each controller file has the
    controller class and its class value `<Name>Controller.jsClass` (statics `id`, `defaults`,
    `overrides`; the doughnut also `descriptors`). A controller reads parsed items with
    `jsGetKey`, `jsGetIndex` and `stacksOf`, and a raw option value stays `Object?` until its
    upstream operator (Chart.js ADR 0036). It reads the members of other modules through
    `lib/src/types/` (Chart.js ADR 0028). It casts only to a `types` interface or to a class of
    its own library, at the upstream read. Three other kinds of casts stay: a `List` cast of a
    value that upstream reads as an array, the `String` cast of a parsing key and the `AnyObject`
    cast of an object that the controller made. `getLabelAndValue` gives
    `({Object? label, String value})`. The files are not pure layers: each imports
    `core.datasetController`.
    - `controller.bar.dart`: `getStackCount` and `getStackIndex` are the `_getStackCount` and
      `_getStackIndex` of upstream with `@internal`, because the spec reads them (Chart.js ADR
      0012).
    - `controller.line.dart`: `updateElements` reads each key of a parsed item once in a loop
      pass (`vValue`, `iValue`), and it reads `prevParsed[iAxis]` at each pass, because the
      scriptable options of the user run between two passes (the 3-read form of Chart.js ADR
      0036). `update` writes `_chart`, `_datasetIndex`, `_decimated` and `points` into the line
      by name (`types.PropertyAccess`), and `draw` casts the line to `types.LineElement`.
    - `controller.bubble.dart`: the parsed radius goes to `_custom`. `resolveDataElementOptions`
      copies the options with `copyOptions(values)..[r'$shared'] = false` (Chart.js ADR 0021 §3)
      and adds the radius with `jsAdd`: a string radius joins, as upstream. `getMaxOverflow`
      casts each data element to `types.PointElement` at `size`.
    - `controller.doughnut.dart`: `overrides` holds the tear-offs of the private top-level legend
      functions `_generateLabels` and `_onClick` (Chart.js ADR 0028 §6). `_onClick` gives the
      raw index of the legend item to `toggleDataVisibility`. `parse` reads a List or a string
      `data`. `controller.pie.dart` imports this file.
    - `controller.pie.dart`: `PieController extends DoughnutController` with the statics `id` and
      `defaults`. `PieController.jsClass` extends `DoughnutController.jsClass` and has its own
      `construct`. It reads `descriptors` and `overrides` through the superclass chain: the
      legend functions of `overrides['pie']` are the doughnut tear-offs (Chart.js ADR 0028 §6).
      Dart has no `PieController.overrides`: read `PieController.jsClass['overrides']`.
    - `controller.polarArea.dart`: it casts the scale `r` to `types.RadialLinearScale` once
      (`controller.polarArea.js:166`), and it ports the #12238 hunk with `== 0` and
      `== 'angular'`. `overrides` holds the legend functions as tear-offs of top-level functions.
      `parseObjectData` calls `parseObjectDataRadialScale` with `jsCall` and the controller as
      `thisArg`.
    - `controller.radar.dart`: the write `line.points = points` is a write by name through
      `types.PropertyAccess`. The cast to `types.RadialLinearScale` stands in the loop of
      `updateElements`, at `controller.radar.js:88`. The label of `getLabelAndValue` is the raw
      label.
    - `controller.scatter.dart`: it imports `core.registry.dart`: `this.chart.registry` is the
      singleton `registry` (row `adapt-chart-registry-getter`). Its `updateElements` keeps the
      parsed values only inside one pass (the 3-read form, as the line). `delete meta.dataset` is
      `meta.dataset = null`. It has no `draw` override, as upstream.
  - `lib/src/plugins/` (Chart.js ADRs 0038-0041 and 0050): the seven plugins of phase 8.
    `index.dart` (the port of `src/plugins/index.js`) exports the plugin objects `colors`,
    `decimation`, `filler`, `legend`, `subTitle`, `title` and `tooltip`, with the export names in
    lowerCamelCase. Each plugin object is a mutable Map with the upstream keys in the upstream
    order, and its hooks take the upstream parameter counts (Chart.js ADR 0038). The library exports
    no class `Title`, `Legend` or `Tooltip`. `plugin.decimation.dart` and the files of
    `plugin.filler/` are pure layers. The other plugin files are not: `plugin.title`,
    `plugin.legend` and `plugin.subtitle` reach `helpers.extras`, `plugin.tooltip` imports
    `core.animations`, and `plugin.colors` imports the controllers.
    - `plugin.colors.dart`: the plugin `colors` with the theme hunks H4a-H4c and H5 (Chart.js ADR
      0050). H5 reads the palette from the theme map of the chart through `chartThemeOf` of
      `core.config.dart`. The doughnut and polar area colorizers throw a `TypeError` for a `data`
      that is not a List. The colorizers write into the dataset Map of the user: a Map with a narrow
      value type or an unmodifiable Map throws (differences.md row `js-semantics-narrow-datasets`).
    - `plugin.decimation.dart`: the plugin object `decimation`. The `data` accessor of
      `plugin.decimation.js:249-265` is a plain entry with the getter value, an `Expando` with the
      last value that the plugin wrote, and a sync before each use (Chart.js ADR 0038 §8, row
      `adapt-decimation-data-accessor`). `lttbDecimation` and `minMaxDecimation` are `@internal`:
      the pure test `test/port/plugins/plugin.decimation_algorithms_test.dart` calls them. They read
      the data items with the JS operators (`jsAdd`, `jsToNumber`, `jsToInt32`, `jsLessThan`). Data
      that is not a List throws a `TypeError` (row `js-semantics-decimation-data`).
    - `plugin.filler/`: the 8 files of `src/plugins/plugin.filler/` (Chart.js ADR 0040).
      `index.dart` has the plugin Map `filler` and the source class `FillerSource`; `meta.$filler`
      is an extra property of the meta, read by name. The filler wraps each plain point of upstream
      in a `PointElement` with only the properties of the plain object (row
      `adapt-line-points-elements`): the boundary points, the radial polygon, the edge objects of
      `segments` and the results of `interpolate` in the stack line (`stackResultPoint`; an Array
      gives a bare point). `filler.drawing.dart` dispatches on `types.LineElement` and
      `types.SimpleArc` (row `adapt-filler-target-classes`). `SimpleArc` of `simpleArc.dart` does
      not implement `types.LineElement`. `PointElement` stays the only implementer of the point
      interfaces in `lib/` (`test/port/plugins/plugin.filler/point_implementers_test.dart`).
    - `plugin.legend.dart`: `Legend` (extends `Element`, implements `types.LegendElement`,
      `LayoutItem` and `TRBL`) with `Legend.jsClass`, and the plugin Map `legend`. The items, the
      hit boxes (`legendHitBoxes`, also a port-only member of `types.LegendElement`, which the
      keyboard of `ChartView` reads, Chart.js ADR 0051 §2) and the column sizes are Maps with the
      upstream keys. The label options `boxWidth`,
      `boxHeight`, `pointStyleWidth` and `padding` are numbers (row `adapt-legend-number-options`).
      The default `onClick` gives the number of the property key of the raw `datasetIndex` to `hide`
      and `show` (row `adapt-legend-dataset-index`).
    - `plugin.subtitle.dart` has the plugin Map `subTitle` (no `_element`). Its box is a `Title` of
      `plugin.title.dart`, and the `WeakMap` of upstream is a file-private `Expando<Title>`
      (Chart.js ADR 0038 §5).
    - `plugin.title.dart` has `Title` (`extends Element implements LayoutItem`, the class value
      `Title.jsClass` with the superclass `Element.jsClass`) and the plugin Map `title`. The box
      fields start as NaN, `undefined` and `false`. `draw` takes an optional chart area.
      `chart.titleBlock` is a field of `types.Chart`: Dart `null` is the JS `undefined` (Chart.js
      ADR 0038).
    - `plugin.tooltip.dart` has `Tooltip extends Element implements types.TooltipModel`, the
      positioners Map (`Tooltip.positioners`, the static of `Tooltip.jsClass` and the plugin key
      `positioners` are one Map), the default callbacks and the plugin Map `tooltip` (Chart.js ADR
      0039). The access by name covers its 28 own names and `_ignoreReplayEvents`: `operator []`
      and `operator []=` handle the 24 names that `Element` does not handle. `update` is a field
      that holds a function (row `harness-method-fields`). The hooks cast `chart.tooltip` to
      `Tooltip`.
  - `lib/src/scales/`: the six scales of `scales/index.dart` and `scale.linearbase.dart`
    (`LinearScaleBase`: not exported, not registered). They are not pure layers: each imports
    `core.scale`. The value methods take any JS value (`Object?`). The category, linear and
    logarithmic `getPixelForValue` and the time `getDecimalForValue` have a port-only
    `value is double` fast path (Chart.js ADR 0025). The `_` members that another file or a spec
    reads drop the underscore: `startValue`, `endValue`, `valueRange`, `offsets`, `generate`,
    `unit`, `adapter`, `pointLabels`, `pointLabelItems`. The time scales read each date through
    `adapters._date` (Chart.js ADR 0024).
  - `lib/src/canvas/`: the port-only canvas layer (Chart.js ADRs 0013 and 0015). `canvas.dart` is
    the Canvas 2D interface, a pure layer. `canvas_ui.dart` and its four parts
    (`canvas_ui_path.dart`, `canvas_ui_paint.dart`, `canvas_ui_text.dart` and
    `canvas_ui_batch.dart`, the circle batch) are the `dart:ui` implementation. No helper imports
    them. `canvas_ui.dart` reflects the `style` attribute of the canvas. Other attributes keep their
    values as strings (Chart.js ADR 0022).
  - `lib/src/platform/` (Chart.js ADR 0037): the ports of `index.js`, `platform.base.js` and
    `platform.basic.js`, and three port-only files. `platform.flutter.dart` replaces
    `platform.dom.js`. `chart_host.dart` is the internal chart host (`ChartHost`,
    `RenderChartHost`). A touch tap gives the compatibility mouse events. A tap outside gives
    `mouseout` to the chart of the last tap (Chart.js ADR 0037). A resize observer gets its first
    notification at the next layout of the host. `flushCanvasMutations` is the mutation checkpoint of the harness (Chart.js ADR 0022).
    `onFirstLayout` is the start hook of the owner of the canvas: `ChartView` starts its chart in
    it (Chart.js ADR 0049 §2). The keyboard of `ChartView` sends its events through
    `dispatchCanvasEvent` (`canvas.dispatchEvent`).
    `native_event.dart` is the stand-in for the DOM event, a pure layer.
  - `lib/src/theme/` (Chart.js ADR 0050, port-only): `compile.dart` has `compileChartTheme` over
    raw Map themes, the emission guard and the deep freeze. `presets.dart` has the internal
    `ChartThemes.light` and `ChartThemes.none`. Both files are pure layers. `theme_data.dart` has
    the public `ChartThemeData` (Chart.js ADR 0050): 6 `Color?` tokens, 2 `TextStyle?` fonts,
    `palette` and `paletteBackgroundAlpha`, the presets `.light()` and `.dark()` (the mirror rule),
    `copyWith`, `lerp` and deep `==`, and the internal `themeDataToRaw` and `compileThemeData`
    (the compiled map of each instance, in an `Expando`). `chart_theme.dart` has `ChartTheme`, an
    `InheritedTheme` with a non-null `data` (`maybeOf` for charts, `of` with the light fallback).
    Both import Flutter: they are not pure layers. Ported files never import a file of
    `lib/src/theme/`. `test/port/theme/coverage_test.dart` (theming.md §8 test 4) compares
    `light_snapshot.json` with the defaults inventory of `doc/upstream/manifest.json`.
    `THEME_SNAPSHOT_UPDATE=1` writes the snapshot again. `theme_data_test.dart` and
    `chart_theme_test.dart` have test 7. `light_pixels_test.dart` checks that the light preset
    paints the bytes of an unthemed chart (16 cases, also on the `test` job of each OS), and
    `blue_screen_test.dart` also has 16 cases with an active element. `goldens_test.dart` (test 9,
    the tag `golden`, `test:goldens`) compares `test/port/theme/goldens/bar_light.png` and
    `bar_dark.png`.
  - `lib/src/widgets/` (Chart.js ADRs 0049-0051, port-only, not pure layers). No file of it
    imports a component or an index of the components (`check:lib-imports`), and no file writes
    `defaults` or `overrides`.
    - `chart_view.dart` has `ChartView`. It keeps one `UiCanvasElement` for the life of its state
      and starts the chart in `ChartHost.onFirstLayout`. The chart gets a root Map: a shallow copy
      of the app config, with `$theme` and the widget plugin. A new config, a new theme and a
      change of the reduced-motion preference reach the chart in one post-frame callback (Chart.js
      ADR 0049 §4). `build` sets the reduced-motion flag from
      `MediaQuery.maybeDisableAnimationsOf`. A chart under `TickerMode(enabled: false)` is muted.
      `dispose` destroys the chart and disposes the context. A `Focus` and a `Semantics` node
      (`container`, `image`, `semanticLabel`) wrap the host (Chart.js ADR 0051 §1 and §8).
    - `chart_theme_switch.dart` has `ChartThemeSwitch`, the runtime theme switch (theming.md §3.7):
      the entry `$theme`, the in-place restore of the user `scales` and of the palette keys, and
      one update with `'theme'`, `'themeFrame'` or `'default'`.
    - `chart_view_plugin.dart` has the inline plugin `$chartView`, last in the `plugins` List of
      the root Map: the palette records of the switch and the focus ring.
      `plugins.$chartView: false` turns it off.
    - `chart_keyboard.dart` has `ChartKeyboard` (Chart.js ADR 0051): the keys move a virtual mouse
      over the legend hit boxes (through `types.LegendElement`) and the data elements, and send
      `mousemove`, `mousedown`, `mouseup`, `click` and `mouseout` `NativeEvent`s to the canvas.
    - `test/port/widgets/` (VM only): `chart_view_test.dart` (the start, the life cycle and the
      keys, the diagnostics, the update, the size, the callbacks and reduced motion),
      `chart_view_unregistered_test.dart` (it calls `removeBuiltins()` first in `main()`),
      `chart_theme_switch_test.dart` (theming.md §8 test 8), `chart_keyboard_test.dart` and
      `chart_view_semantics_test.dart` (Chart.js ADR 0051). A test that pumps a `ChartView` gives
      it a config that is not `const`: Chart.js writes into its `data` and `options`.
  - `test/flutter_test_config.dart`: the port of `test/index.js`. `flutter test` runs it around
    each test file of the package ([Tests](#tests)).
  - `test/specs/`: ported upstream specs. `test/kurkle_color/`: the ported `@kurkle/color` tests.
    `test/port/`: port-only tests, at the path of the `lib/src/` file that they test.
    `test/port/scales/scale_chart_harness.dart` and `scale_time_harness.dart` are helper libraries
    of the scale tests, not test files. `test/port/controllers/` has the controller reference tests
    and their harness `controller_chart_harness.dart` (a library). `controller.<name>_test.dart`
    compares the charts of `tool/reference/controller_<snake>_reference.mjs` (data
    `controller_<snake>_reference.dart`; `<snake>` is `polar_area` for `polarArea`): the eight
    controllers. Pie has no spec file. `test/port/plugins/` has the plugin reference tests and their
    harness `plugin_chart_harness.dart` (a library). `plugin.<id>_test.dart` compares the charts of
    `tool/reference/plugin_<id>_reference.mjs`. The filler tests are in
    `test/port/plugins/plugin.filler/`. `test/port/plugins/index_test.dart` compares the hook
    dispatch of the seven plugins with `plugin_dispatch_reference.dart`.
    `test/port/canvas/path2d_record.dart` (the record form of `Path2D` arguments) and
    `test/support/jasmine.dart` (the Jasmine matchers and spies of the spec ports) are pure helper
    libraries. `test/tool/`: tests of the port tools.
  - `test/fixtures/` (Chart.js ADR 0029): `index.dart` is the registry of the fixture runner, not a
    test file. It has `specs` (`jasmine.fixture.specs` of `test/index.js:15-17`), `handFixtures`
    (147 hand ports, each with the first 12 hex digits of its manifest `sha256`) and `fixtureSkips`
    (39 skips, all `diverges: adapt-date-moment-format`). `hand/<path>.dart` is the hand port of the
    impure config `test/fixtures/<path>.js` of the pin, with the function `fixture()`.
    `test/port/fixtures/index_test.dart` checks the registry against the manifest, the files of
    `hand/` and `doc/differences.md`. `test/port/fixtures/moment_twins_test.dart` has the 36 ICU
    twins of the moment fixtures (row `adapt-date-moment-format`, Chart.js ADR 0029 §9 item 4). Each
    twin is a hand entry of `specsFromFixtures`, so it has the SHA-256 check and the skip of the
    runner. Its `run` hook compares the parsed time values and the time scales with the date strings
    of its config. `_differs` and `_unparsed` name `controller.bar/bar-thickness-no-overlap.json`
    (the moment forgiving parse). Its untagged group `twins` compares the list with `fixtureSkips`.
    The `dart_test.yaml` of the package declares the tags `fixtures` and `golden` (the theme
    goldens of Chart.js ADR 0050). The `dart_test.yaml` of `packages/chartjs_test_utils` declares
    the tag `fixtures`.
  - `tool/`: the port checks (`check_*.dart`), tool 5 (`spec_cases.dart`, also tool 7 with
    `--fixtures`), tool 6 (`parity.dart`), tool 8 (`port_order.dart`), shared code in `tool/src/`,
    `port_sources.yaml` (one entry for each project that the package ports code from, with its pin;
    the Chart.js entry maps `test/fixtures/` to `packages/flutter_chartjs_port/test/fixtures/hand/`),
    `upstream_manifest/` (tool 4, Node.js) and `reference/` (the Node.js generators of reference
    data).
  - `doc/`: all Chart.js port docs: roadmap, parity tracker, design docs, Chart.js-only decisions
    (`doc/adr/`, numbered from 0001) and the Chart.js prior-art survey (`doc/prior-art/`).
    - `doc/adr/`: Chart.js ADRs 0001-0051. Fourteen of them are superseded: Chart.js ADR 0010
      supersedes Chart.js ADR 0002, Chart.js ADR 0011 supersedes Chart.js ADR 0005, Chart.js ADR
      0012 supersedes Chart.js ADR 0004, and Chart.js ADR 0026 supersedes Chart.js ADR 0008.
      Chart.js ADR 0016 supersedes Chart.js ADR 0007, and Chart.js ADR 0033 supersedes Chart.js ADR
      0025 §5 for `xCenter` and `yCenter` (2026-10-21). Chart.js ADR 0032 (JS numeric semantics)
      supersedes Chart.js ADR 0010. Chart.js ADR 0034 (no display-only JS exactness) supersedes
      Chart.js ADR 0009. Chart.js ADR 0035 (third-party sources) supersedes Chart.js ADR 0011.
      Chart.js ADR 0036 states the complete decision of Chart.js ADR 0027 (parsed data) with the
      V8 zone name of `jsToString` and the cast of each parsing key inside the loop of
      `parseObjectData`, and supersedes it. Chart.js ADR 0042 (theming) states the complete
      decision of Chart.js ADR 0001 with the palette of the theme map, and supersedes it. Chart.js
      ADR 0043 (options representation and resolver) states the complete decision of Chart.js ADR
      0006 with `helpers.merge` into an element target, and supersedes it. Chart.js ADR 0037
      supersedes Chart.js ADR 0014 (2026-10-29). Chart.js ADR 0045 (the reference engine on arm64)
      states the complete decision of Chart.js ADR 0032 with the arm64 engine, and supersedes it
      (2026-10-29). Chart.js ADR 0050 (the public theme API) states the complete decision of
      Chart.js ADR 0042 with the public classes, the presets, the theme switch and the touch sizes,
      and supersedes it (2026-10-30). The porting lead accepted Chart.js ADRs 0032, 0034, 0035 and
      0036 on 2026-10-21, Chart.js ADRs 0038-0043 on 2026-10-23, Chart.js ADRs 0037, 0045 and 0046
      on 2026-10-29, and Chart.js ADRs 0048, 0049 and 0050 on 2026-10-30. Chart.js ADR 0037 waited
      for the device check of step 8. Docs and code cite them for the current rules. The porting
      lead (the agent that runs the phase) owns the ADR statuses (the maintainer, 2026-10-21). It
      accepts an ADR when the decision is implemented and its gates are green. A changed decision
      still gets a new ADR that supersedes the old one. Chart.js ADR 0044 (the stack fill search)
      is rejected: its code A/B rejected the change, and Chart.js ADR 0046 records the result.
      Chart.js ADRs 0047 (the published archive) and 0051 (input events and interaction state) are
      proposed. Chart.js ADR 0047 waits for the publish dry run of the release, and Chart.js ADR
      0051 for the night series B-N1. The other ADRs are accepted. Docs name them "Chart.js ADR
      NNNN". "ADR NNNN" alone is a `docs/adr/` file. "D3 ADR NNNN" is a file of
      `packages/flutter_d3_port/doc/adr/`. "ECharts ADR NNNN" is a file of
      `packages/flutter_echarts_port/doc/adr/`. An accepted ADR does not change. A changed decision
      gets a new ADR that states the complete decision and supersedes the old ADR.
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
  (`publish_to: none`, a dev_dependency of `flutter_chartjs_port`). The ported files are in `lib/src/`.
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
    `pumpFrames`, `pumpFrame`, `waitForDone`, `frameInterval`, `specTimeout`, and the extensions
    `CanvasParentElement` and `CssProperties`. Only one `pumpFrames` loop pumps at a time: a loop
    that starts while another loop pumps awaits each step of that loop. It also exports the fixture
    runner of `lib/src/fixture.dart`.
  - `lib/src/fixture.dart` ports `src/fixture.js` (Chart.js ADR 0029): `specsFromFixtures`,
    `specFromFixture` and `FixtureSource` (the manifest and `fixtures.json` of tool 4, the folder
    `upstream` of the upstream fixture files and `requireUpstream`). Each fixture test has the tag
    `fixtures`. The rows are `harness-fixture-sources` and `harness-fixture-frame`. It is not a
    pure layer. `test/fixture_test.dart` runs the probe `test/fixture_probe/probe_fixture.dart` in
    a nested `flutter test --tags fixtures` with `FIXTURES_REQUIRED=1` and `FIXTURE_PROBE_CRLF` (a
    temporary folder with a CRLF copy). The folder `test/fixture_probe/upstream/` stands for the
    upstream fixture files.
  - `lib/src/utils.dart` ports `src/utils.js`: `acquireChart` and `releaseChart` (the ports of
    `_acquireChart` and `_releaseChart`), `waitForResize`, `afterEvent`, `_resolveElementPoint` and
    `triggerMouseEvent`. `lib/src/index.dart` ports `src/index.js`: `acquireChart`, `releaseChart`,
    `releaseCharts` and the registry `charts`. It imports `utils.dart` with the prefix `utils`
    (Chart.js ADR 0012, Collisions). Neither file is a pure layer.
  - `lib/fonts/`: the test font, Liberation Sans 2.1.5 (SIL OFL 1.1), with its `LICENSE`
    (Chart.js ADR 0015).
- `apps/chartjs_gallery`: gallery app (Android, iOS, web, macOS); every Chart.js chart type
  (Chart.js ADR 0031). Each chart of the gallery runs a ported controller. No gallery class
  extends `DatasetController`.
  - The home list (`lib/main.dart`) has the nine entries of `galleryChartTypes`
    (`lib/charts/chart_types.dart`), in the order of the docs. Each tile is enabled and opens
    `ChartTypePage` (`lib/charts/chart_type_page.dart`). The variants of a page are the configs of
    the 11 `chart-editor` blocks of `docs/charts/*.md` in `lib/docs/charts/` and of the Area sample
    `lib/docs/samples/area/line_boundaries.dart`. These files have rule-2 headers. Each tile has
    the icon `check_circle_outline` and its docs source as the subtitle, and no entry has a note.
    The gallery registers `registerables` with the seven plugins, as the docs do: each chart shows
    the legend and the tooltip with their defaults, the filler fills the Radar chart and the Area
    variants `origin`, `start` and `end`, and no page prints the `fill` warning. The Area page has
    the four fill actions of `docs/samples/area/line-boundaries.md:39-74` as its variants:
    `origin` (the first), `start`, `end` and `false` (Chart.js ADR 0031, Open "The Area `fill`
    control").
  - A type page has at most one control line (the variant), then the chart, the readout (the
    datasets, and the hover text of `getLabelAndValue`) and the help text. The help text gives the
    docs source and the input: a hover or a tap on an element shows the tooltip, a tap outside the
    chart hides it, and a tap on a legend item hides or shows its data. Its last line gives the
    keys of Chart.js ADR 0051. The chart is a `ChartView` with the config that the page makes once
    for each variant, and `onChartCreated` gives the chart to the page. The chart has the semantics
    label `<title> chart: <variant>`. The app follows the platform brightness: its builder puts a `ChartTheme` above each route, with the
    light preset or the dark preset over the surface of the dark color scheme (Chart.js ADR 0050).
    The host has no height: the platform gives the aspect of the docs (2, or 1 for doughnut, pie,
    polar area and radar). The page body caps its width at 600. The keys are
    `gallery.type.<stem>`, `type.<stem>.variant.<variant>`, `type.<stem>.host`,
    `type.<stem>.readout` and `type.<stem>.help`.
  - `lib/demo/gallery_components.dart` has `registerGalleryComponents` (it registers
    `registerables` once) and `unitScales` (the two hidden unit scales).
  - The page "Phase 3: canvas and host" has the tabs Canvas, Events, Text, Stress, Elements, Core
    and Axes. The Core tab (`lib/demo/core_demo.dart`) runs a `LineController` chart on the hidden
    scales of `unitScales()`. Its controls are above the chart: `mode`, `axis`, one line of toggles
    and commands, `hover` and `update`. The Axes tab (`lib/demo/axes_demo.dart`) runs a
    `LineController` chart on the scales of phase 6. `x`, `y` and `N` are above the chart, and the
    other parameters are after the readout (Chart.js ADR 0031 §10.7, Open). The plugins of
    `registerables` run with their defaults in both tabs: the legend and the tooltip show. A legend
    click in the Core tab also updates the dataset segments: the inline plugin of the tab gets each
    event in its `afterEvent` hook. Each tab shows its chart in a `ChartView` in a `SizedBox` of
    the height, with `maintainAspectRatio: false`. The keys `core.host` and `axes.host` are on the
    box.
  - The gallery imports the app library `package:flutter_chartjs_port/flutter_chartjs_port.dart`,
    and `helpers.dart` with a `show` list. A file of `lib/` with an import of
    `package:flutter_chartjs_port/src/` has `// ignore_for_file: implementation_imports` after the
    line `// The reason of each import of lib/src is the comment above it.`, and one reason line
    above each such import. A test file has only the reason lines: the lint reports only `lib/`.
    `lib/demo/demo_common.dart` has `jsNumberText`, the JS text of a number for the readouts.
  - `lib/demo/chart_canvas.dart` hosts a real chart for the stress host `HOST=canvas` (the side A
    of the night series A-N1 of Chart.js ADR 0049) and for `_StressChart`, a chart class that
    times its own draws. It connects `ChartHost.onTickerModeChanged` to `animator.mute` and
    `animator.unmute`. It goes after the night record.
  - The modes `chart` and `axes` of the Stress tab measure the real chart path. The mode `chart`
    takes the chart type (the define `TYPE`, 8 types, the `type` line of icon segments). Line and
    scatter draw the points of phase 5 on two hidden unit scales. `axes` adds real scales
    (`lib/demo/stress_axes.dart`) to a `LineController` chart. The stress and benchmark configs
    disable the legend plugin (`plugins.legend: false`, `stressPluginOptions` of
    `lib/demo/stress_chart_config.dart`, Chart.js ADR 0031 Open). The other plugins run; the filler
    fills the radar of the mode `chart`. `lib/demo/stress_timing.dart` has `StressChartTiming`, with
    the parts `elements`, `layout`, `datasetsUpdate` and `datasetsDraw`. `lib/main_stress.dart` is
    the profiling entry. In the modes `chart`, `axes` and `plugins`, its define `HOST` selects the
    host: `canvas` (`ChartCanvas`, the default) or `view` (`ChartView`). `BATCHES` (15) splits the
    timed window into batches, and each `STRESS` line has the key `host` and the batch figures
    `buildP50Ms`, `buildP90Ms`, `rasterP50Ms` and `rasterP90Ms`. Its defines `SEMANTICS` and
    `WINDOWS` serve the night series B-N1 of
    phase 9: `SEMANTICS=1` turns the semantics on, and `WINDOWS=1` prints a line
    `STRESS_WINDOW {json}` for each window of 1 second. With `SEMANTICS` (0 or 1), the toolbar and
    the readout of `StressDemo` are out of the semantics tree (`chartSemanticsOnly`), so that B-N1
    measures the chart node. `lib/main_bench.dart` with
    `lib/bench/chart_bench.dart` is the frameless benchmark of the same cases
    (`packages/flutter_chartjs_port/doc/performance.md` §6). Its mode `motion` (`motion.line` and
    `motion.bar`) times an animated `update`, and its mode `theme` (`theme.switch`, `theme.anim`
    and `theme.equal`) runs the internal theme switch of `ChartView`.
  - The layout rule (Chart.js ADR 0031 §10) applies to the nine type pages and to the Stress,
    Core and Axes tabs: each parameter is a full-width `SegmentChoice` or
    `SegmentToggles` line of `lib/demo/demo_controls.dart`, with short text or icons. A
    `SegmentChoice` item with an `icon` shows the icon only, else its short text. No chip, slider,
    popup menu, dropdown or horizontal scroll. The chart host is fully in view after the first frame
    at 412 x 915. The type pages are also in view at 360 x 640. A widget test pins each page.
    `test/chart_types_test.dart` also pins, on each variant of each type page at 412 x 915, the
    input of Chart.js ADR 0037 §15: a tap on an element shows the tooltip and the readout, a tap on
    the help text hides them, and two taps on legend item 0 hide and show its data. On each variant
    it also pins the keys of Chart.js ADR 0051: Tab focuses the chart, Down and Down show the
    tooltip and the readout of element 0 of dataset 0, Escape hides them, and Down and Enter hide
    the data of legend item 0. It pins the help text and the semantics label of each variant, the
    keys of the host, the readout, the help text and each variant segment, and the title and the
    filler source of each Area variant.
  - Each control has a `ValueKey`. A test finds a segment by its key.
- `packages/flutter_d3_port`: the D3 port (library, `publish_to: none` until 0.1.0, ISC). Phase 0
  has no ported code. `doc/README.md` has the plan and the roadmap.
  - `lib/flutter_d3_port.dart`: the public library. `lib/src/upstream.dart` has `d3Version`
    (`7.9.0`). Both files are port-only.
  - `test/upstream_test.dart` (`@TestOn('vm')`) compares `d3Version` with
    `third_party/d3/package.json`. It also compares each D3 gitlink with its `commit`. It fails
    on a submodule of `.gitmodules` that no entry of the two `tool/port_sources.yaml` files pins.
  - `tool/port_sources.yaml`: the 34 pins in the schema of the Chart.js file (D3 ADR 0001). Each
    entry gives the tag, the commit, the license and the holder of one repository.
  - Paths (D3 ADR 0002): `third_party/<repo>/src/<path>.js` becomes `lib/src/<repo>/<path>.dart`.
    `<repo>` keeps its hyphens. A spec `<repo>/test/<path>-test.js` becomes
    `test/specs/<repo>/<path>_test.dart`. Port-only tests go in `test/port/<repo>/`.
  - `doc/`: all D3 port docs: `README.md` (overview, roadmap, decisions), `porting-flow.md`
    (proposed), `parity.md`, `differences.md`, `upstream-ledger.md` (one section for each
    repository) and the prior-art survey `prior-art/`.
    - `doc/adr/`: D3 ADRs 0001-0006, all proposed. D3 ADR 0001 (upstream sources) has gate 0.
      D3 ADRs 0002 (file naming and layout), 0003 (number to string), 0004 (spec harness) and
      0006 (generators, accessors and JS values) have gate 1. D3 ADR 0005 (path context) has
      gate 1 for the pure interface and gate 4 for the `dart:ui` builder.
  - `check:port`, `test:web`, `test:cases`, `parity` and `port:next` do not examine the package
    yet. `test --no-select` runs its tests. In D3 phase 1, ADR 0008 adds the package to tools 1-3.
- `packages/flutter_echarts_port`: the Apache ECharts port (library, `publish_to: none` until
  0.1.0, Apache-2.0). Phase 0 has no ported code. `doc/README.md` has the plan and the roadmap of
  phases 0-10.
  - `lib/flutter_echarts_port.dart`: the public library. `lib/src/upstream.dart` has
    `echartsVersion` and `zrenderVersion` (both `6.1.0`). Both files are port-only.
  - `test/upstream_test.dart` (`@TestOn('vm')`) compares `echartsVersion` with
    `third_party/echarts/package.json`, and `zrenderVersion` with the zrender dependency of that
    file and with `third_party/zrender/package.json`. It also compares each gitlink with its
    `commit`. It fails on a submodule of `.gitmodules` that no `packages/*/tool/port_sources.yaml`
    pins. The D3 test reads the same files.
  - `tool/port_sources.yaml`: the two pins, Apache ECharts and zrender, in the schema of the
    Chart.js file (ECharts ADR 0001). The `language` of both is `js`.
  - Paths (ECharts ADR 0002): `third_party/echarts/src/<path>.ts` becomes
    `lib/src/echarts/<path>.dart`, and `third_party/zrender/src/<path>.ts` becomes
    `lib/src/zrender/<path>.dart`. A spec `test/ut/spec/<path>.test.ts` becomes
    `test/specs/echarts/<path>_test.dart` or `test/specs/zrender/<path>_test.dart`. Port-only
    tests go in `test/port/echarts/` and `test/port/zrender/`. The harness is in `test/support/`.
    The name `echarts_test_utils` is reserved. `apps/echarts_gallery` comes in ECharts phase 6.
  - `NOTICE`: the port line and the unchanged notice of Apache ECharts (Apache-2.0 section 4(d)).
  - `doc/`: all ECharts port docs: `README.md` (overview, roadmap, decisions), `porting-flow.md`
    (proposed), `parity.md`, `differences.md`, `upstream-ledger.md` (one section for each
    repository) and the prior-art survey `prior-art/`.
    - `doc/adr/`: ECharts ADRs 0001-0009, all proposed. ECharts ADR 0001 (upstream sources) has
      gate 0. ECharts ADRs 0002 (file naming and layout), 0003 (numbers and JS semantics), 0004
      (JS values, classes and options) and 0005 (spec harness and reference tests) have gate 1.
      ECharts ADR 0006 (renderer and canvas layer) has gate 3. ECharts ADR 0007 (environment,
      host and input events) has gates 1, 3 and 5. ECharts ADR 0008 (dates, locales and
      formatting) has gate 4. ECharts ADR 0009 (DOM-bound features, app hooks and theming) has
      gate 6 and later gates.
  - `check:port`, `test:web`, `test:cases`, `parity` and `port:next` do not examine the package
    yet. `test --no-select` runs its tests.
- `third_party/`: reference sources only: never imported, built or shipped. Excluded from
  analysis.
  - Shallow git submodules: `Chart.js` at the tag `v4.6.1`
    (`packages/flutter_chartjs_port/doc/upstream-tracking.md` §2.4), and `kurkle-color` (`v0.3.2`) and
    `chartjs-test-utils` (`v0.4.0`) at release tags. The last two come from Chart.js ADR 0035.
  - The 34 D3 submodules, also shallow at release tags (D3 ADR 0001): `d3` (`v7.9.0`), the 30
    `d3-*` modules, `internmap`, `delaunator` (`v5.1.0`) and `robust-predicates` (`v3.0.3`).
    `packages/flutter_d3_port/tool/port_sources.yaml` gives the tag and the commit of each.
  - The 2 ECharts submodules, also shallow at release tags (ECharts ADR 0001): `echarts`
    (`6.1.0`) and `zrender` (`6.1.0`, the exact version that the ECharts `package.json` requires).
    The tags have no `v` prefix. `packages/flutter_echarts_port/tool/port_sources.yaml` gives the
    tag and the commit of each.
  - `fdlibm/`: unchanged netlib fdlibm 5.3 files (`e_log.c`, `e_log10.c`, `e_atan2.c`, `s_atan.c`,
    `s_sin.c`, `s_cos.c`, `k_sin.c`, `k_cos.c`, `e_rem_pio2.c`, `k_rem_pio2.c`, `s_scalbn.c`) for
    `fdlibm_log.dart`, `fdlibm_atan.dart` and `fdlibm_trig.dart`. fdlibm has no git repository.
    Thus these files are a committed copy. `REUSE.toml` annotates them.
- `tool/`: repository scripts (`check_upstream_pin.sh`).
- `docs/`: docs for all ports only. `docs/adr/`: decisions for all ports. `docs/prior-art/`: prior
  art for future ports. Docs for one port go in the `doc/` folder of its package.
  - ADR 0007 (package names) is accepted (2026-10-22). It supersedes ADR 0003. ADR 0008 (shared
    JS runtime and port tools) is proposed. The gate of ADR 0008 is D3 phase 1.

## Porting rules

1. **Port from the pinned source.** Read the upstream file in `third_party/Chart.js` (check it out
   first). Never port from memory, from upstream `master`, or from other Dart chart libraries.
2. **Mirror upstream structure.** Same module split and names (Dart-cased), so upstream releases can
   be diffed and replayed. Each ported file starts with a header naming its source, license and
   holder, `// Ported from <project> <version> <path> (<SPDX license>, <copyright holder>).`, e.g.
   `// Ported from Chart.js v4.6.1 src/helpers/helpers.math.ts (MIT, Chart.js Contributors).`
   Under a commit pin, the version is `v<last version>+<sha8>`. A file with no upstream source
   starts with the port-only marker `// Original code, not ported from Chart.js: <reason>.`
   instead. All files under `test/port/` and `tool/` are port-only. `check:headers` enforces
   line 1.
3. **Port the specs.** Upstream `test/specs/<module>.tests.js` becomes a test file in `test/specs/`
   (see below). Behaviour without an upstream spec still needs tests.
4. **Track parity.** Update the status text of the module in
   `packages/flutter_chartjs_port/doc/status.yaml` in the same change. Then run
   `dart run melos run parity`. Tool 6 writes `doc/parity.md`. Do not edit it by hand.
5. **No JavaScript at runtime.** No WebView, no JS engine, no `dart:js_interop` in library code
   (ADR 0001). Library code must compile for every Flutter platform and for web WebAssembly.
   `check:lib-imports` fails on a `lib/` import outside its allowlist.
6. **Bumping upstream** is its own change (ADR 0005). The submodule is a shallow clone without
   tags, so fetch both tags first:
   `git -C third_party/Chart.js fetch --depth 1 origin tag <old-tag> tag <new-tag>`,
   `git -C third_party/Chart.js checkout <new-tag>`, review
   `git -C third_party/Chart.js diff <old-tag> <new-tag> -- src test/specs test/fixtures`, and the
   bump report once it exists. A commit pin (`packages/flutter_chartjs_port/doc/upstream-tracking.md`
   §2.4) fetches the full commit in place of `<new-tag>`: then `chartJsVersion` is
   `<last version>+<sha8>`, and the Chart.js `ref` and `commit` are the full commit. Then run
   `git add third_party/Chart.js` and update `chartJsVersion` and the Chart.js `version`, `ref`
   and `commit` in `packages/flutter_chartjs_port/tool/port_sources.yaml`. Run `upstream:manifest`.
   Port the diff for every started module. Close the ledger rows of the range. Move the Chart.js
   citations of `doc/differences.md` to the new pin (`upstream-tracking.md` §4.9). Restamp the
   headers (`packages/flutter_chartjs_port/doc/upstream-tracking.md` §4.8). Update the status texts in
   `doc/status.yaml` and run `dart run melos run parity`. Backports follow ADR 0006. They never
   move the submodule. `upstream:check` and `packages/flutter_chartjs_port/test/upstream_test.dart`
   fail on a mismatch.

The rules below come from the accepted ADRs and from two plans. The plans, `porting-flow.md` and
`upstream-tracking.md`, are still proposed. The doc paths are relative to
`packages/flutter_chartjs_port/doc/`.

- Backports from upstream `master`: ADR 0006 and `upstream-tracking.md` §2.2 (proposed).
- The backport header line `// Upstream backport: chartjs/Chart.js@<sha8> (#<PR>).`:
  `upstream-tracking.md` §2.5 (proposed). `check:headers` already accepts the line.
- The module status values of the `parity.md` legend: `porting-flow.md` §1 step 7 (proposed).
- `// DIVERGES(chartjs): <row id>, <reason>` markers and their `differences.md` rows:
  `porting-flow.md` §4 (proposed). `check:headers` already pairs markers with rows.
- The JS numeric translation rules: Chart.js ADR 0045. Number formatting: Chart.js ADR 0026
  (package:intl with the guards of `js_intl.dart`).
  Emulate JavaScript only where the result changes behavior (Chart.js ADR 0034): the ticks, the
  hit element, the item order, the resolved option, a throw, or a value that reaches a layout, a
  scale, an element property, a hit test, a discrete decision or a public return value. Do not
  emulate JavaScript for exact digits or pixels only. `check:js-semantics` already fails on the
  flagged forms. A kept form carries `// js-ok: <reason>`.
- Deferred plans (`porting-flow.md` §5.1), for example
  `packages/flutter_chartjs_port/doc/canvas-cuts-plan.md`: do not do their work in a phase. A change
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
  property read `object[key]`), `jsOrZero` (`value || 0` before arithmetic, Chart.js ADR 0017 §8),
  `jsAdd` (the operator `a + b` on a raw option value: a string operand joins, else the numbers
  add), `jsGetKey` (the read `object[key]` of a parsed item, a data item or a stack object, with the
  `jsGet` result; a read of a resolver stays `jsGet`), `jsGetIndex` (the read `object[index]` with a
  number index: a List gives the item at a whole index in range, else `undefined`), `jsSetIndex`
  (the write `list[index] = value`: a write at the length appends, a write past it or at a negative
  index throws a `RangeError`), `jsLessThan` (the operator `a < b` on raw values: two strings
  compare by their code units, a `DateTime` by its time value) (Chart.js ADR 0036), `jsSin` and
  `jsCos` (`Math.sin` and `Math.cos` at a protected site: a site that reaches a layout, a scale, an
  element property, a hit test, a public return value or a discrete decision; a display-only site
  keeps `dart:math` with `js-ok`, Chart.js ADR 0045) and the `undefined` sentinel (Chart.js ADR
  0043). `JsStringList` of `js_array.dart` is a string as an array-like value: the reads `s[i]` and
  `s.length`, and a `TypeError` for each write. `_dataCheck` keeps a string `data` in it.
  `jsToString` of a `DateTime` gives the `Date.prototype.toString` text in the platform zone, with
  the V8 zone name on the web and in UTC on the VM (Chart.js ADR 0036, differences.md row
  `platform-date-zone-name`). The conversions of `js_webidl.dart` (`canvasStyle`, `canvasNumber`,
  `canvasKeyword` and `canvasLineDash`) apply the WebIDL conversion of a Canvas 2D setter or of
  `setLineDash` to an option value (Chart.js ADR 0017 §8). Ported code calls them where upstream
  uses the JS builtin or gives an option value to the canvas. A typed Map read stays `map[key]`. Use
  `jsGet` when the receiver can be a value that is not a Map, or when an absent key must give
  `undefined` and not `null`. `helpers.merge` also writes into a `types.PropertyAccess` target, for
  example an element (Chart.js ADR 0039 §10). `clone` and `mergeIf` keep an element as a leaf.
  Ported code tests for the sentinel with `identical(value, undefined)`. The runtime also has these
  parts:
  - `JsClass` of `js_class.dart`: a JS class as a value (Chart.js ADR 0020). A read of a
    static property follows the superclass chain. `jsConstruct` is `new target(...args)`.
    `jsAssign` is `Object.assign` on a class value or a Map.
  - `jsIsFunction` (`typeof value === 'function'`) is true for a class value. `jsCall` throws an
    `ArgumentError` for a class value. `jsTypeof` is `typeof`.
  - `jsObjectFreeze` and `jsObjectIsFrozen` are `Object.freeze` and `Object.isFrozen` (Chart.js
    ADR 0021 §5). Only a `JsFreezable` freezes. A write into frozen options throws a
    `TypeError`.
  - `jsOwnPropertyNames` is `Object.getOwnPropertyNames`. For a resolver, it gives the keys of the
    `ownKeys` trap. `jsMapForEach` is `Map.prototype.forEach` while the callback changes the Map.
  - `jsSplice` is `Array.prototype.splice`. `start` and `deleteCount` go through
    `ToIntegerOrInfinity`. Dart `null` stands for an absent `deleteCount`.
  - `jsDateNow` of `js_date.dart` is `Date.now()` on `clock.now()` (Chart.js ADR 0045 §6). Ported
    code never calls `DateTime.now()`. A `DateTime` is a JS `Date`: `jsToNumber` gives its time
    value (Chart.js ADR 0024).
  - `js_promise.dart` has the promise jobs of Chart.js ADR 0019 §7:
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
  `packages/flutter_chartjs_port/test/specs/<base>_test.dart`. A pure-layer spec imports `package:test`,
  not `flutter_test` ([Tests](#tests)). It calls `setUpSpecs()` of
  `package:chartjs_test_utils/pure.dart` first in `main()`. Tests of behavior without an upstream
  spec go in `test/port/`. `check:headers` already compares each spec path with the mapped path.
- The source list `packages/flutter_chartjs_port/tool/port_sources.yaml`: Chart.js ADR 0035. It has
  one entry for each project that the package ports code from: Chart.js, fdlibm, `@kurkle/color`
  and chartjs-test-utils. Code from another project also needs an entry, with the license and
  holder of the header. A Chart.js bump (rule 6) also updates the Chart.js `version`, `ref` and
  `commit` in the entry. `check:headers` already fails on a
  mismatch.
- The notice of chartjs-test-utils goes in the `LICENSE` of
  `packages/chartjs_test_utils`, not in `packages/flutter_chartjs_port/LICENSE` (Licensing item 1):
  Chart.js ADR 0035. `check:headers` reads the `LICENSE` of the package that contains
  the file.
- The reference engine: Chart.js ADR 0045. Take JavaScript reference values only from the
  darwin-arm64 build of Node.js v24.22.1 (V8 13.6.233.17-node.58, ICU 78.3). The fdlibm data
  (`log10_reference.dart`, `atan2_reference.dart` and `trig_reference.dart`) are frozen: only
  the x64 build of Node.js v24.12.0 writes them again. Each test of a data file pins the Node.js
  version and the architecture of its data. Never take reference values from a browser.
- The four theming invariants (specs run unthemed, no forui or Material in `lib/`, no
  `Chart.defaults` writes for theming, no `lib/src/theme/` import in ported files): Chart.js ADR
  0050. `check:lib-imports` already fails on the two import invariants.

The D3 port applies the rules above with these changes. The D3 ADRs are proposed. The doc paths
are relative to `packages/flutter_d3_port/doc/`.

- Rule 1: read the upstream file in `third_party/<repo>`. Never port from `d4` or from another
  Dart D3 package (`prior-art/README.md`).
- Rule 2: the header names the repository and its tag, for example
  `// Ported from d3-array v3.2.4 src/ticks.js (ISC, Mike Bostock).` The port-only marker is
  `// Original code, not ported from D3: <reason>.` D3 ADR 0001 item 8 gives the holder strings.
  A file whose name fails the `file_names` lint has `// ignore_for_file: file_names` after its
  header lines (D3 ADR 0002).
- Rules 3 and 4: port the specs by D3 ADR 0004. Update the row of the repository in `parity.md`
  in the same change. From D3 phase 2, tool 6 writes `parity.md`.
- Rule 6: a bump moves one repository. It changes the submodule, the entry in
  `tool/port_sources.yaml` and the headers of the files of that repository (D3 ADR 0001 item 7).
  A bump of `third_party/d3` also changes `d3Version`. `upstream:check` and
  `packages/flutter_d3_port/test/upstream_test.dart` fail on a mismatch.
- `upstream-ledger.md` has one section for each repository. A difference carries
  `// DIVERGES(d3): <row id>, <reason>` and a row in `differences.md`.
- Number strings (D3 ADR 0003): when a string is the result of a module, its JS digits are
  behavior. Examples are d3-format, d3-path, d3-color and d3-time-format. The rules of Chart.js
  ADR 0045 apply to them.
- No port depends on another port (ADR 0008). Thus D3 code never imports
  `package:flutter_chartjs_port`. In D3 phase 1, ADR 0008 copies the generic runtime of `lib/src/js/`
  into the shared package `js_semantics`.

The ECharts port applies the rules above with these changes. The ECharts ADRs are proposed. The
doc paths are relative to `packages/flutter_echarts_port/doc/`.

- Rule 1: read the upstream file in `third_party/echarts` or `third_party/zrender`. Never port
  from a Dart ECharts package or from another port of ECharts (`prior-art/README.md`).
- Rule 2: the header names the project and its tag, for example
  `// Ported from Apache ECharts 6.1.0 src/util/number.ts (Apache-2.0, The Apache Software Foundation).`
  or `// Ported from zrender 6.1.0 src/core/matrix.ts (BSD-3-Clause, Baidu Inc.).` The port-only
  marker is `// Original code, not ported from Apache ECharts: <reason>.` A ported file keeps the
  upstream license comment block verbatim after its header lines (ECharts ADR 0001 item 11). A
  file whose name fails the `file_names` lint has `// ignore_for_file: file_names` after its
  header lines (ECharts ADR 0002).
- Rules 3 and 4: port the specs by ECharts ADR 0005. Update the row of the module in `parity.md`
  in the same change.
- Rule 6: an ECharts bump also moves zrender when the new ECharts `package.json` requires another
  zrender version. It changes the submodules, `echartsVersion`, `zrenderVersion`, the entries in
  `tool/port_sources.yaml` and the headers (ECharts ADR 0001 item 9). `upstream:check` and
  `packages/flutter_echarts_port/test/upstream_test.dart` fail on a mismatch.
- `upstream-ledger.md` has one section for each repository. A difference carries
  `// DIVERGES(echarts): <row id>, <reason>`, also in a zrender file, and a row in
  `differences.md`.
- Numbers and JS values follow ECharts ADRs 0003 and 0004 with the rules of Chart.js ADRs 0045
  and 0034. No port depends on another port (ADR 0008). Thus ECharts code never imports
  `package:flutter_chartjs_port` or `package:flutter_d3_port`.

## Tests

- The CI job `test` runs the tests in three shards (`--total-shards=3`). package:test puts a
  continuous part of the tests of each test file in each shard. Thus a test must not need the result
  of an earlier test of its file. A test that uses the state of an earlier test makes that state
  again, or checks it only when that test ran in the same shard. Examples are the group
  `harness-register-builtins` of `packages/flutter_chartjs_port/test/port/flutter_test_config_test.dart`,
  `packages/flutter_chartjs_port/test/port/core/date_format_locale_test.dart` and the group
  `harness-release-at-unmount` of `packages/chartjs_test_utils/test/index_test.dart`.
- A pure-layer file reaches neither `dart:ui` nor `package:flutter` through its direct or indirect
  imports. `check:lib-imports` computes the pure layers from the roots in
  `packages/flutter_chartjs_port/tool/src/lib_imports.dart`. The roots include `lib/src/js/`,
  `lib/src/types/`, `lib/src/kurkle_color/`, the helpers except `helpers.extras`, the files of
  `lib/src/elements/`, `plugin.decimation` and the files of `plugin.filler/` of `lib/src/plugins/`,
  and `platform.base`, `platform.basic` and `native_event` of `lib/src/platform/`. Of
  `lib/src/core/`, the roots are `core.defaults`, `core.element`, `core.config`, `core.adapters`,
  `core.interaction`, `core.layouts`, `core.animation`, `animation_spec`, `reduced_motion`,
  `core.typedRegistry` and the port-only `date_*.dart`. Of `lib/src/theme/`, the roots are `compile.dart` and `presets.dart`.
  The canvas interface `lib/src/canvas/canvas.dart` is pure, because `helpers.canvas` imports it.
- Write the tests of pure layers with `package:test`, not `flutter_test`. These tests run on the
  VM (`test`) and in Chrome with dart2js and dart2wasm (`test:web`).
- A test file that imports `flutter_test`, `dart:io`, `dart:ui` or other non-pure code needs
  `@TestOn('vm')` after its header line. `test:web` does not compile it. `check:lib-imports` fails
  on a test file without `@TestOn('vm')` that imports more than pure layers, `package:test` and
  `package:chartjs_test_utils/pure.dart`. It does not examine the tests of `chartjs_test_utils`.
  Keep the same rule there by hand.
- `flutter test` runs `packages/flutter_chartjs_port/test/flutter_test_config.dart` around each test
  file of `flutter_chartjs_port`. It sets the test view to DPR 1 and 800 x 600 before each test, also
  after a test calls `tester.view.reset()`. It restores `defaults`, `overrides` and `descriptors`
  after each test (`setUpDefaultsRestore()`, the row `harness-defaults-restore`). Thus a test that
  changes them does not change the next test.
- `flutter_test_config.dart` sets the default date zone to UTC (`setDefaultDateZone('Etc/UTC')`,
  the port of `test/index.js:23`). `setUpSpecs()` does the same. A test that changes the zone or
  calls `DateAdapterBase.override` restores the old state with `addTearDown`.
- `flutter_test_config.dart` registers the built-in components before `main()` of each test file and
  before the snapshot of the restore (`setUpBuiltins()`, the row `harness-register-builtins`,
  Chart.js ADR 0022 §8). After the registration, it sets `defaults.plugins.colors.enabled = false`
  (the port of `test/index.js:25-28`), before the snapshot of the restore. `setUpSpecs()` and
  `removeBuiltins()` remove them again, also the colors plugin and its defaults. Thus a pure-layer
  file has the same state under `flutter test` and `dart test`.
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
- A dataset Map of a chart that the colors plugin colorizes needs the type `<String, Object?>`. The
  colorizers write `borderColor` and `backgroundColor` into it (row `js-semantics-narrow-datasets`).
- A chart spec ports a Jasmine spy of a function value as a recording function value (`spyOn` of
  `test/support/jasmine.dart`). The spec stores it in place of the spied property, as
  `core.plugin_test.dart` does. A spy of a method is a spy object in the slot that the library
  reads (`spyOnElementDraw` for `meta.data[i]`, `spyOnDataset` for `meta.dataset`,
  `spyOnArrayListener` for the listeners of a data array, a context in `chart.ctx`).
  `test/support/jasmine.dart` holds the shared matchers (`jasmineEquals`, `objectContaining`,
  `anyFunction`, `JasmineOptions`) and spies (Chart.js ADR 0030). A draw spy needs
  `animation: false` (the default of `acquireChart`) or the end of the animations: it throws a
  `StateError` for an element with a running animation.
- A Jasmine `spyOn(chart, 'update')` is a plugin with a `beforeUpdate` hook (`_spyOnUpdate` of
  `test/specs/global.defaults_test.dart`, Chart.js ADR 0041 §11 item 2).
- Jasmine `this` in a spec port is a set of `late` variables of the group closure.
- A test scale overrides `getPixelForValue(Object? value, [double? index])` and applies
  `jsToNumber(value)` before its arithmetic. A test controller passes the raw
  `jsGet(parsed, axis)` (Chart.js ADR 0025).
- A scale reference test in `test/port/scales/` builds each chart of its generator with
  `acquireChart` in a `testWidgets` case and compares it through `scale_chart_harness.dart`. Its
  `main()` registers the test controller as a class value. The draw calls have the element draws:
  `drawCalls` puts the recording context in `chart.ctx`, in each `scale.ctx`, in the writable
  `DatasetController.ctx` (Chart.js ADR 0030), in the `ctx` of each `Title` box and in the `ctx` of
  the `Legend` box. A `Path2D` argument records as `{path, calls}`
  (`test/port/canvas/path2d_record.dart`). `expectCalls` removes the reference `clip` of the border
  ring of each bar that the port draws without a `clip` (the row `adapt-bar-clip`). A time-scale
  test runs each chart in `withClock` at the fixed `Date.now()` of its generator (`atNow` of
  `scale_time_harness.dart`).
- The controller reference tests in `test/port/controllers/` build each chart of their generator
  with `acquireChart`, run its steps, and compare the observations, the hit queries and the draw
  calls through `controller_chart_harness.dart` (`testControllerChartCases`). The step `setTooltip`
  calls `setActiveElements` of `chart.tooltip` and then `update` on both sides (Chart.js ADR 0041 §3
  item 6). Each file also runs its cases with the light preset (theming.md §8 test 3): then the
  colors compare in their parsed form, and the options compare only the keys of upstream. A JS
  `TypeError` of a case is a Dart `TypeError`. A step that throws stands in the data as `{do}`
  without observations.
- The plugin reference tests in `test/port/plugins/` run the cases of their generator through
  `testPluginChartCases` of `plugin_chart_harness.dart`: the controller harness with `hits: false`,
  the key `boxes` (`observeBoxes`) and a key `plugins.<id>` for each observer of the file. A unit
  case turns off each other plugin (`unitPlugins` of `plugin_chart_common.mjs`), and a full case
  runs the plugins with their defaults (Chart.js ADR 0041 §3 and §4).
- The test files of a controller unit register the controller in `main()`
  (`Chart.register([<Name>Controller.jsClass])`) until the integration agent of its wave adds the
  controller to the namespace `controllers` (Chart.js ADR 0030 §3 item 4). Then
  `flutter_test_config.dart` registers it, and the line goes. A test-only controller subclass
  with its own id (the polar area subclass with option sharing) registers in the `setUp` of its
  group and unregisters in the `tearDown`.
- The JS reference charts get the `BasicPlatform` of Node.js, whose `updateConfig` writes
  `animation: false` (`platform.basic.js:20-22`). The Dart harness gives the platform of
  `platform.flutter.dart`, which keeps the option, as the DOM platform does. Thus a controller
  generator with a case that needs the animation options (the doughnut and polar area `reset`
  cases) puts the no-op `updateConfig` of `BasePlatform` on `BasicPlatform` first.
- The doughnut and pie test files map the expected JS `null` of `xAxisID` and `yAxisID` to
  `undefined` (`_undefinedAxisIds`): their empty `linkScales` keeps the JS `null`, and the Dart
  field `ChartMeta.xAxisID` (an `Object?`, the raw id) has Dart `null` for both.
- The doughnut, pie and polar area generators have the `legend:` cases of Chart.js ADR 0041 §5: the
  real legend with the label options of the old test legend, and the step `clickLegend`. The probe
  `realLegend` reads `legendItems` through `types.LegendElement` and `legendHitBoxes` through a cast
  to `Legend`. The polar area case `legend: off` calls the override `generateLabels` without a
  legend (`TypeError`). The `legend:` cases run unthemed only.
- The controller generators have no step that writes an option. A pin test of an option change
  takes its expected values from a probe on the pinned build, and the test comment gives the
  probe and its output (`controller.scatter_test.dart`, group `showLine`).
- A spec that changes a data array of a chart (`push`, `pop`, `shift`, `splice`, `unshift`)
  changes the `List` and then calls `notifyArrayListeners`, the body of the hooked method
  (differences.md row `platform-array-events`; the helpers `_push` to `_unshift` of
  `test/specs/core.datasetController_test.dart`). `chart.getActiveElements()` in a Jasmine
  `toEqual` is the list of the objects `{element, datasetIndex, index}`. The event object
  `{type, chart, native: true, x, y}` of `core.interaction.tests.js` is a `types.ChartEvent` with
  `native` null.
- `toEqualOptions` reads the keys of an expected object with `jsObjectKeys`, as the upstream
  `for...in` with `hasOwnProperty` does. Thus it compares only the keys of the first scope of an
  expected resolver. An actual element or tooltip (a `types.ElementPropertyRead`) is an object:
  the matcher reads each expected key by name. An expected element compares with `===` (row
  `harness-expected-element`).
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
- A spec file with a fixture group calls `group('auto', fixture.specs('<prefix>'))` at the upstream
  line, with `import '../fixtures/index.dart' as fixture;` (Chart.js ADR 0029). Thus the file has
  `@TestOn('vm')`. Each fixture test has the tag `fixtures`: `test --no-select`, `test:cases` and
  `parity` exclude it, and `test:fixtures` runs it. A hand port is one file at
  `test/fixtures/hand/<path>.dart` with the header of rule 2, the library doc `/// A hand-ported
  fixture config (Chart.js ADR 0029, section 4).` before `library;`, and the function `fixture()`,
  which makes new objects at each call. Its entry in `handFixtures` has the first 12 hex digits of
  the manifest `sha256`. The import prefix is the path without the extension in lower case, with
  each run of other characters than `a-z` and `0-9` as `_`. A fixture skip is an entry of
  `fixtureSkips`. No skip covers a defect. In a hand port, a scriptable option reads `context.tick`
  as a `Tick` (`(jsGet(context, 'tick')! as Tick).value`) and a property of an element with the
  access by name of `Element` (`(jsGet(ctx, 'p0')! as Element)['skip']`), because `jsGet` gives
  `undefined` for these typed objects. A canvas as an image source is `toImageSource()` of
  `UiCanvasElement`. A `moment(...)` value is a `DateTime.utc(...)` of the same time value, with the
  marker of the row `harness-fixture-sources`. `test/fixtures/fixture_events.dart` gives the chart
  event of the raw `mousemove` of the 8 tooltip fixtures (`fixtureMouseMove`, row
  `harness-fixture-sources`). It is outside `hand/`.
- The Node.js generators in `packages/flutter_chartjs_port/tool/reference/` write
  `test/port/js/*_reference.dart`, `test/port/helpers/draw_point_reference.dart`,
  `test/port/elements/*_reference.dart` (point, line, bar and arc),
  `test/port/core/*_reference.dart` (animation, interaction, layouts, scale, scale autoskip, dataset
  controller, registry, controller and date adapter), `test/port/scales/*_reference.dart` (the scale
  chart harness and the seven scales of phase 6), `test/port/theme/*_reference.dart` (light and
  precedence), `test/port/controllers/controller_<snake>_reference.dart` (the eight controllers of
  phase 7), `test/port/plugins/*_reference.dart` and
  `test/port/plugins/plugin.filler/*_reference.dart` (the plugins of phase 8; the tooltip generator
  writes two files, `plugin_tooltip_reference.dart` and `plugin_tooltip_more_reference.dart`,
  because a data file stays below 2,500,000 bytes),
  `test/port/platform/chart_host_input_reference.dart` (the input path of the legend and the
  tooltip, Chart.js ADR 0037 §17) and `test/port/index_umd_reference.dart` (the keys of the UMD
  `Chart`, Chart.js ADR 0048 §1). The other generators run on the reference engine of Chart.js
  ADR 0045. `log10_reference.mjs`, `atan2_reference.mjs` and `trig_reference.mjs` stop unless
  Node.js is the x64 build v24.12.0 (Chart.js ADR 0045 §2): on arm64, the log10 and trig data
  differ in the last bits and in the NaN signs.
  `theme_precedence_reference.mjs` also registers the 8 pinned controllers, and adds a JavaScript
  prototype of the hunks H4a-H5 to `plugin.colors.ts` in its prototype run. It and
  `controller_reference.mjs` register the seven plugins of `src/plugins/index.js` by name (a module
  namespace registers nothing) and set `defaults.plugins.colors.enabled = false`, as
  `flutter_test_config.dart` does. Each generator on the dist calls `registerBuiltins` of
  `scale_chart_common.mjs` (Chart.js ADR 0041 §1): it registers the four namespaces of
  `src/index.umd.ts:28` and sets `colors.enabled = false`. A future generator without plugins pairs
  with `Chart.unregister([plugins])` in `main()` of its Dart file. `theme_precedence_reference.mjs`
  stops unless `third_party/Chart.js`, `third_party/kurkle-color` and
  `third_party/chartjs-test-utils` are at their commits of `tool/port_sources.yaml`, with no change
  in `src/`. `theme_light_reference.mjs` stops unless `third_party/Chart.js` and
  `third_party/kurkle-color` are at their commits, with no change in `src/`. The scale generators
  run a build of Chart.js at the pinned commit (`dist/chart.js` of a clone outside the repository,
  the first argument or `CHARTJS_DIST`) through `scale_chart_common.mjs`. Its header gives the build
  steps. It stops unless the clone is at the `commit` of `tool/port_sources.yaml`. It also stops
  unless `third_party/chartjs-test-utils` is at its commit, with no change in `src/`. It measures
  text in Liberation Sans 2.1.5 from the TTF tables. The canvas of `fakeCanvas` has a `style` with
  `getPropertyValue`, `getPropertyPriority` and `setProperty` with the DOM rules, for the canvas
  direction of `textDirection`. `tool/reference/controller_chart_common.mjs` is the shared code of
  the controller generators. It defines a recording `Path2D` before the dist loads. A comment line
  of a data file has at most 80 characters: the generator stops on a longer probe note. `dartArgs`
  of `scale_chart_common.mjs` applies the WebIDL `ToNumber` to the number arguments of the canvas
  and `Path2D` calls (also `bezierCurveTo`, `quadraticCurveTo` and the first five arguments of
  `arc`), as a browser does. A change of `dartArgs` runs each scale and controller generator again,
  and the data of the generators whose arguments are numbers stays byte-identical.
  `tool/reference/plugin_chart_common.mjs` is the shared code of the plugin generators, with
  `unitPlugins`, `observeBoxes` and `runPluginCase` (Chart.js ADR 0041). Its Dart side is
  `test/port/plugins/plugin_chart_harness.dart`. `plugin_filler_reference.mjs` runs on the bundle,
  with `_getTarget` of the source file `filler.target.js`, and also stops unless
  `third_party/kurkle-color` is at its commit. `filler_target_reference.mjs` runs on the source
  files with type stripping and fakes, and stops unless `third_party/Chart.js`,
  `third_party/kurkle-color` and `third_party/chartjs-test-utils` are at their commits.
  `plugin_dispatch_reference.mjs` replaces each hook of the seven plugin objects of the build with a
  recording function and gives each chart an inline plugin `recorder` with every hook name.
  `test/port/plugins/index_test.dart` does the same with recording closures of the same parameter
  count, and restores the hooks with `addTearDown`. `date_adapter_reference.mjs` and the time-scale
  generators also need a `node_modules` folder with moment 2.29.4, moment-timezone 0.5.42 and
  chartjs-adapter-moment 1.0.1, and run with `TZ=UTC`. `date_adapter_reference.mjs` takes the folder
  as its argument. The time-scale generators and `controller_bar_reference.mjs` (for its timeseries
  case) take it as the second argument or from `MOMENT_NODE_MODULES`. The bar test file runs each
  case at the fixed `Date.now()` of the generator. `chart_host_input_reference.mjs` gives the DOM
  events of Chrome for each gesture action of a step (Chart.js ADR 0037, sections 6 to 9) and feeds
  `chart._eventHandler` with one call for each type of `options.events` in the frame, in the order
  of the first event of each type (section 11). `test/port/platform/chart_host_input_test.dart`
  drives the same actions as Flutter pointer events through `ChartHost`, one pump for each step, and
  compares the DOM events of the host too. `tool/reference/text_metrics/` writes
  `test/port/canvas/text_metrics_reference.dart` from headless Chrome. The engine rule of Chart.js ADR 0045
  does not apply to it. Do not edit the generated files by hand.
- The D3 tests use `package:test` (D3 ADR 0004). In phase 0, `test/upstream_test.dart` is the
  only D3 test. It has `@TestOn('vm')`. Thus `test:web` does not run the D3 package yet. The first
  pure D3 test adds the package to `test:web`.
- In a D3 test file with `// ignore_for_file: file_names`, `@TestOn('vm')` comes after the ignore
  line (D3 ADR 0002 section 2). From phase 1, each D3 spec calls `setUpSpecs()` of
  `test/support/spec_setup.dart` first in `main()`. The D3 package has no
  `flutter_test_config.dart`.
- The ECharts tests use `package:test` (ECharts ADR 0005). In phase 0, `test/upstream_test.dart`
  is the only ECharts test. It has `@TestOn('vm')`. Thus `test:web` does not run the ECharts
  package yet. The first pure ECharts test adds the package to `test:web`.

## Licensing

- Chart.js is MIT. `packages/flutter_chartjs_port/LICENSE` lists both copyright holders and
  `REUSE.toml` annotates the paths. CI runs `reuse lint`.
- D3 is ISC. `packages/flutter_d3_port/LICENSE` is the ISC text with
  `Copyright 2010-2026 Mike Bostock` and `Copyright 2026 Vasiliy Ditsyak`. `LICENSES/ISC.txt` has
  the license text. The `packages/flutter_d3_port/**` table of `REUSE.toml` comes after the
  `chartjs_test_utils` table. D3 ADR 0001 items 8 and 10 give the other components and their
  holder strings. Examples are d3-ease (BSD-3-Clause), ColorBrewer in d3-scale-chromatic
  (Apache-2.0), delaunator (`Mapbox`) and robust-predicates (Unlicense). The change that ports
  the first file of a component adds that component by the three steps below.
- Apache ECharts is Apache-2.0. The code of the ECharts port is Apache-2.0 too.
  `packages/flutter_echarts_port/LICENSE` is the plain Apache-2.0 text, and
  `packages/flutter_echarts_port/NOTICE` keeps the notice of Apache ECharts unchanged.
  `LICENSES/Apache-2.0.txt` has the license text. The `packages/flutter_echarts_port/**` table of
  `REUSE.toml` comes after the D3 table. ECharts ADR 0001 item 12 gives the other components:
  zrender (BSD-3-Clause, `Baidu Inc.`), the d3 code in five ECharts files (BSD-3-Clause), and
  node-timsort, jsdiff and tween.js in zrender files. The change that ports the first file of a
  component adds that component by the three steps below.
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
  only. See `packages/flutter_chartjs_port/doc/prior-art/`.

## Conventions

- Package names: ADR 0007. The library package of a port has the name `flutter_<library>_port`,
  with the suffix `_port`: `flutter_chartjs_port`, `flutter_d3_port` and `flutter_echarts_port`.
  A later port uses the same form. A harness package is `<library>_test_utils`, or the npm name
  of the upstream harness in snake case (`chartjs_test_utils`). A gallery app is
  `apps/<library>_gallery`. A design-system adapter is `<library package>_<system>`, for example
  `flutter_chartjs_port_forui`. The directory and the commit scope of a package are its name.
  Before a change adds a name, examine `https://pub.dev/api/packages/<name>`: it must give 404.
- Lints: `very_good_analysis` (root `analysis_options.yaml`, which also carries its formatter
  settings, so run Dart tools after `flutter pub get`). The `analysis_options.yaml` of
  `flutter_chartjs_port` includes the same rules (Chart.js ADR 0047). Public APIs are documented.
- Commits: Conventional Commits, signed off (`git commit -s`, DCO), for example
  `feat(flutter_chartjs_port): port helpers.math`. The scope of the D3 port is `flutter_d3_port`.
  The scope of the ECharts port is `flutter_echarts_port`. Checks:
  - lefthook ≥ 1.0 `commit-msg` hook (`lefthook install`): `commitlint_cli` checks the type, and
    the scope when one is given, against the list in `commitlint.yaml`; a second command requires a
    `Signed-off-by` trailer;
  - CI `dco` job: checks the sign-off on every pull-request commit.
- CI jobs (`.github/workflows/ci.yaml`): `format`, `analyze`, `test` (ubuntu, macOS, Windows),
  `test-web`, `fixtures` (on `ubuntu-24.04`, also the runner of the theme goldens),
  `port-checks`, `upstream-manifest`, `gallery-web`, `gallery-android`, `gallery-ios`,
  `upstream-pin`, `reuse` and `dco`. A `workflow_dispatch` run has the inputs `update_goldens` and
  `flutter_version` (`test:goldens`).
- Toolchain: Flutter 3.47.7 (Dart 3.13.5), pinned in `.fvmrc`; CI reads the same file. All
  packages and the gallery have the floor `sdk: ^3.13.0` and `flutter: ">=3.47.0"`
  (`packages/flutter_chartjs_port/doc/porting-flow.md` §2.12).
