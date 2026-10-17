// Original code, not ported from Chart.js: a Dart lexer for the port checks.

/// A small Dart lexer for the port checks of porting-flow.md section 4.
///
/// It finds comments and string literals, so that the checks see only code.
/// It does not parse Dart. Only tool 3 resolves types with `package:analyzer`,
/// for the interpolation rule.
library;

/// A comment in a Dart file.
final class Comment {
  /// A comment from [start] to [end] (exclusive) that starts on [line].
  const Comment(this.start, this.end, this.line, this.text);

  /// The offset of the first `/`.
  final int start;

  /// The offset after the comment.
  final int end;

  /// The 1-based line of [start].
  final int line;

  /// The comment text, with the `//` or `/*`, without a line terminator.
  final String text;

  /// Whether this is a `//` comment (also a `///` comment).
  bool get isLineComment => text.startsWith('//');
}

/// A string literal in a Dart file.
final class StringLiteral {
  /// A literal from [start] to [end] with the content from [contentStart]
  /// to [contentEnd].
  const StringLiteral({
    required this.start,
    required this.end,
    required this.contentStart,
    required this.contentEnd,
    required this.nested,
  });

  /// The offset of the opening quote, or of the `r` of a raw string.
  final int start;

  /// The offset after the closing quote.
  final int end;

  /// The offset after the opening quote.
  final int contentStart;

  /// The offset of the closing quote.
  final int contentEnd;

  /// Whether the literal is inside a string interpolation.
  final bool nested;
}

/// An `import` or `export` directive.
final class Directive {
  /// A directive on [line] with the URIs [uris] and the import [prefix].
  const Directive(this.keyword, this.uris, this.line, {this.prefix});

  /// `import` or `export`.
  final String keyword;

  /// The URI, then the URIs of the `if (...)` configurations.
  final List<String> uris;

  /// The 1-based line of the keyword.
  final int line;

  /// The prefix of an `import ... as <prefix>` directive, or null.
  final String? prefix;
}

/// A Dart file, split into code, comments and string literals.
final class DartSource {
  /// Scans [text].
  factory DartSource(String text) {
    final scanner = _Scanner(text)..scan();
    return DartSource._(
      text,
      String.fromCharCodes(scanner.out),
      List.unmodifiable(scanner.comments),
      List.unmodifiable(scanner.strings),
      scanner.lineStarts,
    );
  }

  DartSource._(
    this.text,
    this.code,
    this.comments,
    this.strings,
    this._lineStarts,
  );

  /// The file text.
  final String text;

  /// [text] with the characters of comments and of string contents replaced
  /// by spaces. Line terminators stay, so offsets and lines do not change.
  /// The code of `${...}` interpolations stays too.
  final String code;

  /// The comments, in source order.
  final List<Comment> comments;

  /// The string literals, in the order in which they end.
  final List<StringLiteral> strings;

  final List<int> _lineStarts;

  /// The lines of [text], without line terminators.
  late final List<String> lines = [
    for (var i = 0; i < _lineStarts.length; i++)
      _stripCr(
        text.substring(
          _lineStarts[i],
          i + 1 < _lineStarts.length ? _lineStarts[i + 1] - 1 : text.length,
        ),
      ),
  ];

  /// The 1-based line that contains [offset].
  int lineOf(int offset) => _lineOf(_lineStarts, offset);

  /// The content of [literal] as written, without escapes resolved.
  String contentOf(StringLiteral literal) =>
      text.substring(literal.contentStart, literal.contentEnd);

  /// The `import` and `export` directives.
  late final List<Directive> directives = _directives();

  /// The selector of the library `@TestOn` annotation, or null.
  late final String? testOn = _testOn();

  /// Whether the file is a test library with `@TestOn('vm')`.
  bool get isVmOnly => testOn?.trim() == 'vm';

