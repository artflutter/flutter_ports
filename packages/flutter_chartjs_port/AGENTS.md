# Chart.js port: layout

This file describes `packages/flutter_chartjs_port`: its libraries, its internal rules, its tests and its
docs. The root `AGENTS.md` has the commands, the porting rules, the test rules and the conventions of the
repository.

- `packages/flutter_chartjs_port`: the Chart.js port (library, version 0.1.0). Its pubspec has no
  `publish_to`, so pub can publish it (Chart.js ADR 0047 §6). `CHANGELOG.md` has the entry 0.1.0.
  Its `analysis_options.yaml` includes the rules of the root file, and its `.pubignore` keeps
  `doc/`, `test/`, `tool/`, `dart_test.yaml` and `build/` out of the published archive (Chart.js
  ADR 0047). The harness and the gallery name it as a path dependency. `README.md` is the README
  of pub.dev. It names a file outside the archive by an absolute GitHub URL (Chart.js ADR 0047).
  It shows the typed API first and `ChartView.raw` after it (Chart.js ADR 0052 §13). Each Dart
  snippet of it compiles and runs: a change of a snippet checks it in a temporary test.
  `example/main.dart` (port-only, no pubspec, Chart.js ADR 0047 §5) is the example of the archive:
  one typed `ChartView` with a new data List in `setState` and an `onClick` tear-off with `int`
  indexes (Chart.js ADR 0052 §13). The workspace formats and analyzes it with the package
  rules. `check:headers` and `check:lib-imports` do not examine `example/`.
  - The four public libraries (Chart.js ADRs 0048 §5 and 0108), port-only and not pure layers:
    `lib/flutter_chartjs_port.dart` (the app library: `chartjs.dart` without `Animation` and
    `Element`, the two Flutter names, `ChartView`, `ChartTheme` and `ChartThemeData`, and the
    typed API of `lib/src/typed/typed.dart`),
    `lib/chartjs.dart` (the `chart.js` entry: `lib/src/types.dart` with a hide list, the Canvas 2D
    interface, `ChartMeta`, `defaultDateZone`, `setDefaultDateZone`, `notifyArrayListeners`,
    `JsClass`, `JsObjectFace`, `Undefined`, `undefined` and `lib/src/upstream.dart`; the native
    plugin API of Chart.js ADRs 0108 and 0144: `Plugin`, `PluginHook`, `PluginHookFunction`,
    `CancelableHookFunction` and the seven hook argument classes; and the input surface of Chart.js ADR 0108: `NativeEvent`, `NativeTouch`,
    `NativeEventListener`, `NativeEventTarget`, `DOMRect` and the extensions `CanvasEventTarget`
    and `CssStyleProperties`; and the option types of the rows `adapt-interaction-mode-objects`,
    `adapt-interaction-axis-enum`, `adapt-tooltip-positioner-objects` and
    `adapt-decimation-algorithm-objects`: `InteractionMode` with its six mode classes,
    `InteractionAxis` and `ActiveElement`, `TooltipPositioner` with `AverageTooltipPositioner`,
    `NearestTooltipPositioner` and `TooltipPosition`, and `DecimationAlgorithm` with
    `LttbDecimationAlgorithm` and `MinMaxDecimationAlgorithm`), `lib/helpers.dart` (the `chart.js/helpers`
    entry:
    `lib/src/helpers/index.dart` without the Dart names of the upstream `_` exports, except
    `isPointInArea`, which a ported add-on imports, Chart.js ADR 0108) and `lib/js_semantics.dart`
    (the JS runtime for add-on ports: each library of `lib/src/js/` with each of its names, with
    no `show` list, Chart.js ADR 0132; no other library exports it). `lib/chartjs.dart` also
    exports the names that a chart type of another package needs (Chart.js ADRs 0132 and 0133):
    `ParsedItem`, `ElementPoint`, `VisualElementRange`, and `controllerArgs`, `elementCfgArg` and
    `scaleCfgArg` for the `construct` closure of a class value. `DatasetController.cachedMeta` is
    public for a controller of another package (Chart.js ADR 0133). An app imports the app library next to
    `material_ui.dart` with no prefix. `doc/public_api.txt` is the committed list of their export
    names. `test/tool/public_api_test.dart` compares the list, checks that the app library shares
    no name with the Flutter libraries and `dart:ui`, checks the `@internal` rule of Chart.js ADR
    0048 §6, and checks that the libraries cover the `exports` of `doc/upstream/manifest.json` (the
    allowlist `_notExported` has the reasons, and `_addOnHelpers` lists the `_` exports that a
    ported add-on imports). After a change of the public API,
    `PUBLIC_API_UPDATE=1 flutter test test/tool/public_api_test.dart` writes the list again.
    `test/port/public_library_test.dart` imports the app library next to `material_ui.dart`,
    registers the line set and pumps a `ChartView`.
  - `lib/src/`: ported modules at their upstream paths (`controllers/`, `core/`, `elements/`,
    `helpers/`, `platform/`, `plugins/`, `scales/`, `types/`), and `js/`, the JS runtime: port-only `js_*.dart` files. `js_webidl.dart` has the WebIDL
    conversions of the Canvas 2D setters. `js_class.dart` has the JS class values (Chart.js ADR
    0020). `js_promise.dart` has the promise jobs (Chart.js ADR 0019). The animator walks a copy
    of its chart list (row `adapt-animator-chart-list`): a chart that a listener starts gets its
    first visit in the next frame.
  - `lib/src/options/` (Chart.js ADR 0054, port-only, pure layers): the typed internal model.
    `opt.dart` has the option cell `Opt<T>` (`OptValue`, `OptFunction`, `OptList`, `OptScope`,
    `OptUndefined`, `OptNull`, `OptForeign`) and the classification of a raw JS value for a key of
    a shape. `option_scope.dart` has `OptionScope`, the base of the typed scopes: the own-key
    order of JS, the extras (the keys that its kind does not declare) and the face by name
    (`jsRead`, `jsWrite`, `jsHas`, `jsDelete`, `jsKeys`, `operator []` and `operator []=`): it
    implements `JsObjectFace` of `js_object.dart` (Chart.js ADR 0054 §5) and is not a `Map`.
    `raw_scope.dart` has `RawScope`, an extension
    type over a user Map: the walk reads a user Map through it. `jsGet`, `jsObjectKeys`,
    `isObject`, `clone`, `merge` and `mergeIf` take a typed scope; a `merge` into a typed scope
    makes typed children (`_cloneToScope` of `helpers.core`). `OptionScope.nativeFace` (the class
    of its kind, `ScopeKind.scopeType`; `Defaults` keeps its face) guards the typed walks: `merge`
    and `mergeIf` of a typed scope into a typed scope with the default merger walk the typed keys
    (`_mergeScope`, `typedMergeKeys`, `typedMergeTarget`, row `adapt-typed-scope-merge`); a Map, a
    subclass, a routed target, an array-index extra or a custom merger keeps the walk by name.
    `OptionScope.debugTypedMerge` turns the typed walk off for the twins of
    `test/port/options/typed_merge_test.dart`. The generated files have `OptionKey`
    (one entry for each distinct key name, `optionKeyOf`), `ScopeKind` (one entry for each kind
    of the schema) and one class `<Kind>Scope` for each kind, with a field of an `Opt` cell for
    each key (`<key>Cell`) and a typed setter. A kind takes the name of its `index.d.ts`
    interface; its class adds `Scope`. `defaults`, `overrides` and `descriptors` of
    `core.defaults.dart` are typed roots, built at start from typed cascades of the component
    files (the `Defaults` constructor, the values of `core.*.defaults.dart` and the `defaults`,
    `overrides` and `descriptors` statics of the controllers, elements, scales and plugins), not
    from generated values: a bump changes a default in the same file as upstream (Chart.js ADR
    0054 §3). `defaultRoutes` stays a table of route strings. `Defaults.route` of a typed scope
    is a typed route (`OptionScope.addRoute`); a scope or target scope that is a raw Map becomes a
    typed scope with the same keys in its owner (row `adapt-defaults-route`). `resolved.g.dart`
    (generated from the `resolved` lists of the schema) has the resolved options of the four
    elements: `PointOptions`, `LineOptions`, `BarOptions` and `ArcOptions`, each key a typed
    field (`double`, `bool`, `String?` or `Object?`) with a present bit and a foreign slot
    (`isForeign`, `foreignOf`, Chart.js ADR 0054 §6 and §9). `element_options_base.dart` has
    their base `ElementOptions` (the face, `$shared`, `$animations`, the extras, the frozen
    state, `storeKey`) and `GenericElementOptions`. `foreign_audit.dart` has the hook
    `foreignAudit` of the oracle O2: the typed classes call it inside `assert` for each value that
    they keep in a foreign slot. The option `easing` holds a Flutter `Curve`
    (row `adapt-flutter-curves`, the schema shape `curve`, `classifyTyped<Curve>` of `opt.dart`),
    also in a raw config. `lib/` has no easing names and no table from a name to a curve: a name is
    a foreign value, a debug build stops on it in `_cfgEasing` of `core.animation.dart`, and a
    release build takes `Curves.linear`. The animation calls `Curve.transform`; no animation reads
    `helpers.easing.dart`. An app or a plugin gives its own `Curve` class, with no registration
    (`test/port/options/curve_option_test.dart`). Upstream data hold a name in that place: no
    test compares the value of `easing` with upstream data (the markers of
    `test/support/easing_json.dart`), and no code maps a name to a constant of `Curves`. For an
    upstream config, the adapter `nativeFixtureColors` of `chartjs_test_utils` gives an
    `EffectCurve`, a curve with the formula of the upstream effect, so the animation reference
    tests keep the upstream steps.
  - `lib/src/helpers/helpers.config.dart` (Chart.js ADR 0054 §4): the typed resolvers
    `OptionResolver` (the target of `_createResolver`) and `OptionView` (the target of
    `_attachContext`), with the typed read `readKey(OptionKey)` and a cache by `OptionKey`.
    `Resolver` and `ContextResolver` are their typedefs; `lib/helpers.dart` hides the class names.
    Both are a `JsProxyObject`: the face (`JsObjectFace`) over their traps, with `ownKeys` (the
    `ownKeys` trap) and `hasProperty` (the `has` trap). `mergeScaleConfig` of `core.config.dart`
    writes a typed `ScaleOptionsByIdScope` of `ScaleOptionsScope`s into `options.scales`; the
    config, the data and the options of the user stay raw Maps (Chart.js ADR 0054 §5), and the
    config boundary also takes the typed root, data and options of a typed config. The
    sub-resolver of a top-level resolver (its parent scopes are its root scopes) walks the list
    once when the second walk adds nothing: plain keys, SDK Maps or native-face scopes with no route
    of the key, `_fallback` values that are not functions (row `adapt-resolver-single-walk`); any
    other walk goes over the list twice, as upstream. A first read looks its name up once
    (`_getKeyed`).
  - The face rules (Chart.js ADR 0054 §5, the close step): no class of `lib/src` outside
    `lib/src/js/` is a `Map`. A typed object (a typed scope, resolved options, a resolver or a
    view, a context, a parsed item, a props or hook-argument record, a plugin, a legend or
    tooltip item, `AnimationSpec`) is a `JsObjectFace`: `operator []` and `jsRead` give
    `undefined` for an absent key, `jsKeys` gives the `Object.keys` order, `jsHas` and `jsDelete`
    are `hasOwnProperty` and `delete`. `JsObjectFace` is public (`chartjs.dart` and the app
    library): raw-API code reads a context, the hook arguments or the options by name through
    it. A `Map` of the port is an object of the user. The JS runtime (`jsGet`,
    `jsObjectKeys`, `jsAssign`, `jsSet`, `jsHasOwn`, `jsDeleteKey`, `jsObjectOrNull`) and
    `isObject`, `clone`, `merge`, `mergeIf` and `each` take Maps and faces.
    The walk reads a typed scope with `OptionScope.lookup`. `Config.resolveElementNamedOptions` of
    `core.config.dart` is the typed element step of `_resolveElementOptions`: it reads each own key
    of `defaults.elements.<type>` with `readKey` and stores it into the resolved class of the type.
    `createContext` of `helpers.options.dart` gives the typed context of its `type`
    (`ScriptableChartContext`, `ScriptableContext`, `ScriptableScaleContext`,
    `ScriptableScalePointLabelContext`, `ScriptableTooltipContext`,
    `ScriptableLineSegmentContext`, Chart.js ADR 0054 §11), subclasses of `ContextObject`.
  - The cross-lane types of Chart.js ADR 0054 (B5, pure layers; the lanes adopt them):
    `lib/src/options/typed_record.dart` (`TypedRecord`: typed fields by slot, present and foreign
    bits, extras, the JS key order, the face), `parsed.dart` (`ParsedItem`, `ItemStacks`,
    `StackEntry`, `IndexValues`, `FloatingBar`), `props.dart` (`PointProperties`,
    `BarProperties`, `ArcProperties`, `LineProperties`), `animated_prop.dart` (`AnimatedProp`),
    `lib/src/types/data_item.dart` (`TypedDataItem`). `lib/src/types/plugin.dart` has the native
    plugins of Chart.js ADR 0144 (row `adapt-typed-plugins`): `Plugin<O>` with one typed field for
    each of the 35 hooks and no key by name, the generic enum `PluginHook<A>` (JS name, kind,
    argument class), the hook types `PluginHookFunction<A, O>` (returns `void`) and
    `CancelableHookFunction<A, O>` (returns `bool`: `false` cancels; the ten hooks that upstream
    calls with `cancelable: true`), and the argument classes, plain classes with no `cancelable`
    field. `O` is the options type of the hooks: the `options` function of the plugin makes it from
    the resolved options, or the hooks get the resolved options themselves. `PluginService._notify`
    calls `Plugin.notify`, a generic method that reads the hook field inside the class (a read
    through `Plugin<Object?>` fails the covariance check). `chart.notifyPlugins` takes a
    `PluginHook<A>` and an `A?`; a custom hook name has no form. A value that is not a `Plugin` in
    `config.plugins` or in `Chart.register` stops a debug build; a Map without an `id` stays a
    container of `Chart.register`. A hook takes `types.Chart`: a named hook of an add-on takes
    `Object chart` and casts it to `Chart`. `Element.markUndefined(AnimatedProp)` and
    `isUndefined` are the typed property API of the elements.
  - `lib/src/core/core.element.dart` and `lib/src/elements/` (Chart.js ADR 0017): the port of
    `core.element.ts`, and the four elements (`element.point.dart`, `element.line.dart`,
    `element.bar.dart`, `element.arc.dart`) with `index.dart`. The port-only `element_options.dart`
    (Chart.js ADR 0054) exports the typed element options of `lib/src/options/resolved.g.dart`
    and `element_options_base.dart`: `PointOptions`, `LineOptions`, `BarOptions`, `ArcOptions`
    and `GenericElementOptions`, with `clone` and the frozen state. It keeps
    `createElementOptions` and `copyOptions` (Chart.js ADR 0021), and the typed reads
    `plainOption`, `numberOption` and `rawOption` (Chart.js ADR 0054 §6). These
    files are pure layers. Each numeric property of an element is a `double` field (NaN while
    `undefined`) with a bit of an `int` mask of the `undefined` state; `markUndefined` and
    `isUndefined` read and write the bit (Chart.js ADR 0054 §9). A numeric geometry property has
    its own class next to its element (`ElementXProp`, `BarBaseProp`, `ArcStartAngleProp`, a subclass
    of `AnimatedProp`): it reads and writes the field of the element (`write`, `read`,
    `markUndefined`, `isUndefined`), and no element class has a `switch` by a property id. A style property
    (`StyleProp`: `radius`, `borderWidth`, `tension`, the three colors, `offset`, `spacing`) has the
    `OptionKey` of the resolved options: an animation reads and writes the typed field of the
    options (`valueOf`, `store`), and `Animation` has no name of its property. `Element.$context` is a
    `ContextObject?` with a `covariant` setter, narrowed to `ScriptableContext?` in the four
    element classes. `Element.assign` of a `*Properties` object of a controller takes the typed
    setters for an element of the built-in class (`typedWrites`, the exact-class rule); a user
    subclass, an extra key and a foreign value take the writes by name. The element classes read resolved options through `plainOption`, `numberOption` and `rawOption`,
    `ArcElement` reads a key that is not a `double` through the generated `<key>Value` getter of
    `ArcOptions` (Chart.js ADR 0102), and a plain Map reads by name. `Element` and each element class have a static `jsClass`, the class as a
    value (Chart.js ADR 0020). `PointElement` and `BarElement` implement `types.VisualElementRange`,
    the interface of `getRange`. `getRange` gives an `Object`: the `PointElement` result is the JS
    `+` of `radius` and `hitRadius` (`jsAdd`), a `String` when an option is a string. The hit tests
    and `size` of `PointElement` and the `rAdjust` and `getCenterPoint` of `ArcElement` also add
    their options: two plain typed fields add as numbers, and a foreign or absent value takes
    `jsAdd`. The style of a segment of `helpers.segment.dart` is a `SegmentStyle`, an immutable
    object whose `==` is the compare of `styleChanged` (Chart.js ADR 0142). `LineElement.updateControlPoints` takes a `ChartArea?`: Dart `null`
    is the JS `undefined` of a chart without a layout. The `points` setter of `LineElement` takes
    `List<types.Element>` and copies a list that is not a `List<types.PointElement>` (Chart.js ADR 0028), unless its last copy
    holds the same elements (Chart.js ADR 0095). `lib/src/types/index.dart` also has `RadialLinearScale` and `LegendElement` (Chart.js ADR
    0028), and `TooltipModel` (Chart.js ADR 0039 §14). `Chart.tooltip` is a `TooltipModel?` field:
    the tooltip plugin writes it, and `core.controller.dart` does not import the plugin.
    `RadialLinearScale` of `scale.radialLinear.dart` implements `types.RadialLinearScale`. Its
    `xCenter` and `yCenter` are `double?`: Dart `null` is the `undefined` before the first layout
    (Chart.js ADR 0033). The scale reads `xCenter ?? double.nan` in arithmetic, and the radar and
    polar area controllers write it into a new element as `undefined`.
    - [Chart.js ADR 0067](doc/adr/0067-scalar-bar-geometry.md): the exact `BarElement` computes an ordinary bar
      with scalar locals and keeps the same canvas calls. See `test/port/elements/element.bar_rectangular_test.dart`.
      On an upstream bump, recheck `getBarBounds`, `parseBorderWidth`, `parseBorderRadius`, `boundingRects`,
      `inflateRect` and `draw` (row `adapt-rectangular-bar-draw`).
    - [Chart.js ADR 0068](doc/adr/0068-live-bar-update-layout.md): the exact bar controller proves a live
      single-dataset layout and skips the axis and stack search. See
      `test/port/controllers/bar_index_layout_test.dart`. Only the class check of a container is cached, by its
      identity. Values, routes and ids stay live reads.
    - [Chart.js ADR 0069](doc/adr/0069-bulk-numeric-bar-updates.md): in mode `none`, the bars after the first
      ordinary bar take one bulk numeric update (`core/bar_bulk_update.dart`). See
      `test/port/controllers/bar_bulk_update_test.dart`. The preflight ends before the first bulk write. A failed
      preflight runs the ordinary loop, with no partial bulk write.
    - [Chart.js ADR 0078](doc/adr/0078-prepared-indexed-options.md): native indexed point and bar options copy a
      private static template, and the bulk bar update also takes indexed colors. See
      `test/port/core/indexed_element_options_test.dart`. Each result is a fresh, unfrozen copy. No plan lives
      across an update or a plugin hook.
    - [Chart.js ADR 0079](doc/adr/0079-scatter-point-options.md): the scatter update and overflow loops prepare
      indexed point colors once for each loop. See `test/port/controllers/scatter_point_options_test.dart`. A plan
      checks each point at its original iteration, with no scan of the whole data. It ends before user code can run.
    - [Chart.js ADR 0080](doc/adr/0080-line-20k-options.md): line updates prepare indexed colors, scriptable colors
      copy a template, and contexts track their keys with a mask. See
      `test/port/controllers/line_point_options_test.dart` and `test/port/helpers/context_presence_test.dart`. No
      callback result is cached. Each resolver write or delete ends the plan.
    - [Chart.js ADR 0081](doc/adr/0081-option-resolution-setup.md): native default-key snapshots, kept prefixes and
      owned results cut the setup of point and bar options. See `test/port/options/key_snapshot_test.dart` and
      `test/port/core/owned_element_options_test.dart`. A key add, a key delete and a restore end a snapshot. A
      custom `Config` or key producer keeps its virtual calls.
    - [Chart.js ADR 0082](doc/adr/0082-native-line-resolution.md): a mode-`none` line loop keeps its warmed
      point-color resolver and its native sources. See `test/port/controllers/line_resolution_test.dart`. No plan
      persists across `updateElements` calls. A generic fallback keeps the ordinary context factory.
    - [Chart.js ADR 0083](doc/adr/0083-ordered-color-resolution.md): a scriptable color plan visits only the
      varying colors, and one-argument callbacks take a scalar loop. See
      `test/port/core/varying_color_resolution_test.dart`. No callback result is memoized. An invalidation resumes
      at the next original key.
    - performance.md §54 identifies suggested x bounds as the first data-only
      blocker. Do not replace them with fixed bounds under unsorted parsing:false
      input: binary visible-range selection can omit points. GC timeline evidence
      prioritizes temporary circle/path objects; the diagnostics change no runtime.
    - [Chart.js ADR 0086](doc/adr/0086-weak-point-coordinate-cache.md): the indexed-color line loop keeps weak
      references to the native coordinate maps that it accepted. See `test/port/core/point_coordinate_cache_test.dart`.
      A hit skips only the class check: the loop reads each x and y at its original iteration. A prepared pass makes
      at most 1,024 weak entries.
    - [Chart.js ADR 0087](doc/adr/0087-shared-native-point-contracts.md): `core/point_options.dart` holds the native
      point contracts, and `core/point_option_preparation.dart` holds the preparation of the controllers. See
      `test/port/core/native_point_contracts_test.dart`. Reuse a predicate only when its guarantee and its lifetime
      match the new read. Keep a narrower requirement explicit at its observation point. Do not widen an allowlist
      or a capability to share a helper. `NativePointResolution.resolve` validates its sources before its executor.
    - [Chart.js ADR 0088](doc/adr/0088-prepared-scalar-point-resolution.md): a native line loop runs a prepared
      scalar point-color plan through a direct executor. See `test/port/core/prepared_scalar_point_test.dart`. A
      context that invalidates the attempt continues the ordinary resolution with that context. No context factory
      runs twice.
  - `lib/src/core/` also has these files:
    - `core.config.dart` has the theme hunks H0-H3 and the public H0 reader `chartThemeOf` (Chart.js
      ADR 0147 §2) and the `into` parameter of `resolveNamedOptions` (Chart.js ADR 0021).
      `core.adapters.dart` has `DateAdapter` and `DateAdapterBase`. `DateAdapterBase.jsClass` is the
      `_date` of `adapters`. Both files are pure layers. A time unit is the enum `TimeUnit` of
      `core.adapters.dart` (row `adapt-time-unit-enum`): the options `time.unit`, `time.minUnit`
      and `time.round`, `TimeScale.unit` and the unit of `add`, `diff`, `startOf` and `endOf`.
      The ISO week of upstream `startOf(time, 'isoWeek', weekday)` is the member
      `startOfIsoWeek(time, weekday)`. The default adapter reads no unit name.
    - `date_adapter.dart`, `date_calendar.dart`, `date_zone.dart`, `date_parse.dart` and
      `date_format.dart` are the port-only default date adapter (Chart.js ADR 0024), pure layers.
      `DateAdapterBase.prototype` starts with `dateAdapterMembers`, the rules of
      chartjs-adapter-moment 1.0.1 on moment 2.29.4 with ICU patterns. `setDefaultDateZone`
      selects local time (the default) or UTC. [Chart.js ADR 0110](doc/adr/0110-local-zone-offset-cache.md):
      `LocalZone` of `date_zone.dart` keeps up to 64 offset intervals, and `formats()` clears them once for each
      update. See `test/port/core/date_zone_test.dart` and `date_adapter_test.dart`.
    - `core.interaction.dart` and `core.layouts.dart` are pure layers. `Interaction` is a class with
      the static member `evaluateInteractionItems`. The option `mode` of `interaction`, `hover`
      and the tooltip holds an `InteractionMode` (row `adapt-interaction-mode-objects`, the schema
      shape `interactionMode`), also in a raw config: an object with the method `itemsAt`. Each
      upstream mode is a ready class (`IndexInteractionMode`, `DatasetInteractionMode`,
      `PointInteractionMode`, `NearestInteractionMode`, `XInteractionMode`, `YInteractionMode`):
      an app writes `mode: NearestInteractionMode()`, and an app or a plugin gives its own mode
      as a subclass, with no registration. `lib/` has no mode names and no table from a name to a
      mode: `Interaction` has no `modes`, and `InteractionMode` has no constants. The chart calls
      the method of the value of the option: `Chart.getElementsAtEventForMode` and
      `updateHoverStyle` take the mode itself, and the dataset test is
      `mode is DatasetInteractionMode`. A mode name is a foreign value: a debug build stops on it
      in `InteractionMode.of`, and a release build finds no item. The tests have no table either:
      the generators write the mode class into the reference data (`DartMode` of
      `tool/reference/scale_chart_common.mjs`), and a compare with upstream JSON text puts a
      marker on both sides (`withModeMarkers` of `test/support/mode_json.dart`). The typed API
      takes the same object (`ChartInteraction.mode`, `ChartTooltip.mode`). The option `axis` of
      the same scopes holds the enum `InteractionAxis` (`x`, `y`, `xy`, `r`; row
      `adapt-interaction-axis-enum`, the schema shape `interactionAxis`): the search code tests
      its values (`usesX`, `usesY`), a keyword stops a debug build in `InteractionAxis.of`, and the
      typed API has `ChartInteraction.axis` and `ChartTooltip.axis`. The scale option `axis` stays
      text. `layouts` is a record
      of `addBox`, `removeBox`, `configure` and `update`. A box is a `LayoutItem` of `lib/src/types/layout.dart`.
      The position of a box is the interface `LayoutPosition` of the same file (row
      `adapt-chart-position-enum`): the enum `ChartPosition` (`top`, `left`, `bottom`, `right`,
      `center`, `chartArea`) or, for a scale and the legend, `ScaleValuePosition(scaleId, value)`
      for the object form `{x: 0}`; also in a raw config.
      `layouts.removeBox` takes a `LayoutItem?` (Dart `null` is the JS `undefined` of a stop hook).
    - `core.animation.dart` and the port-only `animation_spec.dart` (`AnimationSpec`, the typed
      animation config) are pure layers. `core.animations.dart` and `core.animator.dart` are not:
      `core.animator` imports `helpers.extras` (Chart.js ADR 0019). `Animations` keeps
      `_properties` in a table by `AnimatedProp` id, and `properties` builds the Map view for the
      specs at each read. A property object animates by its typed keys, and the number path of
      an `Animation` writes an element through `Element.writeNumber` (Chart.js ADR 0054 §10). `core.animator.dart` has
      `getAnims`, `update`, the `@internal` class `Anims` and the field `refresh` (Chart.js ADR
      0029 §6). A fixture replaces `refresh` on the singleton (`harness-method-fields`).
    - The port-only `reduced_motion.dart` (a pure layer) has the reduced-motion flag of a canvas,
      an `Expando` (Chart.js ADR 0049 §7). Only `ChartView` sets it, from
      `MediaQuery.maybeDisableAnimationsOf`. `_createAnimations` of `core.animations.dart` reads
      it: with the flag, it reads no animation config (row `platform-reduced-motion`). No spec and
      no reference test sets it.
    - `core.scale.dart` has `Scale`, `Scale.jsClass` and the typedef `TickCallback`. The typedef
      `Tick` of `core.scale.js:15` is the native class `Tick` of `lib/src/types/tick.dart` (row
      `adapt-native-tick`). `core.scale.dart` and `core.scale.autoskip.dart` are not pure layers:
      `core.scale` imports `helpers.extras`, and `core.scale.autoskip` imports `core.scale`.
      `Scale` implements `MinMax`. Its value methods take `Object?` (Chart.js ADR 0025).
      `Scale._alignToPixels` is a `bool`, the `ToBoolean` of the option at its write in
      `configure` (row `adapt-loop-invariant-truthiness`).
    - [Chart.js ADR 0064](doc/adr/0064-axis-label-plan.md): the exact category scale reuses its string-label
      measurements. See `test/port/core/axis_label_plan_test.dart` and `category_label_source_test.dart`. Tick
      objects, contexts, callbacks and the fit stay live. A Flutter font notification (`canvas_font_tracking.dart`)
      ends the plans.
    - `scale_options.dart` (port-only, pure through `core.ticks`) has the typed facades of the
      scale options (Chart.js ADR 0054 §4): extension types over the `OptionView` of a scale.
      `Scale.options` is a `CoreScaleOptions`, and each scale class narrows it to the facade of
      its type. A getter gives the raw JS value, and the readers keep their JS operators. A
      nested facade (`TickOptions`, …) holds any JS value and reads with `readOption`.
      `TickOptions.format` gives the typed `NumberFormat?` of the tick option `format`. A getter
      of an on/off key of the scale and plugin facades gives a `bool` through `boolOption` of
      `helpers.config.dart` (Chart.js ADR 0121, row `adapt-bool-options`): an absent option is
      `false` (`includeBounds`: `true`), and another type stops a debug build.
    - [Chart.js ADR 0074](doc/adr/0074-incremental-data-updates.md): `Chart.updateData()` is an explicit data-only
      update. It returns `true` when it takes the data-only lifecycle, and `false` when it calls `update('none')`.
      Between two full updates, the caller changes only the data values. A change of the options, the labels, the
      datasets, the stacks or the visibility needs `update`. A plugin opts in with `supportsDataUpdates`. An enabled
      decimation declines. `data_update.dart` holds the native checks and the snapshots of the last full update. The
      typed facade registers its point containers through this framework-free contract. A font, size, DPR or
      structural change ends the kept layout. `update` keeps the full lifecycle. See
      `test/port/core/data_update_test.dart`.
    - [Chart.js ADR 0073](doc/adr/0073-sorted-bar-values.md): a linear scan removes the duplicates of the sorted
      finite bar values (`bar_sorted_values.dart`). See `test/port/core/bar_sorted_values_test.dart`. The helper
      stays a core-layer root of `tool/src/lib_imports.dart`, so that `test:web` runs its tests.
    - [Chart.js ADR 0071](doc/adr/0071-numeric-category-parsing.md): `primitive_parse.dart` parses native numeric
      data on a category scale for the bar and base controllers. See `test/port/core/primitive_parse_test.dart`.
      The preflight is local to each call, and each parsed item is fresh.
    - `core.datasetController.dart` has `DatasetController`, with the mixin `ArrayListener` and
      the class value `DatasetController.jsClass` (Chart.js ADR 0020). `_update` is `update_`, and
      `_getSharedOptions` is `getSharedOptions_` (Chart.js ADR 0023). `cloneIfNotShared` and
      `getSharedOptions` copy the typed element options with `clone` (Chart.js ADR 0021).
      `resolveDataElementOptions`, `resolveDatasetElementOptions` and `getStyle` return
      `ElementOptions`. `ctx` is writable, as the JS property `_ctx` (Chart.js ADR 0030).
      `updateElement` takes a `types.Element`, and `getLabelAndValue` gives
      `({Object? label, String value})` (Chart.js ADR 0028). The parse functions give
      `ParsedItem`; `_stacks` is an `ItemStacks` and the stack objects `StackEntry` (`stacksOf`,
      `axisStackOf`, `visualValuesOf`, `setStackValue`, all `@internal`); the dataset options are
      an `OptionView`; the contexts are typed `ScriptableContext` objects; `_cachedDataOpts` is
      two typed Maps (Chart.js ADR 0054 §8, §11). A parsed item reads with `parsedValueOf`
      (`@internal`, the `ScaleAxis` of the scale), a `TypedDataItem` of `parsing: false` gives its typed `x` or `y`, another data item of
      `parsing: false` and a `_stacks` object that user code gave read with `jsGetKey`. The index reads
      use `jsGetIndex` and `jsSetIndex`, and `getParsed` and the item reads of the parse functions read
      their List directly (Chart.js ADR 0096). `stacksOf` reads `item._stacks` of a parsed item, also of a List item,
      through an `Expando` (Chart.js ADR 0036).
      `_insertElements` keeps the old parsed item at each new index below the old length, as the
      upstream `move` does. `_dataCheck` keeps a string `data` as a `JsStringList`, with no array
      listener (`core.datasetController.js:386`).
      It is not a pure layer: it imports `core.animations`.
    - `core.typedRegistry.dart` (`TypedRegistry`) is a pure layer. `core.registry.dart`
      (`Registry` and the singleton `registry`) and `core.plugins.dart` (`PluginService` and the
      record `PluginDescriptor`) are not pure layers: `core.registry` imports
      `core.datasetController` and `core.scale` (Chart.js ADR 0020).
    - `core.controller.dart` has `Chart`. `resize` and `eventHandler` are fields that hold a
      function (Chart.js ADR 0022). `Chart.register` and `Chart.unregister` take one List.
      `Chart.registry` is a static field (Chart.js ADR 0020). `Chart.jsClass` is the class value
      with the statics of `core.controller.js:105-120` (Chart.js ADR 0048 §2), as are
      `Animation.jsClass`, `Animations.jsClass` and `FlutterPlatform.jsClass`. `toBase64Image`
      returns a `Future<String>` from `HTMLCanvasElement.toDataURL` (row
      `platform-to-base64-image`): each fake canvas of the tests has that member. The dataset meta is the public
      open class `ChartMeta<C extends DatasetController>` of `lib/src/types/chart_meta.dart` (row
      `adapt-native-chart-meta`, doc/native-chart-meta-design-draft.md), with no access by name;
      the chart gives `ChartMeta<DatasetController>`. `getDatasetMeta` computes its `final` `type`,
      its `label` and its `indexAxis`. Its `_dataset` is `datasetConfig`. `getDataVisibility` returns
      `true` at once for an empty `_hiddenIndices`. `toggleDataVisibility` takes any JS value
      (`Object?`) and writes the key `ToString(index)`, as upstream. `visible` is a `bool`,
      `stacked` the enum `StackMode`, `clip` a `ChartClip` with `double?` sides, and `stack` and
      the axis ids (`xAxisID`, `yAxisID`, `rAxisID`, `iAxisID`, `vAxisID`) are `String?`: a value
      that is not a string stops a debug build. The doughnut `total` is a field of
      `DoughnutController`. `_lastEvent` is `lastEvent` with
      `@internal`: the input reference test reads it after each step. `Chart.legend` is a field that
      the legend plugin writes. It is not a pure layer: it imports the platform layer.
    - [Chart.js ADR 0090](doc/adr/0090-replay-single-draw.md): `update` and `updateData` replay the last event
      through `_replayLastEvent`. With no queued animation, the replay skips its render, and the render after it
      draws once. Thus the draw hooks and `animation.onComplete` run once in such an update. The pixels do not
      change. See `test/port/core/core.controller_replay_test.dart`.
    - [Chart.js ADR 0091](doc/adr/0091-live-mouse-move.md): `ChartView` gives the chart `holdMouseMove`. A
      `mousemove` of a live chart (a config update in the last 34 ms of frame time, no queued animation) waits for
      the update of its frame, which replays it in place of the last event. `releaseHeldMove` handles a move that
      no update takes. A `Chart` with no `ChartView` keeps the upstream path. See
      `test/port/widgets/chart_view_live_mouse_test.dart`.
    - [Chart.js ADR 0092](doc/adr/0092-hidden-legend-items.md): a hidden legend of an exact built-in doughnut, pie
      or polar area chart builds `legendItems` at the first read that can run the build, not in `update`. Its guards
      run no user code. Row `adapt-hidden-legend-items` states the stale reads and the one count difference. See
      `test/port/plugins/plugin.legend_hidden_test.dart`.
    - [Chart.js ADR 0093](doc/adr/0093-arc-options.md): arcs take the native option paths: key snapshot, owned
      entry, templates, indexed and scriptable plans (`core/arc_options.dart`, `core/arc_option_preparation.dart`).
      See `test/port/controllers/arc_options_test.dart`. Generated clones share foreign slots with copy on write.
    - [Chart.js ADR 0094](doc/adr/0094-scatter-bubble-point-loops.md): the scatter overflow takes one point size,
      and the bubble parse and loops take native paths. See `test/port/controllers/scatter_point_size_test.dart` and
      `bubble_point_options_test.dart`. Plans end before user code, at the original reads. `DataPoint.bubble` works
      with `parsing: false` through the typed `r` in `_customOf` (row `adapt-bubble-typed-radius`).
    - [Chart.js ADR 0095](doc/adr/0095-radial-static-plans.md): the exact `RadialLinearScale` takes static plans
      for its fit, point labels and angle lines, and `RadarController` writes typed values. See
      `test/port/scales/scale.radialLinear_plans_test.dart` and
      `test/port/controllers/controller.radar_plans_test.dart`. Each plan is local to one loop and starts after one
      ordinary pass of the first index.
    - [Chart.js ADR 0096](doc/adr/0096-per-item-plumbing.md): the per-item reads are direct. `readOption` reads a
      typed scope through `OptionScope.readKey`, and the parse grows `meta.parsed` once. See
      `test/port/core/core.datasetController_plumbing_test.dart` and `core.datasetController_walk_test.dart`. A
      subclass of `OptionScope` that overrides `jsRead` must also override `readKey`.
    - [Chart.js ADR 0099](doc/adr/0099-hidden-legend-indexed-colors.md): a hidden legend also waits with native
      indexed arc options (`Config.prepareIndexedArcStyles`). See `test/port/plugins/plugin.legend_hidden_test.dart`.
      `OptionResolver.peekKey` writes no cache and makes no sub-resolver. A read of the items writes no context.
    - [Chart.js ADR 0100](doc/adr/0100-data-only-indexed-colors.md): `updateData` also takes a data element with no
      cached entry when `DatasetController.hasDataUpdateOptions` proves a native indexed plan. See
      `test/port/core/data_update_test.dart`. A function of a chart or plugin option in the defaults or overrides
      and a tick callback stay on the data-only path, under the contract of
      [Chart.js ADR 0074](doc/adr/0074-incremental-data-updates.md).
    - [Chart.js ADR 0101](doc/adr/0101-context-refresh.md): `ScriptableContext.refresh` writes the six keys of a
      data context with one mask test, and the prepared scatter loop leaves its refresh to the overflow pass. See
      `test/port/controllers/context_refresh_twins_test.dart`. A deleted key takes the setters in `getContext`
      order. A public `update` or `updateElements` keeps each context write.
    - [Chart.js ADR 0102](doc/adr/0102-direct-element-writes.md): in mode `none` or reset, the exact doughnut, pie,
      polar area and bubble controllers write built-in elements through typed setters. See
      `test/port/controllers/direct_element_writes_test.dart`. A user controller or element, another mode, an
      undefined value or another bubble axis takes `updateElement`.
    - [Chart.js ADR 0109](doc/adr/0109-previous-x-of-the-gap-test.md): the gap test of the line and scatter loops
      takes the x of the previous pass when no user code can run between the two reads (`NativeGapReads` of
      `point_options.dart`). `nativeGapReadsEnabled` (define `CHARTJS_NATIVE_GAP_READS`) and `nativeGapReadsTaken`
      serve the twins of `test/port/controllers/native_gap_reads_test.dart`.
    - [Chart.js ADR 0111](doc/adr/0111-range-updates.md): `Chart.updateRanges([mode])` (also on `types.Chart`) is
      `update(mode)` after a change of the `min` and `max` options of the scales only, written or deleted through a
      view of the options. It keeps the configuration of the last full update: no `config.update()`, no new
      resolver, no scale id, type or position checks and no `buildOrUpdateControllers`. Each hook, the layout, the
      dataset updates, the replay and the draw run as in `update`. `_canUpdateRanges` sends each other case to
      `update(mode)`, also a plugin without the opt-in or with a failed `Plugin.rangeUpdateGuard`. Options that only
      the skipped steps read (`responsive`, the chart `indexAxis`, the scale `axis` and `position`) and a
      `Chart.register` or `Chart.unregister` fall under the contract. It counts as a full update for re-entry, and
      ends as one (`_recordUpdateState`). Row `adapt-range-updates`. See `test/port/core/range_update_test.dart`.
    - `index.dart` has the exports of `src/core/index.ts`. `lib/src/index.dart` is the port of
      `src/index.ts`, with the four namespaces and `registerables`. The namespace `controllers` has
      the eight controllers of phase 7 and the namespace `plugins` has the seven plugins of
      `lib/src/plugins/index.dart`, both in code unit order. Thus `flutter_test_config.dart`
      registers them with the built-in components. The port has no UMD entry (Chart.js ADR 0120):
      `src/index.umd.ts` is `n/a`, the namespace cases of the spec `global.namespace` skip, and the
      spec `platform.dom` takes `FlutterPlatform.jsClass` as `DomPlatform` (row
      `platform-dom-platform-class`).
      `lib/src/types.dart` is the port of `src/types.ts`: `lib/src/index.dart` and
      `lib/src/types/index.dart` without the 8 names that both declare (row `adapt-types-entry`).
  - `lib/src/controllers/`: the eight dataset controllers of phase 7. `index.dart` exports them
    (the port of `src/controllers/index.js`). Each controller file has the
    controller class and its class value `<Name>Controller.jsClass` (statics `id`, `defaults`,
    `overrides`; the doughnut also `descriptors`). The parsed items are typed `ParsedItem`
    objects (Chart.js ADR 0054 §8) read with `parsedValueOf`; a data item of `parsing: false` reads with `jsGetKey`, or gives its typed `x` or `y` for a
    `TypedDataItem`; the properties are the props classes of `lib/src/options/props.dart`.
    A controller reads the stacks with `stacksOf` and `axisStackOf`, and a raw option value stays
    `Object?` until its upstream operator (Chart.js ADR 0036). It reads the members of other modules through
    `lib/src/types/` (Chart.js ADR 0028). It casts only to a `types` interface or to a class of
    its own library, at the upstream read. Three other kinds of casts stay: a `List` cast of a
    value that upstream reads as an array, the `String` cast of a parsing key and the `AnyObject`
    cast of an object that the controller made. `getLabelAndValue` gives
    `({Object? label, String value})`. Line, scatter and radar, and in a direct mode bubble, doughnut, pie and polar area (Chart.js
    ADR 0102), write an element of a built-in class (`typedWrites`, the exact-class rule of Chart.js
    ADR 0054 §9) through the port-only interfaces `types.PointElementWrites`,
    `types.LineElementWrites` and `types.ArcElementWrites`, which the concrete
    classes implement: no controller imports an element module (Chart.js ADR 0028 §1). The files
    are not pure layers: each imports `core.datasetController`.
    - `controller.bar.dart`: `getStackCount` and `getStackIndex` are the `_getStackCount` and
      `_getStackIndex` of upstream with `@internal`, because the spec reads them (Chart.js ADR
      0012).
    - `controller.line.dart`: `updateElements` reads each key of a parsed item once in a loop
      pass (`vValue`, `iValue`). It reads `prevParsed[iAxis]` at each pass, because the
      scriptable options of the user run between two passes (the 3-read form of Chart.js ADR
      0036), unless the guards of Chart.js ADR 0109 prove that no user code ran since the read of
      the previous pass: then the gap test takes the held x of that pass. It tests `_stacked` and
      `segment` once for each call (row `adapt-loop-invariant-truthiness`). `update` writes
      `_chart`, `_datasetIndex`, `_decimated` and `points` into the line with the typed setters
      of `types.LineElementWrites` for a line of the built-in class (`typedWrites`), by name
      (`types.PropertyAccess`) for another class, and `draw` casts the line to
      `types.LineElement`.
    - `controller.bubble.dart`: the parsed radius goes to `_custom`. `resolveDataElementOptions`
      copies the options with `values.clone()` and `storeKey(OptionKey.dollarShared, false)`
      (Chart.js ADR 0021 §3) and adds the radius with `jsAdd`: a string radius joins, as upstream.
      `getMaxOverflow` casts each data element to `types.PointElement` at `size`.
    - `controller.doughnut.dart`: `overrides` holds the tear-offs of the private top-level legend
      functions `_generateLabels` and `_onClick` (Chart.js ADR 0028 §6). `_onClick` gives the
      raw index of the legend item to `toggleDataVisibility`. `parse` reads a List or a string
      `data`. `controller.pie.dart` imports this file.
    - `controller.pie.dart`: `PieController extends DoughnutController` with the statics `id` and
      `defaults`. `PieController.jsClass` extends `DoughnutController.jsClass` and has its own
      `construct`. It reads `descriptors` and `overrides` through the superclass chain: the
      legend functions of `overrides['pie']` are the doughnut tear-offs (Chart.js ADR 0028 §6).
      Dart has no `PieController.overrides`: read `PieController.jsClass['overrides']`.
    - `controller.polarArea.dart`: it casts the scale `r` to `types.RadialLinearScale` once
      (`controller.polarArea.js:166`), and it ports the #12238 hunk with `== 0` and
      `== 'angular'`. `overrides` holds the legend functions as tear-offs of top-level functions.
      `parseObjectData` calls `parseObjectDataRadialScaleOf(meta.iScale, parsing, …)` and no
      longer uses `jsCall`.
    - `controller.radar.dart`: the write `line.points = points` is the typed setter of
      `types.LineElementWrites` for a line of the built-in class, by name through
      `types.PropertyAccess` for another class. `parseObjectData`
      calls `parseObjectDataRadialScaleOf(meta.iScale, parsing, …)` and no longer uses `jsCall`.
      The cast to `types.RadialLinearScale` stands in the loop of
      `updateElements`, at `controller.radar.js:88`. The label of `getLabelAndValue` is the raw
      label.
    - `controller.scatter.dart`: it imports `core.registry.dart`: `this.chart.registry` is the
      singleton `registry` (row `adapt-chart-registry-getter`). Its `updateElements` keeps the
      parsed values inside one pass (the 3-read form, as the line), and the x for the next pass
      only under the guards of Chart.js ADR 0109: the built-in scatter shares no options, so only
      the plan of indexed colors holds x. `delete meta.dataset` is
      `meta.dataset = null`. It has no `draw` override, as upstream.
  - `lib/src/plugins/` (Chart.js ADRs 0038-0041 and 0147): the seven plugins of phase 8.
    `index.dart` (the port of `src/plugins/index.js`) exports the plugin objects `colors`,
    `decimation`, `filler`, `legend`, `subTitle`, `title` and `tooltip`, with the export names in
    lowerCamelCase. Each plugin object is a native `Plugin` of `lib/src/types/plugin.dart` with the
    upstream keys in the upstream order (Chart.js ADR 0144); its hooks are private functions of
    the hook type `(chart, args, options)`. `filler`, `decimation` and `colors` are
    `Plugin<FillerOptions>`, `Plugin<DecimationOptions>` and `Plugin<ColorsPluginOptions>`: their
    hooks get the facade. `legend`, `title`, `subTitle` and `tooltip` are `Plugin<OptionView>`. The
    key `_element` of upstream has no field (the tests read `Legend.jsClass`, `Title.jsClass` and
    `Tooltip.jsClass`), and the decimation plugin has no `destroy`. The plugins read their options through the facades of
    the port-only pure `plugin_options.dart`. The library exports no class `Title`, `Legend` or
    `Tooltip`. `plugin.decimation.dart`, `plugin_options.dart` and the files of `plugin.filler/` are
    pure layers. The other plugin files are not: `plugin.title`, `plugin.legend` and
    `plugin.subtitle` reach `helpers.extras`, `plugin.tooltip` imports `core.animations`, and
    `plugin.colors` imports the controllers.
    - `plugin.colors.dart`: the plugin `colors` with the theme hunks H4a-H4c and H5 (Chart.js ADR
      0147 §2). H5 reads the palette from the theme map of the chart through `chartThemeOf` of
      `core.config.dart`. The doughnut and polar area colorizers throw a `TypeError` for a `data`
      that is not a List. The colorizers write a typed dataset scope through its typed keys, and
      the dataset Map of the user by name: a Map with a narrow value type or an unmodifiable Map
      throws (differences.md row `js-semantics-narrow-datasets`).
    - `plugin.decimation.dart`: the plugin object `decimation`. The `data` accessor of
      `plugin.decimation.js:249-265` is a plain entry with the getter value, an `Expando` with the
      last value that the plugin wrote, and a sync before each use (Chart.js ADR 0038 §8, row
      `adapt-decimation-data-accessor`). On a typed dataset scope, the accessor uses its typed keys
      `_data` and `_decimated`. `lttbDecimation` and `minMaxDecimation` are `@internal`:
      the pure test `test/port/plugins/plugin.decimation_algorithms_test.dart` calls them. They read
      the data items with the JS operators (`jsAdd`, `jsToNumber`, `jsToInt32`, `jsLessThan`). Data
      that is not a List throws a `TypeError` (row `js-semantics-decimation-data`). The option
      `algorithm` holds a `DecimationAlgorithm` (row `adapt-decimation-algorithm-objects`, the
      schema shape `decimationAlgorithm`), also in a raw config: an object with the method
      `decimate`. `LttbDecimationAlgorithm` and `MinMaxDecimationAlgorithm` (the default) are the
      algorithms of upstream; an app or a plugin gives its own as a subclass, with no
      registration. The base class is in the pure `decimation_algorithm.dart`. A value that is not
      an algorithm throws the `StateError` of upstream, and an algorithm name stops a debug build.
    - The scale options `bounds`, `ticks.source`, `ticks.align` and `ticks.crossAlign` hold the
      enums `ScaleBounds`, `TickSource`, `TickAlign` and `TickCrossAlign` of the pure
      `lib/src/core/scale_option_enums.dart` (row `adapt-scale-option-enums`), also in a raw
      config; the names of the values are the keywords, and a keyword stops a debug build. The
      typed API has `bounds` on the cartesian axes and `align`, `crossAlign` and `source` on
      `AxisTicks`. Each typed atom of the option model (a native type of an option that was a name
      in Chart.js) has the cell `classifyTyped<T>` of `opt.dart`, and `ShapeBits.typed` is the
      mask of their bits; the generator lists them in its map `typedAtoms`.
    - A font is a Flutter `TextStyle` from the option to the canvas (Chart.js ADR 0116, row
      `adapt-text-style-fonts`), also in a raw config: the options `font`, `titleFont`,
      `bodyFont` and `footerFont`, the canvas `font`, the font of a label item and the result of
      `toFont`. The port-only `ChartTextStyle` of the pure `lib/src/types/chart_text_style.dart`
      extends `TextStyle` with the field `lineHeight`, `fontSize * height`, which the constructor
      computes once; `merge` and `copyWith` give a new `ChartTextStyle`. The resolver merges the
      fonts of the scopes of a font option with `TextStyle.merge` (`_mergeTextStyles` of
      `helpers.config.dart`), as a route and `helpers.merge` do. The canvas lays out each text
      with the whole style. `toFontString`, `toLineHeight`, `ParsedFont`, the CSS parse of the
      canvas and the scope kind `FontSpec` are gone. A font function returns a `ChartTextStyle`;
      a font object stops a debug build in `toFont`. The generators write a font object of a
      config as a `ChartTextStyle` literal and a font text of the canvas as a record
      (`tool/reference/font_record.mjs`, `test/support/font_record.dart`).
    - The scale option `border` holds one `ScaleBorder` of the pure
      `lib/src/types/axis_border.dart` (Chart.js ADR 0141, row `adapt-native-scale-border`),
      also in a raw config: an `AxisBorder` (`display`, `color`, `width`, `dash`, `dashOffset`,
      `z`) for a cartesian scale and a `RadialAxisBorder` (`dash`, `dashOffset`) for the radial
      linear scale. The resolver merges the borders of the scopes with `ScaleBorder.merge`, as it
      merges the fonts (the kind 4 of `nativeMergeKind` and `mergeNativeOptionValues` of
      `helpers.core.dart`), and so do a route, `helpers.merge` and `mergeIf`:
      a border of the same class merges field by field, another class replaces. The radial
      defaults hold their own `RadialAxisBorder`, so the `AxisBorder` of `defaults.scale` never
      reaches a radial scale. The route `scale.border.color` is gone: a cartesian scale reads
      `defaults.borderColor` at its draw for an absent color. A function of the context gives the
      whole border, and a scale calls it with each tick context. A Map stops a debug build in
      `CoreScaleOptions.border`. The typed API has `border` on the six axes. In the tests, the
      generators write the classes in the input configs, and an observed border compares in the
      upstream form (`upstreamBorderOf` of `test/support/scale_border.dart`).
    - The `align` of the legend, the title, the subtitle and an axis title, and the `position` of
      the legend title, hold the enum `ChartAlign` (`start`, `center`, `end`) of the pure
      `lib/src/types/align.dart` (row `adapt-chart-align-enum`), also in a raw config. The
      helpers `alignStartEnd` and `toLeftRightCenter` take a `ChartAlign?`. The typed API takes
      the same enum. The text align of the legend labels is
      the Flutter `TextAlign`, as each text align (below).
    - The `xAlign` and `yAlign` of the tooltip (the options, the model and `TooltipPosition`) hold
      the enums `TooltipXAlign` and `TooltipYAlign` of `lib/src/types/align.dart` (row
      `adapt-tooltip-align-enums`); the typed API has `ChartTooltip.xAlign` and `yAlign`.
    - The text aligns hold the Flutter `TextAlign` (row `adapt-flutter-text-align`), also in a
      raw config: the canvas `textAlign`, `labels.textAlign` of the legend and a legend item,
      `titleAlign`, `bodyAlign` and `footerAlign` of the tooltip, a label item of a scale and the
      options of `renderText`. `canvasTextAlign` of `js_webidl.dart` reads an option value; a
      keyword stops a debug build. `TextAlign.justify` draws as `start`. The `'inner'` of the x
      labels of a scale is `TickAlign.inner`.
    - The arc options `borderAlign` and `spacingMode` hold the enums `ArcBorderAlign` and
      `ArcSpacingMode` of the pure `lib/src/types/arc_option_enums.dart` (row
      `adapt-arc-option-enums`), also in a raw config; the typed API has
      `ArcElementStyle.borderAlign` and `spacingMode`. The native option plans count an enum
      value as a scalar (`_indexedScalar` of `helpers.config.dart`).
    - The number format is package:intl as it is (Chart.js ADR 0119, row
      `adapt-intl-number-format`). The chart option `locale` holds a Flutter `Locale`, and the
      tick option `format` holds a `NumberFormat` of package:intl, also in a raw config; a
      language tag as text or an options object stops a debug build (`localeOf` and
      `numberFormatOf` of `helpers.intl.dart`, hidden in `lib/helpers.dart`). A `NumberFormat`
      formats a tick as it is. Without it, `formatters.numeric` formats through the internal
      `formatNumberDigits` (the decimal or the scientific pattern of the chart locale with the
      digits of the tick spacing). The port does not correct the defects of package:intl, and
      `lib/src/js/` has no number format code. The harness `acquireChart` writes the default
      `locale: Locale('en', 'US')`.
    - The doughnut and pie options `cutout` and `radius` hold a `RadiusLength` and the scale
      option `grace` a `GraceLength` (row `adapt-length-objects`), also in a raw config: the
      open bases of the pure `lib/src/helpers/radius_length.dart` and `grace_length.dart`, with
      the forms `PercentRadius` and `PixelRadius`, and `PercentGrace` and `ValueGrace`. Each
      form computes itself (`fractionOf`, `pixelsOf`, `amountOf`); a new form is a subclass.
      `toPercentage` and `toDimension` are gone, also from the UMD `Chart.helpers`. The typed
      API takes a `RadiusLength` (`ChartLength` is gone).
    - An axis is a class with no members of the pure `lib/src/types/chart_axis.dart` (row
      `adapt-axis-objects`), also in a raw config: `XAxis`, `YAxis` and `RAxis`.
      `CartesianAxis` (`XAxis` or `YAxis`) is the type of the `indexAxis` of a chart and of a
      cartesian dataset, also in the typed API (`indexAxis: const YAxis()`); the `indexAxis`
      defaults of doughnut, pie, polar area and radar hold `RAxis`, and `getIndexAxis` and
      `datasetIndexAxis` of `core.config.dart` take that `RAxis` first. `ScaleAxis` (any of
      the three) is the type of the scale option `axis`, `Scale.axis`, `meta.indexAxis` and
      `LayoutItem.axis`. The core matches an axis with pattern matching; `sameAxis` and
      `axisDataKey` of the pure `lib/src/core/chart_axis_reads.dart` compare two axes and give
      the key `x`, `y` or `r` of a plain object of the user. `AxisKey` is gone: `ParsedItem`,
      `ItemStacks`, `parsedValueOf`, `axisStackOf` and `setPointAxis` take the axis class, and
      `lookupByAxis` and `rlookupByAxis` of `helpers.collection.dart` search by it. A scale id
      `x`, `y` or `r` still gives its axis. An axis letter stops a debug build. A compare with
      upstream JSON text puts a marker on both sides (`withAxisMarkers` of
      `test/support/axis_json.dart`).
    - The option `fill` holds a `FillTarget` of the pure `lib/src/plugins/fill_target.dart`
      (Chart.js ADR 0140, row `adapt-fill-target-objects`), also in a raw config:
      `FillTarget.none` (`false`), `toOrigin` (`true` and `'origin'`), `toStart`, `toEnd`,
      `toStacked`, `shape`, `toDataset(i)` (a number), `toRelative(n)`, `toPrevious` and
      `toNext` (`'+n'` and `'-n'`), `toValue(v)` (`{value}`) and `target.split(above:,
      below:)` (`{target, above, below}`, the class `SplitFill`; a split never holds a split).
      `lib/chartjs.dart` exports the class and its subclasses. The decoded fill of a
      `FillerSource` is a `FillTarget` too, and the filler matches the subclasses; a boolean,
      a number, a Map or a text stops a debug build (`FillTarget.of`), and Dart `null` is no
      fill. `fillTargetTruthy` is the JS truthiness (`none` and `toDataset(0)` are falsy). The
      typed API takes the same object (`ChartFill` and `values.dart` are gone). In the tests,
      the generators write the `FillTarget` of each fill (`tool/reference/fill_target.mjs`), a
      split fill takes its colors from `nativeFixturePaint` of `chartjs_test_utils` (`pure.dart`),
      a JSON text compare puts a marker on both sides (`withFillMarkers` of
      `test/support/fill_json.dart`), and the 18 data fixtures of the moment skips take
      `FillTarget.none` for their `fill: false` (`nativeFixtureFalseFills`).
    - The option `pointStyle` holds a `PointStyle` or `false` (row `adapt-point-style-objects`),
      also in a raw config: an object with the method `draw(ctx, x:, y:, radius:, rad:,
      rotated:, width:, borderWidth:)`. The base classes `PointStyle` and `PathPointStyle` (the
      radius test, the path, the fill and the stroke around `addPath`) are in the pure
      `lib/src/helpers/point_style.dart`. The ten styles of upstream (`CirclePointStyle`, the
      default, to `TrianglePointStyle`) and `ImagePointStyle` (an image) are in
      `helpers.canvas.dart`. An app or a plugin gives its own style as a subclass, with no
      registration. `false` stays a boolean: the legend falls back to the dataset style on a
      falsy `labels.pointStyle`. A style name stops a debug build. The circle batch tests
      `CirclePointStyle`. The typed API takes a `PointStyle` (`ChartPointStyle` is gone);
      `pointStyle: false` goes through `extra`. A compare with upstream JSON text puts a marker
      on both sides (`withPointStyleMarkers` of `test/support/point_style_json.dart`).
    - The line option `cubicInterpolationMode` holds a `CubicInterpolationMode` (row
      `adapt-cubic-interpolation-mode-objects`), also in a raw config: an object with the methods
      `drawsCurves(tension)` and `updateControlPoints(points, tension:, loop:, indexAxis:)`. The
      base class is in the pure `lib/src/helpers/cubic_interpolation_mode.dart`, and the two modes
      of upstream, `DefaultCubicInterpolationMode` (the default) and
      `MonotoneCubicInterpolationMode`, are in `helpers.curve.dart`. An app or a plugin gives its
      own mode as a subclass, with no registration. A keyword stops a debug build. The typed API
      has `cubicInterpolationMode` on the line, scatter and radar datasets and on
      `LineElementStyle`. A compare with upstream JSON text puts a marker on both sides
      (`withCubicModeMarkers` of `test/support/cubic_mode_json.dart`). In the mask of `ShapeBits`
      of `opt.dart`, the seven plain atoms are bits 0 to 6, and a typed atom is its index from 1
      shifted left by 7: a shape holds at most one typed atom (`typedAtomBits` of
      `tool/src/options_gen.dart`).
    - The line option `stepped` holds a boolean or the enum `SteppedLine` (`before`, `after`,
      `middle`) of the pure `lib/src/types/line_option_enums.dart` (row
      `adapt-stepped-line-enum`), and the bar option `borderSkipped` holds a boolean or the enum
      `BorderSkippedEdge` of the pure `lib/src/types/bar_option_enums.dart` (row
      `adapt-border-skipped-enum`), also in a raw config. A keyword stops a debug build. The
      typed API has `stepped` on the line, scatter and radar datasets and on `LineElementStyle`;
      `stepped: true` and `borderSkipped` go through `extra`.
    - `plugin.filler/`: the 8 files of `src/plugins/plugin.filler/` (Chart.js ADR 0040).
      `index.dart` has the plugin `filler` and the source class `FillerSource`; `meta.$filler`
      is an entry of its own `Expando` (`fillerSourceOf`). The filler wraps each plain point of upstream
      in a `PointElement` with only the properties of the plain object (row
      `adapt-line-points-elements`): the boundary points, the radial polygon, the edge objects of
      `segments` and the results of `interpolate` in the stack line (`stackResultPoint`; an Array
      gives a bare point). `filler.drawing.dart` dispatches on `types.LineElement` and
      `types.SimpleArc` (row `adapt-filler-target-classes`). `SimpleArc` of `simpleArc.dart` does
      not implement `types.LineElement`. `PointElement` stays the only implementer of the point
      interfaces in `lib/` (`test/port/plugins/plugin.filler/point_implementers_test.dart`).
      The option `drawTime` holds the enum `FillerDrawTime` of the pure
      `lib/src/plugins/filler_draw_time.dart` (row `adapt-filler-draw-time-enum`), also in a raw
      config; the typed API has `ChartFiller.drawTime`.
    - `plugin.legend.dart`: `Legend` (extends `Element`, implements `types.LegendElement`,
      `LayoutItem` and `TRBL`) with `Legend.jsClass`, and the plugin `legend`. The items of the
      built-in `generateLabels`, the hit boxes (`legendHitBoxes`, also a port-only member of
      `types.LegendElement`, which the keyboard of `ChartView` reads, Chart.js ADR 0051 §2) and the
      column sizes use the shared native `LegendItem` and `LegendHitBox`, and the Flutter `Size`
      (`columnSizes` is a `List<Size>?`). `LegendItem` is extensible, with mutable native fields and
      overridable `copyWith`/`merge` methods (doc/native-legend-item-design-draft.md).
      Generators, rendering and events share that object by identity. Map items, `TypedLegendItem`
      and `ChartLegendItem` are removed. `LegendHitBox` replaces `types.TypedLegendHitBox`: mutable
      double geometry, fixed integer row/column membership, and overridable `contains`, `center`,
      `copyWith` and `merge` (doc/native-legend-hit-box-design-draft.md). Pointer and keyboard
      consumers use the same boxes. `LegendHitBoxX.equalsTo` lives beside the class,
      compares shared fields with the reference-test numeric tolerance, and preserves identity `==`/hashing.
      A tooltip item is the native `TooltipItem` (row `adapt-native-tooltip-item`).
      Legend indexes are nullable integers; a descriptive item has no default click action
      (row `adapt-native-legend-item`).
    - `plugin.subtitle.dart` has the plugin `subTitle` (no `_element`). Its box is a `Title` of
      `plugin.title.dart`, and the `WeakMap` of upstream is a file-private `Expando<Title>`
      (Chart.js ADR 0038 §5).
    - `plugin.title.dart` has `Title` (`extends Element implements LayoutItem`, the class value
      `Title.jsClass` with the superclass `Element.jsClass`) and the plugin `title`. The box
      fields start as NaN, `undefined` and `false`. `draw` takes an optional chart area.
      `chart.titleBlock` is a field of `types.Chart`: Dart `null` is the JS `undefined` (Chart.js
      ADR 0038).
    - `plugin.tooltip.dart` has `Tooltip extends Element implements types.TooltipModel`, the two
      positioner classes, the default callbacks and the plugin `tooltip` (Chart.js ADR 0039). The
      option `position` of the tooltip holds a `TooltipPositioner` (row
      `adapt-tooltip-positioner-objects`, the schema shape `tooltipPositioner`), also in a raw
      config: an object with the method `positionOf(tooltip, items, eventPosition)`, which gives a
      `TooltipPosition` or Dart `null`. `AverageTooltipPositioner` (the default) and
      `NearestTooltipPositioner` are the positioners of upstream. An app or a plugin gives its own
      positioner as a subclass, with no registration. `lib/` has no positioner names and no table:
      `Tooltip.positioners`, the static of `Tooltip.jsClass` and the plugin key `positioners` are
      gone. A positioner name stops a debug build in `TooltipPositioner.of`. The base class and
      `TooltipPosition` are in the pure `tooltip_position.dart`, because `opt.dart` reads the
      type. The generators write the positioner class into the reference data (`DartPositioner`),
      and a positioner of a test has the name `'fn:positioner:<key>'` there. The typed API has
      `ChartTooltip.position`. The tooltip items and body items are the native `TooltipItem` and
      `TooltipBodyItem` of `lib/src/types/tooltip_item.dart` (row `adapt-native-tooltip-item`). The
      label colors, label point styles and positions are typed classes (`TooltipLabelStyle`,
      `TooltipLabelPointStyle`, `TooltipPosition`). The access by name
      covers its 28 own names and `_ignoreReplayEvents`: `operator []` and `operator []=` handle
      the 24 names that `Element` does not handle. `update` is a field that holds a function (row
      `harness-method-fields`). The hooks cast `chart.tooltip` to `Tooltip`.
  - `lib/src/scales/`: the six scales of `scales/index.dart` and `scale.linearbase.dart`
    (`LinearScaleBase`: not exported, not registered). They are not pure layers: each imports
    `core.scale`. The value methods take any JS value (`Object?`). The category, linear and
    logarithmic `getPixelForValue` and the time `getDecimalForValue` have a port-only
    `value is double` fast path (Chart.js ADR 0025). The `_` members that another file or a spec
    reads drop the underscore: `startValue`, `endValue`, `valueRange`, `offsets`, `generate`,
    `unit`, `adapter`, `pointLabels`, `pointLabelItems`. The time scales read each date through
    `adapters._date` (Chart.js ADR 0024). A category `parse` of a value that is not a String skips
    the label scan for a native `List<String>` (row `adapt-category-string-labels`).
  - `lib/src/canvas/`: the port-only canvas layer (Chart.js ADRs 0055 and 0015). `canvas.dart` is
    the Canvas 2D interface, a pure layer. `canvas_ui.dart` and its four parts
    (`canvas_ui_path.dart`, `canvas_ui_paint.dart`, `canvas_ui_text.dart` and
    `canvas_ui_batch.dart`, the circle batch) are the `dart:ui` implementation. No helper imports
    them. `canvas_ui.dart` reflects the `style` attribute of the canvas. Other attributes keep their
    values as strings (Chart.js ADR 0022). The canvas `textBaseline` holds the enum
    `CanvasTextBaseline` of `canvas.dart` (row `adapt-canvas-text-baseline-enum`), also in a label
    item and in the options of `renderText`.
    - [Chart.js ADR 0070](doc/adr/0070-native-rectangular-bar-drawing.md): an ordinary bar rectangle draws through
      the optional `RectBarCanvas` operation of the native context. See
      `test/port/canvas/canvas_rect_bar_test.dart`. A declined call changes no canvas state. The current path stays
      the inner rectangle.
    - [Chart.js ADR 0084](doc/adr/0084-scalar-circles-and-compact-paths.md): the native context reads a full
      circle as scalars, and `Path2D` packs unread move, line and close commands. See
      `test/port/canvas/canvas_test.dart` (group `compact native Path2D`). The first read of `commands` makes one
      stable mutable list. Public and custom replay keep the ordinary loop. Only `uiPathOf` takes the scalar replay.
    - [Chart.js ADR 0085](doc/adr/0085-chunked-path-storage.md): the compact path storage grows to chunks of 1,024
      commands and never copies a full chunk. See `test/port/canvas/path_chunks_test.dart`. No buffer is shared
      across paths, because a user can keep and read an old path.
    - [Chart.js ADR 0106](doc/adr/0106-canvas-shadows.md): the canvas has `shadowBlur`, `shadowColor`,
      `shadowOffsetX` and `shadowOffsetY`, for plugins: no ported caller reads them. `_castShadow` of
      `canvas_ui.dart` draws the shape with a blur mask filter before the shape. Each fast path declines while
      `_State.shadowOn` is true. See `test/port/canvas/canvas_ui_shadow_test.dart`, which the CI job
      `test-impeller` also runs.
    - Chart.js ADRs 0107 and 0139: each typed dataset has `shadow`, a `ChartShadow` of the core file
      `lib/src/types/chart_shadow.dart` (exported by `chartjs.dart`). The dataset option `shadow` (the
      typed atom `chartShadow` of the schema, port-only) holds the `ChartShadow` itself, in typed and raw
      configs; the native option plans and the data-only check accept it, so the data-only path stays.
      The `$chartView` plugin of `ChartView` reads it with `readOption` and sets the four canvas
      attributes around the draw of the dataset; another value stops a debug build. The area fill has
      no shadow, and the shadow does not cascade. See `test/port/widgets/chart_view_shadow_test.dart`.
    - [Chart.js ADR 0113](doc/adr/0113-stroke-pieces-by-browser-system.md): on the web only, a long `Path2D`
      stroke and a one-color line fill to `origin`, `start` or `end` draw in pieces with small bounds
      (`UiPathPieces`, `UiPathBuilder.tryFillColumns`). A stroke takes pieces from
      `UiCanvasContext.strokePieceMinCommands` commands: 2 on a desktop browser system, else 128. Native engines
      keep one draw. The switch `debugDrawLongPathsInPieces` turns the form on for a test on the VM, and
      `debugDefaultTargetPlatformOverride` picks the rule. See `test/port/canvas/canvas_ui_pieces_test.dart`.
    - [Chart.js ADR 0114](doc/adr/0114-dense-curve-merge.md): on a native context, the curves of a dense line
      that lie within half a bitmap pixel in x become lines through their extremes (`writeDenseCurve` of
      `lib/src/elements/line_dense_curve.dart`). Below 2 points for each bitmap pixel the bytes are the same. Hit
      tests and `interpolate` read the points and do not change. The switch `denseCurveMergeEnabled` (define
      `CHARTJS_DENSE_CURVE_MERGE`) and the counter `denseCurvesMerged` serve the twins of
      `test/port/elements/line_dense_curve_test.dart`.
    - [Chart.js ADR 0104](doc/adr/0104-line-curve-draw.md): a dense line draws with packed cubic curves, a
      deferred filler path, a one-scan bound of an ascending segment and a run of circle markers. See
      `test/port/elements/element.point_circle_run_test.dart`. A read of a deferred path gets the same path.
      `PointElement.drawCircleRun` (`canvas_circle_run.dart`) ends its run at the first element or state that it
      does not take, and `DatasetController.draw` draws the rest in order.
    - Once the batch took a circle of a run, `CircleBatch.hold` keeps the run while it has one
      radius, no varying radii and the identical last colors, and `tryAddRunCircle` appends each
      further fill and stroke with `addHeld`, with no test: the batches, the flush points, the draw
      calls and the pixels stay. Another add, a flush, a clear and the start of a run end it. See
      `test/port/canvas/canvas_ui_circle_run_test.dart` (`debugHoldCircleRuns`,
      `debugRecordingCanvas`) and performance.md §69.
    - [Chart.js ADR 0103](doc/adr/0103-radial-line-fan.md): on Impeller, the static angle-line plan draws the
      lines after the first in one `drawRawPoints` call (`LineFanCanvas` of `canvas_line_fan.dart`). See
      `test/port/canvas/canvas_line_fan_test.dart`. Tests on software Skia set `debugLineFanWithoutImpeller`. On
      Impeller, they run with no switch (`test/port/canvas/line_fan_engine.dart`). The CI job `test-impeller` runs
      `canvas_line_fan_test.dart` and `scale.radialLinear_line_fan_test.dart` with `--enable-impeller` and
      `CHART_IMPELLER=1`. That variable fails a run that is not on Impeller.
    - [Chart.js ADR 0097](doc/adr/0097-native-chart-drawing-routes.md): live charts take native drawing routes:
      chunk pictures, fused arc sectors, a ladder atlas of circle fills and `drawLine` for a single-line stroke. See
      `test/port/platform/chart_host_scene_test.dart` and `test/port/canvas/canvas_ui_ladder_test.dart`. Adjacent
      sectors of one color collapse into one `drawArc`, so the seams go (row `adapt-sector-run-seams`). A color
      that 32 bits of sRGB do not keep joins no circle batch (`batchKeepsColor`). Each guard declines before any
      state change.
    - [Chart.js ADR 0066](doc/adr/0066-bounded-canvas-recordings.md): a native recording ends after 256
      non-batched paint calls, and more than eight paint generations flatten into one image. See
      `test/port/canvas/canvas_ui_chunks_test.dart`. Circle runs keep their batching and do not count.

  - `lib/src/platform/` (Chart.js ADR 0037): the ports of `index.js`, `platform.base.js` and
    `platform.basic.js`, and three port-only files. `platform.flutter.dart` replaces
    `platform.dom.js`. `chart_host.dart` is the internal chart host (`ChartHost`,
    `RenderChartHost`). A touch tap gives the compatibility mouse events. A tap outside gives
    `mouseout` to the chart of the last tap (Chart.js ADR 0037). A resize observer gets its first
    notification at the next layout of the host. `flushCanvasMutations` is the mutation checkpoint of the harness (Chart.js ADR 0022).
    `onFirstLayout` is the start hook of the owner of the canvas: `ChartView` starts its chart in
    it (Chart.js ADR 0049 §2). The keyboard of `ChartView` sends its events through
    `dispatchCanvasEvent` (`canvas.dispatchEvent`).
    `native_event.dart` is the stand-in for the DOM event, a pure layer.
    Chart.js ADR 0108 (the input surface for add-on plugins): `NativeEvent` has the DOM fields with
    the DOM init defaults (`bubbles`, `cancelable`, `clientX`, `clientY`, `button`, `buttons`,
    `pointerId`, `pointerType`, `deltaX`, `deltaY`, `deltaMode`, `key` and the four modifiers),
    `defaultPrevented`, `preventDefault()` and `stopPropagation()`; a dispatch sets `target`. The
    host fills the fields with the Chrome values. `native_event.dart` also has
    `NativeEventListener`, `NativeEventTarget` and `DOMRect`. The extension `CanvasEventTarget`
    of `chart_host.dart` gives each canvas `addEventListener` (with `passive`),
    `removeEventListener`, `dispatchEvent`, `ownerDocument`, `eventTarget` (one object for each
    canvas) and `getBoundingClientRect()` (the canvas box in the logical pixels of the view,
    `DOMRect.zero` without a laid-out host). The four registry functions stay internal;
    `dispatchCanvasEvent` gives `!defaultPrevented`. `CanvasDocument.instance` is the one document
    of the isolate: a bubbling canvas event reaches its listeners after the canvas listeners; a
    mouse that went down on the host gives it `pointermove`, `mousemove`, `pointerup`, `mouseup`,
    `click` and `pointercancel` while it is outside the box; while it has a key listener, one
    `HardwareKeyboard` handler sends it each key (`domKeyValue`), before the focus tree. The key
    events of `ChartKeyboard` do not bubble; its virtual mouse events bubble with the mouse fields.
    With `touch-action: none` in the canvas style at the start of a touch sequence, the host
    begins no pan and claims its touch pointers in the gesture arena past the slop or at a second
    finger; a prevented `wheel` claims the pointer signal. `platform.flutter.dart` registers its
    listeners with `passive: true`. `CssStyleProperties` of `lib/src/canvas/canvas.dart` gives
    `style.touchAction`, `style.userSelect` and `removeProperty`. See
    `test/port/platform/chart_host_test.dart` (groups `canvas event target`, `document target`,
    `getBoundingClientRect`, `touch sequence`) and `native_event_test.dart`.
    [Chart.js ADR 0137](doc/adr/0137-trackpad-wheel-events.md): a trackpad scroll gives a `wheel` with the scroll
    deltas, and a trackpad pinch a `wheel` with `ctrlKey` and `deltaY` -100 times the natural log of the scale
    step, as Chrome sends them. A prevented `wheel` takes the gesture from the arena.
    `ChartView.trackpadGestures` (default true) turns it off. See the trackpad cases of `chart_host_test.dart`.
  - `lib/src/theme/` (Chart.js ADR 0147, port-only): `compile.dart` has `compileChartTheme` and
    the deep freeze. `compileChartTheme` takes the typed tokens as named
    parameters (Chart.js ADR 0147 §10): 6 `Color?` tokens, 2 `TextStyle?` fonts, `palette` and
    `paletteBackgroundAlpha`. It gives a deep-frozen typed `ChartOptionsScope` tree (Chart.js ADR
    0054 §3) that holds each color token as the app gives it: no 8-bit rounding, no clamp, no
    change of the color space. No token name is a string, and no Map theme exists. It writes each
    key of the token table of theming.md §4 with the typed setter of its scope, so it has no
    emission guard (Chart.js ADR 0147 §7). `presets.dart`
    has `LightThemeTokens`, the internal constants of the light tokens. Both files are pure
    layers. The pure tests compile the light tokens through `compileLightTheme()` of
    `test/support/light_theme.dart`. `theme_data.dart` has the public `ChartThemeData` (Chart.js
    ADR 0147 §10): the same tokens, the presets `.light()` and `.dark()` (the mirror rule, from
    `LightThemeTokens`), `copyWith`, `lerp` and deep `==`, and the internal `compileThemeData`,
    which gives the fields to `compileChartTheme` (no memo: the theme switch keeps the compiled
    scope of its current theme). `chart_theme.dart`
    has `ChartTheme`, an
    `InheritedTheme` with a non-null `data` (`maybeOf` for charts, `of` with the light fallback).
    Both import Flutter: they are not pure layers. Ported files never import a file of
    `lib/src/theme/`. `test/port/theme/coverage_test.dart` (theming.md §8 test 4) compares
    `light_snapshot.json` with the defaults inventory of `doc/upstream/manifest.json`.
    `THEME_SNAPSHOT_UPDATE=1` writes the snapshot again. `theme_data_test.dart` and
    `chart_theme_test.dart` have test 7. `light_pixels_test.dart` checks that the light preset
    paints the bytes of an unthemed chart (16 cases, also on the `test` job of each OS), and
    `blue_screen_test.dart` also has 16 cases with an active element. `goldens_test.dart` (test 9,
    the tag `golden`, `test:goldens`) compares `test/port/theme/goldens/bar_light.png` and
    `bar_dark.png`.
  - `lib/src/typed/` (Chart.js ADR 0052, port-only, not pure layers): the typed public API.
    `typed.dart` is its export list of 69 names. 26 of them are the classes of
    `lib/src/options/property_animation.dart` (row `adapt-property-animations`): the items of
    `ChartConfig.animations` (the abstract `PropertyAnimation` and one ready class for each of the
    19 animated properties of the elements: `RadiusAnimation`, `BorderColorAnimation`, ...) and of
    `ChartConfig.transitions` (the abstract `ChartTransition` and one ready class for each update
    mode: `HoverTransition`, `ShowTransition`, `HideTransition`, `ResizeTransition`,
    `ResetTransition`). `AnimationSettings` is their base with the four parameters `duration`,
    `delay`, `easing` and `loop`; `ChartAnimation` extends it too. The type of an item names its
    property or its mode: an item has no other name of it and no key. The chart reads its own
    classes by type and leaves a class of another library to that library. A built-in
    `AnimatedProp` has its animation class as a type argument (`_AnimatedBy<RadiusAnimation>`), and
    `AnimatedProp.itemIn` finds the item of a property by the type of the item, with no table. The
    Lists are the fields `propertyAnimations` and `chartTransitions` of `Chart` (the interface
    `ChartAnimationItems`): `ChartView` gives them to the constructor and at each new config. No
    lowering copies an item: `DatasetController.resolveAnimations` gives the Lists to `Animations`,
    and `Animation` reads the parameters of the item itself. The `ChartAnimation` of
    `ChartConfig.animation` goes the same way for `duration`, `delay`, `easing` and `loop`: each of
    these cells of `options.animation` holds the `ChartAnimation` itself, not a copy, and
    `core.animation.dart` reads the parameter from it (`AnimationSettings`). Thus the lowering has
    no `millisecondsOf` for an animation. A color animates with no `type` (row
    `adapt-color-animation-by-value`). `config.dart` has `ChartConfig` and `ChartKind`; its
    `indexAxis` takes a `CartesianAxis` of the core. `datasets.dart` has the 8 dataset classes under `abstract final class Dataset`
    and `DataPoint`, a final class that implements `TypedDataItem`.
    `chart_value.dart` has sealed `ChartValue<T>` and its constant/indexed/resolver
    variants. All dataset background/border, hover and point-specific paint fields
    use `ChartValue<ChartPaint>?` (ADR 0128); lowering writes the corresponding
    `Opt` cell directly. Scalar element/text/scale fields use `ChartPaint`; raw
    configs keep value/list/function forms with paint leaves. `axes.dart` has the 6 axes,
    `AxisTicks`, `AxisGrid` and `AxisTitle`; an axis takes its `border` as an `AxisBorder` (a
    `RadialAxisBorder` for `RadialLinearAxis`) of `lib/chartjs.dart` (Chart.js ADR 0141).
    `groups.dart` has `ChartLegend`, `ChartTitle`, `ChartTooltip`, `ChartFiller`,
    `ChartInteraction` and `ChartAnimation`. `elements.dart` has `ChartElements` and the 4 element
    styles. `callbacks.dart` has `ChartScript` and the views with `int` indexes;
    `ChartContext` is a view over the typed contexts. The event callbacks take the function types
    of the core (Chart.js ADR 0130). Each
    config class is `@immutable` and `final`, with a `const` constructor, `copyWith`, and `==`
    from its `_props` list (`props.dart`). Each class has `extra`, the Chart.js options with no
    parameter. `lower.dart` (internal) gives the typed option scopes of the chart for a config
    (`ChartConfigLowering`: a `ChartConfigurationScope` root, `put`, the typed `mergeExtra`). A
    paint and a font go to the chart as the `ChartPaint` and the `TextStyle` themselves (Chart.js ADRs
    0116 and 0147). Ported files never import
    `lib/src/typed/`, and no file of it imports
    a component (`check:lib-imports`).
  - `lib/src/widgets/` (Chart.js ADRs 0049-0051, port-only, not pure layers). No file of it
    imports a component or an index of the components (`check:lib-imports`), and no file writes
    `defaults` or `overrides`.
    - `chart_view.dart` has `ChartView`, with the typed entry `ChartView(config: ChartConfig)` and
      the raw entry `ChartView.raw(config: Map)` (Chart.js ADR 0052 §9). A typed config lowers
      through one `ChartConfigLowering` of `lib/src/typed/lower.dart` for the life of the state. A
      new typed config that is `==` to the last one gives no update. `==` compares the data Lists
      by identity and the event and text callbacks by presence: these callbacks are trampolines
      to the callback of the newest config, and a new closure of a scriptable color or a tick
      format is a new value. Another config reconciles with the live typed scopes: a dataset
      keeps its scope, its meta and its hidden state by its `key`, or without a key by its index
      and class.
      The README states these rules for apps. The widget keeps one `UiCanvasElement` for the life
      of its state and starts the chart in `ChartHost.onFirstLayout`. The chart gets a typed root
      scope (`ChartConfigurationScope`): the top-level values of the app config, with `$theme` and
      the widget plugin. A new config, a new
      theme and a change of the reduced-motion preference reach the chart in one post-frame
      callback (Chart.js ADR 0049 §4). `build` sets the reduced-motion flag from
      `MediaQuery.maybeDisableAnimationsOf`. A chart under `TickerMode(enabled: false)` is muted.
      `dispose` destroys the chart and disposes the context. A `Focus` and a `Semantics` node
      (`container`, `image`, `semanticLabel`) wrap the host (Chart.js ADR 0051 §1 and §8).
      [Chart.js ADR 0098](doc/adr/0098-chart-view-data-only-updates.md): `ChartView.dataOnlyUpdates` (typed only,
      default false) calls `chart.updateData` when `ChartConfigLowering.apply` reports `lastApplyDataOnly`: equal
      type, options and plugins, the same labels List, kept dataset scopes, and each patch changed only `data` or
      stored a style List with equal items. It needs mode `'none'` and `animation: false`, else
      `chart.update(mode)`. A theme or reduced-motion update stays full. All checks of
      [Chart.js ADR 0074](doc/adr/0074-incremental-data-updates.md) stay in `updateData`. A category scale also needs
      `bounds: 'ticks'` and no added label. After `afterUpdate`, the replay and the draw act as in `update`: their
      callbacks can call `update`. See `test/port/widgets/chart_view_data_only_test.dart`.
    - `chart_theme_switch.dart` has `ChartThemeSwitch`, the runtime theme switch (theming.md §3.7):
      the entry `$theme`, the in-place restore of the user `scales` and of the palette keys, and
      one update with `'theme'`, `'themeFrame'` or `'default'`.
    - `chart_view_plugin.dart` has the inline plugin `$chartView`, last in the `plugins` List of
      the root Map: the palette records of the switch and the focus ring.
      `plugins.$chartView: false` turns it off.
    - `chart_keyboard.dart` has `ChartKeyboard` (Chart.js ADR 0051): the keys move a virtual mouse
      over the legend hit boxes (through `types.LegendElement`) and the data elements, and send
      `mousemove`, `mousedown`, `mouseup`, `click` and `mouseout` `NativeEvent`s to the canvas.
      When `options.events` lists `keydown`, `keypress` or `keyup`, it also sends these key events
      with NaN offsets (Chart.js ADR 0051 §5).
    - `test/port/widgets/` (VM only): `chart_view_test.dart` (the start, the life cycle and the
      keys, the diagnostics, the update, the size, the callbacks and reduced motion),
      `chart_view_unregistered_test.dart` (it calls `removeBuiltins()` first in `main()`),
      `chart_theme_switch_test.dart` (theming.md §8 test 8), `chart_keyboard_test.dart` and
      `chart_view_semantics_test.dart` (Chart.js ADR 0051). A test that pumps a `ChartView.raw`
      gives it a config that is not `const`: Chart.js writes into its `data` and `options`. The
      tests of the typed path are `test/port/typed/reconcile_test.dart`, `change_test.dart` and
      `docs_twins_test.dart`.
  - `test/flutter_test_config.dart`: the port of `test/index.js`. `flutter test` runs it around
    each test file of the package ([Tests](#tests)).
  - `test/specs/`: ported upstream specs.
    `test/port/`: port-only tests, at the path of the `lib/src/` file that they test.
    `test/port/options/` has the oracles of the typed internal model (Chart.js ADR 0054). O1,
    `observation_test.dart`, runs 727 configs (the hand fixtures, the pure data fixtures of
    `doc/upstream/fixtures.json`, the benchmark and focused configs and the configs of the D2
    trace) twice, as given and with a recorder of each user function. After the construction and
    after each of 8 steps it writes a text of JS kinds only (no Dart class name of an option
    object, no `int` marker, a number through `jsNumberToString`): the resolved options with
    their key order, `$shared`, the element properties, `getProps`, the contexts, the animations,
    the active-mode options, the active elements, the draw calls and the user calls. It compares
    the SHA-256 of each text with `observation_digests.dart` on macOS. `O1_UPDATE=1` writes the
    digests, only after a reviewed behavior change; `O1_DUMP=<dir>` writes the texts;
    `tool/observation_diff.sh <base>` writes the texts of a base commit and of the tree and lists
    the files that differ. `key_census_suite.tsv` and `key_census_fixtures.tsv` are the key
    census of the raw configs on the Map model (O2, the input of the option schema).
    `schema_test.dart` is the schema drift test: each path of the defaults inventory of
    `doc/upstream/manifest.json` maps to a declared key and fits its shape, each census path
    maps to a key or to a reviewed extra of `census_review.tsv` (each recorded kind in the shape
    or a reviewed foreign pair), and the built typed roots `defaults`, `overrides` and
    `descriptors` equal the inventory in values and key order (a function default by its
    presence; each object is a typed scope). A bump edits the schema for keys and kinds and the
    component file for values; the test fails until both equal the new inventory. `opt_test.dart` and `option_scope_test.dart` test the cells and
    the scopes on the VM, dart2js and dart2wasm. O1 and O2 stay after the close step of Chart.js
    ADR 0054; the oracle O3 and the frozen Map resolver of `test/support/legacy/` are gone. A test
    reads a typed object through the face (`JsObjectFace`) or its typed members, never as a
    `Map`. O2: `foreign_audit.dart`
    has the reviewed set `reviewedForeignPairs` (one TSV line `owner<TAB>key<TAB>kind` for each
    pair). `flutter_test_config.dart` sets the hook `foreignAudit` before each test file and fails
    the file on a foreign pair that the set does not list (row `harness-foreign-audit`). A new pair
    gets a review of the readers of its key, then a line in the set.
    `--dart-define=O2_COLLECT=true` prints the pairs of each file and checks nothing.
    `test/port/scales/scale_chart_harness.dart` and `scale_time_harness.dart` are helper libraries
    of the scale tests, not test files. `test/port/controllers/` has the controller reference tests
    and their harness `controller_chart_harness.dart` (a library). `controller.<name>_test.dart`
    compares the charts of `tool/reference/controller_<snake>_reference.mjs` (data
    `controller_<snake>_reference.dart`; `<snake>` is `polar_area` for `polarArea`): each
    controller except pie. Pie has no reference test and no spec file: it changes only the defaults
    of the doughnut. `test/port/plugins/` has the plugin reference tests and their
    harness `plugin_chart_harness.dart` (a library). `plugin.<id>_test.dart` compares the charts of
    `tool/reference/plugin_<id>_reference.mjs`. The filler tests are in
    `test/port/plugins/plugin.filler/`. `test/port/plugins/index_test.dart` compares the hook
    dispatch of the seven plugins with `plugin_dispatch_reference.dart`.
    `test/port/canvas/path2d_record.dart` (the record form of `Path2D` arguments) and
    `test/support/jasmine.dart` (the Jasmine matchers and spies of the spec ports) are pure helper
    libraries. `test/tool/`: tests of the port tools.
  - `test/fixtures/` (Chart.js ADR 0029): `index.dart` is the registry of the fixture runner, not a
    test file. It has `specs` (`jasmine.fixture.specs` of `test/index.js:15-17`), `handFixtures`
    (367 hand ports, each with the first 12 hex digits of its manifest `sha256`) and `fixtureSkips`
    (39 skips, all `diverges: adapt-date-moment-format`). `hand/<path>.dart` is the hand port of the
    impure config `test/fixtures/<path>.js` of the pin, with the function `fixture()`. A pure data
    config whose config holds a keyword of an option with a class value (the 22 data fixtures with
    `cubicInterpolationMode`, the 25 with `pointStyle`, the 142 with a `fill` (Chart.js ADR 0140;
    the other 18 are moment skips), the 19 with a scale `border` (Chart.js ADR 0141), the 8 with
    a length, the 35 with an axis letter and the 1 with a constant `segment` style) also has a
    hand port, of `<path>.js` or
    `<path>.json`, with the
    config of `fixtures.json` (Chart.js ADR 0115): the registry test lists the option keys, and
    O1 runs such a fixture from its hand port only.
    `test/port/fixtures/index_test.dart` checks the registry against the manifest, the files of
    `hand/` and `doc/differences.md`. `test/port/fixtures/moment_twins_test.dart` has the 36 ICU
    twins of the moment fixtures (row `adapt-date-moment-format`, Chart.js ADR 0029 §9 item 4). Each
    twin is a hand entry of `specsFromFixtures`, so it has the SHA-256 check and the skip of the
    runner. Its `run` hook compares the parsed time values and the time scales with the date strings
    of its config. `_differs` and `_unparsed` name `controller.bar/bar-thickness-no-overlap.json`
    (the moment forgiving parse). Its untagged group `twins` compares the list with `fixtureSkips`.
    The `dart_test.yaml` of the package declares the tags `fixtures` and `golden` (the theme
    goldens of Chart.js ADR 0147). The `dart_test.yaml` of `packages/chartjs_test_utils` declares
    the tag `fixtures`.
  - `tool/`: the port checks (`check_*.dart`), tool 5 (`spec_cases.dart`, also tool 7 with
    `--fixtures`), tool 6 (`parity.dart`), tool 8 (`port_order.dart`), shared code in `tool/src/`,
    `port_sources.yaml` (one entry for each project that the package ports code from, with its pin;
    the Chart.js entry maps `test/fixtures/` to `packages/flutter_chartjs_port/test/fixtures/hand/`),
    `upstream_manifest/` (tool 4, Node.js) and `reference/` (the Node.js generators of reference
    data, and `reference/p3_page/`: the upstream page of the P3 comparison of performance.md
    §14.9, with its field generator and its server, Chart.js ADR 0053).
  - `doc/`: all Chart.js port docs: roadmap, parity tracker, design docs, Chart.js-only decisions
    (`doc/adr/`, numbered from 0001) and the Chart.js prior-art survey (`doc/prior-art/`).
    - `doc/adr/`: the Chart.js ADRs. `doc/adr/README.md` lists them with their status and their
      supersessions (`adr:index`). The porting lead owns the statuses: it accepts an ADR when its
      code passes the tests. `docs/adr/README.md` has the rules and the template.
    - `doc/differences.md`: one row for each `DIVERGES` difference.
    - `doc/status.yaml`: the hand-written parts of `parity.md`: the text outside the tables, the
      status text of each row, the Dart targets that no header gives and the port-only rows. Tool 6
      writes `doc/parity.md` from it. Do not edit `parity.md` by hand.
    - `doc/upstream/`: the output of tool 4 (`manifest.json`, `fixtures.json`). Do not edit it by
      hand.
    - `doc/porting-flow.md`: the porting plan (proposed). It has the module life cycle, the
      decisions, the test harness, the tools and the phases.
    - `doc/upstream-tracking.md`: how the port follows upstream after the pin (proposed).
    - `doc/upstream-ledger.md`: the upstream commits after the pin, with their triage.
    - `doc/text-metrics.md`: the text-metric probe, the canvas layer against the Chrome canvas.
