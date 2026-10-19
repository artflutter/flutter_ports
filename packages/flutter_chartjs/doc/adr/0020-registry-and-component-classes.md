# Chart.js ADR 0020: Registry and component classes

- Status: proposed
- Date: 2026-10-19
- Related: [Chart.js ADR 0003](0003-type-only-dependencies.md) (type-only dependencies, records),
  [Chart.js ADR 0006](0006-options-representation-and-resolver.md) (plain objects as Maps, the
  `undefined` sentinel), [Chart.js ADR 0009](0009-no-display-only-js-exactness.md) (the protected
  behavior), [Chart.js ADR 0010](0010-js-numeric-semantics.md) (numbers, `jsCall`),
  [Chart.js ADR 0012](0012-dart-file-naming.md) (names, `@internal`),
  [Chart.js ADR 0016](0016-frame-scheduling.md) (the layer of `helpers.extras`),
  [Chart.js ADR 0017](0017-element-properties.md) (element properties, two open items),
  [Chart.js ADR 0018](0018-typed-element-options.md) (typed element options),
  [Chart.js ADR 0019](0019-animation.md) (animation),
  [Chart.js ADR 0021](0021-typed-options-in-the-resolver.md) (typed options in the resolver),
  [Chart.js ADR 0022](0022-chart-test-harness.md) (chart test harness),
  [porting-flow.md](../porting-flow.md) §1.1 (the performance rule) and §5 (phase 5),
  [performance.md](../performance.md) §8

## Context

Phase 5 ports `src/core/core.registry.js`, `core.typedRegistry.js` and `core.plugins.js`. It also
ports the parts of `core.controller.js`, `core.datasetController.js` and `core.scale.js` that use
classes as values. The line numbers refer to Chart.js v4.5.1.

**Classes as values.** A JavaScript class is a value. Chart.js keeps classes in objects. It reads
their static properties by name and constructs them later.
- `Chart.register(...items)` and `Chart.unregister(...items)` give their rest arguments to
  `registry.add` and `registry.remove` (`core.controller.js:112-120`). An item is a class, a plain
  object, an array of items or an object of items (`core.registry.js:124-146`).
- `Registry` keeps four `TypedRegistry` objects (`core.registry.js:13-16`). They are the
  controllers (type `DatasetController`, scope `datasets`, with overrides), the elements (type
  `Element`), the plugins (type `Object`) and the scales (type `Scale`).
- `isForType` returns `Object.prototype.isPrototypeOf.call(this.type.prototype, type.prototype)`
  (`core.typedRegistry.js:16-18`). The test is strict: `DatasetController` is not for the type
  `DatasetController`. Each class is for the type `Object`. An ordinary `function` is also for the
  type `Object`. A plain object, an arrow function, a string and a number are for no type. `null`
  and `undefined` throw a `TypeError` (probes 1 and 11).
- `_getRegistryForType` tests the controllers, the scales and the elements in this order
  (`core.registry.js:17-19`, `:161-170`). `Scale` extends `Element` (`core.scale.js:168`). Thus the
  scales come before the elements. The plugins registry is the fallback.
- `_each` gives an item to `_exec` in two cases (`core.registry.js:126-128`). In the first case, a
  typed registry is for the item. In the second case, the item is for the plugins registry with a
  truthy `id`. `_each` gives each other item to `each`. `each` gives the items of an array or the
  values of a plain object to `_exec`, with no second level (`core.registry.js:134-143`,
  `helpers.core.ts:134-159`).
- `_exec` reads `beforeRegister`, `afterRegister`, `beforeUnregister` and `afterUnregister` from
  the component by name. It calls them with the component as `this` (`core.registry.js:151-156`).
- `register` first registers `Object.getPrototypeOf(item)` when that value has `id` and `defaults`
  (`core.typedRegistry.js:25-31`, `:115-117`). The scope is `this.scope + '.' + id` (`:35`). A
  falsy `id` throws `new Error('class does not have id: ' + item)` (`:37-39`).
- `registerDefaults` merges the defaults of the parent scope, the current defaults of the scope and
  `item.defaults`. Then it routes `item.defaultRoutes` and describes `item.descriptors`
  (`core.typedRegistry.js:84-101`). The controllers registry also calls
  `defaults.override(item.id, item.overrides)` (`:48-50`).
- JavaScript classes inherit static properties. `PieController` has no own `overrides` and no own
  `descriptors`. It reads the objects of `DoughnutController` (probe 1). Thus `overrides.pie` gets
  `aspectRatio` and `plugins.legend.labels.generateLabels`. `register(PieController)` also
  registers `DoughnutController` first.

**Construction.**
- `buildOrUpdateControllers` writes `dataElementType` and `datasetElementType` onto the controller
  class with `Object.assign` (`core.controller.js:443-447`). Then it calls
  `new ControllerClass(this, i)` (`:448`).
- The `DatasetController` constructor copies `new.target.datasetElementType` and
  `new.target.dataElementType` into the instance (`core.datasetController.js:274-275`). The static
  values of `DatasetController` are `null` (`:244`, `:249`).
- The controller constructs its elements with `new this.datasetElementType()`
  (`core.datasetController.js:399-400`) and `new this.dataElementType()` (`:1009`). It reads
  `this.datasetElementType.id` (`:789`) and `this.dataElementType.id` (`:798`). The second read
  occurs once for each element whose options are not shared.
- `controller.scatter.js` writes `false` or an element class into the instance property
  `datasetElementType` (`:94`, `:105`). Line 105 reads the class from `this.chart.registry`.
- `buildOrUpdateScales` calls `new scaleClass({id, type, ctx, chart})`
  (`core.controller.js:357-363`).
- `this.index` of a controller is the dataset index. The scriptable context reads it as
  `datasetIndex` and `index` (`core.datasetController.js:774-776`).

**Plugins.**
- A plugin is an object with an `id`, optional hook methods, and optional `defaults`,
  `defaultRoutes`, `descriptors` and `additionalOptionScopes` (`index.d.ts:826`,
  `core.config.js:267-275`). The seven built-in plugins are object literals.
- Three built-in plugins also keep a class in `_element` (`plugin.legend.js:599`,
  `plugin.title.js:127`, `plugin.tooltip.js:1225`). `plugin.decimation.js:284` declares `destroy`.
  No Chart.js code notifies a hook with that name.
- `_notify` reads `plugin[hook]` at each call. It calls the value with
  `callCallback(method, params, plugin)`. Thus the plugin is `this` (`core.plugins.js:59-71`). Only
  the result `false` with a truthy `args.cancelable` stops the loop.
- `allPlugins` takes the registered plugins in the `Object.keys` order of
  `registry.plugins.items`. Then it adds the inline plugins of `config.plugins`
  (`core.plugins.js:125-144`). The order of the hook calls is an item order that Chart.js ADR 0009
  protects.
- The one caller of `notify` with a filter is the event filter of `_eventHandler`
  (`core.controller.js:1170-1179`). `index.d.ts:555` declares `notifyPlugins(hook, args?)` without
  a filter.

**The count of notifies.** One `update()` plus one `render()` of a chart with 2 scales and 3
datasets notifies the plugins 35 times:
- 21 times in `update()` (`core.controller.js:490`, `:497`, `:524`, `:612`, `:640`, `:649`,
  `:661`, `:673`, `:680`). This count has 4 scale hooks for each scale (`core.scale.js:535`, from
  `:541`, `:545`, `:550` and `:559`). It assumes one update of each scale in the layout. The layout
  can update a scale more than once. The count is then higher.
- 12 times in `render()` and `draw()` (`core.controller.js:684`, `:712`, `:731`, `:766`, `:775`,
  `:793`, `:808`, `:37`).
- 2 times in the tooltip, `beforeTooltipDraw` and `afterTooltipDraw` (`plugin.tooltip.js:1254`,
  `:1260`), when the tooltip renders.

Each animation frame calls `chart.draw()` (`core.animator.js:89`). `draw()` notifies 4 + 2N times
for N visible datasets, plus the 2 tooltip notifies. Each notify reads the hook of each plugin. The
default build has 7 plugins.

**The specs.**
- `core.registry.tests.js` has 15 cases without a chart:
  - ES6 subclasses of `DatasetController`, `Scale` and `Element` with a static `id` and `defaults`
  - a class as a plugin, an object without `id` and the class `FaultyPlugin {}` (`:64-93`)
  - the unregister of an item that is not registered (`:95-99`)
  - one plain class as a controller, a scale, an element and a plugin (`:101-163`)
  - the register callbacks (`:165-204`) and the current defaults of a scope (`:206-222`)
  - the items separately, as an array and as an object (`:224-268`)
- `core.plugin.tests.js:3-17` replaces `plugin.hook` with a spy after the chart exists. The next
  notify must call the spy.
- `core.scale.tests.js:514-522` registers a `Scale` subclass with its own `draw` and
  `convertTicksToLabels`. A chart then constructs it.
- `plugin.title.tests.js:3` and `:32` read `Chart.registry.getPlugin('title')._element`. They call
  `new Title({...})` on that value.
- The scale specs expect `typeof Constructor` to be `'function'` for a registered scale, for
  example `scale.linear.tests.js:9-11`.
- 52 spec lines read the static `Chart.registry`: `core.registry.tests.js`, the `scale.*.tests.js`
  files, `plugin.title.tests.js:3`, `plugin.tooltip.tests.js:2` and `global.namespace.tests.js:19`.

**`registerables`.** `src/index.ts:8-11` imports the four module namespaces `controllers`,
`elements`, `plugins` and `scales`. `registerables` is the array of the four (`:20-25`). The keys
of a module namespace are in code unit order. In the published bundle, each namespace is a frozen
object with a `null` prototype and the same key order (probe 2). Two files have another source
order:
- `controllers/index.js` lists `PolarAreaController` before `PieController` (`:5-6`).
- `elements/index.js` lists `ArcElement`, `LineElement`, `PointElement` and `BarElement`
  (`:1-4`).

The source order of `plugins/index.js` (`:1-7`) and of `scales/index.js` (`:1-6`) is the code
unit order.

