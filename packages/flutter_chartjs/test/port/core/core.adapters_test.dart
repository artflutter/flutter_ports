// Original code, not ported from Chart.js: core.adapters cases with no spec.
import 'package:flutter_chartjs/src/core/core.adapters.dart';
import 'package:flutter_chartjs/src/js/js_class.dart';
import 'package:flutter_chartjs/src/js/js_function.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:test/test.dart';

// Upstream has no spec for src/core/core.adapters.ts (AGENTS.md rule 3). The
// expected values come from src/core/core.adapters.ts at v4.5.1, with its
// types stripped by Node.js v24.12.0 on x64. `scale.time.tests.js:1286`
// calls `override` once. The time scale and its specs come in phase 6.
//
// `override` writes the static `DateAdapterBase.prototype` of the port. A
// tearDown clears it after each test. Upstream specs never restore it.

/// The message of the `Error` of `abstract` (core.adapters.ts:66).
const String _abstractMessage =
    'This method is not implemented: Check that a complete date adapter is '
    'provided.';

/// A [StateError] with the message of `abstract`.
final Matcher _throwsAbstract = throwsA(
  isA<StateError>().having((e) => e.message, 'message', _abstractMessage),
);

/// The `options` of [adapter], read by name: `adapter.options[key]`.
Object? _option(DateAdapter adapter, String key) => jsGet(adapter.options, key);

