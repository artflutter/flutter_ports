// Original code, not ported from Chart.js: the resolved plugin option classes.

/// The resolved option classes of the seven built-in plugins (Chart.js ADR
/// 0182).
///
/// The options of a plugin hook are a context resolver of
/// `core.plugins.js:175-188` (an `OptionView`). Each class is an immutable
/// final class with one typed field for each key, `==` and `hashCode`. Its
/// static method `of` reads each key of the resolved options once, at the
/// first hook of an update, and applies the conversion of the key in the
/// schema (`jsToNumber`, `toFont`, `canvasTextAlign`, ...). A scriptable
/// option gives its value at that read. Each hook of the update gets the
/// same object. A field that still holds the raw value says why.
///
/// The tooltip is the exception (Chart.js ADR 0192): [TooltipOptions] is one
/// immutable `PluginOptions` object with a nullable field for each option,
/// which the plugin service merges from the defaults to the chart, and the
/// tooltip resolves the fallbacks of upstream itself.
///
/// A class takes the name of its `index.d.ts` interface (`LegendOptions`,
/// `TitleOptions`, `TooltipOptions`, `FillerOptions`, `DecimationOptions`)
/// or a port-only name for an inline type of `index.d.ts`
/// (`LegendLabelOptions`, `LegendTitleOptions`, `ColorsPluginOptions` of
/// `plugin.colors.ts:4`). The app library exports them: they are the `O` of
/// the hooks of the built-in plugins.
///
/// This library is a pure layer.
library;

import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/chartjs_core.dart';
import 'package:meta/meta.dart' show immutable;

/// The option [key] of the options object [options]: `options[key]`, the
/// shared typed read [readOption] of `helpers.config.dart`.
///
/// A resolver gives its typed read `readKey`, which gives the result of the
/// read by name of the same key and keeps the same cache. The typed element
/// options give their `valueOf`. Any other object (a plain Map of a spec, a
/// typed scope) gives the read by name: the raw boundary of Chart.js ADR
/// 0054 §5. `null` and `undefined` throw the [TypeError] of the property
/// read, as upstream.
@pragma('vm:prefer-inline')
@pragma('dart2js:prefer-inline')
@pragma('wasm:prefer-inline')
Object? optionOf(Object? options, OptionKey key) => readOption(options, key);

/// The number of the option value [value] for a test `value ? value : x`
/// of upstream: the `ToNumber` of a truthy value, else Dart `null`.
double? _truthyNumber(Object? value) =>
    jsTruthy(value) ? jsToNumber(value) : null;

/// The number of the option value [value] for a destructuring default of
/// upstream: Dart `null` for [undefined], else its `ToNumber`.
double? _definedNumber(Object? value) =>
    identical(value, undefined) ? null : jsToNumber(value);

/// The lines of the text option [value], as `renderText` draws them
/// (`helpers.canvas.ts:457`): each item of a List, else the value itself,
/// as a `ToString`.
// DIVERGES(chartjs): adapt-title-text-lines, the lines of the text.
List<String> _textLines(Object? value) {
  if (value is List<String>) return value;
  assert(
    value == null || value is Undefined,
    'A title text takes a List<String> of its lines, not $value.',
  );
  return const <String>[];
}

/// The corners of a truthy corner option [value] ([toTRBLCorners]), else
/// Dart `null`: the test `borderRadius || ...` of upstream.
BorderRadius? _truthyCorners(Object? value) =>
    jsTruthy(value) ? toTRBLCorners(value) : null;

/// The [LayoutPosition] of a `position` option value, or Dart `null` for a
/// value that is not one. A keyword of Chart.js stops a debug build.
LayoutPosition? _layoutPosition(Object? value) {
  assert(
    value is! String,
    'A position takes a LayoutPosition, not the name "$value".',
  );
  return value is LayoutPosition ? value : null;
}

