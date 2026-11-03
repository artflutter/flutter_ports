// Original code, not ported from Chart.js: guarded native category label reads.

import 'package:flutter_chartjs_port/src/js/js_number.dart' show jsTruthy;
import 'package:flutter_chartjs_port/src/options/raw_scope.dart';
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show ChartConfigurationScope, ChartDataScope;

/// Internal host contract: its data/config getters have ordinary read behavior.
/// Unknown Chart subclasses do not opt in, preserving effectful getter reads.
// A capability checked at runtime, not a standalone operation.
// ignore: one_member_abstracts
abstract interface class CategoryLabelSource {
  /// The native label list, or null when bulk reads cannot be proven safe.
  List<Object?>? categoryLabels(
    Object? explicitLabels, {
    required bool horizontal,
  });
}

final Set<Type> _mapTypes = {
  <String, Object?>{}.runtimeType,
  <String, Object>{}.runtimeType,
  <String, dynamic>{}.runtimeType,
  // DDC distinguishes literal, non-literal and identity Map implementations.
  // Explicit constructors are essential here; literals alone omit LinkedMap.
  // ignore: prefer_collection_literals
  Map<String, Object?>().runtimeType,
  // Capture the non-literal implementation for non-nullable values too.
  // ignore: prefer_collection_literals
  Map<String, Object>().runtimeType,
  // Capture the non-literal implementation for dynamically typed values too.
  // ignore: prefer_collection_literals
  Map<String, dynamic>().runtimeType,
  Map<String, Object?>.identity().runtimeType,
  Map<String, Object>.identity().runtimeType,
  Map<String, dynamic>.identity().runtimeType,
};

final Set<Type> _listTypes = {
  <Object?>[].runtimeType,
  <Object>[].runtimeType,
  <String>[].runtimeType,
  List<Object?>.empty().runtimeType,
  List<String>.empty().runtimeType,
  const <Object?>[].runtimeType,
  const <String>[].runtimeType,
};

/// Probe only ordinary native containers. A custom Map/List and typed scopes
/// with potential routes keep the per-label path. No user getter is evaluated
/// to decide whether a custom container is safe.
List<Object?>? nativeCategoryLabels(
  Object config,
  Object? explicitLabels, {
  required bool horizontal,
}) {
  final Object? data;
  if (config.runtimeType == ChartConfigurationScope) {
    final root = config as ChartConfigurationScope;
    if (root.routeOf('data') != null) return null;
    data = root.dataCell?.raw;
  } else if (_mapTypes.contains(config.runtimeType)) {
    data = RawScope(config as Map<String, Object?>).jsRead('data');
  } else {
    return null;
  }
  final Object? axisLabels;
  final Object? ordinary;
  if (data.runtimeType == ChartDataScope) {
    final scope = data! as ChartDataScope;
    if (scope.routeOf(horizontal ? 'xLabels' : 'yLabels') != null ||
        scope.routeOf('labels') != null) {
      return null;
    }
    axisLabels = horizontal ? scope.xLabelsCell?.raw : scope.yLabelsCell?.raw;
    ordinary = scope.labelsCell?.raw;
  } else if (_mapTypes.contains(data.runtimeType)) {
    final raw = RawScope(data! as Map<String, Object?>);
    axisLabels = raw.jsRead(horizontal ? 'xLabels' : 'yLabels');
    ordinary = raw.jsRead('labels');
  } else {
    return null;
  }
  final labels = jsTruthy(explicitLabels)
      ? explicitLabels
      : jsTruthy(axisLabels)
      ? axisLabels
      : ordinary;
  return _listTypes.contains(labels.runtimeType)
      ? labels! as List<Object?>
      : null;
}
