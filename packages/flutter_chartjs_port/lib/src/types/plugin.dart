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
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show DescriptorsScope;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_chartjs_port/src/types/update_mode.dart';
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
/// beforeUpdate: (chart, args, options) => args.mode != UpdateMode.resize,
/// ```
final class UpdateHookArgs({
  /// `mode`: the mode of `chart.update(mode)`, or Dart `null` for the
  /// `undefined` of an update with no mode or with the function form.
  final UpdateMode? mode,

  /// The function of `chart.updateDatasets(modeOf)`, the function form of
  /// upstream `update((ctx) => mode)`, else Dart `null`.
  final UpdateModeOf? modeOf,

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

  /// `mode`: the update mode of the dataset, or Dart `null` for none.
  required final UpdateMode? mode,
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

/// A plugin whose hooks get the chart interface of the core layer: the
/// built-in plugins, the plugins of the tests, and the type of any plugin.
///
/// ```dart
/// final probe = Plugin<Object?>(id: 'probe', afterDraw: (chart, args, _) {});
/// ```
typedef Plugin<O> = PluginOf<O, types.Chart>;

/// The defaults of a plugin: a typed scope of a built-in plugin, or the
/// [PluginOptions] of an add-on (Chart.js ADR 0148).
///
/// ```dart
/// defaults: LegendOptionsScope()..display = true,   // a built-in plugin
/// defaults: const ZoomPluginOptions(...),           // an add-on
/// ```
abstract interface class PluginDefaults();

/// The options of an add-on plugin as one immutable object (Chart.js ADR
/// 0148). Upstream resolves plugin options with `scriptable: false` and
/// `indexable: false` (U `core.plugins.js:182-187`): each option is a plain
/// value, so a merge of the scopes gives the result of the resolver. The
/// plugin service merges the scopes from the defaults to the options of the
/// chart, and the hooks get the merged object.
///
/// ```dart
/// final class ZoomPluginOptions({final PanOptions? pan})
///     extends PluginOptions<ZoomPluginOptions> {
///   @override
///   String get pluginId => 'zoom';
///   @override
///   ZoomPluginOptions merge(ZoomPluginOptions over) =>
///       ZoomPluginOptions(pan: PanOptions.mergeOf(pan, over.pan));
/// }
/// ```
abstract class const PluginOptions<T extends PluginOptions<T>>()
    implements PluginDefaults {
  /// The options of a plugin.
  this;

  /// The id of the plugin: the key of the options in `options.plugins`.
  String get pluginId;

  /// These options with each field of [over] that [over] sets.
  T merge(T over);

  /// [merge] for options of any type: [over] of another class replaces these
  /// options.
  @internal
  PluginOptions<Object?> mergeOptions(PluginOptions<Object?> over) =>
      over is T ? merge(over) : over;
}

/// `Plugin` (U `index.d.ts:856`): a plugin with its `id`, its metadata and
/// one field for each hook.
///
/// [O] is the type of the options that the hooks get: [options] makes it
/// from the resolved options of the plugin, a [ContextResolver], or the
/// hooks get the merged [PluginOptions] of an add-on. [C] is the type of the
/// chart of the hooks: the public `Chart` for `ChartPlugin`, the core
/// interface for [Plugin]. A hook is a field, so a test can replace it at run
/// time, as upstream code replaces `plugin[hook]`. A plugin is not a `Map`,
/// and it has no key by name.
///
/// ```dart
/// final crosshair = ChartPlugin<ContextResolver>(
///   id: 'crosshair',
///   afterDraw: (chart, args, options) => drawCrosshair(chart),
///   beforeEvent: (chart, args, options) => args.event.type != 'mouseout',
/// );
/// Chart.register([crosshair]);
/// ```
final class PluginOf<O, C extends types.Chart>({
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
  /// `defaults.plugins.<id>`: a typed scope of a built-in plugin, or the
  /// [PluginOptions] of an add-on.
  final PluginDefaults? defaults,

  /// `defaultRoutes`: a route of the defaults for each option key, for
  /// example `{'color': 'color'}` (`defaults.route`).
  final Map<String, String>? defaultRoutes,

  /// `descriptors`: the `_scriptable` and `_indexable` rules of the options
  /// of a built-in plugin. The options of an add-on are [PluginOptions], with
  /// no rules.
  final DescriptorsScope? descriptors,

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
  var void Function(C chart, PluginHookArgs args, O options)? install,

  /// `start` (U `core.plugins.js:118`).
  /// It cannot cancel.
  var void Function(C chart, PluginHookArgs args, O options)? start,

  /// `stop` (U `core.plugins.js:117`).
  /// It cannot cancel.
  var void Function(C chart, PluginHookArgs args, O options)? stop,

  /// `beforeInit` (U `core.controller.js:238`).
  /// It cannot cancel.
  var void Function(C chart, PluginHookArgs args, O options)? beforeInit,

  /// `afterInit` (U `core.controller.js:249`).
  /// It cannot cancel.
  var void Function(C chart, PluginHookArgs args, O options)? afterInit,

  /// `beforeUpdate` (U `core.controller.js:490`).
  /// Cancelable: `false` cancels the step.
  var bool Function(C chart, UpdateHookArgs args, O options)? beforeUpdate,

  /// `afterUpdate` (U `core.controller.js:524`).
  /// It cannot cancel.
  var void Function(C chart, UpdateHookArgs args, O options)? afterUpdate,

  /// `beforeElementsUpdate` (U `core.controller.js:497`).
  /// It cannot cancel.
  var void Function(C chart, PluginHookArgs args, O options)?
  beforeElementsUpdate,

  /// `reset` (U `core.controller.js:472`).
  /// It cannot cancel.
  var void Function(C chart, PluginHookArgs args, O options)? reset,

  /// `beforeDatasetsUpdate` (U `core.controller.js:649`).
  /// Cancelable: `false` cancels the step.
  var bool Function(C chart, UpdateHookArgs args, O options)?
  beforeDatasetsUpdate,

  /// `afterDatasetsUpdate` (U `core.controller.js:661`).
  /// It cannot cancel.
  var void Function(C chart, UpdateHookArgs args, O options)?
  afterDatasetsUpdate,

  /// `beforeDatasetUpdate` (U `core.controller.js:673`).
  /// Cancelable: `false` cancels the step.
  var bool Function(C chart, DatasetUpdateHookArgs args, O options)?
  beforeDatasetUpdate,

  /// `afterDatasetUpdate` (U `core.controller.js:680`).
  /// It cannot cancel.
  var void Function(C chart, DatasetUpdateHookArgs args, O options)?
  afterDatasetUpdate,

  /// `beforeLayout` (U `core.controller.js:612`).
  /// Cancelable: `false` cancels the step.
  var bool Function(C chart, PluginHookArgs args, O options)? beforeLayout,

  /// `beforeDataLimits` (U `core.scale.js:541`).
  /// It cannot cancel.
  var void Function(C chart, ScriptableScaleContext args, O options)?
  beforeDataLimits,

  /// `afterDataLimits` (U `core.scale.js:545`).
  /// It cannot cancel.
  var void Function(C chart, ScriptableScaleContext args, O options)?
  afterDataLimits,

  /// `beforeBuildTicks` (U `core.scale.js:550`).
  /// It cannot cancel.
  var void Function(C chart, ScriptableScaleContext args, O options)?
  beforeBuildTicks,

  /// `afterBuildTicks` (U `core.scale.js:559`).
  /// It cannot cancel.
  var void Function(C chart, ScriptableScaleContext args, O options)?
  afterBuildTicks,

  /// `afterLayout` (U `core.controller.js:640`).
  /// It cannot cancel.
  var void Function(C chart, PluginHookArgs args, O options)? afterLayout,

  /// `beforeRender` (U `core.controller.js:684`).
  /// Cancelable: `false` cancels the step.
  var bool Function(C chart, PluginHookArgs args, O options)? beforeRender,

  /// `afterRender` (U `core.controller.js:37`).
  /// It cannot cancel.
  var void Function(C chart, PluginHookArgs args, O options)? afterRender,

  /// `beforeDraw` (U `core.controller.js:712`).
  /// Cancelable: `false` cancels the step.
  var bool Function(C chart, PluginHookArgs args, O options)? beforeDraw,

  /// `afterDraw` (U `core.controller.js:731`).
  /// It cannot cancel.
  var void Function(C chart, PluginHookArgs args, O options)? afterDraw,

  /// `beforeDatasetsDraw` (U `core.controller.js:766`).
  /// Cancelable: `false` cancels the step.
  var bool Function(C chart, PluginHookArgs args, O options)?
  beforeDatasetsDraw,

  /// `afterDatasetsDraw` (U `core.controller.js:775`).
  /// It cannot cancel.
  var void Function(C chart, PluginHookArgs args, O options)? afterDatasetsDraw,

  /// `beforeDatasetDraw` (U `core.controller.js:793`).
  /// Cancelable: `false` cancels the step.
  var bool Function(C chart, DatasetDrawHookArgs args, O options)?
  beforeDatasetDraw,

  /// `afterDatasetDraw` (U `core.controller.js:808`).
  /// It cannot cancel.
  var void Function(C chart, DatasetDrawHookArgs args, O options)?
  afterDatasetDraw,

  /// `beforeEvent` (U `core.controller.js:1172`).
  /// Cancelable: `false` cancels the step.
  var bool Function(C chart, EventHookArgs args, O options)? beforeEvent,

  /// `afterEvent` (U `core.controller.js:1179`).
  /// It cannot cancel.
  var void Function(C chart, EventHookArgs args, O options)? afterEvent,

  /// `resize` (U `core.controller.js:292`).
  /// It cannot cancel.
  var void Function(C chart, ResizeHookArgs args, O options)? resize,

  /// `beforeDestroy` (U `core.controller.js:938`).
  /// It cannot cancel.
  var void Function(C chart, PluginHookArgs args, O options)? beforeDestroy,

  /// `afterDestroy` (U `core.controller.js:954`).
  /// It cannot cancel.
  var void Function(C chart, PluginHookArgs args, O options)? afterDestroy,

  /// `uninstall` (U `core.plugins.js:50`).
  /// It cannot cancel.
  var void Function(C chart, PluginHookArgs args, O options)? uninstall,

  /// `beforeTooltipDraw` (U `plugin.tooltip.js:1254`).
  /// Cancelable: `false` cancels the step.
  var bool Function(C chart, TooltipDrawHookArgs args, O options)?
  beforeTooltipDraw,

  /// `afterTooltipDraw` (U `plugin.tooltip.js:1260`).
  /// It cannot cancel.
  var void Function(C chart, TooltipDrawHookArgs args, O options)?
  afterTooltipDraw,
}) {
  /// A plugin with the given id, options and hooks.
  this {
    assert(
      options != null ||
          defaults is PluginOptions<Object?> ||
          <ContextResolver>[] is List<O>,
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

  /// Calls the hook [function] that cannot cancel. The chart is a [C]: the
  /// one checked cast of the chart.
  bool _call<A extends Object>(
    void Function(C chart, A args, O options)? function,
    types.Chart chart,
    A args,
    Object view,
  ) {
    function?.call(chart as C, args, _optionsOf(view));
    return true;
  }

  /// Calls the cancelable hook [function].
  bool _cancel<A extends Object>(
    bool Function(C chart, A args, O options)? function,
    types.Chart chart,
    A args,
    Object view,
  ) => function == null || function(chart as C, args, _optionsOf(view));

  @override
  String toString() => 'Plugin($id)';
}
