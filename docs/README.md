# Docs

This folder holds the docs for all ports. The docs of one port are in the `doc/` folder of its
package.

## Decisions (all ports)

- [ADR 0001: Native ports, not wrappers](adr/0001-native-ports-not-wrappers.md)
- [ADR 0002: Pin upstream sources as git submodules at release tags](adr/0002-pin-upstream-sources.md)
  (superseded by ADR 0005)
- [ADR 0003: Package names](adr/0003-package-names.md)
- [ADR 0004: Follow upstream between releases](adr/0004-follow-upstream-between-releases.md)
  (superseded by ADR 0006)
- [ADR 0005: Pin upstream sources](adr/0005-pin-upstream-sources.md)
- [ADR 0006: Follow upstream between releases](adr/0006-follow-upstream-between-releases.md)
- Proposed decisions:
  [ADR 0007: Package names](adr/0007-package-names.md) (it supersedes ADR 0003 on acceptance),
  [ADR 0008: Shared JS runtime and port tools](adr/0008-shared-js-runtime-and-port-tools.md)
  (gate: D3 phase 1).

## Prior art for future ports

- [Other JavaScript chart libraries](prior-art/other-chart-libraries.md): ECharts, Highcharts,
  ApexCharts, Plotly, D3 and others in Dart/Flutter, wrappers versus native ports.

## Ports

