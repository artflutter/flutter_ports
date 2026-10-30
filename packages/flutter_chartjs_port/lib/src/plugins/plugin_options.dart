// Original code, not ported from Chart.js: the plugin option facades.

/// The typed option facades of the seven built-in plugins (Chart.js ADR 0054
/// §4 and §12).
///
/// The options of a plugin hook are a context resolver of
/// `core.plugins.js:175-188` (an `OptionView`). The options of a box (`Title`,
/// `Legend`, `Tooltip`) are the options of its last hook, or the object that
/// a spec gives to the constructor. A facade is an extension type over that
/// object, with no cost: each getter reads one option key with [optionOf],
/// the typed read `readKey` of a resolver. The getters give the resolved JS
/// value, as upstream gives it: the readers keep the JS operators of
/// upstream (`jsTruthy`, `jsToNumber`, `toFont`, ...) at their upstream
/// places, and the reads keep their upstream order. Thus the user calls of a
/// scriptable option keep their order.
///
/// A facade takes the name of its `index.d.ts` interface (`LegendOptions`,
/// `TitleOptions`, `TooltipOptions`, `TooltipCallbacks`, `FillerOptions`,
/// `DecimationOptions`) or a port-only name for an inline type of
/// `index.d.ts` (`LegendLabelOptions`, `LegendTitleOptions`,
/// `ColorsPluginOptions` of `plugin.colors.ts:4`, `FillTargetOptions`). The
/// facades are internal: no public library exports them.
///
/// This library is a pure layer.
library;

import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show readOption;
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';

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

/// `TitleOptions` (`index.d.ts`): the options of the title and the subtitle
/// plugins (`plugin.title.js:145-156`, `plugin.subtitle.js:32-43`).
extension type const TitleOptions(Object? object) {
  /// `align`.
  Object? get align => optionOf(object, OptionKey.align);

  /// `color`.
  Object? get color => optionOf(object, OptionKey.color);

  /// `display`.
  Object? get display => optionOf(object, OptionKey.display);

  /// `font`.
  Object? get font => optionOf(object, OptionKey.font);

  /// `padding`.
  Object? get padding => optionOf(object, OptionKey.padding);

  /// `position`.
  Object? get position => optionOf(object, OptionKey.position);

  /// `text`.
  Object? get text => optionOf(object, OptionKey.text);
}

/// `LegendOptions` (`index.d.ts`): the options of the legend plugin
/// (`plugin.legend.js:636-712`).
extension type const LegendOptions(Object? object) {
  /// `align`.
  Object? get align => optionOf(object, OptionKey.align);

  /// `display`.
  Object? get display => optionOf(object, OptionKey.display);

  /// `labels`.
  LegendLabelOptions get labels =>
      LegendLabelOptions(optionOf(object, OptionKey.labels));

  /// `labels`, the raw value: a falsy value stays itself
  /// (`plugin.legend.js:105`).
  Object? get labelsValue => optionOf(object, OptionKey.labels);

  /// `maxHeight`.
  Object? get maxHeight => optionOf(object, OptionKey.maxHeight);

  /// `maxWidth`.
  Object? get maxWidth => optionOf(object, OptionKey.maxWidth);

  /// `onClick`.
  Object? get onClick => optionOf(object, OptionKey.onClick);

  /// `onHover`.
  Object? get onHover => optionOf(object, OptionKey.onHover);

  /// `onLeave`.
  Object? get onLeave => optionOf(object, OptionKey.onLeave);

  /// `position`.
  Object? get position => optionOf(object, OptionKey.position);

  /// `reverse`.
  Object? get reverse => optionOf(object, OptionKey.reverse);

  /// `rtl`.
  Object? get rtl => optionOf(object, OptionKey.rtl);

  /// `textDirection`.
  Object? get textDirection => optionOf(object, OptionKey.textDirection);

  /// `title`.
  LegendTitleOptions get title =>
      LegendTitleOptions(optionOf(object, OptionKey.title));
}

/// The `labels` of `LegendOptions` (`index.d.ts`, an inline type): the
/// label options of the legend (`plugin.legend.js:664-705`).
extension type const LegendLabelOptions(Object? object) {
  /// `borderRadius`.
  Object? get borderRadius => optionOf(object, OptionKey.borderRadius);

