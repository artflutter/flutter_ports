// Ported from d3-array v3.2.4 test/group-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart' as d3;
import 'package:test/test.dart';

typedef _Row = ({String name, String amount, String date});

const List<_Row> _data = <_Row>[
  (name: 'jim', amount: '34.0', date: '11/12/2015'),
  (name: 'carl', amount: '120.11', date: '11/12/2015'),
  (name: 'stacy', amount: '12.01', date: '01/04/2016'),
  (name: 'stacy', amount: '34.05', date: '01/04/2016'),
];

void main() {
  test('group(data, accessor) returns the expected map', () {
    final result = d3.group(_data, (d) => d.name);
    expect(result.keys.toList(), <String>['jim', 'carl', 'stacy']);
    expect(result, <String, List<_Row>>{
      'jim': <_Row>[(name: 'jim', amount: '34.0', date: '11/12/2015')],
      'carl': <_Row>[(name: 'carl', amount: '120.11', date: '11/12/2015')],
      'stacy': <_Row>[
        (name: 'stacy', amount: '12.01', date: '01/04/2016'),
        (name: 'stacy', amount: '34.05', date: '01/04/2016'),
      ],
    });
  });

  test('group(data, accessor, accessor) returns the expected map', () {
    final result = d3.group2(_data, (d) => d.name, (d) => d.amount);
    expect(result.keys.toList(), <String>['jim', 'carl', 'stacy']);
    expect(result['stacy']!.keys.toList(), <String>['12.01', '34.05']);
    expect(result, <String, Map<String, List<_Row>>>{
      'jim': <String, List<_Row>>{
        '34.0': <_Row>[(name: 'jim', amount: '34.0', date: '11/12/2015')],
      },
      'carl': <String, List<_Row>>{
        '120.11': <_Row>[(name: 'carl', amount: '120.11', date: '11/12/2015')],
      },
      'stacy': <String, List<_Row>>{
        '12.01': <_Row>[(name: 'stacy', amount: '12.01', date: '01/04/2016')],
        '34.05': <_Row>[(name: 'stacy', amount: '34.05', date: '01/04/2016')],
      },
    });
  });

  test('group(data, accessor) interns keys', () {
    final a1 = DateTime.utc(2001);
    final a2 = DateTime.utc(2001);
    final b = DateTime.utc(2002);
    final items = <(DateTime, int)>[(a1, 1), (a2, 2), (b, 3)];
    final map = d3.group(items, (entry) => entry.$1);
    expect(map[a1], <(DateTime, int)>[(a1, 1), (a2, 2)]);
    expect(map[a2], <(DateTime, int)>[(a1, 1), (a2, 2)]);
    expect(map[b], <(DateTime, int)>[(b, 3)]);
    final keys = map.keys.toList();
    expect(identical(keys[0], a1), isTrue);
    expect(identical(keys[1], b), isTrue);

    // Custom key canonicalization via InternMap<DateTime, List<...>, int>.
    final intern = d3.InternMap<DateTime, List<(DateTime, int)>, int>(
      key: (d) => d.millisecondsSinceEpoch,
    );
    for (final item in items) {
      final existing = intern[item.$1];
      if (existing != null) {
        existing.add(item);
      } else {
        intern[item.$1] = <(DateTime, int)>[item];
      }
    }
    final aLocal = DateTime.fromMillisecondsSinceEpoch(
      a1.millisecondsSinceEpoch,
    );
    expect(intern[a1], <(DateTime, int)>[(a1, 1), (a2, 2)]);
    expect(intern[a2], <(DateTime, int)>[(a1, 1), (a2, 2)]);
    expect(intern[aLocal], <(DateTime, int)>[(a1, 1), (a2, 2)]);
    expect(intern[b], <(DateTime, int)>[(b, 3)]);
    expect(identical(intern.keys.first, a1), isTrue);
  });

  test('InternMap canonicalizes keys and retains first-inserted key', () {
    const Object unrelated = 42;
    final map = d3.InternMap<String, int, String>(
      key: (k) => k.toLowerCase(),
      entries: <(String, int)>[('Alpha', 1), ('alpha', 2), ('Beta', 3)],
    );
    expect(map.length, 2);
    expect(map['ALPHA'], 2);
    expect(map['beta'], 3);
    expect(map['gamma'], isNull);
    expect(map[unrelated], isNull);
    expect(map.containsKey('aLpHa'), isTrue);
    expect(map.containsKey('missing'), isFalse);
    expect(map.containsKey(unrelated), isFalse);
    expect(map.keys.toList(), <String>['Alpha', 'Beta']);

    expect(map.remove('ALPHA'), 2);
    expect(map.remove('alpha'), isNull);
    expect(map.remove(unrelated), isNull);
    expect(map.length, 1);
    expect(map.keys.toList(), <String>['Beta']);

    map.clear();
    expect(map.isEmpty, isTrue);
  });

  test('InternSet canonicalizes elements and retains first-inserted value', () {
    const Object unrelated = 42;
    final set = d3.InternSet<String, String>(
      key: (v) => v.toLowerCase(),
      values: <String>['Alpha', 'alpha', 'Beta'],
    );
    expect(set.length, 2);
    expect(set.toList(), <String>['Alpha', 'Beta']);
    expect(set.add('ALPHA'), isFalse);
    expect(set.add('Gamma'), isTrue);
    expect(set.contains('gamma'), isTrue);
    expect(set.contains('missing'), isFalse);
    expect(set.contains(unrelated), isFalse);
    expect(set.lookup('GAMMA'), 'Gamma');
    expect(set.lookup('missing'), isNull);
    expect(set.lookup(unrelated), isNull);

    final copy = set.toSet();
    expect(copy, isA<d3.InternSet<String, String>>());
    expect(copy.contains('alpha'), isTrue);

    expect(set.remove('BETA'), isTrue);
    expect(set.remove('beta'), isFalse);
    expect(set.remove(unrelated), isFalse);
    expect(set.toList(), <String>['Alpha', 'Gamma']);

    set.clear();
    expect(set.isEmpty, isTrue);
  });
}
