// Original code, not ported from Chart.js: native arc option twins.
import 'dart:ui' show Color;

import 'package:flutter_chartjs_port/src/core/core.config.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/elements/element.arc.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    as helpers;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/element_options_base.dart';
import 'package:flutter_chartjs_port/src/options/foreign_audit.dart';
import 'package:flutter_chartjs_port/src/options/opt.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
import 'package:flutter_chartjs_port/src/options/resolved.g.dart';
import 'package:flutter_chartjs_port/src/options/scopes.g.dart';
import 'package:test/test.dart';

const red = Color(0xffff0000);
const blue = Color(0xff0000ff);
const green = Color(0xff00ff00);

/// The ordinary path: the virtual call of a Config subclass.
class _OrdinaryConfig extends Config {}

/// The own keys of `defaults.elements.arc`, with its route in the last place.
ArcOptionsScope _keySource() => ArcOptionsScope()
  ..borderAlign = 'center'
  ..borderColor = blue
  ..borderDash = <Object?>[]
  ..borderDashOffset = 0.0
  ..borderJoinStyleCell = optUndefined
  ..borderRadius = 0.0
  ..borderWidth = 2.0
  ..offset = 0.0
  ..spacing = 0.0
  ..spacingMode = 'angular'
  ..angleCell = optUndefined
  ..circular = true
  ..selfJoin = false
  ..backgroundColor = red;

class _Fixture {
  _Fixture({required bool ordinary})
    : config = ordinary ? _OrdinaryConfig() : Config();
  final Config config;
  final scope = <String, Object?>{
    '_scriptable': true,
    '_indexable': ArcElement.descriptors.jsRead('_indexable'),
    '_allKeys': false,
    'borderAlign': 'center',
    'borderColor': blue,
    'borderDash': <Object?>[],
    'borderDashOffset': 0.0,
    'borderRadius': 0.0,
    'borderWidth': 2.0,
    'offset': 0.0,
    'spacing': 0.0,
    'spacingMode': 'angular',
    'circular': true,
    'selfJoin': false,
    'backgroundColor': red,
  };
  late final scopes = <Object?>[scope];
  final ArcOptionsScope keySource = _keySource();
  final prefixes = <String>['arc', ''];
  int contexts = 0;
  void Function()? beforeContext;

  ElementOptions resolve([double index = 0]) =>
      config.resolveOwnedArcNamedOptions(
        scopes,
        keySource.nativeOwnKeySnapshot,
        () {
          contexts++;
          beforeContext?.call();
          return ScriptableContext.data(null, index, null);
        },
        prefixes,
        immutableKeys: true,
      );

  helpers.OptionResolver get resolver =>
      config.createResolver(scopes, null, prefixes) as helpers.OptionResolver;
}

Object? plain(Object? value) {
  if (value is Function) return 'function';
  if (value is double && !value.isFinite) return '$value';
  if (value is JsObjectFace) {
    return {for (final key in value.jsKeys()) key: plain(value.jsRead(key))};
  }
  if (value is List<Object?>) return value.map(plain).toList();
  return value;
}

void _expectSame(ElementOptions a, ElementOptions b, [String reason = '']) {
  expect(a.jsKeys(), b.jsKeys(), reason: reason);
  for (final key in b.jsKeys()) {
    expect(plain(a.jsRead(key)), plain(b.jsRead(key)), reason: '$reason $key');
  }
}

/// Runs [prepare] on a native and an ordinary fixture and compares [steps]
/// resolves, with their context counts.
void _expectTwins(
  void Function(_Fixture f, List<Object?> trace) prepare, {
  int steps = 6,
  void Function(_Fixture f, int step)? before,
}) {
  final fixtures = [_Fixture(ordinary: false), _Fixture(ordinary: true)];
  final traces = [<Object?>[], <Object?>[]];
  for (var j = 0; j < 2; j++) {
    prepare(fixtures[j], traces[j]);
  }
  final seen = <ElementOptions>{};
  for (var i = 0; i < steps; i++) {
    for (final f in fixtures) {
      before?.call(f, i);
    }
    final a = fixtures[0].resolve(i.toDouble());
    final b = fixtures[1].resolve(i.toDouble());
    _expectSame(a, b, 'step $i');
    expect(a, isA<ArcOptions>());
    expect(a.isFrozen, isFalse);
    expect(seen.add(a), isTrue, reason: 'each result is a fresh object');
    // A later resolve must not see a write to an earlier result.
    a.storeKey(OptionKey.borderWidth, 99.0);
  }
  expect(fixtures[0].contexts, fixtures[1].contexts);
  expect(traces[0], traces[1]);
}

