# Chart.js ADR 0049: The ChartView widget and reduced motion

- Status: proposed
- Date: 2026-10-29
- Related: [Chart.js ADR 0016](0016-frame-scheduling.md) (frame scheduling, the `setState` rule of
  the host layout), [Chart.js ADR 0019](0019-animation.md) §10 and Open "Reduced motion",
  [Chart.js ADR 0037](0037-legend-and-tooltip-input-path.md) §3-§5 and §16 (the host, its sizes
  and the scope of phase 9), [Chart.js ADR 0042](0042-theming.md) (the theme modes),
  [Chart.js ADR 0043](0043-options-representation-and-resolver.md) (raw Map configs in 0.1.0),
  [Chart.js ADR 0048](0048-entry-points-and-public-library.md) (the public libraries and the
  registration), Chart.js ADR 0050 (the theme API), Chart.js ADR 0051 (input events and
  interaction state), [theming.md](../theming.md) §3.7, §5.1 and §11

## Context

Chart.js ADR 0037 §16 gives the rules of the public widget: it builds on the internal host
`ChartHost`, creates the chart after the render object of the host exists (else `detectPlatform`
gives `BasicPlatform`), connects `onTickerModeChanged` to `animator.mute` and `animator.unmute`,
and disposes the `UiCanvasContext`. Chart.js ADR 0016:300 keeps one canvas for each host.
Chart.js ADR 0016:348-351: the first attach and the first `resize()` run in the layout of the
host, and a `setState` call there throws "Build scheduled during frame."
(`widgets/binding.dart:1436`, Flutter 3.47.7). The widget name is not `Chart`, the ported
controller. theming.md §5.1 names it `ChartView`.

The gallery host `ChartCanvas` (`apps/chartjs_gallery/lib/demo/chart_canvas.dart:71-80`) creates
the chart in a post-frame callback. Upstream sizes a chart at construction: `new Chart` attaches
when the canvas is in the document (`src/core/core.controller.js@v4.6.1:1044-1048`). The harness
forces a layout, so that `acquireChart` starts each chart attached
(`packages/chartjs_test_utils/lib/src/utils.dart:106-112`).

The probes of the design panel give these facts (Evidence):
- **A start before the first layout of the host** (at the mount) starts the chart detached
  (Chart.js ADR 0037 §3). `detached()` runs `_stop()`, and `_stop()` runs `animator.remove(this)`
  (`src/core/core.controller.js@v4.6.1:927-931`, `:1032-1049`). This drops the `complete` and
  `progress` listeners of the constructor (`:188-189`). Thus `onComplete`, `onProgress` and
  `afterRender` of an animated render never run (probe T2: 0, 0, 0).
- **A start in a post-frame callback** shows the default canvas size in frame 1 and the chart
  size in frame 2: 300 x 150 (loose constraints) or 400 x 150 (tight width), then 400 x 200. The
  widget below moves from y 150 to y 200 (probes T1 and P6).
- **A start in the first layout of the host** starts the chart attached. The host has the chart
  size in frame 1, and the animator listeners stay (probe T4: 1, 63, 1).
- In every form, an animated chart draws first in frame 2. With `animation: false`, a start in
  the layout paints in frame 1, and a post-frame start paints in frame 2 (judge probe J2).
- A `setState` call in `afterInit` fails with "Build scheduled during frame." for the start in the
  layout. It passes for the post-frame start (J2).
- **An update in `didUpdateWidget`** runs the replay of the last event
  (`src/core/core.controller.js@v4.6.1:529-532`), which calls `onHover` (`:1222-1223`) during the
  build. A `setState` there throws "setState() or markNeedsBuild() called during build."
  (`widgets/framework.dart:5367`; probe P6, `sync=true`).
- **An update in a post-frame callback** of frame N: an animated update draws first in frame N+1,
  as the update in the build does. Only a non-animated update (`'none'`, `animation: false`,
  reduced motion) shows one frame later (J2).
