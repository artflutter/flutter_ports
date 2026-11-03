// Original code, not ported from Chart.js: sealed background-color values.
@TestOn('vm')
library;

import 'dart:ui' show Color;

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show createContext;
import 'package:flutter_chartjs_port/src/js/js_function.dart' show jsCall;
import 'package:flutter_chartjs_port/src/options/opt.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
import 'package:flutter_chartjs_port/src/typed/datasets.dart' show lowerDataset;
import 'package:flutter_test/flutter_test.dart';

const _red = Color(0xffff0000);
const _blue = Color(0xff0000ff);

Color _colorFor(ChartContext context) => context.dataIndex == 0 ? _red : _blue;

class _DerivedColor extends Color {
  const _DerivedColor(super.value);
}

const _derived = _DerivedColor(0xff00ff00);
_DerivedColor _derivedFor(ChartContext context) => _derived;

class _Provider {
  Color choose(ChartContext context) => _red;
}

List<Dataset> _datasets() => const [
  BarDataset(),
  LineDataset(),
  ScatterDataset(),
  BubbleDataset(),
  DoughnutDataset(),
  PieDataset(),
  PolarAreaDataset(),
  RadarDataset(),
];

void _equal(Object a, Object b) {
  expect(a == b, isTrue);
  expect(b == a, isTrue);
  expect(a.hashCode, b.hashCode);
}

