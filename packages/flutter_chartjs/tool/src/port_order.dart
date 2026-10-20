// Original code, not ported from Chart.js: the port-order helper, tool 8.

/// The port-order helper of porting-flow.md section 4, tool 8.
///
/// It reads the upstream modules of the Chart.js pin (the `.js` and `.ts`
/// files under `src/` of `third_party/Chart.js`), their imports and the port
/// state of each module:
/// - A Dart file in `lib/` whose `// Ported from Chart.js` header line names
///   the module, at the Dart path that `tool/port_sources.yaml` maps the
///   module to (AGENTS.md rule 2).
/// - The status column of the module row in `doc/parity.md`
///   (porting-flow.md section 1 step 7).
///
/// A module is done when its status is `ported`, `replaced`, `distributed`
/// or `n/a`. A module is in progress when it is not done, and a Dart file
/// names it or its status is `in progress` or `partial`. A module that is
/// not started is ready when each value import is done. A `partial` module
/// satisfies a named import of a symbol that its status lists.
///
/// An import of a name through a module that re-exports the name (an
/// `index` file) is an import of the module that declares the name. A
/// type-only import does not block a module (Chart.js ADR 0003,
/// porting-flow.md 2.4): `import type`, `export type`, a `type` specifier,
/// each import of a `.d.ts` file, each import in a `.d.ts` file, and a JSDoc
/// `import()` type. The helper lists these types as the interfaces that the
/// module needs, each with the file of `lib/src/types/` that declares it.
/// Modules that import each other are ready together when no other import
/// blocks them.
///
/// Errors (the `--check` mode fails):
/// - a module that the helper cannot read: an unterminated string, comment,
///   template or regular expression, a `{` without its `}`, or an `import`
///   or `export` form that the helper does not know;
/// - a relative import that does not resolve to a module of `src/`;
/// - a `// Ported from` or backport line of a `lib/` file that does not
///   match the header grammar (porting-flow.md 4, tool 2);
/// - a `parity.md` status that is not a value of porting-flow.md section 1
///   step 7.
///
/// Warnings: a module without a `parity.md` row, a row of a path that is
/// not a module, a second row of a module, a `partial` status without
/// symbols, a status that needs a Dart file without one, and a header that
/// names a path that is not a module or that is not at the mapped path.
library;

import 'dart:convert';
import 'dart:io';

import 'check_support.dart';
import 'headers.dart';
import 'port_headers.dart';

/// The name of the helper in its output.
const String portOrderName = 'port:next';

/// The phases of porting-flow.md section 5, by number.
const Map<int, String> phaseNames = {
  1: 'Decisions, minimum tooling, pilot',
  2: 'JS runtime, helpers, defaults',
  3: 'Canvas, text, platform, harness',
  4: 'Elements',
  5: 'Core',
  6: 'Scales',
  7: 'Controllers',
  8: 'Plugins',
  9: 'Flutter API and release',
};

/// The phase of each upstream module (porting-flow.md section 5).
///
/// The first rule whose path is the module path, or a directory (with a
/// final `/`) that contains the module, gives the phase. The phase table
/// names no phase for the entry points `src/index.ts`, `src/index.umd.ts`
/// and `src/types.ts`. They re-export the modules of phases 5 to 8, so the
/// last rule gives them phase 9, with the public API.
const List<(String, int)> phaseRules = [
  ('src/helpers/helpers.math.ts', 1),
  ('src/types/geometric.d.ts', 1),
  ('src/helpers/helpers.canvas.ts', 3),
  ('src/helpers/helpers.dom.ts', 3),
  ('src/helpers/helpers.rtl.ts', 3),
  ('src/helpers/index.ts', 3),
  ('src/core/core.defaults.js', 2),
  ('src/core/core.animations.defaults.js', 2),
  ('src/core/core.layouts.defaults.js', 2),
  ('src/core/core.scale.defaults.js', 2),
  ('src/core/core.ticks.js', 2),
  ('src/core/core.element.ts', 4),
  ('src/helpers/', 2),
  ('src/types/', 2),
  ('src/platform/', 3),
  ('src/elements/', 4),
  ('src/core/', 5),
  ('src/scales/', 6),
  ('src/controllers/', 7),
  ('src/plugins/', 8),
  ('src/', 9),
];

/// The phase of the module [path] by [phaseRules], or the last phase when
/// no rule covers it.
int phaseOf(String path) {
  for (final (rule, phase) in phaseRules) {
    if (rule.endsWith('/') ? path.startsWith(rule) : path == rule) {
      return phase;
    }
  }
  return phaseNames.keys.last;
}

/// The heading of [phase]: its number and its name.
String phaseTitle(int phase) {
  final name = phaseNames[phase];
  return name == null ? 'Phase $phase' : 'Phase $phase ($name)';
}

// ---------------------------------------------------------------------------
// The module reader.

/// A part of an upstream module that the helper cannot read.
final class ModuleSyntaxError implements Exception {
  /// An error on [line] of the module.
  const ModuleSyntaxError(this.line, this.message);

  /// The 1-based line.
  final int line;

  /// What the helper cannot read.
  final String message;

  @override
  String toString() => 'line $line: $message';
}

/// One name of an import or a re-export.
final class ImportBinding {
  /// The name [imported] of the target module, bound to [local].
  const ImportBinding(this.imported, this.local, {this.typeOnly = false});

  /// The name in the target module: `default`, `*` for the namespace, or an
  /// exported name.
  final String imported;

  /// The name in the importing module (an import), or the exported name (a
  /// re-export).
  final String local;

  /// Whether the specifier has the `type` modifier.
  final bool typeOnly;
}

/// The form of a [ModuleImport].
enum ImportKind {
  /// `import ... from '<specifier>'` or `import '<specifier>'`.
  import,

  /// `export {...} from '<specifier>'` or `export * as name from`.
  reexport,

  /// `export * from '<specifier>'`.
  reexportAll,

  /// A JSDoc type `import('<specifier>').Name` in a comment.
  jsDoc,
}

/// One import, re-export or JSDoc `import()` type of an upstream module.
final class ModuleImport {
  /// An import of [specifier] on [line].
  const ModuleImport({
    required this.line,
    required this.specifier,
    required this.kind,
    required this.bindings,
    this.typeOnly = false,
  });

  /// The 1-based line of the `import` or `export` keyword.
  final int line;

  /// The module specifier, for example `../helpers/helpers.core.js`.
  final String specifier;

  /// The form of the statement.
  final ImportKind kind;

  /// The names. Empty for a side-effect import and for `export *`.
  final List<ImportBinding> bindings;

  /// Whether the statement is `import type` or `export type`, or a JSDoc
  /// type.
  final bool typeOnly;

  /// Whether the module needs all of the target: a side-effect import, a
  /// namespace import or `export *`.
  bool get needsAll =>
      kind == ImportKind.reexportAll ||
      (kind == ImportKind.import && bindings.isEmpty);
}

