// Original code, not ported from Chart.js: the code panels of the docs site.

import 'package:flutter/services.dart' show AssetManifest, rootBundle;

/// The source file of the live charts of the line chart page.
const String examplesAsset = 'lib/examples/line_examples.dart';

/// The folders of the source files that the pages show. `pubspec.yaml` lists
/// each folder as an asset folder.
const List<String> snippetFolders = [
  'lib/examples/',
  'lib/migrate/fl_chart/',
  'lib/migrate/graphic/',
  'lib/migrate/syncfusion/',
];

/// Whether the asset [path] is a source file of [snippetFolders].
bool isSnippetSource(String path) =>
    path.endsWith('.dart') &&
    snippetFolders.any((folder) => path.startsWith(folder));

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

  /// Loads the regions of the source files of [snippetFolders].
  static Future<Snippets> load() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final paths = manifest.listAssets().where(isSnippetSource).toList()..sort();
    return Snippets.parseAll([
      for (final path in paths) await rootBundle.loadString(path),
    ]);
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
