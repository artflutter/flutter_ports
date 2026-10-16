import 'dart:convert';
import 'dart:io';

import 'package:flutter_chartjs/flutter_chartjs.dart';
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

void main() {
  test('chartJsVersion is a plain release version', () {
    expect(chartJsVersion, matches(RegExp(r'^\d+\.\d+\.\d+$')));
  });

  // CI checks the pinned commit itself (tool/check_upstream_pin.sh); this test
  // catches a version mismatch locally once the submodule is checked out.
  final root = _repositoryRoot();
  final manifest = root == null
      ? null
      : File('${root.path}/third_party/Chart.js/package.json');

  test(
    'chartJsVersion matches the checked-out upstream submodule',
    () {
      final upstream =
          jsonDecode(manifest!.readAsStringSync()) as Map<String, Object?>;
      expect(upstream['version'], chartJsVersion);
    },
    skip: manifest == null
        ? 'not inside the flutter_ports repository'
        : manifest.existsSync()
        ? false
        : '${manifest.path} is missing; run `dart run melos run upstream`',
  );
}
