// Original code, not ported from Chart.js: shared native arc preparation.

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// Prepare color reuse after the caller's exact-controller check. The result
/// exists only for a plan whose static fields are final and whose colors are
/// native, so that the options for each index differ in their colors only. It
/// belongs to one synchronous loop: the caller must end reuse before active or
/// custom arcs. Reads retain their order: chart, owned arrays, class/index,
/// then config. The chart, list and dataset-index predicates are the ones of
/// the point loops (Chart.js ADR 0087): the guarantees are the same.
ArcOptions Function(int)? prepareNativeArcColors(
  DatasetController controller,
  List<IElement> arcs,
) {
  final owner = controller.chart;
  if (!nativePointChart(owner) ||
      !identical(arcs, controller.cachedMeta.data) ||
      !nativePointList(arcs) ||
      !nativeDataUpdateList(controller.cachedMeta.parsed)) {
    return null;
  }
  final elementClass = controller.dataElementType;
  if (!nativeArcClass(elementClass) ||
      !nativePointDatasetIndex(controller.index)) {
    return null;
  }
  final config = controller.chart.config;
  return config is Config && config.runtimeType == Config
      ? config.prepareIndexedArcColors(
          controller.index,
          controllerType: controller.type,
        )
      : null;
}