**Dart.** Dart has no class values. A Dart `Type` has no static members, no superclass and no
constructor. A Dart subclass does not inherit static members. Dart has no rest parameters and no
`new.target`. A Dart class cannot declare a static member with the name of an instance member, also
an inherited one (probe 7). Three upstream names have this conflict:
- the static `id` of each scale class and the instance `id` of `Scale` (`core.scale.js:175`)
- the static `Chart.registry` (`core.controller.js:108`) and the instance getter `registry`
  (`:229-231`)
- the static and the instance `datasetElementType` and `dataElementType` of `DatasetController`
  (`core.datasetController.js:244`, `:249`, `:274-275`)

**Two open items of Chart.js ADR 0017.** [Chart.js ADR 0017](0017-element-properties.md) gave the
element classes a `static const String id` and `static final` Maps for `defaults`,
`defaultRoutes` and `descriptors`. It left two items open:
- the form in which the registry reads these members and the constructor of a class
- `getRange` in `types.VisualElement` (`index.d.ts:1822`, `core.interaction.js:54`)

## Decision

### 1. The class value

A class value is the Dart object that stands for a JavaScript class as a value. The port-only file
`lib/src/js/js_class.dart` declares it. Its first line is
`// Original code, not ported from Chart.js: JS class values.` The file is a pure layer, because
`lib/src/js/` is a root of tool 1.

```dart
/// The `[[Construct]]` of a class value. [newTarget] is `new.target`.
typedef JsConstruct = Object Function(JsClass newTarget, List<Object?> args);

/// A JavaScript class as a value.
final class JsClass {
  /// `class <name> extends <superclass> { static ... }`.
  JsClass(
    this.name, {
    this.superclass,
    JsConstruct? construct,
    Map<String, Object?>? statics,
  });

  /// `C.name`. [toString] reads it.
  final String name;

  /// `Object.getPrototypeOf(C)` when it is a class value. Null for a base
  /// class, whose static prototype is `Function.prototype`.
  final JsClass? superclass;

  /// `C.id`: a typed slot, read through the static prototype chain.
  Object? get id;

  /// `C[key]`: a `[[Get]]` through the static prototype chain.
  Object? operator [](String key);

  /// `C[key] = value`: a write of an own static property.
  void operator []=(String key, Object? value);

  /// `key in C`.
  bool has(String key);

  /// `Object.prototype.isPrototypeOf.call(other.prototype, C.prototype)`.
  bool isSubclassOf(JsClass other);

  /// `String(C)`: `'class <name> {}'`.
  // DIVERGES(chartjs): js-semantics-class-source, no source text.
  @override
  String toString();
}

/// The JavaScript constructor `Object`.
final JsClass jsObjectClass = JsClass('Object');

/// `new target(...args)`.
Object jsConstruct(Object? target, List<Object?> args);

/// `Object.assign(target, source)` for a class value or a Map [target].
Object jsAssign(Object? target, Map<String, Object?> source);
```

The rules:
- A static property is a property of a class value. The own static properties are in a
  `Map<String, Object?>` in insertion order. The constructor writes `statics` in their order.
- The read gives the own value. Else it gives the value of the nearest superclass that has the key.
  Else it gives the `undefined` sentinel. Thus a subclass reads the `defaults`, `overrides`,
  `defaultRoutes`, `descriptors` and register callbacks of its superclass.
- The write always makes an own static property. It never changes a superclass. Upstream gives the
  same result: `Object.assign(MyLine, {dataElementType})` does not change
  `LineController.dataElementType` (probe 1).
- `id` has a typed slot beside the Map. `operator []=` writes both. The getter `id` reads the slot
  of the nearest class value with an own `id` (probe 4).
- `has` is true for an own or an inherited static property.
- `isSubclassOf(other)` is true when `other` is a superclass of this class value, at any depth. The
  class value itself does not count. `jsObjectClass` counts for each class value other than itself,
  because each class prototype inherits from `Object.prototype`.
- The function properties `length`, `name` and `prototype` are not static properties of a class
  value. No ported code reads them by name.
- A class value has no member for `delete` and no member for `Object.keys`. No ported code deletes
  or enumerates a static property. `each`, `merge` and `clone` of `helpers.core` treat a function
  as a value that is not an object (`helpers.core.ts:53-55`).
- `jsConstruct(target, args)` calls the `construct` of the class value with `target` as
  `newTarget`. A class value without `construct` uses the `construct` of its nearest superclass,
  with the same `newTarget`. This is the implicit constructor of a derived class:
  `constructor(...args) { super(...args); }`.
- A base class without `construct` gives a new empty `Map<String, Object?>`, as `new` of a class
  without a constructor gives a new plain object. A value that is not a class value throws a
  `TypeError`, as `new` of a value that is not a constructor does.
- `jsAssign` writes the keys of `source` in the `jsObjectKeys` order. It uses `operator []=` for a
  class value and a Map write for a Map. It returns `target`. Dart `null` and `undefined` throw a
  `TypeError`. Another target throws an `ArgumentError`. No caller of `jsAssign` passes one.
  `Object.assign` on an element is `Element.assign`
  ([Chart.js ADR 0017](0017-element-properties.md) §6). `Object.assign` on the target of an
  animation writes through `writeProperty` ([Chart.js ADR 0019](0019-animation.md) §2).
- Equality is identity. Thus `==`, `identical`, `List.indexOf` and the matcher `same` give the
  result of `===`.
- A Dart `Function` and a `JsFunction` stand for a function without an own `prototype`: an arrow
  function or a method. Thus `isForType` is false for them, as for an arrow function (probe 11). A
  function that ported code constructs or registers is a class value.

### 2. The JS runtime

Two functions of `lib/src/js/` change. The documentation of a third function changes:
- `jsGet` (`js_object.dart`) gets a case for a class value after the `String` case. It gives
  `C[key]`. The Map, List and String reads keep their cost (probe 6).
- `jsIsFunction` (`js_function.dart`) gives true for a class value, as `typeof C === 'function'`.
  Thus `isFunction` of `helpers.core` gives the upstream result. `callback` then calls `jsCall` for
  a class value, as upstream calls the class. The `typeof Constructor === 'function'` expects of
  the scale specs also pass. The extra type test
  costs about 2 ns on AOT for each notify of 7 plugins, and no measurable time on dart2wasm
  (probe 8).
- `jsCall` keeps its code. Its last case throws an `ArgumentError` for each value that is not a
  Dart `Function` or a `JsFunction` (`js_function.dart:130`). Thus it also throws an
  `ArgumentError` for a class value. JavaScript throws a `TypeError`, because a class constructor
  needs `new`. The documentation of `jsCall` names this case. `callback` and the resolver reach the
  throw where upstream reaches its throw.

`jsToString` of a class value gives `toString()` through its last case (`js_number.dart:83`):
`'class <name> {}'`. JavaScript gives the source text of the class. The two texts are the same
only for a class without a body and without `extends`. This is the row `js-semantics-class-source`
(section 11).

### 3. The class value of a ported class

A ported class gets a static field `jsClass` when upstream registers the class, keeps it as a value
or constructs it from a value. Each upstream superclass of such a class also gets one. In phase 5,
these classes are `Element`, the four elements of phase 4, `DatasetController` and `Scale`. The
scales and `LinearScaleBase` (phase 6), the controllers (phase 7) and the classes `Legend`,
`Title` and `Tooltip` (phase 8) get it in their phase.

```dart
class PointElement extends Element
    implements types.RadialPointElement, types.VisualElementRange {
  /// element.point.ts:22 `static id = 'point'`.
  static const String id = 'point';

  /// element.point.ts:31 `static defaults`.
  static final AnyObject defaults = {/* ... */};

  /// element.point.ts:44 `static defaultRoutes`.
  static final AnyObject defaultRoutes = {/* ... */};

  /// element.point.ts:20 `class PointElement` as a value (Chart.js ADR 0020).
  static final JsClass jsClass = JsClass(
    'PointElement',
    superclass: Element.jsClass,
    statics: {'id': id, 'defaults': defaults, 'defaultRoutes': defaultRoutes},
    construct: (newTarget, args) => PointElement(_cfgArg(args)),
  );

  // ...
}
```

- `name` is the upstream class name. `superclass` is the `jsClass` of the upstream superclass. A
  base class has no `superclass`.
- `statics` has each upstream static property in the upstream order of declaration. The values are
  the objects of the Dart static fields. Thus `PointElement.defaults` and
  `PointElement.jsClass['defaults']` are one Map.
- The `construct` closure converts the arguments to the parameter types of the Dart constructor.
  `_cfgArg` in the example is such a conversion, a private function of the file. An absent
  argument and `undefined` give the Dart default. A value of another type throws a `TypeError`
  (row `adapt-component-class-role`, section 11).
- Ported code reads a static property through the class value where upstream reads it from a class
  value. Examples are the registry, `buildOrUpdateControllers`, `buildOrUpdateScales` and the
  dataset controller.
- Ported code reads the Dart static field where upstream names the class. The one such read in
  `src/` is `static defaults = TimeScale.defaults` (`scale.timeseries.js:41`).
- A Dart static field keeps the form of [Chart.js ADR 0017](0017-element-properties.md) §2 when two
  conditions are true. No instance member of the class has the same name. Upstream never writes the
  static property after the class definition.
- Else the static property is only a property of the class value. Examples are the static `id` of
  a scale class, and `datasetElementType` and `dataElementType` of `DatasetController`. These are
  not `DIVERGES` hunks. The static property exists with its upstream name and value in the class
  value of its upstream class.
- `Element.jsClass` has the statics `defaults` (`{}`) and `defaultRoutes` (the `undefined`
  sentinel as an own property) (`core.element.ts:8-9`). `DatasetController.jsClass` has `defaults`
  (`{}`), `datasetElementType` (`null`) and `dataElementType` (`null`)
  (`core.datasetController.js:239-249`). `Scale.jsClass` extends `Element.jsClass`. It has no own
  statics.
- No upstream member has the name `jsClass`. A static `jsClass` in a class and in its subclass
  gives no analyzer error (probe 7).
