// Ported from chartjs-test-utils v0.4.0 src/fixture.js (MIT, chartjs-test-utils Contributors).

/// Port of `src/fixture.js`: the fixture smoke runner (Chart.js ADR 0029).
///
/// The members of `src/fixture.js` go to these places:
/// - `readFile` and `loadConfig` (fixture.js:3-34): a [FixtureLoad]. Dart
///   runs no JavaScript. Thus [FixtureSource] reads the list of the
///   fixtures from the manifest of tool 4 (`doc/upstream/manifest.json`)
///   and each pure data config from `doc/upstream/fixtures.json`. An impure
///   config is a hand port of `test/fixtures/hand/` in flutter_chartjs_port, a
///   [HandFixture] (Chart.js ADR 0029, sections 3 to 5).
/// - [specFromFixture] (fixture.js:36): one `testWidgets` test for each
///   fixture, with the tag [fixturesTag]. It loads the config, applies the
///   defaults and the plugin rule, acquires the chart, runs the `run` hook,
///   pumps one frame for the image load task, and releases the chart. It
///   compares no image (Chart.js ADR 0034, section 4). Upstream keeps it in
///   the module. The port makes it public, because the twins of the moment
///   fixtures call it (Chart.js ADR 0029, section 9).
/// - [specsFromFixtures] (fixture.js:73): the body of `group('auto', ...)`.
///   It matches the prefix against the paths of the manifest, as the
///   regular expression of fixture.js:74 matches the Karma files.
///
/// Port-only parts (Chart.js ADR 0029, sections 3, 5, 9 and 11; section 3
/// item 5 adds the checks of the upstream files):
/// - A hand port whose 12 hex digits differ from the `sha256` of the
///   manifest fails as stale. An impure fixture without a hand port and
///   without a skip fails. A key of `hand` or of `skips` that is not a
///   fixture of the manifest throws a [StateError].
/// - A skip is a plain `test()` with its reason: `testWidgets` takes only
///   `skip: true`. A `'blocked: plugin.<id>'` skip of a registered plugin
///   fails as stale.
/// - Before a config loads, the runner compares the SHA-256 of the upstream
///   file in `third_party/Chart.js/test/fixtures/` with the `sha256` of the
///   manifest. Without the checkout, each fixture skips with the reason
///   [noSubmoduleReason]. With `FIXTURES_REQUIRED=1`, it fails. Tool 4
///   hashes the files of an LF checkout. Thus, when the SHA-256 of the
///   bytes differs, the runner also compares the SHA-256 of the bytes with
///   each CRLF changed to LF. A checkout with `core.autocrlf=true` (the
///   default of Git for Windows) has CRLF line ends: the submodule has no
///   `.gitattributes`, and the root `.gitattributes` does not apply to it.
///
/// This library is not a pure layer: it imports `flutter_test` and
/// `dart:io`. A test that imports it needs `@TestOn('vm')`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:chartjs_test_utils/src/dom.dart' show pumpFrame, pumpFrames;
import 'package:chartjs_test_utils/src/utils.dart' as utils;
// The harness keeps the charts of flutter_chartjs_port, which does not export
// lib/src.
// ignore: implementation_imports
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
// typeof run === 'function' and the call of the hook,
// ignore: implementation_imports
import 'package:flutter_chartjs_port/src/js/js_function.dart';
// ToBoolean,
// ignore: implementation_imports
import 'package:flutter_chartjs_port/src/js/js_number.dart';
// the JS property read,
// ignore: implementation_imports
import 'package:flutter_chartjs_port/src/js/js_object.dart';
// and the undefined sentinel.
// ignore: implementation_imports
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_test/flutter_test.dart';

/// The tag of each fixture test (Chart.js ADR 0029, section 10).
const String fixturesTag = 'fixtures';

/// The skip reason of each fixture when the upstream fixture files are not
/// checked out (Chart.js ADR 0029, section 11 item 5).
const String noSubmoduleReason =
    'n/a: the submodule third_party/Chart.js is not checked out';

/// The environment variable that makes a missing checkout fail (the CI job
/// `fixtures`).
const String fixturesRequiredVariable = 'FIXTURES_REQUIRED';

/// A config loader (fixture.js:24 and :27 give a new `json` object at each
/// load).
///
/// A hand loader runs its body again at each call, and gives a new object.
/// A data loader gives the decoded subtree of `fixtures.json`, which is the
/// same object at each call in one isolate. The chart writes into it. This
/// is correct because each subtree feeds exactly one test (Chart.js ADR
/// 0029, section 3 item 4). Do not load a data config two times in one
/// isolate.
typedef FixtureLoad = Map<String, Object?> Function();

