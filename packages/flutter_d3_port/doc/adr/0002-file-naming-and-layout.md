# D3 ADR 0002: File naming and package layout

- Status: proposed
- Date: 2026-10-20
- Gate: D3 phase 1. The first ported file of the pilot needs a Dart path.
- Related: [Chart.js ADR 0012](../../../flutter_chartjs/doc/adr/0012-dart-file-naming.md) (the
  precedent: upstream spelling and underscore names),
  [Chart.js ADR 0023](../../../flutter_chartjs/doc/adr/0023-underscore-member-collisions.md)
  (proposed: underscore members whose names collide),
  [ADR 0007](../../../../docs/adr/0007-package-names.md) (the package name),
  [ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) (tool 2 for both
  ports), [D3 ADR 0001](0001-upstream-sources.md) (the pins, the headers and the holders),
  [D3 ADR 0004](0004-spec-harness.md) (the spec form), [D3 ADR 0005](0005-path-context.md) (the
  port-only canvas files), [D3 ADR 0006](0006-generators-accessors-and-js-values.md) (the
  accessors), [porting-flow.md](../porting-flow.md) §1 and §4, [parity.md](../parity.md)

## Context

The port translates D3 file by file (AGENTS.md rules 1 and 2). Tool 2, the bump review and the
header restamp map an upstream path to a Dart path. A mechanical map keeps these tools simple.

[Chart.js ADR 0012](../../../flutter_chartjs/doc/adr/0012-dart-file-naming.md) gives that map for
the Chart.js port. It keeps the upstream file names with their dots and their case. A Chart.js ADR
binds only the Chart.js port. Thus this ADR states the complete D3 rule.

D3 differs from Chart.js in these facts. The counts are at the pins of
[D3 ADR 0001](0001-upstream-sources.md). The Evidence section of this ADR gives the method.

- **Repositories.** The `d3` repository holds only the bundle index `src/index.js`. Its 30 lines
  re-export the 30 module repositories, for example `export * from "d3-array";`. The modules also
  import `internmap`, `delaunator` and `robust-predicates`.
- **Directory names.** The repository names have hyphens, for example `d3-scale-chromatic`. Some
  folders of `src/` have hyphens too, for example `d3-scale-chromatic/src/sequential-multi/`. No
  lint examines directory names.
- **Source files.** The pins have 568 source files. These are the 566 `src/**/*.js` files of the
  30 modules, internmap and robust-predicates, the `index.js` of delaunator at its repository root
  and `d3/src/index.js`.
- **The `file_names` lint.** The lint fails for 107 source names, for example `formatDecimal`,
  `areaRadial` and `BrBG`. In Chart.js, 1 of 90 source names failed.
- **Test files.** The pins have 431 `*-test.js` files. As `<name>_test.dart`, 106 of them fail the
  lint. 89 of these names have a capital letter. 17 have a hyphen. One of the 17 also has a `%`:
  `d3-format/test/format-type-%-test.js`.
- **Other test entries.** Three test files that the upstream scripts run do not end in
  `-test.js`: `d3-contour/test/snapshot.js`, `delaunator/test/test.js` and
  `robust-predicates/test/test.js`. `d3-time/test/test-time-zones` is a shell script with 32
  active checks. The upstream test script does not run it.
- **Helpers.** `test/` has 41 more `.js` files outside the data folders. Test files import 35 of
  them, for example `test/asserts.js`. No test file imports the other 6. The lint fails for 4 of
  the 35 names and for 5 of the 6 names.
- **Exports.** The `export {...} from` lines of the 30 module indexes give 577 public names. No
  name occurs in two modules. The lines have 320 `default as` specifiers. They have 123 renamed
  named specifiers, for example `scheme as schemeBrBG`, `yesdrag as dragEnable` and
  `Transform as ZoomTransform`. 22 bindings have two public names. Examples are `bin` and
  `histogram`, `areaRadial` and `radialArea`, and `easeQuad` and `easeQuadInOut`. 27 files export
  the same local name `scheme`. Dart has no renamed export.
