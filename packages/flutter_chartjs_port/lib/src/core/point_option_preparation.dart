// Original code, not ported from Chart.js: shared native point preparation.

import 'package:flutter_chartjs_port/src/core/core.config.dart' show Config;
import 'package:flutter_chartjs_port/src/core/core.datasetController.dart'
    show DatasetController;
import 'package:flutter_chartjs_port/src/core/data_update.dart'
    show nativeDataUpdateList;
import 'package:flutter_chartjs_port/src/core/point_options.dart';
import 'package:flutter_chartjs_port/src/elements/element_options.dart'
    show PointOptions;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:meta/meta.dart';

/// Prepare color reuse after the caller's exact-controller check and two
/// ordinary resolutions. The returned function belongs to one synchronous loop;
/// the caller must end reuse before active/custom points or foreign coordinates.
/// Reads retain their order: chart, owned arrays, class/index, then config.
@internal
PointOptions Function(int)? prepareNativePointColors(
  DatasetController controller,
  List<types.Element> points, {
  required String controllerType,
}) {
  final owner = controller.chart;
  if (!nativePointChart(owner) ||
      !identical(points, controller.cachedMeta.data) ||
      !nativePointList(points) ||
      !nativeDataUpdateList(controller.cachedMeta.parsed)) {
    return null;
  }
  final elementClass = controller.dataElementType;
  if (!nativePointClass(elementClass) ||
      !nativePointDatasetIndex(controller.index)) {
    return null;
  }
  final config = controller.chart.config;
  return config is Config && config.runtimeType == Config
      ? config.prepareIndexedPointColors(
          controller.index.toInt(),
          controllerType: controllerType,
        )
      : null;
}

/// Prepare a generation-checked line resolver after the exact-class check.
/// The controller's owner guard still runs before each use. The plan validates
/// its sources before context work. Config/resolver checks during callbacks
/// remain with the executor and must not be replaced with a one-time check.
@internal
NativePointResolution? prepareNativePointResolution(
  DatasetController controller,
) {
  if (!nativePointChart(controller.chart) ||
      controller.hasCachedPointNoneOptions) {
    return null;
  }
  final cls = controller.dataElementType;
  if (!nativePointClass(cls) || !nativePointDatasetIndex(controller.index)) {
    return null;
  }
  final config = controller.chart.config;
  return config is Config && config.runtimeType == Config
      ? config.prepareLineResolution(controller.index.toInt())
      : null;
}
