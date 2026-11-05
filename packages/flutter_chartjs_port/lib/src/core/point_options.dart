// Original code, not ported from Chart.js: native point-option loop contracts.

import 'package:flutter_chartjs_port/src/core/core.element.dart' show Element;
import 'package:flutter_chartjs_port/src/core/data_update.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ScriptableContext;
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

/// Native point size/context/property reads and writes, without user callbacks.
abstract interface class NativePointElement {
  /// Unknown subclasses must retain ordinary resolution, even if their typed
  /// property writes are enabled independently.
  bool get supportsNativePointOptions;
}

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
    required this.resolve,
  });
  final Object data;
  final List<Object?> raw;
  final bool Function() valid;
  final ElementOptions? Function(Object Function(), Object Function()?) resolve;
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
    if (element is! Element ||
        element is! NativePointElement ||
        !(element as NativePointElement).supportsNativePointOptions) {
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
