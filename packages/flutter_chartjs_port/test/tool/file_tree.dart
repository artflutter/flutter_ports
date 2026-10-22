// Original code, not ported from Chart.js: temporary file trees for tests.

/// Temporary directory trees for the tests of the port checks.
library;

import 'dart:io';

import 'package:test/test.dart';

import '../../tool/src/check_support.dart';

/// A temporary directory that the test deletes in its tear-down.
final class FileTree {
  /// Creates the directory and registers its deletion with [addTearDown].
  FileTree()
    : root = posixPath(Directory.systemTemp.createTempSync('pc_').path) {
    addTearDown(() => Directory(root).deleteSync(recursive: true));
  }

  /// The absolute directory, with `/` separators.
  final String root;

  /// The absolute path of the relative [path].
  String path(String path) => '$root/$path';

  /// Writes [lines], each with a line end, to the relative [path].
  void write(String path, List<String> lines) =>
      writeText(path, lines.map((line) => '$line\n').join());

  /// Writes [text] to the relative [path].
  void writeText(String path, String text) {
    File(this.path(path))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(text);
  }

  /// Deletes the relative [path].
  void delete(String path) => File(this.path(path)).deleteSync();

  /// Deletes the relative directory [path] and its contents.
  void deleteDirectory(String path) =>
      Directory(this.path(path)).deleteSync(recursive: true);

  /// Creates the empty directory [path].
  void mkdir(String path) =>
      Directory(this.path(path)).createSync(recursive: true);
}

/// The messages of [findings], each with its path and line, for `expect`.
List<String> describeFindings(Iterable<Finding> findings) => [
  for (final finding in findings) finding.toString(),
];
