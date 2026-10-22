# D3 ADR 0001: Upstream sources

- Status: proposed
- Date: 2026-10-20
- Gate: D3 phase 0. Phase 0 applies the pins, the pin checks, the license and the CI checkout.
- Related: [ADR 0005](../../../../docs/adr/0005-pin-upstream-sources.md) (the pin and the bump
  steps), [ADR 0006](../../../../docs/adr/0006-follow-upstream-between-releases.md) (ledger,
  backports and commit pins), [ADR 0007](../../../../docs/adr/0007-package-names.md) (the package
  name), [ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) (the shared
  port tools), [Chart.js ADR 0035](../../../flutter_chartjs_port/doc/adr/0035-third-party-sources.md)
  (the precedent for other projects), [D3 ADR 0002](0002-file-naming-and-layout.md) (the Dart
  paths), [D3 ADR 0004](0004-spec-harness.md) (the spec harness)

## Context

[ADR 0005](../../../../docs/adr/0005-pin-upstream-sources.md) pins the upstream repository of each
port as a reference-only shallow submodule under `third_party/`, at a release tag. The tracked
version also lives in code. Two checks compare that version with the pin. Each port lists the
other projects that it takes code from in its own ADR.
[ADR 0006](../../../../docs/adr/0006-follow-upstream-between-releases.md) adds the upstream ledger,
the backports and the commit pins.
[Chart.js ADR 0035](../../../flutter_chartjs_port/doc/adr/0035-third-party-sources.md) applies these
rules to the Chart.js port.

**One port, 34 repositories.** D3 has no single code repository. The `d3` repository holds the
bundle:
- `src/index.js:1-30` re-exports the 30 module packages, from `d3-array` to `d3-zoom`. The bundle
  has no library code of its own.
- `docs/` holds the API docs of every module in 116 Markdown pages. VitePress builds the d3js.org
  site from them (`docs/.vitepress/config.ts:11`, `package.json:85-87`).
- `test/d3-test.js:10-18` examines only the exports. `test/docs-test.js` examines the doc links.

Each module has its own repository under `https://github.com/d3`. Three more repositories hold
dependencies: `mbostock/internmap` (of d3-array), `mapbox/delaunator` (of d3-delaunay) and
`mourner/robust-predicates` (of delaunator).

**Versions.** The d3 v7.9.0 `package.json:38-67` gives a bare major range for each module, for
example `"d3-format": "3"`. Three more ranges come from the module files:
- `"internmap": "1 - 2"` (`d3-array/package.json:41` at `v3.2.4`)
- `"delaunator": "5"` (`d3-delaunay/package.json:45` at `v6.0.4`)
- `"robust-predicates": "^3.0.2"` (`delaunator/package.json:13` at `v5.1.0`)

The d3 v7.9.0 `yarn.lock` locks d3-format 3.1.0 (`:1018-1019`), delaunator 5.0.1 (`:1197-1198`)
and robust-predicates 3.0.2 (`:1949-1950`). For the other 30 dependencies, the lockfile version is
also the newest tag. npm does not read the lockfile of a dependency. Thus
`npm install d3@7.9.0` resolved d3-format 3.1.2, delaunator 5.1.0 and robust-predicates 3.0.3 on
2026-10-20. The published `d3@7.9.0/dist/d3.js` holds the lockfile code, for example the
d3-format 3.1.0 `formatDecimalParts` (`:9491-9493`).

The three newer tags change this code:
- d3-format v3.1.1 (2026-01-13) changes behavior. Its release notes list four fixes.
  `format(".2r")(0)` gives `"0"` in place of `"0.0"` (`test/format-type-r-test.js:35` at v3.1.2,
  `:5` at v3.1.0). `locale.format` gets an `options` argument (`src/locale.js:23`). v3.1.2
  (2026-01-14) changes no behavior.
- delaunator v5.1.0 (2026-03-22) adds type annotations. Its one runtime change is the empty
  `halfedges` of the collinear case. It is an `Int32Array` (`index.js:165`), not a `Uint32Array`
  (v5.0.1 `index.js:127`).
- robust-predicates v3.0.3 (2026-03-22) fixes `orient3d`. `src/orient2d.js` does not change.
  `src/util.js` changes one comment.

**Licenses.** The `LICENSE` files at the tags give these facts:
- 32 repositories carry the same ISC text. Only their copyright lines differ. The permission text
  from `Permission to use` to `THIS SOFTWARE.` has the md5 `65104b9a27b4a3ad07929e4784f05668` in
  all 32 files.
- d3-ease is BSD-3-Clause (`LICENSE:1-28`, `package.json:18`). Its `LICENSE` names Mike Bostock
  and Robert Penner.
- robust-predicates is Unlicense (`LICENSE:1-24`). Its `LICENSE` has no copyright line. Its
  `package.json:9` names the author, Vladimir Agafonkin.
- The d3-geo `LICENSE` adds an MIT notice of GeographicLib (`:15-34`). The d3-scale-chromatic
  `LICENSE` adds an Apache-2.0 notice of ColorBrewer (`:15-28`).
- The d3-delaunay `LICENSE` names Observable, Inc. and Mapbox, not Mike Bostock (`:1-2`).
- `d3-array/src/quickselect.js:3-4` keeps an ISC notice of Vladimir Agafonkin.
- `d3-array/src/fsum.js:1` links the CPython `math_fsum` code (PSF-2.0). The file has no notice.

The banner of the published bundle (`dist/d3.js:1`) names only Mike Bostock.

