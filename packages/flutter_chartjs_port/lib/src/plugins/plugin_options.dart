// Original code, not ported from Chart.js: the plugin option facades.

/// The typed option facades of the seven built-in plugins (Chart.js ADR 0054
/// §4 and §12).
///
/// The options of a plugin hook are a context resolver of
/// `core.plugins.js:175-188` (an `OptionView`). The options of a box (`Title`,
/// `Legend`, `Tooltip`) are the options of its last hook, or the object that
/// a spec gives to the constructor. A facade is an extension type over that
/// object, with no cost: each getter reads one option key with [optionOf],
/// the typed read `readKey` of a resolver. A getter gives the type of its
/// key in the schema (Chart.js ADR 0150): it applies the conversion that
/// each reader applied at the read (`jsToNumber`, `toFont`,
/// `canvasTextAlign`, ...). Each reader reads the getter at the upstream
/// place of the read, so the reads keep their upstream order. Thus the user
/// calls of a scriptable option keep their order. A getter that still gives
/// the raw value says why.
///
/// A facade takes the name of its `index.d.ts` interface (`LegendOptions`,
/// `TitleOptions`, `TooltipOptions`, `TooltipCallbacks`, `FillerOptions`,
/// `DecimationOptions`) or a port-only name for an inline type of
/// `index.d.ts` (`LegendLabelOptions`, `LegendTitleOptions`,
/// `ColorsPluginOptions` of `plugin.colors.ts:4`). The app library
/// exports them: they are the `O` of the hooks of the built-in plugins.
///
/// This library is a pure layer.
library;

import 'dart:ui' show TextAlign, TextDirection;

import 'package:flutter/painting.dart' show EdgeInsets;
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
  /// `borderRadius`: a number or the corners, which the legend item keeps.
  required final Object? borderRadius,

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
    borderRadius: optionOf(options, OptionKey.borderRadius),
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

