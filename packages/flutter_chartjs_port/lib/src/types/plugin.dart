// Original code, not ported from Chart.js: the native plugin objects.

/// The native plugins of Chart.js ADR 0144: [Plugin] (the name of
/// `index.d.ts:856`), the hooks ([PluginHook]), the hook function types and
/// the argument classes of the hooks.
///
/// A [Plugin] has one field for each hook, with the function type of its
/// hook. A hook that upstream calls with `cancelable: true` is a
/// [CancelableHookFunction]: it returns `false` to cancel the step. Each
/// other hook is a [PluginHookFunction], which returns nothing. The plugin
/// service (`core.plugins.dart`) calls a hook through [Plugin.notify]. No
/// hook is read by name, and no plugin is a Map.
///
/// The argument classes are plain classes. `args` passes through each hook
/// of one notify by identity.
///
/// This library is a core layer.
library;

import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show ContextResolver;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ScriptableScaleContext;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:meta/meta.dart';

/// The function of a hook that cannot cancel: `hook(chart, args, options)`.
///
/// [A] is the argument class of the hook, and [O] the options type of the
/// plugin ([Plugin.options]).
///
/// ```dart
/// final probe = Plugin<ContextResolver>(
///   id: 'probe',
///   afterDraw: (chart, args, options) => draws++,
/// );
/// ```
typedef PluginHookFunction<A extends Object, O> = void Function(
  types.Chart chart,
  A args,
  O options,
);

/// The function of a cancelable hook: `hook(chart, args, options)`. The
/// result `false` cancels the step of the chart, and `true` continues (U
/// `core.plugins.js:66`).
///
/// ```dart
/// final freeze = Plugin<ContextResolver>(
///   id: 'freeze',
///   beforeUpdate: (chart, args, options) => !frozen,
/// );
/// ```
typedef CancelableHookFunction<A extends Object, O> = bool Function(
  types.Chart chart,
  A args,
  O options,
);

