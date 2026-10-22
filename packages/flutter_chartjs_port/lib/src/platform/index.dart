// Ported from Chart.js v4.5.1+7169e651 src/platform/index.js (MIT, Chart.js Contributors).

/// Port of `src/platform/index.js`.
///
/// `platform.flutter.dart` replaces `platform.dom.js` (Chart.js ADR 0014).
/// Thus [FlutterPlatform] takes the place of the `DomPlatform` export.
///
/// The export `_detectPlatform` drops its underscore (Chart.js ADR 0012):
/// [detectPlatform].
library;

import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.dom.dart'
    show getParentNode;
import 'package:flutter_chartjs_port/src/platform/platform.base.dart';
import 'package:flutter_chartjs_port/src/platform/platform.basic.dart';
import 'package:flutter_chartjs_port/src/platform/platform.flutter.dart';

export 'package:flutter_chartjs_port/src/platform/platform.base.dart'
    show BasePlatform;
export 'package:flutter_chartjs_port/src/platform/platform.basic.dart'
    show BasicPlatform;
export 'package:flutter_chartjs_port/src/platform/platform.flutter.dart'
    show FlutterPlatform;

/// index.js:6 `_detectPlatform(canvas)`.
///
/// Upstream returns a class, and core.controller.js:135 calls it with `new`.
/// The port returns the constructor tear-off of the class.
///
/// Upstream gives `BasicPlatform` when `_isDomSupported()` is false or the
/// canvas is an `OffscreenCanvas`, and `DomPlatform` else. The port has no
/// DOM, so `isDomSupported()` is always false (`platform-dom-supported`,
/// differences.md). The port gives [BasicPlatform] for a canvas that no
/// chart host shows, the counterpart of an `OffscreenCanvas`, and for an
/// item that is not a canvas. It gives [FlutterPlatform] for a canvas that a
/// chart host shows: its parent node is the host (`platform-detect-host`,
/// differences.md).
BasePlatform Function() detectPlatform(Object? canvas) {
  // DIVERGES(chartjs): platform-detect-host, a host test for the DOM test.
  if (canvas is! HTMLCanvasElement || getParentNode(canvas) == null) {
    return BasicPlatform.new;
  }
  return FlutterPlatform.new;
}
