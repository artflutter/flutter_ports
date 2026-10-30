# Chart.js ADR 0048: Entry points and the public library

- Status: accepted (2026-10-30)
- Date: 2026-10-29
- Related: [Chart.js ADR 0012](0012-dart-file-naming.md) (names, `_` exports and `_` members),
  [Chart.js ADR 0013](0013-canvas-model.md) (a canvas member arrives with its caller),
  [Chart.js ADR 0020](0020-registry-and-component-classes.md) §3 and §6 (class values, the statics
  of `Chart`, `registerables`), [Chart.js ADR 0024](0024-dates.md) (the zone exports),
  [Chart.js ADR 0037](0037-legend-and-tooltip-input-path.md) §1 (the platform files),
  [Chart.js ADR 0038](0038-plugin-modules-class-values-and-interfaces.md) §1 (the plugin objects),
  [Chart.js ADR 0041](0041-plugin-test-strategy.md) §12 (the namespace spec),
  [Chart.js ADR 0043](0043-options-representation-and-resolver.md) (raw configs, three states),
  [Chart.js ADR 0047](0047-published-archive.md) (the archive),
  [Chart.js ADR 0049](0049-chart-view-widget.md) (the widget), Chart.js ADR 0050 (the theme API),
  [ADR 0007](../../../../docs/adr/0007-package-names.md) (package names)

## Context

Upstream has three code entries (`package.json@v4.6.1:18-33`): `chart.js`, `chart.js/auto` and
`chart.js/helpers`. The types of `chart.js` come from `src/types.ts`. The UMD bundle comes from
`src/index.umd.ts`.

- `src/index.ts@v4.6.1:1-25` exports the modules, the four namespaces and `registerables`. It
  registers nothing. The port has it in `lib/src/index.dart`.
- `src/index.umd.ts@v4.6.1` (54 lines) registers the four namespaces at import (:28). It writes 14
  statics on `Chart` (:30-43), copies the four namespaces and `platforms` onto `Chart` (:46), and
  sets `Chart.Chart` (:47) and `window.Chart` (:49-51).
- `src/types.ts@v4.6.1:6-55` exports `index.js` and `types/index.js`. Its explicit list (:10-54)
  takes the declarations of `types/index.js` for the names that both files export.
- `src/platform/index.js@v4.6.1:4, 13` exports `DomPlatform`. The port replaces
  `platform.dom.js` with `platform.flutter.dart` and its class `FlutterPlatform` (Chart.js ADR 0037
  §1).
- `src/core/core.controller.js@v4.6.1:957-959` returns `this.canvas.toDataURL(...args)`, a
  synchronous data URL.

The port before this ADR:
- `lib/flutter_chartjs_port.dart` exports only `src/upstream.dart`. The rows of
  `src/index.umd.ts` and `src/types.ts` are `not started` (`doc/parity.md:182-183`).
- The cases :6, :26 and :35 of `test/specs/global.namespace_test.dart` skip as
  `blocked: index.umd` (:33-54). The stale-block check of tool 5 keeps them valid only while the
  row `src/index.umd.ts` is not `ported` (Chart.js ADR 0041 §12).
- `test/specs/platform.dom_test.dart` reads `FlutterPlatform` for `Chart.platforms.DomPlatform`
  (its comment at :22-25).
- `Chart.toBase64Image` throws an `UnsupportedError` (`lib/src/core/core.controller.dart:1916-1928`,
  row `platform-to-base64-image`). `dart:ui` reads pixels only asynchronously.
- The specs and the gallery import `package:flutter_chartjs_port/src/` files.

Dart facts:
- Dart has no import side effects. A top-level `final` runs its initializer at the first read,
  once in each isolate.
- A Dart class gets no static member at run time. `Chart.Chart` cannot be a Dart static: the
  analyzer gives `member_with_class_name` (probe `a-fidelity/p6_static_names.out`).
- `Animation` and `Element` of `lib/src/index.dart` collide with `package:flutter/widgets.dart`,
  `material.dart` and `cupertino.dart`. No name collides with `dart:ui`. `Point` of
  `lib/src/types/` collides with `dart:math` only (probes `a-performance/exports/probe_exports.out`,
  `a-simplicity/p3-material-collisions.txt`, `a-fidelity/p5_collisions.out`).
- Eight names collide between `lib/src/index.dart` and `lib/src/types/index.dart`: `BasePlatform`,
  `Chart`, `DatasetController`, `Element`, `LineElement`, `PointElement`, `RadialLinearScale` and
  `Scale` (probe `a-simplicity/p1-types-ambiguity.txt`). The analyzer reports each one as
  `ambiguous_export`.
