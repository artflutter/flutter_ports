# Chart.js ADR 0121: An on/off option holds a bool

- Status: accepted (2026-11-12): its code and the tests of section Tests pass.
- Date: 2026-11-12
- Supersedes: parts of [Chart.js ADR 0054](0054-typed-internal-model.md) §4 (a getter of a scale or plugin facade gives
  the raw JS value, for the 38 keys of section Decision).
- Related: Chart.js ADR [0116](0116-text-style-fonts.md) and [0119](0119-plain-intl-number-format.md) (typed option
  values). The row `adapt-bool-options`.

## Context

The getters of the scale and plugin facades gave `Object?`, because a raw Map config can hold any value. Each reader
then applied JS truthiness (`jsTruthy(opts.reverse)`). In Chart.js, the 38 keys below are declared `boolean` or
`Scriptable<boolean>` in `index.d.ts`, and the census of the upstream specs and fixtures holds only bools there, except
one fixture with `rtl: 'true'` (`plugin.legend/horizontal-rtl-hitbox.js`). The other non-bool values came from
port-only tests that tested JS truthiness.

## Decision

1. The facade getters of these keys give `bool` through `boolOption` of `helpers.config.dart`:
   - the scale options: `alignToPixels`, `reverse`, `clip`, `offset`, `beginAtZero`, `fullSize` and `animate`; the
     ticks `display`, `showLabelBackdrop`, `autoSkip`, `includeBounds` and `mirror`; the major ticks `enabled`; the grid
     `display`, `circular`, `drawOnChartArea`, `drawTicks` and `offset`; the border, the title and the angle lines
     `display`; the point labels `centerPointLabels`;
   - the plugin options: the title `display`; the legend `display`, `reverse` and `rtl`; the legend labels
     `useBorderRadius` and `usePointStyle`; the legend title `display`; the tooltip `displayColors`, `enabled`,
     `reverse`, `rtl` and `usePointStyle`; the filler `propagate`; the decimation `enabled`; the colors `enabled` and
     `forceOverride`.
2. An absent option (Dart `null` or `undefined`) gives `false`, as JS truthiness does. `includeBounds` gives `true`,
   because upstream compares it with `!== false` (scale.linearbase.js:266).
3. A value of another type stops a debug build. A release build takes the value of an absent option.
4. The readers test the bool with no JS rule. The legend item field `borderRadius: useBorderRadius && (…)`
   (plugin.legend.js:697) keeps the raw read of `useBorderRadius`, because that expression gives a value.
5. The hand port of `plugin.legend/horizontal-rtl-hitbox.js` writes `rtl: true`. The port-only cases with `'yes'`, `''`,
   `0`, `NaN` or an object at these keys are gone or give bools.

## Consequences

- 83 `jsTruthy` calls are gone from `lib/src`.
- A scriptable option of these keys returns a bool.
- The on/off keys of the chart, the dataset and the element options, and the keys whose schema shape is wider (the
  scale `display: boolean | 'auto'`), are outside this decision.

## Tests

- `test/port/core/scale_options_test.dart` and `test/port/core/scale_align_to_pixels_test.dart`: the typed getters, an
  absent key and a scriptable option.
- The scale, plugin and legend reference tests, the specs and the fixtures, also `plugin.legend/horizontal-rtl-hitbox`.