- `DatasetController`, `Element` and `Scale` stay concrete classes. A class value without a Dart
  class of its own constructs the Dart class of its nearest superclass.

### 4. Construction and `new.target`

`buildOrUpdateControllers` (`core.controller.js:442-448`):

```dart
final controllerClass = registry.getController(type);
final datasetDefaults = jsGet(defaults['datasets'], type);
final datasetElementType = jsGet(datasetDefaults, 'datasetElementType');
final dataElementType = jsGet(datasetDefaults, 'dataElementType');
jsAssign(controllerClass, {
  'dataElementType': registry.getElement(dataElementType),
  'datasetElementType': jsTruthy(datasetElementType)
      ? registry.getElement(datasetElementType)
      : datasetElementType,
});
// DIVERGES(chartjs): adapt-component-class-role, the cast throws earlier.
meta.controller =
    jsConstruct(controllerClass, [this, i.toDouble()]) as DatasetController;
```

- The map literal keeps the upstream order of `Object.assign`. Both `getElement` calls occur first.
  Then `jsAssign` makes two writes in the key order of the literal.
- `getElement` takes the option value, as the property key of `items[id]` (section 5).
- The argument `i` becomes a `double`. The controller keeps it in `index`. The scriptable context
  reads it as a number (`core.datasetController.js:774-776`).
  [Chart.js ADR 0010](0010-js-numeric-semantics.md) §7 allows an `int` only as a list index. The
  port of `core.datasetController` converts `index` to an `int` where it indexes a list.
- The result of `jsConstruct` gets a cast to `DatasetController`. A registered value that is not a
  class value throws a `TypeError` in `jsConstruct`. Upstream throws at `new` on the same line.
- A class value whose `construct` gives another type throws a `TypeError` at the cast. Upstream
  constructs that object. It sets `meta.controller` and notifies `beforeElementsUpdate`. It throws
  later, at the first absent method (`core.controller.js:497-506`). This is the row
  `adapt-component-class-role` (section 11).

`DatasetController` and each subclass take `new.target` as an optional last positional parameter:

```dart
/// core.datasetController.js:255 `constructor(chart, datasetIndex)`.
///
/// [newTarget] is `new.target`. A direct Dart call stands for
/// `new DatasetController(chart, datasetIndex)`.
DatasetController(this.chart, double datasetIndex, [JsClass? newTarget]) {
  // ...
  final target = newTarget ?? jsClass;
  datasetElementType = target['datasetElementType'];
  dataElementType = target['dataElementType'];
  initialize();
}

/// controller.line.js:6 `class LineController extends DatasetController`.
LineController(types.Chart chart, double datasetIndex, [JsClass? newTarget])
  : super(chart, datasetIndex, newTarget ?? jsClass);
```

- The `construct` closure of a controller class value gives its `newTarget` to the constructor.
  Thus a registered subclass without a Dart class of its own constructs the Dart class of its
  superclass, with its own class value as `new.target`.
- A direct Dart call without `newTarget` uses the class value of the Dart class that it names, as
  `new LineController(chart, i)` does.
- The instance fields `datasetElementType` and `dataElementType` are `Object?`. They hold the
  upstream value: a class value, `false`, or JS `null` as Dart `null`. `ScatterController` writes
  `false` or a class value into the instance field (`controller.scatter.js:94`, `:105`).
- The readers keep the upstream lines:
  - `if (this.datasetElementType)` is `jsTruthy(datasetElementType)`
    (`core.datasetController.js:399`).
  - `new this.datasetElementType()` and `new this.dataElementType()` are
    `jsConstruct(..., const [])` with a cast to `Element` (`:400`, `:1009`). The cast is a part of
    the row `adapt-component-class-role`.
  - `this.datasetElementType.id` and `this.dataElementType.id` are
    `t is JsClass ? t.id : jsGet(t, 'id')` (`:789`, `:798`). The form follows
    [Chart.js ADR 0018](0018-typed-element-options.md) §4. The result is an `Object?`.
    `_resolveElementOptions` and `createElementOptions` of
    [Chart.js ADR 0021](0021-typed-options-in-the-resolver.md) §1 take it as it is.

`buildOrUpdateScales` (`core.controller.js:357-363`):

```dart
final scaleClass = registry.getScale(scaleType);
// DIVERGES(chartjs): adapt-component-class-role, the cast throws earlier.
scale = jsConstruct(scaleClass, [
  <String, Object?>{'id': id, 'type': scaleType, 'ctx': ctx, 'chart': this},
]) as Scale;
```

`Element` and `Scale` do not read `new.target`. Their constructors do not take it.

### 5. `TypedRegistry` and `Registry`

`lib/src/core/core.typedRegistry.dart` ports `core.typedRegistry.js` line by line:

```dart
/// core.typedRegistry.js:8 `TypedRegistry`.
final class TypedRegistry {
  /// core.typedRegistry.js:9. An absent [override] is false.
  TypedRegistry(this.type, this.scope, [this.override = false]);

  final JsClass type;
  final String scope;
  final bool override;

  /// `Object.create(null)`. A key is the `ToString` of an `id`.
  final Map<String, Object> items = {};

  /// core.typedRegistry.js:16 `isForType`.
  bool isForType(Object? type);

  /// core.typedRegistry.js:24 `register`. Returns the scope.
  String register(Object? item);

  /// core.typedRegistry.js:59 `get`. Dart null stands for `undefined`.
  Object? get(Object? id);

  /// core.typedRegistry.js:66 `unregister`.
  void unregister(Object? item);
}
```

- `isForType(type)` throws a `TypeError` for Dart `null` and `undefined`, as the read
  `type.prototype` does. Else it returns `type is JsClass && type.isSubclassOf(this.type)`. The
  plugins registry has the type `jsObjectClass`.
- `register` takes the `superclass` of a class value as `Object.getPrototypeOf(item)`. Each other
  value has a built-in prototype. A built-in prototype is never a component. Dart `null` and
  `undefined` throw a `TypeError`.
- `isIChartComponent(proto)` is `proto != null && proto.has('id') && proto.has('defaults')`
  (`core.typedRegistry.js:115-117`).
- `register` reads `id`, `defaults`, `overrides`, `defaultRoutes` and `descriptors` with `jsGet`.
  Thus a class value, a Map and any other value give the upstream result.
- The scope is `'${this.scope}.${jsToString(id)}'`. The key of `items` is `jsToString(id)`, the
  `ToPropertyKey` of `id in items` and of `items[id] = item`. `get` uses the same key rule.
- `register` gives the raw `id` to `defaults.override(id, overrides)`. `Defaults.override` takes an
  `Object?` scope. Thus an `id` that is not a string gives the upstream result.
- `new Error(message)` is `StateError(message)` with the upstream message. `helpers.config.dart:653`
  does the same for the recursion error. Examples are `'class does not have id: bar'` and
  `'"custom" is not a registered controller.'`.
- `registerDefaults` and `routeDefaults` are private functions with the upstream lines
  (`core.typedRegistry.js:84-113`). `routeDefaults` reads the keys with `jsObjectKeys`.
- `unregister` throws a `TypeError` when `defaults[scope]` is not an object, as the `in` operator
  does (`:75`).

`lib/src/core/core.registry.dart` ports `core.registry.js` line by line:

```dart
/// core.registry.js:11 `Registry`.
final class Registry {
  final TypedRegistry controllers =
      TypedRegistry(DatasetController.jsClass, 'datasets', true);
  final TypedRegistry elements = TypedRegistry(Element.jsClass, 'elements');
  final TypedRegistry plugins = TypedRegistry(jsObjectClass, 'plugins');
  final TypedRegistry scales = TypedRegistry(Scale.jsClass, 'scales');

  void add(List<Object?> args);
  void remove(List<Object?> args);
  void addControllers(List<Object?> args);
  void addElements(List<Object?> args);
  void addPlugins(List<Object?> args);
  void addScales(List<Object?> args);
  Object getController(Object? id);
  Object getElement(Object? id);
  Object getPlugin(Object? id);
  Object getScale(Object? id);
  void removeControllers(List<Object?> args);
  void removeElements(List<Object?> args);
  void removePlugins(List<Object?> args);
  void removeScales(List<Object?> args);
}

/// core.registry.js:186 the singleton instance.
final Registry registry = Registry();
```

- `_typedRegistries` is `[controllers, scales, elements]`, in the upstream order.
- `_getRegistryForType` is the upstream loop. It returns `plugins` when no typed registry is for
  the type.
- `_each(String method, List<Object?> args, [TypedRegistry? typedRegistry])` copies `args`. It
  keeps the upstream condition:
  `typedRegistry != null || reg.isForType(arg) || (identical(reg, plugins) && jsTruthy(jsGet(arg, 'id')))`.
  Else it calls `each(arg, ...)` of `helpers.core`. Thus a List gives its items in index order. A
  Map gives its values in the `jsObjectKeys` order. The callback of `each` does not recurse, as
  upstream.
- `_exec(String method, TypedRegistry registry, Object? component)` calls
  `callback(jsGet(component, 'before${capitalize(method)}'), const [], component)`. Then it calls
  the method. Then it calls the `after` callback. The call `registry[method](component)` becomes a
  `switch` on the two names `'register'` and `'unregister'`.
- The getters return `Object`, the registered value. `index.d.ts` names a class type. A registered
  plain object is also a valid item (`core.registry.tests.js:101-163`).
- `_get` throws when `typedRegistry.get(id)` is Dart `null`. The registry never stores Dart `null`,
  because `register(null)` throws before the write.

### 6. The statics of `Chart`, the rest parameters and `registerables`

A rest parameter `...items` is one `List<Object?>` parameter. The Dart list is the array of the
rest parameter:

