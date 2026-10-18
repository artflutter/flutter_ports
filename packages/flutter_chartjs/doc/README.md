# Chart.js port

`packages/flutter_chartjs` is a native Dart port of [Chart.js](https://www.chartjs.org):
the Chart.js logic (scales, layout, dataset controllers, elements, plugins, animations)
translated to Dart and drawn with Flutter's own canvas. No WebView, no JavaScript at runtime.
Why this approach, and what already exists: [prior art](prior-art/README.md) and
[ADR 0001](../../../docs/adr/0001-native-ports-not-wrappers.md).

- **Upstream:** Chart.js **v4.5.1** (2025-10-13), MIT, pinned as the git submodule
  `third_party/Chart.js` ([ADR 0002](../../../docs/adr/0002-pin-upstream-sources.md)).
  `melos run upstream` checks it out.
- **Progress:** [parity.md](parity.md), one row per upstream source file and spec.
- **Upstream after the pin:** [upstream-ledger.md](upstream-ledger.md) lists the upstream commits
  after the pinned tag, with their triage ([upstream-tracking.md](upstream-tracking.md)).
- **Gallery:** `apps/chartjs_gallery` on Android, iOS, web and macOS (`melos run gallery`,
  `melos run gallery:device`).
- **Decisions:** the decisions for all ports are in [docs/adr/](../../../docs/adr/). The Chart.js
  ADRs are in [adr/](adr/). All of them are accepted. Chart.js ADR 0001 is accepted for its four
  invariants only:
  - [Chart.js ADR 0001: Theming](adr/0001-theming.md)
  - [Chart.js ADR 0002: JS numeric semantics](adr/0002-js-numeric-semantics.md)
  - [Chart.js ADR 0003: Type-only dependencies](adr/0003-type-only-dependencies.md)
  - [Chart.js ADR 0004: Dart file naming](adr/0004-dart-file-naming.md)
  - [Chart.js ADR 0005: Third-party sources](adr/0005-third-party-sources.md)
  - [Chart.js ADR 0006: Options representation and resolver](adr/0006-options-representation-and-resolver.md)
  - [Chart.js ADR 0007: Frame scheduling](adr/0007-frame-scheduling.md)

## What gets ported

| Upstream | Files | Lines (v4.5.1) |
|---|---:|---:|
| `src/` implementation (helpers, core, elements, scales, controllers, plugins, platform) | 83 | 20,138 |
| `src/types` declarations (shape of the public options API) | 7 | 4,070 |
| `test/specs` (Jasmine) | 54 | 25,962 |
| `test/fixtures` image tests (662 PNG reference renders) | 1,324 | — |

Plus the runtime dependency [`@kurkle/color`](https://github.com/kurkle/color) (MIT,
Jukka Kurkela; `^0.3.0`, resolved to **0.3.2** in the v4.5.1 lockfile), which
`helpers.color.ts` wraps for CSS colour parsing and mixing.

## How a module is ported

1. Translate from the pinned upstream file, not from memory or other ports. Keep the
   upstream structure and names (Dart-cased) so upstream releases can be diffed and
   replayed file by file.
2. Start the Dart file with a header naming its source, license and holder, for example
   `// Ported from Chart.js v4.5.1 src/helpers/helpers.math.ts (MIT, Chart.js Contributors).`
   Code from another project (such as `@kurkle/color`) also adds that project's notice to the
   package LICENSE and `REUSE.toml` ([AGENTS.md](../../../AGENTS.md#licensing)).
3. Port the matching spec from `test/specs` next to it.
4. Update the row in [parity.md](parity.md) in the same PR.

## Roadmap (draft)

[porting-flow.md](porting-flow.md) proposes a revised phase plan and the steps of one module port.
[upstream-tracking.md](upstream-tracking.md) proposes how the port follows upstream after the pin.
The new ADRs and design documents use the revised phase numbers of porting-flow.md §5 (4 =
Elements, 5 = Core), not the numbers of the table below.

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
| 0. Scaffold | Workspace, CI, upstream pin, parity tracker, prior-art docs | CI green |
| 1. Decisions | ADRs for the open questions below | ADRs accepted |
| 2. Helpers | `src/helpers/*` except `helpers.canvas` and `helpers.dom`, plus `core.defaults` with the defaults it pulls in (`core.animations.defaults`, `core.layouts.defaults`, `core.scale.defaults`, `core.ticks`) and a Dart port of `@kurkle/color` 0.3.2 | non-chart helper spec cases pass |
| 3. Platform and canvas | Canvas 2D semantics over `dart:ui`, text measurement, device pixel ratio, resize, pointer events (`src/platform`, `helpers.canvas`, `helpers.dom`) | non-chart canvas and DOM helper cases pass |
| 4. Core | element, config and option resolution, registry, plugin service, layouts, scale base, autoskip, dataset controller, animations, interaction, adapters, chart controller | core spec cases with ported dependencies pass |
| 5. Elements | point, line, bar, arc | element spec cases pass |
| 6. Scales | linear base, linear, category, logarithmic, time, timeseries, radial linear | scale spec cases pass |
| 7. Controllers | line, scatter, bar, bubble, doughnut, pie, polar area, radar | controller specs and the remaining chart-level cases pass; gallery shows every type |
| 8. Plugins | title, subtitle, legend, tooltip, filler, decimation, colors | plugin specs pass |
| 9. Flutter API and release | public widget, semantics, docs, pana, first publish | `flutter_chartjs` 0.1.0 on pub.dev |

## Open questions (ADRs before phase 2)

[porting-flow.md](porting-flow.md) section 2 gives a recommended decision for each question below
and adds new ones. Each decision there has a gate phase. Only the gate 1 and gate 2 decisions come
before phase 2. [Chart.js ADR 0001](adr/0001-theming.md) proposes the theming decision.
[theming.md](theming.md) gives the design. Chart.js ADRs 0002 to 0007 propose the gate 1 and gate 2
decisions, for example the options representation
([Chart.js ADR 0006](adr/0006-options-representation-and-resolver.md)).

- **Canvas model.** Port the drawing code against a small Canvas 2D-compatible layer over
  `dart:ui` (keeps upstream drawing code close to line-for-line), or translate each draw call to
  `dart:ui` directly. Canvas 2D semantics that differ from `dart:ui`: the current path is not part
  of `save()`/`restore()`, transforms apply when path points are added, `arcTo` differs from
  `arcToPoint`. Prior art worth studying: [js-runtimes.md](prior-art/js-runtimes.md).
- **Options.** Upstream resolves options through `Proxy`-based scopes (defaults, overrides,
  scriptable and indexable options). Dart has no `Proxy`, so the resolver needs its own design,
  and a decision on a typed Dart options API versus accepting raw Chart.js JSON configs (or both).
- **Text.** CSS font strings, `measureText`, caching; `TextPainter` versus `Paragraph`.
- **Animation.** `requestAnimationFrame` maps onto `SchedulerBinding.scheduleFrameCallback`.
  `core.animator.js` stays one module-level animator on `requestAnimFrame`
  ([Chart.js ADR 0007](adr/0007-frame-scheduling.md)). ADR: Animation (gate 5,
  [porting-flow.md](porting-flow.md) §2.9) decides reduced motion, the theme-change modes and the
  `core.animator` tests.
- **Dates.** Time scales need a date adapter; upstream ships none. Provide a default on
  `DateTime`.
- **Visual verification.** Flutter goldens plus tolerance-based comparison against the upstream
  PNG fixtures; optionally render new references with real Chart.js 4.5.1 in a browser.
