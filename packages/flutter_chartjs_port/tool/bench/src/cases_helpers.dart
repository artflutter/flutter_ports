// Original code, not ported from Chart.js: the helper benchmarks.

/// The cases of `helpers.core` (`merge`, `mergeIf`, `clone`),
/// `helpers.options` (`createContext`, `toFont`, `toPadding`, `toTRBL`),
/// `helpers.canvas` (`toFontString`), `@kurkle/color`, `core.ticks` and
/// `helpers.intl`, `helpers.easing` and `helpers.math`.
library;

import 'dart:math' as math;

import 'package:flutter_chartjs_port/src/core/core.ticks.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.color.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.easing.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.intl.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_intl.dart';
import 'package:flutter_chartjs_port/src/js/js_math.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/kurkle_color/index.esm.dart' as kurkle;
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart';

import 'fixtures.dart';
import 'harness.dart';

/// The `chart` of a `this` object `{chart: {options}, options}`.
final class _Chart implements Chart {
  _Chart(this.options);

  @override
  final Map<String, Object?> options;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A `this` object `{chart, options}`, passed as a [Scale].
final class _Scale implements Scale {
  _Scale(this.chart, this.options);

  @override
  final Chart chart;

  @override
  final Map<String, Object?> options;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A tick `{value}`.
final class _Tick implements Tick {
  const _Tick(this.value);

  @override
  final double value;

  @override
  double? get significand => null;
}

/// A point `{x, y}`.
final class _Point implements Point {
  const _Point(this.x, this.y);

  @override
  final double x;