**Holder strings.** Tool 2 of the Chart.js port compares the holder of each `// Ported from` line
with `port_sources.yaml`. The package `LICENSE` must contain the same string. The copyright list of
the last `REUSE.toml` table that matches the file must also contain it
(`packages/flutter_chartjs_port/tool/src/port_headers.dart:820-841`). Thus each project needs one exact
holder string. The research for this ADR gave different strings for d3-ease, d3-delaunay and
robust-predicates.

**Test data.** Some upstream tests of later phases import npm packages outside the 34
repositories. Other tests read data files from outside sources, for example
`d3-array/test/data/athletes.csv`.

**CI.** At commit `75178b5`, three CI jobs fetched every submodule: the ubuntu leg of `test`,
`port-checks` and `upstream-manifest` (`.github/workflows/ci.yaml:42,69,85` at that commit). With
the D3 submodules, each of these jobs clones 34 more repositories. Item 15 changes these jobs.

**Maintainer decisions.** On 2026-10-20, the maintainer decided four points: the package name, the
license of the port's code, the pin rule and the fsum rule. This ADR records them with the rest of
the design. The ADR stays `proposed` until the maintainer accepts it.

## Decision

1. **Maintainer decisions (2026-10-20).**
   1. The package is `flutter_d3_port`: one Flutter package, `publish_to: none` until 0.1.0.
      [ADR 0007](../../../../docs/adr/0007-package-names.md) states the rule for package names.
      It also states the deviation from [ADR 0003](../../../../docs/adr/0003-package-names.md).
   2. The port's own code is ISC, as upstream (item 9). The Chart.js port is MIT for the same
      reason.
   3. Each repository is at the newest release tag inside the d3 v7.9.0 ranges (item 3).
   4. The port of `d3-array/src/fsum.js` follows upstream. The package gets no PSF-2.0 notice
      (item 11).
2. **Upstream repository.** The `d3` repository is the upstream repository of
   [ADR 0005](../../../../docs/adr/0005-pin-upstream-sources.md). `third_party/d3` pins it at
   `v7.9.0` (commit `1f8dd3b`). The port-only `packages/flutter_d3_port/lib/src/upstream.dart`
   holds `d3Version = '7.9.0'`. `d3Version` names the bundle and its ranges. It names no module
   version.

   The other 33 repositories are the other projects of the port, as `@kurkle/color` is for
   Chart.js. `port_sources.yaml` holds their versions. No constant in code holds them.
3. **Pin rule.** Each repository is at the newest release tag inside the semver ranges of the d3
   v7.9.0 `package.json`. This is the set that `npm install d3@7.9.0` resolved on 2026-10-20.
   - d3 does not list three repositories. Each of them takes the range of its dependent package
     at its pin: internmap from d3-array, delaunator from d3-delaunay, robust-predicates from
     delaunator.
   - Pre-release tags, for example `v2.0.0-rc.1`, do not count.
   - The rule differs from the d3 v7.9.0 lockfile in three repositories: d3-format `v3.1.2`
     (lockfile 3.1.0), delaunator `v5.1.0` (5.0.1) and robust-predicates `v3.0.3` (3.0.2).
   - On 2026-10-20, no repository has a release tag after its pin, inside or outside the ranges
     (`git ls-remote --tags` of each URL).
