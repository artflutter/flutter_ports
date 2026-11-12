// Original code, not ported from Chart.js: the cubic mode in a data compare.

/// The cubic interpolation mode of the tests (row
/// `adapt-cubic-interpolation-mode-objects`).
///
/// The option `cubicInterpolationMode` holds a `CubicInterpolationMode`,
/// and the port has no mode names. Upstream data hold a keyword in that
/// place. Thus a test does not compare the value of the mode with upstream
/// JSON text: both sides get [cubicModeMarker].
/// - [cubicModeJson] is the JSON text of a mode.
/// - [withCubicModeMarkers] changes the upstream JSON text.
library;

/// The text that stands for the value of `cubicInterpolationMode` on both
/// sides of a compare with upstream JSON text.
const String cubicModeMarker = '<cubicInterpolationMode>';

/// The JSON text of a mode: [cubicModeMarker] as a JSON string.
const String cubicModeJson = '"$cubicModeMarker"';

/// A member `"cubicInterpolationMode"` with an upstream keyword.
final RegExp _cubicModeMember = RegExp(
  '"cubicInterpolationMode":"(?:default|monotone)"',
);

/// The upstream JSON text [json] with [cubicModeMarker] as each value of
/// `cubicInterpolationMode`.
String withCubicModeMarkers(String json) => json.replaceAll(
  _cubicModeMember,
  '"cubicInterpolationMode":$cubicModeJson',
);
