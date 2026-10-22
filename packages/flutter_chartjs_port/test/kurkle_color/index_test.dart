// Ported from @kurkle/color v0.3.2 test/index.js (MIT, Jukka Kurkela).
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/kurkle_color/index.esm.dart'
    show Color, RGBA;
import 'package:test/test.dart';

// Upstream runs the asserts of one script with node:assert, on the build of
// src/index.esm.js. Here each assert is one test. Its name is the actual
// expression and the upstream line. `assert.strictEqual(x, undefined)`
// becomes `isNull`, because Dart null stands for the JS undefined results.

/// SameValue (`Object.is`) of a member, as `assert.deepStrictEqual` compares
/// primitives: NaN equals NaN, and 0 differs from -0.
Matcher _sameValue(double expected) => predicate<double>(
  (actual) => actual.isNaN
      ? expected.isNaN
      : actual == expected && actual.isNegative == expected.isNegative,
  'SameValue ${jsNumberToString(expected)}',
);

/// `assert.deepStrictEqual(actual, {r, g, b, a})` for an [RGBA].
Matcher _rgba(double r, double g, double b, double a) => isA<RGBA>()
    .having((v) => v.r, 'r', _sameValue(r))
    .having((v) => v.g, 'g', _sameValue(g))
    .having((v) => v.b, 'b', _sameValue(b))
    .having((v) => v.a, 'a', _sameValue(a));

