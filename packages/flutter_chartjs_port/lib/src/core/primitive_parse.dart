// Original code, not ported from Chart.js: guarded numeric category parsing.

import 'package:flutter_chartjs_port/src/core/data_update.dart'
    show nativeDataUpdateList;
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
  return List<ParsedItem>.generate(end - offset, (k) {
    final i = k + offset;
    final value = data[i];
    return ParsedItem.of(
      iKey,
      iAxis,
      i < labels.length && labels[i] is String ? i.toDouble() : null,
      vKey,
      vAxis,
      value is num && value.isFinite ? value.toDouble() : null,
    );
  });
}
