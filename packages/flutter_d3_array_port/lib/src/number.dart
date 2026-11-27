// Ported from d3-array v3.2.4 src/number.js (ISC, Mike Bostock).

/// Port of `src/number.js` of d3-array 3.2.4.
library;

/// Converts a nullable numeric value [x] to `double`, returning `double.nan`
/// for `null`.
// DIVERGES(d3-array): adapt-array-typed-api, takes num? instead of coercing
// arbitrary JS objects/strings.
@pragma('vm:prefer-inline')
double arrayNumber(num? x) => x == null ? double.nan : x.toDouble();

/// Yields non-null, non-NaN numeric values from [values] as `double`.
// DIVERGES(d3-array): adapt-array-typed-api, typed Iterable<num?> without JS
// string/object coercion.
Iterable<double> arrayNumbers(Iterable<num?> values) sync* {
  for (final value in values) {
    if (value != null) {
      final d = value.toDouble();
      if (d >= d) yield d;
    }
  }
}

/// Yields non-null, non-NaN numeric values extracted from [values] via
/// [valueof].
Iterable<double> arrayNumbersBy<T>(
  Iterable<T> values,
  num? Function(T value) valueof,
) sync* {
  for (final value in values) {
    final v = valueof(value);
    if (v != null) {
      final d = v.toDouble();
      if (d >= d) yield d;
    }
  }
}

/// Yields non-null, non-NaN numeric values extracted from [values] via indexed
/// [valueof].
Iterable<double> arrayNumbersByIndexed<T>(
  Iterable<T> values,
  num? Function(T value, int index, Iterable<T> values) valueof,
) sync* {
  var index = -1;
  for (final value in values) {
    final v = valueof(value, ++index, values);
    if (v != null) {
      final d = v.toDouble();
      if (d >= d) yield d;
    }
  }
}
