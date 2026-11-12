// Original code, not ported from Chart.js: the keyword enums of the tests.

/// The options whose upstream keyword is the name of a Dart enum value (rows
/// `adapt-flutter-stroke-enums`, `adapt-interaction-axis-enum` and
/// `adapt-scale-option-enums`).
///
/// The options `borderCapStyle` and `borderJoinStyle` hold the Flutter enums
/// `StrokeCap` and `StrokeJoin`, the interaction option `axis` holds an
/// `InteractionAxis`, and the scale options `bounds`, `ticks.source`,
/// `ticks.align` and `ticks.crossAlign` hold the enums of
/// `scale_option_enums.dart`, and the `align` of a box holds a `ChartAlign`
/// (row `adapt-chart-align-enum`), and the `xAlign` and `yAlign` of the
/// tooltip hold a `TooltipXAlign` and a `TooltipYAlign` (row
/// `adapt-tooltip-align-enums`), and the `borderAlign` and `spacingMode` of
/// an arc hold an `ArcBorderAlign` and an `ArcSpacingMode` (row
/// `adapt-arc-option-enums`). Upstream data hold a keyword in that place.
/// The names of the enum values are the keywords, so a test compares the
/// name of the value with the upstream text: [keywordJson] gives it as JSON.
library;

import 'dart:ui' show StrokeCap, StrokeJoin, TextAlign;

import 'package:flutter_chartjs_port/src/core/core.adapters.dart' show TimeUnit;
import 'package:flutter_chartjs_port/src/core/core.interaction.dart'
    show InteractionAxis;
import 'package:flutter_chartjs_port/src/core/scale_option_enums.dart'
    show ScaleBounds, TickAlign, TickCrossAlign, TickSource;
import 'package:flutter_chartjs_port/src/plugins/fill_target.dart'
    show FillBoundary;
import 'package:flutter_chartjs_port/src/plugins/filler_draw_time.dart'
    show FillerDrawTime;
import 'package:flutter_chartjs_port/src/types/align.dart'
    show ChartAlign, TooltipXAlign, TooltipYAlign;
import 'package:flutter_chartjs_port/src/types/arc_option_enums.dart'
    show ArcBorderAlign, ArcSpacingMode;
import 'package:flutter_chartjs_port/src/types/bar_option_enums.dart'
    show BorderSkippedEdge;
import 'package:flutter_chartjs_port/src/types/layout.dart' show ChartPosition;
import 'package:flutter_chartjs_port/src/types/line_option_enums.dart'
    show SteppedLine;

/// Whether [value] is a value of an enum whose names are upstream keywords.
bool isKeywordEnum(Object? value) =>
    value is StrokeCap ||
    value is StrokeJoin ||
    value is InteractionAxis ||
    value is ScaleBounds ||
    value is TickSource ||
    value is TickAlign ||
    value is TickCrossAlign ||
    value is ChartAlign ||
    value is TooltipXAlign ||
    value is TooltipYAlign ||
    value is ArcBorderAlign ||
    value is ArcSpacingMode ||
    value is FillerDrawTime ||
    value is TextAlign ||
    value is SteppedLine ||
    value is BorderSkippedEdge ||
    value is FillBoundary ||
    value is TimeUnit ||
    value is ChartPosition;

/// The JSON text of the enum value [value]: the upstream keyword, the name
/// of the value, as a JSON string.
String keywordJson(Object value) => '"${(value as Enum).name}"';