/// The imports and exports of one upstream module.
final class ModuleSyntax {
  /// The syntax of a module with [lines] lines.
  const ModuleSyntax({
    required this.imports,
    required this.localExports,
    required this.defaultName,
    required this.lines,
  });

  /// The imports, re-exports and JSDoc types, in source order.
  final List<ModuleImport> imports;

  /// The exports of the module's own bindings: the exported name and the
  /// local name. A declaration (`export class A`) maps `A` to `A`.
  final Map<String, String> localExports;

  /// The name of the default export: the class, the function or the
  /// identifier of `export default`, or null.
  final String? defaultName;

  /// The `wc -l` count: the number of line ends.
  final int lines;
}

/// Reads the imports and exports of the module [text]. Throws a
/// [ModuleSyntaxError].
ModuleSyntax parseModule(String text) {
  final lexer = _Lexer(text)..run();
  final parser = _Parser(lexer.tokens)..run();
  final jsDoc = <ModuleImport>[];
  for (final comment in lexer.comments) {
    for (final match in _jsDocImport.allMatches(comment.text)) {
      final before = comment.text.substring(0, match.start);
      final name = match[3] ?? '*';
      jsDoc.add(
        ModuleImport(
          line: comment.line + '\n'.allMatches(before).length,
          specifier: match[2]!,
          kind: ImportKind.jsDoc,
          bindings: [ImportBinding(name, name)],
          typeOnly: true,
        ),
      );
    }
  }
  // Both lists are in line order. Merge them, statements first on a line.
  final imports = <ModuleImport>[];
  var j = 0;
  for (final statement in parser.imports) {
    while (j < jsDoc.length && jsDoc[j].line < statement.line) {
      imports.add(jsDoc[j++]);
    }
    imports.add(statement);
  }
  imports.addAll(jsDoc.skip(j));
  return ModuleSyntax(
    imports: imports,
    localExports: parser.localExports,
    defaultName: parser.defaultName,
    lines: '\n'.allMatches(text).length,
  );
}

final RegExp _jsDocImport = RegExp(
  r'''import\(\s*(['"])([^'"\n]+)\1\s*\)(?:\s*\.\s*([A-Za-z_$][\w$]*))?''',
);

enum _Kind { word, string, punct, template, regex }

final class _Token {
  const _Token(this.kind, this.text, this.line, this.depth);

  final _Kind kind;

  /// The text, or the value of a string literal.
  final String text;

  final int line;

  /// The number of open `{` and `${` before the token.
  final int depth;

  bool isWord([String? word]) =>
      kind == _Kind.word && (word == null || text == word);

  bool isPunct(String punct) => kind == _Kind.punct && text == punct;
}

/// The last characters of the punctuators after which a `/` starts a
/// regular expression.
const String _regexAfterPunct = '(,=:[!&|?{};+-*%<>~^}';

/// The keywords after which a `/` starts a regular expression.
const Set<String> _regexAfterWords = {
  'return',
  'typeof',
  'instanceof',
  'in',
  'of',
  'new',
  'delete',
  'void',
  'throw',
  'case',
  'do',
  'else',
  'yield',
  'await',
};

bool _isSpace(int c) =>
    c == 0x20 ||
    c == 0x09 ||
    c == 0x0D ||
    c == 0x0B ||
    c == 0x0C ||
    c == 0xA0 ||
    c == 0xFEFF ||
    c == 0x2028 ||
    c == 0x2029;

bool _isWordChar(int c) =>
    (c >= 0x30 && c <= 0x39) ||
    (c >= 0x41 && c <= 0x5A) ||
    (c >= 0x61 && c <= 0x7A) ||
    c == 0x5F ||
    c == 0x24 ||
    (c >= 0x80 && !_isSpace(c));

/// A JavaScript and TypeScript tokenizer. It keeps words, string values and
/// punctuators, and skips the content of templates and regular expressions.
final class _Lexer {
  _Lexer(this.text);

  final String text;
  final List<_Token> tokens = [];
  final List<({int line, String text})> comments = [];
  int _pos = 0;
  int _line = 1;
  int _depth = 0;

  /// The depth of each open `${` of a template.
  final List<int> _templates = [];

  int _at(int offset) {
    final index = _pos + offset;
    return index < text.length ? text.codeUnitAt(index) : -1;
  }

  void _add(_Kind kind, String value, int line) =>
      tokens.add(_Token(kind, value, line, _depth));

  bool get _regexAllowed {
    if (tokens.isEmpty) return true;
    final last = tokens.last;
    return switch (last.kind) {
      _Kind.punct => _regexAfterPunct.contains(last.text[last.text.length - 1]),
      _Kind.word => _regexAfterWords.contains(last.text),
      _Kind.string || _Kind.template || _Kind.regex => false,
    };
  }

  void run() {
    if (text.startsWith('#!')) _lineComment();
    while (_pos < text.length) {
      final c = text.codeUnitAt(_pos);
      if (c == 0x0A) {
        _line++;
        _pos++;
      } else if (_isSpace(c)) {
        _pos++;
      } else if (c == 0x2F && _at(1) == 0x2F) {
        _lineComment();
      } else if (c == 0x2F && _at(1) == 0x2A) {
        _blockComment();
      } else if (c == 0x2F && _regexAllowed) {
        _regex();
      } else if (c == 0x27 || c == 0x22) {
        _string(c);
      } else if (c == 0x60) {
        _pos++;
        _template(_line);
      } else if (_isWordChar(c)) {
        final start = _pos;
        while (_pos < text.length && _isWordChar(text.codeUnitAt(_pos))) {
          _pos++;
        }
        _add(_Kind.word, text.substring(start, _pos), _line);
      } else if (c == 0x7B) {
        _add(_Kind.punct, '{', _line);
        _depth++;
        _pos++;
      } else if (c == 0x7D) {
        _pos++;
        if (_templates.isNotEmpty && _templates.last == _depth) {
          _templates.removeLast();
          _depth--;
          _template(_line);
        } else {
          _depth--;
          if (_depth < 0) {
            throw ModuleSyntaxError(_line, 'a "}" without its "{".');
          }
          _add(_Kind.punct, '}', _line);
        }
      } else {
        _add(_Kind.punct, String.fromCharCode(c), _line);
        _pos++;
      }
    }
    if (_templates.isNotEmpty) {
      throw ModuleSyntaxError(_line, 'an unterminated template literal.');
    }
    if (_depth != 0) {
      throw ModuleSyntaxError(_line, 'a "{" without its "}".');
    }
  }

  void _lineComment() {
    final start = _pos;
    var end = text.indexOf('\n', _pos);
    if (end < 0) end = text.length;
    comments.add((line: _line, text: text.substring(start, end)));
    _pos = end;
  }

  void _blockComment() {
    final end = text.indexOf('*/', _pos + 2);
    if (end < 0) throw ModuleSyntaxError(_line, 'an unterminated comment.');
    final comment = text.substring(_pos, end + 2);
    comments.add((line: _line, text: comment));
    _line += '\n'.allMatches(comment).length;
    _pos = end + 2;
  }

