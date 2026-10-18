// Ported from Chart.js v4.5.1 src/helpers/helpers.canvas.ts (MIT, Chart.js Contributors).

/// Partial port of `src/helpers/helpers.canvas.ts`: `toFontString` and
/// `_isPointInArea`.
///
/// `helpers.options` and `helpers.curve` import these two functions in phase
/// 2 (porting-flow.md 2.2 and section 5). The other functions take a
/// `CanvasRenderingContext2D`, a canvas or a chart. The canvas layer of phase
/// 3 ports them. This file stays a pure layer: it reaches neither `dart:ui`
/// nor `package:flutter`.
library;

import 'package:flutter_chartjs/src/helpers/helpers.core.dart'
    show isNullOrUndef;
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/types/index.dart';

/// helpers.canvas.ts:25 `toFontString`.
///
/// Converts the given font object into a CSS font string.
/// @param font - A font object.
/// @return The CSS font string. See https://developer.mozilla.org/en-US/docs/Web/CSS/font
/// @private
///
/// A null [font] stands for a falsy JavaScript value: `null` or `undefined`.
/// `font.weight` and `font.size` become strings through `ToString`
/// ([jsToString], [jsNumberToString]), so `12` gives `'12px'`, not `'12.0px'`.
String? toFontString(FontSpec? font) {
  if (font == null || isNullOrUndef(font.size) || isNullOrUndef(font.family)) {
    return null;
  }

  return '${jsTruthy(font.style) ? '${font.style} ' : ''}'
      '${jsTruthy(font.weight) ? '${jsToString(font.weight)} ' : ''}'
      '${jsNumberToString(font.size!)}px '
      '${font.family}';
}

/// helpers.canvas.ts:317 `_isPointInArea`.
///
/// Returns true if the point is inside the rectangle
/// @param point - The point to test
/// @param area - The rectangle
/// @param margin - allowed margin
/// @private
///
/// A null [point] or [area] stands for a falsy JavaScript value: `null` or
/// `undefined`. A null [margin] stands for `undefined`. A null `point.x` or
/// `point.y` is JS `null`, which the relational operators make 0: the port
/// writes `point.x ?? 0` (Chart.js ADR 0010).
///
/// Upstream returns `point` itself when `point` is falsy and [area] is not.
/// Here the result is `false` (`adapt-point-in-area-bool`, differences.md).
/// Every caller reads the result as a boolean (`core.controller.js:817`,
/// `core.interaction.js:122`, `scale.radialLinear.js:171-172`,
/// `element.point.ts:92`, `helpers.curve.ts:163-167`), and `ToBoolean` of a
/// falsy value is `false`.
bool isPointInArea(Point? point, TRBL? area, [double? margin]) {
  // Upstream reassigns its parameter.
  // ignore: parameter_assignments
  margin = jsTruthy(margin)
      ? margin!
      : 0.5; // margin - default is to match rounded decimals

  return area == null ||
      // DIVERGES(chartjs): adapt-point-in-area-bool, false for a falsy point.
      (point != null &&
          (point.x ?? 0) > area.left - margin &&
          (point.x ?? 0) < area.right + margin &&
          (point.y ?? 0) > area.top - margin &&
          (point.y ?? 0) < area.bottom + margin);
}