/// A hook of the `Plugin` interface (U `index.d.ts:856-1240` and the hooks
/// of the tooltip plugin, `index.d.ts:2777-2786`), with its JS name and the
/// argument class [A] of its calls.
///
/// A hook is cancelable when upstream calls it with `cancelable: true`. The
/// call sites decide it, not the declarations of `index.d.ts`.
///
/// ```dart
/// chart.notifyPlugins(PluginHook.afterDraw);
/// ```
enum PluginHook<A extends Object>(
  /// The JS name of the hook.
  final String jsName, {

  /// Whether a hook of the plugin can cancel the step with `false`.
  final bool cancelable = false,
}) {
  /// `install` (U `core.plugins.js:38`).
  install<PluginHookArgs>('install'),

  /// `start` (U `core.plugins.js:118`).
  start<PluginHookArgs>('start'),

  /// `stop` (U `core.plugins.js:117`).
  stop<PluginHookArgs>('stop'),

  /// `beforeInit` (U `core.controller.js:238`).
  beforeInit<PluginHookArgs>('beforeInit'),

  /// `afterInit` (U `core.controller.js:249`).
  afterInit<PluginHookArgs>('afterInit'),

  /// `beforeUpdate` (U `core.controller.js:490`).
  beforeUpdate<UpdateHookArgs>('beforeUpdate', cancelable: true),

  /// `afterUpdate` (U `core.controller.js:524`).
  afterUpdate<UpdateHookArgs>('afterUpdate'),

  /// `beforeElementsUpdate` (U `core.controller.js:497`).
  beforeElementsUpdate<PluginHookArgs>('beforeElementsUpdate'),

  /// `reset` (U `core.controller.js:472`).
  reset<PluginHookArgs>('reset'),

  /// `beforeDatasetsUpdate` (U `core.controller.js:649`).
  beforeDatasetsUpdate<UpdateHookArgs>(
    'beforeDatasetsUpdate',
    cancelable: true,
  ),

  /// `afterDatasetsUpdate` (U `core.controller.js:661`).
  afterDatasetsUpdate<UpdateHookArgs>('afterDatasetsUpdate'),

  /// `beforeDatasetUpdate` (U `core.controller.js:673`).
  beforeDatasetUpdate<DatasetUpdateHookArgs>(
    'beforeDatasetUpdate',
    cancelable: true,
  ),

  /// `afterDatasetUpdate` (U `core.controller.js:680`).
  afterDatasetUpdate<DatasetUpdateHookArgs>('afterDatasetUpdate'),

  /// `beforeLayout` (U `core.controller.js:612`).
  beforeLayout<PluginHookArgs>('beforeLayout', cancelable: true),

  /// `beforeDataLimits` (U `core.scale.js:541`).
  beforeDataLimits<ScriptableScaleContext>('beforeDataLimits'),

  /// `afterDataLimits` (U `core.scale.js:545`).
  afterDataLimits<ScriptableScaleContext>('afterDataLimits'),

  /// `beforeBuildTicks` (U `core.scale.js:550`).
  beforeBuildTicks<ScriptableScaleContext>('beforeBuildTicks'),

  /// `afterBuildTicks` (U `core.scale.js:559`).
  afterBuildTicks<ScriptableScaleContext>('afterBuildTicks'),

  /// `afterLayout` (U `core.controller.js:640`).
  afterLayout<PluginHookArgs>('afterLayout'),

  /// `beforeRender` (U `core.controller.js:684`).
  beforeRender<PluginHookArgs>('beforeRender', cancelable: true),

  /// `afterRender` (U `core.controller.js:37`).
  afterRender<PluginHookArgs>('afterRender'),

  /// `beforeDraw` (U `core.controller.js:712`).
  beforeDraw<PluginHookArgs>('beforeDraw', cancelable: true),

  /// `afterDraw` (U `core.controller.js:731`).
  afterDraw<PluginHookArgs>('afterDraw'),

  /// `beforeDatasetsDraw` (U `core.controller.js:766`).
  beforeDatasetsDraw<PluginHookArgs>('beforeDatasetsDraw', cancelable: true),

  /// `afterDatasetsDraw` (U `core.controller.js:775`).
  afterDatasetsDraw<PluginHookArgs>('afterDatasetsDraw'),

  /// `beforeDatasetDraw` (U `core.controller.js:793`).
  beforeDatasetDraw<DatasetDrawHookArgs>('beforeDatasetDraw', cancelable: true),

  /// `afterDatasetDraw` (U `core.controller.js:808`).
  afterDatasetDraw<DatasetDrawHookArgs>('afterDatasetDraw'),

  /// `beforeEvent` (U `core.controller.js:1172`).
  beforeEvent<EventHookArgs>('beforeEvent', cancelable: true),

  /// `afterEvent` (U `core.controller.js:1179`).
  afterEvent<EventHookArgs>('afterEvent'),

  /// `resize` (U `core.controller.js:292`).
  resize<ResizeHookArgs>('resize'),

  /// `beforeDestroy` (U `core.controller.js:938`).
  beforeDestroy<PluginHookArgs>('beforeDestroy'),

  /// `afterDestroy` (U `core.controller.js:954`).
  afterDestroy<PluginHookArgs>('afterDestroy'),

  /// `uninstall` (U `core.plugins.js:50`).
  uninstall<PluginHookArgs>('uninstall'),

  /// `beforeTooltipDraw` (U `plugin.tooltip.js:1254`).
  beforeTooltipDraw<TooltipDrawHookArgs>('beforeTooltipDraw', cancelable: true),

  /// `afterTooltipDraw` (U `plugin.tooltip.js:1260`).
  afterTooltipDraw<TooltipDrawHookArgs>('afterTooltipDraw'),
}

/// The arguments `{}` of a hook without arguments (`EmptyObject` of
/// `index.d.ts`), and the base of the argument classes.
///
/// ```dart
/// chart.notifyPlugins(PluginHook.reset, const PluginHookArgs());
/// ```
base class const PluginHookArgs() {
  /// An object without fields.
  this;
}

