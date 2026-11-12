// Original code, not ported from Chart.js: incremental data-update contracts.

import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:flutter_chartjs_port/src/core/core.defaults.dart' show defaults;
import 'package:flutter_chartjs_port/src/helpers/cubic_interpolation_mode.dart'
    show CubicInterpolationMode;
import 'package:flutter_chartjs_port/src/helpers/point_style.dart'
    show PointStyle;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/option_scope.dart';
import 'package:flutter_chartjs_port/src/options/parsed.dart';
import 'package:flutter_chartjs_port/src/options/raw_scope.dart';
import 'package:flutter_chartjs_port/src/types/data_item.dart';
import 'package:meta/meta.dart';

final _maps = <Type>{
  <String, Object?>{}.runtimeType, <String, Object>{}.runtimeType,
  <String, dynamic>{}.runtimeType, <String, double>{}.runtimeType,
  <String, num>{}.runtimeType, <String, int>{}.runtimeType,
  <String, bool>{}.runtimeType, <String, String>{}.runtimeType,
  // DDC has distinct constructor implementations.
  // ignore: prefer_collection_literals
  Map<String, Object?>().runtimeType,
  // Include the dynamic constructor representation on DDC too.
  // ignore: prefer_collection_literals
  Map<String, dynamic>().runtimeType,
};
final Set<Type> _scopes = {
  for (final kind in ScopeKind.values) kind.create().runtimeType,
};
final _lists = <Type>{
  <Object?>[].runtimeType,
  <dynamic>[].runtimeType,
  <Object>[].runtimeType,
  <num>[].runtimeType,
  <num?>[].runtimeType,
  <double>[].runtimeType,
  <double?>[].runtimeType,
  <int>[].runtimeType,
  <int?>[].runtimeType,
  <String>[].runtimeType,
  <Color>[].runtimeType,
  <Color?>[].runtimeType,
  <Map<String, Object?>>[].runtimeType,
  <Map<String, double>>[].runtimeType,
  <ParsedItem>[].runtimeType,
  List<Object?>.empty().runtimeType,
  List<dynamic>.empty().runtimeType,
  List<Object>.empty().runtimeType,
  List<num?>.empty().runtimeType,
  List<int?>.empty().runtimeType,
  List<Map<String, Object?>>.empty().runtimeType,
  List<Map<String, double>>.empty().runtimeType,
  List<ParsedItem>.empty().runtimeType,
  List<double>.empty().runtimeType,
  List<double?>.empty().runtimeType,
  List<num>.empty().runtimeType,
  List<int>.empty().runtimeType,
  List<String>.empty().runtimeType,
  const <Object?>[].runtimeType,
  const <dynamic>[].runtimeType,
  const <num?>[].runtimeType,
  const <double?>[].runtimeType,
  const <int?>[].runtimeType,
  const <double>[].runtimeType,
  const <num>[].runtimeType,
  const <int>[].runtimeType,
  const <String>[].runtimeType,
  // A const style List of a raw config (Chart.js ADR 0100).
  const <Object>[].runtimeType,
  const <Color>[].runtimeType,
  const <Color?>[].runtimeType,
};
final _points = <Type>{};

/// Typed lowering registers only standard containers and immutable point types.
@internal
void registerDataUpdateTypes(Iterable<Type> lists, Iterable<Type> points) {
  _lists.addAll(lists);
  _points.addAll(points);
}

/// No custom Map/scope getters run merely to qualify the new lifecycle.
@internal
bool nativeDataUpdateObject(Object? value) =>
    _maps.contains(value.runtimeType) || _scopes.contains(value.runtimeType);

/// A scope of a resolver whose reads by key run no user code: a native object
/// or the root of the defaults. A custom Map or a subclass of a scope class can
/// run any code in a read.
@internal
bool nativeOptionScope(Object? value) =>
    nativeDataUpdateObject(value) || identical(value, defaults);

