# Chart.js ADR 0197: The title and subtitle options are one object each

- Status: accepted (2026-11-23): its code is on main, and all the gates of AGENTS.md pass.
- Date: 2026-11-23
- Supersedes: of [Chart.js ADR 0182](0182-resolved-plugin-option-classes.md), item 1 for `TitleOptions` and item 3
  for `Title.options`; of [Chart.js ADR 0052](0052-typed-public-api.md), §1, §4 and §8 for `ChartTitle` and the
  parameters `title` and `subtitle` of `ChartConfig`; of [Chart.js ADR 0054](0054-typed-internal-model.md), §2 for
  the kind `TitleOptions` of the schema and §3 for the typed defaults scopes, the `defaultRoutes` and the
  descriptors of the title and the subtitle; of [Chart.js ADR 0147](0147-public-theme-api.md), item 7 for the title
  and subtitle keys of the theme; of [Chart.js ADR 0181](0181-plugin-classes-and-typed-get-plugin.md), item 1 for
  the options of `TitlePlugin` and `SubtitlePlugin`
- Related: [Chart.js ADR 0193](0193-legend-options-object.md), [Chart.js ADR 0196](0196-filler-colors-options-objects.md),
  [Chart.js ADR 0148](0148-plugin-typing.md)

## Context

The title and the subtitle plugins were the last built-in plugins with three types for their options: `ChartTitle`
of the typed API with its lowering, `TitleOptionsScope` of the schema, and `TitleOptions`, the resolved values that
`TitleOptions.of` made at each update. Chart.js ADRs 0192 to 0196 made the options of the other five plugins one
immutable `PluginOptions` object each.

The two plugins share one box class, `Title`, and one option type upstream (`TitleOptions` of `index.d.ts`; the
`subtitle` of `PluginOptionsByType` is `TitleOptions` at the pin, with `fullSize`). They have two ids and two
defaults. The `color` routes to `Chart.defaults.color` (`plugin.title.js:158-160`), and each option is scriptable
with the chart context (`:162-165`). The fixture `plugin.title/scriptable-options` gives a function `text`.

## Decision

1. **Two classes over one base.** The sealed `TitleBoxOptions<T>` of `plugin_options.dart` is a `PluginOptions<T>`
   with one nullable field for each option of `TitleOptions` of `index.d.ts` (`align`, `display`, `position`,
   `color`, `font`, `fullSize`, `padding`, `text`), `weight`, `scripted` and `events`, and `merge`, `==`,
   `hashCode` and `layoutOption`. `TitleOptions` (id `title`) and `SubtitleOptions` (id `subtitle`) are its two
   final classes: each gives its plugin id and its constructor, and `merge` gives its class. The fields, `merge`
   and `==` are written once; each class keeps `const`. A font merges by field. Two classes, because the plugin
   service merges the objects of one plugin by their class, and `getPlugin<T>()` and the hooks have one type for
   each plugin.

   ```dart
   ChartConfig(
     datasets: [LineDataset(data: .values([3, 5, 2]))],
     pluginOptions: const [
       TitleOptions(display: true, text: ['Sales']),
       SubtitleOptions(display: true, text: ['2026']),
     ],
   );
   ```

2. **The paths of the options.** `ChartTitle`, `lowerTitle`, `TitleOptions.of` and the parameters `title` and
   `subtitle` of `ChartConfig` are removed: an app gives the objects in `ChartConfig.pluginOptions`. A raw config
   holds the object in `options.plugins.title` or `options.plugins.subtitle`; a Map there stops a debug build,
   `false` turns the plugin off and `true` keeps the defaults. The schema has no kind `TitleOptions`: the keys
   `title` and `subtitle` of `PluginOptionsByType` are `bool | pluginOptions`. `new Title(config)` takes a
   `TitleBoxOptions` or throws a `TypeError`. The theme writes one `TitleOptions` and one `SubtitleOptions` with
   the color and the font that it themes.

3. **The defaults.** Each plugin has one `const` object with the defaults of upstream (`plugin.title.js:145-156`,
   `plugin.subtitle.js:32-43`), and no `defaultRoutes` and no `descriptors`.

4. **The fallbacks in Dart.** The `beforeUpdate` hook gives the box the merged object with the fallback of upstream
   (`resolvedTitleOptions` of `plugin.title.dart`): a `color` that no options set is `Chart.defaults.color`. The
   font stays as the options give it, and the box merges it over `Chart.defaults.font` with `toFont` at each read,
   as upstream. The `start` hook gives the box the merged object; the layout reads only `display`, `fullSize`,
   `position` and `weight` before `beforeUpdate`.

5. **One scriptable function.** `scripted` (`TitleScript<T>`) replaces the scriptable form of each option, as
   `LegendOptions.scripted` does: the plugin calls it once for each update in `beforeUpdate`, with the chart
   context and the options with their fallback, merges the result and adds the fallback again. Row
   `adapt-title-scripted`.

   ```dart
   TitleOptions(
     display: true,
     scripted: (context, options) => TitleOptions(text: ['Zoom: ${zoomLevel()}']),
   );
   ```

6. **Tests.** A test that gives title or subtitle options gives a typed config with `pluginOptions`, or the object
   in a raw config. The generators write `TitleOptions` and `SubtitleOptions` literals, with `scripted` for a
   function `text`, and the reference data are generated again with the same expectations. The 12 data fixtures
   with title or subtitle options get a hand port (Chart.js ADR 0115). No helper turns a Map into options.

## Rejected

- One class with a plugin id field: `merge` and the hooks cannot tell a title from a subtitle by type, and
  `SubtitleOptions(...)` has no form.
- `SubtitleOptions` without `fullSize`: the pin types the subtitle as `TitleOptions`, and its defaults set
  `fullSize: true`.
- Keep `ChartTitle` over the objects: two types with the same fields again.

## Consequences

- A new closure in `scripted` is a new value: a typed config built in `build` updates the chart.
- A scriptable title option runs once for each update, in `beforeUpdate`, where upstream runs it at its first read.
- `Title.options` before the first `beforeUpdate` is the merged object with no color.
- The upstream `plugins.title` and `plugins.subtitle` defaults, routes and descriptors of the manifest compare with
  the fields of the objects; the route and the descriptors are a named exception list of the schema test.

## Tests

`test/port/plugins/plugin_options_test.dart`, `test/port/plugins/plugin.title_test.dart`,
`test/port/plugins/plugin.subtitle_test.dart`, `test/specs/plugin.title_test.dart`, `test/port/plugins/index_test.dart`,
`test/port/options/schema_test.dart`, `test/port/typed/lowering_test.dart`, `test/port/theme/compile_test.dart`,
`test/port/fixtures/index_test.dart`