- An unguarded `setState` in `onHover`, with a config that the parent builds in `build`, loops:
  63 `onHover` calls in 60 frames after one hover (P6).
- `Config` has setters only for `type`, `data` and `options`
  (`src/core/core.config.js@v4.6.1:173-191`). `update()` invalidates the plugin cache
  (`src/core/core.controller.js@v4.6.1:488`). The next notify reads `config.plugins` again
  (`src/core/core.plugins.js@v4.6.1:101-106`, `:125-144`) and calls `stop` and `start` for each id
  that left or came (`:113-119`). The constructor reads `platform` once
  (`src/core/core.controller.js@v4.6.1:136`).
- `chart.update()` animates an equal value: `_createAnimations` has no equality test
  (`src/core/core.animations.js@v4.6.1:99-106`).

Reduced motion. Upstream has no reduced-motion code. Chart.js ADR 0019 §10 (0019:654-668) leaves
the policy to the widget of phase 9. Its Open item "Reduced motion" (0019:1086-1093) lists three
candidates: `animation: false` in a port-only scope, a flag for each chart read in
`_createAnimations`, and `'themeFrame'` for theme switches only. 0019:664-665 states that each
candidate fits into one hunk of `core.animations.dart` or into the options of the widget, with no
change to that decision. Flutter runs an `AnimationBehavior.normal` animation at 0.05 of its
duration under `disableAnimations` (`animation/animation_controller.dart:651`). theming.md §11:
theme removal under the preference animates for 1000 ms. The probe of the flag (`motion.out`, case
C2) gives one draw, `onComplete` 1, `onProgress` 0 and no `Animation` object for an update of 1000
bars. The same update with `animation: false` (C1) gives `onComplete` 0. Thus the text of Chart.js
ADR 0019 alternative 26, "`onComplete` and `onProgress` still run", is wrong for `onProgress`.

## Decision

### 1. The widget

`lib/src/widgets/chart_view.dart` (port-only, `// Original code, not ported from Chart.js: the
public chart widget.`) declares `ChartView`. The app library exports it (Chart.js ADR 0048 §5).

```dart
/// Shows one Chart.js chart: `new Chart(canvas, config)` on a canvas that the
/// widget owns. Register the components first: `Chart.register(registerables)`.
class ChartView extends StatefulWidget {
  /// Creates a widget that shows the chart of [config].
  const ChartView({required this.config, this.updateMode, this.onChartCreated,
      /* the parameters of section 8 */ super.key});

  /// The raw configuration `{type, data, options, plugins, platform}`
  /// (`jsonDecode` output works). The chart writes into its `data` and
  /// `options` Maps, as `initConfig` does. A new Map updates the chart.
  final Map<String, Object?> config;

  /// The mode of the `chart.update` call for a new [config]. Null is the
  /// default mode.
  final String? updateMode;

  /// Called after the frame in which the widget starts a chart, and again
  /// after a new `platform` replaces the chart.
  final ValueChanged<Chart>? onChartCreated;
}
```

The `State` class is private. The app gets the chart through `onChartCreated`, the return value
of `new Chart`. A `destroy` sets `chart.canvas` to null and calls `afterDestroy`
(`src/core/core.controller.js@v4.6.1:937-954`), so a kept chart shows its end.

### 2. The life cycle

1. `initState` makes one `UiCanvasElement` for the life of the `State` (Chart.js ADR 0016:300).
2. `build` reads `TickerMode.valuesOf(context).enabled`, `MediaQuery.maybeDisableAnimationsOf`
   (section 7) and the theme of Chart.js ADR 0050. It returns the internal host with the canvas,
   `onTickerModeChanged` and the internal `onFirstLayout`, inside the wrappers of section 8.
3. `onFirstLayout` starts the chart, in the first layout of the host. It does nothing when the
   `State` has a chart. It builds the root Map of section 4, calls `Chart(canvas, root)`, calls
   `animator.mute(chart)` under `TickerMode(enabled: false)`, and adds a post-frame callback that
   calls `onChartCreated`. An exception goes to `FlutterError.reportError`, and the host still
   sets its size. A post-frame callback then destroys the partial chart of the canvas
   (`Chart.getChart(canvas)`), so that the next new config can start the chart (section 4).
