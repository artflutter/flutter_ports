# D3 parity tracker

This file tracks the port of the 34 pinned D3 repositories. Each repository is a shallow git
submodule `third_party/<repo>` at the tag of [`tool/port_sources.yaml`](../tool/port_sources.yaml)
([D3 ADR 0001](adr/0001-upstream-sources.md)). Run `dart run melos run upstream` to clone them.

Phase 0 ports no file. Thus each row has the status `not started`. In phase 0, this file has one
row for each repository. A person writes it by hand. The status unit is one upstream source file
(D3 ADR 0001). Thus the status of a repository row applies to each of its source files.

From phase 2, tool 6 ([porting-flow.md](porting-flow.md) §4) writes this file from
`doc/status.yaml`, with one row for each upstream source file. Until then, each port change edits
this file in the same change as the code.

Status values ([porting-flow.md](porting-flow.md) §1 step 7, the values of the Chart.js port):

- `not started`: the module has no Dart code.
- `in progress`: Dart code exists for a part of the module.
- `partial: <symbols>`: the port has only the listed symbols, because a ported module needs them.
- `ported`: the Dart code and the ported tests pass. For a pure-layer module, the tests pass on the
  VM, with dart2js and with dart2wasm. This is the last status of a module. The port has no
  `verified` status ([ADR 0006](../../../docs/adr/0006-follow-upstream-between-releases.md)).
- `replaced`: a Flutter file replaces the upstream file.
- `distributed`: the port mirrors a type declaration file as `abstract interface class`
  declarations. The D3 `src/` folders have no type declaration files. The value stays in the list
  for tool 6. Tool 6 serves both ports
  ([ADR 0008](../../../docs/adr/0008-shared-js-runtime-and-port-tools.md)).
- `n/a: <reason>`: the port does not port the file, for the stated reason.

## Repositories

The columns:

- **Source files** and **Lines**: the `src/**/*.js` files that git tracks at the tag, and the sum
  of their `wc -l` counts. delaunator counts only `index.js`, its one source file.
  robust-predicates counts its five `src/*.js` files ([Notes](#notes)).
- **Test files**: the files that the upstream test runner runs. These are the
  `test/**/*-test.js` files, `test/snapshot.js` of d3-contour and `test/test.js` of delaunator
  and robust-predicates.
- **Cases**: the static count of the `it(`, `it.skip(` and `test(` calls at the start of a line
  of the test files, without block comments. Loops make more cases at run time. Tool 4 records the
  run-time cases from phase 2.
- **Phase**: the phase of the [roadmap](README.md#roadmap) that ports the files. When a repository
  has files in two phases, the cell names the files of each phase, with their counts.

| Repository | Tag | Source files | Lines | Test files | Cases | Phase | Status |
|---|---|---:|---:|---:|---:|---|---|
| [d3](https://github.com/d3/d3/tree/v7.9.0) | v7.9.0 | 1 | 30 | 2 | 2 | 1, then each phase: the bundle index grows with each ported module | not started |
| [d3-array](https://github.com/d3/d3-array/tree/v3.2.4) | v3.2.4 | 61 | 1384 | 65 | 530 | 1: `ticks.js`, `nice.js` and `range.js` (3 files, 86 lines, 42 cases). 2: the other files | not started |
| [d3-axis](https://github.com/d3/d3-axis/tree/v3.0.0) | v3.0.0 | 3 | 183 | 2 | 10 | 7 | not started |
| [d3-brush](https://github.com/d3/d3-brush/tree/v3.0.0) | v3.0.0 | 5 | 652 | 1 | 1 | 7 | not started |
| [d3-chord](https://github.com/d3/d3-chord/tree/v3.0.1) | v3.0.1 | 6 | 272 | 2 | 8 | 4 | not started |
| [d3-color](https://github.com/d3/d3-color/tree/v3.1.0) | v3.1.0 | 6 | 595 | 8 | 170 | 2 | not started |
| [d3-contour](https://github.com/d3/d3-contour/tree/v4.0.2) | v4.0.2 | 9 | 416 | 3 | 23 | 5 | not started |
| [d3-delaunay](https://github.com/d3/d3-delaunay/tree/v6.0.4) | v6.0.4 | 5 | 636 | 2 | 41 | 5 | not started |
| [d3-dispatch](https://github.com/d3/d3-dispatch/tree/v3.0.1) | v3.0.1 | 2 | 85 | 1 | 36 | 2 | not started |
| [d3-drag](https://github.com/d3/d3-drag/tree/v3.0.0) | v3.0.0 | 6 | 266 | 1 | 1 | 7 | not started |
| [d3-dsv](https://github.com/d3/d3-dsv/tree/v3.0.1) | v3.0.1 | 5 | 209 | 4 | 136 | 3 | not started |
| [d3-ease](https://github.com/d3/d3-ease/tree/v3.0.1) | v3.0.1 | 12 | 273 | 10 | 77 | 2 | not started |
| [d3-fetch](https://github.com/d3/d3-fetch/tree/v3.0.1) | v3.0.1 | 8 | 83 | 1 | 1 | 7 | not started |
| [d3-force](https://github.com/d3/d3-force/tree/v3.0.0) | v3.0.0 | 12 | 693 | 5 | 16 | 6 | not started |
| [d3-format](https://github.com/d3/d3-format/tree/v3.1.2) | v3.1.2 | 16 | 344 | 24 | 168 | 1 | not started |
| [d3-geo](https://github.com/d3/d3-geo/tree/v3.1.1) | v3.1.1 | 58 | 3280 | 32 | 343 | 5 | not started |
| [d3-hierarchy](https://github.com/d3/d3-hierarchy/tree/v3.1.2) | v3.1.2 | 34 | 1414 | 18 | 83 | 2 | not started |
| [d3-interpolate](https://github.com/d3/d3-interpolate/tree/v3.0.1) | v3.0.1 | 26 | 595 | 22 | 149 | 2: the other files. 6: `zoom.js` (1 file, 71 lines, 5 cases). 7: `transform/` (3 files, 107 lines, 0 cases) | not started |
| [d3-path](https://github.com/d3/d3-path/tree/v3.1.0) | v3.1.0 | 2 | 157 | 2 | 64 | 1 | not started |
| [d3-polygon](https://github.com/d3/d3-polygon/tree/v3.0.1) | v3.0.1 | 7 | 135 | 5 | 23 | 2 | not started |
| [d3-quadtree](https://github.com/d3/d3-quadtree/tree/v3.0.1) | v3.0.1 | 15 | 413 | 13 | 62 | 2 | not started |
| [d3-random](https://github.com/d3/d3-random/tree/v3.0.1) | v3.0.1 | 20 | 370 | 18 | 67 | 2 | not started |
| [d3-scale](https://github.com/d3/d3-scale/tree/v4.0.2) | v4.0.2 | 24 | 1302 | 19 | 433 | 3 | not started |
| [d3-scale-chromatic](https://github.com/d3/d3-scale-chromatic/tree/v3.1.0) | v3.1.0 | 48 | 557 | 1 | 1 | 2 | not started |
| [d3-selection](https://github.com/d3/d3-selection/tree/v3.0.0) | v3.0.0 | 54 | 1057 | 42 | 236 | 7 | not started |
| [d3-shape](https://github.com/d3/d3-shape/tree/v3.2.0) | v3.2.0 | 60 | 2193 | 41 | 268 | 4 | not started |
| [d3-time](https://github.com/d3/d3-time/tree/v3.1.0) | v3.1.0 | 12 | 488 | 36 | 465 | 3 | not started |
| [d3-time-format](https://github.com/d3/d3-time-format/tree/v4.1.0) | v4.1.0 | 5 | 754 | 8 | 146 | 3 | not started |
| [d3-timer](https://github.com/d3/d3-timer/tree/v3.0.1) | v3.0.1 | 4 | 151 | 5 | 42 | 6 | not started |
| [d3-transition](https://github.com/d3/d3-transition/tree/v3.0.1) | v3.0.1 | 29 | 953 | 33 | 180 | 7 | not started |
| [d3-zoom](https://github.com/d3/d3-zoom/tree/v3.0.0) | v3.0.0 | 6 | 523 | 4 | 25 | 6: `transform.js` (1 file, 51 lines, 10 cases). 7: the other files | not started |
| [delaunator](https://github.com/mapbox/delaunator/tree/v5.1.0) | v5.1.0 | 1 | 607 | 1 | 14 | 5 | not started |
| [internmap](https://github.com/mbostock/internmap/tree/v2.0.3) | v2.0.3 | 1 | 61 | 2 | 8 | 2 | not started |
| [robust-predicates](https://github.com/mourner/robust-predicates/tree/v3.0.3) | v3.0.3 | 5 | 1085 | 1 | 8 | 5: `orient2d.js` and `util.js` (2 files, 183 lines). The other three files are `n/a` ([Notes](#notes)) | not started |
| **All 34 repositories** | | **568** | **22216** | **434** | **3837** | | |
| **Without the `d3` bundle** | | **567** | **22186** | **432** | **3835** | | |

## By phase

The same counts, grouped by the Phase column. Phase 0 and phase 8 port no upstream file. Phase 5
counts all five robust-predicates files.

| Phase | Source files | Lines | Cases |
|---|---:|---:|---:|
| 1. Decisions, tooling, pilot | 21 | 587 | 274 |
| 2. Pure data | 225 | 5618 | 1159 |
| 3. Time, DSV and scales | 46 | 2753 | 1180 |
| 4. Shapes and drawing on Flutter | 66 | 2465 | 276 |
| 5. Geometry | 78 | 6024 | 429 |
| 6. Motion and simulation | 18 | 966 | 73 |
| 7. DOM layer | 113 | 3773 | 444 |
| The `d3` bundle index (phases 1-8) | 1 | 30 | 2 |
| **Total** | **568** | **22216** | **3837** |

## Notes

- **d3.** `src/index.js` re-exports the 30 modules. At run time, `test/d3-test.js` makes one case
  for each dependency of `package.json` (`test/d3-test.js:10-11`), thus 30 cases.
  `test/docs-test.js` examines the internal links of the docs site.
- **delaunator.** The source file is `index.js` at the repository root. It has 607 lines at
  v5.1.0. The v5.0.1 file of the d3 v7.9.0 `yarn.lock` has 480 lines. Most of the added lines are
  JSDoc types.
- **robust-predicates.** The count has the five `src/*.js` files at v3.0.3: `incircle.js`,
  `insphere.js`, `orient2d.js`, `orient3d.js` and `util.js`. These files are macro source.
  `compile.js` expands the macros into `esm/` when the package builds. `esm/` is not in git. The
  count does not include the root files `index.js` (a re-export of `esm/`), `compile.js`,
  `bench.js` and `rollup.config.js`. D3 calls only `orient2d` (delaunator v5.1.0 `index.js:5`).
  Thus [D3 ADR 0001](adr/0001-upstream-sources.md) item 17 (proposed) gives the other three files
  the status `n/a`. Until a port change applies it, the row keeps the status `not started`.
- **Three files that no file of their repository imports.** These are d3-scale `src/colors.js`,
  d3-scale-chromatic `src/rampClosed.js` and d3-selection `src/identity.js`. The count includes
  them. The port of their repository decides their status.
- **Files outside `src/`.** The count does not include these files:
  - 93 locale files: 59 in `d3-format/locale/` (379 lines) and 34 in `d3-time-format/locale/`
    (340 lines). The decision "Locale data" ([porting-flow.md](porting-flow.md) §2.10, gate 2)
    gives their Dart form.
  - the three command-line scripts of `d3-dsv/bin/`. They are not library code.
  - 31 test data files in `test/data/` and `test/fixtures/`.
  - 20 snapshot files: 16 PNG files of d3-geo, 2 HTML files of d3-axis and 2 SVG files of
    d3-contour. The decision "Image snapshots" ([porting-flow.md](porting-flow.md) §2.13, gate 5)
    gives their use.
  - the shell script `d3-time/test/test-time-zones`, with 32 active checks and 6 checks in
    comments. The upstream test script does not run it.
- **File names.** 107 of the 567 module source names do not match `^[a-z_][a-z0-9_]*$`. 106 of
  the 431 `*-test.js` names do not match it either. The match reads the name without `.js` and
  without `-test.js`. Thus the Dart files of these names fail the `file_names` lint.
  [D3 ADR 0002](adr/0002-file-naming-and-layout.md) gives the rule for them. One name has a `%`:
  `d3-format/test/format-type-%-test.js`.

## Count script

The four count columns come from this script. Save it as `count.sh` outside the repository. Then
run it from the repository root after `dart run melos run upstream`:

```sh
bash count.sh third_party/d3 third_party/d3-* third_party/internmap \
  third_party/delaunator third_party/robust-predicates
```

For each repository, it prints the name, the source files, the lines, the test files and the
cases. It reads only the files that git tracks. It runs no upstream code.

```sh
for r in "$@"; do
  n=$(basename "$r")
  case $n in
    delaunator) src=index.js; tests=test/test.js ;;
    robust-predicates) src=$(git -C "$r" ls-files 'src/*.js'); tests=test/test.js ;;
    *) src=$(git -C "$r" ls-files 'src/*.js'); tests=$(git -C "$r" ls-files 'test/*-test.js') ;;
  esac
  [ "$n" = d3-contour ] && tests="$tests test/snapshot.js"
  lines=$(cd "$r" && cat $src | wc -l)
  cases=$(cd "$r" && for f in $tests; do perl -0777 -pe 's{/\*.*?\*/}{}gs' "$f"; echo; done |
    grep -cE '^\s*(it|test)(\.skip|\.only)?\(')
  echo "$n $(echo $src | wc -w) $lines $(echo $tests | wc -w) $cases"
done
```

On 2026-10-20, the script ran over scratch clones at the tags of the table. It also ran over the
34 submodules of this repository. Both runs gave the same counts. A longer script of the same
research gave the other figures of this file from the same file lists. These are the split counts
of the Phase column, the [By phase](#by-phase) table and the figures of the [Notes](#notes).
