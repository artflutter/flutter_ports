// Original code, not ported from Chart.js: the Dart SDK of the tools.

/// The Dart SDK path that the tools give to `package:analyzer`.
library;

import 'dart:io';

import 'package:analyzer/file_system/physical_file_system.dart';

import 'check_support.dart';

/// The Dart SDK of the running VM, or of `FLUTTER_ROOT` under
/// `flutter test`, or null to let the analyzer find it. The path is
/// absolute and normalized, as the analyzer requires.
String? dartSdkPath() {
  final executable = File(Platform.resolvedExecutable);
  final name = posixPath(executable.path).split('/').last;
  if (name == 'dart' || name == 'dart.exe') {
    return _normalized(executable.parent.parent.path);
  }
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  return flutterRoot == null
      ? null
      : _normalized('$flutterRoot/bin/cache/dart-sdk');
}

/// The absolute, normalized form of [path] for the analyzer, with the
/// separators of the platform.
String _normalized(String path) {
  final context = PhysicalResourceProvider.INSTANCE.pathContext;
  return context.normalize(context.absolute(path));
}
