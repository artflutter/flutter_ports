# forui theming

This page is part of the [prior-art survey](README.md). The overview asks if a native Chart.js port
exists. This page asks a different question: how does a Flutter design system theme its widgets?

Survey date: **2026-10-16**. Versions, dates and counts are as of that date.

**Question.** How does forui build, find, override and animate its theme? Which parts of that design
fit `flutter_chartjs`?

**Answer.** forui puts an `InheritedTheme` at the root of a subtree. It derives every widget style
from a small set of tokens, in one direction only. Generated code gives each style `copyWith`,
`lerp`, `==` and a delta type for local overrides. This architecture is a good model for a chart
theme.

forui 0.26 and later need Flutter >=3.47, Dart 3.13 and `material_ui`. forui 0.25.0 still runs on
Flutter 3.44. Thus the toolchain alone does not decide the question. The main reason is a proposed
rule: the library must not depend on any design system
([Chart.js ADR 0001](../adr/0001-theming.md)). Thus `flutter_chartjs` takes ideas only. It
maps them onto one extra Chart.js option scope, below user options and chart-type overrides and
above `defaults`.

**Sources.** We read the forui monorepo at tag `forui/0.27.6` (commit `e9cb058`, 2026-10-14). Git
does not hold the generated `*.design.dart` parts. For those parts, we read the 0.27.6 archive from
pub.dev. We also compiled small adapter variants with Flutter 3.44.9 and 3.47.7. Two more probes
tested syntax on Dart 3.12.2 and hash codes on forui 0.27.6 with Flutter 3.47.7.

Citations use the git form `<tag>:<path>:<line>`. The prefix `pub/0.27.6:` names a file in the
pub.dev archive. Chart.js citations use the tag `v4.5.1` of the submodule `third_party/Chart.js`.
Inside a paragraph, `:<line>` refers to the file of the previous citation.

## At a glance

| Item | Value |
|---|---|
| Package | `forui` 0.27.6: Flutter widgets for desktop and touch, design from shadcn/ui |
| Publisher and license | Duobase IO, MIT (`Copyright (c) 2026 Duobase IO`) |
| SDK floor | sdk `>=3.13.0-0`, flutter `>=3.47.0-0` (since 0.26.0) |
| Last line for Flutter 3.44 | 0.25.0 (2026-08-02) |
| Generated code | 78 `.design.dart` parts, 21,483 lines, gitignored |
| States | `FVariants`: platform, interaction and semantic tiers |
| Equality | deep `==`, XOR `hashCode`, unstable `FVariants.hashCode` |
| Churn | 797 `Breaking` lines in the CHANGELOG, 0.1.0 (2024-06) to 0.27.6 (2026-10) |

## What forui is

forui is a library of Flutter widgets for desktop and touch devices. Its visual design follows
shadcn/ui. Duobase IO publishes it on pub.dev under the MIT license. The monorepo also holds the
CLI `forui_cli`, the generator `forui_internal_gen` and icon packages. forui 0.27.6 imports
`material_ui` and `cupertino_ui`, not `package:flutter/material.dart`
(`forui/0.27.6:forui/lib/src/theme/theme_data.dart:5`).

## Theme root and lookup

`FTheme` is a `StatelessWidget` (`forui/0.27.6:forui/lib/src/theme/theme.dart:94`). It builds a
private `_AnimatedTheme` (an `ImplicitlyAnimatedWidget`, `:228`). On each animation frame,
`_AnimatedTheme` builds an `FBasicTheme` with the interpolated data. `FBasicTheme` stacks these
widgets, from the outside in (`:330-345`):

1. `FAccessibilityScope`
2. `FAdaptiveScope` (the runtime platform variant)
3. `_InheritedTheme` (a subclass of `InheritedTheme`)
4. `Directionality`
5. `DefaultTextStyle`

`_InheritedTheme.updateShouldNotify` compares the old and the new data with `!=` (`:370`).
`FTheme.of(context)` calls `dependOnInheritedWidgetOfExactType<_InheritedTheme>()`. Without an
ancestor theme, it returns `FTheme.neutral.light.touch` (`:139-140`). The getter `context.theme` is
a short form of `FTheme.of`.

