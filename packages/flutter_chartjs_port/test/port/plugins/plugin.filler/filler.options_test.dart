// Original code, not ported from Chart.js: tests of the filler options.

// The tests of `decodeFill` and `resolveTarget` of
// lib/src/plugins/plugin.filler/filler.options.dart without a chart. The
// expected values are the values of the spec (plugin.filler.tests.js:51-297)
// and of the Node.js run of the pinned source files of
// tool/reference/filler_target_reference.mjs (the cases `decodeFill ...` of
// filler_target_reference.dart): `'-0'`, `'+1'`, `{value: NaN}` and
// `{target: 'origin'}`, with the FillTarget of the port for each value
// (Chart.js ADR 0140, row adapt-fill-target-objects).
// filler.target_test.dart compares all the cases of that run. The file is
// a pure layer test: test:web runs it too.

import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/src/elements/element.line.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/plugins/fill_target.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/filler.options.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/index.dart';
import 'package:flutter_chartjs_port/src/types/chart_axis.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:test/test.dart';

/// `_decodeFill` of a line whose `fill` option is [fill] (absent for
/// [undefined]) and whose `backgroundColor` is [backgroundColor].
FillTarget _decode(
  Object? fill, {
  int index = 1,
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
final class _Chart() implements types.Chart {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The sources of the fills [fills] with the visibility [visible].
List<FillerSource?> _sources(List<FillTarget> fills, List<bool> visible) => [
  for (var i = 0; i < fills.length; i++)
    FillerSource(
      visible: visible[i],
      index: i,
      fill: fills[i],
      chart: _Chart(),
      axis: const XAxis(),
      scale: null,
      line: LineElement(),
    ),
];

/// The fill to the dataset at [index].
FillTarget _dataset(int index) => FillTarget.toDataset(index);

void main() {
  group('decodeFill', () {
    test('the boundaries (plugin.filler.tests.js:51)', () {
      expect(_decode(FillTarget.toOrigin), FillTarget.toOrigin);
      expect(_decode(FillTarget.toStart), FillTarget.toStart);
      expect(_decode(FillTarget.toEnd), FillTarget.toEnd);
    });

    test('the absolute dataset index (:66)', () {
      expect(_decode(_dataset(1), index: 0), _dataset(1));
      expect(_decode(_dataset(3)), _dataset(3));
      expect(_decode(_dataset(0), index: 2), _dataset(0));
      expect(_decode(_dataset(2), index: 3), _dataset(2));
    });

    test('the relative dataset index (:82)', () {
      expect(_decode(const FillTarget.toRelative(3), index: 0), _dataset(3));
      expect(_decode(FillTarget.toPrevious), _dataset(0));
      expect(_decode(FillTarget.toNext, index: 2), _dataset(3));
      expect(_decode(const FillTarget.toRelative(-2), index: 3), _dataset(1));
    });

    test('true and false (:103)', () {
      expect(_decode(FillTarget.toOrigin, index: 0), FillTarget.toOrigin);
      expect(_decode(FillTarget.none), FillTarget.none);
    });

    test('the self dataset index (:117)', () {
      expect(_decode(_dataset(0), index: 0), FillTarget.none);
      expect(_decode(const FillTarget.toRelative(0)), FillTarget.none);
      expect(
        _decode(const FillTarget.toRelative(0), index: 2),
        FillTarget.none,
      );
      expect(_decode(_dataset(3), index: 3), FillTarget.none);
    });

    test('the out of bounds dataset index (:138)', () {
      expect(_decode(_dataset(-2), index: 0), FillTarget.none);
      expect(_decode(_dataset(4)), FillTarget.none);
      expect(
        _decode(const FillTarget.toRelative(-3), index: 2),
        FillTarget.none,
      );
      expect(_decode(FillTarget.toNext, index: 3), FillTarget.none);
    });

    test('the invalid values (:159)', () {
      // The texts, the floats, the infinities and the array of the spec are
      // no FillTarget (Chart.js ADR 0140): a debug build stops on them. A
      // NaN value and `null` stay.
      expect(_decode(const FillTarget.toValue(double.nan)), FillTarget.none);
      expect(_decode(null), FillTarget.none);
    });

    test('the values of the Node.js run', () {
      expect(_decode(const FillTarget.toRelative(0)), FillTarget.none);
      expect(_decode(FillTarget.toNext), _dataset(2));
      expect(
        _decode(const FillTarget.toValue(double.nan).split()),
        FillTarget.none,
      );
      expect(_decode(FillTarget.toOrigin.split()), FillTarget.toOrigin);
    });

    test('a value fill is the target itself', () {
      const fill = FillTarget.toValue(2);
      expect(_decode(fill), same(fill));
      const target = FillTarget.toValue(3);
      expect(_decode(target.split()), same(target));
    });

    test('a split fill keeps its target and gives no split', () {
      final split = FillTarget.toNext.split();
      expect(split.split(), isA<SplitFill>());
      expect((split.split() as SplitFill).target, FillTarget.toNext);
      expect(_decode(split, index: 0), _dataset(1));
    });

    test('a value that is no FillTarget stops a debug build', () {
      for (final fill in <Object>[true, false, 1, 1.5, 'origin', <Object?>[]]) {
        expect(() => _decode(fill), throwsA(isA<AssertionError>()));
      }
    });

    test('no fill gives the backgroundColor test (filler.options.js:125)', () {
      expect(
        _decode(
          undefined,
          backgroundColor: const ui.Color.fromRGBO(255, 0, 0, 1),
        ),
        FillTarget.toOrigin,
      );
      expect(_decode(undefined), FillTarget.none);
      expect(_decode(undefined, backgroundColor: ''), FillTarget.none);
    });
  });

  group('resolveTarget', () {
    // plugin.filler.tests.js:197-269: the decoded fills of the spec chart.
    final fills = <FillTarget>[
      FillTarget.toStart,
      _dataset(0),
      _dataset(1),
      _dataset(1),
      _dataset(5),
      _dataset(7),
      _dataset(5),
      FillTarget.toEnd,
    ];
    const visible = [false, false, false, false, true, true, true, false];

    test('propagate true (:198)', () {
      final sources = _sources(fills, visible);
      expect(
        [
          for (var i = 0; i < fills.length; i++)
            resolveTarget(sources, i, true),
        ],
        [
          FillTarget.toStart,
          FillTarget.toStart,
          FillTarget.toStart,
          FillTarget.toStart,
          _dataset(5),
          FillTarget.toEnd,
          _dataset(5),
          FillTarget.toEnd,
        ],
      );
    });

    test('propagate false (:235)', () {
      final sources = _sources(fills, visible);
      expect([
        for (var i = 0; i < fills.length; i++) resolveTarget(sources, i, false),
      ], fills);
    });

    test('the recursive propagation (:271)', () {
      final sources = _sources(
        [_dataset(2), _dataset(0), _dataset(1), _dataset(1)],
        const [false, false, false, true],
      );
      expect([
        for (var i = 0; i < 4; i++) resolveTarget(sources, i, true),
      ], List.filled(4, FillTarget.none));
    });

    test('a null source or an index past the end gives false', () {
      // Dataset 1 fills to the null source 0, dataset 2 to the index 5.
      final sources = _sources(
        [_dataset(0), _dataset(0), _dataset(5)],
        const [true, true, true],
      )..[0] = null;
      expect(resolveTarget(sources, 1, true), FillTarget.none);
      expect(resolveTarget(sources, 2, true), FillTarget.none);
    });
  });
}
