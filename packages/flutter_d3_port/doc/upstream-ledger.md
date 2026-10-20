# D3 upstream ledger

This ledger records each merged upstream PR after the pinned tag of each of the 34 D3
repositories. It has one section for each repository, in the order of
[`tool/port_sources.yaml`](../tool/port_sources.yaml). Each section has one row for each merged
PR on `main` after the pin. A commit on `main` without a PR also gets a row, with an empty PR
cell. The rows are in commit order, the oldest first.

[ADR 0006](../../../docs/adr/0006-follow-upstream-between-releases.md) gives the rules for all
ports. [D3 ADR 0001](adr/0001-upstream-sources.md) gives the pins, the status unit (one upstream
source file), the newest tag of each repository and the bump unit (one repository). At each phase
start and at each module start, the porter adds the new rows of the repository (ADR 0006 items 4
and 5). Do not put a pipe in a cell, because a status script will parse a strict grammar.

## Columns and values

The columns are the columns of the [Chart.js ledger](../../flutter_chartjs/doc/upstream-ledger.md).
[The Chart.js upstream tracking](../../flutter_chartjs/doc/upstream-tracking.md) §3 defines the
kinds, the actions and the statuses. The D3 port has no tracking document of its own yet. Until it
has one, these path classes apply to the D3 repositories:

- `runtime`: `src/**`, the `index.js` of delaunator, and the `locale/*.json` files of d3-format
  and d3-time-format. The `package.json` of these two repositories publishes the locale files.
- `harness`: the test helpers, for example `test/asserts.js`, `test/jsdom.js` and
  `test/snapshots.js`.
- `spec`: `test/**/*-test.js`, and the `test/test.js` of delaunator and robust-predicates.
- `fixture`: `test/data/**`, `test/fixtures/**`, `test/snapshots/**` and `test/output/**`.
- `dep`: the `dependencies` of `package.json`. In the d3 bundle, these are the ranges that the pin
  rule reads.
- `docs`: `README.md`, `CHANGES.md`, `docs/**` (the d3js.org site) and `img/**`.
- `build`: all other paths. Examples are CI, lint and build config, lockfiles, dev dependencies,
  `LICENSE` and `CODEOWNERS`.

D3 has no `api` paths and no `types-test` paths. The type declarations of the d3 modules are in
DefinitelyTyped, not in their repositories. robust-predicates is the exception: it tracks
`index.d.ts`. The port does not port that file (D3 ADR 0001 item 17). Thus its path class is
`build`. delaunator writes its `index.d.ts` at build time. Git does not track it.

The `Modules` cell names the upstream source file, relative to the repository root. The `Note`
cell starts with the commit date. For an open row, the note then names the roadmap phase of the
file.

## Fetch

Phase 0 wrote the 78 rows by hand on 2026-10-20, with these steps:

1. Clone each repository without blobs, at 08:25 UTC:
   `git clone --filter=blob:none --no-checkout <url> <dir>`.
2. List the commits after the pin:
   `git -C <dir> log --reverse --format='%h %cs %s' <tag>..origin/main`.
3. Get the PR of each commit: `gh api repos/<owner>/<repo>/commits/<sha>/pulls`. A PR counts only
   with a merge date.
4. Read the diff of each commit that changes more than `README.md`: `git -C <dir> show <sha>`.

The dates are committer dates (`%cs`). The default branch of all 34 repositories is `main`
(`origin/HEAD`). No repository has a tag after its pin: `git tag --contains <tag>` lists only the
pin. Thus no bump comes first (ADR 0006 item 4). For the next fetch, use the commands of the
Chart.js upstream tracking §4.3. Take the URL and the tag from `tool/port_sources.yaml`.

Signals: none open. GitHub lists one advisory for the 34 npm packages
(`gh api /advisories -f ecosystem=npm -f affects=<package>`): GHSA-36jr-mh4h-2g58, "d3-color
vulnerable to ReDoS", for d3-color `>= 1.0.2, < 3.1.0`. The d3-color pin v3.1.0 contains the fix.
Phase 0 did not examine open upstream PRs or issues.

## Overview

78 commits follow the pins. 64 of them have a PR. 14 have no PR. The d3 bundle has 23 of the 78
commits. Four repositories have no commit after the pin: d3-format, d3-geo, d3-scale-chromatic
and internmap.

Five rows are open (`deferred`): two features, one behavior change, one fix and one comment fix.
The other 73 rows are `not-applicable`:

- 65 rows change docs only.
- 6 rows change build files only.
- 1 row changes docs and build files.
- 1 row changes the dependency ranges of the d3 bundle and its lockfile.

The Phase column gives the phase of the [roadmap](README.md#roadmap) that ports the files.

| Repository | Pin | Tag date | Phase | Rows | With PR | Open |
|---|---|---|---|---|---|---|
| [d3](#d3) | v7.9.0 | 2024-03-12 | 1, then each phase (`src/index.js`) | 23 | 18 | 0 |
| [d3-array](#d3-array) | v3.2.4 | 2023-05-30 | 1 (`ticks.js`, `nice.js`, `range.js`), 2 (the other files) | 1 | 1 | 0 |
| [d3-axis](#d3-axis) | v3.0.0 | 2021-06-08 | 7 | 1 | 1 | 0 |
| [d3-brush](#d3-brush) | v3.0.0 | 2021-06-09 | 7 | 1 | 1 | 0 |
| [d3-chord](#d3-chord) | v3.0.1 | 2021-06-05 | 4 | 1 | 1 | 0 |
| [d3-color](#d3-color) | v3.1.0 | 2022-03-28 | 2 | 2 | 2 | 0 |
| [d3-contour](#d3-contour) | v4.0.2 | 2023-01-11 | 5 | 1 | 1 | 0 |
| [d3-delaunay](#d3-delaunay) | v6.0.4 | 2023-03-31 | 5 | 4 | 4 | 3 |
| [d3-dispatch](#d3-dispatch) | v3.0.1 | 2021-06-05 | 2 | 1 | 1 | 0 |
| [d3-drag](#d3-drag) | v3.0.0 | 2021-06-09 | 7 | 3 | 2 | 0 |
| [d3-dsv](#d3-dsv) | v3.0.1 | 2021-06-05 | 3 | 3 | 2 | 0 |
| [d3-ease](#d3-ease) | v3.0.1 | 2021-06-05 | 2 | 1 | 1 | 0 |
| [d3-fetch](#d3-fetch) | v3.0.1 | 2021-06-05 | 7 | 2 | 1 | 0 |
| [d3-force](#d3-force) | v3.0.0 | 2021-06-05 | 6 | 3 | 3 | 0 |
| [d3-format](#d3-format) | v3.1.2 | 2026-01-14 | 1 | 0 | 0 | 0 |
| [d3-geo](#d3-geo) | v3.1.1 | 2024-03-12 | 5 | 0 | 0 | 0 |
| [d3-hierarchy](#d3-hierarchy) | v3.1.2 | 2022-04-02 | 2 | 2 | 2 | 0 |
| [d3-interpolate](#d3-interpolate) | v3.0.1 | 2021-06-05 | 2 (the other files), 6 (`zoom.js`), 7 (`transform/`) | 1 | 1 | 0 |
| [d3-path](#d3-path) | v3.1.0 | 2022-12-19 | 1 | 1 | 1 | 0 |
| [d3-polygon](#d3-polygon) | v3.0.1 | 2021-06-05 | 2 | 1 | 1 | 0 |
| [d3-quadtree](#d3-quadtree) | v3.0.1 | 2021-06-05 | 2 | 2 | 2 | 1 |
| [d3-random](#d3-random) | v3.0.1 | 2021-06-05 | 2 | 2 | 1 | 0 |
| [d3-scale](#d3-scale) | v4.0.2 | 2021-09-24 | 3 | 1 | 1 | 0 |
| [d3-scale-chromatic](#d3-scale-chromatic) | v3.1.0 | 2024-03-12 | 2 | 0 | 0 | 0 |
| [d3-selection](#d3-selection) | v3.0.0 | 2021-06-07 | 7 | 1 | 1 | 0 |
| [d3-shape](#d3-shape) | v3.2.0 | 2022-12-20 | 4 | 1 | 1 | 0 |
| [d3-time](#d3-time) | v3.1.0 | 2022-12-02 | 3 | 3 | 3 | 0 |
| [d3-time-format](#d3-time-format) | v4.1.0 | 2021-12-04 | 3 | 4 | 3 | 1 |
| [d3-timer](#d3-timer) | v3.0.1 | 2021-06-05 | 6 | 1 | 1 | 0 |
| [d3-transition](#d3-transition) | v3.0.1 | 2021-06-09 | 7 | 3 | 2 | 0 |
| [d3-zoom](#d3-zoom) | v3.0.0 | 2021-06-09 | 6 (`transform.js`), 7 (the other files) | 5 | 4 | 0 |
| [internmap](#internmap) | v2.0.3 | 2021-09-19 | 2 | 0 | 0 | 0 |
| [delaunator](#delaunator) | v5.1.0 | 2026-03-22 | 5 | 1 | 1 | 0 |
| [robust-predicates](#robust-predicates) | v3.0.3 | 2026-03-22 | 5 | 2 | 0 | 0 |

## Commit pins (ADR 0006 item 5)

ADR 0006 item 5 makes a commit pin due when both of its conditions are true:

- The newest upstream tag is more than 12 months old.
- The default branch has an unreleased feature or behavior change for a module of the phase.

For D3, each repository has its own newest tag (D3 ADR 0001). A change counts for the module of
its `runtime` paths.

The newest d3 tag, v7.9.0, is from 2024-03-12. On 2026-10-20, it is more than 12 months old (31
months). Thus, until d3 releases a new tag, the first condition is true for the d3 bundle at each
phase start.

The same is true for 30 of the 33 other repositories. Only three repositories have a tag from the
last 12 months: d3-format (v3.1.2, 2026-01-14), delaunator (v5.1.0, 2026-03-22) and
robust-predicates (v3.0.3, 2026-03-22). The d3-format tag becomes more than 12 months old after
2027-01-14. The delaunator and robust-predicates tags become more than 12 months old after
2027-03-22.

Thus, at each phase start, the second condition alone decides for most repositories. Before each
phase starts, the porter does these steps for each repository of the phase:

1. List the tags after the pin (`git tag --contains <tag>`). If a newer release tag exists, the
   bump comes first (ADR 0006 item 4). For a repository other than d3, only a tag inside the
   ranges of the pinned d3 `package.json` counts (D3 ADR 0001 item 7).
2. Fetch `main`. Add the new rows to the section of the repository.
3. Examine the `runtime` rows of the files of the phase. A `feature` row or a `behavior-change` row
   makes a commit pin of the repository due.
4. Do each due commit pin as its own change before the phase starts.

A commit pin moves one repository to a reviewed commit of its `main`. Its version then reads
`<last version>+<sha8>`, for example `3.0.1+<sha8>` for d3-quadtree. For the d3 bundle,
`d3Version` takes this form, for example `7.9.0+<sha8>`. The first commit pin of the port also
extends `tool/check_upstream_pin.sh`, `packages/flutter_d3_port/test/upstream_test.dart` and the
header check. After that change, they accept `<version>+<sha8>` (ADR 0006, Consequences).

The bundle index `src/index.js` of d3 grows with each phase. Thus the d3 bundle is a repository of
each phase. Its 23 rows have no `runtime` row. Thus the bundle needs no commit pin today. A later
feature in `src/index.js`, for example a new export, makes a commit pin of the bundle due at the
next phase start.

On the rows of 2026-10-20, the phase starts give these results. New rows can change them.

| Phase | Repositories of the phase, without the d3 bundle | Commit pin |
|---|---|---|
| 1 | d3-array (`ticks.js`, `nice.js`, `range.js`), d3-path, d3-format | None. d3-array and d3-path have docs rows only. d3-format has no commit after v3.1.2. Its tag is also less than 12 months old. |
| 2 | internmap, d3-array, d3-color, d3-interpolate, d3-ease, d3-random, d3-scale-chromatic, d3-dispatch, d3-polygon, d3-quadtree, d3-hierarchy | d3-quadtree, for #43 (a feature). It is the first commit pin of the port. The other repositories have docs rows and build rows only, or no row. |
| 3 | d3-time, d3-time-format, d3-dsv, d3-scale | d3-time-format, for #109 (a feature), if the Locale data decision (gate 2) ports `locale/*.json`. The other rows are docs rows and build rows. |
| 4 | d3-shape, d3-chord | None. Docs rows only. |
| 5 | d3-geo, robust-predicates, delaunator, d3-delaunay, d3-contour | d3-delaunay, for #145 (a behavior change). The same pin brings the fix #147 and the comment fix #149. The other repositories have docs rows and build rows only, or no row. |
| 6 | d3-timer, d3-force, d3-zoom (`transform.js`), d3-interpolate (`zoom.js`) | None. Docs rows only. |
| 7 | d3-selection, d3-transition, d3-axis, d3-zoom, d3-drag, d3-brush, d3-fetch, d3-interpolate (`transform/`) | None. Docs rows and build rows only. |
| 8 | None | None. No module starts. |

## d3

Pinned: v7.9.0 (1f8dd3b). Watching: main. Last synced: ca958d45 (2026-05-28).

The `docs/` folder of this repository is the d3js.org site. D3 ADR 0001 decides if Dart
doc comments take text from it. If they do, the bump that closes these rows also compares
the changed pages with the Dart doc comments.

### After v7.9.0

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| 2984f0bd | | fix #3830; better bin.thresholds docs | docs | | n/a | skip | not-applicable | | 2024-04-08. Direct commit, no PR. Its subject names the issue #3830. Docs site only (`docs/d3-array/bin.md`). |
| 9bc85632 | #3844 | docs: fix typo in polygonCentroid example | docs | | n/a | skip | not-applicable | | 2024-04-25. Docs site only (`docs/d3-polygon.md`). |
| 45df8c66 | #3845 | Added a Github link to the Definitely Typed | docs | | n/a | skip | not-applicable | | 2024-04-25. Docs site only (`docs/getting-started.md`). |
| 4e044dc0 | #3831 | fix: typo | docs | | n/a | skip | not-applicable | | 2024-05-27. Docs site only (`docs/d3-time.md`). |
| fecbf47d | #3888 | added comments to avoid confusion between the default values and customized ones | docs | | n/a | skip | not-applicable | | 2024-06-03. Docs site only (`docs/d3-axis.md`). |
| c834894e | #3886 | caret dependency ranges | dep, build | | n/a | skip | not-applicable | | 2024-06-03. The `dependencies` ranges change from major versions (`"3"`) to caret ranges (`"^3.2.4"` for d3-array). Each of the 30 module pins is in both ranges. Thus the pin set does not change. |
| 583ff0e6 | #3890 | an example of using an explicit namespace | docs | | n/a | skip | not-applicable | | 2024-06-17. Docs site only (`docs/d3-selection/namespaces.md`). |
| a971a07d | #3892 | clarify https://d3js.org/d3-geo/projection#projection_rotate | docs | | n/a | skip | not-applicable | | 2024-06-24. Docs site only (`docs/d3-geo/projection.md`). |
| 4c01ba47 | #3896 | Fixed example pie.sortValues code in docs | docs | | n/a | skip | not-applicable | | 2024-07-08. Docs site only (`docs/d3-shape/pie.md`). |
| 59b2e233 | #3924 | remove ?intent=fork | docs | | n/a | skip | not-applicable | | 2024-09-20. Docs site only (21 files under `docs/`). |
| 6773edc5 | #3928 | replace incorrect Wikipedia reference link | docs | | n/a | skip | not-applicable | | 2024-10-03. Docs site only (`docs/d3-random.md`). |
| f138b408 | | Update README.md | docs | | n/a | skip | not-applicable | | 2024-10-04. Direct commit, no PR. Docs only (`README.md`). |
| 009a2d1f | #3932 | adds Made by Observable button | docs, build | | n/a | skip | not-applicable | | 2024-10-11. Docs site only. The `package.json` change is the `vitepress` dev dependency. The `dependencies` do not change. |
| 1efb9192 | | Update README.md | docs | | n/a | skip | not-applicable | | 2024-10-18. Direct commit, no PR. Docs only (`README.md`). |
| 5425fc34 | | restore examples link | docs | | n/a | skip | not-applicable | | 2024-10-21. Direct commit, no PR. Docs site only (the site config, `docs/api.md`, `docs/d3-axis.md`). |
| 5416b3af | #3940 | changed utm_source for examples link | docs | | n/a | skip | not-applicable | | 2024-10-22. Docs site only (the site config). |
| aa2c2f97 | #3941 | add rel external to links so that we can track referrer | docs | | n/a | skip | not-applicable | | 2024-10-22. Docs site only (the site config and `docs/index.md`). |
| 844b75af | #3962 | Update getting-started.md link to Svelte example | docs | | n/a | skip | not-applicable | | 2025-01-03. Docs site only (`docs/getting-started.md`). |
| a10166cc | | Update CHANGES.md | docs | | n/a | skip | not-applicable | | 2025-01-25. Direct commit, no PR. A typo fix in `CHANGES.md`. |
| ab223942 | #4015 | fix: support links on d3js.org are outdated | docs | | n/a | skip | not-applicable | | 2025-03-10. Docs site only (`docs/community.md` and the site footer). |
| 66bfe8c6 | #4039 | Fix external edge bundling references | docs | | n/a | skip | not-applicable | | 2025-07-27. Docs site only (`docs/d3-shape/curve.md`). |
| 42ccb63d | #4084 | fix broken link | docs | | n/a | skip | not-applicable | | 2025-12-02. Docs site only (`docs/d3-force/simulation.md`). |
| ca958d45 | #4122 | docs: Incorrect alt text copied from the Observable Framework repository; it should describe D3 downloads. | docs | | n/a | skip | not-applicable | | 2026-05-28. Docs only (`README.md`, an image alt text). |

## d3-array

Pinned: v3.2.4 (94d4541). Watching: main. Last synced: be0ae0d2 (2023-10-06).

### After v3.2.4

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| be0ae0d2 | #279 | restructure README | docs | | n/a | skip | not-applicable | | 2023-10-06. Docs only. The README now links to the API reference on d3js.org. |

## d3-axis

Pinned: v3.0.0 (64372b1). Watching: main. Last synced: 20aef368 (2023-10-06).

### After v3.0.0

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| 20aef368 | #94 | restructure README | docs | | n/a | skip | not-applicable | | 2023-10-06. Docs only. The README now links to the API reference on d3js.org. |

## d3-brush

Pinned: v3.0.0 (ec2bce6). Watching: main. Last synced: a8e15cc4 (2023-10-06).

### After v3.0.0

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| a8e15cc4 | #103 | restructure README | docs | | n/a | skip | not-applicable | | 2023-10-06. Docs only. The README now links to the API reference on d3js.org. |

## d3-chord

Pinned: v3.0.1 (57ac4d9). Watching: main. Last synced: 4b57cc2a (2023-10-06).

### After v3.0.1

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| 4b57cc2a | #30 | restructure README | docs | | n/a | skip | not-applicable | | 2023-10-06. Docs only. The README now links to the API reference on d3js.org. |

## d3-color

Pinned: v3.1.0 (7a1573e). Watching: main. Last synced: 71c7f100 (2023-10-06).

### After v3.1.0

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| 958249d3 | #104 | document color.formatHex8 | docs | | n/a | skip | not-applicable | | 2022-05-19. Docs only (`README.md`). `color.formatHex8` is already in v3.1.0 (`src/color.js:179`). |
| 71c7f100 | #119 | restructure README | docs | | n/a | skip | not-applicable | | 2023-10-06. Docs only. The README now links to the API reference on d3js.org. |

## d3-contour

Pinned: v4.0.2 (0ba2dd0). Watching: main. Last synced: 8a3b95a6 (2023-10-06).

### After v4.0.2

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| 8a3b95a6 | #77 | restructure README | docs | | n/a | skip | not-applicable | | 2023-10-06. Docs only. The README now links to the API reference on d3js.org. |

## d3-delaunay

Pinned: v6.0.4 (c5a08b3). Watching: main. Last synced: afbeebfc (2025-11-10).

### After v6.0.4

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| 7bf3fd03 | #143 | restructure README | docs | | n/a | skip | not-applicable | | 2023-10-06. Docs only. The README now links to the API reference on d3js.org. |
| dc894a16 | #145 | Make `Delaunay.find` return `-1` instead of `NaN` for edge cases | runtime, spec | `src/delaunay.js` | behavior-change | replay | deferred | | 2024-05-29. Phase 5. `find` returns -1, not NaN, when `points` has fewer than two values (`_step`, `src/delaunay.js:140` at v6.0.4). `renderPoints` ignores a last odd value (`:181`). Upstream replaces one spec case with four. A behavior change is never a backport (ADR 0006 item 2). The tag v6.0.4 is older than 12 months. Thus this row makes a commit pin of d3-delaunay due at the start of phase 5 (ADR 0006 item 5). |
| c1f5b52b | #147 | fix incorrect voronoi diagram for 5 collinear points | runtime, spec | `src/delaunay.js` | fix | replay | deferred | | 2024-07-14. Phase 5. It fixes the issue #146 (a wrong Voronoi diagram for five collinear points). A new jitter of all coordinates replaces `jitter()` in the collinear case (`src/delaunay.js:30-32, :59-66` at v6.0.4). The commit pin of #145 brings it. Without that pin, it meets ADR 0006 item 2 when `src/delaunay.js` is `in progress`. Its logic needs no other unreleased commit. Its hunk context has the whitespace change of #145 (`:57`). |
| afbeebfc | #149 | fix comment typo: collinear means "null" area, not "non-null" | runtime | `src/delaunay.js` | n/a | replay | deferred | | 2025-11-10. Phase 5. A comment fix only (`src/delaunay.js:16` at v6.0.4). It has no behavior change. The commit pin of #145 brings it. |

## d3-dispatch

Pinned: v3.0.1 (904ddf2). Watching: main. Last synced: faa22468 (2023-10-06).

### After v3.0.1

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| faa22468 | #37 | restructure README | docs | | n/a | skip | not-applicable | | 2023-10-06. Docs only. The README now links to the API reference on d3js.org. |

## d3-drag

Pinned: v3.0.0 (1b88d8a). Watching: main. Last synced: 3c44c765 (2023-10-06).

### After v3.0.0

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| c86caa24 | #88 | Fix typo | docs | | n/a | skip | not-applicable | | 2023-01-17. Docs only (`README.md`). The next row reverts it. |
| c6a7e46c | | Revert "Fix typo (#88)" | docs | | n/a | skip | not-applicable | | 2023-01-17. Direct commit, no PR. It reverts #88. Docs only (`README.md`). |
| 3c44c765 | #94 | restructure README | docs | | n/a | skip | not-applicable | | 2023-10-06. Docs only. The README now links to the API reference on d3js.org. |

## d3-dsv

Pinned: v3.0.1 (3446779). Watching: main. Last synced: a2facce6 (2023-10-06).

### After v3.0.1

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| 6d96d6c0 | #89 | remove redundant word | docs | | n/a | skip | not-applicable | | 2022-01-11. Docs only (`README.md`). |
| cbf0c5e6 | | Update the parseRows row function description | docs | | n/a | skip | not-applicable | | 2023-05-18. Direct commit, no PR. Docs only (`README.md`, the `parseRows` text). |
| a2facce6 | #100 | restructure README | docs | | n/a | skip | not-applicable | | 2023-10-06. Docs only. The README now links to the API reference on d3js.org. |

## d3-ease

Pinned: v3.0.1 (a091968). Watching: main. Last synced: 4099c6d7 (2023-10-06).

### After v3.0.1

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| 4099c6d7 | #37 | restructure README | docs | | n/a | skip | not-applicable | | 2023-10-06. Docs only. The README now links to the API reference on d3js.org. |

## d3-fetch

Pinned: v3.0.1 (20a0b61). Watching: main. Last synced: 407684e2 (2023-10-06).

### After v3.0.1

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| befd675c | #51 | restructure README | docs | | n/a | skip | not-applicable | | 2023-10-06. Docs only. The README now links to the API reference on d3js.org. |
| 407684e2 | | no examples | docs | | n/a | skip | not-applicable | | 2023-10-06. Direct commit, no PR. Docs only (`README.md`). |

## d3-force

Pinned: v3.0.0 (156712c). Watching: main. Last synced: c3e73cf6 (2023-10-06).

### After v3.0.0

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| 475ec96f | #183 | Let and Const in README | docs | | n/a | skip | not-applicable | | 2021-06-11. Docs only (`README.md`). |
| 51e9a5d7 | #222 | Fix typo in README.md | docs | | n/a | skip | not-applicable | | 2023-10-04. Docs only (`README.md`). |
| c3e73cf6 | #221 | Restructure README | docs | | n/a | skip | not-applicable | | 2023-10-06. Docs only. The README now links to the API reference on d3js.org. |

## d3-format

Pinned: v3.1.2 (ebdc2d5). Watching: main. Last synced: ebdc2d53 (2026-01-14).

### After v3.1.2

No commit on `main` after v3.1.2.

## d3-geo

Pinned: v3.1.1 (8c53a90). Watching: main. Last synced: 8c53a90a (2024-03-12).

### After v3.1.1

No commit on `main` after v3.1.1.

## d3-hierarchy

Pinned: v3.1.2 (7bea49e). Watching: main. Last synced: c4ae7066 (2025-04-08).

### After v3.1.2

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| 563dd3a8 | #211 | restructure README | docs | | n/a | skip | not-applicable | | 2023-10-06. Docs only. The README now links to the API reference on d3js.org. |
| c4ae7066 | #218 | feat: support latest nodejs version | build | | n/a | skip | not-applicable | | 2025-04-08. CI workflow only (`.github/workflows/node.js.yml`). The title starts with `feat:`. No runtime path changes. |

## d3-interpolate

Pinned: v3.0.1 (6562b85). Watching: main. Last synced: 2eeffc0d (2023-10-06).

### After v3.0.1

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| 2eeffc0d | #115 | restructure README | docs | | n/a | skip | not-applicable | | 2023-10-06. Docs only. The README now links to the API reference on d3js.org. |

## d3-path

Pinned: v3.1.0 (58bce7a). Watching: main. Last synced: 103ce944 (2023-10-06).

### After v3.1.0

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| 103ce944 | #37 | restructure README | docs | | n/a | skip | not-applicable | | 2023-10-06. Docs only. The README now links to the API reference on d3js.org. |

## d3-polygon

Pinned: v3.0.1 (be52ab2). Watching: main. Last synced: a31c7d65 (2023-10-06).

### After v3.0.1

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| a31c7d65 | #38 | restructure README | docs | | n/a | skip | not-applicable | | 2023-10-06. Docs only. The README now links to the API reference on d3js.org. |

## d3-quadtree

Pinned: v3.0.1 (24d7ea8). Watching: main. Last synced: d01b12a0 (2023-10-06).

The diff of #43 (the first row below) also changes one more result. Take an `addAll` call with valid points and a datum
with a NaN coordinate. At `main`, that datum keeps 0 in the `Float64Array`
(`src/add.js:53-54, :59`). Then `add` puts it into the tree at the position (0, 0) (`:76`). At
v3.0.1, `new Array(n)` keeps `undefined` (`src/add.js:54-55`). Then `add` ignores the datum
(`:8`).

No upstream test covers this case. No upstream issue reports it (GitHub search, 2026-10-20). The
review of the commit pin chooses `replay` or `diverged` for this result.

### After v3.0.1

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| 7224f73d | #43 | accept iterables | runtime, spec, docs, build | `src/add.js` | feature | replay | deferred | | 2021-07-16. Phase 2. `addAll` and `quadtree(data)` accept an iterable. Label: enhancement. A feature is never a backport (ADR 0006 item 2). The tag v3.0.1 is older than 12 months. Thus this row makes a commit pin of d3-quadtree due at the start of phase 2 (ADR 0006 item 5). The diff also changes the result for a NaN coordinate (the text above the table). |
| d01b12a0 | #50 | restructure README | docs | | n/a | skip | not-applicable | | 2023-10-06. Docs only. The README now links to the API reference on d3js.org. |

## d3-random

Pinned: v3.0.1 (4a8ed7d). Watching: main. Last synced: 608b3629 (2023-10-06).

### After v3.0.1

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| 588790e0 | | typo | docs | | n/a | skip | not-applicable | | 2021-08-17. Direct commit, no PR. A typo fix in `README.md`. |
| 608b3629 | #50 | restructure README | docs | | n/a | skip | not-applicable | | 2023-10-06. Docs only. The README now links to the API reference on d3js.org. |

## d3-scale

Pinned: v4.0.2 (83555bd). Watching: main. Last synced: d6904a4b (2023-10-06).

### After v4.0.2

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| d6904a4b | #283 | restructure README | docs | | n/a | skip | not-applicable | | 2023-10-06. Docs only. The README now links to the API reference on d3js.org. |

## d3-scale-chromatic

Pinned: v3.1.0 (2c52792). Watching: main. Last synced: 2c527921 (2024-03-12).

### After v3.1.0

No commit on `main` after v3.1.0.

## d3-selection

Pinned: v3.0.0 (91245ee). Watching: main. Last synced: d8ea8005 (2023-10-06).

### After v3.0.0

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| d8ea8005 | #314 | restructure README | docs | | n/a | skip | not-applicable | | 2023-10-06. Docs only. The README now links to the API reference on d3js.org. |

## d3-shape

Pinned: v3.2.0 (8ec8265). Watching: main. Last synced: a82254af (2023-10-06).

### After v3.2.0

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| a82254af | #210 | restructure README | docs | | n/a | skip | not-applicable | | 2023-10-06. Docs only. The README now links to the API reference on d3js.org. |

## d3-time

Pinned: v3.1.0 (d66bba6). Watching: main. Last synced: 03d890d0 (2024-06-03).

### After v3.1.0

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| 9e8dc940 | #60 | fix links | docs | | n/a | skip | not-applicable | | 2023-01-05. Docs only (`README.md`). |
| 720eb23b | #67 | restructure README | docs | | n/a | skip | not-applicable | | 2023-10-06. Docs only. The README now links to the API reference on d3js.org. |
| 03d890d0 | #69 | update actions | build | | n/a | skip | not-applicable | | 2024-06-03. CI, lint, build and dev dependencies only. The `dependencies` (`d3-array` `2 - 3`) do not change. `LICENSE` changes its year range from 2010-2022 to 2010-2024. The holder stays Mike Bostock. The bump that contains it compares the `LICENSE` lines with D3 ADR 0001. |

## d3-time-format

Pinned: v4.1.0 (76cfef1). Watching: main. Last synced: 9c473e05 (2023-10-06).

### After v4.1.0

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| 0497d0ad | #108 | Fixes code block formatting | docs | | n/a | skip | not-applicable | | 2021-12-20. Docs only (`README.md`). |
| 4b622854 | #109 | Add vi-VN locale | runtime | `locale/vi-VN.json` | feature | replay | deferred | | 2021-12-30. Phase 3. It adds a 35th locale file. The `exports` key `./locale/*` of `package.json` makes the locale files public data. The Locale data decision (gate 2) decides if the port carries `locale/*.json`. If it does, this row makes a commit pin of d3-time-format due at the start of phase 3. If it does not, the row becomes `not-applicable`. |
| d6feb945 | | Update README.md | docs | | n/a | skip | not-applicable | | 2022-02-19. Direct commit, no PR. Docs only (`README.md`). |
| 9c473e05 | #122 | restructure README | docs | | n/a | skip | not-applicable | | 2023-10-06. Docs only. The README now links to the API reference on d3js.org. |

## d3-timer

Pinned: v3.0.1 (441e45b). Watching: main. Last synced: 50cec670 (2023-10-06).

### After v3.0.1

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| 50cec670 | #56 | restructure README | docs | | n/a | skip | not-applicable | | 2023-10-06. Docs only. The README now links to the API reference on d3js.org. |

## d3-transition

Pinned: v3.0.1 (c4c94c4). Watching: main. Last synced: 7a3b625d (2023-10-06).

### After v3.0.1

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| f998abc1 | | fix external | build | | n/a | skip | not-applicable | | 2021-06-09. Direct commit, no PR. Build only (`rollup.config.js`, the externals of the UMD bundle). |
| c1f17d9c | #118 | Use const instead of var in README | docs | | n/a | skip | not-applicable | | 2021-06-11. Docs only (`README.md`). |
| 7a3b625d | #145 | restructure README | docs | | n/a | skip | not-applicable | | 2023-10-06. Docs only. The README now links to the API reference on d3js.org. |

## d3-zoom

Pinned: v3.0.0 (debbe3d). Watching: main. Last synced: c8df708b (2023-10-06).

### After v3.0.0

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| 1bccd3fd | #237 | document the d3.ZoomTransform constructor | docs | | n/a | skip | not-applicable | | 2021-06-11. Docs only (`README.md`). |
| 23016d4a | | fix link | docs | | n/a | skip | not-applicable | | 2022-06-02. Direct commit, no PR. A link fix in `README.md`. |
| 077f87cc | #256 | Update urls from /master/ to /main/ | docs | | n/a | skip | not-applicable | | 2022-10-28. Docs only (`README.md`). |
| 95cd670c | #264 | Update wheelDelta  example in README.md | docs | | n/a | skip | not-applicable | | 2023-04-05. Docs only (`README.md`). |
| c8df708b | #271 | restructure README | docs | | n/a | skip | not-applicable | | 2023-10-06. Docs only. The README now links to the API reference on d3js.org. |

## internmap

Pinned: v2.0.3 (78db0b3). Watching: main. Last synced: 78db0b38 (2021-09-19).

### After v2.0.3

No commit on `main` after v2.0.3.

## delaunator

Pinned: v5.1.0 (3ce6521). Watching: main. Last synced: c2bd4edf (2026-06-18).

### After v5.1.0

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| c2bd4edf | #96 | [AutoCodeowners] Add CODEOWNERS file | build | | n/a | skip | not-applicable | | 2026-06-18. Repository metadata only (`CODEOWNERS`). |

## robust-predicates

Pinned: v3.0.3 (8bed7fa). Watching: main. Last synced: 4b3c7422 (2026-09-10).

### After v3.0.3

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| db6dca0d | | upgrade dev deps | build | | n/a | skip | not-applicable | | 2026-05-25. Direct commit, no PR. Dev dependencies only. The test-data packages `robust-orientation` and `nextafter` keep their ranges. |
| 4b3c7422 | | upgrade dev deps | build | | n/a | skip | not-applicable | | 2026-09-10. Direct commit, no PR. Dev dependencies and the lint config only. The test-data packages `robust-orientation` and `nextafter` keep their ranges. |
