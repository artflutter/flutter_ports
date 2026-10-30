// Original code, not ported from Chart.js: the option schema generator.

/// The generator of the typed option scopes (Chart.js ADR 0054 §2).
///
/// [readSchema] reads `tool/options_schema.yaml` into a [Schema]. [generate]
/// gives the text of each generated file of `lib/src/options/`, not yet
/// formatted:
/// - `option_keys.g.dart`: `enum OptionKey` (one entry for each distinct key
///   name of the schema, by JS name) and `optionKeyOf`;
/// - `scope_kinds.g.dart`: `enum ScopeKind` (one entry for each kind) with
///   the keys, the shapes and the nested kinds of each kind;
/// - `scopes.g.dart`: one typed scope class `<Kind>Scope` for each kind.
///
/// The command `tool/options_gen.dart` writes and formats the files, and
/// compares them in its check mode.
library;

import 'mini_yaml.dart';

/// The atoms of a shape, with their bits (`ShapeBits` of
/// `lib/src/options/opt.dart`).
const Map<String, int> shapeAtoms = {
  'number': 1,
  'bool': 2,
  'string': 4,
  'fn': 8,
  'list': 16,
  'scope': 32,
  'any': 64,
};

/// The shape of a key: the bits of its atoms and the kind of its `scope`
/// atom.
final class Shape {
  /// A shape with the atoms of [mask] and the nested kind [scope].
  const Shape(this.mask, [this.scope]);

  /// Parses a shape text such as `number | scope Padding`.
  factory Shape.parse(String text, String where) {
    var mask = 0;
    String? scope;
    for (final part in text.split('|')) {
      final atom = part.trim();
      if (atom.startsWith('scope ')) {
        final kind = atom.substring(6).trim();
        if (scope != null) {
          throw FormatException('$where: two scope atoms in "$text"');
        }
        if (!RegExp(r'^[A-Z][A-Za-z0-9]*$').hasMatch(kind)) {
          throw FormatException('$where: bad kind name "$kind"');
        }
        scope = kind;
        mask |= shapeAtoms['scope']!;
      } else {
        final bit = shapeAtoms[atom];
        if (bit == null || atom == 'scope') {
          throw FormatException('$where: unknown shape atom "$atom"');
        }
        mask |= bit;
      }
    }
    return Shape(mask, scope);
  }

  /// The bits of the atoms.
  final int mask;

  /// The kind of the `scope` atom, or null.
  final String? scope;

  /// The Dart type `T` of the cell `Opt<T>` of the key.
  String get dartType {
    if (mask == shapeAtoms['number']) return 'double';
    if (mask == shapeAtoms['bool']) return 'bool';
    if (mask == shapeAtoms['string']) return 'String';
    if (mask == shapeAtoms['scope']) return '${scope}Scope';
    return 'Object';
  }

  /// The Dart expression of the classification of `raw`.
  String get classify {
    if (mask == shapeAtoms['number']) return 'classifyNumber(raw)';
    if (mask == shapeAtoms['bool']) return 'classifyBool(raw)';
    if (mask == shapeAtoms['string']) return 'classifyString(raw)';
    if (mask == shapeAtoms['scope']) return 'classifyScope<${scope}Scope>(raw)';
    return 'classifyUnion(raw, $mask)';
  }

  /// The classification function, as a tear-off or a closure.
  String get classifier {
    if (mask == shapeAtoms['number']) return 'classifyNumber';
    if (mask == shapeAtoms['bool']) return 'classifyBool';
    if (mask == shapeAtoms['string']) return 'classifyString';
    if (mask == shapeAtoms['scope']) return 'classifyScope<${scope}Scope>';
    return '(raw) => classifyUnion(raw, $mask)';
  }
}

/// One kind of the schema.
final class Kind {
  /// A kind.
  Kind(this.name, this.doc, this.element, this.others, this.keys);

  /// The kind name: the index.d.ts interface name or a port-only name.
  final String name;

  /// The doc line.
  final String doc;

  /// The element type id of an element kind, or null.
  final String? element;

  /// The shape of an undeclared key, or null (any value).
  final Shape? others;

  /// The declared keys and their shapes, in schema order.
  final Map<String, Shape> keys;

  /// The Dart name of the scope class.
  String get className => '${name}Scope';

  /// The name of the `ScopeKind` entry.
  String get enumName => lowerFirst(name);
}

/// The parsed schema.
final class Schema {
  /// A schema of [kinds].
  Schema(this.kinds);

  /// The kinds, in schema order.
  final List<Kind> kinds;