- **Default exports.** 480 source files have an `export default`. 144 of them get no name from an
  index or from a declaration, for example `export default function(x)`. Their importers name
  them. One such file has two names: d3-geo `src/path/bounds.js` is `pathBounds` in
  `src/path/index.js:4` and `boundsStream` in `src/projection/fit.js:2`.
- **Underscore names.** No export name of the pins starts with `_`. Many member names start with
  `_`, for example `this._root` and `this._x` of d3-quadtree. In Dart, a `_` at the start of a
  name makes the name private to its library.
- **Split classes.** Four classes get most of their methods from other files:
  - `d3-quadtree src/quadtree.js:1-12` imports 12 method files.
  - `d3-hierarchy src/hierarchy/index.js` imports 13.
  - `d3-selection src/selection/index.js` imports 34.
  - `d3-transition src/transition/index.js` imports 20.
  - A method file reads the `_` fields of its class, for example `this._x` and `tree._root`
    (`d3-quadtree src/add.js:2`, `:11`).
- **The bundle test.** `d3/test/d3-test.js:10-19` makes one case for each dependency of
  `package.json`, thus 30 cases. Each case asserts that the bundle exports each name of the
  module. Dart cannot list the exports of a library at run time.

The probe P3 of the research of 2026-10-20 built a package with such Dart names (Dart 3.12.2):
- Hyphenated directories analyze, resolve as `package:` URIs, run on the VM and compile with
  dart2js.
- `file_names` gives an info for `formatDecimal.dart` and `BuGn.dart`. The line
  `// ignore_for_file: file_names` removes the info.
- `test/d3-format/format-type-%_test.dart` ran under `dart test` on the VM and with dart2js. No
  probe ran such a name under `flutter test`, on Windows or with dart2wasm.

## Decision

### 1. Paths

Dart paths are relative to `packages/flutter_d3_port`. `<repo>` is the repository name with its
hyphens.

| Upstream | Dart |
|---|---|
| `<repo>/src/<path>.js` | `lib/src/<repo>/<path>.dart` |
| `delaunator/index.js` | `lib/src/delaunator/index.dart` |
| `d3/src/index.js` | `lib/src/d3/index.dart` (the bundle index) |
| `<repo>/test/<path>-test.js` | `test/specs/<repo>/<path>_test.dart` |
| A test entry without the `-test.js` suffix: `d3-contour/test/snapshot.js`, `delaunator/test/test.js`, `robust-predicates/test/test.js`, `d3-time/test/test-time-zones` | `test/specs/<repo>/<name>_test.dart`: `snapshot_test.dart`, `test_test.dart`, `test_test.dart`, `test-time-zones_test.dart` |
| A helper `<repo>/test/<path>.js` that a test file imports | `test/specs/<repo>/<path>.dart` |
| Port-only tests of `lib/src/<repo>/<path>.dart` | `test/port/<repo>/<path>_test.dart` |
| Port-only library code | `lib/src/<topic>/`, where `<topic>` is not a repository name, for example `lib/src/canvas/` ([D3 ADR 0005](0005-path-context.md)) |
| Port-only test support | `test/support/` ([D3 ADR 0004](0004-spec-harness.md)) |

- The map from a pinned file to its Dart file is one prefix substitution:
  `third_party/<repo>/src/` becomes `lib/src/<repo>/`. Bump diffs, headers and Dart paths name the
  same folders.
- File names keep the upstream spelling and case, for example
  `lib/src/d3-format/formatDecimal.dart` and `lib/src/d3-scale-chromatic/diverging/BrBG.dart`.
- The `%` of `format-type-%-test.js` stays. Phase 1 probes this name under `flutter test`, on
  Windows and with dart2wasm. If the probe fails, a new D3 ADR gives the character a replacement.
- No two Dart paths of the pins are equal, also with the case ignored.
- robust-predicates has no `src/index.js`. Its root `index.js` re-exports `esm/`, a build output
  that is not in git ([D3 ADR 0001](0001-upstream-sources.md) item 17). Thus a Dart import of the
  package `robust-predicates` imports `lib/src/robust-predicates/orient2d.dart`.
