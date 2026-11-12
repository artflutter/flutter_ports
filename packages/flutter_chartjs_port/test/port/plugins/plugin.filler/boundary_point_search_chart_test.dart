// Original code, not ported from Chart.js: boundary search chart equivalence.
@TestOn('vm')
library;

import 'dart:ui';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/elements/element.line.dart';
import 'package:flutter_chartjs_port/src/plugins/fill_target.dart'
    show FillBoundary;
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/boundary_point_search.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/filler.target.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/index.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_chartjs_port/src/types/line_option_enums.dart'
    show SteppedLine;
import 'package:flutter_test/flutter_test.dart';

import '../../scales/scale_chart_harness.dart' show drawCalls;

class _ObservedLine extends LineElement {
  _ObservedLine(LineElement original) {
    points = original.points;
    options = original.options;
    loop = original.loop ?? false;
  }

  int calls = 0;

  @override
  Object? interpolate(types.Point point, String property) {
    calls++;
    return super.interpolate(point, property);
  }
}

void main() {
  tearDown(() {
    boundaryPointSearchEnabled = true;
    boundarySegmentSearchEnabled = true;
  });
  testWidgets('a user dataset target keeps its interpolation callbacks', (
    tester,
  ) async {
    final chart = acquireChart({
      'type': 'line',
      'data': {
        'labels': [for (var i = 0; i < 64; i++) '$i'],
        'datasets': [
          {
            'data': [for (var i = 0; i < 64; i++) 0],
            'fill': false,
            'pointRadius': 0,
          },
          {
            'data': [
              for (var i = 0; i < 64; i++)
                if (i % 12 == 5) null else i % 7 - 3,
            ],
            'fill': 0,
            'pointRadius': 0,
            'backgroundColor': const Color(0x88334455),
          },
        ],
      },
      'options': {
        'animation': false,
        'responsive': false,
        'plugins': {'legend': false, 'tooltip': false},
      },
    });
    final meta = chart.getDatasetMeta(0);
    final target = _ObservedLine(meta.dataset! as LineElement);
    meta.dataset = target;
    boundaryPointSearchEnabled = false;
    final original = drawCalls(chart);
    final calls = target.calls;
    expect(calls, greaterThan(0));
    target.calls = 0;
    boundaryPointSearchEnabled = true;
    expect(drawCalls(chart), original);
    expect(target.calls, calls);
  });
  for (final axis in ['x', 'y']) {
    for (final fill in [
      FillBoundary.origin,
      FillBoundary.start,
      FillBoundary.end,
    ]) {
      for (final reverse in [false, true]) {
        testWidgets(
          '$axis $fill reverse=$reverse preserves every draw command',
          (tester) async {
            final chart = acquireChart({
              'type': 'line',
              'data': {
                'labels': [for (var i = 0; i < 64; i++) '$i'],
                'datasets': [
                  for (var k = 0; k < 3; k++)
                    {
                      'data': [
                        for (var i = 0; i < 64; i++)
                          if (i % 12 == 5) null else (i + k) % 7 - 3,
                      ],
                      'fill': {
                        'target': fill,
                        'above': const Color(0x88334455),
                        'below': const Color(0x88778899),
                      },
                      'pointRadius': 0,
                      if (k == 1) 'tension': 0.4,
                      if (k == 2) 'stepped': SteppedLine.middle,
                      'borderColor': const Color(0xff123456),
                    },
                ],
              },
              'options': {
                'indexAxis': axis,
                'animation': false,
                'responsive': false,
                'plugins': {'legend': false, 'tooltip': false},
                'scales': {
                  axis: {'display': false, 'reverse': reverse},
                  axis == 'x' ? 'y' : 'x': {'display': false},
                },
              },
            });
            final source = chart.getDatasetMeta(0).$filler! as FillerSource;
            final target = getTarget(source)! as types.LineElement;
            final search = BoundaryPointSearch.create(target, axis);
            if (!reverse) {
              expect(search, isNotNull);
              expect(search!.find(target.points[2]), same(target.points[2]));
              expect(
                search.bound((
                  property: axis,
                  start: axis == 'x' ? target.points[0].x : target.points[0].y,
                  end: axis == 'x' ? target.points[1].x : target.points[1].y,
                )),
                isNotNull,
              );
            } else {
              expect(search, isNull);
            }
            boundaryPointSearchEnabled = false;
            final original = drawCalls(chart);
            boundaryPointSearchEnabled = true;
            expect(drawCalls(chart), original);
            boundarySegmentSearchEnabled = false;
            expect(drawCalls(chart), original);
            boundarySegmentSearchEnabled = true;
            // The next update builds a fresh boundary with the new scale range.
            final data = chart.data as Map<String, Object?>;
            final datasets = data['datasets']! as List<Object?>;
            final dataset = datasets.first! as Map<String, Object?>;
            (dataset['data']! as List<Object?>)[0] = 20;
            chart.update('none');
            boundaryPointSearchEnabled = false;
            final changed = drawCalls(chart);
            boundaryPointSearchEnabled = true;
            expect(drawCalls(chart), changed);
          },
        );
      }
    }
  }
}
