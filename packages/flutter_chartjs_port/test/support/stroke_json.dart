// Original code, not ported from Chart.js: the stroke enums of the tests.

/// The line cap and the line join of the tests (row
/// `adapt-flutter-stroke-enums`).
///
/// The options `borderCapStyle` and `borderJoinStyle` hold the Flutter enums
/// `StrokeCap` and `StrokeJoin`. Upstream data hold a keyword in that place.
/// The names of the enum values are the keywords, so a test compares the
/// name of the value with the upstream text: [strokeJson] gives it as JSON.
library;

import 'dart:ui' show StrokeCap, StrokeJoin;

/// Whether [value] is a line cap or a line join.
bool isStroke(Object? value) => value is StrokeCap || value is StrokeJoin;

/// The JSON text of the line cap or the line join [stroke]: the upstream
/// keyword, the name of the enum value, as a JSON string.
String strokeJson(Object stroke) => '"${(stroke as Enum).name}"';
