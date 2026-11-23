// Original code, not ported from Chart.js: shared animation options.

/// One resolution of the animation options for the bars of one
/// `BarController.update` call (Chart.js ADR 0151, row
/// `adapt-shared-bar-animations`), and for the points of one
/// `ScatterController.update` call (Chart.js ADR 0160, row
/// `adapt-shared-point-animations`). The text below says bar; a point of a
/// scatter update takes the same guard, with the change of item 3 that the
/// last paragraph states.
///
/// Upstream resolves the animation options again for each bar
/// (core.datasetController.js:841-861 and :898-908): a resolver with a
/// context is never cacheable (helpers.config.ts:128). The result is the same
/// for each bar of the loop when no read of the resolution depends on the
/// bar, and when no input of the resolution changes between two bars.
///
/// The inputs of `resolveAnimations(index, mode)` are the chart option
/// `animation`, the scope keys of the controller type and the mode, the
/// option scopes of the dataset, the defaults, the items of the app
/// (`ChartConfig.animations` and `ChartConfig.transitions`) and the context
/// of the bar. Only the context depends on the bar. Only two reads of a
/// resolver take a value of the context: the call of a scriptable option
/// (`_resolveScriptable`) and the item of an indexable option at the index
/// of the context (`_resolveArray`). Both add one to [optionCallEpoch]. The
/// context of a bar has `active: false` in each call of `updateElement`, so
/// the hover state of a bar is not an input.
///
/// The guard:
/// 1. One time for each update call ([SharedBarAnimations.begin]): the mode
///    animates; the controller, the chart, the value scale and the index
///    scale are objects of their exact built-in classes (their existing
///    probes). A subclass of the app can run code between two bars, or
///    replace `resolveAnimations` or `getContext`.
/// 2. Around the ordinary resolution of a bar: [optionCallEpoch] before and
///    after `resolveAnimations`. An equal count shows that the resolution
///    read no value of the context. `Animations.holdsPlainValues` shows that
///    no kept value is a resolver that keeps the context of that bar.
/// 3. Before each next bar: [optionCallEpoch] again. An equal count shows
///    that no scriptable option ran and that no active animation was
///    cancelled since the kept resolution: no code of the app ran that could
///    change an input. The element is a built-in bar and the property object
///    has no foreign value (`Element.takesProperties`), and the options of
///    the property object are absent or shared: no bar resolved element
///    options of its own, which can call code of the app.
///
/// A point of a scatter update has element options of its own in each
/// animated update: the scatter controller shares no options
/// (core.datasetController.js:270 and :809: `enableOptionSharing` is false).
/// Item 3 accepts them for a point. The resolution of these options runs
/// between two points, and each call of app code in it (a scriptable option
/// or the item of an indexable option at the index) adds one to the count,
/// so the test of the count already covers it. The point must be a
/// `PointElement` of the exact class with a `PointProperties` object with no
/// foreign value, and the options are absent or a resolved options object.
///
/// A bar that fails a test of item 3 takes the ordinary resolution, and its
/// result can become the kept object. The kept object lives until the end of
/// the update call: no object outlives the loop (Chart.js ADR 0054 section 4
/// as Chart.js ADR 0151 states it).
///
/// Each bar with the kept object keeps its `getContext(index, undefined,
/// mode)` call (the writes of `parsed`, `raw`, `index`, `active` and `mode`
/// into the context of the element) and its `Animations.update(element,
/// properties)` call.
library;

import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:meta/meta.dart';

/// The kept animation options of one `BarController.update` or
/// `ScatterController.update` call.
// DIVERGES(chartjs): adapt-shared-bar-animations, one resolution for a loop.
final class SharedBarAnimations._(
  final DatasetController _controller,

  /// The update mode of the call.
  final String mode,
) {
  /// The plan of one update call of [controller] in the mode [mode], or Dart
  /// `null` when item 1 of the guard fails. [exactClass] is whether the
  /// controller is an object of the class `BarController` or
  /// `ScatterController` itself.
  static SharedBarAnimations? begin(
    DatasetController controller,
    String mode, {
    required bool exactClass,
  }) {
    // `_isDirectUpdateMode`: these modes resolve no animations.
    if (!exactClass || mode == 'reset' || mode == 'none') return null;
    final Object chart = controller.chart;
    if (chart is! BulkBarChart || !chart.supportsBulkBarUpdate) return null;
    final meta = controller.cachedMeta;
    final Object? valueScale = meta.vScale;
    final Object? indexScale = meta.iScale;
    if (valueScale is! NativeBarIndexReads ||
        !valueScale.supportsNativeBarIndexReads ||
        indexScale is! NativeBarIndexReads ||
        !indexScale.supportsNativeBarIndexReads) {
      return null;
    }
    return SharedBarAnimations._(controller, mode);
  }

  /// The `Animations` object of the last ordinary resolution that passed
  /// item 2 of the guard, or Dart `null`.
  Animations? _kept;

  /// [optionCallEpoch] before the resolution of [_kept].
  int _epoch = 0;

  /// Whether the resolution of [_kept] made a context: the chart option
  /// `animation` is not `false` (core.datasetController.js:849).
  bool _context = false;

  /// `resolveAnimations(index, mode).update(element, properties)` of
  /// `DatasetController.updateElement` (core.datasetController.js:905), with
  /// the kept object where the guard holds.
  void updateElement(IElement element, int index, Object properties) {
    final controller = _controller;
    final sharable = _sharable(element, properties);
    final kept = _kept;
    if (kept != null && sharable && optionCallEpoch == _epoch) {
      // The side effect of the resolution: the writes into the context.
      if (_context) controller.getContext(index, null, mode);
      assert(_countHit(), 'Counts a bar with the kept object.');
      kept.update(element, properties);
      return;
    }
    final before = optionCallEpoch;
    final animations = controller.resolveAnimations(index, mode);
    if (sharable && before == optionCallEpoch && animations.holdsPlainValues) {
      _kept = animations;
      // The count before the update: a cancel in the update of this bar ends
      // the kept object for the next bar.
      _epoch = before;
      _context =
          readOption(controller.chart.options, OptionKey.animation) != false;
    } else {
      _kept = null;
    }
    animations.update(element, properties);
  }

  /// Whether [element] with [properties] is a built-in bar whose property
  /// object has no foreign value and no element options of its own, or a
  /// built-in point whose property object has no foreign value.
  static bool _sharable(IElement element, Object properties) {
    if (properties is PointProperties) {
      // DIVERGES(chartjs): adapt-shared-point-animations, a point with
      // options of its own (Chart.js ADR 0160).
      if (properties.hasForeign ||
          element is! Element ||
          !element.takesProperties(properties)) {
        return false;
      }
      return true;
    }
    if (properties is! BarProperties || properties.hasForeign) return false;
    if (element is! Element || !element.takesProperties(properties)) {
      return false;
    }
    final options = properties.options;
    return options == null || options.isShared;
  }
}

/// The count of the bars that took a kept `Animations` object, in a build
/// with asserts. A profile build and a release build count nothing.
@visibleForTesting
int get debugSharedBarAnimationHits => _hits;

int _hits = 0;

bool _countHit() {
  _hits++;
  return true;
}