`_InheritedTheme.wrap` lets `InheritedTheme.capture` carry the theme into overlays
(`forui/0.27.6:forui/lib/src/theme/theme.dart:358-371`). `FTheme.capture` also gives a pushed route
a `ValueListenable` of the theme (`:145`). Thus a dialog follows live theme changes.

## Tokens and the one-way derivation

`FThemeData` has a private constructor and a public factory
(`forui/0.27.6:forui/lib/src/theme/theme_data.dart:542`). The factory requires `FColors colors` and
`bool touch`. All other arguments are optional: typography, icons, `FStyle`, about 50 widget styles
and a list of extensions. The factory fills each absent argument from the tokens before it
(`:616-618`, `:653`). We show the steps with full type names. forui writes dot shorthands here.

- `typography ??= FTypography.inherit(colors: colors, touch: touch)`
- `icons ??= const FIcons.lucide()`
- `style ??= FStyle.inherit(colors: colors, typography: typography, touch: touch)`
- each widget style, for example
  `cardStyle ?? FCardStyle.inherit(colors: colors, typography: typography, style: style, touch: touch)`

`FColors` holds 15 colors in shadcn/ui pairs, for example `primary` and `primaryForeground`. Its
`hover(color)` method changes the HSL lightness. Its `disable(color)` method multiplies the opacity
(`forui/0.27.6:forui/lib/src/theme/colors.dart:280`, `:302`). `touch` selects desktop or touch sizes
at construction time. The theme data does not store it. `FSizes` holds reference values only: its
dartdoc says "Changing these values will not update the sizes of actual widgets"
(`forui/0.27.6:forui/lib/src/theme/sizes.dart:7`).

`FThemeData.copyWith` has no `colors`, `typography`, `style`, `icons` or `hapticFeedback`
parameters (`forui/0.27.6:forui/lib/src/theme/theme_data.dart:1343`). It takes only deltas for
widget styles. To change a token, you call the factory again. Then the new token flows into every
widget style. Since 0.24.0, the only preset is `FTheme.neutral`.

## Widget styles and generated code

A maintainer writes each widget style by hand as an immutable class with an `inherit(...)` factory.
The factory holds the default values, widget sizes included
(`forui/0.27.6:forui/lib/src/widgets/button/button.dart:509-520`).

The generator `forui_internal_gen` is a `build_runner` builder on `source_gen`. It finds style
classes by name, with the patterns `^F(?!Inherited).*(Style|Styles)$` and `^F.*(Motion)$`
(`forui/0.27.6:forui_internal_gen/lib/src/design_generator.dart:12-13`). For each class, it writes
five pieces into a `part` file. A delta is a value that applies changes to a base style. The table
uses `FCardStyle` as the example (`pub/0.27.6:lib/src/widgets/card.design.dart`).

| Generated piece | Content |
|---|---|
| `$FCardStyleTransformations` | extension with `copyWith(deltas)` and `lerp` (not virtual) |
| `_$FCardStyleFunctions` | mixin with `==`, an XOR `hashCode`, `debugFillProperties` and `call(Object _) => this` |
| `FCardStyleDelta` | abstract class with the factories `.delta(...)` and `.context()` |
| `_FCardStyleDelta` | delta that applies field deltas to a base style |
| `_FCardStyleContext` | delta that returns its input unchanged |

The `call` member makes each style its own delta. In `copyWith`, a nested style takes its delta
type. `TextStyle`, `Decoration` and `EdgeInsets` fields take hand-written deltas. A nullable field
takes a sentinel default or a `T? Function()?` wrapper. The sentinels let `null` mean "set to null"
instead of "no change". In `lerp`, values without an interpolation, for example `Duration` and
`Curve`, switch at `t = 0.5`.

Git does not hold the output (`forui/0.27.6:forui/.gitignore:38-40`). CI runs `build_runner` in
every job. At publish time, `forui/.pubignore` replaces `.gitignore`. Thus the pub archive holds
the 78 parts.

