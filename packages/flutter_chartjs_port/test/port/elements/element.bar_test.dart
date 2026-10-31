// Original code, not ported from Chart.js: element.bar cases with no spec.
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/elements/element.bar.dart';
import 'package:flutter_chartjs_port/src/elements/element_options.dart';
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/props.dart' show BorderSkipped;
import 'package:flutter_chartjs_port/src/types/animation.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:test/test.dart';

import '../helpers/rounded_rect_upstream.dart';
import 'bar_reference.dart';

// Upstream behavior that test/specs/element.bar.tests.js does not check
// (AGENTS.md rule 3).
//
// The expected results of the range methods, getCenterPoint,
// tooltipPosition, getRange and draw come from
// src/elements/element.bar.js at v4.5.1, run with type stripping in Node.js
// v24.22.1 on arm64. The draw calls go to the upstream mock context of
// chartjs-test-utils 0.4.0, padded to the parameter lists of MockContext
// (harness-mock-optional-args). bar_reference.dart has the data, which
// tool/reference/bar_reference.mjs writes (Chart.js ADR 0045).
//
// The range results are booleans, and the points are the results of one
// IEEE operation. Thus the tests compare them exactly. The draw calls compare
// each number with closeTo (Chart.js ADR 0034), and NaN with isNaN.
//
// The draw of the port has two DIVERGES forms (differences.md). The
// comparison with the reference translates each of them back into the
// upstream form:
// - adapt-rounded-rect-path: addRoundedRectPath makes one roundRect call.
//   The context of the draw is an UpstreamRoundedRectContext, which records
//   that call as the four arcs and four lines of upstream.
// - adapt-bar-clip: draw does not call clip() when inflateAmount is 0. For
//   such a bar, the expected calls are the reference calls without 'clip'.
//
// Each reference case runs twice (Chart.js ADR 0018, section 6): with the
// plain Map options of the reference, and with a BarOptions with the same
// entries. Both compare with the same reference data.

/// The JS animation object `{active: () => active, _to: to}`.
final class _Animation implements Animation {
  _Animation({required this.isActive, required this.to});

  /// The result of [active].
  final bool isActive;

  @override
  bool active() => isActive;

  @override
  final Object? to;
}

/// [options] as they are: the plain Map form of the options.
AnyObject _plainOptions(AnyObject options) => options;

/// The two forms of the options of a bar (Chart.js ADR 0018, section 6): the
/// plain Map, and a [BarOptions] with the same entries in the same key
/// order.
const Map<String, Object Function(AnyObject options)> _optionsForms = {
  'Map options': _plainOptions,
  'BarOptions': BarOptions.new,
};

/// [cfg] with its `options` Map in the form [form].
AnyObject _withOptions(AnyObject cfg, Object Function(AnyObject) form) => {
  for (final MapEntry(:key, :value) in cfg.entries)
    key: key == 'options' && value is AnyObject ? form(value) : value,
};

/// `new BarElement(cfg)` with an animation for each entry of [animations],
/// as the generator builds it.
BarElement _bar(
  Map<String, Object?> cfg, [
  List<BarReferenceAnimation> animations = const [],
]) {
  final bar = BarElement(cfg);
  if (animations.isNotEmpty) {
    bar.$animations = {
      for (final (prop, active, to) in animations)
        prop: _Animation(isActive: active, to: to),
    };
  }
  return bar;
}

/// The expected calls as matchers: the names exactly, numbers with
/// [closeTo] or [isNaN], other values with `==`.
List<Object?> _calls(List<(String, List<Object?>)> calls) => [
  for (final (name, args) in calls)
    {
      'name': name,
      'args': [
        for (final arg in args)
          if (arg is num && arg.isNaN)
            isNaN
          else if (arg is num)
            closeTo(arg, 1e-9)
          else
            arg,
      ],
    },
];

/// The names of the draw calls of [ctx].
List<Object?> _names(MockContext ctx) => [
  for (final call in ctx.getCalls()) call['name'],
];

