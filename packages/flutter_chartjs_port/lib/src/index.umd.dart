// Ported from Chart.js v4.6.1 src/index.umd.ts (MIT, Chart.js Contributors).

/// Port of `src/index.umd.ts`: the UMD entry, the class value `Chart` with
/// the statics of the UMD bundle (Chart.js ADR 0048, sections 1 and 7).
///
/// Dart has no import side effects and no global object. Thus the body of
/// the module (:28-47) runs at the first read of [chartUmd], once in each
/// isolate, not at the import (`platform-umd-entry`). A second read gives
/// the same object, and the registration of :28 runs once. `window.Chart`
/// (:49-51) has no form.
///
/// - :9 `import * as helpers`: [_helpers] has each runtime export of
///   `src/helpers/index.ts` under its upstream name, also a `_` name, in
///   code unit order, as the module namespace gives them. The value is the
///   Dart member (Chart.js ADR 0012).
/// - :20 `import * as platforms`: [_platforms] has the keys of
///   `platform/index.js` in code unit order. The key `DomPlatform` gives
///   `FlutterPlatform.jsClass` (`platform-umd-dom-platform`).
/// - :39-40 `Interaction` and `layouts` are plain objects upstream. The
///   port has the class `Interaction` with two statics and the record
///   `layouts` (`adapt-umd-namespace-objects`).
///
/// No public library exports this library, and the widgets do not import it:
/// a read of [chartUmd] keeps every component (Chart.js ADR 0048, section
/// 1). The test harness keeps its own registration
/// (`harness-register-builtins`). The library imports the platform layer.
/// Thus it is not a pure layer.
library;

import 'package:flutter_chartjs_port/src/core/core.adapters.dart' show adapters;
import 'package:flutter_chartjs_port/src/core/core.animation.dart'
    show Animation;
import 'package:flutter_chartjs_port/src/core/core.animations.dart'
    show Animations;
import 'package:flutter_chartjs_port/src/core/core.animator.dart' show animator;
import 'package:flutter_chartjs_port/src/core/core.controller.dart' show Chart;
import 'package:flutter_chartjs_port/src/core/core.datasetController.dart'
    show DatasetController;
import 'package:flutter_chartjs_port/src/core/core.element.dart' show Element;
import 'package:flutter_chartjs_port/src/core/core.interaction.dart'
    show Interaction;
import 'package:flutter_chartjs_port/src/core/core.layouts.dart' show layouts;
import 'package:flutter_chartjs_port/src/core/core.registry.dart' show registry;
import 'package:flutter_chartjs_port/src/core/core.scale.dart' show Scale;
import 'package:flutter_chartjs_port/src/core/core.ticks.dart' show ticks;
import 'package:flutter_chartjs_port/src/helpers/index.dart' as helpers;
import 'package:flutter_chartjs_port/src/index.dart'
    show controllers, elements, plugins, scales;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/platform/index.dart'
    show BasePlatform, BasicPlatform, FlutterPlatform, detectPlatform;
import 'package:flutter_chartjs_port/src/types/basic.dart' show AnyObject;