/// Root routes could run callbacks during metadata checks.
@internal
bool nativeDataUpdateRoot(Object value) =>
    nativeDataUpdateObject(value) &&
    (value is! OptionScope ||
        [
          'data',
          'options',
          'plugins',
        ].every((key) => value.routeOf(key) == null));

/// Native container eligibility, including the typed facade's point lists.
@internal
bool nativeDataUpdateList(Object? value) =>
    _lists.contains(value.runtimeType) || value is TypedDataList<num>;

/// Immutable point implementations registered by the typed facade.
@internal
bool nativeDataUpdatePoint(TypedDataItem value) =>
    _points.contains(value.runtimeType);

/// Read only after native object qualification; routes cannot qualify.
@internal
Object? dataUpdateField(Object object, String key) {
  if (object is OptionScope) {
    if (object.routeOf(key) != null) return undefined;
    final cell = object.ownCell(key);
    return cell == null ? undefined : cell.raw;
  }
  return RawScope(object as Map<String, Object?>).jsRead(key);
}

Iterable<String> _keys(Object object) => object is OptionScope
    ? object.ownKeys.map((key) => key is OptionKey ? key.jsName : key as String)
    : (object as Map<String, Object?>).keys;

/// Static user settings only. Scale settings are frozen by the separate native
/// scale contract; event handlers remain live and are not layout/style inputs.
@internal
bool staticDataUpdateOptions(Object? value, {bool dataset = false}) {
  final seen = HashSet<Object>.identity();
  bool visit(Object? node, Set<String> skip) {
    if (node == null ||
        node is Undefined ||
        node is num ||
        node is bool ||
        node is String ||
        node is Enum ||
        node is PointStyle ||
        node is CubicInterpolationMode ||
        node.runtimeType == Color) {
      return true;
    }
    if (!seen.add(node)) return false;
    try {
      if (nativeDataUpdateList(node)) {
        return (node as List<Object?>).every((v) => visit(v, const {}));
      }
      if (!nativeDataUpdateObject(node)) return false;
      for (final key in _keys(node)) {
        if (skip.contains(key) || key == 'onClick' || key == 'onHover') {
          continue;
        }
        if (node is OptionScope && node.routeOf(key) != null) return false;
        if (!visit(dataUpdateField(node, key), const {})) return false;
      }
      return true;
    } finally {
      seen.remove(node);
    }
  }

  return visit(value, dataset ? const {'data'} : const {'scales'});
}

bool _number(Object? value) =>
    value == null || value is Undefined || value is num;

bool _numericPoint(TypedDataItem point) =>
    _number(point.x) && _number(point.y) && _number(point.r);

/// The fields read by native default parsers. Custom parsing keys fall back.
@internal
enum DataUpdateShape { cartesian, bubble, radial, scalar }

/// Preflight values without executing user conversions. Null means fallback;
/// true means primitive numeric data, false means supported structured data.
@internal
bool? dataUpdateValues(
  Object? source, {
  DataUpdateShape shape = DataUpdateShape.cartesian,
  bool prepared = false,
}) {
  if (!nativeDataUpdateList(source)) return null;
  var primitive = true;
  Type? mapType;
  Type? pointType;
  for (final item in source! as List<Object?>) {
    if (_number(item)) continue;
    primitive = false;
    if (item.runtimeType == pointType) {
      // The class of the last point: no set lookups for a list of one class.
      if (!_numericPoint(item! as TypedDataItem)) return null;
    } else if (item is ParsedItem) {
      if (item.hasForeign ||
          item.hasSlot(3) ||
          item.hasSlot(4) ||
          !_number(item.x) ||
          !_number(item.y) ||
          !_number(item.r)) {
        return null;
      }
    } else if (item.runtimeType == mapType ||
        _maps.contains(item.runtimeType)) {
      mapType = item.runtimeType;
      // The map is native. Read only fields consumed by default parsers;
      // unrelated attributes need not be walked or converted.
      final map = item! as Map<String, Object?>;
      final valid = switch (shape) {
        DataUpdateShape.cartesian => _number(map['x']) && _number(map['y']),
        DataUpdateShape.bubble =>
          _number(map['x']) &&
              _number(map['y']) &&
              _number(map[prepared ? '_custom' : 'r']),
        DataUpdateShape.radial => _number(map['r']),
        DataUpdateShape.scalar => _number(map['value']),
      };
      if (!valid ||
          (prepared &&
              (!_number(map['_custom']) || !_number(map['_stacks'])))) {
        return null;
      }
    } else if (_points.contains(item.runtimeType)) {
      pointType = item.runtimeType;
      if (!_numericPoint(item! as TypedDataItem)) return null;
    } else if (nativeDataUpdateList(item)) {
      if (!(item! as List<Object?>).every(_number)) return null;
    } else {
      return null;
    }
  }
  return primitive;
}