- Chart.js: [`packages/flutter_chartjs/doc/`](../packages/flutter_chartjs/doc/README.md)
  - [Overview and roadmap](../packages/flutter_chartjs/doc/README.md)
  - [Parity tracker](../packages/flutter_chartjs/doc/parity.md)
  - [Differences](../packages/flutter_chartjs/doc/differences.md): one row for each `DIVERGES`
    hunk, where the port does not translate the upstream lines.
  - [Upstream manifest](../packages/flutter_chartjs/doc/upstream/README.md): the spec cases, the
    fixtures, the defaults and the JS builtin sites of the pinned Chart.js, as tool 4 writes them.
  - [Porting flow](../packages/flutter_chartjs/doc/porting-flow.md) (proposed): the steps of one
    module port, the decisions and their gate phases, the test harness, the tools and a revised
    phase plan.
  - [Theming](../packages/flutter_chartjs/doc/theming.md) (proposed): the design behind Chart.js
    ADR 0001.
  - [Upstream tracking](../packages/flutter_chartjs/doc/upstream-tracking.md) (proposed): how the
    port follows Chart.js fixes and improvements after the pinned tag.
  - [Upstream ledger](../packages/flutter_chartjs/doc/upstream-ledger.md): the upstream commits
    after the pinned tag, with their triage.
  - Decisions (accepted, Chart.js ADR 0001 for its four invariants only):
    [Chart.js ADR 0001: Theming](../packages/flutter_chartjs/doc/adr/0001-theming.md),
    [Chart.js ADR 0002: JS numeric semantics](../packages/flutter_chartjs/doc/adr/0002-js-numeric-semantics.md)
    (superseded by Chart.js ADR 0010),
    [Chart.js ADR 0003: Type-only dependencies](../packages/flutter_chartjs/doc/adr/0003-type-only-dependencies.md),
    [Chart.js ADR 0004: Dart file naming](../packages/flutter_chartjs/doc/adr/0004-dart-file-naming.md)
    (superseded by Chart.js ADR 0012),
    [Chart.js ADR 0005: Third-party sources](../packages/flutter_chartjs/doc/adr/0005-third-party-sources.md)
    (superseded by Chart.js ADR 0011),
    [Chart.js ADR 0006: Options representation and resolver](../packages/flutter_chartjs/doc/adr/0006-options-representation-and-resolver.md),
    [Chart.js ADR 0007: Frame scheduling](../packages/flutter_chartjs/doc/adr/0007-frame-scheduling.md),
    [Chart.js ADR 0008: Number formatting on package:intl](../packages/flutter_chartjs/doc/adr/0008-number-formatting-on-package-intl.md),
    [Chart.js ADR 0009: No display-only JS exactness](../packages/flutter_chartjs/doc/adr/0009-no-display-only-js-exactness.md),
    [Chart.js ADR 0010: JS numeric semantics](../packages/flutter_chartjs/doc/adr/0010-js-numeric-semantics.md),
    [Chart.js ADR 0011: Third-party sources](../packages/flutter_chartjs/doc/adr/0011-third-party-sources.md),
    [Chart.js ADR 0012: Dart file naming](../packages/flutter_chartjs/doc/adr/0012-dart-file-naming.md).
  - Proposed decisions:
    [Chart.js ADR 0013: Canvas model](../packages/flutter_chartjs/doc/adr/0013-canvas-model.md),
    [Chart.js ADR 0014: Input events and the chart host](../packages/flutter_chartjs/doc/adr/0014-input-events-and-chart-host.md),
    [Chart.js ADR 0015: Text](../packages/flutter_chartjs/doc/adr/0015-text.md),
    [Chart.js ADR 0016: Frame scheduling](../packages/flutter_chartjs/doc/adr/0016-frame-scheduling.md)
    (it supersedes Chart.js ADR 0007 on acceptance),
    [Chart.js ADR 0017: Element properties](../packages/flutter_chartjs/doc/adr/0017-element-properties.md),
    [Chart.js ADR 0018: Typed element options](../packages/flutter_chartjs/doc/adr/0018-typed-element-options.md),
    [Chart.js ADR 0019: Animation](../packages/flutter_chartjs/doc/adr/0019-animation.md),
    [Chart.js ADR 0020: Registry and component classes](../packages/flutter_chartjs/doc/adr/0020-registry-and-component-classes.md),
    [Chart.js ADR 0021: Typed options in the resolver](../packages/flutter_chartjs/doc/adr/0021-typed-options-in-the-resolver.md),
    [Chart.js ADR 0022: Chart test harness on Flutter](../packages/flutter_chartjs/doc/adr/0022-chart-test-harness.md),
    [Chart.js ADR 0023: Underscore members with a colliding name](../packages/flutter_chartjs/doc/adr/0023-underscore-member-collisions.md),
    [Chart.js ADR 0024: Dates](../packages/flutter_chartjs/doc/adr/0024-dates.md),
    [Chart.js ADR 0025: Scale value parameters](../packages/flutter_chartjs/doc/adr/0025-scale-value-parameters.md),
    [Chart.js ADR 0026: Number formatting on package:intl](../packages/flutter_chartjs/doc/adr/0026-number-formatting-on-package-intl.md)
    (it supersedes Chart.js ADR 0008 on acceptance).
  - Prior art: [overview](../packages/flutter_chartjs/doc/prior-art/README.md),
    [Chart.js packages](../packages/flutter_chartjs/doc/prior-art/chartjs-packages.md),
    [running real Chart.js without a WebView](../packages/flutter_chartjs/doc/prior-art/js-runtimes.md),
    [forui theming](../packages/flutter_chartjs/doc/prior-art/forui-theming.md).
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
  - Proposed decisions:
    [D3 ADR 0001: Upstream sources](../packages/flutter_d3_port/doc/adr/0001-upstream-sources.md),
    [D3 ADR 0002: File naming and package layout](../packages/flutter_d3_port/doc/adr/0002-file-naming-and-layout.md),
    [D3 ADR 0003: Number to string and number formatting](../packages/flutter_d3_port/doc/adr/0003-number-to-string.md),
    [D3 ADR 0004: Spec harness](../packages/flutter_d3_port/doc/adr/0004-spec-harness.md),
    [D3 ADR 0005: Path context and drawing](../packages/flutter_d3_port/doc/adr/0005-path-context.md),
    [D3 ADR 0006: Generators, accessors and JS values](../packages/flutter_d3_port/doc/adr/0006-generators-accessors-and-js-values.md).
  - Prior art: [overview](../packages/flutter_d3_port/doc/prior-art/README.md),
    [D3 packages](../packages/flutter_d3_port/doc/prior-art/d3-packages.md).
