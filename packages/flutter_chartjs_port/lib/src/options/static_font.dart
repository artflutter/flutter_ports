// Original code, not ported from Chart.js: reusable scalar font inputs.

/// Font inputs already cached by a resolver, with no scriptable, indexed or
/// foreign values. Positive numbers exclude signed-zero identity differences.
typedef StaticFontInputs = ({
  double size,
  String family,
  String style,
  Object lineHeight,
  String? weight,
});

/// The ordinary scalar subset with no conversions, callbacks or warnings that
/// can have side effects. Other inputs retain the full toFont path.
StaticFontInputs? staticFontInputs(
  Object? size,
  Object? family,
  Object? style,
  Object? lineHeight,
  Object? weight,
) {
  if (size is! double || !size.isFinite || size <= 0 || family is! String) {
    return null;
  }
  if (style is! String ||
      !(style == 'normal' ||
          style == 'italic' ||
          style == 'initial' ||
          style == 'inherit' ||
          style == 'unset' ||
          style == 'oblique') ||
      !(lineHeight is String ||
          (lineHeight is double && lineHeight.isFinite && lineHeight > 0)) ||
      !(weight == null || weight is String)) {
    return null;
  }
  return (
    size: size,
    family: family,
    style: style,
    lineHeight: lineHeight!,
    weight: weight as String?,
  );
}
