// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 test/specs/fixtures.spec.js (MIT, chartjs-plugin-zoom contributors).
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart';

void main() {
  group('fixtures', () {
    group('zoom', specs('zoom'));
    group('pan', specs('pan'));
  });
}