  /// The distinct key names, sorted by their code units.
  List<String> get keyNames {
    final names = <String>{
      for (final kind in kinds) ...kind.keys.keys,
    }.toList()..sort();
    return names;
  }
}

/// Reads the schema [text].
Schema readSchema(String text) {
  final root = parseYamlSubset(text);
  if (root is! Map<String, Object?> || root.keys.toList().join() != 'kinds') {
    throw const FormatException('the schema has one top-level key: kinds');
  }
  final kindsNode = root['kinds'];
  if (kindsNode is! Map<String, Object?>) {
    throw const FormatException('kinds: a mapping of kinds');
  }
  final kinds = <Kind>[];
  for (final MapEntry(key: name, value: node) in kindsNode.entries) {
    if (!RegExp(r'^[A-Z][A-Za-z0-9]*$').hasMatch(name)) {
      throw FormatException('kind $name: not an UpperCamelCase name');
    }
    if (node is! Map<String, Object?>) {
      throw FormatException('kind $name: a mapping');
    }
    for (final field in node.keys) {
      if (!const {'doc', 'element', 'others', 'keys'}.contains(field)) {
        throw FormatException('kind $name: unknown field $field');
      }
    }
    final doc = node['doc'];
    if (doc is! String || doc.isEmpty) {
      throw FormatException('kind $name: no doc');
    }
    final element = node['element'] as String?;
    final othersText = node['others'] as String?;
    final keysNode = node['keys'];
    final keys = <String, Shape>{};
    if (keysNode is Map<String, Object?>) {
      for (final MapEntry(:key, :value) in keysNode.entries) {
        if (value is! String) {
          throw FormatException('kind $name: key $key has no shape');
        }
        keys[key] = Shape.parse(value, 'kind $name key $key');
      }
    } else if (keysNode != 'none') {
      throw FormatException('kind $name: keys is a mapping or "none"');
    }
    kinds.add(
      Kind(
        name,
        doc,
        element,
        othersText == null
            ? null
            : Shape.parse(othersText, 'kind $name others'),
        keys,
      ),
    );
  }
  final names = {for (final kind in kinds) kind.name};
  for (final kind in kinds) {
    for (final shape in [...kind.keys.values, ?kind.others]) {
      final scope = shape.scope;
      if (scope != null && !names.contains(scope)) {
        throw FormatException('kind ${kind.name}: unknown kind $scope');
      }
    }
  }
  return Schema(kinds);
}

/// [text] with its first character in lower case.
String lowerFirst(String text) =>
    text.isEmpty ? text : text[0].toLowerCase() + text.substring(1);

