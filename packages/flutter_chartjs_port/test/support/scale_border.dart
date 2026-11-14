// Original code, not ported from Chart.js: the scale border in a data compare.

/// The scale border of the tests (Chart.js ADR 0141, row
/// `adapt-native-scale-border`).
///
/// The scale option `border` holds an `AxisBorder` or a `RadialAxisBorder`.
/// Upstream data hold the resolved `border` object of a scale: its keys and,
/// through the route `scale.border.color`, the default `borderColor`.
/// [upstreamBorderOf] gives that object for a border of the port.
library;

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