/// `TitleOptions` (`index.d.ts`): the resolved options of the title and the
/// subtitle plugins (`plugin.title.js:145-156`, `plugin.subtitle.js:32-43`).
///
/// The plugin makes one object from the resolved options of each update
/// ([TitleOptions.of]). A scriptable option gives its value at that read.
/// The layout reads `fullSize`, `position` and `weight` through
/// [layoutOption].
///
/// ```dart
/// final options = TitleOptions.of({'display': true, 'text': ['Sales']});
/// print(options.text); // [Sales]
/// ```
// DIVERGES(chartjs): adapt-native-plugin-options, resolved values.
@immutable
final class const TitleOptions({
  /// `align`, a [ChartAlign] (row `adapt-chart-align-enum`).
  required final ChartAlign? align,

  /// `color`: the paint of the option value, or [ChartPaint.unchanged]
  /// without one.
  required final ChartPaint color,

  /// `display`.
  required final bool display,

  /// `font`: the [toFont] of the option value.
  required final ChartTextStyle font,

  /// `fullSize`: the truthiness of the option value.
  required final bool fullSize,

  /// `padding`.
  required final EdgeInsets padding,

  /// `position`, a [ChartPosition] (row `adapt-chart-position-enum`).
  required final ChartPosition? position,

  /// `text`: its lines.
  required final List<String> text,

  /// `weight`: a number, or Dart `null` for no number.
  required final num? weight,
}) implements LayoutBoxOptions {
  /// The options with the given values.
  this;

  /// The options of the resolved options [options]: one read of each key, in
  /// the order of the keys of `index.d.ts`.
  // A static method: a factory makes the lint ask for const Map literals of
  // the resolved options.
  // ignore: prefer_constructors_over_static_methods
  static TitleOptions of(Object? options) {
    if (options is TitleOptions) return options;
    final weight = optionOf(options, OptionKey.weight);
    return TitleOptions(
      align: ChartAlign.of(optionOf(options, OptionKey.align)),
      color: chartPaintOf(optionOf(options, OptionKey.color)),
      display: boolOption(
        optionOf(options, OptionKey.display),
        OptionKey.display,
      ),
      font: toFont(optionOf(options, OptionKey.font)),
      fullSize: jsTruthy(optionOf(options, OptionKey.fullSize)),
      padding: paddingOption(optionOf(options, OptionKey.padding)),
      position: ChartPosition.of(optionOf(options, OptionKey.position)),
      text: _textLines(optionOf(options, OptionKey.text)),
      weight: weight is num ? weight : null,
    );
  }

  @override
  Object? layoutOption(OptionKey key) => switch (key) {
    OptionKey.display => display,
    OptionKey.fullSize => fullSize,
    OptionKey.position => position ?? undefined,
    OptionKey.weight => weight ?? undefined,
    _ => undefined,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TitleOptions &&
          other.align == align &&
          other.color == color &&
          other.display == display &&
          other.font == font &&
          other.fullSize == fullSize &&
          other.padding == padding &&
          other.position == position &&
          _listEquals(other.text, text) &&
          other.weight == weight;

  @override
  int get hashCode => Object.hash(
    align,
    color,
    display,
    font,
    fullSize,
    padding,
    position,
    Object.hashAll(text),
    weight,
  );

  @override
  String toString() =>
      'TitleOptions(display: $display, text: $text, position: $position)';
}

/// Whether the Lists [a] and [b] have equal items in the same order.
bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// `LegendOptions` (`index.d.ts`): the resolved options of the legend plugin
/// (`plugin.legend.js:636-712`).
///
/// The plugin makes one object from the resolved options of each update
/// ([LegendOptions.of]). A scriptable option gives its value at that read.
/// The layout reads `display`, `fullSize`, `position` and `weight` through
/// [layoutOption].
///
/// ```dart
/// final options = LegendOptions.of({'display': false});
/// print(options.display); // false
/// ```
// DIVERGES(chartjs): adapt-native-plugin-options, resolved values.
@immutable
final class const LegendOptions({
  /// `align`, a [ChartAlign] (row `adapt-chart-align-enum`).
  required final ChartAlign? align,

  /// `display`.
  required final bool display,

  /// `fullSize`: the truthiness of the option value.
  required final bool fullSize,

  /// `labels`. A falsy option value gives the label options of `{}`
  /// (`plugin.legend.js:105`).
  required final LegendLabelOptions labels,

  /// `maxHeight`: the number of a truthy value, else Dart `null`
  /// (`plugin.legend.js:154`).
  required final double? maxHeight,

  /// `maxWidth`: the number of a truthy value, else Dart `null`
  /// (`plugin.legend.js:153`).
  required final double? maxWidth,

  /// `onClick`: the function, or Dart `null` for no function (Chart.js ADR
  /// 0130).
  required final LegendEventHandler? onClick,

  /// `onHover`: the function, or Dart `null` for no function (Chart.js ADR
  /// 0130).
  required final LegendEventHandler? onHover,

  /// `onLeave`: the function, or Dart `null` for no function (Chart.js ADR
  /// 0130).
  required final LegendEventHandler? onLeave,

  /// `position`, a [LayoutPosition] (row `adapt-chart-position-enum`).
  required final LayoutPosition? position,

  /// `reverse`.
  required final bool reverse,

  /// `rtl`.
  required final bool rtl,

  /// `textDirection`.
  required final TextDirection? textDirection,

  /// `title`. A falsy option value gives the title options of `{}`.
  required final LegendTitleOptions title,

  /// `weight`: a number, or Dart `null` for no number.
  required final num? weight,

  /// The resolved options that gave these values, or Dart `null` for options
  /// that a program makes. The legend reads its proofs for a hidden legend
  /// from them (row `adapt-hidden-legend-items`). It is not a part of `==`.
  final Object? view,
}) implements LayoutBoxOptions {
  /// The options with the given values.
  this;

  /// The options of the resolved options [options]: one read of each key.
  /// A [LegendOptions] stays itself.
  // ignore: prefer_constructors_over_static_methods
  static LegendOptions of(Object? options) {
    if (options is LegendOptions) return options;
    final labels = optionOf(options, OptionKey.labels);
    final title = optionOf(options, OptionKey.title);
    final weight = optionOf(options, OptionKey.weight);
    return LegendOptions(
      align: ChartAlign.of(optionOf(options, OptionKey.align)),
      display: boolOption(
        optionOf(options, OptionKey.display),
        OptionKey.display,
      ),
      fullSize: jsTruthy(optionOf(options, OptionKey.fullSize)),
      labels: LegendLabelOptions.of(
        jsTruthy(labels) ? labels : <String, Object?>{},
      ),
      maxHeight: _truthyNumber(optionOf(options, OptionKey.maxHeight)),
      maxWidth: _truthyNumber(optionOf(options, OptionKey.maxWidth)),
      onClick: functionOption<LegendEventHandler>(
        optionOf(options, OptionKey.onClick),
        OptionKey.onClick,
      ),
      onHover: functionOption<LegendEventHandler>(
        optionOf(options, OptionKey.onHover),
        OptionKey.onHover,
      ),
      onLeave: functionOption<LegendEventHandler>(
        optionOf(options, OptionKey.onLeave),
        OptionKey.onLeave,
      ),
      position: _layoutPosition(optionOf(options, OptionKey.position)),
      reverse: boolOption(
        optionOf(options, OptionKey.reverse),
        OptionKey.reverse,
      ),
      rtl: boolOption(optionOf(options, OptionKey.rtl), OptionKey.rtl),
      textDirection: textDirectionOption(
        optionOf(options, OptionKey.textDirection),
      ),
      title: LegendTitleOptions.of(
        jsTruthy(title) ? title : <String, Object?>{},
      ),
      weight: weight is num ? weight : null,
      view: options,
    );
  }

  @override
  Object? layoutOption(OptionKey key) => switch (key) {
    OptionKey.display => display,
    OptionKey.fullSize => fullSize,
    OptionKey.position => position ?? undefined,
    OptionKey.weight => weight ?? undefined,
    _ => undefined,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegendOptions &&
          other.align == align &&
          other.display == display &&
          other.fullSize == fullSize &&
          other.labels == labels &&
          other.maxHeight == maxHeight &&
          other.maxWidth == maxWidth &&
          other.onClick == onClick &&
          other.onHover == onHover &&
          other.onLeave == onLeave &&
          other.position == position &&
          other.reverse == reverse &&
          other.rtl == rtl &&
          other.textDirection == textDirection &&
          other.title == title &&
          other.weight == weight;

  @override
  int get hashCode => Object.hash(
    align,
    display,
    fullSize,
    labels,
    maxHeight,
    maxWidth,
    onClick,
    onHover,
    onLeave,
    position,
    reverse,
    rtl,
    textDirection,
    title,
    weight,
  );

  @override
  String toString() =>
      'LegendOptions(display: $display, position: $position, '
      'labels: $labels)';
}

/// The `labels` of `LegendOptions` (`index.d.ts`, an inline type): the
/// resolved label options of the legend (`plugin.legend.js:664-705`).
///
/// ```dart
/// final labels = LegendLabelOptions.of({'usePointStyle': true});
/// print(labels.usePointStyle); // true
/// ```
// DIVERGES(chartjs): adapt-native-plugin-options, resolved values.
@immutable
final class const LegendLabelOptions({
  /// `borderRadius`: the corners of a truthy number or of the Flutter
  /// [BorderRadius] of the option ([toTRBLCorners]), else Dart `null`
  /// (`plugin.legend.js:692`, row `adapt-flutter-border-radius`).
  required final BorderRadius? borderRadius,

  /// `boxHeight`: Dart `null` for an absent value, else its number
  /// (`plugin.legend.js:25`, row `adapt-legend-number-options`).
  required final double? boxHeight,

  /// `boxWidth`: Dart `null` for an absent value, else its number
  /// (`plugin.legend.js:25`, row `adapt-legend-number-options`).
  required final double? boxWidth,

  /// `color`: a [ChartPaint] or a Flutter `Color`, which the legend item and
  /// the canvas take.
  required final Object? color,

  /// `filter`: the function, or Dart `null` for no function (Chart.js ADR
  /// 0130).
  required final LegendItemFilter? filter,

  /// `font`: the [toFont] of the option value.
  required final ChartTextStyle font,

  /// `generateLabels`, the option value: `plugin.legend.dart` reads it as a
  /// `LegendLabelsGenerator`, a function of the `Chart` class, which this
  /// core layer does not import.
  required final Object? generateLabels,

  /// `padding`: its number (row `adapt-legend-number-options`).
  required final double padding,

  /// `pointStyle`: a `PointStyle` or a boolean, which the legend item keeps.
  required final Object? pointStyle,

  /// `pointStyleWidth`: the number of a truthy value, else Dart `null`
  /// (`plugin.legend.js:29`, `:336`).
  required final double? pointStyleWidth,

  /// `sort`: the function, or Dart `null` for no function (Chart.js ADR
  /// 0130).
  required final LegendItemComparator? sort,

  /// `textAlign`, a Flutter [TextAlign] (row `adapt-flutter-text-align`).
  required final TextAlign? textAlign,

  /// `useBorderRadius`.
  required final bool useBorderRadius,

  /// `usePointStyle`.
  required final bool usePointStyle,
}) {
  /// The options with the given values.
  this;

  /// The label options of the resolved options [options]: one read of each
  /// key.
  // ignore: prefer_constructors_over_static_methods
  static LegendLabelOptions of(Object? options) => LegendLabelOptions(
    borderRadius: _truthyCorners(optionOf(options, OptionKey.borderRadius)),
    boxHeight: _definedNumber(optionOf(options, OptionKey.boxHeight)),
    boxWidth: _definedNumber(optionOf(options, OptionKey.boxWidth)),
    color: optionOf(options, OptionKey.color),
    filter: functionOption<LegendItemFilter>(
      optionOf(options, OptionKey.filter),
      OptionKey.filter,
    ),
    font: toFont(optionOf(options, OptionKey.font)),
    generateLabels: optionOf(options, OptionKey.generateLabels),
    padding: jsToNumber(optionOf(options, OptionKey.padding)),
    pointStyle: optionOf(options, OptionKey.pointStyle),
    pointStyleWidth: _truthyNumber(
      optionOf(options, OptionKey.pointStyleWidth),
    ),
    sort: functionOption<LegendItemComparator>(
      optionOf(options, OptionKey.sort),
      OptionKey.sort,
    ),
    textAlign: canvasTextAlign(optionOf(options, OptionKey.textAlign)),
    useBorderRadius: boolOption(
      optionOf(options, OptionKey.useBorderRadius),
      OptionKey.useBorderRadius,
    ),
    usePointStyle: boolOption(
      optionOf(options, OptionKey.usePointStyle),
      OptionKey.usePointStyle,
    ),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegendLabelOptions &&
          other.borderRadius == borderRadius &&
          other.boxHeight == boxHeight &&
          other.boxWidth == boxWidth &&
          other.color == color &&
          other.filter == filter &&
          other.font == font &&
          other.generateLabels == generateLabels &&
          other.padding == padding &&
          other.pointStyle == pointStyle &&
          other.pointStyleWidth == pointStyleWidth &&
          other.sort == sort &&
          other.textAlign == textAlign &&
          other.useBorderRadius == useBorderRadius &&
          other.usePointStyle == usePointStyle;

  @override
  int get hashCode => Object.hash(
    borderRadius,
    boxHeight,
    boxWidth,
    color,
    filter,
    font,
    generateLabels,
    padding,
    pointStyle,
    pointStyleWidth,
    sort,
    textAlign,
    useBorderRadius,
    usePointStyle,
  );

  @override
  String toString() =>
      'LegendLabelOptions(usePointStyle: $usePointStyle, padding: $padding)';
}

/// The `title` of `LegendOptions` (`index.d.ts`, an inline type): the
/// resolved title options of the legend (`plugin.legend.js:706-711`).
///
/// ```dart
/// final title = LegendTitleOptions.of({'display': true, 'text': ['Series']});
/// print(title.text); // [Series]
/// ```
// DIVERGES(chartjs): adapt-native-plugin-options, resolved values.
@immutable
final class const LegendTitleOptions({
  /// `color`: a [ChartPaint] or a Flutter `Color`, which the canvas takes.
  required final Object? color,

  /// `display`.
  required final bool display,

  /// `font`: the [toFont] of the option value.
  required final ChartTextStyle font,

  /// `padding`.
  required final EdgeInsets padding,

  /// `position`, a [ChartAlign] (row `adapt-chart-align-enum`).
  required final ChartAlign? position,

  /// `text`: its lines.
  required final List<String> text,
}) {
  /// The options with the given values.
  this;

  /// The title options of the resolved options [options]: one read of each
  /// key.
  // ignore: prefer_constructors_over_static_methods
  static LegendTitleOptions of(Object? options) => LegendTitleOptions(
    color: optionOf(options, OptionKey.color),
    display: boolOption(
      optionOf(options, OptionKey.display),
      OptionKey.display,
    ),
    font: toFont(optionOf(options, OptionKey.font)),
    padding: paddingOption(optionOf(options, OptionKey.padding)),
    position: ChartAlign.of(optionOf(options, OptionKey.position)),
    text: _textLines(optionOf(options, OptionKey.text)),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegendTitleOptions &&
          other.color == color &&
          other.display == display &&
          other.font == font &&
          other.padding == padding &&
          other.position == position &&
          _listEquals(other.text, text);

  @override
  int get hashCode => Object.hash(
    color,
    display,
    font,
    padding,
    position,
    Object.hashAll(text),
  );

  @override
  String toString() => 'LegendTitleOptions(display: $display, text: $text)';
}

/// `TooltipOptions` (`index.d.ts:2795`): the options of the tooltip plugin
/// (`plugin.tooltip.js:1275-1325`), one immutable object with one nullable
/// field for each option (Chart.js ADR 0192). A null field is not set.
///
/// An app gives the options in `ChartConfig.pluginOptions`, or in
/// `options.plugins.tooltip` of a raw config. A Map there stops a debug
/// build. The plugin service merges the options of the defaults, the theme
/// and the chart from the defaults to the chart ([merge]), as for the
/// options of an add-on (Chart.js ADR 0148): no resolver runs. The tooltip
/// then fills [mode], [intersect], [axis] and [includeInvisible] from
/// `options.interaction` (the `additionalOptionScopes` of upstream), merges
/// the three fonts over `Chart.defaults.font` (the `defaultRoutes` of
/// upstream), gives [boxWidth] and [boxHeight] the size of [bodyFont], and
/// merges the result of [scripted] at each read with its context.
///
/// ```dart
/// ChartConfig(
///   datasets: [LineDataset(data: .values([3, 5, 2]))],
///   pluginOptions: const [
///     TooltipOptions(mode: IndexInteractionMode(), intersect: false),
///   ],
/// );
/// ```
// DIVERGES(chartjs): adapt-native-plugin-options, one options object.
@immutable
final class const TooltipOptions({
  /// `enabled`: whether the chart draws the tooltip. The default is `true`.
  /// With `false`, an [external] function still gets each change.
  final bool? enabled,

  /// `external`: the function that shows the tooltip of the app. The tooltip
  /// calls it after an update that changed its state.
  final TooltipExternal? external,

  /// `position`: the object that finds the position of the tooltip (row
  /// `adapt-tooltip-positioner-objects`). The default is
  /// `AverageTooltipPositioner()`.
  final TooltipPositioner? position,

  /// `backgroundColor`: the paint of the box.
  final ChartPaint? backgroundColor,

  /// `titleColor`: the paint of the title text.
  final ChartPaint? titleColor,

  /// `titleFont`: the font of the title. The tooltip merges it over
  /// `Chart.defaults.font` ([toFont], the route of
  /// plugin.tooltip.js:1327-1331). The color of the font is not read: set
  /// [titleColor].
  final TextStyle? titleFont,

  /// `titleSpacing`: the space between two title lines, in pixels.
  final double? titleSpacing,

  /// `titleMarginBottom`: the space below the title, in pixels.
  final double? titleMarginBottom,

  /// `titleAlign`: the horizontal align of the title lines (row
  /// `adapt-flutter-text-align`).
  final TextAlign? titleAlign,

  /// `bodyColor`: the paint of the label text.
  final ChartPaint? bodyColor,

  /// `bodySpacing`: the space between two label items, in pixels.
  final double? bodySpacing,

  /// `bodyFont`: the font of the label lines, merged over `Chart.defaults.font`
  /// as [titleFont].
  final TextStyle? bodyFont,

  /// `bodyAlign`: the horizontal align of the label lines.
  final TextAlign? bodyAlign,

  /// `footerColor`: the paint of the footer text.
  final ChartPaint? footerColor,

  /// `footerSpacing`: the space between two footer lines, in pixels.
  final double? footerSpacing,

  /// `footerMarginTop`: the space above the footer, in pixels.
  final double? footerMarginTop,

  /// `footerFont`: the font of the footer, merged over `Chart.defaults.font` as
  /// [titleFont].
  final TextStyle? footerFont,

  /// `footerAlign`: the horizontal align of the footer lines.
  final TextAlign? footerAlign,

  /// `padding`: the space in the box around the text (Chart.js ADR 0123).
  final EdgeInsets? padding,

  /// `caretPadding`: the extra distance from the tip of the caret to the point
  /// of the tooltip, in pixels.
  final double? caretPadding,

  /// `caretSize`: the size of the caret, in pixels.
  final double? caretSize,

  /// `cornerRadius`: the corners of the box (row
  /// `adapt-flutter-border-radius`).
  final BorderRadius? cornerRadius,

  /// `boxHeight`: the height of a color box, in pixels. Null gives the size of
  /// [bodyFont] (plugin.tooltip.js:1303).
  final double? boxHeight,

  /// `boxWidth`: the width of a color box, in pixels. Null gives the size of
  /// [bodyFont] (plugin.tooltip.js:1304).
  final double? boxWidth,

  /// `multiKeyBackground`: the paint behind a color box.
  final ChartPaint? multiKeyBackground,

  /// `displayColors`: whether each label line shows the color box of its item.
  final bool? displayColors,

  /// `boxPadding`: the space between a color box and its text, in pixels.
  final double? boxPadding,

  /// `borderColor`: the paint of the border of the box.
  final ChartPaint? borderColor,

  /// `borderWidth`: the width of the border of the box, in pixels.
  final double? borderWidth,

  /// `animation`: the animation of a change of the tooltip: the settings of
  /// each property without an item of [animations]. [TooltipAnimation.off]
  /// turns the animations of the tooltip off (`animation: false`).
  final TooltipAnimation? animation,

  /// `animations`: the animation of single properties of the tooltip:
  /// [XAnimation], [YAnimation], [WidthAnimation], [HeightAnimation],
  /// [CaretXAnimation], [CaretYAnimation] and [OpacityAnimation]. A parameter
  /// that is null takes the value of [animation]. [merge] keeps each item whose
  /// class the other options have no item of.
  final List<PropertyAnimation>? animations,

  /// `callbacks`: the native callbacks of the text, the colors and the point
  /// styles (Chart.js ADR 0125). [merge] merges them by field.
  final TooltipCallbacks? callbacks,

  /// `xAlign`: the place of the box beside its caret along x. Null gives the
  /// place that the tooltip finds for its size.
  final TooltipXAlign? xAlign,

  /// `yAlign`: the place of the box beside its caret along y. Null gives the
  /// place that the tooltip finds for its size.
  final TooltipYAlign? yAlign,

  /// `itemSort`: the order of two items. The sort is stable ([jsSort]).
  final TooltipItemComparator? itemSort,

  /// `filter`: whether the tooltip shows an item. It runs before [itemSort].
  final TooltipItemFilter? filter,

  /// `usePointStyle`: whether a color box is the point style of its item.
  final bool? usePointStyle,

  /// `rtl`: whether the tooltip draws from right to left.
  final bool? rtl,

  /// `textDirection`: the text direction of the canvas during the draw. Null
  /// keeps the direction of the canvas (Chart.js ADR 0124).
  final TextDirection? textDirection,

  /// `mode` (`CoreInteractionOptions`, index.d.ts:1605): the items of the
  /// tooltip. Null gives the `mode` of `options.interaction`.
  final InteractionMode? mode,

  /// `intersect`: whether the tooltip shows only when the pointer is on an
  /// item. Null gives the `intersect` of `options.interaction`.
  final bool? intersect,

  /// `axis`: the axes of the distance from the event to an item. Null gives the
  /// `axis` of `options.interaction`.
  final InteractionAxis? axis,

  /// `includeInvisible`: whether an event also hits the items outside the chart
  /// area. Null gives the `includeInvisible` of `options.interaction`.
  final bool? includeInvisible,

  /// `reverse`: whether the tooltip reverses the order of its active items
  /// (plugin.tooltip.js:1202).
  final bool? reverse,

  /// The scriptable options of upstream as one function: the tooltip calls
  /// it with its context and the options of the update at each read, and
  /// merges the result over them. The result gives only the options that
  /// change.
  ///
  /// ```dart
  /// TooltipOptions(
  ///   scripted: (context, options) => TooltipOptions(
  ///     backgroundColor: context.tooltipItems!.length > 1 ? multi : single,
  ///   ),
  /// );
  /// ```
  // DIVERGES(chartjs): adapt-tooltip-scripted, one function for the options.
  final TooltipScript? scripted,

  /// `events`: the event types of the plugin, the option that the event
  /// filter of the chart reads (`core.controller.js:1170`, Chart.js ADR
  /// 0150). Null gives the `events` of the chart.
  @override final List<String>? events,
}) extends PluginOptions<TooltipOptions> implements InteractionOptionValues {
  /// The tooltip options.
  this;

  @override
  String get pluginId => 'tooltip';

  /// These options with each field that [over] sets. The fonts, [animation]
  /// and [callbacks] merge by field, as the resolver of upstream merges the
  /// keys of an object option, and [animations] keep each item whose class
  /// [over] has no item of.
  @override
  TooltipOptions merge(TooltipOptions over) => TooltipOptions(
    enabled: over.enabled ?? enabled,
    external: over.external ?? external,
    position: over.position ?? position,
    backgroundColor: over.backgroundColor ?? backgroundColor,
    titleColor: over.titleColor ?? titleColor,
    titleFont: titleFont?.merge(over.titleFont) ?? over.titleFont,
    titleSpacing: over.titleSpacing ?? titleSpacing,
    titleMarginBottom: over.titleMarginBottom ?? titleMarginBottom,
    titleAlign: over.titleAlign ?? titleAlign,
    bodyColor: over.bodyColor ?? bodyColor,
    bodySpacing: over.bodySpacing ?? bodySpacing,
    bodyFont: bodyFont?.merge(over.bodyFont) ?? over.bodyFont,
    bodyAlign: over.bodyAlign ?? bodyAlign,
    footerColor: over.footerColor ?? footerColor,
    footerSpacing: over.footerSpacing ?? footerSpacing,
    footerMarginTop: over.footerMarginTop ?? footerMarginTop,
    footerFont: footerFont?.merge(over.footerFont) ?? over.footerFont,
    footerAlign: over.footerAlign ?? footerAlign,
    padding: over.padding ?? padding,
    caretPadding: over.caretPadding ?? caretPadding,
    caretSize: over.caretSize ?? caretSize,
    cornerRadius: over.cornerRadius ?? cornerRadius,
    boxHeight: over.boxHeight ?? boxHeight,
    boxWidth: over.boxWidth ?? boxWidth,
    multiKeyBackground: over.multiKeyBackground ?? multiKeyBackground,
    displayColors: over.displayColors ?? displayColors,
    boxPadding: over.boxPadding ?? boxPadding,
    borderColor: over.borderColor ?? borderColor,
    borderWidth: over.borderWidth ?? borderWidth,
    animation: animation?.merge(over.animation) ?? over.animation,
    animations: _mergeAnimations(animations, over.animations),
    callbacks: callbacks?.merge(over.callbacks) ?? over.callbacks,
    xAlign: over.xAlign ?? xAlign,
    yAlign: over.yAlign ?? yAlign,
    itemSort: over.itemSort ?? itemSort,
    filter: over.filter ?? filter,
    usePointStyle: over.usePointStyle ?? usePointStyle,
    rtl: over.rtl ?? rtl,
    textDirection: over.textDirection ?? textDirection,
    mode: over.mode ?? mode,
    intersect: over.intersect ?? intersect,
    axis: over.axis ?? axis,
    includeInvisible: over.includeInvisible ?? includeInvisible,
    reverse: over.reverse ?? reverse,
    scripted: over.scripted ?? scripted,
    events: over.events ?? events,
  );

  /// The value of the interaction option [key] for the interaction modes,
  /// which read `intersect`, `axis` and `includeInvisible` of the options
  /// that they get (`core.interaction.js`), or [undefined].
  @override
  Object? interactionOption(OptionKey key) => switch (key) {
    OptionKey.intersect => intersect ?? undefined,
    OptionKey.axis => axis ?? undefined,
    OptionKey.includeInvisible => includeInvisible ?? undefined,
    OptionKey.mode => mode ?? undefined,
    _ => undefined,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TooltipOptions &&
          other.enabled == enabled &&
          other.external == external &&
          other.position == position &&
          other.backgroundColor == backgroundColor &&
          other.titleColor == titleColor &&
          other.titleFont == titleFont &&
          other.titleSpacing == titleSpacing &&
          other.titleMarginBottom == titleMarginBottom &&
          other.titleAlign == titleAlign &&
          other.bodyColor == bodyColor &&
          other.bodySpacing == bodySpacing &&
          other.bodyFont == bodyFont &&
          other.bodyAlign == bodyAlign &&
          other.footerColor == footerColor &&
          other.footerSpacing == footerSpacing &&
          other.footerMarginTop == footerMarginTop &&
          other.footerFont == footerFont &&
          other.footerAlign == footerAlign &&
          other.padding == padding &&
          other.caretPadding == caretPadding &&
          other.caretSize == caretSize &&
          other.cornerRadius == cornerRadius &&
          other.boxHeight == boxHeight &&
          other.boxWidth == boxWidth &&
          other.multiKeyBackground == multiKeyBackground &&
          other.displayColors == displayColors &&
          other.boxPadding == boxPadding &&
          other.borderColor == borderColor &&
          other.borderWidth == borderWidth &&
          other.animation == animation &&
          _nullableListEquals(other.animations, animations) &&
          other.callbacks == callbacks &&
          other.xAlign == xAlign &&
          other.yAlign == yAlign &&
          other.itemSort == itemSort &&
          other.filter == filter &&
          other.usePointStyle == usePointStyle &&
          other.rtl == rtl &&
          other.textDirection == textDirection &&
          other.mode == mode &&
          other.intersect == intersect &&
          other.axis == axis &&
          other.includeInvisible == includeInvisible &&
          other.reverse == reverse &&
          other.scripted == scripted &&
          _nullableListEquals(other.events, events);

  @override
  int get hashCode => Object.hashAll([
    enabled,
    external,
    position,
    backgroundColor,
    titleColor,
    titleFont,
    titleSpacing,
    titleMarginBottom,
    titleAlign,
    bodyColor,
    bodySpacing,
    bodyFont,
    bodyAlign,
    footerColor,
    footerSpacing,
    footerMarginTop,
    footerFont,
    footerAlign,
    padding,
    caretPadding,
    caretSize,
    cornerRadius,
    boxHeight,
    boxWidth,
    multiKeyBackground,
    displayColors,
    boxPadding,
    borderColor,
    borderWidth,
    animation,
    if (animations case final items?) Object.hashAll(items) else null,
    callbacks,
    xAlign,
    yAlign,
    itemSort,
    filter,
    usePointStyle,
    rtl,
    textDirection,
    mode,
    intersect,
    axis,
    includeInvisible,
    reverse,
    scripted,
    if (events case final types?) Object.hashAll(types) else null,
  ]);

  @override
  String toString() =>
      'TooltipOptions(enabled: $enabled, mode: $mode, position: $position)';
}

/// [TooltipOptions.scripted]: the options that change for the tooltip
/// context [context], over the options [options] of the update. Dart `null`
/// changes nothing.
// DIVERGES(chartjs): adapt-tooltip-scripted, one function for the options.
typedef TooltipScript = TooltipOptions? Function(
  ScriptableTooltipContext context,
  TooltipOptions options,
);

/// The items of [base] whose class [over] has no item of, then the items
/// of [over]: the merge of the `animations` scopes by property.
List<PropertyAnimation>? _mergeAnimations(
  List<PropertyAnimation>? base,
  List<PropertyAnimation>? over,
) {
  if (base == null || over == null) return over ?? base;
  return [
    for (final item in base)
      if (!over.any((o) => o.runtimeType == item.runtimeType)) item,
    ...over,
  ];
}

/// Whether the nullable Lists [a] and [b] have equal items in the same
/// order.
bool _nullableListEquals<T>(List<T>? a, List<T>? b) =>
    a == null || b == null ? identical(a, b) : _listEquals(a, b);

/// `animation` of the tooltip: the length, the wait, the curve and the
/// repeat of a change of the tooltip (`plugin.tooltip.js:1311-1314`). The
/// default is 400 milliseconds on `Curves.easeOutQuart`. [off] is the
/// `animation: false` of upstream: the tooltip shows each change at once.
///
/// ```dart
/// TooltipOptions(
///   animation: TooltipAnimation(duration: Duration(milliseconds: 150)),
/// );
/// ```
// DIVERGES(chartjs): adapt-property-animations, the settings object.
@immutable
final class TooltipAnimation extends AnimationSettings {
  /// The animation settings of the tooltip. A null parameter takes the
  /// value of the defaults.
  const new({super.duration, super.delay, super.easing, super.loop})
    : isOff = false;

  const new _off() : isOff = true;

  /// No animation: `animation: false`.
  static const TooltipAnimation off = TooltipAnimation._off();

  /// Whether this is [off].
  final bool isOff;

  /// These settings with each parameter that [over] sets. [off] on either
  /// side wins over the settings below it: the `false` of a scope ends the
  /// fallback of upstream.
  TooltipAnimation merge(TooltipAnimation? over) {
    if (over == null) return this;
    if (over.isOff || isOff) return over;
    return TooltipAnimation(
      duration: over.duration ?? duration,
      delay: over.delay ?? delay,
      easing: over.easing ?? easing,
      loop: over.loop ?? loop,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TooltipAnimation &&
          other.isOff == isOff &&
          other.duration == duration &&
          other.delay == delay &&
          other.easing == easing &&
          other.loop == loop;

  @override
  int get hashCode => Object.hash(isOff, duration, delay, easing, loop);

  @override
  String toString() => isOff
      ? 'TooltipAnimation.off'
      : 'TooltipAnimation(duration: $duration, easing: $easing)';
}

/// `FillerOptions` (`index.d.ts`): the resolved options of the filler plugin
/// (`plugin.filler/index.js:146-149`).
///
/// ```dart
/// final options = FillerOptions.of({'propagate': false});
/// print(options.propagate); // false
/// ```
// DIVERGES(chartjs): adapt-native-plugin-options, resolved values.
@immutable
final class const FillerOptions({
  /// `drawTime`, a [FillerDrawTime] (row `adapt-filler-draw-time-enum`).
  required final FillerDrawTime? drawTime,

  /// `propagate`.
  required final bool propagate,
}) {
  /// The options with the given values.
  this;

  /// The options of the resolved options [options].
  // ignore: prefer_constructors_over_static_methods
  static FillerOptions of(Object? options) => FillerOptions(
    drawTime: FillerDrawTime.of(optionOf(options, OptionKey.drawTime)),
    propagate: boolOption(
      optionOf(options, OptionKey.propagate),
      OptionKey.propagate,
    ),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FillerOptions &&
          other.drawTime == drawTime &&
          other.propagate == propagate;

  @override
  int get hashCode => Object.hash(drawTime, propagate);

  @override
  String toString() =>
      'FillerOptions(drawTime: $drawTime, propagate: $propagate)';
}

/// `DecimationOptions` (`index.d.ts`): the resolved options of the
/// decimation plugin (`plugin.decimation.js:200-203`).
///
/// ```dart
/// final options = DecimationOptions.of({
///   'enabled': true,
///   'algorithm': const LttbDecimationAlgorithm(),
///   'samples': 50,
/// });
/// print(options.samples); // 50.0
/// ```
// DIVERGES(chartjs): adapt-native-plugin-options, resolved values.
@immutable
final class const DecimationOptions({
  /// `algorithm`: the algorithm of the option. A value that is not an
  /// algorithm gives an algorithm that throws the error of upstream at its
  /// use (`Unsupported decimation algorithm`).
  required final DecimationAlgorithm algorithm,

  /// `enabled`.
  required final bool enabled,

  /// `samples`: the number of a truthy value, else Dart `null`
  /// (`plugin.decimation.js:12`).
  required final double? samples,

  /// `threshold`: the number of a truthy value, else Dart `null`
  /// (`plugin.decimation.js:242`).
  required final double? threshold,
}) {
  /// The options with the given values.
  this;

  /// The options of the resolved options [options].
  // ignore: prefer_constructors_over_static_methods
  static DecimationOptions of(Object? options) {
    final algorithm = optionOf(options, OptionKey.algorithm);
    return DecimationOptions(
      algorithm:
          DecimationAlgorithm.of(algorithm) ??
          _UnsupportedAlgorithm(jsToString(algorithm)),
      enabled: boolOption(
        optionOf(options, OptionKey.enabled),
        OptionKey.enabled,
      ),
      samples: _truthyNumber(optionOf(options, OptionKey.samples)),
      threshold: _truthyNumber(optionOf(options, OptionKey.threshold)),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DecimationOptions &&
          other.algorithm == algorithm &&
          other.enabled == enabled &&
          other.samples == samples &&
          other.threshold == threshold;

  @override
  int get hashCode => Object.hash(algorithm, enabled, samples, threshold);

  @override
  String toString() =>
      'DecimationOptions(algorithm: $algorithm, enabled: $enabled, '
      'samples: $samples, threshold: $threshold)';
}

/// The algorithm of an option value that is not an algorithm: its
/// [decimate] throws the error of `plugin.decimation.js:277`, the `default`
/// of the `switch` by the name of the algorithm.
// DIVERGES(chartjs): adapt-decimation-algorithm-objects, the error at its use.
final class const _UnsupportedAlgorithm(final String name)
    extends DecimationAlgorithm {
  @override
  List<ParsedItem?> decimate(
    List<ParsedItem?> data,
    int start,
    int count,
    double availableWidth,
    DecimationOptions options,
  ) => throw StateError("Unsupported decimation algorithm '$name'");

  @override
  bool operator ==(Object other) =>
      other is _UnsupportedAlgorithm && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

/// `ColorsPluginOptions` (`plugin.colors.ts:4-7`): the resolved options of
/// the colors plugin.
///
/// ```dart
/// final options = ColorsPluginOptions.of({'forceOverride': true});
/// print(options.forceOverride); // true
/// ```
// DIVERGES(chartjs): adapt-native-plugin-options, resolved values.
@immutable
final class const ColorsPluginOptions({
  /// `enabled`.
  required final bool enabled,

  /// `forceOverride`.
  required final bool forceOverride,
}) {
  /// The options with the given values.
  this;

  /// The options of the resolved options [options].
  // ignore: prefer_constructors_over_static_methods
  static ColorsPluginOptions of(Object? options) => ColorsPluginOptions(
    enabled: boolOption(
      optionOf(options, OptionKey.enabled),
      OptionKey.enabled,
    ),
    forceOverride: boolOption(
      optionOf(options, OptionKey.forceOverride),
      OptionKey.forceOverride,
    ),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColorsPluginOptions &&
          other.enabled == enabled &&
          other.forceOverride == forceOverride;

  @override
  int get hashCode => Object.hash(enabled, forceOverride);

  @override
  String toString() =>
      'ColorsPluginOptions(enabled: $enabled, '
      'forceOverride: $forceOverride)';
}
