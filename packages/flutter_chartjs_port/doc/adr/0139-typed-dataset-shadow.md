# Chart.js ADR 0139: The dataset option `shadow` holds a `ChartShadow`

- Status: accepted
- Date: 2026-11-13
- Related: Chart.js ADRs 0054, 0074, 0100, 0106, 0107, 0130.
- Supersedes: items 2, 3, 4 and 5 of Chart.js ADR 0107, and its rejected alternatives "A nested
  `shadow` object in the dataset" and "New keys in the option schema".

## Context

Chart.js ADR 0107 gave each typed dataset the parameter `shadow`, a `ChartShadow`. The lowering
split the shadow into four plain keys of the dataset: `shadowColor`, `shadowBlur`, `shadowOffsetX`
and `shadowOffsetY`. The keys were extras of the typed dataset scope, and the inline plugin of
`ChartView` read them back by name with four `jsGet` calls. A raw dataset had to set the four keys,
and the config check had a special case for `shadowColor`.

Chart.js ADR 0107 gave two reasons for the split. First, a nested object sent each update of the
dataset to the full path, because the data-only check accepted plain values only. Second, the
option schema held the keys of Chart.js, and its drift test compared them with the upstream
inventory.

Both reasons are gone:

- The data-only checks of Chart.js ADRs 0074 and 0100 now accept native value types. The dataset
  option `clip` holds a `ChartClip`, an immutable Dart object, and the native option plans count it
  as a scalar.
- The schema holds port-only keys and kinds, for example `$theme` of the root config and the
  port-only kind of the element options of a custom element type. The drift test
  (`test/port/options/schema_test.dart`) checks that each path of the upstream inventory and of the
  key census maps to a declared key, and that each leaf of the built default roots is an inventory
  path. It does not require a declared key to be upstream. A key with no default is no leaf of the
  roots.

## Decision

1. `ChartShadow` is a class of the core file `lib/src/types/chart_shadow.dart`. It has `color` (a
   `Color`, required), `blur` (the `shadowBlur` of the canvas, default 0, not negative) and
   `offset` (an `Offset`, default `Offset.zero`), and `copyWith`, `==`, `hashCode` and `toString`.
   The class is open. It does not use `Diagnosticable`, because a core file imports no Flutter
   framework library.
2. The schema has the typed atom `chartShadow` and the key `shadow: chartShadow` in the seven
   dataset kinds that have `clip: chartClip`. The key is port-only. The chart options have no key
   `shadow`.
3. The lowering writes the `ChartShadow` of `Dataset.shadow` into the key `shadow` with no copy.
   `Dataset.extra` merges after it, so an entry `shadow` of `extra` wins.
4. A `ChartView.raw` dataset sets the same `ChartShadow` in its key `shadow`. A value of another
   type stops a debug build in the plugin, and a release build draws no shadow. The keys
   `shadowColor`, `shadowBlur`, `shadowOffsetX` and `shadowOffsetY` of a dataset are plain extras
   with no effect. The config check has no special case for `shadowColor`.
5. The inline plugin `$chartView` reads the option with `readOption(dataset, OptionKey.shadow)` in
   `beforeDatasetDraw`. For a `ChartShadow`, it calls `save()` and sets the four canvas attributes
   from the fields. Its `afterDatasetDraw` calls `restore()`.
6. The native option plans (`_indexedScalar` of `helpers.config.dart`) count a `ChartShadow` as a
   scalar, and the static settings check of the data-only update (`staticDataUpdateOptions` of
   `data_update.dart`) accepts a `ChartShadow` of the exact class with a `Color` of the exact
   class. Thus a dataset with a shadow keeps the data-only update.
7. `lib/chartjs.dart` exports `ChartShadow`, as it exports `ChartClip`. The app library gets it
   from there. The typed export list `lib/src/typed/typed.dart` no longer has it, because the name
   rules of the typed API forbid a name of `lib/chartjs.dart`.

Items 1, 6 and 7 of Chart.js ADR 0107 stay. The plugin reads the dataset only: the shadow does not
cascade from `options.datasets` or from `options`.

## Consequences

- The typed API and a raw config hold the same object, and no code splits or joins it.
- The four reads by name go, and with them the baseline of `check:typed-reads` for
  `chart_view_plugin.dart`.
- A raw config of Chart.js ADR 0107 with the four keys draws no shadow now. Version 0.1.0 is not
  released, so no app depends on the keys.
- `doc/public_api.txt` lists `ChartShadow` under `lib/chartjs.dart` too.

## Alternatives considered

- **Keep the four plain keys.** It keeps a split and four reads by name for a value that is one
  Dart object. Rejected.
- **A cascade through the resolver.** The key is in the dataset kinds only, and the plugin reads the
  dataset. A later change can add the key to the chart options and read it through the resolver if
  apps need it.
