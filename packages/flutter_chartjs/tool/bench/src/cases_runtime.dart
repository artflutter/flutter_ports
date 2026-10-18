// Original code, not ported from Chart.js: the JS runtime benchmarks.

/// The cases of `lib/src/js/`: `jsCall`, `jsGet`, `jsTruthy`, `jsToNumber`,
/// `jsNumberToString`, `jsObjectKeys` and `jsSort`.
library;

import 'package:flutter_chartjs/src/js/js_array.dart';
import 'package:flutter_chartjs/src/js/js_function.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';

import 'harness.dart';

/// An item of the sort cases: a value with ties and its insertion index.
final class _Item {
  _Item(this.value, this.index);

  final double value;
  final double index;
}

/// The JS runtime cases.
List<BenchCase> runtimeCases() => [
  BenchCase(
    'js',
    'jsCall/arity_match',
    () {
      Object? f(Object? a) => a;
      final args = <Object?>[1.0];
      return (n) {
        var acc = 0;
        for (var i = 0; i < n; i++) {
          if (jsCall(f, args) != null) acc++;
        }
        return acc;
      };
    },
    per: 'jsCall of a 1-parameter closure with 1 argument',
  ),
  BenchCase(
    'js',
    'jsCall/arity_match_2',
    () {
      Object? f(Object? a, Object? b) => b;
      final args = <Object?>[1.0, 2.0];
      return (n) {
        var acc = 0;
        for (var i = 0; i < n; i++) {
          if (jsCall(f, args) != null) acc++;
        }
        return acc;
      };
    },
    per: 'jsCall of a 2-parameter closure with 2 arguments',
  ),
  BenchCase(
    'js',
    'jsCall/extra_args',
    () {
      Object? f(Object? a) => a;
      final args = <Object?>[1.0, 2.0, 3.0];
      return (n) {
        var acc = 0;
        for (var i = 0; i < n; i++) {
          if (jsCall(f, args) != null) acc++;
        }
        return acc;
      };
    },
    per: 'jsCall of a 1-parameter closure with 3 arguments',
  ),
  BenchCase(
    'js',
    'jsCall/missing_args',
    () {
      Object? f(Object? a, Object? b, Object? c) => c;
      final args = <Object?>[1.0];
      return (n) {
        var acc = 0;
        for (var i = 0; i < n; i++) {
          if (identical(jsCall(f, args), undefined)) acc++;
        }
        return acc;
      };
    },
    per: 'jsCall of a 3-parameter closure with 1 argument',
  ),
  BenchCase(
    'js',
    'jsCall/js_function_this',
    () {
      final f = JsFunction((Object? self, Object? a) => self);
      final args = <Object?>[1.0];
      final self = <String, Object?>{};
      return (n) {
        var acc = 0;
        for (var i = 0; i < n; i++) {
          if (jsCall(f, args, thisArg: self) != null) acc++;
        }
        return acc;
      };
    },
    per: 'jsCall of a JsFunction with this and 1 argument',
  ),
  BenchCase(
    'js',
    'direct_call/reference',
    () {
      Object? f(Object? a) => a;
      // A list read keeps the compilers from inlining the closure.
      final g = <Object? Function(Object?)>[f][0];
      return (n) {
        var acc = 0;
        for (var i = 0; i < n; i++) {
          if (g(1.0) != null) acc++;
        }
        return acc;
      };
    },
    per: 'direct closure call (reference, not a port path)',
  ),
  BenchCase('js', 'jsGet/map_hit', () {
    final map = <String, Object?>{
      for (var i = 0; i < 20; i++) 'key$i': i.toDouble(),
    };
    return (n) {
      var acc = 0;
      for (var i = 0; i < n; i++) {
        if (jsGet(map, 'key7') != null) acc++;
      }
      return acc;
    };
  }, per: 'jsGet of an own key of a 20-key Map'),
  BenchCase('js', 'jsGet/map_miss', () {
    final map = <String, Object?>{
      for (var i = 0; i < 20; i++) 'key$i': i.toDouble(),
    };
    return (n) {
      var acc = 0;
      for (var i = 0; i < n; i++) {
        if (identical(jsGet(map, 'absent'), undefined)) acc++;
      }
      return acc;
    };
  }, per: 'jsGet of an absent key of a 20-key Map'),
  BenchCase('js', 'jsGet/list_index', () {
    final list = <Object?>[for (var i = 0; i < 100; i++) i.toDouble()];
    return (n) {
      var acc = 0;
      for (var i = 0; i < n; i++) {
        if (jsGet(list, '42') != null) acc++;
      }
      return acc;
    };
  }, per: "jsGet(list, '42')"),
  BenchCase('js', 'jsGet/list_number_key', () {
    final list = <Object?>[for (var i = 0; i < 100; i++) i.toDouble()];
    return (n) {
      var acc = 0;
      for (var i = 0; i < n; i++) {
        if (jsGet(list, 42.0) != null) acc++;
      }
      return acc;
    };
  }, per: 'jsGet(list, 42.0): ToString of the key'),
  BenchCase('js', 'jsGet/list_length', () {
    final list = <Object?>[for (var i = 0; i < 100; i++) i.toDouble()];
    return (n) {
      var acc = 0;
      for (var i = 0; i < n; i++) {
        if (jsGet(list, 'length') != null) acc++;
      }
      return acc;
    };
  }, per: "jsGet(list, 'length')"),
  BenchCase(
    'js',
    'jsTruthy/mixed8',
    () {
      final values = <Object?>[
        null,
        undefined,
        true,
        0.0,
        1.5,
        '',
        'a',
        <String, Object?>{},
      ];
      return (n) {
        var acc = 0;
        for (var i = 0; i < n; i++) {
          for (final v in values) {
            if (jsTruthy(v)) acc++;
          }
        }
        return acc;
      };
    },
    items: 8,
    per: 'jsTruthy over 8 mixed values',
  ),
  BenchCase('js', 'jsToNumber/double', () {
    final values = <Object?>[1.5, 2.5, 3.5, 4.5];
    return (n) {
      var acc = 0.0;
      for (var i = 0; i < n; i++) {
        acc += jsToNumber(values[i & 3]);
      }
      return acc.toInt();
    };
  }, per: 'jsToNumber of a double'),
  BenchCase('js', 'jsToNumber/string', () {
    final values = <Object?>['123.45', '  7 ', '1e3', '-0.5'];
    return (n) {
      var acc = 0.0;
      for (var i = 0; i < n; i++) {
        acc += jsToNumber(values[i & 3]);
      }
      return acc.toInt();
    };
  }, per: 'jsToNumber of a numeric string (RegExp path)'),
  BenchCase('js', 'jsNumberToString/mixed', () {
    final values = <double>[12, 0.1 + 0.2, 1e21, 1.5e-7, -3, 1234.5678];
    return (n) {
      var acc = 0;
      for (var i = 0; i < n; i++) {
        acc += jsNumberToString(values[i % 6]).length;
      }
      return acc;
    };
  }, per: 'jsNumberToString of one of 6 doubles'),
  BenchCase(
    'js',
    'jsNumberToString/integral',
    () {
      return (n) {
        var acc = 0;
        for (var i = 0; i < n; i++) {
          acc += jsNumberToString((i & 1023).toDouble()).length;
        }
        return acc;
      };
    },
    per: 'jsNumberToString of an integral double (index keys)',
  ),
  BenchCase('js', 'jsObjectKeys/map30', () {
    final map = <String, Object?>{
      for (var i = 0; i < 30; i++) 'option$i': i.toDouble(),
    };
    return (n) {
      var acc = 0;
      for (var i = 0; i < n; i++) {
        acc += jsObjectKeys(map).length;
      }
      return acc;
    };
  }, per: 'jsObjectKeys of a 30-key Map'),
  BenchCase(
    'js',
    'jsSort/10k_ties',
    () {
      final base = <_Item>[
        for (var i = 0; i < 10000; i++)
          _Item(((i * 7919) % 100).toDouble(), i.toDouble()),
      ];
      return (n) {
        var acc = 0;
        for (var i = 0; i < n; i++) {
          final list = List<_Item>.of(base);
          jsSort<_Item>(list, (a, b) => a.value - b.value);
          acc += list[5000].index.toInt();
        }
        return acc;
      };
    },
    items: 10000,
    per: 'copy + jsSort of 10k items with 100 distinct keys',
  ),
  BenchCase(
    'js',
    'list_sort/10k_ties_reference',
    () {
      final base = <_Item>[
        for (var i = 0; i < 10000; i++)
          _Item(((i * 7919) % 100).toDouble(), i.toDouble()),
      ];
      return (n) {
        var acc = 0;
        for (var i = 0; i < n; i++) {
          final list = List<_Item>.of(base)
            ..sort((a, b) => a.value.compareTo(b.value));
          acc += list[5000].index.toInt();
        }
        return acc;
      };
    },
    items: 10000,
    per: 'copy + List.sort (unstable, reference only)',
  ),
];