4. **Submodules.** Each repository is a reference-only shallow submodule at
   `third_party/<repository name>`. The URL is `https://github.com/d3/<repository name>`. Three
   repositories have other URLs: `https://github.com/mbostock/internmap`,
   `https://github.com/mapbox/delaunator` and `https://github.com/mourner/robust-predicates`.

   | Submodule | Tag | Commit | Date | SPDX | Holder | Copyright lines of the `LICENSE` at the tag |
   |---|---|---|---|---|---|---|
   | `third_party/d3` | `v7.9.0` | `1f8dd3b92960f58726006532c11e9457864513ec` | 2024-03-12 | ISC | `Mike Bostock` | `Copyright 2010-2023 Mike Bostock` |
   | `third_party/d3-array` | `v3.2.4` | `94d4541626ae3ac6c847e3d4c6e31aca1a8879b4` | 2023-05-30 | ISC | `Mike Bostock` | `Copyright 2010-2023 Mike Bostock` |
   | `third_party/d3-axis` | `v3.0.0` | `64372b12c9ba5c8a816277b3ad04ff813db5af97` | 2021-06-08 | ISC | `Mike Bostock` | `Copyright 2010-2021 Mike Bostock` |
   | `third_party/d3-brush` | `v3.0.0` | `ec2bce6f15074a9ead7f9a84c61335be51c123a3` | 2021-06-09 | ISC | `Mike Bostock` | `Copyright 2010-2021 Mike Bostock` |
   | `third_party/d3-chord` | `v3.0.1` | `57ac4d9029e66c025117356ae58ab36c7457a2d1` | 2021-06-05 | ISC | `Mike Bostock` | `Copyright 2010-2021 Mike Bostock` |
   | `third_party/d3-color` | `v3.1.0` | `7a1573ed260de4fd97d061975244841132adde92` | 2022-03-28 | ISC | `Mike Bostock` | `Copyright 2010-2022 Mike Bostock` |
   | `third_party/d3-contour` | `v4.0.2` | `0ba2dd047ce4cc2980025eff5c4fea989bf2da85` | 2023-01-11 | ISC | `Mike Bostock` | `Copyright 2012-2023 Mike Bostock` |
   | `third_party/d3-delaunay` | `v6.0.4` | `c5a08b375cd57f4a314b07979e25e3e30387943f` | 2023-03-31 | ISC | `Observable, Inc.` | `Copyright 2018-2021 Observable, Inc.`, `Copyright 2021 Mapbox` |
   | `third_party/d3-dispatch` | `v3.0.1` | `904ddf22634bb642460685992f4ce22898f8aeb4` | 2021-06-05 | ISC | `Mike Bostock` | `Copyright 2010-2021 Mike Bostock` |
   | `third_party/d3-drag` | `v3.0.0` | `1b88d8a2d69fca86d4d90a8329987693b79ec506` | 2021-06-09 | ISC | `Mike Bostock` | `Copyright 2010-2021 Mike Bostock` |
   | `third_party/d3-dsv` | `v3.0.1` | `344677983ac44e7bbf0e2527ad7f0223d66a2f38` | 2021-06-05 | ISC | `Mike Bostock` | `Copyright 2013-2021 Mike Bostock` |
   | `third_party/d3-ease` | `v3.0.1` | `a0919680efc6f8e667275ba1d6330bf6a4cc9301` | 2021-06-05 | BSD-3-Clause | `Mike Bostock` | `Copyright 2010-2021 Mike Bostock`, `Copyright 2001 Robert Penner` |
   | `third_party/d3-fetch` | `v3.0.1` | `20a0b61b87a55c88e6b83580c927523b5c0448fe` | 2021-06-05 | ISC | `Mike Bostock` | `Copyright 2016-2021 Mike Bostock` |
   | `third_party/d3-force` | `v3.0.0` | `156712c8c3285d77cb487e1685c5adafcd0394a4` | 2021-06-05 | ISC | `Mike Bostock` | `Copyright 2010-2021 Mike Bostock` |
   | `third_party/d3-format` | `v3.1.2` | `ebdc2d530277df379157f82fee6ea5623d179bd7` | 2026-01-14 | ISC | `Mike Bostock` | `Copyright 2010-2026 Mike Bostock` |
   | `third_party/d3-geo` | `v3.1.1` | `8c53a90ae70c94bace73ecb02f2c792c649c86ba` | 2024-03-12 | ISC | `Mike Bostock` | `Copyright 2010-2024 Mike Bostock`, and for GeographicLib (MIT) `Copyright 2008-2012 Charles Karney` |
   | `third_party/d3-hierarchy` | `v3.1.2` | `7bea49efdc1093b28a8d60d2f8717d8a17803564` | 2022-04-02 | ISC | `Mike Bostock` | `Copyright 2010-2021 Mike Bostock` |
   | `third_party/d3-interpolate` | `v3.0.1` | `6562b85040f7a9b96efe49b54a77eb6fceafa1c1` | 2021-06-05 | ISC | `Mike Bostock` | `Copyright 2010-2021 Mike Bostock` |
   | `third_party/d3-path` | `v3.1.0` | `58bce7a53df2b03f70092a9b00b78055c4ffee04` | 2022-12-19 | ISC | `Mike Bostock` | `Copyright 2015-2022 Mike Bostock` |
   | `third_party/d3-polygon` | `v3.0.1` | `be52ab24e723b5b0078e13f51003981839ad8134` | 2021-06-05 | ISC | `Mike Bostock` | `Copyright 2010-2021 Mike Bostock` |
   | `third_party/d3-quadtree` | `v3.0.1` | `24d7ea88ea7099407cdce67e7fe548a3a1893d92` | 2021-06-05 | ISC | `Mike Bostock` | `Copyright 2010-2021 Mike Bostock` |
   | `third_party/d3-random` | `v3.0.1` | `4a8ed7dd38cac562f924d69f475f9f058366240b` | 2021-06-05 | ISC | `Mike Bostock` | `Copyright 2010-2021 Mike Bostock` |
   | `third_party/d3-scale` | `v4.0.2` | `83555bd759c7314420bd4240642beda5e258db9e` | 2021-09-24 | ISC | `Mike Bostock` | `Copyright 2010-2021 Mike Bostock` |
   | `third_party/d3-scale-chromatic` | `v3.1.0` | `2c52792197299346b7bdb94322bb4dff8f554fea` | 2024-03-12 | ISC | `Mike Bostock` | `Copyright 2010-2024 Mike Bostock`, and for ColorBrewer (Apache-2.0) `Copyright 2002 Cynthia Brewer, Mark Harrower, and The Pennsylvania State University` |
   | `third_party/d3-selection` | `v3.0.0` | `91245ee124ec4dd491e498ecbdc9679d75332b49` | 2021-06-07 | ISC | `Mike Bostock` | `Copyright 2010-2021 Mike Bostock` |
   | `third_party/d3-shape` | `v3.2.0` | `8ec82658454750cfa29efb1e0ea514e3dd9b2297` | 2022-12-20 | ISC | `Mike Bostock` | `Copyright 2010-2022 Mike Bostock` |
   | `third_party/d3-time` | `v3.1.0` | `d66bba6f83801b2f3a3e6440dba8df3357669c73` | 2022-12-02 | ISC | `Mike Bostock` | `Copyright 2010-2022 Mike Bostock` |
   | `third_party/d3-time-format` | `v4.1.0` | `76cfef1da81b70404c0226ec9db9b0d56fa09461` | 2021-12-04 | ISC | `Mike Bostock` | `Copyright 2010-2021 Mike Bostock` |
   | `third_party/d3-timer` | `v3.0.1` | `441e45b3f582762cd20035d47b40e9759ed1b235` | 2021-06-05 | ISC | `Mike Bostock` | `Copyright 2010-2021 Mike Bostock` |
   | `third_party/d3-transition` | `v3.0.1` | `c4c94c421e2ef9e9ffc253fab33ccf99f1434901` | 2021-06-09 | ISC | `Mike Bostock` | `Copyright 2010-2021 Mike Bostock` |
   | `third_party/d3-zoom` | `v3.0.0` | `debbe3d76d86ea96965ed4cc61beb6bdf7238156` | 2021-06-09 | ISC | `Mike Bostock` | `Copyright 2010-2021 Mike Bostock` |
   | `third_party/internmap` | `v2.0.3` | `78db0b387b951c036f7a8d6580d98afd8f416a5e` | 2021-09-19 | ISC | `Mike Bostock` | `Copyright 2021 Mike Bostock` |
   | `third_party/delaunator` | `v5.1.0` | `3ce65210ba78a8f02ec6e73cf202838d7df14051` | 2026-03-22 | ISC | `Mapbox` | `Copyright (c) 2026, Mapbox` |
   | `third_party/robust-predicates` | `v3.0.3` | `8bed7fadb4284911e1111876e54a6f8acfa445cd` | 2026-03-22 | Unlicense | `Vladimir Agafonkin` | none (a public-domain dedication) |

   - The commit is the tagged commit. For an annotated tag, the gitlink and the `commit` of the
     entry hold this commit, not the tag object. d3-format `v3.1.2` and d3-scale-chromatic
     `v3.1.0` are lightweight tags.
   - The date is the date of the tagged commit. For each annotated tag, the tagger date is the
     same day.
   - Each `.gitmodules` entry has `shallow = true`, as the Chart.js entries do. The analysis
     excludes the submodules (`third_party/**` in `analysis_options.yaml`).
     `dart run melos run upstream` clones every `third_party` submodule at its pin.