/// A hand-ported config: its loader and the first 12 hex digits of the
/// `sha256` of the upstream file in the manifest.
typedef HandFixture = ({FixtureLoad load, String sha256});

/// One item of `fixtures.items` of the manifest of tool 4.
typedef FixtureItem = ({String path, String sha256, String? png, bool data});

/// fixture.js:36 `inputs`: the loader of the config and the PNG path.
typedef FixtureInputs = ({FixtureLoad? load, String? png});

/// The decoded files of [FixtureSource], by file path. A test file reads
/// each file once.
final Map<String, Object?> _decoded = {};

/// The files of tool 4 that stand for the Karma files (fixture.js:77).
///
/// The paths are relative to the working directory of `flutter test`, the
/// package root.
final class FixtureSource {
  /// The files of tool 4 at [manifest] and [data], and the upstream
  /// fixture files in [upstream].
  const FixtureSource({
    this.manifest = 'doc/upstream/manifest.json',
    this.data = 'doc/upstream/fixtures.json',
    this.upstream = '../../third_party/Chart.js/test/fixtures',
    this.requireUpstream,
  });

  /// The manifest of tool 4.
  final String manifest;

  /// The pure data configs of tool 4, by fixture path.
  final String data;

  /// The directory of the upstream fixture files at the pin.
  final String upstream;

  /// Whether a missing [upstream] directory fails each fixture. Null reads
  /// the environment variable `FIXTURES_REQUIRED`: `1` fails.
  final bool? requireUpstream;

  /// Whether a missing [upstream] directory fails each fixture.
  bool get upstreamRequired =>
      requireUpstream ?? Platform.environment[fixturesRequiredVariable] == '1';

  /// Whether the upstream fixture files are checked out. An uninitialized
  /// submodule is an empty directory.
  bool get hasUpstream => Directory(upstream).existsSync();

  /// The items of the manifest, in its order. Read once for each isolate.
  List<FixtureItem> get items =>
      (_decoded['items:$manifest'] ??= _readItems(manifest))
          as List<FixtureItem>;

  /// The pure data config of [path]. The data file is decoded once for each
  /// isolate, at the first call. Each subtree feeds one test.
  Map<String, Object?> dataConfig(String path) {
    final configs =
        (_decoded[data] ??= jsonDecode(File(data).readAsStringSync()))!
            as Map<String, Object?>;
    final config = configs[path];
    if (config is! Map<String, Object?>) {
      throw StateError('$path is not a pure data config of $data.');
    }
    return config;
  }

  static List<FixtureItem> _readItems(String manifest) {
    final json =
        jsonDecode(File(manifest).readAsStringSync())! as Map<String, Object?>;
    final fixtures = json['fixtures']! as Map<String, Object?>;
    return [
      for (final item
          in (fixtures['items']! as List<Object?>).cast<Map<String, Object?>>())
        (
          path: item['path']! as String,
          sha256: item['sha256']! as String,
          png: item['png'] as String?,
          data: item['data'] == true,
        ),
    ];
  }
}

/// fixture.js:73 `specsFromFixtures(path)`: the body of `group('auto', ...)`.
///
/// [path] is a regular expression source, as upstream: a dot matches any
/// character, and `scale.time` also matches `scale.timeseries`. [hand] maps
/// a fixture path to its hand port, and [skips] maps a fixture path to its
/// skip reason. Throws a [StateError] when a key of [hand] or [skips] is not
/// a fixture of the manifest.
void Function() specsFromFixtures(
  String path, {
  Map<String, HandFixture> hand = const {},
  Map<String, String> skips = const {},
  FixtureSource source = const FixtureSource(),
}) {
  // DIVERGES(chartjs): harness-fixture-sources, the manifest.
  final items = source.items;
  final known = {for (final item in items) item.path};
  for (final key in [...hand.keys, ...skips.keys]) {
    if (!known.contains(key)) {
      throw StateError('$key is not a fixture of ${source.manifest}.');
    }
  }
  // fixture.js:74: the prefix is a regular expression source, not escaped.
  final regex = RegExp('^$path.+\\.(json|js)\$');
  final inputs = [
    for (final item in items)
      if (regex.hasMatch(item.path)) item,
  ];
  return () {
    final checkedOut = source.hasUpstream;
    for (final item in inputs) {
      _declare(item, hand[item.path], skips[item.path], source, checkedOut);
    }
  };
}

