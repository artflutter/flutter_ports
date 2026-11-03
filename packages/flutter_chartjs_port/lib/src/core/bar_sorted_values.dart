// Original code, not ported from Chart.js: sorted bar-value deduplication.

/// Deduplicate an owned finite sorted list, or decline before changing it.
/// The caller owns an ordinary numeric concatenation, not a user List getter.
/// Preserve arrayUnique's identity when unique and its Set zero normalization
/// when duplicates require a new growable list.
List<double>? uniqueSortedBarValues(List<double> values) {
  var previous = double.negativeInfinity;
  var uniqueCount = 0;
  for (final value in values) {
    if (!value.isFinite || value < previous) return null;
    if (uniqueCount == 0 || value != previous) uniqueCount++;
    previous = value;
  }
  if (uniqueCount == values.length) return values;

  final result = <double>[];
  previous = double.negativeInfinity;
  for (final value in values) {
    if (result.isEmpty || value != previous) {
      result.add(value == 0 ? 0 : value);
    }
    previous = value;
  }
  return result;
}
