// Original code, not ported from Chart.js: native color value comparisons.

/// Native colors replace CSS scalar values in the Color-only port. These
/// comparisons leave identity semantics of all other JS objects unchanged.
library;

// Test-only access to the port's internal numerical color representation.
// ignore_for_file: implementation_imports, invalid_use_of_internal_member
import 'package:flutter_chartjs_port/src/options/prepared_color.dart';

/// Color value equality, or null when neither operand is a native color.
/// This is a test adaptation, not a parser or a chart-input conversion.
bool? equalColorValues(Object? a, Object? b) {
  final aChannels = a is PreparedColor ? a : nativeColorReader?.call(a);
  final bChannels = b is PreparedColor ? b : nativeColorReader?.call(b);
  if (aChannels == null && bChannels == null) return null;
  if (aChannels == null || bChannels == null) return false;
  if (a is! PreparedColor && b is! PreparedColor) return a == b;
  return aChannels == bChannels;
}
