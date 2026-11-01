// Original code, not ported from Chart.js: native inputs for upstream fixtures.

/// Frozen upstream fixtures contain CSS colors. This test-only adapter decodes
/// their inputs before invoking the Color-only chart API. Production charts do
/// not import this module; their string rejection remains enabled.
library;

// Test-only access to the native color bridge.
// Callback arity must remain explicit for the observation oracle.
// ignore_for_file: implementation_imports, avoid_types_on_closure_parameters
import 'package:chartjs_test_utils/src/color_reference.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_colors.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/options/prepared_color.dart';

final _callbacks = Expando<Object>('fixture native color callback');

bool _isColor(String key) =>
    key == 'color' ||
    key == 'multiKeyBackground' ||
    key == 'above' ||
    key == 'below' ||
    key.endsWith('Color') ||
    key == 'fillStyle' ||
    key == 'strokeStyle' ||
    key == r'$borderColors' ||
    key == r'$backgroundColors';

/// Migrates color options, leaving data, labels and ordinary text intact.
void nativeFixtureColors(Object? config) {
  installNativeColorCodec();
  final seen = Set<Object>.identity();
  Object? color(Object? value) {
    // Upstream uses false/empty colors to suppress a stroke.
    if (value == false) return null;
    if (value is String) {
      if (value.isEmpty) return null;
      final parsed = referenceColor(value);
      if (!parsed.valid) return value;
      final rgb = parsed.rgbaBytes!;
      return PreparedColor(
        rgb.r.round(),
        rgb.g.round(),
        rgb.b.round(),
        rgb.a / 255,
      ).paint;
    }
    if (value is List) return <Object?>[for (final item in value) color(item)];
    if (value is JsFunction || value is Function) {
      final existing = _callbacks[value!];
      if (existing != null) return existing;
      final fn = value is JsFunction ? value.function : value as Function;
      final self = value is JsFunction;
      Object? invoke(List<Object?> args) => color(
        jsCall(
          value,
          self ? args.skip(1).toList() : args,
          thisArg: self && args.isNotEmpty ? args.first : null,
        ),
      );
      final Function wrapper;
      if (fn is Object? Function()) {
        wrapper = () => invoke([]);
      } else if (fn is Object? Function(Never)) {
        wrapper = (Object? a) => invoke([a]);
      } else if (fn is Object? Function(Never, Never)) {
        wrapper = (Object? a, Object? b) => invoke([a, b]);
      } else {
        wrapper = (Object? a, Object? b, Object? c) => invoke([a, b, c]);
      }
      final wrapped = self ? JsFunction(wrapper) : wrapper;
      _callbacks[value] = wrapped;
      _callbacks[wrapped] = wrapped;
      return wrapped;
    }
    return value;
  }

  void walk(Object? value, {bool dataset = false}) {
    if (value is! Map<String, Object?> || !seen.add(value)) return;
    for (final key in value.keys.toList()) {
      if (dataset && (key == 'data' || key == 'label')) continue;
      if (_isColor(key)) {
        value[key] = color(value[key]);
      } else {
        walk(value[key]);
      }
    }
  }

  if (config is Map<String, Object?>) {
    walk(config['options']);
    final data = config['data'];
    if (data is Map<String, Object?>) {
      final datasets = data['datasets'];
      if (datasets is List) {
        for (final dataset in datasets) {
          walk(dataset, dataset: true);
        }
      }
    }
  }
}