- The analyzer reports `invalid_use_of_internal_member` when another package reads an `@internal`
  member of an exported concrete class. The judge probe J1 gives 3 warnings for `Chart.lastEvent`,
  `Chart.metasets` and `ChartMeta.dataset_`. Chart.js ADR 0012:93-95 covers only the members of
  type libraries, which carry no `@internal`.
- Some `_` members of `lib/src/types/` have no `@internal`: `types.ChartMeta`
  (`lib/src/types/index.dart:228-237`) and `LayoutItem.layers` (`lib/src/types/layout.dart:126-135`).
  Some concrete members lack `@internal`: `Animation.to` (`lib/src/core/core.animation.dart:285-287`)
  and `ChartMeta.parsed` (`lib/src/core/core.controller.dart:341-343`).

Sizes of release web builds (Flutter 3.47.7). These are build outputs, not timed runs:

| Build | dart2js | dart2wasm | Probe |
|---|---|---|---|
| No chart | 1,185,733 B | 999,096 B | `a-performance/size/sizes.txt` s0 |
| A line chart, the line set registered | 1,436,413 B | 1,392,816 B | s1 |
| s1 and an unread import of `src/index.dart` and `src/helpers/index.dart` | 1,436,413 B | 1,393,999 B | s1b |
| `registerables` registered | 1,639,008 B | 1,616,123 B | s2 |
| The line set and a read of the UMD class value, against the line set | +211,910 B | +231,908 B | `a-fidelity/p2_shake_dart2js.out` V2 − V0, `p2_shake_dart2wasm.out` W2 − W0 |

Thus `registerables` adds about 202.5 kB of dart2js output to a line-only app. A read of the UMD
value keeps every component.

A design panel of phase 9 (three drafts and one judge) scored the options of each item in the
order of `porting-flow.md` §1.1, with the Flutter conventions and the cost of a later change for
the public API.

## Decision

### 1. `lib/src/index.umd.dart`

The port of `src/index.umd.ts` is `lib/src/index.umd.dart`, with the rule-2 header of
`src/index.umd.ts`. No public library exports it, and no file of `lib/src/widgets/` imports it.
Thus an app pays no byte for it.

- `final JsClass chartUmd = _evaluate();` is the default export (:53). `_evaluate` keeps the
  upstream order and returns `Chart.jsClass`:
  1. `Chart.register([controllers, scales, elements, plugins])` (:28, Chart.js ADR 0020 §6).
  2. The writes of :30-43 into `Chart.jsClass` by name, in their order:
     - `helpers`: `Map<String, Object?>.of(_helpers)`, a mutable copy, as the spread gives.
     - `_adapters`: `adapters`.
     - `Animation`, `Animations`, `DatasetController`, `Element` and `Scale`: their class values.
     - `animator`: the animator.
     - `controllers`: `registry.controllers.items`.
     - `elements`: the namespace of `lib/src/index.dart`.
     - `Interaction`: an unmodifiable Map `{evaluateInteractionItems, modes}`, with the same
       `modes` Map as `Interaction.modes`.
     - `layouts`: the record of `core.layouts.dart`.
     - `platforms`: `_platforms` (section 7).
     - `Ticks`: `ticks`.
  3. `Object.assign(Chart, controllers, scales, elements, plugins, platforms)` (:46): one
     `jsAssign(Chart.jsClass, <source>)` call for each source, in that order. `jsAssign` takes one
     source (`lib/src/js/js_class.dart:222`).
  4. `Chart.jsClass['Chart'] = Chart.jsClass` (:47).
  5. :49-51 have no form: the port has no global object.
- `_helpers` has one entry for each runtime export of `src/helpers/index.ts@v4.6.1:1-16`, in code
  unit order, as the module namespace gives. The key is the upstream name, also for a `_` name. The
  value is the Dart member (Chart.js ADR 0012:66-69 gives the Dart name).
- The body runs at the first read of `chartUmd`, once in each isolate. A second read gives the
  same object, and the registration of step 1 runs once.

### 2. The new class values

These classes get a `static final JsClass jsClass` (Chart.js ADR 0020 §3), because the UMD body
keeps them as values:
- `Chart.jsClass` (`src/core/core.controller.js@v4.6.1:103`): the statics of :105-120 in their
  order (`defaults`, `instances`, `overrides`, `registry`, `version`, `getChart`, `register`,
  `unregister`), the same objects as the Dart statics. `construct` gives `Chart(args[0], args[1])`,
  with `undefined` for an absent argument. `Chart.jsClass` does not reference
  `index.umd.dart`: only `_evaluate` writes the UMD statics.
