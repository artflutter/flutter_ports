// Original code, not ported from Chart.js: guarded numeric category parsing.

import 'package:flutter_chartjs_port/src/core/data_update.dart'
    show nativeDataUpdateList;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/parsed.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

/// A category scale with ordinary, already-resolved label-source reads.
abstract interface class NativeCategoryParseScale() {
  /// Whether [labels] is still the native source used by ordinary parsing.
  bool supportsNativeCategoryParse(List<Object?> labels);
}

/// A scale whose number/null parsing has the built-in linear behavior.
abstract interface class NativeNumericParseScale() {
  /// Unknown subclasses keep their ordinary parse calls.
  bool get supportsNativeNumericParse;
}

/// A finite number as a double, or Dart `null`.
///
/// The type tests come first: `isFinite` and `toDouble()` on a num are calls
/// in an AOT build (performance.md §72). An int is always finite. On the web
/// each number is a double, so the first branch takes it.
@pragma('vm:prefer-inline')
@pragma('dart2js:prefer-inline')
@pragma('wasm:prefer-inline')
double? _finiteDouble(Object? value) {
  if (value is double) return value.isFinite ? value : null;
  // js-ok: only the VM and dart2wasm get here with a number, an int.
  return value is int ? value * 1.0 : null;
}

/// Parse a callback-free primitive range, or decline before creating records.
/// The caller has already performed its ordinary initial getLabels read.
/// No result or qualification is cached between calls, and records stay fresh.
List<ParsedItem>? tryParseNumericCategories(
  types.Scale iScale,
  types.Scale? vScale,
  List<Object?> labels,
  List<Object?> data,
  int start,
  int count,
) {
  if (iScale is! NativeCategoryParseScale ||
      vScale is! NativeNumericParseScale ||
      !(vScale! as NativeNumericParseScale).supportsNativeNumericParse ||
      !nativeDataUpdateList(data) ||
      !(iScale as NativeCategoryParseScale).supportsNativeCategoryParse(
        labels,
      ) ||
      !start.isFinite ||
      !count.isFinite ||
      start < 0 ||
      count <= 0 ||
      start != start.truncateToDouble() ||
      count != count.truncateToDouble() ||
      start + count > data.length) {
    return null;
  }
  final offset = start;
  final end = offset + count;
  // Preflight the whole native range: a late object must not run conversions
  // or mutate labels after an earlier item has bypassed its ordinary reads.
  for (var i = offset; i < end; i++) {
    final value = data[i];
    if (value is! num && value != null && !identical(value, undefined)) {
      return null;
    }
    if (i < labels.length) {
      final label = labels[i];
      if (label is! String && label != null && !identical(label, undefined)) {
        return null;
      }
    }
  }
  final iAxis = iScale.axis;
  final vAxis = vScale.axis;
  return List<ParsedItem>.generate(end - offset, (k) {
    final i = k + offset;
    final value = data[i];
    return ParsedItem.of(
      iAxis,
      i < labels.length && labels[i] is String ? i * 1.0 : null,
      vAxis,
      _finiteDouble(value),
    );
  });
}

/// Parse a callback-free numeric range with one scale on both axes, or decline
/// before creating records. The caller has already performed its ordinary
/// initial getLabels read, and the labels of this form are never parsed: the
/// value of the second key of the literal `{[iAxis]: true, [vAxis]: value}`
/// replaces the first. Records stay fresh, with one own key.
List<ParsedItem>? tryParseNumericSingleScale(
  types.Scale scale,
  List<Object?> data,
  int start,
  int count,
) {
  if (scale is! NativeNumericParseScale ||
      !(scale as NativeNumericParseScale).supportsNativeNumericParse ||
      !nativeDataUpdateList(data) ||
      !start.isFinite ||
      !count.isFinite ||
      start < 0 ||
      count <= 0 ||
      start != start.truncateToDouble() ||
      count != count.truncateToDouble() ||
      start + count > data.length) {
    return null;
  }
  final offset = start;
  final length = count;
  for (var i = offset, end = offset + length; i < end; i++) {
    final value = data[i];
    if (value is! num && value != null && !identical(value, undefined)) {
      return null;
    }
  }
  final axis = scale.axis;
  return List<ParsedItem>.generate(length, (i) {
    final value = data[i + offset];
    return ParsedItem()..setValue(axis, _finiteDouble(value));
  });
}
