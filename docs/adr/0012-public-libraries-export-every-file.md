# ADR 0012: The public libraries export every file

- Status: proposed
- Date: 2026-11-19
- Supersedes: [ADR 0011](0011-public-library-exports-every-file.md); of
  [Chart.js ADR 0048](../../packages/flutter_chartjs_port/doc/adr/0048-entry-points-and-public-library.md), §5,
  §6 and the import rule of §3; of
  [Chart.js ADR 0052](../../packages/flutter_chartjs_port/doc/adr/0052-typed-public-api.md) §8, the import rules of
  `lib/src/typed/`; of [Chart.js ADR 0147](../../packages/flutter_chartjs_port/doc/adr/0147-public-theme-api.md)
  §19, the direct-import test of invariant 4
- Related: [ADR 0009](0009-add-on-ports.md),
  [Chart.js ADR 0061](../../packages/flutter_chartjs_port/doc/adr/0061-native-flutter-colors.md)

## Context

ADR 0011 made each public library export every file of its package, and each file import the public library. It
left out `flutter_chartjs_port`: its core layers reach no Flutter framework library, and its public libraries had
curated name lists. The files of the Chart.js port kept 1615 imports of `src/` files with `show` lists and `types`
prefixes. On 2026-11-19 the maintainer asked to export every name of `flutter_chartjs_port` and to replace the
`src/` imports with `package:flutter_chartjs_port/flutter_chartjs_port.dart`.

## Decision

1. **Exports.** The public library of a package exports each file of `lib/src/`. A package with a pure library and
   a Flutter library splits the files by layer: the pure library exports each file with no Flutter import, and the
   Flutter library exports the pure library and the other files.

   ```dart
   // flutter_d3_color_port/lib/d3_color.dart
   export 'package:flutter_d3_color_port/src/color.dart';
   ```

2. **Imports.** A file of `lib/src/`, a test, a tool and the example import the public library of their package,
   not a file of `lib/src/`. A pure file imports the pure library. An index of `lib/src/` still exports its module
   files.
3. **No combinators.** An import has no `show` list, no `hide` list and no prefix. The exceptions are these:
   - Two imported names clash: a `hide` on one import, or a prefix. A package import hides a `dart:` name with no
     error, so a file that reads `pi` of `dart:math` next to the host helpers has `hide pi` on the helpers.
   - A local name hides an imported name: `core.controller.dart` reads `chartjs.defaults` in the static `defaults`
     of `Chart`.
   - A check needs the list: `package:flutter/painting.dart` in a core layer shows `TextStyle` (Chart.js ADRs 0116
     and 0123).
4. **Flutter names.** A public library hides an internal name that clashes with a name of
   `package:flutter/widgets.dart`, so that an app imports it next to Flutter with no `hide`. An upstream export
   keeps its name: the sankey element `Flow` (sankey seam S21).
5. **Module indexes.** The index of a D3 module exports its files with no `show` list. A renamed specifier stays a
   declaration of the index: `const interpolateHslLong = hslLong;`.
6. **The three libraries of the Chart.js port.**

   ```dart
   // lib/chartjs_core.dart: each core file (Chart.js ADR 0061), no hide.
   // lib/chartjs.dart: chartjs_core.dart and each other file, no hide.
   // lib/flutter_chartjs_port.dart: the app library.
   export 'package:flutter_chartjs_port/chartjs.dart'
       hide Animation, Element, FilterCallback, Title, Tooltip;
   ```

   A core file imports `chartjs_core.dart`. A test that runs in a browser imports `chartjs_core.dart`. Another file
   imports `flutter_chartjs_port.dart`, or `chartjs.dart` when it uses one of the five hidden names. A file with a
   Flutter widget import and a hidden name imports `chartjs.dart` with a prefix. `helpers.dart` and
   `js_semantics.dart` stay the entries of the add-on ports (ADR 0009).
7. **One name, one declaration.** Each public top-level name of `lib/src/` is unique in the package. An interface
   of `src/types/` with the name of a class has the prefix `I`: `IChart`, `IScale`, `IElement` (row
   `adapt-public-library-names`). No export has `@internal`.
8. **Rules on used names.** `check:lib-imports` resolves the names that each file of `lib/src/` and each ported
   test uses (`tool/src/name_uses.dart`). A ported file uses no name of `lib/src/theme/` or `lib/src/typed/`. A file
   of `lib/src/widgets/` uses no name of `controllers/`, `scales/`, `elements/`, `plugins/` or `src/index.dart`. A
   file of `lib/src/typed/` uses only the names of its allowlist. A ported file exports no file of `theme/` or
   `typed/`. Dart tree shaking keeps the names that code uses, so these rules keep the intent of the old import
   rules.
9. **Scope.** The rules apply to each package of `packages/`. `check:lib-imports` reports a `src/` import only in
   the Chart.js port. An add-on port imports the public libraries of its host (ADR 0009).

## Rejected

- Keep the curated lists of Chart.js ADR 0048: each new name needs an edit of a list, and the lists change no code
  that runs.
- One library for the core files and the Flutter files: a core file then reaches the Flutter framework.
- Hide no Flutter name in the app library: each app that uses `Tooltip` or `Title` of Flutter needs a `hide`.

## Consequences

- `doc/public_api.txt` lists each name of `lib/src/`. The next release adds names and removes none.
- A removed prefix or list can bind a name to another declaration with no analyzer error. Each change of imports
  compares the binding of each changed site, and an import of a top-level name never hides an inherited member.
- The interfaces `IElement`, `IPointElement`, `ILineElement`, `ISimpleArc`, `IBasePlatform`, `IDefaults`,
  `IAnimation` and `IAnimationEvent` have a core class of the same role. A later change can remove them.

## Tests

- `test/tool/public_api_test.dart`, `test/tool/check_lib_imports_test.dart`,
  `test/port/plugins/plugin.filler/point_implementers_test.dart`, `test/port/typed/names_test.dart`
- `dart run melos run analyze`, `test --no-select`, `test:web`, `test:cases`, `test:fixtures`, `check:port`
