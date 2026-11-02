// Original code, not ported from Chart.js: native font cache invalidation.

import 'package:flutter/painting.dart' show PaintingBinding;
import 'package:flutter_chartjs_port/src/canvas/canvas_ui_text.dart';

bool _listening = false;

/// Track Flutter font changes before allowing cross-update metric reuse.
/// A bare engine without a painting binding keeps the normal measurement path.
Object? trackedTextMetricsGeneration() {
  if (!_listening) {
    final PaintingBinding binding;
    try {
      binding = PaintingBinding.instance;
      // Flutter signals a missing binding with Error, not Exception.
      // ignore: avoid_catching_errors
    } on Error {
      // BindingBase.checkInstance throws when no binding exists. Do not create
      // a binding as a side effect of using an offscreen canvas.
      return null;
    }
    binding.systemFonts.addListener(invalidateCanvasTextMetrics);
    _listening = true;
    invalidateCanvasTextMetrics();
  }
  return canvasTextMetricsGeneration;
}
