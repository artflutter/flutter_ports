// Original code, not ported from Chart.js: native arc-option loop contracts.

import 'package:flutter_chartjs_port/chartjs_core.dart';

/// Native arc context and property reads and writes, without user callbacks.
abstract interface class NativeArcElement() {
  /// Unknown subclasses must retain ordinary resolution at their own arc.
  bool get supportsNativeArcOptions;
}

/// The exact radial scale: `getDistanceFromCenterForValue` of an arc loop runs
/// no user code once its `reverse` option is a scalar.
abstract interface class NativeArcScale() {
  /// Unknown subclasses keep the ordinary options and context refresh.
  bool get supportsNativeArcOptions;
}

/// The scale capability, read once before a polar area loop plan.
bool nativeArcScale(Object? scale) =>
    scale is NativeArcScale && scale.supportsNativeArcOptions;

/// Read the arc capability where the ordinary loop would use the arc. Active
/// state is a separate live check.
bool nativeArcElement(Object? arc) =>
    arc is NativeArcElement && arc.supportsNativeArcOptions;

/// Native class metadata only, as `nativePointClass`: the element type of
/// the id `arc`.
bool nativeArcClass(ElementType? value) => value?.id == 'arc';
