# chartjs-plugin-zoom port

`packages/flutter_chartjs_plugin_zoom_port` is a native Dart port of
[chartjs-plugin-zoom](https://github.com/chartjs/chartjs-plugin-zoom), the zoom and pan plugin of
Chart.js. The plugin runs on the Chart.js port `packages/flutter_chartjs_port`. It is the first
add-on port of the repository ([ADR 0009](../../../docs/adr/0009-add-on-ports.md)). The port has
two goals: the plugin for Flutter apps, and a test of the connection between a third-party plugin
and the public API of the Chart.js port.

- **Upstream:** chartjs-plugin-zoom, MIT, the commit `fb81d331` of `master` (2026-10-02), 34
  commits after the release `v2.2.0`. The version is the commit pin `2.2.0+fb81d331`
  ([Zoom ADR 0001](adr/0001-upstream-sources.md)). The release `v2.2.0` needs Hammer.js. The
  pinned commit uses the DOM Pointer Events.
  - `third_party/chartjs-plugin-zoom` is the shallow git submodule.
    [`tool/port_sources.yaml`](../tool/port_sources.yaml) gives the commit, the license and the
    holder.
  - `chartjsPluginZoomVersion` in `lib/src/upstream.dart` gives the version.
  - `dart run melos run upstream` clones the submodule. `dart run melos run upstream:check`
    compares the gitlink with the pin.
- **Host:** `flutter_chartjs_port`, a path dependency. The zoom port imports only its public
  libraries, `js_semantics.dart` among them ([Zoom ADR 0003](adr/0003-host-connection.md)).
  [Chart.js ADR 0108](../../flutter_chartjs_port/doc/adr/0108-input-surface-and-exports-for-add-on-plugins.md)
  is the host change for the zoom port: the input surface of the canvas, the JS runtime and the
  typed plugin API.
- **Host seams:** [host-seams.md](host-seams.md) lists each use of the host with its state and
  the tests that pin it. At the end of zoom phase 4 (2026-11-10), 18 seams connect, 6 need only a
  Dart form in the zoom port and 3 wait for later host decisions (H18, H19, and H27, the trackpad
  of a native desktop app). H28, the range update of Chart.js ADR 0111, connects since the same
  day.
- **Progress:** [parity.md](parity.md), one row for each upstream file.
- **Differences:** [differences.md](differences.md), one row for each `DIVERGES` difference.
- **Upstream after the pin:** [upstream-ledger.md](upstream-ledger.md).
- **Prior art:** [prior-art/README.md](prior-art/README.md), the survey of the zoom and pan code
  of other Dart and Flutter packages (2026-11-10). Prior art is never a source (AGENTS.md rule 1).
- **Test harness:** `packages/chartjs_test_utils`, a dev dependency from phase 2 (ADR 0009 item 7).
  `test/flutter_test_config.dart` ports the set-up of `test/index.js` with its event helpers. The
  specs dispatch synthetic DOM events on the canvas. The port-only tests of `test/port/` also drive
  a `ChartView` with the pointer and key events of Flutter.
- **Gallery:** the zoom page of `apps/chartjs_gallery` (phase 4, ADR 0009 item 8).
- **License:** MIT, as upstream ([LICENSE](../LICENSE)).

## The option `rangeOnlyUpdates`

The port has one option that upstream does not have: `plugins.zoom.rangeOnlyUpdates`, a `bool` with
no default (an absent key is `false`). With `true`, each zoom and pan step updates the chart with
`chart.updateRanges(transition)` of the host
([Chart.js ADR 0111](../../flutter_chartjs_port/doc/adr/0111-range-updates.md)) in place of
`chart.update(transition)`. The range update keeps the configuration of the last full update and
skips its rebuild; each hook, the layout, the dataset updates and the draw run as in `update`, and
each scriptable option that these steps read runs again. The ranges, the ticks, the points and the
pixels are those of `update`. The options that only the skipped steps read (`responsive`, the chart
`indexAxis`, the `axis` and `position` of a scale) keep the results of the last full update.

```dart
ChartView(
  config: ChartConfig(
    // ...
    extra: {
      'plugins': {
        'zoom': {
          'zoom': {'wheel': {'enabled': true}, 'pinch': {'enabled': true}},
          'pan': {'enabled': true},
          'rangeOnlyUpdates': true,
        },
      },
    },
  ),
)
```

The app keeps the contract of `updateRanges`: between the full updates of the chart, nothing
changes an option, a default (`Chart.defaults`, `Chart.overrides`), the theme, a dataset, a scale
or a plugin in place, and no plugin is registered or unregistered. New data values, a new data List and new labels are allowed. A `ChartView`
keeps the contract: a new config, a new theme and a change of the reduced-motion preference reach
the chart through a full update. An app that writes `chart.options` or a dataset Map in place calls
`chart.update()` after the write. The host takes `update` by itself when one of its checks fails:
another class of chart, config or controller, a plugin that does not opt into the partial
lifecycles, a notified change of a data array, another `data`, `options` or dataset object, another
chart type or another inline plugin List, or an update since which the state is not valid (a resize, a visibility change, a cancelled update). Row
`adapt-range-only-updates` of [differences.md](differences.md), seam H28.

## What gets ported

| Upstream (at the pin) | Files | Lines | Cases |
|---|---:|---:|---:|
| `src/*.ts` | 12 | 1,913 | — |
| `src/*.test.ts` | 2 | 133 | 6 `it` calls |
| `test/specs/*.spec.js` | 9 | 2,367 | 62 `it` calls |
| `test/fixtures/{pan,zoom}/*.js` | 12 | — | 12 fixtures, each with a PNG image |
| `test/index.js` | 1 | 143 | — |

The counts come from `wc -l` and from a count of the lines that start with `it(` or `xit(`. A loop
in a spec can make more cases than its `it` calls.

## Decisions

- [Zoom ADR 0001: Upstream source, name and license](adr/0001-upstream-sources.md) (proposed):
  the commit pin, the name `flutter_chartjs_plugin_zoom_port`, the MIT notice, the harness.
- [Zoom ADR 0002: File naming and package layout](adr/0002-file-naming-and-layout.md) (proposed):
  `src/<name>.ts` to `lib/src/<name>.dart`, the specs, the set-up, the fixtures, `zoomPlugin`.
- [Zoom ADR 0003: The connection to the host port](adr/0003-host-connection.md) (proposed): public
  libraries only, host changes first, the Dart forms of the DOM uses, the typed plugin object, the
  option facades, the numeric limits and the data-only opt-in.
- [ADR 0009: Ports of add-on libraries](../../../docs/adr/0009-add-on-ports.md) (proposed): the
  rule for all add-on ports.
- [Chart.js ADR 0108: The input surface and exports for add-on plugins](../../flutter_chartjs_port/doc/adr/0108-input-surface-and-exports-for-add-on-plugins.md)
  (accepted 2026-11-10): the host change of zoom phase 1.

The rules of the Chart.js port (AGENTS.md) apply, with the changes of these ADRs. The porting
flow of the Chart.js port applies to each module: `packages/flutter_chartjs_port/doc/porting-flow.md`
§1 (the life cycle) and §4 (the checks).

## Roadmap

Each phase ends with green checks of the whole workspace. A phase that changes the host port also
runs the checks of the host (AGENTS.md, "Before a push").

Phases 1 to 4 are done (2026-11-10). One item stays open: the device check of H8 of phase 4 on
Android and iOS (Chart.js ADR 0108 Open 1), which needs a device run of the gallery page. Phase 5
is next.

| Phase | Content | Exit | State |
|---|---|---|---|
| 0 | Scaffold: the package, the pin, the checks, the ADRs, the seam list, then the prior-art survey file. | The scaffold and the docs are in. The survey file follows. | Done 2026-10-30. The survey file: done 2026-11-10. |
| 1 | The host change of Chart.js ADR 0108: the input path (H2 to H8), the JS runtime `js_semantics.dart` with `jsHypot` (H13), the typed plugin API (H16) and the harness (H23), with host tests and a row update in `host-seams.md`. The port checks `check:lib-imports`, `check:headers` and `check:js-semantics` examine the zoom package (ADR 0009 item 6). | The seams H2 to H8, H13, H16 and H23 are `connects`. The Chart.js port passes its checks. | Done 2026-11-10 (Chart.js ADR 0108 accepted). |
| 2 | The pure modules: `types`, `options`, `defaults`, `state`, `utils`, `scale.types`, `core`, with `src/*.test.ts`, and the base of the set-up `test/flutter_test_config.dart`. | `utils_test.dart` and `scale.types_test.dart` pass. | Done 2026-11-10. |
| 3 | The input modules `handlers` and `gestures`, the plugin `plugin`, `index` and `index.umd` (the input specs need the registered plugin), the helpers of the set-up (H23), the specs `api`, `defaults`, `module`, `zoom.wheel`, `zoom.drag`, `pan`, `zoom.pinch` and `gestures`, the check of H17 and the test of the data-only opt-in (H25). | The specs pass or have a reason. | Done 2026-11-10: the 83 cases of the 8 specs pass, with no skip. |
| 4 | The fixtures: the 12 hand fixtures with the comparison of the scale ranges (H24). The zoom page of the gallery (H20). The tests of real input on a `ChartView`. A device check of H8 on Android and iOS. | All upstream cases pass or have a reason. | Done 2026-11-10: the fixtures, the gallery page and the tests of real input (`test/port/handlers_test.dart`, `gestures_test.dart`, `index_test.dart`). The device check of H8 is open. |
| 5 | The app surface: the typed options slot (H18), with the typed plugin in the inline plugins of a typed config, and the theme extension (H19), each after its Chart.js ADR. | The README shows the typed form. | Open. |
| 6 | Release 0.1.0, after the release of `flutter_chartjs_port`, and the bump to the upstream tag of the next release (Zoom ADR 0001 item 7). | — | Open. |
