# Prior art: D3 in Dart and Flutter

Survey date: **2026-10-20**. Numbers that change over time (versions, downloads, likes, stars) are
as of that date.

**Question.** Does a native Dart or Flutter port of [D3](https://d3js.org) exist? Are the D3
packages ports, wrappers or new code? How does each one work?

**Answer.** No formal or complete D3 port for Flutter exists.

- A formal port pins its upstream versions. It names its source in each file. It keeps the
  upstream notice. It runs the upstream tests on each compiler. No package does all four.
- A complete port has the 30 modules of D3 v7. No package has more than 16.
- The nearest one is [`d4`](d3-packages.md#pkg-d4). It has line-for-line ports of 16 D3 v7
  modules in pure Dart. It does not draw. Its last publish was on 2024-12-01.
- The other ports cover one module or one layout, or parts of a few modules inside a larger
  library. The D3 v3 code of the Dart 1 era does not compile on current SDKs.
- No pub.dev package runs the D3 JavaScript in a WebView or an `HtmlElementView`. On GitHub, only
  apps and demos do.

## At a glance

| Package | Kind | D3 upstream | Draws with | Works on | D3 notice | Status |
|---|---|---|---|---|---|---|
| [`d4`](d3-packages.md#pkg-d4) and 17 `d4_*` | **native port**, line for line, one package for each module | 16 of the 30 D3 v7 modules, from d3-array 3.2.4 to d3-time-format 4.1.0 | nothing: SVG path strings or a `Path` context | pure Dart, all platforms. `d4_selection`: browser only, with analysis errors | absent (ISC, author only) | last publish 2024-12-01 |
| [`fluent_2`](d3-packages.md#pkg-fluent_2), D3 part | **native port**, line-cited, internal to a widget library | parts of 10 modules at stated versions, from d3-array 3.2.4 to d3-time-format 3.0.0 | a `dart:ui` `Path` sink, Fluent chart widgets | Flutter (web and desktop by its description) | absent (MIT, ICITECH) | 0.0.7, 2026-09-25 |
| [`charted`](d3-packages.md#pkg-charted) (Google) | hand reimplementation of a D3 v3 subset, with a chart layer | D3 3.4.x (not cited) | SVG DOM | browser, Dart 2 only | merged: "Michael Bostock and Google Inc." | archived. 0.6.1, 2018-07-17 |
| [`sankey_flutter`](d3-packages.md#pkg-sankey_flutter) | transcription, with a layout divergence | d3-sankey 0.12.3 (not cited) | `CustomPaint` | all Flutter platforms | replaced by the name of the author | 0.0.3, 2025-12-29 |
| [`flex_org_chart`](d3-packages.md#pkg-flex_org_chart) | partial port of the layout, new widgets | d3-org-chart 3.1.1. The tidy tree follows van der Ploeg 2013 | widgets in a `Stack`, `CustomPainter` links | all Flutter platforms | d3-org-chart (MIT) in `THIRD_PARTY_LICENSES.md` | active. 0.5.1, 2026-09-04 |
| [`MathGaps/d3-force-flutter`](d3-packages.md#pkg-d3_force) (GitHub) | module port with known bugs | d3-force 3.0.0, d3-quadtree 3 | nothing (the example uses a `Ticker` and a render object) | pure Dart | absent (MIT). The quadtree has no license | archived, never published |
| [`e_chart_ext`, `chart_xutil`](d3-packages.md#pkg-e_chart_ext) | native ports inside a chart library | d3-force 3.x, d3-hierarchy 3.x, d3-sankey 0.12, d3-quadtree | ECharts-like Flutter painters | Flutter, SDK `<3.0.0`, analysis error | absent (Apache-2.0) | abandoned. 0.0.1, 2023-05-10 |
| [`treemap`](d3-packages.md#pkg-treemap) and other d3-hierarchy fragments | direct ports of single algorithms | d3-hierarchy treemap tiles, pack siblings, enclose | widgets | Flutter | absent | 2019-2025 |
| [`delaunay`](d3-packages.md#pkg-delaunay) | native port | Delaunator 4.0.x | nothing (typed lists) | pure Dart | absent from `LICENSE`. The docs credit Delaunator | maintained. 3.0.0, 2025-10-11 |
| [`topo` family](d3-packages.md#pkg-topo) | native ports | topojson-client, topojson-server, topojson-simplify (not D3 modules) | GeoJSON and TopoJSON data | pure Dart | absent (ISC, author only) | stale since 2023-08 |
| [`d3`](d3-packages.md#pkg-legacy) (rwl) | JS interop (`dart:js`) | a bundled D3 3.5.10 | DOM, through D3 JavaScript | Dart 1 web only | in the bundled file | abandoned since 2016 |

The survey also found these. None is a formal or complete D3 port:

- **D3 code in larger libraries.** [`graphic`](d3-packages.md#pkg-larger) has one d3-array 2.x and
  d3-scale 2.x function that came through AntV. [`mermaid_core`](d3-packages.md#pkg-larger) has
  the d3-sankey steps, the d3-array ticks and `curveBasis` of its mermaid.js port.
- **One more d3-force port.** [`theiskaa/force_graph`](d3-packages.md#pkg-d3_force) (GitHub, 2026,
  MIT) ports four forces and a part of d3-quadtree.
- **Older D3 code and JS interop.** [`d3d`, `d3dart`, the vizdom family, `nvd3`,
  `choropleth_map_angular_dart`](d3-packages.md#pkg-legacy) and generated facades follow D3 v3 or
  D3 v4. [`grizzly_range`](d3-packages.md#pkg-legacy) ports the d3-array 2.x ticks.
- **Fragments in apps.** [d3-sankey in `iceice666/pirc`](d3-packages.md#pkg-fragments) is the only
  Dart file found with the upstream version and the upstream notice. Other apps have the d3-zoom
  math, a Voronoi or d3-force-style simulations.
- **Inspired or independent.** [The `dv_*` family, `graphview_plus`, `sankey_diagram_flutter`,
  `fl_chart`, `graphview`](d3-packages.md#pkg-inspired) and others use D3 names or no D3 at all.

[Ruled out](d3-packages.md#pkg-ruleouts) after inspection:
- `d3_ui` (a design system)
- the Direct3D and ID3 packages
- music-chord packages
- wrappers of other JS libraries that use D3 inside
- force, treemap, quadtree and Voronoi packages with their own algorithms

## Pages

- [D3 packages](d3-packages.md): each package above, from the Dart API to the output. The page
  gives the source of the D3 code, what each package ports, the tests, the limitations and the
  evidence. Its re-check marks name the claims that a second reader confirmed.
- [Chart.js prior art](../../../flutter_chartjs_port/doc/prior-art/README.md): the survey of the first
  port, with the same method.
- [Other JavaScript chart libraries](../../../../docs/prior-art/other-chart-libraries.md): the
  survey of 2026-10-16 for all ports. Its D3 rows were the start of this survey.

## How the survey was done

1. **pub.dev search.** The survey sent 354 query strings to the pub.dev search API in six batches.
   Some strings repeat a query that failed with HTTP 429. To see past the cap of 100 results, the
   batches also used other sort orders. The `dependency:` filter found the reverse dependencies.
2. **pub.dev name sweep.** The name list `/api/package-names` had 92,779 names at 22:57 UTC on
   2026-10-19. A pattern search over all these names found the members of each package family.
   The survey read the metadata of about 3,600 names. It downloaded 225 archives.
3. **GitHub, GitLab and Codeberg.** The survey sent 80 repository queries with the Dart filter, 8
   queries without a language filter, topic queries and owner listings. It sent 145 code-search
   queries in three batches: 44, 62 and 39. The code search uses the legacy index. Thus its totals
   are too low.

   The survey cloned 43 repositories. It read others through the GitHub contents API. GitLab,
   Codeberg and a web search found no other Dart port.
4. **Source inspection.** Each archive or clone went into its own directory. The survey read the
   code statically. It ran no package code and no `pub get`. It compared the code with the
   upstream modules at their release tags.
5. **Transcriptions.** Three layout claims depend on Python transcriptions of the upstream
   algorithms (sankey, flextree, compact). These are not runs of the real JavaScript.
6. **Re-check.** The main session of this change and the author of these pages read the cited
   files again for the key claims. [D3 packages](d3-packages.md) marks each claim that nobody
   examined a second time.

## Conclusions for flutter_d3_port

- **No formal or complete D3 port for Flutter exists.** No package pins, cites, credits and tests
  the way that this repository requires. No package has more than 16 of the 30 D3 v7 modules. The
  case for a native port is [ADR 0001](../../../../docs/adr/0001-native-ports-not-wrappers.md).
- **`d4` is the nearest one.** It has 2,859 tests with the upstream names against 3,259 upstream
  tests (88%). It has no pins, no source headers, no D3 notice and no web or wasm test legs. It
  does not emulate JS number-to-string. It does not draw.
- **What each prior art teaches this port:**
  - `d4`: a list of JS number traps for the specs (`double.toString` in path strings,
    `Math.round`, `log10`, the saturation of `round()`, the `Date`/UTC split). A Flutter port
    also needs a `dart:ui` path context and a painter host
    ([D3 ADR 0003](../adr/0003-number-to-string.md), [D3 ADR 0005](../adr/0005-path-context.md)).
  - `fluent_2`: a path sink with the d3-path method names, golden values from Node.js, a stable
    sort and `jsRound`. Commit the reference generator. Record the reference engine
    ([D3 ADR 0004](../adr/0004-spec-harness.md)).
  - `charted`: without a pin, source headers and ported tests, a port stops at one upstream
    version. DOM code does not apply to Flutter.
  - `sankey_flutter`: parity values must come from the pinned JavaScript, not from the port. Keep
    `null` and `undefined` apart ([D3 ADR 0006](../adr/0006-generators-accessors-and-js-values.md)).
    Keep the upstream copyright line.
  - `flex_org_chart`: a reference to the upstream file and lines on each function is cheap.
    Record the upstream version. Make fixtures with the upstream JavaScript. Cover the known edge
    cases.
  - `d3-force-flutter`: the upstream tests find drift. A case that fails must stop a release.
    Internal and public values (`velocityDecay`) are different things in D3.
  - `treemap` and the other fragments: Dart packages often copy d3-hierarchy code without the
    notice.
  - `delaunay`: this port pins the newer delaunator v5.1.0 with robust-predicates v3.0.3.
  - `graphic` and `mermaid_core`: old D3 forms reach Dart through ports of other JS libraries.
  - The Dart 1 packages: JS interop and `dart:html` code did not survive Dart 2 and Dart 3.
  - The inspired packages: a D3 name or constant does not make a port.
- **Licenses.** Most ports drop the D3 notice. `sankey_flutter` replaced the name of Mike Bostock
  in the d3-sankey license text. This port keeps "Copyright 2010-2026 Mike Bostock" in its ISC
  `LICENSE`. The change that ports the code of another component adds the notice of that
  component ([D3 ADR 0001](../adr/0001-upstream-sources.md)).
- **[AGENTS.md](../../../../AGENTS.md) rule 1 forbids a port from any of them.** This port
  translates only the pinned upstream files. Each package on these pages is prior art only. It is
  neither a source nor a dependency of this port. This rule includes `d4` (ISC) and `fluent_2`
  (MIT).
- **Names.** Other packages hold the pub.dev names `d3`, `d3d`, `d3dart` and `d4`.
  [ADR 0007](../../../../docs/adr/0007-package-names.md) records the name `flutter_d3_port`.
