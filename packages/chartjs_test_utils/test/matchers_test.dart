// Original code, not ported from Chart.js: tests of the harness matchers.
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart'
    as elements;
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:test/test.dart';

// The pass and fail results follow chartjs-test-utils 0.4.0
// src/matchers.js and src/matchers.options.js: each case states the JS
// expression that gives the same result.

final class _Point implements Point {
  const _Point(this.x, this.y);

  @override
  final double? x;

  @override
  final double? y;
}

/// The inline style of [_Canvas].
final class _Style implements CSSStyleDeclaration {
  _Style(String cssText) {
    for (final declaration in cssText.split(';')) {
      final colon = declaration.indexOf(':');
      if (colon < 0) continue;
      final name = declaration.substring(0, colon).trim();
      final value = declaration.substring(colon + 1).trim();
      if (name.isNotEmpty && value.isNotEmpty) _properties[name] = value;
    }
  }

  final Map<String, String> _properties = {};

  @override
  String getPropertyValue(String property) => _properties[property] ?? '';

  @override
  String getPropertyPriority(String property) => '';

  @override
  void setProperty(String property, String? value, [String? priority]) {
    if (value == null || value.isEmpty) {
      _properties.remove(property);
    } else {
      _properties[property] = value;
    }
  }
}

/// A canvas with the render size [width] x [height] and the inline style
/// [style].
final class _Canvas implements HTMLCanvasElement {
  _Canvas(this.width, this.height, [String style = '']) : style = _Style(style);

  @override
  int width;

  @override
  int height;

  @override
  final _Style style;

  @override
  CanvasRenderingContext2D? getContext(String contextId) => null;

  @override
  String? getAttribute(String name) => null;

  @override
  void setAttribute(String name, String value) {}

  @override
  void removeAttribute(String name) {}
}

/// The mock context of [_Canvas].
final class _Context extends MockContext {
  _Context(this.canvas);

  @override
  final HTMLCanvasElement canvas;
}

/// A platform with the device pixel ratio [ratio].
final class _Platform implements types.BasePlatform {
  _Platform(this.ratio);

  final double ratio;

  @override
  double getDevicePixelRatio() => ratio;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A chart with the members that the chart matchers read.
final class _Chart implements types.Chart {
  _Chart({
    required this.canvas,
    required this.width,
    required this.height,
    CanvasRenderingContext2D? ctx,
    bool noContext = false,
    Object? devicePixelRatio,
    double platformRatio = 1,
  }) : ctx = noContext
           ? null
           : (ctx ?? (canvas == null ? null : _Context(canvas))),
       options = {'devicePixelRatio': devicePixelRatio},
       platform = _Platform(platformRatio);

  @override
  final HTMLCanvasElement? canvas;

  @override
  final CanvasRenderingContext2D? ctx;

  @override
  double width;

  @override
  double height;

  @override
  final Map<String, Object?> options;

