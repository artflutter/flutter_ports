// Original code, not ported from Chart.js: the chart.js/helpers entry of the package.
/// The `chart.js/helpers` entry: the helpers of `src/helpers/index.ts`, for
/// code that extends Chart.js (Chart.js ADR 0048, section 5).
///
/// The library mirrors the code entry `./helpers` of the `package.json` of
/// Chart.js. An upper case constant of upstream has a lowerCamelCase name:
/// `PI` is `pi`, and `HALF_PI` is `halfPi` (Chart.js ADR 0012). The Dart
/// names of the upstream `_` exports, for example `angleDiff` of
/// `_angleDiff`, stay internal (Chart.js ADR 0048, section 6).
///
/// The typed resolver classes of Chart.js ADR 0054 keep their names of
/// today, `Resolver` and `ContextResolver`; their class names
/// `OptionResolver` and `OptionView` stay internal. The typed context
/// classes (`ScriptableContext` and the others) stay internal too: a
/// context is a `ContextObject`. So does `SegmentStyle`, the typed style
/// of a line segment.
///
/// Next to `package:flutter_chartjs_port/chartjs.dart`, import it with a
/// prefix, as `src/index.umd.ts` keeps the helpers in `Chart.helpers`.
library;

import 'package:flutter_chartjs_port/src/canvas/canvas_colors.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.color.dart' as colors;

export 'package:flutter_chartjs_port/src/helpers/index.dart'
    hide
        OptionResolver,
        OptionView,
        ScriptableChartContext,
        ScriptableContext,
        ScriptableLineSegmentContext,
        ScriptableScaleContext,
        ScriptableScalePointLabelContext,
        ScriptableTooltipContext,
        SegmentStyle,
        addGrace,
        alignPixel,
        alignStartEnd,
        angleBetween,
        angleDiff,
        arrayUnique,
        attachContext,
        bezierCurveTo,
        bezierInterpolation,
        boundSegment,
        boundSegments,
        capitalize,
        color,
        computeSegments,
        createBoundarySegment,
        createResolver,
        decimalPlaces,
        deprecated,
        descriptors,
        elementsEqual,
        factorize,
        filterBetween,
        getHoverColor,
        getParentNode,
        getStartAndCountOfVisiblePoints,
        int16Range,
        isBetween,
        isClickEvent,
        isDomSupported,
        isPointInArea,
        limitValue,
        longestText,
        lookup,
        lookupByKey,
        measureText,
        merger,
        mergerIf,
        nativeSegmentType,
        normalizeAngle,
        parseObjectDataRadialScale,
        parseObjectDataRadialScaleOf,
        pointInLine,
        readOption,
        readValueToProps,
        rlookupByKey,
        scaleRangesChanged,
        setMinAndMaxByKey,
        splitKey,
        steppedInterpolation,
        steppedLineTo,
        textX,
        toLeftRightCenter,
        updateBezierControlPoints;

/// The color helper accepts Flutter Color, never CSS strings.
Object color(Object? value) {
  installNativeColorCodec();
  return colors.color(value);
}

/// Computes a native hover color without formatting or parsing strings.
Object? getHoverColor(Object? value) {
  installNativeColorCodec();
  return colors.getHoverColor(value);
}
