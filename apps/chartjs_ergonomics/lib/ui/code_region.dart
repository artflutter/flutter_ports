// Original code, not ported from Chart.js: the code region of a sample file.

final RegExp _marker = RegExp(r'^\s*//\s*#(end)?docregion\s+sample\s*$');

/// The lines of [source] between `// #docregion sample` and
/// `// #enddocregion sample`, with no common indent. Throws a
/// [FormatException] when [source] has no such region.
String codeRegion(String source) {
  final lines = <String>[];
  var open = false;
  var closed = false;
  for (final line in source.split('\n')) {
    final match = _marker.firstMatch(line);
    if (match == null) {
      if (open) lines.add(line.trimRight());
    } else if (match[1] == null) {
      open = true;
    } else if (open) {
      open = false;
      closed = true;
    }
  }
  if (!closed) throw const FormatException('No region `sample`.');
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