/// The last full configuration generation. Data arrays may be replaced while
/// dataset identities, counts and label containers stay stable. In-place edits
/// to options/labels are explicitly outside updateData's caller contract.
@internal
final class DataUpdateSnapshot {
  DataUpdateSnapshot._(
    this.data,
    this.options,
    this.datasets,
    this.labels,
    this.counts,
  );
  final Object data;
  final Object options;
  final List<Object> datasets;
  final List<({Object? source, int length})> labels;
  final List<int> counts;

  List<Object?>? _validatedSources;
  List<bool?>? _primitiveSources;

  /// The API declares numeric-value-only mutation within an existing source.
  /// A replacement array is checked again; record/key/type changes in place
  /// require a full update, just like configuration and label changes.
  bool? validateValues(
    int index,
    DataUpdateShape shape, {
    required bool prepared,
  }) {
    final source = dataUpdateField(datasets[index], 'data');
    final sources = _validatedSources ??= List<Object?>.filled(
      datasets.length,
      null,
    );
    final primitive = _primitiveSources ??= List<bool?>.filled(
      datasets.length,
      null,
    );
    if (identical(source, sources[index])) return primitive[index];
    final result = dataUpdateValues(source, shape: shape, prepared: prepared);
    if (result != null) {
      sources[index] = source;
      primitive[index] = result;
    }
    return result;
  }

  bool settingsValidated = false;

  /// Full updates record identity/count tokens; settings are checked lazily.
  bool validateSettings() {
    if (settingsValidated) return true;
    if (!staticDataUpdateOptions(options) ||
        !datasets.every((d) => staticDataUpdateOptions(d, dataset: true))) {
      return false;
    }
    settingsValidated = true;
    return true;
  }

  static DataUpdateSnapshot? capture(Object data, Object options) {
    if (!nativeDataUpdateObject(data) || !nativeDataUpdateObject(options)) {
      return null;
    }
    if (data is OptionScope &&
        [
          'datasets',
          'labels',
          'xLabels',
          'yLabels',
        ].any((key) => data.routeOf(key) != null)) {
      return null;
    }
    final raw = dataUpdateField(data, 'datasets');
    if (!nativeDataUpdateList(raw)) return null;
    final datasets = <Object>[];
    final counts = <int>[];
    for (final dataset in raw! as List<Object?>) {
      if (!nativeDataUpdateObject(dataset)) {
        return null;
      }
      final values = dataUpdateField(dataset!, 'data');
      if (!nativeDataUpdateList(values)) return null;
      datasets.add(dataset);
      counts.add((values! as List<Object?>).length);
    }
    final labels = <({Object? source, int length})>[];
    for (final key in ['labels', 'xLabels', 'yLabels']) {
      final value = dataUpdateField(data, key);
      if (value != null &&
          value is! Undefined &&
          !nativeDataUpdateList(value)) {
        return null;
      }
      labels.add((source: value, length: value is List ? value.length : 0));
    }
    return DataUpdateSnapshot._(data, options, datasets, labels, counts);
  }

