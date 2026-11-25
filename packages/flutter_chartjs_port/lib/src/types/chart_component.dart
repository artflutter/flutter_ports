// Original code, not ported from Chart.js: the typed chart components.

/// The typed components of the registry (Chart.js ADR 0204): the forms of
/// the component classes that Chart.js keeps as values
/// (`core.registry.js:13-16`).
///
/// - [IChartComponent] is what a registry reads from an item: the JSDoc type
///   `IChartComponent` of `core.typedRegistry.js:4-6`. A [ChartComponent]
///   and a plugin implement it.
/// - [ChartComponent] is the base of the three kinds: [ElementType] (this
///   file), `ControllerType` (`core.datasetController.dart`) and `ScaleType`
///   (`core.scale.dart`). Each one holds the static values of its class and
///   a typed `create`, the `new` of the class.
///
/// ```dart
/// // class PointElement extends Element { static id = 'point'; ... }
/// static final ElementType component = ElementType(
///   id: id,
///   defaults: defaults,
///   defaultRoutes: defaultRoutes,
///   create: PointElement.new,
/// );
/// ```
///
/// A component is immutable. Each field has its own value: a component
/// inherits no value of its [IChartComponent.parent].
///
/// This library is a core layer.
library;

import 'package:flutter_chartjs_port/chartjs_core.dart';

/// `IChartComponent` of `core.typedRegistry.js:4-6` and `ChartComponent` of
/// `index.d.ts`: the values that a registry reads from a component or a
/// plugin.
abstract interface class IChartComponent() {
  /// `id`: the key of the item in its registry and of its defaults.
  String get id;

  /// The component that registers first, `Object.getPrototypeOf(item)` when
  /// it is a component (`core.typedRegistry.js:28-32`): its defaults are the
  /// base of the defaults of this item. Dart `null` for a plugin and a
  /// component with no registered superclass.
  IChartComponent? get parent;

  /// `defaults`: the defaults that the registry merges into
  /// `defaults.<scope>.<id>`.
  PluginDefaults? get defaults;

  /// `overrides`: the overrides of a chart type, which the registry of the
  /// controllers writes into `overrides.<id>`.
  ChartOptionsScope? get overrides;

  /// `defaultRoutes`: a route of the defaults for each option key, for
  /// example `{'backgroundColor': 'backgroundColor'}`.
  Map<String, String>? get defaultRoutes;

  /// `descriptors`: the `_scriptable` and `_indexable` rules of the scope.
  DescriptorsScope? get descriptors;
}

/// A register hook of a component: `beforeRegister`, `afterRegister`,
/// `beforeUnregister` or `afterUnregister` (`core.registry.js:151-157`). It
/// gets the component, in place of `this`.
typedef ComponentHook = void Function(ChartComponent component);

/// A component class of Chart.js as a typed value: a controller, a scale or
/// an element (Chart.js ADR 0204).
abstract base class ChartComponent({
  /// `static id`.
  @override required final String id,

  /// `static defaults`.
  @override required final OptionScope defaults,

  /// `static defaultRoutes`.
  @override final Map<String, String>? defaultRoutes,

  /// `static descriptors`.
  @override final DescriptorsScope? descriptors,

  /// `static beforeRegister`.
  final ComponentHook? beforeRegister,

  /// `static afterRegister`.
  final ComponentHook? afterRegister,

  /// `static beforeUnregister`.
  final ComponentHook? beforeUnregister,

  /// `static afterUnregister`.
  final ComponentHook? afterUnregister,
}) implements IChartComponent {
  /// A component with the static values of its class.
  this;

  @override
  ChartComponent? get parent;

  @override
  ChartOptionsScope? get overrides => null;

  @override
  String toString() => '$runtimeType($id)';
}

/// The element types of a dataset controller: the classes of the dataset
/// element and of the data elements (`core.datasetController.js:274-275`).
/// Dart `null` stands for the JS `null` of a controller with no such
/// element.
typedef ElementTypes = ({ElementType? dataset, ElementType? data});

/// An element class as a typed value: `class XElement extends Element` with
/// its statics.
final class ElementType({
  required super.id,
  required super.defaults,

  /// `new XElement()` (`core.datasetController.js:397`, `:1009`).
  required final Element Function() create,
  super.defaultRoutes,
  super.descriptors,
  super.beforeRegister,
  super.afterRegister,
  super.beforeUnregister,
  super.afterUnregister,

  /// The registered element class that this class extends.
  @override final ElementType? parent,
}) extends ChartComponent {
  /// An element type.
  this;
}
