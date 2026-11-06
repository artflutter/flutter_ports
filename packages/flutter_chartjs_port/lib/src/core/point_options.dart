// Original code, not ported from Chart.js: native point-option loop contracts.

import 'package:flutter_chartjs_port/src/core/bar_bulk_update.dart'
    show BulkBarScale;
import 'package:flutter_chartjs_port/src/core/core.element.dart' show Element;
import 'package:flutter_chartjs_port/src/core/data_update.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ScriptableContext;
import 'package:flutter_chartjs_port/src/js/js_class.dart' show JsClass;
import 'package:flutter_chartjs_port/src/js/js_number.dart' show jsTruthy;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGetIndex;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/element_options_base.dart'
    show ElementOptions;
import 'package:flutter_chartjs_port/src/options/option_scope.dart';
import 'package:flutter_chartjs_port/src/options/parsed.dart';
import 'package:flutter_chartjs_port/src/types/data_item.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:meta/meta.dart';

/// A chart whose config/data/context, metadata and DPR reads run no user code.
/// Unknown subclasses retain ordinary option resolution.
abstract interface class NativePointChart {
  /// True only for the built-in chart, or an explicit equivalent wrapper.
  bool get supportsNativePointOptions;
}

/// A chart that finds the meta of a dataset with no write (Chart.js ADR 0092).
// ignore: one_member_abstracts
abstract interface class DatasetMetaSource {
  /// The meta of `getDatasetMeta(datasetIndex)` when it has one, or Dart
  /// `null`. `getDatasetMeta` adds a meta for a dataset that has none.
  types.ChartMeta? existingDatasetMeta(num datasetIndex);
}

/// Native point size/context/property reads and writes, without user callbacks.
abstract interface class NativePointElement {
  /// Unknown subclasses must retain ordinary resolution, even if their typed
  /// property writes are enabled independently.
  bool get supportsNativePointOptions;
}

/// Read the chart capability at the current observation point. A previous
/// result does not authorize new config, context or metadata reads.
@internal
bool nativePointChart(Object? chart) =>
    chart is NativePointChart && chart.supportsNativePointOptions;

/// Read the point capability where the ordinary loop would use the point.
/// Active state is a separate live check: overflow does not require inactivity.
@internal
bool nativePointElement(Object? point) =>
    point is NativePointElement && point.supportsNativePointOptions;

/// The existing numeric-scale capability, without bar-specific grid checks.
/// Callers must check scale/chart ownership afterward, in the original order.
@internal
bool nativePointProjection(types.Scale scale) =>
    scale is BulkBarScale && (scale as BulkBarScale).supportsBulkBarUpdate;

/// Native class metadata only. Keep the two id reads and their short circuit;
/// unknown class objects are never inspected merely to qualify a shortcut.
@internal
bool nativePointClass(Object? value) =>
    value is JsClass && value.id is String && value.id == 'point';

/// A dataset index already read from an exact native controller.
@internal
bool nativePointDatasetIndex(double index) =>
    index.isFinite && index >= 0 && index == index.truncateToDouble();

/// Common line/scatter prerequisites over already-read loop inputs. This is
/// permission to attempt preparation, not a reusable proof about the dataset.
/// Point activity, coordinates, projections and source plans stay live.
@internal
bool canPrepareNativePointUpdate({
  required String mode,
  required Object? sharedOptions,
  required bool includeOptions,
  required Object? stacked,
  required Object? segment,
  required String iAxis,
  required String vAxis,
  required double start,
  required double count,
}) =>
    mode == 'none' &&
    sharedOptions == null &&
    includeOptions &&
    !jsTruthy(stacked) &&
    !jsTruthy(segment) &&
    (iAxis == 'x' || iAxis == 'y') &&
    (vAxis == 'x' || vAxis == 'y') &&
    start.isFinite &&
    start >= 0 &&
    start == start.truncateToDouble() &&
    count.isFinite &&
    count > 2 &&
    count == count.truncateToDouble();

final _pointLists = <Type>{
  <types.Element>[].runtimeType,
  List<types.Element>.empty().runtimeType,
  <types.PointElement>[].runtimeType,
  List<types.PointElement>.empty().runtimeType,
};

/// Only native list indexing may occur between prepared option reads.
bool nativePointList(List<types.Element> points) =>
    _pointLists.contains(points.runtimeType);

/// Weak identities of maps already accepted by the native container contract.
/// Values are never cached. Slots follow point indexes, and fill is bounded to
/// avoid allocating a weak reference for every point in replacement workloads.
@internal
final class NativePointCoordinateCache {
  List<WeakReference<Object>?> _maps = [];
  int _remaining = 0;

  /// Start one prepared loop, retaining only slots inside the current length.
  void prepare(int length) {
    _maps.length = length;
    _remaining = 1024;
  }