| JavaScript | Dart | Result |
|---|---|---|
| `Chart.register(A)` | `Chart.register([a])` | registers `a` |
| `Chart.register(A, B)` | `Chart.register([a, b])` | registers `a`, then `b` |
| `Chart.register([A, B])` | `Chart.register([[a, b]])` | registers `a`, then `b` |
| `Chart.register({A, B})` | `Chart.register([{'A': a, 'B': b}])` | registers the values in the `jsObjectKeys` order |
| `Chart.register([[A, B]])` | `Chart.register([[[a, b]]])` | throws `class does not have id: ...` |
| `Chart.register(null)` | `Chart.register([null])` | throws a `TypeError` |
| `Chart.register(...registerables)` | `Chart.register(registerables)` | registers each value of each Map |
| `Chart.register(registerables)` | `Chart.register([registerables])` | throws |

Here `a` is `A.jsClass`, a plugin Map or another item. The registry methods of section 5 take the
same form.

The statics of `Chart` in `lib/src/core/core.controller.dart` (`core.controller.js:105-120`):

```dart
static final Defaults defaults = core_defaults.defaults;
static AnyObject get overrides => core_defaults.overrides;
static final Registry registry = core_registry.registry;
static const String version = chartJsVersion;
static Chart? getChart(Object? key) => _getChart(key);

static void register(List<Object?> items) {
  registry.add(items);
  _invalidatePlugins();
}

static void unregister(List<Object?> items) {
  registry.remove(items);
  _invalidatePlugins();
}
```

- `instances` (`:106`) is also a static. The port of `core.controller.js` decides its Dart type.
  This decision needs only the iteration of its values in the `jsObjectKeys` order
  (`invalidatePlugins`, `:1265-1267`).
- `static getChart = getChart` becomes a static method. The result is the same.
- `version` is `chartJsVersion` of `lib/src/upstream.dart`. Upstream reads the version from
  `package.json` (`core.controller.js:12`). Thus a bump changes both.
- The instance getter `registry` (`:229-231`) has no Dart form. Dart forbids it beside the static
  `Chart.registry` (probe 7). `index.d.ts:565` declares only the static. 52 spec lines read the
  static.
- The one upstream reader of the getter is `controller.scatter.js:105`. Its port reads the
  singleton `registry` of `core.registry.dart` (phase 7). It is the same object. This is the row
  `adapt-chart-registry-getter` (section 11).

`registerables` (`src/index.ts:20-25`) is a `List<AnyObject>` of four unmodifiable Maps:
`controllers`, `elements`, `plugins` and `scales`. The keys are the export names in code unit
order, as in the published bundle (probe 2):
- `controllers`: `BarController`, `BubbleController`, `DoughnutController`, `LineController`,
  `PieController`, `PolarAreaController`, `RadarController`, `ScatterController`
- `elements`: `ArcElement`, `BarElement`, `LineElement`, `PointElement`
- `plugins`: `Colors`, `Decimation`, `Filler`, `Legend`, `SubTitle`, `Title`, `Tooltip`
- `scales`: `CategoryScale`, `LinearScale`, `LogarithmicScale`, `RadialLinearScale`, `TimeScale`,
  `TimeSeriesScale`

A value is the class value of the class or the Map of the plugin. Thus
`Chart.register(registerables)` registers the items in the order of the bundle. The source order of
`controllers/index.js` and `elements/index.js` gives another order of `items`, of
`defaults.datasets` and of `overrides`. Each Map gets the entries of its classes in the phase that
ports them. In phase 5, only `elements` has entries. `src/index.ts:13-18` also exports the four
Maps by name: `controllers`, `elements`, `plugins` and `scales`.

`Chart.register([registerables])` throws a `StateError` with the message
`'class does not have id: [object Object]'`. Upstream throws a `TypeError` (`'id' in null`),
because the namespaces of the bundle have a `null` prototype (probe 2). Both throw at the first
namespace, before a write. Only the error class and the message differ. Thus it is not a `DIVERGES`
hunk. [Chart.js ADR 0017](0017-element-properties.md) §5 treats a write by name in the same way.

`lib/src/core/index.dart` ports `src/core/index.ts`. Each `export` directive shows the upstream
name with the rules of [Chart.js ADR 0012](0012-dart-file-naming.md). The names are `adapters` for
`_adapters`, `Animation`, `Animations`, `animator`, `Chart`, `DatasetController`, `defaults`,
`Element`, `Interaction`, `layouts`, `registry`, `Scale` and `Ticks`. Dart has no
`export ... as`. Thus `export {default as plugins}` (`src/core/index.ts:12`) exports the class name
`PluginService`. In `src/index.ts`, the local export `plugins` (`:13-18`) takes the place of that
name in any case. The class values are static members. They need no export of their own.

### 7. Plugins and the hook dispatch

A plugin is a JavaScript object in the forms of
[Chart.js ADR 0006](0006-options-representation-and-resolver.md):
- A plain object is a `Map<String, Object?>`. This is the form of the built-in plugins, of the
  inline plugins in `config.plugins` and of the plugin objects of the specs. Each property is a Map
  entry, also `_element`, `positioners` and `destroy`.
- A class that a program registers as a plugin is a class value. Its hooks are static properties
  (`core.registry.tests.js:64-81`).
- A hook is a function value of `lib/src/js/js_function.dart`: a Dart `Function`, or a
  `JsFunction` when the hook reads `this`.

```dart
/// plugin.tooltip.js:1223 the default export (phase 8).
final AnyObject plugin = {
  'id': 'tooltip',
  '_element': Tooltip.jsClass,
  'positioners': positioners,
  'afterInit': (Object? chart, Object? args, Object? options) {/* ... */},
  // ...
  'defaults': {/* ... */},
  'additionalOptionScopes': ['interaction'],
};
```

`lib/src/core/core.plugins.dart` ports `core.plugins.js` line by line. The class is
`PluginService`. A descriptor `{plugin, options}` is a record, as
[Chart.js ADR 0003](0003-type-only-dependencies.md) gives for an inline object type that ported
code only reads:

```dart
/// core.plugins.js:12 `{plugin: object, options: object}`.
typedef PluginDescriptor = ({Object plugin, AnyObject options});

/// core.plugins.js:35 `notify`. Dart null stands for the `undefined` of a
/// notify before `install` (core.plugins.js:41-43).
bool? notify(
  types.Chart chart,
  String hook, [
  AnyObject? args,
  bool Function(PluginDescriptor descriptor)? filter,
]);
```

- `filter` is a typed Dart function. `notify` applies it with `where`. Its one caller is the event
  filter of `core.controller.js:1170`. `index.d.ts:555` declares `notifyPlugins` without a filter.
  Thus no user function reaches it.
- `_cache` is `cache` with `@internal`, because `isPluginEnabled` reads it
  (`core.controller.js:1139`, [Chart.js ADR 0012](0012-dart-file-naming.md)). `_init` and
  `_oldCache` keep the underscore.
- `allPlugins` takes the keys of `registry.plugins.items` with `jsObjectKeys`. Thus the hook order
  is the upstream order, also for an integer-like `id` (probe 10). The test
  `plugins.indexOf(plugin) === -1` becomes a test with `identical`.
- `localIds[plugin.id]` uses the key `jsToString(jsGet(plugin, 'id'))`. Thus a local plugin without
  an `id` gets the key `'undefined'`, as upstream.

The hook dispatch of `_notify` (`core.plugins.js:59-71`) is:

```dart
/// core.plugins.js:59 `_notify`.
bool _notify(
  List<PluginDescriptor> descriptors,
  types.Chart chart,
  String hook, [
  AnyObject? args,
]) {
  args ??= <String, Object?>{};
  for (final descriptor in descriptors) {
    final plugin = descriptor.plugin;
    // `plugin[hook]`. An absent key of a Map gives Dart null. Dart null
    // and `undefined` are not functions. Thus a plain Map read is enough.
    final Object? method =
        plugin is Map<dynamic, dynamic> ? plugin[hook] : jsGet(plugin, hook);
    // callCallback calls only a function value (helpers.core.ts:108-110).
    if (!jsIsFunction(method)) continue;
    final params = [chart, args, descriptor.options];
    if (identical(callback(method, params, plugin), false) &&
        jsTruthy(args['cancelable'])) {
      return false;
    }
  }
  return true;
}
```

- The read occurs at each call, as upstream. A hook that a plugin gets or replaces after the
  descriptors exist runs at the next notify (`core.plugin.tests.js:3-17`).
- The two changes from the upstream lines give the same result for each input. The Map read skips
  the second key test of `jsGet` for an absent key. The `params` list exists only for a function
  value, where `callCallback` uses it. Thus they are not `DIVERGES` hunks (section 13).
- The type test is `Map<dynamic, dynamic>`, as in `jsGet`. On dart2wasm, the test
  `Map<String, Object?>` costs 126 ns for each notify of 7 plugins, against 93 ns (probe 8).
- A `JsFunction` hook gets the plugin as `this`: the Map, or the class value of a class plugin.
- This form costs 77 ns on AOT and 94 ns on dart2wasm for each notify of 7 plugins (probe 8). The
  literal port costs 87 ns and 131 ns with a descriptor of the static type `AnyObject`. A class
  plugin needs the static type `Object`. The literal port then costs more.

### 8. Subclasses and plugins in specs and in user code

A spec ports `class X extends Y {}` and its static properties to a class value:

```dart
// core.registry.tests.js:3-11
final customController = JsClass(
  'CustomController',
  superclass: DatasetController.jsClass,
)
  ..['id'] = 'custom'
  ..['defaults'] = <String, Object?>{'foo': 'bar'}
  ..['overrides'] = <String, Object?>{'bar': 'foo'};
Chart.register([customController]);
expect(Chart.registry.getController('custom'), same(customController));
```

A subclass with its own methods also has a Dart class. Its class value constructs it:

```dart
// core.scale.tests.js:514-522. The method signatures follow the Scale port.
final class _CustomScale extends Scale {
  _CustomScale(super.cfg);

  @override
  void draw([ChartArea? chartArea]) {}

  @override
  List<Object?> convertTicksToLabels(List<types.Tick> ticks) => ['tick'];
}

final customScale = JsClass(
  'CustomScale',
  superclass: Scale.jsClass,
  construct: (newTarget, args) => _CustomScale(args[0]! as AnyObject),
)
  ..['id'] = 'customScale'
  ..['defaults'] = <String, Object?>{};
```

