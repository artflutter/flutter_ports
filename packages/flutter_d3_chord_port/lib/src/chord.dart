// Ported from d3-chord v3.0.1 src/chord.js (ISC, Mike Bostock).

/// Port of `src/chord.js` of d3-chord 3.0.1: [ChordSubgroup], [Chord],
/// [ChordGroup], [Chords], [ChordLayout], [chord], [chordDirected], and
/// [chordTranspose].
library;

import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_chord_port/src/math.dart';

/// Numeric comparator for [ChordLayout.sortGroups],
/// [ChordLayout.sortSubgroups], and [ChordLayout.sortChords].
///
/// Matches `d3.ascending`, `d3.descending`, and subtraction comparators such
/// as `(a, b) => b - a`.
typedef ChordComparator = num Function(double a, double b);

/// One endpoint (source or target) of a [Chord].
// DIVERGES(d3-chord): adapt-chord-typed-api, immutable typed ChordSubgroup.
final class const ChordSubgroup({
  /// Zero-based node index in the flow matrix.
  required final int index,

  /// Start angle in radians (0 at 12 o'clock, clockwise).
  required final double startAngle,

  /// End angle in radians (0 at 12 o'clock, clockwise).
  required final double endAngle,

  /// Flow value `matrix[i][j]` for this subgroup.
  required final double value,
}) {
  /// Creates an immutable [ChordSubgroup].
  this;

  @override
  // All fields are final and the class is const-immutable.
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) =>
      other is ChordSubgroup &&
      index == other.index &&
      startAngle == other.startAngle &&
      endAngle == other.endAngle &&
      value == other.value;

  @override
  // All fields are final and the class is const-immutable.
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => Object.hash(index, startAngle, endAngle, value);

  @override
  String toString() =>
      'ChordSubgroup(index: $index, startAngle: $startAngle, '
      'endAngle: $endAngle, value: $value)';
}

/// A bidirectional (or directed) flow ribbon between [source] and [target].
// DIVERGES(d3-chord): adapt-chord-typed-api, immutable typed Chord.
final class const Chord({
  /// Source subgroup (larger value in undirected mode).
  required final ChordSubgroup source,

  /// Target subgroup.
  required final ChordSubgroup target,
}) {
  /// Creates an immutable [Chord].
  this;

  @override
  // All fields are final and the class is const-immutable.
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) =>
      other is Chord && source == other.source && target == other.target;

  @override
  // All fields are final and the class is const-immutable.
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => Object.hash(source, target);

  @override
  String toString() => 'Chord(source: $source, target: $target)';
}

/// Outer arc descriptor for one node in a chord diagram.
// DIVERGES(d3-chord): adapt-chord-typed-api, immutable typed ChordGroup.
final class const ChordGroup({
  /// Zero-based node index in the flow matrix.
  required final int index,

  /// Start angle in radians (0 at 12 o'clock, clockwise).
  required final double startAngle,

  /// End angle in radians (0 at 12 o'clock, clockwise).
  required final double endAngle,

  /// Total flow value for node [index].
  required final double value,
}) {
  /// Creates an immutable [ChordGroup].
  this;

  @override
  // All fields are final and the class is const-immutable.
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) =>
      other is ChordGroup &&
      index == other.index &&
      startAngle == other.startAngle &&
      endAngle == other.endAngle &&
      value == other.value;

  @override
  // All fields are final and the class is const-immutable.
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => Object.hash(index, startAngle, endAngle, value);

  @override
  String toString() =>
      'ChordGroup(index: $index, startAngle: $startAngle, '
      'endAngle: $endAngle, value: $value)';
}

