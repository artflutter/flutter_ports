// Original code, not ported from Chart.js: the reduced-motion flag.

/// The reduced-motion flag of a chart canvas (Chart.js ADR 0049, section
/// 7): a chart on a canvas with the flag starts no animation (row
/// `platform-reduced-motion`). Only `ChartView` sets it, from
/// `MediaQuery.maybeDisableAnimationsOf`. No public library exports it.
///
/// The flag is keyed by the canvas, so that the first `update()` of the
/// constructor of a chart reads it. This file is a pure layer.
library;

/// The canvases with the flag.
final Expando<bool> _reducedMotion = Expando<bool>('reduced motion');

/// Sets the flag of [canvas] to [enabled].
void setReducedMotion(Object canvas, {required bool enabled}) {
  _reducedMotion[canvas] = enabled ? true : null;
}

/// Whether [canvas] has the flag. Dart `null` gives false.
bool isReducedMotion(Object? canvas) =>
    canvas != null && (_reducedMotion[canvas] ?? false);