  /// `boxHeight`.
  Object? get boxHeight => optionOf(object, OptionKey.boxHeight);

  /// `boxWidth`.
  Object? get boxWidth => optionOf(object, OptionKey.boxWidth);

  /// `color`.
  Object? get color => optionOf(object, OptionKey.color);

  /// `filter`.
  Object? get filter => optionOf(object, OptionKey.filter);

  /// `font`.
  Object? get font => optionOf(object, OptionKey.font);

  /// `generateLabels`.
  Object? get generateLabels => optionOf(object, OptionKey.generateLabels);

  /// `padding`.
  Object? get padding => optionOf(object, OptionKey.padding);

  /// `pointStyle`.
  Object? get pointStyle => optionOf(object, OptionKey.pointStyle);

  /// `pointStyleWidth`.
  Object? get pointStyleWidth => optionOf(object, OptionKey.pointStyleWidth);

  /// `sort`.
  Object? get sort => optionOf(object, OptionKey.sort);

  /// `textAlign`.
  Object? get textAlign => optionOf(object, OptionKey.textAlign);

  /// `useBorderRadius`.
  Object? get useBorderRadius => optionOf(object, OptionKey.useBorderRadius);

  /// `usePointStyle`.
  Object? get usePointStyle => optionOf(object, OptionKey.usePointStyle);
}

/// The `title` of `LegendOptions` (`index.d.ts`, an inline type): the title
/// options of the legend (`plugin.legend.js:706-711`).
extension type const LegendTitleOptions(Object? object) {
  /// `color`.
  Object? get color => optionOf(object, OptionKey.color);

  /// `display`.
  Object? get display => optionOf(object, OptionKey.display);

  /// `font`.
  Object? get font => optionOf(object, OptionKey.font);

  /// `padding`.
  Object? get padding => optionOf(object, OptionKey.padding);

  /// `position`.
  Object? get position => optionOf(object, OptionKey.position);

  /// `text`.
  Object? get text => optionOf(object, OptionKey.text);
}

/// `TooltipOptions` (`index.d.ts`): the options of the tooltip plugin
/// (`plugin.tooltip.js:1275-1325`), with the keys of the `interaction`
/// scope that the tooltip reads (`mode`, `reverse`).
extension type const TooltipOptions(Object? object) {
  /// `animations`.
  Object? get animations => optionOf(object, OptionKey.animations);

  /// `backgroundColor`.
  Object? get backgroundColor => optionOf(object, OptionKey.backgroundColor);

  /// `bodyAlign`.
  Object? get bodyAlign => optionOf(object, OptionKey.bodyAlign);

  /// `bodyColor`.
  Object? get bodyColor => optionOf(object, OptionKey.bodyColor);

  /// `bodyFont`.
  Object? get bodyFont => optionOf(object, OptionKey.bodyFont);

  /// `bodySpacing`.
  Object? get bodySpacing => optionOf(object, OptionKey.bodySpacing);

  /// `borderColor`.
  Object? get borderColor => optionOf(object, OptionKey.borderColor);

  /// `borderWidth`.
  Object? get borderWidth => optionOf(object, OptionKey.borderWidth);

  /// `boxHeight`.
  Object? get boxHeight => optionOf(object, OptionKey.boxHeight);

  /// `boxPadding`.
  Object? get boxPadding => optionOf(object, OptionKey.boxPadding);

  /// `boxWidth`.
  Object? get boxWidth => optionOf(object, OptionKey.boxWidth);

  /// `callbacks`.
  Object? get callbacks => optionOf(object, OptionKey.callbacks);

  /// `caretPadding`.
  Object? get caretPadding => optionOf(object, OptionKey.caretPadding);

  /// `caretSize`.
  Object? get caretSize => optionOf(object, OptionKey.caretSize);

  /// `cornerRadius`.
  Object? get cornerRadius => optionOf(object, OptionKey.cornerRadius);

  /// `displayColors`.
  Object? get displayColors => optionOf(object, OptionKey.displayColors);

  /// `enabled`.
  Object? get enabled => optionOf(object, OptionKey.enabled);

  /// `external`.
  Object? get external => optionOf(object, OptionKey.external);