/// `{mode}` of `beforeUpdate`, `afterUpdate`, `beforeDatasetsUpdate` and
/// `afterDatasetsUpdate` (U `core.controller.js:490`, `:524`, `:649`,
/// `:661`).
///
/// ```dart
/// beforeUpdate: (chart, args, options) => args.mode != 'resize',
/// ```
final class UpdateHookArgs({
  /// `mode`: the update mode of `chart.update(mode)`, a string, a function
  /// or `undefined`.
  required final Object? mode,

  /// Whether this update kept the layout of the last update, so no box ran its
  /// `update`: the data-only lifecycle of Chart.js ADR 0074. It is not a key of
  /// the object, because upstream always runs the layout.
  @internal final bool layoutKept = false,
}) extends PluginHookArgs {
  /// The arguments of an update.
  this;
}

/// `{meta, index, mode}` of `beforeDatasetUpdate` and `afterDatasetUpdate`
/// (U `core.controller.js:670-680`).
///
/// ```dart
/// beforeDatasetUpdate: (chart, args, options) => args.meta.visible,
/// ```
final class DatasetUpdateHookArgs({
  /// `meta`: the meta of the dataset.
  required final types.ChartMeta meta,

  /// `index`: the index of the dataset.
  required final int index,

  /// `mode`: the update mode, as in [UpdateHookArgs.mode].
  required final Object? mode,
}) extends PluginHookArgs {
  /// The arguments of the update of one dataset.
  this;
}

/// `{meta, index}` of `beforeDatasetDraw` and `afterDatasetDraw` (U
/// `core.controller.js:786-808`).
///
/// ```dart
/// afterDatasetDraw: (chart, args, options) => labels.draw(args.meta),
/// ```
final class DatasetDrawHookArgs({
  /// `meta`: the meta of the dataset.
  required final types.ChartMeta meta,

  /// `index`: the index of the dataset.
  required final int index,
}) extends PluginHookArgs {
  /// The arguments of the draw of one dataset.
  this;
}

/// `{event, replay, inChartArea}` of `beforeEvent` and `afterEvent`, and the
/// key `changed` that a plugin writes (U `core.controller.js:1162-1179`).
///
/// ```dart
/// afterEvent: (chart, args, options) {
///   if (args.event.type == 'click') args.changed = select(args.event);
/// },
/// ```
final class EventHookArgs({
  /// `event`: the chart event.
  required final types.ChartEvent event,

  /// `replay`: whether the chart replays the last event in an update.
  required final bool replay,

  /// `inChartArea`: whether the event is in the chart area. A `beforeEvent`
  /// hook can write it: the chart reads it after the hook.
  var bool inChartArea = false,

  /// `changed`: a hook writes `true` to render the chart after the event.
  var bool changed = false,
}) extends PluginHookArgs {
  /// The arguments of an event.
  this;
}

/// `{size}` of `resize` (U `core.controller.js:292`).
///
/// ```dart
/// resize: (chart, args, options) => layoutFor(args.size.width),
/// ```
final class ResizeHookArgs({
  /// `size`: the new size of the chart in logical pixels.
  required final ({double width, double height}) size,
}) extends PluginHookArgs {
  /// The arguments of a resize.
  this;
}

/// `{tooltip}` of `beforeTooltipDraw` and `afterTooltipDraw` (U
/// `plugin.tooltip.js:1250-1260`).
///
/// ```dart
/// beforeTooltipDraw: (chart, args, options) => args.tooltip.opacity > 0,
/// ```
final class TooltipDrawHookArgs({
  /// `tooltip`: the tooltip of the chart.
  required final types.TooltipModel tooltip,
}) extends PluginHookArgs {
  /// The arguments of the draw of the tooltip.
  this;
}

