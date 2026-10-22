# D3 port

`packages/flutter_d3_port` is a native Dart port of [D3](https://d3js.org). The port translates
the D3 modules to Dart: arrays, scales, shapes, layouts, geography, formats and time. Flutter
draws the results with its own canvas. The port has no WebView and runs no JavaScript. The reasons
for this approach, and the packages that already exist, are in the [prior art](prior-art/README.md)
and in [ADR 0001](../../../docs/adr/0001-native-ports-not-wrappers.md).
[ADR 0007](../../../docs/adr/0007-package-names.md) (accepted 2026-10-22) records the package name.

- **Upstream:** d3 **v7.9.0** (2024-03-12), ISC, with its 30 modules and three more repositories:
  internmap, delaunator and robust-predicates. Each of the 34 repositories is a shallow git
  submodule `third_party/<repo>`
  ([ADR 0005](../../../docs/adr/0005-pin-upstream-sources.md),
  [D3 ADR 0001](adr/0001-upstream-sources.md)).
  - `d3Version` in `lib/src/upstream.dart` names the version of the bundle.
    [`tool/port_sources.yaml`](../tool/port_sources.yaml) names the tag and the commit of each
    repository.
  - `dart run melos run upstream` clones the submodules. `dart run melos run upstream:check`
    compares the gitlinks with the pins.
  - Backports and commit pins follow
    [ADR 0006](../../../docs/adr/0006-follow-upstream-between-releases.md).
- **Progress:** [parity.md](parity.md), with one row for each repository in phase 0.
- **Differences:** [differences.md](differences.md), one row for each `DIVERGES` difference. It
  has no rows in phase 0.
- **Upstream after the pins:** [upstream-ledger.md](upstream-ledger.md) lists the upstream commits
  after each pinned tag, with one section for each repository.
- **Porting flow:** [porting-flow.md](porting-flow.md) (proposed) gives the life cycle of one
  module, the decisions, the test harness, the tools and the phases.
- **Prior art:** [prior-art/](prior-art/README.md), the D3 packages for Dart and Flutter. They are
  prior art only, not sources (AGENTS.md rule 1).
- **Gallery:** `apps/d3_gallery`, from phase 4.
- **License:** the code of the port is ISC, as upstream ([LICENSE](../LICENSE)). D3 ADR 0001 lists
  the other license components. Each component comes with the change that ports its code.

## What gets ported

| Upstream (at the pins) | Files | Lines | Cases |
|---|---:|---:|---:|
| `src/` of the 30 modules, internmap and robust-predicates | 566 | 21,579 | — |
| delaunator `index.js` (v5.1.0) | 1 | 607 | — |
| d3 bundle `src/index.js` (the re-exports of the 30 modules) | 1 | 30 | — |
| tests: the files that the upstream test runners run | 434 | — | 3,837 |
| locale data (`d3-format/locale/`, `d3-time-format/locale/`) | 93 | 719 | — |
| test data (31 files) and snapshots (20 files) | 51 | — | — |

[parity.md](parity.md) gives the counts of each repository, the count script and the notes. The
cases are static counts of the `it(` and `test(` calls. Loops make more cases at run time.

- Phases 1-6 cover 454 source files with 18,413 lines and 3,391 cases. Their source needs no DOM.
  The count includes the three robust-predicates files that D3 ADR 0001 item 17 makes `n/a`.
- Phase 7 ports the DOM-bound modules: 113 source files with 3,773 lines and 444 cases.
- The port does not port the three command-line scripts of `d3-dsv/bin/`, the build files, the
  type declarations or the benchmarks (D3 ADR 0001 item 17). Doc comments can adapt the text of
  the docs site in `third_party/d3/docs/` (D3 ADR 0001 item 13).

## How a module is ported

1. Translate from the pinned upstream file. Do not translate from memory, from d4 or from another
   Dart library (AGENTS.md rule 1). Keep the upstream structure and names (Dart-cased). Then a
   bump of a repository can replay its changes file by file.
2. Start the Dart file with a header that names its source, license and holder, for example
   `// Ported from d3-array v3.2.4 src/ticks.js (ISC, Mike Bostock).`
   - A file whose name fails the `file_names` lint adds `// ignore_for_file: file_names` after
     the header lines ([D3 ADR 0002](adr/0002-file-naming-and-layout.md)).
   - Code from another license component adds its notice to the package `LICENSE` and to
     `REUSE.toml` ([AGENTS.md](../../../AGENTS.md#licensing)).
3. Port the upstream test file of the module to `test/specs/<repo>/`
   ([D3 ADR 0004](adr/0004-spec-harness.md)).
4. Update the row of the repository in [parity.md](parity.md) in the same change. From phase 2,
   update `doc/status.yaml` and run tool 6. Tool 6 writes `parity.md`.

[porting-flow.md](porting-flow.md) §1 gives all steps.

## Roadmap

**Status (2026-10-20).** Phase 0 is in progress. The port has no ported module yet.

| Phase | Scope | Exit criteria |
|---|---|---|
| 0. Scaffold and design | Package, 34 submodules, `port_sources.yaml`, `d3Version`, `upstream_test.dart`, pin checks, `LICENSE`, `REUSE.toml`, docs, prior art, ADR 0007, ADR 0008 and D3 ADRs 0001-0006 (proposed), commit scope, melos and CI entries. No change in `flutter_chartjs_port` | CI green; `upstream:check` passes for Chart.js and D3 |
| 1. Decisions, tooling, pilot | Gate 1 ADRs accepted; the shared JS runtime (staged, ADR 0008); tools 1-3 for both ports; the Node `assert` stand-in; the pure path context; pilot by hand: d3-array `ticks.js`, `nice.js`, `range.js`, d3-path, d3-format | The pilot cases pass on the VM, dart2js and dart2wasm; number strings match x64 Node.js reference strings; tools 1-3 green for both ports with the Chart.js outputs unchanged |
| 2. Pure data | internmap, the rest of d3-array, d3-color, d3-interpolate without `transform/`, d3-ease, d3-random, d3-scale-chromatic, d3-dispatch, d3-polygon, d3-quadtree, d3-hierarchy; tools 4-6 | All cases of these modules pass or skip with a valid reason on the three legs; `test:cases` reports none missing |
| 3. Time, DSV and scales | the JS `Date` runtime and time zones, d3-time, d3-time-format, d3-dsv, d3-scale | The time and scale cases pass with `America/Los_Angeles` installed on all legs |
| 4. Shapes and drawing on Flutter | d3-shape, d3-chord, the `dart:ui` path builder, `apps/d3_gallery`, `doc/performance.md` | Shape and chord cases pass; the gallery builds for Android, iOS, web (wasm) and macOS; frame figures recorded |
| 5. Geometry | d3-geo, robust-predicates (`orient2d`), delaunator, d3-delaunay, d3-contour | Non-snapshot cases pass; image snapshots skip with a valid reason |
| 6. Motion and simulation | d3-timer, d3-force, the pure parts of d3-zoom and `interpolateZoom` | d3-timer cases pass under a fake clock; d3-force cases pass |
| 7. DOM layer | `doc/dom-layer.md`, the DOM ADR, then d3-selection, d3-transition, d3-axis, d3-zoom, d3-drag, d3-brush, d3-fetch, d3-interpolate `transform/` | The cases of the chosen option pass; the others skip with a valid reason |
| 8. Flutter API and release | Public widgets and painters, semantics, docs, the release model of the shared runtime, pana | `flutter_d3_port` 0.1.0 on pub.dev |

The order follows the runtime dependencies of the modules and the environment that they need:
- Pure computation comes first. Time, drawing, real time and the DOM come after it.
- The longest chain of runtime dependencies is internmap, d3-array, d3-time, d3-time-format and
  d3-scale (the `dependencies` of each `package.json`). Thus d3-scale comes in phase 3.
- A case that needs a module of a later phase skips as `'blocked: <module>'`.

## Decisions

The decisions for all ports are in [docs/adr/](../../../docs/adr/). The D3 ADRs are in
[adr/](adr/). New ADRs start as proposed. The maintainer accepts them.

Cross-port ADRs that apply to this port:
- [ADR 0001: Native ports, not wrappers](../../../docs/adr/0001-native-ports-not-wrappers.md)
  (accepted)
- [ADR 0005: Pin upstream sources](../../../docs/adr/0005-pin-upstream-sources.md) (accepted)
- [ADR 0006: Follow upstream between releases](../../../docs/adr/0006-follow-upstream-between-releases.md)
  (accepted)
- [ADR 0007: Package names](../../../docs/adr/0007-package-names.md) (accepted 2026-10-22. It
  supersedes ADR 0003)
- [ADR 0008: Shared JS runtime and port tools](../../../docs/adr/0008-shared-js-runtime-and-port-tools.md)
  (proposed)

D3 ADRs (all proposed):
- [D3 ADR 0001: Upstream sources](adr/0001-upstream-sources.md) (gate 0)
- [D3 ADR 0002: File naming and package layout](adr/0002-file-naming-and-layout.md) (gate 1)
- [D3 ADR 0003: Number to string and number formatting](adr/0003-number-to-string.md) (gate 1)
- [D3 ADR 0004: Spec harness](adr/0004-spec-harness.md) (gate 1)
- [D3 ADR 0005: Path context and drawing](adr/0005-path-context.md) (gate 1 for the pure
  interface, gate 4 for the `dart:ui` builder)
- [D3 ADR 0006: Generators, accessors and JS values](adr/0006-generators-accessors-and-js-values.md)
  (gate 1)

Later decisions have no ADR file yet. [porting-flow.md](porting-flow.md) §2 gives the question,
the facts and a proposal for each:
- Collections and iteration (gate 2, §2.9)
- Locale data (gate 2, §2.10)
- Dates and time zones (gate 3, §2.11)
- `new Function` in d3-dsv (gate 3, §2.12)
- Image snapshots (gate 5, §2.13)
- Timers and frames (gate 6, §2.14)
- DOM layer (gate 7, §2.15), after the design document `doc/dom-layer.md`
- d3-transition's prototype patch (gate 7, §2.16)
- Fetch (gate 7, §2.17)

## Open questions

The ADRs above are proposed. Thus each of them is an open question until the maintainer accepts
it. [porting-flow.md](porting-flow.md) §7 lists the other open questions:
- the phase of `interpolateZoom` (phase 2 or phase 6)
- a port-order helper (tool 8) across the 34 repositories
- the d3-format pilot cases that read the locale files before the Locale data decision
- the acceptance of the gate 0 ADRs before the phase 0 commit
- a D3 `upstream-tracking.md`
- the release model of the shared runtime
- the DOM layer in the scope of 0.1.0