5. **Pin checks.**
   - `tool/check_upstream_pin.sh` (`dart run melos run upstream:check`, CI job `upstream-pin`)
     keeps its Chart.js check. It also fails unless the `third_party/d3` gitlink is the commit of
     tag `v<d3Version>`.
   - The script also fails unless each other D3 gitlink is the upstream commit of the `ref` of
     its entry (`git ls-remote`). The script needs no submodule checkout.
   - `packages/flutter_d3_port/test/upstream_test.dart` (`@TestOn('vm')`) compares `d3Version`
     with the `version` of `third_party/d3/package.json` when the submodule is present.
   - The test also compares each gitlink (`git ls-files -s third_party/<repository name>`) with
     the `commit` of its entry. This command reads the index. Thus it works for staged and for
     committed gitlinks.
   - The script and the test also fail on a submodule of `.gitmodules` that no entry pins. The
     Chart.js `port_sources.yaml` gives the entries of the three Chart.js submodules. Thus a new
     D3 submodule needs an entry.
   - From D3 phase 1, the shared tool 2 of `port_tools`
     ([ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md)) also compares
     each D3 gitlink with its entry. The Chart.js tool does this for the Chart.js pins now.
6. **Source list.** `packages/flutter_d3_port/tool/port_sources.yaml` has 34 entries, one for each
   repository. The entries have the keys of the Chart.js file. The `version_source` of an entry
   names the range, the `package.json` line of the range and the date of the resolution. It also
   names the version of the d3 v7.9.0 `yarn.lock`. The `holder` follows item 8. The `notices` key
   of item 12 records code from a third project inside a repository.
7. **[ADR 0006](../../../../docs/adr/0006-follow-upstream-between-releases.md) for D3.**
   - **Status unit.** The status unit is one upstream source file, as in Chart.js. A "module" of
     ADR 0006 items 2, 4 and 5 is one such file. [parity.md](../parity.md) groups the files by
     repository.
   - **Newest tag.** The newest upstream tag is per repository. For `third_party/d3`, it is the
     newest release tag of d3. For each other repository, it is the newest release tag inside
     the ranges of the pinned d3 `package.json` (item 3). A tag outside these ranges does not
     count until a d3 release adds it to a range.
   - **Basis of the range limit.** The range limit applies ADR 0006 item 4. It is not an
     exception to that item. ADR 0006 item 4 puts the bump first when a bump can move the pin to
     a newer tag. The pin rule of item 3 does not let a bump pin a tag outside the ranges. Each
     port lists its other projects in its own ADR (ADR 0005, Consequences). In the same way,
     Chart.js ADR 0035 item 5 pins `@kurkle/color` and chartjs-test-utils at the
     versions of the Chart.js lockfile, not at their newest tags.
   - **Bump first.** Before a file goes from `not started` to `in progress`, the porter lists the
     newer tags of its repository (ADR 0006 item 4).
   - **Bump unit.** A bump moves one repository: its submodule, its entry and the headers of its
     files. ADR 0005 item 5 gives the steps. The bump also changes the `version`, `ref`, `commit`
     and `version_source` of the entry. A bump of `third_party/d3` also changes `d3Version`.
   - **Range change.** After a bump of `third_party/d3`, the porter applies the pin rule with the
     new ranges. Each repository that the new ranges move gets its own bump.
   - **Ledger.** [The upstream ledger](../upstream-ledger.md) has one section for each repository.
     A row is one merged upstream PR after the pinned tag on the default branch. A commit without
     a PR also gets a row.
   - **Commit pin.** The two conditions of ADR 0006 item 5 apply per repository. On 2026-10-20,
     31 of the 34 pinned tags are more than 12 months old. Only the d3-format, delaunator and
     robust-predicates tags are from 2026.
   - **Commit pin version.** For a commit pin of a module repository, the `version` of its entry
     reads `<last version>+<sha8>`. A commit pin of `third_party/d3` gives the same form to
     `d3Version`. The PR of the first D3 commit pin extends the checks of item 5, as ADR 0006
     states.
