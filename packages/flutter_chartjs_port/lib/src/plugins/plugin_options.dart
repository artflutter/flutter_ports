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
import 'package:flutter_chartjs_port/src/canvas/canvas_values.dart'
    show canvasNumber, canvasTextAlign;
import 'package:flutter_chartjs_port/src/core/core.interaction.dart'
    show InteractionMode;
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show
        boolOption,
        functionOption,
        paddingOption,
        readOption,
        textDirectionOption;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show toFont;
import 'package:flutter_chartjs_port/src/js/js_number.dart'
    show jsToNumber, jsTruthy;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
import 'package:flutter_chartjs_port/src/plugins/filler_draw_time.dart'
    show FillerDrawTime;
import 'package:flutter_chartjs_port/src/plugins/tooltip_position.dart'
    show TooltipPositioner;
import 'package:flutter_chartjs_port/src/types/align.dart'
    show ChartAlign, TooltipXAlign, TooltipYAlign;
import 'package:flutter_chartjs_port/src/types/chart_paint.dart'
    show ChartPaint, chartPaintOf;
import 'package:flutter_chartjs_port/src/types/chart_text_style.dart'
    show ChartTextStyle;
import 'package:flutter_chartjs_port/src/types/layout.dart'
    show ChartPosition, LayoutPosition;
import 'package:flutter_chartjs_port/src/types/legend_callbacks.dart';
import 'package:flutter_chartjs_port/src/types/tooltip_callbacks.dart';

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

/// `TitleOptions` (`index.d.ts`): the options of the title and the subtitle
/// plugins (`plugin.title.js:145-156`, `plugin.subtitle.js:32-43`).
extension type const TitleOptions(Object? object) {
  /// `align`, a [ChartAlign] (row `adapt-chart-align-enum`).
  ChartAlign? get align => ChartAlign.of(optionOf(object, OptionKey.align));

  /// `color`: the paint of the option value, or [ChartPaint.unchanged]
  /// without one.
  ChartPaint get color => chartPaintOf(optionOf(object, OptionKey.color));

  /// `display`.
  bool get display =>
      boolOption(optionOf(object, OptionKey.display), OptionKey.display);

  /// `font`: the [toFont] of the option value.
  ChartTextStyle get font => toFont(optionOf(object, OptionKey.font));

  /// `padding`.
  EdgeInsets get padding => paddingOption(optionOf(object, OptionKey.padding));

  /// `position`, a [ChartPosition] (row `adapt-chart-position-enum`).
  ChartPosition? get position =>
      ChartPosition.of(optionOf(object, OptionKey.position));

  /// `text`: its lines, a String is one line.
  List<String> get text => _textLines(optionOf(object, OptionKey.text));
}

/// `LegendOptions` (`index.d.ts`): the options of the legend plugin
/// (`plugin.legend.js:636-712`).
extension type const LegendOptions(Object? object) {
  /// `align`, a [ChartAlign] (row `adapt-chart-align-enum`).
  ChartAlign? get align => ChartAlign.of(optionOf(object, OptionKey.align));

  /// `display`.
  bool get display =>
      boolOption(optionOf(object, OptionKey.display), OptionKey.display);

  /// `labels`.
  LegendLabelOptions get labels =>
      LegendLabelOptions(optionOf(object, OptionKey.labels));

  /// `labels`, the raw value: a falsy value stays itself
  /// (`plugin.legend.js:105`).
  Object? get labelsValue => optionOf(object, OptionKey.labels);

  /// `maxHeight`: the number of a truthy value, else Dart `null`
  /// (`plugin.legend.js:154`).
  double? get maxHeight => _truthyNumber(optionOf(object, OptionKey.maxHeight));

  /// `maxWidth`: the number of a truthy value, else Dart `null`
  /// (`plugin.legend.js:153`).
  double? get maxWidth => _truthyNumber(optionOf(object, OptionKey.maxWidth));

  /// `onClick`: the function itself, or Dart `null` for no function (Chart.js
  /// ADR 0130).
  LegendEventHandler? get onClick => functionOption<LegendEventHandler>(
    optionOf(object, OptionKey.onClick),
    OptionKey.onClick,
  );

  /// `onHover`: the function itself, or Dart `null` for no function (Chart.js
  /// ADR 0130).
  LegendEventHandler? get onHover => functionOption<LegendEventHandler>(
    optionOf(object, OptionKey.onHover),
    OptionKey.onHover,
  );

  /// `onLeave`: the function itself, or Dart `null` for no function (Chart.js
  /// ADR 0130).
  LegendEventHandler? get onLeave => functionOption<LegendEventHandler>(
    optionOf(object, OptionKey.onLeave),
    OptionKey.onLeave,
  );

