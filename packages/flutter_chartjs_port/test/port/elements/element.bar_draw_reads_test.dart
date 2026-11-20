// Original code, not ported from Chart.js: the option reads of the bar draw.

import 'dart:ui' as ui;

import 'package:chartjs_test_utils/pure.dart' show MockContext;
import 'package:flutter_chartjs_port/chartjs_core.dart';
import 'package:test/test.dart';

const _blue = ui.Color(0xFF4F6BED);
const _teal = ui.Color(0xB011A098);
const _dark = ui.Color(0xFF1E293B);
const _red = ui.Color(0xFFDD4400);

const _gradient = ChartGradient.linear(ui.Offset.zero, ui.Offset(9, 0), [
  _red,
  _teal,
]);

// The exact-class guard of the draw declines this subclass: it takes the
// ordinary sequence of `boundingRects`.
class _ReferenceBar(super.cfg) extends BarElement;

typedef _MakeBar = BarElement Function(Map<String, Object?> cfg);

/// The canvas calls of a vertical and of a horizontal bar with [options].
String _calls(_MakeBar make, Object? Function() options, double inflate) {
  final ctx = MockContext();
  for (final horizontal in [false, true]) {
    make({
      'x': 30.0,
      'y': horizontal ? 60.0 : 40.0,
      'base': horizontal ? 20.0 : 120.0,
      'width': 9.0,
      'height': 9.0,
      'horizontal': horizontal,
      'enableBorderRadius': true,
      'inflateAmount': inflate,
      'borderSkipped': BorderSkipped()..bottom = true,
      'options': options(),
    }).draw(ctx);
  }
  return '${ctx.getCalls()}';
}

/// The style that each `fillStyle` write of a bar with [options] got.
List<Object?> _styles(_MakeBar make, Object? options) {
  final ctx = MockContext();
  make({
    'x': 30.0,
    'y': 40.0,
    'base': 120.0,
    'width': 9.0,
    'height': 9.0,
    'horizontal': false,
    'enableBorderRadius': true,
    'inflateAmount': 0.0,
    'borderSkipped': BorderSkipped()..bottom = true,
    'options': options,
  }).draw(ctx);
  return [
    for (final call in ctx.getCalls())
      if (call['name'] == 'setFillStyle') (call['args']! as List).single,
  ];
}

