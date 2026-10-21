// Original code, not ported from Chart.js: tests of the fixture runner.
@TestOn('vm')
@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_test/flutter_test.dart';

// The tag `fixtures` keeps the tests of the runner out of the melos `test`
// run. Thus `setUpAll` runs `test/fixture_probe/probe_fixture.dart` in a
// subprocess with `--tags fixtures`, and each test below asserts one fact of
// its JSON events. The subprocess has `FIXTURES_REQUIRED=1`, and
// `FIXTURE_PROBE_CRLF` gives a temporary directory with an upstream file
// that has CRLF line ends.

/// One test of the probe run.
final class _Test {
  _Test(this.name, this.group);

  /// The full name.
  final String name;

  /// The full name of the innermost group.
  final String group;

  String result = '';
  bool skipped = false;
  String? skipReason;

  /// The error and print messages of the test.
  final StringBuffer messages = StringBuffer();
}

/// The tests of the probe run, by full name, in the order of their start.
final Map<String, _Test> _tests = {};

/// The `flutter` command of the SDK that runs this test.
String get _flutter {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return 'flutter';
  return '$root/bin/flutter${Platform.isWindows ? '.bat' : ''}';
}

void _parse(String output) {
  final groups = <int, String>{};
  final byId = <int, _Test>{};
  for (final line in const LineSplitter().convert(output)) {
    if (!line.startsWith('{')) continue;
    final event = jsonDecode(line) as Map<String, Object?>;
    switch (event['type']) {
      case 'group':
        final group = event['group']! as Map<String, Object?>;
        groups[group['id']! as int] = group['name']! as String;
      case 'testStart':
        final test = event['test']! as Map<String, Object?>;
        final ids = (test['groupIDs']! as List<Object?>).cast<int>();
        if (ids.isEmpty) continue;
        final metadata = test['metadata']! as Map<String, Object?>;
        final result = byId[test['id']! as int] = _Test(
          test['name']! as String,
          groups[ids.last] ?? '',
        )..skipReason = metadata['skipReason'] as String?;
        _tests[result.name] = result;
      case 'error' || 'print':
        byId[event['testID']]?.messages
          ?..writeln(event['error'] ?? event['message'])
          ..writeln();
      case 'testDone':
        byId[event['testID']! as int]
          ?..result = event['result']! as String
          ..skipped = event['skipped'] == true;
    }
  }
}

_Test _test(String name) {
  final test = _tests['probe $name'];
  if (test == null) fail('the probe run has no test "probe $name".');
  return test;
}

void _expectPass(String name) {
  final test = _test(name);
  expect(
    test.result == 'success' && !test.skipped,
    isTrue,
    reason: '"$name": ${test.result}\n${test.messages}',
  );
}

void _expectFail(String name, Pattern message) {
  final test = _test(name);
  expect(test.result, isNot('success'), reason: '"$name" passed');
  expect(
    test.messages.toString(),
    message is RegExp ? matches(message) : contains(message),
    reason: name,
  );
}

void _expectSkip(String name, String reason) {
  final test = _test(name);
  expect(test.skipped, isTrue, reason: '"$name" did not skip');
  expect(test.skipReason, reason);
}

