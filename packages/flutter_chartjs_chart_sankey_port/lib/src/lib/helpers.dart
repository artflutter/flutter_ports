// Ported from chartjs-chart-sankey v0.19.1 src/lib/helpers.ts (MIT, Jukka Kurkela).

/// Port of `src/lib/helpers.ts`.
library;

import 'package:flutter_chartjs_chart_sankey_port/src/types.dart';
import 'package:flutter_chartjs_port/js_semantics.dart'
    show jsToString, jsTruthy;

/// helpers.ts:1 `defined`: whether [x] is not `undefined`.
///
/// The typed fields of the port hold Dart `null` for the JavaScript
/// `undefined` (`SankeyNode.x`, `SankeyNode.y`). Thus the test is a null
/// test.
bool defined(Object? x) => x != null;

/// helpers.ts:3 `toTextLines`: the lines of a label. [raw] is a string, a
/// number or a List of them, at any depth. A string splits at each line
/// feed. A falsy value gives no line.
List<String> toTextLines(Object? raw) {
  if (!jsTruthy(raw)) return [];

  final lines = <String>[];
  final inputs = raw is List ? List<Object?>.of(raw) : <Object?>[raw];

  while (inputs.isNotEmpty) {
    final input = inputs.removeLast();
    if (input is String) {
      lines.insertAll(0, input.split('\n'));
    } else if (input is List) {
      inputs.addAll(input);
    } else if (jsTruthy(input)) {
      lines.insert(0, jsToString(input));
    }
  }

  return lines;
}

/// helpers.ts:25 `validateSizeValue`: the size method of the option `size`.
/// A value that is not a [SankeySize] gives [SankeySize.max]. An upstream
/// name is not a value: a debug build stops on it.
// DIVERGES(sankey): adapt-sankey-option-enums, an enum of the size methods.
SankeySize validateSizeValue(Object? size) {
  assert(size is! String, 'size takes a SankeySize, not the name "$size".');
  return size is SankeySize ? size : SankeySize.max;
}