/// The list of [Chord] objects produced by [ChordLayout], together with the
/// outer [groups] list.
// DIVERGES(d3-chord): adapt-chord-typed-api, typed ListBase<Chord> with
// groups property.
final class Chords(
  final List<Chord> _chords, {

  /// Outer group arcs of length `n`, ordered by node index `0 .. n - 1`.
  required final List<ChordGroup> groups,
}) extends ListBase<Chord> {
  /// Creates a [Chords] collection backed by [_chords] and [groups].
  this;

  @override
  int get length => _chords.length;

  @override
  set length(int value) => _chords.length = value;

  @override
  Chord operator [](int index) => _chords[index];

  @override
  void operator []=(int index, Chord value) => _chords[index] = value;
}

const ChordGroup _emptyGroup = ChordGroup(
  index: 0,
  startAngle: 0,
  endAngle: 0,
  value: 0,
);

@pragma('vm:prefer-inline')
bool _isTruthy(double v) => v != 0 && !v.isNaN;

/// Stable sort of parallel `idx[0..len)` and `vals[0..len)` using [cmp].
///
/// Uses inline insertion sort for `len <= 32` and iterative bottom-up merge
/// sort for larger sizes, guaranteeing ES2019 stability with zero closures or
/// map allocations.
// DIVERGES(d3-chord): adapt-chord-fast-forms, unboxed stable insertion/merge
// sort on Int32List/Float64List buffers.
void _stableSortPairs(
  Int32List idx,
  Float64List vals,
  int len,
  ChordComparator cmp,
  Int32List tmpIdx,
  Float64List tmpVals,
) {
  if (len <= 1) return;
  if (len <= 12) {
    for (var i = 1; i < len; ++i) {
      final k = idx[i];
      final v = vals[i];
      var j = i - 1;
      while (j >= 0 && cmp(vals[j], v) > 0) {
        idx[j + 1] = idx[j];
        vals[j + 1] = vals[j];
        --j;
      }
      idx[j + 1] = k;
      vals[j + 1] = v;
    }
    return;
  }

  // Insertion-sort initial runs of size 8.
  const run = 8;
  for (var start = 0; start < len; start += run) {
    final end = start + run < len ? start + run : len;
    for (var i = start + 1; i < end; ++i) {
      final k = idx[i];
      final v = vals[i];
      var j = i - 1;
      while (j >= start && cmp(vals[j], v) > 0) {
        idx[j + 1] = idx[j];
        vals[j + 1] = vals[j];
        --j;
      }
      idx[j + 1] = k;
      vals[j + 1] = v;
    }
  }

  var srcIdx = idx;
  var srcVals = vals;
  var dstIdx = tmpIdx;
  var dstVals = tmpVals;
  for (var width = run; width < len; width <<= 1) {
    for (var lo = 0; lo < len; lo += width << 1) {
      final mid = lo + width < len ? lo + width : len;
      final hi = mid + width < len ? mid + width : len;
      var p = lo;
      var q = mid;
      var out = lo;
      while (p < mid && q < hi) {
        if (!(cmp(srcVals[p], srcVals[q]) > 0)) {
          dstIdx[out] = srcIdx[p];
          dstVals[out] = srcVals[p];
          ++p;
        } else {
          dstIdx[out] = srcIdx[q];
          dstVals[out] = srcVals[q];
          ++q;
        }
        ++out;
      }
      while (p < mid) {
        dstIdx[out] = srcIdx[p];
        dstVals[out] = srcVals[p];
        ++p;
        ++out;
      }
      while (q < hi) {
        dstIdx[out] = srcIdx[q];
        dstVals[out] = srcVals[q];
        ++q;
        ++out;
      }
    }
    final ti = srcIdx;
    srcIdx = dstIdx;
    dstIdx = ti;
    final tv = srcVals;
    srcVals = dstVals;
    dstVals = tv;
  }
  if (!identical(srcIdx, idx)) {
    for (var i = 0; i < len; ++i) {
      idx[i] = srcIdx[i];
      vals[i] = srcVals[i];
    }
  }
}

