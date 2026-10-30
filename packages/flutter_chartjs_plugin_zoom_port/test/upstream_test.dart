// Original code, not ported from chartjs-plugin-zoom: the pin tests.
@TestOn('vm')
library;

// The test reads the submodule and runs git with dart:io. Thus a web leg
// (`dart test -p chrome`) cannot compile this file.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';
import 'package:test/test.dart';

/// A release version `<major>.<minor>.<patch>`, or a commit pin
/// `<last version>+<sha8>` (Zoom ADR 0001).
final RegExp _versionPattern = RegExp(
  r'^(\d+\.\d+\.\d+)(?:\+([0-9a-f]{8}))?$',
);

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
  test('chartjsPluginZoomVersion is a release version or a commit pin', () {
    expect(chartjsPluginZoomVersion, matches(_versionPattern));
    expect(_versionPattern.hasMatch('2.2.0'), isTrue);
    expect(_versionPattern.hasMatch('2.2.0+fb81d331'), isTrue);
    expect(_versionPattern.hasMatch('2.2.0+fb81d33'), isFalse);
    expect(_versionPattern.hasMatch('2.2.0+FB81D331'), isFalse);
    expect(_versionPattern.hasMatch('v2.2.0'), isFalse);
  });

  test(
    'chartjsPluginZoomPackageVersion is the part of '
    'chartjsPluginZoomVersion before +',
    () {
      expect(
        chartjsPluginZoomPackageVersion,
        _versionPattern.firstMatch(chartjsPluginZoomVersion)!.group(1),
      );
    },
  );

  // CI compares the pinned commit with the upstream tag
  // (tool/check_upstream_pin.sh). These tests find a version mismatch
  // locally when the submodule is checked out.
  final root = _repositoryRoot();
  final manifest = root == null
      ? null
      : File('${root.path}/third_party/chartjs-plugin-zoom/package.json');

  test(
    'chartjsPluginZoomPackageVersion matches the checked-out submodule',
    () {
      final upstream =
          jsonDecode(manifest!.readAsStringSync()) as Map<String, Object?>;
      expect(upstream['name'], 'chartjs-plugin-zoom');
      expect(upstream['version'], chartjsPluginZoomPackageVersion);
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
          '${root.path}/packages/flutter_chartjs_plugin_zoom_port/tool/'
          'port_sources.yaml',
        );
  final sources = sourcesFile != null && sourcesFile.existsSync()
      ? _readSources(sourcesFile.readAsStringSync())
      : const <Map<String, String>>[];
  final commit = _versionPattern.firstMatch(chartjsPluginZoomVersion)?.group(2);

  group(
    'tool/port_sources.yaml',
    () {
      test('has one entry, chartjs-plugin-zoom at the version', () {
        expect(sources, hasLength(1));
        final zoom = sources.single;
        expect(zoom['header'], 'chartjs-plugin-zoom');
        expect(zoom['version'], 'v$chartjsPluginZoomVersion');
        expect(zoom['spdx'], 'MIT');
        expect(zoom['holder'], 'chartjs-plugin-zoom contributors');
        expect(zoom['pin.kind'], 'submodule');
        expect(zoom['pin.path'], 'third_party/chartjs-plugin-zoom');
        expect(zoom['pin.commit'], matches(RegExp(r'^[0-9a-f]{40}$')));
        if (commit == null) {
          expect(zoom['pin.ref'], 'v$chartjsPluginZoomVersion');
        } else {
          // A commit pin names the full commit as its ref.
          expect(zoom['pin.ref'], zoom['pin.commit']);
          expect(zoom['pin.commit'], startsWith(commit));
        }
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
          : _gitlink(root, 'third_party/chartjs-plugin-zoom');
      test(
        'the gitlink of third_party/chartjs-plugin-zoom is the commit of '
        'the entry',
        () {
          expect(gitlink, sources.single['pin.commit']);
        },
        skip: gitlink == null
            ? 'git or the third_party/chartjs-plugin-zoom gitlink is not '
                  'available'
            : false,
      );
    },
    skip: sourcesFile == null
        ? 'not inside the flutter_ports repository'
        : false,
  );
}
