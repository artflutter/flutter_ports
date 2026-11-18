// Original code, not ported from D3: tests of the bundle index.
import 'package:flutter_d3_port/d3.dart';
import 'package:test/test.dart';

void main() {
  test('the bundle exports the names of d3-color', () {
    final c = color('steelblue')!;
    expect(c, isA<Rgb>());
    expect(Hcl.from(c).rgb().formatHex(), '#4682b4');
    expect(gray(50).formatHex(), '#777777');
    expect(lch(50, 0, 0).formatHex(), '#777777');
    expect(Cubehelix.parse('white').formatHex(), '#ffffff');
    expect(d3Version, '7.9.0');
  });

  test('the bundle exports the names of d3-interpolate', () {
    expect(interpolate<double>(1, 3)(0.5), 2);
    expect(interpolateNumber(10, 20)(0.25), 12.5);
    expect(interpolateRound(10, 20)(0.26), 13);
    expect(interpolateHue(10, 350)(0.2), 6);
    expect(interpolateBasis([0, 10, 0])(0), 0);
    expect(interpolateBasisClosed([0, 10, 0])(0), closeTo(1.6667, 1e-4));
    expect(interpolateDiscrete(['a', 'b'])(0.5), 'b');
    expect(quantize(interpolateNumber(0, 1), 3), [0, 0.5, 1]);
    expect(piecewise<double>([0, 2, 10])(0.75), 6);
    expect(
      interpolateDate(DateTime.utc(2000), DateTime.utc(2000, 1, 2))(0.5),
      DateTime.utc(2000, 1, 1, 12),
    );
    expect(interpolateArray<double>([0, 10], [10, 20])(0.5), [5, 15]);
    expect(interpolateNumberArray([0.0], [4.0])(0.5), [2]);

    final red = color('red')!;
    final blue = color('blue')!;
    expect(interpolateRgb(red, blue)(0.5).toString(), 'rgb(128, 0, 128)');
    final gamma = interpolateRgb.gamma(2.2);
    expect(gamma, isA<InterpolateRgb>());
    expect(
      gamma(color('purple')!, color('orange')!)(0.5).toString(),
      'rgb(204, 120, 93)',
    );
    expect(interpolateRgbBasis([red, blue])(0).toString(), 'rgb(255, 0, 0)');
    expect(interpolateRgbBasisClosed([red, blue])(0), isA<Rgb>());
    expect(interpolateHsl(red, blue)(0.5), isA<Hsl>());
    expect(interpolateHslLong(red, blue)(0.5), isA<Hsl>());
    expect(interpolateLab(red, blue)(0.5), isA<Lab>());
    expect(interpolateHcl(red, blue)(0.5), isA<Hcl>());
    expect(interpolateHclLong(red, blue)(0.5), isA<Hcl>());
    expect(interpolateCubehelix(red, blue)(0.5), isA<Cubehelix>());
    expect(interpolateCubehelixLong.gamma(3)(red, blue)(0.5), isA<Cubehelix>());

    final zoom = interpolateZoom((0, 0, 1), (0, 0, 2));
    expect(zoom, isA<ZoomInterpolator>());
    final end = zoom(1);
    expect(end, isA<ZoomView>());
    expect(end.$3, closeTo(2, 1e-12));
    expect(interpolateZoom.rho(1), isA<InterpolateZoom>());

    final parts = interpolateTransform(
      decompose(1, 0, 0, 1, 0, 0),
      decompose(1, 0, 0, 1, 48, 0),
    )(0.5);
    expect(parts, isA<TransformParts>());
    expect(parts.translateX, 24);
  });
}