/// [text] with its first character in upper case.
String upperFirst(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

/// The reserved words of Dart and the names of the members of an enum value,
/// which a key identifier must not take.
const Set<String> _reserved = {
  'assert', 'break', 'case', 'catch', 'class', 'const', 'continue', //
  'default', 'do', 'else', 'enum', 'extends', 'false', 'final', 'finally',
  'for', 'if', 'in', 'is', 'new', 'null', 'rethrow', 'return', 'super',
  'switch', 'this', 'throw', 'true', 'try', 'var', 'void', 'while', 'with',
  'await', 'yield', 'index', 'name', 'values', 'hashCode', 'runtimeType',
  'toString', 'noSuchMethod', 'jsName',
};

/// The Dart identifier of the key [name]: `_x` gives `descX`, `$x` gives
/// `dollarX`, and a reserved word gets the suffix `Key`.
String keyIdentifier(String name) {
  var id = name;
  if (id.startsWith('_')) id = 'desc${upperFirst(id.substring(1))}';
  if (id.startsWith(r'$')) id = 'dollar${upperFirst(id.substring(1))}';
  if (!RegExp(r'^[a-z][A-Za-z0-9]*$').hasMatch(id)) {
    throw FormatException('key $name: no Dart identifier');
  }
  return _reserved.contains(id) ? '${id}Key' : id;
}

/// The names that a typed setter of a scope class must not take: the
/// members of `OptionScope`, of `Object` and of `MapBase`.
const Set<String> _memberNames = {
  'kind', 'cellOf', 'setCell', 'hasField', 'classify', 'keyOf', 'lookup', //
  'owns', 'store', 'delete', 'ownKeys', 'ownKeyCount', 'jsKeys',
  'classifyName', 'jsRead', 'jsWrite', 'jsHas', 'jsDelete', 'cloneScope',
  'hashCode', 'runtimeType', 'length', 'keys', 'values', 'entries',
  'isEmpty', 'isNotEmpty', 'routes', 'route',
};

/// A Dart string literal of [text].
String dartString(String text) {
  if (text.contains(r'$') && !text.contains("'")) return "r'$text'";
  return "'${text.replaceAll(r'\', r'\\').replaceAll("'", r"\'")}'";
}

/// The doc comment lines of [text], wrapped at 76 columns with [indent].
String docLines(String text, String indent) {
  final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  final lines = <String>[];
  var line = '';
  for (final word in words) {
    final next = line.isEmpty ? word : '$line $word';
    if ('$indent/// $next'.length > 80 && line.isNotEmpty) {
      lines.add(line);
      line = word;
    } else {
      line = next;
    }
  }
  if (line.isNotEmpty) lines.add(line);
  return lines.map((l) => '$indent/// $l\n').join();
}

/// The line 1 of each generated file.
const String _header =
    '// Original code, not ported from Chart.js: generated from '
    'tool/options_schema.yaml by tool/options_gen.dart.\n';

/// The note after the header of each generated file.
const String _generated =
    '// Do not edit. Edit tool/options_schema.yaml and run\n'
    '// `dart run melos run options:gen` (Chart.js ADR 0054 §2).\n';

/// The texts of the generated files of [schema], by file name.
Map<String, String> generate(Schema schema) => {
  'option_keys.g.dart': _optionKeys(schema),
  'scope_kinds.g.dart': _scopeKinds(schema),
  'scopes.g.dart': _scopes(schema),
};

String _optionKeys(Schema schema) {
  final out = StringBuffer()
    ..write(_header)
    ..write(_generated)
    ..write('\n')
    ..write(
      '/// The option keys of the typed internal model (Chart.js ADR 0054 §2):\n'
      '/// one entry for each distinct key name of `tool/options_schema.yaml`.\n'
      '/// A name that is not here stays a `String` (an extra of its scope).\n'
      '///\n'
      '/// This library is a pure layer.\n'
      'library;\n\n'
      '/// An option key by its JS name.\n'
      'enum OptionKey {\n',
    );
  final names = schema.keyNames;
  for (final (i, name) in names.indexed) {
    out
      ..write('  /// The key `$name`.\n')
      ..write('  ${keyIdentifier(name)}(${dartString(name)})')
      ..write(i == names.length - 1 ? ';\n\n' : ',\n');
  }
  out
    ..write('  const OptionKey(this.jsName);\n\n')
    ..write('  /// The JS property name.\n')
    ..write('  final String jsName;\n')
    ..write('}\n\n')
    ..write(
      '/// The [OptionKey] of the JS name [name], or Dart `null` for a name\n'
      '/// that is not a key of the schema.\n'
      'OptionKey? optionKeyOf(String name) => switch (name) {\n',
    );
  for (final name in names) {
    out.write('  ${dartString(name)} => OptionKey.${keyIdentifier(name)},\n');
  }
  out.write('  _ => null,\n};\n');
  return out.toString();
}

String _scopeKinds(Schema schema) {
  final out = StringBuffer()
    ..write(_header)
    ..write(_generated)
    ..write('\n')
    ..write(
      '/// The scope kinds of the typed internal model (Chart.js ADR 0054 §2):\n'
      '/// one entry for each kind of `tool/options_schema.yaml`, with its\n'
      '/// keys, their shapes and the kinds of the nested scopes.\n'
      '///\n'
      '/// This library is a pure layer.\n'
      'library;\n\n'
      "import 'package:flutter_chartjs_port/src/options/opt.dart';\n"
      "import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';\n"
      "import 'package:flutter_chartjs_port/src/options/option_scope.dart';\n"
      "import 'package:flutter_chartjs_port/src/options/scopes.g.dart';\n\n"
      '/// A kind of option scope.\n'
      'enum ScopeKind {\n',
    );
  for (final (i, kind) in schema.kinds.indexed) {
    final element = kind.element;
    out
      ..write(docLines(kind.doc, '  '))
      ..write('  ${kind.enumName}(${dartString(kind.name)}')
      ..write(element == null ? '' : ', element: ${dartString(element)}')
      ..write(')')
      ..write(i == schema.kinds.length - 1 ? ';\n\n' : ',\n');
  }
  out
    ..write('  const ScopeKind(this.typeName, {this.element});\n\n')
    ..write('  /// The kind name of the schema.\n')
    ..write('  final String typeName;\n\n')
    ..write(
      '  /// The element type id of an element kind (`point`, `line`, `bar`,\n'
      '  /// `arc` or `generic`), else Dart `null`.\n',
    )
    ..write('  final String? element;\n\n')
    ..write('  /// A new empty scope of this kind.\n')
    ..write('  OptionScope create() => switch (this) {\n');
  for (final kind in schema.kinds) {
    out.write('    ScopeKind.${kind.enumName} => ${kind.className}(),\n');
  }
  out
    ..write('  };\n\n')
    ..write('  /// The declared keys, in schema order.\n')
    ..write('  List<OptionKey> get keys => switch (this) {\n');
  for (final kind in schema.kinds) {
    final keys = [
      for (final name in kind.keys.keys) 'OptionKey.${keyIdentifier(name)}',
    ];
    out.write(
      '    ScopeKind.${kind.enumName} => const [${keys.join(', ')}],\n',
    );
  }
  out
    ..write('  };\n\n')
    ..write(
      '  /// The shape bits (`ShapeBits`) of the declared key [key], or 0 for a\n'
      '  /// key that the kind does not declare.\n',
    )
    ..write('  int shapeOf(OptionKey key) => switch (this) {\n');
  for (final kind in schema.kinds) {
    if (kind.keys.isEmpty) {
      out.write('    ScopeKind.${kind.enumName} => 0,\n');
      continue;
    }
    out.write('    ScopeKind.${kind.enumName} => switch (key) {\n');
    for (final MapEntry(key: name, value: shape) in kind.keys.entries) {
      out.write('      OptionKey.${keyIdentifier(name)} => ${shape.mask},\n');
    }
    out.write('      _ => 0,\n    },\n');
  }
  out
    ..write('  };\n\n')
    ..write(
      '  /// The kind of the nested scope of the declared key [key], when its\n'
      '  /// shape has a `scope` atom, else Dart `null`.\n',
    )
    ..write('  ScopeKind? childKind(OptionKey key) => switch (this) {\n');
  for (final kind in schema.kinds) {
    final scoped = {
      for (final MapEntry(key: name, value: shape) in kind.keys.entries)
        if (shape.scope != null) name: shape.scope!,
    };
    if (scoped.isEmpty) {
      out.write('    ScopeKind.${kind.enumName} => null,\n');
      continue;
    }
    out.write('    ScopeKind.${kind.enumName} => switch (key) {\n');
    for (final MapEntry(key: name, value: scope) in scoped.entries) {
      out.write(
        '      OptionKey.${keyIdentifier(name)} => '
        'ScopeKind.${lowerFirst(scope)},\n',
      );
    }
    out.write('      _ => null,\n    },\n');
  }
  out
    ..write('  };\n\n')
    ..write(
      '  /// The shape bits of a key that the kind does not declare (`others`\n'
      '  /// of the schema; `any` when the schema gives none).\n',
    )
    ..write('  int get othersShape => switch (this) {\n');
  for (final kind in schema.kinds) {
    out.write(
      '    ScopeKind.${kind.enumName} => '
      '${kind.others?.mask ?? shapeAtoms['any']},\n',
    );
  }
  out
    ..write('  };\n\n')
    ..write(
      '  /// The kind of the nested scope of a key that the kind does not\n'
      '  /// declare (the `scope` atom of `others`), else Dart `null`.\n',
    )
    ..write('  ScopeKind? get othersKind => switch (this) {\n');
  for (final kind in schema.kinds) {
    final scope = kind.others?.scope;
    out.write(
      '    ScopeKind.${kind.enumName} => '
      '${scope == null ? 'null' : 'ScopeKind.${lowerFirst(scope)}'},\n',
    );
  }
  out
    ..write('  };\n\n')
    ..write(
      '  /// The cell of the raw JS value [raw] for a key that the kind does not\n'
      '  /// declare, by the shape `others`.\n',
    )
    ..write('  Opt<Object?> classifyOther(Object? raw) => switch (this) {\n');
  for (final kind in schema.kinds) {
    out.write(
      '    ScopeKind.${kind.enumName} => '
      '${(kind.others ?? Shape(shapeAtoms['any']!)).classify},\n',
    );
  }
  out.write('  };\n}\n');
  return out.toString();
}

String _scopes(Schema schema) {
  final out = StringBuffer()
    ..write(_header)
    ..write(_generated)
    ..write('\n')
    ..write(
      '/// The typed option scopes of the typed internal model (Chart.js ADR\n'
      '/// 0054 §3): one class `<Kind>Scope` for each kind of\n'
      '/// `tool/options_schema.yaml`. Each declared key has a field of an\n'
      '/// `Opt` cell, a getter and a setter of the cell (`<key>Cell`), and a\n'
      '/// typed setter of a plain value. `OptionScope` keeps the key order,\n'
      '/// the extras and the face.\n'
      '///\n'
      '/// This library is a pure layer.\n'
      'library;\n\n'
      "import 'package:flutter_chartjs_port/src/options/opt.dart';\n"
      "import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';\n"
      "import 'package:flutter_chartjs_port/src/options/option_scope.dart';\n"
      "import 'package:flutter_chartjs_port/src/options/scope_kinds.g.dart';\n",
    );
  for (final kind in schema.kinds) {
    out
      ..write('\n')
      ..write(docLines(kind.doc, ''))
      ..write('base class ${kind.className} extends OptionScope {\n')
      ..write('  /// An empty scope.\n')
      ..write('  ${kind.className}();\n\n')
      ..write('  @override\n')
      ..write('  ScopeKind get kind => ScopeKind.${kind.enumName};\n');
    for (final MapEntry(key: name, value: shape) in kind.keys.entries) {
      final id = keyIdentifier(name);
      final type = shape.dartType;
      out
        ..write('\n  Opt<$type>? _$id;\n\n')
        ..write('  /// The cell of `$name`, or Dart `null` when absent.\n')
        ..write('  Opt<$type>? get ${id}Cell => _$id;\n\n')
        ..write(
          '  /// Stores the cell of `$name`. Dart `null` deletes the key.\n',
        )
        ..write('  set ${id}Cell(Opt<$type>? cell) {\n')
        ..write('    if (cell == null) {\n')
        ..write('      delete(OptionKey.$id);\n')
        ..write('    } else {\n')
        ..write('      store(OptionKey.$id, cell);\n')
        ..write('    }\n')
        ..write('  }\n');
      final setter = _memberNames.contains(id) ? '${id}Value' : id;
      out.write('\n  /// Stores the plain value [value] of `$name`.\n');
      switch (type) {
        case 'double' || 'bool' || 'String':
          out.write(
            '  set $setter($type value) => '
            'store(OptionKey.$id, OptValue<$type>(value));\n',
          );
        case 'Object':
          out.write(
            '  set $setter(Object value) => '
            'store(OptionKey.$id, classify(OptionKey.$id, value));\n',
          );
        default:
          out.write(
            '  set $setter($type value) => '
            'store(OptionKey.$id, OptScope<$type>(value));\n',
          );
      }
    }
    // cellOf
    out
      ..write('\n  @override\n')
      ..write('  Opt<Object?>? cellOf(OptionKey key) => ');
    if (kind.keys.isEmpty) {
      out.write('null;\n');
    } else {
      out.write('switch (key) {\n');
      for (final name in kind.keys.keys) {
        final id = keyIdentifier(name);
        out.write('    OptionKey.$id => _$id,\n');
      }
      out.write('    _ => null,\n  };\n');
    }
    // setCell
    out
      ..write('\n  @override\n')
      ..write('  void setCell(OptionKey key, Opt<Object?>? cell) {\n');
    if (kind.keys.isNotEmpty) {
      out.write('    switch (key) {\n');
      for (final MapEntry(key: name, value: shape) in kind.keys.entries) {
        final id = keyIdentifier(name);
        out
          ..write('      case OptionKey.$id:\n')
          ..write('        _$id = fitCell(cell, ${shape.classifier});\n');
      }
      out
        ..write('      default:\n')
        ..write(
          "        throw ArgumentError.value(key, 'key', "
          "'Not a key of ${kind.name}');\n",
        )
        ..write('    }\n');
    } else {
      out.write(
        "    throw ArgumentError.value(key, 'key', "
        "'Not a key of ${kind.name}');\n",
      );
    }
    // hasField
    out
      ..write('  }\n')
      ..write('\n  @override\n')
      ..write('  bool hasField(OptionKey key) => ');
    if (kind.keys.isEmpty) {
      out.write('false;\n');
    } else {
      final ids = [
        for (final name in kind.keys.keys) 'OptionKey.${keyIdentifier(name)}',
      ];
      out.write(
        'switch (key) {\n    ${ids.join(' || ')} => true,\n'
        '    _ => false,\n  };\n',
      );
    }
    // classify
    out
      ..write('\n  @override\n')
      ..write('  Opt<Object?> classify(OptionKey key, Object? raw) => ');
    if (kind.keys.isEmpty) {
      out.write('kind.classifyOther(raw);\n');
    } else {
      out.write('switch (key) {\n');
      for (final MapEntry(key: name, value: shape) in kind.keys.entries) {
        out.write(
          '    OptionKey.${keyIdentifier(name)} => ${shape.classify},\n',
        );
      }
      out.write('    _ => kind.classifyOther(raw),\n  };\n');
    }
    out.write('}\n');
  }
  return out.toString();
}
