// Original code, not ported from Chart.js: PointElement cases with no spec.
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/elements/element_options.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.curve.dart'
    show updateBezierControlPoints;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/props.dart'
    show PointProperties;
import 'package:flutter_chartjs_port/src/types/animation.dart' as types;
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:test/test.dart';

import 'point_reference.dart';

// Upstream behavior that test/specs/element.point.tests.js does not check
// (AGENTS.md rule 3): the hit tests at the edges of the hit radius, with and
// without useFinalPosition, size, getRange and the calls of draw. The
// expected values are in point_reference.dart, which
// tool/reference/point_reference.mjs writes from src/elements/element.point.ts
// at v4.5.1 in Node.js v24.22.1 on arm64, with the mock context of
// chartjs-test-utils (Chart.js ADR 0045). The hit tests, size and getRange
// compare exactly. The draw calls compare the names exactly and each number
// with closeTo (Chart.js ADR 0034).
//
// Each comparison with the reference runs twice (Chart.js ADR 0018, section
// 6): with the plain Map options of the reference, and with a PointOptions
// with the same entries. Both compare with the same reference data.
//
// The other groups test the element design of Chart.js ADR 0017 for the
// point: the start values, the access by name, the control points of a
// SplinePoint, the radar angle, the TypeError of undefined options and the
// cache of the drawPoint adapter.

/// A test animation with the two members that getProps reads.
final class _Animation implements types.Animation {
  _Animation(this.to, {required this.isActive});

  /// The result of [active].
  final bool isActive;

  @override
  bool active() => isActive;

  @override
  final Object? to;
}

/// A JavaScript object literal `{left, top, right, bottom}`, passed as a
/// [ChartArea].
final class _Area implements ChartArea {
  const _Area(this.left, this.top, this.right, this.bottom);

  @override
  final double left;

  @override
  final double top;

  @override
  final double right;

  @override
  final double bottom;

  @override
  double get width => right - left;

  @override
  double get height => bottom - top;
}

/// An image point style, the `{width, height}` of an `HTMLImageElement`.
final class _Image implements CanvasImageSource {
  const _Image();

  @override
  double get width => 8;

  @override
  double get height => 6;
}

const _image = _Image();

/// The mock context with a recorded `drawImage`. The generator adds the same
/// method to the upstream mock, which has none.
final class _Context extends MockContext {
  @override
  void drawImage(
    CanvasImageSource image,
    double dx,
    double dy, [
    double? dw,
    double? dh,
  ]) {
    record('drawImage', [image, dx, dy, dw, dh]);
  }
}

/// [value] with the marker [pointImage] replaced by the test image, also in
/// a nested Map.
Object? _fromReference(Object? value) => switch (value) {
  pointImage => _image,
  final Map<String, Object?> map => <String, Object?>{
    for (final MapEntry(:key, :value) in map.entries)
      key: _fromReference(value),
  },
  _ => value,
};

/// A matcher of a number: [isNaN] for NaN, else equality.
Matcher _number(double value) => value.isNaN ? isNaN : equals(value);

/// The expected calls as matchers: the names exactly, numbers with
/// [closeTo] (NaN with [isNaN]), the image marker as the test image, other
/// values with `==`.
List<Object?> _calls(List<(String, List<Object?>)> calls) => [
  for (final (name, args) in calls)
    {
      'name': name,
      'args': [
        for (final arg in args)
          switch (arg) {
            final num n when n.isNaN => isNaN,
            final num n => closeTo(n, 1e-9),
            _ => _fromReference(arg),
          },
      ],
    },
];

/// [options] as they are: the plain Map form of the options.
AnyObject _plainOptions(AnyObject options) => options;

/// The two forms of the options of a point (Chart.js ADR 0018, section 6):
/// the plain Map, and a [PointOptions] with the same entries in the same key
/// order.
const Map<String, Object Function(AnyObject options)> _optionsForms = {
  'Map options': _plainOptions,
  'PointOptions': PointOptions.new,
};

/// [cfg] with its `options` Map in the form [form].
AnyObject _withOptions(AnyObject cfg, Object Function(AnyObject) form) => {
  for (final MapEntry(:key, :value) in cfg.entries)
    key: key == 'options' && value is AnyObject ? form(value) : value,
};

