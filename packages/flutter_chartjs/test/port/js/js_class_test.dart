// Original code, not ported from Chart.js: tests of lib/src/js/js_class.dart.
import 'dart:collection';

import 'package:flutter_chartjs/src/js/js_class.dart';
import 'package:flutter_chartjs/src/js/js_number.dart' show jsToString;
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:test/test.dart';

// The expected values come from Node.js v24.12.0 on x64 (V8 13.6), with the
// JavaScript classes of each comment, for example:
//   class A { static id = 'a'; static defaults = {x: 1}; }
//   class B extends A {}
//   class C extends B { static id = 'c'; }
// The class value case of jsGet is in js_object_test.dart. The class value
// cases of jsIsFunction and jsCall are in js_function_test.dart.

/// The [undefined] sentinel.
final Matcher _isUndefined = same(undefined);

/// A Map that records the order of its writes.
final class _RecordingMap extends MapBase<String, Object?> {
  final Map<String, Object?> _map = {};

  /// The keys of the writes, in their order.
  final List<String> writes = [];

  @override
  Object? operator [](Object? key) => _map[key];

  @override
  void operator []=(String key, Object? value) {
    writes.add(key);
    _map[key] = value;
  }

  @override
  Iterable<String> get keys => _map.keys;

  @override
  Object? remove(Object? key) => _map.remove(key);

  @override
  void clear() => _map.clear();
}

