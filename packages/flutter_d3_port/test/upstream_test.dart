// Original code, not ported from D3: tests of the upstream pins.
@TestOn('vm')
library;

// The test reads the submodules and runs git with dart:io. Thus the web legs
// (`dart test -p chrome`) cannot compile this file.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_d3_port/flutter_d3_port.dart';
import 'package:test/test.dart';

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
/// other lines. The package has no YAML dependency. Thus this small reader
/// reads only the block form of these files.
List<Map<String, String>> _readSources(String text) {
  final entries = <Map<String, String>>[];
  final entryStart = RegExp(r'^  - ([a-z_]+): *(.*)$');
  final keyLine = RegExp(r'^( +)([a-z_]+): *(.*)$');
  Map<String, String>? entry;
  String? section;
  for (final line in const LineSplitter().convert(text)) {
    if (line.trim().isEmpty || line.trimLeft().startsWith('#')) continue;
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
  final result = Process.runSync('git', [
    '-C',
    root.path,
    'ls-files',
    '--stage',
    '--',
    path,
  ]);
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

/// Whether git runs in [root].
bool _hasGit(Directory root) {
  try {
    return Process.runSync('git', [
          '-C',
          root.path,
          'rev-parse',
          '--git-dir',
        ]).exitCode ==
        0;
  } on ProcessException {
    return false;
  }
}

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
  test('d3Version is a plain release version', () {
    expect(d3Version, matches(RegExp(r'^\d+\.\d+\.\d+$')));
  });

  // CI compares the pinned commits with the upstream tags
  // (tool/check_upstream_pin.sh). This test finds a version mismatch
  // locally when the submodule is checked out.
  final root = _repositoryRoot();
  final manifest = root == null
      ? null
      : File('${root.path}/third_party/d3/package.json');

  test(
    'd3Version matches the checked-out upstream submodule',
    () {
      final upstream =
          jsonDecode(manifest!.readAsStringSync()) as Map<String, Object?>;
      expect(upstream['version'], d3Version);
    },
    skip: manifest == null
        ? 'not inside the flutter_ports repository'
        : manifest.existsSync()
        ? false
        : '${manifest.path} is missing. Run `dart run melos run upstream`.',
  );

  final sourcesFile = root == null
      ? null
      : File('${root.path}/packages/flutter_d3_port/tool/port_sources.yaml');
  final sources = sourcesFile != null && sourcesFile.existsSync()
      ? _readSources(sourcesFile.readAsStringSync())
      : const <Map<String, String>>[];

  group(
    'tool/port_sources.yaml',
    () {
      test('has an entry for the d3 bundle at v$d3Version', () {
        final d3 = sources.where((s) => s['header'] == 'd3').toList();
        expect(d3, hasLength(1));
        expect(d3.single['version'], 'v$d3Version');
        expect(d3.single['pin.ref'], 'v$d3Version');
        expect(d3.single['pin.path'], 'third_party/d3');
      });

      // The gitlink tests below read the entries. This test also finds a
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

      final git = root != null && _hasGit(root);
      for (final source in sources) {
        final header = source['header'];
        final path = source['pin.path'];
        test(
          '$header: the gitlink of $path is the commit of the entry',
          () {
            expect(source['pin.kind'], 'submodule');
            expect(source['pin.ref'], source['version']);
            expect(source['pin.commit'], matches(RegExp(r'^[0-9a-f]{40}$')));
            expect(_gitlink(root!, path!), source['pin.commit']);
          },
          skip: git ? false : 'git is not available in the repository',
        );
      }
    },
    skip: sourcesFile == null
        ? 'not inside the flutter_ports repository'
        : false,
  );
}