void main() {
  // Some cases write a color of another type on purpose (the oracle O2).
  setUp(() {
    final audit = foreignAudit;
    foreignAudit = null;
    addTearDown(() => foreignAudit = audit);
  });

  // The two colors of each case, with a border of 1. A key with the value
  // [_absent] is not in the options.
  const absent = _Absent();
  final colors = <String, (Object?, Object?)>{
    'two paints': (
      const ChartPaint.solid(_dark),
      const ChartPaint.solid(_blue),
    ),
    'one paint object': (
      const ChartPaint.solid(_blue),
      const ChartPaint.solid(_blue),
    ),
    'gradients': (_gradient, _gradient),
    'a paint and a gradient': (const ChartPaint.solid(_dark), _gradient),
    'colors of dart:ui': (_dark, _blue),
    'a string and a number': ('red', 12),
    'a number and a paint': (12, const ChartPaint.solid(_blue)),
    'null colors': (null, null),
    'a null border': (null, const ChartPaint.solid(_blue)),
    'undefined colors': (undefined, undefined),
    'absent colors': (absent, absent),
    'an absent border': (absent, const ChartPaint.solid(_blue)),
    'an absent background': (const ChartPaint.solid(_dark), absent),
  };

  Map<String, Object?> source(
    (Object?, Object?) pair, {
    Object? borderWidth = 1.0,
    Object? radius = 0.0,
  }) => <String, Object?>{
    'borderWidth': borderWidth,
    'borderRadius': radius,
    if (!identical(pair.$1, absent)) 'borderColor': pair.$1,
    if (!identical(pair.$2, absent)) 'backgroundColor': pair.$2,
  };

  group('the colors of typed options are those of the read by name', () {
    for (final MapEntry(key: name, value: pair) in colors.entries) {
      for (final (kind, make) in <(String, _MakeBar)>[
        ('the bar', BarElement.new),
        ('a subclass', _ReferenceBar.new),
      ]) {
        test('$name, $kind', () {
          for (final inflate in [0.0, 0.33]) {
            for (final width in <Object?>[1.0, 0.0]) {
              final typed = _calls(
                make,
                () => BarOptions(source(pair, borderWidth: width)),
                inflate,
              );
              final byName = _calls(
                make,
                () => GenericElementOptions(source(pair, borderWidth: width)),
                inflate,
              );
              expect(typed, byName, reason: 'inflate $inflate, width $width');
              expect(typed, contains('fill'));
            }
          }
        });
      }
    }

    test('each fill style is the style of the raw value of its key', () {
      const dark = ChartPaint.solid(_dark);
      const blue = ChartPaint.solid(_blue);
      for (final make in <_MakeBar>[BarElement.new, _ReferenceBar.new]) {
        // The border fill comes first, then the background fill. The style
        // of a solid paint is its color.
        expect(_styles(make, BarOptions(source((dark, blue)))), [_dark, _blue]);
        expect(_styles(make, BarOptions(source((_gradient, _dark)))), [
          _gradient,
          _dark,
        ]);
        // A foreign value goes to the canvas as it is.
        expect(_styles(make, BarOptions(source(('red', 12)))), ['red', 12]);
        // An absent key and a null color give no style: the canvas keeps
        // its style, as the DOM ignores `undefined`.
        expect(_styles(make, BarOptions(source((absent, absent)))), [
          null,
          null,
        ]);
        expect(_styles(make, BarOptions(source((null, null)))), [null, null]);
      }
    });

    test('a later write of a key gives the new color', () {
      for (final make in <_MakeBar>[BarElement.new, _ReferenceBar.new]) {
        final options = BarOptions(
          source((
            const ChartPaint.solid(_dark),
            const ChartPaint.solid(_blue),
          )),
        );
        // A paint, then a foreign value, then a paint again: the typed
        // field is empty for the foreign value.
        options['backgroundColor'] = 'red';
        expect(_styles(make, options).last, 'red');
        options['backgroundColor'] = const ChartPaint.solid(_teal);
        expect(_styles(make, options).last, _teal);
        options['borderColor'] = 7;
        expect(_styles(make, options).first, 7);
        expect(_styles(make, options.clone()), [7, _teal]);
      }
    });
  });

  group('the bar against the ordinary sequence of a subclass', () {
    // The width and the radius of each case, as a `double`, as an `int` and
    // as a value that is no number.
    final numbers = <String, (Object?, Object?)>{
      'doubles': (1.0, 0.0),
      'whole numbers': (2, 0),
      'a double width and a whole radius': (1.5, 0),
      'a whole width and a double radius': (1, 0.0),
      'a width of 0': (0.0, 0.0),
      'a negative zero as the radius': (1.0, -0.0),
      'a negative width': (-3.0, 0.0),
      'a wide border': (40, 0),
      'a width of NaN': (double.nan, 0.0),
      'a width of infinity': (double.infinity, 0.0),
      'a radius of NaN': (1.0, double.nan),
      'a radius': (1.0, 3.0),
      'a whole radius': (1, 3),
      'a width object': (<String, Object?>{'top': 2, 'left': 1}, 0.0),
      'a radius object': (1.0, <String, Object?>{'topLeft': 2}),
      'a string as the width': ('2', 0.0),
      'a string as the radius': (1.0, '0'),
      'a null width': (null, 0.0),
      'a null radius': (1.0, null),
      'a bool as the width': (true, 0.0),
    };

    for (final MapEntry(key: name, value: pair) in numbers.entries) {
      test(name, () {
        for (final inflate in [0.0, 0.33]) {
          Object? options() => BarOptions(
            source(
              (const ChartPaint.solid(_dark), const ChartPaint.solid(_blue)),
              borderWidth: pair.$1,
              radius: pair.$2,
            ),
          );
          final bar = _calls(BarElement.new, options, inflate);
          final reference = _calls(_ReferenceBar.new, options, inflate);
          expect(bar, reference, reason: 'inflate $inflate');
          expect(bar, contains('fill'));
        }
      });
    }
  });

  test('an element with no options throws the error of the read by name', () {
    for (final make in <_MakeBar>[BarElement.new, _ReferenceBar.new]) {
      final bar = make({
        'x': 30.0,
        'y': 40.0,
        'base': 120.0,
        'width': 9.0,
        'horizontal': false,
        'inflateAmount': 0.0,
        'borderSkipped': BorderSkipped(),
      });
      final ctx = MockContext();
      expect(() => bar.draw(ctx), throwsA(isA<TypeError>()));
      expect(ctx.getCalls(), isEmpty);
    }
  });
}

// The mark of a key that is not in the options.
final class const _Absent();
