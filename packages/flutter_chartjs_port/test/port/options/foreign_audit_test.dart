// Original code, not ported from Chart.js: tests of the oracle O2.

import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/foreign_audit.dart';
import 'package:flutter_chartjs_port/src/options/resolved.g.dart';
import 'package:flutter_chartjs_port/src/options/scopes.g.dart';
import 'package:test/test.dart';

import 'foreign_audit.dart';

void main() {
  // The hook of the oracle O2 (Chart.js ADR 0054 §15, differences.md row
  // `harness-foreign-audit`). Under `flutter test`, the test config sets
  // the hook before this file; each test puts it back at its end.
  group('harness-foreign-audit', () {
    late List<String> pairs;

    setUp(() {
      final saved = foreignAudit;
      pairs = <String>[];
      foreignAudit = (owner, key, raw) =>
          pairs.add('$owner\t$key\t${jsKindOf(raw)}');
      addTearDown(() => foreignAudit = saved);
    });

    test('a typed scope reports a value outside the type of its key', () {
      // `radius` of the point defaults has the shape `number`.
      PointOptionsScope()
        ..['radius'] = 3
        ..['radius'] = '4'
        ..['radius'] = undefined
        ..['radius'] = null
        ..['radius'] = (ctx) => 1;
      expect(pairs, ['PointOptionsScope\tradius\tstring']);
    });

    test('a resolved options class reports a foreign value', () {
      PointOptions()
        ..['radius'] = 3.0
        ..['radius'] = '4'
        ..['rotation'] = true;
      expect(pairs, [
        'PointOptions\tradius\tstring',
        'PointOptions\trotation\tboolean',
      ]);
    });

    test('the kinds are the JS kinds', () {
      expect(
        [
          undefined,
          null,
          true,
          1,
          's',
          <Object?>[],
          DateTime.utc(2026),
          (Object? x) => x,
          jsObjectClass,
          <String, Object?>{},
        ].map(jsKindOf),
        [
          'undefined',
          'null',
          'boolean',
          'number',
          'string',
          'array',
          'Date',
          'function',
          'function',
          'object',
        ],
      );
    });

    test('the collector names each unreviewed pair', () {
      final collector = ForeignAuditCollector()
        ..record('Kind', 'key', 'text')
        ..record('Kind', 'key', 'other text');
      expect(collector.pairs, ['Kind\tkey\tstring']);
      expect(collector.unreviewed, ['Kind\tkey\tstring']);
      expect(
        collector.throwIfUnreviewed,
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Kind\tkey\tstring'),
          ),
        ),
      );
    });

    test('the reviewed set is sorted and has no duplicate line', () {
      final list = reviewedForeignPairs.toList();
      expect(list, [...list]..sort());
      for (final pair in list) {
        expect(pair.split('\t'), hasLength(3), reason: pair);
      }
    });
  });
}