- `Animation.jsClass` (`src/core/core.animation.js@v4.6.1:27`) and `Animations.jsClass`
  (`src/core/core.animations.js@v4.6.1:6`).
- `FlutterPlatform.jsClass`: `JsClass('FlutterPlatform', superclass: BasePlatform.jsClass,
  construct: (newTarget, args) => FlutterPlatform())`, the form of `BasicPlatform.jsClass`.

### 3. Registration

No library code and no widget code registers a component, as the ESM entry
(`src/index.ts@v4.6.1:20`). The app calls `Chart.register(registerables)` or a list of class values
and plugin Maps before its first chart. An unregistered type throws the upstream message
`"line" is not a registered controller.` (`src/core/core.registry.js@v4.6.1:178`,
`lib/src/core/core.registry.dart:249`).

- The README quick start calls `Chart.register(registerables)` in `main()` before `runApp`. It
  also gives the lists of each chart type of `docs/getting-started/integration.md@v4.6.1:34-67`.
  The palette of a theme needs the `colors` plugin (row `theme-H5`).
- `check:lib-imports` gets a rule: a file of `lib/src/widgets/` imports no file of `controllers/`,
  `scales/`, `elements/` or `plugins/`, and not `src/index.dart` or `src/index.umd.dart`.
- The test harness keeps its direct registration (`setUpBuiltins`, row
  `harness-register-builtins`). It does not read `chartUmd`.

### 4. `lib/src/types.dart`

The port of `src/types.ts` is `lib/src/types.dart`, with the rule-2 header of `src/types.ts`:

```dart
export 'package:flutter_chartjs_port/src/index.dart';
// DIVERGES(chartjs): adapt-types-entry, the classes take the 8 shared names.
export 'package:flutter_chartjs_port/src/types/index.dart'
    hide BasePlatform, Chart, DatasetController, Element, LineElement,
        PointElement, RadialLinearScale, Scale;
```

- Upstream takes the declarations of `types/index.js` for the ambiguous names (:10-54). Dart takes
  the 8 classes of `index.dart` and hides the 8 interfaces. The class implements its interface, so
  each typed reader of the interface accepts it.
- The TypeScript-only names of :48-52 have no Dart form. The plugin names of :36-41 are the plugin
  Maps (Chart.js ADR 0038 §1). `DomPlatform` is `FlutterPlatform` (section 7).
- `ambiguous_export` finds each new collision at analysis time.

### 5. The public libraries

The package has three public libraries. All three are port-only files. None is a pure layer.

```dart
// lib/chartjs.dart: the `chart.js` entry (src/types.ts) for code that
// extends Chart.js. Import it with a prefix or with `hide` next to Flutter.
export 'src/canvas/canvas.dart' show CanvasGradient, CanvasImageSource,
    CanvasPath, CanvasPattern, CanvasRenderingContext2D, CSSStyleDeclaration,
    HTMLCanvasElement, Path2D, TextMetrics;
export 'src/core/core.controller.dart' show ChartMeta;
export 'src/core/date_adapter.dart' show defaultDateZone, setDefaultDateZone;
export 'src/helpers/helpers.collection.dart' show notifyArrayListeners;
export 'src/js/js_class.dart' show JsClass;
export 'src/js/js_undefined.dart' show Undefined, undefined;
export 'src/types.dart' hide ChartMeta, LayoutItem, PluginService, adapters,
    detectPlatform /* and the names of section 6 */;
export 'src/upstream.dart';

// lib/flutter_chartjs_port.dart: the app library.
export 'chartjs.dart' hide Animation, Element;
export 'src/theme/...' show /* Chart.js ADR 0050 */;
export 'src/widgets/chart_view.dart' show ChartView;

// lib/helpers.dart: the `chart.js/helpers` entry.
export 'src/helpers/index.dart' hide /* the Dart names of upstream `_` exports */;
```

- A file of a Flutter app imports `package:flutter/widgets.dart` (or `material.dart`) and
  `package:flutter_chartjs_port/flutter_chartjs_port.dart` with no prefix and no collision.
- `chartjs.dart` and `helpers.dart` mirror the code entries `.` and `./helpers` of
  `package.json@v4.6.1:18-33`. Code that extends Chart.js (a plugin, a controller subclass, a
  scale) imports them, with a prefix or `hide Animation, Element` next to Flutter.