  /// Release the slot array when the prepared path is no longer eligible.
  void clear() {
    _maps = [];
    _remaining = 0;
  }

  /// Match by identity only, without equality, hashing or user property reads.
  /// A miss drops the old weak entry, including a collected target.
  bool contains(Object? value, int index) {
    if (index < 0 || index >= _maps.length) return false;
    final entry = _maps[index];
    if (entry != null && identical(entry.target, value) && value != null) {
      return true;
    }
    _maps[index] = null;
    return false;
  }

  void _remember(Object value, int index) {
    if (_remaining == 0 || index < 0 || index >= _maps.length) return;
    _maps[index] = WeakReference(value);
    _remaining--;
  }
}

/// Qualifies each parsed item at its original iteration, before any conversion
/// can run user code. It never validates the whole dataset a second time.
/// Container implementation is cached by type; coordinate values stay live.
final class NativePointCoordinates {
  /// Classifier state belongs to this loop; only proven map identities survive.
  NativePointCoordinates({this.cache});

  /// Controller-owned storage, enabled after a native color plan exists.
  final NativePointCoordinateCache? cache;
  Type? _lastType;
  bool _nativeObject = false;

  /// True when x/y reads and their numeric conversions cannot call user code.
  bool accepts(Object? value, [int? index]) {
    if (value is ParsedItem) {
      return !value.hasForeign && _number(value.x) && _number(value.y);
    }
    if (value is TypedDataItem && nativeDataUpdatePoint(value)) {
      return _number(value.x) && _number(value.y);
    }
    if (value is! Map<String, Object?> && value is! OptionScope) return false;
    final known = index != null && (cache?.contains(value, index) ?? false);
    if (known) {
      // The preceding native map must not leave an older custom type in the
      // loop-local classifier. Its next observation still takes ordinary reads.
      _lastType = null;
      _nativeObject = false;
    } else {
      final type = value.runtimeType;
      if (type != _lastType) {
        _lastType = type;
        _nativeObject = nativeDataUpdateObject(value);
      }
      if (!_nativeObject) return false;
      if (index != null && value is Map<String, Object?>) {
        cache?._remember(value, index);
      }
    }
    if (value is OptionScope &&
        (value.routeOf('x') != null || value.routeOf('y') != null)) {
      return false;
    }
    return _number(dataUpdateField(value!, 'x')) &&
        _number(dataUpdateField(value, 'y'));
  }
}

bool _number(Object? value) =>
    value == null || value is Undefined || value is num;

/// A loop-local resolution over native sources. The validator must run before
/// every scope shortcut. Its context shortcut is used only in a proven native
/// resolver window; ordinary fallback keeps the ordinary context factory.
@internal
final class NativePointResolution {
  NativePointResolution({
    required this.data,
    required this.raw,
    required this.valid,
    required this._resolve,
  });
  final Object data;
  final List<Object?> raw;

  /// Diagnostic source check; [resolve] always invokes it itself.
  final bool Function() valid;
  final ElementOptions? Function(Object Function(), Object Function()?)
  _resolve;

  /// Revalidate before touching contexts or resolving options. The executor
  /// still owns its finer-grained generation checks during user callbacks.
  ElementOptions? resolve(
    Object Function() context,
    Object Function()? preparedContext,
  ) {
    if (!valid()) return null;
    return _resolve(context, preparedContext);
  }
}

/// Existing context refresh over captured native arrays. It never creates a
/// context, reads coordinate properties, or skips the ordinary typed setters.
@internal
final class NativePointContextReader {
  NativePointContextReader._(
    this._meta,
    this._points,
    this._parsed,
    this._raw,
    this._mode,
  );
  final types.ChartMeta _meta;
  final List<types.Element> _points;
  final List<Object?> _parsed;
  final List<Object?> _raw;
  final String _mode;

  static NativePointContextReader? prepare(
    types.ChartMeta meta,
    List<Object?> raw,
    String mode,
  ) {
    final points = meta.data;
    final parsed = meta.parsed;
    if (!nativePointList(points) ||
        !nativeDataUpdateList(parsed) ||
        !nativeDataUpdateList(raw)) {
      return null;
    }
    return NativePointContextReader._(meta, points, parsed, raw, mode);
  }

  ScriptableContext? read(int index) {
    if (!identical(_meta.data, _points) ||
        !identical(_meta.parsed, _parsed) ||
        index < 0 ||
        index >= _points.length) {
      return null;
    }
    final element = _points[index];
    if (element is! Element || !nativePointElement(element)) {
      return null;
    }
    final context = element.$context;
    if (context is! ScriptableContext) return null;
    final value = index.toDouble();
    return context
      ..parsed = jsGetIndex(_parsed, value)
      ..raw = jsGetIndex(_raw, value)
      ..dataIndex = value
      ..index = value
      ..active = false
      ..mode = _mode;
  }
}
