// Original code, not ported from Chart.js: the source files of the tests.

import 'dart:io';

import 'package:chartjs_docs/ui/snippets.dart';

/// The source files of the code panels, read from the disk. Each read adds
/// its path to [reads].
CodeSources fileSources([List<String>? reads]) => CodeSources((path) async {
  reads?.add(path);
  return File(path).readAsStringSync();
});

/// The paths of the source files of [folders], sorted.
List<String> sourceFiles([List<String> folders = snippetFolders]) => [
  for (final folder in folders)
    for (final file
        in Directory(folder).listSync().whereType<File>().toList()
          ..sort((a, b) => a.path.compareTo(b.path)))
      if (isSnippetSource(file.path)) file.path,
];

/// The regions of all the source files of [folders].
Snippets regionsOf(List<String> folders) => Snippets.parseAll([
  for (final path in sourceFiles(folders)) File(path).readAsStringSync(),
]);