8. **Holder strings.** Each project has one holder string. The header, `port_sources.yaml`, the
   package `LICENSE` and the last `REUSE.toml` table that matches the file use this string.
   - The holder is the first copyright line of the repository `LICENSE` at the pin. It omits
     `Copyright`, `(c)`, the years and the comma before the name.
   - The robust-predicates `LICENSE` has no copyright line. Its holder is the `author` of its
     `package.json` (`:9`).

   | Holder | Repositories |
   |---|---|
   | `Mike Bostock` | d3, internmap and the 29 d3-* repositories other than d3-delaunay (d3-ease included) |
   | `Observable, Inc.` | d3-delaunay |
   | `Mapbox` | delaunator |
   | `Vladimir Agafonkin` | robust-predicates |

   Header examples:
   - `// Ported from d3-array v3.2.4 src/ticks.js (ISC, Mike Bostock).`
   - `// Ported from d3-ease v3.0.1 src/back.js (BSD-3-Clause, Mike Bostock).`
   - `// Ported from d3-delaunay v6.0.4 src/voronoi.js (ISC, Observable, Inc.).`
   - `// Ported from delaunator v5.1.0 index.js (ISC, Mapbox).`
   - `// Ported from robust-predicates v3.0.3 src/orient2d.js (Unlicense, Vladimir Agafonkin).`

   The header pattern reads the license up to the first comma
   (`packages/flutter_chartjs_port/tool/src/headers.dart:9-11`). Thus `Observable, Inc.` is a valid
   holder. The package `LICENSE` and the `REUSE.toml` table of the files also get the other
   copyright lines of a repository `LICENSE`. Examples are Robert Penner in d3-ease and Mapbox in
   d3-delaunay.

   For robust-predicates, the `REUSE.toml` table lists `Vladimir Agafonkin` with no year. This
   text names the author of the dedication. It makes no copyright claim.
9. **License of the port's code.** The port's own code is ISC.
   - In phase 0, `packages/flutter_d3_port/LICENSE` starts with the line `ISC License`. Two
     copyright lines follow: `Copyright 2010-2026 Mike Bostock` and
     `Copyright 2026 Vasiliy Ditsyak`. The ISC text of the 32 ISC repositories comes last.
   - The line of Mike Bostock merges the ten year ranges of the pins into one line. Item 4 keeps
     the exact line of each repository. The union 2010-2026 covers every range. All other lines
     stay verbatim, as Chart.js ADR 0035 item 6 asks.
   - The `REUSE.toml` table for `packages/flutter_d3_port/**` has `SPDX-License-Identifier = "ISC"`
     and the copyrights `2010-2026 Mike Bostock` and `2026 Vasiliy Ditsyak`. It replaces the MIT
     table `**` for the package.
   - Phase 0 adds `LICENSES/ISC.txt` and no other `LICENSES/` file.
10. **Other license components.** Each component is part of the change that ports the first file
    that it covers (AGENTS.md Licensing). A new `LICENSES/` file is part of the change with its
    first `REUSE.toml` annotation. `reuse lint` fails on a license file that no annotation uses.
    The `holder` of a `notices` item (item 12) uses the holder string of this table.

    | Component | Evidence at the pin | SPDX | Holder string | Lines in the package `LICENSE` | Form | `LICENSES/` | `REUSE.toml` table | First phase |
    |---|---|---|---|---|---|---|---|---|
    | d3-ease, the whole repository | `d3-ease/LICENSE:1-28`, `package.json:18` | BSD-3-Clause | `Mike Bostock`, `Robert Penner` | `Copyright 2010-2021 Mike Bostock`, `Copyright 2001 Robert Penner` | a separate component with the full BSD-3-Clause text | `BSD-3-Clause.txt` (present) | the d3-ease Dart files and specs: `"BSD-3-Clause AND ISC"`, the two lines and the port line | 2 |
    | ColorBrewer, 35 files of d3-scale-chromatic | `d3-scale-chromatic/LICENSE:15-28` | Apache-2.0 | `Cynthia Brewer, Mark Harrower, and The Pennsylvania State University` | `Copyright 2002 Cynthia Brewer, Mark Harrower, and The Pennsylvania State University` | a separate component: the upstream notice, a statement that the Dart files are changed, and the full Apache-2.0 text | `Apache-2.0.txt` (new) | the 35 Dart files: `"Apache-2.0 AND ISC"`, `2010-2024 Mike Bostock`, the ColorBrewer line and the port line | 2 |
    | GeographicLib, a pass-through notice of d3-geo | `d3-geo/LICENSE:15-34` | MIT | `Charles Karney` | `Copyright 2008-2012 Charles Karney` | a separate component that states that no file derives from GeographicLib | `MIT.txt` (present) | none | 5 |
    | quickselect, one file of d3-array | `d3-array/src/quickselect.js:3-4` | ISC | `Vladimir Agafonkin` | `Copyright 2018 Vladimir Agafonkin` | a line of the ISC block | none | the Dart port of `quickselect.js`: ISC, `2010-2023 Mike Bostock`, `2018 Vladimir Agafonkin` and the port line | 2 |
    | d3-delaunay | `d3-delaunay/LICENSE:1-2` | ISC | `Observable, Inc.`, `Mapbox` | `Copyright 2018-2021 Observable, Inc.`, `Copyright 2021 Mapbox` | two lines of the ISC block | none | the d3-delaunay Dart files and specs: ISC, `2018-2021 Observable, Inc.`, `2021 Mapbox` and the port line | 5 |
    | delaunator | `delaunator/LICENSE:3` | ISC | `Mapbox` | `Copyright (c) 2026, Mapbox` | a line of the ISC block | none | the delaunator Dart files and specs: ISC, `2026 Mapbox` and the port line | 5 |
    | robust-predicates | `robust-predicates/LICENSE:1-24`, `package.json:9-10` | Unlicense | `Vladimir Agafonkin` | none | a separate component with the full Unlicense text | `Unlicense.txt` (new) | the robust-predicates Dart files and specs: `"Unlicense AND ISC"`, `Vladimir Agafonkin` and the port line | 5 |
    | internmap | `internmap/LICENSE:1` | ISC | `Mike Bostock` | the merged Bostock line | none | none | the package table | 2 |

    - **ColorBrewer.** These are the 35 files:
      - `src/categorical/`: Accent, Dark2, Paired, Pastel1, Pastel2, Set1, Set2 and Set3
      - all 9 files of `src/diverging/`
      - all 6 files of `src/sequential-single/`
      - `src/sequential-multi/`: BuGn, BuPu, GnBu, OrRd, PuBu, PuBuGn, PuRd, RdPu, YlGn, YlGnBu,
        YlOrBr and YlOrRd
    - **No NOTICE content.** The default branch of `axismaps/colorbrewer` (commit `7d135fc`,
      2021-05-03) has `LICENCE.txt` with the Apache-2.0 text and no NOTICE file (`gh api`,
      2026-10-20). d3-scale-chromatic has no NOTICE file. Thus the component has no NOTICE text.
    - **Changed files.** Apache-2.0 section 4(b) asks for a notice in each changed file. The
      `// Ported from` header of each Dart file states that the file is a Dart port of the source
      file. The d3-scale-chromatic spec `test/index-test.js` holds no scheme data. The package
      table covers its port.
    - **GeographicLib.** No file of d3-geo v3.1.1 `src/` names GeographicLib or Karney (`grep`, 0
      hits). d3/d3-geo@2f59a1e7 (2020-07-30) removed `src/adder.js`. That file said "Code adapted
      from GeographicLib by Charles F. F. Karney" (`gh api`, the parent commit `c1f9fd1`). The
      component stays, because the d3-geo `LICENSE` at the pin carries the notice. It costs one
      MIT block and no new `LICENSES/` file.
    - **quickselect.** The Dart file keeps the two upstream comment lines below its header. The
      notice uses the year of the comment, 2018.
    - **robust-predicates.** Its `README.md:3` calls it "A modern port of Jonathan R Shewchuk's C
      code". The header of Shewchuk's `predicates.c` reads "Placed in the public domain by"
      (line 9). The port needs no Shewchuk notice.
    - **No notice.** The research found no other code from a third project. These cases need no
      notice:
      - The colormaps of d3-scale-chromatic that are not ColorBrewer. They are data from CC0
        sources, polynomial fits by D3 authors, short color lists and formulas.
      - The references to papers and algorithms in comments, for example
        `d3-hierarchy/src/tree.js:99`.
      - The locale files of d3-format (59) and d3-time-format (34). They are module files under
        the module license.
      - The d3-contour code "Based on" shapefile and topojson-client (`src/contours.js:51,81-82`).
        Mike Bostock is the holder of that code. d3-contour publishes it under ISC.
