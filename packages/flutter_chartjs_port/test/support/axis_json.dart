// Original code, not ported from Chart.js: the axis in a data compare.

/// The axis of the tests (row `adapt-axis-objects`).
///
/// The `indexAxis` and the `axis` of a scale hold an axis class (`XAxis`,
/// `YAxis`, `RAxis`), and the port has no axis letters. Upstream data hold
/// a letter in that place. Thus a test does not compare the axis with
/// upstream JSON text: both sides get [axisMarker].
/// - [axisJson] is the JSON text of an axis.
/// - [withAxisMarkers] changes the upstream JSON text.
library;

/// The text that stands for an axis on both sides of a compare with
/// upstream JSON text.
const String axisMarker = '<axis>';

/// The JSON text of an axis: [axisMarker] as a JSON string.
const String axisJson = '"$axisMarker"';

/// A member `"indexAxis"` or `"axis"` with an axis letter.
final RegExp _axisMember = RegExp('"(indexAxis|axis)":"[xyr]"');

/// The upstream JSON text [json] with [axisMarker] as each axis letter of
/// `indexAxis` and `axis`.
String withAxisMarkers(String json) =>
    json.replaceAllMapped(_axisMember, (m) => '"${m[1]}":$axisJson');