/// `chord.js:28` `chord`: circular chord layout generator for an `n × n` flow
/// matrix.
// DIVERGES(d3-chord): adapt-chord-typed-api, typed ChordLayout class.
// DIVERGES(d3-chord): adapt-chord-fast-forms, reusable unboxed
// Float64List/Int32List scratch buffers and stable inline sort.
final class ChordLayout._({
  required final bool _directed,
  required final bool _transpose,
}) {
  double _padAngle = 0;

  /// Comparator used to order outer groups by their total flow (`null` keeps
  /// matrix order).
  ChordComparator? sortGroups;

  /// Comparator used to order subgroups within each group (`null` keeps matrix
  /// order).
  ChordComparator? sortSubgroups;

  /// Comparator used to order the returned chords by combined flow (`null`
  /// keeps matrix order).
  ChordComparator? sortChords;

  // Reusable unboxed scratch buffers (never exposed in returned Chords).
  Float64List _flat = Float64List(0);
  Float64List _groupSums = Float64List(0);
  Int32List _groupIndex = Int32List(0);
  Float64List _groupSortVals = Float64List(0);
  Int32List _subIdx = Int32List(0);
  Float64List _subVals = Float64List(0);
  Int32List _tmpIdx = Int32List(0);
  Float64List _tmpVals = Float64List(0);

  void _ensureCapacity(int n, int n2) {
    if (_flat.length < n2) _flat = Float64List(n2);
    if (_groupSums.length < n) {
      _groupSums = Float64List(n);
      _groupIndex = Int32List(n);
      _groupSortVals = Float64List(n);
    }
    final subCap = _directed ? n * 2 : n;
    if (_subIdx.length < subCap) {
      _subIdx = Int32List(subCap);
      _subVals = Float64List(subCap);
    }
    if (_tmpIdx.length < subCap) {
      _tmpIdx = Int32List(subCap);
      _tmpVals = Float64List(subCap);
    }
  }

  void _ensureSortScratch(int len) {
    if (_tmpIdx.length < len) {
      _tmpIdx = Int32List(len);
      _tmpVals = Float64List(len);
    }
  }

  /// Pad angle in radians between adjacent groups (defaults to `0`).
  double get padAngle => _padAngle;

  /// Sets the pad angle in radians between adjacent groups, clamped to `>= 0`.
  set padAngle(double value) {
    _padAngle = math.max(0, value);
  }

  /// Computes the chord layout for the square `n × n` flow [matrix].
  Chords call(List<List<num>> matrix) {
    final n = matrix.length;
    if (n == 0) return Chords(<Chord>[], groups: <ChordGroup>[]);

    final n2 = n * n;
    _ensureCapacity(n, n2);
    final flat = _flat;
    final groupSums = _groupSums;
    final groupIndex = _groupIndex;

    // Flatten matrix into unboxed Float64List without division or modulo.
    if (_transpose) {
      for (var r = 0; r < n; ++r) {
        final row = matrix[r];
        if (row is List<double>) {
          for (var c = 0; c < n; ++c) {
            flat[c * n + r] = row[c];
          }
        } else {
          for (var c = 0; c < n; ++c) {
            flat[c * n + r] = row[c].toDouble();
          }
        }
      }
    } else {
      for (var r = 0; r < n; ++r) {
        final row = matrix[r];
        final base = r * n;
        if (row is List<double>) {
          for (var c = 0; c < n; ++c) {
            flat[base + c] = row[c];
          }
        } else {
          for (var c = 0; c < n; ++c) {
            flat[base + c] = row[c].toDouble();
          }
        }
      }
    }

    // Compute group sums and scaling factor from value to angle in [0, 2pi].
    var k = 0.0;
    if (_directed) {
      for (var i = 0; i < n; ++i) {
        var sum = 0.0;
        final rowOff = i * n;
        for (var j = 0; j < n; ++j) {
          sum += flat[rowOff + j] + flat[j * n + i];
        }
        groupSums[i] = sum;
        groupIndex[i] = i;
        k += sum;
      }
    } else {
      for (var i = 0; i < n; ++i) {
        var sum = 0.0;
        final rowOff = i * n;
        for (var j = 0; j < n; ++j) {
          sum += flat[rowOff + j];
        }
        groupSums[i] = sum;
        groupIndex[i] = i;
        k += sum;
      }
    }
    k = math.max(0, chordTau - _padAngle * n) / k;
    final dx = _isTruthy(k) ? _padAngle : chordTau / n;

    final sg = sortGroups;
    if (sg != null) {
      final sortVals = _groupSortVals;
      for (var i = 0; i < n; ++i) {
        sortVals[i] = groupSums[i];
      }
      _stableSortPairs(groupIndex, sortVals, n, sg, _tmpIdx, _tmpVals);
    }

    final sources = List<ChordSubgroup?>.filled(n2, null);
    final targets = List<ChordSubgroup?>.filled(n2, null);
    final groups = List<ChordGroup>.filled(n, _emptyGroup);
    final subIdx = _subIdx;
    final subVals = _subVals;
    final ss = sortSubgroups;

    var x = 0.0;
    var chordCount = 0;

    if (_directed) {
      for (var gi = 0; gi < n; ++gi) {
        final i = groupIndex[gi];
        final x0 = x;
        final rowOff = i * n;
        var m = 0;
        // Incoming j in [-n, -1] => src = -1 - j goes from n - 1 down to 0.
        for (var j = -n; j < 0; ++j) {
          final v = flat[(-1 - j) * n + i];
          if (_isTruthy(v)) {
            subIdx[m] = j;
            subVals[m] = -v;
            ++m;
          }
        }
        // Outgoing j in [0, n - 1].
        for (var j = 0; j < n; ++j) {
          final v = flat[rowOff + j];
          if (_isTruthy(v)) {
            subIdx[m] = j;
            subVals[m] = v;
            ++m;
          }
        }
        if (ss != null && m > 1) {
          _stableSortPairs(subIdx, subVals, m, ss, _tmpIdx, _tmpVals);
        }
        for (var si = 0; si < m; ++si) {
          final j = subIdx[si];
          if (j < 0) {
            final slot = (-1 - j) * n + i;
            final v = flat[slot];
            final start = x;
            x += v * k;
            if (sources[slot] == null && targets[slot] == null) ++chordCount;
            targets[slot] = ChordSubgroup(
              index: i,
              startAngle: start,
              endAngle: x,
              value: v,
            );
          } else {
            final slot = rowOff + j;
            final v = flat[slot];
            final start = x;
            x += v * k;
            if (sources[slot] == null && targets[slot] == null) ++chordCount;
            sources[slot] = ChordSubgroup(
              index: i,
              startAngle: start,
              endAngle: x,
              value: v,
            );
          }
        }
        groups[i] = ChordGroup(
          index: i,
          startAngle: x0,
          endAngle: x,
          value: groupSums[i],
        );
        x += dx;
      }
    } else {
      for (var gi = 0; gi < n; ++gi) {
        final i = groupIndex[gi];
        final x0 = x;
        final rowOff = i * n;
        var m = 0;
        for (var j = 0; j < n; ++j) {
          final v = flat[rowOff + j];
          if (_isTruthy(v) || _isTruthy(flat[j * n + i])) {
            subIdx[m] = j;
            subVals[m] = v;
            ++m;
          }
        }
        if (ss != null && m > 1) {
          _stableSortPairs(subIdx, subVals, m, ss, _tmpIdx, _tmpVals);
        }
        for (var si = 0; si < m; ++si) {
          final j = subIdx[si];
          final v = flat[rowOff + j];
          final start = x;
          x += v * k;
          final sub = ChordSubgroup(
            index: i,
            startAngle: start,
            endAngle: x,
            value: v,
          );
          if (i < j) {
            final slot = rowOff + j;
            final t = targets[slot];
            if (t == null) {
              if (sources[slot] == null) ++chordCount;
              sources[slot] = sub;
            } else if (sub.value < t.value) {
              sources[slot] = t;
              targets[slot] = sub;
            } else {
              sources[slot] = sub;
            }
          } else if (i == j) {
            final slot = rowOff + i;
            if (sources[slot] == null) ++chordCount;
            sources[slot] = sub;
            targets[slot] = sub;
          } else {
            final slot = j * n + i;
            final s = sources[slot];
            if (s == null) {
              if (targets[slot] == null) ++chordCount;
              targets[slot] = sub;
            } else if (s.value < sub.value) {
              sources[slot] = sub;
              targets[slot] = s;
            } else {
              targets[slot] = sub;
            }
          }
        }
        groups[i] = ChordGroup(
          index: i,
          startAngle: x0,
          endAngle: x,
          value: groupSums[i],
        );
        x += dx;
      }
    }

    if (chordCount == 0) {
      return Chords(<Chord>[], groups: groups);
    }

    // Collect non-empty chords in ascending slot order (Object.values order).
    Chord? firstChord;
    var firstIdx = 0;
    for (var slot = 0; slot < n2; ++slot) {
      final s = sources[slot];
      if (s != null) {
        firstChord = Chord(source: s, target: targets[slot]!);
        firstIdx = slot;
        break;
      }
    }
    final chords = List<Chord>.filled(chordCount, firstChord!);
    var out = 1;
    for (var slot = firstIdx + 1; slot < n2; ++slot) {
      final s = sources[slot];
      if (s != null) {
        chords[out++] = Chord(source: s, target: targets[slot]!);
      }
    }

    final sc = sortChords;
    if (sc != null && chordCount > 1) {
      final cIdx = Int32List(chordCount);
      final cVals = Float64List(chordCount);
      for (var i = 0; i < chordCount; ++i) {
        final c = chords[i];
        cIdx[i] = i;
        cVals[i] = c.source.value + c.target.value;
      }
      _ensureSortScratch(chordCount);
      _stableSortPairs(cIdx, cVals, chordCount, sc, _tmpIdx, _tmpVals);
      final sorted = List<Chord>.filled(chordCount, chords[cIdx[0]]);
      for (var i = 1; i < chordCount; ++i) {
        sorted[i] = chords[cIdx[i]];
      }
      return Chords(sorted, groups: groups);
    }

    return Chords(chords, groups: groups);
  }
}