  @override
  final types.BasePlatform platform;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A chart on a canvas of [rw] x [rh] with the inline style [style]. The
/// chart has the size of the render size divided by [ratio].
_Chart _chartOn(
  int rw,
  int rh, [
  String style = '',
  double ratio = 1,
]) => _Chart(
  canvas: _Canvas(rw, rh, style),
  width: rw / ratio,
  height: rh / ratio,
  platformRatio: ratio,
);

/// The mismatch text of [matcher] for [actual].
String _mismatch(Matcher matcher, Object? actual) {
  final state = <Object?, Object?>{};
  expect(matcher.matches(actual, state), isFalse);
  return matcher
      .describeMismatch(actual, StringDescription(), state, false)
      .toString();
}

void main() {
  group('toBeCloseToPixel', () {
    test('passes within 2 pixels', () {
      expect(100, toBeCloseToPixel(101.9));
      expect(100, toBeCloseToPixel(98.1));
      expect(100, isNot(toBeCloseToPixel(102)));
      expect(0, toBeCloseToPixel(-1.5));
    });

    test('passes within 0.5% of the larger value', () {
      // 1000 * 0.005 = 5.
      expect(1000, toBeCloseToPixel(1005));
      expect(1005, toBeCloseToPixel(1000));
      expect(1000, isNot(toBeCloseToPixel(1005.1)));
      expect(-1000, toBeCloseToPixel(-995));
    });

    test('coerces with ToNumber and fails on NaN', () {
      // isNaN('10') is false, and '10' - 11 is -1.
      expect('10', toBeCloseToPixel(11));
      expect(null, toBeCloseToPixel(1)); // null is 0.
      expect(undefined, isNot(toBeCloseToPixel(0)));
      expect(double.nan, isNot(toBeCloseToPixel(double.nan)));
      expect('a', isNot(toBeCloseToPixel(0)));
      expect(0, isNot(toBeCloseToPixel(undefined)));
    });

    test('compares infinite values as JS', () {
      // Infinity <= Infinity * 0.005 is true.
      expect(double.infinity, toBeCloseToPixel(0));
      // Infinity - Infinity is NaN, and NaN <= x and NaN < 2 are false.
      expect(double.infinity, isNot(toBeCloseToPixel(double.infinity)));
    });

    test('describes the expected value', () {
      expect(
        StringDescription().addDescriptionOf(toBeCloseToPixel(12)).toString(),
        'close to pixel 12 (0.5% or less than 2 px)',
      );
    });
  });

  group('toBeCloseToPoint', () {
    test('compares x and y after rounding to 2 places', () {
      expect(
        const _Point(11.6161, 12.6559),
        toBeCloseToPoint({
          'x': 11.616,
          'y': 12.656,
        }),
      );
      expect(
        const _Point(11.6161, 12.6559),
        toBeCloseToPoint(const _Point(11.62, 12.66)),
      );
      expect(
        const _Point(11.6149, 12.656),
        isNot(toBeCloseToPoint({'x': 11.616, 'y': 12.656})),
      );
    });

    test('reads a Map as an object literal', () {
      expect({'x': 1, 'y': 2, 'z': 3}, toBeCloseToPoint({'x': 1.001, 'y': 2}));
      // {x: 1}.y is undefined: NaN === NaN is false.
      expect({'x': 1}, isNot(toBeCloseToPoint({'x': 1})));
    });

    test('takes a null member as 0', () {
      // Math.round(null * 100) / 100 is 0.
      expect(const _Point(null, 0), toBeCloseToPoint({'x': 0, 'y': null}));
    });

    test('rounds half up as Math.round', () {
      // Math.round(-0.5) is -0 and Math.round(0.5) is 1.
      expect({'x': -0.005, 'y': 0}, toBeCloseToPoint({'x': 0, 'y': 0}));
      expect({'x': 0.005, 'y': 0}, toBeCloseToPoint({'x': 0.01, 'y': 0}));
    });
  });

  group('toEqualOneOf', () {
    test('passes when the value is === to one value', () {
      expect('top', toEqualOneOf(['left', 'top']));
      expect(2, toEqualOneOf([1, 2.0]));
      expect(-0.0, toEqualOneOf([0]));
      expect(undefined, toEqualOneOf([null, undefined]));
    });

    test('fails on another value or type', () {
      expect('2', isNot(toEqualOneOf([2])));
      expect(null, isNot(toEqualOneOf([undefined])));
      expect(double.nan, isNot(toEqualOneOf([double.nan])));
      expect(<Object?>[], isNot(toEqualOneOf([<Object?>[]])));
      expect(1, isNot(toEqualOneOf([])));
    });

    test('compares objects by reference', () {
      final object = <String, Object?>{'a': 1};
      expect(object, toEqualOneOf([object]));
      expect(
        object,
        isNot(
          toEqualOneOf([
            <String, Object?>{'a': 1},
          ]),
        ),
      );
    });
  });

  group('toEqualOptions', () {
    test('compares the keys of the expected object only', () {
      expect(
        {'a': 1, 'b': 'x', 'c': true},
        toEqualOptions({'a': 1, 'b': 'x'}),
      );
      expect({'a': 1}, isNot(toEqualOptions({'a': 1, 'b': 'x'})));
    });

    test('skips the expected keys that start with _', () {
      expect({'a': 1}, toEqualOptions({'a': 1, '_fallback': true}));
    });

    test('compares nested objects and arrays', () {
      expect(
        {
          'a': {'b': 1, 'c': 2},
          'list': [
            1,
            'x',
            <String, Object?>{'d': 3, 'e': 4},
          ],
        },
        toEqualOptions({
          'a': {'b': 1},
          'list': [
            1,
            'x',
            {'d': 3},
          ],
        }),
      );
    });

    test('an absent key is undefined', () {
      expect(<String, Object?>{}, toEqualOptions({'a': undefined}));
      expect(<String, Object?>{}, isNot(toEqualOptions({'a': null})));
      expect({'a': null}, isNot(toEqualOptions({'a': undefined})));
    });

    test('reads a resolver through its get trap', () {
      final resolver = createResolver([
        <String, Object?>{'color': 'red'},
        <String, Object?>{'color': 'blue', 'size': 2},
      ]);
      expect(resolver, toEqualOptions({'color': 'red', 'size': 2}));
      expect(resolver, isNot(toEqualOptions({'color': 'blue'})));
    });

    // `for (const key in expected)` with `hasOwnProperty` gives the keys of
    // Object.keys. For a resolver, the getOwnPropertyDescriptor trap reads
    // only the first scope (helpers.config.ts:73-75). The values come from
    // the pinned helpers.config.ts and matchers.options.js in Node.js
    // v24.12.0 on x64.
    test('an expected resolver compares the keys of its first scope', () {
      final resolver = createResolver([
        <String, Object?>{'a': 1},
        <String, Object?>{'a': 2, 'b': 3},
      ]);
      expect(resolver.keys, ['a', 'b']);
      expect(<String, Object?>{'a': 1}, toEqualOptions(resolver));
      expect(
        _mismatch(toEqualOptions(resolver), <String, Object?>{'a': 2}),
        'a: Expected 2 to equal 1',
      );
    });

    test('an expected resolver with a fallback chain ends', () {
      // The sub-resolver of `scales` falls back to `scale`. Its ownKeys give
      // `grid`, and `scales.grid.grid` is a resolver again. Object.keys
      // gives no key of `scales`.
      List<Object?> scopes() => [
        <String, Object?>{'scales': <String, Object?>{}},
        <String, Object?>{
          'scale': <String, Object?>{
            'grid': <String, Object?>{'display': true},
          },
        },
        <String, Object?>{
          'scales': <String, Object?>{'_fallback': 'scale'},
        },
      ];
      final resolver = createResolver(scopes());
      final scales = resolver['scales']! as Map<String, Object?>;
      expect(scales.keys, ['grid']);
      expect(
        (scales['grid']! as Map<String, Object?>)['grid'],
        isA<Map<String, Object?>>(),
      );
      expect(
        <String, Object?>{'scales': <String, Object?>{}},
        toEqualOptions(resolver),
      );
      expect(createResolver(scopes()), toEqualOptions(resolver));
      expect(
        _mismatch(toEqualOptions(resolver), <String, Object?>{}),
        'scales: Expected undefined to be an object',
      );
    });

    test('reports each difference with its path', () {
      expect(
        _mismatch(
          toEqualOptions({
            'a': 1,
            'b': {'c': 'x'},
            'd': [1, 2],
            'e': {'f': 1},
            'g': [1],
          }),
          {
            'a': 2,
            'b': {'c': 'y'},
            'd': [1],
            'e': 5,
            'g': 'z',
          },
        ),
        [
          'a: Expected 2 to equal 1',
          'b.c: Expected "y" to equal "x"',
          'd.length: Expected 1 to equal 2',
          'd[1]: Expected undefined to equal 2',
          'e: Expected 5 to be an object',
          'e.f: Expected undefined to equal 1',
          'g: Expected "z" to be an array',
          'g.length: Expected undefined to equal 1',
          'g[0]: Expected undefined to equal 1',
        ].join('\n'),
      );
    });

    test('formats objects and arrays as JSON', () {
      expect(
        _mismatch(
          toEqualOptions({'a': 1}),
          {
            'a': [1, 'x'],
          },
        ),
        'a: Expected [1,"x"] to equal 1',
      );
    });

    // matchers.options.js:1-3: isObject is true for an instance of a class,
    // so an element is an actual object (Chart.js ADR 0039, section 10). The
    // results come from a probe of phase 8: the pinned Chart.js build and
    // matchers.options.js at v0.4.0 in Node.js v24.12.0 on x64.
    group('an element', () {
      elements.PointElement point() => elements.PointElement({
        'x': 1,
        'y': 2,
        'options': <String, Object?>{
          'radius': 3,
          'nested': <String, Object?>{'a': 1},
        },
      });

      test('passes with the expected keys', () {
        expect(
          point(),
          toEqualOptions({
            'x': 1,
            'options': {
              'radius': 3,
              'nested': {'a': 1},
            },
          }),
        );
        expect(
          {'el': point()},
          toEqualOptions({
            'el': {'x': 1},
          }),
        );
      });

      test('fails with a message for a wrong key', () {
        expect(
          _mismatch(toEqualOptions({'x': 2}), point()),
          'x: Expected 1 to equal 2',
        );
        expect(
          _mismatch(
            toEqualOptions({
              'options': {
                'nested': {'a': 2},
              },
            }),
            point(),
          ),
          'options.nested.a: Expected 1 to equal 2',
        );
      });

      test('an absent name is undefined', () {
        expect(point(), toEqualOptions({'z': undefined}));
        expect(
          _mismatch(toEqualOptions({'z': null}), point()),
          'z: Expected undefined to equal null',
        );
      });

      test('an element has no JSON in a message', () {
        // Upstream writes the JSON of the own keys of the element. The port
        // has no list of the keys, so the report gives null. The result of
        // the match is the same.
        expect(
          _mismatch(
            toEqualOptions({
              'el': [1],
            }),
            {'el': point()},
          ),
          [
            'el: Expected null to be an array',
            'el.length: Expected undefined to equal 1',
            'el[0]: Expected undefined to equal 1',
          ].join('\n'),
        );
      });

      // The row harness-expected-element. The upstream results come from a
      // probe of phase 8 in Node.js v24.12.0 on x64.
      group('harness-expected-element', () {
        test('an expected element compares by identity', () {
          // Port difference: upstream compares the own keys of an expected
          // element. Thus another element with the same own keys passes,
          // and a plain object with these keys passes. No ported spec gives
          // an element as an expected value.
          final element = point();
          expect({'el': element}, toEqualOptions({'el': element}));
          expect({'el': point()}, isNot(toEqualOptions({'el': element})));
          expect(
            {
              'el': <String, Object?>{
                'x': 1,
                'y': 2,
                'active': false,
                'options': <String, Object?>{
                  'radius': 3,
                  'nested': <String, Object?>{'a': 1},
                },
              },
            },
            isNot(toEqualOptions({'el': element})),
          );
        });
      });
    });

    test('a mismatch without a result of matches gives no text', () {
      // package:matcher calls describeMismatch also after a throw in
      // matches. Then the report shows the throw.
      expect(
        toEqualOptions({
          'a': 1,
        }).describeMismatch(1, StringDescription(), {}, false).toString(),
        '',
      );
    });
  });

  // matchers.js:106-174 with the three hunks of the row
  // harness-chart-matchers (Chart.js ADR 0022, section 9). The display size
  // values of a canvas with one px style come from Chrome (probe SP2 of
  // Chart.js ADR 0022).
  group('harness-chart-matchers', () {
    test('toBeValidChart passes for a chart with a canvas and a context', () {
      expect(_chartOn(300, 150), toBeValidChart());
    });

    test('toBeValidChart gives the upstream messages in their order', () {
      expect(
        _mismatch(toBeValidChart(), 5),
        'Expected 5 to be an instance of Chart',
      );
      expect(
        _mismatch(
          toBeValidChart(),
          _Chart(canvas: null, width: 300, height: 150),
        ),
        'Expected canvas to be an instance of HTMLCanvasElement',
      );
      expect(
        _mismatch(
          toBeValidChart(),
          _Chart(
            canvas: _Canvas(300, 150),
            width: 300,
            height: 150,
            noContext: true,
          ),
        ),
        'Expected context to be an instance of CanvasRenderingContext2D',
      );
      expect(
        _mismatch(
          toBeValidChart(),
          _Chart(canvas: _Canvas(300, 150), width: 300, height: double.nan),
        ),
        'Expected height to be a strict finite number',
      );
      expect(
        _mismatch(
          toBeValidChart(),
          _Chart(
            canvas: _Canvas(300, 150),
            width: double.infinity,
            height: 150,
          ),
        ),
        'Expected width to be a strict finite number',
      );
    });

    test('a canvas without a px style has the render size', () {
      expect(
        _chartOn(300, 150),
        toBeChartOfSize({'dw': 300, 'dh': 150, 'rw': 300, 'rh': 150}),
      );
    });

    test('a side with a px style has that value', () {
      expect(
        _chartOn(300, 150, 'width: 320px; height: 240px'),
        toBeChartOfSize({'dw': 320, 'dh': 240, 'rw': 300, 'rh': 150}),
      );
      // parseInt('345.42px', 10) is 345.
      expect(
        _chartOn(300, 150, 'width: 345.42px; height: 150px'),
        toBeChartOfSize({'dw': 345, 'dh': 150, 'rw': 300, 'rh': 150}),
      );
    });

    test('one px style keeps the aspect ratio of the render size', () {
      // 405 * 150 / 300 is 202.5, and parseInt truncates it.
      expect(
        _chartOn(300, 150, 'width: 405px'),
        toBeChartOfSize({'dw': 405, 'dh': 202, 'rw': 300, 'rh': 150}),
      );
      // 425 * 410 / 400 is 435.625.
      expect(
        _chartOn(400, 410, 'width: 425px'),
        toBeChartOfSize({'dw': 425, 'dh': 435, 'rw': 400, 'rh': 410}),
      );
      // 401 * 400 / 200 is 802.
      expect(
        _chartOn(400, 200, 'height: 401px'),
        toBeChartOfSize({'dw': 802, 'dh': 401, 'rw': 400, 'rh': 200}),
      );
    });

    test('display none gives auto, thus 0, for a side without a px style', () {
      expect(
        _chartOn(300, 150, 'display: none'),
        toBeChartOfSize({'dw': 0, 'dh': 0, 'rw': 300, 'rh': 150}),
      );
      expect(
        _chartOn(300, 150, 'display: none; width: 200px'),
        toBeChartOfSize({'dw': 200, 'dh': 0, 'rw': 300, 'rh': 150}),
      );
    });

    test('the pixel ratio is the option, else the one of the platform', () {
      // The platform ratio 3: the chart is a third of the render size.
      expect(
        _chartOn(960, 720, 'width: 320px; height: 240px', 3),
        toBeChartOfSize({'dw': 320, 'dh': 240, 'rw': 960, 'rh': 720}),
      );
      // The option `devicePixelRatio` 2 takes the place of the platform.
      final chart = _Chart(
        canvas: _Canvas(640, 480, 'width: 320px; height: 240px'),
        width: 320,
        height: 240,
        devicePixelRatio: 2,
        platformRatio: 3,
      );
      expect(
        chart,
        toBeChartOfSize({'dw': 320, 'dh': 240, 'rw': 640, 'rh': 480}),
      );
    });

    test('toBeChartOfSize gives the upstream messages in their order', () {
      final size = {'dw': 300, 'dh': 150, 'rw': 300, 'rh': 150};
      expect(_mismatch(toBeChartOfSize(size), 5), contains('instance of'));
      // The sanity check of the chart height against the render height.
      expect(
        _mismatch(
          toBeChartOfSize(size),
          _Chart(canvas: _Canvas(300, 150), width: 300, height: 100),
        ),
        'Expected chart height 100 to be equal to original render height '
        '150',
      );
      expect(
        _mismatch(
          toBeChartOfSize(size),
          _Chart(canvas: _Canvas(300, 150), width: 200, height: 150),
        ),
        'Expected chart width 200 to be equal to original render width 300',
      );
      // A validity check replaces the message of a sanity check.
      expect(
        _mismatch(
          toBeChartOfSize({'dw': 300, 'dh': 100, 'rw': 300, 'rh': 150}),
          _Chart(canvas: _Canvas(300, 150), width: 300, height: 100),
        ),
        'Expected display height 150 to be equal to 100',
      );
      expect(
        _mismatch(
          toBeChartOfSize({'dw': 30, 'dh': 150, 'rw': 300, 'rh': 150}),
          _chartOn(300, 150),
        ),
        'Expected display width 300 to be equal to 30',
      );
      expect(
        _mismatch(
          toBeChartOfSize({'dw': 300, 'dh': 150, 'rw': 300, 'rh': 15}),
          _chartOn(300, 150),
        ),
        'Expected render height 150 to be equal to 15',
      );
      expect(
        _mismatch(
          toBeChartOfSize({'dw': 300, 'dh': 150, 'rw': 3, 'rh': 150}),
          _chartOn(300, 150),
        ),
        'Expected render width 300 to be equal to 3',
      );
    });
  });
}
