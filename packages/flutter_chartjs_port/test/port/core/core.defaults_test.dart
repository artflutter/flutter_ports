// Original code, not ported from Chart.js: core.defaults cases with no spec.
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter/animation.dart' show Curve;
import 'package:flutter/painting.dart' show TextStyle;
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/core/core.interaction.dart'
    show InteractionMode;
import 'package:flutter_chartjs_port/src/helpers/grace_length.dart'
    show GraceLength;
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show attachContext, createResolver;
import 'package:flutter_chartjs_port/src/helpers/radius_length.dart'
    show RadiusLength;
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/option_scope.dart'
    show OptionScope;
import 'package:flutter_chartjs_port/src/types/chart_axis.dart';
import 'package:flutter_chartjs_port/src/types/chart_text_style.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:test/test.dart';

import '../../support/axis_json.dart';
import '../../support/color_json.dart';
import '../../support/easing_json.dart';
import '../../support/font_record.dart';
import '../../support/keyword_enum_json.dart';
import '../../support/length_json.dart';
import '../../support/mode_json.dart';

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
String _json(Object? value) => referenceColorTokens(_jsonRaw(value));

String _jsonRaw(Object? value) => switch (value) {
  _ when nativeColorBytes(value) != null => jsonEncode(nativeColorBytes(value)),
  null => 'null',
  Undefined() => '"<undefined>"',
  final bool b => b ? 'true' : 'false',
  final double d => jsNumberToString(d),
  num() => throw ArgumentError.value(value, 'value', 'is an int'),
  final String s => jsonEncode(s),
  final TextStyle font => _jsonRaw(fontObjectRecordOf(font)),
  _ when jsIsFunction(value) => '"<fn>"',
  Curve() => curveJson,
  final Object keyword when isKeywordEnum(keyword) => keywordJson(keyword),
  RadiusLength() || GraceLength() => lengthJson,
  ScaleAxis() => axisJson,
  InteractionMode() => modeJson,
  final List<Object?> list => '[${list.map(_json).join(',')}]',
  final Object map when _isObject(map) =>
    '{${jsObjectKeys(map).map((k) => _entry(map, k)).join(',')}}',
  _ => throw ArgumentError.value(value, 'value', 'has no JSON form'),
};

/// Whether [value] is an object: a Map or a typed scope with a face
/// (Chart.js ADR 0054 §5).
bool _isObject(Object? value) =>
    value is Map<String, Object?> || value is JsObjectFace;

/// The JSON member `"key":value` of [key] in [map].
String _entry(Object map, String key) =>
    '${jsonEncode(key)}:${_json(jsGet(map, key))}';

/// The JavaScript property read `object[key]` on an object (a Map or a typed
/// scope): an absent key gives [undefined].
Object? _get(Object? object, String key) {
  if (!_isObject(object)) throw ArgumentError.value(object, 'object');
  return jsGet(object, key);
}

/// `Object.keys(object)`.
List<String> _keys(Object? object) {
  if (!_isObject(object)) throw ArgumentError.value(object, 'object');
  return jsObjectKeys(object);
}

