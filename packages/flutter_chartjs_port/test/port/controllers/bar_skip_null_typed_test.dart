// Original code, not ported from Chart.js: the skipNull index, typed config.
@TestOn('vm')
library;

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart' show TextStyle, ValueKey;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_chartjs_port/src/core/bar_skip_null.dart';
import 'package:flutter_chartjs_port/src/typed/lower.dart'
    show ChartConfigLowering;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

/// The bar config of the bench window `skipnull`: three typed datasets with
/// `skipNull` through `extra`, one null value in ten at other places, the
/// scales hidden or shown.
ChartConfig _config(int count, {required bool shown}) {
  final grid = AxisGrid(
    display: shown,
    color: const ChartPaint.solid(ui.Color(0xffe5e9f1)),
    drawTicks: false,
  );
  final ticks = AxisTicks(
    display: shown,
    stepSize: 25,
    font: const TextStyle(fontSize: 10),
    maxRotation: 0,
    autoSkip: true,
    extra: const {'maxTicksLimit': 5},
  );
  return ChartConfig(
    type: ChartKind.bar,
    animation: ChartAnimation.none,
    datasets: [
      for (var k = 0; k < 3; k++)
        BarDataset(
          key: ValueKey('series$k'),
          label: 'Values ${k + 1}',
          data: [
            for (var i = 0; i < count; i++)
              if ((i + k * 3) % 10 == 0) null else 12.0 + (i * 7 + k) % 70,
          ],
          backgroundColor: const ChartValue.constant(
            ChartPaint.solid(ui.Color(0xff4f6bed)),
          ),
          borderWidth: 0,
          barPercentage: .8,
          categoryPercentage: 1,
          extra: const {'skipNull': true},
        ),
    ],
    labels: [for (var i = 0; i < count; i++) 'c$i'],
    scales: {
      'x': CategoryAxis(display: shown, grid: grid, ticks: ticks),
      'y': LinearAxis(
        min: 0,
        max: 100,
        display: shown,
        grid: grid,
        ticks: ticks,
      ),
    },
  );
}

Object? _plain(Object? value) =>
    value is double && !value.isFinite ? value.toString() : value;

Object _observe(types.ChartMeta meta) => [
  for (final e in meta.data)
    [
      for (final key in ['x', 'y', 'base', 'width', 'height'])
        _plain((e as types.ElementPropertyRead)[key]),
    ],
];

void main() {
  for (final shown in [false, true]) {
    test('a typed config takes the index, scales shown $shown', () {
      final chart = Chart(
        UiCanvasElement(width: 800, height: 480),
        ChartConfigLowering(_config(200, shown: shown)).lower(),
      );
      addTearDown(chart.destroy);
      for (var d = 0; d < 3; d++) {
        final meta = chart.getDatasetMeta(d);
        final controller = meta.controller! as BarController;
        var before = BarSkipNullIndex.debugVisits;
        // No `update` call: no index.
        controller.updateElements(meta.data, 0, meta.data.length, 'none');
        final search = BarSkipNullIndex.debugVisits - before;
        final expected = _observe(meta);
        before = BarSkipNullIndex.debugVisits;
        controller.update('none');
        final fast = BarSkipNullIndex.debugVisits - before;
        expect(_observe(meta), expected);
        // 3 proofs of 200 items, and 2 x 3 reads for each bar.
        expect(fast, lessThanOrEqualTo(3 * 200 + 200 * 2 * 3));
        expect(search, greaterThan(fast * 10));
      }
    });
  }
}
