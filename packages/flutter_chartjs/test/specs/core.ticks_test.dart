// Ported from Chart.js v4.5.1 test/specs/core.ticks.tests.js (MIT, Chart.js Contributors).
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs/src/core/core.ticks.dart' show ticks;
import 'package:flutter_chartjs/src/js/js_function.dart';
import 'package:flutter_chartjs/src/types/index.dart';
import 'package:test/test.dart';

// The spec reads `Chart.Ticks`, which src/index.umd.ts:43 sets. Here it is
// `ticks` of core.ticks.dart.

/// The `chart` of the JavaScript object literal
/// `{chart: {options: {locale}}, ...}`, passed as a [Chart]. The formatters
/// read only its options.
final class _Chart implements Chart {
  _Chart(this.options);

  @override
  final Map<String, Object?> options;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The JavaScript object literal `{chart, options}` that the spec passes as
/// `this`, passed as a [Scale]. The formatters read only `chart` and
/// `options`.
final class _Scale implements Scale {
  _Scale(this.chart, this.options);

  @override
  final Chart chart;

  @override
  final Map<String, Object?> options;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A JavaScript object literal `{value}`, passed as a [Tick].
final class _Tick implements Tick {
  const _Tick(this.value);

  @override
  final double value;

  @override
  double? get significand => null;
}

/// The member read `object.key` of the object literal [object].
Object? _member(Object? object, String key) =>
    (object! as Map<String, Object?>)[key];

void main() {
  setUpSpecs();
  group('Test tick generators', () {
    // formatters are used as default config values so users want to be able
    // to reference them
    test('Should expose formatters api', () {
      // `typeof x` is a string, so the first two upstream expectations
      // always pass. The port checks that the two values exist.
      expect(ticks, isNotNull);
      final formatters = ticks['formatters'];
      expect(formatters, isNotNull);
      // typeof value === 'function' is jsIsFunction.
      expect(jsIsFunction(_member(formatters, 'values')), isTrue);
      expect(jsIsFunction(_member(formatters, 'numeric')), isTrue);
    });

    test(
      'Should generate linear spaced ticks with correct precision',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'Should generate logarithmic spaced ticks with correct precision',
      () {},
      skip: 'blocked: controller.line',
    );

    group('formatters.numeric', () {
      test('should not fail on empty or 1 item array', () {
        final scale = _Scale(
          _Chart(<String, Object?>{'locale': 'en'}),
          <String, Object?>{
            'ticks': <String, Object?>{'format': <String, Object?>{}},
          },
        );
        // numeric.apply(scale, args) is jsCall with scale as thisArg.
        final numeric = _member(ticks['formatters'], 'numeric');
        expect(
          jsCall(numeric, [1.0, 0.0, <Tick>[]], thisArg: scale),
          '1',
        );
        expect(
          jsCall(numeric, [
            1.0,
            0.0,
            <Tick>[const _Tick(1)],
          ], thisArg: scale),
          '1',
        );
        expect(
          jsCall(numeric, [
            1.0,
            0.0,
            <Tick>[const _Tick(1), const _Tick(1.01)],
          ], thisArg: scale),
          '1.00',
        );
      });
    });
  });
}