4. `onTickerModeChanged` calls `animator.mute` or `animator.unmute`, as
   `apps/chartjs_gallery/lib/demo/chart_canvas.dart:82-93` does.
5. `didUpdateWidget` and `didChangeDependencies` schedule the update of section 4.
6. `dispose` calls `chart.destroy()` and then `canvas.getContext2d().dispose()`.

`ChartHost` and `RenderChartHost` get one internal parameter `VoidCallback? onFirstLayout`.
`_performLayout` calls it in the branch of the first layout, after `_laidOut = true` and
`_reportConnection()` (`lib/src/platform/chart_host.dart:633-640`). Thus the chart finds the host
laid out, gets `FlutterPlatform`, attaches in its constructor and takes its size in frame 1. The
rule of Chart.js ADR 0016:348 then also covers the start hooks (section 6).

### 3. Keys and diagnostics

- A new key gives a new `State`, a new canvas and a new chart. A `GlobalKey` move keeps the
  `State`, the canvas and the host render object: Chart.js ADR 0037 §4 gives no attach change. A
  new host that takes over the canvas in the same frame calls `onFirstLayout` again, and the
  `State` with a chart ignores it.
- `ChartView.debugFillProperties` adds `DiagnosticsProperty<Object?>('type')`,
  `IntProperty('datasets')` (the length of `config.data.datasets` when it is a List), the theme
  property of Chart.js ADR 0050, `StringProperty('updateMode', defaultValue: null)` and
  `ObjectFlagProperty<ValueChanged<Chart>>.has('onChartCreated')`. The private `State` adds the
  chart `id`, `attached`, the size, `muted` and `reducedMotion`. No property prints the config
  Map.

### 4. A new config

- **The root Map.** The widget gives `Chart` a shallow copy of `config` that it owns. `data` and
  `options` keep their identity. The root also holds the entries that Chart.js ADRs 0050 and 0051
  add: `$theme` and the internal widget plugin in `plugins`.
- **The change test is identity.** `!identical(oldWidget.config, widget.config)` schedules one
  post-frame callback, none when one is pending. The same Map gives no update.
- **The update** runs in that post-frame callback and reads the last `widget.config` (`c`):
  1. `chart.config.type = c['type']` when not identical (`src/core/core.config.js@v4.6.1:173-175`);
  2. `chart.data = c['data']` when not identical (`src/core/core.controller.js@v4.6.1:217`);
  3. `chart.options = c['options']` when not identical (`:225`);
  4. the root `plugins` gets the app list of `c['plugins']` and the widget entries, when
     `c['plugins']` is not identical to the last app list;
  5. when `c['platform']` is not identical: `destroy`, a new chart on the same canvas with the same
     root, then `onChartCreated`;
  6. else `chart.update()` (the JS `undefined` mode) when `updateMode` is null or when the
     preference of section 7 turned on, or `chart.update(updateMode)`.

  A theme change of Chart.js ADR 0050 and a preference change of section 7 use the same callback.
  Thus a frame has at most one `update` call from the widget. A `State` with no chart, after a
  failed start, starts the chart in this callback. A `State` whose host has not had its first
  layout does nothing: the first layout starts the chart with the last config.
- **Plugins.** A new `plugins` value follows the upstream path: the next `update` reads the list
  again and calls `stop` and `start`. The chart, its hidden datasets and its animations stay. Only
  a new `platform` makes a new chart.