- The port-only exports: the canvas interface (a plugin draws on `chart.ctx`), the concrete
  `ChartMeta` (the type of `getDatasetMeta`), the zone functions (Chart.js ADR 0024:766-767),
  `notifyArrayListeners` (row `platform-array-events`), `JsClass` (a user subclass registers
  through its class value, Chart.js ADR 0020:768-771) and `undefined` (the third state of a config
  value, Chart.js ADR 0043:82-87).
- These stay internal: `ChartHost`, `RenderChartHost`, the canvas event helpers of
  `chart_host.dart`, `UiCanvasElement`, `index.umd.dart`, `lib/src/js/` except `JsClass` and
  `undefined`, the theme compiler, `chartThemeOf`, `themeConfigKey` and the reduced-motion flag
  (Chart.js ADR 0049).
- `upstream.dart` gives `chartJsVersion` and `chartJsPackageVersion`.

### 6. Hide rules and `@internal`

The public libraries hide these names:
- the Dart names of the upstream `_` exports (Chart.js ADR 0012:66-69), for example `adapters` and
  `detectPlatform` in `chartjs.dart` and `angleDiff` in `helpers.dart`;
- `PluginService`: `chart.js` has no such name (`lib/src/core/index.dart:22-24`);
- `types.ChartMeta`: the concrete `ChartMeta` takes the name, and its `_` members carry
  `@internal`;
- `LayoutItem` and the port-only declarations around it, because `LayoutItem.layers` comes from
  `_layers` and has no `@internal`; a later export is an addition;
- each declaration of `lib/src/types/` with no declaration of the same name in
  `src/types/*.d.ts@v4.6.1`, for example `PropertyAccess`, `ElementPropertyRead`, `SimpleArc` and
  `VisualElementRange`.

The implementation step lists the names. A `hide` of a name that the library does not export is an
analyzer warning, so the lists stay exact. Before 0.1.0, `Animation.to`, `ChartMeta.parsed` and
each other member that the public API test finds get `@internal`.

### 7. `Chart.platforms` and the `DomPlatform` key

`Chart.platforms` of `index.umd.dart` is `_platforms`, an unmodifiable Map with the keys in code
unit order: `BasePlatform` (`BasePlatform.jsClass`), `BasicPlatform` (`BasicPlatform.jsClass`),
`DomPlatform` (`FlutterPlatform.jsClass`, with the marker of the row
`platform-umd-dom-platform`) and `_detectPlatform` (`detectPlatform`). The keys are the upstream
names, as the other namespaces have the bundle keys (Chart.js ADR 0020:586-587,
`lib/src/index.dart:93-104`). The specs read `Chart.platforms.DomPlatform` as written
(`test/specs/platform.dom.tests.js@v4.6.1:1, 21`, `test/specs/global.namespace.tests.js@v4.6.1:17`).
No public library exports `_platforms`. The class value has the name `FlutterPlatform`.

### 8. `toBase64Image`

- `HTMLCanvasElement` of `lib/src/canvas/canvas.dart` gets
  `Future<String> toDataURL([String? type, Object? quality]);`. The ported caller arrives with this
  ADR (Chart.js ADR 0013: a member arrives with its caller).
- `UiCanvasElement.toDataURL` takes the snapshot of the bitmap at the call (`_snapshot()`). Then it
  encodes PNG with `Image.toByteData(format: ui.ImageByteFormat.png)`, disposes the image and
  returns `data:image/png;base64,<data>`. A canvas with no pixels gives `'data:,'`, as the HTML
  standard gives (not in the repository).
- `Chart.toBase64Image` becomes
  `Future<String> toBase64Image([String? type, Object? quality])`, which returns
  `canvas!.toDataURL(type, quality)` with the marker of the row. The method is not `async`: a
  destroyed chart throws a `TypeError` at the call, as upstream
  (`src/core/core.controller.js@v4.6.1:957-959`, `:948`).
- The result holds the bitmap at the call. A draw after the call is not in the result. Each `type`
  gives PNG, and `quality` has no effect. The bytes differ from the encoder of Chrome.

### 9. Rows, status and gates

New `differences.md` rows:
- `platform-umd-entry` (platform, `src/index.umd.ts@v4.6.1:28-53`): the body runs at the first
  read of `chartUmd`, once in each isolate, not at the import. `window.Chart` (:49-51) has no form.
