// Original code, not ported from Chart.js: the checks of the fixture registry test/fixtures/index.dart (Chart.js ADR 0029).
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/index.dart';

/// The fixture groups of the manifest specs: the upstream spec file and the
/// prefix of `describe('auto', jasmine.fixture.specs(prefix))`.
typedef _Group = ({String spec, String prefix});

List<_Group> _groups() {
  final json =
      jsonDecode(File('doc/upstream/manifest.json').readAsStringSync())!
          as Map<String, Object?>;
  final specs = (json['specs']! as List<Object?>).cast<Map<String, Object?>>();
  return [
    for (final spec in specs)
      for (final group
          in (spec['fixtureGroups']! as List<Object?>)
              .cast<Map<String, Object?>>())
        (spec: spec['file']! as String, prefix: group['prefix']! as String),
  ];
}

/// The Dart spec file of an upstream spec file (Chart.js ADR 0012):
/// `<base>.tests.js` is `test/specs/<base>_test.dart`.
File _dartSpec(String spec) => File(
  'test/specs/${spec.substring(0, spec.length - '.tests.js'.length)}_test.dart',
);

/// The regular expression of `fixture.js:74` for [prefix].
RegExp _match(String prefix) => RegExp('^$prefix.+\\.(json|js)\$');

/// The paths of the hand ports under `test/fixtures/hand/`, as fixture
/// paths (`hand/<path>.dart` is `<path>.js`).
Set<String> _handFiles() {
  const root = 'test/fixtures/hand/';
  return {
    for (final entity in Directory(root).listSync(recursive: true))
      if (entity is File && entity.path.endsWith('.dart'))
        '${entity.path.substring(root.length, entity.path.length - 5)}.js'
            .replaceAll(r'\', '/'),
  };
}

void main() {
  const source = FixtureSource();
  final items = {for (final item in source.items) item.path: item};

  test('each key of handFixtures and fixtureSkips is a manifest fixture', () {
    final unknown = [
      for (final key in [...handFixtures.keys, ...fixtureSkips.keys])
        if (!items.containsKey(key)) key,
    ];
    expect(unknown, isEmpty);
  });

  test('no key of handFixtures is a pure data fixture', () {
    final data = [
      for (final key in handFixtures.keys)
        if (items[key]?.data ?? false) key,
    ];
    expect(data, isEmpty);
  });

  test('no key is both a hand port and a skip', () {
    expect(
      handFixtures.keys.where(fixtureSkips.containsKey).toList(),
      isEmpty,
    );
  });

  test('each impure fixture of a ported spec file has a hand port or a '
      'skip', () {
    final groups = _groups();
    final open = <String>[];
    var matched = 0;
    for (final group in groups) {
      if (!_dartSpec(group.spec).existsSync()) continue;
      final regex = _match(group.prefix);
      for (final item in items.values) {
        if (!regex.hasMatch(item.path)) continue;
        matched++;
        if (item.data) continue;
        if (handFixtures.containsKey(item.path)) continue;
        if (fixtureSkips.containsKey(item.path)) continue;
        open.add('${group.spec}: ${item.path}');
      }
    }
    expect(open, isEmpty);
    // The 20 spec files of FR section 6.2 match 529 fixtures at the pin.
    expect(matched, greaterThan(0));
  });

  test('each hand port file has an entry, and each entry has its file', () {
    final files = _handFiles();
    expect(
      files.difference(handFixtures.keys.toSet()).toList()..sort(),
      isEmpty,
      reason: 'files without an entry in handFixtures',
    );
    expect(
      handFixtures.keys.toSet().difference(files).toList()..sort(),
      isEmpty,
      reason: 'entries without a file under test/fixtures/hand/',
    );
  });

  test('each sha256 of handFixtures is the first 12 hex digits of the '
      'manifest sha256', () {
    final wrong = [
      for (final MapEntry(:key, :value) in handFixtures.entries)
        if (!RegExp(r'^[0-9a-f]{12}$').hasMatch(value.sha256) ||
            items[key]?.sha256.substring(0, 12) != value.sha256)
          key,
    ];
    expect(wrong, isEmpty);
  });

  test('each skip reason has a valid form, and each diverges row exists', () {
    final differences = File('doc/differences.md').readAsStringSync();
    final reason = RegExp(
      r'^(blocked: [A-Za-z0-9_.]+|n/a: .+|diverges: ([a-z0-9-]+))$',
    );
    final bad = <String>[];
    for (final MapEntry(:key, :value) in fixtureSkips.entries) {
      final match = reason.firstMatch(value);
      if (match == null) {
        bad.add('$key: $value');
        continue;
      }
      final row = match.group(2);
      if (row != null && !differences.contains('<a id="$row"></a>')) {
        bad.add('$key: no row $row in doc/differences.md');
      }
    }
    expect(bad, isEmpty);
  });
}
