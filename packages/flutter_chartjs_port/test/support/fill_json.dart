// Original code, not ported from Chart.js: the fill in a data compare.

/// The fill of the tests (row `adapt-fill-target-objects`, Chart.js ADR
/// 0140).
///
/// The option `fill` holds a `FillTarget`, and the port has no fill
/// keywords, numbers, booleans or objects. Upstream data hold one of them in
/// that place.
/// - A test does not compare the fill with upstream JSON text: both sides
///   get [fillMarker]. [fillJson] is the JSON text of a fill, and
///   [withFillMarkers] changes the upstream JSON text.
/// - The data fixtures of the moment skips (Chart.js ADR 0029, section 9)
///   run from `fixtures.json`, with no hand port: [nativeFixtureFalseFills]
///   gives each of their `fill: false` its `FillTarget.none`.
library;

import 'package:flutter_chartjs_port/src/plugins/fill_target.dart';

/// The text that stands for the value of `fill` on both sides of a compare
/// with upstream JSON text.
const String fillMarker = '<fill>';

/// The JSON text of a fill: [fillMarker] as a JSON string.
const String fillJson = '"$fillMarker"';

/// A member `"fill"` with an upstream value: a boolean, a number, a text or
/// an object without a nested object.
final RegExp _fillMember = RegExp(
  r'"fill":(?:true|false|-?[\d.]+|"[^"]*"|\{[^{}]*\})',
);

/// The upstream JSON text [json] with [fillMarker] as each value of `fill`.
String withFillMarkers(String json) =>
    json.replaceAll(_fillMember, '"fill":$fillJson');

/// Gives each `fill: false` in the Maps and Lists of the decoded fixture
/// [config] its `FillTarget.none`. Another value of `fill` throws a
/// [StateError]: a data fixture with such a value has a hand port (Chart.js
/// ADR 0115).
void nativeFixtureFalseFills(Object? config) {
  switch (config) {
    case final Map<String, Object?> map:
      for (final key in map.keys.toList()) {
        if (key == 'fill') {
          final value = map[key];
          if (value != false) {
            throw StateError(
              'The fill $value of a data fixture needs a hand '
              'port (Chart.js ADR 0115).',
            );
          }
          map[key] = FillTarget.none;
        } else {
          nativeFixtureFalseFills(map[key]);
        }
      }
    case final List<Object?> list:
      list.forEach(nativeFixtureFalseFills);
  }
}
