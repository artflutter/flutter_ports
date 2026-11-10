// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 test/specs/fixtures.spec.js (MIT, chartjs-plugin-zoom contributors).
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;

void main() {
  group('fixtures', () {
    group('zoom', fixture.specs('zoom'));
    group('pan', fixture.specs('pan'));
  });
}
