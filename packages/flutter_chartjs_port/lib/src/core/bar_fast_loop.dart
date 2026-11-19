// Original code, not ported from Chart.js: fast bar loop guards.

/// The guards of the fast bar update loop (Chart.js ADR 0069) for a chart
/// with several datasets and for an update mode other than `none` (Chart.js
/// ADR 0152).
library;

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The count of the fast loops that ran in an update mode other than `none`.
/// Only tests read it.
int fastBarModesTaken = 0;

/// The count of the fast loops that ran with the layout of several datasets
/// (one for each dataset and update). Only tests read it.
int fastBarMultiTaken = 0;

/// The count of the ordinary bar loops that took one search of the axes and
/// the stacks for the update of a dataset. Only tests read it.
int fastBarPlansTaken = 0;

/// Whether the reads of the option `hidden` of each dataset object of
/// [chart] (`Chart.isDatasetVisible`) run no user code: the dataset List and
/// each dataset are native containers with no route for `hidden`.
bool fastBarHiddenReadsAreNative(IChart chart) {
  final owner = chart;
  if (owner is! Chart) return false;
  final Object config = owner.config;
  if (config.runtimeType != Config) return false;
  final data = (config as Config).data;
  if (!nativeDataUpdateObject(data) ||
      (data is OptionScope && data.routeOf('datasets') != null)) {
    return false;
  }
  final datasets = dataUpdateField(data, 'datasets');
  if (!nativeDataUpdateList(datasets) || datasets is! List<Object?>) {
    return false;
  }
  for (var i = 0; i < datasets.length; i++) {
    final dataset = datasets[i];
    if (dataset != null &&
        (!nativeDataUpdateObject(dataset) ||
            (dataset is OptionScope && dataset.routeOf('hidden') != null))) {
      return false;
    }
  }
  return true;
}

/// Whether the loop of `updateStacks` (core.datasetController.js:152) runs no
/// user code for the parsed items [parsed] of [controller]: the chart and the
/// value scale have the built-in reads of the visible metas, the reads of the
/// option `hidden` are native ([fastBarHiddenReadsAreNative]), and each item
/// is a typed parsed item with no foreign key. Then the visible metas of the
/// value scale do not change in the loop, and the sub-stack of the stack key
/// stays the same object (Chart.js ADR 0152).
bool fastStackLoopIsNative(DatasetController controller, List<Object?> parsed) {
  final owner = controller.chart;
  final vScale = controller.cachedMeta.vScale;
  if (owner is! Chart ||
      !owner.supportsNativeBarIndexReads ||
      vScale == null ||
      vScale is! NativeBarIndexReads ||
      !(vScale as NativeBarIndexReads).supportsNativeBarIndexReads ||
      !identical(vScale.chart, owner) ||
      !fastBarHiddenReadsAreNative(owner)) {
    return false;
  }
  for (var i = 0; i < parsed.length; i++) {
    final item = parsed[i];
    if (item is! ParsedItem || item.hasForeign) return false;
  }
  return true;
}

/// The count of the data-only updates of several controllers that kept the
/// rulers of the bar controllers. Only tests read it.
int fastBarRulersKept = 0;

/// Whether `updateElement` of a dataset controller of [chart] writes the
/// properties of an element directly in the update mode [mode], as it does in
/// the mode `none`.
///
/// With the chart option `animation` equal to the value `false` itself,
/// `DatasetController.resolveAnimations` makes no resolver and no context: it
/// gives a new `Animations` with no property, and `Animations.update` calls
/// `Element.assign`, the write of the mode `none`. The values `0` and `null`
/// do not pass: they set `animationsDisabled` and still resolve the animation
/// options.
///
/// The caller first asks the controller that it holds no cached animations
/// of the mode (`DatasetController.hasNoCachedAnimations`): `configure`
/// clears them in each chart update, so only a direct call of a controller
/// method after a write into the live options can find some.
///
/// The caller reads this after the first ordinary bar of the update, so the
/// option is in the cache of the chart options: the read runs no user code.
/// The mode `reset` has another geometry, and the mode `active` reads the
/// hover options of each bar: both keep the ordinary loop.
bool fastBarModeWritesDirectly(IChart chart, String mode) {
  if (mode == 'reset' || mode == 'active') return false;
  final options = chart.options;
  return options.runtimeType == OptionView &&
      identical(readOption(options, OptionKey.animation), false);
}

/// Whether a data-only update of the several [controllers] of a chart can
/// keep the ruler of each bar controller, as the update of one controller
/// does.
///
/// The ruler of a bar controller on a category scale holds the pixel of each
/// index, the smallest distance of two index values of the visible bar
/// datasets of the scale, the stack count and three options. A data-only
/// update with the layout kept has the same counts, options, stacks and
/// visibility (Chart.js ADR 0074). With primitive data in each dataset, the
/// index value of each item is its index. So the ruler of the last data-only
/// update holds for each controller. A dataset with object data can move its
/// index values, also for the ruler of another dataset: then no ruler stays.
bool fastBarKeepsRulers(List<DatasetController> controllers) {
  if (controllers.length < 2) return false;
  for (final controller in controllers) {
    if (!controller.primitiveDataUpdate || controller.parsing == false) {
      return false;
    }
  }
  fastBarRulersKept++;
  return true;
}

