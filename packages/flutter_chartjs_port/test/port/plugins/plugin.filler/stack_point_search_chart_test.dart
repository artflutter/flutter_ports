// Original code, not ported from Chart.js: stack-search drawing equivalence.
@TestOn('vm')
library;

import 'dart:ui';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/elements/element.line.dart';
import 'package:flutter_chartjs_port/src/plugins/fill_target.dart'
    show FillBoundary;
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/stack_point_search.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart'
    show ChartPaint;
import 'package:flutter_test/flutter_test.dart';

import '../../scales/scale_chart_harness.dart' show drawCalls;

void main() {
  tearDown(() => stackPointSearchEnabled = true);
  testWidgets('a real aligned stack takes the shortcut and keeps draw calls', (
    tester,
  ) async {
    final chart = acquireChart({
      'type': 'line',
      'data': {
        'labels': [for (var i = 0; i < 64; i++) '$i'],
        'datasets': [
          for (var k = 0; k < 3; k++)
            {
              'data': [for (var i = 0; i < 64; i++) 1 + (i + k) % 7],
              'fill': FillBoundary.stack,
              'pointRadius': 0,
              'backgroundColor': ChartPaint.solid(
                Color.fromARGB(100, 30 + 60 * k, 80, 160),
              ),
              'borderColor': const ChartPaint.solid(Color(0xff123456)),
            },
        ],
      },
      'options': {
        'animation': false,
        'responsive': false,
        'plugins': {'legend': false, 'tooltip': false},
        'scales': {
          'x': {'display': false},
          'y': {'display': false, 'stacked': true},
        },
      },
    });
    final source = chart.getDatasetMeta(2).dataset! as LineElement;
    final target = chart.getDatasetMeta(1).dataset! as LineElement;
    final search = StackPointSearch.create(
      source,
      source.points,
      source.segments,
      1,
    )!;
    expect(
      search.find(0, target, source.points[20])!.point,
      same(target.points[20]),
    );
    stackPointSearchEnabled = false;
    final original = drawCalls(chart);
    stackPointSearchEnabled = true;
    expect(drawCalls(chart), original);
  });
}
