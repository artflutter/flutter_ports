# Chart.js ADR 0118: The theme compile writes typed setters and has no guard

- Status: accepted (2026-11-12): its code and the tests of section Tests pass.
- Date: 2026-11-12
- Supersedes: item 6 of [Chart.js ADR 0117](0117-typed-theme-tokens.md) (the emission guard stays as the debug
  assert of each emitted key); parts of [Chart.js ADR 0050](0050-public-theme-api.md): the sentence "A debug assert
  and a test enforce this list" of the never-emitted list, and the words "`_put` with its assert" in "No public `raw`
  in 0.1.0"; and the sentence of [Chart.js ADR 0054](0054-typed-internal-model.md) "The frozen Map of the compiled
  theme (an object under a key with no option kind) is `JsFrozenMap` of the JS runtime".
- Related: theming.md §3.3 (the never-emitted list) and §4 (the token table).

## Context

After Chart.js ADR 0117, `compileChartTheme` took 10 typed tokens. It still wrote each key as a dotted string path
(`'scale.ticks.color'`) into a Map, and `_typed` then wrote that Map into the typed scopes by name. Each path went
through the emission guard `themeNeverEmittedReason` in a debug assert. The guard and its sets were about 250 lines.
The guard protected the compile from a raw Map input. That input is gone. The emitted paths are now constant code,
so no input can reach a key outside the token table.

## Decision

1. The compiler writes each key with the typed setter of its scope, for example `ticks.color = color`. A private
   tree makes each scope at its first use and puts it into its parent. Thus each scope gets its keys in the order of
   their first write, as before.
2. Two keys stay keys by name, because their scope is a dictionary by name: the scale id `radialLinear` under
   `scales`, and the port-only modes `theme` and `themeFrame` under `transitions`. The compiler writes them with
   `store` and an `OptScope` cell, as the typed lowering writes a scale id.
3. Gone: `themeNeverEmittedReason`, the sets `themeScaleTypes`, `themeBehaviorKeys`, `themeTooltipInteractionKeys` and
   `themePluginBehaviorPaths`, the path lists, `_put`, `_typed`, the Map case of `_freeze`, and `JsFrozenMap` of the
   JS runtime, which had no other user.
4. The never-emitted list of theming.md §3.3 stays as a design rule: the token table has none of its keys. A later
   public `raw` field needs this list as its guard, in a new ADR (Chart.js ADR 0050).
5. The compiler freezes each scope that it makes, and each palette List is frozen at its construction.

## Consequences

- The compiler has no by-name read: its baseline of `check:typed-reads` is gone.
- A change of the token table is a change of code in `compileChartTheme`, and of the expected paths in the tests.

## Tests

- `test/port/theme/compile_test.dart`: the test themes and the light tokens compile only to the paths of the token
  table (`_tokenPaths`), the key order, the deep freeze (each scope, also each transition scope, and each List) and
  the other tests of the compile.
- `test/port/theme/theme_data_test.dart`, the group `B3: the token allowlist`: each token alone emits exactly its
  paths of theming.md §4.
- The light-preset groups of the controller and plugin reference tests and the coverage snapshot: the light tokens
  still give an unthemed chart.
