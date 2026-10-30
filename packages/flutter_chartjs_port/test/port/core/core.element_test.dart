// Original code, not ported from Chart.js: core.element cases with no spec.
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ScriptableContext;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/animated_prop.dart';
import 'package:flutter_chartjs_port/src/types/animation.dart' as types;
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:test/test.dart';

// The spec core.element.tests.js tests only getProps with x and y. These
// tests cover the element design of Chart.js ADR 0017: the undefined state,
// the access by name, the subclass protocol, both branches of getProps,
// tooltipPosition, hasValue, the statics and ElementPoint. The upstream
// results come from a run of src/core/core.element.ts in Node.js v24.12.0
// (V8 13.6) on x64, with type stripping: a new Element has the own keys x,
// y, active, options and $animations, tooltipPosition() of a new Element
// gives {x: undefined, y: undefined}, getProps with an empty $animations
// object and final true gives a new object, and hasValue is false for NaN
// and Infinity and true for 0, -0 and '5'.

/// A test animation with the two members that getProps reads.
final class _Animation implements types.Animation {
  _Animation(this.to, {this._active = true});

  final bool _active;

  @override
  bool active() => _active;

  @override
  final Object? to;
}

/// A subclass that follows the protocol of the Element doc: a numeric, a
/// boolean and an object property, each with the access by name.
final class _Box extends Element {
  _Box([AnyObject? cfg]) {
    if (cfg != null) assign(cfg);
  }

  double? _width;
  bool? _horizontal;
  List<String>? _labels;

  /// A boolean with a start value, which upstream never sets to undefined.
  bool animated = true;

  double get width => _width ?? double.nan;
  set width(double value) => _width = value;

  bool? get horizontal => _horizontal;
  set horizontal(bool value) => _horizontal = value;

  List<String>? get labels => _labels;
  set labels(List<String> value) => _labels = value;

  @override
  Object? operator [](String prop) => switch (prop) {
    'width' => _width ?? undefined,
    'horizontal' => _horizontal ?? undefined,
    'labels' => _labels ?? undefined,
    'animated' => animated,
    _ => super[prop],
  };

  @override
  void operator []=(String prop, Object? value) {
    switch (prop) {
      case 'width':
        _width = toNumberProp(prop, value);
      case 'horizontal':
        _horizontal = toBoolProp(prop, value);
      case 'labels':
        _labels = toObjectProp<List<String>>(prop, value);
      case 'animated':
        animated = toDefinedBoolProp(prop, value);
      default:
        super[prop] = value;
    }
  }
}

final Matcher _isUndefined = same(undefined);