/// index.umd.ts:9 `import * as helpers from './helpers/index.js'`.
///
/// Each runtime export of `src/helpers/index.ts` (122 names, 47 of them
/// with a `_`) under its upstream name, in code unit order, with the Dart
/// member as the value. A `_` name drops its underscore in Dart, and an
/// upper case constant is lowerCamelCase (Chart.js ADR 0012). The keys are
/// `Object.keys(Chart.helpers)` of the pinned bundle
/// (`test/port/index_umd_reference.dart`).
final AnyObject _helpers = Map<String, Object?>.unmodifiable(
  <String, Object?>{
    'HALF_PI': helpers.halfPi,
    'INFINITY': helpers.infinity,
    'PI': helpers.pi,
    'PITAU': helpers.piTau,
    'QUARTER_PI': helpers.quarterPi,
    'RAD_PER_DEG': helpers.radPerDeg,
    'TAU': helpers.tau,
    'TWO_THIRDS_PI': helpers.twoThirdsPi,
    '_addGrace': helpers.addGrace,
    '_alignPixel': helpers.alignPixel,
    '_alignStartEnd': helpers.alignStartEnd,
    '_angleBetween': helpers.angleBetween,
    '_angleDiff': helpers.angleDiff,
    '_arrayUnique': helpers.arrayUnique,
    '_attachContext': helpers.attachContext,
    '_bezierCurveTo': helpers.bezierCurveTo,
    '_bezierInterpolation': helpers.bezierInterpolation,
    '_boundSegment': helpers.boundSegment,
    '_boundSegments': helpers.boundSegments,
    '_capitalize': helpers.capitalize,
    '_computeSegments': helpers.computeSegments,
    '_createResolver': helpers.createResolver,
    '_decimalPlaces': helpers.decimalPlaces,
    '_deprecated': helpers.deprecated,
    '_descriptors': helpers.descriptors,
    '_elementsEqual': helpers.elementsEqual,
    '_factorize': helpers.factorize,
    '_filterBetween': helpers.filterBetween,
    '_getParentNode': helpers.getParentNode,
    '_getStartAndCountOfVisiblePoints': helpers.getStartAndCountOfVisiblePoints,
    '_int16Range': helpers.int16Range,
    '_isBetween': helpers.isBetween,
    '_isClickEvent': helpers.isClickEvent,
    '_isDomSupported': helpers.isDomSupported,
    '_isPointInArea': helpers.isPointInArea,
    '_limitValue': helpers.limitValue,
    '_longestText': helpers.longestText,
    '_lookup': helpers.lookup,
    '_lookupByKey': helpers.lookupByKey,
    '_measureText': helpers.measureText,
    '_merger': helpers.merger,
    '_mergerIf': helpers.mergerIf,
    '_normalizeAngle': helpers.normalizeAngle,
    '_parseObjectDataRadialScale': helpers.parseObjectDataRadialScale,
    '_pointInLine': helpers.pointInLine,
    '_readValueToProps': helpers.readValueToProps,
    '_rlookupByKey': helpers.rlookupByKey,
    '_scaleRangesChanged': helpers.scaleRangesChanged,
    '_setMinAndMaxByKey': helpers.setMinAndMaxByKey,
    '_splitKey': helpers.splitKey,
    '_steppedInterpolation': helpers.steppedInterpolation,
    '_steppedLineTo': helpers.steppedLineTo,
    '_textX': helpers.textX,
    '_toLeftRightCenter': helpers.toLeftRightCenter,
    '_updateBezierControlPoints': helpers.updateBezierControlPoints,
    'addRoundedRectPath': helpers.addRoundedRectPath,
    'almostEquals': helpers.almostEquals,
    'almostWhole': helpers.almostWhole,
    'callback': helpers.callback,
    'clearCanvas': helpers.clearCanvas,
    'clipArea': helpers.clipArea,
    'clone': helpers.clone,
    'color': helpers.color,
    'createContext': helpers.createContext,
    'debounce': helpers.debounce,
    'defined': helpers.defined,
    'distanceBetweenPoints': helpers.distanceBetweenPoints,
    'drawPoint': helpers.drawPoint,
    'drawPointLegend': helpers.drawPointLegend,
    'each': helpers.each,
    'easingEffects': helpers.easingEffects,
    'finiteOrDefault': helpers.finiteOrDefault,
    'fontString': helpers.fontString,
    'formatNumber': helpers.formatNumber,
    'getAngleFromPoint': helpers.getAngleFromPoint,
    'getDatasetClipArea': helpers.getDatasetClipArea,
    'getHoverColor': helpers.getHoverColor,
    'getMaximumSize': helpers.getMaximumSize,
    'getRelativePosition': helpers.getRelativePosition,
    'getRtlAdapter': helpers.getRtlAdapter,
    'getStyle': helpers.getStyle,
    'isArray': helpers.isArray,
    'isFinite': helpers.isFinite,
    'isFunction': helpers.isFunction,
    'isNullOrUndef': helpers.isNullOrUndef,
    'isNumber': helpers.isNumber,
    'isObject': helpers.isObject,
    'isPatternOrGradient': helpers.isPatternOrGradient,
    'listenArrayEvents': helpers.listenArrayEvents,
    'log10': helpers.log10,
    'merge': helpers.merge,
    'mergeIf': helpers.mergeIf,
    'niceNum': helpers.niceNum,
    'noop': helpers.noop,
    'overrideTextDirection': helpers.overrideTextDirection,
    'readUsedSize': helpers.readUsedSize,
    'renderText': helpers.renderText,
    'requestAnimFrame': helpers.requestAnimFrame,
    'resolve': helpers.resolve,
    'resolveObjectKey': helpers.resolveObjectKey,
    'restoreTextDirection': helpers.restoreTextDirection,
    'retinaScale': helpers.retinaScale,
    'setsEqual': helpers.setsEqual,
    'sign': helpers.sign,
    'splineCurve': helpers.splineCurve,
    'splineCurveMonotone': helpers.splineCurveMonotone,
    'supportsEventListenerOptions': helpers.supportsEventListenerOptions,
    'throttled': helpers.throttled,
    'toDegrees': helpers.toDegrees,
    'toDimension': helpers.toDimension,
    'toFont': helpers.toFont,
    'toFontString': helpers.toFontString,
    'toLineHeight': helpers.toLineHeight,
    'toPadding': helpers.toPadding,
    'toPercentage': helpers.toPercentage,
    'toRadians': helpers.toRadians,
    'toTRBL': helpers.toTRBL,
    'toTRBLCorners': helpers.toTRBLCorners,
    'uid': helpers.uid,
    'unclipArea': helpers.unclipArea,
    'unlistenArrayEvents': helpers.unlistenArrayEvents,
    'valueOrDefault': helpers.valueOrDefault,
  },
);

