// Original code, not ported from Chart.js: core.defaults cases with no spec.
import 'dart:convert';

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs/src/core/core.defaults.dart';
import 'package:flutter_chartjs/src/helpers/helpers.config.dart'
    show attachContext, createResolver;
import 'package:flutter_chartjs/src/js/js_array.dart';
import 'package:flutter_chartjs/src/js/js_function.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;
import 'package:test/test.dart';

// Upstream behavior that test/specs/core.defaults.tests.js does not check
// (AGENTS.md rule 3). The expected values come from src/core/core.defaults.js
// at v4.5.1, with the types of its .ts imports stripped by node:module and
// @kurkle/color 0.3.2 from third_party/kurkle-color, in Node.js v24.12.0 on
// x64. A test that pins a difference of the port says so.
//
// Most tests use a new `Defaults({}, [])`, as the probe does. The tests of
// the singleton and of the harness use `defaults`. The harness restores it
// after each test (setUpSpecs).

/// `JSON.stringify(value, replacer)` with the replacer of the Node.js probe:
/// `undefined` is `"<undefined>"` and a function is `"<fn>"`.
String _json(Object? value) => switch (value) {
  null => 'null',
  Undefined() => '"<undefined>"',
  final bool b => b ? 'true' : 'false',
  final double d => jsNumberToString(d),
  num() => throw ArgumentError.value(value, 'value', 'is an int'),
  final String s => jsonEncode(s),
  _ when jsIsFunction(value) => '"<fn>"',
  final List<Object?> list => '[${list.map(_json).join(',')}]',
  final Map<String, Object?> map =>
    '{${jsObjectKeys(map).map((k) => _entry(map, k)).join(',')}}',
  _ => throw ArgumentError.value(value, 'value', 'has no JSON form'),
};

/// The JSON member `"key":value` of [key] in [map].
String _entry(Map<String, Object?> map, String key) =>
    '${jsonEncode(key)}:${_json(map[key])}';

/// The JavaScript property read `object[key]` on an object (a Map): an
/// absent key gives [undefined].
Object? _get(Object? object, String key) {
  final map = object! as Map<String, Object?>;
  return map.containsKey(key) ? map[key] : undefined;
}

/// `Object.keys(object)`.
List<String> _keys(Object? object) =>
    jsObjectKeys(object! as Map<String, Object?>);

/// `new Defaults({}, [])`.
Defaults _defaults() => Defaults(<String, Object?>{}, const []);

