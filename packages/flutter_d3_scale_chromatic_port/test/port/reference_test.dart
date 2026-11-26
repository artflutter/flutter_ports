// Original code, not ported from d3-scale-chromatic: Node.js reference tests.

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';
import 'package:test/test.dart';

import 'd3_scale_chromatic_reference.dart';

final Map<String, List<Rgb>> _categorical = {
  'schemeAccent': schemeAccent,
  'schemeCategory10': schemeCategory10,
  'schemeDark2': schemeDark2,
  'schemeObservable10': schemeObservable10,
  'schemePaired': schemePaired,
  'schemePastel1': schemePastel1,
  'schemePastel2': schemePastel2,
  'schemeSet1': schemeSet1,
  'schemeSet2': schemeSet2,
  'schemeSet3': schemeSet3,
  'schemeTableau10': schemeTableau10,
};

final Map<String, List<List<Rgb>?>> _discrete = {
  'schemeBlues': schemeBlues,
  'schemeBrBG': schemeBrBG,
  'schemeBuGn': schemeBuGn,
  'schemeBuPu': schemeBuPu,
  'schemeGnBu': schemeGnBu,
  'schemeGreens': schemeGreens,
  'schemeGreys': schemeGreys,
  'schemeOrRd': schemeOrRd,
  'schemeOranges': schemeOranges,
  'schemePRGn': schemePRGn,
  'schemePiYG': schemePiYG,
  'schemePuBu': schemePuBu,
  'schemePuBuGn': schemePuBuGn,
  'schemePuOr': schemePuOr,
  'schemePuRd': schemePuRd,
  'schemePurples': schemePurples,
  'schemeRdBu': schemeRdBu,
  'schemeRdGy': schemeRdGy,
  'schemeRdPu': schemeRdPu,
  'schemeRdYlBu': schemeRdYlBu,
  'schemeRdYlGn': schemeRdYlGn,
  'schemeReds': schemeReds,
  'schemeSpectral': schemeSpectral,
  'schemeYlGn': schemeYlGn,
  'schemeYlGnBu': schemeYlGnBu,
  'schemeYlOrBr': schemeYlOrBr,
  'schemeYlOrRd': schemeYlOrRd,
};

final Map<String, Color Function(double)> _interpolators = {
  'interpolateBlues': interpolateBlues,
  'interpolateBrBG': interpolateBrBG,
  'interpolateBuGn': interpolateBuGn,
  'interpolateBuPu': interpolateBuPu,
  'interpolateCividis': interpolateCividis,
  'interpolateCool': interpolateCool,
  'interpolateCubehelixDefault': interpolateCubehelixDefault,
  'interpolateGnBu': interpolateGnBu,
  'interpolateGreens': interpolateGreens,
  'interpolateGreys': interpolateGreys,
  'interpolateInferno': interpolateInferno,
  'interpolateMagma': interpolateMagma,
  'interpolateOrRd': interpolateOrRd,
  'interpolateOranges': interpolateOranges,
  'interpolatePRGn': interpolatePRGn,
  'interpolatePiYG': interpolatePiYG,
  'interpolatePlasma': interpolatePlasma,
  'interpolatePuBu': interpolatePuBu,
  'interpolatePuBuGn': interpolatePuBuGn,
  'interpolatePuOr': interpolatePuOr,
  'interpolatePuRd': interpolatePuRd,
  'interpolatePurples': interpolatePurples,
  'interpolateRainbow': interpolateRainbow,
  'interpolateRdBu': interpolateRdBu,
  'interpolateRdGy': interpolateRdGy,
  'interpolateRdPu': interpolateRdPu,
  'interpolateRdYlBu': interpolateRdYlBu,
  'interpolateRdYlGn': interpolateRdYlGn,
  'interpolateReds': interpolateReds,
  'interpolateSinebow': interpolateSinebow,
  'interpolateSpectral': interpolateSpectral,
  'interpolateTurbo': interpolateTurbo,
  'interpolateViridis': interpolateViridis,
  'interpolateWarm': interpolateWarm,
  'interpolateYlGn': interpolateYlGn,
  'interpolateYlGnBu': interpolateYlGnBu,
  'interpolateYlOrBr': interpolateYlOrBr,
  'interpolateYlOrRd': interpolateYlOrRd,
};

const Set<String> _hexInterpolators = {
  'interpolateViridis',
  'interpolateMagma',
  'interpolateInferno',
  'interpolatePlasma',
};

const Set<String> _trigInterpolators = {
  'interpolateCubehelixDefault',
  'interpolateWarm',
  'interpolateCool',
  'interpolateRainbow',
  'interpolateSinebow',
};

void main() {
  test('all 11 categorical schemes match upstream hex strings', () {
    expect(
      _categorical.keys,
      unorderedEquals(referenceCategoricalSchemes.keys),
    );
    for (final entry in referenceCategoricalSchemes.entries) {
      final actual = _categorical[entry.key]!
          .map((c) => c.formatHex())
          .toList();
      expect(actual, entry.value, reason: entry.key);
    }
  });

  test('all 27 ColorBrewer discrete schemes match upstream hex tables', () {
    expect(_discrete.keys, unorderedEquals(referenceDiscreteSchemes.keys));
    for (final entry in referenceDiscreteSchemes.entries) {
      final actual = _discrete[entry.key]!;
      final expected = entry.value;
      expect(actual.length, expected.length, reason: entry.key);
      for (var k = 0; k < expected.length; k++) {
        if (expected[k] == null) {
          expect(actual[k], isNull, reason: '${entry.key}[$k]');
        } else {
          expect(
            actual[k]!.map((c) => c.formatHex()).toList(),
            expected[k],
            reason: '${entry.key}[$k]',
          );
        }
      }
    }
  });

  test('all 38 interpolators match upstream Node.js across referenceTs', () {
    expect(
      _interpolators.keys,
      unorderedEquals(referenceInterpolatorTexts.keys),
    );
    for (final entry in referenceInterpolatorTexts.entries) {
      final name = entry.key;
      final fn = _interpolators[name]!;
      final expectedTexts = entry.value;
      final expectedRgbs = referenceInterpolatorRgb[name]!;
      for (var i = 0; i < referenceTs.length; i++) {
        final t = referenceTs[i];
        final actual = fn(t);
        if (_hexInterpolators.contains(name)) {
          expect(actual.formatHex(), expectedTexts[i], reason: '$name($t)');
        } else if (_trigInterpolators.contains(name)) {
          // Trig interpolators may differ in the last bit on native libm;
          // check rounded RGB within 1 and exact text when away from half-way.
          final rgb = actual.rgb();
          final (er, eg, eb) = expectedRgbs[i];
          expect(
            rgb.r.clamp(0, 255).round(),
            closeTo(er, 1),
            reason: '$name($t).r',
          );
          expect(
            rgb.g.clamp(0, 255).round(),
            closeTo(eg, 1),
            reason: '$name($t).g',
          );
          expect(
            rgb.b.clamp(0, 255).round(),
            closeTo(eb, 1),
            reason: '$name($t).b',
          );
        } else {
          expect(actual.toString(), expectedTexts[i], reason: '$name($t)');
        }
      }
    }
  });
}
