# Chart.js ADR 0204: Typed chart components

- Status: accepted (2026-11-25): its code is on main, and the gates of AGENTS.md pass.
- Date: 2026-11-25
- Supersedes: of [Chart.js ADR 0020](0020-registry-and-component-classes.md), §1 to §6 and §8; of
  [Chart.js ADR 0133](0133-construct-helpers-and-meta-for-add-on-chart-types.md), item 1 and the
  `controllerArgs` part of item 2
- Related: [Chart.js ADR 0144](0144-native-plugins.md), [Chart.js ADR 0203](0203-typed-date-adapter.md)

## Context

The registry held `JsClass` values. A `JsClass` stood for a JS class: static properties by name, a superclass
chain and a `construct` closure with `List<Object?>` arguments. The controller build wrote the element types into
the registered class value with `jsAssign` and made the controller with `jsConstruct`. The registry read `id`,
`defaults`, `overrides`, `defaultRoutes`, `descriptors` and the register hooks by name, and took nested Lists and
Maps of items.

## Decision

1. `IChartComponent` (core layer, `lib/src/types/chart_component.dart`) is what a typed registry reads from an
   item: `id`, `parent`, `defaults`, `overrides`, `defaultRoutes` (`Map<String, String>?`) and `descriptors`
   (`DescriptorsScope?`). The JSDoc type `IChartComponent` of `core.typedRegistry.js:4-6` has this name. A plugin
   implements it.
2. `ChartComponent` is the abstract base class of the three kinds. `ElementType` is in the same core file.
   `ControllerType` is in `core.datasetController.dart`, and `ScaleType` and the record `ScaleConfig` are in
   `core.scale.dart`. The base class is not sealed: the element kind must stay in the core layer, and the other
   two kinds cannot. Each kind has a typed `create`, the `new` of the class.

   ```dart
   // Before
   static final JsClass jsClass = JsClass(
     'LineController',
     superclass: DatasetController.jsClass,
     statics: {'id': id, 'defaults': defaults, 'overrides': overrides},
     construct: (newTarget, args) {
       final (:chart, :datasetIndex) = controllerArgs(args);
       return LineController(chart, datasetIndex, newTarget);
     },
   );
   // After
   static final ControllerType component = ControllerType(
     id: id,
     defaults: defaults,
     overrides: overrides,
     create: LineController.new,
   );
   ```

3. A component is immutable, and each field has its own value. `parent` sets only the order of registration and
   the base scope of the defaults (`core.typedRegistry.js:28-32`, `:88`). Thus `PieController.component` names
   the `overrides` and `descriptors` of the doughnut controller.
4. The controller build gives the element types to `create` as the record `ElementTypes`. The constructor of
   `DatasetController` takes it as its last optional parameter, in place of `new.target`. The build writes
   nothing into the registered component.
5. `TypedRegistry<T extends IChartComponent>` keeps `Map<String, T> items`. `Registry` picks the typed registry of
   an item by its Dart type. `getController`, `getScale` and `getElement` take a `String` and give the typed
   component. `Chart.register` and `Chart.unregister` take an `Iterable<IChartComponent>`, with no nested List or
   Map. `registerables` is the `List<IChartComponent>` of the items of the four namespaces.
6. `Scale` takes the record `ScaleConfig`. The option `platform` holds `BasePlatform Function()`.
7. `js_class.dart` is gone: `JsClass`, `jsObjectClass`, `jsConstruct`, `JsConstruct` and `jsAssign`. Also gone:
   `controllerArgs`, `scaleCfgArg`, `elementCfgArg`, the `jsClass` of `Chart`, `Animation`, `Animations`,
   `Element`, `DatasetController`, `Scale`, `Legend`, `Title`, `Tooltip` and the platforms, and the `JsClass`
   branches of `jsGet`, `jsSet`, `isFunction` and `Opt`.

## Consequences

- A component with no `id` or no `defaults` is a compile error, not the `StateError` `class does not have id`.
- `register` takes no nested List or Map. The spec cases with such items skip as
  `diverges: adapt-typed-components`.
- A component inherits no static value. A subclass names the values of its parent class.
- A component is not a function: a resolver never calls it as a scriptable option.
- The sankey port gives its `defaults`, `descriptors` and `overrides` as typed scopes with its keys as extras.
- The row `adapt-typed-components` replaces the rows `adapt-component-class-role`, `adapt-element-type-classes`
  and `js-semantics-class-source`.

## Tests

`test/port/core/core.typedRegistry_test.dart`, `test/port/core/core.registry_test.dart`,
`test/specs/core.registry_test.dart`, `test/port/core/core.datasetController_test.dart`.