  void _string(int quote) {
    final line = _line;
    final value = StringBuffer();
    _pos++;
    while (true) {
      if (_pos >= text.length) {
        throw ModuleSyntaxError(line, 'an unterminated string literal.');
      }
      final c = text.codeUnitAt(_pos);
      if (c == 0x5C && _pos + 1 < text.length) {
        final next = text.codeUnitAt(_pos + 1);
        // A line continuation, also after a CR.
        final crlf = next == 0x0D && _at(2) == 0x0A;
        if (next == 0x0A || crlf) _line++;
        value.writeCharCode(next);
        _pos += crlf ? 3 : 2;
      } else if (c == quote) {
        _pos++;
        break;
      } else if (c == 0x0A) {
        throw ModuleSyntaxError(line, 'an unterminated string literal.');
      } else {
        value.writeCharCode(c);
        _pos++;
      }
    }
    _add(_Kind.string, value.toString(), line);
  }

  /// Reads a template from after its "`" or "}" up to its "`" or its next
  /// `${`.
  void _template(int line) {
    while (true) {
      if (_pos >= text.length) {
        throw ModuleSyntaxError(line, 'an unterminated template literal.');
      }
      final c = text.codeUnitAt(_pos);
      if (c == 0x5C) {
        if (_at(1) == 0x0A) _line++;
        _pos += 2;
      } else if (c == 0x60) {
        _pos++;
        _add(_Kind.template, '`', line);
        return;
      } else if (c == 0x24 && _at(1) == 0x7B) {
        _pos += 2;
        _add(_Kind.punct, r'${', _line);
        _depth++;
        _templates.add(_depth);
        return;
      } else {
        if (c == 0x0A) _line++;
        _pos++;
      }
    }
  }

  void _regex() {
    final line = _line;
    var inClass = false;
    _pos++;
    while (true) {
      if (_pos >= text.length || text.codeUnitAt(_pos) == 0x0A) {
        throw ModuleSyntaxError(line, 'an unterminated regular expression.');
      }
      final c = text.codeUnitAt(_pos);
      if (c == 0x5C) {
        _pos += 2;
        continue;
      }
      _pos++;
      if (c == 0x5B) {
        inClass = true;
      } else if (c == 0x5D) {
        inClass = false;
      } else if (c == 0x2F && !inClass) {
        break;
      }
    }
    while (_pos < text.length && _isWordChar(text.codeUnitAt(_pos))) {
      _pos++;
    }
    _add(_Kind.regex, '/', line);
  }
}

/// Reads the top-level `import` and `export` statements of the tokens.
final class _Parser {
  _Parser(this.tokens);

  final List<_Token> tokens;
  final List<ModuleImport> imports = [];
  final Map<String, String> localExports = {};
  String? defaultName;
  int _i = 0;

  _Token? _peek([int offset = 0]) {
    final index = _i + offset;
    return index < tokens.length ? tokens[index] : null;
  }

  bool _wordAt(int offset, [String? word]) =>
      _peek(offset)?.isWord(word) ?? false;

  bool _punctAt(int offset, String punct) =>
      _peek(offset)?.isPunct(punct) ?? false;

  bool _stringAt(int offset) => _peek(offset)?.kind == _Kind.string;

  Never _fail(int line, String form) => throw ModuleSyntaxError(
    line,
    'an $form form that the helper does not read.',
  );

  void run() {
    while (_i < tokens.length) {
      final token = tokens[_i];
      final afterDot = _i > 0 && tokens[_i - 1].isPunct('.');
      if (token.kind == _Kind.word && token.depth == 0 && !afterDot) {
        if (token.text == 'import' && !_punctAt(1, '(') && !_punctAt(1, '.')) {
          _import();
          continue;
        }
        if (token.text == 'export') {
          _export();
          continue;
        }
      }
      _i++;
    }
  }

  String _name(int line, String form) {
    final token = _peek();
    if (token == null ||
        (token.kind != _Kind.word && token.kind != _Kind.string)) {
      _fail(line, form);
    }
    _i++;
    return token.text;
  }

  void _expectWord(String word, int line, String form) {
    if (!_wordAt(0, word)) _fail(line, form);
    _i++;
  }

  String _specifier(int line, String form) {
    _expectWord('from', line, form);
    if (!_stringAt(0)) _fail(line, form);
    return tokens[_i++].text;
  }

  void _import() {
    const form = 'import';
    final line = tokens[_i].line;
    _i++;
    if (_stringAt(0)) {
      imports.add(
        ModuleImport(
          line: line,
          specifier: tokens[_i++].text,
          kind: ImportKind.import,
          bindings: const [],
        ),
      );
      return;
    }
    var typeOnly = false;
    if (_wordAt(0, 'type') && !_punctAt(1, ',') && !_wordAt(1, 'from')) {
      typeOnly = true;
      _i++;
    }
    final bindings = <ImportBinding>[];
    if (_wordAt(0) && !(_wordAt(0, 'from') && _stringAt(1))) {
      bindings.add(ImportBinding('default', tokens[_i++].text));
      if (_punctAt(0, ',')) _i++;
    }
    if (_punctAt(0, '*')) {
      _i++;
      _expectWord('as', line, form);
      bindings.add(ImportBinding('*', _name(line, form)));
    } else if (_punctAt(0, '{')) {
      bindings.addAll(_specifiers(line, form));
    }
    if (bindings.isEmpty) _fail(line, form);
    imports.add(
      ModuleImport(
        line: line,
        specifier: _specifier(line, form),
        kind: ImportKind.import,
        bindings: bindings,
        typeOnly: typeOnly,
      ),
    );
  }

  /// Reads `{a, b as c, type D}` from its `{`.
  List<ImportBinding> _specifiers(int line, String form) {
    _i++;
    final result = <ImportBinding>[];
    while (!_punctAt(0, '}')) {
      var typeOnly = false;
      final next = _peek(1);
      if (_wordAt(0, 'type') &&
          next != null &&
          (next.kind == _Kind.string ||
              (next.kind == _Kind.word && next.text != 'as'))) {
        typeOnly = true;
        _i++;
      }
      final name = _name(line, form);
      var local = name;
      if (_wordAt(0, 'as')) {
        _i++;
        local = _name(line, form);
      }
      result.add(ImportBinding(name, local, typeOnly: typeOnly));
      if (_punctAt(0, ',')) {
        _i++;
      } else if (!_punctAt(0, '}')) {
        _fail(line, form);
      }
    }
    _i++;
    return result;
  }