- **Docs.** The dartdoc of `config` and the README state these rules:
  - a new config Map updates the chart after the frame; the same Map gives no update;
  - after a change in place, call `chart.update()` from an event handler or a post-frame callback,
    never from `build`;
  - a change of a data List in place calls `notifyArrayListeners(list, key, args)` for `push`,
    `pop`, `shift`, `splice` and `unshift` (row `platform-array-events`), then `chart.update()`;
  - keep the dataset Maps to keep the metas, the hidden datasets and the animations; new dataset
    Maps give new metas, as upstream;
  - a nested Map literal of a config needs the type `<String, Object?>`: the chart writes into it;
  - a parent that rebuilds in each frame keeps its config in its `State`, or uses
    `updateMode: 'none'`;
  - an `onHover` that calls `setState` compares the value first;
  - an imperative `chart.options` edit lasts until the next new `options` object. A theme switch
    keeps it, except an edit inside `chart.options.scales.<id>` (Chart.js ADR 0050).

### 5. The size

`ChartView` has no size parameter. The constraints and the options `responsive`,
`maintainAspectRatio` and `aspectRatio` give the size, by the rules of Chart.js ADR 0037 §5
(`lib/src/platform/platform.flutter.dart:560-612`):

| Constraints | Default options | Size |
|---|---|---|
| Bounded width and height (`SizedBox`, `Expanded`) | `maintainAspectRatio: true` | the box width; the height `width / aspectRatio`, capped at the box height (then the width from the height) |
| Bounded width, unbounded height (`Column`, `ListView`) | the same | the box width; the height `width / aspectRatio` |
| Unbounded width | the same | 300 wide, or the bounded height and the aspect ratio |
| Any | `maintainAspectRatio: false` | the box; an unbounded side takes 300 or 150 |
| Any | `responsive: false` | the canvas size: 300 x 150, or 300 x 300 for the aspect ratio 1 |

The dartdoc and the README give three forms: a `Column` or a scroll view (the aspect ratio gives
the height), `SizedBox(height: h)` with `maintainAspectRatio: false`, and `Expanded` with
`maintainAspectRatio: false`. A later size parameter is an addition.

### 6. Event callbacks

The app gives `onHover`, `onClick` and `onResize` as function values in the options, and plugin
hooks in plugin Maps, as upstream. `ChartView` has no Flutter event callback in 0.1.0. A typed
closure works with JS arity (`lib/src/js/js_function.dart:112-144`):
`'onClick': (ChartEvent event, List<ActiveElement> elements, Chart chart) {...}`. The app library
exports these types (Chart.js ADR 0048 §4 and §5).

The dartdoc of `ChartView` and the README give this table:

| Callback | Phase | `setState` |
|---|---|---|
| `onHover`, `onClick`, plugin `beforeEvent` and `afterEvent` of an input | throttled frame callback | allowed |
| `onResize` and plugin `resize` after a size change | throttled frame callback | allowed |
| animator `onProgress`, `onComplete`, `afterRender` | animator frame callback | allowed |
| all hooks of a widget update, the replayed `onHover` (section 4) | post-frame callback | allowed |
| `onChartCreated` | post-frame callback | allowed |
| the start: `install`, `start`, `beforeInit`, `afterInit`, the hooks of the first update, scriptable options, the first `onResize` and `resize`, `onComplete` of a first render with no animation | first layout of the host | not allowed |
| `attach` and `detach` of an attach change or a canvas swap | layout or build | not allowed |
| `beforeDestroy`, `afterDestroy`, `stop`, `uninstall` at the unmount | `dispose` | not allowed |

In a "not allowed" phase, the app calls `WidgetsBinding.instance.addPostFrameCallback`. The
events reach the chart in a throttled frame callback (`lib/src/platform/platform.flutter.dart:384-399`,
`:341-348`). This extends the rule of Chart.js ADR 0016:348 to the start hooks.

### 7. Reduced motion

This section states the decision of the Open item "Reduced motion" of Chart.js ADR 0019
(0019:1086-1093): **candidate 2, a flag read in each `_createAnimations` call, with the flag
keyed by the canvas.**

