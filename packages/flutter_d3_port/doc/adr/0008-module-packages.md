# D3 ADR 0008: One package for each D3 module

- Status: proposed
- Date: 2026-11-15
- Supersedes: [D3 ADR 0002](0002-file-naming-and-layout.md) §1 (the paths of a module) and §6 (the module indexes and the public libraries)
- Related: [ADR 0007](../../../../docs/adr/0007-package-names.md), [D3 ADR 0007](0007-native-dart-forms.md), [ADR 0005](../../../../docs/adr/0005-pin-upstream-sources.md)

## Context

On npm, each D3 module is a package of its own, for example
[`d3-color`](https://www.npmjs.com/package/d3-color). The package `d3` depends on the 30 module
packages and re-exports them. D3 ADR 0002 put all modules into `flutter_d3_port` and rejected one
package for each repository. On 2026-11-15 the maintainer asked for the npm layout, starting with
d3-color. The precedent is `flutter_kurkle_color_port`, the color package of the Chart.js port.

## Decision

1. Each ported D3 module repository is a package `packages/flutter_<repo>_port`, with each `-` of
   the repository name as `_`: `flutter_d3_color_port` for d3-color. The name follows ADR 0007,
   and pub.dev must give 404 for it first.
2. In a module package, `src/<path>.js` becomes `lib/src/<path>.dart`, and
   `test/<path>-test.js` becomes `test/<path>_test.dart`. A test helper `test/<path>.js` becomes
   `test/<path>.dart`. Port-only tests go in `test/port/`. The file name rules of D3 ADR 0002 §2
   and the identifier rules of §3 to §5 apply.
3. A module package has `lib/<module>.dart` (for d3-color, `d3_color.dart`), the pure library
   with no Flutter import: `lib/src/index.dart` and the version constant. Its main library
   `lib/flutter_<repo>_port.dart` adds the Flutter layer, if the module has one.
4. A module package has its own `tool/port_sources.yaml` with the one pin of its repository, the
   top-level key `marker: <repo>` (`DIVERGES(d3-color)`), `doc/differences.md` and
   `doc/performance.md`. `lib/src/upstream.dart` has the version constant, for example
   `d3ColorVersion`. The D3 ADRs of `packages/flutter_d3_port/doc/adr/` apply to each module
   package.
5. A module package depends on the module packages that its upstream `package.json` names, and on
   no other port.
6. `flutter_d3_port` is the bundle. It depends on each module package, and
   `lib/src/d3/index.dart` exports the pure library of each one, as `d3/src/index.js` re-exports
   each module. `package:flutter_d3_port/d3.dart` is the pure bundle library.
7. `doc/parity.md` of `flutter_d3_port` keeps one row for each repository and names the package
   of a ported module.

## Rejected

- One package for all modules (D3 ADR 0002): an app pays for 30 modules to use one, and the
  layout differs from npm.
- A module package that re-exports the Flutter layer of another module: the bundle does that.

## Consequences

- An app can depend on `flutter_d3_color_port` alone.
- Each new module adds a workspace entry, a commit scope, a `REUSE.toml` table and its pin to
  the pin check.
- Tool 2 runs once for each module package, as its own home package.

## Tests

- `packages/flutter_d3_color_port/test/upstream_test.dart`
- `packages/flutter_d3_port/test/upstream_test.dart`