11. **fsum (maintainer decision).** `d3-array/src/fsum.js:1` links `Modules/mathmodule.c#L1423` of
    CPython at commit `a74eea23`. The file follows CPython `math_fsum`. CPython is PSF-2.0. The
    port follows upstream d3-array:
    - The package `LICENSE` gets no PSF-2.0 component. `LICENSES/` gets no `PSF-2.0.txt`. No
      `REUSE.toml` table names PSF-2.0.
    - The Dart file keeps the upstream URL comment below its header.

    The reasons:
    1. The port translates `d3-array/src/fsum.js` at its pin. d3-array publishes this file under
       ISC, with no PSF notice.
    2. The port reads no CPython file (AGENTS.md rule 1).
    3. CPython credits the method to recipes of Raymond Hettinger and Mark Dickinson
       (`mathmodule.c:1315-1318` at `a74eea23`). The port takes the method through d3-array.
    4. The URL comment keeps the origin of the method visible.

    If a later review finds code that the port takes directly from CPython, a new ADR supersedes
    this item.
12. **Embedded notices.** A `notices` list in an entry of `port_sources.yaml` records code from a
    third project inside that repository. An item has these keys:
    - `project`: the name of the third project.
    - `url`: its home page or repository.
    - `spdx`: the SPDX ID of its notice.
    - `holder`: the holder string of item 10.
    - `evidence`: the path and lines of the notice at the pin.
    - `files`: the source paths that hold the code, relative to the repository root. A
      pass-through notice has no files.

    ```yaml
      - header: d3-scale-chromatic
        # ... the keys of item 6
        notices:
          - project: ColorBrewer
            url: http://colorbrewer2.org
            spdx: Apache-2.0
            holder: Cynthia Brewer, Mark Harrower, and The Pennsylvania State University
            evidence: LICENSE:15-28
            files:
              - src/categorical/Accent.js
              # ... the other 34 files of item 10
    ```

    - The three items are ColorBrewer in d3-scale-chromatic, quickselect in d3-array
      (`https://github.com/mourner/quickselect`, ISC, `Vladimir Agafonkin`,
      `src/quickselect.js:3-4`) and GeographicLib in d3-geo (MIT, `Charles Karney`,
      `LICENSE:15-34`, no files).
    - An item is part of the change that ports the first file that it covers, with its `LICENSE`
      component. For GeographicLib, this is the change with the first d3-geo file.
    - A header never names a `notices` project. The header names the repository that the port
      reads.
    - From D3 phase 1, the shared tool 2 of `port_tools`
      ([ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md)) reads the items.
      It fails when the package `LICENSE` does not name the holder. It fails when a path of
      `files` does not exist at the pin. It fails when the last `REUSE.toml` table of the Dart
      file of a path does not list the holder and the SPDX ID.
