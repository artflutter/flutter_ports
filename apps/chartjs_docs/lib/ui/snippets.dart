// Original code, not ported from Chart.js: the code panels of the docs site.

import 'package:flutter/services.dart' show rootBundle;

/// The asset with the code of the live charts.
const String examplesAsset = 'lib/examples/line_examples.dart';

final RegExp _marker = RegExp(r'^\s*//\s*#(end)?docregion\s+(\S+)\s*$');

/// The named code regions of a source file.
class Snippets {
  /// The regions of [source], between `// #docregion <name>` and
  /// `// #enddocregion <name>`. The text of a region has no markers and no
  /// common indent.
  factory Snippets.parse(String source) {
    final open = <String, List<String>>{};
    final closed = <String, String>{};
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
        closed[name] = _dedent(open.remove(name)!);
      }
    }
    return Snippets._(closed);
  }

  const Snippets._(this._regions);

  /// Loads the regions of [examplesAsset].
  static Future<Snippets> load() async =>
      Snippets.parse(await rootBundle.loadString(examplesAsset));

  final Map<String, String> _regions;

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