void main() {
  test("new Color('#fef').rgb (:4)", () {
    expect(Color('#fef').rgb, _rgba(255, 238, 255, 1));
  });
  test("new Color('#fffFEF').rgb (:5)", () {
    expect(Color('#fffFEF').rgb, _rgba(255, 255, 239, 1));
  });
  test("new Color('#feg').rgb (:6)", () {
    expect(Color('#feg').rgb, _rgba(255, 238, 0, 1));
  });
  test("new Color('rgb(244, 233, 100)').rgb (:7)", () {
    expect(Color('rgb(244, 233, 100)').rgb, _rgba(244, 233, 100, 1));
  });
  test("new Color('rgb(100%, 30%, 90%)').rgb (:8)", () {
    expect(Color('rgb(100%, 30%, 90%)').rgb, _rgba(255, 77, 229, 1));
  });
  test("new Color('rgb(255, 0, 0)').rgb (:9)", () {
    expect(Color('rgb(255, 0, 0)').rgb, _rgba(255, 0, 0, 1));
  });
  test("new Color('hsl(240, 100%, 50.5%)').rgb (:10)", () {
    expect(Color('hsl(240, 100%, 50.5%)').rgb, _rgba(3, 3, 255, 1));
  });
  test("new Color('hsl(240deg, 100%, 50.5%)').rgb (:11)", () {
    expect(Color('hsl(240deg, 100%, 50.5%)').rgb, _rgba(3, 3, 255, 1));
  });
  test("new Color('hwb(240, 100%, 50.5%)').rgb (:12)", () {
    expect(Color('hwb(240, 100%, 50.5%)').rgb, _rgba(169, 169, 169, 1));
  });
  test("new Color('hsl(0deg 100% 50%)').rgb (:13)", () {
    expect(Color('hsl(0deg 100% 50%)').rgb, _rgba(255, 0, 0, 1));
  });
  test("new Color('moccasin').rgb (:14)", () {
    expect(Color('moccasin').rgb, _rgba(255, 228, 181, 1));
  });
  test("new Color('rgb(0 255 0)').rgb (:15)", () {
    expect(Color('rgb(0 255 0)').rgb, _rgba(0, 255, 0, 1));
  });
  test("new Color('rgb(0 0 100% / 80%)').rgb (:16)", () {
    expect(Color('rgb(0 0 100% / 80%)').rgb, _rgba(0, 0, 255, 0.8));
  });
  test("new Color('hsv(240, 100%, 50.5%)').rgb (:17)", () {
    expect(Color('hsv(240, 100%, 50.5%)').rgb, _rgba(0, 0, 129, 1));
  });
  test("new Color('hsv(244, 100%, 100%, 0.6)').rgb (:18)", () {
    expect(Color('hsv(244, 100%, 100%, 0.6)').rgb, _rgba(17, 0, 255, 0.6));
  });
  test('new Color({r: 255, g: 254, b: 253}).rgb (:19)', () {
    expect(
      Color(<String, Object?>{'r': 255, 'g': 254, 'b': 253}).rgb,
      _rgba(255, 254, 253, 1),
    );
  });
  test('new Color({r: 255, g: 254, b: 253, a: 0.3}).rgb (:20)', () {
    expect(
      Color(<String, Object?>{'r': 255, 'g': 254, 'b': 253, 'a': 0.3}).rgb,
      _rgba(255, 254, 253, 0.3),
    );
  });
  test('new Color([255, 254, 253]).rgb (:21)', () {
    expect(Color(<Object?>[255, 254, 253]).rgb, _rgba(255, 254, 253, 1));
  });
  test('new Color([255, 254, 253, 0.5]).rgb (:22)', () {
    expect(Color(<Object?>[255, 254, 253, 0.5]).rgb, _rgba(255, 254, 253, 0.5));
  });
  test("new Color('#feff').rgb (:24)", () {
    expect(Color('#feff').rgb, _rgba(255, 238, 255, 1));
  });
  test("new Color('#fef0').rgb (:25)", () {
    expect(Color('#fef0').rgb, _rgba(255, 238, 255, 0));
  });
  test("new Color('#fefa').rgbString() (:26)", () {
    expect(Color('#fefa').rgbString(), 'rgba(255, 238, 255, 0.67)');
  });
  test("new Color('#c814e933').rgb (:27)", () {
    expect(Color('#c814e933').rgb, _rgba(200, 20, 233, 0.2));
  });
  test("new Color('#c814e900').rgb (:28)", () {
    expect(Color('#c814e900').rgb, _rgba(200, 20, 233, 0));
  });
  test("new Color('#c814e9ff').rgb (:29)", () {
    expect(Color('#c814e9ff').rgb, _rgba(200, 20, 233, 1));
  });
  test("new Color('rgba(200, 20, 233, 0.2)').rgb (:30)", () {
    expect(Color('rgba(200, 20, 233, 0.2)').rgb, _rgba(200, 20, 233, 0.2));
  });
  test("new Color('rgba(200, 20, 233, 0)').rgb (:31)", () {
    expect(Color('rgba(200, 20, 233, 0)').rgb, _rgba(200, 20, 233, 0));
  });
  test("new Color('rgba(200, 20, 233, 1e-15)').rgb (:32)", () {
    expect(Color('rgba(200, 20, 233, 1e-15)').rgb, _rgba(200, 20, 233, 0));
  });
  test("new Color('rgba(100%, 30%, 90%, 0.2)').rgb (:33)", () {
    expect(Color('rgba(100%, 30%, 90%, 0.2)').rgb, _rgba(255, 77, 229, 0.2));
  });
  test("new Color('rgba(255, 0, 0, .5)').rgb (:34)", () {
    expect(Color('rgba(255, 0, 0, .5)').rgb, _rgba(255, 0, 0, 0.5));
  });
  test("new Color('hsla(12, 10%, 50%, .3)').rgb (:35)", () {
    expect(Color('hsla(12, 10%, 50%, .3)').rgb, _rgba(140, 120, 115, 0.3));
  });
  test("new Color('hsla(12, 10%, 50%, 30%)').rgb (:36)", () {
    expect(Color('hsla(12, 10%, 50%, 30%)').rgb, _rgba(140, 120, 115, 0.3));
  });
  test("new Color('hwb(244, 100%, 100%, 0.6)').rgb (:37)", () {
    expect(Color('hwb(244, 100%, 100%, 0.6)').rgb, _rgba(128, 128, 128, 0.6));
  });
  test(
    "new Color('hsla(240.0384227364303,...,0.3)').rgb (:38)",
    () {
      expect(
        Color(
          'hsla(240.0384227364303,4.12843378950259%,48.71943371204973%,0.3)',
        ).rgb,
        _rgba(119, 119, 129, 0.3),
      );
    },
  );
  test("new Color('hsla(-10.0, 100%, 50%, -0.2)').hslString() (:39)", () {
    expect(
      Color('hsla(-10.0, 100%, 50%, -0.2)').hslString(),
      'hsla(350, 100%, 50%, 0)',
    );
  });
  test("new Color('hsla(-1e1, 1e2%, 50%, -2e-1)').hslString() (:40)", () {
    expect(
      Color('hsla(-1e1, 1e2%, 50%, -2e-1)').hslString(),
      'hsla(350, 100%, 50%, 0)',
    );
  });
  test("new Color('blue').rgb (:42)", () {
    expect(Color('blue').rgb, _rgba(0, 0, 255, 1));
  });
  test("new Color('BluE').rgb (:43)", () {
    expect(Color('BluE').rgb, _rgba(0, 0, 255, 1));
  });
  test("new Color('transparent').rgb (:44)", () {
    expect(Color('transparent').rgb, _rgba(0, 0, 0, 0));
  });
  test("new Color('yellowblue').rgb (:46)", () {
    expect(Color('yellowblue').rgb, isNull);
  });
  test("new Color('#1').rgb (:47)", () {
    expect(Color('#1').rgb, isNull);
  });
  test("new Color('#f').rgb (:48)", () {
    expect(Color('#f').rgb, isNull);
  });
  test("new Color('#4f').rgb (:49)", () {
    expect(Color('#4f').rgb, isNull);
  });
  test("new Color('#45ab4').rgb (:50)", () {
    expect(Color('#45ab4').rgb, isNull);
  });
  test("new Color('#45ab45e').rgb (:51)", () {
    expect(Color('#45ab45e').rgb, isNull);
  });
  test("new Color('yellowblue').hexString() (:53)", () {
    expect(Color('yellowblue').hexString(), isNull);
  });
  test("new Color('#45ab45ed').hexString() (:55)", () {
    expect(Color('#45ab45ed').hexString(), '#45AB45ED');
  });
  test("new Color('hsl(100, 50%, 50%)').rgb (:56)", () {
    expect(Color('hsl(100, 50%, 50%)').rgb, _rgba(106, 191, 64, 1));
  });
  test("new Color('hsl(100, 50%, 50%)').hexString() (:57)", () {
    expect(Color('hsl(100, 50%, 50%)').hexString(), '#6ABF40');
  });
  test("new Color('hsl(100, 50%, 50%)').hslString() (:58)", () {
    expect(Color('hsl(100, 50%, 50%)').hslString(), 'hsl(100, 50%, 50%)');
  });
  test("new Color('hsl(100, 50%, 75%)').hexString() (:59)", () {
    expect(Color('hsl(100, 50%, 75%)').hexString(), '#B5DF9F');
  });
  test("new Color('rgb(54, 162, 235)').hslString() (:60)", () {
    expect(Color('rgb(54, 162, 235)').hslString(), 'hsl(204, 82%, 57%)');
  });
  test("new Color('#123').hexString() (:61)", () {
    expect(Color('#123').hexString(), '#123');
  });
  test("new Color('#123F').hexString() (:62)", () {
    expect(Color('#123F').hexString(), '#123');
  });
  test("new Color('#1234').hexString() (:63)", () {
    expect(Color('#1234').hexString(), '#1234');
  });
  test("new Color('#112233').hexString() (:64)", () {
    expect(Color('#112233').hexString(), '#123');
  });
  test("new Color('#112233FF').hexString() (:65)", () {
    expect(Color('#112233FF').hexString(), '#123');
  });

  // manipulation
  test("new Color('#7743CE').alpha(0.5).lighten(0.5).hslString() (:68)", () {
    expect(
      Color('#7743CE').alpha(0.5).lighten(0.5).hslString(),
      'hsla(262, 58%, 80%, 0.5)',
    );
  });
  test("new Color('rgb(0, 100, 255)').negate().rgbString() (:70)", () {
    expect(Color('rgb(0, 100, 255)').negate().rgbString(), 'rgb(255, 155, 0)');
  });
  test("new Color('hsl(100, 50%, 50%)').lighten(0.5).hslString() (:72)", () {
    expect(
      Color('hsl(100, 50%, 50%)').lighten(0.5).hslString(),
      'hsl(100, 50%, 75%)',
    );
  });
  test("new Color('hsl(100, 50%, 50%)').darken(0.5).hslString() (:73)", () {
    expect(
      Color('hsl(100, 50%, 50%)').darken(0.5).hslString(),
      'hsl(100, 50%, 25%)',
    );
  });
  test("new Color('hsl(100, 50%, 50%)').saturate(0.5).hslString() (:75)", () {
    expect(
      Color('hsl(100, 50%, 50%)').saturate(0.5).hslString(),
      'hsl(100, 75%, 50%)',
    );
  });
  test("new Color('hsl(204, 82%, 57%)').saturate(0.5).hslString() (:76)", () {
    expect(
      Color('hsl(204, 82%, 57%)').saturate(0.5).hslString(),
      'hsl(204, 100%, 57%)',
    );
  });
  test("new Color('rgb(54, 162, 235)').saturate(0.5).hslString() (:77)", () {
    expect(
      Color('rgb(54, 162, 235)').saturate(0.5).hslString(),
      'hsl(204, 100%, 57%)',
    );
  });
  test("new Color('rgb(54, 162, 235)').saturate(0.5).rgbString() (:78)", () {
    expect(
      Color('rgb(54, 162, 235)').saturate(0.5).rgbString(),
      'rgb(34, 167, 255)',
    );
  });
  test("new Color('hsl(100, 50%, 50%)').desaturate(0.5).hslString() (:79)", () {
    expect(
      Color('hsl(100, 50%, 50%)').desaturate(0.5).hslString(),
      'hsl(100, 25%, 50%)',
    );
  });
  test("new Color('#5CBF54').greyscale().hexString() (:80)", () {
    expect(Color('#5CBF54').greyscale().hexString(), '#969696');
  });
  test("new Color('rgba(10, 10, 10, 0.8)').clearer(0.5).rgbString() (:82)", () {
    expect(
      Color('rgba(10, 10, 10, 0.8)').clearer(0.5).rgbString(),
      'rgba(10, 10, 10, 0.4)',
    );
  });
  test("new Color('rgba(10, 10, 10, 0.8)').opaquer(0.5).rgbString() (:83)", () {
    expect(
      Color('rgba(10, 10, 10, 0.8)').opaquer(0.5).rgbString(),
      'rgb(10, 10, 10)',
    );
  });
  test("new Color('hsl(60, 20%, 20%)').rotate(180).hslString() (:85)", () {
    expect(
      Color('hsl(60, 20%, 20%)').rotate(180).hslString(),
      'hsl(240, 20%, 20%)',
    );
  });
  test("new Color('hsl(60, 20%, 20%)').rotate(-90).hslString() (:86)", () {
    expect(
      Color('hsl(60, 20%, 20%)').rotate(-90).hslString(),
      'hsl(330, 20%, 20%)',
    );
  });
  test("new Color('cyan').mix(new Color('yellow')).rgbString() (:88)", () {
    expect(
      Color('cyan').mix(Color('yellow')).rgbString(),
      'rgb(128, 255, 128)',
    );
  });
  test("new Color('cyan').mix(new Color('yellow'), 0.3).rgbString() (:89)", () {
    expect(
      Color('cyan').mix(Color('yellow'), 0.3).rgbString(),
      'rgb(179, 255, 77)',
    );
  });
  test("new Color('rgba(10, 10, 10, 0.8)').clone().rgbString() (:91)", () {
    expect(
      Color('rgba(10, 10, 10, 0.8)').clone().rgbString(),
      'rgba(10, 10, 10, 0.8)',
    );
  });
  test("new Color('invalid-color-value').lighten(0.1).hslString() (:93)", () {
    expect(Color('invalid-color-value').lighten(0.1).hslString(), isNull);
  });
  test(
    "new Color('invalid-color-value').mix(undefined, 0.5).rgbString() (:94)",
    () {
      expect(Color('invalid-color-value').mix(null, 0.5).rgbString(), isNull);
    },
  );
  test(
    "new Color('red').interpolate(new Color('green'), 0).rgbString() (:96)",
    () {
      expect(
        Color('red').interpolate(Color('green'), 0).rgbString(),
        'rgb(255, 0, 0)',
      );
    },
  );
  test(
    "new Color('red').interpolate(new Color('green'), 0.25).rgbString() (:97)",
    () {
      expect(
        Color('red').interpolate(Color('green'), 0.25).rgbString(),
        'rgb(225, 65, 0)',
      );
    },
  );
  test(
    "new Color('red').interpolate(new Color('green'), 0.5).rgbString() (:98)",
    () {
      expect(
        Color('red').interpolate(Color('green'), 0.5).rgbString(),
        'rgb(188, 92, 0)',
      );
    },
  );
  test(
    "new Color('red').interpolate(new Color('green'), 0.75).rgbString() (:99)",
    () {
      expect(
        Color('red').interpolate(Color('green'), 0.75).rgbString(),
        'rgb(137, 112, 0)',
      );
    },
  );
  test(
    "new Color('red').interpolate(new Color('green'), 1).rgbString() (:100)",
    () {
      expect(
        Color('red').interpolate(Color('green'), 1).rgbString(),
        'rgb(0, 128, 0)',
      );
    },
  );
  test(
    "new Color('#fefa').interpolate(new Color('#ced5'), 0.6).hexString() "
    '(:102)',
    () {
      expect(
        Color('#fefa').interpolate(Color('#ced5'), 0.6).hexString(),
        '#E2EDEC77',
      );
    },
  );

  // invalid values
  test("new Color('rgba(267,292,60,0.2)').rgbString() (:105)", () {
    expect(
      Color('rgba(267,292,60,0.2)').rgbString(),
      'rgba(255, 255, 60, 0.2)',
    );
  });
}
