// Original code, not ported from Chart.js: scalar bar draw equivalence.
// Signed-zero probes must retain their double literals.
// ignore_for_file: prefer_int_literals
@TestOn('vm')
library;

import 'dart:collection';
import 'dart:ui' as ui;

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/elements/element.bar.dart';
import 'package:flutter_chartjs_port/src/elements/element_options.dart';
import 'package:flutter_chartjs_port/src/options/props.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart'
    show ChartPaint;
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

import '../canvas/pixel_compare.dart';

// The exact-class guard keeps this subclass on the unchanged draw path.
class _ReferenceBar extends BarElement {
  _ReferenceBar(super.cfg);
}

class _ReadMap extends MapBase<String, Object?> {
  _ReadMap(this.values_, this.reads);
  final Map<String, Object?> values_;
  final List<String> reads;
  @override
  Object? operator [](Object? key) {
    reads.add('$key');
    return values_[key];
  }

  @override
  void operator []=(String key, Object? value) => values_[key] = value;
  @override
  Iterable<String> get keys => values_.keys;
  @override
  void clear() => values_.clear();
  @override
  Object? remove(Object? key) => values_.remove(key);
}

@immutable
class _EffectfulEquality {
  const _EffectfulEquality(this.onEquals);
  final void Function() onEquals;
  @override
  bool operator ==(Object other) {
    onEquals();
    return false;
  }

  @override
  int get hashCode => 0;
}

BorderSkipped _skip(int mask) => BorderSkipped()
  ..top = mask & 1 != 0
  ..right = mask & 2 != 0
  ..bottom = mask & 4 != 0
  ..left = mask & 8 != 0;

Map<String, Object?> _config({
  bool horizontal = false,
  double x = 40.25,
  double y = 22.5,
  double base = 100.75,
  double width = 25.5,
  double height = 25.5,
  int skip = 0,
  Object? borderWidth = 1.0,
  Object? radius = 0.0,
  double inflation = 0,
  bool transparent = false,
}) => {
  'x': x,
  'y': y,
  'base': base,
  'width': width,
  'height': height,
  'horizontal': horizontal,
  'borderSkipped': _skip(skip),
  'enableBorderRadius': true,
  'inflateAmount': inflation,
  'options': BarOptions({
    'borderWidth': borderWidth,
    'borderRadius': radius,
    'borderColor': ChartPaint.solid(
      ui.Color(transparent ? 0x804488CC : 0xFF4488CC),
    ),
    'backgroundColor': ChartPaint.solid(
      ui.Color(transparent ? 0x60DD8855 : 0xFFDD8855),
    ),
  }),
};

// Check signed zero as well as non-finite coordinates in recorded arguments.
Object? _normalize(Object? value) {
  if (value is double) {
    if (!value.isFinite) return value.toString();
    if (value == 0 && value.isNegative) return '-0';
  }
  if (value is List) return value.map(_normalize).toList();
  if (value is Map) {
    return {for (final key in value.keys) key: _normalize(value[key])};
  }
  return value;
}

Object? _calls(BarElement bar) {
  final context = createMockContext();
  bar.draw(context);
  return _normalize(context.getCalls());
}

