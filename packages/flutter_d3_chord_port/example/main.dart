// Original code, not ported from d3-chord: package example.

// Example prints chord layout and SVG ribbon outputs.
// ignore_for_file: avoid_print

import 'package:flutter_d3_chord_port/d3_chord.dart';

void main() {
  const matrix = <List<double>>[
    [11975, 5871, 8916, 2868],
    [1951, 10048, 2060, 6171],
    [8010, 16145, 8090, 8045],
    [1013, 990, 940, 6907],
  ];

  // 1. Undirected chord layout + ribbon SVG strings.
  final layout = chord(padAngle: 0.05, sortSubgroups: (a, b) => b - a);
  final chords = layout(matrix);
  final rib = ribbon(radius: 240);
  print('Groups: ${chords.groups.length}, Chords: ${chords.length}');
  for (final g in chords.groups) {
    print(
      'Group ${g.index}: ${g.startAngle.toStringAsFixed(3)}..'
      '${g.endAngle.toStringAsFixed(3)} (value=${g.value})',
    );
  }
  print('First ribbon path: ${rib(chords.first)}');

  // 2. Directed chord layout + arrow ribbon.
  final directedChords = chordDirected(padAngle: 0.04)(matrix);
  final arrow = ribbonArrow(radius: 240, headRadius: 12);
  print('Directed chords: ${directedChords.length}');
  print('First arrow ribbon path: ${arrow(directedChords.first)}');
}
