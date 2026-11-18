# ADR 0011: The public library exports every file

- Status: accepted (2026-11-18): its code and the tests of section Tests pass.
- Date: 2026-11-18
- Supersedes: of [D3 ADR 0008](../../packages/flutter_d3_port/doc/adr/0008-module-packages.md) §6, the `show`
  lists of a module index, the rule "An index exports only the names of its ported files", the exports of the pure
  library and of the bundle libraries, and the prefix of a renamed specifier; of
  [Zoom ADR 0002](../../packages/flutter_chartjs_plugin_zoom_port/doc/adr/0002-file-naming-and-layout.md), item 7
  (the exports of the public library); of
  [Sankey ADR 0002](../../packages/flutter_chartjs_chart_sankey_port/doc/adr/0002-file-naming-and-layout.md), item 2
  (the exports of the public library)
- Related: [ADR 0009](0009-add-on-ports.md),
  [Chart.js ADR 0012](../../packages/flutter_chartjs_port/doc/adr/0012-dart-file-naming.md)

## Context

The files of a port imported each other by their `src/` paths, with `show` lists, `hide` lists and prefixes. The
public libraries exported curated `show` lists. A new name needed edits in several lists, and the lists did not
change the code that runs. On 2026-11-18 the maintainer asked for the form of `flutter_kurkle_color_port`: the
public library exports every file, and each file imports the public library.

## Decision

1. **Exports.** The public library of a package exports each file of `lib/src/`. A package with a pure library and
   a Flutter library splits the files by layer: the pure library exports each file with no Flutter import, and the
   Flutter library exports the pure library and the other files.

   ```dart
   // flutter_d3_color_port/lib/d3_color.dart
   export 'package:flutter_d3_color_port/src/color.dart';
   export 'package:flutter_d3_color_port/src/cubehelix.dart';
   export 'package:flutter_d3_color_port/src/index.dart';
   ```

2. **Imports.** A file of `lib/src/`, a test, a tool and the example import the public library of their package,
   not a file of `lib/src/`. A pure file imports the pure library.

   ```dart
   import 'package:flutter_d3_color_port/d3_color.dart';
   ```

3. **No combinators.** An import has no `show` list, no `hide` list and no prefix. The exceptions are these:
   - Two imported names clash. A `hide` on one import, or a prefix, resolves the clash: `hide Element` on
     `package:flutter/widgets.dart` next to `chartjs.dart`. A package import hides a `dart:` name with no error,
     so a file that reads `pi` of `dart:math` next to the host helpers has `hide pi` on the helpers.
   - A local name hides an imported name: the locals `max` and `min` keep `import 'dart:math' as math;`.
   - Two files declare one name, and a third file needs both: the `utils` prefix of the harness (Chart.js ADR
     0012, Collisions), the prefixes of the hand fixtures, the `types` prefix of the host interfaces.
   - A check needs the list: `package:flutter/painting.dart` in a core layer shows `TextStyle` (Chart.js ADRs
     0116 and 0123).
4. **Flutter names.** A public library hides an internal name that clashes with a name of
   `package:flutter/widgets.dart`, so that an app imports it next to Flutter with no `hide`. A file of `lib/src/`
   that uses that name imports its file. An upstream export keeps its name.

   ```dart
   export 'package:flutter_chartjs_plugin_zoom_port/src/state.dart' hide State;
   ```

   The sankey element `Flow` is an upstream export: the library exports it, and an app imports the library with a
   prefix or Flutter with `hide Flow` (sankey seam S21).
5. **Module indexes.** The index of a D3 module exports its files with no `show` list. A renamed specifier stays a
   declaration of the index, with no prefix: `const interpolateHslLong = hslLong;`. A prefix stays when a
   parameter hides the name (`value.interpolate` in `piecewise.dart`).
6. **Scope.** The rule applies to each package of `packages/` except `flutter_chartjs_port`. A core layer of the
   Chart.js port reaches no library that imports the Flutter framework (Chart.js ADR 0061), and its four public
   libraries have a committed name list that shares no name with Flutter (Chart.js ADR 0048).

## Rejected

- Hide each clashing name in the public library: 13 `src/` imports stay in 9 files of the zoom port.
- Hide no name in the public library: each app that imports the zoom library next to Flutter needs `hide State`.
- Keep the `show` lists: each new name needs an edit of a list, and the lists change no code that runs.

## Consequences

- The public libraries export the helpers of their modules. The next release of each published package adds names
  and removes none.
- A resolution check compares the binding of each name before and after a change of imports: a removed prefix or
  list can bind a name to another declaration with no analyzer error.

## Tests

- `dart run melos run analyze`, `test --no-select`, `test:web`, `test:fixtures:zoom`, `test:fixtures:sankey`,
  `test:zoom:range-only` and `check:port`
