# Chart.js ADR 0004: Dart file naming

- Status: accepted (2026-10-18)
- Date: 2026-10-17

## Context

AGENTS.md rule 2 asks for the upstream module split and names, "Dart-cased". The rule does not say
whether "Dart-cased" applies to file names. [porting-flow.md](../porting-flow.md) §2.5 proposed
this decision. Its gate is phase 1, because the first ported file needs a path.

- Upstream file names have dots and camelCase, for example `controller.polarArea.js`,
  `core.datasetController.js` and `plugin.filler/simpleArc.js`.
- The `file_names` lint asks for lower_case_with_underscores names. very_good_analysis 10.3.0
  enables it (`analysis_options.10.3.0.yaml:87`).
- Tool 2, the bump report and the header restamp map upstream paths to Dart paths. A mechanical
  mapping keeps these tools simple.
- Upstream marks internal exports with a leading underscore, for example `_angleDiff`
  (`helpers.math.ts:152`). In Dart, a leading underscore makes a name private to its library.
  Another library cannot import that name.

Probes on Dart 3.12.2 (2026-10-17) gave these results for the `file_names` lint:
- `controller.polarArea.dart` and `controller.POLAR_Area.dart` pass. The lint examines only the
  text before the first dot.
- `simpleArc.dart` and `BadName.dart` fail.
- `// ignore_for_file: file_names` below the header line removes the info.

Of the 90 upstream `src` files, only `src/plugins/plugin.filler/simpleArc.js` gives a Dart name
that fails the lint. All 54 spec files give names that pass. No two upstream files map to the same
Dart path.

## Decision

**Paths.** The Dart path follows from the upstream path. Dart paths are relative to
`packages/flutter_chartjs`.

| Upstream | Dart |
|---|---|
| `src/<path>.js`, `src/<path>.ts` | `lib/src/<path>.dart` |
| `src/types/<name>.d.ts` | `lib/src/types/<name>.dart` |
| `test/specs/<base>.tests.js` | `test/specs/<base>_test.dart` |
| `test/index.js` | `test/flutter_test_config.dart` |
| port-only tests of `lib/src/<path>.dart` | `test/port/<path>_test.dart` |

File and directory names keep the upstream spelling with its dots and its case. An example is
`lib/src/controllers/controller.polarArea.dart`. Sources from other projects take their Dart
target from `tool/port_sources.yaml` ([Chart.js ADR 0005](0005-third-party-sources.md)).

**The `simpleArc` exception.** `lib/src/plugins/plugin.filler/simpleArc.dart` keeps its name. It
carries `// ignore_for_file: file_names` below its header lines.

**Identifiers.** Identifiers are Dart-cased. Constants use lowerCamelCase, for example `PI` →
`pi`, `TAU` → `tau` and `RAD_PER_DEG` → `radPerDeg` (`helpers.math.dart`). Classes keep their
UpperCamelCase names.

**Underscore exports.** Upstream `_`-prefixed exports drop the underscore, for example
`_angleDiff` → `angleDiff`. The package does not export `lib/src`. Thus these names stay internal
to the package. The `///` line keeps the upstream name, for example
`` /// helpers.math.ts:152 `_angleDiff`. ``.

**Collisions.** If two names collide without the underscore, import one library with a prefix,
for example `as helpers_config`. The known case is `core.config.js`. Its line 1 imports
`descriptors` from `core.defaults.js`. Its line 3 imports `_descriptors` from `helpers.config.ts`.

**Underscore members.** A `_`-prefixed member that another module reads drops the underscore. It
carries `@internal` from `package:meta`. Examples are `meta._parsed` (19 uses in 4 files, 8 of
them outside `core.datasetController.js`) and `chart._animationsDisabled` (5 reads outside
`core.controller.js`). A `_` member that only its own file reads keeps the underscore.

## Consequences

- The map from an upstream path to a Dart path is mechanical. Tool 2 compares each Dart path with
  the mapped path.
- Bump diffs, file headers and the Dart tree name the same paths, apart from the extension.
- If `file_names` starts to examine the whole name, this ADR needs a new form
  ([porting-flow.md](../porting-flow.md) §7, risk 5).
- `@internal` needs `meta` as a dependency of `flutter_chartjs`. The first PR that uses
  `@internal` adds it ([porting-flow.md](../porting-flow.md) §6).
