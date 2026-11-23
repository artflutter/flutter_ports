// Ported from Chart.js v4.6.1 src/plugins/plugin.title.js (MIT, Chart.js Contributors).

/// Port of `src/plugins/plugin.title.js`.
///
/// [Title] is the layout box of the chart title. [title] is the plugin
/// object, the default export of the upstream file and `Title` of
/// `src/plugins/index.js:6` (Chart.js ADR 0038, section 1). It is a typed
/// `Plugin` (Chart.js ADR 0054 §12) with the upstream keys in the upstream
/// order: `id`, `_element`, `start`, `stop`, `beforeUpdate` and `defaults`.
/// The `defaultRoutes` and the `descriptors` have no field (Chart.js ADR
/// 0197).
///
/// Each hook is a private function of the hook type `(types.Chart chart,
/// args, TitleOptions options)` (Chart.js ADR 0150, in place of the
/// upstream parameter counts of Chart.js ADR 0038, section 3): the argument
/// class of its hook, and the merged [TitleOptions] of `plugin_options.dart`
/// (Chart.js ADR 0197). The box keeps a [TitleBoxOptions]: the options of
/// the title or of the subtitle.
/// `chart.titleBlock` is a field of `types.Chart`: Dart `null` stands for JS
/// `undefined` and for the `delete` of `plugin.title.js:136`.
///
/// The fields of the box start as the fields of `Scale` start: NaN for the
/// edges, the `undefined` sentinel for `position` and `weight`, and `false`
/// for `fullSize` (Chart.js ADR 0038, section 7).
///
/// Not a pure layer: it imports `helpers.extras`.
library;

import 'dart:ui';

import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_chartjs_port/chartjs.dart';

