// Ported from Chart.js v4.6.1 src/scales/scale.linear.js (MIT, Chart.js Contributors).

/// Port of `src/scales/scale.linear.js`.
///
/// [LinearScale] is the numeric scale of a cartesian axis. It gets the
/// parse, the range options, the ticks and the labels from
/// [LinearScaleBase]. It adds the data limits, the tick limit of the axis
/// size and the linear pixel mapping.
///
/// - Options are the resolvers of `helpers.config` (Chart.js ADR 0043). The
///   scale reads an option with `options[key]` or [jsGet], and applies
///   [jsToNumber] before arithmetic.
/// - Numbers are `double` (Chart.js ADR 0045).
/// - The value methods take any JS value (Chart.js ADR 0025).
///   [LinearScale.getPixelForValue] starts with the port-only fast path for
///   a `double` of Chart.js ADR 0025, section 3.
/// - The scale reads the `@internal` members [LinearScaleBase.startValue]
///   and [LinearScaleBase.valueRange] (the upstream `_startValue` and
///   `_valueRange`) and [Scale.resolveTickFontOptions] (the upstream
///   `_resolveTickFontOptions`).
///
/// `core.scale.dart` imports `helpers.extras`, which is not a pure layer.
/// Thus this library is not a pure layer.
library;

import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/core/core.ticks.dart' show formatters;
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show isFinite;
import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart'
    show toRadians;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_math.dart'
    show jsCos, jsMin, jsSin;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show ScaleOptionsScope, TickOptionsScope;
import 'package:flutter_chartjs_port/src/scales/scale.linearbase.dart';
import 'package:meta/meta.dart';

/// scale.linear.js:6 `LinearScale extends LinearScaleBase`.
class LinearScale extends LinearScaleBase {
  /// The constructor of LinearScaleBase (scale.linearbase.js:156). Upstream
  /// declares no constructor in this class.
  ///
  /// [cfg] is the object `{id, type, ctx, chart}` of [Scale.new].
  LinearScale(super.cfg);

  // scale.linear.js:8 `static id = 'linear'`. Scale has the instance field
  // `id`. Thus the value is only in the statics of jsClass.

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
    final minRotation = toRadians(
      jsToNumber(jsGet(options['ticks'], 'minRotation')),
    );
    final sinOrCos = horizontal ? jsSin(minRotation) : jsCos(minRotation);
    final ratio = jsTruthy(sinOrCos) ? sinOrCos : 0.001;
    final tickFont = resolveTickFontOptions(0);
    return (length / jsMin(40, jsToNumber(tickFont.lineHeight) / ratio))
        .ceilToDouble();
  }

  // Utils

  /// scale.linear.js:44 `getPixelForValue(value)`.
  ///
  /// [value] is any JS value (Chart.js ADR 0025). Dart `null` (JS `null`)
  /// gives NaN. Another value gets `ToNumber` ([jsToNumber]), as the
  /// upstream subtraction applies it: the `undefined` sentinel and a string
  /// that is not a number give NaN. [index] has no effect.
  @override
  double getPixelForValue(Object? value, [double? index]) {
    if (value is double) {
      // Port-only fast path for a number (Chart.js ADR 0025, section 3).
      return getPixelForDecimal((value - startValue) / valueRange);
    }
    return value == null
        ? double.nan
        : getPixelForDecimal((jsToNumber(value) - startValue) / valueRange);
  }

  /// scale.linear.js:48 `getValueForPixel(pixel)`.
  @override
  double getValueForPixel(double pixel) {
    return startValue + getDecimalForPixel(pixel) * valueRange;
  }
}