- `lib/src/core/reduced_motion.dart` (port-only, pure, `// Original code, not ported from
  Chart.js: the reduced-motion flag.`) declares
  `void setReducedMotion(Object canvas, {required bool enabled})` and
  `bool isReducedMotion(Object? canvas)` on an `Expando<bool>`. No public library exports it.
- One hunk in `Animations._createAnimations` of `lib/src/core/core.animations.dart`
  (`src/core/core.animations.js@v4.6.1:68`, `:88`): `final reduced = isReducedMotion(_chart.canvas);`
  before the loop, and `final cfg = reduced ? null : animatedProps[prop];`, with the marker of the
  row `platform-reduced-motion`.
- With the flag, `_createAnimations` reads no animation config. Each value goes to its target at
  once (`:99-103`), and a running animation of the property ends (`:94-97`). `Animations.update`
  starts no animation (`:125-130`), so `render()` draws at once and calls
  `onAnimationsComplete` (`src/core/core.controller.js@v4.6.1:683-696`, `:33-39`). `onComplete`
  runs once for each render, and `onProgress` does not run. The flag covers each `Animations`
  object of the chart: the element properties and options of each dataset controller
  (`src/core/core.datasetController.js@v4.6.1:856`) and the tooltip
  (`src/plugins/plugin.tooltip.js@v4.6.1:517`).
- Only `ChartView` sets the flag. `build` calls
  `setReducedMotion(canvas, enabled: MediaQuery.maybeDisableAnimationsOf(context) ?? false)`
  before the start. The canvas key lets the first `update()` of the constructor read the flag, so
  the start needs no second update. No spec and no reference test sets the flag.
- The widget never writes `defaults`, `overrides` or `defaults.animation`, and it changes no
  option of the app config for reduced motion (Chart.js ADR 0019:666-667).
- When the preference turns on while a chart exists, the post-frame callback of section 4 calls
  `chart.update()` in the default mode. A running or looping animation then ends at its target.
  When the preference turns off, the widget makes no update. The next update animates.
- A theme switch under the preference keeps `update('themeFrame')`, and a theme removal keeps
  `update('default')` (Chart.js ADR 0042:150-153). Both end at once. Thus the 1000 ms removal of
  theming.md §11 goes, with no transitions-only scope.
- An app that wants motion under the preference wraps the widget in a `MediaQuery` with
  `disableAnimations: false`.
- The night measurement A-N3 decides the form of the read (Evidence): the `Expando` read lands
  when the upper end of each interval of B − A is below 0.1 ms on the Pixel 8a, macOS and Chrome
  with dart2wasm. Else a port-only `bool` field of `UiCanvasElement`, read through a type test,
  lands by the same rule. Else the porting lead opens this section again with the figures.
- The result of A-N3 (night 1, [performance.md](../performance.md) §15.3): by its rule, the
  `Expando` read did not land on any deciding platform. Each platform has primary upper ends
  above 0.1 ms, and macOS has h = 4 control hits of 2 to 9 µs (h* = 3). But no
  primary interval lies wholly above 0 on any platform, and the bound of 0.1 ms is 0.02 to 0.06 %
  of the A mean at N 20000, below the noise of the night. The field of `UiCanvasElement` was not
  built. Thus the porting lead opened this section again (2026-10-30) and kept the `Expando`
  read: it is one `Expando` lookup in each `_createAnimations` call, and the field changes a
  canvas class for a gain that no night can resolve. This is the decision of this section.

### 8. Parts that Chart.js ADRs 0050 and 0051 decide

This ADR does not decide these parts. It gives them the root Map and the post-frame callback of
section 4, and the host of section 2.
- **Chart.js ADR 0050 (theme API):** the parameter `theme` (`ChartThemeData?`, null reads the
  inherited theme), the entry `$theme` of the root Map, the internal widget plugin for the palette
  restore, the in-place restore of the user scales, the update modes `'theme'`, `'themeFrame'`
  and `'default'`, the theme property of the diagnostics, and the theme part of the README. The
  theme update runs in the post-frame callback of section 4, not in `didUpdateWidget`.