/// plugin.title.js:7 `class Title extends Element`.
///
/// The layout box of the chart title. `layouts.addBox` gives it the default
/// layer, which calls [draw] (core.layouts.js:301-308).
class Title(
  ({
    Object? chart,
    TitleBoxOptions<Object?>? options,
    CanvasRenderingContext2D? ctx,
  })
  config,
) extends Element implements LayoutItem {
  /// plugin.title.js:11 `constructor(config)`.
  ///
  /// @param {{ ctx: any; options: any; chart: any; }} config
  ///
  /// The upstream `config` object is a record (Chart.js ADR 0038, section
  /// 4). The `construct` closure of [jsClass] reads it from a JS value.
  this {
    options = config.options;
  }

  /// plugin.title.js:15 `options`, the [TitleBoxOptions] of the box: the
  /// merged options of the plugin, with the fallbacks of upstream after the
  /// `beforeUpdate` hook (Chart.js ADR 0197). Dart `null` stands for JS
  /// `undefined`: a read of an option then throws the [TypeError] of the
  /// null check, as the read of a member of `undefined` throws upstream.
  // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
  @override
  TitleBoxOptions<Object?>? get options =>
      super.options as TitleBoxOptions<Object?>?;

  @override
  set options(covariant TitleBoxOptions<Object?>? value) =>
      super.options = value;

  /// plugin.title.js:7 `class Title` as a value (Chart.js ADR 0020, section
  /// 3).
  ///
  /// Its superclass is [Element.jsClass]. It has no static property. Its
  /// `construct` reads the `config` argument with [_titleConfig].
  static final JsClass jsClass = JsClass(
    'Title',
    superclass: Element.jsClass,
    construct: (newTarget, args) => Title(_titleConfig(args)),
  );

  /// plugin.title.js:14 `chart`. Upstream stores it and never reads it.
  /// Thus it keeps any value.
  final Object? chart = config.chart;

  /// plugin.title.js:16 `ctx`. Dart `null` stands for JS `undefined`.
  CanvasRenderingContext2D? ctx = config.ctx;

  /// plugin.title.js:17 `_padding`, the native padding of the last
  /// [update] that displays the title. Dart `null` stands for JS
  /// `undefined`, the start value. [draw] reads it.
  ///
  /// A `late` field would throw a `LateInitializationError` at the read
  /// before the first write. Upstream throws a `TypeError` there, as the
  /// null check of Dart `null` does.
  // ignore: use_late_for_private_fields_and_variables
  EdgeInsets? _padding;

  /// plugin.title.js:18 `top`. NaN stands for JS `undefined`, the start
  /// value.
  @override
  double top = double.nan;

  /// plugin.title.js:19 `bottom`. NaN stands for JS `undefined`.
  @override
  double bottom = double.nan;

  /// plugin.title.js:20 `left`. NaN stands for JS `undefined`.
  @override
  double left = double.nan;

  /// plugin.title.js:21 `right`. NaN stands for JS `undefined`.
  @override
  double right = double.nan;

  /// plugin.title.js:22 `width`. NaN stands for JS `undefined`.
  @override
  double width = double.nan;

  /// plugin.title.js:23 `height`. NaN stands for JS `undefined`.
  @override
  double height = double.nan;

  /// plugin.title.js:24 `position`. Dart `null` stands for JS
  /// `undefined`, the start value. `layouts.configure` writes the
  /// `position` option (core.layouts.js:333).
  @override
  LayoutPosition? position;

  /// plugin.title.js:25 `weight`. Dart `null` stands for JS
  /// `undefined`, the start value. `layouts.configure` writes the `weight`
  /// option (core.layouts.js:334).
  @override
  double? weight;

  /// plugin.title.js:26 `fullSize`. False stands for JS `undefined`, the
  /// start value: the readers test only its truthiness (Chart.js ADR 0038,
  /// section 7).
  @override
  bool fullSize = false;

  /// core.layouts.js:301 `_layers`. Dart `null` stands for JS `undefined`,
  /// the start value: `layouts.addBox` writes the default layer.
  @override
  List<LayoutLayer> Function()? layers;

  /// core.layouts.js:15 `box.axis`. The title has no axis: Dart `null`
  /// stands for JS `undefined`.
  @override
  ScaleAxis? get axis => null;

  /// plugin.title.js:29 `update(maxWidth, maxHeight)`.
  ///
  /// Upstream has no third parameter. `core.layouts.js:187-191` passes the
  /// margins, and the title ignores them (Chart.js ADR 0038, section 7).
  @override
  void update(double maxWidth, double maxHeight, [TRBL? margins]) {
    final opts = options!;

    left = 0;
    top = 0;

    if (opts.display != true) {
      width = height = right = bottom = 0;
      return;
    }

    width = right = maxWidth;
    height = bottom = maxHeight;

    // The lines of `opts.text` (Chart.js ADR 0150): `isArray(text) ?
    // text.length : 1`.
    final lineCount = (opts.text ?? const <String>[]).length;
    final padding = _padding = opts.padding ?? EdgeInsets.zero;
    final lineHeight = toFont(opts.font).lineHeight!;
    final textSize = lineCount * lineHeight + padding.vertical;

    if (isHorizontal()) {
      height = textSize;
    } else {
      width = textSize;
    }
  }

  /// plugin.title.js:54 `isHorizontal()`.
  @override
  bool isHorizontal() {
    final pos = options!.position;
    return pos == ChartPosition.top || pos == ChartPosition.bottom;
  }

  /// plugin.title.js:59 `_drawArgs(offset)`: the object `{titleX, titleY,
  /// maxWidth, rotation}`, a record.
  ///
  /// `_alignStartEnd` takes the `align` option, a [ChartAlign].
  ({double titleX, double titleY, double maxWidth, double rotation}) _drawArgs(
    double offset,
  ) {
    final Title(:top, :left, :bottom, :right) = this;
    final options = this.options!;
    // DIVERGES(chartjs): adapt-chart-align-enum, the enum value.
    final alignName = options.align;
    var rotation = 0.0;
    double maxWidth;
    double titleX;
    double titleY;

    if (isHorizontal()) {
      titleX = alignStartEnd(alignName, left, right);
      titleY = top + offset;
      maxWidth = right - left;
    } else {
      if (options.position == ChartPosition.left) {
        titleX = left + offset;
        titleY = alignStartEnd(alignName, bottom, top);
        rotation = pi * -0.5;
      } else {
        titleX = right - offset;
        titleY = alignStartEnd(alignName, top, bottom);
        rotation = pi * 0.5;
      }
      maxWidth = bottom - top;
    }
    return (
      titleX: titleX,
      titleY: titleY,
      maxWidth: maxWidth,
      rotation: rotation,
    );
  }

  /// plugin.title.js:84 `draw()`.
  ///
  /// Upstream takes no argument. The default layer of `layouts.addBox`
  /// passes the chart area (core.layouts.js:305), and the title ignores it
  /// (Chart.js ADR 0038, section 7).
  ///
  /// Before the first [update] that displays the title, `_padding` is Dart
  /// `null`, and the read of its `top` throws a [TypeError], as the read of
  /// `this._padding.top` throws upstream. A title without a context throws
  /// the [TypeError] of `ctx.save()` in `renderText` after the reads of the
  /// options, as upstream.
  @override
  void draw([ChartArea? chartArea]) {
    final ctx = this.ctx;
    final opts = options!;

    if (opts.display != true) {
      return;
    }

    final fontOpts = toFont(opts.font);
    final lineHeight = fontOpts.lineHeight!;
    final offset = lineHeight / 2 + _padding!.top;
    final (:titleX, :titleY, :maxWidth, :rotation) = _drawArgs(offset);

    // The arguments of renderText, in the upstream order of their reads.
    final text = opts.text ?? const <String>[];
    final textOpts = RenderTextOpts(
      color: opts.color ?? const ChartPaint.unchanged(),
      maxWidth: maxWidth,
      rotation: rotation,
      textAlign: toLeftRightCenter(opts.align),
      // DIVERGES(chartjs): adapt-canvas-text-baseline-enum, the enum value.
      textBaseline: CanvasTextBaseline.middle,
      translation: (titleX, titleY),
    );
    renderText(ctx!, text, 0, 0, fontOpts, textOpts);
  }
}

