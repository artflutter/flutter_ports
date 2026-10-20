// Ported from Chart.js v4.5.1 src/platform/platform.base.js (MIT, Chart.js Contributors).

/// Port of `src/platform/platform.base.js`.
///
/// The class implements the `BasePlatform` interface of
/// `lib/src/types/index.dart` (index.d.ts:2167). Both have the same name.
/// Thus this file imports the type library with the prefix `types`.
///
/// This library is a pure layer: it imports only the canvas interface and
/// the type libraries.
library;

import 'package:flutter_chartjs/src/canvas/canvas.dart';
import 'package:flutter_chartjs/src/js/js_class.dart';
import 'package:flutter_chartjs/src/js/js_math.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;

/// platform.base.js:9 `BasePlatform`.
///
/// Abstract class that allows abstracting platform dependencies away from the
/// chart.
///
/// Upstream exports a plain class, which `Chart.platforms.BasePlatform`
/// exposes and which a user can pass as `config.platform`. The Dart class is
/// not abstract, so that `BasePlatform()` gives the same object.
class BasePlatform implements types.BasePlatform {
  /// platform.base.js:9 the implicit constructor.
  BasePlatform();

  /// platform.base.js:9 `class BasePlatform` as a value (Chart.js ADR 0020,
  /// section 3).
  ///
  /// `core.controller.js:136` constructs `config.platform` with `new`. Thus
  /// a platform of the configuration is a class value. It has no statics.
  /// Its `construct` ignores the arguments, as the implicit constructor
  /// does. A class value that extends it without a `construct` of its own
  /// constructs a [BasePlatform].
  static final JsClass jsClass = JsClass(
    'BasePlatform',
    construct: (newTarget, args) => BasePlatform(),
  );

  /// platform.base.js:16 `acquireContext(canvas, aspectRatio)`.
  ///
  /// Called at chart construction time, returns a context2d instance
  /// implementing the [W3C Canvas 2D Context API
  /// standard](https://www.w3.org/TR/2dcontext/).
  ///
  /// The upstream body is empty, so it returns `undefined`. Dart `null`
  /// stands for it: core.controller.js:140 tests only its truthiness.
  @override
  CanvasRenderingContext2D? acquireContext(
    Object? canvas, [
    double? aspectRatio,
  ]) => null;

  /// platform.base.js:24 `releaseContext(context)`.
  ///
  /// Called at chart destruction time, releases any resources associated to
  /// the context previously returned by the acquireContext() method.
  /// Returns true if the method succeeded, else false.
  @override
  bool releaseContext(CanvasRenderingContext2D context) {
    return false;
  }

  /// platform.base.js:35 `addEventListener(chart, type, listener)`.
  ///
  /// Registers the specified listener on the given chart.
  @override
  void addEventListener(types.Chart chart, String type, Function listener) {}

  /// platform.base.js:43 `removeEventListener(chart, type, listener)`.
  ///
  /// Removes the specified listener previously registered with
  /// addEventListener.
  @override
  void removeEventListener(
    types.Chart chart,
    String type, [
    Function? listener,
  ]) {}

  /// platform.base.js:48 `getDevicePixelRatio()`.
  ///
  /// Returns the current devicePixelRatio of the device this platform is
  /// connected to.
  @override
  double getDevicePixelRatio() {
    return 1;
  }

  /// platform.base.js:59 `getMaximumSize(element, width, height,
  /// aspectRatio)`.
  ///
  /// Returns the maximum size in pixels of given canvas element.
  ///
  /// `width || element.width` takes the canvas width for a falsy [width]:
  /// `undefined` (Dart `null`), 0 or NaN. The test of [aspectRatio] is the
  /// JS ToBoolean too.
  @override
  ({double width, double height}) getMaximumSize(
    HTMLCanvasElement element, [
    double? width,
    double? height,
    double? aspectRatio,
  ]) {
    final w = jsMax(
      0,
      jsTruthy(width) ? width! : element.width.toDouble(),
    );
    final h = jsTruthy(height) ? height! : element.height.toDouble();
    return (
      width: w,
      height: jsMax(
        0,
        jsTruthy(aspectRatio) ? (w / aspectRatio!).floorToDouble() : h,
      ),
    );
  }

  /// platform.base.js:72 `isAttached(canvas)`.
  ///
  /// Returns true if the canvas is attached to the platform, false if not.
  @override
  bool isAttached(HTMLCanvasElement? canvas) {
    return true;
  }

  /// platform.base.js:80 `updateConfig(config)`.
  ///
  /// Updates config with platform specific requirements
  @override
  void updateConfig(types.ChartConfiguration config) {
    // no-op
  }
}
