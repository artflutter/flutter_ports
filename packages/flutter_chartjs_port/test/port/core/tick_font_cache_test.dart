// Original code, not ported from Chart.js: tick font cache guards.
import 'dart:async';
import 'dart:collection';

import 'package:chartjs_test_utils/pure.dart' show setUpDefaultsRestore;
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/core/tick_font_cache.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart' show undefined;
import 'package:flutter_chartjs_port/src/options/option_scope.dart';
import 'package:flutter_chartjs_port/src/options/scopes.g.dart';
import 'package:test/test.dart';

Map<String, Object?> _font([Object? size = 12.0]) => {
  'size': size,
  'family': 'Arial',
  'style': 'normal',
  'lineHeight': 1.2,
  'weight': null,
};

OptionView _ticks(Object? font) => attachContext(
  createResolver([
    {'font': font},
  ]),
  {'index': 0},
);

ParsedFont _uncached(OptionView ticks, int index) => toFont(
  ticks.setContext({'index': index}).readKey(OptionKey.font),
);

ParsedFont _resolve(TickFontCache cache, OptionView ticks, int index) {
  final cached = cache.read(ticks);
  if (cached != null) return cached;
  final font = _uncached(ticks, index);
  cache.remember(ticks, font);
  return font;
}

List<Object?> _values(ParsedFont font) => [
  font.size,
  font.family,
  font.style,
  font.lineHeight,
  font.weight,
  font.string,
];

final class _DescriptorDefaults implements DescriptorDefaults {
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

final class _ObservedFont extends FontSpecScope {
  int reads = 0;

  @override
  Object? jsRead(String name) {
    reads++;
    return super.jsRead(name);
  }
}

final class _MutatingFont extends MapBase<String, Object?> {
  final Map<String, Object?> fields = _font();
  void Function()? onFamily;
  @override
  Object? operator [](Object? key) {
    if (key == 'family') onFamily?.call();
    return fields[key];
  }