- `adapt-umd-namespace-objects` (adapt, `src/index.umd.ts@v4.6.1:39-40`,
  `src/core/core.interaction.js@v4.6.1:252`, `src/core/core.layouts.js@v4.6.1:283`):
  `Chart.Interaction` is a Map view of the two statics of the Dart class `Interaction`.
  `Chart.layouts` is the Dart record, with no read by name.
- `adapt-types-entry` (adapt, `src/types.ts@v4.6.1:10-54`): section 4.
- `platform-umd-dom-platform` (platform, `src/index.umd.ts@v4.6.1:20, 41, 46`,
  `src/platform/index.js@v4.6.1:4, 13`): the key `DomPlatform` gives the class value of the
  replacement (Chart.js ADR 0037 §1), with the name `FlutterPlatform`.

The row `platform-to-base64-image` gets the text of section 8. The row `harness-register-builtins`
keeps its text. `status.yaml` gives `src/index.umd.ts` and `src/types.ts` the status `ported`.

The gate of this ADR: the 3 `blocked: index.umd` cases pass, `test:cases` reports 0 missing cases,
the public API test passes, and a release web build of the public library with the line set has no
marker of another component (dart2js and dart2wasm).

The result of the gate (2026-10-30, `lib/` of `ec7d85c`): the 4 cases of `global.namespace`
pass, and `test:cases` reports 958 passed, 0 failed, 78 skipped and 0 missing cases in 53 spec
files. The public API test passes in `test --no-select`. Two release web builds of the gallery (Flutter
3.47.7) import the app library, show one line chart in a `ChartView` and differ only in the
registration. The markers are the string literals that only one component file holds:
`doughnut`, `polarArea`, `bubble`, `labelTextColor`, `lttb`, `min-max`, `propagate` and
`subtitle`.

| Build | dart2js `main.dart.js` | dart2wasm `main.dart.wasm` | Markers |
|---|---|---|---|
| The line set | 1,448,881 B | 1,424,126 B | none |
| `registerables` (the control) | 1,651,831 B | 1,646,300 B | each marker |

## Alternatives considered

- **Statics on the Dart class `Chart`.** Dart adds no static at run time. `Chart.Chart` is not
  possible. The statics then exist at each import, so the UMD body becomes import code that Dart
  does not have. Rejected on criteria 1, 3, 5 and 6.
- **`n/a` for `src/index.umd.ts`.** The 3 spec cases stay skipped, and `test:cases` keeps 3 cases
  that cannot pass. Rejected on criterion 1.
- **Dart export names as the namespace keys** (`FlutterPlatform`, `detectPlatform`, `helpers` keys
  without `_`). The four namespaces of `lib/src/index.dart` keep the bundle keys, also where the
  Dart name differs (`'Colors': colors`). The specs read `DomPlatform`. Rejected on criteria 1
  and 3.
- **Both keys, or a public `typedef DomPlatform`.** More names, and a public name for a class that
  the port replaced. Rejected on criteria 3, 5 and 6.
- **The harness reads `chartUmd` in place of its register call.** No behavior changes.
  `setUpBuiltins` registers once for each test file (`packages/chartjs_test_utils/lib/pure.dart:97-104`),
  and `removeBuiltins` unregisters. A lazy final registers once for each isolate. No probe
  covered a registration again after a removal. Rejected.
- **The widget registers `registerables`.** Each app then keeps every component (+202.5 kB of
  dart2js output for a line-only app), and the upstream throw of an unregistered type goes.
  Rejected on criteria 1, 2 and 6.
- **An `auto.dart` library or a lazy registration at the first miss.** More code and more public
  names in 0.1.0. A lazy registration hides the upstream throw. An `auto` form is a later addition.
- **`types.dart` as `n/a`, with the interfaces internal.** The hook and callback types
  (`ChartEvent`, `ActiveElement`, `TooltipModel`, `LegendElement`, `ChartArea`) need public names
  for typed closures. Chart.js ADR 0003:76-78 is about the options API. Rejected on criteria 1
  and 5.
- **A `show` list by hand for the types.** It repeats the upstream list in a form that drifts. The
  `hide` of the 8 names gives the same result. Rejected on criteria 3 and 4.
- **Two libraries that keep the `Animation` and `Element` collisions.** Each Flutter app then needs
  a prefix or a `hide`. A later rename breaks users in both directions. Rejected on criteria 5 and
  6.
- **One library, no `helpers.dart` in 0.1.0.** Plugin authors need the helpers, and upstream has
  `chart.js/helpers`. Rejected on criteria 1 and 3.
