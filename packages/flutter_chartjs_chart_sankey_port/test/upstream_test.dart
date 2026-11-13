// Original code, not ported from chartjs-chart-sankey: the pin tests.
@TestOn('vm')
library;

// The test reads the submodule and runs git with dart:io. Thus a web leg
// (`dart test -p chrome`) cannot compile this file.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart';
import 'package:test/test.dart';

/// A release version `<major>.<minor>.<patch>` (Sankey ADR 0001).
final RegExp _versionPattern = RegExp(r'^\d+\.\d+\.\d+$');

/// The closest ancestor of the working directory that has a `.gitmodules`
/// file: the repository root. Null outside the repository.
Directory? _repositoryRoot() {
  var dir = Directory.current.absolute;
  while (true) {
    if (File('${dir.path}/.gitmodules').existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) return null;
    dir = parent;
  }
}

/// The entries of a `tool/port_sources.yaml` file.
///
/// Each entry maps a key to its scalar value. The keys are the scalar keys
/// of the entry (`header`, `version`) and the keys of its `pin` mapping
/// with a `pin.` prefix (`pin.path`, `pin.commit`). The reader skips all
/// other lines. An unindented line is a top-level key (`sources`, and the
/// `marker` and `host` of an add-on port): it ends the current entry. The
/// package has no YAML dependency. Thus this small reader reads only the
/// block form of these files.
List<Map<String, String>> _readSources(String text) {
  final entries = <Map<String, String>>[];
  final entryStart = RegExp(r'^  - ([a-z_]+): *(.*)$');
  final keyLine = RegExp(r'^( +)([a-z_]+): *(.*)$');
  Map<String, String>? entry;
  String? section;
  for (final line in const LineSplitter().convert(text)) {
    if (line.trim().isEmpty || line.trimLeft().startsWith('#')) continue;
    if (!line.startsWith(' ')) {
      entry = null;
      section = null;
      continue;
    }
    final start = entryStart.firstMatch(line);
    if (start != null) {
      entry = {start.group(1)!: _scalar(start.group(2)!)};
      entries.add(entry);
      section = null;
      continue;
    }
    final match = keyLine.firstMatch(line);
    if (entry == null || match == null) continue;
    final indent = match.group(1)!.length;
    final key = match.group(2)!;
    final value = _scalar(match.group(3)!);
    if (indent == 4) {
      section = value.isEmpty ? key : null;
      if (value.isNotEmpty) entry[key] = value;
    } else if (indent == 6 && section == 'pin' && value.isNotEmpty) {
      entry['pin.$key'] = value;
    }
  }
  return entries;
}

/// [text] without its quotes.
String _scalar(String text) {
  final value = text.trim();
  if (value.length >= 2 &&
      (value.startsWith('"') && value.endsWith('"') ||
          value.startsWith("'") && value.endsWith("'"))) {
    return value.substring(1, value.length - 1);
  }
  return value;
}

/// The gitlink of [path] in the index of [root]: the commit that the
/// superproject records for the submodule. It works for staged and for
/// committed gitlinks. Null when git fails or [path] is not a submodule.
String? _gitlink(Directory root, String path) {
  final ProcessResult result;
  try {
    result = Process.runSync('git', [
      '-C',
      root.path,
      'ls-files',
      '--stage',
      '--',
      path,
    ]);
  } on ProcessException {
    return null;
  }
  if (result.exitCode != 0) return null;
  final match = RegExp(
    '^160000 ([0-9a-f]{40}) ',
    multiLine: true,
  ).firstMatch('${result.stdout}');
  return match?.group(1);
}

/// The `path` values of the `.gitmodules` file [text].
List<String> _submodulePaths(String text) => [
  for (final match in RegExp(
    r'^\s*path\s*=\s*(\S+)\s*$',
    multiLine: true,
  ).allMatches(text))
    match.group(1)!,
];

/// The `tool/port_sources.yaml` files of the workspace packages under
/// [root], sorted by path. Each file lists the submodules of one port.
List<File> _sourceFiles(Directory root) {
  final packages = Directory('${root.path}/packages');
  if (!packages.existsSync()) return const [];
  return [
    for (final dir in packages.listSync().whereType<Directory>())
      if (File('${dir.path}/tool/port_sources.yaml').existsSync())
        File('${dir.path}/tool/port_sources.yaml'),
  ]..sort((a, b) => a.path.compareTo(b.path));
}

