// Original code, not ported from Chart.js: the option groups of the typed API.

/// The option groups of the typed API (Chart.js ADR 0052, sections 1 and
/// 6): the plugins [ChartLegend], [ChartTitle], [ChartTooltip] and
/// [ChartFiller], and the options [ChartInteraction] and [ChartAnimation]
/// of `ChartConfig`.
///
/// The callbacks of a group get one details object. The chart calls the
/// callback of the newest config: `==` of a group compares a callback only
/// by its presence, so a new closure in each build does not update the
/// chart.
library;

import 'dart:ui' show Color;

import 'package:flutter/foundation.dart'
    show DiagnosticPropertiesBuilder, Diagnosticable, ValueChanged, immutable;
import 'package:flutter/painting.dart' show EdgeInsets, TextStyle;
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart'
    show OptionKey;
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show
        AnimationOptionsScope,
        FillerOptionsScope,
        InteractionOptionsScope,
        LegendLabelOptionsScope,
        LegendOptionsScope,
        TitleOptionsScope,
        TooltipCallbacksScope,
        TooltipOptionsScope;
import 'package:flutter_chartjs_port/src/theme/css.dart' show fontScopeOf;
import 'package:flutter_chartjs_port/src/typed/callbacks.dart'
    show ChartAnimationDetails, ChartLegendEventDetails, ChartTooltipItem;
import 'package:flutter_chartjs_port/src/typed/lower.dart';
import 'package:flutter_chartjs_port/src/typed/props.dart';
import 'package:flutter_chartjs_port/src/typed/values.dart'
    show ChartAlign, ChartEasing, ChartInteractionMode, ChartPosition;
import 'package:meta/meta.dart' show internal;

/// The legend: the options of the legend plugin, `options.plugins.legend`
/// (`docs/configuration/legend.md`).
///
/// The legend shows an item for each dataset, or for each data item of a
/// pie, a doughnut and a polar area chart. A click on an item hides or
/// shows its data. An [onClick] replaces that default toggle, as in
/// Chart.js.
@immutable
final class ChartLegend with Diagnosticable {
  /// The legend options.
  const ChartLegend({
    this.display,
    this.position,
    this.align,
    this.reverse,
    this.labelColor,
    this.labelFont,
    this.boxWidth,
    this.boxHeight,
    this.labelPadding,
    this.usePointStyle,
    this.onClick,
    this.onHover,
    this.onLeave,
    this.extra,
  });

  /// Whether the chart shows the legend: `display`. The default is `true`.
  final bool? display;

  /// The side of the chart of the legend: `position`. The default is
  /// [ChartPosition.top]. [ChartPosition.chartArea] puts the legend in the
  /// chart area.
  final ChartPosition? position;

  /// The alignment of the legend along its side: `align`.
  final ChartAlign? align;

  /// Whether the items come in the reverse order: `reverse`.
  final bool? reverse;

  /// The color of the item text: `labels.color`.
  final Color? labelColor;

  /// The font of the item text: `labels.font`. The color of the font is
  /// not read: set [labelColor].
  final TextStyle? labelFont;

  /// The width of the color box of an item, in pixels: `labels.boxWidth`.
  /// The default is 40.
  final double? boxWidth;

  /// The height of the color box of an item, in pixels:
  /// `labels.boxHeight`. The default is the font size.
  final double? boxHeight;

  /// The space between the items, in pixels: `labels.padding`. The default
  /// is 10.
  final double? labelPadding;

  /// Whether the item shows the point style of its data in place of the
  /// color box: `labels.usePointStyle`.
  final bool? usePointStyle;

  /// The function of a click on an item: `onClick`. It replaces the
  /// default toggle of the visibility.
  final ValueChanged<ChartLegendEventDetails>? onClick;

  /// The function of a pointer that moves onto an item: `onHover`.
  final ValueChanged<ChartLegendEventDetails>? onHover;

  /// The function of a pointer that leaves an item: `onLeave`.
  final ValueChanged<ChartLegendEventDetails>? onLeave;

  /// The Chart.js legend options that have no parameter, for example
  /// `{'title': {'display': true, 'text': 'Votes'}}`.
  ///
  /// The entries go into the legend Map last: an entry wins over a
  /// parameter with the same key. A Map value merges into the Map of the
  /// key, a List or another value replaces it. The chart gets a copy of
  /// each Map and the Lists of the app.
  final Map<String, Object?>? extra;