  @override
  final double y;
}

/// The helper cases.
List<BenchCase> helperCases() => [
  // helpers.core
  BenchCase(
    'core',
    'clone/bar_config',
    () {
      final config = barChartConfig();
      return (n) {
        var acc = 0;
        for (var i = 0; i < n; i++) {
          acc += (clone(config)! as AnyObject).length;
        }
        return acc;
      };
    },
    per: 'clone of a bar config, 3 datasets x 100 points',
  ),
  BenchCase('core', 'merge/bar_config', () {
    final config = barChartConfig();
    return (n) {
      var acc = 0;
      for (var i = 0; i < n; i++) {
        acc += (merge(<String, Object?>{}, config)! as AnyObject).length;
      }
      return acc;
    };
  }, per: 'merge({}, config) of a bar config'),
  BenchCase(
    'core',
    'mergeIf/options_over_defaults',
    () {
      final options = barChartOptions();
      final scaleDefaults = <String, Object?>{
        'scales': <String, Object?>{
          'x': <String, Object?>{
            'type': 'category',
            'offset': true,
            'grid': <String, Object?>{'offset': true, 'display': true},
            'ticks': <String, Object?>{'autoSkip': true, 'padding': 3.0},
          },
          'y': <String, Object?>{
            'type': 'linear',
            'beginAtZero': true,
            'grace': 0.0,
            'ticks': <String, Object?>{'padding': 3.0},
          },
        },
        'plugins': <String, Object?>{
          'legend': <String, Object?>{'display': true, 'align': 'center'},
          'tooltip': <String, Object?>{'enabled': true},
        },
      };
      return (n) {
        var acc = 0;
        for (var i = 0; i < n; i++) {
          final target = <String, Object?>{};
          mergeIf(target, <Object?>[options, scaleDefaults]);
          acc += target.length;
        }
        return acc;
      };
    },
    per: 'mergeIf({}, [options, scale and plugin defaults])',
  ),
  // helpers.options
  BenchCase(
    'options',
    'createContext/chain3',
    () {
      return (n) {
        var acc = 0;
        for (var i = 0; i < n; i++) {
          final chart = createContext(null, <String, Object?>{
            'chart': 'chart',
            'type': 'chart',
          });
          final dataset = createContext(chart, <String, Object?>{
            'active': false,
            'datasetIndex': 0.0,
            'index': 0.0,
            'mode': 'default',
            'type': 'dataset',
          });
          final data = createContext(dataset, <String, Object?>{
            'active': false,
            'dataIndex': 1.0,
            'raw': 1.0,
            'index': 1.0,
            'mode': 'default',
            'type': 'data',
          });
          acc += data.ownKeyCount;
        }
        return acc;
      };
    },
    per: '3 createContext calls, chart > dataset > data',
  ),
  BenchCase(
    'options',
    'createContext/read_chain3',
    () {
      final contexts = dataContexts(1);
      final ctx = contexts[0];
      return (n) {
        var acc = 0;
        for (var i = 0; i < n; i++) {
          if (jsGet(ctx, 'chart') != null) acc++; // two levels up
          if (jsGet(ctx, 'datasetIndex') != null) acc++; // one level up
          if (jsGet(ctx, 'dataIndex') != null) acc++; // own
          if (identical(jsGet(ctx, 'absent'), undefined)) acc++; // miss
        }
        return acc;
      };
    },
    items: 4,
    per: '4 reads of a data context: own, parent, root, miss',
  ),
  BenchCase('options', 'toFont/map', () {
    final options = <String, Object?>{'size': 14.0, 'weight': 'bold'};
    return (n) {
      var acc = 0;
      for (var i = 0; i < n; i++) {
        acc += toFont(options).string?.length ?? 0;
      }
      return acc;
    };
  }, per: 'toFont({size, weight}) over defaults.font'),
  BenchCase(
    'options',
    'toPadding/number_and_object',
    () {
      final object = <String, Object?>{
        'top': 1.0,
        'left': 2.0,
        'right': 3.0,
        'bottom': 4.0,
      };
      return (n) {
        var acc = 0.0;
        for (var i = 0; i < n; i++) {
          acc += toPadding(5.0).width + toPadding(object).height;
        }
        return acc.toInt();
      };
    },
    items: 2,
    per: 'toPadding(5) + toPadding({top, left, right, bottom})',
  ),
  BenchCase('options', 'toTRBL/object', () {
    final object = <String, Object?>{
      'top': 1.0,
      'left': 2.0,
      'right': 3.0,
      'bottom': 4.0,
    };
    return (n) {
      var acc = 0.0;
      for (var i = 0; i < n; i++) {
        acc += toTRBL(object).top;
      }
      return acc.toInt();
    };
  }, per: 'toTRBL({top, left, right, bottom})'),
  BenchCase('options', 'toFontString/parsed', () {
    final font = toFont(<String, Object?>{'size': 14.0, 'weight': 'bold'});
    return (n) {
      var acc = 0;
      for (var i = 0; i < n; i++) {
        acc += toFontString(font)?.length ?? 0;
      }
      return acc;
    };
  }, per: 'toFontString of a parsed font'),
  // @kurkle/color
  BenchCase('color', 'kurkle/parse_hex', () {
    return (n) {
      var acc = 0;
      for (var i = 0; i < n; i++) {
        if (kurkle.color('#ff6384').valid) acc++;
      }
      return acc;
    };
  }, per: "color('#ff6384')"),
  BenchCase('color', 'kurkle/parse_rgba', () {
    return (n) {
      var acc = 0;
      for (var i = 0; i < n; i++) {
        if (kurkle.color('rgba(255, 99, 132, 0.5)').valid) acc++;
      }
      return acc;
    };
  }, per: "color('rgba(255, 99, 132, 0.5)')"),
  BenchCase('color', 'kurkle/parse_hsl', () {
    return (n) {
      var acc = 0;
      for (var i = 0; i < n; i++) {
        if (kurkle.color('hsl(204, 82%, 57%)').valid) acc++;
      }
      return acc;
    };
  }, per: "color('hsl(204, 82%, 57%)')"),
  BenchCase('color', 'kurkle/parse_name', () {
    return (n) {
      var acc = 0;
      for (var i = 0; i < n; i++) {
        if (kurkle.color('cornflowerblue').valid) acc++;
      }
      return acc;
    };
  }, per: "color('cornflowerblue')"),
  BenchCase('color', 'kurkle/rgbString', () {
    final c = kurkle.color('rgba(255, 99, 132, 0.5)');
    return (n) {
      var acc = 0;
      for (var i = 0; i < n; i++) {
        acc += c.rgbString()?.length ?? 0;
      }
      return acc;
    };
  }, per: 'rgbString of a parsed color'),
  BenchCase('color', 'kurkle/clone_mix', () {
    final c1 = kurkle.color('#ff6384');
    final c2 = kurkle.color('rgba(54, 162, 235, 0.5)');
    return (n) {
      var acc = 0;
      for (var i = 0; i < n; i++) {
        if (c1.clone().mix(c2, 0.3).valid) acc++;
      }
      return acc;
    };
  }, per: 'clone().mix(c2, 0.3)'),
  BenchCase('color', 'getHoverColor/rgba', () {
    return (n) {
      var acc = 0;
      for (var i = 0; i < n; i++) {
        final hover = getHoverColor('rgba(255, 99, 132, 0.5)');
        acc += hover is String ? hover.length : 0;
      }
      return acc;
    };
  }, per: 'parse + saturate + darken + hexString'),
  // core.ticks and helpers.intl
  BenchCase(
    'ticks',
    'ticks/numeric_11_cache_hit',
    () {
      final scale = _Scale(_Chart(<String, Object?>{'locale': 'en-US'}), {
        'ticks': <String, Object?>{},
      });
      final ticks = <Tick>[
        for (var i = 0; i <= 10; i++) _Tick(i * 10.0),
      ];
      final numeric = formatters['numeric'];
      jsCall(numeric, [10.0, 1.0, ticks], thisArg: scale);
      return (n) {
        var acc = 0;
        for (var i = 0; i < n; i++) {
          for (var t = 0; t < ticks.length; t++) {
            final label = jsCall(numeric, [
              ticks[t].value,
              t.toDouble(),
              ticks,
            ], thisArg: scale);
            acc += (label! as String).length;
          }
        }
        return acc;
      };
    },
    items: 11,
    per: 'formatters.numeric over 11 ticks 0..100, intl cache hit',
  ),
  BenchCase(
    'ticks',
    'formatNumber/cache_hit',
    () {
      final options = <String, Object?>{
        'notation': undefined,
        'minimumFractionDigits': 1.0,
        'maximumFractionDigits': 1.0,
      };
      formatNumber(12.5, 'en-US', options);
      return (n) {
        var acc = 0;
        for (var i = 0; i < n; i++) {
          acc += formatNumber(12.5, 'en-US', options).length;
        }
        return acc;
      };
    },
    per: 'formatNumber with a cached NumberFormat (key + format)',
  ),
  BenchCase(
    'ticks',
    'formatNumber/cache_miss',
    () {
      final options = <String, Object?>{
        'notation': undefined,
        'minimumFractionDigits': 1.0,
        'maximumFractionDigits': 1.0,
      };
      return (n) {
        var acc = 0;
        for (var i = 0; i < n; i++) {
          acc += jsNumberFormat('en-US', options).format(12.5).length;
        }
        return acc;
      };
    },
    per: 'first call: new jsNumberFormat + format (the cache miss cost)',
  ),
  // helpers.easing
  BenchCase(
    'easing',
    'easing/31x1000',
    () {
      final effects = easingEffects.values.toList();
      final ts = <double>[for (var i = 0; i < 1000; i++) i / 999];
      return (n) {
        var acc = 0.0;
        for (var i = 0; i < n; i++) {
          for (final effect in effects) {
            for (final t in ts) {
              acc += effect(t);
            }
          }
        }
        return acc.isNaN ? 0 : acc.toInt();
      };
    },
    items: 31000,
    per: '31 effects x 1,000 t values',
  ),
  // helpers.math
  BenchCase(
    'math',
    'limitValue/10k',
    () {
      final values = <double>[for (var i = 0; i < 10000; i++) i * 0.37 - 1000];
      return (n) {
        var acc = 0.0;
        for (var i = 0; i < n; i++) {
          for (final v in values) {
            acc += limitValue(v, -500, 500);
          }
        }
        return acc.toInt();
      };
    },
    items: 10000,
    per: '10k values',
  ),
  BenchCase(
    'math',
    'getAngleFromPoint/10k',
    () {
      const centre = _Point(200, 200);
      final points = <Point>[
        for (var i = 0; i < 10000; i++)
          _Point(200 + 150 * math.cos(i * 0.01), 200 + 90 * math.sin(i * 0.02)),
      ];
      return (n) {
        var acc = 0.0;
        for (var i = 0; i < n; i++) {
          for (final p in points) {
            acc += getAngleFromPoint(centre, p).angle;
          }
        }
        return acc.toInt();
      };
    },
    items: 10000,
    per: '10k points, jsAtan2 + sqrt',
  ),
  BenchCase(
    'math',
    'jsAtan2/10k',
    () {
      final ys = <double>[for (var i = 0; i < 10000; i++) math.sin(i * 0.013)];
      final xs = <double>[for (var i = 0; i < 10000; i++) math.cos(i * 0.011)];
      return (n) {
        var acc = 0.0;
        for (var i = 0; i < n; i++) {
          for (var k = 0; k < 10000; k++) {
            acc += jsAtan2(ys[k], xs[k]);
          }
        }
        return acc.toInt();
      };
    },
    items: 10000,
    per: '10k fdlibm atan2 calls',
  ),
  BenchCase(
    'math',
    'dart_math_atan2/10k_reference',
    () {
      final ys = <double>[for (var i = 0; i < 10000; i++) math.sin(i * 0.013)];
      final xs = <double>[for (var i = 0; i < 10000; i++) math.cos(i * 0.011)];
      return (n) {
        var acc = 0.0;
        for (var i = 0; i < n; i++) {
          for (var k = 0; k < 10000; k++) {
            acc += math.atan2(ys[k], xs[k]);
          }
        }
        return acc.toInt();
      };
    },
    items: 10000,
    per: '10k dart:math atan2 calls (reference, not a port path)',
  ),
  BenchCase(
    'math',
    'log10/10k',
    () {
      final values = <double>[for (var i = 1; i <= 10000; i++) i * 1.37];
      return (n) {
        var acc = 0.0;
        for (var i = 0; i < n; i++) {
          for (final v in values) {
            acc += log10(v);
          }
        }
        return acc.toInt();
      };
    },
    items: 10000,
    per: '10k fdlibm log10 calls',
  ),
  BenchCase(
    'math',
    'dart_math_log_ln10/10k_reference',
    () {
      final values = <double>[for (var i = 1; i <= 10000; i++) i * 1.37];
      return (n) {
        var acc = 0.0;
        for (var i = 0; i < n; i++) {
          for (final v in values) {
            acc += math.log(v) / math.ln10;
          }
        }
        return acc.toInt();
      };
    },
    items: 10000,
    per: '10k dart:math log / ln10 (reference, not a port path)',
  ),
];
