// Original code, not ported from Chart.js: the kept typed copy of line.points.

// Keep each step of a test as its own statement.
// ignore_for_file: cascade_invocations

import 'package:flutter_chartjs_port/chartjs_core.dart';
import 'package:test/test.dart';

// differences.md `adapt-line-points-identity`: a write of the same elements
// keeps the last typed copy. Each write still drops the derived state.

List<IElement> _points(int n) => <IElement>[
  for (var i = 0; i < n; i++)
    PointElement(<String, Object?>{'x': i.toDouble(), 'y': 1.0}),
];

void main() {
  group('LineElement.points', () {
    test('a write of the same elements keeps the typed copy', () {
      final points = _points(3);
      final line = LineElement()..points = points;
      final first = line.points;
      line.points = points;
      expect(identical(line.points, first), isTrue);
      expect(first, isA<List<IPointElement>>());
      expect(first, points);
    });

    test('a new list of the same elements keeps the typed copy', () {
      final points = _points(3);
      final line = LineElement()..points = points;
      final first = line.points;
      line.points = <IElement>[...points];
      expect(identical(line.points, first), isTrue);
    });

    test('a write of the same elements still drops the derived state', () {
      final points = _points(3);
      final line = LineElement()..points = points;
      line
        ..['_segments'] = <Segment>[]
        ..['_path'] = Path2D()
        ..['_pointsUpdated'] = true
        ..points = points;
      expect(line['_segments'], same(undefined));
      expect(line['_path'], same(undefined));
      expect(line['_pointsUpdated'], isFalse);
    });

    test('another element, order or length makes a new copy', () {
      final points = _points(3);
      final line = LineElement()..points = points;
      final first = line.points;
      points[1] = PointElement();
      line.points = points;
      final second = line.points;
      expect(identical(second, first), isFalse);
      expect(second, points);
      line.points = points.reversed.toList();
      final third = line.points;
      expect(identical(third, second), isFalse);
      expect(third, points.reversed.toList());
      points.add(PointElement());
      line.points = points;
      expect(line.points, points);
      points.removeLast();
      line.points = points;
      expect(line.points, points);
    });

    test(
      'an element written into the copy makes the next write copy again',
      () {
        final points = _points(3);
        final line = LineElement()..points = points;
        final first = line.points;
        first[0] = PointElement();
        line.points = points;
        expect(identical(line.points, first), isFalse);
        expect(line.points, points);
      },
    );

    test('a typed list stays the value and is never the copy of a write', () {
      final typed = <IPointElement>[PointElement(), PointElement()];
      final line = LineElement()..points = typed;
      expect(identical(line.points, typed), isTrue);
      final same = <IElement>[...typed];
      line.points = same;
      expect(identical(line.points, typed), isFalse);
      expect(line.points, typed);
    });

    test('a write of another value by name ends the copy', () {
      final points = _points(2);
      final line = LineElement()..points = points;
      final first = line.points;
      final other = <IPointElement>[...first];
      line['_points'] = other;
      line.points = points;
      expect(identical(line.points, other), isFalse);
      expect(identical(line.points, first), isFalse);
      expect(line.points, points);
      final second = line.points;
      line['points'] = <IElement>[...points];
      final byName = line.points;
      expect(identical(byName, second), isFalse);
      line.points = points;
      expect(identical(line.points, byName), isFalse);
      expect(line.points, points);
    });

    test('an empty list keeps a copy too', () {
      final line = LineElement()..points = <IElement>[];
      final first = line.points;
      line.points = <IElement>[];
      expect(identical(line.points, first), isTrue);
      expect(first, isEmpty);
    });
  });
}
