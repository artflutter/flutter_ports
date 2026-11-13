# Sankey ADR 0001: Upstream source, name and license

- Status: proposed
- Date: 2026-11-13
- Gate: sankey phase 0. Phase 0 applies the pin, the pin checks, the name and the license while the
  ADR is proposed (the zoom precedent).
- Related: [ADR 0005](../../../../docs/adr/0005-pin-upstream-sources.md) (the pin and the bump
  steps), [ADR 0007](../../../../docs/adr/0007-package-names.md) (the name rule),
  [ADR 0009](../../../../docs/adr/0009-add-on-ports.md) (add-on ports),
  [Chart.js ADR 0035](../../../flutter_chartjs_port/doc/adr/0035-third-party-sources.md) (the
  `port_sources.yaml` schema), [Sankey ADR 0002](0002-file-naming-and-layout.md) (the Dart paths),
  [Sankey ADR 0003](0003-host-connection.md) (the connection to the host port)

## Context

**The upstream repository.** [kurkle/chartjs-chart-sankey](https://github.com/kurkle/chartjs-chart-sankey)
is the sankey chart type for Chart.js, by a Chart.js maintainer. Its `LICENSE` is MIT with the line
`Copyright (c) 2019-2026 Jukka Kurkela`. Its npm package has the peer dependency
`"chart.js": ">=3.3.0"` and no runtime dependency.

**Why this add-on.** The zoom port is a plugin: it listens to input and changes scale ranges. This
port is a chart type: a dataset controller and an element class of another package. It tests the
other half of the host API for add-ons. Of the Chart.js add-ons that the selection examined on
2026-11-13 (GitHub API), this one had the most commits by a person in the 12 months before: 96. Its
last release, `v0.19.1`, is of 2026-09-12.

**The pin.** The tag `v0.19.1` is the commit `90b638b11b9cdc5735b72f1b93022120e67a5eb7`. Upstream
releases with semantic-release: the `version` of `package.json` is `0.0.0-development` at each
commit, and the release version is the tag name.

**The size at the pin.** `src/` has 9 source files with 2,125 lines and 6 unit test files with
1,184 lines. `test/specs/` has 5 spec files. `test/fixtures/` has 44 fixture configs with 44 PNG
images. `test/setup.js` is the set-up of the tests.

**The test harness.** The tests run in a browser with Vitest. `test/utils/chart.js` is a copy of
the chart helpers of chartjs-test-utils 0.5.0. The repository has `packages/chartjs_test_utils`,
the port of chartjs-test-utils 0.4.0, whose `src/` is the same.

**The host.** The tests use chart.js `^4.4.5`. The Chart.js port is at Chart.js v4.6.1.

**pub.dev examination (2026-11-13).** `https://pub.dev/api/packages/<name>` gave 404 for
`flutter_chartjs_chart_sankey_port`, `flutter_chartjs_chart_sankey`, `chartjs_chart_sankey` and
`chartjs_sankey`.

## Decision

1. **The name.** The library package is `flutter_chartjs_chart_sankey_port`
   (`packages/flutter_chartjs_chart_sankey_port`), by ADR 0007 item 1 and ADR 0009 item 5. The
   commit scope is `flutter_chartjs_chart_sankey_port`. The docs name the decisions of this package
   "Sankey ADR NNNN". The tag of the `DIVERGES` markers is `sankey`.
2. **The pin.** A shallow git submodule `third_party/chartjs-chart-sankey` pins the release tag
   `v0.19.1`. `chartjsChartSankeyVersion` in `lib/src/upstream.dart` is `0.19.1`. The header
   version of rule 2 (AGENTS.md) is `v0.19.1`, for example
   `// Ported from chartjs-chart-sankey v0.19.1 src/flow.ts (MIT, Jukka Kurkela).`
3. **The checks.**
   - `test/upstream_test.dart` compares the entry of `tool/port_sources.yaml` with the version, and
     the gitlink with the `commit` of the entry. It reads the name of the upstream `package.json`.
     It does not compare the `version` of that file, which is a placeholder.
   - `tool/check_upstream_pin.sh` (`upstream:check`) fails unless the gitlink is the commit of the
     tag `v<chartjsChartSankeyVersion>` and the `commit` of the entry.
4. **The license.** The code of the port is MIT, the license of upstream. The package `LICENSE` has
   the MIT text with `Copyright (c) 2019-2026 Jukka Kurkela` and `Copyright (c) 2026 Vasiliy
   Ditsyak`. `REUSE.toml` has a table for `packages/flutter_chartjs_chart_sankey_port/**` with both
   holders. The holder string of the headers and of `port_sources.yaml` is `Jukka Kurkela`. The
   package ports no Chart.js code.
5. **The harness.** The tests use `packages/chartjs_test_utils` for the chart helpers that
   `test/utils/chart.js` copies from chartjs-test-utils. The other files of `test/utils/` compare
   images and have no Dart file (Sankey ADR 0002 item 5).
6. **Package state.** The package stays `publish_to: none` until its first release. It depends on
   `flutter_chartjs_port` with a path dependency (ADR 0009 item 2).

## Alternatives considered

- **chartjs-chart-matrix or chartjs-chart-treemap.** Both are chart types of the same author with
  a stable major version. The sankey chart has the larger surface: a layout, node-scoped options,
  labels, a custom animation and two orientations. It tests more of the host API.
- **chartjs-plugin-annotation.** It is a plugin, as zoom is. It tests the same half of the host
  API again.

## Consequences

- `third_party/chartjs-chart-sankey` is the reference source of the port. It is not built, imported
  or shipped.
- A bump moves the submodule to a later tag, `chartjsChartSankeyVersion`, the entry of
  `tool/port_sources.yaml` and the headers (ADR 0005, rule 6 of AGENTS.md).
