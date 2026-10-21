# ECharts port differences

This file lists the hunks of ported code that do not translate the upstream lines
([porting-flow.md](porting-flow.md) §4). Each hunk carries the line comment
`// DIVERGES(echarts): <ID>, <reason>`. From phase 1, tool 2 pairs each marker with a row of this
file ([ADR 0008](../../../docs/adr/0008-shared-js-runtime-and-port-tools.md)). A port-only file is
not a row. A hunk of a port-only file that gives the difference of a row carries the marker of
that row.

One marker form covers both repositories, Apache ECharts and zrender
([ECharts ADR 0001](adr/0001-upstream-sources.md)). ADR 0008 item 8 (the config value of the
`DIVERGES` tag) gives one tag and one `differences.md` to each port config. The Upstream column of a row names the repository.

The ID starts with its category: `adapt`, `platform`, `js-semantics`, `harness` or
`not-followed`. The port has no `theme` category. ECharts has themes for each chart instance. Thus
the Flutter themes of the port change no upstream line
([ECharts ADR 0009](adr/0009-dom-features-app-hooks-and-theming.md)). A skip reason
`'diverges: <ID>'` names a row.

The Upstream column names the repository, the path, the tag and the lines. Examples:
`echarts src/util/number.ts@6.1.0:222-237` and `zrender src/core/env.ts@6.1.0:41-47`. The tags
have no `v` prefix. Under a commit pin, the version is `6.1.0+<sha8>`.

The ECharts ADRs reserve these IDs. A row with the ID comes with the change that ports the hunk.

| ID | The difference | ADR |
|---|---|---|
| `platform-env-detect` | `zrender src/core/env.ts` gives fixed values in place of the browser detection | [ECharts ADR 0007](adr/0007-environment-host-and-input-events.md) |
| `platform-request-anim-frame` | `zrender src/animation/requestAnimationFrame.ts` uses a frame hook of the Flutter layer | [ECharts ADR 0006](adr/0006-renderer-and-canvas-layer.md) |
| `platform-zr-viewport` | `zrender src/canvas/Painter.ts` `createRoot` makes a `ZrViewport` in place of a `div` | [ECharts ADR 0006](adr/0006-renderer-and-canvas-layer.md) |
| `platform-animation-mute` | `zrender src/animation/Animation.ts` requests no frame while `TickerMode` is off | [ECharts ADR 0006](adr/0006-renderer-and-canvas-layer.md) |
| `platform-config-dpr` | `zrender src/config.ts` takes the DPR that the host sets | [ECharts ADR 0007](adr/0007-environment-host-and-input-events.md) |
| `platform-container-size` | `zrender src/canvas/helper.ts` `getSize` reads `root.computedStyle`, with no `document` | [ECharts ADR 0007](adr/0007-environment-host-and-input-events.md) |
| `platform-date-local-offset` | The local offsets come from `LocalZone`, with the platform limits of the shared row (Chart.js ADR 0024) | [ECharts ADR 0008](adr/0008-dates-locales-and-formatting.md) |
| `platform-navigator-platform` | `echarts src/model/globalDefault.ts:23-27` reads the settable `navigatorPlatform` | [ECharts ADR 0008](adr/0008-dates-locales-and-formatting.md) |
| `adapt-module-side-effects` | The top-level `use(...)` statements of the entry files become functions, for example `useAll()` | [ECharts ADR 0002](adr/0002-file-naming-and-layout.md) |
| `adapt-instance-mixin` | The instance mixin of `echarts src/coord/radar/RadarModel.ts:179` becomes a subclass | [ECharts ADR 0004](adr/0004-js-values-classes-and-options.md) |
| `adapt-legacy-extend` | The public `extend*` API waits until after 0.1.0 | [ECharts ADR 0004](adr/0004-js-values-classes-and-options.md) |
| `harness-canvas-mock-text` | The chart specs measure a text as its length, as jest-canvas-mock does | [ECharts ADR 0005](adr/0005-spec-harness-and-reference-tests.md) |
| `harness-dom-supported` | The specs run with `domSupported` false. Upstream ran them in jsdom | [ECharts ADR 0005](adr/0005-spec-harness-and-reference-tests.md) |
| `platform-data-url-async` | `getDataURL` and `getConnectedDataURL` return a `Future` | [ECharts ADR 0009](adr/0009-dom-features-app-hooks-and-theming.md) |
| `platform-heatmap-pixels` | The heatmap computes its intensity field in Dart in place of `getImageData` | [ECharts ADR 0009](adr/0009-dom-features-app-hooks-and-theming.md) |
| `platform-tooltip-html` | `renderMode: 'html'` gives the `richText` tooltip. `shouldTooltipConfine` tests the resolved render mode | [ECharts ADR 0009](adr/0009-dom-features-app-hooks-and-theming.md) |
| `platform-window-open` | Links go to an app hook `openLink` in place of `window.open` | [ECharts ADR 0009](adr/0009-dom-features-app-hooks-and-theming.md) |
| `platform-dataview-dom` | The toolbox DataView is a Flutter panel in place of DOM content | [ECharts ADR 0009](adr/0009-dom-features-app-hooks-and-theming.md) |
| `platform-geojson-function` | The GeoJSON fallback decodes JSON in place of `new Function` | [ECharts ADR 0009](adr/0009-dom-features-app-hooks-and-theming.md) |

Phase 0 ports no code. Thus the table below has no rows.

| ID | Dart file and symbol | Upstream file@version:lines | Category | Reason | Upstream reference | Pinning test | Re-check on bump |
|---|---|---|---|---|---|---|---|
