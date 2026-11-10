// Original code, not ported from Chart.js: shared native point preparation.

import 'package:flutter_chartjs_port/src/core/core.config.dart' show Config;
import 'package:flutter_chartjs_port/src/core/core.datasetController.dart'
    show DatasetController;
import 'package:flutter_chartjs_port/src/core/data_update.dart'
    show dataUpdateField, nativeDataUpdateList, nativeDataUpdateObject;
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

/// A context reader beside a prepared plan, for the same synchronous loop. It
/// reads the native data chain once, without routes, as the plan does; a chain
/// that does not qualify keeps the ordinary `getContext` of each point.
@internal
NativePointContextReader? prepareNativePointContexts(
  DatasetController controller,
  String mode,
) {
  if (!nativePointChart(controller.chart) ||
      !nativePointDatasetIndex(controller.index)) {
    return null;
  }
  final config = controller.chart.config;
  if (config is! Config ||
      config.runtimeType != Config ||
      !config.supportsDataUpdates) {
    return null;
  }
  final data = config.data;
  if (!nativeDataUpdateObject(data)) return null;
  final datasets = dataUpdateField(data, 'datasets');
  if (!nativeDataUpdateList(datasets)) return null;
  final list = datasets! as List<Object?>;
  final index = controller.index.toInt();
  if (index >= list.length) return null;
  final dataset = list[index];
  if (!nativeDataUpdateObject(dataset)) return null;
  final raw = dataUpdateField(dataset!, 'data');
  return nativeDataUpdateList(raw)
      ? NativePointContextReader.prepare(
          controller.cachedMeta,
          raw! as List<Object?>,
          mode,
        )
      : null;
}

/// The size fields of the frozen entry that `resolveDataElementOptions(index)`
/// would copy, after the caller's exact-controller check. With that entry the
/// ordinary resolve reads no chart, context or user value: it only copies it.
@internal
NativePointSizeFields? cachedNativePointSizeFields(
  DatasetController controller,
) => nativePointClass(controller.dataElementType)
    ? NativePointSizeFields.of(controller.cachedPointOptions('default'))
    : null;

/// The gap reads of one line or scatter loop (Chart.js ADR 0109), after the
/// caller's exact-controller check, or Dart `null`: then each pass reads
/// `prevParsed[iAxis]`.
///
/// These are the loop-wide guards: a direct update (no `updateElement`), no
/// stack and no `segment` (no `applyStack`, no read of the dataset), the axes
/// `x` and `y`, the chart of the controller with native reads (its pixel ratio
/// in `getPixelForDecimal`), the native linear projection of both scales on
/// that chart, a native list of points and a native parsed list. Each of these
/// stays for the loop: the classes do not change, and the loop reads its
/// locals. The live identity of the parsed list and the per-pass guards stay
/// with [NativeGapReads] and the loop.
@internal
NativeGapReads? prepareNativeGapReads(
  DatasetController controller,
  List<types.Element> points, {
  required bool directUpdate,
  required bool hasStack,
  required bool hasSegment,
  required types.Scale iScale,
  required types.Scale vScale,
  required double maxGapLength,
}) {
  if (!directUpdate || hasStack || hasSegment) return null;
  final chart = controller.chart;
  return _gapAxis(iScale.axis) &&
          _gapAxis(vScale.axis) &&
          nativePointChart(chart) &&
          nativePointProjection(iScale) &&
          identical(iScale.chart, chart) &&
          nativePointProjection(vScale) &&
          identical(vScale.chart, chart) &&
          nativePointList(points)
      ? NativeGapReads.of(controller.cachedMeta, maxGapLength)
      : null;
}

bool _gapAxis(String axis) => axis == 'x' || axis == 'y';

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
