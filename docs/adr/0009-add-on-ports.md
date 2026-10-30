# ADR 0009: Ports of add-on libraries

- Status: proposed
- Date: 2026-10-30
- Gate: zoom phase 0. Phase 0 applies the package name, the dependency on the host port and the
  rule of item 3 while the ADR is proposed (the D3 and ECharts precedent).
- Related: [ADR 0001](0001-native-ports-not-wrappers.md) (native ports),
  [ADR 0005](0005-pin-upstream-sources.md) (the pins),
  [ADR 0007](0007-package-names.md) (the package names),
  [ADR 0008](0008-shared-js-runtime-and-port-tools.md) (the shared JS runtime, "no port depends on
  another port"),
  [Chart.js ADR 0048](../../packages/flutter_chartjs_port/doc/adr/0048-entry-points-and-public-library.md)
  (the public libraries of the Chart.js port),
  [Zoom ADR 0001](../../packages/flutter_chartjs_plugin_zoom_port/doc/adr/0001-upstream-sources.md)
  (the first add-on port),
  [Zoom ADR 0003](../../packages/flutter_chartjs_plugin_zoom_port/doc/adr/0003-host-connection.md)
  (the host connection of the first add-on port)

## Context

Some upstream libraries are add-ons of another upstream library. An add-on has its own repository,
license, release cycle and npm package. Its npm package has a `peerDependencies` entry on the
other library: the host. The add-on imports the public entry points of the host. Examples:

- chartjs-plugin-zoom has `"peerDependencies": {"chart.js": ">=3.2.0"}` (`package.json` at the
  pin of
  [Zoom ADR 0001](../../packages/flutter_chartjs_plugin_zoom_port/doc/adr/0001-upstream-sources.md)).
  Its sources import `chart.js` and `chart.js/helpers` (for example `src/handlers.ts:3-5`).
- chartjs-plugin-annotation, chartjs-chart-matrix, chartjs-chart-treemap and the date adapters
  have the same form.
- Apache ECharts has extensions too, for example echarts-gl and echarts-wordcloud.

The repository has three ports of host libraries: `flutter_chartjs_port`, `flutter_d3_port` and
`flutter_echarts_port`. On 2026-10-30, the maintainer selected chartjs-plugin-zoom as the first
port of an add-on. The goal is the port of the plugin, and a test of the connection between a
third-party plugin and the Chart.js port.

The rules of the repository do not cover an add-on:

- [ADR 0008](0008-shared-js-runtime-and-port-tools.md) item 1 (proposed) says "No port depends on
  another port." That rule is for ports of independent libraries, for example D3 and ECharts. A
  port of an add-on cannot run without the port of its host, as upstream cannot.
- [ADR 0007](0007-package-names.md) item 1 gives the name form `flutter_<library>_port`. It does
  not say if an add-on port is a "port" of item 1 or an adapter of item 5.
- The host port decides its public API. An add-on port that imports `src/` of the host reaches
  past that API. The `implementation_imports` lint of `very_good_analysis` flags such an import.

## Decision

1. **Add-on ports.** An add-on port is the port of an upstream library whose npm package has a
   peer dependency on a library that the repository ports: the host. The port of the host is the
   host port.
2. **The dependency.** An add-on port depends on its host port, as upstream depends on its host.
   This is a regular dependency in `dependencies`. It is a path dependency until both packages
   have a release. ADR 0008 item 1 applies to ports of independent libraries. An add-on port
   depends on no port other than its host port. A host port never depends on an add-on port.
3. **Public libraries only.** An add-on port imports only the public libraries of its host port.
   For the Chart.js port, these are the three libraries of Chart.js ADR 0048 §5:
   `flutter_chartjs_port.dart`, `chartjs.dart` and `helpers.dart`. An add-on port never imports
   `package:<host>/src/`. When the add-on needs a part of the host that the public libraries do not
   give, the host port gets a change: a new export, a new member or a new port-only API. Each such
   change has the decision of the host port (a host ADR, for example a Chart.js ADR). The add-on
   port records each need in its doc `host-seams.md` until the host change lands.
4. **The JS runtime.** An add-on port takes the JS runtime functions (for example `jsRound` or
   `jsLog10`) from the shared package of ADR 0008, `js_semantics`, when it exists. Until then, the
   add-on port waits, or the host port exports the functions that the add-on needs, by item 3.
   The add-on port does not copy the runtime.
5. **The name.** The library package of an add-on port takes the name of ADR 0007 item 1:
   `flutter_<library>_port`. `<library>` is the npm name of the add-on in lower case, with `_` in
   place of `-`. The first add-on port is `flutter_chartjs_plugin_zoom_port`. An add-on port is
   not a design-system adapter of ADR 0007 item 5: it ports upstream code.
6. **Docs, ADRs and checks.** An add-on port has its own `doc/` folder, its own ADRs (named
   "<Add-on> ADR NNNN", for example "Zoom ADR 0001"), its own `tool/port_sources.yaml` and its
   own `test/upstream_test.dart`, as each port has. The port rules of the host port (AGENTS.md)
   apply to the add-on port, with the changes of its ADRs. The port tools of the host
   (`check:headers`, `check:lib-imports`, `check:js-semantics`, tools 5 to 8) examine the add-on
   package when its first ported file lands, or when ADR 0008 moves the tools to `port_tools`.
7. **Test harness.** An add-on port uses the harness package of its host port as a dev
   dependency, when upstream uses the same upstream harness. chartjs-plugin-zoom uses
   chartjs-test-utils, and the zoom port uses `chartjs_test_utils`. Helpers that only the add-on
   needs stay in the test folder of the add-on port.
8. **Gallery.** An add-on port has no gallery app of its own. Its samples go into the gallery
   app of its host port, for example `apps/chartjs_gallery`. That gallery then depends on the
   add-on port.
9. **Release.** An add-on port releases after its host port. Its constraint on the host is the
   range of releases that it supports. It stays `publish_to: none` until its first release.

## Alternatives considered

- **The add-on code in the host port.** Rejected. Upstream has two repositories, two license
  holders and two release cycles. One package mixes two upstream structures. Rule 2 of AGENTS.md
  (mirror the upstream structure) fails. An app that needs no zoom also gets the zoom code.
- **Imports of `src/` of the host.** Rejected. The lint flags them. An add-on that reaches past
  the public API does not test the public API, and each internal change of the host breaks it.
- **The name `flutter_chartjs_port_zoom`** (the adapter form of ADR 0007 item 5). Rejected. An
  adapter connects a port to a design system and ports no upstream code. The zoom package ports
  chartjs-plugin-zoom. The form `flutter_<library>_port` tells the reader the upstream name.
- **A copy of the JS runtime in the add-on port.** Rejected. Two copies drift. ADR 0008 already
  plans one shared runtime.
- **A gallery app for each add-on.** Rejected. A plugin shows on a chart of its host. A second
  app duplicates the host gallery.

## Consequences

- `packages/flutter_chartjs_plugin_zoom_port` depends on `packages/flutter_chartjs_port` with a
  path dependency.
- ADR 0008 item 1 gets the clause "except an add-on port on its host port (ADR 0009)". ADR 0008 is
  proposed. Thus the clause is a revision before acceptance, as ADR 0007 had.
- Each gap of the host API that an add-on finds becomes a host change with a host ADR. The first
  list is the zoom inventory
  ([host-seams.md](../../packages/flutter_chartjs_plugin_zoom_port/doc/host-seams.md)).
- The JS runtime need of an add-on can bring the gate of ADR 0008 forward.
- `apps/chartjs_gallery` gets a zoom page when the zoom port has its first working gestures.
