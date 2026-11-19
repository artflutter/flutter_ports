// Original code, not ported from Chart.js: the typed config of a cfg Map.

/// The animation config of the port is a typed [AnimationSpec] (row
/// `adapt-animation-option-types`). The upstream data and the old tests give
/// it as a JS object. [animationSpecOf] gives the [AnimationSpec] with the
/// same behavior.
library;

import 'package:flutter_chartjs_port/chartjs_core.dart';

import 'easing_json.dart';

/// The [AnimationSpec] of the JS cfg object [cfg], with its keys in their
/// order, written through the face:
/// - a `duration` or a `delay` is its `ToNumber`, or absent for a value that
///   is not finite (upstream gives NaN for a duration and 0 for a delay
///   there, as the port does for an absent value);
/// - a `loop` is its `ToBoolean`;
/// - an `easing` name is its `EffectCurve` ([exactEasing]);
/// - the key `type` goes: the port has no option `type`, and the Dart type
///   of the value selects the interpolator.
AnimationSpec animationSpecOf(Map<String, Object?> cfg) {
  final spec = AnimationSpec();
  for (final MapEntry(:key, :value) in exactEasing(cfg).entries) {
    switch (key) {
      case 'type':
        continue;
      case 'duration' || 'delay':
        final number = _absent(value) ? double.nan : jsToNumber(value);
        spec[key] = number.isFinite ? number : undefined;
      case 'loop':
        spec[key] = _absent(value) ? value : jsTruthy(value);
      default:
        spec[key] = value;
    }
  }
  return spec;
}

/// Whether [value] is `null` or `undefined`.
bool _absent(Object? value) => value == null || value is Undefined;

/// Whether the upstream cfg [cfg] names a `type` whose interpolator differs
/// from the interpolator of the Dart type of [value], the start value of
/// the animation (row `adapt-animation-option-types`). Upstream animates
/// such a value with the interpolator of the name. The port has no option
/// `type`, so the steps differ.
bool animationTypeDiverges(Map<String, Object?> cfg, Object? value) {
  final type = cfg['type'];
  if (type == null || type is Undefined) return false;
  final kind = switch (value) {
    num() => 'number',
    bool() => 'boolean',
    _ => null,
  };
  return type != kind && !(type == 'color' && kind == null);
}

/// Whether the upstream cfg [cfg] gives `from` or `to` the JS `null`. Dart
/// `null` is the absent value of the typed spec (row
/// `adapt-animation-option-types`), so upstream animates to `null` where the
/// port takes the next value.
bool animationNullDiverges(Map<String, Object?> cfg) =>
    (cfg.containsKey('from') && cfg['from'] == null) ||
    (cfg.containsKey('to') && cfg['to'] == null);
