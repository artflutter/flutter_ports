// Original code, not ported from Chart.js: core.scale.autoskip has no spec.
@TestOn('vm')
library;

import 'package:flutter_chartjs_port/src/core/core.scale.autoskip.dart';
import 'package:flutter_chartjs_port/src/core/core.scale.dart' show Tick;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import 'scale_autoskip_reference.dart';

// test/specs has no core.scale.autoskip.tests.js. The chart cases of
// core.scale.tests.js that test autoSkip need a line controller (phase 7).
// These tests cover autoSkip and its private helpers determineMaxTicks,
// calculateSpacing, getMajorIndices, skipMajors, skip and getEvenSpacing
// (AGENTS.md rule 3). The expected values are in
// scale_autoskip_reference.dart, which
// tool/reference/scale_autoskip_reference.mjs writes from
// src/core/core.scale.autoskip.js at v4.5.1 in Node.js v24.22.1 on arm64
// (Chart.js ADR 0045). core.scale.autoskip imports core.scale, which is not
// a pure layer. Thus this file runs on the VM only.

/// The scale object `{options, _tickSize(), _length, _maxLength}` of a
/// case, passed as a [types.Scale]. autoSkip reads no other member.
final class _Scale implements types.Scale {
  _Scale(this.options, this._tickSize, this.length, this.maxLength);

  @override
  final Map<String, Object?> options;

  final double _tickSize;

  @override
  final double length;

  @override
  final double maxLength;

  @override
  double tickSize() => _tickSize;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The ticks of [c]: `{value: i}`, with `major: true` at each index of
/// `c.majors`.
List<Tick> _ticks(AutoskipReferenceCase c) => [
  for (var i = 0; i < c.count; i++)
    if (c.majors.contains(i))
      Tick(value: i.toDouble(), major: true)
    else
      Tick(value: i.toDouble()),
];

void main() {
  test('the reference comes from Node.js v24.22.1 on arm64', () {
    expect(autoskipReferenceNode, 'v24.22.1');
    expect(autoskipReferenceArch, 'arm64');
  });

  group('autoSkip', () {
    for (final c in autoskipReference) {
      test(c.name, () {
        final ticks = _ticks(c);
        final kept = autoSkip(
          _Scale(c.options, c.tickSize, c.length, c.maxLength),
          ticks,
        );
        expect([for (final tick in kept) ticks.indexOf(tick)], c.kept);
      });
    }

    test('returns a new list of the same tick objects', () {
      final ticks = [for (var i = 0; i < 5; i++) Tick(value: i.toDouble())];
      final kept = autoSkip(
        _Scale(
          <String, Object?>{
            'offset': false,
            'ticks': <String, Object?>{'major': <String, Object?>{}},
          },
          10,
          400,
          400,
        ),
        ticks,
      );
      expect(identical(kept, ticks), isFalse);
      expect(kept, hasLength(5));
      for (var i = 0; i < 5; i++) {
        expect(identical(kept[i], ticks[i]), isTrue);
      }
    });

    test('a scale without tick options throws a TypeError', () {
      // `scale.options.ticks.maxTicksLimit` of an absent `ticks` reads a
      // property of undefined.
      expect(
        () => autoSkip(
          _Scale(<String, Object?>{'offset': false}, 10, 400, 400),
          [Tick(value: 0)],
        ),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
