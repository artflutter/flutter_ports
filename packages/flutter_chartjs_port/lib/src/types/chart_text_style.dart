// Original code, not ported from Chart.js: the font of a chart.

/// The font of a chart (Chart.js ADR 0116, row `adapt-text-style-fonts`).
///
/// Chart.js holds a font as a plain object `{family, size, style, weight,
/// lineHeight}`, builds a CSS font text from it and gives the text to the
/// canvas. In the port, a font is a [ChartTextStyle]: a Flutter `TextStyle`
/// with the line height in pixels. The option takes it, the resolver merges it
/// with [TextStyle.merge], the layout reads [ChartTextStyle.lineHeight] and the
/// canvas lays out the text with the style itself.
///
/// ```dart
/// ChartTitle(
///   display: true,
///   text: 'Sales',
///   font: ChartTextStyle(fontSize: 20, fontWeight: FontWeight.bold),
/// );
/// ```
///
/// This library is a pure layer.
library;

import 'dart:ui'
    show
        Color,
        FontFeature,
        FontStyle,
        FontVariation,
        FontWeight,
        Locale,
        Paint,
        Shadow,
        TextBaseline,
        TextDecoration,
        TextDecorationStyle,
        TextLeadingDistribution;

import 'package:flutter/painting.dart' show TextOverflow, TextStyle;
import 'package:meta/meta.dart' show immutable;

/// A font of a chart: a Flutter `TextStyle` with [lineHeight], the height of
/// one line of text in pixels.
///
/// [TextStyle.height] is the line height as a multiple of
/// [TextStyle.fontSize], the `lineHeight` of a Chart.js font. The constructor
/// computes [lineHeight] once from the two fields. [merge] and [copyWith] give
/// a new [ChartTextStyle], so [lineHeight] follows the merged size and height:
/// `ChartTextStyle(fontSize: 20)` merged over a font with `height: 1.2` has the
/// line height 24.
@immutable
class const ChartTextStyle({
  super.inherit,
  super.color,
  super.backgroundColor,
  super.fontSize,
  super.fontWeight,
  super.fontStyle,
  super.letterSpacing,
  super.wordSpacing,
  super.textBaseline,
  super.height,
  super.leadingDistribution,
  super.locale,
  super.foreground,
  super.background,
  super.shadows,
  super.fontFeatures,
  super.fontVariations,
  super.decoration,
  super.decorationColor,
  super.decorationStyle,
  super.decorationThickness,
  super.debugLabel,
  super.fontFamily,
  super.fontFamilyFallback,
  super.package,
  super.overflow,
}) extends TextStyle {
  /// A font. [lineHeight] is `fontSize * height`, or Dart `null` when one of
  /// the two is `null`.
  this
    // The initializer stays in the list: the analyzer of Dart 3.14 rejects
    // each const instance when a field initializer reads a super parameter
    // of a superclass from another library (the VM accepts it).
    // ignore: initialize_in_field_declaration
    : lineHeight = fontSize != null && height != null
          ? fontSize * height
          : null;

  /// The font of the fields of [style].
  new from(TextStyle style)
    : this(
        inherit: style.inherit,
        color: style.color,
        backgroundColor: style.backgroundColor,
        fontSize: style.fontSize,
        fontWeight: style.fontWeight,
        fontStyle: style.fontStyle,
        letterSpacing: style.letterSpacing,
        wordSpacing: style.wordSpacing,
        textBaseline: style.textBaseline,
        height: style.height,
        leadingDistribution: style.leadingDistribution,
        locale: style.locale,
        foreground: style.foreground,
        background: style.background,
        shadows: style.shadows,
        fontFeatures: style.fontFeatures,
        fontVariations: style.fontVariations,
        decoration: style.decoration,
        decorationColor: style.decorationColor,
        decorationStyle: style.decorationStyle,
        decorationThickness: style.decorationThickness,
        debugLabel: style.debugLabel,
        fontFamily: style.fontFamily,
        fontFamilyFallback: style.fontFamilyFallback,
        overflow: style.overflow,
      );

  /// The height of one line of text in pixels: `fontSize * height`, or Dart
  /// `null` when the font has no size or no height.
  final double? lineHeight;

  @override
  ChartTextStyle copyWith({
    bool? inherit,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    TextLeadingDistribution? leadingDistribution,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    List<FontVariation>? fontVariations,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    String? debugLabel,
    String? fontFamily,
    List<String>? fontFamilyFallback,
    String? package,
    TextOverflow? overflow,
  }) => ChartTextStyle.from(
    super.copyWith(
      inherit: inherit,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      leadingDistribution: leadingDistribution,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      fontVariations: fontVariations,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
      debugLabel: debugLabel,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      package: package,
      overflow: overflow,
    ),
  );

  /// The merge of [TextStyle.merge], as a [ChartTextStyle]: a field of
  /// [other] wins, and a null field of [other] keeps the field of this font.
  @override
  ChartTextStyle merge(TextStyle? other) {
    final merged = super.merge(other);
    return merged is ChartTextStyle ? merged : ChartTextStyle.from(merged);
  }
}
