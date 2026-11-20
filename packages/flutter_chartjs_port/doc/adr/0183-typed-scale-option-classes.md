# Chart.js ADR 0183: Typed scale option classes

- Status: accepted (2026-11-20): the scale option classes are on main, and the tests and the port checks of the change pass.
- Date: 2026-11-20
- Supersedes: of [Chart.js ADR 0054](0054-typed-internal-model.md) §4, the item on the facades of the scale options
- Related: [Chart.js ADR 0182](0182-resolved-plugin-option-classes.md), [Chart.js ADR 0121](0121-bool-options.md), [Chart.js ADR 0111](0111-range-updates.md)

## Context

`Scale.options` was an extension type over the resolver view of the scale (`CoreScaleOptions` and six
more facades). The facade implemented `OptionView`, so an app read and wrote any key by name. Of its
getters, 70 gave the raw JS value as `Object?`, and each reader applied a JS operator to it. The
maintainer asked for a typed scale options API, as the plugin options of Chart.js ADR 0182 have
(2026-11-20).

The scale options differ from the plugin options. Upstream resolves the grid, tick, angle line and
point label options again for each tick context, and the specs write into the view between two reads
of one update.

## Decision

1. **Classes with typed getters.** Each facade is a class with a `const` constructor over the view:

   ```dart
   // Before
   extension type const CoreScaleOptions(OptionView _view) implements OptionView {
     Object? get weight => _view.readKey(OptionKey.weight);
   }
   // After
   base class const CoreScaleOptions(final OptionView view) implements LayoutBoxOptions {
     double? get weight => _number(view.readKey(OptionKey.weight));
   }
   ```

   A getter reads its key at each read and converts the value: a number is a `double?` (Dart `null`
   for an absent value, else `jsToNumber`), an on/off key a `bool`, a keyword an enum, a font a
   `TextStyle?`, a dash a `List<double>?`, `labels` a `List<Object?>?`, `stack` a `String?`.

2. **The view stays the cache.** No getter keeps a value. The view keeps the cache of upstream: a
   scriptable option runs at the read of upstream, and a write into the view shows at the next read.

3. **Raw values that stay.** `min`, `max`, `suggestedMin` and `suggestedMax` (the scale parses them),
   the 14 hooks, `ticks.callback` and `pointLabels.callback` (their function types take `Scale`, which
   the core library does not import), the colors that the canvas takes (`backgroundColor`,
   `grid.color`, `grid.tickColor`, `angleLines.color`, `pointLabels.backdropColor`),
   `pointLabels.borderRadius`, `time.parser`, `time.isoWeekday` and `adapters` give the raw value.
   `displayFormats` stays a wrapper of the live object: the time scale merges the formats of the
   adapter into it.

4. **One object for each view.** `Scale.options` makes the object of its view with `createOptions`,
   and keeps it while `init` gives no new view. Each scale class narrows the type:
   `LinearScale.options` is a `LinearScaleOptions`. `IScale.options` is a `CoreScaleOptions`.

5. **`optionsView`.** `Scale.optionsView` (also on `IScale`) gives the view. A write by name
   (`scale.optionsView['min'] = 5`), the internal plans of the scales and the controllers, and
   `setContext` of the scale options use it. A nested class has its view in `view`, and its
   `setContext(context)` gives the class of the context view.

6. **The layout.** The classes implement `LayoutBoxOptions`: `layoutOption` gives `fullSize`,
   `position`, `weight`, `stack` and `stackWeight`, and reads another key from the view.

7. **Row.** The markers use the new row `adapt-native-scale-options`.

## Rejected

- Resolved values with `of`, as Chart.js ADR 0182: a write into the view during an update does not
  show, and an eager read of each key for each tick calls scriptable options that upstream does not
  call.
- `late final` fields: a write into the view after the first read does not show.

## Consequences

- A string number option (`ticks.padding: '5'`) is a number at its read: `'8' + 0` gives 8, where
  upstream joins the strings.
- A JS `null` number or font option is an absent option: a time `stepSize: null` takes the step 1,
  where upstream throws, and a `null` tick font takes the default size of the radial backdrop.
- An app reads and writes by name only through `optionsView`.
- The readers keep the results of upstream `undefined` for an absent number: `sampleSize`,
  `maxTicksLimit`, `grid.z` and the time `stepSize` test Dart `null`, and a reader that gives the
  number to a JS operator reads it through `scaleNumber`.

## Tests

`test/port/core/scale_options_test.dart`, `test/port/core/axis_label_plan_test.dart`,
`test/port/core/range_update_test.dart`, `test/port/scales/scale.radialLinear_plans_test.dart`,
`test/support/scale_options_of.dart`, the scale specs.
