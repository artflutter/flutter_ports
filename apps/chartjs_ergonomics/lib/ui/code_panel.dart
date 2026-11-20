// Original code, not ported from Chart.js: the code panel of a sample.

import 'package:chartjs_ergonomics/ui/code_region.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

const _keywords = {
  'bool',
  'class',
  'const',
  'double',
  'else',
  'extends',
  'false',
  'final',
  'for',
  'if',
  'in',
  'int',
  'late',
  'null',
  'num',
  'return',
  'super',
  'true',
  'var',
  'void',
};

final RegExp _token = RegExp(
  r'(?<comment>//[^\n]*)'
  r"|(?<string>r?'(?:\\.|[^'\\\n])*'|r?"
  r'"(?:\\.|[^"\\\n])*")'
  r'|(?<number>\b\d+(?:\.\d+)?\b)'
  r'|(?<named>\b[a-z_]\w*(?=:(?!:)))'
  r'|(?<type>\b[A-Z]\w*)'
  r'|(?<word>\b[a-z_]\w*)',
);

const _plainColor = Color(0xff1e293b);
const _commentColor = Color(0xff64748b);
const _stringColor = Color(0xff15803d);
const _numberColor = Color(0xffb45309);
const _keywordColor = Color(0xff4f46e5);
const _typeColor = Color(0xff0e7490);
const _namedColor = Color(0xff7c3aed);

/// The colored spans of the Dart code [code].
List<TextSpan> highlightDart(String code) {
  final spans = <TextSpan>[];
  var end = 0;
  for (final match in _token.allMatches(code)) {
    final text = match[0]!;
    final color = switch (match) {
      _ when match.namedGroup('comment') != null => _commentColor,
      _ when match.namedGroup('string') != null => _stringColor,
      _ when match.namedGroup('number') != null => _numberColor,
      _ when match.namedGroup('named') != null => _namedColor,
      _ when match.namedGroup('type') != null => _typeColor,
      _ when _keywords.contains(text) => _keywordColor,
      _ => null,
    };
    if (color == null) continue;
    if (match.start > end) {
      spans.add(TextSpan(text: code.substring(end, match.start)));
    }
    spans.add(
      TextSpan(
        text: text,
        style: TextStyle(color: color),
      ),
    );
    end = match.end;
  }
  if (end < code.length) spans.add(TextSpan(text: code.substring(end)));
  return spans;
}

/// The code of the region `sample` of the asset [path].
class const CodePanel({required final String path, super.key})
    extends StatefulWidget {
  /// Creates the panel of the source file at the asset [path].
  this;

  @override
  State<CodePanel> createState() => _CodePanelState();
}

class _CodePanelState() extends State<CodePanel> {
  late final Future<String> _code = rootBundle
      .loadString(widget.path)
      .then(codeRegion);

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xfff6f8fb),
      border: Border.all(color: const Color(0xffe2e8f0)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: FutureBuilder<String>(
        future: _code,
        builder: (context, snapshot) => switch (snapshot) {
          AsyncSnapshot(:final data?) => _Code(code: data),
          AsyncSnapshot(:final error?) => Text('$error'),
          _ => const SizedBox(height: 40),
        },
      ),
    ),
  );
}

class const _Code({required final String code}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: SelectableText.rich(
      TextSpan(children: highlightDart(code)),
      style: const TextStyle(
        fontFamily: 'RobotoMono',
        fontSize: 12.5,
        height: 1.45,
        color: _plainColor,
      ),
    ),
  );
}