/// The reference [calls] of a draw of [bar] in the form of the port for
/// the row adapt-bar-clip: without the 'clip' call when the inflateAmount
/// of [bar] is 0.
List<(String, List<Object?>)> _withoutClipAtZero(
  BarElement bar,
  List<(String, List<Object?>)> calls,
) => bar.inflateAmount == 0
    ? [
        for (final call in calls)
          if (call.$1 != 'clip') call,
      ]
    : calls;

/// A drawn bar of 30 x 80 pixels with its top at 20, a border of 2 and the
/// bottom edge skipped.
Map<String, Object?> _drawCfg([Map<String, Object?> extra = const {}]) => {
  'horizontal': false,
  'x': 50,
  'y': 20,
  'base': 100,
  'width': 30,
  'height': 80,
  'options': <String, Object?>{
    'borderColor': 'red',
    'backgroundColor': 'blue',
    'borderWidth': 2,
    'borderRadius': 0,
  },
  'borderSkipped': <String, Object?>{'bottom': true},
  'inflateAmount': 0,
  ...extra,
};

void main() {
  setUpSpecs();

  group('reference', () {
    test('has the reference of Node.js v24.22.1 on arm64', () {
      expect(barReferenceNode, 'v24.22.1');
      expect(barReferenceArch, 'arm64');
      expect(barRangeReference, hasLength(12));
      expect(barDrawReference, hasLength(31));
    });
  });

  group('inRange, inXRange and inYRange', () {
    for (final MapEntry(key: name, value: form) in _optionsForms.entries) {
      group(name, () {
        for (final c in barRangeReference) {
          test(c.name, () {
            final bar = _bar(_withOptions(c.cfg, form), c.animations);
            final final_ = c.useFinalPosition;
            expect([
              for (final (x, y, _, _, _) in c.points)
                (
                  x,
                  y,
                  bar.inRange(x, y, final_),
                  bar.inXRange(x, final_),
                  bar.inYRange(y, final_),
                ),
            ], c.points);
          });
        }
      });
    }

    test('includes the edges within the epsilon of _isBetween', () {
      final bar = BarElement({'base': 0, 'width': 4, 'x': 10, 'y': 15});
      expect(bar.inXRange(8 - 1e-6), isTrue);
      expect(bar.inXRange(8 - 2e-6), isFalse);
      expect(bar.inYRange(15 + 1e-6), isTrue);
      expect(bar.inYRange(15 + 2e-6), isFalse);
    });

    test('is false for NaN coordinates', () {
      final bar = BarElement({'base': 0, 'width': 4, 'x': 10, 'y': 15});
      expect(bar.inRange(double.nan, 5), isFalse);
      expect(bar.inXRange(double.nan), isFalse);
      expect(bar.inYRange(double.nan), isFalse);
    });
  });

  group('getCenterPoint and tooltipPosition', () {
    for (final MapEntry(key: name, value: form) in _optionsForms.entries) {
      group(name, () {
        for (final c in barRangeReference) {
          test(c.name, () {
            final bar = _bar(_withOptions(c.cfg, form), c.animations);
            final final_ = c.useFinalPosition;
            final center = bar.getCenterPoint(final_);
            expect(center, isA<ElementPoint>());
            expect(center, ElementPoint(c.center.$1, c.center.$2));
            expect(
              bar.tooltipPosition(final_),
              ElementPoint(c.tooltip.$1, c.tooltip.$2),
            );
          });
        }
      });
    }
  });

  group('getRange', () {
    for (final MapEntry(key: name, value: form) in _optionsForms.entries) {
      group(name, () {
        for (final c in barRangeReference) {
          test(c.name, () {
            final bar = _bar(_withOptions(c.cfg, form), c.animations);
            expect(bar.getRange('x'), c.rangeX.isNaN ? isNaN : c.rangeX);
            expect(bar.getRange('y'), c.rangeY.isNaN ? isNaN : c.rangeY);
          });
        }
      });
    }

    test('gives half the height for an axis other than x', () {
      final bar = BarElement({'width': 6, 'height': 10});
      expect(bar.getRange('x'), 3);
      expect(bar.getRange('y'), 5);
      expect(bar.getRange('r'), 5);
    });

    test('reads the current width and height, not the final values', () {
      final bar = _bar(
        {'width': 6, 'height': 10},
        [
          ('width', true, 60),
          ('height', true, 100),
        ],
      );
      expect(bar.getRange('x'), 3);
      expect(bar.getRange('y'), 5);
    });
  });

  group('draw', () {
    for (final MapEntry(key: name, value: form) in _optionsForms.entries) {
      group(name, () {
        for (final c in barDrawReference) {
          test(c.name, () {
            final bar = _bar(_withOptions(c.cfg, form), c.animations);
            // adapt-rounded-rect-path: record roundRect as the upstream
            // calls.
            final ctx = UpstreamRoundedRectContext();
            if (c.error == null) {
              bar.draw(ctx);
            } else {
              expect(c.error, 'TypeError');
              expect(() => bar.draw(ctx), throwsA(isA<TypeError>()));
            }
            // adapt-bar-clip: no 'clip' when inflateAmount is 0.
            expect(ctx.getCalls(), _calls(_withoutClipAtZero(bar, c.calls)));
          });
        }
      });
    }

    test('the reference has clipped bars with inflateAmount 0 and not 0', () {
      final clipped = [
        for (final c in barDrawReference)
          if (c.calls.any((call) => call.$1 == 'clip'))
            _bar(c.cfg, c.animations).inflateAmount,
      ];
      expect(clipped.where((amount) => amount == 0), hasLength(16));
      expect(clipped.where((amount) => amount != 0), hasLength(6));
    });

    group('adapt-bar-clip', () {
      test('fills the border with evenodd and no clip for inflateAmount 0', () {
        final ctx = createMockContext();
        _bar(_drawCfg()).draw(ctx);
        expect(_names(ctx), [
          'save',
          'beginPath',
          'rect',
          'rect',
          'setFillStyle',
          'fill',
          'beginPath',
          'rect',
          'setFillStyle',
          'fill',
          'restore',
        ]);
        expect(ctx.getCalls()[5], {
          'name': 'fill',
          'args': ['evenodd', null],
        });
      });

      test('clips to the outer rectangle for another inflateAmount', () {
        for (final amount in [0.33, -0.5, double.nan]) {
          final ctx = createMockContext();
          _bar(_drawCfg({'inflateAmount': amount})).draw(ctx);
          expect(_names(ctx), [
            'save',
            'beginPath',
            'rect',
            'clip',
            'rect',
            'setFillStyle',
            'fill',
            'beginPath',
            'rect',
            'setFillStyle',
            'fill',
            'restore',
          ], reason: '$amount');
        }
      });

      test('skips the clip for -0, as JS -0 === 0', () {
        final ctx = createMockContext();
        _bar(_drawCfg({'inflateAmount': -0.0})).draw(ctx);
        expect(_names(ctx), isNot(contains('clip')));
      });

      test(
        'the inner rectangle is inside the outer one at inflateAmount 0',
        () {
          // The proof of the row: the clip is the outer rectangle, and the
          // border ring and the fill are inside it. Each case gives the
          // rectangles of the calls before the first fill.
          for (final extra in <Map<String, Object?>>[
            {},
            {
              'options': <String, Object?>{
                'borderWidth': <String, Object?>{
                  'top': 3,
                  'right': 1,
                  'bottom': 0,
                  'left': 6,
                },
                'borderRadius': 9,
              },
              'enableBorderRadius': true,
            },
            {
              'options': <String, Object?>{
                'borderWidth': 40,
                'borderRadius': 99,
              },
              'enableBorderRadius': true,
              'borderSkipped': <String, Object?>{},
            },
          ]) {
            final ctx = createMockContext();
            _bar(_drawCfg(extra)).draw(ctx);
            final shapes = [
              for (final call in ctx.getCalls())
                if (call['name'] == 'rect' || call['name'] == 'roundRect')
                  call['args']! as List<Object?>,
            ];
            expect(shapes, hasLength(3), reason: '$extra');
            final outer = shapes[0];
            final inner = shapes[1];
            double at(List<Object?> args, int i) => args[i]! as double;
            expect(at(inner, 0), greaterThanOrEqualTo(at(outer, 0)));
            expect(at(inner, 1), greaterThanOrEqualTo(at(outer, 1)));
            expect(
              at(inner, 0) + at(inner, 2),
              lessThanOrEqualTo(at(outer, 0) + at(outer, 2)),
            );
            expect(
              at(inner, 1) + at(inner, 3),
              lessThanOrEqualTo(at(outer, 1) + at(outer, 3)),
            );
            // The fill of the bar is the inner rectangle.
            expect(shapes[2], inner);
          }
        },
      );
    });

    test('draws no border when the inner rectangle is the outer one', () {
      final ctx = createMockContext();
      _bar(
        _drawCfg({
          'borderSkipped': <String, Object?>{
            'top': true,
            'right': true,
            'bottom': true,
            'left': true,
          },
        }),
      ).draw(ctx);
      expect(_names(ctx), [
        'save',
        'beginPath',
        'rect',
        'setFillStyle',
        'fill',
        'restore',
      ]);
    });

    test('adds a rounded path when a corner has a radius', () {
      final ctx = createMockContext();
      _bar(
        _drawCfg({
          'options': <String, Object?>{'borderWidth': 0, 'borderRadius': 4},
          'enableBorderRadius': true,
        }),
      ).draw(ctx);
      // adapt-rounded-rect-path: one roundRect call in place of the arcs.
      expect(_names(ctx), contains('roundRect'));
      expect(_names(ctx), isNot(contains('arc')));
      expect(_names(ctx), isNot(contains('rect')));
    });

    test('ignores the chart area argument', () {
      final withArea = createMockContext();
      final withoutArea = createMockContext();
      _bar(_drawCfg()).draw(withArea, _Area());
      _bar(_drawCfg()).draw(withoutArea);
      expect(withArea.getCalls(), withoutArea.getCalls());
    });

    // Chart.js ADR 0054 §9: the BorderSkipped of the bar controller reads
    // as the plain object of its edges.
    test('a BorderSkipped draws as the Map of its edges', () {
      for (final skipped in [
        BorderSkipped()..bottom = true,
        BorderSkipped.all(),
        BorderSkipped()..['middle'] = true,
      ]) {
        final typed = createMockContext();
        final plain = createMockContext();
        _bar(_drawCfg({'borderSkipped': skipped})).draw(typed);
        _bar(
          _drawCfg({
            'borderSkipped': <String, Object?>{
              for (final key in skipped.jsKeys()) key: skipped[key],
            },
          }),
        ).draw(plain);
        expect(
          typed.getCalls(),
          plain.getCalls(),
          reason: '${skipped.jsKeys()}',
        );
      }
    });

    test('accepts a typed Map of booleans for borderSkipped', () {
      final typed = createMockContext();
      final plain = createMockContext();
      _bar(
        _drawCfg({
          'borderSkipped': <String, bool>{'bottom': true},
        }),
      ).draw(typed);
      _bar(_drawCfg()).draw(plain);
      expect(typed.getCalls(), plain.getCalls());
    });
  });

  group('access by name', () {
    test('starts in the undefined state', () {
      final bar = BarElement();
      for (final prop in const [
        'horizontal',
        'base',
        'width',
        'height',
        'inflateAmount',
        'borderSkipped',
        'enableBorderRadius',
        'options',
      ]) {
        expect(bar[prop], same(undefined), reason: prop);
      }
      expect(bar.horizontal, isNull);
      expect(bar.base, isNaN);
      expect(bar.width, isNaN);
      expect(bar.height, isNaN);
      expect(bar.inflateAmount, isNaN);
      expect(bar.borderSkipped, isNull);
      expect(bar.enableBorderRadius, isNull);
      expect(bar.options, isNull);
    });

    test('writes a num as a double', () {
      final bar = BarElement();
      for (final prop in const ['base', 'width', 'height', 'inflateAmount']) {
        bar[prop] = 3;
        expect(bar[prop], isA<double>(), reason: prop);
        expect(bar[prop], 3, reason: prop);
      }
      expect(bar.base, 3);
      expect(bar.width, 3);
      expect(bar.height, 3);
      expect(bar.inflateAmount, 3);
    });

    test('writes booleans and the borderSkipped Map', () {
      final skipped = <String, Object?>{'top': true};
      final bar = BarElement()
        ..['horizontal'] = true
        ..['enableBorderRadius'] = false
        ..['borderSkipped'] = skipped;
      expect(bar.horizontal, isTrue);
      expect(bar.enableBorderRadius, isFalse);
      expect(bar.borderSkipped, same(skipped));
      expect(bar['horizontal'], isTrue);
      expect(bar['enableBorderRadius'], isFalse);
      expect(bar['borderSkipped'], same(skipped));
    });

    test('a write of undefined restores the undefined state', () {
      final bar = BarElement(_drawCfg({'enableBorderRadius': true}));
      for (final prop in const [
        'horizontal',
        'base',
        'width',
        'height',
        'inflateAmount',
        'borderSkipped',
        'enableBorderRadius',
      ]) {
        bar[prop] = undefined;
        expect(bar[prop], same(undefined), reason: prop);
      }
      expect(bar.base, isNaN);
      expect(bar.horizontal, isNull);
      expect(bar.borderSkipped, isNull);
    });

    test('the setters write the typed properties', () {
      final bar = BarElement()
        ..horizontal = true
        ..base = 1
        ..width = 2
        ..height = 3
        ..inflateAmount = 0.33
        ..borderSkipped = {'left': true}
        ..enableBorderRadius = true;
      expect(bar['horizontal'], isTrue);
      expect(bar['base'], 1);
      expect(bar['width'], 2);
      expect(bar['height'], 3);
      expect(bar['inflateAmount'], 0.33);
      expect(bar['borderSkipped'], {'left': true});
      expect(bar['enableBorderRadius'], isTrue);
    });

    test('throws an ArgumentError for a value outside the type', () {
      final bar = BarElement();
      for (final (prop, value) in const [
        ('base', '3'),
        ('base', null),
        ('width', true),
        ('height', <String, Object?>{}),
        ('inflateAmount', 'auto'),
        ('horizontal', 1),
        ('horizontal', null),
        ('enableBorderRadius', 'true'),
        ('borderSkipped', true),
        ('borderSkipped', 'start'),
        ('borderSkipped', null),
      ]) {
        expect(
          () => bar[prop] = value,
          throwsArgumentError,
          reason: '$prop = $value',
        );
        expect(bar[prop], same(undefined), reason: prop);
      }
    });

    test('passes the other names to Element', () {
      final options = <String, Object?>{'borderWidth': 1};
      final bar = BarElement()
        ..['x'] = 4
        ..['y'] = 5
        ..['active'] = true
        ..['options'] = options
        ..[r'$context'] = 'context';
      expect(bar.x, 4);
      expect(bar.y, 5);
      expect(bar.active, isTrue);
      expect(bar.options, same(options));
      expect(bar[r'$context'], 'context');
      expect(bar['other'], same(undefined));
    });

    test('the constructor writes cfg through operator []=', () {
      final bar = BarElement({
        'horizontal': true,
        'base': 1,
        'width': 2,
        'height': 3,
        'inflateAmount': 0.5,
        'enableBorderRadius': true,
        r'$context': 7,
      });
      expect(bar.horizontal, isTrue);
      expect(bar.base, 1);
      expect(bar.width, 2);
      expect(bar.height, 3);
      expect(bar.inflateAmount, 0.5);
      expect(bar.enableBorderRadius, isTrue);
      expect(bar[r'$context'], 7);
      expect(() => BarElement({'base': 'a'}), throwsArgumentError);
    });

    test('getProps reads the bar properties by name', () {
      final bar = BarElement({'base': 1, 'horizontal': true})
        ..$animations = {'base': _Animation(isActive: true, to: 9)};
      final current = bar.getProps(const ['base', 'horizontal', 'width']);
      expect(current, same(bar));
      final finals = bar.getProps(const ['base', 'horizontal', 'width'], true);
      expect(finals['base'], 9);
      expect(finals['horizontal'], isTrue);
      expect(finals['width'], same(undefined));
    });
  });

  group('statics', () {
    test('id', () {
      expect(BarElement.id, 'bar');
    });

    test('defaults in the upstream key order', () {
      expect(BarElement.defaults.jsKeys(), [
        'borderSkipped',
        'borderWidth',
        'borderRadius',
        'inflateAmount',
        'pointStyle',
      ]);
      expect(BarElement.defaults['borderSkipped'], 'start');
      expect(BarElement.defaults['borderWidth'], isA<double>());
      expect(BarElement.defaults['borderWidth'], 0);
      expect(BarElement.defaults['borderRadius'], 0);
      expect(BarElement.defaults['inflateAmount'], 'auto');
      expect(BarElement.defaults['pointStyle'], same(undefined));
    });

    test('defaultRoutes in the upstream key order', () {
      expect(BarElement.defaultRoutes, {
        'backgroundColor': 'backgroundColor',
        'borderColor': 'borderColor',
      });
      expect(BarElement.defaultRoutes.keys, [
        'backgroundColor',
        'borderColor',
      ]);
    });

    test('jsClass is BarElement as a value', () {
      // From element.bar.js in Node.js v24.12.0 on x64: the own statics of
      // BarElement are id, defaults and defaultRoutes, and its superclass is
      // Element. 'descriptors' in BarElement is false. typeof BarElement is
      // 'function'.
      final c = BarElement.jsClass;
      expect(c.name, 'BarElement');
      expect(c.superclass, same(Element.jsClass));
      expect(c.id, 'bar');
      expect(c['id'], BarElement.id);
      expect(c['defaults'], same(BarElement.defaults));
      expect(c['defaultRoutes'], same(BarElement.defaultRoutes));
      expect(c.has('descriptors'), isFalse);
      expect(c.isSubclassOf(Element.jsClass), isTrue);
      expect(c.isSubclassOf(c), isFalse);
    });

    test('jsConstruct of jsClass makes a BarElement with the cfg', () {
      // new BarElement({x: 2}) and new BarElement() (Chart.js ADR 0020,
      // section 3).
      final element = jsConstruct(BarElement.jsClass, [
        <String, Object?>{'x': 2},
      ]);
      expect(element, isA<BarElement>());
      expect((element as BarElement)['x'], 2.0);
      expect(jsConstruct(BarElement.jsClass, const []), isA<BarElement>());
      // class My extends BarElement { static id = 'my'; }: the subclass value
      // constructs a BarElement and reads the statics of BarElement.
      final my = JsClass('My', superclass: BarElement.jsClass)..['id'] = 'my';
      expect(jsConstruct(my, const []), isA<BarElement>());
      expect(my.id, 'my');
      expect(BarElement.jsClass.id, 'bar');
      expect(my['defaults'], same(BarElement.defaults));
    });
  });

  group('types', () {
    test('a BarElement is an Element and a VisualElement', () {
      final bar = BarElement();
      expect(bar, isA<Element>());
      expect(bar, isA<types.Element>());
      expect(bar, isA<types.VisualElement>());
    });
  });
}

/// A chart area, which [BarElement.draw] ignores.
final class _Area implements types.ChartArea {
  @override
  double get top => 0;

  @override
  double get right => 100;

  @override
  double get bottom => 100;

  @override
  double get left => 0;

  @override
  double get width => 100;

  @override
  double get height => 100;
}
