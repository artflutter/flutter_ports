// Original code, not ported from Chart.js: a YAML subset reader.

/// A reader for the block-style YAML subset of `tool/port_sources.yaml`.
///
/// The checks cannot depend on `package:yaml` without a new dependency of
/// `flutter_chartjs`. The subset has block mappings, block sequences, `#`
/// comments and one-line scalars (plain, single-quoted or double-quoted).
/// All scalars are strings. Other YAML gives a [FormatException].
library;

/// Parses [text]. Returns a `Map<String, Object?>`, a `List<Object?>`, a
/// `String` or null (an empty document or an empty value).
Object? parseYamlSubset(String text) => _Parser(_lines(text)).document();

final class _Line {
  const _Line(this.number, this.indent, this.text);

  final int number;
  final int indent;
  final String text;
}

List<_Line> _lines(String text) {
  final result = <_Line>[];
  final raw = text.split('\n');
  for (var i = 0; i < raw.length; i++) {
    var line = raw[i];
    if (line.endsWith('\r')) line = line.substring(0, line.length - 1);
    final content = _stripComment(line);
    final text = content.trim();
    if (text.isEmpty) continue;
    final indent = content.length - content.trimLeft().length;
    if (content.substring(0, indent).contains('\t')) {
      throw FormatException('line ${i + 1}: tab in the indentation');
    }
    if (text == '---' || text == '...' || text.startsWith('%')) {
      throw FormatException('line ${i + 1}: directives are not supported');
    }
    result.add(_Line(i + 1, indent, text));
  }
  return result;
}

/// [line] without a `#` comment outside quotes.
String _stripComment(String line) {
  int? quote;
  for (var i = 0; i < line.length; i++) {
    final c = line.codeUnitAt(i);
    if (quote == null) {
      if (c == 0x23 && (i == 0 || line[i - 1] == ' ')) {
        return line.substring(0, i);
      }
      // A quote opens a quoted scalar only at the start of a scalar.
      if ((c == 0x22 || c == 0x27) && (i == 0 || ' :-'.contains(line[i - 1]))) {
        quote = c;
      }
    } else if (quote == 0x22 && c == 0x5C) {
      i++;
    } else if (c == quote) {
      quote = null;
    }
  }
  return line;
}

final class _Parser {
  _Parser(this.lines);

  final List<_Line> lines;
  int index = 0;

  bool get _done => index >= lines.length;

  _Line get _current => lines[index];

  Object? document() {
    if (lines.isEmpty) return null;
    final result = _node(_current.indent);
    if (!_done) throw _error(_current, 'unexpected indentation');
    return result;
  }

  FormatException _error(_Line line, String message) =>
      FormatException('line ${line.number}: $message');

  static bool _isItem(String text) => text == '-' || text.startsWith('- ');

  Object? _node(int indent) =>
      _isItem(_current.text) ? _sequence(indent) : _mapping(indent);

  List<Object?> _sequence(int indent) {
    final result = <Object?>[];
    while (!_done && _current.indent == indent && _isItem(_current.text)) {
      final line = _current;
      final rest = line.text.substring(1).trimLeft();
      if (rest.isEmpty) {
        index++;
        result.add(
          !_done && _current.indent > indent ? _node(_current.indent) : null,
        );
      } else if (_splitKey(rest, line) != null) {
        // `- key: value` starts a mapping at the column of `key`.
        final column = indent + line.text.length - rest.length;
        lines[index] = _Line(line.number, column, rest);
        result.add(_mapping(column));
      } else {
        result.add(_scalar(rest, line));
        index++;
      }
    }
    if (!_done && _current.indent > indent) {
      throw _error(_current, 'unexpected indentation');
    }
    return result;
  }

  Map<String, Object?> _mapping(int indent) {
    final result = <String, Object?>{};
    while (!_done && _current.indent == indent) {
      final line = _current;
      if (_isItem(line.text)) {
        throw _error(line, 'a sequence item in a mapping');
      }
      final pair = _splitKey(line.text, line);
      if (pair == null) throw _error(line, 'expected "key: value"');
      if (result.containsKey(pair.key)) {
        throw _error(line, 'duplicate key "${pair.key}"');
      }
      index++;
      if (pair.value.isNotEmpty) {
        result[pair.key] = _scalar(pair.value, line);
      } else if (!_done &&
          (_current.indent > indent ||
              (_current.indent == indent && _isItem(_current.text)))) {
        result[pair.key] = _node(_current.indent);
      } else {
        result[pair.key] = null;
      }
    }
    if (!_done && _current.indent > indent) {
      throw _error(_current, 'unexpected indentation');
    }
    return result;
  }

  /// The key and the value text of `key: value`, or null if [text] is not a
  /// mapping entry.
  ({String key, String value})? _splitKey(String text, _Line line) {
    if (text.startsWith('"') || text.startsWith("'")) {
      final end = _quotedEnd(text, line);
      final after = text.substring(end);
      if (after != ':' && !after.startsWith(': ')) return null;
      return (
        key: _scalar(text.substring(0, end), line),
        value: after.substring(1).trim(),
      );
    }
    for (var i = 0; i < text.length; i++) {
      if (text[i] == ':' && (i + 1 == text.length || text[i + 1] == ' ')) {
        final key = text.substring(0, i).trimRight();
        if (key.isEmpty) return null;
        return (key: _scalar(key, line), value: text.substring(i + 1).trim());
      }
    }
    return null;
  }

  /// The offset after the closing quote of the quoted scalar at the start of
  /// [text].
  int _quotedEnd(String text, _Line line) {
    final quote = text[0];
    for (var i = 1; i < text.length; i++) {
      if (quote == '"' && text[i] == r'\') {
        i++;
      } else if (text[i] == quote) {
        if (quote == "'" && i + 1 < text.length && text[i + 1] == "'") {
          i++;
        } else {
          return i + 1;
        }
      }
    }
    throw _error(line, 'unterminated quoted scalar');
  }

  String _scalar(String text, _Line line) {
    if (text.startsWith('"') || text.startsWith("'")) {
      final end = _quotedEnd(text, line);
      if (end != text.length) {
        throw _error(line, 'text after a quoted scalar');
      }
      final body = text.substring(1, end - 1);
      return text[0] == "'"
          ? body.replaceAll("''", "'")
          : _unescape(body, line);
    }
    if ('[]{},&*!|>%@`'.contains(text[0])) {
      throw _error(line, 'unsupported YAML syntax: $text');
    }
    if (text.contains(': ')) {
      throw _error(line, 'quote a scalar that contains ": "');
    }
    return text;
  }

  String _unescape(String body, _Line line) {
    final buffer = StringBuffer();
    for (var i = 0; i < body.length; i++) {
      final c = body[i];
      if (c != r'\') {
        buffer.write(c);
        continue;
      }
      if (++i >= body.length) throw _error(line, 'bad escape');
      switch (body[i]) {
        case '"':
          buffer.write('"');
        case r'\':
          buffer.write(r'\');
        case '/':
          buffer.write('/');
        case 'n':
          buffer.write('\n');
        case 't':
          buffer.write('\t');
        case 'u':
          if (i + 4 >= body.length) throw _error(line, 'bad escape');
          final code = int.tryParse(body.substring(i + 1, i + 5), radix: 16);
          if (code == null) throw _error(line, 'bad escape');
          buffer.writeCharCode(code);
          i += 4;
        default:
          throw _error(line, r'unsupported escape \' + body[i]);
      }
    }
    return buffer.toString();
  }
}
