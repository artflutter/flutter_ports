// Original code, not ported from Chart.js: the tests of the live series.

import 'package:chartjs_supabase_dashboard/src/live_series.dart';
import 'package:chartjs_supabase_dashboard/src/metric_source.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_metric_source.dart';

/// Pages of 100 seconds: [MemoryMetricSource.start] is on their grid.
const span = Duration(seconds: 100);

/// The time [seconds] after [MemoryMetricSource.start], of the row with
/// that id.
DateTime at(int seconds) =>
    MemoryMetricSource.start.add(Duration(seconds: seconds));

void main() {
  test('start loads the cell of the newest row', () async {
    final source = MemoryMetricSource(rows: 250);
    final series = LiveSeries(source, pageSpan: span);
    addTearDown(series.dispose);

    await series.start(pump: false);

    expect(series.ready, isTrue);
    expect(series.pages, 1);
    expect(series.rowCount, 51);
    expect(series.reachedStart, isFalse);
    expect(series.oldest, at(200));
    expect(
      series.newest,
      MemoryMetricSource.start.add(const Duration(seconds: 250)),
    );
    expect(
      series.points.first.x,
      series.oldest!.millisecondsSinceEpoch.toDouble(),
    );
    expect(
      series.points.last.x,
      series.newest!.millisecondsSinceEpoch.toDouble(),
    );
  });

  test('loadOlder loads the cells before the oldest page', () async {
    final source = MemoryMetricSource(rows: 250);
    final series = LiveSeries(source, pageSpan: span);
    addTearDown(series.dispose);
    await series.start(pump: false);

    await series.loadOlder();
    expect(series.pages, 2);
    expect(series.rowCount, 151);
    expect(series.reachedStart, isFalse);

    await series.loadOlder();
    expect(series.pages, 3);
    expect(series.rowCount, 250);
    expect(series.oldest, at(1));

    // No row is before the third page: the start of the data.
    await series.loadOlder();
    expect(series.pages, 3);
    expect(series.reachedStart, isTrue);

    final calls = source.pageCalls;
    await series.loadOlder();
    expect(source.pageCalls, calls, reason: 'no page after the start');
  });

  test('pageStarts has the grid time of each page', () async {
    final source = MemoryMetricSource(rows: 250);
    final series = LiveSeries(source, pageSpan: span);
    addTearDown(series.dispose);

    await series.start(pump: false);
    expect(series.pageStarts, [at(200)]);

    await series.loadOlder();
    await series.loadOlder();
    expect(series.pageStarts, [at(200), at(100), at(0)]);

    // An empty table has no page.
    final empty = LiveSeries(MemoryMetricSource(), pageSpan: span);
    addTearDown(empty.dispose);
    await empty.start(pump: false);
    expect(empty.pageStarts, isEmpty);
    expect(empty.reachedStart, isTrue);
  });

  test('a cell with no row gives no page', () async {
    // The rows 1 to 50, and row 51 at 1000 s: the cells from 100 s to
    // 1000 s are empty.
    final source = MemoryMetricSource(rows: 50)..addRow(51, at(1000), 1);
    final series = LiveSeries(source, pageSpan: span);
    addTearDown(series.dispose);

    await series.start(pump: false);
    await series.loadOlder();

    expect(series.pageStarts, [at(1000), at(0)]);
    expect(series.rowCount, 51);
    expect(source.pageCalls, 2);
  });

  test('a page joins the points in the order of the time', () async {
    final source = MemoryMetricSource(rows: 250);
    final series = LiveSeries(source, pageSpan: span);
    addTearDown(series.dispose);
    await series.start(pump: false);
    await series.loadOlder();

    final times = [for (final point in series.points) point.x! as double];
    expect(times, hasLength(151));
    expect(times, orderedEquals([...times]..sort()));
    expect(series.pointIndexAt(at(151).millisecondsSinceEpoch.toDouble()), 51);
  });

  test('a page that is on its way blocks a second one', () async {
    final source = MemoryMetricSource(rows: 500);
    final series = LiveSeries(source, pageSpan: span);
    addTearDown(series.dispose);
    await series.start(pump: false);

    await Future.wait([series.loadOlder(), series.loadOlder()]);

    expect(series.pages, 2);
    expect(source.pageCalls, 2);
  });

  test('a realtime row joins the series once', () async {
    final source = MemoryMetricSource(rows: 10);
    final series = LiveSeries(source, pageSpan: span);
    addTearDown(series.dispose);
    await series.start(pump: false);
    await Future<void>.delayed(Duration.zero);
    expect(series.status, LinkStatus.live);

    final ts = MemoryMetricSource.start.add(const Duration(seconds: 11));
    source
      ..addRow(11, ts, 42)
      ..addRow(11, ts, 42);

    expect(series.rowCount, 11);
    expect(series.received, 2);
    expect(series.newest, ts);
    expect(series.points.last.y, 42);
  });

  test('extent gives the values in view and the rows next to them', () async {
    final source = MemoryMetricSource(rows: 300);
    final series = LiveSeries(source);
    addTearDown(series.dispose);
    await series.start(pump: false);

    double at(int id) => MemoryMetricSource.start
        .add(Duration(seconds: id))
        .millisecondsSinceEpoch
        .toDouble();
    // The rows 109 to 121 have the values 9 to 21.
    expect(series.extent(at(110), at(120)), (min: 9.0, max: 21.0));
    // One time: the rows 149, 150 and 151.
    expect(series.extent(at(150), at(150)), (min: 49.0, max: 51.0));
  });

  test('a gap longer than gapThreshold breaks the line', () async {
    final source = MemoryMetricSource(rows: 3);
    final series = LiveSeries(source, pageSpan: span);
    addTearDown(series.dispose);
    await series.start(pump: false);
    expect(series.gapThreshold, const Duration(hours: 1));
    expect(series.dashThreshold, const Duration(hours: 2));

    // 1 hour after row 3: the line joins the two rows.
    final joined = MemoryMetricSource.start.add(
      const Duration(hours: 1, seconds: 3),
    );
    source.addRow(4, joined, 6);
    expect(series.points, hasLength(4));
    expect(series.points[3].y, 6);

    // One second more than 1 hour after row 4: a point with no value.
    source.addRow(5, joined.add(const Duration(hours: 1, seconds: 1)), 7);
    expect(series.rowCount, 5);
    expect(series.points, hasLength(6));
    expect(series.points[4].y, isNull);
    expect(series.points[5].y, 7);
  });

  testWidgets('the pump inserts values and gets them back', (tester) async {
    final source = MemoryMetricSource(rows: 5);
    final series = LiveSeries(source, pageSpan: span);
    await series.start();
    expect(series.pumping, isTrue);

    // One insert in the middle of each slot of 5 s.
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 5));

    expect(series.sent, 3);
    expect(series.received, 3);
    expect(series.rowCount, 8);
    expect(series.roundTrip, isNotNull);
    expect(series.error, isNull);

    series.pumping = false;
    await tester.pump(const Duration(seconds: 10));
    expect(series.sent, 3);

    series.dispose();
    expect(source.disposed, isTrue);
  });
}
