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
  - [Upstream ledger](../packages/flutter_chartjs/doc/upstream-ledger.md): the upstream commits
    after the pinned tag, with their triage.
  - Decisions (all proposed):
    [Chart.js ADR 0001: Theming](../packages/flutter_chartjs/doc/adr/0001-theming.md),
    [Chart.js ADR 0002: JS numeric semantics](../packages/flutter_chartjs/doc/adr/0002-js-numeric-semantics.md),
    [Chart.js ADR 0003: Type-only dependencies](../packages/flutter_chartjs/doc/adr/0003-type-only-dependencies.md),
    [Chart.js ADR 0004: Dart file naming](../packages/flutter_chartjs/doc/adr/0004-dart-file-naming.md),
    [Chart.js ADR 0005: Third-party sources](../packages/flutter_chartjs/doc/adr/0005-third-party-sources.md),
    [Chart.js ADR 0006: Options representation and resolver](../packages/flutter_chartjs/doc/adr/0006-options-representation-and-resolver.md),
    [Chart.js ADR 0007: Frame scheduling](../packages/flutter_chartjs/doc/adr/0007-frame-scheduling.md).
  - Prior art: [overview](../packages/flutter_chartjs/doc/prior-art/README.md),
    [Chart.js packages](../packages/flutter_chartjs/doc/prior-art/chartjs-packages.md),
    [running real Chart.js without a WebView](../packages/flutter_chartjs/doc/prior-art/js-runtimes.md),
    [forui theming](../packages/flutter_chartjs/doc/prior-art/forui-theming.md).
