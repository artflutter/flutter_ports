// Original code, not ported from Chart.js: element.bar cases with no spec.
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs/src/core/core.element.dart';
import 'package:flutter_chartjs/src/elements/element.bar.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/types/animation.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;
import 'package:test/test.dart';

import 'bar_reference.dart';

// Upstream behavior that test/specs/element.bar.tests.js does not check
// (AGENTS.md rule 3).
//
// The expected results of the range methods, getCenterPoint,
// tooltipPosition, getRange and draw come from
// src/elements/element.bar.js at v4.5.1, run with type stripping in Node.js
// v24.12.0 on x64. The draw calls go to the upstream mock context of
// chartjs-test-utils 0.4.0, padded to the parameter lists of MockContext
// (harness-mock-optional-args). bar_reference.dart has the data, which
// tool/reference/bar_reference.mjs writes (Chart.js ADR 0010).
//
// The range results are booleans, and the points are the results of one
// IEEE operation. Thus the tests compare them exactly. The draw calls compare
// each number with closeTo (Chart.js ADR 0009), and NaN with isNaN.

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
          if (arg is num) arg.isNaN ? isNaN : closeTo(arg, 1e-9) else arg,
      ],
    },
];

/// The names of the draw calls of [ctx].
List<Object?> _names(MockContext ctx) => [
  for (final call in ctx.getCalls()) call['name'],
];

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
    test('has the reference of Node.js v24.12.0 on x64', () {
      expect(barReferenceNode, 'v24.12.0');
      expect(barReferenceArch, 'x64');
      expect(barRangeReference, hasLength(12));
      expect(barDrawReference, hasLength(31));
    });
  });

  group('inRange, inXRange and inYRange', () {
    for (final c in barRangeReference) {
      test(c.name, () {
        final bar = _bar(c.cfg, c.animations);
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
    for (final c in barRangeReference) {
      test(c.name, () {
        final bar = _bar(c.cfg, c.animations);
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

  group('getRange', () {
    for (final c in barRangeReference) {
      test(c.name, () {
        final bar = _bar(c.cfg, c.animations);
        expect(bar.getRange('x'), c.rangeX.isNaN ? isNaN : c.rangeX);
        expect(bar.getRange('y'), c.rangeY.isNaN ? isNaN : c.rangeY);
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
    for (final c in barDrawReference) {
      test(c.name, () {
        final bar = _bar(c.cfg, c.animations);
        final ctx = createMockContext();
        if (c.error == null) {
          bar.draw(ctx);
        } else {
          expect(c.error, 'TypeError');
          expect(() => bar.draw(ctx), throwsA(isA<TypeError>()));
        }
        expect(ctx.getCalls(), _calls(c.calls));
      });
    }

    test('fills the border with evenodd inside the clip', () {
      final ctx = createMockContext();
      _bar(_drawCfg()).draw(ctx);
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
      ]);
      expect(ctx.getCalls()[6], {
        'name': 'fill',
        'args': ['evenodd', null],
      });
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
      expect(_names(ctx), contains('arc'));
      expect(_names(ctx), isNot(contains('rect')));
    });

    test('ignores the chart area argument', () {
      final withArea = createMockContext();
      final withoutArea = createMockContext();
      _bar(_drawCfg()).draw(withArea, _Area());
      _bar(_drawCfg()).draw(withoutArea);
      expect(withArea.getCalls(), withoutArea.getCalls());
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
      expect(BarElement.defaults.keys, [
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
