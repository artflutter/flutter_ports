// Original code, not ported from Chart.js: element.arc cases with no spec.
import 'dart:math' as math;

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs/src/canvas/canvas.dart';
import 'package:flutter_chartjs/src/core/core.element.dart';
import 'package:flutter_chartjs/src/elements/element.arc.dart';
import 'package:flutter_chartjs/src/elements/element_options.dart';
import 'package:flutter_chartjs/src/js/js_class.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/types/animation.dart' as types;
import 'package:flutter_chartjs/src/types/basic.dart';
import 'package:flutter_chartjs/src/types/geometric.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;
import 'package:test/test.dart';

import 'arc_reference.dart';

// The spec element.arc.tests.js tests inRange, getCenterPoint and two draw
// cases that count the calls. These tests cover the rest of
// src/elements/element.arc.ts and the element design of Chart.js ADR 0017
// for ArcElement:
// - the properties, the access by name and the statics;
// - inRange at the edges of the angles and the radii, with a full
//   circumference, equal angles, an undefined circumference
//   (valueOrDefault) and NaN, and with animations;
// - getCenterPoint and tooltipPosition with offset, spacing and animations;
// - the calls of draw: full circles, the inner border (clipArc), the border
//   joins and selfJoin (clipSelf), spacing and offset (pathArc), the border
//   radius (parseBorderRadius), circular false and the border dash.
// The expected results come from arc_reference.dart, which
// tool/reference/arc_reference.mjs writes from the pinned element.arc.ts and
// the mock context of chartjs-test-utils in Node.js v24.12.0 on x64. Each
// reference case runs twice (Chart.js ADR 0018, section 6): with the plain
// Map options of the reference, and with an ArcOptions with the same
// entries. Both compare with the same reference data.

/// A test animation with the two members that getProps reads.
final class _Animation implements types.Animation {
  const _Animation(this.to, {required this._active});

  final bool _active;

  @override
  bool active() => _active;

  @override
  final Object? to;
}

/// The canvas of [_CanvasContext]: the size that `clipSelf` reads.
final class _Canvas implements HTMLCanvasElement {
  _Canvas(this.width, this.height);

  @override
  int width;

  @override
  int height;

  @override
  CSSStyleDeclaration get style => throw UnimplementedError();

  @override
  CanvasRenderingContext2D? getContext(String contextId) =>
      throw UnimplementedError();

  @override
  String? getAttribute(String name) => throw UnimplementedError();

  @override
  void setAttribute(String name, String value) => throw UnimplementedError();

  @override
  void removeAttribute(String name) => throw UnimplementedError();
}

/// A [MockContext] with a canvas. `clipSelf` reads `ctx.canvas.width` and
/// `ctx.canvas.height`. The mock context of chartjs-test-utils has no
/// canvas, in JavaScript and in Dart. The reference generator gives the
/// upstream mock the same canvas.
final class _CanvasContext extends MockContext {
  _CanvasContext()
    : canvas = _Canvas(arcReferenceCanvasWidth, arcReferenceCanvasHeight);

  @override
  final HTMLCanvasElement canvas;
}

/// [options] as they are: the plain Map form of the options.
AnyObject _plainOptions(AnyObject options) => options;

/// The two forms of the options of an arc (Chart.js ADR 0018, section 6):
/// the plain Map, and an [ArcOptions] with the same entries in the same key
/// order.
const Map<String, AnyObject Function(AnyObject options)> _optionsForms = {
  'Map options': _plainOptions,
  'ArcOptions': ArcOptions.new,
};

/// [cfg] with its `options` Map in the form [form].
AnyObject _withOptions(AnyObject cfg, AnyObject Function(AnyObject) form) => {
  for (final MapEntry(:key, :value) in cfg.entries)
    key: key == 'options' && value is AnyObject ? form(value) : value,
};

/// `new ArcElement(cfg)` with the animations of a reference case as
/// `$animations`, and the options of [cfg] in the form [form].
ArcElement _arc(
  Map<String, Object?> cfg, [
  Map<String, ArcReferenceAnimation> animations = const {},
  AnyObject Function(AnyObject) form = _plainOptions,
]) {
  final arc = ArcElement(_withOptions(cfg, form));
  if (animations.isNotEmpty) {
    arc.$animations = {
      for (final MapEntry(:key, :value) in animations.entries)
        key: _Animation(value.to, active: value.active),
    };
  }
  return arc;
}