  List<Directive> _directives() {
    final result = <Directive>[];
    final keyword = RegExp(r'^[ \t]*(import|export)\b', multiLine: true);
    for (final match in keyword.allMatches(code)) {
      final semicolon = code.indexOf(';', match.end);
      if (semicolon < 0) continue;
      final uris = <String>[];
      for (final literal in strings) {
        if (literal.nested ||
            literal.start < match.end ||
            literal.end > semicolon) {
          continue;
        }
        // Strings in parentheses are the values of `if (a == 'b')` tests.
        final before = code.substring(match.end, literal.start);
        final depth =
            '('.allMatches(before).length - ')'.allMatches(before).length;
        if (depth == 0) uris.add(contentOf(literal));
      }
      if (uris.isNotEmpty) {
        final prefix = _importPrefix.firstMatch(
          code.substring(match.end, semicolon),
        );
        result.add(
          Directive(
            match.group(1)!,
            uris,
            lineOf(match.start),
            prefix: match.group(1) == 'import' ? prefix?.group(1) : null,
          ),
        );
      }
    }
    return result;
  }

  String? _testOn() {
    final match = RegExp(r'@TestOn\s*\(').firstMatch(code);
    if (match == null) return null;
    for (final literal in strings) {
      if (!literal.nested && literal.start >= match.end) {
        return contentOf(literal);
      }
    }
    return null;
  }
}

/// The `as <prefix>` part of an import, in code without string contents.
final RegExp _importPrefix = RegExp(r'(?<![\w$])as\s+([A-Za-z_$][\w$]*)');

int _lineOf(List<int> lineStarts, int offset) {
  var low = 0;
  var high = lineStarts.length - 1;
  while (low < high) {
    final mid = (low + high + 1) >> 1;
    if (lineStarts[mid] <= offset) {
      low = mid;
    } else {
      high = mid - 1;
    }
  }
  return low + 1;
}

String _stripCr(String line) =>
    line.endsWith('\r') ? line.substring(0, line.length - 1) : line;

const int _newline = 0x0A;
const int _carriageReturn = 0x0D;
const int _space = 0x20;
const int _quote = 0x22;
const int _dollar = 0x24;
const int _apostrophe = 0x27;
const int _star = 0x2A;
const int _slash = 0x2F;
const int _backslash = 0x5C;
const int _upperR = 0x52;
const int _lowerR = 0x72;
const int _openBrace = 0x7B;
const int _closeBrace = 0x7D;

bool _isIdentifierStart(int c) =>
    (c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A) || c == 0x5F;

bool _isIdentifierPart(int c) =>
    _isIdentifierStart(c) || (c >= 0x30 && c <= 0x39);

/// One level of the scanner: code (top level or in `${...}`) or a string.
final class _Frame {
  _Frame.code({required this.interpolation})
    : quote = 0,
      triple = false,
      raw = false,
      start = 0,
      contentStart = 0;

  _Frame.string({
    required this.quote,
    required this.triple,
    required this.raw,
    required this.start,
    required this.contentStart,
  }) : interpolation = false;

  final bool interpolation;
  final int quote;
  final bool triple;
  final bool raw;
  final int start;
  final int contentStart;
  int braces = 0;

  bool get isCode => quote == 0;
}

final class _Scanner {
  _Scanner(this.s) : out = List<int>.of(s.codeUnits);

  final String s;
  final List<int> out;
  final List<Comment> comments = [];
  final List<StringLiteral> strings = [];
  final List<int> lineStarts = [0];

  void _blank(int from, int to) {
    for (var k = from; k < to && k < out.length; k++) {
      if (out[k] != _newline && out[k] != _carriageReturn) out[k] = _space;
    }
  }

  int _at(int i) => i < s.length ? s.codeUnitAt(i) : -1;

  bool _isTripleAt(int i, int quote) =>
      _at(i) == quote && _at(i + 1) == quote && _at(i + 2) == quote;