  @override
  void operator []=(String key, Object? value) => fields[key] = value;
  @override
  Iterable<String> get keys => fields.keys;
  @override
  void clear() => fields.clear();
  @override
  Object? remove(Object? key) => fields.remove(key);
}

void main() {
  setUpDefaultsRestore();

  test('a getter changing an earlier field cannot poison the cached font', () {
    final raw = _MutatingFont();
    final ticks = _ticks(raw);
    final font =
        (ticks.proxy! as OptionResolver).readKey(OptionKey.font)!
            as OptionResolver;
    raw.onFamily = () => font['size'] = 18.0;
    final cache = TickFontCache();
    expect(_resolve(cache, ticks, 0).size, 12);
    expect(cache.read(ticks), isNull);
    expect(_resolve(cache, ticks, 1).size, 18);
    expect(cache.read(ticks)!.size, 18);
  });

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

  test(
    'static inputs reuse parsing but keep mutable font objects independent',
    () {
      final ticks = _ticks(_font());
      final cache = TickFontCache();
      final first = _resolve(cache, ticks, 0);
      expect(ticks.cachedStaticFont(), isNotNull);
      final second = cache.read(ticks)!;
      expect(_values(second), _values(first));
      expect(second, isNot(same(first)));
      first.string = 'caller changed first';
      second.string = 'caller changed second';
      final third = cache.read(ticks)!;
      expect(third.string, 'normal 12px Arial');
      expect(third, isNot(same(second)));
    },
  );

  test('resolver writes, deletes and font replacement invalidate reuse', () {
    final ticks = _ticks(_font());
    final cache = TickFontCache();
    _resolve(cache, ticks, 0);
    final proxy = ticks.proxy! as OptionResolver;
    final font = proxy.readKey(OptionKey.font)! as OptionResolver;
    for (final size in [18.0, 9.0]) {
      font['size'] = size;
      expect(cache.read(ticks), isNull);
      expect(_resolve(cache, ticks, 1).size, size);
      expect(cache.read(ticks)!.size, size);
    }
    font.jsDelete('size');
    expect(cache.read(ticks), isNull);
    expect(_values(_resolve(cache, ticks, 1)), _values(_uncached(ticks, 1)));
    ticks['font'] = _font(25.0);
    expect(cache.read(ticks), isNull);
    expect(_resolve(cache, ticks, 1).size, 25);
  });

  test(
    'raw map mutation follows upstream resolver caching and new resolvers',
    () {
      final raw = _font();
      final ticks = _ticks(raw);
      final cache = TickFontCache();
      _resolve(cache, ticks, 0);
      raw['size'] = 23.0;
      expect(_values(_resolve(cache, ticks, 1)), _values(_uncached(ticks, 1)));
      final fresh = _ticks(raw);
      expect(_resolve(cache, fresh, 0).size, 23);
    },
  );

  test(
    'switching a cached scalar to a callback evaluates every new context',
    () {
      final ticks = _ticks(_font());
      final cache = TickFontCache();
      _resolve(cache, ticks, 0);
      final font =
          (ticks.proxy! as OptionResolver).readKey(OptionKey.font)!
              as OptionResolver;
      final calls = <int>[];
      double sizeForContext(Map<String, Object?> context) {
        final index = context['index']! as int;
        calls.add(index);
        return 10.0 + index;
      }

      font['size'] = sizeForContext;
      for (var i = 0; i < 3; i++) {
        expect(cache.read(ticks), isNull);
        expect(_resolve(cache, ticks, i).size, 10 + i);
      }
      expect(calls, [0, 1, 2]);
    },
  );

  for (final entry in <String, Object?>{
    'whole scriptable font': (Map<String, Object?> c) =>
        _font(10.0 + (c['index']! as int)),
    'indexed font': [_font(10.0), _font(20.0)],
    'indexed size': _font([10.0, 20.0]),
    'indexed family': {
      ..._font(),
      'family': ['Arial', 'serif'],
    },
    'scriptable line height': {
      ..._font(),
      'lineHeight': (Map<String, Object?> c) => 1.0 + (c['index']! as int),
    },
  }.entries) {
    test('${entry.key} retains per-tick resolution', () {
      final ticks = _ticks(entry.value);
      final reference = _ticks(entry.value);
      final cache = TickFontCache();
      for (var i = 0; i < 4; i++) {
        expect(
          _values(_resolve(cache, ticks, i)),
          _values(_uncached(reference, i)),
        );
        expect(cache.read(ticks), isNull);
      }
    });
  }

  test('invalid styles still warn once per font resolution', () {
    final ticks = _ticks({..._font(), 'style': 'invalid'});
    final cache = TickFontCache();
    final warnings = <String>[];
    runZoned(
      () {
        _resolve(cache, ticks, 0);
        _resolve(cache, ticks, 1);
      },
      zoneSpecification: ZoneSpecification(
        print: (_, _, _, message) => warnings.add(message),
      ),
    );
    expect(warnings, [
      'Invalid font style specified: "invalid"',
      'Invalid font style specified: "invalid"',
    ]);
    expect(cache.read(ticks), isNull);
  });

  test('changed defaults preserve the eager fallback throw', () {
    final ticks = _ticks(_font());
    final cache = TickFontCache();
    _resolve(cache, ticks, 0);
    defaults.jsWrite('font', null);
    expect(cache.read(ticks), isNull);
    expect(() => _resolve(cache, ticks, 1), throwsA(isA<TypeError>()));
  });

  test('missing fields keep live global fallback values', () {
    final ticks = _ticks({'family': 'Arial'});
    final cache = TickFontCache();
    final first = _resolve(cache, ticks, 0);
    expect(cache.read(ticks), isNull);
    (defaults.fontCell!.raw! as FontSpecScope).size = 24.0;
    final second = _resolve(cache, ticks, 1);
    expect(second.size, 24);
    expect(second.size, isNot(first.size));
    expect(cache.read(ticks), isNull);
  });

  test('absent ticks.font reuses and tracks the live global font', () {
    final ticks = attachContext(createResolver([<String, Object?>{}]), {
      'index': 0,
    });
    final cache = TickFontCache();
    final first = _resolve(cache, ticks, 0);
    expect(_values(cache.read(ticks)!), _values(first));
    (defaults.fontCell!.raw! as FontSpecScope).size = 27.0;
    expect(cache.read(ticks), isNull);
    final second = _resolve(cache, ticks, 1);
    expect(second.size, 27);
    expect(_values(cache.read(ticks)!), _values(second));
  });

  test('an absent default weight remains distinct from explicit null', () {
    final ticks = attachContext(createResolver([<String, Object?>{}]), {
      'index': 0,
    });
    final cache = TickFontCache();
    expect(_resolve(cache, ticks, 0).weight, isNull);
    (defaults.fontCell!.raw! as FontSpecScope).jsDelete('weight');
    expect(cache.read(ticks), isNull);
    expect(_resolve(cache, ticks, 1).weight, same(undefined));
    expect(cache.read(ticks), isNull);
  });

  test('custom fallback objects retain eager reads', () {
    final ticks = _ticks(_font());
    final cache = TickFontCache();
    _resolve(cache, ticks, 0);
    final fallback = _ObservedFont();
    defaults.font = fallback;
    expect(cache.read(ticks), isNull);
    _resolve(cache, ticks, 1);
    _resolve(cache, ticks, 2);
    expect(fallback.reads, 10);
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
    expect(_values(_resolve(cache, ticks, 1)), _values(_uncached(ticks, 1)));
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

  test('routed default font fields keep eager getter calls', () {
    final ticks = _ticks(_font());
    final cache = TickFontCache();
    _resolve(cache, ticks, 0);
    final fallback = defaults.fontCell!.raw! as FontSpecScope;
    var reads = 0;
    fallback.addRoute(
      'size',
      ScopeRoute(
        (local) {
          reads++;
          return local;
        },
        targetScope: fallback,
        targetName: 'size',
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