/// `Plugin` (U `index.d.ts:856`): a plugin with its `id`, its metadata and
/// one field for each hook.
///
/// [O] is the type of the options that the hooks get: [options] makes it
/// from the resolved options of the plugin, a [ContextResolver]. A hook is a
/// field, so a test can replace it at run time, as upstream code replaces
/// `plugin[hook]`. A plugin is not a `Map`, and it has no key by name.
///
/// ```dart
/// final crosshair = Plugin<ContextResolver>(
///   id: 'crosshair',
///   afterDraw: (chart, args, options) => drawCrosshair(chart),
///   beforeEvent: (chart, args, options) => args.event.type != 'mouseout',
/// );
/// Chart.register([crosshair]);
/// ```
final class Plugin<O>({
  /// `id`: the id of the plugin, the key of its options in
  /// `options.plugins`.
  required final String id,

  /// Makes the options that the hooks get from the resolved options of the
  /// plugin, for example the constructor of an extension type over them.
  /// Dart `null` gives the resolved options themselves: then [O] must be
  /// [ContextResolver], `Object` or `Object?`.
  final O Function(ContextResolver options)? options,

  /// `events`: the event types of the plugin.
  final List<String>? events,

  /// `defaults`: the default options, which the registry merges into
  /// `defaults.plugins.<id>`. A built-in plugin gives a typed scope, and
  /// another plugin a `Map<String, Object?>`.
  final Object? defaults,

  /// `defaultRoutes`: a route of the defaults for each option key, for
  /// example `{'color': 'color'}` (`defaults.route`).
  final Map<String, String>? defaultRoutes,

  /// `descriptors`: the `_scriptable` and `_indexable` rules of the options.
  /// A built-in plugin gives a typed scope, and another plugin a
  /// `Map<String, Object?>`.
  final Object? descriptors,

  /// `additionalOptionScopes`: more scopes of the options after
  /// `plugins.<id>` (U `core.config.js:267-278`).
  final List<String>? additionalOptionScopes,

  /// Opt into Chart.updateData's data/update/draw hooks without layout hooks.
  /// Such hooks must not mutate configuration, source/parsed data or structure.
  /// They may refresh their own derived state from the committed chart data.
  /// This Dart capability is deliberately outside the JavaScript own keys.
  final bool supportsDataUpdates = false,

  /// Optional additional eligibility check of the resolved plugin options.
  /// It must be observational only and must not modify the chart or options.
  final bool Function(O options)? dataUpdateGuard,

  /// `install` (U `core.plugins.js:38`).
  /// It cannot cancel.
  var PluginHookFunction<PluginHookArgs, O>? install,

  /// `start` (U `core.plugins.js:118`).
  /// It cannot cancel.
  var PluginHookFunction<PluginHookArgs, O>? start,

  /// `stop` (U `core.plugins.js:117`).
  /// It cannot cancel.
  var PluginHookFunction<PluginHookArgs, O>? stop,

  /// `beforeInit` (U `core.controller.js:238`).
  /// It cannot cancel.
  var PluginHookFunction<PluginHookArgs, O>? beforeInit,

  /// `afterInit` (U `core.controller.js:249`).
  /// It cannot cancel.
  var PluginHookFunction<PluginHookArgs, O>? afterInit,

  /// `beforeUpdate` (U `core.controller.js:490`).
  /// Cancelable: `false` cancels the step.
  var CancelableHookFunction<UpdateHookArgs, O>? beforeUpdate,

  /// `afterUpdate` (U `core.controller.js:524`).
  /// It cannot cancel.
  var PluginHookFunction<UpdateHookArgs, O>? afterUpdate,

  /// `beforeElementsUpdate` (U `core.controller.js:497`).
  /// It cannot cancel.
  var PluginHookFunction<PluginHookArgs, O>? beforeElementsUpdate,

  /// `reset` (U `core.controller.js:472`).
  /// It cannot cancel.
  var PluginHookFunction<PluginHookArgs, O>? reset,

  /// `beforeDatasetsUpdate` (U `core.controller.js:649`).
  /// Cancelable: `false` cancels the step.
  var CancelableHookFunction<UpdateHookArgs, O>? beforeDatasetsUpdate,

  /// `afterDatasetsUpdate` (U `core.controller.js:661`).
  /// It cannot cancel.
  var PluginHookFunction<UpdateHookArgs, O>? afterDatasetsUpdate,

  /// `beforeDatasetUpdate` (U `core.controller.js:673`).
  /// Cancelable: `false` cancels the step.
  var CancelableHookFunction<DatasetUpdateHookArgs, O>? beforeDatasetUpdate,

  /// `afterDatasetUpdate` (U `core.controller.js:680`).
  /// It cannot cancel.
  var PluginHookFunction<DatasetUpdateHookArgs, O>? afterDatasetUpdate,

  /// `beforeLayout` (U `core.controller.js:612`).
  /// Cancelable: `false` cancels the step.
  var CancelableHookFunction<PluginHookArgs, O>? beforeLayout,

  /// `beforeDataLimits` (U `core.scale.js:541`).
  /// It cannot cancel.
  var PluginHookFunction<ScriptableScaleContext, O>? beforeDataLimits,

  /// `afterDataLimits` (U `core.scale.js:545`).
  /// It cannot cancel.
  var PluginHookFunction<ScriptableScaleContext, O>? afterDataLimits,

  /// `beforeBuildTicks` (U `core.scale.js:550`).
  /// It cannot cancel.
  var PluginHookFunction<ScriptableScaleContext, O>? beforeBuildTicks,

  /// `afterBuildTicks` (U `core.scale.js:559`).
  /// It cannot cancel.
  var PluginHookFunction<ScriptableScaleContext, O>? afterBuildTicks,

  /// `afterLayout` (U `core.controller.js:640`).
  /// It cannot cancel.
  var PluginHookFunction<PluginHookArgs, O>? afterLayout,

  /// `beforeRender` (U `core.controller.js:684`).
  /// Cancelable: `false` cancels the step.
  var CancelableHookFunction<PluginHookArgs, O>? beforeRender,

  /// `afterRender` (U `core.controller.js:37`).
  /// It cannot cancel.
  var PluginHookFunction<PluginHookArgs, O>? afterRender,

  /// `beforeDraw` (U `core.controller.js:712`).
  /// Cancelable: `false` cancels the step.
  var CancelableHookFunction<PluginHookArgs, O>? beforeDraw,

  /// `afterDraw` (U `core.controller.js:731`).
  /// It cannot cancel.
  var PluginHookFunction<PluginHookArgs, O>? afterDraw,

  /// `beforeDatasetsDraw` (U `core.controller.js:766`).
  /// Cancelable: `false` cancels the step.
  var CancelableHookFunction<PluginHookArgs, O>? beforeDatasetsDraw,

  /// `afterDatasetsDraw` (U `core.controller.js:775`).
  /// It cannot cancel.
  var PluginHookFunction<PluginHookArgs, O>? afterDatasetsDraw,

  /// `beforeDatasetDraw` (U `core.controller.js:793`).
  /// Cancelable: `false` cancels the step.
  var CancelableHookFunction<DatasetDrawHookArgs, O>? beforeDatasetDraw,

  /// `afterDatasetDraw` (U `core.controller.js:808`).
  /// It cannot cancel.
  var PluginHookFunction<DatasetDrawHookArgs, O>? afterDatasetDraw,

  /// `beforeEvent` (U `core.controller.js:1172`).
  /// Cancelable: `false` cancels the step.
  var CancelableHookFunction<EventHookArgs, O>? beforeEvent,

  /// `afterEvent` (U `core.controller.js:1179`).
  /// It cannot cancel.
  var PluginHookFunction<EventHookArgs, O>? afterEvent,

  /// `resize` (U `core.controller.js:292`).
  /// It cannot cancel.
  var PluginHookFunction<ResizeHookArgs, O>? resize,

  /// `beforeDestroy` (U `core.controller.js:938`).
  /// It cannot cancel.
  var PluginHookFunction<PluginHookArgs, O>? beforeDestroy,

  /// `afterDestroy` (U `core.controller.js:954`).
  /// It cannot cancel.
  var PluginHookFunction<PluginHookArgs, O>? afterDestroy,

  /// `uninstall` (U `core.plugins.js:50`).
  /// It cannot cancel.
  var PluginHookFunction<PluginHookArgs, O>? uninstall,

  /// `beforeTooltipDraw` (U `plugin.tooltip.js:1254`).
  /// Cancelable: `false` cancels the step.
  var CancelableHookFunction<TooltipDrawHookArgs, O>? beforeTooltipDraw,

  /// `afterTooltipDraw` (U `plugin.tooltip.js:1260`).
  /// It cannot cancel.
  var PluginHookFunction<TooltipDrawHookArgs, O>? afterTooltipDraw,
}) {
  /// A plugin with the given id, options and hooks.
  this {
    assert(
      options != null || <ContextResolver>[] is List<O>,
      'Plugin<$O> $id: give options, a function that makes a $O.',
    );
  }

  /// The check of the resolved plugin options for `Chart.updateRanges`
  /// (Chart.js ADR 0111), or Dart `null` for none. A false result sends the
  /// range update to `update`. A built-in plugin whose hooks write the
  /// configuration under some options sets it: the colors plugin with
  /// `forceOverride` writes new color Lists into the datasets in each layout,
  /// and a kept dataset resolver would keep the old List. It must be
  /// observational only. It is a Dart field outside the JavaScript own keys.
  @internal
  // DIVERGES(chartjs): adapt-range-updates, the guard of a built-in plugin.
  bool Function(O options)? rangeUpdateGuard;

  /// Calls the hook [hook] of this plugin with `(chart, args, options)`, the
  /// options made from the resolved options [view] (U `core.plugins.js:59-71`).
  ///
  /// The result is `false` when a cancelable hook cancels, else `true`: an
  /// absent hook continues. The plugin service calls it. The hook fields are
  /// read here, where their type has the [O] of this plugin: a read through
  /// `Plugin<Object?>` fails the covariance check of Dart.
  @internal
  bool notify<A extends Object>(
    PluginHook<A> hook,
    types.Chart chart,
    A args,
    Object view,
  ) => switch (hook) {
    PluginHook.install => _call(install, chart, args as PluginHookArgs, view),
    PluginHook.start => _call(start, chart, args as PluginHookArgs, view),
    PluginHook.stop => _call(stop, chart, args as PluginHookArgs, view),
    PluginHook.beforeInit => _call(
      beforeInit,
      chart,
      args as PluginHookArgs,
      view,
    ),
    PluginHook.afterInit => _call(
      afterInit,
      chart,
      args as PluginHookArgs,
      view,
    ),
    PluginHook.beforeUpdate => _cancel(
      beforeUpdate,
      chart,
      args as UpdateHookArgs,
      view,
    ),
    PluginHook.afterUpdate => _call(
      afterUpdate,
      chart,
      args as UpdateHookArgs,
      view,
    ),
    PluginHook.beforeElementsUpdate => _call(
      beforeElementsUpdate,
      chart,
      args as PluginHookArgs,
      view,
    ),
    PluginHook.reset => _call(reset, chart, args as PluginHookArgs, view),
    PluginHook.beforeDatasetsUpdate => _cancel(
      beforeDatasetsUpdate,
      chart,
      args as UpdateHookArgs,
      view,
    ),
    PluginHook.afterDatasetsUpdate => _call(
      afterDatasetsUpdate,
      chart,
      args as UpdateHookArgs,
      view,
    ),
    PluginHook.beforeDatasetUpdate => _cancel(
      beforeDatasetUpdate,
      chart,
      args as DatasetUpdateHookArgs,
      view,
    ),
    PluginHook.afterDatasetUpdate => _call(
      afterDatasetUpdate,
      chart,
      args as DatasetUpdateHookArgs,
      view,
    ),
    PluginHook.beforeLayout => _cancel(
      beforeLayout,
      chart,
      args as PluginHookArgs,
      view,
    ),
    PluginHook.beforeDataLimits => _call(
      beforeDataLimits,
      chart,
      args as ScriptableScaleContext,
      view,
    ),
    PluginHook.afterDataLimits => _call(
      afterDataLimits,
      chart,
      args as ScriptableScaleContext,
      view,
    ),
    PluginHook.beforeBuildTicks => _call(
      beforeBuildTicks,
      chart,
      args as ScriptableScaleContext,
      view,
    ),
    PluginHook.afterBuildTicks => _call(
      afterBuildTicks,
      chart,
      args as ScriptableScaleContext,
      view,
    ),
    PluginHook.afterLayout => _call(
      afterLayout,
      chart,
      args as PluginHookArgs,
      view,
    ),
    PluginHook.beforeRender => _cancel(
      beforeRender,
      chart,
      args as PluginHookArgs,
      view,
    ),
    PluginHook.afterRender => _call(
      afterRender,
      chart,
      args as PluginHookArgs,
      view,
    ),
    PluginHook.beforeDraw => _cancel(
      beforeDraw,
      chart,
      args as PluginHookArgs,
      view,
    ),
    PluginHook.afterDraw => _call(
      afterDraw,
      chart,
      args as PluginHookArgs,
      view,
    ),
    PluginHook.beforeDatasetsDraw => _cancel(
      beforeDatasetsDraw,
      chart,
      args as PluginHookArgs,
      view,
    ),
    PluginHook.afterDatasetsDraw => _call(
      afterDatasetsDraw,
      chart,
      args as PluginHookArgs,
      view,
    ),
    PluginHook.beforeDatasetDraw => _cancel(
      beforeDatasetDraw,
      chart,
      args as DatasetDrawHookArgs,
      view,
    ),
    PluginHook.afterDatasetDraw => _call(
      afterDatasetDraw,
      chart,
      args as DatasetDrawHookArgs,
      view,
    ),
    PluginHook.beforeEvent => _cancel(
      beforeEvent,
      chart,
      args as EventHookArgs,
      view,
    ),
    PluginHook.afterEvent => _call(
      afterEvent,
      chart,
      args as EventHookArgs,
      view,
    ),
    PluginHook.resize => _call(resize, chart, args as ResizeHookArgs, view),
    PluginHook.beforeDestroy => _call(
      beforeDestroy,
      chart,
      args as PluginHookArgs,
      view,
    ),
    PluginHook.afterDestroy => _call(
      afterDestroy,
      chart,
      args as PluginHookArgs,
      view,
    ),
    PluginHook.uninstall => _call(
      uninstall,
      chart,
      args as PluginHookArgs,
      view,
    ),
    PluginHook.beforeTooltipDraw => _cancel(
      beforeTooltipDraw,
      chart,
      args as TooltipDrawHookArgs,
      view,
    ),
    PluginHook.afterTooltipDraw => _call(
      afterTooltipDraw,
      chart,
      args as TooltipDrawHookArgs,
      view,
    ),
  };

  /// Whether the data-only lifecycle can run this plugin with the resolved
  /// options [view] (Chart.js ADR 0074).
  @internal
  bool allowsDataUpdates(Object view) =>
      supportsDataUpdates && (dataUpdateGuard?.call(_optionsOf(view)) ?? true);

  /// Whether `Chart.updateRanges` can keep this plugin with the resolved
  /// options [view] (Chart.js ADR 0111).
  @internal
  bool allowsRangeUpdates(Object view) =>
      supportsDataUpdates && (rangeUpdateGuard?.call(_optionsOf(view)) ?? true);

  /// The options of a hook: [options] of the resolved options [view], or
  /// [view] itself.
  O _optionsOf(Object view) {
    final make = options;
    return make == null ? view as O : make(view as ContextResolver);
  }

  bool _call<A extends Object>(
    PluginHookFunction<A, O>? function,
    types.Chart chart,
    A args,
    Object view,
  ) {
    function?.call(chart, args, _optionsOf(view));
    return true;
  }

  bool _cancel<A extends Object>(
    CancelableHookFunction<A, O>? function,
    types.Chart chart,
    A args,
    Object view,
  ) => function == null || function(chart, args, _optionsOf(view));

  @override
  String toString() => 'Plugin($id)';
}