/// The `config` of `new Title(config)` from the arguments [args] of the
/// `construct` closure of [Title.jsClass]: the reads `config.chart`,
/// `config.options` and `config.ctx` of plugin.title.js:14-16.
///
/// An absent argument, [undefined] and JS `null` throw the [TypeError] of
/// the read `config.chart`, as upstream. A member with the value
/// [undefined] gives Dart `null`. The `chart` keeps any value, because
/// `Title` never reads it. An `options` that is not a [TitleBoxOptions]
/// (Chart.js ADR 0197) and a `ctx` that is not a context throw a
/// [TypeError]. Upstream stores such a value.
// DIVERGES(chartjs): adapt-component-class-role, other options throw.
({
  Object? chart,
  TitleBoxOptions<Object?>? options,
  CanvasRenderingContext2D? ctx,
})
_titleConfig(List<Object?> args) {
  final config = args.isEmpty ? undefined : args[0];
  return (
    chart: _orNull(jsGet(config, 'chart')),
    options: _orNull(jsGet(config, 'options')) as TitleBoxOptions<Object?>?,
    ctx: _orNull(jsGet(config, 'ctx')) as CanvasRenderingContext2D?,
  );
}

/// Dart `null` for the [undefined] sentinel, else [value].
Object? _orNull(Object? value) => identical(value, undefined) ? null : value;

/// plugin.title.js:108 `createTitle(chart, titleOpts)`.
void _createTitle(IChart chart, TitleOptions titleOpts) {
  final title = Title((ctx: chart.ctx, options: titleOpts, chart: chart));

  layouts
    ..configure(chart, title, titleOpts)
    ..addBox(chart, title);
  chart.titleBlock = title;
}

/// plugin.title.js:129 `start(chart, _args, options)`. The box keeps the
/// merged options until `beforeUpdate` of the same update gives it the
/// options with their fallbacks: the layout reads only `display`,
/// `fullSize`, `position` and `weight` between the two hooks.
void _start(IChart chart, PluginHookArgs _, TitleOptions options) {
  _createTitle(chart, options);
}

/// plugin.title.js:133 `stop(chart)`. Dart `null` stands for the
/// `undefined` of a chart without a title block: `removeBox` then changes
/// nothing (core.layouts.js:318-323). `delete chart.titleBlock` is the write
/// of Dart `null`.
void _stop(IChart chart, PluginHookArgs _, TitleOptions _) {
  final titleBlock = chart.titleBlock;
  layouts.removeBox(chart, titleBlock);
  chart.titleBlock = null;
}

/// plugin.title.js:139 `beforeUpdate(chart, _args, options)`. Without a
/// title block, the null check throws the TypeError of the write into
/// `undefined` in `layouts.configure` (core.layouts.js:332).
///
/// The box gets the options with the fallbacks of upstream
/// ([resolvedTitleOptions], Chart.js ADR 0197), so `scripted` runs once for
/// each update.
bool _beforeUpdate(IChart chart, UpdateHookArgs _, TitleOptions options) {
  final title = chart.titleBlock! as Title;
  final resolved = resolvedTitleOptions(
    chart,
    options,
    (color) => TitleOptions(color: color),
  );
  layouts.configure(chart, title, resolved);
  title.options = resolved;
  return true;
}

