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

  test('the bundle exports the names of d3-scale-chromatic', () {
    expect(schemeCategory10, hasLength(10));
    expect(schemeCategory10.first.formatHex(), '#1f77b4');
    expect(schemeTableau10, hasLength(10));
    expect(schemeBrBG[5], hasLength(5));
    expect(schemeBlues[9], hasLength(9));
    expect(interpolateBrBG(0.5), isA<Rgb>());
    expect(interpolateBlues(0.5), isA<Rgb>());
    expect(interpolateViridis(0).formatHex(), '#440154');
    expect(interpolateViridis(1).formatHex(), '#fde725');
    expect(interpolateMagma(0.5), isA<Rgb>());
    expect(interpolateInferno(0.5), isA<Rgb>());
    expect(interpolatePlasma(0.5), isA<Rgb>());
    expect(interpolateCividis(0.5), isA<Rgb>());
    expect(interpolateTurbo(0.5), isA<Rgb>());
    expect(interpolateSinebow(0.5), isA<Rgb>());
    expect(interpolateRainbow(0.5), isA<Cubehelix>());
    expect(interpolateWarm(0.5), isA<Cubehelix>());
    expect(interpolateCool(0.5), isA<Cubehelix>());
    expect(interpolateCubehelixDefault(0.5), isA<Cubehelix>());
    expect(d3ScaleChromaticVersion, '3.1.0');
  });

  test('the bundle exports the names of d3-path', () {
    final p = path()
      ..moveTo(0, 0)
      ..lineTo(10, 20)
      ..closePath();
    expect(p, isA<Path>());
    expect(p, isA<CanvasPath>());
    expect('$p', 'M0,0L10,20Z');
    final r = pathRound(2)..moveTo(1.2345, 6.7891);
    expect('$r', 'M1.23,6.79');
    expect(d3PathVersion, '3.1.0');
  });

  test('the bundle exports the names of d3-shape', () {
    final l = line<(double, double)>()
      ..x = ((d, _, _) => d.$1)
      ..y = ((d, _, _) => d.$2)
      ..curve = curveMonotoneX;
    expect(l([(0, 0), (10, 20), (20, 10)]), startsWith('M0,0C'));
    final slices = pie<double>()([1, 2, 3]);
    expect(slices, hasLength(3));
    final a = arc<PieArc<double>>()
      ..innerRadiusConst(20)
      ..outerRadiusConst(50);
    expect(a(slices.first), startsWith('M'));
    expect(symbol<Object?>(symbolStar, 64)(), startsWith('M'));
    expect(symbolsFill, hasLength(7));
    expect(symbolsStroke, hasLength(7));
    final stacked =
        (stack<Map<String, double>, String>()
          ..keysConst(['a', 'b'])
          ..offset = stackOffsetWiggle
          ..order = stackOrderInsideOut)([
          {'a': 10, 'b': 20},
          {'a': 15, 'b': 25},
        ]);
    expect(stacked, hasLength(2));
    expect(d3ShapeVersion, '3.2.0');
  });

  test('the bundle exports the names of d3-format', () {
    expect(format('.3s')(145500000), '146M');
    expect(format(r'+$,.2f')(-1234.56), r'−$1,234.56');
    expect(formatPrefix(',.1', 1e6)(4.2e6), '4.2M');
    expect(formatSpecifier('08d').width, 8);
    expect(
      formatLocale(localeFrFR).format(r'$,.2f')(1234.56),
      '1\u00a0234,56\u00a0€',
    );
    expect(formatLocales, hasLength(59));
    expect(precisionFixed(0.05), 2);
    expect(precisionPrefix(1e-9, 1e-6), 3);
    expect(precisionRound(0.01, 1.01), 3);
    expect(d3FormatVersion, '3.1.2');
  });

  test('the bundle exports the names of d3-array', () {
    expect(sum([1, 2, 3, 4]), 10);
    expect(fsum([1, 1e16, 1, -1e16]), 2);
    expect(extent([3, 1, 4, 1, 5]), (1, 5));
    expect(mean([2, 4, 6]), 4);
    expect(median([1, 2, 3, 4]), 2.5);
    expect(deviation([1, 2, 3]), 1);
    expect(ticks(0, 10, 5), [0, 2, 4, 6, 8, 10]);
    expect(nice(0.123, 0.987, 5), (0.0, 1.0));
    expect(range(5), [0, 1, 2, 3, 4]);
    expect(bisectLeft([1, 2, 2, 3], 2), 1);
    expect(bisectRight([1, 2, 2, 3], 2), 3);
    expect(bin<double>()([0, 1, 2, 10]), isNotEmpty);
    expect(d3ArrayVersion, '3.2.4');
  });
}