void main() {
  late JsClass a;
  late JsClass b;
  late JsClass c;
  late Map<String, Object?> defaultsOfA;

  setUp(() {
    defaultsOfA = {'x': 1.0};
    a = JsClass('A', statics: {'id': 'a', 'defaults': defaultsOfA});
    b = JsClass('B', superclass: a);
    c = JsClass('C', superclass: b, statics: {'id': 'c'});
  });

  group('JsClass', () {
    test('keeps its name and superclass', () {
      expect(a.name, 'A');
      expect(a.superclass, isNull);
      expect(b.superclass, same(a));
      expect(c.superclass, same(b));
    });

    test('a subclass reads the statics of its superclass', () {
      // B.id is 'a' and C.id is 'c'. 'id' in B is true. B.defaults ===
      // A.defaults is true. B.absent is undefined.
      expect(b.id, 'a');
      expect(b['id'], 'a');
      expect(c.id, 'c');
      expect(c['id'], 'c');
      expect(b.has('id'), isTrue);
      expect(b['defaults'], same(defaultsOfA));
      expect(c['defaults'], same(defaultsOfA));
      expect(b['absent'], _isUndefined);
      expect(b.has('absent'), isFalse);
    });

    test('a write makes an own static property of the class value', () {
      // Object.assign(B, {id: 'b', extra: 2}) gives A.id 'a', B.id 'b',
      // C.id 'c', A.extra undefined, B.extra 2 and C.extra 2.
      b['id'] = 'b';
      b['extra'] = 2.0;
      expect([a.id, b.id, c.id], ['a', 'b', 'c']);
      expect(a['extra'], _isUndefined);
      expect(a.has('extra'), isFalse);
      expect(b['extra'], 2.0);
      expect(c['extra'], 2.0);
    });

    test('a write of undefined keeps an own key', () {
      // B.id = undefined gives B.id undefined, 'id' in B true and C.id 'c'.
      b['id'] = undefined;
      expect(b.id, _isUndefined);
      expect(b['id'], _isUndefined);
      expect(b.has('id'), isTrue);
      expect(c.id, 'c');
      expect(a.id, 'a');
    });

    test('an own JS null is a value, not an absent key', () {
      // class S { static dataElementType = null; } class S2 extends S {}
      // S2.dataElementType is null, and 'dataElementType' in S2 is true.
      final s = JsClass('S', statics: {'dataElementType': null});
      final s2 = JsClass('S2', superclass: s);
      expect(s2['dataElementType'], isNull);
      expect(s2.has('dataElementType'), isTrue);
      expect(s2.has('datasetElementType'), isFalse);
    });

    test('the id of a class value without an id is undefined', () {
      // class Element {}: Element.id is undefined, 'id' in Element is false.
      final element = JsClass('Element', statics: {'defaults': {}});
      expect(element.id, _isUndefined);
      expect(element['id'], _isUndefined);
      expect(element.has('id'), isFalse);
      expect(JsClass('Sub', superclass: element).id, _isUndefined);
    });

    test('an id that is not a string keeps its value', () {
      final numeric = JsClass('N', statics: {'id': 7.0});
      expect(numeric.id, 7.0);
      expect(JsClass('M', superclass: numeric).id, 7.0);
    });

    test('equality is identity', () {
      final other = JsClass('A', statics: {'id': 'a'});
      expect(a == a, isTrue);
      expect(a == other, isFalse);
      expect([b, a].indexOf(a), 1);
    });
  });

  group('isSubclassOf', () {
    test('is strict and follows the chain', () {
      // Object.prototype.isPrototypeOf.call(X.prototype, Y.prototype) for
      // each pair: A of A false, A of B true, A of C true, B of A false.
      expect(a.isSubclassOf(a), isFalse);
      expect(b.isSubclassOf(a), isTrue);
      expect(c.isSubclassOf(a), isTrue);
      expect(c.isSubclassOf(b), isTrue);
      expect(a.isSubclassOf(b), isFalse);
      expect(b.isSubclassOf(c), isFalse);
    });

    test('each class value but Object is for the type Object', () {
      // Object of A true, Object of Object false.
      expect(a.isSubclassOf(jsObjectClass), isTrue);
      expect(c.isSubclassOf(jsObjectClass), isTrue);
      expect(jsObjectClass.isSubclassOf(jsObjectClass), isFalse);
      final derived = JsClass('D', superclass: jsObjectClass);
      expect(derived.isSubclassOf(jsObjectClass), isTrue);
      expect(jsObjectClass.isSubclassOf(derived), isFalse);
    });
  });

  group('jsConstruct', () {
    test('gives the class value as new.target to its construct', () {
      final targets = <JsClass>[];
      final p = JsClass(
        'P',
        construct: (newTarget, args) {
          targets.add(newTarget);
          return [...args];
        },
      );
      expect(jsConstruct(p, [1.0, 'x']), [1.0, 'x']);
      expect(targets, [same(p)]);
    });

    test('a subclass without construct uses the construct of its '
        'superclass, with its own new.target', () {
      // class P { constructor(...args) { this.args = args;
      // this.target = new.target.name; } } class Q extends P {}
      // new Q(1, 'x') gives args [1, 'x'] and the target 'Q'.
      final p = JsClass(
        'P',
        construct: (newTarget, args) => {
          'args': [...args],
          'target': newTarget.name,
        },
      );
      final q = JsClass('Q', superclass: p);
      final r = JsClass('R', superclass: q);
      expect(jsConstruct(q, [1.0, 'x']), {
        'args': [1.0, 'x'],
        'target': 'Q',
      });
      expect(jsConstruct(r, const []), {'args': <Object?>[], 'target': 'R'});
    });

    test('a class value without construct in its chain gives a new plain '
        'object', () {
      // Object.keys(new A()) and Object.keys(new Object()) are [].
      final first = jsConstruct(b, const []);
      final second = jsConstruct(b, const []);
      expect(first, isA<Map<String, Object?>>());
      expect(first, isEmpty);
      expect(identical(first, second), isFalse);
      expect(jsConstruct(jsObjectClass, const []), <String, Object?>{});
    });

    test('throws a TypeError for a value that is not a class value', () {
      // new null, new undefined, new 5, new ({a: 1}) and new (() => 1)
      // throw a TypeError: "... is not a constructor".
      for (final value in <Object?>[
        null,
        undefined,
        5.0,
        'A',
        <String, Object?>{'a': 1.0},
        () => 1.0,
      ]) {
        expect(
          () => jsConstruct(value, const []),
          throwsA(isA<TypeError>()),
          reason: '$value',
        );
      }
    });
  });

  group('jsAssign', () {
    test('writes the keys of the source in the Object.keys order', () {
      // const t = {z: 0}; Object.assign(t, {b: 1, 10: 2, a: 3, 2: 4})
      // returns t. The writes are 2, 10, b, a. Object.keys(t) is
      // ['2', '10', 'z', 'b', 'a'].
      final target = _RecordingMap()..['z'] = 0.0;
      target.writes.clear();
      final result = jsAssign(target, {
        'b': 1.0,
        '10': 2.0,
        'a': 3.0,
        '2': 4.0,
      });
      expect(result, same(target));
      expect(target.writes, ['2', '10', 'b', 'a']);
      expect(target.keys, ['z', '2', '10', 'b', 'a']);
      expect(target['10'], 2.0);
    });

    test('writes own static properties of a class value', () {
      // class S { static dataElementType = null; } class S2 extends S {}
      // Object.assign(S2, {dataElementType: 'x'}) gives S.dataElementType
      // null and S2.dataElementType 'x'.
      final s = JsClass('S', statics: {'dataElementType': null});
      final s2 = JsClass('S2', superclass: s);
      expect(jsAssign(s2, {'dataElementType': 'x', 'id': 's2'}), same(s2));
      expect(s['dataElementType'], isNull);
      expect(s2['dataElementType'], 'x');
      expect(s2.id, 's2');
      expect(s.id, _isUndefined);
    });

    test('a write of a present key keeps the position of the key', () {
      final target = <String, Object?>{'a': 1.0, 'b': 2.0};
      jsAssign(target, {'c': 3.0, 'a': 4.0});
      expect(target.keys, ['a', 'b', 'c']);
      expect(target['a'], 4.0);
    });

    test('throws a TypeError for null and undefined', () {
      // Object.assign(null, {}) and Object.assign(undefined, {}) throw a
      // TypeError: "Cannot convert undefined or null to object".
      expect(() => jsAssign(null, const {}), throwsA(isA<TypeError>()));
      expect(() => jsAssign(undefined, const {}), throwsA(isA<TypeError>()));
    });

    test('throws an ArgumentError for another target', () {
      expect(() => jsAssign(5.0, const {}), throwsArgumentError);
      expect(() => jsAssign('s', const {}), throwsArgumentError);
    });
  });

  group('js-semantics-class-source', () {
    test('a class without a body and without extends prints its source', () {
      // String(class FaultyPlugin {}) is 'class FaultyPlugin {}', and
      // '' + class X {} is 'class X {}'.
      final faulty = JsClass('FaultyPlugin');
      expect(faulty.toString(), 'class FaultyPlugin {}');
      expect(jsToString(faulty), 'class FaultyPlugin {}');
      expect(jsToString(JsClass('X')), 'class X {}');
      // The message of core.registry.tests.js:88-92.
      expect(
        'class does not have id: ${jsToString(faulty)}',
        'class does not have id: class FaultyPlugin {}',
      );
    });

    test('another class prints no source text', () {
      // String(B) is 'class B extends A {}' in JavaScript. The port gives
      // the text of a class without a body and without extends.
      expect(jsToString(b), 'class B {}');
      expect(jsToString(c), 'class C {}');
    });
  });
}
