// Original code, not ported from Chart.js: the point style in a data compare.

/// The point style of the tests (row `adapt-point-style-objects`).
///
/// The option `pointStyle` holds a `PointStyle`, and the port has no style
/// names. Upstream data hold a name in that place. Thus a test does not
/// compare the value of the style with upstream JSON text: both sides get
/// [pointStyleMarker].
/// - [pointStyleJson] is the JSON text of a style.
/// - [withPointStyleMarkers] changes the upstream JSON text.
library;

/// The text that stands for the value of `pointStyle` on both sides of a
/// compare with upstream JSON text.
const String pointStyleMarker = '<pointStyle>';

/// The JSON text of a style: [pointStyleMarker] as a JSON string.
const String pointStyleJson = '"$pointStyleMarker"';

/// A member `"pointStyle"` with an upstream style name.
final RegExp _pointStyleMember = RegExp(
  '"pointStyle":"(?:circle|cross|crossRot|dash|line|rect|rectRounded|'
  'rectRot|star|triangle)"',
);

/// The upstream JSON text [json] with [pointStyleMarker] as each style name
/// of `pointStyle`.
String withPointStyleMarkers(String json) =>
    json.replaceAll(_pointStyleMember, '"pointStyle":$pointStyleJson');
