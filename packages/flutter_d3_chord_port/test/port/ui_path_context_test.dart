// Original code, not ported from d3-chord: direct UiPathContext tests.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_d3_chord_port/flutter_d3_chord_port.dart';
import 'package:flutter_d3_path_port/flutter_d3_path_port.dart';
import 'package:test/test.dart';

const _matrix = <List<double>>[
  [11975, 5871, 8916, 2868],
  [1951, 10048, 2060, 6171],
  [8010, 16145, 8090, 8045],
  [1013, 990, 940, 6907],
];

void main() {
  test('ribbon draws directly to UiPathContext with valid bounds', () {
    final chords = chord(padAngle: 0.05)(_matrix);
    final ctx = uiPathContext();
    final gen = ribbon(radius: 180)..context = ctx;
    for (final c in chords) {
      expect(gen(c), isNull);
    }
    final bounds = ctx.path.getBounds();
    expect(bounds.width, inInclusiveRange(300, 380));
    expect(bounds.height, inInclusiveRange(300, 380));
    // Point just inside the first chord's source arc is contained.
    final mid =
        (chords.first.source.startAngle + chords.first.source.endAngle) / 2 -
        math.pi / 2;
    final single = ribbon(radius: 180).toUiPath(chords.first);
    expect(
      single.contains(ui.Offset(160 * math.cos(mid), 160 * math.sin(mid))),
      isTrue,
    );
    expect(single.contains(const ui.Offset(250, 250)), isFalse);
  });

  test('toUiPath and drawToUiPath reuse UiPathContext across ribbons', () {
    final directed = chordDirected(padAngle: 0.04)(_matrix);
    final arrow = ribbonArrow(
      sourceRadius: 160,
      targetRadius: 152,
      headRadius: 12,
      padAngle: 0.01,
    );
    final reusable = uiPathContext();
    for (final c in directed) {
      reusable.reset();
      final p = arrow.toUiPath(c, reusable);
      final bounds = p.getBounds();
      expect(bounds.width, greaterThan(0));
      expect(bounds.height, greaterThan(0));
    }

    reusable.reset();
    for (final c in directed) {
      arrow.drawToUiPath(c, reusable);
    }
    expect(reusable.path.getBounds().width, greaterThan(250));
  });
}
