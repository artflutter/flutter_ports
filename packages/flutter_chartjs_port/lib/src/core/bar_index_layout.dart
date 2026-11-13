// Original code, not ported from Chart.js: live native bar topology guards.

import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/raw_scope.dart';
import 'package:flutter_chartjs_port/src/options/scopes.g.dart';
import 'package:flutter_chartjs_port/src/types/chart_axis.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

/// Explicit contract for ordinary controller/scale metadata reads. Unknown
/// subclasses must retain their virtual methods and user getter behavior.
abstract interface class NativeBarIndexReads() {
  /// Whether index-layout metadata has the built-in read behavior.
  bool get supportsNativeBarIndexReads;
}

/// A chart that can prove the single-dataset axis/stack position at this
/// instant. The caller rechecks after option resolution; nothing is frozen.
abstract interface class SingleBarIndexSource() {
  /// True only when the axis count is one and axis/stack indices are zero.
  bool hasSingleBarIndexLayout(
    types.DatasetController controller,
    types.Scale scale,
  );
}

final _maps = <Type>{
  <String, Object?>{}.runtimeType,
  <String, Object>{}.runtimeType,
  <String, dynamic>{}.runtimeType,
  // DDC distinguishes literal maps and LinkedMap constructors.
  // ignore: prefer_collection_literals
  Map<String, Object?>().runtimeType,
  // Capture non-nullable LinkedMap implementations too.
  // ignore: prefer_collection_literals
  Map<String, Object>().runtimeType,
  // Capture dynamically typed LinkedMap implementations too.
  // ignore: prefer_collection_literals
  Map<String, dynamic>().runtimeType,
};
final _lists = <Type>{
  <Object?>[].runtimeType,
  <Object>[].runtimeType,
  <Map<String, Object?>>[].runtimeType,
  List<Object?>.empty().runtimeType,
  const <Object?>[].runtimeType,
};

/// Validate a container's implementation only when its identity changes.
/// Its contents, routes, list length and selected axis id are always live.
final class SingleBarDatasetSource(final Object _config) {
  /// The config object itself is retained by Config and cannot be replaced.
  this;

  final int _rootKind = _kind(_config, ChartConfigurationScope);
  Object? _data;
  int _dataKind = 0;
  Object? _datasets;
  bool _nativeList = false;
  Object? _dataset;
  int _datasetKind = 0;

  // 0 unknown, 1 exact scope, 2 native map. Runtime type is immutable;
  // caching this classification never caches a user value or route.
  static int _kind(Object? value, Type scopeType) {
    final type = value.runtimeType;
    return type == scopeType
        ? 1
        : _maps.contains(type)
        ? 2
        : 0;
  }

  /// No custom getter/list operator/route runs to qualify a fast path.
  bool read(CartesianAxis axis) {
    final Object? data;
    if (_rootKind == 1) {
      final scope = _config as ChartConfigurationScope;
      if (scope.routeOf('data') != null) return false;
      data = scope.dataCell?.raw;
    } else if (_rootKind == 2) {
      data = RawScope(_config as Map<String, Object?>).jsRead('data');
    } else {
      return false;
    }
    if (!identical(data, _data)) {
      _data = data;
      _datasets = null;
      _nativeList = false;
      _dataset = null;
      _datasetKind = 0;
      _dataKind = _kind(data, ChartDataScope);
    }
    final Object? datasets;
    if (_dataKind == 1) {
      final scope = data! as ChartDataScope;
      if (scope.routeOf('datasets') != null) return false;
      datasets = scope.datasetsCell?.raw;
    } else if (_dataKind == 2) {
      datasets = RawScope(data! as Map<String, Object?>).jsRead('datasets');
    } else {
      return false;
    }
    if (!identical(datasets, _datasets)) {
      _datasets = datasets;
      _dataset = null;
      _datasetKind = 0;
      _nativeList = _lists.contains(datasets.runtimeType);
    }
    if (!_nativeList) return false;
    final list = datasets! as List<Object?>;
    if (list.length != 1) return false;
    final dataset = list[0];
    if (!identical(dataset, _dataset)) {
      _dataset = dataset;
      _datasetKind = _kind(dataset, BarControllerDatasetOptionsScope);
    }
    final horizontal = axis is XAxis;
    final key = horizontal ? 'xAxisID' : 'yAxisID';
    final Object? id;
    if (_datasetKind == 1) {
      final scope = dataset! as BarControllerDatasetOptionsScope;
      if (scope.routeOf(key) != null) return false;
      final cell = horizontal ? scope.xAxisIDCell : scope.yAxisIDCell;
      id = cell == null ? undefined : cell.raw;
    } else if (_datasetKind == 2) {
      id = RawScope(dataset! as Map<String, Object?>).jsRead(key);
    } else {
      return false;
    }
    return id is String || identical(id, undefined);
  }
}

/// Only immutable key order is cached, never scale fields or option values.
/// The caller owns a native map and checks all its current keys on each read.
final class BarScaleKeys() {
  /// A new [BarScaleKeys].
  this;

  List<String> _insertion = const [];
  List<String> _ordered = const [];

  /// The current JS Object.keys order of the chart's native scale dictionary.
  List<String> read<T>(Map<String, T> scales) {
    var matches = scales.length == _insertion.length;
    if (matches) {
      var i = 0;
      for (final key in scales.keys) {
        if (key != _insertion[i++]) {
          matches = false;
          break;
        }
      }
    }
    if (!matches) {
      _insertion = List.of(scales.keys);
      _ordered = jsObjectKeys(scales);
    }
    return _ordered;
  }
}