void main() {
  setUp(() {
    final saved = foreignAudit;
    foreignAudit = (_, _, _) {};
    addTearDown(() => foreignAudit = saved);
  });

  group('owned arc results against the ordinary Config', () {
    test('static options', () {
      _expectTwins((_, _) {});
    });

    test('indexed colors', () {
      _expectTwins((f, _) {
        f.scope['backgroundColor'] = <Color>[red, blue, green];
        f.scope['borderColor'] = const <Color>[blue, red];
      });
    });

    test('an indexed borderWidth and offset', () {
      _expectTwins((f, _) {
        f.scope['backgroundColor'] = <Color>[red, blue];
        f.scope['borderWidth'] = <double>[1, 2, 3];
        f.scope['offset'] = <int>[4, 5];
      });
    });

    test('an indexed angle and spacing of a polar area', () {
      _expectTwins((f, _) {
        f.scope['angle'] = <double>[10, 20];
        f.scope['spacing'] = <double>[1, 2, 3];
      });
    });

    test('the raw reference of a non-indexable list stays', () {
      final dash = <double>[2, 3];
      final fixtures = [_Fixture(ordinary: false), _Fixture(ordinary: true)];
      for (final f in fixtures) {
        f.scope['borderDash'] = dash;
        f.scope['backgroundColor'] = <Color>[red, blue];
      }
      for (var i = 0; i < 4; i++) {
        for (final f in fixtures) {
          final result = f.resolve(i.toDouble());
          expect(result.jsRead('borderDash'), same(dash));
          expect(result.valueOf(OptionKey.borderDash), same(dash));
        }
      }
    });

    test('a list of objects in a non-indexable key gives its resolvers', () {
      _expectTwins((f, _) {
        f.scope['backgroundColor'] = <Color>[red, blue];
        f.scope['borderDash'] = <Object?>[
          <String, Object?>{'inner': 1.0},
        ];
      });
    });

    test('a non-indexable list that gets an object in the steps', () {
      final results = <List<Object?>>[];
      for (final ordinary in [false, true]) {
        final f = _Fixture(ordinary: ordinary);
        final dash = <Object?>[];
        f.scope['borderDash'] = dash;
        f.scope['backgroundColor'] = <Color>[red, blue];
        final out = <Object?>[];
        for (var i = 0; i < 6; i++) {
          if (i == 3) {
            dash.add(<String, Object?>{'inner': 1.0});
          }
          out.add(plain(f.resolve(i.toDouble()).jsRead('borderDash')));
        }
        results.add(out);
      }
      expect(results[0], results[1]);
      expect(results[0][5], isA<List<Object?>>());
    });

    test('a non-indexable key other than borderDash keeps a foreign list', () {
      _expectTwins((f, _) {
        bool indexable(String name) => name != 'spacing';
        f.scope['_indexable'] = indexable;
        f.scope['spacing'] = <double>[1, 2];
        f.scope['backgroundColor'] = <Color>[red, blue];
      });
    });

    test('foreign static values keep the ordinary path', () {
      _expectTwins((f, _) {
        f.scope['backgroundColor'] = <Color>[red, blue];
        f.scope['borderWidth'] = '4';
        f.scope['borderAlign'] = 5.0;
        f.scope['circular'] = 1.0;
      });
    });

    test('an empty and a nested selected color', () {
      _expectTwins((f, _) => f.scope['backgroundColor'] = <Color>[]);
      _expectTwins((f, _) {
        f.scope['backgroundColor'] = <Object?>[
          red,
          <String, Object?>{'a': 1.0},
          blue,
        ];
      });
    });

    test('live lists keep their length and items', () {
      final lists = [
        <Color>[red],
        <Color>[red],
      ];
      var slot = 0;
      _expectTwins(
        (f, _) => f.scope['backgroundColor'] = lists[slot++],
        before: (f, step) {
          final list = f.scope['backgroundColor']! as List<Color>;
          if (step == 3) {
            list
              ..clear()
              ..addAll([blue, green, red]);
          }
          if (step == 5) list.clear();
        },
      );
    });

    test('an index above 2^53 takes the double remainder', () {
      final fixtures = [_Fixture(ordinary: false), _Fixture(ordinary: true)];
      for (final f in fixtures) {
        f.scope['backgroundColor'] = <Color>[red, blue, green];
      }
      for (final index in [
        0.0,
        1.0,
        9007199254740990.0,
        9007199254740992.0,
        9007199254740994.0,
        1e300,
      ]) {
        _expectSame(
          fixtures[0].resolve(index),
          fixtures[1].resolve(index),
          '$index',
        );
      }
    });

    test('a scriptable color with one and two parameters', () {
      _expectTwins((f, trace) {
        Color color(Object? ctx) {
          trace.add((ctx! as ScriptableContext).index);
          return (ctx as ScriptableContext).index == 1 ? blue : red;
        }

        f.scope['backgroundColor'] = color;
      });
      _expectTwins((f, trace) {
        Color color(Object? ctx, Object? options) {
          trace.add((options! as helpers.OptionView).readKey(OptionKey.offset));
          return green;
        }

        f.scope['borderColor'] = color;
      });
    });

    test('a key that is not scriptable keeps its raw function', () {
      Object? fn(Object? ctx) => throw StateError('never called');
      for (final ordinary in [false, true]) {
        final f = _Fixture(ordinary: ordinary);
        f.scope['_scriptable'] = false;
        f.scope['backgroundColor'] = fn;
        f.scope['borderColor'] = <Color>[red, blue];
        for (var i = 0; i < 4; i++) {
          expect(f.resolve(i.toDouble()).jsRead('backgroundColor'), same(fn));
        }
      }
    });

    for (final key in ['borderColor', 'backgroundColor']) {
      test('a $key callback that gives borderDash an object in its slot', () {
        final results = <List<Object?>>[];
        for (final ordinary in [false, true]) {
          final f = _Fixture(ordinary: ordinary);
          final dash = <Object?>[];
          f.scope['borderDash'] = dash;
          var calls = 0;
          Color color(Object? ctx) {
            calls++;
            if ((ctx! as ScriptableContext).index == 2 && dash.isEmpty) {
              dash.add(<String, Object?>{'inner': 1.0});
            }
            return red;
          }

          f.scope[key] = color;
          final out = <Object?>[];
          for (var i = 0; i < 5; i++) {
            out.add(plain(f.resolve(i.toDouble()).jsRead('borderDash')));
          }
          out.add(calls);
          results.add(out);
        }
        expect(results[0], results[1]);
      });
    }

    test('a context factory that changes the raw list or the resolver', () {
      final results = <List<Object?>>[];
      for (final ordinary in [false, true]) {
        final f = _Fixture(ordinary: ordinary);
        final dash = <Object?>[];
        f.scope['borderDash'] = dash;
        f.scope['backgroundColor'] = <Color>[red, blue];
        final out = <Object?>[];
        for (var i = 0; i < 6; i++) {
          if (i == 2) {
            f.beforeContext = () {
              if (dash.isEmpty) dash.add(<String, Object?>{'inner': 1.0});
            };
          }
          if (i == 4) {
            f.beforeContext = () => f.resolver.jsWrite('borderWidth', 7.0);
          }
          out.add(plain(f.resolve(i.toDouble())));
        }
        out.add(f.contexts);
        results.add(out);
      }
      expect(results[0], results[1]);
    });

    test('a resolver write and a cache clear between two resolves', () {
      final results = <List<Object?>>[];
      for (final ordinary in [false, true]) {
        final f = _Fixture(ordinary: ordinary);
        f.scope['backgroundColor'] = <Color>[red, blue];
        final out = <Object?>[];
        for (var i = 0; i < 6; i++) {
          if (i == 2) f.resolver.jsWrite('borderWidth', 7.0);
          if (i == 4) {
            f.scope['offset'] = 3.0;
            f.config.clearCache();
          }
          out.add(plain(f.resolve(i.toDouble())));
        }
        results.add(out);
      }
      expect(results[0], results[1]);
    });

    test('the hover prefixes keep the ordinary reads', () {
      final results = <Object?>[];
      for (final ordinary in [false, true]) {
        final f = _Fixture(ordinary: ordinary);
        f.scope['backgroundColor'] = <Color>[red, blue];
        f.scope['hoverBackgroundColor'] = green;
        final out = <Object?>[];
        for (var i = 0; i < 4; i++) {
          out.add(
            plain(
              f.config.resolveOwnedArcNamedOptions(
                f.scopes,
                f.keySource.nativeOwnKeySnapshot,
                () => ScriptableContext.data(null, i.toDouble(), null),
                const <String>['arcHover', 'hover', 'arc', ''],
              ),
            ),
          );
        }
        results.add(out);
      }
      expect(results[0], results[1]);
    });

    test('the private arc token is never written or returned', () {
      final f = _Fixture(ordinary: false);
      Color color(Object? ctx) => red;
      f.scope['backgroundColor'] = color;
      final a = f.resolve();
      final b = f.resolve(1);
      expect(identical(a, b), isFalse);
      expect(a.isFrozen, isFalse);
      expect(b.isFrozen, isFalse);
    });
  });

  group('the descriptor guard', () {
    test('admits the exact built-in arc predicate by identity', () {
      final indexable = ArcElement.descriptors.jsRead('_indexable');
      expect(Defaults.nativeElementDescriptors(true, indexable), isTrue);
    });

    test('declines a wrapper and an unknown predicate', () {
      final indexable =
          ArcElement.descriptors.jsRead('_indexable')! as bool Function(String);
      bool wrapper(String name) => indexable(name);
      expect(Defaults.nativeElementDescriptors(true, wrapper), isFalse);
      expect(Defaults.nativeElementDescriptors(wrapper, true), isFalse);
      expect(Defaults.nativeElementDescriptors(null, true), isFalse);
    });

    // A predicate that the guard admits, with a counter: a warm plan calls no
    // descriptor, and the ordinary path calls it for each key.
    for (final style in ['indexed colors', 'a scriptable color']) {
      test('a warm plan of $style calls no descriptor', () {
        var calls = 0;
        bool counted(String name) {
          calls++;
          return name != 'borderDash';
        }

        Defaults.nativeElementPredicate(counted);
        final f = _Fixture(ordinary: false);
        f.scope['_indexable'] = counted;
        Color color(Object? ctx) => green;
        f.scope['backgroundColor'] = style == 'indexed colors'
            ? <Color>[red, blue]
            : color;
        f
          ..resolve()
          ..resolve(1);
        calls = 0;
        final result = f.resolve(2);
        f.resolve(3);
        expect(calls, 0);
        expect(result.jsRead(r'$shared'), false);
        expect(result.jsRead('borderDash'), same(f.scope['borderDash']));
      });
    }

    test('the ordinary Config calls the descriptor for each key', () {
      var calls = 0;
      bool counted(String name) {
        calls++;
        return name != 'borderDash';
      }

      Defaults.nativeElementPredicate(counted);
      final f = _Fixture(ordinary: true);
      f.scope['_indexable'] = counted;
      f.scope['backgroundColor'] = <Color>[red, blue];
      f
        ..resolve()
        ..resolve(1);
      calls = 0;
      f.resolve(2);
      expect(calls, greaterThan(0));
    });

    test('a user predicate keeps each ordinary call', () {
      _expectTwins((f, trace) {
        f.scope['backgroundColor'] = <Color>[red, blue];
        bool indexable(String name) {
          trace.add(name);
          return name != 'borderDash';
        }

        f.scope['_indexable'] = indexable;
      });
    });
  });

  test('an undefined key of a template stays undefined and foreign', () {
    final f = _Fixture(ordinary: false);
    f.scope['backgroundColor'] = <Color>[red, blue];
    f
      ..resolve()
      ..resolve(1);
    final result = f.resolve(2);
    expect(result.jsRead('angle'), same(undefined));
    expect(result.jsRead('borderJoinStyle'), same(undefined));
    expect(result.isForeign(OptionKey.angle), isTrue);
    expect(result.jsKeys().first, r'$shared');
    expect(jsGet(result, r'$shared'), false);
  });
}
