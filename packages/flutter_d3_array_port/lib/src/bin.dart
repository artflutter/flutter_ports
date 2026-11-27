// Ported from d3-array v3.2.4 src/bin.js (ISC, Mike Bostock).

/// Port of `src/bin.js` of d3-array 3.2.4.
library;

import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_array_port/src/bisect.dart';
import 'package:flutter_d3_array_port/src/extent.dart';
import 'package:flutter_d3_array_port/src/nice.dart';
import 'package:flutter_d3_array_port/src/threshold/sturges.dart';
import 'package:flutter_d3_array_port/src/ticks.dart';

/// A histogram bin containing elements of type `T` within `[x0, x1)`.
// DIVERGES(d3-array): adapt-array-typed-api, typed Bin<T> class extending
// ListBase<T> with double x0 and x1 bounds instead of JS array expando fields.
final class Bin<T>(
  /// The lower bound of the bin (inclusive).
  var double x0,

  /// The upper bound of the bin (exclusive, except for the last bin).
  var double x1, [
  List<T>? elements,
]) extends ListBase<T> {
  /// Creates a [Bin] with lower bound [x0], upper bound [x1], and optional
  /// initial [elements].
  this;

  final List<T> _elements = elements ?? <T>[];

  @override
  int get length => _elements.length;

  @override
  set length(int newLength) => _elements.length = newLength;

  @override
  T operator [](int index) => _elements[index];

  @override
  void operator []=(int index, T value) => _elements[index] = value;

  @override
  void add(T element) => _elements.add(element);

  @override
  void addAll(Iterable<T> iterable) => _elements.addAll(iterable);

  @override
  String toString() => 'Bin([$x0, $x1): $_elements)';
}

/// Accessor extracting a numeric value for binning from a datum of type `T`.
typedef BinValueAccessor<T> = num? Function(T value, int index, List<T> data);

/// Accessor computing the `[min, max]` binning domain from extracted values.
typedef BinDomainAccessor = (double, double)? Function(List<double?> values);

/// Callback computing an approximate threshold count from extracted values.
typedef BinThresholdCount = int Function(
  List<double?> values,
  double min,
  double max,
);

/// Callback computing explicit threshold boundaries from extracted values.
typedef BinThresholdValues = List<double> Function(
  List<double?> values,
  double min,
  double max,
);

(double, double)? _defaultDomain(List<double?> values) =>
    extent<double>(values);

int _defaultThresholdCount(List<double?> values, double min, double max) =>
    thresholdSturges(values, min, max);