  /// A copy of these legend options with the given parameters. A
  /// parameter that is `null` keeps its value.
  ChartLegend copyWith({
    bool? display,
    ChartPosition? position,
    ChartAlign? align,
    bool? reverse,
    Color? labelColor,
    TextStyle? labelFont,
    double? boxWidth,
    double? boxHeight,
    double? labelPadding,
    bool? usePointStyle,
    ValueChanged<ChartLegendEventDetails>? onClick,
    ValueChanged<ChartLegendEventDetails>? onHover,
    ValueChanged<ChartLegendEventDetails>? onLeave,
    Map<String, Object?>? extra,
  }) => ChartLegend(
    display: display ?? this.display,
    position: position ?? this.position,
    align: align ?? this.align,
    reverse: reverse ?? this.reverse,
    labelColor: labelColor ?? this.labelColor,
    labelFont: labelFont ?? this.labelFont,
    boxWidth: boxWidth ?? this.boxWidth,
    boxHeight: boxHeight ?? this.boxHeight,
    labelPadding: labelPadding ?? this.labelPadding,
    usePointStyle: usePointStyle ?? this.usePointStyle,
    onClick: onClick ?? this.onClick,
    onHover: onHover ?? this.onHover,
    onLeave: onLeave ?? this.onLeave,
    extra: extra ?? this.extra,
  );

  List<TypedProperty> get _props => [
    ('display', display),
    ('position', position),
    ('align', align),
    ('reverse', reverse),
    ('labelColor', labelColor),
    ('labelFont', labelFont),
    ('boxWidth', boxWidth),
    ('boxHeight', boxHeight),
    ('labelPadding', labelPadding),
    ('usePointStyle', usePointStyle),
    ('onClick', byPresence(onClick)),
    ('onHover', byPresence(onHover)),
    ('onLeave', byPresence(onLeave)),
    ('extra', byEntries(extra)),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartLegend && propsEqual(_props, other._props);

  @override
  int get hashCode => propsHash(_props);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    addProps(properties, _props);
  }
}

/// The `legend` scope of [legend] (Chart.js ADR 0052, section 2; Chart.js
/// ADR 0054 §7). The handlers lower to trampolines that call the handler of
/// the newest config of [lowering].
@internal
LegendOptionsScope lowerLegend(
  ChartLegend legend,
  ChartConfigLowering lowering,
) {
  final labels = LegendLabelOptionsScope();
  put(labels, OptionKey.color, colorValue(legend.labelColor));
  put(labels, OptionKey.font, fontScopeOf(legend.labelFont));
  put(labels, OptionKey.boxWidth, legend.boxWidth);
  put(labels, OptionKey.boxHeight, legend.boxHeight);
  put(labels, OptionKey.padding, legend.labelPadding);
  put(labels, OptionKey.usePointStyle, legend.usePointStyle);
  final scope = LegendOptionsScope();
  put(scope, OptionKey.display, legend.display);
  put(scope, OptionKey.position, legend.position?.name);
  put(scope, OptionKey.align, legend.align?.name);
  put(scope, OptionKey.reverse, legend.reverse);
  if (labels.ownKeyCount != 0) scope.labels = labels;
  if (legend.onClick != null) {
    scope.onClick = legendTrampoline(() => lowering.config.legend?.onClick);
  }
  if (legend.onHover != null) {
    scope.onHover = legendTrampoline(() => lowering.config.legend?.onHover);
  }
  if (legend.onLeave != null) {
    scope.onLeave = legendTrampoline(() => lowering.config.legend?.onLeave);
  }
  return mergeExtra(scope, legend.extra);
}

/// A title or a subtitle: the options of the title plugin,
/// `options.plugins.title`, or of the subtitle plugin,
/// `options.plugins.subtitle` (`docs/configuration/title.md`,
/// `docs/configuration/subtitle.md`).
@immutable
final class ChartTitle with Diagnosticable {
  /// The title options.
  const ChartTitle({
    this.display,
    this.text,
    this.color,
    this.font,
    this.align,
    this.position,
    this.padding,
    this.fullSize,
    this.extra,
  });

  /// Whether the chart shows the title: `display`. The default is `false`.
  /// Set it to `true` to show the [text].
  final bool? display;

  /// The text of the title: `text`. The lines of a title with more lines
  /// go through [extra] as a List.
  final String? text;

  /// The color of the text: `color`.
  final Color? color;

  /// The font of the text: `font`. The color of the font is not read: set
  /// [color].
  final TextStyle? font;

