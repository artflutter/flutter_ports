// Original code, not ported from d3-array: Node.js reference parity tests.

import 'dart:typed_data';

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

import 'd3_array_reference.dart';

void _expectCloseList(List<double> actual, List<double> expected, double tol) {
  expect(actual.length, expected.length);
  for (var i = 0; i < expected.length; ++i) {
    final e = expected[i];
    final a = actual[i];
    if (e.isNaN) {
      expect(a.isNaN, isTrue, reason: 'index $i expected NaN, got $a');
    } else if (tol == 0) {
      expect(a, e, reason: 'index $i');
    } else {
      expect(a, closeTo(e, tol), reason: 'index $i');
    }
  }
}

void main() {
  test('statistics match Node.js upstream d3-array v3.2.4', () {
    expect(count(refSampleA), refCountA);
    expect(count(refSampleB), refCountB);
    expect(sum(refSampleA), closeTo(refSumA, 1e-12));
    expect(sum(refSampleB), closeTo(refSumB, 1e-9));
    expect(fsum(refSampleA), refFsumA);
    expect(fsum(refFsumStress), refFsumStressResult);
    expect(mean(refSampleA), closeTo(refMeanA, 1e-12));
    expect(mean(refSampleB), closeTo(refMeanB, 1e-9));
    expect(variance(refSampleA), closeTo(refVarianceA, 1e-10));
    expect(variance(refSampleB), closeTo(refVarianceB, 1e-4));
    expect(deviation(refSampleA), closeTo(refDeviationA, 1e-12));
    expect(deviation(refSampleB), closeTo(refDeviationB, 1e-9));
    expect(min(refSampleA), refMinA);
    expect(max(refSampleA), refMaxA);
    expect(minIndex(refSampleB), refMinIndexB);
    expect(maxIndex(refSampleB), refMaxIndexB);
    expect(median(refSampleA), refMedianA);
    expect(medianIndex(refSampleA), refMedianIndexA);
    expect(medianIndex(refSampleB), refMedianIndexB);
  });

  test('quantiles, cumsum, fcumsum, and rank match Node.js', () {
    for (var i = 0; i < refQuantilePs.length; ++i) {
      final p = refQuantilePs[i];
      expect(quantile(refSampleA, p), closeTo(refQuantilesA[i], 1e-12));
      expect(quantile(refSampleB, p), closeTo(refQuantilesB[i], 1e-9));
      expect(quantileIndex(refSampleA, p), refQuantileIndicesA[i]);
    }
    _expectCloseList(cumsum(refSampleA), refCumsumA, 1e-12);
    _expectCloseList(fcumsum(refFsumStress), refFcumsumStress, 0);
    _expectCloseList(rank(refSampleB), refRankB, 0);
  });

  test('ticks, tickIncrement, tickStep, and nice match Node.js', () {
    for (var i = 0; i < refTickCases.length; ++i) {
      final (a, b, c) = refTickCases[i];
      _expectCloseList(ticks(a, b, c), refTicksExpected[i], 1e-12);
      final inc = tickIncrement(a, b, c);
      final expInc = refTickIncrementExpected[i];
      if (expInc.isNaN) {
        expect(inc.isNaN, isTrue, reason: 'tickIncrement($a, $b, $c)');
      } else {
        expect(inc, expInc, reason: 'tickIncrement($a, $b, $c)');
      }
      final st = tickStep(a, b, c);
      final expSt = refTickStepExpected[i];
      if (expSt.isNaN) {
        expect(st.isNaN, isTrue, reason: 'tickStep($a, $b, $c)');
      } else {
        expect(st, expSt, reason: 'tickStep($a, $b, $c)');
      }
      final niced = nice(a, b, c);
      expect(niced.$1, closeTo(refNiceExpected[i].$1, 1e-12));
      expect(niced.$2, closeTo(refNiceExpected[i].$2, 1e-12));
    }
  });

  test('thresholds and bin match Node.js', () {
    final lo = min(refSampleA)!;
    final hi = max(refSampleA)!;
    expect(thresholdSturges(refSampleA), refSturgesA);
    expect(thresholdScott(refSampleA, lo, hi), refScottA);
    expect(thresholdFreedmanDiaconis(refSampleA, lo, hi), refFreedmanDiaconisA);

    final bDefault = bin<double>()(refSampleA);
    expect(bDefault.length, refBinDefaultA.length);
    for (var i = 0; i < bDefault.length; ++i) {
      expect(bDefault[i].x0, closeTo(refBinDefaultA[i].$1, 1e-12));
      expect(bDefault[i].x1, closeTo(refBinDefaultA[i].$2, 1e-12));
      expect(bDefault[i].length, refBinDefaultA[i].$3);
    }

    final bScott = bin<double>(thresholdsCount: thresholdScott)(refSampleA);
    expect(bScott.length, refBinScottA.length);
    for (var i = 0; i < bScott.length; ++i) {
      expect(bScott[i].x0, closeTo(refBinScottA[i].$1, 1e-12));
      expect(bScott[i].x1, closeTo(refBinScottA[i].$2, 1e-12));
      expect(bScott[i].length, refBinScottA[i].$3);
    }

    final bFD = bin<double>(thresholdsCount: thresholdFreedmanDiaconis)(
      refSampleA,
    );
    expect(bFD.length, refBinFDA.length);
    for (var i = 0; i < bFD.length; ++i) {
      expect(bFD[i].x0, closeTo(refBinFDA[i].$1, 1e-12));
      expect(bFD[i].x1, closeTo(refBinFDA[i].$2, 1e-12));
      expect(bFD[i].length, refBinFDA[i].$3);
    }
  });

  test('blur, blur2, and blurImage match Node.js', () {
    for (var i = 0; i < refBlur1Radii.length; ++i) {
      final copy = List<double>.of(refBlur1Input);
      blur(copy, refBlur1Radii[i]);
      _expectCloseList(copy, refBlur1Expected[i], 1e-12);
    }

    const radii2 = <(double, double)>[(1, 1), (1.5, 0.5), (2, 0), (0, 2)];
    for (var i = 0; i < radii2.length; ++i) {
      final grid = Blur2Data(data: List<double>.of(refBlur2Input), width: 9);
      blur2(grid, radii2[i].$1, radii2[i].$2);
      _expectCloseList(grid.data, refBlur2Expected[i], 1e-12);
    }

    final img = BlurImageData(
      data: Uint8ClampedList.fromList(refBlurImageInput),
      width: 6,
      height: 5,
    );
    blurImage(img, 1.5, 1);
    expect(img.data, refBlurImageExpected);
  });
}