/// The `color` of `Chart.defaults` as a paint, or Dart `null` for a value
/// that is no color: the `defaultRoutes` `{color: 'color'}` of
/// plugin.title.js:158-160 and plugin.subtitle.js:45-47, a route to
/// `defaults.color`.
// DIVERGES(chartjs): adapt-native-plugin-options, the route in Dart.
ChartPaint? _defaultColor() => switch (optionOf(defaults, OptionKey.color)) {
  final ChartPaint paint => paint,
  final Color color => ChartPaint.solid(color),
  _ => null,
};

/// The options [source] of the hooks of the title or the subtitle plugin
/// with the fallbacks of upstream (Chart.js ADR 0197), and the result of
/// [TitleBoxOptions.scripted] merged over them:
///
/// - A `color` that [source] does not set is the `color` of
///   `Chart.defaults`, the route of plugin.title.js:158-160.
/// - [TitleBoxOptions.scripted] gets the chart context and these options,
///   once for each update, where upstream calls each scriptable option at
///   its first read in the update. Its result merges over [source], and a
///   color that it does not set falls back again.
///
/// The font stays as the options give it: the box merges it over
/// `Chart.defaults.font` with `toFont` at each read, as upstream.
/// [withColorOnly] makes the options of the class of [source] with only a
/// color.
// DIVERGES(chartjs): adapt-title-scripted, one function for the options.
T resolvedTitleOptions<T extends TitleBoxOptions<T>>(
  IChart chart,
  T source,
  T Function(ChartPaint? color) withColorOnly,
) {
  T withColor(T options) => options.color != null
      ? options
      : options.merge(withColorOnly(_defaultColor()));
  final base = withColor(source);
  final script = source.scripted;
  if (script == null) return base;
  final scripted = script(chart.getContext(), base);
  return scripted == null ? base : withColor(source.merge(scripted));
}

/// plugin.title.js:120 the default export, `Title` of
/// `src/plugins/index.js:6` (Chart.js ADR 0038, section 1).
///
/// A native [Plugin] (Chart.js ADR 0144) with the upstream keys in the
/// upstream order. Each hook is a private function of the hook type
/// `(chart, args, options)` with the argument class of its hook and the
/// merged [TitleOptions] (Chart.js ADR 0197). The key `_element: Title` of
/// plugin.title.js:127 is for the tests: they read `Title.jsClass`.
// DIVERGES(chartjs): adapt-typed-plugins, no key `_element`.
final title = TitlePlugin();

/// The title plugin: a class of its own, so `registry.getPlugin<TitlePlugin>()`
/// finds it by its type.
// DIVERGES(chartjs): adapt-typed-plugins, a class for each plugin.
final class TitlePlugin() extends Plugin<TitleOptions> {
  /// The title plugin.
  this
    : super(
        id: 'title',
        // The hooks get the merged TitleOptions (Chart.js ADR 0197).
        start: _start,
        stop: _stop,
        beforeUpdate: _beforeUpdate,
        // plugin.title.js:145-156: one TitleOptions with each default
        // (Chart.js ADR 0197). The route of the `color` (:158-160) and the
        // descriptors (:162-165) have no field: the plugin gives the `color` of
        // `Chart.defaults` where no options set one, and the one function
        // `scripted` takes the place of the scriptable options
        // ([resolvedTitleOptions]).
        // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
        defaults: const TitleOptions(
          // DIVERGES(chartjs): adapt-chart-align-enum, the enum value.
          align: ChartAlign.center,
          display: false,
          // DIVERGES(chartjs): adapt-text-style-fonts, the font is a
          // ChartTextStyle.
          font: ChartTextStyle(fontWeight: FontWeight.bold),
          fullSize: true,
          padding: EdgeInsets.all(10),
          position: ChartPosition.top,
          // DIVERGES(chartjs): adapt-title-text-lines, the lines of `''`.
          text: [''],
          // by default greater than legend (1000) to be above
          weight: 2000,
        ),
        // DIVERGES(chartjs): adapt-incremental-data-update, partial-lifecycle
        // opt-in.
        supportsDataUpdates: true,
      );
}