The generated code uses `const new(...)`. The library code uses `const new(...)` and primary
constructors (`forui/0.27.6:forui/lib/src/theme/theme.dart:193`, `:283`). Dart 3.12.2 rejects both
forms (see [Toolchain floors](#toolchain-floors)). The code also uses dot shorthands. Dart 3.12
accepts dot shorthands. By convention, the samples in this repository do not use them.

## Widget-local overrides

The `style` parameter of a widget has the delta type. `FCard.style` is an `FCardStyleDelta` with the
default `const FCardStyleDelta.context()`
(`forui/0.27.6:forui/lib/src/widgets/card.dart:47`, `:76`). In `build()`, the widget calls
`this.style(context.theme.cardStyle)` (`:85`). The theme style is the base. The delta applies on
top of it.

A full `FCardStyle` is also a delta that returns itself. Thus a full style replaces the theme style.
forui has no inherited override scope for one widget type, apart from groups such as
`FTooltipGroup`. To change all cards in a subtree, you put a nested `FTheme` above the subtree.
That theme gets its data from `copyWith`.

## Variants and the tier resolution

In 0.18.0, `FVariants<K, E, V, D>` replaced `FWidgetStateMap`. An `FVariants` holds a `base` value
and a map from constraints to values. A constraint is a variant, an AND of two constraints, or a NOT
of a variant. forui has no OR operator. A list of keys expresses OR.

Each variant declares a tier in its `@Variants` annotation. The generator converts the annotations
into extension types. By convention, the tiers are 0 for platform, 1 for interaction and 2 for
semantic (`forui/0.27.6:forui/lib/src/theme/variant_platform.dart:44`,
`forui/0.27.6:forui/lib/src/theme/variant.dart:9-17`). The interaction variants are `hovered`,
`pressed`, `focused` and `dragged`. The semantic variants are `disabled`, `selected` and `error`.

Widget variants use the same tiers. `FButton` sizes are tier 1. Its styles, for example `primary`
and `destructive`, are tier 2 (`forui/0.27.6:forui/lib/src/widgets/button/button.dart:12-24`).

`resolve(variants)` returns the value of the most specific constraint that the current set
satisfies. If no constraint matches, it returns `base`
(`forui/0.27.6:forui/lib/src/theme/variants.dart:173-190`). `FVariantConstraint.max` decides the
specificity. It supports five tiers (`forui/0.27.6:forui/lib/src/theme/variant.dart:56-83`):

1. Compare the operand count in each tier, from the highest tier down.
2. If all tiers are equal, compare the total operand count.
3. If the totals are equal, compare the sorted operand names.

Thus one semantic operand wins over any number of interaction operands.

`FAdaptiveScope` reads `kIsWeb` first and `defaultTargetPlatform` second
(`forui/0.27.6:forui/lib/src/theme/adaptive_scope.dart:24-38`). The shorthands `touch` and
`desktop` group the native platforms. `web` is a separate variant that is neither touch nor desktop
(`forui/0.27.6:forui/lib/src/theme/variant_platform.dart:76-79`). Thus an entry for `touch` never
applies in a phone browser. For the same reason, `context.platformVariant.touch` is false in a
phone browser (`:85`).

`FTappable` sets `pressed` from a raw `Listener`, not from a `GestureDetector`. A source comment
says that this choice keeps the press detection outside the gesture arena
(`forui/0.27.6:forui/lib/src/foundation/tappable/tappable.dart:764-770`). The proposed ADR: Input
events and interaction state takes the same position for charts. The chart enters the gesture arena
only with one `TapGestureRecognizer` for `click` ([porting-flow.md §2.7](../porting-flow.md)).

The Styling 2.0 design doc rejects a fluent API like Mix, a generic `Delta<S>` mixin, single-tier
specificity, OR operators and responsive variants
(`forui/0.27.6:design_docs/shipped/styling_2.0.md:235-247`, `:391-397`, `:645-648`). The doc is
rationale, not an API reference. For example, it names the identity delta `.inherit()`. The shipped
name is `.context()`.

## Lerp and animated themes

`FThemeData.lerp` interpolates each token and each widget style
(`forui/0.27.6:forui/lib/src/theme/theme_data.dart:750`). `FColors.lerpColor` converts both colors to
Display P3 when their color spaces differ (`forui/0.27.6:forui/lib/src/theme/colors.dart:188-195`).
`FVariants.lerpWhereUsing` interpolates only the keys that both sides hold
(`forui/0.27.6:forui/lib/src/theme/variants.dart:88-118`). Icons and other values without an
interpolation switch at `t = 0.5`.

`FThemeMotion` has a default of 200 ms with `Curves.linear`
(`forui/0.27.6:forui/lib/src/theme/theme.dart:283-291`). `_AnimatedTheme` starts an animation each
time the new data is `!=` the old data. Thus two themes from the same inputs must be equal.
Otherwise each rebuild starts a new animation.

The forui docs give two rules for this
(`forui/0.27.6:docs/content/docs/concepts/themes.mdx:231-238`). Theme code uses static functions,
not closure literals. Icon classes implement `==` and `hashCode`.

## Extensions and Material interop

`FThemeData`, `FColors` and `FStyle` accept `ThemeExtension`s, in a map with the `Type` as the key.
`extension<T>()` throws if the theme has no extension of type `T`
(`forui/0.27.6:forui/lib/src/theme/theme_data.dart:948`). forui has no `maybeExtension`.

The `ThemeExtension` type changed between forui lines. forui 0.25.0 imports it from
`package:flutter/material.dart`. forui 0.26.0 and later import it from `package:material_ui`
(`forui/0.27.6:forui/CHANGELOG.md:193-194`, `:260-261`). `material_ui` 1.7.0 declares its own
class (`lib/src/theme_data.dart:145`). Flutter 3.47.7 still declares a separate class in
`packages/flutter/lib/src/material/theme_data.dart:131`.

We passed a `material_ui` extension to forui 0.25.0 and a `flutter/material.dart` extension to
forui 0.27.6. Both builds failed with `list_element_type_not_assignable`. Thus an extension for one
forui line does not compile against the other line.

Material interop goes in one direction. `toApproximateMaterialTheme()` returns a `material_ui`
`ThemeData` (`forui/0.27.6:forui/lib/src/theme/theme_data.dart:981`). The CLI snippet
`material-theme` writes the same mapping into the app. forui widgets are not fully independent of
Material. `FTextField` wraps a `material_ui` `TextField` in a `Theme`
(`forui/0.27.6:forui/lib/src/widgets/text_field/input/input.dart:335-345`). `FTabs` builds a
`material_ui` `TabBar` (`forui/0.27.6:forui/lib/src/widgets/tabs/tabs.dart:190-197`).

## The generator and the CLI

Other projects cannot use `forui_internal_gen`. Its pubspec sets `publish_to: 'none'` and version
`0.0.0` (`forui/0.27.6:forui_internal_gen/pubspec.yaml:3-4`). It requires Dart `>=3.13.0-0` and
Flutter `>=3.47.0-0`. Its type checkers refer to `package:forui/src/...`. Its output calls forui
types.

No other generator that we examined fits `flutter_chartjs`. theme_tailor generates code for Material
`ThemeExtension` classes. Its `@TailorMixin` example extends `ThemeExtension<T>` from
`package:flutter/material.dart` (theme_tailor 4.0.1 `README.md:65`, `:112-118`). The library must
not import that file. Also, theme_tailor 4.x needs Dart >=3.13. The last release that runs on
Dart 3.12 is theme_tailor 3.1.3 (sdk `>=3.9.0`).

freezed 4 needs Dart >=3.13. freezed and dart_mappable 4.10.0 (sdk `>=3.7.0`) have no `lerp`.

`forui_cli` follows the shadcn/ui copy model. It copies editable code into the project of the user.
The commands are `init`, `theme create`, `style create|ls` and `snippet create|ls`. `theme create`
takes a six-character `--preset` code or starts a wizard. It writes a theme library with colors,
typography, style and icons.

A tool, `forui_cli/tool/main.dart`, reads forui with the analyzer. It rewrites the source text of
each `F*Style(s).inherit` factory as a top-level function. It stores the results as string literals
in committed catalogs: 88 styles, the `neutral` theme and the snippets. A presubmit job runs the
tool again. A bot then commits the diff.

The rewrite catches only explicit `F<Name>Style.inherit` calls. 58 dot-shorthand `.inherit(...)`
calls stay as calls into forui. Thus the copied code is not self-contained. The CLI also has no
merge or upgrade path. When forui changes an `inherit` signature, the copied code breaks, as with
the new required `icons` parameters in 0.22.0.

The Untime retrospective is an internal review of an app on forui
(`forui/0.27.6:design_docs/shipped/untime_retrospective.md:20-44`). It says that LLMs edit the
CLI output well. It also says that deltas "sometimes confuse even us, the maintainers". It calls
`FVariants` "still too verbose" for tappable variants.

## Churn

The CHANGELOG has 797 lines with `Breaking` in about 28 months. The type of the widget `style`
parameter changed twice:

| Versions | `style` parameter type |
|---|---|
| up to 0.12 | a style object |
| 0.13.0 (2025-07) | `FXxxStyle Function(FXxxStyle)` |
| 0.18.0 (2026-02) | `FXxxStyleDelta` |

The state model changed three times: `FVariants` in 0.18, extension-type wrappers in 0.19, and
`touch` in place of `desktop` in 0.20. forui removed its presets in 0.24. In 0.22.0, it added many
required style fields. The 0.18.0 notes say that data-driven fixes "are not available for most of
these changes" (`forui/0.27.6:forui/CHANGELOG.md:2033-2034`).

## Testing

forui renders its widget goldens with the neutral light and neutral dark themes. A "blue screen"
test in 58 test files shows that a widget takes all its colors from the theme. The test theme sets
each color to `0xFF03A9F4` and removes the shadows
(`forui/0.27.6:forui/test/src/test_scaffold.dart:45-70`). Each such test compares the render with
the shared `blue-screen.png` for its OS (`:14`).

There are 3,777 golden PNGs: 2,034 for macOS and 1,743 for Windows. CI does not run them now. The
workflows say "Auto-triggers disabled while goldens are paused in CI (see flutter/flutter#184182)".
No test covers `copyWith` or `lerp` for each style.

## Toolchain floors

| Package | sdk | flutter |
|---|---|---|
| forui 0.25.0 | `>=3.12.0-0` | `>=3.44.0-0` |
| forui 0.26.0 to 0.27.6, `forui_cli` 0.27.0, `forui_internal_gen` | `>=3.13.0-0` | `>=3.47.0-0` |
| `material_ui` 1.0.0 to 1.3.0 | `^3.12.0` | `>=3.44.0` |
| `material_ui` 1.4.0 and later | `^3.13.0` | `>=3.47.0` |
| `flutter_chartjs` | `^3.12.0` | `>=3.44.0` |

This repository pins Flutter 3.44.9 (Dart 3.12.2). The Flutter 3.47 line became stable on
2026-08-12. Its latest patch, 3.47.7, shipped on 2026-10-08. From 0.15.0 to 0.27.6, forui raised
its floor only in the first minor release after each new Flutter stable line. For the last three
lines, that release came 3 to 12 days later: 0.18.0 for 3.41, 0.22.0 for 3.44 and 0.26.0 for 3.47.

On Dart 3.12.2, the analyzer rejects primary constructors and `const new(...)`. The diagnostics are
`experiment_not_enabled` and `experiment_not_enabled_off_by_default`, for the feature
`primary-constructors`. Dot shorthands compile on Dart 3.12.2. They need language version 3.10
(Flutter 3.38).

In our tests on 3.44.9, one workspace member with a 3.47 floor made `pub get` fail for the whole
workspace. On 3.47.7, each member keeps its own language version. But a 3.12 member can then call
a Flutter API from 3.47 without a diagnostic. An adapter that does not subclass `ThemeExtension`
worked on both lines. With `forui: ">=0.25.0 <0.28.0"`, it resolved 0.25.0 on 3.44.9. On 3.47.7, it
resolved 0.27.6 only after `flutter pub upgrade forui`, because pub keeps the locked version.

## Licensing

`forui`, `forui_cli` and `forui_internal_gen` are MIT, `Copyright (c) 2026 Duobase IO`. Up to
0.16.0, the holder was "Forus Labs Pte Ltd". `forui/LICENSE` also includes the Inter font under
OFL-1.1. `forui_lucide` adds ISC (Lucide) and MIT (Feather). Ideas are free to use. Copied code
needs the three items from [AGENTS.md](../../../../AGENTS.md#licensing):

1. the line `Copyright (c) 2026 Duobase IO` in the LICENSE of the package that receives the code
2. a `REUSE.toml` annotation for the path of that package, placed last, with every holder
3. the file header from rule 2, for example
   `// Ported from forui 0.27.6 forui/lib/src/theme/colors.dart (MIT, Duobase IO).`

The package that receives the code is `packages/flutter_chartjs` or the forui adapter. Today,
AGENTS.md names only `packages/flutter_chartjs/LICENSE`. [porting-flow.md §6](../porting-flow.md)
proposes the general rule: the LICENSE of the package that contains the code. A new adapter package
also needs an entry in the Layout section of AGENTS.md and a scope in `commitlint.yaml`.

Do not copy the Inter font or the Lucide assets. They bring OFL-1.1 and ISC terms. Only copied code
raises the Forus Labs question. It is possible that code from before 0.17.0 needs the Forus Labs
notice too. That case needs a licensing decision.

## Known defects not to copy

- **`copyWith` drops custom icons.** `FThemeData.copyWith` calls the factory without `icons:`
  (`forui/0.27.6:forui/lib/src/theme/theme_data.dart:1411-1418`). The factory default
  `const FIcons.lucide()` then replaces a custom set (`:617`). Widgets that read
  `context.theme.icons` at build time, for example `FAlert`, show Lucide icons again
  (`forui/0.27.6:forui/lib/src/widgets/alert.dart:111`).
- **`FVariants.hashCode` is not stable.** It hashes `variants.entries`
  (`forui/0.27.6:forui/lib/src/theme/variants.dart:253`). Each call creates new `MapEntry` objects
  with identity hashes. `FThemeData.hashCode` is an XOR over all fields, the `FVariants` style
  fields included (`pub/0.27.6:lib/src/theme/theme_data.design.dart:200-216`,
  `forui/0.27.6:forui/lib/src/widgets/alert.dart:164`). Thus two calls on one theme, or two equal
  themes, give different hash codes. `==` still works, because `mapEquals` compares values by
  constraint key. We tested this on 0.27.6 with Flutter 3.47.7.
- **`And.hashCode` depends on the operand order.** `And.==` is symmetric. But `hashCode` is
  `Object.hash(_left, _right)` (`forui/0.27.6:forui/lib/src/theme/variant.dart:144-152`).
  `FVariants.==`, `exact` and `remove` find these keys by hash
  (`forui/0.27.6:forui/lib/src/theme/variants.dart:244-250`, `:308-311`, `:378-381`). Thus an
  `exact` operation for `hovered.and(focused)` does not update an entry for `focused.and(hovered)`.
  It adds a second key with the same logic.
- **The tiebreak compares joined strings.** `max` sorts the operand names and joins them with no
  separator (`forui/0.27.6:forui/lib/src/theme/variant.dart:78-82`). The design doc compares the
  sorted lists (`forui/0.27.6:design_docs/shipped/styling_2.0.md:339-341`, `:359-368`). For
  `['a', 'z']` and `['ab', 'b']`, a list comparison picks the first list. The joined strings `'az'`
  and `'abb'` pick the second list.
- **The generated `hashCode` is an XOR.** Two fields that swap equal values give the same hash.
  Flutter's own theme classes use `Object.hash`.

## What it means for flutter_chartjs

The theme design is in [Chart.js ADR 0001](../adr/0001-theming.md) (proposed) and in
[packages/flutter_chartjs/doc/theming.md](../theming.md). This section lists the forui ideas that the
design takes or rejects, with the reason for each. The per-module porting rules, the `DIVERGES`
marker and the library import guard are in [porting-flow.md](../porting-flow.md).
[upstream-tracking.md](../upstream-tracking.md) tells how upstream changes to defaults reach
the theme, through the `theme-review` action.

**Ideas we take**

- **Our own theme root.** `ChartTheme` is an `InheritedTheme` subclass with `wrap` and an
  `of(context)` lookup. Without a `ChartTheme` ancestor, the chart adds no theme scope. Then
  `ChartTheme.of` returns `ChartThemes.light`. That preset holds the v4.5.1 values: `'#666'`,
  `'rgba(0,0,0,0.1)'` and a font with family `"'Helvetica Neue', 'Helvetica', 'Arial', sans-serif"`,
  size 12, style `'normal'`, line height 1.2 and weight `null`
  (`v4.5.1:src/core/core.defaults.js:41-60`). Why: a chart without a theme renders like upstream.
  The ported specs keep their values.
- **A one-way derivation from a few tokens.** Chart.js already has a token layer. `Defaults.color`,
  `backgroundColor` and `borderColor` reach elements, scales and plugins through routes
  (`v4.5.1:src/core/core.defaults.js:41-43`, `:130`, `v4.5.1:src/core/core.scale.defaults.js:86-89`).
  For fonts, only the tooltip routes its font slots to `font`
  (`v4.5.1:src/plugins/plugin.tooltip.js:1327-1331`). `toFont` fills the other font slots from
  `defaults.font` (`v4.5.1:src/helpers/helpers.options.ts:115-117`). In the chart theme, one plain
  function derives every emitted key from the `ChartColors` and `ChartTypography` tokens
  ([theming.md §4](../theming.md)). Typed component styles wait for the typed options API.
  Why: a token change reaches every key, as in forui.
- **One extra option scope.** The theme compiles to a map with the key shape of `Chart.defaults`.
  The ported resolver reads that map as an extra scope between `overrides[type]` and `defaults`,
  also in the scale merge (`v4.5.1:src/core/core.config.js:311-313`, `:331-339`, `:106-110`). The
  global `defaults` stay as in upstream. Why: the ported resolver stays the single source of option
  semantics. The cost is eight marked `DIVERGES(chartjs)` hunks in two ported files. The review of
  each upstream bump includes these hunks ([theming.md §3.1, §9](../theming.md)).
- **Value equality.** Every theme class implements `==` and `hashCode`. `hashCode` uses
  `Object.hash` over field values and map keys and values, never an XOR or `MapEntry` objects. A
  test asserts equal hash codes for equal objects and for two calls on one object. Theme values use
  static functions, not closure literals. Why: each `!=` notification of the inherited theme costs
  a `chart.update()`. That call clears the cached option scopes
  (`v4.5.1:src/core/core.config.js:197-206`, `v4.5.1:src/core/core.controller.js:478`).
- **A `copyWith` that carries every token, with a test.** Why: the forui icon defect shows the risk.
- **Plain derivation code and docs on the concrete class.** Why: the Untime retrospective found
  that the maintainers and LLMs work better with plain code than with delta types.
- **`lerp` on the theme classes.** `ChartThemeData` has a `lerp`. An animated theme widget is a
  later, opt-in item ([theming.md §5.1, §5.2](../theming.md)). Why: apps can get the forui
  model of an animated theme when they need it.
- **The blue-screen test.** A test theme sets every token and the palette to one color. Every chart
  type, with titles, a legend title and a visible tooltip, must then render only that color. The
  test compares the pixels without a golden file. A committed list of known upstream leaks gives the
  only exceptions ([theming.md §8](../theming.md)). Why: the test proves that no chart color
  bypasses the theme.
- **Optional adapters outside the library.** Later, a forui adapter package maps `FColors` and
  `FTypography` onto the chart theme, after the model of `toApproximateMaterialTheme()`. Material
  gets a documented snippet that CI compiles, not a package. The reason is that
  `flutter/material.dart` and `material_ui` declare distinct types
  ([theming.md §5.2, §5.3](../theming.md)). Why: the library stays free of both design
  systems. Only the adapter follows forui releases.

**Things we do not take**

- **forui, `material_ui` or Material as a dependency of the library.** The library keeps sdk
  `^3.12.0` and flutter `>=3.44.0`. Its only Flutter imports are `package:flutter/widgets.dart` and
  the lower layers. Under Chart.js ADR 0001 (proposed), AGENTS.md rule 5 gets the list of
  forbidden imports ([porting-flow.md §6](../porting-flow.md)). The import guard (porting-flow.md tool 1)
  enforces the list. Why: the library must not depend on a design system. The Flutter 3.47 pin that
  forui 0.26 needs is a separate change (ADR: Toolchain pin and library floor).
- **`ThemeExtension` as the slot for the chart theme, also in adapters.** Why: the two
  `ThemeExtension` types do not mix. Our test adapter without `ThemeExtension` worked on both forui
  lines.
- **Generated deltas for every option, and `forui_internal_gen`.** Chart.js options are already
  partial values over defaults, with merge and scope precedence. Why: a delta adds nothing to that.
  The generator is unpublished, tied to forui and needs Dart 3.13. ADR: Options representation and
  resolver puts the typed options API after 0.1.0. ADR: Typed options API then decides it
  ([porting-flow.md §2.1](../porting-flow.md)).
- **`FVariants` as a general state system.** Upstream renders two states, default and active,
  through the `hover` option prefixes. The ported dataset controller keeps that resolution. Why:
  more states diverge from upstream ([theming.md §6](../theming.md)).
- **The platform as the source of hover or touch sizes.** forui's `web` variant is never touch or
  desktop. Thus a platform rule fails in a phone browser. An adapter that passes
  `context.platformVariant.touch` to the chart theme gives desktop sizes in a phone browser. We
  recommend the pointer kind as the source of hover and touch sizes (ADR: Input events and
  interaction state). We also recommend an explicit `touch` argument on the forui adapter.
- **`lerp` on Chart.js option maps, or a typed mirror of the options.** Why: `core.animation.js`
  already interpolates resolved values. By default, a theme change updates the chart once. Chart.js
  then animates the element colors through `transitions.theme`
  ([theming.md §3.8](../theming.md)).
- **A CLI that copies theme code into apps.** Why: copied code has no upgrade path. Presets and a
  documented theme API cover the same need ([theming.md §5.1](../theming.md)).
- **Verbatim copies of forui code.** Why: the code uses primary constructors and `const new`, two
  Dart 3.13 features. Copied code also needs the three licensing items above. The HSL formula of
  `FColors.hover` and its default factors 0.075 and 0.05 are code, not an idea
  (`forui/0.27.6:forui/lib/src/theme/colors.dart:118`, `:126`, `:280-299`). A chart hover with that
  formula must call `FColors.hover` at run time in the forui adapter. Otherwise, it is a port and
  needs the three items.
- **Variant logic.** The chart theme has no variants. If a later ADR adds states, the logic must use
  AND and NOT only. Ties must use an element-wise comparison. The hash must not depend on the
  operand order. Why: these rules avoid the forui defects above.
- **The churn pattern.** Chart.js ADR 0001 settles the theme and override model once, in phase 5
  before the hunks H0-H3 land (Core: `core.config` and option resolution) of the revised plan in
  [porting-flow.md §5](../porting-flow.md). Theme classes stay internal until phase 9. Why:
  forui changed its `style` parameter type twice in 28 months.

**Constraints from upstream.** The colors plugin disables itself when the singleton
`defaults.borderColor` or `defaults.backgroundColor` differs from `'rgba(0,0,0,0.1)'`
(`v4.5.1:src/plugins/plugin.colors.ts:90-92`). It also disables itself when the chart config sets
dataset, chart-level or `elements` colors (`:107-117`). `forceOverride` cancels both checks
(`:119-121`). Thus a theme that writes `Chart.defaults` stops the palette.

The chart theme never writes the singleton. It adds an option scope instead. Thus the palette stays
active. Four `DIVERGES(chartjs)` hunks in the port of `plugin.colors.ts` let the theme supply the
palette ([theming.md §3.5](../theming.md)).

**Port-only code.** The theme layer is port-only code, that is, code with no upstream source. Its
files start with `// Original code, not ported from Chart.js: <reason>.` Each of the eight theme
hunks in ported files carries `// DIVERGES(chartjs): <row id>, <reason>`. Each hunk also gets a row
in the proposed `packages/flutter_chartjs/doc/differences.md`. [porting-flow.md §6](../porting-flow.md)
proposes both conventions for AGENTS.md rule 2.

**The forui adapter.** Only the adapter follows forui releases. forui minor releases often break
APIs (see [Churn](#churn)). Some of them also raise the Flutter floor (see
[Toolchain floors](#toolchain-floors)). Thus the adapter needs a release for each forui minor. Our
test adapter with `forui: ">=0.25.0 <0.28.0"` resolved on both toolchains. But
[theming.md §5.3](../theming.md) picks one floor and one tested range: `forui: ^0.27.0` on
Flutter 3.47, after 0.1.0.

[ADR 0003](../../../../docs/adr/0003-package-names.md) names `flutter_chartjs`, `chartjs_gallery` and the
`flutter_<library>` rule for later ports. It does not name adapter packages. Thus the adapter
package name needs an amendment to ADR 0003. The proposed name is `flutter_chartjs_forui`, with the
rule `flutter_chartjs_<design system>` for adapters.