  void _export() {
    const form = 'export';
    final line = tokens[_i].line;
    _i++;
    var typeOnly = false;
    if (_wordAt(0, 'type') && (_punctAt(1, '{') || _punctAt(1, '*'))) {
      typeOnly = true;
      _i++;
    }
    if (_punctAt(0, '*')) {
      _i++;
      String? name;
      if (_wordAt(0, 'as')) {
        _i++;
        name = _name(line, form);
      }
      imports.add(
        ModuleImport(
          line: line,
          specifier: _specifier(line, form),
          kind: name == null ? ImportKind.reexportAll : ImportKind.reexport,
          bindings: [if (name != null) ImportBinding('*', name)],
          typeOnly: typeOnly,
        ),
      );
      return;
    }
    if (_punctAt(0, '{')) {
      final bindings = _specifiers(line, form);
      if (_wordAt(0, 'from') && _stringAt(1)) {
        imports.add(
          ModuleImport(
            line: line,
            specifier: _specifier(line, form),
            kind: ImportKind.reexport,
            bindings: bindings,
            typeOnly: typeOnly,
          ),
        );
      } else {
        for (final binding in bindings) {
          localExports[binding.local] = binding.imported;
        }
      }
      return;
    }
    _declaration(line);
  }

  /// Reads `export <declaration>` after its `export`.
  void _declaration(int line) {
    const form = 'export';
    if (_wordAt(0, 'declare')) _i++;
    final token = _peek();
    if (token != null && token.isPunct('=')) {
      _i++;
      return;
    }
    if (token == null || token.kind != _Kind.word) _fail(line, form);
    _i++;
    switch (token.text) {
      case 'default':
        localExports['default'] = 'default';
        defaultName = _defaultName();
      case 'const' || 'let' || 'var':
        if (_wordAt(0, 'enum')) _i++;
        _declared();
      case 'function':
        if (_punctAt(0, '*')) _i++;
        _declared();
      case 'async':
        _expectWord('function', line, form);
        if (_punctAt(0, '*')) _i++;
        _declared();
      case 'abstract':
        _expectWord('class', line, form);
        _declared();
      case 'class' ||
          'interface' ||
          'type' ||
          'enum' ||
          'namespace' ||
          'module':
        _declared();
      case 'as':
        break;
      default:
        _fail(line, '"export ${token.text}"');
    }
  }

  /// Records the declared name at the current token, if it is a name.
  void _declared() {
    if (_wordAt(0)) {
      final name = tokens[_i++].text;
      localExports[name] = name;
    }
  }