- **Chart.js ADR 0051 (input events and interaction state):** the parameters `focusNode`,
  `autofocus`, `semanticLabel` and `excludeFromSemantics`, the `Focus` and `Semantics` wrappers of
  the host, the keys, the focus ring of the widget plugin, and the `keydown`, `keyup` and
  `keypress` events. Its callbacks follow the table of section 6.

### 9. Rows, tests and measurements

- New `differences.md` row `platform-reduced-motion` (platform,
  `src/core/core.animations.js@v4.6.1:68, 88-103`): for a canvas with the flag, `_createAnimations`
  reads no animation config. Only `ChartView` sets the flag. The widget code is port-only: no other
  row. `platform-array-events` keeps its text.
- `test/port/widgets/chart_view_test.dart` (`@TestOn('vm')`) pins sections 2 to 7, and a group
  `platform-reduced-motion` of `test/port/core/core.animations_test.dart` pins the hunk. All
  animation specs and the 8 controller reference files pass unchanged.
- The gate of this ADR: the tests pass, and the figures of A-N1 (the widget overhead) and A-N3
  (the read of the flag) are in `performance.md`. Night 1 recorded both figures in
  [performance.md](../performance.md) §15.

## Alternatives considered

- **The start at the mount of the host** (in `createRenderObject` or `initState`). The chart starts
  detached and loses its animator listeners. Rejected on criterion 1.
- **The start in a post-frame callback** (the gallery form). Frame 1 shows the canvas default, and
  the widget below moves by 50 px in frame 2. A chart with `animation: false` paints one frame
  later. Rejected on criteria 1 and 2.
- **A `ChartViewController` or a `GlobalKey` with a public `State`.** More public names and more
  code. A controller can come later as an addition. Rejected on criteria 4 to 6.
- **The update in `didUpdateWidget`.** A common `onHover` readout with `setState` throws in debug,
  through the replay of the last event. Rejected on criteria 1 and 5.
- **A new chart for a new `plugins` value.** It loses the hidden datasets and the animations, and
  upstream keeps the chart. Rejected on criteria 1 and 2.
- **An assert for a new `plugins` value.** A release build then keeps the old plugins. Rejected on
  criterion 1.
- **Deep equality of the configs.** It walks O(points) in each rebuild and misses changes in place.
  Rejected on criteria 2 and 4.
- **An explicit update only.** Each app then writes the setter calls. An automatic update later
  changes the apps that rebuild. Rejected on criteria 5 and 6.
- **A `height` or `aspectRatio` parameter, or a widget that always fills its box.** The options
  already give the size, and Flutter gives `SizedBox`, `Expanded` and `AspectRatio`. Rejected.
- **Flutter event callbacks through a plugin or written into the options.** They copy the upstream
  filters, add a plugin to each notify and change the hook order. Rejected on criteria 1 to 4.
- **Reduced motion as `animation: false` in a port-only scope** (Chart.js ADR 0019 candidate 1,
  alternative 27). It changes a resolved option and silences `onComplete`. Rejected on criterion 1.
- **`'themeFrame'` for theme switches only** (candidate 3). Charts animate under the preference,
  as upstream does, and the 1000 ms removal stays. Rejected on criteria 2, 5 and 6.
- **A flag keyed by the chart, with a second `update()` after the start.** The constructor runs
  `update()` before the widget gets the chart (`lib/src/core/core.controller.dart:601-676`), so the
  first update animates. Rejected on criterion 4.
- **Durations times 0.05, the Flutter form.** It changes each duration and speeds up the loops.
  Rejected on criterion 1.

## Consequences

- The chart is attached from its constructor and has its size in frame 1, as upstream. The
  `setState` rule of Chart.js ADR 0016:348 covers the start hooks. Flutter reports a break in
  debug.
- A new config shows one frame later only for a non-animated update.
- Under the preference, no chart of a `ChartView` animates: no entry animation, no hover
  transition, no tooltip fade, no theme transition. The end values, the resolved options and the
  `onComplete` contract stay those of a config whose durations are 0.
