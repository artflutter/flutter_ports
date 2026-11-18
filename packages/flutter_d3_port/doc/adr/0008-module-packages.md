# D3 ADR 0008: One package for each D3 module

- Status: accepted (2026-11-15): its code and the tests of section Tests pass.
- Superseded in part by: [ADR 0011](../../../../docs/adr/0011-public-library-exports-every-file.md): the export forms of §6 (2026-11-18)
- Date: 2026-11-15
- Supersedes: [D3 ADR 0002](0002-file-naming-and-layout.md) §1 (the paths) and §6 (the module indexes and the public libraries)
- Related: [ADR 0007](../../../../docs/adr/0007-package-names.md), [D3 ADR 0007](0007-native-dart-forms.md), [ADR 0005](../../../../docs/adr/0005-pin-upstream-sources.md)

## Context

On npm, each D3 module is a package of its own, for example `d3-color`. The package `d3` depends
on the 30 module packages and re-exports them. D3 ADR 0002 (proposed) puts all modules into
`flutter_d3_port`. On 2026-11-15 the maintainer asked for the npm layout, starting with d3-color.
The precedent is `flutter_kurkle_color_port`, the color package of the Chart.js port. This ADR
keeps the section numbers of D3 ADR 0002.

## Decision

### 1. Paths

- `packages/flutter_<repo>_port`: each ported D3 repository is a package, with each `-` of the
  repository name as `_`, for example `flutter_d3_color_port`. Before the package exists,
  `https://pub.dev/api/packages/<name>` must give 404.
- `lib/src/<path>.dart` of the module package: the port of `<repo>/src/<path>.js`. The file name
  keeps the upstream spelling and case, also a `%`.
- `test/<path>_test.dart`: the port of `<repo>/test/<path>-test.js`.
- `test/<path>.dart`: the port of a helper `<repo>/test/<path>.js` that a test file imports.
- `test/snapshot_test.dart`, `test/test_test.dart` and `test/test-time-zones_test.dart`: the
  ports of the four test entries with no `-test.js` suffix, `d3-contour/test/snapshot.js`,
  `delaunator/test/test.js`, `robust-predicates/test/test.js` and
  `d3-time/test/test-time-zones`.
- `test/port/<path>_test.dart`: a port-only test. `test/support/`: port-only test support.
- `lib/src/<topic>/`: port-only library code, where `<topic>` is no folder of `src/`, for
  example `lib/src/ui/`.
- `lib/src/d3/index.dart` of `flutter_d3_port`: the port of `d3/src/index.js`, the bundle index.
- `n/a`: the six helpers that no test file imports. These are d3-geo `test/compute-scale.js`,
  d3-hierarchy `test/pack/bench-enclose.js`, `test/pack/find-bugs.js`,
  `test/pack/find-enclose-bugs.js` and `test/pack/find-place-bugs.js`, and d3-quadtree
  `test/benchmark.js`.
- The data files stay in the submodules. No package copies them.

### 6. Module indexes and public libraries

- `lib/src/index.dart` of a module package: the port of `src/index.js`. Its lines translate the
  export lines:
  - `export 'package:<package>/src/f.dart' show a, b;` translates `export {a, b} from "./f.js";`
    and `export {default as a} from "./f.js";`.
  - `const y = f.x;` translates a renamed function `x as y`, with `f.dart` imported with a prefix.
  - A getter translates a renamed variable, for example
    `List<Object?> get schemeBrBG => brbg.scheme;`.
  - A `typedef` translates a renamed class, for example `typedef ZoomTransform = transform.Transform;`.
  - A second declaration of the same kind translates a second public name of one binding, for
    example `const radialArea = areaRadial;`.
- These declarations need no `DIVERGES` marker. An index exports only the names of its ported
  files.
- `import 'package:flutter_<repo>_port/<module>.dart'` translates an import of another D3
  repository by its package name. A relative import becomes a package import of the mapped file.
- `lib/<module>.dart`, for example `d3_color.dart`: the pure library of a module package. It
  exports `lib/src/index.dart` and the version constant, and it imports no Flutter library.
- `lib/flutter_<repo>_port.dart`: the main library of a module package. It exports the pure
  library and the Flutter layer of the module, port-only extensions in `lib/src/ui/`, for example
  `toUiColor()`.
- `export 'package:flutter_d3_color_port/d3_color.dart' hide d3ColorVersion;`: the bundle index
  exports the pure library of each module package.
- `package:flutter_d3_port/d3.dart` is the pure bundle library, and
  `package:flutter_d3_port/flutter_d3_port.dart` adds the Flutter layer of each module.

### 8. Package files

- `tool/port_sources.yaml` of a module package has the one pin of its repository and the
  top-level key `marker: <repo>`, the tag of `// DIVERGES(<repo>): <row id>, <reason>`.
- `// Original code, not ported from <repo>: <reason>.` is the port-only marker of a module
  package.
- `lib/src/upstream.dart` has the version constant of the repository, for example
  `d3ColorVersion`.
- `doc/differences.md` and `doc/performance.md` of a module package have its rows and its
  figures.
- A module package depends on Flutter and on the module packages that its upstream
  `package.json` names, and on no other port.
- `flutter_d3_port` depends on each module package. Its `doc/parity.md` keeps one row for each
  repository and names the package of a ported module.

## Rejected

- One package for all modules: an app pays for 30 modules to use one, and the layout differs from
  npm.
- A module package that re-exports the Flutter layer of another module: the bundle does that.

## Consequences

- An app can depend on `flutter_d3_color_port` alone.
- Each new module adds a workspace entry, a commit scope, a `REUSE.toml` table and its pin to the
  pin check.
- Tool 2 runs once for each module package, as its own home package.

## Tests

- `packages/flutter_d3_color_port/test/upstream_test.dart`
- `packages/flutter_d3_port/test/upstream_test.dart`
- `packages/flutter_d3_port/test/port/d3/index_test.dart`