  /// The name of the default export after `export default`, or null.
  String? _defaultName() {
    if (_wordAt(0, 'abstract')) _i++;
    if (_wordAt(0, 'async') && _wordAt(1, 'function')) _i++;
    if (_wordAt(0, 'class') || _wordAt(0, 'function')) {
      _i++;
      if (_punctAt(0, '*')) _i++;
      if (_wordAt(0) && !_wordAt(0, 'extends') && !_wordAt(0, 'implements')) {
        return tokens[_i++].text;
      }
      return null;
    }
    final token = _peek();
    final next = _peek(1);
    if (token != null &&
        token.kind == _Kind.word &&
        (next == null || next.isPunct(';') || next.line != token.line)) {
      _i++;
      localExports['default'] = token.text;
      return token.text;
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// The port state.

/// The state of a `parity.md` status (porting-flow.md section 1 step 7).
enum ParityState {
  /// `not started`.
  notStarted,

  /// `in progress`.
  inProgress,

  /// `partial: <symbols>`.
  partial,

  /// `ported`, `replaced`, `distributed` or `n/a`.
  done,

  /// Another text.
  unknown,
}

/// The [ParityState] of the `parity.md` [status], and the symbols of a
/// `partial` status: the names in backticks up to the first `. `, `; ` or
/// ` (`.
({ParityState state, Set<String> symbols}) classifyStatus(String status) {
  final text = status.trim();
  final lower = text.toLowerCase();
  bool starts(String value) => RegExp(
    '^${RegExp.escape(value)}(?![\\w/-])',
  ).hasMatch(lower);
  if (starts('not started')) {
    return (state: ParityState.notStarted, symbols: const {});
  }
  if (starts('in progress')) {
    return (state: ParityState.inProgress, symbols: const {});
  }
  if (starts('partial')) {
    var list = text.substring('partial'.length);
    final end = RegExp(r'\.\s|;\s|\s\(').firstMatch(list);
    if (end != null) list = list.substring(0, end.start);
    return (
      state: ParityState.partial,
      symbols: {
        for (final match in RegExp(r'`([A-Za-z_$][\w$]*)`').allMatches(list))
          match[1]!,
      },
    );
  }
  for (final value in const ['ported', 'replaced', 'distributed', 'n/a']) {
    if (starts(value)) return (state: ParityState.done, symbols: const {});
  }
  return (state: ParityState.unknown, symbols: const {});
}

/// One row of a `parity.md` table of the upstream sources.
final class ParityRow {
  /// The row of [path] on [line] with its [status].
  const ParityRow(this.path, this.line, this.status);

  /// The project-relative upstream path, for example `src/core/core.scale.js`.
  final String path;

  /// The 1-based line.
  final int line;

  /// The text of the status column.
  final String status;
}

/// The rows of the tables in [markdown] whose first cell links an upstream
/// path to [blobPrefix] plus that path.
List<ParityRow> parseParityRows(String markdown, String blobPrefix) {
  final row = RegExp(r'^\|\s*\[`([^`]+)`\]\(([^)\s]*)\)\s*\|(.*)$');
  final cell = RegExp(r'(?<!\\)\|');
  final rows = <ParityRow>[];
  final lines = const LineSplitter().convert(markdown);
  for (var i = 0; i < lines.length; i++) {
    final match = row.firstMatch(lines[i].trim());
    if (match == null || match[2] != '$blobPrefix${match[1]}') continue;
    // The text after the last `|` of the row is not a cell.
    final cells = match[3]!.split(cell);
    if (cells.length > 1) cells.removeLast();
    rows.add(ParityRow(match[1]!, i + 1, cells.last));
  }
  return rows;
}

/// The names that the Dart files [files] declare at the start of a line:
/// classes, mixins, enums, typedefs and extension types. Maps each name to
/// the path of its first file.
Map<String, String> declaredTypes(Map<String, String> files) {
  final declaration = RegExp(
    r'^(?:(?:abstract|base|final|interface|sealed|mixin)\s+)*'
    r'(?:class|mixin|enum|typedef|extension\s+type)\s+([A-Za-z_$][\w$]*)',
    multiLine: true,
  );
  final result = <String, String>{};
  for (final MapEntry(key: path, value: text) in files.entries) {
    for (final match in declaration.allMatches(text)) {
      result.putIfAbsent(match[1]!, () => path);
    }
  }
  return result;
}

// ---------------------------------------------------------------------------
// The report.

/// What a [Dependency] names.
enum DependencyKind {
  /// A module of `src/`.
  module,

  /// A package, for example `@kurkle/color`.
  package,

  /// A relative specifier that does not resolve.
  unresolved,
}

/// A value import of a module, by the module that declares the names.
final class Dependency {
  /// A dependency on [target].
  Dependency(this.target, this.kind);

  /// The module path, the package name, or the specifier that does not
  /// resolve.
  final String target;

  /// What [target] names.
  final DependencyKind kind;

  /// The imported names. Empty when the module needs all of [target].
  final Set<String> names = {};

  /// Whether the module needs all of [target]: a side-effect import, a
  /// namespace import or `export *`.
  bool needsAll = false;
}

/// A type that a module imports for its types only (Chart.js ADR 0003).
final class Interface {
  /// The type [name] of the module [from].
  const Interface(this.name, this.from, this.declaredIn);

  /// The type name.
  final String name;

  /// The upstream module (or package) that declares the type.
  final String from;

  /// The package-relative Dart file of `lib/src/types/` that declares
  /// [name], or null.
  final String? declaredIn;
}

/// The port category of a module.
enum ModuleCategory {
  /// The status is `ported`, `replaced`, `distributed` or `n/a`.
  done,

  /// A Dart file names the module, or its status is `in progress` or
  /// `partial`.
  inProgress,

  /// Not started, and each value import is done.
  ready,

  /// Not started, and a value import is not done.
  blocked,
}

/// The report of one upstream module.
final class ModuleReport {
  /// The report of the module [path].
  ModuleReport({
    required this.path,
    required this.lines,
    required this.phase,
    required this.parityStatus,
    required this.dartFile,
    required this.dependencies,
    required this.interfaces,
    required this.error,
  });

  /// The project-relative path, for example `src/core/core.scale.js`.
  final String path;

  /// The `wc -l` count of the upstream file.
  final int lines;

  /// The phase of porting-flow.md section 5 ([phaseOf]).
  final int phase;

  /// The `parity.md` status, or null without a row.
  final String? parityStatus;

  /// The package-relative Dart file whose header names the module, or null.
  final String? dartFile;

  /// The value imports, by target.
  final List<Dependency> dependencies;

  /// The types of the type-only imports.
  final List<Interface> interfaces;

  /// Why the helper cannot read the module, or null.
  final String? error;

  /// The category.
  ModuleCategory category = ModuleCategory.blocked;

  /// The value imports that are not done.
  List<Dependency> missing = const [];

  /// The other modules of an import cycle that are ready together with
  /// this module.
  List<String> group = const [];

  /// The number of modules that are not done and miss this module.
  int neededBy = 0;
}

/// The result of [computePortOrder].
final class PortOrder {
  /// The report of the upstream [project] at [version].
  const PortOrder({
    required this.project,
    required this.version,
    required this.sourceDirectory,
    required this.modules,
    required this.findings,
    required this.files,
  });

  /// The project, `Chart.js`.
  final String project;

  /// The pinned version, for example `v4.5.1`.
  final String version;

  /// The repository-relative directory of the modules.
  final String sourceDirectory;

  /// One report for each module, sorted by phase and path.
  final List<ModuleReport> modules;

  /// The errors and warnings.
  final List<Finding> findings;

  /// The number of files that the helper read: modules and Dart files.
  final int files;

  /// The modules of [category], in phase order.
  List<ModuleReport> inCategory(ModuleCategory category) => [
    for (final module in modules)
      if (module.category == category) module,
  ];
}

/// An input of the helper that is missing or does not parse.
final class PortOrderInputError implements Exception {
  /// The error [message].
  const PortOrderInputError(this.message);

  /// What is missing.
  final String message;

  @override
  String toString() => message;
}

/// The inputs of the helper.
final class PortOrderInput {
  /// The helper for [package] in [repository]. Both are absolute paths with
  /// `/` separators.
  const PortOrderInput({required this.repository, required this.package});

  /// The repository root, with `third_party/` and `REUSE.toml`.
  final String repository;

  /// The `flutter_chartjs` package, with `tool/port_sources.yaml`,
  /// `doc/parity.md` and `lib/`.
  final String package;
}

/// The extensions of the upstream modules.
const List<String> moduleExtensions = ['.js', '.ts'];

/// Computes the port order. Throws a [PortOrderInputError] when
/// `tool/port_sources.yaml` or `doc/parity.md` is missing or does not
/// parse, or when the Chart.js pin is not checked out.
PortOrder computePortOrder(PortOrderInput input) {
  final repo = input.repository;
  String rel(String path) => relativePath(repo, path);

  final sourcesFile = '${input.package}/$portSourcesPath';
  final List<PortSource> sources;
  try {
    sources = parsePortSources(File(sourcesFile).readAsStringSync());
  } on FileSystemException catch (e) {
    throw PortOrderInputError('${rel(sourcesFile)}: ${e.message}.');
  } on FormatException catch (e) {
    throw PortOrderInputError('${rel(sourcesFile)}: ${e.message}.');
  }
  final source = sources.where((s) => s.header == chartJsProject).firstOrNull;
  if (source == null) {
    throw PortOrderInputError(
      '${rel(sourcesFile)} has no $chartJsProject entry.',
    );
  }
  final sourceDirectory = '${source.pinPath}/src';
  final srcDir = Directory('$repo/$sourceDirectory');
  if (!srcDir.existsSync() || srcDir.listSync().isEmpty) {
    throw PortOrderInputError(
      '$sourceDirectory is not checked out (dart run melos run upstream).',
    );
  }
  final parityFile = '${input.package}/doc/parity.md';
  if (!File(parityFile).existsSync()) {
    throw PortOrderInputError('${rel(parityFile)} does not exist.');
  }

  final findings = <Finding>[];
  final pin = '$repo/${source.pinPath}';
  final paths = [
    for (final entity in srcDir.listSync(recursive: true, followLinks: false))
      if (entity is File &&
          moduleExtensions.any((e) => entity.path.endsWith(e)))
        relativePath(pin, posixPath(entity.absolute.path)),
  ]..sort();

  final graph = _Graph(
    {
      for (final path in paths) path: File('$pin/$path').readAsStringSync(),
    },
    externals: {for (final s in sources) s.header},
    pinPath: source.pinPath,
    pinFile: (path) => File('$pin/$path').existsSync(),
    findings: findings,
  );

  final dartFiles = dartFilesUnder('${input.package}/lib');
  final dartOf = _dartFiles(dartFiles, source, graph, rel, findings);

  final typesDart = source.dartPathOf('src/types/index.d.ts');
  final typesDir = typesDart == null
      ? '${input.package}/lib/src/types'
      : '$repo/${typesDart.substring(0, typesDart.lastIndexOf('/'))}';
  final types = declaredTypes({
    for (final file in dartFilesUnder(typesDir))
      relativePath(input.package, file): File(file).readAsStringSync(),
  });
  final moduleTypes = <String, Map<String, String>>{};
  String? declaredIn(String name, String from) {
    final declared = types[name];
    if (declared != null) return declared;
    final dart = dartOf[from];
    if (dart == null) return null;
    return moduleTypes.putIfAbsent(
      from,
      () => declaredTypes({
        relativePath(input.package, dart): File(dart).readAsStringSync(),
      }),
    )[name];
  }

  final parity = _parityStatuses(
    File(parityFile).readAsStringSync(),
    '${source.url}/blob/${source.treeRef}/',
    graph,
    rel(parityFile),
    findings,
  );

  final modules = <String, ModuleReport>{};
  final states = <String, ({ParityState state, Set<String> symbols})>{};
  for (final path in paths) {
    final row = parity[path];
    final status = row == null
        ? (state: ParityState.notStarted, symbols: const <String>{})
        : classifyStatus(row.status);
    states[path] = status;
    final dart = dartOf[path];
    final mapped = source.dartPathOf(path);
    final needsDart =
        status.state == ParityState.partial ||
        status.state == ParityState.inProgress ||
        RegExp(r'^(ported|distributed)\b').hasMatch(row?.status.trim() ?? '');
    if (row != null && dart == null && needsDart) {
      findings.add(
        Finding.warning(
          rel(parityFile),
          row.line,
          'the status of $path is "${_shortStatus(row.status.trim())}", '
          'but no Dart file${mapped == null ? '' : ' at $mapped'} names it '
          'in its header.',
        ),
      );
    }
    modules[path] = ModuleReport(
      path: path,
      lines: graph.lines[path] ?? 0,
      phase: phaseOf(path),
      parityStatus: row?.status.trim(),
      dartFile: dart == null ? null : relativePath(input.package, dart),
      dependencies: graph.dependencies(path),
      interfaces: [
        for (final (name, from) in graph.interfaces(path))
          Interface(name, from, declaredIn(name, from)),
      ],
      error: graph.errors[path],
    );
  }

  bool satisfied(Dependency dependency) {
    switch (dependency.kind) {
      case DependencyKind.package:
        return graph.externals.any(
          (p) => dependency.target == p || dependency.target.startsWith('$p/'),
        );
      case DependencyKind.unresolved:
        return false;
      case DependencyKind.module:
        final state = states[dependency.target];
        if (state == null) return false;
        if (state.state == ParityState.done) return true;
        if (state.state != ParityState.partial ||
            dependency.needsAll ||
            dependency.names.isEmpty) {
          return false;
        }
        final defaultName = graph.syntax[dependency.target]?.defaultName;
        return dependency.names.every(
          (name) => state.symbols.contains(
            name == 'default' ? defaultName ?? name : name,
          ),
        );
    }
  }

  for (final module in modules.values) {
    final state = states[module.path]!.state;
    module
      ..missing = [
        for (final dependency in module.dependencies)
          if (!satisfied(dependency)) dependency,
      ]
      ..category = switch (state) {
        ParityState.done => ModuleCategory.done,
        ParityState.inProgress ||
        ParityState.partial => ModuleCategory.inProgress,
        ParityState.notStarted || ParityState.unknown =>
          module.dartFile != null
              ? ModuleCategory.inProgress
              : module.missing.isEmpty && module.error == null
              ? ModuleCategory.ready
              : ModuleCategory.blocked,
      };
  }
  _readyCycles(modules);
  for (final module in modules.values) {
    // A ready module misses only the other modules of its cycle.
    if (module.category == ModuleCategory.done ||
        module.category == ModuleCategory.ready) {
      continue;
    }
    for (final dependency in module.missing) {
      final target = modules[dependency.target];
      if (dependency.kind == DependencyKind.module && target != null) {
        target.neededBy++;
      }
    }
  }

  final sorted = modules.values.toList()
    ..sort((a, b) {
      final phase = a.phase.compareTo(b.phase);
      return phase != 0 ? phase : a.path.compareTo(b.path);
    });
  return PortOrder(
    project: source.header,
    version: source.version,
    sourceDirectory: sourceDirectory,
    modules: sorted,
    findings: findings,
    files: paths.length + dartFiles.length,
  );
}

/// Marks the blocked modules of an import cycle as ready when each of their
/// missing imports is a module of the same cycle (Tarjan's algorithm).
void _readyCycles(Map<String, ModuleReport> modules) {
  final blocked = {
    for (final module in modules.values)
      if (module.category == ModuleCategory.blocked && module.error == null)
        module.path: module,
  };
  final index = <String, int>{};
  final low = <String, int>{};
  final stack = <String>[];
  final onStack = <String>{};
  var counter = 0;

  Iterable<String> edges(String path) => [
    for (final dependency in blocked[path]!.missing)
      if (dependency.kind == DependencyKind.module &&
          blocked.containsKey(dependency.target))
        dependency.target,
  ];

  void connect(String path) {
    index[path] = low[path] = counter++;
    stack.add(path);
    onStack.add(path);
    for (final next in edges(path)) {
      if (!index.containsKey(next)) {
        connect(next);
        low[path] = low[path]! < low[next]! ? low[path]! : low[next]!;
      } else if (onStack.contains(next)) {
        low[path] = low[path]! < index[next]! ? low[path]! : index[next]!;
      }
    }
    if (low[path] != index[path]) return;
    final component = <String>[];
    String member;
    do {
      member = stack.removeLast();
      onStack.remove(member);
      component.add(member);
    } while (member != path);
    if (component.length < 2) return;
    final members = component.toSet();
    final closed = members.every(
      (m) => blocked[m]!.missing.every(
        (d) => d.kind == DependencyKind.module && members.contains(d.target),
      ),
    );
    if (!closed) return;
    for (final m in members) {
      final others = members.toList()
        ..remove(m)
        ..sort();
      blocked[m]!
        ..category = ModuleCategory.ready
        ..group = others;
    }
  }

  for (final path in blocked.keys) {
    if (!index.containsKey(path)) connect(path);
  }
}

/// The Dart file of each module: the file in [files] whose header names the
/// module at the mapped Dart path.
Map<String, String> _dartFiles(
  List<String> files,
  PortSource source,
  _Graph graph,
  String Function(String) rel,
  List<Finding> findings,
) {
  final result = <String, String>{};
  for (final file in files) {
    final path = rel(file);
    final header = Header.parse(
      const LineSplitter().convert(File(file).readAsStringSync()),
    );
    for (final line in header.malformed) {
      findings.add(
        Finding(
          path,
          line,
          'the header line does not match the grammar of porting-flow.md 4, '
          'tool 2.',
        ),
      );
    }
    for (final portedFrom in header.portedFrom) {
      if (portedFrom.project != source.header ||
          !portedFrom.path.startsWith('src/')) {
        continue;
      }
      if (!graph.lines.containsKey(portedFrom.path)) {
        findings.add(
          Finding.warning(
            path,
            portedFrom.line,
            '${portedFrom.path} is not a module of ${graph.pinPath}/src.',
          ),
        );
        continue;
      }
      final mapped = source.dartPathOf(portedFrom.path);
      if (mapped != path) {
        findings.add(
          Finding.warning(
            path,
            portedFrom.line,
            'the Dart path of ${portedFrom.path} is $mapped, not this file: '
            'the helper does not count it.',
          ),
        );
        continue;
      }
      result[portedFrom.path] = file;
    }
  }
  return result;
}

/// The `parity.md` row of each module.
Map<String, ParityRow> _parityStatuses(
  String markdown,
  String blobPrefix,
  _Graph graph,
  String parityPath,
  List<Finding> findings,
) {
  final result = <String, ParityRow>{};
  for (final row in parseParityRows(markdown, blobPrefix)) {
    if (!row.path.startsWith('src/')) continue;
    if (!graph.lines.containsKey(row.path)) {
      findings.add(
        Finding.warning(
          parityPath,
          row.line,
          '${row.path} is not a module of ${graph.pinPath}/src.',
        ),
      );
      continue;
    }
    if (result.containsKey(row.path)) {
      findings.add(
        Finding.warning(
          parityPath,
          row.line,
          'a second row of ${row.path}: the helper reads the first row '
          '(line ${result[row.path]!.line}).',
        ),
      );
      continue;
    }
    result[row.path] = row;
    final status = classifyStatus(row.status);
    if (status.state == ParityState.unknown) {
      findings.add(
        Finding(
          parityPath,
          row.line,
          'the status "${row.status.trim()}" of ${row.path} is not a value of '
          'porting-flow.md section 1 step 7 (not started, in progress, '
          'partial, ported, replaced, distributed, n/a).',
        ),
      );
    } else if (status.state == ParityState.partial && status.symbols.isEmpty) {
      findings.add(
        Finding.warning(
          parityPath,
          row.line,
          'the partial status of ${row.path} lists no symbols in backticks.',
        ),
      );
    }
  }
  for (final path in graph.lines.keys) {
    if (!result.containsKey(path)) {
      findings.add(
        Finding.warning(
          parityPath,
          null,
          'no row for $path: the helper counts it as not started.',
        ),
      );
    }
  }
  return result;
}

/// The origin of an imported name: the module that declares it.
typedef _Origin = ({String target, DependencyKind kind, String name});

/// The upstream modules and their imports.
final class _Graph {
  _Graph(
    Map<String, String> texts, {
    required this.externals,
    required this.pinPath,
    required this.pinFile,
    required this.findings,
  }) {
    for (final MapEntry(key: path, value: text) in texts.entries) {
      lines[path] = '\n'.allMatches(text).length;
      try {
        syntax[path] = parseModule(text);
      } on ModuleSyntaxError catch (e) {
        errors[path] = e.message;
        findings.add(Finding('$pinPath/$path', e.line, e.message));
      }
    }
    for (final MapEntry(key: path, value: module) in syntax.entries) {
      for (final import in module.imports) {
        final specifier = import.specifier;
        if (specifier.startsWith('.') &&
            resolve(path, specifier) == null &&
            !isData(path, specifier)) {
          findings.add(
            Finding(
              '$pinPath/$path',
              import.line,
              'the import "$specifier" does not resolve to a module of '
                  '$pinPath/src.',
            ),
          );
        }
      }
    }
  }

  /// The project names of `tool/port_sources.yaml`: the packages that the
  /// port has.
  final Set<String> externals;

  /// The repository-relative directory of the pin.
  final String pinPath;

  final List<Finding> findings;

  /// The `wc -l` count of each module.
  final Map<String, int> lines = {};

  /// The syntax of each module that the helper can read.
  final Map<String, ModuleSyntax> syntax = {};

  /// The error of each module that the helper cannot read.
  final Map<String, String> errors = {};

  /// Whether a path (relative to the pin) is a file of the pin.
  final bool Function(String path) pinFile;

  /// Whether the relative [specifier] in [importer] names a JSON file of the
  /// pin: data, not a module. `core.controller.js:12` imports `version` from
  /// `package.json`. The port has `chartJsPackageVersion` of
  /// `lib/src/upstream.dart` for it, so such an import does not block a
  /// module.
  bool isData(String importer, String specifier) {
    if (!specifier.startsWith('.') || !specifier.endsWith('.json')) {
      return false;
    }
    final slash = importer.lastIndexOf('/');
    final path = normalizeRelative(
      '${importer.substring(0, slash + 1)}$specifier',
    );
    return path != null && pinFile(path);
  }

  /// The module of the relative [specifier] in [importer], or null.
  String? resolve(String importer, String specifier) {
    final slash = importer.lastIndexOf('/');
    final path = normalizeRelative(
      '${importer.substring(0, slash + 1)}$specifier',
    );
    if (path == null) return null;
    final stem = path.endsWith('.js')
        ? path.substring(0, path.length - 3)
        : null;
    final candidates = [
      path,
      if (stem != null) ...['$stem.ts', '$stem.d.ts'],
      if (stem == null) ...[
        for (final extension in const ['.js', '.ts', '.d.ts'])
          '$path$extension',
        '$path/index.js',
        '$path/index.ts',
      ],
    ];
    return candidates.where(lines.containsKey).firstOrNull;
  }

  _Origin _target(String importer, String specifier, String name) {
    if (!specifier.startsWith('.')) {
      return (target: specifier, kind: DependencyKind.package, name: name);
    }
    final module = resolve(importer, specifier);
    if (module == null) {
      return (target: specifier, kind: DependencyKind.unresolved, name: name);
    }
    if (name == '*') {
      return (target: module, kind: DependencyKind.module, name: name);
    }
    return origin(module, name) ??
        (target: module, kind: DependencyKind.module, name: name);
  }

  /// The module that declares [name] of [module], through the re-exports
  /// and the exported imports of [module], or null when [module] does not
  /// export [name].
  _Origin? origin(String module, String name, [Set<String>? seen]) {
    final visited = seen ?? <String>{};
    final module0 = syntax[module];
    if (module0 == null || !visited.add('$module\u0000$name')) return null;
    for (final import in module0.imports) {
      if (import.kind != ImportKind.reexport) continue;
      for (final binding in import.bindings) {
        if (binding.local == name) {
          return _target(module, import.specifier, binding.imported);
        }
      }
    }
    final local = module0.localExports[name];
    if (local != null) {
      for (final import in module0.imports) {
        if (import.kind != ImportKind.import) continue;
        for (final binding in import.bindings) {
          if (binding.local == local) {
            return _target(module, import.specifier, binding.imported);
          }
        }
      }
      return (target: module, kind: DependencyKind.module, name: name);
    }
    if (name == 'default') return null;
    for (final import in module0.imports) {
      if (import.kind != ImportKind.reexportAll ||
          !import.specifier.startsWith('.')) {
        continue;
      }
      final target = resolve(module, import.specifier);
      if (target == null) continue;
      final found = origin(target, name, visited);
      if (found != null) return found;
    }
    return null;
  }

  bool _isTypeOnly(String importer, ModuleImport import) {
    if (import.typeOnly || importer.endsWith('.d.ts')) return true;
    final target = import.specifier.startsWith('.')
        ? resolve(importer, import.specifier)
        : null;
    return target != null && target.endsWith('.d.ts');
  }

  /// The value imports of [path], by the module that declares the names.
  List<Dependency> dependencies(String path) {
    final module = syntax[path];
    if (module == null) return const [];
    final result = <String, Dependency>{};
    void add(_Origin origin, {required bool all}) {
      if (origin.target == path) return;
      final dependency = result.putIfAbsent(
        origin.target,
        () => Dependency(origin.target, origin.kind),
      );
      if (all || origin.name == '*') {
        dependency.needsAll = true;
      } else {
        dependency.names.add(origin.name);
      }
    }

    for (final import in module.imports) {
      if (_isTypeOnly(path, import) || isData(path, import.specifier)) {
        continue;
      }
      if (import.needsAll) {
        add(_target(path, import.specifier, '*'), all: true);
      }
      for (final binding in import.bindings) {
        if (binding.typeOnly) continue;
        add(_target(path, import.specifier, binding.imported), all: false);
      }
    }
    return result.values.toList();
  }

  /// The types of the type-only imports of [path]: the name and the module
  /// that declares it.
  List<(String, String)> interfaces(String path) {
    final module = syntax[path];
    if (module == null) return const [];
    final result = <(String, String)>{};
    for (final import in module.imports) {
      if (isData(path, import.specifier)) continue;
      final all = _isTypeOnly(path, import);
      for (final binding in import.bindings) {
        if (!all && !binding.typeOnly) continue;
        final origin = _target(path, import.specifier, binding.imported);
        final name = switch (origin.name) {
          'default' => syntax[origin.target]?.defaultName ?? binding.local,
          '*' => binding.local,
          final other => other,
        };
        result.add((name, origin.target));
      }
    }
    return result.toList();
  }
}

// ---------------------------------------------------------------------------
// The output.

/// The longest line of the text report.
const int reportWidth = 100;

/// The text report of [order], with the findings at the end.
String renderPortOrder(PortOrder order) {
  final out = StringBuffer();
  final counts = {
    for (final category in ModuleCategory.values)
      category: order.inCategory(category).length,
  };
  out
    ..writeln(
      '$portOrderName: ${order.project} ${order.version}, '
      '${order.modules.length} modules in ${order.sourceDirectory}: '
      '${counts[ModuleCategory.done]} done, '
      '${counts[ModuleCategory.inProgress]} in progress, '
      '${counts[ModuleCategory.ready]} ready, '
      '${counts[ModuleCategory.blocked]} blocked.',
    )
    ..writeln();

  void section(
    String title,
    ModuleCategory category,
    void Function(ModuleReport) details,
  ) {
    final modules = order.inCategory(category);
    if (modules.isEmpty) {
      out
        ..writeln('$title: none.')
        ..writeln();
      return;
    }
    out.writeln('$title:');
    int? phase;
    for (final module in modules) {
      if (module.phase != phase) {
        phase = module.phase;
        out.writeln('  ${phaseTitle(phase)}');
      }
      details(module);
    }
    out.writeln();
  }

  String size(ModuleReport module) {
    final needed = module.neededBy == 0
        ? ''
        : ', needed by ${module.neededBy} '
              '${module.neededBy == 1 ? 'module' : 'modules'}';
    return '${module.path} (${module.lines} lines$needed)';
  }

  String missing(Dependency dependency) => switch (dependency.kind) {
    DependencyKind.module => () {
      final target = order.modules
          .where((m) => m.path == dependency.target)
          .firstOrNull;
      final label = switch (target?.category) {
        ModuleCategory.inProgress => 'in progress',
        ModuleCategory.ready => 'ready',
        ModuleCategory.blocked => 'blocked',
        ModuleCategory.done || null => 'not done',
      };
      return '${dependency.target} ($label)';
    }(),
    DependencyKind.package =>
      '${dependency.target} (no entry in $portSourcesPath)',
    DependencyKind.unresolved => '${dependency.target} (does not resolve)',
  };

  section('Ready to port, in phase order', ModuleCategory.ready, (module) {
    out.writeln('    ${size(module)}');
    if (module.group.isNotEmpty) {
      _writeList(out, 'port together with', module.group);
    }
    _writeList(out, 'interfaces', [
      for (final type in module.interfaces)
        '${type.name} (${type.declaredIn ?? 'not declared'})',
    ]);
  });
  section('In progress', ModuleCategory.inProgress, (module) {
    out.writeln('    ${size(module)}');
    _writeList(out, 'Dart file', [module.dartFile ?? 'none']);
    _writeList(out, 'parity.md', [
      if (module.parityStatus == null)
        'no row'
      else
        _shortStatus(module.parityStatus!),
    ]);
    if (module.missing.isNotEmpty) {
      _writeList(out, 'waits for', module.missing.map(missing).toList());
    }
  });
  section('Blocked', ModuleCategory.blocked, (module) {
    out.writeln('    ${size(module)}');
    if (module.error != null) {
      _writeList(out, 'does not parse', [module.error!]);
    }
    _writeList(out, 'missing', module.missing.map(missing).toList());
  });
  order.findings.forEach(out.writeln);
  return out.toString();
}

/// The first words of a long `parity.md` status.
String _shortStatus(String status) {
  final end = status.indexOf(RegExp(r'\s\(|[.;:]\s'));
  return end < 0 ? status : status.substring(0, end);
}

/// Writes `<label>: <items>` with an indent of six columns, wrapped at
/// [reportWidth].
void _writeList(StringBuffer out, String label, List<String> items) {
  const indent = '      ';
  if (items.isEmpty) {
    out.writeln('$indent$label: none');
    return;
  }
  var line = '$indent$label: ';
  for (final (index, item) in items.indexed) {
    final text = index < items.length - 1 ? '$item,' : item;
    if (line.trim().endsWith(':') || line.length + text.length < reportWidth) {
      line += line.endsWith(' ') ? text : ' $text';
    } else {
      out.writeln(line);
      line = '$indent  $text';
    }
  }
  out.writeln(line);
}

/// The JSON data of [order]: the same data as [renderPortOrder].
Map<String, Object?> portOrderJson(PortOrder order) {
  Map<String, Object?> module(ModuleReport m) => {
    'module': m.path,
    'phase': m.phase,
    'lines': m.lines,
    'parityStatus': m.parityStatus,
    'dart': m.dartFile,
    'neededBy': m.neededBy,
    'group': m.group,
    'interfaces': [
      for (final type in m.interfaces)
        {'name': type.name, 'from': type.from, 'declaredIn': type.declaredIn},
    ],
    'missing': [
      for (final d in m.missing)
        {
          'target': d.target,
          'kind': d.kind.name,
          'names': d.names.toList(),
          'needsAll': d.needsAll,
        },
    ],
    'error': m.error,
  };
  return {
    'project': order.project,
    'version': order.version,
    'sourceDirectory': order.sourceDirectory,
    'summary': {
      'modules': order.modules.length,
      for (final category in ModuleCategory.values)
        category.name: order.inCategory(category).length,
    },
    'ready': [
      for (final m in order.inCategory(ModuleCategory.ready)) module(m),
    ],
    'inProgress': [
      for (final m in order.inCategory(ModuleCategory.inProgress)) module(m),
    ],
    'blocked': [
      for (final m in order.inCategory(ModuleCategory.blocked)) module(m),
    ],
    'findings': [
      for (final f in order.findings)
        {
          'severity': f.severity.name,
          'path': f.path,
          'line': f.line,
          'message': f.message,
        },
    ],
  };
}