/// `TooltipOptions` (`index.d.ts`): the resolved options of the tooltip
/// plugin (`plugin.tooltip.js:1275-1325`), with the keys of the
/// `interaction` scope that the tooltip reads (`mode`, `reverse`).
///
/// The plugin makes one object from the resolved options of each update
/// ([TooltipOptions.of]). The tooltip resolves its options again with its
/// own context where upstream calls `setContext` (plugin.tooltip.js:515).
///
/// ```dart
/// final options = TooltipOptions.of({'enabled': false, 'caretSize': 5});
/// print(options.caretSize); // 5.0
/// ```
// DIVERGES(chartjs): adapt-native-plugin-options, resolved values.
@immutable
final class const TooltipOptions({
  /// `animations`, the raw value: `false` or the scope of the animations.
  required final Object? animations,

  /// `backgroundColor`, the raw value: the canvas takes a paint or a Flutter
  /// `Color`.
  required final Object? backgroundColor,

  /// `bodyAlign`, a Flutter [TextAlign] (row `adapt-flutter-text-align`).
  required final TextAlign? bodyAlign,

  /// `bodyColor`, the raw value: the canvas takes a paint or a Flutter `Color`.
  required final Object? bodyColor,

  /// `bodyFont`: the [toFont] of the option value.
  required final ChartTextStyle bodyFont,

  /// `bodySpacing`: its number.
  required final double bodySpacing,

  /// `borderColor`, the raw value: the canvas takes a paint or a Flutter
  /// `Color`.
  required final Object? borderColor,

  /// `borderWidth`: Dart `null` for an absent value, else its number, as the
  /// canvas setter `lineWidth` takes it ([canvasNumber]).
  required final double? borderWidth,

  /// `boxHeight`: its number.
  required final double boxHeight,

  /// `boxPadding`: its number.
  required final double boxPadding,

  /// `boxWidth`: its number.
  required final double boxWidth,

  /// `callbacks`.
  required final TooltipCallbacks callbacks,

  /// `caretPadding`: its number.
  required final double caretPadding,

  /// `caretSize`: its number.
  required final double caretSize,

  /// `cornerRadius`, the raw value: a number or the corners, which
  /// `toTRBLCorners` reads.
  required final Object? cornerRadius,

  /// `displayColors`.
  required final bool displayColors,

  /// `enabled`.
  required final bool enabled,

  /// `external`: the function itself, or Dart `null` for no function (row
  /// `adapt-native-tooltip-item`).
  required final TooltipExternal? external,

  /// `filter`: the function itself, or Dart `null` for no function (row
  /// `adapt-native-tooltip-item`).
  required final TooltipItemFilter? filter,

  /// `footerAlign`, a Flutter [TextAlign] (row `adapt-flutter-text-align`).
  required final TextAlign? footerAlign,

  /// `footerColor`, the raw value: the canvas takes a paint or a Flutter
  /// `Color`.
  required final Object? footerColor,

  /// `footerFont`: the [toFont] of the option value.
  required final ChartTextStyle footerFont,

  /// `footerMarginTop`: its number.
  required final double footerMarginTop,

  /// `footerSpacing`: its number.
  required final double footerSpacing,

  /// `itemSort`: the function itself, or Dart `null` for no function (row
  /// `adapt-native-tooltip-item`).
  required final TooltipItemComparator? itemSort,

  /// `mode`: the mode itself, or Dart `null` for a value that is not a
  /// mode (row `adapt-interaction-mode-objects`).
  required final InteractionMode? mode,

  /// `multiKeyBackground`, the raw value: the canvas takes a paint or a
  /// Flutter `Color`.
  required final Object? multiKeyBackground,

  /// `padding`.
  required final EdgeInsets padding,

  /// `position`: the positioner itself, or Dart `null` for a value that is
  /// not a positioner (row `adapt-tooltip-positioner-objects`).
  required final TooltipPositioner? position,

  /// `reverse`.
  required final bool reverse,

  /// `rtl`.
  required final bool rtl,

  /// `textDirection`.
  required final TextDirection? textDirection,

  /// `titleAlign`, a Flutter [TextAlign] (row `adapt-flutter-text-align`).
  required final TextAlign? titleAlign,

  /// `titleColor`, the raw value: the canvas takes a paint or a Flutter
  /// `Color`.
  required final Object? titleColor,

  /// `titleFont`: the [toFont] of the option value.
  required final ChartTextStyle titleFont,

  /// `titleMarginBottom`: its number.
  required final double titleMarginBottom,

  /// `titleSpacing`: its number.
  required final double titleSpacing,

  /// `usePointStyle`.
  required final bool usePointStyle,

  /// `xAlign`.
  required final TooltipXAlign? xAlign,

  /// `yAlign`.
  required final TooltipYAlign? yAlign,

  /// The resolved options that gave these values, or Dart `null` for options
  /// that a program makes. The tooltip resolves them again with its context,
  /// and the interaction mode reads `intersect`, `axis` and
  /// `includeInvisible` from them. It is not a part of `==`.
  final Object? view,
}) {
  /// The options with the given values.
  this;

  /// The options of the resolved options [options]: one read of each key.
  /// A [TooltipOptions] stays itself.
  // ignore: prefer_constructors_over_static_methods
  static TooltipOptions of(Object? options) {
    if (options is TooltipOptions) return options;
    return TooltipOptions(
      animations: optionOf(options, OptionKey.animations),
      backgroundColor: optionOf(options, OptionKey.backgroundColor),
      bodyAlign: canvasTextAlign(optionOf(options, OptionKey.bodyAlign)),
      bodyColor: optionOf(options, OptionKey.bodyColor),
      bodyFont: toFont(optionOf(options, OptionKey.bodyFont)),
      bodySpacing: jsToNumber(optionOf(options, OptionKey.bodySpacing)),
      borderColor: optionOf(options, OptionKey.borderColor),
      borderWidth: canvasNumber(optionOf(options, OptionKey.borderWidth)),
      boxHeight: jsToNumber(optionOf(options, OptionKey.boxHeight)),
      boxPadding: jsToNumber(optionOf(options, OptionKey.boxPadding)),
      boxWidth: jsToNumber(optionOf(options, OptionKey.boxWidth)),
      callbacks: tooltipCallbacksOf(optionOf(options, OptionKey.callbacks)),
      caretPadding: jsToNumber(optionOf(options, OptionKey.caretPadding)),
      caretSize: jsToNumber(optionOf(options, OptionKey.caretSize)),
      cornerRadius: optionOf(options, OptionKey.cornerRadius),
      displayColors: boolOption(
        optionOf(options, OptionKey.displayColors),
        OptionKey.displayColors,
      ),
      enabled: boolOption(
        optionOf(options, OptionKey.enabled),
        OptionKey.enabled,
      ),
      external: functionOption<TooltipExternal>(
        optionOf(options, OptionKey.external),
        OptionKey.external,
      ),
      filter: functionOption<TooltipItemFilter>(
        optionOf(options, OptionKey.filter),
        OptionKey.filter,
      ),
      footerAlign: canvasTextAlign(optionOf(options, OptionKey.footerAlign)),
      footerColor: optionOf(options, OptionKey.footerColor),
      footerFont: toFont(optionOf(options, OptionKey.footerFont)),
      footerMarginTop: jsToNumber(optionOf(options, OptionKey.footerMarginTop)),
      footerSpacing: jsToNumber(optionOf(options, OptionKey.footerSpacing)),
      itemSort: functionOption<TooltipItemComparator>(
        optionOf(options, OptionKey.itemSort),
        OptionKey.itemSort,
      ),
      mode: InteractionMode.of(optionOf(options, OptionKey.mode)),
      multiKeyBackground: optionOf(options, OptionKey.multiKeyBackground),
      padding: paddingOption(optionOf(options, OptionKey.padding)),
      position: TooltipPositioner.of(optionOf(options, OptionKey.position)),
      reverse: boolOption(
        optionOf(options, OptionKey.reverse),
        OptionKey.reverse,
      ),
      rtl: boolOption(optionOf(options, OptionKey.rtl), OptionKey.rtl),
      textDirection: textDirectionOption(
        optionOf(options, OptionKey.textDirection),
      ),
      titleAlign: canvasTextAlign(optionOf(options, OptionKey.titleAlign)),
      titleColor: optionOf(options, OptionKey.titleColor),
      titleFont: toFont(optionOf(options, OptionKey.titleFont)),
      titleMarginBottom: jsToNumber(
        optionOf(options, OptionKey.titleMarginBottom),
      ),
      titleSpacing: jsToNumber(optionOf(options, OptionKey.titleSpacing)),
      usePointStyle: boolOption(
        optionOf(options, OptionKey.usePointStyle),
        OptionKey.usePointStyle,
      ),
      xAlign: TooltipXAlign.of(optionOf(options, OptionKey.xAlign)),
      yAlign: TooltipYAlign.of(optionOf(options, OptionKey.yAlign)),
      view: options,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TooltipOptions &&
          other.animations == animations &&
          other.backgroundColor == backgroundColor &&
          other.bodyAlign == bodyAlign &&
          other.bodyColor == bodyColor &&
          other.bodyFont == bodyFont &&
          other.bodySpacing == bodySpacing &&
          other.borderColor == borderColor &&
          other.borderWidth == borderWidth &&
          other.boxHeight == boxHeight &&
          other.boxPadding == boxPadding &&
          other.boxWidth == boxWidth &&
          other.callbacks == callbacks &&
          other.caretPadding == caretPadding &&
          other.caretSize == caretSize &&
          other.cornerRadius == cornerRadius &&
          other.displayColors == displayColors &&
          other.enabled == enabled &&
          other.external == external &&
          other.filter == filter &&
          other.footerAlign == footerAlign &&
          other.footerColor == footerColor &&
          other.footerFont == footerFont &&
          other.footerMarginTop == footerMarginTop &&
          other.footerSpacing == footerSpacing &&
          other.itemSort == itemSort &&
          other.mode == mode &&
          other.multiKeyBackground == multiKeyBackground &&
          other.padding == padding &&
          other.position == position &&
          other.reverse == reverse &&
          other.rtl == rtl &&
          other.textDirection == textDirection &&
          other.titleAlign == titleAlign &&
          other.titleColor == titleColor &&
          other.titleFont == titleFont &&
          other.titleMarginBottom == titleMarginBottom &&
          other.titleSpacing == titleSpacing &&
          other.usePointStyle == usePointStyle &&
          other.xAlign == xAlign &&
          other.yAlign == yAlign;

  @override
  int get hashCode => Object.hashAll([
    animations,
    backgroundColor,
    bodyAlign,
    bodyColor,
    bodyFont,
    bodySpacing,
    borderColor,
    borderWidth,
    boxHeight,
    boxPadding,
    boxWidth,
    callbacks,
    caretPadding,
    caretSize,
    cornerRadius,
    displayColors,
    enabled,
    external,
    filter,
    footerAlign,
    footerColor,
    footerFont,
    footerMarginTop,
    footerSpacing,
    itemSort,
    mode,
    multiKeyBackground,
    padding,
    position,
    reverse,
    rtl,
    textDirection,
    titleAlign,
    titleColor,
    titleFont,
    titleMarginBottom,
    titleSpacing,
    usePointStyle,
    xAlign,
    yAlign,
  ]);

  @override
  String toString() =>
      'TooltipOptions(enabled: $enabled, mode: $mode, position: $position)';
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
  List<Object?> decimate(
    List<Object?> data,
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