  void scan() {
    for (var k = 0; k < s.length; k++) {
      if (s.codeUnitAt(k) == _newline) lineStarts.add(k + 1);
    }
    final stack = [_Frame.code(interpolation: false)];
    var i = 0;
    while (i < s.length) {
      final frame = stack.last;
      final c = s.codeUnitAt(i);
      if (frame.isCode) {
        i = _code(stack, frame, c, i);
      } else {
        i = _string(stack, frame, c, i);
      }
    }
    // Unterminated strings end at the end of the file.
    while (stack.length > 1) {
      final frame = stack.removeLast();
      if (!frame.isCode) _addString(frame, s.length, s.length, stack.length);
    }
  }

  int _code(List<_Frame> stack, _Frame frame, int c, int i) {
    if (c == _slash && _at(i + 1) == _slash) {
      var end = i;
      while (end < s.length && s.codeUnitAt(end) != _newline) {
        end++;
      }
      _addComment(i, end);
      return end;
    }
    if (c == _slash && _at(i + 1) == _star) {
      var depth = 1;
      var end = i + 2;
      while (end < s.length && depth > 0) {
        if (_at(end) == _slash && _at(end + 1) == _star) {
          depth++;
          end += 2;
        } else if (_at(end) == _star && _at(end + 1) == _slash) {
          depth--;
          end += 2;
        } else {
          end++;
        }
      }
      _addComment(i, end);
      return end;
    }
    final raw =
        (c == _lowerR || c == _upperR) &&
        (_at(i + 1) == _quote || _at(i + 1) == _apostrophe) &&
        (i == 0 || !_isIdentifierPart(s.codeUnitAt(i - 1)));
    if (raw || c == _quote || c == _apostrophe) {
      final quoteAt = raw ? i + 1 : i;
      final quote = s.codeUnitAt(quoteAt);
      final triple = _isTripleAt(quoteAt, quote);
      final contentStart = quoteAt + (triple ? 3 : 1);
      stack.add(
        _Frame.string(
          quote: quote,
          triple: triple,
          raw: raw,
          start: i,
          contentStart: contentStart,
        ),
      );
      return contentStart;
    }
    if (frame.interpolation) {
      if (c == _openBrace) {
        frame.braces++;
      } else if (c == _closeBrace) {
        if (frame.braces == 0) {
          stack.removeLast();
          return i + 1;
        }
        frame.braces--;
      }
    }
    return i + 1;
  }

  int _string(List<_Frame> stack, _Frame frame, int c, int i) {
    if (!frame.raw && c == _backslash) {
      _blank(i, i + 2);
      return i + 2;
    }
    if (c == frame.quote && (!frame.triple || _isTripleAt(i, c))) {
      final end = i + (frame.triple ? 3 : 1);
      stack.removeLast();
      _addString(frame, i, end, stack.length);
      return end;
    }
    if (!frame.triple && c == _newline) {
      // An unterminated one-line string ends at the line end.
      stack.removeLast();
      _addString(frame, i, i, stack.length);
      return i;
    }
    if (!frame.raw && c == _dollar) {
      final next = _at(i + 1);
      if (next == _openBrace) {
        stack.add(_Frame.code(interpolation: true));
        return i + 2;
      }
      if (_isIdentifierStart(next)) {
        var end = i + 1;
        while (end < s.length && _isIdentifierPart(s.codeUnitAt(end))) {
          end++;
        }
        return end;
      }
    }
    _blank(i, i + 1);
    return i + 1;
  }

  void _addComment(int start, int end) {
    final line = _lineOf(lineStarts, start);
    comments.add(Comment(start, end, line, _stripCr(s.substring(start, end))));
    _blank(start, end);
  }

  void _addString(_Frame frame, int contentEnd, int end, int depth) {
    strings.add(
      StringLiteral(
        start: frame.start,
        end: end,
        contentStart: frame.contentStart,
        contentEnd: contentEnd,
        // The stack without the string frame: the top level is depth 1.
        nested: depth > 1,
      ),
    );
  }
}