  /// The alignment of the title along its side: `align`.
  final ChartAlign? align;

  /// The side of the chart of the title: `position`. The title takes
  /// [ChartPosition.top], [ChartPosition.left], [ChartPosition.bottom] and
  /// [ChartPosition.right]. The default is the top.
  final ChartPosition? position;

  /// The space around the title: `padding`. Chart.js reads the top and the
  /// bottom.
  final EdgeInsets? padding;

  /// Whether the box of the title takes the full width or height of the
  /// chart: `fullSize`. The default is `true`.
  final bool? fullSize;

  /// The Chart.js title options that have no parameter. The rules of
  /// [ChartLegend.extra] apply.
  final Map<String, Object?>? extra;

  /// A copy of these title options with the given parameters. A parameter
  /// that is `null` keeps its value.
  ChartTitle copyWith({
    bool? display,
    String? text,
    Color? color,
    TextStyle? font,
    ChartAlign? align,
    ChartPosition? position,
    EdgeInsets? padding,
    bool? fullSize,
    Map<String, Object?>? extra,
  }) => ChartTitle(
    display: display ?? this.display,
    text: text ?? this.text,
    color: color ?? this.color,
    font: font ?? this.font,
    align: align ?? this.align,
    position: position ?? this.position,
    padding: padding ?? this.padding,
    fullSize: fullSize ?? this.fullSize,
    extra: extra ?? this.extra,
  );

  List<TypedProperty> get _props => [
    ('display', display),
    ('text', text),
    ('color', color),
    ('font', font),
    ('align', align),
    ('position', position),
    ('padding', padding),
    ('fullSize', fullSize),
    ('extra', byEntries(extra)),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartTitle && propsEqual(_props, other._props);

  @override
  int get hashCode => propsHash(_props);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    addProps(properties, _props);
  }
}

/// The `title` or `subtitle` scope of [title].
@internal
TitleOptionsScope lowerTitle(ChartTitle title) {
  final scope = TitleOptionsScope();
  put(scope, OptionKey.display, title.display);
  put(scope, OptionKey.text, title.text);
  put(scope, OptionKey.color, colorValue(title.color));
  put(scope, OptionKey.font, fontScopeOf(title.font));
  put(scope, OptionKey.align, title.align?.name);
  put(scope, OptionKey.position, title.position?.name);
  put(scope, OptionKey.padding, paddingScope(title.padding));
  put(scope, OptionKey.fullSize, title.fullSize);
  return mergeExtra(scope, title.extra);
}

/// The tooltip: the options of the tooltip plugin,
/// `options.plugins.tooltip` (`docs/configuration/tooltip.md`).
///
/// The text callbacks give the text of the title, of a label line and of
/// the footer. Dart `null` gives the default text of Chart.js.
@immutable
final class ChartTooltip with Diagnosticable {
  /// The tooltip options.
  const ChartTooltip({
    this.enabled,
    this.mode,
    this.intersect,
    this.backgroundColor,
    this.titleColor,
    this.titleFont,
    this.bodyColor,
    this.bodyFont,
    this.footerColor,
    this.footerFont,
    this.padding,
    this.cornerRadius,
    this.displayColors,
    this.titleText,
    this.labelText,
    this.footerText,
    this.extra,
  });

  /// Whether the chart shows the tooltip: `enabled`. The default is
  /// `true`.
  final bool? enabled;

  /// The items of the tooltip: `mode`. The default is the mode of
  /// `ChartConfig.interaction`.
  final ChartInteractionMode? mode;

  /// Whether the tooltip shows only when the pointer is on an item:
  /// `intersect`. The default is the value of `ChartConfig.interaction`.
  final bool? intersect;

  /// The color of the tooltip box: `backgroundColor`.
  final Color? backgroundColor;

  /// The color of the title text: `titleColor`.
  final Color? titleColor;

  /// The font of the title text: `titleFont`. The color of the font is not
  /// read: set [titleColor].
  final TextStyle? titleFont;

  /// The color of the label text: `bodyColor`.
  final Color? bodyColor;

  /// The font of the label text: `bodyFont`. The color of the font is not
  /// read: set [bodyColor].
  final TextStyle? bodyFont;

  /// The color of the footer text: `footerColor`.
  final Color? footerColor;

  /// The font of the footer text: `footerFont`. The color of the font is
  /// not read: set [footerColor].
  final TextStyle? footerFont;

