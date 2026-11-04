// Original code, not ported from Chart.js: native context refresh boundaries.
import 'dart:collection';

import 'package:flutter_chartjs_port/src/core/point_options.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:test/test.dart';

class _Meta implements types.ChartMeta {
  _Meta(this.data, this.parsed);
  @override
  List<types.Element> data;
  @override
  List<Object?> parsed;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ObservedList extends ListBase<Object?> {
  int reads = 0;
  @override
  int get length {
    reads++;
    return 1;
  }

  @override
  set length(int value) {}
  @override
  Object? operator [](int index) {
    reads++;
    return null;
  }

  @override
  void operator []=(int index, Object? value) {}
}

class _CustomPoint extends PointElement {
  int reads = 0;
  @override
  ScriptableContext? get $context {
    reads++;
    return super.$context;
  }
}

void main() {
  test('refresh uses live items and original key insertion order', () {
    final point = PointElement();
    final context = ScriptableContext.data(null, 0, point);
    point.$context = context;
    context
      ..jsDelete('parsed')
      ..jsDelete('raw')
      ..jsWrite('note', true)
      ..jsWrite('1', 'first');
    final raw = <Object?>[
      <String, Object?>{'raw': 1},
    ];
    final parsed = <Object?>[
      <String, Object?>{'parsed': 1},
    ];
    final meta = _Meta(<types.Element>[point], parsed);
    final reader = NativePointContextReader.prepare(meta, raw, 'none')!;
    expect(reader.read(0), same(context));
    expect(context.raw, same(raw[0]));
    expect(context.parsed, same(parsed[0]));
    expect(context.jsKeys(), [
      '1',
      'active',
      'dataIndex',
      'element',
      'index',
      'mode',
      'type',
      'note',
      'parsed',
      'raw',
    ]);
    raw[0] = null;
    parsed[0] = 7.0;
    reader.read(0);
    expect(context.raw, isNull);
    expect(context.parsed, 7);
    final old = context.raw;
    meta.parsed = List<Object?>.of(parsed);
    expect(reader.read(0), isNull);
    expect(context.raw, old);
  });
  test('custom sources decline without indexing', () {
    final point = PointElement();
    final custom = _ObservedList();
    final meta = _Meta(<types.Element>[point], custom);
    expect(NativePointContextReader.prepare(meta, <Object?>[], 'none'), isNull);
    expect(custom.reads, 0);
    meta.parsed = <Object?>[];
    expect(NativePointContextReader.prepare(meta, custom, 'none'), isNull);
    expect(custom.reads, 0);
  });
  test(
    'custom points and absent contexts leave creation to ordinary resolution',
    () {
      final point = _CustomPoint();
      final native = PointElement();
      final meta = _Meta(<types.Element>[point, native], <Object?>[1, 2]);
      final reader = NativePointContextReader.prepare(meta, <Object?>[
        1,
        2,
      ], 'none')!;
      expect(reader.read(0), isNull);
      expect(point.reads, 0);
      expect(reader.read(1), isNull);
      expect(reader.read(-1), isNull);
      expect(reader.read(2), isNull);
    },
  );
}