- A static property of a class body goes into `statics`. A static property that the spec writes
  after the class goes into a write with `operator []=`.
- The register callbacks are static properties with function values, for example
  `custom['beforeRegister'] = () => beforeRegisterCount++` (`core.registry.tests.js:172`). A
  `JsFunction` gets the component as `this`.
- A plugin of a spec or of a user is a Map literal, for example
  `{'id': 'a', 'hook': (Object? chart, Object? args, Object? options) {}}`. A spy replaces
  `plugin['hook']`. The next notify reads the spy.
- An ES6 plugin class is a class value without `superclass` (`core.registry.tests.js:65-70`).
  `class FaultyPlugin {}` is `JsClass('FaultyPlugin')`. Its message is
  `'class does not have id: class FaultyPlugin {}'`, as upstream (`:88-92`).
- `instanceof X` in ported code is a Dart type test on the Dart class (`plugin.colors.ts:60-62`,
  `plugin.filler/index.js:25`). A class value without a Dart class of its own constructs the Dart
  class of its nearest superclass. Thus `instanceof` of each ported class gives the upstream
  result.
- A user registers a Dart subclass through its class value. Phase 5 adds no typed helper for this
  (Alternatives). A typed front end can come with the typed options API after 0.1.0
  ([Chart.js ADR 0006](0006-options-representation-and-resolver.md)). It will give the same class
  values and Maps to the registry.

### 9. `getRange`

`lib/src/types/index.dart` declares the port-only interface `VisualElementRange`. It stands for
the optional member `getRange?(axis)` of `VisualElement` (`index.d.ts:1822`):

```dart
/// index.d.ts:1822 the optional member `getRange?(axis: 'x' | 'y'): number`
/// of `VisualElement`. An element class with an upstream `getRange`
/// implements it.
abstract interface class VisualElementRange implements VisualElement {
  /// index.d.ts:1822 `getRange(axis)`.
  double getRange(String axis);
}
```

- `PointElement` and `BarElement` implement it. `PointElement.getRange([String? axis])` and
  `BarElement.getRange(String axis)` keep their phase 4 signatures (probe 9).
- `ArcElement` and `LineElement` do not implement it. They have no upstream `getRange`. They get no
  method and no `DIVERGES` hunk.
- `types.VisualElement` does not change.
- `core.interaction.dart` ports `core.interaction.js:53-55` as:

```dart
final el = data[0];
final Object range =
    el is types.VisualElementRange ? el.getRange(axis) : false;
if (jsTruthy(range)) {
  // ...
}
```

- An element without the method gives `false`, as upstream. A user element can implement the
  interface. The form needs no `DIVERGES` marker and no `differences.md` row.
- The type test occurs once for each `binarySearch` call, on `data[0]`.

### 10. Pure layers

- `lib/src/js/js_class.dart` is a pure layer (root `lib/src/js/`).
- `lib/src/core/core.typedRegistry.dart` imports `core.defaults`, `helpers.core` and the JS
  runtime. It is a pure layer. It becomes a root of tool 1.
- `lib/src/core/core.registry.dart` imports `core.datasetController.dart`, `core.element.dart` and
  `core.scale.dart` for their class values, as upstream imports the classes
  (`core.registry.js:1-3`).
- `core.scale.js` imports `helpers.extras` (`core.scale.js:5`). Under
  [Chart.js ADR 0016](0016-frame-scheduling.md) decision 10, `helpers.extras.dart` is not a pure
  layer. Thus `core.registry.dart` and `core.plugins.dart` are not pure layers.
- `core.plugins.dart` names the chart as `types.Chart`
  ([Chart.js ADR 0003](0003-type-only-dependencies.md)).
- The registry spec calls `Chart.register`. `core.controller.dart` reaches the platform layer.
  Thus the registry spec needs `@TestOn('vm')` in any case.

### 11. `differences.md` rows

The port adds three rows. Each item below gives the columns of `differences.md`.

**`js-semantics-class-source`**
- Dart file and symbol: `lib/src/js/js_class.dart` `JsClass.toString`.
- Upstream: `src/core/core.typedRegistry.js`@v4.5.1:37-39.
- Category: `js-semantics`.
- Reason: In JavaScript, `String(C)` gives the source text of a class. The port gives
  `'class <name> {}'`. The two texts are the same for a class without a body and without `extends`,
  for example `class FaultyPlugin {}` (`core.registry.tests.js:88-92`). The text appears in the
  message of the `register` error and in `jsToString` of a class value. The throw is the same.
- Test: `test/port/js/js_class_test.dart`, group `js-semantics-class-source`.
- On a bump: compare the messages that print an item in `core.typedRegistry.js` and
  `core.registry.js`.

**`adapt-chart-registry-getter`**
- Dart file and symbol: `lib/src/core/core.controller.dart` `Chart` (no instance getter
  `registry`), `lib/src/controllers/controller.scatter.dart` `ScatterController.addElements`
  (phase 7).
- Upstream: `src/core/core.controller.js`@v4.5.1:229-231,
  `src/controllers/controller.scatter.js`@v4.5.1:105.
- Category: `adapt`.
- Reason: Dart forbids a static member and an instance member with the same name. The static
  `Chart.registry` stays, as `index.d.ts:565` declares it. The scatter controller reads the
  singleton `registry` of `core.registry.dart`. It is the object that the getter returns. The
  controller file imports `core.registry.dart`. Upstream reads the object through the chart.
- Test: `test/port/core/core.controller_test.dart`, group `adapt-chart-registry-getter`.
  `Chart.registry` is `registry`. In phase 7, a scatter chart with `showLine` gets a `LineElement`
  as its dataset element.
- On a bump: compare the readers of `chart.registry`.

**`adapt-component-class-role`**
- Dart file and symbol: `lib/src/core/core.controller.dart` `Chart.buildOrUpdateControllers` and
  `Chart.buildOrUpdateScales`, `lib/src/core/core.datasetController.dart`
  `DatasetController.addElements` and `DatasetController._insertElements`.
- Upstream: `src/core/core.controller.js`@v4.5.1:357-367, 442-450, 495-506,
  `src/core/core.datasetController.js`@v4.5.1:399-401, 1008-1010.
- Category: `adapt`.
- Reason: The port casts the result of `jsConstruct` to the class of its role: `DatasetController`,
  `Scale` or `Element`. Thus each later call stays typed. A class value of another role throws a
  `TypeError` at the cast. An example is a plain class that `addControllers` registers. Upstream
  constructs the object and keeps it. It throws a `TypeError` later, at the first absent method.
  Before that throw, `buildOrUpdateControllers` sets `meta.controller` and ends its loop. `update()`
  notifies `beforeElementsUpdate` (`core.controller.js:497`). `buildOrUpdateScales` writes
  `scales[scale.id]` (`:364`). The port does none of these. Both throw a `TypeError` in the same
  `update()` call. A value that is not a class value throws at `new` in both.
- Test: `test/port/core/core.controller_test.dart`, group `adapt-component-class-role`. A plain
  class value that `addControllers` registers throws a `TypeError` in `update()`. A spy plugin gets
  no `beforeElementsUpdate`. `meta.controller` stays unset.
- On a bump: compare `buildOrUpdateControllers`, `buildOrUpdateScales`, `addElements` and
  `_insertElements`.

### 12. Tests

- `test/specs/core.registry_test.dart` ports the 15 cases line by line. It has `@TestOn('vm')`
  (section 10). The prototype of probe 5 passes them.
- `test/port/js/js_class_test.dart` is pure. It runs on the VM, with dart2js and with dart2wasm.
  It tests these items:
  - the read through the static prototype chain, the own write, `has` and the slot of `id`
  - `isSubclassOf`: strict, with the `Object` root
  - `jsConstruct`: an inherited `construct`, `newTarget`, an empty Map for a base class, and a
    `TypeError` for other values
  - `jsAssign` in the key order of the source
  - the `jsGet` case, `jsIsFunction`, the `ArgumentError` of `jsCall`, and the group
    `js-semantics-class-source`
- `test/port/core/core.typedRegistry_test.dart` is pure. `test/port/core/core.registry_test.dart`
  runs on the VM. They test the behaviors of probes 1 and 2 that the specs do not test. The
  expected values are the output of the probes:
  - A parent with `id` and `defaults` registers first.
  - A subclass reads the `overrides` and `descriptors` of its superclass.
  - A duplicate `id` keeps the first class value.
  - The order of the values of a Map item and of the keys of `items` is the `jsObjectKeys` order.
  - Dart `null` and `undefined` throw a `TypeError`. A number does not throw.
  - A nested list throws `'class does not have id: [object Object]'`.
  - `add(registerables)` on a new `Registry` gives the items in the order of probe 2. In phase 5,
    the test covers the four elements. `Chart.register([registerables])` throws.
- The restore of the harness resets `defaults`, `overrides` and `descriptors` after each test. It
  does not reset the `items` of the singleton `registry`
  ([Chart.js ADR 0022](0022-chart-test-harness.md) §8). Thus a test of the singleton unregisters
  each item that it registers, as `core.registry.tests.js` does. A test of a `TypedRegistry` makes
  a new instance.
- `test/port/core/core.plugins_test.dart` tests the cancel rules of probe 10 and these items:
  - A hook that a plugin gets after the descriptors exist runs.
  - A `JsFunction` hook gets the Map or the class value as `this`.
  - `false` with `cancelable` stops the loop. `false` without `cancelable` does not stop it.
  - A value that is not a function gives no call. A class value as a hook throws an
    `ArgumentError`.
  - The hook order follows `jsObjectKeys` of `items`.
- `test/port/core/core.interaction_test.dart`: a data element without `VisualElementRange` gives
  the full range. A `BarElement` with shared options gives the range of the binary search.
- `test/port/core/core.controller_test.dart` has the groups of the two `adapt` rows (section 11).

### 13. Microbenchmark gains and the performance rule

[porting-flow.md](../porting-flow.md) §1.1 measures performance by the frame rate, the draw time
and the raster time. This decision applies the rule in this way:
- A form that keeps the upstream structure can take a gain that only a microbenchmark measures.
  §1.1 asks for no more records for such a form. Examples are the Map read and the late `params`
  list of section 7.
