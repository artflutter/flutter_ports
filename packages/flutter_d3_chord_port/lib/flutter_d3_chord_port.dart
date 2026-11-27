// Original code, not ported from d3-chord: the public library of the package.

/// A native, fully statically typed Dart port of
/// [d3-chord](https://github.com/d3/d3-chord) 3.0.1 for Flutter.
///
/// Exports the pure Dart `d3_chord.dart` library (`chord`, `chordDirected`,
/// `chordTranspose`, `ChordLayout`, `Chords`, `Chord`, `ChordSubgroup`,
/// `ChordGroup`, `ribbon`, `ribbonArrow`, `ribbonBy`, `ribbonArrowBy`,
/// `RibbonGenerator`) plus direct Flutter `dart:ui.Path` helpers
/// (`lib/src/ui/chord_ui.dart`) powered by `UiPathContext` from
/// `flutter_d3_path_port` (ADR 0011, D3 ADR 0023).
library;

export 'package:flutter_d3_chord_port/d3_chord.dart';
export 'package:flutter_d3_chord_port/src/ui/chord_ui.dart';
