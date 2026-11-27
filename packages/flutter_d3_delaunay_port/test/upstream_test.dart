// Original code, not ported from d3-delaunay: the pin tests.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_d3_delaunay_port/d3_delaunay.dart'
    show d3DelaunayVersion, delaunatorVersion, robustPredicatesVersion;
import 'package:test/test.dart';

final RegExp _versionPattern = RegExp(r'^\d+\.\d+\.\d+$');

Directory? _repositoryRoot() {
  var dir = Directory.current.absolute;
  while (true) {
    if (File('${dir.path}/.gitmodules').existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) return null;
    dir = parent;
  }
}

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

String _scalar(String text) {
  final value = text.trim();
  if (value.length >= 2 &&
      (value.startsWith('"') && value.endsWith('"') ||
          value.startsWith("'") && value.endsWith("'"))) {
    return value.substring(1, value.length - 1);
  }
  return value;
}

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

List<String> _submodulePaths(String text) => [
  for (final match in RegExp(
    r'^\s*path\s*=\s*(\S+)\s*$',
    multiLine: true,
  ).allMatches(text))
    match.group(1)!,
];

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
  test('upstream version constants are release versions', () {
    expect(d3DelaunayVersion, matches(_versionPattern));
    expect(delaunatorVersion, matches(_versionPattern));
    expect(robustPredicatesVersion, matches(_versionPattern));
  });

  final root = _repositoryRoot();
  final manifests = <(String, String, String, File?)>[
    (
      'd3-delaunay',
      d3DelaunayVersion,
      'third_party/d3-delaunay',
      root == null
          ? null
          : File('${root.path}/third_party/d3-delaunay/package.json'),
    ),
    (
      'delaunator',
      delaunatorVersion,
      'third_party/delaunator',
      root == null
          ? null
          : File('${root.path}/third_party/delaunator/package.json'),
    ),
    (
      'robust-predicates',
      robustPredicatesVersion,
      'third_party/robust-predicates',
      root == null
          ? null
          : File('${root.path}/third_party/robust-predicates/package.json'),
    ),
  ];

  for (final (name, version, _, manifest) in manifests) {
    test(
      'the checked-out submodule is $name at $version',
      () {
        final upstream =
            jsonDecode(manifest!.readAsStringSync()) as Map<String, Object?>;
        expect(upstream['name'], name);
        expect(upstream['version'], version);
      },
      skip: manifest == null
          ? 'not inside the flutter_ports repository'
          : manifest.existsSync()
          ? false
          : '${manifest.path} is missing. Run `dart run melos run upstream`.',
    );
  }

  final sourcesFile = root == null
      ? null
      : File(
          '${root.path}/packages/flutter_d3_delaunay_port/tool/port_sources.yaml',
        );
  final sources = sourcesFile != null && sourcesFile.existsSync()
      ? _readSources(sourcesFile.readAsStringSync())
      : const <Map<String, String>>[];

  group(
    'tool/port_sources.yaml',
    () {
      test('names the marker tag', () {
        final text = sourcesFile!.readAsStringSync();
        expect(
          text,
          contains(RegExp(r'^marker: d3-delaunay$', multiLine: true)),
        );
      });

      test('has three entries: d3-delaunay, delaunator, robust-predicates', () {
        expect(sources, hasLength(3));

        final delaunay = sources[0];
        expect(delaunay['header'], 'd3-delaunay');
        expect(delaunay['version'], 'v$d3DelaunayVersion');
        expect(delaunay['spdx'], 'ISC');
        expect(delaunay['holder'], 'Observable, Inc.');
        expect(delaunay['pin.path'], 'third_party/d3-delaunay');
        expect(delaunay['pin.ref'], 'v$d3DelaunayVersion');
        expect(delaunay['pin.commit'], matches(RegExp(r'^[0-9a-f]{40}$')));

        final delaunator = sources[1];
        expect(delaunator['header'], 'delaunator');
        expect(delaunator['version'], 'v$delaunatorVersion');
        expect(delaunator['spdx'], 'ISC');
        expect(delaunator['holder'], 'Mapbox');
        expect(delaunator['pin.path'], 'third_party/delaunator');
        expect(delaunator['pin.ref'], 'v$delaunatorVersion');
        expect(delaunator['pin.commit'], matches(RegExp(r'^[0-9a-f]{40}$')));

        final robust = sources[2];
        expect(robust['header'], 'robust-predicates');
        expect(robust['version'], 'v$robustPredicatesVersion');
        expect(robust['spdx'], 'Unlicense');
        expect(robust['holder'], 'Vladimir Agafonkin');
        expect(robust['pin.path'], 'third_party/robust-predicates');
        expect(robust['pin.ref'], 'v$robustPredicatesVersion');
        expect(robust['pin.commit'], matches(RegExp(r'^[0-9a-f]{40}$')));
      });

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

      for (var i = 0; i < 3; i++) {
        final (_, _, path, _) = manifests[i];
        final gitlink = root == null ? null : _gitlink(root, path);
        test(
          'the gitlink of $path is the commit of entry $i',
          () {
            expect(gitlink, sources[i]['pin.commit']);
          },
          skip: gitlink == null
              ? 'git or the $path gitlink is not available'
              : false,
        );
      }
    },
    skip: sourcesFile == null
        ? 'not inside the flutter_ports repository'
        : false,
  );
}
