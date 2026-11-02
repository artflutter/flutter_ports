// Original code, not ported from Chart.js: Color-only chart input contract.
// Keep setup and assertions separate in contract tests.
// ignore_for_file: cascade_invocations
@TestOn('vm')
library;

import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/chartjs.dart' as core show Animation;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_chartjs_port/helpers.dart' as helpers;
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart'
    as core_defaults;
import 'package:flutter_chartjs_port/src/elements/element_options.dart';
import 'package:flutter_chartjs_port/src/kurkle_color/index.esm.dart'
    as numerical;
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
import 'package:flutter_chartjs_port/src/typed/lower.dart'
    show ChartConfigLowering;
import 'package:flutter_test/flutter_test.dart';

const _blue = ui.Color(0xFF2050C0);
const _red = ui.Color(0x80FF0000);

Map<String, Object?> _raw([Object? color = _blue]) => {
  'type': 'line',
  'data': <String, Object?>{
    'labels': <Object?>['red', 'blue', 'green'],
    'datasets': <Object?>[
      <String, Object?>{
        'data': <Object?>[1, 3, 2],
        'backgroundColor': color,
      },
    ],
  },
  'options': <String, Object?>{
    'animation': false,
    'responsive': false,
    'plugins': <String, Object?>{'legend': false, 'tooltip': false},
  },
};

void _destroy(Chart chart, UiCanvasElement canvas) {
  chart.destroy();
  canvas.getContext2d().dispose();
}

void main() {
  test('raw defaults are native before chart construction', () {
    final before = core_defaults.defaults
        .lookup(OptionKey.backgroundColor)!
        .raw;
    expect(before, const ui.Color.fromRGBO(0, 0, 0, 0.1));
    expect(core_defaults.defaults['backgroundColor'], same(before));
    final canvas = UiCanvasElement(width: 120, height: 80);
    final chart = Chart(canvas, _raw());
    expect(
      core_defaults.defaults.lookup(OptionKey.backgroundColor)!.raw,
      same(before),
    );
    expect(core_defaults.defaults['backgroundColor'], same(before));
    _destroy(chart, canvas);
  });
  test('public defaults expose native Color before chart construction', () {
    expect(Chart.defaults['color'], isA<ui.Color>());
  });
  test('native canvas retains Color identity and rejects strings', () {
    final canvas = UiCanvasElement(width: 120, height: 80);
    final context = canvas.getContext2d();
    const color = ui.Color.from(
      alpha: 0.1234,
      red: 0.8,
      green: 0.3,
      blue: 0.2,
      colorSpace: ui.ColorSpace.displayP3,
    );
    context.fillStyle = color;
    expect(identical(context.fillStyle, color), isTrue);
    for (final value in ['red', '#2050c0', 'rgb(32,80,192)', '', 42]) {
      expect(() => context.fillStyle = value, throwsArgumentError);
      expect(() => context.strokeStyle = value, throwsArgumentError);
      expect(identical(context.fillStyle, color), isTrue);
    }
    context.dispose();
  });

  test('raw CSS colors fail before acquiring the canvas', () {
    final canvas = UiCanvasElement(width: 120, height: 80);
    for (final value in [
      'red',
      '#2050c0',
      <Object?>[_blue, 'blue'],
    ]) {
      expect(() => Chart(canvas, _raw(value)), throwsArgumentError);
      expect(Chart.getChart(canvas), isNull);
    }
    final chart = Chart(canvas, _raw());
    expect(
      (chart.getDatasetMeta(0).data.first.options! as PointOptions)
          .backgroundColor,
      _blue,
    );
    _destroy(chart, canvas);
  });

  test('typed scalars, lists and callbacks keep native Color values', () {
    for (final dataset in [
      const LineDataset(data: [1, 3, 2], backgroundColor: _blue),
      const LineDataset(
        data: [1, 3, 2],
        backgroundColors: [_blue, _red, _blue],
      ),
      LineDataset(data: const [1, 3, 2], backgroundColorFor: (_) => _blue),
    ]) {
      final canvas = UiCanvasElement(width: 120, height: 80);
      final config = ChartConfig(
        type: .line,
        datasets: [dataset],
        animation: ChartAnimation.none,
      );
      final chart = Chart(canvas, ChartConfigLowering(config).lower());
      expect(
        (chart.getDatasetMeta(0).data.first.options! as PointOptions)
            .backgroundColor,
        _blue,
      );
      _destroy(chart, canvas);
    }
  });

  test('built-in defaults and automatic palette render without CSS', () {
    final canvas = UiCanvasElement(width: 120, height: 80);
    final config = _raw();
    final dataset =
        ((config['data']! as Map)['datasets']! as List).first as Map;
    dataset.remove('backgroundColor');
    final chart = Chart(canvas, config);
    chart.update('none');
    expect(chart.getDatasetMeta(0).data, hasLength(3));
    _destroy(chart, canvas);
  });

  test('hover and animation produce Color, never strings', () {
    expect(helpers.getHoverColor(_blue), const ui.Color(0xFF003CCA));
    expect(() => helpers.getHoverColor('#2050c0'), throwsArgumentError);
    final target = PointOptions({'backgroundColor': _red});
    final animation = core.Animation(
      <String, Object?>{'duration': 1000, 'type': 'color'},
      target,
      'backgroundColor',
      _blue,
    );
    for (final offset in [0, 250, 500, 750, 1000]) {
      animation.tick(animation.start + offset);
      expect(target.backgroundColor, isA<ui.Color>());
    }
    expect(target.backgroundColor, _blue);
  });

  test('color animation groups are configurations, not color values', () {
    final canvas = UiCanvasElement(width: 120, height: 80);
    final config = _raw();
    final options = config['options']! as Map<String, Object?>;
    options['animations'] = <String, Object?>{
      'backgroundColor': <String, Object?>{
        'type': 'color',
        'from': _red,
        'to': _blue,
      },
    };
    final chart = Chart(canvas, config);
    _destroy(chart, canvas);
  });

  test('the numerical constructor never parses CSS strings', () {
    for (final value in ['red', '#fff', 'rgba(1,2,3,0.5)', '']) {
      expect(() => numerical.Color(value), throwsArgumentError);
    }
  });

  test('gradient stops require Color', () {
    final canvas = UiCanvasElement(width: 120, height: 80);
    final context = canvas.getContext2d();
    final gradient = context.createLinearGradient(0, 0, 100, 0);
    gradient.addColorStop(0, _blue);
    gradient.addColorStop(1, _red);
    expect(() => gradient.addColorStop(0.5, 'red'), throwsArgumentError);
    context
      ..fillStyle = gradient
      ..fillRect(0, 0, 100, 50);
    context.dispose();
  });
}
