// Original code, not ported from Chart.js: native indexed option regressions.
import 'dart:collection';
import 'dart:ui' show Color;

import 'package:flutter_chartjs_port/src/core/core.config.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    as helpers;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/element_options_base.dart';
import 'package:flutter_chartjs_port/src/options/foreign_audit.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
import 'package:flutter_chartjs_port/src/options/resolved.g.dart';
import 'package:test/test.dart';

const _red = Color(0xffff0000);
const _blue = Color(0xff0000ff);

// An otherwise identical Config that intentionally retains the ordinary path.
class _OrdinaryConfig extends Config {}

class _ObservedConfig extends Config {
  int calls = 0;
  @override
  ElementOptions resolveElementNamedOptions(
    List<Object?> scopes,
    List<Object> keys,
    Object Function() context,
    List<String> prefixes,
    ElementOptions into,
  ) {
    calls++;
    return super.resolveElementNamedOptions(
      scopes,
      keys,
      context,
      prefixes,
      into,
    );
  }
}

class _DerivedColor extends Color {
  const _DerivedColor(super.value);
}

class _Opaque {
  int reads = 0;
  @override
  Type get runtimeType {
    reads++;
    return _Opaque;
  }
}

class _ObservedList extends ListBase<Object?> {
  _ObservedList(this.values);
  final List<Object?> values;
  final List<String> reads = [];
  @override
  int get length {
    reads.add('length');
    return values.length;
  }

  @override
  set length(int value) => values.length = value;
  @override
  Object? operator [](int index) {
    reads.add('$index');
    return values[index];
  }

  @override
  void operator []=(int index, Object? value) => values[index] = value;
}

class _Fixture {
  _Fixture({bool ordinary = false, Object? colors = const [_red, _blue]})
    : config = ordinary ? _OrdinaryConfig() : Config(),
      scope = {
        '_scriptable': true,
        '_indexable': true,
        'radius': 3.0,
        'backgroundColor': colors,
        'borderColor': _blue,
      } {
    scopes = [scope];
  }
  final Config config;
  final Map<String, Object?> scope;
  late final List<Object?> scopes;
  final keys = <Object>[
    OptionKey.radius,
    OptionKey.backgroundColor,
    OptionKey.borderColor,
  ];
  final prefixes = <String>['point', ''];
  int contexts = 0;
  Object Function()? makeContext;
  PointOptions resolve([double index = 0]) => config.resolveElementNamedOptions(
    scopes,
    keys,
    () {
      contexts++;
      return makeContext?.call() ?? ScriptableContext.data(null, index, null);
    },
    prefixes,
    PointOptions(),
  ) as PointOptions;

  helpers.OptionResolver get resolver =>
      config.createResolver(scopes, null, prefixes) as helpers.OptionResolver;

  bool probe([double index = 0]) =>
      resolver
          .resolveIndexedElementOptions(
            keys,
            () => ScriptableContext.data(null, index, null),
            PointOptions(),
            Defaults.nativeElementDescriptors,
            () => true,
          )
          ?.resolved ??
      false;
}

Object? _plain(Object? value) => switch (value) {
  final helpers.OptionView v => {
    for (final k in v.jsKeys()) k: _plain(v.jsRead(k)),
  },
  final List<Object?> l => l.map(_plain).toList(),
  _ => value,
};

void _same(ElementOptions actual, ElementOptions expected) {
  expect(actual.jsKeys(), expected.jsKeys());
  for (final key in expected.jsKeys()) {
    expect(
      _plain(actual.jsRead(key)),
      _plain(expected.jsRead(key)),
      reason: key,
    );
  }
}