/// `chord.js:16` default export: constructs a new undirected [ChordLayout].
ChordLayout chord({
  double padAngle = 0,
  ChordComparator? sortGroups,
  ChordComparator? sortSubgroups,
  ChordComparator? sortChords,
}) => ChordLayout._(directed: false, transpose: false)
  ..padAngle = padAngle
  ..sortGroups = sortGroups
  ..sortSubgroups = sortSubgroups
  ..sortChords = sortChords;

/// `chord.js:20` `chordTranspose`: constructs a transposed undirected
/// [ChordLayout].
ChordLayout chordTranspose({
  double padAngle = 0,
  ChordComparator? sortGroups,
  ChordComparator? sortSubgroups,
  ChordComparator? sortChords,
}) => ChordLayout._(directed: false, transpose: true)
  ..padAngle = padAngle
  ..sortGroups = sortGroups
  ..sortSubgroups = sortSubgroups
  ..sortChords = sortChords;

/// `chord.js:24` `chordDirected`: constructs a directed [ChordLayout] where
/// each chord `i -> j` is generated from `matrix[i][j]` alone.
ChordLayout chordDirected({
  double padAngle = 0,
  ChordComparator? sortGroups,
  ChordComparator? sortSubgroups,
  ChordComparator? sortChords,
}) => ChordLayout._(directed: true, transpose: false)
  ..padAngle = padAngle
  ..sortGroups = sortGroups
  ..sortSubgroups = sortSubgroups
  ..sortChords = sortChords;
