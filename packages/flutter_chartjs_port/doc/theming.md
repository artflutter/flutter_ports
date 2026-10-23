# flutter_chartjs_port theming design

- Status: proposed ([Chart.js ADR 0042](adr/0042-theming.md), accepted (2026-10-23), restates
  [Chart.js ADR 0001](adr/0001-theming.md) with the palette change and supersedes it)
- Date: 2026-10-16
- Related: [forui theming survey](prior-art/forui-theming.md), [porting flow](porting-flow.md),
  [upstream tracking](upstream-tracking.md),
  [ADR 0006](../../../docs/adr/0006-follow-upstream-between-releases.md)

This document gives the design behind Chart.js ADR 0042. That ADR decides the mechanism in
section 3. Section 5 is an API sketch for phase 9.

Upstream paths are relative to `third_party/Chart.js` (v4.5.1, `9c5cf9f`). forui citations use
the form `forui/0.27.6:<path>:<line>` of the [survey](prior-art/forui-theming.md).

**Decision (Chart.js ADR 0042, which restates Chart.js ADR 0001)**

- A theme compiles to one frozen map with the key shape of `Chart.defaults`. The ported resolver
  reads it as one option scope between `overrides[type]` and `defaults`.
- The theme never writes `Chart.defaults`.
- Eight `DIVERGES(chartjs)` hunks do this: H0-H3 in `core.config`, H4a-H4c and H5 in
  `plugin.colors`. With no theme, they have no effect.
- Ported specs and fixtures run with no theme. That run is the oracle.
- `lib/` has no forui or Material dependency.
- Chart.js options beat the theme key by key. There are no deltas, variants or CLI.
- The theme models two states: default and active.

## 1. Goals and non-goals

Goals:

1. **No theme means upstream:** unthemed specs and fixtures behave like v4.5.1.
2. **A small, replayable diff:** the hunks only add lines. No hunk changes an upstream line
   (Chart.js ADR 0042).
3. **Familiar to forui users:** an inherited theme, value equality, `copyWith`, `lerp`, presets.
4. **No writes to `Chart.defaults`:** themes stay per subtree. The colors-plugin check
   (`plugin.colors.ts:90-92`) sees upstream values.
5. **Static values:** default-mode element options stay `$shared` and frozen
   (`core.datasetController.js:823-832`).
6. **A correct runtime switch** with native color animation and reduced motion.
7. **No library floor change for theming:** the floor is `sdk: ^3.13.0`, `flutter: ">=3.47.0"`
   (porting-flow.md §2.12, since 2026-10-21). Theming does not raise it.

Non-goals:

