// Original code, not ported from d3-chord: comprehensive unit tests.

import 'dart:math' as math;

import 'package:flutter_d3_chord_port/d3_chord.dart';
import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:test/test.dart';

const _circosMatrix = <List<double>>[
  [11975, 5871, 8916, 2868],
  [1951, 10048, 2060, 6171],
  [8010, 16145, 8090, 8045],
  [1013, 990, 940, 6907],
];

final class _CustomEndpoint({
  required final double r,
  required final double a0,
  required final double a1,
});

final class _CustomLink({
  required final _CustomEndpoint from,
  required final _CustomEndpoint to,
  required final double gap,
  required final double arrowHead,
});

void main() {
  group('ChordLayout', () {
    test('empty matrix returns empty Chords and groups', () {
      final res = chord()(<List<double>>[]);
      expect(res, isEmpty);
      expect(res.groups, isEmpty);
    });

    test('zero matrix produces zero-width groups and no chords', () {
      final res = chord(padAngle: 0.1)(const [
        [0, 0, 0],
        [0, 0, 0],
        [0, 0, 0],
      ]);
      expect(res, isEmpty);
      expect(res.groups, hasLength(3));
      for (var i = 0; i < 3; ++i) {
        expect(res.groups[i].index, i);
        expect(res.groups[i].value, 0);
        expect(res.groups[i].startAngle, closeTo(i * 0.1, 1e-12));
        expect(res.groups[i].endAngle, closeTo(i * 0.1, 1e-12));
      }
    });

    test('padAngle clamps negative values to 0 and handles >= tau / n', () {
      final c = chord(padAngle: -1.5);
      expect(c.padAngle, 0);
      c.padAngle = -0.25;
      expect(c.padAngle, 0);

      // When padAngle * n >= tau, k == 0 so dx = tau / n.
      final hugePad = chord(padAngle: 3.5)(const [
        [10, 5],
        [5, 10],
      ]);
      expect(hugePad.groups[0].startAngle, 0);
      expect(hugePad.groups[0].endAngle, 0);
      expect(hugePad.groups[1].startAngle, closeTo(math.pi, 1e-12));
      expect(hugePad.groups[1].endAngle, closeTo(math.pi, 1e-12));
    });

    test('chordDirected emits one chord per non-zero directed entry', () {
      const m = <List<double>>[
        [0, 10, 0],
        [5, 2, 8],
        [0, 0, 0],
      ];
      final res = chordDirected(padAngle: 0.02)(m);
      // Non-zero entries: (0,1)=10, (1,0)=5, (1,1)=2, (1,2)=8 (4 chords).
      expect(res, hasLength(4));
      expect(res.groups, hasLength(3));
      // Group 0 sum = out(10) + in(5) = 15
      expect(res.groups[0].value, 15);
      // Group 1 sum = out(5+2+8) + in(10+2) = 27
      expect(res.groups[1].value, 27);
      // Group 2 sum = out(0) + in(8) = 8
      expect(res.groups[2].value, 8);
      // Directed self-loop (1,1) has distinct source and target arcs.
      final selfLoop = res.singleWhere(
        (c) => c.source.index == 1 && c.target.index == 1,
      );
      expect(selfLoop.source.startAngle, isNot(selfLoop.target.startAngle));
    });

    test('chordTranspose transposes matrix before layout', () {
      final transposed = chordTranspose()(_circosMatrix);
      final manual = List<List<double>>.generate(
        4,
        (i) => List<double>.generate(4, (j) => _circosMatrix[j][i]),
      );
      final expected = chord()(manual);
      expect(transposed.groups, expected.groups);
      expect(transposed, expected);
    });

    test('sortGroups, sortSubgroups, and sortChords apply stably', () {
      final c = chord(
        padAngle: 0.04,
        sortGroups: (a, b) => b - a,
        sortSubgroups: (a, b) => a - b,
        sortChords: (a, b) => b - a,
      );
      final res = c(_circosMatrix);
      // Largest group (index 2, value 40290) starts at angle 0.
      expect(res.groups[2].startAngle, 0);
      // Chords are sorted descending by combined flow.
      for (var i = 1; i < res.length; ++i) {
        final prev = res[i - 1].source.value + res[i - 1].target.value;
        final curr = res[i].source.value + res[i].target.value;
        expect(prev, greaterThanOrEqualTo(curr));
      }
      // Tie-breaking stability: equal-value matrix keeps original index order.
      const tieMatrix = <List<double>>[
        [1, 1, 1],
        [1, 1, 1],
        [1, 1, 1],
      ];
      final stable = chord(
        sortGroups: (a, b) => b - a,
        sortSubgroups: (a, b) => b - a,
        sortChords: (a, b) => b - a,
      )(tieMatrix);
      expect(stable.groups[0].startAngle, 0);
      expect(
        stable.groups[1].startAngle,
        greaterThan(stable.groups[0].startAngle),
      );
      expect(
        stable.groups[2].startAngle,
        greaterThan(stable.groups[1].startAngle),
      );
    });

    test(
      'Chords extends ListBase<Chord> and value classes support ==/hashCode',
      () {
        final res = chord()(_circosMatrix);
        expect(res, isA<List<Chord>>());
        expect(res.first, res[0]);
        expect(res.first.hashCode, res[0].hashCode);
        expect(res.first.toString(), contains('Chord('));
        expect(res.groups.first.toString(), contains('ChordGroup('));
        expect(res.first.source.toString(), contains('ChordSubgroup('));
        // Mutation through ListBase works.
        final first = res.first;
        res[0] = res.last;
        expect(res[0], res.last);
        res[0] = first;
      },
    );
  });

  group('RibbonGenerator', () {
    test('ribbon produces README reference SVG path string', () {
      final r = ribbon(radius: 240);
      const c = Chord(
        source: ChordSubgroup(
          index: 0,
          startAngle: 0.7524114,
          endAngle: 1.1212972,
          value: 5871,
        ),
        target: ChordSubgroup(
          index: 1,
          startAngle: 1.8617078,
          endAngle: 1.9842927,
          value: 1951,
        ),
      );
      final svg = r(c)!;
      const expected =
          'M164.0162810494058,-175.21032946354026'
          'A240,240,0,0,1,216.1595644740915,-104.28347273835429'
          'Q0,0,229.9158815306728,68.8381247563705'
          'A240,240,0,0,1,219.77316791012538,96.43523560788266'
          'Q0,0,164.0162810494058,-175.21032946354026Z';
      final numRe = RegExp(r'-?\d+(?:\.\d+)?(?:e[+-]?\d+)?');
      expect(svg.replaceAll(numRe, '#'), expected.replaceAll(numRe, '#'));
      final aNums = numRe
          .allMatches(svg)
          .map((m) => double.parse(m.group(0)!))
          .toList();
      final eNums = numRe
          .allMatches(expected)
          .map((m) => double.parse(m.group(0)!))
          .toList();
      expect(aNums.length, eNums.length);
      for (var i = 0; i < eNums.length; ++i) {
        expect(aNums[i], closeTo(eNums[i], 1e-11));
      }
    });

    test('ribbonArrow emits quadraticCurveTo + two lineTo segments', () {
      final r = ribbonArrow(radius: 200, headRadius: 15);
      expect(r.headRadius, isNotNull);
      final chords = chordDirected(padAngle: 0.04)(_circosMatrix);
      final d = r(chords.first)!;
      expect(d, startsWith('M'));
      expect(d, contains('A200,200,'));
      expect(d, contains('Q0,0,'));
      expect(d, contains('L'));
      expect(d, endsWith('Z'));
    });

    test('ribbon draws directly into CanvasPath context and draw()', () {
      final buf = path();
      final r = ribbon(radius: 150, context: buf);
      final chords = chord()(_circosMatrix);
      expect(r(chords[1]), isNull);
      final viaContext = buf.toString();

      final buf2 = path();
      final rNoCtx = ribbon(radius: 150)..draw(chords[1], buf2);
      expect(buf2.toString(), viaContext);
      expect(rNoCtx(chords[1]), viaContext);
    });

    test(
      'ribbon padAngle collapses narrow arcs and handles reversed angles',
      () {
        final r = ribbon(radius: 100, padAngle: 0.2);
        const narrow = Chord(
          source: ChordSubgroup(
            index: 0,
            startAngle: 0.5,
            endAngle: 0.55,
            value: 1,
          ),
          target: ChordSubgroup(
            index: 1,
            startAngle: 2,
            endAngle: 1.4,
            value: 2,
          ),
        );
        final svg = r(narrow);
        expect(svg, isNotNull);
        expect(svg, endsWith('Z'));
      },
    );

    test('self-loop ribbon skips target arc when sa0==ta0 and sa1==ta1', () {
      final r = ribbon(radius: 120);
      final chords = chord()(_circosMatrix);
      final selfLoop = chords.first; // (0, 0)
      final svg = r(selfLoop)!;
      // Only one 'A' command (source arc), not two!
      expect('A'.allMatches(svg).length, 1);
    });

    test('ribbonBy and ribbonArrowBy work with fully custom typed models', () {
      final gen = ribbonArrowBy<_CustomLink, _CustomEndpoint>(
        source: (l) => l.from,
        target: (l) => l.to,
        sourceRadius: (e) => e.r,
        targetRadius: (e) => e.r - 8,
        startAngle: (e) => e.a0,
        endAngle: (e) => e.a1,
        padAngle: (l) => l.gap,
        headRadius: (l) => l.arrowHead,
      );
      final link = _CustomLink(
        from: _CustomEndpoint(r: 180, a0: 0.1, a1: 0.5),
        to: _CustomEndpoint(r: 180, a0: 2, a1: 2.4),
        gap: 0.02,
        arrowHead: 12,
      );
      final svg = gen(link);
      expect(svg, isNotNull);
      expect(svg, contains('A180,180,'));
      expect(svg, contains('L'));

      final plain = ribbonBy<_CustomLink, _CustomEndpoint>(
        source: (l) => l.from,
        target: (l) => l.to,
        radiusConst: 150,
        startAngle: (e) => e.a0,
        endAngle: (e) => e.a1,
        padAngleConst: 0.01,
      );
      expect(plain(link), contains('A150,150,'));
    });

    test('internal helpers chordConstant and chordArraySlice work', () {
      final c = chordConstant(42);
      expect(c(), 42);
      expect(chordArraySlice([1, 2, 3, 4], 1, 3), [2, 3]);
    });
  });
}
