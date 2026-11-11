// Original code, not ported from Chart.js: the easing in a compare with data.

/// The easing of the tests (row `adapt-flutter-curves`).
///
/// The option `easing` holds a Flutter `Curve`, and the port has no easing
/// names. Upstream data hold a name in that place. Thus a test does not
/// compare the value of `easing` with upstream data: both sides get
/// [curveMarker].
/// - [curveJson] is the JSON text of a curve.
/// - [withCurveMarkers] changes the upstream JSON text.
/// - [withCurveMarkersIn] changes upstream Dart data.
/// - [exactEasing] gives a config the upstream formula of its easing, for a
///   test that compares the steps of an animation with upstream.
library;

import 'package:chartjs_test_utils/pure.dart' show EffectCurve;

/// The text that stands for the value of `easing` on both sides of a
/// compare with upstream data.
const String curveMarker = '<curve>';

/// The JSON text of a curve: [curveMarker] as a JSON string.
const String curveJson = '"$curveMarker"';

final RegExp _easingMember = RegExp('"easing":"[A-Za-z]+"');

/// The upstream JSON text [json] with [curveMarker] as each value of
/// `easing`.
String withCurveMarkers(String json) =>
    json.replaceAll(_easingMember, '"easing":$curveJson');

/// A copy of the upstream data [data] with [curveMarker] as each String
/// value of a key `easing`.
Object? withCurveMarkersIn(Object? data) => switch (data) {
  final Map<String, Object?> map => {
    for (final MapEntry(:key, :value) in map.entries)
      key: key == 'easing' && value is String
          ? curveMarker
          : withCurveMarkersIn(value),
  },
  final List<Object?> list => [
    for (final item in list) withCurveMarkersIn(item),
  ],
  _ => data,
};

/// [cfg] with an [EffectCurve] in place of the key of the upstream effect.
Map<String, Object?> exactEasing(Map<String, Object?> cfg) =>
    switch (cfg['easing']) {
      final String effect => {...cfg, 'easing': EffectCurve(effect)},
      _ => cfg,
    };
