# Docs

This folder holds the docs for all ports. The docs of one port are in the `doc/` folder of its
package.

## Decisions (all ports)

- [ADR 0001: Native ports, not wrappers](adr/0001-native-ports-not-wrappers.md)
- [ADR 0002: Pin upstream sources as git submodules at release tags](adr/0002-pin-upstream-sources.md)
- [ADR 0003: Package names](adr/0003-package-names.md)
- [ADR 0004: Follow upstream between releases](adr/0004-follow-upstream-between-releases.md)
  (proposed)

## Prior art for future ports

- [Other JavaScript chart libraries](prior-art/other-chart-libraries.md): ECharts, Highcharts,
  ApexCharts, Plotly, D3 and others in Dart/Flutter, wrappers versus native ports.

## Ports

- Chart.js: [`packages/flutter_chartjs/doc/`](../packages/flutter_chartjs/doc/README.md)
  - [Overview and roadmap](../packages/flutter_chartjs/doc/README.md)
  - [Parity tracker](../packages/flutter_chartjs/doc/parity.md)
  - [Porting flow](../packages/flutter_chartjs/doc/porting-flow.md) (proposed): the steps of one
    module port, the decisions and their gate phases, the test harness, the tools and a revised
    phase plan.
  - [Theming](../packages/flutter_chartjs/doc/theming.md) (proposed): the design behind Chart.js
    ADR 0001.
  - [Upstream tracking](../packages/flutter_chartjs/doc/upstream-tracking.md) (proposed): how the
    port follows Chart.js fixes and improvements after the pinned tag.
  - Decisions: [Chart.js ADR 0001: Theming](../packages/flutter_chartjs/doc/adr/0001-theming.md)
    (proposed).
  - Prior art: [overview](../packages/flutter_chartjs/doc/prior-art/README.md),
    [Chart.js packages](../packages/flutter_chartjs/doc/prior-art/chartjs-packages.md),
    [running real Chart.js without a WebView](../packages/flutter_chartjs/doc/prior-art/js-runtimes.md),
    [forui theming](../packages/flutter_chartjs/doc/prior-art/forui-theming.md).