- A form that changes the upstream structure needs a gain in the frame figures of
  [performance.md](../performance.md). Its `adapt` row must name such a figure (§1.1). A gain below
  the resolution of the frame figures, 0.1 ms, does not count for such a form.
- Against the chosen form, the typed hook slots (CT, Alternatives) save 56 ns on AOT for each
  notify of 7 plugins. On dart2wasm, they save 68 ns (probe 8). The form M of the judge has a
  descriptor of the static type `AnyObject`. Against M, CT saves 38 ns and 65 ns.
- One draw of a chart with 3 datasets makes 10 notifies. Thus CT saves about 0.6 µs on AOT and
  0.7 µs on dart2wasm for each draw. One `update()` plus `render()` makes 35 notifies. CT saves
  about 2.0 µs and 2.4 µs there. These gains are more than 40 times below 0.1 ms.
- The gain grows by 2 notifies for each visible dataset. It reaches 0.1 ms for each draw at about
  890 visible datasets on AOT and 730 on dart2wasm. This is a calculation from the figures of
  probe 8, not a measurement.
- [Chart.js ADR 0019](0019-animation.md) applies the same threshold to `NumberSlots` (its
  alternative 4 and Open).

### 14. What this decision needs from Chart.js ADRs 0019, 0021 and 0022

- [Chart.js ADR 0019](0019-animation.md) (animation): nothing. The layer of `core.registry.dart`
  follows the layer of `core.scale.dart` and `core.datasetController.dart` (section 10). This
  decision is valid for each answer. Chart.js ADR 0019 §1 makes `jsTypeof` follow the class value
  case of `jsIsFunction` (section 2).
- [Chart.js ADR 0021](0021-typed-options-in-the-resolver.md) (typed options in the resolver):
  nothing. It gets the element class value at `dataElementType` and `datasetElementType` of a
  controller. It gets the `id` as a typed read (section 4). It keys the typed options class on the
  `id` (Chart.js ADR 0021 §1).
- For Chart.js ADR 0021, the `static const String id` of each element class stays
  ([Chart.js ADR 0017](0017-element-properties.md) §2). A derived element class reaches its parent
  through `superclass`, and the `id` of the parent through `superclass.id`. A static property that
  Chart.js ADR 0021 needs goes into the `statics` of the class value.
- [Chart.js ADR 0022](0022-chart-test-harness.md) (chart test harness): nothing. The registry
  state is the four `items` Maps and the own static properties that `jsAssign` writes on
  controller class values. The upstream harness restores none of them. Most specs unregister their
  own items. `core.scale.tests.js:522`, `:555`, `:585` and `core.plugin.tests.js:416-417` leave
  their items registered, as upstream does. A spy on a plugin hook replaces a Map entry. Chart.js
  ADR 0022 §8 registers the built-in components before the snapshot of the restore.
- For Chart.js ADR 0022, this decision sets only the statics of `Chart` (section 6). The
  constructor, `id` and `destroy()` of `Chart` are a part of the port of `core.controller.js`.
  `core.plugins.dart` reads `chart.config` and `chart.getContext()` through `types.Chart`
  (`core.plugins.js:102`, `:158`). The port of `core.config.js` gives the type of `config`. This
  decision adds no `resize` and no `eventHandler` to `types.Chart`. Thus the fields of Chart.js
  ADR 0022 §5 need no getter form.

## Alternatives considered

The scores use the order of [porting-flow.md](../porting-flow.md) §1.1: (1) the upstream behavior,
(2) performance, (3) the upstream structure, (4) less code of our own.

**The three drafts of the panel.** The judge gave each draft a score from 0 to 10 for each
priority:

| Draft | (1) | (2) | (3) | (4) | Main reasons |
|---|---|---|---|---|---|
| fidelity (chosen) | 9 | 7 | 9 | 7 | Each probed edge behavior matches upstream. Its prototype passes 22 of 22 cases. It has no `adapt` row for registry semantics. |
| performance | 8 | 8 | 4 | 4 | The fastest dispatch for typed plugins. It drops the static `Chart.registry`. It adds a second plugin form and 5 `adapt` rows. Its Map plugins are slower than the literal port. |
| simplicity | 8 | 7 | 8 | 8 | The least code. Its required `String id` changes the `FaultyPlugin` message. It has no form for an inherited `id` or for the base classes. |

**Form of a class value.**
- **A typed descriptor for each kind.** The performance draft has `ChartComponent`,
  `ControllerClass`, `ScaleClass`, `ElementClass` and `Plugin`. The simplicity draft has
  `ComponentClass<T>` with `ControllerClass`, `ScaleClass` and `ElementClass`.
  - (1) The simplicity draft requires a non-null `String id`. The case `class FaultyPlugin {}`
    (`core.registry.tests.js:88-92`) then needs another message and a `js-semantics` row. A
    subclass that inherits its `id` has no form. The base classes have no descriptor. Thus
    `Chart.register(DatasetController)` has no Dart form.
  - (1) The performance draft keeps `id` as `String?`. An `id` that is not a string has no form.
    Upstream keys it through `ToPropertyKey`. Its `isForType` is a kind test with a `DIVERGES` row.
  - (1) The performance draft uses Dart `null` for an absent static property and for `undefined`.
    It states that no upstream class declares `undefined` for a static property. That statement is
    false: `core.element.ts:9` declares `static defaultRoutes = undefined`. The two states give
    the same reads in Chart.js. Thus the error has no effect on behavior.
  - (1) The writes by name of the specs (`X.id = 'custom'`) and of `Object.assign` need a field for
    each name, or a Map.
  - (2) A typed `id` field reads in 1.01 ns against 1.78 ns for the slot of `JsClass` on AOT. On
    dart2wasm, the figures are 0.58 ns and 1.17 ns (probe 4). The judge measured 0.82 ns against
    1.35 ns on AOT. The read occurs once for each element with options that are not shared. For
    20000 such elements, the difference is about 15 µs on AOT and 12 µs on dart2wasm in one update.
  - (2) A typed factory constructs in 2.85 ns against 3.46 ns for `jsConstruct` on AOT. On
    dart2wasm, the figures are 4.72 ns and 5.15 ns (probe 4). The judge measured 2.45 ns against
    2.88 ns on AOT. The construction occurs only for a new element.
  - (3) A typed descriptor has no upstream counterpart. (4) The simplicity draft has less code. The
    performance draft has more.
  - Rejected for (1).
- **Dart `Type` objects and a side table.** (1) A `Type` gives no superclass on AOT and on the
  web. A spec class `X extends Y` without a Dart class has no `Type`. (3) It is the class value with
  one more indirection. Rejected.
- **A parallel hierarchy of class objects with virtual getters.** (1) Virtual getters give the
  static inheritance. The writes by name and `'id' in proto` still need a Map. (4) One more class
  for each ported class. Rejected.
- **The Dart static fields of Chart.js ADR 0017 §2 as the only source.** (1) A Dart subclass does
  not inherit static members. Thus `PieController` loses the doughnut `overrides`. The pie chart
  then loses its legend labels. Writes by name and spec classes without a Dart class have no form.
  (3) The scale `id` and the controller element types cannot be Dart statics (probe 7). Rejected.
- **A Map for each class value, with a `create` key.** (1) `_each` gives a Map with an `id` to the
  plugins registry. A controller then needs a marker key and a changed `_each`. Rejected.
- **A Map read for `id` without the typed slot.** (2) The read costs 8.56 ns against 1.78 ns on
  AOT. On dart2wasm, it costs 12.37 ns against 1.17 ns (probe 4). (3) The structure is the same.
  Rejected, because the slot is faster with the same structure.

**`isForType`.**
- **A kind test** (performance draft: `type is C`, with the row `adapt-registry-is-for-type`). (1)
  It gives the upstream registry for each class value with an `id`. It is not strict for a base
  class. (3) A `DIVERGES` hunk. Rejected.
- **A covariant type test** (simplicity draft: `type is ComponentClass<T>`). (1) It is exact for
  the component classes. The base classes have no component class in that draft. Rejected with its
  class form.

**`new.target`.**
- **A required third constructor parameter** (performance and simplicity drafts). (1) The same
  result in `buildOrUpdateControllers`. (3) Each direct construction passes a class value, where
  upstream passes none. The optional parameter gives the `new.target` of a direct call. Rejected for
  (3).
- **A global variable** that `jsConstruct` sets before the call. (1) A direct Dart call inside
  another construction reads the wrong value. Rejected.
- **An instance getter `constructor`, or a virtual getter in each class.** (1) Take a registered
  class value without a Dart class of its own. Its instances read the value of the Dart superclass.
  `Object.assign` wrote the element types onto the subclass value. Thus the instances read the
  wrong element types. Rejected.
- **`registry.getController(meta.type)` in the constructor.** (1) A direct construction gets
  another class than `new.target`. (3) A hidden dependency. Rejected.

**Plugin form and hook dispatch.** Probe 8 measures the forms in one harness. The harness has 7
plugins with the hooks and parameter counts of the built-in plugins, and 35 notifies for each cycle.
The figures are ns for each notify, the median of three processes:

| Form | AOT | dart2wasm |
|---|---|---|
| A: the literal port: Map read, `params` for each plugin, `callback`. Descriptor of type `AnyObject` | 87.0 | 131.4 |
| M: the read of section 7, descriptor of type `AnyObject` (the judge form) | 58.9 | 90.0 |
| Ms: descriptor of type `Object`, test `is Map<String, Object?>` | 76.0 | 125.9 |
| Md: descriptor of type `Object`, test `is Map<dynamic, dynamic>` | 75.1 | 92.6 |
| Mr: Md with the record descriptor | 74.7 | 94.3 |
| Mrc: Mr with the class value case in `jsIsFunction` (chosen) | 76.9 | 93.7 |
| Mg: descriptor of type `Object`, `jsGet` for each read | 121.0 | 159.1 |
| CT: the typed `Plugin` slots of the performance draft | 20.7 | 25.4 |