- The port does not port a helper that no test file imports. These 6 files get the status `n/a`:
  d3-geo `test/compute-scale.js` (a command-line script), d3-hierarchy `test/pack/bench-enclose.js`,
  `test/pack/find-bugs.js`, `test/pack/find-enclose-bugs.js` and `test/pack/find-place-bugs.js`,
  and d3-quadtree `test/benchmark.js`.
- Data files stay in the submodules ([D3 ADR 0001](0001-upstream-sources.md) item 14,
  [D3 ADR 0004](0004-spec-harness.md) section 6). The gate 2 decision "Locale data" gives the Dart
  form of the locale files ([porting-flow.md](../porting-flow.md) §2.10).
- Each test of `test/specs/` and `test/port/` has the header of AGENTS.md rule 2. A port-only file
  starts with `// Original code, not ported from D3: <reason>.` A file under `test/port/` or
  `test/support/` is port-only.

### 2. The `file_names` lint

A Dart file whose name fails `file_names` carries `// ignore_for_file: file_names` directly after
its header lines. The rule applies to library files and to test files. In a test file with
`@TestOn('vm')`, the annotation comes after the ignore line.

At the pins, the rule applies to 218 Dart files:
- 107 source files
- 106 spec files
- 4 helpers: d3-array `OneTimeNumber.dart`, d3-geo `path/test-context.dart`, d3-scale
  `roundEpsilon.dart` and d3-shape `polygonContext.dart`
- `test/specs/d3-time/test-time-zones_test.dart`

Tool 2 applies the test of the lint to each Dart file name. It fails when a file whose name fails
the lint has no ignore line after its header lines. It also fails when a file whose name passes
has the line.

### 3. Identifiers

- Identifiers are Dart-cased, as in Chart.js ADR 0012. Constants use lowerCamelCase. The port
  removes an inner underscore. For example, `tree_add` becomes `treeAdd`. Classes keep their
  UpperCamelCase names.
- A default export takes its Dart name from the first source of this list:
  1. Its public name in the `src/index.js` of its repository. For example,
     `d3-shape/src/curve/basis.js` declares `curveBasis`.
  2. The name of its declaration. For example, `export default function sort` gives `sort`
     (`d3-array src/sort.js:4`).
  3. The name that its importers give it. If two importers give two names, the importer whose path
     sorts first gives the name. At the pins, this occurs only for d3-geo `src/path/bounds.js`.
     Its Dart name is `pathBounds`. `src/projection/fit.dart` imports the file with a prefix.
- A name that clashes with a Dart or Flutter name stays, for example `Path`, `Node`, `Timer` and
  `Transform`. A ported file imports `dart:async`, `dart:ui` and the Flutter libraries with a
  prefix where a name clashes. It imports `dart:math` as `math`.

### 4. Underscore members

These rules adapt Chart.js ADR 0012 and Chart.js ADR 0023 (proposed):
- A `_`-prefixed member that another Dart library reads drops the underscore. It carries
  `@internal` from `package:meta`.
- If the class has a member with the name without the underscore, the Dart name gets the
  underscore at its end instead. For example, d3-quadtree has the field `_x` and the accessor `x`
  (`src/x.js`). The field becomes `x_`.
- A `_` member that only its own file reads keeps its name.
- The `///` line of the member keeps the upstream name.

### 5. Split classes

A class whose methods come from other files keeps one Dart file for each upstream file:
- The file that declares the class keeps the class, its constructor and the methods that it
  declares inline. An example is `treeProto.copy` (`d3-quadtree src/quadtree.js:37-58`).
- Each method file declares an extension on the class with its methods. The name of the extension
  is the UpperCamelCase form of the import name in the class file. For example, `tree_add` gives
  `extension TreeAdd on Quadtree` in `lib/src/d3-quadtree/add.dart`.
- The class file exports each extension. This export translates the prototype line, for example
  `treeProto.add = tree_add;`. The class file also imports the method files that its own code
  calls. Dart allows these import cycles.
