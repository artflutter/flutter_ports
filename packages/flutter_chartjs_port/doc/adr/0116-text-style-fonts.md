# Chart.js ADR 0116: The font is a Flutter TextStyle

- Status: accepted (2026-11-12): its code and the tests of section Tests pass.
- Date: 2026-11-12
- Supersedes: parts of [Chart.js ADR 0061](0061-native-flutter-colors.md) (the sentence "the framework-free
  core can import dart:ui, but cannot import package:flutter framework libraries", for `TextStyle`),
  [Chart.js ADR 0015](0015-text.md) (the CSS font shorthand that the canvas parses),
  [Chart.js ADR 0050](0050-public-theme-api.md) (a theme font lowers to the keys of a font object) and
  [Chart.js ADR 0052](0052-typed-public-api.md) (a typed font lowers through `fontScopeOf` to a `FontSpecScope`).
- Related: Chart.js ADR [0054](0054-typed-internal-model.md) (the typed internal model) and
  [0115](0115-hand-ports-of-typed-data-fixtures.md) (the hand ports of the data fixtures with a class value). The
  row `adapt-text-style-fonts`.

## Context

Chart.js holds a font as a plain object `{family, size, style, weight, lineHeight}`. `toFont`
(helpers.options.ts:115) merges each key with `defaults.font`, checks the style against a pattern, parses a size text
with `parseInt`, parses the line height (`'normal'`, a number, or a text with `px`, `em` or `%`) and builds the CSS
font text `toFontString` (helpers.canvas.ts:21). The draw code gives that text to the canvas: `ctx.font =
font.string`. A partial font object merges with the font objects of the other scopes: the resolver makes a
sub-resolver of the font objects, a `defaultRoutes` entry merges a font object with its target
(core.defaults.js:144-153), and the tooltip fonts route to `font` (plugin.tooltip.js:1326-1330).

Before this decision, the port kept the font as a typed scope of these keys (`FontSpecScope`), built the CSS text in
`toFont`, and the canvas parsed the CSS text again (`parseCanvasFont`). The theme and the typed API took a Flutter
`TextStyle` and lowered it to the keys first (`fontScopeOf`). Thus a `TextStyle` of an app became keys, then CSS text,
then a parsed font of the canvas. The maintainer rejects each such conversion: the core takes the native type and
uses it.

## Decision

1. A font is a Flutter `TextStyle` from the option to the canvas: the options `font`, `titleFont`, `bodyFont` and
   `footerFont` of each scope, `defaults.font`, the defaults of the plugins and the scales, the theme, the typed API,
   the canvas `font`, the font of a label item and the result of `toFont`. Also in a raw config. A font function
   returns a `TextStyle`.
2. The resolver merges the `TextStyle`s of a font option with `TextStyle.merge`. It gathers the scopes that upstream
   gathers for a font object (the scopes of the key, then the scopes of its `_fallback` key), and a field of a
   scope with higher priority wins. A `defaultRoutes` entry merges its `TextStyle` over the `TextStyle` of its target.
   `helpers.merge` and `mergeIf` merge two fonts, and a `raw` font of a theme merges over the token font.
   `toFont(font, [fallback])` merges `font` over `fallback`, or over `defaults.font`, and gives a `ChartTextStyle`.
3. The port-only class `ChartTextStyle` extends `TextStyle` with the field `lineHeight`, the height of one line in
   pixels. Its constructor computes the field once: `fontSize * height`, or Dart `null` when one of the two is
   `null`. `merge` and `copyWith` give a new `ChartTextStyle`, so the field follows the merged size and height. The
   layout reads `lineHeight` and `fontSize` with no other math. `TextStyle.height` is the `lineHeight` of a Chart.js
   font, a multiple of the size, and `defaults.font` has `height: 1.2`. A line height in pixels, in `em` or in
   percent has no form (the maintainer's decision). `toLineHeight` is gone.
4. The canvas lays out each text with the `TextStyle` of its `font`. The paint of the text is the fill or the stroke of
   the canvas, as in a DOM canvas. The default `font` of a new canvas state is
   `TextStyle(fontFamily: 'sans-serif', fontSize: 10)`, the `10px sans-serif` of the DOM.
5. Gone: `toFontString`, `toLineHeight`, `ParsedFont`, the style check of `toFont` and its console warning, the
   `parseInt` of a size text, the CSS parse of the canvas (`parseCanvasFont`, `CanvasFont`), the kind `FontSpec` of
   the option schema with `FontSpecScope`, `fontScopeOf` and `fontSpecOf` of `lib/src/theme/css.dart`, the parsed
   font template of `options/static_font.dart`, and the interfaces `FontSpec` and `CanvasFontSpec` of
   `lib/src/types/index.dart`.
6. A core layer imports `package:flutter/painting.dart` with `show` of `TextStyle` and `TextOverflow` (a parameter
   of `TextStyle.copyWith`) and no other name. A test file without `@TestOn('vm')` can import it in the same form.
   `check:lib-imports` fails on another name.
7. The upstream values with no `TextStyle` form: a line height of item 3, the style `'oblique'` with or without an
   angle (an app gives `FontStyle.italic`), the relative weights `'lighter'` and `'bolder'` (an app gives a
   `FontWeight`), the style keywords `'initial'`, `'inherit'` and `'unset'` (a null field), and a size as text. A
   family list is `fontFamily` and `fontFamilyFallback`. A generic family (`sans-serif`) stays a family name.

## Consequences

- An app and a plugin give a font in one form. The fields that the core reads for its layout are `fontSize` and
  `height`. The canvas layout reads the whole `TextStyle`, so a `letterSpacing` of an app also changes the measured
  width.
- A text cache compares two fonts with `TextStyle.==`. The static tick font cache also compares the global font,
  because `toFont` merges the tick font over it.
- The canvas gives the `FontWeight` of a style to the engine with no change. For a weight from 501 to 549, the engine
  gives the bold face of the test font, as the CSS rule of `@font-face` fonts does. Chrome with system fonts gives
  the regular face there. The CSS parse gave the nearest of the nine weights before.
- The draw-call compares with upstream data compare the family, the fallback families, the size, the weight and the
  style of each font record. The generators read these values from the upstream CSS text
  (`tool/reference/font_record.mjs`), and they write a font object of a config as a `ChartTextStyle` literal.

## Tests

- `test/port/helpers/helpers.config_test.dart` and `test/port/core/core.defaults_test.dart`, groups
  `adapt-text-style-fonts`: the merge of item 2, also through the `_fallback` key and a route.
  `test/port/theme/compile_test.dart`: the merge of a `raw` font.
- `test/specs/helpers.options_test.dart` and `test/port/helpers/helpers.options_test.dart`: `toFont` and the field
  `lineHeight` of item 3. The upstream cases of a text form skip with `'diverges: adapt-text-style-fonts'`.
- `test/port/canvas/canvas_ui_text_test.dart`: the layout of item 4.
- `test/tool/check_lib_imports_test.dart`, the case of the painting library, and the run of `check:lib-imports`:
  item 6.
- The reference tests of the scales, the controllers and the plugins: the font records of the draw calls.
