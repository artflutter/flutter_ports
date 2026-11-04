// Original code, not ported from Chart.js: native point-option loop contracts.

import 'package:flutter_chartjs_port/src/core/data_update.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/option_scope.dart';
import 'package:flutter_chartjs_port/src/options/parsed.dart';
import 'package:flutter_chartjs_port/src/types/data_item.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

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

/// Qualifies each parsed item at its original iteration, before any conversion
/// can run user code. It never validates the whole dataset a second time.
/// Container implementation is cached by type; coordinate values stay live.
final class NativePointCoordinates {
  Type? _lastType;
  bool _nativeObject = false;

  /// True when x/y reads and their numeric conversions cannot call user code.
  bool accepts(Object? value) {
    if (value is ParsedItem) {
      return !value.hasForeign && _number(value.x) && _number(value.y);
    }
    if (value is TypedDataItem && nativeDataUpdatePoint(value)) {
      return _number(value.x) && _number(value.y);
    }
    if (value is! Map<String, Object?> && value is! OptionScope) return false;
    final type = value.runtimeType;
    if (type != _lastType) {
      _lastType = type;
      _nativeObject = nativeDataUpdateObject(value);
    }
    if (!_nativeObject) return false;
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