The judge ran the same harness before probe 8. That run gave A 88 and 131 ns, M 59.5 and 85 ns,
and CT 21 and 26 ns. It also measured MX, the `_notify` of the performance draft with Map plugins:
106 ns on AOT and 189 ns on dart2wasm.

- **The literal port (A).** (1) The same. (2) Slower than the chosen form. (3) The same lines.
  Rejected, because the chosen form keeps the structure and is faster (section 13).
- **The test `is Map<String, Object?>` (Ms).** (1) The same. (2) 33 ns slower on dart2wasm for each
  notify. Rejected.
- **Typed hook slots (CT, performance draft).** A `Plugin` class keeps a list of typed hooks with a
  slot for each of the 35 known names. A Map of extra hooks takes other names. `operator []=` writes
  the slot. The Map plugins keep a branch of their own.
  - (1) The same for typed plugins. The extras Map takes a custom hook name. A spy write through
    `operator []=` reaches the next notify. Thus CT has no behavior objection.
  - (2) 20.7 ns against 76.9 ns on AOT, and 25.4 ns against 93.7 ns on dart2wasm, for each notify.
    The gain is below the resolution of the frame figures (section 13).
  - (2) The Map branch of the performance draft (MX) makes the `params` list for each plugin. It is
    slower than the literal port. If a later ADR adopts CT, its Map branch must keep the skip before
    the `params` list.
  - (3) A second plugin form, a table of 35 hook names, a hook type without `this` and 5 `adapt`
    rows. (4) More code.
  - Deferred to phase 8. Phase 8 measures the built-in plugins in the gallery. A new ADR adopts CT
    when the dispatch shows in the frame figures.
- **The chosen form plus a direct call of a typed hook** (fidelity F2m). (2) No stable gain in
  probe 3. On AOT, it gave 74 ns against 76 ns. On dart2wasm, it gave 100 to 125 ns against 114 ns
  in two builds. (3) A branch and a rule for hook signatures. Rejected.
- **A plugin class with a field for each hook and a `switch` by name** (fidelity F3, performance B,
  simplicity C). (2) The slowest form: 197 ns on AOT and 174 ns on dart2wasm in probe 3. A `switch`
  over the hook names compares strings one by one. (3) A plugin class has no upstream counterpart.
  Rejected.
- **Named fields with an `int` switch, or a virtual method for each hook** (performance D and E,
  simplicity D). (2) 81 ns and 66 ns on AOT, 54 ns and 53 ns on dart2wasm (probe 10). They are
  slower than CT. (3) A class for each plugin. Rejected.
- **A hook enum with a hook table for each plugin** (fidelity F4), and **a hook list by index**
  (simplicity E). (2) 18 ns on AOT and 13 ns on dart2wasm (probe 3). These forms are CT with
  another key. A table that `operator []=` keeps current also keeps the read at each call. A write
  to a Map entry does not reach the table. Thus Map plugins need the Map branch. Rejected on (3),
  (4) and the size of the gain, as CT.
- **A cache of the plugins that have each hook** (fidelity F5, performance F). (2) 23 ns on AOT and
  31 ns on dart2wasm (probe 3). (1) The cache lives until the next `invalidate()`
  (`core.controller.js:488`). A write to a Map plugin between two updates does not reach it.
  Upstream reads `plugin[hook]` at each call (`core.plugins.js:63`). With a `Plugin` class whose
  `operator []=` drops the cache, it is a variant of CT. Rejected for (1) with Map plugins, and as
  CT for typed plugins.
- **The slot index at the call site** (performance G). (2) 14 ns on AOT and 17 ns on dart2wasm
  (probe 10). (3) It changes about 30 call sites of `notifyPlugins` and the public signature.
  Rejected.
- **A final class for `PluginDescriptor`.** (2) No stable difference (probe 8, Md against Mr). On
  AOT, it gave 75.1 ns against 74.7 ns. On dart2wasm, it gave 92.6 ns against 94.3 ns.
  [Chart.js ADR 0003](0003-type-only-dependencies.md) gives a record. Rejected.
- **A filter with the arguments of `Array.prototype.filter` through `jsCall`.** (1) No user function
  reaches the filter (`index.d.ts:555`). (4) More code. Rejected.
- **`JsError` for `new Error`** (performance draft). (3) The port already uses `StateError` with the
  upstream message (`helpers.config.dart:653`). Rejected.

**Rest parameters.**
- **Optional positional parameters** (`register(Object? a, [Object? b = _absent, ...])`). (1) A
  spread has no form. A fixed count limits the items. (3) The call `Chart.register(a, b)` looks like
  upstream. Rejected.
- **One loopable parameter** (`register(Object? items)`). (1) `Chart.register(...registerables)`
  has no form, because `Chart.register(registerables)` throws upstream. A List then has two
  meanings. Rejected.

**`registerables`.**
- **The Maps in the source order of the four `index.js` files** (simplicity draft). (1) The source
  order of `controllers/index.js` and `elements/index.js` is not the code unit order. The bundle
  registers `pie` before `polarArea` and `bar` before `line` (probe 2). The source order gives
  another order of `items`, `defaults.datasets` and `overrides`. Rejected.

**`Chart.registry`.**
- **No static `registry`** (performance draft). (1) `index.d.ts:565` declares only the static. 52
  spec lines read it. Rejected.
- **The instance getter under another name.** (3) A member with no upstream name. The one reader
  (`controller.scatter.js:105`) can read the singleton. Rejected.

**User registration.**
- **A typed helper now**, for example a function that makes a controller class value from a
  constructor tear-off. (1) The same class values. (2) Registration is not on the frame path. (3) No
  upstream counterpart. (4) More code before a user needs it. Rejected for phase 5.

**Layers.**
- **The class values of the base classes in a port-only pure file.** `core.registry.dart` then
  imports no file that reaches `helpers.extras`. (2) No frame gain. The registry spec runs on the VM
  in any case (section 10). (3) The class values move away from their classes. The imports of
  `core.registry.js:1-3` change. Rejected.

**`getRange`.**
- **`getRange` in `types.VisualElement`**, with a method of `ArcElement` and `LineElement` that
  gives the result of the upstream test for an absent method. (1) A direct call gives a value where
  JavaScript throws a `TypeError`. It needs a row. (4) Two more methods. Rejected.
- **The test `el is PointElement || el is BarElement`.** (1) A user element with `getRange` does
  not get the binary search. Rejected.
- **An optional parameter in `BarElement.getRange`** (fidelity draft). (4) It is not necessary.
  `PointElement.getRange([String? axis])` and `BarElement.getRange(String axis)` both implement
  `double getRange(String axis)` (probe 9). Rejected.

## Consequences

- Each class that upstream registers, keeps as a value or constructs from a value has a static
  `jsClass`. Each upstream superclass of such a class has one too. Phase 5 adds it to `Element`,
  the four elements, `DatasetController` and `Scale`. Phases 6 to 8 add it to the scales,
  `LinearScaleBase`, the controllers and the element classes of the plugins.
- The registry, the controller and the plugin service read static properties by name, as upstream.
  A subclass inherits the static properties of its superclass. `PieController` gets the doughnut
  `overrides` and `descriptors`. `TimeSeriesScale` registers `TimeScale` first.
- The plugin hooks run in the upstream order: the `jsObjectKeys` order of
  `registry.plugins.items`, then the inline plugins.
- The built-in plugins of phase 8 are top-level Maps. Their hooks keep the upstream parameter
  counts.
- `Chart.register` takes one list. A spread of upstream becomes the list itself.
- `PointElement` and `BarElement` implement `types.VisualElementRange`. Their `getRange` signatures
  do not change.
- The JS runtime gets one file (`js_class.dart`) and two changes: the `jsGet` case and
  `jsIsFunction`. The documentation of `jsCall` names the class value case.
- `differences.md` gets three rows: `js-semantics-class-source`, `adapt-chart-registry-getter` and
  `adapt-component-class-role`.
- The two open items of [Chart.js ADR 0017](0017-element-properties.md) get their answer here.
  Sections 3 and 4 give the reads of the static members and of the constructor. Section 9 gives
  `getRange`.
- The dispatch costs 77 ns on AOT and 94 ns on dart2wasm for each notify of 7 plugins (probe 8,
  Apple M3 Max):
  - One draw with 3 datasets makes 10 notifies: about 0.8 µs and 0.9 µs.
  - One `update()` plus `render()` with 2 scales and 3 datasets makes 35 notifies: about 2.7 µs and
    3.3 µs.
  - One draw with 100 datasets makes 204 notifies: about 16 µs and 19 µs.
- The `args` Map that a call site makes, for example `{mode, cancelable: true}`, costs more than
  the dispatch. It adds 53 ns on AOT and 31 ns on dart2wasm to a notify (probe 10, form "alloc").
  Upstream makes the same objects. The port of `core.controller` keeps them. The frame figures of
  phase 5 include their cost.
- The registry spec and `core.registry_test.dart` run on the VM only. `core.typedRegistry_test.dart`
  and `js_class_test.dart` also run with dart2js and dart2wasm. `core.typedRegistry.dart` becomes a
  pure-layer root of tool 1.

## Open

- The frame figures of the dispatch on the Pixel 8a, macOS, Chrome with dart2wasm and the iPhone.
  The probes ran only on an Apple M3 Max, with AOT and with dart2wasm in Node.js v24.12.0. Phase 5
  records the frame figures when it draws charts. Phase 8 records them with the real plugins in
  `performance.md`. A gain of CT in these figures brings a new ADR (section 13).
- The layer of `core.registry.dart` and `core.plugins.dart` (section 10). They become pure layers
  if a later ADR makes `core.scale.dart` and `core.datasetController.dart` pure. Then tool 1 adds
  them as roots.
- The parameter types of the `Scale` and `DatasetController` constructors. The ports of
  `core.scale.js` and `core.datasetController.js` decide them. The `construct` closures follow
  them.
- `jsGet` reads an absent key of a Map twice. A faster read of an absent key helps each caller of
  `jsGet`. It is outside this decision.
- A typed front end for user plugins and user classes. It can come with the typed options API after
  0.1.0.

