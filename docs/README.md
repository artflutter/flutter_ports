# Docs

This folder holds the docs for all ports. The docs of one port are in the `doc/` folder of its
package.

## Decisions (all ports)

[docs/adr/README.md](adr/README.md) has the rules and the template of all ADRs, and the list of the
ADRs of all ports.

## Prior art for future ports

- [Other JavaScript chart libraries](prior-art/other-chart-libraries.md): ECharts, Highcharts,
  ApexCharts, Plotly, D3 and others in Dart/Flutter, wrappers versus native ports.

## Ports

- Chart.js: [`packages/flutter_chartjs_port/doc/`](../packages/flutter_chartjs_port/doc/README.md)
  - [Overview and roadmap](../packages/flutter_chartjs_port/doc/README.md)
  - [Parity tracker](../packages/flutter_chartjs_port/doc/parity.md)
  - [Differences](../packages/flutter_chartjs_port/doc/differences.md): one row for each `DIVERGES`
    hunk, where the port does not translate the upstream lines.
  - [Upstream manifest](../packages/flutter_chartjs_port/doc/upstream/README.md): the spec cases, the
    fixtures, the defaults and the JS builtin sites of the pinned Chart.js, as tool 4 writes them.
  - [Porting flow](../packages/flutter_chartjs_port/doc/porting-flow.md) (proposed): the steps of one
    module port, the decisions and their gate phases, the test harness, the tools and a revised
    phase plan.
  - [Theming](../packages/flutter_chartjs_port/doc/theming.md) (proposed): the design behind Chart.js
    ADR 0147.
  - [Upstream tracking](../packages/flutter_chartjs_port/doc/upstream-tracking.md) (proposed): how the
    port follows Chart.js fixes and improvements after the pinned tag.
  - [Upstream ledger](../packages/flutter_chartjs_port/doc/upstream-ledger.md): the upstream commits
    after the pinned tag, with their triage.
  - [Decisions](../packages/flutter_chartjs_port/doc/adr/README.md): the ADRs of the port, with their status.
  - Prior art: [overview](../packages/flutter_chartjs_port/doc/prior-art/README.md),
    [Chart.js packages](../packages/flutter_chartjs_port/doc/prior-art/chartjs-packages.md),
    [running real Chart.js without a WebView](../packages/flutter_chartjs_port/doc/prior-art/js-runtimes.md),
    [forui theming](../packages/flutter_chartjs_port/doc/prior-art/forui-theming.md).
- D3: [`packages/flutter_d3_port/doc/`](../packages/flutter_d3_port/doc/README.md)
  - [Overview and roadmap](../packages/flutter_d3_port/doc/README.md)
  - [Parity tracker](../packages/flutter_d3_port/doc/parity.md): one row for each of the 34
    repositories in phase 0.
  - [Differences](../packages/flutter_d3_port/doc/differences.md): one row for each `DIVERGES`
    hunk. It has no rows in phase 0.
  - [Porting flow](../packages/flutter_d3_port/doc/porting-flow.md) (proposed): the life cycle of
    one module, the decisions and their gates, the test harness, the tools and the phases.
  - [Upstream ledger](../packages/flutter_d3_port/doc/upstream-ledger.md): the upstream commits
    after each pinned tag, with their triage. It has one section for each repository.
  - [Decisions](../packages/flutter_d3_port/doc/adr/README.md): the ADRs of the port, with their status.
  - Prior art: [overview](../packages/flutter_d3_port/doc/prior-art/README.md),
    [D3 packages](../packages/flutter_d3_port/doc/prior-art/d3-packages.md).
- Apache ECharts: [`packages/flutter_echarts_port/doc/`](../packages/flutter_echarts_port/doc/README.md)
  - [Overview and roadmap](../packages/flutter_echarts_port/doc/README.md)
  - [Parity tracker](../packages/flutter_echarts_port/doc/parity.md): one row for each module of
    Apache ECharts 6.1.0 and zrender 6.1.0. All rows are "not started" in phase 0.
  - [Differences](../packages/flutter_echarts_port/doc/differences.md): one row for each
    `DIVERGES` hunk. It has no rows in phase 0.
  - [Porting flow](../packages/flutter_echarts_port/doc/porting-flow.md) (proposed): the life cycle
    of one module, the decisions and their gates, the test harness, the tools and the phases.
  - [Upstream ledger](../packages/flutter_echarts_port/doc/upstream-ledger.md): the upstream
    commits after each pinned tag, with their triage. It has one section for each repository.
  - [Decisions](../packages/flutter_echarts_port/doc/adr/README.md): the ADRs of the port, with their status.
  - Prior art: [overview](../packages/flutter_echarts_port/doc/prior-art/README.md),
    [ECharts packages](../packages/flutter_echarts_port/doc/prior-art/echarts-packages.md).
- chartjs-plugin-zoom, an add-on of the Chart.js port:
  [`packages/flutter_chartjs_plugin_zoom_port/doc/`](../packages/flutter_chartjs_plugin_zoom_port/doc/README.md)
  - [Overview and roadmap](../packages/flutter_chartjs_plugin_zoom_port/doc/README.md)
  - [Host seams](../packages/flutter_chartjs_plugin_zoom_port/doc/host-seams.md): each use of
    `chart.js` and of the DOM by the plugin, with the state of the Chart.js port.
  - [Parity tracker](../packages/flutter_chartjs_plugin_zoom_port/doc/parity.md): one row for each
    upstream file. All rows are "not started" in phase 0.
  - [Differences](../packages/flutter_chartjs_plugin_zoom_port/doc/differences.md): one row for
    each `DIVERGES` hunk. It has no rows in phase 0.
  - [Upstream ledger](../packages/flutter_chartjs_plugin_zoom_port/doc/upstream-ledger.md): the
    upstream commits after the pinned commit.
  - [Decisions](../packages/flutter_chartjs_plugin_zoom_port/doc/adr/README.md): the ADRs of the port, with their status.