  /// The space in the tooltip box around the text: `padding`.
  final EdgeInsets? padding;

  /// The radius of the corners of the tooltip box, in pixels:
  /// `cornerRadius`.
  final double? cornerRadius;

  /// Whether each label line shows the color box of its dataset:
  /// `displayColors`.
  final bool? displayColors;

  /// The title of the tooltip: `callbacks.title`. It gets the items of the
  /// tooltip. `null` gives the default title, the label of the first item.
  final String? Function(List<ChartTooltipItem> items)? titleText;

  /// The text of the label line of an item: `callbacks.label`. `null`
  /// gives the default text, the dataset label and the value
  /// (`docs/configuration/tooltip.md`, "Label Callback").
  final String? Function(ChartTooltipItem item)? labelText;

  /// The footer of the tooltip: `callbacks.footer`. It gets the items of
  /// the tooltip. `null` gives the default footer, no footer.
  final String? Function(List<ChartTooltipItem> items)? footerText;

  /// The Chart.js tooltip options that have no parameter, for example
  /// `{'position': 'nearest'}`. The rules of [ChartLegend.extra] apply.
  final Map<String, Object?>? extra;

  /// A copy of these tooltip options with the given parameters. A
  /// parameter that is `null` keeps its value.
  ChartTooltip copyWith({
    bool? enabled,
    ChartInteractionMode? mode,
    bool? intersect,
    Color? backgroundColor,
    Color? titleColor,
    TextStyle? titleFont,
    Color? bodyColor,
    TextStyle? bodyFont,
    Color? footerColor,
    TextStyle? footerFont,
    EdgeInsets? padding,
    double? cornerRadius,
    bool? displayColors,
    String? Function(List<ChartTooltipItem> items)? titleText,
    String? Function(ChartTooltipItem item)? labelText,
    String? Function(List<ChartTooltipItem> items)? footerText,
    Map<String, Object?>? extra,
  }) => ChartTooltip(
    enabled: enabled ?? this.enabled,
    mode: mode ?? this.mode,
    intersect: intersect ?? this.intersect,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    titleColor: titleColor ?? this.titleColor,
    titleFont: titleFont ?? this.titleFont,
    bodyColor: bodyColor ?? this.bodyColor,
    bodyFont: bodyFont ?? this.bodyFont,
    footerColor: footerColor ?? this.footerColor,
    footerFont: footerFont ?? this.footerFont,
    padding: padding ?? this.padding,
    cornerRadius: cornerRadius ?? this.cornerRadius,
    displayColors: displayColors ?? this.displayColors,
    titleText: titleText ?? this.titleText,
    labelText: labelText ?? this.labelText,
    footerText: footerText ?? this.footerText,
    extra: extra ?? this.extra,
  );

  List<TypedProperty> get _props => [
    ('enabled', enabled),
    ('mode', mode),
    ('intersect', intersect),
    ('backgroundColor', backgroundColor),
    ('titleColor', titleColor),
    ('titleFont', titleFont),
    ('bodyColor', bodyColor),
    ('bodyFont', bodyFont),
    ('footerColor', footerColor),
    ('footerFont', footerFont),
    ('padding', padding),
    ('cornerRadius', cornerRadius),
    ('displayColors', displayColors),
    ('titleText', byPresence(titleText)),
    ('labelText', byPresence(labelText)),
    ('footerText', byPresence(footerText)),
    ('extra', byEntries(extra)),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartTooltip && propsEqual(_props, other._props);

  @override
  int get hashCode => propsHash(_props);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    addProps(properties, _props);
  }
}

