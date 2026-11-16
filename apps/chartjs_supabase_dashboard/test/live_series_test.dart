// Original code, not ported from Chart.js: the tests of the live series.

import 'package:chartjs_supabase_dashboard/src/live_series.dart';
import 'package:chartjs_supabase_dashboard/src/metric_source.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_metric_source.dart';

void main() {
  test('start loads the newest page in the order of the ids', () async {
    final source = MemoryMetricSource(rows: 250);
    final series = LiveSeries(source, pageSize: 100);
    addTearDown(series.dispose);

    await series.start(pump: false);

    expect(series.ready, isTrue);
    expect(series.pages, 1);
    expect(series.rowCount, 100);
    expect(series.reachedStart, isFalse);
    expect(
      series.oldest,
      MemoryMetricSource.start.add(const Duration(seconds: 151)),
    );
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

  test('loadOlder loads the pages before the oldest row', () async {
    final source = MemoryMetricSource(rows: 250);
    final series = LiveSeries(source, pageSize: 100);
    addTearDown(series.dispose);
    await series.start(pump: false);

    await series.loadOlder();
    expect(series.pages, 2);
    expect(series.rowCount, 200);
    expect(series.reachedStart, isFalse);

    await series.loadOlder();
    expect(series.pages, 3);
    expect(series.rowCount, 250);
    expect(series.reachedStart, isTrue);
    expect(
      series.oldest,
      MemoryMetricSource.start.add(const Duration(seconds: 1)),
    );

    final calls = source.pageCalls;
    await series.loadOlder();
    expect(source.pageCalls, calls, reason: 'no page after the start');
  });

  test('pageStarts has the oldest row of each page', () async {
    final source = MemoryMetricSource(rows: 250);
    final series = LiveSeries(source, pageSize: 100);
    addTearDown(series.dispose);
    DateTime at(int seconds) =>
        MemoryMetricSource.start.add(Duration(seconds: seconds));

    await series.start(pump: false);
    expect(series.pageStarts, [at(151)]);

    await series.loadOlder();
    await series.loadOlder();
    expect(series.pageStarts, [at(151), at(51), at(1)]);

    // An empty page at the start of the data adds no split.
    final empty = LiveSeries(MemoryMetricSource(), pageSize: 100);
    addTearDown(empty.dispose);
    await empty.start(pump: false);
    expect(empty.pageStarts, isEmpty);
  });

  test('a page joins the points in the order of the time', () async {
    final source = MemoryMetricSource(rows: 250);
    final series = LiveSeries(source, pageSize: 100);
    addTearDown(series.dispose);
    await series.start(pump: false);
    await series.loadOlder();

    final times = [for (final point in series.points) point.x as double];
    expect(times, hasLength(200));
    expect(times, orderedEquals([...times]..sort()));
    expect(
      series.pointIndexAt(
        MemoryMetricSource.start
            .add(const Duration(seconds: 151))
            .millisecondsSinceEpoch
            .toDouble(),
      ),
      100,
    );
  });

  test('a page that is on its way blocks a second one', () async {
    final source = MemoryMetricSource(rows: 500);
    final series = LiveSeries(source, pageSize: 100);
    addTearDown(series.dispose);
    await series.start(pump: false);

    await Future.wait([series.loadOlder(), series.loadOlder()]);

    expect(series.pages, 2);
    expect(source.pageCalls, 2);
  });

  test('a realtime row joins the series once', () async {
    final source = MemoryMetricSource(rows: 10);
    final series = LiveSeries(source, pageSize: 100);
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
    final series = LiveSeries(source, pageSize: 100);
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
    final series = LiveSeries(source, pageSize: 100);
    await series.start();
    expect(series.pumping, isTrue);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(series.sent, 3);
    expect(series.received, 3);
    expect(series.rowCount, 8);
    expect(series.roundTrip, isNotNull);
    expect(series.error, isNull);

    series.pumping = false;
    await tester.pump(const Duration(seconds: 2));
    expect(series.sent, 3);

    series.dispose();
    expect(source.disposed, isTrue);
  });
}