void main() {
  tearDown(DateAdapterBase.prototype.clear);

  group('adapters', () {
    test('has the key _date, the class value of DateAdapterBase', () {
      expect(adapters.keys, ['_date']);
      expect(adapters['_date'], same(DateAdapterBase.jsClass));
      expect(DateAdapterBase.jsClass.name, 'DateAdapterBase');
      expect(jsIsFunction(adapters['_date']), isTrue);
    });

    test('the class value has the static override', () {
      final override = jsGet(DateAdapterBase.jsClass, 'override');
      expect(jsIsFunction(override), isTrue);
      jsCall(override, [
        <String, Object?>{
          'formats': () => <String, Object?>{'day': 'D'},
        },
      ]);
      expect(DateAdapterBase().formats(), {'day': 'D'});
    });

    test('new adapters._date(options) constructs a DateAdapterBase', () {
      final options = <String, Object?>{'zone': 'UTC'};
      final adapter = jsConstruct(adapters['_date'], [options]);
      expect(adapter, isA<DateAdapterBase>());
      expect((adapter as DateAdapterBase).options, same(options));
      final none = jsConstruct(adapters['_date'], const []) as DateAdapter;
      expect(none.options, <String, Object?>{});
    });
  });

  group('DateAdapterBase', () {
    test('keeps the options object', () {
      final options = <String, Object?>{'zone': 'UTC'};
      expect(DateAdapterBase(options).options, same(options));
      expect(_option(DateAdapterBase(options), 'zone'), 'UTC');
    });

    test('a falsy options gives a new empty object', () {
      for (final value in [null, 0.0, '', false, double.nan, undefined]) {
        expect(
          DateAdapterBase(value).options,
          <String, Object?>{},
          reason: '$value',
        );
      }
      expect(DateAdapterBase().options, <String, Object?>{});
      expect(
        DateAdapterBase().options,
        isNot(same(DateAdapterBase().options)),
      );
    });

    test('a truthy options that is not an object stays as it is', () {
      expect(DateAdapterBase('abc').options, 'abc');
      expect(DateAdapterBase(5.0).options, 5.0);
      expect(DateAdapterBase([1.0]).options, [1.0]);
    });

    test('init does nothing', () {
      final adapter = DateAdapterBase()
        ..init(undefined)
        ..init(<String, Object?>{'x': 1.0});
      expect(adapter.options, <String, Object?>{});
    });

    test('the other methods throw the abstract error', () {
      final adapter = DateAdapterBase();
      expect(adapter.formats, _throwsAbstract);
      expect(() => adapter.parse(1.0, 2.0), _throwsAbstract);
      expect(() => adapter.format(1.0, 2.0), _throwsAbstract);
      expect(() => adapter.add(1.0, 2.0, 3.0), _throwsAbstract);
      expect(() => adapter.diff(1.0, 2.0, 3.0), _throwsAbstract);
      expect(() => adapter.startOf(1.0, 2.0, 3.0), _throwsAbstract);
      expect(() => adapter.endOf(1.0, 2.0), _throwsAbstract);
    });
  });

  group('adapt-date-adapter-prototype', () {
    // The model of `Object.assign(DateAdapterBase.prototype, members)`. The
    // results are the upstream results, except the error of a member that is
    // not a function.

    test('reaches the adapters made before and after it', () {
      final calls = <List<Object?>>[];
      final before = DateAdapterBase(<String, Object?>{'tag': 'before'});
      DateAdapterBase.override({
        'parse': JsFunction((Object? self, Object? value, Object? format) {
          calls.add([
            _option(self! as DateAdapter, 'tag'),
            value,
            format,
          ]);
          return 42.0;
        }),
        'formats': () => <String, Object?>{'day': 'D'},
        '_id': 'probe',
      });
      final after = DateAdapterBase(<String, Object?>{'tag': 'after'});
      expect(
        [before.parse('x'), before.parse('x', 'fmt'), after.parse('y')],
        [
          42.0,
          42.0,
          42.0,
        ],
      );
      expect(calls, [
        ['before', 'x', undefined],
        ['before', 'x', 'fmt'],
        ['after', 'y', undefined],
      ]);
      expect(before.formats(), {'day': 'D'});
      expect(after.formats(), {'day': 'D'});
      expect(DateAdapterBase.prototype['_id'], 'probe');
      expect(() => after.format(1.0, 'f'), _throwsAbstract);
    });

    test('of init gets the chart options, as scale.time.tests.js:1286', () {
      Object? chartOptions;
      DateAdapterBase.override({
        'init': (Object? options) {
          chartOptions = options;
        },
      });
      final options = <String, Object?>{'locale': 'es'};
      DateAdapterBase().init(options);
      expect(chartOptions, same(options));
    });

    test('a later override replaces only its own keys', () {
      DateAdapterBase.override({
        'parse': (Object? value) => 42.0,
        'formats': () => <String, Object?>{'day': 'D'},
      });
      DateAdapterBase.override({
        'add': JsFunction(
          (Object? self, Object? t, Object? n, Object? u) => [
            _option(self! as DateAdapter, 'tag'),
            t,
            n,
            u,
          ],
        ),
      });
      final adapter = DateAdapterBase(<String, Object?>{'tag': 'after'});
      expect(adapter.add(1.0, 2.0, 'day'), ['after', 1.0, 2.0, 'day']);
      expect(adapter.parse('z'), 42.0);
      expect(adapter.formats(), {'day': 'D'});
    });

    test('passes the arguments of each method', () {
      DateAdapterBase.override({
        'startOf': (Object? t, Object? u, Object? w) => [t, u, w],
        'endOf': (Object? t, Object? u) => [t, u],
        'diff': (Object? x, Object? y, Object? u) =>
            (x! as double) - (y! as double),
        'format': (Object? t, Object? f) => '$f:$t',
      });
      final adapter = DateAdapterBase();
      expect(adapter.startOf(1.0, 'day'), [1.0, 'day', undefined]);
      expect(adapter.startOf(1.0, 'isoWeek', 3.0), [1.0, 'isoWeek', 3.0]);
      expect(adapter.endOf(5.0, 'day'), [5.0, 'day']);
      expect(adapter.diff(9.0, 2.0, 'day'), 7.0);
      expect(adapter.format('t', 'f'), 'f:t');
    });

    test('a member that is not a function throws at the call', () {
      // JavaScript throws a TypeError: "after.format is not a function".
      DateAdapterBase.override({'format': 5.0});
      final adapter = DateAdapterBase();
      expect(() => adapter.format(1.0, 'f'), throwsArgumentError);
      DateAdapterBase.override({'format': undefined});
      expect(() => adapter.format(1.0, 'f'), throwsArgumentError);
    });

    test('through a subclass value writes the members of the base', () {
      final sub = JsClass('Sub', superclass: DateAdapterBase.jsClass);
      final override = jsGet(sub, 'override');
      expect(override, same(jsGet(DateAdapterBase.jsClass, 'override')));
      jsCall(override, [
        <String, Object?>{
          'formats': () => <String, Object?>{'sub': true},
        },
      ]);
      expect(DateAdapterBase().formats(), {'sub': true});
      final instance = jsConstruct(sub, const []) as DateAdapter;
      expect(instance.formats(), {'sub': true});
    });
  });
}