/// A platform whose device pixel ratio is 2. Only `getDevicePixelRatio` is
/// read.
final class _Platform implements types.BasePlatform {
  @override
  double getDevicePixelRatio() => 2;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A chart with a [_Platform]. Only `platform` is read.
final class _Chart implements types.Chart {
  @override
  final types.BasePlatform platform = _Platform();

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Matches a JavaScript `TypeError`, a Dart [TypeError] in the port.
final Matcher _throwsTypeError = throwsA(isA<TypeError>());

void main() {
  setUpSpecs();

  group('the singleton', () {
    test('has the upstream keys, values and key order', () {
      expect(
        _keys(defaults),
        [
          'animation',
          'backgroundColor',
          'borderColor',
          'color',
          'datasets',
          'devicePixelRatio',
          'elements',
          'events',
          'font',
          'hover',
          'hoverBackgroundColor',
          'hoverBorderColor',
          'hoverColor',
          'indexAxis',
          'interaction',
          'maintainAspectRatio',
          'onHover',
          'onClick',
          'parsing',
          'plugins',
          'responsive',
          'scale',
          'scales',
          'showLine',
          'drawActiveElementsOnTop',
          'animations',
          'transitions',
          'layout',
        ],
      );
      expect(
        _json(defaults),
        '{"animation":{"delay":"<undefined>","duration":1000,'
        '"easing":"easeOutQuart","fn":"<undefined>","from":"<undefined>",'
        '"loop":"<undefined>","to":"<undefined>","type":"<undefined>"},'
        '"backgroundColor":"rgba(0,0,0,0.1)",'
        '"borderColor":"rgba(0,0,0,0.1)","color":"#666","datasets":{},'
        '"devicePixelRatio":"<fn>","elements":{},'
        '"events":["mousemove","mouseout","click","touchstart","touchmove"],'
        '"font":{"family":"\'Helvetica Neue\', \'Helvetica\', \'Arial\', '
        'sans-serif","size":12,"style":"normal","lineHeight":1.2,'
        '"weight":null},"hover":{},"hoverBackgroundColor":"<fn>",'
        '"hoverBorderColor":"<fn>","hoverColor":"<fn>","indexAxis":"x",'
        '"interaction":{"mode":"nearest","intersect":true,'
        '"includeInvisible":false},"maintainAspectRatio":true,'
        '"onHover":null,"onClick":null,"parsing":true,"plugins":{},'
        '"responsive":true,"scale":{"display":true,"offset":false,'
        '"reverse":false,"beginAtZero":false,"bounds":"ticks","clip":true,'
        '"grace":0,"grid":{"display":true,"lineWidth":1,'
        '"drawOnChartArea":true,"drawTicks":true,"tickLength":8,'
        '"tickWidth":"<fn>","tickColor":"<fn>","offset":false,'
        '"color":"rgba(0,0,0,0.1)"},"border":{"display":true,"dash":[],'
        '"dashOffset":0,"width":1,"color":"rgba(0,0,0,0.1)"},'
        '"title":{"display":false,"text":"","padding":{"top":4,"bottom":4},'
        '"color":"#666"},"ticks":{"minRotation":0,"maxRotation":50,'
        '"mirror":false,"textStrokeWidth":0,"textStrokeColor":"",'
        '"padding":3,"display":true,"autoSkip":true,"autoSkipPadding":3,'
        '"labelOffset":0,"callback":"<fn>","minor":{},"major":{},'
        '"align":"center","crossAlign":"near","showLabelBackdrop":false,'
        '"backdropColor":"rgba(255, 255, 255, '
        '0.75)","backdropPadding":2,'
        '"color":"#666"}},"scales":{},"showLine":true,'
        '"drawActiveElementsOnTop":true,"animations":{"colors":'
        '{"type":"color","properties":["color","borderColor",'
        '"backgroundColor"]},"numbers":{"type":"number","properties":'
        '["x","y","borderWidth","radius","tension"]}},"transitions":'
        '{"active":{"animation":{"duration":400}},"resize":{"animation":'
        '{"duration":0}},"show":{"animations":{"colors":'
        '{"from":"transparent"},"visible":{"type":"boolean","duration":0}}},'
        '"hide":{"animations":{"colors":{"to":"transparent"},"visible":'
        '{"type":"boolean","easing":"linear","fn":"<fn>"}}}},'
        '"layout":{"autoPadding":true,"padding":{"top":0,"right":0,'
        '"bottom":0,"left":0}}}',
      );
    });

    test('has the upstream descriptors and overrides', () {
      expect(
        _json(descriptors),
        '{"_scriptable":"<fn>","_indexable":"<fn>",'
        '"hover":{"_fallback":"interaction"},'
        '"interaction":{"_scriptable":false,"_indexable":false},'
        '"animation":{"_fallback":false,"_indexable":false,'
        '"_scriptable":"<fn>"},"animations":{"_fallback":"animation"},'
        '"scale":{"_fallback":false,"_scriptable":"<fn>",'
        '"_indexable":"<fn>","ticks":{"_scriptable":"<fn>",'
        '"_indexable":"<fn>"}},"scales":{"_fallback":"scale"}}',
      );
      expect(_json(overrides), '{}');
      expect(jsCall(descriptors['_scriptable'], ['onClick']), false);
      expect(jsCall(descriptors['_scriptable'], ['color']), true);
      expect(jsCall(descriptors['_indexable'], ['events']), false);
      expect(jsCall(descriptors['_indexable'], ['color']), true);
    });

    test('routes the colors of the scale', () {
      final scale = defaults['scale']! as Map<String, Object?>;
      expect(_keys(scale['ticks']), [
        'minRotation',
        'maxRotation',
        'mirror',
        'textStrokeWidth',
        'textStrokeColor',
        'padding',
        'display',
        'autoSkip',
        'autoSkipPadding',
        'labelOffset',
        'callback',
        'minor',
        'major',
        'align',
        'crossAlign',
        'showLabelBackdrop',
        'backdropColor',
        'backdropPadding',
        'color',
      ]);
      expect(_keys(scale['grid']), [
        'display',
        'lineWidth',
        'drawOnChartArea',
        'drawTicks',
        'tickLength',
        'tickWidth',
        'tickColor',
        'offset',
        'color',
      ]);
      expect(_get(scale['ticks'], 'color'), '#666');
      expect(_get(scale['grid'], 'color'), 'rgba(0,0,0,0.1)');
      expect(_get(scale['border'], 'color'), 'rgba(0,0,0,0.1)');
      expect(_get(scale['title'], 'color'), '#666');

      defaults['color'] = 'red';
      defaults['borderColor'] = 'blue';
      expect(_get(scale['ticks'], 'color'), 'red');
      expect(_get(scale['grid'], 'color'), 'blue');
      expect(_get(scale['border'], 'color'), 'blue');
      expect(_get(scale['title'], 'color'), 'red');
    });

    test('calls its function values', () {
      expect(
        jsCall(defaults['hoverBackgroundColor'], [
          <String, Object?>{},
          <String, Object?>{'backgroundColor': 'rgba(0,0,0,0.1)'},
        ]),
        '#00000019',
      );
      expect(
        jsCall(defaults['hoverBorderColor'], [
          <String, Object?>{},
          <String, Object?>{'borderColor': '#36A2EB'},
        ]),
        '#059BFF',
      );
      expect(
        jsCall(defaults['hoverColor'], [
          <String, Object?>{},
          <String, Object?>{'color': '#666'},
        ]),
        '#5C5C5C',
      );
      expect(
        jsCall(defaults['devicePixelRatio'], [
          <String, Object?>{'chart': _Chart()},
        ]),
        2.0,
      );
    });

    test('a hover color of a color that does not parse is undefined', () {
      Object? hover(Object? value) => jsCall(defaults['hoverBackgroundColor'], [
        <String, Object?>{},
        <String, Object?>{'backgroundColor': value},
      ]);
      for (final value in [undefined, '', 'nope', 0.0, double.nan, -0.0]) {
        expect(hover(value), same(undefined), reason: '$value');
      }
      expect(hover('currentColor'), same(undefined));
      expect(hover('#fff'), '#E6E6E6');
      expect(hover(<String, Object?>{'r': 1.0}), '#010000');
      expect(
        jsCall(defaults['hoverColor'], [<String, Object?>{}, 'str']),
        same(undefined),
      );
    });

    test('the hover colors read a resolver through its get trap', () {
      final resolver = createResolver(
        [
          <String, Object?>{
            'barBackgroundColor': '#ff0000',
            'barBorderColor': '#00ff00',
            'barColor': '#0000ff',
          },
        ],
        ['bar', ''],
      );
      final context = attachContext(resolver, <String, Object?>{});
      expect(resolver.containsKey('backgroundColor'), false);
      expect(
        jsCall(defaults['hoverBackgroundColor'], [
          <String, Object?>{},
          resolver,
        ]),
        '#E60000',
      );
      expect(
        jsCall(defaults['hoverBorderColor'], [<String, Object?>{}, context]),
        '#00E600',
      );
      expect(
        jsCall(defaults['hoverColor'], [<String, Object?>{}, resolver]),
        '#0000E6',
      );
    });
  });

  group('set, get, describe, override and apply', () {
    test('merges an array of values objects', () {
      final d = _defaults()
        ..set('v', <Object?>[
          <String, Object?>{'a': 1.0},
          <String, Object?>{'b': 2.0},
        ]);
      expect(_json(d['v']), '{"a":1,"b":2}');
    });

    test('returns the scope object', () {
      final d = _defaults();
      expect(identical(d.set('w'), d['w']), true);
      final root = d.set(<String, Object?>{'rootKey': 1.0});
      expect(identical(root, d), true);
      expect(d['rootKey'], 1.0);
      expect(identical(d.get(''), d), true);
    });

    test('describe and override write the module objects', () {
      _defaults()
        ..describe('dd', <String, Object?>{'_fallback': 'x'})
        ..override('oo', <String, Object?>{'y': 1.0});
      expect(_json(descriptors['dd']), '{"_fallback":"x"}');
      expect(_json(overrides['oo']), '{"y":1}');
      _defaults().describe(<String, Object?>{'_rootDesc': true});
      expect(descriptors['_rootDesc'], true);
    });

    test('apply calls each applier with the instance', () {
      final d = _defaults();
      final calls = <Object?>[];
      d.apply([(x) => calls.add(identical(x, d)), (x) => calls.add(2.0)]);
      expect(calls, [true, 2.0]);
    });
  });

  group('three states', () {
    test('set stores the undefined sentinel and null', () {
      final d = _defaults()
        ..set('u', <String, Object?>{'a': undefined, 'b': null});
      final u = d['u']! as Map<String, Object?>;
      expect(_keys(u), ['a', 'b']);
      expect(_get(u, 'a'), same(undefined));
      expect(_get(u, 'b'), isNull);
      expect(u.containsKey('a'), true);
    });

    test('getScope replaces a falsy value with a new object', () {
      final d = _defaults()
        ..set('k', <String, Object?>{'z': 0.0})
        ..set('k.z', <String, Object?>{'w': 1.0});
      expect(_json(d['k']), '{"z":{"w":1}}');
      d['k2'] = null;
      d.set('k2', <String, Object?>{'w': 1.0});
      expect(_json(d['k2']), '{"w":1}');
      d['k3'] = undefined;
      d.set('k3', <String, Object?>{'w': 1.0});
      expect(_keys(d).skip(_keys(d).length - 3), ['k', 'k2', 'k3']);
      expect(_json(d['k3']), '{"w":1}');
    });

    test('a routed name reads the target for undefined, not for null', () {
      final d = _defaults()
        ..set('c', <String, Object?>{'x': null})
        ..route('c', 'x', '', 'color');
      final c = d['c']! as Map<String, Object?>;
      expect(_get(c, 'x'), isNull);
      c['x'] = undefined;
      expect(_get(c, 'x'), '#666');
      expect(_keys(c), ['x']);
      d['color'] = 'red';
      expect(_get(c, 'x'), 'red');
    });

    test('a routed name keeps a falsy local value', () {
      final d = _defaults()
        ..set('j', <String, Object?>{
          'n': 0.0,
          't': <String, Object?>{'a': 1.0},
        })
        ..route('j', 'n', 'j', 't');
      expect(_get(d['j'], 'n'), 0.0);
    });

    test('set with an undefined value restores the route', () {
      final d = _defaults()
        ..set('a', <String, Object?>{
          'font': <String, Object?>{'size': 10.0},
        })
        ..set('b', <String, Object?>{
          'font': <String, Object?>{'size': 20.0, 'style': 'bold'},
        })
        ..route('a', 'font', 'b', 'font')
        ..set('a', <String, Object?>{'font': undefined});
      expect(_json(_get(d['a'], 'font')), '{"size":20,"style":"bold"}');
    });
  });

  group('route', () {
    /// The scopes `a` and `b` of the probe, with `a.font` routed to `b.font`.
    Defaults routedFont() => _defaults()
      ..set('a', <String, Object?>{
        'font': <String, Object?>{'size': 10.0},
      })
      ..set('b', <String, Object?>{
        'font': <String, Object?>{'size': 20.0, 'style': 'bold'},
      })
      ..route('a', 'font', 'b', 'font');

    test('merges a local object over the target object', () {
      final d = routedFont();
      final a = d['a']! as Map<String, Object?>;
      expect(_json(a['font']), '{"size":10,"style":"bold"}');
      expect(identical(a['font'], a['font']), false);
      expect(_keys(a), ['font']);
    });

    test('set merges into a copy of a routed object', () {
      final d = routedFont()
        ..set('a', <String, Object?>{
          'font': <String, Object?>{'weight': 'bold'},
        });
      final a = d['a']! as RoutedScope;
      expect(_json(a.ownValues['font']), '{"size":10}');
      expect(_json(a['font']), '{"size":10,"style":"bold"}');
    });

    test('a route on the root', () {
      final d = routedFont()..route('', 'rootRouted', 'a', 'font');
      expect(_json(d['rootRouted']), '{"size":10,"style":"bold"}');
    });

    test('a new name comes last, an own name keeps its place', () {
      final d = _defaults()
        ..set('e', <String, Object?>{'p': 1.0, 'q': 2.0})
        ..route('e', 'z', '', 'color')
        ..set('f', <String, Object?>{'p': 1.0, 'z': 5.0, 'q': 2.0})
        ..route('f', 'z', '', 'color');
      expect(_keys(d['e']), ['p', 'q', 'z']);
      expect(_get(d['e'], 'z'), '#666');
      expect((d['e']! as Map<String, Object?>).containsKey('z'), true);
      expect(_keys(d['f']), ['p', 'z', 'q']);
      expect(_get(d['f'], 'z'), 5.0);
    });

    test('merges a string, an array or undefined target as Object.assign', () {
      final d = _defaults()
        ..set('g', <String, Object?>{
          's': 'abc',
          'o': <String, Object?>{'k': 1.0},
        })
        ..route('g', 'o', 'g', 's')
        ..set('h', <String, Object?>{
          'o': <String, Object?>{'k': 1.0},
        })
        ..route('h', 'o', 'h', 'missing')
        ..set('i', <String, Object?>{
          'arr': <Object?>['x', 'y'],
          'o': <String, Object?>{'k': 1.0},
        })
        ..route('i', 'o', 'i', 'arr');
      expect(_json(_get(d['g'], 'o')), '{"0":"a","1":"b","2":"c","k":1}');
      expect(_json(_get(d['h'], 'o')), '{"k":1}');
      expect(_json(_get(d['i'], 'o')), '{"0":"x","1":"y","k":1}');
      d
        ..['color'] = 'red'
        ..set('c', <String, Object?>{'x': null})
        ..route('c', 'x', '', 'color')
        ..set('c', <String, Object?>{
          'x': <String, Object?>{'deep': 1.0},
        });
      expect(
        _json(_get(d['c'], 'x')),
        '{"0":"r","1":"e","2":"d","deep":1}',
      );
    });

    test('a route reads another route', () {
      final d = _defaults()
        ..set('ch1', <String, Object?>{'v': undefined})
        ..set('ch2', <String, Object?>{})
        ..route('ch2', 'v', '', 'color')
        ..route('ch1', 'v', 'ch2', 'v');
      d['color'] = 'red';
      expect(_get(d['ch1'], 'v'), 'red');
      d['color'] = 'blue';
      expect(_get(d['ch1'], 'v'), 'blue');
    });

    test('creates the scope, then the target scope', () {
      final d = _defaults()..route('nr.inner', 'x', 'nt', 'y');
      expect(_keys(d).skip(_keys(d).length - 2), ['nr', 'nt']);
      expect(_json(d['nr']), '{"inner":{"x":"<undefined>"}}');
      expect(_json(d['nt']), '{}');
    });

    test('a copy of a routed scope reads the routes', () {
      final d = _defaults()
        ..set('g', <String, Object?>{
          'o': <String, Object?>{'k': 1.0},
        })
        ..route('g', 'o', '', 'font');
      d['font'] = <String, Object?>{'size': 3.0};
      expect(_json(d['g']), '{"o":{"size":3,"k":1}}');
    });

    test('a new routed name is not configurable', () {
      final d = _defaults()
        ..set('e', <String, Object?>{'p': 1.0})
        ..route('e', 'z', '', 'color');
      expect(() => d.route('e', 'z', '', 'backgroundColor'), _throwsTypeError);
      // The failed route stored the routed value as the local value.
      d['color'] = 'green';
      expect(_get(d['e'], 'z'), '#666');
      expect(
        () => (d['e']! as Map<String, Object?>).remove('z'),
        _throwsTypeError,
      );
      expect(_keys(d['e']), ['p', 'z']);
    });

    test('an own routed name is configurable', () {
      final d = _defaults()
        ..set('f', <String, Object?>{'z': undefined})
        ..route('f', 'z', '', 'color');
      d['color'] = 'green';
      d.route('f', 'z', '', 'backgroundColor');
      final f = d['f']! as RoutedScope;
      expect(f.ownValues['z'], 'green');
      expect(f['z'], 'green');
      f.remove('z');
      f['z'] = 9.0;
      expect(_keys(f), ['z']);
      expect(f['z'], 9.0);
      d.route('f', 'z', '', 'borderColor');
      expect(f.ownValues['z'], 9.0);
      expect(f['z'], 9.0);
      expect(_keys(f), ['z']);
    });

    test('a delete of an own routed name removes it', () {
      final d = _defaults()
        ..set('f', <String, Object?>{'p': 1.0, 'z': 5.0, 'q': 2.0})
        ..route('f', 'z', '', 'color')
        ..route('f', 'z', '', 'backgroundColor');
      expect(_get(d['f'], 'z'), 5.0);
      (d['f']! as Map<String, Object?>).remove('z');
      expect(_keys(d['f']), ['p', 'q']);
      expect(_keys(d.get('f')), ['p', 'q']);
    });

    test('a route on a scope that is not an object throws', () {
      final d = _defaults();
      d['nonobj'] = 5.0;
      expect(() => d.route('nonobj', 'x', '', 'color'), _throwsTypeError);
      // The target scope exists before the throw.
      expect(
        () => d.route('nonobj', 'x', 'newTarget', 'y'),
        _throwsTypeError,
      );
      expect(_json(d['newTarget']), '{}');
    });

    test('a route on a scope that a route reads goes to the owner', () {
      final d = _defaults()
        ..set('t', <String, Object?>{
          'font': <String, Object?>{'size': undefined},
        })
        ..set('p', <String, Object?>{})
        ..route('p', 'font', 't', 'font')
        ..route('p.font', 'size', '', 'color');
      expect(_get(_get(d['t'], 'font'), 'size'), '#666');
      expect(_json(_get(d['p'], 'font')), '{"size":"#666"}');
      expect((d['p']! as RoutedScope).ownValues['font'], same(undefined));
      (d['t']! as Map<String, Object?>)['font'] = <String, Object?>{
        'size': 7.0,
      };
      expect(_json(_get(d['p'], 'font')), '{"size":7}');
      expect(_json(_get(d['t'], 'font')), '{"size":7}');
    });

    test('a route on a routed undefined value goes to the target', () {
      final d = _defaults()
        ..set('a', <String, Object?>{'font': undefined})
        ..set('b', <String, Object?>{
          'font': <String, Object?>{'size': 20.0},
        })
        ..route('a', 'font', 'b', 'font')
        ..route('a.font', 'x', '', 'color');
      expect(_get(_get(d['b'], 'font'), 'x'), '#666');
      expect((d['a']! as RoutedScope).ownValues['font'], same(undefined));
      expect(_json(_get(d['a'], 'font')), '{"size":20,"x":"#666"}');
      expect(_keys(_get(d['b'], 'font')), ['size', 'x']);
      (d['b']! as Map<String, Object?>)['font'] = <String, Object?>{
        'size': 30.0,
      };
      expect(_json(_get(d['a'], 'font')), '{"size":30}');
    });
  });

  group('adapt-defaults-route', () {
    // Pins the difference of the port: a routed scope is a RoutedScope in
    // the place of the plain Map, and the hidden `_<name>` is not a key.
    test('the scope becomes a RoutedScope over the same entries', () {
      final d = _defaults()..set('s', <String, Object?>{'p': 1.0, 'q': 2.0});
      final plain = d['s']! as Map<String, Object?>;
      expect(plain, isNot(isA<RoutedScope>()));
      d.route('s', 'q', '', 'color');
      final routed = d['s']! as RoutedScope;
      expect(identical(routed.ownValues, plain), true);
      expect(_keys(routed), ['p', 'q']);
      expect(routed.containsKey('_q'), false);
      // The Map that the routed scope replaced holds the local values.
      routed['q'] = undefined;
      expect(_get(plain, 'q'), same(undefined));
      expect(routed['q'], '#666');
      expect(identical(d.get('s'), routed), true);
    });

    test('an own key _<name> is not the local value', () {
      final d = _defaults()
        ..set('c', <String, Object?>{'_x': 1.0, 'x': 2.0})
        ..route('c', 'x', '', 'color');
      // Upstream gives {"_x":2,"x":2}.
      expect(_json(d['c']), '{"_x":1,"x":2}');
      (d['c']! as Map<String, Object?>)['_x'] = undefined;
      // Upstream gives '#666'.
      expect(_get(d['c'], 'x'), 2.0);
    });

    test('a route reads the RoutedScope that replaced its target', () {
      final d = _defaults()
        ..set('t', <String, Object?>{'v': undefined})
        ..set('u', <String, Object?>{})
        ..route('u', 'v', 't', 'v')
        ..route('t', 'v', '', 'color');
      expect(_get(d['t'], 'v'), '#666');
      expect(_get(d['u'], 'v'), '#666');
    });
  });

  group('adapt-defaults-scope-object', () {
    // Pins the difference of the port: each node of a scope path is a Map.
    test('a scope path that ends at a string throws', () {
      final d = _defaults();
      d['k4'] = 'str';
      // Upstream returns 'str' for both calls.
      expect(() => d.set('k4', <String, Object?>{'w': 1.0}), _throwsTypeError);
      expect(() => d.get('k4'), _throwsTypeError);
    });

    test('a scope path through a string throws, as upstream', () {
      final d = _defaults();
      d['k4'] = 'str';
      expect(
        () => d.set('k4.x', <String, Object?>{'w': 1.0}),
        _throwsTypeError,
      );
    });

    test('a route on an array scope throws', () {
      final d = _defaults();
      // Upstream routes the array: d.events.x is '#666'.
      expect(() => d.route('events', 'x', '', 'color'), _throwsTypeError);
      expect(_keys(d), isNot(contains('x')));
    });
  });

  group('harness restore', () {
    // setUpSpecs restores the defaults, overrides and descriptors after each
    // test. Each of the two tests first checks the state of the snapshot and
    // then changes the global scopes. In any test order, the second test
    // finds the state that the restore after the first test made.
    late String defaultsJson;
    late String descriptorsJson;
    late Object? ticks;
    late Object? events;
    late Object? animation;

    setUpAll(() {
      defaultsJson = _json(defaults);
      descriptorsJson = _json(descriptors);
      ticks = (defaults['scale']! as Map<String, Object?>)['ticks'];
      events = defaults['events'];
      animation = defaults['animation'];
    });

    void checkSnapshot() {
      expect(_json(defaults), defaultsJson);
      expect(_json(descriptors), descriptorsJson);
      expect(_json(overrides), '{}');
      final scale = defaults['scale']! as Map<String, Object?>;
      expect(identical(scale['ticks'], ticks), true);
      expect(identical(defaults['events'], events), true);
      expect(_get(defaults, 'leak'), same(undefined));
      expect(identical(defaults['animation'], animation), true);
      expect(_get(defaults, 'onHover'), isNull);
      expect(defaults.containsKey('onHover'), true);
      expect(_get(scale['ticks'], 'mirror'), false);
      expect(_keys(defaults['font']), isNot(contains('fallbackFamily')));
      expect(defaults['font'], isNot(isA<RoutedScope>()));
      // The routes of the snapshot still read the root.
      defaults['color'] = 'blue';
      expect(_get(scale['ticks'], 'color'), 'blue');
    }

    void changeScopes() {
      final scale = defaults['scale']! as Map<String, Object?>;
      defaults
        ..set('leak', <String, Object?>{'a': 1.0})
        ..set('font', <String, Object?>{'size': 99.0})
        ..route('font', 'fallbackFamily', '', 'color')
        ..route('scale.ticks', 'mirror', '', 'color')
        ..describe('leak', <String, Object?>{'_fallback': 'x'})
        ..override('leak', <String, Object?>{'b': 2.0});
      defaults['color'] = 'red';
      defaults['animation'] = null;
      defaults.remove('onHover');
      (scale['ticks']! as Map<String, Object?>)['mirror'] = undefined;
      (defaults['events']! as List<Object?>).add('wheel');
      scale['grid'] = <String, Object?>{};
      expect(_get(defaults['font'], 'fallbackFamily'), 'red');
      expect(_get(scale['ticks'], 'mirror'), 'red');
    }

    test('a test finds the snapshot and changes the global scopes', () {
      checkSnapshot();
      changeScopes();
    });

    test('another test finds the snapshot and changes the global scopes', () {
      checkSnapshot();
      changeScopes();
    });
  });
}