/// Expects that [actual] is [expected]: a number within 1e-9 (relative
/// above 1), NaN for NaN, a list item by item, and any other value equal.
///
/// The reference numbers are V8 numbers. `dart:math` `sin` and `cos` can
/// differ in the last bit on other engines (Chart.js ADR 0010).
void _expectValue(Object? actual, Object? expected, String where) {
  switch (expected) {
    case final num n when n.isNaN:
      expect(actual, isA<double>().having((v) => v.isNaN, 'isNaN', isTrue));
    case final num n when n.isInfinite:
      expect(actual, n, reason: where);
    case final num n:
      expect(actual, closeTo(n, 1e-9 * math.max(1, n.abs())), reason: where);
    case final List<Object?> list:
      expect(actual, isA<List<Object?>>(), reason: where);
      final items = actual! as List<Object?>;
      expect(items, hasLength(list.length), reason: where);
      for (var i = 0; i < list.length; i++) {
        _expectValue(items[i], list[i], '$where[$i]');
      }
    default:
      expect(actual, expected, reason: where);
  }
}

/// Expects that the recorded [calls] are the [expected] calls: the same
/// names, and the arguments as [_expectValue] compares them.
void _expectCalls(
  List<ContextCall> calls,
  List<(String, List<Object?>)> expected,
) {
  expect(
    [for (final call in calls) call['name']],
    [for (final (name, _) in expected) name],
  );
  for (var i = 0; i < expected.length; i++) {
    final (name, args) = expected[i];
    _expectValue(calls[i]['args'], args, 'call $i ($name)');
  }
}

/// The options of every draw test that does not come from the reference.
Map<String, Object?> _options([Map<String, Object?> extra = const {}]) => {
  'backgroundColor': 'red',
  'borderColor': 'blue',
  'borderWidth': 2,
  ...extra,
};

/// An arc for the draw tests that do not come from the reference.
ArcElement _drawArc([Map<String, Object?> extra = const {}]) => ArcElement({
  'x': 50,
  'y': 40,
  'startAngle': 0.25,
  'endAngle': 2,
  'innerRadius': 10,
  'outerRadius': 30,
  'options': _options(extra),
});

/// The recorded calls named [name].
List<ContextCall> _named(MockContext ctx, String name) => [
  for (final call in ctx.getCalls())
    if (call['name'] == name) call,
];

final Matcher _isUndefined = same(undefined);

