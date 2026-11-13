// Original code, not ported from Chart.js: the scale border in a data compare.

/// The scale border of the tests (Chart.js ADR 0141, row
/// `adapt-native-scale-border`).
///
/// The scale option `border` holds an `AxisBorder` or a `RadialAxisBorder`.
/// Upstream data hold the resolved `border` object of a scale: its keys and,
/// through the route `scale.border.color`, the default `borderColor`.
/// [upstreamBorderOf] gives that object for a border of the port.
library;

import 'dart:convert';

import 'package:flutter_chartjs_port/src/core/core.defaults.dart' show defaults;
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart'
    show OptionKey;
import 'package:flutter_chartjs_port/src/types/axis_border.dart';

/// The upstream form of the resolved border [border], or [border] itself
/// for another value.
///
/// An [AxisBorder] gives its fields that are set, with the keys of the
/// upstream object in the order of the upstream defaults, and the color that
/// a cartesian scale draws: its own color, else the default `borderColor`,
/// the value of the upstream route. A [RadialAxisBorder] gives its fields
/// that are set: the radial scale has no axis line. With [routeColor]
/// false, an absent color stays absent: the object before the route.
Object? upstreamBorderOf(Object? border, {bool routeColor = true}) =>
    switch (border) {
      final AxisBorder b => <String, Object?>{
        'display': ?b.display,
        'dash': ?b.dash,
        'dashOffset': ?b.dashOffset,
        'width': ?b.width,
        'color':
            ?(b.color ??
            (routeColor ? defaults.lookup(OptionKey.borderColor)?.raw : null)),
        'z': ?b.z,
      },
      final RadialAxisBorder b => <String, Object?>{
        'dash': ?b.dash,
        'dashOffset': ?b.dashOffset,
      },
      _ => border,
    };

/// The leaves of the border [border] under [prefix]: one leaf
/// `<prefix>.<field>` for each field that it sets, with the key of the
/// upstream object, as a theme sets the key `color` of the upstream `border`
/// object. A border with no field set gives no leaf.
Map<String, Object?> borderLeaves(String prefix, ScaleBorder border) => {
  for (final MapEntry(:key, :value)
      in (upstreamBorderOf(border, routeColor: false)! as Map<String, Object?>)
          .entries)
    '$prefix.$key': value,
};

/// The keys of the upstream `border` object in the order of the port: the
/// order of [upstreamBorderOf].
const List<String> _borderKeys = [
  'display',
  'dash',
  'dashOffset',
  'width',
  'color',
  'z',
];

/// The reference text [text] of `<label>: <JSON>` lines in the form of the
/// port.
///
/// The port holds the border as one object with no key order: each
/// `border` object takes the order of [upstreamBorderOf]. The radial linear
/// scale has its own border in its defaults, after `grid`, with only `dash`
/// and `dashOffset`: the border of each scale of the type `radialLinear`
/// moves there and keeps these keys. A theme with a `scale.border` gives the
/// radial scale an empty border after its other keys. A line whose value is
/// not JSON, or that has no border, stays as it is.
String withPortBorders(String text) =>
    [for (final line in text.split('\n')) _portBorderLine(line)].join('\n');

String _portBorderLine(String line) {
  final at = line.indexOf(': ');
  if (at < 0 || !line.contains('"border"')) return line;
  final Object? value;
  try {
    value = jsonDecode(line.substring(at + 2));
  } on FormatException {
    return line;
  }
  final label = line.substring(0, at);
  return '$label: ${jsonEncode(_portBorders(value, theme: label == 'theme'))}';
}

Object? _portBorders(Object? value, {bool theme = false}) {
  if (value is List<Object?>) {
    return [for (final item in value) _portBorders(item)];
  }
  if (value is! Map<String, Object?>) return value;
  final radial = value['type'] == 'radialLinear' && value['grid'] != null;
  final out = <String, Object?>{};
  for (final MapEntry(:key, value: item) in value.entries) {
    if (key == 'border' && item is Map<String, Object?>) {
      if (radial) continue;
      out[key] = {
        for (final name in _borderKeys)
          if (item.containsKey(name)) name: item[name],
      };
    } else {
      out[key] = _portBorders(item);
    }
    if (radial && key == 'grid') {
      if (value['border'] case final Map<String, Object?> border) {
        out['border'] = {
          for (final name in const ['dash', 'dashOffset'])
            if (border.containsKey(name)) name: border[name],
        };
      }
    }
  }
  final scale = out['scale'];
  if (theme && scale is Map<String, Object?> && scale.containsKey('border')) {
    if (out['scales'] case final Map<String, Object?> scales) {
      if (scales['radialLinear'] case final Map<String, Object?> radialTheme) {
        radialTheme['border'] = <String, Object?>{};
      }
    }
  }
  return out;
}