/// The point element of an inRange case, with its `$animations`, and its
/// options in the form [form].
PointElement _inRangePoint(
  PointInRangeCase c,
  Object Function(AnyObject) form,
) {
  final point = PointElement(_withOptions(c.cfg, form));
  final animations = c.animations;
  if (animations != null) {
    point.$animations = {
      for (final MapEntry(:key, :value) in animations.entries)
        key: _Animation(value.to, isActive: value.active),
    };
  }
  return point;
}

/// The options of a drawn point in the draw tests of the adapter.
Map<String, Object?> _options({double radius = 5}) => {
  'radius': radius,
  'borderWidth': 2,
  'borderColor': 'red',
  'backgroundColor': 'blue',
  'pointStyle': 'circle',
};

/// The radius of each `arc` call of [ctx].
List<Object?> _arcRadii(MockContext ctx) => [
  for (final call in ctx.getCalls())
    if (call['name'] == 'arc') (call['args']! as List<Object?>)[2],
];

final Matcher _isUndefined = same(undefined);

void main() {
  group('reference', () {
    test('has the reference of Node.js v24.22.1 on arm64', () {
      expect(pointReferenceNode, 'v24.22.1');
      expect(pointReferenceArch, 'arm64');
      expect(pointInRangeReference, hasLength(35));
      expect(pointSizeReference, hasLength(18));
      expect(pointGetRangeReference, hasLength(6));
      expect(pointDrawReference, hasLength(68));
    });
  });

  group('statics', () {
    test('id is point', () {
      expect(PointElement.id, 'point');
    });

    test('defaults has the upstream keys and values in order', () {
      expect(PointElement.defaults.jsKeys(), [
        'borderWidth',
        'hitRadius',
        'hoverBorderWidth',
        'hoverRadius',
        'pointStyle',
        'radius',
        'rotation',
      ]);
      expect(
        [
          for (final key in PointElement.defaults.jsKeys())
            PointElement.defaults[key],
        ],
        [1, 1, 1, 4, 'circle', 3, 0],
      );
    });

    test('defaultRoutes routes the two colors', () {
      expect(PointElement.defaultRoutes, {
        'backgroundColor': 'backgroundColor',
        'borderColor': 'borderColor',
      });
    });

    test('the statics of Element do not change', () {
      expect(Element.defaults.jsKeys(), isEmpty);
      expect(Element.defaultRoutes, _isUndefined);
    });

    test('jsClass is PointElement as a value', () {
      // From element.point.ts in Node.js v24.12.0 on x64: the own statics of
      // PointElement are id, defaults and defaultRoutes, and its superclass is
      // Element. 'descriptors' in PointElement is false. typeof PointElement is
      // 'function'.
      final c = PointElement.jsClass;
      expect(c.name, 'PointElement');
      expect(c.superclass, same(Element.jsClass));
      expect(c.id, 'point');
      expect(c['id'], PointElement.id);
      expect(c['defaults'], same(PointElement.defaults));
      expect(c['defaultRoutes'], same(PointElement.defaultRoutes));
      expect(c.has('descriptors'), isFalse);
      expect(c.isSubclassOf(Element.jsClass), isTrue);
      expect(c.isSubclassOf(c), isFalse);
    });

    test('jsConstruct of jsClass makes a PointElement with the cfg', () {
      // new PointElement({x: 2}) and new PointElement() (Chart.js ADR 0020,
      // section 3).
      final element = jsConstruct(PointElement.jsClass, [
        <String, Object?>{'x': 2},
      ]);
      expect(element, isA<PointElement>());
      expect((element as PointElement)['x'], 2.0);
      expect(jsConstruct(PointElement.jsClass, const []), isA<PointElement>());
      // class My extends PointElement { static id = 'my'; }: the subclass value
      // constructs a PointElement and reads the statics of PointElement.
      final my = JsClass('My', superclass: PointElement.jsClass)..['id'] = 'my';
      expect(jsConstruct(my, const []), isA<PointElement>());
      expect(my.id, 'my');
      expect(PointElement.jsClass.id, 'point');
      expect(my['defaults'], same(PointElement.defaults));
    });
  });

  group('properties', () {
    test('a new point has the upstream start values', () {
      final point = PointElement();
      expect(point.parsed, isNull);
      expect(point.skip, isNull);
      expect(point.stop, isNull);
      expect(point.options, isNull);
      expect(point.angle, isNull);
      expect(point.active, false);
      for (final value in [
        point.x,
        point.y,
        point.cp1x,
        point.cp1y,
        point.cp2x,
        point.cp2y,
      ]) {
        expect(value, isNaN);
      }
      for (final prop in [
        'parsed',
        'skip',
        'stop',
        'options',
        'x',
        'y',
        'cp1x',
        'cp1y',
        'cp2x',
        'cp2y',
        'angle',
        r'$context',
      ]) {
        expect(point[prop], _isUndefined, reason: prop);
      }
    });

    test('the constructor assigns cfg', () {
      final parsed = <String, Object?>{'x': 1, 'y': 2};
      final options = <String, Object?>{'radius': 3};
      final context = <String, Object?>{'type': 'data'};
      final point = PointElement({
        'x': 10,
        'y': 1.5,
        'parsed': parsed,
        'skip': false,
        'stop': true,
        'options': options,
        'angle': 2,
        r'$context': context,
      });
      expect(point.x, 10.0);
      expect(point.y, 1.5);
      expect(point.parsed, same(parsed));
      expect(point.skip, false);
      expect(point.stop, true);
      expect(point.options, same(options));
      expect(point.angle, 2.0);
      expect(point[r'$context'], same(context));
    });

    test('a write by name gives a double for a num', () {
      final point = PointElement()
        ..['cp1x'] = 1
        ..['cp1y'] = 2
        ..['cp2x'] = 3
        ..['cp2y'] = 4.5
        ..['angle'] = 5;
      expect(
        [point.cp1x, point.cp1y, point.cp2x, point.cp2y, point.angle],
        [1.0, 2.0, 3.0, 4.5, 5.0],
      );
      for (final prop in ['cp1x', 'cp1y', 'cp2x', 'cp2y', 'angle']) {
        expect(point[prop], isA<double>(), reason: prop);
      }
    });

    test('the setters and the reads by name agree', () {
      final parsed = Object();
      final point = PointElement()
        ..parsed = parsed
        ..skip = true
        ..stop = false
        ..cp1x = 1
        ..cp1y = 2
        ..cp2x = 3
        ..cp2y = 4
        ..angle = 0.5;
      expect(point['parsed'], same(parsed));
      expect(point['skip'], true);
      expect(point['stop'], false);
      expect(
        [point['cp1x'], point['cp1y'], point['cp2x'], point['cp2y']],
        [1.0, 2.0, 3.0, 4.0],
      );
      expect(point['angle'], 0.5);
    });

    test('a write of undefined restores the undefined state', () {
      final point = PointElement({
        'parsed': <String, Object?>{},
        'skip': true,
        'stop': true,
        'cp1x': 1,
        'cp1y': 1,
        'cp2x': 1,
        'cp2y': 1,
        'angle': 1,
      });
      for (final prop in [
        'parsed',
        'skip',
        'stop',
        'cp1x',
        'cp1y',
        'cp2x',
        'cp2y',
        'angle',
      ]) {
        point[prop] = undefined;
        expect(point[prop], _isUndefined, reason: prop);
      }
      expect(point.parsed, isNull);
      expect(point.skip, isNull);
      expect(point.stop, isNull);
      expect(point.cp1x, isNaN);
      expect(point.angle, isNull);
    });

    test('a write outside the type throws an ArgumentError', () {
      final point = PointElement();
      for (final (prop, value) in <(String, Object?)>[
        ('parsed', null),
        ('skip', null),
        ('skip', 'true'),
        ('skip', 1),
        ('stop', null),
        ('stop', 0),
        ('cp1x', null),
        ('cp1y', '1'),
        ('cp2x', true),
        ('cp2y', null),
        ('angle', null),
        ('angle', '0.5'),
      ]) {
        expect(
          () => point[prop] = value,
          throwsA(isA<ArgumentError>()),
          reason: '$prop: $value',
        );
        expect(point[prop], _isUndefined, reason: prop);
      }
    });

    test(r'Element handles x, y, active, options and $animations', () {
      final options = <String, Object?>{'radius': 1};
      final animations = <String, types.Animation>{};
      final point = PointElement()
        ..['x'] = 1
        ..['y'] = 2
        ..['active'] = true
        ..['options'] = options
        ..[r'$animations'] = animations;
      expect(point.x, 1.0);
      expect(point.y, 2.0);
      expect(point.active, true);
      expect(point.options, same(options));
      expect(point.$animations, same(animations));
      expect(() => point['x'] = 'a', throwsA(isA<ArgumentError>()));
    });

    test(
      'is an Element, a PointElement, a SplinePoint and a VisualElement',
      () {
        final point = PointElement();
        expect(point, isA<Element>());
        expect(point, isA<types.Element>());
        expect(point, isA<types.PointElement>());
        expect(point, isA<types.RadialPointElement>());
        expect(point, isA<SplinePoint>());
        expect(point, isA<types.VisualElement>());
      },
    );
  });

  group('control points', () {
    test('updateBezierControlPoints writes the control points', () {
      final points = [
        PointElement({'x': 0, 'y': 0}),
        PointElement({'x': 10, 'y': 10}),
        PointElement({'x': 20, 'y': 0}),
      ];
      updateBezierControlPoints(
        points,
        {'tension': 0.4},
        const _Area(0, 0, 100, 100),
        false,
        'x',
      );
      for (final point in points) {
        for (final prop in ['cp1x', 'cp1y', 'cp2x', 'cp2y']) {
          final value = point[prop];
          expect(value, isA<double>(), reason: prop);
          expect((value! as double).isFinite, true, reason: prop);
        }
        expect(point['cp1x'], point.cp1x);
        expect(point['cp2y'], point.cp2y);
      }
      // The middle point has a smooth tangent: its control points lie on
      // either side of it.
      expect(points[1].cp1x, lessThan(10));
      expect(points[1].cp2x, greaterThan(10));
    });

    test('a SplinePoint write of NaN keeps a value, not undefined', () {
      final point = PointElement()..cp1x = double.nan;
      expect(point.cp1x, isNaN);
      expect(point['cp1x'], isA<double>());
      expect(point['cp1x'], isNot(_isUndefined));
    });
  });

  group('angle', () {
    test('the property read of helpers.segment gives the radar angle', () {
      final types.PointElement radar = PointElement({'angle': 1.5});
      final types.PointElement other = PointElement();
      // PointElementProperty, the read of helpers.segment.js:47 and :104.
      expect(radar['angle'], 1.5);
      expect(other['angle'], isNaN);
    });
  });

  group('inRange, inXRange, inYRange and getCenterPoint', () {
    for (final MapEntry(key: name, value: form) in _optionsForms.entries) {
      group(name, () {
        for (final c in pointInRangeReference) {
          test(c.name, () {
            final point = _inRangePoint(c, form);
            final useFinalPosition = c.useFinalPosition;
            expect(
              point.inRange(c.mouseX, c.mouseY, useFinalPosition),
              c.inRange,
              reason: 'inRange',
            );
            expect(
              point.inXRange(c.mouseX, useFinalPosition),
              c.inXRange,
              reason: 'inXRange',
            );
            expect(
              point.inYRange(c.mouseY, useFinalPosition),
              c.inYRange,
              reason: 'inYRange',
            );
            expect(
              point.getCenterPoint(useFinalPosition),
              ElementPoint(c.centerX, c.centerY),
              reason: 'getCenterPoint',
            );
          });
        }
      });
    }

    test('the hit tests throw a TypeError without options', () {
      final point = PointElement({'x': 10, 'y': 15});
      expect(() => point.inRange(10, 15), throwsA(isA<TypeError>()));
      expect(() => point.inXRange(10), throwsA(isA<TypeError>()));
      expect(() => point.inYRange(15), throwsA(isA<TypeError>()));
      expect(point.getCenterPoint(), const ElementPoint(10, 15));
    });
  });

  group('size', () {
    for (final MapEntry(key: name, value: form) in _optionsForms.entries) {
      group(name, () {
        for (final c in pointSizeReference) {
          test(c.name, () {
            final elementOptions = c.elementOptions;
            final point = PointElement({
              if (elementOptions != null) 'options': form(elementOptions),
            });
            final options = c.options;
            final size = options == null
                ? point.size()
                : point.size(form(options));
            expect(size, _number(c.size));
          });
        }
      });
    }
  });

  group('getRange', () {
    for (final MapEntry(key: name, value: form) in _optionsForms.entries) {
      group(name, () {
        for (final c in pointGetRangeReference) {
          test(c.name, () {
            final options = c.options;
            final point = PointElement({
              if (options != null) 'options': form(options),
            });
            expect(point.getRange(), _number(c.range));
          });
        }
      });
    }

    test('ignores the axis', () {
      final point = PointElement({
        'options': <String, Object?>{'radius': 3, 'hitRadius': 1},
      });
      expect(point.getRange('x'), 4);
      expect(point.getRange('y'), 4);
    });
  });

  // A string `radius` or `hitRadius` joins in the JS `+` of
  // element.point.ts:15, :65 and :105. A bubble makes a string radius from
  // a string `r` (controller.bubble.js:165). The expected values come from
  // the pinned build in Node.js v24.12.0 on x64 (a probe of
  // `getRange`, `inRange` and `inXRange` with string options).
  group('string options join in the JS +', () {
    // (options, getRange, the distances of inRange(d, 0) that hit, the
    // distances of inXRange(d) that hit), for the distances 5, 9, 50, 100,
    // 106, 108 and 300 from a point at (0, 0).
    final cases = <(Map<String, Object?>, Object, Set<int>, Set<int>)>[
      (
        {'radius': '07', 'hitRadius': 1},
        '071',
        {5, 9, 50, 100, 106},
        {5, 9, 50},
      ),
      ({'radius': 7, 'hitRadius': '1'}, '71', {5, 9}, {5, 9, 50}),
      ({'radius': '2', 'hitRadius': '3'}, '23', {5, 9}, {5, 9}),
      ({'radius': 3, 'hitRadius': 1}, 4.0, <int>{}, <int>{}),
      ({'radius': null, 'hitRadius': '4'}, 'null4', <int>{}, <int>{}),
    ];
    const distances = [5, 9, 50, 100, 106, 108, 300];
    for (final MapEntry(key: name, value: form) in _optionsForms.entries) {
      group(name, () {
        for (final (options, range, hits, xHits) in cases) {
          test('$options', () {
            final point = PointElement({
              'x': 0.0,
              'y': 0.0,
              'options': form(options),
            });
            expect(point.getRange(), range);
            for (final d in distances) {
              expect(point.inRange(d.toDouble(), 0), hits.contains(d));
              expect(point.inXRange(d.toDouble()), xHits.contains(d));
              expect(point.inYRange(d.toDouble()), xHits.contains(d));
            }
          });
        }
      });
    }

    // `size` (element.point.ts:84-86): `radius && options.borderWidth || 0`
    // keeps a string `borderWidth`, and `radius + borderWidth` joins.
    // The expected values come from a probe of `size` on the pinned build.
    final sizes = <(Map<String, Object?>, double)>[
      ({'radius': 3, 'borderWidth': '1'}, 62),
      ({'radius': '3', 'borderWidth': 1}, 8),
      ({'radius': 3, 'hoverRadius': '5', 'borderWidth': '2'}, 104),
      ({'radius': 0, 'borderWidth': '2'}, 0),
      ({'radius': 3, 'borderWidth': null}, 6),
      ({'radius': 3, 'borderWidth': 'a'}, double.nan),
    ];
    for (final MapEntry(key: name, value: form) in _optionsForms.entries) {
      for (final (options, size) in sizes) {
        test('$name size $options', () {
          final point = PointElement({'options': form(options)});
          expect(point.size(), size.isNaN ? isNaN : size);
        });
      }
    }
  });

  group('draw', () {
    for (final MapEntry(key: name, value: form) in _optionsForms.entries) {
      group(name, () {
        for (final c in pointDrawReference) {
          test(c.name, () {
            final ctx = _Context();
            final point = PointElement(
              _withOptions(
                _fromReference(c.cfg)! as Map<String, Object?>,
                form,
              ),
            );
            final area = c.area;
            point.draw(
              ctx,
              area == null
                  ? null
                  : _Area(area.left, area.top, area.right, area.bottom),
            );
            expect(ctx.getCalls(), _calls(c.calls));
          });
        }
      });
    }

    test('throws a TypeError without options unless skip is true', () {
      expect(
        () => PointElement({'x': 10, 'y': 15}).draw(_Context()),
        throwsA(isA<TypeError>()),
      );
      final ctx = _Context();
      PointElement({'x': 10, 'y': 15, 'skip': true}).draw(ctx);
      expect(ctx.getCalls(), isEmpty);
    });
  });

  group('drawPoint adapter', () {
    test('draws the same calls with the kept adapter', () {
      final point = PointElement({'options': _options(), 'x': 50, 'y': 40});
      final first = _Context();
      final second = _Context();
      point
        ..draw(first)
        ..draw(second);
      expect(second.getCalls(), first.getCalls());
      expect(_arcRadii(second), [5]);
    });

    test('reads a change of the options Map at the next draw', () {
      final options = _options();
      final point = PointElement({'options': options, 'x': 50, 'y': 40})
        ..draw(_Context());
      options['radius'] = 7;
      final ctx = _Context();
      point.draw(ctx);
      expect(_arcRadii(ctx), [7]);
    });

    test('reads a new options Map at the next draw', () {
      final point = PointElement({'options': _options(), 'x': 50, 'y': 40})
        ..draw(_Context())
        ..options = _options(radius: 9);
      final ctx = _Context();
      point.draw(ctx);
      expect(_arcRadii(ctx), [9]);
    });
  });

  group('size with a truthy radius whose number is 0', () {
    // element.point.ts:83-84: `radius && options.hoverRadius` tests the raw
    // option value. The pinned build in x64 Node.js v24.12.0 gives 10 for
    // the radius '0', ' ' and [] with hoverRadius 4 and borderWidth 1, and 0
    // for the radius '0' with hoverRadius 0 (a probe of these configs).
    for (final radius in <Object?>['0', ' ', <Object?>[]]) {
      test('radius ${radius is String ? "'$radius'" : '[]'} adds the hover '
          'radius and the border', () {
        final point = PointElement();
        expect(
          point.size(<String, Object?>{
            'radius': radius,
            'hoverRadius': 4.0,
            'borderWidth': 1.0,
          }),
          10,
        );
      });
    }

    test("radius '0' with hoverRadius 0 gives 0", () {
      final point = PointElement();
      expect(
        point.size(<String, Object?>{
          'radius': '0',
          'hoverRadius': 0.0,
          'borderWidth': 1.0,
        }),
        0,
      );
    });
  });

  // Chart.js ADR 0054 §9: the typed writes of a property object, with the
  // exact-class rule.
  group('typed writes', () {
    test('assign of a PointProperties takes the typed setters', () {
      final options = PointOptions();
      final parsed = <String, Object?>{'x': 1.0, 'y': 2.0};
      final props = PointProperties()
        ..y = 2
        ..x = 1
        ..skip = false
        ..stop = true
        ..parsed = parsed
        ..options = options
        ..angle = 0.5;
      final point = PointElement()..assign(props);
      expect(point.x, 1);
      expect(point.y, 2);
      expect(point.skip, isFalse);
      expect(point.stop, isTrue);
      expect(point.parsed, same(parsed));
      expect(point.options, same(options));
      expect(point.angle, 0.5);
      expect(point['cp1x'], _isUndefined);
    });

    test('a foreign value and an extra key go by name', () {
      final foreign = PointProperties()
        ..x = 1
        ..['y'] = 'a';
      final point = PointElement();
      expect(() => point.assign(foreign), throwsArgumentError);
      // The key before the throw is written, as Object.assign does.
      expect(point.x, 1);
      expect(point['y'], _isUndefined);
      final extra = PointProperties()
        ..x = 3
        ..['raw'] = 7
        ..['custom'] = 'c';
      final other = PointElement()..assign(extra);
      expect(other.x, 3);
      expect(other['raw'], 7);
      expect(other['custom'], 'c');
    });

    test('an element of a user subclass gets the writes by name', () {
      final order = <String>[];
      final point = _RecordingPoint(order)
        ..assign(
          PointProperties()
            ..y = 2
            ..x = 1,
        );
      expect(order, ['y', 'x']);
      expect(point.x, 1);
      expect(point.typedWrites, isFalse);
      expect(PointElement().typedWrites, isTrue);
    });
  });
}

/// A point of a user subclass that records each write by name.
final class _RecordingPoint extends PointElement {
  _RecordingPoint(this.order);

  final List<String> order;

  @override
  void operator []=(String prop, Object? value) {
    order.add(prop);
    super[prop] = value;
  }
}
