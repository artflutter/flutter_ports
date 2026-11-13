// Original code, not ported from Chart.js: numeric single-scale parsing twins.
@TestOn('vm')
library;

import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/core/core.scale.dart' show scaleCfgArg;
import 'package:flutter_chartjs_port/src/core/primitive_parse.dart';
import 'package:flutter_chartjs_port/src/options/parsed.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_test/flutter_test.dart';

// The twin of the radial parse (Chart.js ADR 0095): the exact radial scale
// takes the numeric path, and a trivial subclass takes the generic loop. The
// records must have the same own keys and the same value bits.

class _OrdinaryRadial(super.cfg) extends RadialLinearScale {
  int parses = 0;

  @override
  Object? parse(Object? raw, [double? index]) {
    parses++;
    return super.parse(raw, index);
  }

  static final value = JsClass(
    'ParseOrdinaryRadial',
    superclass: RadialLinearScale.jsClass,
    statics: {'id': 'parse-ordinary-radial'},
    construct: (_, args) => _OrdinaryRadial(scaleCfgArg(args)),
  );
}

class _ObservedList(final List<Object?> values) extends ListBase<Object?> {
  @override
  int get length => values.length;
  @override
  set length(int value) => values.length = value;
  @override
  Object? operator [](int index) => values[index];
  @override
  void operator []=(int index, Object? value) => values[index] = value;
}

String _bits(Object? value) {
  if (value is double) {
    final data = ByteData(8)..setFloat64(0, value);
    return value.isNaN ? 'nan' : data.getUint64(0).toRadixString(16);
  }
  return '$value';
}

List<String> _records(List<ParsedItem> items) => [
  for (final item in items)
    '${item.jsKeys()} ${_bits(item.r)} ${item.r.runtimeType}',
];

AnyObject _config(List<Object?> data, String? scaleType) => <String, Object?>{
  'type': 'radar',
  'data': <String, Object?>{
    'labels': <Object?>[for (var i = 0; i < data.length; i++) 'L$i'],
    'datasets': <Object?>[
      <String, Object?>{'data': data},
    ],
  },
  'options': <String, Object?>{
    'responsive': false,
    'scales': <String, Object?>{
      'r': <String, Object?>{'type': ?scaleType},
    },
  },
};

Chart _chart(List<Object?> data, String? scaleType) {
  final chart = Chart(
    UiCanvasElement(width: 200, height: 200),
    _config(data, scaleType),
  );
  addTearDown(chart.destroy);
  return chart;
}

void main() {
  Chart.register([_OrdinaryRadial.value]);

  group('tryParseNumericSingleScale', () {
    final values = <Object?>[
      5.0,
      -0.0,
      0.0,
      0,
      7,
      null,
      undefined,
      double.nan,
      double.infinity,
      double.negativeInfinity,
      1e300,
      double.minPositive,
    ];

    testWidgets('gives the records of the generic loop', (tester) async {
      final fast = _chart(<Object?>[...values], null);
      final slow = _chart(<Object?>[...values], 'parse-ordinary-radial');
      final fastMeta = fast.getDatasetMeta(0);
      final slowMeta = slow.getDatasetMeta(0);
      final controller = fastMeta.controller!;
      final ordinary = slowMeta.controller!;
      final list = <Object?>[...values];
      expect(
        _records(controller.parsePrimitiveData(fastMeta, list, 0, 12)),
        _records(ordinary.parsePrimitiveData(slowMeta, list, 0, 12)),
      );
      expect(
        _records(controller.parsePrimitiveData(fastMeta, list, 3, 4)),
        _records(ordinary.parsePrimitiveData(slowMeta, list, 3, 4)),
      );
      final scale = slow.scales['r']! as _OrdinaryRadial;
      expect(scale.parses, greaterThan(0));
    });

    testWidgets('makes fresh records', (tester) async {
      final chart = _chart(<Object?>[1.0, 2.0], null);
      final meta = chart.getDatasetMeta(0);
      final controller = meta.controller!;
      final list = <Object?>[1.0, 2.0];
      final first = controller.parsePrimitiveData(meta, list, 0, 2);
      final second = controller.parsePrimitiveData(meta, list, 0, 2);
      expect(identical(first[0], second[0]), isFalse);
      expect(identical(first[0], first[1]), isFalse);
      first.add(ParsedItem());
      expect(first, hasLength(3));
    });

    testWidgets('accepts a typed list and the exact radial scale', (
      tester,
    ) async {
      final chart = _chart(<Object?>[1.0], null);
      final scale = chart.scales['r']!;
      final parsed = tryParseNumericSingleScale(
        scale,
        Float64List.fromList([1, 2]),
        0,
        2,
      );
      expect(_records(parsed!), [
        '[r] ${_bits(1.0)} double',
        '[r] ${_bits(2.0)} double',
      ]);
    });

    testWidgets('declines each other input before creating a record', (
      tester,
    ) async {
      final chart = _chart(<Object?>[1.0], null);
      final twin = _chart(<Object?>[1.0], 'parse-ordinary-radial');
      final scale = chart.scales['r']!;
      expect(
        tryParseNumericSingleScale(twin.scales['r']!, <Object?>[1.0], 0, 1),
        isNull,
      );
      // A custom container, a string or an object of a late index.
      expect(
        tryParseNumericSingleScale(scale, _ObservedList([1.0]), 0, 1),
        isNull,
      );
      expect(
        tryParseNumericSingleScale(scale, <Object?>[1.0, '2'], 0, 2),
        isNull,
      );
      expect(
        tryParseNumericSingleScale(
          scale,
          <Object?>[1.0, <String, Object?>{}],
          0,
          2,
        ),
        isNull,
      );
      // A range outside the data, or that is no range of indexes.
      for (final (start, count) in const [
        (0.0, 3.0),
        (2.0, 1.0),
        (-1.0, 1.0),
        (0.5, 1.0),
        (0.0, 0.5),
        (0.0, 0.0),
        (double.nan, 1.0),
        (0.0, double.infinity),
      ]) {
        expect(
          tryParseNumericSingleScale(scale, <Object?>[1.0, 2.0], start, count),
          isNull,
        );
      }
    });

    testWidgets('a late string in the range keeps the generic loop', (
      tester,
    ) async {
      final data = <Object?>[1.0, 2.0, '3', 'x'];
      final fast = _chart(<Object?>[...data], null);
      final slow = _chart(<Object?>[...data], 'parse-ordinary-radial');
      expect(
        _records(fast.getDatasetMeta(0).parsed.cast<ParsedItem>()),
        _records(slow.getDatasetMeta(0).parsed.cast<ParsedItem>()),
      );
    });
  });
}
