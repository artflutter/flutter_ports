// Ported from d3-hierarchy v3.1.2 test/pack/siblings-test.js (ISC, Mike Bostock).

import 'dart:math' as math;

import 'package:flutter_d3_hierarchy_port/d3_hierarchy.dart';
import 'package:test/test.dart';

void _swap<T>(List<T> array, int i, int j) {
  final t = array[i];
  array[i] = array[j];
  array[j] = t;
}

void _permute<T>(List<T> array, void Function(List<T>) f, [int? n]) {
  final len = n ?? array.length;
  if (len == 1) {
    f(array);
    return;
  }
  for (var i = 0; i < len - 1; ++i) {
    _permute(array, f, len - 1);
    _swap(array, (len & 1) != 0 ? 0 : i, len - 1);
  }
  _permute(array, f, len - 1);
}

PackCircle _circleValue(double value) => PackCircle(r: math.sqrt(value));

PackCircle _circleRadius(double radius) => PackCircle(r: radius);

bool _intersectsAny(List<PackCircle> circles) {
  for (var i = 0, n = circles.length; i < n; ++i) {
    final ci = circles[i];
    for (var j = i + 1; j < n; ++j) {
      if (_intersects(ci, circles[j])) {
        return true;
      }
    }
  }
  return false;
}

bool _intersects(PackCircle a, PackCircle b) {
  final dr = a.r + b.r - 1e-6;
  final dx = b.x - a.x;
  final dy = b.y - a.y;
  return dr > 0 && dr * dr > dx * dx + dy * dy;
}

void main() {
  test(
    'packSiblings(circles) produces a non-overlapping layout of circles',
    () {
      _permute(
        [100.0, 200.0, 500.0, 70.0, 3.0].map(_circleValue).toList(),
        (p) => expect(_intersectsAny(packSiblings(p)), isFalse),
      );
      _permute(
        [3.0, 30.0, 50.0, 400.0, 600.0].map(_circleValue).toList(),
        (p) => expect(_intersectsAny(packSiblings(p)), isFalse),
      );
      _permute(
        [1.0, 1.0, 3.0, 30.0, 50.0, 400.0, 600.0].map(_circleValue).toList(),
        (p) => expect(_intersectsAny(packSiblings(p)), isFalse),
      );
      expect(
        _intersectsAny(
          packSiblings(
            [
              0.24155803737254639,
              0.06349736576607135,
              0.4721808601742349,
              0.7469141449305542,
              1.6399276349079663,
            ].map(_circleRadius).toList(),
          ),
        ),
        isFalse,
      );
      expect(
        _intersectsAny(
          packSiblings(
            [
              2.0,
              9071.0,
              79.0,
              51.0,
              325.0,
              867.0,
              546.0,
              19773.0,
              371.0,
              16.0,
              165781.0,
              10474.0,
              6928.0,
              40201.0,
              31062.0,
              14213.0,
              8626.0,
              12.0,
              299.0,
              1075.0,
              98918.0,
              4738.0,
              664.0,
              2694.0,
              2619.0,
              51237.0,
              21431.0,
              99.0,
              5920.0,
              1117.0,
              321.0,
              519162.0,
              33559.0,
              234.0,
              4207.0,
            ].map(_circleValue).toList(),
          ),
        ),
        isFalse,
      );
      expect(
        _intersectsAny(
          packSiblings(
            [
              0.3371386860049076,
              58.65337373332081,
              2.118883785686244,
              1.7024669121097333,
              5.834919697833051,
              8.949453403094978,
              6.792586534702093,
              105.30490014617664,
              6.058936212213754,
              0.9535722042975694,
              313.7636051642043,
            ].map(_circleRadius).toList(),
          ),
        ),
        isFalse,
      );
      expect(
        _intersectsAny(
          packSiblings(
            [
              6.26551789195159,
              1.707773433636342,
              9.43220282933871,
              9.298909705475646,
              5.753163715613753,
              8.882383159012575,
              0.5819319661882536,
              2.0234859171687747,
              2.096171518434433,
              9.762727931304937,
            ].map(_circleRadius).toList(),
          ),
        ),
        isFalse,
      );
      expect(
        _intersectsAny(
          packSiblings(
            [
              9.153035316963035,
              9.86048622524424,
              8.3974499571329,
              7.8338007571397865,
              8.78260490259886,
              6.165829618300345,
              7.134819943097564,
              7.803701771392344,
              5.056638985134191,
              7.424601077645588,
              8.538658023474753,
              2.4616388562274896,
              0.5444633747829343,
              9.005740508584667,
            ].map(_circleRadius).toList(),
          ),
        ),
        isFalse,
      );
      expect(
        _intersectsAny(
          packSiblings(
            [
              2.23606797749979,
              52.07088264296293,
              5.196152422706632,
              20.09975124224178,
              357.11557267679996,
              4.898979485566356,
              14.7648230602334,
              17.334875731491763,
            ].map(_circleRadius).toList(),
          ),
        ),
        isFalse,
      );
    },
  );

  test(
    'packSiblings(circles) can successfully pack a circle with a tiny radius',
    () {
      expect(
        _intersectsAny(
          packSiblings(
            [
              0.5672035864083508,
              0.6363498687452267,
              0.5628456216244132,
              1.5619458670239148,
              1.5658933259424268,
              0.9195955097595698,
              0.4747083763630309,
              0.38341282734497434,
              1.3475593361729394,
              0.7492342961633259,
              1.0716990115071823,
              0.31686823341701664,
              2.8766442376551415e-7,
            ].map(_circleRadius).toList(),
          ),
        ),
        isFalse,
      );
    },
  );

  test('packSiblings accepts large circles', () {
    final c1 = packSiblings([
      PackCircle(r: 100000000000),
      PackCircle(r: 1),
      PackCircle(r: 1),
    ]);
    expect(
      [
        (c1[0].x, c1[0].y, c1[0].r),
        (c1[1].x, c1[1].y, c1[1].r),
        (c1[2].x, c1[2].y, c1[2].r),
      ],
      [(0.0, 0.0, 1e11), (1e11 + 1, 0.0, 1.0), (1e11 + 1, 2.0, 1.0)],
    );
    final c2 = packSiblings([
      PackCircle(r: 10000000000000000),
      PackCircle(r: 1),
      PackCircle(r: 1),
    ]);
    expect(
      [
        (c2[0].x, c2[0].y, c2[0].r),
        (c2[1].x, c2[1].y, c2[1].r),
        (c2[2].x, c2[2].y, c2[2].r),
      ],
      [(0.0, 0.0, 1e16), (1e16 + 1, 0.0, 1.0), (1e16 + 1, 2.0, 1.0)],
    );
  });
}
