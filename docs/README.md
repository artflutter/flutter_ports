# Docs

This folder holds the docs for all ports. The docs of one port are in the `doc/` folder of its
package.

## Decisions (all ports)

- [ADR 0001: Native ports, not wrappers](adr/0001-native-ports-not-wrappers.md)
- [ADR 0002: Pin upstream sources as git submodules at release tags](adr/0002-pin-upstream-sources.md)
  (superseded by ADR 0005)
- [ADR 0003: Package names](adr/0003-package-names.md) (superseded by ADR 0007)
- [ADR 0004: Follow upstream between releases](adr/0004-follow-upstream-between-releases.md)
  (superseded by ADR 0006)
- [ADR 0005: Pin upstream sources](adr/0005-pin-upstream-sources.md)
- [ADR 0006: Follow upstream between releases](adr/0006-follow-upstream-between-releases.md)
- [ADR 0007: Package names](adr/0007-package-names.md) (it supersedes ADR 0003)
- Proposed decisions:
  [ADR 0008: Shared JS runtime and port tools](adr/0008-shared-js-runtime-and-port-tools.md)
  (gate: D3 phase 1).

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
    ADR 0042.
  - [Upstream tracking](../packages/flutter_chartjs_port/doc/upstream-tracking.md) (proposed): how the
    port follows Chart.js fixes and improvements after the pinned tag.
  - [Upstream ledger](../packages/flutter_chartjs_port/doc/upstream-ledger.md): the upstream commits
    after the pinned tag, with their triage.
  - Decisions (all accepted, except Chart.js ADR 0044, which is rejected):
    [Chart.js ADR 0001: Theming](../packages/flutter_chartjs_port/doc/adr/0001-theming.md)
    (superseded by Chart.js ADR 0042),
    [Chart.js ADR 0002: JS numeric semantics](../packages/flutter_chartjs_port/doc/adr/0002-js-numeric-semantics.md)
    (superseded by Chart.js ADR 0010),
    [Chart.js ADR 0003: Type-only dependencies](../packages/flutter_chartjs_port/doc/adr/0003-type-only-dependencies.md),
    [Chart.js ADR 0004: Dart file naming](../packages/flutter_chartjs_port/doc/adr/0004-dart-file-naming.md)
    (superseded by Chart.js ADR 0012),
    [Chart.js ADR 0005: Third-party sources](../packages/flutter_chartjs_port/doc/adr/0005-third-party-sources.md)
    (superseded by Chart.js ADR 0011),
    [Chart.js ADR 0006: Options representation and resolver](../packages/flutter_chartjs_port/doc/adr/0006-options-representation-and-resolver.md)
    (superseded by Chart.js ADR 0043),
    [Chart.js ADR 0007: Frame scheduling](../packages/flutter_chartjs_port/doc/adr/0007-frame-scheduling.md)
    (superseded by Chart.js ADR 0016),
    [Chart.js ADR 0008: Number formatting on package:intl](../packages/flutter_chartjs_port/doc/adr/0008-number-formatting-on-package-intl.md)
    (superseded by Chart.js ADR 0026),
    [Chart.js ADR 0009: No display-only JS exactness](../packages/flutter_chartjs_port/doc/adr/0009-no-display-only-js-exactness.md)
    (superseded by Chart.js ADR 0034),
    [Chart.js ADR 0010: JS numeric semantics](../packages/flutter_chartjs_port/doc/adr/0010-js-numeric-semantics.md)
    (superseded by Chart.js ADR 0032),
    [Chart.js ADR 0011: Third-party sources](../packages/flutter_chartjs_port/doc/adr/0011-third-party-sources.md)
    (superseded by Chart.js ADR 0035),
    [Chart.js ADR 0012: Dart file naming](../packages/flutter_chartjs_port/doc/adr/0012-dart-file-naming.md)
    (it supersedes Chart.js ADR 0004),
    [Chart.js ADR 0013: Canvas model](../packages/flutter_chartjs_port/doc/adr/0013-canvas-model.md),
    [Chart.js ADR 0014: Input events and the chart host](../packages/flutter_chartjs_port/doc/adr/0014-input-events-and-chart-host.md)
    (superseded by Chart.js ADR 0037),
    [Chart.js ADR 0015: Text](../packages/flutter_chartjs_port/doc/adr/0015-text.md),
    [Chart.js ADR 0016: Frame scheduling](../packages/flutter_chartjs_port/doc/adr/0016-frame-scheduling.md)
    (it supersedes Chart.js ADR 0007),
    [Chart.js ADR 0017: Element properties](../packages/flutter_chartjs_port/doc/adr/0017-element-properties.md),
    [Chart.js ADR 0018: Typed element options](../packages/flutter_chartjs_port/doc/adr/0018-typed-element-options.md),
    [Chart.js ADR 0019: Animation](../packages/flutter_chartjs_port/doc/adr/0019-animation.md),
    [Chart.js ADR 0020: Registry and component classes](../packages/flutter_chartjs_port/doc/adr/0020-registry-and-component-classes.md),
    [Chart.js ADR 0021: Typed options in the resolver](../packages/flutter_chartjs_port/doc/adr/0021-typed-options-in-the-resolver.md),
    [Chart.js ADR 0022: Chart test harness on Flutter](../packages/flutter_chartjs_port/doc/adr/0022-chart-test-harness.md),
    [Chart.js ADR 0023: Underscore members with a colliding name](../packages/flutter_chartjs_port/doc/adr/0023-underscore-member-collisions.md),
    [Chart.js ADR 0024: Dates](../packages/flutter_chartjs_port/doc/adr/0024-dates.md),
    [Chart.js ADR 0025: Scale value parameters](../packages/flutter_chartjs_port/doc/adr/0025-scale-value-parameters.md)
    (superseded in part by Chart.js ADR 0033),
    [Chart.js ADR 0026: Number formatting on package:intl](../packages/flutter_chartjs_port/doc/adr/0026-number-formatting-on-package-intl.md)
    (it supersedes Chart.js ADR 0008),
    [Chart.js ADR 0027: Parsed data in the controllers](../packages/flutter_chartjs_port/doc/adr/0027-parsed-data.md)
    (superseded by Chart.js ADR 0036),
    [Chart.js ADR 0028: Controller interfaces and values](../packages/flutter_chartjs_port/doc/adr/0028-controller-interfaces.md),
    [Chart.js ADR 0029: Fixture smoke runner](../packages/flutter_chartjs_port/doc/adr/0029-fixture-smoke-runner.md),
    [Chart.js ADR 0030: Controller test strategy](../packages/flutter_chartjs_port/doc/adr/0030-controller-test-strategy.md),
    [Chart.js ADR 0031: Gallery chart types and the stress controller](../packages/flutter_chartjs_port/doc/adr/0031-gallery-chart-types.md),
    [Chart.js ADR 0032: JS numeric semantics](../packages/flutter_chartjs_port/doc/adr/0032-js-numeric-semantics.md)
    (superseded by Chart.js ADR 0045),
    [Chart.js ADR 0033: Radial scale centers before the first layout](../packages/flutter_chartjs_port/doc/adr/0033-radial-scale-centers.md)
    (it supersedes the `xCenter` and `yCenter` bullet of Chart.js ADR 0025 §5),
    [Chart.js ADR 0034: No display-only JS exactness](../packages/flutter_chartjs_port/doc/adr/0034-no-display-only-js-exactness.md)
    (it supersedes Chart.js ADR 0009),
    [Chart.js ADR 0035: Third-party sources](../packages/flutter_chartjs_port/doc/adr/0035-third-party-sources.md)
    (it supersedes Chart.js ADR 0011),
    [Chart.js ADR 0036: Parsed data in the controllers](../packages/flutter_chartjs_port/doc/adr/0036-parsed-data.md)
    (it supersedes Chart.js ADR 0027),
    [Chart.js ADR 0037: Legend and tooltip input path](../packages/flutter_chartjs_port/doc/adr/0037-legend-and-tooltip-input-path.md)
    (it supersedes Chart.js ADR 0014),
    [Chart.js ADR 0038: Plugin modules, class values and interfaces](../packages/flutter_chartjs_port/doc/adr/0038-plugin-modules-class-values-and-interfaces.md),
    [Chart.js ADR 0039: Tooltip model and animation](../packages/flutter_chartjs_port/doc/adr/0039-tooltip-model-and-animation.md),
    [Chart.js ADR 0040: Filler targets and plain points](../packages/flutter_chartjs_port/doc/adr/0040-filler-targets-and-plain-points.md),
    [Chart.js ADR 0041: Plugin test strategy](../packages/flutter_chartjs_port/doc/adr/0041-plugin-test-strategy.md),
    [Chart.js ADR 0042: Theming](../packages/flutter_chartjs_port/doc/adr/0042-theming.md)
    (it supersedes Chart.js ADR 0001),
    [Chart.js ADR 0043: Options representation and resolver](../packages/flutter_chartjs_port/doc/adr/0043-options-representation-and-resolver.md)
    (it supersedes Chart.js ADR 0006),
    [Chart.js ADR 0044: Stack fill search](../packages/flutter_chartjs_port/doc/adr/0044-stack-fill-search.md)
    (rejected),
    [Chart.js ADR 0045: Reference engine on arm64](../packages/flutter_chartjs_port/doc/adr/0045-reference-engine-arm64.md)
    (it supersedes Chart.js ADR 0032),
    [Chart.js ADR 0046: Stack fill search, the result of the code A/B](../packages/flutter_chartjs_port/doc/adr/0046-stack-fill-search-result.md).
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
  - Proposed decisions:
    [D3 ADR 0001: Upstream sources](../packages/flutter_d3_port/doc/adr/0001-upstream-sources.md),
    [D3 ADR 0002: File naming and package layout](../packages/flutter_d3_port/doc/adr/0002-file-naming-and-layout.md),
    [D3 ADR 0003: Number to string and number formatting](../packages/flutter_d3_port/doc/adr/0003-number-to-string.md),
    [D3 ADR 0004: Spec harness](../packages/flutter_d3_port/doc/adr/0004-spec-harness.md),
    [D3 ADR 0005: Path context and drawing](../packages/flutter_d3_port/doc/adr/0005-path-context.md),
    [D3 ADR 0006: Generators, accessors and JS values](../packages/flutter_d3_port/doc/adr/0006-generators-accessors-and-js-values.md).
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
  - Proposed decisions:
    [ECharts ADR 0001: Upstream sources](../packages/flutter_echarts_port/doc/adr/0001-upstream-sources.md),
    [ECharts ADR 0002: File naming and package layout](../packages/flutter_echarts_port/doc/adr/0002-file-naming-and-layout.md),
    [ECharts ADR 0003: Numbers, number strings and JS semantics](../packages/flutter_echarts_port/doc/adr/0003-numbers-and-js-semantics.md),
    [ECharts ADR 0004: JS values, classes and options](../packages/flutter_echarts_port/doc/adr/0004-js-values-classes-and-options.md),
    [ECharts ADR 0005: Spec harness, reference tests and the visual pages](../packages/flutter_echarts_port/doc/adr/0005-spec-harness-and-reference-tests.md),
    [ECharts ADR 0006: Renderer: the zrender canvas painter on a Canvas 2D layer](../packages/flutter_echarts_port/doc/adr/0006-renderer-and-canvas-layer.md),
    [ECharts ADR 0007: Runtime environment, chart host and input events](../packages/flutter_echarts_port/doc/adr/0007-environment-host-and-input-events.md),
    [ECharts ADR 0008: Dates, time zones, locales and formatting](../packages/flutter_echarts_port/doc/adr/0008-dates-locales-and-formatting.md),
    [ECharts ADR 0009: DOM-bound features, app hooks and theming](../packages/flutter_echarts_port/doc/adr/0009-dom-features-app-hooks-and-theming.md).
  - Prior art: [overview](../packages/flutter_echarts_port/doc/prior-art/README.md),
    [ECharts packages](../packages/flutter_echarts_port/doc/prior-art/echarts-packages.md).
