// Original code, not ported from Chart.js: native padding option tests.
import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_chartjs_port/chartjs_core.dart';
import 'package:test/test.dart';

void main() {
  test('typed and raw scopes keep the complete native padding', () {
    const padding = EdgeInsets.fromLTRB(1, 2, 3, 4);
    final scope = LayoutOptionsScope()..padding = padding;
    expect(scope.paddingCell, isA<OptValue<EdgeInsets>>());
    expect(scope.readKey(OptionKey.padding), same(padding));
    expect(paddingOption({'padding': padding}['padding']), same(padding));
    expect(staticDataUpdateOptions(scope), isTrue);
  });

  test('an absent option inherits; an explicit inset replaces every side', () {
    const fallback = EdgeInsets.symmetric(vertical: 4);
    final inherited = createResolver([
      {},
      {'padding': fallback},
    ]);
    expect(paddingOption(inherited.readKey(OptionKey.padding)), fallback);
    const padding = EdgeInsets.only(left: 8);
    final explicit = createResolver([
      {'padding': padding},
      {'padding': fallback},
    ]);
    expect(paddingOption(explicit.readKey(OptionKey.padding)), same(padding));
    expect(paddingOption(explicit.readKey(OptionKey.padding)).vertical, 0);
    expect(paddingOption(undefined), EdgeInsets.zero);
  });

  test('a scriptable padding returns a native value at each context', () {
    // A Map: the subject is a scriptable option of a raw resolver.
    final resolver = createResolver([
      {
        'padding': (Object? ctx, Object? _) =>
            EdgeInsets.all((ctx! as Map<String, Object?>)['index']! as double),
      },
    ]);
    final first = attachContext(resolver, {'index': 2.0});
    final second = attachContext(resolver, {'index': 5.0});
    expect(paddingOption(first['padding']), const EdgeInsets.all(2));
    expect(paddingOption(second['padding']), const EdgeInsets.all(5));
  });

  test('old scalar and object padding inputs are rejected in debug', () {
    for (final value in <Object>[
      4.0,
      '4',
      {'left': 4.0},
    ]) {
      expect(() => paddingOption(value), throwsA(isA<AssertionError>()));
    }
  });

  test('scalar label spacing and border widths retain their schema', () {
    expect(const LegendLabelOptions(padding: 3).padding, 3);
    expect((BarOptionsScope()..borderWidth = 2).borderWidthCell!.raw, 2);
  });
}
