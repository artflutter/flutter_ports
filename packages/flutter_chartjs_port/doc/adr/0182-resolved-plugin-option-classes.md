# Chart.js ADR 0182: Resolved option classes for the built-in plugins

- Status: accepted (2026-11-19): the option classes are on main, and the tests and the port checks pass.
- Superseded in part by: [Chart.js ADR 0192](0192-tooltip-options-object.md) (2026-11-23), for the tooltip parts of items 1, 4, 5 and 7; [Chart.js ADR 0193](0193-legend-options-object.md) (2026-11-23), for the legend parts of items 1, 3, 5 and 7
- Date: 2026-11-19
- Supersedes: of [Chart.js ADR 0150](0150-typed-plugin-options.md), item 2 (the facades of the built-in plugins) and item 3 (the getters of the facades).
- Related: [Chart.js ADR 0181](0181-plugin-classes-and-typed-get-plugin.md), [Chart.js ADR 0148](0148-plugin-typing.md)

## Context

The options of the seven built-in plugins were extension types over `Object?`: `TitleOptions`,
`LegendOptions`, `LegendLabelOptions`, `LegendTitleOptions`, `TooltipOptions`, `FillerOptions`,
`DecimationOptions` and `ColorsPluginOptions`. Each getter read one key of a resolver by name at
each read. The title and the subtitle shared one facade. The maintainer asked for final option
classes with typed fields, as `ZoomPluginOptions` of the zoom port is (2026-11-19).

The title, legend and tooltip options are scriptable upstream: a function option gets the chart
context, or the tooltip context, at its read. A final class holds values. Thus a class needs typed
function fields, or the plugin resolves the options before the hook. The maintainer chose the
second form.

## Decision

1. **A final class of resolved values.** Each of the eight types is an immutable final class with
   one typed field for each key, `==` and `hashCode`. The static method `of` reads each key of the
   resolved options once and makes the object. A scriptable option gives its value at that read.

   ```dart
   // Before
   extension type const TitleOptions(Object? object) {
     List<String> get text => _textLines(optionOf(object, OptionKey.text));
   }
   // After
   final class const TitleOptions({required final List<String> text, ...}) {
     static TitleOptions of(Object? options) => ...;
   }
   ```

   `of` keeps an object of its own class. A missing `labels` or `title` of the legend gives the
   options of `{}`.

2. **One object for each set of resolved options.** `PluginOf` makes the options of a resolved
   view at the first hook that has a function, and keeps them in an `Expando` keyed by the view.
   Each hook of one update gets the same object. A new update makes new views, so the options of
   the next update are new.

3. **The boxes keep the resolved values.** `Title.options` is a `TitleOptions?` and
   `Legend.options` is a `LegendOptions`. The layout reads `display`, `fullSize`, `position` and
   `weight` of a box through the interface `LayoutBoxOptions` (`readOption` gives
   `layoutOption(key)`). The doughnut and polar area legend generators read the typed label
   fields.

4. **The tooltip resolves with its context.** The tooltip keeps the resolved view of its options
   and makes a `TooltipOptions` of `setContext(getContext())` where upstream calls `setContext`.

5. **The link to the view.** `LegendOptions.view` and `TooltipOptions.view` hold the resolved
   options that gave the values. They are not a part of `==`. The proofs of the hidden legend
   build (row `adapt-hidden-legend-items`), the interaction mode of the tooltip (`intersect`,
   `axis`, `includeInvisible`) and the tooltip `setContext` read them.

6. **The decimation algorithm.** `DecimationOptions.algorithm` is a `DecimationAlgorithm`. A value
   that is not an algorithm gives a private algorithm whose `decimate` throws the error of
   upstream, `Unsupported decimation algorithm '<value>'`. `DecimationAlgorithm.decimate` takes a
   `DecimationOptions`.

7. **Raw values that stay.** The colors of the legend and the tooltip, the legend label
   `borderRadius` and `pointStyle`, the tooltip `cornerRadius` and `animations` stay `Object?`:
   their domain is a union of types. The legend label `generateLabels` stays `Object?`, because
   its function type takes the `Chart` class, which the core layer does not import.

8. **Hooks of a typed plugin.** `PluginOf.hookOf(hook)` gives the function of a hook. A read of a
   hook field through `Plugin<Object?>` fails the covariance check of Dart when the options type
   is a class.

9. **Row.** The markers use the new row `adapt-native-plugin-options`.

## Alternatives considered

- **Typed function fields.** Each scriptable key gets a value field and a function field. The
  maintainer chose the resolved values.
- **The facades.** They read by name at each read, and the title and the subtitle share one type.

## Consequences

- The upstream reads are late: a write into the options between two hooks of one update shows in
  the same update upstream. In the port, the options of an update are fixed at its first hook,
  and the write shows at the next update.
- A scriptable option of the title, the subtitle and the legend runs once for each set of
  resolved options. At the start of a chart, the plugin service makes two sets (the start hook and
  the first update): a scriptable legend label color runs twice, where upstream runs it once. The
  case of the resolver trace skips with `diverges: adapt-native-plugin-options`.
- A string interaction mode in the tooltip options stops a debug build at the first hook, not at
  the first event.
- A test that reads a plugin option reads the typed field, or `view` for a read of upstream order.
