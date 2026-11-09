// Original code, not ported from Chart.js: the code panels of the docs site.

import 'dart:async';

import 'package:chartjs_docs/ui/docs_theme.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

const _keywords = {
  'bool',
  'const',
  'double',
  'else',
  'false',
  'final',
  'if',
  'int',
  'null',
  'num',
  'return',
  'true',
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

const _commentColor = Color(0xff64748b);
const _stringColor = Color(0xff15803d);
const _numberColor = Color(0xffb45309);
const Color _keywordColor = DocColors.primary;
const _typeColor = Color(0xff0e7490);
const _namedColor = Color(0xff7c3aed);

/// The spans of the Dart code [code].
@visibleForTesting
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

/// A panel of Dart code with a copy button.
class CodeBlock extends StatefulWidget {
  /// Creates a panel for [code].
  const CodeBlock({required this.code, super.key});

  /// The Dart code.
  final String code;

  @override
  State<CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<CodeBlock> {
  Timer? _reset;
  bool _copied = false;

  late List<TextSpan> _spans = highlightDart(widget.code);

  @override
  void didUpdateWidget(CodeBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code != widget.code) _spans = highlightDart(widget.code);
  }

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: DocColors.code,
    child: Stack(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 14, 48, 14),
          child: Text.rich(
            TextSpan(children: _spans),
            softWrap: false,
            style: const TextStyle(
              fontFamily: monoFont,
              fontSize: 12.5,
              height: 1.55,
              color: DocColors.ink,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            tooltip: _copied ? 'Copied' : 'Copy the code',
            iconSize: 17,
            visualDensity: VisualDensity.compact,
            color: _copied ? const Color(0xff15803d) : DocColors.muted,
            onPressed: _copy,
            icon: Icon(_copied ? Icons.check : Icons.content_copy),
          ),
        ),
      ],
    ),
  );
}