  /// `position`, a [LayoutPosition] (row `adapt-chart-position-enum`).
  LayoutPosition? get position =>
      _layoutPosition(optionOf(object, OptionKey.position));

  /// `reverse`.
  bool get reverse =>
      boolOption(optionOf(object, OptionKey.reverse), OptionKey.reverse);

  /// `rtl`.
  bool get rtl => boolOption(optionOf(object, OptionKey.rtl), OptionKey.rtl);

  /// `textDirection`.
  TextDirection? get textDirection =>
      textDirectionOption(optionOf(object, OptionKey.textDirection));

  /// `title`.
  LegendTitleOptions get title =>
      LegendTitleOptions(optionOf(object, OptionKey.title));
}

/// The `labels` of `LegendOptions` (`index.d.ts`, an inline type): the
/// label options of the legend (`plugin.legend.js:664-705`).
extension type const LegendLabelOptions(Object? object) {
  /// `borderRadius`, the raw value: the legend item keeps it.
  Object? get borderRadius => optionOf(object, OptionKey.borderRadius);

  /// `boxHeight`: Dart `null` for an absent value, else its number
  /// (`plugin.legend.js:25`, row `adapt-legend-number-options`).
  double? get boxHeight =>
      _definedNumber(optionOf(object, OptionKey.boxHeight));

  /// `boxWidth`: Dart `null` for an absent value, else its number
  /// (`plugin.legend.js:25`, row `adapt-legend-number-options`).
  double? get boxWidth => _definedNumber(optionOf(object, OptionKey.boxWidth));

  /// `color`, the raw value: the legend item and the canvas take a paint or
  /// a Flutter `Color`.
  Object? get color => optionOf(object, OptionKey.color);

  /// `filter`: the function itself, or Dart `null` for no function (Chart.js
  /// ADR 0130).
  LegendItemFilter? get filter => functionOption<LegendItemFilter>(
    optionOf(object, OptionKey.filter),
    OptionKey.filter,
  );

  /// `font`: the [toFont] of the option value.
  ChartTextStyle get font => toFont(optionOf(object, OptionKey.font));

  /// `generateLabels`, the raw value: `plugin.legend.dart` reads it as a
  /// `LegendLabelsGenerator`, which takes the chart class.
  Object? get generateLabels => optionOf(object, OptionKey.generateLabels);

  /// `padding`: its number (row `adapt-legend-number-options`).
  double get padding => jsToNumber(optionOf(object, OptionKey.padding));

  /// `pointStyle`, the raw value: a `PointStyle` or a boolean, which the
  /// legend item keeps.
  Object? get pointStyle => optionOf(object, OptionKey.pointStyle);

  /// `pointStyleWidth`: the number of a truthy value, else Dart `null`
  /// (`plugin.legend.js:29`, `:336`).
  double? get pointStyleWidth =>
      _truthyNumber(optionOf(object, OptionKey.pointStyleWidth));

  /// `sort`: the function itself, or Dart `null` for no function (Chart.js
  /// ADR 0130).
  LegendItemComparator? get sort => functionOption<LegendItemComparator>(
    optionOf(object, OptionKey.sort),
    OptionKey.sort,
  );

  /// `textAlign`, a Flutter [TextAlign] (row `adapt-flutter-text-align`).
  TextAlign? get textAlign =>
      canvasTextAlign(optionOf(object, OptionKey.textAlign));

  /// `useBorderRadius`.
  bool get useBorderRadius => boolOption(
    optionOf(object, OptionKey.useBorderRadius),
    OptionKey.useBorderRadius,
  );

  /// `usePointStyle`.
  bool get usePointStyle => boolOption(
    optionOf(object, OptionKey.usePointStyle),
    OptionKey.usePointStyle,
  );
}

/// The `title` of `LegendOptions` (`index.d.ts`, an inline type): the title
/// options of the legend (`plugin.legend.js:706-711`).
extension type const LegendTitleOptions(Object? object) {
  /// `color`, the raw value: the canvas takes a paint or a Flutter `Color`.
  Object? get color => optionOf(object, OptionKey.color);

  /// `display`.
  bool get display =>
      boolOption(optionOf(object, OptionKey.display), OptionKey.display);

  /// `font`: the [toFont] of the option value.
  ChartTextStyle get font => toFont(optionOf(object, OptionKey.font));

  /// `padding`.
  EdgeInsets get padding => paddingOption(optionOf(object, OptionKey.padding));

  /// `position`, a [ChartAlign] (row `adapt-chart-align-enum`).
  ChartAlign? get position =>
      ChartAlign.of(optionOf(object, OptionKey.position));

