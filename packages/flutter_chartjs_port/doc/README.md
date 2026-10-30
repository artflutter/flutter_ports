# Chart.js port

`packages/flutter_chartjs_port` is a native Dart port of [Chart.js](https://www.chartjs.org):
the Chart.js logic (scales, layout, dataset controllers, elements, plugins, animations)
translated to Dart and drawn with Flutter's own canvas. No WebView, no JavaScript at runtime.
Why this approach, and what already exists: [prior art](prior-art/README.md) and
[ADR 0001](../../../docs/adr/0001-native-ports-not-wrappers.md).

- **Upstream:** Chart.js **v4.6.1**, MIT, pinned as the git submodule
  `third_party/Chart.js` ([ADR 0005](../../../docs/adr/0005-pin-upstream-sources.md)). The tag
  (2026-10-22) ended the commit pin `v4.5.1+7169e651` of 2026-10-20
  ([upstream-tracking.md](upstream-tracking.md) §2.4). Its `src/` is the `src/` of that pin.
  `melos run upstream` checks it out. Backports and commit pins follow
  [ADR 0006](../../../docs/adr/0006-follow-upstream-between-releases.md).
- **Progress:** [parity.md](parity.md), one row per upstream source file and spec.
- **Differences:** [differences.md](differences.md), one row for each `DIVERGES` hunk, where the
  port does not translate the upstream lines.
- **Upstream manifest:** [upstream/](upstream/README.md), the spec cases, the fixtures, the
  defaults and the JS builtin sites of the pinned Chart.js. Tool 4 of
  [porting-flow.md](porting-flow.md) §4 writes it.
- **Upstream after the pin:** [upstream-ledger.md](upstream-ledger.md) lists the upstream commits
  after the pin, with their triage ([upstream-tracking.md](upstream-tracking.md)).
- **Text metrics:** [text-metrics.md](text-metrics.md), the text-metric probe of phase 3. It
  compares the text metrics of the canvas layer with the Chrome canvas, with the same test font.
- **Performance:** [performance.md](performance.md), the profile builds of the gallery stress demo
  on macOS, in Chrome and on an Android phone, two baselines (plain Flutter and the Chrome
  canvas), and the changes that the builds caused, for example the circle batch.
- **Canvas and host cuts:** [canvas-cuts-plan.md](canvas-cuts-plan.md) (proposed), the plan that
  replaces arc math and host sizing code of the port with `dart:ui` and Flutter layout.
- **Gallery:** `apps/chartjs_gallery` on Android, iOS, web and macOS (`melos run gallery`,
  `melos run gallery:device`).
- **Decisions:** the decisions for all ports are in [docs/adr/](../../../docs/adr/). The Chart.js
  ADRs are in [adr/](adr/). Chart.js ADRs 0001-0043, 0045 and 0046 are accepted. Chart.js ADRs
  0047-0051 are proposed. Chart.js ADR 0044 is rejected: its code A/B rejected the change, and Chart.js ADR 0046 records the result. The porting
  lead accepted Chart.js ADRs 0038-0043 on 2026-10-23, and Chart.js ADRs 0037, 0045 and 0046 on
  2026-10-29. Thirteen accepted ADRs are superseded: Chart.js ADR 0010 supersedes Chart.js ADR 0002, Chart.js ADR 0011
  supersedes Chart.js ADR 0005, Chart.js ADR 0012 supersedes Chart.js ADR 0004, Chart.js ADR 0016
  supersedes Chart.js ADR 0007, Chart.js ADR 0026 supersedes Chart.js ADR 0008, Chart.js ADR 0032
  supersedes Chart.js ADR 0010, Chart.js ADR 0034 supersedes Chart.js ADR 0009, Chart.js ADR 0035
  supersedes Chart.js ADR 0011, Chart.js ADR 0036 supersedes Chart.js ADR 0027, Chart.js ADR 0037
  supersedes Chart.js ADR 0014, Chart.js ADR 0042 supersedes Chart.js ADR 0001, Chart.js ADR
  0043 supersedes Chart.js ADR 0006, and Chart.js ADR 0045 supersedes Chart.js ADR 0032.
  Chart.js ADR 0033 supersedes the `xCenter` and `yCenter` bullet of Chart.js ADR 0025 §5. The
  list:
  - [Chart.js ADR 0001: Theming](adr/0001-theming.md) (superseded by Chart.js ADR 0042)
  - [Chart.js ADR 0002: JS numeric semantics](adr/0002-js-numeric-semantics.md) (superseded by
    Chart.js ADR 0010)
  - [Chart.js ADR 0003: Type-only dependencies](adr/0003-type-only-dependencies.md)
  - [Chart.js ADR 0004: Dart file naming](adr/0004-dart-file-naming.md) (superseded by Chart.js ADR
    0012)
  - [Chart.js ADR 0005: Third-party sources](adr/0005-third-party-sources.md) (superseded by
    Chart.js ADR 0011)
  - [Chart.js ADR 0006: Options representation and resolver](adr/0006-options-representation-and-resolver.md)
    (superseded by Chart.js ADR 0043)
  - [Chart.js ADR 0007: Frame scheduling](adr/0007-frame-scheduling.md) (superseded by Chart.js ADR
    0016)
  - [Chart.js ADR 0008: Number formatting on package:intl](adr/0008-number-formatting-on-package-intl.md)
    (superseded by Chart.js ADR 0026)
  - [Chart.js ADR 0009: No display-only JS exactness](adr/0009-no-display-only-js-exactness.md)
    (superseded by Chart.js ADR 0034)
  - [Chart.js ADR 0010: JS numeric semantics](adr/0010-js-numeric-semantics.md) (superseded by
    Chart.js ADR 0032)
  - [Chart.js ADR 0011: Third-party sources](adr/0011-third-party-sources.md) (superseded by
    Chart.js ADR 0035)
  - [Chart.js ADR 0012: Dart file naming](adr/0012-dart-file-naming.md) (it supersedes Chart.js ADR
    0004)
  - [Chart.js ADR 0013: Canvas model](adr/0013-canvas-model.md)
  - [Chart.js ADR 0014: Input events and the chart host](adr/0014-input-events-and-chart-host.md)
    (superseded by Chart.js ADR 0037)
  - [Chart.js ADR 0015: Text](adr/0015-text.md)
  - [Chart.js ADR 0016: Frame scheduling](adr/0016-frame-scheduling.md) (it supersedes Chart.js ADR
    0007)
  - [Chart.js ADR 0017: Element properties](adr/0017-element-properties.md)
  - [Chart.js ADR 0018: Typed element options](adr/0018-typed-element-options.md)
  - [Chart.js ADR 0019: Animation](adr/0019-animation.md)
  - [Chart.js ADR 0020: Registry and component classes](adr/0020-registry-and-component-classes.md)
  - [Chart.js ADR 0021: Typed options in the resolver](adr/0021-typed-options-in-the-resolver.md)
  - [Chart.js ADR 0022: Chart test harness on Flutter](adr/0022-chart-test-harness.md)
  - [Chart.js ADR 0023: Underscore members with a colliding name](adr/0023-underscore-member-collisions.md)
  - [Chart.js ADR 0024: Dates](adr/0024-dates.md)
  - [Chart.js ADR 0025: Scale value parameters](adr/0025-scale-value-parameters.md) (superseded in
    part by Chart.js ADR 0033)
  - [Chart.js ADR 0026: Number formatting on package:intl](adr/0026-number-formatting-on-package-intl.md)
    (it supersedes Chart.js ADR 0008)
  - [Chart.js ADR 0027: Parsed data in the controllers](adr/0027-parsed-data.md) (superseded by
    Chart.js ADR 0036)
  - [Chart.js ADR 0028: Controller interfaces and values](adr/0028-controller-interfaces.md)
  - [Chart.js ADR 0029: Fixture smoke runner](adr/0029-fixture-smoke-runner.md)
  - [Chart.js ADR 0030: Controller test strategy](adr/0030-controller-test-strategy.md)
  - [Chart.js ADR 0031: Gallery chart types and the stress controller](adr/0031-gallery-chart-types.md)
  - [Chart.js ADR 0032: JS numeric semantics](adr/0032-js-numeric-semantics.md) (superseded by
    Chart.js ADR 0045)
  - [Chart.js ADR 0033: Radial scale centers before the first layout](adr/0033-radial-scale-centers.md)
    (it supersedes the `xCenter` and `yCenter` bullet of Chart.js ADR 0025 §5)
  - [Chart.js ADR 0034: No display-only JS exactness](adr/0034-no-display-only-js-exactness.md) (it
    supersedes Chart.js ADR 0009)
  - [Chart.js ADR 0035: Third-party sources](adr/0035-third-party-sources.md) (it supersedes
    Chart.js ADR 0011)
  - [Chart.js ADR 0036: Parsed data in the controllers](adr/0036-parsed-data.md) (it supersedes
    Chart.js ADR 0027)
  - [Chart.js ADR 0037: Legend and tooltip input path](adr/0037-legend-and-tooltip-input-path.md)
    (it supersedes Chart.js ADR 0014)
  - [Chart.js ADR 0038: Plugin modules, class values and interfaces](adr/0038-plugin-modules-class-values-and-interfaces.md)
  - [Chart.js ADR 0039: Tooltip model and animation](adr/0039-tooltip-model-and-animation.md)
  - [Chart.js ADR 0040: Filler targets and plain points](adr/0040-filler-targets-and-plain-points.md)
  - [Chart.js ADR 0041: Plugin test strategy](adr/0041-plugin-test-strategy.md)
  - [Chart.js ADR 0042: Theming](adr/0042-theming.md) (it supersedes Chart.js ADR 0001)
  - [Chart.js ADR 0043: Options representation and resolver](adr/0043-options-representation-and-resolver.md)
    (it supersedes Chart.js ADR 0006)
  - [Chart.js ADR 0044: Stack fill search](adr/0044-stack-fill-search.md) (rejected)
  - [Chart.js ADR 0045: Reference engine on arm64](adr/0045-reference-engine-arm64.md) (it
    supersedes Chart.js ADR 0032)
  - [Chart.js ADR 0046: Stack fill search, the result of the code A/B](adr/0046-stack-fill-search-result.md)
  - [Chart.js ADR 0047: The published archive](adr/0047-published-archive.md) (proposed)
  - [Chart.js ADR 0048: Entry points and the public library](adr/0048-entry-points-and-public-library.md) (proposed)
  - [Chart.js ADR 0049: The ChartView widget and reduced motion](adr/0049-chart-view-widget.md) (proposed)
  - [Chart.js ADR 0050: The public theme API](adr/0050-public-theme-api.md) (proposed; it supersedes
    Chart.js ADR 0042 on acceptance)
  - [Chart.js ADR 0051: Input events and interaction state](adr/0051-input-events-and-interaction-state.md) (proposed)

## What gets ported

| Upstream | Files | Lines (v4.6.1) |
|---|---:|---:|
| `src/` implementation (helpers, core, elements, scales, controllers, plugins, platform) | 83 | 20,251 |
| `src/types` declarations (shape of the public options API) | 7 | 4,119 |
| `test/specs` (Jasmine) | 54 | 26,375 |
| `test/fixtures` image tests (667 PNG reference renders) | 1,334 | — |

Plus the runtime dependency [`@kurkle/color`](https://github.com/kurkle/color) (MIT,
Jukka Kurkela; `^0.3.0`, resolved to **0.3.2** in the lockfile of the pin), which
`helpers.color.ts` wraps for CSS colour parsing and mixing.

## How a module is ported

1. Translate from the pinned upstream file, not from memory or other ports. Keep the
   upstream structure and names (Dart-cased) so upstream releases can be diffed and
   replayed file by file.
2. Start the Dart file with a header naming its source, license and holder, for example
   `// Ported from Chart.js v4.6.1 src/helpers/helpers.math.ts (MIT, Chart.js Contributors).`
   Code from another project (such as `@kurkle/color`) also adds that project's notice to the
   package LICENSE and `REUSE.toml` ([AGENTS.md](../../../AGENTS.md#licensing)).
3. Port the matching spec from `test/specs` next to it.
4. Update the status text of the module in [status.yaml](status.yaml) and run
   `dart run melos run parity` (tool 6), which writes [parity.md](parity.md), in the same PR.

## Roadmap (draft)

[porting-flow.md](porting-flow.md) proposes a revised phase plan and the steps of one module port.
[upstream-tracking.md](upstream-tracking.md) proposes how the port follows upstream after the pin.
The new ADRs and design documents use the revised phase numbers of porting-flow.md §5 (4 =
Elements, 5 = Core), not the numbers of the table below.

**Status (2026-10-30).** Phases 0 to 8 of porting-flow.md §5 are done. Phase 9 (Flutter API and
release) is in progress. Phase 2 ported the
rest of the JS runtime, 14 helper files, the `core.defaults` closure and `@kurkle/color` 0.3.2
([parity.md](parity.md)). Phase 3 added the canvas layer over `dart:ui`
([Chart.js ADR 0013](adr/0013-canvas-model.md)), the internal chart host and `src/platform`
([Chart.js ADR 0014](adr/0014-input-events-and-chart-host.md)), canvas text and the test font
([Chart.js ADR 0015](adr/0015-text.md)), and the phase 3 harness rows. All 18 helper files are
ported. The 12 non-chart `helpers.canvas` cases, the 4 `helpers.color` cases and the 5
`helpers.dom` cases with a Flutter equivalent pass. The text-metric probe found all 80 widths
equal to Chrome ([text-metrics.md](text-metrics.md)). Phase 4 ported `core.element`, the point,
line, bar and arc elements and `src/elements/index.js`
([Chart.js ADR 0017](adr/0017-element-properties.md)). These files are pure layers. The
`core.element` spec case and 20 of the 21 element spec cases pass. The other element case needs
a chart. It passes since phase 7. Phase 5 ported the 21 core modules
and the chart harness of chartjs-test-utils. Phase 6 ported the seven scales and the default date
adapter ([Chart.js ADR 0024](adr/0024-dates.md)). Phase 7 ported the eight dataset controllers,
the fixture smoke runner ([Chart.js ADR 0029](adr/0029-fixture-smoke-runner.md)) and the gallery
pages of the nine chart types ([Chart.js ADR 0031](adr/0031-gallery-chart-types.md)). At its end,
831 spec cases pass, 0 fail and 111 skip in the 45 ported spec files, and 457 of the 529 upstream
fixtures pass. The rows of porting-flow.md §5 give the results of each phase. Phase 8 ported the
seven plugins of `src/plugins/` with the theme hunks H4a-H4c and H5, and the input path of the
legend and the tooltip ([Chart.js ADR 0037](adr/0037-legend-and-tooltip-input-path.md)). At its
end (2026-10-29), 955 spec cases pass, 0 fail and 81 skip in the 53 ported spec files, and 628 of
the 667 upstream fixtures pass. The other 39 skip as `diverges: adapt-date-moment-format`.

At the start of phase 9 (2026-10-29), the pin moved to the tag v4.6.1, and the reference engine
moved to arm64 ([Chart.js ADR 0045](adr/0045-reference-engine-arm64.md)). Phase 9 ported
`src/index.umd.ts` and `src/types.ts` and added the three public libraries
([Chart.js ADR 0048](adr/0048-entry-points-and-public-library.md)), the widget `ChartView` with
reduced motion ([Chart.js ADR 0049](adr/0049-chart-view-widget.md)), the public theme API with
the presets, the runtime theme switch and the goldens
([Chart.js ADR 0050](adr/0050-public-theme-api.md)), and the keyboard, the focus and the
semantics node of `ChartView`
([Chart.js ADR 0051](adr/0051-input-events-and-interaction-state.md)). The gallery uses
`ChartView` and the public libraries. The package has its README for pub.dev, the example
`example/main.dart` and the published archive of
[Chart.js ADR 0047](adr/0047-published-archive.md). On 2026-10-30, 958 spec cases pass, 0 fail
and 78 skip, no case is missing, and the counts of the fixtures did not change. The published
floor (porting-flow.md §2.12) and the release of 0.1.0 are open.

The order follows upstream's own layering:
- `helpers` depend only on `core.defaults` (and a type-only import of the chart controller).
  `core.defaults` in turn pulls in the animation, layout and scale defaults and, through the
  scale defaults, the tick formatters in `core.ticks`.
- `core` uses `platform` only through `core.controller.js`.
- Elements, scales and controllers sit on `core` and `helpers`. Plugins do too, plus `elements`
  (the filler plugin) and the doughnut and polar area controllers (the colors plugin, through
  the package index).

Most upstream specs build a chart from the fully registered bundle: `src/index.umd.ts` calls
`Chart.register(controllers, scales, elements, plugins)`, and the test setup adds a date adapter.
That covers 2 of the 12 helper spec files and 14 of the 23 core, element and scale spec files.
So each phase is gated on the spec cases whose dependencies are already ported. The
chart-building cases stay open in [parity.md](parity.md) until a first controller with its
elements and scales lands (phases 5-7).

| Phase | Scope | Exit criteria |
|---|---|---|
| 0. Scaffold | done; Workspace, CI, upstream pin, parity tracker, prior-art docs | CI green |
| 1. Decisions | ADRs for the open questions below | ADRs accepted |
| 2. Helpers | done; `src/helpers/*` except `helpers.canvas` and `helpers.dom`, plus `core.defaults` with the defaults it pulls in (`core.animations.defaults`, `core.layouts.defaults`, `core.scale.defaults`, `core.ticks`) and a Dart port of `@kurkle/color` 0.3.2 | non-chart helper spec cases pass |
| 3. Platform and canvas | done; Canvas 2D semantics over `dart:ui`, text measurement, device pixel ratio, resize, pointer events (`src/platform`, `helpers.canvas`, `helpers.dom`) | non-chart canvas and DOM helper cases pass |
| 4. Core | done (phase 5 of porting-flow.md §5); element (done in phase 4 of porting-flow.md §5), config and option resolution, registry, plugin service, layouts, scale base, autoskip, dataset controller, animations, interaction, adapters, chart controller | core spec cases with ported dependencies pass |
| 5. Elements | done (phase 4 of porting-flow.md §5); point, line, bar, arc | element spec cases pass |
| 6. Scales | done (phase 6 of porting-flow.md §5); linear base, linear, category, logarithmic, time, timeseries, radial linear | scale spec cases pass |
| 7. Controllers | done (phase 7 of porting-flow.md §5); line, scatter, bar, bubble, doughnut, pie, polar area, radar | controller specs and the remaining chart-level cases pass; gallery shows every type |
| 8. Plugins | done; title, subtitle, legend, tooltip, filler, decimation, colors | plugin specs pass |
| 9. Flutter API and release | in progress; public widget, semantics, docs, pana, first publish | `flutter_chartjs_port` 0.1.0 on pub.dev |

## Open questions (ADRs before phase 2)

[porting-flow.md](porting-flow.md) section 2 gives a recommended decision for each question below
and adds new ones. Each decision there has a gate phase. Only the gate 1 and gate 2 decisions come
before phase 2. [Chart.js ADR 0042](adr/0042-theming.md) holds the theming decision. It
supersedes Chart.js ADR 0001. [theming.md](theming.md) gives the design. Chart.js ADRs 0003 and
0006 to 0012 held the gate 1 and gate 2 decisions. All of them are accepted. An example is the
options representation of Chart.js ADR 0006, now in
[Chart.js ADR 0043](adr/0043-options-representation-and-resolver.md).

- **Canvas model.** Decided in [Chart.js ADR 0013](adr/0013-canvas-model.md): a Canvas
  2D-compatible layer over `dart:ui`, with a retained bitmap of pictures in device pixels. The
  upstream drawing code stays close to line for line.
- **Options.** Upstream resolves options through `Proxy`-based scopes (defaults, overrides,
  scriptable and indexable options). Dart has no `Proxy`, so the resolver needs its own design,
  and a decision on a typed Dart options API versus accepting raw Chart.js JSON configs (or both).
- **Text.** Decided in [Chart.js ADR 0015](adr/0015-text.md): a parser for the CSS font
  shorthand, `ui.Paragraph` with LRU caches, and Liberation Sans as the test font.
- **Input events.** Decided in [Chart.js ADR 0037](adr/0037-legend-and-tooltip-input-path.md)
  (it supersedes [Chart.js ADR 0014](adr/0014-input-events-and-chart-host.md)): the DOM event names of Chrome from Flutter pointer events, an internal chart host
  that sizes the chart before the first paint, no claim in the gesture arena, and the compatibility
  mouse events of a touch tap.
- **Animation.** `requestAnimationFrame` maps onto `SchedulerBinding.scheduleFrameCallback`.
  `core.animator.js` stays one module-level animator on `requestAnimFrame`
  ([Chart.js ADR 0016](adr/0016-frame-scheduling.md)). [Chart.js ADR 0019](adr/0019-animation.md)
  decides reduced motion, the theme-change modes and the `core.animator` tests.
- **Dates.** Time scales need a date adapter, and upstream ships none. Decided in
  [Chart.js ADR 0024](adr/0024-dates.md): a default adapter with the rules of
  chartjs-adapter-moment 1.0.1 on moment 2.29.4. Its calendar works on wall milliseconds with
  integer day arithmetic, and `DateTime` gives the local offsets. It uses ICU format patterns of
  `DateFormat` in place of moment tokens
  ([Chart.js ADR 0034](adr/0034-no-display-only-js-exactness.md)). It uses local time by default,
  and UTC in the specs.
- **Visual verification.** Decided in [Chart.js ADR 0034](adr/0034-no-display-only-js-exactness.md):
  no image comparison against the upstream PNGs. The fixture configs run as smoke tests. Flutter
  goldens test only Flutter behavior.
