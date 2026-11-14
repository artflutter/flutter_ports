// Original code, not ported from Chart.js: the lengths in a data compare.

/// The lengths of the tests (row `adapt-length-objects`).
///
/// The options `cutout` and `radius` of a doughnut hold a `RadiusLength`,
/// and the scale option `grace` a `GraceLength`. Upstream data hold a number
/// or a percent text in that place. Thus a test does not compare the value
/// with upstream JSON text: both sides get [lengthMarker], and [lengthJson]
/// is the JSON text of a length.
library;

/// The text that stands for a length on both sides of a compare with
/// upstream JSON text.
const String lengthMarker = '<length>';

/// The JSON text of a length: [lengthMarker] as a JSON string.
const String lengthJson = '"$lengthMarker"';
