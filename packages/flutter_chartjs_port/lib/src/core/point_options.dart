// Original code, not ported from Chart.js: native point-option loop contracts.

import 'package:flutter_chartjs_port/src/core/bar_bulk_update.dart'
    show BulkBarScale;
import 'package:flutter_chartjs_port/src/core/core.element.dart' show Element;
import 'package:flutter_chartjs_port/src/core/data_update.dart';
import 'package:flutter_chartjs_port/src/elements/element_options.dart'
    show PointOptions, plainOption;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ScriptableContext;
import 'package:flutter_chartjs_port/src/js/js_class.dart' show JsClass;
import 'package:flutter_chartjs_port/src/js/js_math.dart' show jsMax;
import 'package:flutter_chartjs_port/src/js/js_number.dart' show jsTruthy;
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

/// The truthiness of a number with no foreign value: not 0 and not NaN.
bool _truthy(double value) => value != 0 && !value.isNaN;

/// element.point.ts:81-87 `size` over plain numbers: the `||` and `&&` of
/// upstream on numbers, with no box. The plain branch of `PointElement.size`
/// and the native overflow loops share it.
@internal
@pragma('vm:prefer-inline')
@pragma('dart2js:prefer-inline')
@pragma('wasm:prefer-inline')
double nativePointSize(double radius, double hoverRadius, double borderWidth) {
  final r = _truthy(radius) ? radius : 0.0;
  final biggest = jsMax(
    r,
    _truthy(r) && _truthy(hoverRadius) ? hoverRadius : 0,
  );
  final width = _truthy(biggest) && _truthy(borderWidth) ? borderWidth : 0.0;
  return (biggest + width) * 2;
}

/// The three plain fields that `size` reads, taken once from one options object
/// inside one synchronous native loop. Absent or foreign values decline: their
/// JS conversions stay with the ordinary options object and `size`.
@internal
final class NativePointSizeFields {
  NativePointSizeFields._(this.radius, this.hoverRadius, this.borderWidth);

  /// The fields of [options], or Dart `null` unless all three are plain.
  static NativePointSizeFields? of(Object? options) =>
      options is PointOptions &&
          plainOption(options, OptionKey.radius) &&
          plainOption(options, OptionKey.hoverRadius) &&
          plainOption(options, OptionKey.borderWidth)
      ? NativePointSizeFields._(
          options.radius,
          options.hoverRadius,
          options.borderWidth,
        )
      : null;

  /// `options.radius`.
  final double radius;

  /// `options.hoverRadius`.
  final double hoverRadius;

  /// `options.borderWidth`.
  final double borderWidth;
}

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

/// One loop's classifier of typed data items: the implementation class is
/// cached by type, and the fields of an item stay live.
@internal
final class NativeTypedItems {
  Type? _lastType;
  bool _native = false;

  /// True for an immutable point class that the typed facade registered.
  bool accepts(TypedDataItem value) {
    final type = value.runtimeType;
    if (type != _lastType) {
      _lastType = type;
      _native = nativeDataUpdatePoint(value);
    }
    return _native;
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
  final NativeTypedItems _typedItems = NativeTypedItems();
  Type? _lastType;
  bool _nativeObject = false;

  /// True when x/y reads and their numeric conversions cannot call user code.
  bool accepts(Object? value, [int? index]) {
    if (value is ParsedItem) {
      return !value.hasForeign && _number(value.x) && _number(value.y);
    }
    if (value is TypedDataItem && _typedItems.accepts(value)) {
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
/// context or reads coordinate properties. Its writes are those of `getContext`
/// on a data context, of any element class: the capability check of [read] is
/// for points, and a loop over other elements calls [readQualified].
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

  bool get _sourcesLive =>
      identical(_meta.data, _points) && identical(_meta.parsed, _parsed);

  /// The refresh of the context of the point at [index], or Dart `null` for the
  /// ordinary `getContext`: changed sources, a custom point, or a context that
  /// does not exist.
  ScriptableContext? read(int index) {
    if (!_sourcesLive || index < 0 || index >= _points.length) return null;
    final element = _points[index];
    return nativePointElement(element) ? _refresh(element, index) : null;
  }

  /// [read] for the [element] at [index] of the native list of a loop that has
  /// read its capability at this iteration, so that no second read is needed.
  ScriptableContext? readQualified(types.Element element, int index) =>
      _sourcesLive ? _refresh(element, index) : null;

  ScriptableContext? _refresh(types.Element element, int index) {
    if (element is! Element) return null;
    final context = element.$context;
    if (context is! ScriptableContext) return null;
    // The lists are native: [prepare] proved their classes. An index past the
    // end of one gives `undefined`, as `jsGetIndex` and `getParsed` do.
    final parsed = _parsed;
    final raw = _raw;
    return context..refresh(
      index < parsed.length ? parsed[index] : undefined,
      index < raw.length ? raw[index] : undefined,
      index.toDouble(),
      false,
      _mode,
    );
  }
}