void main() {
  test('factories expose a closed set of typed variants', () {
    const values = <ChartValue<Color>>[
      ChartValue.constant(_red),
      ChartValue.indexed([_red, _blue]),
      ChartValue.resolver(_colorFor),
    ];
    final kinds = [
      for (final value in values)
        switch (value) {
          ChartConstant<Color>() => 'constant',
          ChartIndexed<Color>() => 'indexed',
          ChartResolver<Color>() => 'resolver',
        },
    ];
    expect(kinds, ['constant', 'indexed', 'resolver']);
    expect((values[0] as ChartConstant<Color>).value, same(_red));
    expect((values[1] as ChartIndexed<Color>).values, [_red, _blue]);
    expect((values[2] as ChartResolver<Color>).callback, _colorFor);
  });

  test('variant identity remains distinct even for the same output', () {
    const constant = ChartValue.constant(_red);
    const indexed = ChartValue.indexed([_red]);
    const resolver = ChartValue.resolver(_colorFor);
    expect(constant, isNot(indexed));
    expect(indexed, isNot(resolver));
    expect(resolver, isNot(constant));
  });

  test('constant equality is symmetric across generic instantiations', () {
    _equal(
      const ChartValue<Color>.constant(_derived),
      const ChartValue<_DerivedColor>.constant(_derived),
    );
    expect(
      const ChartValue.constant(_red),
      isNot(const ChartValue.constant(_blue)),
    );
  });

  test('indexed equality compares items and ignores generic instantiation', () {
    _equal(
      const ChartValue<Color>.indexed(<Color>[_derived]),
      const ChartValue<_DerivedColor>.indexed(<_DerivedColor>[_derived]),
    );
    _equal(
      ChartValue<Color>.indexed(List<Color>.of([_red, _blue])),
      ChartValue<Color>.indexed(List<Color>.of([_red, _blue])),
    );
    expect(
      const ChartValue.indexed([_red, _blue]),
      isNot(const ChartValue.indexed([_blue, _red])),
    );
  });

  test(
    'resolver equality uses function equality, including method tear-offs',
    () {
      final provider = _Provider();
      _equal(
        ChartValue.resolver(provider.choose),
        ChartValue.resolver(provider.choose),
      );
      expect(
        ChartValue.resolver(provider.choose),
        isNot(ChartValue.resolver(_Provider().choose)),
      );
      _equal(
        const ChartValue<Color>.resolver(_derivedFor),
        const ChartValue<_DerivedColor>.resolver(_derivedFor),
      );
      expect(
        ChartValue<Color>.resolver((context) => _red),
        isNot(ChartValue<Color>.resolver((context) => _red)),
      );
    },
  );

  test('constant lowering retains a typed cell and native Color identity', () {
    final scope = lowerDataset(
      const BarDataset(backgroundColor: ChartValue.constant(_red)),
      ChartKind.bar,
    );
    final cell = scope.ownCell(OptionKey.backgroundColor);
    expect(cell, isA<OptValue<Color>>());
    expect(cell!.raw, same(_red));
  });

  test('indexed lowering copies to a mutable engine list', () {
    final colors = <Color>[_red, _blue];
    final value = ChartValue.indexed(colors);
    final scope = lowerDataset(
      BarDataset(backgroundColor: value),
      ChartKind.bar,
    );
    final cell = scope.ownCell(OptionKey.backgroundColor);
    expect(cell, isA<OptList<Color>>());
    final items = (cell! as OptList<Color>).items;
    expect(items, [_red, _blue]);
    expect(identical(items, colors), isFalse);
    items[0] = _blue;
    items.add(_red);
    expect(colors, [_red, _blue]);
    expect((value as ChartIndexed<Color>).values, same(colors));
  });

  test('an empty indexed list retains existing empty-list behavior', () {
    final scope = lowerDataset(
      const BarDataset(backgroundColor: ChartValue<Color>.indexed([])),
      ChartKind.bar,
    );
    final cell = scope.ownCell(OptionKey.backgroundColor)! as OptList<Color>;
    expect(cell.items, isEmpty);
    cell.items.add(_red);
    expect(cell.raw, [_red]);
  });

  test('resolver lowering is lazy and adapts the typed context', () {
    final calls = <int?>[];
    final value = ChartValue<Color>.resolver((context) {
      calls.add(context.dataIndex);
      return context.dataIndex == 0 ? _red : _blue;
    });
    final scope = lowerDataset(
      BarDataset(backgroundColor: value),
      ChartKind.bar,
    );
    final cell = scope.ownCell(OptionKey.backgroundColor);
    expect(cell, isA<OptFunction<Color>>());
    expect(calls, isEmpty);
    final function = (cell! as OptFunction<Color>).function;
    for (final index in [0.0, 1.0]) {
      final context = createContext(null, {'type': 'data', 'dataIndex': index});
      expect(jsCall(function, [context, null]), index == 0 ? _red : _blue);
    }
    expect(calls, [0, 1]);
  });

  test('omission inherits while raw extra null remains explicitly present', () {
    final omitted = lowerDataset(const BarDataset(), ChartKind.bar);
    expect(omitted.ownCell(OptionKey.backgroundColor), isNull);
    final explicitNull = lowerDataset(
      const BarDataset(
        backgroundColor: ChartValue.constant(_red),
        extra: {'backgroundColor': null},
      ),
      ChartKind.bar,
    );
    expect(explicitNull.ownCell(OptionKey.backgroundColor), isA<OptNull>());
  });

  test(
    'extra overrides the value and preserves the background key position',
    () {
      final scope = lowerDataset(
        const BarDataset(
          label: 'A',
          backgroundColor: ChartValue.constant(_red),
          borderColor: _red,
          borderWidth: 1,
          extra: {'backgroundColor': _blue},
        ),
        ChartKind.bar,
      );
      expect(scope.jsKeys(), [
        'label',
        'backgroundColor',
        'borderColor',
        'borderWidth',
      ]);
      expect(scope.ownCell(OptionKey.backgroundColor)!.raw, same(_blue));
    },
  );

  for (final empty in _datasets()) {
    test('${empty.runtimeType}: copyWith switches one background value', () {
      final indexed = empty.copyWith(
        backgroundColor: const ChartValue.indexed([_red, _blue]),
      );
      final constant = indexed.copyWith(
        backgroundColor: const ChartValue.constant(_blue),
      );
      final resolver = constant.copyWith(
        backgroundColor: const ChartValue.resolver(_colorFor),
      );
      expect(indexed.backgroundColor, isA<ChartIndexed<Color>>());
      expect(constant.backgroundColor, isA<ChartConstant<Color>>());
      expect(resolver.backgroundColor, isA<ChartResolver<Color>>());
      expect(
        resolver.copyWith().backgroundColor,
        same(resolver.backgroundColor),
      );
      expect(
        // Explicit null is part of copyWith's keep-current-value contract.
        // ignore: avoid_redundant_argument_values
        resolver.copyWith(backgroundColor: null).backgroundColor,
        same(resolver.backgroundColor),
      );
      expect(
        lowerDataset(indexed, ChartKind.bar).ownCell(OptionKey.backgroundColor),
        isA<OptList<Color>>(),
      );
      expect(
        lowerDataset(
          constant,
          ChartKind.bar,
        ).ownCell(OptionKey.backgroundColor),
        isA<OptValue<Color>>(),
      );
      expect(
        lowerDataset(
          resolver,
          ChartKind.bar,
        ).ownCell(OptionKey.backgroundColor),
        isA<OptFunction<Color>>(),
      );
    });
  }

  test('equivalent values preserve Dataset and ChartConfig equality', () {
    final data = <num?>[1, 2];
    final a = BarDataset(
      data: data,
      backgroundColor: ChartValue.indexed(List<Color>.of([_red, _blue])),
    );
    final b = BarDataset(
      data: data,
      backgroundColor: ChartValue.indexed(List<Color>.of([_red, _blue])),
    );
    _equal(a, b);
    _equal(
      ChartConfig(type: ChartKind.bar, datasets: [a]),
      ChartConfig(type: ChartKind.bar, datasets: [b]),
    );
  });
}
