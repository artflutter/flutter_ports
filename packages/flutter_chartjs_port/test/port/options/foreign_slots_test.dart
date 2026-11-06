// Original code, not ported from Chart.js: shared foreign slots of the options.
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/element_options_base.dart';
import 'package:flutter_chartjs_port/src/options/foreign_audit.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
import 'package:flutter_chartjs_port/src/options/resolved.g.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {
    final saved = foreignAudit;
    foreignAudit = (_, _, _) {};
    addTearDown(() => foreignAudit = saved);
  });

  final classes = <String, (ElementOptions Function(), OptionKey, OptionKey)>{
    'point': (PointOptions.new, OptionKey.radius, OptionKey.hitRadius),
    'line': (LineOptions.new, OptionKey.borderWidth, OptionKey.tension),
    'arc': (ArcOptions.new, OptionKey.angle, OptionKey.offset),
  };

  for (final MapEntry(key: name, value: (make, first, second))
      in classes.entries) {
    group('$name options', () {
      test('a clone reads the foreign values of its source', () {
        final a = make()..storeKey(first, 'x');
        final b = a.clone();
        expect(b.valueOf(first), 'x');
        expect(b.isForeign(first), isTrue);
        expect(b.foreignOf(first), 'x');
      });

      test('a foreign write to a clone leaves the source', () {
        final a = make()..storeKey(first, 'x');
        final b = a.clone()..storeKey(first, 'y');
        expect(a.valueOf(first), 'x');
        expect(b.valueOf(first), 'y');
      });

      test('a foreign write to the source leaves its clone', () {
        final a = make()..storeKey(first, 'x');
        final b = a.clone();
        a.storeKey(first, 'y');
        expect(a.valueOf(first), 'y');
        expect(b.valueOf(first), 'x');
      });

      test('a write of a plain value clears only the written object', () {
        final a = make()..storeKey(first, 'x');
        final b = a.clone()..storeKey(first, 3.0);
        expect(a.isForeign(first), isTrue);
        expect(a.foreignOf(first), 'x');
        expect(b.isForeign(first), isFalse);
        expect(b.valueOf(first), 3.0);
      });

      test('a delete in one copy leaves the other', () {
        final a = make()..storeKey(first, 'x');
        final b = a.clone();
        expect(b.jsDelete(first.jsName), isTrue);
        expect(a.valueOf(first), 'x');
        expect(b.valueOf(first), same(undefined));
      });

      test('three copies keep three states', () {
        final a = make()
          ..storeKey(first, 'x')
          ..storeKey(second, 'z');
        final b = a.clone();
        final c = b.clone();
        b.storeKey(first, 'y');
        c.storeKey(second, 'w');
        expect([a.valueOf(first), a.valueOf(second)], ['x', 'z']);
        expect([b.valueOf(first), b.valueOf(second)], ['y', 'z']);
        expect([c.valueOf(first), c.valueOf(second)], ['x', 'w']);
      });

      test('a frozen source keeps its slots and gives a writable clone', () {
        final a = make()
          ..storeKey(first, 'x')
          ..freeze();
        final b = a.clone()..storeKey(first, 'y');
        expect(a.valueOf(first), 'x');
        expect(b.valueOf(first), 'y');
        expect(() => a.storeKey(first, 'z'), throwsA(isA<TypeError>()));
      });

      test('a clone with no foreign value allocates its slots on demand', () {
        final a = make();
        final b = a.clone()..storeKey(first, 'x');
        expect(a.isForeign(first), isFalse);
        expect(b.valueOf(first), 'x');
      });
    });
  }

  for (final MapEntry(key: name, value: make) in {
    'point': PointOptions.new,
    'line': LineOptions.new,
    'bar': BarOptions.new,
    'arc': ArcOptions.new,
  }.entries) {
    test('the direct store of \$shared of $name options', () {
      final a = make()..storeKey(OptionKey.dollarShared, true);
      expect(a.$sharedValue, isTrue);
      expect(a.jsKeys().first, r'$shared');
      a.storeKey(OptionKey.dollarShared, false);
      expect(a.jsRead(r'$shared'), isFalse);
      expect(a.clone().$sharedValue, isFalse);
      a.freeze();
      expect(
        () => a.storeKey(OptionKey.dollarShared, true),
        throwsA(isA<TypeError>()),
      );
      expect(a.$sharedValue, isFalse);
    });
  }

  test(r'$shared of a generic options object stays in its Map', () {
    final a = GenericElementOptions()
      ..jsWrite('z', 1)
      ..storeKey(OptionKey.dollarShared, true);
    expect(a.jsKeys(), ['z', r'$shared']);
    expect(a.$sharedValue, isTrue);
    a.freeze();
    expect(
      () => a.storeKey(OptionKey.dollarShared, false),
      throwsA(isA<TypeError>()),
    );
  });

  test('jsToString of a string is the string', () {
    const value = 'arc';
    expect(identical(jsToString(value), value), isTrue);
    expect(jsToString(''), '');
    expect(jsToString(null), 'null');
    expect(jsToString(1.5), '1.5');
  });
}
