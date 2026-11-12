// Original code, not ported from Chart.js: native inputs for upstream fixtures.

/// Frozen upstream fixtures contain CSS colors. This test-only adapter decodes
/// their inputs before invoking the Color-only chart API. Production charts do
/// not import this module; their string rejection remains enabled.
library;

// Test-only access to the native color bridge.
// Callback arity must remain explicit for the observation oracle.
// ignore_for_file: implementation_imports, avoid_types_on_closure_parameters
import 'dart:ui' as ui;

import 'package:chartjs_test_utils/src/color_reference.dart';
import 'package:chartjs_test_utils/src/native_easing.dart';
import 'package:flutter_chartjs_port/src/core/core.adapters.dart' show TimeUnit;
import 'package:flutter_chartjs_port/src/core/scale_option_enums.dart'
    show ScaleBounds, TickAlign, TickCrossAlign, TickSource;
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/plugins/fill_target.dart'
    show FillBoundary;
import 'package:flutter_chartjs_port/src/plugins/filler_draw_time.dart'
    show FillerDrawTime;
import 'package:flutter_chartjs_port/src/types/align.dart' show ChartAlign;
import 'package:flutter_chartjs_port/src/types/arc_option_enums.dart'
    show ArcBorderAlign, ArcSpacingMode;
import 'package:flutter_chartjs_port/src/types/bar_option_enums.dart'
    show BorderSkippedEdge;
import 'package:flutter_chartjs_port/src/types/layout.dart'
    show ChartPosition, ScaleValuePosition;
import 'package:flutter_chartjs_port/src/types/line_option_enums.dart'
    show SteppedLine;

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

/// The value of [values] with the name [value] for a String that is such a
/// name, else [value] itself. An indexable value (a List) gives a new List
/// with each item so converted. A scriptable value stays.
Object? _enumValue<T extends Enum>(List<T> values, Object? value) =>
    switch (value) {
      final String name => values.asNameMap()[name] ?? name,
      final List<Object?> items => <Object?>[
        for (final item in items) _enumValue(values, item),
      ],
      _ => value,
    };

/// The [ScaleValuePosition] of the object form `{id: value}` of a position
/// [value], else [value] itself.
Object? _scaleValuePosition(Object? value) {
  if (value is Map<String, Object?> && value.length == 1) {
    final MapEntry(:key, value: scaleValue) = value.entries.single;
    return ScaleValuePosition(key, scaleValue);
  }
  return value;
}

/// The values of the enum of the scale option [key] of the object of the
/// key [owner], or Dart `null` for another option: `bounds` of a scale, and
/// `source`, `align` and `crossAlign` of `ticks`.
List<Enum>? _scaleEnumValues(String key, String? owner) => switch ((
  key,
  owner,
)) {
  ('bounds', _) => ScaleBounds.values,
  ('source', 'ticks') => TickSource.values,
  ('align', 'ticks') => TickAlign.values,
  ('crossAlign', 'ticks') => TickCrossAlign.values,
  _ => null,
};

/// Migrates color options, an upstream easing name to its curve, and the
/// keyword of a line cap, a line join or a scale option of
/// `scale_option_enums.dart` to its enum value, leaving data, labels and
/// ordinary text intact.
void nativeFixtureColors(Object? config) {
  final seen = Set<Object>.identity();
  Object? color(Object? value) {
    // Upstream uses false/empty colors to suppress a stroke.
    if (value == false) return null;
    if (value is String) {
      if (value.isEmpty) return null;
      final parsed = referenceColor(value);
      if (!parsed.valid) return value;
      final rgb = parsed.rgbaBytes!;
      return ui.Color.fromRGBO(
        rgb.r.round(),
        rgb.g.round(),
        rgb.b.round(),
        rgb.a / 255,
      );
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

  void walk(Object? value, {bool dataset = false, String? owner}) {
    if (value is! Map<String, Object?> || !seen.add(value)) return;
    for (final key in value.keys.toList()) {
      if (dataset && (key == 'data' || key == 'label')) continue;
      if (_isColor(key)) {
        value[key] = color(value[key]);
      } else if (key == 'easing') {
        // The option takes a Flutter curve, not an upstream easing name.
        value[key] = nativeFixtureEasing(value[key]);
      } else if (key == 'borderCapStyle' || key == 'lineCap') {
        // The option takes the Flutter enum, not the upstream keyword. The
        // names of the enum values are the keywords.
        value[key] = _enumValue(ui.StrokeCap.values, value[key]);
      } else if (key == 'borderJoinStyle' || key == 'lineJoin') {
        value[key] = _enumValue(ui.StrokeJoin.values, value[key]);
      } else if (key == 'align' &&
          (owner == 'legend' || owner == 'title' || owner == 'subtitle')) {
        // The align of a box takes a ChartAlign (row adapt-chart-align-enum).
        value[key] = _enumValue(ChartAlign.values, value[key]);
      } else if (key == 'position' && owner != 'tooltip') {
        // The position of the legend title takes a ChartAlign (row
        // adapt-chart-align-enum); the position of a box takes a
        // ChartPosition, and the object form `{id: value}` a
        // ScaleValuePosition (row adapt-chart-position-enum). A name of the
        // one enum is no name of the other: `center` of the owner `title` is
        // the align of the legend title.
        final position = value[key];
        value[key] = owner == 'title'
            ? _enumValue(
                ChartPosition.values,
                _enumValue(ChartAlign.values, position),
              )
            : _scaleValuePosition(_enumValue(ChartPosition.values, position));
      } else if (key == 'borderAlign') {
        // An arc option takes its enum (row adapt-arc-option-enums).
        value[key] = _enumValue(ArcBorderAlign.values, value[key]);
      } else if (key == 'spacingMode') {
        value[key] = _enumValue(ArcSpacingMode.values, value[key]);
      } else if ((key == 'unit' || key == 'minUnit' || key == 'round') &&
          owner == 'time') {
        // A time unit takes its enum (row adapt-time-unit-enum).
        value[key] = _enumValue(TimeUnit.values, value[key]);
      } else if (key == 'textAlign' ||
          key == 'titleAlign' ||
          key == 'bodyAlign' ||
          key == 'footerAlign') {
        // A text align takes the Flutter enum (row adapt-flutter-text-align).
        value[key] = _enumValue(ui.TextAlign.values, value[key]);
      } else if (key == 'stepped') {
        // The keyword form takes its enum (row adapt-stepped-line-enum); a
        // boolean stays.
        value[key] = _enumValue(SteppedLine.values, value[key]);
      } else if (key == 'borderSkipped') {
        // The keyword form takes its enum (row adapt-border-skipped-enum).
        value[key] = _enumValue(BorderSkippedEdge.values, value[key]);
      } else if ((key == 'fill' || (key == 'target' && owner == 'fill')) &&
          value[key] is String) {
        // A fill keyword takes its enum (row adapt-fill-target-objects). A
        // relative index as text is no name: such a fixture is a hand port
        // (Chart.js ADR 0115).
        value[key] = _enumValue(FillBoundary.values, value[key]);
      } else if (key == 'drawTime' && owner == 'filler') {
        // The filler draw time takes its enum (row
        // adapt-filler-draw-time-enum).
        value[key] = _enumValue(FillerDrawTime.values, value[key]);
      } else if (_scaleEnumValues(key, owner) case final values?) {
        // A scale option takes its enum, not the upstream keyword (row
        // adapt-scale-option-enums).
        value[key] = _enumValue(values, value[key]);
      } else {
        walk(value[key], owner: key);
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