- a second style system: variants, deltas, a typed mirror of all options
- fixes of upstream quirks in core: #11910, `helpers.options.ts:117`, `plugin.legend.js:286`
- brightness detection (upstream declined it in #8658)
- code generation or a CLI
- states that upstream never draws

## 2. forui concepts mapped onto flutter_chartjs_port

| forui 0.27.6 | flutter_chartjs_port | Verdict | Reason |
|---|---|---|---|
| `FTheme` → `_AnimatedTheme` → `_InheritedTheme` (`forui/0.27.6:forui/lib/src/theme/theme.dart:94, 228, 358`) | `ChartTheme extends InheritedTheme`, not animated | adapt | Chart.js animates element colors itself. A lerped theme costs one chart update per frame |
| Without a theme, `FTheme.of` returns `neutral.light.touch` (`forui/0.27.6:forui/lib/src/theme/theme.dart:138-140`) | `maybeOf` gives charts null (upstream). `of` returns `ChartThemes.light` instead | adapt | An unthemed chart must equal upstream |
| `copyWith` without tokens, `touch: true` hard-coded, custom icons lost (`forui/0.27.6:forui/lib/src/theme/theme_data.dart:1411-1418, 617`) | `copyWith` carries every field | adopt, fixed | forui loses fields |
| `FThemeData` factory (`forui/0.27.6:forui/lib/src/theme/theme_data.dart:614-618`), `FColors` (`forui/0.27.6:forui/lib/src/theme/colors.dart:280-299`) | `ChartColors`, named after the `Chart.defaults` fields. The compiler derives every key from them | adapt | The same one-way derivation. Equal names keep bump audits mechanical |
| `FTypography`, `FSizes` (`forui/0.27.6:forui/lib/src/theme/sizes.dart:7`), `FAdaptiveScope` (`forui/0.27.6:forui/lib/src/theme/adaptive_scope.dart:24-38`) | `ChartTypography` of `ChartFont`. No sizes and no platform in 0.1.0 | adapt | Chart.js reads `FontSpec`. Core never reads the platform. `flutter_test` reports Android |
| Generated deltas and sentinels | Chart.js options beat the theme key by key | reject | Options are partial already. Deltas "sometimes confuse even us, the maintainers". LLMs do worse (`forui/0.27.6:design_docs/shipped/untime_retrospective.md:26-32`). The generator needs Dart 3.13. Since 2026-10-21, the library floor is Dart 3.13. Thus this reason no longer applies |
| `FVariants` (`forui/0.27.6:forui/lib/src/theme/variants.dart:173-190`) | modes `default` and `active` | reject | More modes need dataset-controller hunks |
| Blue-screen goldens (`forui/0.27.6:forui/test/src/test_scaffold.dart:14`) | a blue-screen pixel assertion | adopt | It shows that no color bypasses the theme |

## 3. How the theme reaches option resolution

### 3.1 Hunks

The chart widget puts the compiled map into the raw config under `r'$theme'`. `initConfig` returns
the same config object (`core.config.js:129-136`). Every lookup thus sees the map without a
signature change.

| # | Upstream site | Kind | Change |
|---|---|---|---|
| H0 | `core.config.js`, before `class Config` (:158) | added | `themeConfigKey`, the private `_themeOf` and the public `chartThemeOf` |
| H1 | `core.config.js:106-110` (`mergeScaleConfig`) | added | a separate `mergeIf(scale, [theme.scales[type], theme.scale])` before the upstream line |
| H2 | `core.config.js:312-313` (`getOptionScopes`) | added | theme scopes between `overrides[type]` and `defaults` |
| H3 | `core.config.js:336-337` (`chartOptionScopes`) | added | `?_themeOf(_config)` after `overrides[type]` |
| H4a | `plugin.colors.ts`, after :25 | added | the palette keys and two library variables |
| H4b | `plugin.colors.ts:28` (`getBorderColor`) | added | a theme branch before the unchanged line |
| H4c | `plugin.colors.ts:32` (`getBackgroundColor`) | added | a theme branch before the unchanged line |
| H5 | `plugin.colors.ts:123` (`beforeLayout`) | added | sets the two variables from the theme map of the chart (`chartThemeOf`) |

Each hunk has one `// DIVERGES(chartjs): <row id>, <reason>` line and one `differences.md` row.
The row ids are `theme-H0` to `theme-H5`. The header check (porting-flow.md, tool 2) uses
this id to pair markers and rows.

```dart
    // DIVERGES(chartjs): theme-H1, theme scale styles fill first.
    final theme = _themeOf(config);
    if (theme != null) {
      final themeScales = theme['scales'];
      mergeIf(scale, [
        if (themeScales is AnyObject) jsGet(themeScales, jsGet(scale, 'type')),
        theme['scale'],
      ]);
    }
    mergeIf(scale, [
      jsGet(defaults['scales'], jsGet(scale, 'type')),
      defaults['scale'],
    ]);
```

The port tests the type of `theme['scales']`. A theme `scales` value that is not a Map thus gives
no source and no throw. `_themeOf` gives null for a `$theme` value that is not a Map.

`mergeIf` applies its sources in order. It fills only absent keys (`helpers.core.ts:272-282,
310-323`). The separate call thus gives the result of one longer list. The upstream line stays
unchanged. H2 serves dataset, element, animation and plugin options
(`core.datasetController.js:438-445, 815-817`, `core.config.js:229-242`,
`core.plugins.js:175-188`). With no theme, H2 and H3 add no scope. A JS prototype of the hunks on
the chart.js 4.5.1 dist then matched upstream in 10 of 10 option snapshots.

### 3.2 Precedence

For bar `backgroundColor`, from highest to lowest:

1. The dataset, with its `datasets.bar.elements.bar`, `datasets.bar` and `elements.bar` sub-keys
   (`core.config.js:307-309`). The colors plugin writes at this level.
2. user `options`
3. `overrides[type]`
4. the theme: `raw` keys over token keys
5. `defaults`, whose routes read `Defaults.*`
6. descriptors

The defaults level has three parts in this order: the controller defaults `defaults.datasets[type]`,
the element defaults `defaults.elements[type]`, and the root defaults that the routes read. The
theme beats all three. `test/port/theme/precedence_test.dart` pins this order.

Lookup is prefix-major. In active mode, the resolver searches every scope for
`barHoverBackgroundColor` and `hoverBackgroundColor` before `backgroundColor`
(`core.datasetController.js:815`). A static theme hover color thus beats the derived hover color of
every dataset. The compiler therefore emits no hover colors. The root function in `defaults`
derives the hover color from the base color that won (`core.defaults.js:62-64`). In the prototype,
`rgb(200, 0, 0)` gave `#B40000`.

Scales: user `scales.<id>` > chart-type and dataset-type overrides (`core.config.js:89, 102`) >
`theme.scales[type]` > `theme.scale` > `defaults.scales[type]` > `defaults.scale`. Plugins and
chart level: user options > `overrides[type]` > theme > defaults. The chart-type overrides reach
a scale of the user options through its axis (`core.config.js:78-90`). Then each dataset adds the
overrides of `dataset.type || config.type` to its scales (`core.config.js:93-104`). Thus a
dataset without a type also adds the chart-type overrides to the scales that it creates.

### 3.3 Compile step and emitted keys

`compileChartTheme(ChartThemeData?)` is pure and memoized per instance. It returns null when it
emits no visual key. It adds the `transitions` keys only beside visual keys. It freezes its result
deeply. If neither the user options nor `overrides[type]` hold `plugins.<id>`, the theme's map is
`scopes[0]` (`core.plugins.js:162, 177`, `core.config.js:306-314`), the target of the set trap
(`helpers.config.ts:35, 101-106`). No v4.5.1 code writes there. A future write throws instead of a
leak into other charts.

Colors become `rgba()` strings with 8-bit sRGB channels and an alpha from `jsNumberToString`. Other
color spaces convert through `ColorSpace.extendedSRGB` and clamp, because a direct Display P3 to
sRGB `withValues` only clamps (`dart:ui` `painting.dart:3901-3914, 4053-4056` of 3.47.7,
`:3919-3932, 4071-4074` of 3.44.9).
Fonts become `FontSpec` maps of the non-null fields.

Emitted:

- root `color` and the token keys of section 4
- `plugins.colors.$borderColors` and `plugins.colors.$backgroundColors`, from the `palette` field
  `{colors, backgroundAlpha}`: the colors at their alpha, and the colors at `backgroundAlpha` (0.5
  when absent)
- the `raw` keys that pass the guard
- `transitions.theme.animation.{duration,easing}` and `transitions.themeFrame.animation.duration: 0`

In phase 5, the tokens emit only the root `color`, the `scale` keys and the element keys. Phase 6
added the `scales.radialLinear` keys. Phase 8 added the plugin keys and the palette keys. Wave 1
added `plugins.title.color`, `plugins.title.font` and the palette keys. Wave 2 added
`plugins.subtitle.color`, `plugins.subtitle.font` (without `weight`) and the two legend fonts
`plugins.legend.labels.font` and `plugins.legend.title.font` (the whole font token). Wave 3 added
the tooltip keys: the tokens `inverseSurface` and `onInverseSurface` give
`plugins.tooltip.backgroundColor`, `titleColor`, `bodyColor`, `footerColor` and
`multiKeyBackground`. The font token gives `plugins.tooltip.bodyFont` (the whole font token) and
`titleFont` and `footerFont` (without `weight`). The tooltip keys come after the legend keys.

Never emitted. A debug assert and the emission test enforce this list.

- Root `backgroundColor`, `borderColor` and `font`. The `''` scope key resolves to the theme root
  (`helpers.core.ts:338`), ahead of `defaults.elements.<type>`. These keys then beat the arc's
  `'#fff'`.
- Static `hover*Color` keys.
- Behavior keys: `events`, `interaction`, `hover`, `onHover`, `onClick`, `animation`,
  `animations`, `responsive`, `maintainAspectRatio`, `aspectRatio`, `indexAxis`, `type`,
  `datasets`, `parsing`, `devicePixelRatio`, `locale`, `layout`, `display`, `enabled`,
  `forceOverride`, and (Chart.js ADR 0042) the data and decision keys `fill`
  (`filler.options.js:12`), `spanGaps` and `showLine` (`controller.line.js:63, 82`,
  `controller.scatter.js:71, 102, 119`), `stacked` (`core.datasetController.js:120-121`),
  `reverse` (`core.scale.js:481`), `min`, `max`, `suggestedMin` and `suggestedMax`
  (`core.scale.js:262-265`), `beginAtZero` and `grace` (`core.scale.js:394, 429`), `bounds`
  (`scale.linearbase.js:257, 273`), `base` (`controller.bar.js:564`), `grouped`
  (`controller.bar.js:437`) and `skipNull` (`controller.bar.js:639-650`). They change the fill
  target, the line segments, the dataset element, the bar geometry, the data range or the ticks.
  A flat `labels` is not a behavior key, because `plugins.legend.labels` holds the legend colors
  and fonts. The `''` scope of the theme comes before `defaults.datasets[type]`.
  The tooltip also resolves `interaction` (`plugin.tooltip.js:1349`). The
  resolver finds the `hover` scopes of every scope before the `interaction` scopes
  (`helpers.config.ts:346-351`, `core.defaults.js:168-170`). Thus a theme `hover` beats the
  `interaction` of the user options and of `overrides[type]`. It then changes the hover elements
  (`core.controller.js:1259-1260`).
- The interaction keys under `plugins.tooltip`: `mode`, `intersect`, `axis` and
  `includeInvisible` (`core.defaults.js:66-70`, `core.interaction.js:272, 308`). The tooltip
  resolves them from `plugins.tooltip`, then from `interaction` (`core.config.js:267-275`). The
  theme scope of `plugins.tooltip` comes before `defaults.interaction` (H2). Thus a theme key
  changes the tooltip elements (`plugin.tooltip.js:1200`).
- The behavior paths of `themePluginBehaviorPaths` (Chart.js ADR 0042):
  `plugins.decimation.algorithm`, `.samples` and `.threshold` (`plugin.decimation.js:269, 12,
  242`), `plugins.filler.propagate` (`plugin.filler/index.js:47`), `plugins.legend.reverse`
  (`plugin.legend.js:116-117`), `plugins.legend.rtl` (`plugin.legend.js:235-259`),
  `plugins.tooltip.position` (`plugin.tooltip.js:651, 1012, 1218`), `plugins.tooltip.xAlign`
  and `.yAlign` (`plugin.tooltip.js:273, 270`), `scale.labels` (`core.scale.js:360`),
  `scale.ticks.stepSize`, `.count`, `.precision` and `.maxTicksLimit`
  (`scale.linearbase.js:32-104, 216-260`), and the content keys `plugins.title.text` and
  `plugins.subtitle.text` (`plugin.title.js:43, 97`), `plugins.legend.title.text`
  (`plugin.legend.js:487`) and `scale.title.text` (`core.scale.js:102, 613`). The guard
  compares paths, not names: `position` is also a layout key of a box, and it passes. It
  compares each prefix of 2 or more keys of the normalized path, in which a leading
  `scales.<type>` becomes `scale`: thus `scales.linear.ticks.stepSize` fails as
  `scale.ticks.stepSize`. The draw-only keys `plugins.tooltip.rtl` and
  `plugins.tooltip.textDirection`, the fonts and the layout keys of a box pass.
- `plugins.<id>: bool`. Only user options can use it (`core.plugins.js:101-107, 146-154`).
- `scales.<id>` other than a scale type. These keys are dead. H1 reads only
  `scales[<scale type>]`. Chart-level lookups find every defaulted key in the scale copy-in first.
  Scale ids belong to one chart. Key enumeration reads only `scopes[0]` (`helpers.config.ts:73-75`).
  No axis thus appears, also for the allowed `scales.radialLinear` key. The guard knows the six
  scale ids of v4.5.1: `scale.category.js:36`, `scale.linear.js:8`, `scale.logarithmic.js:76`,
  `scale.radialLinear.js:340`, `scale.time.js:201` and `scale.timeseries.js:36`. A third-party
  scale type fails the guard.
- `_`-prefixed keys, read as descriptors (`helpers.config.ts:200-212`), and `$` keys other than
  the palette.
- A palette key with a value that is not a List with at least one item. An empty List gives
  `i % 0` in hunk H4b, a throw in Dart.
- Functions, nulls and the `undefined` sentinel. A JS null is a value. A stored `undefined` blocks
  the scale defaults in the merge of H1.

The compiler leaves out a `raw` List with a rejected item as a whole. It leaves out a Map without
keys. A theme with only `transitions` keys compiles to null.

### 3.4 Fonts

`toFont` fills absent fields from the global `defaults.font` (`helpers.options.ts:115-117`). Only
the scale-title measurement reads a chart-level font. The compiler thus writes a font object into
every slot and no root `font`. The derivation omits the fields that upstream sets locally:

- title weight `'bold'` (`plugin.title.js:148-150`)
- subtitle weight `'normal'` (`plugin.subtitle.js:35-37`)
- tooltip title and footer weight `'bold'` (`plugin.tooltip.js:1281-1283, 1295-1297`)
- point-label size 10 (`scale.radialLinear.js:383-385`)

Fonts merge per key across scopes. CSS family lists belong to ADR: Text.

### 3.5 Palette and the colors plugin

The plugin colorizes the datasets only when they have no user colors and the singleton defaults
are unchanged (`plugin.colors.ts:90-92, 113-121`). Neither check sees the theme. The palette thus
runs under a theme. It writes into the datasets, above the theme.

Chart.js ADR 0042 decides the palette form (form B). H4a adds the two palette keys of a theme map,
two library variables and their reader after `BACKGROUND_COLORS` (`plugin.colors.ts:25`). The
reader gives the List under `plugins.colors` of the theme map, or `null` for a missing key, a value
that is not a List and an empty List (the guard of §3.3 rule 9 also rejects these values). H4b and
H4c add a theme branch before the unchanged upstream line:

```dart
/// plugin.colors.ts:27 `getBorderColor(i)`. The TypeScript source declares
/// no return type. A theme palette holds any static JS value.
Object? _getBorderColor(int i) {
  // DIVERGES(chartjs): theme-H4b, the theme palette comes first.
  final themeColors = _themeBorderColors;
  // js-ok: i is an int and never negative, so Dart % equals JS %.
  if (themeColors != null) return themeColors[i % themeColors.length];
  // js-ok: i is an int and never negative, so Dart % equals JS %.
  return _borderColors[i % _borderColors.length];
}
```

Whenever `beforeLayout` reaches the colorizer, H5 sets both variables from the theme map of the
chart (`chartThemeOf` of `core.config.dart`, the public H0 reader), Dart `null` included:

```dart
    // DIVERGES(chartjs): theme-H5, the palette of the chart theme for this run.
    final theme = chartThemeOf(config);
    _themeBorderColors = _themePalette(theme, themeBorderColorsKey);
    _themeBackgroundColors = _themePalette(theme, themeBackgroundColorsKey);

    final colorizer = _getColorizer(chart);
```

The reset at each run keeps the palette of one chart out of the next chart, also out of an
unthemed chart. H5 comes after the returns of `:103` and `:119`. Thus it runs only when the
colorizer runs. The colorizer runs synchronously right after H5. A test interleaves two charts with
different palettes. H5 reads the theme map, not the plugin options. Thus a `$borderColors` key in
the user options, `overrides[type]` or `defaults` has no effect, as upstream. An argument instead
of the variables changes six upstream signatures: `getColorizer`, the three `colorize*` functions
and both getters.

### 3.6 Scale copy-in and option caches

`mergeScaleConfig` copies the defaults into `options.scales.<id>` once (#11910, open). `update()`
merges into that copy (`core.config.js:115-120, 197-201`). H1 puts the theme into the copy. A theme
switch therefore needs fresh user options. Without them, the prototype kept the old `x` ticks.

The caches need no hunk. `chart.update()` clears or rebuilds every option cache
(`core.controller.js:478-488, 653-655`). `keyCache` holds keys only (`core.config.js:138-149`).
`_sharedOptions` refreshes only in non-direct modes (`core.datasetController.js:229, 867-872,
910-914`).

### 3.7 Runtime theme switch

Port-only code in the phase 9 widget does the switch. The widget keeps a shallow copy of the input
datasets.

```dart
    // #11910: mergeScaleConfig copied the old theme into options.scales.
    final options = widget.config['options'];
    chart.options = options is Map<String, Object?>
        ? copyJsonLike(options)
        : <String, Object?>{};
    // The colors plugin wrote the old palette into the datasets.
    restorePaletteKeys(chart.datasets, _inputDatasets());
    chart.update(_mode(scope));
```

Before this code, equal themes return early. The compiled map then replaces or removes `$theme`.
`restorePaletteKeys` resets in place only `borderColor` and `backgroundColor`, the keys that the
plugin writes (`plugin.colors.ts:36-37, 43, 49`). Dataset identity must survive, because metasets
use the dataset object as their key (`core.controller.js:832`). In the prototype, fresh dataset
copies showed a hidden dataset again, rebuilt the controller and replayed the entry animation (bar
`y` 272 → 192). The in-place restore kept all three. Data arrays and decimation state
(`plugin.decimation.js:249-265`) stay unchanged.

Update modes: `'theme'` animates (section 3.8). Reduced motion
(`MediaQuery.maybeDisableAnimationsOf`) uses `'themeFrame'`, with zero duration. Theme removal
uses `'default'`, as any upstream option change does. The widget never uses `'none'`, because the
elements then keep their old colors. It never uses `'resize'`, because that mode skips the radar
line options (`controller.radar.js:61-62`).

The modes `'theme'` and `'themeFrame'` need no code in the animation files. The resolver reads the
emitted `transitions` keys (section 3.8). [Chart.js ADR 0019](adr/0019-animation.md) §10
(proposed) leaves the reduced-motion policy to the phase 9 widget. The core, the animator and the
chart host have no reduced-motion code. The Open section of that ADR lists these candidates:
- `animation: false` in a port-only scope of the widget while the preference is on. The user
  `onComplete` and `onProgress` callbacks then stop.
- A flag for each chart that `_createAnimations` reads one time. It keeps the user callbacks. It
  also stops the animation of a theme removal.
- `'themeFrame'` for theme switches only, as above. Theme removal then needs a mode with the
  duration 0 and without the theme scope.

The phase 9 decision does not write `defaults.animation`, because `defaults` is global.

### 3.8 Animation of a theme change

The compiler emits `transitions.theme` with 200 ms and `'linear'`, the values of forui's
`FThemeMotion` (`forui/0.27.6:forui/lib/src/theme/theme.dart:283-291`). The resolver reads it
through `datasetAnimationScopeKeys` (`core.config.js:229-242`). The `colors` animation covers
`color`, `borderColor` and `backgroundColor` (`core.animations.defaults.js:2, 22-31`). Scales,
legend, title and tooltip switch at once, as upstream does for any option change. In 0.1.0 the
duration and the easing are fixed.

## 4. Token mapping

A null token themes nothing. A partial theme thus restates nothing.

| Token | Replaces (v4.5.1) | Emitted keys |
|---|---|---|
| `colors.color` | `Defaults.color` `'#666'` (`core.defaults.js:43`) | root `color` (the legend reads it through `chart.options.color`, `plugin.legend.js:661, 707`), `scale.ticks.color`, `scale.title.color`, `scales.radialLinear.pointLabels.color`, `plugins.title.color`, `plugins.subtitle.color` |
| `colors.borderColor` | `Defaults.borderColor` (`:42`) | `scale.grid.color`, `scale.border.color`, `scales.radialLinear.angleLines.color`, `elements.{point,line,bar}.borderColor` |
| `colors.backgroundColor` | `Defaults.backgroundColor` (`:41`) | `elements.{point,line,bar,arc}.backgroundColor` |
| `colors.surface` | `'#fff'` (`element.arc.ts:379`), `'rgba(255, 255, 255, 0.75)'` (`core.scale.defaults.js:81`) | `elements.arc.borderColor`, `scale.ticks.backdropColor` at alpha 0.75 |
| `colors.inverseSurface` | `'rgba(0,0,0,0.8)'` (`plugin.tooltip.js:1279`) | `plugins.tooltip.backgroundColor` |
| `colors.onInverseSurface` | `'#fff'` (`plugin.tooltip.js:1280, 1287, 1292, 1305`) | `plugins.tooltip.{titleColor,bodyColor,footerColor,multiKeyBackground}` |
| `palette` (`{colors, backgroundAlpha}`) | `BORDER_COLORS`, `BACKGROUND_COLORS` (`plugin.colors.ts:14-25`) | `plugins.colors.$borderColors` (the colors at their alpha), `plugins.colors.$backgroundColors` (the colors at `backgroundAlpha`, 0.5 when absent) |
| `typography.font` | `Defaults.font` (`core.defaults.js:54-60`) | `scale.ticks.font`, `scale.title.font`, `plugins.legend.labels.font`, `plugins.legend.title.font`, `plugins.tooltip.bodyFont`. Without weight: `plugins.title.font`, `plugins.subtitle.font`, `plugins.tooltip.titleFont`, `plugins.tooltip.footerFont` |
| `typography.pointLabels` | point-label size 10 (`scale.radialLinear.js:383-385`) | `scales.radialLinear.pointLabels.font`: the base font without size, then this font |

"At alpha 0.75" replaces the alpha of the surface color, as `plugin.colors.ts:25` replaces the
alpha of the palette.

`ChartThemes.light` writes `borderColor: Color.from(alpha: 0.1, red: 0, green: 0, blue: 0)`.
This keeps the alpha exact. `Color(0x1A000000)` emits `rgba(0, 0, 0, 0.10196078431372549)`
instead.

## 5. API sketch (decided in phase 9)

The theme classes stay internal until phase 9. The sketch fixes only the names that the mechanism
tests use. The samples compile under Dart 3.13, the library floor (porting-flow.md §2.12).

### 5.1 The 0.1.0 surface

`ChartTheme({required ChartThemeData? data, required Widget child})` extends `InheritedTheme`.
`data: null` disables theming. Charts read `ChartTheme.maybeOf`, where null means upstream. Other
widgets read `ChartTheme.of` or `context.chartTheme`, with `ChartThemes.light` as the fallback.

```dart
@immutable
class ChartThemeData with Diagnosticable {
  /// `const ChartThemeData()` themes nothing and compiles to null.
  const ChartThemeData({
    this.colors = const ChartColors(),
    this.typography = const ChartTypography(),
    this.palette,
    this.raw = const <String, Object?>{},
  });

  final ChartColors colors;
  final ChartTypography typography;

  /// Null keeps the Chart.js palette (plugin.colors.ts:14-25).
  final ChartPalette? palette;

  /// Chart.js keys without a token. They beat the token keys.
  final Map<String, Object?> raw;

  // copyWith (every field), lerp, == and hashCode (deep) omitted.
}
```

`ChartThemeData` stores nothing derived. `copyWith(colors: …)` thus changes every key that
derives from the colors. `lerp` interpolates the tokens and the palette. It switches `raw` at
`t = 0.5`. It returns `a` for `lerp(a, a, t)`, because `a*(1-t)+a*t != a` in floating point.
Examples of `raw` keys are `scale.ticks.textStrokeColor` (`core.scale.defaults.js:67`) and
`plugins.tooltip.borderColor` (`plugin.tooltip.js:1308`). The emission guard applies to them too.

Presets:

- `ChartThemes.light` holds every token at its v4.5.1 value. Its palette is the list of
  `plugin.colors.ts:14-22` with background alpha 0.5 (`:25`). Test 3 checks it against the
  unthemed oracle.
  Without a theme, `ChartTheme.of` returns it.
- `ChartThemes.dark` uses this project's own colors, not forui colors. It keeps the Chart.js
  palette and the upstream hover colors.
- `ChartThemes.none` is `const ChartThemeData()`. It compiles to null. It is a per-chart opt-out.

On the phase 9 widget, here `ChartView({required config, theme})`, Chart.js options in `config`
beat the theme key by key. This is the delta mechanism. `theme:` replaces the inherited theme, for
example with `ChartTheme.maybeOf(context)?.copyWith(…)`. `ChartTheme(data: null)` or
`theme: ChartThemes.none` disables theming. The widget name must not be `Chart`, because `Chart`
is the ported controller (`core.controller.js:103`).

Typed component styles (elements, scale, legend, tooltip, title) are not part of 0.1.0. ADR:
Typed options API decides them after 0.1.0 (porting-flow.md, decision 2.1). One option reuses
the generated option classes, with the tokens as defaults. The other option keeps component
overrides in `raw`. Until then, one internal function derives the keys of section 4.

### 5.2 Later

| Item | Content | Condition |
|---|---|---|
| `AnimatedChartTheme`, `ChartTheme.targetOf` | lerps `data` per frame. A private `ChartTheme._({data, target, child})` gives charts the end value | an app needs a lerped theme |
| `ChartThemeTransition.frames` | one chart update per frame, scales included | a phase 9 benchmark |
| `ChartThemeExtension<T>` with `toScope` | `plugins.<id>.*` of a third-party plugin, from the tokens | the first ported third-party plugin |
| Hover strategies | sealed `ChartHover`: `UpstreamChartHover`, `IdentityChartHover`, `LightnessChartHover`. Root `hover*Color` scriptables, one set per value, read only in active mode | a dark preset with lighter hover colors |
| `touch` flag, `ChartSizes` | hit and hover radius, tooltip and legend padding, font sizes. Never behavior keys | a new ADR that supersedes Chart.js ADR 0042, together with ADR: Input events and interaction state |
| Material snippet | `onSurfaceVariant`, `outlineVariant`, `primary` at alpha 0.1, `surface`, `inverseSurface`, `onInverseSurface`, `textTheme.bodySmall` of the target `ThemeData`. CI compiles it in the gallery | after 0.1.0 |
| forui adapter | section 5.3 | after 0.1.0 |

`LightnessChartHover` uses this project's own rule over the ported `@kurkle/color`. If the HSL
lightness of the base color is below 0.5, the hover color is `lighten(lighten)`. Otherwise it is
`darken(darken)`. forui's `FColors.hover` gave only the idea of a direction from the lightness. No
forui code goes into the library.

### 5.3 forui adapter (after 0.1.0)

`packages/flutter_chartjs_port_forui` gives the widget `FChartTheme` and `toApproximateChartTheme` on
`FThemeData`, after the model of `toApproximateMaterialTheme`
(`forui/0.27.6:forui/lib/src/theme/theme_data.dart:981`). It is not a `ThemeExtension`. It uses
forui's floor: `forui: ^0.27.0`, `sdk: ^3.13.0`, `flutter: ">=3.47.0"`. Since 2026-10-21, the
library has the same `sdk` and `flutter` floor (porting-flow.md §2.12). Thus the floor no longer
blocks an adapter on forui 0.27.

Mapping: `color` ← `mutedForeground`, `borderColor` ← `border`, `backgroundColor` ← `primary`
at alpha 0.1, `surface` ← `background`. The tooltip maps `inverseSurface` ← `foreground` and
`onInverseSurface` ← `background`, as in
`forui/0.27.6:forui/lib/src/widgets/tooltip/tooltip.dart:465-471`. The font is
`typography.body.xs`. `FColors` has no chart tokens. The Chart.js palette thus stays, unless the
app gives one.

`FTheme` lerps for 200 ms (`forui/0.27.6:forui/lib/src/theme/theme.dart:228-281`). The adapter
reads the target `FThemeData` of the nearest `FTheme`, not the lerped value. Charts thus update
once. Inside a nested `FBasicTheme`, the adapter finds the farther `FTheme`. The app then gives
`data:`. The adapter gets one release per forui minor, because forui minors often break the API.

The adapter change also does these items:

1. The adapter takes its name from
   [ADR 0007](../../../docs/adr/0007-package-names.md) item 5. First-party design-system adapters
   take the name `flutter_chartjs_port_<system>`. They stay `publish_to: none` until their first
   release. On 2026-10-22, pub.dev had no package `flutter_chartjs_port_forui`.
2. It adds the `commitlint.yaml` scope `flutter_chartjs_port_forui` and a line in the AGENTS.md Layout
   section.
3. It adds the package `LICENSE` and its `REUSE.toml` annotation.

## 6. States

| State | Upstream | Theme |
|---|---|---|
| default | mode `'default'`, prefixes `[type, '']` | token keys |
| active (hover, touch, `setActiveElements`) | mode `'active'`, prefixes `[typeHover, 'hover', type, '']`, `context.active`, 400 ms (`core.datasetController.js:804-835, 919-935`, `core.animations.defaults.js:38-42`) | upstream `getHoverColor` (`helpers.color.ts:28-32`) over the themed base. Hover strategies wait (section 5.2) |
| pressed, focused, disabled, selected, hidden legend item | none | not modeled. A focus ring is a port-only plugin (ADR: Input events and interaction state) |
| platform | none | none in 0.1.0. A later `touch` flag changes sizes only |
| brightness | declined (#8658) | The app picks the theme. Nothing reads the platform brightness |

The state is `active`, not `hovered`, because touch and code set it too. The spec harness installs
no theme. It disables the colors plugin (`test/index.js:25-28`, porting-flow.md, section 3). Hover
specs such as `controller.line.tests.js:784-799` thus run unthemed. Theme tests assert that
`Defaults` stays unchanged.

## 7. Port-only code and divergences

- `lib/src/theme/` holds `tokens.dart`, `theme_data.dart`, `chart_theme.dart`, `presets.dart` and
  `compile.dart`, each with the port-only header (porting-flow.md, section 1). The parity generator
  (porting-flow.md, tool 6) lists them in its port-only section. They get no `differences.md` rows.
- Each hunk has one row in `packages/flutter_chartjs_port/doc/differences.md`, in the column set of porting-flow.md. A
  theme row has the category `theme`. It names its section 8 test. The H4b and H4c rows say
  "added lines".
- The import guard (porting-flow.md, tool 1) must reject an import of `src/theme/` in a ported
  file. It keeps `lib/` free of `material`, `cupertino`, `material_ui` and `forui`. The forui
  adapter is its own package. The Material snippet lives in the gallery.
- `dart run melos run parity` writes the `differences.md` row count by category into the `core.config` and
  `plugin.colors` rows of `parity.md`. Nobody edits these notes by hand. The status texts of these
  rows in `doc/status.yaml` hold the placeholder `{{differences}}`.
- Port-only tests live under `test/port/theme/`.

## 8. Tests

Required in phases 5-8. The hunks in brackets are the `differences.md` rows that a test pins.

1. **No theme equals upstream** (H0, H2, H3). Unthemed ported specs and fixtures are the oracle.
   Port-only tests: no extra scope without a theme, the section 3.2 position with a theme,
   `ChartThemes.none` compiles to null, no dependence on `TargetPlatform`.
2. **Precedence** (H1, H2, H3, H5). A sentinel table has one row per level of section 3.2, for
   elements, scales, plugins and chart level. The palette beats the theme element colors. User
   colors disable the palette. The group `palette` of `test/port/theme/precedence_test.dart` has
   the palette rows (phase 8, wave 1). The expected lines come from a JavaScript prototype of the
   hunks H4a-H5 on the pinned `plugin.colors.ts`.
3. **The light preset equals upstream** (H4a, H4b, H4c, H5). The test resolves 8 chart types with
   the colors plugin on and off. It compares element options (default and active) and the scale,
   legend, tooltip, title and subtitle keys, with colors parsed. The JS prototype matched 16 of 16
   cases with the explicit palette. The controller test files have the part with the colors
   plugin off (phase 7). The group `test 3: the light palette` of `precedence_test.dart` has the
   part with the colors plugin on (phase 8, wave 1). The plugin keys are in
   `presets_plugins_test.dart` (phase 8, wave 3). The reference tests of the seven plugins run
   their cases again with the light preset (phase 8).
4. **Coverage snapshot.** A committed JSON snapshot holds `compileChartTheme(ChartThemes.light)`.
   The test compares it with the defaults inventory of the upstream manifest (porting-flow.md,
   tool 4) and a `notThemed` list with a reason per key. It reports:
   - ADDED: a visual leaf that is neither emitted nor listed
   - REMOVED: an emitted path that upstream no longer has
   - CHANGED: an emitted value that differs from upstream, with the new literal
   - STALE: a `notThemed` key that upstream removed, that the preset emits, or whose upstream
     value differs from the value that its reason uses (the local font weights of title,
     subtitle and tooltip)
5. **Emission rules.** Presets and test themes compile only to allowed paths. A themed
   `scales.<id>` fails the emission guard and creates no axis on a doughnut. A themed
   `scales.radialLinear` creates no axis on a bar chart.
6. **Blue screen.** A test-support theme sets every token and the palette (alpha 1) to one blue,
   on a blue background. In all 8 chart types, with titles, legend title and a visible tooltip,
   every pixel must be blue. The test needs no golden file. The 8 default charts have no leak:
   their committed known-leaks list is empty. A pin case gives a legend item without `fillStyle`
   and `strokeStyle`. It has the leak of the singleton `defaults.color`
   (`plugin.legend.js:286, 314, 319`) in its own committed list. Each list fails when it changes.
   The JS prototype (Chart.js ADR 0042, probe P2) covered the 8 types with the colors plugin on
   and off, with no hover. It found no leak. The active-element case waits for
   `IdentityChartHover`.

Section 10 ("Phase 5 state" to "Phase 8 state") names the test files and the test groups of
phases 5 to 8.

Required in phase 9:

7. **Equality and lerp.** Equal themes are `==` with equal hashes. Each field breaks `==`. The
   test covers `copyWith()`, the `lerp` ends and `lerp(a, a, t)`. Equal themes cause no
   `chart.update`. `InheritedTheme.capture` reaches overlays.
8. **Theme switch.** A switch updates elements, scales and the palette. A hidden dataset stays
   hidden. Controllers, data arrays and decimated data stay. Removal restores the upstream colors.
   Reduced motion uses `'themeFrame'`.
9. **Goldens.** One golden per public preset on one chart type, on the pinned runner
   (porting-flow.md, section 3).

Only a regression adds more: SHADOWED and INCONSISTENT coverage classes, randomized themes, or
goldens for each chart type.

## 9. Upstream bump impact

Review these items on each bump, and on each backport (ADR 0006) into a hunk host:

- the values that the presets restate: `core.defaults.js:41-64`, `element.arc.ts:377-395`,
  `element.point.ts:31-50`, `core.scale.defaults.js:28-89`, `scale.radialLinear.js:345-410`,
  `plugin.tooltip.js:1274-1331`, `plugin.title.js:145-160`, `plugin.subtitle.js:32-47`,
  `plugin.legend.js:636-720`, `plugin.colors.ts:14-25, 90-92`, `core.animations.defaults.js:1-72`
- the routes (`defaultRoutes`, `defaults.route`), because they define what a token means
- new visual keys, also keys without defaults
- the hunk hosts `core.config.js:106-110, 296-342` and `plugin.colors.ts:14-33, 102-126`, with 3
  and 6 commits in `v4.0.0-release..v4.5.1`. The palette hunks landed in phase 8.
- the singleton reads that the theme cannot reach: `plugin.legend.js:286`, `helpers.options.ts:117`,
  `scale.radialLinear.js:14`, `plugin.colors.ts:91`, `core.datasetController.js:817`
- resolver semantics, `mode` branches in controllers, and the upstream signals #12268, #12205 and
  #11910 ([upstream-tracking.md](upstream-tracking.md))

A backport into a hunk host re-applies the hunks and runs their pinning tests. The
port-upstream-change checklist (upstream-tracking.md) needs this step.

Theming owns no tool. The coverage snapshot test (section 8, item 4) is the only map from
defaults to tokens. The bump PR runs it against the new manifest. Section 6 of the bump report
(upstream-tracking.md) lists the raw defaults diff, the `index.d.ts` diff, the theme hunks in
changed hosts and, from phase 6, the coverage snapshot output. Its rows get the `theme-review` action. It has no token map.

Example, v4.5.1 to `master` `7169e651`: #12130 adds the scale title keys `strokeColor` and
`strokeWidth` without defaults (`core.scale.js:1615-1619`). Thus the manifest has no new leaf, and
the coverage snapshot test needs no change. A `notThemed` line for a key that the manifest does
not have fails as STALE. Apps can set the keys through `raw`. #12238 adds a geometry key. No hunk
host changed.

## 10. Delivery plan

[porting-flow.md](porting-flow.md), section 5, owns the phase table. This table lists only the
theming work in each phase.

| Phase | Theming work | Needs |
|---|---|---|
| 0. Now | the forui survey, this document and Chart.js ADR 0001 (proposed), linked from `docs/README.md`, `packages/flutter_chartjs_port/doc/prior-art/README.md` (Pages) and `packages/flutter_chartjs_port/doc/README.md` (Chart.js ADR 0001 and this document) | — |
| 1. Decisions and minimum tooling | Chart.js ADR 0001 is accepted for its four invariants only. The rest stays proposed. porting-flow.md, section 6, adds the four invariants of Chart.js ADR 0001 to AGENTS.md rule 5 | — |
| 2. JS runtime, helpers, defaults | a faithful `core.defaults` singleton, `getHoverColor`, `jsNumberToString` | [Chart.js ADR 0032](adr/0032-js-numeric-semantics.md) |
| 3. Canvas, text, platform, harness | CSS `rgba()` and font strings in the canvas layer, a harness without a theme | ADR: Canvas model, ADR: Text |
| 4. Elements | nothing | — |
| 5. Core | a Dart prototype of H0-H3, then Chart.js ADR 0001 accepted. H0-H3, `compile.dart` over raw Map themes, the guard, internal `ChartThemes.light`, test 1 and the non-palette rows of test 2 with test-registered components, `differences.md` rows | `core.config`, `helpers.config`, [Chart.js ADR 0006](adr/0006-options-representation-and-resolver.md) |
| 6. Scales | H1 tests with real scales, test 4 against the defaults inventory that tool 4 records from mid phase 2 | scale ports, porting-flow.md tool 4 |
| 7. Controllers | test 3 for elements and scales, test 5, hover tests, the blue screen without plugins | controllers |
| 8. Plugins | H4a-H4c and H5, the palette rows of test 2, test 3 for plugin keys and the palette, decimation tests, the full blue screen | plugin ports |
| 9. Flutter API and release | public theme classes and presets, the theme widget and its sync, docs, tests 7-9 | public widget |
| After 0.1.0 | section 5.2 items on demand, `flutter_chartjs_port_forui` | ADR: Toolchain pin and library floor |

**Phase 5 state.** These parts exist:
- The hunks H0-H3 in `lib/src/core/core.config.dart`, with the rows `theme-H0` to `theme-H3`. The
  groups `theme-H0` to `theme-H3` of `test/port/core/core.config_test.dart` pin them.
- Test 1 at the `Config` level, and the element, scale, plugin and chart-level rows of test 2. They
  use raw Map themes, and they write `defaults` and `overrides` directly. They also pin the derived
  hover color of section 3.2.
- `lib/src/theme/compile.dart`: `compileChartTheme` over raw Map themes, the emission guard and the
  deep freeze. Until phase 9, a theme is a raw Map theme with the fields `colors`, `typography` and
  `raw`. A color token is a `RawThemeColor` record of sRGB components from 0 to 1.
- `lib/src/theme/presets.dart`: the internal `ChartThemes.light` and `ChartThemes.none`. The light
  preset holds `colors.color`, `colors.borderColor`, `colors.backgroundColor`, `colors.surface`
  and `typography.font`.
- The tests in `test/port/theme/`. `compile_test.dart` has test 1 and test 5 without a chart.
  `presets_test.dart` compares the light preset with `light_reference.dart`, the phase 5 part of
  test 3. `target_platform_test.dart` runs test 1 under each `TargetPlatform`, on the VM.
- `presets_test.dart` registers the four elements through a new `TypedRegistry` in its `main()`,
  before the snapshot of the defaults restore. It has no copy of `registerDefaults`.
- `test/flutter_test_config.dart` registers the built-in components before the snapshot of the
  restore (row `harness-register-builtins`). `presets_test.dart` calls `setUpSpecs()` first. That
  call removes the built-in components again.
- Test 1 at the chart level and the non-palette rows of test 2 with test-registered components, in
  `test/port/theme/precedence_test.dart`. Its `main()` registers two dataset controllers with a
  point element, the scale `themeLinear` and the plugin `themeProbe`. Each chart comes from
  `acquireChart` of [Chart.js ADR 0022](adr/0022-chart-test-harness.md).
- Test 1 there: a chart without an effective theme resolves the upstream options and gets the
  upstream scope lists. A theme puts its scopes in the positions of section 3.2.
- Test 2 there: one row for each level of section 3.2, for elements, scales, plugins and the chart
  level. User colors beat the theme. The theme base color gives the derived hover color.
- `tool/reference/theme_precedence_reference.mjs` writes the expected values. It runs each chart
  with the upstream `core.config.js` and with a JavaScript prototype of the hunks H0-H3.

**Phase 6 state.** These parts exist, in addition to the parts of phase 5:
- `compile.dart` emits the `scales.radialLinear` keys of §4. The token `colors.color` emits
  `scales.radialLinear.pointLabels.color`. The token `colors.borderColor` emits
  `scales.radialLinear.angleLines.color`. The typography token `pointLabels` emits
  `scales.radialLinear.pointLabels.font`: the `typography.font` Map without `size`, then the fields
  of `typography.pointLabels` (§3.4). Without a `pointLabels` size, hunk H1 merges the theme font
  into the scale copy-in first. Then `mergeIf` adds the size 10 of `defaults.scales.radialLinear`.
  `scales.radialLinear.ticks.color` needs no key: H1 fills it from `scale.ticks.color` first. The
  theme key `scale.grid.color` does not reach `angleLines.color`, because the copy-in always has
  `angleLines.color`.
- `ChartThemes.light` also holds `typography.pointLabels` with the size 10
  (`scale.radialLinear.js:383-385`).
- `precedence_test.dart` also registers the category, linear and radial linear scales, the
  controllers `themeReal` and `themeReal2`, and the radial test controller `themeRadial`. Test 2
  has the H1 tables of the category and linear scales. It also has the H1 tables of four keys of
  the radial linear scale: the point-label color, the angle-line color, the point-label font and
  the tick color. The
  group `a compiled theme on a radial chart` compares a radial chart with a compiled theme with the
  prototype. It also compares the chart with an upstream chart without a theme that has the values
  that the tokens replace in `defaults` (§4). The group `the singleton read at
  scale.radialLinear.js:14` pins the read of §9. The group `test 5: a theme scale type creates no
  axis` has the part of test 5 without the controllers of phase 7.
- Test 3, the radial case: `light_reference.dart` has the restated `scales.radialLinear` keys and
  `themeLightRadial`. `presets_radial_test.dart` compares them on the VM only, because the scales
  are not pure layers. `presets_test.dart` keeps the other cases on the VM, dart2js and dart2wasm.
- Test 4: `coverage_test.dart` compares the committed `light_snapshot.json` with
  `defaults.values.defaults` of `doc/upstream/manifest.json` and with a `notThemed` list of 32
  keys, each with a reason. It reports ADDED, REMOVED and CHANGED, and two more lists: STALE (a
  `notThemed` key that upstream removed or that the preset emits) and DOLLAR (a `$` key in the
  inventory). `THEME_SNAPSHOT_UPDATE=1` writes the snapshot again. The test reads only the
  defaults. Thus a color in `overrides` stays a risk of §11 until a SHADOWED check exists.

**Phase 7 state.** These parts exist, in addition to the parts of phase 6 ([Chart.js ADR
0030](adr/0030-controller-test-strategy.md), sections 8-11):
- Test 3 for the 8 chart types: each controller test file
  `test/port/controllers/controller.<name>_test.dart` has the group
  `theming.md §8 test 3: the light preset`. It runs the reference cases of its generator with
  `compileChartTheme(ChartThemes.light)`. `testControllerChartCases` compares `defaults` after
  each themed case. The 6 files of charts with scales also have the test
  `the light preset leaves no stale scale key`. A doughnut or a pie chart has no scale, so that
  check has no path to examine there.
- Test 5 on the real bar and doughnut controllers: the group
  `test 5: a theme scale type creates no axis` of `precedence_test.dart` has 6 more cases. A bar
  chart keeps the scale ids `x,y`, and a doughnut chart has no scale, with and without a theme
  scale key.
- The group `hover` of `precedence_test.dart`: for the 8 chart types, the steps of
  `triggerMouseEvent` with the compiled hover theme give the options of an upstream chart with the
  replaced values in `defaults`. The active bar background is `#B40000`
  (`core.defaults.js:62-64`). `tool/reference/theme_precedence_reference.mjs` registers the 8
  pinned controllers and writes 47 scenarios. It stops unless `third_party/Chart.js`,
  `third_party/kurkle-color` and `third_party/chartjs-test-utils` are at their commits of
  `tool/port_sources.yaml`, with no change in `src/`.
- The blue screen without plugins: `test/port/theme/blue_screen_test.dart` (VM only). A theme with
  each color token at `#2050c0` paints only that blue over a background of the same blue, for the
  8 chart types, with no tolerance. The committed known-leaks list is empty. A control chart
  without the theme paints other pixels, and the 8 themed charts leave `defaults` unchanged.

**Phase 8 state.** These parts exist, in addition to the parts of phase 7 ([Chart.js ADR
0042](adr/0042-theming.md)):
- The hunks H4a, H4b, H4c and H5 in `lib/src/plugins/plugin.colors.dart`, with the rows
  `theme-H4a` to `theme-H5`. H5 reads the palette from the theme map of the chart through
  `chartThemeOf`, the public H0 reader of `lib/src/core/core.config.dart`. The group `theme-H0`
  of `test/port/core/core.config_test.dart` pins `chartThemeOf`. The group `theme palette` of
  `test/port/plugins/plugin.colors_test.dart` pins the palette on bar, doughnut and polar area
  charts and the reset of H5.
- `compile.dart` emits the plugin keys of §3.3: the title and subtitle colors and fonts, the two
  legend fonts and the tooltip keys. The `palette` field `{colors, backgroundAlpha}` emits
  `plugins.colors.$borderColors` and `plugins.colors.$backgroundColors`. The guard has rule 2b
  (the paths of `themePluginBehaviorPaths`, also under `scales.<type>`) and rule 9 (a palette value that is not a List with
  at least one item). `compile_test.dart` has the emission tests of these keys and rules.
- `ChartThemes.light` also holds `colors.inverseSurface`, `colors.onInverseSurface` and the
  `palette`: the 7 colors of `BORDER_COLORS` at alpha 1 and `backgroundAlpha` 0.5
  (`plugin.colors.ts:14-25`).
- `test/flutter_test_config.dart` registers the seven plugins with the built-in components. It
  then sets `defaults.plugins.colors.enabled = false` before the snapshot of the restore, as
  `test/index.js:25-28` does. The spec `plugin.colors_test.dart` and the fixtures of
  `plugin.colors` run without a theme (invariant 1).
- Test 2: the group `palette` of `precedence_test.dart` has 8 rows. The palette beats the theme
  element colors. User colors disable the palette, and `forceOverride` writes over them. A theme
  without a palette keeps the upstream palette. Two interleaved charts keep their own palettes. A
  palette key in the user options, in `defaults` or in `overrides` has no effect. An empty or
  non-List theme palette keeps the upstream palette. The palette keys of `plugin.colors.dart`
  equal the keys of the compiler. A removed theme gives the upstream palette at the next
  colorize. `tool/reference/theme_precedence_reference.mjs` registers the seven pinned plugins,
  disables the colors plugin as `test/index.js:25-28` does, and writes 62 scenarios. In waves 1,
  2 and 3 the `theme:` lines of 9, 9 and 8 of the 47 scenarios of phase 7 got the new plugin and
  palette keys of the compiled themes. The other lines stayed byte-identical. In wave 4 the
  registered legend changed the layout values of 7 of the 47 scenarios, in the upstream run and in
  the prototype run.
- Test 3: the group `test 3: the light palette` of `precedence_test.dart` compares the 8 chart
  types with the colors plugin on, with the light preset and without a theme. The dataset colors,
  the element options in the modes `default` and `active` and the style setters of one draw are
  equal after the parse. `presets_plugins_test.dart` compares the 19 resolved keys of the title,
  subtitle, legend and tooltip plugins with `themeLightPlugins` of `light_reference.dart`. The
  title, tooltip title and tooltip footer fonts keep `bold`, and the subtitle font keeps
  `normal`. `tool/reference/theme_light_reference.mjs` registers five plugins. The reference
  tests of the seven plugins in `test/port/plugins/` run their cases again with the light
  preset, in the group `theming.md §8 test 3: the light preset`.
- Test 4: `coverage_test.dart` has 25 `notThemed` keys and 2 module constants
  (`plugins.colors.$borderColors` and `$backgroundColors`, `plugin.colors.ts:14-25`). A field of
  a manifest route leaf with a Map value (the tooltip fonts, `plugin.tooltip.js:1327-1331`) is a
  leaf with the route value of that field. The 10 "phase 8" entries of `notThemed` are gone
  (title 1, subtitle 1, tooltip 8).
- The decimation: `test/port/theme/decimation_theme_test.dart` (VM only). A theme leaves the
  decimated data and `_data` of `plugin.decimation.js:249-265` unchanged, for `min-max` and for
  `lttb`. Only `borderColor` and `backgroundColor` of the dataset differ (§3.7).
- The full blue screen: `test/port/theme/blue_screen_test.dart` (VM only). A theme with each
  color token and the palette at `#2050c0` paints only that blue over a background of the same
  blue, for the 8 chart types with the colors plugin on and off, with the title, the subtitle,
  the legend title and a visible tooltip, with no tolerance. The known-leaks list of the 8 chart
  types is empty. The pin case of a legend item without `fillStyle` and `strokeStyle` has the
  list `setFillStyle #666` and `setStrokeStyle #666` (`plugin.legend.js:286, 314, 319`). A blue
  theme without the palette and with the colors plugin on paints the upstream palette (the rows
  `theme-H4b` and `theme-H4c`).
- The cost of the palette: [performance.md](performance.md) §14.5.

These parts wait:
- The blue screen with an active element waits for `IdentityChartHover` (§8 item 6).
- The layout keys of the plugin boxes and the fonts pass the guard. They move only the layout,
  as the font token does (Chart.js ADR 0042, Open item 1).
- Phase 9 decides the public palette type (Chart.js ADR 0042, Open item 3).

Chart.js ADR 0042 restates Chart.js ADR 0001 with the palette change of §3.5. The porting lead
accepted it after the adversarial review of phase 8, with all gates green (2026-10-23). It
supersedes Chart.js ADR 0001.

## 11. Risks, open questions and alternatives

Risks:

- For emitted keys, a theme beats app code that changes `Chart.defaults`.
- Chart-type overrides beat the theme. A future upstream color in `overrides[type]` hides the theme
  value. No test fails until a SHADOWED check exists.
- A theme switch discards imperative `chart.options` edits.
- A `'themeFrame'` update during an animation retargets that animation. The animation then ends on
  its own schedule (`core.animation.js:51-64`).
- Theme removal under reduced motion animates for 1000 ms, the default duration.
  [Chart.js ADR 0019](adr/0019-animation.md) §10 (proposed) leaves the reduced-motion policy to the
  phase 9 widget (section 3.7). porting-flow.md, decision 2.9, lists this item.
- It is possible that `$theme` and the palette keys collide with future upstream keys. The coverage
  test flags any `$` key in the inventory.

Open questions, to decide in phase 9:

1. Touch values (hit radius 8, hover radius 6, font 14), and whether touch changes `interaction`
   (proposed: no). A new ADR that supersedes Chart.js ADR 0042 decides them, together with ADR:
   Input events and interaction state. porting-flow.md, decision 2.7, must list this item.
2. `easing` as a string (proposed) or an enum
   ([Chart.js ADR 0043](adr/0043-options-representation-and-resolver.md)).
3. Does `frames` exist at all if its benchmark fails?
4. Typed component styles: generated option classes, or `raw` only (section 5.1)? ADR: Typed
   options API decides this question after 0.1.0.

Chart.js ADR 0042 closes two questions. The theme sits below `overrides[type]`, because chart-type
structure must win. #11910 stays a non-goal, as an upstream-tracking.md signal.

Alternatives considered:

| Option | Chosen | Reason |
|---|---|---|
| Theme in `Chart.defaults`, in the user options, or as a scope | a scope | Defaults are global. A changed default disables the palette. Tokens in the user's `options.scales` create axes on a doughnut |
| Datasets on a switch: copies or an in-place restore | in-place restore | A new dataset object loses its meta and legend visibility. It also replays the entry animation |
| A rendering run of every fixture under the light preset | dropped | Equal resolved options and the blue screen show the same result |
| Material mapping: a package or a snippet | a snippet | The two Material libraries have distinct `ColorScheme` types |
| forui adapter: forui 0.25 to 0.27 on 3.44, or forui 0.27 on 3.47 | forui 0.27 on 3.47 | One floor and one tested range |