/// A configurable, callable histogram bin generator for elements of type `T`.
// DIVERGES(d3-array): adapt-array-typed-api, typed generic BinGenerator<T>
// with cascade-friendly properties and *Const setters instead of JS dual
// getter/setter methods.
// DIVERGES(d3-array): adapt-array-fast-forms, direct double fast path for
// default identity binning avoiding per-element closure calls and intermediate
// nullable list allocation.
final class BinGenerator<T>({
  required BinValueAccessor<T> value,
  BinDomainAccessor? domain,
  BinThresholdCount? thresholdsCount,
  BinThresholdValues? thresholdsValues,
  bool isDefaultIdentity = false,
}) {
  /// Creates a [BinGenerator] with the specified [value] accessor.
  this;

  BinValueAccessor<T> _value = value;
  bool _isDefaultIdentity = isDefaultIdentity;
  double? _constValue;
  BinDomainAccessor _domain = domain ?? _defaultDomain;
  bool _isDefaultDomain = domain == null;
  BinThresholdCount? _thresholdCount = thresholdsValues == null
      ? (thresholdsCount ?? thresholdSturges)
      : null;
  BinThresholdValues? _thresholdValues = thresholdsValues;

  /// The current value accessor.
  BinValueAccessor<T> get value => _value;

  /// Sets the value accessor.
  set value(BinValueAccessor<T> fn) {
    _value = fn;
    _isDefaultIdentity = false;
    _constValue = null;
  }

  /// Sets a 1-argument value accessor.
  void valueSimple(num? Function(T value) fn) {
    _value = (d, _, _) => fn(d);
    _isDefaultIdentity = false;
    _constValue = null;
  }

  /// Sets a constant numeric value for every datum.
  void valueConst(num v) {
    final d = v.toDouble();
    _constValue = d;
    _isDefaultIdentity = false;
    _value = (_, _, _) => d;
  }

  /// The current domain accessor.
  BinDomainAccessor get domain => _domain;

  /// Sets the domain accessor.
  set domain(BinDomainAccessor fn) {
    _domain = fn;
    _isDefaultDomain = identical(fn, _defaultDomain);
  }

  /// Sets a constant `[min, max]` domain.
  void domainConst(num min, num max) {
    final lo = min.toDouble();
    final hi = max.toDouble();
    _domain = (_) => (lo, hi);
    _isDefaultDomain = false;
  }

  /// Resets the domain accessor to the default [extent].
  void domainDefault() {
    _domain = _defaultDomain;
    _isDefaultDomain = true;
  }

  /// The current threshold count callback, if configured by count.
  BinThresholdCount? get thresholdsCount => _thresholdCount;

  /// Sets a threshold count callback (e.g. [thresholdSturges],
  /// `thresholdScott`, `thresholdFreedmanDiaconis`).
  set thresholdsCount(BinThresholdCount? fn) {
    _thresholdCount = fn ?? thresholdSturges;
    _thresholdValues = null;
  }

  /// Sets an approximate constant threshold count.
  void thresholdsCountConst(int count) {
    _thresholdCount = (_, _, _) => count;
    _thresholdValues = null;
  }

  /// The current explicit threshold values callback, if configured by values.
  BinThresholdValues? get thresholdsValues => _thresholdValues;

  /// Sets an explicit threshold values callback.
  set thresholdsValues(BinThresholdValues? fn) {
    if (fn == null) {
      _thresholdValues = null;
      _thresholdCount = thresholdSturges;
    } else {
      _thresholdValues = fn;
      _thresholdCount = null;
    }
  }

  /// Sets explicit constant threshold boundaries (copied defensively).
  void thresholdsValuesConst(Iterable<num> values) {
    final copy = List<double>.of(
      values.map((v) => v.toDouble()),
      growable: false,
    );
    _thresholdValues = (_, _, _) => copy;
    _thresholdCount = null;
  }

  /// Bins [data] into a list of [Bin]s.
  List<Bin<T>> call(Iterable<T> data) {
    final items = data is List<T> ? data : List<T>.of(data, growable: false);
    final n = items.length;
    final Object rawItems = items;

    // Fast path: default identity accessor directly on List<double> /
    // Float64List avoids per-element closure invocation and nullable copy.
    if (_isDefaultIdentity && rawItems is List<double>) {
      return _binDoubleList(rawItems, items);
    }

    final values = List<double?>.filled(n, null);
    final constVal = _constValue;
    if (constVal != null) {
      for (var i = 0; i < n; ++i) {
        values[i] = constVal;
      }
    } else {
      final valFn = _value;
      for (var i = 0; i < n; ++i) {
        final v = valFn(items[i], i, items);
        values[i] = v?.toDouble();
      }
    }

    final xz = _domain(values);
    var x0 = xz?.$1 ?? double.nan;
    var x1 = xz?.$2 ?? double.nan;

    List<double> tz;
    var step = double.nan;

    final tv = _thresholdValues;
    if (tv != null) {
      tz = tv(values, x0, x1);
    } else {
      final tc = _thresholdCount ?? _defaultThresholdCount;
      final tn = tc(values, x0, x1).toDouble();
      final maxVal = x1;
      if (_isDefaultDomain) {
        final niced = nice(x0, x1, tn);
        x0 = niced.$1;
        x1 = niced.$2;
      }
      tz = ticks(x0, x1, tn);
      if (tz.isNotEmpty && tz[0] <= x0) {
        step = tickIncrement(x0, x1, tn);
      }
      if (tz.isNotEmpty && tz[tz.length - 1] >= x1) {
        if (maxVal >= x1 && _isDefaultDomain) {
          final st = tickIncrement(x0, x1, tn);
          if (st.isFinite) {
            if (st > 0) {
              x1 = ((x1 / st).floorToDouble() + 1.0) * st;
            } else if (st < 0) {
              x1 = ((x1 * -st).ceilToDouble() + 1.0) / -st;
            }
          }
        } else {
          tz = tz.sublist(0, tz.length - 1);
        }
      }
    }

    var m = tz.length;
    var a = 0;
    var b = m;
    while (a < m && tz[a] <= x0) {
      ++a;
    }
    while (b > a && tz[b - 1] > x1) {
      --b;
    }
    if (a > 0 || b < m) {
      tz = tz.sublist(a, b);
      m = b - a;
    }

    final bins = List<Bin<T>>.generate(
      m + 1,
      (i) => Bin<T>(i > 0 ? tz[i - 1] : x0, i < m ? tz[i] : x1),
    );

    if (step.isFinite) {
      if (step > 0) {
        for (var i = 0; i < n; ++i) {
          final x = values[i];
          if (x != null && x0 <= x && x <= x1) {
            final idx = ((x - x0) / step).floor();
            bins[idx < 0 ? 0 : (idx < m ? idx : m)].add(items[i]);
          }
        }
      } else if (step < 0) {
        for (var i = 0; i < n; ++i) {
          final x = values[i];
          if (x != null && x0 <= x && x <= x1) {
            final j = ((x0 - x) * step).floor();
            final bump = (j >= 0 && j < m && tz[j] <= x) ? 1 : 0;
            final idx = j + bump;
            bins[idx < 0 ? 0 : (idx < m ? idx : m)].add(items[i]);
          }
        }
      }
    } else {
      for (var i = 0; i < n; ++i) {
        final x = values[i];
        if (x != null && x0 <= x && x <= x1) {
          bins[bisectRight<double>(tz, x, 0, m)].add(items[i]);
        }
      }
    }

    return bins;
  }

  List<Bin<T>> _binDoubleList(List<double> values, List<T> items) {
    final n = values.length;
    final xz = _isDefaultDomain ? extent<double>(values) : _domain(values);
    var x0 = xz?.$1 ?? double.nan;
    var x1 = xz?.$2 ?? double.nan;

    List<double> tz;
    var step = double.nan;

    final tv = _thresholdValues;
    if (tv != null) {
      tz = tv(values, x0, x1);
    } else {
      final tc = _thresholdCount ?? _defaultThresholdCount;
      final tn = tc(values, x0, x1).toDouble();
      final maxVal = x1;
      if (_isDefaultDomain) {
        final niced = nice(x0, x1, tn);
        x0 = niced.$1;
        x1 = niced.$2;
      }
      tz = ticks(x0, x1, tn);
      if (tz.isNotEmpty && tz[0] <= x0) {
        step = tickIncrement(x0, x1, tn);
      }
      if (tz.isNotEmpty && tz[tz.length - 1] >= x1) {
        if (maxVal >= x1 && _isDefaultDomain) {
          final st = tickIncrement(x0, x1, tn);
          if (st.isFinite) {
            if (st > 0) {
              x1 = ((x1 / st).floorToDouble() + 1.0) * st;
            } else if (st < 0) {
              x1 = ((x1 * -st).ceilToDouble() + 1.0) / -st;
            }
          }
        } else {
          tz = tz.sublist(0, tz.length - 1);
        }
      }
    }

    var m = tz.length;
    var a = 0;
    var b = m;
    while (a < m && tz[a] <= x0) {
      ++a;
    }
    while (b > a && tz[b - 1] > x1) {
      --b;
    }
    if (a > 0 || b < m) {
      tz = tz.sublist(a, b);
      m = b - a;
    }

    final lists = List<List<T>>.generate(m + 1, (_) => <T>[], growable: false);

    if (values is Float64List) {
      final f64 = values;
      if (step.isFinite) {
        if (step > 0) {
          for (var i = 0; i < n; ++i) {
            final x = f64[i];
            if (x0 <= x && x <= x1) {
              final d = (x - x0) / step;
              final idx = d >= m ? m : d.toInt();
              lists[idx].add(x as T);
            }
          }
        } else if (step < 0) {
          for (var i = 0; i < n; ++i) {
            final x = f64[i];
            if (x0 <= x && x <= x1) {
              final d = (x0 - x) * step;
              final int idx;
              if (d >= m) {
                idx = m;
              } else {
                final j = d.toInt();
                idx = tz[j] <= x ? j + 1 : j;
              }
              lists[idx].add(x as T);
            }
          }
        }
      } else {
        for (var i = 0; i < n; ++i) {
          final x = f64[i];
          if (x0 <= x && x <= x1) {
            lists[bisectRight<double>(tz, x, 0, m)].add(x as T);
          }
        }
      }
    } else if (step.isFinite) {
      if (step > 0) {
        for (var i = 0; i < n; ++i) {
          final x = values[i];
          if (x0 <= x && x <= x1) {
            final d = (x - x0) / step;
            final idx = d >= m ? m : d.toInt();
            lists[idx].add(items[i]);
          }
        }
      } else if (step < 0) {
        for (var i = 0; i < n; ++i) {
          final x = values[i];
          if (x0 <= x && x <= x1) {
            final d = (x0 - x) * step;
            final int idx;
            if (d >= m) {
              idx = m;
            } else {
              final j = d.toInt();
              idx = tz[j] <= x ? j + 1 : j;
            }
            lists[idx].add(items[i]);
          }
        }
      }
    } else {
      for (var i = 0; i < n; ++i) {
        final x = values[i];
        if (x0 <= x && x <= x1) {
          lists[bisectRight<double>(tz, x, 0, m)].add(items[i]);
        }
      }
    }

    return List<Bin<T>>.generate(
      m + 1,
      (i) => Bin<T>(i > 0 ? tz[i - 1] : x0, i < m ? tz[i] : x1, lists[i]),
    );
  }
}