void main() {
  test('chartjsChartSankeyVersion is a release version', () {
    expect(chartjsChartSankeyVersion, matches(_versionPattern));
    expect(_versionPattern.hasMatch('0.19.1'), isTrue);
    expect(_versionPattern.hasMatch('0.19.1+90b638b1'), isFalse);
    expect(_versionPattern.hasMatch('v0.19.1'), isFalse);
  });

  // CI compares the pinned commit with the upstream tag
  // (tool/check_upstream_pin.sh). These tests find a version mismatch
  // locally when the submodule is checked out.
  final root = _repositoryRoot();
  final manifest = root == null
      ? null
      : File('${root.path}/third_party/chartjs-chart-sankey/package.json');

  // Upstream releases with semantic-release: the `version` of package.json
  // is a placeholder at each commit, and the release version is the tag
  // name. tool/check_upstream_pin.sh compares the gitlink with the commit of
  // the tag `v<chartjsChartSankeyVersion>`.
  test(
    'the checked-out submodule is chartjs-chart-sankey',
    () {
      final upstream =
          jsonDecode(manifest!.readAsStringSync()) as Map<String, Object?>;
      expect(upstream['name'], 'chartjs-chart-sankey');
      expect(upstream['version'], '0.0.0-development');
    },
    skip: manifest == null
        ? 'not inside the flutter_ports repository'
        : manifest.existsSync()
        ? false
        : '${manifest.path} is missing. Run `dart run melos run upstream`.',
  );

  final sourcesFile = root == null
      ? null
      : File(
          '${root.path}/packages/flutter_chartjs_chart_sankey_port/tool/'
          'port_sources.yaml',
        );
  final sources = sourcesFile != null && sourcesFile.existsSync()
      ? _readSources(sourcesFile.readAsStringSync())
      : const <Map<String, String>>[];

  test('the reader of port_sources.yaml skips the top-level keys', () {
    const text = '''
# A comment.
marker: sankey
host: flutter_chartjs_port

sources:
  - header: a
    version: "v1.0.0"
    pin:
      kind: submodule
      path: third_party/a
      commit: 0123
marker: x
    path: third_party/b
''';
    expect(_readSources(text), [
      {
        'header': 'a',
        'version': 'v1.0.0',
        'pin.kind': 'submodule',
        'pin.path': 'third_party/a',
        'pin.commit': '0123',
      },
    ]);
  });

  group(
    'tool/port_sources.yaml',
    () {
      test('names the marker tag and the host of the add-on port', () {
        final text = sourcesFile!.readAsStringSync();
        expect(text, contains(RegExp(r'^marker: sankey$', multiLine: true)));
        expect(
          text,
          contains(RegExp(r'^host: flutter_chartjs_port$', multiLine: true)),
        );
      });

      test('has one entry, chartjs-chart-sankey at the version', () {
        expect(sources, hasLength(1));
        final sankey = sources.single;
        expect(sankey['header'], 'chartjs-chart-sankey');
        expect(sankey['version'], 'v$chartjsChartSankeyVersion');
        expect(sankey['spdx'], 'MIT');
        expect(sankey['holder'], 'Jukka Kurkela');
        expect(sankey['pin.kind'], 'submodule');
        expect(sankey['pin.path'], 'third_party/chartjs-chart-sankey');
        expect(sankey['pin.commit'], matches(RegExp(r'^[0-9a-f]{40}$')));
        expect(sankey['pin.ref'], 'v$chartjsChartSankeyVersion');
      });

      // The gitlink test below reads the entry. This test also finds a
      // submodule without an entry. Each port lists its submodules in its
      // own tool/port_sources.yaml.
      test('each submodule of .gitmodules is the pin of an entry', () {
        final pins = [
          for (final file in _sourceFiles(root!))
            for (final source in _readSources(file.readAsStringSync()))
              if (source['pin.kind'] == 'submodule') source['pin.path'],
        ];
        expect(
          _submodulePaths(File('${root.path}/.gitmodules').readAsStringSync()),
          unorderedEquals(pins),
        );
      });

      final gitlink = root == null
          ? null
          : _gitlink(root, 'third_party/chartjs-chart-sankey');
      test(
        'the gitlink of third_party/chartjs-chart-sankey is the commit of '
        'the entry',
        () {
          expect(gitlink, sources.single['pin.commit']);
        },
        skip: gitlink == null
            ? 'git or the third_party/chartjs-chart-sankey gitlink is not '
                  'available'
            : false,
      );
    },
    skip: sourcesFile == null
        ? 'not inside the flutter_ports repository'
        : false,
  );
}