/// The `tooltip` scope of [tooltip]. The text callbacks lower to
/// trampolines that call the callback of the newest config of [lowering].
@internal
TooltipOptionsScope lowerTooltip(
  ChartTooltip tooltip,
  ChartConfigLowering lowering,
) {
  final callbacks = TooltipCallbacksScope();
  if (tooltip.titleText != null) {
    callbacks.title = tooltipItemsTrampoline(
      () => lowering.config.tooltip?.titleText,
    );
  }
  if (tooltip.labelText != null) {
    callbacks.label = tooltipItemTrampoline(
      () => lowering.config.tooltip?.labelText,
    );
  }
  if (tooltip.footerText != null) {
    callbacks.footer = tooltipItemsTrampoline(
      () => lowering.config.tooltip?.footerText,
    );
  }
  final scope = TooltipOptionsScope();
  put(scope, OptionKey.enabled, tooltip.enabled);
  put(scope, OptionKey.mode, tooltip.mode?.name);
  put(scope, OptionKey.intersect, tooltip.intersect);
  put(scope, OptionKey.backgroundColor, colorValue(tooltip.backgroundColor));
  put(scope, OptionKey.titleColor, colorValue(tooltip.titleColor));
  put(scope, OptionKey.titleFont, fontScopeOf(tooltip.titleFont));
  put(scope, OptionKey.bodyColor, colorValue(tooltip.bodyColor));
  put(scope, OptionKey.bodyFont, fontScopeOf(tooltip.bodyFont));
  put(scope, OptionKey.footerColor, colorValue(tooltip.footerColor));
  put(scope, OptionKey.footerFont, fontScopeOf(tooltip.footerFont));
  put(scope, OptionKey.padding, paddingScope(tooltip.padding));
  put(scope, OptionKey.cornerRadius, tooltip.cornerRadius);
  put(scope, OptionKey.displayColors, tooltip.displayColors);
  if (callbacks.ownKeyCount != 0) scope.callbacks = callbacks;
  return mergeExtra(scope, tooltip.extra);
}

/// The interaction: which elements an event hits, `options.interaction`
/// (`docs/configuration/interactions.md`).
///
/// The hover, the click callbacks and the tooltip read it.
@immutable
final class ChartInteraction with Diagnosticable {
  /// The interaction options.
  const ChartInteraction({
    this.mode,
    this.intersect,
    this.includeInvisible,
    this.extra,
  });

  /// The elements that an event hits: `mode`. The default is
  /// [ChartInteractionMode.nearest].
  final ChartInteractionMode? mode;

  /// Whether an event hits only the elements under the pointer:
  /// `intersect`. The default is `true`.
  final bool? intersect;

  /// Whether an event also hits the elements outside the chart area:
  /// `includeInvisible`. The default is `false`.
  final bool? includeInvisible;

  /// The Chart.js interaction options that have no parameter, for example
  /// `{'axis': 'x'}`. The rules of [ChartLegend.extra] apply.
  final Map<String, Object?>? extra;

  /// A copy of these interaction options with the given parameters. A
  /// parameter that is `null` keeps its value.
  ChartInteraction copyWith({
    ChartInteractionMode? mode,
    bool? intersect,
    bool? includeInvisible,
    Map<String, Object?>? extra,
  }) => ChartInteraction(
    mode: mode ?? this.mode,
    intersect: intersect ?? this.intersect,
    includeInvisible: includeInvisible ?? this.includeInvisible,
    extra: extra ?? this.extra,
  );

  List<TypedProperty> get _props => [
    ('mode', mode),
    ('intersect', intersect),
    ('includeInvisible', includeInvisible),
    ('extra', byEntries(extra)),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartInteraction && propsEqual(_props, other._props);

  @override
  int get hashCode => propsHash(_props);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    addProps(properties, _props);
  }
}

/// The `interaction` scope of [interaction].
@internal
InteractionOptionsScope lowerInteraction(ChartInteraction interaction) {
  final scope = InteractionOptionsScope();
  put(scope, OptionKey.mode, interaction.mode?.name);
  put(scope, OptionKey.intersect, interaction.intersect);
  put(scope, OptionKey.includeInvisible, interaction.includeInvisible);
  return mergeExtra(scope, interaction.extra);
}

/// The filler: the options of the filler plugin, `options.plugins.filler`
/// (`docs/charts/area.md`, "Configuration").
///
/// The filler plugin fills the area of a dataset with a `fill`, for
/// example `LineDataset.fill`.
@immutable
final class ChartFiller with Diagnosticable {
  /// The filler options.
  const ChartFiller({this.propagate, this.extra});

  /// Whether the fill of a dataset whose target dataset is hidden goes on
  /// to the next visible target: `propagate`. The default is `true`. With
  /// `false`, the dataset has no fill when its target is hidden.
  final bool? propagate;

  /// The Chart.js filler options that have no parameter, for example
  /// `{'drawTime': 'beforeDraw'}`. The rules of [ChartLegend.extra] apply.
  final Map<String, Object?>? extra;

  /// A copy of these filler options with the given parameters. A parameter
  /// that is `null` keeps its value.
  ChartFiller copyWith({bool? propagate, Map<String, Object?>? extra}) =>
      ChartFiller(
        propagate: propagate ?? this.propagate,
        extra: extra ?? this.extra,
      );