/// The local value of the routed key [name] of the typed scope [scope]: its
/// own cell, without the route (the hidden `_<name>` of
/// core.defaults.js:136-140).
Object? _local(Object? scope, String name) =>
    (scope! as OptionScope).ownCell(name)?.raw;

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
    test('keeps the face of its scope class (nativeFace)', () {
      // Defaults overrides no read, write or key by name: the typed walks of
      // the merge and of the resolvers take it as a scope of its class.
      expect(defaults.nativeFace, isTrue);
      expect(defaults.kind.scopeType, isNot(Defaults));
    });

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
        referenceColorTokens(
          '{"animation":{"delay":"<undefined>","duration":1000,'
          '"easing":"<curve>","fn":"<undefined>","from":"<undefined>",'
          '"loop":"<undefined>","to":"<undefined>","type":"<undefined>"},'
          '"backgroundColor":"rgba(0,0,0,0.1)",'
          '"borderColor":"rgba(0,0,0,0.1)","color":"#666","datasets":{},'
          '"devicePixelRatio":"<fn>","elements":{},'
          '"events":["mousemove","mouseout","click","touchstart","touchmove"],'
          '"font":{"family":"Helvetica '
          'Neue","fallback":["Helvetica","Arial","sans-serif"],"size":12,'
          '"weight":null,"style":"normal","height":1.2},"hover":{},'
          '"hoverBackgroundColor":"<fn>",'
          '"hoverBorderColor":"<fn>","hoverColor":"<fn>","indexAxis":$axisJson,'
          '"interaction":{"mode":"<mode>","intersect":true,'
          '"includeInvisible":false},"maintainAspectRatio":true,'
          '"onHover":null,"onClick":null,"parsing":true,"plugins":{},'
          '"responsive":true,"scale":{"display":true,"offset":false,'
          '"reverse":false,"beginAtZero":false,"bounds":"ticks","clip":true,'
          '"grace":"<length>","grid":{"display":true,"lineWidth":1,'
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
          '{"type":"boolean","easing":"<curve>","fn":"<fn>"}}}},'
          '"layout":{"autoPadding":true,"padding":{"top":0,"right":0,'
          '"bottom":0,"left":0}}}',
        ),
      );
    });

    test('has the upstream descriptors and overrides', () {
      expect(
        _json(descriptors),
        referenceColorTokens(
          '{"_scriptable":"<fn>","_indexable":"<fn>",'
          '"hover":{"_fallback":"interaction"},'
          '"interaction":{"_scriptable":false,"_indexable":false},'
          '"animation":{"_fallback":false,"_indexable":false,'
          '"_scriptable":"<fn>"},"animations":{"_fallback":"animation"},'
          '"scale":{"_fallback":false,"_scriptable":"<fn>",'
          '"_indexable":"<fn>","ticks":{"_scriptable":"<fn>",'
          '"_indexable":"<fn>"}},"scales":{"_fallback":"scale"}}',
        ),
      );
      expect(
        _json(overrides),
        referenceColorTokens('{}'),
      );
      expect(jsCall(descriptors['_scriptable'], ['onClick']), false);
      expect(jsCall(descriptors['_scriptable'], ['color']), true);
      expect(jsCall(descriptors['_indexable'], ['events']), false);
      expect(jsCall(descriptors['_indexable'], ['color']), true);
    });

    test('routes the colors of the scale', () {
      final scale = defaults['scale']! as JsObjectFace;
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
      expect(
        _get(scale['ticks'], 'color'),
        const ui.Color.fromRGBO(102, 102, 102, 1),
      );
      expect(
        _get(scale['grid'], 'color'),
        const ui.Color.fromRGBO(0, 0, 0, 0.1),
      );
      expect(
        _get(scale['border'], 'color'),
        const ui.Color.fromRGBO(0, 0, 0, 0.1),
      );
      expect(
        _get(scale['title'], 'color'),
        const ui.Color.fromRGBO(102, 102, 102, 1),
      );

      defaults['color'] = const ui.Color.fromRGBO(255, 0, 0, 1);
      defaults['borderColor'] = const ui.Color.fromRGBO(0, 0, 255, 1);
      expect(
        _get(scale['ticks'], 'color'),
        const ui.Color.fromRGBO(255, 0, 0, 1),
      );
      expect(
        _get(scale['grid'], 'color'),
        const ui.Color.fromRGBO(0, 0, 255, 1),
      );
      expect(
        _get(scale['border'], 'color'),
        const ui.Color.fromRGBO(0, 0, 255, 1),
      );
      expect(
        _get(scale['title'], 'color'),
        const ui.Color.fromRGBO(255, 0, 0, 1),
      );
    });

    test('calls its function values', () {
      expect(
        jsCall(defaults['hoverBackgroundColor'], [
          <String, Object?>{},
          <String, Object?>{
            'backgroundColor': const ui.Color.fromRGBO(0, 0, 0, 0.1),
          },
        ]),
        const ui.Color.fromRGBO(0, 0, 0, 0.1),
      );
      expect(
        jsCall(defaults['hoverBorderColor'], [
          <String, Object?>{},
          <String, Object?>{
            'borderColor': const ui.Color.fromRGBO(54, 162, 235, 1),
          },
        ]),
        const ui.Color.fromRGBO(5, 155, 255, 1),
      );
      expect(
        jsCall(defaults['hoverColor'], [
          <String, Object?>{},
          <String, Object?>{
            'color': const ui.Color.fromRGBO(102, 102, 102, 1),
          },
        ]),
        const ui.Color.fromRGBO(92, 92, 92, 1),
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
      expect(hover(undefined), same(undefined));
      for (final value in ['', 'nope', 0.0, double.nan, -0.0]) {
        expect(() => hover(value), throwsArgumentError, reason: '$value');
      }
      expect(() => hover('currentColor'), throwsArgumentError);
      expect(
        hover(const ui.Color.fromRGBO(255, 255, 255, 1)),
        const ui.Color.fromRGBO(230, 230, 230, 1),
      );
      expect(
        hover(const ui.Color.fromRGBO(1, 0, 0, 1)),
        const ui.Color.fromRGBO(1, 0, 0, 1),
      );
      expect(
        jsCall(defaults['hoverColor'], [<String, Object?>{}, 'str']),
        same(undefined),
      );
    });

    test('the hover colors read a resolver through its get trap', () {
      final resolver = createResolver(
        [
          <String, Object?>{
            'barBackgroundColor': const ui.Color.fromRGBO(
              255,
              0,
              0,
              1,
            ),
            'barBorderColor': const ui.Color.fromRGBO(0, 255, 0, 1),
            'barColor': const ui.Color.fromRGBO(0, 0, 255, 1),
          },
        ],
        ['bar', ''],
      );
      final context = attachContext(resolver, <String, Object?>{});
      expect(resolver.hasProperty('backgroundColor'), false);
      expect(
        jsCall(defaults['hoverBackgroundColor'], [
          <String, Object?>{},
          resolver,
        ]),
        const ui.Color.fromRGBO(230, 0, 0, 1),
      );
      expect(
        jsCall(defaults['hoverBorderColor'], [<String, Object?>{}, context]),
        const ui.Color.fromRGBO(0, 230, 0, 1),
      );
      expect(
        jsCall(defaults['hoverColor'], [<String, Object?>{}, resolver]),
        const ui.Color.fromRGBO(0, 0, 230, 1),
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
      expect(
        _json(d['v']),
        referenceColorTokens('{"a":1,"b":2}'),
      );
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
      expect(
        _json(descriptors['dd']),
        referenceColorTokens('{"_fallback":"x"}'),
      );
      expect(
        _json(overrides['oo']),
        referenceColorTokens('{"y":1}'),
      );
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
      final u = d['u'];
      expect(_keys(u), ['a', 'b']);
      expect(_get(u, 'a'), same(undefined));
      expect(_get(u, 'b'), isNull);
      expect(jsHasOwn(u, 'a'), true);
    });

    test('getScope replaces a falsy value with a new object', () {
      final d = _defaults()
        ..set('k', <String, Object?>{'z': 0.0})
        ..set('k.z', <String, Object?>{'w': 1.0});
      expect(
        _json(d['k']),
        referenceColorTokens('{"z":{"w":1}}'),
      );
      d['k2'] = null;
      d.set('k2', <String, Object?>{'w': 1.0});
      expect(
        _json(d['k2']),
        referenceColorTokens('{"w":1}'),
      );
      d['k3'] = undefined;
      d.set('k3', <String, Object?>{'w': 1.0});
      expect(_keys(d).skip(_keys(d).length - 3), ['k', 'k2', 'k3']);
      expect(
        _json(d['k3']),
        referenceColorTokens('{"w":1}'),
      );
    });

    test('a routed name reads the target for undefined, not for null', () {
      final d = _defaults()
        ..set('c', <String, Object?>{'x': null})
        ..route('c', 'x', '', 'color');
      final c = d['c'];
      expect(_get(c, 'x'), isNull);
      jsSet(c, 'x', undefined);
      expect(_get(c, 'x'), const ui.Color.fromRGBO(102, 102, 102, 1));
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
      expect(
        _json(_get(d['a'], 'font')),
        referenceColorTokens('{"size":20,"style":"bold"}'),
      );
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
      final a = d['a'];
      expect(
        _json(_get(a, 'font')),
        referenceColorTokens('{"size":10,"style":"bold"}'),
      );
      expect(identical(_get(a, 'font'), _get(a, 'font')), false);
      expect(_keys(a), ['font']);
    });

    test('set merges into a copy of a routed object', () {
      final d = routedFont()
        ..set('a', <String, Object?>{
          'font': <String, Object?>{'weight': 'bold'},
        });
      final a = d['a'];
      expect(
        _json(_local(a, 'font')),
        referenceColorTokens('{"size":10}'),
      );
      expect(
        _json(_get(a, 'font')),
        referenceColorTokens('{"size":10,"style":"bold"}'),
      );
    });

    test('a route on the root', () {
      final d = routedFont()..route('', 'rootRouted', 'a', 'font');
      expect(
        _json(d['rootRouted']),
        referenceColorTokens('{"size":10,"style":"bold"}'),
      );
    });

    test('a new name comes last, an own name keeps its place', () {
      final d = _defaults()
        ..set('e', <String, Object?>{'p': 1.0, 'q': 2.0})
        ..route('e', 'z', '', 'color')
        ..set('f', <String, Object?>{'p': 1.0, 'z': 5.0, 'q': 2.0})
        ..route('f', 'z', '', 'color');
      expect(_keys(d['e']), ['p', 'q', 'z']);
      expect(
        _get(d['e'], 'z'),
        const ui.Color.fromRGBO(102, 102, 102, 1),
      );
      expect(jsHasOwn(d['e'], 'z'), true);
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
      expect(
        _json(_get(d['g'], 'o')),
        referenceColorTokens('{"0":"a","1":"b","2":"c","k":1}'),
      );
      expect(
        _json(_get(d['h'], 'o')),
        referenceColorTokens('{"k":1}'),
      );
      expect(
        _json(_get(d['i'], 'o')),
        referenceColorTokens('{"0":"x","1":"y","k":1}'),
      );
      d
        ..['color'] = 'red'
        ..set('c', <String, Object?>{'x': null})
        ..route('c', 'x', '', 'color')
        ..set('c', <String, Object?>{
          'x': <String, Object?>{'deep': 1.0},
        });
      expect(
        _json(_get(d['c'], 'x')),
        referenceColorTokens('{"0":"r","1":"e","2":"d","deep":1}'),
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
      expect(
        _json(d['nr']),
        referenceColorTokens('{"inner":{"x":"<undefined>"}}'),
      );
      expect(
        _json(d['nt']),
        referenceColorTokens('{}'),
      );
    });

    test('a copy of a routed scope reads the routes', () {
      final d = _defaults()
        ..set('g', <String, Object?>{
          'o': <String, Object?>{'k': 1.0},
        })
        ..route('g', 'o', '', 'font');
      d['font'] = <String, Object?>{'size': 3.0};
      expect(
        _json(d['g']),
        referenceColorTokens('{"o":{"size":3,"k":1}}'),
      );
    });

    test('a new routed name is not configurable', () {
      final d = _defaults()
        ..set('e', <String, Object?>{'p': 1.0})
        ..route('e', 'z', '', 'color');
      expect(() => d.route('e', 'z', '', 'backgroundColor'), _throwsTypeError);
      // The failed route stored the routed value as the local value.
      d['color'] = 'green';
      expect(
        _get(d['e'], 'z'),
        const ui.Color.fromRGBO(102, 102, 102, 1),
      );
      expect(
        () => jsDeleteKey(d['e'], 'z'),
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
      final f = d['f']! as JsObjectFace;
      expect(_local(f, 'z'), 'green');
      expect(f['z'], 'green');
      f.jsDelete('z');
      f['z'] = 9.0;
      expect(_keys(f), ['z']);
      expect(f['z'], 9.0);
      d.route('f', 'z', '', 'borderColor');
      expect(_local(f, 'z'), 9.0);
      expect(f['z'], 9.0);
      expect(_keys(f), ['z']);
    });

    test('a delete of an own routed name removes it', () {
      final d = _defaults()
        ..set('f', <String, Object?>{'p': 1.0, 'z': 5.0, 'q': 2.0})
        ..route('f', 'z', '', 'color')
        ..route('f', 'z', '', 'backgroundColor');
      expect(_get(d['f'], 'z'), 5.0);
      jsDeleteKey(d['f'], 'z');
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
      expect(
        _json(d['newTarget']),
        referenceColorTokens('{}'),
      );
    });

    test('a route on a scope that a route reads goes to the owner', () {
      final d = _defaults()
        ..set('t', <String, Object?>{
          'font': <String, Object?>{'size': undefined},
        })
        ..set('p', <String, Object?>{})
        ..route('p', 'font', 't', 'font')
        ..route('p.font', 'size', '', 'color');
      expect(
        _get(_get(d['t'], 'font'), 'size'),
        const ui.Color.fromRGBO(102, 102, 102, 1),
      );
      expect(
        _json(_get(d['p'], 'font')),
        referenceColorTokens('{"size":"#666"}'),
      );
      expect(_local(d['p'], 'font'), same(undefined));
      jsSet(d['t'], 'font', <String, Object?>{
        'size': 7.0,
      });
      expect(
        _json(_get(d['p'], 'font')),
        referenceColorTokens('{"size":7}'),
      );
      expect(
        _json(_get(d['t'], 'font')),
        referenceColorTokens('{"size":7}'),
      );
    });

    test('a route on a routed undefined value goes to the target', () {
      final d = _defaults()
        ..set('a', <String, Object?>{'font': undefined})
        ..set('b', <String, Object?>{
          'font': <String, Object?>{'size': 20.0},
        })
        ..route('a', 'font', 'b', 'font')
        ..route('a.font', 'x', '', 'color');
      expect(
        _get(_get(d['b'], 'font'), 'x'),
        const ui.Color.fromRGBO(102, 102, 102, 1),
      );
      expect(_local(d['a'], 'font'), same(undefined));
      expect(
        _json(_get(d['a'], 'font')),
        referenceColorTokens('{"size":20,"x":"#666"}'),
      );
      expect(_keys(_get(d['b'], 'font')), ['size', 'x']);
      jsSet(d['b'], 'font', <String, Object?>{
        'size': 30.0,
      });
      expect(
        _json(_get(d['a'], 'font')),
        referenceColorTokens('{"size":30}'),
      );
    });
  });

  group('adapt-text-style-fonts', () {
    // A font is a ChartTextStyle (Chart.js ADR 0116): a route merges its
    // local font over the font of its target with TextStyle.merge, as
    // core.defaults.js:144-153 merges a local font object.
    test('a route merges a local font over the target font', () {
      final d = _defaults()
        ..set('a', <String, Object?>{
          'font': const ChartTextStyle(fontSize: 10),
        })
        ..set('b', <String, Object?>{
          'font': const ChartTextStyle(
            fontSize: 20,
            fontStyle: ui.FontStyle.italic,
          ),
        })
        ..route('a', 'font', 'b', 'font');
      expect(
        _get(d['a'], 'font'),
        const ChartTextStyle(fontSize: 10, fontStyle: ui.FontStyle.italic),
      );
    });

    test('a route without a local font gives the target font', () {
      const target = ChartTextStyle(fontSize: 20);
      final d = _defaults()
        ..set('a', <String, Object?>{})
        ..set('b', <String, Object?>{'font': target})
        ..route('a', 'font', 'b', 'font');
      expect(_get(d['a'], 'font'), same(target));
    });
  });

  group('adapt-defaults-route', () {
    // Pins the difference of the port: a route on a raw Map scope puts a
    // typed scope with the same keys, values and order in the place of the
    // Map, and the hidden `_<name>` is not a key.
    test('the scope becomes a typed scope over the same entries', () {
      final d = _defaults()..set('s', <String, Object?>{'p': 1.0, 'q': 2.0});
      final plain = d['s']! as Map<String, Object?>;
      d.route('s', 'q', '', 'color');
      final routed = d['s']! as OptionScope;
      expect(identical(routed, plain), false);
      expect(_keys(routed), ['p', 'q']);
      expect(routed.jsHas('_q'), false);
      // The typed scope holds the local values; the Map that it replaced
      // keeps its entries and has no route.
      routed['q'] = undefined;
      expect(_get(plain, 'q'), 2.0);
      expect(_local(routed, 'q'), same(undefined));
      expect(routed['q'], const ui.Color.fromRGBO(102, 102, 102, 1));
      expect(identical(d.get('s'), routed), true);
    });

    test('an own key _<name> is not the local value', () {
      final d = _defaults()
        ..set('c', <String, Object?>{'_x': 1.0, 'x': 2.0})
        ..route('c', 'x', '', 'color');
      // Upstream gives {"_x":2,"x":2}.
      expect(
        _json(d['c']),
        referenceColorTokens('{"_x":1,"x":2}'),
      );
      jsSet(d['c'], '_x', undefined);
      // Upstream gives '#666'.
      expect(_get(d['c'], 'x'), 2.0);
    });

    test('a route reads the typed scope that replaced its target', () {
      final d = _defaults()
        ..set('t', <String, Object?>{'v': undefined})
        ..set('u', <String, Object?>{})
        ..route('u', 'v', 't', 'v')
        ..route('t', 'v', '', 'color');
      expect(
        _get(d['t'], 'v'),
        const ui.Color.fromRGBO(102, 102, 102, 1),
      );
      expect(
        _get(d['u'], 'v'),
        const ui.Color.fromRGBO(102, 102, 102, 1),
      );
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
      ticks = (defaults['scale']! as JsObjectFace)['ticks'];
      events = defaults['events'];
      animation = defaults['animation'];
    });

    void checkSnapshot() {
      expect(_json(defaults), defaultsJson);
      expect(_json(descriptors), descriptorsJson);
      expect(
        _json(overrides),
        referenceColorTokens('{}'),
      );
      final scale = defaults['scale']! as JsObjectFace;
      expect(identical(scale['ticks'], ticks), true);
      expect(identical(defaults['events'], events), true);
      expect(_get(defaults, 'leak'), same(undefined));
      expect(identical(defaults['animation'], animation), true);
      expect(_get(defaults, 'onHover'), isNull);
      expect(defaults.jsHas('onHover'), true);
      expect(_get(scale['ticks'], 'mirror'), false);
      // A font is a ChartTextStyle (Chart.js ADR 0116).
      expect(defaults['font'], isA<ChartTextStyle>());
      expect((defaults['font']! as TextStyle).fontSize, 12);
      // The routes of the snapshot still read the root.
      defaults['color'] = const ui.Color.fromRGBO(0, 0, 255, 1);
      expect(
        _get(scale['ticks'], 'color'),
        const ui.Color.fromRGBO(0, 0, 255, 1),
      );
    }

    void changeScopes() {
      final scale = defaults['scale']! as JsObjectFace;
      defaults
        ..set('leak', <String, Object?>{'a': 1.0})
        ..route('scale.ticks', 'mirror', '', 'color')
        ..describe('leak', <String, Object?>{'_fallback': 'x'})
        ..override('leak', <String, Object?>{'b': 2.0});
      defaults['color'] = 'red';
      defaults['font'] = const ChartTextStyle(fontSize: 99);
      defaults['animation'] = null;
      defaults.jsDelete('onHover');
      (scale['ticks']! as JsObjectFace)['mirror'] = undefined;
      (defaults['events']! as List<Object?>).add('wheel');
      scale['grid'] = <String, Object?>{};
      expect((defaults['font']! as TextStyle).fontSize, 99);
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
