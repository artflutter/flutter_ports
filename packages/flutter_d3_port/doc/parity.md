# D3 parity tracker

This file tracks the port of the 34 pinned D3 repositories. Each repository is a shallow git
submodule `third_party/<repo>` at the tag of [`tool/port_sources.yaml`](../tool/port_sources.yaml)
([D3 ADR 0001](adr/0001-upstream-sources.md)). Run `dart run melos run upstream` to clone them.

d3-color is the first ported repository (2026-11-15), in the native Dart forms of
[D3 ADR 0007](adr/0007-native-dart-forms.md), as the package `flutter_d3_color_port`
([D3 ADR 0008](adr/0008-module-packages.md)). d3-interpolate is the second (2026-11-16), as the
package `flutter_d3_interpolate_port`, in the native forms of
[D3 ADR 0011](adr/0011-interpolate-native-forms.md). d3-scale-chromatic is the third (2026-11-26),
as the package `flutter_d3_scale_chromatic_port`, in the native forms of
[D3 ADR 0012](adr/0012-scale-chromatic-native-forms.md). d3-path is the fourth (2026-11-26), as the
package `flutter_d3_path_port`, in the native forms of
[D3 ADR 0014](adr/0014-path-native-forms.md). d3-shape is the fifth (2026-11-26), as the
package `flutter_d3_shape_port`, in the native forms of
[D3 ADR 0015](adr/0015-shape-native-forms.md). d3-format is the sixth (2026-11-26), as the
package `flutter_d3_format_port`, in the native forms of
[D3 ADR 0016](adr/0016-format-native-forms.md). d3-array is the seventh (2026-11-27), as the
package `flutter_d3_array_port`, in the native forms of
[D3 ADR 0017](adr/0017-array-native-forms.md). d3-contour is ported as the
package `flutter_d3_contour_port`, in the native forms of
[D3 ADR 0020](adr/0020-contour-native-forms.md). d3-hierarchy is ported as the
package `flutter_d3_hierarchy_port`, in the native forms of
[D3 ADR 0018](adr/0018-hierarchy-native-forms.md). d3-quadtree is ported as the
package `flutter_d3_quadtree_port`, in the native forms of
[D3 ADR 0019](adr/0019-quadtree-native-forms.md). d3-chord is ported as the
package `flutter_d3_chord_port`, in the native forms of
[D3 ADR 0023](adr/0023-chord-native-forms.md). d3-delaunay (bundling delaunator
and robust-predicates `orient2d`) is ported as the package
`flutter_d3_delaunay_port`, in the native forms of
[D3 ADR 0022](adr/0022-delaunay-native-forms.md). d3-time is ported as the package
`flutter_d3_time_port`, in the native forms of
[D3 ADR 0021](adr/0021-time-native-forms.md). d3-time-format is ported as the package
`flutter_d3_time_format_port`, in the native forms of
[D3 ADR 0025](adr/0025-time-format-native-forms.md). d3-random is ported as the package
`flutter_d3_random_port`, in the native forms of
[D3 ADR 0026](adr/0026-random-native-forms.md). d3-geo is ported as the package
`flutter_d3_geo_port`, in the native forms of
[D3 ADR 0024](adr/0024-geo-native-forms.md). The other rows have the status `not started`. Until
phase 2, this file has one row for each repository. A person writes it by hand. The status unit is one upstream source file
(D3 ADR 0001). Thus the status of a repository row applies to each of its source files.

From phase 2, tool 6 ([porting-flow.md](porting-flow.md) §4) writes this file from
`doc/status.yaml`, with one row for each upstream source file. Until then, each port change edits
this file in the same change as the code.

Status values ([porting-flow.md](porting-flow.md) §1 step 7, the values of the Chart.js port):