/// Declares the test of [item]: a skip, a failing test for a stale entry or
/// a missing checkout, or [specFromFixture].
void _declare(
  FixtureItem item,
  HandFixture? hand,
  String? skip,
  FixtureSource source,
  bool checkedOut,
) {
  // DIVERGES(chartjs): harness-fixture-sources, the registry.
  final path = item.path;
  if (skip != null) {
    final plugin = RegExp(r'^blocked: plugin\.(\S+)$').firstMatch(skip)?[1];
    if (plugin != null && Chart.registry.plugins.get(plugin) != null) {
      test(
        path,
        () => fail(
          'stale skip: plugin.$plugin is registered. Remove the skip of '
          '$path.',
        ),
        tags: fixturesTag,
      );
    } else {
      // DIVERGES(chartjs): harness-fixture-frame, a plain test.
      test(path, () {}, skip: skip, tags: fixturesTag);
    }
    return;
  }
  if (!checkedOut) {
    if (source.upstreamRequired) {
      test(
        path,
        () => fail(
          'the upstream fixture files are not checked out at '
          '${source.upstream}, and $fixturesRequiredVariable is 1. Run '
          '"dart run melos run upstream".',
        ),
        tags: fixturesTag,
      );
    } else {
      test(path, () {}, skip: noSubmoduleReason, tags: fixturesTag);
    }
    return;
  }
  final description = path.substring(0, path.lastIndexOf('.'));
  if (hand != null) {
    if (hand.sha256.length != 12 || !item.sha256.startsWith(hand.sha256)) {
      test(
        path,
        () => fail(
          'the hand port of $path is stale: port the diff of the bump and '
          'update its sha256.',
        ),
        tags: fixturesTag,
      );
      return;
    }
    specFromFixture(description, path, (
      load: _checked(item, source, hand.load),
      png: item.png,
    ));
  } else if (item.data) {
    specFromFixture(description, path, (
      load: _checked(item, source, () => source.dataConfig(path)),
      png: item.png,
    ));
  } else {
    specFromFixture(description, path, (load: null, png: item.png));
  }
}

/// [load] after the check of the upstream file of [item]: its SHA-256 must
/// be the `sha256` of the manifest (Chart.js ADR 0029, section 3 item 5).
/// The SHA-256 of the bytes with each CRLF changed to LF is also correct:
/// tool 4 hashes an LF checkout, and `core.autocrlf=true` writes CRLF line
/// ends.
FixtureLoad _checked(FixtureItem item, FixtureSource source, FixtureLoad load) {
  return () {
    final file = File('${source.upstream}/${item.path}');
    if (!file.existsSync()) {
      fail(
        'the upstream file ${item.path} does not exist in ${source.upstream}: '
        'the manifest ${source.manifest} is not at the pin. Run "dart run '
        'melos run upstream:manifest".',
      );
    }
    final bytes = file.readAsBytesSync();
    final actual = _sha256(bytes);
    if (actual != item.sha256 && _sha256(_lf(bytes)) != item.sha256) {
      fail(
        'the config of ${item.path} is stale: the SHA-256 of the upstream '
        'file is $actual, and ${source.manifest} has ${item.sha256} (the '
        'runner also compared the file with each CRLF changed to LF). Run '
        '"dart run melos run upstream:manifest" and port the diff.',
      );
    }
    return load();
  };
}

/// fixture.js:36 `specFromFixture(description, inputs)`. [description] is
/// the path without its extension: the input key of fixture.js:83 without
/// the prefix `/base/test/fixtures/`.
///
/// Upstream reads `input` from `inputs.js || inputs.json` (:37), the Karma
/// URL. The port gives [input] (the test name, the path with its extension,
/// relative to `test/fixtures/`) as its own parameter, because the loader
/// replaces the URL. Thus the description default (:40) and the message of
/// a missing PNG (:53) have the relative path, not the Karma path.
void specFromFixture(String description, String input, FixtureInputs inputs) {
  testWidgets(input, (tester) async {
    final load = inputs.load;
    if (load == null) {
      fail(
        'hand-port $input to test/fixtures/hand/, or skip it with a reason.',
      );
    }
    final json = load(); // :39
    final descr = jsTruthy(json['description'])
        ? json['description']
        : (json['description'] = description); // :40

    final config = json['config']! as Map<String, Object?>;
    final options =
        (jsTruthy(config['options'])
                ? config['options']
                : (config['options'] = <String, Object?>{}))!
            as Map<String, Object?>; // :43

    // plugins are disabled by default, except if the path contains 'plugin'
    // or there are instance plugins
    if (!input.contains('plugin') &&
        identical(jsGet(config, 'plugins'), undefined)) {
      options['plugins'] = jsTruthy(options['plugins'])
          ? options['plugins']
          : false;
    }

    final fixtureOptions = json['options'] as Map<String, Object?>?;
    final chart = utils.acquireChart(config, fixtureOptions); // :50
    try {
      final run = fixtureOptions == null
          ? undefined
          : jsGet(fixtureOptions, 'run'); // :63
      if (jsIsFunction(run)) {
        final result = jsCall(run, [chart]);
        if (result is Future<Object?>) await _settle(result); // :65
      }
      if (inputs.png == null) {
        fail('$descr\r\nMissing PNG comparison file for $input'); // :52-55
      }
      // DIVERGES(chartjs): harness-fixture-frame, one frame.
      await pumpFrame(); // :57
      // :58 toEqualImageData: n/a (Chart.js ADR 0034 section 4).
    } finally {
      // DIVERGES(chartjs): harness-fixture-frame, also on a fail.
      utils.releaseChart(chart); // :59
    }
  }, tags: fixturesTag);
}