  bool matches(Object currentData, Object currentOptions) {
    if (!identical(data, currentData) || !identical(options, currentOptions)) {
      return false;
    }
    final raw = dataUpdateField(data, 'datasets');
    if (!nativeDataUpdateList(raw)) return false;
    final current = raw! as List<Object?>;
    if (current.length != datasets.length) return false;
    for (var i = 0; i < current.length; i++) {
      if (!identical(current[i], datasets[i])) return false;
      final values = dataUpdateField(datasets[i], 'data');
      if (!nativeDataUpdateList(values) ||
          (values! as List).length != counts[i]) {
        return false;
      }
    }
    var i = 0;
    for (final key in ['labels', 'xLabels', 'yLabels']) {
      final value = dataUpdateField(data, key);
      final saved = labels[i++];
      if (!identical(value, saved.source) ||
          (value is List && value.length != saved.length)) {
        return false;
      }
    }
    return true;
  }
}

/// The second capture of the last full update for `Chart.updateRanges`
/// (Chart.js ADR 0111, check 6): the `data` and `options` objects of the
/// config and the dataset objects, read with [dataUpdateField] from native
/// objects only, the chart type and the inline plugins of the config.
/// Unlike [DataUpdateSnapshot], it keeps no value List and no labels: a
/// range update parses the data as `update` does, so new values, a new data
/// List and new labels are allowed.
@internal
final class RangeUpdateSnapshot {
  RangeUpdateSnapshot._(
    this.data,
    this.options,
    this.datasets,
    this.type,
    this.plugins,
    this.pluginCount,
  );

  /// The `data` object of the config.
  final Object data;

  /// The `options` object of the config.
  final Object options;

  /// The dataset objects, in their order.
  final List<Object> datasets;

  /// The chart type of the config (`config.type`).
  final Object? type;

  /// The inline plugins of the config (`config.plugins`): a List, or another
  /// value.
  final Object? plugins;

  /// The length of [plugins] when it is a List, else -1.
  final int pluginCount;

  /// The capture of [data] and [options], or null when one of them, the
  /// dataset List or a dataset is not a native object, or when a route of the
  /// typed data scope could run code in a read. [type] and [plugins] are the
  /// chart type and the inline plugins of the config.
  static RangeUpdateSnapshot? capture(
    Object data,
    Object options, {
    required Object? type,
    required Object? plugins,
  }) {
    if (!nativeDataUpdateObject(data) || !nativeDataUpdateObject(options)) {
      return null;
    }
    if (data is OptionScope && data.routeOf('datasets') != null) return null;
    final raw = dataUpdateField(data, 'datasets');
    if (!nativeDataUpdateList(raw)) return null;
    final datasets = <Object>[];
    for (final dataset in raw! as List<Object?>) {
      if (!nativeDataUpdateObject(dataset)) return null;
      datasets.add(dataset!);
    }
    return RangeUpdateSnapshot._(
      data,
      options,
      datasets,
      type,
      plugins,
      plugins is List<Object?> ? plugins.length : -1,
    );
  }

  /// Whether [currentData] and [currentOptions] are the captured objects,
  /// with the same count of datasets and the same object at each index, and
  /// whether [type] equals the captured type and [plugins] is the captured
  /// value, a List of the same length.
  bool matches(
    Object currentData,
    Object currentOptions, {
    required Object? type,
    required Object? plugins,
  }) {
    if (!identical(data, currentData) || !identical(options, currentOptions)) {
      return false;
    }
    if (type != this.type || !identical(plugins, this.plugins)) return false;
    if (plugins is List<Object?> && plugins.length != pluginCount) {
      return false;
    }
    final raw = dataUpdateField(data, 'datasets');
    if (!nativeDataUpdateList(raw)) return false;
    final current = raw! as List<Object?>;
    if (current.length != datasets.length) return false;
    for (var i = 0; i < current.length; i++) {
      if (!identical(current[i], datasets[i])) return false;
    }
    return true;
  }
}