  /// `filter`.
  Object? get filter => optionOf(object, OptionKey.filter);

  /// `footerAlign`.
  Object? get footerAlign => optionOf(object, OptionKey.footerAlign);

  /// `footerColor`.
  Object? get footerColor => optionOf(object, OptionKey.footerColor);

  /// `footerFont`.
  Object? get footerFont => optionOf(object, OptionKey.footerFont);

  /// `footerMarginTop`.
  Object? get footerMarginTop => optionOf(object, OptionKey.footerMarginTop);

  /// `footerSpacing`.
  Object? get footerSpacing => optionOf(object, OptionKey.footerSpacing);

  /// `itemSort`.
  Object? get itemSort => optionOf(object, OptionKey.itemSort);

  /// `mode`.
  Object? get mode => optionOf(object, OptionKey.mode);

  /// `multiKeyBackground`.
  Object? get multiKeyBackground =>
      optionOf(object, OptionKey.multiKeyBackground);

  /// `padding`.
  Object? get padding => optionOf(object, OptionKey.padding);

  /// `position`.
  Object? get position => optionOf(object, OptionKey.position);

  /// `reverse`.
  Object? get reverse => optionOf(object, OptionKey.reverse);

  /// `rtl`.
  Object? get rtl => optionOf(object, OptionKey.rtl);

  /// `textDirection`.
  Object? get textDirection => optionOf(object, OptionKey.textDirection);

  /// `titleAlign`.
  Object? get titleAlign => optionOf(object, OptionKey.titleAlign);

  /// `titleColor`.
  Object? get titleColor => optionOf(object, OptionKey.titleColor);

  /// `titleFont`.
  Object? get titleFont => optionOf(object, OptionKey.titleFont);

  /// `titleMarginBottom`.
  Object? get titleMarginBottom =>
      optionOf(object, OptionKey.titleMarginBottom);

  /// `titleSpacing`.
  Object? get titleSpacing => optionOf(object, OptionKey.titleSpacing);

  /// `usePointStyle`.
  Object? get usePointStyle => optionOf(object, OptionKey.usePointStyle);

  /// `xAlign`.
  Object? get xAlign => optionOf(object, OptionKey.xAlign);

  /// `yAlign`.
  Object? get yAlign => optionOf(object, OptionKey.yAlign);
}

/// `FillerOptions` (`index.d.ts`): the options of the filler plugin
/// (`plugin.filler/index.js:146-149`).
extension type const FillerOptions(Object? object) {
  /// `drawTime`.
  Object? get drawTime => optionOf(object, OptionKey.drawTime);

  /// `propagate`.
  Object? get propagate => optionOf(object, OptionKey.propagate);
}

/// The fill option object `{target, above, below}` or `{value}` of a line
/// (`index.d.ts` `ComplexFillTarget` and `FillTarget`, inline types): a
/// resolver of the line options, or the raw value.
extension type const FillTargetOptions(Object? object) {
  /// `above`.
  Object? get above => optionOf(object, OptionKey.above);

  /// `below`.
  Object? get below => optionOf(object, OptionKey.below);

  /// `target`.
  Object? get target => optionOf(object, OptionKey.target);

  /// `value`.
  Object? get value => optionOf(object, OptionKey.value);
}

/// `DecimationOptions` (`index.d.ts`): the options of the decimation plugin
/// (`plugin.decimation.js:200-203`).
extension type const DecimationOptions(Object? object) {
  /// `algorithm`.
  Object? get algorithm => optionOf(object, OptionKey.algorithm);

  /// `enabled`.
  Object? get enabled => optionOf(object, OptionKey.enabled);

  /// `samples`.
  Object? get samples => optionOf(object, OptionKey.samples);

  /// `threshold`.
  Object? get threshold => optionOf(object, OptionKey.threshold);
}

/// `ColorsPluginOptions` (`plugin.colors.ts:4-7`): the options of the colors
/// plugin.
extension type const ColorsPluginOptions(Object? object) {
  /// `enabled`.
  Object? get enabled => optionOf(object, OptionKey.enabled);

  /// `forceOverride`.
  Object? get forceOverride => optionOf(object, OptionKey.forceOverride);
}
