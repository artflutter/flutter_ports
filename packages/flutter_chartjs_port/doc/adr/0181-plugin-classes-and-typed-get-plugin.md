# Chart.js ADR 0181: A class for each plugin, and getPlugin by type

- Status: accepted (2026-11-19): the plugin classes and `getPlugin<T>()` are on main, and the tests and the port checks pass.
- Date: 2026-11-19
- Supersedes: of [Chart.js ADR 0020](0020-registry-and-component-classes.md), in §5 the signature `Object getPlugin(Object? id)`; of [Chart.js ADR 0148](0148-plugin-typing.md), in item 1 the final class `PluginOf`.
- Related: [Chart.js ADR 0144](0144-native-plugins.md), [Chart.js ADR 0150](0150-typed-plugin-options.md)

## Context

`Registry.getPlugin` took an `Object?` id and returned an `Object`. Each caller cast the result.
The id is a string key of the JavaScript object model. The maintainer asked for a typed lookup with
no id (2026-11-19).

A lookup by type needs a separate run-time type for each plugin. Before this decision, the seven
built-in plugins were instances of one class, `PluginOf`. Their option types are extension types
over `Object?`. Dart erases an extension type at run time. Thus each built-in plugin was a
`Plugin<Object?>` at run time. The title and the subtitle plugins also had the same static type,
`Plugin<TitleOptions>`.

## Decision

1. **A class for each plugin.** `PluginOf` is a `base class`. Each plugin of the port is a final
   subclass with its own name, and the plugin object is an instance of it:

   ```dart
   final title = TitlePlugin();

   final class TitlePlugin() extends Plugin<TitleOptions> {
     this : super(id: 'title', options: TitleOptions.new, ...);
   }
   ```

   The classes are `ColorsPlugin`, `DecimationPlugin`, `FillerPlugin`, `LegendPlugin`,
   `SubtitlePlugin`, `TitlePlugin` and `TooltipPlugin`. The zoom port has `ZoomPlugin`, a subclass
   of `ChartPlugin<ZoomPluginOptions>`. The names of the plugin objects do not change.

2. **getPlugin by type.** The registry finds a plugin by its class:

   ```dart
   // Before
   final zoom = Chart.registry.getPlugin('zoom') as ChartPlugin<ZoomPluginOptions>;
   // After
   final zoom = Chart.registry.getPlugin<ZoomPlugin>();
   ```

   The signature is `T getPlugin<T extends Plugin<Object?>>()`. If no registered plugin is a `T`,
   the method throws a `StateError` with the text `<T> is not a registered plugin.`. If two
   registered plugins are a `T`, a debug build stops. The registry keeps the `id` keys of its items
   for the upstream order and for the unregister step. No public method of the registry takes a
   plugin id.

3. **Tests.** A test that finds its own plugin by `getPlugin` declares a private subclass for it.
   A test that only examines a registration reads `registry.plugins.items`. The reference texts of
   `registry_reference.dart` keep the upstream message, and the test changes the plugin lines to the
   Dart message.

4. **Rows.** The markers use the row `adapt-typed-plugins` of the Chart.js port and the row
   `adapt-typed-plugin-object` of the zoom port.

## Alternatives considered

- **A string id with a cast in the method.** The maintainer rejected each form with an id.
- **A lookup by the option type.** The option types of the built-in plugins are extension types,
  and Dart erases them. The title and the subtitle also share one option type.

## Consequences

- The public library gets the seven plugin classes, and the zoom library gets `ZoomPlugin`.
- A plugin of an app that it wants to find with `getPlugin` needs a class of its own. An inline
  `Plugin<Object?>(...)` works as before, but `getPlugin` cannot select it.
- The option facades stay extension types. Their move to final option classes is a separate
  decision.
