// Original code, not ported from Chart.js: native context refresh boundaries.
import 'dart:collection';

import 'package:flutter_chartjs_port/chartjs_core.dart';
import 'package:test/test.dart';

class _Meta(
  @override var List<IElement> data,
  @override var List<ParsedItem?> parsed,
) implements ChartMeta {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ObservedList() extends ListBase<ParsedItem?> {
  int reads = 0;
  @override
  int get length {
    reads++;
    return 1;
  }

  @override
  set length(int value) {}
  @override
  ParsedItem? operator [](int index) {
    reads++;
    return null;
  }

  @override
  void operator []=(int index, ParsedItem? value) {}
}

class _CustomPoint() extends PointElement {
  int reads = 0;
  @override
  ScriptableContext? get $context {
    reads++;
    return super.$context;
  }
}

void main() {
  test('refresh uses live items', () {
    final point = PointElement();
    final context = ScriptableContext.data(null, 0, point);
    point.$context = context;
    final raw = <Object?>[
      <String, Object?>{'raw': 1},
    ];
    final parsed = <ParsedItem?>[ParsedItem()..jsWrite('parsed', 1)];
    final meta = _Meta(<IElement>[point], parsed);
    final reader = NativePointContextReader.prepare(meta, raw, 'none')!;
    expect(reader.read(0), same(context));
    expect(context.raw, same(raw[0]));
    expect(context.parsed, same(parsed[0]));
    expect(context.mode, 'none');
    expect(context.index, 0);
    raw[0] = null;
    final next = ParsedItem()..r = 7.0;
    parsed[0] = next;
    reader.read(0);
    expect(context.raw, isNull);
    expect(context.parsed, same(next));
    final old = context.raw;
    meta.parsed = List<ParsedItem?>.of(parsed);
    expect(reader.read(0), isNull);
    expect(context.raw, old);
  });
  test('custom sources decline without indexing', () {
    final point = PointElement();
    final custom = _ObservedList();
    final meta = _Meta(<IElement>[point], custom);
    expect(NativePointContextReader.prepare(meta, <Object?>[], 'none'), isNull);
    expect(custom.reads, 0);
    meta.parsed = <ParsedItem?>[];
    expect(NativePointContextReader.prepare(meta, custom, 'none'), isNull);
    expect(custom.reads, 0);
  });
  test(
    'custom points and absent contexts leave creation to ordinary resolution',
    () {
      final point = _CustomPoint();
      final native = PointElement();
      final meta = _Meta(
        <IElement>[point, native],
        <ParsedItem?>[ParsedItem(), ParsedItem()],
      );
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
