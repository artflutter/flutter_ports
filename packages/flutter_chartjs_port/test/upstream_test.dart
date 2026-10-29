// Original code, not ported from Chart.js: tests of the upstream pin.
@TestOn('vm')
library;

// dart:io reads the submodule and flutter_test reaches dart:ui, so the web
// legs (`dart test -p chrome`) cannot compile this file.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

/// The closest ancestor of the working directory that has a `.gitmodules`
/// file, i.e. the repository root, or null outside the repository.
Directory? _repositoryRoot() {
  var dir = Directory.current.absolute;
  while (true) {
    if (File('${dir.path}/.gitmodules').existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) return null;
    dir = parent;
  }
}

/// A release version, `<major>.<minor>.<patch>`, and for a commit pin
/// `+<sha8>` (doc/upstream-tracking.md §2.4).
final RegExp _versionPattern = RegExp(
  r'^(\d+\.\d+\.\d+)(?:\+([0-9a-f]{8}))?$',
);

/// The gitlink of [path] in the index of [root], or null when git fails or
/// [path] is not a submodule.
String? _gitlink(Directory root, String path) {
  try {
    final result = Process.runSync('git', [
      '-C',
      root.path,
      'ls-files',
      '--stage',
      '--',
      path,
    ]);
    if (result.exitCode != 0) return null;
    return RegExp(
      '^160000 ([0-9a-f]{40}) ',
      multiLine: true,
    ).firstMatch('${result.stdout}')?.group(1);
  } on ProcessException {
    return null;
  }
}

void main() {
  test('chartJsVersion is a release version or a commit pin', () {
    expect(chartJsVersion, matches(_versionPattern));
    expect(_versionPattern.hasMatch('4.5.1'), isTrue);
    expect(_versionPattern.hasMatch('4.5.1+7169e651'), isTrue);
    expect(_versionPattern.hasMatch('4.5.1+7169e65'), isFalse);
    expect(_versionPattern.hasMatch('4.5.1+7169E651'), isFalse);
    expect(_versionPattern.hasMatch('v4.5.1'), isFalse);
  });

  test('chartJsPackageVersion is the part of chartJsVersion before +', () {
    expect(
      chartJsPackageVersion,
      _versionPattern.firstMatch(chartJsVersion)!.group(1),
    );
    expect(Chart.version, chartJsPackageVersion);
  });

  // CI checks the pinned commit itself (tool/check_upstream_pin.sh); this test
  // catches a version mismatch locally once the submodule is checked out.
  final root = _repositoryRoot();
  final manifest = root == null
      ? null
      : File('${root.path}/third_party/Chart.js/package.json');

  test(
    'chartJsPackageVersion matches the checked-out upstream submodule',
    () {
      final upstream =
          jsonDecode(manifest!.readAsStringSync()) as Map<String, Object?>;
      expect(upstream['version'], chartJsPackageVersion);
    },
    skip: manifest == null
        ? 'not inside the flutter_ports repository'
        : manifest.existsSync()
        ? false
        : '${manifest.path} is missing; run `dart run melos run upstream`',
  );

  final commit = _versionPattern.firstMatch(chartJsVersion)?.group(2);
  final gitlink = root == null ? null : _gitlink(root, 'third_party/Chart.js');
  test(
    'the gitlink of a commit pin starts with the commit of chartJsVersion',
    () {
      expect(gitlink, startsWith(commit!));
    },
    skip: commit == null
        ? 'chartJsVersion is a release: tool/check_upstream_pin.sh compares '
              'the gitlink with the tag'
        : gitlink == null
        ? 'git or the third_party/Chart.js gitlink is not available'
        : false,
  );
}