void main() {
  setUp(() {
    // Several cases intentionally exercise foreign numeric and color values.
    final saved = foreignAudit;
    foreignAudit = (_, _, _) {};
    addTearDown(() => foreignAudit = saved);
  });

  test('native producer entry preserves custom Config virtual dispatch', () {
    final f = _Fixture();
    final config = _ObservedConfig();
    for (var i = 0; i < 3; i++) {
      final result = config.resolveNativeElementNamedOptions(
        f.scopes,
        f.keys,
        () => ScriptableContext.data(null, 1, null),
        f.prefixes,
        PointOptions(),
      );
      expect(result.valueOf(OptionKey.backgroundColor), _blue);
    }
    expect(config.calls, 3);
  });

  test('warm native lists activate; options remain fresh and unshared', () {
    final f = _Fixture();
    final first = f.resolve();
    expect(f.probe(), isTrue);
    final second = f.resolve(1);
    expect(first.backgroundColor, _red);
    expect(second.backgroundColor, _blue);
    expect(first.$sharedValue, isFalse);
    expect(second.$sharedValue, isFalse);
    expect(identical(first, second), isFalse);
    first.storeKey(OptionKey.radius, 42.0);
    expect(f.resolve().radius, 3);
    expect(f.contexts, 3);
  });

  for (final colors in <List<Object?>>[
    <Color>[_red, _blue],
    List<Color>.of([_red, _blue], growable: false),
    List<Color>.unmodifiable([_red, _blue]),
    const <Color>[_red, _blue],
    <Object?>[_red, null, undefined],
  ]) {
    test('native ${colors.runtimeType} matches ordinary resolution', () {
      final fast = _Fixture(colors: colors);
      final full = _Fixture(ordinary: true, colors: colors);
      for (var i = 0; i < 8; i++) {
        _same(fast.resolve(i.toDouble()), full.resolve(i.toDouble()));
      }
      expect(fast.probe(), isTrue);
    });
  }

  test('list contents and lengths remain live, including empty and nested', () {
    final colors = <Object?>[_red, _blue];
    final fast = _Fixture(colors: colors)..resolve();
    final full = _Fixture(ordinary: true, colors: colors)..resolve();
    expect(fast.probe(), isTrue);
    for (final values in <List<Object?>>[
      [_blue],
      [],
      [_red, null, undefined],
      [
        <String, Object?>{'radius': 7.0},
      ],
      [
        <Object?>[_red],
      ],
      [_red, _blue],
    ]) {
      colors
        ..clear()
        ..addAll(values);
      _same(fast.resolve(3), full.resolve(3));
    }
    expect(fast.probe(), isTrue);
  });

  test('writes, deletes and full cache clears invalidate the plan', () {
    final f = _Fixture()..resolve();
    expect(f.probe(), isTrue);
    f.resolver.jsWrite('backgroundColor', <Color>[_blue]);
    expect(f.resolve().backgroundColor, _blue);
    f.resolver.jsDelete('radius');
    expect(f.resolve().radiusValue, same(undefined));
    f.scope['radius'] = 9.0;
    f.scope['backgroundColor'] = <Color>[_red];
    f.config.clearCache();
    expect(f.resolve().radius, 9);
    expect(f.resolve().backgroundColor, _red);
    expect(f.probe(), isTrue);
  });

  test('changed key sequence preserves enumeration and values', () {
    final f = _Fixture()..resolve();
    expect(f.probe(), isTrue);
    f.keys
      ..clear()
      ..addAll([OptionKey.backgroundColor, OptionKey.radius]);
    expect(f.resolve().jsKeys(), [r'$shared', 'radius', 'backgroundColor']);
    expect(f.probe(), isTrue);
  });

  test(
    'context factory mutations run once and retain ordinary descriptor reads',
    () {
      for (final clear in [false, true]) {
        final f = _Fixture()..resolve();
        expect(f.probe(), isTrue);
        f.makeContext = () {
          if (clear) {
            f.config.clearCache();
          } else {
            f.resolver.jsWrite('_indexable', false);
          }
          return ScriptableContext.data(null, 1, null);
        };
        final result = f.resolve();
        expect(f.contexts, 2);
        expect(
          result.backgroundColor,
          clear ? _blue : f.scope['backgroundColor'],
        );
      }
    },
  );

  test('custom list getters have exactly the ordinary read trace', () {
    final a = _ObservedList([_red, _blue]);
    final b = _ObservedList([_red, _blue]);
    final fast = _Fixture(colors: a);
    final full = _Fixture(ordinary: true, colors: b);
    for (var i = 0; i < 3; i++) {
      a.reads.clear();
      b.reads.clear();
      _same(fast.resolve(i.toDouble()), full.resolve(i.toDouble()));
      expect(a.reads, b.reads);
    }
    expect(fast.probe(), isFalse);
  });

  test('custom descriptors and scriptable options preserve call order', () {
    for (final scriptable in [false, true]) {
      final a = <String>[];
      final b = <String>[];
      _Fixture setup(List<String> calls, {required bool ordinary}) {
        final f = _Fixture(ordinary: ordinary);
        if (scriptable) {
          // JS-arity callback: the config Map provides no function context.
          // ignore: avoid_types_on_closure_parameters
          f.scope['radius'] = (Object? _) {
            calls.add('radius');
            return 5.0;
          };
        } else {
          // The config Map does not provide a function parameter type.
          // ignore: avoid_types_on_closure_parameters
          f.scope['_indexable'] = (String name) {
            calls.add(name);
            return true;
          };
        }
        return f;
      }

      final fast = setup(a, ordinary: false);
      final full = setup(b, ordinary: true);
      for (var i = 0; i < 3; i++) {
        a.clear();
        b.clear();
        _same(fast.resolve(i.toDouble()), full.resolve(i.toDouble()));
        expect(a, b);
      }
      expect(fast.probe(), isFalse);
    }
  });

  test('non-native contexts and exceptional indices retain fallback', () {
    for (final index in <Object?>[-1.0, 0.5, double.nan, null, undefined]) {
      final fast = _Fixture()..resolve();
      final full = _Fixture(ordinary: true)..resolve();
      Object context() => ScriptableContext(null)..index = index;
      fast.makeContext = context;
      full.makeContext = context;
      _same(fast.resolve(), full.resolve());
      expect(fast.contexts, full.contexts);
    }
    final fast = _Fixture()..resolve();
    final full = _Fixture(ordinary: true)..resolve();
    fast.makeContext = () => <String, Object?>{'index': 1.0};
    full.makeContext = fast.makeContext;
    _same(fast.resolve(), full.resolve());
    expect(fast.contexts, 2);
  });

  test(
    'root built-in predicates qualify without replacing their functions',
    () {
      final f = _Fixture();
      f.scope
        ..remove('_scriptable')
        ..remove('_indexable');
      f.scopes.add(descriptors);
      f.resolve();
      expect(f.probe(), isTrue);
      expect(f.resolve(1).backgroundColor, _blue);
    },
  );

  test(
    'indexed numeric options retain raw integer and negative zero values',
    () {
      final f = _Fixture(colors: _red);
      f.scope['radius'] = <Object?>[2, -0.0, double.infinity];
      f.resolve();
      expect(f.probe(), isTrue);
      expect(f.resolve().radiusValue, isA<int>());
      expect((f.resolve(1).radiusValue! as double).isNegative, isTrue);
      expect(f.resolve(2).radiusValue, double.infinity);
    },
  );

  test('context may change a selected value to a nested object', () {
    final a = <Object?>[_red];
    final b = <Object?>[_red];
    final fast = _Fixture(colors: a)..resolve();
    final full = _Fixture(ordinary: true, colors: b)..resolve();
    expect(fast.probe(), isTrue);
    fast.makeContext = () {
      a[0] = <String, Object?>{'radius': 7.0};
      return ScriptableContext.data(null, 0, null);
    };
    full.makeContext = () {
      b[0] = <String, Object?>{'radius': 7.0};
      return ScriptableContext.data(null, 0, null);
    };
    _same(fast.resolve(), full.resolve());
    expect(fast.contexts, 2);
  });

  test('cached rejection remains correct for changed keys and cache clear', () {
    final f = _Fixture();
    // The config Map does not provide a function parameter type.
    // ignore: avoid_types_on_closure_parameters
    f.scope['radius'] = (Object? _) => 4.0;
    f.resolve();
    expect(f.probe(), isFalse);
    f.keys.remove(OptionKey.radius);
    expect(f.resolve().backgroundColor, _red);
    // A conservative rejection may persist for an otherwise eligible shape.
    expect(f.probe(), isFalse);
    f.scope['radius'] = 3.0;
    f.keys.insert(0, OptionKey.radius);
    f.config.clearCache();
    expect(f.resolve().radius, 3.0);
    expect(f.probe(), isTrue);
  });

  test(
    'inherited index and context-time key changes keep ordinary behavior',
    () {
      final fast = _Fixture()..resolve();
      final full = _Fixture(ordinary: true)..resolve();
      fast.makeContext = () =>
          ScriptableContext(<String, Object?>{'index': 1.0});
      full.makeContext = fast.makeContext;
      _same(fast.resolve(), full.resolve());
      fast.makeContext = () {
        fast.keys
          ..clear()
          ..add(OptionKey.borderColor);
        return ScriptableContext.data(null, 0, null);
      };
      full.makeContext = () {
        full.keys
          ..clear()
          ..add(OptionKey.borderColor);
        return ScriptableContext.data(null, 0, null);
      };
      _same(fast.resolve(), full.resolve());
      expect(fast.contexts, 3);
    },
  );

  test(
    'large integer contexts use JavaScript numeric rounding before modulo',
    () {
      const green = Color(0xff00ff00);
      final colors = <Object?>[_red, _blue, green];
      final fast = _Fixture(colors: colors)..resolve();
      final full = _Fixture(ordinary: true, colors: colors)..resolve();
      // Parse at runtime: JS already rounds this integer; VM/Wasm retain it.
      final index = int.parse('9007199254740993');
      fast.makeContext = () => ScriptableContext(null)..index = index;
      full.makeContext = fast.makeContext;
      final actual = fast.resolve();
      _same(actual, full.resolve());
      expect(actual.backgroundColor, green);
      expect(fast.contexts, 2);
    },
  );

  test('Color subclasses in native Color lists retain the fast path', () {
    const color = _DerivedColor(0xffff0000);
    final f = _Fixture(colors: <Color>[color])..resolve();
    expect(f.probe(), isTrue);
    expect(f.resolve().backgroundColor, same(color));
  });

  test('opaque option values are rejected without inspecting runtimeType', () {
    final opaque = _Opaque();
    final f = _Fixture();
    f.scope['pointStyle'] = opaque;
    f.keys.add(OptionKey.pointStyle);
    f
      ..resolve()
      ..resolve();
    expect(f.probe(), isFalse);
    expect(opaque.reads, 0);
  });

  test('shared flag is stored before context and not overwritten after it', () {
    for (final ordinary in [false, true]) {
      final f = _Fixture(ordinary: ordinary)..resolve();
      for (final invalidate in [false, true]) {
        final into = PointOptions();
        var calls = 0;
        final result = f.config.resolveElementNamedOptions(
          f.scopes,
          f.keys,
          () {
            calls++;
            expect(into.$sharedValue, isFalse);
            into.storeKey(OptionKey.dollarShared, true);
            if (invalidate) f.config.clearCache();
            return ScriptableContext.data(null, 0, null);
          },
          f.prefixes,
          into,
        );
        expect(result, same(into));
        expect(result.$sharedValue, isTrue);
        expect(calls, 1);
      }
    }
  });

  test('foreign audit mutation preserves subsequent indexed reads', () {
    final colors = <Object?>[_red];
    final f = _Fixture(colors: colors)..resolve();
    expect(f.probe(), isTrue);
    f.resolver.jsWrite('radius', '4');
    foreignAudit = (owner, key, value) {
      if (owner == 'PointOptions' && key == 'radius') colors[0] = _blue;
    };
    expect(f.resolve().backgroundColor, _blue);
  });
}