  /// `text`: its lines, a String is one line.
  List<String> get text => _textLines(optionOf(object, OptionKey.text));
}

/// `TooltipOptions` (`index.d.ts`): the options of the tooltip plugin
/// (`plugin.tooltip.js:1275-1325`), with the keys of the `interaction`
/// scope that the tooltip reads (`mode`, `reverse`).
extension type const TooltipOptions(Object? object) {
  /// `animations`, the raw value: `false` or the scope of the animations.
  Object? get animations => optionOf(object, OptionKey.animations);

  /// `backgroundColor`, the raw value: the canvas takes a paint or a Flutter
  /// `Color`.
  Object? get backgroundColor => optionOf(object, OptionKey.backgroundColor);

  /// `bodyAlign`, a Flutter [TextAlign] (row `adapt-flutter-text-align`).
  TextAlign? get bodyAlign =>
      canvasTextAlign(optionOf(object, OptionKey.bodyAlign));

  /// `bodyColor`, the raw value: the canvas takes a paint or a Flutter `Color`.
  Object? get bodyColor => optionOf(object, OptionKey.bodyColor);

  /// `bodyFont`: the [toFont] of the option value.
  ChartTextStyle get bodyFont => toFont(optionOf(object, OptionKey.bodyFont));

  /// `bodySpacing`: its number.
  double get bodySpacing => jsToNumber(optionOf(object, OptionKey.bodySpacing));

  /// `borderColor`, the raw value: the canvas takes a paint or a Flutter
  /// `Color`.
  Object? get borderColor => optionOf(object, OptionKey.borderColor);

  /// `borderWidth`: Dart `null` for an absent value, else its number, as the
  /// canvas setter `lineWidth` takes it ([canvasNumber]).
  double? get borderWidth =>
      canvasNumber(optionOf(object, OptionKey.borderWidth));

  /// `boxHeight`: its number.
  double get boxHeight => jsToNumber(optionOf(object, OptionKey.boxHeight));

  /// `boxPadding`: its number.
  double get boxPadding => jsToNumber(optionOf(object, OptionKey.boxPadding));

  /// `boxWidth`: its number.
  double get boxWidth => jsToNumber(optionOf(object, OptionKey.boxWidth));

  /// `callbacks`.
  TooltipCallbacks get callbacks =>
      tooltipCallbacksOf(optionOf(object, OptionKey.callbacks));

  /// `caretPadding`: its number.
  double get caretPadding =>
      jsToNumber(optionOf(object, OptionKey.caretPadding));

  /// `caretSize`: its number.
  double get caretSize => jsToNumber(optionOf(object, OptionKey.caretSize));

  /// `cornerRadius`, the raw value: a number or the corners, which
  /// `toTRBLCorners` reads.
  Object? get cornerRadius => optionOf(object, OptionKey.cornerRadius);

  /// `displayColors`.
  bool get displayColors => boolOption(
    optionOf(object, OptionKey.displayColors),
    OptionKey.displayColors,
  );

  /// `enabled`.
  bool get enabled =>
      boolOption(optionOf(object, OptionKey.enabled), OptionKey.enabled);

  /// `external`: the function itself, or Dart `null` for no function (row
  /// `adapt-native-tooltip-item`).
  TooltipExternal? get external => functionOption<TooltipExternal>(
    optionOf(object, OptionKey.external),
    OptionKey.external,
  );

  /// `filter`: the function itself, or Dart `null` for no function (row
  /// `adapt-native-tooltip-item`).
  TooltipItemFilter? get filter => functionOption<TooltipItemFilter>(
    optionOf(object, OptionKey.filter),
    OptionKey.filter,
  );

  /// `footerAlign`, a Flutter [TextAlign] (row `adapt-flutter-text-align`).
  TextAlign? get footerAlign =>
      canvasTextAlign(optionOf(object, OptionKey.footerAlign));

  /// `footerColor`, the raw value: the canvas takes a paint or a Flutter
  /// `Color`.
  Object? get footerColor => optionOf(object, OptionKey.footerColor);

  /// `footerFont`: the [toFont] of the option value.
  ChartTextStyle get footerFont =>
      toFont(optionOf(object, OptionKey.footerFont));

  /// `footerMarginTop`: its number.
  double get footerMarginTop =>
      jsToNumber(optionOf(object, OptionKey.footerMarginTop));

  /// `footerSpacing`: its number.
  double get footerSpacing =>
      jsToNumber(optionOf(object, OptionKey.footerSpacing));

