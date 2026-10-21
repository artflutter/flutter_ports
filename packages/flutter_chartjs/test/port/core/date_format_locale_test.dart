// Original code, not ported from Chart.js: the locale of the date adapter.
@TestOn('vm')
library;

import 'package:flutter_chartjs/src/core/core.adapters.dart';
import 'package:flutter_chartjs/src/core/date_adapter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:test/test.dart';

// The locale of the default date adapter (Chart.js ADR 0024, decision 6)
// when the app loads the date data after the first chart.
//
// moment 2.29.4 on the x64 Node.js v24.12.0 (scratchpad locale_probe.cjs):
// after a failed `moment.locale('zz')`, the format gives `January` and the
// week starts on Sunday. `moment.defineLocale('zz', …)` then makes `zz` the
// global locale (moment.js:2182-2185). The next format uses its months and
// its week start (dow 1).
//
// `initializeDateFormatting` loads the date data of each locale, and no call
// removes it. Thus these cases are in a file of their own: the other date
// tests run in a process with the en_US data only.
//
// The cases depend on each other and run in the order of the file. A test
// shard (`--total-shards`) can run a part of the cases. Thus each case after
// the first load of the date data loads the data again. The load does not
// change data that is already loaded.

/// The time of the fields in UTC.
double _at(int y, [int m = 1, int d = 1, int h = 0]) =>
    DateTime.utc(y, m, d, h).millisecondsSinceEpoch.toDouble();

void main() {
  String? previousZone;
  String? previousLocale;
  setUp(() {
    previousZone = defaultDateZone;
    setDefaultDateZone('Etc/UTC');
    previousLocale = Intl.defaultLocale;
  });
  tearDown(() {
    setDefaultDateZone(previousZone);
    Intl.defaultLocale = previousLocale;
  });

  final adapter = DateAdapterBase();
  // 2015-01-01 is a Thursday.
  final t = _at(2015, 1, 1, 20);

  test('a locale without date data gives the en_US texts', () {
    Intl.defaultLocale = 'de';
    adapter.formats();
    expect(adapter.format(t, 'MMMM'), 'January');
    expect(adapter.startOf(t, 'week'), _at(2014, 12, 28));
  });

  test('an alias of en_US before initializeDateFormatting', () {
    // Without the date data, intl accepts each alias of en_US. The cache
    // keeps the patterns of these cases for the case after the data.
    for (final alias in ['en-US', 'en_us']) {
      Intl.defaultLocale = alias;
      adapter.formats();
      expect(adapter.format(t, 'MMM d'), 'Jan 1', reason: alias);
      expect(adapter.format(t, 'h:mm a'), '8:00 pm', reason: alias);
      expect(adapter.parse('Mar 4 2015', 'MMM d yyyy'), _at(2015, 3, 4));
      expect(adapter.startOf(t, 'week'), _at(2014, 12, 28));
    }
  });

  test('the data of a locale applies from the next formats() call', () async {
    Intl.defaultLocale = 'de';
    expect(adapter.format(t, 'MMMM'), 'January');
    await initializeDateFormatting();
    // The cache keeps en_US for 'de' until the next update. The time scale
    // calls formats() once in each update (scale.time.js:277).
    expect(adapter.format(t, 'MMMM'), 'January');
    adapter.formats();
    expect(adapter.format(t, 'MMMM'), 'Januar');
    expect(adapter.startOf(t, 'week'), _at(2014, 12, 29));
    expect(adapter.parse('4. März 2015', 'd. MMMM yyyy'), _at(2015, 3, 4));
  });

  test('an alias of en_US after initializeDateFormatting', () async {
    await initializeDateFormatting();
    // The date data has no key for an alias. The members use en_US, also
    // for the patterns that the cache has from before the data, and they
    // do not throw (Chart.js ADR 0024, decision 6).
    for (final alias in ['en-US', 'en_us']) {
      Intl.defaultLocale = alias;
      adapter.formats();
      expect(adapter.format(t, 'MMM d'), 'Jan 1', reason: alias);
      expect(adapter.format(t, 'h:mm a'), '8:00 pm', reason: alias);
      expect(adapter.parse('Mar 4 2015', 'MMM d yyyy'), _at(2015, 3, 4));
      expect(adapter.startOf(t, 'week'), _at(2014, 12, 28));
    }
  });

  test('a locale that intl does not know gives en_US, not a throw', () async {
    await initializeDateFormatting();
    // After initializeDateFormatting, the DateFormat constructor throws an
    // ArgumentError for such a locale. moment keeps `en` for a locale
    // without data.
    expect(() => DateFormat('MMMM', 'xx'), throwsArgumentError);
    Intl.defaultLocale = 'xx';
    adapter.formats();
    expect(adapter.format(t, 'MMMM'), 'January');
    expect(adapter.startOf(t, 'week'), _at(2014, 12, 28));
  });

  test(
    'a locale with a region that intl does not know uses the language',
    () async {
      await initializeDateFormatting();
      Intl.defaultLocale = 'de_XX';
      adapter.formats();
      expect(adapter.format(t, 'MMMM'), 'Januar');
      expect(adapter.startOf(t, 'week'), _at(2014, 12, 29));
    },
  );
}