/// Creates a numeric [BinGenerator] with default identity value, [extent]
/// domain, and [thresholdSturges] thresholds.
BinGenerator<T> bin<T extends num?>({
  BinDomainAccessor? domain,
  BinThresholdCount? thresholdsCount,
  BinThresholdValues? thresholdsValues,
}) => BinGenerator<T>(
  value: (d, _, _) => d,
  domain: domain,
  thresholdsCount: thresholdsCount,
  thresholdsValues: thresholdsValues,
  isDefaultIdentity: true,
);

/// Creates a [BinGenerator] for arbitrary data of type `T` using a 1-arg
/// numeric [value] accessor.
BinGenerator<T> binBy<T>(
  num? Function(T value) value, {
  BinDomainAccessor? domain,
  BinThresholdCount? thresholdsCount,
  BinThresholdValues? thresholdsValues,
}) => BinGenerator<T>(
  value: (d, _, _) => value(d),
  domain: domain,
  thresholdsCount: thresholdsCount,
  thresholdsValues: thresholdsValues,
);

/// Creates a [BinGenerator] for arbitrary data of type `T` using an indexed
/// numeric [value] accessor.
BinGenerator<T> binByIndexed<T>(
  BinValueAccessor<T> value, {
  BinDomainAccessor? domain,
  BinThresholdCount? thresholdsCount,
  BinThresholdValues? thresholdsValues,
}) => BinGenerator<T>(
  value: value,
  domain: domain,
  thresholdsCount: thresholdsCount,
  thresholdsValues: thresholdsValues,
);

/// Deprecated alias for [bin].
// Upstream d3-array exports histogram as a deprecated alias for bin.
// ignore: remove_deprecations_in_breaking_versions
@Deprecated('Use bin instead.')
BinGenerator<T> histogram<T extends num?>({
  BinDomainAccessor? domain,
  BinThresholdCount? thresholdsCount,
  BinThresholdValues? thresholdsValues,
}) => bin<T>(
  domain: domain,
  thresholdsCount: thresholdsCount,
  thresholdsValues: thresholdsValues,
);

/// Ensures `math` import is used cleanly for bounds clamping if needed.
int clampBinIndex(int i, int m) => math.min(m, math.max(0, i));
