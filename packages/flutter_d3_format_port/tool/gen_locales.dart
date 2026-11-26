// Original code, not ported from d3-format: generates lib/src/locales.dart.

import 'dart:convert';
import 'dart:io';

String _escapeString(String value) {
  final hasControlOrSpecial = value.codeUnits.any(
    (c) =>
        c < 0x20 ||
        c == 0x7f ||
        c == 0x00a0 ||
        c == 0x200f ||
        c == 0x202f ||
        c == 0x5c,
  );
  if (!hasControlOrSpecial) {
    if (value.contains("'") && !value.contains('"') && !value.contains(r'$')) {
      return '"$value"';
    }
    if (value.contains(r'$') && !value.contains("'")) {
      return "r'$value'";
    }
    if (!value.contains("'") && !value.contains(r'$')) {
      return "'$value'";
    }
  }
  final out = StringBuffer("'");
  for (var i = 0; i < value.length; ++i) {
    final c = value.codeUnitAt(i);
    if (c == 0x27) {
      out.write(r"\'");
    } else if (c == 0x5c) {
      out.write(r'\\');
    } else if (c == 0x24) {
      out.write(r'\$');
    } else if (c < 0x20 ||
        c == 0x7f ||
        c == 0x00a0 ||
        c == 0x200f ||
        c == 0x202f) {
      out
        ..write(r'\u')
        ..write(c.toRadixString(16).padLeft(4, '0'));
    } else {
      out.writeCharCode(c);
    }
  }
  out.write("'");
  return out.toString();
}

String _constName(String tag) {
  final parts = tag.split('-');
  final buf = StringBuffer('locale');
  for (final part in parts) {
    if (part.isEmpty) continue;
    buf
      ..write(part[0].toUpperCase())
      ..write(part.substring(1));
  }
  return buf.toString();
}

void main() {
  final localeDir = Directory('../../third_party/d3-format/locale');
  if (!localeDir.existsSync()) {
    stderr.writeln('Missing ${localeDir.path}');
    exitCode = 1;
    return;
  }
  final files =
      localeDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort(
          (a, b) => a.uri.pathSegments.last.compareTo(b.uri.pathSegments.last),
        );

  final buf = StringBuffer()
    ..writeln(
      '// Original code, not ported from d3-format: all 59 upstream locales.',
    )
    ..writeln()
    ..writeln(
      '/// All 59 built-in `d3-format` v3.1.2 locale definitions as `const`',
    )
    ..writeln('/// [FormatLocaleDefinition] objects.')
    ..writeln('library;')
    ..writeln()
    ..writeln("import 'package:flutter_d3_format_port/src/locale.dart';")
    ..writeln()
    ..writeln('const List<int> _group3 = [3];')
    ..writeln('const List<String> _arabicNumerals = [')
    ..writeln("  '٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩',")
    ..writeln('];')
    ..writeln();

  final entries = <(String, String)>[];
  for (final file in files) {
    final name = file.uri.pathSegments.last;
    final tag = name.substring(0, name.length - 5);
    final constName = _constName(tag);
    entries.add((tag, constName));
    final data = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
    final decimal = data['decimal']! as String;
    final thousands = data['thousands'] as String?;
    final grouping = (data['grouping'] as List<Object?>?)
        ?.map((e) => (e! as num).toInt())
        .toList();
    final currency = (data['currency'] as List<Object?>?)
        ?.map((e) => e! as String)
        .toList();
    final numerals = (data['numerals'] as List<Object?>?)
        ?.map((e) => e! as String)
        .toList();
    final percent = data['percent'] as String?;
    final minus = data['minus'] as String?;
    final nan = data['nan'] as String?;

    buf
      ..writeln('/// Locale definition for `$tag`.')
      ..writeln(
        'const FormatLocaleDefinition $constName = FormatLocaleDefinition(',
      );
    if (decimal != '.') {
      buf.writeln('  decimal: ${_escapeString(decimal)},');
    }
    if (thousands != null) {
      buf.writeln('  thousands: ${_escapeString(thousands)},');
    }
    if (grouping != null) {
      if (grouping.length == 1 && grouping[0] == 3) {
        buf.writeln('  grouping: _group3,');
      } else {
        buf.writeln('  grouping: [${grouping.join(', ')}],');
      }
    }
    if (currency != null) {
      final c0 = _escapeString(currency[0]);
      final c1 = _escapeString(currency[1]);
      buf.writeln('  currency: ($c0, $c1),');
    }
    if (numerals != null) {
      const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
      final isArabic =
          numerals.length == 10 &&
          List<int>.generate(
            10,
            (i) => i,
          ).every((i) => numerals[i] == arabic[i]);
      if (isArabic) {
        buf.writeln('  numerals: _arabicNumerals,');
      } else {
        final items = numerals.map(_escapeString).join(', ');
        buf.writeln('  numerals: [$items],');
      }
    }
    if (percent != null && percent != '%') {
      buf.writeln('  percent: ${_escapeString(percent)},');
    }
    if (minus != null && minus != '\u2212') {
      buf.writeln('  minus: ${_escapeString(minus)},');
    }
    if (nan != null && nan != 'NaN') {
      buf.writeln('  nan: ${_escapeString(nan)},');
    }
    buf
      ..writeln(');')
      ..writeln();
  }

  buf
    ..writeln(
      '/// All 59 built-in `d3-format` v3.1.2 locales keyed by BCP-47 tag.',
    )
    ..writeln('const Map<String, FormatLocaleDefinition> formatLocales = {');
  for (final (tag, constName) in entries) {
    buf.writeln("  '$tag': $constName,");
  }
  buf.writeln('};');

  File('lib/src/locales.dart').writeAsStringSync(buf.toString());
  stdout.writeln(
    'Generated lib/src/locales.dart with ${entries.length} locales.',
  );
}
