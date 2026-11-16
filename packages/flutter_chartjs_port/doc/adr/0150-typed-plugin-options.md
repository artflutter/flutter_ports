# Chart.js ADR 0150: Typed plugin options

- Status: accepted (2026-11-16): its code and the tests of section Tests pass.
- Date: 2026-11-16
- Supersedes: of [Chart.js ADR 0144](0144-native-plugins.md), item 4 for `ResizeHookArgs.size`, item 5, and item 6
  for `events`; of [Chart.js ADR 0148](0148-plugin-typing.md), item 3 for the members of `PluginOptions`, and the
  consequence on `Plugin.events`.
- Related: [native-plugin-options-design-draft.md](../native-plugin-options-design-draft.md)

## Context

After Chart.js ADRs 0144 and 0148, the hooks of the legend, title, subtitle and tooltip plugins got the resolved
options as an `OptionView`. 49 getters of the option facades gave the raw JS value, and each reader converted it
(`jsToNumber`, `toFont`, `canvasTextAlign`). The plugin field `events` had no reader: upstream reads only the option
`events` (`core.controller.js:1170`), and an add-on had no form of that option. The hook `resize` got a record, and
the option `onResize` got a Flutter `Size`.

## Decision

1. **The options of a hook.** The optional `options` of a plugin makes the `O` of its hooks from the resolved
   options. With no `options`, the hooks get the resolved options themselves: then `O` is `ContextResolver`,
   `Object` or `Object?`, and another `O` stops a debug build. A plugin whose `defaults` is a `PluginOptions` gets
   the merged options object. `O` has no bound, because a facade is an extension type over `Object?`. The plugin
   service stores `Plugin<Object?>` and calls `Plugin.notify`, which reads the hook field inside the class.
   `dataUpdateGuard` and `rangeUpdateGuard` take `O`.

2. **The built-in plugins get their facades.**

   ```dart
   final legend = Plugin<LegendOptions>(id: 'legend', options: LegendOptions.new, start: _start);
   void _start(types.Chart chart, PluginHookArgs _, LegendOptions options) {
     final legend = Legend((ctx: chart.ctx, options: options.object!, chart: chart));
   }
   ```

   `legend` is a `Plugin<LegendOptions>`, `title` and `subTitle` are `Plugin<TitleOptions>`, `tooltip` is a
   `Plugin<TooltipOptions>`, and `filler`, `decimation` and `colors` take `FillerOptions`, `DecimationOptions` and
   `ColorsPluginOptions`. A hook takes the argument class of its hook. A box keeps the resolved options and reads
   them through the facade. The plugin of `ChartView` reads no option and takes the resolved options.

3. **A getter gives the type of its schema key.**

   ```dart
   double get caretSize => jsToNumber(optionOf(object, OptionKey.caretSize));
   ChartTextStyle get titleFont => toFont(optionOf(object, OptionKey.titleFont));
   TextAlign? get bodyAlign => canvasTextAlign(optionOf(object, OptionKey.bodyAlign));
   double? get maxWidth => _truthyNumber(optionOf(object, OptionKey.maxWidth)); // `x || this.maxWidth`
   List<String> get text => _textLines(optionOf(object, OptionKey.text)); // a String is one line
   ```

   The getter applies the conversion that each reader applied at the read. A reader reads the getter at the
   upstream place of the read, so the reads and the calls of a scriptable option keep their order. This decision
   gives a type to 34 getters: the numbers, the fonts, the text aligns, the positions, `drawTime`, the lines of a
   title text and the tooltip `borderWidth` (`canvasNumber`).

4. **Fifteen getters stay raw.** The colors stay raw, because the canvas takes a `ChartPaint` or a Flutter `Color`
   and validates the rest. The tooltip `cornerRadius` (a number or the corners) and `animations` (`false` or a
   scope) stay raw. The legend label `borderRadius` and `pointStyle` stay raw, because the legend item keeps them.
   `generateLabels` stays raw, because its type takes the public `Chart`, which a core layer cannot name.
   `LegendOptions.labelsValue` keeps a falsy value. The decimation `algorithm` stays raw, because its error names
   the raw value.

5. **The events of a plugin.** `Plugin` has no field `events`. `PluginOptions<T>` has three members: `pluginId`,
   `merge(over)` and `events`.

   ```dart
   List<String>? get events => null; // PluginOptions: an add-on overrides it with a field
   bool eventFilter(PluginDescriptor plugin) => _includes(
     switch (plugin.options) {
       final PluginOptions<Object?> options => options.events ?? _options.readKey(OptionKey.events),
       final view => _or(readOption(view, OptionKey.events), _options.readKey(OptionKey.events)),
     },
     e.native!.type,
   );
   ```

   `ZoomPluginOptions` has the field `events`. An event type stays a `String`.

6. **The size of a resize.** `ResizeHookArgs.size` is a Flutter `Size`. `_resize` makes one `Size` and gives it to
   the hook `resize` and to the option `onResize`.

## Rejected

- Typed colors: a raw config can hold a Flutter `Color`, and a `ChartPaint` getter makes a new paint at each read.
- An enum of the event types: `NativeEvent.type` and `addEventListener` take the same `String`.
- Typed `defaultRoutes`, `additionalOptionScopes` and descriptor rules: they are the scope paths and the key names
  of the config layer, which the controllers, the scales and the elements share.

## Consequences

- The hooks of the seven built-in plugins have typed options. A test that calls a hook gives the facade, for
  example `LegendOptions(chart.options)`.
- An add-on can limit its events with its options object.
- No read moves: the observation digests of the oracle do not change.

## Tests

- `test/port/plugins/plugin_options_test.dart`
- `test/port/core/core.plugins_typed_public_test.dart`, `test/port/core/core.plugins_test.dart`,
  `test/port/types/plugin_test.dart`
- `test/port/plugin_test.dart` of `flutter_chartjs_plugin_zoom_port`
- The full test list of AGENTS.md before a push.