  /// `itemSort`: the function itself, or Dart `null` for no function (row
  /// `adapt-native-tooltip-item`).
  TooltipItemComparator? get itemSort => functionOption<TooltipItemComparator>(
    optionOf(object, OptionKey.itemSort),
    OptionKey.itemSort,
  );

  /// `mode`: the mode itself, or Dart `null` for a value that is not a
  /// mode (row `adapt-interaction-mode-objects`).
  InteractionMode? get mode =>
      InteractionMode.of(optionOf(object, OptionKey.mode));

  /// `multiKeyBackground`, the raw value: the canvas takes a paint or a
  /// Flutter `Color`.
  Object? get multiKeyBackground =>
      optionOf(object, OptionKey.multiKeyBackground);

  /// `padding`.
  EdgeInsets get padding => paddingOption(optionOf(object, OptionKey.padding));

  /// `position`: the positioner itself, or Dart `null` for a value that is
  /// not a positioner (row `adapt-tooltip-positioner-objects`).
  TooltipPositioner? get position =>
      TooltipPositioner.of(optionOf(object, OptionKey.position));

  /// `reverse`.
  bool get reverse =>
      boolOption(optionOf(object, OptionKey.reverse), OptionKey.reverse);

  /// `rtl`.
  bool get rtl => boolOption(optionOf(object, OptionKey.rtl), OptionKey.rtl);

  /// `textDirection`.
  TextDirection? get textDirection =>
      textDirectionOption(optionOf(object, OptionKey.textDirection));

  /// `titleAlign`, a Flutter [TextAlign] (row `adapt-flutter-text-align`).
  TextAlign? get titleAlign =>
      canvasTextAlign(optionOf(object, OptionKey.titleAlign));

  /// `titleColor`, the raw value: the canvas takes a paint or a Flutter
  /// `Color`.
  Object? get titleColor => optionOf(object, OptionKey.titleColor);

  /// `titleFont`: the [toFont] of the option value.
  ChartTextStyle get titleFont => toFont(optionOf(object, OptionKey.titleFont));

  /// `titleMarginBottom`: its number.
  double get titleMarginBottom =>
      jsToNumber(optionOf(object, OptionKey.titleMarginBottom));

  /// `titleSpacing`: its number.
  double get titleSpacing =>
      jsToNumber(optionOf(object, OptionKey.titleSpacing));

  /// `usePointStyle`.
  bool get usePointStyle => boolOption(
    optionOf(object, OptionKey.usePointStyle),
    OptionKey.usePointStyle,
  );

  /// `xAlign`.
  TooltipXAlign? get xAlign =>
      TooltipXAlign.of(optionOf(object, OptionKey.xAlign));

  /// `yAlign`.
  TooltipYAlign? get yAlign =>
      TooltipYAlign.of(optionOf(object, OptionKey.yAlign));
}

/// `FillerOptions` (`index.d.ts`): the options of the filler plugin
/// (`plugin.filler/index.js:146-149`).
extension type const FillerOptions(Object? object) {
  /// `drawTime`, a [FillerDrawTime] (row `adapt-filler-draw-time-enum`).
  FillerDrawTime? get drawTime =>
      FillerDrawTime.of(optionOf(object, OptionKey.drawTime));

  /// `propagate`.
  bool get propagate =>
      boolOption(optionOf(object, OptionKey.propagate), OptionKey.propagate);
}

/// `DecimationOptions` (`index.d.ts`): the options of the decimation plugin
/// (`plugin.decimation.js:200-203`).
extension type const DecimationOptions(Object? object) {
  /// `algorithm`: the raw value. The plugin reads the algorithm with
  /// `DecimationAlgorithm.of`, and names the raw value in its error.
  Object? get algorithm => optionOf(object, OptionKey.algorithm);

  /// `enabled`.
  bool get enabled =>
      boolOption(optionOf(object, OptionKey.enabled), OptionKey.enabled);

  /// `samples`: the number of a truthy value, else Dart `null`
  /// (`plugin.decimation.js:12`).
  double? get samples => _truthyNumber(optionOf(object, OptionKey.samples));

  /// `threshold`: the number of a truthy value, else Dart `null`
  /// (`plugin.decimation.js:242`).
  double? get threshold => _truthyNumber(optionOf(object, OptionKey.threshold));
}

/// `ColorsPluginOptions` (`plugin.colors.ts:4-7`): the options of the colors
/// plugin.
extension type const ColorsPluginOptions(Object? object) {
  /// `enabled`.
  bool get enabled =>
      boolOption(optionOf(object, OptionKey.enabled), OptionKey.enabled);

  /// `forceOverride`.
  bool get forceOverride => boolOption(
    optionOf(object, OptionKey.forceOverride),
    OptionKey.forceOverride,
  );
}
