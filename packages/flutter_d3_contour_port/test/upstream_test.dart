// Original code, not ported from d3-contour: the pin tests.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_d3_contour_port/d3_contour.dart' show d3ContourVersion;
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
  test('d3ContourVersion is a release version', () {
    expect(d3ContourVersion, matches(_versionPattern));
    expect(_versionPattern.hasMatch('4.0.2'), isTrue);
    expect(_versionPattern.hasMatch('4.0.2+0ba2dd04'), isFalse);
    expect(_versionPattern.hasMatch('v4.0.2'), isFalse);
  });

  final root = _repositoryRoot();
  final manifest = root == null
      ? null
      : File('${root.path}/third_party/d3-contour/package.json');

  test(
    'the checked-out submodule is d3-contour at d3ContourVersion',
    () {
      final upstream =
          jsonDecode(manifest!.readAsStringSync()) as Map<String, Object?>;
      expect(upstream['name'], 'd3-contour');
      expect(upstream['version'], d3ContourVersion);
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
          '${root.path}/packages/flutter_d3_contour_port/tool/port_sources.yaml',
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
          contains(RegExp(r'^marker: d3-contour$', multiLine: true)),
        );
      });

      test('has one entry, d3-contour at the version', () {
        expect(sources, hasLength(1));
        final entry = sources.single;
        expect(entry['header'], 'd3-contour');
        expect(entry['version'], 'v$d3ContourVersion');
        expect(entry['spdx'], 'ISC');
        expect(entry['holder'], 'Mike Bostock');
        expect(entry['pin.kind'], 'submodule');
        expect(entry['pin.path'], 'third_party/d3-contour');
        expect(entry['pin.commit'], matches(RegExp(r'^[0-9a-f]{40}$')));
        expect(entry['pin.ref'], 'v$d3ContourVersion');
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

      final gitlink = root == null
          ? null
          : _gitlink(root, 'third_party/d3-contour');
      test(
        'the gitlink of third_party/d3-contour is the commit of the entry',
        () {
          expect(gitlink, sources.single['pin.commit']);
        },
        skip: gitlink == null
            ? 'git or the third_party/d3-contour gitlink is not available'
            : false,
      );
    },
    skip: sourcesFile == null
        ? 'not inside the flutter_ports repository'
        : false,
  );
}
