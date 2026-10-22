// Ported from Chart.js v4.5.1+7169e651 test/fixtures/controller.line/segments/range.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() {
  // `ctx[p].parsed[axis]`: `ctx.p0` and `ctx.p1` are point elements, read by
  // name (Chart.js ADR 0017, section 5). The parsed value is a number.
  double parsed(Object? ctx, String p, String axis) =>
      jsToNumber(jsGet((jsGet(ctx, p)! as Element)['parsed'], axis));

  // A destructuring default applies only when the property is undefined.
  double prop(Object? range, String key, double fallback) {
    final value = jsGet(range, key);
    return identical(value, undefined) ? fallback : jsToNumber(value);
  }

  // Upstream: function x(ctx, {min = -Infinity, max = Infinity}).
  bool x(Object? ctx, Object? range) {
    final min = prop(range, 'min', double.negativeInfinity);
    final max = prop(range, 'max', double.infinity);
    return (parsed(ctx, 'p0', 'x') >= min || parsed(ctx, 'p1', 'x') >= min) &&
        (parsed(ctx, 'p0', 'x') < max && parsed(ctx, 'p1', 'x') < max);
  }

  // Upstream: function y(ctx, {min = -Infinity, max = Infinity}).
  bool y(Object? ctx, Object? range) {
    final min = prop(range, 'min', double.negativeInfinity);
    final max = prop(range, 'max', double.infinity);
    return (parsed(ctx, 'p0', 'y') >= min || parsed(ctx, 'p1', 'y') >= min) &&
        (parsed(ctx, 'p0', 'y') < max || parsed(ctx, 'p1', 'y') < max);
  }

  bool xy(Object? ctx, Object? xr, Object? yr) {
    return x(ctx, xr) && y(ctx, yr);
  }

  return <String, Object?>{
    'config': <String, Object?>{
      'type': 'line',
      'data': <String, Object?>{
        'datasets': <Object?>[
          <String, Object?>{
            'data': <Object?>[
              <String, Object?>{'x': 0, 'y': 0},
              <String, Object?>{'x': 1, 'y': 1},
              <String, Object?>{'x': 2, 'y': 2},
              <String, Object?>{'x': 3, 'y': 3},
              <String, Object?>{'x': 4, 'y': 4},
              <String, Object?>{'x': 5, 'y': 5},
              <String, Object?>{'x': 6, 'y': 7},
              <String, Object?>{'x': 7, 'y': 8},
            ],
            'borderColor': 'black',
            'segment': <String, Object?>{
              'borderColor': (Object? ctx) =>
                  x(ctx, <String, Object?>{'min': 3, 'max': 4})
                  ? 'red'
                  : y(ctx, <String, Object?>{'min': 5})
                  ? 'green'
                  : xy(
                      ctx,
                      <String, Object?>{'min': 0},
                      <String, Object?>{'max': 1},
                    )
                  ? 'blue'
                  : undefined,
              'borderDash': (Object? ctx) =>
                  x(ctx, <String, Object?>{'min': 3, 'max': 4}) ||
                      y(ctx, <String, Object?>{'min': 5})
                  ? <Object?>[5, 5]
                  : undefined,
            },
          },
        ],
      },
      'options': <String, Object?>{
        'scales': <String, Object?>{
          'x': <String, Object?>{'type': 'linear', 'display': false},
          'y': <String, Object?>{'display': false},
        },
      },
    },
  };
}