- Chart.js ADR 0019 §10 keeps the core without reduced-motion code until phase 9, and 0019:664-665
  allow the hunk of section 7. Chart.js ADR 0019 does not change.
- The widget changes `chart_host.dart`, which `canvas-cuts-plan.md` cites. The same commit updates
  the references of the plan.
- The gallery uses `ChartView` on its type pages. `ChartCanvas` stays as the side A of A-N1 until
  the night record.
- A-N1 (night 1, [performance.md](../performance.md) §15.2) gives PASS on macOS, the Pixel 8a and
  the VS Code browser, and on the added iPhone 17 Pro: no interval of B − A of `buildP50Ms` or
  `rasterP50Ms` lies wholly above 0.1 ms. The largest lower end is +0.0744 ms (Pixel 8a,
  `line-1000`, raster, with a mean of +0.27 ms). That cell is fragile: without pair 1 or pair 6 of
  its 9 pairs, or without the pairs after a battery gate with `pass=0`, its interval lies wholly
  above 0.1 ms. The porting lead ruled that those pairs stay valid (the night protocol §5.3, the
  precedent of performance.md §13.6). Each Pixel 8a run had the semantics on (an accessibility
  service of the phone), so the Pixel 8a effect cannot be separated from the semantics work. A
  record run with the service off is open.

## Open

1. **Intrinsic sizes before the start.** An `IntrinsicHeight` parent or a dry layout sees
   300 x 150 before the start (`lib/src/platform/chart_host.dart:597-613`,
   `lib/src/canvas/canvas_ui.dart:242-243`). A fix needs `getMaximumSize` before the chart exists.
   Trigger: a user report.
2. **A controller object and typed widget callbacks.** Both are later additions. Trigger: an app
   request.
3. **The read of the flag.** A-N3 decides between the `Expando` and the field of `UiCanvasElement`
   (section 7). Closed on 2026-10-30: A-N3 did not land the `Expando` read by its rule, and the
   porting lead kept it by the fallback of the rule ([performance.md](../performance.md) §15.3).
4. **Unverified start facts.** An error of the start is reported and the host keeps a size, and a
   start in the layout also starts a chart in an offstage overlay entry
   (`widgets/overlay.dart:980-982`). The tests of section 9 check both.

## Evidence

The working files of phase 9 in `.handover/phase9/panel/` (not committed):
- `brief.md` (the items A7-A11), the drafts `a-fidelity.md`, `a-performance.md` and
  `a-simplicity.md`, the verdicts `judge-a.md` (sections 0.1, A7-A11) and the interfaces of
  `judge-b.md`.
- `probes/a-judge/j2_widget_probe.out` with `j2_chart_host.diff` and
  `j2_widget_probe_test.dart.txt` (J2: the frame of the first draw for each start and update form,
  and the `setState` of `afterInit`).
- `probes/a-performance/start/first_frame.out` (T1, T2, T4: the host size in frames 1 to 3),
  `start/complete.out` (the entry animation callbacks), `motion/motion.out` (C1, C2: the flag and
  `animation: false`).
- `probes/a-fidelity/p_mount_create_probe_test.out` and `mount_create_probe_test.dart.txt` (the
  detached start at the mount).
- `probes/a-simplicity/p6-widget/result.txt` with `chart_view.dart`, `reduced_motion.dart` and
  `core.animations.diff` (the layout shift, the replay in the build, the `onHover` loop, the flag
  before the first update).
- Flutter 3.47.7: `widgets/binding.dart:1436`, `widgets/framework.dart:5367`,
  `widgets/media_query.dart:2026` (`maybeDisableAnimationsOf`),
  `animation/animation_controller.dart:651`.
- The night series A-N1 to A-N6: protocols written before the first run, figures in
  `performance.md` (phase 9). Night 1 (2026-10-29 to 2026-10-30) ran A-N1 and A-N3:
  [performance.md](../performance.md) §15.