void main() {
  setUpSpecs();

  group('properties', () {
    test('a new arc has the upstream start values', () {
      final arc = ArcElement();
      expect(arc.circumference, isNaN);
      expect(arc.startAngle, isNaN);
      expect(arc.endAngle, isNaN);
      expect(arc.innerRadius, isNaN);
      expect(arc.outerRadius, isNaN);
      expect(arc.pixelMargin, 0);
      expect(arc.fullCircles, 0);
      expect(arc.options, isNull);
      expect(arc.active, isFalse);
      for (final name in [
        'circumference',
        'startAngle',
        'endAngle',
        'innerRadius',
        'outerRadius',
        'options',
        'x',
        'y',
        r'$animations',
      ]) {
        expect(arc[name], _isUndefined, reason: name);
      }
      expect(arc['pixelMargin'], 0.0);
      expect(arc['fullCircles'], 0.0);
    });

    test('the constructor writes each key of cfg by name', () {
      final options = <String, Object?>{'borderWidth': 1};
      final arc = ArcElement({
        'circumference': 1,
        'startAngle': 2,
        'endAngle': 3,
        'innerRadius': 4,
        'outerRadius': 5,
        'pixelMargin': 6,
        'fullCircles': 7,
        'x': 8,
        'y': 9,
        'options': options,
        r'$context': 'extra',
      });
      expect(arc.circumference, 1.0);
      expect(arc.startAngle, 2.0);
      expect(arc.endAngle, 3.0);
      expect(arc.innerRadius, 4.0);
      expect(arc.outerRadius, 5.0);
      expect(arc.pixelMargin, 6.0);
      expect(arc.fullCircles, 7.0);
      expect(arc.x, 8.0);
      expect(arc.y, 9.0);
      expect(arc.options, same(options));
      expect(arc[r'$context'], 'extra');
      for (final name in [
        'circumference',
        'startAngle',
        'endAngle',
        'innerRadius',
        'outerRadius',
        'pixelMargin',
        'fullCircles',
      ]) {
        expect(arc[name], isA<double>(), reason: name);
      }
    });

    test('a write by name of undefined restores the undefined state', () {
      final arc = ArcElement({'pixelMargin': 1, 'circumference': 2});
      arc['pixelMargin'] = undefined;
      arc['circumference'] = undefined;
      expect(arc.pixelMargin, isNaN);
      expect(arc['pixelMargin'], _isUndefined);
      expect(arc.circumference, isNaN);
      expect(arc['circumference'], _isUndefined);
    });

    test('NaN is a value, not the undefined state', () {
      final arc = ArcElement({'circumference': double.nan});
      expect(arc.circumference, isNaN);
      expect(arc['circumference'], isA<double>());
    });

    test('a write by name of a value that is not a number throws', () {
      for (final name in [
        'circumference',
        'startAngle',
        'endAngle',
        'innerRadius',
        'outerRadius',
        'pixelMargin',
        'fullCircles',
      ]) {
        final arc = ArcElement();
        for (final value in <Object?>[null, '1', true, <String, Object?>{}]) {
          expect(
            () => arc[name] = value,
            throwsArgumentError,
            reason: '$name = $value',
          );
        }
      }
    });

    test('the setters write the typed members', () {
      final arc = ArcElement()
        ..circumference = 1
        ..startAngle = 2
        ..endAngle = 3
        ..innerRadius = 4
        ..outerRadius = 5
        ..pixelMargin = 6
        ..fullCircles = 7;
      expect(arc['circumference'], 1.0);
      expect(arc['startAngle'], 2.0);
      expect(arc['endAngle'], 3.0);
      expect(arc['innerRadius'], 4.0);
      expect(arc['outerRadius'], 5.0);
      expect(arc['pixelMargin'], 6.0);
      expect(arc['fullCircles'], 7.0);
    });

    test('is an Element, an ArcProps, a VisualElement and a Point', () {
      final arc = ArcElement();
      expect(arc, isA<Element>());
      expect(arc, isA<ArcProps>());
      expect(arc, isA<types.VisualElement>());
      expect(arc, isA<types.Element>());
      expect(arc, isA<Point>());
    });

    test('inXRange and inYRange are false', () {
      // Upstream ArcElement has no inXRange and no inYRange. The one caller,
      // getAxisItems (core.interaction.js:234), tests the method first.
      final arc = ArcElement({
        'x': 0,
        'y': 0,
        'startAngle': 0,
        'endAngle': 7,
        'innerRadius': 0,
        'outerRadius': 10,
        'options': <String, Object?>{'spacing': 0, 'borderWidth': 0},
      });
      expect(arc.inRange(1, 1), isTrue);
      expect(arc.inXRange(1), isFalse);
      expect(arc.inYRange(1, true), isFalse);
    });
  });

  group('statics', () {
    test('id', () {
      expect(ArcElement.id, 'arc');
    });

    test('defaults have the upstream keys, values and order', () {
      expect(ArcElement.defaults.keys, [
        'borderAlign',
        'borderColor',
        'borderDash',
        'borderDashOffset',
        'borderJoinStyle',
        'borderRadius',
        'borderWidth',
        'offset',
        'spacing',
        'angle',
        'circular',
        'selfJoin',
      ]);
      expect(ArcElement.defaults, {
        'borderAlign': 'center',
        'borderColor': '#fff',
        'borderDash': isEmpty,
        'borderDashOffset': 0.0,
        'borderJoinStyle': _isUndefined,
        'borderRadius': 0.0,
        'borderWidth': 2.0,
        'offset': 0.0,
        'spacing': 0.0,
        'angle': _isUndefined,
        'circular': true,
        'selfJoin': false,
      });
    });

    test('defaultRoutes', () {
      expect(ArcElement.defaultRoutes, {'backgroundColor': 'backgroundColor'});
    });

    test('descriptors', () {
      expect(ArcElement.descriptors.keys, ['_scriptable', '_indexable']);
      expect(ArcElement.descriptors['_scriptable'], isTrue);
      final indexable =
          ArcElement.descriptors['_indexable']! as bool Function(String);
      expect(indexable('borderDash'), isFalse);
      expect(indexable('borderWidth'), isTrue);
      expect(indexable('backgroundColor'), isTrue);
    });

    test('jsClass is ArcElement as a value', () {
      // From element.arc.ts in Node.js v24.12.0 on x64: the own statics of
      // ArcElement are id, defaults, defaultRoutes and descriptors, and its
      // superclass is Element. typeof ArcElement is 'function'.
      final c = ArcElement.jsClass;
      expect(c.name, 'ArcElement');
      expect(c.superclass, same(Element.jsClass));
      expect(c.id, 'arc');
      expect(c['id'], ArcElement.id);
      expect(c['defaults'], same(ArcElement.defaults));
      expect(c['defaultRoutes'], same(ArcElement.defaultRoutes));
      expect(c['descriptors'], same(ArcElement.descriptors));
      expect(c.isSubclassOf(Element.jsClass), isTrue);
      expect(c.isSubclassOf(c), isFalse);
    });

    test('jsConstruct of jsClass makes a ArcElement with the cfg', () {
      // new ArcElement({x: 2}) and new ArcElement() (Chart.js ADR 0020,
      // section 3).
      final element = jsConstruct(ArcElement.jsClass, [
        <String, Object?>{'x': 2},
      ]);
      expect(element, isA<ArcElement>());
      expect((element as ArcElement)['x'], 2.0);
      expect(jsConstruct(ArcElement.jsClass, const []), isA<ArcElement>());
      // class My extends ArcElement { static id = 'my'; }: the subclass value
      // constructs a ArcElement and reads the statics of ArcElement.
      final my = JsClass('My', superclass: ArcElement.jsClass)..['id'] = 'my';
      expect(jsConstruct(my, const []), isA<ArcElement>());
      expect(my.id, 'my');
      expect(ArcElement.jsClass.id, 'arc');
      expect(my['defaults'], same(ArcElement.defaults));
    });
  });

  group('inRange', () {
    test('has the reference of Node.js v24.12.0 on x64', () {
      expect(arcReferenceNode, 'v24.12.0');
      expect(arcReferenceArch, 'x64');
      expect(arcInRangeReference, hasLength(55));
    });

    for (final MapEntry(key: name, value: form) in _optionsForms.entries) {
      group(name, () {
        for (final c in arcInRangeReference) {
          test(c.name, () {
            final arc = _arc(c.cfg, c.animations, form);
            expect(
              arc.inRange(c.chartX, c.chartY, c.useFinalPosition),
              c.result,
            );
          });
        }
      });
    }

    test('throws a TypeError when options is undefined', () {
      final arc = ArcElement({
        'x': 0,
        'y': 0,
        'startAngle': 0,
        'endAngle': 1,
        'innerRadius': 0,
        'outerRadius': 10,
      });
      expect(() => arc.inRange(1, 1), throwsA(isA<TypeError>()));
    });
  });

  group('getCenterPoint', () {
    test('has the reference of Node.js v24.12.0 on x64', () {
      expect(arcCenterReference, hasLength(11));
    });

    for (final MapEntry(key: name, value: form) in _optionsForms.entries) {
      group(name, () {
        for (final c in arcCenterReference) {
          test(c.name, () {
            final arc = _arc(c.cfg, c.animations, form);
            final center = arc.getCenterPoint(c.useFinalPosition);
            _expectValue(center.x, c.x, 'x');
            _expectValue(center.y, c.y, 'y');
            expect(arc.tooltipPosition(c.useFinalPosition), center);
          });
        }
      });
    }

    test('tooltipPosition without an argument is the current position', () {
      final arc = _arc(arcCenterReference.last.cfg, {
        'x': const (active: true, to: 100),
      });
      expect(arc.tooltipPosition(), arc.getCenterPoint(false));
      expect(arc.tooltipPosition(), isNot(arc.getCenterPoint(true)));
    });

    test('throws a TypeError when options is undefined', () {
      final arc = ArcElement({'x': 0, 'y': 0});
      expect(arc.getCenterPoint, throwsA(isA<TypeError>()));
      expect(arc.tooltipPosition, throwsA(isA<TypeError>()));
    });
  });

  group('draw', () {
    test('has the reference of Node.js v24.12.0 on x64', () {
      expect(arcDrawReference, hasLength(54));
    });

    for (final MapEntry(key: name, value: form) in _optionsForms.entries) {
      group(name, () {
        for (final c in arcDrawReference) {
          test(c.name, () {
            final arc = _arc(c.cfg, const {}, form);
            final ctx = _CanvasContext();
            arc.draw(ctx);
            _expectCalls(ctx.getCalls(), c.calls);
            expect(arc.pixelMargin, c.pixelMargin);
            expect(arc.fullCircles, c.fullCircles);
          });
        }
      });
    }

    test('ignores the area', () {
      final withArea = _CanvasContext();
      final withoutArea = _CanvasContext();
      _drawArc().draw(withArea, _Area());
      _drawArc().draw(withoutArea);
      expect(withArea.getCalls(), withoutArea.getCalls());
    });

    test('throws a TypeError when options is undefined', () {
      final arc = ArcElement({'circumference': 1});
      final ctx = _CanvasContext();
      expect(() => arc.draw(ctx), throwsA(isA<TypeError>()));
      expect(ctx.getCalls(), isEmpty);
    });

    test('selfJoin reads ctx.canvas, which the mock context lacks', () {
      // Upstream gets a TypeError from the mock context of chartjs-test-utils
      // at `ctx.canvas.width` (element.arc.ts:35).
      final arc = _drawArc({'selfJoin': true, 'borderRadius': 0})..endAngle = 4;
      expect(() => arc.draw(createMockContext()), throwsUnsupportedError);
    });

    test('a borderDash List<double> is the argument itself', () {
      final dash = <double>[4, 2];
      final ctx = _CanvasContext();
      _drawArc({'borderDash': dash}).draw(ctx);
      final args = _named(ctx, 'setLineDash').single['args']! as List<Object?>;
      expect(args.single, same(dash));
    });

    test('a borderDash List of int becomes a List<double>', () {
      final ctx = _CanvasContext();
      _drawArc({
        'borderDash': const [4, 2],
      }).draw(ctx);
      final args = _named(ctx, 'setLineDash').single['args']! as List<Object?>;
      expect(
        args.single,
        isA<List<double>>().having((l) => l, 'items', [4, 2]),
      );
    });

    test('a borderDash that is not a list throws a TypeError', () {
      final ctx = _CanvasContext();
      expect(
        () => _drawArc({'borderDash': 5}).draw(ctx),
        throwsA(isA<TypeError>()),
      );
    });

    test('a JS null borderDashOffset sets 0, the ToNumber of the setter', () {
      // The DOM setter converts null to 0. The JS mock records null.
      final ctx = _CanvasContext();
      _drawArc({'borderDashOffset': null}).draw(ctx);
      expect(_named(ctx, 'setLineDashOffset').single['args'], [0.0]);
    });

    test('a borderJoinStyle that is not a string is its ToString', () {
      // The DOM setter converts the value with ToString and ignores a value
      // that is not a join. The JS mock records the value itself.
      final ctx = _CanvasContext();
      _drawArc({'borderJoinStyle': 5}).draw(ctx);
      expect(_named(ctx, 'setLineJoin').single['args'], ['5']);
    });

    test('a numeric option that is a string is its ToNumber', () {
      final ctx = _CanvasContext();
      _drawArc({'borderWidth': '3', 'borderAlign': 'inner'}).draw(ctx);
      expect(_named(ctx, 'setLineWidth').single['args'], [6.0]);
    });

    test('the center does not move after a draw', () {
      final arc = _drawArc({'offset': 8, 'spacing': 4});
      final before = arc.getCenterPoint();
      arc.draw(_CanvasContext());
      expect(arc.getCenterPoint(), before);
    });
  });
}

/// An area for [ArcElement.draw], which ignores it.
final class _Area implements ChartArea {
  @override
  double get left => 0;

  @override
  double get top => 0;

  @override
  double get right => 100;

  @override
  double get bottom => 100;

  @override
  double get width => 100;

  @override
  double get height => 100;
}
