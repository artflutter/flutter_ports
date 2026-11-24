// Original code, not ported from Chart.js: core.adapters cases with no spec.
import 'package:flutter_chartjs_port/chartjs_core.dart';
import 'package:test/test.dart';

// Upstream has no spec for src/core/core.adapters.ts (AGENTS.md rule 3). The
// expected values come from src/core/core.adapters.ts at v4.5.1, with its
// types stripped by Node.js v24.12.0 on x64. `scale.time.tests.js:1286`
// calls `override` once: the port gives a subclass to `adapters.date` there
// (row adapt-date-adapter-class).

/// The `options` of [adapter], read by name: `adapter.options[key]`.
Object? _option(DateAdapter adapter, String key) => jsGet(adapter.options, key);

void main() {
  final factory = adapters.date;
  tearDown(() => adapters.date = factory);

  group('adapters', () {
    test('date starts with the constructor of DefaultDateAdapter', () {
      expect(adapters.date, same(DefaultDateAdapter.new));
      expect(adapters.date(null), isA<DefaultDateAdapter>());
    });

    test('date(options) gives the options to the adapter', () {
      final options = <String, Object?>{'zone': 'UTC'};
      expect(adapters.date(options).options, same(options));
      expect(adapters.date(undefined).options, <String, Object?>{});
    });

    test('an app writes the constructor of its own adapter', () {
      adapters.date = _RecordingAdapter.new;
      final adapter = adapters.date(null);
      expect(adapter, isA<_RecordingAdapter>());
      expect(adapter.parse('2015'), 42);
      expect(adapter.add(0, 1, TimeUnit.second), 1000);
    });
  });

  group('DateAdapterBase', () {
    test('keeps the options object', () {
      final options = <String, Object?>{'zone': 'UTC'};
      expect(DefaultDateAdapter(options).options, same(options));
      expect(_option(DefaultDateAdapter(options), 'zone'), 'UTC');
    });

    test('a falsy options gives a new empty object', () {
      for (final value in [null, 0.0, '', false, double.nan, undefined]) {
        expect(
          DefaultDateAdapter(value).options,
          <String, Object?>{},
          reason: '$value',
        );
      }
      expect(DefaultDateAdapter().options, <String, Object?>{});
      expect(
        DefaultDateAdapter().options,
        isNot(same(DefaultDateAdapter().options)),
      );
    });

    test('a truthy options that is not an object stays as it is', () {
      expect(DefaultDateAdapter('abc').options, 'abc');
      expect(DefaultDateAdapter(5.0).options, 5.0);
      expect(DefaultDateAdapter([1.0]).options, [1.0]);
    });

    test('init does nothing', () {
      final adapter = DefaultDateAdapter()
        ..init(undefined)
        ..init(<String, Object?>{'x': 1.0});
      expect(adapter.options, <String, Object?>{});
    });

    test('an override of init gets the chart options', () {
      final adapter = _RecordingAdapter();
      final options = <String, Object?>{'locale': 'es'};
      adapter.init(options);
      expect(adapter.chartOptions, same(options));
    });
  });
}

/// An adapter of a test: `parse` gives 42, and `init` keeps the chart
/// options.
final class _RecordingAdapter([super.options]) extends DefaultDateAdapter {
  /// The chart options of the last [init].
  Object? chartOptions;

  @override
  void init(Object? chartOptions) => this.chartOptions = chartOptions;

  @override
  double? parse(Object? value, [String? format]) => 42;
}