void main() {
  // The typed property API of Chart.js ADR 0054 §9.
  group('markUndefined', () {
    test('puts a property into the undefined state', () {
      final element = Element()
        ..x = 1
        ..y = 2;
      expect(element.isUndefined(AnimatedProp.x), isFalse);
      element.markUndefined(AnimatedProp.x);
      expect(element.isUndefined(AnimatedProp.x), isTrue);
      expect(element['x'], same(undefined));
      expect(element.x, isNaN);
      expect(element.y, 2);
      expect(element.isUndefined(const AnimatedProp.custom('foo')), isTrue);
    });
  });

  // The id constants of the typed switches match the ids of AnimatedProp.
  test('the id constants are the ids of AnimatedProp', () {
    expect(animatedPropX, AnimatedProp.x.id);
    expect(animatedPropY, AnimatedProp.y.id);
    expect(animatedPropBase, AnimatedProp.base.id);
    expect(animatedPropWidth, AnimatedProp.width.id);
    expect(animatedPropHeight, AnimatedProp.height.id);
    expect(animatedPropCircumference, AnimatedProp.circumference.id);
    expect(animatedPropEndAngle, AnimatedProp.endAngle.id);
    expect(animatedPropInnerRadius, AnimatedProp.innerRadius.id);
    expect(animatedPropOuterRadius, AnimatedProp.outerRadius.id);
    expect(animatedPropStartAngle, AnimatedProp.startAngle.id);
  });

  group(r'$context', () {
    test('the typed read gives a ScriptableContext only', () {
      final context = ScriptableContext(null)..['type'] = 'data';
      final elem = Element();
      expect(elem.$context, isNull);
      elem.$context = context;
      expect(elem.$context, same(context));
      expect(elem[r'$context'], same(context));
      elem[r'$context'] = 'ctx';
      expect(elem.$context, isNull);
      expect(elem[r'$context'], 'ctx');
      elem[r'$context'] = undefined;
      expect(elem[r'$context'], _isUndefined);
    });
  });

  group('undefined state', () {
    test('a new element has the upstream start values', () {
      final elem = Element();
      expect(elem.x, isNaN);
      expect(elem.y, isNaN);
      expect(elem.active, isFalse);
      expect(elem.options, isNull);
      expect(elem.$animations, isNull);
      expect(elem['x'], _isUndefined);
      expect(elem['y'], _isUndefined);
      expect(elem['active'], isFalse);
      expect(elem['options'], _isUndefined);
      expect(elem[r'$animations'], _isUndefined);
    });

    test('the setters leave the undefined state', () {
      final options = <String, Object?>{'radius': 2.0};
      final animations = <String, types.Animation>{};
      final elem = Element()
        ..x = 10
        ..y = -1.5
        ..active = true
        ..options = options
        ..$animations = animations;
      expect(elem['x'], 10.0);
      expect(elem['y'], -1.5);
      expect(elem['active'], isTrue);
      expect(elem['options'], same(options));
      expect(elem[r'$animations'], same(animations));
    });

    test('a write of undefined by name gives the undefined state again', () {
      final elem = Element()
        ..x = 1
        ..y = 2
        ..options = {}
        ..$animations = {};
      elem['x'] = undefined;
      elem['y'] = undefined;
      elem['options'] = undefined;
      elem[r'$animations'] = undefined;
      expect(elem.x, isNaN);
      expect(elem.y, isNaN);
      expect(elem.options, isNull);
      expect(elem.$animations, isNull);
      expect(elem['x'], _isUndefined);
      expect(elem['y'], _isUndefined);
      expect(elem['options'], _isUndefined);
      expect(elem[r'$animations'], _isUndefined);
    });

    test('NaN is a value, not the undefined state', () {
      final elem = Element()..['x'] = double.nan;
      expect(elem.x, isNaN);
      expect(elem['x'], isA<double>().having((x) => x.isNaN, 'isNaN', true));
      expect(elem['y'], _isUndefined);
    });
  });

  group('access by name', () {
    test('a num becomes a double', () {
      final elem = Element()
        ..['x'] = 10
        ..['y'] = -3;
      expect(elem['x'], isA<double>());
      expect(elem['x'], 10.0);
      expect(elem.x, 10.0);
      expect(elem['y'], isA<double>());
      expect(elem.y, -3.0);
      elem['x'] = 2.5;
      expect(elem.x, 2.5);
    });

    test('an unknown name reads undefined', () {
      final elem = Element();
      expect(elem[r'$context'], _isUndefined);
      expect(elem['radius'], _isUndefined);
      expect(elem[''], _isUndefined);
    });

    test('an unknown name keeps the value as it is', () {
      final context = <String, Object?>{'type': 'data'};
      final elem = Element()
        ..[r'$context'] = context
        ..['count'] = 3
        ..['empty'] = null
        ..['absent'] = undefined;
      expect(elem[r'$context'], same(context));
      expect(elem['count'], 3);
      expect(elem['count'], isA<int>());
      expect(elem['empty'], isNull);
      expect(elem['absent'], _isUndefined);
      expect(elem['other'], _isUndefined);
      elem['count'] = 'text';
      expect(elem['count'], 'text');
    });

    test('an extra property does not change the declared properties', () {
      final elem = Element()..['radius'] = 4;
      expect(elem.x, isNaN);
      expect(elem['x'], _isUndefined);
      expect(elem['active'], isFalse);
    });

    test('a value outside the type of a declared property throws', () {
      final elem = Element()..x = 1;
      for (final value in <Object?>[null, '5', true, <String, Object?>{}]) {
        expect(
          () => elem['x'] = value,
          throwsA(
            isA<ArgumentError>()
                .having((error) => error.name, 'name', 'x')
                .having((error) => error.invalidValue, 'value', value),
          ),
          reason: '$value',
        );
        expect(() => elem['y'] = value, throwsArgumentError, reason: '$value');
      }
      for (final value in <Object?>[undefined, null, 1, 'true']) {
        expect(
          () => elem['active'] = value,
          throwsArgumentError,
          reason: '$value',
        );
      }
      for (final value in <Object?>[null, 'a', <Object?>[], 1]) {
        expect(
          () => elem['options'] = value,
          throwsArgumentError,
          reason: '$value',
        );
      }
      for (final value in <Object?>[
        null,
        <String, Object?>{},
        <String, Object?>{'x': _Animation(1.0)},
        _Animation(1.0),
      ]) {
        expect(
          () => elem[r'$animations'] = value,
          throwsArgumentError,
          reason: '$value',
        );
      }
      expect(elem.x, 1.0);
      expect(elem.y, isNaN);
      expect(elem.active, isFalse);
      expect(elem.options, isNull);
      expect(elem.$animations, isNull);
    });

    test('a bool and the declared objects are written by name', () {
      final options = <String, Object?>{'radius': 3.0};
      final animations = <String, types.Animation>{
        'x': _Animation(4.0),
      };
      final elem = Element()
        ..['active'] = true
        ..['options'] = options
        ..[r'$animations'] = animations;
      expect(elem.active, isTrue);
      expect(elem.options, same(options));
      expect(elem.$animations, same(animations));
      elem['active'] = false;
      expect(elem.active, isFalse);
    });
  });

  // core.element.ts does not declare `hidden`. The port declares it for the
  // read of each draw (performance.md section 10.6). It must keep any value
  // as an extra property does: the draw tests its ToBoolean
  // (core.datasetController.js:730, the scenario 'draw with hidden values'
  // of core.datasetController_test.dart).
  group('hidden', () {
    test('starts undefined', () {
      final elem = Element();
      expect(elem.hidden, _isUndefined);
      expect(elem['hidden'], _isUndefined);
      expect(_Box()['hidden'], _isUndefined);
    });

    test('keeps any value, as an extra property does', () {
      final map = <String, Object?>{};
      for (final value in <Object?>[
        true,
        false,
        1,
        0,
        'a',
        '',
        map,
        null,
        undefined,
      ]) {
        final byName = Element()..['hidden'] = value;
        final extra = Element()..['hiddenExtra'] = value;
        expect(byName.hidden, same(value), reason: '$value');
        expect(byName['hidden'], same(value), reason: '$value');
        expect(byName['hidden'], same(extra['hiddenExtra']), reason: '$value');
        final typed = Element()..hidden = value;
        expect(typed['hidden'], same(value), reason: '$value');
      }
      // NaN is not identical to itself in JavaScript (dart2js).
      final nan = Element()..['hidden'] = double.nan;
      expect(nan.hidden, isNaN);
      expect(nan['hidden'], isNaN);
    });

    test('a subclass reads and writes it through super', () {
      final elem = _Box()..['hidden'] = true;
      expect(elem.hidden, isTrue);
      expect(elem['hidden'], isTrue);
      elem.hidden = undefined;
      expect(elem['hidden'], _isUndefined);
    });

    test('assign writes it', () {
      final elem = Element()..assign({'hidden': 0, 'x': 1});
      expect(elem.hidden, 0);
      expect(elem.x, 1.0);
    });
  });

  group('assign', () {
    test('writes each key through operator []=', () {
      final options = <String, Object?>{'radius': 2};
      final elem = Element()
        ..assign({
          'options': options,
          'x': 10,
          'y': 15,
          r'$context': 'ctx',
        });
      expect(elem.options, same(options));
      expect(elem['x'], isA<double>());
      expect(elem.x, 10.0);
      expect(elem.y, 15.0);
      expect(elem[r'$context'], 'ctx');
    });

    test('writes the keys in the Object.keys order', () {
      final order = <String>[];
      final elem = _Recorder(order)..assign({'b': 1, '1': 2, 'a': 3, '0': 4});
      expect(order, ['0', '1', 'b', 'a']);
      expect(elem['0'], 4);
    });

    test('stops at a value outside the type of a declared property', () {
      final elem = Element();
      expect(
        () => elem.assign({'x': 1, 'y': 'text', 'active': true}),
        throwsArgumentError,
      );
      expect(elem.x, 1.0);
      expect(elem.y, isNaN);
      expect(elem.active, isFalse);
    });
  });

  group('subclass protocol', () {
    test('the constructor assigns cfg', () {
      final elem = _Box({
        'width': 4,
        'horizontal': true,
        'labels': <String>['a'],
        'x': 2,
        'extra': null,
      });
      expect(elem.width, 4.0);
      expect(elem.horizontal, isTrue);
      expect(elem.labels, ['a']);
      expect(elem.x, 2.0);
      expect(elem['extra'], isNull);
      expect(elem['y'], _isUndefined);
    });

    test('a subclass reads its own names and passes the others to super', () {
      final elem = _Box();
      expect(elem['width'], _isUndefined);
      expect(elem['horizontal'], _isUndefined);
      expect(elem['labels'], _isUndefined);
      expect(elem.width, isNaN);
      expect(elem.horizontal, isNull);
      elem
        ..['width'] = 7
        ..['horizontal'] = false
        ..['x'] = 1
        ..['other'] = 'o';
      expect(elem['width'], 7.0);
      expect(elem['horizontal'], isFalse);
      expect(elem['x'], 1.0);
      expect(elem['other'], 'o');
      elem
        ..['width'] = undefined
        ..['horizontal'] = undefined;
      expect(elem['width'], _isUndefined);
      expect(elem['horizontal'], _isUndefined);
    });

    test('the conversion helpers throw for another value', () {
      final elem = _Box();
      expect(() => elem['width'] = null, throwsArgumentError);
      expect(() => elem['width'] = '1', throwsArgumentError);
      expect(() => elem['horizontal'] = null, throwsArgumentError);
      expect(() => elem['horizontal'] = 1, throwsArgumentError);
      expect(() => elem['labels'] = null, throwsArgumentError);
      expect(() => elem['labels'] = <int>[1], throwsArgumentError);
      expect(
        () => elem['labels'] = 'a',
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'labels')
              .having((error) => error.message, 'message', contains('List')),
        ),
      );
      expect(elem['width'], _isUndefined);
      expect(elem['horizontal'], _isUndefined);
      expect(elem['labels'], _isUndefined);
    });

    test('a boolean with a start value accepts only a bool', () {
      final elem = _Box();
      expect(elem['animated'], isTrue);
      elem['animated'] = false;
      expect(elem.animated, isFalse);
      for (final value in <Object?>[undefined, null, 1, 'true']) {
        expect(
          () => elem['animated'] = value,
          throwsA(
            isA<ArgumentError>()
                .having((error) => error.name, 'name', 'animated')
                .having((error) => error.message, 'message', 'Not a bool'),
          ),
          reason: '$value',
        );
      }
      expect(elem['animated'], isFalse);
    });
  });

  group('getProps', () {
    test('returns the element when final is not true', () {
      final elem = Element()
        ..x = 1
        ..$animations = {'x': _Animation(5.0)};
      expect(elem.getProps(['x']), same(elem));
      expect(elem.getProps(['x'], false), same(elem));
      // An explicit null stands for an explicit JS undefined.
      // ignore: avoid_redundant_argument_values
      expect(elem.getProps(['x'], null), same(elem));
    });

    test('returns the element when it has no animations', () {
      final elem = Element()..x = 1;
      expect(elem.getProps(['x'], true), same(elem));
    });

    test('the element reads by name through the result', () {
      final elem = Element()
        ..x = 1
        ..['radius'] = 2;
      final props = elem.getProps(['x', 'y', 'radius']);
      expect(props['x'], 1.0);
      expect(props['y'], _isUndefined);
      expect(props['radius'], 2);
      expect(props['other'], _isUndefined);
    });

    test('an empty animation object gives a new object', () {
      final elem = Element()
        ..x = 1
        ..$animations = {};
      final props = elem.getProps(['x', 'z'], true);
      expect(props, isNot(same(elem)));
      expect(props, isNot(isA<Element>()));
      expect(props['x'], 1.0);
      expect(props['z'], _isUndefined);
      expect(props['y'], _isUndefined);
    });

    test('a new object reads the target of an active animation only', () {
      final elem = Element()
        ..x = 10
        ..y = 1.5
        ..['radius'] = 3
        ..$animations = {
          'x': _Animation(20.0, active: false),
          'y': _Animation(7.0),
          'radius': _Animation('r'),
          'width': _Animation(undefined),
          'height': _Animation(null),
        };
      final props = elem.getProps([
        'x',
        'y',
        'radius',
        'width',
        'height',
        'base',
      ], true);
      expect(props['x'], 10.0);
      expect(props['y'], 7.0);
      expect(props['radius'], 'r');
      expect(props['width'], _isUndefined);
      expect(props['height'], isNull);
      expect(props['base'], _isUndefined);
      // A name outside props is not an own key of the new object.
      expect(elem.getProps(['x'], true)['y'], _isUndefined);
    });

    test('a new object keeps its values after the element changes', () {
      final elem = Element()
        ..x = 1
        ..$animations = {};
      final props = elem.getProps(['x'], true);
      elem.x = 2;
      expect(props['x'], 1.0);
    });
  });

  group('tooltipPosition', () {
    test('gives NaN for the undefined state', () {
      expect(
        Element().tooltipPosition(),
        const ElementPoint(double.nan, double.nan),
      );
    });

    test('gives the current or the final position', () {
      final elem = Element()
        ..x = 10
        ..y = 1.5;
      expect(elem.tooltipPosition(), const ElementPoint(10, 1.5));
      elem.$animations = {
        'x': _Animation(20.0, active: false),
        'y': _Animation(7.0),
      };
      expect(elem.tooltipPosition(true), const ElementPoint(10, 7));
      expect(elem.tooltipPosition(false), const ElementPoint(10, 1.5));
      expect(elem.tooltipPosition(), const ElementPoint(10, 1.5));
    });

    test('gives the ToNumber of a target that is not a double', () {
      final elem = Element()
        ..x = 1
        ..y = 2
        ..$animations = {
          'x': _Animation(undefined),
          'y': _Animation('3'),
        };
      expect(elem.tooltipPosition(true), const ElementPoint(double.nan, 3));
    });
  });

  group('hasValue', () {
    test('needs a finite x and y', () {
      expect(Element().hasValue(), isFalse);
      expect((Element()..x = 1).hasValue(), isFalse);
      expect((Element()..y = 1).hasValue(), isFalse);
      expect(
        (Element()
              ..x = 1
              ..y = 2)
            .hasValue(),
        isTrue,
      );
      expect(
        (Element()
              ..x = 0
              ..y = -0.0)
            .hasValue(),
        isTrue,
      );
      for (final value in [double.nan, double.infinity, -double.infinity]) {
        expect(
          (Element()
                ..x = value
                ..y = 1)
              .hasValue(),
          isFalse,
          reason: '$value',
        );
      }
    });
  });

  group('statics', () {
    test('defaults is an empty object and defaultRoutes is undefined', () {
      expect(Element.defaults, isA<AnyObject>());
      expect(Element.defaults, isEmpty);
      expect(Element.defaultRoutes, _isUndefined);
    });

    test('jsClass is Element as a value', () {
      // From src/core/core.element.ts in Node.js v24.12.0 on x64: the own
      // statics of Element are defaults and defaultRoutes. 'defaultRoutes'
      // in Element is true, with the value undefined. 'id' in Element and
      // 'descriptors' in Element are false. The static prototype of Element
      // is Function.prototype. typeof Element is 'function'.
      final c = Element.jsClass;
      expect(c.name, 'Element');
      expect(c.superclass, isNull);
      expect(c['defaults'], same(Element.defaults));
      expect(c.has('defaultRoutes'), isTrue);
      expect(c['defaultRoutes'], _isUndefined);
      expect(c.has('id'), isFalse);
      expect(c.id, _isUndefined);
      expect(c.has('descriptors'), isFalse);
      expect(c.isSubclassOf(jsObjectClass), isTrue);
      expect(c.isSubclassOf(c), isFalse);
    });

    test('jsConstruct of jsClass makes an Element and ignores the '
        'arguments', () {
      // new Element({x: 1}) has x undefined: the implicit constructor of
      // Element takes no parameter.
      final element = jsConstruct(Element.jsClass, [
        <String, Object?>{'x': 1},
      ]);
      expect(element, isA<Element>());
      expect((element as Element)['x'], _isUndefined);
      // class Custom extends Element {}: the subclass value constructs an
      // Element (Chart.js ADR 0020, section 3).
      final custom = JsClass('Custom', superclass: Element.jsClass);
      expect(jsConstruct(custom, const []), isA<Element>());
      expect(custom['defaults'], same(Element.defaults));
    });
  });

  group('adapt-component-class-role', () {
    // The element constructors copy cfg with `if (cfg) Object.assign(this,
    // cfg)`. In Node.js v24.12.0 on x64, new PointElement(), (null), (0) and
    // (false) copy nothing, new PointElement(5) and (true) copy nothing and
    // do not throw, and new PointElement('ab') copies the own key '0'. The
    // port throws a TypeError for a truthy cfg that is not a Map.
    test('elementCfgArg gives Dart null for an absent or a falsy cfg', () {
      for (final args in <List<Object?>>[
        [],
        [undefined],
        [null],
        [0],
        [-0.0],
        [double.nan],
        [false],
        [''],
      ]) {
        expect(elementCfgArg(args), isNull, reason: '$args');
      }
    });

    test('elementCfgArg gives a Map as it is', () {
      final cfg = <String, Object?>{'x': 1};
      expect(elementCfgArg([cfg, 'ignored']), same(cfg));
      // An empty object is truthy. Object.assign copies nothing from it.
      final empty = <String, Object?>{};
      expect(elementCfgArg([empty]), same(empty));
    });

    test('elementCfgArg throws a TypeError for a truthy cfg that is not a '
        'Map', () {
      for (final value in <Object?>[
        5,
        true,
        'ab',
        <Object?>[1],
        JsClass('A'),
        () {},
      ]) {
        expect(
          () => elementCfgArg([value]),
          throwsA(isA<TypeError>()),
          reason: '$value',
        );
      }
    });
  });

  group('ElementPoint', () {
    test('is a Point that compares by value', () {
      const point = ElementPoint(1, 2);
      expect(point, isA<types.Point>());
      expect(point.x, 1.0);
      expect(point.y, 2.0);
      expect(point, const ElementPoint(1, 2));
      expect(point.hashCode, const ElementPoint(1, 2).hashCode);
      expect(point, isNot(const ElementPoint(2, 1)));
      expect(point, isNot(const ElementPoint(1, 3)));
    });

    test('NaN equals NaN and 0 equals -0', () {
      const nan = ElementPoint(0 / 0, 1);
      expect(nan, const ElementPoint(double.nan, 1));
      expect(nan.hashCode, const ElementPoint(double.nan, 1).hashCode);
      expect(nan, isNot(const ElementPoint(0, 1)));
      const negativeZero = ElementPoint(-0, 1);
      expect(negativeZero.x.isNegative, isTrue);
      expect(const ElementPoint(0, 1), negativeZero);
      expect(const ElementPoint(0, 1).hashCode, negativeZero.hashCode);
    });

    test('prints as the object literal', () {
      expect(const ElementPoint(1, 2.5).toString(), '{x: 1, y: 2.5}');
      expect(
        const ElementPoint(double.nan, -0).toString(),
        '{x: NaN, y: 0}',
      );
    });
  });

  group('types', () {
    test('an Element is a types.Element, a Point and an ElementProps', () {
      final elem = Element()
        ..x = 3
        ..y = 4;
      expect(elem, isA<types.Element>());
      expect(elem, isA<types.Point>());
      expect(elem, isA<ElementProps>());
      final types.Point point = elem;
      expect(point.x, 3.0);
      expect(point.y, 4.0);
    });
  });
}

/// An element that records the names of its writes by name.
final class _Recorder extends Element {
  _Recorder(this.order);

  final List<String> order;

  @override
  void operator []=(String prop, Object? value) {
    order.add(prop);
    super[prop] = value;
  }
}