void _expectCalls(Map<String, Object?> cfg, String reason) => expect(
  _calls(BarElement(cfg)),
  _calls(_ReferenceBar(cfg)),
  reason: reason,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final horizontal in [false, true]) {
    test('canvas traces: orientation $horizontal, every skipped-edge mask', () {
      for (var mask = 0; mask < 16; mask++) {
        for (final border in [-2.0, -0.0, 0.0, 0.3, 1.0, 30.0]) {
          for (final size in [-2.0, -0.0, 0.0, 0.02, 4.0, 25.5]) {
            for (final base in [-30.0, 22.5, 100.75]) {
              _expectCalls(
                _config(
                  horizontal: horizontal,
                  skip: mask,
                  borderWidth: border,
                  width: size,
                  height: size,
                  base: base,
                ),
                '$horizontal, $mask, $border, $size, $base',
              );
            }
          }
        }
      }
    });
  }

  test('signed zeros, overflow, non-finite and unused dimensions', () {
    for (final horizontal in [false, true]) {
      for (final n in [
        -0.0,
        0.0,
        double.nan,
        double.infinity,
        -double.infinity,
        1e308,
      ]) {
        _expectCalls(
          _config(horizontal: horizontal, x: n, y: n, base: n),
          '$horizontal $n coordinates',
        );
        _expectCalls(
          _config(horizontal: horizontal, width: n, height: n),
          '$horizontal $n dimensions',
        );
        _expectCalls(
          _config(horizontal: horizontal, borderWidth: n),
          '$horizontal $n border',
        );
      }
    }
    for (final horizontal in [false, true]) {
      for (var mask = 0; mask < 16; mask++) {
        _expectCalls(
          _config(
            horizontal: horizontal,
            x: -0.0,
            y: -0.0,
            width: -0.0,
            height: -0.0,
            skip: mask,
          ),
          'coupled signed zeros $horizontal $mask',
        );
      }
    }
    _expectCalls(
      _config(x: -0.0, y: -0.0, inflation: -0.0),
      'negative zero inflation',
    );
    _expectCalls(
      _config(horizontal: true, x: -0.0, y: -0.0, inflation: -0.0),
      'horizontal negative zero inflation',
    );
    _expectCalls(_config(height: double.nan), 'vertical looping height');
    _expectCalls(
      _config(horizontal: true, width: double.nan),
      'horizontal unused width',
    );
    _expectCalls(_config(y: -1e308, base: 1e308), 'height overflow');
  });

  test('radius, inflation and non-scalar options retain the original path', () {
    for (final radius in <Object?>[
      null,
      '0',
      4,
      {'topLeft': 4},
      double.nan,
    ]) {
      for (final inflation in [-0.0, 0.0, -0.33, 0.33, double.nan]) {
        _expectCalls(
          _config(radius: radius, inflation: inflation),
          '$radius $inflation',
        );
      }
    }
    for (final width in <Object?>[
      null,
      '2',
      {'top': 3, 'left': 2},
    ]) {
      _expectCalls(_config(borderWidth: width), '$width');
    }
    final cfg = _config();
    final options = (cfg['options']! as BarOptions)..jsDelete('borderRadius');
    _expectCalls(cfg, 'absent radius');
    options
      ..jsWrite('borderRadius', 0)
      ..jsDelete('borderWidth');
    _expectCalls(cfg, 'absent width');
    options.jsWrite('borderWidth', 1.0);
    (cfg['borderSkipped']! as BorderSkipped).jsWrite('left', 'yes');
    _expectCalls(cfg, 'foreign skipped edge');
  });

  test('custom option and edge getters keep their original reads', () {
    for (final customOptions in [false, true]) {
      for (final customEdges in [false, true]) {
        final observed = <List<String>>[];
        final traces = <Object?>[];
        for (final reference in [false, true]) {
          final reads = <String>[];
          final cfg = _config();
          if (customOptions) {
            cfg['options'] = _ReadMap({
              'borderColor': const ChartPaint.solid(ui.Color(0xFF4488CC)),
              'backgroundColor': const ChartPaint.solid(ui.Color(0xFFDD8855)),
              'borderWidth': 1.0,
              'borderRadius': 0.0,
            }, reads);
          }
          if (customEdges) {
            cfg['borderSkipped'] = _ReadMap({'bottom': true}, reads);
          }
          final bar = reference ? _ReferenceBar(cfg) : BarElement(cfg);
          reads.clear();
          traces.add(_calls(bar));
          observed.add(reads);
        }
        expect(traces[0], traces[1]);
        expect(observed[0], observed[1]);
      }
    }
  });

  test('the radius guard never invokes custom equality', () {
    var calls = 0;
    final radius = _EffectfulEquality(() => calls++);
    _expectCalls(_config(radius: radius), 'effectful equality');
    expect(calls, 0);
  });

  for (final horizontal in [false, true]) {
    for (final transparent in [false, true]) {
      test('exact pixels, state and path: $horizontal/$transparent', () async {
        for (final scale in [0.75, 1.0, 2.625]) {
          for (final width in [0.02, 3.0, 25.5]) {
            for (final border in [0.0, 1.0, 30.0]) {
              final cfg = _config(
                horizontal: horizontal,
                transparent: transparent,
                width: width,
                height: width,
                borderWidth: border,
                skip: 4,
              );
              Future<Render> render(BarElement bar) => renderContext((ctx) {
                ctx
                  ..fillStyle = const ui.Color(0xFFEEEEEE)
                  ..fillRect(0, 0, 160, 160)
                  ..save()
                  ..setTransform(scale, 0, 0, scale, 0.5, 0.5)
                  ..beginPath()
                  ..rect(1, 1, 110, 120)
                  ..clip()
                  ..fillStyle = const ui.Color(0xFF00BB55);
                bar.draw(ctx);
                // The bar restores styles but leaves its final inner path.
                ctx
                  ..strokeStyle = const ui.Color(0x80443322)
                  ..lineWidth = 0.5
                  ..stroke()
                  ..fillRect(2, 2, 5, 5)
                  ..restore();
              });
              final actual = await render(BarElement(cfg));
              final reference = await render(_ReferenceBar(cfg));
              expect(
                actual.bytes,
                reference.bytes,
                reason: '$scale $width $border',
              );
            }
          }
        }
      });
    }
  }
}
