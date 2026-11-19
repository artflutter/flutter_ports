// Original code, not ported from Chart.js: guarded numeric category parsing.

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

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
  return value is int ? value * 1.0 : null;
}

/// The `_custom` of a floating bar from the two parse results of its pair:
/// the arithmetic of `parseFloatBar` after its two `vScale.parse` calls.
typedef FloatingBarOf = FloatingBar Function(double? start, double? end);

/// The outer Lists of floating pairs that a typed or a raw config gives, in
/// addition to the containers of [nativeDataUpdateList]. Only the exact
/// platform Lists: their reads run no user code.
final _pairLists = <Type>{
  <List<double>>[].runtimeType,
  <List<double>?>[].runtimeType,
  <List<num>>[].runtimeType,
  <List<num>?>[].runtimeType,
  <List<Object?>>[].runtimeType,
  <List<Object?>?>[].runtimeType,
  List<List<double>>.empty().runtimeType,
  List<List<num>>.empty().runtimeType,
  List<List<Object?>>.empty().runtimeType,
  const <List<double>>[].runtimeType,
  const <List<num>>[].runtimeType,
  const <List<Object?>>[].runtimeType,
};

/// Whether [value] is a floating pair `[start, end]` whose two parse calls of
/// the exact linear scale run no user code: a native List with at least two
/// items, and a number in each of the first two.
// DIVERGES(chartjs): adapt-native-floating-parse, the pair of numbers.
@pragma('vm:prefer-inline')
bool _nativePair(Object? value) {
  if (value is! List<Object?> || !nativeDataUpdateList(value)) return false;
  return value.length >= 2 && value[0] is num && value[1] is num;
}

/// Parse a callback-free primitive range, or decline before creating records.
/// The caller has already performed its ordinary initial getLabels read.
/// No result or qualification is cached between calls, and records stay fresh.
///
/// With [floatingBar], an item that is a pair of numbers (`[start, end]`,
/// `_nativePair`) also qualifies: its value is the `barEnd` of the
/// [FloatingBar] that [floatingBar] makes from the parse results of the two
/// numbers, and the record gets it as `_custom` after its two axis keys, in
/// the key order of `parseArrayOrPrimitive` (controller.bar.js:153-168).
List<ParsedItem>? tryParseNumericCategories(
  IScale iScale,
  IScale? vScale,
  List<Object?> labels,
  List<Object?> data,
  int start,
  int count, {
  FloatingBarOf? floatingBar,
}) {
  if (iScale is! NativeCategoryParseScale ||
      vScale is! NativeNumericParseScale ||
      !(vScale! as NativeNumericParseScale).supportsNativeNumericParse ||
      !(nativeDataUpdateList(data) ||
          (floatingBar != null && _pairLists.contains(data.runtimeType))) ||
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
  var pairs = false;
  for (var i = offset; i < end; i++) {
    final value = data[i];
    if (value is! num && value != null && !identical(value, undefined)) {
      if (floatingBar == null || !_nativePair(value)) return null;
      pairs = true;
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
  if (pairs) {
    return List<ParsedItem>.generate(end - offset, (k) {
      final i = k + offset;
      final value = data[i];
      final index = i < labels.length && labels[i] is String ? i * 1.0 : null;
      if (value is List<Object?>) {
        // The preflight proved a native pair of numbers.
        final bar = floatingBar!(
          _finiteDouble(value[0]),
          _finiteDouble(value[1]),
        );
        return ParsedItem.of(iAxis, index, vAxis, bar.barEnd)..custom = bar;
      }
      return ParsedItem.of(iAxis, index, vAxis, _finiteDouble(value));
    });
  }
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
  IScale scale,
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
