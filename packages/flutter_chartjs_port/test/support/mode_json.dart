// Original code, not ported from Chart.js: the mode in a compare with data.

/// The interaction mode of the tests (row `adapt-interaction-mode-objects`).
///
/// The option `mode` holds an `InteractionMode`, and the port has no mode
/// names. Upstream data hold a name in that place. Thus a test does not
/// compare the value of `mode` with upstream JSON text: both sides get
/// [modeMarker].
/// - [modeJson] is the JSON text of a mode.
/// - [withModeMarkers] changes the upstream JSON text.
library;

/// The text that stands for the value of an interaction `mode` on both
/// sides of a compare with upstream JSON text.
const String modeMarker = '<mode>';

/// The JSON text of a mode: [modeMarker] as a JSON string.
const String modeJson = '"$modeMarker"';

/// A member `"mode"` with an upstream interaction mode. The `mode` of a
/// context is an update mode: it has another value, and it stays.
final RegExp _modeMember = RegExp(
  '"mode":"(?:index|dataset|point|nearest|x|y)"',
);

/// The upstream JSON text [json] with [modeMarker] as each interaction
/// `mode`.
String withModeMarkers(String json) =>
    json.replaceAll(_modeMember, '"mode":$modeJson');