void main() {
  setUpAll(() async {
    final crlf = Directory.systemTemp.createTempSync('fixture_probe_crlf');
    addTearDown(() => crlf.deleteSync(recursive: true));
    File('${crlf.path}/crlf/lines.json')
      ..createSync(recursive: true)
      ..writeAsStringSync(
        'probe upstream file crlf/lines.json\r\nsecond line\r\n',
      );
    final process = await Process.run(
      _flutter,
      [
        'test',
        '--tags',
        fixturesTag,
        '--reporter',
        'json',
        'test/fixture_probe/probe_fixture.dart',
      ],
      environment: {
        fixturesRequiredVariable: '1',
        'FIXTURE_PROBE_CRLF': crlf.path,
      },
      runInShell: Platform.isWindows,
    );
    _parse(process.stdout as String);
    if (_tests.isEmpty) {
      fail('the probe run gave no tests:\n${process.stderr}');
    }
  });

  group('prefix', () {
    test('scale.time matches scale.timeseries', () {
      _expectPass('prefix time scale.timeseries/a.json');
    });

    test('a dot matches any character', () {
      _expectPass('prefix dot aXb/c.json');
    });

    test('a path equal to the prefix with no rest does not match', () {
      _expectPass('prefix rest edge/xy.json');
      expect(_tests.keys, isNot(contains('probe prefix rest edge/x.json')));
    });
  });

  test('each test name is the path with its extension, in the group', () {
    final test = _test('prefix time scale.timeseries/a.json');
    expect(test.group, 'probe prefix time');
    expect(test.name, '${test.group} scale.timeseries/a.json');
    expect(
      [
        for (final test in _tests.values)
          if (test.group == 'probe sources') test.name.substring(14),
      ],
      [
        'source/both.json',
        'source/impure.js',
        'source/stale.js',
        'source/skip.json',
        'source/stale-skip.json',
        'source/blocked.json',
      ],
    );
  });

  test('all declared tests run under --tags fixtures', () {
    expect(_tests.length, 27);
    expect(_tests.keys, isNot(contains('probe untagged')));
  });

  group('the plugin rule', () {
    test('no plugins option gives false', () {
      _expectPass('rule rule/none.js');
    });

    test('a path with plugin keeps it absent', () {
      _expectPass('plugin path plugin.x/keep.js');
    });

    test('a set config.plugins keeps it absent', () {
      _expectPass('rule rule/instance.js');
    });

    test('an object options.plugins stays the object', () {
      _expectPass('rule rule/object.js');
    });
  });

  group('the run hook', () {
    test('a sync hook runs on the attached chart', () {
      _expectPass('run run/sync.js');
    });

    test('a Future that frames complete settles before the test ends', () {
      _expectPass('run run/future.js');
      _expectPass('the Future of the hook settled');
    });

    test('a Future that never completes fails with the Jasmine timeout', () {
      _expectFail(
        'run run/never.js',
        'Timeout - Async function did not complete within 5000ms',
      );
    });

    test('a hook that throws fails, and the chart is released', () {
      _expectFail('run run/throws.js', 'probe sync error');
      _expectPass('the chart of the hook that throws is released');
    });

    test('a Future that completes with an error fails', () {
      _expectFail('run run/async-throws.js', 'probe async error');
    });
  });

  test('an item without a PNG fails with the message of fixture.js:53 on '
      'the relative path', () {
    _expectFail(
      'png png/none.json',
      // The dump of flutter_test prints the line end of the message
      // (`'\r\n'`) as a line end.
      RegExp(r'png/none\r?\nMissing PNG comparison file for png/none\.json'),
    );
  });

  group('the sources', () {
    test('a hand entry wins over a data config', () {
      // The data config of source/both.json has the type "nope", which
      // throws.
      _expectPass('sources source/both.json');
    });

    test('an impure item without a hand entry fails', () {
      _expectFail(
        'sources source/impure.js',
        'hand-port source/impure.js to test/fixtures/hand/, or skip it with '
            'a reason.',
      );
    });

    test('a stale sha256 of a hand entry fails', () {
      _expectFail(
        'sources source/stale.js',
        'the hand port of source/stale.js is stale: port the diff of the '
            'bump and update its sha256.',
      );
    });

    test('a skip gives a skipped test with its reason', () {
      _expectSkip('sources source/skip.json', 'n/a: probe');
      _expectSkip('sources source/blocked.json', 'blocked: plugin.absent');
    });

    test('a blocked: plugin.<id> skip of a registered plugin fails', () {
      _expectFail(
        'sources source/stale-skip.json',
        'stale skip: plugin.probe is registered. Remove the skip of '
            'source/stale-skip.json.',
      );
    });
  });

  group('the upstream files (Chart.js ADR 0029 §3 item 5)', () {
    test('another SHA-256 than the manifest fails', () {
      _expectFail(
        'upstream upstream/changed.json',
        'the config of upstream/changed.json is stale: the SHA-256 of the '
            'upstream file is',
      );
    });

    test('a CRLF checkout of an LF upstream file passes', () {
      // core.autocrlf=true of Git for Windows: the manifest has the SHA-256
      // of the LF form.
      _expectPass('crlf crlf/lines.json');
    });

    test('a missing upstream file fails', () {
      _expectFail(
        'upstream upstream/missing.json',
        'the upstream file upstream/missing.json does not exist in '
            'test/fixture_probe/upstream',
      );
    });

    test('without the checkout, a fixture skips', () {
      _expectSkip('no checkout aXb/c.json', noSubmoduleReason);
      expect(
        noSubmoduleReason,
        'n/a: the submodule third_party/Chart.js is not checked out',
      );
    });

    test('without the checkout, a required fixture fails', () {
      const message = 'the upstream fixture files are not checked out';
      _expectFail('no checkout required aXb/c.json', message);
      // FIXTURES_REQUIRED=1 of the probe run.
      _expectFail('no checkout env aXb/c.json', message);
    });
  });

  test('a hand or skip key that is not a fixture throws a StateError', () {
    const source = FixtureSource(
      manifest: 'test/fixture_probe/manifest.json',
      data: 'test/fixture_probe/fixtures.json',
      upstream: 'test/fixture_probe/upstream',
    );
    expect(
      () => specsFromFixtures(
        'rule/',
        hand: {
          'rule/nope.js': (load: () => <String, Object?>{}, sha256: ''),
        },
        source: source,
      ),
      throwsStateError,
    );
    expect(
      () => specsFromFixtures(
        'rule/',
        skips: {'rule/nope.json': 'n/a: probe'},
        source: source,
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          'rule/nope.json is not a fixture of '
              'test/fixture_probe/manifest.json.',
        ),
      ),
    );
    expect(
      specsFromFixtures(
        'rule/',
        skips: {'rule/none.js': 'n/a: probe'},
        source: source,
      ),
      isA<void Function()>(),
    );
  });

  test('FixtureSource reads the manifest items in order', () {
    const source = FixtureSource(
      manifest: 'test/fixture_probe/manifest.json',
      data: 'test/fixture_probe/fixtures.json',
    );
    final items = source.items;
    expect(items, hasLength(23));
    expect(items.first, (
      path: 'scale.timeseries/a.json',
      sha256: items.first.sha256,
      png: 'scale.timeseries/a.png',
      data: true,
    ));
    expect(items.firstWhere((i) => i.path == 'png/none.json').png, isNull);
    expect(items.firstWhere((i) => i.path == 'rule/none.js').data, isFalse);
    expect(
      source.dataConfig('aXb/c.json')['config'],
      isA<Map<String, Object?>>(),
    );
    expect(() => source.dataConfig('rule/none.js'), throwsStateError);
    expect(
      const FixtureSource().upstream,
      '../../third_party/Chart.js/test/fixtures',
    );
  });
}