final Type _nativeMetaList = <ChartMeta<DatasetController>?>[].runtimeType;

/// Whether the search of `_calculateBarIndexPixels` for the axes and the
/// stacks (`_getAxisCount`, `_getAxis`, `getFirstScaleIdForIndexAxis` and
/// `getStackIndex` with no data index) runs no user code for [controller] on
/// its index scale [scale].
///
/// Then one search gives the result of the search for each bar, as long as no
/// user code runs between the bars: the bulk loop has that property. This
/// function reads each container that the search reads, and it calls no
/// getter of an object of the user:
/// - the chart, the controller and the scale have the built-in reads;
/// - the chart option `indexAxis` is in the cache of the chart options;
/// - the config root, the data object, the dataset List and each dataset are
///   native containers with no route, and each axis id of the index axis is a
///   String or absent;
/// - each scale up to the first scale of the index axis has the built-in
///   reads, as in the proof of one dataset (Chart.js ADR 0068);
/// - the sorted metas are the List of the chart, with no hole;
/// - each visible bar meta of the scale has a built-in bar controller whose
///   option `grouped` is a cached bool (the meta field `stack` is a `String?`,
///   so each stack name is a primitive);
/// - the option `stacked` of the scale is a cached `StackMode` or absent.
///
/// The caller declines `skipNull` before (`cachedBulkBarOptions`): the search
/// then takes no data index.
bool fastBarSearchIsNative(DatasetController controller, IScale scale) {
  final owner = controller.chart;
  if (owner is! Chart ||
      !owner.supportsNativeBarIndexReads ||
      controller is! NativeBarIndexReads ||
      !(controller as NativeBarIndexReads).supportsNativeBarIndexReads ||
      scale is! NativeBarIndexReads ||
      !(scale as NativeBarIndexReads).supportsNativeBarIndexReads ||
      !identical(scale.chart, owner) ||
      !identical(controller.cachedMeta.iScale, scale)) {
    return false;
  }
  final Object options = owner.options;
  final Object config = owner.config;
  if (options.runtimeType != OptionView ||
      config.runtimeType != Config ||
      !(config as Config).supportsDataUpdates) {
    return false;
  }
  final axis = (options as OptionView).cachedBarIndexAxis;
  if (axis == null) return false;

  // `getFirstScaleIdForIndexAxis`: the scales up to the first match.
  final scales = owner.scales;
  var found = false;
  for (final key in jsObjectKeys(scales)) {
    final candidate = scales[key]!;
    if (!candidate.supportsNativeBarIndexReads) return false;
    if (sameAxis(candidate.axis, axis)) {
      found = true;
      break;
    }
  }
  if (!found) return false;

  // `_getAxis` and `_indexAxisIdOf`: the dataset objects of the user.
  final data = config.data;
  if (!nativeDataUpdateObject(data) ||
      (data is OptionScope && data.routeOf('datasets') != null)) {
    return false;
  }
  final datasets = dataUpdateField(data, 'datasets');
  if (!nativeDataUpdateList(datasets) || datasets is! List<Object?>) {
    return false;
  }
  final key = axis is XAxis ? 'xAxisID' : 'yAxisID';
  for (var i = 0; i < datasets.length; i++) {
    final dataset = datasets[i];
    if (dataset == null ||
        !nativeDataUpdateObject(dataset) ||
        (dataset is OptionScope && dataset.routeOf(key) != null)) {
      return false;
    }
    final id = dataUpdateField(dataset, key);
    if (!(id is String || identical(id, undefined))) return false;
  }

  // `_getStacks`: the visible bar metas of the scale and the two options.
  final metas = owner.sortedMetasets;
  if (metas.runtimeType != _nativeMetaList) return false;
  final type = controller.type;
  final horizontal = scale.axis is XAxis;
  if (!horizontal && scale.axis is! YAxis) return false;
  for (var i = 0; i < metas.length; i++) {
    final meta = metas[i];
    if (meta == null) return false;
    if (!meta.visible ||
        meta.type != type ||
        (horizontal ? meta.xAxisID : meta.yAxisID) != scale.id) {
      continue;
    }
    final other = meta.controller;
    if (other == null ||
        other is! NativeBarIndexReads ||
        !(other as NativeBarIndexReads).supportsNativeBarIndexReads) {
      return false;
    }
    final Object grouped = other.options;
    if (grouped.runtimeType != OptionView ||
        !(grouped as OptionView).hasCachedBarGrouping) {
      return false;
    }
  }
  final stacked = scale.options;
  return stacked is OptionView &&
      stacked.runtimeType == OptionView &&
      stacked.hasCachedBarStacking;
}
