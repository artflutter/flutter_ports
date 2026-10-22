// Original code, not ported from Chart.js: tests of the filler options.

// The tests of `decodeFill` and `resolveTarget` of
// lib/src/plugins/plugin.filler/filler.options.dart without a chart. The
// expected values are the values of the spec (plugin.filler.tests.js:51-297)
// and of the Node.js run of the pinned source files of
// tool/reference/filler_target_reference.mjs (Node.js v24.12.0 on x64, the
// cases `decodeFill ...` of filler_target_reference.dart): `'-0'`, `''`,
// `[]`, NaN, Infinity, `'+1'`, `{value: NaN}` and `{target: 'origin'}`.
// filler.target_test.dart compares all the cases of that run. The file is
// a pure layer test: test:web runs it too.

import 'package:flutter_chartjs_port/src/elements/element.line.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/filler.options.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/index.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:test/test.dart';

/// `_decodeFill` of a line whose `fill` option is [fill] (absent for
/// [undefined]) and whose `backgroundColor` is [backgroundColor].
Object _decode(
  Object? fill, {
  double index = 1,
  double count = 4,
  Object? backgroundColor = undefined,
}) => decodeFill(
  LineElement(<String, Object?>{
    'options': <String, Object?>{
      if (!identical(fill, undefined)) 'fill': fill,
      if (!identical(backgroundColor, undefined))
        'backgroundColor': backgroundColor,
    },
  }),
  index,
  count,
);

/// A chart that the sources of [resolveTarget] name and never read.
final class _Chart implements types.Chart {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The sources of the fills [fills] with the visibility [visible].
List<FillerSource?> _sources(List<Object> fills, List<bool> visible) => [
  for (var i = 0; i < fills.length; i++)
    FillerSource(
      visible: visible[i],
      index: i.toDouble(),
      fill: fills[i],
      chart: _Chart(),
      axis: 'x',
      scale: null,
      line: LineElement(),
    ),
];

void main() {
  group('decodeFill', () {
    test('the boundaries (plugin.filler.tests.js:51)', () {
      expect(_decode('origin'), 'origin');
      expect(_decode('start'), 'start');
      expect(_decode('end'), 'end');
    });

    test('the absolute dataset index (:66)', () {
      expect(_decode(1, index: 0), 1);
      expect(_decode(3), 3);
      expect(_decode(0, index: 2), 0);
      expect(_decode(2, index: 3), 2);
    });

    test('the relative dataset index (:82)', () {
      expect(_decode('+3', index: 0), 3);
      expect(_decode('-1'), 0);
      expect(_decode('+1', index: 2), 3);
      expect(_decode('-2', index: 3), 1);
    });

    test('true and false (:103)', () {
      expect(_decode(true, index: 0), 'origin');
      expect(_decode(false), false);
    });

    test('the self dataset index (:117)', () {
      expect(_decode(0, index: 0), false);
      expect(_decode('-0'), false);
      expect(_decode('+0', index: 2), false);
      expect(_decode(3, index: 3), false);
    });

    test('the out of bounds dataset index (:138)', () {
      expect(_decode(-2, index: 0), false);
      expect(_decode(4), false);
      expect(_decode('-3', index: 2), false);
      expect(_decode('+1', index: 3), false);
    });

    test('the invalid values (:159)', () {
      for (final fill in <Object?>[
        'foo',
        '+foo',
        '-foo',
        '+1.1',
        '-2.2',
        3.3,
        -4.4,
        double.nan,
        double.infinity,
        '',
        null,
        <Object?>[],
      ]) {
        expect(_decode(fill), false, reason: '$fill');
      }
    });

    test('the values of the Node.js run', () {
      expect(_decode('-0'), false);
      expect(_decode(''), false);
      expect(_decode(<Object?>[]), false);
      expect(_decode(double.nan), false);
      expect(_decode(double.infinity), false);
      expect(_decode('+1'), 2);
      expect(_decode(<String, Object?>{'value': double.nan}), false);
      expect(_decode(<String, Object?>{'target': 'origin'}), 'origin');
    });

    test('an option object with a value is the object itself', () {
      final fill = <String, Object?>{'value': 2};
      expect(_decode(fill), same(fill));
      final target = <String, Object?>{'value': 3};
      expect(_decode(<String, Object?>{'target': target}), same(target));
    });

    test('no fill gives the backgroundColor test (filler.options.js:125)', () {
      expect(_decode(undefined, backgroundColor: 'red'), 'origin');
      expect(_decode(undefined), false);
      expect(_decode(undefined, backgroundColor: ''), false);
    });
  });

  group('resolveTarget', () {
    // plugin.filler.tests.js:197-269: the decoded fills of the spec chart.
    const fills = <Object>['start', 0.0, 1.0, 1.0, 5.0, 7.0, 5.0, 'end'];
    const visible = [false, false, false, false, true, true, true, false];

    test('propagate true (:198)', () {
      final sources = _sources(fills, visible);
      expect(
        [
          for (var i = 0; i < fills.length; i++)
            resolveTarget(sources, i, true),
        ],
        ['start', 'start', 'start', 'start', 5, 'end', 5, 'end'],
      );
    });

    test('propagate false (:235)', () {
      final sources = _sources(fills, visible);
      expect(
        [
          for (var i = 0; i < fills.length; i++)
            resolveTarget(sources, i, false),
        ],
        fills,
      );
    });

    test('the recursive propagation (:271)', () {
      final sources = _sources(
        const [2.0, 0.0, 1.0, 1.0],
        const [false, false, false, true],
      );
      expect(
        [for (var i = 0; i < 4; i++) resolveTarget(sources, i, true)],
        [false, false, false, false],
      );
    });

    test('a null source or an index past the end gives false', () {
      // Dataset 1 fills to the null source 0, dataset 2 to the index 5.
      final sources = _sources(
        const [0.0, 0.0, 5.0],
        const [true, true, true],
      )..[0] = null;
      expect(resolveTarget(sources, 1, true), false);
      expect(resolveTarget(sources, 2, true), false);
    });
  });
}