- The fields that the method files read follow section 4.

Extension methods resolve statically. No subclass can override them. Phase 2 ports d3-quadtree
and d3-hierarchy with this form first. If the form fails there, a new D3 ADR gives another form.
The DOM layer decision (gate 7) gives the form of `Selection` and `Transition`, because
`Transition` reuses methods of `Selection` ([porting-flow.md](../porting-flow.md) §2.15 and
§2.16).

### 6. Module indexes and the public libraries

Each `src/index.js` of a module maps to `lib/src/<repo>/index.dart`. Its lines translate the
export lines:

| Upstream | Dart |
|---|---|
| `export {a, b} from "./f.js";` | `export 'package:flutter_d3_port/src/<repo>/f.dart' show a, b;` |
| `export {default as a} from "./f.js";` | `export '.../f.dart' show a;`. The default export has the name `a` by section 3 |
| A renamed specifier `x as y` of a function | The index imports `f.dart` with a prefix and declares `const y = f.x;` |
| A renamed specifier of a variable or a value | A getter, for example `List<Object?> get schemeBrBG => brbg.scheme;`. A getter keeps the live binding of an ES module |
| A renamed specifier of a class | A `typedef`, for example `typedef ZoomTransform = transform.Transform;` |
| A second public name of one binding | A second declaration of the same kind, for example `const radialArea = areaRadial;` |

- These declarations translate the `export ... as` lines. They need no `DIVERGES` marker.
- An index exports only the names of its ported files. A `show` list keeps the internal names of a
  file out of the index.
- An import of another repository by its package name goes to the `index.dart` of that repository.
  An example is `import {Path} from "d3-path";` (`d3-shape src/path.js:1`). A relative import goes
  to the mapped Dart file. All imports in `lib/` are package imports, as the lint
  `always_use_package_imports` asks.
- `lib/src/d3/index.dart` exports the index of each module that has a ported file, for example
  `export 'package:flutter_d3_port/src/d3-array/index.dart';`.
- Public libraries:
  - `package:flutter_d3_port/d3.dart` exports `lib/src/d3/index.dart`. It is a pure layer. Phase 1
    adds it with the first ported module.
  - `package:flutter_d3_port/flutter_d3_port.dart` is the library of phase 0. Later phases add the
    Flutter layer to it ([D3 ADR 0005](0005-path-context.md)).
  - The docs tell users to write `import 'package:flutter_d3_port/d3.dart' as d3;`. Then the code
    reads `d3.max(values)` and `d3.scaleLinear()`, as in JavaScript. The names `max`, `min` and
    `sum` do not clash with `dart:math`.

### 7. The bundle index check

A check of `check:port` ([porting-flow.md](../porting-flow.md) §4) compares the exported names. It
resolves the libraries with `package:analyzer`. It has two parts:
1. Each module `index.dart` exports the public names of the pinned `src/index.js` whose files are
   ported. It exports no other name. This part reads the submodules.
2. `lib/src/d3/index.dart` exports each name of each module `index.dart`. This part reads only
   the package.

The spec `test/specs/d3/d3_test.dart` keeps the 30 cases of `d3/test/d3-test.js`. Each case skips
as `'n/a: check:port compares the exports (D3 ADR 0002)'`. The case of `d3/test/docs-test.js`
skips as `'n/a: the port has no docs site'`.

## Alternatives considered

- **Dart-style directories** (`lib/src/d3_array/`) or no prefix (`lib/src/array/`). Rejected. The
  map from a pinned file is then no longer one prefix substitution. The bump diffs name other
  folders. Effective Dart asks for lowercase directory names. No lint examines them.
- **A snake_case map of the file names** (`formatDecimal.js` to `format_decimal.dart`, `BrBG.js` to
  `br_bg.dart`). Rejected. The side-by-side review of a bump gets harder for 218 files. The map
  also needs a rule for each case pattern. A reader cannot always invert it.
