// Ported from d3-array v3.2.4 test/groupSort-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart' hide group;

import 'port/test_data.dart';

void main() {
  test('groupSort(data, reduce, key) returns sorted keys when reduce is an '
      'accessor', () {
    expect(
      groupSort(
        barleyData,
        (g) => medianBy(g, (d) => d.yield),
        (d) => d.variety,
      ),
      <String>[
        'Svansota',
        'No. 462',
        'Manchuria',
        'No. 475',
        'Velvet',
        'Peatland',
        'Glabron',
        'No. 457',
        'Wisconsin No. 38',
        'Trebi',
      ],
    );
    expect(
      groupSort(
        barleyData,
        (g) => -medianBy(g, (d) => d.yield)!,
        (d) => d.variety,
      ),
      <String>[
        'Trebi',
        'Wisconsin No. 38',
        'No. 457',
        'Glabron',
        'Peatland',
        'Velvet',
        'No. 475',
        'Manchuria',
        'No. 462',
        'Svansota',
      ],
    );
    expect(
      groupSort(
        barleyData,
        (g) => medianBy(g, (d) => -d.yield),
        (d) => d.variety,
      ),
      <String>[
        'Trebi',
        'Wisconsin No. 38',
        'No. 457',
        'Glabron',
        'Peatland',
        'Velvet',
        'No. 475',
        'Manchuria',
        'No. 462',
        'Svansota',
      ],
    );
    expect(
      groupSort(barleyData, (g) => medianBy(g, (d) => d.yield), (d) => d.site),
      <String>[
        'Grand Rapids',
        'Duluth',
        'University Farm',
        'Morris',
        'Crookston',
        'Waseca',
      ],
    );
    expect(
      groupSort(
        barleyData,
        (g) => -medianBy(g, (d) => d.yield)!,
        (d) => d.site,
      ),
      <String>[
        'Waseca',
        'Crookston',
        'Morris',
        'University Farm',
        'Duluth',
        'Grand Rapids',
      ],
    );
    expect(
      groupSort(barleyData, (g) => medianBy(g, (d) => -d.yield), (d) => d.site),
      <String>[
        'Waseca',
        'Crookston',
        'Morris',
        'University Farm',
        'Duluth',
        'Grand Rapids',
      ],
    );
  });

  test('groupSort(data, reduce, key) returns sorted keys when reduce is a '
      'comparator', () {
    expect(
      groupSortCompare(
        barleyData,
        (a, b) =>
            ascending(medianBy(a, (d) => d.yield), medianBy(b, (d) => d.yield)),
        (d) => d.variety,
      ),
      <String>[
        'Svansota',
        'No. 462',
        'Manchuria',
        'No. 475',
        'Velvet',
        'Peatland',
        'Glabron',
        'No. 457',
        'Wisconsin No. 38',
        'Trebi',
      ],
    );
    expect(
      groupSortCompare(
        barleyData,
        (a, b) => descending(
          medianBy(a, (d) => d.yield),
          medianBy(b, (d) => d.yield),
        ),
        (d) => d.variety,
      ),
      <String>[
        'Trebi',
        'Wisconsin No. 38',
        'No. 457',
        'Glabron',
        'Peatland',
        'Velvet',
        'No. 475',
        'Manchuria',
        'No. 462',
        'Svansota',
      ],
    );
    expect(
      groupSortCompare(
        barleyData,
        (a, b) =>
            ascending(medianBy(a, (d) => d.yield), medianBy(b, (d) => d.yield)),
        (d) => d.site,
      ),
      <String>[
        'Grand Rapids',
        'Duluth',
        'University Farm',
        'Morris',
        'Crookston',
        'Waseca',
      ],
    );
    expect(
      groupSortCompare(
        barleyData,
        (a, b) => descending(
          medianBy(a, (d) => d.yield),
          medianBy(b, (d) => d.yield),
        ),
        (d) => d.site,
      ),
      <String>[
        'Waseca',
        'Crookston',
        'Morris',
        'University Farm',
        'Duluth',
        'Grand Rapids',
      ],
    );
  });
}
