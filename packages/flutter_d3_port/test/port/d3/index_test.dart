// Original code, not ported from D3: tests of the bundle index.
import 'package:flutter_d3_port/d3.dart' as d3;
import 'package:test/test.dart';

void main() {
  test('the bundle exports the names of d3-color', () {
    final c = d3.color('steelblue')!;
    expect(c, isA<d3.Rgb>());
    expect(d3.Hcl.from(c).rgb().formatHex(), '#4682b4');
    expect(d3.gray(50).formatHex(), '#777777');
    expect(d3.lch(50, 0, 0).formatHex(), '#777777');
    expect(d3.Cubehelix.parse('white').formatHex(), '#ffffff');
    expect(d3.d3Version, '7.9.0');
  });

  test('the bundle exports the names of d3-interpolate', () {
    expect(d3.interpolate<double>(1, 3)(0.5), 2);
    expect(d3.interpolateNumber(10, 20)(0.25), 12.5);
    expect(d3.interpolateRound(10, 20)(0.26), 13);
    expect(d3.interpolateHue(10, 350)(0.2), 6);
    expect(d3.interpolateBasis([0, 10, 0])(0), 0);
    expect(d3.interpolateBasisClosed([0, 10, 0])(0), closeTo(1.6667, 1e-4));
    expect(d3.interpolateDiscrete(['a', 'b'])(0.5), 'b');
    expect(d3.quantize(d3.interpolateNumber(0, 1), 3), [0, 0.5, 1]);
    expect(d3.piecewise<double>([0, 2, 10])(0.75), 6);
    expect(
      d3.interpolateDate(DateTime.utc(2000), DateTime.utc(2000, 1, 2))(0.5),
      DateTime.utc(2000, 1, 1, 12),
    );
    expect(d3.interpolateArray<double>([0, 10], [10, 20])(0.5), [5, 15]);
    expect(d3.interpolateNumberArray([0.0], [4.0])(0.5), [2]);

    final red = d3.color('red')!;
    final blue = d3.color('blue')!;
    expect(d3.interpolateRgb(red, blue)(0.5).toString(), 'rgb(128, 0, 128)');
    final gamma = d3.interpolateRgb.gamma(2.2);
    expect(gamma, isA<d3.InterpolateRgb>());
    expect(
      gamma(d3.color('purple')!, d3.color('orange')!)(0.5).toString(),
      'rgb(204, 120, 93)',
    );
    expect(d3.interpolateRgbBasis([red, blue])(0).toString(), 'rgb(255, 0, 0)');
    expect(d3.interpolateRgbBasisClosed([red, blue])(0), isA<d3.Rgb>());
    expect(d3.interpolateHsl(red, blue)(0.5), isA<d3.Hsl>());
    expect(d3.interpolateHslLong(red, blue)(0.5), isA<d3.Hsl>());
    expect(d3.interpolateLab(red, blue)(0.5), isA<d3.Lab>());
    expect(d3.interpolateHcl(red, blue)(0.5), isA<d3.Hcl>());
    expect(d3.interpolateHclLong(red, blue)(0.5), isA<d3.Hcl>());
    expect(d3.interpolateCubehelix(red, blue)(0.5), isA<d3.Cubehelix>());
    expect(
      d3.interpolateCubehelixLong.gamma(3)(red, blue)(0.5),
      isA<d3.Cubehelix>(),
    );

    final zoom = d3.interpolateZoom((0, 0, 1), (0, 0, 2));
    expect(zoom, isA<d3.ZoomInterpolator>());
    final end = zoom(1);
    expect(end, isA<d3.ZoomView>());
    expect(end.$3, closeTo(2, 1e-12));
    expect(d3.interpolateZoom.rho(1), isA<d3.InterpolateZoom>());

    final parts = d3.interpolateTransform(
      d3.decompose(1, 0, 0, 1, 0, 0),
      d3.decompose(1, 0, 0, 1, 48, 0),
    )(0.5);
    expect(parts, isA<d3.TransformParts>());
    expect(parts.translateX, 24);
  });
}
