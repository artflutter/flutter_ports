// Original code, not ported from Chart.js: the Flutter Color-only boundary.

import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/src/js/js_function.dart' show jsIsFunction;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show JsObjectFace;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart' show Undefined;
import 'package:flutter_chartjs_port/src/options/prepared_color.dart';
import 'package:flutter_chartjs_port/src/types/color.dart';

bool _installed = false;

/// Installs the numerical/native bridge without any parser or string cache.
void installNativeColorCodec() {
  if (_installed) return;
  _installed = true;
  nativeColorCheck = (value) => value is ui.Color;
  nativeColorReader = (value) {
    if (value is! ui.Color) return null;
    final srgb = value.withValues(colorSpace: ui.ColorSpace.extendedSRGB);
    return PreparedColor(
      (srgb.r * 255).round().clamp(0, 255),
      (srgb.g * 255).round().clamp(0, 255),
      (srgb.b * 255).round().clamp(0, 255),
      srgb.a.clamp(0.0, 1.0),
      value,
    );
  };
  nativeColorWriter = (value) => ui.Color.fromRGBO(
    value.red,
    value.green,
    value.blue,
    value.alpha,
  );
}

/// A solid canvas color. CSS strings and all other values fail explicitly.
ui.Color requireUiColor(Object? value, String argument) {
  if (value is ui.Color) return value;
  if (value is PreparedColor) {
    installNativeColorCodec();
    return value.paint as ui.Color;
  }
  throw ArgumentError.value(
    value,
    argument,
    'Expected Flutter Color; CSS color strings are unsupported',
  );
}

Object? _field(Object? object, String key) => switch (object) {
  final Map<Object?, Object?> map => map[key],
  final JsObjectFace face => face.jsRead(key),
  _ => null,
};

Iterable<String> _keys(Object? object) => switch (object) {
  final Map<Object?, Object?> map => map.keys.whereType<String>(),
  final JsObjectFace face => face.jsKeys(),
  _ => const <String>[],
};

bool _colorKey(String key) =>
    key == 'color' ||
    key.endsWith('Color') ||
    key == 'multiKeyBackground' ||
    key == r'$borderColors' ||
    key == r'$backgroundColors';

/// Rejects static CSS inputs before a failed constructor can acquire a canvas.
/// Dataset data/labels are not color options. Callback results are checked when
/// consumed, without extra calls to user code.
void validateChartColors(Object? config) {
  final seen = Set<Object>.identity();
  void color(Object? value, String path) {
    if (value == null || value is Undefined || jsIsFunction(value)) return;
    if (value is List) {
      if (!seen.add(value)) return;
      for (var i = 0; i < value.length; i++) {
        color(value[i], '$path[$i]');
      }
      return;
    }
    if (value is ui.Color ||
        value is PreparedColor ||
        value is CanvasGradient ||
        value is CanvasPattern) {
      return;
    }
    throw ArgumentError.value(
      value,
      path,
      'Expected Flutter Color; CSS color strings are unsupported',
    );
  }

  void scope(Object? value, String path, {bool dataset = false}) {
    if (value is! Map && value is! JsObjectFace) return;
    if (!seen.add(value!)) return;
    for (final key in _keys(value)) {
      if (dataset && (key == 'data' || key == 'label')) continue;
      final child = _field(value, key);
      if (key == 'animations') {
        for (final group in _keys(child)) {
          final spec = _field(child, group);
          if (_field(spec, 'type') == 'color') {
            color(_field(spec, 'from'), '$path.animations.$group.from');
            color(_field(spec, 'to'), '$path.animations.$group.to');
          }
        }
      } else if (key == 'scales' ||
          key == 'datasets' ||
          key == 'elements' ||
          key == 'transitions') {
        for (final id in _keys(child)) {
          scope(
            _field(child, id),
            '$path.$key.$id',
            dataset: key == 'datasets',
          );
        }
      } else if (key == 'fill') {
        color(_field(child, 'above'), '$path.fill.above');
        color(_field(child, 'below'), '$path.fill.below');
      } else if (key == 'plugins') {
        for (final plugin in const [
          'legend',
          'title',
          'subtitle',
          'tooltip',
          'colors',
          'filler',
          'decimation',
        ]) {
          scope(_field(child, plugin), '$path.plugins.$plugin');
        }
      } else if (_colorKey(key)) {
        color(child, '$path.$key');
      } else if (const [
        'scale',
        'hover',
        'segment',
        'pointLabels',
        'ticks',
        'grid',
        'border',
        'title',
        'subtitle',
        'labels',
      ].contains(key)) {
        scope(child, '$path.$key');
      }
    }
  }

  scope(_field(config, 'options'), 'options');
  final datasets = _field(_field(config, 'data'), 'datasets');
  if (datasets is List) {
    for (var i = 0; i < datasets.length; i++) {
      scope(datasets[i], 'data.datasets[$i]', dataset: true);
    }
  }
}