13. **Doc comments from the d3 docs.** A doc comment can adapt text of `third_party/d3/docs/` at the
    pin. Take the text from the pinned files, not from the live d3js.org site (AGENTS.md rule 1).
    - The adapted text gets no second `// Ported from` line. Each such line maps one source file
      to one Dart path (`packages/flutter_chartjs_port/tool/src/port_headers.dart:868-877`). One docs
      page covers many source files.
    - The adapted text needs no extra notice. The d3 `LICENSE` (ISC, `Copyright 2010-2023 Mike
      Bostock`) covers the whole repository. `docs/` has no license file of its own. The package
      `LICENSE` and the package table name Mike Bostock.
    - Some last `REUSE.toml` tables do not list Mike Bostock: the tables of d3-delaunay,
      delaunator and robust-predicates. When a doc comment of such a file adapts docs text, that
      table also gets `2010-2023 Mike Bostock`.
    - A bump of `third_party/d3` also reviews the diff of `docs/`.
14. **Test data of later phases.** Phase 0 pins no test data. These npm packages of the upstream
    tests are outside the 34 repositories (npm registry, 2026-10-20):

    | Package | Range | Newest in range | License | Upstream users | Phase |
    |---|---|---|---|---|---|
    | world-atlas | `1` (d3-geo `package.json`) | 1.1.4 | BSD-3-Clause | d3-geo `test/projection/fit-test.js:9`, `test/snapshots.js:28` | 5 |
    | topojson-client | `3` (d3-geo `package.json`) | 3.1.0 | ISC | d3-geo `test/projection/fit-test.js:3`, `test/snapshots.js:2` | 5 |
    | csv-spectrum | `1` (d3-dsv `package.json`) | 1.0.0 | BSD-2-Clause | d3-dsv `test/csv-test.js:2,81` | 3 |
    | robust-orientation | `^1.2.1` (robust-predicates `package.json`) | 1.2.1 | MIT | robust-predicates `test/test.js:5,31`, the `orient2d` test | 5 |
    | nextafter | `^1.0.0` (robust-predicates `package.json`) | 1.0.0 | MIT | robust-predicates `test/test.js:6,58,110,197`, only the `incircle`, `orient3d` and `insphere` tests | none |

    The phase that ports such a test applies these rules in the same change:
    1. A VM-only test (`@TestOn('vm')`) can read the data at test time from a reference-only
       shallow submodule (ADR 0005 item 2). The submodule pins the newest tag in the
       `devDependencies` range of the pinned repository. It gets an entry in `port_sources.yaml`
       for the pin checks. The package then holds no copy. It needs no notice.
    2. Data in this tree needs a notice in the package `LICENSE`, a `REUSE.toml` table and a
       `LICENSES/` file, as code does. This rule applies to a copy and to generated values.
    3. A Dart port of robust-orientation or nextafter code is code from another project. Item 18
       applies.
    4. Some data files of the 34 repositories come from outside sources, for example
       `d3-array/test/data/athletes.csv`, `d3-geo/test/data/us-10m.json` and
       `robust-predicates/test/fixtures/orient2d.txt`. These files stay in the submodules.
       VM-only tests read them there. The port copies none of them into the package before it
       knows their origin.

    [D3 ADR 0004](0004-spec-harness.md) states how the spec harness reads these files.
15. **CI checkout by path.** Each CI job that needs submodules fetches only the submodules that
    its steps read, by path. The jobs of the Chart.js port read `third_party/Chart.js`,
    `third_party/kurkle-color` and `third_party/chartjs-test-utils`. The ubuntu leg of `test` also
    reads `third_party/d3` for `upstream_test.dart`. The job `upstream-pin` needs no submodule. A
    later D3 job or check adds the D3 paths that it reads.
16. **Reference only.** The rules of [ADR 0005](../../../../docs/adr/0005-pin-upstream-sources.md)
    item 2 apply to each of the 34 submodules. robust-predicates needs one more rule:
    - Its `src/*.js` files hold macros, for example `$Two_Diff_Tail(...)`. `compile.js` expands
      them into `esm/` at build time. `esm/` is not in git.
    - The port expands the macros by hand. `compile.js` gives their definitions. Each expanded
      block names its macro in a comment.
    - A tool can build `esm/` for review in a throwaway clone outside this repository.
17. **Not pinned and not ported.** The port pins only the 34 repositories of item 4. It does not
    pin CPython, GeographicLib, ColorBrewer, mourner/quickselect, the npm packages of item 14 or
    the npm tools of the upstream builds. The port does not port these parts of the pinned
    repositories:
    - **The command-line tools of d3-dsv.** These are the three files of `bin/`: `dsv2dsv.js`,
      `dsv2json.js` and `json2dsv.js`. Their dependencies `commander`, `iconv-lite` and `rw`
      (`d3-dsv/package.json:37-41`) serve only `bin/`. No file of `src/` imports them.
    - **The docs sites.** These are `d3/docs/`, `d3/API.md`, `delaunator/docs/`, the `README.md`
      and `CHANGES.md` files and the `img/` folders. Item 13 lets doc comments adapt the text.
    - **The build files.** These are `rollup.config.js`, `d3/bundle.js`, `d3/prebuild.sh`,
      `robust-predicates/compile.js`, `delaunator/tsconfig.json`, `eslint.config.js`, the
      lockfiles and the `package.json` scripts. The port reads `compile.js` for the macros only.
    - **The type declarations.** robust-predicates tracks `index.d.ts`. delaunator v5.1.0 tracks
      no declaration file. Its `tsc` step writes `index.d.ts` from the JSDoc types
      (`package.json:30`, `tsconfig.json:9`). Git ignores that file (`.gitignore:7`).
    - **The benchmarks.** These are `d3-quadtree/test/benchmark.js`,
      `d3-hierarchy/test/pack/bench-enclose.js`, `delaunator/bench.js` and
      `robust-predicates/bench.js`.
    - **The other predicates.** These are `src/orient3d.js`, `src/incircle.js` and
      `src/insphere.js` of robust-predicates. No D3 code calls them. delaunator imports only
      `orient2d` (`index.js:5` at `v5.1.0`). Their status is `n/a`. Their upstream cases skip with
      an `n/a:` reason. The ported files are `src/orient2d.js`, with `orient2dfast`, and
      `src/util.js`. `index.js` re-exports `esm/`, a build output.
    - **The test tools.** These are jsdom, js-beautify, htl, node-canvas, pngjs and pixelmatch.
      The later decisions on the DOM layer (gate 7) and on image snapshots (gate 5) cover the
      cases that use them. [D3 ADR 0004](0004-spec-harness.md) replaces mocha, vitest and the Node
      `assert` module.
