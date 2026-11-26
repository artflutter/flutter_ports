// Original code, not ported from d3-scale-chromatic: Flutter layer tests.

import 'dart:ui' as ui;

import 'package:flutter_d3_color_port/flutter_d3_color_port.dart';
import 'package:flutter_d3_scale_chromatic_port/flutter_d3_scale_chromatic_port.dart';
import 'package:test/test.dart';

void main() {
  test('toUiColors converts categorical and ColorBrewer schemes', () {
    final uiCat = schemeCategory10.toUiColors();
    expect(uiCat.length, 10);
    expect(uiCat.first, const ui.Color(0xff1f77b4));
    expect(uiCat.last, const ui.Color(0xff17becf));

    final uiBlues = schemeBlues[3]!.toUiColors();
    expect(uiBlues.length, 3);
    expect(uiBlues[0], schemeBlues[3]![0].toUiColor());
    expect(uiBlues[2], schemeBlues[3]![2].toUiColor());
  });

  test('toUiColorInterpolator wraps Rgb and Cubehelix interpolators', () {
    final viridisUi = interpolateViridis.toUiColorInterpolator();
    expect(viridisUi(0), const ui.Color(0xff440154));
    expect(viridisUi(1), const ui.Color(0xfffde725));

    final rainbowUi = interpolateRainbow.toUiColorInterpolator();
    expect(rainbowUi(0.5), interpolateRainbow(0.5).toUiColor());

    final turboUi = interpolateTurbo.toUiColorInterpolator();
    expect(turboUi(0.5), interpolateTurbo(0.5).toUiColor());
  });
}
