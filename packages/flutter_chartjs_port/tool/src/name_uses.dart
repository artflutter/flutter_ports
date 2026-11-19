// Original code, not ported from Chart.js: the name uses of tool 1.

/// The names of the package that each file of `lib/src/` uses, resolved with
/// `package:analyzer` (ADR 0012).
///
/// Each file imports a public library, so an import no longer shows which
/// files a file needs. The rules of tool 1 on the theme, the typed API and
/// the widgets read the uses instead: a use of a name is a use of the file
/// that declares it.
library;

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import 'check_support.dart';
import 'dart_sdk.dart';

/// One use of a name of the package: the name, the 1-based line of the use
/// and the package-relative path of the file that declares the name.
typedef NameUse = ({String name, int line, String target});

/// The uses of names of other files of the package in each file of
/// `lib/src/` and in each ported file of `test/` of the package in
/// [packageDirectory] named [packageName], by package-relative path.
Future<Map<String, List<NameUse>>> resolveNameUses(
  String packageDirectory,
  String packageName,
) async {
  final packageRoot = Directory(packageDirectory).absolute.path;
  final roots = [
    for (final dir in ['lib/src', 'test'])
      if (Directory('$packageRoot/$dir').existsSync())
        Directory('$packageRoot/$dir').absolute.path,
  ];
  if (roots.isEmpty) return const {};
  final collection = AnalysisContextCollection(
    includedPaths: roots,
    sdkPath: dartSdkPath(),
  );
  final uses = <String, List<NameUse>>{};
  for (final context in collection.contexts) {
    for (final path in context.contextRoot.analyzedFiles()) {
      if (!path.endsWith('.dart')) continue;
      final relative = posixPath(path.substring(packageRoot.length + 1));
      if (relative.startsWith('test/') &&
          !File(path).readAsStringSync().startsWith('// Ported from ')) {
        continue;
      }
      final result = await context.currentSession.getResolvedUnit(path);
      if (result is! ResolvedUnitResult) continue;
      final visitor = _UseVisitor(
        result,
        packageName,
        posixPath(packageRoot),
        relative,
      );
      result.unit.accept(visitor);
      uses[relative] = visitor.uses;
    }
  }
  return uses;
}

final class _UseVisitor(
  final ResolvedUnitResult result,
  final String packageName,
  final String packageRoot,
  final String path,
) extends RecursiveAstVisitor<void> {
  final List<NameUse> uses = [];
  final Set<String> _seen = {};

  void _add(int offset, Element? element) {
    final library = element?.library;
    if (element == null || library == null) return;
    final target = _target(library.uri);
    if (target == null) return;
    if (target == path) return;
    final line = result.lineInfo.getLocation(offset).lineNumber;
    final name = element.name ?? '';
    if (_seen.add('$line $name $target')) {
      uses.add((name: name, line: line, target: target));
    }
  }

  /// The package-relative path of the library [uri], or null for a library
  /// of another package.
  String? _target(Uri uri) {
    final prefix = 'package:$packageName/';
    final text = uri.toString();
    if (text.startsWith(prefix)) return 'lib/${text.substring(prefix.length)}';
    if (uri.scheme != 'file') return null;
    final file = posixPath(uri.toFilePath());
    return file.startsWith('$packageRoot/')
        ? file.substring(packageRoot.length + 1)
        : null;
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    // The directives name libraries, not uses.
    for (final declaration in node.declarations) {
      declaration.accept(this);
    }
  }

  @override
  void visitComment(Comment node) {}

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (!node.inDeclarationContext()) _add(node.offset, node.element);
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitNamedType(NamedType node) {
    _add(node.name.offset, node.element);
    super.visitNamedType(node);
  }
}
