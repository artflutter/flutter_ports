// Ported from Chart.js v4.6.1 src/scales/scale.linear.js (MIT, Chart.js Contributors).

/// Port of `src/scales/scale.linear.js`.
///
/// [LinearScale] is the numeric scale of a cartesian axis. It gets the
/// parse, the range options, the ticks and the labels from
/// [LinearScaleBase]. It adds the data limits, the tick limit of the axis
/// size and the linear pixel mapping.
///
/// - Options are the typed resolver views of `helpers.config` (Chart.js ADR
///   0054 §4), through the facade [LinearScaleOptions]. The scale reads an
///   option with a getter of the facade (`options.ticks.minRotation`), and
///   applies [jsToNumber] before arithmetic.
/// - Numbers are `double` (Chart.js ADR 0146).
/// - The value methods take a `double` (Chart.js ADR 0186, row
///   `adapt-native-scale-values`).
/// - The scale reads the `@internal` members [LinearScaleBase.startValue]
///   and [LinearScaleBase.valueRange] (the upstream `_startValue` and
///   `_valueRange`) and [Scale.resolveTickFontOptions] (the upstream
///   `_resolveTickFontOptions`).
///
/// `core.scale.dart` imports `helpers.extras`, which is not a pure layer.
/// Thus this library is not a pure layer.
library;

import 'dart:math' as math;

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:meta/meta.dart';

/// scale.linear.js:6 `LinearScale extends LinearScaleBase`.
class LinearScale(super.cfg)
    extends LinearScaleBase
    implements NativeNumericParseScale {
  /// The constructor of LinearScaleBase (scale.linearbase.js:156). Upstream
  /// declares no constructor in this class.
  ///
  /// `cfg` is the object `{id, type, ctx, chart}` of [Scale.new].
  this;

  // scale.linear.js:8 `static id = 'linear'`. Scale has the instance field
  // `id`. Thus the value is only in the statics of jsClass.

  /// Native support for the explicit data-only lifecycle.
  @override
  // DIVERGES(chartjs): adapt-incremental-data-update, native opt-in.
  bool get supportsDataUpdates =>
      super.runtimeType == LinearScale &&
      getUserBounds().minDefined &&
      getUserBounds().maxDefined &&
      optionsView.cachedFixedDataBounds;

  /// scale.linear.js:13 `static defaults`.
  ///
  /// The tick callback is the function object of `Ticks.formatters.numeric`
  /// (core.ticks.js:28), `formatters['numeric']` of `core.ticks.dart`. A
  /// Dart `static final` gets its value at the first read, not at the load
  /// of the library. Thus the callback is the value of
  /// `formatters['numeric']` at the first read of [defaults]. The object is
  /// a typed scope of the kind `ScaleOptions` (Chart.js ADR 0054 §3).

  static final ScaleOptionsScope defaults = ScaleOptionsScope()
    ..ticks = (TickOptionsScope()..callback = formatters['numeric']!);

  /// scale.linear.js:6 `class LinearScale extends LinearScaleBase` as a
  /// value (Chart.js ADR 0020, section 3).
  ///
  /// It extends [LinearScaleBase.jsClass]. Its statics are `id`
  /// (`'linear'`) and [defaults], in the upstream order of declaration
  /// (scale.linear.js:8-17). Its `construct` calls `LinearScale(cfg)` with
  /// the `cfg` of [scaleCfgArg].
  static final JsClass jsClass = JsClass(
    'LinearScale',
    superclass: LinearScaleBase.jsClass,
    statics: {'id': 'linear', 'defaults': defaults},
    construct: (newTarget, args) => LinearScale(scaleCfgArg(args)),
  );

  /// This exact built-in scale has ordinary axis and metadata reads.
  @override
  // DIVERGES(chartjs): adapt-live-bar-layout, opt in only the built-in class.
  bool get supportsNativeBarIndexReads => _nativeBarIndexReads;

  /// Only this exact built-in class has the numeric projection contract.
  @override
  // DIVERGES(chartjs): adapt-bulk-bar-update, native linear projection.
  bool get supportsBulkBarUpdate => super.runtimeType == LinearScale;

  /// The inputs of [getPixelForValue] of a number, for the bulk point loop
  /// of Chart.js ADR 0166: only this exact built-in class.
  @override
  // DIVERGES(chartjs): adapt-bulk-point-update, the exact class only.
  LinearPixels? get linearPixels => super.runtimeType == LinearScale
      ? linearPixelsOf(startValue, valueRange)
      : null;

  @override
  // DIVERGES(chartjs): adapt-numeric-category-parse, exact numeric semantics.
  bool get supportsNativeNumericParse => super.runtimeType == LinearScale;

  late final bool _nativeBarIndexReads = runtimeType == LinearScale;

  /// The options of the scale: the linear scale options (index.d.ts:3356).
  @override
  LinearScaleOptions get options => super.options as LinearScaleOptions;

  /// The linear scale options of the view [view].
  @override
  @protected
  LinearScaleOptions createOptions(OptionView view) => LinearScaleOptions(view);

  /// scale.linear.js:20 `determineDataLimits()`.
  ///
  /// A min that is not finite gives 0. A max that is not finite gives 1.
  @override
  void determineDataLimits() {
    final (:min, :max) = getMinMax(true);

    this.min = isFinite(min) ? min : 0;
    this.max = isFinite(max) ? max : 1;

    // Common base implementation to handle min, max, beginAtZero
    handleTickRangeOptions();
  }

  /// scale.linear.js:34 `computeTickLimit()`.
  ///
  /// Returns the maximum number of ticks based on the scale dimension
  /// @protected
  ///
  /// `toRadians` applies `ToNumber` to the `minRotation` option
  /// ([jsToNumber]). A sine or a cosine of 0 or NaN gives the ratio 0.001.
  /// The `lineHeight` of the tick font is a number.
  @override
  @protected
  double computeTickLimit() {
    final horizontal = isHorizontal();
    final length = horizontal ? width : height;
    final minRotation = toRadians(jsToNumber(options.ticks.minRotation));
    final sinOrCos = horizontal ? math.sin(minRotation) : math.cos(minRotation);
    final ratio = jsTruthy(sinOrCos) ? sinOrCos : 0.001;
    final tickFont = resolveTickFontOptions(0);
    return (length /
            math.min<double>(40, jsToNumber(tickFont.lineHeight) / ratio))
        .ceilToDouble();
  }

  // Utils

  /// scale.linear.js:44 `getPixelForValue(value)`.
  ///
  /// [index] has no effect.
  @override
  double getPixelForValue(double value, [int? index]) {
    return getPixelForDecimal((value - startValue) / valueRange);
  }

  /// scale.linear.js:48 `getValueForPixel(pixel)`.
  @override
  double getValueForPixel(double pixel) {
    return startValue + getDecimalForPixel(pixel) * valueRange;
  }
}
