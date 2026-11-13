// Original code, not ported from Chart.js: tick font cache guards.
import 'package:chartjs_test_utils/pure.dart' show setUpDefaultsRestore;
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/core/tick_font_cache.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart';
import 'package:flutter_chartjs_port/src/options/option_scope.dart';
import 'package:flutter_chartjs_port/src/types/chart_text_style.dart';
import 'package:test/test.dart';

// A font is a ChartTextStyle (Chart.js ADR 0116): one immutable value. The
// cache gives the same object again while the static font option and the
// global font stay the same.

ChartTextStyle _font([double size = 12]) =>
    ChartTextStyle(fontFamily: 'Arial', fontSize: size, height: 1.2);

OptionView _ticks(Object? font) => attachContext(
  createResolver([
    {'font': font},
  ]),
  {'index': 0},
);

ChartTextStyle _uncached(OptionView ticks, int index) =>
    toFont(ticks.setContext({'index': index}).readKey(OptionKey.font));

ChartTextStyle _resolve(TickFontCache cache, OptionView ticks, int index) {
  final cached = cache.read(ticks);
  if (cached != null) return cached;
  final font = _uncached(ticks, index);
  cache.remember(ticks, font);
  return font;
}

final class _DescriptorDefaults() implements DescriptorDefaults {
  int reads = 0;

  @override
  Object? get allKeys {
    reads++;
    return false;
  }

  @override
  Object? get indexable {
    reads++;
    return true;
  }

  @override
  Object? get scriptable {
    reads++;
    return true;
  }
}

void main() {
  setUpDefaultsRestore();

  test('cold probe does not resolve or invoke a font callback', () {
    var calls = 0;
    final ticks = _ticks((Object? _) {
      calls++;
      return _font();
    });
    expect(ticks.cachedStaticFont(), isNull);
    expect(TickFontCache().read(ticks), isNull);
    expect(calls, 0);
  });

  test('a static font gives the same resolved font again', () {
    final ticks = _ticks(_font());
    final cache = TickFontCache();
    final first = _resolve(cache, ticks, 0);
    expect(ticks.cachedStaticFont(), isNotNull);
    expect(cache.read(ticks), same(first));
    expect(cache.read(ticks), _uncached(ticks, 1));
  });

  test('a font replacement invalidates reuse', () {
    final ticks = _ticks(_font());
    final cache = TickFontCache();
    _resolve(cache, ticks, 0);
    ticks['font'] = _font(25);
    expect(cache.read(ticks), isNull);
    expect(_resolve(cache, ticks, 1).fontSize, 25);
    expect(cache.read(ticks)!.fontSize, 25);
  });

  test('switching a cached font to a callback evaluates every context', () {
    final ticks = _ticks(_font());
    final cache = TickFontCache();
    _resolve(cache, ticks, 0);
    final calls = <int>[];
    ChartTextStyle fontForContext(Object? context) {
      final index = (context! as Map<String, Object?>)['index']! as int;
      calls.add(index);
      return _font(10.0 + index);
    }

    ticks['font'] = fontForContext;
    for (var i = 0; i < 3; i++) {
      expect(cache.read(ticks), isNull);
      expect(_resolve(cache, ticks, i).fontSize, 10 + i);
    }
    expect(calls, [0, 1, 2]);
  });

  for (final entry in <String, Object?>{
    'whole scriptable font': (Map<String, Object?> c) =>
        _font(10.0 + (c['index']! as int)),
    'indexed font': [_font(10), _font(20)],
  }.entries) {
    test('${entry.key} retains per-tick resolution', () {
      final ticks = _ticks(entry.value);
      final reference = _ticks(entry.value);
      final cache = TickFontCache();
      for (var i = 0; i < 4; i++) {
        expect(_resolve(cache, ticks, i), _uncached(reference, i));
        expect(cache.read(ticks), isNull);
      }
    });
  }

  test('a changed global font invalidates reuse', () {
    final ticks = _ticks(const ChartTextStyle(fontSize: 12));
    final cache = TickFontCache();
    expect(_resolve(cache, ticks, 0).fontFamily, 'Helvetica Neue');
    defaults.font = const ChartTextStyle(fontFamily: 'serif', fontSize: 9);
    expect(cache.read(ticks), isNull);
    final second = _resolve(cache, ticks, 1);
    expect(second.fontFamily, 'serif');
    expect(second.fontSize, 12);
  });

  test('absent ticks.font reuses and tracks the live global font', () {
    final ticks = attachContext(createResolver([<String, Object?>{}]), {
      'index': 0,
    });
    final cache = TickFontCache();
    final first = _resolve(cache, ticks, 0);
    expect(cache.read(ticks), same(first));
    defaults.font = const ChartTextStyle(fontSize: 27, height: 1);
    expect(cache.read(ticks), isNull);
    final second = _resolve(cache, ticks, 1);
    expect(second.fontSize, 27);
    expect(second.lineHeight, 27);
    expect(cache.read(ticks), same(second));
  });

  test('deleted descriptor cache entries are resolved before reuse', () {
    final ticks = _ticks(_font());
    final cache = TickFontCache();
    _resolve(cache, ticks, 0);
    (ticks.proxy! as OptionResolver).jsDelete('_scriptable');
    expect(cache.read(ticks), isNull);
    _resolve(cache, ticks, 1);
    expect(cache.read(ticks), isNotNull);
  });

  test('sub-proxies keep their normal property reads', () {
    final ticks = attachContext(
      createResolver([
        {'font': _font()},
      ]),
      {'index': 0},
      {'font': _font()},
    );
    final cache = TickFontCache();
    _resolve(cache, ticks, 0);
    expect(cache.read(ticks), isNull);
    expect(_resolve(cache, ticks, 1), _uncached(ticks, 1));
  });

  test('routed global font keeps getter calls on every resolution', () {
    final ticks = _ticks(_font());
    final cache = TickFontCache();
    _resolve(cache, ticks, 0);
    var reads = 0;
    defaults.addRoute(
      'font',
      ScopeRoute(
        (local) {
          reads++;
          return local;
        },
        targetScope: defaults,
        targetName: 'font',
      ),
    );
    for (var i = 0; i < 2; i++) {
      expect(cache.read(ticks), isNull);
      _resolve(cache, ticks, i);
    }
    expect(reads, 2);
  });

  test('overridden setContext is still called on every resolution', () {
    final ticks = attachContext(
      createResolver([
        {'font': _font(), '_scriptable': false},
      ]),
      {'index': 0},
    );
    final cache = TickFontCache();
    _resolve(cache, ticks, 0);
    var calls = 0;
    OptionView setContext(Object context) {
      calls++;
      return attachContext(ticks.proxy, context);
    }

    ticks['setContext'] = setContext;
    _resolve(cache, ticks, 1);
    _resolve(cache, ticks, 2);
    expect(calls, 2);
    expect(cache.read(ticks), isNull);
  });

  test('custom descriptor getters are not skipped', () {
    final descriptor = _DescriptorDefaults();
    final ticks = attachContext(
      createResolver([
        {'font': _font()},
      ]),
      {'index': 0},
      null,
      descriptor,
    );
    descriptor.reads = 0;
    final cache = TickFontCache();
    _resolve(cache, ticks, 0);
    _resolve(cache, ticks, 1);
    expect(descriptor.reads, 6);
    expect(cache.read(ticks), isNull);
  });
}