- **A pure library.** No user needs one: the pure layers do not draw a chart. Rejected on
  criteria 3, 4 and 6.
- **`toImageSync` beside `toBase64Image`.** It skips the encode (`lib/src/canvas/canvas_ui.dart:737`).
  No frame path needs it, and no controller object holds it (Chart.js ADR 0049). It is a later
  addition.
- **A second name `toBase64ImageAsync`, or `RenderRepaintBoundary.toImage` only.** The first adds a
  name and keeps a method that throws. The second gives no upstream string and no upstream name.
  Rejected.

## Consequences

- An app imports one library next to Flutter with no prefix. It registers the components that it
  needs, and the tree shaking keeps only those.
- Code that extends Chart.js imports `chartjs.dart` and `helpers.dart` with a prefix or a `hide`.
- After 0.1.0, each public name is a commitment. The committed list `doc/public_api.txt` and the
  public API test guard it.
- `chartUmd` stays internal. Only the tests read the UMD statics (`Chart.helpers`,
  `Chart.Interaction` and the others).
- `toBase64Image` returns a `Future<String>`. The 13 fake canvas classes of 12 test files get the
  new member.
- The change of `canvas.dart`, `canvas_ui.dart` and `core.controller.dart` updates the references
  of `canvas-cuts-plan.md` in the same commit (`porting-flow.md` §5.1).
- AGENTS.md (Layout, Commands, Porting rules) names the three public libraries, `index.umd.dart`,
  `types.dart` and the new check rule.

## Open

1. **`chart.js/auto`.** A later `auto` form (a library or a function) is an addition. Trigger: an
   app request.
2. **`toImageSync`.** A later addition on the canvas or on a controller object. Trigger: a frame
   path or an app request.
3. **The `src/` imports of the gallery that stay.** Phase 9 unit 7 moves the gallery to the public
   libraries and records a reason for each `src/` import that stays. Resolved (2026-10-30): unit 7
   (`7426e81`) moved the gallery. 15 files of `apps/chartjs_gallery/lib/` keep 38 imports of
   `src/`, and 11 test files keep 36. A reason line stands above each import.
4. **The `_` names of the helpers.** The drafts give different counts (144, about 160, 51 or 44
   `_` names). A regex count of the judge gives 121 runtime exports with 47 `_` names (unverified).
   The reference test of `index.umd.dart` gives the list. Resolved (2026-10-30):
   `test/port/index_umd_reference.dart` gives 122 runtime exports of `src/helpers/index.ts`, with
   47 `_` names. The hide list of `lib/helpers.dart` has 47 names.
5. **The import rule of section 3 and the input ADR.** Resolved (2026-10-29): Chart.js ADR 0051
   reads `legendHitBoxes` through a new port-only member of `types.LegendElement`. The rule of
   section 3 keeps no exception.

## Evidence

The working files of phase 9 in `.handover/phase9/panel/` (not committed):
- `brief.md` (the items A1-A6), the drafts `a-fidelity.md`, `a-performance.md` and
  `a-simplicity.md`, and the verdicts `judge-a.md` (sections 0, A1-A6).
- Probes in `probes/a-fidelity/`: `p1_global_namespace.out` (the 4 cases pass with the class
  value), `p2_shake_dart2js.out` and `p2_shake_dart2wasm.out` (the UMD read keeps every
  component), `p5_collisions.out`, `p6_static_names.out`, `p_to_data_url_probe_test.out` (the
  snapshot at the call: first pixel `ff0000ff`).
- Probes in `probes/a-performance/`: `size/sizes.txt` (the sizes table), `exports/probe_exports.out`,
  `base64/base64.out` (the data URL decodes to the canvas size).
- Probes in `probes/a-simplicity/`: `p1-types-ambiguity.txt` (the 8 hides),
  `p3-material-collisions.txt`, `p5-treeshake/result.txt` (the component markers of a release
  build), `p7-result.txt`.
- Probe in `probes/a-judge/`: `j1_internal_use.out` (the 3 `invalid_use_of_internal_member`
  warnings).
- Upstream: `src/index.umd.ts@v4.6.1:1-54`, `src/index.ts@v4.6.1:1-25`, `src/types.ts@v4.6.1:1-55`,
  `src/platform/index.js@v4.6.1:1-13`, `src/helpers/index.ts@v4.6.1:1-16`,
  `test/specs/global.namespace.tests.js@v4.6.1:1-39`, `package.json@v4.6.1:18-33`.