## Evidence

The probes are in the folder
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/42473ad1-0196-429c-8b17-c32d881d14b9/scratchpad/design/registry/`.
The paths below are relative to it. The machine is an Apple M3 Max with macOS 26.5.1, Dart 3.12.2
(Flutter 3.44.9) and Node.js v24.12.0 (arm64, V8 13.6). Other processes ran at the same time.
`dart compile exe` gives the AOT figures. `dart compile wasm`, run with a `.mjs` loader in Node.js,
gives the dart2wasm figures. No probe gives JavaScript reference values for a test. Thus the x64
rule of [Chart.js ADR 0010](0010-js-numeric-semantics.md) does not apply.

1. **The pinned registry** (`fidelity/probes/registry_behavior.mjs`, output
   `fidelity/probes/registry_behavior.out`). Node.js runs `third_party/Chart.js/src/index.ts`
   without its TypeScript types. A resolve hook maps the `.js` imports to the `.ts` files. An x64
   run of Node.js v24.19.0 under Rosetta gives the same output
   (`fidelity/probes/registry_behavior.x64.out`). Results:
   - `register(PieController, ScatterController, TimeSeriesScale)` gives the controller items
     `doughnut`, `pie`, `scatter` and the scale items `time`, `timeseries`.
   - `PieController.overrides === DoughnutController.overrides` is true, with no own property.
     `overrides.pie` has the keys `aspectRatio` and `plugins`.
   - `isForType` of a plain class gives false, false, false, true (controllers, scales, elements,
     plugins). `LinearScale` gives false, true, true, true. An ordinary function gives true for the
     plugins. `{id}` and a string give false. `null` throws a `TypeError`.
   - The messages:
     - `'class does not have id: bar'`
     - `'class does not have id: class FaultyPlugin {}'`
     - the full source text for a class with a body
     - `'class does not have id: [object Object]'` for a nested list
     - `'"nope" is not a registered controller.'`
   - `register(null)` and `register(undefined)` throw a `TypeError`. `register(5)` does not throw.
   - A duplicate `id` keeps the first class. A subclass without own `defaults` registers the
     `defaults` of its superclass. `Object.assign(MyLine, {dataElementType})` does not change
     `LineController.dataElementType`. An inherited `beforeRegister` gets the subclass as `this`.
2. **The published bundle** (`fidelity/probes/registry_dist.mjs`, output
   `fidelity/probes/registry_dist.out`, the npm tarball `fidelity/dl-chartjs/chart.js-4.5.1.tgz`).
   Node.js runs `package/dist/chart.js`. The namespaces are frozen objects with a `null` prototype.
   `Chart.register(...registerables)` gives these items in this order:
   - plugins: `colors`, `decimation`, `filler`, `legend`, `subtitle`, `title`, `tooltip`
   - controllers: `bar`, `bubble`, `doughnut`, `line`, `pie`, `polarArea`, `radar`, `scatter`
   - elements: `arc`, `bar`, `line`, `point`
   - scales: `category`, `linear`, `logarithmic`, `radialLinear`, `time`, `timeseries`

   `Chart.register(registerables)` throws
   `TypeError: Cannot use 'in' operator to search for 'id' in null`. The x64 run gives the same
   output (`fidelity/probes/registry_dist.x64.out`).
3. **The hook dispatch of the fidelity draft** (`fidelity/bench/bin/plugin_dispatch.dart`, outputs
   `fidelity/probes/plugin_dispatch_aot.out` and `fidelity/probes/plugin_dispatch_wasm.out`). One
   sequence has 24 notifies without the scale hooks. The figure is the time for one notify of 7
   plugins, the median of three runs, in ns. Build 1
   (`fidelity/bench/bin/plugin_dispatch_build1.dart`) gives 114 ns for F1m and 100 ns for F2m on
   dart2wasm:

   | Form | AOT | dart2wasm |
   |---|---|---|
   | F1: the literal port with `jsGet` | 147 | 201 |
   | F1m: the read of section 7 with a `Map<String, Object?>` test | 76 | 114 |
   | F2m: F1m with a direct call of a typed hook | 74 | 125 (100 in build 1) |
   | F3: a plugin class, `switch` by name | 197 | 174 |
   | F4: a hook enum and a hook table | 18 | 13 |
   | F5: a cache of the plugins that have each hook | 23 | 31 |

4. **The class value reads** (`fidelity/bench/bin/class_value.dart`, outputs
   `fidelity/probes/class_value_aot.out` and `fidelity/probes/class_value_wasm.out`). The probe
   makes 20000 reads of `dataElementType.id` and 20000 constructions. The figure is the best of
   three passes, in ns for each operation:

   | Operation | AOT | dart2wasm |
   |---|---|---|
   | `id`, a Map read through the chain | 8.56 | 12.37 |
   | `id`, the typed slot (chosen) | 1.78 | 1.17 |
   | `id`, a typed field of a descriptor | 1.01 | 0.58 |
   | `jsConstruct(cls, const [])` (chosen) | 3.46 | 5.15 |
   | a direct constructor call | 2.86 | 4.91 |
   | a typed factory of a descriptor | 2.85 | 4.72 |

   The judge ran the probe again on AOT: 1.35 ns against 0.82 ns for `id`, and 2.88 ns against
   2.45 ns for the construction.
5. **A prototype of this decision** (`fidelity/proto/lib/js_class.dart`,
   `fidelity/proto/lib/registry.dart`, `fidelity/proto/test/core_registry_test.dart`, output
   `fidelity/probes/proto_test.out`). It ports `JsClass`, `TypedRegistry`, `Registry`, the `Chart`
   statics, `allPlugins` and `_notify` on the real `core.defaults.dart`, `helpers.core.dart` and JS
   runtime of the package. Stand-ins give the class values of `DatasetController` and `Scale`. The
   15 cases of `core.registry.tests.js` and 7 tests of the behaviors of probe 1 pass: 22 of 22. A
   run of the judge copy (`judge/fid_proto/`) for this ADR also passes 22 of 22
   (`final/proto_rerun.out`).
6. **The `jsGet` case** (`fidelity/bench/bin/jsget_case.dart`, outputs
   `fidelity/probes/jsget_case_aot.out` and `fidelity/probes/jsget_case_wasm.out`). A Map read
   through `jsGet` costs 10.03 ns without and 9.94 ns with a class value case after the `String`
   case on AOT. On dart2wasm, both cost 17.6 ns.
7. **The name conflicts** (`fidelity/bench/conflicts/a.dart`, `b.dart`, `c.dart`, output
   `fidelity/probes/conflicts.out`). `dart analyze` gives `conflicting_static_and_instance` for
   three cases:
   - a static `id` in a subclass of a class with an instance `id`
   - a static and an instance `registry` in one class
   - a static and an instance `datasetElementType` in one class

   A static `jsClass` in a class and in its subclass gives no error.
8. **The dispatch forms in one harness** (`final/bench/bin/final_dispatch.dart` with the generated
   `final/bench/lib/forms.dart` of the judge, outputs `final/bench/out/aot_runs.txt` and
   `final/bench/out/wasm_runs.txt`).
   - The harness is the harness of the judge (`judge/bench/bin/judge_dispatch.dart`, outputs
     `judge/bench/out/aot.txt` and `judge/bench/out/wasm.txt`). It has five more forms and no MX.
   - One cycle is the sequence of 35 notifies of the Context. The 7 plugins have the hooks and the
     upstream parameter counts of the built-in plugins.
   - All forms give the same calls in the same order. The driver compares the call logs.
   - Each figure is the median of 11 rounds in one process. The table of the Alternatives gives the
     median of three processes. The load average was 5 to 8 (`final/bench/out/load.txt`).
9. **`getRange` on the phase 4 classes** (`final/range_proto/bin/main.dart`, output
   `final/range_proto/out.txt`). Subclasses of the real `PointElement` and `BarElement` implement an
   interface with `double getRange(String axis)`. They keep the current signatures. `dart analyze`
   finds no issue. The test of section 9 gives `[4.0, 5.0, 2.0, false]` for these four elements:
   - a point with radius 3 and hitRadius 1
   - a bar of width 10 and height 4, on `x` and on `y`
   - an arc

   The simplicity draft gives the same form with stand-in classes
   (`simplicity/dart/get_range/main.dart`).
10. **The probes of the performance draft.**
    - `performance/probe_upstream/registry_probe.mjs` (output `final/perf_registry_probe.out`) runs
      the pinned source. The plugins `zz` and `7` register with `7` first.
      `register(DatasetController)`, `register(Scale)` and `register(Element)` throw
      `class does not have id: ...`. `register({})` registers nothing.
    - `performance/probe_upstream/notify_probe.mjs` (output `final/perf_notify_probe.out`) runs the
      upstream `_notify`. A Dart port runs the same cases with Map plugins
      (`performance/bench/bin/notify_proto.dart`, output `final/perf_notify_proto.out`). The two
      outputs are equal for these cases:
      - the results `undefined`, `null`, 0, `true`, 1 and `false` with `cancelable`
      - `false` without `cancelable`, and `false` without args
      - a hook that clears `cancelable`
      - an absent hook, and a value that is not a function
    - `performance/bench/gen.py` and `performance/bench/bin/plugin_dispatch.dart`, outputs
      `performance/bench/results/aot_cycle.txt` and `performance/bench/results/wasm_cycle.txt`.
      The form "alloc" adds a new two-key args Map to each notify. It gives 91.3 ns against 38.1 ns
      on AOT, and 71.7 ns against 40.6 ns on dart2wasm. The same files give the forms D (81.1 ns
      and 53.5 ns), E (65.8 ns and 53.0 ns) and G (14.2 ns and 17.0 ns).
11. **The probes of the simplicity draft.**
    - `simplicity/js/registry_probe.mjs` (output `final/simplicity_registry_probe.out`) runs the
      pinned source. `plugins.isForType(() => 1)` is false, because an arrow function has no
      `prototype`.
    - `simplicity/js/namespace_order_probe.mjs` (output `final/simplicity_namespace_order.out`)
      gives the keys of the four namespaces in code unit order.