/// index.umd.ts:20 `import * as platforms from './platform/index.js'`.
///
/// The keys of `platform/index.js` (:4-13) in code unit order, as the module
/// namespace gives them. The key `DomPlatform` gives the class value of the
/// replacement `FlutterPlatform` (Chart.js ADR 0037, section 1), and
/// `_detectPlatform` gives [detectPlatform].
final AnyObject _platforms = Map<String, Object?>.unmodifiable(
  <String, Object?>{
    'BasePlatform': BasePlatform.jsClass,
    'BasicPlatform': BasicPlatform.jsClass,
    // DIVERGES(chartjs): platform-umd-dom-platform, the FlutterPlatform class.
    'DomPlatform': FlutterPlatform.jsClass,
    '_detectPlatform': detectPlatform,
  },
);

/// index.umd.ts:53 `export default Chart`: the class value of `Chart`
/// ([Chart.jsClass]) after the body of the module (:28-51).
// DIVERGES(chartjs): platform-umd-entry, the body runs at the first read.
final JsClass chartUmd = _evaluate();

/// index.umd.ts:28-51, the body of the module. Each statement is one
/// statement of upstream, in the upstream order.
JsClass _evaluate() {
  // Register built-ins
  Chart.register([controllers, scales, elements, plugins]);

  Chart.jsClass['helpers'] = Map<String, Object?>.of(_helpers);
  Chart.jsClass['_adapters'] = adapters;
  Chart.jsClass['Animation'] = Animation.jsClass;
  Chart.jsClass['Animations'] = Animations.jsClass;
  Chart.jsClass['animator'] = animator;
  Chart.jsClass['controllers'] = registry.controllers.items;
  Chart.jsClass['DatasetController'] = DatasetController.jsClass;
  Chart.jsClass['Element'] = Element.jsClass;
  Chart.jsClass['elements'] = elements;
  // DIVERGES(chartjs): adapt-umd-namespace-objects, a Map of the statics.
  Chart.jsClass['Interaction'] = Map<String, Object?>.unmodifiable(
    <String, Object?>{
      'evaluateInteractionItems': Interaction.evaluateInteractionItems,
      'modes': Interaction.modes,
    },
  );
  // DIVERGES(chartjs): adapt-umd-namespace-objects, the record of layouts.
  Chart.jsClass['layouts'] = layouts;
  Chart.jsClass['platforms'] = _platforms;
  Chart.jsClass['Scale'] = Scale.jsClass;
  Chart.jsClass['Ticks'] = ticks;

  // Compatibility with ESM extensions
  //
  // `Object.assign(Chart, controllers, scales, elements, plugins,
  // platforms)`: jsAssign takes one source, so the five sources are five
  // calls in that order.
  jsAssign(Chart.jsClass, controllers);
  jsAssign(Chart.jsClass, scales);
  jsAssign(Chart.jsClass, elements);
  jsAssign(Chart.jsClass, plugins);
  jsAssign(Chart.jsClass, _platforms);
  Chart.jsClass['Chart'] = Chart.jsClass;

  // :49-51 `window.Chart = Chart` has no form: the port has no global object
  // (`platform-umd-entry`).
  return Chart.jsClass;
}