18. **New sources.** Code from a project outside the 34 repositories needs four things in the same
    change:
    1. an entry in `port_sources.yaml`
    2. its notice in the package `LICENSE`
    3. a `REUSE.toml` table
    4. the header of AGENTS.md rule 2

    A source with a git repository also needs a shallow submodule. Code from a third project inside
    a pinned repository needs a `notices` item (item 12) in place of an entry. Never copy code from
    GPL or otherwise incompatible projects.

## Alternatives considered

- **The d3 v7.9.0 lockfile set** (d3-format 3.1.0, delaunator 5.0.1, robust-predicates 3.0.2).
  The maintainer rejected this set. This set matches the published `dist/d3.js`. Its cost is that
  d3-format stays at 3.1.0 with no exit:
  - The changes of 3.1.1 are behavior changes and a feature. ADR 0006 item 2 never takes them as
    backports.
  - d3 has no tag after v7.9.0. Thus ADR 0006 item 4 gives no bump.
  - The `yarn.lock` of the d3 default branch still locks 3.1.0 (`:1155-1156`, `gh api`,
    2026-10-20). Thus ADR 0006 item 5 gives no commit pin.

  The Chart.js reason for its lockfile does not apply. Chart.js ADR 0035 keeps the lockfile
  versions because the Chart.js specs and fixture thresholds come from them. Each D3 repository
  brings its own specs at its own tag. The d3 bundle test examines only the exports.
- **The newest tag of each repository, without the ranges.** Rejected. Today the set is the same.
  Later, a new major outside the ranges can break the bundle index and the docs of the pinned d3.
- **Nested submodules at `third_party/d3/<repository name>`.** Rejected. `third_party/d3` is itself
  a submodule. Its work tree cannot hold other submodules of this repository.
- **A version constant in code for each repository.** Rejected. ADR 0005 item 4 asks for the
  version of the upstream repository in code. Chart.js ADR 0035 compares only the gitlinks of its
  other projects. The pin script of item 5 also compares each D3 gitlink with its tag.
- **Combined holder strings,** for example `Mike Bostock and Robert Penner` for d3-ease or
  `Observable, Inc. and Mapbox` for d3-delaunay. Rejected. Tool 2 requires the exact string in the
  package `LICENSE` and in the `REUSE.toml` copyright list. Neither file holds a combined string.
- **A header without a holder for robust-predicates.** Rejected. It changes the header grammar of
  the shared tools ([ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md)) for
  one project with two ported files.
- **Ten verbatim lines of Mike Bostock.** Rejected. The ten lines name the same holder. One line
  with the union of the years covers each of them.
- **A PSF-2.0 component for `fsum.js`.** The maintainer rejected it (item 11). It adds
  `LICENSES/PSF-2.0.txt` and a `REUSE.toml` table for one file that upstream publishes as ISC.
- **No GeographicLib component.** Rejected. Chart.js ADR 0035 item 6 takes the notices from the
  license file at the pin.
- **Separate `port_sources.yaml` entries for ColorBrewer and quickselect.** Rejected. A header then
  names a project that the port does not read (AGENTS.md rule 1). Each entry also needs a pin.
- **The bundle banner as the only notice.** Rejected. `dist/d3.js:1` names only Mike Bostock. It
  omits Observable, Mapbox, Robert Penner, Charles Karney and ColorBrewer.
- **A second `// Ported from` line for docs text.** Rejected (item 13).
- **`submodules: true` in each CI job.** Rejected. Each of these jobs then clones 34 more
  repositories that it does not read.

## Consequences

- `.gitmodules` lists 37 submodules. A plain `git clone` downloads none of them.
  `dart run melos run upstream` clones all of them, at depth 1.
- Contributors read each D3 source at its pin, as they read Chart.js.
- The port differs from the published `dist/d3.js` of v7.9.0 in these d3-format edge cases:
  - `formatPrefix` with parentheses or a width
  - `s` with NaN or ±Infinity
  - `r` with zero
  - `precisionFixed`, `precisionRound` and `precisionPrefix` with a step of zero

  The specs of d3-format v3.1.2 pin the new behavior.
- `d3Version` names the bundle only. The header of each ported file names its own repository and
  tag.
- Phase 0 adds `LICENSES/ISC.txt` only. `Apache-2.0.txt` and `Unlicense.txt` are part of the
  first ported files of d3-scale-chromatic and robust-predicates.
- The ledger has 34 sections. Most pinned tags are more than 12 months old. Thus the first
  condition of ADR 0006 item 5 is true for most repositories. The changes on their default
  branches decide each commit pin.
- Two unreleased upstream changes can make a commit pin due. They are d3-quadtree `7224f73` (#43,
  a feature, phase 2) and d3-delaunay `dc894a1` (#145, a behavior change, phase 5). The ledger
  triages them.
- From D3 phase 1, the shared tool 2 of `port_tools` reads the `notices` key.
- A new major of a module does not count until a d3 release adds it to a range (item 7).
