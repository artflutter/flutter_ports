// Original code, not ported from Chart.js: rounded arc collapse regression.
@TestOn('vm')
library;

import 'dart:ui';

import 'package:flutter_chartjs_port/src/elements/element.arc.dart';
import 'package:flutter_chartjs_port/src/elements/element_options.dart';
import 'package:flutter_chartjs_port/src/types/arc_option_enums.dart';
import 'package:flutter_test/flutter_test.dart';

import '../canvas/pixel_compare.dart';

void main() {
  test(
    'a rounded slice keeps its center clear across collapsed-arc frames',
    () async {
      // Pink slice of the 1k stress scene, ring 11 at t=100/60, radius 31.
      // The old inner end exceeded its start by 5.6e-17 radians and wrapped.
      const start = -0.524968019741612;
      const end = -0.025128536999438678;
      for (final delta in [-1e-14, 0.0, 1e-14]) {
        final arc = ArcElement()
          ..x = 50
          ..y = 50
          ..innerRadius = 15.5
          ..outerRadius = 23.25
          ..startAngle = start
          ..endAngle = end + delta
          ..circumference = end + delta - start
          ..options = ArcOptions({
            'backgroundColor': const Color.fromRGBO(255, 99, 132, 0.5),
            'borderColor': const Color(0xffffffff),
            'borderWidth': 2.0,
            'borderAlign': ArcBorderAlign.center,
            'borderRadius': 4.0,
            'offset': 0.0,
            'spacing': 2.0,
            'circular': true,
            'selfJoin': false,
            'spacingMode': ArcSpacingMode.angular,
          });
        final image = await renderContext(arc.draw, width: 100, height: 100);
        expect(
          image.ink,
          greaterThan(0),
          reason: 'the slice must still render',
        );
        for (var y = 43; y <= 57; y++) {
          for (var x = 43; x <= 57; x++) {
            expect(
              image.alpha(x, y),
              0,
              reason: 'hole at ($x,$y), delta $delta',
            );
          }
        }
      }
    },
  );
}