- `not started`: the module has no Dart code.
- `in progress`: Dart code exists for a part of the module.
- `partial: <symbols>`: the port has only the listed symbols, because a ported module needs them.
- `ported`: the Dart code and the ported tests pass. For a pure-layer module, the tests pass on the
  VM, with DDC and with dart2wasm (`test:web` runs Chrome with DDC and with dart2wasm). This is the last status of a module. The port has no
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
| [d3-array](https://github.com/d3/d3-array/tree/v3.2.4) | v3.2.4 | 61 | 1384 | 65 | 530 | 1: `ticks.js`, `nice.js` and `range.js` (3 files, 86 lines, 42 cases). 2: the other files | ported in the package `flutter_d3_array_port` ([D3 ADR 0017](adr/0017-array-native-forms.md)): 450 upstream cases pass and 81 skip (80 as `diverges: adapt-array-typed-api`, 1 upstream `it.skip`), on the VM, DDC and dart2wasm. |
| [d3-axis](https://github.com/d3/d3-axis/tree/v3.0.0) | v3.0.0 | 3 | 183 | 2 | 10 | 7 | not started |
| [d3-brush](https://github.com/d3/d3-brush/tree/v3.0.0) | v3.0.0 | 5 | 652 | 1 | 1 | 7 | not started |
| [d3-chord](https://github.com/d3/d3-chord/tree/v3.0.1) | v3.0.1 | 6 | 272 | 2 | 8 | 4 | ported in the package `flutter_d3_chord_port` ([D3 ADR 0023](adr/0023-chord-native-forms.md)): all 8 upstream cases pass (plus comprehensive unit, Node.js reference parity, faster-form twin, and `UiPathContext` tests), on the VM, DDC and dart2wasm. |
| [d3-color](https://github.com/d3/d3-color/tree/v3.1.0) | v3.1.0 | 6 | 595 | 8 | 170 | 2 | ported in the package `flutter_d3_color_port` ([D3 ADR 0008](adr/0008-module-packages.md)): 162 cases pass and 8 skip as `diverges: adapt-color-factories`, on the VM, DDC and dart2wasm. `src/define.js`: `n/a: Dart classes take the place of the prototype helper` |
| [d3-contour](https://github.com/d3/d3-contour/tree/v4.0.2) | v4.0.2 | 9 | 416 | 3 | 23 | 5 | ported in the package `flutter_d3_contour_port` ([D3 ADR 0020](adr/0020-contour-native-forms.md)): all 23 upstream cases pass (13 `contours`, 8 `density`, 2 `snapshot` geometry) on the VM, DDC and dart2wasm. |
| [d3-delaunay](https://github.com/d3/d3-delaunay/tree/v6.0.4) | v6.0.4 | 5 | 636 | 2 | 41 | 5 | ported in the package `flutter_d3_delaunay_port` ([D3 ADR 0022](adr/0022-delaunay-native-forms.md)): all 41 upstream cases pass (plus Node.js reference parity, faster-form twin, and `UiPathContext` tests), on the VM, DDC and dart2wasm. |
| [d3-dispatch](https://github.com/d3/d3-dispatch/tree/v3.0.1) | v3.0.1 | 2 | 85 | 1 | 36 | 2 | not started |
| [d3-drag](https://github.com/d3/d3-drag/tree/v3.0.0) | v3.0.0 | 6 | 266 | 1 | 1 | 7 | not started |
| [d3-dsv](https://github.com/d3/d3-dsv/tree/v3.0.1) | v3.0.1 | 5 | 209 | 4 | 136 | 3 | not started |
| [d3-ease](https://github.com/d3/d3-ease/tree/v3.0.1) | v3.0.1 | 12 | 273 | 10 | 77 | 2 | not started |
| [d3-fetch](https://github.com/d3/d3-fetch/tree/v3.0.1) | v3.0.1 | 8 | 83 | 1 | 1 | 7 | not started |
| [d3-force](https://github.com/d3/d3-force/tree/v3.0.0) | v3.0.0 | 12 | 693 | 5 | 16 | 6 | not started |
| [d3-format](https://github.com/d3/d3-format/tree/v3.1.2) | v3.1.2 | 16 | 344 | 24 | 168 | 1 | ported in the package `flutter_d3_format_port` ([D3 ADR 0016](adr/0016-format-native-forms.md)): 167 upstream cases pass and 1 skips as `diverges: adapt-format-typed-api`, on the VM, DDC and dart2wasm, plus all 59 upstream locales as `const` Dart objects. |
| [d3-geo](https://github.com/d3/d3-geo/tree/v3.1.1) | v3.1.1 | 58 | 3280 | 32 | 343 | 5 | ported in the package `flutter_d3_geo_port` ([D3 ADR 0024](adr/0024-geo-native-forms.md)): all 58 `src/` files and 32 upstream test files ported (415 tests pass, 7 skip as `diverges: adapt-geo-typed-api`, plus Node.js reference parity, faster-form twin, and `UiPathContext` rendering tests), on the VM, DDC and dart2wasm. |
| [d3-hierarchy](https://github.com/d3/d3-hierarchy/tree/v3.1.2) | v3.1.2 | 34 | 1414 | 18 | 83 | 2 | ported in the package `flutter_d3_hierarchy_port` ([D3 ADR 0018](adr/0018-hierarchy-native-forms.md)): 77 upstream cases pass and 6 skip as `diverges: adapt-hierarchy-typed-api`, on the VM, DDC and dart2wasm. |
| [d3-interpolate](https://github.com/d3/d3-interpolate/tree/v3.0.1) | v3.0.1 | 26 | 595 | 22 | 149 | 2: the other files. 6: `zoom.js` (1 file, 71 lines, 5 cases). 7: `transform/` (3 files, 107 lines, 0 cases) | ported in the package `flutter_d3_interpolate_port` ([D3 ADR 0011](adr/0011-interpolate-native-forms.md)), ahead of phases 2, 6 and 7: 114 cases pass and 35 skip, 34 as `diverges: adapt-interpolate-typed-values` and 1 as `diverges: adapt-interpolate-date-value`, on the VM, DDC and dart2wasm. `src/object.js` and `src/string.js`: `n/a: interpolate takes typed values only`. `src/transform/parse.js`: `n/a: no transform text; the Flutter layer reads a Matrix4` |
| [d3-path](https://github.com/d3/d3-path/tree/v3.1.0) | v3.1.0 | 2 | 157 | 2 | 64 | 1 | ported in the package `flutter_d3_path_port` ([D3 ADR 0014](adr/0014-path-native-forms.md)): 61 cases pass and 3 skip as `diverges: adapt-path-typed-args`, on the VM, DDC and dart2wasm, plus native Flutter `UiPathContext`. |
| [d3-polygon](https://github.com/d3/d3-polygon/tree/v3.0.1) | v3.0.1 | 7 | 135 | 5 | 23 | 2 | not started |
| [d3-quadtree](https://github.com/d3/d3-quadtree/tree/v3.0.1) | v3.0.1 | 15 | 413 | 13 | 62 | 2 | ported in the package `flutter_d3_quadtree_port` ([D3 ADR 0019](adr/0019-quadtree-native-forms.md)): all 62 upstream cases pass (plus 21 port, Node.js reference parity, and faster-form twin tests), on the VM, DDC and dart2wasm. |
| [d3-random](https://github.com/d3/d3-random/tree/v3.0.1) | v3.0.1 | 20 | 370 | 18 | 67 | 2 | ported in the package `flutter_d3_random_port` ([D3 ADR 0026](adr/0026-random-native-forms.md)): all 67 upstream cases pass (plus Node.js bit-exact LCG & seeded draw reference parity and faster-form twin tests), on the VM, DDC and dart2wasm. |
| [d3-scale](https://github.com/d3/d3-scale/tree/v4.0.2) | v4.0.2 | 24 | 1302 | 19 | 433 | 3 | not started |
| [d3-scale-chromatic](https://github.com/d3/d3-scale-chromatic/tree/v3.1.0) | v3.1.0 | 48 | 557 | 1 | 1 | 2 | ported in the package `flutter_d3_scale_chromatic_port` ([D3 ADR 0012](adr/0012-scale-chromatic-native-forms.md)), ahead of phase 2: all 76 schemes and interpolators pass on the VM, DDC and dart2wasm. `src/rampClosed.js`: `n/a: unused upstream file; no file of d3-scale-chromatic imports it` |
| [d3-selection](https://github.com/d3/d3-selection/tree/v3.0.0) | v3.0.0 | 54 | 1057 | 42 | 236 | 7 | not started |
| [d3-shape](https://github.com/d3/d3-shape/tree/v3.2.0) | v3.2.0 | 60 | 2193 | 41 | 268 | 4 | ported in the package `flutter_d3_shape_port` ([D3 ADR 0015](adr/0015-shape-native-forms.md)): 231 upstream cases pass and 37 skip as `diverges: adapt-shape-typed-api`, on the VM, DDC and dart2wasm, plus direct Flutter `Canvas` rendering via `UiPathContext`. |
| [d3-time](https://github.com/d3/d3-time/tree/v3.1.0) | v3.1.0 | 12 | 488 | 36 | 465 | 3 | ported in the package `flutter_d3_time_port` ([D3 ADR 0021](adr/0021-time-native-forms.md)): 453 upstream cases pass and 12 skip as `diverges: adapt-time-typed-api` (plus all 32 POSIX IANA timezone checks in `test/test_time_zones_test.dart`, Node.js reference parity, and faster-form twin tests), on the VM, DDC and dart2wasm. |
| [d3-time-format](https://github.com/d3/d3-time-format/tree/v4.1.0) | v4.1.0 | 5 | 754 | 8 | 146 | 3 | ported in the package `flutter_d3_time_format_port` ([D3 ADR 0025](adr/0025-time-format-native-forms.md)): 142 upstream cases pass and 4 skip as `diverges: adapt-time-format-typed-api` (plus all 34 upstream locales as `const` Dart objects, POSIX IANA TZ checks, Node.js reference parity, and faster-form twin tests), on the VM, DDC and dart2wasm. |
| [d3-timer](https://github.com/d3/d3-timer/tree/v3.0.1) | v3.0.1 | 4 | 151 | 5 | 42 | 6 | not started |
| [d3-transition](https://github.com/d3/d3-transition/tree/v3.0.1) | v3.0.1 | 29 | 953 | 33 | 180 | 7 | not started |
| [d3-zoom](https://github.com/d3/d3-zoom/tree/v3.0.0) | v3.0.0 | 6 | 523 | 4 | 25 | 6: `transform.js` (1 file, 51 lines, 10 cases). 7: the other files | not started |
| [delaunator](https://github.com/mapbox/delaunator/tree/v5.1.0) | v5.1.0 | 1 | 607 | 1 | 14 | 5 | ported in the package `flutter_d3_delaunay_port` ([D3 ADR 0022](adr/0022-delaunay-native-forms.md)): all 14 upstream cases (including all 8 JSON fixtures) pass on the VM. |
| [internmap](https://github.com/mbostock/internmap/tree/v2.0.3) | v2.0.3 | 1 | 61 | 2 | 8 | 2 | not started |
| [robust-predicates](https://github.com/mourner/robust-predicates/tree/v3.0.3) | v3.0.3 | 5 | 1085 | 1 | 8 | 5: `orient2d.js` and `util.js` (2 files, 183 lines). The other three files are `n/a` ([Notes](#notes)) | ported in the package `flutter_d3_delaunay_port` ([D3 ADR 0022](adr/0022-delaunay-native-forms.md)): `src/orient2d.js` and `src/util.js` ported (2 `orient2d`/`orient2dfast` cases including 128×128 grid and 1,000 hard fixtures pass on the VM); `src/incircle.js`, `src/insphere.js` and `src/orient3d.js` are `n/a: unused by d3-delaunay and delaunator` (6 upstream cases skip). |
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