  List<TypedProperty> get _props => [
    ('propagate', propagate),
    ('extra', byEntries(extra)),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartFiller && propsEqual(_props, other._props);

  @override
  int get hashCode => propsHash(_props);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    addProps(properties, _props);
  }
}

/// The `filler` scope of [filler].
@internal
FillerOptionsScope lowerFiller(ChartFiller filler) {
  final scope = FillerOptionsScope();
  put(scope, OptionKey.propagate, filler.propagate);
  return mergeExtra(scope, filler.extra);
}

/// The animation of the chart: `options.animation`
/// (`docs/configuration/animations.md`).
///
/// [ChartAnimation.none] turns the animations off: `animation: false`.
@immutable
final class ChartAnimation with Diagnosticable {
  /// The animation options.
  const ChartAnimation({
    this.duration,
    this.delay,
    this.easing,
    this.loop,
    this.onProgress,
    this.onComplete,
    this.extra,
  }) : _none = false;

  const ChartAnimation._none()
    : duration = null,
      delay = null,
      easing = null,
      loop = null,
      onProgress = null,
      onComplete = null,
      extra = null,
      _none = true;

  /// No animation: `animation: false`. A change of the data then shows at
  /// once. Its copies are [none] too.
  static const ChartAnimation none = ChartAnimation._none();

  /// The length of the animations: `duration`. The default is 1000
  /// milliseconds.
  final Duration? duration;

  /// The wait before the animations start: `delay`.
  final Duration? delay;

  /// The easing function of the animations: `easing`. The default is
  /// [ChartEasing.easeOutQuart].
  final ChartEasing? easing;

  /// Whether the animations repeat without end: `loop`.
  final bool? loop;

  /// The function of each step of the animations: `onProgress`.
  final ValueChanged<ChartAnimationDetails>? onProgress;

  /// The function of the end of the animations: `onComplete`.
  final ValueChanged<ChartAnimationDetails>? onComplete;

  /// The Chart.js animation options that have no parameter. The rules of
  /// [ChartLegend.extra] apply.
  final Map<String, Object?>? extra;

  /// Whether this is [none].
  final bool _none;

  /// A copy of these animation options with the given parameters. A
  /// parameter that is `null` keeps its value. A copy of [none] is [none].
  ChartAnimation copyWith({
    Duration? duration,
    Duration? delay,
    ChartEasing? easing,
    bool? loop,
    ValueChanged<ChartAnimationDetails>? onProgress,
    ValueChanged<ChartAnimationDetails>? onComplete,
    Map<String, Object?>? extra,
  }) => _none
      ? none
      : ChartAnimation(
          duration: duration ?? this.duration,
          delay: delay ?? this.delay,
          easing: easing ?? this.easing,
          loop: loop ?? this.loop,
          onProgress: onProgress ?? this.onProgress,
          onComplete: onComplete ?? this.onComplete,
          extra: extra ?? this.extra,
        );

  List<TypedProperty> get _props => [
    if (_none) ('none', true),
    ('duration', duration),
    ('delay', delay),
    ('easing', easing),
    ('loop', loop),
    ('onProgress', byPresence(onProgress)),
    ('onComplete', byPresence(onComplete)),
    ('extra', byEntries(extra)),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartAnimation &&
          other._none == _none &&
          propsEqual(_props, other._props);

  @override
  int get hashCode => propsHash(_props);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    addProps(properties, _props);
  }
}

/// The `animation` option of [animation]: `false` for
/// [ChartAnimation.none], else an `AnimationOptionsScope`. The callbacks
/// lower to trampolines that call the callback of the newest config of
/// [lowering].
@internal
Object lowerAnimation(
  ChartAnimation animation,
  ChartConfigLowering lowering,
) {
  if (animation._none) return false;
  final scope = AnimationOptionsScope();
  put(scope, OptionKey.duration, millisecondsOf(animation.duration));
  put(scope, OptionKey.delay, millisecondsOf(animation.delay));
  put(scope, OptionKey.easing, animation.easing?.name);
  put(scope, OptionKey.loop, animation.loop);
  if (animation.onProgress != null) {
    scope.onProgress = animationTrampoline(
      () => lowering.config.animation?.onProgress,
    );
  }
  if (animation.onComplete != null) {
    scope.onComplete = animationTrampoline(
      () => lowering.config.animation?.onComplete,
    );
  }
  return mergeExtra(scope, animation.extra);
}