- **`file_names` off for the whole package** (a package `analysis_options.yaml`). Rejected.
  Port-only files then also escape the lint. The ignore line marks exactly the files whose upstream name
  fails.
- **A snake_case map for test names only.** Rejected. The source files and the test files then
  need two different name rules in tool 2 and tool 5.
- **`test/<repo>/<name>_test.dart`** (the research proposal). Rejected. The Chart.js port keeps
  ported specs in `test/specs/` and port-only tests in `test/port/`. Tool 5 reads `test/specs/`.
- **One package for each repository** (the d4 approach). Rejected. The release work grows with
  the module count. The prior-art survey found constraint conflicts in the d4 umbrella package
  ([prior art](../prior-art/README.md)).
- **One package for the pure modules and one for the Flutter layer.** Not chosen. The maintainer
  named one package ([ADR 0007](../../../../docs/adr/0007-package-names.md)). Tool 1 keeps the pure
  layers apart inside the package.
- **The 30 cases of `d3-test.js` as a VM test with `package:analyzer`.** Rejected. Each test run
  then resolves the whole package. The check of section 7 gives the same result in `check:port`.
- **`part` files for the split classes.** Not chosen. A part file shares the privacy of its
  library. Thus the `_` fields keep their names. A part file cannot add members to a class
  either. Thus the method files still need extensions.

  The class library then holds the imports of 12 to 34 method files. Tool 1 then sees one library
  for each split class. Each other ported file is a library, as in the Chart.js port.

## Consequences

- The map from an upstream path to a Dart path is mechanical. Tool 2 compares each Dart path with
  the mapped path. Its D3 config gives the `test/specs/<repo>/` and `test/port/<repo>/` rules of
  section 1 ([ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md)).
- 218 Dart files carry the ignore line. A change of `file_names` to the whole name needs a new ADR
  that supersedes this ADR. A lint on directory names needs one too
  ([porting-flow.md](../porting-flow.md) §7, risk 6).
- Section 4 needs `meta` as a dependency of `flutter_d3_port`. The first change that adds
  `@internal` adds it. If the root `pubspec.lock` changes, that change follows the deferred-plan
  rule ([porting-flow.md](../porting-flow.md) §6).
- The module indexes and the bundle index grow with each ported file. The bundle index check of
  section 7 keeps them complete.
- An `@internal` member is not part of the public API. Code outside the package that reads such a
  member gets the analyzer warning `invalid_use_of_internal_member`. That code also needs a
  `package:flutter_d3_port/src/` import. The lint `implementation_imports` flags that import.
- Phase 1 probes the `%` name (section 1). Phase 2 probes the split-class form (section 5).

## Evidence

The counts come from scripts of the research of 2026-10-20. The scripts read shallow clones at the
pins of D3 ADR 0001, with delaunator at v5.1.0 and robust-predicates at v3.0.3. They ran no
upstream code.
- **File names.** A probe package had an empty Dart file at the mapped path of each source file,
  spec file, test entry and helper. `dart analyze` with the `file_names` rule (Dart 3.12.2) gave
  222 infos. These are 107 source files, 106 spec files and 9 helpers. 5 of the 9 helpers are
  among the 6 files that the port does not port. No two Dart paths are equal with the case
  ignored.
- **Exports.** A scan read the `export {...} from` lines of the 30 module indexes. It counted the
  specifiers, the renamed specifiers, the bindings with two names and the public names. The index
  of internmap has no such line. `d3/src/index.js` has 30 `export * from` lines.
- **Default exports.** A scan read the `export default` lines and the default imports of each
  source file. It found 144 files with no index name and no declaration name. One of them has two
  import names.
- **Split classes.** A count of the default imports of the four class files.
- **The split form.** A probe package used very_good_analysis 10.3.0. It had a class file in
  `lib/src/d3-quadtree/` and a method file with an extension. It also had the export of the
  extension and the import cycle of section 5. `dart analyze --fatal-infos` gave no issue.
- **Test files.** [parity.md](../parity.md) has the count script of the test files and the cases.
  It counts 434 test files with the three entries.
