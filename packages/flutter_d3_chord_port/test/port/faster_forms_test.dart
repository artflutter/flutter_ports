// Original code, not ported from d3-chord: faster-form twin tests.

/// Verifies that every optimized hot path in `flutter_d3_chord_port` (row
/// `adapt-chord-fast-forms`) produces bit-identical results to the literal
/// upstream baseline algorithms across small (`n <= 32`) and large (`n > 32`)
/// matrices, all sort combinations, ties, directed/transpose layouts, and
/// plain/padded/arrow ribbons.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_chord_port/d3_chord.dart';
import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:test/test.dart';

final class _Lcg(var int seed) {
  double nextDouble() {
    seed = seed * 48271 % 2147483647;
    return seed / 2147483647.0;
  }
}

final class _RefSlot() {
  ChordSubgroup? source;
  ChordSubgroup? target;
}

int _sign(num c) => c < 0 ? -1 : (c > 0 ? 1 : 0);

bool _truthy(double v) => v != 0 && !v.isNaN;

/// Literal upstream `src/chord.js` baseline translation for twin testing.
Chords _baselineChord(
  List<List<num>> matrix, {
  required bool directed,
  required bool transpose,
  double padAngle = 0,
  ChordComparator? sortGroups,
  ChordComparator? sortSubgroups,
  ChordComparator? sortChords,
}) {
  final n = matrix.length;
  if (n == 0) return Chords(<Chord>[], groups: <ChordGroup>[]);

  final flat = Float64List(n * n);
  for (var i = 0; i < n * n; ++i) {
    flat[i] = transpose
        ? matrix[i % n][i ~/ n].toDouble()
        : matrix[i ~/ n][i % n].toDouble();
  }

  final groupSums = List<double>.filled(n, 0);
  final groupIndex = List<int>.generate(n, (i) => i);
  final slots = List<_RefSlot?>.filled(n * n, null);
  final groups = List<ChordGroup?>.filled(n, null);

  var k = 0.0;
  for (var i = 0; i < n; ++i) {
    var sum = 0.0;
    for (var j = 0; j < n; ++j) {
      sum += flat[i * n + j] + (directed ? flat[j * n + i] : 0.0);
    }
    groupSums[i] = sum;
    k += sum;
  }
  k = math.max(0, chordTau - padAngle * n) / k;
  final dx = _truthy(k) ? padAngle : chordTau / n;

  if (sortGroups != null) {
    groupIndex.sort((a, b) {
      final c = _sign(sortGroups(groupSums[a], groupSums[b]));
      return c != 0 ? c : a - b;
    });
  }

  var x = 0.0;
  for (final i in groupIndex) {
    final x0 = x;
    if (directed) {
      final sub = <int>[
        for (var j = -n; j < n; ++j)
          if (_truthy(j < 0 ? flat[(-1 - j) * n + i] : flat[i * n + j])) j,
      ];
      if (sortSubgroups != null) {
        final pos = <int, int>{
          for (var idx = 0; idx < sub.length; ++idx) sub[idx]: idx,
        };
        sub.sort((a, b) {
          final va = a < 0 ? -flat[(-1 - a) * n + i] : flat[i * n + a];
          final vb = b < 0 ? -flat[(-1 - b) * n + i] : flat[i * n + b];
          final c = _sign(sortSubgroups(va, vb));
          return c != 0 ? c : pos[a]! - pos[b]!;
        });
      }
      for (final j in sub) {
        if (j < 0) {
          final slotIdx = (-1 - j) * n + i;
          final slot = slots[slotIdx] ??= _RefSlot();
          final v = flat[slotIdx];
          final start = x;
          x += v * k;
          slot.target = ChordSubgroup(
            index: i,
            startAngle: start,
            endAngle: x,
            value: v,
          );
        } else {
          final slotIdx = i * n + j;
          final slot = slots[slotIdx] ??= _RefSlot();
          final v = flat[slotIdx];
          final start = x;
          x += v * k;
          slot.source = ChordSubgroup(
            index: i,
            startAngle: start,
            endAngle: x,
            value: v,
          );
        }
      }
    } else {
      final sub = <int>[
        for (var j = 0; j < n; ++j)
          if (_truthy(flat[i * n + j]) || _truthy(flat[j * n + i])) j,
      ];
      if (sortSubgroups != null) {
        final pos = <int, int>{
          for (var idx = 0; idx < sub.length; ++idx) sub[idx]: idx,
        };
        sub.sort((a, b) {
          final c = _sign(sortSubgroups(flat[i * n + a], flat[i * n + b]));
          return c != 0 ? c : pos[a]! - pos[b]!;
        });
      }
      for (final j in sub) {
        final v = flat[i * n + j];
        final start = x;
        x += v * k;
        final sg = ChordSubgroup(
          index: i,
          startAngle: start,
          endAngle: x,
          value: v,
        );
        final _RefSlot slot;
        if (i < j) {
          slot = (slots[i * n + j] ??= _RefSlot())..source = sg;
        } else {
          slot = (slots[j * n + i] ??= _RefSlot())..target = sg;
          if (i == j) slot.source = sg;
        }
        if (slot.source != null &&
            slot.target != null &&
            slot.source!.value < slot.target!.value) {
          final tmp = slot.source;
          slot
            ..source = slot.target
            ..target = tmp;
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

  final chords = <Chord>[
    for (var i = 0; i < slots.length; ++i)
      if (slots[i] != null)
        Chord(source: slots[i]!.source!, target: slots[i]!.target!),
  ];
  if (sortChords != null && chords.length > 1) {
    final idx = List<int>.generate(chords.length, (i) => i)
      ..sort((a, b) {
        final ca = chords[a];
        final cb = chords[b];
        final c = _sign(
          sortChords(
            ca.source.value + ca.target.value,
            cb.source.value + cb.target.value,
          ),
        );
        return c != 0 ? c : a - b;
      });
    return Chords(
      [for (final i in idx) chords[i]],
      groups: [for (final g in groups) g!],
    );
  }
  return Chords(chords, groups: [for (final g in groups) g!]);
}

/// Literal upstream `src/ribbon.js` baseline translation for twin testing.
String _baselineRibbon(
  Chord c, {
  required double sourceRadius,
  required double targetRadius,
  double padAngle = 0,
  double? headRadius,
}) {
  final ap = padAngle / 2;
  var sa0 = c.source.startAngle - chordHalfPi;
  var sa1 = c.source.endAngle - chordHalfPi;
  var ta0 = c.target.startAngle - chordHalfPi;
  var ta1 = c.target.endAngle - chordHalfPi;
  if (ap > chordEpsilon) {
    if ((sa1 - sa0).abs() > ap * 2 + chordEpsilon) {
      if (sa1 > sa0) {
        sa0 += ap;
        sa1 -= ap;
      } else {
        sa0 -= ap;
        sa1 += ap;
      }
    } else {
      sa0 = sa1 = (sa0 + sa1) / 2;
    }
    if ((ta1 - ta0).abs() > ap * 2 + chordEpsilon) {
      if (ta1 > ta0) {
        ta0 += ap;
        ta1 -= ap;
      } else {
        ta0 -= ap;
        ta1 += ap;
      }
    } else {
      ta0 = ta1 = (ta0 + ta1) / 2;
    }
  }
  final buf = path()
    ..moveTo(sourceRadius * math.cos(sa0), sourceRadius * math.sin(sa0))
    ..arc(0, 0, sourceRadius, sa0, sa1);
  if (sa0 != ta0 || sa1 != ta1) {
    if (headRadius != null) {
      final tr2 = targetRadius - headRadius;
      final ta2 = (ta0 + ta1) / 2;
      buf
        ..quadraticCurveTo(0, 0, tr2 * math.cos(ta0), tr2 * math.sin(ta0))
        ..lineTo(targetRadius * math.cos(ta2), targetRadius * math.sin(ta2))
        ..lineTo(tr2 * math.cos(ta1), tr2 * math.sin(ta1));
    } else {
      buf
        ..quadraticCurveTo(
          0,
          0,
          targetRadius * math.cos(ta0),
          targetRadius * math.sin(ta0),
        )
        ..arc(0, 0, targetRadius, ta0, ta1);
    }
  }
  buf
    ..quadraticCurveTo(
      0,
      0,
      sourceRadius * math.cos(sa0),
      sourceRadius * math.sin(sa0),
    )
    ..closePath();
  return buf.toString();
}

void main() {
  double asc(double a, double b) => a - b;
  double desc(double a, double b) => b - a;

  test('optimized ChordLayout matches baseline across sizes n=4, 16, 40', () {
    final r = _Lcg(2026);
    for (final n in [4, 16, 40]) {
      // Include ties (quantized values) and zeros to stress stable sorting
      // across both insertion sort (<= 32) and merge sort (> 32).
      final matrix = List<List<double>>.generate(
        n,
        (_) => List<double>.generate(n, (_) {
          final u = r.nextDouble();
          if (u < 0.25) return 0;
          return (r.nextDouble() * 12).floorToDouble() * 10;
        }),
      );

      for (final mode in [0, 1, 2]) {
        for (final sorted in [false, true]) {
          final layout = switch (mode) {
            0 => chord(
              padAngle: 0.02,
              sortGroups: sorted ? desc : null,
              sortSubgroups: sorted ? asc : null,
              sortChords: sorted ? desc : null,
            ),
            1 => chordDirected(
              padAngle: 0.02,
              sortGroups: sorted ? asc : null,
              sortSubgroups: sorted ? desc : null,
              sortChords: sorted ? asc : null,
            ),
            _ => chordTranspose(
              padAngle: 0.02,
              sortGroups: sorted ? desc : null,
              sortSubgroups: sorted ? desc : null,
              sortChords: sorted ? asc : null,
            ),
          };
          final actual = layout(matrix);
          final expected = _baselineChord(
            matrix,
            directed: mode == 1,
            transpose: mode == 2,
            padAngle: 0.02,
            sortGroups: layout.sortGroups,
            sortSubgroups: layout.sortSubgroups,
            sortChords: layout.sortChords,
          );
          expect(
            actual.groups,
            expected.groups,
            reason: 'n=$n mode=$mode s=$sorted',
          );
          expect(actual, expected, reason: 'n=$n mode=$mode s=$sorted');
        }
      }
    }
  });

  test(
    'optimized ChordLayout preserves independence across repeated calls',
    () {
      final layout = chord(
        padAngle: 0.03,
        sortGroups: desc,
        sortSubgroups: desc,
      );
      final first = layout(const [
        [10, 20],
        [30, 40],
      ]);
      final snapGroups = List<ChordGroup>.of(first.groups);
      final snapChords = List<Chord>.of(first);
      // Larger call grows internal scratch buffers.
      layout(const [
        [1, 2, 3, 4],
        [5, 6, 7, 8],
        [9, 10, 11, 12],
        [13, 14, 15, 16],
      ]);
      expect(first.groups, snapGroups);
      expect(first, snapChords);
    },
  );

  test('optimized RibbonGenerator matches baseline bit-for-bit', () {
    final chords = chord(padAngle: 0.04)(const [
      [11975, 5871, 8916, 2868],
      [1951, 10048, 2060, 6171],
      [8010, 16145, 8090, 8045],
      [1013, 990, 940, 6907],
    ]);
    final directed = chordDirected(padAngle: 0.04)(const [
      [0, 120, 45, 30],
      [80, 15, 210, 60],
      [0, 90, 0, 190],
      [55, 10, 95, 40],
    ]);

    final plainConst = ribbon(radius: 240);
    final plainFn = ribbon()..radius = ((_) => 240);
    final padded = ribbon(
      sourceRadius: 220,
      targetRadius: 205,
      padAngle: 0.015,
    );
    final arrowConst = ribbonArrow(
      sourceRadius: 200,
      targetRadius: 188,
      headRadius: 11,
      padAngle: 0.01,
    );
    final arrowFn = ribbonArrow()
      ..sourceRadius = ((_) => 200)
      ..targetRadius = ((_) => 188)
      ..headRadius = ((_) => 11)
      ..padAngle = ((_) => 0.01);

    for (final c in chords) {
      final basePlain = _baselineRibbon(
        c,
        sourceRadius: 240,
        targetRadius: 240,
      );
      expect(plainConst(c), basePlain);
      expect(plainFn(c), basePlain);
      expect(
        padded(c),
        _baselineRibbon(
          c,
          sourceRadius: 220,
          targetRadius: 205,
          padAngle: 0.015,
        ),
      );
    }
    for (final c in directed) {
      final baseArrow = _baselineRibbon(
        c,
        sourceRadius: 200,
        targetRadius: 188,
        padAngle: 0.01,
        headRadius: 11,
      );
      expect(arrowConst(c), baseArrow);
      expect(arrowFn(c), baseArrow);
    }
  });
}
