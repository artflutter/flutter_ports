// Ported from d3-array v3.2.4 src/mode.js (ISC, Mike Bostock).

/// Port of `src/mode.js` of d3-array 3.2.4.
library;

@pragma('vm:prefer-inline')
bool _isValid<T>(T value) => value is! num || value >= value;

/// Returns the mode (most frequent value) of [values], ignoring `null` and
/// `NaN`. Ties are broken by first appearance. Returns `null` if no valid
/// values exist.
// DIVERGES(d3-array): adapt-array-typed-api, uses native Dart value-equal
// Map<T, int> (preserving insertion order and DateTime value equality).
T? mode<T>(Iterable<T?> values) {
  final counts = <T, int>{};
  for (final value in values) {
    if (value != null && _isValid(value)) {
      counts[value] = (counts[value] ?? 0) + 1;
    }
  }
  T? modeValue;
  var modeCount = 0;
  for (final entry in counts.entries) {
    if (entry.value > modeCount) {
      modeCount = entry.value;
      modeValue = entry.key;
    }
  }
  return modeValue;
}

/// Returns the mode of values extracted from [values] using [valueof].
K? modeBy<T, K>(Iterable<T> values, K? Function(T value) valueof) {
  final counts = <K, int>{};
  for (final element in values) {
    final value = valueof(element);
    if (value != null && _isValid(value)) {
      counts[value] = (counts[value] ?? 0) + 1;
    }
  }
  K? modeValue;
  var modeCount = 0;
  for (final entry in counts.entries) {
    if (entry.value > modeCount) {
      modeCount = entry.value;
      modeValue = entry.key;
    }
  }
  return modeValue;
}

/// Returns the mode of values extracted from [values] using indexed [valueof].
K? modeByIndexed<T, K>(
  Iterable<T> values,
  K? Function(T value, int index, Iterable<T> values) valueof,
) {
  final counts = <K, int>{};
  var index = -1;
  for (final element in values) {
    final value = valueof(element, ++index, values);
    if (value != null && _isValid(value)) {
      counts[value] = (counts[value] ?? 0) + 1;
    }
  }
  K? modeValue;
  var modeCount = 0;
  for (final entry in counts.entries) {
    if (entry.value > modeCount) {
      modeCount = entry.value;
      modeValue = entry.key;
    }
  }
  return modeValue;
}
