// Ported from Chart.js v4.5.1 src/platform/platform.basic.js (MIT, Chart.js Contributors).

/// Port of `src/platform/platform.basic.js`.
///
/// Platform fallback implementation (minimal).
/// @see https://github.com/chartjs/Chart.js/pull/4591#issuecomment-319575939
///
/// This library is a pure layer. `getContext('2d')` is
/// [HTMLCanvasElement.getContext] of the canvas interface.
library;

import 'package:flutter_chartjs/src/canvas/canvas.dart';
import 'package:flutter_chartjs/src/platform/platform.base.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;

/// platform.basic.js:13 `BasicPlatform`.
///
/// Platform class for charts without access to the DOM or to many element
/// properties. This platform is used by default for any chart passed an
/// OffscreenCanvas.
///
/// In the port, `detectPlatform` gives it for a canvas that no chart host
/// shows (`lib/src/platform/index.dart`): a canvas that draws without a
/// widget, the counterpart of an `OffscreenCanvas`.
class BasicPlatform extends BasePlatform {
  /// platform.basic.js:13 the implicit constructor.
  BasicPlatform();

  /// platform.basic.js:14 `acquireContext(item)`.
  ///
  /// To prevent canvas fingerprinting, some add-ons undefine the getContext
  /// method, for example: https://github.com/kkapsner/CanvasBlocker
  /// https://github.com/chartjs/Chart.js/issues/2807
  ///
  /// `item && item.getContext && item.getContext('2d') || null`: an item
  /// that is not an [HTMLCanvasElement] has no `getContext`, so it gives
  /// `null`.
  @override
  CanvasRenderingContext2D? acquireContext(
    Object? item, [
    double? aspectRatio,
  ]) {
    return item is HTMLCanvasElement ? item.getContext('2d') : null;
  }

  /// platform.basic.js:20 `updateConfig(config)`.
  @override
  void updateConfig(types.ChartConfiguration config) {
    config.options['animation'] = false;
  }
}