/// `Promise.resolve(run(chart))` (fixture.js:65): pumps frames until
/// [future] settles. Then throws its error, if any. [pumpFrames] fails with
/// the Jasmine timeout message after 5000 ms.
Future<void> _settle(Future<Object?> future) async {
  var settled = false;
  Object? error;
  StackTrace? stackTrace;
  unawaited(
    future.then<void>(
      (_) => settled = true,
      onError: (Object e, StackTrace s) {
        error = e;
        stackTrace = s;
        settled = true;
      },
    ),
  );
  await pumpFrames(() => settled);
  if (error case final e?) Error.throwWithStackTrace(e, stackTrace!);
}

// The SHA-256 of FIPS 180-4, for the check of the upstream files. The
// harness has no dependency on package:crypto.

const int _mask = 0xffffffff;

const List<int> _k = [
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, //
  0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
  0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786,
  0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
  0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
  0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
  0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,
  0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
  0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
];

/// [bytes] with each CRLF changed to LF.
Uint8List _lf(Uint8List bytes) {
  if (!bytes.contains(0x0d)) return bytes;
  final result = BytesBuilder(copy: false);
  for (var i = 0; i < bytes.length; i++) {
    if (bytes[i] == 0x0d && i + 1 < bytes.length && bytes[i + 1] == 0x0a) {
      continue;
    }
    result.addByte(bytes[i]);
  }
  return result.takeBytes();
}

int _rotr(int x, int n) => ((x >> n) | (x << (32 - n))) & _mask;

/// The SHA-256 of [message] as 64 lower-case hex digits.
String _sha256(Uint8List message) {
  final length = message.length;
  final padded = Uint8List(((length + 72) >> 6) << 6)
    ..setRange(0, length, message);
  padded[length] = 0x80;
  final view = ByteData.sublistView(padded)
    ..setUint32(padded.length - 8, (length * 8) ~/ 0x100000000)
    ..setUint32(padded.length - 4, (length * 8) & _mask);
  final h = [
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, //
    0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
  ];
  final w = Uint32List(64);
  for (var chunk = 0; chunk < padded.length; chunk += 64) {
    for (var i = 0; i < 16; i++) {
      w[i] = view.getUint32(chunk + 4 * i);
    }
    for (var i = 16; i < 64; i++) {
      final s0 = _rotr(w[i - 15], 7) ^ _rotr(w[i - 15], 18) ^ (w[i - 15] >> 3);
      final s1 = _rotr(w[i - 2], 17) ^ _rotr(w[i - 2], 19) ^ (w[i - 2] >> 10);
      w[i] = w[i - 16] + s0 + w[i - 7] + s1;
    }
    var a = h[0];
    var b = h[1];
    var c = h[2];
    var d = h[3];
    var e = h[4];
    var f = h[5];
    var g = h[6];
    var hh = h[7];
    for (var i = 0; i < 64; i++) {
      final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
      final ch = (e & f) ^ (~e & g);
      final t1 = (hh + s1 + ch + _k[i] + w[i]) & _mask;
      final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
      final maj = (a & b) ^ (a & c) ^ (b & c);
      final t2 = (s0 + maj) & _mask;
      hh = g;
      g = f;
      f = e;
      e = (d + t1) & _mask;
      d = c;
      c = b;
      b = a;
      a = (t1 + t2) & _mask;
    }
    h[0] = (h[0] + a) & _mask;
    h[1] = (h[1] + b) & _mask;
    h[2] = (h[2] + c) & _mask;
    h[3] = (h[3] + d) & _mask;
    h[4] = (h[4] + e) & _mask;
    h[5] = (h[5] + f) & _mask;
    h[6] = (h[6] + g) & _mask;
    h[7] = (h[7] + hh) & _mask;
  }
  return [for (final word in h) word.toRadixString(16).padLeft(8, '0')].join();
}
