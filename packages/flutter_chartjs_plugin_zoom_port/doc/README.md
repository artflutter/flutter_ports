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
  libraries ([Zoom ADR 0003](adr/0003-host-connection.md)).
- **Host seams:** [host-seams.md](host-seams.md) lists each use of the host with its state. On
  2026-10-30, 7 seams connect, 4 need only a Dart form in the zoom port, 11 need a host change and
  2 need a test.
- **Progress:** [parity.md](parity.md), one row for each upstream file.
- **Differences:** [differences.md](differences.md), one row for each `DIVERGES` difference. It
  has no rows in phase 0.
- **Upstream after the pin:** [upstream-ledger.md](upstream-ledger.md).
- **Prior art:** the survey file of the zoom and pan code of other Dart and Flutter packages
  comes in a later change. Prior art is never a source (AGENTS.md rule 1).
- **Test harness:** `packages/chartjs_test_utils`, a dev dependency from phase 2 (ADR 0009 item 7).
- **Gallery:** a zoom page in `apps/chartjs_gallery`, from phase 4 (ADR 0009 item 8).
- **License:** MIT, as upstream ([LICENSE](../LICENSE)).

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
  libraries only, host changes first, the Dart forms of the DOM uses.
- [ADR 0009: Ports of add-on libraries](../../../docs/adr/0009-add-on-ports.md) (proposed): the
  rule for all add-on ports.

The rules of the Chart.js port (AGENTS.md) apply, with the changes of these ADRs. The porting
flow of the Chart.js port applies to each module: `packages/flutter_chartjs_port/doc/porting-flow.md`
§1 (the life cycle) and §4 (the checks).

## Roadmap

Each phase ends with green checks of the whole workspace. A phase that changes the host port also
runs the checks of the host (AGENTS.md, "Before a push").

| Phase | Content | Exit |
|---|---|---|
| 0 | Scaffold: the package, the pin, the checks, the ADRs, the seam list, then the prior-art survey file. | The scaffold and the docs are in. The survey file follows. |
| 1 | Host changes for the input path: H2, H3, H6, H7, H4 with H5, and H8, each with a Chart.js ADR, host tests and a row update in `host-seams.md`. | The seams H2 to H8 are `connects`. The Chart.js port passes its checks. |
| 2 | The JS runtime (H13, ADR 0008 stage 1 or a host export). The pure modules: `types`, `options`, `defaults`, `state`, `utils`, `scale.types`, `core`, with `src/*.test.ts` and `test/specs/api.spec.js`. | `api_test.dart`, `utils_test.dart` and `scale.types_test.dart` pass. |
| 3 | The input modules: `handlers` and `gestures`, the set-up `test/flutter_test_config.dart` (H23), the specs `zoom.wheel`, `zoom.drag`, `pan`, `zoom.pinch` and `gestures`. | The five specs pass. |
| 4 | The plugin: `plugin`, `index`, `index.umd`, the specs `defaults`, `module` and `fixtures`, the 12 hand fixtures (H24), the check of H17, the zoom page of the gallery (H20), a device check of H8 on Android and iOS. | All upstream cases pass or have a reason. |
| 5 | The app surface: the typed options slot (H18) and the theme extension (H19), after their host decisions. | The README shows the typed form. |
| 6 | Release 0.1.0, after the release of `flutter_chartjs_port`, and the bump to the upstream tag of the next release (Zoom ADR 0001 item 7). | — |
