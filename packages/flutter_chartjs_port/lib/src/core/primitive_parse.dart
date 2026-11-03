// Original code, not ported from Chart.js: guarded numeric category parsing.

import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/parsed.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

/// A category scale with ordinary, already-resolved label-source reads.
// A runtime capability, not a standalone operation.
// ignore: one_member_abstracts
abstract interface class NativeCategoryParseScale {
  /// Whether [labels] is still the native source used by ordinary parsing.
  bool supportsNativeCategoryParse(List<Object?> labels);
}

/// A scale whose number/null parsing has the built-in linear behavior.
abstract interface class NativeNumericParseScale {
  /// Unknown subclasses keep their ordinary parse calls.
  bool get supportsNativeNumericParse;
}

final _nativeLists = <Type>{
  <Object?>[].runtimeType,
  <Object>[].runtimeType,
  <num>[].runtimeType,
  <double>[].runtimeType,
  <int>[].runtimeType,
  List<Object?>.empty().runtimeType,
  List<Object>.empty().runtimeType,
  List<num>.empty().runtimeType,
  List<double>.empty().runtimeType,
  List<int>.empty().runtimeType,
  const <Object?>[].runtimeType,
  const <num>[].runtimeType,
  const <double>[].runtimeType,
  const <int>[].runtimeType,
};

/// Parse a callback-free primitive range, or decline before creating records.
/// The caller has already performed its ordinary initial getLabels read.
/// No result or qualification is cached between calls, and records stay fresh.
List<ParsedItem>? tryParseNumericCategories(
  types.Scale iScale,
  types.Scale? vScale,
  List<Object?> labels,
  List<Object?> data,
  double start,
  double count,
) {
  if (iScale is! NativeCategoryParseScale ||
      vScale is! NativeNumericParseScale ||
      !(vScale! as NativeNumericParseScale).supportsNativeNumericParse ||
      !_nativeLists.contains(data.runtimeType) ||
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
  final offset = start.toInt();
  final end = offset + count.toInt();
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
  final iKey = AxisKey.of(iAxis);
  final vKey = AxisKey.of(vAxis);
  final parsed = <ParsedItem>[];
  for (var i = offset; i < end; i++) {
    final value = data[i];
    parsed.add(
      ParsedItem.of(
        iKey,
        iAxis,
        i < labels.length && labels[i] is String ? i.toDouble() : null,
        vKey,
        vAxis,
        value is num && value.isFinite ? value.toDouble() : null,
      ),
    );
  }
  return parsed;
}
