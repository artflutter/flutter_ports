# Plugin — migration draft

The decision is [Chart.js ADR 0144](adr/0144-native-plugins.md), which supersedes Chart.js ADR 0126. The
difference row is [`adapt-typed-plugins`](differences.md#adapt-typed-plugins).

## The class

Before:

```dart
typedef PluginHookFunction<A extends Object> =
    Object? Function(types.Chart chart, A args, Object options);

final class Plugin({
  final bool supportsDataUpdates = false,
  final bool Function(Object options)? dataUpdateGuard,
}) implements JsObjectFace {
  // The metadata and the 39 hooks are slots of one List<Object?>, with an own-key order,
  // extras and reads and writes by name.
  Object? id;
  Object? events;
  Object? defaults;
  PluginHookFunction<UpdateHookArgs>? beforeUpdate; // and 38 more hooks

  // Tests the function against 9 typedefs, else jsCall with `this` the plugin.
  Object? invokeHook(PluginHook hook, Object function, types.Chart chart, Object args, Object options);
}

// A Map plugin: core.plugins.dart reads map[hook] and calls it with jsCall.
extension type const MapPlugin(Map<dynamic, dynamic> map) { ... }
```

After:

```dart
typedef PluginHookFunction<A extends Object, O> =
    void Function(types.Chart chart, A args, O options);

// false cancels the step, true continues.
typedef CancelableHookFunction<A extends Object, O> =
    bool Function(types.Chart chart, A args, O options);

final class Plugin<O>({
  required final String id,

  // Makes the options of a hook from the resolved options: FillerOptions.new,
  // ZoomPluginOptions.new. Null gives the resolved options themselves.
  final O Function(ContextResolver options)? options,

  final List<String>? events,
  final Object? defaults, // a typed scope of a built-in plugin, an AnyObject of an add-on
  final Map<String, String>? defaultRoutes,
  final Object? descriptors, // a typed scope of a built-in plugin, an AnyObject of an add-on
  final List<String>? additionalOptionScopes,
  final bool supportsDataUpdates = false,
  final bool Function(O options)? dataUpdateGuard,

  // Mutable: a spec puts a spy into a hook.
  var PluginHookFunction<PluginHookArgs, O>? install,
  var PluginHookFunction<PluginHookArgs, O>? start,
  var CancelableHookFunction<UpdateHookArgs, O>? beforeUpdate,
  var PluginHookFunction<UpdateHookArgs, O>? afterUpdate,
  var PluginHookFunction<ScriptableScaleContext, O>? beforeDataLimits,
  var CancelableHookFunction<CancelableHookArgs, O>? beforeDraw,
  var CancelableHookFunction<DatasetDrawHookArgs, O>? beforeDatasetDraw,
  var CancelableHookFunction<EventHookArgs, O>? beforeEvent,
  var PluginHookFunction<EventHookArgs, O>? afterEvent,
  var PluginHookFunction<ResizeHookArgs, O>? resize,
  var CancelableHookFunction<TooltipDrawHookArgs, O>? beforeTooltipDraw,
  // ... the other hooks, with the kinds of Chart.js ADR 0144 item 2
}) {
  this;
}
```

- `MapPlugin`, the slot List, the extras, `jsRead`, `jsWrite` and `invokeHook` go.
- The service calls a hook through a generic method of `Plugin<O>`. A read of a hook field through
  `Plugin<Object>` fails the covariance check of Dart.
- A Map in `plugins` stops a debug build. A release build skips it.

## The hook arguments

The argument classes become plain final classes. They have no slots, no face and no extras.

```dart
// Before
final class ResizeHookArgs({required Object? size}) extends PluginHookArgs { ... }
final class EventHookArgs({
  required types.ChartEvent? event,
  required Object? replay,
  bool? cancelable,
  bool? inChartArea,
  bool? changed,
}) extends PluginHookArgs { ... }
final class TooltipDrawHookArgs({required Object? tooltip, bool? cancelable}) extends PluginHookArgs { ... }
// The scale hooks: PluginHookFunction<AnyObject>.

// After
final class ResizeHookArgs({required final ({double width, double height}) size})
    extends PluginHookArgs;
final class EventHookArgs({
  required final types.ChartEvent event,
  required final bool replay,
  var bool inChartArea = false, // a hook can write it
  var bool changed = false, // a hook can write it
}) extends PluginHookArgs;
final class TooltipDrawHookArgs({required final types.TooltipModel tooltip}) extends PluginHookArgs;
// The scale hooks: PluginHookFunction<ScriptableScaleContext, O>, the
// scale.getContext() of core.scale.js:535.
```

- The hook kind replaces the field `cancelable`. `DatasetUpdateHookArgs` and `DatasetDrawHookArgs` take
  a `ChartMeta`, not a `ChartMeta?`.

## The notify

```dart
// Before
bool? notifyPlugins(String hook, [Object? args, FilterCallback? filter]);
chart.notifyPlugins('resize', ResizeHookArgs(size: newSize));

// After: the hook gives the argument class and the kind.
enum PluginHook<A extends Object>(final String jsName, {final bool cancelable = false}) {
  beforeUpdate<UpdateHookArgs>('beforeUpdate', cancelable: true),
  resize<ResizeHookArgs>('resize'),
  // ...
}
bool notifyPlugins<A extends Object>(PluginHook<A> hook, A args, [FilterCallback? filter]);
chart.notifyPlugins(PluginHook.resize, ResizeHookArgs(size: newSize));
```

## The built-in plugins

```dart
// Before
final Plugin legend = Plugin(supportsDataUpdates: true)
  ..id = 'legend'
  ..jsWrite('_element', Legend.jsClass)
  ..beforeUpdate = _beforeUpdate;

void _beforeUpdate(types.Chart chart, Object _, Object options) {
  layouts.configure(chart, chart.legend! as Legend, options);
}

// After: the legend passes the resolved options to its box, so it takes them as they are.
final legend = Plugin<OptionView>(
  id: 'legend',
  supportsDataUpdates: true,
  beforeUpdate: _beforeUpdate,
);

bool _beforeUpdate(types.Chart chart, Object _, Object options) {
  layouts.configure(chart, chart.legend! as Legend, options);
  return true;
}

// After: the filler reads its options through the facade.
final filler = Plugin<FillerOptions>(
  id: 'filler',
  options: FillerOptions.new,
  beforeDraw: _beforeDraw,
);

bool _beforeDraw(types.Chart chart, PluginHookArgs _, FillerOptions options) {
  final draw = FillerDrawTime.of(options.drawTime) == FillerDrawTime.beforeDraw;
  return true;
}
```

The specs read `Legend.jsClass`, `Title.jsClass` and `Tooltip.jsClass` directly, not `_element`.

## The ChartView plugin

```dart
// Before: a Map
<String, Object?>{
  'id': r'$chartView',
  'supportsDataUpdates': true,
  'beforeDatasetDraw': (types.Chart chart, Object? args, Object? options) {
    shadowed = _beginShadow(chart, args); // tests `args is! DatasetDrawHookArgs`
  },
};

// After
Plugin<OptionView>(
  id: r'$chartView',
  options: (view) => view,
  supportsDataUpdates: true,
  beforeDatasetDraw: (chart, args, _) {
    shadowed = _beginShadow(chart, args.meta);
    return true;
  },
);
```

## An add-on plugin and an app

```dart
// Before: zoom
final Plugin zoomPlugin = Plugin(supportsDataUpdates: true)
  ..id = 'zoom'
  ..defaults = defaults
  ..beforeEvent = _beforeEvent;

bool? _beforeEvent(Object chart, EventHookArgs args, Object _) {
  final state = getState(chart);
  if (isZoomingOrPanningState(state)) return false;
  if (args.event!.type == 'click' || args.event!.type == 'mouseup') {
    if (state.filterNextClick) {
      state.filterNextClick = false;
      return false;
    }
  }
  return null;
}

// After
final zoomPlugin = Plugin<ZoomPluginOptions>(
  id: 'zoom',
  options: ZoomPluginOptions.new,
  defaults: defaults,
  supportsDataUpdates: true,
  beforeEvent: _beforeEvent,
);

bool _beforeEvent(Object chart, EventHookArgs args, ZoomPluginOptions _) {
  final state = getState(chart);
  if (isZoomingOrPanningState(state)) return false;
  if (args.event.type == 'click' || args.event.type == 'mouseup') {
    if (state.filterNextClick) {
      state.filterNextClick = false;
      return false;
    }
  }
  return true;
}

// Before: an inline plugin of an app
'plugins': [<String, Object?>{'id': 'probe', 'afterDraw': (chart, args, options) => count++}],

// After: the same object in a raw config and in ChartConfig.plugins
final probe = Plugin<Object?>(id: 'probe', afterDraw: (_, _, _) => count++);
ChartView(config: ChartConfig(plugins: [probe], ...));
```

## Open

- The hooks take `types.Chart`, because `plugin.decimation` and the filler are core layers. The public
  library hides `types.Chart`. Thus the zoom port keeps its 8 casts to `Chart` in its named hook
  functions.
- The update mode is a string, a function or `undefined`. `UpdateHookArgs.mode` stays `Object?` until the
  update mode gets its own type.
- The spec `core.plugin` calls the hook name `'hook'` 18 times. No `Plugin` field has this name: each case
  takes a hook of the 35, or skips with `diverges:`.
