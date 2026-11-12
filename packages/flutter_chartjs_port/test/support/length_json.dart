// Original code, not ported from Chart.js: the lengths in a data compare.

/// The lengths of the tests (row `adapt-length-objects`).
///
/// The options `cutout` and `radius` of a doughnut hold a `RadiusLength`,
/// and the scale option `grace` a `GraceLength`. Upstream data hold a number
/// or a percent text in that place. Thus a test does not compare the value
/// with upstream JSON text: both sides get [lengthMarker].
/// - [lengthJson] is the JSON text of a length.
/// - [withLengthMarkers] changes the upstream JSON text.
library;

/// The text that stands for a length on both sides of a compare with
/// upstream JSON text.
const String lengthMarker = '<length>';

/// The JSON text of a length: [lengthMarker] as a JSON string.
const String lengthJson = '"$lengthMarker"';

/// A member `"cutout"` or `"grace"` with a number or a percent text, or a
/// member `"radius"` with a percent text (a number `radius` is the radius
/// of a point).
final RegExp _lengthMember = RegExp(
  '"(cutout|grace)":(?:"-?[0-9.]+%"|-?[0-9.]+(?:e[+-]?[0-9]+)?)|'
  '"(radius)":"-?[0-9.]+%"',
);

/// The upstream JSON text [json] with [lengthMarker] as each length.
String withLengthMarkers(String json) => json.replaceAllMapped(
  _lengthMember,
  (m) => '"${m[1] ?? m[2]}":$lengthJson',
);
