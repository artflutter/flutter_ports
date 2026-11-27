// Ported from d3-chord v3.0.1 test/ribbon-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_chord_port/d3_chord.dart';
import 'package:test/test.dart';

const _sampleSub = ChordSubgroup(
  index: 0,
  startAngle: 42,
  endAngle: 42,
  value: 1,
);

const _sampleChord = Chord(
  source: _sampleSub,
  target: ChordSubgroup(index: 1, startAngle: 1, endAngle: 2, value: 3),
);

void main() {
  // DIVERGES(d3-chord): adapt-chord-typed-api, typed Chord/ChordSubgroup
  // accessors and *Const constant setters replace untyped JS object literals.
  test('ribbon() has the expected defaults', () {
    final r = ribbon(radius: 42);
    expect(r.radius(_sampleSub), 42);
    expect(r.startAngle(_sampleSub), 42);
    expect(r.endAngle(_sampleSub), 42);
    expect(r.source(_sampleChord), _sampleChord.source);
    expect(r.target(_sampleChord), _sampleChord.target);
    expect(r.context, isNull);
    expect(r.headRadius, isNull);
    expect(r.padAngle(_sampleChord), 0);
  });

  test('ribbon.radius(radius) sets the radius accessor', () {
    double foo(ChordSubgroup d) => d.value;
    final r = ribbon()..radius = foo;
    expect(r.radius, same(foo));
    expect(r.sourceRadius, same(foo));
    expect(r.targetRadius, same(foo));
    r.radiusConst(42);
    expect(r.radius(_sampleSub), 42);
    expect(r.targetRadius(_sampleSub), 42);
  });

  test('ribbon.startAngle(startAngle) sets the startAngle accessor', () {
    double foo(ChordSubgroup d) => d.value;
    final r = ribbon()..startAngle = foo;
    expect(r.startAngle, same(foo));
    r.startAngleConst(1.2);
    expect(r.startAngle(_sampleSub), 1.2);
  });

  test('ribbon.endAngle(endAngle) sets the endAngle accessor', () {
    double foo(ChordSubgroup d) => d.value;
    final r = ribbon()..endAngle = foo;
    expect(r.endAngle, same(foo));
    r.endAngleConst(1.2);
    expect(r.endAngle(_sampleSub), 1.2);
  });

  test('ribbon.source(source) sets the source accessor', () {
    ChordSubgroup foo(Chord d) => d.target;
    final r = ribbon()..source = foo;
    expect(r.source, same(foo));
  });

  test('ribbon.target(target) sets the target accessor', () {
    ChordSubgroup foo(Chord d) => d.source;
    final r = ribbon()..target = foo;
    expect(r.target, same(foo));
  });
}
