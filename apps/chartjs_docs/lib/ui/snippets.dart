// Original code, not ported from Chart.js: the code panels of the docs site.

import 'dart:async';

import 'package:flutter/services.dart' show rootBundle;

/// The folder of the code panels of the line chart page, one file for each
/// panel.
const String lineExamples = 'lib/examples/line';

/// The folder of the code panels of the bar chart page, one file for each
/// panel.
const String barExamples = 'lib/examples/bar';

/// The folders of the source files that the pages show. `pubspec.yaml` lists
/// each folder as an asset folder.
const List<String> snippetFolders = [
  '$lineExamples/',
  '$barExamples/',
  'lib/migrate/fl_chart/',
  'lib/migrate/graphic/',
  'lib/migrate/syncfusion/',
];

/// Whether the asset [path] is a source file of [snippetFolders].
bool isSnippetSource(String path) =>
    path.endsWith('.dart') &&
    snippetFolders.any((folder) => path.startsWith(folder));

/// The region [name] of the source file [source].
class const CodeRegion(
  /// The asset path of the source file, in a folder of [snippetFolders].
  final String source,

  /// The name of the region: the lines between `// #docregion <name>` and
  /// `// #enddocregion <name>`.
  final String name,
) {
  /// Creates the region [name] of [source].
  this;

  @override
  String toString() => '$source#$name';
}

/// The code regions of the source files. A file loads at the first request
/// of one of its regions, and then stays in memory.
class CodeSources(
  /// Reads the text of the source file with an asset path.
  final Future<String> Function(String path) _read,
) {
  /// Creates the source files that the function [_read] reads.
  this;

  /// The source files of the assets of the app.
  factory assets() => CodeSources(rootBundle.loadString);

  final Map<String, Future<Snippets>> _loads = {};
  final Map<String, Snippets> _loaded = {};

  /// The regions of [source], or null before its file loads.
  Snippets? loaded(String source) => _loaded[source];

  /// Loads the regions of [source] once. After an error, the next call reads
  /// the file again.
  Future<Snippets> load(String source) => _loads[source] ??= _parse(source);

  Future<Snippets> _parse(String source) async {
    try {
      return _loaded[source] = Snippets.parse(await _read(source));
    } on Object {
      // The next call reads the file again.
      unawaited(_loads.remove(source));
      rethrow;
    }
  }
}

final RegExp _marker = RegExp(r'^\s*//\s*#(end)?docregion\s+(\S+)\s*$');

/// The named code regions of the source files.
class const Snippets._(final Map<String, String> _regions) {
  /// The regions of [source], between `// #docregion <name>` and
  /// `// #enddocregion <name>`. The text of a region has no markers and no
  /// common indent.
  factory parse(String source) => Snippets.parseAll([source]);

  /// The regions of each source of [sources]. A name must be unique over all
  /// the sources.
  factory parseAll(Iterable<String> sources) {
    final closed = <String, String>{};
    for (final source in sources) {
      final open = <String, List<String>>{};
      for (final line in source.split('\n')) {
        final match = _marker.firstMatch(line);
        if (match == null) {
          for (final lines in open.values) {
            lines.add(line);
          }
        } else if (match[1] == null) {
          open[match[2]!] = [];
        } else {
          final name = match[2]!;
          if (closed.containsKey(name)) {
            throw ArgumentError.value(name, 'name', 'two regions');
          }
          closed[name] = _dedent(open.remove(name)!);
        }
      }
    }
    return Snippets._(closed);
  }

  /// The names of the regions.
  Iterable<String> get names => _regions.keys;

  /// The code of the region [name].
  String operator [](String name) =>
      _regions[name] ?? (throw ArgumentError.value(name, 'name', 'no region'));
}

String _dedent(List<String> lines) {
  var indent = 1 << 30;
  for (final line in lines) {
    if (line.trim().isEmpty) continue;
    final width = line.length - line.trimLeft().length;
    if (width < indent) indent = width;
  }
  return lines
      .map((line) => line.trim().isEmpty ? '' : line.substring(indent))
      .join('\n')
      .trim();
}
