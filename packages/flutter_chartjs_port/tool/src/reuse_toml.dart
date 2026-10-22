// Original code, not ported from Chart.js: a REUSE.toml reader.

/// A reader for the `[[annotations]]` tables of `REUSE.toml`.
///
/// It reads the TOML subset that `REUSE.toml` uses: tables, arrays of
/// tables, `key = value` lines, strings, arrays (also on more than one line)
/// and `#` comments. Other values stay as their text. The checks cannot
/// depend on a TOML package without a new dependency of `flutter_chartjs_port`.
library;

import 'check_support.dart';

/// One `[[annotations]]` table.
final class ReuseAnnotation {
  /// An annotation of [paths] on [line].
  ReuseAnnotation({
    required this.line,
    required this.paths,
    required this.copyrights,
    required this.license,
  }) : _patterns = [for (final path in paths) globToRegExp(path)];

  /// The 1-based line of the `[[annotations]]` header.
  final int line;

  /// The `path` globs.
  final List<String> paths;

  /// The `SPDX-FileCopyrightText` entries.
  final List<String> copyrights;

  /// The `SPDX-License-Identifier` expression.
  final String license;

  final List<RegExp> _patterns;

  /// The license identifiers of [license], without `AND`, `OR`, `WITH` and
  /// parentheses.
  Set<String> get licenseIds => {
    for (final token in license.split(RegExp(r'[\s()]+')))
      if (token.isNotEmpty && !const {'AND', 'OR', 'WITH'}.contains(token))
        token,
  };

  /// Whether a `path` glob matches the repository-relative [path].
  bool matches(String path) => _patterns.any((p) => p.hasMatch(path));
}

/// The annotations of [text], in file order. Throws a [FormatException] for
/// text outside the subset.
List<ReuseAnnotation> parseReuseToml(String text) {
  final tables = _TomlReader(text).read();
  return [
    for (final table in tables)
      if (table.name == 'annotations' && table.isArray)
        ReuseAnnotation(
          line: table.line,
          paths: _strings(table.values['path']),
          copyrights: _strings(table.values['SPDX-FileCopyrightText']),
          license: _strings(table.values['SPDX-License-Identifier']).join(' '),
        ),
  ];
}

/// The annotation that REUSE applies to [path]: the last one that matches.
ReuseAnnotation? annotationFor(List<ReuseAnnotation> annotations, String path) {
  for (final annotation in annotations.reversed) {
    if (annotation.matches(path)) return annotation;
  }
  return null;
}

List<String> _strings(Object? value) => switch (value) {
  null => const [],
  final String s => [s],
  final List<Object?> list => [for (final item in list) '$item'],
  _ => ['$value'],
};

final class _Table {
  _Table(this.name, this.line, {required this.isArray});

  final String name;
  final int line;
  final bool isArray;
  final Map<String, Object?> values = {};
}

final class _TomlReader {
  _TomlReader(this.s);

  final String s;
  int i = 0;

  int get _line => '\n'.allMatches(s.substring(0, i)).length + 1;

  FormatException _error(String message) =>
      FormatException('REUSE.toml line $_line: $message');

  String? get _peek => i < s.length ? s[i] : null;

  bool _at(String text) => s.startsWith(text, i);

  /// Skips spaces and tabs, and also line ends and comments if
  /// [lineEnds] is set.
  void _skip({bool lineEnds = false}) {
    while (i < s.length) {
      final c = s[i];
      if (c == ' ' || c == '\t' || (lineEnds && (c == '\n' || c == '\r'))) {
        i++;
      } else if (lineEnds && c == '#') {
        while (i < s.length && s[i] != '\n') {
          i++;
        }
      } else {
        return;
      }
    }
  }

  void _endOfLine() {
    _skip();
    if (_peek == '#') {
      while (i < s.length && s[i] != '\n') {
        i++;
      }
    }
    if (_peek == '\r') i++;
    if (_peek != null && _peek != '\n') throw _error('expected a line end');
  }

  List<_Table> read() {
    final tables = <_Table>[];
    var current = _Table('', 1, isArray: false);
    tables.add(current);
    while (true) {
      _skip(lineEnds: true);
      if (_peek == null) return tables;
      if (_at('[')) {
        final line = _line;
        final isArray = _at('[[');
        i += isArray ? 2 : 1;
        final close = isArray ? ']]' : ']';
        final end = s.indexOf(close, i);
        if (end < 0) throw _error('unterminated table header');
        current = _Table(s.substring(i, end).trim(), line, isArray: isArray);
        tables.add(current);
        i = end + close.length;
        _endOfLine();
        continue;
      }
      final key = _key();
      _skip();
      if (_peek != '=') throw _error('expected "=" after $key');
      i++;
      _skip();
      current.values[key] = _value();
      _endOfLine();
    }
  }

  String _key() {
    if (_peek == '"' || _peek == "'") return _string();
    final start = i;
    while (i < s.length && RegExp('[A-Za-z0-9_-]').hasMatch(s[i])) {
      i++;
    }
    if (i == start) throw _error('expected a key');
    return s.substring(start, i);
  }

  Object? _value() {
    if (_peek == '"' || _peek == "'") return _string();
    if (_peek == '[') {
      i++;
      final items = <Object?>[];
      while (true) {
        _skip(lineEnds: true);
        if (_peek == ']') {
          i++;
          return items;
        }
        items.add(_value());
        _skip(lineEnds: true);
        if (_peek == ',') {
          i++;
        } else if (_peek != ']') {
          throw _error('expected "," or "]" in an array');
        }
      }
    }
    final start = i;
    while (i < s.length && !' \t\r\n,]#'.contains(s[i])) {
      i++;
    }
    if (i == start) throw _error('expected a value');
    return s.substring(start, i);
  }

  String _string() {
    final quote = s[i];
    if (_at(quote * 3)) throw _error('multi-line strings are not supported');
    i++;
    final buffer = StringBuffer();
    while (i < s.length && s[i] != quote) {
      if (s[i] == '\n') throw _error('unterminated string');
      if (quote == '"' && s[i] == r'\' && i + 1 < s.length) {
        i++;
        buffer.write(switch (s[i]) {
          'n' => '\n',
          't' => '\t',
          final c => c,
        });
      } else {
        buffer.write(s[i]);
      }
      i++;
    }
    if (i >= s.length) throw _error('unterminated string');
    i++;
    return buffer.toString();
  }
}
